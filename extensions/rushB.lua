extension = sgs.Package("rushB")
local packages = {}
table.insert(packages, extension)
---------------------------------
sgs.LoadTranslationTable{
    --["rushB"] = "DIY",
	["rushB"] = "Maki·DIY",
}
---------------------------------
local skills = sgs.SkillList()
---------------------------------
rushB_xuyou = sgs.General(extension, "rushB_xuyou", "qun", 3)
rushB_chenglveCard = sgs.CreateSkillCard{
	name = "rushB_chenglve",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local cards
		if room:askForChoice(source, self:objectName(), "d1t2+d2t1") == "d1t2" then
			source:drawCards(1, self:objectName())
			cards = room:askForExchange(source, self:objectName(), math.min(source:getHandcardNum(), 2), 2, true)
		else
			source:drawCards(2, self:objectName())
			cards = room:askForExchange(source, self:objectName(), math.min(source:getHandcardNum(), 1), 1, true)
		end
		if cards then
			room:throwCard(cards, source, nil)
			room:addPlayerMark(source, "chenglve" .. sgs.Sanguosha:getCard(cards:getSubcards():first()):getSuitString() .. "-Clear")
			room:addPlayerMark(source, "&" .. sgs.Sanguosha:getCard(cards:getSubcards():first()):getSuitString() .. "-Clear")
			if cards:subcardsLength() < 2 then return false end
			room:addPlayerMark(source, "chenglve" .. sgs.Sanguosha:getCard(cards:getSubcards():last()):getSuitString() .. "-Clear")
			room:addPlayerMark(source, "&" .. sgs.Sanguosha:getCard(cards:getSubcards():last()):getSuitString() .. "-Clear")
		end
	end,
}
rushB_chenglve = sgs.CreateViewAsSkillV2{
	name = "rushB_chenglve",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("#rushB_chenglve")
			and not player:hasUsed("rushB_chenglve")
	end,
	create_card = function(skill, request)
		return rushB_chenglveCard:clone()
	end,
}
chenglveCards = sgs.CreateTargetModSkillV2{
	name = "#chenglveCards",
	pattern = "^SkillCard",
	correct_func = function(skill, ctx)
		local from, card = ctx:getPrimary(), ctx:getCard()
		if not (from and card) then return false end
		local mod = ctx:getModType()
		if mod ~= sgs.TargetModSkill_Residue and mod ~= sgs.TargetModSkill_DistanceLimit then return false end
		if from:getMark("chenglve" .. card:getSuitString() .. "-Clear") > 0 then
			return 1000
		end
		return false
	end,
}
rushB_xuyou:addSkill(rushB_chenglve)
rushB_xuyou:addSkill(chenglveCards)
extension:insertRelatedSkills("rushB_chenglve", "#chenglveCards")
rushB_xuyou:addSkill("yinshicai")
rushB_xuyou:addSkill("cunmu")
sgs.LoadTranslationTable{
	["rushB_xuyou"] = "MK许攸",
	["#rushB_xuyou"] = "朝秦暮楚",
	["designer:rushB_xuyou"] = "俺的西木野Maki",
	["cv:rushB_xuyou"] = "官方",
	["illustrator:rushB_xuyou"] = "猎枭",
	["rushB_chenglve"] = "成略",
	["rushb_chenglve"] = "成略",
	[":rushB_chenglve"] = "出牌阶段限一次，你可以选择摸一张牌然后弃置两张手牌或摸两张牌然后弃置一张手牌。若如此做，你于此回合内使用与以此法弃置的牌相同花色的牌无距离和次数限制。",
	["d1t2"] = "摸1弃2",
	["d2t1"] = "摸2弃1",
	["$rushB_chenglve1"] = "成略在胸，良计速出。",
	["$rushB_chenglve2"] = "吾有良略在怀，必为阿瞒所需。",
	["~rushB_xuyou"] = "阿瞒，没有我，你得不到冀州啊！",
}
---------------------------------
rushB_jvshou = sgs.General(extension, "rushB_jvshou", "qun", 3)
rushB_jianying = sgs.CreateTriggerSkillV2{
    name = "rushB_jianying",
	--global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardResponded},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local card
		local jianying = false
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and not card:isKindOf("SkillCard") then
			if card:isRed() and (player:getMark("&jianyingcolorblack") > 0 or player:getMark("&jianyingcolorred") > 0) then
		    	if player:getMark("&jianyingcolorblack") > 0 then
			        room:setPlayerMark(player, "&jianyingcolorblack", 0)
				else
				    jianying = true
				end
			elseif card:isBlack() and (player:getMark("&jianyingcolorblack") > 0 or player:getMark("&jianyingcolorred") > 0) then
		    	if player:getMark("&jianyingcolorred") > 0 then
			        room:setPlayerMark(player, "&jianyingcolorred", 0)
				else
				    jianying = true
				end
			end
			if card:getNumber() == player:getMark("&".."jianying".."number") or jianying then
			    room:sendCompulsoryTriggerLog(player, skill:objectName())
			    room:broadcastSkillInvoke(skill:objectName())
				player:drawCards(1)
			end
			room:setPlayerMark(player, "&".."jianying".."number", card:getNumber())
			if card:isRed() then
		    	room:setPlayerMark(player, "&".."jianyingcolorred", 1)
			elseif card:isBlack() then
		    	room:setPlayerMark(player, "&jianyingcolorblack", 1)
			end
		end
	end,
}
rushB_shibei = sgs.CreateTriggerSkillV2{
	name = "rushB_shibei",
	--global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to:objectName() == player:objectName() then
				room:addPlayerMark(player, "&".."rushB_shibei".."-Clear")
				if math.mod(player:getMark("&".."rushB_shibei".."-Clear"), 2) == 1 then
				    room:sendCompulsoryTriggerLog(player, skill:objectName())
				    room:broadcastSkillInvoke(skill:objectName())
				    room:recover(player, sgs.RecoverStruct(player, nil, damage.damage))
			    else
				    room:sendCompulsoryTriggerLog(player, skill:objectName())
				    room:broadcastSkillInvoke(skill:objectName())
				    room:loseHp(player, 1, true, player, skill:objectName())
			    end
			end
		end
	end,
}
rushB_jvshou:addSkill(rushB_jianying)
rushB_jvshou:addSkill(rushB_shibei)
sgs.LoadTranslationTable{
	["rushB_jvshou"] = "MK沮授",
	["#rushB_jvshou"] = "监军谋国",
	["designer:rushB_jvshou"] = "俺的西木野Maki",
	["cv:rushB_jvshou"] = "官方",
	["illustrator:rushB_jvshou"] = "官方",
	["rushB_jianying"] = "渐营",
	["jianyingnumber"] = "渐营点数",
	["jianyingcolorblack"] = "渐营黑色",
	["jianyingcolorred"] = "渐营红色",
	[":rushB_jianying"] = "锁定技，每当你使用或打出一张牌时，若此牌与你使用或打出的上一张牌颜色相同或点数相同，你摸一张牌。",
	["$rushB_jianying1"] = "由缓至急，循循而进",
	["$rushB_jianying2"] = "事须缓图，欲速不达也",
	["rushB_shibei"] = "矢北",
    [":rushB_shibei"] = "锁定技，每当你受到伤害后，若为你本回合受到的单数次伤害，你回复X点体力，否则你失去1点体力。（X为伤害值）",
	["$rushB_shibei1"] = "矢志于北，尽忠于国",
	["$rushB_shibei2"] = "命系袁氏，一心向北",
	["~rushB_jvshou"] = "志士凋亡，河北哀矣！",
}
---------------------------------
rushB_sunquan = sgs.General(extension, "rushB_sunquan$", "wu")

rushB_zhihengVS = sgs.CreateViewAsSkillV2{
	name = "rushB_zhiheng",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:isNude()
	end,
	can_select_card = function(skill, request, candidate)
		return candidate ~= nil
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() == 1 then
			local c = sgs.Sanguosha:getCard(ids:first())
			local chain = sgs.Sanguosha:cloneCard("iron_chain", c:getSuit(), c:getNumber())
			chain:addSubcard(ids:first())
			chain:setSkillName(skill:objectName())
			return chain
		end
	end,
}
zhihengRes = sgs.CreateProhibitSkill{
	name = "#zhihengRes",
	is_prohibited = function(self, from, to, card)
		return table.contains(card:getSkillNames(), "rushB_zhiheng") and to
	end,
}
rushB_zhiheng = sgs.CreateTriggerSkillV2{
	name = "rushB_zhiheng",
	view_as_skill = rushB_zhihengVS,
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local move = data:toMoveOneTime()
		local n = player:getMark("fzhiheng")
		if event == sgs.CardsMoveOneTime then
			if move.reason.m_skillName == "rushB_zhiheng" then
				room:broadcastSkillInvoke("rushB_zhiheng")
				if player:isKongcheng() and player:getMark("zhiheng".."-Clear") < 1 then
				    room:addPlayerMark(player, "zhiheng".."-Clear")
				    room:setPlayerMark(player, "fzhiheng", sgs.Sanguosha:getCard(move.card_ids:first()):getNumber())
				end
			end
		end
		if n > 0 then
			room:setPlayerMark(player, "fzhiheng", 0)
			player:drawCards(n)
		end
		return false
	end,
}
rushB_jiuyuan = sgs.CreateTriggerSkillV2{
	name = "rushB_jiuyuan$",
	events = {sgs.PreCardUsed},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:getKingdom() == "wu") then return false end
		local names, objs = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if p:hasLordSkill(skill:objectName()) and player:objectName() ~= p:objectName() then
				table.insert(names, skill:objectName())
				table.insert(objs, p:objectName())
			end
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(objs, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		local target = ctx.invoker
		local p = player
		local _data = sgs.QVariant()
		_data:setValue(p)
		if use.card and use.card:isKindOf("Peach") and target:getHp() > p:getHp()
		and use.to:contains(target) and p:hasLordSkill(skill:objectName()) and room:askForSkillInvoke(target, skill:objectName(), _data) then
			room:broadcastSkillInvoke(skill:objectName())
			local recov = sgs.RecoverStruct()
			recov.recover = 1
			recov.who = target
			room:setEmotion(p, "recover")
			room:recover(p, recov)
			use.to = sgs.SPlayerList()
			data:setValue(use)
			target:drawCards(1, skill:objectName())
		end
	end,
}
rushB_jiuyuanRec = sgs.CreateTriggerSkillV2{
	name = "#rushB_jiuyuanRec$",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed, sgs.PreHpRecover},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasLordSkill("rushB_jiuyuan") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Peach") and use.from and (use.from:getKingdom() == "wu") and (player:objectName() ~= use.from:objectName()) and player:hasFlag("Global_Dying") then
				room:setCardFlag(use.card, "jiuyuanRec")
			end
		elseif event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.card and rec.card:hasFlag("jiuyuanRec") then
			    room:sendCompulsoryTriggerLog(player, "rushB_jiuyuan")
				room:broadcastSkillInvoke("rushB_jiuyuan")
				rec.recover = rec.recover + 1
				data:setValue(rec)
			end
		end
	end,
}
rushB_sunquan:addSkill(rushB_zhiheng)
rushB_sunquan:addSkill(zhihengRes)
extension:insertRelatedSkills("rushB_zhiheng", "#zhihengRes")
rushB_sunquan:addSkill(rushB_jiuyuan)
rushB_sunquan:addSkill(rushB_jiuyuanRec)
extension:insertRelatedSkills("rushB_jiuyuan", "#rushB_jiuyuanRec")
sgs.LoadTranslationTable{
	["rushB_sunquan"] = "MK孙权",
	["#rushB_sunquan"] = "年轻的贤君",
	["designer:rushB_sunquan"] = "俺的西木野Maki",
	["cv:rushB_sunquan"] = "官方",
	["illustrator:rushB_sunquan"] = "官方",
	["rushB_zhiheng"] = "制衡",
	["rushb_zhiheng"] = "制衡",
	[":rushB_zhiheng"] = "出牌阶段，你可以将一张牌当【铁索连环】重铸。<font color='green'><b>每回合限一次，</b></font>若你以此法重铸了所有手牌，你摸X张牌。（X为你以此法弃置的手牌的点数）",
	["$rushB_zhiheng1"] = "容我三思。",
	["$rushB_zhiheng2"] = "且慢！",
	["rushB_jiuyuan"] = "救援",
	[":rushB_jiuyuan"] = "主公技，当其他吴势力角色对其使用【桃】时，若其体力值大于你，其可以终止此【桃】结算，若如此做，你回复1点体力，其摸一张牌。锁定技，其他吴势力角色使用的【桃】指定你为目标后，回复的体力+1。",
	["$rushB_jiuyuan1"] = "有汝辅佐，甚好。",
	["$rushB_jiuyuan2"] = "好舒服啊！",
	["~rushB_sunquan"] = "父亲...大哥...仲谋愧矣...",
}
---------------------------------
rushB_dengai = sgs.General(extension, "rushB_dengai", "wei")
rushB_tuntian = sgs.CreateTriggerSkillV2{
	name = "rushB_tuntian",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.FinishJudge, sgs.PreCardUsed},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local tuntian1, tuntian2 = false, false
			if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
				and not (move.to and move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)) and move.from:getPhase() == sgs.Player_NotActive then
				tuntian1 = true
			end
			if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
				and not (move.to and move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)) and move.from:getPhase() ~= sgs.Player_NotActive 
				and not sgs.Sanguosha:getCard(move.card_ids:first()):hasFlag("tuntian") and sgs.Sanguosha:getCard(move.card_ids:first()):isKindOf("Slash") then
				tuntian2 = true
			end
			if (tuntian1 or tuntian2) and player:askForSkillInvoke(skill:objectName(), data) then
				room:addPlayerMark(player, skill:objectName() .. "engine")
				if player:getMark(skill:objectName() .. "engine") > 0 then
					room:broadcastSkillInvoke(skill:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|heart"
					judge.good = false
					judge.reason = skill:objectName()
					judge.who = player
					room:judge(judge)
					room:removePlayerMark(player, skill:objectName() .. "engine")
				end
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from:getPhase() ~= sgs.Player_NotActive then
				room:setCardFlag(use.card, "tuntian")
			end
		else
			local judge = data:toJudge()
			if judge.reason == skill:objectName() and room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_PlaceJudge then
				if judge:isGood() then
					if sgs.GetConfig("heg_skill", true) and not room:askForSkillInvoke(player, skill:objectName(), data) then return false end
					player:addToPile("field", judge.card:getEffectiveId())
				elseif judge.card:getSuit() == sgs.Card_Heart then
					player:obtainCard(judge.card)
				end
			end
		end
		return false
	end,
}
tuntianDis = sgs.CreateDistanceSkillV2{
	name = "#tuntianDis",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local from = ctx:getPrimary()
		if from and from:hasSkill("rushB_tuntian") and not from:getPile("field"):isEmpty() then
			return -from:getPile("field"):length()
		end
		return false
	end,
}
rushB_zaoxian = sgs.CreateTriggerSkillV2{
    name = "rushB_zaoxian",
	frequency = sgs.Skill_Wake,
	waked_skills = "jixi",
	events = {sgs.EventPhaseChanging, sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) and player:getMark(skill:objectName()) < 1 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("kzaoxian") > 0 then
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName())
				room:removePlayerMark(player, "kzaoxian")
				player:gainAnExtraTurn()
			end
		else
			if player:getPhase() == sgs.Player_Start and (player:getPile("field"):length() >= 3 or player:canWake(skill:objectName())) and player:getMark(skill:objectName()) == 0 then
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName())
				room:addPlayerMark(player, "kzaoxian")
				room:addPlayerMark(player, skill:objectName())
				room:acquireSkill(player, "jixi")
			end
		end
	end,
}

rushB_dengai:addSkill(rushB_tuntian)
rushB_dengai:addSkill(tuntianDis)
rushB_dengai:addSkill(rushB_zaoxian)
extension:insertRelatedSkills("rushB_tuntian", "#tuntianDis")
sgs.LoadTranslationTable{
	["rushB_dengai"] = "MK邓艾",
	["#rushB_dengai"] = "矫然的壮士",
	["designer:rushB_dengai"] = "俺的西木野Maki",
	["cv:rushB_dengai"] = "官方",
	["illustrator:rushB_dengai"] = "官方",
	["rushB_tuntian"] = "屯田",
	[":rushB_tuntian"] = "当你于回合外失去牌或于回合内弃置【杀】后，你可以进行判定，若结果：不为红桃，将判定牌置于武将牌上，称为“田”；为红桃，你获得此判定牌。你与其他角色的距离-X（X为“田”的数量）。",
	["$rushB_tuntian1"] = "文为世范，行为士则。",
	["$rushB_tuntian2"] = "兴修水利，垦辟荒野，军民并丰，乃国之大事矣。",
	["rushB_zaoxian"] = "凿险",
    [":rushB_zaoxian"] = "觉醒技，准备阶段开始时，若你的“田”大于或等于三张，你获得“急袭”，且你于当前回合结束后获得一个额外回合。",
	["$rushB_zaoxian1"] = "克服山险，奇袭敌后！",
	["$rushB_zaoxian2"] = "瞒天过海，乘虚而入！",
	["rushB_jixi"] = "急袭",
	["rushb_jixi"] = "急袭",
	[":rushB_jixi"] = "你可以将一张“田”当【顺手牵羊】使用。",
	["$rushB_jixi1"] = "轻甲疾行，随我破敌！",
	["$rushB_jixi2"] = "神兵突现，防不胜防！",
	["~rushB_dengai"] = "汝等小人，竟诬我谋反……",
}
---------------------------------
rushB_zhonghui = sgs.General(extension, "rushB_zhonghui", "wei")
rushB_quanji = sgs.CreateTriggerSkillV2{
	name = "rushB_quanji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseEnd, sgs.Damaged, sgs.Damage},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local x = damage.damage
			for i = 0, x - 1, 1 do
				if player:askForSkillInvoke(skill:objectName()) then
					room:broadcastSkillInvoke(skill:objectName())
					room:drawCards(player, 1, skill:objectName())
				    if player:isNude() then return nil end
					local card_id = room:askForExchange(player, skill:objectName(), 1, 1, true, "QuanjiPush")
					player:addToPile("power", card_id)
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			local x = damage.damage
			for i = 0, x - 1, 1 do
				if player:askForSkillInvoke(skill:objectName()) then
					room:broadcastSkillInvoke(skill:objectName())
					room:drawCards(player, 1, skill:objectName())
				    if player:isNude() then return nil end
					local card_id = room:askForExchange(player, skill:objectName(), 1, 1, true, "QuanjiPush")
					player:addToPile("power", card_id)
				end
			end
		else
		    if player:getPhase() == sgs.Player_Play then
			    if player:getHandcardNum() > player:getHp() then
				    if player:askForSkillInvoke(skill:objectName()) then
						room:broadcastSkillInvoke(skill:objectName())
						room:drawCards(player, 1, skill:objectName())
						if not player:isKongcheng() then
							local card_id = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
							if player:getHandcardNum() == 1 then
								card_id = player:handCards():first()
								room:getThread():delay()
							else
								card_id = room:askForExchange(player, skill:objectName(), 1, 1, true, "QuanjiPush")
							end
							player:addToPile("power", card_id)
						end
					end
				end
			end
		end
	end,
}
rushB_quanjiKeep = sgs.CreateMaxCardsSkillV2{
	name = "#rushB_quanjiKeep",
	frequency = sgs.Skill_Compulsory,
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local target = ctx:getHolder()
		if target and target:hasSkill("rushB_quanji") then
			return target:getPile("power"):length()
		end
		return false
	end,
}
rushB_zili = sgs.CreateTriggerSkillV2{
	name = "rushB_zili",
	frequency = sgs.Skill_Wake,
	events = {sgs.EventPhaseStart},
	waked_skills = "rushB_paiyi",
	can_trigger = function(skill, event, room, player, data)
		if (player and player:isAlive() and player:hasSkill(skill:objectName()))
		and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish)
		and (player:getMark("rushB_zili") == 0)
		and (player:getPile("power"):length() >= 3 or player:canWake(skill:objectName())) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName(), math.random(1, 3))
		room:addPlayerMark(player, "rushB_zili")
		if room:changeMaxHpForAwakenSkill(player, -1, skill:objectName()) then
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
			room:drawCards(player, 2)
			room:acquireSkill(player, "rushB_paiyi")
		end
		return false
	end,
}
rushB_paiyiCard = sgs.CreateSkillCard{
	name = "rushB_paiyi",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local n, x, damage = math.min(7, source:getPile("power"):length()), math.random(1, 4), nil
		if target:getHandcardNum() + n > source:getHandcardNum() and target:objectName() ~= source:objectName() then
		    if x == 1 then damage = sgs.DamageStruct_Normal end
		    if x == 2 then damage = sgs.DamageStruct_Ice end
		    if x == 3 then damage = sgs.DamageStruct_Thunder end
		    if x == 4 then damage = sgs.DamageStruct_Fire end
		    room:damage(sgs.DamageStruct(self:objectName(), source, target, 1, damage))
		end
		local powers = source:getPile("power")
		if powers:length() > 0 and target:isAlive() then
			local id
			if powers:length() == 1 then
				id = powers:first()
			else
				room:fillAG(powers, source)
				id = room:askForAG(source, powers, false, self:objectName())
				room:clearAG(source)
			end
			if id ~= -1 then
				local card = sgs.Sanguosha:getCard(id)
				room:throwCard(card, nil, nil)
				room:drawCards(target, n, self:objectName())
			end
		end
	end,
}
rushB_paiyi = sgs.CreateViewAsSkillV2{
	name = "rushB_paiyi",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not (player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY) then return false end
		local powers = player:getPile("power")
		return not powers:isEmpty()
	end,
	create_card = function(skill, request)
		return rushB_paiyiCard:clone()
	end,
}
rushB_zhonghui:addSkill(rushB_quanji)
rushB_zhonghui:addSkill(rushB_quanjiKeep)
extension:insertRelatedSkills("rushB_quanji", "#rushB_quanjiKeep")
rushB_zhonghui:addSkill(rushB_zili)
if not sgs.Sanguosha:getSkill("rushB_paiyi") then skills:append(rushB_paiyi) end
sgs.LoadTranslationTable{
	["rushB_zhonghui"] = "MK钟会",
	["#rushB_zhonghui"] = "谋逆潜蛟",
	["designer:rushB_zhonghui"] = "俺的西木野Maki",
	["cv:rushB_zhonghui"] = "官方",
	["illustrator:rushB_zhonghui"] = "未知",
	["rushB_quanji"] = "权计",
	[":rushB_quanji"] = "出牌阶段结束时，你的手牌数大于体力值时，或当你造成/受到一点伤害后，你可以摸一张牌，之后将一张牌置于武将牌上称为“权”。锁定技，你的手牌上限+X（X为“权”的数量）。",
	["$rushB_quanji1"] = "备兵驯马，以待战机。",
	["$rushB_quanji2"] = "避其锋芒，权且忍让。",
	["rushB_zili"] = "自立",
    [":rushB_zili"] = "觉醒技，准备/结束阶段开始时，若“权”大于或等于三张，你失去1点体力上限，摸两张牌并回复1点体力，然后获得“排异”。",
	["$rushB_zili1"] = "金鳞，岂是池中之物！",
	["$rushB_zili2"] = "千载一时，鼎足而立！",
	["rushB_paiyi"] = "排异",
	["rushb_paiyi"] = "排异",
    [":rushB_paiyi"] = "出牌阶段，你可以将一张“权”置入弃牌堆并选择一名角色：若如此做，若其手牌数+X大于你的手牌数，该角色受到1点随机属性伤害，然后其摸X张牌。（X为“权”的数量且至多为7）",
	["$rushB_paiyi1"] = "艾命不尊，死有余辜！",
	["$rushB_paiyi2"] = "非我族类，其心必异！",
	["~rushB_zhonghui"] = "伯约，我已无力回天......",
}
---------------------------------
diy_f_xusheng = sgs.General(extension, "diy_f_xusheng", "wu")
diy_f_pojunCard = sgs.CreateSkillCard{
	name = "diy_f_pojun",
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and math.min(to_select:getEquips():length() + to_select:getHandcardNum(), to_select:getHp()) > 0
	end,
	feasible = function(self, targets, player)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local n, x = math.min(targets[1]:getEquips():length() + targets[1]:getHandcardNum(), targets[1]:getHp()), 0
		if n > 0 then
			local remove = sgs.IntList()
			for i = 1, n do--进行多次执行
				local id = room:askForCardChosen(source, targets[1], "he", self:objectName(),
					false,--选择卡牌时手牌不可见
					sgs.Card_MethodNone,--设置为弃置类型
					remove,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
					i>1)--只有执行过一次选择才可取消
				if id < 0 then break end--如果卡牌id无效就结束多次执行
				remove:append(id)--将选择的id添加到虚拟卡的子卡表
			end
			local dummy = sgs.Sanguosha:cloneCard("slash")
			dummy:addSubcards(remove)
			dummy:deleteLater()
			local tt = sgs.SPlayerList()
			tt:append(targets[1])
			targets[1]:addToPile("diy_f_pojun", dummy, false, tt)
		end
	end,
}
diy_f_pojunvs = sgs.CreateViewAsSkillV2{
	name = "diy_f_pojun",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:usedTimes("#diy_f_pojun") + player:usedTimes("diy_f_pojun") < 1
	end,
	can_select_card = function(skill, request, candidate)
		return candidate ~= nil and request:getSelectedCardIds():length() < 1
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local MXC = diy_f_pojunCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			MXC:addSubcard(id)
		end
		return MXC
	end,
}
diy_f_pojun = sgs.CreateTriggerSkillV2{
	name = "diy_f_pojun",
	--global = true,
	events = {sgs.DamageCaused, sgs.EventPhaseChanging, sgs.EventPhaseStart},
	view_as_skill = diy_f_pojunvs,
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.DamageCaused then
			if player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
			return false
		end
		local names, objs = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(objs, p:objectName())
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(objs, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
			    for _, p in sgs.qlist(room:getAllPlayers()) do
				    if not p:getPile("diy_f_pojun"):isEmpty() then
					    local dummy = sgs.Sanguosha:cloneCard("slash")
					    dummy:addSubcards(p:getPile("diy_f_pojun"))
					    room:obtainCard(p, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, p:objectName(), skill:objectName(), ""), false)
					    dummy:deleteLater()
				    end
			    end
		    end
		elseif event == sgs.EventPhaseStart then
			local target = ctx.invoker
		    if target and target:getPhase() == sgs.Player_RoundStart then
			    local p = player
		        if p:objectName() ~= target:objectName() and not p:isNude() and room:askForCard(p, "..", "@diy_f_pojun") then
				    room:sendCompulsoryTriggerLog(p, skill:objectName())
					room:broadcastSkillInvoke(skill:objectName())
					local n, x = math.min(target:getEquips():length() + target:getHandcardNum(), target:getHp()), 0
                	if n > 0 then
		                local remove = sgs.IntList()
						for i = 1, n do--进行多次执行
							local id = room:askForCardChosen(p, target, "he", skill:objectName(),
								false,--选择卡牌时手牌不可见
								sgs.Card_MethodNone,--设置为弃置类型
								remove,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
								i>1)--只有执行过一次选择才可取消
							if id < 0 then break end--如果卡牌id无效就结束多次执行
							remove:append(id)--将选择的id添加到虚拟卡的子卡表
						end
						local dummy = sgs.Sanguosha:cloneCard("slash")
						dummy:addSubcards(remove)
						dummy:deleteLater()
						local tt = sgs.SPlayerList()
						tt:append(target)
						target:addToPile("diy_f_pojun", dummy, false, tt)
	                end
			    end
		    end
		else
			local damage = data:toDamage()
			local to = damage.to
			local n = 0
			if damage.from:hasSkill(skill:objectName()) and to and to:isAlive() then
				if to:getHandcardNum() <= damage.from:getHandcardNum() then n = n + 1 end
				if to:getEquips():length() <= damage.from:getEquips():length() then n = n + 1 end
				if to:getJudgingArea():length() >= damage.from:getJudgingArea():length() then n = n + 1 end
				room:sendCompulsoryTriggerLog(player, skill:objectName())
			    room:broadcastSkillInvoke(skill:objectName())
				damage.damage = damage.damage + n
				data:setValue(damage)
			end
		end
		return false
	end,
}
diy_f_xusheng:addSkill(diy_f_pojun)
sgs.LoadTranslationTable{
	["diy_f_xusheng"] = "MK徐盛",
	["#diy_f_xusheng"] = "整军经武",
	["designer:diy_f_xusheng"] = "俺的西木野Maki",
	["cv:diy_f_xusheng"] = "官方",
	["illustrator:diy_f_xusheng"] = "官方",
	["diy_f_pojun"] = "破军",
	["@diy_f_pojun"] = "你可以发动“破军”<br/> <b>操作提示</b>: 选择一张牌→点击确定<br/>",
	[":diy_f_pojun"] = "<font color='green'>出牌阶段限一次</font>或其他角色的回合开始时，你可以弃置一张牌并选择一名其他角色将其一至X张牌扣置于其武将牌旁（X为其体力值），若如此做，当前回合结束时，其获得这些牌；当你一名其他角色造成伤害时，若其：①手牌数不大于你；②装备区牌数不大于你；③判定区牌数不小于你，每满足一项则此伤害+1。",
	["pojun:continue"] = "是否继续发动“破军”扣置目标牌",
	["$diy_f_pojun1"] = "犯大吴疆土者，盛必击而破之！",
	["$diy_f_pojun2"] = "若敢来犯，必教你大败而归！",
	["~diy_f_xusheng"] = "盛只恨……不能再为主公……破敌制胜了……",
}
---------------------------------
diy_k_ganning = sgs.General(extension, "diy_k_ganning", "wu")
diy_k_qixiCard = sgs.CreateSkillCard{
	name = "diy_qixi",
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and not to_select:isNude()
	end,
	feasible = function(self, targets, player)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local dummy = sgs.Sanguosha:cloneCard("slash")
		for _, card in sgs.qlist(targets[1]:getHandcards()) do
			dummy:addSubcard(card)
		end
		for _, cards in sgs.qlist(targets[1]:getEquips()) do
			dummy:addSubcard(cards)
		end
		room:obtainCard(source, dummy)
		dummy:deleteLater()
	end,
}
diy_k_qixi = sgs.CreateViewAsSkillV2{
	name = "diy_k_qixi",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		local qixii, qixir = false, false
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:isBlack() or (card:isRed() and card:isKindOf("EquipCard")) then
				qixii = true
			end
		end
		for _, cards in sgs.qlist(player:getEquips()) do
			if cards:isBlack() or (cards:isRed() and cards:isKindOf("EquipCard")) then
				qixir = true
			end
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			for _, p in sgs.qlist(player:getAliveSiblings()) do
				return not p:isNude() and (qixii or qixir)
			end
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern() or ""
			for _, p in sgs.qlist(player:getAliveSiblings()) do
				return not p:isNude() and (qixii or qixir) and string.find(pattern, "@@diy_k_qixi") ~= nil
			end
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate or candidate:hasFlag("using") then return false end
		if request:getSelectedCardIds():length() >= 1 then return false end
		return candidate:isBlack() or (candidate:isRed() and candidate:isKindOf("EquipCard"))
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = sgs.Sanguosha:getCard(ids:first())
		local new_card = nil
		local patt = request:getReason()
		if card:isBlack() then
			new_card = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_SuitToBeDecided, 0)
		elseif card:isRed() and card:isKindOf("EquipCard") then
			new_card = diy_k_qixiCard:clone()
		end
		if new_card then
		    if patt == "@@diy_k_qixi" then
				if card:isBlack() then
				    new_card:setSkillName("diy_fenwei")
			    elseif card:isRed() and card:isKindOf("EquipCard") then
				    new_card:setSkillName("diy_fenwei")
			    end
			else
				if card:isBlack() then
				    new_card:setSkillName(skill:objectName())
			    elseif card:isRed() and card:isKindOf("EquipCard") then
				    new_card:setSkillName("diy_qixi")
			    end
			end
		end
		new_card:addSubcard(card)
		return new_card
	end,
}
diy_k_fenwei = sgs.CreateTriggerSkillV2{
	name = "diy_k_fenwei",
	--global = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetConfirming},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		local names, objs = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(objs, p:objectName())
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(objs, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		local splayer = player
		if use.to:length() < 2 then return false end
		local targets = sgs.SPlayerList()
		local target_list = {}
		for _, pe in sgs.qlist(use.to) do
			targets:append(pe)
			table.insert(target_list, pe:objectName())
		end
		if not targets:isEmpty() and splayer:getMark("fenwei".."-Clear") < 1 then
			splayer:setTag("fenwei", data)
			room:setPlayerProperty(splayer, "fenwei_targets", sgs.QVariant(table.concat(target_list, "+")))
		    local to = room:askForPlayersChosen(splayer, targets, skill:objectName(), 0, use.to:length(), "~fenwei", true, false)
			room:setPlayerProperty(splayer, "fenwei_targets", sgs.QVariant())
			splayer:removeTag("fenwei")
			if not to:isEmpty() then
				room:broadcastSkillInvoke(skill:objectName(), math.random(1, 2))
				room:addPlayerMark(splayer, "fenwei".."-Clear")
				for _, p in sgs.qlist(to) do
				    local nullified_list = use.nullified_list
				    table.insert(nullified_list, p:objectName())
				    use.nullified_list = nullified_list
				    data:setValue(use)
	                local qixii, qixir = false, false
	                for _, card in sgs.qlist(splayer:getHandcards()) do
		                if card:isBlack() or (card:isRed() and card:isKindOf("EquipCard")) then
			                qixii = true
		                end
	                end
	                for _, cards in sgs.qlist(splayer:getEquips()) do
		                if cards:isBlack() or (cards:isRed() and cards:isKindOf("EquipCard")) then
			                qixir = true
		                end
	                end
			        if p:objectName() == splayer:objectName() and (qixii or qixir) then
		                room:askForUseCard(splayer, "@@diy_k_qixi", "@choose-players")
					end
				end
			end
		end
	end,
}

diy_k_ganning:addSkill(diy_k_qixi)
diy_k_ganning:addSkill(diy_k_fenwei)

