--==《新武将》==--
extension_li = sgs.Package("kearmsxfyli", sgs.Package_GeneralPack)
extension_zhen = sgs.Package("kearmsxfyzhen", sgs.Package_GeneralPack)

--buff集中
kearmsxfyslashmore = sgs.CreateTargetModSkill{
	name = "kearmsxfyslashmore",
	pattern = ".",
	residue_func = function(self, from, card, to)
		local n = 0
		--[[if table.contains(card:getSkillNames(), "kelqjuesui") and from:hasSkill("kelqjuesuiUse") then
			n = n + 999
		end]]
		return n
	end,
	extra_target_func = function(self, from, card)
		local n = 0
		--[[if from:hasSkill("kesxhuiji")
		and card:isKindOf("Slash") then
			n = n + 999
		end]]
		return n
	end,
	distance_limit_func = function(self, from, card, to)
		if card:isKindOf("Slash") and table.contains(card:getSkillNames(), "zcruixi") then
			return 999
		end
		local n = 0
		return n
	end
}

sgs.LoadTranslationTable{
    ["kearmsxfyli"] = "四象封印·少阴·离",
	["kearmsxfyzhen"] = "四象封印·少阴·震",
	["sxfy_gen"] = "四象封印·太阴·艮",
	["sxfy_kun"] = "四象封印·太阴·坤",
	["sxfy_xun"] = "四象封印·少阳·巽",
	["sxfy_kan"] = "四象封印·少阳·坎",
	["sxfy_dui"] = "四象封印·太阳·兑",
	["sxfy_qian"] = "四象封印·太阳·乾",
}

kesxdengzhi = sgs.General(extension_li, "kesxdengzhi", "shu", 3)

kesxjimeng = sgs.CreateTriggerSkill{
	name = "kesxjimeng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) 
		and (player:getCardCount() > 0)
		and (player:getPhase() == sgs.Player_Start) then
			local ids = player:handCards()
			for _, id in sgs.qlist(player:getEquipsId()) do
				ids:append(id)
			end
			local fri = room:askForYiji(player,ids,self:objectName(),false,false,true,-1,sgs.SPlayerList(),sgs.CardMoveReason(),"kesxjimeng_ask",true)
			if fri and fri:getCardCount()>0 and player:isAlive() then
				ids = fri:handCards()
				for _, id in sgs.qlist(fri:getEquipsId()) do
					ids:append(id)
				end
				local tos = sgs.SPlayerList()
				tos:append(player)
				room:askForYiji(fri,ids,self:objectName(),false,false,false,-1,tos,sgs.CardMoveReason(),"kesxjimeng_choose:"..player:objectName())
			end
		end	
	end,
	--[[can_trigger = function(self, player)
		return true
	end]]
}
kesxdengzhi:addSkill(kesxjimeng)

kesxhehe = sgs.CreateTriggerSkill{
	name = "kesxhehe",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseEnd) and (player:getPhase() == sgs.Player_Draw) then
			local players = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if (p:getHandcardNum() == player:getHandcardNum()) then
					players:append(p)
				end
			end
			local fris = room:askForPlayersChosen(player, players, self:objectName(), 0, 2, "kesxhehe-ask", true, true)
			if fris:length() > 0 then
			    for _, q in sgs.qlist(fris) do
					q:drawCards(1,self:objectName())
				end
			end
		end	
	end,
	--[[can_trigger = function(self, player)
		return true
	end]]
}
kesxdengzhi:addSkill(kesxhehe)


sgs.LoadTranslationTable{

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

kesxwenyang = sgs.General(extension_li, "kesxwenyang", "wei", 4)

kesxquedi = sgs.CreateOneCardViewAsSkill{
	name = "kesxquedi",
	response_or_use = true,
	view_filter = function(self, card)
		if not card:isKindOf("Slash") then return false end
		local juedou = sgs.Sanguosha:cloneCard("duel")
		juedou:addSubcard(card:getEffectiveId())
		juedou:setSkillName("kesxquedi")
		juedou:deleteLater()
		return juedou:isAvailable(sgs.Self)
	end,
	view_as = function(self, card)
		local juedou = sgs.Sanguosha:cloneCard("duel")
		juedou:addSubcard(card:getId())
		juedou:setSkillName("kesxquedi")
		return juedou
	end,
	enabled_at_play = function(self, player)
		local juedou = sgs.Sanguosha:cloneCard("duel")
		juedou:setSkillName("kesxquedi")
		juedou:deleteLater()
		return juedou:isAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern:contains("duel")
		and sgs.Sanguosha:getCurrentCardUseReason()~=sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
	end
}
kesxwenyang:addSkill(kesxquedi)

sgs.LoadTranslationTable{

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

kesxchengpu = sgs.General(extension_li, "kesxchengpu", "wu", 4)

kesxchunlao = sgs.CreateTriggerSkill{
    name = "kesxchunlao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd,sgs.CardsMoveOneTime},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.from and player:objectName() == move.from:objectName()
			and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD
			and (player:getPhase() == sgs.Player_Discard) then
				local tag = player:getTag("kesxchunlaoToGet"):toIntList()
				for _,card_id in sgs.qlist(move.card_ids) do
					tag:append(card_id)
				end
				local d = sgs.QVariant()
				d:setValue(tag)
				player:setTag("kesxchunlaoToGet", d)
			end
		end
		if (event == sgs.EventPhaseEnd) then
			if (player:getPhase() == sgs.Player_Discard) then
				local tag = player:getTag("kesxchunlaoToGet"):toIntList()
				if (tag:length() >= 2 and player:hasSkill(self)) then
					local eny = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "kesxchunlao-ask",true,true)
					if eny then
						room:broadcastSkillInvoke(self:objectName())
						local dummy = sgs.Sanguosha:cloneCard("slash")
						dummy:addSubcards(eny:handCards())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, eny:objectName(), self:objectName(), "")
						room:moveCardTo(dummy, nil, sgs.Player_DiscardPile, reason)
						dummy:deleteLater()
						dummy = sgs.Sanguosha:cloneCard("slash")
						for _,id in sgs.qlist(tag) do
							if room:getCardPlace(id)==sgs.Player_DiscardPile
							then dummy:addSubcard(id) end
						end
						eny:obtainCard(dummy)
						dummy:deleteLater()
						if eny:askForSkillInvoke(self:objectName(), ToData("kesxchunlao0:"..player:objectName()), false) then
							room:recover(player, sgs.RecoverStruct())
						end
					end
				end
				player:removeTag("kesxchunlaoToGet")
			end
		end
	end
}
kesxchengpu:addSkill(kesxchunlao)

