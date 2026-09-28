module("extensions.animic",package.seeall)
extension=sgs.Package("animic")

sgs.LoadTranslationTable{
	["animic"] = "动漫包",
}

zzy_marisa=sgs.General(extension,"zzy_marisa","magic",4,false,false)

modao = sgs.CreateTriggerSkillV2{
	name = "modao" ,
	events = {sgs.EventPhaseStart,sgs.Damage, sgs.EventPhaseChanging} ,
	on_record = function(skill, event, room, player, ctx)
		if not ctx.owner or not player or not player:isAlive() or ctx.owner:objectName() ~= player:objectName() then return end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:setPlayerMark(player, "modao",0)
			end
		elseif event == sgs.Damage then
			local damage = ctx.original_data:toDamage()
			if damage.to then
				room:setPlayerMark(player, "modao",player:getMark("modao")+damage.damage)
				room:setPlayerMark(player, "&modao+:+damage-Clear", player:getMark("modao"))
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				return "modao"
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("modao") > 0 then
				return "modao"
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			if not room:askForSkillInvoke(player,"modao",ctx.original_data) then return false end
			ctx.choice = room:askForChoice(player, "modao", "1+2+3+4+5+6+7+8+9")
			return true
		end
		return event == sgs.EventPhaseChanging
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local choice = tonumber(ctx.choice)
			player:setTag("modao", sgs.QVariant(choice))
			local players = sgs.SPlayerList()
			players:append(player)
			room:addPlayerMark(player, "&modao+:+"..choice.."-Clear", 1, players)
		elseif event == sgs.EventPhaseChanging then
			local num = player:getTag("modao"):toInt()
			if num > 0 then
				if player:getMark("modao") >= num then
					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if not p:isKongcheng() then
							targets:append(p)
						end
					end
					if targets:isEmpty() then return false end
					local target = room:askForPlayerChosen(player, targets, "modao")
					local discards = sgs.IntList()
					local to_obtain = dummyCard()
					for i = 1, num do--进行多次执行
						local id = room:askForCardChosen(player, target, "h", "modao",
							false,--选择卡牌时手牌不可见
							sgs.Card_MethodNone,--设置为弃置类型
							discards,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
							false)--只有执行过一次选择才可取消
						if id < 0 then break end--如果卡牌id无效就结束多次执行
						discards:append(id)--将选择的id添加到虚拟卡的子卡表
						to_obtain:addSubcard(sgs.Sanguosha:getCard(id))
					end	
					player:obtainCard(to_obtain)
				end
			end
			room:setPlayerMark(player, "modao",0)
			player:setTag("modao", sgs.QVariant(0))
		end
		return false
	end,
}

zzy_marisa:addSkill(modao)
sgs.LoadTranslationTable{
	["#zzy_marisa"] = "普通的魔法使",
	["zzy_marisa"] = "雾雨魔理沙",
	["designer:zzy_marisa"] = "zengzouyu",
	["cv:zzy_marisa"] = "",
	["illustrator:zzy_marisa"] = "豆",
	["modao"] = "魔盗",
	[":modao"] = "准备阶段你可以声明一非零数值X，然后若此回合内你造成的伤害不小于X，此回合结束时你获得一名其他角色的X张手牌。",
}


jiela=sgs.General(extension,"jiela","magic",3,false,false)

huayuanCard = sgs.CreateSkillCard{
	name = "huayuanCard", 
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		return #targets < 2 and not to_select:isChained()
	end,
	on_effect = function(self, effect) 
		if effect.to:isNude() then return end
		local room = effect.to:getRoom()
		room:setPlayerProperty(effect.to, "chained", sgs.QVariant(true))
	end,
}

huayuanVS = sgs.CreateViewAsSkillV2{
	name = "huayuan",
	n = 0,
	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@@huayuan"
		end
		return false
	end,
	create_card = function(skill, request)
		return huayuanCard:clone()
	end,
}

