--==《新武将》==--
kearmsxfyli = sgs.Package("kearmsxfyli", sgs.Package_GeneralPack)
kearmsxfyzhen = sgs.Package("kearmsxfyzhen", sgs.Package_GeneralPack)

--on_record 按 (owner,instance) 逐实例调用；共享状态只许首个实例记录一次，与旧版 on_trigger 每事件一次对齐
local function kesxV2RecordOnce(room, skill, ctx)
	for _, p in sgs.qlist(room:getAllPlayers(true)) do
		for _, iid in sgs.qlist(p:getSkillInstanceIds(skill:objectName())) do
			return ctx.owner == p and ctx.instanceID == iid
		end
	end
	return false
end

--buff集中
kearmsxfyslashmore = sgs.CreateTargetModSkillV2 {
	name = "kearmsxfyslashmore",
	pattern = ".",
	correct_func = function(skill, ctx)
		local from = ctx:getPrimary()
		local card = ctx:getCard()
		if not from or not card then return false end
		local mod_type = ctx:getModType()
		if mod_type == sgs.TargetModSkill_Residue then
			if from:getPhase() == sgs.Player_Play and from:getMark("sxkuangcaiUse-PlayClear") < 2 and from:hasSkill("sxkuangcai") then
				return 999
			end
			return false
		end
		if mod_type == sgs.TargetModSkill_ExtraTarget then
			--[[if from:hasSkill("kesxhuiji")
			and card:isKindOf("Slash") then
				return 999
			end]]
			return false
		end
		if mod_type == sgs.TargetModSkill_DistanceLimit then
			if card:isKindOf("Slash") and card:getSkillName() == "zcruixi" then
				return 999
			end
			if from:getPhase() == sgs.Player_Play and from:getMark("sxkuangcaiUse-PlayClear") < 2 and from:hasSkill("sxkuangcai") then
				return 999
			end
			return false
		end
		return false
	end,
}
kearmsxfyli:addSkills(kearmsxfyslashmore)

sgs.LoadTranslationTable {
	["kearmsxfyli"] = "四象封印·少阴·离",
	["kearmsxfyzhen"] = "四象封印·少阴·震",
	["sxfygen"] = "四象封印·太阴·艮",
	["sxfykun"] = "四象封印·太阴·坤",
	["sxfyxun"] = "四象封印·少阳·巽",
	["sxfykan"] = "四象封印·少阳·坎",
	["sxfydui"] = "四象封印·太阳·兑",
	["sxfyqian"] = "四象封印·太阳·乾",
}

kesxdengzhi = sgs.General(kearmsxfyli, "kesxdengzhi", "shu", 3)

kesxjimeng = sgs.CreateTriggerSkillV2 {
	name = "kesxjimeng",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if (event == sgs.EventPhaseStart) and player:isAlive() and (player:getCardCount() > 0) and (player:getPhase() == sgs.Player_Start) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local ids = player:handCards()
		for _, id in sgs.qlist(player:getEquipsId()) do
			ids:append(id)
		end
		local fri = room:askForYiji(player, ids, skill:objectName(), false, false, true, -1, sgs.SPlayerList(), sgs.CardMoveReason(), "kesxjimeng_ask", true)
		if fri and fri:getCardCount() > 0 and player:isAlive() then
			ids = fri:handCards()
			for _, id in sgs.qlist(fri:getEquipsId()) do
				ids:append(id)
			end
			local tos = sgs.SPlayerList()
			tos:append(player)
			room:askForYiji(fri, ids, skill:objectName(), false, false, false, -1, tos, sgs.CardMoveReason(), "kesxjimeng_choose:" .. player:objectName())
		end
		return false
	end,
	--[[can_trigger = function(self, player)
		return true
	end]]
}
kesxdengzhi:addSkill(kesxjimeng)

kesxhehe = sgs.CreateTriggerSkillV2 {
	name = "kesxhehe",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseEnd },
	can_trigger = function(skill, event, room, player, data)
		if (event == sgs.EventPhaseEnd) and player:isAlive() and (player:getPhase() == sgs.Player_Draw) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHandcardNum() == player:getHandcardNum() then
				players:append(p)
			end
		end
		local fris = room:askForPlayersChosen(player, players, skill:objectName(), 0, 2, "kesxhehe-ask", true, true)
		if fris:length() > 0 then
			room:drawCards(fris, 1, skill:objectName())
		end
		return false
	end,
	--[[can_trigger = function(self, player)
		return true
	end]]
}
kesxdengzhi:addSkill(kesxhehe)

sgs.LoadTranslationTable {

	["kesxdengzhi"] = "邓芝[离]",
	["&kesxdengzhi"] = "邓芝",
	["#kesxdengzhi"] = "绝境的外交家",
	["designer:kesxdengzhi"] = "官方",
	["cv:kesxdengzhi"] = "官方",
	["illustrator:kesxdengzhi"] = "凝聚永恒",

	["kesxjimeng"] = "急盟",
	["kesxjimeng_ask"] = "你可以发动“急盟”交给一名角色任意张牌",
	["kesxjimeng_choose"] = "急盟：请选择交给 %src 的牌",
	[":kesxjimeng"] = "准备阶段，你可以交给一名其他角色至少一张牌，然后其交给你至少一张牌。",

	["kesxhehe"] = "和合",
	["kesxhehe-ask"] = "你可以发动“和合”令至多两名角色各摸一张牌",
	[":kesxhehe"] = "摸牌阶段结束时，你可以令至多两名手牌数与你相同的其他角色各摸一张牌。",

	["$kesxjimeng1"] = "精诚协作，以御北虏。",
	["$kesxjimeng2"] = "两家携手，共抗时艰。",
	["$kesxhehe1"] = "清廉严谨，以身作则。",
	["$kesxhehe2"] = "赏罚明断，自我而始。",

	["~kesxdengzhi"] = "大王命世之英，何行此不智之举？",
}

kesxwenyang = sgs.General(kearmsxfyli, "kesxwenyang", "wei", 4)

kesxquedi = sgs.CreateViewAsSkillV2 {
	name = "kesxquedi",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local juedou = sgs.Sanguosha:cloneCard("duel")
			juedou:setSkillName("kesxquedi")
			juedou:deleteLater()
			return juedou:isAvailable(player)
		elseif reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern():contains("duel")
		end
		return false
	end,
	can_select_card = function(skill, request, card)
		if not card:isKindOf("Slash") then
			return false
		end
		local juedou = sgs.Sanguosha:cloneCard("duel")
		juedou:addSubcard(card:getEffectiveId())
		juedou:setSkillName("kesxquedi")
		juedou:deleteLater()
		return juedou:isAvailable(request:getInitiator())
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local juedou = sgs.Sanguosha:cloneCard("duel")
		juedou:addSubcard(ids:first())
		juedou:setSkillName("kesxquedi")
		return juedou
	end,
}
kesxwenyang:addSkill(kesxquedi)

sgs.LoadTranslationTable {

	["kesxwenyang"] = "文鸯[离]",
	["&kesxwenyang"] = "文鸯",
	["#kesxwenyang"] = "独骑破军",
	["designer:kesxwenyang"] = "官方",
	["cv:kesxwenyang"] = "官方",
	["illustrator:kesxwenyang"] = "鬼画府",

	["kesxquedi"] = "却敌",
	[":kesxquedi"] = "你可以将一张【杀】当【决斗】使用。",

	["$kesxquedi1"] = "哼，缘何退却？有胆来战！",
	["$kesxquedi2"] = "八千之众，尚不如我一人乎？",

	["~kesxwenyang"] = "得报父仇，我无憾矣。",
}

kesxchengpu = sgs.General(kearmsxfyli, "kesxchengpu", "wu", 4)

kesxchunlao = sgs.CreateTriggerSkillV2 {
	name = "kesxchunlao",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.CardsMoveOneTime },
	on_record = function(skill, event, room, player, ctx)
		local owner = ctx.owner
		if not owner then return end
		if event == sgs.EventPhaseStart then
			if owner:objectName() == player:objectName() and owner:getPhase() == sgs.Player_Discard then
				owner:removeTag("kesxchunlaoToGet")
			end
			return
		end
		if event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			if
				move.from
				and owner:objectName() == move.from:objectName()
				and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
				and (owner:getPhase() == sgs.Player_Discard)
			then
				local tag = owner:getTag("kesxchunlaoToGet"):toIntList()
				for _, card_id in sgs.qlist(move.card_ids) do
					tag:append(card_id)
				end
				local d = sgs.QVariant()
				d:setValue(tag)
				owner:setTag("kesxchunlaoToGet", d)
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseEnd then return false end
		if player:isAlive() and player:getPhase() == sgs.Player_Discard
			and player:getTag("kesxchunlaoToGet"):toIntList():length() >= 2 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local eny = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "kesxchunlao-ask", true, true)
		if not eny then return false end
		ctx.targets:append(eny)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local tag = player:getTag("kesxchunlaoToGet"):toIntList()
		local eny = ctx.targets:first()
		room:broadcastSkillInvoke(skill:objectName())
		local dummy = sgs.Sanguosha:cloneCard("slash")
		dummy:addSubcards(eny:handCards())
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, eny:objectName(), skill:objectName(), "")
		room:moveCardTo(dummy, nil, sgs.Player_DiscardPile, reason)
		dummy:deleteLater()
		dummy = sgs.Sanguosha:cloneCard("slash")
		for _, id in sgs.qlist(tag) do
			if room:getCardPlace(id) == sgs.Player_DiscardPile then
				dummy:addSubcard(id)
			end
		end
		eny:obtainCard(dummy)
		dummy:deleteLater()
		if eny:askForSkillInvoke(skill:objectName(), ToData("kesxchunlao0:" .. player:objectName()), false) then
			room:recover(player, sgs.RecoverStruct())
		end
		player:removeTag("kesxchunlaoToGet")
		return false
	end,
}
kesxchengpu:addSkill(kesxchunlao)

sgs.LoadTranslationTable {

	["kesxchengpu"] = "程普[离]",
	["&kesxchengpu"] = "程普",
	["#kesxchengpu"] = "三朝虎臣",
	["designer:kesxchengpu"] = "官方",
	["cv:kesxchengpu"] = "官方",
	["illustrator:kesxchengpu"] = "玖等仁品",

	["kesxchunlao"] = "醇醪",
	["kesxchunlao:kesxchunlao0"] = "醇醪：你可以令 %src 回复1点体力",
	["kesxchunlao-ask"] = "你可以发动“醇醪”将弃置的牌交换一名其他角色的手牌",
	[":kesxchunlao"] = "弃牌阶段结束时，若你本阶段弃置了至少两张牌，你可以令一名其他角色将所有手牌置入弃牌堆并获得你弃置的牌，然后其可以令你回复1点体力。",

	["$kesxchunlao1"] = "醇酒佳酿杯中饮，醉酒提壶力千钧。",
	["$kesxchunlao2"] = "身被疮痍，唯酒能医。",

	["~kesxchengpu"] = "酒尽身死，壮哉！",
}

kesxlijue = sgs.General(kearmsxfyli, "kesxlijue", "qun", 5)

kesxxiongsuan = sgs.CreateTriggerSkillV2 {
	name = "kesxxiongsuan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if (event == sgs.EventPhaseStart) and player:isAlive() and (player:getPhase() == sgs.Player_Start) then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getHp() > player:getHp() then
					return false
				end
			end
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local players = sgs.SPlayerList()
		for _, q in sgs.qlist(room:getAllPlayers()) do
			if q:getHp() == player:getHp() then
				players:append(q)
			end
		end
		room:sendCompulsoryTriggerLog(player, skill)
		local fris = room:askForPlayersChosen(player, players, skill:objectName(), 1, 99, "kesxxiongsuan-ask", true, true)
		for _, q in sgs.qlist(fris) do
			room:damage(sgs.DamageStruct(skill:objectName(), player, q))
		end
		return false
	end,
}
kesxlijue:addSkill(kesxxiongsuan)

sgs.LoadTranslationTable {

	["kesxlijue"] = "李傕[离]",
	["&kesxlijue"] = "李傕",
	["#kesxlijue"] = "奸谋恶勇",
	["designer:kesxlijue"] = "官方",
	["cv:kesxlijue"] = "官方",
	["illustrator:kesxlijue"] = "凝聚永恒",

	["kesxxiongsuan"] = "兇算",
	["kesxxiongsuan-ask"] = "请选择发动“兇算”造成伤害的角色",
	[":kesxxiongsuan"] = "锁定技，准备阶段，若没有角色体力值大于你，你对至少一名体力值等于你的角色各造成1点伤害。",

	["$kesxxiongsuan1"] = "狼抗傲慢，祸福沿袭！",
	["$kesxxiongsuan2"] = "我就喜欢听这，狼嚎悲鸣！",

	["~kesxlijue"] = "这一次我拿不下长安了吗？",
}

kesxfeiyi = sgs.General(kearmsxfyli, "kesxfeiyi", "shu", 3)

kesxtiaoheCard = sgs.CreateSkillCard {
	name = "kesxtiaoheCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if #targets == 0 then
			return to_select:getWeapon() ~= nil
		end
		if #targets == 1 then
			return to_select:getArmor() ~= nil
		end
		return #targets < 2
	end,
	feasible = function(self, targets, player)
		return #targets == 2
	end,
	about_to_use = function(self, room, use)
		room:setTag("kesxtiaoheUse", ToData(use))
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, player, targets)
		local use = room:getTag("kesxtiaoheUse"):toCardUse()
		local w = use.to:first():getWeapon()
		if w and player:canDiscard(use.to:first(), w:getEffectiveId()) then
			room:throwCard(w, self:getSkillName(), use.to:first(), player)
		end
		local a = use.to:last():getArmor()
		if a and player:canDiscard(use.to:last(), a:getEffectiveId()) then
			room:throwCard(a, self:getSkillName(), use.to:last(), player)
		end
	end,
}

kesxtiaohe = sgs.CreateViewAsSkillV2 {
	name = "kesxtiaohe",
	n = 0,
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	create_card = function(skill, request)
		return kesxtiaoheCard:clone()
	end,
}
kesxfeiyi:addSkill(kesxtiaohe)

kesxqiansu = sgs.CreateTriggerSkillV2 {
	name = "kesxqiansu",
	frequency = sgs.Skill_Frequent,
	events = { sgs.TargetConfirmed },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.TargetConfirmed then return false end
		local use = data:toCardUse()
		if use.card:isKindOf("TrickCard") and use.to:contains(player) and (player:getEquipsId():length() == 0) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:drawCards(1, skill:objectName())
		return false
	end,
}
kesxfeiyi:addSkill(kesxqiansu)

sgs.LoadTranslationTable {

	["kesxfeiyi"] = "费祎[离]",
	["&kesxfeiyi"] = "费祎",
	["#kesxfeiyi"] = "洞世权相",
	["designer:kesxfeiyi"] = "官方",
	["cv:kesxfeiyi"] = "官方",
	["illustrator:kesxfeiyi"] = "凝聚永恒",

	["kesxtiaohe"] = "调和",
	[":kesxtiaohe"] = "出牌阶段限一次，你可以选择一名装备区有武器牌的角色和另一名装备区有防具牌的角色，然后你分别弃置这两张牌。",

	["kesxqiansu"] = "谦素",
	[":kesxqiansu"] = "当你成为锦囊牌的目标后，若你的装备区没有牌，你可以摸一张牌。",

	["$kesxtiaohe1"] = "斟酌损益，进尽忠言，此臣等之任也。",
	["$kesxtiaohe2"] = "两相匡护，以各安其分，兼尽其用。",
	["$kesxqiansu1"] = "承葛公遗托，富国安民。",
	["$kesxqiansu2"] = "保国治民，敬守社稷。",

	["~kesxfeiyi"] = "吾何惜一死，惜不见大汉中兴矣。",
}

kesxfanyufeng = sgs.General(kearmsxfyli, "kesxfanyufeng", "qun", 3, false)

kesxbazhanCard = sgs.CreateSkillCard {
	name = "kesxbazhanCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return (#targets < 1) and to_select:isMale()
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:showCard(player, self:getSubcards():first())
		room:giveCard(player, target, self, self:getSkillName(), true)
		local cc = sgs.Sanguosha:getCard(self:getSubcards():first())
		local xxx = room:askForExchange(target, "kesxbazhan", 1, 1, false, "kesxbazhan-choose:" .. player:objectName(), true, "^" .. cc:getType())
		if xxx then
			room:showCard(target, xxx:getSubcards():first())
			room:giveCard(target, player, xxx, self:getSkillName(), true)
		end
	end,
}

kesxbazhan = sgs.CreateViewAsSkillV2 {
	name = "kesxbazhan",
	n = 1,
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 2,
	can_activate = function(skill, request)
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_card = function(skill, request, card)
		return request:getSelectedCardIds():isEmpty() and not card:isEquipped()
	end,
	create_card = function(skill, request)
		local card = kesxbazhanCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		return card
	end,
}
kesxfanyufeng:addSkill(kesxbazhan)

kesxqiaoyingex = sgs.CreateCardLimitSkill {
	name = "#kesxqiaoyingex",
	limit_list = function(self, player)
		return "use"
	end,
	limit_pattern = function(self, player)
		if (player:getMark("&kesxqiaoying-Clear") < player:getHandcardNum()) and (player:getMark("kesxqiaoyingeffect-Clear") > 0) then
			return ".|red|.|hand"
		end
		return ""
	end,
}
kesxfanyufeng:addSkill(kesxqiaoyingex)

kesxqiaoying = sgs.CreateTriggerSkillV2 {
	name = "kesxqiaoying",
	events = { sgs.EventPhaseStart, sgs.DamageInflicted },
	on_record = function(skill, event, room, player, ctx)
		local owner = ctx.owner
		if not owner or not owner:isAlive() then return end
		if event == sgs.DamageInflicted then
			local current = room:getCurrent()
			if not current or owner:objectName() ~= current:objectName() then return end
			local damage = ctx.original_data:toDamage()
			if damage.to:getHandcardNum() > damage.to:getMark("&kesxqiaoying-Clear") then
				room:sendCompulsoryTriggerLog(owner, skill)
				damage.damage = 1 + damage.damage
				ctx.original_data:setValue(damage)
			end
			return
		end
		if (event == sgs.EventPhaseStart) and owner:objectName() == player:objectName()
			and (owner:getPhase() == sgs.Player_RoundStart) then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				room:setPlayerMark(p, "&kesxqiaoying-Clear", p:getHandcardNum())
				room:setPlayerMark(p, "kesxqiaoyingeffect-Clear", 1)
			end
		end
	end,
}
kesxfanyufeng:addSkill(kesxqiaoying)
kearmsxfyli:insertRelatedSkills("kesxqiaoying", "#kesxqiaoyingex")

sgs.LoadTranslationTable {

	["kesxfanyufeng"] = "樊玉凤[离]",
	["&kesxfanyufeng"] = "樊玉凤",
	["#kesxfanyufeng"] = "红鸾寡宿",
	["designer:kesxfanyufeng"] = "官方",
	["cv:kesxfanyufeng"] = "官方",
	["illustrator:kesxfanyufeng"] = "琬焱",

	["kesxbazhan"] = "把盏",
	["kesxbazhan-choose"] = "你可以交给 %src 一张牌",
	[":kesxbazhan"] = "出牌阶段限两次，你可以展示一张手牌并交给一名男性角色，然后其可以展示一张与此牌类别不同的手牌并交给你。",

	["kesxqiaoying"] = "醮影",
	[":kesxqiaoying"] = "在你的回合内，手牌数大于其当前回合开始时的手牌数的角色不能使用红色手牌且其受到的伤害+1。",

	["$kesxbazhan1"] = "今与将军把盏，酒不醉人人自醉。",
	["$kesxbazhan2"] = "昨日把盏消残酒，醉时朦胧见君来。",
	["$kesxqiaoying1"] = "经年相别，顾盼云泥，此间再未合影。",
	["$kesxqiaoying2"] = "举杯邀月盼云郎，我与月影成两人。",

	["~kesxfanyufeng"] = "浓酒只消昨日恨，奈何岁月败美人。 ",
}

kesxchengyu = sgs.General(kearmsxfyli, "kesxchengyu", "wei", 3, true)

kesxchengyu:addSkill("shefu")

kesxyibing = sgs.CreateTriggerSkillV2 {
	name = "kesxyibing",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Dying },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.Dying then return false end
		local dying_data = data:toDying()
		local source = dying_data.who
		if source ~= player and source:getCardCount() > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local source = ctx.original_data:toDying().who
		if source and player:askForSkillInvoke(skill, source) then
			ctx.targets:append(source)
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local source = ctx.targets:first()
		room:broadcastSkillInvoke(skill:objectName())
		local card_id = room:askForCardChosen(player, source, "he", skill:objectName())
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
		room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
		return false
	end,
}
kesxchengyu:addSkill(kesxyibing)

sgs.LoadTranslationTable {

	["kesxchengyu"] = "程昱[离]",
	["&kesxchengyu"] = "程昱",
	["#kesxchengyu"] = "泰山捧日",
	["designer:kesxchengyu"] = "官方",
	["cv:kesxchengyu"] = "官方",
	["illustrator:kesxchengyu"] = "DH",

	["kesxyibing"] = "益兵",
	[":kesxyibing"] = "当其他角色进入濒死状态时，你可以获得其一张牌。",

	["$kesxyibing1"] = "助曹公者昌，逆曹公者亡！",
	["$kesxyibing2"] = "愚民不可共济大事，必当与智者为伍。",

	["~kesxchengyu"] = "此诚报效国家之时，吾却休矣。",
}

kesxzhangyi = sgs.General(kearmsxfyli, "kesxzhangyi", "shu", 4, true)

kesxzhiyiVS = sgs.CreateViewAsSkillV2 {
	name = "kesxzhiyi",
	n = 0,
	response_or_use = true,
	target_mode = sgs.ViewAsSkillV2_NoTarget,
	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@kesxzhiyi"
	end,
	create_card = function(skill, request)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("_kesxzhiyi")
		return slash
	end,
}
kesxzhiyi = sgs.CreateTriggerSkillV2 {
	name = "kesxzhiyi",
	events = { sgs.EventPhaseChanging, sgs.CardUsed },
	view_as_skill = kesxzhiyiVS,
	frequency = sgs.Skill_Compulsory,
	on_record = function(skill, event, room, player, ctx)
		if event == sgs.CardUsed then
			local owner = ctx.owner
			local use = ctx.original_data:toCardUse()
			if owner and use.from and use.from:objectName() == owner:objectName()
				and use.card and use.card:isKindOf("Slash") then
				room:setPlayerMark(owner, "&kesxzhiyi-Clear", 1)
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseChanging then return false end
		local change = data:toPhaseChange()
		if (change.to == sgs.Player_NotActive) and (player:getMark("&kesxzhiyi-Clear") > 0) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		if sgs.Slash_IsAvailable(player) and room:askForUseCard(player, "@@kesxzhiyi", "kesxzhiyi-ask", 1) then
			return false
		end
		player:drawCards(1, skill:objectName())
		return false
	end,
}
kesxzhangyi:addSkill(kesxzhiyi)

sgs.LoadTranslationTable {

	["kesxzhangyi"] = "张翼[离]",
	["&kesxzhangyi"] = "张翼",
	["#kesxzhangyi"] = "亢锐怀忠",
	["designer:kesxzhangyi"] = "官方",
	["cv:kesxzhangyi"] = "官方",
	["illustrator:kesxzhangyi"] = "鬼画府",

	["kesxzhiyi"] = "执义",
	["kesxzhiyi:sha"] = "视为使用一张【杀】",
	["kesxzhiyi:draw"] = "摸一张牌",
	["kesxzhiyi-ask"] = "执义：你可以视为使用一张【杀】",
	[":kesxzhiyi"] = "锁定技，每个回合结束时，若你本回合使用过【杀】，你摸一张牌或视为使用一张【杀】。",

	["$kesxzhiyi1"] = "伯约勿扰，吾来助你！",
	["$kesxzhiyi2"] = "众将听令，此战可进不可退！",

	["~kesxzhangyi"] = "主公，季汉亡矣！",
}

kesxjianggan = sgs.General(kearmsxfyzhen, "kesxjianggan", "wei", 3, true)

kesxdaoshu = sgs.CreateTriggerSkillV2 {
	name = "kesxdaoshu",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseStart then return false end
		if not (player and player:isAlive() and player:getPhase() == sgs.Player_Start) then return false end
		local names, owners = {}, {}
		for _, jg in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if jg:isAlive() and jg:getMark("&usekesxdaoshu_lun") < 1 then
				table.insert(names, skill:objectName())
				table.insert(owners, jg:objectName())
			end
		end
		if #owners > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local canchooses = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(ctx.invoker)) do
			if not p:isKongcheng() then
				canchooses:append(p)
			end
		end
		local target = room:askForPlayerChosen(player, canchooses, skill:objectName(), "kesxdaoshu-ask", true, true)
		if not target then return false end
		ctx.targets:append(target)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.targets:first()
		room:broadcastSkillInvoke(skill:objectName())
		room:setPlayerMark(player, "&usekesxdaoshu_lun", 1)
		local card_id = room:askForCardChosen(player, target, "h", skill:objectName())
		room:showCard(target, card_id)
		local thecard = sgs.Sanguosha:getCard(card_id)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
		room:obtainCard(ctx.invoker, thecard, reason, true)
		room:setPlayerMark(ctx.invoker, "&kesxdaoshu+:+" .. thecard:getSuitString() .. "+-Clear", 1)
		room:setPlayerMark(player, "&kesxdaoshu+:+" .. thecard:getSuitString() .. "+-Clear", 1)
		return false
	end,
}
kesxjianggan:addSkill(kesxdaoshu)

kesxdaoshuex = sgs.CreateCardLimitSkill {
	name = "#kesxdaoshuex",
	limit_list = function(self, player, card)
		return "use"
	end,
	limit_pattern = function(self, player, card)
		if player:getMark("&kesxdaoshu+:+" .. card:getSuitString() .. "+-Clear") > 0 then
			return ".|.|.|hand"
		end
		return ""
	end,
}
kesxjianggan:addSkill(kesxdaoshuex)
--kearmsxfyzhen:insertRelatedSkills("kesxdaoshu","#kesxdaoshuex")

kesxdaizui = sgs.CreateTriggerSkillV2 {
	name = "kesxdaizui",
	events = { sgs.Damaged },
	frequency = sgs.Skill_Frequent,
	on_record = function(skill, event, room, player, ctx)
		local owner = ctx.owner
		if not (owner and player:objectName() == owner:objectName()) then return end
		if event == sgs.Damaged then
			if player:getMark("&usekesxdaoshu_lun") > 0 then
				room:sendCompulsoryTriggerLog(player, skill)
				room:setPlayerMark(player, "&usekesxdaoshu_lun", 0)
			end
		end
	end,
}
kesxjianggan:addSkill(kesxdaizui)

sgs.LoadTranslationTable {

	["kesxjianggan"] = "蒋干[震]",
	["&kesxjianggan"] = "蒋干",
	["#kesxjianggan"] = "独步江淮",
	["designer:kesxjianggan"] = "官方",
	["cv:kesxjianggan"] = "官方",
	["illustrator:kesxjianggan"] = "官方",

	["kesxdaoshu"] = "盗书",
	["usekesxdaoshu"] = "已盗书",
	["kesxdaoshu-ask"] = "你可以选择发动“盗书”的角色",
	[":kesxdaoshu"] = "每轮限一次，一名角色的准备阶段，你可以展示另一名角色的一张手牌并令其获得之，然后你与其本回合不能使用与该牌花色相同的手牌。",

	["kesxdaizui"] = "戴罪",
	[":kesxdaizui"] = "当你受到伤害后，你本轮视为未发动过“盗书”。",

	["$kesxdaoshu1"] = "在此机要之地，何不一窥东吴军机。",
	["$kesxdaoshu2"] = "哦？密信……果然有所收获。",
	["$kesxdaizui1"] = "望丞相权且记过，容干将功折罪啊！",
	["$kesxdaizui2"] = "干，谢丞相不杀之恩！",

	["~kesxjianggan"] = "唉！假信害我不浅啊……",
}

kesxmayunlu = sgs.General(kearmsxfyzhen, "kesxmayunlu", "shu", 4, false)

kesxfenghun = sgs.CreateTriggerSkillV2 {
	name = "kesxfenghun",
	events = { sgs.DamageCaused },
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.DamageCaused then return false end
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
			local use = room:getUseStruct(damage.card)
			if not use.to:contains(damage.to) then
				return false
			end
			if player:canDiscard(player, "he") or player:canDiscard(damage.to, "he") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local tos = sgs.SPlayerList()
		if player:canDiscard(player, "he") then
			tos:append(player)
		end
		if player:canDiscard(damage.to, "he") then
			tos:append(damage.to)
		end
		local to = room:askForPlayerChosen(player, tos, skill:objectName(), "kesxfenghun-ask", true, true)
		if not to then return false end
		ctx.targets:append(to)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local to = ctx.targets:first()
		room:broadcastSkillInvoke(skill:objectName())
		local to_throw = room:askForCardChosen(player, to, "he", skill:objectName())
		local card = sgs.Sanguosha:getCard(to_throw)
		room:throwCard(card, to, player)
		if card:getSuit() == sgs.Card_Diamond then
			local damage = ctx.original_data:toDamage()
			damage.damage = 1 + damage.damage
			ctx.original_data:setValue(damage)
		end
		return false
	end,
}
kesxmayunlu:addSkill(kesxfenghun)

kesxmayunlu:addSkill("mashu")

sgs.LoadTranslationTable {

	["kesxmayunlu"] = "马云騄[震]",
	["&kesxmayunlu"] = "马云騄",
	["#kesxmayunlu"] = "剑胆琴心",
	["designer:kesxmayunlu"] = "官方",
	["cv:kesxmayunlu"] = "官方",
	["illustrator:kesxmayunlu"] = "叶碧芳",

	["kesxfenghun"] = "凤魂",
	["kesxfenghun-ask"] = "你可以发动“凤魂”弃置你或目标一张牌",
	[":kesxfenghun"] = "当你使用【杀】对目标角色造成伤害时，你可以弃置你或其一张牌，若此牌为♦，此伤害+1。",

	["$kesxfenghun1"] = "贼人是不是被本姑娘给吓破胆了呀？",
	["$kesxfenghun2"] = "看我不好好杀杀你的威风！",

	["~kesxmayunlu"] = "子龙哥哥，救我~",
}

kesxmateng = sgs.General(kearmsxfyzhen, "kesxmateng$", "qun", 4, true)

kesxxiongyiCard = sgs.CreateSkillCard {
	name = "kesxxiongyiCard",
	will_throw = false,
	filter = function(self, selected, to_select, player)
		return (#selected < 99)
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@kesxxiongyi")
		room:doSuperLightbox(source, self:getSkillName())
		while #targets > 0 do
			for _, p in ipairs(targets) do
				local cantargets = sgs.SPlayerList()
				for _, pp in sgs.qlist(room:getAllPlayers()) do
					if p:canSlash(pp, false) then
						cantargets:append(pp)
					end
				end
				if not room:askForUseSlashTo(p, cantargets, "kesxxiongyi-ask", true, false, false, nil, nil, "kesxxiongyiflag") then
					return
				end
			end
		end
	end,
}
kesxxiongyiVS = sgs.CreateViewAsSkillV2 {
	name = "kesxxiongyi",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:getMark("@kesxxiongyi") >= 1
	end,
	create_card = function(skill, request)
		return kesxxiongyiCard:clone()
	end,
}

kesxxiongyi = sgs.CreateTriggerSkillV2 {
	name = "kesxxiongyi",
	view_as_skill = kesxxiongyiVS,
	events = { sgs.TargetConfirmed, sgs.TargetSpecified },
	frequency = sgs.Skill_Limited,
	limit_mark = "@kesxxiongyi",
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.TargetSpecified then return end
		local owner = ctx.owner
		if not (owner and owner:objectName() == player:objectName()) then return end
		local use = ctx.original_data:toCardUse()
		if use.card:isKindOf("Slash") and use.card:hasFlag("kesxxiongyiflag") then
			local log = sgs.LogMessage()
			log.type = "$kesxxiongyilog"
			log.from = player
			room:sendLog(log)
			local no_respond_list = use.no_respond_list
			for _, szm in sgs.qlist(use.to) do
				table.insert(no_respond_list, szm:objectName())
			end
			use.no_respond_list = no_respond_list
			ctx.original_data:setValue(use)
		end
	end,
}
kesxmateng:addSkill(kesxxiongyi)

kesxmateng:addSkill("mashu")
kesxyouqiCard = sgs.CreateSkillCard {
	name = "kesxyouqiCard",
	--target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if #targets < 1 and to_select:getKingdom() == "qun" then
			return to_select:getOffensiveHorse() ~= nil or to_select:getDefensiveHorse() ~= nil
		elseif #targets == 1 then
			return targets[1]:getOffensiveHorse() and not to_select:getOffensiveHorse() and to_select:hasOffensiveHorseArea()
				or targets[1]:getDefensiveHorse() and not to_select:getDefensiveHorse() and to_select:hasDefensiveHorseArea()
		end
	end,
	feasible = function(self, targets, player)
		return #targets == 2
	end,
	about_to_use = function(self, room, use)
		room:setTag("kesxyouqiUse", ToData(use))
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		local use = room:getTag("kesxyouqiUse"):toCardUse()
		local to1 = use.to:at(0)
		local to2 = use.to:at(1)
		local ids = sgs.IntList()
		for _, e in sgs.list(to1:getEquips()) do
			if e:isKindOf("Horse") then
				local n = e:getRealCard():toEquipCard():location()
				if to2:hasEquipArea(n) and not to2:getEquip(n) then
					continue
				end
			end
			ids:append(e:getEffectiveId())
		end
		local id = room:askForCardChosen(source, to1, "e", "kesxyouqi", false, sgs.Card_MethodNone, ids)
		if id > -1 and to2:isAlive() then
			room:moveCardTo(sgs.Sanguosha:getCard(id), to2, sgs.Player_PlaceEquip)
		end
	end,
}

kesxyouqivs = sgs.CreateViewAsSkillV2 {
	name = "kesxyouqi",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@kesxyouqi"
	end,
	create_card = function(skill, request)
		return kesxyouqiCard:clone()
	end,
}

kesxyouqi = sgs.CreateTriggerSkillV2 {
	name = "kesxyouqi$",
	events = { sgs.EventPhaseStart },
	view_as_skill = kesxyouqivs,
	can_trigger = function(skill, event, room, player, data)
		if not ((event == sgs.EventPhaseStart) and player:hasLordSkill(skill:objectName()) and (player:getPhase() == sgs.Player_Start)) then
			return false
		end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getKingdom() == "qun" and (p:getOffensiveHorse() or p:getDefensiveHorse()) then
				--检查能否移到其他角色的区域内
				for _, pto in sgs.qlist(room:getOtherPlayers(p)) do
					if
						(p:getOffensiveHorse() and pto:hasOffensiveHorseArea() and not pto:getOffensiveHorse())
						or (p:getDefensiveHorse() and pto:hasDefensiveHorseArea() and not pto:getDefensiveHorse())
					then
						return skill:objectName()
					end
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForUseCard(player, "@@kesxyouqi", "@kesxyouqi", -1, sgs.Card_MethodNone) ~= nil
	end,
}
kesxmateng:addSkill(kesxyouqi)

sgs.LoadTranslationTable {

	["kesxmateng"] = "马腾[震]",
	["&kesxmateng"] = "马腾",
	["#kesxmateng"] = "勇冠西州",
	["designer:kesxmateng"] = "官方",
	["cv:kesxmateng"] = "官方",
	["illustrator:kesxmateng"] = "峰雨同程",

	["kesxxiongyi"] = "雄异",
	["$kesxxiongyilog"] = "%from 的“<font color='yellow'><b>雄异</b></font>”生效，此【杀】不能被响应 ",
	["kesxxiongyi-ask"] = "雄异：你可以使用一张【杀】",
	[":kesxxiongyi"] = "限定技，出牌阶段，你可以令任意名角色依次选择是否使用一张【杀】且此【杀】不能被响应，然后这些角色重复此流程，直到其中一名角色选择否。",

	["kesxyouqi"] = "游骑",
	["@kesxyouqi"] = "你可以发动“游骑”移动一名角色的坐骑牌",
	[":kesxyouqi"] = "主公技，准备阶段，你可以将一名群势力角色装备区内的一张坐骑牌移动到另一名角色的装备区。",

	["$kesxxiongyi1"] = "集众人之力，成群雄霸业！",
	["$kesxxiongyi2"] = "将士们，随我起事！",

	["~kesxmateng"] = "逆子无谋，祸及全族。",
}

kesxsunhao = sgs.General(kearmsxfyzhen, "kesxsunhao$", "wu", 5, true)

kesxcanshi = sgs.CreateTriggerSkillV2 {
	name = "kesxcanshi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DrawNCards, sgs.TargetSpecifying },
	on_record = function(skill, event, room, player, ctx)
		local owner = ctx.owner
		if not (owner and owner:objectName() == player:objectName()) then return end
		if event == sgs.DrawNCards then
			local draw = ctx.original_data:toDraw()
			if draw.reason ~= "draw_phase" then
				return
			end
			room:sendCompulsoryTriggerLog(player, skill)
			local nnn = 0
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:isWounded() then
					nnn = nnn + 1
				end
			end
			draw.num = math.max(1, nnn)
			ctx.original_data:setValue(draw)
			room:setPlayerMark(player, "&kesxcanshi-Clear", 1)
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if (event == sgs.TargetSpecifying) and (player:getMark("&kesxcanshi-Clear") > 0) then
			local use = data:toCardUse()
			if use.card and (use.card:isKindOf("Slash") or use.card:isNDTrick()) then
				for _, p in sgs.qlist(use.to) do
					if p:isWounded() and player:canDiscard(player, "he") then
						return skill:objectName()
					end
				end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:askForDiscard(player, skill:objectName(), 1, 1, false, true, "kesxcanshi-ask")
		return false
	end,
}
kesxsunhao:addSkill(kesxcanshi)

kesxsunhao:addSkill("chouhai")
kesxsunhao:addSkill("guiming")

sgs.LoadTranslationTable {

	["kesxsunhao"] = "孙皓[震]",
	["&kesxsunhao"] = "孙皓",
	["#kesxsunhao"] = "时日曷丧",
	["designer:kesxsunhao"] = "官方",
	["cv:kesxsunhao"] = "官方",
	["illustrator:kesxsunhao"] = "LiuHeng",

	["kesxcanshi"] = "残蚀",
	["kesxcanshi-ask"] = "残蚀：请弃置一张牌",
	[":kesxcanshi"] = "锁定技，摸牌阶段，你令摸牌数改为已受伤角色数且至少为1，然后你本回合使用【杀】或普通锦囊牌指定已受伤角色为目标时，你弃置一张牌。",

	["$kesxcanshi1"] = "众人与蝼蚁何异？哼哼哼...",
	["$kesxcanshi2"] = "难道一切不在朕手中？",

	["~kesxsunhao"] = "命啊，命！",
}

kesxluotong = sgs.General(kearmsxfyzhen, "kesxluotong", "wu", 3, true)

kesxjinjian = sgs.CreateTriggerSkillV2 {
	name = "kesxjinjian",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DamageCaused, sgs.DamageInflicted },
	on_record = function(skill, event, room, player, ctx)
		local owner = ctx.owner
		if not (owner and owner:objectName() == player:objectName()) then return end
		if event == sgs.DamageCaused then
			if player:getMark("&kesxjinjianadd-Clear") > 0 then
				room:sendCompulsoryTriggerLog(player, skill)
				local damage = ctx.original_data:toDamage()
				damage.damage = 1 + damage.damage
				ctx.original_data:setValue(damage)
				room:setPlayerMark(player, "&kesxjinjianadd-Clear", 0)
			end
		elseif event == sgs.DamageInflicted then
			if player:getMark("&kesxjinjianmin-Clear") > 0 then
				room:sendCompulsoryTriggerLog(player, skill)
				local damage = ctx.original_data:toDamage()
				damage.damage = 1 + damage.damage
				ctx.original_data:setValue(damage)
				room:setPlayerMark(player, "&kesxjinjianmin-Clear", 0)
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.DamageCaused then
			if player:getMark("&kesxjinjianadd-Clear") == 0
				and player:getMark("kesxjinjianhit-Clear") == 0 then
				return skill:objectName()
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from and player:getMark("&kesxjinjianmin-Clear") == 0
				and player:getMark("kesxjinjianbehit-Clear") == 0 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if event == sgs.DamageCaused then
			return player:askForSkillInvoke(skill:objectName(), ToData("kesxjinjian0:" .. damage.to:objectName()))
		else
			return player:askForSkillInvoke(skill:objectName(), ToData("kesxjinjian1:" .. damage.from:objectName()))
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		if event == sgs.DamageCaused then
			room:setPlayerMark(player, "kesxjinjianhit-Clear", 1)
			room:setPlayerMark(player, "&kesxjinjianadd-Clear", 1)
		else
			room:setPlayerMark(player, "kesxjinjianbehit-Clear", 1)
			room:setPlayerMark(player, "&kesxjinjianmin-Clear", 1)
		end
		return true
	end,
}
kesxluotong:addSkill(kesxjinjian)