sgs.LoadTranslationTable{
	["diy_k_ganning"] = "MK甘宁",
	["#diy_k_ganning"] = "兴王定霸",
	["designer:diy_k_ganning"] = "俺的西木野Maki",
	["cv:diy_k_ganning"] = "官方",
	["illustrator:diy_k_ganning"] = "官方",
	["diy_k_qixi"] = "奇袭",
	["diy_qixi"] = "奇袭",
	[":diy_k_qixi"] = "你可以将一张黑色牌或红色装备牌当【过河拆桥】使用。当你以此法使用红色装备牌转化的【过河拆桥】时，你改为获得其所有牌。",
	["$diy_k_qixi1"] = "击敌不备，奇袭拔寨！",
	["$diy_k_qixi2"] = "轻羽透重铠，奇袭溃坚城！",
	["$diy_k_qixi3"] = "你用不了这么多了！",
	["$diy_k_qixi4"] = "弟兄们，准备动手！",
	["diy_k_fenwei"] = "奋威",
	["diy_fenwei"] = "奋威",
	[":diy_k_fenwei"] = "<font color='green'>每回合限一次</font>，当一张锦囊牌指定两个或更多目标后，你可令此牌对其中任意名目标角色无效。若其中包含你，则你可以发动一次“奇袭”。",
	["$diy_k_fenwei1"] = "舍身护主，扬吴将之风！",
	["$diy_k_fenwei2"] = "袭军挫阵，奋江东之威！",
	["$diy_k_fenwei3"] = "哼，敢欺我东吴无人？",
	["$diy_k_fenwei4"] = "奋勇当先，威名远扬！",
	["~diy_k_ganning"] = "别管我……继续杀……",
}
---------------------------------
wen_zhugeliang = sgs.General(extension, "wen_zhugeliang", "shu", 3)
wen_jingtian = sgs.CreateTriggerSkillV2{
	name = "wen_jingtian",
	--global = true,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_Start then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:askForSkillInvoke(skill:objectName()) then
			room:broadcastSkillInvoke(skill:objectName(), 1)
			local count = player:getPile("chushibiao"):length()
			if count >= 7 then
				count = 7
			elseif count <= 3 then
				count = 3
			end
			room:askForGuanxing(player, room:getNCards(count))
		end
	end,
}
wen_jingtian_ex = sgs.CreateTriggerSkillV2{
	name = "#wen_jingtian_ex",
	events = {sgs.GameStart, sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to ~= sgs.Player_NotActive then return false end
			local names, objs = {}, {}
			for _, p in sgs.qlist(room:findPlayersBySkillName("wen_jingtian")) do
				table.insert(names, skill:objectName())
				table.insert(objs, p:objectName())
			end
			if #names > 0 then
				return table.concat(names, "|"), table.concat(objs, "|")
			end
			return false
		else
			if player:hasSkill("wen_jingtian") then
				return skill:objectName()
			end
			return false
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
		    if change.to == sgs.Player_NotActive then
			    local splayer = player
			    if splayer:getPile("chushibiao"):isEmpty() then
					room:sendCompulsoryTriggerLog(splayer, "wen_jingtian")
					room:broadcastSkillInvoke("wen_jingtian")
					splayer:drawCards(7)
					local id = room:askForExchange(splayer, "wen_jingtian", 7, 7, true, "", false)
					splayer:addToPile("chushibiao", id)
				end
			end
		else
		    if player:hasSkill("wen_jingtian") then
			    room:sendCompulsoryTriggerLog(player, "wen_jingtian")
			    room:broadcastSkillInvoke("wen_jingtian")
			    player:drawCards(7)
				local id = room:askForExchange(player, "wen_jingtian", 7, 7, true, "", false)
				player:addToPile("chushibiao", id)
			end
		end
		return false
	end,
}
wen_jtweidiCard = sgs.CreateSkillCard{
	name = "wen_jtweidi",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	feasible = function(self, targets, player)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		room:obtainCard(targets[1], self, false)
		source:addToPile("chushibiao", room:getDrawPile():last())
		local choice1 = room:askForChoice(source, self:objectName(), "1+3", ToData(targets[1]))
		local choice2 = room:askForChoice(targets[1], self:objectName(), "2+4", ToData(source))
		local log = sgs.LogMessage()
		log.type = "#weidi_choice"
		log.from = source
		log.to:append(targets[1])
		if choice1 == "1" and choice2 == "2" then
		    log.arg = "wen_jtweidi:1"
		    log.arg2 = "wen_jtweidi:2"
		elseif choice1 == "1" and choice2 == "4" then
		    log.arg = "wen_jtweidi:1"
		    log.arg2 = "wen_jtweidi:4"
		elseif choice1 == "3" and choice2 == "2" then
		    log.arg = "wen_jtweidi:3"
		    log.arg2 = "wen_jtweidi:2"
		elseif choice1 == "3" and choice2 == "4" then
		    log.arg = "wen_jtweidi:3"
		    log.arg2 = "wen_jtweidi:4"
		end
		room:sendLog(log)
		if choice1 == "1" and choice2 == "2" then
		    room:broadcastSkillInvoke(self:objectName(), 2)
			for _,skill in sgs.qlist(targets[1]:getVisibleSkillList()) do
				room:addPlayerMark(targets[1], "Qingcheng"..skill:objectName())
			end
			room:damage(sgs.DamageStruct(self:objectName(), source, targets[1], 2, sgs.DamageStruct_Fire))
			for _,skill in sgs.qlist(targets[1]:getVisibleSkillList()) do
				room:removePlayerMark(targets[1], "Qingcheng"..skill:objectName())
			end
		elseif choice1 == "1" and choice2 == "4" then
		    source:drawCards(1)
			local id = room:askForExchange(source, self:objectName(), math.min(source:getHandcardNum(), 2), 2, true, "", false)
		    room:obtainCard(targets[1], id, false)
		elseif choice1 == "3" and choice2 == "2" then
		    room:damage(sgs.DamageStruct(self:objectName(), targets[1], source, 1, sgs.DamageStruct_Normal))
		    source:drawCards(1)
		elseif choice1 == "3" and choice2 == "4" then
			if room:askForChoice(source, self:objectName().."draw", "first+last") == "first" then
		        source:drawCards(4)
			    targets[1]:drawCards(1)
			else
			    targets[1]:drawCards(1)
		        source:drawCards(4)
			end
		end
	end,
}
wen_jtweidiVS = sgs.CreateViewAsSkillV2{
	name = "wen_jtweidi",
	n = 1,
	expand_pile = "chushibiao",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and (player:usedTimes("#wen_jtweidi") + player:usedTimes("wen_jtweidi")) < 1
			and not player:getPile("chushibiao"):isEmpty()
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate or request:getSelectedCardIds():length() >= 1 then return false end
		local player = request:getInitiator()
		if player then
			local id = candidate:getEffectiveId()
			if player:getPile("chushibiao"):contains(id) then
				return true
			end
		end
		return false
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() == 1 then
			local jtweidi = wen_jtweidiCard:clone()
			jtweidi:addSubcard(ids:first())
			jtweidi:setSkillName(skill:objectName())
			return jtweidi
		end
	end,
}
wen_jtweidi = sgs.CreateTriggerSkillV2{
	name = "wen_jtweidi",
	events = {sgs.PreCardUsed, sgs.DamageCaused},
	view_as_skill = wen_jtweidiVS,
	priority = 1,
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.to and damage.to:hasSkill(skill:objectName()) then
				return skill:objectName(), damage.to
			end
			return false
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == "wen_jtweidi" then
				local names, objs = {}, {}
				for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					table.insert(names, skill:objectName())
					table.insert(objs, p:objectName())
				end
				if #names > 0 then
					return table.concat(names, "|"), table.concat(objs, "|")
				end
			end
			return false
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.DamageCaused then
		    local damage = data:toDamage()
		    if player:hasSkill("wen_jtweidi") and not player:getPile("chushibiao"):isEmpty() and room:askForSkillInvoke(player, "wen_jtweidi", data) then
				room:broadcastSkillInvoke("wen_jtweidi")
			    room:fillAG(player:getPile("chushibiao"), player)
		        local id = room:askForAG(player, player:getPile("chushibiao"), false, skill:objectName())
		        room:clearAG(player)
		        room:throwCard(id, player, nil)
				damage.prevented = true
                data:setValue(damage)
				return true
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local skillname = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n
				if skillname == "wen_jtweidi" then
					room:broadcastSkillInvoke(skillname, 1)
					return true
				end
			end
		end
	end,
}


wen_zemin = sgs.CreateTriggerSkillV2{
	name = "wen_zemin",
	--global = true,
	events = {sgs.DamageCaused, sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.DamageCaused then
			if player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
			return false
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_RoundStart then return false end
			local names, objs = {}, {}
			for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				table.insert(names, skill:objectName())
				table.insert(objs, p:objectName())
			end
			if #names > 0 then
				return table.concat(names, "|"), table.concat(objs, "|")
			end
			return false
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.DamageCaused then
		    local damage = data:toDamage()
		    if damage.from:hasSkill(skill:objectName()) and not damage.from:getPile("chushibiao"):isEmpty() and damage.from:objectName() ~= damage.to:objectName() and room:askForSkillInvoke(damage.from, skill:objectName(), data) then
				room:broadcastSkillInvoke(skill:objectName())
			    room:fillAG(damage.from:getPile("chushibiao"), damage.from)
		        local id = room:askForAG(damage.from, damage.from:getPile("chushibiao"), false, skill:objectName())
		        room:clearAG(damage.from)
		        room:obtainCard(damage.to, id)
				room:addPlayerMark(damage.from, "&zeminfrom")
				room:addPlayerMark(damage.to, "&zeminto")
				room:addPlayerMark(damage.to, "zeminto")
				damage.prevented = true
                data:setValue(damage)
				return true
			end
		elseif event == sgs.EventPhaseStart then
			local target = ctx.invoker
		    if target and target:getPhase() == sgs.Player_RoundStart then
			    if target:getMark("zeminto") > 0 and target:getMark("&zeminto") > 0 then
				    room:removePlayerMark(target, "zeminto", target:getMark("zeminto"))
				elseif target:getMark("zeminto") == 0 and target:getMark("&zeminto") > 0 then
				    room:removePlayerMark(target, "&zeminto")
			        local splayer = player
				    if splayer:getMark("&zeminfrom") > 0 and target:getMark("&zeminto") == 0 then
			            room:removePlayerMark(splayer, "&zeminfrom", splayer:getMark("&zeminfrom"))
					end
				end
			end
		end
		return false
	end,
}
wen_zemin_ex = sgs.CreateProhibitSkill{
	name = "#wen_zemin_ex",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("wen_zemin") and from:getMark("&zeminto") > 0 and to:getMark("&zeminfrom") > 0
	end,
}

wen_zhugeliang:addSkill(wen_jingtian)
wen_zhugeliang:addSkill(wen_jingtian_ex)
extension:insertRelatedSkills("wen_jingtian", "#wen_jingtian_ex")
wen_zhugeliang:addSkill(wen_jtweidi)
wen_zhugeliang:addSkill(wen_zemin)
wen_zhugeliang:addSkill(wen_zemin_ex)
extension:insertRelatedSkills("wen_zemin", "#wen_zemin_ex")
sgs.LoadTranslationTable{
	["wen_zhugeliang"] = "文辞诸葛亮",
	["&wen_zhugeliang"] = "文诸葛亮",
	["#wen_zhugeliang"] = "奏表绝唱",
	["designer:wen_zhugeliang"] = "未知",
	["cv:wen_zhugeliang"] = "官方",
	["illustrator:wen_zhugeliang"] = "官方",
	["wen_jingtian"] = "经天",
	[":wen_jingtian"] = "游戏开始时或每名角色回合结束时，若你没有“表”，你摸七张牌，然后将七张牌扣置于武将牌旁，称为“表”。准备阶段，你可以观看牌堆顶的X张牌，然后将任意数量的牌置于牌堆顶，将其余的牌置于牌堆底。（X为“表”数且至少为3，至多为7）",
	["$wen_jingtian1"] = "祈星辰之力，佑我蜀汉！",
	["$wen_jingtian2"] = "伏望天恩，誓讨汉贼！",
	["wen_jtweidi"] = "纬地",
	["wen_jtweidi:1"] = "镇压",
	["wen_jtweidi:2"] = "反抗",
	["wen_jtweidi:3"] = "安抚",
	["wen_jtweidi:4"] = "归顺",
	["#weidi_choice"] = "%from 选择了 %arg，%to 选择了 %arg2",
	[":wen_jtweidi"] = "出牌阶段限一次，你可以将一张“表”交给一名其他角色，然后将牌堆底一张牌置入“表”中并与其进行谋弈，若：你选择镇压，其选择反抗，则你对其造成2点火焰伤害；你选择安抚，其选择反抗，你受到1点伤害并摸一张牌；"..
	"你选择镇压，其选择归顺，你摸一张牌并交给其两张牌；你选择安抚，其选择归顺，其摸一张牌你摸四张牌。当一名角色对你造成伤害时，你可以弃置一张“表”，然后防止此伤害。",
	["$wen_jtweidi1"] = "万事俱备，只欠业火。",
	["$wen_jtweidi2"] = "风~起~",
	["wen_zemin"] = "泽民",
	["chushibiao"] = "表",
	["zeminfrom"] = "泽民来源",
	["zeminto"] = "泽民目标",
	[":wen_zemin"] = "当你对一名角色造成伤害时，若该角色不为你，你可以选择一张“表”令其获得此“表”，然后防止此伤害。"..
	"且令其于其下个回合开始前，不能指定你为目标。",
	["$wen_zemin1"] = "此非万全之策，唯惧天雷。",
	["$wen_zemin2"] = "此计可保你一时平安。",
	["~wen_zhugeliang"] = "今当远离，临表涕零，不知...所言...",
}
---------------------------------
diy_k_jiakui = sgs.General(extension, "diy_k_jiakui", "wei", 4, true, false, false, 3, 1)
diy_k_zhongzuo = sgs.CreateTriggerSkillV2{
	name = "diy_k_zhongzuo",
	--global = true,
	events = {sgs.EventPhaseChanging, sgs.DamageDone},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to ~= sgs.Player_NotActive then return false end
		end
		local names, objs = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(objs, p:objectName())
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(objs, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
	    if event == sgs.DamageDone then
			local target = ctx.invoker
		    if target:getMark("damaged_round-Clear") == 0 then
			    room:setPlayerMark(target, "damaged_round-Clear", 1)
		    end
		    local source = data:toDamage().from
		    if source and source:isAlive() and source:getMark("damage_round-Clear") == 0 then
			    room:setPlayerMark(source, "damage_round-Clear", 1)
		    end
		else
		    if data:toPhaseChange().to ~= sgs.Player_NotActive then return false end
		    local p = player
		    if p:getMark("damage_round-Clear") == 0 and p:getMark("damaged_round-Clear") == 0 then return false end
		    local to = room:askForPlayerChosen(p, room:getAlivePlayers(), skill:objectName(), "@zhongzuo-invoke", true, true)
		    if to then
			    room:broadcastSkillInvoke(skill:objectName())
			    to:drawCards(2, skill:objectName())
			    if to:isWounded() then
				    p:drawCards(1, skill:objectName())
				end
			end
		end
		return false
	end,
}


diy_k_tongqu = sgs.CreateTriggerSkillV2{
	name = "diy_k_tongqu",
	events = {sgs.GameStart, sgs.DrawNCards},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
        	if draw.reason ~= "draw_phase" then return false end
			if room:askForSkillInvoke(player, skill:objectName()) then
				room:loseHp(player, 1, true, player, skill:objectName())
				draw.num = draw.num + 1 + player:getLostHp()
				data:setValue(draw)
			else
				room:sendCompulsoryTriggerLog(player, skill:objectName())
			    room:broadcastSkillInvoke(skill:objectName())
				draw.num = draw.num + 1
				data:setValue(draw)
			end
		end
		return false
	end,
}
diy_k_wanlan = sgs.CreateTriggerSkillV2{
	name = "diy_k_wanlan",
	events = {sgs.Damage, sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local damage = data:toDamage()
		if ((event == sgs.Damage and damage.to:isAlive()) or (event == sgs.Damaged and damage.from:isAlive())) and not player:hasFlag("wanlan") and room:askForDiscard(player, skill:objectName(), 2, 2, true, true) then
		    room:sendCompulsoryTriggerLog(player, skill:objectName())
			room:broadcastSkillInvoke(skill:objectName())
			room:setPlayerFlag(player, "wanlan")
		    player:drawCards(4)
		    if event == sgs.Damaged then
		        room:damage(sgs.DamageStruct(skill:objectName(), player, damage.from, damage.damage, damage.nature))
			else
		        room:damage(sgs.DamageStruct(skill:objectName(), player, damage.to, damage.damage, damage.nature))
			end
			room:setPlayerFlag(player, "-wanlan")
		end
		return false
	end,
}
diy_k_jiakui:addSkill(diy_k_zhongzuo)
diy_k_jiakui:addSkill(diy_k_tongqu)
diy_k_jiakui:addSkill(diy_k_wanlan)
sgs.LoadTranslationTable{
	["diy_k_jiakui"] = "MK贾逵",
	["#diy_k_jiakui"] = "肃齐万里",
	["designer:diy_k_jiakui"] = "俺的西木野Maki",
	["cv:diy_k_jiakui"] = "官方",
	["illustrator:diy_k_jiakui"] = "官方",
	["diy_k_zhongzuo"] = "忠佐",
	[":diy_k_zhongzuo"] = "一名角色的回合结束时，若你在此回合内造成过或受到过伤害，你可令一名角色摸两张牌。若该角色已受伤，你摸一张牌。",
	["$diy_k_zhongzuo1"] = "明法立继，为圣上保百姓安居。",
	["$diy_k_zhongzuo2"] = "立军定邦，辅大魏之国祚绵长。",
	["diy_k_tongqu"] = "通渠",
	["@diy_k_tongqu"] = "你可以发动“通渠”<br/> <b>操作提示</b>: 点击确定<br/>",
	[":diy_k_tongqu"] = "锁定技，摸牌阶段你额外摸一张牌，然后若你选择失去1点体力，额外摸X张牌。（X为你已损失的体力值）",
	["$diy_k_tongqu1"] = "断山蓄水，以备不虞之变。",
	["$diy_k_tongqu2"] = "开渠联镇，但求百姓得利。",
	["diy_k_wanlan"] = "挽澜",
	[":diy_k_wanlan"] = "当你造成/受到伤害后，你可以弃置两张牌并摸四张牌，然后对目标/伤害来源造成等量的同属性伤害。",
	["$diy_k_wanlan1"] = "挽狂澜于既倒，扶大厦于将倾！",
	["$diy_k_wanlan2"] = "深受国恩，今日便是报偿之时！",
	["~diy_k_jiakui"] = "不斩孙权，九泉之下羞见先帝啊！",
}
---------------------------------
--[[
diy_k_guozhao = sgs.General(extension, "diy_k_guozhao", "wei", 4, false, false, false, 3, 1)
diy_k_wufei = sgs.CreateTriggerSkill{
	name = "diy_k_wufei",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageInflicted then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:objectName() ~= damage.from:objectName() then
					players:append(p)
				end
			end
			if not players:isEmpty() then
			    local to = room:askForPlayerChosen(player, players, self:objectName(), "@choose-players", true, false)
				if not to then return nil end
			    room:sendCompulsoryTriggerLog(player, self:objectName())
			    room:broadcastSkillInvoke(self:objectName())
			    room:damage(sgs.DamageStruct(self:objectName(), damage.from, to, damage.damage, damage.nature))
			elseif players:isEmpty() then
			    local to = room:askForPlayerChosen(player, targets, self:objectName(), "@choose-players", true, false)
				if not to then return nil end
			    room:sendCompulsoryTriggerLog(player, self:objectName())
			    room:broadcastSkillInvoke(self:objectName())
				player:drawCards(4)
				room:askForDiscard(player, self:objectName(), 2, 2, false, true)
				if not to:isNude() then
		            local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:deleteLater()
		            for _, card in sgs.qlist(to:getHandcards()) do
			            dummy:addSubcard(card)
		            end
		            for _, cards in sgs.qlist(to:getEquips()) do
			            dummy:addSubcard(cards)
		            end
					room:throwCard(dummy, to, player)
				else
				    room:loseMaxHp(1)
				    room:loseHp(1)
				end
			end
			return true
		else
		    local damage = data:toDamage()
			local players, targets = sgs.SPlayerList(), sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:objectName() ~= damage.to:objectName() then
					players:append(p)
				else
					targets:append(p)
				end
			end
			if not players:isEmpty() then
			    local to = room:askForPlayerChosen(player, players, self:objectName(), "@choose-players", true, false)
				if not to then return nil end
			    room:sendCompulsoryTriggerLog(player, self:objectName())
			    room:broadcastSkillInvoke(self:objectName())
			    room:damage(sgs.DamageStruct(self:objectName(), to, damage.to, damage.damage, damage.nature))
			elseif players:isEmpty() and not targets:isEmpty() then
			    local to = room:askForPlayerChosen(player, targets, self:objectName(), "@choose-players", true, false)
				if not to then return nil end
			    room:sendCompulsoryTriggerLog(player, self:objectName())
			    room:broadcastSkillInvoke(self:objectName())
				player:drawCards(4)
				room:askForDiscard(player, self:objectName(), 2, 2, false, true)
				if not to:isNude() then
		            local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:deleteLater()
		            for _, card in sgs.qlist(to:getHandcards()) do
			            dummy:addSubcard(card)
		            end
		            for _, cards in sgs.qlist(to:getEquips()) do
			            dummy:addSubcard(cards)
		            end
					room:throwCard(dummy, to, player)
				else
				    room:loseMaxHp(1)
				    room:loseHp(1)
				end
			end
			return true
		end
	end,
}
diy_k_guozhao:addSkill(diy_k_wufei)
sgs.LoadTranslationTable{
	["diy_k_guozhao"] = "MK郭照",
--	["mobile_guozhao"] = "郭女王",
	["#diy_k_guozhao"] = "碧海青天",
	["designer:diy_k_guozhao"] = "俺的西木野Maki",
	["cv:diy_k_guozhao"] = "官方",
	["illustrator:diy_k_guozhao"] = "官方",
--	["mobileyichong"] = "易宠",
--	[":mobileyichong"] = "准备阶段，你可以选择一名其他角色并指定一种花色，获得其所有该花色的牌，并直到你下个回合开始令其获得“雀”标记（若场上已有“雀”标记，则转移给该角色）。拥有“雀”标记的角色获得你指定花色的牌时，你获得此牌（你至多因此“雀”标记获得5张牌）",
--	["$mobileyichong1"] = "得陛下怜爱，恩宠不衰",
--	["$mobileyichong2"] = "谬蒙圣恩，光授殊宠",
--	["mobilewufei"] = "诬诽",
	["diy_k_wufei"] = "诬诽",
--	[":mobilewufei"] = "你使用【杀】或伤害类普通锦囊牌指定目标后，令拥有“雀”标记的其他角色代替你成为伤害来源。你受到伤害后，若拥有“雀”标记的角色体力值大于1且大于你，你可以令其受到1点伤害。",
	[":diy_k_wufei"] = "当你造成伤害时，防止此伤害并令一名不为目标的其他角色对目标造成等量同属性伤害。当你受到伤害时，防止此伤害并令来源对不为来源的其他角色造成等量同属性伤害。若无可选择的目标，则改为摸四张牌并弃置两张牌，然后弃置目标所有牌，若没牌则改为其失去1点体力上限并失去1点体力。",
	["$diy_k_wufei1"] = "处尊居显，位极椒房",
	["$diy_k_wufei2"] = "自在东宫，及即尊位",
	["~diy_k_guozhao"] = "我的出身，不配为后？",
}
]]
--看不懂
---------------------------------
rushB_spdiaochan = sgs.General(extension, "rushB_spdiaochan", "qun", 3, false)
rushB_lihunCard = sgs.CreateSkillCard{
	name = "rushB_lihun",
	filter = function(self, targets, to_select, player)
		return (#targets == 0) and not to_select:isNude() and (to_select:objectName() ~= player:objectName())
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		effect.from:turnOver()
		local dummy_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, cd in sgs.qlist(effect.to:getHandcards()) do
			dummy_card:addSubcard(cd)
		end
		for _, cd in sgs.qlist(effect.to:getEquips()) do
			dummy_card:addSubcard(cd)
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, effect.from:objectName(),effect.to:objectName(), "rushB_lihun", nil)
		room:moveCardTo(dummy_card, effect.to, effect.from, sgs.Player_PlaceHand, reason, false)
		effect.to:setFlags("rushB_lihunTarget")
	end,
}
rushB_lihunVS = sgs.CreateViewAsSkillV2{
	name = "rushB_lihun",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:canDiscard(player, "he")
			and (not player:hasUsed("#rushB_lihun")) and (not player:hasUsed("rushB_lihun"))
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate or request:getSelectedCardIds():length() >= 1 then return false end
		local player = request:getInitiator()
		return player and not player:isJilei(candidate)
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = rushB_lihunCard:clone()
		card:addSubcard(ids:first())
		return card
	end,
}
rushB_lihun = sgs.CreateTriggerSkillV2{
	name = "rushB_lihun",
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	view_as_skill = rushB_lihunVS,
	can_trigger = function(skill, event, room, player, data)
		if player and (player:hasUsed("#rushB_lihun") or player:hasUsed("rushB_lihun")) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if (event == sgs.EventPhaseEnd) and (player:getPhase() == sgs.Player_Play) then
			local target
			for _, other in sgs.qlist(room:getOtherPlayers(player)) do
				if other:hasFlag("rushB_lihunTarget") then
					other:setFlags("-rushB_lihunTarget")
					target = other
					break
				end
			end
			if (not target) or (target:getHp() < 1) or player:isNude() then return false end
			local to_back = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			to_back:deleteLater()
			if player:getCardCount(true) <= target:getHp() then
				if not player:isKongcheng() then to_back = player:wholeHandCards() end
				for i = 0, 3, 1 do
					if player:getEquip(i) then to_back:addSubcard(player:getEquip(i):getEffectiveId()) end
				end
			else
				to_back = room:askForExchange(player, skill:objectName(), target:getHp(), target:getHp(), true, "rushB_lihunGoBack:"..target:objectName().."::"..target:getHp())
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), skill:objectName(), nil)
			room:moveCardTo(to_back, player, target, sgs.Player_PlaceHand, reason)
		elseif (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_NotActive) then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("rushB_lihunTarget") then
					p:setFlags("-rushB_lihunTarget")
				end
			end
		end
	end,
}
rushB_spdiaochan:addSkill(rushB_lihun)
rushB_spdiaochan:addSkill("tenyearbiyue")
sgs.LoadTranslationTable{
	["rushB_spdiaochan"] = "MK·☆SP貂蝉",
	["&rushB_spdiaochan"] = "MK貂蝉",
	["#rushB_spdiaochan"] = "驭身控魂",
	["designer:rushB_spdiaochan"] = "俺的西木野Maki",
	["cv:rushB_spdiaochan"] = "官方",
	["illustrator:rushB_spdiaochan"] = "魔奇士",
	["rushB_lihun"] = "离魂",
	["rushb_lihun"] = "离魂",
    [":rushB_lihun"] = "出牌阶段限一次，你可以弃置一张牌将武将牌翻面，并选择一名其他角色：若如此做，你获得该角色区域内的所有牌，且出牌阶段结束时，你交给该角色X张牌。（X为该角色的体力值）",
	["rushB_lihunGoBack"] = "[离魂]请返还给%src%arg张牌",
	["$rushB_lihun1"] = "将军，人家空虚寂寞冷嘛。",
	["$rushB_lihun2"] = "哎呀，大人莫走，再陪陪妾身嘛。",
	["~rushB_spdiaochan"] = "此生多的是身不由己，待来世再结真心......",
}
---------------------------------
rushB_zhouyu = sgs.General(extension, "rushB_zhouyu", "wu", 3)
rushB_fanjianCard = sgs.CreateSkillCard{
	name = "rushB_fanjian",
	target_fixed = false,
	will_throw = false,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		local subid = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(subid)
		local card_id = card:getEffectiveId()
		local suit = room:askForSuit(target, "rushB_fanjian")
		room:getThread():delay()
		room:showCard(source, card_id)
		if card:getSuit() ~= suit then
		    room:throwCard(self, source, nil)
			local damage = sgs.DamageStruct()
			damage.card = nil
			damage.from = source
			damage.to = target
			room:damage(damage)
		else
		    room:obtainCard(target, self, false)
		    room:loseHp(target, 1, true, source, self:objectName())
		end
	end,
}
rushB_fanjian = sgs.CreateViewAsSkillV2{
	name = "rushB_fanjian",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:isKongcheng() then
			return not player:hasUsed("#rushB_fanjian") and not player:hasUsed("rushB_fanjian")
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		return candidate and request:getSelectedCardIds():length() < 1 and not candidate:isEquipped()
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = rushB_fanjianCard:clone()
		card:addSubcard(ids:first())
		return card
	end,
}
rushB_zhouyu:addSkill("yingzi")
rushB_zhouyu:addSkill(rushB_fanjian)
sgs.LoadTranslationTable{
	["rushB_zhouyu"] = "MK周瑜",
	["#rushB_zhouyu"] = "雄姿英发",
	["designer:rushB_zhouyu"] = "俺的西木野Maki",
	["cv:rushB_zhouyu"] = "官方",
	["illustrator:rushB_zhouyu"] = "魔奇士",
	["rushB_fanjian"] = "反间",
	["rushb_fanjian"] = "反间",
	[":rushB_fanjian"] = "出牌阶段限一次，你可以选择一张手牌，令一名其他角色说出一种花色后展示之，若猜错则弃置此牌并对其造成1点伤害，若猜对则其获得此牌并失去1点体力。",
	["$rushB_fanjian1"] = "巧施间策，敌自乱矣。",
	["$rushB_fanjian2"] = "以真真假假之计，乱敌心智。",
	["~rushB_zhouyu"] = "吴国未兴，我怎能死......",
}
---------------------------------
rushB_mateng = sgs.General(extension, "rushB_mateng", "qun")
rushB_xiongyiCard = sgs.CreateSkillCard{
	name = "rushB_xiongyi",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < self:getSubcards():length() and to_select:objectName() ~= player:objectName()
	end,
	feasible = function(self, targets, player)
		return #targets > 0--== self:getSubcards():length()
	end,
	on_use = function(self, room, source, targets)
		--[[for _, p in sgs.qlist(targets) do
		    room:obtainCard(p, self:getSubcards():first(), false)
			targets:removeOne(p)
		end]]
		local suijigives = {}
		for _, c in sgs.qlist(self:getSubcards()) do
			table.insert(suijigives, c)
		end
		for _, p in pairs(targets) do
			local random_card = suijigives[math.random(1, #suijigives)]
			room:obtainCard(p, random_card, false)
			table.removeOne(suijigives, random_card)
		end
		source:drawCards(self:getSubcards():length())
	end,
}
rushB_xiongyivs = sgs.CreateViewAsSkillV2{
	name = "rushB_xiongyi",
	n = 999,
	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return false
		end
		return string.startsWith(request:getPattern(), "@@rushB_xiongyi")
	end,
	can_select_card = function(skill, request, candidate)
		return candidate ~= nil
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() > 0 then
			local skillcard = rushB_xiongyiCard:clone()
			for _, c in sgs.qlist(ids) do
				skillcard:addSubcard(c)
			end
			return skillcard
		end
	end,
}
rushB_xiongyi = sgs.CreateTriggerSkillV2{
	name = "rushB_xiongyi",
	--global = true,
	events = {sgs.EventPhaseStart},
	view_as_skill = rushB_xiongyivs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
			    if not room:askForUseCard(player, "@@rushB_xiongyi", "@rushB_xiongyi") then return false end
			end
		end
		return false
	end,
}
rushB_mateng:addSkill(rushB_xiongyi)
rushB_mateng:addSkill("mashu")
sgs.LoadTranslationTable{
	["rushB_mateng"] = "MK马腾",
	["#rushB_mateng"] = "马足龙沙",
	["designer:rushB_mateng"] = "俺的西木野Maki",
	["cv:rushB_mateng"] = "官方",
	["illustrator:rushB_mateng"] = "君桓文化",
	["rushB_xiongyi"] = "雄异",
	["rushb_xiongyi"] = "雄异",
	--[":rushB_xiongyi"] = "回合开始时，你可以选择任意张牌然后选择等量名其他角色，这些角色依次获得你以此法交出的第一张牌，然后你摸等量的牌。",
	[":rushB_xiongyi"] = "回合开始时，你可以选择任意张牌然后选择等量名其他角色，这些角色随机获得你以此法选择的其中一张牌，然后你摸等量的牌。",
	["@rushB_xiongyi"] = "你可以发动“雄异”：选择任意张牌->选择等量名其他角色",
	["$rushB_xiongyi1"] = "是时候出击了！",
	["$rushB_xiongyi2"] = "兄弟们，冲啊！",
	["~rushB_mateng"] = "吾儿，勿忘父仇......",
}
---------------------------------
diy_f_spmachao = sgs.General(extension, "diy_f_spmachao", "qun")
diy_f_zhuijiCard = sgs.CreateSkillCard{
	name = "diy_f_zhuiji",
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	feasible = function(self, targets, player)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local n, damage = math.random(1, 4), nil
		if n == 1 then damage = sgs.DamageStruct_Normal end
		if n == 2 then damage = sgs.DamageStruct_Ice end
		if n == 3 then damage = sgs.DamageStruct_Thunder end
		if n == 4 then damage = sgs.DamageStruct_Fire end
		room:damage(sgs.DamageStruct(self:objectName(), source, targets[1], 1, damage))
	end,
}
diy_f_zhuijivs = sgs.CreateViewAsSkillV2{
	name = "diy_f_zhuiji",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:isNude()
	end,
	can_select_card = function(skill, request, candidate)
		return candidate ~= nil and request:getSelectedCardIds():length() < 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local skillcard = diy_f_zhuijiCard:clone()
		for _, c in sgs.qlist(ids) do
			skillcard:addSubcard(c)
		end
		skillcard:setSkillName(skill:objectName())
		return skillcard
	end,
}
diy_f_zhuiji = sgs.CreateTriggerSkillV2{
	name = "diy_f_zhuiji",
	--global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage},
	view_as_skill = diy_f_zhuijivs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local damage = data:toDamage()
		local n = damage.damage
		if damage.from:objectName() ~= damage.to:objectName() and damage.from:hasSkill(skill:objectName()) then
			if n > 0 then
				room:sendCompulsoryTriggerLog(damage.from, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName(), math.random(1, 3))
				room:addPlayerMark(damage.to, "&".."diy_f_zhuiji".."-Clear")
			else
				room:sendCompulsoryTriggerLog(damage.from, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName(), 4)
			end
		end
	end,
}
diy_f_zhuijiDis = sgs.CreateDistanceSkillV2{
	name = "#diy_f_zhuijiDis",
	frequency = sgs.Skill_Compulsory,
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(self, ctx)
		local from = ctx:getPrimary()
		local to = ctx:getSecondary()
		if from:hasSkill("diy_f_zhuiji") and to:getMark("&".."diy_f_zhuiji".."-Clear") > 0 then
			return -to:getMark("&".."diy_f_zhuiji".."-Clear")
		end
	end,
}
diy_f_xionglieCard = sgs.CreateSkillCard{
	name = "diy_f_xionglie",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and not to_select:isNude()
	end,
	feasible = function(self, targets, player)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local id = room:askForCardChosen(source, targets[1], "he", self:objectName())
		room:obtainCard(source, id)
		local n, damage = math.random(1, 4), nil
		if n == 1 then damage = sgs.DamageStruct_Normal end
		if n == 2 then damage = sgs.DamageStruct_Ice end
		if n == 3 then damage = sgs.DamageStruct_Thunder end
		if n == 4 then damage = sgs.DamageStruct_Fire end
		room:damage(sgs.DamageStruct(self:objectName(), targets[1], source, 1, damage))
	end,
}
diy_f_xionglievs = sgs.CreateViewAsSkillV2{
	name = "diy_f_xionglie",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return false
		end
		for _, sib in sgs.qlist(player:getSiblings()) do
			if not sib:isNude() then return true end
		end
		return false
	end,
	create_card = function(skill, request)
		local skillcard = diy_f_xionglieCard:clone()
		skillcard:setSkillName(skill:objectName())
		return skillcard
	end,
}
diy_f_xionglie = sgs.CreateTriggerSkillV2{
	name = "diy_f_xionglie",
	--global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged},
	view_as_skill = diy_f_xionglievs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local damage = data:toDamage()
		local n = damage.damage
		if damage.from:objectName() ~= damage.to:objectName() and damage.to:hasSkill(skill:objectName()) then
			if n > 0 then
				room:sendCompulsoryTriggerLog(damage.to, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName(), math.random(1, 3))
				room:addPlayerMark(damage.from, "&".."diy_f_xionglie".."-Clear")
			else
				room:sendCompulsoryTriggerLog(damage.to, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName(), 4)
			end
		end
	end,
}
diy_f_xionglieDis = sgs.CreateDistanceSkillV2{
	name = "#diy_f_xionglieDis",
	frequency = sgs.Skill_Compulsory,
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(self, ctx)
		local from = ctx:getPrimary()
		local to = ctx:getSecondary()
		if to:hasSkill("diy_f_xionglie") and from:getMark("&".."diy_f_xionglie".."-Clear") > 0 then
			return from:getMark("&".."diy_f_xionglie".."-Clear")
		end
		if from:hasSkill("diy_f_zhuiji") and to:getMark("&".."diy_f_zhuiji".."-Clear") > 0 then
			return -to:getMark("&".."diy_f_zhuiji".."-Clear")
		end
	end,
}
spmachaoAudio = sgs.CreateTriggerSkillV2{
	name = "#spmachaoAudio",
	events = {sgs.PreCardUsed, sgs.CardUsed},
	priority = 1,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local skill = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n
				if skill == "diy_f_zhuiji" then
					room:broadcastSkillInvoke(skill, math.random(1, 3))
					return true
				end
				if skill == "diy_f_xionglie" then
					room:broadcastSkillInvoke(skill, 4)
					return true
				end
			end
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
		    if use.m_addHistory and player:hasSkill("diy_f_zhuiji") then
			    room:addPlayerHistory(player, use.card:getClassName(), -1)
			end
		end
	end,
}
diy_f_zhuijiUse = sgs.CreateTargetModSkillV2{
	name = "#diy_f_zhuijiUse",
	frequency = sgs.Skill_Compulsory,
	pattern = "^SkillCard",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(self, ctx)
		local modType = ctx:getModType()
		if modType ~= sgs.TargetModSkill_Residue and modType ~= sgs.TargetModSkill_DistanceLimit then
			return nil
		end
		local from = ctx:getPrimary()
		local to = ctx:getSecondary()
		if from:hasSkill("diy_f_zhuiji") and to and to:getMark("&".."diy_f_zhuiji".."-Clear") > 0 then
			return 1000
		else
			return 0
		end
	end,
}
diy_f_spmachao:addSkill(diy_f_zhuiji)
diy_f_spmachao:addSkill(diy_f_zhuijiUse)
diy_f_spmachao:addSkill(diy_f_zhuijiDis)
extension:insertRelatedSkills("diy_f_zhuiji", "#diy_f_zhuijiUse")
extension:insertRelatedSkills("diy_f_zhuiji", "#diy_f_zhuijiDis")
diy_f_spmachao:addSkill(diy_f_xionglie)
diy_f_spmachao:addSkill(diy_f_xionglieDis)
extension:insertRelatedSkills("diy_f_xionglie", "#diy_f_xionglieDis")
diy_f_spmachao:addSkill(spmachaoAudio)
sgs.LoadTranslationTable{
	["diy_f_spmachao"] = "MK·sp马超", ["&diy_f_spmachao"] = "MK马超",
	["#diy_f_spmachao"] = "西凉雄狮",
	["designer:diy_f_spmachao"] = "俺的西木野Maki",
	["cv:diy_f_spmachao"] = "官方",
	["illustrator:diy_f_spmachao"] = "极略三国",
	["diy_f_zhuiji"] = "追击",
--	[":secondsr_zhuiji"] = "锁定技，当你对其他角色造成伤害后，你令你与其的距离-1。",
	[":diy_f_zhuiji"] = "锁定技，当你造成伤害后，你计算与目标的距离-1，你对以此法造成伤害的角色使用牌无次数、距离限制且此牌不计入使用次数。出牌阶段，你可以弃置一张牌，对一名其他角色造成1点伤害。",
	["$diy_f_zhuiji1"] = "听我号令，骑兵尽出，袭杀曹贼！",
	["$diy_f_zhuiji2"] = "铁枪横扫之处，尔等断无残生之机！",
	["$diy_f_zhuiji3"] = "鸾铃到处，敌皆破胆！",
	["$diy_f_zhuiji4"] = "战机已失，速速回营！",
	["diy_f_xionglie"] = "雄烈",
	["damageadd"] = "伤害+1",
	["notusejink"] = "不能使用【闪】",
--	[":sr_xionglie"] = "当你使用【杀】指定目标后，你可以选择一项：1.令此【杀】不能被【闪】响应；2.令此【杀】的伤害+1若你与所有其他角色的距离为1，改为依次执行两项。",
	[":diy_f_xionglie"] = "锁定技，当你受到伤害后，伤害来源计算与你的距离+1。出牌阶段，你可以获得其他角色一张牌，令该角色对你造成1点伤害。",
	["$diy_f_xionglie1"] = "厉马秣兵，只待今日！",
	["$diy_f_xionglie2"] = "敌军防备空虚，出击直取敌营！",
	["$diy_f_xionglie3"] = "敌军早有防备，先行扰阵疲敌！",
	["$diy_f_xionglie4"] = "全军速撤回营，以期再觅良机！",
	["~diy_f_spmachao"] = "父兄妻儿俱丧，吾有何面目活于世间......",
}
---------------------------------
diy_k_wangji = sgs.General(extension, "diy_k_wangji", "wei")
diy_k_qizhi = sgs.CreateTriggerSkillV2{
	name = "diy_k_qizhi",
	--global = true,
	events = {sgs.CardUsed, sgs.CardResponded},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and not card:isKindOf("SkillCard") then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
		        if not p:isNude() then
					targets:append(p)
				end
			end
			if targets:length() > 0 then
				local target = room:askForPlayerChosen(player, targets, skill:objectName(), "qizhi-invoke", true, true)
				if target then
					room:broadcastSkillInvoke(skill:objectName())
					room:addPlayerMark(player, "&qizhi-Clear")
					room:addPlayerMark(player, skill:objectName().."engine")
					if player:getMark(skill:objectName().."engine") > 0 then
					    local card_id = nil
						if not target:isNude() then card_id = "he" end
						if not target:isKongcheng() and target:getEquips():isEmpty() then card_id = "h" end
						if target:isKongcheng() and not target:getEquips():isEmpty() then card_id = "e" end
						local id = room:askForCardChosen(player, target, card_id, skill:objectName())
						room:throwCard(id, target, nil)
						if room:getCurrent():objectName() == target:objectName() then
						    target:drawCards(2, skill:objectName())
						else
						    target:drawCards(1, skill:objectName())
				        end
						room:removePlayerMark(player, skill:objectName().."engine")
					end
				end
			end
		end
		return false
	end,
}
diy_k_jinqu = sgs.CreateTriggerSkillV2{
	name = "diy_k_jinqu",
	--global = true,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:getPhase() == sgs.Player_Finish) then return false end
		local names, objs = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			table.insert(names, skill:objectName())
			table.insert(objs, p:objectName())
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(objs, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		local splayer = player
	    if not room:askForSkillInvoke(splayer, skill:objectName()) then return false end
		room:broadcastSkillInvoke(skill:objectName())
		room:addPlayerMark(splayer, skill:objectName().."engine")
		if splayer:getMark(skill:objectName().."engine") > 0 then
			splayer:drawCards(2, skill:objectName())
			local n = splayer:getHandcardNum() + splayer:getEquips():length() - splayer:getMark("&qizhi-Clear")
			if n > 0 and target and target:objectName() == splayer:objectName() then
				room:askForDiscard(splayer, skill:objectName(), n, n, false, true)
			end
			room:removePlayerMark(splayer, skill:objectName().."engine")
		end
		return false
	end,
}
diy_k_wangji:addSkill(diy_k_qizhi)
diy_k_wangji:addSkill(diy_k_jinqu)
sgs.LoadTranslationTable{
	["diy_k_wangji"] = "MK王基",
	["#diy_k_wangji"] = "经行合一",
	["designer:diy_k_wangji"] = "俺的西木野Maki",
	["cv:diy_k_wangji"] = "官方",
	["illustrator:diy_k_wangji"] = "官方",
	["diy_k_qizhi"] = "奇制",
	[":diy_k_qizhi"] = "当你使用/打出牌后，你可以选择一名有牌的角色，令其弃置一张牌并摸一张牌。若以此法选择的角色为当前回合角色，则其改为摸两张牌。",
	["$diy_k_qizhi1"] = "声东击西，敌寇一网成擒！",
	["$diy_k_qizhi2"] = "吾意不在此地，已遣别部出发。",
	["diy_k_jinqu"] = "进趋",
	[":diy_k_jinqu"] = "每名角色的结束阶段开始时，你可以摸两张牌，然后若当前为你的回合，则你弃置X张牌。（X为你于此回合内发动“奇制”的次数）",
	["$diy_k_jinqu1"] = "建上昶水城，以逼夏口！",
	["$diy_k_jinqu2"] = "通川聚粮，伐吴之业，当步步为营。",
	["~diy_k_wangji"] = "天下之势，必归大魏，可恨，未能得见了。",
}
---------------------------------
diy_k_zhaoxiang = sgs.General(extension, "diy_k_zhaoxiang", "shu", 4, false)
diy_k_fanghunvs = sgs.CreateViewAsSkillV2{
	name = "diy_k_fanghun",
	n = 1,
	mute = true,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or player:getMark("&diy_k_meiying") <= 0 then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return sgs.Slash_IsAvailable(player) or sgs.Analeptic_IsAvailable(player)
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
				or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern()
			return pattern == "slash" or pattern == "jink" or pattern == "analeptic"
				or (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach")))
		end
		return false
	end,
	can_select_card = function(skill, request, to_select)
		local selected = request:getSelectedCardIds()
		if (selected:length() > 1) or to_select:hasFlag("using") then return false end
		if selected:length() > 0 then
			return to_select:getSuit() == sgs.Sanguosha:getCard(selected:at(0)):getSuit()
		end
		if not (to_select:isKindOf("Analeptic") or to_select:isKindOf("Jink") or to_select:isKindOf("Peach") or to_select:isKindOf("Slash")) then return false end
		local player = request:getInitiator()
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if player:isWounded() or (to_select:isKindOf("Analeptic")) then
				return true
			elseif sgs.Slash_IsAvailable(player) and to_select:isKindOf("Jink") then
				return true
			elseif sgs.Analeptic_IsAvailable(player) and to_select:isKindOf("Peach") then
				return true
			else
				return false
			end
		elseif (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
				or (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = request:getPattern()
			if pattern == "slash" then
			    return to_select:isKindOf("Jink")
			elseif pattern == "jink" then
			    return to_select:isKindOf("Slash")
			elseif string.find(pattern, "peach") then
			    return to_select:isKindOf("Analeptic")
			elseif string.find(pattern, "analeptic") or pattern == "analeptic" then
				return to_select:isKindOf("Peach")
			end
			return false
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = sgs.Sanguosha:getCard(ids:at(0))
		local new_card = nil
		if card:isKindOf("Peach") then
			new_card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_SuitToBeDecided, 0)
		elseif card:isKindOf("Slash") then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		elseif card:isKindOf("Analeptic") then
			new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, 0)
		elseif card:isKindOf("Jink") then
			new_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			new_card:setSkillName(skill:objectName())
			for _, c in sgs.qlist(ids) do
				new_card:addSubcard(c)
			end
		end
		return new_card
	end,
}
diy_k_fanghun = sgs.CreateTriggerSkillV2{
	name = "diy_k_fanghun",
	view_as_skill = diy_k_fanghunvs,
	events = {sgs.TargetConfirmed, sgs.CardUsed, sgs.PreCardUsed, sgs.CardResponded},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
	    if event == sgs.TargetConfirmed then
		    local use = data:toCardUse()
		    if use.from:objectName() == player:objectName() or use.to:contains(player) then
			    if use.card:isKindOf("Slash") then
				    room:sendCompulsoryTriggerLog(player, skill:objectName())
				    room:broadcastSkillInvoke(skill:objectName(), math.random(1, 2))
				    player:gainMark("&diy_k_meiying")
				end
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local card_skill = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n
				if card_skill == skill:objectName() then
					room:broadcastSkillInvoke(skill:objectName(), math.random(1, 2))
					return true
				end
			end
		else
			local card = nil
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and card:getSkillName() == skill:objectName() then
			    player:loseMark("&diy_k_meiying")
				player:drawCards(1)
			end
		end
		return false
	end,
}
diy_k_fuhan = sgs.CreateTriggerSkillV2{
	name = "diy_k_fuhan",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Limited,
	limit_mark = "@fuhan",
	waked_skills = "diy_k_queshi",
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local x, n = player:getMark("&diy_k_meiying"), 0
		n = math.min(8, x)
		n = math.max(2, x)
		if player:getPhase() == sgs.Player_RoundStart and x > 0 and player:getMark("@fuhan") > 0 and room:askForSkillInvoke(player, skill:objectName()) then
			room:broadcastSkillInvoke(skill:objectName())
			room:addPlayerMark(player, skill:objectName().."engine")
			if player:getMark(skill:objectName().."engine") > 0 then
				room:removePlayerMark(player, "@fuhan")
				player:loseAllMarks("&diy_k_meiying")
				local fuhans = {}
				local fuhan = {}
				for _,name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
					if sgs.Sanguosha:getGeneral(name):getKingdom() == "shu" then
						table.insert(fuhans, name)
					end
				end
				for _,p in sgs.qlist(room:getAllPlayers(true)) do
					if table.contains(fuhans, p:getGeneralName()) then
						table.removeOne(fuhans, p:getGeneralName())
					end
				end
				for i = 1, 5 do
					local first = fuhans[math.random(1, #fuhans)]
					table.insert(fuhan, first)
					table.removeOne(fuhans, first)
				end
				local general = room:askForGeneral(player, table.concat(fuhan, "+"))
				local skills = sgs.Sanguosha:getGeneral(general):getVisibleSkillList()
			    for _,oneskill in sgs.qlist(skills) do
				    room:acquireSkill(player, oneskill:objectName())
			    end
				room:setPlayerProperty(player, "maxhp", sgs.QVariant(n))
				room:recover(player, sgs.RecoverStruct(player))
				room:acquireSkill(player, "diy_k_queshi")
				room:removePlayerMark(player, skill:objectName().."engine")
			end
		end
		return false
	end,
}
diy_k_queshi = sgs.CreateTargetModSkillV2{
	name = "diy_k_queshi",
	frequency = sgs.Skill_Compulsory,
	pattern = "^SkillCard",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local modType = ctx:getModType()
		if modType ~= sgs.TargetModSkill_Residue and modType ~= sgs.TargetModSkill_DistanceLimit then
			return nil
		end
		local from = ctx:getPrimary()
		local card = ctx:getCard()
		if from:hasSkill(skill:objectName()) and card and table.contains(card:getSkillNames(), "diy_k_fanghun") then
			return 1000
		else
			return 0
		end
	end,
}
diy_k_queshii = sgs.CreateTriggerSkillV2{
	name = "#diy_k_queshii",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill("diy_k_queshi") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local move = data:toMoveOneTime()
		if move.from == nil then return false end
		if move.to_place == sgs.Player_DiscardPile then
			local card_ids = sgs.IntList()
			for _, card_id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(card_id):isKindOf("BasicCard") then
					card_ids:append(card_id)
				end
			end
			if not card_ids:isEmpty() then
				room:sendCompulsoryTriggerLog(player, "diy_k_queshi")
				room:broadcastSkillInvoke("diy_k_queshi", math.random(1, 2))
				for _, id in sgs.qlist(card_ids) do
					room:obtainCard(player, sgs.Sanguosha:getCard(id), true)
				end
			end
		end
		return false
	end,
}
diy_k_zhaoxiang:addSkill(diy_k_fanghun)
diy_k_zhaoxiang:addSkill(diy_k_fuhan)
if not sgs.Sanguosha:getSkill("diy_k_queshi") then skills:append(diy_k_queshi) end
if not sgs.Sanguosha:getSkill("diy_k_queshii") then skills:append(diy_k_queshii) end
extension:insertRelatedSkills("diy_k_queshi", "#diy_k_queshii")
sgs.LoadTranslationTable{
	["diy_k_zhaoxiang"] = "MK赵襄",
	["#diy_k_zhaoxiang"] = "拾梅鹊影",
	["designer:diy_k_zhaoxiang"] = "官方(国际服)",
	["cv:diy_k_zhaoxiang"] = "官方",
	["illustrator:diy_k_zhaoxiang"] = "官方",
	["diy_k_fanghun"] = "芳魂",
	["diy_k_meiying"] = "梅影",
	[":diy_k_fanghun"] = "当你使用【杀】指定目标后或成为【杀】的目标后，你获得1个“梅影”标记；你可以移去1个“梅影”标记来发动”龙胆”并摸一张牌。",
	["$diy_k_fanghun1"] = "万花凋落尽，一梅独傲霜。",
	["$diy_k_fanghun2"] = "暗香疏影处，凌风踏雪来。",
	["diy_k_fuhan"] = "扶汉",
	[":diy_k_fuhan"] = "限定技，回合开始时，你可以移去所有“梅影”标记，然后从五张未登场的蜀势力武将牌中选择一名并获得其所有技能，并将体力上限数调整为以此技能移去所有“梅影”标记的数量（至少2至多8），回复1点体力并获得技能“鹊拾”。",
	["$diy_k_fuhan1"] = "承先父之志，扶汉兴刘。",
	["$diy_k_fuhan2"] = "天将降大任于我！",
	["diy_k_queshi"] = "鹊拾",
--	[":diy_k_queshi"] = "游戏开始时，你将【银月枪】置于你的装备区。当你发动“扶汉”后，你从场上、牌堆、弃牌堆中获得【银月枪】。",
	[":diy_k_queshi"] = "锁定技，当基本牌进入弃牌堆时，你获得之；你使用“芳魂”转化的牌无次数和距离限制。",
	["$diy_k_queshi1"] = "",
	["$diy_k_queshi2"] = "",
	["~diy_k_zhaoxiang"] = "遁入阴影之中......",
}
---------------------------------
diy_k_xunyou = sgs.General(extension, "diy_k_xunyou", "wei", 3)
diy_k_qiceCard = sgs.CreateSkillCard{
	name = "diy_k_qice",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		local card = player:getTag("diy_k_qice"):toCard()
		card:addSubcards(player:getHandcards())
		card:setSkillName(self:objectName())
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, player) 
			and not player:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets, player)
		local card = player:getTag("diy_k_qice"):toCard()
		card:addSubcards(player:getHandcards())
		card:setSkillName(self:objectName())
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, player)
	end,	
	on_validate = function(self, card_use)
		local xunyou = card_use.from
		local room = xunyou:getRoom()
		room:addPlayerMark(xunyou, self:objectName().."-SelfPlayClear")
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString())
		use_card:addSubcards(xunyou:getHandcards())
		use_card:setSkillName(self:objectName())
		local available = true
		for _,p in sgs.qlist(card_use.to) do
			if xunyou:isProhibited(p,use_card)	then
				available = false
				break
			end
		end
		available = available and use_card:isAvailable(xunyou)
		if not available then return nil end
		return use_card		
	end,
}
diy_k_qice = sgs.CreateViewAsSkillV2{
	name = "diy_k_qice",
	n = 0,
	guhuo_type = "r",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark(skill:objectName().."-SelfPlayClear") < 1 and not player:isKongcheng()
	end,
	create_card = function(skill, request)
		local name = request:getUserString()
		if (not name) or name == "" then
			local player = request:getInitiator()
			local c = player and player:getTag("diy_k_qice"):toCard()
			if c then name = c:objectName() end
		end
		if name and name ~= "" then
			local card = diy_k_qiceCard:clone()
			card:setUserString(name)
			return card
		end
		return nil
	end,
}
diy_k_zhiyu = sgs.CreateTriggerSkillV2{
	name = "diy_k_zhiyu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.Damaged then
		    local damage = data:toDamage()
			room:sendCompulsoryTriggerLog(player, skill)
			local n = 0
			while n < damage.damage do
			    player:drawCards(2)
				n = n + 1
			end
		else
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(), "diy_k_qice") then
			    room:sendCompulsoryTriggerLog(player, skill)
				player:drawCards(math.random(0,2))
				room:removePlayerMark(player, use.card:getSkillName().."-SelfPlayClear")
			end
		end
	end,
}
diy_k_xunyou:addSkill(diy_k_qice)
diy_k_xunyou:addSkill(diy_k_zhiyu)
diy_k_qice:setGuhuoDialog("r")
sgs.LoadTranslationTable{
	["diy_k_xunyou"] = "MK荀攸",
	["#diy_k_xunyou"] = "十二奇策",
	["designer:diy_k_xunyou"] = "俺的西木野Maki",
	["cv:diy_k_xunyou"] = "官方",
	["illustrator:diy_k_xunyou"] = "Thinking",
	["diy_k_qice"] = "奇策",
    [":diy_k_qice"] = "出牌阶段限一次，你可以将所有手牌（至少一张）当任意一张非延时类锦囊牌使用。",
	["$diy_k_qice1"] = "奇策十二，可挽狂澜。",
	["$diy_k_qice2"] = "我，还有一计。",
	["diy_k_zhiyu"] = "智愚",
	[":diy_k_zhiyu"] = "锁定技，每当你受到1点伤害后，你摸两张牌。当你使用“奇策”结算完成时，你摸0~2张牌，然后令“奇策”视为未使用过。",
	["$diy_k_zhiyu1"] = "大象无形，大盈若冲。",
	["$diy_k_zhiyu2"] = "藏巧于拙，以屈为伸。",
	["~diy_k_xunyou"] = "世事如棋局，你我皆不过是棋子罢了。",
}
---------------------------------
diy_f_kongrong = sgs.General(extension, "diy_f_kongrong", "qun", 3)
diy_f_mingshi = sgs.CreateTriggerSkillV2{
	name = "diy_f_mingshi",
	events = {sgs.DamageInflicted},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local damage = data:toDamage()
		local mingshi1, mingshi2 = false, false
		if damage.from then
			if not damage.from:faceUp() and player:faceUp() then
			    mingshi1 = true
			end
			if damage.from:faceUp() and not player:faceUp() then
			    mingshi2 = true
			end
			if mingshi1 or mingshi2 then
		        room:sendCompulsoryTriggerLog(player, skill)
				damage.damage = damage.damage - 1
				if damage.damage < 1 then
					damage.prevented = true
					data:setValue(damage)
					return true
				end
				data:setValue(damage)
			end
		end
		return false
	end,
}
diy_f_lirang = sgs.CreateTriggerSkillV2{
	name = "diy_f_lirang",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards, sgs.AfterDrawNCards},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local draw = data:toDraw()
        if draw.reason ~= "draw_phase" then return false end
		if event == sgs.DrawNCards then
		    local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:faceUp() then
					players:append(p)
				end
			end
		    local target = room:askForPlayerChosen(player, players, skill:objectName(), "@choose-players", true, true)
			if target then
			    room:broadcastSkillInvoke(skill:objectName(), 1)
				room:setPlayerFlag(target, skill:objectName())
				local lose_num = {}
			    for i = 1, data:toInt() do
				    table.insert(lose_num, tostring(i))
			    end
				local choice = room:askForChoice(player, skill:objectName(), table.concat(lose_num, "+"))
			    local count = data:toInt() - tonumber(choice)
			    data:setValue(count)
				target:drawCards(tonumber(choice))
			end
		else
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasFlag(skill:objectName()) then
					targets:append(p)
				end
			end
			if not targets:isEmpty() and room:askForChoice(player, "@lirangobtain", "yes+no") == "yes" then
		        room:sendCompulsoryTriggerLog(player, skill, 2)
			    for _, p in sgs.qlist(targets) do
				    room:setPlayerFlag(p, "-"..skill:objectName())
				    p:turnOver()
				end
			end
		end
	end,
}
diy_f_kongrong:addSkill(diy_f_mingshi)
diy_f_kongrong:addSkill(diy_f_lirang)
sgs.LoadTranslationTable{
	["diy_f_kongrong"] = "MK孔融",
	["#diy_f_kongrong"] = "凛然重义",
	["designer:diy_f_kongrong"] = "俺的西木野Maki",
	["cv:diy_f_kongrong"] = "官方",
	["illustrator:diy_f_kongrong"] = "佚名",
	["diy_f_mingshi"] = "名士",
	[":diy_f_mingshi"] = "锁定技，当你受到伤害时，若来源的“翻面”状态与你不同，你令伤害值-1。",
	["$diy_f_mingshi1"] = "孔门之后，忠孝为先。",
	["$diy_f_mingshi2"] = "名士之风，仁义高洁。",
	["diy_f_lirang"] = "礼让",
	["@lirangobtain"] = "是否令一名目标获得“礼让”牌",
	["@lirangfaceup"] = "是否让获得“礼让”牌的目标翻面",
	[":diy_f_lirang"] = "你可以选择一名正面朝上的其他角色，然后于摸牌阶段摸牌时少摸任意张牌并以此法选择的角色摸等量张牌，然后选择是否令以此法选择的角色翻面。",
	["$diy_f_lirang1"] = "夫礼先王以承天之道，以治人之情。",
	["$diy_f_lirang2"] = "谦者，德之柄也，让者，礼之逐也。",
	["~diy_f_kongrong"] = "覆巢之下，岂有完卵……",
}
---------------------------------
diy_k_liuzan = sgs.General(extension, "diy_k_liuzan", "wu")
diy_k_fenyin = sgs.CreateTriggerSkillV2{
    name = "diy_k_fenyin",
	--global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardResponded},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local card
		local fenyin = false
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card then
			local n = card:getNumber()
			if (card:isVirtualCard() or card:isKindOf("SkillCard")) and (n == nil or n < 1) then n = 1 end
			if card:isRed() and (player:getMark("&".."fenyin".."colorblack".."-Clear") > 0 or player:getMark("&".."fenyin".."colorred".."-Clear") > 0) then
		    	if player:getMark("&".."fenyin".."colorblack".."-Clear") > 0 then
				    fenyin = true
				end
			    room:setPlayerMark(player, "&".."fenyin".."colorblack".."-Clear", 0)
			elseif card:isBlack() and (player:getMark("&".."fenyin".."colorblack".."-Clear") > 0 or player:getMark("&".."fenyin".."colorred".."-Clear") > 0) then
		    	if player:getMark("&".."fenyin".."colorred".."-Clear") > 0 then
				    fenyin = true
				end
			    room:setPlayerMark(player, "&".."fenyin".."colorred".."-Clear", 0)
			end
			if card:getNumber() == player:getMark("&".."fenyin".."number".."-Clear") or fenyin then
			    room:sendCompulsoryTriggerLog(player, skill)
				player:drawCards(1)
			end
			room:setPlayerMark(player, "&".."fenyin".."number".."-Clear", n)
			if card:isRed() then
		    	room:setPlayerMark(player, "&".."fenyin".."colorred".."-Clear", 1)
			elseif card:isBlack() then
		    	room:setPlayerMark(player, "&".."fenyin".."colorblack".."-Clear", 1)
			end
		end
		if card:isKindOf("Slash") then
		    room:addPlayerHistory(player, card:getClassName(), -1)
		end
	end,
}
diy_k_liuzan:addSkill(diy_k_fenyin)
sgs.LoadTranslationTable{
	["diy_k_liuzan"] = "MK留赞",
	["#diy_k_liuzan"] = "啸天亢音",
	["designer:diy_k_liuzan"] = "俺的西木野Maki",
	["cv:diy_k_liuzan"] = "官方",
	["illustrator:diy_k_liuzan"] = "官方",
	["diy_k_fenyin"] = "奋音",
	["fenyinnumber"] = "奋音点数",
	["fenyincolorblack"] = "奋音黑色",
	["fenyincolorred"] = "奋音红色",
	[":diy_k_fenyin"] = "锁定技，当你使用牌时，若此牌与你于本回合内使用的上一张牌的颜色不同或点数相同，你摸一张牌；你使用【杀】不计入使用次数。",
	["$diy_k_fenyin1"] = "阵前亢歌，以振军心！",
	["$diy_k_fenyin2"] = "吾军杀声震天，则敌心必乱！",
	["~diy_k_liuzan"] = "贼子们，来吧！啊......",
}
---------------------------------
diy_m_wenyang = sgs.General(extension, "diy_m_wenyang", "wei+wu")
diy_m_chuifengCard = sgs.CreateSkillCard{
	name = "diy_m_chuifeng",
	filter = function(self, targets, to_select, player)
		if to_select:objectName() == player:objectName() then return false end
		if #targets == 0 then
			return true
		end
	end,
	feasible = function(self, targets, player)
		return #targets >= 0
	end,
	on_use = function(self, room, source, targets)
		room:loseHp(source, 1, true, source, self:objectName())
		if targets[1] then
			local choice = room:askForChoice(source, self:objectName(), "duel+slash+thunder_slash+ice_slash+fire_slash")
			local card = sgs.Sanguosha:cloneCard(choice)
			card:setSkillName("_diy_m_chuifengg")
			room:broadcastSkillInvoke("diy_m_chuifeng")
			room:addPlayerMark(targets[1], "Armor_Nullified");
			for _,skill in sgs.qlist(targets[1]:getVisibleSkillList()) do
				room:addPlayerMark(targets[1], "Qingcheng"..skill:objectName())
			end
			room:useCard(sgs.CardUseStruct(card, source, targets[1]), false)
			card:deleteLater()
			room:removePlayerMark(targets[1], "Armor_Nullified");
			for _,skill in sgs.qlist(targets[1]:getVisibleSkillList()) do
				room:removePlayerMark(targets[1], "Qingcheng"..skill:objectName())
			end
		else
			local card = sgs.Sanguosha:cloneCard("analeptic")
			card:setSkillName("_diy_m_chuifengg")
			room:broadcastSkillInvoke("diy_m_chuifeng")
			room:useCard(sgs.CardUseStruct(card, source, source), false)
			card:deleteLater()
		end
	end,
}
diy_m_chuifeng = sgs.CreateViewAsSkillV2{
	name = "diy_m_chuifeng",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and (player:getMark("&mwei") > 0 or player:getKingdom() == "wei")
	end,
	create_card = function(skill, request)
		return diy_m_chuifengCard:clone()
	end,
}
diy_m_chongjian = sgs.CreateViewAsSkillV2{
    name = "diy_m_chongjian",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
	    return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and (player:getMark("&mwu") > 0 or player:getKingdom() == "wu")
	end,
	can_select_card = function(skill, request, to_select)
	    return to_select and to_select:isKindOf("EquipCard")
			and request:getSelectedCardIds():isEmpty()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		local new_card
	    if request:getInitiator():getMark("m_miaojian") == 0 and ids:length() == 1 then
		    local card = sgs.Sanguosha:getCard(ids:at(0))
		    if card:isKindOf("Armor") then
		    	new_card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_SuitToBeDecided, 0)
	    	elseif card:isKindOf("Weapon") then
			    new_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
	    	elseif card:isKindOf("DefensiveHorse") then
		    	new_card = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, 0)
	    	elseif card:isKindOf("OffensiveHorse") then
			    new_card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, 0)
	    	elseif card:isKindOf("Treasure") then
			    new_card = sgs.Sanguosha:cloneCard("ice_slash", sgs.Card_SuitToBeDecided, 0)
		    end
		end
		if new_card then
			new_card:setSkillName(skill:objectName())
			for _, c in sgs.qlist(ids) do
				new_card:addSubcard(c)
			end
		end
		return new_card
	end,
}
diy_m_quedi = sgs.CreateTriggerSkillV2{
	name = "diy_m_quedi",
	--global = true,
	priority = 100,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished, sgs.CardUsed, sgs.GameStart, sgs.EventPhaseStart, sgs.TargetSpecifying},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardFinished then
			local use = data:toCardUse()
		    if use.from:objectName() ~= player:objectName() or not (player:hasSkill("diy_m_chuifeng") or player:hasSkill("diy_m_chongjian")) then return false end
			local card_skill = use.card:getSkillName()
			if card_skill == "diy_m_chuifengg" then
				if player:hasSkill("diy_m_chuifeng") and room:askForChoice(player, "diy_m_chuifengask", "yes+no") == "yes" then
				    if player:getMark("&mwei") > 0 then
					    room:setPlayerMark(player, "&mwei", 0)
					    room:setPlayerMark(player, "&mwu", 1)
					else
					    if player:getKingdom() ~= "wei" then return false end
						room:setPlayerProperty(player, "kingdom", sgs.QVariant("wu"))
					end
				end
			end
			if card_skill == "diy_m_chongjian" then
			    for _,p in sgs.qlist(use.to) do
			        room:removePlayerMark(p, "Armor_Nullified");
			        for _,skill in sgs.qlist(p:getVisibleSkillList()) do
				        room:removePlayerMark(p, "Qingcheng"..skill:objectName())
			        end
			    end
			    if player:hasSkill(card_skill) and room:askForChoice(player, "diy_m_chongjianask", "yes+no") == "yes" then
				    if player:getMark("&mwu") > 0 then
					    room:setPlayerMark(player, "&mwu", 0)
					    room:setPlayerMark(player, "&mwei", 1)
					else
					    if player:getKingdom() ~= "wu" then return false end
						room:setPlayerProperty(player, "kingdom", sgs.QVariant("wei"))
					end
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
		    if use.from:objectName() ~= player:objectName() or not (player:hasSkill("diy_m_chuifeng") or player:hasSkill("diy_m_chongjian")) then return false end
			local card_skill = use.card:getSkillName()
			if card_skill == "diy_m_chuifengg" or card_skill == "diy_m_chongjian" or card_skill == "diy_m_choujue" then
			    room:sendCompulsoryTriggerLog(player, skill)
				room:addPlayerHistory(player, use.card:getClassName(), -1)
			end
		elseif event == sgs.TargetSpecifying then
			local use = data:toCardUse()
			local card_skill = use.card:getSkillName()
		    if use.from:objectName() ~= player:objectName() or not player:hasSkill("diy_m_chongjian") or card_skill ~= "diy_m_chongjian" then return false end
			for _,p in sgs.qlist(use.to) do
		        if use.from:objectName() == p:objectName() then return false end
			    room:addPlayerMark(p, "Armor_Nullified");
			    for _,skill in sgs.qlist(p:getVisibleSkillList()) do
				    room:addPlayerMark(p, "Qingcheng"..skill:objectName())
			    end
			end
		elseif event == sgs.GameStart then
		    if player:getGeneralName() == "diy_m_wenyang" or not (player:hasSkill("diy_m_chuifeng") or player:hasSkill("diy_m_chongjian")) or player:getKingdom() == "wu" or player:getKingdom() == "wei" then return false end
			room:sendCompulsoryTriggerLog(player, skill, 1)
			local choice = room:askForChoice(player, "diy_m_wenyang_extrakingdom", "wu+wei")
			room:setPlayerMark(player, "&m"..choice, 1)
		else
		    if player:getPhase() ~= sgs.Player_RoundStart or not (player:hasSkill("diy_m_chuifeng") or player:hasSkill("diy_m_chongjian")) or player:getMark("&mwei") > 0 or player:getMark("&mwu") > 0 or player:getKingdom() == "wu" or player:getKingdom() == "wei" then return false end
		    if player:getGeneralName() == "diy_m_wenyang" then
			    local choice = room:askForChoice(player, "diy_m_wenyang_extrakingdom", "wu+wei")
				room:setPlayerProperty(player, "kingdom", sgs.QVariant(choice))
			else
			    local choice = room:askForChoice(player, "diy_m_wenyang_extrakingdom", "wu+wei")
				room:setPlayerMark(player, "&m"..choice, 1)
			end
		end
	end,
}
diy_m_choujue = sgs.CreateTriggerSkillV2{
	name = "diy_m_choujue",
	--global = true,
	priority = 100,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if data:toPhaseChange().to ~= sgs.Player_NotActive then return false end
		local names, objs = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if math.abs(p:getHandcardNum() - p:getHp()) < 3 or p:objectName() == player:objectName() then continue end
			table.insert(names, skill:objectName())
			table.insert(objs, p:objectName())
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(objs, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		local target = ctx.invoker
		local p = player
		if math.abs(p:getHandcardNum() - p:getHp()) < 3 or p:objectName() == target:objectName() then return false end
		local card = sgs.Sanguosha:cloneCard("slash")
		card:setSkillName("_diy_m_choujue")
		room:addPlayerMark(target, "Armor_Nullified");
		for _,s in sgs.qlist(target:getVisibleSkillList()) do
			room:addPlayerMark(target, "Qingcheng"..s:objectName())
		end
		room:useCard(sgs.CardUseStruct(card, p, target), false)
		card:deleteLater()
		room:removePlayerMark(target, "Armor_Nullified");
		for _,s in sgs.qlist(target:getVisibleSkillList()) do
			room:removePlayerMark(target, "Qingcheng"..s:objectName())
		end
	end,
}
diy_m_wenyang:addSkill(diy_m_quedi)
diy_m_wenyang:addSkill(diy_m_chuifeng)
diy_m_wenyang:addSkill(diy_m_chongjian)
diy_m_wenyang:addSkill(diy_m_choujue)
sgs.LoadTranslationTable{
    ["diy_m_wenyang"] = "MK文鸯",
    ["#diy_m_wenyang"] = "独骑破军",
	["designer:diy_m_wenyang"] = "俺的西木野Maki",
	["cv:diy_m_wenyang"] = "官方",
    ["illustrator:diy_m_wenyang"] = "云涯",
    ["mwu"] = "吴势力",
    ["mwei"] = "魏势力",
    ["diy_m_wenyang_extrakingdom"] = "请选择你的势力",
    ["diy_m_quedi"] = "却敌",
    [":diy_m_quedi"] = "锁定技，游戏开始时，若你的：主将为文鸯，则你选择将势力变更为“吴”或“魏”；副将为文鸯，则你选择获得一个“吴”或“魏”的势力标记。锁定技，回合开始时，若你的势力不为“吴”或“魏”，且你的：主将为文鸯，"..
	"则你选择将势力变更为“吴”或“魏”；副将为文鸯，则你选择获得一个“吴”或“魏”的势力标记。锁定技，你因“椎锋”、“冲坚”、“仇决”使用的牌不计入使用次数且你因“椎锋”、“冲坚”、“仇决”使用牌指定其他角色为目标时无视其防具"..
	"且令其技能无效至此牌结算完成时。",
	["$diy_m_quedi1"] = "力摧敌阵，如视天光破云！",
	["$diy_m_quedi2"] = "让尔等有命追，无命回！",
    ["diy_m_chuifeng"] = "椎锋",
    ["diy_m_chuifengg"] = "椎锋",
    ["diy_m_chuifengask"] = "是否将势力变更为“吴”",
    [":diy_m_chuifeng"] = "魏势力技，你可以失去1点体力，视为对一名其他角色使用一张【决斗】或任一种【杀】或视为使用一张【酒】，然后你可以于结算完成时选择将势力是否变更为“吴”。",
	["$diy_m_chuifeng1"] = "率军冲锋，不惧刀枪所阻！",
	["$diy_m_chuifeng2"] = "登锋履刃，何妨马革裹尸！",
    ["diy_m_chongjian"] = "冲坚",
    ["diy_m_chongjianask"] = "是否将势力变更为“魏”",
    [":diy_m_chongjian"] = "吴势力技，你可以将一张防具牌当【酒】、武器牌当【杀】、防御马当雷【杀】、进攻马当火【杀】、宝物牌当冰【杀】使用，然后你可以于结算完成时选择将势力是否变更为“魏”。",
	["$diy_m_chongjian1"] = "尔等良将，于我不堪一击！",
	["$diy_m_chongjian2"] = "此等残兵，破之何其易也！",
	["diy_m_choujue"] = "仇决",
	[":diy_m_choujue"] = "锁定技，每个回合结束时，若你的手牌数与体力值相差3或更多且当前不为你的回合，则视为你对当前回合角色使用一张【杀】。",
	["$diy_m_choujue1"] = "血海深仇，便在今日来报！",
	["$diy_m_choujue2"] = "取汝之头，以祭先父！",
	["~diy_m_wenyang"] = "半生功业，而见疑于一家之言，岂能无怨！",
}
---------------------------------
diy_m_jiangji = sgs.General(extension, "diy_m_jiangji", "wei", 3)
diy_m_jichouVS = sgs.CreateViewAsSkillV2{
	name = "diy_m_jichou",
	n = 1,
	frequency = sgs.Skill_Compulsory,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return true
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			if not string.find(request:getPattern(), "nullification") then return false end
			for _, card in sgs.qlist(player:getHandcards()) do
				if card:isKindOf("Nullification") and player:getMark(skill:objectName()..card:objectName().."-Clear") < 1 then
					return true
				end
			end
		end
		return false
	end,
	can_select_card = function(skill, request, to_select)
	    local pattern = request:getPattern()
		local player = request:getInitiator()
		if not player or not to_select then return false end
		if string.find(pattern, "nullification") then
		    return to_select:isKindOf("Nullification") and player:getMark(skill:objectName()..to_select:objectName().."-Clear") < 1
		else
		    return to_select:isNDTrick() and not to_select:isKindOf("Nullification") and player:getMark(skill:objectName()..to_select:objectName().."-Clear") < 1
		end
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() > 0 then
		    local card = sgs.Sanguosha:getCard(ids:at(0)):objectName()
			local new_card = sgs.Sanguosha:cloneCard(card, sgs.Card_SuitToBeDecided, 0)
		    for _, c in sgs.qlist(ids) do
			    new_card:addSubcard(c)
		    end
		    new_card:setSkillName(skill:objectName())
		    return new_card
		end
	end,
}
diy_m_jichou = sgs.CreateTriggerSkillV2{
	name = "diy_m_jichou",
	events = {sgs.CardFinished},
	view_as_skill = diy_m_jichouVS,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardFinished then
			local use = data:toCardUse()
		    if table.contains(use.card:getSkillNames(), "diy_m_jichou") and use.card:isNDTrick() and player:hasSkill("diy_m_jichou") then
			    if player:getMark(use.card:getSkillName()..use.card:objectName().."-Clear") < 1 then
					room:addPlayerMark(player, use.card:getSkillName()..use.card:objectName().."-Clear")
					room:obtainCard(player, use.card, false)
				end
			end
		end
	end,
}

diy_m_jilunVS = sgs.CreateViewAsSkillV2{
	name = "diy_m_jilun",
	n = 1,
	frequency = sgs.Skill_Compulsory,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return true
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			if not string.find(request:getPattern(), "nullification") then return false end
			for _, card in sgs.qlist(player:getHandcards()) do
				if card:isKindOf("Nullification") and player:getMark("diy_m_jichou"..card:objectName().."-Clear") > 0 and player:getMark(skill:objectName()..card:objectName().."-Clear") < 1 then
					return true
				end
			end
		end
		return false
	end,
	can_select_card = function(skill, request, to_select)
	    local pattern = request:getPattern()
		local player = request:getInitiator()
		if not player or not to_select then return false end
		if string.find(pattern, "nullification") then
		    return to_select:isKindOf("Nullification") and player:getMark("diy_m_jichou"..to_select:objectName().."-Clear") > 0 and player:getMark(skill:objectName()..to_select:objectName().."-Clear") < 1
		else
		    return to_select:isNDTrick() and not to_select:isKindOf("Nullification") and player:getMark("diy_m_jichou"..to_select:objectName().."-Clear") > 0 and player:getMark(skill:objectName()..to_select:objectName().."-Clear") < 1
		end
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() > 0 then
		    local card = sgs.Sanguosha:getCard(ids:at(0)):objectName()
			local new_card = sgs.Sanguosha:cloneCard(card, sgs.Card_SuitToBeDecided, 0)
		    for _, c in sgs.qlist(ids) do
			    new_card:addSubcard(c)
		    end
		    new_card:setSkillName(skill:objectName())
		    return new_card
		end
	end,
}
diy_m_jilun = sgs.CreateTriggerSkillV2{
	name = "diy_m_jilun",
	events = {sgs.Damaged, sgs.CardFinished},
	view_as_skill = diy_m_jilunVS,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to:objectName() == player:objectName() and player:hasSkill("diy_m_jilun") then
				room:sendCompulsoryTriggerLog(player, "diy_m_jilun")
				room:broadcastSkillInvoke("diy_m_jilun", math.random(1, 2))
			    local n = 0
			    while n < damage.damage do
			        player:drawCards(2)
				    n = n + 1
			    end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
		    if table.contains(use.card:getSkillNames(), "diy_m_jilun") and use.card:isNDTrick() and player:hasSkill("diy_m_jilun") then
			    if player:getMark("diy_m_jichou"..use.card:objectName().."-Clear") > 0 then
					room:addPlayerMark(player, use.card:getSkillName()..use.card:objectName().."-Clear")
					room:obtainCard(player, use.card, false)
				end
			end
		end
	end,
}
diy_m_jiangji:addSkill(diy_m_jichou)
diy_m_jiangji:addSkill(diy_m_jilun)
sgs.LoadTranslationTable{
	["diy_m_jiangji"] = "MK蒋济",
	["#diy_m_jiangji"] = "盛魏昌杰",
	["designer:diy_m_jiangji"] = "俺的西木野Maki",
	["cv:diy_m_jiangji"] = "官方",
	["illustrator:diy_m_jiangji"] = "官方",
	["diy_m_jichou"] = "急筹",
	[":diy_m_jichou"] = "出牌阶段，你可以将一张未被记录过且本回合未被“机论”记录过的普通锦囊牌当做同名牌使用之。锁定技，当你以此法使用一张普通锦囊牌结算完成时，你记录之，然后获得此牌。",
	["$diy_m_jichou1"] = "此危亡之时，当出此急谋",
	["$diy_m_jichou2"] = "急筹布划，运策捭阖",
	["diy_m_jilun"] = "机论",
	[":diy_m_jilun"] = "锁定技，每当你受到1点伤害后，你摸两张牌。出牌阶段，你可以将一张已被“急筹”记录过且本回合未被“机论”记录过的普通锦囊牌当做同名牌使用。锁定技，当你以此法使用一张普通锦囊牌结算完成时，你记录之，然后获得此牌。",
	["$diy_m_jilun1"] = "时移不移，违天之祥也",
	["$diy_m_jilun2"] = "民望不因，违人之咎也",
	["~diy_m_jiangji"] = "洛水之誓，言犹在耳……呃咳咳",
}

diy_zu_zhongyan = sgs.General(extension, "diy_zu_zhongyan", "jin", 3, false)
diy_zuguanguCard = sgs.CreateSkillCard{
	name = "diy_zuguangu",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local num, n = {}, source:getChangeSkillState(self:objectName())
		for i = 0, 4 do
			table.insert(num, tostring(i))
		end
		local choice = room:askForChoice(source, "diy_zuguangunum", table.concat(num, "+"))
		room:setPlayerMark(source, "&diy_zuguangu", tonumber(choice))
		if n == 1 then
		    if choice == "0" or room:getDrawPile():isEmpty() then return false end
		    local card_ids = room:getNCards(tonumber(choice))
			room:fillAG(card_ids, source)
			local id = room:askForAG(source, card_ids, false, self:objectName())
			local card = sgs.Sanguosha:getCard(id)
			room:clearAG()
			if card:isKindOf("BasicCard") or card:isNDTrick() then
				local name = card:objectName()
				if name ~= "jink" and name ~= "nullification" and name ~= "jl_wuxiesy" then
					room:setPlayerProperty(source, "diy_zuguangu", sgs.QVariant(name))
					room:askForUseCard(source, "@@diy_zuguangu", "@diy_zuguangu:" .. name)
					room:setPlayerProperty(source, "diy_zuguangu", sgs.QVariant(false))
				end
			end
			room:setChangeSkillState(source, self:objectName(), 2)
		else
			local to = room:askForPlayerChosen(source, room:getAlivePlayers(), self:objectName(), "diy_zuguangu-invoke", false, false)
		    if choice == "0" or to:isKongcheng() then return false end
			local x = math.min(to:getHandcardNum(), tonumber(choice))
			local remove = sgs.IntList()
			for i = 1, x do--进行多次执行
				local id = room:askForCardChosen(source, to, "h", self:objectName(),
					false,--选择卡牌时手牌不可见
					sgs.Card_MethodNone,--设置为弃置类型
					remove,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
					i>1)--只有执行过一次选择才可取消
				if id < 0 then break end--如果卡牌id无效就结束多次执行
				remove:append(id)--将选择的id添加到虚拟卡的子卡表
			end
			room:fillAG(remove, source)
		    local id = room:askForAG(source, remove, false, self:objectName())
			local card = sgs.Sanguosha:getCard(id)
		    room:clearAG(source)
			if card:isKindOf("BasicCard") or card:isNDTrick() then
				local name = card:objectName()
				if name ~= "jink" and name ~= "nullification" and name ~= "jl_wuxiesy" then
					room:setPlayerProperty(source, "diy_zuguangu", sgs.QVariant(name))
					room:askForUseCard(source, "@@diy_zuguangu", "@diy_zuguangu:" .. name)
					room:setPlayerProperty(source, "diy_zuguangu", sgs.QVariant(false))
				end
			end
			room:setChangeSkillState(source, self:objectName(), 1)
		end
	end,
}
diy_zuguanguvs = sgs.CreateViewAsSkillV2{
	name = "diy_zuguangu",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:usedTimes("#diy_zuguangu") + player:usedTimes("diy_zuguangu") < 2
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern() or ""
			return string.startsWith(pattern, "@@diy_zuguangu")
		end
		return false
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		local pattern = request:getPattern() or ""
		if pattern == "@@diy_zuguangu" then
			local dzgg = player:property(skill:objectName()):toString()
			local cd = sgs.Sanguosha:cloneCard(dzgg, sgs.Card_NoSuit, 0)
			cd:setSkillName(skill:objectName())
			return cd
		else
			return diy_zuguanguCard:clone()
		end
	end,
}
diy_zuguangu = sgs.CreateTriggerSkillV2{
	name = "diy_zuguangu",
	events = {sgs.EventPhaseStart},
	view_as_skill = diy_zuguanguvs,
	change_skill = true,
	can_trigger = function(skill, event, room, player, data)
		return false
	end,
}
diy_zuxiaoyong = sgs.CreateTriggerSkillV2{
	name = "diy_zuxiaoyong",
	--global = true,
	priority = 100,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		if not use.card:isKindOf("SkillCard") and use.from:objectName() == player:objectName() then
			local n, m = utf8len(sgs.Sanguosha:translate(use.card:objectName())), player:getMark("&diy_zuguangu")
			if player:getMark("diy_zuxiaoyong-"..m.."-Clear") < 1 and n == m then
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName())
			    room:addPlayerMark(player, "diy_zuxiaoyong-"..m.."-Clear")
				if m > 1 then
					room:drawCards(player, m-1, skill:objectName())
				end
			end
		end
	end,
}
diy_zu_zhongyan:addSkill(diy_zuguangu)
diy_zu_zhongyan:addSkill(diy_zuxiaoyong)
diy_zu_zhongyan:addSkill("zu_zhong_baozu")
sgs.LoadTranslationTable{
	["diy_zu_zhongyan"] = "MK族钟琰",
	["#diy_zu_zhongyan"] = "落芳清雅",
	["designer:diy_zu_zhongyan"] = "Maki,FC[颍川·钟氏]",
	["cv:diy_zu_zhongyan"] = "官方",
	["illustrator:diy_zu_zhongyan"] = "土豆",
	["diy_zuguangu"] = "观骨",
	["diy_zuguangunum"] = "观骨观看牌数",
	["@diy_zuguangu"] = "你可以发动“观骨”，视为使用一张【%src】",
	["diy_zuguangu-invoke"] = "你可以发动“观骨”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	[":diy_zuguangu"] = "转换技，出牌阶段限两次，阳：你可以观看牌堆顶至多四张牌；阴：你可以观看一名角色至多四张手牌。然后你可以视为使用其中一张基本或普通锦囊牌。",
	[":diy_zuguangu1"] = "转换技，出牌阶段限两次，阳：你可以观看牌堆顶至多四张牌<font color=\"#01A5AF\"><s>；阴：你可以观看一名角色至多四张手牌</s></font>。然后你可以视为使用其中一张基本或普通锦囊牌。",
	[":diy_zuguangu2"] = "转换技，出牌阶段限两次，<font color=\"#01A5AF\"><s>阳：你可以观看牌堆顶至多四张牌；</s></font>阴：你可以观看一名角色至多四张手牌。然后你可以视为使用其中一张基本或普通锦囊牌。",
	["$diy_zuguangu1"] = "此才拔萃，然观其形骨，恐早夭。",
	["$diy_zuguangu2"] = "绯衣者，汝所拔乎？",
	["diy_zuxiaoyong"] = "啸咏",
    [":diy_zuxiaoyong"] = "锁定技，当你回合内首次使用牌名字数为X的牌时（X为上次“观骨”观看牌数），你摸X-1张牌。",
	["$diy_zuxiaoyong1"] = "凉风萧条，露沾我衣。",
	["$diy_zuxiaoyong2"] = "忧来多方，慨然永怀。",
	["~diy_zu_zhongyan"] = "此间天下人，皆分一斗之才......",
}
---------------------------------
mjin_simayi = sgs.General(extension, "mjin_simayi", "jin")
mjin_buchen = sgs.CreateTriggerSkillV2{
	name = "mjin_buchen",
	hide_skill = true,
	--global = true,
	priority = 100,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Appear, sgs.EventPhaseChanging, sgs.DrawNCards},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			local names, objs = {}, {}
			for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if p:getMark("mjinbuchen"..player:objectName()) > 0 then
					table.insert(names, skill:objectName())
					table.insert(objs, p:objectName())
				end
			end
			if #names > 0 then
				return table.concat(names, "|"), table.concat(objs, "|")
			end
			return false
		end
		if player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local to = nil
		if event == sgs.Appear and player:hasSkill(skill:objectName()) then
			to = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "@choose-players", false, true)
			room:broadcastSkillInvoke(skill:objectName(), math.random(1,2))
			room:addPlayerMark(player, "mjinbuchen"..to:objectName())
			room:sendCompulsoryTriggerLog(player, skill)
			room:gainMaxHp(player)
			room:recover(player, sgs.RecoverStruct(player, nil, 1))
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			local target = ctx.invoker
			if player:getMark("mjinbuchen"..target:objectName()) > 0 then
		        room:sendCompulsoryTriggerLog(player, skill:objectName())
		        room:broadcastSkillInvoke(skill:objectName())
		        draw.num = draw.num + player:getMark("mjinbuchen"..target:objectName())
		        data:setValue(draw)
			end
		else
		    local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:hasSkill(skill:objectName()) then
				room:sendCompulsoryTriggerLog(player, skill)
				if player:getGeneralName() == "mjin_simayi" or player:getGeneral2Name() == "mjin_simayi" then
				    if player:getGeneralName() == "mjin_simayi" then
				        player:setProperty("yinniGeneral", ToData(player:getGeneralName()))
					    room:changeHero(player, "yinni_hide", false, true, false, false)
					elseif player:getGeneral2Name() == "mjin_simayi" then
				        player:setProperty("yinniGeneral2", ToData(player:getGeneral2Name()))
					    room:changeHero(player, "yinni_hide", false, true, true, false)
					end
				end
				player:drawCards(1)
			end
		end
	end,
}
--V2 全局技能以隐藏技能名挂到所有武将；换将后于结算时补挂 acquired 实例。
local rushB_global_skill_names = {
	"#mjin_buchen_list",
}
-- Reentrancy + one-shot: attachSkillToPlayer can re-enter via on_record (50p soft-stuck).
local rushB_ensuring_globals = false
local function rushB_ensure_global_instances(room)
	if rushB_ensuring_globals then return end
	if room:getTag("rushB_globals_ensured"):toBool() then return end
	rushB_ensuring_globals = true
	local players = room:getAllPlayers(true)
	if players:isEmpty() then
		rushB_ensuring_globals = false
		return
	end
	local skip_set = {}
	local skip_str = room:getTag("rushB_ensure_skip"):toString()
	if skip_str ~= "" then
		for _, n in ipairs(skip_str:split("+")) do
			if n ~= "" then skip_set[n] = true end
		end
	end
	local skip_changed = false
	for _, p in sgs.qlist(players) do
		for _, skill_name in ipairs(rushB_global_skill_names) do
			if not skip_set[skill_name] and p:getSkillInstanceIds(skill_name):isEmpty() then
				room:attachSkillToPlayer(p, skill_name)
				if p:getSkillInstanceIds(skill_name):isEmpty() then
					skip_set[skill_name] = true
					skip_changed = true
				end
			end
		end
	end
	if skip_changed then
		local parts = {}
		for n, _ in pairs(skip_set) do table.insert(parts, n) end
		room:setTag("rushB_ensure_skip", sgs.QVariant(table.concat(parts, "+")))
	end
	room:setTag("rushB_globals_ensured", sgs.QVariant(true))
	rushB_ensuring_globals = false