sgs.LoadTranslationTable{

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

kesxlijue = sgs.General(extension_li, "kesxlijue", "qun", 5)

kesxxiongsuan = sgs.CreateTriggerSkill{
    name = "kesxxiongsuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Start) then
			for _, p in sgs.qlist(room:getAllPlayers()) do 
				if (p:getHp() > player:getHp()) then
					return
				end
			end
			local players = sgs.SPlayerList()
			for _, q in sgs.qlist(room:getAllPlayers()) do 
				if q:getHp() == player:getHp() then
					players:append(q)
				end
			end
			room:sendCompulsoryTriggerLog(player, self)
			local fris = room:askForPlayersChosen(player, players, self:objectName(), 1, 99, "kesxxiongsuan-ask", true, true)
			for _, q in sgs.qlist(fris) do 
				room:damage(sgs.DamageStruct(self:objectName(), player, q))
			end
		end
	end
}
kesxlijue:addSkill(kesxxiongsuan)

sgs.LoadTranslationTable{

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

kesxfeiyi = sgs.General(extension_li, "kesxfeiyi", "shu", 3)

kesxtiaoheCard = sgs.CreateSkillCard{
	name = "kesxtiaoheCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if #targets == 0 then
			return to_select:getWeapon()~=nil
		end
		if #targets == 1 then
			return to_select:getArmor()~=nil
		end
		return #targets < 2
	end,
	feasible = function(self, targets)
		return #targets == 2
	end ,
	about_to_use = function(self,room,use)
		room:setTag("kesxtiaoheUse",ToData(use))
		self:cardOnUse(room,use)
	end,
	on_use = function(self, room, player, targets)
		local use = room:getTag("kesxtiaoheUse"):toCardUse()
		local w = use.to:first():getWeapon()
		if w and player:canDiscard(use.to:first(),w:getEffectiveId()) then
			room:throwCard(w, self:getSkillName(), use.to:first(), player)
		end
		local a = use.to:last():getArmor()
		if a and player:canDiscard(use.to:last(),a:getEffectiveId()) then
			room:throwCard(a, self:getSkillName(), use.to:last(), player)
		end
	end
}

kesxtiaohe = sgs.CreateViewAsSkill{
	name = "kesxtiaohe",
	n = 0 ,
	view_filter = function(self, selected, to_select)
		return false
	end ,
	view_as = function(self, cards)
		return kesxtiaoheCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kesxtiaoheCard") 
	end
}
kesxfeiyi:addSkill(kesxtiaohe)

kesxqiansu = sgs.CreateTriggerSkill{
	name = "kesxqiansu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("TrickCard") and use.to:contains(player) and (player:getEquipsId():length() == 0) then
				if room:askForSkillInvoke(player, self:objectName(), data) then 
					player:drawCards(1,self:objectName())
				end
			end
		end
	end,
}
kesxfeiyi:addSkill(kesxqiansu)

sgs.LoadTranslationTable{

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

kesxfanyufeng = sgs.General(extension_li, "kesxfanyufeng", "qun", 3,false)

kesxbazhanCard = sgs.CreateSkillCard{
	name = "kesxbazhanCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return (#targets < 1) and to_select:isMale()
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:showCard(player,self:getSubcards():first())
		room:giveCard(player,target,self,self:getSkillName(),true)
		local cc = sgs.Sanguosha:getCard(self:getSubcards():first())
		local xxx = room:askForExchange(target, "kesxbazhan", 1, 1, false, "kesxbazhan-choose:"..player:objectName(), true, "^"..cc:getType()) 
		if xxx then
			room:showCard(target,xxx:getSubcards():first())
			room:giveCard(target,player,xxx,self:getSkillName(),true)
		end
	end
}

kesxbazhan = sgs.CreateViewAsSkill{
	name = "kesxbazhan",
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end ,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = kesxbazhanCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end ,
	enabled_at_play = function(self, player)
		return player:usedTimes("#kesxbazhanCard") < 2
	end
}
kesxfanyufeng:addSkill(kesxbazhan)

kesxqiaoyingex = sgs.CreateCardLimitSkill{
	name = "#kesxqiaoyingex",
	limit_list = function(self, player)
		return "use"
	end,
	limit_pattern = function(self, player)
		if (player:getMark("&kesxqiaoying-Clear") < player:getHandcardNum())
		and (player:getMark("kesxqiaoyingeffect-Clear") > 0) then
			return ".|red|.|hand"
		end
		return ""
	end
}
kesxfanyufeng:addSkill(kesxqiaoyingex)

kesxqiaoying = sgs.CreateTriggerSkill{
	name = "kesxqiaoying",
	events = {sgs.EventPhaseStart,sgs.DamageInflicted},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			if room:getCurrent():hasSkill("kesxqiaoying") 
			and (damage.to:getHandcardNum() > damage.to:getMark("&kesxqiaoying-Clear")) then
				room:sendCompulsoryTriggerLog(room:getCurrent(),self)
				damage.damage = 1 + damage.damage
				data:setValue(damage)
			end
		end
		if (event == sgs.EventPhaseStart) and player:hasSkill(self:objectName())
		and (player:getPhase() == sgs.Player_RoundStart) then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				room:setPlayerMark(p,"&kesxqiaoying-Clear",p:getHandcardNum())
				room:setPlayerMark(p,"kesxqiaoyingeffect-Clear",1)
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
kesxfanyufeng:addSkill(kesxqiaoying)
extension_li:insertRelatedSkills("kesxqiaoying", "#kesxqiaoyingex")

sgs.LoadTranslationTable{

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

kesxchengyu = sgs.General(extension_li, "kesxchengyu", "wei", 3,true)

kesxchengyu:addSkill("shefu")

kesxyibing = sgs.CreateTriggerSkill{
	name = "kesxyibing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Dying) then
			local dying_data = data:toDying()
			local source = dying_data.who
			if source~=player and source:getCardCount()>0
			and player:askForSkillInvoke(self, source) then
				room:broadcastSkillInvoke(self:objectName())
				local card_id = room:askForCardChosen(player, source, "he", self:objectName())
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
				room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
			end
		end
	end,
}
kesxchengyu:addSkill(kesxyibing)

sgs.LoadTranslationTable{

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

kesxzhangyi = sgs.General(extension_li, "kesxzhangyi", "shu", 4,true)

kesxzhiyiVS = sgs.CreateViewAsSkill{
	name = "kesxzhiyi" ,
	n = 0 ,
	view_filter = function(self, selected, to_select)
		return false
	end ,
	view_as = function(self, cards)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("_kesxzhiyi")
		return slash
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return pattern=="@@kesxzhiyi"
	end
}
kesxzhiyi = sgs.CreateTriggerSkill{
	name = "kesxzhiyi" ,
	events = {sgs.EventPhaseChanging,sgs.CardUsed} ,
	view_as_skill = kesxzhiyiVS ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				room:setPlayerMark(player,"&kesxzhiyi-Clear",1)
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) and (player:getMark("&kesxzhiyi-Clear") > 0) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				if sgs.Slash_IsAvailable(player)
				and room:askForUseCard(player, "@@kesxzhiyi", "kesxzhiyi-ask", 1)
				then return end
				player:drawCards(1,self:objectName())
			end
		end
	end
}
kesxzhangyi:addSkill(kesxzhiyi)

sgs.LoadTranslationTable{

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

kesxjianggan = sgs.General(extension_zhen, "kesxjianggan", "wei", 3, true)

kesxdaoshu = sgs.CreateTriggerSkill{
	name = "kesxdaoshu",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				for _, jg in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if jg:isAlive() and jg:getMark("&usekesxdaoshu_lun")<1 then
						local canchooses = sgs.SPlayerList()
						for _, p in sgs.qlist(room:getOtherPlayers(player)) do
							if not p:isKongcheng() then
								canchooses:append(p)
							end
						end
						local target = room:askForPlayerChosen(jg, canchooses, self:objectName(), "kesxdaoshu-ask", true, true)
						if target then
							room:broadcastSkillInvoke(self:objectName())
							room:setPlayerMark(jg,"&usekesxdaoshu_lun",1)
							local card_id = room:askForCardChosen(jg, target, "h", self:objectName())
							room:showCard(target,card_id)
							local thecard = sgs.Sanguosha:getCard(card_id)
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, jg:objectName())
							room:obtainCard(player, thecard, reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
							room:setPlayerMark(player, "&kesxdaoshu+:+"..thecard:getSuitString().."+-Clear",1)
							room:setPlayerMark(jg, "&kesxdaoshu+:+"..thecard:getSuitString().."+-Clear",1)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
}
kesxjianggan:addSkill(kesxdaoshu)

kesxdaoshuex = sgs.CreateCardLimitSkill{
	name = "#kesxdaoshuex",
	limit_list = function(self, player, card)
		return "use"
	end,
	limit_pattern = function(self, player, card)
		if (player:getMark("&kesxdaoshu+:+"..card:getSuitString().."+-Clear") > 0) then
			return ".|.|.|hand"
		end
		return ""
	end
}
kesxjianggan:addSkill(kesxdaoshuex)
--extension_zhen:insertRelatedSkills("kesxdaoshu", "#kesxdaoshuex")

kesxdaizui = sgs.CreateTriggerSkill{
	name = "kesxdaizui",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Frequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damaged) then
			if player:getMark("&usekesxdaoshu_lun") > 0 then
				room:sendCompulsoryTriggerLog(player,self)
				room:setPlayerMark(player,"&usekesxdaoshu_lun", 0)
			end
		end
	end
}
kesxjianggan:addSkill(kesxdaizui)

sgs.LoadTranslationTable{

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

kesxmayunlu = sgs.General(extension_zhen, "kesxmayunlu", "shu", 4, false)

kesxfenghun = sgs.CreateTriggerSkill{
	name = "kesxfenghun",
	events = {sgs.DamageCaused},
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") then
				local use = room:getUseStruct(damage.card)
				if not use.to:contains(damage.to) then return end
				local tos = sgs.SPlayerList()
				if player:canDiscard(player, "he") then 
					tos:append(player)
				end
				if player:canDiscard(damage.to, "he") then
					tos:append(damage.to)
				end
				local to = room:askForPlayerChosen(player, tos, self:objectName(), "kesxfenghun-ask", true, true)
				if to then
					room:broadcastSkillInvoke(self:objectName())
					local to_throw = room:askForCardChosen(player, to, "he", self:objectName())
					local card = sgs.Sanguosha:getCard(to_throw)
					room:throwCard(card, to, player)
					if (card:getSuit() == sgs.Card_Diamond) then
						damage.damage = 1 + damage.damage
						data:setValue(damage)
					end
				end
			end
		end
	end
}
kesxmayunlu:addSkill(kesxfenghun)

kesxmayunlu:addSkill("mashu")

sgs.LoadTranslationTable{

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

kesxmateng = sgs.General(extension_zhen, "kesxmateng$", "qun", 4, true)

kesxxiongyiCard = sgs.CreateSkillCard{
	name = "kesxxiongyiCard",
	will_throw = false,
	filter = function(self, selected, to_select)
		return (#selected < 99)
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source,"@kesxxiongyi")
		room:doSuperLightbox(source,self:getSkillName())
		while #targets>0 do
			for _, p in ipairs(targets) do
				local cantargets = sgs.SPlayerList()
				for _, pp in sgs.qlist(room:getAllPlayers()) do
					if p:canSlash(pp,false) then cantargets:append(pp) end
				end
				if not room:askForUseSlashTo(p, cantargets,"kesxxiongyi-ask",true,false,false,nil,nil,"kesxxiongyiflag") then
					return
				end
			end
		end
	end,
}
kesxxiongyiVS = sgs.CreateZeroCardViewAsSkill{
	name = "kesxxiongyi",
	view_as = function(self, cards)
		return kesxxiongyiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@kesxxiongyi") >= 1
	end
}

kesxxiongyi = sgs.CreateTriggerSkill{
	name = "kesxxiongyi",
	view_as_skill = kesxxiongyiVS,
	events = {sgs.TargetConfirmed,sgs.TargetSpecified} ,
	frequency = sgs.Skill_Limited,
	limit_mark = "@kesxxiongyi",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TargetSpecified) then	
			local use = data:toCardUse()
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
				data:setValue(use)	
			end
		end
	end
}
kesxmateng:addSkill(kesxxiongyi)

kesxmateng:addSkill("mashu")
kesxyouqiCard = sgs.CreateSkillCard{
	name = "kesxyouqiCard",
	--target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if #targets<1 and to_select:getKingdom() == "qun" then
			return to_select:getOffensiveHorse()~=nil or to_select:getDefensiveHorse()~=nil
		elseif #targets==1 then
			return targets[1]:getOffensiveHorse() and not to_select:getOffensiveHorse() and to_select:hasOffensiveHorseArea()
			or targets[1]:getDefensiveHorse() and not to_select:getDefensiveHorse() and to_select:hasDefensiveHorseArea()
		end
	end,
	feasible = function(self,targets)
		return #targets==2
	end,
	about_to_use = function(self,room,use)
		room:setTag("kesxyouqiUse",ToData(use))
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,source,targets)
	   	local use = room:getTag("kesxyouqiUse"):toCardUse()
		local to1 = use.to:at(0)
	   	local to2 = use.to:at(1)
		local ids = sgs.IntList()
		for _,e in sgs.list(to1:getEquips())do
			if e:isKindOf("Horse") then
				local n = e:getRealCard():toEquipCard():location()
				if to2:hasEquipArea(n) and not to2:getEquip(n) then
					continue
				end
			end
			ids:append(e:getEffectiveId())
		end
		local id = room:askForCardChosen(source,to1,"e","kesxyouqi",false,sgs.Card_MethodNone,ids)
		if id>-1 and to2:isAlive() then
			room:moveCardTo(sgs.Sanguosha:getCard(id),to2,sgs.Player_PlaceEquip)
		end
	end
}

kesxyouqivs = sgs.CreateViewAsSkill{
	name = "kesxyouqi",
	n = 0;
	view_as = function(self, cards)
		return kesxyouqiCard:clone()
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern=="@@kesxyouqi"
	end,
	enabled_at_play = function(self, player)
		return false
	end
}

kesxyouqi = sgs.CreateTriggerSkill{
	name = "kesxyouqi$",
	events = {sgs.EventPhaseStart},
	view_as_skill = kesxyouqivs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and player:hasLordSkill(self:objectName())
		and (player:getPhase() == sgs.Player_Start) then
			local choosetargets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getKingdom() == "qun" and (p:getOffensiveHorse() or p:getDefensiveHorse()) then
				    --检查能否移到其他角色的区域内
					for _, pto in sgs.qlist(room:getOtherPlayers(p)) do
						if (p:getOffensiveHorse() and pto:hasOffensiveHorseArea() and not pto:getOffensiveHorse())
						or (p:getDefensiveHorse() and pto:hasDefensiveHorseArea() and not pto:getDefensiveHorse()) then
							room:askForUseCard(player, "@@kesxyouqi", "@kesxyouqi",-1,sgs.Card_MethodNone)
							return
						end
					end
				end
			end
		end
	end
}
kesxmateng:addSkill(kesxyouqi)

sgs.LoadTranslationTable{

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

kesxsunhao = sgs.General(extension_zhen, "kesxsunhao$", "wu", 5, true)

kesxcanshi = sgs.CreateTriggerSkill{
	name = "kesxcanshi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards,sgs.TargetSpecifying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			room:sendCompulsoryTriggerLog(player,self)
			local nnn = 0
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:isWounded() then
					nnn = nnn + 1
				end
			end
			draw.num = math.max(1,nnn)
			data:setValue(draw)
			room:setPlayerMark(player,"&kesxcanshi-Clear",1)
		elseif (event == sgs.TargetSpecifying) and (player:getMark("&kesxcanshi-Clear") > 0) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") or use.card:isNDTrick() then
				local tri = 0
				for _, p in sgs.qlist(use.to) do
					if p:isWounded() then
						tri = 1
						break
					end
				end
				if (tri == 1) and player:canDiscard(player, "he") then
					room:askForDiscard(player, self:objectName(), 1, 1, false, true, "kesxcanshi-ask") 
				end
			end
		end
	end,
}
kesxsunhao:addSkill(kesxcanshi)

kesxsunhao:addSkill("chouhai")
kesxsunhao:addSkill("guiming")

sgs.LoadTranslationTable{

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

kesxluotong = sgs.General(extension_zhen, "kesxluotong", "wu", 3, true)

kesxjinjian = sgs.CreateTriggerSkill{
	name = "kesxjinjian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused,sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			if (player:getMark("&kesxjinjianadd-Clear") > 0) then
				room:sendCompulsoryTriggerLog(player,self)
				damage.damage = 1 + damage.damage
				data:setValue(damage)
				room:setPlayerMark(player,"&kesxjinjianadd-Clear",0)
			elseif player:getMark("kesxjinjianhit-Clear") == 0 then
				if player:askForSkillInvoke(self:objectName(), ToData("kesxjinjian0:"..damage.to:objectName())) then
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerMark(player,"kesxjinjianhit-Clear",1)
					room:setPlayerMark(player,"&kesxjinjianadd-Clear",1)
					return true
				end
			end
		end
		if (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			if (player:getMark("&kesxjinjianmin-Clear") > 0) then
				room:sendCompulsoryTriggerLog(player,self)
				damage.damage = 1 + damage.damage
				data:setValue(damage)
				room:setPlayerMark(player,"&kesxjinjianmin-Clear",0)
			elseif (player:getMark("kesxjinjianbehit-Clear") == 0) then
				if player:askForSkillInvoke(self:objectName(), ToData("kesxjinjian1:"..damage.from:objectName())) then
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerMark(player,"kesxjinjianbehit-Clear",1)
					room:setPlayerMark(player,"&kesxjinjianmin-Clear",1)
					return true
				end
			end
		end
	end,
}
kesxluotong:addSkill(kesxjinjian)

kesxrenzheng = sgs.CreateTriggerSkill{
	name = "kesxrenzheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageComplete},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DamageComplete) then
			local damage = data:toDamage()
			if damage.prevented then
				for _, sh in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					room:sendCompulsoryTriggerLog(sh,self)
					room:getCurrent():drawCards(1,self:objectName())
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end
}
kesxluotong:addSkill(kesxrenzheng)

sgs.LoadTranslationTable{

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

kesxyanghu = sgs.General(extension_zhen, "kesxyanghu", "wei", 4, true)

kesxmingfaCard = sgs.CreateSkillCard{
	name = "kesxmingfaCard",
	filter = function(self, targets, to_select)
		return (#targets < 1) and (to_select:getHp() > 1)
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:damage(sgs.DamageStruct("kesxmingfa", player, target))
		room:setPlayerMark(player,"&usekesxmingfa",1)
		room:setPlayerMark(player,"usekesxmingfa"..target:objectName(),1)
		room:setPlayerMark(target,"&kesxmingfa",1)
	end
}
--主技能
kesxmingfaVS = sgs.CreateViewAsSkill{
	name = "kesxmingfa",
	n = 0,
	view_as = function(self, cards)
		return kesxmingfaCard:clone()
	end,
	enabled_at_play = function(self, player)
		return (player:getMark("&usekesxmingfa") == 0)
	end, 
}

kesxmingfa = sgs.CreateTriggerSkill{
	name = "kesxmingfa",
	view_as_skill = kesxmingfaVS,
	events = {sgs.Death,sgs.HpRecover},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.HpRecover) then
			local rec = data:toRecover()
			if (rec.who:getMark("&kesxmingfa") > 0) then
				room:setPlayerMark(rec.who,"&kesxmingfa",0)
				for _, yh in sgs.qlist(room:getAllPlayers()) do
					if yh:getMark("usekesxmingfa"..rec.who:objectName()) > 0 then
					    room:setPlayerMark(yh,"usekesxmingfa"..rec.who:objectName(),0)
					    room:setPlayerMark(yh,"&usekesxmingfa",0)
					end
				end
			end
		end
		if (event == sgs.Death) then
			local death = data:toDeath()
			if (death.who:getMark("&kesxmingfa") > 0) then
				room:setPlayerMark(death.who,"&kesxmingfa",0)
				for _, yh in sgs.qlist(room:getAllPlayers()) do
					if yh:getMark("usekesxmingfa"..death.who:objectName()) > 0 then
					    room:setPlayerMark(yh,"usekesxmingfa"..death.who:objectName(),0)
					    room:setPlayerMark(yh,"&usekesxmingfa",0)
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end
}
kesxyanghu:addSkill(kesxmingfa)

sgs.LoadTranslationTable{

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

kesxlvlingqi = sgs.General(extension_zhen, "kesxlvlingqi", "qun", 4, false)

kesxhuiji = sgs.CreateTriggerSkill{
	name = "kesxhuiji",
	events = {sgs.TargetSpecifying, sgs.CardAsked,sgs.CardFinished,sgs.CardEffected},
	frequency = sgs.Skill_Frequent, 
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		--清除
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:hasFlag("kesxhuijiflag") then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					room:setPlayerMark(p,"&kesxhuiji-Clear",0)
				end
			end
		end
		if (event == sgs.CardEffected) then
			local effect = data:toCardEffect()
			if effect.card:hasFlag("kesxhuijiflag") then
				player:setFlags("kesxhuijiAsked")
			end
		end
		if (event == sgs.CardAsked) and (player:hasFlag("kesxhuijiAsked")) then
			local pattern = data:toStringList()
			if pattern[1]~="jink" or pattern[2]=="kesxhuiji-help"
			or pattern[3]~="use" then return false end
			player:setFlags("-kesxhuijiAsked")
			local lieges = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("&kesxhuiji-Clear") > 0 then
					lieges:append(p)
				end
			end
			if lieges:length()<1 or not player:askForSkillInvoke(self,data,false) then return false end
			for _,fri in sgs.qlist(lieges)do
				local jink = room:askForUseCard(fri, "jink", "kesxhuiji-help", -1, sgs.Card_MethodUse, false, player)
				if jink then
					room:provide(jink)
					return true
				end
			end
			return false
		end
		--尿分叉
		if (event == sgs.TargetSpecifying) and player:hasSkill(self:objectName()) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				local extargets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if (not use.to:contains(p)) and player:canSlash(p, use.card, true) then 
						extargets:append(p)
					end
				end
				player:setTag("kesxhuijiUse",data)
				local enys = room:askForPlayersChosen(player, extargets, self:objectName(), 0, 2, "kesxhuiji-ask", true, false)
				if enys:length() > 0 then
					room:broadcastSkillInvoke(self:objectName())
					room:setCardFlag(use.card,"kesxhuijiflag")
					for _,q in sgs.qlist(enys) do
						use.to:append(q)
					end
					room:sortByActionOrder(use.to)
					data:setValue(use)
					for _,qq in sgs.qlist(use.to) do
						room:setPlayerMark(qq,"&kesxhuiji-Clear",1)
					end
				end
			end
		end
	end
}
kesxlvlingqi:addSkill(kesxhuiji)

sgs.LoadTranslationTable{

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


kesxzhouchu = sgs.General(extension_zhen, "kesxzhouchu", "wu", 4, true)

kesxxiongxiaCard = sgs.CreateSkillCard{
	name = "kesxxiongxiaCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:addSubcards(self:getSubcards())
		duel:setSkillName("kesxxiongxia")
		duel:deleteLater()
		return #targets < 2 and duel:targetFilter(sgs.PlayerList(),to_select,source)
	end,
	feasible = function(self, targets)
		return #targets == 2
	end ,
	about_to_use = function(self,room,use)
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:addSubcards(self:getSubcards())
		duel:setSkillName("kesxxiongxia")
		use.card = duel
		room:useCard(use, true)
		duel:deleteLater()
	end
}

kesxxiongxiaVS = sgs.CreateViewAsSkill{
	name = "kesxxiongxia",
	n = 2,
	view_filter = function(self, selected, to_select)
        return true
	end,
	view_as = function(self, cards)
		if #cards > 1 then
			local duel = sgs.Sanguosha:cloneCard("duel")
			for _,c in ipairs(cards) do
				duel:addSubcard(c)
			end
			duel:setSkillName("kesxxiongxia")
			duel:deleteLater()
			if sgs.Self:isLocked(duel) then return end
			local duel = kesxxiongxiaCard:clone()
			for _,c in ipairs(cards) do
				duel:addSubcard(c)
			end
			return duel
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("&bankesxxiongxia-Clear")<1
		and player:getCardCount()>1
	end, 
}

kesxxiongxia = sgs.CreateTriggerSkill{
	name = "kesxxiongxia",
	view_as_skill = kesxxiongxiaVS,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"kesxxiongxia") then
				for _, q in sgs.qlist(use.to) do
					if not use.card:hasFlag("DamageDone_"..q:objectName()) then
						return
					end
				end
				room:setPlayerMark(player,"&bankesxxiongxia-Clear",1)
			end
		end
	end,
}
kesxzhouchu:addSkill(kesxxiongxia)

sgs.LoadTranslationTable{

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



extension_gen = sgs.Package("sxfy_gen", sgs.Package_GeneralPack)

sx_guanxing = sgs.General(extension_gen, "sx_guanxing", "shu", 4)

sxwuyouCard = sgs.CreateSkillCard{
	name = "sxwuyouCard",
	filter = function(self, targets, to_select,source)
		return #targets<1 and to_select~=source and source:canPindian(to_select)
	end,
	on_use = function(self, room, player, targets)
		for _, p in sgs.list(targets) do
			if player:canPindian(p) then
				local n = player:pindianInt(p,self:getSkillName())
				local from,to = player,p
				if n<1 then
					room:acquireOneTurnSkills(player,self:getSkillName(),"wusheng")
					from,to = p,player
				end
				if n==0 then continue end
				local dc = dummyCard("duel")
				dc:setSkillName("_sxwuyou")
				if from:canUse(dc,to) then
					room:useCard(sgs.CardUseStruct(dc,from,to))
				end
			end
		end
	end
}
sxwuyou = sgs.CreateViewAsSkill{
	name = "sxwuyou",
	n = 0,
	view_as = function(self, cards)
		return sxwuyouCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#sxwuyouCard")<1 and player:canPindian()
	end, 
}
sx_guanxing:addSkill(sxwuyou)

sx_jiangwan = sgs.General(extension_gen, "sx_jiangwan", "shu", 3)

sxbeiwuVS = sgs.CreateViewAsSkill{
	name = "sxbeiwu",
	n = 1,
	view_filter = function(self, selected, to_select)
        return to_select:isEquipped() and sgs.Self:getMark(to_select:toString().."sxbeiwu-Clear")<1
	end,
	view_as = function(self, cards)
		local dc = sgs.Self:getTag("sxbeiwu"):toCard()
		if dc and #cards > 0 then
			dc = sgs.Sanguosha:cloneCard(dc:objectName())
			for _,c in ipairs(cards) do
				dc:addSubcard(c)
			end
			dc:setSkillName("sxbeiwu")
			return dc
		end
	end,
	enabled_at_play = function(self, player)
		return player:hasEquip()
	end, 
}
sxbeiwu = sgs.CreateTriggerSkill{
	name = "sxbeiwu",
	view_as_skill = sxbeiwuVS,
	events = {sgs.CardsMoveOneTime},
	juguan_type = "ex_nihilo,duel",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_PlaceEquip and move.to:objectName()==player:objectName() then
				for _,id in sgs.qlist(move.card_ids) do
					room:setPlayerMark(player,id.."sxbeiwu-Clear",1)
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:hasSkill(self:objectName(),true)
	end,
}
sx_jiangwan:addSkill(sxbeiwu)
sxchengshi = sgs.CreateTriggerSkill{
	name = "sxchengshi",
	events = {sgs.Death},
	frequency = sgs.Skill_Limited,
	limit_mark = "@sxchengshi";
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Death) and player:getMark("@sxchengshi")>0 then
			local death = data:toDeath()
			if player:askForSkillInvoke(self,death.who) then
				room:removePlayerMark(player,"@sxchengshi")
				player:peiyin("mobileyanjincui")
				room:doSuperLightbox(player,self:objectName())
				room:swapSeat(player,death.who)
				room:swapCards(player,death.who,"e",self:objectName())
			end
		end
	end,
}
sx_jiangwan:addSkill(sxchengshi)

sx_maliang = sgs.General(extension_gen, "sx_maliang", "shu", 3)

sxxiemuCard = sgs.CreateSkillCard{
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
				room:showCard(player,self:getEffectiveId())
				room:giveCard(player,p,self,self:getSkillName())
				room:addPlayerMark(player,"&sxxiemubf-Clear")
			end
		end
	end
}
sxxiemuvs = sgs.CreateViewAsSkill{
	name = "sxxiemuvs&",
	n = 1,
	view_filter = function(self, selected, to_select)
        return to_select:getTypeId()==1
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local dc = sxxiemuCard:clone()
			for _,c in ipairs(cards) do
				dc:addSubcard(c)
			end
			return dc
		end
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#sxxiemuCard")<1
	end, 
}
extension_gen:addSkills(sxxiemuvs)
sxxiemu = sgs.CreateTriggerSkill{
	name = "sxxiemu",
	events = {sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_Play) then
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasSkill(self:objectName(),true) then
						room:attachSkillToPlayer(player,"sxxiemuvs")
						break
					end
				end
			end
			if (change.from >= sgs.Player_Play) then
				if player:hasSkill("sxxiemuvs",true) then
					room:detachSkillFromPlayer(player,"sxxiemuvs",true)
				end
			end
		end
	end,
}
sx_maliang:addSkill(sxxiemu)
sxxiemubf = sgs.CreateAttackRangeSkill{
	name = "#sxxiemubf",
    extra_func = function(self,target)
		return target:getMark("&sxxiemubf-Clear")
	end,
}
sx_maliang:addSkill(sxxiemubf)
sxnamanCard = sgs.CreateSkillCard{
	name = "sxnamanCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, source)
		local dc = sgs.Sanguosha:cloneCard("savage_assault")
		dc:addSubcards(self:getSubcards())
		dc:setSkillName("sxnaman")
		dc:deleteLater()
		return source~=to_select and #targets<self:subcardsLength()
		and not source:isProhibited(to_select,dc)
	end,
	about_to_use = function(self,room,use)
		local dc = sgs.Sanguosha:cloneCard("savage_assault")
		dc:addSubcards(self:getSubcards())
		dc:setSkillName("sxnaman")
		use.card = dc
		self:cardOnUse(room,use)
		dc:deleteLater()
	end
}
sxnaman = sgs.CreateViewAsSkill{
	name = "sxnaman",
	n = 998,
	view_filter = function(self, selected, to_select)
        return to_select:getTypeId()==1 and #selected<sgs.Self:getAliveSiblings():length()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local sc = sxnamanCard:clone()
			for _,c in ipairs(cards) do
				sc:addSubcard(c)
			end
			return sc
		end
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#sxnamanCard")<1
	end, 
}
sx_maliang:addSkill(sxnaman)

sx_xushu = sgs.General(extension_gen,"sx_xushu","shu",3)
sxwuyan = sgs.CreateFilterSkill{
	name = "sxwuyan",
	view_filter = function(self,card)
		return card:isKindOf("TrickCard")
		and card:objectName()~="nullification"
	end,
	view_as = function(self,card)
		local ex = sgs.Sanguosha:cloneCard("nullification",card:getSuit(),card:getNumber())
    	ex:setSkillName("sxwuyan")
	    local wrap = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
	    wrap:takeOver(ex)
	    return wrap
	end
}
sx_xushu:addSkill(sxwuyan)
sxjujian = sgs.CreateTriggerSkill{
	name = "sxjujian",
	events = {sgs.CardFinished,sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:hasFlag("sxjujianbf") and player:getMark("sxjujian-Clear")<1
			and room:getCardPlace(use.card:getEffectiveId())==sgs.Player_DiscardPile then
				local to = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"sxjujian0:",true,true)
				if to then
					player:addMark("sxjujian-Clear")
					player:peiyin("jujian")
					room:giveCard(player,to,use.card,self:objectName())
				end
			end
		else
			local use = data:toCardUse()
			if use.card:isKindOf("Nullification") then
				room:setCardFlag(use.card,"sxjujianbf")
			end
		end
	end,
}
sx_xushu:addSkill(sxjujian)

sx_zhonghui = sgs.General(extension_gen,"sx_zhonghui","wei",4)
sxxingfa = sgs.CreateTriggerSkill{
	name = "sxxingfa",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()==sgs.Player_Start and player:getHandcardNum()>=player:getHp() then
				local to = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"sxxingfa0:",true,true)
				if to then
					player:peiyin("paiyi")
					room:damage(sgs.DamageStruct(self:objectName(),player,to))
				end
			end
		end
	end,
}
sx_zhonghui:addSkill(sxxingfa)

sx_wangyuanji = sgs.General(extension_gen,"sx_wangyuanji","wei",3,false)

sxqianchong = sgs.CreateTargetModSkill{
	name = "sxqianchong",
	pattern = ".",
	residue_func = function(self, from, card, to)
		if from:hasSkill("sxqianchong") and from:getEquips():length()%2==1 then
			return 1000
		end
		if from:getMark("&sxjuezhu-Clear")>0 then
			return 1000
		end
		return 0
	end,
	extra_target_func = function(self, from, card)
		local n = 0
		--[[if from:hasSkill("kesxhuiji")
		and card:isKindOf("Slash") then
			n = n + 1000
		end]]
		return n
	end,
	distance_limit_func = function(self, from, card, to)
		if from:hasSkill("sxqianchong") and from:getEquips():length()%2==0 then
			return 1000
		end
		return 0
	end
}
sx_wangyuanji:addSkill(sxqianchong)
sxshangjian = sgs.CreateTriggerSkill{
	name = "sxshangjian",
	events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime},
	can_trigger = function(self,target)
		return target and target:hasSkill(self:objectName(),true)
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()==sgs.Player_Finish and player:getMark("&sxshangjian-Clear")<=player:getHp() and player:hasSkill(self) then
				local ids = sgs.IntList()
				for i, id in sgs.qlist(room:getDiscardPile()) do
					if player:getMark(id.."sxshangjian-Clear")>0 then
						ids:append(id)
					end
				end
				if ids:length()>0 then
					room:fillAG(ids,player)
					if player:askForSkillInvoke(self,ToData(ids)) then
						player:peiyin("shangjian")
						local id = room:askForAG(player,ids,false,self:objectName())
						room:obtainCard(player,id)
					end
					room:clearAG(player)
				end
			end
		else
			local move = data:toMoveOneTime()
			if (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and move.from:objectName()==player:objectName() then
				for i, id in sgs.qlist(move.card_ids) do
					if move.from_places:at(i)==sgs.Player_PlaceHand
					or move.from_places:at(i)==sgs.Player_PlaceEquip then
						room:addPlayerMark(player,"&sxshangjian-Clear")
						player:addMark(id.."sxshangjian-Clear")
					end
				end
			end
		end
	end,
}
sx_wangyuanji:addSkill(sxshangjian)

sx_xuezong = sgs.General(extension_gen,"sx_xuezong","wu",3)
sxfunan = sgs.CreateTriggerSkill{
	name = "sxfunan",
	events = {sgs.CardOffset},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardOffset) then
			local effect = data:toCardEffect()
			if effect.card:getTypeId()>0 and effect.card:getEffectiveId()>-1
			and room:getCardOwner(effect.card:getEffectiveId())==nil then
				local use = room:getUseStruct(effect.offset_card)
				if use.from~=player and use.from:isAlive() and use.from:getMark("sxfunan-Clear")<1
				and use.from:hasSkill(self) and use.from:askForSkillInvoke(self,data) then
					use.from:addMark("sxfunan-Clear")
					use.from:peiyin("funan")
					use.from:obtainCard(effect.card)
				end
			end
		end
	end,
}
sx_xuezong:addSkill(sxfunan)
sxjiexun = sgs.CreateTriggerSkill{
	name = "sxjiexun",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()==sgs.Player_Finish then
				local tos = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:canDiscard(p,"h") then
						tos:append(p)
					end
				end
				local to = room:askForPlayerChosen(player,tos,self:objectName(),"sxjiexun0:",true,true)
				if to then
					player:peiyin("jiexun")
					tos = room:askForDiscard(to,self:objectName(),1,1)
					if tos and tos:getSuit()==3 then
						to:drawCards(2,self:objectName())
					end
				end
			end
		end
	end,
}
sx_xuezong:addSkill(sxjiexun)

sx_sunshao = sgs.General(extension_gen,"sx_sunshao","wu",3)
sxdingyi = sgs.CreateTriggerSkill{
	name = "sxdingyi",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()==sgs.Player_Finish and player:getEquips():length()<1 then
				for i, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasSkill(self) and player:askForSkillInvoke(self) then
						p:peiyin("fourthmobilezhidingyi")
						player:drawCards(1,self:objectName())
						break
					end
				end
			end
		end
	end,
}
sx_sunshao:addSkill(sxdingyi)
sxzuici = sgs.CreateTriggerSkill{
	name = "sxzuici",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() then
				local tos = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(damage.from)) do
					local has = false
					for _, c in sgs.qlist(p:getCards("ej")) do
						if player:isProhibited(damage.from,c) then continue end
						if c:isKindOf("EquipCard") then
							local n = c:getRealCard():toEquipCard():location()
							if damage.from:getEquip(n) then continue end
						end
						has = true
						break
					end
					if has then tos:append(p) end
				end
				player:setTag("sxzuiciFrom",ToData(damage.from))
				local to = room:askForPlayerChosen(player,tos,self:objectName(),"sxzuici0:"..damage.from:objectName(),true,true)
				if to then
					player:peiyin("fourthmobilezhizuici")
					tos = sgs.IntList()
					for _, c in sgs.qlist(to:getCards("ej")) do
						if player:isProhibited(damage.from,c) then tos:append(c:getEffectiveId()) end
						if c:isKindOf("EquipCard") then
							local n = c:getRealCard():toEquipCard():location()
							if damage.from:getEquip(n) then tos:append(c:getEffectiveId()) end
						end
					end
					local id = room:askForCardChosen(player,to,"ej",self:objectName(),false,sgs.Card_MethodNone,tos)
					if id>-1 then
						room:moveCardTo(sgs.Sanguosha:getCard(id),damage.from,room:getCardPlace(id),true)
					end
				end
			end
		end
	end,
}
sx_sunshao:addSkill(sxzuici)



extension_kun = sgs.Package("sxfy_kun", sgs.Package_GeneralPack)

sx_liuzang = sgs.General(extension_kun, "sx_liuzang$", "qun", 3)

sxyingeCard = sgs.CreateSkillCard{
	name = "sxyingeCard",
	filter = function(self, targets, to_select,source)
		return #targets<1 and to_select~=source
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("mobilerenyaohu")
		for _,p in sgs.list(targets) do
			if p:getCardCount()>0 then
				local dc = room:askForExchange(p,self:getSkillName(),1,1,true,"sxyinge0:"..player:objectName())
				if dc then
					room:giveCard(p,player,dc,self:getSkillName())
					if not p:isAlive() then continue end
					local tos = sgs.SPlayerList()
					dc = dummyCard()
					dc:setSkillName("_sxyinge")
					for _,q in sgs.list(room:getOtherPlayers(p)) do
						if q==player or player:inMyAttackRange(q) then
							if p:canSlash(q,dc,false) then
								tos:append(q)
							end
						end
					end
					local to = room:askForPlayerChosen(p,tos,self:getSkillName(),"sxyinge1:")
					if to then
						room:useCard(sgs.CardUseStruct(dc,p,to))
					end
				end
			end
		end
	end
}
sxyinge = sgs.CreateViewAsSkill{
	name = "sxyinge",
	n = 0,
	view_as = function(self, cards)
		return sxyingeCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#sxyingeCard")<1
	end, 
}
sx_liuzang:addSkill(sxyinge)
sxshiren = sgs.CreateTriggerSkill{
	name = "sxshiren",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TargetConfirmed) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.to:contains(player)
			and use.from~=player and player:askForSkillInvoke(self,data) then
				player:peiyin("mobilerenhuaibi")
				player:drawCards(2,self:objectName())
				local dc = room:askForExchange(player,self:objectName(),1,1,true,"sxshiren0:"..use.from:objectName())
				if dc then
					room:giveCard(player,use.from,dc,self:objectName())
				end
			end
		end
	end,
}
sx_liuzang:addSkill(sxshiren)
sxjuyi = sgs.CreateTriggerSkill{
	name = "sxjuyi$",
	events = {sgs.DamageCaused},
	can_trigger = function(self,target)
		return target and target:getKingdom()=="qun"
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			player:addMark(damage.to:objectName().."sxjuyi-Clear")
			if player~=damage.to and damage.to:hasLordSkill(self)
			and player:getMark(damage.to:objectName().."sxjuyi-Clear")==1
			and player:askForSkillInvoke(self,damage.to) then
				damage.to:peiyin("mobilerenjutu")
				player:damageRevises(data,-damage.damage)
				local id = room:askForCardChosen(player,damage.to,"he",self:objectName())
				if id>-1 then
					room:obtainCard(player,id)
				end
				return true
			end
		end
	end,
}
sx_liuzang:addSkill(sxjuyi)

sx_liubiao = sgs.General(extension_kun, "sx_liubiao$", "qun", 3)
sxzishou = sgs.CreateTriggerSkill{
	name = "sxzishou",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) and player:askForSkillInvoke(self) then
				player:peiyin("zishou")
				local ks = {}
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if not table.contains(ks,p:getKingdom()) then
						table.insert(ks,p:getKingdom())
					end
				end
				player:drawCards(#ks,self:objectName())
				player:skip(sgs.Player_Play)
			end
		end
	end,
}
sx_liubiao:addSkill(sxzishou)
sxzongshi = sgs.CreateMaxCardsSkill{
    name = "sxzongshi",
	extra_func = function(self,target)
        local x = 0
		if target:hasSkill("sxzongshi") then
	       	local ks = {target:getKingdom()}
			for _,p in sgs.list(target:getAliveSiblings())do
				if table.contains(ks,p:getKingdom()) then continue end
				table.insert(ks,p:getKingdom())
			end
			x = x+#ks
		end
		return x
	end 
}
sx_liubiao:addSkill(sxzongshi)
sxjujing = sgs.CreateTriggerSkill{
	name = "sxjujing$",
	events = {sgs.Damaged},
	can_trigger = function(self,target)
		return target and target:isAlive()
		and target:hasLordSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			if player~=damage.from and damage.from and damage.from:getKingdom()=="qum"
			and room:askForDiscard(player,self:objectName(),2,2,true,true,"sxjujing0:",".",self:objectName()) then
				player:peiyin(self)
				room:recover(player,sgs.RecoverStruct(self:objectName(),player))
			end
		end
	end,
}
sx_liubiao:addSkill(sxjujing)

sx_gongsunyuan = sgs.General(extension_kun,"sx_gongsunyuan$","qun",4)
sxhuaiyi = sgs.CreateTriggerSkill{
	name = "sxhuaiyi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()==sgs.Player_Start and player:getHandcardNum()>0 then
				player:peiyin("huaiyi")
				room:sendCompulsoryTriggerLog(player,self:objectName())
				room:showAllCards(player)
				local hs = player:getHandcards()
				for _,h in sgs.qlist(hs)do
					if h:getColor()~=hs:first():getColor() then
						local dc = room:askForExchange(player,self:objectName(),1,1,false,"sxhuaiyi0:")
						local rc = dummyCard()
						for _,c in sgs.qlist(hs)do
							if dc:getColor()==c:getColor() and player:canDiscard(player,c:getId()) then
								rc:addSubcard(c)
							end
						end
						room:throwCard(rc,self:objectName(),player)
						if player:isAlive() then
							local tos = sgs.SPlayerList()
							for _,p in sgs.qlist(room:getOtherPlayers(player))do
								if p:getCardCount()>0 then
									tos:append(p)
								end
							end
							tos = room:askForPlayersChosen(player,tos,self:objectName(),1,rc:subcardsLength(),"sxhuaiyi1:"..rc:subcardsLength())
							for _,p in sgs.qlist(tos)do
								room:doAnimate(1,player:objectName(),p:objectName())
							end
							for _,p in sgs.qlist(tos)do
								local id = room:askForCardChosen(player,p,"he",self:objectName())
								room:obtainCard(player,id)
							end
							if tos:length()>1 then
								room:loseHp(player,1,true,player,self:objectName())
							end
						end
						break
					end
				end
			end
		end
	end,
}
sx_gongsunyuan:addSkill(sxhuaiyi)
sxfengbai = sgs.CreateTriggerSkill{
	name = "sxfengbai$",
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(self,target)
		return target and target:hasLordSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_PlaceHand and move.from_places:contains(sgs.Player_PlaceEquip)
			and move.from:objectName()~=player:objectName() and move.to:objectName()==player:objectName()
			and move.from:getKingdom()=="qun" then
				local from = room:findPlayerByObjectName(move.from:objectName())
				if player:askForSkillInvoke(self,from) then
					player:peiyin(self)
					from:drawCards(1,self:objectName())
				end
			end
		end
	end,
}
sx_gongsunyuan:addSkill(sxfengbai)

sx_fuhuanghou = sgs.General(extension_kun,"sx_fuhuanghou","qun",3,false)
sxzhuikongVS = sgs.CreateViewAsSkill{
	name = "sxzhuikong",
	n = 1,
	response_pattern = "@@sxzhuikong",
	expand_pile = "#sxzhuikong",
	view_filter = function(self, selected, to_select)
        return sgs.Self:getPileName(to_select:getEffectiveId())=="#sxzhuikong"
	end,
	view_as = function(self, cards)
		if #cards>0 then
			return cards[1]
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
}
sxzhuikong = sgs.CreateTriggerSkill{
	name = "sxzhuikong",
	view_as_skill = sxzhuikongVS,
	events = {sgs.EventPhaseStart},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()==sgs.Player_Start then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:hasSkill(self) and p:canPindian(player) then
						local dc = room:askForCard(p,"slash","sxzhuikong0:"..player:objectName(),ToData(player),sgs.Card_MethodPindian)
						if dc then
							p:peiyin("zhuikong")
							p:skillInvoked(self,0)
							local pd = p:PinDian(player,self:objectName(),dc)
							local ids = sgs.IntList()
							local source = p
							if pd.success then
								ids:append(pd.to_card:getEffectiveId())
							else
								source = player
								ids:append(pd.from_card:getEffectiveId())
							end
							if room:getCardOwner(ids:first()) then continue end
							room:setPlayerMark(source,"sxzhuikongNum",ids:first())
							room:notifyMoveToPile(source,ids,"sxzhuikong")
							room:askForUseCard(source,"@@sxzhuikong","sxzhuikong1:")
						end
					end
				end
			end
		end
	end,
}
sx_fuhuanghou:addSkill(sxzhuikong)
sxqiuyuan = sgs.CreateTriggerSkill{
	name = "sxqiuyuan",
	events = {sgs.TargetConfirming},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TargetConfirming) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.from~=player then
				local to = room:getOtherPlayers(player)
				to:removeOne(use.from)
				to = room:askForPlayerChosen(player,to,self:objectName(),"sxqiuyuan0:",true,true)
				if to then
					player:peiyin("qiuyuan")
					to:setTag("sxqiuyuanUse",data)
					local dc = room:askForExchange(to,self:objectName(),1,1,true,"sxqiuyuan1:"..player:objectName(),true)
					if dc then
						room:giveCard(to,player,dc,self:objectName())
					else
						use.to:append(to)
						room:sortByActionOrder(use.to)
						data:setValue(use)
					end
				end
			end
		end
	end,
}
sx_fuhuanghou:addSkill(sxqiuyuan)

sx_cenhun = sgs.General(extension_kun,"sx_cenhun","wu",3)
sx_cenhun:addSkill("jishe")
sxwudu = sgs.CreateTriggerSkill{
	name = "sxwudu",
	events = {sgs.DamageInflicted},
	can_trigger = function(self,target)
		return target and target:isKongcheng()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			for _,p in sgs.qlist(room:getAllPlayers())do
				if p:hasSkill(self) and p:askForSkillInvoke(self,player) then
					p:peiyin(self)
					room:loseMaxHp(p,1,self:objectName())
					return p:damageRevises(data,-damage.damage)
				end
			end
		end
	end,
}
sx_cenhun:addSkill(sxwudu)

sx_wanglang = sgs.General(extension_kun, "sx_wanglang", "wei", 3)
sxgusheCard = sgs.CreateSkillCard{
	name = "sxgusheCard",
	filter = function(self, targets, to_select,source)
		return #targets<1 and to_select~=source and source:canPindian(to_select)
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("gushe")
		for _, p in sgs.list(targets) do
			local from,to,has = player,p,true
			while from:canPindian(to) and (has or from:askForSkillInvoke(self:getSkillName(),to,false)) do
				has = false
				local n = from:pindianInt(to,self:getSkillName())
				if n>0 then
					from:drawCards(1,self:getSkillName())
					from,to = p,player
				elseif n<0 then
					to:drawCards(1,self:getSkillName())
					from,to = player,p
				else
					if player:canPindian(p) and player:askForSkillInvoke(self:getSkillName(),p,false) then
						from,to = player,p
						has = true
					elseif p:canPindian(player) and p:askForSkillInvoke(self:getSkillName(),player,false) then
						from,to = p,player
						has = true
					else
						break
					end
				end
			end
		end
	end
}
sxgushe = sgs.CreateViewAsSkill{
	name = "sxgushe",
	n = 0,
	view_as = function(self, cards)
		return sxgusheCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#sxgusheCard")<1 and player:canPindian()
	end,
}
sx_wanglang:addSkill(sxgushe)
sxjici = sgs.CreateTriggerSkill{
	name = "sxjici",
	events = {sgs.PindianVerifying},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.PindianVerifying) then
			local pindian = data:toPindian()
			if pindian.from:hasSkill(self) and pindian.from:askForSkillInvoke(self,data) then
				pindian.from:peiyin("jici")
				room:loseHp(pindian.from,1,true,pindian.from,self:objectName())
				pindian.from_number = 13
				data:setValue(pindian)
				local log = sgs.LogMessage()
				log.from = pindian.from
				log.type = "$sxjiciLog"
				log.card_str = pindian.from_card:getEffectiveId()
				log.arg = "K"
				room:sendLog(log)
			end
			if pindian.to:hasSkill(self) and pindian.to:askForSkillInvoke(self,data) then
				pindian.to:peiyin("jici")
				room:loseHp(pindian.to,1,true,pindian.to,self:objectName())
				pindian.to_number = 13
				data:setValue(pindian)
				local log = sgs.LogMessage()
				log.from = pindian.to
				log.type = "$sxjiciLog"
				log.card_str = pindian.to_card:getEffectiveId()
				log.arg = "K"
				room:sendLog(log)
			end
		end
	end,
}
sx_wanglang:addSkill(sxjici)

sx_huaxin = sgs.General(extension_kun, "sx_huaxin", "wei", 3)
sxyuanqing = sgs.CreateTriggerSkill{
	name = "sxyuanqing",
	events = {sgs.EventPhaseChanging,sgs.CardsMoveOneTime},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.to==sgs.Player_NotActive and player:hasSkill(self) then
				local has = false
				for _, id in sgs.qlist(room:getDiscardPile()) do
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if p:getMark(id.."sxyuanqing-Clear")>0 then
							has = true
							break
						end
					end
				end
				if has and player:askForSkillInvoke(self) then
					player:peiyin("renyuanqing")
					for _, p in sgs.qlist(room:getAllPlayers()) do
						local ids = sgs.IntList()
						for _, id in sgs.qlist(room:getDiscardPile()) do
							if p:getMark(id.."sxyuanqing-Clear")>0 then
								ids:append(id)
							end
						end
						if ids:length()>0 then
							room:fillAG(ids,p)
							local id = room:askForAG(p,ids,false,self:objectName())
							room:obtainCard(p,id)
							room:clearAG(p)
						end
					end
				end
			end
		else
			local move = data:toMoveOneTime()
			if (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and move.from:objectName()==player:objectName() then
				for i, id in sgs.qlist(move.card_ids) do
					if move.from_places:at(i)==sgs.Player_PlaceHand
					or move.from_places:at(i)==sgs.Player_PlaceEquip then
						player:addMark(id.."sxyuanqing-Clear")
					end
				end
			end
		end
	end,
}
sx_huaxin:addSkill(sxyuanqing)
sxshuchen = sgs.CreateViewAsSkill{
	name = "sxshuchen",
	n = 1,
	view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards>0 then
			local dc = sgs.Sanguosha:cloneCard("peach")
			dc:setSkillName(self:objectName())
			dc:addSubcard(cards[1])
			return dc
		end
	end,
	enabled_at_response = function(self,player,pattern)
		return string.find(pattern,"peach")
		and not player:hasFlag("CurrentPlayer")
		and player:getHandcardNum()>player:getMaxCards()
	end,
	enabled_at_play = function(self, player)
		return not player:hasFlag("CurrentPlayer")
		and player:getHandcardNum()>player:getMaxCards()
		and dummyCard("peach"):isAvailable(player)
	end,
}
sx_huaxin:addSkill(sxshuchen)

sx_simashi = sgs.General(extension_kun, "sx_simashi", "wei", 4)
sxjinglve = sgs.CreateTriggerSkill{
	name = "sxjinglve",
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.CardsMoveOneTime},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()==sgs.Player_Discard then
				room:removeTag("sxjinglveIds")
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getCardCount()>1 and p:hasSkill(self) then
						local dc = room:askForExchange(p,self:objectName(),2,2,true,"sxjinglve0:"..player:objectName(),true)
						if dc then
							p:peiyin("jinglve")
							p:skillInvoked(self,0)
							room:showCard(p,dc:getSubcards())
							room:giveCard(p,player,dc,self:objectName())
							dc = sgs.QList2Table(dc:getSubcards())
							dc = table.concat(dc,",")
							player:setTag(p:objectName().."sxjinglve",ToData(dc))
							room:setPlayerCardLimitation(player,"discard",dc,true)
						end
					end
				end
			end
		elseif (event == sgs.EventPhaseEnd) then
			if player:getPhase()==sgs.Player_Discard then
				local ids = room:getTag("sxjinglveIds"):toIntList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					local srt = player:getTag(p:objectName().."sxjinglve"):toString()
					if srt~="" then
						player:removeTag(p:objectName().."sxjinglve")
						room:removePlayerCardLimitation(player,"discard",srt.."$1")
						local ids2 = sgs.IntList()
						for _,id in sgs.qlist(room:getDiscardPile())do
							if ids:contains(id) then ids2:append(id) end
						end
						if ids2:length()>0 then
							room:fillAG(ids2,p)
							if p:askForSkillInvoke(self,ToData("obtain"),false) then
								local id = room:askForAG(p,ids2,false,self:objectName())
								room:obtainCard(p,id)
							end
							room:clearAG(p)
						end
					end
				end
			end
		else
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_DiscardPile and move.from and move.from:objectName()==player:objectName() and player:getPhase()==sgs.Player_Discard
			and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD then
				local ids = room:getTag("sxjinglveIds"):toIntList()
				for _, id in sgs.qlist(move.card_ids) do
					ids:append(id)
				end
				room:setTag("sxjinglveIds",ToData(ids))
			end
		end
	end,
}
sx_simashi:addSkill(sxjinglve)



extension_xun = sgs.Package("sxfy_xun", sgs.Package_GeneralPack)

sx_zhangbao = sgs.General(extension_xun, "sx_zhangbao", "shu", 4)
sxjuezhu = sgs.CreateTriggerSkill{
	name = "sxjuezhu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage,sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damage) then
			if player:getMark("&sxjuezhu-Clear")<1 then
				room:sendCompulsoryTriggerLog(player,self)
				room:setPlayerMark(player,"&sxjuezhu-Clear",1)
			end
		else
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() then
				local dc = dummyCard("duel")
				dc:setSkillName("_sxjuezhu")
				if player:canUse(dc,damage.from) then
					room:sendCompulsoryTriggerLog(player,self)
					room:useCard(sgs.CardUseStruct(dc,player,damage.from))
				end
			end
		end
	end,
}
sx_zhangbao:addSkill(sxjuezhu)
sxchengji = sgs.CreateViewAsSkill{
	name = "sxchengji",
	n = 2,
	view_filter = function(self, selected, to_select)
        if #selected<1 then return true end
		return selected[1]:getColor()~=to_select:getColor()
	end,
	view_as = function(self, cards)
		if #cards>1 then
			local dc = sgs.Sanguosha:cloneCard("slash")
			dc:setSkillName(self:objectName())
			dc:addSubcard(cards[1])
			dc:addSubcard(cards[2])
			return dc
		end
	end,
	enabled_at_response = function(self,player,pattern)
		return string.find(pattern,"slash")
		and player:getCardCount()>1
	end,
	enabled_at_play = function(self, player)
		return player:getCardCount()>1
		and dummyCard():isAvailable(player)
	end,
}
sx_zhangbao:addSkill(sxchengji)

sx_guansuo = sgs.General(extension_xun, "sx_guansuo", "shu", 4)
sxzhengnanvs = sgs.CreateViewAsSkill{
	name = "sxzhengnan",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isRed() and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards>0 then
			local dc = sgs.Sanguosha:cloneCard("slash")
			dc:setSkillName(self:objectName())
			dc:addSubcard(cards[1])
			return dc
		end
	end,
	enabled_at_response = function(self,player,pattern)
		return string.find(pattern,"sxzhengnan")
	end,
	enabled_at_play = function(self, player)
		return false
	end,
}
sxzhengnan = sgs.CreateTriggerSkill{
	name = "sxzhengnan",
	view_as_skill = sxzhengnanvs,
	events = {sgs.EventPhaseStart,sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()==sgs.Player_Start and player:getHandcardNum()>0 then
				room:askForUseCard(player,"@@sxzhengnan","sxzhengnan0")
			end
		elseif (event == sgs.Death) then
			local death = data:toDeath()
			if death.damage and death.damage.card and death.damage.from==player
			and table.contains(death.damage.card:getSkillNames(),self:objectName()) then
				player:drawCards(2,self:objectName())
			end
		end
	end,
}
sx_guansuo:addSkill(sxzhengnan)

sx_liuchen = sgs.General(extension_xun, "sx_liuchen$", "shu", 4)
sxzhanjueCard = sgs.CreateSkillCard{
	name = "sxzhanjueCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, source)
		local duel = dummyCard("duel")
		duel:addSubcards(self:getSubcards())
		duel:setSkillName("sxzhanjue")
		local tos = sgs.PlayerList()
		for _,p in sgs.list(targets) do
			tos:append(p)
		end
		return duel:targetFilter(tos,to_select,source)
	end,
	about_to_use = function(self,room,use)
		local duel = dummyCard("duel")
		duel:addSubcards(self:getSubcards())
		duel:setSkillName("sxzhanjue")
		use.card = duel
		use.from:peiyin("zhanjue")
		self:cardOnUse(room,use)
		use.from:drawCards(1,self:getSkillName())
	end
}
sxzhanjue = sgs.CreateViewAsSkill{
	name = "sxzhanjue",
	view_as = function(self, cards)
		local duel = dummyCard("duel")
		duel:setSkillName("sxzhanjue")
		for _,c in sgs.qlist(sgs.Self:getHandcards()) do
			duel:addSubcard(c)
		end
		if sgs.Self:isLocked(duel) then return end
		duel = sxzhanjueCard:clone()
		for _,c in sgs.qlist(sgs.Self:getHandcards()) do
			duel:addSubcard(c)
		end
		return duel
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#sxzhanjueCard")<1
		and player:getHandcardNum()>0
	end, 
}
sx_liuchen:addSkill(sxzhanjue)
sxqinwang = sgs.CreateTriggerSkill{
	name = "sxqinwang$",
	events = {sgs.CardAsked},
	can_trigger = function(self,target)
		return target and target:hasLordSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardAsked) then
			local str = data:toStringList()
			if str[1]:match("slash") or str[1]:match("Slash") then
				if sgs.Sanguosha:getCurrentCardUseReason()~=sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
				then return false end
				local shus = room:getLieges("shu",player)
				if shus:length()>0 and player:askForSkillInvoke(self) then
					player:peiyin("qinwang")
					for _, p in sgs.qlist(shus) do
						if p:getHandcardNum()>0 and room:askForCard(p,"BasicCard","sxzhengnan0:"..player:objectName(),ToData(player)) then
							local dc = dummyCard()
							dc:setSkillName("_sxzhengnan")
							room:provide(dc)
							return true
						end
					end
				end
			end
		end
	end,
}
sx_liuchen:addSkill(sxqinwang)

sx_caorui = sgs.General(extension_xun, "sx_caorui$", "wei", 3)
sxhuituoCard = sgs.CreateSkillCard{
	name = "sxhuituoCard",
	target_fixed = true,
	will_throw = false,
	about_to_use = function(self,room,use)
		local moves = sgs.CardsMoveList()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE,use.from:objectName(),"sxhuituo","")
		for _,id in sgs.list(self:getSubcards())do
			if use.from:hasCard(id) then
				moves:append(sgs.CardsMoveStruct(id,nil,sgs.Player_DrawPile,reason))
			else
				moves:append(sgs.CardsMoveStruct(id,use.from,sgs.Player_PlaceHand,reason))
			end
		end
		room:moveCardsAtomic(moves,false)
	end
}
sxhuituovs = sgs.CreateViewAsSkill{
	name = "sxhuituo",
	n = 4,
	expand_pile = "#sxhuituo",
	view_filter = function(self, selected, to_select)
        return true
	end,
	view_as = function(self, cards)
		if #cards > 1 then
			local x,n = 0,0
			for _,c in sgs.list(cards)do
				if sgs.Self:getPileName(c:getEffectiveId())=="#sxhuituo"
				then x = x+1 else n = n+1 end
			end
			if x~=n then return end
			local sc = sxhuituoCard:clone()
			for _,c in sgs.list(cards)do
				sc:addSubcard(c)
			end
			return sc
		end
	end,
	enabled_at_response = function(self,player,pattern)
		return string.find(pattern,"sxhuituo")
	end,
	enabled_at_play = function(self, player)
		return false
	end, 
}
sxhuituo = sgs.CreateTriggerSkill{
	name = "sxhuituo",
	view_as_skill = sxhuituovs,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damaged) then
			if player:askForSkillInvoke(self,data) then
				player:peiyin("huituo")
				local ids = room:showDrawPile(player,2,self:objectName(),false)
				room:notifyMoveToPile(player,ids,"sxhuituo")
				room:askForUseCard(player,"@@sxhuituo","sxhuituo0")
			end
		end
	end,
}
sx_caorui:addSkill(sxhuituo)
sxmingjianCard = sgs.CreateSkillCard{
	name = "sxmingjianCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, source)
		return #targets<1 and to_select~=source
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("mingjian")
		for _,p in sgs.list(targets)do
			room:showCard(player,self:getEffectiveId())
			room:giveCard(player,p,self,self:getSkillName())
			local c = sgs.Sanguosha:getCard(self:getEffectiveId())
			if p:hasCard(c) and c:isAvailable(p) then
				room:askForUseCard(p,c:toString(),"sxmingjian0:"..c:objectName())
			end
		end
	end
}
sxmingjian = sgs.CreateViewAsSkill{
	name = "sxmingjian",
	n = 1,
	view_filter = function(self, selected, to_select)
        return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local sc = sxmingjianCard:clone()
			sc:addSubcard(cards[1])
			return sc
		end
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#sxmingjianCard")<1
		and player:getCardCount()>0
	end, 
}
sx_caorui:addSkill(sxmingjian)
sx_caorui:addSkill("xingshuai")

sx_guohuanghou = sgs.General(extension_xun, "sx_guohuanghou", "wei", 3,false)
sxjiaozhaoCard = sgs.CreateSkillCard{
	name = "sxjiaozhaoCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, source)
		return #targets<1 and to_select~=source
		and to_select:getHandcardNum()>1
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("jiaozhao")
		for _,p in sgs.list(targets)do
			local dc = room:askForExchange(p,"sxjiaozhao0",2,2,false,"sxjiaozhao0:"..player:objectName())
			if dc then
				room:showCard(p,dc:getSubcards())
				room:fillAG(dc:getSubcards(),player)
				if player:hasFlag("sxdanxinbf") then
					local id = room:askForAG(player,dc:getSubcards(),false,self:objectName())
					room:obtainCard(player,id)
				else
					local bc = room:askForExchange(player,"sxjiaozhao1",1,1,false,"sxjiaozhao1:"..p:objectName(),true)
					if bc then
						local moves = sgs.CardsMoveList()
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP,player:objectName(),p:objectName(),self:getSkillName(),"")
						local id = room:askForAG(player,dc:getSubcards(),false,self:objectName())
						moves:append(sgs.CardsMoveStruct(id,player,sgs.Player_PlaceHand,reason))
						moves:append(sgs.CardsMoveStruct(bc:getEffectiveId(),p,sgs.Player_PlaceHand,reason))
						room:moveCardsAtomic(moves,false)
					end
				end
				room:clearAG(player)
			end
		end
		player:setFlags("-sxdanxinbf")
	end
}
sxjiaozhao = sgs.CreateViewAsSkill{
	name = "sxjiaozhao",
	response_pattern = "@@sxjiaozhao",
	view_as = function(self, cards)
		return sxjiaozhaoCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#sxjiaozhaoCard")<1
	end, 
}
sx_guohuanghou:addSkill(sxjiaozhao)
sxdanxin = sgs.CreateTriggerSkill{
	name = "sxdanxin",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.Damaged) then
			player:setFlags("sxdanxinbf")
			room:askForUseCard(player,"@@sxjiaozhao","sxdanxin0")
			player:setFlags("-sxdanxinbf")
		end
	end,
}
sx_guohuanghou:addSkill(sxdanxin)