kesxrenzheng = sgs.CreateTriggerSkillV2 {
	name = "kesxrenzheng",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageComplete },
	on_record = function(skill, event, room, player, ctx)
		local owner = ctx.owner
		if not owner then return end
		if event == sgs.DamageComplete then
			local damage = ctx.original_data:toDamage()
			if damage.prevented then
				room:sendCompulsoryTriggerLog(owner, skill)
				room:getCurrent():drawCards(1, skill:objectName())
			end
		end
	end,
}
kesxluotong:addSkill(kesxrenzheng)

sgs.LoadTranslationTable {

	["kesxluotong"] = "骆统[震]",
	["&kesxluotong"] = "骆统",
	["#kesxluotong"] = "蹇谔匪躬",
	["designer:kesxluotong"] = "官方",
	["cv:kesxluotong"] = "官方",
	["illustrator:kesxluotong"] = "第七个桔子",

	["kesxjinjian"] = "进谏",
	["kesxjinjian:kesxjinjian0"] = "你将对 %src 造成伤害，你可以发动“进谏”防止此伤害",
	["kesxjinjian:kesxjinjian1"] = "%src 将对你造成伤害，你可以发动“进谏”防止此伤害",
	["kesxjinjianadd"] = "进谏加伤",
	["kesxjinjianmin"] = "进谏减伤",
	[":kesxjinjian"] = "每回合各限一次，当你受到/造成伤害时，你可以防止此伤害，然后你本回合下次受到伤害/造成伤害时，此伤害+1。",

	["kesxrenzheng"] = "仁政",
	[":kesxrenzheng"] = "锁定技，每次伤害结算后，若此伤害已被防止，你令当前回合角色摸一张牌。",

	["$kesxjinjian1"] = "臣有一言，藏之如鲠在喉，今不吐不快！",
	["$kesxjinjian2"] = "胥吏者，百姓之所倚、天子之所期，焉能哑然？",
	["$kesxrenzheng1"] = "兴亡百姓皆苦，统之所愿者，苦尽而甘来也。",
	["$kesxrenzheng2"] = "政之施者当可克仁而为之，如此方成大同。",

	["~kesxluotong"] = "上愧天子，下愧百姓，焉能苟活？ ",
}

kesxyanghu = sgs.General(kearmsxfyzhen, "kesxyanghu", "wei", 4, true)

kesxmingfaCard = sgs.CreateSkillCard {
	name = "kesxmingfaCard",
	filter = function(self, targets, to_select, player)
		return (#targets < 1) and (to_select:getHp() > 1)
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:damage(sgs.DamageStruct("kesxmingfa", player, target))
		room:setPlayerMark(player, "&usekesxmingfa", 1)
		room:setPlayerMark(player, "usekesxmingfa" .. target:objectName(), 1)
		room:setPlayerMark(target, "&kesxmingfa", 1)
	end,
}
--主技能
kesxmingfaVS = sgs.CreateViewAsSkillV2 {
	name = "kesxmingfa",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:getMark("&usekesxmingfa") == 0
	end,
	create_card = function(skill, request)
		return kesxmingfaCard:clone()
	end,
}

kesxmingfa = sgs.CreateTriggerSkillV2 {
	name = "kesxmingfa",
	view_as_skill = kesxmingfaVS,
	events = { sgs.Death, sgs.HpRecover },
	on_record = function(skill, event, room, player, ctx)
		if event == sgs.HpRecover then
			local rec = ctx.original_data:toRecover()
			if rec.who:getMark("&kesxmingfa") > 0 then
				room:setPlayerMark(rec.who, "&kesxmingfa", 0)
				for _, yh in sgs.qlist(room:getAllPlayers()) do
					if yh:getMark("usekesxmingfa" .. rec.who:objectName()) > 0 then
						room:setPlayerMark(yh, "usekesxmingfa" .. rec.who:objectName(), 0)
						room:setPlayerMark(yh, "&usekesxmingfa", 0)
					end
				end
			end
		elseif event == sgs.Death then
			local death = ctx.original_data:toDeath()
			if death.who:getMark("&kesxmingfa") > 0 then
				room:setPlayerMark(death.who, "&kesxmingfa", 0)
				for _, yh in sgs.qlist(room:getAllPlayers()) do
					if yh:getMark("usekesxmingfa" .. death.who:objectName()) > 0 then
						room:setPlayerMark(yh, "usekesxmingfa" .. death.who:objectName(), 0)
						room:setPlayerMark(yh, "&usekesxmingfa", 0)
					end
				end
			end
		end
	end,
}
kesxyanghu:addSkill(kesxmingfa)

sgs.LoadTranslationTable {

	["kesxyanghu"] = "羊祜[震]",
	["&kesxyanghu"] = "羊祜",
	["#kesxyanghu"] = "制纮同轨",
	["designer:kesxyanghu"] = "官方",
	["cv:kesxyanghu"] = "官方",
	["illustrator:kesxyanghu"] = "芝芝不加糖",

	["kesxmingfa"] = "明伐",
	["usekesxmingfa"] = "明伐失效",
	[":kesxmingfa"] = "出牌阶段，你可以对一名体力值大于1的角色造成1点伤害，然后本技能失效直到其死亡或回复体力。",

	["$kesxmingfa1"] = "以诚相待，吴人倾心，攻之必克。",
	["$kesxmingfa2"] = "以强击弱，易如反掌，何须诡诈？",

	["~kesxyanghu"] = "憾东吴尚存，天下未定也。",
}

kesxlvlingqi = sgs.General(kearmsxfyzhen, "kesxlvlingqi", "qun", 4, false)

kesxhuiji = sgs.CreateTriggerSkillV2 {
	name = "kesxhuiji",
	events = { sgs.TargetSpecifying, sgs.CardAsked, sgs.CardFinished, sgs.CardEffected },
	frequency = sgs.Skill_Frequent,
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player:isAlive()) then return end
		--清除
		if event == sgs.CardFinished then
			local use = ctx.original_data:toCardUse()
			if use.card:hasFlag("kesxhuijiflag") then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p, "&kesxhuiji-Clear", 0)
				end
			end
		elseif event == sgs.CardEffected then
			local effect = ctx.original_data:toCardEffect()
			if effect.card:hasFlag("kesxhuijiflag") then
				player:setFlags("kesxhuijiAsked")
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.CardAsked then
			if not player:hasFlag("kesxhuijiAsked") then return false end
			local pattern = data:toStringList()
			if pattern[1] ~= "jink" or pattern[2] == "kesxhuiji-help" or pattern[3] ~= "use" then
				return false
			end
			local names, owners = {}, {}
			for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				table.insert(names, skill:objectName())
				table.insert(owners, p:objectName())
			end
			if #owners > 0 then
				return table.concat(names, "|"), table.concat(owners, "|")
			end
			return false
		elseif (event == sgs.TargetSpecifying) and player:hasSkill(skill:objectName()) then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if (not use.to:contains(p)) and player:canSlash(p, use.card, true) then
						return skill:objectName()
					end
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.CardAsked then
			local invoker = ctx.invoker
			invoker:setFlags("-kesxhuijiAsked")
			local lieges = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(invoker)) do
				if p:getMark("&kesxhuiji-Clear") > 0 then
					lieges:append(p)
				end
			end
			if lieges:isEmpty() then return false end
			return invoker:askForSkillInvoke(skill, ctx.original_data, false)
		elseif event == sgs.TargetSpecifying then
			local use = ctx.original_data:toCardUse()
			local extargets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if (not use.to:contains(p)) and player:canSlash(p, use.card, true) then
					extargets:append(p)
				end
			end
			local enys = room:askForPlayersChosen(player, extargets, skill:objectName(), 0, 2, "kesxhuiji-ask", true, false)
			if enys:isEmpty() then return false end
			for _, q in sgs.qlist(enys) do
				ctx.targets:append(q)
			end
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.CardAsked then
			local invoker = ctx.invoker
			for _, fri in sgs.qlist(room:getOtherPlayers(invoker)) do
				if fri:getMark("&kesxhuiji-Clear") > 0 then
					local jink = room:askForUseCard(fri, "jink", "kesxhuiji-help:" .. invoker:objectName(), -1, sgs.Card_MethodUse, false, invoker)
					if jink then
						room:provide(jink)
						return true
					end
				end
			end
			return false
		elseif event == sgs.TargetSpecifying then
			room:broadcastSkillInvoke(skill:objectName())
			local use = ctx.original_data:toCardUse()
			room:setCardFlag(use.card, "kesxhuijiflag")
			for _, q in sgs.qlist(ctx.targets) do
				use.to:append(q)
			end
			room:sortByActionOrder(use.to)
			ctx.original_data:setValue(use)
			for _, qq in sgs.qlist(use.to) do
				room:setPlayerMark(qq, "&kesxhuiji-Clear", 1)
			end
		end
		return false
	end,
}
kesxlvlingqi:addSkill(kesxhuiji)

sgs.LoadTranslationTable {

	["kesxlvlingqi"] = "吕玲绮[震]",
	["&kesxlvlingqi"] = "吕玲绮",
	["#kesxlvlingqi"] = "无双虓姬",
	["designer:kesxlvlingqi"] = "官方",
	["cv:kesxlvlingqi"] = "官方",
	["illustrator:kesxlvlingqi"] = "匠人绘",

	["kesxhuiji"] = "挥戟",
	[":kesxhuiji"] = "当你使用【杀】指定目标时，你可以令至多两名角色成为此【杀】的额外目标，然后当此【杀】的目标需要响应此【杀】时，其可以令其余目标选择是否代替其使用【闪】。",
	["kesxhuiji-ask"] = "挥戟：你可以为此【杀】额外指定两名目标",

	["$kesxhuiji1"] = "虓女暴怒发冲冠，画戟刃过惊雷断！",
	["$kesxhuiji2"] = "纵马执戟冲敌阵，天下谁人敢当锋！",

	["~kesxlvlingqi"] = "戟断马亡，此地竟是我的葬身之处吗？",
}

kesxzhouchu = sgs.General(kearmsxfyzhen, "kesxzhouchu", "wu", 4, true)

kesxxiongxiaCard = sgs.CreateSkillCard {
	name = "kesxxiongxiaCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:addSubcards(self:getSubcards())
		duel:setSkillName("kesxxiongxia")
		duel:deleteLater()
		return #targets < 2 and duel:targetFilter(sgs.PlayerList(), to_select, source)
	end,
	feasible = function(self, targets, player)
		return #targets == 2
	end,
	about_to_use = function(self, room, use)
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:addSubcards(self:getSubcards())
		duel:setSkillName("kesxxiongxia")
		use.card = duel
		room:useCard(use, true)
		duel:deleteLater()
	end,
}

kesxxiongxiaVS = sgs.CreateViewAsSkillV2 {
	name = "kesxxiongxia",
	n = 2,
	response_or_use = true,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:getMark("&bankesxxiongxia-Clear") < 1 and player:getCardCount() > 1
	end,
	card_selection_feasible = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 2 then return false end
		local player = request:getInitiator()
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:addSubcards(ids)
		duel:setSkillName("kesxxiongxia")
		duel:deleteLater()
		return not player:isLocked(duel)
	end,
	create_card = function(skill, request)
		local card = kesxxiongxiaCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		return card
	end,
}

kesxxiongxia = sgs.CreateTriggerSkillV2 {
	name = "kesxxiongxia",
	view_as_skill = kesxxiongxiaVS,
	events = { sgs.CardFinished },
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.CardFinished then return end
		local owner = ctx.owner
		if not (owner and owner:objectName() == player:objectName()) then return end
		local use = ctx.original_data:toCardUse()
		if table.contains(use.card:getSkillNames(), "kesxxiongxia") then
			for _, q in sgs.qlist(use.to) do
				if not use.card:hasFlag("DamageDone_" .. q:objectName()) then
					return
				end
			end
			room:setPlayerMark(player, "&bankesxxiongxia-Clear", 1)
		end
	end,
}
kesxzhouchu:addSkill(kesxxiongxia)

sgs.LoadTranslationTable {

	["kesxzhouchu"] = "周处[震]",
	["&kesxzhouchu"] = "周处",
	["#kesxzhouchu"] = "英情天逸",
	["designer:kesxzhouchu"] = "官方",
	["cv:kesxzhouchu"] = "官方",
	["illustrator:kesxzhouchu"] = "MUMU",

	["kesxxiongxia"] = "兇侠",
	["bankesxxiongxia"] = "兇侠失效",
	[":kesxxiongxia"] = "出牌阶段，你可以将两张牌当【决斗】对两名其他角色使用，此牌结算后，若此牌对所有目标角色均造成过伤害，本技能失效直到本回合结束。",

	["$kesxxiongxia1"] = "入林射猛虎，投水斩孽蛟！",
	["$kesxxiongxia2"] = "此害不除，焉除三害！",

	["~kesxzhouchu"] = "刹那遭罪，殃堕无间……",
}

sxfygen = sgs.Package("sxfygen", sgs.Package_GeneralPack)

sx_guanxing = sgs.General(sxfygen, "sx_guanxing", "shu", 4)

sxwuyouCard = sgs.CreateSkillCard {
	name = "sxwuyouCard",
	filter = function(self, targets, to_select, source)
		return #targets < 1 and to_select ~= source and source:canPindian(to_select)
	end,
	on_use = function(self, room, player, targets)
		for _, p in sgs.list(targets) do
			if player:canPindian(p) then
				local n = player:pindianInt(p, self:getSkillName())
				local from, to = player, p
				if n < 1 then
					room:acquireOneTurnSkills(player, self:getSkillName(), "wusheng")
					from, to = p, player
				end
				if n == 0 then
					continue
				end
				local dc = dummyCard("duel")
				dc:setSkillName("_sxwuyou")
				if from:canUse(dc, to) then
					room:useCard(sgs.CardUseStruct(dc, from, to))
				end
			end
		end
	end,
}
sxwuyou = sgs.CreateViewAsSkillV2 {
	name = "sxwuyou",
	n = 0,
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:canPindian()
	end,
	create_card = function(skill, request)
		return sxwuyouCard:clone()
	end,
}
sx_guanxing:addSkill(sxwuyou)

sx_jiangwan = sgs.General(sxfygen, "sx_jiangwan", "shu", 3)

sxbeiwuVS = sgs.CreateViewAsSkillV2 {
	name = "sxbeiwu",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:hasEquip()
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		return candidate:isEquipped() and player:getMark(candidate:toString() .. "sxbeiwu-Clear") < 1
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		local name = request:getUserString()
		if name ~= "ex_nihilo" and name ~= "duel" then return nil end
		local dc = sgs.Sanguosha:cloneCard(name)
		if not dc then return nil end
		for _, c in sgs.qlist(ids) do
			dc:addSubcard(c)
		end
		dc:setSkillName("sxbeiwu")
		return dc
	end,
}
sxbeiwu = sgs.CreateTriggerSkillV2 {
	name = "sxbeiwu",
	view_as_skill = sxbeiwuVS,
	events = { sgs.CardsMoveOneTime },
	juguan_type = "ex_nihilo,duel",
	on_record = function(skill, event, room, player, ctx)
		local owner = ctx.owner
		if not (owner and owner:objectName() == player:objectName()) then return end
		if event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			if move.to_place == sgs.Player_PlaceEquip and move.to:objectName() == player:objectName() then
				for _, id in sgs.qlist(move.card_ids) do
					room:setPlayerMark(player, id .. "sxbeiwu-Clear", 1)
				end
			end
		end
	end,
}
sx_jiangwan:addSkill(sxbeiwu)
sxchengshi = sgs.CreateTriggerSkillV2 {
	name = "sxchengshi",
	events = { sgs.Death },
	frequency = sgs.Skill_Limited,
	limit_mark = "@sxchengshi",
	can_trigger = function(skill, event, room, player, data)
		if (event == sgs.Death) and player:hasSkill(skill:objectName()) and player:getMark("@sxchengshi") > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local death = ctx.original_data:toDeath()
		if player:askForSkillInvoke(skill, death.who) then
			ctx.targets:append(death.who)
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local who = ctx.targets:first()
		room:removePlayerMark(player, "@sxchengshi")
		player:peiyin("mobileyanjincui")
		room:doSuperLightbox(player, skill:objectName())
		room:swapSeat(player, who)
		room:swapCards(player, who, "e", skill:objectName())
		return false
	end,
}
sx_jiangwan:addSkill(sxchengshi)

sx_maliang = sgs.General(sxfygen, "sx_maliang", "shu", 3)

sxxiemuCard = sgs.CreateSkillCard {
	name = "sxxiemuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, source)
		return #targets < 1 and to_select:hasSkill("sxxiemu")
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("xiemu")
		for _, p in sgs.list(targets) do
			if p:isAlive() then
				room:showCard(player, self:getEffectiveId())
				room:giveCard(player, p, self, self:getSkillName(), true)
				room:addPlayerMark(player, "&sxxiemubf-Clear")
			end
		end
	end,
}
sxxiemuvs = sgs.CreateViewAsSkillV2 {
	name = "sxxiemuvs&",
	n = 1,
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_card = function(skill, request, candidate)
		return request:getSelectedCardIds():isEmpty() and candidate:getTypeId() == 1
	end,
	create_card = function(skill, request)
		local card = sxxiemuCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		return card
	end,
}
sxfygen:addSkills(sxxiemuvs)
sxxiemu = sgs.CreateTriggerSkillV2 {
	name = "sxxiemu",
	events = { sgs.EventPhaseChanging },
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player:isAlive()) then return end
		if event == sgs.EventPhaseChanging then
			local change = ctx.original_data:toPhaseChange()
			if change.to == sgs.Player_Play then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasSkill(skill:objectName(), true) and kesxV2RecordOnce(room, skill, ctx) then
						room:attachSkillToPlayer(player, "sxxiemuvs")
						break
					end
				end
			end
			if change.from >= sgs.Player_Play then
				if player:hasSkill("sxxiemuvs", true) then
					room:detachSkillFromPlayer(player, "sxxiemuvs", true)
				end
			end
		end
	end,
}
sx_maliang:addSkill(sxxiemu)
sxxiemubf = sgs.CreateAttackRangeSkillV2 {
	name = "#sxxiemubf",
	correct_func = function(skill, ctx)
		return ctx:getHolder():getMark("&sxxiemubf-Clear")
	end,
}
sx_maliang:addSkill(sxxiemubf)
sxnamanCard = sgs.CreateSkillCard {
	name = "sxnamanCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, source)
		local dc = sgs.Sanguosha:cloneCard("savage_assault")
		dc:addSubcards(self:getSubcards())
		dc:setSkillName("sxnaman")
		dc:deleteLater()
		return source ~= to_select and #targets < self:subcardsLength() and not source:isProhibited(to_select, dc)
	end,
	about_to_use = function(self, room, use)
		local dc = sgs.Sanguosha:cloneCard("savage_assault")
		dc:addSubcards(self:getSubcards())
		dc:setSkillName("sxnaman")
		use.card = dc
		self:cardOnUse(room, use)
		dc:deleteLater()
	end,
}
sxnaman = sgs.CreateViewAsSkillV2 {
	name = "sxnaman",
	n = 998,
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		return candidate:getTypeId() == 1 and request:getSelectedCardIds():length() < player:getAliveSiblings():length()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local card = sxnamanCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		return card
	end,
}
sx_maliang:addSkill(sxnaman)

sx_xushu = sgs.General(sxfygen, "sx_xushu", "shu", 3)
sxwuyan = sgs.CreateFilterSkill {
	name = "sxwuyan",
	view_filter = function(self, card)
		return card:isKindOf("TrickCard") and card:objectName() ~= "nullification"
	end,
	view_as = function(self, card)
		local ex = sgs.Sanguosha:cloneCard("nullification", card:getSuit(), card:getNumber())
		ex:setSkillName("sxwuyan")
		--local wrap = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
		--wrap:takeOver(ex)
		return ex
	end,
}
sx_xushu:addSkill(sxwuyan)
sxjujian = sgs.CreateTriggerSkillV2 {
	name = "sxjujian",
	events = { sgs.CardFinished, sgs.CardUsed },
	on_record = function(skill, event, room, player, ctx)
		local owner = ctx.owner
		if not (owner and owner:objectName() == player:objectName()) then return end
		if event == sgs.CardUsed then
			local use = ctx.original_data:toCardUse()
			if use.card and use.card:isKindOf("Nullification") then
				room:setCardFlag(use.card, "sxjujianbf")
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.CardFinished then return false end
		local use = data:toCardUse()
		if use.card and use.card:hasFlag("sxjujianbf") and player:getMark("sxjujian-Clear") < 1
			and player:hasTurn() and room:getCardPlace(use.card:getEffectiveId()) == sgs.Player_DiscardPile then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "sxjujian0:", true, true)
		if not to then return false end
		ctx.targets:append(to)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local to = ctx.targets:first()
		local use = ctx.original_data:toCardUse()
		player:addMark("sxjujian-Clear")
		player:peiyin("jujian")
		room:giveCard(player, to, use.card, skill:objectName())
		return false
	end,
}
sx_xushu:addSkill(sxjujian)

sx_zhonghui = sgs.General(sxfygen, "sx_zhonghui", "wei", 4)
sxxingfa = sgs.CreateTriggerSkillV2 {
	name = "sxxingfa",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start
			and player:getHandcardNum() >= player:getHp() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "sxxingfa0:", true, true)
		if not to then return false end
		ctx.targets:append(to)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("paiyi")
		room:damage(sgs.DamageStruct(skill:objectName(), player, ctx.targets:first()))
		return false
	end,
}
sx_zhonghui:addSkill(sxxingfa)

sx_wangyuanji = sgs.General(sxfygen, "sx_wangyuanji", "wei", 3, false)