end
mjin_buchen_list = sgs.CreateTriggerSkillV2{
	name = "#mjin_buchen_list",
	events = {sgs.TurnStart, sgs.HpChanged},
	global = true,
	priority = 100,
	frequency = sgs.Skill_Compulsory,
	on_record = function(skill, event, room, player, ctx)
		rushB_ensure_global_instances(room)
	end,
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		for _,p in sgs.list(room:getAlivePlayers()) do
			if p:hasSkill("mjin_buchen") then return end
		end
		if player:getGeneralName() == "yinni_hide" and player:property("yinni_general"):toString() == "" then player:setProperty("yinni_general", ToData(player:property("yinniGeneral"):toString())) end
		if player:getGeneral2Name() == "yinni_hide" and player:property("yinni_general2"):toString() == "" then player:setProperty("yinni_general2", ToData(player:property("yinniGeneral2"):toString())) end
		return false
	end,
}
mjin_yingshiCard = sgs.CreateSkillCard{
	name = "mjin_yingshi",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local maxhp = source:getMaxHp()
        local list = room:getNCards(maxhp, false)
        room:returnToTopDrawPile(list)
        room:fillAG(list, source)
        room:askForAG(source, list, true, self:objectName())
        room:clearAG(source)
	end,
}
mjin_yingshi = sgs.CreateViewAsSkillV2{
	name = "mjin_yingshi",
	n = 0,
	frequency = sgs.Skill_Compulsory,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_card = function(skill, request, candidate)
		return false
	end,
	create_card = function(skill, request)
	    return mjin_yingshiCard:clone()
	end,
}
mjin_xiongzhiCard = sgs.CreateSkillCard{
	name = "mjin_xiongzhi",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local id = room:getDrawPile():first()
		room:obtainCard(source, id, false)
		local card = sgs.Sanguosha:getCard(id)
		room:setCardFlag(card, "mjin_xiongzhi")
		if not card:isAvailable(source) or not room:askForUseCard(source, "@@mjin_xiongzhi", "@jinxiongzhi:"..card:objectName()) then
		    room:setCardFlag(card, "-mjin_xiongzhi")
			room:moveCardTo(card, nil, sgs.Player_Discard)
			room:addPlayerMark(source, self:objectName().."-PlayClear")
		else
		    room:setCardFlag(card, "-mjin_xiongzhi")
		end
	end,
}
mjin_xiongzhi = sgs.CreateViewAsSkillV2{
	name = "mjin_xiongzhi",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:getMark(skill:objectName().."-PlayClear") < 1
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern() or ""
			return string.startsWith(pattern, "@@mjin_xiongzhi")
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		return candidate and candidate:hasFlag("mjin_xiongzhi")
			and request:getSelectedCardIds():length() < 1
	end,
	card_selection_feasible = function(skill, request)
		local pattern = request:getPattern() or ""
		if pattern == "@@mjin_xiongzhi" then
			return request:getSelectedCardIds():length() == 1
		end
		return request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
	    local pattern = request:getPattern() or ""
		local ids = request:getSelectedCardIds()
		if pattern == "@@mjin_xiongzhi" then
			if ids:length() ~= 1 then return nil end
			local skillcard = sgs.Sanguosha:getCard(ids:first())
			skillcard:setSkillName("_"..skill:objectName())
			for _, c in sgs.qlist(ids) do
				skillcard:addSubcard(c)
			end
			return skillcard
		else
			if not ids:isEmpty() then return nil end
		    return mjin_xiongzhiCard:clone()
		end
	end,
}
mjin_quanbian = sgs.CreateTriggerSkillV2{
	name = "mjin_quanbian",
	--global = true,
	events = {sgs.CardUsed, sgs.CardResponded},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and not card:hasFlag("mjin_xiongzhi") and not card:isKindOf("SkillCard") and player:getPhase() == sgs.Player_Play then
			local peachs = sgs.IntList()
			for _,id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id):getSuit() == card:getSuit() then
					peachs:append(id)
				end
			end
			if not peachs:isEmpty() and player:getMark(card:getSuitString().."-PlayClear") < 1 and room:askForSkillInvoke(player, skill:objectName(), data) then
			    room:broadcastSkillInvoke(skill:objectName())
			    room:addPlayerMark(player, card:getSuitString().."-PlayClear")
				room:obtainCard(player, peachs:at(0), true)
			end
			room:addPlayerMark(player, "&"..skill:objectName().."-PlayClear")
			if player:getMark("&"..skill:objectName().."-PlayClear") >= player:getMaxHp() then
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				room:setPlayerFlag(player, "Global_PlayPhaseTerminated")
			end
		end
	end,
}
mjin_simayi:addSkill(mjin_buchen)
mjin_simayi:addSkill(mjin_yingshi)
mjin_simayi:addSkill(mjin_xiongzhi)
mjin_simayi:addSkill(mjin_quanbian)
if not sgs.Sanguosha:getSkill("#mjin_buchen_list") then skills:append(mjin_buchen_list) end
sgs.LoadTranslationTable{
	["mjin_simayi"] = "MK晋司马懿",
	["&mjin_simayi"] = "MK司马懿",
	["#mjin_simayi"] = "红梅迎春",
	["designer:mjin_simayi"] = "俺的西木野Maki",
	["cv:mjin_simayi"] = "官方",
	["illustrator:mjin_simayi"] = "biou09",
	["mjin_buchen"] = "不臣",
	[":mjin_buchen"] = "隐匿技，锁定技，当你登场后，你令一名其他角色自下回合起的额定摸牌数+1，然后增加1点体力上限并恢复1点体力；锁定技，回合结束后，你进入隐匿状态并摸一张牌。",
	["$mjin_buchen1"] = "雄韬大略无异辈，何须俯首为人臣？",
	["$mjin_buchen2"] = "魏室摇摇欲坠，何不取而代之？",
	["mjin_yingshi"] = "鹰视",
	--[":mjin_yingshi"] = "锁定技，出牌阶段，你可以观看牌堆顶的X张牌（X为你的体力上限）。",
	[":mjin_yingshi"] = "锁定技，出牌阶段，牌堆顶的X张牌对你可见（X为你的体力上限）。\
	->查看方法：点击技能按钮",
	["$mjin_yingshi1"] = "谋大事者，必察常人所不察。",
	["$mjin_yingshi2"] = "吾为人，清俊而鹰视！",
	["mjin_xiongzhi"] = "雄志",
	[":mjin_xiongzhi"] = "出牌阶段，你可以获得牌堆顶的一张牌，若你能使用此牌，你使用之，否则将此牌置入弃牌堆且本阶段“雄志”无效。",
	["$mjin_xiongzhi1"] = "率土之滨，尽归我司马一族！",
	["$mjin_xiongzhi2"] = "蛰伏多载，今朝雄志可展！",
	["mjin_quanbian"] = "权变",
	[":mjin_quanbian"] = "当你于出牌阶段内第一次使用或打出一种花色的手牌时，你可以从牌堆中随机获得一张与此牌花色相同的牌。出牌阶段，当你不因“雄志”使用至少X张手牌后，你结束此阶段（X为你的体力上限）。",
	["$mjin_quanbian1"] = "吾为权变之事，此况应付自如。",
	["$mjin_quanbian2"] = "圣人者，应时权变，见形施宜。",
	["~mjin_simayi"] = "吾梦贾逵、王凌为祟，甚恶之......",
}
---------------------------------
---------------------------------
rushB_xiahouba = sgs.General(extension, "rushB_xiahouba", "shu")
rushB_baobian_tiaoxinCard = sgs.CreateSkillCard{
	name = "rushB_baobian_tiaoxin",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	feasible = function(self, targets, player)
		return #targets > 0
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:moveCardTo(sgs.Sanguosha:getCard(self:getSubcards():first()), effect.from, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, effect.from:objectName(), self:objectName(), ""))
		room:broadcastSkillInvoke("@recast")
		local log = sgs.LogMessage()
		log.type = "#UseCard_Recast"
		log.from = effect.from
		log.card_str = ""..sgs.Sanguosha:getCard(self:getSubcards():first()):toString()
		room:sendLog(log)
		effect.from:drawCards(1, "recast")
		local use_slash = false
		if effect.to:canSlash(effect.from, nil, false) then
			use_slash = room:askForUseSlashTo(effect.to,effect.from, "@tiaoxin-slash:" .. effect.from:objectName())
		end
		if (not use_slash) then
		    if not effect.to:isNude() then
			    room:throwCard(room:askForCardChosen(effect.from, effect.to, "he", "rushB_baobian_tiaoxin", false, sgs.Card_MethodDiscard), effect.to, effect.from)
			end
		end
	end,
}
rushB_baobian_shensuCard = sgs.CreateSkillCard{
	name = "rushB_baobian_shensu",
	filter = function(self, targets, to_select, player)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, player)
	end,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
			slash:deleteLater()
		end
	end,
}
rushB_baobianCard = sgs.CreateSkillCard{
	name = "rushB_baobian",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:loseHp(source, 1, true, source, self:objectName())
		if source:isAlive() then
			room:drawCards(source, 1, "baobian")
		end
	end,
}
rushB_baobianvs = sgs.CreateViewAsSkillV2{
	name = "rushB_baobian",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return true
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern() or ""
			return string.startsWith(pattern, "@@rushB_baobian_shensu")
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not (player and candidate) then return false end
		local pattern = request:getPattern() or ""
		if string.endsWith(pattern, "2") then
			return request:getSelectedCardIds():isEmpty() and candidate:isKindOf("EquipCard") and not player:isJilei(candidate)
		elseif player:getHp() <= 3 then
		    return true
		else
		    return false
		end
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local pattern = request:getPattern() or ""
		local n = request:getSelectedCardIds():length()
		if string.find(pattern, "@@rushB_baobian_shensu2") then
			return n > 0 and player:getHp() <= 1
		elseif string.find(pattern, "@@rushB_baobian_shensu1") or string.find(pattern, "@@rushB_baobian_shensu3") then
			return n == 0 and player:getHp() <= 1
		else
			if n > 0 then
				return (not player:isNude()) and player:getHp() <= 3
			end
			return true
		end
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
	    local pattern = request:getPattern() or ""
		local ids = request:getSelectedCardIds()
		if string.find(pattern, "@@rushB_baobian_shensu2") then
	        if ids:length() > 0 then
		        if player:getHp() <= 1 then
	                local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
		            card:setSkillName("rushB_baobian_shensu")
			        for _, c in sgs.qlist(ids) do
				        card:addSubcard(c)
			        end
		            return card
				end
			end
		elseif string.find(pattern, "@@rushB_baobian_shensu1") or string.find(pattern, "@@rushB_baobian_shensu3") then
			if ids:length() > 0 or player:getHp() > 1 then return false end
			local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
			card:setSkillName("rushB_baobian_shensu")
			return card
		else
			if not player:isNude() then
			    if ids:length() > 0 then
		            if player:getHp() <= 3 then
	                    local card = rushB_baobian_tiaoxinCard:clone()
		                card:setSkillName("rushB_baobian_tiaoxin")
			            for _, c in sgs.qlist(ids) do
				            card:addSubcard(c)
			            end
		                return card
					end
			    else
		            if ids:length() > 0 then return false end
				    return rushB_baobianCard:clone()
				end
			else
		        if ids:length() > 0 then return false end
				return rushB_baobianCard:clone()
			end
		end
	end,
}
rushB_baobian = sgs.CreateTriggerSkillV2{
    name = "rushB_baobian",
	events = {sgs.PreCardUsed, sgs.EventPhaseChanging, sgs.MarkChanged, sgs.CardUsed},
	view_as_skill = rushB_baobianvs,
	can_trigger = function(skill, event, room, player, data)
	    if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
	    local data = ctx.original_data
		if event == sgs.PreCardUsed then
		    local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(), "rushB_baobian") then
				if use.from:getHp() <= 3 then
                    room:broadcastSkillInvoke("rushB_baobian", 1)
                elseif use.from:getHp() <= 2 then
                    room:broadcastSkillInvoke("rushB_baobian", 3)
                elseif use.from:getHp() <= 2 then
                    room:broadcastSkillInvoke("rushB_baobian", 5)
				end
			end
			if table.contains(use.card:getSkillNames(), "rushB_baobian_tiaoxin") then
				room:broadcastSkillInvoke("rushB_baobian", 2)
			end
			if table.contains(use.card:getSkillNames(), "rushB_baobian_shensu") then
				room:broadcastSkillInvoke("rushB_baobian", 6)
			end
		elseif event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
			if not player:hasSkill(skill:objectName()) or player:getHp() > 1 then return false end
			if change.to == sgs.Player_Start then
			    --if room:askForUseCard(player, "@@baobianshensu1", "@baobianshensu1") then
				if room:askForUseCard(player, "@@rushB_baobian_shensu1", "@rushB_baobian_shensu1", 1) then
				    player:skip(sgs.Player_Judge)
				    player:skip(sgs.Player_Draw)
				end
			elseif change.to == sgs.Player_Play and not player:isNude() then
			    --if room:askForUseCard(player, "@@baobianshensu2", "@baobianshensu2") then
				if room:askForUseCard(player, "@@rushB_baobian_shensu2", "@rushB_baobian_shensu2", 2, sgs.Card_MethodDiscard) then
				    player:skip(change.to)
				end
			elseif change.to == sgs.Player_Discard then
			    --if room:askForUseCard(player, "@@baobianshensu3", "@baobianshensu3") then
				if room:askForUseCard(player, "@@rushB_baobian_shensu3", "@rushB_baobian_shensu3", 3) then
				    player:skip(change.to)
					player:turnOver()
				end
			end
		elseif event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "baobianpaoxiao-Clear" and mark.who:getMark(mark.name) > 1 and mark.who:getHp() <= 2 then
				room:sendCompulsoryTriggerLog(mark.who, "paoxiao")
				room:broadcastSkillInvoke("rushB_baobian", 4)
			end
		elseif event == sgs.CardUsed then
		    local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from:hasSkill("rushB_baobian") then
				room:addPlayerMark(use.from, "baobianpaoxiao-Clear")
				room:addPlayerMark(use.from, "paoxiao-Clear")
			end
		end
	end,
}
rushB_baobian_paoxiao = sgs.CreateTargetModSkillV2{
	name = "#rushB_baobian_paoxiao",
	pattern = "^SkillCard",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(self, ctx)
		local from = ctx:getPrimary()
		local card = ctx:getCard()
		local modType = ctx:getModType()
		local n = 0
		if modType == sgs.TargetModSkill_Residue then
			if from:hasSkill("rushB_baobian") and from:getHp() <= 2 and card and card:isKindOf("Slash") then
				n = 1000
			end
		elseif modType == sgs.TargetModSkill_DistanceLimit then
			if from:hasSkill("rushB_baobian") and from:getHp() <= 2 and card and card:isKindOf("Slash") and from:getMark("paoxiao-Clear") > 0 then
				n = 1000
			end
		end
        return n
	end,
}
rushB_baobian_shensus = sgs.CreateTargetModSkillV2{
	name = "#rushB_baobian_shensus",
	pattern = "^SkillCard",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(self, ctx)
		if ctx:getModType() ~= sgs.TargetModSkill_DistanceLimit then return nil end
		local from = ctx:getPrimary()
		local card = ctx:getCard()
		local n = 0
		if from:hasSkill("rushB_baobian") and from:getHp() <= 1 and card and table.contains(card:getSkillNames(), "rushB_baobian_shensu") then
			n = 1000
		end
        return n
	end,
}
rushB_xiahouba:addSkill(rushB_baobian)
rushB_xiahouba:addSkill(rushB_baobian_paoxiao)
rushB_xiahouba:addSkill(rushB_baobian_shensus)
extension:insertRelatedSkills("rushB_baobian", "#rushB_baobian_paoxiao")
extension:insertRelatedSkills("rushB_baobian", "#rushB_baobian_shensus")