sx_liuye = sgs.General(extension_xun, "sx_liuye", "wei", 3)
sxpolu = sgs.CreateTriggerSkill{
	name = "sxpolu",
	events = {sgs.Damaged,sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if player:canDiscard(damage.to,"e") and player:askForSkillInvoke(self,damage.to) then
			player:peiyin("polu")
			local id = room:askForCardChosen(player,damage.to,"e",self:objectName(),false,sgs.Card_MethodDiscard)
			if id>-1 then
				room:throwCard(id,self:objectName(),damage.to,player)
				if damage.to==player then
					player:drawCards(1,self:objectName())
				end
			end
		end
	end,
}
sx_liuye:addSkill(sxpolu)
sxchoulveCard = sgs.CreateSkillCard{
	name = "sxchoulveCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, source)
		return #targets<1 and to_select~=source
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("choulve")
		for _,p in sgs.list(targets)do
			room:giveCard(player,p,self,self:getSkillName())
			local dc = room:askForExchange(p,self:getSkillName(),1,1,true,"sxchoulve0:"..player:objectName(),true,"EquipCard")
			if dc then
				room:showCard(p,dc:getEffectiveId())
				room:giveCard(p,player,dc,self:getSkillName())
			end
		end
	end
}
sxchoulve = sgs.CreateViewAsSkill{
	name = "sxchoulve",
	n = 1,
	view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local sc = sxchoulveCard:clone()
			sc:addSubcard(cards[1])
			return sc
		end
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#sxchoulveCard")<1
		and player:getHandcardNum()>0
	end, 
}
sx_liuye:addSkill(sxchoulve)

sx_dingfeng = sgs.General(extension_xun, "sx_dingfeng", "wu", 4)
sxduanbing = sgs.CreateTriggerSkill{
	name = "sxduanbing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and player:getMark("sxduanbing-Clear")<1 then
			player:addMark("sxduanbing-Clear")
			player:peiyin("duanbing")
			room:sendCompulsoryTriggerLog(player,self:objectName())
			player:damageRevises(data,1)
		end
	end,
}
sxduanbingbf = sgs.CreateAttackRangeSkill{
	name = "#sxduanbingbf",
	fixed_func = function(self, target)
		if target:hasSkill("sxduanbing") then
			return 1			
		end
		return -1
	end
}
sx_dingfeng:addSkill(sxduanbing)
sx_dingfeng:addSkill(sxduanbingbf)
sxfenxunCard = sgs.CreateSkillCard{
	name = "sxfenxunCard",
	target_fixed = false,
	--will_throw = false,
	filter = function(self, targets, to_select, source)
		return #targets<1 and to_select~=source
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("fenxun")
		for _,p in sgs.list(targets)do
			room:insertAttackRangePair(player,p)
			p:addMark("sxfenxunbf-Clear")
		end
	end
}
sxfenxunvs = sgs.CreateViewAsSkill{
	name = "sxfenxun",
	n = 1,
	view_filter = function(self, selected, to_select)
        return to_select:isKindOf("Armor")
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local sc = sxfenxunCard:clone()
			sc:addSubcard(cards[1])
			return sc
		end
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#sxfenxunCard")<1
		and player:getCardCount()>0
	end, 
}
sxfenxun = sgs.CreateTriggerSkill{
	name = "sxfenxun",
	view_as_skill = sxfenxunvs,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to==sgs.Player_NotActive then
			for _,p in sgs.list(room:getOtherPlayers(player))do
				if p:getMark("sxfenxunbf-Clear")>0 then
					for i=1,p:getMark("sxfenxunbf-Clear") do
						room:removeAttackRangePair(player,p)
					end
				end
			end
		end
	end,
}
sx_dingfeng:addSkill(sxfenxun)

sx_sunluban = sgs.General(extension_xun, "sx_sunluban", "wu", 3,false)
sxzenhui = sgs.CreateTriggerSkill{
	name = "sxzenhui",
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") or use.card:isKindOf("TrickCard") then
			local tos = sgs.SPlayerList()
			for _,p in sgs.list(room:getOtherPlayers(player))do
				if use.to:contains(p) then continue end
				tos:append(p)
			end
			local to = room:askForPlayerChosen(player,tos,self:objectName(),"sxzenhui0:"..use.card:objectName(),true,true)
			if to then
				player:peiyin("zhenhui")
				use.from = to
				data:setValue(use)
			end
		end
	end,
}
sx_sunluban:addSkill(sxzenhui)
sxchuyi = sgs.CreateTriggerSkill{
	name = "sxchuyi",
	events = {sgs.DamageCaused},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		for _,p in sgs.list(room:getOtherPlayers(player))do
			if p:inMyAttackRange(damage.to) and p:getMark("sxchuyi_lun")<1
			and p:hasSkill(self) and p:askForSkillInvoke(self,damage.to) then
				p:addMark("sxchuyi_lun")
				player:damageRevises(data,1)
			end
		end
	end,
}
sx_sunluban:addSkill(sxchuyi)


extension_kan = sgs.Package("sxfy_kan", sgs.Package_GeneralPack)


sx_xiahouba = sgs.General(extension_kan, "sx_xiahouba", "shu", 4)
sxbaobian = sgs.CreateTriggerSkill{
	name = "sxbaobian",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase()==sgs.Player_Play then
			local tos = sgs.SPlayerList()
			for _,p in sgs.list(room:getAllPlayers())do
				if p:canDiscard(p,"h") then tos:append(p) end
			end
			local to = room:askForPlayerChosen(player,tos,self:objectName(),"sxbaobian0:",true,true)
			if to then
				player:peiyin("baobian")
				room:loseHp(player,1,true,player,self:objectName())
				local dc = room:askForDiscard(to,self:objectName(),1,1)
				if dc and player:isAlive() and sgs.Sanguosha:getCard(dc:getEffectiveId()):isKindOf("BasicCard") then
					dc = dummyCard()
					dc:setSkillName("_sxbaobian")
					if player:canSlash(to,dc,false) then
						room:useCard(sgs.CardUseStruct(dc,player,to))
					end
				end
			end
		end
	end,
}
sx_xiahouba:addSkill(sxbaobian)

sx_lvfan = sgs.General(extension_kan, "sx_lvfan", "wu", 3)
sx_lvfan:addSkill("yandiaodu")
sxdiancai = sgs.CreateTriggerSkill{
	name = "sxdiancai",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceEquip)
		and move.from:isAlive() and move.from:getEquips():length()<1 then
			player:peiyin("yandiancai")
			room:sendCompulsoryTriggerLog(player,self:objectName())
			player:drawCards(1,self:objectName())
		end
	end,
}
sx_lvfan:addSkill(sxdiancai)