sxqianchong = sgs.CreateTargetModSkillV2 {
	name = "sxqianchong",
	pattern = ".",
	correct_func = function(skill, ctx)
		local from = ctx:getPrimary()
		if not from then return false end
		if ctx:getModType() == sgs.TargetModSkill_Residue then
			if from:hasSkill("sxqianchong") and from:getEquips():length() % 2 == 1 then
				return 1000
			end
			if from:getMark("&sxjuezhu-Clear") > 0 then
				return 1000
			end
			return false
		elseif ctx:getModType() == sgs.TargetModSkill_DistanceLimit then
			if from:hasSkill("sxqianchong") and from:getEquips():length() % 2 == 0 then
				return 1000
			end
			return false
		end
		return false
	end,
}
sx_wangyuanji:addSkill(sxqianchong)
sxshangjian = sgs.CreateTriggerSkillV2 {
	name = "sxshangjian",
	events = { sgs.EventPhaseStart, sgs.CardsMoveOneTime },
	on_record = function(skill, event, room, player, ctx)
		local owner = ctx.owner
		if not (owner and owner:objectName() == player:objectName()) then return end
		if event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			if (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and move.from:objectName() == player:objectName() then
				for i, id in sgs.qlist(move.card_ids) do
					if move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip then
						room:addPlayerMark(player, "&sxshangjian-Clear")
						player:addMark(id .. "sxshangjian-Clear")
					end
				end
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseStart then return false end
		if player:getPhase() == sgs.Player_Finish and player:getMark("&sxshangjian-Clear") <= player:getHp() then
			for i, id in sgs.qlist(room:getDiscardPile()) do
				if player:getMark(id .. "sxshangjian-Clear") > 0 then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local ids = sgs.IntList()
		for i, id in sgs.qlist(room:getDiscardPile()) do
			if player:getMark(id .. "sxshangjian-Clear") > 0 then
				ids:append(id)
			end
		end
		if ids:isEmpty() then return false end
		room:fillAG(ids, player)
		if not player:askForSkillInvoke(skill, ToData(ids)) then
			room:clearAG(player)
			return false
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local ids = sgs.IntList()
		for i, id in sgs.qlist(room:getDiscardPile()) do
			if player:getMark(id .. "sxshangjian-Clear") > 0 then
				ids:append(id)
			end
		end
		player:peiyin("shangjian")
		local id = room:askForAG(player, ids, false, skill:objectName())
		room:obtainCard(player, id)
		room:clearAG(player)
		return false
	end,
}
sx_wangyuanji:addSkill(sxshangjian)

sx_xuezong = sgs.General(sxfygen, "sx_xuezong", "wu", 3)
sxfunan = sgs.CreateTriggerSkillV2 {
	name = "sxfunan",
	events = { sgs.CardOffset },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if effect.card:getTypeId() > 0 and effect.card:getEffectiveId() > -1 and room:getCardOwner(effect.card:getEffectiveId()) == nil then
				local use = room:getUseStruct(effect.offset_card)
				if use.from and use.from ~= player and use.from:isAlive()
					and use.from:getMark("sxfunan-Clear") < 1 and player:hasTurn()
					and use.from:hasSkill(skill:objectName()) then
					return skill:objectName(), use.from
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local effect = ctx.original_data:toCardEffect()
		player:addMark("sxfunan-Clear")
		player:peiyin("funan")
		player:obtainCard(effect.card)
		return false
	end,
}
sx_xuezong:addSkill(sxfunan)
sxjiexun = sgs.CreateTriggerSkillV2 {
	name = "sxjiexun",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseStart or player:getPhase() ~= sgs.Player_Finish then return false end
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:canDiscard(p, "h") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local tos = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:canDiscard(p, "h") then
				tos:append(p)
			end
		end
		local to = room:askForPlayerChosen(player, tos, skill:objectName(), "sxjiexun0:", true, true)
		if not to then return false end
		ctx.targets:append(to)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local to = ctx.targets:first()
		player:peiyin("jiexun")
		local dc = room:askForDiscard(to, skill:objectName(), 1, 1)
		if dc and dc:getSuit() == 3 then
			to:drawCards(2, skill:objectName())
		end
		return false
	end,
}
sx_xuezong:addSkill(sxjiexun)

sx_sunshao = sgs.General(sxfygen, "sx_sunshao", "wu", 3)
sxdingyi = sgs.CreateTriggerSkillV2 {
	name = "sxdingyi",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:getEquips():length() < 1 then
			local names, owners = {}, {}
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasSkill(skill:objectName()) then
					table.insert(names, skill:objectName())
					table.insert(owners, p:objectName())
				end
			end
			if #owners > 0 then
				return table.concat(names, "|"), table.concat(owners, "|")
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return ctx.invoker:askForSkillInvoke(skill:objectName())
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("fourthmobilezhidingyi")
		ctx.invoker:drawCards(1, skill:objectName())
		return false
	end,
}
sx_sunshao:addSkill(sxdingyi)
sxzuici = sgs.CreateTriggerSkillV2 {
	name = "sxzuici",
	events = { sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.Damaged then return false end
		local damage = data:toDamage()
		if not (damage.from and damage.from:isAlive()) then return false end
		for _, p in sgs.qlist(room:getOtherPlayers(damage.from)) do
			for _, c in sgs.qlist(p:getCards("ej")) do
				if player:isProhibited(damage.from, c) then
					continue
				end
				if c:isKindOf("EquipCard") then
					local n = c:getRealCard():toEquipCard():location()
					if damage.from:getEquip(n) then
						continue
					end
				end
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local tos = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(damage.from)) do
			local has = false
			for _, c in sgs.qlist(p:getCards("ej")) do
				if player:isProhibited(damage.from, c) then
					continue
				end
				if c:isKindOf("EquipCard") then
					local n = c:getRealCard():toEquipCard():location()
					if damage.from:getEquip(n) then
						continue
					end
				end
				has = true
				break
			end
			if has then
				tos:append(p)
			end
		end
		local to = room:askForPlayerChosen(player, tos, skill:objectName(), "sxzuici0:" .. damage.from:objectName(), true, true)
		if not to then return false end
		ctx.targets:append(to)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local to = ctx.targets:first()
		player:peiyin("fourthmobilezhizuici")
		local ids = sgs.IntList()
		for _, c in sgs.qlist(to:getCards("ej")) do
			if player:isProhibited(damage.from, c) then
				ids:append(c:getEffectiveId())
			end
			if c:isKindOf("EquipCard") then
				local n = c:getRealCard():toEquipCard():location()
				if damage.from:getEquip(n) then
					ids:append(c:getEffectiveId())
				end
			end
		end
		local id = room:askForCardChosen(player, to, "ej", skill:objectName(), false, sgs.Card_MethodNone, ids)
		if id > -1 then
			room:moveCardTo(sgs.Sanguosha:getCard(id), damage.from, room:getCardPlace(id), true)
		end
		return false
	end,
}
sx_sunshao:addSkill(sxzuici)

sxfykun = sgs.Package("sxfykun", sgs.Package_GeneralPack)

sx_liuzang = sgs.General(sxfykun, "sx_liuzang$", "qun", 3)

sxyingeCard = sgs.CreateSkillCard {
	name = "sxyingeCard",
	filter = function(self, targets, to_select, source)
		return #targets < 1 and to_select ~= source
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("mobilerenyaohu")
		for _, p in sgs.list(targets) do
			if p:getCardCount() > 0 then
				local dc = room:askForExchange(p, self:getSkillName(), 1, 1, true, "sxyinge0:" .. player:objectName())
				if dc then
					room:giveCard(p, player, dc, self:getSkillName())
					if not p:isAlive() then
						continue
					end
					local tos = sgs.SPlayerList()
					dc = dummyCard()
					dc:setSkillName("_sxyinge")
					for _, q in sgs.list(room:getOtherPlayers(p)) do
						if q == player or player:inMyAttackRange(q) then
							if p:canSlash(q, dc, false) then
								tos:append(q)
							end
						end
					end
					local to = room:askForPlayerChosen(p, tos, self:getSkillName(), "sxyinge1:")
					if to then
						room:useCard(sgs.CardUseStruct(dc, p, to))
					end
				end
			end
		end
	end,
}
sxyinge = sgs.CreateViewAsSkillV2 {
	name = "sxyinge",
	n = 0,
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	create_card = function(skill, request)
		return sxyingeCard:clone()
	end,
}
sx_liuzang:addSkill(sxyinge)
sxshiren = sgs.CreateTriggerSkillV2 {
	name = "sxshiren",
	events = { sgs.TargetConfirmed },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.TargetConfirmed then return false end
		local use = data:toCardUse()
		if use.card:isKindOf("Slash")
			and use.to:contains(player)
			and player:getMark("sxshirenUse-Clear") < 1
			and use.from ~= player
			and player:hasTurn()
		then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		player:peiyin("mobilerenhuaibi")
		player:addMark("sxshirenUse-Clear")
		player:drawCards(2, skill:objectName())
		local dc = room:askForExchange(player, skill:objectName(), 1, 1, true, "sxshiren0:" .. use.from:objectName())
		if dc then
			room:giveCard(player, use.from, dc, skill:objectName())
		end
		return false
	end,
}
sx_liuzang:addSkill(sxshiren)
sxjuyi = sgs.CreateTriggerSkillV2 {
	name = "sxjuyi$",
	events = { sgs.DamageCaused },
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.DamageCaused then return end
		if not (player and player:getKingdom() == "qun") then return end
		local damage = ctx.original_data:toDamage()
		if not (damage.to and ctx.owner == damage.to) then return end
		player:addMark(damage.to:objectName() .. "sxjuyi-Clear")
	end,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.DamageCaused then return false end
		if not (player and player:getKingdom() == "qun") then return false end
		local damage = data:toDamage()
		if player ~= damage.to and damage.to:hasLordSkill(skill:objectName())
			and player:getMark(damage.to:objectName() .. "sxjuyi-Clear") == 1 then
			return skill:objectName(), damage.to
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return ctx.invoker:askForSkillInvoke(skill, player)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		player:peiyin("mobilerenjutu")
		ctx.invoker:damageRevises(ctx.original_data, -damage.damage)
		local id = room:askForCardChosen(ctx.invoker, player, "he", skill:objectName())
		if id > -1 then
			room:obtainCard(ctx.invoker, id)
		end
		return true
	end,
}
sx_liuzang:addSkill(sxjuyi)

sx_liubiao = sgs.General(sxfykun, "sx_liubiao$", "qun", 3)
sxzishou = sgs.CreateTriggerSkillV2 {
	name = "sxzishou",
	events = { sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseChanging then return false end
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("noszishou")
		local ks = {}
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if not table.contains(ks, p:getKingdom()) then
				table.insert(ks, p:getKingdom())
			end
		end
		player:drawCards(#ks, skill:objectName())
		player:skip(sgs.Player_Play)
		return false
	end,
}
sx_liubiao:addSkill(sxzishou)
sxzongshi = sgs.CreateMaxCardsSkillV2 {
	name = "sxzongshi",
	correct_func = function(skill, ctx)
		local target = ctx:getHolder()
		if not (target and target:hasSkill(skill:objectName())) then return 0 end
		local ks = { target:getKingdom() }
		for _, p in sgs.qlist(target:getAliveSiblings()) do
			if not table.contains(ks, p:getKingdom()) then
				table.insert(ks, p:getKingdom())
			end
		end
		return #ks
	end,
}
sx_liubiao:addSkill(sxzongshi)
sxjujing = sgs.CreateTriggerSkillV2 {
	name = "sxjujing$",
	events = { sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.Damaged then return false end
		if not (player and player:isAlive() and player:hasLordSkill(skill:objectName())) then return false end
		local damage = data:toDamage()
		if player ~= damage.from and damage.from and damage.from:getKingdom() == "qum" then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForDiscard(player, skill:objectName(), 2, 2, true, true, "sxjujing0:", ".", skill:objectName())
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin(skill)
		room:recover(player, sgs.RecoverStruct(skill:objectName(), player))
		return false
	end,
}
sx_liubiao:addSkill(sxjujing)

sx_gongsunyuan = sgs.General(sxfykun, "sx_gongsunyuan$", "qun", 4)
sxhuaiyi = sgs.CreateTriggerSkillV2 {
	name = "sxhuaiyi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:getHandcardNum() > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("huaiyi")
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		room:showAllCards(player)
		local hs = player:getHandcards()
		for _, h in sgs.qlist(hs) do
			if h:getColor() ~= hs:first():getColor() then
				local dc = room:askForExchange(player, skill:objectName(), 1, 1, false, "sxhuaiyi0:")
				local rc = dummyCard()
				for _, c in sgs.qlist(hs) do
					if dc:getColor() == c:getColor() and player:canDiscard(player, c:getId()) then
						rc:addSubcard(c)
					end
				end
				room:throwCard(rc, skill:objectName(), player)
				if player:isAlive() then
					local tos = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getCardCount() > 0 then
							tos:append(p)
						end
					end
					tos = room:askForPlayersChosen(player, tos, skill:objectName(), 1, rc:subcardsLength(), "sxhuaiyi1:" .. rc:subcardsLength())
					for _, p in sgs.qlist(tos) do
						room:doAnimate(1, player:objectName(), p:objectName())
					end
					for _, p in sgs.qlist(tos) do
						local id = room:askForCardChosen(player, p, "he", skill:objectName())
						room:obtainCard(player, id)
					end
					if tos:length() > 1 then
						room:loseHp(player, 1, true, player, skill:objectName())
					end
				end
				break
			end
		end
		return false
	end,
}
sx_gongsunyuan:addSkill(sxhuaiyi)
sxfengbai = sgs.CreateTriggerSkillV2 {
	name = "sxfengbai$",
	events = { sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasLordSkill(skill:objectName())) then return false end
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if
				move.to_place == sgs.Player_PlaceHand
				and move.from_places:contains(sgs.Player_PlaceEquip)
				and move.from:objectName() ~= player:objectName()
				and move.to:objectName() == player:objectName()
				and move.from:isAlive()
				and move.from:getKingdom() == "qun"
			then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local from = room:findPlayerByObjectName(move.from:objectName())
		if player:askForSkillInvoke(skill, from) then
			ctx.targets:append(from)
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin(skill)
		ctx.targets:first():drawCards(1, skill:objectName())
		return false
	end,
}
sx_gongsunyuan:addSkill(sxfengbai)

sx_fuhuanghou = sgs.General(sxfykun, "sx_fuhuanghou", "qun", 3, false)
sxzhuikongVS = sgs.CreateViewAsSkillV2 {
	name = "sxzhuikong",
	n = 1,
	expand_pile = "#sxzhuikong",
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@sxzhuikong"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		return player and player:getPileName(candidate:getEffectiveId()) == "#sxzhuikong"
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:isEmpty() then return nil end
		return sgs.Sanguosha:getCard(ids:first())
	end,
}
sxzhuikong = sgs.CreateTriggerSkillV2 {
	name = "sxzhuikong",
	view_as_skill = sxzhuikongVS,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local names, owners = {}, {}
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill(skill:objectName()) and p:canPindian(player) then
					table.insert(names, skill:objectName())
					table.insert(owners, p:objectName())
				end
			end
			if #owners > 0 then
				return table.concat(names, "|"), table.concat(owners, "|")
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local dc = room:askForCard(player, "slash", "sxzhuikong0:" .. ctx.invoker:objectName(), ToData(ctx.invoker), sgs.Card_MethodPindian)
		if not dc then return false end
		ctx.extra_data = ToData(dc:getEffectiveId())
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local dc = sgs.Sanguosha:getCard(ctx.extra_data:toInt())
		player:peiyin("zhuikong")
		player:skillInvoked(skill, 0)
		local pd = player:PinDian(ctx.invoker, skill:objectName(), dc)
		local ids = sgs.IntList()
		local source = player
		if pd.success then
			ids:append(pd.to_card:getEffectiveId())
		else
			source = ctx.invoker
			ids:append(pd.from_card:getEffectiveId())
		end
		if room:getCardOwner(ids:first()) then
			return false
		end
		room:setPlayerMark(source, "sxzhuikongNum", ids:first())
		room:notifyMoveToPile(source, ids, "sxzhuikong")
		room:askForUseCard(source, "@@sxzhuikong", "sxzhuikong1:")
		return false
	end,
}
sx_fuhuanghou:addSkill(sxzhuikong)
sxqiuyuan = sgs.CreateTriggerSkillV2 {
	name = "sxqiuyuan",
	events = { sgs.TargetConfirming },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.TargetConfirming then return false end
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.from ~= player then
			for _, p in sgs.qlist(room:getOtherPlayers(use.from)) do
				if p == player or use.to:contains(p) then
					continue
				end
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local to = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(use.from)) do
			if p == player or use.to:contains(p) then
				continue
			end
			to:append(p)
		end
		to = room:askForPlayerChosen(player, to, skill:objectName(), "sxqiuyuan0:", true, true)
		if not to then return false end
		ctx.targets:append(to)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local to = ctx.targets:first()
		player:peiyin("qiuyuan")
		to:setTag("sxqiuyuanUse", ctx.original_data)
		local dc = room:askForExchange(to, skill:objectName(), 1, 1, true, "sxqiuyuan1:" .. player:objectName(), true)
		if dc then
			room:giveCard(to, player, dc, skill:objectName())
		else
			use.to:append(to)
			room:sortByActionOrder(use.to)
			ctx.original_data:setValue(use)
		end
		return false
	end,
}
sx_fuhuanghou:addSkill(sxqiuyuan)

sx_cenhun = sgs.General(sxfykun, "sx_cenhun", "wu", 3)
sx_cenhun:addSkill("jishe")
sxwudu = sgs.CreateTriggerSkillV2 {
	name = "sxwudu",
	events = { sgs.DamageInflicted },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isKongcheng()) then return false end
		if event == sgs.DamageInflicted then
			local names, owners = {}, {}
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:hasSkill(skill:objectName()) then
					table.insert(names, skill:objectName())
					table.insert(owners, p:objectName())
				end
			end
			if #owners > 0 then
				return table.concat(names, "|"), table.concat(owners, "|")
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.invoker)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		player:peiyin(skill)
		room:loseMaxHp(player, 1, skill:objectName())
		return player:damageRevises(ctx.original_data, -damage.damage)
	end,
}
sx_cenhun:addSkill(sxwudu)

sx_wanglang = sgs.General(sxfykun, "sx_wanglang", "wei", 3)
sxgusheCard = sgs.CreateSkillCard {
	name = "sxgusheCard",
	filter = function(self, targets, to_select, source)
		return #targets < 1 and to_select ~= source and source:canPindian(to_select)
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("gushe")
		for _, p in sgs.list(targets) do
			local from, to, has = player, p, true
			while from:canPindian(to) and (has or from:askForSkillInvoke(self:getSkillName(), to, false)) do
				has = false
				local n = from:pindianInt(to, self:getSkillName())
				if n > 0 then
					from:drawCards(1, self:getSkillName())
					from, to = p, player
				elseif n < 0 then
					to:drawCards(1, self:getSkillName())
					from, to = player, p
				else
					if player:canPindian(p) and player:askForSkillInvoke(self:getSkillName(), p, false) then
						from, to = player, p
						has = true
					elseif p:canPindian(player) and p:askForSkillInvoke(self:getSkillName(), player, false) then
						from, to = p, player
						has = true
					else
						break
					end
				end
			end
		end
	end,
}
sxgushe = sgs.CreateViewAsSkillV2 {
	name = "sxgushe",
	n = 0,
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:canPindian()
	end,
	create_card = function(skill, request)
		return sxgusheCard:clone()
	end,
}
sx_wanglang:addSkill(sxgushe)
sxjici = sgs.CreateTriggerSkillV2 {
	name = "sxjici",
	events = { sgs.PindianVerifying },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event ~= sgs.PindianVerifying then return false end
		local pindian = data:toPindian()
		local names, owners = {}, {}
		for _, p in ipairs({ pindian.from, pindian.to }) do
			if p and p:hasSkill(skill:objectName()) then
				table.insert(names, skill:objectName())
				table.insert(owners, p:objectName())
			end
		end
		if #owners > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local pindian = ctx.original_data:toPindian()
		player:peiyin("jici")
		room:loseHp(player, 1, true, player, skill:objectName())
		local card_id
		if player:objectName() == pindian.from:objectName() then
			pindian.from_number = 13
			card_id = pindian.from_card:getEffectiveId()
		else
			pindian.to_number = 13
			card_id = pindian.to_card:getEffectiveId()
		end
		ctx.original_data:setValue(pindian)
		local log = sgs.LogMessage()
		log.from = player
		log.type = "$sxjiciLog"
		log.card_str = card_id
		log.arg = "K"
		room:sendLog(log)
		return false
	end,
}
sx_wanglang:addSkill(sxjici)

sx_huaxin = sgs.General(sxfykun, "sx_huaxin", "wei", 3)
sxyuanqing = sgs.CreateTriggerSkillV2 {
	name = "sxyuanqing",
	events = { sgs.EventPhaseChanging, sgs.CardsMoveOneTime },
	on_record = function(skill, event, room, player, ctx)
		if not (player and player:isAlive()) then return end
		if event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			if (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and move.from:objectName() == player:objectName() then
				for i, id in sgs.qlist(move.card_ids) do
					if move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip then
						player:addMark(id .. "sxyuanqing-Clear")
					end
				end
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event ~= sgs.EventPhaseChanging then return false end
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive or not player:hasSkill(skill:objectName()) then return false end
		for _, id in sgs.qlist(room:getDiscardPile()) do
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark(id .. "sxyuanqing-Clear") > 0 then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("renyuanqing")
		for _, p in sgs.qlist(room:getAllPlayers()) do
			local ids = sgs.IntList()
			for _, id in sgs.qlist(room:getDiscardPile()) do
				if p:getMark(id .. "sxyuanqing-Clear") > 0 then
					ids:append(id)
				end
			end
			if ids:length() > 0 then
				room:fillAG(ids, p)
				local id = room:askForAG(p, ids, false, skill:objectName())
				room:obtainCard(p, id)
				room:clearAG(p)
			end
		end
		return false
	end,
}
sx_huaxin:addSkill(sxyuanqing)
sxshuchen = sgs.CreateViewAsSkillV2 {
	name = "sxshuchen",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or player:hasFlag("CurrentPlayer") or player:getHandcardNum() <= player:getMaxCards() then
			return false
		end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return dummyCard("peach"):isAvailable(player)
		end
		return string.find(request:getPattern(), "peach") ~= nil
	end,
	can_select_card = function(skill, request, candidate)
		return request:getSelectedCardIds():isEmpty() and not candidate:isEquipped()
	end,
	create_card = function(skill, request)
		local dc = sgs.Sanguosha:cloneCard("peach")
		dc:setSkillName("sxshuchen")
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			dc:addSubcard(id)
		end
		return dc
	end,
}
sx_huaxin:addSkill(sxshuchen)

sx_simashi = sgs.General(sxfykun, "sx_simashi", "wei", 4)
sxjinglve = sgs.CreateTriggerSkillV2 {
	name = "sxjinglve",
	events = { sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.CardsMoveOneTime },
	on_record = function(skill, event, room, player, ctx)
		if not (player and player:isAlive()) then return end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard then
			room:removeTag("sxjinglveIds")
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				local srt = player:getTag(p:objectName() .. "sxjinglve"):toString()
				if srt ~= "" then
					player:removeTag(p:objectName() .. "sxjinglve")
					room:removePlayerCardLimitation(player, "discard", srt .. "$1")
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			if
				move.to_place == sgs.Player_DiscardPile
				and move.from
				and move.from:objectName() == player:objectName()
				and player:getPhase() == sgs.Player_Discard
				and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
				and kesxV2RecordOnce(room, skill, ctx)
			then
				local ids = room:getTag("sxjinglveIds"):toIntList()
				for _, id in sgs.qlist(move.card_ids) do
					ids:append(id)
				end
				room:setTag("sxjinglveIds", ToData(ids))
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		local names, owners = {}, {}
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getCardCount() > 1 and p:hasSkill(skill:objectName()) then
					table.insert(names, skill:objectName())
					table.insert(owners, p:objectName())
				end
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard then
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:getTag(p:objectName() .. "sxjinglve"):toString() ~= "" then
					local ids = room:getTag("sxjinglveIds"):toIntList()
					for _, id in sgs.qlist(room:getDiscardPile()) do
						if ids:contains(id) then
							table.insert(names, skill:objectName())
							table.insert(owners, p:objectName())
							break
						end
					end
				end
			end
		end
		if #owners > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local dc = room:askForExchange(player, skill:objectName(), 2, 2, true, "sxjinglve0:" .. ctx.invoker:objectName(), true)
			if not dc then return false end
			ctx.extra_data = ToData(table.concat(sgs.QList2Table(dc:getSubcards()), ","))
			return true
		elseif event == sgs.EventPhaseEnd then
			local ids = room:getTag("sxjinglveIds"):toIntList()
			local ids2 = sgs.IntList()
			for _, id in sgs.qlist(room:getDiscardPile()) do
				if ids:contains(id) then
					ids2:append(id)
				end
			end
			if ids2:isEmpty() then return false end
			ctx.extra_data = ToData(table.concat(sgs.QList2Table(ids2), ","))
			room:fillAG(ids2, player)
			if not player:askForSkillInvoke(skill, ToData("obtain"), false) then
				room:clearAG(player)
				return false
			end
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			player:peiyin("jinglve")
			player:skillInvoked(skill, 0)
			local dc = dummyCard()
			local list = {}
			for _, s in ipairs(ctx.extra_data:toString():split(",")) do
				local id = tonumber(s)
				if id then
					dc:addSubcard(id)
					table.insert(list, id)
				end
			end
			room:showCard(player, dc:getSubcards())
			room:giveCard(player, ctx.invoker, dc, skill:objectName(), true)
			local dcstr = table.concat(list, ",")
			ctx.invoker:setTag(player:objectName() .. "sxjinglve", ToData(dcstr))
			room:setPlayerCardLimitation(ctx.invoker, "discard", dcstr, true)
		elseif event == sgs.EventPhaseEnd then
			local ids2 = sgs.IntList()
			for _, s in ipairs(ctx.extra_data:toString():split(",")) do
				local id = tonumber(s)
				if id then ids2:append(id) end
			end
			local id = room:askForAG(player, ids2, false, skill:objectName())
			room:obtainCard(player, id)
			room:clearAG(player)
		end
		return false
	end,
}
sx_simashi:addSkill(sxjinglve)

sxfyxun = sgs.Package("sxfyxun", sgs.Package_GeneralPack)

sx_zhangbao = sgs.General(sxfyxun, "sx_zhangbao", "shu", 4)
sxjuezhu = sgs.CreateTriggerSkillV2 {
	name = "sxjuezhu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damage, sgs.Damaged },
	on_record = function(skill, event, room, player, ctx)
		if event == sgs.Damage then
			if player:getMark("&sxjuezhu-Clear") < 1 then
				room:sendCompulsoryTriggerLog(player, skill)
				room:setPlayerMark(player, "&sxjuezhu-Clear", 1)
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.Damaged then return false end
		local damage = data:toDamage()
		if damage.from and damage.from:isAlive() then
			local dc = dummyCard("duel")
			dc:setSkillName("_sxjuezhu")
			if player:canUse(dc, damage.from) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local dc = dummyCard("duel")
		dc:setSkillName("_sxjuezhu")
		room:sendCompulsoryTriggerLog(player, skill)
		room:useCard(sgs.CardUseStruct(dc, player, damage.from))
		return false
	end,
}
sx_zhangbao:addSkill(sxjuezhu)
sxchengji = sgs.CreateViewAsSkillV2 {
	name = "sxchengji",
	n = 2,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or player:getCardCount() <= 1 then return false end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return dummyCard():isAvailable(player)
		end
		return string.find(request:getPattern(), "slash") ~= nil
	end,
	can_select_card = function(skill, request, candidate)
		local selected = request:getSelectedCardIds()
		if selected:isEmpty() then return true end
		if selected:length() >= 2 then return false end
		return sgs.Sanguosha:getCard(selected:first()):getColor() ~= candidate:getColor()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 2
	end,
	create_card = function(skill, request)
		local dc = sgs.Sanguosha:cloneCard("slash")
		dc:setSkillName("sxchengji")
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			dc:addSubcard(id)
		end
		return dc
	end,
}
sx_zhangbao:addSkill(sxchengji)

sx_guansuo = sgs.General(sxfyxun, "sx_guansuo", "shu", 4)
sxzhengnanvs = sgs.CreateViewAsSkillV2 {
	name = "sxzhengnan",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return string.find(request:getPattern(), "sxzhengnan") ~= nil
	end,
	can_select_card = function(skill, request, candidate)
		return request:getSelectedCardIds():isEmpty() and candidate:isRed() and not candidate:isEquipped()
	end,
	create_card = function(skill, request)
		local dc = sgs.Sanguosha:cloneCard("slash")
		dc:setSkillName("sxzhengnan")
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			dc:addSubcard(id)
		end
		return dc
	end,
}
sxzhengnan = sgs.CreateTriggerSkillV2 {
	name = "sxzhengnan",
	view_as_skill = sxzhengnanvs,
	events = { sgs.EventPhaseStart, sgs.Death },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getHandcardNum() > 0 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		if event == sgs.Death then
			local owner = ctx.owner
			if not (owner and owner:objectName() == player:objectName()) then return end
			local death = ctx.original_data:toDeath()
			if death.damage and death.damage.card and death.damage.from == player and table.contains(death.damage.card:getSkillNames(), skill:objectName()) then
				player:drawCards(2, skill:objectName())
			end
		end
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForUseCard(player, "@@sxzhengnan", "sxzhengnan0") ~= nil
	end,
}
sx_guansuo:addSkill(sxzhengnan)

sx_liuchen = sgs.General(sxfyxun, "sx_liuchen$", "shu", 4)
sxzhanjueCard = sgs.CreateSkillCard {
	name = "sxzhanjueCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, source)
		local duel = dummyCard("duel")
		duel:addSubcards(self:getSubcards())
		duel:setSkillName("sxzhanjue")
		local tos = sgs.PlayerList()
		for _, p in sgs.list(targets) do
			tos:append(p)
		end
		return duel:targetFilter(tos, to_select, source)
	end,
	about_to_use = function(self, room, use)
		local duel = dummyCard("duel")
		duel:addSubcards(self:getSubcards())
		duel:setSkillName("sxzhanjue")
		use.card = duel
		use.from:peiyin("zhanjue")
		self:cardOnUse(room, use)
		use.from:drawCards(1, self:getSkillName())
	end,
}
sxzhanjue = sgs.CreateViewAsSkillV2 {
	name = "sxzhanjue",
	n = 0,
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		if not (player and player:getHandcardNum() > 0) then return false end
		local duel = dummyCard("duel")
		duel:setSkillName("sxzhanjue")
		for _, c in sgs.qlist(player:getHandcards()) do
			duel:addSubcard(c)
		end
		return not player:isLocked(duel)
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		local card = sxzhanjueCard:clone()
		for _, c in sgs.qlist(player:getHandcards()) do
			card:addSubcard(c)
		end
		return card
	end,
}
sx_liuchen:addSkill(sxzhanjue)
sxqinwang = sgs.CreateTriggerSkillV2 {
	name = "sxqinwang$",
	events = { sgs.CardAsked },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:hasLordSkill(skill:objectName())) then return false end
		if event == sgs.CardAsked then
			local str = data:toStringList()
			if str[1]:match("slash") or str[1]:match("Slash") then
				if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
					return false
				end
				local shus = room:getLieges("shu", player)
				if shus:length() > 0 then
					for _, p in sgs.qlist(shus) do
						if p:getHandcardNum() > 0 then
							return skill:objectName()
						end
					end
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("qinwang")
		for _, p in sgs.qlist(room:getLieges("shu", player)) do
			if p:getHandcardNum() > 0 and room:askForCard(p, "BasicCard", "sxqinwang0:" .. player:objectName(), ToData(player)) then
				local dc = dummyCard()
				dc:setSkillName("_sxzhengnan")
				room:provide(dc)
				return true
			end
		end
		return false
	end,
}
sx_liuchen:addSkill(sxqinwang)

sx_caorui = sgs.General(sxfyxun, "sx_caorui$", "wei", 3)
sxhuituoCard = sgs.CreateSkillCard {
	name = "sxhuituoCard",
	target_fixed = true,
	will_throw = false,
	about_to_use = function(self, room, use)
		local moves = sgs.CardsMoveList()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, use.from:objectName(), "sxhuituo", "")
		for _, id in sgs.list(self:getSubcards()) do
			if use.from:hasCard(id) then
				moves:append(sgs.CardsMoveStruct(id, nil, sgs.Player_DrawPile, reason))
			else
				moves:append(sgs.CardsMoveStruct(id, use.from, sgs.Player_PlaceHand, reason))
			end
		end
		room:moveCardsAtomic(moves, false)
	end,
}
sxhuituovs = sgs.CreateViewAsSkillV2 {
	name = "sxhuituo",
	n = 4,
	expand_pile = "#sxhuituo",
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return string.find(request:getPattern(), "sxhuituo") ~= nil
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		local selected = request:getSelectedCardIds()
		if selected:length() <= 1 then return false end
		local x, n = 0, 0
		for _, id in sgs.qlist(selected) do
			if player:getPileName(id) == "#sxhuituo" then
				x = x + 1
			else
				n = n + 1
			end
		end
		return x == n
	end,
	create_card = function(skill, request)
		local sc = sxhuituoCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(id)
		end
		return sc
	end,
}
sxhuituo = sgs.CreateTriggerSkillV2 {
	name = "sxhuituo",
	view_as_skill = sxhuituovs,
	events = { sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Damaged then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_pay = function(skill, event, room, player, ctx)
		player:peiyin("huituo")
		local ids = room:showDrawPile(player, 2, skill:objectName(), false)
		room:notifyMoveToPile(player, ids, "sxhuituo")
		return room:askForUseCard(player, "@@sxhuituo", "sxhuituo0") ~= nil
	end,
}
sx_caorui:addSkill(sxhuituo)
sxmingjianCard = sgs.CreateSkillCard {
	name = "sxmingjianCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, source)
		return #targets < 1 and to_select ~= source
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("mingjian")
		for _, p in sgs.list(targets) do
			room:showCard(player, self:getEffectiveId())
			room:giveCard(player, p, self, self:getSkillName(), true)
			local c = sgs.Sanguosha:getCard(self:getEffectiveId())
			if p:hasCard(c) and c:isAvailable(p) then
				room:askForUseCard(p, c:toString(), "sxmingjian0:" .. c:objectName())
			end
		end
	end,
}
sxmingjian = sgs.CreateViewAsSkillV2 {
	name = "sxmingjian",
	n = 1,
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:getCardCount() > 0
	end,
	create_card = function(skill, request)
		local sc = sxmingjianCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(id)
		end
		return sc
	end,
}
sx_caorui:addSkill(sxmingjian)
sx_caorui:addSkill("xingshuai")

sx_guohuanghou = sgs.General(sxfyxun, "sx_guohuanghou", "wei", 3, false)
sxjiaozhaoCard = sgs.CreateSkillCard {
	name = "sxjiaozhaoCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, source)
		return #targets < 1 and to_select ~= source and to_select:getHandcardNum() > 1
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("jiaozhao")
		for _, p in sgs.list(targets) do
			local dc = room:askForExchange(p, "sxjiaozhao0", 2, 2, false, "sxjiaozhao0:" .. player:objectName())
			if dc then
				room:showCard(p, dc:getSubcards())
				room:fillAG(dc:getSubcards(), player)
				if player:hasFlag("sxdanxinbf") then
					local id = room:askForAG(player, dc:getSubcards(), false, self:objectName())
					room:obtainCard(player, id)
				else
					local bc = room:askForExchange(player, "sxjiaozhao1", 1, 1, false, "sxjiaozhao1:" .. p:objectName(), true)
					if bc then
						local moves = sgs.CardsMoveList()
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), p:objectName(), self:getSkillName(), "")
						local id = room:askForAG(player, dc:getSubcards(), false, self:objectName())
						moves:append(sgs.CardsMoveStruct(id, player, sgs.Player_PlaceHand, reason))
						moves:append(sgs.CardsMoveStruct(bc:getEffectiveId(), p, sgs.Player_PlaceHand, reason))
						room:moveCardsAtomic(moves, false)
					end
				end
				room:clearAG(player)
			end
		end
		player:setFlags("-sxdanxinbf")
	end,
}
sxjiaozhao = sgs.CreateViewAsSkillV2 {
	name = "sxjiaozhao",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local player = request:getInitiator()
			return player and player:usedTimes("#sxjiaozhaoCard") < 1
		end
		return request:getPattern() == "@@sxjiaozhao"
	end,
	create_card = function(skill, request)
		return sxjiaozhaoCard:clone()
	end,
}
sx_guohuanghou:addSkill(sxjiaozhao)
sxdanxin = sgs.CreateTriggerSkillV2 {
	name = "sxdanxin",
	events = { sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Damaged then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		player:setFlags("sxdanxinbf")
		local card = room:askForUseCard(player, "@@sxjiaozhao", "sxdanxin0")
		player:setFlags("-sxdanxinbf")
		return card ~= nil
	end,
}
sx_guohuanghou:addSkill(sxdanxin)

sx_liuye = sgs.General(sxfyxun, "sx_liuye", "wei", 3)
sxpolu = sgs.CreateTriggerSkillV2 {
	name = "sxpolu",
	events = { sgs.Damaged, sgs.Damage },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.Damaged and event ~= sgs.Damage then return false end
		local damage = data:toDamage()
		if player:canDiscard(damage.to, "e") then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		return player:askForSkillInvoke(skill, damage.to)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		player:peiyin("polu")
		local id = room:askForCardChosen(player, damage.to, "e", skill:objectName(), false, sgs.Card_MethodDiscard)
		if id > -1 then
			room:throwCard(id, skill:objectName(), damage.to, player)
			if damage.to == player then
				player:drawCards(1, skill:objectName())
			end
		end
		return false
	end,
}
sx_liuye:addSkill(sxpolu)
sxchoulveCard = sgs.CreateSkillCard {
	name = "sxchoulveCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, source)
		return #targets < 1 and to_select ~= source
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("choulve")
		for _, p in sgs.list(targets) do
			room:giveCard(player, p, self, self:getSkillName())
			local dc = room:askForExchange(p, self:getSkillName(), 1, 1, true, "sxchoulve0:" .. player:objectName(), true, "EquipCard")
			if dc then
				room:showCard(p, dc:getEffectiveId())
				room:giveCard(p, player, dc, self:getSkillName(), true)
			end
		end
	end,
}
sxchoulve = sgs.CreateViewAsSkillV2 {
	name = "sxchoulve",
	n = 1,
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:getHandcardNum() > 0
	end,
	can_select_card = function(skill, request, candidate)
		return not candidate:isEquipped()
	end,
	create_card = function(skill, request)
		local sc = sxchoulveCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(id)
		end
		return sc
	end,
}
sx_liuye:addSkill(sxchoulve)

sx_dingfeng = sgs.General(sxfyxun, "sx_dingfeng", "wu", 4)
sxduanbing = sgs.CreateTriggerSkillV2 {
	name = "sxduanbing",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.ConfirmDamage },
	can_trigger = function(skill, event, room, player, data)
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and player:getMark("sxduanbing-Clear") < 1 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:addMark("sxduanbing-Clear")
		player:peiyin("duanbing")
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		player:damageRevises(ctx.original_data, 1)
		return false
	end,
}
sxduanbingbf = sgs.CreateAttackRangeSkillV2 {
	name = "#sxduanbingbf",
	fixed_func = function(skill, ctx)
		local holder = ctx:getHolder()
		if holder and holder:hasSkill("sxduanbing") then
			return 1
		end
		return false
	end,
}
sx_dingfeng:addSkill(sxduanbing)
sx_dingfeng:addSkill(sxduanbingbf)
sxfenxunCard = sgs.CreateSkillCard {
	name = "sxfenxunCard",
	target_fixed = false,
	--will_throw = false,
	filter = function(self, targets, to_select, source)
		return #targets < 1 and to_select ~= source
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("fenxun")
		for _, p in sgs.list(targets) do
			room:insertAttackRangePair(player, p)
			p:addMark("sxfenxunbf-Clear")
		end
	end,
}
sxfenxunvs = sgs.CreateViewAsSkillV2 {
	name = "sxfenxun",
	n = 1,
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:getCardCount() > 0
	end,
	can_select_card = function(skill, request, candidate)
		return candidate:isKindOf("Armor")
	end,
	create_card = function(skill, request)
		local sc = sxfenxunCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(id)
		end
		return sc
	end,
}
sxfenxun = sgs.CreateTriggerSkillV2 {
	name = "sxfenxun",
	view_as_skill = sxfenxunvs,
	events = { sgs.EventPhaseChanging },
	on_record = function(skill, event, room, player, ctx)
		if not (player and player:isAlive()) then return end
		local change = ctx.original_data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			for _, p in sgs.list(room:getOtherPlayers(player)) do
				if p:getMark("sxfenxunbf-Clear") > 0 then
					for i = 1, p:getMark("sxfenxunbf-Clear") do
						room:removeAttackRangePair(player, p)
					end
				end
			end
		end
	end,
}
sx_dingfeng:addSkill(sxfenxun)

sx_sunluban = sgs.General(sxfyxun, "sx_sunluban", "wu", 3, false)
sxzenhui = sgs.CreateTriggerSkillV2 {
	name = "sxzenhui",
	events = { sgs.CardUsed },
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if not (use.card:isKindOf("Slash") or use.card:isKindOf("TrickCard")) then return false end
		for _, p in sgs.list(room:getOtherPlayers(player)) do
			if not use.to:contains(p) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local tos = sgs.SPlayerList()
		for _, p in sgs.list(room:getOtherPlayers(player)) do
			if not use.to:contains(p) then
				tos:append(p)
			end
		end
		local to = room:askForPlayerChosen(player, tos, skill:objectName(), "sxzenhui0:" .. use.card:objectName(), true, true)
		if to then
			ctx.extra_data:setValue(ToData(to))
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local to = ctx.extra_data:toPlayer()
		if to then
			local use = ctx.original_data:toCardUse()
			player:peiyin("zhenhui")
			use.from = to
			ctx.original_data:setValue(use)
		end
		return false
	end,
}
sx_sunluban:addSkill(sxzenhui)
sxchuyi = sgs.CreateTriggerSkillV2 {
	name = "sxchuyi",
	events = { sgs.DamageCaused },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		local damage = data:toDamage()
		local names, owners = {}, {}
		for _, p in sgs.list(room:getOtherPlayers(player)) do
			if p:inMyAttackRange(damage.to) and p:getMark("sxchuyi_lun") < 1 and p:hasSkill(skill) then
				table.insert(names, skill:objectName())
				table.insert(owners, p:objectName())
			end
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		return player:askForSkillInvoke(skill, damage.to)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local invoker = ctx.invoker
		player:addMark("sxchuyi_lun")
		if invoker then
			invoker:damageRevises(ctx.original_data, 1)
		end
		return false
	end,
}
sx_sunluban:addSkill(sxchuyi)

sxfykan = sgs.Package("sxfykan", sgs.Package_GeneralPack)

sx_xiahouba = sgs.General(sxfykan, "sx_xiahouba", "shu", 4)
sxbaobian = sgs.CreateTriggerSkillV2 {
	name = "sxbaobian",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseStart or player:getPhase() ~= sgs.Player_Play then return false end
		for _, p in sgs.list(room:getAllPlayers()) do
			if p:canDiscard(p, "h") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local tos = sgs.SPlayerList()
		for _, p in sgs.list(room:getAllPlayers()) do
			if p:canDiscard(p, "h") then
				tos:append(p)
			end
		end
		local to = room:askForPlayerChosen(player, tos, skill:objectName(), "sxbaobian0:", true, true)
		if not to then return false end
		ctx.targets:append(to)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local to = ctx.targets:first()
		player:peiyin("baobian")
		room:loseHp(player, 1, true, player, skill:objectName())
		local dc = room:askForDiscard(to, skill:objectName(), 1, 1)
		if dc and player:isAlive() and sgs.Sanguosha:getCard(dc:getEffectiveId()):isKindOf("BasicCard") then
			dc = dummyCard()
			dc:setSkillName("_sxbaobian")
			if player:canSlash(to, dc, false) then
				room:useCard(sgs.CardUseStruct(dc, player, to))
			end
		end
		return false
	end,
}
sx_xiahouba:addSkill(sxbaobian)

sx_lvfan = sgs.General(sxfykan, "sx_lvfan", "wu", 3)
sx_lvfan:addSkill("yandiaodu")
sxdiancai = sgs.CreateTriggerSkillV2 {
	name = "sxdiancai",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardsMoveOneTime },
	on_record = function(skill, event, room, player, ctx)
		local owner = ctx.owner
		if not (owner and owner:objectName() == player:objectName()) then return end
		local move = ctx.original_data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceEquip) and move.from:isAlive() and move.from:getEquips():length() < 1 then
			player:peiyin("yandiancai")
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			player:drawCards(1, skill:objectName())
		end
	end,
}
sx_lvfan:addSkill(sxdiancai)

sx_sunyi = sgs.General(sxfykan, "sx_sunyi", "wu", 4)
sxzaoli = sgs.CreateTriggerSkillV2 {
	name = "sxzaoli",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:getCardCount() > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("mobileyongzaoli")
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		local choices = {}
		if player:getHandcardNum() > 0 then
			table.insert(choices, "sxzaoli1")
		end
		if player:hasEquip() then
			table.insert(choices, "sxzaoli2")
		end
		local n, x = player:getLostHp(), 0
		if room:askForChoice(player, skill:objectName(), table.concat(choices, "+")) == "sxzaoli1" then
			x = player:getHandcardNum()
			player:throwAllHandCards(skill:objectName())
		else
			x = player:getEquips():length()
			player:throwAllEquips(skill:objectName())
		end
		player:drawCards(x + n, skill:objectName())
		if n > 0 then
			room:loseHp(player, 1, true, player, skill:objectName())
		end
		return false
	end,
}
sx_sunyi:addSkill(sxzaoli)