huayuan = sgs.CreateTriggerSkillV2{
	name = "huayuan" ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = huayuanVS,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			return "huayuan"
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForUseCard(player, "@@huayuan", "@huayuan") ~= nil
	end,
	on_effect = function(skill, event, room, player, ctx)
		return false
	end,
}

cuisheng = sgs.CreateTriggerSkillV2{
	name = "cuisheng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:isChained() then
			local skills, who = {}, {}
			for _,p in sgs.qlist(room:findPlayersBySkillName("cuisheng")) do
				table.insert(skills, "cuisheng")
				table.insert(who, p:objectName())
			end
			if #skills > 0 then
				return table.concat(skills, "|"), table.concat(who, "|")
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local n = 0
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:isChained() then
				n = n + 1
			end
		end
		if ctx.invoker:getHandcardNum() >= n then return false end
		return room:askForSkillInvoke(player,"cuisheng",ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:drawCards(ctx.invoker, 1, "cuisheng")
		return false
	end,
}

jiaosha = sgs.CreateTriggerSkillV2{
	name = "jiaosha" ,
	events = {sgs.EventPhaseChanging,sgs.EventPhaseStart} ,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:isChained() then
					return "jiaosha"
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_NotActive then return false end
			if room:getTag("jiaoshaTarget") then
				return "jiaosha"
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:isChained() then
					targets:append(p)
				end
			end
			if targets:isEmpty() then return false end
			local to = room:askForPlayerChosen(player, targets, "jiaosha", "jiaosha-invoke", true, true)
			if not to then return false end
			ctx.targets:append(to)
			return true
		end
		return event == sgs.EventPhaseStart
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		if event ~= sgs.EventPhaseChanging or not target then return false end
		room:setPlayerProperty(target, "chained", sgs.QVariant(false))
		room:damage(sgs.DamageStruct("jiaosha", player, target))
		local playerdata = sgs.QVariant()
		playerdata:setValue(target)
		room:setTag("jiaoshaTarget", playerdata)
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart and room:getTag("jiaoshaTarget") then
			local target = room:getTag("jiaoshaTarget"):toPlayer()
			room:removeTag("jiaoshaTarget")
			if target and target:isAlive() then
				target:gainAnExtraTurn()
			end
		end
		return false
	end,
}

jiela:addSkill(huayuan)
jiela:addSkill(cuisheng)
jiela:addSkill(jiaosha)
sgs.LoadTranslationTable{
	["#jiela"] = "荆棘之兴",
	["jiela"] = "婕拉",
	["designer:jiela"] = "zengzouyu",
	["cv:jiela"] = "",
	["illustrator:jiela"] = "_FMM-CAT_",
	["huayuan"] = "荆棘花园",
	[":huayuan"] = "准备阶段，你可以横置一至两名角色的武将牌。",
	["cuisheng"] = "万物催生",
	[":cuisheng"] = "一名武将牌横置的角色的结束阶段，若其手牌数小于场上武将牌横置角色数，你可以令其摸一张牌。",
	["jiaosha"] = "绞杀藤蔓",
	[":jiaosha"] = "回合结束时，你可以对一名武将牌横置的角色造成一点伤害并重置其武将牌，然后其进行一个额外的回合。",
}

mutoyugi=sgs.General(extension,"mutoyugi","magic",3,true,false)

huanglue = sgs.CreateTriggerSkillV2{
	name = "huanglue" ,
	events = {sgs.CardUsed} ,
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if not use.from or not use.card or use.card:getTypeId() == 0 then return false end
		if use.card:getNumber() >= 13 then return false end
		local skills, who = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName("huanglue")) do
			table.insert(skills, "huanglue")
			table.insert(who, p:objectName())
		end
		if #skills > 0 then
			return table.concat(skills, "|"), table.concat(who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		if not use.from or not use.card or use.card:getTypeId() == 0 then return false end
		local point = use.card:getNumber()
		if point >= 13 then return false end
		if table.contains(use.nullified_list, "_ALL_TARGETS") then return false end
		local point_str = ".."
		if point == 12 then
			point_str = ".|.|13|.|."
		else
			point_str = ".|.|"..tostring(point+1).."~13|.|."
		end
		return room:askForCard(player, point_str, "@huanglue", ctx.original_data, "huanglue") ~= nil
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		local nullified_list = use.nullified_list
		table.insert(nullified_list, "_ALL_TARGETS")
		use.nullified_list = nullified_list
		data:setValue(use)
		local ids = sgs.IntList()
		if use.card:isVirtualCard() then
			ids = use.card:getSubcards()
		else
			ids:append(use.card:getEffectiveId())
		end
		if ids:length() > 0 then
			room:throwCard(use.card, room:getCardOwner(use.card:getEffectiveId()), player)
		end
		if not use.whocard then
			room:setTag("SkipGameRule",sgs.QVariant(tonumber(event)))
		end
		return false
	end,
}

luafenwei = sgs.CreateTriggerSkillV2{
	name = "luafenwei" ,
	events = {sgs.TargetConfirmed},
	frequency = sgs.Skill_Frequent, 
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_NotActive then return false end
		local use = data:toCardUse()
		if event == sgs.TargetConfirmed and use.to:contains(player) then
			if not use.card or use.card:getTypeId() == 0 or not player:isKongcheng() then return false end
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getEquips():length() + p:getJudgingArea():length() > 0 then
					return "luafenwei"
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getEquips():length() + p:getJudgingArea():length() > 0 then
				targets:append(p)
			end
		end
		if targets:isEmpty() then return false end
		local to = room:askForPlayerChosen(player, targets, "luafenwei", "luafenwei-invoke", true, true)
		if not to then return false end
		ctx.targets:append(to)
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		if not target then return false end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
		local card_id = room:askForCardChosen(player, target, "ej", "luafenwei")
		room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
		return false
	end,
}

mutoyugi:addSkill(huanglue)
mutoyugi:addSkill(luafenwei)
sgs.LoadTranslationTable{
	["#mutoyugi"] = "法老王",
	["mutoyugi"] = "阿图姆",
	["designer:mutoyugi"] = "zengzouyu",
	["cv:mutoyugi"] = "",
	["illustrator:mutoyugi"] = "月色火焰",
	["huanglue"] = "皇略",
	[":huanglue"] = "当有角色使用牌时，你可以弃置一张点数更大的牌，将此牌的使用改为弃置。",
	["luafenwei"] = "奋危",
	[":luafenwei"] = "你于回合外成为牌的目标时，若你没有手牌，你可以获得场上的一张牌。",
}

suika=sgs.General(extension,"suika","magic",4,false,false)

guihaoVS = sgs.CreateViewAsSkillV2{
	name = "guihao",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if player:getMark("guihao") <= 0 then return false end
			local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
			newanal:deleteLater()
			if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then return false end
			return true
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return string.find(request:getPattern() or "", "analeptic") ~= nil and player:getMark("guihao") > 0
		end
		return false
	end,
	can_select_card = function(skill, request, card)
		if not card or not request:getSelectedCardIds():isEmpty() then return false end
		return not card:isEquipped() and card:isBlack()
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:isEmpty() then return nil end
		local acard = sgs.Sanguosha:getCard(ids:first())
		if not acard then return nil end
		local analeptic = sgs.Sanguosha:cloneCard("analeptic", acard:getSuit(), acard:getNumber())
		analeptic:setSkillName("guihao")
		analeptic:addSubcard(acard)
		return analeptic
	end,
}

guihao = sgs.CreateTriggerSkillV2{
	name = "guihao",
	events = {sgs.EventPhaseStart,sgs.CardUsed},
	view_as_skill = guihaoVS,
	on_record = function(skill, event, room, player, ctx)
		if not ctx.owner or not player or not player:isAlive() or ctx.owner:objectName() ~= player:objectName() then return end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:setPlayerMark(player, "guihao",0)
				room:setPlayerMark(player, "&guihao",0)
			end
		elseif event == sgs.CardUsed then
			local use = ctx.original_data:toCardUse()
			if use.card and use.card:isKindOf("Analeptic") and use.m_addHistory then
				room:addPlayerHistory(player, use.card:getClassName(),-1)
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			return "guihao"
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player,"guihao",ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:loseHp(player, 1, true, player, "guihao")
		room:drawCards(player, player:getLostHp(), "guihao")
		room:addPlayerMark(player, "guihao")
		room:addPlayerMark(player, "&guihao")
		return false
	end,
}
suika:addSkill(guihao)
sgs.LoadTranslationTable{
	["#suika"] = "奔放不羁的鬼豪",
	["suika"] = "伊吹萃香",
	["designer:suika"] = "zengzouyu",
	["cv:suika"] = "",
	["illustrator:suika"] = "螺/mconch",
	["guihao"] = "鬼豪",
	[":guihao"] = "准备阶段你可以流失一点体力并摸X张牌，然后直到你的下回合开始前，你可以将你的黑色手牌当酒使用且你使用酒不计入次数限制(X为你已损失体力值)。",
}

nakamura=sgs.General(extension,"nakamura","real",3,false,false)

caiduanMaxCards = sgs.CreateMaxCardsSkillV2{
	name = "#caiduanMaxCards",
	correct_func = function(skill, ctx)
		local holder = ctx:getHolder()
		if holder then
			return -holder:getMark("caiduan")
		end
		return false
	end
}

caiduanProhibit = sgs.CreateProhibitSkill{
	name = "#caiduanProhibit" ,
	is_prohibited = function(self, from, to, card)
		for _, p in sgs.qlist(from:getAliveSiblings()) do
			if p:hasSkill("caiduan") and from:hasFlag("caiduan"..p:objectName()) and card:targetFixed() then
				return from:objectName() == to:objectName()
			end
		end
		return false
	end
}

caiduanCard = sgs.CreateSkillCard{
	name = "caiduanCard",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		local card_id = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(card_id)
		if card and card:targetFixed() then
			return false
		end
		--if sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, card) == 0 then return false end
		local nakamura = nil
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if player:hasFlag("caiduan"..p:objectName()) then
				nakamura = p
				break
			end
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if #targets == 0 and to_select:objectName() == nakamura:objectName()
			or #targets > 0 and (table.contains(targets,nakamura) or to_select:objectName() == nakamura:objectName()) then
			return card and card:targetFilter(qtargets, to_select, player) 
			and not player:isProhibited(to_select, card, qtargets)
		end
	end,
	feasible = function(self, targets, player)
		local card_id = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(card_id)
		local nakamura = nil
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if player:hasFlag("caiduan"..p:objectName()) then
				nakamura = p
				break
			end
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, player) and (card:targetFixed() or table.contains(targets,nakamura))
	end,	
	on_validate = function(self, card_use)
		local card_id = self:getSubcards():first()
		return sgs.Sanguosha:getCard(card_id)		
	end,
}