sx_sunyi = sgs.General(extension_kan, "sx_sunyi", "wu", 4)
sxzaoli = sgs.CreateTriggerSkill{
	name = "sxzaoli",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase()==sgs.Player_Start and player:getCardCount()>0 then
			player:peiyin("mobileyongzaoli")
			room:sendCompulsoryTriggerLog(player,self:objectName())
			local choices = {}
			if player:getHandcardNum()>0 then
				table.insert(choices,"sxzaoli1")
			end
			if player:hasEquip() then
				table.insert(choices,"sxzaoli2")
			end
			local n,x = player:getLostHp(),0
			if room:askForChoice(player,self:objectName(),table.concat(choices,"+"))=="sxzaoli1" then
				x = player:getHandcardNum()
				player:throwAllHandCards(self:objectName())
			else
				x = player:getEquips():length()
				player:throwAllEquips(self:objectName())
			end
			player:drawCards(x+n,self:objectName())
			if n>0 then
				room:loseHp(player,1,true,player,self:objectName())
			end
		end
	end,
}
sx_sunyi:addSkill(sxzaoli)

sx_liuzan = sgs.General(extension_kan, "sx_liuzan", "wu", 4)
sxfenyin = sgs.CreateTriggerSkill{
	name = "sxfenyin",
	events = {sgs.CardUsed,sgs.DrawNCards},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason~="draw_phase" then return end
			if player:hasSkill(self) and player:askForSkillInvoke(self,data) then
				player:addMark("sxfenyinUse-Clear")
				player:peiyin("fenyin")
				draw.num = draw.num+2
				data:setValue(draw)
			end
		else
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and player:getMark("sxfenyinUse-Clear")>0 then
				if player:getMark("&sxfenyin+:+"..use.card:getColorString().."-Clear")>0 then
					room:askForDiscard(player,self:objectName(),1,1,false,true)
				end
				for _,m in sgs.list(player:getMarkNames())do
					if m:startsWith("&sxfenyin+:+") then
						room:setPlayerMark(player,m,0)
					end
				end
				room:setPlayerMark(player,"&sxfenyin+:+"..use.card:getColorString().."-Clear",1)
			end
		end
	end,
}
sx_liuzan:addSkill(sxfenyin)