sgs.LoadTranslationTable{
	["rushB_xiahouba"] = "MK夏侯霸",
	["#rushB_xiahouba"] = "超尘逐电",
	["designer:rushB_xiahouba"] = "俺的西木野Maki",
	["cv:rushB_xiahouba"] = "官方",
	["illustrator:rushB_xiahouba"] = "枭瞳",
	["rushB_baobian"] = "豹变",
	["rushb_baobian"] = "豹变",
	["rushB_baobian_tiaoxin"] = "挑衅",
	["rushb_baobian_tiaoxin"] = "挑衅",
	["rushB_baobian_shensu"] = "神速",
	["rushb_baobian_shensu"] = "神速",
	--["@baobianshensu1"] = "你可以发动“神速”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	--["@baobianshensu2"] = "你可以发动“神速”<br/> <b>操作提示</b>: 选择一张装备牌→选择一名角色→点击确定<br/>",
	--["@baobianshensu3"] = "你可以发动“神速”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["@rushB_baobian_shensu1"] = "你可以发动“神速”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["@rushB_baobian_shensu2"] = "你可以发动“神速”<br/> <b>操作提示</b>: 选择一张装备牌→选择一名角色→点击确定<br/>",
	["@rushB_baobian_shensu3"] = "你可以发动“神速”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	[":rushB_baobian"] = "锁定技，若你的体力值为：3或更低，你拥有“挑衅”；2或更低，你拥有“咆哮”；1或更低，你拥有“神速”。\
	出牌阶段，你可以（点击此按钮）失去1点体力，然后摸一张牌。\
	挑衅：出牌阶段，你可以重铸一张牌并选择一名其他角色（点击此按钮->选择一张牌->选择目标角色），令其对你使用一张【杀】，若其不使用【杀】，则你弃置其一张牌；\
	咆哮：锁定技，你使用【杀】无次数限制，若你使用过【杀】，则你使用【杀】无距离限制；\
	神速：你可以选择一至三项：跳过判定阶段和摸牌阶段、跳过出牌阶段并弃置一张装备牌、跳过弃牌阶段并翻面：你每选择上述一项，视为你使用一张无距离限制的【杀】。",
	["$rushB_baobian1"] = "寡谋少勇之辈，速速回阵，可免一死！",
	["$rushB_baobian2"] = "汝等久食魏禄，今怎可助贼篡国！",
	["$rushB_baobian3"] = "此等土鸡瓦犬之辈，安为我一合之将！",
	["$rushB_baobian4"] = "既为先锋，合当斩将刈旗！",
	["$rushB_baobian5"] = "时时快敌一步，方可盈握先机！",
	["$rushB_baobian6"] = "兵力悬殊，那就速袭决胜！",
	["~rushB_xiahouba"] = "可怜半生骁勇将，一朝毙命流矢下......",
}
---------------------------------
rushB_lusu = sgs.General(extension, "rushB_lusu", "wu", 3)
rushB_dimengCard = sgs.CreateSkillCard{
	name = "rushB_dimeng",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		return #targets < 2 
	end,
	feasible = function(self, targets, player)
		return #targets == 2 
	end,
	on_use = function(self, room, source, targets)
	    local ids, id = sgs.IntList(), sgs.IntList()
		if not targets[1]:isKongcheng() then
	        for _, card in sgs.qlist(targets[1]:getHandcards()) do
			    ids:append(card:getEffectiveId())
		    end
		end
	    if not targets[2]:isKongcheng() then
	        for _, card_id in sgs.qlist(targets[2]:getHandcards()) do
			    id:append(card_id:getEffectiveId())
		    end
		end
		local splayers = sgs.SPlayerList()
		splayers:append(targets[1])
		targets[1]:addToPile("dimeng", id, false, splayers)
		local splayers = sgs.SPlayerList()
		splayers:append(targets[2])
		targets[2]:addToPile("dimeng", ids, false, splayers)
	end,
}
rushB_dimengvs = sgs.CreateViewAsSkillV2{
	name = "rushB_dimeng",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:usedTimes("#rushB_dimeng") + player:usedTimes("rushB_dimeng") < 1
	end,
	can_select_card = function(skill, request, candidate)
		return false
	end,
	create_card = function(skill, request)
		return rushB_dimengCard:clone()
	end,
}
rushB_dimeng = sgs.CreateTriggerSkillV2{
	name = "rushB_dimeng",
	--global = true,
	events = {sgs.EventPhaseEnd},
	view_as_skill = rushB_dimengvs,
	can_trigger = function(skill, event, room, player, data)
	    if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish and player:hasSkill(skill:objectName()) then
		  	    local players = sgs.SPlayerList()
			    for _, p in sgs.qlist(room:getAlivePlayers()) do
				    if not p:getPile("dimeng"):isEmpty() then players:append(p) end
			    end
			    if players:isEmpty() then return false end
				local dummy, dummi, n, x = sgs.Sanguosha:cloneCard("slash"), sgs.Sanguosha:cloneCard("slash"), players:first():getPile("dimeng"):length(), players:last():getPile("dimeng"):length()
				room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
				dummy:addSubcards(players:first():getPile("dimeng"))
				dummi:addSubcards(players:last():getPile("dimeng"))
				room:obtainCard(players:first(), dummy, false)
				room:obtainCard(players:last(), dummi, false)
				dummy:deleteLater()
				dummi:deleteLater()
				if player:isKongcheng() or n == x then return false end
				local m = math.abs(n - x)
				if player:getHandcardNum() >= m then
				    room:askForDiscard(player, skill:objectName(), m, m)
				else
				    room:askForDiscard(player, skill:objectName(), player:getHandcardNum(), player:getHandcardNum())
				end
			end
		end
		return false
	end,
}
rushB_lusu:addSkill("haoshi")
rushB_lusu:addSkill(rushB_dimeng)
sgs.LoadTranslationTable{
	["rushB_lusu"] = "MK鲁肃",
	["#rushB_lusu"] = "联刘抗曹",
	["designer:rushB_lusu"] = "俺的西木野Maki",
	["cv:rushB_lusu"] = "官方",
	["illustrator:rushB_lusu"] = "聚一",
	["rushB_dimeng"] = "缔盟",
	["rushb_dimeng"] = "缔盟",
    [":rushB_dimeng"] = "出牌阶段限一次，你可以选择两名角色，然后令这两名角色将各自手牌置于武将牌上。若如此做，回合结束后你令这两名角色获得对方武将上的牌，然后你弃置等量的牌。",
	["$rushB_dimeng1"] = "吾等，应勠力同心，共聚大义！",
	["$rushB_dimeng2"] = "将军降曹，何以自处？联盟为上！",
	["~rushB_lusu"] = "未料得此生不继，联盟恐变哪......",
}
---------------------------------
rushB_wujing = sgs.General(extension, "rushB_wujing", "wu")
rushB_diaoguiCard = sgs.CreateSkillCard{
	name = "rushB_diaogui",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:getPile("diaohulishan_diaogui"):isEmpty() and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		targets[1]:addToPile("diaohulishan_diaogui", self, false)
		room:swapSeat(targets[1], source)
		room:setPlayerFlag(source, "diaogui")
		room:setPlayerFlag(targets[1], "diaogui")
		local n = 1
        local nextalive = source:getNextAlive()
        local prevalive = source:getNextAlive(room:alivePlayerCount() - 1)
        
        -- 检查交换后的上家是否为队友
        if source:isYourFriend(prevalive) then
            n = n + 1
        end
        
        -- 检查交换后的下家是否为队友
        if source:isYourFriend(nextalive) then
            n = n + 1
        end
		source:drawCards(n)
	end,
}
rushB_diaoguivs = sgs.CreateViewAsSkillV2{
	name = "rushB_diaogui",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:usedTimes("#rushB_diaogui") + player:usedTimes("rushB_diaogui") < 1
	end,
	can_select_card = function(skill, request, candidate)
		return candidate ~= nil
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local vscard = rushB_diaoguiCard:clone()
		for _, i in sgs.qlist(ids) do
			vscard:addSubcard(i)
		end
		return vscard
	end,
}
rushB_diaogui = sgs.CreateTriggerSkillV2{
	name = "rushB_diaogui",
	view_as_skill = rushB_diaoguivs,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:hasSkill(skill:objectName()) then
		  	    local players = sgs.SPlayerList()
			    for _, p in sgs.qlist(room:getAlivePlayers()) do
				    if p:hasFlag("diaogui") then players:append(p) end
			    end
			    if players:isEmpty() then return false end
				room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
				room:swapSeat(players:last(), players:first())
			    if not players:first():getPile("diaohulishan_diaogui"):isEmpty() then
				    local dummy = sgs.Sanguosha:cloneCard("slash")
				    dummy:addSubcards(players:first():getPile("diaohulishan_diaogui"))
					dummy:deleteLater()
					room:throwCard(dummy, players:first(), nil)
				end
			    if not players:last():getPile("diaohulishan_diaogui"):isEmpty() then
				    local dummy = sgs.Sanguosha:cloneCard("slash")
				    dummy:addSubcards(players:last():getPile("diaohulishan_diaogui"))
					dummy:deleteLater()
					room:throwCard(dummy, players:last(), nil)
				end
			end
		end
		return false
	end,
}
rushB_fengyang = sgs.CreateTriggerSkillV2{
    name = "rushB_fengyang",
	--global = true,
	priority = 100,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
	    local data = ctx.original_data
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if player:hasSkill(skill:objectName()) and player:getMark(skill:objectName().."-Clear") < 1 then
				for _, p in sgs.qlist(use.to) do
			        room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
					player:drawCards(player:distanceTo(p))
					room:addPlayerMark(player, skill:objectName().."-Clear")
			    end
			end
		end
	end,
}
rushB_wujing:addSkill(rushB_diaogui)
rushB_wujing:addSkill(rushB_fengyang)
sgs.LoadTranslationTable{
	["rushB_wujing"] = "MK吴景",
	["#rushB_wujing"] = "助吴征战",
	["designer:rushB_wujing"] = "俺的西木野Maki",
	["cv:rushB_wujing"] = "官方",
	["illustrator:rushB_wujing"] = "小牛",
	["rushB_diaogui"] = "调归",
	["rushb_diaogui"] = "调归",
	["diaohulishan_diaogui"] = "调虎离山",
	[":rushB_diaogui"] = "阵法技，出牌阶段限一次，你可以将一张牌当做【调虎离山】置于一名其他角色的武将牌上，若与你阵营相同的角色因此而形成队列，你摸X张牌。（X为该队列中的角色数）\
	队列：上家或下家至少一人为你队友\
	【调虎离山】：将一张装备牌置于一名目标的武将牌上，然后与其交换座位。回合结束时，与以此法交换座位的角色交换回座位并弃置【调虎离山】。",
	["$rushB_diaogui1"] = "闻伯符立业，景，特来相助！",
	["$rushB_diaogui2"] = "臣虽驽钝，愿以此腔热血报国！",
	["rushB_fengyang"] = "风扬",
	[":rushB_fengyang"] = "锁定技，每回合限一次，当你使用牌结算完成时，你摸X张牌。（X为你到使用牌的目标的距离）",
	["$rushB_fengyang1"] = "谁也休想染指江东寸土！",
	["$rushB_fengyang2"] = "如此咽喉要地，吾当亲力守之！",
	["~rushB_wujing"] = "恨未能见，我江东一统天下之时！",
}
---------------------------------
mmou_zhangjiao = sgs.General(extension, "mmou_zhangjiao$", "qun", 3, true)
mmou_leijiCard = sgs.CreateSkillCard{
	name = "mmou_leiji",
	filter = function(self, selected, to_select, player)
	    return #selected == 0 and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
	    source:loseMark("&huangjindaobing", 4)
		room:damage(sgs.DamageStruct(self:objectName(), source, targets[1], 1, sgs.DamageStruct_Thunder))
	end,
}
mmou_leiji = sgs.CreateViewAsSkillV2{
    name = "mmou_leiji",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getMark("&huangjindaobing") >= 4
			and player:usedTimes("#mmou_leiji") + player:usedTimes("mmou_leiji") < 1
	end,
	can_select_card = function(skill, request, candidate)
		return false
	end,
	create_card = function(skill, request)
		return mmou_leijiCard:clone()
	end,
}
mmou_guidaoCard = sgs.CreateSkillCard{
	name = "mmou_guidao",
	target_fixed = true,
	on_use = function(self, room, source, targets)
	   local mark_num = {}
		    for i = 1, math.min(5, source:getMark("&huangjinfu")) do
			    table.insert(mark_num, tostring(i))
		    end
		    local choice = room:askForChoice(source, choice, table.concat(mark_num, "+"))
		    source:loseMark("&huangjinfu", tonumber(choice))
		    source:gainMark("&huangjindaobing", tonumber(choice))
	end,
}
mmou_guidaovs = sgs.CreateViewAsSkillV2{
    name = "mmou_guidao",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and (player:getMark("&huangjinfu") >= 1 or player:getMaxHp() > 4)
			and player:usedTimes("#mmou_guidao") + player:usedTimes("mmou_guidao") < 1
	end,
	can_select_card = function(skill, request, candidate)
		return false
	end,
	create_card = function(skill, request)
		return mmou_guidaoCard:clone()
	end,
}
mmou_guidao = sgs.CreateTriggerSkillV2{
	name = "mmou_guidao",
	--global = true,
	priority = 100,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.CardsMoveOneTime, sgs.MarkChanged, sgs.AskForPeachesDone},
	view_as_skill = mmou_guidaovs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardsMoveOneTime then
		    local move = data:toMoveOneTime()
		    if move.from == nil then return false end
		    if move.to_place == sgs.Player_DiscardPile then
			    local card_ids = sgs.IntList()
			    for _, card_id in sgs.qlist(move.card_ids) do
				    if sgs.Sanguosha:getCard(card_id):isBlack() then
					    card_ids:append(card_id)
				    end
			    end
			    if not card_ids:isEmpty() and player:hasSkill(skill:objectName()) then
				    room:sendCompulsoryTriggerLog(player, skill:objectName())
				    room:broadcastSkillInvoke(skill:objectName(), math.random(1, 2))
				    player:gainMark("&huangjinfu", card_ids:length())
			    end
		    end
		elseif event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "&huangjinfu" and mark.who:getMark("&huangjinfu") >= mark.who:getMaxHp() and mark.who:objectName() == player:objectName() and player:hasSkill(skill:objectName()) then
				local mhp = player:getMaxHp()
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				room:broadcastSkillInvoke(skill:objectName())
				player:loseMark("&huangjinfu", mhp)
				player:gainMark("&huangjindaobing", mhp)
			end
		else
		    if player:hasSkill(skill:objectName()) then
			    room:sendCompulsoryTriggerLog(player, skill:objectName())
			    room:broadcastSkillInvoke(skill:objectName(), math.random(1, 2))
			    player:gainMark("&huangjindaobing", 4)
			end
		end
		return false
	end,
}
mmou_huangtian = sgs.CreateTriggerSkillV2{
	name = "mmou_huangtian$",
	events = {sgs.EventPhaseStart},
	--global = true,
	priority = 100,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player and player:getPhase() == sgs.Player_RoundStart
			and not player:isKongcheng() and player:getKingdom() == "qun" then
		    local names, objs = {}, {}
		    for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
		        if p:objectName() ~= player:objectName() and p:hasLordSkill(skill:objectName()) then
				    table.insert(names, skill:objectName())
					table.insert(objs, p:objectName())
			    end
		    end
			if #names > 0 then
				return table.concat(names, "|"), table.concat(objs, "|")
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local target = ctx.invoker
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:broadcastSkillInvoke(skill:objectName())
		local card_id = room:askForDiscard(target, skill:objectName(), 1, 1, false, true)
    	if sgs.Sanguosha:getCard(card_id:getSubcards():first()):isRed() then
            if player:getMark("&huangjindaobing") >= 4 then
			    room:sendCompulsoryTriggerLog(player, "mmou_leiji")
		        room:broadcastSkillInvoke("mmou_leiji")
				player:loseMark("&huangjindaobing", 4)
                room:damage(sgs.DamageStruct("mmou_leiji", player, target, 1, sgs.DamageStruct_Thunder))
			end
        end
		return false
	end,
}
mmou_zhangjiao:addSkill(mmou_leiji)
mmou_zhangjiao:addSkill(mmou_guidao)
mmou_zhangjiao:addSkill(mmou_huangtian)
sgs.LoadTranslationTable{
	["mmou_zhangjiao"] = "MK谋张角",
	["#mmou_zhangjiao"] = "道法行雷",
	["designer:mmou_zhangjiao"] = "俺的西木野Maki",
	["cv:mmou_zhangjiao"] = "官方",
	["illustrator:mmou_zhangjiao"] = "梦回唐朝",
	["mmou_leiji"] = "雷击",
	[":mmou_leiji"] = "出牌阶段限一次，你可以选择一名其他角色并弃置四个“道兵”标记，然后对其造成1点雷电伤害。",
	["$mmou_leiji1"] = "雷电加身，助破万钧！",
	["$mmou_leiji2"] = "雷霆天降，可击四海！",
	["mmou_guidao"] = "鬼道",
	["huangjindaobing"] = "道兵",
	["huangjinfu"] = "黄巾符",
	["losemark"] = "弃置标记",
	[":mmou_guidao"] = "锁定技，游戏开始时，你获得四个“道兵”标记；当一张黑色牌进入弃牌堆时，你获得等量个“黄巾符”标记，"..
	"当你的“黄巾符”标记大于等于你的体力上限时，你移除等同于你当前体力上限值的“黄巾符”标记并获得等量个“道兵”标记。出牌阶段限一次，你可以（点击此按钮）弃置至多5个“黄巾符”标记，"..
	"并获得等量个“道兵”标记。",
	["$mmou_guidao1"] = "行大顺之道，以教旧世赈民。",
	["$mmou_guidao2"] = "通晓阴阳，轮转鬼道。",
	["mmou_huangtian"] = "黄天",
	[":mmou_huangtian"] = "主公技，锁定技，其他群势力角色的回合开始时，该角色弃置一张牌，若其弃置的牌不为黑色则你可以对其使用“雷击”，以此法使用的“雷击”不消耗“道兵”标记。",
	["$mmou_huangtian1"] = "太平道法，天书详记！",
	["$mmou_huangtian2"] = "天书既出，太平可期！",
	["~mmou_zhangjiao"] = "黄天未兴，为何……为何……",
}
---------------------------------
rushB_mouzhugeliang = sgs.General(extension, "rushB_mouzhugeliang", "shu", 3)