caiduanVS = sgs.CreateViewAsSkillV2{
	name = "caiduan",
	n = 1,
	expand_pile = "wooden_ox",
	will_throw_selected_cards = false,
	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@@caiduan"
		end
		return false
	end,
	can_select_card = function(skill, request, card)
		if not card or not request:getSelectedCardIds():isEmpty() then return false end
		local player = request:getInitiator()
		if not player then return false end
		local nakamura = nil
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if player:hasFlag("caiduan"..p:objectName()) then
				nakamura = p
				break
			end
		end
		if nakamura and card:isAvailable(player) then
			return card:targetFilter(sgs.PlayerList(), nakamura, player)
		end
		return false
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:isEmpty() then return nil end
		local usecard = caiduanCard:clone()
		for _,id in sgs.qlist(ids) do
			usecard:addSubcard(id)
		end
		return usecard
	end,
}

caiduan = sgs.CreateTriggerSkillV2{
	name = "caiduan" ,
	events = {sgs.TurnStart,sgs.EventPhaseStart,sgs.ChoiceMade,sgs.EventPhaseChanging} ,
	view_as_skill = caiduanVS,
	on_record = function(skill, event, room, player, ctx)
		if event == sgs.TurnStart then
			room:setPlayerMark(player,"caiduan",0)
		elseif event == sgs.ChoiceMade then
			local use = ctx.original_data:toCardUse()
			local current = room:getCurrent()
			if use and current then
				local clear = {}
				for _,flag in ipairs(current:getFlagList()) do--
					if string.find(flag,"caiduan") then
						table.insert(clear, flag)
					end
				end
				for _,flag in ipairs(clear) do
					if current:hasFlag(flag) then
						room:setPlayerFlag(current, "-"..flag)
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = ctx.original_data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return end
			if player:getMark("caiduan") > 0 then
				room:setPlayerMark(player,"caiduan",0)
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local skills, who = {}, {}
			for _,p in sgs.qlist(room:findPlayersBySkillName("caiduan")) do
				if p:objectName() ~= player:objectName() then
					table.insert(skills, "caiduan")
					table.insert(who, p:objectName())
				end
			end
			if #skills > 0 then
				return table.concat(skills, "|"), table.concat(who, "|")
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			return room:askForSkillInvoke(player,"caiduan",ctx.original_data)
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local target = ctx.invoker
			if not target then return false end
			room:setPlayerFlag(target, "caiduan"..player:objectName())
			local card = room:askForUseCard(target, "@@caiduan", "@caiduan")
			if target:hasFlag("caiduan"..player:objectName()) then
				room:setPlayerFlag(target, "-caiduan"..player:objectName())
			end
			if not card then
				room:addPlayerMark(target,"caiduan")
				room:addPlayerMark(target,"&caiduan-Clear")
			end
		end
		return false
	end,
}