sx_liuzan = sgs.General(sxfykan, "sx_liuzan", "wu", 4)
sxfenyin = sgs.CreateTriggerSkillV2 {
	name = "sxfenyin",
	events = { sgs.CardUsed, sgs.DrawNCards },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then
				return false
			end
			if player:hasSkill(skill) then
				return skill:objectName()
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId() > 0 and player:getMark("sxfenyinUse-Clear") > 0 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.DrawNCards then
			return player:askForSkillInvoke(skill, ctx.original_data)
		end
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.DrawNCards then
			local draw = ctx.original_data:toDraw()
			player:addMark("sxfenyinUse-Clear")
			player:peiyin("fenyin")
			draw.num = draw.num + 2
			ctx.original_data:setValue(draw)
		else
			local use = ctx.original_data:toCardUse()
			if player:getMark("&sxfenyin+:+" .. use.card:getColorString() .. "-Clear") > 0 then
				room:askForDiscard(player, skill:objectName(), 1, 1, false, true)
			end
			for _, m in sgs.list(player:getMarkNames()) do
				if m:startsWith("&sxfenyin+:+") then
					room:setPlayerMark(player, m, 0)
				end
			end
			room:setPlayerMark(player, "&sxfenyin+:+" .. use.card:getColorString() .. "-Clear", 1)
		end
		return false
	end,
}
sx_liuzan:addSkill(sxfenyin)

sx_jiling = sgs.General(sxfykan, "sx_jiling", "qun", 4)
sxshuangren = sgs.CreateTriggerSkillV2 {
	name = "sxshuangren",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseStart or player:getPhase() ~= sgs.Player_Play then return false end
		for _, p in sgs.list(room:getOtherPlayers(player)) do
			if player:canPindian(p) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local tos = sgs.SPlayerList()
		for _, p in sgs.list(room:getOtherPlayers(player)) do
			if player:canPindian(p) then
				tos:append(p)
			end
		end
		local to = room:askForPlayerChosen(player, tos, skill:objectName(), "sxshuangren0", true, true)
		if not to then return false end
		ctx.targets:append(to)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local to = ctx.targets:first()
		player:peiyin("heg_shuangren")
		if player:pindian(to, skill:objectName()) then
			local tos = sgs.SPlayerList()
			local dc = dummyCard()
			dc:setSkillName("_sxshuangren")
			for _, p in sgs.list(room:getAllPlayers()) do
				if to:distanceTo(p) == 1 and player:canSlash(p, dc, false) then
					tos:append(p)
				end
			end
			tos = room:askForPlayersChosen(player, tos, skill:objectName(), 0, 2, "sxshuangren1")
			for _, p in sgs.list(tos) do
				room:useCard(sgs.CardUseStruct(dc, player, p))
			end
		else
			room:setPlayerCardLimitation(player, "use", "Slash", true)
		end
		return false
	end,
}
sx_jiling:addSkill(sxshuangren)

sx_liru = sgs.General(sxfykan, "sx_liru", "qun", 3)
sxmiejiCard = sgs.CreateSkillCard {
	name = "sxmiejiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, source)
		return #targets < 1 and to_select ~= source
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("mieji")
		for _, p in sgs.list(targets) do
			room:giveCard(player, p, self, self:getSkillName())
			local dc = dummyCard()
			for i = 1, 2 do
				if dc:subcardsLength() < player:getCardCount() and player:canDiscard(p, "he") then
					local id = room:askForCardChosen(player, p, "he", self:getSkillName(), false, sgs.Card_MethodDiscard, dc:getSubcards(), true)
					if id < 0 then
						break
					end
					dc:addSubcard(id)
				else
					break
				end
			end
			room:throwCard(dc, self:getSkillName(), p, player)
		end
	end,
}
sxmieji = sgs.CreateViewAsSkillV2 {
	name = "sxmieji",
	n = 1,
	limit_scope = sgs.Skill_Limit_Turn,
	max_usage_limit = 1,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:getHandcardNum() > 0
	end,
	can_select_card = function(skill, request, candidate)
		return candidate:isKindOf("TrickCard") and candidate:isBlack()
	end,
	create_card = function(skill, request)
		local sc = sxmiejiCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(id)
		end
		return sc
	end,
}
sx_liru:addSkill(sxmieji)
sxjuece = sgs.CreateTriggerSkillV2 {
	name = "sxjuece",
	events = { sgs.EventPhaseStart, sgs.CardsMoveOneTime },
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.CardsMoveOneTime then return end
		local owner = ctx.owner
		if not (owner and player:hasSkill(skill:objectName(), true) and kesxV2RecordOnce(room, skill, ctx)) then return end
		local move = ctx.original_data:toMoveOneTime()
		if move.from then
			for i, id in sgs.list(move.card_ids) do
				if move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip then
					move.from:addMark("sxjueceNum-Clear")
				end
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseStart or player:getPhase() ~= sgs.Player_Finish then return false end
		for _, p in sgs.list(room:getAllPlayers()) do
			if p:getMark("sxjueceNum-Clear") > 1 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local tos = sgs.SPlayerList()
		for _, p in sgs.list(room:getAllPlayers()) do
			if p:getMark("sxjueceNum-Clear") > 1 then
				tos:append(p)
			end
		end
		local to = room:askForPlayerChosen(player, tos, skill:objectName(), "sxjuece0", true, true)
		if not to then return false end
		ctx.targets:append(to)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("juece")
		room:damage(sgs.DamageStruct(skill:objectName(), player, ctx.targets:first()))
		return false
	end,
}
sx_liru:addSkill(sxjuece)

sx_wangyun = sgs.General(sxfykan, "sx_wangyun", "qun", 3)
sxlianji = sgs.CreateViewAsSkillV2 {
	name = "sxlianji",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:getCardCount() > 0 and dummyCard("collateral"):isAvailable(player)
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		return candidate:isKindOf("EquipCard")
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local sc = sgs.Sanguosha:cloneCard("collateral")
		sc:setSkillName("sxlianji")
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(id)
		end
		return sc
	end,
}
sx_wangyun:addSkill(sxlianji)
sxzongji = sgs.CreateTriggerSkillV2 {
	name = "sxzongji",
	events = { sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event ~= sgs.Damaged then return false end
		local damage = data:toDamage()
		if not (damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel"))) then
			return false
		end
		local names, owners = {}, {}
		for _, p in sgs.list(room:getAllPlayers()) do
			if p:hasSkill(skill:objectName()) and (p:canDiscard(player, "he") or (damage.from and p:canDiscard(damage.from, "he"))) then
				table.insert(names, skill:objectName())
				table.insert(owners, p:objectName())
			end
		end
		if #owners > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local invoker = ctx.invoker
		player:peiyin("moucheng")
		if player:canDiscard(invoker, "he") then
			local id = room:askForCardChosen(player, invoker, "he", skill:objectName(), false, sgs.Card_MethodDiscard)
			if id > -1 then
				room:throwCard(id, skill:objectName(), invoker, player)
			end
		end
		if player:isAlive() and damage.from and player:canDiscard(damage.from, "he") then
			local id = room:askForCardChosen(player, damage.from, "he", skill:objectName(), false, sgs.Card_MethodDiscard)
			if id > -1 then
				room:throwCard(id, skill:objectName(), damage.from, player)
			end
		end
		return false
	end,
}
sx_wangyun:addSkill(sxzongji)

sx_taoqian = sgs.General(sxfykan, "sx_taoqian", "qun", 4)
sxyirang = sgs.CreateTriggerSkillV2 {
	name = "sxyirang",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and player:getHandcardNum() > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("yirang")
		room:showAllCards(player)
		local n = 990
		for _, p in sgs.list(room:getOtherPlayers(player)) do
			if p:getHandcardNum() < n then
				n = p:getHandcardNum()
			end
		end
		local tos = sgs.SPlayerList()
		for _, p in sgs.list(room:getOtherPlayers(player)) do
			if p:getHandcardNum() <= n then
				tos:append(p)
			end
		end
		local to = room:askForPlayerChosen(player, tos, skill:objectName(), "sxyirang0")
		if to then
			room:doAnimate(1, player:objectName(), to:objectName())
			local hs = player:getHandcards()
			room:giveCard(player, to, player:handCards(), skill:objectName(), true)
			n = {}
			for _, h in sgs.list(hs) do
				if table.contains(n, h:getType()) then
					continue
				end
				table.insert(n, h:getType())
			end
			player:drawCards(#n, skill:objectName())
		end
		return false
	end,
}
sx_taoqian:addSkill(sxyirang)

sgs.LoadTranslationTable {

	["sx_taoqian"] = "陶谦[巽]",
	["&sx_taoqian"] = "陶谦",
	["#sx_taoqian"] = "三让徐州",
	["illustrator:sx_taoqian"] = "F.源",

	["sxyirang"] = "揖让",
	[":sxyirang"] = "出牌阶段开始时，你可以展示所有手牌，将这些牌交给一名手牌数最少的其他角色，然后你摸X张牌（X为交出牌的类别数）。",
	["sxyirang0"] = "揖让：请选择交给手牌的目标",

	["sx_wangyun"] = "王允[巽]",
	["&sx_wangyun"] = "王允",
	--["#sx_wangyun"] = "骄悍激躁",
	["illustrator:sx_wangyun"] = "Thinking",

	["sxlianji"] = "连机",
	[":sxlianji"] = "你可以将一张装备牌当做【借刀杀人】使用。",
	["sxzongji"] = "纵计",
	[":sxzongji"] = "当一名角色受到【杀】或【决斗】造成的伤害后，你可以弃置其与伤害来源各一张牌。",

	["sx_liru"] = "李儒[巽]",
	["&sx_liru"] = "李儒",
	--["#sx_liru"] = "骄悍激躁",
	["illustrator:sx_liru"] = "MSNZero",

	["sxmieji"] = "灭计",
	[":sxmieji"] = "出牌阶段限一次，你可以将一张黑色锦囊牌交给一名其他角色，然后你可以弃置其至多两张牌。",
	["sxjuece"] = "绝策",
	[":sxjuece"] = "结束阶段，你可以对一名本回合失去过至少两张牌的角色造成1点伤害。",
	["sxjuece0"] = "绝策：你可以选择一名角色造成1点伤害",

	["sx_jiling"] = "纪灵[巽]",
	["&sx_jiling"] = "纪灵",
	["#sx_jiling"] = "仲帝大将",
	["illustrator:sx_jiling"] = "樱花闪乱",

	["sxshuangren"] = "双刃",
	[":sxshuangren"] = "出牌阶段开始时，你可以拼点：若你赢，你可以视为对对方距离1的至多两名角色各使用一张【杀】；若你没赢，你本回合不能使用【杀】。",
	["sxshuangren0"] = "双刃：你可以与一名其他角色拼点",
	["sxshuangren1"] = "双刃：你可以选择至多两名角色各视为使用【杀】",

	["sx_liuzan"] = "留赞[巽]",
	["&sx_liuzan"] = "留赞",
	--["#sx_liuzan"] = "骄悍激躁",
	["illustrator:sx_liuzan"] = "NOVART",

	["sxfenyin"] = "奋音",
	[":sxfenyin"] = "摸牌阶段摸牌时，你可以多摸两张牌，若如此做，本回合你使用牌时，若此牌与你本回合使用的上一张牌颜色相同，你弃置一张牌。",

	["sx_sunyi"] = "孙翊[巽]",
	["&sx_sunyi"] = "孙翊",
	["#sx_sunyi"] = "骄悍激躁",
	["illustrator:sx_sunyi"] = "凡果",

	["sxzaoli"] = "躁厉",
	[":sxzaoli"] = "锁定技，准备阶段，你选择弃置所有手牌或装备区所有牌，然后摸等量的牌，若你已受伤，则多摸等同已损失体力值的牌，然后失去1点体力。",
	["sxzaoli1"] = "弃置所有手牌",
	["sxzaoli2"] = "弃置所有装备区牌",

	["sx_lvfan"] = "吕范[巽]",
	["&sx_lvfan"] = "吕范",
	["#sx_lvfan"] = "持筹廉悍",
	["illustrator:sx_lvfan"] = "鬼画府",

	["sxdiancai"] = "典财",
	[":sxdiancai"] = "当一名角色失去装备区所有牌后，你摸一张牌。",

	["sx_xiahouba"] = "夏侯霸[巽]",
	["&sx_xiahouba"] = "夏侯霸",
	["#sx_xiahouba"] = "棘途壮志",
	["illustrator:sx_xiahouba"] = "熊猫探员",

	["sxbaobian"] = "豹变",
	[":sxbaobian"] = "出牌阶段开始时，你可以失去1点体力并令一名角色弃置一张手牌，若弃置了基本牌，你视为对其使用一张【杀】。",
	["sxbaobian0"] = "豹变：你可以选择一名角色并失去1点体力令其弃置一张手牌",

	["sx_sunluban"] = "孙鲁班[巽]",
	["&sx_sunluban"] = "孙鲁班",
	["#sx_sunluban"] = "为虎作伥",
	["illustrator:sx_sunluban"] = "FOOLTOWN",

	["sxzenhui"] = "谮毁",
	[":sxzenhui"] = "当你使用【杀】或锦囊牌时，你可以令一名非目标角色成为此牌使用者。",
	["sxchuyi"] = "除异",
	[":sxchuyi"] = "每轮限一次，当其他角色对你攻击范围内的角色造成伤害时，你可以令此伤害+1。",
	["sxzenhui0"] = "谮毁：你可以令一名非目标角色成为此【%src】使用者",

	["sx_dingfeng"] = "丁奉[巽]",
	["&sx_dingfeng"] = "丁奉",
	["#sx_dingfeng"] = "寸短寸险",
	["illustrator:sx_dingfeng"] = "G.G.G.",

	["sxduanbing"] = "短兵",
	[":sxduanbing"] = "锁定技，你的攻击范围为1，你使用【杀】每回合首次造成的伤害+1。",
	["sxfenxun"] = "奋迅",
	[":sxfenxun"] = "出牌阶段限一次，你可以弃置一张防具牌并选择一名其他角色，其本回合视为在你的攻击范围内。",

	["sx_liuye"] = "刘晔[巽]",
	["&sx_liuye"] = "刘晔",
	--["#sx_liuye"] = "虎翼将军",
	--["illustrator:sx_liuye"] = "",

	["sxpolu"] = "破橹",
	[":sxpolu"] = "当你造成或受到伤害后，你可以弃置受伤角色装备区一张牌，若受伤角色为你，你摸一张牌。",
	["sxchoulve"] = "筹略",
	[":sxchoulve"] = "出牌阶段限一次，你可以交给一名其他角色一张手牌，然后其可以展示并交给你一张装备牌。",
	["sxchoulve0"] = "筹略：你可以展示并交给%src一张装备牌",

	["sx_guohuanghou"] = "郭皇后[巽]",
	["&sx_guohuanghou"] = "郭皇后",
	--["#sx_guohuanghou"] = "虎翼将军",
	--["illustrator:sx_guohuanghou"] = "",

	["sxjiaozhao"] = "矫诏",
	[":sxjiaozhao"] = "出牌阶段限一次，你可以令一名手牌数不小于2的其他角色展示两张手牌，然后你可以用一张牌交换其中一张。",
	["sxdanxin"] = "殚心",
	[":sxdanxin"] = "当你受到伤害后，你可以发动一次“矫诏”且改为你获得展示牌中的一张。",
	["sxjiaozhao0"] = "矫诏：请选择两张手牌展示",
	["sxjiaozhao1"] = "矫诏：你可以用一张牌交换其中一张",
	["sxdanxin0"] = "殚心：你可以发动“矫诏”",

	["sx_caorui"] = "曹叡[巽]",
	["&sx_caorui"] = "曹叡",
	--["#sx_caorui"] = "虎翼将军",
	--["illustrator:sx_caorui"] = "",

	["sxhuituo"] = "恢拓",
	[":sxhuituo"] = "当你受到伤害后，你可以展示牌堆顶两张牌，然后用任意张牌替换其中等量的牌。",
	["sxmingjian"] = "明鉴",
	[":sxmingjian"] = "出牌阶段限一次，你可以将一张牌展示并交给一名其他角色，然后其可以使用之。",
	["sxhuituo0"] = "恢拓：你可以替换这些牌",
	["#sxhuituo"] = "牌堆牌",
	["sxmingjian0"] = "明鉴：你可以使用这张【%src】",

	["sx_liuchen"] = "刘谌[巽]",
	["&sx_liuchen"] = "刘谌",
	--["#sx_liuchen"] = "虎翼将军",
	--["illustrator:sx_liuchen"] = "",

	["sxzhanjue"] = "战绝",
	[":sxzhanjue"] = "出牌阶段限一次，你可以将所有手牌当做【决斗】使用，然后摸一张牌。",
	["sxqinwang"] = "勤王",
	[":sxqinwang"] = "主公技，当你需要打出【杀】时，其他蜀势力角色可以弃置一张基本牌，视为替你打出一张【杀】。",
	["sxqinwang0"] = "勤王：你可以弃置一张基本牌响应%src",

	["sx_guansuo"] = "关索[巽]",
	["&sx_guansuo"] = "关索",
	["#sx_guansuo"] = "征南先锋",
	["illustrator:sx_guansuo"] = "depp",

	["sxzhengnan"] = "征南",
	[":sxzhengnan"] = "准备阶段，你可以将一张红色手牌当做【杀】使用，若你因此杀死了角色，你摸两张牌。",
	["sxzhengnan0"] = "征南：你可以将一张红色手牌当做【杀】使用",

	["sx_zhangbao"] = "张苞[巽]",
	["&sx_zhangbao"] = "张苞",
	["#sx_zhangbao"] = "虎翼将军",
	["illustrator:sx_zhangbao"] = "",

	["sxjuezhu"] = "角逐",
	[":sxjuezhu"] = "锁定技，当你造成/受到伤害后，你本回合使用牌无次数限制/视为对伤害来源使用一张【决斗】。",
	["sxchengji"] = "承继",
	[":sxchengji"] = "你可以将两张颜色不同的牌当做【杀】使用或打出。",

	["sx_simashi"] = "司马师[坤]",
	["&sx_simashi"] = "司马师",
	--["#sx_simashi"] = "求仁失益",
	--["illustrator:sx_simashi"] = "鬼画府",

	["sxjinglve"] = "景略",
	[":sxjinglve"] = "其他角色弃牌阶段开始时，你可以展示并交给其两张牌，令其本阶段不能其中这些牌，然后你可以于此阶段结束时获得此阶段弃置的一张牌。",
	["sxjinglve:obtain"] = "景略：你可以选择获得一张牌",

	["sx_huaxin"] = "华歆[坤]",
	["&sx_huaxin"] = "华歆",
	["#sx_huaxin"] = "情素拂烛",
	["illustrator:sx_huaxin"] = "游漫美绘",

	["sxyuanqing"] = "渊清",
	[":sxyuanqing"] = "回合结束时，你可以令所有角色各选择并获得弃牌堆中因其本回合失去而置入的一张牌。",
	["sxshuchen"] = "疏陈",
	[":sxshuchen"] = "你的回合外，你可以将超出手牌上限部分的手牌当做【桃】使用。",

	["sx_wanglang"] = "王朗[坤]",
	["&sx_wanglang"] = "王朗",
	--["#sx_wanglang"] = "求仁失益",
	--["illustrator:sx_wanglang"] = "鬼画府",

	["sxgushe"] = "鼓舌",
	[":sxgushe"] = "出牌阶段限一次，你可以拼点：赢的角色摸一张牌，然后没赢的角色可以与对方重复此流程。",
	["sxjici"] = "激词",
	[":sxjici"] = "当你亮出拼点牌时，你可以失去1点体力，令此牌点数视为K。",
	["$sxjiciLog"] = "%from 的拼点牌 %card 点数视为 %arg",

	["sx_cenhun"] = "岑昏[坤]",
	["&sx_cenhun"] = "岑昏",
	["#sx_cenhun"] = "伐梁倾瓴",
	["illustrator:sx_cenhun"] = "心中一凛",

	["sxwudu"] = "无度",
	[":sxwudu"] = "当一名没有手牌的角色受到伤害时，你可以扣减1点体力上限，防止此伤害。",

	["sx_fuhuanghou"] = "伏皇后[坤]",
	["&sx_fuhuanghou"] = "伏皇后",
	--["#sx_fuhuanghou"] = "求仁失益",
	--["illustrator:sx_fuhuanghou"] = "鬼画府",

	["sxzhuikong"] = "惴恐",
	[":sxzhuikong"] = "其他角色的准备阶段，你可以用一张【杀】与其拼点；赢的角色可以使用对方的拼点牌。",
	["sxqiuyuan"] = "求援",
	[":sxqiuyuan"] = "当你成为其他角色使用【杀】的目标时，你可以令另一名其他角色选择交给你一张牌或成为此【杀】的额外目标。",
	["sxzhuikong0"] = "惴恐：你可以选择一张【杀】与%src拼点",
	["sxzhuikong1"] = "惴恐：你可以使用对方的拼点牌",
	["#sxzhuikong"] = "拼点牌",
	["sxqiuyuan0"] = "求援：你成为【杀】目标，可以令另一名其他角色选择",
	["sxqiuyuan1"] = "求援：你可以交给%src一张牌，否则成为此【杀】额外目标",

	["sx_gongsunyuan"] = "公孙渊[坤]",
	["&sx_gongsunyuan"] = "公孙渊",
	--["#sx_gongsunyuan"] = "求仁失益",
	--["illustrator:sx_gongsunyuan"] = "鬼画府",

	["sxhuaiyi"] = "怀异",
	[":sxhuaiyi"] = "锁定技，准备阶段，你展示所有手牌，若颜色不同，你弃置其中一种颜色所有牌，然后获得一至等量名其他角色各一张牌，若超过一名角色，你失去1点体力。",
	["sxfengbai"] = "封拜",
	[":sxfengbai"] = "主公技，当你获得群势力角色装备区的牌后，你可以令其摸一张牌。",
	["sxhuaiyi0"] = "怀异：请选择一种颜色的一张牌",
	["sxhuaiyi1"] = "怀异：请选择至多%src名角色获得牌",

	["sx_liubiao"] = "刘表[坤]",
	["&sx_liubiao"] = "刘表",
	--["#sx_liubiao"] = "求仁失益",
	--["illustrator:sx_liubiao"] = "鬼画府",

	["sxzishou"] = "自守",
	[":sxzishou"] = "出牌阶段开始前，你可以摸X张牌（X为场上势力数），然后跳过此阶段。",
	["sxzongshi"] = "宗室",
	[":sxzongshi"] = "锁定技，你的手牌上限+X（X为场上势力数）。",
	["sxjujing"] = "踞荆",
	[":sxjujing"] = "主公技，当你受到其他群势力角色造成的伤害后，你可以弃置两张牌，然后回复1点体力。",
	["sxjujing0"] = "踞荆：你可以弃置两张牌回复1点体力",

	["sx_liuzang"] = "刘璋[坤]",
	["&sx_liuzang"] = "刘璋",
	["#sx_liuzang"] = "求仁失益",
	["illustrator:sx_liuzang"] = "鬼画府",

	["sxyinge"] = "引戈",
	[":sxyinge"] = "出牌阶段限一次，你可以令一名其他角色交给你一张牌，然后其视为对你或你攻击范围内的一名其他角色使用一张【杀】。",
	["sxshiren"] = "施仁",
	[":sxshiren"] = "每回合限一次，当你成为其他角色使用【杀】的目标后，你可以摸两张牌，然后交给其一张牌。",
	["sxjuyi"] = "据益",
	[":sxjuyi"] = "主公技，其他群势力角色每回合首次对你造成伤害时，其可以防止之，然后获得你一张牌。",
	["sxyinge0"] = "引戈：请选择一张牌交给%src",
	["sxyinge1"] = "引戈：请选择【杀】的目标",
	["sxshiren0"] = "施仁：请选择一张牌交给%src",

	["sx_sunshao"] = "孙邵[艮]",
	["&sx_sunshao"] = "孙邵",
	["#sx_sunshao"] = "创基抉政",
	["illustrator:sx_sunshao"] = "君桓文化",

	["sxdingyi"] = "定仪",
	[":sxdingyi"] = "装备区没有牌的角色于其结束阶段可以摸一张牌。",
	["sxzuici"] = "罪辞",
	[":sxzuici"] = "当你受到伤害后，你可以将场上一张牌移至伤害来源区域内。",
	["sxzuici0"] = "罪辞：你可以将场上一张牌移至%src区域内",

	["sx_xuezong"] = "薛综[艮]",
	["&sx_xuezong"] = "薛综",
	--["#sx_xuezong"] = "身曹心汉",
	--["illustrator:sx_xuezong"] = "L",

	["sxfunan"] = "复难",
	[":sxfunan"] = "每回合限一次，其他角色使用的牌被你抵消时，你可以获得之。",
	["sxjiexun"] = "戒训",
	[":sxjiexun"] = "结束阶段，你可以令一名角色弃置一张手牌，然后若此牌为♦，其摸两张牌。",
	["sxjiexun0"] = "戒训：你可以令一名角色弃置一张手牌",

	["sx_wangyuanji"] = "王元姬[艮]",
	["&sx_wangyuanji"] = "王元姬",
	["#sx_wangyuanji"] = "情雅抑华",
	["illustrator:sx_wangyuanji"] = "李秀森",

	["sxqianchong"] = "谦冲",
	[":sxqianchong"] = "锁定技，若你装备区内的牌数为奇数/偶数，你使用牌无次数/距离限制。",
	["sxshangjian"] = "尚俭",
	[":sxshangjian"] = "结束阶段，若你本回合失去的牌数小于等于你的体力值，你可以从弃牌堆中获得一张你本回合失去的牌。",

	["sx_zhonghui"] = "钟会[艮]",
	["&sx_zhonghui"] = "钟会",
	--["#sx_zhonghui"] = "身曹心汉",
	--["illustrator:sx_zhonghui"] = "L",

	["sxxingfa"] = "兴伐",
	[":sxxingfa"] = "准备阶段，若你的的手牌数大于等于体力值，你可以对一名其他角色造成1点伤害。",
	["sxxingfa0"] = "兴伐：你可以对一名其他角色造成1点伤害",

	["sx_xushu"] = "徐庶[艮]",
	["&sx_xushu"] = "徐庶",
	["#sx_xushu"] = "身曹心汉",
	["illustrator:sx_xushu"] = "L",

	["sxwuyan"] = "无言",
	[":sxwuyan"] = "锁定技，你的锦囊牌均视为【无懈可击】。",
	["sxjujian"] = "举荐",
	[":sxjujian"] = "每回合限一次，当你使用【无懈可击】后，你可以将此牌交给一名其他角色。",
	["sxjujian0"] = "举荐：你可以将此【无懈可击】交给一名其他角色",

	["sx_maliang"] = "马良[艮]",
	["&sx_maliang"] = "马良",
	--["#sx_maliang"] = "方整威重",
	--["illustrator:sx_maliang"] = "凡果",

	["sxxiemu"] = "协穆",
	[":sxxiemu"] = "其他角色出牌阶段限一次，其可以将一张基本牌展示并交给你，然后其本回合的攻击范围+1。",
	["sxnaman"] = "纳蛮",
	[":sxnaman"] = "出牌阶段限一次，你可以将任意张基本牌当做等量目标的【南蛮入侵】使用。",
	["sxxiemubf"] = "协穆:攻击范围+1",
	["sxxiemuvs"] = "协穆",
	[":sxxiemuvs"] = "出牌阶段限一次，你可以将一张基本牌展示并交给“协穆”技能角色，然后你本回合的攻击范围+1。",

	["sx_jiangwan"] = "蒋琬[艮]",
	["&sx_jiangwan"] = "蒋琬",
	["#sx_jiangwan"] = "方整威重",
	["illustrator:sx_jiangwan"] = "凡果",

	["sxbeiwu"] = "备武",
	[":sxbeiwu"] = "你可以将装备区里一张不为本回合置入的牌当做【无中生有】或【决斗】使用。",
	["sxchengshi"] = "承事",
	[":sxchengshi"] = "限定技，其他角色死亡时，你可以与其交换座次和装备区里的所有牌。",

	["sx_guanxing"] = "关兴[艮]",
	["&sx_guanxing"] = "关兴",
	["#sx_guanxing"] = "龙骧将军",
	["illustrator:sx_guanxing"] = "峰雨同程",

	["sxwuyou"] = "武佑",
	[":sxwuyou"] = "出牌阶段限一次，你可以拼点：若你没赢，你本回合获得“武圣”；赢的角色视为对没赢的角色使用一张【决斗】。",
}

sxfyqian = sgs.Package("sxfyqian", sgs.Package_GeneralPack)

sx_tianfeng = sgs.General(sxfyqian, "sx_tianfeng", "qun", 3)
sxgangjian = sgs.CreateTriggerSkillV2 {
	name = "sxgangjian",
	events = { sgs.EventPhaseStart, sgs.CardFinished },
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.CardFinished or not ctx.owner then return end
		local use = ctx.original_data:toCardUse()
		if table.contains(use.card:getSkillNames(), skill:objectName()) then
			if not use.card:hasFlag("DamageDone") then
				for _, p in sgs.list(use.to) do
					if p:isAlive() and p:getPhase() == sgs.Player_Start then
						room:setPlayerCardLimitation(p, "use", "TrickCard", true)
					end
				end
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local names, owners = {}, {}
			for _, p in sgs.list(room:getOtherPlayers(player)) do
				if p:hasSkill(skill:objectName()) then
					local dc = dummyCard()
					dc:setSkillName("_sxgangjian")
					if player:canSlash(p, dc, false) then
						table.insert(names, skill:objectName())
						table.insert(owners, p:objectName())
					end
				end
			end
			if #owners > 0 then
				return table.concat(names, "|"), table.concat(owners, "|")
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.invoker)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("sxgangjian")
		local dc = dummyCard()
		dc:setSkillName("_sxgangjian")
		room:useCard(sgs.CardUseStruct(dc, ctx.invoker, player))
		return false
	end,
}
sx_tianfeng:addSkill(sxgangjian)
sxguijieCard = sgs.CreateSkillCard {
	name = "sxguijieCard",
	target_fixed = true,
	on_validate_in_response = function(self, from)
		local room = from:getRoom()
		room:throwCard(self, self:getSkillName(), from)
		from:drawCards(1, self:getSkillName())
		local dc = dummyCard("jink")
		dc:setSkillName("sxguijie")
		return dc
	end,
	on_validate = function(self, use)
		local room = use.from:getRoom()
		room:throwCard(self, self:getSkillName(), use.from)
		use.from:drawCards(1, self:getSkillName())
		local dc = dummyCard("jink")
		dc:setSkillName("sxguijie")
		return dc
	end,
}
sxguijie = sgs.CreateViewAsSkillV2 {
	name = "sxguijie",
	n = 2,
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:getCardCount() > 1 and string.find(request:getPattern(), "jink") ~= nil
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		return candidate:isRed() and not player:isJilei(candidate)
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 2
	end,
	create_card = function(skill, request)
		local sc = sxguijieCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(id)
		end
		return sc
	end,
}
sx_tianfeng:addSkill(sxguijie)

sx_liuxie = sgs.General(sxfyqian, "sx_liuxie$", "qun", 3)
sxtianming = sgs.CreateTriggerSkillV2 {
	name = "sxtianming",
	events = { sgs.TargetConfirmed },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.to:contains(player) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:askForSkillInvoke(skill, ctx.original_data) then
			player:peiyin("tianming")
			player:throwAllHandCardsAndEquips(skill:objectName())
			player:drawCards(2, skill:objectName())
		end
		local x = 0
		for _, p in sgs.list(room:getAlivePlayers()) do
			if p:getHp() > x then
				x = p:getHp()
			end
		end
		local xp = nil
		for _, p in sgs.list(room:getAlivePlayers()) do
			if p:getHp() >= x then
				if xp then
					xp = nil
					break
				end
				xp = p
			end
		end
		if xp and xp ~= player and xp:askForSkillInvoke(skill, ctx.original_data) then
			xp:throwAllHandCardsAndEquips(skill:objectName())
			xp:drawCards(2, skill:objectName())
		end
		return false
	end,
}
sx_liuxie:addSkill(sxtianming)
sxmizhaoCard = sgs.CreateSkillCard {
	name = "sxmizhaoCard",
	target_fixed = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		if #targets < 1 then
			return to_select ~= source
		end
		return #targets < 2
	end,
	feasible = function(self, targets, player)
		return #targets == 2
	end,
	about_to_use = function(self, room, use)
		room:setTag("sxmizhaoData", ToData(use))
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("mizhao")
		local use = room:getTag("sxmizhaoData"):toCardUse()
		local dc = dummyCard()
		dc:addSubcards(player:handCards())
		dc:addSubcards(player:getEquipsId())
		if use.to:first():isAlive() then
			room:giveCard(player, use.to:first(), dc, "sxmizhao")
		end
		if use.to:first():isAlive() and use.to:last():isAlive() and use.to:first():askForSkillInvoke("sxmizhao", use.to:last(), false) then
			room:loseHp(use.to:first(), 1, true, use.to:first(), "sxmizhao")
			room:loseHp(use.to:last(), 1, true, use.to:first(), "sxmizhao")
		end
	end,
}
sxmizhaoVS = sgs.CreateViewAsSkillV2 {
	name = "sxmizhao",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@sxmizhao"
	end,
	create_card = function(skill, request)
		return sxmizhaoCard:clone()
	end,
}
sxmizhao = sgs.CreateTriggerSkillV2 {
	name = "sxmizhao",
	view_as_skill = sxmizhaoVS,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardFinished then
			if player:getPhase() == sgs.Player_Finish and player:getCardCount() > 0 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:askForUseCard(player, "@@sxmizhao", "sxmizhao0")
		return false
	end,
}
sx_liuxie:addSkill(sxmizhao)
sxzhongyan = sgs.CreateTriggerSkillV2 {
	name = "sxzhongyan$",
	events = { sgs.Death },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who:getKingdom() == "qun" and player:hasLordSkill(skill:objectName()) and player:isWounded() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:recover(player, sgs.RecoverStruct(skill:objectName(), player))
		return false
	end,
}
sx_liuxie:addSkill(sxzhongyan)

sx_simazhao = sgs.General(sxfyqian, "sx_simazhao", "wei", 4)
sxzhaoxin = sgs.CreateTriggerSkillV2 {
	name = "sxzhaoxin",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getHandcardNum() > 0 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		player:peiyin("zhaoxin")
		room:showAllCards(player)
		local hs = player:getHandcards()
		for _, h in sgs.list(hs) do
			if h:getColor() ~= hs:last():getColor() then
				return false
			end
		end
		local tp = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "sxzhaoxin0")
		if tp then
			room:damage(sgs.DamageStruct(skill:objectName(), player, tp))
		end
		return false
	end,
}
sx_simazhao:addSkill(sxzhaoxin)

sx_guonvwang = sgs.General(sxfyqian, "sx_guonvwang", "wei", 3, false)
local function sxwufei_effect(skill, room, player)
	local aps = sgs.SPlayerList()
	for _, p in sgs.list(room:getAlivePlayers()) do
		if p:isFemale() and p:getHandcardNum() > 0 then
			aps:append(p)
		end
	end
	local tp = room:askForPlayerChosen(player, aps, skill:objectName(), "sxwufei0", true, true)
	if tp then
		player:peiyin("wufei")
		room:showAllCards(tp)
		local sc = room:askForExchange(tp, skill:objectName(), 1, 1, false, "sxwufei1")
		if sc then
			local dc = dummyCard()
			for _, h in sgs.list(tp:getHandcards()) do
				if h:getColor() == sc:getColor() and not tp:isJilei(h) then
					dc:addSubcard(h)
				end
			end
			room:throwCard(dc, skill:objectName(), tp)
			tp:drawCards(1, skill:objectName())
		end
	end
end
sxwufei = sgs.CreateTriggerSkillV2 {
	name = "sxwufei",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:isAlive() and player:getPhase() == sgs.Player_Start then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		sxwufei_effect(skill, room, player)
		return false
	end,
}
sx_guonvwang:addSkill(sxwufei)
sxjiaochong = sgs.CreateTriggerSkillV2 {
	name = "sxjiaochong",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:isAlive() and player:isMale() and player:getPhase() == sgs.Player_Finish then
			local names, owners = {}, {}
			for _, p in sgs.list(room:getAllPlayers()) do
				if p:hasSkill(skill:objectName()) then
					for _, q in sgs.list(room:getAlivePlayers()) do
						if q:isFemale() and q:getHandcardNum() > 0 then
							table.insert(names, skill:objectName())
							table.insert(owners, p:objectName())
							break
						end
					end
				end
			end
			if #owners > 0 then
				return table.concat(names, "|"), table.concat(owners, "|")
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("jiaochong")
		local wf = sgs.Sanguosha:getTriggerSkill("sxwufei")
		if wf then
			sxwufei_effect(wf, room, player)
		end
		return false
	end,
}
sx_guonvwang:addSkill(sxjiaochong)

sx_jiakui = sgs.General(sxfyqian, "sx_jiakui", "wei", 3)
sxzhongzuo = sgs.CreateTriggerSkillV2 {
	name = "sxzhongzuo",
	events = { sgs.Damaged, sgs.Damage, sgs.EventPhaseChanging },
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player:isAlive()) then return end
		if event == sgs.EventPhaseChanging then
			local change = ctx.original_data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				if ctx.owner:getMark("sxzhongzuoDamage-Clear") > 0 then
					room:sendCompulsoryTriggerLog(ctx.owner, skill:objectName())
					ctx.owner:peiyin("zhongzuo")
					local aps = SPlayerList(ctx.owner, player)
					room:sortByActionOrder(aps)
					room:drawCards(aps, 1, skill:objectName())
				end
			end
		else
			player:addMark("sxzhongzuoDamage-Clear")
		end
	end,
}
sx_jiakui:addSkill(sxzhongzuo)
sxwanlan = sgs.CreateTriggerSkillV2 {
	name = "sxwanlan",
	events = { sgs.Dying },
	frequency = sgs.Skill_Limited,
	limit_mark = "@sxwanlan",
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Dying then
			local dying = data:toDying()
			if dying.who ~= player and player:getMark("@sxwanlan") > 0 and player:getHandcardNum() > 0 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local dying = ctx.original_data:toDying()
		return player:askForSkillInvoke(skill, dying.who)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local dying = ctx.original_data:toDying()
		player:peiyin("wanlan")
		room:doSuperLightbox(player, skill:objectName())
		room:removePlayerMark(player, "@sxwanlan")
		room:giveCard(player, dying.who, player:handCards(), skill:objectName())
		room:recover(dying.who, sgs.RecoverStruct(skill:objectName(), player, 1 - dying.who:getHp()))
		return false
	end,
}
sx_jiakui:addSkill(sxwanlan)

