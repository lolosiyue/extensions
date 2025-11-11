module("extensions.animic",package.seeall)
extension=sgs.Package("animic")

sgs.LoadTranslationTable{
	["animic"] = "动漫包",
}

zzy_marisa=sgs.General(extension,"zzy_marisa","magic",4,false,false)

modao = sgs.CreateTriggerSkill{
	name = "modao" ,
	events = {sgs.EventPhaseStart,sgs.Damage, sgs.EventPhaseChanging} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:setPlayerMark(player, self:objectName(),0)
				if (not room:askForSkillInvoke(player,self:objectName(),data)) then return false end
				local choice = tonumber(room:askForChoice(player, self:objectName(), "1+2+3+4+5+6+7+8+9"))
				player:setTag(self:objectName(), sgs.QVariant(choice))
				local players = sgs.SPlayerList()
				players:append(player)
				room:addPlayerMark(player, "&modao+:+"..choice.."-Clear", 1, players)
			end
			return false
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to then
				room:setPlayerMark(player, self:objectName(),player:getMark(self:objectName())+damage.damage)
				room:setPlayerMark(player, "&modao+:+damage-Clear", player:getMark(self:objectName()))
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark(self:objectName()) > 0 then--
				local num = player:getTag(self:objectName()):toInt()
				if num > 0 then
					if player:getMark(self:objectName()) >= num then
						local targets = sgs.SPlayerList()
						for _,p in sgs.qlist(room:getOtherPlayers(player)) do
							if not p:isKongcheng() then
								targets:append(p)
							end
						end
						if targets:isEmpty() then return false end
						local target = room:askForPlayerChosen(player, targets, self:objectName())
						local discards = sgs.IntList()
						local to_obtain = dummyCard()
						for i = 1, num do--进行多次执行
							local id = room:askForCardChosen(player, target, "h", self:objectName(),
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
				room:setPlayerMark(player, self:objectName(),0)
				player:setTag(self:objectName(), sgs.QVariant(0))
			end
		end
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
	filter = function(self, targets, to_select) 
		return #targets < 2 and not to_select:isChained()
	end,
	on_effect = function(self, effect) 
		if effect.to:isNude() then return end
		local room = effect.to:getRoom()
		room:setPlayerProperty(effect.to, "chained", sgs.QVariant(true))
	end,
}

huayuanVS = sgs.CreateViewAsSkill{
	name = "huayuan",
	n = 0,
	response_pattern = "@@huayuan",
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self)
		return huayuanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
}

huayuan = sgs.CreateTriggerSkill{
	name = "huayuan" ,
	events = {sgs.EventPhaseStart} ,
	view_as_skill = huayuanVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:askForUseCard(player, "@@huayuan", "@huayuan")
			end
			return false
		end
	end,
}