sx_jiling = sgs.General(extension_kan, "sx_jiling", "qun", 4)
sxshuangren = sgs.CreateTriggerSkill{
	name = "sxshuangren",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase()==sgs.Player_Play then
			local tos = sgs.SPlayerList()
			for _,p in sgs.list(room:getOtherPlayers(player))do
				if player:canPindian(p) then tos:append(p) end
			end
			local to = room:askForPlayerChosen(player,tos,self:objectName(),"sxshuangren0",true,true)
			if to then
				player:peiyin("shuangren")
				if player:pindian(to,self:objectName()) then
					tos = sgs.SPlayerList()
					local dc = dummyCard()
					dc:setSkillName("_sxshuangren")
					for _,p in sgs.list(room:getAllPlayers())do
						if to:distanceTo(p)==1 and player:canSlash(p,dc,false)
						then tos:append(p) end
					end
					tos = room:askForPlayersChosen(player,tos,self:objectName(),0,2,"sxshuangren1")
					for _,p in sgs.list(tos)do
						room:useCard(sgs.CardUseStruct(dc,player,p))
					end
				else
					room:setPlayerCardLimitation(player,"use","Slash",true)
				end
			end
		end
	end,
}
sx_jiling:addSkill(sxshuangren)

sx_liru = sgs.General(extension_kan, "sx_liru", "qun", 3)
sxmiejiCard = sgs.CreateSkillCard{
	name = "sxmiejiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, source)
		return #targets<1 and to_select~=source
	end,
	on_use = function(self, room, player, targets)
		player:peiyin("mieji")
		for _,p in sgs.list(targets)do
			room:giveCard(player,p,self,self:getSkillName())
			local dc = dummyCard()
			for i=1,2 do
				if dc:subcardsLength()<player:getCardCount() and player:canDiscard(p,"he") then
					local id = room:askForCardChosen(player,p,"he",self:getSkillName(),false,sgs.Card_MethodDiscard,dc:getSubcards(),true)
					if id<0 then break end
					dc:addSubcard(id)
				else
					break
				end
			end
			room:throwCard(dc,self:getSkillName(),p,player)
		end
	end
}
sxmieji = sgs.CreateViewAsSkill{
	name = "sxmieji",
	n = 1,
	view_filter = function(self, selected, to_select)
        return to_select:isKindOf("TrickCard") and to_select:isBlack()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local sc = sxmiejiCard:clone()
			sc:addSubcard(cards[1])
			return sc
		end
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#sxmiejiCard")<1
		and player:getHandcardNum()>0
	end, 
}
sx_liru:addSkill(sxmieji)
sxjuece = sgs.CreateTriggerSkill{
	name = "sxjuece",
	events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime},
	can_trigger = function(self,target)
		return target and target:hasSkill(self:objectName(),true)
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from then
				for i,id in sgs.list(move.card_ids)do
					if move.from_places:at(i)==sgs.Player_PlaceHand or move.from_places:at(i)==sgs.Player_PlaceEquip then
						move.from:addMark("sxjueceNum-Clear")
					end
				end
			end
		elseif player:getPhase()==sgs.Player_Finish and player:hasSkill(self:objectName()) then
			local tos = sgs.SPlayerList()
			for _,p in sgs.list(room:getAllPlayers())do
				if p:getMark("sxjueceNum-Clear")>1 then tos:append(p) end
			end
			local to = room:askForPlayerChosen(player,tos,self:objectName(),"sxjuece0",true,true)
			if to then
				player:peiyin("juece")
				room:damage(sgs.DamageStruct(self:objectName(),player,to))
			end
		end
	end,
}
sx_liru:addSkill(sxjuece)

sx_wangyun = sgs.General(extension_kan, "sx_wangyun", "qun", 3)
sxlianji = sgs.CreateViewAsSkill{
	name = "sxlianji",
	n = 1,
	view_filter = function(self, selected, to_select)
        return to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local sc = sgs.Sanguosha:cloneCard("collateral")
			sc:setSkillName(self:objectName())
			sc:addSubcard(cards[1])
			return sc
		end
	end,
	enabled_at_play = function(self, player)
		return player:getCardCount()>0
		and dummyCard("collateral"):isAvailable(player)
	end, 
}
sx_wangyun:addSkill(sxlianji)
sxzongji = sgs.CreateTriggerSkill{
	name = "sxzongji",
	events = {sgs.Damaged},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.Damaged then
			local damage = data:toDamage()
			if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) then
				for _,p in sgs.list(room:getAllPlayers())do
					if p:hasSkill(self) and (p:canDiscard(player,"he") or p:canDiscard(damage.from,"he"))
					and p:askForSkillInvoke(self,data) then
						p:peiyin("moucheng")
						if p:canDiscard(player,"he") then
							local id = room:askForCardChosen(p,player,"he",self:objectName(),false,sgs.Card_MethodDiscard)
							if id>-1 then room:throwCard(id,self:objectName(),player,p) end
						end
						if p:isAlive() and p:canDiscard(damage.from,"he") then
							local id = room:askForCardChosen(p,damage.from,"he",self:objectName(),false,sgs.Card_MethodDiscard)
							if id>-1 then room:throwCard(id,self:objectName(),damage.from,p) end
						end
					end
				end
			end
		end
	end,
}
sx_wangyun:addSkill(sxzongji)

sx_taoqian = sgs.General(extension_kan, "sx_taoqian", "qun", 4)
sxyirang = sgs.CreateTriggerSkill{
	name = "sxyirang",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase()==sgs.Player_Play and player:getHandcardNum()>0 and player:askForSkillInvoke(self) then
			player:peiyin("yirang")
			room:showAllCards(player)
			local n = 990
			for _,p in sgs.list(room:getOtherPlayers(player))do
				if p:getHandcardNum()<n then n = p:getHandcardNum() end
			end
			local tos = sgs.SPlayerList()
			for _,p in sgs.list(room:getOtherPlayers(player))do
				if p:getHandcardNum()<=n then tos:append(p) end
			end
			local to = room:askForPlayerChosen(player,tos,self:objectName(),"sxyirang0")
			if to then
				room:doAnimate(1,player:objectName(),to:objectName())
				local hs = player:getHandcards()
				room:giveCard(player,to,player:handCards(),self:objectName(),true)
				n = {}
				for _,h in sgs.list(hs)do
					if table.contains(n,h:getType()) then continue end
					table.insert(n,h:getType())
				end
				player:drawCards(#n,self:objectName())
			end
		end
	end,
}
sx_taoqian:addSkill(sxyirang)


sgs.LoadTranslationTable{



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
	[":sxshuangren"] = "出牌阶段开始时，你可以与一名其他角色拼点：若你赢，你可以视为对其距离1的至多两名角色各使用一张【杀】；若你没赢，你本回合不能使用【杀】。",
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
	[":sxgushe"] = "出牌阶段限一次，你可以与一名其他角色拼点：赢的角色摸一张牌，然后没赢的角色可以与对方重复此流程。",
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
	[":sxwuyou"] = "出牌阶段限一次，你可以与一名其他角色拼点：若你没赢，你本回合获得“武圣”；赢的角色视为对没赢的角色使用一张【决斗】。",

}





extension_qian = sgs.Package("sxfy_qian",sgs.Package_GeneralPack)

sx_tianfeng = sgs.General(extension_qian,"sx_tianfeng","qun",3)
sxgangjian = sgs.CreateTriggerSkill{
	name = "sxgangjian",
	events = {sgs.EventPhaseStart,sgs.CardFinished},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Start then
				for _,p in sgs.list(room:getOtherPlayers(player))do
					if p:hasSkill(self) then
						local dc = dummyCard()
						dc:setSkillName("_sxgangjian")
						if player:canSlash(p,dc,false) and p:askForSkillInvoke(self,player) then
							p:peiyin("sxgangjian")
							room:useCard(sgs.CardUseStruct(dc,player,p))
						end
					end
				end
			end
		else
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),self:objectName()) then
				if not use.card:hasFlag("DamageDone") then
					for _,p in sgs.list(use.to)do
						if p:isAlive() and p:getPhase()==sgs.Player_Start then
							room:setPlayerCardLimitation(p,"use","TrickCard",true)
						end
					end
				end
			end
		end
	end,
}
sx_tianfeng:addSkill(sxgangjian)
sxguijieCard = sgs.CreateSkillCard{
	name = "sxguijieCard",
	target_fixed = true,
	on_validate_in_response = function(self,from)
		local room = from:getRoom()
		room:throwCard(self,self:getSkillName(),from)
		from:drawCards(1,self:getSkillName())
		local dc = dummyCard("jink")
		dc:setSkillName("sxguijie")
		return dc
	end,
	on_validate = function(self,use)
		local room = use.from:getRoom()
		room:throwCard(self,self:getSkillName(),use.from)
		use.from:drawCards(1,self:getSkillName())
		local dc = dummyCard("jink")
		dc:setSkillName("sxguijie")
		return dc
	end,
}
sxguijie = sgs.CreateViewAsSkill{
	name = "sxguijie",
	n = 2,
	view_filter = function(self,selected,to_select)
        return to_select:isRed() and not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self,cards)
		if #cards > 1 then
			local sc = sxguijieCard:clone()
			for _,c in sgs.list(cards)do
				sc:addSubcard(c)
			end
			return sc
		end
	end,
	enabled_at_response = function(self,player,pattern)
		return string.find(pattern,"jink") and player:getCardCount()>1
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
sx_tianfeng:addSkill(sxguijie)