sx_yufan = sgs.General(sxfyqian, "sx_yufan", "wu", 3)
sxzongxuan = sgs.CreateTriggerSkillV2 {
	name = "sxzongxuan",
	events = { sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if
				move.from_places:contains(sgs.Player_PlaceHand)
				and player:objectName() == move.from:objectName()
				and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
			then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local tps = sgs.SPlayerList()
		for _, p in sgs.list(room:getAlivePlayers()) do
			if player:canDiscard(p, "ej") then
				tps:append(p)
			end
		end
		local tp = room:askForPlayerChosen(player, tps, skill:objectName(), "sxzongxuan0", true, true)
		if tp then
			ctx.targets:append(tp)
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local tp = ctx.targets:first()
		player:peiyin("zongxuan")
		local id = room:askForCardChosen(player, tp, "ej", skill:objectName(), false, sgs.Card_MethodDiscard)
		if id > -1 then
			room:throwCard(id, skill:objectName(), tp, player)
		end
		return false
	end,
}
sx_yufan:addSkill(sxzongxuan)
sxzhiyan = sgs.CreateTriggerSkillV2 {
	name = "sxzhiyan",
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseStart, sgs.EventPhaseChanging },
	on_record = function(skill, event, room, player, ctx)
		if not player or not player:isAlive() then return end
		if event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile and kesxV2RecordOnce(room, skill, ctx) then
				local ids = player:getTag("sxzhiyanIds"):toIntList()
				for _, id in sgs.list(move.card_ids) do
					ids:append(id)
				end
				player:setTag("sxzhiyanIds", ToData(ids))
			end
		elseif event == sgs.EventPhaseChanging then
			if ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
				player:removeTag("sxzhiyanIds")
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			local ids = player:getTag("sxzhiyanIds"):toIntList()
			if ids:length() > 0 then
				local ids2 = sgs.IntList()
				for _, id in sgs.list(ids) do
					local c = sgs.Sanguosha:getCard(id)
					if c:isKindOf("EquipCard") and room:getCardOwner(id) == nil then
						ids2:append(id)
					end
				end
				if ids2:length() > 0 then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local ids = player:getTag("sxzhiyanIds"):toIntList()
		local ids2 = sgs.IntList()
		for _, id in sgs.list(ids) do
			local c = sgs.Sanguosha:getCard(id)
			if c:isKindOf("EquipCard") and room:getCardOwner(id) == nil then
				ids2:append(id)
			end
		end
		if ids2:length() > 0 then
			room:fillAG(ids2, player)
			if player:askForSkillInvoke(skill, ToData(ids2)) then
				return true
			end
			room:clearAG(player)
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("zhiyan")
		local ids = player:getTag("sxzhiyanIds"):toIntList()
		local ids2 = sgs.IntList()
		for _, id in sgs.list(ids) do
			local c = sgs.Sanguosha:getCard(id)
			if c:isKindOf("EquipCard") and room:getCardOwner(id) == nil then
				ids2:append(id)
			end
		end
		if ids2:length() > 0 then
			local id = room:askForAG(player, ids2, false, skill:objectName())
			room:obtainCard(player, id)
		end
		room:clearAG(player)
		return false
	end,
}
sx_yufan:addSkill(sxzhiyan)

sx_zhugeke = sgs.General(sxfyqian, "sx_zhugeke", "wu", 3)
sxaocai = sgs.CreateTriggerSkillV2 {
	name = "sxaocai",
	events = { sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseChanging and player and player:isAlive() then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local names, owners = {}, {}
				for _, p in sgs.list(room:getAllPlayers()) do
					if p:isKongcheng() and p:hasSkill(skill:objectName()) then
						table.insert(names, skill:objectName())
						table.insert(owners, p:objectName())
					end
				end
				if #owners > 0 then
					return table.concat(names, "|"), table.concat(owners, "|")
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("aocai")
		local ids = room:getNCards(2)
		room:fillAG(ids, player)
		local id = room:askForAG(player, ids, true, skill:objectName())
		room:clearAG(ctx.invoker)
		room:returnToTopDrawPile(ids)
		if id >= 0 then
			room:obtainCard(ctx.invoker, id)
		end
		return false
	end,
}
sx_zhugeke:addSkill(sxaocai)
sxduwuCard = sgs.CreateSkillCard {
	name = "sxduwuCard",
	target_fixed = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		return #targets < 1 and source:inMyAttackRange(to_select)
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("duwu")
		for _, p in sgs.list(targets) do
			room:damage(sgs.DamageStruct("sxduwu", player, p))
		end
	end,
}
sxduwu = sgs.CreateViewAsSkillV2 {
	name = "sxduwu",
	n = 999,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:usedTimes("#sxduwuCard") < 1 and player:canDiscard(player, "h")
		end
		return request:getPattern() == "@@sxduwu"
	end,
	card_selection_feasible = function(skill, request)
		return true
	end,
	create_card = function(skill, request)
		local dc = sxduwuCard:clone()
		dc:addSubcards(request:getInitiator():getHandcards())
		return dc
	end,
}
sx_zhugeke:addSkill(sxduwu)

sx_mengda = sgs.General(sxfyqian, "sx_mengda", "shu", 4)
sxzhuan = sgs.CreateTriggerSkillV2 {
	name = "sxzhuan",
	events = { sgs.Damaged },
	frequency = sgs.Skill_Compulsory,
	on_record = function(skill, event, room, player, ctx)
		if not (player and player:isAlive() and event == sgs.Damaged) then return end
		player:addMark("sxzhuanDamaged-Clear")
		if player:getMark("sxzhuanDamaged-Clear") == 1 and player:hasSkill(skill:objectName()) then
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			player:peiyin("keolgoude")
			player:drawCards(3, skill:objectName())
			local damage = ctx.original_data:toDamage()
			if damage.from and damage.from:isAlive() then
				local id = room:askForCardChosen(damage.from, player, "he", skill:objectName())
				if id >= 0 then
					room:obtainCard(damage.from, id, false)
				end
			end
		end
	end,
}
sx_mengda:addSkill(sxzhuan)

sgs.LoadTranslationTable {

	["sx_mengda"] = "孟达[乾]",
	["#sx_mengda"] = "据国向己",
	["illustrator:sx_mengda"] = "张帅",

	["sxzhuan"] = "逐安",
	[":sxzhuan"] = "锁定技，当你每回合首次受到伤害后，你摸三张牌，然后伤害来源获得你一张牌。",

	["sx_zhugeke"] = "诸葛恪[乾]",
	--["#sx_zhugeke"] = "肃齐万里",
	--["illustrator:sx_zhugeke"] = "凡果",

	["sxaocai"] = "傲才",
	[":sxaocai"] = "每回合结束时，若你没有手牌，你可以观看牌堆顶两张牌，然后你可以获得其中一张。",
	["sxduwu"] = "黩武",
	[":sxduwu"] = "出牌阶段限一次，你可以弃置所有手牌，然后对攻击范围内一名角色造成1点伤害。",

	["sx_yufan"] = "虞翻[乾]",
	--["#sx_yufan"] = "肃齐万里",
	--["illustrator:sx_yufan"] = "凡果",

	["sxzongxuan"] = "纵玄",
	[":sxzongxuan"] = "当你的手牌因弃置而进入弃牌堆后，你可以弃置场上一张牌。",
	["sxzhiyan"] = "直言",
	[":sxzhiyan"] = "结束阶段，你可以获得本回合进入弃牌堆的一张装备牌。",

	["sx_jiakui"] = "贾逵[乾]",
	["#sx_jiakui"] = "肃齐万里",
	--["illustrator:sx_jiakui"] = "凡果",

	["sxzhongzuo"] = "忠佐",
	[":sxzhongzuo"] = "锁定技，一名角色回合结束时，若你于本回合造成或受到过伤害，你与其各摸一张牌。",
	["sxwanlan"] = "挽澜",
	[":sxwanlan"] = "限定技，其他角色进入濒死状态时，你可以将所有手牌交给其，然后其回复体力至1点。",

	["sx_guonvwang"] = "郭女王[乾]",
	["#sx_guonvwang"] = "文德皇后",
	["illustrator:sx_guonvwang"] = "凡果",

	["sxwufei"] = "诬诽",
	[":sxwufei"] = "准备阶段，你可以令一名女性角色展示所有手牌，然后其弃置其中一种颜色的所有牌并摸一张牌。",
	["sxjiaochong"] = "椒宠",
	[":sxjiaochong"] = "男性角色的结束阶段，你可以发动“诬诽”。",
	["sxwufei0"] = "你可以对一名女性发动“诬诽”",
	["sxwufei1"] = "诬诽：请选择一张牌弃置所有颜色",

	["sx_simazhao"] = "司马昭[乾]",
	["#sx_simazhao"] = "四海威服",
	--["illustrator:sx_simazhao"] = "城与橙与程",

	["sxzhaoxin"] = "昭心",
	[":sxzhaoxin"] = "锁定技，准备阶段，你展示所有手牌，若颜色相同，你对一名角色造成1点伤害。",
	["sxzhaoxin0"] = "昭心：请选择对一名角色造成伤害",

	["sx_liuxie"] = "刘协[乾]",
	["#sx_liuxie"] = "汉末天子",
	--["illustrator:sx_liuxie"] = "城与橙与程",

	["sxtianming"] = "天命",
	[":sxtianming"] = "当你成为【杀】的目标后，你和体力值唯一最大的角色依次可以弃置所有牌，然后摸两张牌。",
	["sxmizhao"] = "密诏",
	[":sxmizhao"] = "结束阶段，你可以将所有手牌交给一名其他角色并选择另一名角色，然后其可以与你选择的角色各失去1点体力。",
	["sxzhongyan"] = "终焉",
	[":sxzhongyan"] = "主公技，其他群势力角色死亡时，你可以回复1点体力。",
	["sxmizhao0"] = "你可以发动“密诏”选择两名角色",

	["sx_tianfeng"] = "田丰[乾]",
	["#sx_tianfeng"] = "天姿竭杰",
	["illustrator:sx_tianfeng"] = "城与橙与程",

	["sxgangjian"] = "刚谏",
	[":sxgangjian"] = "其他角色的准备阶段，你可以令其视为对你使用一张【杀】，若此【杀】未造成伤害，其本回合不能使用锦囊牌。",
	["sxguijie"] = "瑰杰",
	[":sxguijie"] = "当你需要使用或打出【闪】时，你可以弃置两张红色牌并摸一张牌，视为使用或打出之。",
}

sxfydui = sgs.Package("sxfydui", sgs.Package_GeneralPack)

sx_caozhen = sgs.General(sxfydui, "sx_caozhen", "wei", 4)
sxsidi = sgs.CreateTriggerSkillV2 {
	name = "sxsidi",
	events = { sgs.CardResponded },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardResponded and player and player:isAlive() then
			local res = data:toCardResponse()
			if res.m_card:isKindOf("Slash") then
				local names, owners = {}, {}
				for _, p in sgs.list(room:getAllPlayers()) do
					if p:hasSkill(skill:objectName()) then
						table.insert(names, skill:objectName())
						table.insert(owners, p:objectName())
					end
				end
				if #owners > 0 then
					return table.concat(names, "|"), table.concat(owners, "|")
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("sidi")
		player:drawCards(1, skill:objectName())
		return false
	end,
}
sx_caozhen:addSkill(sxsidi)

sx_dongyun = sgs.General(sxfydui, "sx_dongyun", "shu", 3)
sxbingzheng = sgs.CreateTriggerSkillV2 {
	name = "sxbingzheng",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player and player:isAlive() and player:getPhase() == sgs.Player_Finish then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local tps = sgs.SPlayerList()
		for _, p in sgs.list(room:getAlivePlayers()) do
			if p:canDiscard(p, "he") then
				tps:append(p)
			end
		end
		local tp = room:askForPlayerChosen(player, tps, skill:objectName(), "sxbingzheng0", true, true)
		if tp then
			ctx.targets:append(tp)
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local tp = ctx.targets:first()
		room:askForDiscard(tp, skill:objectName(), 1, 1, false, true)
		if tp:getHandcardNum() ~= tp:getHp() then
			room:loseHp(player, 1, true, player, skill:objectName())
		end
		return false
	end,
}
sx_dongyun:addSkill(sxbingzheng)
sxduliang = sgs.CreateTriggerSkillV2 {
	name = "sxduliang",
	events = { sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Damaged then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		--player:peiyin("sheyan")
		player:drawCards(1, skill:objectName())
		if player:getHp() == player:getHandcardNum() then
			room:recover(player, sgs.RecoverStruct(skill:objectName(), player))
		end
		return false
	end,
}
sx_dongyun:addSkill(sxduliang)

sx_baosanniang = sgs.General(sxfydui, "sx_baosanniang", "shu", 3, false)
sxzhennan = sgs.CreateTriggerSkillV2 {
	name = "sxzhennan",
	events = { sgs.EventPhaseStart, sgs.CardFinished },
	on_record = function(skill, event, room, player, ctx)
		if not (player and player:isAlive() and event == sgs.CardFinished and ctx.owner) then return end
		local use = ctx.original_data:toCardUse()
		if use.card:getTypeId() > 0 and player:getMark("&zhennan-Clear") > 0 then
			room:setPlayerMark(player, "&zhennan-Clear", 0)
			if use.card:isRed() and room:getCardOwner() == nil then
				player:obtainCard(use.card)
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player and player:isAlive() and player:getPhase() == sgs.Player_Start then
			local names, owners = {}, {}
			for _, p in sgs.list(room:getOtherPlayers(player)) do
				if p:hasSkill(skill:objectName()) then
					table.insert(names, skill:objectName())
					table.insert(owners, p:objectName())
				end
			end
			if #owners > 0 then
				return table.concat(names, "|"), table.concat(owners, "|")
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForCard(player, ".", "sxzhennan0:" .. ctx.invoker:objectName(), ctx.original_data, skill:objectName()) ~= nil
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("zhennan")
		room:setPlayerMark(player, "&zhennan-Clear", 1)
		return false
	end,
}
sx_baosanniang:addSkill(sxzhennan)
sxshuyong = sgs.CreateTriggerSkillV2 {
	name = "sxshuyong",
	events = { sgs.CardUsed, sgs.EventPhaseStart },
	on_record = function(skill, event, room, player, ctx)
		if not (player and player:isAlive() and ctx.owner) then return end
		if event == sgs.CardUsed then
			local use = ctx.original_data:toCardUse()
			if use.card:getTypeId() > 0 and player:hasFlag("CurrentPlayer") then
				player:setTag("sxshuyongPrev", ToData(player:getTag("sxshuyongName"):toString()))
				player:setTag("sxshuyongName", ToData(use.card:objectName()))
			end
		elseif player:getPhase() == sgs.Player_NotActive then
			player:removeTag("sxshuyongName")
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardUsed and player and player:isAlive() and player:hasFlag("CurrentPlayer") then
			local use = data:toCardUse()
			if use.card:getTypeId() > 0 and use.card:sameNameWith(player:getTag("sxshuyongPrev"):toString()) then
				local names, owners = {}, {}
				for _, p in sgs.list(room:getOtherPlayers(player)) do
					if p:hasSkill(skill:objectName()) then
						table.insert(names, skill:objectName())
						table.insert(owners, p:objectName())
					end
				end
				if #owners > 0 then
					return table.concat(names, "|"), table.concat(owners, "|")
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("shuyong")
		player:drawCards(1, skill:objectName())
		return false
	end,
}
sx_baosanniang:addSkill(sxshuyong)

sx_liuba = sgs.General(sxfydui, "sx_liuba", "shu", 3)
sxduanbi = sgs.CreateTriggerSkillV2 {
	name = "sxduanbi",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player and player:isAlive() and player:getPhase() == sgs.Player_Finish and player:canDiscard(player, "h") then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("duanbi")
		player:throwAllHandCards(skill:objectName())
		local tps = room:askForPlayersChosen(player, room:getAlivePlayers(), skill:objectName(), 2, 2, "sxduanbi0")
		for _, p in sgs.qlist(tps) do
			room:doAnimate(1, player:objectName(), p:objectName())
		end
		room:drawCards(tps, 2, skill:objectName())
		return false
	end,
}
sx_liuba:addSkill(sxduanbi)

sx_kongrong = sgs.General(sxfydui, "sx_kongrong", "qun", 3)
sxlirang = sgs.CreateTriggerSkillV2 {
	name = "sxlirang",
	events = { sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.EventPhaseChanging },
	on_record = function(skill, event, room, player, ctx)
		if not (player and player:isAlive() and ctx.owner) then return end
		if event == sgs.CardsMoveOneTime then
			if player:getPhase() ~= sgs.Player_Finish then return end
			local move = ctx.original_data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile and kesxV2RecordOnce(room, skill, ctx) then
				local ids = player:getTag("sxlirangIds"):toIntList()
				for _, id in sgs.list(move.card_ids) do
					ids:append(id)
				end
				player:setTag("sxlirangIds", ToData(ids))
			end
		elseif event == sgs.EventPhaseChanging then
			if ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
				player:removeTag("sxlirangIds")
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseEnd and player and player:isAlive() and player:getPhase() == sgs.Player_Finish then
			local ids = player:getTag("sxlirangIds"):toIntList()
			if ids:length() < 1 then return false end
			local names, owners = {}, {}
			for _, p in sgs.list(room:getOtherPlayers(player)) do
				if p:hasSkill(skill:objectName()) then
					local dc = dummyCard()
					for _, id in sgs.list(ids) do
						local c = sgs.Sanguosha:getCard(id)
						if c:isRed() and room:getCardOwner(id) == nil then
							dc:addSubcard(id)
						end
					end
					if dc:subcardsLength() > 0 then
						table.insert(names, skill:objectName())
						table.insert(owners, p:objectName())
					end
				end
			end
			if #owners > 0 then
				return table.concat(names, "|"), table.concat(owners, "|")
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local ids = ctx.invoker:getTag("sxlirangIds"):toIntList()
		local dc = dummyCard()
		for _, id in sgs.list(ids) do
			local c = sgs.Sanguosha:getCard(id)
			if c:isRed() and room:getCardOwner(id) == nil then
				dc:addSubcard(id)
			end
		end
		if dc:subcardsLength() < 1 then return false end
		room:fillAG(dc:getSubcards(), player)
		local sc = room:askForExchange(player, skill:objectName(), 1, 1, true, "sxlirang0:" .. ctx.invoker:objectName(), true)
		if sc then
			ctx.extra_data:setValue(sc:getEffectiveId())
			return true
		end
		room:clearAG(player)
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local ids = ctx.invoker:getTag("sxlirangIds"):toIntList()
		local dc = dummyCard()
		for _, id in sgs.list(ids) do
			local c = sgs.Sanguosha:getCard(id)
			if c:isRed() and room:getCardOwner(id) == nil then
				dc:addSubcard(id)
			end
		end
		player:peiyin("heg_lirang")
		player:skillInvoked(skill, 0)
		ctx.invoker:obtainCard(sgs.Sanguosha:getCard(ctx.extra_data:toInt()), false)
		room:obtainCard(player, dc)
		room:clearAG(player)
		return false
	end,
}
sx_kongrong:addSkill(sxlirang)

sx_zoushi = sgs.General(sxfydui, "sx_zoushi", "qun", 3, false)
sxhuoshui = sgs.CreateTriggerSkillV2 {
	name = "sxhuoshui",
	events = { sgs.DamageForseen },
	frequency = sgs.Skill_Compulsory,
	on_record = function(skill, event, room, player, ctx)
		if
			not (ctx.owner and player and player:isAlive() and event == sgs.DamageForseen)
			or ctx.owner == player
			or player:getJudgingArea():length() < 1
		then
			return
		end
		ctx.owner:peiyin("huoshoug")
		room:sendCompulsoryTriggerLog(ctx.owner, skill:objectName())
		player:damageRevises(ctx.original_data, 1)
	end,
}
sx_zoushi:addSkill(sxhuoshui)
sxqingchengCard = sgs.CreateSkillCard {
	name = "sxqingchengCard",
	target_fixed = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		if #targets < 1 and to_select ~= source then
			local dc = dummyCard("indulgence")
			dc:addSubcard(self:getSubcards():first())
			if source:isLocked(dc) or source:isProhibited(source, dc) then
				return
			end
			dc = dummyCard("indulgence")
			dc:addSubcard(self:getSubcards():last())
			if source:isLocked(dc) or source:isProhibited(to_select, dc) then
				return
			end
			return true
		end
	end,
	about_to_use = function(self, room, use)
		use.from:peiyin("heg_qingcheng")
		local dc = dummyCard("indulgence")
		dc:addSubcards(self:getSubcards():first())
		dc:setSkillName("sxqingcheng")
		if use.from:canUse(dc, use.from) then
			room:useCard(sgs.CardUseStruct(dc, use.from, use.from))
		end
		dc = dummyCard("indulgence")
		dc:addSubcards(self:getSubcards():last())
		dc:setSkillName("sxqingcheng")
		if use.from:canUse(dc, use.to:last()) then
			room:useCard(sgs.CardUseStruct(dc, use.from, use.to))
		end
	end,
}
sxqingcheng = sgs.CreateViewAsSkillV2 {
	name = "sxqingcheng",
	n = 2,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:getCardCount() > 1 and player:usedTimes("#sxqingchengCard") < 1
	end,
	can_select_card = function(skill, request, candidate)
		return candidate:isRed() and candidate:getTypeId() ~= 2
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 2
	end,
	create_card = function(skill, request)
		local sc = sxqingchengCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(id)
		end
		return sc
	end,
}
sx_zoushi:addSkill(sxqingcheng)

sx_sunluyu = sgs.General(sxfydui, "sx_sunluyu", "wu", 3, false)
sxmumu = sgs.CreateTriggerSkillV2 {
	name = "sxmumu",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if
			event == sgs.EventPhaseStart
			and player
			and player:isAlive()
			and player:getPhase() == sgs.Player_Start
			and player:canDiscard(player, "h")
		then
			for _, p in sgs.list(room:getAlivePlayers()) do
				local es = p:getEquips()
				if es:length() < 1 then
					continue
				end
				for _, q in sgs.list(room:getAlivePlayers()) do
					local found = false
					for _, e in sgs.list(es) do
						local n = e:getRealCard():toEquipCard():location()
						if q:hasEquipArea(n) and q:getEquip(n) == nil then
							found = true
							break
						end
					end
					if found then
						return skill:objectName()
					end
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		player:peiyin("duanbi")
		return room:askForCard(player, ".", "sxmumu0", ctx.original_data, skill:objectName()) ~= nil
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("mumu")
		local tps = sgs.SPlayerList()
		for _, p in sgs.list(room:getAlivePlayers()) do
			local es = p:getEquips()
			if es:length() < 1 then
				continue
			end
			for _, q in sgs.list(room:getAlivePlayers()) do
				local found = false
				for _, e in sgs.list(es) do
					local n = e:getRealCard():toEquipCard():location()
					if q:hasEquipArea(n) and q:getEquip(n) == nil then
						found = true
						break
					end
				end
				if found then
					tps:append(p)
					break
				end
			end
		end
		local tp = room:askForPlayerChosen(player, tps, "sxmumu1")
		room:doAnimate(1, player:objectName(), tp:objectName())
		local ids = sgs.IntList()
		for _, q in sgs.list(room:getAlivePlayers()) do
			for _, e in sgs.list(tp:getEquips()) do
				local n = e:getRealCard():toEquipCard():location()
				if q:hasEquipArea(n) and q:getEquip(n) == nil then
				else
					ids:append(e:getId())
				end
			end
		end
		local id = room:askForCardChosen(player, tp, "e", skill:objectName(), false, sgs.Card_MethodNone, ids)
		if id < 0 then
			return false
		end
		tps:clear()
		local e = sgs.Sanguosha:getCard(id)
		for _, q in sgs.list(room:getAlivePlayers()) do
			local n = e:getRealCard():toEquipCard():location()
			if q:hasEquipArea(n) and q:getEquip(n) == nil then
				tps:append(q)
			end
		end
		local tp2 = room:askForPlayerChosen(player, tps, "sxmumu2")
		if tp2 then
			room:doAnimate(1, player:objectName(), tp2:objectName())
			room:moveCardTo(e, tp2, sgs.Player_PlaceEquip, true)
		end
		return false
	end,
}
sx_sunluyu:addSkill(sxmumu)
sxmeibu = sgs.CreateTriggerSkillV2 {
	name = "sxmeibu",
	events = { sgs.CardUsed },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardUsed and player and player:isAlive() then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:getWeapon() and player:canDiscard(player, "h") then
				local names, owners = {}, {}
				for _, p in sgs.list(room:getAllPlayers()) do
					if p:hasSkill(skill:objectName()) then
						table.insert(names, skill:objectName())
						table.insert(owners, p:objectName())
					end
				end
				if #owners > 0 then
					return table.concat(names, "|"), table.concat(owners, "|")
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.invoker)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("meibu")
		room:askForDiscard(ctx.invoker, skill:objectName(), 1, 1)
		return false
	end,
}
sx_sunluyu:addSkill(sxmeibu)

sx_zhoufang = sgs.General(sxfydui, "sx_zhoufang", "wu", 3)
sxqijianCard = sgs.CreateSkillCard {
	name = "sxqijianCard",
	target_fixed = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		return #targets < 1 or #targets < 2 and targets[1]:getHandcardNum() == to_select:getHandcardNum()
	end,
	feasible = function(self, targets, player)
		return #targets == 2
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("duanfa")
		for i, p in sgs.list(targets) do
			local n = 2
			if i == 2 then
				n = 1
			end
			local tp = targets[n]
			if p:canDiscard(tp, "he") and room:askForChoice(p, "sxqijian", "sxqijian1+sxqijian2", ToData(tp)) == "sxqijian1" then
				n = room:askForCardChosen(p, tp, "he", "sxqijian", false, sgs.Card_MethodDiscard)
				if n >= 0 then
					room:throwCard(id, "sxqijian", tp, p)
				end
			else
				tp:drawCards(1, "sxqijian")
			end
		end
	end,
}
sxqijianVS = sgs.CreateViewAsSkillV2 {
	name = "sxqijian",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@sxqijian"
	end,
	create_card = function(skill, request)
		return sxqijianCard:clone()
	end,
}
sxqijian = sgs.CreateTriggerSkillV2 {
	name = "sxqijian",
	events = { sgs.EventPhaseStart },
	view_as_skill = sxqijianVS,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:askForUseCard(player, "@@sxqijian", "sxqijian0")
		return false
	end,
}
sx_zhoufang:addSkill(sxqijian)
sxyoudiVS = sgs.CreateViewAsSkillV2 {
	name = "sxyoudi",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@sxyoudi"
	end,
	can_select_card = function(skill, request, candidate)
		return candidate:isRed()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local sc = sgs.Sanguosha:cloneCard("snatch")
		sc:setSkillName(skill:objectName())
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(id)
		end
		return sc
	end,
}
sxyoudi = sgs.CreateTriggerSkillV2 {
	name = "sxyoudi",
	events = { sgs.EventPhaseStart },
	view_as_skill = sxyoudiVS,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:askForUseCard(player, "@@sxyoudi", "sxyoudi0")
		return false
	end,
}
sx_zhoufang:addSkill(sxyoudi)

sgs.LoadTranslationTable {

	["sx_zhoufang"] = "周鲂[乾]",
	["#sx_zhoufang"] = "下发载义",
	["illustrator:sx_zhoufang"] = "黑白画谱",

	["sxqijian"] = "七笺",
	[":sxqijian"] = "准备阶段，你可以令两名手牌数之和为7角色各选择一项：1.弃置对方一张牌；2.令对方摸一张牌。",
	["sxyoudi"] = "诱敌",
	[":sxyoudi"] = "结束阶段，你可以将一张红色牌当做【顺手牵羊】使用。",
	["sxqijian0"] = "你可以发动“七笺”选择两名手牌和为7的角色",
	["sxqijian1"] = "弃置对方一张牌",
	["sxqijian2"] = "令对方摸一张牌",
	["sxyoudi0"] = "你可以发动“诱敌”将红色牌当做【顺手牵羊】使用",

	["sx_sunluyu"] = "孙鲁育[乾]",
	["#sx_sunluyu"] = "舍身饲虎",
	["illustrator:sx_sunluyu"] = "depp",

	["sxmumu"] = "穆穆",
	[":sxmumu"] = "准备阶段，你可以弃置一张手牌，然后移动场上一张装备牌。",
	["sxmeibu"] = "魅步",
	[":sxmeibu"] = "装备着武器牌的角色使用【杀】时，你可以令其弃置一张手牌。",
	["sxmumu0"] = "你可以发动“穆穆”弃置手牌移动场上装备",
	["sxmumu1"] = "穆穆：请选择要移动装备的角色",
	["sxmumu2"] = "穆穆：请选择移动目标",

	["sx_zoushi"] = "邹氏[乾]",
	["#sx_zoushi"] = "祸心之魅",
	["illustrator:sx_zoushi"] = "Tuu",

	["sxhuoshui"] = "祸水",
	[":sxhuoshui"] = "锁定技，判定区有牌的其他角色受到的伤害+1。",
	["sxqingcheng"] = "倾城",
	[":sxqingcheng"] = "出牌阶段限一次，你可以将两张红色非锦囊牌当两张【乐不思蜀】依次对你和一名其他角色使用。",

	["sx_kongrong"] = "孔融[乾]",
	["#sx_kongrong"] = "建安文首",
	["illustrator:sx_kongrong"] = "凝聚永恒",

	["sxlirang"] = "礼让",
	[":sxlirang"] = "一名角色的弃牌阶段结束时，你可以交给其一张牌，然后获得此阶段进入弃牌堆的所有红色牌。",
	["sxlirang0"] = "你可以发动“礼让”交给%src一张牌获得这些牌",

	["sx_liuba"] = "刘巴[乾]",
	["#sx_liuba"] = "撰科行律",
	["illustrator:sx_liuba"] = "君桓文化",

	["sxduanbi"] = "锻币",
	[":sxduanbi"] = "结束阶段，你可以弃置所有手牌，然后令两名角色各摸两张牌。",
	["sxduanbi0"] = "锻币：请选择两名角色各摸两张牌",

	["sx_baosanniang"] = "鲍三娘[乾]",
	["#sx_baosanniang"] = "慕花之姝",
	["illustrator:sx_baosanniang"] = "张帅",

	["sxzhennan"] = "镇南",
	[":sxzhennan"] = "其他角色的准备阶段，你可以弃置一张手牌，若如此做，其本回合使用下一张牌后，若此牌为红色，你令其获得之。",
	["sxshuyong"] = "姝勇",
	[":sxshuyong"] = "当其他角色于其回合内连续使用两张同名牌时，你可以摸一张牌。",
	["sxzhennan0"] = "你可以发动“镇南”弃置一张手牌令%src使用下一红色牌回收",

	["sx_dongyun"] = "董允[乾]",
	--["#sx_dongyun"] = "据国向己",
	--["illustrator:sx_dongyun"] = "张帅",

	["sxbingzheng"] = "秉正",
	[":sxbingzheng"] = "结束阶段，你可以令一名角色弃置一张牌，若其手牌数不等于体力值，你失去1点体力。",
	["sxduliang"] = "笃良",
	[":sxduliang"] = "当你受到伤害后，你可以摸一张牌，若你的手牌等于体力值，你回复1点体力。",
	["sxbingzheng0"] = "你可以发动“秉正”令一名角色弃置一张牌",

	["sx_caozhen"] = "曹真[乾]",
	--["#sx_caozhen"] = "据国向己",
	--["illustrator:sx_caozhen"] = "张帅",

	["sxsidi"] = "司敌",
	[":sxsidi"] = "当有角色打出【杀】，你可以摸一张牌。",
}

sxfy_qinglong = sgs.Package("sxfy_qinglong", sgs.Package_GeneralPack)

sx_nanhua = sgs.General(sxfy_qinglong, "sx_nanhua", "qun", 3)
sxxianluCard = sgs.CreateSkillCard {
	name = "sxxianluCard",
	target_fixed = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		return #targets < 1 and source:canDiscard(to_select, "e")
	end,
	on_use = function(self, room, player, targets)
		for i, p in sgs.list(targets) do
			local id = room:askForCardChosen(player, p, "e", "sxxianlu", false, sgs.Card_MethodDiscard)
			if id >= 0 then
				room:throwCard(id, "sxxianlu", p, player)
				local dc = dummyCard("indulgence", "sxxianlu")
				dc:addSubcard(id)
				if dc:isRed() and not player:isProhibited(player, dc) then
					room:moveCardTo(dc, player, sgs.Player_PlaceTable)
					local tps = sgs.SPlayerList()
					tps:append(player)
					dc:use(room, player, tps)
					room:damage(sgs.DamageStruct("sxxianlu", player, p))
				end
			end
		end
	end,
}
sxxianlu = sgs.CreateViewAsSkillV2 {
	name = "sxxianlu",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:usedTimes("#sxxianluCard") < 1
	end,
	create_card = function(skill, request)
		return sxxianluCard:clone()
	end,
}
sx_nanhua:addSkill(sxxianlu)
sxtianshu = sgs.CreateMaxCardsSkillV2 {
	name = "sxtianshu",
	correct_func = function(skill, ctx)
		local target = ctx:getHolder()
		if not (target and target:hasSkill(skill:objectName())) then
			return false
		end
		local ks = { target:getKingdom() }
		for _, p in sgs.qlist(target:getAliveSiblings()) do
			if table.contains(ks, p:getKingdom()) then
				continue
			end
			table.insert(ks, p:getKingdom())
		end
		return #ks - 1
	end,
}
sx_nanhua:addSkill(sxtianshu)

sx_zerong = sgs.General(sxfy_qinglong, "sx_zerong", "qun", 4)
sxcansi = sgs.CreateTriggerSkillV2 {
	name = "sxcansi",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start and player:getCardCount() > 0 then
			for _, p in sgs.list(room:getAlivePlayers()) do
				if player:inMyAttackRange(p) then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local tps = sgs.SPlayerList()
		for _, p in sgs.list(room:getAlivePlayers()) do
			if player:inMyAttackRange(p) then
				tps:append(p)
			end
		end
		if tps:length() < 1 then
			return false
		end
		room:sendCompulsoryTriggerLog(player, skill)
		local tp = room:askForPlayerChosen(player, tps, skill:objectName(), "sxcansi0")
		room:doAnimate(1, player:objectName(), tp:objectName())
		local id = room:askForCardChosen(tp, player, "he", skill:objectName())
		room:obtainCard(tp, id, false)
		local dc = dummyCard(nil, "_sxcansi")
		if player:isAlive() and tp:isAlive() and player:canSlash(tp, dc, false) then
			room:useCard(sgs.CardUseStruct(dc, player, tp))
		end
		dc = dummyCard("duel", "_sxcansi")
		if player:isAlive() and tp:isAlive() and player:canUse(dc, tp) then
			room:useCard(sgs.CardUseStruct(dc, player, tp))
		end
		return false
	end,
}
sx_zerong:addSkill(sxcansi)

sx_pangdegong = sgs.General(sxfy_qinglong, "sx_pangdegong", "qun", 3)
sxlingjian = sgs.CreateTriggerSkillV2 {
	name = "sxlingjian",
	events = { sgs.CardFinished },
	frequency = sgs.Skill_Compulsory,
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player:isAlive() and event == sgs.CardFinished) then return end
		local use = ctx.original_data:toCardUse()
		if use.card:isKindOf("Slash") then
			player:addMark("sxlingjianUse-Clear")
			if use.card:hasFlag("DamageDone") then
				return
			end
			if player:getMark("sxlingjianUse-Clear") == 1 and player:hasSkill(skill:objectName()) then
				room:sendCompulsoryTriggerLog(player, skill)
				if player:hasSkill("sxmingshi", true) and player:getMark("@sxmingshi") < 1 then
					room:addPlayerMark(player, "@sxmingshi")
				end
			end
		end
	end,
}
sx_pangdegong:addSkill(sxlingjian)
sxmingshiCard = sgs.CreateSkillCard {
	name = "sxmingshiCard",
	target_fixed = true,
	mute = true,
	on_use = function(self, room, player, targets)
		room:removePlayerMark(player, "@sxmingshi")
		local choices = { "sxmingshi1" }
		if player:isWounded() then
			table.insert(choices, "sxmingshi2")
		end
		table.insert(choices, "sxmingshi3")
		room:doSuperLightbox(player, "sxmingshi")
		for _, p in sgs.list(room:getAlivePlayers()) do
			for _, c in sgs.list(p:getCards("ej")) do
				for _, q in sgs.list(room:getAlivePlayers()) do
					if player:isProhibited(q, c) then
						continue
					end
					if c:isKindOf("EquipCard") then
						local n = c:getRealCard():toEquipCard():location()
						if q:getEquip(n) then
							continue
						end
					end
					table.insert(choices, "sxmingshi4")
					break
				end
				if table.contains(choices, "sxmingshi4") then
					break
				end
			end
			if table.contains(choices, "sxmingshi4") then
				break
			end
		end
		local choice = room:askForChoice(player, "sxmingshi", table.concat(choices, "+"))
		if choice == "sxmingshi1" then
			player:drawCards(2, "sxmingshi")
		end
		if choice == "sxmingshi2" then
			room:recover(player, sgs.RecoverStruct("sxmingshi", player))
		end
		if choice == "sxmingshi3" then
			local tp = room:askForPlayerChosen(player, room:getAlivePlayers(), "sxmingshi3", "sxmingshi3")
			room:damage(sgs.DamageStruct("sxmingshi", player, tp))
		end
		if choice == "sxmingshi4" then
			room:moveField(player, "sxmingshi", false, "ej")
		end
	end,
}
sxmingshi = sgs.CreateViewAsSkillV2 {
	name = "sxmingshi",
	limit_mark = "@sxmingshi",
	frequency = sgs.Skill_Limited,
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:getMark("@sxmingshi") > 0
	end,
	create_card = function(skill, request)
		return sxmingshiCard:clone()
	end,
}
sx_pangdegong:addSkill(sxmingshi)