rushB_moubazhen = sgs.CreateTriggerSkillV2{
    name = "rushB_moubazhen",
    events = {sgs.CardUsed, sgs.TargetConfirming, sgs.MarkChanged, sgs.Death, sgs.EventPhaseChanging},
    shiming_skill = true,
    waked_skills = "kongcheng,olhuoji,olkanpo,bazhen",
    frequency = sgs.Skill_Compulsory,
    -- Automatic mission events use the standard V2 instance dispatcher.
    can_trigger = function(skill, event, room, player, data)
        if not player or not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
        local names = {}
        for _, id in sgs.qlist(player:getValidSkillInstanceIds(skill:objectName())) do
            local ref = sgs.SkillInstanceRef(player:objectName(), sgs.SkillInstanceKey(skill:objectName(), id))
            local names = player:getSkillInstanceStateValue(skill:objectName(), id, "names"):toString():split("+")
            local eligible = false
            if event == sgs.TargetConfirming or event == sgs.CardUsed then
                local use = data:toCardUse()
                if use.card and not use.card:isKindOf("SkillCard") and not use.card:isKindOf("EquipCard")
                    and not table.contains(names, use.card:objectName()) then
                    eligible = (event == sgs.CardUsed and use.from == player)
                        or (event == sgs.TargetConfirming and use.to:length() == 1
                            and use.to:contains(player) and use.from and use.from ~= player)
                end
            elseif event == sgs.Death then
                eligible = data:toDeath().who ~= player
            elseif event == sgs.MarkChanged then
                eligible = data:toMark().name == "bazhendeath" and player:getMark("bazhendeath") > 0
            elseif event == sgs.EventPhaseChanging then
                eligible = data:toPhaseChange().to == sgs.Player_NotActive
                    and #names > room:alivePlayerCount() and player:getMark("bazhendeath") == 0
            end
            if eligible and room:getShimingStatus(ref) == 0 then table.insert(names, ref.key:toString()) end
        end
        if #names == 0 then return false end
        return table.concat(names, "+")
    end,
    on_cost = function(skill, event, room, player, ctx)
        return room:getShimingStatus(ctx:getActivationRef()) == 0
    end,
    on_effect = function(skill, event, room, player, ctx)
        -- Revalidate after V2 hooks; a nested outcome may have removed this copy.
        local ref = ctx:getActivationRef()
        if not player:hasSkillInstance(skill:objectName(), ref.key.instanceID)
            or player:isSkillInvalid(skill:objectName(), ref.key.instanceID)
            or room:getShimingStatus(ref) ~= 0 then return false end
        local data = ctx.original_data
        local names = player:getSkillInstanceStateValue(skill:objectName(), ref.key.instanceID, "names"):toString():split("+")
	    if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card:isKindOf("SkillCard") then return false end
			if use.to:length() == 1 and use.to:contains(player) and use.from:objectName() ~= player:objectName() and player:hasSkill(skill:objectName()) and not use.card:isKindOf("EquipCard") and not table.contains(names, use.card:objectName()) then
				table.insert(names,use.card:objectName())
				room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
				local nullified_list = use.nullified_list
				table.insert(nullified_list, player:objectName())
				use.nullified_list = nullified_list
				data:setValue(use)

                player:setSkillInstanceStateValue(skill:objectName(), ref.key.instanceID, "names", sgs.QVariant(table.concat(names, "+")))
				local result = ""
				for i, v in ipairs(names) do
					if i > 1 then
						result = result .. "+|+"
					end
					result = result .. v
				end
				player:setSkillDescriptionSwap("rushB_moubazhen", "%arg11", result)
				room:changeTranslation(player, "rushB_moubazhen", 1)
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("SkillCard") then return false end
			if not player:hasSkill(skill:objectName()) or use.from:objectName() ~= player:objectName() or table.contains(names, use.card:objectName()) or use.card:isKindOf("EquipCard") then return false end
			room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
			table.insert(names, use.card:objectName())
			local nullified_list = use.nullified_list
			for _, p in sgs.qlist(use.to) do
				table.insert(nullified_list, p:objectName())
			end
			use.nullified_list = nullified_list
			data:setValue(use)

            player:setSkillInstanceStateValue(skill:objectName(), ref.key.instanceID, "names", sgs.QVariant(table.concat(names, "+")))
			local result = ""
			for i, v in ipairs(names) do
				if i > 1 then
					result = result .. "+|+"
				end
				result = result .. v
			end
			player:setSkillDescriptionSwap("rushB_moubazhen", "%arg11", result)
			room:changeTranslation(player, "rushB_moubazhen", 1)
		elseif event == sgs.Death then
		    local death = data:toDeath()
		    if death.who:objectName() ~= player:objectName() and player:hasSkill(skill:objectName()) then
		        room:addPlayerMark(player, "bazhendeath")
			end
		elseif event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "bazhendeath" and player:getMark(mark.name) > 0 and player:hasSkill(skill:objectName()) then
                if not room:sendShimingLog(ref, false) then return false end
                room:detachSkillFromPlayer(player, "tenyearguanxing")
                room:detachSkillFromPlayer(player, ref.key:toString())
			    room:acquireSkill(player, "olhuoji")
			    room:acquireSkill(player, "olkanpo")
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			if #names > room:alivePlayerCount() then
		        local players = sgs.SPlayerList()
			    for _, p in sgs.qlist(room:getAllPlayers()) do
				    if p:isAlive() then
				    	players:append(p)
				    end
			    end
			    if not players:isEmpty() and player:getMark("bazhendeath") == 0 then
                    if not room:sendShimingLog(ref) then return false end
                    room:acquireSkill(player, "kongcheng")
                    room:detachSkillFromPlayer(player, ref.key:toString(), true)
				    room:attachSkillToPlayer(player, "bazhen")
			    end
			end
	    end
	    return false
    end,
}
rushB_mouzhugeliang:addSkill("tenyearguanxing")
rushB_mouzhugeliang:addSkill(rushB_moubazhen)
sgs.LoadTranslationTable{
	["rushB_mouzhugeliang"] = "MK谋诸葛亮",
	["#rushB_mouzhugeliang"] = "暮年之志",
	["designer:rushB_mouzhugeliang"] = "俺的西木野Maki",
	["cv:rushB_mouzhugeliang"] = "官方",
	["illustrator:rushB_mouzhugeliang"] = "第七个桔子", --“谋定天下”
	["rushB_moubazhen"] = "八阵",
    [":rushB_moubazhen"] = "使命技，锁定技，当你成为其他角色使用非装备牌的唯一目标时或当你使用非装备牌时，若此牌名未被记录至【八阵图】，则你将此牌记录至【八阵图】内且此牌无效。\
	\
	成功：回合结束后，若【八阵图】内记录的项数大于全场角色数且没有角色已死亡，则你使命成功，获得“空城”，然后修改“八阵”。\
	\
	失败：若场上至少有一名角色已死亡，则你使命失败，失去“观星”、“八阵”，获得“火计”、“看破”。",
    [":rushB_moubazhen1"] = "使命技，锁定技，当你成为其他角色使用非装备牌的唯一目标时或当你使用非装备牌时，若此牌名未被记录至【八阵图】，则你将此牌记录至【八阵图】内且此牌无效。\
	\
	成功：回合结束后，若【八阵图】内记录的项数大于全场角色数且没有角色已死亡，则你使命成功，获得“空城”，然后修改“八阵”。\
	\
	失败：若场上至少有一名角色已死亡，则你使命失败，失去“观星”、“八阵”，获得“火计”、“看破”。\
	<font color=\"red\"><b>已记录：%arg11</b></font>",
	["$rushB_moubazhen1"] = "天有八门，地有八方！",
	["$rushB_moubazhen2"] = "我，就是智慧的化身！", --其实这个是“看破”语音，但是因为听着太带感（太搞）就加进去了
	["~rushB_mouzhugeliang"] = "龙困浅滩遭虾戏，虎落平阳被犬欺......",
}
---------------------------------
rushB_lvbu = sgs.General(extension, "rushB_lvbu", "qun")
rushB_wushuang = sgs.CreateTriggerSkillV2{
	name = "rushB_wushuang",
	events = {sgs.CardUsed, sgs.CardFinished, sgs.CardEffected, sgs.TargetSpecified, sgs.CardResponded},
	--global = true,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Duel") and not player:hasSkill(skill:objectName()) then
				for _, p in sgs.qlist(use.to) do
					if p:hasSkill(skill:objectName()) then
						return skill:objectName(), p:objectName()
					end
				end
				return false
			end
		elseif event == sgs.CardResponded or event == sgs.CardEffected then
			for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				return skill:objectName(), p:objectName()
			end
			return false
		end
		if player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local target = ctx.invoker
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from:objectName() == target:objectName() and use.from:hasSkill(skill:objectName()) then
				for _, p in sgs.qlist(use.to) do
					if use.to:contains(use.from) then return false end
					room:sendCompulsoryTriggerLog(use.from, skill:objectName(), true, true)
					if not room:askForCard(p, "jink", "@rushB_wushuang-jink", data, sgs.Card_MethodResponse, target, false, skill:objectName(), true, use.card) then
	                    room:setPlayerCardLimitation(p, "use, response", "Jink", false)
					end
				end
		    elseif use.card:isKindOf("Duel") and use.from:objectName() == target:objectName() and use.from:hasSkill(skill:objectName()) then
				for _, p in sgs.qlist(use.to) do
					if use.to:contains(use.from) then return false end
					room:sendCompulsoryTriggerLog(use.from, skill:objectName(), true, true)
					if not room:askForCard(p, "slash", "@rushB_wushuang-slash", data, sgs.Card_MethodResponse, target, false, skill:objectName(), true, use.card) then
	                    room:setPlayerCardLimitation(p, "use, response", "Slash", false)
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.from and use.from:hasSkill(skill:objectName()) then
				for _, p in sgs.qlist(use.to) do
					room:removePlayerCardLimitation(p, "use, response", "Slash$0")
				end
				for _, p in sgs.qlist(use.to) do
					room:removePlayerCardLimitation(p, "use, response", "Jink$0")
				end
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Duel") then
                local wushuang = {}
                if target:hasSkill(skill:objectName()) then
                    for _, p in sgs.qlist(use.to) do
                        table.insert(wushuang, p:objectName())
                    end
                end
                for _, p in sgs.qlist(use.to) do
                    if p:hasSkill(skill:objectName()) then
                        table.insert(wushuang, target:objectName())
                    end
                end
                room:setTag("rushB_wushuang_"..use.card:toString(), sgs.QVariant(table.concat(wushuang, "+")))
			elseif use.card:isKindOf("Slash") and target and target:isAlive() and target:hasSkill(skill:objectName()) then
				room:sendCompulsoryTriggerLog(target, skill:objectName())
				local jink_list = sgs.QList2Table(target:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_list[i + 1] == 1 then
						jink_list[i + 1] = 2
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_list))
				target:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		elseif event == sgs.CardResponded then
            local resp = data:toCardResponse()
            if resp.m_toCard and resp.m_toCard:isKindOf("Duel") and not target:hasFlag("rushB_wushuangSlash") then
                local wushuang = room:getTag("rushB_wushuang_" .. resp.m_toCard:toString()):toString()
                if wushuang and wushuang ~= "" then
                    if string.find(wushuang, target:objectName()) then
                        room:setPlayerFlag(target,"rushB_wushuangSlash")
                        if not room:askForCard(target, "slash", "duel-slash:"..resp.m_who:objectName(), room:getTag("rushB_wushuangData"), sgs.Card_MethodResponse, resp.m_who, false, "",false,resp.m_toCard) then
                            resp.nullified = true
                            data:setValue(resp)
                        end
                        room:setPlayerFlag(target,"-rushB_wushuangSlash")
                    end
                end
            end
		elseif event == sgs.CardEffected then
			 local effect = data:toCardEffect()
            if effect.card:isKindOf("Duel") then
                local wushuang = room:getTag("rushB_wushuang_" .. effect.card:toString()):toString()
                if wushuang and wushuang ~= "" then
                    if string.find(wushuang, effect.to:objectName()) or string.find(wushuang, effect.from:objectName()) then
                        room:setTag("rushB_wushuangData", data)
                    end
                end
			end
		end
		return false
	end,
}
rushB_lvbu:addSkill(rushB_wushuang)
sgs.LoadTranslationTable{
	["rushB_lvbu"] = "MK吕布",
	["#rushB_lvbu"] = "虓虎之勇",
	["designer:rushB_lvbu"] = "俺的西木野Maki",
	["cv:rushB_lvbu"] = "官方",
	["illustrator:rushB_lvbu"] = "7点Game",
	["rushB_wushuang"] = "无双",
    [":rushB_wushuang"] = "锁定技，每当你使用【杀】后，目标角色须打出一张非虚拟非转化的【闪】，否则其无法使用【闪】响应此【杀】；" ..
	"每当你使用【决斗】时，目标角色须打出一张非虚拟非转化的【杀】，否则其无法打出【杀】响应此【决斗】。" ..
	"锁定技，每当你指定【杀】的目标后，目标角色须使用两张【闪】抵消此【杀】。你指定或成为【决斗】的目标后，与你【决斗】的角色每次须连续打出两张【杀】。",
	["@rushB_wushuang-jink"] = "请打出一张非虚拟非转化【闪】，否则无法使用【闪】响应此【杀】",
	["@rushB_wushuang-slash"] = "请打出一张非虚拟非转化【杀】，否则无法打出【杀】响应此【决斗】",
	["$rushB_wushuang1"] = "乘赤兔，舞画戟，斩将破敌不过举手而为！",
	["$rushB_wushuang2"] = "此身此武，天下无双！",
	["~rushB_lvbu"] = "若有来生日，当斩一切敌！",
}
---------------------------------
rushB_liuye = sgs.General(extension, "rushB_liuye", "wei", 3)
rushB_poyuan = sgs.CreateTriggerSkillV2{
	name = "rushB_poyuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseStart then
			local poyuan1, poyuan2, n = false, false, 0
			if player:getPhase() == sgs.Player_RoundStart then
				if not player:getWeapon() and player:hasEquipArea(0) then
				    poyuan1 = true
				end
				if not player:getTreasure() and player:hasEquipArea(4) then
				    poyuan2 = true
				end
				if poyuan1 or poyuan2 then
					room:sendCompulsoryTriggerLog(player, skill:objectName())
					room:broadcastSkillInvoke(skill:objectName())
		            local ids, idt = sgs.IntList(), sgs.IntList()
		            for _, id in sgs.qlist(room:getDrawPile()) do
		            	if sgs.Sanguosha:getCard(id):isKindOf("Weapon") then
				            ids:append(id)
			            end
			            if sgs.Sanguosha:getCard(id):isKindOf("Treasure") then
				            idt:append(id)
			            end
		            end
			    	if poyuan1 and not ids:isEmpty() then
					    for _, id in sgs.qlist(ids) do
						    local card = sgs.Sanguosha:getCard(id)
				            room:useCard(sgs.CardUseStruct(card, player, player))
							break
						end
					elseif not poyuan1 or (poyuan1 and ids:isEmpty()) then
					    n = n + 2
				    end
			    	if poyuan2 and not idt:isEmpty() then
					    for _, id in sgs.qlist(idt) do
						    local card = sgs.Sanguosha:getCard(id)
				            room:useCard(sgs.CardUseStruct(card, player, player))
							break
						end
					elseif not poyuan2 or (poyuan2 and idt:isEmpty()) then
					    n = n + 2
				    end
					if n > 0 then
					    room:drawCards(player, n)
					end
				end
			end
		else
			local poyuan1, poyuan2 = false, false
			for i = 1, data:toDamage().damage do
				if not player:getWeapon() then
				    poyuan1 = true
				end
				if not player:getTreasure() then
				    poyuan2 = true
				end
				if poyuan1 and poyuan2 then
					room:sendCompulsoryTriggerLog(player, skill:objectName())
					room:broadcastSkillInvoke(skill:objectName())
					room:drawCards(player, 3, skill:objectName())
				elseif poyuan1 or poyuan2 then
					room:sendCompulsoryTriggerLog(player, skill:objectName())
					room:broadcastSkillInvoke(skill:objectName())
					room:drawCards(player, 2, skill:objectName())
				elseif not poyuan1 and not poyuan2 then
					room:sendCompulsoryTriggerLog(player, skill:objectName())
					room:broadcastSkillInvoke(skill:objectName())
					room:drawCards(player, 1, skill:objectName())
				end
			end
		end
		return false
	end,
}
rushB_huaceCard = sgs.CreateSkillCard{
	name = "rushB_huace",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
        local huaces, CardsPile = {}, nil
		if self:subcardsLength() == 0 then
			CardsPile = room:getDiscardPile()
		else
			CardsPile = room:getDrawPile()
			room:setCardFlag(sgs.Sanguosha:getCard(self:getSubcards():first()), "rushB_huace_vscard")
		end
		for _, id in sgs.qlist(CardsPile) do
			local c = sgs.Sanguosha:getEngineCard(id)
			if (c:isKindOf("BasicCard") or c:isNDTrick()) and not (c:isKindOf("Suijiyingbian") or c:isKindOf("Jink") or c:isKindOf("Nullification") or c:isKindOf("FczhizheBasic") or c:isKindOf("FczhizheTrick") or c:isKindOf("KezhuanYing") or c:isKindOf("BigJoker") or c:isKindOf("SmallJoker")) then
			    if not table.contains(huaces, c:objectName()) and source:getMark("rushB_huace"..c:objectName().."-PlayClear") < 1 then table.insert(huaces, c:objectName()) end
			end
		end
		if #huaces == 0 then
		    room:setPlayerFlag(source, "rushB_huaceNone")
		end
		local choice = room:askForChoice(source, "rushB_huace", table.concat(huaces, "+"))
		for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
			local c = sgs.Sanguosha:getEngineCard(id)
			if c:objectName() == choice then
				room:setPlayerMark(source, "rushB_huaceName", id) 
				break 
			end
		end
		if room:askForUseCard(source, "@rushB_huace", "@rushB_huace-ask:"..choice) then
			room:addPlayerMark(source, "rushB_huace"..choice.."-PlayClear")
		end
		
	end,
}
rushB_huaceVS = sgs.CreateViewAsSkillV2{
	name = "rushB_huace",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return not player:hasFlag("rushB_huaceNone")
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern() or ""
			return string.find(pattern, "@rushB_huace") ~= nil
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		local pattern = request:getPattern() or ""
		if string.find(pattern, "@rushB_huace") then
			return false
		else
			return candidate ~= nil
		end
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		local pattern = request:getPattern() or ""
		local ids = request:getSelectedCardIds()
		if string.find(pattern, "@rushB_huace") then
			local c = sgs.Sanguosha:getEngineCard(player:getMark("rushB_huaceName"))
			local transcard = sgs.Sanguosha:cloneCard(c:objectName())
			transcard:setSkillName(skill:objectName())
			return transcard
		else
			if ids:isEmpty() then
				local c = rushB_huaceCard:clone()
				c:setSkillName(skill:objectName())
				return c
			else
				local card = rushB_huaceCard:clone()
				for _, cd in sgs.qlist(ids) do
					card:addSubcard(cd)
				end
				card:setSkillName(skill:objectName())
				return card
			end
		end
	end,
}
rushB_huace = sgs.CreateTriggerSkillV2 {
	name = "rushB_huace",
	view_as_skill = rushB_huaceVS,
	events = { sgs.PreCardUsed },
	can_trigger = function(skill, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and table.contains(use.card:getSkillNames(), "rushB_huace") and not use.card:isKindOf("SkillCard") then
				for _,cd in sgs.list(player:getCards("he"))do
					if cd:hasFlag("rushB_huace_vscard") then
						room:setCardFlag(cd, "-rushB_huace_vscard")
						use.card:addSubcard(cd)
					end
				end
				data:setValue(use)
			end
		end
	end
}
rushB_liuye:addSkill(rushB_poyuan)
rushB_liuye:addSkill(rushB_huace)
sgs.LoadTranslationTable{
	["rushB_liuye"] = "MK刘晔",
	["#rushB_liuye"] = "霹雳惊雷",
	["designer:rushB_liuye"] = "Maki,FC",
	["cv:rushB_liuye"] = "官方",
	["illustrator:rushB_liuye"] = "匠人绘",
	["rushB_poyuan"] = "破垣",
	[":rushB_poyuan"] = "锁定技，回合开始时，若你的装备区内没有武器牌和宝物牌，则你依次使用一张武器牌和宝物牌（若无法使用对应的牌则改为摸两张牌）；" ..
	"当你受到1点伤害后，若你的装备区内：没有武器牌和宝物牌/有武器牌或宝物牌/有武器牌和宝物牌，则你摸三/二/一张牌。",
	["$rushB_poyuan1"] = "弹如飞星，恰如天崩摧城。",
	["$rushB_poyuan2"] = "石若雨下，断绝尔等生路。",
	["rushB_huace"] = "画策",
	["rushb_huace"] = "画策",
	["@rushB_huace"] = "你可以使用【%src】",
	["@rushB_huace-ask"] = "请为【%src】选择目标",
	--[":rushB_huace"] = "锁定技，当你使用普通锦囊牌或基本牌，或其他角色对你使用普通锦囊牌或基本牌时，你摸一张牌。" ..
	--"<font color='green'><b>出牌阶段每种牌名限一次，</b></font>你可以视为使用一张牌堆中的普通锦囊牌或基本牌，若使用以此法选择的牌，则清除此牌名。",
	[":rushB_huace"] = "<font color='green'><b>出牌阶段每种牌名限一次，</b></font>你可以视为使用一张弃牌堆中的普通锦囊牌或基本牌，或将一张牌当牌堆中的一张普通锦囊牌或基本牌使用。",
	["$rushB_huace1"] = "今破汉中，蜀人丧胆，当一举而克。",
	["$rushB_huace2"] = "推此向前，则蜀地传檄可定。",
	["~rushB_liuye"] = "两面逢迎，该有此报......",	
}
---------------------------------
rushB_caiyong = sgs.General(extension, "rushB_caiyong", "qun", 3)
rushB_pizhuanCard = sgs.CreateSkillCard{
	name = "rushB_pizhuan",
	will_throw = true,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local card_id = room:getDrawPile():first()
		local card = sgs.Sanguosha:getCard(card_id)
		if source:getMark(card:getSuit().."-Clear") < 1 then 
		    room:addPlayerMark(source, card:getSuit().."-Clear")
			source:addToPile("bookpile", card)
			if card:getSuit() == sgs.Card_Heart then
			    room:addPlayerMark(source, self:objectName().."1-Clear")
			elseif card:getSuit() == sgs.Card_Diamond then
			    room:addPlayerMark(source, self:objectName().."2-Clear")
			elseif card:getSuit() == sgs.Card_Club then
			    room:addPlayerMark(source, self:objectName().."3-Clear")
			elseif card:getSuit() == sgs.Card_Spade then
			    room:addPlayerMark(source, self:objectName().."4-Clear")
			end
		else
		    room:throwCard(card, source, nil)
		end
		if source:getMark(self:objectName().."1-Clear") > 0 and source:getMark(self:objectName().."2-Clear") > 0
		and source:getMark(self:objectName().."3-Clear") > 0 and source:getMark(self:objectName().."4-Clear") > 0 then 
			room:setPlayerFlag(source, "rushB_pizhuan")
		end
	end,
}
rushB_pizhuan = sgs.CreateViewAsSkillV2{
	name = "rushB_pizhuan",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getPile("bookpile"):length() < 4 and not player:hasFlag("rushB_pizhuan")
	end,
	create_card = function(skill, request)
		return rushB_pizhuanCard:clone()
	end,
}
rushB_pizhuan_cardmax = sgs.CreateMaxCardsSkillV2{
    name = "#rushB_pizhuan_cardmax",
    holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(skill, ctx)
	    local player = ctx:getHolder()
	    local n = 0
		if player and player:getPile("bookpile"):length() > 0 then
		    n = n + player:getPile("bookpile"):length()
		end
		return n
	end,
}
rushB_tongboCard = sgs.CreateSkillCard{
	name = "rushB_tongbo",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local pile = source:getPile("bookpile")
		local subCards = self:getSubcards()
		local to_handcard = sgs.IntList()
		local to_pile = sgs.IntList()
		local set = source:getPile("bookpile")
		for _,id in sgs.qlist(subCards) do
			set:append(id)
		end
		for _,id in sgs.qlist(set) do
			if not subCards:contains(id) then
				to_handcard:append(id)
			elseif not pile:contains(id) then
				to_pile:append(id)
			end
		end
		assert(to_handcard:length() == to_pile:length())
		if to_pile:length() == 0 or to_handcard:length() ~= to_pile:length() then return end
		source:addToPile("bookpile", to_pile, false)
		local to_handcard_x = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _,id in sgs.qlist(to_handcard) do
			to_handcard_x:addSubcard(id)
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, source:objectName())
		room:obtainCard(source, to_handcard_x, reason, false)
		to_handcard_x:deleteLater()
		local choices = {}
		local choice = nil
		local invoke = nil
		for _,id in sgs.qlist(room:getDrawPile()) do
		    local card = sgs.Sanguosha:getEngineCard(id)
			if card:isNDTrick() or card:isKindOf("BasicCard") then
				if table.contains(choices, card:objectName()) or card:isKindOf("Jink") or card:isKindOf("Nullification") then continue end
				local transcard = sgs.Sanguosha:cloneCard(card:objectName())
				transcard:setSkillName(self:objectName())
				transcard:deleteLater()
				if not transcard:isAvailable(source) then continue end
				if source:getMark(self:objectName().."+"..card:objectName().."-Clear") < 1 then table.insert(choices, card:objectName()) end
			end
			if not source:isWounded() then
				table.removeOne(choices, "peach")
			end
			if not sgs.Slash_IsAvailable(source) then
				table.removeOne(choices, "slash")
				table.removeOne(choices, "ice_slash")
				table.removeOne(choices, "thunder_slash")
				table.removeOne(choices, "fire_slash")
			end
			if not sgs.Analeptic_IsAvailable(source) then
				table.removeOne(choices, "analeptic")
			end
		end
		for _,id in sgs.qlist(room:getDiscardPile()) do
		    local card = sgs.Sanguosha:getEngineCard(id)
			if card:isNDTrick() or card:isKindOf("BasicCard") then
				if table.contains(choices, card:objectName()) or card:isKindOf("Jink") or card:isKindOf("Nullification") then continue end
				local transcard = sgs.Sanguosha:cloneCard(card:objectName())
				transcard:setSkillName(self:objectName())
				transcard:deleteLater()
				if not transcard:isAvailable(source) then continue end
				if source:getMark(self:objectName().."+"..card:objectName().."-Clear") < 1 then table.insert(choices, card:objectName()) end
			end
			if not source:isWounded() then
				table.removeOne(choices, "peach")
			end
			if not sgs.Slash_IsAvailable(source) then
				table.removeOne(choices, "slash")
				table.removeOne(choices, "ice_slash")
				table.removeOne(choices, "thunder_slash")
				table.removeOne(choices, "fire_slash")
			end
			if not sgs.Analeptic_IsAvailable(source) then
				table.removeOne(choices, "analeptic")
			end
		end
		if #choices > 0 then
		    choice = room:askForChoice(source, "rushB_tongbo", table.concat(choices, "+"))
		    for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
			    local c = sgs.Sanguosha:getEngineCard(id)
			    if c:objectName() == choice then
			        room:setPlayerMark(source, "rushB_tongboName", id)
					table.removeOne(choices, choice)
				    break 
			    end
		    end
			room:addPlayerMark(source, self:objectName().."+"..choice.."-Clear")
		    invoke = room:askForUseCard(source, "@@rushB_tongbo", "@rushB_tongbo")
		    for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
			    local c = sgs.Sanguosha:getEngineCard(id)
			    if c:objectName() == choice then
			        room:removePlayerMark(source, "rushB_tongboName", id)
			    end
		    end
		end
		if not invoke then
		    table.insert(choices, choice)
		end
		if #choices == 0 then
		    room:setPlayerFlag(source, "rushB_tongbo")
		end
	end,
}
rushB_tongboVS = sgs.CreateViewAsSkillV2{
	name = "rushB_tongbo",
	n = 999,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return not player:getPile("bookpile"):isEmpty() and not player:hasFlag("rushB_tongbo")
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return string.find(request:getPattern(), "@@rushB_tongbo") and not player:getPile("bookpile"):isEmpty()
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		if string.find(request:getPattern(), "@@rushB_tongbo") then return false end
		if not candidate then return false end
		local player = request:getInitiator()
		local ids = request:getSelectedCardIds()
		if player and ids:length() < player:getPile("bookpile"):length() then
			for _, id in sgs.qlist(ids) do
				if sgs.Sanguosha:getCard(id):getSuit() == candidate:getSuit() then return false end
			end
			return true
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		if string.find(request:getPattern(), "@@rushB_tongbo") then
			return request:getSelectedCardIds():isEmpty()
		end
		return player and request:getSelectedCardIds():length() == player:getPile("bookpile"):length()
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if string.find(request:getPattern(), "@@rushB_tongbo") then
			local c = sgs.Sanguosha:getEngineCard(player:getMark("rushB_tongboName"))
			local transcard = sgs.Sanguosha:cloneCard(c:objectName())
		    --transcard:addSubcard(player:getPile("bookpile"):first())
			transcard:setSkillName("_rushB_tongbo")
			return transcard
		end
		local ids = request:getSelectedCardIds()
		local skillcard = rushB_tongboCard:clone()
		for _, id in sgs.qlist(ids) do
			skillcard:addSubcard(id)
		end
		return skillcard
	end,
}
rushB_tongbo = sgs.CreateTriggerSkillV2 {
	name = "rushB_tongbo",
	view_as_skill = rushB_tongboVS,
	events = { sgs.PreCardUsed },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if use.card and table.contains(use.card:getSkillNames(), "rushB_tongbo") and not use.card:isKindOf("SkillCard") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		if use.card and not player:getPile("bookpile"):isEmpty() then
			use.card:addSubcard(player:getPile("bookpile"):first())
			data:setValue(use)
		end
		return false
	end
}