sx_liuxie = sgs.General(extension_qian,"sx_liuxie$","qun",3)
sxtianming = sgs.CreateTriggerSkill{
	name = "sxtianming",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.to:contains(player) then
				if player:askForSkillInvoke(self,data) then
					player:peiyin("tianming")
					player:throwAllHandCardsAndEquips(self:objectName())
					player:drawCards(2,self:objectName())
				end
				local x = 0
				for _,p in sgs.list(room:getAlivePlayers())do
					if p:getHp()>x then x = p:getHp() end
				end
				local xp = nil
				for _,p in sgs.list(room:getAlivePlayers())do
					if p:getHp()>=x then
						if xp then
							xp = nil
							break
						end
						xp = p
					end
				end
				if xp and xp~=player and xp:askForSkillInvoke(self,data) then
					xp:throwAllHandCardsAndEquips(self:objectName())
					xp:drawCards(2,self:objectName())
				end
			end
		end
	end,
}
sx_liuxie:addSkill(sxtianming)
sxmizhaoCard = sgs.CreateSkillCard{
	name = "sxmizhaoCard",
	target_fixed = false,
	mute = true;
	filter = function(self,targets,to_select,source)
		if #targets<1 then return to_select~=source end
		return #targets < 2
	end,
	feasible = function(self,targets)
		return #targets == 2
	end,
	about_to_use = function(self,room,use)
		room:setTag("sxmizhaoData",ToData(use))
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,player,targets)
		player:peiyin("mizhao")
		local use = room:getTag("sxmizhaoData"):toCardUse()
		local dc = dummyCard()
		dc:addSubcards(player:handCards())
		dc:addSubcards(player:getEquipsId())
		if use.to:first():isAlive() then
			room:giveCard(player,use.to:first(),dc,"sxmizhao")
		end
		if use.to:first():isAlive() and use.to:last():isAlive()
		and use.to:first():askForSkillInvoke("sxmizhao",use.to:last(),false) then
			room:loseHp(use.to:first(),1,true,use.to:first(),"sxmizhao")
			room:loseHp(use.to:last(),1,true,use.to:first(),"sxmizhao")
		end
	end
}
sxmizhaoVS = sgs.CreateViewAsSkill{
	name = "sxmizhao",
	response_pattern = "@@sxmizhao",
	view_as = function(self,cards)
		return sxmizhaoCard:clone()
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
sxmizhao = sgs.CreateTriggerSkill{
	name = "sxmizhao",
	view_as_skill = sxmizhaoVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			if player:getPhase()==sgs.Player_Finish and player:getCardCount()>0 then
				room:askForUseCard(player,"@@sxmizhao","sxmizhao0")
			end
		end
	end,
}
sx_liuxie:addSkill(sxmizhao)
sxzhongyan = sgs.CreateTriggerSkill{
	name = "sxzhongyan$",
	events = {sgs.Death},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.Death) then
			local death = data:toDeath()
			if death.who:getKingdom()=="qun" and player:hasLordSkill(self)
			and player:isWounded() and player:askForSkillInvoke(self) then
				room:recover(player,sgs.RecoverStruct(self:objectName(),player))
			end
		end
	end,
}
sx_liuxie:addSkill(sxzhongyan)

sx_simazhao = sgs.General(extension_qian,"sx_simazhao","wei",4)
sxzhaoxin = sgs.CreateTriggerSkill{
	name = "sxzhaoxin",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Start and player:getHandcardNum()>0 then
				room:sendCompulsoryTriggerLog(player,self:objectName())
				player:peiyin("zhaoxin")
				room:showAllCards(player)
				local hs = player:getHandcards()
				for _,h in sgs.list(hs)do
					if h:getColor()~=hs:last():getColor()
					then return end
				end
				local tp = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"sxzhaoxin0")
				if tp then
					room:damage(sgs.DamageStruct(self:objectName(),player,tp))
				end
			end
		end
	end,
}
sx_simazhao:addSkill(sxzhaoxin)

sx_guonvwang = sgs.General(extension_qian,"sx_guonvwang","wei",3,false)
sxwufei = sgs.CreateTriggerSkill{
	name = "sxwufei",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self,target)
		return target and target:isAlive() and target:hasSkill(self)
		and target:getPhase()==sgs.Player_Start
	end,
	on_trigger = function(self,event,player,data,room)
		local aps = sgs.SPlayerList()
		for _,p in sgs.list(room:getAlivePlayers())do
			if p:isFemale() and p:getHandcardNum()>0
			then aps:append(p) end
		end
		local tp = room:askForPlayerChosen(player,aps,self:objectName(),"sxwufei0",true,true)
		if tp then
			player:peiyin("wufei")
			room:showAllCards(tp)
			local sc = room:askForExchange(tp,self:objectName(),1,1,false,"sxwufei1")
			if sc then
				local dc = dummyCard()
				for _,h in sgs.list(tp:getHandcards())do
					if h:getColor()==sc:getColor() and not tp:isJilei(h)
					then dc:addSubcard(h) end
				end
				room:throwCard(dc,self:objectName(),tp)
				tp:drawCards(1,self:objectName())
			end
		end
	end,
}
sx_guonvwang:addSkill(sxwufei)
sxjiaochong = sgs.CreateTriggerSkill{
	name = "sxjiaochong",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self,target)
		return target and target:isAlive() and target:isMale()
		and target:getPhase()==sgs.Player_Finish
	end,
	on_trigger = function(self,event,player,data,room)
		for _,p in sgs.list(room:getAllPlayers())do
			if p:hasSkill(self) then
				local wf = sgs.Sanguosha:getTriggerSkill("sxwufei")
				for _,q in sgs.list(room:getAlivePlayers())do
					if q:isFemale() and q:getHandcardNum()>0 then
						if wf and p:askForSkillInvoke(self) then
							p:peiyin("jiaochong")
							wf:trigger(event,room,p,data)
						end
						break
					end
				end
			end
		end
	end,
}
sx_guonvwang:addSkill(sxjiaochong)

sx_jiakui = sgs.General(extension_qian,"sx_jiakui","wei",3)
sxzhongzuo = sgs.CreateTriggerSkill{
	name = "sxzhongzuo",
	events = {sgs.Damaged,sgs.Damage,sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to==sgs.Player_NotActive then
				for _,p in sgs.list(room:getAllPlayers())do
					if p:getMark("sxzhongzuoDamage-Clear")>0 and p:hasSkill(self:objectName()) then
						room:sendCompulsoryTriggerLog(p,self:objectName())
						p:peiyin("zhongzuo")
						p:drawCards(1,self:objectName())
						player:drawCards(1,self:objectName())
					end
				end
			end
		else
			player:addMark("sxzhongzuoDamage-Clear")
		end
	end,
}
sx_jiakui:addSkill(sxzhongzuo)
sxwanlan = sgs.CreateTriggerSkill{
	name = "sxwanlan",
	events = {sgs.Dying},
	frequency = sgs.Skill_Limited,
	limit_mark = "@sxwanlan";
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.Dying then
			local dying = data:toDying()
			if dying.who~=player and player:getMark("@sxwanlan")>0 and player:getHandcardNum()>0
			and player:askForSkillInvoke(self,dying.who) then
				player:peiyin("wanlan")
				room:doSuperLightbox(player,self:objectName())
				room:removePlayerMark(player,"@sxwanlan")
				room:giveCard(player,dying.who,player:handCards(),self:objectName())
				room:recover(dying.who,sgs.RecoverStruct(self:objectName(),player,1-dying.who:getHp()))
			end
		end
	end,
}
sx_jiakui:addSkill(sxwanlan)

sx_yufan = sgs.General(extension_qian,"sx_yufan","wu",3)
sxzongxuan = sgs.CreateTriggerSkill{
	name = "sxzongxuan",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceHand) and player:objectName() == move.from:objectName()
			and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD then
				local tps = sgs.SPlayerList()
				for _,p in sgs.list(room:getAlivePlayers())do
					if player:canDiscard(p,"ej") then tps:append(p) end
				end
				local tp = room:askForPlayerChosen(player,tps,self:objectName(),"sxzongxuan0",true,true)
				if tp then
					player:peiyin("zongxuan")
					local id = room:askForCardChosen(player,tp,"ej",self:objectName(),false,sgs.Card_MethodDiscard)
					if id>-1 then room:throwCard(id,self:objectName(),tp,player) end
				end
			end
		end
	end,
}
sx_yufan:addSkill(sxzongxuan)
sxzhiyan = sgs.CreateTriggerSkill{
	name = "sxzhiyan",
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_DiscardPile then
				local ids = player:getTag("sxzhiyanIds"):toIntList()
				for _,id in sgs.list(move.card_ids)do
					ids:append(id)
				end
				player:setTag("sxzhiyanIds",ToData(ids))
			end
		elseif player:getPhase()==sgs.Player_Finish then
			local ids = player:getTag("sxzhiyanIds"):toIntList()
			if ids:length()>0 and player:hasSkill(self) then
				local ids2 = sgs.IntList()
				for _,id in sgs.list(ids)do
					local c = sgs.Sanguosha:getCard(id)
					if c:isKindOf("EquipCard") and room:getCardOwner(id)==nil then
						ids2:append(id)
					end
				end
				if ids2:length()>0 then
					room:fillAG(ids2,player)
					if player:askForSkillInvoke(self,ToData(ids2)) then
						player:peiyin("zhiyan")
						local id = room:askForAG(player,ids2,false,self:objectName())
						room:obtainCard(player,id)
					end
					room:clearAG(player)
				end
			end
			player:removeTag("sxzhiyanIds")
		end
	end,
}
sx_yufan:addSkill(sxzhiyan)

sx_zhugeke = sgs.General(extension_qian,"sx_zhugeke","wu",3)
sxaocai = sgs.CreateTriggerSkill{
	name = "sxaocai",
	events = {sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to==sgs.Player_NotActive then
				for _,p in sgs.list(room:getAllPlayers())do
					if p:isKongcheng() and p:hasSkill(self:objectName())
					and p:askForSkillInvoke(self) then
						p:peiyin("aocai")
						local ids = room:getNCards(2)
						room:fillAG(ids,p)
						local id = room:askForAG(p,ids,true,self:objectName())
						room:clearAG(player)
						room:returnToTopDrawPile(ids)
						if id>=0 then
							room:obtainCard(player,id)
						end
					end
				end
			end
		end
	end,
}
sx_zhugeke:addSkill(sxaocai)
sxduwuCard = sgs.CreateSkillCard{
	name = "sxduwuCard",
	target_fixed = false,
	mute = true;
	filter = function(self,targets,to_select,source)
		return #targets<1 and source:inMyAttackRange(to_select)
	end,
	on_use = function(self,room,player,targets)
		player:peiyin("duwu")
		for _,p in sgs.list(targets)do
			room:damage(sgs.DamageStruct("sxduwu",player,p))
		end
	end
}
sxduwu = sgs.CreateViewAsSkill{
	name = "sxduwu",
	response_pattern = "@@sxduwu",
	view_as = function(self,cards)
		local dc = sxduwuCard:clone()
		dc:addSubcards(sgs.Self:getHandcards())
		return dc
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#sxduwuCard")<1 and player:canDiscard(player,"h")
	end,
}
sx_zhugeke:addSkill(sxduwu)

sx_mengda = sgs.General(extension_qian,"sx_mengda","shu",4)
sxzhuan = sgs.CreateTriggerSkill{
	name = "sxzhuan",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.Damaged then
			player:addMark("sxzhuanDamaged-Clear")
			if player:getMark("sxzhuanDamaged-Clear")==1 and player:hasSkill(self) then
				room:sendCompulsoryTriggerLog(player,self:objectName())
				player:peiyin("keolgoude")
				player:drawCards(3,self:objectName())
				local damage = data:toDamage()
				if damage.from and damage.from:isAlive() then
					local id = room:askForCardChosen(damage.from,player,"he",self:objectName())
					if id>=0 then room:obtainCard(damage.from,id,false) end
				end
			end
		end
	end,
}
sx_mengda:addSkill(sxzhuan)

sgs.LoadTranslationTable{


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




extension_dui = sgs.Package("sxfy_dui",sgs.Package_GeneralPack)

sx_caozhen = sgs.General(extension_dui,"sx_caozhen","wei",4)
sxsidi = sgs.CreateTriggerSkill{
	name = "sxsidi",
	events = {sgs.CardResponded},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.CardResponded then
			local res = data:toCardResponse()
			if res.m_card:isKindOf("Slash") then
				for i,p in sgs.list(room:getAllPlayers())do
					if p:hasSkill(self) and p:askForSkillInvoke(self,data) then
						p:peiyin("sidi")
						p:drawCards(1,self:objectName())
					end
				end
			end
		end
	end,
}
sx_caozhen:addSkill(sxsidi)

sx_dongyun = sgs.General(extension_dui,"sx_dongyun","shu",3)
sxbingzheng = sgs.CreateTriggerSkill{
	name = "sxbingzheng",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self,target)
		return target and target:isAlive() and target:hasSkill(self)
		and target:getPhase()==sgs.Player_Finish
	end,
	on_trigger = function(self,event,player,data,room)
		local tps = sgs.SPlayerList()
		for _,p in sgs.list(room:getAlivePlayers())do
			if p:canDiscard(p,"he") then tps:append(p) end
		end
		local tp = room:askForPlayerChosen(player,tps,self:objectName(),"sxbingzheng0",true,true)
		if tp then
			room:askForDiscard(tp,self:objectName(),1,1,false,true)
			if tp:getHandcardNum()~=tp:getHp() then
				room:loseHp(player,1,true,player,self:objectName())
			end
		end
	end,
}
sx_dongyun:addSkill(sxbingzheng)
sxduliang = sgs.CreateTriggerSkill{
	name = "sxduliang",
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.Damaged then
			if player:askForSkillInvoke(self,data) then
				--player:peiyin("sheyan")
				player:drawCards(1,self:objectName())
				if player:getHp()==player:getHandcardNum() then
					room:recover(player,sgs.RecoverStruct(self:objectName(),player))
				end
			end
		end
	end,
}
sx_dongyun:addSkill(sxduliang)

sx_baosanniang = sgs.General(extension_dui,"sx_baosanniang","shu",3,false)
sxzhennan = sgs.CreateTriggerSkill{
	name = "sxzhennan",
	events = {sgs.EventPhaseStart,sgs.CardFinished},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and player:getMark("&zhennan-Clear")>0 then
				room:setPlayerMark(player,"&zhennan-Clear",0)
				if use.card:isRed() and room:getCardOwner()==nil then
					player:obtainCard(use.card)
				end
			end
		elseif player:getPhase()==sgs.Player_Start then
			for _,p in sgs.list(room:getOtherPlayers(player))do
				if p:hasSkill(self) and room:askForCard(p,".","sxzhennan0:"..player:objectName(),data,self:objectName()) then
					p:peiyin("zhennan")
					room:setPlayerMark(p,"&zhennan-Clear",1)
				end
			end
		end
	end,
}
sx_baosanniang:addSkill(sxzhennan)
sxshuyong = sgs.CreateTriggerSkill{
	name = "sxshuyong",
	events = {sgs.CardUsed,sgs.EventPhaseStart},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and player:hasFlag("CurrentPlayer") then
				if use.card:sameNameWith(player:getTag("sxshuyongName"):toString()) then
					for _,p in sgs.list(room:getOtherPlayers(player))do
						if p:hasSkill(self) and p:askForSkillInvoke(self,data) then
							p:peiyin("shuyong")
							p:drawCards(1,self:objectName())
						end
					end
				end
				player:setTag("sxshuyongName",ToData(use.card:objectName()))
			end
		elseif player:getPhase()==sgs.Player_NotActive then
			player:removeTag("sxshuyongName")
		end
	end,
}
sx_baosanniang:addSkill(sxshuyong)

sx_liuba = sgs.General(extension_dui,"sx_liuba","shu",3)
sxduanbi = sgs.CreateTriggerSkill{
	name = "sxduanbi",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self,target)
		return target and target:isAlive() and target:hasSkill(self)
		and target:getPhase()==sgs.Player_Finish
	end,
	on_trigger = function(self,event,player,data,room)
		if player:canDiscard(player,"h") and player:askForSkillInvoke(self,data) then
			player:peiyin("duanbi")
			player:throwAllHandCards(self:objectName())
			local tps = room:askForPlayersChosen(player,room:getAlivePlayers(),self:objectName(),2,2,"sxduanbi0")
			for _,p in sgs.list(tps)do
				room:doAnimate(1,player:objectName(),p:objectName())
			end
			for _,p in sgs.list(tps)do
				p:drawCards(2,self:objectName())
			end
		end
	end,
}
sx_liuba:addSkill(sxduanbi)

sx_kongrong = sgs.General(extension_dui,"sx_kongrong","qun",3)
sxlirang = sgs.CreateTriggerSkill{
	name = "sxlirang",
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseEnd},
	can_trigger = function(self,target)
		return target and target:isAlive()
		and target:getPhase()==sgs.Player_Finish
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_DiscardPile then
				local ids = player:getTag("sxlirangIds"):toIntList()
				for _,id in sgs.list(move.card_ids)do
					ids:append(id)
				end
				player:setTag("sxlirangIds",ToData(ids))
			end
		else
			local ids = player:getTag("sxlirangIds"):toIntList()
			for _,p in sgs.list(room:getOtherPlayers(player))do
				if p:hasSkill(self) then
					local dc = dummyCard()
					for _,id in sgs.list(ids)do
						local c = sgs.Sanguosha:getCard(id)
						if c:isRed() and room:getCardOwner(id)==nil then
							dc:addSubcard(id)
						end
					end
					if dc:subcardsLength()>0 then
						room:fillAG(dc:getSubcards(),p)
						local sc = room:askForExchange(p,self:objectName(),1,1,true,"sxlirang0:"..player:objectName(),true)
						if sc then
							p:peiyin("lirang")
							p:skillInvoked(self,0)
							player:obtainCard(sc,false)
							room:obtainCard(p,dc)
						end
						room:clearAG(p)
					end
				end
			end
			player:removeTag("sxlirangIds")
		end
	end,
}
sx_kongrong:addSkill(sxlirang)

sx_zoushi = sgs.General(extension_dui,"sx_zoushi","qun",3,false)
sxhuoshui = sgs.CreateTriggerSkill{
	name = "sxhuoshui",
	events = {sgs.DamageForseen},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.DamageForseen and player:getJudgingArea():length()>0 then
			local damage = data:toDamage()
			for _,p in sgs.list(room:getOtherPlayers(player))do
				if p:hasSkill(self) then
					p:peiyin("huoshoug")
					room:sendCompulsoryTriggerLog(p,self:objectName())
					player:damageRevises(data,1)
				end
			end
		end
	end,
}
sx_zoushi:addSkill(sxhuoshui)
sxqingchengCard = sgs.CreateSkillCard{
	name = "sxqingchengCard",
	target_fixed = false,
	mute = true;
	filter = function(self,targets,to_select,source)
		if #targets<1 and to_select~=source then
			local dc = dummyCard("indulgence")
			dc:addSubcard(self:getSubcards():first())
			if source:isLocked(dc) or source:isProhibited(source,dc) then return end
			dc = dummyCard("indulgence")
			dc:addSubcard(self:getSubcards():last())
			if source:isLocked(dc) or source:isProhibited(to_select,dc) then return end
			return true
		end
	end,
	about_to_use = function(self,room,use)
		use.from:peiyin("qingcheng")
		local dc = dummyCard("indulgence")
		dc:addSubcards(self:getSubcards():first())
		dc:setSkillName("sxqingcheng")
		if use.from:canUse(dc,use.from) then
			room:useCard(sgs.CardUseStruct(dc,use.from,use.from))
		end
		dc = dummyCard("indulgence")
		dc:addSubcards(self:getSubcards():last())
		dc:setSkillName("sxqingcheng")
		if use.from:canUse(dc,use.to:last()) then
			room:useCard(sgs.CardUseStruct(dc,use.from,use.to))
		end
	end,
}
sxqingcheng = sgs.CreateViewAsSkill{
	name = "sxqingcheng",
	n = 2,
	view_filter = function(self,selected,to_select)
        return to_select:isRed() and to_select:getTypeId()~=2
	end,
	view_as = function(self,cards)
		if #cards > 1 then
			local sc = sxqingchengCard:clone()
			for _,c in sgs.list(cards)do
				sc:addSubcard(c)
			end
			return sc
		end
	end,
	enabled_at_play = function(self,player)
		return player:getCardCount()>1
		and player:usedTimes("#sxqingchengCard")<1
	end,
}
sx_zoushi:addSkill(sxqingcheng)