sx_yangbiao = sgs.General(sxfy_qinglong, "sx_yangbiao", "qun", 3)
sxyizheng = sgs.CreateTriggerSkillV2 {
	name = "sxyizheng",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			for _, p in sgs.list(room:getAlivePlayers()) do
				if player:getHp() <= p:getHp() and player:canPindian(p) then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local tps = sgs.SPlayerList()
		for _, p in sgs.list(room:getAlivePlayers()) do
			if player:getHp() <= p:getHp() and player:canPindian(p) then
				tps:append(p)
			end
		end
		local tp = room:askForPlayerChosen(player, tps, skill:objectName(), "sxyizheng0", true, true)
		if tp then
			ctx.targets:append(tp)
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local tp = ctx.targets:first()
		player:peiyin("yizheng")
		local n = player:pindianInt(tp, skill:objectName())
		if n > 0 then
			room:damage(sgs.DamageStruct(skill:objectName(), player, tp))
		elseif n < 0 then
			room:damage(sgs.DamageStruct(skill:objectName(), tp, player))
		end
		return false
	end,
}
sx_yangbiao:addSkill(sxyizheng)
sxrangjie = sgs.CreateTriggerSkillV2 {
	name = "sxrangjie",
	events = { sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Damaged then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local tps = sgs.SPlayerList()
		for _, p in sgs.list(room:getAlivePlayers()) do
			for _, c in sgs.list(p:getCards("ej")) do
				for _, q in sgs.list(room:getAlivePlayers()) do
					if player:isProhibited(q, c) then
						continue
					end
					if c:isKindOf("EquipCard") then
						local n = c:getRealCard():toEquipCard():location()
						if q:getEquip(n) then
							continue
						end
					end
					tps:append(p)
					break
				end
			end
		end
		local tp = room:askForPlayerChosen(player, tps, skill:objectName(), "sxrangjie0", true, true)
		if tp then
			ctx.targets:append(tp)
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local tp = ctx.targets:first()
		player:peiyin("rangjie")
		local ids = sgs.IntList()
		for _, c in sgs.list(tp:getCards("ej")) do
			local has = true
			for _, q in sgs.list(room:getAlivePlayers()) do
				if player:isProhibited(q, c) then
					continue
				end
				if c:isKindOf("EquipCard") then
					local n = c:getRealCard():toEquipCard():location()
					if q:getEquip(n) then
						continue
					end
				end
				has = false
			end
			if has then
				ids:append(c:getId())
			end
		end
		local id = room:askForCardChosen(player, tp, "ej", "sxrangjie", false, sgs.Card_MethodNone, ids)
		local c = sgs.Sanguosha:getCard(id)
		local tps = sgs.SPlayerList()
		for _, q in sgs.list(room:getAlivePlayers()) do
			if player:isProhibited(q, c) then
				continue
			end
			if c:isKindOf("EquipCard") then
				local n = c:getRealCard():toEquipCard():location()
				if q:getEquip(n) then
					continue
				end
			end
			tps:append(q)
		end
		local tq = room:askForPlayerChosen(player, tps, "sxrangjie1", "sxrangjie1:" .. c:objectName())
		room:doAnimate(1, player:objectName(), tq:objectName())
		room:moveCardTo(c, tq, room:getCardPlace(id), true)
		return false
	end,
}
sx_yangbiao:addSkill(sxrangjie)

sx_peixiu = sgs.General(sxfy_qinglong, "sx_peixiu", "qun", 3)
sxzhitu = sgs.CreateViewAsSkillV2 {
	name = "sxzhitu",
	guhuo_type = "r",
	n = 999,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not (player and player:getCardCount() > 1) then return false end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return true end
		local pattern = request:getPattern()
		if string.find(pattern, "@@") then
			return false
		end
		local dc = dummyCard(pattern)
		return dc and dc:isNDTrick()
	end,
	can_select_card = function(skill, request, candidate)
		local ids = request:getSelectedCardIds()
		if ids:length() < 1 then return true end
		local n = 0
		for _, id in sgs.qlist(ids) do
			n = n + sgs.Sanguosha:getCard(id):getNumber()
		end
		return n + candidate:getNumber() <= 13
	end,
	card_selection_feasible = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() < 2 then return false end
		local n = 0
		for _, id in sgs.qlist(ids) do
			n = n + sgs.Sanguosha:getCard(id):getNumber()
		end
		return n == 13
	end,
	create_card = function(skill, request)
		local pattern = request:getPattern()
		if pattern == "" then
			pattern = request:getUserString()
		end
		if pattern == "" then return nil end
		local sc = sgs.Sanguosha:cloneCard(pattern)
		sc:setSkillName(skill:objectName())
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(id)
		end
		return sc
	end,
}
sx_peixiu:addSkill(sxzhitu)

sx_baoxin = sgs.General(sxfy_qinglong, "sx_baoxin", "qun", 3)
sxyimou = sgs.CreateTriggerSkillV2 {
	name = "sxyimou",
	events = { sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Damaged and player:getCardCount() > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local ids = player:handCards()
		for _, id in sgs.list(player:getEquipsId()) do
			ids:append(id)
		end
		room:askForYiji(player, ids, skill:objectName(), false, false, true, 1, room:getOtherPlayers(player), CardMoveReason(), "sxyimou0", true)
		return false
	end,
}
sx_baoxin:addSkill(sxyimou)
sxmutao = sgs.CreateTriggerSkillV2 {
	name = "sxmutao",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			for _, p in sgs.list(room:getOtherPlayers(player)) do
				if p:getHandcardNum() > 0 then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local tps = sgs.SPlayerList()
		for _, p in sgs.list(room:getOtherPlayers(player)) do
			if p:getHandcardNum() > 0 then
				tps:append(p)
			end
		end
		local tp = room:askForPlayerChosen(player, tps, skill:objectName(), "sxmutao0", true, true)
		if tp then
			ctx.targets:append(tp)
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local tp = ctx.targets:first()
		player:peiyin("mutao")
		room:showCard(tp, tp:handCards())
		for _, h in sgs.list(tp:getHandcards()) do
			if h:isKindOf("Slash") then
				room:damage(sgs.DamageStruct(skill:objectName(), player, tp))
				break
			end
		end
		return false
	end,
}
sx_baoxin:addSkill(sxmutao)

sx_huangfusong = sgs.General(sxfy_qinglong, "sx_huangfusong", "qun", 4)
sxtaoluan = sgs.CreateTriggerSkillV2 {
	name = "sxtaoluan",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player and player:isAlive() and player:getPhase() == sgs.Player_Finish then
			local names, owners = {}, {}
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:hasSkill(skill:objectName()) and p:getCardCount() > 0 then
					table.insert(names, skill:objectName())
					table.insert(owners, p:objectName())
				end
			end
			if #owners > 0 then
				return table.concat(names, "|"), table.concat(owners, "|")
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local dc = room:askForCard(player, "..", "sxtaoluan0:" .. ctx.invoker:objectName(), ctx.original_data, sgs.Card_MethodNone)
		if dc then
			local ids = {}
			for _, id in sgs.qlist(dc:getSubcards()) do
				table.insert(ids, tostring(id))
			end
			ctx.extra_data:setValue(table.concat(ids, "+"))
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:skillInvoked(skill)
		local dc0 = dummyCard()
		for _, s in sgs.list(ctx.extra_data:toString():split("+")) do
			dc0:addSubcard(tonumber(s))
		end
		room:giveCard(player, ctx.invoker, dc0, skill:objectName())
		room:showCard(ctx.invoker, ctx.invoker:handCards())
		local dc = dummyCard()
		for _, h in sgs.list(ctx.invoker:getHandcards()) do
			if h:isKindOf("Jink") and ctx.invoker:canDiscard(ctx.invoker, h:getId()) then
				dc:addSubcard(h)
			end
		end
		room:throwCard(dc, skill:objectName(), ctx.invoker)
		return false
	end,
}
sx_huangfusong:addSkill(sxtaoluan)

sgs.LoadTranslationTable {

	["sxfy_qinglong"] = "四象封印·青龙",

	["sx_huangfusong"] = "皇甫嵩[青]",
	["#sx_huangfusong"] = "定巾平乱",
	["illustrator:sx_huangfusong"] = "鬼画府",

	["sxtaoluan"] = "讨乱",
	[":sxtaoluan"] = "其他角色的结束阶段，你可以将一张牌交给其并展示其手牌，弃置其手牌中的【闪】。",
	["sxtaoluan0"] = "你可以发动“讨乱”将一张牌交给%src",

	["sx_baoxin"] = "鲍信[青]",
	["#sx_baoxin"] = "坚檏的忠相",
	["illustrator:sx_baoxin"] = "凡果",

	["sxyimou"] = "毅谋",
	[":sxyimou"] = "当你受到伤害后，你可以将一张牌交给一名其他角色。",
	["sxmutao"] = "募讨",
	[":sxmutao"] = "准备阶段，你可以令一名其他角色展示其手牌，若其中有【杀】，你对其造成1点伤害。",
	["sxyimou0"] = "你可以发动“毅谋”将一张牌交给其他角色",
	["sxmutao0"] = "你可以发动“募讨”展示一名角色手牌",

	["sx_peixiu"] = "裴秀[青]",
	["#sx_peixiu"] = "晋图开秘",
	["illustrator:sx_peixiu"] = "鬼画府",

	["sxzhitu"] = "制图",
	[":sxzhitu"] = "你可以将至少两张点数之和等于13的牌当任意一种普通锦囊牌使用。",

	["sx_yangbiao"] = "杨彪[青]",
	["#sx_yangbiao"] = "东归护主",
	["illustrator:sx_yangbiao"] = "木美人",

	["sxyizheng"] = "义争",
	[":sxyizheng"] = "准备阶段，你可以与一名体力大于等于你的角色拼点：赢的角色对没赢的角色造成1点伤害。",
	["sxrangjie"] = "让节",
	[":sxrangjie"] = "当你受到伤害后，你可以移动场上一张牌。",
	["sxyizheng0"] = "义争：你可以与一名角色拼点",
	["sxrangjie0"] = "你可以发动“让节”选择移动一名角色场上一张牌",
	["sxrangjie1"] = "让节：请选择【%src】移动目标",

	["sx_pangdegong"] = "庞德公[青]",
	["#sx_pangdegong"] = "以德服人",
	["illustrator:sx_pangdegong"] = "小罗没想好",

	["sxlingjian"] = "令荐",
	[":sxlingjian"] = "锁定技，当你每回合首次使用【杀】后，若此牌未造成伤害，“明识”视为未发动。",
	["sxmingshi"] = "明识",
	[":sxmingshi"] = "限定技，出牌阶段，你可以选择一项：1.摸两张牌；2.回复1点体力；3.对一名角色造成1点伤害；4.移动场上一张牌。",
	["sxmingshi1"] = "摸两张牌",
	["sxmingshi2"] = "回复1点体力",
	["sxmingshi3"] = "对一名角色造成1点伤害",
	["sxmingshi4"] = "移动场上一张牌",

	["sx_zerong"] = "笮融[青]",
	["#sx_zerong"] = "沉寂的浮屠",
	["illustrator:sx_zerong"] = "小罗没想好",

	["sxcansi"] = "残肆",
	[":sxcansi"] = "锁定技，准备阶段，你令攻击范围内一名角色获得你一张牌，然后你依次对其使用【杀】和【决斗】。",
	["sxcansi0"] = "残肆：请选择令一名角色获得你一张牌",

	["sx_nanhua"] = "南华小仙[青]",
	["#sx_nanhua"] = "祓炁除煞",
	["illustrator:sx_nanhua"] = "小罗没想好",

	["sxxianlu"] = "仙箓",
	[":sxxianlu"] = "出牌阶段限一次，你可以弃置一名角色装备区一张牌，若此牌为红色，你将此牌当做【乐不思蜀】置入你的判定区并对其造成1点伤害。",
	["sxtianshu"] = "天书",
	[":sxtianshu"] = "锁定技，你的手牌上限+X（X为场上势力数-1）。",
}

sxfy_baihu = sgs.Package("sxfy_baihu", sgs.Package_GeneralPack)

sx_majun = sgs.General(sxfy_baihu, "sx_majun", "wei", 3)
sxgongqiaoCard = sgs.CreateSkillCard {
	name = "sxgongqiaoCard",
	target_fixed = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		return #targets < 1
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("gongqiao")
		for i, p in sgs.list(targets) do
			local ids = sgs.IntList()
			local c = nil
			while p:isAlive() do
				room:getThread():delay()
				c = sgs.Sanguosha:getCard(room:getNCards(1):last())
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), p:objectName(), self:getSkillName(), "")
				room:moveCardsAtomic(sgs.CardsMoveStruct(c:getId(), nil, sgs.Player_PlaceTable, reason), true)
				if c:isKindOf("EquipCard") then
					break
				end
				ids:append(c:getId())
			end
			if c then
				if c:isKindOf("EquipCard") and c:isAvailable(p) then
					room:useCard(sgs.CardUseStruct(c, p))
				end
			end
			if p:isAlive() then
				local moves = sgs.CardsMoveList()
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_OVERRIDE, p:objectName(), self:getSkillName(), "")
				moves:append(sgs.CardsMoveStruct(p:handCards(), nil, sgs.Player_DrawPile, reason))
				moves:append(sgs.CardsMoveStruct(ids, p, sgs.Player_PlaceHand, reason))
				room:moveCardsAtomic(moves, false)
				ids:clear()
			end
			if c and room:getCardPlace(c:getId()) == sgs.Player_PlaceTable then
				ids:append(c:getId())
			end
			room:throwCard(ids, self:getSkillName(), nil)
		end
	end,
}
sxgongqiao = sgs.CreateViewAsSkillV2 {
	name = "sxgongqiao",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:usedTimes("#sxgongqiaoCard") < 1
	end,
	create_card = function(skill, request)
		return sxgongqiaoCard:clone()
	end,
}
sx_majun:addSkill(sxgongqiao)

sx_zhangfen = sgs.General(sxfy_baihu, "sx_zhangfen", "wu", 4)
sxwangluCard = sgs.CreateSkillCard {
	name = "sxwangluCard",
	target_fixed = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		return #targets < 1 and source:canDiscard(to_select, "e")
	end,
	on_use = function(self, room, player, targets)
		for i, p in sgs.list(targets) do
			local id = room:askForCardChosen(player, p, "e", self:getSkillName(), false, sgs.Card_MethodDiscard)
			if id >= 0 then
				room:throwCard(id, self:getSkillName(), p, player)
				local c = sgs.Sanguosha:getCard(id)
				if c:isKindOf("Weapon") then
					c = c:getRealCard():toWeapon()
					p:drawCards(c:getRange(), self:getSkillName())
				end
			end
		end
	end,
}
sxwanglu = sgs.CreateViewAsSkillV2 {
	name = "sxwanglu",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:usedTimes("#sxwangluCard") < 1
	end,
	create_card = function(skill, request)
		return sxwangluCard:clone()
	end,
}
sx_zhangfen:addSkill(sxwanglu)

sx_zhaoyan = sgs.General(sxfy_baihu, "sx_zhaoyan", "wu", 3, false)
sxjinhuiVS = sgs.CreateViewAsSkillV2 {
	name = "sxjinhui",
	n = 1,
	expand_pile = "#sxjinhui",
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return string.find(request:getPattern(), "@@sxjinhui") ~= nil
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		return player and player:getPile("#sxjinhui"):contains(candidate:getId())
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		return sgs.Sanguosha:getCard(request:getSelectedCardIds():first())
	end,
}
sxjinhui = sgs.CreateTriggerSkillV2 {
	name = "sxjinhui",
	view_as_skill = sxjinhuiVS,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("jinhui")
		local ids = room:showDrawPile(player, 3, skill:objectName())
		local tps = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			for _, id in sgs.qlist(ids) do
				if sgs.Sanguosha:getCard(id):isAvailable(p) then
					tps:append(p)
					break
				end
			end
		end
		local tp = room:askForPlayerChosen(player, tps, skill:objectName(), "sxjinhui0")
		if tp then
			room:notifyMoveToPile(tp, ids, "sxjinhui")
			local c = room:askForUseCard(tp, "@@sxjinhui!", "sxjinhui1")
			if c and player:isAlive() then
				local ids2 = sgs.IntList()
				ids:removeOne(c:getEffectiveId())
				for _, id in sgs.qlist(ids) do
					local bc = sgs.Sanguosha:getCard(id)
					if bc:getColor() ~= c:getColor() and bc:isAvailable(player) then
						ids2:append(id)
					end
				end
				if ids2:length() > 0 then
					room:notifyMoveToPile(player, ids2, "sxjinhui")
					c = room:askForUseCard(player, "@@sxjinhui!", "sxjinhui1")
					if c then
						ids:removeOne(c:getEffectiveId())
					end
				end
			end
		end
		room:throwCard(ids, skill:objectName(), nil)
		return false
	end,
}
sx_zhaoyan:addSkill(sxjinhui)
sxqingman = sgs.CreateTriggerSkillV2 {
	name = "sxqingman",
	events = { sgs.EventPhaseChanging },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local n = math.min(3, 5 - player:getEquips():length())
				n = n - player:getHandcardNum()
				if n ~= 0 then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local n = math.min(3, 5 - player:getEquips():length())
		n = n - player:getHandcardNum()
		player:peiyin("qingman")
		room:sendCompulsoryTriggerLog(player, skill:objectName())
		if n > 0 then
			player:drawCards(n, skill:objectName())
		else
			room:askForDiscard(player, skill:objectName(), -n, -n)
		end
		return false
	end,
}
sx_zhaoyan:addSkill(sxqingman)

sx_zhengxuan = sgs.General(sxfy_baihu, "sx_zhengxuan", "qun", 3)
sxzhengjingCard = sgs.CreateSkillCard {
	name = "sxzhengjingCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		return #targets < 1 and to_select ~= source
	end,
	on_use = function(self, room, player, targets)
		local ids = player:property("sxzhengjingIds"):toString():split("+")
		for i, p in sgs.list(targets) do
			local dc = dummyCard()
			local dc2 = dummyCard()
			for _, id in sgs.list(ids) do
				if sgs.Sanguosha:getCard(id):getSuit() == self:getSuit() then
					dc:addSubcard(id)
				else
					dc2:addSubcard(id)
				end
			end
			p:obtainCard(dc)
			if player:isAlive() then
				player:obtainCard(dc2)
			end
		end
	end,
}
sxzhengjingvs = sgs.CreateViewAsSkillV2 {
	name = "sxzhengjing",
	n = 1,
	expand_pile = "#sxzhengjing",
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@sxzhengjing!"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		return player
			and table.contains(player:property("sxzhengjingIds"):toString():split("+"), tostring(candidate:getId()))
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local sc = sxzhengjingCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(id)
		end
		return sc
	end,
}
sxzhengjing = sgs.CreateTriggerSkillV2 {
	name = "sxzhengjing",
	view_as_skill = sxzhengjingvs,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Draw then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local dc = room:askForExchange(player, skill:objectName(), 3, 1, false, "sxzhengjing0", true)
		if dc then
			local ids = {}
			for _, id in sgs.qlist(dc:getSubcards()) do
				table.insert(ids, tostring(id))
			end
			ctx.extra_data:setValue(table.concat(ids, "+"))
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:skillInvoked(skill)
		local dc = dummyCard()
		for _, s in sgs.list(ctx.extra_data:toString():split("+")) do
			dc:addSubcard(tonumber(s))
		end
		room:showCard(player, dc:getSubcards())
		local ids = room:showDrawPile(player, dc:subcardsLength(), skill:objectName(), false)
		room:notifyMoveToPile(player, ids, "sxzhengjing")
		local stc = {}
		for i, id in sgs.qlist(ids) do
			table.insert(stc, id)
		end
		for i, id in sgs.qlist(dc:getSubcards()) do
			table.insert(stc, id)
		end
		room:setPlayerProperty(player, "sxzhengjingIds", ToData(table.concat(stc, "+")))
		room:askForUseCard(player, "@@sxzhengjing!", "sxzhengjing1")
		return false
	end,
}
sx_zhengxuan:addSkill(sxzhengjing)

sx_simahui = sgs.General(sxfy_baihu, "sx_simahui", "qun", 3)
sxjianjievs = sgs.CreateViewAsSkillV2 {
	name = "sxjianjie",
	n = 1,
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@sxjianjie"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		return player and player:getMark("sxjianjieId") == candidate:getId()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local card = sgs.Sanguosha:getCard(request:getSelectedCardIds():first())
		if card:isRed() then
			local dc = sgs.Sanguosha:cloneCard("fire_attack")
			dc:setSkillName("_sxjianjie")
			dc:addSubcard(request:getSelectedCardIds():first())
			return dc
		elseif card:isBlack() then
			local dc = sgs.Sanguosha:cloneCard("iron_chain")
			dc:setSkillName("_sxjianjie")
			dc:addSubcard(request:getSelectedCardIds():first())
			return dc
		end
		return nil
	end,
}
sxjianjie = sgs.CreateTriggerSkillV2 {
	name = "sxjianjie",
	view_as_skill = sxjianjievs,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local tps = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getCardCount() > 0 then
				tps:append(p)
			end
		end
		tps = room:askForPlayersChosen(player, tps, skill:objectName(), 0, 3, "sxjianjie0", true, true)
		if tps:length() > 0 then
			for _, p in sgs.qlist(tps) do
				ctx.targets:append(p)
			end
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("jianjie")
		for _, p in sgs.qlist(ctx.targets) do
			local id = room:askForCardChosen(player, p, "he", skill:objectName())
			room:setPlayerMark(p, "sxjianjieId", id)
			room:showCard(p, id)
		end
		for _, p in sgs.qlist(ctx.targets) do
			if p:isAlive() then
				room:askForUseCard(p, "@@sxjianjie", "sxjianjie1")
			end
		end
		return false
	end,
}
sx_simahui:addSkill(sxjianjie)
sxchenghao = sgs.CreateTriggerSkillV2 {
	name = "sxchenghao",
	events = { sgs.DamageInflicted },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.DamageInflicted and player and player:isAlive() then
			local damage = data:toDamage()
			if damage.nature ~= sgs.DamageStruct_Normal then
				local names, owners = {}, {}
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasSkill(skill:objectName()) and p:getMark("sxchenghaoUse-Clear") < 1 and p:hasTurn() then
						table.insert(names, skill:objectName())
						table.insert(owners, p:objectName())
					end
				end
				if #owners > 0 then
					return table.concat(names, "|"), table.concat(owners, "|")
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:addMark("sxchenghaoUse-Clear")
		player:peiyin("chenghao")
		local ids = room:getNCards(1)
		room:fillAG(ids, player)
		local tp = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "sxchenghao0")
		if tp then
			room:obtainCard(tp, ids:last(), false)
		end
		room:clearAG(player)
		return false
	end,
}
sx_simahui:addSkill(sxchenghao)

sx_miheng = sgs.General(sxfy_baihu, "sx_miheng", "qun", 3)
sxkuangcai = sgs.CreateTriggerSkillV2 {
	name = "sxkuangcai",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.PreCardUsed, sgs.CardFinished },
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player:isAlive() and player:getPhase() == sgs.Player_Play
			and kesxV2RecordOnce(room, skill, ctx)) then return end
		if event == sgs.PreCardUsed then
			local use = ctx.original_data:toCardUse()
			if use.card:getTypeId() > 0 and player:getMark("sxkuangcaiUse-PlayClear") < 2 then
				room:addPlayerMark(player, "sxkuangcaiUse-PlayClear")
				room:setCardFlag(use.card, "sxkuangcaiUse")
			end
		else
			local use = ctx.original_data:toCardUse()
			if use.card:hasFlag("sxkuangcaiUse") and player:hasSkill(skill:objectName()) then
				player:peiyin("kuangcai")
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				if use.card:hasFlag("DamageDone") then
					player:drawCards(1, skill:objectName())
				else
					room:askForDiscard(player, skill:objectName(), 1, 1, false, true)
				end
			end
		end
	end,
}
sx_miheng:addSkill(sxkuangcai)
sxshejian = sgs.CreateTriggerSkillV2 {
	name = "sxshejian",
	events = { sgs.EventPhaseChanging, sgs.TargetConfirmed },
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player) then return end
		if event == sgs.EventPhaseChanging then
			if ctx.original_data:toPhaseChange().to == sgs.Player_NotActive and kesxV2RecordOnce(room, skill, ctx) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					for _, q in sgs.qlist(room:getAlivePlayers()) do
						if q:getMark("&sxshejian+#" .. p:objectName() .. "-Clear") > 0 then
							room:damage(sgs.DamageStruct(skill:objectName(), p, q))
						end
					end
				end
			end
		else
			player:setTag("sxshejianData", ctx.original_data)
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.TargetConfirmed or not player then
			return false
		end
		local use = data:toCardUse()
		if
			use.card:getTypeId() > 0
			and use.from
			and use.from ~= player
			and use.to:contains(player)
			and player:getHandcardNum() > 1
			and player:canDiscard("h")
		then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		return room:askForDiscard(player, skill:objectName(), 2, 2, true, false, "sxshejian0:" .. use.from:objectName(), ".", skill:objectName())
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("shejian")
		room:setPlayerMark(ctx.original_data:toCardUse().from, "&sxshejian+#" .. player:objectName() .. "-Clear", 1)
		return false
	end,
}
sx_miheng:addSkill(sxshejian)

sx_liuli = sgs.General(sxfy_baihu, "sx_liuli", "shu", 3)
sxfuliCard = sgs.CreateSkillCard {
	name = "sxfuliCard",
	target_fixed = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		return #targets < 1 and to_select ~= source
	end,
	on_use = function(self, room, player, targets)
		--player:peiyin("fuli")
		room:showAllCards(player)
		local dc = dummyCard()
		for i, h in sgs.list(player:getHandcards()) do
			if h:isDamageCard() and player:canDiscard(player, h:getId()) then
				dc:addSubcard(h)
			end
		end
		room:throwCard(dc, "sxfuli", player)
		for i, p in sgs.list(targets) do
			room:showAllCards(p)
			dc = dummyCard()
			for i, h in sgs.list(p:getHandcards()) do
				if h:isDamageCard() and p:canDiscard(p, h:getId()) then
					dc:addSubcard(h)
				end
			end
			room:throwCard(dc, "sxfuli", p)
			if p:isAlive() then
				room:recover(p, sgs.RecoverStruct("sxfuli", player))
			end
		end
	end,
}
sxfuli = sgs.CreateViewAsSkillV2 {
	name = "sxfuli",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		return player and player:usedTimes("#sxfuliCard") < 1
	end,
	create_card = function(skill, request)
		return sxfuliCard:clone()
	end,
}
sx_liuli:addSkill(sxfuli)
sxdehuavs = sgs.CreateViewAsSkillV2 {
	name = "sxdehua",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@sxdehua"
	end,
	create_card = function(skill, request)
		local dc = sgs.Sanguosha:cloneCard(request:getInitiator():property("sxdehuaCn"):toString())
		dc:setSkillName("sxdehua")
		return dc
	end,
}
sxdehua = sgs.CreateTriggerSkillV2 {
	name = "sxdehua",
	view_as_skill = sxdehuavs,
	events = { sgs.EventPhaseChanging, sgs.CardsMoveOneTime },
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player:isAlive() and event == sgs.CardsMoveOneTime
			and kesxV2RecordOnce(room, skill, ctx)) then return end
		local move = ctx.original_data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
			if (move.from ~= move.to or move.to_place ~= sgs.Player_PlaceHand and move.to_place ~= sgs.Player_PlaceEquip) and move.from:objectName() == player:objectName() then
				for i, id in sgs.qlist(move.card_ids) do
					if move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip then
						player:addMark("sxdehuaNum-Clear")
					end
				end
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseChanging and player and player:isAlive() then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local names, owners = {}, {}
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("sxdehuaNum-Clear") == 2 and p:hasSkill(skill:objectName()) then
						local ids = room:getAvailableCardList(p, "basic", skill:objectName())
						if ids:length() > 0 then
							table.insert(names, skill:objectName())
							table.insert(owners, p:objectName())
						end
					end
				end
				if #owners > 0 then
					return table.concat(names, "|"), table.concat(owners, "|")
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local ids = room:getAvailableCardList(player, "basic", skill:objectName())
		if ids:length() < 1 then return false end
		room:fillAG(ids, player)
		local id = room:askForAG(player, ids, true, skill:objectName(), "sxdehua0")
		room:clearAG(player)
		if id < 0 then
			return false
		end
		ctx.extra_data:setValue(id)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local c = sgs.Sanguosha:getEngineCard(ctx.extra_data:toInt())
		room:setPlayerProperty(player, "sxdehuaCn", ToData(c:objectName()))
		room:askForUseCard(player, "@@sxdehua", "sxdehua1:" .. c:objectName())
		return false
	end,
}
sx_liuli:addSkill(sxdehua)

sgs.LoadTranslationTable {

	["sxfy_baihu"] = "四象封印·白虎",

	["sx_liuli"] = "刘理[白]",
	["#sx_liuli"] = "安平王",
	["illustrator:sx_liuli"] = "黯荧岛工作室",

	["sxfuli"] = "抚黎",
	[":sxfuli"] = "出牌阶段限一次，你可以展示所有手牌并弃置其中所有伤害牌（无则不弃），然后你选择一名其他角色，其也如此做且回复1点体力。",
	["sxdehua"] = "德化",
	[":sxdehua"] = "你失去仅两张牌的回合结束时，你可以视为使用任意一种基本牌。",
	["sxdehua0"] = "你可以发动“德化”选择其中一张牌视为使用",
	["sxdehua1"] = "德化：你可以视为使用【%src】",

	["sx_miheng"] = "祢衡[白]",
	["#sx_miheng"] = "狂傲奇人",
	["illustrator:sx_miheng"] = "MUMU",

	["sxkuangcai"] = "狂才",
	[":sxkuangcai"] = "锁定技，出牌阶段，你使用的前两张牌无距离和次数限制，结算后若此牌造成了伤害，你摸一张牌，否则弃置一张牌。",
	["sxshejian"] = "舌剑",
	[":sxshejian"] = "当你成为其他角色使用牌的唯一目标后，你可以弃置两张牌，若如此做，此回合结束时你对其造成1点伤害。",
	["sxshejian0"] = "你可以发动“舌剑”弃置两张手牌，目标为%src",

	["sx_simahui"] = "司马徽[白]",
	["#sx_simahui"] = "水镜先生",
	["illustrator:sx_simahui"] = "黑桃J",

	["sxjianjie"] = "荐杰",
	[":sxjianjie"] = "准备阶段，你可以至多3名角色各一张牌并展示之，这些角色依次将请展示的红色/黑色牌当做【火攻】/【铁索连环】使用。",
	["sxchenghao"] = "称好",
	[":sxchenghao"] = "每回合限一次，有角色受到属性伤害时，你可以观看牌堆顶一张牌并将之交给一名角色。",
	["sxjianjie0"] = "你可以发动“荐杰”选择至多3名角色",
	["sxjianjie1"] = "荐杰：请将红色/黑色牌当做【火攻】/【铁索连环】使用",
	["sxchenghao0"] = "称好：请选择角色获得这张牌",

	["sx_zhengxuan"] = "郑玄[白]",
	["#sx_zhengxuan"] = "兼采定道",
	["illustrator:sx_zhengxuan"] = "Monkey",

	["sxzhengjing"] = "整经",
	[":sxzhengjing"] = "摸牌阶段开始时，你可以展示手牌和牌堆顶等量的牌（至多3张），你将其中一种花色的牌交给一名其他角色，然后获得其余的牌。",
	["sxzhengjing0"] = "你可以发动“整经”展示至多3张手牌",
	["sxzhengjing1"] = "整经：请选择一种花色的一张牌交给其他角色",
	["#sxzhengjing"] = "牌堆",

	["sx_zhaoyan"] = "赵嫣[白]",
	["#sx_zhaoyan"] = "霞蔚青歇",
	["illustrator:sx_zhaoyan"] = "塞拉斯",

	["sxjinhui"] = "锦绘",
	[":sxjinhui"] = "准备阶段，你可以亮出牌堆顶三张牌，令一名角色使用其中一张牌，你使用其中颜色不同的另一张牌。",
	["sxqingman"] = "轻幔",
	[":sxqingman"] = "锁定技，回合结束时，你将手牌调整至X张（X为你空置装备栏数，至多为3）。",
	["sxjinhui0"] = "锦绘：请使用其中一张牌",
	["#sxjinhui"] = "锦绘",

	["sx_zhangfen"] = "张奋[白]",
	["#sx_zhangfen"] = "御驰大攻",
	["illustrator:sx_zhangfen"] = "塞拉斯",

	["sxwanglu"] = "望橹",
	[":sxwanglu"] = "出牌阶段限一次，你可以弃置场上一张装备牌，若为武器牌，装备的角色摸X张牌（X为此武器的攻击范围）。",

	["sx_majun"] = "马钧[白]",
	["#sx_majun"] = "名巧天下",
	["illustrator:sx_majun"] = "塞拉斯",

	["sxgongqiao"] = "工巧",
	[":sxgongqiao"] = "出牌阶段限一次，你可以选择一名角色，连续亮出牌堆顶牌直到亮出装备牌，其使用之并用所有手牌交换其余亮出的牌。",
}