rushB_caiyong:addSkill(rushB_pizhuan)
rushB_caiyong:addSkill(rushB_pizhuan_cardmax)
extension:insertRelatedSkills("rushB_pizhuan", "#rushB_pizhuan_cardmax")
rushB_caiyong:addSkill(rushB_tongbo)
sgs.LoadTranslationTable{
	["rushB_caiyong"] = "MK蔡邕",
	["#rushB_caiyong"] = "妙笔生花",
	["designer:rushB_caiyong"] = "俺的西木野Maki",
	["cv:rushB_caiyong"] = "官方",
	["illustrator:rushB_caiyong"] = "zoo",
	["rushB_pizhuan"] = "辟撰",
	["rushb_pizhuan"] = "辟撰",
	["bookpile"] = "书",
	[":rushB_pizhuan"] = "出牌阶段，若你已记录的花色数以及X皆少于4，你可以将牌堆顶的一张未被记录花色的牌置于武将牌上（若该牌花色已被记录，改为弃置之），" ..
	"称为“书”并记录此“书”的花色；锁定技，你的手牌上限+X。（X为“书”的数量）",
	["$rushB_pizhuan1"] = "历史，谁也无法更改。",
	["$rushB_pizhuan2"] = "笔下成河，辟古开今。",
	["rushB_tongbo"] = "通博",
	["rushb_tongbo"] = "通博",
	["@rushB_tongbo"] = "你可以发动“通博”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	[":rushB_tongbo"] = "出牌阶段，你可以选择X张花色不同的牌替换等量的“书”，然后你可以将第一张“书”当做一张牌堆或弃牌堆中有的普通锦囊牌或基本牌使用。（X为“书”的数量）",
	["$rushB_tongbo1"] = "闻天下事，晓天下情。",
	["$rushB_tongbo2"] = "上通天地，下达九州。",
	["~rushB_caiyong"] = "我只求，写完汉史......",
}
---------------------------------
rushB_lijueguosi = sgs.General(extension, "rushB_lijueguosi", "qun")