sx_sunluyu = sgs.General(extension_dui,"sx_sunluyu","wu",3,false)
sxmumu = sgs.CreateTriggerSkill{
	name = "sxmumu",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self,target)
		return target and target:isAlive() and target:hasSkill(self)
		and target:getPhase()==sgs.Player_Start
	end,
	on_trigger = function(self,event,player,data,room)
		if player:canDiscard(player,"h") then
			player:peiyin("duanbi")
			local tps = sgs.SPlayerList()
			for _,p in sgs.list(room:getAlivePlayers())do
				local es = p:getEquips()
				if es:length()<1 then continue end
				for _,q in sgs.list(room:getAlivePlayers())do
					for _,e in sgs.list(es)do
						local n = e:getRealCard():toEquipCard():location()
						if q:hasEquipArea(n) and q:getEquip(n)==nil then
							tps:append(p)
							break
						end
					end
				end
			end
			if tps:length()>0 and room:askForCard(player,".","sxmumu0",data,self:objectName()) then
				player:peiyin("mumu")
				local tp = room:askForPlayerChosen(player,tps,"sxmumu1")
				room:doAnimate(1,player:objectName(),tp:objectName())
				local ids = sgs.IntList()
				for _,q in sgs.list(room:getAlivePlayers())do
					for _,e in sgs.list(tp:getEquips())do
						local n = e:getRealCard():toEquipCard():location()
						if q:hasEquipArea(n) and q:getEquip(n)==nil then
						else ids:append(e:getId()) end
					end
				end
				local id = room:askForCardChosen(player,tp,"e",self:objectName(),false,sgs.Card_MethodNone,ids)
				if id<0 then return end
				tps:clear()
				local e = sgs.Sanguosha:getCard(id)
				for _,q in sgs.list(room:getAlivePlayers())do
					local n = e:getRealCard():toEquipCard():location()
					if q:hasEquipArea(n) and q:getEquip(n)==nil then tps:append(q) end
				end
				local tp2 = room:askForPlayerChosen(player,tps,"sxmumu2")
				if tp2 then
					room:doAnimate(1,player:objectName(),tp2:objectName())
					room:moveCardTo(e,tp2,sgs.Player_PlaceEquip,true)
				end
			end
		end
	end,
}
sx_sunluyu:addSkill(sxmumu)
sxmeibu = sgs.CreateTriggerSkill{
	name = "sxmeibu",
	events = {sgs.CardUsed},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:getWeapon()
			and player:canDiscard(player,"h") then
				for _,p in sgs.list(room:getAllPlayers())do
					if p:hasSkill(self) and p:askForSkillInvoke(self,player) then
						p:peiyin("meibu")
						room:askForDiscard(player,self:objectName(),1,1)
					end
				end
			end
		end
	end,
}
sx_sunluyu:addSkill(sxmeibu)

sx_zhoufang = sgs.General(extension_dui,"sx_zhoufang","wu",3)
sxqijianCard = sgs.CreateSkillCard{
	name = "sxqijianCard",
	target_fixed = false,
	mute = true;
	filter = function(self,targets,to_select,source)
		return #targets<1 or #targets<2 and targets[1]:getHandcardNum()==to_select:getHandcardNum()
	end,
	feasible = function(self,targets)
		return #targets == 2
	end,
	on_use = function(self,room,player,targets)
		player:peiyin("duanfa")
		for i,p in sgs.list(targets)do
			local n = 2
			if i==2 then n = 1 end
			local tp = targets[n]
			if p:canDiscard(tp,"he") and room:askForChoice(p,"sxqijian","sxqijian1+sxqijian2",ToData(tp))=="sxqijian1" then
				n = room:askForCardChosen(p,tp,"he","sxqijian",false,sgs.Card_MethodDiscard)
				if n>=0 then room:throwCard(id,"sxqijian",tp,p) end
			else
				tp:drawCards(1,"sxqijian")
			end
		end
	end
}
sxqijianVS = sgs.CreateViewAsSkill{
	name = "sxqijian",
	response_pattern = "@@sxqijian",
	view_as = function(self,cards)
		return sxqijianCard:clone()
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
sxqijian = sgs.CreateTriggerSkill{
	name = "sxqijian",
	events = {sgs.EventPhaseStart},
	view_as_skill = sxqijianVS;
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Start then
			room:askForUseCard(player,"@@sxqijian","sxqijian0")
		end
	end,
}
sx_zhoufang:addSkill(sxqijian)
sxyoudiVS = sgs.CreateViewAsSkill{
	name = "sxyoudi",
	response_pattern = "@@sxyoudi",
	n = 1,
	view_filter = function(self,selected,to_select)
        return to_select:isRed()
	end,
	view_as = function(self,cards)
		if #cards > 0 then
			local sc = sgs.Sanguosha:cloneCard("snatch")
			sc:setSkillName(self:objectName())
			for _,c in sgs.list(cards)do
				sc:addSubcard(c)
			end
			return sc
		end
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
sxyoudi = sgs.CreateTriggerSkill{
	name = "sxyoudi",
	events = {sgs.EventPhaseStart},
	view_as_skill = sxyoudiVS;
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Finish then
			room:askForUseCard(player,"@@sxyoudi","sxyoudi0")
		end
	end,
}
sx_zhoufang:addSkill(sxyoudi)

sgs.LoadTranslationTable{



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

extension_qinglong = sgs.Package("sxfy_qinglong",sgs.Package_GeneralPack)


sx_nanhua = sgs.General(extension_qinglong,"sx_nanhua","qun",3)
sxxianluCard = sgs.CreateSkillCard{
	name = "sxxianluCard",
	target_fixed = false,
	filter = function(self,targets,to_select,source)
		return #targets<1 and source:canDiscard(to_select,"e")
	end,
	on_use = function(self,room,player,targets)
		for i,p in sgs.list(targets)do
			local id = room:askForCardChosen(player,p,"e","sxxianlu",false,sgs.Card_MethodDiscard)
			if id>=0 then
				room:throwCard(id,"sxxianlu",p,player)
				local dc = dummyCard("indulgence","sxxianlu")
				dc:addSubcard(id)
				if dc:isRed() and not player:isProhibited(player,dc) then
					room:moveCardTo(dc,player,sgs.Player_PlaceTable)
					local tps = sgs.SPlayerList()
					tps:append(player)
					dc:use(room,player,tps)
					room:damage(sgs.DamageStruct("sxxianlu",player,p))
				end
			end
		end
	end
}
sxxianlu = sgs.CreateViewAsSkill{
	name = "sxxianlu",
	view_as = function(self,cards)
		return sxxianluCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#sxxianluCard")<1
	end,
}
sx_nanhua:addSkill(sxxianlu)
sxtianshu = sgs.CreateMaxCardsSkill{
    name = "sxtianshu",
	extra_func = function(self,target)
        local x = 0
		if target:hasSkill("sxtianshu") then
	       	local ks = {target:getKingdom()}
			for _,p in sgs.list(target:getAliveSiblings())do
				if table.contains(ks,p:getKingdom()) then continue end
				table.insert(ks,p:getKingdom())
			end
			x = x+#ks-1
		end
		return x
	end 
}
sx_nanhua:addSkill(sxtianshu)

sx_zerong = sgs.General(extension_qinglong,"sx_zerong","qun",4)
sxcansi = sgs.CreateTriggerSkill{
	name = "sxcansi",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Start and player:getCardCount()>0 then
			local tps = sgs.SPlayerList()
			for _,p in sgs.list(room:getAlivePlayers())do
				if player:inMyAttackRange(p)
				then tps:append(p) end
			end
			if tps:length()<1 then return end
			room:sendCompulsoryTriggerLog(player,self)
			local tp = room:askForPlayerChosen(player,tps,self:objectName(),"sxcansi0")
			room:doAnimate(1,player:objectName(),tp:objectName())
			local id = room:askForCardChosen(tp,player,"he",self:objectName())
			room:obtainCard(tp,id,false)
			local dc = dummyCard(nil,"_sxcansi")
			if player:isAlive() and tp:isAlive() and player:canSlash(tp,dc,false) then
				room:useCard(sgs.CardUseStruct(dc,player,tp))
			end
			dc = dummyCard("duel","_sxcansi")
			if player:isAlive() and tp:isAlive() and player:canUse(dc,tp) then
				room:useCard(sgs.CardUseStruct(dc,player,tp))
			end
		end
	end,
}
sx_zerong:addSkill(sxcansi)

sx_pangdegong = sgs.General(extension_qinglong,"sx_pangdegong","qun",3)
sxlingjian = sgs.CreateTriggerSkill{
	name = "sxlingjian",
	events = {sgs.CardFinished},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				player:addMark("sxlingjianUse-Clear")
				if uae.card:hasFlag("DamageDone") then return end
				if player:getMark("sxlingjianUse-Clear")==1 and player:hasSkill(self) then
					room:sendCompulsoryTriggerLog(player,self)
					if player:hasSkill("sxmingshi",true) and player:getMark("@sxmingshi")<1 then
						room:addPlayerMark(player,"@sxmingshi")
					end
				end
			end
		end
	end,
}
sx_pangdegong:addSkill(sxlingjian)
sxmingshiCard = sgs.CreateSkillCard{
	name = "sxmingshiCard",
	target_fixed = true,
	on_use = function(self,room,player,targets)
		room:removePlayerMark(player,"@sxmingshi")
		local choices = {"sxmingshi1"}
		if player:isWounded() then
			table.insert(choices,"sxmingshi2")
		end
		table.insert(choices,"sxmingshi3")
		for _,p in sgs.list(room:getAlivePlayers())do
			for _,c in sgs.list(p:getCards("ej"))do
				for _,q in sgs.list(room:getAlivePlayers())do
					if p:isProhibited(q,c) then continue end
					if c:isKindOf("EquipCard") then
						local n = c:getRealCard():toEquipCard():location()
						if q:getEquip(n) then continue end
					end
					table.insert(choices,"sxmingshi4")
					break
				end
				if table.contains(choices,"sxmingshi4")
				then break end
			end
			if table.contains(choices,"sxmingshi4")
			then break end
		end
		local choice = room:askForChoice(player,"sxmingshi",table.concat(choices,"+"))
		if choice=="sxmingshi1" then
			player:drawCards(2,"sxmingshi")
		end
		if choice=="sxmingshi2" then
			room:recover(player,sgs.RecoverStruct("sxmingshi",player))
		end
		if choice=="sxmingshi3" then
			local tp = room:askForPlayerChosen(player,room:getAlivePlayers(),"sxmingshi3","sxmingshi3")
			room:damage(sgs.DamageStruct("sxmingshi",player,tp))
		end
		if choice=="sxmingshi4" then
			room:moveField(player,"sxmingshi",false,"ej")
		end
	end
}
sxmingshi = sgs.CreateViewAsSkill{
	name = "sxmingshi",
	limit_mark = "@sxmingshi",
	frequency = sgs.Skill_Limited,
	view_as = function(self,cards)
		return sxmingshiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@sxmingshi")>0
	end,
}
sx_pangdegong:addSkill(sxmingshi)

sx_yangbiao = sgs.General(extension_qinglong,"sx_yangbiao","qun",3)
sxyizheng = sgs.CreateTriggerSkill{
	name = "sxyizheng",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Start then
			local tps = sgs.SPlayerList()
			for _,p in sgs.list(room:getAlivePlayers())do
				if player:getHp()<=p:getHp() and player:canPindian(p)
				then tps:append(p) end
			end
			local tp = room:askForPlayerChosen(player,tps,self:objectName(),"sxyizheng0",true,true)
			if tp then
				player:peiyin("yizheng")
				local n = player:pindianInt(tp,self:objectName())
				if n>0 then
					room:damage(sgs.DamageStruct(self:objectName(),player,tp))
				elseif n<0 then
					room:damage(sgs.DamageStruct(self:objectName(),tp,player))
				end
			end
		end
	end,
}
sx_yangbiao:addSkill(sxyizheng)
sxrangjie = sgs.CreateTriggerSkill{
	name = "sxrangjie",
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.Damaged then
			local tps = sgs.SPlayerList()
			for _,p in sgs.list(room:getAlivePlayers())do
				for _,c in sgs.list(p:getCards("ej"))do
					for _,q in sgs.list(room:getAlivePlayers())do
						if p:isProhibited(q,c) then continue end
						if c:isKindOf("EquipCard") then
							local n = c:getRealCard():toEquipCard():location()
							if q:getEquip(n) then continue end
						end
						tps:append(p)
						break
					end
				end
			end
			local tp = room:askForPlayerChosen(player,tps,self:objectName(),"sxrangjie0",true,true)
			if tp then
				player:peiyin("rangjie")
				local ids = sgs.IntList()
				for _,c in sgs.list(tp:getCards("ej"))do
					local has = true
					for _,q in sgs.list(room:getAlivePlayers())do
						if tp:isProhibited(q,c) then continue end
						if c:isKindOf("EquipCard") then
							local n = c:getRealCard():toEquipCard():location()
							if q:getEquip(n) then continue end
						end
						has = false
					end
					if has then ids:append(c:getId()) end
				end
				local id = room:askForCardChosen(player,tp,"ej","sxrangjie",false,sgs.Card_MethodNone,ids)
				local c = sgs.Sanguosha:getCard(id)
				tps = sgs.SPlayerList()
				for _,q in sgs.list(room:getAlivePlayers())do
					if tp:isProhibited(q,c) then continue end
					if c:isKindOf("EquipCard") then
						local n = c:getRealCard():toEquipCard():location()
						if q:getEquip(n) then continue end
					end
					tps:append(q)
				end
				local tq = room:askForPlayerChosen(player,tps,"sxrangjie1","sxrangjie1:"..c:objectName())
				room:doAnimate(1,player:objectName(),tq:objectName())
				room:moveCardTo(c,tq,room:getCardPlace(id),true)
			end
		end
	end,
}
sx_yangbiao:addSkill(sxrangjie)

sx_peixiu = sgs.General(extension_qinglong,"sx_peixiu","qun",3)
sxzhitu = sgs.CreateViewAsSkill{
	name = "sxzhitu",
	guhuo_type = "r",
	n = 999,
	view_filter = function(self,selected,to_select)
		local n = 0
		for _,c in sgs.list(selected)do
			n = n+c:getNumber()
		end
        return #selected<1 or n+to_select:getNumber()<=13
	end,
	view_as = function(self,cards)
		local n = 0
		for _,c in sgs.list(cards)do
			n = n+c:getNumber()
		end
		if #cards<2 or n~=13 then return end
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="" then
			local c = sgs.Self:getTag("sxzhitu"):toCard()
			if c then pattern = c:objectName() else return end
		end
		local sc = sgs.Sanguosha:cloneCard(pattern)
		sc:setSkillName(self:objectName())
		for _,c in sgs.list(cards)do
			sc:addSubcard(c)
		end
		return sc
	end,
	enabled_at_response = function(self,player,pattern)
		if string.find(pattern,"@@") then return end
		local dc = dummyCard(pattern)
		return dc and dc:isNDTrick() and player:getCardCount()>1
	end,
	enabled_at_play = function(self,player)
		return player:getCardCount()>1
	end,
}
sx_peixiu:addSkill(sxzhitu)

sx_baoxin = sgs.General(extension_qinglong,"sx_baoxin","qun",3)
sxyimou = sgs.CreateTriggerSkill{
	name = "sxyimou",
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.Damaged then
			if player:getCardCount()>0 then
				local ids = player:handCards()
				for _,id in sgs.list(player:getEquipsId())do
					ids:append(id)
				end
				room:askForYiji(player,ids,self:objectName(),false,false,true,1,room:getOtherPlayers(player),CardMoveReason(),"sxyimou0",true)
			end
		end
	end,
}
sx_baoxin:addSkill(sxyimou)
sxmutao = sgs.CreateTriggerSkill{
	name = "sxmutao",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Start then
			local tps = sgs.SPlayerList()
			for _,p in sgs.list(room:getOtherPlayers(player))do
				if p:getHandcardNum()>0 then tps:append(p) end
			end
			local tp = room:askForPlayerChosen(player,tps,self:objectName(),"sxmutao0",true,true)
			if tp then
				player:peiyin("mutao")
				room:showCard(tp,tp:handCards())
				for _,h in sgs.list(tp:getHandcards())do
					if h:isKindOf("Slash") then
						room:damage(sgs.DamageStruct(self:objectName(),player,tp))
						break
					end
				end
			end
		end
	end,
}
sx_baoxin:addSkill(sxmutao)

sx_huangfusong = sgs.General(extension_qinglong,"sx_huangfusong","qun",4)
sxtaoluan = sgs.CreateTriggerSkill{
	name = "sxtaoluan",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Finish then
			local tps = sgs.SPlayerList()
			for _,p in sgs.list(room:getOtherPlayers(player))do
				if p:hasSkill(self) and p:getCardCount()>0 then
					local tps = sgs.SPlayerList()
					tps:append(player)
					local ids = player:handCards()
					for _,id in sgs.list(player:getEquipsId())do
						ids:append(id)
					end
					if room:askForYiji(p,ids,self:objectName(),false,false,true,1,tps,CardMoveReason(),"sxtaoluan0"..player:objectName(),true) then
						p:peiyin("yantaoluan")
						room:showCard(player,player:handCards())
						tps = dummyCard()
						for _,h in sgs.list(player:getHandcards())do
							if h:isKindOf("Jink") and player:canDiscard(player,h:getId())
							then tps:addSubcard(h) end
						end
						room:throwCard(tps,self:objectName(),player)
					end
				end
			end
		end
	end,
}
sx_huangfusong:addSkill(sxtaoluan)

sgs.LoadTranslationTable{

	["sxfy_qinglong"] = "四象封印·青龙",



	["sx_huangfusong"] = "皇甫嵩[青]",
	["#sx_huangfusong"] = "定巾平乱",
	["illustrator:sx_huangfusong"] = "鬼画府",

	["sxtaoluan"] = "讨乱",
	[":sxtaoluan"] = "其他角色的结束阶段，你可以将一张牌交给其并展示其手牌，弃置其手牌中的【闪】。",
	["sxtaoluan0"] = "你可以发动“讨乱”将一张牌交给其他角色",

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




extension_zhencang = sgs.Package("sxfy_zhencang",sgs.Package_GeneralPack)

_zc_xuanhuafuTr = sgs.CreateTriggerSkill{
	name = "_zc_xuanhuafu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecifying},
	can_trigger = function(self,target)
		return target and target:hasWeapon("_zc_xuanhuafu")
	end,
	on_trigger = function(self,event,player,data,room)
   		if event==sgs.TargetSpecifying then
	       	local use = data:toCardUse()
	       	if use.card:isKindOf("Slash") then
	           	local tps = sgs.SPlayerList()
				for _,p in sgs.list(room:getOtherPlayers(player))do
    	           	if use.to:contains(p) then continue end
					for _,q in sgs.list(use.to)do
						if q:distanceTo(p)==1 and player:canSlash(p,use.card,false) then
							tps:append(p)
							break
						end
					end
	           	end
				local tp = room:askForPlayerChosen(player,tps,self:objectName(),"_zc_xuanhuafu0",false,true)
				if tp then
	             	room:setEmotion(player,"weapon/_zc_xuanhuafu")
                    use.to:append(tp)
					room:sortByActionOrder(use.to)
					data:setValue(use)
				end
	       	end
		end
		return false
	end
}
_zc_xuanhuafu = sgs.CreateWeapon{
	name = "_zc_xuanhuafu",
	class_name = "Xuanhuafu",
	range = 3,
	suit = 3,
	number = 5,
	equip_skill = _zc_xuanhuafuTr,
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,_zc_xuanhuafuTr,true,true,false)
		return false
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,"_zc_xuanhuafu",true,true)
		return false
	end,
}
_zc_xuanhuafu:setParent(extension_zhencang)

zc_zhengcong = sgs.General(extension_zhencang,"zc_zhengcong","qun",4,false)
zcqiyue = sgs.CreateTriggerSkill{
	name = "zcqiyue",
	events = {sgs.GameStart},
	waked_skills = "_zc_xuanhuafu",
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.GameStart then
			for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true))do
				if room:getCardOwner(id) then continue end
				local c = sgs.Sanguosha:getCard(id)
				if c:isKindOf("Xuanhuafu") then
					room:sendCompulsoryTriggerLog(player,self)
					player:obtainCard(c)
					break
				end
			end
		end
	end,
}
zc_zhengcong:addSkill(zcqiyue)
zcjieji = sgs.CreateTriggerSkill{
	name = "zcjieji",
	events = {sgs.Damage,sgs.PreCardUsed},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("zcjiejiSlash") and damage.to~=player and damage.to:isAlive()
			and damage.to:getCardCount()>0 and player:hasSkill(self) and player:askForSkillInvoke(self,damage.to) then
				local id = room:askForCardChosen(player,damage.to,"he",self:objectName())
				if(id>=0)then
					room:obtainCard(player,id,false)
					local dc = dummyCard(nil,"_zcjieji")
					if(damage.to:canSlash(player,dc,false))then
						room:useCard(sgs.CardUseStruct(dc,damage.to,player))
					end
				end
			end
		else
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				player:addMark("zcjiejiSlash")
				if(player:getMark("zcjiejiSlash")==1)then
					room:setCardFlag(use.card,"zcjiejiSlash")
				end
			end
		end
	end,
}
zc_zhengcong:addSkill(zcjieji)