sxfy_zhuque = sgs.Package("sxfy_zhuque", sgs.Package_GeneralPack)

sx_qinghe = sgs.General(sxfy_zhuque, "sx_qinghe", "wei", 3, false)
sxzengouCard = sgs.CreateSkillCard {
	name = "sxzengouCard",
	target_fixed = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		return #targets < 1 and to_select ~= source
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("zengou")
		for _, p in sgs.list(targets) do
			local ids = p:handCards()
			if ids:length() < 1 then
				continue
			end
			local hids = sgs.IntList()
			for i = 1, 2 do
				local id = room:doGongxin(player, p, ids, self:objectName())
				if id < 0 then
					break
				end
				ids:removeOne(id)
				hids:append(id)
				if ids:length() < 1 then
					break
				end
			end
			room:showCard(p, hids)
			ids = room:getAvailableCardList(player, "basic", "sxzengou")
			for _, hid in sgs.list(hids) do
				local cn = sgs.Sanguosha:getCard(hid):objectName()
				for _, id in sgs.list(ids) do
					if cn == sgs.Sanguosha:getEngineCard(id):objectName() then
						ids:removeOne(id)
						break
					end
				end
			end
			if ids:length() > 0 and player:isAlive() then
				room:fillAG(ids, player)
				local id = room:askForAG(player, ids, false, "sxzengou", "sxzengou0")
				room:clearAG(p)
				local cn = sgs.Sanguosha:getEngineCard(id):objectName()
				room:setPlayerProperty(player, "sxzengouCn", ToData(cn))
				if room:askForUseCard(player, "@@sxzengou", "sxzengou1:" .. cn) then
					continue
				end
			end
			p:drawCards(1, "sxzengou")
		end
	end,
}
sxzengou = sgs.CreateViewAsSkillV2 {
	name = "sxzengou",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:usedTimes("#sxzengouCard") < 1 and player:getMark("sxzengouBan_lun") < 1
		end
		return request:getPattern() == "@@sxzengou"
	end,
	create_card = function(skill, request)
		if request:getPattern() == "@@sxzengou" then
			local dc = sgs.Sanguosha:cloneCard(request:getInitiator():property("sxzengouCn"):toString())
			dc:setSkillName("_sxzengou")
			return dc
		end
		return sxzengouCard:clone()
	end,
}
sx_qinghe:addSkill(sxzengou)
sxfeiliCard = sgs.CreateSkillCard {
	name = "sxfeiliCard",
	target_fixed = true,
	mute = true,
	on_use = function(self, room, player, targets)
		player:peiyin("feili")
		if self:subcardsLength() < 1 then
			room:addPlayerMark(player, "sxzengouBan_lun")
		end
	end,
}
sxfeilivs = sgs.CreateViewAsSkillV2 {
	name = "sxfeili",
	n = 2,
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@sxfeili"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		return not player:isJilei(candidate)
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		return request:getSelectedCardIds():length() == 2 or player:getMark("sxzengouBan_lun") < 1
	end,
	create_card = function(skill, request)
		local sc = sxfeiliCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(id)
		end
		return sc
	end,
}
sxfeili = sgs.CreateTriggerSkillV2 {
	name = "sxfeili",
	view_as_skill = sxfeilivs,
	events = { sgs.DamageInflicted },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.DamageInflicted then
			if player:getMark("sxzengouBan_lun") < 1 or player:getCardCount() > 1 and player:canDiscard(player, "he") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForUseCard(player, "@@sxfeili", "sxfeili0") ~= nil
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		return player:damageRevises(ctx.original_data, -damage.damage)
	end,
}
sx_qinghe:addSkill(sxfeili)

sx_huangwudie = sgs.General(sxfy_zhuque, "sx_huangwudie", "shu", 4, false)
sxshuangruivs = sgs.CreateViewAsSkillV2 {
	name = "sxshuangrui",
	n = 999,
	response_or_use = true,
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@sxshuangrui"
	end,
	can_select_card = function(skill, request, candidate)
		return not candidate:isEquipped()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local dc = sgs.Sanguosha:cloneCard("slash")
		dc:setSkillName("sxshuangrui")
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			dc:addSubcard(id)
		end
		return dc
	end,
}
sxshuangrui = sgs.CreateTriggerSkillV2 {
	name = "sxshuangrui",
	view_as_skill = sxshuangruivs,
	events = { sgs.EventPhaseStart, sgs.TargetSpecified },
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and event == sgs.TargetSpecified) then return end
		local use = ctx.original_data:toCardUse()
		if use.card:isKindOf("Slash") and table.contains(use.card:getSkillNames(), skill:objectName()) then
			local list = use.no_respond_list
			for i, p in sgs.qlist(use.to) do
				if p:getHandcardNum() == player:getHandcardNum() then
					table.insert(list, p:objectName())
				end
			end
			use.no_respond_list = list
			ctx.original_data:setValue(use)
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:askForUseCard(player, "@@sxshuangrui", "sxshuangrui0")
		return false
	end,
}
sx_huangwudie:addSkill(sxshuangrui)

sx_quyi = sgs.General(sxfy_zhuque, "sx_quyi", "qun", 4)
sxfuqi = sgs.CreateTriggerSkillV2 {
	name = "sxfuqi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified },
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player:isAlive() and event == sgs.TargetSpecified) then return end
		local use = ctx.original_data:toCardUse()
		if use.card:isKindOf("Slash") then
			local list = use.no_respond_list
			local has = true
			for i, p in sgs.qlist(use.to) do
				if p:distanceTo(player) == 1 then
					if player == ctx.owner then
						if has then
							has = false
							player:peiyin("fuqi")
							room:sendCompulsoryTriggerLog(player, skill:objectName())
						end
						table.insert(list, p:objectName())
					end
					if p:hasSkill(skill:objectName()) then
						p:peiyin("fuqi")
						room:sendCompulsoryTriggerLog(p, skill:objectName())
						table.insert(list, p:objectName())
					end
				end
			end
			use.no_respond_list = list
			ctx.original_data:setValue(use)
		end
	end,
}
sx_quyi:addSkill(sxfuqi)
sxjiaozi = sgs.CreateTriggerSkillV2 {
	name = "sxjiaozi",
	global = true,
	events = { sgs.DamageCaused },
	frequency = sgs.Skill_Compulsory,
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player:isAlive() and event == sgs.DamageCaused) then return end
		--local damage = ctx.original_data:toDamage()
		player:addMark("sxjiaoziNum-Clear")
		if player:getMark("sxjiaoziNum-Clear") == 1 then
			for i, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHandcardNum() > player:getHandcardNum() then
					return
				end
			end
			if player:hasSkill(skill:objectName()) then
				player:damageRevises(ctx.original_data, 1)
			end
		end
	end,
}
sx_quyi:addSkill(sxjiaozi)

sx_wenyuan = sgs.General(sxfy_zhuque, "sx_wenyuan", "shu", 3, false)
sxkengqiang = sgs.CreateTriggerSkillV2 {
	name = "sxkengqiang",
	events = { sgs.ConfirmDamage, sgs.CardUsed },
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player:isAlive() and event == sgs.ConfirmDamage
			and kesxV2RecordOnce(room, skill, ctx)) then return end
		local damage = ctx.original_data:toDamage()
		if damage.card and damage.card:hasFlag("sxkengqiangUse") then
			player:damageRevises(ctx.original_data, 1)
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isDamageCard() and player:getMark("sxkengqiangUse-Clear") < 1 and player:hasTurn() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("kengqiang")
		player:addMark("sxkengqiangUse-Clear")
		local use = ctx.original_data:toCardUse()
		if room:askForChoice(player, skill:objectName(), "sxkengqiang1+sxkengqiang2", ctx.original_data) == "sxkengqiang1" then
			player:drawCards(2, skill:objectName())
		else
			room:loseHp(player, 1, true, player, skill:objectName())
			room:setCardFlag(use.card, "sxkengqiangUse")
		end
		return false
	end,
}
sx_wenyuan:addSkill(sxkengqiang)
sxshangjue = sgs.CreateTriggerSkillV2 {
	name = "sxshangjue",
	events = { sgs.Dying },
	limit_mark = "@sxshangjue",
	frequency = sgs.Skill_Limited,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Dying then
			local dying = data:toDying()
			if dying.who == player and player:getMark("@sxshangjue") > 0 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("shangjue")
		room:doSuperLightbox(player, "sxshangjue")
		room:removePlayerMark(player, "@sxshangjue")
		room:recover(player, sgs.RecoverStruct(skill:objectName(), player, player:getMaxHp() - player:getHp()))
		if player:hasSkill("sxkengqiang", true) and player:askForSkillInvoke("sxshangjue0", ToData("srt"), false) then
			room:detachSkillFromPlayer(player, "sxkengqiang")
			room:addPlayerMark(player, "@sxshangjue")
		end
		return false
	end,
}
sx_wenyuan:addSkill(sxshangjue)

sx_jushou = sgs.General(sxfy_zhuque, "sx_jushou", "qun", 3)
sxjianying = sgs.CreateTriggerSkillV2 {
	name = "sxjianying",
	events = { sgs.EventPhaseStart, sgs.CardUsed },
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player:isAlive() and event == sgs.CardUsed and player:getPhase() == sgs.Player_Play) then return end
		local use = ctx.original_data:toCardUse()
		if use.card:getTypeId() > 0 then
			player:addMark(use.card:getSuitString() .. "sxjianyingS-PlayClear")
			player:addMark(use.card:getNumberString() .. "sxjianyingN-PlayClear")
			for _, m in sgs.list(player:getMarkNames()) do
				if m:startsWith("&sxjianying+") then
					if m:contains(use.card:getSuitString()) and player:getMark(use.card:getSuitString() .. "sxjianyingS-PlayClear") == 1 then
						player:drawCards(1, skill:objectName())
					end
					if m:contains(use.card:getNumberString()) and player:getMark(use.card:getNumberString() .. "sxjianyingS-PlayClear") == 1 then
						player:drawCards(1, skill:objectName())
					end
				end
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				for _, c in sgs.qlist(p:getCards("ej")) do
					for _, q in sgs.qlist(room:getAlivePlayers()) do
						if player:isProhibited(q, c) then
							continue
						end
						if c:isKindOf("EquipCard") then
							local n = c:getRealCard():toEquipCard():location()
							if q:getEquip(n) then
								continue
							end
						end
						return skill:objectName()
					end
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local aps = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			for _, c in sgs.qlist(p:getCards("ej")) do
				if aps:contains(p) then
					break
				end
				for _, q in sgs.qlist(room:getAlivePlayers()) do
					if player:isProhibited(q, c) then
						continue
					end
					if c:isKindOf("EquipCard") then
						local n = c:getRealCard():toEquipCard():location()
						if q:getEquip(n) then
							continue
						end
					end
					aps:append(p)
					break
				end
			end
		end
		local tp = room:askForPlayerChosen(player, aps, skill:objectName(), "sxjianying0", true, true)
		if tp then
			ctx.targets:append(tp)
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local tp = ctx.targets:first()
		player:peiyin("jianying")
		local ids = sgs.IntList()
		for _, c in sgs.qlist(tp:getCards("ej")) do
			local x = c:getId()
			for _, q in sgs.qlist(room:getAlivePlayers()) do
				if player:isProhibited(q, c) then
					continue
				end
				if c:isKindOf("EquipCard") then
					local n = c:getRealCard():toEquipCard():location()
					if q:getEquip(n) then
						continue
					end
				end
				x = -1
				break
			end
			if x > -1 then
				ids:append(x)
			end
		end
		local id = room:askForCardChosen(player, tp, "ej", skill:objectName(), false, sgs.Card_MethodNone, ids)
		local c = sgs.Sanguosha:getCard(id)
		local aps = sgs.SPlayerList()
		for _, q in sgs.qlist(room:getAlivePlayers()) do
			if player:isProhibited(q, c) then
				continue
			end
			if c:isKindOf("EquipCard") then
				local n = c:getRealCard():toEquipCard():location()
				if q:getEquip(n) then
					continue
				end
			end
			aps:append(q)
		end
		tp = room:askForPlayerChosen(player, aps, "sxjianying1", "sxjianying1:" .. c:objectName())
		if tp then
			room:setPlayerMark(player, "&sxjianying+" .. c:getSuitString() .. "_char+" .. c:getNumberString() .. "-PlayClear", 1)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), tp:objectName(), skill:objectName(), "")
			room:moveCardTo(c, tp, room:getCardPlace(id), reason, true)
		end
		return false
	end,
}
sx_jushou:addSkill(sxjianying)
sxshibei = sgs.CreateTriggerSkillV2 {
	name = "sxshibei",
	events = { sgs.Damaged },
	limit_mark = "@sxshibei",
	frequency = sgs.Skill_Limited,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Damaged and player:getMark("@sxshibei") > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("shibei")
		room:doSuperLightbox(player, "sxshibei")
		room:removePlayerMark(player, "@sxshibei")
		room:recover(player, sgs.RecoverStruct(skill:objectName(), player))
		return false
	end,
}
sx_jushou:addSkill(sxshibei)

sx_zhangxuan = sgs.General(sxfy_zhuque, "sx_zhangxuan", "wu", 3, false)
sxtongli = sgs.CreateTriggerSkillV2 {
	name = "sxtongli",
	global = true,
	events = { sgs.CardUsed },
	on_record = function(skill, event, room, player, ctx)
		if
			not (ctx.owner and player and player:isAlive() and player:getPhase() == sgs.Player_Play)
			or event ~= sgs.CardUsed
		then
			return
		end
		local use = ctx.original_data:toCardUse()
		if use.card:getTypeId() > 0 and kesxV2RecordOnce(room, skill, ctx) then
			player:addMark("sxtongliNum-PlayClear")
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardUsed and player:getPhase() == sgs.Player_Play then
			local use = data:toCardUse()
			if use.card:getTypeId() > 0 then
				local suits = {}
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					for _, c in sgs.qlist(p:getCards("ej")) do
						if table.contains(suits, c:getSuit()) then
							continue
						end
						table.insert(suits, c:getSuit())
					end
				end
				if #suits == player:getMark("sxtongliNum-PlayClear") then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("tongli")
		local use = ctx.original_data:toCardUse()
		use.extra_use = use.extra_use + 1
		ctx.original_data:setValue(use)
		return false
	end,
}
sx_zhangxuan:addSkill(sxtongli)
sxshezang = sgs.CreateTriggerSkillV2 {
	name = "sxshezang",
	events = { sgs.Dying },
	limit_mark = "@sxshezang",
	frequency = sgs.Skill_Limited,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Dying then
			local dying = data:toDying()
			if dying.who == player and player:getMark("@sxshezang") > 0 then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill, ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:peiyin("shezang")
		room:doSuperLightbox(player, "sxshezang")
		room:removePlayerMark(player, "@sxshezang")
		for i = 1, 4 do
			local aps = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				for _, e in sgs.qlist(p:getEquips()) do
					local n = e:getRealCard():toEquipCard():location()
					if player:getEquip(n) or player:isProhibited(player, e) then
						continue
					end
					aps:append(p)
					break
				end
			end
			local tp = room:askForPlayerChosen(player, aps, skill:objectName(), "sxshezang0", true)
			if tp then
				local ids = sgs.IntList()
				for _, e in sgs.qlist(tp:getEquips()) do
					local n = e:getRealCard():toEquipCard():location()
					if player:getEquip(n) or player:isProhibited(player, e) then
						ids:append(e:getId())
					end
				end
				local id = room:askForCardChosen(player, tp, "e", skill:objectName(), false, sgs.Card_MethodNone, ids)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), tp:objectName(), skill:objectName(), "")
				room:moveCardTo(sgs.Sanguosha:getCard(id), tp, sgs.Player_PlaceEquip, reason, true)
				if not player:isAlive() then
					break
				end
			else
				break
			end
		end
		return false
	end,
}
sx_zhangxuan:addSkill(sxshezang)

sx_xushao = sgs.General(sxfy_zhuque, "sx_xushao", "qun", 4)
sxyingmenCard = sgs.CreateSkillCard {
	name = "sxyingmenCard",
	target_fixed = true,
	mute = true,
	on_use = function(self, room, player, targets)
		player:drawCards(2, "sxyingmen")
		local dc = room:askForExchange(player, "sxyingmen", 2, 2, false, "sxyingmen0", false, "BasicCard,TrickCard+^DelayedTrick")
		if dc then
			player:addToPile("sxfangke", dc)
		end
	end,
}
sxyingmen = sgs.CreateViewAsSkillV2 {
	name = "sxyingmen",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:usedTimes("#sxyingmenCard") < 1 and player:getPile("sxfangke"):length() < 1
	end,
	create_card = function(skill, request)
		return sxyingmenCard:clone()
	end,
}
sx_xushao:addSkill(sxyingmen)
sxpingjianvs = sgs.CreateViewAsSkillV2 {
	name = "sxpingjian",
	n = 2,
	expand_pile = "sxfangke",
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or player:isKongcheng() then return false end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			for _, id in sgs.qlist(player:getPile("sxfangke")) do
				local c = sgs.Sanguosha:getEngineCard(id)
				local dc = dummyCard(c:objectName(), "sxpingjian")
				if dc:isAvailable(player) then
					return true
				end
			end
			return false
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return false end
		local pattern = request:getPattern()
		if string.sub(pattern, 1, 1) == "." or string.sub(pattern, 1, 1) == "@" then return false end
		for _, id in sgs.qlist(player:getPile("sxfangke")) do
			local c = sgs.Sanguosha:getCard(id)
			for _, cn in sgs.list(pattern:split("+")) do
				if c:objectName():contains(cn) then
					return true
				end
			end
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if candidate:isEquipped() then
			return false
		end
		if request:getSelectedCardIds():length() < 1 then
			local pattern = request:getPattern()
			if pattern ~= "" then
				for _, cn in sgs.list(pattern:split("+")) do
					if candidate:objectName():contains(cn) then
						return player:getPile("sxfangke"):contains(candidate:getId())
					end
				end
				return false
			end
			return player:getPile("sxfangke"):contains(candidate:getId())
		end
		return not player:getPile("sxfangke"):contains(candidate:getId())
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 2
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		local sc = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(ids:first()):objectName())
		sc:setSkillName("sxpingjian")
		sc:addSubcard(ids:last())
		return sc
	end,
}
sxpingjian = sgs.CreateTriggerSkillV2 {
	name = "sxpingjian",
	view_as_skill = sxpingjianvs,
	events = { sgs.CardFinished },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getSkillName() == skill:objectName() then
				local ids = player:getPile("sxfangke")
				if ids:length() > 0 then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local ids = player:getPile("sxfangke")
		if ids:length() > 0 then
			room:fillAG(ids, player)
			local id = room:askForAG(player, ids, false, skill:objectName(), "sxpingjian0")
			room:clearAG(player)
			room:throwCard(id, skill:objectName(), nil)
		end
		return false
	end,
}
sx_xushao:addSkill(sxpingjian)

sgs.LoadTranslationTable {

	["sxfy_zhuque"] = "四象封印·朱雀",

	["sx_xushao"] = "许劭[朱]",
	["#sx_xushao"] = "识人读心",
	["illustrator:sx_xushao"] = "Thinking",

	["sxyingmen"] = "盈门",
	[":sxyingmen"] = "出牌阶段限一次，若你没有“访客”，你可以摸两张牌，然后将等量的基本牌或普通锦囊牌置于武将牌上，当做“访客”。",
	["sxpingjian"] = "评鉴",
	[":sxpingjian"] = "你可以将一张手牌当做“访客”使用，然后移去一张“访客”。",
	["sxyingmen0"] = "盈门：请选择等量的基本牌或普通锦囊牌",
	["sxfangke"] = "访客",

	["sx_zhangxuan"] = "张嫙[朱]",
	["#sx_zhangxuan"] = "玉宇嫁蔷",
	["illustrator:sx_zhangxuan"] = "匠人绘",

	["sxtongli"] = "同礼",
	[":sxtongli"] = "出牌阶段限一次，当你使用牌时，若你本阶段已使用的牌等于X，你可以令此牌额外结算一次（X为场上牌的花色数）。",
	["sxshezang"] = "奢葬",
	[":sxshezang"] = "限定技，当你陷入濒死状态时，你可以将场上4张牌移动到你的装备区。",
	["sxshezang0"] = "奢葬：请选择移动牌的来源",

	["sx_jushou"] = "沮授[朱]",
	["#sx_jushou"] = "徐图渐营",
	["illustrator:sx_jushou"] = "匠人绘",

	["sxjianying"] = "渐营",
	[":sxjianying"] = "出牌阶段开始时，你可以移动场上一张牌，然后你于此阶段首次使用与此牌花色或点数相同的牌时，你摸一张牌。",
	["sxshibei"] = "矢北",
	[":sxshibei"] = "限定技，当你受到伤害后，你可以回复1点体力。",
	["sxjianying0"] = "你可以发动“渐营”选择角色移动牌",
	["sxjianying1"] = "渐营：请选择【%src】移动目标",

	["sx_wenyuan"] = "文鸳[朱]",
	["#sx_wenyuan"] = "揾泪红袖",
	["illustrator:sx_wenyuan"] = "匠人绘",

	["sxkengqiang"] = "铿锵",
	[":sxkengqiang"] = "每回合限一次，当你使用伤害类牌时，你可以选择一项：1.摸两张牌；2.失去1点体力令此牌伤害+1。",
	["sxshangjue"] = "伤决",
	[":sxshangjue"] = "限定技，当你陷入濒死状态时，你可以回复体力至上限，然后你可以失去“铿锵”令此技能视为未发动。",
	["sxkengqiang1"] = "摸两张牌",
	["sxkengqiang2"] = "失去1点体力令此牌伤害+1",
	["sxshangjue0:srt"] = "伤决：你可以失去“铿锵”令此技能视为未发动",

	["sx_quyi"] = "麹义[朱]",
	["#sx_quyi"] = "名门的骁将",
	["illustrator:sx_quyi"] = "克里斯",

	["sxfuqi"] = "伏骑",
	[":sxfuqi"] = "锁定技，你和与你距离为1的角色互相使用的【杀】不能被响应。",
	["sxjiaozi"] = "骄恣",
	[":sxjiaozi"] = "锁定技，当你每回合首次造成伤害时，若你的手牌最多，此伤害+1。",

	["sx_huangwudie"] = "黄舞蝶[朱]",
	["#sx_huangwudie"] = "力弓双绝",
	["illustrator:sx_huangwudie"] = "克里斯",

	["sxshuangrui"] = "双锐",
	[":sxshuangrui"] = "准备阶段，你可以将任意手牌当做【杀】使用，若目标手牌与你相同，其不能响应此牌。",
	["sxshuangrui0"] = "你可以发动“双锐”将任意手牌当【杀】使用",

	["sx_qinghe"] = "清河公主[朱]",
	["#sx_qinghe"] = "冀不推宝",
	["illustrator:sx_qinghe"] = "克里斯",

	["sxzengou"] = "谮构",
	[":sxzengou"] = "出牌阶段限一次，你可以观看一名角色手牌并展示其中两张牌，然后你需视为使用一张与展示牌牌名均不同的基本牌，否则其摸一张牌。",
	["sxfeili"] = "诽离",
	[":sxfeili"] = "当你受到伤害时，你可以弃置两张牌或令“谮构”本轮失效，然后防止此伤害。",
	["sxzengou0"] = "谮构：请选择要视为使用的牌",
	["sxzengou1"] = "谮构：请视为使用【%src】",
	["sxfeili0"] = "你可以发动“诽离”防止此伤害",
}

sxfy_xuanwu = sgs.Package("sxfy_xuanwu",sgs.Package_GeneralPack)

sx_lvboshe = sgs.General(sxfy_xuanwu,"sx_lvboshe","qun",4)
sxfushivs = sgs.CreateViewAsSkillV2{
	name = "sxfushi",
	n = 998,
	response_or_use = true,
	can_activate = function(skill,request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return sgs.Slash_IsAvailable(player)
		end
		return request:getPattern():contains("slash")
	end,
	can_select_card = function(skill,request,candidate)
		return candidate:isKindOf("Slash")
	end,
	card_selection_feasible = function(skill,request)
		return request:getSelectedCardIds():length()>0
	end,
	create_card = function(skill,request)
		local sc = sgs.Sanguosha:cloneCard("slash")
		sc:setSkillName("sxfushi")
		for _,id in sgs.qlist(request:getSelectedCardIds())do
			sc:addSubcard(id)
		end
		return sc
	end,
}
sxfushi = sgs.CreateTriggerSkillV2{
	name = "sxfushi",
	view_as_skill = sxfushivs,
	events = {sgs.CardFinished,sgs.CardUsed},
	on_record = function(skill,event,room,player,ctx)
		if not (ctx.owner and player and player:isAlive()) then return end
		if event==sgs.CardFinished then
			local use = ctx.original_data:toCardUse()
			if use.card:hasFlag("sxfushiBf") then
				for _,p in sgs.qlist(room:getAllPlayers())do
					if use.card:hasFlag("sxfushiBf"..p:objectName()) and p:hasSkill(skill) then
						if room:getCardOwner(use.card:getEffectiveId()) then break end
						p:peiyin("fushi")
						room:sendCompulsoryTriggerLog(p,skill:objectName())
						p:obtainCard(use.card)
					end
				end
			end
		else
			local use = ctx.original_data:toCardUse()
			if use.card:getSkillName()==skill:objectName() then
				player:peiyin("fushi")
			end
			if use.card:isKindOf("Slash") and player:getMark("sxfushiNum-Clear")<1 then
				player:addMark("sxfushiNum-Clear")
				for _,p in sgs.qlist(room:getAlivePlayers())do
					if p:distanceTo(player)<=1 then
						room:setCardFlag(use.card,"sxfushiBf")
						room:setCardFlag(use.card,"sxfushiBf"..p:objectName())
					end
				end
			end
		end
	end,
}
sx_lvboshe:addSkill(sxfushi)

sx_caojinyu = sgs.General(sxfy_xuanwu,"sx_caojinyu","wei",3,false)
sxyuqi = sgs.CreateTriggerSkillV2{
	name = "sxyuqi",
	events = {sgs.Damaged},
	can_trigger = function(skill,event,room,player,data)
		if event==sgs.Damaged and player and player:isAlive() then
			local skills = {}
			local owners = {}
			for _,p in sgs.qlist(room:getAllPlayers())do
				if p:distanceTo(player)<=p:getHp() and p:hasSkill(skill) then
					table.insert(skills,skill:objectName())
					table.insert(owners,p:objectName())
				end
			end
			if #skills>0 then
				return table.concat(skills,"|"),table.concat(owners,"|")
			end
		end
		return false
	end,
	on_cost = function(skill,event,room,player,ctx)
		return player:askForSkillInvoke(skill:objectName(),ctx.invoker)
	end,
	on_effect = function(skill,event,room,player,ctx)
		player:peiyin("yuqi")
		player:drawCards(1,skill:objectName())
		return false
	end,
}
sx_caojinyu:addSkill(sxyuqi)
sxshanshen = sgs.CreateTriggerSkillV2{
	name = "sxshanshen",
	events = {sgs.Death},
	can_trigger = function(skill,event,room,player,data)
		if event==sgs.Death then
			local death = data:toDeath()
			if death.damage and death.damage.from==player then return false end
			if player:isWounded() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill,event,room,player,ctx)
		return player:askForSkillInvoke(skill)
	end,
	on_effect = function(skill,event,room,player,ctx)
		player:peiyin("shanshen")
		room:recover(player,sgs.RecoverStruct(skill:objectName(),player))
		return false
	end,
}
sx_caojinyu:addSkill(sxshanshen)

sx_kebineng = sgs.General(sxfy_xuanwu,"sx_kebineng","qun",4)
sxkoujingvs = sgs.CreateViewAsSkillV2{
	name = "sxkoujing",
	n = 998,
	response_or_use = true,
	can_activate = function(skill,request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:getMark("sxkoujingUse-PlayClear")<1
		end
		return false
	end,
	can_select_card = function(skill,request,candidate)
		return not candidate:isEquipped()
	end,
	card_selection_feasible = function(skill,request)
		return request:getSelectedCardIds():length()>0
	end,
	create_card = function(skill,request)
		local sc = sgs.Sanguosha:cloneCard("slash")
		sc:setSkillName("sxkoujing")
		for _,id in sgs.qlist(request:getSelectedCardIds())do
			sc:addSubcard(id)
		end
		return sc
	end,
}
sxkoujing = sgs.CreateTriggerSkillV2{
	name = "sxkoujing",
	view_as_skill = sxkoujingvs,
	events = {sgs.Damaged,sgs.CardUsed},
	on_record = function(skill,event,room,player,ctx)
		if not (ctx.owner and player and player:isAlive() and event==sgs.CardUsed) then return end
		local use = ctx.original_data:toCardUse()
		if table.contains(use.card:getSkillNames(),skill:objectName()) then
			room:addPlayerMark(player,"sxkoujingUse-Clear")
			player:peiyin("koujing")
		end
	end,
	can_trigger = function(skill,event,room,player,data)
		if event==sgs.Damaged and player and player:isAlive() then
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),skill:objectName()) and player~=damage.from then
				local skills = {}
				local owners = {}
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:hasSkill(skill) then
						table.insert(skills,skill:objectName())
						table.insert(owners,p:objectName())
					end
				end
				if #skills>0 then
					return table.concat(skills,"|"),table.concat(owners,"|")
				end
			end
		end
		return false
	end,
	on_cost = function(skill,event,room,player,ctx)
		local damage = ctx.original_data:toDamage()
		return ctx.invoker:askForSkillInvoke(skill,ToData("0:"..damage.from:objectName()),false)
	end,
	on_effect = function(skill,event,room,player,ctx)
		local damage = ctx.original_data:toDamage()
		room:swapCards(ctx.invoker,damage.from,"h",skill:objectName())
		return false
	end,
}
sx_kebineng:addSkill(sxkoujing)

sx_ganfuren = sgs.General(sxfy_xuanwu,"sx_ganfuren","shu",3,false)
sxzhijie = sgs.CreateTriggerSkillV2{
	name = "sxzhijie",
	events = {sgs.EventPhaseStart,sgs.CardUsed},
	on_record = function(skill,event,room,player,ctx)
		if
			not (ctx.owner and player and player:isAlive() and player:getPhase()==sgs.Player_Play)
			or event~=sgs.CardUsed
		then
			return
		end
		local use = ctx.original_data:toCardUse()
		if use.card:getTypeId()>0 and player:getMark("sxzhijieUse-PlayClear")>0
		and player:getMark("sxzhijieNum-PlayClear")<3 and kesxV2RecordOnce(room,skill,ctx) then
			player:addMark("sxzhijieNum-PlayClear")
			for _,p in sgs.qlist(room:getAllPlayers())do
				if player:getMark("&sxzhijie+"..use.card:getType().."+#"..p:objectName().."-PlayClear")>0 then
					p:drawCards(1,skill:objectName())
				end
			end
		end
	end,
	can_trigger = function(skill,event,room,player,data)
		if event==sgs.EventPhaseStart and player and player:isAlive() and player:getPhase()==sgs.Player_Play
		and player:getHandcardNum()>0 then
			local skills = {}
			local owners = {}
			for _,p in sgs.qlist(room:getAllPlayers())do
				if p:getMark("sxzhijieUse_lun")<1 and p:hasSkill(skill) then
					table.insert(skills,skill:objectName())
					table.insert(owners,p:objectName())
				end
			end
			if #skills>0 then
				return table.concat(skills,"|"),table.concat(owners,"|")
			end
		end
		return false
	end,
	on_cost = function(skill,event,room,player,ctx)
		return player:askForSkillInvoke(skill:objectName(),ctx.invoker)
	end,
	on_effect = function(skill,event,room,player,ctx)
		player:peiyin("zhijie")
		player:addMark("sxzhijieUse_lun")
		local id = room:askForCardChosen(player,ctx.invoker,"h",skill:objectName())
		if id<0 then return false end
		room:showCard(ctx.invoker,id)
		id = sgs.Sanguosha:getEngineCard(id):getType()
		room:setPlayerMark(ctx.invoker,"&sxzhijie+"..id.."+#"..player:objectName().."-PlayClear",1)
		ctx.invoker:addMark("sxzhijieUse-PlayClear")
		return false
	end,
}
sx_ganfuren:addSkill(sxzhijie)
sxshushen = sgs.CreateTriggerSkillV2{
	name = "sxshushen",
	events = {sgs.EventPhaseChanging,sgs.CardsMoveOneTime},
	on_record = function(skill,event,room,player,ctx)
		if not (ctx.owner and player and event==sgs.CardsMoveOneTime) then return end
		local move = ctx.original_data:toMoveOneTime()
		if (move.to_place==sgs.Player_PlaceHand or move.to_place==sgs.Player_PlaceEquip)
		and move.to:objectName()==player:objectName() and player:hasTurn()
		and kesxV2RecordOnce(room, skill, ctx) then
			player:addMark("sxshushenNum-Clear",move.card_ids:length())
		end
	end,
	can_trigger = function(skill,event,room,player,data)
		if event==sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local skills = {}
				local owners = {}
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:getMark("sxshushenNum-Clear")>2 and p:hasSkill(skill:objectName()) then
						table.insert(skills,skill:objectName())
						table.insert(owners,p:objectName())
					end
				end
				if #skills>0 then
					return table.concat(skills,"|"),table.concat(owners,"|")
				end
			end
		end
		return false
	end,
	on_cost = function(skill,event,room,player,ctx)
		local tps = sgs.SPlayerList()
		for _,q in sgs.qlist(room:getOtherPlayers(player))do
			if q:isWounded() then tps:append(q) end
		end
		local tp = room:askForPlayerChosen(player,tps,skill:objectName(),"sxshushen0",true,true)
		if tp then
			ctx.targets:append(tp)
			return true
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		player:peiyin("shushen")
		room:recover(ctx.targets:first(),sgs.RecoverStruct(skill:objectName(),player))
		return false
	end,
}
sx_ganfuren:addSkill(sxshushen)

sx_niujin = sgs.General(sxfy_xuanwu,"sx_niujin","wei",4)
sxcuorui = sgs.CreateTriggerSkillV2{
	name = "sxcuorui",
	events = {sgs.Death,sgs.GameStart},
	can_trigger = function(skill,event,room,player,data)
		if event==sgs.Death then
			local death = data:toDeath()
			if death.damage and death.damage.from==player then else return false end
		end
		local x = math.min(7,room:getPlayers():length())
		if player:getHandcardNum()<x then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill,event,room,player,ctx)
		return player:askForSkillInvoke(skill)
	end,
	on_effect = function(skill,event,room,player,ctx)
		player:peiyin("cuorui")
		local x = math.min(7,room:getPlayers():length())
		player:drawCards(x-player:getHandcardNum(),skill:objectName())
		return false
	end,
}
sx_niujin:addSkill(sxcuorui)