rushB_xiongsuanvs = sgs.CreateViewAsSkillV2{
	name = "rushB_xiongsuan",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		return (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
			and string.find(request:getPattern(), "@@rushB_xiongsuan") ~= nil
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if string.find(request:getPattern(), "@@rushB_xiongsuan") then
			local c = sgs.Sanguosha:getEngineCard(player:getMark("rushB_xiongsuanName"))
			local transcard = sgs.Sanguosha:cloneCard(c:objectName())
			transcard:setSkillName(skill:objectName())
			return transcard
		end
		return nil
	end,
}
rushB_xiongsuan = sgs.CreateTriggerSkillV2{
	name = "rushB_xiongsuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.GameStart},
	view_as_skill = rushB_xiongsuanvs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart and (player:getPhase() == sgs.Player_Finish or player:getPhase() == sgs.Player_Discard or player:getPhase() == sgs.Player_Play
		or player:getPhase() == sgs.Player_Draw or player:getPhase() == sgs.Player_Judge or player:getPhase() == sgs.Player_Start) and player:hasSkill("keolranji")
		and room:askForChoice(player, skill:objectName(), "use+cancel") == "use" then
		    --room:askForUseCard(player, "@@rushB_xiongsuan", "rushB_xiongsuan-ask")
			local choices = {}
		    for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
		        local card = sgs.Sanguosha:getEngineCard(id)
			    if card:isKindOf("BasicCard") or card:isNDTrick() then
				    if table.contains(choices, card:objectName()) then continue end
				    local transcard = sgs.Sanguosha:cloneCard(card:objectName())
					transcard:deleteLater()
				    transcard:setSkillName("rushB_xiongsuan")
				    if not transcard:isAvailable(player) then continue end
					if player:getMark(skill:objectName().."+"..card:objectName().."-Clear") < 1 then table.insert(choices, card:objectName()) end
			    end
		    end
		    if #choices < 1 then return end
		    local choice = room:askForChoice(player, "rushB_xiongsuanUse", table.concat(choices, "+"))
		    for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
			    local c = sgs.Sanguosha:getEngineCard(id)
			    if c:objectName() == choice then
			        room:setPlayerMark(player, "rushB_xiongsuanName", id)
					table.removeOne(choices, choice)
				break end
		    end
			room:addPlayerMark(player, skill:objectName().."+"..choice.."-Clear")
		    room:askForUseCard(player, "@@rushB_xiongsuan", "rushB_xiongsuan-ask:"..choice)
		    room:setPlayerMark(player, "rushB_xiongsuanName", 0)
		elseif event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, "rushB_xiongsuan")
			room:broadcastSkillInvoke("rushB_xiongsuan", math.random(1, 2))
			local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
			local god_generals = {}
			for _, name in ipairs(all_generals) do
				local general = sgs.Sanguosha:getGeneral(name)
				if general:getKingdom() == "god" or general:getKingdom() == "wei" or general:getKingdom() == "shu" or general:getKingdom() == "wu" or general:getKingdom() == "qun" or general:getKingdom() == "jin" then
					for _, skill in sgs.qlist(general:getVisibleSkillList()) do
						if skill:getFrequency() == sgs.Skill_Limited and not player:hasSkill(skill:objectName()) then
							table.insert(god_generals, name)
						end
					end
				end
			end
			local n = 0
			for _, p in sgs.qlist(room:getAllPlayers(true)) do
				if table.contains(god_generals, p:getGeneralName()) then
					table.removeOne(god_generals, p:getGeneralName())
				end
				n = n + 1
			end
			local god_general = {}
			for i = 1, n do
				local first = god_generals[math.random(1, #god_generals)]
				if not table.contains(god_general, "keolmou_jiangwei") and math.random() > 0.8 then --彩蛋：偷偷替换成OL谋姜维
					table.insert(god_general, "keolmou_jiangwei")
				else
					table.insert(god_general, first)
				end
				table.removeOne(god_generals, first)
			end
			local m = 1
			while m > 0 do
				local generals = table.concat(god_general, "+")
				local general = sgs.Sanguosha:getGeneral(room:askForGeneral(player, generals))
				local skill_names = {}
				for _, skill in sgs.qlist(general:getVisibleSkillList()) do
					if skill:getFrequency() == sgs.Skill_Limited and not player:hasSkill(skill:objectName()) then
						table.insert(skill_names, skill:objectName())
					end
				end
				if #skill_names > 0 then
					local one = room:askForChoice(player, "rushB_xiongsuan", table.concat(skill_names, "+"))
					room:acquireSkill(player, one)
					m = m - 1
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			room:sendCompulsoryTriggerLog(player, "rushB_xiongsuan")
			room:broadcastSkillInvoke("rushB_xiongsuan", math.random(1, 2))
			local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
			local god_generals = {}
			for _, name in ipairs(all_generals) do
				local general = sgs.Sanguosha:getGeneral(name)
				if general:getKingdom() == "god" or general:getKingdom() == "wei" or general:getKingdom() == "shu" or general:getKingdom() == "wu" or general:getKingdom() == "qun" or general:getKingdom() == "jin" then
					for _, skill in sgs.qlist(general:getVisibleSkillList()) do
						if skill:getFrequency() == sgs.Skill_Limited and not player:hasSkill(skill:objectName()) then
							table.insert(god_generals, name)
						end
					end
				end
			end
			local n = 0
			for _, p in sgs.qlist(room:getAllPlayers(true)) do
				if table.contains(god_generals, p:getGeneralName()) then
					table.removeOne(god_generals, p:getGeneralName())
				end
				n = n + 1
			end
			local god_general = {}
			for i = 1, n do
				local first = god_generals[math.random(1, #god_generals)]
				if not table.contains(god_general, "keolmou_jiangwei") and math.random() > 0.9 then --彩蛋：偷偷替换成OL谋姜维
					table.insert(god_general, "keolmou_jiangwei")
				else
					table.insert(god_general, first)
				end
				table.removeOne(god_generals, first)
			end
			local m = 1
			while m > 0 do
				local generals = table.concat(god_general, "+")
				local general = sgs.Sanguosha:getGeneral(room:askForGeneral(player, generals))
				local skill_names = {}
				for _, skill in sgs.qlist(general:getVisibleSkillList()) do
					if skill:getFrequency() == sgs.Skill_Limited and not player:hasSkill(skill:objectName()) then
						table.insert(skill_names, skill:objectName())
					end
				end
				if #skill_names > 0 then
					local one = room:askForChoice(player, "rushB_xiongsuan", table.concat(skill_names, "+"))
					room:acquireNextTurnSkills(player, "rushB_xiongsuan", one)
					m = m - 1
				end
			end
		end
	end,
}
--rushB_xiongsuan:setGuhuoDialog("lr")
rushB_lijueguosi:addSkill(rushB_xiongsuan)
sgs.LoadTranslationTable{
	["rushB_lijueguosi"] = "MK李傕＆郭汜",
	["&rushB_lijueguosi"] = "MK李傕郭汜",
	["#rushB_lijueguosi"] = "祸乱长安",
	["designer:rushB_lijueguosi"] = "俺的西木野Maki",
	["cv:rushB_lijueguosi"] = "官方",
	["illustrator:rushB_lijueguosi"] = "MUMU",
	["rushB_xiongsuanUse"] = "凶算",
	["rushB_xiongsuan"] = "凶算",
	["rushB_xiongsuan-ask"] = "你可以发动“燃己”<br/> <b>操作提示</b>: 选择等同于此【%src】目标数的角色→点击确定<br/>",
	[":rushB_xiongsuan"] = "锁定技，回合开始时，你从三位有限定技的(官方势力)武将中选择一个限定技并获得；你于下回合开始时失去不于游戏开始时获得且以此法获得的限定技；" ..
	"回合开始时，若你有技能“燃己”<font color=\"red\"><b>(注:OL谋姜维的限定技)</b></font>，则你每个阶段开始时可视为使用一张本回合未以此法使用过的基本牌或普通锦囊牌。",
	["$rushB_xiongsuan1"] = "哼哼哼哼，天子在我二人手中，天下就在我二人手中！",
	["$rushB_xiongsuan2"] = "政事朝纲，唯我二人专擅！",
	["~rushB_lijueguosi"] = "额...汝何必与我相争，以致两败之境......",
}
---------------------------------
rushB_mousunquan = sgs.General(extension, "rushB_mousunquan$", "wu")
rushB_moutongyeCard = sgs.CreateSkillCard{
	name = "rushB_moutongye",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, player)
		local n = player:getChangeSkillState("rushB_moutongye")
		if n == 1 then
			room:setChangeSkillState(player, "rushB_moutongye", 2)
		elseif n == 2 then
			room:setChangeSkillState(player, "rushB_moutongye", 3)
		elseif n == 3 then
			room:setChangeSkillState(player, "rushB_moutongye", 1)
		end
	end,
}
rushB_moutongyevs = sgs.CreateViewAsSkillV2{
	name = "rushB_moutongye",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:usedTimes("#rushB_moutongye") + player:usedTimes("rushB_moutongye") < 1
	end,
	create_card = function(skill, request)
		return rushB_moutongyeCard:clone()
	end,
}
rushB_moutongye = sgs.CreateTriggerSkillV2{
	name = "rushB_moutongye",
	--global = true,
	events = {sgs.CardUsed, sgs.GameStart},
	view_as_skill = rushB_moutongyevs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local n = player:getChangeSkillState("rushB_moutongye")
		if event == sgs.CardUsed then
			local use = data:toCardUse()
		    if use.card:isKindOf("BasicCard") and (n == 2 or n == 3) then
			    room:sendCompulsoryTriggerLog(player, skill:objectName())
			    room:broadcastSkillInvoke(skill:objectName())
				player:drawCards(1)
			end
		    if use.card:isKindOf("TrickCard") and (n == 1 or n == 3) then
			    room:sendCompulsoryTriggerLog(player, skill:objectName())
			    room:broadcastSkillInvoke(skill:objectName())
				player:drawCards(1)
			end
		    if use.card:isKindOf("EquipCard") and (n == 1 or n == 2) then
			    room:sendCompulsoryTriggerLog(player, skill:objectName())
			    room:broadcastSkillInvoke(skill:objectName())
				player:drawCards(1)
			end
		else
			room:setChangeSkillState(player, "rushB_moutongye", 1)
		end
		return false
	end,
}
rushB_moutongye_ex = sgs.CreateProhibitSkill{
	name = "#rushB_moutongye_ex",
	is_prohibited = function(self, from, to, card)
		local n, x = from:getChangeSkillState("rushB_moutongye"), to:getChangeSkillState("rushB_moutongye")
		if from:hasSkill("rushB_moutongye") then
			if n == 1 then
		    	return card:isKindOf("BasicCard") and from and from:hasSkill("rushB_moutongye") and to
			elseif n == 2 then
		    	return card:isKindOf("TrickCard") and from and from:hasSkill("rushB_moutongye") and to
			elseif n == 3 then
		    	return card:isKindOf("EquipCard") and from and from:hasSkill("rushB_moutongye") and to
			end
		elseif to:hasSkill("rushB_moutongye") then
			if x == 1 then
		    	return card:isKindOf("BasicCard") and from and from:objectName() ~= to:objectName() and to and to:hasSkill("rushB_moutongye")
			elseif x == 2 then
		    	return card:isKindOf("TrickCard") and from and from:objectName() ~= to:objectName() and to and to:hasSkill("rushB_moutongye")
			elseif x == 3 then
		    	return card:isKindOf("EquipCard") and from and from:objectName() ~= to:objectName() and to and to:hasSkill("rushB_moutongye")
			end
		end
	end,
}
rushB_moutongye_extra = sgs.CreateTargetModSkillV2{
	name = "#rushB_moutongye_extra",
	frequency = sgs.Skill_Compulsory,
	pattern = "^SkillCard",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local modType = ctx:getModType()
		if modType ~= sgs.TargetModSkill_Residue and modType ~= sgs.TargetModSkill_DistanceLimit then
			return nil
		end
		local from = ctx:getPrimary()
		local card = ctx:getCard()
		local n, x = from:getChangeSkillState("rushB_moutongye"), 0
		if from:hasSkill("rushB_moutongye") and card then
		    if card:isKindOf("BasicCard") and (n == 2 or n == 3) then
			    x = 1000
			end
		    if card:isKindOf("TrickCard") and (n == 1 or n == 3) then
			    x = 1000
			end
		    if card:isKindOf("EquipCard") and (n == 1 or n == 2) then
			    x = 1000
			end
		end
		return x
	end,
}
rushB_mousunquan:addSkill("tenyearzhiheng")
rushB_mousunquan:addSkill(rushB_moutongye)
rushB_mousunquan:addSkill(rushB_moutongye_ex)
rushB_mousunquan:addSkill(rushB_moutongye_extra)
extension:insertRelatedSkills("rushB_moutongye", "#rushB_moutongye_ex")
extension:insertRelatedSkills("rushB_moutongye", "#rushB_moutongye_extra")
rushB_mousunquan:addSkill("tenyearjiuyuan")
sgs.LoadTranslationTable{
	["rushB_mousunquan"] = "MK谋孙权",
	["#rushB_mousunquan"] = "永开吴祚",
	["designer:rushB_mousunquan"] = "俺的西木野Maki",
	["cv:rushB_mousunquan"] = "官方",
	["illustrator:rushB_mousunquan"] = "陈层",
	["rushB_moutongye"] = "统业",
	["rushb_moutongye"] = "统业",
	[":rushB_moutongye"] = "出牌阶段限一次，你可以变更“统业”的状态。锁定技，你需按照顺序依次执行以下一项：" ..
	"①于下次发动“统业”前你不能使用基本牌且不能成为其他角色使用基本牌的目标；" ..
	"②于下次发动“统业”前你不能使用锦囊牌且不能成为其他角色使用锦囊牌的目标；" ..
	"③于下次发动“统业”前你不能使用装备牌且不能成为其他角色使用装备牌的目标。" ..
	"若如此做，你于下次发动“统业”前使用可使用的类别的牌时摸一张牌且无次数和距离限制。",
	[":rushB_moutongye1"] = "出牌阶段限一次，你可以变更“统业”的状态。锁定技，你需按照顺序依次执行以下一项：" ..
	"①于下次发动“统业”前你不能使用基本牌且不能成为其他角色使用基本牌的目标；" ..
	"②于下次发动“统业”前你不能使用锦囊牌且不能成为其他角色使用锦囊牌的目标；" ..
	"③于下次发动“统业”前你不能使用装备牌且不能成为其他角色使用装备牌的目标。" ..
	"若如此做，你于下次发动“统业”前使用可使用的类别的牌时摸一张牌且无次数和距离限制。<font color='red'><b>状态：①<b></font>",
	[":rushB_moutongye2"] = "出牌阶段限一次，你可以变更“统业”的状态。锁定技，你需按照顺序依次执行以下一项：" ..
	"①于下次发动“统业”前你不能使用基本牌且不能成为其他角色使用基本牌的目标；" ..
	"②于下次发动“统业”前你不能使用锦囊牌且不能成为其他角色使用锦囊牌的目标；" ..
	"③于下次发动“统业”前你不能使用装备牌且不能成为其他角色使用装备牌的目标。" ..
	"若如此做，你于下次发动“统业”前使用可使用的类别的牌时摸一张牌且无次数和距离限制。<font color='red'><b>状态：②<b></font>",
	[":rushB_moutongye3"] = "出牌阶段限一次，你可以变更“统业”的状态。锁定技，你需按照顺序依次执行以下一项：" ..
	"①于下次发动“统业”前你不能使用基本牌且不能成为其他角色使用基本牌的目标；" ..
	"②于下次发动“统业”前你不能使用锦囊牌且不能成为其他角色使用锦囊牌的目标；" ..
	"③于下次发动“统业”前你不能使用装备牌且不能成为其他角色使用装备牌的目标。" ..
	"若如此做，你于下次发动“统业”前使用可使用的类别的牌时摸一张牌且无次数和距离限制。<font color='red'><b>状态：③<b></font>",
	["$rushB_moutongye1"] = "定四海之纷乱，统宇内之九州。",
	["$rushB_moutongye2"] = "据天险而为吴主，开国祚统江山之永固。",
	["~rushB_mousunquan"] = "天下一统，吾终不可得乎......",
}
---------------------------------
rushB_peixiu = sgs.General(extension, "rushB_peixiu", "wei")
rushB_xingtu = sgs.CreateTriggerSkillV2{
    name = "rushB_xingtu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardUsed or event == sgs.CardResponded then
			local card = nil
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				card = use.card
			else
				card = data:toCardResponse().m_card
			end
		    local x, xingtu, n = player:getMark("&".."rushB_xingtunum"), false, card:getNumber()
		    if card:isKindOf("SkillCard") then return false end
		    if x > 0 then
				for i=1,x do
					if x/n==i then
						xingtu = true
						break
					end
				end
		        if xingtu then
			        room:sendCompulsoryTriggerLog(player, skill:objectName())
			        room:broadcastSkillInvoke(skill:objectName())
					if player:isKongcheng() then
			            room:addPlayerMark(player, "&rushB_xingtudraw")
						local n = player:getMark("&rushB_xingtudraw")
						room:drawCards(player, 1+n, skill:objectName())
						player:setSkillDescriptionSwap("rushB_xingtu", "%arg11", n+1)
                        room:changeTranslation(player, "rushB_xingtu", 1)
					else
			            room:drawCards(player, 1, skill:objectName())
					end
		        end
		    end
		elseif event == sgs.CardFinished or event == sgs.CardResponded then
			local card = nil
			if event == sgs.CardFinished then
				local use = data:toCardUse()
				card = use.card
			else
				card = data:toCardResponse().m_card
			end
		    local n = card:getNumber()
		    if card:isKindOf("SkillCard") then return false end
		    room:setPlayerMark(player, "&".."rushB_xingtunum", n)
		end
	end,
}
rushB_xingtuAudio = sgs.CreateTriggerSkillV2{
    name = "#rushB_xingtuAudio",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardResponded},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) and player:hasSkill("rushB_xingtu") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		local x, m, n = card:getNumber(), player:getMark("&".."rushB_xingtunum"), false
		if card:isKindOf("SkillCard") or not card:isKindOf("Slash") then return false end
		for i=1,x do
			if m*i==x then
				n = true
			end
		end
		if n then
		    room:sendCompulsoryTriggerLog(player, "rushB_xingtu")
		    room:broadcastSkillInvoke("rushB_xingtu")
		end
		return false
	end,
}
rushB_xingtu_extra = sgs.CreateTargetModSkillV2{
	name = "#rushB_xingtu_extra",
	frequency = sgs.Skill_Compulsory,
	pattern = "^SkillCard",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local modType = ctx:getModType()
		if modType ~= sgs.TargetModSkill_Residue and modType ~= sgs.TargetModSkill_DistanceLimit then
			return nil
		end
		local from = ctx:getPrimary()
		local card = ctx:getCard()
		local x, m, n = card and card:getNumber() or 0, from:getMark("&".."rushB_xingtunum"), 0
		if from:hasSkill("rushB_xingtu") then
			for i=1,x do
				if m*i==x then
					n = n + 1000
				end
			end
		end
		return n
	end,
}
rushB_juezhiCard = sgs.CreateSkillCard{
	name = "rushB_juezhi",
	will_throw = true,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local x, invoke, n = 0, false, source:getChangeSkillState(self:objectName())
		x = math.min(sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber() + sgs.Sanguosha:getCard(self:getSubcards():last()):getNumber(), 13)
		local to_obtain
		for i=1,x do
			if x % i==0 then
				if not to_obtain then
					to_obtain = i
				elseif math.random() < 0.5 then
					to_obtain = i
				end
			end
		end
		if source:isNude() then
		    invoke = true
		end
		local g = source:getMark("&rushB_juezhiGet")
		while g >= 0 do
			local ids = sgs.IntList()
			for _,id in sgs.qlist(room:getDrawPile()) do
				local m = sgs.Sanguosha:getCard(id):getNumber()
				if m > 13 then m = 13 end
		    	if m == to_obtain then
					ids:append(id)
				end
			end
			if not ids:isEmpty() then
				room:obtainCard(source, ids:at(0), false)
			end
			g = g - 1
		end
		if invoke then
			if n == 1 then
		    	source:drawCards(math.min(5, source:getMaxHp()))
				room:setChangeSkillState(source, self:objectName(), 2)
			else
				room:addPlayerMark(source, "&rushB_juezhiGet")
				room:setChangeSkillState(source, self:objectName(), 1)
			end
		end
	end,
}
rushB_juezhivs = sgs.CreateViewAsSkillV2{
	name = "rushB_juezhi",
	n = 2,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:getEquips():length() + player:getHandcardNum() >= 2
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate then return false end
		local ids = request:getSelectedCardIds()
		if ids:length() == 0 then
			return true
		elseif ids:length() == 1 then
		    local x = sgs.Sanguosha:getCard(ids:first()):getNumber()
		    if x > 0 then
				for i=1,13 do
					if x*i==candidate:getNumber() then
						return true
					end
				end
			else
			    return true
		    end
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() >= 2
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() <= 1 then return nil end
		local skillcard = rushB_juezhiCard:clone()
		for _, id in sgs.qlist(ids) do
			skillcard:addSubcard(id)
		end
		return skillcard
	end,
}
rushB_juezhi = sgs.CreateTriggerSkillV2{
	name = "rushB_juezhi",
	change_skill = true,
	events = {sgs.RoundStart},
	view_as_skill = rushB_juezhivs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local n = player:getChangeSkillState("rushB_juezhi")
		local count = room:getTag("TurnLengthCount"):toInt()
		if n == 1 and count > 1 then
			room:setChangeSkillState(player, skill:objectName(), 2)
		else
			room:setChangeSkillState(player, skill:objectName(), 1)
		end
		return false
	end,
}
rushB_peixiu:addSkill(rushB_xingtu)
rushB_peixiu:addSkill(rushB_xingtuAudio)
rushB_peixiu:addSkill(rushB_xingtu_extra)
extension:insertRelatedSkills("rushB_xingtu", "#rushB_xingtuAudio")
extension:insertRelatedSkills("rushB_xingtu", "#rushB_xingtu_extra")
rushB_peixiu:addSkill(rushB_juezhi)
sgs.LoadTranslationTable{
	["rushB_peixiu"] = "MK裴秀",
	["#rushB_peixiu"] = "登高勘形",
	["designer:rushB_peixiu"] = "俺的西木野Maki",
	["cv:rushB_peixiu"] = "官方",
	["illustrator:rushB_peixiu"] = "凡果",
    ["rushB_xingtu"] = "行图",
	["rushB_xingtunum"] = "行图点数",
	["rushB_xingtudraw"] = "行图摸牌+",
	[":rushB_xingtu"] = "锁定技，你使用牌结算结束后记录此牌点数。你使用牌时，若此牌点数为“行图”记录点数的约数，你摸[1]张牌，若你没有手牌则令“[]”里的数字+1；你使用点数为“行图”记录点数的倍数的牌无次数和距离限制。",
	[":rushB_xingtu1"] = "锁定技，你使用牌结算结束后记录此牌点数。你使用牌时，若此牌点数为“行图”记录点数的约数，你摸[%arg11]张牌，若你没有手牌则令“[]”里的数字+1；你使用点数为“行图”记录点数的倍数的牌无次数和距离限制。",
	["$rushB_xingtu1"] = "考古之郡国、今之州县，为地图一十八篇。",
	["$rushB_xingtu2"] = "水陆之径若绘之以记，则无所忘失。",
	["rushB_juezhi"] = "爵制",
	["rushb_juezhi"] = "爵制",
	["rushB_juezhiGet"] = "爵制得牌+",
	[":rushB_juezhi"] = "转换技，出牌阶段，你可以弃置两张牌（弃置的第二张牌须为第一张牌的倍数），然后从牌库中随机获得[1]张点数为X的约数的牌（X为你弃置牌点数之和，若X大于13则X为13）。" ..
	"若弃置牌后你没有牌，①摸Y张牌（Y为体力上限且至多为5）；②令“[]”里的数字+1。每轮开始时，你转换状态。",
	[":rushB_juezhi1"] = "转换技，出牌阶段，你可以弃置两张牌（弃置的第二张牌须为第一张牌的倍数），然后从牌库中随机获得[1]张点数为X的约数的牌（X为你弃置牌点数之和，若X大于13则X为13）。" ..
	"若弃置牌后你没有牌，①摸Y张牌（Y为体力上限且至多为5）；②令“[]”里的数字+1。每轮开始时，你转换状态。<font color=\"red\"><b>状态：①</b></font>",
	[":rushB_juezhi2"] = "转换技，出牌阶段，你可以弃置两张牌（弃置的第二张牌须为第一张牌的倍数），然后从牌库中随机获得[1]张点数为X的约数的牌（X为你弃置牌点数之和，若X大于13则X为13）。" ..
	"若弃置牌后你没有牌，①摸Y张牌（Y为体力上限且至多为5）；②令“[]”里的数字+1。每轮开始时，你转换状态。<font color=\"red\"><b>状态：②</b></font>",
	["$rushB_juezhi1"] = "复恢爵制，分土画疆，则官民皆可定也。",
	["$rushB_juezhi2"] = "为国效忠者，自增封加爵、进德酬功。",
	["~rushB_peixiu"] = "不能再佐陛下，臣甚憾之......",
}

---------------------------------
sgsup_zhebang = sgs.General(extension, "sgsup_zhebang", "qun", 3)
sgskanxueSlash = sgs.CreateFilterSkill{
	name = "sgskanxueSlash&", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (place == sgs.Player_PlaceHand) and to_select:isRed()
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName("sgskanxue")
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end,
}
sgskanxueCard = sgs.CreateSkillCard{
	name = "sgskanxue",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:showAllCards(source)
		room:addPlayerMark(source, "&sgskanxue")
		local card_id = room:askForDiscard(source, self:objectName(), 1, 1)
		local invoke --= false
		if sgs.Sanguosha:getCard(card_id:getSubcards():first()):isKindOf("BasicCard") then
		    invoke = 1 --"BasicCard"
		elseif sgs.Sanguosha:getCard(card_id:getSubcards():first()):isKindOf("TrickCard") then
		    invoke = 2 --"TrickCard"
		elseif sgs.Sanguosha:getCard(card_id:getSubcards():first()):isKindOf("EquipCard") then
		    invoke = 3 --"EquipCard"
		end
		local kanxue = false
		for _,p in sgs.qlist(room:getOtherPlayers(source)) do
            local choices = {}			
			if not p:hasSkill("sgskanxueSlash") then
				table.insert(choices, "acquirekanxue")
			end
			for _,card in sgs.qlist(p:getHandcards()) do
				--if card:isKindOf(invoke) then
				if (invoke == 1 and card:isKindOf("BasicCard")) or (invoke == 2 and card:isKindOf("TrickCard")) or (invoke == 3 and card:isKindOf("EquipCard")) then
					kanxue = true
				end
			end		
			if kanxue then table.insert(choices, "throwsame") end
		    local choice = room:askForChoice(p, self:objectName(), table.concat(choices, "+"))
			local log = sgs.LogMessage()
			log.type = "#sgskanxue"
			log.arg = choice
			log.to:append(p)
			room:sendLog(log)
			if choice == "throwsame" then
		        room:showAllCards(p)
			    --room:askForDiscard(p, self:objectName(), 1, 1, false, false, "sgskanxue-discard", invoke)
				if invoke == 1 then
					room:askForDiscard(p, self:objectName(), 1, 1, false, false, "sgskanxue-discard", "BasicCard")
				elseif invoke == 2 then
					room:askForDiscard(p, self:objectName(), 1, 1, false, false, "sgskanxue-discard", "TrickCard")
				elseif invoke == 3 then
					room:askForDiscard(p, self:objectName(), 1, 1, false, false, "sgskanxue-discard", "EquipCard")
				end
			else
			    room:acquireOneTurnSkills(p, self:objectName(), "sgskanxueSlash") --room:attachSkillToPlayer(p, "sgskanxueSlash")
				room:filterCards(p, p:getCards("he"), true)
			end
		end
	end,
}
sgskanxuevs = sgs.CreateViewAsSkillV2{
    name = "sgskanxue",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:isKongcheng()
			and player:usedTimes("#sgskanxue") + player:usedTimes("sgskanxue") < 1
	end,
	create_card = function(skill, request)
		return sgskanxueCard:clone()
	end,
}
sgskanxue = sgs.CreateTriggerSkillV2{
	name = "sgskanxue",
	--global = true,
	events = {sgs.EventPhaseChanging},
	view_as_skill = sgskanxuevs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) and player:getMark("&sgskanxue") > 0 then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("&sgskanxue") > 0 then
			    --[[for _, p in sgs.qlist(room:getAllPlayers()) do
				    if p:hasSkill("sgskanxueSlash") then
					    room:detachSkillFromPlayer(p, "sgskanxueSlash", true)
				    end
			    end]]
				room:removePlayerMark(player, "&sgskanxue")
		    end
		end
		return false
	end,
}
sgszhenhuaCard = sgs.CreateSkillCard{
	name = "sgszhenhua",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:getMark(self:objectName().."-Clear") < 1 and not to_select:isNude()
	end,
	feasible = function(self, targets, player)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local id = room:askForCardChosen(source, targets[1], "he", self:objectName())
		room:throwCard(id, targets[1], source)
		source:drawCards(1)
		targets[1]:drawCards(1)
		room:addPlayerMark(targets[1], self:objectName().."-Clear")
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if source:canSlash(p, nil, false) then
				players:append(p)
			end
		end
		if sgs.Sanguosha:getCard(id):isRed() then
		    room:addPlayerHistory(source, "#sgszhenhua", -1)
		    room:addPlayerHistory(source, "sgszhenhua", -1)
		end
		if sgs.Sanguosha:getCard(id):isKindOf("Slash") and not players:isEmpty() then
			local target = room:askForPlayerChosen(source, players, self:objectName(), "@choose-players", true, false)
			if not target then return false end
			room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(id), source, target))
		end
	end,
}
sgszhenhua = sgs.CreateViewAsSkillV2{
	name = "sgszhenhua",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not (player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY) then return false end
		local players = player:getSiblings()
		players:append(player)
	    for _, sib in sgs.qlist(players) do
			if not sib:isNude() and sib:getMark(skill:objectName().."-Clear") < 1 then
				return player:usedTimes("#sgszhenhua") + player:usedTimes("sgszhenhua") < 1
			end
		end
		return false
	end,
	create_card = function(skill, request)
		return sgszhenhuaCard:clone()
	end,
}
if not sgs.Sanguosha:getSkill("sgskanxueSlash") then skills:append(sgskanxueSlash) end
sgsup_zhebang:addSkill(sgskanxue)
sgsup_zhebang:addSkill(sgszhenhua)
sgs.LoadTranslationTable{
	["sgsup_zhebang"] = "折棒",
	["#sgsup_zhebang"] = "看学浪",
	["designer:sgsup_zhebang"] = "吃蛋挞的折棒",
	["cv:sgsup_zhebang"] = "吃蛋挞的折棒",
	["illustrator:sgsup_zhebang"] = "吃蛋挞的折棒",
	["sgskanxue"] = "看学",
	["sgskanxueSlash"] = "看学杀",
	["throwsame"] = "展示所有手牌，并弃置一张同类型的牌",
	["acquirekanxue"] = "直到回合结束，所有红色手牌均视为【杀】",
	["#sgskanxue"] = "%to 选择了 %arg",
	["sgskanxue-discard"] = "看学：请弃置一张牌",
    [":sgskanxue"] = "出牌阶段限一次，你可以展示所有手牌并弃置一张牌，然后令所有其他角色选择一项：1.展示所有手牌，并弃置一张同类型的牌；2.直到回合结束，所有红色手牌均视为【杀】。",
	["$sgskanxue1"] = "看折棒，学折棒，学好技术才能浪。哈喽！大家好，我是折棒。",
	["$sgskanxue2"] = "众所周知，三国杀是一款非常平衡的游戏。",
	["sgszhenhua"] = "震华",
	[":sgszhenhua"] = "出牌阶段限一次，你可以弃置一名角色一张牌，然后你与该角色各摸一张牌。若所弃牌为：红色，此技能视为未使用过（本回合不能选择相同目标）；【杀】，你可以使用之，此【杀】不计入次数。",
	["$sgszhenhua1"] = "威震华夏的武圣关云长，拥有将红牌当杀的神技。",
	["$sgszhenhua2"] = "而历史角落的无名小卒，却只能一轮八十牌。",
	["~sgsup_zhebang"] = "好的，那么本期视频就到这里，如果大家喜欢这期视频的话，请务必给个点赞、收藏、投币一键三连，支持下up主以及关注我。我是折棒，让我们下期视频再见。",
}
---------------------------------
rushB_zhebang = sgs.General(extension, "rushB_zhebang", "qun")
rushB_kanxue_extra = sgs.CreateTargetModSkillV2{
	name = "#rushB_kanxue_extra",
	frequency = sgs.Skill_Compulsory,
	pattern = "^SkillCard",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local from = ctx:getPrimary()
		local card = ctx:getCard()
		local modType = ctx:getModType()
		if modType == sgs.TargetModSkill_Residue then
			if from:hasSkill("rushB_kanxue") and card and card:getSuit() == sgs.Card_Heart and card:isKindOf("Slash") then
				return 1000
			end
		elseif modType == sgs.TargetModSkill_DistanceLimit then
			if from:hasSkill("rushB_kanxue") and card and card:getSuit() == sgs.Card_Diamond and card:isKindOf("Slash") then
				return 1000
			end
		end
		return 0
	end,
}
rushB_kanxuevs = sgs.CreateViewAsSkillV2{
	name = "rushB_kanxue",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local wusheng = false
			if player:getMark(skill:objectName().."-Clear") > 0 then
				for _, card in sgs.qlist(player:getHandcards()) do
				    if card:getSuit() == sgs.Card_Heart then
					    wusheng = true
					end
				end
				for _, card in sgs.qlist(player:getEquips()) do
				    if card:getSuit() == sgs.Card_Heart or card:isKindOf("Crossbow") then
					    wusheng = true
					end
				end
			else
				for _, card in sgs.qlist(player:getHandcards()) do
				    if card:isRed() then
					    wusheng = true
					end
				end
				for _, card in sgs.qlist(player:getEquips()) do
				    if card:isRed() then
					    wusheng = true
					end
				end
			end
			return wusheng
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			if request:getPattern() ~= "slash" then return false end
			local wusheng = false
			for _, card in sgs.qlist(player:getHandcards()) do
				if card:isRed() then
					wusheng = true
				end
			end
			for _, card in sgs.qlist(player:getEquips()) do
				if card:isRed() then
					wusheng = true
				end
			end
			return wusheng
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate then return false end
		local player = request:getInitiator()
		if player and player:getMark(skill:objectName().."-Clear") > 0 then
			for _, card in sgs.qlist(player:getEquips()) do
			    if card:isKindOf("Crossbow") then
				    return candidate:isRed()
				end
			end
			return candidate:getSuit() == sgs.Card_Heart
		else
		    return candidate:isRed()
		end
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local new_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
		if new_card then
			new_card:setSkillName("rushB_kanxue_tenyearwusheng")
			for _, id in sgs.qlist(ids) do
				new_card:addSubcard(id)
			end
		end
		return new_card
	end,
}
rushB_kanxue = sgs.CreateTriggerSkillV2{
	name = "rushB_kanxue",
	--global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.CardUsed, sgs.PreCardUsed, sgs.EventPhaseChanging},
	view_as_skill = rushB_kanxuevs,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Damaged then
			local names, owners = {}, {}
			for _, splayer in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				table.insert(names, skill:objectName())
				table.insert(owners, splayer:objectName())
			end
			if #names > 0 then
				return table.concat(names, "|"), table.concat(owners, "|")
			end
		elseif event == sgs.CardUsed then
			if player and player:hasSkill(skill:objectName()) then
				local use = data:toCardUse()
				if use.card and table.contains(use.card:getSkillNames(), "rushB_kanxue_tenyearwusheng") and use.card:getSuit() == sgs.Card_Heart then
					return skill:objectName()
				end
			end
		elseif event == sgs.PreCardUsed then
			if player and player:hasSkill(skill:objectName()) then
				local use = data:toCardUse()
				if use.card and use.card:getSkillName() == "rushB_kanxue_tenyearwusheng" then
					return skill:objectName()
				end
			end
		elseif event == sgs.EventPhaseChanging then
			if player and player:hasSkill(skill:objectName()) then
				local change = data:toPhaseChange()
				if change.to == sgs.Player_NotActive or change.to == sgs.Player_RoundStart then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(), "rushB_kanxue_tenyearwusheng") and use.card:getSuit() == sgs.Card_Heart then
			    room:addPlayerMark(use.from, "rushB_kanxue-Clear")
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local name = use.from:getGeneralName()
				if use.card:getSkillName() == "rushB_kanxue_tenyearwusheng" then
					room:broadcastSkillInvoke("rushB_kanxue", 3)
					return true
				end
			end
		elseif event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:hasSkill(skill:objectName()) and player:getHujia() >= 1 and room:askForSkillInvoke(player, skill:objectName()) then
				room:broadcastSkillInvoke(skill:objectName(), 2)
				local n = player:getHujia()
				player:loseHujia(n)
				room:recover(player, sgs.RecoverStruct(player, nil, n))
				player:drawCards(n)
			elseif change.to == sgs.Player_RoundStart and player:hasSkill(skill:objectName()) and room:askForSkillInvoke(player, skill:objectName()) then
				room:broadcastSkillInvoke(skill:objectName(), 1)
			    room:loseHp(player, 1, true, player, skill:objectName())
				player:gainHujia(2)
				if not player:isNude() then
				    if room:askForDiscard(player, skill:objectName(), 1, 1, true, true) then
				        player:gainHujia(1)
					end
				end
			end
		elseif event == sgs.Damaged then
	        local damage = data:toDamage()
			local splayer = player
			local num = 1
			local m, x, n = 2, 1, 1
			if splayer:getHujia() > splayer:getHp() then m = m * 2 end
			if splayer:getHujia() < splayer:getHp() then x = x - 1 n = n + 1 end
			if splayer:getHujia() == splayer:getHp() then n = n - 1 x = x + 1 end
			if splayer:getHujia() > splayer:getHp() then num = num + 1 end
	        if splayer:distanceTo(damage.to) <= num then
				    if (x > 0 and damage.to:isAlive()) or (n > 0 and splayer:isAlive()) then
				        if room:askForSkillInvoke(splayer, "rushB_kanxue_yuqi", data) then
		        	        local log = sgs.LogMessage()
			                log.type = "#rushB_kanxue"
			                log.from = splayer
					        log.arg = "rushB_kanxue_yuqi"
			                room:sendLog(log)
					        room:broadcastSkillInvoke(skill:objectName(), 4)
		                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					        local card_ids, dummy_ids1, dummy_ids2 = room:getNCards(m), sgs.IntList(), sgs.IntList()
							if x > 0 then
								while x > 0 and damage.to:isAlive() and not card_ids:isEmpty() do
									room:fillAG(card_ids, splayer)
									local id1 = room:askForAG(splayer, card_ids, true, skill:objectName())
									if (id1 == -1) then room:clearAG(splayer) break end
									card_ids:removeOne(id1)
									dummy_ids1:append(id1)
									room:clearAG(splayer)
									x = x - 1
								end
							else
								room:fillAG(card_ids, splayer)
								room:getThread():delay(100)
								room:clearAG(splayer)
							end
							if not dummy_ids1:isEmpty() then
								dummy:addSubcards(dummy_ids1)
								room:obtainCard(damage.to, dummy, false)
								dummy:clearSubcards()
							end
					        if n > 0 then
								while n > 0 and splayer:isAlive() and not card_ids:isEmpty() do
									room:fillAG(card_ids, splayer)
									local id2 = room:askForAG(splayer, card_ids, true, skill:objectName())
									if (id2 == -1) then room:clearAG(splayer) break end
									card_ids:removeOne(id2)
									dummy_ids2:append(id2)
									room:clearAG(splayer)
									n = n - 1
								end
							else
								room:fillAG(card_ids, splayer)
								room:getThread():delay(100)
								room:clearAG(splayer)
							end
					        if not dummy_ids2:isEmpty() then
								dummy:addSubcards(dummy_ids2)
								room:obtainCard(splayer, dummy, false)
								dummy:deleteLater()
							end
			                for _,id in sgs.qlist(card_ids:getSubcards()) do
					            room:moveCardTo(sgs.Sanguosha:getCard(id), nil, sgs.Player_DrawPile)
					        end
						end
			        end
				end
		end
		return false
	end,
}
rushB_zhebang:addSkill(rushB_kanxue)
rushB_zhebang:addSkill(rushB_kanxue_extra)
extension:insertRelatedSkills("rushB_kanxue", "#rushB_kanxue_extra")
sgs.LoadTranslationTable{
	["rushB_zhebang"] = "MK折棒",
	--["&rushB_zhebang"] = "折棒",
	["#rushB_zhebang"] = "古月·无极",
	["designer:rushB_George"] = "俺的西木野Maki",
	["cv:rushB_George"] = "吃蛋挞的折棒",
	["illustrator:rushB_George"] = "吃蛋挞的折棒",
	["rushB_kanxue"] = "看学",
	["rushb_kanxue"] = "看学",
	["#rushB_kanxue"] = "%from 发动了“%arg”",
	["rushB_kanxue_tenyearwusheng"] = "武圣",
	["rushb_kanxue_tenyearwusheng"] = "武圣",
	["rushB_kanxue_yuqi"] = "隅泣",
	["rushb_kanxue_yuqi"] = "隅泣",
    [":rushB_kanxue"] = "锁定技，你视为拥有技能“武圣”和“隅泣”。回合开始时，你可以失去1点体力并获得2点护甲，然后可以弃置一张牌并获得1点护甲。回合结束时，若你拥有的护甲值不小于1，则你可以弃置所有护甲并恢复等量点体力、摸等量张牌。\
	<b>[武圣]</b>：你可以将一张红色牌当【杀】使用或打出；你使用的方块【杀】无距离限制、使用的红桃【杀】无次数限制。\
	<b>[隅泣]</b>：当一名角色受到伤害后，若你与其距离不大于[1]，你可以观看牌堆顶的[2]张牌，将其中至多[1]张牌交给该角色，然后获得其余牌中至多[1]张牌，将剩余的牌置于牌堆顶。若你的护甲值：大于体力值，第一个[]中的数字+1、第二个[]中的数字翻倍；等于体力值，第三个[]中的数字+1、第四个[]中的数字-1；小于体力值，第三个[]中的数字-1、第四个[]中的数字+1。",
	["$rushB_kanxue1"] = "看折棒，学折棒，学好技术才能浪。哈喽！大家好，我是折棒。",
	["$rushB_kanxue2"] = "众所周知，三国杀是一款非常平衡的游戏。",
	["$rushB_kanxue3"] = "威震华夏的武圣关云长，拥有将红牌当杀的神技。",
	["$rushB_kanxue4"] = "而历史角落的无名小卒，却只能一轮八十牌。",
	["~rushB_zhebang"] = "好的，那么本期视频就到这里，如果大家喜欢这期视频的话，请务必给个点赞、收藏、投币一键三连，支持下up主以及关注我。我是折棒，让我们下期视频再见。",
}
---------------------------------
-- D I T --
---------------------------------
DIT_luxun = sgs.General(extension, "DIT_luxun", "wu", 3, true, false, false, 2)
DIT_qianxunCard = sgs.CreateSkillCard{
	name = "DIT_qianxun",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		if source:getPile("qianxun"):isEmpty() then
		    for _,card in sgs.qlist(source:getHandcards()) do
			    source:addToPile("qianxun", card)
		    end
		else
			if not source:isKongcheng() then
		        for _,card in sgs.qlist(source:getHandcards()) do
				    room:throwCard(card, source, nil)
		        end
			end
		end
	end,
}
DIT_qianxunvs = sgs.CreateViewAsSkillV2{
    name = "DIT_qianxun",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		return (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
			and string.find(request:getPattern(), "@@DIT_qianxun") ~= nil
	end,
	create_card = function(skill, request)
		return DIT_qianxunCard:clone()
	end,
}
DIT_qianxun = sgs.CreateTriggerSkillV2{
	name = "DIT_qianxun",
	--global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed, sgs.EventPhaseChanging, sgs.PreCardUsed},
	view_as_skill = DIT_qianxunvs,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.TargetConfirmed then
			if player and player:hasSkill(skill:objectName()) then
				local use = data:toCardUse()
				if use.to:contains(player) and use.from:objectName() ~= player:objectName()
				and (use.card:isKindOf("Snatch") or use.card:isKindOf("Indulgence")) then
					return skill:objectName()
				end
			end
		elseif event == sgs.PreCardUsed then
			if player and player:hasSkill(skill:objectName()) then
				local use = data:toCardUse()
				if use.card and use.card:getSkillName() == "DIT_qianxun" then
					return skill:objectName()
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, splayer in sgs.qlist(room:getAllPlayers()) do
					if not splayer:getPile("qianxun"):isEmpty() then
						local holder = room:findPlayerBySkillName(skill:objectName())
						if holder then return skill:objectName(), holder end
						break
					end
				end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local target = ctx.invoker
			if use.to:contains(target) and use.from:objectName() ~= target:objectName() then
				if use.card:isKindOf("Snatch") or use.card:isKindOf("Indulgence") then
					if room:askForChoice(target, "@DIT_qianxun", "yes+no") == "yes" then
						player:setFlags("-qianxunTarget")
						player:setFlags("qianxunTarget")
						if player:isAlive() and player:hasFlag("qianxunTarget") then
							player:setFlags("-qianxunTarget")
							room:askForUseCard(player, "@@DIT_qianxun!", "@DIT_qianxun")
						end
					end
				end
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local skill_name = use.card:getSkillName()
				if skill_name == "DIT_qianxun" then
				    room:broadcastSkillInvoke(skill:objectName())
				end
			end
		else
		    local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
			    for _, p in sgs.qlist(room:getAllPlayers()) do
				    if not p:getPile("qianxun"):isEmpty() then
					    local dummy = sgs.Sanguosha:cloneCard("slash")
					    dummy:addSubcards(p:getPile("qianxun"))
					    room:obtainCard(p, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, p:objectName(), skill:objectName(), ""), false)
				    end
			    end
		    end
		end
		return false
	end,
}
DIT_lianying = sgs.CreateTriggerSkillV2{
	name = "DIT_lianying",
	--global = true,
	events = {sgs.CardFinished},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.card then
			local skill_name = use.card:getSkillName()
			if skill_name == "DIT_duoshi" or skill_name == "DIT_qianxun" then
				local holder = room:findPlayerBySkillName(skill:objectName())
				if holder then return skill:objectName(), holder end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card then
				local skill_name = use.card:getSkillName()
				if skill_name == "DIT_duoshi" then
				    room:sendCompulsoryTriggerLog(use.from, skill:objectName())
				    room:broadcastSkillInvoke(skill:objectName())
					use.from:drawCards(math.min(2, use.from:getMark("DIT_duoshi-Clear") + 1))
					room:setPlayerMark(use.from, "DIT_duoshi-Clear", use.from:getMark("DIT_duoshi-Clear") + 1)
				end
				if skill_name == "DIT_qianxun" then
				    room:sendCompulsoryTriggerLog(use.from, skill:objectName())
				    room:broadcastSkillInvoke(skill:objectName())
					use.from:drawCards(math.min(2, use.from:getMark("DIT_qianxun-Clear") + 1))
					room:setPlayerMark(use.from, "DIT_qianxun-Clear", use.from:getMark("DIT_qianxun-Clear") + 1)
				end
			end
		end
		return false
	end,
}
DIT_duoshivs = sgs.CreateViewAsSkillV2{
	name = "DIT_duoshi",
	n = 999,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return not player:isNude()
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern()
			return (pattern == "slash" or pattern == "jink") and not player:isNude()
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		return candidate ~= nil
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() >= 2
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() < 2 then return nil end
		local new_card = nil
		if request:getPattern() == "jink" then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		else
			new_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			new_card:setSkillName(skill:objectName())
			for _, id in sgs.qlist(ids) do
				new_card:addSubcard(id)
			end
		end
		return new_card
	end,
}
DIT_duoshi = sgs.CreateTriggerSkillV2{
	name = "DIT_duoshi",
	events = {sgs.PreCardUsed},
	view_as_skill = DIT_duoshivs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == "DIT_duoshi"
				and (use.card:isKindOf("Jink") or use.card:isKindOf("Slash")) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local name = use.from:getGeneralName()
				if use.card:getSkillName() == "DIT_duoshi" and (use.card:isKindOf("Jink") or use.card:isKindOf("Slash")) then
					room:broadcastSkillInvoke("DIT_duoshi")
					return true
				end
			end
		end
		return false
	end,
}
DIT_luxun:addSkill(DIT_qianxun)
DIT_luxun:addSkill(DIT_lianying)
DIT_luxun:addSkill(DIT_duoshi)
sgs.LoadTranslationTable{
	["DIT_luxun"] = "MK陆逊",
	["#DIT_luxun"] = "智慧之魂",
	["designer:DIT_luxun"] = "俺的西木野Maki",
	["illustrator:DIT_luxun"] = "DH",
	["DIT_qianxun"] = "谦逊",
	["dit_qianxun"] = "谦逊",
	["@DIT_qianxun"] = "你可以发动“谦逊”将所有手牌置于武将牌上",
    [":DIT_qianxun"] = "锁定技，当你成为其他角色使用的【顺手牵羊】或【乐不思蜀】的目标后，你可以将所有手牌置于武将牌上（若武将牌上有以此法放置的牌且你有手牌则改为弃置所有手牌，没有手牌则仅触发“连营”摸牌），然后回合结束后你获得这些牌。",
	["$DIT_qianxun1"] = "君子，生当如鹿。",
	["$DIT_qianxun2"] = "鹿栖于林，与世无争。",
	["DIT_lianying"] = "连营",
	[":DIT_lianying"] = "锁定技，当你使用“度势”或因“谦逊”将牌置于武将牌上后，你摸X/Y+1张牌。（X为你当前回合发动“度势”的次数且至多为2，Y为你当前回合发动“谦逊”的次数且至多为2）",
	["$DIT_lianying1"] = "抽刀断水，水更流。",
	["$DIT_lianying2"] = "夫诸过处，水流不息。",
	["DIT_duoshi"] = "度势",
	["dit_duoshi"] = "度势",
	[":DIT_duoshi"] = "你可以将至少两张牌当一张【杀】/【闪】使用或打出。",
	["$DIT_duoshi1"] = "观其变而夺其势，然后可图。",
	["$DIT_duoshi2"] = "因势利导，不劳而定天下。",
	["~DIT_luxun"] = "想不到，竟葬身于权利的漩涡中......",
}
---------------------------------
DIT_if_mouwolong = sgs.General(extension, "DIT_if_mouwolong", "shu", 3)
DIT_if_moubazhen = sgs.CreateTriggerSkillV2{
	name = "DIT_if_moubazhen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirming},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			local use = data:toCardUse()
			if use.to:contains(player) and use.from:objectName() ~= player:objectName() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.to:contains(player) then
				if use.from:objectName() ~= player:objectName() then
			        local choice, list = room:askForChoice(player, skill:objectName(), "1+3+5+7+9"), room:askForChoice(use.from, skill:objectName(), "2+4+6+8")
					if choice == "9" then return false end
		            room:sendCompulsoryTriggerLog(player, skill:objectName())
		            room:broadcastSkillInvoke(skill:objectName())
			        if (choice == "1" and list == "2") or (choice == "3" and list == "4") or (choice == "5" and list == "6") or (choice == "7" and list == "8") then
					    local log = sgs.LogMessage()
					    log.type = "#DIT_if_moubazhensuccess"
					    log.from = player
				    	room:sendLog(log)
						if player:getMark(skill:objectName()) < 3 then
							room:addPlayerMark(player, skill:objectName())
						end
						if player:getMark(skill:objectName()) >= 3 then
							sgs.Sanguosha:changeBGMEffect("audio/skill/DIT_if_mouwolong.ogg") --切换为谋卧龙诸葛亮-江山如梦专属BGM
						end
					    local nullified_list = use.nullified_list
					    table.insert(nullified_list, player:objectName())
					    use.nullified_list = nullified_list
					    data:setValue(use)
			        else
			    	    local log = sgs.LogMessage()
				        log.type = "#DIT_if_moubazhenfail"
				        log.from = player
				        room:sendLog(log)
				        if use.card:isKindOf("SkillCard") then
				            if player:hasSkill(use.card:getSkillName()) then return false end
							room:acquireSkill(player, use.card:getSkillName())
				        else
				            room:obtainCard(player, use.card, false)
				        end
			        end
				end
			end
		end
		return false
	end,
}
DIT_if_mouhuojivs = sgs.CreateViewAsSkillV2{
    name = "DIT_if_mouhuoji",
    n = 1,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        return player and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
    end,
    can_select_card = function(skill, request, candidate)
        return candidate and candidate:isRed() and request:getSelectedCardIds():isEmpty()
    end,
    card_selection_feasible = function(skill, request)
        return request:getSelectedCardIds():length() == 1
    end,
    create_card = function(skill, request)
        local ids = request:getSelectedCardIds()
        if ids:length() ~= 1 then return nil end
        local card = sgs.Sanguosha:getCard(ids:first())
	    local fireattack = sgs.Sanguosha:cloneCard("FireAttack", card:getSuit(), card:getNumber())
	    fireattack:setSkillName(skill:objectName())
	    fireattack:addSubcard(card:getId())
	    return fireattack
	end,
}
DIT_if_mouhuoji = sgs.CreateTriggerSkillV2{
	name = "DIT_if_mouhuoji",
	events = {sgs.CardUsed},
	view_as_skill = DIT_if_mouhuojivs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			local use = data:toCardUse()
			if use.card and table.contains(use.card:getSkillNames(), "DIT_if_mouhuoji") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and table.contains(use.card:getSkillNames(), "DIT_if_mouhuoji") and room:askForChoice(player, skill:objectName(), "1+2") == "1" then
			    for _,p in sgs.qlist(use.to) do
				    if p:isKongcheng() then return false end
					local card_ids = sgs.IntList()
					for _,card in sgs.qlist(p:getHandcards()) do
					    card_ids:append(card:getEffectiveId())
					end
				    room:fillAG(card_ids, player)
					local id, card_id = room:askForAG(player, card_ids, false, skill:objectName()), nil
					room:clearAG(player)
					room:showCard(p, id)
					card_id = room:askForCard(player, ".|"..sgs.Sanguosha:getCard(id):getSuitString().."|.|hand", "@DIT_if_mouhuoji:"..sgs.Sanguosha:getCard(id):getSuitString()..":"..p:objectName(), data, sgs.Card_MethodNone, player, false, skill:objectName(), false, use.card)
					if card_id then
				        room:throwCard(card_id, player, nil)
						room:damage(sgs.DamageStruct("fire_attack", player, p, 1, sgs.DamageStruct_Fire))
					end
					use.to:removeOne(p)
					room:sortByActionOrder(use.to)
					data:setValue(use)
				end
			end
		end
		return false
	end,
}
DIT_if_moukanpovs = sgs.CreateViewAsSkillV2{
    name = "DIT_if_moukanpo",
    n = 1,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        if not player then return false end
        local reason = request:getReason()
        if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
        if not string.find(request:getPattern(), "nullification") then return false end
	    for _, card in sgs.qlist(player:getCards("he")) do
		    if card:isBlack() then return true end
		end
	    return false
	end,
    can_select_card = function(skill, request, candidate)
        return candidate and candidate:isBlack() and request:getSelectedCardIds():isEmpty()
    end,
    card_selection_feasible = function(skill, request)
        return request:getSelectedCardIds():length() == 1
    end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local first = sgs.Sanguosha:getCard(ids:first())
		local ncard = sgs.Sanguosha:cloneCard("nullification", first:getSuit(), first:getNumber())
		ncard:addSubcard(first)
		ncard:setSkillName(skill:objectName())
		return ncard
	end,
}
DIT_if_moukanpo = sgs.CreateTriggerSkillV2{
	name = "DIT_if_moukanpo",
	events = {sgs.CardUsed},
	view_as_skill = DIT_if_moukanpovs,
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			local use = data:toCardUse()
			if use.card and table.contains(use.card:getSkillNames(), "DIT_if_moukanpo") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and table.contains(use.card:getSkillNames(), "DIT_if_moukanpo") then
			    local choices = {}
				if not room:getDrawPile():isEmpty() then
				    table.insert(choices, "1")
				end
				if not room:getDiscardPile():isEmpty() then
				    table.insert(choices, "2")
				end
				table.insert(choices, "3")
				local choice = room:askForChoice(player, skill:objectName(), table.concat(choices, "+"))
				if choice == "1" then
					local card_ids = sgs.IntList()
					for _,id in sgs.qlist(room:getDrawPile()) do
					    card_ids:append(id)
					end
				    room:fillAG(card_ids, player)
					local id = room:askForAG(player, card_ids, false, skill:objectName())
					room:clearAG(player)
					room:obtainCard(player, id, false)
				else
					local card_ids = sgs.IntList()
					for _,id in sgs.qlist(room:getDiscardPile()) do
					    card_ids:append(id)
					end
				    room:fillAG(card_ids, player)
					local id = room:askForAG(player, card_ids, false, skill:objectName())
					room:clearAG(player)
					room:obtainCard(player, id, false)
				end
			end
		end
		return false
	end,
}
DIT_if_moucangzhuo_extra = sgs.CreateMaxCardsSkillV2{
	name = "#DIT_if_moucangzhuo_extra",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local target = ctx:getHolder()
		local n = 0
		if target and target:hasSkill("DIT_if_moucangzhuo") then
			for _, card in sgs.qlist(target:getHandcards()) do
				if card:isKindOf("TrickCard") then
				    n = n + 1
				end
			end
		end
		return n
	end,
}
DIT_if_moucangzhuo = sgs.CreateTriggerSkillV2{
	name = "DIT_if_moucangzhuo",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.EventPhaseProceeding},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_Discard then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			for _,card in sgs.qlist(player:getHandcards()) do
				if card:isKindOf("TrickCard") then
					room:setPlayerCardLimitation(player, "discard", card:toString(), false)
				end
			end
		elseif event == sgs.EventPhaseEnd then
			for _,card in sgs.qlist(player:getHandcards()) do
				if card:isKindOf("TrickCard") then
					room:removePlayerCardLimitation(player, "discard", card:toString().."$0")
				end
			end
		else
			local n = 0
			for _,card in sgs.qlist(player:getHandcards()) do
				if card:isKindOf("TrickCard") then
					n = n + 1
				end
			end
			if player:getHandcardNum() <= player:getMaxCards() - n then return false end
			room:sendCompulsoryTriggerLog(player, skill:objectName())
		    room:broadcastSkillInvoke(skill:objectName())
		end
		return false
	end,
}

