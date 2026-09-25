--==《新武将》==--
extension = sgs.Package("kearwangushengxiang", sgs.Package_GeneralPack)
local skills = sgs.SkillList()

--buff集中
kenewgirlniangslashmore = sgs.CreateTargetModSkillV2{
	name = "kenewgirlniangslashmore",
	pattern = ".",
	--[[residue_func = function(self, from, card, to)
		local n = 0
		return n
	end,]]
	correct_func = function(self, ctx)
		local n = 0
		--[[if (table.contains(card:getSkillNames(), "kerongchang")) then
			n = n + 1000
		end]]
		if ctx:getModType() == sgs.TargetModSkill_DistanceLimit then
			return n
		end
		return nil
	end
}
if not sgs.Sanguosha:getSkill("kenewgirlniangslashmore") then skills:append(kenewgirlniangslashmore) end

kenewgirlhuamulan = sgs.General(extension, "kenewgirlhuamulan", "qun", 3, false)
kenewgirlhuamulantwo = sgs.General(extension, "kenewgirlhuamulantwo", "qun", 3, false,true,true)
-- kenewgirlhuamulan:addSkill("hongyan")

kenewgirlshixieCard = sgs.CreateSkillCard{
	name = "kenewgirlshixieCard",
	will_throw = false,
	mute = true,
	filter = function(self, selected, to_select, player)
		return (#selected == 0)
		and (
			(to_select:getMark("banshixie-Clear") == 0)
	    )
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:moveCardTo(card, player, sgs.Player_DrawPile)
		if (card:getSuit() == sgs.Card_Spade) then
			room:broadcastSkillInvoke("kenewgirlshixie",4)
			room:setPlayerMark(player,"useshixiespade-Clear",1)
			room:setPlayerMark(target,"banshixie-Clear",1)
			room:damage(sgs.DamageStruct(self:objectName(), player, target, 2))
		elseif (card:getSuit() == sgs.Card_Club) then
			room:broadcastSkillInvoke("kenewgirlshixie",math.random(1,2))
			room:setPlayerMark(player,"useshixieclub-Clear",1)
			room:setPlayerMark(target,"banshixie-Clear",1)
			if player:canDiscard(target, "he") then
				local to_throw = room:askForCardChosen(player, target, "he", "kenewgirlshixie")
				local card = sgs.Sanguosha:getCard(to_throw)
				if card:isKindOf("EquipCard") then
					local card_use = sgs.CardUseStruct()
					card_use.from = player
					card_use.to:append(player)
					card_use.card = card
					room:useCard(card_use, false)
				else
				    room:throwCard(card, target, player)
				end
			end
		elseif (card:getSuit() == sgs.Card_Heart) then
			room:broadcastSkillInvoke("kenewgirlshixie",3)
			room:setPlayerMark(player,"useshixieheart-Clear",1)
			room:setPlayerMark(target,"banshixie-Clear",1)
			room:recover(target, sgs.RecoverStruct(),true)
			--target:gainHujia(1)
		elseif (card:getSuit() == sgs.Card_Diamond) then
			room:broadcastSkillInvoke("kenewgirlshixie",math.random(1,2))
			room:setPlayerMark(player,"useshixiediamond-Clear",1)
			room:setPlayerMark(target,"banshixie-Clear",1)
			local result = room:askForChoice(target,"kenewgirlshixie","top+bot")
			if result == "top" then
			    target:drawCards(2,"kenewgirlshixie")
			else
				target:drawCards(2,"kenewgirlshixie",false)
			end
		end
	end,
}

kenewgirlshixie = sgs.CreateViewAsSkillV2{
	name = "kenewgirlshixie",
	n = 1,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		return ((player:getMark("useshixiespade-Clear") == 0) and (candidate:getSuit() == sgs.Card_Spade))
		or ((player:getMark("useshixiediamond-Clear") == 0) and (candidate:getSuit() == sgs.Card_Diamond))
		or ((player:getMark("useshixieclub-Clear") == 0) and (candidate:getSuit() == sgs.Card_Club))
		or ((player:getMark("useshixieheart-Clear") == 0) and (candidate:getSuit() == sgs.Card_Heart))
	end ,
	card_selection_feasible = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return false end
		local player = request:getInitiator()
		local c = sgs.Sanguosha:getCard(ids:first())
		return ((c:getSuit() == sgs.Card_Spade) and (player:getMark("useshixiespade-Clear") == 0))
		or ((c:getSuit() == sgs.Card_Diamond) and (player:getMark("useshixiediamond-Clear") == 0))
		or ((c:getSuit() == sgs.Card_Club) and (player:getMark("useshixieclub-Clear") == 0))
		or ((c:getSuit() == sgs.Card_Heart) and (player:getMark("useshixieheart-Clear") == 0))
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = kenewgirlshixieCard:clone()
		card:addSubcards(getCardList(ids))
		return card
	end,
	can_select_target = function(skill, request, selected, candidate)
		return (#selected == 0)
		and (
			(candidate:getMark("banshixie-Clear") == 0)
	    )
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
}
kenewgirlhuamulan:addSkill(kenewgirlshixie)
kenewgirlhuamulantwo:addSkill(kenewgirlshixie)

kenewgirlcongrong = sgs.CreateTriggerSkillV2{
    name = "kenewgirlcongrong",
	frequency = sgs.Skill_Limited,
	limit_mark = "@kenewgirlcongrong",
	events = {sgs.DamageInflicted},
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.DamageInflicted then return false end
		local damage = data:toDamage()
		if not damage.to or (damage.damage < damage.to:getHp()) then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, ml in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if ml:getMark("@kenewgirlcongrong") > 0 then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, ml:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local _data = sgs.QVariant()
		_data:setValue(damage.to)
		room:setPlayerFlag(damage.to,"ifwantkenewgirlcongrong")
		local invoked = room:askForSkillInvoke(player, skill:objectName(), _data)
		room:setPlayerFlag(damage.to,"-ifwantkenewgirlcongrong")
		return invoked
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local victim = damage.to
		room:broadcastSkillInvoke(skill:objectName())
		room:doSuperLightbox("kenewgirlhuamulan", "kenewgirlcongrong")
		room:removePlayerMark(player,"@kenewgirlcongrong")
		local to_get = sgs.IntList()
		for _,c in sgs.qlist(victim:getCards("e")) do
			to_get:append(c:getEffectiveId())
		end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:addSubcards(getCardList(to_get))
		player:obtainCard(dummy)
		player:gainHujia(to_get:length())
		--room:recover(player, sgs.RecoverStruct())
		dummy:deleteLater()
		--room:setPlayerProperty(theone, "general", sgs.QVariant(kenewgirlhuamulantwo))
		--room:changeHero(player, "kenewgirlhuamulantwo", false, false, player:getGeneral2Name()=="kenewgirlhuamulan", false)
		if victim:getGeneralName() == "kenewgirlhuamulan" then
			room:changeHero(victim,"kenewgirlhuamulantwo",false, false, false, false)
		elseif victim:getGeneral2Name() == "kenewgirlhuamulan" then
			room:changeHero(victim,"kenewgirlhuamulantwo",false, false, true, false)
		else
		end
		room:handleAcquireDetachSkills(player, "-hongyan")
		room:removePlayerMark(player,"@kenewgirlcongrong")
		return true
	end,
}
kenewgirlhuamulan:addSkill(kenewgirlcongrong)
kenewgirlhuamulantwo:addSkill(kenewgirlcongrong)

sgs.LoadTranslationTable {
		--花木兰
	["kenewgirlhuamulan"] = "花木兰", 
	["&kenewgirlhuamulan"] = "花木兰",
	["#kenewgirlhuamulan"] = "万古生香",
	["designer:kenewgirlhuamulan"] = "小珂酱",
	["cv:kenewgirlhuamulan"] = "酒井苍，小珂酱",
	["illustrator:kenewgirlhuamulan"] = "官方",

	["kenewgirlhuamulantwo"] = "花木兰", 
	["&kenewgirlhuamulantwo"] = "花木兰",
	["#kenewgirlhuamulantwo"] = "万古生香",
	["designer:kenewgirlhuamulantwo"] = "小珂酱",
	["cv:kenewgirlhuamulantwo"] = "酒井苍，小珂酱",
	["illustrator:kenewgirlhuamulantwo"] = "官方",

	["kenewgirlshixie"] = "市械",
	[":kenewgirlshixie"] = "<font color='green'><b>出牌阶段每名角色或花色限一次，</b></font>你可以将一张牌置于牌堆顶令一名角色根据此牌花色执行对应效果：\
	♠：你对其造成2点伤害；\
	♣：你弃置其一张牌，若此牌为装备牌，你改为使用之；\
	♥：其回复1点体力；\
	♦：其从牌堆顶或牌堆底摸两张牌。",
	["kenewgirlshixie:top"] = "摸两张牌",
	["kenewgirlshixie:bot"] = "从牌堆底摸两张牌",

	["kenewgirlcongrong"] = "从戎",
	[":kenewgirlcongrong"] = "限定技，当一名角色受到致命伤害时，你可以获得其装备区的所有牌并获得等量的“护甲”，然后防止此伤害并失去“红颜”。",

	["$kenewgirlshixie1"] = "商市琳琅，吾独爱青锋三尺。",
	["$kenewgirlshixie2"] = "枝枝转势雕弓动，片片摇光玉剑斜。",
	["$kenewgirlshixie3"] = "红妆翠袖争曼舞，绣鞋玉钗贴花黄。",
	["$kenewgirlshixie4"] = "朔气传金柝，寒光照铁衣！",
	["$kenewgirlcongrong1"] = "舍旧时云裳，渡万里关山！",


    ["~kenewgirlhuamulan"] = "几度思归还把酒，拂云堆上祝明妃。",
	}


kenewgirlzhangfei = sgs.General(extension, "kenewgirlzhangfei", "qun", 3,false)

kenewgirlfuyi = sgs.CreateTriggerSkillV2{
	name = "kenewgirlfuyi",
	waked_skills = "mashu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirming,sgs.DamageForseen,sgs.PreHpRecover,sgs.CardEffected},
	can_trigger = function(skill, event, room, player, data)
		if (event == sgs.CardEffected) then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("Analeptic")
			and effect.card:hasFlag("kenewgirlfuyieff") then
				return skill:objectName(), player
			end
		elseif (event == sgs.PreHpRecover) then
			local recover = data:toRecover()
			if recover.card and recover.card:hasFlag("kenewgirlfuyieff") then
				return skill:objectName(), player
			end
		elseif (event == sgs.DamageForseen) then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("kenewgirlfuyieff") then
				return skill:objectName(), player
			end
		elseif (event == sgs.TargetConfirming) then
			local use = data:toCardUse()
			if (use.to:length() == 1)
			and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then
				local trigger_list_skill, trigger_list_who = {}, {}
				for _, zf in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					if (((use.to:at(0):objectName() == zf:objectName()) and (use.from:objectName() ~= zf:objectName()))
					or (use.from:objectName() == zf:objectName() and (use.to:at(0):objectName() ~= zf:objectName())))
					and (zf:getMark(use.card:getTypeId().."kenewgirlfuyi_lun") < 1) then
						table.insert(trigger_list_skill, skill:objectName())
						table.insert(trigger_list_who, zf:objectName())
					end
				end
				if #trigger_list_skill > 0 then
					return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event ~= sgs.TargetConfirming then return true end
		local data = ctx.original_data
		local use = data:toCardUse()
		local zf = player
		local choicelist = "eff+beishui"
		local targets = sgs.SPlayerList()
		for _, all in sgs.qlist(room:getAllPlayers()) do
			if use.card:targetFilter(sgs.PlayerList(), all, use.from) and not room:isProhibited(use.from, all, use.card) then
				targets:append(all)
			end
		end
		if not targets:isEmpty() then
			choicelist = string.format("%s+%s", choicelist, "add")
		end
		choicelist = string.format("%s+%s", choicelist, "cancel")
		local result = room:askForChoice(zf,skill:objectName(),choicelist, data)
		if result == "cancel" then return false end
		room:setTag("kenewgirlfuyi", data)
		ctx.choice = result
		ctx.extra_data:setValue("")
		if result == "add" then
			local enys = room:askForPlayersChosen(zf, targets, skill:objectName(), 0, 2, "kenewgirlfuyi-ask", false, true)
			local names = {}
			for _, p in sgs.qlist(enys) do
				table.insert(names, p:objectName())
			end
			ctx.extra_data:setValue(table.concat(names, "+"))
		elseif result == "beishui" then
			room:setPlayerFlag(zf,"beishuifuyi")
			local enys = room:askForPlayersChosen(zf, room:getOtherPlayers(use.to:at(0)), skill:objectName(), 0, 2, "kenewgirlfuyi-ask", false, true)
			room:setPlayerFlag(zf,"-beishuifuyi")
			local names = {}
			for _, p in sgs.qlist(enys) do
				table.insert(names, p:objectName())
			end
			ctx.extra_data:setValue(table.concat(names, "+"))
		end
		return true
	end,
	on_pay = function(skill, event, room, player, ctx)
		if event ~= sgs.TargetConfirming then return true end
		local use = ctx.original_data:toCardUse()
		if use.card:getTypeId()>0
		and player:getMark(use.card:getTypeId().."kenewgirlfuyi_lun")<1
		then
			room:addPlayerMark(player,use.card:getTypeId().."kenewgirlfuyi_lun")
			MarkRevises(player,"&kenewgirlfuyi_lun",use.card:getType())
		end
		room:broadcastSkillInvoke(skill:objectName())
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.CardEffected then
			local effect = ctx.original_data:toCardEffect()
			if effect.card:isKindOf("Analeptic")
			and effect.card:hasFlag("kenewgirlfuyieff") then
				room:addPlayerMark(effect.to,"drank",1)
			end
			return false
		elseif event == sgs.PreHpRecover then
			local recover = ctx.original_data:toRecover()
			if recover.card and recover.card:hasFlag("kenewgirlfuyieff") then
				local rec = recover.recover
				recover.recover = 1 + rec
				ctx.original_data:setValue(recover)
			end
			return false
		elseif event == sgs.DamageForseen then
			local damage = ctx.original_data:toDamage()
			if damage.card and damage.card:hasFlag("kenewgirlfuyieff") then
				local hurt = damage.damage
				damage.damage = hurt+ 1
				ctx.original_data:setValue(damage)
			end
			return false
		elseif event == sgs.TargetConfirming then
			local use = ctx.original_data:toCardUse()
			local result = ctx.choice
			local zf = player
			if result == "add" then
				for _, name in sgs.qlist(ctx.extra_data:toString():split("+")) do
					local p = room:findPlayerByObjectName(name, true)
					if p then
						use.to:append(p)
						room:doAnimate(1, use.from:objectName(), p:objectName())
					end
				end
				room:sortByActionOrder(use.to)
				ctx.original_data:setValue(use)
				--sendlog
			elseif result == "eff" then
				room:setCardFlag(use.card,"kenewgirlfuyieff")
			elseif result == "beishui" then
				local tyjy = sgs.Sanguosha:cloneCard("god_salvation", use.card:getSuit(), use.card:getNumber())
				use.card = tyjy
				--room:setCardFlag(use.card, skill:objectName())
				ctx.original_data:setValue(use)
				tyjy:deleteLater()
				room:handleAcquireDetachSkills(zf, "-kenewgirlfuyi|mashu")
				for _, name in sgs.qlist(ctx.extra_data:toString():split("+")) do
					local p = room:findPlayerByObjectName(name, true)
					if p then
						use.to:append(p)
						room:doAnimate(1, use.from:objectName(), p:objectName())
					end
				end
				room:sortByActionOrder(use.to)
				room:setCardFlag(use.card,"kenewgirlfuyieff")
				ctx.original_data:setValue(use)
			end
		end
		return false
	end,
}
kenewgirlzhangfei:addSkill(kenewgirlfuyi)

kenewgirlzhenyi = sgs.CreateTriggerSkillV2{
	name = "kenewgirlzhenyi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardFinished,sgs.Damage,sgs.CardUsed},
	can_trigger = function(skill, event, room, player, data)
		if (event == sgs.CardUsed) and player:hasSkill(skill:objectName()) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				return skill:objectName(), player
			end
		elseif (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card and damage.from then
				return skill:objectName(), player
			end
		elseif (event == sgs.CardFinished) then
			return skill:objectName(), player
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.CardFinished then
			local use = ctx.original_data:toCardUse()
			if use.card:isDamageCard() and not use.card:hasFlag("kenewgirlzhenyiflag") then
				room:setPlayerFlag(use.from, "kenewgirlzhenyiTarget")
				ctx.extra_data:setValue("go")
			end
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if (event == sgs.CardUsed) and player:hasSkill(skill:objectName()) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				if player:hasFlag("useslashzhenyi") and player:hasFlag("playkenewgirlzhenyi") then
					room:broadcastSkillInvoke(skill:objectName(),4)
				end
				room:setPlayerFlag(player,"useslashzhenyi")
			end
		elseif (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card and damage.from then
				room:setCardFlag(damage.card, "kenewgirlzhenyiflag")
			end
		elseif (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if ctx.extra_data:toString() == "go" then
				for _, zf in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					if (zf:distanceTo(use.from) <= 1)
					and zf:askForSkillInvoke(skill:objectName(),ToData("kenewgirlzhenyi-ask:"..use.from:objectName()..":"..use.to:length())) then
						if (use.from:objectName() == zf:objectName()) and (zf:getPhase() == sgs.Player_Play) then
							room:setPlayerFlag(zf,"playkenewgirlzhenyi")
						end
						room:broadcastSkillInvoke(skill:objectName(),math.random(1,3))
						if use.m_addHistory then
							--room:addPlayerHistory(use.from, use.card:getClassName(),-1)
							use.m_addHistory = false
							data:setValue(use)
						end
						use.from:drawCards(use.to:length(),skill:objectName())
						if zf:getHandcardNum() < use.from:getHandcardNum() then
							zf:obtainCard(use.card)
						end
					end
				end
				room:setPlayerFlag(use.from, "-kenewgirlzhenyiTarget")
			end
			room:setCardFlag(use.card, "-kenewgirlzhenyiflag")
		end
		return false
	end,
}
kenewgirlzhangfei:addSkill(kenewgirlzhenyi)

sgs.LoadTranslationTable {
--新张飞
	["kenewgirlzhangfei"] = "张飞[香]", 
	["&kenewgirlzhangfei"] = "张飞",
	["#kenewgirlzhangfei"] = "逢贤的飞翼",
	["designer:kenewgirlzhangfei"] = "小珂酱",
	["cv:kenewgirlzhangfei"] = "小沉香，小珂酱",
	["illustrator:kenewgirlzhangfei"] = "-",
	["information:kenewgirlzhangfei"] = "ᅟᅠ<i>她笑嘻嘻地伸出手，角落里缩成一团的幼虎龇起牙，猛地一挠，给那只手添上几道血痕。她也不恼，随意掸掸灰便席地而坐，嘴里轻轻哼起歌来，身体跟着拍子微微摇晃。她的影子在阳光下越拉越长，随后完全消失，直到烛灯亮起才又蹦了出来，忽明忽闪地摇曳在桃花巷里。\
    ᅟᅠ万籁俱寂，只留轻柔的歌声在风中回荡，当旋律再度重复时，眼泪从她脸颊划过，脑海又回想起早些时候遇到的两位特别的伙伴......\
    ᅟᅠ“桃花短暂，却将最珍贵的时刻，印照心间。”</i>",


	["kenewgirlzhenyi:kenewgirlzhenyi-ask"] = "你可以发动“振翼”令 %src 摸 %dest 张牌",

	["kenewgirlfuyi"] = "赴义",
	["kenewgirlfuyi-ask"] = "请选择此牌的额外目标（至多两名）",
	["kenewgirlfuyi:add"] = "为此牌选择至多两名额外目标",
	["kenewgirlfuyi:eff"] = "令此牌的伤害值或回复值+1",
	["kenewgirlfuyi:beishui"] = "背水：依次执行前两项",
	[":kenewgirlfuyi"] = "<font color='green'><b>每轮每种类型限一次，</s></font>当你/其他角色使用基本牌或普通锦囊牌指定其他角色/你角色为唯一目标时，你可以选择一项：1.选择至多两名额外目标；2.令此牌的伤害值或回复值+1；\
	背水：将牌名改为【桃园结义】且你失去“赴义”并获得“马术”。",
	
	
	["kenewgirlzhenyi"] = "振翼",
	[":kenewgirlzhenyi"] = "当你距离1以内的角色使用的未造成伤害的伤害类牌结算完毕后，你可以令此牌不计入次数且其摸等同于此牌目标数的牌，然后若你的手牌数小于其，你获得此牌。",
	
	["$kenewgirlfuyi1"] = "侠气盈门千光照，春意满园百媚生。",
	["$kenewgirlfuyi2"] = "桃园之谊，千秋不弃。",
	["$kenewgirlfuyi3"] = "英雄露颖在今朝，一试矛兮一试刀。",
	["$kenewgirlzhenyi1"] = "落樱翩翩，展翼垂天！",
	["$kenewgirlzhenyi2"] = "一盏桃花酿，手足情，自难忘~",
	["$kenewgirlzhenyi3"] = "没了张屠夫，还想吃带毛猪？",
	["$kenewgirlzhenyi4"] = "今必斩汝马下！",

	["~kenewgirlzhangfei"] = "涿县的桃花，开了吗？",
}

kenewgirlnvjiangwei = sgs.General(extension, "kenewgirlnvjiangwei", "shu", 3,false)

kenewgirljizhi = sgs.CreateTriggerSkillV2{
	name = "kenewgirljizhi",
	frequency = sgs.Skill_Limited,
	limit_mark = "@kenewgirljizhimark",
	events = {sgs.AskForPeaches,sgs.BuryVictim},
	can_trigger = function(skill, event, room, player, data)
		if (event == sgs.AskForPeaches)
		and player:hasSkill(skill:objectName())
		and (player:getMark("@kenewgirljizhimark") > 0) then
			local dying_data = data:toDying()
			if dying_data.who:objectName() == player:objectName() then
				return skill:objectName(), player
			end
		elseif event == sgs.BuryVictim then
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then
				return skill:objectName(), player
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.AskForPeaches then
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		elseif event == sgs.BuryVictim then
			local fris = room:askForPlayersChosen(player, room:findPlayersBySkillName(skill:objectName()), skill:objectName(), 0, 99, "kenewgirljizhi-ask", true, true)
			local names = {}
			for _, p in sgs.qlist(fris) do
				table.insert(names, p:objectName())
			end
			ctx.extra_data:setValue(table.concat(names, "+"))
		end
		return true
	end,
	on_pay = function(skill, event, room, player, ctx)
		if event == sgs.AskForPeaches then
			room:broadcastSkillInvoke(skill:objectName())
			room:doSuperLightbox("kenewgirlnvjiangwei", "kenewgirljizhi")
			room:removePlayerMark(player,"@kenewgirljizhimark")
		elseif event == sgs.BuryVictim then
			if ctx.extra_data:toString() ~= "" then
				room:broadcastSkillInvoke(skill:objectName())
			end
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.AskForPeaches then
			local recover = sgs.RecoverStruct()
			recover.who = player
			recover.recover = 2
			room:recover(player, recover,true)
			local num = 0
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if not player:isYourFriend(p) then
					num = num + 1
				end
			end
			room:drawCards(player,num,skill:objectName())
		elseif event == sgs.BuryVictim then
			for _, name in sgs.qlist(ctx.extra_data:toString():split("+")) do
				local p = room:findPlayerByObjectName(name, true)
				if p then
					room:setPlayerMark(p,"@kenewgirljizhimark",1)
				end
			end
		end
		return false
	end,
}
kenewgirlnvjiangwei:addSkill(kenewgirljizhi)

kenewgirljingmuCard = sgs.CreateSkillCard{
	name = "kenewgirljingmuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return (#targets < 1) and (to_select:objectName() ~= player:objectName())
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		--[[local ids = sgs.IntList()
		for _, id in sgs.qlist(self:getSubcards()) do
			ids:append(id)
		end]]
		player:addToPile("kenewgirljingmu", self:getSubcards(),false)
		local result = room:askForChoice(target,"kenewgirljingmu","one+two")
	    if result == "one" then	
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName("kenewgirljingmu")
			local card_use = sgs.CardUseStruct()
			card_use.from = target
			card_use.to:append(target)
			card_use.card = slash
			room:useCard(card_use, false)
			slash:deleteLater()  
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local dummytwo = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local get = 0
			local gettwo = 0
			local rec = sgs.IntList()
			for _, id in sgs.qlist(player:getPile("kenewgirljingmu")) do
				if not sgs.Sanguosha:getCard(id):isAvailable(player) then
					dummy:addSubcard(id)
					get = 1
				else
					dummytwo:addSubcard(id)
					gettwo = gettwo + 1
				end
			end
			if get == 1 then
			    player:obtainCard(dummy)
			end
			dummy:deleteLater()
			if gettwo > 0 then
			    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName())
				reason.m_skillName = "kenewgirljingmu"
				room:moveCardTo(dummytwo, player, nil, sgs.Player_DiscardPile, reason)
				player:drawCards(gettwo,"recast")
			end
			dummytwo:deleteLater()
		else
			room:showCard(player,player:getPile("kenewgirljingmu"))
			local get = 0
			local gettwo = 0
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local dummytwo = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			for _, id in sgs.qlist(player:getPile("kenewgirljingmu")) do
				if sgs.Sanguosha:getCard(id):isAvailable(player) then
					dummy:addSubcard(id)
					get = get + 1
				else
					dummytwo:addSubcard(id)
					gettwo = 1
				end
			end
			if (get > 0) then
			    player:obtainCard(dummy)
			end
			dummy:deleteLater()
			if (gettwo == 1) then
			    room:throwCard(dummytwo, nil, player)
			end
			dummytwo:deleteLater()
			if (get > 0) then
				local disnum = get + get
				local ddd = math.min(disnum,target:getCardCount())
			    room:askForDiscard(target, "kenewgirljingmu", ddd, ddd, false, true, "kenewgirljingmudis")
			end
            if (get == 0) then
				room:setPlayerMark(target,"&kenewgirljingmubuff-SelfClear",1)
			end
		end
	end
}

kenewgirljingmu = sgs.CreateViewAsSkillV2{
    name = "kenewgirljingmu",
    n = 99,
    target_mode = sgs.ViewAsSkillV2_SelectTargets,
    limit_scope = sgs.Skill_Limit_Phase,
    max_usage_limit = 1,
    can_activate = function(skill, request)
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
    end,
    can_select_card = function(skill, request, candidate)
        return (not candidate:isEquipped()) and request:getSelectedCardIds():length() < 99
    end,
    card_selection_feasible = function(skill, request)
        return request:getSelectedCardIds():length() > 0
    end,
    create_card = function(skill, request)
        local ids = request:getSelectedCardIds()
        if ids:length() == 0 then return nil end
        local card = kenewgirljingmuCard:clone()
        card:addSubcards(getCardList(ids))
        return card
    end,
    can_select_target = function(skill, request, selected, candidate)
        return (#selected < 1) and (candidate:objectName() ~= request:getInitiator():objectName())
    end,
    targets_feasible = function(skill, request, selected)
        return #selected == 1
    end,
}
kenewgirlnvjiangwei:addSkill(kenewgirljingmu)

sgs.LoadTranslationTable {
	["kenewgirlnvjiangwei"] = "姜维[香]", 
	["&kenewgirlnvjiangwei"] = "姜维",
	["#kenewgirlnvjiangwei"] = "纵死不折",
	["designer:kenewgirlnvjiangwei"] = "小珂酱",
	["cv:kenewgirlnvjiangwei"] = "欧皇在努力，小珂酱",
	["illustrator:kenewgirlnvjiangwei"] = "-",

	["kenewgirljizhi"] = "继志",
	["kenewgirljizhi-ask"] = "你可以令任意名角色重置“继志”",
	[":kenewgirljizhi"] = "限定技，当你处于濒死状态时，你回复2点体力并摸X张牌（X为与你阵营不同的角色数）；其他角色死亡后，其可以令你重置“继志”。",
	
	["kenewgirljingmu"] = "惊木",
	["kenewgirljingmubuff"] = "惊木距离",
	
	["kenewgirljingmu:one"] = "对自己使用一张【杀】",
	["kenewgirljingmu:two"] = "亮出扣置的牌",
	[":kenewgirljingmu"] = "出牌阶段限一次，你可以扣置任意张牌并令一名其他角色选择一项：1.其视为对其使用一张【杀】，你收回不能使用的牌并重铸其余牌。2.亮出扣置的牌，你收回可以使用的牌，然后其弃置两倍的牌，若没有可以使用的牌，其下回合对你使用牌无距离限制。",
	
	["kenewgirljingmudis"] = "惊木：请选择弃置的牌",


	["$kenewgirljizhi1"] = "铁血长河冷，萧萧金戈凉。",
	["$kenewgirljizhi2"] = "剑出铮铮响，叱咤起一方！",
	["$kenewgirljizhi3"] = "赤血一腔染剑霜，白发千丈祭国殇！",
	["$kenewgirljingmu1"] = "丞相在此，小儿岂敢不降？！",
	["$kenewgirljingmu2"] = "凭此木像，可教魏兵望风而逃！",

	["~kenewgirlnvjiangwei"] = "心未死，国未亡...",
}

kenewgirlnvzhugeliang = sgs.General(extension, "kenewgirlnvzhugeliang", "qun", 3,false)

kenewgirlduoshuai = sgs.CreateTriggerSkillV2{
	name = "kenewgirlduoshuai",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameReady,--[[sgs.DrawInitialCards,]]sgs.DrawNCards},
	can_trigger = function(skill, event, room, player, data)
		if not player:hasSkill(skill:objectName()) then return false end
		if event == sgs.GameReady then
			return skill:objectName(), player
		elseif (event == sgs.DrawNCards) and player:hasFlag("hasusedduoshuai") then
			return skill:objectName(), player
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.GameReady then
			local eny = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "kenewgirlduoshuai-ask", true, true)
			if not eny then return false end
			ctx.extra_data:setValue(eny)
			ctx.choice = room:askForChoice(player,"kenewgirlduoshuai","one+two")
		end
		return true
	end,
	on_pay = function(skill, event, room, player, ctx)
		if event == sgs.GameReady then
			room:broadcastSkillInvoke(skill:objectName())
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.GameReady then
			local eny = ctx.extra_data:toPlayer()
			if ctx.choice == "one" then
				room:damage(sgs.DamageStruct(skill:objectName(), player, eny,1))
			else
				room:damage(sgs.DamageStruct(skill:objectName(), player, eny,2))
			end
			room:setPlayerFlag(player,"hasusedduoshuai")
			room:setPlayerMark(player,"usekenewgirlduoshuai",math.min(5,eny:getHp()))
			if not eny:isAlive() then room:setPlayerMark(player,"usekenewgirlduoshuai",0) end
		elseif (event == sgs.DrawNCards) and player:hasFlag("hasusedduoshuai") then
			local draw = ctx.original_data:toDraw()
			if (draw.reason == "InitialHandCards") then
				room:setPlayerFlag(player,"-hasusedduoshuai")
				local num = draw.num
				draw.num = player:getMark("usekenewgirlduoshuai")
				ctx.original_data:setValue(draw)
				room:setPlayerMark(player,"usekenewgirlduoshuai",0)
			end
		end
		return false
	end,
	priority = -5,
}
kenewgirlnvzhugeliang:addSkill(kenewgirlduoshuai)

kenewgirlshibing = sgs.CreateTriggerSkillV2{
	name = "kenewgirlshibing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted,sgs.ConfirmDamage},
	can_trigger = function(skill, event, room, player, data)
		if not player:hasSkill(skill:objectName()) then return false end
		local damage = data:toDamage()
		if --[[(player:getMark("usetimesshibing-Clear") - player:getMark("&kenewgirlshibing") <= 0)
		and (damage.reason ~= "kenewgirlduoshuai")
		and]]damage.card then
			return skill:objectName(), player
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_pay = function(skill, event, room, player, ctx)
		room:setEmotion(player,"armor/eight_diagram")
		--player:drawCards(1)
		room:addPlayerMark(player,"usetimesshibing-Clear")
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if (event == sgs.ConfirmDamage) then
			local damage = data:toDamage()
			local _data = sgs.QVariant()
			_data:setValue(damage.to)
			local judge = sgs.JudgeStruct()
			judge.good = false
			judge.pattern = ".|.|1,7,11,13|."
			judge.play_animation = true
			judge.who = player
			judge.reason = skill:objectName()
			room:judge(judge)
			local thenum = judge.card:getNumber()
			if (thenum % 2 == 0) then
				local log = sgs.LogMessage()
				log.type = "$kenewgirlshibingdraw"
				log.from = player
				room:sendLog(log)
				--sgs.Sanguosha:playAudioEffect("audio/equip/eight_diagram.ogg")

				player:drawCards(2)
			end
			local bf = 0
			if (thenum % 3 == 0) then
				room:broadcastSkillInvoke(skill:objectName(),math.random(1,4))
				bf = 1
				local log = sgs.LogMessage()
				log.type = "$kenewgirlshibingdiscard"
				log.from = player
				room:sendLog(log)
				if player:canDiscard(damage.to, "he") and room:askForSkillInvoke(player, "kenewgirlshibingdiscardask", _data) then
					local id = room:askForCardChosen(player, damage.to, "he", skill:objectName(), false, sgs.Card_MethodDiscard)
					room:throwCard(id, damage.to, player)
				end
			end
			if (thenum % 4 == 0) then
				if bf == 0 then
					room:broadcastSkillInvoke(skill:objectName(),math.random(3,4))
				end
				local log = sgs.LogMessage()
				log.type = "$kenewgirlshibingfour"
				log.from = player
				room:sendLog(log)
				local result = room:askForChoice(player,"kenewgirlshibing","add+dis+cancel", data)
				if result == "add" then
					local hurt = damage.damage
					damage.damage = hurt + 1
					data:setValue(damage)
					local log = sgs.LogMessage()
					log.type = "$kenewgirlshibingadd"
					log.from = player
					room:sendLog(log)
				end
				if result == "dis" then
					--[[if bf == 0 then
					    room:broadcastSkillInvoke(skill:objectName(),math.random(1,2))
					end]]
					local hurt = damage.damage
					local log = sgs.LogMessage()
					log.type = "$kenewgirlshibingdis"
					log.from = player
					room:sendLog(log)
					if hurt > 1 then
						damage.damage = hurt - 1
						data:setValue(damage)
					else
						damage.prevented = true
						data:setValue(damage)
						return true
					end
				end
			end
			if (thenum % 5 == 0) then
				local log = sgs.LogMessage()
				log.type = "$kenewgirlshibingfive"
				log.from = player
				room:sendLog(log)
				room:setTag("kenewgirlshibingDamage", data)
				local eny = room:askForPlayerChosen(player, room:getOtherPlayers(damage.to), skill:objectName(), "kenewgirlshibing-ask", true, true)
				room:removeTag("kenewgirlshibingDamage")
				if eny then
					room:doAnimate(1, player:objectName(), eny:objectName())
					room:broadcastSkillInvoke(skill:objectName(),5)
					room:getThread():delay(700)
					damage.to = eny
					damage.transfer = true
					data:setValue(damage)
					local logg = sgs.LogMessage()
					logg.type = "$kenewgirlshibingtransfer"
					logg.from = player
					logg.to:append(eny)
					room:sendLog(logg)
				end
			end
			--[[if (thenum % 2 ~= 0) and (thenum % 3 ~= 0) and (thenum % 4 ~= 0) and (thenum % 5 ~= 0) then
				room:addPlayerMark(player,"&kenewgirlshibing")
			end]]
		end
		if (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			local _data = sgs.QVariant()
			_data:setValue(damage.from)
			local judge = sgs.JudgeStruct()
			judge.good = false
			judge.pattern = ".|.|1,7,11,13|."
			judge.play_animation = true
			judge.who = player
			judge.reason = skill:objectName()
			room:judge(judge)
			local thenum = judge.card:getNumber()
			if (thenum % 2 == 0) then
				local log = sgs.LogMessage()
				log.type = "$kenewgirlshibingdraw"
				log.from = player
				room:sendLog(log)
				--sgs.Sanguosha:playAudioEffect("audio/equip/eight_diagram.ogg")

				player:drawCards(2)
			end
			local bf = 0
			if (thenum % 3 == 0) then
				room:broadcastSkillInvoke(skill:objectName(),math.random(1,4))
				bf = 1
				local log = sgs.LogMessage()
				log.type = "$kenewgirlshibingdiscard"
				log.from = player
				room:sendLog(log)
				if not player:isYourFriend(damage.from) then room:setPlayerFlag(player,"wantuseshibingdis") end
				if player:canDiscard(damage.from, "he") and room:askForSkillInvoke(player, "kenewgirlshibingdiscardask", _data) then
					local id = room:askForCardChosen(player, damage.from, "he", skill:objectName(), false, sgs.Card_MethodDiscard)
					room:throwCard(id, damage.from, player)
				end
				room:setPlayerFlag(player,"-wantuseshibingdis")
			end
			if (thenum % 4 == 0) then
				if bf == 0 then
					room:broadcastSkillInvoke(skill:objectName(),math.random(3,4))
				end
				local log = sgs.LogMessage()
				log.type = "$kenewgirlshibingfour"
				log.from = player
				room:sendLog(log)
				if player:isYourFriend(damage.to) then room:setPlayerFlag(player,"wantuseshibingjian") end
				local result = room:askForChoice(player,"kenewgirlshibing","add+dis+cancel")
				room:setPlayerFlag(player,"-wantuseshibingjian")
				if result == "add" then
					local hurt = damage.damage
					damage.damage = hurt + 1
					data:setValue(damage)
					local log = sgs.LogMessage()
					log.type = "$kenewgirlshibingadd"
					log.from = player
					room:sendLog(log)
				end
				if result == "dis" then
					local hurt = damage.damage
					local log = sgs.LogMessage()
					log.type = "$kenewgirlshibingdis"
					log.from = player
					room:sendLog(log)
					if hurt > 1 then
						damage.damage = hurt - 1
						data:setValue(damage)
					else
						return true
					end
				end
			end
			if (thenum % 5 == 0) then
				local log = sgs.LogMessage()
				log.type = "$kenewgirlshibingfive"
				log.from = player
				room:sendLog(log)
				room:setTag("kenewgirlshibingDamage", data)
				local eny = room:askForPlayerChosen(player, room:getOtherPlayers(damage.to), skill:objectName(), "kenewgirlshibing-ask", true, true)
				room:removeTag("kenewgirlshibingDamage")
				if eny then
					room:doAnimate(1, player:objectName(), eny:objectName())
					room:broadcastSkillInvoke(skill:objectName(),5)
					room:getThread():delay(700)
					damage.to = eny
					damage.transfer = true
					data:setValue(damage)
					local logg = sgs.LogMessage()
					logg.type = "$kenewgirlshibingtransfer"
					logg.from = player
					logg.to:append(eny)
					room:sendLog(logg)
				end
			end
			if (thenum % 2 ~= 0) and (thenum % 3 ~= 0) and (thenum % 4 ~= 0) and (thenum % 5 ~= 0) then
				--room:addPlayerMark(player,"&kenewgirlshibing")
				room:setPlayerMark(player,"usetimesshibing-Clear",0)
			end
		end
		return false
	end,
}
kenewgirlnvzhugeliang:addSkill(kenewgirlshibing)

sgs.LoadTranslationTable {
--新诸葛亮
	["kenewgirlnvzhugeliang"] = "诸葛亮[香]", 
	["&kenewgirlnvzhugeliang"] = "诸葛亮",
	["#kenewgirlnvzhugeliang"] = "敢归云间宿",
	["designer:kenewgirlnvzhugeliang"] = "小珂酱",
	["cv:kenewgirlnvzhugeliang"] = "酒井苍，小珂酱",
	["illustrator:kenewgirlnvzhugeliang"] = "-",
	["information:kenewgirlnvzhugeliang"] = "ᅟᅠ<i>大火在眼前燃起，迸出股股浓烟，被点燃的草木发出噼啪的爆响......\
ᅟᅠ“啊。”又做噩梦了，阿亮在榻上慵懒地坐起身来，摇了摇脑袋。水镜说过，梦境都映照着现实，为什么自己常常会做些奇怪的梦呢......\
ᅟᅠ晌午已过，桌上的烛台在阳光下熠熠生光，让人睁不开眼。睡眼朦胧里，三只青鸟从屋檐飞过，清脆的歌声飘荡在山谷——乱世依然，此景却不得多见。\
ᅟᅠ该去地里浇水了。\
ᅟᅠ阿亮推开房门，却听见噼啪的声响，远处闪过一袭少女的身影，大火在眼前燃起，迸出股股浓烟......\
ᅟᅠ“喂，是谁在我草庐边上玩火！”</i>",


	["kenewgirlduoshuai"] = "夺帅",
	["kenewgirlduoshuai:two"] = "对其造成2点伤害",
	["kenewgirlduoshuai:one"] = "对其造成1点伤害",
	["kenewgirlduoshuai-ask"] = "你可以发动“夺帅”对一名角色造成1或2点伤害",
	[":kenewgirlduoshuai"] = "<font color='green'><b>游戏开始前，</b></font>你可以对一名其他角色造成1或2点伤害，然后你的起始手牌数改为其体力值（至多五张）。",

	["kenewgirlshibing"] = "石兵",
	["kenewgirlshibing:add"] = "此伤害+1",
	["kenewgirlshibing:dis"] = "此伤害-1",
	[":kenewgirlshibing"] = "当你因牌受到或造成伤害时，你可以判定，若结果为：\
	○2的倍数，你摸两张牌；\
	○3的倍数，你可以弃置对方的一张牌；\
	○4的倍数，你可以令此伤害-1或+1；\
	○5的倍数，你可以将此伤害转移给一名角色。",

	["$kenewgirlshibingdraw"] = "%from 的<font color='yellow'><b>“石兵”</b></font>判定结果为2的倍数。",
	["$kenewgirlshibingdiscard"] = "%from 的<font color='yellow'><b>“石兵”</b></font>判定结果为3的倍数。",
	["$kenewgirlshibingfour"] = "%from 的<font color='yellow'><b>“石兵”</b></font>判定结果为4的倍数。",
	["$kenewgirlshibingdis"] = "%from 选择令此伤害-1。",
	["$kenewgirlshibingadd"] = "%from 选择令此伤害+1。",
	["$kenewgirlshibingfive"] = "%from 的<font color='yellow'><b>“石兵”</b></font>判定结果为5的倍数。",
	["$kenewgirlshibingtransfer"] = "%from 将此伤害转移给 %to 。",

	["kenewgirlshibing-ask"] = "你可以发动“石兵”将此伤害转移给一名角色",
	["kenewgirlshibingdiscardask"] = "石兵：弃置其一张牌",

	["$kenewgirlduoshuai1"] = "与其恋子以求生，不如弃子而取胜！",
	["$kenewgirlduoshuai2"] = "袭敌未稳之际，攻其无备之间！",
	["$kenewgirlduoshuai3"] = "夺敌帅旗，寒敌军心！",
	["$kenewgirlduoshuai4"] = "宁失一子，莫输一先！",

	["$kenewgirlshibing1"] = "静以修身，俭以养德。",
	["$kenewgirlshibing2"] = "图难于易，为大于细。",
	["$kenewgirlshibing3"] = "乱石筑兵阵，遁甲开八门。",
	["$kenewgirlshibing4"] = "门下三千客，胸中十万兵！",
	["$kenewgirlshibing5"] = "将军！",

    ["~kenewgirlnvzhugeliang"] = "天公若借二十载，仍作少年弈东风！",
}

kenewgirlniangzhaoyun = sgs.General(extension, "kenewgirlniangzhaoyun", "qun", 3,false)

kenewgirltanyan = sgs.CreateTriggerSkillV2{
	name = "kenewgirltanyan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.TargetSpecified},
	can_trigger = function(skill, event, room, player, data)
		if not player:hasSkill(skill:objectName()) then return false end
		if (event == sgs.TargetSpecified) then
			if (player:getPhase() == sgs.Player_Play) then
				return skill:objectName(), player
			end
		elseif (event == sgs.EventPhaseStart) then
			if player:getPhase() == sgs.Player_Play then
				return skill:objectName(), player
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local enys = room:askForPlayersChosen(player, room:getAllPlayers(), skill:objectName(), 0, 4, "kenewgirltanyan-ask", true, false)
			local names = {}
			for _, eny in sgs.qlist(enys) do
				table.insert(names, eny:objectName())
			end
			ctx.extra_data:setValue(table.concat(names, "+"))
		end
		return true
	end,
	on_pay = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			if ctx.extra_data:toString() ~= "" then
				room:broadcastSkillInvoke(skill:objectName())
			end
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if (event == sgs.TargetSpecified) then
			if (player:getPhase() == sgs.Player_Play) then
				if player:getMark("endtanyan-PlayClear") == 0 then
				    room:addPlayerMark(player,"usecardtanyan-PlayClear",1)
				end
				if (player:getMark("usecardtanyan-PlayClear") > player:getMark("allnumtanyan-PlayClear")) then
					room:setPlayerMark(player,"usecardtanyan-PlayClear",0)
					room:setPlayerMark(player,"endtanyan-PlayClear",1)
				end
			end
		end
		if (event == sgs.EventPhaseStart) then
			if player:getPhase() == sgs.Player_Play then
				local enys = sgs.SPlayerList()
				for _, name in sgs.qlist(ctx.extra_data:toString():split("+")) do
					local p = room:findPlayerByObjectName(name, true)
					if p then enys:append(p) end
				end
				if (enys:length() > 0) then
					--给一个初始计数值
					room:setPlayerMark(player,"allnumtanyan-PlayClear",enys:length())
					room:addPlayerMark(player,"usecardtanyan-PlayClear",1)
					player:drawCards(player:getMark("allnumtanyan-PlayClear"),skill:objectName())
					local num = 1
					room:doAnimate(1, player:objectName(), enys:at(0):objectName())
					room:getThread():delay(600)
					room:setEmotion(enys:at(0),"Arcane/dianxing")
					local playerxxx = enys:at(0)
					for _, eny in sgs.qlist(enys) do
						room:setPlayerMark(eny,"tanyanshunxu-PlayClear",num)
						num = num + 1
						if (playerxxx:objectName() ~= eny:objectName()) then
						    room:doAnimate(1, playerxxx:objectName(), eny:objectName())
						    room:getThread():delay(600)
						    room:setEmotion(eny,"Arcane/dianxing")
						end
						playerxxx = eny
					end
				end
			end
		end
		return false
	end,
}
kenewgirlniangzhaoyun:addSkill(kenewgirltanyan)

kenewgirltanyanex = sgs.CreateProhibitSkill{
	name = "kenewgirltanyanex",
	is_prohibited = function(self, from, to, card)
		return from and (from:getMark("usecardtanyan-PlayClear") > 0)
		and to and (to:getMark("tanyanshunxu-PlayClear") ~= from:getMark("usecardtanyan-PlayClear"))
	end
}
if not sgs.Sanguosha:getSkill("kenewgirltanyanex") then skills:append(kenewgirltanyanex) end



kenewgirlganglvCard = sgs.CreateSkillCard{
	name = "kenewgirlganglv",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	mute = true,
	filter = function(self, targets, to_select, player)
		local card = sgs.Sanguosha:getCard(self:getSubcards():at(0))
		local lists = sgs.PlayerList()
		for _, t in sgs.list(targets) do lists:append(t) end
		return card:targetFilter(lists, to_select, player) and not player:isProhibited(to_select, card, lists)
	end,
	feasible = function(self, targets, player)
		local card = sgs.Sanguosha:getCard(self:getSubcards():at(0))
		local lists = sgs.PlayerList()
		for _, t in sgs.list(targets) do lists:append(t) end
		return card:targetsFeasible(lists, player)
	end,
	about_to_use = function(self, room, use)
		local source = use.from
		local n = 1
		for _, p in sgs.list(use.to) do
			room:setPlayerMark(p, "kenewgirlganglv_target", n)
			n = n + 1
		end
	end
}

kenewgirlganglvVS = sgs.CreateViewAsSkillV2{
	name = "kenewgirlganglv",
	n = 1,
	expand_pile = "#kenewgirlganglv",
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		return request:getPattern() == "@@kenewgirlganglv"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		return candidate:isAvailable(player) and player:getPile("#kenewgirlganglv"):contains(candidate:getEffectiveId())
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local slash = kenewgirlganglvCard:clone()
		slash:addSubcard(ids:at(0))
		return slash
	end,
	can_select_target = function(skill, request, selected, candidate)
		local ids = request:getSelectedCardIds()
		if ids:isEmpty() then return false end
		local card = sgs.Sanguosha:getCard(ids:at(0))
		local lists = sgs.PlayerList()
		for _, t in ipairs(selected) do lists:append(t) end
		local player = request:getInitiator()
		return card:targetFilter(lists, candidate, player) and not player:isProhibited(candidate, card, lists)
	end,
	targets_feasible = function(skill, request, selected)
		local ids = request:getSelectedCardIds()
		local lists = sgs.PlayerList()
		for _, t in ipairs(selected) do lists:append(t) end
		if ids:isEmpty() then return #selected == 0 end
		local card = sgs.Sanguosha:getCard(ids:at(0))
		return card:targetsFeasible(lists, request:getInitiator())
	end,
}

kenewgirlganglv = sgs.CreateTriggerSkillV2{
	name = "kenewgirlganglv",
	events = {sgs.CardsMoveOneTime},
	view_as_skill = kenewgirlganglvVS,
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if (event ~= sgs.CardsMoveOneTime) or not player:hasSkill(skill:objectName()) then return false end
		local move = data:toMoveOneTime()
		if move.from
		and (move.from:getMark("bankenewgirlganglv-Clear") == 0)
		and (move.from:objectName() == player:objectName())
		and (not move.from_places:contains(sgs.Player_PlaceJudge))
		and (
			(bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
			or ((move.to_place == sgs.Player_PlaceHand) and move.to and (move.to:objectName() ~= move.from:objectName()))
	        )then
			return skill:objectName(), player
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local cards = sgs.IntList()
		local names = {}
		for _, id in sgs.qlist(move.card_ids) do
			if not sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
				cards:append(id)
				table.insert(names,id)
			end
		end
		if cards:length() > 0 then
			player:setTag("kenewgirlganglvcards", sgs.QVariant(table.concat(names,"+")))
			room:notifyMoveToPile(player, cards, skill:objectName(), room:getCardPlace(cards:at(0)), true)
			local card = room:askForUseCard(player, "@@kenewgirlganglv", "kenewgirlganglv-use")
			room:notifyMoveToPile(player, cards, skill:objectName(), room:getCardPlace(cards:at(0)), false)
			player:removeTag("kenewgirlganglvcards")
			if card then
				room:setPlayerMark(player,"bankenewgirlganglv-Clear",1)
				room:setPlayerMark(player,"&kenewgirlganglv-Clear",1)
				card = sgs.Sanguosha:getCard(card:getSubcards():at(0))
				room:broadcastSkillInvoke(skill:objectName())
				--card:setSkillName(skill:objectName())
				if card:targetFixed() then
					local nonetarget = sgs.SPlayerList()
					room:useCard(sgs.CardUseStruct(card, player, nonetarget))
				else
					local targets = sgs.SPlayerList()
					for i = 1, 20 do
						for _, p in sgs.list(room:getAlivePlayers()) do
							if p:getMark("kenewgirlganglv_target") == i then
								targets:append(p)
								room:setPlayerMark(p, "kenewgirlganglv_target", 0)
							end
						end
					end
					if targets:length() > 0 then
						room:useCard(sgs.CardUseStruct(card, player, targets))
					end
				end
			else
				if player:askForSkillInvoke(skill:objectName(),ToData("kenewgirlganglv-ask")) then
					room:broadcastSkillInvoke(skill:objectName())
					room:setPlayerMark(player,"&kenewgirlganglv-Clear",1)
					room:setPlayerMark(player,"bankenewgirlganglv-Clear",1)
					player:drawCards(1,skill:objectName())
				end
			end
		else
			if player:askForSkillInvoke(skill:objectName(),ToData("kenewgirlganglv-ask")) then
				room:broadcastSkillInvoke(skill:objectName())
				room:setPlayerMark(player,"&kenewgirlganglv-Clear",1)
				room:setPlayerMark(player,"bankenewgirlganglv-Clear",1)
				player:drawCards(1,skill:objectName())
			end
		end
		return false
	end,
}
kenewgirlniangzhaoyun:addSkill(kenewgirlganglv)

sgs.LoadTranslationTable {
	["kenewgirlniangzhaoyun"] = "赵云[香]", 
	["&kenewgirlniangzhaoyun"] = "赵云",
	["#kenewgirlniangzhaoyun"] = "青龙解金锁",
	["designer:kenewgirlniangzhaoyun"] = "小珂酱",
	["cv:kenewgirlniangzhaoyun"] = "小沉香，小珂酱",
	["illustrator:kenewgirlniangzhaoyun"] = "-",

	["kenewgirltanyan"] = "探眼",
	["kenewgirltanyanex"] = "探眼",
	["kenewgirltanyan-ask"] = "你可以按顺序选择发动“探眼”的角色",
	[":kenewgirltanyan"] = "<font color='green'><b>出牌阶段开始时，</s></font>你可以依次选择至多四名角色并摸等量的牌，你本阶段对这些角色使用牌无距离限制，且你使用的前等量张牌只能分别依次指定这些角色为目标。",

	["kenewgirlganglv"] = "纲律",
	["#kenewgirlganglv"] = "纲律",
	["kenewgirlganglv-use"] = "纲律：你可以使用其中一张牌，或点击“取消”选择是否摸一张牌",
	[":kenewgirlganglv"] = "每个回合限一次，当你的牌被弃置或获得后，你可以使用其中一张非装备牌或摸一张牌。",

	["kenewgirlganglv:kenewgirlganglv-ask"] = "你可以发动“纲律”摸一张牌",

	["$kenewgirltanyan1"] = "探龙眼兮入蛟宫，仰天呼气兮成白虹。",
	["$kenewgirltanyan2"] = "一骑白龙游乱世，七尺长枪踏千山。",
	["$kenewgirltanyan3"] = "佯袭生门之东南，力溃景门于正西！",
	["$kenewgirltanyan4"] = "吾破此阵，有如观鱼赏花耳～",
	["$kenewgirlganglv1"] = "律军以严，则兵马略无所弃也。",
	["$kenewgirlganglv2"] = "贼寇未灭，何以家为？",
	["$kenewgirlganglv3"] = "云当立身，以断箕谷之敌！",

	["~kenewgirlniangzhaoyun"] = "北伐...北伐...",
}

kenewgirlxiahouyuan = sgs.General(extension, "kenewgirlxiahouyuan", "wei", 4,false)

kenewgirlbuguanCard = sgs.CreateSkillCard{
	name = "kenewgirlbuguanCard",
	target_fixed = true,
	--[[filter = function(self, targets, to_select, player)
		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets) do
			qtargets:append(p)
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_string = nil, self:getUserString()
			if user_string ~= "" then
				card = sgs.Sanguosha:cloneCard(user_string:split("+")[1])
				card:setSkillName("kenewgirlbuguan")
			end
			return card and card:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, card, qtargets)
		end
		local card = player:getTag("kenewgirlbuguan"):toCard()
		return card and card:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, card, qtargets)
	end,]]
	on_validate = function(self, cardUse)
		local player = cardUse.from
		local room = player:getRoom()
		local choices = {}
		table.insert(choices, "losehp") 
		if (player:getCardCount() >= 2) then table.insert(choices, "discard") end
		if player:hasEquipArea() then table.insert(choices, "throw") end
		table.insert(choices, "cancel") 
		local choice = room:askForChoice(player, "kenewgirlbuguan", table.concat(choices, "+"))
		if choice == "losehp" then
			room:setPlayerMark(player,"buguanlose-Clear",1)
			room:loseHp(sgs.HpLostStruct(player, 1, "kenewgirlbuguan", player))
		elseif choice == "discard" then
			room:setPlayerMark(player,"buguandis-Clear",1)
			room:askForDiscard(player, "kenewgirlbuguan", 2, 2, false, true, "kenewgirlbuguan-discard") 
		elseif choice == "throw" then
			room:setPlayerMark(player,"buguanthrow-Clear",1)
			player:throwEquipArea()
		end
		if not (choice == "cancel") then
			local buguanslash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			buguanslash:setSkillName("kenewgirlbuguan")
			room:setCardFlag(buguanslash,"kenewgirlbuguan")
			room:setCardFlag(buguanslash, "SlashIgnoreArmor")
			buguanslash:deleteLater()
			local ppp = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canSlash(p, buguanslash, false) then	
					ppp:append(p)
				end
			end
			if not ppp:isEmpty() then
				local eny = room:askForPlayerChosen(player, ppp, "kenewgirlbuguan", "kenewgirlbuguanslash", false, true)
				cardUse.to:append(eny)
			end
			return buguanslash
		end
	end
}
kenewgirlbuguanvs = sgs.CreateViewAsSkillV2{
	name = "kenewgirlbuguan",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_NoTarget,
	limit_scope = sgs.Skill_Limit_Phase,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		return kenewgirlbuguanCard:clone()
	end,
}

kenewgirlbuguan = sgs.CreateTriggerSkillV2{
	name = "kenewgirlbuguan",
	events = {sgs.DamageCaused,sgs.CardUsed},
	view_as_skill = kenewgirlbuguanvs,
	can_trigger = function(skill, event, room, player, data)
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if ((table.contains(use.card:getSkillNames(), "kenewgirlbuguan")) or use.card:hasFlag("kenewgirlbuguan")) and use.m_addHistory then
				return skill:objectName(), player
			end
		elseif (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			if damage.card and ((table.contains(damage.card:getSkillNames(), "kenewgirlbuguan")) or damage.card:hasFlag("kenewgirlbuguan"))
			and damage.from and damage.from:hasSkill(skill:objectName())
			and ((damage.from:getMark("buguanlose-Clear") > 0)
				or (damage.from:getMark("buguandis-Clear") > 0)
				or (damage.from:getMark("buguanthrow-Clear") > 0)) then
				return skill:objectName(), damage.from
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.DamageCaused then
			local damage = ctx.original_data:toDamage()
			local from = damage.from
			if from:getMark("buguanlose-Clear") > 0 then
				ctx.extra_data:setValue("lose")
				ctx.choice = room:askForChoice(from,skill:objectName(),"hlose+hdraw", ctx.original_data)
			elseif from:getMark("buguandis-Clear") > 0 then
				ctx.extra_data:setValue("dis")
				ctx.choice = room:askForChoice(from,skill:objectName(),"hdis+hrec", ctx.original_data)
			elseif from:getMark("buguanthrow-Clear") > 0 then
				ctx.extra_data:setValue("throw")
				ctx.choice = room:askForChoice(from,skill:objectName(),"hthrow+hpanding", ctx.original_data)
			else
				return false
			end
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if (event == sgs.CardUsed) then
			local use = ctx.original_data:toCardUse()
			if ((table.contains(use.card:getSkillNames(), "kenewgirlbuguan")) or use.card:hasFlag("kenewgirlbuguan")) and use.m_addHistory then
				room:addPlayerHistory(player, use.card:getClassName(),-1)
				--room:broadcastSkillInvoke(skill:objectName())
			end
		elseif (event == sgs.DamageCaused) then
			local damage = ctx.original_data:toDamage()
			local from = damage.from
			local to = damage.to
			local branch = ctx.extra_data:toString()
			if branch == "lose" then
				if ctx.choice == "hlose" then
					room:loseHp(sgs.HpLostStruct(to, 1, "kenewgirlbuguan", from))
				else
					room:setPlayerFlag(from, "kenewgirlbuguan_draw")
					room:askForPlayerChosen(from, room:getAllPlayers(), skill:objectName(), "kenewgirlbuguanm-ask", true, true):drawCards(2)
					room:setPlayerFlag(from, "-kenewgirlbuguan_draw")
				end
			elseif branch == "dis" then
				if ctx.choice == "hdis" then
					local num = math.min(2,to:getCardCount())
					room:askForDiscard(to, skill:objectName(), num, num, false, true, "kenewgirlbuguan-discard")
				else
					local recover = sgs.RecoverStruct()
					room:setPlayerFlag(from, "kenewgirlbuguan_recover")
					local xxx = room:askForPlayerChosen(from, room:getAllPlayers(), skill:objectName(), "kenewgirlbuguanh-ask", true, true)
					room:setPlayerFlag(from, "-kenewgirlbuguan_recover")
					recover.who = xxx
					recover.recover = 1
					room:recover(xxx, recover,true)
				end
			elseif branch == "throw" then
				if ctx.choice == "hthrow" then
					if to:hasEquipArea() then
						to:throwEquipArea()
					end
				else
					room:setPlayerFlag(from, "kenewgirlbuguan_judge")
					local one = room:askForPlayerChosen(from, room:getAllPlayers(), skill:objectName(), "kenewgirlbuguanj-ask", true, true)
					room:setPlayerFlag(from, "-kenewgirlbuguan_judge")
					if one:hasJudgeArea() then
						one:throwJudgeArea()
					end
				end
			end
		end
		return false
	end
}
kenewgirlxiahouyuan:addSkill(kenewgirlbuguan)

sgs.LoadTranslationTable {
	["kenewgirlxiahouyuan"] = "夏侯渊[香]", 
	["&kenewgirlxiahouyuan"] = "夏侯渊",
	["#kenewgirlxiahouyuan"] = "游隼",
	["designer:kenewgirlxiahouyuan"] = "小珂酱",
	["cv:kenewgirlxiahouyuan"] = "小沉香，小珂酱",
	["illustrator:kenewgirlxiahouyuan"] = "佚名，小珂酱",

	["kenewgirlbuguan"] = "步关",
	["kenewgirlbuguanslash"] = "步关：请选择【杀】的目标",
	["kenewgirlbuguan-discard"] = "步关：请选择弃置的牌",
	["kenewgirlbuguanj-ask"] = "请选择废除判定区的角色",
	["kenewgirlbuguanm-ask"] = "请选择摸牌的角色",
	["kenewgirlbuguanh-ask"] = "请选择回复体力的角色",
	["kenewgirlbuguan:losehp"] = "失去1点体力",
	["kenewgirlbuguan:discard"] = "弃置两张牌",
	["kenewgirlbuguan:throw"] = "废除装备区",
	["kenewgirlbuguan:hlose"] = "令其失去1点体力",
	["kenewgirlbuguan:hdraw"] = "令一名角色摸两张牌",
	["kenewgirlbuguan:hdis"] = "令其弃置两张牌",
	["kenewgirlbuguan:hrec"] = "令一名角色回复1点体力",
	["kenewgirlbuguan:hthrow"] = "令其废除装备区",
	["kenewgirlbuguan:hpanding"] = "令一名角色废除判定区",
	[":kenewgirlbuguan"] = "出牌阶段限一次，你可以：\
	弃置两张牌/失去1点体力/废除装备区（若有）\
	视为使用一张无距离和次数限制、不计入次数且无视防具的【杀】，此【杀】造成伤害时，你令目标角色执行相同项或令一名角色：\
	回复1点体力/摸两张牌/废除判定区。",



	["$kenewgirlbuguan1"] = "扬尘百丈之袤，决机两阵之间。",
	["$kenewgirlbuguan2"] = "虎步平关右，疾羽定峦丘。",
	["$kenewgirlbuguan3"] = "转战千里赴戎机，破敌一瞬拜征西！",
	["$kenewgirlbuguan4"] = "轻甲疾行，以解祁山之围!",

	["~kenewgirlxiahouyuan"] = "为帅亲战，失之鹿角，徒负功名也。",
}

kenewgirlzhangjiao = sgs.General(extension, "kenewgirlzhangjiao", "qun", 4,false)

kenewgirljuzhongCard = sgs.CreateSkillCard{
	name = "kenewgirljuzhongCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		local themin = to_select
		local yes = 1
		local yes2 = 1
		for _, min in sgs.qlist(to_select:getAliveSiblings()) do
			if (min:getHandcardNum() < to_select:getHandcardNum()) then
				yes = 0
				break
			end
		end
		for _, max in sgs.qlist(to_select:getAliveSiblings()) do
			if (max:getHandcardNum() > to_select:getHandcardNum()) then
				yes2 = 0
				break
			end
		end
		return ((yes == 1) and (player:getMark("usejuzhongmo-PlayClear") < 2))
		or ((yes2 == 1) and (player:getMark("usejuzhongqi-PlayClear") < 2))
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local mo = 1
		for _, min in sgs.qlist(target:getAliveSiblings()) do
			if (min:getHandcardNum() < target:getHandcardNum()) then
				mo = 0
				break
			end
		end
		local qi = 1
		for _, max in sgs.qlist(target:getAliveSiblings()) do
			if (max:getHandcardNum() > target:getHandcardNum()) then
				qi = 0
				break
			end
		end
		local choices = {}
		local dest = sgs.QVariant()
		dest:setValue(target)
		if (mo == 1) and (player:getMark("usejuzhongmo-PlayClear") < 2) then table.insert(choices, "minmo") end
		if (qi == 1) and (player:getMark("usejuzhongqi-PlayClear") < 2) then table.insert(choices, "maxqi") end
		local choice = room:askForChoice(player, "kenewgirljuzhong", table.concat(choices, "+"), dest)
		if choice == "minmo" then 
			room:addPlayerMark(player,"usejuzhongmo-PlayClear",1)
			target:drawCards(1)
		elseif choice == "maxqi" then 
			room:addPlayerMark(player,"usejuzhongqi-PlayClear",1)
			if target:canDiscard(target, "he") then
			    room:askForDiscard(target, "kenewgirljuzhong", 1, 1, false, true, "kenewgirljuzhong-discard")
			end
		end
	end
}

kenewgirljuzhongVS = sgs.CreateViewAsSkillV2{
	name = "kenewgirljuzhong",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
		and ((player:getMark("usejuzhongmo-PlayClear") < 2) or (player:getMark("usejuzhongqi-PlayClear") < 2))
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		return kenewgirljuzhongCard:clone()
	end,
	can_select_target = function(skill, request, selected, candidate)
		if #selected >= 1 then return false end
		local player = request:getInitiator()
		local yes = 1
		local yes2 = 1
		for _, min in sgs.qlist(candidate:getAliveSiblings()) do
			if (min:getHandcardNum() < candidate:getHandcardNum()) then
				yes = 0
				break
			end
		end
		for _, max in sgs.qlist(candidate:getAliveSiblings()) do
			if (max:getHandcardNum() > candidate:getHandcardNum()) then
				yes2 = 0
				break
			end
		end
		return ((yes == 1) and (player:getMark("usejuzhongmo-PlayClear") < 2))
		or ((yes2 == 1) and (player:getMark("usejuzhongqi-PlayClear") < 2))
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
}

kenewgirljuzhong = sgs.CreateTriggerSkillV2{
	name = "kenewgirljuzhong" ,
	view_as_skill = kenewgirljuzhongVS,
	events = {sgs.EventPhaseChanging} ,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseChanging then return false end
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			return skill:objectName(), player
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local themin = player
		for _, min in sgs.qlist(room:getAllPlayers()) do
			if (min:getHandcardNum() < themin:getHandcardNum()) then
				themin = min
			end
		end
		--检查唯一
		local yesmin = 1
		for _, p in sgs.qlist(room:getOtherPlayers(themin)) do
			if (p:getHandcardNum() <= themin:getHandcardNum()) then
				yesmin = 0
			end
		end
		local themax = player
		for _, max in sgs.qlist(room:getAllPlayers()) do
			if (max:getHandcardNum() > themax:getHandcardNum()) then
				themax = max
			end
		end
		--检查唯一
		local yesmax = 1
		for _, p in sgs.qlist(room:getOtherPlayers(themax)) do
			if (p:getHandcardNum() >= themax:getHandcardNum()) then
				yesmax = 0
			end
		end
		if (yesmin == 0 --[[and yesmax == 0]]) then
		    for _, zj in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				room:sendCompulsoryTriggerLog(zj,skill:objectName())
				--room:broadcastSkillInvoke(skill:objectName())
				local goon = 0
				local bfyy = 1
				for _, p in sgs.qlist(room:getOtherPlayers(zj)) do
					if (p:getHandcardNum() > zj:getHandcardNum()) then
						goon = 1
						break
					end
				end
				while (goon == 1) do
					if (bfyy == 1) then
					    room:broadcastSkillInvoke(skill:objectName())
					end
					bfyy = 0
					zj:drawCards(1)
					goon = 0
					for _, p in sgs.qlist(room:getOtherPlayers(zj)) do
						if (p:getHandcardNum() > zj:getHandcardNum()) then
							goon = 1
							break
						end
					end
				end
			end

		end
		return false
	end,
}
kenewgirlzhangjiao:addSkill(kenewgirljuzhong)

sgs.LoadTranslationTable {
	--新张角
	["kenewgirlzhangjiao"] = "张角[香]", 
	["&kenewgirlzhangjiao"] = "张角",
	["#kenewgirlzhangjiao"] = "泽众的导师",
	["designer:kenewgirlzhangjiao"] = "小珂酱",
	["cv:kenewgirlzhangjiao"] = "官方",
	["illustrator:kenewgirlzhangjiao"] = "官方",

	["kenewgirljuzhong"] = "聚众",
	["kenewgirljuzhong-discard"] = "聚众：请弃置一张牌",
	["kenewgirljuzhong:minmo"] = "令其摸一张牌",
	["kenewgirljuzhong:maxqi"] = "令其弃置一张牌",
	[":kenewgirljuzhong"] = "<font color='green'><b>出牌阶段各限两次，</b></font>你可以令手牌数最少/最多的一名角色摸一张牌/弃置一张牌；<font color='green'><b>每个回合结束时，</b></font>若没有手牌数唯一最少的角色，你将手牌摸至全场最多。",

	["$kenewgirljuzhong1"] = "汝等，当日积善言善行。",
	["$kenewgirljuzhong2"] = "黄天在上，福佑万民！",
	["$kenewgirljuzhong3"] = "太平天术，一统天下！",
	--["$kenewgirljuzhong4"] = "",


    ["~kenewgirlzhangjiao"] = "逆天而行，必遭天谴啊！",
}

kenewgirlzhoubuyi = sgs.General(extension, "kenewgirlzhoubuyi", "wei", 3,false)

kenewgirlshiqian = sgs.CreateTriggerSkillV2{
	name = "kenewgirlshiqian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	can_trigger = function(skill, event, room, player, data)
		if not player:hasSkill(skill:objectName()) then return false end
		if (event == sgs.EventAcquireSkill) or (event == sgs.EventLoseSkill) then
			return skill:objectName(), player
		elseif (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			if damage.from then
				return skill:objectName(), player
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.DamageInflicted then
			local damage = ctx.original_data:toDamage()
			local eny = damage.from
		    local to_data = sgs.QVariant()
			to_data:setValue(eny)
			local skill_list = {}
			for _,sk in sgs.qlist(eny:getVisibleSkillList()) do
				if (not table.contains(skill_list,sk:objectName())) and (not sk:isAttachedLordSkill()) and not player:hasSkill(sk) then
					table.insert(skill_list,sk:objectName())
				end
			end
			if (#skill_list <= 0) then return false end
			if not room:askForSkillInvoke(player, skill:objectName(), to_data) then return false end
			room:broadcastSkillInvoke(skill:objectName())
			local skill_qc = room:askForChoice(player, skill:objectName(), table.concat(skill_list,"+"), to_data)
			ctx.choice = skill_qc
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if (event == sgs.EventAcquireSkill) then
			room:sendCompulsoryTriggerLog(player,skill:objectName(),true,true)
			player:drawCards(1)
		elseif (event == sgs.EventLoseSkill) then
			room:sendCompulsoryTriggerLog(player,skill:objectName(),true,true)
			player:drawCards(1)
		elseif (event == sgs.DamageInflicted) then
			if (ctx.choice ~= "") then
				room:acquireOneTurnSkills(player, skill:objectName(), ctx.choice)
			end
		end
		return false
	end
}
kenewgirlzhoubuyi:addSkill(kenewgirlshiqian)

kenewgirlchenjiCard = sgs.CreateSkillCard{
	name = "kenewgirlchenjiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < 1
		--and (to_select:objectName() ~= sgs.Self:objectName()) 
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]

		--[[local fcard_ids = sgs.IntList()
		for _,c in sgs.qlist(player:getCards("h")) do
			fcard_ids:append(c:getEffectiveId())
		end
		if fcard_ids:length() < 10 then
			local cha = (10 - fcard_ids:length())
			if (cha > 0) then
				local pdcard_ids = room:getNCards(cha)
				for _, id in sgs.qlist(pdcard_ids) do
					fcard_ids:append(id)
				end
			end
		end

		local card_ids = sgs.IntList()
		while true do
			if fcard_ids:isEmpty() then break end
			if not fcard_ids:isEmpty() then
				if (fcard_ids:length() == 1) then
					for _,c in sgs.qlist(fcard_ids) do
						card_ids:append(c)
						fcard_ids:removeOne(c)
					end
				end
				if (fcard_ids:length() > 1) then
					local rr = math.random(0,fcard_ids:length()-1)
		            card_ids:append(fcard_ids:at(rr))
					fcard_ids:removeOne(fcard_ids:at(rr))
				end
			end
		end]]
		--统计技能数
		local getnum = 0
		local skill_list = {}
		for _,skill in sgs.qlist(player:getVisibleSkillList()) do
			if not skill:isAttachedLordSkill() then
				getnum = getnum + 1
			end
		end
		getnum = getnum - 1
		local card_ids = room:getNCards(5)
		room:fillAG(card_ids)
		local to_get = sgs.IntList()
		local to_throw = sgs.IntList()
		--按钮技能不算
		
		while (getnum > 0) do
			local card_id = room:askForAG(target, card_ids, true, "kenewgirlchenji")
			room:takeAG(player, card_id, false)
			card_ids:removeOne(card_id)
			to_get:append(card_id)
			getnum = getnum - 1
		end
		local willda = 1
		if not to_get:isEmpty() then
			for _, id in sgs.qlist(to_get) do
				if --[[(room:getCardPlace(id) == sgs.Player_DrawPile) and not]]  sgs.Sanguosha:getCard(id):isKindOf("TrickCard") then
					willda = 0
				end
				room:obtainCard(target,id)
			end
		end
		--处理牌堆的其他牌
		local todis = sgs.IntList()
		if not card_ids:isEmpty() then
			for _, id in sgs.qlist(card_ids) do
				if (room:getCardPlace(id) ~= sgs.Player_PlaceHand) then
				    todis:append(id)
				end
			end
		end
		--room:askForGuanxing(player,todis,1)
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:addSubcards(getCardList(todis))
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), "kenewgirlchenji","")
		--room:moveCardTo(dummy, nil, sgs.Player_DrawPile,reason)
		--room:moveCardsInToDrawpile(player,dummy)
		room:throwCard(dummy, reason, nil)
		dummy:deleteLater()
		room:clearAG()
		if willda == 1 then
			room:damage(sgs.DamageStruct(self:objectName(),target,player))
		else
			local log = sgs.LogMessage()
			log.type = "$kenewgirlchenjilog"
			log.from = player
			log.to:append(target)
			room:sendLog(log)
			room:doAnimate(1, target:objectName(), to:objectName())
			room:getThread():delay(500)
			local thedamage = sgs.DamageStruct("kenewgirlchenji", player, target)
			local _data = sgs.QVariant()
			_data:setValue(thedamage)
			room:getThread():trigger(sgs.Damage, room, player, _data)
			room:getThread():trigger(sgs.Damaged, room, target, _data)
		end
	end
}


kenewgirlchenji = sgs.CreateViewAsSkillV2{
	name = "kenewgirlchenji",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_SelectTargets,
	limit_scope = sgs.Skill_Limit_Phase,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		return kenewgirlchenjiCard:clone()
	end,
	can_select_target = function(skill, request, selected, candidate)
		return #selected < 1
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
}
kenewgirlzhoubuyi:addSkill(kenewgirlchenji)

sgs.LoadTranslationTable {
		--新周不疑
	["kenewgirlzhoubuyi"] = "周不疑[香]", 
	["&kenewgirlzhoubuyi"] = "周不疑",
	["#kenewgirlzhoubuyi"] = "雪智的少女",
	["designer:kenewgirlzhoubuyi"] = "小珂酱",
	["cv:kenewgirlzhoubuyi"] = "官方",
	["illustrator:kenewgirlzhoubuyi"] = "-",

	["kenewgirlshiqian"] = "师堑",
	[":kenewgirlshiqian"] = "当你受到伤害时，你可以获得伤害来源一个你未拥有的技能直到你回合结束；当你获得或失去技能时，你摸一张牌。",

	["kenewgirlchenji"] = "陈计",
	[":kenewgirlchenji"] = "出牌阶段限一次，你可以展示牌堆顶的五张牌并令一名角色获得其中X张（X为你的技能数-1），然后弃置其余牌，若其没有获得锦囊牌，其对你造成1点伤害，否则你视为对其造成过1点伤害。",

	["$kenewgirlshiqian1"] = "未及弱冠，难足行千里，唯以文代旅。",
	["$kenewgirlshiqian2"] = "著论四卷，彰建安之文风，颂明公之峥瑞。",
	["$kenewgirlchenji1"] = "不疑得仓舒为知己，其如伯牙之遇子期也。",
	["$kenewgirlchenji2"] = "仓舒以舟称象，我以计破城，孰优乎？",

	["$kenewgirlchenjilog"] = "%from 视为对 %to 造成过 1 点伤害",

    ["~kenewgirlzhoubuyi"] = "仓舒慢行，不疑来也。",
}




kenewgirlxuchu = sgs.General(extension, "kenewgirlxuchu", "wei", 4,false)

kenewgirlchandou = sgs.CreateTriggerSkillV2{
    name = "kenewgirlchandou",
	frequency = sgs.Skill_Compulsory,
    events = {sgs.CardOffset},
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.CardOffset then return false end
		local effect = data:toCardEffect()
		if effect.card:isKindOf("Slash")
		and ((effect.from and effect.from:hasSkill(skill:objectName()))
			or (effect.to and effect.to:hasSkill(skill:objectName()))) then
			return skill:objectName(), player
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local effect = ctx.original_data:toCardEffect()
		if not effect.card:isKindOf("Slash") then return false end
		if effect.from and effect.from:hasSkill(skill:objectName()) then
			ctx.choice = room:askForChoice(player,skill:objectName(),"dis+juedou+beishui", ctx.original_data)
		end
		if effect.to and effect.to:hasSkill(skill:objectName()) then
			ctx.extra_data:setValue(room:askForChoice(effect.to,skill:objectName(),"dis+juedou+beishui", ctx.original_data))
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
        if (event == sgs.CardOffset) then
            local effect = ctx.original_data:toCardEffect()
            if effect.card:isKindOf("Slash") then
				if (player:objectName() == effect.from:objectName()) then
					if (ctx.choice == "dis") then
						room:askForDiscard(player, skill:objectName(), math.min(2,player:getHandcardNum()), math.min(2,player:getHandcardNum()), false, false, "kenewgirlchandoudis")
					elseif (ctx.choice == "juedou") then
						--local card_id = room:askForExchange(player, skill:objectName(), 1, 1, true, "kenewgirlchandoujuedou"):getSubcards():first()
						--local juedoucard = sgs.Sanguosha:getCard(card_id)
						local juedou = sgs.Sanguosha:cloneCard("duel",sgs.Card_NoSuit, 0)
						--juedou:addSubcard(juedoucard)
						juedou:setSkillName("_"..skill:objectName())
						local card_use = sgs.CardUseStruct()
						card_use.from = player
						card_use.to:append(effect.to)
						card_use.card = juedou
						room:useCard(card_use, true)
						juedou:deleteLater()
					else
						--room:slashResult(effect,nil)
						room:askForDiscard(player, skill:objectName(), math.min(2,player:getHandcardNum()), math.min(2,player:getHandcardNum()), false, false, "kenewgirlchandoudis")
						--local card_id = room:askForExchange(player, skill:objectName(), 1, 1, true, "kenewgirlchandoujuedou"):getSubcards():first()
						--local juedoucard = sgs.Sanguosha:getCard(card_id)
						local juedou = sgs.Sanguosha:cloneCard("duel",sgs.Card_NoSuit, 0)
						--juedou:addSubcard(juedoucard)
						juedou:setSkillName("_"..skill:objectName())
						local card_use = sgs.CardUseStruct()
						card_use.from = player
						card_use.to:append(effect.to)
						card_use.card = juedou
						room:useCard(card_use, true)
						juedou:deleteLater()
						room:getThread():delay(400)
						return true
					end
				end
				if (player:objectName() == effect.to:objectName()) or (effect.to and effect.to:hasSkill(skill:objectName())) then
					local to_choice = ctx.extra_data:toString()
					if (to_choice == "dis") then
						effect.to:drawCards(2,skill:objectName())
					elseif (to_choice == "juedou") then
						--local card_id = room:askForExchange(effect.to, skill:objectName(), 1, 1, true, "kenewgirlchandoujuedou"):getSubcards():first()
						--local juedoucard = sgs.Sanguosha:getCard(card_id)
						local juedou = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
						--juedou:addSubcard(juedoucard)
						juedou:setSkillName("_"..skill:objectName())
						local card_use = sgs.CardUseStruct()
						card_use.from = effect.to
						card_use.to:append(effect.from)
						card_use.card = juedou
						room:useCard(card_use, true)
						juedou:deleteLater()
					else
						--room:slashResult(effect,nil)
						effect.to:drawCards(2,skill:objectName())
						--local card_id = room:askForExchange(effect.to, skill:objectName(), 1, 1, true, "kenewgirlchandoujuedou"):getSubcards():first()
						--local juedoucard = sgs.Sanguosha:getCard(card_id)
						local juedou = sgs.Sanguosha:cloneCard("duel",sgs.Card_NoSuit, 0)
						--juedou:addSubcard(juedoucard)
						juedou:setSkillName("_"..skill:objectName())
						local card_use = sgs.CardUseStruct()
						card_use.from = effect.to
						card_use.to:append(effect.from)
						card_use.card = juedou
						room:useCard(card_use, true)
						juedou:deleteLater()
						room:getThread():delay(400)
						return true
					end
				end
			end
        end
		return false
    end,
}
kenewgirlxuchu:addSkill(kenewgirlchandou)

sgs.LoadTranslationTable {
		--新许褚
	["kenewgirlxuchu"] = "许褚[香]", 
	["&kenewgirlxuchu"] = "许褚",
	["#kenewgirlxuchu"] = "虎侯安在？",
	["designer:kenewgirlxuchu"] = "小珂酱",
	["cv:kenewgirlxuchu"] = "",
	["illustrator:kenewgirlxuchu"] = "-",
	

	["kenewgirlchandou"] = "缠斗",
	["kenewgirlchandoudis"] = "请选择弃置的牌",
	["kenewgirlchandou:dis"] = "摸两张牌（抵消杀时）/弃置两张手牌（杀被抵消时）",
	["kenewgirlchandou:juedou"] = "视为对对方使用一张【决斗】",
	["kenewgirlchandou:beishui"] = "依次执行前两项，然后此【杀】依然造成伤害",
	[":kenewgirlchandou"] = "锁定技，当你抵消【杀】/使用的【杀】被抵消时，你选择一项：\
	1.摸两张牌 / 弃置两张手牌；\
	2.视为对对方使用一张【决斗】；\
	背水：此【杀】依然造成伤害。",

	["$kenewgirlchandou1"] = "",
	["$kenewgirlchandou2"] = "",
	["$kenewgirlchandou3"] = "",
	["$kenewgirlchandou4"] = "",


    ["~kenewgirlxuchu"] = "",
}

kenewgirlsunce = sgs.General(extension, "kenewgirlsunce", "wu", 3, false)

kenewgirljiang = sgs.CreateTriggerSkillV2{
	name = "kenewgirljiang",
	events = {sgs.TargetConfirmed, sgs.TargetSpecified},
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if not player:hasSkill(skill:objectName()) then return false end
		local use = data:toCardUse()
		if ((event == sgs.TargetSpecified) or (event == sgs.TargetConfirmed and use.to:contains(player)))
		and ((use.card:isDamageCard() and use.card:isNDTrick()) or (use.card:isKindOf("Slash")))
		and (player:getMark("&banjiang-Clear") == 0) then
			return skill:objectName(), player
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_pay = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		player:drawCardsList(1,skill:objectName())
		if not ((use.card:isRed()) or (use.card:isKindOf("Duel"))) then
			room:setPlayerMark(player,"&banjiang-Clear",1)
		end
		return false
	end
}
kenewgirlsunce:addSkill(kenewgirljiang)

kenewgirlscshixieCard = sgs.CreateSkillCard{
	name = "kenewgirlscshixieCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return (#targets < 1) and (to_select:objectName() ~= player:objectName())
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:removePlayerMark(player,"@kenewgirlscshixie")
		--room:setPlayerMark(target,"&kenewgirlscshixie"..player:getGeneralName(),1)
		room:setPlayerMark(player,"&kenewgirlscshixie".."+"..target:getGeneralName(),1)
		local to_dis = sgs.IntList()
		for _,h in sgs.qlist(target:getCards("he")) do
			if (h:getSuit() ~= sgs.Card_Heart)
			and player:canDiscard(target,h:getEffectiveId()) then 
				to_dis:append(h:getEffectiveId())
			end
		end
		if not to_dis:isEmpty() then
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			dummy:addSubcards(getCardList(to_dis))
			--local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, source:objectName(), self:objectName(),"")
			room:throwCard(dummy, target, player)
			dummy:deleteLater()
		end
		room:setFixedDistance(player,target, 1)
	end
}

kenewgirlscshixieVS = sgs.CreateViewAsSkillV2{
    name = "kenewgirlscshixie",
    n = 0,
    target_mode = sgs.ViewAsSkillV2_SelectTargets,
	limit_mark = "@kenewgirlscshixie",
	can_activate = function(skill, request)
		local player = request:getInitiator()
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
		and (player:getMark("@kenewgirlscshixie") > 0)
    end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
    create_card = function(skill, request)
        return kenewgirlscshixieCard:clone()
    end,
	can_select_target = function(skill, request, selected, candidate)
		local player = request:getInitiator()
		return (#selected < 1) and (candidate:objectName() ~= player:objectName())
	end,
	targets_feasible = function(skill, request, selected)
		return #selected == 1
	end,
}

kenewgirlscshixie = sgs.CreateTriggerSkillV2{
	name = "kenewgirlscshixie",
	view_as_skill = kenewgirlscshixieVS,
	events = {sgs.EventPhaseChanging},
	frequency = sgs.Skill_Limited,
	limit_mark = "@kenewgirlscshixie",
	can_trigger = function(skill, event, room, player, data)
		if not player:hasSkill(skill:objectName()) then return false end
		local change = data:toPhaseChange()
		if (change.to ~= sgs.Player_NotActive) then	return false end
		return skill:objectName(), player
	end,
	on_effect = function(skill, event, room, player, ctx)
		for _, yj in sgs.qlist(room:getAllPlayers(true)) do
			if (player:getMark("&kenewgirlscshixie+"..yj:getGeneralName()) > 0)
			and yj:isDead() then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("_kenewgirlscshixie")
				local card_use = sgs.CardUseStruct()
				card_use.from = yj
				card_use.to:append(player)
				card_use.card = slash
				room:useCard(card_use, false)
				slash:deleteLater()
			end
		end
		return false
	end
}
kenewgirlsunce:addSkill(kenewgirlscshixie)

sgs.LoadTranslationTable {
		--新孙策
	["kenewgirlsunce"] = "孙策[香]", 
	["&kenewgirlsunce"] = "孙策",
	["#kenewgirlsunce"] = "凯歌彻江东",
	["designer:kenewgirlsunce"] = "小珂酱",
	["cv:kenewgirlsunce"] = "",
	["illustrator:kenewgirlsunce"] = "-",

	["kenewgirljiang"] = "姬昂",
	["banjiang"] = "姬昂失效",
	[":kenewgirljiang"] = "当你使用或成为【杀】或伤害类普通锦囊牌的目标后，你可以摸一张牌，若此伤害类牌不为红色或【决斗】，本回合“姬昂”失效。",

	["kenewgirlscshixie"] = "噬邪",
	[":kenewgirlscshixie"] = "限定技，出牌阶段，你可以令一名其他角色弃置所有非♥牌且你本局游戏与其距离视为1，若如此做，此后你的回合结束时，若该角色已死亡，其视为对你使用一张【杀】。",

	["$kenewgirljiang1"] = "",
	["$kenewgirljiang2"] = "",
	["$kenewgirlscshixie1"] = "",
	["$kenewgirlscshixie2"] = "",

    ["~kenewgirlsunce"] = "",
}





sgs.Sanguosha:addSkills(skills)
sgs.LoadTranslationTable{
    ["kearwangushengxiang"] = "新创包·万古生香",

}
return {extension}