sx_wuke = sgs.General(sxfy_xuanwu,"sx_wuke","wu",3,false)
sxanda = sgs.CreateTriggerSkillV2{
	name = "sxanda",
	events = {sgs.Dying},
	can_trigger = function(skill,event,room,player,data)
		if event==sgs.Dying then
			local dying = data:toDying()
			if player:getMark("sxandaUse_lun")<1 and dying.damage and dying.damage.from then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill,event,room,player,ctx)
		return player:askForSkillInvoke(skill,ctx.original_data:toDying().who)
	end,
	on_effect = function(skill,event,room,player,ctx)
		player:addMark("sxandaUse_lun")
		player:peiyin("anda")
		local dying = ctx.original_data:toDying()
		if dying.damage.from:getCardCount()>0 then
			local dc = room:askForCard(dying.damage.from,"..","sxanda0:"..dying.who:objectName(),ctx.original_data,sgs.Card_MethodNone)
			if dc then
				room:giveCard(dying.damage.from,dying.who,dc,skill:objectName())
				return false
			end
		end
		room:recover(dying.who,sgs.RecoverStruct(skill:objectName(),player))
		return false
	end,
}
sx_wuke:addSkill(sxanda)
sxzhuguoCard = sgs.CreateSkillCard{
	name = "sxzhuguoCard",
	target_fixed = false,
	mute = true,
	filter = function(self,targets,to_select,source)
		return #targets<1
	end,
	on_use = function(self,room,player,targets)
		player:peiyin("zengou")
		for _,p in sgs.list(targets)do
			local x = 2-p:getHandcardNum()
			if x>0 then
				p:drawCards(x,"sxzhuguo")
			end
		end
	end
}
sxzhuguo = sgs.CreateViewAsSkillV2{
	name = "sxzhuguo",
	n = 0,
	can_activate = function(skill,request)
		local player = request:getInitiator()
		if not player then return false end
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:usedTimes("#sxzhuguoCard")<1
	end,
	create_card = function(skill,request)
		return sxzhuguoCard:clone()
	end,
}
sx_wuke:addSkill(sxzhuguo)

sx_wangshen = sgs.General(sxfy_xuanwu,"sx_wangshen","wei",3)
sxanran = sgs.CreateTriggerSkillV2{
	name = "sxanran",
	events = {sgs.Damaged},
	can_trigger = function(skill,event,room,player,data)
		if event==sgs.Damaged then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill,event,room,player,ctx)
		return player:askForSkillInvoke(skill)
	end,
	on_effect = function(skill,event,room,player,ctx)
		player:peiyin("anran")
		local x = math.min(4,player:getMark("&sxanran+#num")+1)
		player:drawCards(x,skill:objectName())
		room:addPlayerMark(player,"&sxanran+#num")
		return false
	end,
}
sx_wangshen:addSkill(sxanran)
sxgaobanvs = sgs.CreateViewAsSkillV2{
	name = "sxgaoban",
	n = 1,
	expand_pile = "#sxgaoban",
	can_activate = function(skill,request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@sxgaoban"
	end,
	can_select_card = function(skill,request,candidate)
		return request:getInitiator():getPileName(candidate:getId())=="#sxgaoban"
	end,
	card_selection_feasible = function(skill,request)
		return request:getSelectedCardIds():length()>0
	end,
	create_card = function(skill,request)
		return sgs.Sanguosha:getCard(request:getSelectedCardIds():first())
	end,
}
sxgaoban = sgs.CreateTriggerSkillV2{
	name = "sxgaoban",
	view_as_skill = sxgaobanvs;
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging,sgs.CardsMoveOneTime,sgs.DamageDone},
	on_record = function(skill,event,room,player,ctx)
		if not (ctx.owner and player) then return end
		if event==sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			if move.to_place==sgs.Player_DiscardPile then
				for _,id in sgs.qlist(move.card_ids)do
					player:addMark(id.."sxshushenId-Clear")
				end
			end
		elseif event==sgs.DamageDone then
			local aps = room:getTag("sxgaobanDone"):toString():split("+")
			if table.contains(aps,player:objectName()) then return end
			table.insert(aps,player:objectName())
			room:setTag("sxgaobanDone",ToData(table.concat(aps,"+")))
		else
			local change = ctx.original_data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local first = nil
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p:hasSkill(skill:objectName()) then first = p break end
				end
				if ctx.owner == (first or player) then
					player:setTag("sxgaobanPending", ToData(room:getTag("sxgaobanDone"):toString()))
					room:removeTag("sxgaobanDone")
				end
			end
		end
	end,
	can_trigger = function(skill,event,room,player,data)
		if event==sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local ap = player:getTag("sxgaobanPending"):toString()
				if ap ~= "" and not ap:contains("+") then
					local skills = {}
					local owners = {}
					for _,p in sgs.qlist(room:getOtherPlayers(player))do
						if p:hasSkill(skill:objectName()) then
							table.insert(skills,skill:objectName())
							table.insert(owners,p:objectName())
						end
					end
					if #skills>0 then
						return table.concat(skills,"|"),table.concat(owners,"|")
					end
				end
			end
		end
		return false
	end,
	on_effect = function(skill,event,room,player,ctx)
		local ap = ctx.invoker:getTag("sxgaobanPending"):toString()
		if not ap:contains("+") then
			for _,q in sgs.qlist(room:getAlivePlayers())do
				if q:objectName()==ap then
					local ids = sgs.IntList()
					player:peiyin("gaoban")
					room:sendCompulsoryTriggerLog(player,skill:objectName())
					for _,id in sgs.qlist(room:getDiscardPile())do
						if player:getMark(id.."sxshushenId-Clear")>0 then
							local c = sgs.Sanguosha:getCard(id)
							if c:isKindOf("Slash") and c:isAvailable(q) then
								ids:append(id)
							end
						end
					end
					if ids:length()>0 then
						room:notifyMoveToPile(q,ids,"sxgaoban")
						if room:askForUseCard(q,"@@sxgaoban","sxgaoban0") then break end
					end
					room:setPlayerMark(player,"&sxanran+#num",0)
				end
			end
		end
		room:removeTag("sxgaobanDone")
		return false
	end,
}
sx_wangshen:addSkill(sxgaoban)






sgs.LoadTranslationTable{

	["sxfy_xuanwu"] = "四象封印·玄武",


	["sx_wangshen"] = "王沈[玄]",
	["#sx_wangshen"] = "崇虎田光",
	["illustrator:sx_wangshen"] = "错落宇宙",

	["sxanran"] = "岸然",
	[":sxanran"] = "当你受到伤害后，你可以摸一张牌，然后此技能摸牌数+1",
	["sxgaoban"] = "告变",
	[":sxgaoban"] = "锁定技，其他角色的回合结束时，若本回合仅有一名角色受到伤害，此受到伤害的角色选择一项：1.使用本回合置入弃牌堆的一张【杀】；2.令你重置“岸然”。",
	["sxgaoban0"] = "告变：你可以使用弃牌堆一张【杀】",
	["#sxgaoban"] = "弃牌堆",

	["sx_wuke"] = "吴珂[玄]",
	["#sx_wuke"] = "智略权谲",
	["illustrator:sx_wuke"] = "铁杵",

	["sxanda"] = "谙达",
	[":sxanda"] = "每轮限一次，当一名角色陷入濒死时，你可以令伤害来源选择一项：1.交给其一张牌；2.其回复1点体力。",
	["sxzhuguo"] = "助国",
	[":sxzhuguo"] = "出牌阶段限一次，你可以令一名角色将手牌摸至2张。",
	["sxanda0"] = "谙达：请交给%src一张牌，否则其回复1点体力",

	["sx_niujin"] = "牛金[玄]",
	["#sx_niujin"] = "独进的兵胆",
	["illustrator:sx_niujin"] = "游漫美绘",

	["sxcuorui"] = "挫锐",
	[":sxcuorui"] = "游戏开始时和你杀死其他角色时，你可以摸牌至X张（X为角色数且至多为7）。",

	["sx_ganfuren"] = "甘夫人[玄]",
	["#sx_ganfuren"] = "昭烈皇后",
	["illustrator:sx_ganfuren"] = "错落宇宙",

	["sxzhijie"] = "智诫",
	[":sxzhijie"] = "每轮限一次，一名角色出牌阶段开始时，你可以展示其一张手牌，其此阶段前3次使用与此牌类型相同的牌时，你摸一张牌。",
	["sxshushen"] = "淑慎",
	[":sxshushen"] = "每回合结束时，若你本回合获得了至少3张牌。你可以令一名其他角色回复1点体力。",
	["sxshushen0"] = "你可以发动“淑慎”选择令一名其他角色回复体力",

	["sx_lvboshe"] = "吕伯奢[玄]",
	["#sx_lvboshe"] = "醉乡路稳",
	["illustrator:sx_lvboshe"] = "丝葱",

	["sxfushi"] = "缚豕",
	[":sxfushi"] = "你距离1以内的角色使用每回合首次使用【杀】结算后，你获得之。你可以将任意张【杀】当做一张指定至多等量目标的【杀】使用。",

	["sx_caojinyu"] = "曹金玉[玄]",
	["#sx_caojinyu"] = "金乡公主",
	["illustrator:sx_caojinyu"] = "月月岛",

	["sxyuqi"] = "隅泣",
	[":sxyuqi"] = "计算与你距离小于等于你体力值的角色受到伤害后，你可以令其摸一张牌。",
	["sxshanshen"] = "善身",
	[":sxshanshen"] = "当一名角色死亡后，若伤害来源不为你。你可以回复1点体力。",

	["sx_kebineng"] = "轲比能[玄]",
	["#sx_kebineng"] = "瀚海鲸波",
	["illustrator:sx_kebineng"] = "丝葱",

	["sxkoujing"] = "寇旌",
	[":sxkoujing"] = "出牌阶段限一次，你可以将任意手牌当做一张无距离与次数限制的杀使用，当其他角色受到此【杀】造成的伤害后，其可以与你交换手牌。",
	["sxkoujing:0"] = "寇旌：你可以与%src交换手牌",



}

sxfy_zhencang = sgs.Package("sxfy_zhencang", sgs.Package_GeneralPack)

_zc_xuanhuafuTr = sgs.CreateTriggerSkillV2 {
	name = "_zc_xuanhuafu",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecifying },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.TargetSpecifying and player:hasWeapon("_zc_xuanhuafu") then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _, p in sgs.list(room:getOtherPlayers(player)) do
					if use.to:contains(p) then
						continue
					end
					for _, q in sgs.list(use.to) do
						if q:distanceTo(p) == 1 and player:canSlash(p, use.card, false) then
							return skill:objectName()
						end
					end
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local tps = sgs.SPlayerList()
		for _, p in sgs.list(room:getOtherPlayers(player)) do
			if use.to:contains(p) then
				continue
			end
			for _, q in sgs.list(use.to) do
				if q:distanceTo(p) == 1 and player:canSlash(p, use.card, false) then
					tps:append(p)
					break
				end
			end
		end
		local tp = room:askForPlayerChosen(player, tps, skill:objectName(), "_zc_xuanhuafu0", false, true)
		if tp then
			ctx.targets:append(tp)
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		room:setEmotion(player, "weapon/_zc_xuanhuafu")
		use.to:append(ctx.targets:first())
		room:sortByActionOrder(use.to)
		ctx.original_data:setValue(use)
		return false
	end,
}
_zc_xuanhuafu = sgs.CreateWeapon {
	name = "_zc_xuanhuafu",
	class_name = "Xuanhuafu",
	range = 3,
	suit = 3,
	number = 5,
	equip_skill = _zc_xuanhuafuTr,
	on_install = function(self, player)
		local room = player:getRoom()
		room:acquireSkill(player, _zc_xuanhuafuTr, true, true, false)
		return false
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "_zc_xuanhuafu", true, true)
		return false
	end,
}
_zc_xuanhuafu:setParent(sxfy_zhencang)

zc_zhengcong = sgs.General(sxfy_zhencang, "zc_zhengcong", "qun", 4, false)
zcqiyue = sgs.CreateTriggerSkillV2 {
	name = "zcqiyue",
	events = { sgs.GameStart },
	waked_skills = "_zc_xuanhuafu",
	frequency = sgs.Skill_Compulsory,
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player == ctx.owner and event == sgs.GameStart) then return end
		for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
			if room:getCardOwner(id) then
				continue
			end
			local c = sgs.Sanguosha:getCard(id)
			if c:isKindOf("Xuanhuafu") then
				room:sendCompulsoryTriggerLog(player, skill)
				player:obtainCard(c)
				break
			end
		end
	end,
}
zc_zhengcong:addSkill(zcqiyue)
zcjieji = sgs.CreateTriggerSkillV2 {
	name = "zcjieji",
	events = { sgs.Damage, sgs.PreCardUsed },
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player:isAlive() and event == sgs.PreCardUsed) then return end
		local use = ctx.original_data:toCardUse()
		if use.card:isKindOf("Slash") then
			player:addMark("zcjiejiSlash")
			if player:getMark("zcjiejiSlash") == 1 then
				room:setCardFlag(use.card, "zcjiejiSlash")
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Damage and player and player:isAlive() then
			local damage = data:toDamage()
			if
				damage.card
				and damage.card:hasFlag("zcjiejiSlash")
				and damage.to ~= player
				and damage.to:isAlive()
				and damage.to:getCardCount() > 0
			then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		return player:askForSkillInvoke(skill, damage.to)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local id = room:askForCardChosen(player, damage.to, "he", skill:objectName())
		if id >= 0 then
			room:obtainCard(player, id, false)
			local dc = dummyCard(nil, "_zcjieji")
			if damage.to:canSlash(player, dc, false) then
				room:useCard(sgs.CardUseStruct(dc, damage.to, player))
			end
		end
		return false
	end,
}
zc_zhengcong:addSkill(zcjieji)

_zc_baipishuangbiTr = sgs.CreateTriggerSkillV2 {
	name = "_zc_baipishuangbi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.TargetSpecified, sgs.ConfirmDamage },
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player == ctx.owner and player:hasWeapon("_zc_baipishuangbi")) then return end
		if event == sgs.TargetSpecified then
			local use = ctx.original_data:toCardUse()
			if use.card:isKindOf("Slash") then
				local can = true
				for _, p in sgs.list(use.to) do
					if p:getGender() ~= player:getGender() and player:isKongcheng() then
						if can then
							can = false
							room:setEmotion(player, "weapon/_zc_baipishuangbi")
							room:sendCompulsoryTriggerLog(player, skill)
						end
						room:setCardFlag(use.card, "Baipishuangbi" .. p:objectName())
					end
				end
			end
		else
			local damage = ctx.original_data:toDamage()
			if damage.card and damage.card:hasFlag("Baipishuangbi" .. damage.to:objectName()) then
				player:damageRevises(ctx.original_data, 1)
			end
		end
	end,
}
_zc_baipishuangbi = sgs.CreateWeapon {
	name = "_zc_baipishuangbi",
	class_name = "Baipishuangbi",
	range = 1,
	suit = 0,
	number = 2,
	equip_skill = _zc_baipishuangbiTr,
	on_install = function(self, player)
		local room = player:getRoom()
		room:acquireSkill(player, _zc_baipishuangbiTr, true, true, false)
		return false
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "_zc_baipishuangbi", true, true)
		return false
	end,
}
_zc_baipishuangbi:setParent(sxfy_zhencang)

zc_jiangjie = sgs.General(sxfy_zhencang, "zc_jiangjie", "qun", 3, false)
zcfengzhan = sgs.CreateTriggerSkillV2 {
	name = "zcfengzhan",
	events = { sgs.GameStart },
	waked_skills = "_zc_baipishuangbi",
	frequency = sgs.Skill_Compulsory,
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player == ctx.owner and event == sgs.GameStart) then return end
		for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
			if room:getCardOwner(id) then
				continue
			end
			local c = sgs.Sanguosha:getCard(id)
			if c:isKindOf("Baipishuangbi") then
				room:sendCompulsoryTriggerLog(player, skill)
				player:obtainCard(c)
				break
			end
		end
	end,
}
zc_jiangjie:addSkill(zcfengzhan)
zcruixivs = sgs.CreateViewAsSkillV2 {
	name = "zcruixi",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@zcruixi"
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local dc = sgs.Sanguosha:cloneCard("slash")
		dc:setSkillName(skill:objectName())
		dc:addSubcard(request:getSelectedCardIds():first())
		return dc
	end,
}
zcruixi = sgs.CreateTriggerSkillV2 {
	name = "zcruixi",
	view_as_skill = zcruixivs,
	events = { sgs.EventPhaseStart, sgs.CardsMoveOneTime },
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player:isAlive() and event == sgs.CardsMoveOneTime) then return end
		local move = ctx.original_data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
			if move.from:objectName() == player:objectName() and (move.from ~= move.to or move.to_place ~= sgs.Player_PlaceHand and move.to_place ~= sgs.Player_PlaceEquip) then
				player:addMark("zcruixiHas-Clear")
			end
		end
	end,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player and player:isAlive() and player:getPhase() == sgs.Player_Finish then
			local skills = {}
			local owners = {}
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("zcruixiHas-Clear") > 0 and p:hasSkill(skill) and p:getCardCount() > 0 then
					table.insert(skills, skill:objectName())
					table.insert(owners, p:objectName())
				end
			end
			if #skills > 0 then
				return table.concat(skills, "|"), table.concat(owners, "|")
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:askForUseCard(player, "@@zcruixi", "zcruixi0")
		return false
	end,
}
zc_jiangjie:addSkill(zcruixi)

zc_zhangmeiren = sgs.General(sxfy_zhencang, "zc_zhangmeiren", "wu", 3, false)
zclianrong = sgs.CreateTriggerSkillV2 {
	name = "zclianrong",
	events = { sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if
				move.to_place == sgs.Player_DiscardPile
				and move.from
				and move.from:objectName() ~= player:objectName()
				and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
			then
				for _, id in sgs.qlist(move.card_ids) do
					local c = sgs.Sanguosha:getCard(id)
					if c:getSuit() == 2 and room:getCardOwner(id) == nil then
						return skill:objectName()
					end
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local ids = sgs.IntList()
		for _, id in sgs.qlist(move.card_ids) do
			local c = sgs.Sanguosha:getCard(id)
			if c:getSuit() == 2 and room:getCardOwner(id) == nil then
				ids:append(id)
			end
		end
		if ids:length() > 0 then
			room:fillAG(ids, player)
			if player:askForSkillInvoke(skill) then
				return true
			end
			room:clearAG(player)
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		local ids = sgs.IntList()
		for _, id in sgs.qlist(move.card_ids) do
			local c = sgs.Sanguosha:getCard(id)
			if c:getSuit() == 2 and room:getCardOwner(id) == nil then
				ids:append(id)
			end
		end
		local aps = sgs.SPlayerList()
		aps:append(player)
		local dc = dummyCard()
		while ids:length() > 0 do
			local id = room:askForAG(player, ids, true, skill:objectName(), "zclianrong0")
			if id < 0 then
				break
			end
			ids:removeOne(id)
			room:takeAG(player, id, false, aps)
			dc:addSubcard(id)
		end
		player:obtainCard(dc)
		room:clearAG(player)
		return false
	end,
}
zc_zhangmeiren:addSkill(zclianrong)
zcyuanzhuoCard = sgs.CreateSkillCard {
	name = "zcyuanzhuoCard",
	target_fixed = false,
	filter = function(self, targets, to_select, source)
		return #targets < 1 and to_select ~= source and source:canDiscard(to_select, "he")
	end,
	on_use = function(self, room, player, targets)
		for i, p in sgs.list(targets) do
			local id = room:askForCardChosen(player, p, "he", "zcyuanzhuo", false, sgs.Card_MethodDiscard)
			if id >= 0 then
				room:throwCard(id, "zcyuanzhuo", p, player)
				local dc = dummyCard("fire_attack", "_zcyuanzhuo")
				if p:canUse(dc, player) then
					room:useCard(sgs.CardUseStruct(dc, p, player))
				end
			end
		end
	end,
}
zcyuanzhuo = sgs.CreateViewAsSkillV2 {
	name = "zcyuanzhuo",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and player:usedTimes("#zcyuanzhuoCard") < 1
	end,
	create_card = function(skill, request)
		return zcyuanzhuoCard:clone()
	end,
}
zc_zhangmeiren:addSkill(zcyuanzhuo)

zc_wangmeiren = sgs.General(sxfy_zhencang, "zc_wangmeiren", "wu", 3, false)
zcbizunVS = sgs.CreateViewAsSkillV2 {
	name = "zcbizun",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player or player:getMark("zcbizunBan-Clear") > 0 or not player:hasTurn() then return false end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return dummyCard():isAvailable(player)
		end
		local pattern = request:getPattern()
		return string.find(pattern, "slash") or string.find(pattern, "jink")
	end,
	can_select_card = function(skill, request, candidate)
		return candidate:isKindOf("EquipCard")
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local pattern = request:getPattern()
		if pattern == "" then
			pattern = "slash"
		end
		for _, p in sgs.list(pattern:split("+")) do
			if p == "jink" or p == "slash" then
				local sc = sgs.Sanguosha:cloneCard(p)
				sc:setSkillName(skill:objectName())
				for _, id in sgs.qlist(request:getSelectedCardIds()) do
					sc:addSubcard(id)
				end
				return sc
			end
		end
	end,
}
zcbizun = sgs.CreateTriggerSkillV2 {
	name = "zcbizun",
	events = { sgs.PreCardUsed, sgs.CardFinished },
	view_as_skill = zcbizunVS,
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player) then return end
		if event == PreCardUsed then
			local use = ctx.original_data:toCardUse()
			if table.contains(use.card:getSkillNames(), skill:objectName()) then
				room:addPlayerMark(player, "zcbizunBan-Clear")
			end
		else
			local use = ctx.original_data:toCardUse()
			if table.contains(use.card:getSkillNames(), skill:objectName()) and kesxV2RecordOnce(room, skill, ctx) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					local has = true
					for _, q in sgs.qlist(room:getOtherPlayers(p)) do
						if q:getHandcardNum() >= p:getHandcardNum() then
							has = false
						end
					end
					if has then
						if room:canMoveField("ej") then
							room:moveField(p, skill:objectName(), true, "ej")
						end
						break
					end
				end
			end
		end
	end,
}
zc_wangmeiren:addSkill(zcbizun)
zcqiangong = sgs.CreateTriggerSkillV2 {
	name = "zcqiangong",
	events = { sgs.CardsMoveOneTime },
	frequency = sgs.Skill_Compulsory,
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player == ctx.owner and event == sgs.CardsMoveOneTime) then return end
		local move = ctx.original_data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceDelayedTrick) or move.from_places:contains(sgs.Player_PlaceEquip) then
			if move.from:objectName() == player:objectName() and player:getCards("ej"):length() < 1 then
				room:sendCompulsoryTriggerLog(player, skill)
				player:drawCards(1, skill:objectName())
			end
		end
	end,
}
zc_wangmeiren:addSkill(zcqiangong)

zc_maohuanghou = sgs.General(sxfy_zhencang, "zc_maohuanghou", "wei", 3, false)
zcdechong = sgs.CreateTriggerSkillV2 {
	name = "zcdechong",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player and player:isAlive() then
			local skills = {}
			local owners = {}
			if player:getPhase() == sgs.Player_Start then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getCardCount() > 0 and p:hasSkill(skill) then
						table.insert(skills, skill:objectName())
						table.insert(owners, p:objectName())
					end
				end
			elseif player:getPhase() == sgs.Player_Discard then
				if player:getHandcardNum() >= player:getHp() then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if player:getMark("&zcdechong+#" .. p:objectName() .. "-Clear") > 0 then
							table.insert(skills, skill:objectName())
							table.insert(owners, p:objectName())
						end
					end
				end
			end
			if #skills > 0 then
				return table.concat(skills, "|"), table.concat(owners, "|")
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if ctx.invoker:getPhase() == sgs.Player_Start then
			local dc = room:askForExchange(player, skill:objectName(), 99, 1, true, "zcdechong0:" .. ctx.invoker:objectName(), true)
			if dc then
				ctx.extra_data = ToData(table.concat(sgs.QList2Table(dc:getSubcards()), ","))
				return true
			end
			return false
		end
		return player:askForSkillInvoke(skill, ctx.invoker, false)
	end,
	on_effect = function(skill, event, room, player, ctx)
		if ctx.invoker:getPhase() == sgs.Player_Start then
			local dc = dummyCard()
			for _, id in sgs.list(ctx.extra_data:toString():split(",")) do
				dc:addSubcard(tonumber(id))
			end
			player:skillInvoked(skill, -1)
			room:giveCard(player, ctx.invoker, dc, skill:objectName())
			room:setPlayerMark(ctx.invoker, "&zcdechong+#" .. player:objectName() .. "-Clear", 1)
		else
			room:damage(sgs.DamageStruct(skill:objectName(), player, ctx.invoker))
		end
		return false
	end,
}
zc_maohuanghou:addSkill(zcdechong)
zcyinzu = sgs.CreateAttackRangeSkillV2 {
	name = "zcyinzu",
	holder_selector = sgs.CorrectSkill_AllHolders,
	correct_func = function(skill, ctx)
		local target = ctx:getPrimary()
		if not target then return false end
		if target:getHandcardNum() > target:getHp() then
			return 1
		end
		return -1
	end,
}
zc_maohuanghou:addSkill(zcyinzu)

zc_caoxiong = sgs.General(sxfy_zhencang, "zc_caoxiong", "wei", 3)
zcwuweiCard = sgs.CreateSkillCard {
	name = "zcwuweiCard",
	target_fixed = false,
	filter = function(self, targets, to_select, source)
		local sc = sgs.Sanguosha:getCard(self:getEffectiveId())
		return #targets < 1 and not source:isProhibited(to_select, sc)
	end,
	on_use = function(self, room, player, targets)
		for _, p in sgs.list(targets) do
			local n = p:getAttackRange()
			InstallEquip(self:getEffectiveId(), player, "zcwuwei", p)
			n = p:getAttackRange() - n
			if n > 0 and player:canDiscard(p, "he") then
				local ids = sgs.IntList()
				for i = 1, n do
					local id = room:askForCardChosen(player, p, "he", "zcwuwei", false, sgs.Card_MethodDiscard, ids)
					if id < 0 then
						break
					end
					ids:append(id)
					if ids:length() >= p:getCardCount() then
						break
					end
				end
				room:throwCard(ids, "zcwuwei", p, player)
			end
		end
	end,
}
zcwuweiVS = sgs.CreateViewAsSkillV2 {
	name = "zcwuwei",
	n = 1,
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@zcwuwei"
	end,
	can_select_card = function(skill, request, candidate)
		return candidate:isKindOf("EquipCard")
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local sc = zcwuweiCard:clone()
		sc:addSubcard(request:getSelectedCardIds():first())
		return sc
	end,
}
zcwuwei = sgs.CreateTriggerSkillV2 {
	name = "zcwuwei",
	events = { sgs.Damaged },
	view_as_skill = zcwuweiVS,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Damaged and player:getCardCount() > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:askForUseCard(player, "@@zcwuwei", "zcwuwei0")
		return false
	end,
}
zc_caoxiong:addSkill(zcwuwei)
zcleiruo = sgs.CreateTriggerSkillV2 {
	name = "zcleiruo",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			for i, p in sgs.list(room:getOtherPlayers(player)) do
				if p:hasEquip() then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local tps = sgs.SPlayerList()
		for i, p in sgs.list(room:getOtherPlayers(player)) do
			if p:hasEquip() then
				tps:append(p)
			end
		end
		local tp = room:askForPlayerChosen(player, tps, skill:objectName(), "zcleiruo0", true, true)
		if tp then
			ctx.targets:append(tp)
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local tp = ctx.targets:first()
		local id = room:askForCardChosen(player, tp, "e", skill:objectName())
		room:obtainCard(player, id)
		local dc = dummyCard(nil, "_zcleiruo")
		if tp:isAlive() and tp:canSlash(player, dc, false) and tp:askForSkillInvoke(skill, player, false) then
			room:useCard(sgs.CardUseStruct(dc, tp, player))
		end
		return false
	end,
}
zc_caoxiong:addSkill(zcleiruo)

zc_huangchong = sgs.General(sxfy_zhencang, "zc_huangchong", "shu", 3)
zcjuxian = sgs.CreateTriggerSkillV2 {
	name = "zcjuxian",
	events = { sgs.BeforeCardsMove },
	frequency = sgs.Skill_Compulsory,
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player == ctx.owner and event == sgs.BeforeCardsMove) then return end
		local move = ctx.original_data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
			if move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip then
				if move.from:objectName() == player:objectName() and move.from ~= move.to then
					room:sendCompulsoryTriggerLog(player, skill)
					move:removeCardIds(move.card_ids)
					ctx.original_data:setValue(move)
				end
			end
		end
	end,
}
zc_huangchong:addSkill(zcjuxian)
zclijun = sgs.CreateTriggerSkillV2 {
	name = "zclijun",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local tps = sgs.SPlayerList()
		for i, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getHandcardNum() > 0 then
				tps:append(p)
			end
		end
		tps = room:askForPlayersChosen(player, tps, skill:objectName(), 0, player:getHp(), "zcleiruo0:" .. player:getHp(), true, true)
		if tps:length() > 0 then
			for _, p in sgs.qlist(tps) do
				ctx.targets:append(p)
			end
			return true
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local p2id = {}
		for i, p in sgs.qlist(ctx.targets) do
			local id = room:askForCardChosen(player, p, "h", skill:objectName())
			p2id[p:objectName()] = id
			room:showCard(p, id)
		end
		for i, p in sgs.qlist(ctx.targets) do
			local c = sgs.Sanguosha:getCard(p2id[p:objectName()])
			if p:hasCard(c) then
				if c:isAvailable(p) and room:askForUseCard(p, c:toString(), "zclijun1:" .. c:objectName()) then
				else
					room:throwCard(c, skill:objectName(), p)
				end
			end
		end
		return false
	end,
}
zc_huangchong:addSkill(zclijun)

zc_panglin = sgs.General(sxfy_zhencang, "zc_panglin", "shu", 3)
zczhuying = sgs.CreateTriggerSkillV2 {
	name = "zczhuying",
	events = { sgs.DamageInflicted },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.DamageInflicted and player and player:isAlive() then
			local damage = data:toDamage()
			if damage.nature == sgs.DamageStruct_Normal and not damage.to:isChained() then
				local skills = {}
				local owners = {}
				for i, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasSkill(skill) then
						table.insert(skills, skill:objectName())
						table.insert(owners, p:objectName())
					end
				end
				if #skills > 0 then
					return table.concat(skills, "|"), table.concat(owners, "|")
				end
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if damage.to:isChained() then return false end
		return player:askForSkillInvoke(skill, damage.to)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:setPlayerChained(ctx.original_data:toDamage().to)
		return false
	end,
}
zc_panglin:addSkill(zczhuying)
zczhongshi = sgs.CreateTriggerSkillV2 {
	name = "zczhongshi",
	events = { sgs.DamageCaused },
	frequency = sgs.Skill_Compulsory,
	on_record = function(skill, event, room, player, ctx)
		if not (ctx.owner and player and player == ctx.owner and event == sgs.DamageCaused) then return end
		local damage = ctx.original_data:toDamage()
		if damage.to:isChained() ~= player:isChained() then
			room:sendCompulsoryTriggerLog(player, skill)
			player:damageRevises(ctx.original_data, 1)
		end
	end,
}
zc_panglin:addSkill(zczhongshi)

sgs.LoadTranslationTable {

	["sxfy_zhencang"] = "珍藏封印",

	["zc_panglin"] = "庞林[珍藏]",
	["#zc_panglin"] = "随军御敌",
	["illustrator:zc_panglin"] = "绘绘子酱",

	["zczhuying"] = "驻营",
	[":zczhuying"] = "其他角色受到普通伤害时，若其未横置，你可以令其横置。",
	["zczhongshi"] = "忠事",
	[":zczhongshi"] = "锁定技，你对与你横置状态不同的角色造成伤害时，此伤害+1。",

	["zc_huangchong"] = "黄崇[珍藏]",
	["#zc_huangchong"] = "星陨绵竹",
	["illustrator:zc_huangchong"] = "绘绘子酱",

	["zcjuxian"] = "据险",
	[":zcjuxian"] = "锁定技，其他角色获得你的牌时，防止之。",
	["zclijun"] = "励军",
	[":zclijun"] = "准备阶段，你可以展示至多X名角色各一张手牌（X为你的体力值），这些角色依次选择一项：1.使用之；2.弃置之。",
	["zclijun0"] = "你可以发动“励军”展示至多%src名角色各一张手牌",

	["zc_caoxiong"] = "曹熊[珍藏]",
	["#zc_caoxiong"] = "萧怀侯",
	["illustrator:zc_caoxiong"] = "绘绘子酱",

	["zcwuwei"] = "无为",
	[":zcwuwei"] = "当你受到伤害后，你可以将一张装备牌置入一名角色装备区，然后弃置其X张牌（X为其因此增加的攻击范围）。",
	["zcleiruo"] = "羸弱",
	[":zcleiruo"] = "结束阶段，你可以获得一名其他角色装备区的一张牌，然后该角色可以视为对你使用一张【杀】。",
	["zcwuwei0"] = "你可以发动“无为”将一张装备牌置入一名角色装备区",
	["zcleiruo0"] = "你可以发动“羸弱”获得一名其他角色装备区的一张牌",

	["zc_maohuanghou"] = "毛皇后[珍藏]",
	["#zc_maohuanghou"] = "明悼皇后",
	["illustrator:zc_maohuanghou"] = "绘绘子酱",

	["zcdechong"] = "得宠",
	[":zcdechong"] = "其他角色的准备阶段，你可以交给其至少一张牌，然后其弃牌阶段开始时，若其手牌数大于等于体力值，你可以对其造成1点伤害。",
	["zcyinzu"] = "荫族",
	[":zcyinzu"] = "锁定技，所有手牌数大于体力值的角色攻击范围+1；所有手牌数小于等于体力值的角色攻击范围-1。",
	["zcdechong0"] = "你可以发动“得宠”交给%src至少一张牌",

	["zc_wangmeiren"] = "王美人[珍藏]",
	["#zc_wangmeiren"] = "敬怀皇后",
	["illustrator:zc_wangmeiren"] = "绘绘子酱",

	["zcbizun"] = "避尊",
	[":zcbizun"] = "每回合限一次，你可将一张装备牌当做【杀】或【闪】使用，然后手牌唯一最多的角色可以移动场上一张牌。",
	["zcqiangong"] = "迁宫",
	[":zcqiangong"] = "锁定技，当你失去场上最后一张牌后，你摸一张牌。",

	["zc_zhangmeiren"] = "张美人[珍藏]",
	["#zc_zhangmeiren"] = "琼楼孤蒂",
	["illustrator:zc_zhangmeiren"] = "绘绘子酱",

	["zclianrong"] = "怜容",
	[":zclianrong"] = "当其他角色的♥牌因弃置而置入弃牌堆后，你可以获得之。",
	["zcyuanzhuo"] = "怨灼",
	[":zcyuanzhuo"] = "出牌阶段限一次，你可以弃置一名其他角色一张牌，然后其视为对你使用一张【火攻】。",
	["zclianrong0"] = "怜容：请选择获得的牌",

	["_zc_baipishuangbi"] = "百辟双匕",
	[":_zc_baipishuangbi"] = "装备牌/武器<br/><b>攻击范围</b>：1<br/><b>武器技能</b>：锁定技，你使用【杀】指定与你性别不同的一个目标后，若你没有手牌，此【杀】对其伤害+1。",

	["zc_jiangjie"] = "姜婕[珍藏]",
	["#zc_jiangjie"] = "率然藏艳",
	["illustrator:zc_jiangjie"] = "绘绘子酱",

	["zcfengzhan"] = "锋展",
	[":zcfengzhan"] = "锁定技，游戏开始时，你获得【百辟双匕】。",
	["zcruixi"] = "锐袭",
	[":zcruixi"] = "一名角色结束阶段，若你本回合失去过牌，你可以将一张牌当无距离限制的【杀】使用。",
	["zcruixi0"] = "你可以发动“锐袭”将一张牌当无距离限制的【杀】使用",

	["_zc_xuanhuafu"] = "宣花斧",
	[":_zc_xuanhuafu"] = "装备牌/武器<br/><b>攻击范围</b>：3<br/><b>武器技能</b>：锁定技，你使用【杀】指定目标时，你额外指定一个目标距离1的另一名其他角色为目标。",

	["zc_zhengcong"] = "郑聪[珍藏]",
	["#zc_zhengcong"] = "莽绽凶蛇",
	["illustrator:zc_zhengcong"] = "绘绘子酱",

	["zcqiyue"] = "起钺",
	[":zcqiyue"] = "锁定技，游戏开始时，你获得【宣花斧】。",
	["zcjieji"] = "劫击",
	[":zcjieji"] = "当你每回合使用首张【杀】对其他角色造成伤害后，你可以获得其一张牌，然后其视为对你使用一张【杀】。",
}

return { kearmsxfyli, kearmsxfyzhen, sxfygen, sxfykun, sxfyxun, sxfykan, sxfyqian, sxfydui, sxfy_qinglong, sxfy_baihu, sxfy_zhuque, sxfy_xuanwu, sxfy_zhencang }