DIT_if_mouwolong:addSkill(DIT_if_moubazhen)
DIT_if_mouwolong:addSkill(DIT_if_mouhuoji)
DIT_if_mouwolong:addSkill(DIT_if_moukanpo)
DIT_if_mouwolong:addSkill(DIT_if_moucangzhuo)
DIT_if_mouwolong:addSkill(DIT_if_moucangzhuo_extra)
extension:insertRelatedSkills("DIT_if_moucangzhuo", "#DIT_if_moucangzhuo_extra")
sgs.LoadTranslationTable{
	["DIT_if_mouwolong"] = "谋卧龙诸葛亮-江山如梦",
	["&DIT_if_mouwolong"] = "谋卧龙IF",
	["#DIT_if_mouwolong"] = "契若金兰",
	["designer:DIT_if_mouwolong"] = "俺的西木野Maki",
	["illustrator:DIT_if_mouwolong"] = "鬼画府",
	["DIT_if_moubazhen"] = "八阵",
	["DIT_if_moubazhen:1"] = "乾卦",
	["DIT_if_moubazhen:2"] = "坤卦",
	["DIT_if_moubazhen:3"] = "离卦",
	["DIT_if_moubazhen:4"] = "坎卦",
	["DIT_if_moubazhen:5"] = "震卦",
	["DIT_if_moubazhen:6"] = "巽卦",
	["DIT_if_moubazhen:7"] = "艮卦",
	["DIT_if_moubazhen:8"] = "兑卦",
	["DIT_if_moubazhen:9"] = "取消",
	["#DIT_if_moubazhensuccess"] = "%from 对卦成功",
	["#DIT_if_moubazhenfail"] = "%from 对卦失败",
	[":DIT_if_moubazhen"] = "锁定技，当其他角色对你使用一张牌时，你与其进行卦象“博弈”。若“对卦”：成功（即为对宫卦），则此牌对你无效" ..
	"【<b>江山如梦：</b>且若你累计“对卦”成功三次，你切换游戏背景音乐为[谋卧龙诸葛亮-江山如梦]的专属BGM】；" ..
	"失败，此牌为实体牌，你获得之，否则你获得对应的技能。",
	["$DIT_if_moubazhen1"] = "君可为一郡之长，守疆土、明法典、泽百姓。",
	["$DIT_if_moubazhen2"] = "周易卜数，八卦定方，皆示与君义结金兰。",
	["DIT_if_mouhuoji"] = "火计",
	["dit_if_mouhuoji"] = "火计",
	["@DIT_if_mouhuoji-heart"] = "请弃置一张红桃手牌",
	["@DIT_if_mouhuoji-diamond"] = "请弃置一张方块手牌",
	["@DIT_if_mouhuoji-spade"] = "请弃置一张黑桃手牌",
	["@DIT_if_mouhuoji-club"] = "请弃置一张梅花手牌",
	["DIT_if_mouhuoji:1"] = "观看手牌",
	["DIT_if_mouhuoji:2"] = "取消",
	[":DIT_if_mouhuoji"] = "出牌阶段，你可以将一张红色牌当【火攻】使用。当你以此法使用【火攻】时，你可以观看目标手牌，若如此做，则你选择其中一张牌作为其【火攻】的展示牌。",
	["$DIT_if_mouhuoji1"] = "金兰为友，同众星举火，其势可燎原。",
	["$DIT_if_mouhuoji2"] = "月照星火，邀嘉宾话夜雨，而共剪西窗之烛。",
	["DIT_if_moukanpo"] = "看破",
	["dit_if_moukanpo"] = "看破",
	["DIT_if_moukanpo:1"] = "观看牌堆",
	["DIT_if_moukanpo:2"] = "观看弃牌堆",
	["DIT_if_moukanpo:3"] = "取消",
	[":DIT_if_moukanpo"] = "你可以将一张黑色牌当【无懈可击】使用。当你以此法使用【无懈可击】时，你可以选择一项：1.观看牌堆；2.观看弃牌堆。若如此做，则你获得其中一张牌。",
	["$DIT_if_moukanpo1"] = "浊世浑浑，能得一知己者，人生之幸尔。",
	["$DIT_if_moukanpo2"] = "污流逐世，人皆随波，独君与我溯而逆之。",
	["DIT_if_moucangzhuo"] = "藏拙",
	[":DIT_if_moucangzhuo"] = "锁定技，你手牌中的锦囊牌不计入手牌上限，且你手牌中的锦囊牌无法于弃牌阶段被弃置。",
	["$DIT_if_moucangzhuo1"] = "君子不显其智于众，不受愚夫之扰。",
	["$DIT_if_moucangzhuo2"] = "大智者若愚，藏锐器于胸腹，彰大义于广厦。",
	["~DIT_if_mouwolong"] = "世上知我者，唯徐元直尔......",
}
---------------------------------
DIT_heg_zuoci = sgs.General(extension, "DIT_heg_zuoci", "qun", 3)
DIT_heg_jihun = sgs.CreateTriggerSkillV2{
	name = "DIT_heg_jihun",
	--global = true,
	priority = 100,
	events = {sgs.GameStart, sgs.Damaged, sgs.Damage, sgs.QuitDying},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.QuitDying then
			local dying = data:toDying()
			if dying.who and not dying.who:isDead() then
				local holder = room:findPlayerBySkillName(skill:objectName())
				if holder then return skill:objectName(), holder end
			end
		elseif player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.GameStart then
			local list = {}
		    for _,p in sgs.qlist(room:getAllPlayers()) do
		        if table.contains(list, p:getKingdom()) then continue end
		        table.insert(list, p:getKingdom())
		    end
		    room:sendCompulsoryTriggerLog(player, skill:objectName())
		    room:broadcastSkillInvoke(skill:objectName())
			local n = 0
			while n < 3 do
			    local mark = room:askForChoice(player, skill:objectName(), table.concat(list, "+"))
			    player:gainMark("&"..skill:objectName().."_hun"..mark, 1)
				n = n + 1
			end
			player:gainMark("&"..skill:objectName().."_hun", n)
		elseif event == sgs.Damaged then
		    local damage = data:toDamage()
			local n = 0
			while n < damage.damage and player:hasSkill(skill:objectName()) and room:askForSkillInvoke(player, skill:objectName(), data) do
				local list = {}
				for _,p in sgs.qlist(room:getAllPlayers()) do
	        	    if table.contains(list, p:getKingdom()) then continue end
			        table.insert(list, p:getKingdom())
			    end
			    room:broadcastSkillInvoke(skill:objectName())
				local mark = room:askForChoice(player, skill:objectName(), table.concat(list, "+"))
				player:gainMark("&"..skill:objectName().."_hun", damage.damage)
				player:gainMark("&"..skill:objectName().."_hun"..mark, damage.damage)
				n = n + 1
			end
		elseif event == sgs.Damage then
		    local damage = data:toDamage()
			local n = 0
			for _,p in sgs.qlist(room:getOtherPlayers(damage.to)) do
			    if p:getKingdom() == damage.to:getKingdom() and damage.to:isDead() then n = n + 1 end
			end
			for _,p in sgs.qlist(room:getOtherPlayers(damage.to)) do
			    if p:getKingdom() == damage.to:getKingdom() and damage.to:isDead() and n == 0 then room:removePlayerMark(player, "&DIT_heg_jihun_hun", player:getMark("&DIT_heg_jihun_hun"..p:getKingdom())) room:setPlayerMark(player, "&DIT_heg_jihun_hun"..p:getKingdom(), 0)  end
			end
			local n = 0
			while n < damage.damage and player:hasSkill(skill:objectName()) and room:askForSkillInvoke(player, skill:objectName(), data) do
				local list = {}
				for _,p in sgs.qlist(room:getAllPlayers()) do
	        	    if table.contains(list, p:getKingdom()) then continue end
			        table.insert(list, p:getKingdom())
			    end
			    room:broadcastSkillInvoke(skill:objectName())
				local mark = room:askForChoice(player, skill:objectName(), table.concat(list, "+"))
				player:gainMark("&"..skill:objectName().."_hun", damage.damage)
				player:gainMark("&"..skill:objectName().."_hun"..mark, damage.damage)
				n = n + 1
			end
		else
		    local dying = data:toDying()
			local zuoci = player
			if dying.who:isDead() or not room:askForSkillInvoke(zuoci, skill:objectName(), data) then return false end
			local list = {}
			for _,p in sgs.qlist(room:getAllPlayers()) do
			    if table.contains(list, p:getKingdom()) then continue end
			    table.insert(list, p:getKingdom())
			end
			room:broadcastSkillInvoke(skill:objectName())
			local n = 0
			while n < dying.damage.damage do
				local mark = room:askForChoice(zuoci, skill:objectName(), table.concat(list, "+"))
				zuoci:gainMark("&"..skill:objectName().."_hun", dying.damage.damage)
				zuoci:gainMark("&"..skill:objectName().."_hun"..mark, dying.damage.damage)
				n = n + 1
			end
		end
		return false
	end,
}
DIT_heg_yiguiCard = sgs.CreateSkillCard{
	name = "DIT_heg_yigui",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		local card = player:getTag("DIT_heg_yigui"):toCard()
		card:setSkillName(self:objectName())
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, player) 
			and not player:isProhibited(to_select, card, qtargets) and player:getMark("&DIT_heg_jihun_hun"..to_select:getKingdom()) >= 1
	end,
	feasible = function(self, targets, player)
		local card = player:getTag("DIT_heg_yigui"):toCard()
		card:setSkillName(self:objectName())
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, player)
	end,	
	on_validate = function(self, card_use)
		local xunyou = card_use.from
		local room = xunyou:getRoom()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString())
		use_card:setSkillName(self:objectName())
		local available = true
		for _,p in sgs.qlist(card_use.to) do
			if xunyou:isProhibited(p,use_card) then
				available = false
				break
			end
		end
		available = available and use_card:isAvailable(xunyou)
		if not available then return nil end
		return use_card		
	end,
}
DIT_heg_yiguivs = sgs.CreateViewAsSkillV2{
	name = "DIT_heg_yigui",
	n = 0,
	guhuo_type = "lr",
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or player:getMark("&DIT_heg_jihun_hun") == 0 then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return true
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern()
			return pattern == "slash" or pattern == "jink" or pattern == "nullification"
				or (string.find(pattern, "peach") and not player:hasFlag("Global_PreventPeach"))
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local pattern = request:getPattern()
		if pattern == "slash" then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("DIT_heg_yigui")
			return slash
		elseif pattern == "jink" then
			local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
			jink:setSkillName("DIT_heg_yigui")
			return jink
		elseif pattern == "nullification" then
			local nullification = sgs.Sanguosha:cloneCard("nullification", sgs.Card_NoSuit, 0)
			nullification:setSkillName("DIT_heg_yigui")
			return nullification
		elseif string.find(pattern, "peach") then
			local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
			peach:setSkillName("DIT_heg_yigui")
			return peach
		else
		    local name = request:getUserString()
		    if name and name ~= "" then
			    local card = DIT_heg_yiguiCard:clone()
			    card:setUserString(name)
			    return card
		    end
		    return nil
		end
	end,
}
DIT_heg_yigui = sgs.CreateTriggerSkillV2{
	name = "DIT_heg_yigui",
	events = {sgs.PreCardUsed, sgs.CardUsed, sgs.PreCardResponded},
	view_as_skill = DIT_heg_yiguivs,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.PreCardUsed or event == sgs.CardUsed then
			local use = data:toCardUse()
			return use.card and table.contains(use.card:getSkillNames(), "DIT_heg_yigui")
				and skill:objectName() or false
		elseif event == sgs.PreCardResponded then
			local resp = data:toCardResponse()
			if resp.m_card and table.contains(resp.m_card:getSkillNames(), "DIT_heg_yigui") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local skill_name = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n
				if skill_name == "DIT_heg_yigui" and use.to:length() > 1 then
			        local players, list = sgs.SPlayerList(), {}
					for _,p in sgs.qlist(room:getAllPlayers()) do
					    if player:getMark("&DIT_heg_jihun_hun"..p:getKingdom()) > 0 then
						    players:append(p)
						end
					    if use.to:contains(p) and not table.contains(list, p:getKingdom()) then
						    table.insert(list, p:getKingdom())
						end
					end
					if #list < 2 then return false end
				    local target = room:askForPlayerChosen(player, players, skill:objectName(), "@choose-players", false, false)
					for _,p in sgs.qlist(room:getAllPlayers()) do
						--[[if ((((target:getKingdom() == "wei" and p:getKingdom() ~= "wei") or (target:getKingdom() == "wu" and p:getKingdom() ~= "wu") or (target:getKingdom() == "shu" and p:getKingdom() ~= "shu") 
						or (target:getKingdom() == "qun" and p:getKingdom() ~= "qun") or (target:getKingdom() == "jin" and p:getKingdom() ~= "jin") or (target:getKingdom() == "god" and p:getKingdom() ~= "god") 
						or (target:getKingdom() == "han" and p:getKingdom() ~= "han") or (target:getKingdom() == "ye" and p:getKingdom() ~= "ye") or (target:getKingdom() == "yao" and p:getKingdom() ~= "yao") 
						or (target:getKingdom() == "kesheng" and p:getKingdom() ~= "kesheng") or (target:getKingdom() == "kexian" and p:getKingdom() ~= "kexian") or (target:getKingdom() == "keyao" and p:getKingdom() ~= "keyao") 
						or (target:getKingdom() == "kegui" and p:getKingdom() ~= "kegui") or (target:getKingdom() == "sdfc" and p:getKingdom() ~= "sdfc") or (target:getKingdom() == "pal" and p:getKingdom() ~= "pal") 
						or (target:getKingdom() == "devil" and p:getKingdom() ~= "devil") or (target:getKingdom() == "maki_god" and p:getKingdom() ~= "maki_god") or (target:getKingdom() == "sy_god" and p:getKingdom() ~= "sy_god"))
						and player:getMark("&DIT_heg_jihun_hun"..p:getKingdom()) > 0) or player:getMark("&DIT_heg_jihun_hun"..p:getKingdom()) == 0) and use.to:contains(p) then]]
						if ((target:getKingdom() ~= p:getKingdom() and player:getMark("&DIT_heg_jihun_hun"..p:getKingdom()) > 0) or player:getMark("&DIT_heg_jihun_hun"..p:getKingdom()) == 0) and use.to:contains(p) then
						    use.to:removeOne(p)
						    room:sortByActionOrder(use.to)
						    data:setValue(use)
						end
					end
				end
				if skill_name == "DIT_heg_yigui" then
			        for _,p in sgs.qlist(use.to) do
						if p:objectName() == player:objectName() and player:getMark("&DIT_heg_jihun_hun"..player:getKingdom()) == 0 then return false end
					end
				end
			end
		elseif event == sgs.PreCardResponded then
			local resp = data:toCardResponse()
			if resp.m_card and table.contains(resp.m_card:getSkillNames(), "DIT_heg_yigui") and (resp.m_card:isKindOf("Slash") or resp.m_card:isKindOf("Jink") or resp.m_card:isKindOf("Nullification")) then
			    local choices = {}
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if player:getMark("&DIT_heg_jihun_hun"..p:getKingdom()) > 0 and not table.contains(choices, p:getKingdom()) then
						table.insert(choices, p:getKingdom())
					end
				end
				if #choices == 0 then return false end
				local choice = room:askForChoice(player, skill:objectName(), table.concat(choices, "+"))
				player:loseMark("&DIT_heg_jihun_hun", 1)
				player:loseMark("&DIT_heg_jihun_hun"..choice, 1)
			end
		else
			local use = data:toCardUse()
			if use.card then
				local skill_name = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n
				if skill_name == "DIT_heg_yigui" then
			        for _,p in sgs.qlist(use.to) do
						player:loseMark("&DIT_heg_jihun_hun", 1)
						player:loseMark("&DIT_heg_jihun_hun"..p:getKingdom(), 1)
						break
					end
				end
			end
			if use.card and table.contains(use.card:getSkillNames(), "DIT_heg_yigui") and (use.card:isKindOf("Jink") or use.card:isKindOf("Nullification")) and use.to == nil then
			    local choices = {}
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if player:getMark("&DIT_heg_jihun_hun"..p:getKingdom()) > 0 and not table.contains(choices, p:getKingdom()) then
						table.insert(choices, p:getKingdom())
					end
				end
				if #choices == 0 then return false end
				local choice = room:askForChoice(player, skill:objectName(), table.concat(choices, "+"))
				player:loseMark("&DIT_heg_jihun_hun", 1)
				player:loseMark("&DIT_heg_jihun_hun"..choice, 1)
			end
		end
		return false
	end,
}
DIT_heg_yigui_extra = sgs.CreateTargetModSkillV2{
    name = "DIT_heg_yigui_extra",
	pattern = "^SkillCard",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local n = 0
		if ctx:getModType() == sgs.TargetModSkill_DistanceLimit then
			local from = ctx:getPrimary()
			local to = ctx:getSecondary()
			local card = ctx:getCard()
			if from and from:hasSkill("DIT_heg_yigui") and to and from:getMark("&DIT_heg_jihun_hun"..to:getKingdom()) > 0 and card and table.contains(card:getSkillNames(), "DIT_heg_yigui") then
				n = 1000
			end
		end
		return n
	end,
}
DIT_heg_yigui_ex = sgs.CreateProhibitSkill{
	name = "DIT_heg_yigui_ex",
	is_prohibited = function(self, from, to, card)
		return from:hasSkill("DIT_heg_yigui") and to and from:getMark("&DIT_heg_jihun_hun"..to:getKingdom()) == 0 and card and table.contains(card:getSkillNames(), "DIT_heg_yigui")
	end,
}
if not sgs.Sanguosha:getSkill("DIT_heg_yigui_extra") then skills:append(DIT_heg_yigui_extra) end
if not sgs.Sanguosha:getSkill("DIT_heg_yigui_ex") then skills:append(DIT_heg_yigui_ex) end
DIT_heg_yigui:setGuhuoDialog("lr")
DIT_heg_zuoci:addSkill(DIT_heg_jihun)
DIT_heg_zuoci:addSkill(DIT_heg_yigui)
sgs.LoadTranslationTable{
	["DIT_heg_zuoci"] = "MK左慈",
	["#DIT_heg_zuoci"] = "鬼影神道",
	["designer:DIT_heg_zuoci"] = "俺的西木野Maki",
	["illustrator:DIT_heg_zuoci"] = "吕阳",
	["DIT_heg_jihun"] = "汲魂",
	["DIT_heg_jihun_hun"] = "魂",
	["DIT_heg_jihun_hunye"] = "魂：野心家",
	["DIT_heg_jihun_hunyao"] = "魂：妖",
	["DIT_heg_jihun_hunwei"] = "魂：魏",
	["DIT_heg_jihun_hunshu"] = "魂：蜀",
	["DIT_heg_jihun_hunwu"] = "魂：吴",
	["DIT_heg_jihun_hunqun"] = "魂：群",
	["DIT_heg_jihun_hunjin"] = "魂：晋",
	["DIT_heg_jihun_hungod"] = "魂：神",
	["DIT_heg_jihun_hundevil"] = "魂：魔",
	["DIT_heg_jihun_hunkegui"] = "魂：鬼",
	["DIT_heg_jihun_hunkeyao"] = "魂：妖",
	["DIT_heg_jihun_hunkesheng"] = "魂：圣",
	["DIT_heg_jihun_hunkexian"] = "魂：仙",
	["DIT_heg_jihun_hunsdfc"] = "魂：沙雕",
	["DIT_heg_jihun_hunpal"] = "魂：古生物",
	["DIT_heg_jihun_hunsy_god"] = "魂：神·极",
	["DIT_heg_jihun_hunhan"] = "魂：汉",
	[":DIT_heg_jihun"] = "游戏开始时，你获得三个现存势力的“魂”标记。当你受到伤害后，你可以获得X个“魂”标记。当一名角色的濒死结算结束后，若其存活，你可以获得X个“魂”标记。（X为伤害值）",
	["$DIT_heg_jihun1"] = "魂聚则生，魂散则弃。",
	["$DIT_heg_jihun2"] = "魂羽化游，以抚四方。",
	["DIT_heg_yigui"] = "役鬼",
	["dit_heg_yigui"] = "役鬼",
	[":DIT_heg_yigui"] = "在合适的时机下，你可以弃置一个你拥有势力的“魂”标记，视为对此势力的角色使用一张牌。若如此做，你以此法使用的牌无次数和距离限制。",
	["$DIT_heg_yigui1"] = "百鬼众魅，自缚见形。",
	["$DIT_heg_yigui2"] = "来去无踪，众谓鬼役。",
    ["~DIT_heg_zuoci"] = "仙人转世，一去无返......", --呃...腾云跨风，飞升太虚......
}


--威赵云
mk_WEIzhaoyun = sgs.General(extension, "mk_WEIzhaoyun", "shu", 4, true)

mk_danlve = sgs.CreateTriggerSkillV2{
	name = "mk_danlve",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.TargetSpecified, sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			if card and card:isRed() and card:getSkillName() ~= "mk_danlve_yinyue" and room:askForSkillInvoke(player, "mk_danlveYY", data) then
				room:broadcastSkillInvoke(skill:objectName(), 1)
				player:addToPile("mk_danlve_yinyue", card:getEffectiveId())
				local current = room:getCurrent()
				if player:getPhase() == sgs.Player_NotActive and player:canSlash(current) then
					room:askForUseSlashTo(player, current, "mk_danlve-yinyueSlash:" .. current:objectName())
				end
			end
		else
			local use = data:toCardUse()
			if event == sgs.TargetSpecified then
				if use.card and use.card:isBlack() and use.card:getSkillName() ~= "mk_danlve_qinggang" and room:askForSkillInvoke(player, "mk_danlveQG", data) then
					room:broadcastSkillInvoke(skill:objectName(), 2)
					player:addToPile("mk_danlve_qinggang", use.card:getEffectiveId())
					if use.card:isKindOf("Slash") then
						room:setPlayerFlag(player, "mk_danlve_qinggangSource")
						for _, p in sgs.qlist(use.to) do
							room:setPlayerFlag(p, "mk_danlve_qinggangTarget")
							room:addPlayerMark(p, "Armor_Nullified")
						end
					end
				end
			elseif event == sgs.CardFinished then
				if use.card and use.card:isKindOf("Slash") and use.from and use.from:objectName() == player:objectName() and player:hasFlag("mk_danlve_qinggangSource") then
					room:setPlayerFlag(player, "-mk_danlve_qinggangSource")
					for _, p in sgs.qlist(use.to) do
						if not p:hasFlag("mk_danlve_qinggangTarget") or p:getMark("Armor_Nullified") == 0 then continue end
						room:setPlayerFlag(p, "-mk_danlve_qinggangTarget")
						room:removePlayerMark(p, "Armor_Nullified")
					end
				end
			end
		end
		return false
	end,
}
mk_danlves = sgs.CreateTriggerSkillV2{
	name = "#mk_danlves",
	frequency = sgs.Skill_Frequent,
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill},
	can_trigger = function(skill, event, room, player, data)
		if not player then return false end
		if event == sgs.GameStart then
			if player:hasSkill("mk_danlve") then
				if player:hasSkill(skill:objectName()) then return skill:objectName() end
				local owner = room:findPlayerBySkillName(skill:objectName())
				if owner then return skill:objectName(), owner end
			end
		elseif event == sgs.EventAcquireSkill then
			if data:toSkillChange().skillName == "mk_danlve" then
				if player:hasSkill(skill:objectName()) then return skill:objectName() end
				local owner = room:findPlayerBySkillName(skill:objectName())
				if owner then return skill:objectName(), owner end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toSkillChange().skillName == "mk_danlve"
				or data:toString() == "mk_danlve_yinyue" or data:toString() == "mk_danlve_qinggang" then
				if player:hasSkill(skill:objectName()) then return skill:objectName() end
				local owner = room:findPlayerBySkillName(skill:objectName())
				if owner then return skill:objectName(), owner end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local target = ctx.invoker or player
		if event == sgs.GameStart then
			if target:hasSkill("mk_danlve") then
				if not target:hasSkill("mk_danlve_yinyue") then room:attachSkillToPlayer(target, "mk_danlve_yinyue") end
				if not target:hasSkill("mk_danlve_qinggang") then room:attachSkillToPlayer(target, "mk_danlve_qinggang") end
			end
		elseif event == sgs.EventAcquireSkill then
			if data:toSkillChange().skillName == "mk_danlve" then
				if not target:hasSkill("mk_danlve_yinyue") then room:attachSkillToPlayer(target, "mk_danlve_yinyue") end
				if not target:hasSkill("mk_danlve_qinggang") then room:attachSkillToPlayer(target, "mk_danlve_qinggang") end
			end
		elseif event == sgs.EventLoseSkill then
			if data:toSkillChange().skillName == "mk_danlve" then
				if target:hasSkill("mk_danlve_yinyue") then room:detachSkillFromPlayer(target, "mk_danlve_yinyue", true) end
				if target:hasSkill("mk_danlve_qinggang") then room:detachSkillFromPlayer(target, "mk_danlve_qinggang", true) end
			--防老六：
			elseif data:toString() == "mk_danlve_yinyue" then room:attachSkillToPlayer(target, "mk_danlve_yinyue")
			elseif data:toString() == "mk_danlve_qinggang" then room:attachSkillToPlayer(target, "mk_danlve_qinggang")
			----
			end
		end
		return false
	end,
}
  --“银月”卡
mk_danlve_yinyue = sgs.CreateViewAsSkillV2{
	name = "mk_danlve_yinyue&",
	n = 1,
	expand_pile = "mk_danlve_yinyue",
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return not player:getPile("mk_danlve_yinyue"):isEmpty()
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern()
			if not (pattern == "slash" or pattern == "jink" or (string.find(pattern, "peach") and not player:hasFlag("Global_PreventPeach"))
				or string.find(pattern, "analeptic") or pattern == "nullification")
				or player:getPile("mk_danlve_yinyue"):isEmpty() then
				return false
			end
			if pattern == "nullification" then
				for _, id in sgs.qlist(player:getPile("mk_danlve_yinyue")) do
					local nd = sgs.Sanguosha:getCard(id)
					if nd and nd:isKindOf("Nullification") then return true end
				end
				return false
			end
			return true
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate or not request:getSelectedCardIds():isEmpty() then return false end
		local pattern = request:getPattern()
		if pattern == "slash" then
			return candidate:isKindOf("Slash")
		elseif pattern == "jink" then
			return candidate:isKindOf("Jink")
		elseif string.find(pattern, "peach") then
			return candidate:isKindOf("Peach")
		elseif string.find(pattern, "analeptic") then
			return candidate:isKindOf("Analeptic")
		elseif pattern == "nullification" then
			return candidate:isKindOf("Nullification")
		else
			return not (candidate:isKindOf("Nullification") or candidate:isKindOf("Jink"))
		end
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:isEmpty() then return nil end
		local first = sgs.Sanguosha:getCard(ids:first())
		local yinyue
		if first:isKindOf("Horse") then
			yinyue = sgs.Sanguosha:cloneCard(first:getClassName(), sgs.Card_SuitToBeDecided, 0)
		else
			yinyue = sgs.Sanguosha:cloneCard(first:objectName(), sgs.Card_SuitToBeDecided, 0)
		end
		for i = 0, ids:length() - 1 do
			yinyue:addSubcard(ids:at(i))
		end
		yinyue:setSkillName("mk_danlve_yinyue")
		return yinyue
	end,
}
  --“青釭”卡
mk_danlve_qinggang = sgs.CreateViewAsSkillV2{
	name = "mk_danlve_qinggang&",
	n = 1,
	expand_pile = "mk_danlve_qinggang",
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return not player:getPile("mk_danlve_qinggang"):isEmpty()
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern()
			if not (pattern == "slash" or pattern == "jink" or (string.find(pattern, "peach") and not player:hasFlag("Global_PreventPeach"))
				or string.find(pattern, "analeptic") or pattern == "nullification")
				or player:getPile("mk_danlve_qinggang"):isEmpty() then
				return false
			end
			if pattern == "nullification" then
				for _, id in sgs.qlist(player:getPile("mk_danlve_qinggang")) do
					local nd = sgs.Sanguosha:getCard(id)
					if nd and nd:isKindOf("Nullification") then return true end
				end
				return false
			end
			return true
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate or not request:getSelectedCardIds():isEmpty() then return false end
		local pattern = request:getPattern()
		if pattern == "slash" then
			return candidate:isKindOf("Slash")
		elseif pattern == "jink" then
			return candidate:isKindOf("Jink")
		elseif string.find(pattern, "peach") then
			return candidate:isKindOf("Peach")
		elseif string.find(pattern, "analeptic") then
			return candidate:isKindOf("Analeptic")
		elseif pattern == "nullification" then
			return candidate:isKindOf("Nullification")
		else
			return not (candidate:isKindOf("Nullification") or candidate:isKindOf("Jink"))
		end
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:isEmpty() then return nil end
		local first = sgs.Sanguosha:getCard(ids:first())
		local qinggang
		if first:isKindOf("Horse") then
			qinggang = sgs.Sanguosha:cloneCard(first:getClassName(), sgs.Card_SuitToBeDecided, 0)
		else
			qinggang = sgs.Sanguosha:cloneCard(first:objectName(), sgs.Card_SuitToBeDecided, 0)
		end
		for i = 0, ids:length() - 1 do
			qinggang:addSubcard(ids:at(i))
		end
		qinggang:setSkillName("mk_danlve_qinggang")
		return qinggang
	end,
}
--
mk_danlveAR = sgs.CreateAttackRangeSkillV2{
	name = "#mk_danlveAR",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local player = ctx:getHolder()
		local n = 0
		if player and player:hasSkill("mk_danlve") then
			if player:getPile("mk_danlve_yinyue"):length() > 0 then n = n + 2 end
			if player:getPile("mk_danlve_qinggang"):length() > 0 then n = n + 1 end
		end
		return n
	end,
}
mk_WEIzhaoyun:addSkill(mk_danlve)
mk_WEIzhaoyun:addSkill(mk_danlves)
mk_WEIzhaoyun:addSkill(mk_danlveAR)
extension:insertRelatedSkills("mk_danlve", "#mk_danlves")
extension:insertRelatedSkills("mk_danlve", "#mk_danlveAR")
if not sgs.Sanguosha:getSkill("mk_danlve_yinyue") then skills:append(mk_danlve_yinyue) end
if not sgs.Sanguosha:getSkill("mk_danlve_qinggang") then skills:append(mk_danlve_qinggang) end

mk_kongying = sgs.CreateTriggerSkillV2{
	name = "mk_kongying",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.TargetSpecified, sgs.ConfirmDamage, sgs.CardFinished},
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				local resp = data:toCardResponse()
				if resp.m_isUse then
					card = resp.m_card
				end
			end
			if card and not card:isKindOf("SkillCard") and card:getHandlingMethod() == sgs.Card_MethodUse then
				if (player:getMark("&"..skill:objectName()) == 0 and card:getSkillName() ~= "mk_danlve_yinyue")
				or (player:getMark("&"..skill:objectName()) == 1 and card:getSkillName() ~= "mk_danlve_qinggang") then
					room:setPlayerMark(player, "&"..skill:objectName(), 0)
					return false
				end
				if player:getMark("&"..skill:objectName()) == 0 and table.contains(card:getSkillNames(), "mk_danlve_yinyue") then
					room:addPlayerMark(player, "&"..skill:objectName())
					return false
				end
				if player:getMark("&"..skill:objectName()) == 1 and table.contains(card:getSkillNames(), "mk_danlve_qinggang")
				and room:askForSkillInvoke(player, skill:objectName(), data) then
					room:broadcastSkillInvoke(skill:objectName())
					room:doLightbox("mk_kongyingAnimate") --触发连招：“子龙一身都是胆”
					room:setPlayerMark(player, "&"..skill:objectName(), 0)
					if not player:isKongcheng() then
						local yy_black, qg_red, otr_throw = sgs.IntList(), sgs.IntList(), sgs.IntList()
						for _, cd in sgs.qlist(player:getHandcards()) do
							if cd:isBlack() then yy_black:append(cd:getEffectiveId())
							elseif cd:isRed() then qg_red:append(cd:getEffectiveId())
							else otr_throw:append(cd:getEffectiveId())
							end
						end
						local dummy = sgs.Sanguosha:cloneCard("slash")
						if yy_black:length() > 0 then
							dummy:addSubcards(yy_black)
							player:addToPile("mk_danlve_yinyue", dummy)
							dummy:clearSubcards()
						end
						if qg_red:length() > 0 then
							dummy:addSubcards(qg_red)
							player:addToPile("mk_danlve_qinggang", dummy)
							dummy:clearSubcards()
						end
						if otr_throw:length() > 0 then
							dummy:addSubcards(otr_throw)
							room:throwCard(dummy, player, nil)
							dummy:clearSubcards()
						end
						dummy:deleteLater()
						room:setPlayerMark(player, "mk_kongyingQM", card:getEffectiveId())
					else
						room:drawCards(player, room:alivePlayerCount()-1, skill:objectName())
						room:setPlayerMark(player, "mk_kongyingJS", card:getEffectiveId())
					end
				end
			end
		else
			local use, damage = data:toCardUse(), data:toDamage()
			if event == sgs.TargetSpecified then
				if use.card and not use.card:isKindOf("SkillCard") and use.from and use.from:objectName() == player:objectName()
				and player:getMark("mk_kongyingQM") == use.card:getEffectiveId() then
					room:setPlayerMark(player, "mk_kongyingQM", 0)
					room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
					local no_respond_list = use.no_respond_list
					for _, p in sgs.qlist(use.to) do
						table.insert(no_respond_list, p:objectName())
					end
					use.no_respond_list = no_respond_list
					data:setValue(use)
				end
			elseif event == sgs.ConfirmDamage then
				if damage.card and not damage.card:isKindOf("SkillCard") and damage.from and damage.from:objectName() == player:objectName()
				and player:getMark("mk_kongyingJS") == damage.card:getEffectiveId() then
					room:setPlayerMark(player, "mk_kongyingJS", 0)
					room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true)
					damage.damage = damage.damage + 1
					data:setValue(damage)
				end
			elseif event == sgs.CardFinished then
				if use.card and not use.card:isKindOf("SkillCard") and use.from and use.from:objectName() == player:objectName() then
					if player:getMark("mk_kongyingQM") > 0 then room:setPlayerMark(player, "mk_kongyingQM", 0) end
					if player:getMark("mk_kongyingJS") > 0 then room:setPlayerMark(player, "mk_kongyingJS", 0) end
				end
			end
		end
		return false
	end,
}
mk_WEIzhaoyun:addSkill(mk_kongying)
--

sgs.LoadTranslationTable{
	["mk_WEIzhaoyun"] = "威赵云",
	["#mk_WEIzhaoyun"] = "赤胆龙心",
	["designer:mk_WEIzhaoyun"] = "FC,Maki",
	["cv:mk_WEIzhaoyun"] = "官方",
	["illustrator:mk_WEIzhaoyun"] = "君桓文化",
	["information:mk_WEIzhaoyun"] = "“背水空营显勇敢，子龙一身都是胆！”",
	["mk_danlve"] = "胆略", --改编自Maki佬设计的武器【青釭银月】
	[":mk_danlve"] = "[银月]当你使用或打出一张不为“银月”牌的红色牌后，你可以将此牌置于你的武将牌上，称为“银月”；然后若此时为你的回合外，你可以对当前回合角色使用一张【杀】；\
	[青釭]当你使用一张不为“青釭”牌的黑色牌指定目标后，你可以将此牌置于你的武将牌上，称为“青釭”；然后若此牌为【杀】，你无视目标防具至此牌结算完成时。\
	你可以将“银月”牌和“青釭”牌如手牌般使用或打出；若你有“[银月/青釭]”牌，你的攻击范围[+2/+1]。",
	["mk_danlve_yinyue"] = "银月",
	["mk_danlveYY"] = "[胆略]银月",
	["mk_danlve-yinyueSlash"] = "[胆略-银月]你可以对 %src 使用一张【杀】",
	["mk_danlve_qinggang"] = "青釭",
	["mk_danlveQG"] = "[胆略]青釭",
	["$mk_danlve1"] = "豪胆干云立乾坤，枪出寒潭斩蛟龙！", --银月
	["$mk_danlve2"] = "剑起星奔诛万里，摧却终南第一峰！", --青釭
	["mk_kongying"] = "空营",
	[":mk_kongying"] = "连招技（“银月”牌+“青釭”牌），若你有手牌，你可以将所有[黑/红]色手牌置为“[银月/青釭]”牌，其余手牌弃置，然后令此“青釭”牌不可被目标响应；\
	否则你可以摸X张牌（X为其他存活角色数），然后令此“青釭”牌伤害+1。",
	["mk_kongyingAnimate"] = "image=image/animate/mk_kongying.png",
	["$mk_kongying1"] = "枪出如龙势如虎，气掠涯南海角东！",
	["$mk_kongying2"] = "天涯海角不相负，海角天涯豪气存！",
	["~mk_WEIzhaoyun"] = "红日坠瑶池，白袍入枯冢......",
}
---------------------------------
--...
---------------------------------
--V2 全局技能需要实例先会被调度；此处先为全部武将挂 innate 实例，
--结算时再由 on_record 的 rushB_ensure_global_instances 补挂 acquired 实例。
for _, gen in sgs.qlist(sgs.Sanguosha:getAllGenerals()) do
	for _, skill_name in ipairs(rushB_global_skill_names) do
		gen:addSkill(skill_name)
	end
end
sgs.Sanguosha:addSkills(skills)
---------------------------------
return {extension}