shenni = sgs.CreateTriggerSkillV2{
	name = "shenni",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.BeforeCardsMove},
	can_trigger = function(skill, event, room, player, data)
		local move = data:toMoveOneTime()
		if not move.from or move.from:objectName() ~= player:objectName() then return false end
		local current = room:getCurrent()
		if not current then return false end
		local pending = "shenni"..player:objectName()
		local punished = pending.."shenni"
		if current:hasFlag(pending) and not current:hasFlag(punished) then
			if (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) 
			and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
				return "shenni"
			end
		else
			if move.to_place == sgs.Player_DiscardPile and not current:hasFlag(pending) then
				return "shenni"
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local current = room:getCurrent()
		if not current then return false end
		local pending = "shenni"..player:objectName()
		local punished = pending.."shenni"
		if current:hasFlag(pending) and not current:hasFlag(punished) then
			return (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) 
			and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)))
		end
		if move.to_place ~= sgs.Player_DiscardPile or current:hasFlag(pending) then return false end
		return room:askForSkillInvoke(player,"shenni",ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local move = data:toMoveOneTime()
		local current = room:getCurrent()
		if not current then return false end
		local pending = "shenni"..player:objectName()
		local punished = pending.."shenni"
		if current:hasFlag(pending) and not current:hasFlag(punished) then
			if (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) 
			and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
				room:setPlayerFlag(current, punished)
				room:setPlayerMark(player, "&shenni-Clear", 0)
				room:loseHp(player,1, true, player, "shenni")
			end
		else
			if move.to_place == sgs.Player_DiscardPile then
				room:addPlayerMark(player, "&shenni-Clear")
				local moveA = sgs.CardsMoveStruct()
				moveA.card_ids = move.card_ids
				moveA.to = player
				moveA.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(moveA, false)
				move.card_ids = sgs.IntList()
				data:setValue(move)
				room:setPlayerFlag(current, pending)
			end
		end
		return false
	end,
}
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#caiduanMaxCards") then skills:append(caiduanMaxCards) end
if not sgs.Sanguosha:getSkill("#caiduanProhibit") then skills:append(caiduanProhibit) end
sgs.Sanguosha:addSkills(skills)
nakamura:addSkill(caiduan)
extension:insertRelatedSkills("caiduan", "#caiduanMaxCards")
nakamura:addSkill(shenni)
sgs.LoadTranslationTable{
	["#nakamura"] = "逆天而行",
	["nakamura"] = "仲村由理",
	["designer:nakamura"] = "zengzouyu",
	["cv:nakamura"] = "",
	["illustrator:nakamura"] = "goto p",
	["caiduan"] = "裁断",
	[":caiduan"] = "其他角色的回合开始时，你可以令其展示并对你使用一张牌，若不能如此做则其本回合手牌上限-1。",
	["shenni"] = "神逆",
	[":shenni"] = "每名角色的回合限一次，当你的牌进入弃牌堆时，你可以收回此牌，若如此做，你于本回合内下一次失去牌时流失一点体力。",
}