cuisheng = sgs.CreateTriggerSkill{
	name = "cuisheng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and player:isChained() then
			for _,source in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local n = 0
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:isChained() then
						n = n + 1
					end
				end
				if player:getHandcardNum() >= n then return false end
				if (not room:askForSkillInvoke(source,self:objectName(),data)) then return false end
				room:drawCards(player, 1, "cuisheng")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

jiaosha = sgs.CreateTriggerSkill{
	name = "jiaosha" ,
	events = {sgs.EventPhaseChanging,sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:hasSkill(self:objectName()) then
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:isChained() then
						targets:append(p)
					end
				end
				if targets:isEmpty() then return false end
				local to = room:askForPlayerChosen(player, targets, "jiaosha", "jiaosha-invoke", true, true)
				if to then
					room:setPlayerProperty(to, "chained", sgs.QVariant(false))
					room:damage(sgs.DamageStruct(self:objectName(), player, to))
					local playerdata = sgs.QVariant()
					playerdata:setValue(to)
					room:setTag("jiaoshaTarget", playerdata)
				end
			end
		elseif event==sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_NotActive then return false end
			if room:getTag("jiaoshaTarget") then
				local target = room:getTag("jiaoshaTarget"):toPlayer()
				room:removeTag("jiaoshaTarget")
				if target and target:isAlive() then
					target:gainAnExtraTurn()
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
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

huanglue = sgs.CreateTriggerSkill{
	name = "huanglue" ,
	events = {sgs.CardUsed} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if not use.from or not use.card or use.card:getTypeId() == 0 then return false end
			local point = use.card:getNumber()
			if point >= 13 then return false end
			local point_str = ".."
			if point == 12 then
				point_str = ".|.|13|.|."
			else
				point_str = ".|.|"..tostring(point+1).."~13|.|."
			end
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local invoked = room:askForCard(p, point_str, "@huanglue", data, self:objectName())
				if invoked then
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
						room:throwCard(use.card, room:getCardOwner(use.card:getEffectiveId()), p)
					end
					if not use.whocard then
						room:setTag("SkipGameRule",sgs.QVariant(tonumber(event)))
					end
					break
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

luafenwei = sgs.CreateTriggerSkill{
	name = "luafenwei" ,
	events = {sgs.TargetConfirmed},
	frequency = sgs.Skill_Frequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
                if player:getPhase() ~= sgs.Player_NotActive then return false end
		if event == sgs.TargetConfirmed and use.to:contains(player) then
			if not use.card or use.card:getTypeId() == 0 or not player:isKongcheng() then return false end
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getEquips():length() + p:getJudgingArea():length() > 0 then
                                    targets:append(p)
				end
			end
			if targets:isEmpty() then return false end
			local to = room:askForPlayerChosen(player, targets, "luafenwei", "luafenwei-invoke", true, true)
			if to then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
				local card_id = room:askForCardChosen(player, to, "ej", self:objectName())
				room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
			end
		end
		return false
	end
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

guihaoVS = sgs.CreateViewAsSkill{
	name = "guihao",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped() and to_select:isBlack()
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
		newanal:deleteLater()
		if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then return false end
		return player:getMark("guihao") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "analeptic") and player:getMark("guihao") > 0
	end
}

guihao = sgs.CreateTriggerSkill{
	name = "guihao",
	events = {sgs.EventPhaseStart,sgs.CardUsed},
	view_as_skill = guihaoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				room:setPlayerMark(player, "guihao",0)
				room:setPlayerMark(player, "&guihao",0)
				if (not room:askForSkillInvoke(player,self:objectName(),data)) then return false end
				room:loseHp(player)
				room:drawCards(player, player:getLostHp(), "guihao")
				room:addPlayerMark(player, "guihao")
				room:addPlayerMark(player, "&guihao")
			end
			return false
		elseif event==sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Analeptic") and use.m_addHistory then
				room:addPlayerHistory(player, use.card:getClassName(),-1)
			end
		end
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

caiduanMaxCards = sgs.CreateMaxCardsSkill{
	name = "#caiduanMaxCards",

	extra_func = function(self, target)
		return -target:getMark("caiduan")
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
	filter = function(self, targets, to_select)
		local card_id = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(card_id)
		if card and card:targetFixed() then
			return false
		end
		--if sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, card) == 0 then return false end
		local nakamura = nil
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
			if sgs.Self:hasFlag("caiduan"..p:objectName()) then
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
			return card and card:targetFilter(qtargets, to_select, sgs.Self) 
			and not sgs.Self:isProhibited(to_select, card, qtargets)
		end
	end,
	feasible = function(self, targets)
		local card_id = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(card_id)
		local nakamura = nil
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
			if sgs.Self:hasFlag("caiduan"..p:objectName()) then
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
		return card and card:targetsFeasible(qtargets, sgs.Self) and (card:targetFixed() or table.contains(targets,nakamura))
	end,	
	on_validate = function(self, card_use)
		local card_id = self:getSubcards():first()
		return sgs.Sanguosha:getCard(card_id)		
	end,
}

caiduanVS = sgs.CreateViewAsSkill{
	name = "caiduan",
	n = 1,
	expand_pile = "wooden_ox",
	view_filter = function(self, selected, to_select)
		local nakamura = nil
		for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
			if sgs.Self:hasFlag("caiduan"..p:objectName()) then
				nakamura = p
				break
			end
		end
		if nakamura and to_select:isAvailable(sgs.Self) then
			return to_select:targetFilter(sgs.PlayerList(), nakamura, sgs.Self)
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local usecard = caiduanCard:clone()
		for _,card in pairs(cards) do
			usecard:addSubcard(card)
		end
		return usecard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@caiduan"
	end
}

caiduan = sgs.CreateTriggerSkill{
	name = "caiduan" ,
	events = {sgs.TurnStart,sgs.EventPhaseStart,sgs.ChoiceMade,sgs.EventPhaseChanging} ,
	view_as_skill = caiduanVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.TurnStart then
			room:setPlayerMark(player,"caiduan",0)
		elseif event==sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:objectName() == player:objectName() then continue end
					if (not room:askForSkillInvoke(p,self:objectName(),data)) then continue end
					room:setPlayerFlag(player, "caiduan"..p:objectName())
					local card = room:askForUseCard(player, "@@caiduan", "@caiduan")
					if player:hasFlag("caiduan"..p:objectName()) then
						room:setPlayerFlag(player, "-caiduan"..p:objectName())
					end
					if not card then
						room:addPlayerMark(player,"caiduan")
						room:addPlayerMark(player,"&caiduan-Clear")
					end
				end
			end
		elseif event==sgs.ChoiceMade then
			local use = data:toCardUse()
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
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			if player:getMark("caiduan") > 0 then
				room:setPlayerMark(player,"caiduan",0)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

shenni = sgs.CreateTriggerSkill{
	name = "shenni",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local current = room:getCurrent()
		local move = data:toMoveOneTime()
		local source = move.from
		if source and source:objectName() == player:objectName() then
			if current and current:hasFlag("shenni"..player:objectName()) and not current:hasFlag("shenni"..player:objectName()..self:objectName()) then
				
				if (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) 
				and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
					room:setPlayerFlag(current, "shenni"..player:objectName()..self:objectName())
					room:setPlayerMark(player, "&shenni-Clear", 0)
					room:loseHp(player)
				end
			else
				if move.to_place == sgs.Player_DiscardPile then
                    if current:hasFlag("shenni"..player:objectName()) or not room:askForSkillInvoke(player,self:objectName(), data) then
						return false 
					end
					room:addPlayerMark(player, "&shenni-Clear")
                    local moveA = sgs.CardsMoveStruct()
					moveA.card_ids = move.card_ids
					moveA.to = player
					moveA.to_place = sgs.Player_PlaceHand
					room:moveCardsAtomic(moveA, false)
					move.card_ids = sgs.IntList()
					data:setValue(move)
					room:setPlayerFlag(current, "shenni"..player:objectName())
				end
			end
		end
		return false
	end
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

huanmeng = sgs.CreateTriggerSkill{
	name = "huanmeng",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand)
			or move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand then
				if player:getHandcardNum() >= 4 then
					room:filterCards(player, player:getCards("h"), true)
				else
					room:filterCards(player, player:getCards("h"), false)
				end
			end
		end
	end,
}

yui_changxin = sgs.CreateTriggerSkill {
	name = "yui_changxin",
	events = {sgs.AskForPeachesDone,sgs.Predamage,sgs.PreHpRecover},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.AskForPeachesDone then
			local dying = data:toDying()
			if dying.who:objectName() ~= player:objectName() or (not player:hasSkill(self:objectName())) then
				return false
			end
			if player:getCardCount(false,false) == 0 or player:getHp() > 0 then return false end
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
					if targets:isEmpty() then return false end
					local to = room:askForPlayerChosen(player, targets, "yui_changxin", "yui_changxin-invoke", true, true)
					if to then
						local to_throw = room:askForCardChosen(player, to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
						room:throwCard(sgs.Sanguosha:getCard(to_throw), to, player)
					end
				else break end
			end
			return false
		elseif event==sgs.Predamage then
			local damage = data:toDamage()
			if damage.from and damage.from:hasSkill(self:objectName())
			and room:getCurrentDyingPlayer() and room:getCurrentDyingPlayer():objectName()==damage.from:objectName() then
				return true
			end
		elseif event==sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.from and rec.from:hasSkill(self:objectName())
			and room:getCurrentDyingPlayer() and room:getCurrentDyingPlayer():objectName()==rec.from:objectName() then
				return true
			end
		end
	end,
	can_trigger = function(self,target)
		return target ~= nil
	end   
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