_zc_baipishuangbiTr = sgs.CreateTriggerSkill{
	name = "_zc_baipishuangbi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified,sgs.ConfirmDamage},
	can_trigger = function(self,target)
		return target and target:hasWeapon("_zc_baipishuangbi")
	end,
	on_trigger = function(self,event,player,data,room)
   		if event==sgs.TargetSpecified then
	       	local use = data:toCardUse()
	       	if use.card:isKindOf("Slash") then
				local can = true
				for _,p in sgs.list(use.to)do
    	           	if p:getGender()~=player:getGender() and player:isKongcheng() then
						if can then
							can = false
							room:setEmotion(player,"weapon/_zc_baipishuangbi")
							room:sendCompulsoryTriggerLog(player,self)
						end
						room:setCardFlag(use.card,"Baipishuangbi"..p:objectName())
					end
	           	end
	       	end
		else
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("Baipishuangbi"..damage.to:objectName()) then
				player:damageRevises(data,1)
			end
		end
		return false
	end
}
_zc_baipishuangbi = sgs.CreateWeapon{
	name = "_zc_baipishuangbi",
	class_name = "Baipishuangbi",
	range = 1,
	suit = 0,
	number = 2,
	equip_skill = _zc_baipishuangbiTr,
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,_zc_baipishuangbiTr,true,true,false)
		return false
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,"_zc_baipishuangbi",true,true)
		return false
	end,
}
_zc_baipishuangbi:setParent(extension_zhencang)

zc_jiangjie = sgs.General(extension_zhencang,"zc_jiangjie","qun",3,false)
zcfengzhan = sgs.CreateTriggerSkill{
	name = "zcfengzhan",
	events = {sgs.GameStart},
	waked_skills = "_zc_baipishuangbi",
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.GameStart then
			for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true))do
				if room:getCardOwner(id) then continue end
				local c = sgs.Sanguosha:getCard(id)
				if c:isKindOf("Baipishuangbi") then
					room:sendCompulsoryTriggerLog(player,self)
					player:obtainCard(c)
					break
				end
			end
		end
	end,
}
zc_jiangjie:addSkill(zcfengzhan)
zcruixivs = sgs.CreateViewAsSkill{
	name = "zcruixi",
	response_pattern = "@@zcruixi",
	n = 1,
	view_as = function(self,cards)
		if #cards>0 then
			local dc = sgs.Sanguosha:cloneCard("slash")
			dc:setSkillName(self:objectName())
			dc:addSubcard(cards[1])
			return dc
		end
	end,
}
zcruixi = sgs.CreateTriggerSkill{
	name = "zcruixi",
	view_as_skill = zcruixivs;
	events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Finish then
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:getMark("zcruixiHas-Clear")>0 and p:hasSkill(self) and p:getCardCount()>0 then
						room:askForUseCard(p,"@@zcruixi","zcruixi0")
					end
				end
			end
		else
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
				if move.from:objectName()==player:objectName() and (move.from~=move.to or move.to_place~=sgs.Player_PlaceHand and move.to_place~=sgs.Player_PlaceEquip)
				then player:addMark("zcruixiHas-Clear") end
			end
		end
	end,
}
zc_jiangjie:addSkill(zcruixi)

zc_zhangmeiren = sgs.General(extension_zhencang,"zc_zhangmeiren","wu",3,false)
zclianrong = sgs.CreateTriggerSkill{
	name = "zclianrong",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_DiscardPile and move.from and move.from:objectName()~=player:objectName()
			and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD then
				local ids = sgs.IntList()
				for _,id in sgs.qlist(move.card_ids)do
					local c = sgs.Sanguosha:getCard(id)
					if c:getSuit()==2 and room:getCardOwner(id)==nil
					then ids:append(id) end
				end
				if ids:length()>0 then
					room:fillAG(ids,player)
					if player:askForSkillInvoke(self) then
						local aps = sgs.SPlayerList()
						aps:append(player)
						local dc = dummyCard()
						while(ids:length()>0)do
							local id = room:askForAG(player,ids,true,self:objectName(),"zclianrong0")
							if id<0 then break end
							ids:removeOne(id)
							room:takeAG(player,id,false,aps)
							dc:addSubcard(id)
						end
						player:obtainCard(dc)
					end
					room:clearAG(player)
				end
			end
		end
	end,
}
zc_zhangmeiren:addSkill(zclianrong)
zcyuanzhuoCard = sgs.CreateSkillCard{
	name = "zcyuanzhuoCard",
	target_fixed = false,
	filter = function(self,targets,to_select,source)
		return #targets<1 and to_select~=source
		and source:canDiscard(to_select,"he")
	end,
	on_use = function(self,room,player,targets)
		for i,p in sgs.list(targets)do
			local id = room:askForCardChosen(player,p,"he","zcyuanzhuo",false,sgs.Card_MethodDiscard)
			if id>=0 then
				room:throwCard(id,"zcyuanzhuo",p,player)
				local dc = dummyCard("fire_attack","_zcyuanzhuo")
				if p:canUse(dc,player) then
					room:useCard(sgs.CardUseStruct(dc,p,player))
				end
			end
		end
	end
}
zcyuanzhuo = sgs.CreateViewAsSkill{
	name = "zcyuanzhuo",
	view_as = function(self,cards)
		return zcyuanzhuoCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#zcyuanzhuoCard")<1
	end,
}
zc_zhangmeiren:addSkill(zcyuanzhuo)

zc_wangmeiren = sgs.General(extension_zhencang,"zc_wangmeiren","wu",3,false)
zcbizunVS = sgs.CreateViewAsSkill{
	name = "zcbizun",
	n = 1,
	view_filter = function(self,selected,to_select)
        return to_select:isKindOf("EquipCard")
	end,
	view_as = function(self,cards)
		if #cards > 0 then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern=="" then pattern = "slash" end
			for _,p in sgs.list(pattern:split("+"))do
				if p=="jink" or p=="slash" then
					local sc = sgs.Sanguosha:cloneCard(p)
					sc:setSkillName(self:objectName())
					for _,c in sgs.list(cards)do
						sc:addSubcard(c)
					end
					return sc
				end
			end
		end
	end,
	enabled_at_response = function(self,player,pattern)
		return player:getMark("zcbizunBan-Clear")<1
		and (string.find(pattern,"slash") or string.find(pattern,"jink"))
	end,
	enabled_at_play = function(self,player)
		return player:getMark("zcbizunBan-Clear")<1
		and dummyCard():isAvailable(player)
	end,
}
zcbizun = sgs.CreateTriggerSkill{
	name = "zcbizun",
	events = {sgs.PreCardUsed,sgs.CardFinished},
	view_as_skill = zcbizunVS;
	on_trigger = function(self,event,player,data,room)
		if event == PreCardUsed then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),self:objectName()) then
				room:addPlayerMark(player,"zcbizunBan-Clear")
			end
		else
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),self:objectName()) then
				for _,p in sgs.qlist(room:getAlivePlayers())do
					local has = true
					for _,q in sgs.qlist(room:getOtherPlayers(p))do
						if q:getHandcardNum()>=p:getHandcardNum()
						then has = false end
					end
					if has then
						if(room:canMoveField("ej"))then
							room:moveField(p,self:objectName(),true,"ej")
						end
						break
					end
				end
			end
		end
	end,
}
zc_wangmeiren:addSkill(zcbizun)
zcqiangong = sgs.CreateTriggerSkill{
	name = "zcqiangong",
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceDelayedTrick) or move.from_places:contains(sgs.Player_PlaceEquip) then
				if move.from:objectName()==player:objectName() and player:getCards("ej"):length()<1 then
					room:sendCompulsoryTriggerLog(player,self)
					player:drawCards(1,self:objectName())
				end
			end
		end
	end,
}
zc_wangmeiren:addSkill(zcqiangong)

zc_maohuanghou = sgs.General(extension_zhencang,"zc_maohuanghou","wei",3,false)
zcdechong = sgs.CreateTriggerSkill{
	name = "zcdechong",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Start then
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p:hasSkill(self) and p:getCardCount()>0 then
						local dc = room:askForExchange(p,self:objectName(),99,1,true,"zcdechong0:"..player:objectName(),true)
						if dc then
							p:skillInvoked(self,-1)
							room:giveCard(p,player,dc,self:objectName())
							room:setPlayerMark(player,"&zcdechong+#"..p:objectName().."-Clear",1)
						end
					end
				end
			elseif player:getPhase()==sgs.Player_Discard then
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if player:getMark("&zcdechong+#"..p:objectName().."-Clear")>0
					and player:getHandcardNum()>=player:getHp() and p:askForSkillInvoke(self,player,false) then
						room:damage(sgs.DamageStruct(self:objectName(),p,player))
					end
				end
			end
		end
	end,
}
zc_maohuanghou:addSkill(zcdechong)
zcyinzu = sgs.CreateAttackRangeSkill{
	name = "zcyinzu",
    extra_func = function(self,target)
		for _,p in sgs.qlist(target:getAliveSiblings(true))do
			if p:hasSkill(self) then
				if target:getHandcardNum()>target:getHp()
				then return 1 else return -1 end
			end
		end
	end,
}
zc_maohuanghou:addSkill(zcyinzu)

zc_caoxiong = sgs.General(extension_zhencang,"zc_caoxiong","wei",3)
zcwuweiCard = sgs.CreateSkillCard{
	name = "zcwuweiCard",
	target_fixed = false,
	filter = function(self,targets,to_select,source)
		local sc = sgs.Sanguosha:getCard(self:getEffectiveId())
		return #targets<1 and not source:isProhibited(to_select,sc)
	end,
	on_use = function(self,room,player,targets)
		for _,p in sgs.list(targets)do
			local n = p:getAttackRange()
			InstallEquip(self:getEffectiveId(),player,"zcwuwei",p)
			n = p:getAttackRange()-n
			if n>0 and player:canDiscard(p,"he") then
				local ids = sgs.IntList()
				for i=1,n do
					local id = room:askForCardChosen(player,p,"he","zcwuwei",false,sgs.Card_MethodDiscard,ids)
					if id<0 then break end
					ids:append(id)
					if ids:length()>=p:getCardCount()
					then break end
				end
				room:throwCard(ids,"zcwuwei",p,player)
			end
		end
	end
}
zcwuweiVS = sgs.CreateViewAsSkill{
	name = "zcwuwei",
	n = 1,
	response_pattern = "@@zcwuwei",
	view_filter = function(self,selected,to_select)
        return to_select:isKindOf("EquipCard")
	end,
	view_as = function(self,cards)
		if #cards > 0 then
			local sc = zcwuweiCard:clone()
			sc:addSubcard(cards[1])
			return sc
		end
	end,
}
zcwuwei = sgs.CreateTriggerSkill{
	name = "zcwuwei",
	events = {sgs.Damaged},
	view_as_skill = zcwuweiVS,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.Damaged then
			if player:getCardCount()>0 then
				room:askForUseCard(player,"@@zcwuwei","zcwuwei0")
			end
		end
	end,
}
zc_caoxiong:addSkill(zcwuwei)
zcleiruo = sgs.CreateTriggerSkill{
	name = "zcleiruo",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Finish then
				local tps = sgs.SPlayerList()
				for i,p in sgs.list(room:getOtherPlayers(player))do
					if p:hasEquip() then tps:append(p) end
				end
				local tp = room:askForPlayerChosen(player,tps,self:objectName(),"zcleiruo0",true,true)
				if tp then
					local id = room:askForCardChosen(player,tp,"e",self:objectName())
					room:obtainCard(player,id)
					local dc = dummyCard(nil,"_zcleiruo")
					if tp:isAlive() and tp:canSlash(player,dc,false) and tp:askForSkillInvoke(self,player,false)
					then room:useCard(sgs.CardUseStruct(dc,tp,player)) end
				end
			end
		end
	end,
}
zc_caoxiong:addSkill(zcleiruo)

zc_huangchong = sgs.General(extension_zhencang,"zc_huangchong","shu",3)
zcjuxian = sgs.CreateTriggerSkill{
	name = "zcjuxian",
	events = {sgs.BeforeCardsMove},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) then
				if move.to_place==sgs.Player_PlaceHand or move.to_place==sgs.Player_PlaceEquip then
					if move.from:objectName()==player:objectName() and move.from~=move.to then
						room:sendCompulsoryTriggerLog(player,self)
						move:removeCardIds(move.card_ids)
						data:setValue(move)
					end
				end
			end
		end
	end,
}
zc_huangchong:addSkill(zcjuxian)
zclijun = sgs.CreateTriggerSkill{
	name = "zclijun",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Start then
				local tps = sgs.SPlayerList()
				for i,p in sgs.qlist(room:getAlivePlayers())do
					if p:getHandcardNum()>0 then tps:append(p) end
				end
				tps = room:askForPlayersChosen(player,tps,self:objectName(),0,player:getHp(),"zcleiruo0:"..player:getHp(),true,true)
				local p2id = {}
				for i,p in sgs.qlist(tps)do
					local id = room:askForCardChosen(player,p,"h",self:objectName())
					p2id[p:objectName()] = id
					room:showCard(p,id)
				end
				for i,p in sgs.list(tps)do
					local c = sgs.Sanguosha:getCard(p2id[p:objectName()])
					if p:hasCard(c) then
						if c:isAvailable(p) and room:askForUseCard(p,c:toString(),"zclijun1:"..c:objectName()) then
						else room:throwCard(c,self:objectName(),p) end
					end
				end
			end
		end
	end,
}
zc_huangchong:addSkill(zclijun)

zc_panglin = sgs.General(extension_zhencang,"zc_panglin","shu",3)
zczhuying = sgs.CreateTriggerSkill{
	name = "zczhuying",
	events = {sgs.DamageInflicted},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.nature==sgs.DamageStruct_Normal then
				for i,p in sgs.qlist(room:getAllPlayers())do
					if not damage.to:isChained() and p:hasSkill(self)
					and p:askForSkillInvoke(self,damage.to) then
						room:setPlayerChained(damage.to)
					end
				end
			end
		end
	end,
}
zc_panglin:addSkill(zczhuying)
zczhongshi = sgs.CreateTriggerSkill{
	name = "zczhongshi",
	events = {sgs.DamageCaused},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.to:isChained()~=player:isChained() then
				room:sendCompulsoryTriggerLog(player,self)
				player:damageRevises(data,1)
			end
		end
	end,
}
zc_panglin:addSkill(zczhongshi)

sgs.LoadTranslationTable{

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




















return {extension_li,extension_zhen,extension_gen,extension_kun,extension_xun,
extension_kan,extension_qian,extension_dui,extension_qinglong,extension_zhencang}