yui=sgs.General(extension,"yui","real",3,false,false)

huanmengfilter = sgs.CreateFilterSkill{
	name = "#huanmeng-filter", 
	view_filter = function(self,to_select)
        if to_select:isKindOf("ExNihilo") then return false end 
		local room = sgs.Sanguosha:currentRoom()
		local owner = room:getCardOwner(to_select:getEffectiveId())
		if owner == nil then return false end
		if owner:getCardCount(false,false) >= 4 then return false end 
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:getSuit() == sgs.Card_Heart) and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, originalCard)
		local exnihilo = sgs.Sanguosha:cloneCard("ExNihilo", originalCard:getSuit(), originalCard:getNumber())
		exnihilo:setSkillName("huanmeng")
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(exnihilo)
		return card
	end
}

huanmeng = sgs.CreateTriggerSkillV2{
	name = "huanmeng",
	events = {sgs.CardsMoveOneTime},
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.CardsMoveOneTime then return end
		if not ctx.owner or not player or not player:isAlive() or ctx.owner:objectName() ~= player:objectName() then return end
		local move = ctx.original_data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand)
		or move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand then
			if player:getHandcardNum() >= 4 then
				room:filterCards(player, player:getCards("h"), true)
			else
				room:filterCards(player, player:getCards("h"), false)
			end
		end
	end,
}

yui_changxin = sgs.CreateTriggerSkillV2 {
	name = "yui_changxin",
	events = {sgs.AskForPeachesDone,sgs.Predamage,sgs.PreHpRecover},
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.AskForPeachesDone then
			local dying = data:toDying()
			if dying.who and dying.who:objectName() == player:objectName()
			and player:getCardCount(false,false) > 0 and player:getHp() <= 0 then
				return "yui_changxin"
			end
		elseif event == sgs.Predamage then
			local damage = data:toDamage()
			if damage.from and damage.from:hasSkill("yui_changxin")
			and room:getCurrentDyingPlayer() and room:getCurrentDyingPlayer():objectName()==damage.from:objectName() then
				return "yui_changxin", damage.from
			end
		elseif event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.from and rec.from:hasSkill("yui_changxin")
			and room:getCurrentDyingPlayer() and room:getCurrentDyingPlayer():objectName()==rec.from:objectName() then
				return "yui_changxin", rec.from
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.AskForPeachesDone then
			while player:getCardCount(false,false) > 0 do
                --[[local avai_ids = {}
                for _,c in sgs.qlist(player:getHandcards()) do
                    if c:isAvailable(player) then table.insert(avai_ids,c:getEffectiveId()) end
                end
                --之前给你发过一个类似的技能，写AI的时候一定要参考那个注释哈。
                local pattern = table.concat(avai_ids,"#")
				local card = room:askForUseCard(player, pattern, "@yui_changxin")]]
						local pattern = "|.|.|.|."
						for _,cd in sgs.qlist(player:getHandcards()) do
							if cd:isKindOf("EquipCard") and not player:isLocked(cd)  then
								if cd:isAvailable(player) then
									pattern = "EquipCard,"..pattern
									break
								end
							end
						end
						for _,cd in sgs.qlist(player:getHandcards()) do
							if cd:isKindOf("Analeptic") and not player:isLocked(cd)  then
								local card = sgs.Sanguosha:cloneCard("Analeptic", cd:getSuit(), cd:getNumber())
								card:deleteLater()
								if card:isAvailable(player) then
									pattern = "Analeptic,"..pattern
									break
								end
							end
						end
						for _,cd in sgs.qlist(player:getHandcards()) do
							if cd:isKindOf("Slash") and not player:isLocked(cd)  then
								local card = sgs.Sanguosha:cloneCard("Slash", cd:getSuit(), cd:getNumber())
								card:deleteLater()
								if card:isAvailable(player) then
									for _,p in sgs.qlist(room:getOtherPlayers(player)) do
										if (not sgs.Sanguosha:isProhibited(player, p, cd)) and player:canSlash(p, card, true) then
											pattern = "Slash,"..pattern
											break
										end
									end
								end
								break
							end
						end
						for _,cd in sgs.qlist(player:getHandcards()) do
							if cd:isKindOf("Peach") and not player:isLocked(cd)  then
								if cd:isAvailable(player) then
									pattern = "Peach,"..pattern
									break
								end
							end
						end
						for _,cd in sgs.qlist(player:getHandcards()) do
							if cd:isKindOf("TrickCard") and not player:isLocked(cd) then
								for _,p in sgs.qlist(room:getOtherPlayers(player)) do
									if not sgs.Sanguosha:isProhibited(player, p, cd) then 
										pattern = "TrickCard+^Nullification,"..pattern
										break
									end
								end
								break
							end
						end
				local card = room:askForUseCard(player, pattern, "@yui_changxin")
				if card then
					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if not p:isNude() then
							targets:append(p)
						end
					end
					if targets:isEmpty() then break end
					local to = room:askForPlayerChosen(player, targets, "yui_changxin", "yui_changxin-invoke", true, true)
					if to then
						local to_throw = room:askForCardChosen(player, to, "he", "yui_changxin", false, sgs.Card_MethodDiscard)
						room:throwCard(sgs.Sanguosha:getCard(to_throw), to, player)
					end
				else break end
			end
			return false
		elseif event == sgs.Predamage or event == sgs.PreHpRecover then
			return true
		end
		return false
	end,
}

yui:addSkill(huanmeng)
yui:addSkill(huanmengfilter)
extension:insertRelatedSkills("huanmeng", "#huanmeng-filter")
yui:addSkill(yui_changxin)
sgs.LoadTranslationTable{
	["#yui"] = "幻梦终遂",
	["yui"] = "由依",
	["designer:yui"] = "无限连的陆伯言",
	["cv:yui"] = "",
	["illustrator:yui"] = "切符",
	["huanmeng"] = "幻梦",
	[":huanmeng"] = "<font color=\"blue\"><b>锁定技，</b></font>当你的手牌数小于4张时，你的红桃手牌均视为无中生有。",
	["yui_changxin"] = "尝新",
	[":yui_changxin"] = "当你濒死求桃失败，你可以依次使用牌直到不能使用，你每以此法使用一张牌可以弃置一名其他角色一张牌，结算过程中防止你造成的伤害与体力回复。",
}