extension = sgs.Package("olclan")

local ol_clans = {}
--- 判斷兩名玩家是否屬於同一宗族 (Clan)
--- 
--- **判定邏輯**：
--- 1. **身分一致性**：若兩者為同一名玩家物件，回傳 `true`。
--- 2. **宗族表比對**：遍歷 `ol_clans` 全域表。
--- 3. **後綴匹配**：利用 `endsWith` 檢查武將主將名（GeneralName）。
---    - 若 `first` 匹配到某宗族 A 的成員後綴，則檢查 `second` 是否也匹配該宗族 A 的成員後綴。
---
--- **注意**：此函數極度依賴全域變數 `ol_clans` 的結構（預期為 `table<string, string[]>`）。
---
---@param first ServerPlayer 第一名待檢查的玩家
---@param second ServerPlayer 第二名待檢查的玩家
---@return boolean 是否屬於同一宗族
function isSameClan(first, second)
	if first:objectName() == second:objectName() then
		return true
	end
	for c, gs in pairs(ol_clans) do
		for _, gn in ipairs(gs) do
			if first:getGeneralName():endsWith(gn) then
				for _, gn2 in ipairs(gs) do
					if second:getGeneralName():endsWith(gn2) then
						return true
					end
				end
				return false
			end
		end
	end
	return false
end

--==颍川·钟氏==--

ol_clans.yingchuan_zhong = { "zhonghui" }
zu_zhonghui = sgs.General(extension, "zu_zhonghui", "wei", 4, true, false, false, 3)
zuyuzhi = sgs.CreateTriggerSkillV2 {
	name = "zuyuzhi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.RoundStart, sgs.RoundEnd, sgs.CardUsed },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.RoundStart and not player:isKongcheng() then
			room:sendCompulsoryTriggerLog(player, skill)
			local dc = room:askForExchange(player, skill:objectName(), 1, 1, false, "yuzhishow", false)
			local card = sgs.Sanguosha:getCard(dc:getEffectiveId())
			room:showCard(player, dc:getEffectiveId())
			local x = card:nameLength()
			player:drawCards(x, skill:objectName())
			room:setPlayerMark(player, "zuyuzhiDraw_lun", x)
			room:setPlayerMark(player, "&zuyuzhi_lun", x)
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId() > 0 then
				room:addPlayerMark(player, "yuzhiUse_lun")
				room:removePlayerMark(player, "&zuyuzhi_lun")
			end
		elseif event == sgs.RoundEnd then
			local o = player:getMark("zuyuzhiNum")
			local u = player:getMark("yuzhiUse_lun")
			local x = player:getMark("zuyuzhiDraw_lun")
			room:setPlayerMark(player, "zuyuzhiNum", x)
			if u < x or o < x and data:toInt() > 1 then
				room:sendCompulsoryTriggerLog(player, skill)
				local choices = { "losehps" }
				if player:hasSkill("zu_zhong_baozu", true) then
					table.insert(choices, "removes_zu_zhong_baozu")
				end
				if room:askForChoice(player, "losehoorremoveskill", table.concat(choices, "+")) ~= "losehps" then
					room:detachSkillFromPlayer(player, "zu_zhong_baozu")
				else
					room:loseHp(player, 1, true, player, skill:objectName())
				end
			end
		end
	end,
}
zuxieshu = sgs.CreateTriggerSkillV2 {
	name = "zuxieshu",
	events = { sgs.Damage, sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if damage.card and damage.card:getTypeId() > 0 then
			local n = damage.card:nameLength()
			if room:askForDiscard(player, skill:objectName(), n, n, true, true, "zuxieshuask:" .. n .. ":" .. player:getLostHp(), ".", skill:objectName()) then
				room:broadcastSkillInvoke(skill:objectName())
				player:drawCards(player:getLostHp(), skill:objectName())
			end
		end
	end,
}
zu_zhonghui:addSkill(zuyuzhi)
zu_zhonghui:addSkill(zuxieshu)
zu_zhong_baozu = sgs.CreateTriggerSkillV2 {
	name = "zu_zhong_baozu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@zu_zhong_baozu",
	events = { sgs.Dying },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.Dying then
			local dying = data:toDying()
			if isSameClan(player, dying.who) and player:getMark("@zu_zhong_baozu") > 0 and player:askForSkillInvoke(skill:objectName(), data) then
				local n = math.random(1, 2)
				if player:getGeneralName():endsWith("zhonghui") or player:getGeneral2Name():endsWith("zhonghui") then
					n = math.random(1, 6)
				elseif player:getGeneralName():endsWith("zhongyu") or player:getGeneral2Name():endsWith("zhongyu") then
					n = n + 6
				elseif player:getGeneralName():endsWith("zhongyan") or player:getGeneral2Name():endsWith("zhongyan") then
					n = n + 8
				elseif player:getGeneralName():endsWith("zhongyao") or player:getGeneral2Name():endsWith("zhongyao") then
					n = n + 10
				end
				room:broadcastSkillInvoke(skill:objectName(), n, player)
				room:removePlayerMark(player, "@zu_zhong_baozu")
				room:doSuperLightbox(dying.who, "zu_zhong_baozu")
				room:setPlayerChained(dying.who, true)
				room:recover(dying.who, sgs.RecoverStruct("zu_zhong_baozu", player))
			end
		end
		return false
	end,
}
zu_zhonghui:addSkill(zu_zhong_baozu)
sgs.LoadTranslationTable {
	["olclan"] = "门阀士族",

	["zu_zhong_baozu"] = "保族", --<颍川·钟氏>专属宗族技
	[":zu_zhong_baozu"] = "宗族技，限定技，当同族角色进入濒死状态时，你可以令其横置并恢复1点体力。",
	["$zu_zhong_baozu1"] = "[钟会] 不为刀下脍，且做俎上刀。",
	["$zu_zhong_baozu2"] = "[钟会] 动我钟家的人，哼，你长了几个脑袋？",
	["$zu_zhong_baozu3"] = "[钟会] 吾族恒大，谁敢欺之。",
	["$zu_zhong_baozu4"] = "[钟会] 有我在一日，谁也动不得吾族分毫。",
	["$zu_zhong_baozu5"] = "[钟会] 钟门欲屹万年，当先居万人之上。",
	["$zu_zhong_baozu6"] = "[钟会] 诸位同门，随我钟会赌一遭如何？",
	["$zu_zhong_baozu8"] = "[钟毓] 会期大祸将至，请晋公恕之。",
	["$zu_zhong_baozu7"] = "[钟毓] 弟会腹有恶谋，不可不防。",
	["$zu_zhong_baozu9"] = "[钟琰] 好女宜家，可度大厄。",
	["$zu_zhong_baozu10"] = "[钟琰] 宗族有难，当施以援手。",
	["$zu_zhong_baozu11"] = "[钟繇] 立规定矩，教习钟门之才。",
	["$zu_zhong_baozu12"] = "[钟繇] 放任纨绔，于族是祸非福。",

	--[[阵亡：兵来似欲作恶，当云何？

伯约误我！

谋事在人，成事在天。 ]]

	["zu_zhonghui"] = "族钟会",
	["#zu_zhonghui"] = "百巧惎",
	["designer:zu_zhonghui"] = "玄蝶既白",
	["illustrator:zu_zhonghui"] = "官方",
	["information:zu_zhonghui"] = "宗族：[颍川·钟氏]",
	["zuyuzhi"] = "迂志",
	["yuzhishow"] = "迂志：请选择展示的牌",
	["losehoorremoveskill"] = "选择失去体力或失去宗族技",
	["losehps"] = "失去体力",
	["removes_zu_zhong_baozu"] = "失去宗族技",
	[":zuyuzhi"] = "锁定技，每轮开始时，你展示一张手牌并摸X张牌（X为此牌牌名字数）；每轮结束时，若你本轮使用牌数或上轮以此法摸牌数小于X，你失去1点体力或失去宗族技。",
	["$zuyuzhi1"] = "风水轮流转，轮到我钟某问鼎重几何了。",
	["$zuyuzhi2"] = "汉鹿已失，魏牛犹在，吾欲执其耳。",
	["$zuyuzhi3"] = "空将宝地赠他人，某怎会心甘情愿？",
	["$zuyuzhi4"] = "入宝山而空手回，其与匹夫何异？",
	["$zuyuzhi5"] = "天降大任于斯，不受必遭其殃。",
	["$zuyuzhi6"] = "我欲行夏禹旧事，为天下人。",
	["zuxieshu"] = "挟术",
	["zuxieshuask"] = "挟术：你可以弃置 %src 张牌并摸 %dest 张牌",
	[":zuxieshu"] = "当你造成或受到牌的伤害后，你可以弃置X张牌（X为此牌牌名字数）并摸你已损失体力值张牌。",
	["$zuxieshu1"] = "大丈夫胸怀四海，有提携玉龙之术。",
	["$zuxieshu2"] = "今长缨在手，欲问鼎九州。",
	["$zuxieshu3"] = "历经风浪至此，会不可止步于龙门。",
	["$zuxieshu4"] = "王霸之志在胸，我岂池中之物？",
	["$zuxieshu5"] = "我若束手无策，诸位又有何施为？",
	["$zuxieshu6"] = "我有佐国之术，可缚苍龙。",
	["~zu_zhonghui"] = "兵来似欲作恶，当云何？",
}
---------------------------------

table.insert(ol_clans.yingchuan_zhong, "zhongyu")
zu_zhongyu = sgs.General(extension, "zu_zhongyu", "wei", 3)
zujiejian = sgs.CreateTriggerSkillV2 {
	name = "zujiejian",
	events = { sgs.TargetSpecified },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		if use.card:getTypeId() > 0 then
			room:addPlayerMark(player, "&zujiejian-Clear")
			local id = use.card:getSubcards():first()
			local card = sgs.Sanguosha:getCard(id)
			local n = card:nameLength()
			if use.card:getTypeId() < 3 and n == player:getMark("&zujiejian-Clear") then
				local target = room:askForPlayerChosen(player, use.to, skill:objectName(), "zujiejian-invoke", true, true)
				if target then
					room:broadcastSkillInvoke(skill:objectName())
					target:drawCards(n, skill:objectName())
				end
			end
		end
	end,
}
zuhuanghan = sgs.CreateTriggerSkillV2 {
	name = "zuhuanghan",
	events = { sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if damage.card and damage.card:getTypeId() > 0 then
			return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		room:broadcastSkillInvoke(skill:objectName())
		local n = damage.card:nameLength()
		player:drawCards(n, skill:objectName())
		room:askForDiscard(player, skill:objectName(), player:getLostHp(), player:getLostHp(), false, true)
		room:addPlayerMark(player, "huanghan-Clear")
		if player:getMark("huanghan-Clear") > 1 and player:getMark("@zu_zhong_baozu") < 1 and player:hasSkill("zu_zhong_baozu", true) then
			room:addPlayerMark(player, "@zu_zhong_baozu")
		end
	end,
}
zu_zhongyu:addSkill(zujiejian)
zu_zhongyu:addSkill(zuhuanghan)
zu_zhongyu:addSkill("zu_zhong_baozu")
sgs.LoadTranslationTable {
	["zu_zhongyu"] = "族钟毓",
	["#zu_zhongyu"] = "础润殷忧",
	["designer:zu_zhongyu"] = "玄蝶既白",
	["illustrator:zu_zhongyu"] = "匠人绘",
	["information:zu_zhongyu"] = "宗族：[颍川·钟氏]",
	["zujiejian"] = "捷谏",
	["zujiejian-invoke"] = "你可以发动“捷谏”<br/> <b>操作提示</b>: 选择一名角色→点击确定",
	[":zujiejian"] = "当你每回合使用第X张牌指定目标后，若不为装备牌，你可以令一名目标角色摸X张牌。（X为此牌牌名字数）",
	["$zujiejian1"] = "庙胜之策，不临矢石。",
	["$zujiejian2"] = "王者之兵，有征无战。",
	["zuhuanghan"] = "惶汗",
	[":zuhuanghan"] = "当你受到一张牌造成的伤害后，你可以摸X张牌（X为此牌牌名字数）并弃置你已损失体力值张牌，若你本回合发动“惶汗”的次数大于1，你重置“保族”。",
	["$zuhuanghan1"] = "居天子阶下，故诚惶诚恐。",
	["$zuhuanghan2"] = "战战惶惶，汗出如浆。",
	["~zu_zhongyu"] = "百年钟氏，一朝为尘矣......",
}
---------------------------------

table.insert(ol_clans.yingchuan_zhong, "zhongyan")
zu_zhongyan = sgs.General(extension, "zu_zhongyan", "jin", 3, false)
zuguanguCard = sgs.CreateSkillCard {
	name = "zuguanguCard",
	--target_fixed = true,
	filter = function(self, targets, to_select, from)
		return from:getChangeSkillState("zuguangu") == 2 and #targets < 1
	end,
	feasible = function(self, targets, from)
		return from:getChangeSkillState("zuguangu") == 1 or #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local card_ids = sgs.IntList()
		if source:getChangeSkillState("zuguangu") == 1 then
			local choice = room:askForChoice(source, "zuguangunum", "1+2+3+4")
			room:setChangeSkillState(source, "zuguangu", 2)
			card_ids = room:getNCards(tonumber(choice))
			room:returnToTopDrawPile(card_ids)
		else
			room:setChangeSkillState(source, "zuguangu", 1)
			for i = 1, 4 do
				if card_ids:length() >= targets[1]:getHandcardNum() then
					break
				end
				local id = room:askForCardChosen(source, targets[1], "h", "zuguangu", false, sgs.Card_MethodNone, card_ids, i > 1)
				if id < 0 then
					break
				end
				card_ids:append(id)
			end
		end
		if card_ids:isEmpty() then
			return
		end
		room:setPlayerMark(source, "&zuguangu", card_ids:length())
		room:notifyMoveToPile(source, card_ids, "zuguangu")
		room:askForUseCard(source, "@@zuguangu", "@zuguangu:")
		room:notifyMoveToPile(source, card_ids, "zuguangu", sgs.Player_PlaceUnknown, false)
	end,
}
zuguanguvs = sgs.CreateViewAsSkillV2 {
	name = "zuguangu",
	expand_pile = "#zuguangu",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:usedTimes("#zuguanguCard") <= player:getMark("zuguanguUse-Clear")
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern():startsWith("@@zuguangu")
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		if request:getSelectedCardIds():length() >= 1 then return false end
		local player = request:getInitiator()
		return request:getPattern() == "@@zuguangu" and player:getPileName(candidate:getId()) == "#zuguangu" and candidate:isAvailable(player)
	end,
	card_selection_feasible = function(skill, request)
		if request:getPattern() == "@@zuguangu" then
			return request:getSelectedCardIds():length() >= 1
		end
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if request:getPattern() == "@@zuguangu" then
			if ids:length() < 1 then
				return nil
			end
			return sgs.Sanguosha:getCard(ids:first())
		end
		return zuguanguCard:clone()
	end,
}
zuguangu = sgs.CreateTriggerSkillV2 {
	name = "zuguangu",
	events = { sgs.EventPhaseStart },
	change_skill = true,
	view_as_skill = zuguanguvs,
	can_trigger = function(skill, event, room, player, data)
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		return false
	end,
}
zuxiaoyong = sgs.CreateTriggerSkillV2 {
	name = "zuxiaoyong",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardUsed },
	global = true,
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.card:getTypeId() > 0 and player:hasFlag("CurrentPlayer") then
			local m = use.card:nameLength()
			-- on_record 已先累計（每事件一次），此處條件等同舊版 addMark 後 < 2
			if player:getMark(m .. "zuxiaoyong-Clear") < 2 and m == player:getMark("&zuguangu") then
				local holder = room:findPlayerBySkillName(skill:objectName())
				if holder then
					return skill:objectName(), holder
				end
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 global 技能每事件只執行一次；on_record 按持有者逐一呼叫，僅首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		local use = ctx.original_data:toCardUse()
		if use.card:getTypeId() > 0 and player:hasFlag("CurrentPlayer") then
			local m = use.card:nameLength()
			player:addMark(m .. "zuxiaoyong-Clear")
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:sendCompulsoryTriggerLog(ctx.invoker, skill)
		room:addPlayerMark(ctx.invoker, "zuguanguUse-Clear")
	end,
}
zu_zhongyan:addSkill(zuguangu)
zu_zhongyan:addSkill(zuxiaoyong)
zu_zhongyan:addSkill("zu_zhong_baozu")
sgs.LoadTranslationTable {
	["zu_zhongyan"] = "族钟琰",
	["#zu_zhongyan"] = "紫闼飞莺",
	["designer:zu_zhongyan"] = "玄蝶既白",
	["illustrator:zu_zhongyan"] = "凡果",
	["information:zu_zhongyan"] = "宗族：[颍川·钟氏]",
	["zuguangu"] = "观骨",
	["zuguangunum"] = "观看牌数",
	["@zuguangu"] = "你可以使用观看的一张牌",
	["zuguangu-invoke"] = "你可以发动“观骨”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	[":zuguangu"] = "转换技，出牌阶段限一次，①你可以观看牌堆顶至多四张牌；②你可以观看一名角色至多四张手牌。然后你可以使用其中一张牌。",
	[":zuguangu1"] = '转换技，出牌阶段限一次，①你可以观看牌堆顶至多四张牌；<font color="#01A5AF"><s>②你可以观看一名角色至多四张手牌</s></font>。然后你可以使用其中一张牌。',
	[":zuguangu2"] = '转换技，出牌阶段限一次，<font color="#01A5AF"><s>①你可以观看牌堆顶至多四张牌；</s></font>②你可以观看一名角色至多四张手牌。然后你可以使用其中一张牌。',
	["#zuguangu"] = "观看牌",
	["$zuguangu1"] = "此才拔萃，然观其形骨，恐早夭。",
	["$zuguangu2"] = "绯衣者，汝所拔乎？",
	["zuxiaoyong"] = "啸咏",
	[":zuxiaoyong"] = "锁定技，当你回合内首次使用牌名字数为X的牌时（X为上次“观骨”观看牌数），你本回合发动“观骨”的次数限制+1。",
	["$zuxiaoyong1"] = "凉风萧条，露沾我衣。",
	["$zuxiaoyong2"] = "忧来多方，慨然永怀。",
	["~zu_zhongyan"] = "此间天下人，皆分一斗之才......",
}

table.insert(ol_clans.yingchuan_zhong, "zhongyao")
zu_zhongyao = sgs.General(extension, "zu_zhongyao", "wei", 3)
zuchengqiCard = sgs.CreateSkillCard {
	name = "zuchengqiCard",
	will_throw = false,
	target_fixed = true,
	on_validate_in_response = function(self, from)
		if self:getUserString():contains("+") then
			local choice = {}
			local n = 0
			for _, id in sgs.qlist(self:getSubcards()) do
				n = n + sgs.Sanguosha:getCard(id):nameLength()
			end
			for _, pn in ipairs(self:getUserString():split("+")) do
				local dc = dummyCard(pn)
				if dc:nameLength() > n then
					continue
				end
				dc:setSkillName(self:getSkillName())
				dc:addSubcards(self:getSubcards())
				if from:getMark(pn .. "zuchengqiUse-Clear") < 1 and not from:isLocked(dc) then
					table.insert(choice, pn)
				end
			end
			if #choice < 1 then
				return nil
			end
			local room = from:getRoom()
			choice = room:askForChoice(from, self:getSkillName(), table.concat(choice, "+"))
			local dc = dummyCard(choice)
			dc:setSkillName(self:getSkillName())
			dc:addSubcards(self:getSubcards())
			return dc
		end
		return self
	end,
	on_validate = function(self, use)
		if self:getUserString():contains("+") then
			local choice = {}
			local n = 0
			for _, id in sgs.qlist(self:getSubcards()) do
				n = n + sgs.Sanguosha:getCard(id):nameLength()
			end
			for _, pn in ipairs(self:getUserString():split("+")) do
				local dc = dummyCard(pn)
				if dc:nameLength() > n then
					continue
				end
				dc:setSkillName(self:getSkillName())
				dc:addSubcards(self:getSubcards())
				if use.from:getMark(pn .. "zuchengqiUse-Clear") < 1 and not use.from:isLocked(dc) then
					table.insert(choice, pn)
				end
			end
			if #choice < 1 then
				return nil
			end
			local room = use.from:getRoom()
			choice = room:askForChoice(use.from, self:getSkillName(), table.concat(choice, "+"))
			local dc = dummyCard(choice)
			dc:setSkillName(self:getSkillName())
			dc:addSubcards(self:getSubcards())
			return dc
		end
		return self
	end,
	about_to_use = function(self, room, use)
		local choice = {}
		local n = 0
		for _, id in sgs.qlist(self:getSubcards()) do
			n = n + sgs.Sanguosha:getCard(id):nameLength()
		end
		for _, pn in ipairs(patterns()) do
			local dc = dummyCard(pn)
			if dc:nameLength() > n then
				continue
			end
			if dc and (dc:isNDTrick() or dc:getTypeId() == 1) and use.from:getMark(pn .. "zuchengqiUse-Clear") < 1 then
				dc:setSkillName(self:getSkillName())
				dc:addSubcards(self:getSubcards())
				if dc:isAvailable(use.from) then
					table.insert(choice, pn)
				end
			end
		end
		if #choice < 1 then
			return
		end
		choice = room:askForChoice(use.from, self:getSkillName(), table.concat(choice, "+"))
		local dc = dummyCard(choice)
		dc:setSkillName(self:getSkillName())
		dc:addSubcards(self:getSubcards())
		room:setPlayerProperty(use.from, "zuchengqiUse", ToData(dc:toString()))
		room:askForUseCard(use.from, "@@zuchengqi", "zuchengqi0:" .. choice)
	end,
}
zuchengqiVS = sgs.CreateViewAsSkillV2 {
	name = "zuchengqi",
	n = 998,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		local pattern = request:getPattern() or ""
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:getHandcardNum() > 1
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return pattern:startsWith("@@zuchengqi")
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			for _, pn in ipairs(pattern:split("+")) do
				if player:getHandcardNum() < 2 then
					break
				end
				local dc = dummyCard(pn)
				if dc and player:getMark(pn .. "zuchengqiUse-Clear") < 1 and (dc:isNDTrick() or dc:getTypeId() == 1) then
					return true
				end
			end
			return pattern:startsWith("@@zuchengqi")
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		if request:getSelectedCardIds():length() >= 998 then return false end
		return request:getPattern() ~= "@@zuchengqi" and not candidate:isEquipped()
	end,
	card_selection_feasible = function(skill, request)
		local ids = request:getSelectedCardIds()
		local pattern = request:getPattern() or ""
		if pattern == "@@zuchengqi" then
			return ids:length() == 0
		end
		if ids:length() < 2 then
			return false
		end
		if pattern == "" or pattern:contains("+") then
			return true
		end
		local n = 0
		for i = 0, ids:length() - 1 do
			n = n + sgs.Sanguosha:getCard(ids:at(i)):nameLength()
		end
		local dc = dummyCard(pattern)
		if not dc then
			return false
		end
		return n >= dc:nameLength()
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		local pattern = request:getPattern() or ""
		if pattern == "@@zuchengqi" then
			local player = request:getInitiator()
			local dc = sgs.Card_Parse(player:property("zuchengqiUse"):toString())
			local card = sgs.Sanguosha:cloneCard(dc:objectName())
			card:setSkillName(skill:objectName())
			card:addSubcards(dc:getSubcards())
			return card
		end
		if ids:length() < 2 then
			return nil
		end
		if pattern == "" or pattern:contains("+") then
			local card = zuchengqiCard:clone()
			card:setUserString(pattern)
			for i = 0, ids:length() - 1 do
				card:addSubcard(sgs.Sanguosha:getCard(ids:at(i)))
			end
			return card
		else
			local n = 0
			for i = 0, ids:length() - 1 do
				n = n + sgs.Sanguosha:getCard(ids:at(i)):nameLength()
			end
			local card = sgs.Sanguosha:cloneCard(pattern)
			if n < card:nameLength() then
				card:deleteLater()
				return nil
			end
			card:setSkillName(skill:objectName())
			for i = 0, ids:length() - 1 do
				card:addSubcard(sgs.Sanguosha:getCard(ids:at(i)))
			end
			return card
		end
	end,
}
zuchengqi = sgs.CreateTriggerSkillV2 {
	name = "zuchengqi",
	view_as_skill = zuchengqiVS,
	events = { sgs.CardUsed },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		if use.card:getTypeId() > 0 then
			room:addPlayerMark(player, use.card:objectName() .. "zuchengqiUse-Clear")
			if table.contains(use.card:getSkillNames(), skill:objectName()) then
				local m = use.card:nameLength()
				local n = 0
				for _, id in sgs.qlist(use.card:getSubcards()) do
					n = n + sgs.Sanguosha:getCard(id):nameLength()
				end
				if n == m then
					local to = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "zuchengqi1:")
					if to then
						room:doAnimate(1, player:objectName(), to:objectName())
						to:drawCards(1, skill:objectName())
					end
				end
			end
		end
	end,
}
zu_zhongyao:addSkill(zuchengqi)
zujieliCard = sgs.CreateSkillCard {
	name = "zujieliCard",
	will_throw = false,
	target_fixed = true,
	about_to_use = function(self, room, use) end,
}
zujieliVS = sgs.CreateViewAsSkillV2 {
	name = "zujieli",
	n = 998,
	expand_pile = "#zujieliN,#zujieli",
	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return false
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern():startsWith("@@zujieli")
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		if request:getSelectedCardIds():length() >= 998 then return false end
		local player = request:getInitiator()
		local ep = player:getPileName(candidate:getEffectiveId())
		return ep == "#zujieliN" or ep == "#zujieli"
	end,
	card_selection_feasible = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() < 2 then
			return false
		end
		local player = request:getInitiator()
		local x = 0
		for i = 0, ids:length() - 1 do
			local c = sgs.Sanguosha:getCard(ids:at(i))
			if player:getPileName(c:getEffectiveId()) == "#zujieli" then
				x = x + 1
			else
				x = x - 1
			end
		end
		return x == 0
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() < 2 then
			return nil
		end
		local card = zujieliCard:clone()
		for i = 0, ids:length() - 1 do
			card:addSubcard(sgs.Sanguosha:getCard(ids:at(i)))
		end
		return card
	end,
}
zujieli = sgs.CreateTriggerSkillV2 {
	name = "zujieli",
	view_as_skill = zujieliVS,
	events = { sgs.EventPhaseStart, sgs.CardUsed },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId() > 0 then
				local m = use.card:nameLength()
				if m > player:getMark("&zujieli-Clear") then
					room:setPlayerMark(player, "&zujieli-Clear", m)
				end
			end
		elseif player:getPhase() == sgs.Player_Finish then
			local aps = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getHandcardNum() > 0 then
					aps:append(p)
				end
			end
			local target = room:askForPlayerChosen(player, aps, skill:objectName(), "zujieli0:", true, true)
			if target then
				room:broadcastSkillInvoke(skill:objectName())
				local n = 0
				for _, h in sgs.qlist(target:getHandcards()) do
					local x = h:nameLength()
					if x > n then
						n = x
					end
				end
				local ids = sgs.IntList()
				for _, h in sgs.qlist(target:getHandcards()) do
					local x = h:nameLength()
					if x >= n then
						ids:append(h:getId())
					end
				end
				n = player:getMark("&zujieli-Clear")
				local cns = room:getNCards(n, false)
				room:notifyMoveToPile(player, cns, "zujieliN", sgs.Player_DrawPile, true)
				room:notifyMoveToPile(player, ids, "zujieli", sgs.Player_PlaceHand, true)
				local dc = room:askForUseCard(player, "@@zujieli", "zujieli1:", -1, sgs.Card_MethodNone)
				room:notifyMoveToPile(player, cns, "zujieliN", sgs.Player_DrawPile, false)
				room:notifyMoveToPile(player, ids, "zujieli", sgs.Player_PlaceHand, false)
				room:returnToTopDrawPile(cns)
				if dc then
					local move1 = sgs.CardsMoveStruct()
					move1.to = target
					move1.to_place = sgs.Player_PlaceHand
					move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK, player:objectName(), target:objectName(), skill:objectName(), "")
					local move2 = sgs.CardsMoveStruct()
					move2.from = target
					move2.to = nil
					move2.to_place = sgs.Player_DrawPile
					move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName(), target:objectName(), skill:objectName(), "")
					for _, id in sgs.qlist(dc:getSubcards()) do
						if cns:contains(id) then
							move1.card_ids:append(id)
						else
							move2.card_ids:append(id)
						end
					end
					local moves = sgs.CardsMoveList()
					moves:append(move1)
					moves:append(move2)
					room:moveCardsAtomic(moves, false)
				end
			end
		end
	end,
}
zu_zhongyao:addSkill(zujieli)
zu_zhongyao:addSkill("zu_zhong_baozu")
sgs.LoadTranslationTable {
	["zu_zhongyao"] = "族钟繇",
	["#zu_zhongyao"] = "开达理干",
	--["designer:zu_zhongyao"] = "玄蝶既白",
	--["illustrator:zu_zhongyao"] = "凡果",
	["information:zu_zhongyao"] = "宗族：[颍川·钟氏]",
	["zuchengqi"] = "承启",
	["zuchengqi0"] = "承启：你可以使用【%src】",
	["zuchengqi1"] = "承启：请令一名角色摸一张牌",
	[":zuchengqi"] = "你可以将至少两张手牌当任意一张牌名字数不大于X的基本牌或普通锦囊牌使用（你本回合使用过的基本牌或普通锦囊牌除外；X为这些牌转化前的牌名字数之和），然后当你使用此牌时，若此牌的牌名字数等于X，你令一名角色摸一张牌。",
	["$zuchengqi1"] = "世有十万字形，亦当有十万字体。",
	["$zuchengqi2"] = "笔画如骨，不可拘于一形。",
	["zujieli"] = "诫厉",
	[":zujieli"] = "结束阶段，你可以观看一名角色的牌名字数最大的手牌，然后你可以用其中任意张牌交换牌堆顶的Y张牌中的等量张（Y为你本回合使用过的牌中牌名字数的最大值）。",
	["$zujieli1"] = "子不学难成其材，子不教难筑其器。",
	["$zujieli2"] = "此子顽劣如斯，必当严加管教。",
	["zujieli0"] = "诫厉：你可以观看一名角色牌名字数最大的手牌",
	["zujieli1"] = "诫厉：你可以进行牌交换",
	["#zujieli"] = "手牌",
	["#zujieliN"] = "牌堆牌",
	["~zu_zhongyao"] = "幼子得宠而无忌，恐生无妄之祸。",
}

---------------------------------
--==陈留·吴氏==--

--族吴班
ol_clans.chenliu_wu = { "wuban", "wulan" }
zu_wuban = sgs.General(extension, "zu_wuban", "shu", 4, true)
zuzhandingVS = sgs.CreateViewAsSkillV2 {
	name = "zuzhanding",
	n = 999,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return sgs.Slash_IsAvailable(player)
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "slash"
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		if request:getSelectedCardIds():length() >= 999 then return false end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:addSubcard(candidate:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(request:getInitiator())
		end
		return true
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash")
			for i = 0, ids:length() - 1 do
				slash:addSubcard(sgs.Sanguosha:getCard(ids:at(i)))
			end
			slash:setSkillName(skill:objectName())
			slash:setFlags(skill:objectName())
			return slash
		end
		return nil
	end,
}
zuzhanding = sgs.CreateTriggerSkillV2 {
	name = "zuzhanding",
	events = { sgs.CardUsed, sgs.CardFinished },
	view_as_skill = zuzhandingVS,
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(), skill:objectName()) or use.card:hasFlag(skill:objectName()) then
				room:addMaxCards(player, -1, false)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(), skill:objectName()) or use.card:hasFlag(skill:objectName()) then
				room:sendCompulsoryTriggerLog(player, skill)
				if use.card:hasFlag("DamageDone") then
					local n = player:getMaxCards() - player:getHandcardNum()
					if n > 0 then
						room:drawCards(player, n, skill:objectName())
					elseif n < 0 then
						room:askForDiscard(player, skill:objectName(), -n, -n)
					end
				else
					use.m_addHistory = false
					data:setValue(use)
				end
			end
		end
	end,
}
zu_wuban:addSkill(zuzhanding)
zu_wu_muyin = sgs.CreateTriggerSkillV2 {
	name = "zu_wu_muyin",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:getPhase() == sgs.Player_RoundStart then
			local mxc = 0
			for _, p in sgs.qlist(room:getAllPlayers()) do --计算全场手牌上限的最大值
				if p:getMaxCards() > mxc then
					mxc = p:getMaxCards()
				end
			end
			local zuwu = sgs.SPlayerList()
			for _, zw in sgs.qlist(room:getAllPlayers()) do --筛选出符合选择条件的角色
				if isSameClan(player, zw) and zw:getMaxCards() < mxc then
					zuwu:append(zw)
				end
			end
			local target = room:askForPlayerChosen(player, zuwu, skill:objectName(), "zu_wu_muyin0:", true, true)
			if target then
				local n = math.random(1, 2)
				if player:getGeneralName():endsWith("wuxian") or player:getGeneral2Name():endsWith("wuxian") then
					n = n + 2
				elseif player:getGeneralName():endsWith("wukuang") or player:getGeneral2Name():endsWith("wukuang") then
					n = n + 4
				elseif player:getGeneralName():endsWith("wuqiao") or player:getGeneral2Name():endsWith("wuqiao") then
					n = n + 6
				end
				room:broadcastSkillInvoke(skill:objectName(), n, player)
				room:addMaxCards(target, 1, false)
			end
		end
	end,
}
zu_wuban:addSkill(zu_wu_muyin)

--族吴苋
table.insert(ol_clans.chenliu_wu, "wuxian")
zu_wuxian = sgs.General(extension, "zu_wuxian", "shu", 3, false)
zuyirongCard = sgs.CreateSkillCard {
	name = "zuyirongCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local hc, mxc = source:getHandcardNum(), source:getMaxCards()
		if hc < mxc then
			room:drawCards(source, mxc - hc, "zuyirong")
			room:addMaxCards(source, -1, false)
		elseif hc > mxc then
			room:askForDiscard(source, "zuyirong", hc - mxc, hc - mxc)
			room:addMaxCards(source, 1, false)
		end
	end,
}
zuyirong = sgs.CreateViewAsSkillV2 {
	name = "zuyirong",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:usedTimes("#zuyirongCard") < 2 and player:getHandcardNum() ~= player:getMaxCards()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		return zuyirongCard:clone()
	end,
}
zu_wuxian:addSkill(zuyirong)
zuguixiang = sgs.CreateTriggerSkillV2 {
	name = "zuguixiang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local change = data:toPhaseChange()
		if change.to == sgs.Player_RoundStart or change.to == sgs.Player_NotActive then
			return false
		end
		room:addPlayerMark(player, "zuguixiang-Clear") --记录进行到了第几个阶段
		if player:getMark("zuguixiang-Clear") == player:getMaxCards() then
			room:sendCompulsoryTriggerLog(player, skill)
			change.to = sgs.Player_Play
			data:setValue(change)
		end
	end,
}
zu_wuxian:addSkill(zuguixiang)
zu_wuxian:addSkill("zu_wu_muyin")

--族吴匡
table.insert(ol_clans.chenliu_wu, "wukuang")
zu_wukuang = sgs.General(extension, "zu_wukuang", "qun", 4, true)
zulianzhu = sgs.CreateTriggerSkillV2 {
	name = "zulianzhu",
	change_skill = true,
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart, sgs.EventAcquireSkill, sgs.EventPhaseEnd },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		-- 舊版 can_trigger 不限持有者；V2 需以實際持有者為 owner，每事件取一位
		local holder = room:findPlayerBySkillName(skill:objectName())
		if holder then
			return skill:objectName(), holder
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local player = ctx.invoker
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill(skill, true) and not player:hasSkill("zulianzhuvs", true) then
					room:attachSkillToPlayer(player, "zulianzhuvs")
					break
				end
			end
		elseif event == sgs.EventAcquireSkill and player:hasSkill(skill, true) then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getPhase() == sgs.Player_Play and not p:hasSkill("zulianzhuvs", true) then
					room:attachSkillToPlayer(p, "zulianzhuvs")
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() >= sgs.Player_Play and player:hasSkill("zulianzhuvs", true) then
				room:detachSkillFromPlayer(player, "zulianzhuvs", true)
			end
		end
	end,
}
zu_wukuang:addSkill(zulianzhu)
--联诛卡--
zulianzhuCard = sgs.CreateSkillCard {
	name = "zulianzhuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if #targets == 0 then
			if self:subcardsLength() > 0 then --阳
				return to_select:hasSkill("zulianzhu") and to_select:getChangeSkillState("zulianzhu") == 1 and to_select:getCardCount() > 0
			else --阴
				return to_select:hasSkill("zulianzhu") and to_select:getChangeSkillState("zulianzhu") == 2
			end
		end
	end,
	on_use = function(self, room, source, targets)
		local zwk = targets[1]
		room:notifySkillInvoked(zwk, "zulianzhu")
		if self:subcardsLength() > 0 then
			local card2 = zwk ~= source and room:askForCard(zwk, "..!", "@zulianzhuRecast", ToData(source), sgs.Card_MethodRecast)
			local card1 = sgs.Sanguosha:getCard(self:getSubcards():first())
			local log = sgs.LogMessage()
			log.type = "#UseCard_Recast"
			log.from = source
			log.card_str = card1:toString()
			room:sendLog(log)
			room:moveCardTo(card1, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName(), "zulianzhu", ""))
			source:drawCards(1, "recast")
			if card2 then
				log.from = zwk
				log.card_str = card2:toString()
				room:sendLog(log)
				room:moveCardTo(card2, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, zwk:objectName(), "zulianzhu", ""))
				zwk:drawCards(1, "recast")
			end
			if card2 and card1:getColor() == card2:getColor() then
				room:addMaxCards(zwk, 1, false)
			end
			room:setChangeSkillState(zwk, "zulianzhu", 2)
		else
			local SlashTargets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if p == zwk then
					continue
				end
				if source:canSlash(p, nil, false) and zwk:canSlash(p, nil, false) then
					SlashTargets:append(p)
				end
			end
			if SlashTargets:isEmpty() then
				return false
			end
			local target = room:askForPlayerChosen(zwk, SlashTargets, "zulianzhu", "@zulianzhu-slash:" .. source:objectName())
			room:doAnimate(1, zwk:objectName(), target:objectName())
			local use_slash1 = room:askForUseSlashTo(source, target, "@zulianzhu-useslash:" .. target:objectName(), false)
			local use_slash2 = room:askForUseSlashTo(zwk, target, "@zulianzhu-useslash:" .. target:objectName(), false)
			if use_slash1 and use_slash2 and use_slash1:getColor() ~= use_slash2:getColor() then
				room:addMaxCards(zwk, -1, false)
			end
			room:setChangeSkillState(zwk, "zulianzhu", 1)
		end
	end,
}
zulianzhuvs = sgs.CreateViewAsSkillV2 {
	name = "zulianzhuvs&",
	n = 1,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		local player = request:getInitiator()
		if not player then return false end
		for _, p in sgs.qlist(player:getAliveSiblings(true)) do
			if p:hasSkill("zulianzhu") then
				return not player:hasUsed("#zulianzhuCard")
			end
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		if request:getSelectedCardIds():length() >= 1 then return false end
		local player = request:getInitiator()
		return not player:isCardLimited(candidate, sgs.Card_MethodRecast)
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() <= 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		local lzvs_card = zulianzhuCard:clone()
		for i = 0, ids:length() - 1 do
			lzvs_card:addSubcard(sgs.Sanguosha:getCard(ids:at(i)))
		end
		return lzvs_card
	end,
}
extension:addSkills(zulianzhuvs)
zu_wukuang:addSkill("zu_wu_muyin")

--族吴乔
table.insert(ol_clans.chenliu_wu, "wuqiao")
zu_wuqiao = sgs.General(extension, "zu_wuqiao", "qun", 4, true)
local function fcjyzCandiscard(player) --借用一下界老于禁的黑牌可弃判定
	for _, c in sgs.qlist(player:getCards("he")) do
		if c:isBlack() and player:canDiscard(player, c:getEffectiveId()) then
			return true
		end
	end
end
zuqiajue = sgs.CreateTriggerSkillV2 {
	name = "zuqiajue",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.EventPhaseEnd },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if player:getPhase() ~= sgs.Player_Draw then
			return false
		end
		if event == sgs.EventPhaseStart then
			if fcjyzCandiscard(player) and room:askForCard(player, ".|black", "@zuqiajue-invoke", data, skill:objectName()) then
				room:broadcastSkillInvoke(skill:objectName())
				room:setPlayerFlag(player, skill:objectName())
			end
		elseif event == sgs.EventPhaseEnd then
			if player:hasFlag(skill:objectName()) then
				room:setPlayerFlag(player, "-" .. skill:objectName())
				room:showAllCards(player)
				local num = 0
				for _, c in sgs.qlist(player:getHandcards()) do
					num = num + c:getNumber()
				end
				if num > 30 then
					room:addMaxCards(player, -2, false)
				else
					player:insertPhase(sgs.Player_Draw)
				end
			end
		end
	end,
}
zu_wuqiao:addSkill(zuqiajue)
zu_wuqiao:addSkill("zu_wu_muyin")

sgs.LoadTranslationTable {
	--<陈留·吴氏>专属宗族技：穆荫
	["zu_wu_muyin"] = "穆荫",
	[":zu_wu_muyin"] = "宗族技，<font color='green'><b>回合开始时，</b></font>你可以令一名手牌上限不为全场最大的同族角色手牌上限+1。",
	["zu_wu_muyin0"] = "穆荫：你可以令一名手牌上限不为全场最大的同族角色手牌上限+1",
	["$zu_wu_muyin2"] = "[吴班] 祖训秉心，其荫何能薄也？",
	["$zu_wu_muyin1"] = "[吴班] 世代佐忠义，子孙何绝焉？",
	["$zu_wu_muyin4"] = "[吴苋] 吴氏一族，感明君青睐。",
	["$zu_wu_muyin3"] = "[吴苋] 吴门隆盛，闻钟而鼎食。",
	["$zu_wu_muyin5"] = "[吴匡] 家有贵女，其德泽三代！",
	["$zu_wu_muyin6"] = "[吴匡] 吾家当以此女而兴之！",
	["$zu_wu_muyin7"] = "[吴乔] 生继汉泽于身，死效忠义于行。",
	["$zu_wu_muyin8"] = "[吴乔] 吾祖彰汉室之荣，今子孙未敢忘。",

	--族吴班
	["zu_wuban"] = "族吴班",
	["#zu_wuban"] = "豪侠督进",
	["designer:zu_wuban"] = "大宝",
	["illustrator:zu_wuban"] = "匠人绘",
	["information:zu_wuban"] = "宗族：[陈留·吴氏]",
	--斩钉
	["zuzhanding"] = "斩钉",
	[":zuzhanding"] = "你可以将任意张牌当【杀】使用并令你的手牌上限-1。若此【杀】造成伤害，你将手牌调整至手牌上限，否则此【杀】不计入次数。",
	["zuzhandingDebuff"] = "斩钉-",
	["$zuzhanding1"] = "汝颈硬，比之金铁何如？",
	["$zuzhanding2"] = "魍魉鼠辈，速速系颈俯首！",
	--阵亡
	["~zu_wuban"] = "无胆鼠辈，安敢暗箭伤人......",

	--族吴苋
	["zu_wuxian"] = "族吴苋",
	["#zu_wuxian"] = "庄姝晏晏",
	["designer:zu_wuxian"] = "玄蝶既白",
	["illustrator:zu_wuxian"] = "君桓文化",
	["information:zu_wuxian"] = "宗族：[陈留·吴氏]",
	--移荣
	["zuyirong"] = "移荣",
	[":zuyirong"] = "<font color='green'><b>出牌阶段限两次，</b></font>你可以将手牌[摸/弃]至手牌上限，然后你的手牌上限[-1/+1]。",
	["zuyirongDebuff"] = "移荣-",
	["zuyirongBuff"] = "移荣+",
	["$zuyirong2"] = "移花接木，花容更胜从前。",
	["$zuyirong1"] = "花开彼岸，繁荣不减当年。",
	--贵相
	["zuguixiang"] = "贵相",
	[":zuguixiang"] = "锁定技，你本回合的第X个阶段开始前，你将此阶段改为出牌阶段（X为你的手牌上限）。",
	["$zuguixiang1"] = "女相显贵，凤仪从龙。",
	["$zuguixiang2"] = "正官七杀，天生富贵。",
	--阵亡
	["~zu_wuxian"] = "玄德东征，何日归还......",

	--族吴匡
	["zu_wukuang"] = "族吴匡",
	["#zu_wukuang"] = "诛绝宦竖",
	["designer:zu_wukuang"] = "玄蝶既白",
	["illustrator:zu_wukuang"] = "匠人绘",
	["information:zu_wukuang"] = "宗族：[陈留·吴氏]",
	--联诛
	["zulianzhu"] = "联诛",
	[":zulianzhu"] = "转换技，每名角色的出牌阶段限一次，①其可以与你各重铸一张牌，若这两张牌颜色相同，你的手牌上限+1；"
		.. "②其可以令你选择（除其之外的）另一名其他角色，然后其与你可以依次对该角色使用一张【杀】，若这两张【杀】颜色不同，你的手牌上限-1。",
	[":zulianzhu1"] = "转换技，每名角色的出牌阶段限一次，①其可以与你各重铸一张牌，若这两张牌颜色相同，你的手牌上限+1。"
		.. '<font color="#01A5AF"><s>②其可以令你选择（除其之外的）另一名其他角色，然后其与你可以依次对该角色使用一张【杀】（无距离限制），若这两张【杀】颜色不同，你的手牌上限-1。</s></font>',
	[":zulianzhu2"] = '转换技，每名角色的出牌阶段限一次，<font color="#01A5AF"><s>①其可以与你各重铸一张牌，若这两张牌颜色相同，你的手牌上限+1。</s></font>'
		.. "②其可以令你选择（除其之外的）另一名其他角色，然后其与你可以依次对该角色使用一张【杀】，若这两张【杀】颜色不同，你的手牌上限-1。",
	["zulianzhuvs"] = "联诛卡",
	[":zulianzhuvs"] = "转换技，出牌阶段限一次，①你可以与拥有“联诛”的角色各重铸一张牌，若这两张牌颜色相同，其手牌上限+1；"
		.. "②你可以令拥有“联诛”的角色选择（不为你二人的）另一名其他角色，然后你与其可以依次对该角色使用一张【杀】，若这两张【杀】颜色不同，其手牌上限-1。",
	["@zulianzhuRecast"] = "[联诛·阳]请重铸一张牌",
	["@zulianzhu-slash"] = "[联诛·阴]请选择一名除%src之外的其他角色作为%src与你联手出【杀】的目标",
	["@zulianzhu-useslash"] = "[联诛·阴]你可以对%src使用一张【杀】",
	["$zulianzhu2"] = "尽诛贼常侍，正在此时！",
	["$zulianzhu1"] = "奸宦作乱，当联兵伐之！",
	--阵亡
	["~zu_wukuang"] = "孟德何在？本初何在？......",

	--族吴乔
	["zu_wuqiao"] = "族吴乔",
	["#zu_wuqiao"] = "孤节卅岁",
	["designer:zu_wuqiao"] = "玄蝶既白",
	["illustrator:zu_wuqiao"] = "官方",
	["information:zu_wuqiao"] = "宗族：[陈留·吴氏]",
	--跒倔
	["zuqiajue"] = "跒倔",
	[":zuqiajue"] = "摸牌阶段开始时，你可以弃置一张黑色牌，若如此做，此阶段结束时，你展示所有手牌：若这些牌的点数之和大于30，你的手牌上限-2；否则你执行一个额外的摸牌阶段。",
	["zuqiajueDebuff"] = "跒倔-",
	["@zuqiajue-invoke"] = "[跒倔]你可以弃置一张黑色牌争取一个额外的摸牌阶段",
	["$zuqiajue1"] = "汉旗未复，此生不居檐下。",
	["$zuqiajue2"] = "蜀川大好，皆可为家。",
	--阵亡
	["~zu_wuqiao"] = "蜀川万里，孤身伶仃......",
}

--颍川荀氏
ol_clans.yingchuan_xun = { "xunshu", "xunyu" }
nyzu_xunshu = sgs.General(extension, "nyzu_xunshu", "qun", 3, true, false, false)

ny_balongCard = sgs.CreateSkillCard {
	name = "ny_balong",
	will_throw = false,
	target_fixed = true,
	about_to_use = function(self, room, use)
		local source = use.from
		if source:getMark("ny_balong_old") > 0 then
			room:setPlayerMark(source, "ny_balong_old", 0)
			room:askForChoice(source, self:objectName(), "ny_balong_new+cancel")
		else
			room:setPlayerMark(source, "ny_balong_old", 1)
			room:askForChoice(source, self:objectName(), "ny_balong_old+cancel")
		end
		--source:drawCards(1)
		return
	end,
	on_use = function(self, room, source, targets)
		return false
	end,
}
ny_balongVS = sgs.CreateViewAsSkillV2 {
	name = "ny_balong",
	frequency = sgs.Skill_Compulsory,
	n = 0,
	can_activate = function(skill, request)
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		return ny_balongCard:clone()
	end,
}
ny_balong = sgs.CreateTriggerSkillV2 {
	name = "ny_balong",
	events = { sgs.HpChanged },
	frequency = sgs.Skill_Compulsory,
	view_as_skill = ny_balongVS,
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:isDead() then
			return false
		end
		if player:getMark("ny_balong-Clear") > 0 then
			return false
		end
		room:addPlayerMark(player, "ny_balong-Clear", 1)
		if player:isKongcheng() then
			return false
		end
		local trick = 0
		local equip = 0
		local basic = 0
		local show = sgs.IntList()
		for _, card in sgs.qlist(player:getHandcards()) do
			show:append(card:getId())
			if card:isKindOf("TrickCard") then
				trick = trick + 1
			elseif card:isKindOf("BasicCard") then
				basic = basic + 1
			elseif card:isKindOf("EquipCard") then
				equip = equip + 1
			end
		end
		if trick > equip and trick > basic then
			room:sendCompulsoryTriggerLog(player, skill)
			room:showCard(player, show)
			local n = room:getAlivePlayers():length()
			if player:getMark("ny_balong_old") > 0 then
				n = 8
			end
			if player:getHandcardNum() < n then
				player:drawCards(n - player:getHandcardNum(), skill:objectName())
			end
		end
	end,
}

ny_shenjunVS = sgs.CreateViewAsSkillV2 {
	name = "ny_shenjun",
	n = 999,
	response_or_use = true,
	can_activate = function(skill, request)
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return ("@@ny_shenjun"):find(request:getPattern(), 1, true) ~= nil
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		return request:getSelectedCardIds():length() < player:getMark("ny_shenjun")
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		return player:property("ny_shenjun"):toString() ~= ""
			and request:getSelectedCardIds():length() == player:getMark("ny_shenjun")
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		local pattern = player:property("ny_shenjun"):toString()
		local ids = request:getSelectedCardIds()
		if pattern ~= "" and ids:length() == player:getMark("ny_shenjun") then
			local card = sgs.Sanguosha:cloneCard(pattern)
			card:setSkillName("ny_shenjun")
			card:setFlags("ny_shenjun")
			for i = 0, ids:length() - 1 do
				card:addSubcard(sgs.Sanguosha:getCard(ids:at(i)))
			end
			return card
		end
		return nil
	end,
}

ny_shenjunCard = sgs.CreateSkillCard {
	name = "ny_shenjun",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, from)
		local card = sgs.Sanguosha:cloneCard(self:getUserString())
		card:addSubcards(self:getSubcards())
		card:setSkillName("ny_shenjun")

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, from)
	end,
	feasible = function(self, targets, from)
		local card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_SuitToBeDecided, -1)
		card:addSubcards(self:getSubcards())
		card:setSkillName("ny_shenjun")

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, from)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local card = sgs.Sanguosha:cloneCard(self:getUserString())
		card:addSubcards(self:getSubcards())
		card:setSkillName("ny_shenjun")
		return card
	end,
}

ny_shenjun = sgs.CreateTriggerSkillV2 {
	name = "ny_shenjun",
	events = { sgs.CardUsed, sgs.CardResponded, sgs.EventPhaseEnd },
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = ny_shenjunVS,
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		-- 舊版 can_trigger 不限持有者；V2 需以實際持有者為 owner，每事件取一位
		local holder = room:findPlayerBySkillName(skill:objectName())
		if holder then
			return skill:objectName(), holder
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
				local response = data:toCardResponse()
				if response.m_isUse then
					card = response.m_card
				end
			end
			if card and (card:isKindOf("Slash") or card:isNDTrick()) then
			else
				return false
			end
			if table.contains(card:getSkillNames(), skill:objectName()) then
				return false
			end
			for _, pl in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if pl:isAlive() then
					local show = sgs.IntList()
					for _, cc in sgs.qlist(pl:getHandcards()) do
						if cc:sameNameWith(card) then
							show:append(cc:getId())
						end
					end
					if not show:isEmpty() then
						room:sendCompulsoryTriggerLog(pl, skill)
						room:setPlayerFlag(pl, "ny_shenjun")
						room:showCard(pl, show)
						for _, id in sgs.qlist(show) do
							room:setCardTip(id, "ny_shenjun")
						end
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			for _, pl in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if pl:isAlive() and pl:hasFlag("ny_shenjun") then
					room:setPlayerFlag(pl, "-ny_shenjun")
					local count = 0
					local choices = {}
					for _, cc in sgs.qlist(pl:getHandcards()) do
						if cc:hasTip("ny_shenjun") then
							count = count + 1
							if not table.contains(choices, cc:objectName()) then
								local dc = sgs.Sanguosha:cloneCard(cc:objectName())
								dc:setSkillName("ny_shenjun")
								dc:deleteLater()
								if dc:isAvailable(pl) then
									table.insert(choices, cc:objectName())
								end
							end
						end
					end
					if count > 0 and #choices > 0 then
						table.insert(choices, "cancel")
						room:setPlayerMark(pl, "ny_shenjun", count)
						local choice = room:askForChoice(pl, skill:objectName(), table.concat(choices, "+"))
						if choice ~= "cancel" then
							room:setPlayerProperty(pl, "ny_shenjun", sgs.QVariant(choice))
							local prompt = string.format("@ny_shenjun:%s::%s:", count, choice)
							room:askForUseCard(pl, "@@ny_shenjun", prompt)
						end
					end
				end
			end
		end
	end,
}

nyzu_xunshu:addSkill(ny_shenjun)
nyzu_xunshu:addSkill(ny_shenjunVS)
nyzu_xunshu:addSkill(ny_balong)
nyzu_xunshu:addSkill(ny_balongVS)
kezudaojie = sgs.CreateTriggerSkillV2 {
	name = "kezudaojie",
	events = { sgs.CardFinished, sgs.CardUsed },
	frequency = sgs.Skill_Compulsory,
	global = true,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag("kezudaojieBf") and player:isAlive() and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 global 技能的 CardUsed 記帳每事件只執行一次；on_record 按持有者逐一呼叫，僅首位持有者記錄
		if event ~= sgs.CardUsed then return end
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		local use = ctx.original_data:toCardUse()
		if use.card:isKindOf("TrickCard") and not use.card:isDamageCard() then
			player:addMark("kezudaojie-Clear")
			if player:getMark("kezudaojie-Clear") == 1 then
				room:setCardFlag(use.card, "kezudaojieBf")
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		if room:getCardOwner(use.card:getEffectiveId()) then
			return false
		end
		local n = math.random(1, 2)
		if player:getGeneralName():endsWith("xunchen") or player:getGeneral2Name():endsWith("xunchen") then
			n = n + 2
		elseif player:getGeneralName():endsWith("xunyou") or player:getGeneral2Name():endsWith("xunyou") then
			n = n + 4
		elseif player:getGeneralName():endsWith("xuncan") or player:getGeneral2Name():endsWith("xuncan") then
			n = n + 6
		elseif player:getGeneralName():endsWith("xuncai") or player:getGeneral2Name():endsWith("xuncai") then
			n = n + 8
		elseif player:getGeneralName():endsWith("xunshuang") or player:getGeneral2Name():endsWith("xunshuang") then
			n = n + 10
		end
		room:sendCompulsoryTriggerLog(player, skill, n)
		local choice = { "hp" }
		for _, sk in sgs.qlist(player:getVisibleSkillList()) do
			if (not sk:isAttachedLordSkill()) and (sk:getFrequency(player) == sgs.Skill_Compulsory) then
				table.insert(choice, "skill=" .. sk:objectName())
			end
		end
		choice = room:askForChoice(player, skill:objectName(), table.concat(choice, "+"), data)
		if choice == "hp" then
			room:loseHp(player, 1, true, player, skill:objectName())
		else
			local sk = choice:split("=")[2]
			room:detachSkillFromPlayer(player, sk)
		end
		if player:isAlive() then
			local targets = sgs.SPlayerList()
			for _, pl in sgs.qlist(room:getAlivePlayers()) do
				if isSameClan(player, pl) then
					targets:append(pl)
				end
			end
			local target = room:askForPlayerChosen(player, targets, skill:objectName(), "@kezudaojie:" .. use.card:objectName())
			if target then
				room:doAnimate(1, player:objectName(), target:objectName())
				room:obtainCard(target, use.card, true)
			end
		end
	end,
}
nyzu_xunshu:addSkill(kezudaojie)

table.insert(ol_clans.yingchuan_xun, "xunchen")
nyzu_xunchen = sgs.General(extension, "nyzu_xunchen", "qun", 3, true, false, false)

ny_sankuang = sgs.CreateTriggerSkillV2 {
	name = "ny_sankuang",
	events = { sgs.CardFinished, sgs.CardUsed },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		if event == sgs.CardUsed then
			if use.card:getTypeId() > 0 and player:getMark(use.card:getType() .. "ny_sankuang_lun") < 1 then
				player:addMark(use.card:getType() .. "ny_sankuang_lun")
				room:setCardFlag(use.card, "ny_sankuangBf")
			end
			return false
		end
		if not use.card:hasFlag("ny_sankuangBf") then
			return false
		end
		player:setTag("ny_sankuang_use", data)
		local prompt = string.format("@ny_sankuang:%s:", use.card:objectName())
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName() .. "$-1", prompt, false, true)
		if player:getMark("ny_beishi_used") < 1 then
			room:setPlayerMark(player, "ny_beishi_used", 1)
			local viewers = sgs.SPlayerList()
			viewers:append(player)
			room:setPlayerMark(target, "&ny_beishi", 1, viewers)
			room:setPlayerMark(target, "ny_beishi_from" .. player:objectName(), 1)
		end
		local min = 0
		if target:getCards("ej"):length() > 0 then
			min = min + 1
		end
		if target:isWounded() then
			min = min + 1
		end
		if target:getHandcardNum() > target:getHp() then
			min = min + 1
		end
		if target:getCardCount() > 0 then
			local give_pro = string.format("ny_sankuang_give:%s::%s:", player:objectName(), min)
			local give = room:askForExchange(target, skill:objectName(), 999, min, true, give_pro, false)
			if give then
				room:giveCard(target, player, give, skill:objectName(), false)
			end
		end
		if target:isAlive() and (room:getCardOwner(use.card:getEffectiveId()) == nil or player:hasCard(use.card)) then
			room:obtainCard(target, use.card, true)
		end
	end,
}

ny_beishi = sgs.CreateTriggerSkillV2 {
	name = "ny_beishi",
	events = { sgs.CardsMoveOneTime },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceHand) and move.from:getMark("ny_beishi_from" .. player:objectName()) > 0 and move.is_last_handcard and player:isWounded() then
				room:sendCompulsoryTriggerLog(player, skill)
				room:recover(player, sgs.RecoverStruct(skill:objectName(), player))
			end
		end
	end,
}

nyzu_xunchen:addSkill(ny_sankuang)
nyzu_xunchen:addSkill(ny_beishi)
nyzu_xunchen:addSkill("kezudaojie")

table.insert(ol_clans.yingchuan_xun, "xunyou")
nyzu_xunyou = sgs.General(extension, "nyzu_xunyou", "wei", 3, true, false, false)

ny_baichu = sgs.CreateTriggerSkillV2 {
	name = "ny_baichu",
	events = { sgs.CardFinished, sgs.RoundEnd },
	frequency = sgs.Skill_NotFrequent,
	waked_skills = "qice",
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.CardFinished then
			if player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		elseif event == sgs.RoundEnd then
			-- 舊版 can_trigger 不限持有者；V2 需以實際持有者為 owner，每事件取一位
			local holder = room:findPlayerBySkillName(skill:objectName())
			if holder then
				return skill:objectName(), holder
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardFinished and player:objectName() == ctx.invoker:objectName() then
			local use = data:toCardUse()
			if use.card:isKindOf("SkillCard") then
				return false
			end
			local suits = { "spade", "diamond", "club", "heart" }
			local suit = use.card:getSuitString()
			local ckind = use.card:getType()

			local groups = player:getTag("ny_baichu_groups"):toString():split("+")
			local records = player:getTag("ny_baichu_records"):toString():split("+")
			local invoke = true

			if table.contains(suits, suit) then
				local group = string.format("%s_%s", ckind, suit)
				if table.contains(groups, group) then
					if not player:hasSkill("qice", true) then
						room:sendCompulsoryTriggerLog(player, skill)
						invoke = false
						room:addPlayerMark(player, "ny_zuqice_lun")
						room:acquireSkill(player, "qice")
					end
				else
					room:sendCompulsoryTriggerLog(player, skill)
					invoke = false

					table.insert(groups, group)
					player:setTag("ny_baichu_groups", sgs.QVariant(table.concat(groups, "+")))

					local all = {}
					for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
						local card = sgs.Sanguosha:getEngineCard(id)
						if card:isNDTrick() then
							if (not table.contains(all, card:objectName())) and (not table.contains(records, card:objectName())) then
								table.insert(all, card:objectName())
							end
						end
					end
					if #all > 0 then
						local choice = room:askForChoice(player, skill:objectName(), table.concat(all, "+"), data, table.concat(records, "+"), "ny_baichu_record")

						table.insert(records, choice)
						player:setTag("ny_baichu_records", sgs.QVariant(table.concat(records, "+")))
						local sts = player:getTag("ny_baichu_sts"):toString():split("+")
						table.insert(sts, suit)
						table.insert(sts, ckind)
						table.insert(sts, choice)
						table.insert(sts, "|")
						player:setTag("ny_baichu_sts", sgs.QVariant(table.concat(sts, "+")))
						player:setSkillDescriptionSwap(skill:objectName(), "%arg11", table.concat(sts, "+"))
						room:changeTranslation(player, skill:objectName())
					end
				end
			end

			if table.contains(records, use.card:objectName()) then
				if invoke then
					room:sendCompulsoryTriggerLog(player, skill)
				end

				local choice = "draw"
				if player:isWounded() then
					choice = room:askForChoice(player, skill:objectName(), "draw+recover", data)
				end
				if choice == "draw" then
					player:drawCards(1, skill:objectName())
				else
					room:recover(player, sgs.RecoverStruct(skill:objectName(), player))
				end
			end
		elseif event == sgs.RoundEnd then
			local invoker = ctx.invoker
			if invoker:getMark("ny_zuqice_lun") > 0 and invoker:hasSkill("qice", true) then
				room:detachSkillFromPlayer(invoker, "qice", false, true)
			end
		end
	end,
}

nyzu_xunyou:addSkill(ny_baichu)
nyzu_xunyou:addSkill("kezudaojie")

table.insert(ol_clans.yingchuan_xun, "xuncan")
kezu_xuncan = sgs.General(extension, "kezu_xuncan", "wei", 3, true, false, false)

kezuyunshenCard = sgs.CreateSkillCard {
	name = "kezuyunshenCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return (#targets == 0) and (to_select:objectName() ~= player:objectName())
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:recover(target, sgs.RecoverStruct(self:getSkillName(), player))
		local slash = sgs.Sanguosha:cloneCard("ice_slash")
		slash:setSkillName("_kezuyunshen")
		if room:askForChoice(player, "kezuyunshen", "self+he") == "self" then
			if target:canSlash(player, slash, false) then
				room:useCard(sgs.CardUseStruct(slash, target, player), true)
			end
		else
			if player:canSlash(target, slash, false) then
				room:useCard(sgs.CardUseStruct(slash, player, target), true)
			end
		end
		slash:deleteLater()
	end,
}

kezuyunshen = sgs.CreateViewAsSkillV2 {
	name = "kezuyunshen",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not player:hasUsed("#kezuyunshenCard")
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		return kezuyunshenCard:clone()
	end,
}
kezu_xuncan:addSkill(kezuyunshen)

kezushangshen = sgs.CreateTriggerSkillV2 {
	name = "kezushangshen",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		-- 舊版 can_trigger 不限持有者；V2 需以實際持有者為 owner，每事件取一位
		local holder = room:findPlayerBySkillName(skill:objectName())
		if holder then
			return skill:objectName(), holder
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.nature ~= sgs.DamageStruct_Normal then
				for _, wc in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					room:addPlayerMark(wc, "bankezushangshen-Clear", 1)
				end
				for _, wc in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					if wc:getMark("bankezushangshen-Clear") <= 1 then
						if wc:askForSkillInvoke(skill:objectName(), data) then
							room:broadcastSkillInvoke(skill:objectName())
							local judge = sgs.JudgeStruct()
							judge.pattern = ".|spade|2~9"
							judge.good = false
							judge.negative = true
							judge.reason = "lightning"
							judge.who = wc
							room:judge(judge)
							if judge:isBad() then
								local ds = sgs.DamageStruct()
								ds.to = wc
								ds.damage = 3
								ds.reason = "lightning"
								ds.nature = sgs.DamageStruct_Thunder
								room:damage(ds)
							end
							local cha = 4 - damage.to:getHandcardNum()
							if (cha > 0) and damage.to:isAlive() then
								damage.to:drawCards(cha, skill:objectName())
							end
						end
					end
				end
			end
		end
	end,
}
kezu_xuncan:addSkill(kezushangshen)

kezufenchai = sgs.CreateTriggerSkillV2 {
	name = "kezufenchai",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.ChoiceMade, sgs.CardUsed, sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_PlaceJudge and move.to:objectName() == player:objectName() then
				--and move.reason.m_reason==sgs.CardMoveReason_S_REASON_JUDGE then
				local to = player:getTag("fenchaiPlayer"):toPlayer()
				if to then
					for _, id in sgs.list(move.card_ids) do
						local c = sgs.Sanguosha:getCard(id)
						local toc = sgs.Sanguosha:cloneCard(c:objectName(), c:getSuit(), c:getNumber())
						if to:isAlive() then
							toc:setSuit(sgs.Card_Heart)
						else
							toc:setSuit(sgs.Card_Spade)
						end
						toc:setSkillName("kezufenchai")
						local wrap = sgs.Sanguosha:getWrappedCard(id)
						wrap:takeOver(toc)
						room:broadcastUpdateCard(room:getAlivePlayers(), id, wrap)
						local log = sgs.LogMessage()
						log.type = "#FilterJudge"
						log.from = player
						log.card_str = c:toString()
						log.arg = "kezufenchai"
						room:sendLog(log)
						room:broadcastSkillInvoke(log.arg)
					end
				end
			end
		elseif event == sgs.ChoiceMade then
			local struct = data:toString()
			if struct == "" then
				return
			end
			local to = player:getTag("fenchaiPlayer"):toPlayer()
			if to then
				return
			end
			local promptlist = struct:split(":")
			if promptlist[1] == "skillInvoke" and table.contains(promptlist, "yer") or promptlist[1] == "playerChosen" or promptlist[1] == "cardChosen" or promptlist[1] == "Yiji" then
				for _, pn in sgs.list(promptlist) do
					if pn:startsWith("sgs") then
						for _, pt in sgs.list(pn:split("+")) do
							local to = room:findPlayerByObjectName(pt)
							if to and to:getGender() ~= player:getGender() then
								player:setTag("fenchaiPlayer", ToData(to))
								room:setPlayerMark(to, "&kezufenchai-Keep", 1)
								return
							end
						end
					end
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("SkillCard") and use.to:length() > 0 then
				local to = player:getTag("fenchaiPlayer"):toPlayer()
				if to then
					return
				end
				for _, p in sgs.list(use.to) do
					if p:getGender() ~= player:getGender() then
						player:setTag("fenchaiPlayer", ToData(p))
						room:setPlayerMark(p, "&kezufenchai-Keep", 1)
						return
					end
				end
			end
		end
	end,
}
kezu_xuncan:addSkill(kezufenchai)
kezu_xuncan:addSkill("kezudaojie")

table.insert(ol_clans.yingchuan_xun, "xuncai")
kezu_xuncai = sgs.General(extension, "kezu_xuncai", "qun", 3, false, false, false)

kezulieshiCard = sgs.CreateSkillCard {
	name = "kezulieshiCard",
	target_fixed = true,
	on_use = function(self, room, player, targets)
		local choices = {}
		if player:hasJudgeArea() then
			table.insert(choices, "lieshidamage=" .. player:objectName())
		end
		for _, c in sgs.qlist(player:getHandcards()) do
			if c:isKindOf("Jink") then
				table.insert(choices, "jink")
				break
			end
		end
		for _, c in sgs.qlist(player:getHandcards()) do
			if c:isKindOf("Slash") then
				table.insert(choices, "slash")
				break
			end
		end
		local choice = room:askForChoice(player, "kezulieshi", table.concat(choices, "+"))
		table.removeOne(choices, choice)
		local log = sgs.LogMessage()
		log.from = player
		if choice:startsWith("lieshidamage") then
			log.type = "$kezulieshidamage"
			log.to:append(player)
			room:sendLog(log)
			player:throwJudgeArea()
			room:damage(sgs.DamageStruct("kezulieshi", player, player, 1, sgs.DamageStruct_Fire))
		elseif choice == "jink" then
			log.type = "$kezulieshijink"
			room:sendLog(log)
			local dummy = sgs.Sanguosha:cloneCard("slash")
			for _, c in sgs.qlist(player:getCards("he")) do
				if c:isKindOf("Jink") then
					dummy:addSubcard(c)
				end
			end
			dummy:deleteLater()
			if dummy:subcardsLength() > 0 then
				--UseCardRecast(player,dummy,"kezulieshi",dummy:subcardsLength())
				room:throwCard(dummy, "kezulieshi", player)
			end
		elseif choice == "slash" then
			log.type = "$kezulieshislash"
			room:sendLog(log)
			local dummy = sgs.Sanguosha:cloneCard("slash")
			for _, c in sgs.qlist(player:getCards("he")) do
				if c:isKindOf("Slash") then
					dummy:addSubcard(c)
				end
			end
			dummy:deleteLater()
			if dummy:subcardsLength() > 0 then
				--UseCardRecast(player,dummy,"kezulieshi",dummy:subcardsLength())
				room:throwCard(dummy, "kezulieshi", player)
			end
		end
		if player:isDead() then
			return
		end
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "kezulieshi", "kezulieshi-ask", false, true)
		if not target:hasJudgeArea() and table.contains(choices, "lieshidamage=" .. player:objectName()) then
			table.removeOne(choices, "lieshidamage=" .. player:objectName())
		end
		local s, j = false, false
		for _, c in sgs.qlist(target:getHandcards()) do
			if c:isKindOf("Jink") then
				j = true
			end
			if c:isKindOf("Slash") then
				s = true
			end
		end
		if table.contains(choices, "slash") and s == false then
			table.removeOne(choices, "slash")
		end
		if table.contains(choices, "jink") and j == false then
			table.removeOne(choices, "jink")
		end
		if #choices < 1 then
			return
		end
		local choice = room:askForChoice(target, "kezulieshi", table.concat(choices, "+"))
		log.from = target
		log.to:append(player)
		if choice:startsWith("lieshidamage") then
			log.type = "$kezulieshidamage"
			room:sendLog(log)
			target:throwJudgeArea()
			room:damage(sgs.DamageStruct("kezulieshi", player, target, 1, sgs.DamageStruct_Fire))
		elseif choice == "jink" then
			log.type = "$kezulieshijink"
			room:sendLog(log)
			local dummy = sgs.Sanguosha:cloneCard("slash")
			for _, c in sgs.qlist(target:getCards("he")) do
				if c:isKindOf("Jink") then
					dummy:addSubcard(c)
				end
			end
			dummy:deleteLater()
			if dummy:subcardsLength() > 0 then
				--UseCardRecast(target,dummy,"kezulieshi",dummy:subcardsLength())
				room:throwCard(dummy, "kezulieshi", target)
			end
		elseif choice == "slash" then
			log.type = "$kezulieshislash"
			room:sendLog(log)
			local dummy = sgs.Sanguosha:cloneCard("slash")
			for _, c in sgs.qlist(target:getCards("he")) do
				if c:isKindOf("Slash") then
					dummy:addSubcard(c)
				end
			end
			dummy:deleteLater()
			if dummy:subcardsLength() > 0 then
				--UseCardRecast(target,dummy,"kezulieshi",dummy:subcardsLength())
				room:throwCard(dummy, "kezulieshi", target)
			end
		end
	end,
}
kezulieshi = sgs.CreateViewAsSkillV2 {
	name = "kezulieshi",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		for _, c in sgs.qlist(player:getHandcards()) do
			if c:isKindOf("Jink") or c:isKindOf("Slash") then
				return true
			end
		end
		return player:hasJudgeArea()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		return kezulieshiCard:clone()
	end,
}
kezu_xuncai:addSkill(kezulieshi)

kezudianzhan = sgs.CreateTriggerSkillV2 {
	name = "kezudianzhan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardFinished },
	global = true,
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		-- on_record 已先累計（每事件一次），標記值 1 等同舊版 addMark 前 < 1
		if use.card:getTypeId() > 0 and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getMark(use.card:getSuitString() .. "dianzhan_lun") == 1 then
			return skill:objectName()
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 global 技能每事件只記帳一次；on_record 按持有者逐一呼叫，僅首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		local use = ctx.original_data:toCardUse()
		if use.card:getTypeId() > 0 and player:getMark(use.card:getSuitString() .. "dianzhan_lun") < 1 then
			player:addMark(use.card:getSuitString() .. "dianzhan_lun")
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		if event == sgs.CardFinished then
			MarkRevises(player, "&kezudianzhan_lun", use.card:getSuitString() .. "_char")
			room:broadcastSkillInvoke(skill:objectName())
			local chain = 0
			if use.to:length() == 1 then
				if not use.to:at(0):isChained() then
					room:setPlayerChained(use.to:at(0))
					chain = 1
				end
			end
			local dummy = sgs.Sanguosha:cloneCard("slash")
			for _, c in sgs.qlist(player:getCards("h")) do
				if c:getSuit() == use.card:getSuit() and not player:isCardLimited(c, sgs.Card_MethodRecast) then
					dummy:addSubcard(c)
				end
			end
			if dummy:subcardsLength() > 0 then
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), "kezudianzhan", "")
				--重铸
				room:moveCardTo(dummy, nil, sgs.Player_DiscardPile, reason)
				--标记摸的牌
				player:drawCards(dummy:subcardsLength(), "recast")
				chain = chain + 1
			end
			dummy:deleteLater()
			if chain == 2 then
				player:drawCards(1, skill:objectName())
			end
		end
	end,
}
kezu_xuncai:addSkill(kezudianzhan)

kezuhuanyin = sgs.CreateTriggerSkillV2 {
	name = "kezuhuanyin",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EnterDying },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EnterDying then
			local dying = ctx.original_data:toDying()
			if dying.who == player then
				local cha = 4 - player:getHandcardNum()
				if cha > 0 then
					room:sendCompulsoryTriggerLog(player, skill)
					player:drawCards(cha, skill:objectName())
				end
			end
		end
	end,
}
kezu_xuncai:addSkill(kezuhuanyin)
kezu_xuncai:addSkill("kezudaojie")

sgs.LoadTranslationTable {
	["ny_yingchuanxunshi"] = "颍川荀氏",
	["kezudaojie"] = "蹈节",
	[":kezudaojie"] = "宗族技，锁定技，当你每回合首次使用的非伤害类锦囊牌结算后，你失去1点体力或失去一个锁定技。然后令一名同族角色获得此牌。",
	["kezudaojie:skill"] = "失去“%src”",
	["kezudaojie:hp"] = "失去1点体力",
	["@kezudaojie"] = "你须令一名同族角色获得此【%src】",

	["$kezudaojie1"] = "[荀淑] 荀人如玉，向节而生。",
	["$kezudaojie2"] = "[荀淑] 竹有其节，焚之不改。",
	["$kezudaojie3"] = "[荀谌] 此生所重者，慷慨之节也。",
	["$kezudaojie4"] = "[荀谌] 愿以此身，全清尚之节。",
	["$kezudaojie5"] = "[荀攸] 秉忠正之心，可抚宁内外。",
	["$kezudaojie6"] = "[荀攸] 贤者，温良恭俭让以得之。",
	["$kezudaojie7"] = "[荀粲] 君子持节，何移情乎？",
	["$kezudaojie8"] = "[荀粲] 我心慕鸳，从一而终。",
	["$kezudaojie9"] = "[荀采] 女子有节，宁死蹈之。",
	["$kezudaojie10"] = "[荀采] 荀氏三纲，死不贰嫁。",
	["$kezudaojie11"] = "[荀爽] 君子固穷，心如石，不可转",
	["$kezudaojie12"] = "[荀爽] 志节不屈，为玉碎，不为瓦全",

	--族荀淑

	["nyzu_xunshu"] = "族荀淑",
	["#nyzu_xunshu"] = "长儒赡宗",
	["designer:nyzu_xunshu"] = "玄蝶既白",
	["illustrator:nyzu_xunshu"] = "凡果",
	["information:nyzu_xunshu"] = "宗族：[颍川·荀氏]",

	["ny_balong"] = "八龙",
	[":ny_balong"] = "锁定技，当你每回合体力值首次变化后，若你手牌中锦囊牌为唯一最多的类别，你展示手牌并将手牌摸至场上角色数张。",
	["ny_balong:ny_balong_old"] = "当前为旧版“八龙”",
	["ny_balong:ny_balong_new"] = "当前为新版“八龙”",
	["ny_shenjun"] = "神君",
	[":ny_shenjun"] = "当一名角色使用【杀】或普通锦囊牌时，你展示所有与此牌同名的手牌（称为“神君”牌），然后本阶段结束时，你可以将“神君”牌数张牌当任意“神君”牌使用。",
	["@ny_shenjun"] = "你可以将 %src 张牌当作【%arg】使用",

	["$kezudaojie_nyzu_xunshu1"] = "荀人如玉，向节而生。",
	["$kezudaojie_nyzu_xunshu2"] = "竹有其节，焚之不改。",
	["$ny_balong1"] = "八龙之蜿蜿，云旗之委蛇。",
	["$ny_balong2"] = "穆王乘八牡，天地恣遨游。",
	["$ny_shenjun1"] = "区区障眼之法，难遮神人之目。",
	["$ny_shenjun2"] = "我以天地为师，自可道法自然。",
	["~nyzu_xunshu"] = "天下陆沉，荀氏难支……",

	--族荀谌

	["nyzu_xunchen"] = "族荀谌",
	["#nyzu_xunchen"] = "栖木之择",
	["designer:nyzu_xunchen"] = "玄蝶既白",
	["illustrator:nyzu_xunchen"] = "凡果",
	["information:nyzu_xunchen"] = "宗族：[颍川·荀氏]",

	["kezudaojie_nyzu_xunchen"] = "蹈节",
	[":kezudaojie_nyzu_xunchen"] = "宗族技，锁定技，当你每回合首次使用的非伤害类锦囊牌结算后，你失去1点体力或失去一个锁定技。然后令一名同族角色获得此牌。",
	["ny_sankuang"] = "三恇",
	[":ny_sankuang"] = "锁定技，当你每轮首次使用一种类别的牌后，你令一名角色交给你至少X张牌并获得你使用的牌（X为其满足的条件数）：1.场上有牌；2.已受伤；3.体力值小于手牌数。",
	["@ny_sankuang"] = "你须令一名其他角色交给你X张牌并获得【%src】",
	["ny_sankuang_give"] = "请交给%src至少%arg张牌",
	["ny_beishi"] = "卑势",
	[":ny_beishi"] = "锁定技，当你首次发动“三恇”选择的角色失去最后的手牌后，你回复1点体力。",

	["$kezudaojie_nyzu_xunchen1"] = "此生所重者，慷慨之节也。",
	["$kezudaojie_nyzu_xunchen2"] = "愿以此身，全清尚之节。",
	["$ny_sankuang1"] = "人言可畏，宜常辟之。",
	["$ny_sankuang2"] = "天地可敬，可常惧之。",
	["$ny_beishi1"] = "虎卑其势，将有所逮。",
	["$ny_beishi2"] = "至山穷水尽，复柳暗花明。",
	["~nyzu_xunchen"] = "行贰臣之为，羞见列祖……",

	--族荀攸

	["nyzu_xunyou"] = "族荀攸",
	["#nyzu_xunyou"] = "挥智千军",
	["designer:nyzu_xunyou"] = "玄蝶既白",
	["illustrator:nyzu_xunyou"] = "错落宇宙",
	["information:nyzu_xunyou"] = "宗族：[颍川·荀氏]",

	["ny_baichu"] = "百出",
	[":ny_baichu"] = "当你使用牌结算结束后，若此牌：1.花色和类别的组合为你首次使用，你记录一个未被记录的普通锦囊牌的牌名，否则你本轮视为拥有技能“奇策”；2.为“百出”已记录的牌，你摸一张牌或回复1点体力。",
	[":ny_baichu1"] = "当你使用牌结算结束后，若此牌：1.花色和类别的组合为你首次使用，你记录一个未被记录的普通锦囊牌的牌名，否则你本轮视为拥有技能“奇策”；2.为“百出”已记录的牌，你摸一张牌或回复1点体力。<br/><font color='red'>已记录：%arg11</font>",
	["ny_baichu:draw"] = "摸一张牌",
	["ny_baichu:recover"] = "恢复一点体力",
	["ny_baichu_record"] = "请记录一个未被记录的普通锦囊牌的牌名",
	["ny_zuqice"] = "奇策",
	[":ny_zuqice"] = "出牌阶段限一次，你可以将所有手牌当任意一张普通锦囊牌使用。",

	["$kezudaojie_nyzu_xunyou1"] = "秉忠正之心，可抚宁内外。",
	["$kezudaojie_nyzu_xunyou2"] = "贤者，温良恭俭让以得之。",
	["$ny_baichu1"] = "腹有经纶，到用时施无穷之计。",
	["$ny_baichu2"] = "胸纳甲兵，烽烟起可靖疆晏海。",
	["$ny_zuqice1"] = "二袁相争，此曹公得利之时。",
	["$ny_zuqice2"] = "穷寇宜追，需防死蛇之不僵。",
	["~nyzu_xunyou"] = "无知命之寿，明知命之节。",

	["kezu_xuncai"] = "族荀采",
	["#kezu_xuncai"] = "怀刃自誓",
	["designer:kezu_xuncai"] = "玄蝶既白",
	["illustrator:kezu_xuncai"] = "凡果",
	["information:kezu_xuncai"] = "宗族：[颍川·荀氏]",

	["kezulieshi"] = "烈誓",
	["lieshidamage"] = "废除判定区并受到 %src 的火焰伤害",
	["kezulieshi:jink"] = "弃置所有【闪】",
	["kezulieshi:slash"] = "弃置所有【杀】",
	[":kezulieshi"] = "出牌阶段，你可以选择一项：1.废除判定区并受到你造成的的1点火焰伤害；2.弃置所有【闪】；3.弃置所有【杀】，然后令一名其他角色选择其余两项中的一项。",
	["$kezulieshidamage"] = "%from 选择了：废除判定区并受到 %to 造成的1点火焰伤害",
	["$kezulieshijink"] = "%from 选择了：弃置所有的【闪】",
	["$kezulieshislash"] = "%from 选择了：弃置所有的【杀】",
	["kezulieshi-ask"] = "请选择发动“烈誓”的角色",

	["kezudianzhan"] = "点盏",
	[":kezudianzhan"] = "锁定技，当你每轮首次使用一种花色的牌结算后，你横置此牌的目标（若目标唯一）并重铸此花色的所有手牌，然后若你以此法横置了角色且重铸了牌，你摸一张牌。",

	["kezuhuanyin"] = "还阴",
	[":kezuhuanyin"] = "锁定技，当你进入濒死状态时，你将手牌摸至四张。",

	["$kezudaojie_kezu_xuncai2"] = "荀氏三纲，死不贰嫁。",
	["$kezudaojie_kezu_xuncai1"] = "女子有节，宁死蹈之。",
	["$kezulieshi1"] = "拭刃为誓，女无二夫。",
	["$kezulieshi2"] = "霜刃证言，宁死不贰。",
	["$kezudianzhan1"] = "此灯如我，独向光明。",
	["$kezudianzhan2"] = "此间皆暗，唯灯瞩明。",
	["$kezuhuanyin1"] = "且将此身，还于阴氏。",
	["$kezuhuanyin2"] = "生不得同户，死可葬同穴乎？",

	["~kezu_xuncai"] = "苦难已过，世间大好……",

	["kezu_xuncan"] = "族荀粲",
	["#kezu_xuncan"] = "分钗断带",
	["designer:kezu_xuncan"] = "玄蝶既白",
	["illustrator:kezu_xuncan"] = "凡果",
	["information:kezu_xuncan"] = "宗族：[颍川·荀氏]",

	["kezudaojie_kezu_xuncan"] = "蹈节",
	[":kezudaojie_kezu_xuncan"] = "宗族技，锁定技，当你每回合首次使用的非伤害类锦囊牌结算后，你失去1点体力或失去一个锁定技。然后令一名同族角色获得此牌。",

	["kezuyunshen"] = "熨身",
	["kezuyunshen:self"] = "该角色对你使用一张冰【杀】",
	["kezuyunshen:he"] = "你对该角色使用一张冰【杀】",
	[":kezuyunshen"] = "出牌阶段限一次，你可以令一名其他角色回复1点体力，然后你选择一项：1.视为其对你使用一张冰【杀】；2.视为你对其使用一张冰【杀】。",

	["kezushangshen"] = "伤神",
	[":kezushangshen"] = "每回合首次一名角色受到属性伤害后，你可以进行一次【闪电】判定，然后该角色将手牌摸至四张。",

	["kezufenchai"] = "分钗",
	[":kezufenchai"] = "锁定技，若首次成为你技能目标的异性角色存活，你的判定牌花色视为♥，否则视为♠。",

	["$kezudaojie_kezu_xuncan1"] = "君子持节，何移情乎？",
	["$kezudaojie_kezu_xuncan2"] = "我心慕鸳，从一而终。",
	["$kezuyunshen1"] = "此心恋卿，尽融三九之冰。",
	["$kezuyunshen2"] = "寒梅傲雪，馥郁三尺之香。",
	["$kezushangshen1"] = "识字数万，此痛无字可言。",
	["$kezushangshen2"] = "吾妻已逝，吾心悲怆。",
	["$kezufenchai1"] = "钗同我心，奈何分之？",
	["$kezufenchai2"] = "夫妻分钗，天涯陌路。",

	["~kezu_xuncan"] = "此钗，今日可合乎？",
}

table.insert(ol_clans.yingchuan_xun, "xunshuang")
zu_xunshuang = sgs.General(extension, "zu_xunshuang", "qun", 3)

zuyangji = sgs.CreateTriggerSkillV2 {
	name = "zuyangji",
	events = { sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.HpChanged, sgs.DamageDone },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		-- 舊版 can_trigger 不限持有者、每事件一次；V2 需以實際持有者為 owner
		local holder = room:findPlayerBySkillName(skill:objectName())
		if holder then
			return skill:objectName(), holder
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版無條件的每事件記帳；on_record 按持有者逐一呼叫，僅首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		if event == sgs.HpChanged then
			player:addMark("zuyangjiHpChanged-Clear")
		elseif event == sgs.DamageDone then
			local damage = ctx.original_data:toDamage()
			if damage.card and damage.card:hasFlag("zuyangjiUse") then
				room:setTag("zuyangjiDamage", ToData(true))
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local target = ctx.invoker
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("zuyangjiHpChanged-Clear") > 0 and p:getHandcardNum() > 0 and p:hasSkill(skill:objectName()) and p:askForSkillInvoke(skill:objectName(), data) then
						p:peiyin(skill)
						room:showAllCards(p)
						local lc = nil
						room:removeTag("zuyangjiDamage")
						while p:isAlive() do
							local has = false
							for _, h in sgs.qlist(p:getHandcards()) do
								has = h:isBlack() and h:isAvailable(p)
								if has then
									break
								end
							end
							if has then
								has = room:askForUseCard(p, "$.|black|.|hand!", "zuyangji0", -1, sgs.Card_MethodUse, false, nil, nil, "zuyangjiUse")
								if has then
									lc = has
								else
									break
								end
								if room:getTag("zuyangjiDamage"):toBool() then
									break
								end
							else
								break
							end
						end
						if lc and lc:getSuit() == 0 and room:getCardOwner(lc:getEffectiveId()) == nil then
							local dc = dummyCard("indulgence")
							dc:setSkillName("zuyangji")
							dc:addSubcard(lc)
							if p:isProhibited(target, dc) then
								continue
							end
							room:moveCardTo(dc, p, sgs.Player_PlaceTable, true)
							lc = sgs.SPlayerList()
							lc:append(target)
							dc:use(room, p, lc)
						end
					end
				end
			end
		elseif (event == sgs.EventPhaseStart) and (target:getPhase() == sgs.Player_Start) then
			if target:getHandcardNum() > 0 and target:hasSkill(skill:objectName()) and target:askForSkillInvoke(skill:objectName(), data) then
				target:peiyin(skill)
				room:showAllCards(target)
				local lc = nil
				room:removeTag("zuyangjiDamage")
				while target:isAlive() do
					local has = false
					for _, h in sgs.qlist(target:getHandcards()) do
						has = h:isBlack() and h:isAvailable(target)
						if has then
							break
						end
					end
					if has then
						has = room:askForUseCard(target, "$.|black|.|hand!", "zuyangji0", -1, sgs.Card_MethodUse, false, nil, nil, "zuyangjiUse")
						if has then
							lc = has
						else
							break
						end
						if room:getTag("zuyangjiDamage"):toBool() then
							break
						end
					else
						break
					end
				end
				if lc and lc:getSuit() == 0 and room:getCardOwner(lc:getEffectiveId()) == nil then
					local dc = dummyCard("indulgence")
					dc:setSkillName("zuyangji")
					dc:addSubcard(lc)
					if target:isProhibited(target, dc) then
						return
					end
					room:moveCardTo(dc, target, sgs.Player_PlaceTable, true)
					lc = sgs.SPlayerList()
					lc:append(target)
					dc:use(room, target, lc)
				end
			end
		end
	end,
}
zu_xunshuang:addSkill(zuyangji)
zudandao = sgs.CreateTriggerSkillV2 {
	name = "zudandao",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.FinishRetrial },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.FinishRetrial then
			room:sendCompulsoryTriggerLog(player, skill)
			local cp = room:getCurrent()
			if cp:isAlive() then
				room:addMaxCards(cp, 3, true)
			end
		end
	end,
}
zu_xunshuang:addSkill(zudandao)
zuqingli = sgs.CreateTriggerSkillV2 {
	name = "zuqingli",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		-- 舊版 can_trigger 不限持有者、每事件一次；V2 需以實際持有者為 owner
		local holder = room:findPlayerBySkillName(skill:objectName())
		if holder then
			return skill:objectName(), holder
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
			local change = ctx.original_data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					local n = p:getMaxCards() - p:getHandcardNum()
					if n > 0 and p:hasSkill(skill:objectName()) then
						if n > 5 then
							n = 5
						end
						room:sendCompulsoryTriggerLog(p, skill)
						p:drawCards(n, skill:objectName())
					end
				end
			end
		end
	end,
}
zu_xunshuang:addSkill(zuqingli)
zu_xunshuang:addSkill("kezudaojie")
sgs.LoadTranslationTable {
	["zu_xunshuang"] = "族荀爽",
	["#zu_xunshuang"] = "分投急所",
	--["designer:zu_xunshuang"] = "玄蝶既白",
	--["illustrator:zu_xunshuang"] = "鬼画府",
	["information:zu_xunshuang"] = "宗族：[颍川·荀氏]",

	["zuyangji"] = "佯疾",
	[":zuyangji"] = "准备阶段，或你的体力值变化过的回合结束时，你可以展示所有手牌，然后依次使用其中的黑色牌，直到你无法使用或造成了伤害，然后若以此法使用的最后一张牌为♠，你将之当做【乐不思蜀】置于当前回合角色判定区。",

	["zudandao"] = "耽道",
	[":zudandao"] = "锁定技，你判定后，当前回合角色本回合手牌上限+3。",

	["zuqingli"] = "清励",
	[":zuqingli"] = "锁定技，每回合结束时，你将手牌摸至手牌上限（至多摸5张）。",

	["zuyangji0"] = "佯疾：请使用手牌中的黑色牌",

	["$zuyangji1"] = "吾女性烈，非力可强，唯情可欺",
	["$zuyangji2"] = "此身病弱，难当社稷之重",
	["$zudandao1"] = "吾志在学，不在仕",
	["$zudandao2"] = "愿为学海之舟，耻为樊笼之雀",
	["$zuqingli1"] = "身在红尘心自远，独揖孤舟钓寒秋",
	["$zuqingli2"] = "吾心向明月，世俗于我，如浮云尔",

	["~zu_xunshuang"] = "父不知子贤，子不知父愚",
}

zu_xunyu = sgs.General(extension, "zu_xunyu", "qun", 3, true, false, false)
zudingan = sgs.CreateTriggerSkillV2 {
	name = "zudingan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardFinished, sgs.CardUsed },
	global = true,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag("zudinganUse") and player:isAlive() and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.CardUsed then return end
		-- 舊版 global 每事件記帳一次；on_record 按持有者逐一呼叫，僅首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		local data = ctx.original_data
		local use = data:toCardUse()
		if use.card:getTypeId() > 0 then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:getMark(use.card:objectName() .. "zudinganUse_lun") > 0 then
					break
				end
				if p:getMark(use.card:objectName() .. "zudinganUse-Clear") > 0 then
					player:addMark(use.card:objectName() .. "zudinganUse_lun")
					room:setCardFlag(use.card, "zudinganUse")
				end
			end
			player:addMark(use.card:objectName() .. "zudinganUse-Clear")
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			local tps = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if use.to:contains(p) then
					continue
				end
				tps:append(p)
			end
			tps = room:askForPlayersChosen(player, tps, skill:objectName() .. "$-1", 1, 9, "zudingan0", true, false)
			if tps:length() > 0 then
				tps:append(player)
				room:sortByActionOrder(tps)
				room:drawCards(tps, 1, skill:objectName())
				local x = 0
				for _, p in sgs.qlist(tps) do
					if p == player then
						continue
					end
					x = math.max(x, p:getHandcardNum())
				end
				local aps = sgs.SPlayerList()
				for _, p in sgs.qlist(tps) do
					if p:getHandcardNum() >= x and p ~= player then
						aps:append(p)
					end
				end
				local choice = room:askForChoice(player, skill:objectName(), "zudingan1+zudingan2")
				for _, p in sgs.qlist(aps) do
					if p:isAlive() then
						if choice == "zudingan2" then
							local n2x = {}
							local x = 0
							for _, h in sgs.qlist(p:getHandcards()) do
								n2x[h:objectName()] = (n2x[h:objectName()] or 0) + 1
								x = math.max(x, n2x[h:objectName()])
							end
							for o, n in pairs(n2x) do
								if n >= x then
									local ids = sgs.IntList()
									for _, h in sgs.qlist(p:getHandcards()) do
										if h:objectName() == o and p:canDiscard(h:getId()) then
											ids:append(h:getId())
										end
									end
									room:throwCard(ids, skill:objectName(), p)
									break
								end
							end
						else
							room:damage(sgs.DamageStruct(skill:objectName(), player, p))
						end
					end
				end
			end
		end
	end,
}
zu_xunyu:addSkill(zudingan)
zufuningCard = sgs.CreateSkillCard {
	name = "zufuningCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, from)
		return #targets < 1 and to_select ~= from
	end,
	on_use = function(self, room, source, targets)
		local color = self:getColorString()
		for _, p in sgs.list(targets) do
			room:giveCard(source, p, self, "zufuning")
			if source:isDead() then
				break
			end
			if color ~= "no_color" then
				room:recover(source, sgs.RecoverStruct("zufuning", source))
			end
			if self:subcardsLength() > source:getMark("zufuningDoneNum-Clear") then
				local n = source:getHandcardNum() - source:getMaxHp()
				if n > 0 then
					room:askForDiscard(source, "zufuning", n, n)
				elseif n < 0 then
					source:drawCards(-n, "zufuning")
				end
			end
		end
	end,
}
zufuningvs = sgs.CreateViewAsSkillV2 {
	name = "zufuning",
	n = 999,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return request:getPattern() == "@@zufuning"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		return request:getSelectedCardIds():length() < player:getLostHp()
	end,
	card_selection_feasible = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		return request:getSelectedCardIds():length() >= player:getLostHp()
	end,
	create_card = function(skill, request)
		local sc = zufuningCard:clone()
		for _, c in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(sgs.Sanguosha:getCard(c))
		end
		return sc
	end,
}
zufuning = sgs.CreateTriggerSkillV2 {
	name = "zufuning",
	view_as_skill = zufuningvs,
	events = { sgs.HpChanged, sgs.DamageDone },
	can_trigger = function(skill, event, room, player, data)
		-- on_record 已先累計標記；標記值 1 等同舊版 addMark 前 < 1（首次）
		if event == sgs.HpChanged and player:isAlive() and player:hasSkill(skill:objectName())
			and player:getMark("zufuningHp-Clear") == 1 and player:getLostHp() > 0 then
			return skill:objectName()
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 can_trigger 不限持有者、每事件記帳一次；僅首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		if event == sgs.DamageDone then
			if player:getMark("zufuningDone-Clear") < 1 then
				player:addMark("zufuningDone-Clear")
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					p:addMark("zufuningDoneNum-Clear")
				end
			end
		elseif event == sgs.HpChanged then
			player:addMark("zufuningHp-Clear")
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.HpChanged then
			room:askForUseCard(player, "@@zufuning", "zufuning0:" .. player:getLostHp())
		end
	end,
}
zu_xunyu:addSkill(zufuning)
zu_xunyu:addSkill("kezudaojie")
sgs.LoadTranslationTable {
	["zu_xunyu"] = "族荀彧",
	--["#zu_xunyu"] = "分投急所",
	--["designer:zu_xunyu"] = "玄蝶既白",
	--["illustrator:zu_xunyu"] = "鬼画府",
	["information:zu_xunyu"] = "宗族：[颍川·荀氏]",

	["zudingan"] = "定安",
	[":zudingan"] = "锁定技，你使用牌后，若本回合有角色使用过同名牌（每轮每个牌名限一次），你选择与任意名不为目标的角色各摸一张牌。然后你选择一项令其他角色中手牌最多的角色执行：1.受到你造成的1点伤害；2.随机弃置手牌中最多的同名牌。",
	["zudingan0"] = "定安：请选择任意名角色共同摸牌",
	["zudingan1"] = "受到你的1点伤害",
	["zudingan2"] = "随机弃置手牌中最多的同名牌",

	["zufuning"] = "抚宁",
	[":zufuning"] = "每回合你的体力值首次变化后，你可将至少X张牌交给一名角色（X为你已损失体力值）。若你交给的牌：颜色均相同，你回复1点体力；数量大于本回合受到过伤害的角色数，你将手牌调整至体力上限。",
	["zufuning0"] = "你可以发动“抚宁”将%src张牌交给一名其他角色",

	--[[
	["$zudingan1"] = "",
	["$zudingan2"] = "",
	["$zufuning1"] = "",
	["$zufuning2"] = "",

	["~zu_xunyu"] = "",]]
}

--颍川韩氏
sgs.LoadTranslationTable {

	["ke_yinchuanhanshi"] = "颍川韩氏",
	["kezuxumin"] = "恤民",
	["kezuxuminex"] = "恤民",
	[":kezuxumin"] = "宗族技，限定技，你可以将一张牌当【五谷丰登】对任意名其他角色使用。",
}

ol_clans.yingchuan_han = { "hanshao", "hanfu" }
kezu_hanshao = sgs.General(extension, "kezu_hanshao", "qun", 3, true, false, false)

kezufangzhen = sgs.CreateTriggerSkillV2 {
	name = "kezufangzhen",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.RoundStart },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.RoundStart then
			local tl = player:getTag("kezufangzhenTL"):toIntList()
			if tl:contains(data:toInt()) then
				room:handleAcquireDetachSkills(player, "-kezufangzhen")
				player:removeTag("kezufangzhenTL")
			end
		end
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Play) then
			local aps = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if not p:isChained() then
					aps:append(p)
				end
			end
			local fri = room:askForPlayerChosen(player, aps, skill:objectName(), "kezufangzhen-ask", true, true)
			if fri then
				local tl = player:getTag("kezufangzhenTL"):toIntList()
				tl:append(fri:getSeat())
				player:setTag("kezufangzhenTL", ToData(tl))
				room:setPlayerChained(fri, true)
				if room:askForChoice(player, "kezufangzhen", "mopai+rec", ToData(fri)) == "mopai" then
					player:drawCards(2, skill:objectName())
					local cards = room:askForExchange(player, skill:objectName(), 2, 2, true, "kezufangzhenchoose", false)
					room:obtainCard(fri, cards, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), player:objectName(), skill:objectName(), ""), false)
				else
					room:recover(fri, sgs.RecoverStruct(skill:objectName(), player))
				end
			end
		end
	end,
}
kezu_hanshao:addSkill(kezufangzhen)

kezuliujuVS = sgs.CreateViewAsSkillV2 {
	name = "kezuliuju",
	n = 1,
	expand_pile = "#kezuliuju",
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return request:getPattern() == "@@kezuliuju"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		return candidate:isAvailable(player) and player:getPile("#kezuliuju"):contains(candidate:getEffectiveId())
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		return sgs.Sanguosha:getCard(request:getSelectedCardIds():at(0))
	end,
}
kezuliuju = sgs.CreateTriggerSkillV2 {
	name = "kezuliuju",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = kezuliujuVS,
	events = { sgs.EventPhaseEnd },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			local targets = sgs.SPlayerList()
			for _, p in sgs.list(room:getOtherPlayers(player)) do
				if player:canPindian(p) then
					targets:append(p)
				end
			end
			local target = room:askForPlayerChosen(player, targets, skill:objectName(), "kezuliuju-ask", true, true)
			if target then
				room:broadcastSkillInvoke(skill:objectName())
				local fm, tm = player:distanceTo(target), target:distanceTo(player)
				local pd = player:PinDian(target, skill:objectName())
				if pd.from_number ~= pd.to_number then
					local loser = player
					if pd.success then
						loser = target
					end
					local ids = sgs.IntList()
					if pd.from_card:getTypeId() ~= 1 then
						ids:append(pd.from_card:getEffectiveId())
					end
					if pd.to_card:getTypeId() ~= 1 then
						ids:append(pd.to_card:getEffectiveId())
					end
					while ids:length() > 0 and loser:isAlive() do
						loser:setTag("kezuliujuIds", ToData(ids))
						room:notifyMoveToPile(loser, ids, skill:objectName(), room:getCardPlace(ids:at(0)), true)
						local card = room:askForUseCard(loser, "@@kezuliuju", "kezuliuju-use")
						room:notifyMoveToPile(loser, ids, skill:objectName(), room:getCardPlace(ids:at(0)), false)
						if card then
							ids:removeOne(card:getEffectiveId())
						else
							break
						end
					end
				end
				if (fm ~= player:distanceTo(target) or tm ~= target:distanceTo(player)) and player:hasSkill("kezuxumin", true) and player:getMark("@kezuxumin") < 1 then
					room:setPlayerMark(player, "@kezuxumin", 1)
				end
			end
		end
	end,
}
kezu_hanshao:addSkill(kezuliuju)

kezuxuminCard = sgs.CreateSkillCard {
	name = "kezuxuminCard",
	target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		local wgfd = sgs.Sanguosha:cloneCard("amazing_grace")
		wgfd:setSkillName("kezuxumin")
		wgfd:addSubcard(self)
		wgfd:deleteLater()
		return to_select ~= source and not source:isProhibited(to_select, wgfd)
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@kezuxumin")
		local n = math.random(1, 2)
		if source:getGeneralName():endsWith("hanrong") or source:getGeneral2Name():endsWith("hanrong") then
			n = n + 2
		elseif source:getGeneralName():endsWith("hanfu") or source:getGeneral2Name():endsWith("hanfu") then
			n = n + 4
		end
		room:broadcastSkillInvoke("kezuxumin", n, source)
		room:doSuperLightbox(source, "kezuxumin")
		local wgfd = sgs.Sanguosha:cloneCard("amazing_grace")
		wgfd:setSkillName("_kezuxumin")
		wgfd:addSubcard(self)
		local use = sgs.CardUseStruct(wgfd, source)
		for _, p in ipairs(targets) do
			use.to:append(p)
		end
		room:useCard(use, true)
		wgfd:deleteLater()
	end,
}
kezuxumin = sgs.CreateViewAsSkillV2 {
	name = "kezuxumin",
	frequency = sgs.Skill_Limited,
	limit_mark = "@kezuxumin",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:getMark("@kezuxumin") > 0
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		local wgfd = sgs.Sanguosha:cloneCard("amazing_grace")
		wgfd:setSkillName("kezuxumin")
		wgfd:addSubcard(candidate)
		wgfd:deleteLater()
		return not player:isLocked(wgfd)
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local card = kezuxuminCard:clone()
		for _, c in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(sgs.Sanguosha:getCard(c))
		end
		return card
	end,
}
kezu_hanshao:addSkill(kezuxumin)

sgs.LoadTranslationTable {
	["kezu_hanshao"] = "族韩韶",
	["#kezu_hanshao"] = "分投急所",
	["designer:kezu_hanshao"] = "玄蝶既白",
	["illustrator:kezu_hanshao"] = "鬼画府",
	["information:kezu_hanshao"] = "宗族：[颍川·韩氏]",

	["kezufangzhen"] = "放赈",
	["kezufangzhen:mopai"] = "摸两张牌，然后交给其两张牌",
	["kezufangzhen:rec"] = "令其回复1点体力",
	["kezufangzhen-ask"] = "你可以选择发动“放赈”的角色",
	["kezufangzhenchoose"] = "放赈：请选择给出的两张牌",
	[":kezufangzhen"] = "<font color='green'><b>出牌阶段开始时，</b></font>你可以横置一名角色并选择一项：1.摸两张牌并交给其两张牌；2.令其回复1点体力。若如此做，第X轮开始时（X为其座次）你失去“放赈”。",

	["kezuliuju"] = "留驹",
	["#kezuliuju"] = "留驹",
	["kezuliuju-ask"] = "你可以发动“留驹”与一名角色拼点",
	["kezuliuju-use"] = "留驹：你可以使用一张拼点牌",
	[":kezuliuju"] = "<font color='green'><b>出牌阶段结束时，</b></font>你可以拼点，输的角色可以使用拼点牌中任意张非基本牌，然后若你与其的距离或其与你的距离因此变化，你重置“恤民”。",

	["$kezufangzhen1"] = "百姓罹灾，当施粮以赈。",
	["$kezufangzhen2"] = "开仓放粮，以赈灾民。",
	["$kezuliuju1"] = "当逐千里之驹，情深可留嬴城。",
	["$kezuliuju2"] = "乡老十里相送，此驹可彰吾情。",
	["$kezuxumin1"] = "[韩韶] 民者居野而多艰，不可不恤。",
	["$kezuxumin2"] = "[韩韶] 天下之本，上为君，下为民。",

	["~kezu_hanshao"] = "天地不仁，万物何辜……",
}

table.insert(ol_clans.yingchuan_han, "hanrong")
kezu_hanrong = sgs.General(extension, "kezu_hanrong", "qun", 3, true, false, false)

kezulianhe = sgs.CreateTriggerSkillV2 {
	name = "kezulianhe",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseEnd then
			-- 效果作用於事件玩家（結束出牌階段者）；V2 需以實際持有者為 owner
			if player:getPhase() == sgs.Player_Play and player:getMark("&lianhenum-PlayClear") > 0 then
				local holder = room:findPlayerBySkillName(skill:objectName())
				if holder then
					return skill:objectName(), holder
				end
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.CardsMoveOneTime then return end
		-- 舊版每事件記帳一次；on_record 按持有者逐一呼叫，僅首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		local move = ctx.original_data:toMoveOneTime()
		if
			move.to_place == sgs.Player_PlaceHand
			and move.to:objectName() == player:objectName()
			and player:getPhase() == sgs.Player_Play
			and player:getMark("&beusekezulianhe-SelfPlayClear") > 0
		then
			if move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW or player:getMark("&hasdrawlianhe-PlayClear") > 0 then
				room:setPlayerMark(player, "&hasdrawlianhe-PlayClear", 1)
				room:setPlayerMark(player, "&lianhenum-PlayClear", 0)
			else
				room:addPlayerMark(player, "&lianhenum-PlayClear", move.card_ids:length())
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if event == sgs.EventPhaseStart and target:getPhase() == sgs.Player_Play then
			local aps = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if not p:isChained() then
					aps:append(p)
				end
			end
			if aps:length() >= 2 then
				if target:askForSkillInvoke(skill:objectName(), ToData("kezulianhe0"), false) then
					local ones = room:askForPlayersChosen(target, aps, skill:objectName(), 2, 2, "kezulianhe-ask", true, true)
					if ones:length() == 2 then
						room:broadcastSkillInvoke(skill:objectName())
						for _, p in sgs.qlist(ones) do
							room:setPlayerChained(p)
							room:setPlayerMark(p, target:objectName() .. "kezulianhe-SelfPlayClear", 1)
							room:setPlayerMark(p, "&beusekezulianhe-SelfPlayClear", 1)
						end
					end
				end
			end
		end
		if (event == sgs.EventPhaseEnd) and (target:getPhase() == sgs.Player_Play) then
			local n = target:getMark("&lianhenum-PlayClear")
			if n > 0 then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if target:getMark(p:objectName() .. "kezulianhe-SelfPlayClear") > 0 then
						room:sendCompulsoryTriggerLog(target, skill)
						n = math.min(3, n)
						local givenum = n - 1
						local drawnum = n + 1
						if givenum > 0 and target ~= p then
							target:setTag("kezulianheFrom", ToData(p))
							local card = room:askForExchange(target, skill:objectName(), givenum, givenum, true, "kezulianhegive:" .. p:objectName() .. ":" .. givenum .. ":" .. drawnum, true)
							if card then
								local log = sgs.LogMessage()
								log.type = "$kezulianheloggive"
								log.from = target
								log.to:append(p)
								room:sendLog(log)
								room:giveCard(target, p, card, skill:objectName())
								continue
							end
						end
						local log = sgs.LogMessage()
						log.type = "$kezulianhelogdraw"
						log.from = target
						log.to:append(p)
						room:sendLog(log)
						p:drawCards(drawnum, skill:objectName())
					end
				end
			end
		end
	end,
}
kezu_hanrong:addSkill(kezulianhe)

kezuhuanjiaVS = sgs.CreateViewAsSkillV2 {
	name = "kezuhuanjia",
	n = 1,
	expand_pile = "#kezuhuanjia",
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return request:getPattern() == "@@kezuhuanjia"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		return candidate:isAvailable(player) and player:getPile("#kezuhuanjia"):contains(candidate:getEffectiveId())
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		return sgs.Sanguosha:getCard(request:getSelectedCardIds():at(0))
	end,
}

kezuhuanjia = sgs.CreateTriggerSkillV2 {
	name = "kezuhuanjia",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = kezuhuanjiaVS,
	events = { sgs.EventPhaseEnd, sgs.Pindian, sgs.DamageDone },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseEnd and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.DamageDone then return end
		-- 舊版 can_trigger 不限持有者、每事件記帳一次；僅首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		local damage = ctx.original_data:toDamage()
		if damage.card and damage.card:hasFlag("huanjiacard") then
			room:setPlayerMark(damage.from, damage.card:toString() .. "huanjiada-Clear", 1)
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canPindian(p) then
					targets:append(p)
				end
			end
			if targets:length() > 0 then
				local target = room:askForPlayerChosen(player, targets, skill:objectName(), "kezuliuju-ask", true, true)
				if target then
					room:broadcastSkillInvoke(skill:objectName())
					local pd = player:PinDian(target, skill:objectName())
					local winner = target
					if pd.success then
						winner = player
					end
					local ids = sgs.IntList()
					ids:append(pd.from_card:getEffectiveId())
					ids:append(pd.to_card:getEffectiveId())
					winner:setTag("kezuhuanjiaIds", ToData(ids))
					room:notifyMoveToPile(winner, ids, skill:objectName(), room:getCardPlace(ids:at(0)), true)
					local card = room:askForUseCard(winner, "@@kezuhuanjia", "kezuhuanjia-use", -1, sgs.Card_MethodUse, true, nil, nil, "huanjiacard")
					room:notifyMoveToPile(winner, ids, skill:objectName(), room:getCardPlace(ids:at(0)), false)
					if card then
						if winner:getMark(card:toString() .. "huanjiada-Clear") > 0 then
							ids = {}
							for _, sk in sgs.list(player:getVisibleSkillList()) do
								if sk:isAttachedLordSkill() then
									continue
								end
								table.insert(ids, sk:objectName())
							end
							if #ids < 1 then
								return
							end
							ids = table.concat(ids, "+")
							ids = room:askForChoice(player, skill:objectName(), ids)
							room:detachSkillFromPlayer(player, ids)
						else
							ids:removeOne(card:getEffectiveId())
							room:obtainCard(player, ids:first())
						end
					end
				end
			end
		end
	end,
}
kezu_hanrong:addSkill(kezuhuanjia)

kezu_hanrong:addSkill("kezuxumin")

sgs.LoadTranslationTable {
	["kezu_hanrong"] = "族韩融",
	["#kezu_hanrong"] = "虎口扳渡",
	["designer:kezu_hanrong"] = "玄蝶既白",
	["illustrator:kezu_hanrong"] = "鬼画府",
	["information:kezu_hanrong"] = "宗族：[颍川·韩氏]",

	["kezulianhe"] = "连和",
	[":kezulianhe"] = "<font color='green'><b>出牌阶段开始时，</b></font>你可以横置两名角色，这些角色下个<font color='green'><b>出牌阶段结束时，</b></font>若其此阶段没有因摸牌而获得手牌，其选择一项：1.令你摸X+1张牌；2.交给你X-1张牌（X为其此阶段获得的手牌数且至多为3）。",
	["kezulianhe:kezulianhe0"] = "你可以发动“连和”横置两名角色",
	["beusekezulianhe"] = "连和",
	["hasdrawlianhe"] = "连和已摸牌",
	["lianhenum"] = "连和获得牌",
	["kezulianhe-ask"] = "你可以选择发动“连和”的两名角色（未处于“连环状态”）",
	["kezulianhegive"] = "你可以选择 %dest 张牌交给 %src ，或点击取消令其摸 %arg 张牌",
	["$kezulianhelogdraw"] = "%from 执行<font color='yellow'><b>“连和”</b></font>效果，令 %to 摸牌",
	["$kezulianheloggive"] = "%from 执行<font color='yellow'><b>“连和”</b></font>效果，选择交给 %to 两张牌",

	["kezuhuanjia"] = "缓颊",
	["#kezuhuanjia"] = "缓颊",

	["kezuhuanjia-use"] = "缓颊：你可以使用一张拼点牌",
	[":kezuhuanjia"] = "<font color='green'><b>出牌阶段结束时，</b></font>你可以拼点，赢的角色可以使用一张拼点牌，若使用的牌：未造成伤害，你获得另一张拼点牌；造成了伤害，你失去一个技能。",

	["$kezuxumin3"] = "[韩融] 江海陆沉，皆为黎庶之泪。",
	["$kezuxumin4"] = "[韩融] 天下汹汹，百姓何辜？",
	["$kezulianhe1"] = "枯草难存于劲风，唯抱簇得生。",
	["$kezulianhe2"] = "吾所来之由，一为好，二为和。",
	["$kezuhuanjia1"] = "我之所言，皆为君好。",
	["$kezuhuanjia2"] = "吾言之切切，请君听之。",

	["~kezu_hanrong"] = "天下兴亡，皆苦百姓。",
}

zu_hanfu = sgs.General(extension, "zu_hanfu", "qun", 4, true, false, false, 3)

zuheta = sgs.CreateTriggerSkillV2 {
	name = "zuheta",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.CardUsed },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			-- 目標記帳已於 on_record 完成
			if use.card:getTypeId() > 0 and use.to:length() > 0
				and (use.card:isKindOf("BasicCard") or use.card:isNDTrick())
				and player:isChained() and player:getMark("&zuheta-Clear") > 0
				and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and not player:isChained()
				and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.CardUsed then return end
		-- 舊版 can_trigger 不限持有者、每事件記帳一次；僅首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		local use = ctx.original_data:toCardUse()
		if use.card:getTypeId() > 0 and use.to:length() > 0 then
			for _, p in sgs.qlist(use.to) do
				player:setMark(p:objectName() .. "zuhetaTo-Clear", 1)
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local aps = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:getMark(p:objectName() .. "zuhetaTo-Clear") < 1 then
					continue
				end
				if use.to:contains(p) or player:canUse(use.card, p) then
					aps:append(p)
				end
			end
			player:setTag("zuheta_data", data)
			aps = room:askForPlayersChosen(player, aps, skill:objectName() .. "$-1", 0, 9, "zuheta0:" .. use.card:objectName(), true)
			if aps:length() > 0 then
				room:setPlayerChained(player)
				for _, p in sgs.qlist(aps) do
					if use.to:contains(p) then
						use.to:removeOne(p)
					else
						use.to:append(p)
					end
				end
				room:sortByActionOrder(use.to)
				data:setValue(use)
			end
		elseif event == sgs.EventPhaseStart then
			if player:askForSkillInvoke(skill:objectName() .. "$-1") then
				room:setPlayerMark(player, "&zuheta-Clear", 1)
				room:setPlayerChained(player)
			end
		end
	end,
}
zu_hanfu:addSkill(zuheta)
zuyingxiangvs = sgs.CreateViewAsSkillV2 {
	name = "zuyingxiang",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return request:getPattern() == "@@zuyingxiang!"
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if not player then return nil end
		local dc = sgs.Sanguosha:cloneCard(player:property("zuyingxiangCn"):toString())
		dc:setSkillName("_zuyingxiang")
		return dc
	end,
}
zuyingxiang = sgs.CreateTriggerSkillV2 {
	name = "zuyingxiang",
	view_as_skill = zuyingxiangvs,
	events = { sgs.EventPhaseEnd },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:getPhase() == sgs.Player_Play and player:canPindian() then
			local cns = {}
			for _, cn in sgs.list(patterns()) do
				local dc = dummyCard(cn)
				if dc:isKindOf("BasicCard") or dc:isNDTrick() and dc:isSingleTargetCard() then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if dc:isAvailable(p) then
							table.insert(cns, cn)
							break
						end
					end
				end
			end
			if #cns > 0 and player:askForSkillInvoke(skill:objectName() .. "$-1") then
				local cn = room:askForChoice(player, skill:objectName(), table.concat(cns, "+"))
				local log = sgs.LogMessage()
				log.type = "$zuyingxiangLog"
				log.from = player
				log.arg = cn
				room:sendLog(log)
				cns = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:canPindian(p) then
						cns:append(p)
					end
				end
				local tp = room:askForPlayerChosen(player, cns, skill:objectName(), "zuyingxiang0")
				if tp then
					local owner = nil
					room:doAnimate(1, player:objectName(), tp:objectName())
					local pd = player:PinDian(tp, skill:objectName())
					if pd.from_number > pd.to_number then
						owner = player
					elseif pd.from_number < pd.to_number then
						owner = tp
					end
					if owner and owner:isAlive() and dummyCard(cn):isAvailable(owner) then
						room:setPlayerProperty(owner, "zuyingxiangCn", ToData(cn))
						room:askForUseCard(owner, "@@zuyingxiang!", "zuyingxiang1:" .. cn)
					end
					if pd.from_card:objectName() == cn or pd.to_card:objectName() == cn then
						if player:hasSkill("kezuxumin", true) and player:getMark("@kezuxumin") < 1 then
							room:addPlayerMark(player, "@kezuxumin")
						end
					elseif player:isAlive() then
						local dc = dummyCard()
						if room:getCardOwner(pd.from_card:getEffectiveId()) == nil then
							dc:addSubcard(pd.from_card)
						end
						if room:getCardOwner(pd.to_card:getEffectiveId()) == nil then
							dc:addSubcard(pd.to_card)
						end
						player:obtainCard(dc)
						cns = {}
						for _, s in sgs.qlist(player:getVisibleSkillList()) do
							if s:isAttachedLordSkill() then
								continue
							end
							table.insert(cns, s:objectName())
						end
						cn = room:askForChoice(player, skill:objectName(), table.concat(cns, "+"))
						room:detachSkillFromPlayer(player, cn)
					end
				end
			end
		end
	end,
}
zu_hanfu:addSkill(zuyingxiang)
zu_hanfu:addSkill("kezuxumin")

sgs.LoadTranslationTable {
	["zu_hanfu"] = "族韩馥",
	["#zu_hanfu"] = "扎钉守角",
	--["designer:zu_hanfu"] = "玄蝶既白",
	--["illustrator:zu_hanfu"] = "鬼画府",
	["information:zu_hanfu"] = "宗族：[颍川·韩氏]",

	["zuheta"] = "和他",
	[":zuheta"] = "出牌阶段开始时，你可以横置，若如此做，本回合你使用牌时，你可以重置，然后额外指定或取消任意名本回合成为过你使用牌的目标的角色。",
	["zuheta0"] = "和他：你可以选择角色为【%src】增加或取消目标",

	["zuyingxiang"] = "迎乡",
	[":zuyingxiang"] = "出牌阶段结束时，你可以声明一种基本牌或单目标普通锦囊牌并进行拼点：赢的角色视为使用你声明的牌，若此牌与任意拼点牌：同牌名，你视为未发动过宗族技；牌名均不同，你获得所有拼点牌并失去一个技能。",
	["zuyingxiang0"] = "迎乡：请选择拼点目标",
	["zuyingxiang1"] = "迎乡：请视为使用【%src】",

	["$kezuxumin5"] = "[韩馥] 不恤袁门恩举，馥无以至今日，况牧一州之民乎？",
	["$kezuxumin6"] = "[韩馥] 民尽主兴袁氏，我又怎能不恤此民意？",
	["$zuheta1"] = "兵者不可为首，待他州发动再和之不迟",
	["$zuheta2"] = "学从袁，职自董，当助袁氏乎？当助董氏乎？",
	["$zuyingxiang1"] = "颖川冲要，不捍大难，冀州虽鄙，堪留余谷",
	["$zuyingxiang2"] = "西山冷冷，众卿莫怀守土依依",
	["$zuyingxiang3"] = "遣骑迎乡人，则韩氏不来唯荀姓独往",

	["~zu_hanfu"] = "动则门生，行必故吏，此馥何主也",
}

--太原王氏
ol_clans.taiyuan_wang = { "wangyun", "wanglie" }
kezu_wangyun = sgs.General(extension, "kezu_wangyun", "qun", 3, true, false, false)

kezujiexuanVS = sgs.CreateViewAsSkillV2 {
	name = "kezujiexuan",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:getMark("@kezujiexuan") > 0
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		local n = player:getChangeSkillState("kezujiexuan")
		return (candidate:isRed() and n == 1) or (candidate:isBlack() and n == 2)
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if not player then return nil end
		local n = player:getChangeSkillState("kezujiexuan")
		local ids = request:getSelectedCardIds()
		if n == 1 then
			local ssqy = sgs.Sanguosha:cloneCard("snatch")
			ssqy:addSubcard(sgs.Sanguosha:getCard(ids:at(0)))
			ssqy:setSkillName("kezujiexuan")
			return ssqy
		elseif n == 2 then
			local ghcq = sgs.Sanguosha:cloneCard("dismantlement")
			ghcq:addSubcard(sgs.Sanguosha:getCard(ids:at(0)))
			ghcq:setSkillName("kezujiexuan")
			return ghcq
		end
	end,
}
kezujiexuan = sgs.CreateTriggerSkillV2 {
	name = "kezujiexuan",
	frequency = sgs.Skill_Limited,
	events = { sgs.PreCardUsed },
	limit_mark = "@kezujiexuan",
	change_skill = true,
	view_as_skill = kezujiexuanVS,
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.PreCardUsed then
			local use = ctx.original_data:toCardUse()
			if table.contains(use.card:getSkillNames(), "kezujiexuan") then
				room:removePlayerMark(player, "@kezujiexuan")
				if player:getChangeSkillState("kezujiexuan") == 1 then
					room:setChangeSkillState(player, "kezujiexuan", 2)
				else
					room:setChangeSkillState(player, "kezujiexuan", 1)
				end
			end
		end
	end,
}
kezu_wangyun:addSkill(kezujiexuan)

kezumingjieCard = sgs.CreateSkillCard {
	name = "kezumingjieCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:removePlayerMark(source, "@kezumingjie")
		room:setPlayerMark(target, "&kezumingjie+#" .. source:objectName(), 1)
		room:addPlayerMark(target, source:objectName() .. "kezumingjie-Clear")
	end,
}
kezumingjieVS = sgs.CreateViewAsSkillV2 {
	name = "kezumingjie",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:getMark("@kezumingjie") > 0
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		return kezumingjieCard:clone()
	end,
}
kezumingjie = sgs.CreateTriggerSkillV2 {
	name = "kezumingjie",
	view_as_skill = kezumingjieVS,
	events = { sgs.CardOffset, sgs.TargetSpecifying, sgs.CardUsed, sgs.EventPhaseChanging },
	frequency = sgs.Skill_Limited,
	limit_mark = "@kezumingjie",
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.TargetSpecifying then
			if player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseChanging then
			-- 舊版 can_trigger 不限持有者、每事件一次；V2 需以實際持有者為 owner
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local holder = room:findPlayerBySkillName(skill:objectName())
				if holder then
					return skill:objectName(), holder
				end
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版每事件記帳一次；僅首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		if event == sgs.CardOffset then
			local effect = ctx.original_data:toCardEffect()
			local tag = player:getTag("kezumingjieToGet"):toIntList()
			tag:append(effect.card:getEffectiveId())
			player:setTag("kezumingjieToGet", ToData(tag))
		elseif event == sgs.CardUsed then
			local use = ctx.original_data:toCardUse()
			if use.card:getTypeId() > 0 and use.card:getSuit() == sgs.Card_Spade then
				local tag = player:getTag("kezumingjieToGet"):toIntList()
				tag:append(use.card:getEffectiveId())
				player:setTag("kezumingjieToGet", ToData(tag))
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseChanging then
			local target = ctx.invoker
			--先询问使用再清除之
			for _, wy in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if target:getMark(wy:objectName() .. "kezumingjie-Clear") > 0 then
					continue
				end
				if target:getMark("&kezumingjie+#" .. wy:objectName()) < 1 then
					continue
				end
				room:setPlayerMark(target, "&kezumingjie+#" .. wy:objectName(), 0)
				local tag = target:getTag("kezumingjieToGet"):toIntList()
				while target:isAlive() and tag:length() > 0 do
					local canusecards = sgs.IntList()
					for _, id in sgs.qlist(tag) do
						if not canusecards:contains(id) and room:getCardPlace(id) == sgs.Player_DiscardPile and sgs.Sanguosha:getCard(id):isAvailable(wy) then
							canusecards:append(id)
						end
					end
					if canusecards:isEmpty() then
						break
					end
					room:fillAG(canusecards, wy)
					local to_back = room:askForAG(wy, canusecards, true, skill:objectName())
					room:clearAG(wy)
					if to_back < 0 then
						break
					end
					tag:removeOne(to_back)
					room:addPlayerMark(wy, "kezumingjie-PlayClear", to_back)
					room:askForUseCard(wy, "@@kezumingjiemark", "kezumingjieuseask:" .. sgs.Sanguosha:getCard(to_back):objectName())
				end
			end
			target:removeTag("kezumingjieToGet")
		elseif event == sgs.TargetSpecifying then
			local use = data:toCardUse()
			if use.card:isKindOf("BasicCard") or use.card:isNDTrick() then
				room:setTag("kezumingjieData", data)
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("&kezumingjie+#" .. player:objectName()) > 0 and not use.to:contains(p) and player:askForSkillInvoke(skill:objectName(), ToData("kezumingjie0:" .. p:objectName())) then
						room:broadcastSkillInvoke(skill:objectName())
						room:doAnimate(1, player:objectName(), p:objectName())
						local log = sgs.LogMessage()
						log.type = "#kezumingjiechoose"
						log.from = player
						log.card_str = use.card:toString()
						log.to:append(p)
						room:sendLog(log)
						use.to:append(p)
						room:sortByActionOrder(use.to)
						data:setValue(use)
					end
				end
			end
		end
	end,
}
kezu_wangyun:addSkill(kezumingjie)

kezumingjiemark = sgs.CreateViewAsSkillV2 {
	name = "kezumingjiemark",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return request:getPattern() == "@@kezumingjiemark"
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if not player then return nil end
		local id = player:getMark("kezumingjie-PlayClear")
		return sgs.Sanguosha:getEngineCard(id)
	end,
}
extension:addSkills(kezumingjiemark)

kezuzhongliu = sgs.CreateTriggerSkillV2 {
	name = "kezuzhongliu",
	events = { sgs.PreCardUsed, sgs.CardUsed },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		if event == sgs.CardUsed then
			if use.card:hasFlag("kezuzhongliuBf") then
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				local n = math.random(1, 2)
				if player:getGeneralName():endsWith("wangling") or player:getGeneral2Name():endsWith("wangling") then
					n = n + 2
				elseif player:getGeneralName():endsWith("wanghun") or player:getGeneral2Name():endsWith("wanghun") then
					n = n + 4
				elseif player:getGeneralName():endsWith("wanglun") or player:getGeneral2Name():endsWith("wanglun") then
					n = n + 6
				elseif player:getGeneralName():endsWith("wangchang") or player:getGeneral2Name():endsWith("wangchang") then
					n = n + 8
				elseif player:getGeneralName():endsWith("wangshen") or player:getGeneral2Name():endsWith("wangshen") then
					n = n + 10
				elseif player:getGeneralName():endsWith("wangguang") or player:getGeneral2Name():endsWith("wangguang") then
					n = n + 12
				elseif player:getGeneralName():endsWith("wangmingshan") or player:getGeneral2Name():endsWith("wangmingshan") then
					n = n + 14
				end
				room:broadcastSkillInvoke(skill:objectName(), n, player)
				local sks = {}
				for _, sk in sgs.qlist(player:getVisibleSkillList()) do
					if player:hasInnateSkill(sk:objectName()) then
						if sk:isLimitedSkill() then
							room:setPlayerMark(player, sk:getLimitMark(), 1)
						else
							local translate = sgs.Sanguosha:translate(":" .. sk:objectName())
							if string.find(translate, "限") and string.find(translate, "次") or string.find(translate, "发动次数") then
								table.insert(sks, sk:objectName())
							end
						end
					end
				end
				local ms, fs = player:getMarkNames(), player:getFlagList()
				for _, skn in sgs.list(sks) do
					for _, m in sgs.list(ms) do
						if string.find(m, skn) and not string.find(m, "sgs") and (m:endsWith("-PlayClear") or m:endsWith("-Clear") or m:endsWith("_lun") or m:startsWith("&" .. skn)) then
							room:setPlayerMark(player, m, 0)
						end
					end
					for _, f in sgs.list(fs) do
						if f:startsWith("kezuzhongliuUse:") and string.find(f, skn) then
							local fsp = f:split(":")
							room:addPlayerHistory(player, fsp[2], 0)
							room:setPlayerFlag(player, "-" .. f)
						end
					end
				end
			end
		elseif event == sgs.PreCardUsed then
			if use.card:getTypeId() < 1 then
				local cn = use.card:getClassName()
				if use.card:inherits("LuaSkillCard") then
					cn = "#" .. use.card:objectName()
				end
				room:setPlayerFlag(player, "kezuzhongliuUse:" .. cn)
				return
			end
			local owner = room:getCardOwner(use.card:getEffectiveId())
			--若使用的牌没有主人，或有主人但不是同族的角色，就可以重置
			if
				not (owner and isSameClan(player, owner) and use.m_isHandcard) --或者不是手牌
			then
				room:setCardFlag(use.card, "kezuzhongliuBf")
			end
		end
	end,
}
kezu_wangyun:addSkill(kezuzhongliu)

sgs.LoadTranslationTable {
	["ke_taiyuanwangshi"] = "太原王氏",
	["kezuzhongliu"] = "中流",
	[":kezuzhongliu"] = "宗族技，锁定技，当你使用牌时，若此牌不是同族角色的手牌，你武将牌上的技能视为未发动过。",

	["$kezuzhongliu1"] = "[王允] 国朝汹汹如涌，当如柱石镇之。",
	["$kezuzhongliu2"] = "[王允] 砥中流之柱，其舍我复谁？",
	["$kezuzhongliu3"] = "[王凌] 王门世代骨鲠，皆为国之柱石。",
	["$kezuzhongliu4"] = "[王凌] 行舟至中流而遇浪，大风起兮。",

	["kezu_wangyun"] = "族王允",
	["#kezu_wangyun"] = "曷丧偕亡",
	["designer:kezu_wangyun"] = "玄蝶既白",
	["illustrator:kezu_wangyun"] = "官方",
	["information:kezu_wangyun"] = "宗族：[太原·王氏]",

	["kezujiexuan"] = "解悬",
	[":kezujiexuan"] = "转换技，限定技，阳：你可以将一张红色牌当【顺手牵羊】使用；阴：你可以将一张黑色牌当【过河拆桥】使用。",
	[":kezujiexuan1"] = "转换技，限定技，阳：你可以将一张红色牌当【顺手牵羊】使用。<font color='#01A5AF'><s>阴：你可以将一张黑色牌当【过河拆桥】使用。</s></font>",
	[":kezujiexuan2"] = "转换技，限定技，<font color='#01A5AF'><s>阳：你可以将一张红色牌当【顺手牵羊】使用；</s></font>阴：你可以将一张黑色牌当【过河拆桥】使用。",

	["kezumingjie"] = "铭戒",
	["kezumingjie:kezumingjie0"] = "你可以令 %src 成为此牌的额外目标",
	["kezumingjieuseask"] = "你可以使用此【%src】：选择目标->点击确定",
	[":kezumingjie"] = "限定技，出牌阶段，你可以选择一名角色，直到其下个回合结束，当你使用基本牌或普通锦囊牌指定目标时，你可以令该角色成为此牌的额外目标，且其下个回合结束时，你可以使用弃牌堆中任意张当前回合被使用过的♠牌或被抵消的牌。",
	["#kezumingjiechoose"] = "%to 成为 %card 的额外目标",

	["$kezujiexuan1"] = "允不才，愿以天下苍生为己任。",
	["$kezujiexuan2"] = "愿以此躯为膳，饲天下以太平。",
	["$kezumingjie1"] = "大公至正，恪忠义于国。",
	["$kezumingjie2"] = "此生柱国之志，铭恪于胸。",
	["$"] = "",
	["$"] = "",

	["~kezu_wangyun"] = "获罪于君，当伏大辟以谢天下。",
}

table.insert(ol_clans.taiyuan_wang, "wangling")
kezu_wangling = sgs.General(extension, "kezu_wangling", "wei", 4, true, false, false)

kezubolongCard = sgs.CreateSkillCard {
	name = "kezubolongCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select ~= player
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local choices = {}
		if player:getCardCount() > 0 then
			table.insert(choices, "give")
		end
		local n = player:getHandcardNum()
		if target:getCardCount() >= n then
			table.insert(choices, "jiu")
		end
		if #choices > 0 then
			if room:askForChoice(target, "kezubolong", table.concat(choices, "+")) == "give" then
				local card = room:askForExchange(player, "kezubolong", 1, 1, true, "kezubolongchoose:1:" .. target:objectName(), false)
				if card then
					room:giveCard(player, target, card, "kezubolong")
				end
				local dc = sgs.Sanguosha:cloneCard("thunder_slash")
				dc:setSkillName("_kezubolong")
				if player:canUse(dc, target) then
					room:useCard(sgs.CardUseStruct(dc, player, target), true)
				end
				dc:deleteLater()
			else
				local card = room:askForExchange(target, "kezubolong", n, n, true, "kezubolongchoose:" .. n .. ":" .. player:objectName(), false)
				if card then
					room:giveCard(target, player, card, "kezubolong")
				end
				local dc = sgs.Sanguosha:cloneCard("analeptic")
				dc:setSkillName("_kezubolong")
				if target:canUse(dc, player) then
					room:useCard(sgs.CardUseStruct(dc, target, player), true)
				end
				dc:deleteLater()
			end
		end
	end,
}

kezubolong = sgs.CreateViewAsSkillV2 {
	name = "kezubolong",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return (not player:hasUsed("#kezubolongCard"))
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		return kezubolongCard:clone()
	end,
}
kezu_wangling:addSkill(kezubolong)
kezu_wangling:addSkill("kezuzhongliu")

sgs.LoadTranslationTable {
	["kezu_wangling"] = "族王凌",
	["#kezu_wangling"] = "荧惑守斗",
	["designer:kezu_wangling"] = "玄蝶既白",
	["illustrator:kezu_wangling"] = "官方",
	["information:kezu_wangling"] = "宗族：[太原·王氏]",

	["kezubolong"] = "驳龙",
	["kezubolongchoose"] = "驳龙：请选择%src张牌交给%dest",
	["kezubolong:give"] = "其交给你一张牌，然后其视为对你使用一张雷【杀】",
	["kezubolong:jiu"] = "你交给等同于其手牌数的牌，然后视为对其使用一张【酒】",
	[":kezubolong"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.你交给其一张牌，然后视为对其使用一张雷【杀】；2.其交给你X张牌（X为你的手牌数），然后视为对你使用一张【酒】。",

	["$kezubolong1"] = "驳者，食虎之兽焉，可摄冢虎。",
	["$kezubolong2"] = "主上暗弱，当另择明主侍之。",

	["~kezu_wangling"] = "凌忠心可鉴，死亦未悔。",
}

table.insert(ol_clans.taiyuan_wang, "wanghun")
kezu_wanghun = sgs.General(extension, "kezu_wanghun", "jin", 3, true, false, false)

kezufuxunCard = sgs.CreateSkillCard {
	name = "kezufuxunCard",
	will_throw = false,
	filter = function(self, targets, to_select, source)
		if source:objectName() == to_select:objectName() then
			return false
		end
		if self:subcardsLength() > 0 then
			return true
		end
		return to_select:getHandcardNum() > 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local tri = target:getMark("&kezufuxunmove-PlayClear") < 1
		if self:subcardsLength() < 1 then
			local card_id = room:askForCardChosen(source, target, "h", "kezufuxun")
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
			room:obtainCard(source, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
		else
			room:giveCard(source, target, self, "kezufuxun")
		end
		if (target:getHandcardNum() == source:getHandcardNum()) and tri then
			local ids = room:getAvailableCardList(source, "basic", "kezufuxun")
			if ids:isEmpty() then
				return
			end
			room:fillAG(ids, source)
			local id = room:askForAG(source, ids, true, "kezufuxun", "kezufuxun0:")
			room:clearAG(source)
			if id < 0 then
				return
			end
			room:setPlayerMark(source, "kezufuxunbasic", id)
			room:askForUseCard(source, "@@kezufuxunbasic", "kezufuxunvs-ask")
		end
	end,
}
kezufuxunVS = sgs.CreateViewAsSkillV2 {
	name = "kezufuxun",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not player:hasUsed("#kezufuxunCard")
	end,
	can_select_card = function(skill, request, candidate)
		return not candidate:isEquipped()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() <= 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() == 0 then
			return kezufuxunCard:clone()
		elseif ids:length() == 1 then
			local card = kezufuxunCard:clone()
			card:addSubcard(sgs.Sanguosha:getCard(ids:at(0)))
			return card
		end
	end,
}
kezufuxun = sgs.CreateTriggerSkillV2 {
	name = "kezufuxun",
	view_as_skill = kezufuxunVS,
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版以事件玩家為門（需持有本技能）；on_record 按持有者逐一呼叫，僅事件玩家本人為持有者時記錄
		if not ctx.owner or ctx.owner:objectName() ~= player:objectName() or ctx.instanceID ~= 0 then return end
		if event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			if player:getPhase() == sgs.Player_Play then
				if move.to_place == sgs.Player_PlaceHand and move.to:isAlive() and player:objectName() ~= move.to:objectName() then
					local to = room:findPlayerByObjectName(move.to:objectName())
					room:setPlayerMark(to, "&kezufuxunmove-PlayClear", 1)
				end
				if move.from_places:contains(sgs.Player_PlaceHand) and move.from:isAlive() and player:objectName() ~= move.from:objectName() then
					local from = room:findPlayerByObjectName(move.from:objectName())
					room:setPlayerMark(from, "&kezufuxunmove-PlayClear", 1)
				end
			end
		end
	end,
}
kezu_wanghun:addSkill(kezufuxun)

kezufuxunbasic = sgs.CreateViewAsSkillV2 {
	name = "kezufuxunbasic",
	n = 1,
	response_or_use = true,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return request:getPattern() == "@@kezufuxunbasic"
	end,
	can_select_card = function(skill, request, candidate)
		return request:getSelectedCardIds():length() < 1
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if not player then return nil end
		local ids = request:getSelectedCardIds()
		if ids:length() < 1 then return nil end
		local c = sgs.Sanguosha:getCard(player:getMark("kezufuxunbasic"))
		c = sgs.Sanguosha:cloneCard(c:objectName())
		c:setSkillName("_kezufuxun")
		c:addSubcard(sgs.Sanguosha:getCard(ids:at(0)))
		return c
	end,
}
extension:addSkills(kezufuxunbasic)

kezuchenya = sgs.CreateTriggerSkillV2 {
	name = "kezuchenya",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.ChoiceMade, sgs.SkillTriggered, sgs.CardFinished },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		local holder = nil
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			for _, s in ipairs(use.card:getSkillNames()) do
				if player:hasFlag("kezuchenya_" .. s) then
					holder = true
					break
				end
			end
		elseif event == sgs.SkillTriggered then
			if player:hasFlag("kezuchenya_" .. data:toString()) then
				holder = true
			end
		end
		if not holder then return false end
		-- 舊版 can_trigger 不限持有者、每事件一次；V2 需以實際持有者為 owner
		local owner = room:findPlayerBySkillName(skill:objectName())
		if owner then
			return skill:objectName(), owner
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.ChoiceMade then return end
		-- 舊版每事件記帳一次；僅首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		local struct = ctx.original_data:toString()
		if struct == "" then
			return
		end
		local promptlist = struct:split(":")
		if promptlist[1] ~= "notifyInvoked" or player:hasEquipSkill(promptlist[2]) then
			return
		end
		local translation = sgs.Sanguosha:translate(":" .. promptlist[2])
		if translation ~= ":" .. promptlist[2] then
			for _, t in ipairs(translation:split("，")) do
				if t:endsWith("出牌阶段限一次") then
					player:setFlags("kezuchenya_" .. promptlist[2])
					break
				end
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local target = ctx.invoker
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			for _, s in ipairs(use.card:getSkillNames()) do
				if target:hasFlag("kezuchenya_" .. s) then
					target:setFlags("-kezuchenya_" .. s)
					for _, owner in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
						if owner:isAlive() and target:getHandcardNum() > 0 and owner:askForSkillInvoke(skill:objectName(), ToData(target)) then
							room:broadcastSkillInvoke(skill:objectName())
							room:askForUseCard(target, "@@kezuchenyacz", "kezuchenya-ask", -1, sgs.Card_MethodRecast)
						end
					end
				end
			end
		elseif event == sgs.SkillTriggered then
			if target:hasFlag("kezuchenya_" .. data:toString()) then
				target:setFlags("-kezuchenya_" .. data:toString())
				for _, owner in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					if owner:isAlive() and target:getHandcardNum() > 0 and owner:askForSkillInvoke(skill:objectName(), ToData(target)) then
						room:broadcastSkillInvoke(skill:objectName())
						room:askForUseCard(target, "@@kezuchenyacz", "kezuchenya-ask", -1, sgs.Card_MethodRecast)
					end
				end
			end
		end
	end,
}
kezu_wanghun:addSkill(kezuchenya)

kezuchenyaCard = sgs.CreateSkillCard {
	name = "kezuchenyaCard",
	target_fixed = true,
	will_throw = false,
	mute = true,
	handling_method = sgs.Card_MethodRecast,
	about_to_use = function(self, room, use)
		UseCardRecast(use.from, self, self:getSkillName(), self:subcardsLength())
	end,
}

--重铸
kezuchenyacz = sgs.CreateViewAsSkillV2 {
	name = "kezuchenyacz",
	n = 99,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return request:getPattern() == "@@kezuchenyacz"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		return candidate:nameLength() == player:getHandcardNum()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local card = kezuchenyaCard:clone()
		for _, c in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(sgs.Sanguosha:getCard(c))
		end
		return card
	end,
}
extension:addSkills(kezuchenyacz)

kezu_wanghun:addSkill("kezuzhongliu")

sgs.LoadTranslationTable {
	["kezu_wanghun"] = "族王浑",
	["#kezu_wanghun"] = "献捷横江",
	["designer:kezu_wanghun"] = "玄蝶既白",
	["illustrator:kezu_wanghun"] = "官方",
	["information:kezu_wanghun"] = "宗族：[太原·王氏]",

	["kezufuxun"] = "抚循",
	["kezufuxunbasic"] = "抚循",
	["kezufuxunmove"] = "手牌变化",
	["kezufuxun0"] = "抚循：请选择一种基本牌",
	["kezufuxunvs-ask"] = "抚循：你可以将一张牌当任意基本牌使用",
	[":kezufuxun"] = "出牌阶段限一次，你可以获得或交给一名其他角色一张手牌，然后若其手牌数与你相同且本阶段此前其手牌数没有变化过，你可以将一张牌当任意基本牌使用。",

	["kezuchenya"] = "沉雅",
	["kezuchenyacz"] = "沉雅",
	["kezuchenya-ask"] = "你可以发动“沉雅”重铸牌",
	["kezuchenyaczCard"] = "沉雅",
	[":kezuchenya"] = "当一名角色发动标签含有“<font color='green'><b>出牌阶段限一次</b></font>”的技能后，你可以令其选择是否重铸任意张牌名字数为X的牌（X为其手牌数）。",

	["$kezufuxun1"] = "东吴遗民惶惶，宜抚而不宜罚。",
	["$kezufuxun2"] = "江东新附，不可以严法度之。",
	["$kezuchenya1"] = "喜怒不现于形，此为执中之道。",
	["$kezuchenya2"] = "胸有万丈之海，故而波澜不惊。",
	["$kezuzhongliu5"] = "[王浑] 国潮汹涌，当为中流之砥柱。",
	["$kezuzhongliu6"] = "[王浑] 执剑斩巨浪，息风波者出我辈。",

	["~kezu_wanghun"] = "灭国之功本属我，奈何枉作他人衣。",
}

table.insert(ol_clans.taiyuan_wang, "wanglun")
kezu_wanglun = sgs.General(extension, "kezu_wanglun", "wei", 3, true, false, false)

kezuqiuxinCard = sgs.CreateSkillCard {
	name = "kezuqiuxinCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, from)
		return (#targets < 1) and (to_select:objectName() ~= from:objectName())
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local result = room:askForChoice(target, "kezuqiuxin", "sha+jinnang")
		if result == "sha" then
			room:setPlayerMark(target, "&kezuqiuxinsha+#" .. player:objectName(), 1)
		else
			room:setPlayerMark(target, "&kezuqiuxinjinnang+#" .. player:objectName(), 1)
		end
	end,
}
--主技能
kezuqiuxinVS = sgs.CreateViewAsSkillV2 {
	name = "kezuqiuxin",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not player:hasUsed("#kezuqiuxinCard")
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		return kezuqiuxinCard:clone()
	end,
}

kezuqiuxin = sgs.CreateTriggerSkillV2 {
	name = "kezuqiuxin",
	view_as_skill = kezuqiuxinVS,
	events = { sgs.TargetSpecified },
	frequency = sgs.Skill_NotFrequent,
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			for _, p in sgs.qlist(use.to) do
				local ids = sgs.IntList()
				if use.card:isKindOf("Slash") and p:getMark("&kezuqiuxinsha+#" .. player:objectName()) > 0 then
					room:setPlayerMark(p, "&kezuqiuxinsha+#" .. player:objectName(), 0)
					ids = room:getAvailableCardList(player, "trick", "kezuqiuxin")
				elseif use.card:isNDTrick() and p:getMark("&kezuqiuxinjinnang+#" .. player:objectName()) > 0 then
					room:setPlayerMark(p, "&kezuqiuxinjinnang+#" .. player:objectName(), 0)
					for _, id in sgs.qlist(room:getAvailableCardList(player, "basic", "kezuqiuxin")) do
						if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
							ids:append(id)
						end
					end
				end
				if ids:length() > 0 then
					player:setTag("kezuqiuxinTo", ToData(p))
					room:fillAG(ids, player)
					local id = room:askForAG(player, ids, true, "kezuqiuxin", "kezuqiuxinask")
					room:clearAG(player)
					if id >= 0 then
						ids:removeOne(id)
						local c = sgs.Sanguosha:getCard(id)
						local dc = sgs.Sanguosha:cloneCard(c:objectName())
						dc:setSkillName("_kezuqiuxin")
						if player:canUse(dc, p) then
							room:useCard(sgs.CardUseStruct(dc, player, p))
						end
						dc:deleteLater()
					end
				end
			end
		end
	end,
}
kezu_wanglun:addSkill(kezuqiuxin)

kezujianyuan = sgs.CreateTriggerSkillV2 {
	name = "kezujianyuan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardFinished, sgs.ChoiceMade, sgs.SkillTriggered },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		local found = false
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			for _, s in ipairs(use.card:getSkillNames()) do
				if player:hasFlag("kezujianyuan_" .. s) then
					found = true
					break
				end
			end
		elseif event == sgs.SkillTriggered then
			if player:hasFlag("kezujianyuan_" .. data:toString()) then
				found = true
			end
		end
		if not found then return false end
		-- 舊版 can_trigger 不限持有者、每事件一次；V2 需以實際持有者為 owner
		local owner = room:findPlayerBySkillName(skill:objectName())
		if owner then
			return skill:objectName(), owner
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版每事件記帳一次；僅首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		local data = ctx.original_data
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId() > 0 then
				room:addPlayerMark(player, "sgsjianyuantimes-PlayClear")
			end
		elseif event == sgs.ChoiceMade then
			local skillname = data:toString()
			if skillname == "" then
				return
			end
			local promptlist = skillname:split(":")
			if promptlist[1] ~= "notifyInvoked" or player:hasEquipSkill(promptlist[2]) then
				return
			end
			local translation = sgs.Sanguosha:translate(":" .. promptlist[2])
			local n = player:getMark("sgsjianyuantimes-PlayClear")
			if n > 0 and translation ~= ":" .. promptlist[2] then
				for _, t in ipairs(translation:split("，")) do
					if t:endsWith("出牌阶段限一次") then
						player:setFlags("kezujianyuan_" .. promptlist[2])
						break
					end
				end
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local target = ctx.invoker
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			for _, s in ipairs(use.card:getSkillNames()) do
				if target:hasFlag("kezujianyuan_" .. s) then
					target:setFlags("-kezujianyuan_" .. s)
					local n = target:getMark("sgsjianyuantimes-PlayClear")
					for _, owner in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
						if owner:isAlive() and n > 0 and owner:askForSkillInvoke(skill:objectName(), ToData(target)) then
							room:broadcastSkillInvoke(skill:objectName())
							room:askForUseCard(target, "@@kezujianyuancz", "kezujianyuan-ask:" .. n, -1, sgs.Card_MethodRecast)
						end
					end
				end
			end
		elseif event == sgs.SkillTriggered then
			if target:hasFlag("kezujianyuan_" .. data:toString()) then
				target:setFlags("-kezujianyuan_" .. data:toString())
				local n = target:getMark("sgsjianyuantimes-PlayClear")
				for _, owner in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					if owner:isAlive() and n > 0 and owner:askForSkillInvoke(skill:objectName(), ToData(target)) then
						room:broadcastSkillInvoke(skill:objectName())
						room:askForUseCard(target, "@@kezujianyuancz", "kezujianyuan-ask:" .. n, -1, sgs.Card_MethodRecast)
					end
				end
			end
		end
		--[[
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
				local skillname = use.card:getSkillName()
			if skillname~="" then
				local translation = sgs.Sanguosha:translate(":"..skillname)
			local n = player:getMark("kezujianyuantimes-PlayClear")
			if n>0 and translation~=":"..skillname and string.find(translation,"出牌阶段限一次，") then
				--for _,t in ipairs(translation:split("，")) do
					--if t:endsWith("出牌阶段限一次")
					--then
						for _,owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
							if owner:isAlive() and owner:askForSkillInvoke(self,ToData(player))
							then
								room:broadcastSkillInvoke(self:objectName())
								room:askForUseCard(player, "@@kezujianyuancz", "kezujianyuan-ask:"..n)
							end
						end
						--break
					--end
				--end
			end
			end
		end--]]
	end,
}
kezu_wanglun:addSkill(kezujianyuan)

kezujianyuanCard = sgs.CreateSkillCard {
	name = "kezujianyuanCard",
	target_fixed = true,
	will_throw = false,
	mute = true,
	handling_method = sgs.Card_MethodRecast,
	about_to_use = function(self, room, use)
		UseCardRecast(use.from, self, self:getSkillName(), self:subcardsLength())
	end,
}

--重铸
kezujianyuancz = sgs.CreateViewAsSkillV2 {
	name = "kezujianyuancz",
	n = 99,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return request:getPattern() == "@@kezujianyuancz"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		return candidate:nameLength() == player:getMark("sgsjianyuantimes-PlayClear") and not player:isCardLimited(candidate, sgs.Card_MethodRecast)
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local card = kezujianyuanCard:clone()
		for _, c in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(sgs.Sanguosha:getCard(c))
		end
		return card
	end,
}
extension:addSkills(kezujianyuancz)

kezu_wanglun:addSkill("kezuzhongliu")

sgs.LoadTranslationTable {
	["kezu_wanglun"] = "族王沦",
	["#kezu_wanglun"] = "半缘修道",
	["designer:kezu_wanglun"] = "玄蝶既白",
	["illustrator:kezu_wanglun"] = "官方",
	["information:kezu_wanglun"] = "宗族：[太原·王氏]",

	["kezuqiuxin"] = "求心",
	["kezuqiuxinask"] = "你可以选择一种牌名对其使用",
	["kezuqiuxin:sha"] = "任意一种【杀】",
	["kezuqiuxin:jinnang"] = "任意一种普通锦囊牌",
	["kezuqiuxinsha"] = "求心杀",
	["kezuqiuxinjinnang"] = "求心锦囊",
	[":kezuqiuxin"] = "出牌阶段限一次，你可以令一名其他角色声明一项：1.你使用任意一种【杀】指定其为目标；2.你使用任意普通锦囊牌指定其为目标。然后你下次满足其声明项时，你可以视为执行另一项。",

	["kezujianyuan"] = "简远",
	[":kezujianyuan"] = "当一名角色发动标签含有“<font color='green'><b>出牌阶段限一次</b></font>”的技能后，你可以令其重铸任意张牌名字数为X的牌（X为其本阶段结算完毕的牌数）。",
	["kezujianyuan-ask"] = "简远：你重铸任意张牌名字数为%src的牌",

	["$kezuqiuxin1"] = "此生所求者，顺心意尔。",
	["$kezuqiuxin2"] = "羡孔丘知天命之岁，叹吾生之不达。",
	["$kezujianyuan1"] = "我视天地为三，其为众妙之门。",
	["$kezujianyuan2"] = "昔年孔明有言，宁静方能致远。",
	["$kezuzhongliu7"] = "[王沦] 上善若水，中流而引全局。",
	["$kezuzhongliu8"] = "[王沦] 泽物无声，此真名士风流。",

	["~kezu_wanglun"] = "人间多锦绣，奈何我云不喜。",
}

table.insert(ol_clans.taiyuan_wang, "wangguang")
kezu_wangguang = sgs.General(extension, "kezu_wangguang", "wei", 3, true, false, false)

kezulilunCard = sgs.CreateSkillCard {
	name = "kezulilunCard",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodRecast,
	on_use = function(self, room, player, targets)
		room:setPlayerMark(player, "zhongliulilun", 0)
		local mcard = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:setPlayerMark(player, mcard:objectName() .. "lilun-Clear", 1)
		UseCardRecast(player, self, self:getSkillName(), self:subcardsLength())
		local ids = sgs.IntList()
		for _, card_id in sgs.qlist(self:getSubcards()) do
			if room:getCardPlace(card_id) == sgs.Player_DiscardPile and sgs.Sanguosha:getCard(card_id):isAvailable(player) then
				ids:append(card_id)
			end
		end
		if ids:length() > 0 then
			room:fillAG(ids, player)
			local to_back = room:askForAG(player, ids, true, self:getSkillName())
			room:clearAG(player)
			if to_back > -1 then
				room:setPlayerMark(player, "kezulilunuse", to_back)
				room:askForUseCard(player, "@@kezulilunuse", "kezulilunask:" .. sgs.Sanguosha:getCard(to_back):objectName())
			end
		end
	end,
}

kezulilun = sgs.CreateViewAsSkillV2 {
	name = "kezulilun",
	n = 2,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not player:hasUsed("#kezulilunCard")
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		if player:getMark(candidate:objectName() .. "lilun-Clear") > 0 or player:isCardLimited(candidate, sgs.Card_MethodRecast) then
			return false
		end
		local selected = request:getSelectedCardIds()
		return selected:length() < 1 or sgs.Sanguosha:getCard(selected:at(0)):sameNameWith(candidate)
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 2
	end,
	create_card = function(skill, request)
		local card = kezulilunCard:clone()
		for _, c in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(sgs.Sanguosha:getCard(c))
		end
		return card
	end,
}
kezu_wangguang:addSkill(kezulilun)

kezulilunuse = sgs.CreateViewAsSkillV2 {
	name = "kezulilunuse",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return request:getPattern() == "@@kezulilunuse"
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if not player then return nil end
		return sgs.Sanguosha:getCard(player:getMark("kezulilunuse"))
	end,
}
extension:addSkills(kezulilunuse)

kezujianjiCard = sgs.CreateSkillCard {
	name = "kezujianjiCard",
	filter = function(self, targets, to_select, player)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("kezujianji")
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
			slash:setSkillName("kezujianji")
			room:removePlayerMark(source, "@kezujianji")
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		end
	end,
}
kezujianjiVS = sgs.CreateViewAsSkillV2 {
	name = "kezujianji",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		local pattern = request:getPattern() or ""
		return pattern:startsWith("@@kezujianji")
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("kezujianji")
		return slash
	end,
}

kezujianji = sgs.CreateTriggerSkillV2 {
	name = "kezujianji",
	view_as_skill = kezujianjiVS,
	frequency = sgs.Skill_Limited,
	limit_mark = "@kezujianji",
	global = true,
	events = { sgs.EventPhaseChanging, sgs.CardUsed, sgs.CardResponded, sgs.TargetConfirmed },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				-- 舊版 global 每事件一次；V2 需以實際持有者為 owner，取仍有標記者
				for _, wg in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					if wg:getMark("@kezujianji") > 0 then
						return skill:objectName(), wg
					end
				end
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 global 每事件記帳一次；僅首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		local data = ctx.original_data
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId() > 0 then
				local cur = room:getCurrent()
				if use.from ~= cur and cur:isAdjacentTo(use.from) then
					cur:setMark("kezujianjiuse-Clear", 1)
				end
				if table.contains(use.card:getSkillNames(), skill:objectName()) then
					room:removePlayerMark(use.from, "@kezujianji")
				end
			end
		elseif event == sgs.CardResponded then
			local response = data:toCardResponse()
			if response.m_isUse and response.m_card:getTypeId() > 0 then
				local cur = room:getCurrent()
				if player ~= cur and cur:isAdjacentTo(player) then
					cur:setMark("kezujianjiuse-Clear", 1)
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local cur = room:getCurrent()
			if (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and use.to:contains(player) and player ~= cur and cur:isAdjacentTo(player) then
				cur:setMark("kezujianjitar-Clear", 1)
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
			local target = ctx.invoker
			for _, wg in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if wg:getMark("@kezujianji") > 0 then
					if target:getMark("kezujianjiuse-Clear") < 1 then
						if wg:askForSkillInvoke(skill:objectName(), ToData("kezujianji01:" .. target:objectName())) then
							room:removePlayerMark(wg, "@kezujianji")
							wg:peiyin(skill)
							local aps = SPlayerList(wg, target)
							room:sortByActionOrder(aps)
							room:drawCards(aps, 1, skill:objectName())
						end
					end
					if target:getMark("kezujianjitar-Clear") < 1 then
						room:askForUseCard(wg, "@@kezujianji", "kezujianji02")
					end
				end
			end
		end
	end,
}
kezu_wangguang:addSkill(kezujianji)
kezu_wangguang:addSkill("kezuzhongliu")

sgs.LoadTranslationTable {
	["kezu_wangguang"] = "族王广",
	["#kezu_wangguang"] = "才性离异",
	["designer:kezu_wangguang"] = "玄蝶既白",
	["illustrator:kezu_wangguang"] = "官方",
	["information:kezu_wangguang"] = "宗族：[太原·王氏]",

	["kezulilun"] = "离论",
	["kezulilunask"] = "你可以使用这张【%src】：选择目标->点击确定",

	[":kezulilun"] = "出牌阶段限一次，你可以重铸两张本回合未以此法重铸过的相同牌名的牌，然后你可以使用其中一张牌。",

	["kezujianji"] = "见机",
	["kezujianji:kezujianji01"] = "你可以发动“见机”与 %src 各摸一张牌",
	["kezujianji02"] = "你可以发动“见机”视为使用一张【杀】",
	["kezujianjitar"] = "见机已指定目标",
	["kezujianjiuse"] = "见机已使用牌",
	[":kezujianji"] = "限定技，一名角色的回合结束时，若与其相邻的角色于此回合：没有使用过牌，你可以与其各摸一张牌；没有成为过【杀】或【决斗】的目标，你可以视为使用一张【杀】。",

	["$kezulilun1"] = "明胆异气，不能相生",
	["$kezulilun2"] = "心之与声，明为二物",
	["$kezujianji1"] = "夫谋大事者，非见利而行",
	["$kezujianji2"] = "爽咎由自取，民心自失尔",
	["$kezuzhongliu13"] = "[王广] 潮有信，民有心，当依大势而为",
	["$kezuzhongliu14"] = "[王广] 中流之水不可逆，唯顺尔",

	["~kezu_wangguang"] = "父过盈渊，子愿代父偿……",
}

table.insert(ol_clans.taiyuan_wang, "wangmingshan")
kezu_wangmingshan = sgs.General(extension, "kezu_wangmingshan", "wei", 4, true, false, false)

kezutanque = sgs.CreateTriggerSkillV2 {
	name = "kezutanque",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardFinished },
	global = true,
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.card:getNumber() > 0 and use.card:getTypeId() > 0
			and player:getMark("kezutanque-Clear") < 1
			and player:isAlive() and player:hasTurn() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 global 每事件記帳一次；僅首位持有者記錄。先保存舊點數供效果計算
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		local use = ctx.original_data:toCardUse()
		if use.card:getNumber() > 0 and use.card:getTypeId() > 0 then
			player:setTag("kezutanqueNumPrev", ToData(player:getMark("kezutanqueNum")))
			player:setMark("kezutanqueNum", use.card:getNumber())
			if player:isAlive() and player:hasSkill(skill:objectName(), true) then
				player:setMark("&kezutanque", use.card:getNumber())
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local cha = math.abs(use.card:getNumber() - player:getTag("kezutanqueNumPrev"):toInt())
		local players = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getHp() == cha then
				players:append(p)
			end
		end
		local eny = room:askForPlayerChosen(player, players, skill:objectName(), "kezutanque-ask", true, true)
		if eny then
			player:addMark("kezutanque-Clear")
			room:broadcastSkillInvoke(skill:objectName())
			room:damage(sgs.DamageStruct(skill:objectName(), player, eny))
		end
	end,
}
kezu_wangmingshan:addSkill(kezutanque)

kezushengmoCard = sgs.CreateSkillCard {
	name = "kezushengmoCard",
	will_throw = false,
	filter = function(self, targets, to_select, from)
		local pattern = self:getUserString()
		local use_card = dummyCard(pattern:split("+")[1])
		if use_card:targetFixed() then
			return false
		end
		use_card:setSkillName("kezushengmo")
		local plist = sgs.PlayerList()
		for i = 1, #targets do
			plist:append(targets[i])
		end
		return use_card:targetFilter(plist, to_select, from)
	end,
	feasible = function(self, targets, from)
		local pattern = self:getUserString()
		local dc = dummyCard(pattern:split("+")[1])
		local plist = sgs.PlayerList()
		for i = 1, #targets do
			plist:append(targets[i])
		end
		return dc:targetFixed() or dc:targetsFeasible(plist, from)
	end,
	on_validate = function(self, use)
		local room = use.from:getRoom()
		local cards = {}
		for _, id in sgs.list(room:getDiscardPile()) do
			if use.from:getMark(id .. "shengmoDP-Clear") > 0 then
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
		end
		local cmp = function(a, b)
			return a:getNumber() < b:getNumber()
		end
		table.sort(cards, cmp)
		local theids = sgs.IntList()
		for _, c in sgs.list(cards) do
			if c:getNumber() ~= cards[1]:getNumber() and c:getNumber() ~= cards[#cards]:getNumber() then
				theids:append(c:getEffectiveId())
			end
		end
		room:fillAG(theids, use.from)
		local id = room:askForAG(use.from, theids, true, "kezushengmo", "kezushengmoask")
		room:clearAG(use.from)
		if id < 0 then
			return nil
		end
		room:obtainCard(use.from, id, true)
		local pattern = {}
		for _, pn in sgs.list(self:getUserString():split("+")) do
			if use.from:getMark("kezushengmo_guhuo_remove_" .. pn) < 1 then
				table.insert(pattern, pn)
			end
		end
		pattern = room:askForChoice(use.from, "kezushengmo", table.concat(pattern, "+"))
		room:addPlayerMark(use.from, "kezushengmo_guhuo_remove_" .. pattern)
		local use_card = dummyCard(pattern)
		use_card:setSkillName("_kezushengmo")
		return use_card
	end,
	on_validate_in_response = function(self, from)
		local room = from:getRoom()
		local cards = {}
		for _, id in sgs.list(room:getDiscardPile()) do
			if from:getMark(id .. "shengmoDP-Clear") > 0 then
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
		end
		local cmp = function(a, b)
			return a:getNumber() < b:getNumber()
		end
		table.sort(cards, cmp)
		local theids = sgs.IntList()
		for _, c in sgs.list(cards) do
			if c:getNumber() ~= cards[1]:getNumber() and c:getNumber() ~= cards[#cards]:getNumber() then
				theids:append(c:getEffectiveId())
			end
		end
		room:fillAG(theids, from)
		local id = room:askForAG(from, theids, true, "kezushengmo", "kezushengmoask")
		room:clearAG(from)
		if id < 0 then
			return nil
		end
		room:obtainCard(from, id, true)
		local pattern = {}
		for _, pn in sgs.list(self:getUserString():split("+")) do
			if from:getMark("kezushengmo_guhuo_remove_" .. pn) < 1 then
				table.insert(pattern, pn)
			end
		end
		pattern = room:askForChoice(from, "kezushengmo", table.concat(pattern, "+"))
		room:addPlayerMark(from, "kezushengmo_guhuo_remove_" .. pattern)
		local use_card = dummyCard(pattern)
		use_card:setSkillName("_kezushengmo")
		return use_card
	end,
}
kezushengmoVS = sgs.CreateViewAsSkillV2 {
	name = "kezushengmo",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return false
		end
		local can = false
		local plist
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			plist = patterns()
		else
			plist = request:getPattern():split("+")
		end
		for _, p in sgs.list(plist) do
			local dc = dummyCard(p)
			if dc and dc:getTypeId() == 1 and player:getMark("kezushengmo_guhuo_remove_" .. p) < 1 then
				dc:setSkillName("kezushengmo")
				if (reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY and dc:isAvailable(player))
					or (reason ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY and not player:isLocked(dc)) then
					can = true
					break
				end
			end
		end
		if can == false then
			return false
		end
		local cards = {}
		for i = 0, sgs.Sanguosha:getCardCount() - 1 do
			if player:getMark(i .. "shengmoDP-Clear") > 0 then
				table.insert(cards, sgs.Sanguosha:getCard(i))
			end
		end
		if #cards < 3 then
			return false
		end
		local cmp = function(a, b)
			return a:getNumber() < b:getNumber()
		end
		table.sort(cards, cmp)
		for _, c in sgs.list(cards) do
			if c:getNumber() ~= cards[1]:getNumber() and c:getNumber() ~= cards[#cards]:getNumber() then
				return true
			end
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		local pattern = request:getPattern() or ""
		if pattern == "" then
			-- 出牌階段無 pattern：由 guhuo 宣告（userString）取得牌名
			pattern = request:getUserString() or ""
			if pattern == "" then
				return nil
			end
		end
		local new_card = kezushengmoCard:clone()
		new_card:setUserString(pattern)
		return new_card
	end,
}
kezushengmo = sgs.CreateTriggerSkillV2 {
	name = "kezushengmo",
	view_as_skill = kezushengmoVS,
	guhuo_type = "l",
	priority = { 0, 2 },
	events = { sgs.CardsMoveOneTime, sgs.SwappedPile },
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 can_trigger：target:hasSkill(self, true) → 事件者即持有者
		if not ctx.owner or ctx.owner:objectName() ~= player:objectName() then return end
		if event == sgs.CardsMoveOneTime then
			local move = ctx.original_data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile then
				for _, id in sgs.qlist(move.card_ids) do
					if room:getCardPlace(id) == sgs.Player_DiscardPile then
						room:addPlayerMark(player, id .. "shengmoDP-Clear")
					end
				end
			end
			if move.from_places:contains(sgs.Player_DiscardPile) then
				for _, id in sgs.qlist(move.card_ids) do
					room:setPlayerMark(player, id .. "shengmoDP-Clear", 0)
				end
			end
		else
			for _, m in sgs.list(player:getMarkNames()) do
				if m:endsWith("shengmoDP-Clear") then
					room:setPlayerMark(player, m, 0)
				end
			end
		end
	end,
}
kezu_wangmingshan:addSkill(kezushengmo)

kezu_wangmingshan:addSkill("kezuzhongliu")
sgs.LoadTranslationTable {
	["kezu_wangmingshan"] = "族王明山",
	["#kezu_wangmingshan"] = "擅书多艺",
	["designer:kezu_wangmingshan"] = "玄蝶既白",
	["illustrator:kezu_wangmingshan"] = "官方",
	["information:kezu_wangmingshan"] = "宗族：[太原·王氏]",

	["kezutanque"] = "弹雀",
	["kezutanque-ask"] = "你可以发动“弹雀”对一名角色造成1点伤害",
	[":kezutanque"] = "每回合限一次，当你使用有点数的牌结算后，你可以对一名体力值为X的角色造成1点伤害（X为此牌与你上一张使用的牌的点数差且不为0）。",

	["kezushengmo"] = "剩墨",
	[":kezushengmo"] = "你可以获得一张当前回合置入弃牌堆中的点数不是最大且不是最小的牌，视为使用一张本局游戏你未以此法使用过的基本牌。",
	["kezushengmoask"] = "剩墨：你可以获得一张牌",

	["$kezutanque1"] = "挽弓射莺雀，势惊执刀人",
	["$kezutanque2"] = "吾可射落山雀，亦可毙汝性命",
	["$kezushengmo1"] = "挥毫纵墨，诸君可见砚底之春秋",
	["$kezushengmo2"] = "余墨染青衫，墨尽颜色存",
	["$kezuzhongliu15"] = "[王明山] 既敢居于中流，何惧水漫之厄",
	["$kezuzhongliu16"] = "[王明山] 往昔门庭若鸿，府内俱藏乾坤",

	["~kezu_wangmingshan"] = "一人之罪，王门何辜?",
}

table.insert(ol_clans.taiyuan_wang, "wangchang")
zu_wangchang = sgs.General(extension, "zu_wangchang", "wei", 4)
zukaijiCard = sgs.CreateSkillCard {
	name = "zukaijiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, from)
		return #targets < 1 and to_select:getMark("sgszukaijiTo_lun") < 1 and to_select:canDiscard(from, "h")
	end,
	on_use = function(self, room, player, targets)
		for _, p in sgs.list(targets) do
			room:addPlayerMark(p, "sgszukaijiTo_lun")
			if p:canDiscard(player, "h") then
				local id = room:askForCardChosen(p, player, "h", self:getSkillName(), false, sgs.Card_MethodDiscard)
				if id < 0 then
					continue
				end
				room:throwCard(id, self:getSkillName(), player, p)
				if room:getCardOwner(id) or player:isDead() then
					continue
				end
				local c = sgs.Sanguosha:getCard(id)
				if c:isAvailable(player) then
					local ids = sgs.IntList()
					ids:append(id)
					room:notifyMoveToPile(player, ids, "zukaiji")
					if room:askForUseCard(player, "@@zukaiji", "zukaiji0:" .. c:objectName()) then
						player:drawCards(1, self:getSkillName())
					end
					room:notifyMoveToPile(player, ids, "zukaiji", sgs.Player_DiscardPile, false)
				end
			end
		end
	end,
}
zukaiji = sgs.CreateViewAsSkillV2 {
	name = "zukaiji",
	expand_pile = "#zukaiji",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@@zukaiji"
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:usedTimes("#zukaijiCard") < 1 and player:getHandcardNum() > 0
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
			and request:getPattern() == "@@zukaiji" then
			return player:getPileName(candidate:getEffectiveId()) == "#zukaiji"
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
			and request:getPattern() == "@@zukaiji" then
			return request:getSelectedCardIds():length() == 1
		end
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
			and request:getPattern() == "@@zukaiji" then
			local ids = request:getSelectedCardIds()
			if ids:length() < 1 then
				return nil
			end
			return sgs.Sanguosha:getCard(ids:first())
		end
		return zukaijiCard:clone()
	end,
}
zu_wangchang:addSkill(zukaiji)
zu_wangchang:addSkill("kezuzhongliu")

sgs.LoadTranslationTable {
	["zu_wangchang"] = "族王昶",
	["#zu_wangchang"] = "治论识度",
	--["designer:zu_wangchang"] = "玄蝶既白",
	--["illustrator:zu_wangchang"] = "官方",
	["information:zu_wangchang"] = "宗族：[太原·王氏]",

	["zukaiji"] = "开济",
	[":zukaiji"] = "出牌阶段限一次，你可以令一名本轮未以此法指定过的角色弃置你的一张手牌，然后你可以使用此次弃置的牌，若如此做，你摸一张牌。",
	["zukaiji0"] = "开济：你可以使用此【%src】",
	["#zukaiji"] = "弃置牌",

	["$zukaiji1"] = "开济国朝之心，可曰昭昭",
	["$zukaiji2"] = "开大盛之世，匡大魏之朝",
	["$kezuzhongliu9"] = "[王昶] 吾祖以国为重，故可为之中流",
	["$kezuzhongliu10"] = "[王昶] 铸国之重担，击水之中流",

	["~zu_wangchang"] = "大慎未计，如何长眠于九泉",
}

table.insert(ol_clans.taiyuan_wang, "wangshen")
zu_wangshen = sgs.General(extension, "zu_wangshen", "wei", 3)

zuanran = sgs.CreateTriggerSkillV2 {
	name = "zuanran",
	events = { sgs.EventPhaseStart, sgs.Damaged, sgs.PreCardUsed },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.PreCardUsed then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Play then
				return false
			end
		end
		if player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 can_trigger 只要求存活：PreCardUsed 清標每事件一次，由首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		if event == sgs.PreCardUsed and player:isAlive() then
			local use = ctx.original_data:toCardUse()
			if use.card:getTypeId() > 0 then
				for _, p in sgs.list(room:getAlivePlayers()) do
					room:setPlayerMark(p, "sgszuanranTo-Clear", 0)
				end
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if player:hasSkill(skill:objectName()) and player:askForSkillInvoke(skill:objectName(), data) then
			player:peiyin(skill)
			room:addPlayerMark(player, "&zuanran+#num")
			local n = math.min(4, player:getMark("&zuanran+#num"))
			local tos = room:askForPlayersChosen(player, room:getAlivePlayers(), skill:objectName(), 0, n, "zuanran0:" .. n)
			if tos:isEmpty() then
				room:addPlayerMark(player, "sgszuanranTo-Clear")
				for _, id in sgs.list(player:drawCardsList(n, skill:objectName())) do
					room:addPlayerMark(player, id .. "sgszuanranId-Clear")
				end
			else
				for _, p in sgs.list(tos) do
					room:addPlayerMark(p, "sgszuanranTo-Clear")
					room:doAnimate(1, player:objectName(), p:objectName())
					for _, id in sgs.list(p:drawCardsList(1, skill:objectName())) do
						room:addPlayerMark(p, id .. "sgszuanranId-Clear")
					end
				end
			end
		end
	end,
}
zu_wangshen:addSkill(zuanran)
zuanranbf = sgs.CreateCardLimitSkill {
	name = "#zuanranbf",
	limit_list = function(self, player)
		return "use"
	end,
	limit_pattern = function(self, player, card)
		if player:getMark("sgszuanranTo-Clear") > 0 and player:getMark(card:toString() .. "sgszuanranId-Clear") > 0 then
			return card:toString()
		end
	end,
}
zu_wangshen:addSkill(zuanranbf)

zugaobianvs = sgs.CreateViewAsSkillV2 {
	name = "zugaobian",
	expand_pile = "#zugaobian",
	n = 1,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return request:getPattern() == "@@zugaobian"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		return player:getPileName(candidate:getEffectiveId()) == "#zugaobian" and candidate:isAvailable(player)
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() < 1 then
			return nil
		end
		return sgs.Sanguosha:getCard(ids:first())
	end,
}
zugaobian = sgs.CreateTriggerSkillV2 {
	name = "zugaobian",
	global = true,
	view_as_skill = zugaobianvs,
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging, sgs.CardsMoveOneTime, sgs.DamageDone },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local dps = room:getTag("zugaobianDamage"):toString():split("+")
				if #dps ~= 1 then
					return false
				end
				-- 舊版 global 每事件一次；V2 需以實際持有者為 owner
				local holder = room:findPlayerBySkillName(skill:objectName())
				if holder then
					return skill:objectName(), holder
				end
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 can_trigger 只要求存活：記帳每事件一次，由首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		if not player:isAlive() then return end
		local data = ctx.original_data
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_NotActive then
				room:removeTag("zugaobianDamage")
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile then
				for _, id in sgs.qlist(move.card_ids) do
					player:addMark(id .. "zugaobianId-Clear")
				end
			end
		elseif event == sgs.DamageDone then
			local dps = room:getTag("zugaobianDamage"):toString():split("+")
			if table.contains(dps, player:objectName()) then
				return
			end
			table.insert(dps, player:objectName())
			room:setTag("zugaobianDamage", ToData(table.concat(dps, "+")))
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event ~= sgs.EventPhaseChanging then return end
		local dps = room:getTag("zugaobianDamage"):toString():split("+")
		if #dps ~= 1 then
			return
		end
		local invoker = ctx.invoker
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:objectName() == dps[1] then
				for _, q in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
					if q:objectName() == invoker:objectName() then
						continue
					end
					room:sendCompulsoryTriggerLog(q, skill)
					local ids = sgs.IntList()
					for _, id in sgs.qlist(room:getDiscardPile()) do
						if p:getMark(id .. "zugaobianId-Clear") > 0 and sgs.Sanguosha:getCard(id):isKindOf("Slash") then
							ids:append(id)
						end
					end
					if ids:length() > 0 then
						room:notifyMoveToPile(p, ids, "zugaobian")
						if room:askForUseCard(p, "@@zugaobian", "zugaobian0") then
							continue
						end
					end
					room:loseHp(p, 1, true, q, skill:objectName())
				end
			end
		end
	end,
}
zu_wangshen:addSkill(zugaobian)
zu_wangshen:addSkill("kezuzhongliu")

sgs.LoadTranslationTable {
	["zu_wangshen"] = "族王沈",
	["#zu_wangshen"] = "崇虎田光",
	--["designer:zu_wangshen"] = "玄蝶既白",
	--["illustrator:zu_wangshen"] = "官方",
	["information:zu_wangshen"] = "宗族：[太原·王氏]",

	["zuanran"] = "岸然",
	[":zuanran"] = "出牌阶段开始时或你受到伤害后，你可以选择，1.摸X张牌；2.令至多X名角色各摸一张牌（X为此技能发动次数且至多为4）。然后以此法获得牌的角色本回合使用的下一张牌不能是这些牌。",
	["zugaobian"] = "告变",
	[":zugaobian"] = "锁定技，其他角色回合结束时，若本回合仅有一名角色受到过伤害，你令其选择使用本回合进入弃牌堆的一张【杀】或失去1点体力。",
	["zuanran0"] = "岸然：你可选择至多%src名角色各摸一张牌，否则你摸%src张牌",
	["zugaobian0"] = "告变：请使用其中一张【杀】，否则失去1点体力",
	["#zugaobian"] = "弃牌堆",

	["$zuanran1"] = "此身伟岸，何惧悠悠之口",
	["$zuanran2"] = "天时在彼，何故抱残守缺？",
	["$zugaobian1"] = "帝髦召甲士带兵，欲谋不轨",
	["$zugaobian2"] = "晋公何在，君上欲谋反作乱",
	["$kezuzhongliu11"] = "[王沈] 活水驱沧海，天下大势不可违",
	["$kezuzhongliu12"] = "[王沈] 志随中流之水，可济沧海之云帆",

	["~zu_wangshen"] = "我有从龙之志，何惧万世骂名",
}

--弘农杨氏
ol_clans.hongnong_yang = { "yangzhen", "yangbiao", "yangci", "yangzhi", "yangyan" }
zu_yangci = sgs.General(extension, "zu_yangci", "qun", 3)
zuqieyi = sgs.CreateTriggerSkillV2 {
	name = "zuqieyi",
	events = { sgs.EventPhaseStart, sgs.CardFinished },
	can_trigger = function(skill, event, room, player, data)
		if not (player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Play then
				return false
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId() <= 0 or player:getMark("zuqieyiUse-Clear") < 1 then
				return false
			end
		end
		return skill:objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseStart then
			if player:askForSkillInvoke(skill:objectName() .. "$-1", data) then
				local ids = room:getNCards(2)
				room:fillAG(ids, player)
				room:askForAG(player, ids, true, skill:objectName())
				room:clearAG(player)
				player:addMark("zuqieyiUse-Clear")
				room:returnToTopDrawPile(ids)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			player:addMark(use.card:getSuitString() .. "zuqieyiSuit-Clear")
			if player:getMark(use.card:getSuitString() .. "zuqieyiSuit-Clear") == 1 then
				player:addMark("zuqieyiUse-Clear")
				local ids = room:showDrawPile(player, 1, skill:objectName(), false)
				local c = sgs.Sanguosha:getCard(ids:first())
				if c:getColor() == use.card:getColor() or c:getType() == use.card:getType() then
					player:obtainCard(c)
				else
					c = room:askForExchange(player, skill:objectName(), 1, 1, true, "zuqieyi0")
					if c then
						room:moveCardTo(c, nil, sgs.Player_DrawPile, false)
					end
				end
			end
		end
	end,
}
zu_yangci:addSkill(zuqieyi)
zujianzhi = sgs.CreateTriggerSkillV2 {
	name = "zujianzhi",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.CardUsed },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Finish then
				return false
			end
			if player:isAlive() and player:getMark("zuqieyiUse-Clear") > 0 and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 can_trigger 只要求存活：CardUsed 記帳每事件一次，由首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		if event == sgs.CardUsed and player:isAlive() then
			local use = ctx.original_data:toCardUse()
			if use.card:getTypeId() > 0 then
				player:addMark(use.card:getSuitString() .. "_zujianzhiSuit-Clear")
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local n = player:getMark("zuqieyiUse-Clear")
		room:sendCompulsoryTriggerLog(player, skill)
		local choices = {}
		for i = 1, n do
			table.insert(choices, i)
		end
		local x = room:askForChoice(player, skill:objectName(), table.concat(choices, "+"), data)
		choices = {}
		for _, m in ipairs(player:getMarkNames()) do
			if m:contains("_zujianzhiSuit") and player:getMark(m) > 0 then
				local ms = m:split("_")
				table.insert(choices, ms[1])
			end
		end
		local ids = sgs.IntList()
		for i = 1, tonumber(x) do
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|" .. table.concat(choices, ",")
			judge.good = true
			judge.reason = skill:objectName()
			judge.who = player
			room:judge(judge)
			if player:isDead() then
				return false
			end
			if judge:isGood() then
				if room:getCardOwner(judge.card:getEffectiveId()) == nil then
					ids:append(judge.card:getEffectiveId())
				end
			else
				n = 0
			end
		end
		player:assignmentCards(ids, "zujianzhi|zujianzhi0", room:getAlivePlayers(), ids:length(), ids:length())
		if n == 0 and player:isAlive() then
			room:damage(sgs.DamageStruct(skill:objectName(), nil, player, 1, sgs.DamageStruct_Thunder))
		end
	end,
}
zu_yangci:addSkill(zujianzhi)
zuquhuo = sgs.CreateTriggerSkillV2 {
	name = "zuquhuo",
	global = true,
	events = { sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		local move = data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceHand) and player:isAlive() and move.from:objectName() == player:objectName() and player:getMark("zuquhuoUse-Clear") < 1 then
			if
				move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE
				or move.reason.m_reason == sgs.CardMoveReason_S_REASON_RESPONSE
				or bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
			then
				return false
			end
			local has = false
			for i, id in sgs.qlist(move.card_ids) do
				if move.from_places:at(i) == sgs.Player_PlaceHand then
					local c = sgs.Sanguosha:getCard(id)
					if c:isKindOf("Analeptic") or c:isKindOf("EquipCard") then
						has = true
						break
					end
				end
			end
			if not has then return false end
			-- 舊版 global 每事件一次；V2 需以實際持有者為 owner
			local holder = room:findPlayerBySkillName(skill:objectName())
			if holder then
				return skill:objectName(), holder
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local move = ctx.original_data:toMoveOneTime()
		for i, id in sgs.qlist(move.card_ids) do
			if move.from_places:at(i) == sgs.Player_PlaceHand then
				local c = sgs.Sanguosha:getCard(id)
				if c:isKindOf("Analeptic") or c:isKindOf("EquipCard") then
					player:addMark("zuquhuoUse-Clear")
					if not player:hasSkill(skill:objectName()) then
						break
					end
					local tps = sgs.SPlayerList()
					for _, p in sgs.list(room:getAlivePlayers()) do
						if p:isWounded() and isSameClan(player, p) then
							tps:append(p)
						end
					end
					local n = math.random(1, 2)
					if player:getGeneralName():endsWith("yangxiu") or player:getGeneral2Name():endsWith("yangxiu") then
						n = n + 2
					elseif player:getGeneralName():endsWith("yangbiao") or player:getGeneral2Name():endsWith("yangbiao") then
						n = n + 4
					elseif player:getGeneralName():endsWith("yangzhong") or player:getGeneral2Name():endsWith("yangzhong") then
						n = n + 6
					end
					local tp = room:askForPlayerChosen(player, tps, skill:objectName() .. "$" .. n, "zuquhuo0", true, true)
					if tp then
						room:recover(tp, sgs.RecoverStruct(skill:objectName(), player))
					end
					break
				end
			end
		end
	end,
}
zu_yangci:addSkill(zuquhuo)

sgs.LoadTranslationTable {
	["zu_yangci"] = "族杨赐",
	["#zu_yangci"] = "固世笃忠贞",
	--["designer:zu_yangci"] = "玄蝶既白",
	--["illustrator:zu_yangci"] = "官方",
	["information:zu_yangci"] = "宗族：[弘农·杨氏]",

	["zuqieyi"] = "切议",
	[":zuqieyi"] = "出牌阶段开始时，你可以观看牌堆顶的两张牌，然后你于本回合第一次使用一种花色的牌结算结束后展示牌堆顶的一张牌。若这两张牌颜色或类别相同，则你获得展示的牌，否则你将一张牌置于牌堆顶。",
	["zujianzhi"] = "谏直",
	[":zujianzhi"] = "锁定技，结束阶段，你进行至多X次判定（X为你本回合发动“切议”的次数），然后你将判定牌中你本回合使用过的花色的牌分配给任意角色。若判定牌中有你本回合未使用过的花色的牌，你受到1点无伤害来源的雷电伤害。",
	["zuquhuo"] = "去惑",
	[":zuquhuo"] = "宗族技，当你每回合第一次不因使用、打出或弃置而失去手牌中的【酒】或装备牌后，你可以令一名同族角色回复1点体力。",
	["zuqieyi0"] = "切议：请选择将一张牌置于牌堆顶",
	["zujianzhi0"] = "谏直：请分配这些牌",
	["zuquhuo0"] = "你可以发动“去惑”令一名同族角色回复体力",
	["$zuqieyi1"] = "张角将成祸患，何不庙胜先分之、弱之？",
	["$zuqieyi2"] = "昔授尚书于华光，今剖时弊于朝堂",
	["$zujianzhi1"] = "昔虹贯牛山，管仲谏桓公无近妃宫",
	["$zujianzhi2"] = "臣三尺讲席未冷，岂容佞言惑君？",
	["$zuquhuo1"] = "[杨赐]为师为傅，所在授业解惑",
	["$zuquhuo2"] = "[杨赐]荧惑守心，宋景退殿，惟德可去蛇变",
	["~zu_yangci"] = "泰山颓，梁木坏，哲人萎",
}

table.insert(ol_clans.hongnong_yang, "yangxiu")
zu_yangxiu = sgs.General(extension, "zu_yangxiu", "wei", 3)
zujiewu = sgs.CreateTriggerSkillV2 {
	name = "zujiewu",
	events = { sgs.EventPhaseStart, sgs.TargetSpecified },
	can_trigger = function(skill, event, room, player, data)
		if not (player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Play then
				return false
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:getTypeId() < 1 or player:getMark("zujiewuUse-Clear") < 1 then
				return false
			end
		end
		return skill:objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseStart then
			local tp = room:askForPlayerChosen(player, room:getOtherPlayers(player), skill:objectName(), "zujiewu0", true, true)
			if tp then
				player:peiyin(skill)
				player:addMark("zujiewuUse-Clear")
				room:setPlayerMark(tp, "&zujiewu+#" .. player:objectName() .. "-PlayClear", 1)
				room:setPlayerMark(player, "HandcardVisible_" .. tp:objectName() .. "-PlayClear", 1)
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			for _, p in sgs.list(use.to) do
				if p:objectName() == player:objectName() then
					continue
				end
				for _, p in sgs.list(room:getAllPlayers()) do
					if p:getMark("&zujiewu+#" .. player:objectName() .. "-PlayClear") > 0 and p:getHandcardNum() > 0 and player:askForSkillInvoke(skill:objectName(), data) then
						player:peiyin(skill)
						local id = room:askForCardChosen(player, p, "h", skill:objectName())
						player:addMark("zujiewuUse-Clear")
						if id < 0 then
							break
						end
						room:showCard(p, id)
						local c = sgs.Sanguosha:getCard(id)
						if c:getSuit() == use.card:getSuit() then
							player:drawCards(1, skill:objectName())
						end
						if c:hasTip("zujiewu") then
							c = nil
							if player:getHandcardNum() >= p:getHandcardNum() then
								local prompt = "zujiewu1:" .. p:objectName()
								if player:getHandcardNum() > p:getHandcardNum() then
									prompt = "zujiewu2"
								end
								c = room:askForExchange(player, skill:objectName(), 1, 1, true, prompt, prompt ~= "zujiewu2")
							end
							if c == nil then
								local id2 = room:askForCardChosen(player, p, "h", skill:objectName())
								c = sgs.Sanguosha:getCard(id2)
							end
							if c then
								room:moveCardTo(c, nil, sgs.Player_DrawPile, false)
							end
						end
						room:setCardTip(id, "zujiewu-Clear")
						break
					end
				end
				break
			end
		end
	end,
}
zu_yangxiu:addSkill(zujiewu)
zugaoshivs = sgs.CreateViewAsSkillV2 {
	name = "zugaoshi",
	expand_pile = "#zugaoshi",
	n = 1,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return request:getPattern() == "@@zugaoshi"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		return player:getPileName(candidate:getEffectiveId()) == "#zugaoshi" and candidate:isAvailable(player)
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() < 1 then
			return nil
		end
		return sgs.Sanguosha:getCard(ids:first())
	end,
}
zugaoshi = sgs.CreateTriggerSkillV2 {
	name = "zugaoshi",
	view_as_skill = zugaoshivs,
	events = { sgs.EventPhaseStart, sgs.CardUsed },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Finish then
				return false
			end
			if player:isAlive() and player:getMark("zujiewuUse-Clear") > 0 and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 can_trigger 只要求存活：CardUsed 記帳每事件一次，由首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		if event == sgs.CardUsed and player:isAlive() then
			local use = ctx.original_data:toCardUse()
			if use.card:getTypeId() > 0 then
				player:addMark(use.card:objectName() .. "zugaoshiName-Clear")
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local n = player:getMark("zujiewuUse-Clear")
		if player:askForSkillInvoke(skill:objectName(), data) then
			player:peiyin(skill)
			local ids = sgs.IntList()
			for i = 1, n do
				local id = room:showDrawPile(player, 1, skill:objectName()):first()
				ids:append(id)
				if player:getMark(sgs.Sanguosha:getCard(id):objectName() .. "zugaoshiName-Clear") > 0 or player:isDead() then
					break
				end
				room:getThread():delay()
			end
			while ids:length() > 0 and player:isAlive() do
				room:notifyMoveToPile(player, ids, "zugaoshi")
				local c = room:askForUseCard(player, "@@zugaoshi", "zugaoshi0")
				if c then
					ids:removeOne(c:getEffectiveId())
				else
					break
				end
			end
			if ids:isEmpty() then
				player:drawCards(2, skill:objectName())
			end
			for _, id in sgs.list(ids) do
				if room:getCardPlace(id) == sgs.Player_PlaceTable then
					room:throwCard(id, skill:objectName(), nil)
				end
			end
		end
	end,
}
zu_yangxiu:addSkill(zugaoshi)
zu_yangxiu:addSkill("zuquhuo")

sgs.LoadTranslationTable {
	["zu_yangxiu"] = "族杨修",
	["#zu_yangxiu"] = "皓首邀终始",
	--["designer:zu_yangxiu"] = "玄蝶既白",
	--["illustrator:zu_yangxiu"] = "官方",
	["information:zu_yangxiu"] = "宗族：[弘农·杨氏]",

	["zujiewu"] = "捷悟",
	[":zujiewu"] = "出牌阶段开始时，你可以令一名角色的手牌于本阶段始终对你可见，然后你可以于本阶段使用牌指定其他角色为目标后，你可以展示“捷悟”角色的一张手牌。若这两张牌花色相同，你摸一张牌；若此牌本回合因此展示过，将你与其之中手牌较多的角色的一张牌置于牌堆顶。",
	["zugaoshi"] = "高视",
	[":zugaoshi"] = "结束阶段，你可以亮出牌堆顶的一张牌并重复此流程直到亮出了你于本回合使用过的牌或X张牌（X为你本回合发动“捷悟”的次数），然后你可以使用其中的任意张牌。若你使用了所有亮出的牌，你摸两张牌。",
	["zujiewu0"] = "你可以发动“捷悟”令一名角色的手牌于本阶段始终对你可见",
	["zujiewu1"] = "捷悟：你可以将你或%src一张牌置于牌堆顶",
	["zujiewu2"] = "捷悟：请将你的一张牌置于牌堆顶",
	["zugaoshi0"] = "高视：你可以使用其中的牌",
	["#zugaoshi"] = "高视亮出",
	["$zujiewu1"] = "只此四字，绝、妙、好、辞",
	["$zujiewu2"] = "君侯，他日君若乘上高轩，我当为君揽辔策马！",
	["$zugaoshi1"] = "听风仰德，省览建安辞章",
	["$zugaoshi2"] = "杨宗显迹，高视魏京群英",
	["$zuquhuo3"] = "[杨修]非鱼非我，惟知君侯心意而已",
	["$zuquhuo4"] = "[杨修]依我所教，答记方能无有疑惑",
	["~zu_yangxiu"] = "空晓事而未见老，枉少作而愧对君……",
}

table.insert(ol_clans.hongnong_yang, "yangzhong")
zu_yangzhong = sgs.General(extension, "zu_yangzhong", "qun", 4)
zujuetuCard = sgs.CreateSkillCard {
	name = "zujuetuCard",
	target_fixed = true,
	will_throw = false,
	about_to_use = function(self, room, use) end,
}
zujuetuvs = sgs.CreateViewAsSkillV2 {
	name = "zujuetu",
	n = 4,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		local pattern = request:getPattern() or ""
		return pattern:contains("@@zujuetu")
	end,
	can_select_card = function(skill, request, candidate)
		if request:getPattern() == "@@zujuetu!" then
			for _, id in sgs.qlist(request:getSelectedCardIds()) do
				if sgs.Sanguosha:getCard(id):getSuit() == candidate:getSuit() then
					return false
				end
			end
			return not candidate:isEquipped()
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		if request:getPattern() == "@@zujuetu!" then
			local ids = request:getSelectedCardIds()
			if ids:length() < 1 then
				return false
			end
			local player = request:getInitiator()
			if not player then return false end
			for _, h in sgs.list(player:getHandcards()) do
				local has = false
				for _, id in sgs.qlist(ids) do
					if sgs.Sanguosha:getCard(id):getSuit() == h:getSuit() then
						has = true
					end
				end
				if has == false then
					return false
				end
			end
			return true
		end
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		if request:getPattern() == "@@zujuetu!" then
			local ids = request:getSelectedCardIds()
			if ids:length() < 1 then
				return nil
			end
			local sc = zujuetuCard:clone()
			for _, id in sgs.qlist(ids) do
				sc:addSubcard(sgs.Sanguosha:getCard(id))
			end
			return sc
		end
		local player = request:getInitiator()
		if not player then return nil end
		local dc = sgs.Sanguosha:cloneCard("dismantlement")
		dc:addSubcard(player:getMark("zujuetuId"))
		dc:setSkillName("_zujuetu")
		return dc
	end,
}
zujuetu = sgs.CreateTriggerSkillV2 {
	name = "zujuetu",
	view_as_skill = zujuetuvs,
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Discard or player:isKongcheng() then
				return
			end
			room:sendCompulsoryTriggerLog(player, skill)
			local sc = room:askForUseCard(player, "@@zujuetu!", "zujuetu0")
			if sc == nil then
				sc = zujuetuCard:clone()
				local suits = sgs.IntList()
				for _, h in sgs.list(player:getHandcards()) do
					if suits:contains(h:getSuit()) then
						continue
					end
					suits:append(h:getSuit())
					sc:addSubcard(h)
				end
			end
			local dc = dummyCard()
			for _, id in sgs.list(player:handCards()) do
				if sc:getSubcards():contains(id) then
					continue
				end
				dc:addSubcard(id)
			end
			room:throwCard(dc, skill:objectName(), player)
			local tps = sgs.SPlayerList()
			for _, p in sgs.list(room:getAlivePlayers()) do
				if p:getHandcardNum() > 0 then
					tps:append(p)
				end
			end
			local tp = room:askForPlayerChosen(player, tps, skill:objectName(), "zujuetu1")
			if tp then
				room:doAnimate(1, player:objectName(), tp:objectName())
				dc = room:askForCardShow(tp, player, skill:objectName())
				room:showCard(tp, dc:getEffectiveId())
				for _, h in sgs.list(player:getHandcards()) do
					if h:getSuit() == dc:getSuit() then
						sc = false
					end
				end
				if sc then
					room:damage(sgs.DamageStruct(skill:objectName(), player, tp))
				else
					sc = dummyCard("dismantlement", "zujuetu")
					sc:addSubcard(dc)
					if sc:isAvailable(player) then
						room:setPlayerMark(player, "zujuetuId", dc:getEffectiveId())
						room:askForUseCard(player, "@@zujuetu1!", "zujuetu2")
					end
				end
			end
		end
	end,
}
zu_yangzhong:addSkill(zujuetu)
zukuduCard = sgs.CreateSkillCard {
	name = "zukuduCard",
	will_throw = false,
	handling_method = sgs.Card_MethodRecast,
	filter = function(self, targets, to_select, from)
		return #targets < 1
	end,
	on_use = function(self, room, player, targets)
		room:removePlayerMark(player, "@zukudu")
		room:doSuperLightbox(player, "zukudu")
		UseCardRecast(player, self, self:getSkillName(), self:subcardsLength())
		local n = sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber() - sgs.Sanguosha:getCard(self:getSubcards():last()):getNumber()
		n = math.min(5, math.abs(n))
		for _, tp in ipairs(targets) do
			room:setPlayerMark(tp, "&zukudu", n)
		end
	end,
}
zukuduvs = sgs.CreateViewAsSkillV2 {
	name = "zukudu",
	n = 2,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return player:getMark("@zukudu") > 0 and player:getCardCount() > 0
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		return not player:isCardLimited(candidate, sgs.Card_MethodRecast)
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 2
	end,
	create_card = function(skill, request)
		local card = zukuduCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		return card
	end,
}
zukudu = sgs.CreateTriggerSkillV2 {
	name = "zukudu",
	view_as_skill = zukuduvs,
	frequency = sgs.Skill_Limited,
	limit_mark = "@zukudu",
	events = { sgs.EventPhaseChanging, sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("&zukudu") > 0 then
				local holder = room:findPlayerBySkillName(skill:objectName())
				if holder then
					return skill:objectName(), holder
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_NotActive and player:getMark("zukuduBf") > 0 then
				local holder = room:findPlayerBySkillName(skill:objectName())
				if holder then
					return skill:objectName(), holder
				end
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
			if player:getMark("&zukudu") > 0 then
				room:removePlayerMark(player, "&zukudu")
				player:drawCards(1, skill:objectName())
				if player:getMark("&zukudu") < 1 then
					player:addMark("zukuduBf")
				end
			end
		elseif player:getPhase() == sgs.Player_NotActive and player:getMark("zukuduBf") > 0 then
			player:removeMark("zukuduBf")
			player:gainAnExtraTurn()
		end
	end,
}
zu_yangzhong:addSkill(zukudu)
zu_yangzhong:addSkill("zuquhuo")

sgs.LoadTranslationTable {
	["zu_yangzhong"] = "族杨众",
	["#zu_yangzhong"] = "同舟而济",
	--["designer:zu_yangzhong"] = "玄蝶既白",
	--["illustrator:zu_yangzhong"] = "官方",
	["information:zu_yangzhong"] = "宗族：[弘农·杨氏]",

	["zujuetu"] = "绝途",
	[":zujuetu"] = "锁定技，弃牌阶段开始时，你选择手牌中每种花色的牌各一张，将其余的手牌置入弃牌堆，然后令一名角色展示一张手牌。若你手牌中没有此花色的牌，则你对其造成1点伤害，否则你将此牌当【过河拆桥】使用。",
	["zukudu"] = "苦渡",
	[":zukudu"] = "限定技，出牌阶段，你可以重铸两张牌，令一名角色于其回合结束时摸一张牌直到其以此法获得了X张牌（X为你重铸的牌的点数之差且至多为5），然后其于最后一个以此法获得牌的回合结束后执行一个额外的回合。",
	["zujuetu0"] = "绝途：请选择保留的各花色牌",
	["zujuetu1"] = "绝途：请选择令一名角色展示牌",
	["zujuetu2"] = "绝途：请选择【过河拆桥】使用目标",
	["$zujuetu1"] = "此天子銮驾，尔可有异心耶？",
	["$zujuetu2"] = "断途绝路，莫使凉州人追来！",
	["$zukudu1"] = "大河汤汤，行路艰难辛苦",
	["$zukudu2"] = "羁途苦旅，终见月明花开",
	["$zuquhuo7"] = "[杨众]莫愁前路漫漫，脚下便是归途",
	["$zuquhuo8"] = "[杨众]多疑离情无用，长歌可以当哭",

	["~zu_yangzhong"] = "为之奈何，为之奈何！",
}

zu_yangbiao = sgs.General(extension, "zu_yangbiao", "qun", 3)
zujiannan = sgs.CreateTriggerSkillV2 {
	name = "zujiannan",
	events = { sgs.EventPhaseStart, sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Play then
				return false
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not (move.from_places:contains(sgs.Player_PlaceHand) and player:getMark("zujiannanBf-PlayClear") > 0) then
				return false
			end
		end
		return skill:objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseStart then
			if player:askForSkillInvoke(skill:objectName(), data) then
				player:peiyin(skill)
				player:addMark("zujiannanBf-PlayClear")
				for i, id in sgs.qlist(player:drawCardsList(2, skill:objectName())) do
					if player:handCards():contains(id) then
						room:setCardTip(id, "zujiannan-PlayClear")
						room:setCardFlag(id, "zujiannanBf")
					end
				end
				player:addMark("zujiannanUse-Clear")
			end
		else
			local move = data:toMoveOneTime()
			local has = move.is_last_handcard
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("Global_Dying") then
					return
				end
			end
			for i, id in sgs.qlist(move.card_ids) do
				if has then
					break
				end
				if sgs.Sanguosha:getCard(id):hasFlag("zujiannanBf") then
					for _, h in sgs.qlist(move.from:getHandcards()) do
						if h:hasFlag("zujiannanBf") then
							has = false
						end
					end
					break
				end
			end
			if has then
				local choices = {}
				for _, t in ipairs({ "zujiannan1", "zujiannan2", "zujiannan3", "zujiannan4" }) do
					if player:getMark(t .. "-Clear") < 1 then
						table.insert(choices, t)
					end
				end
				if #choices < 1 then
					return
				end
				room:sendCompulsoryTriggerLog(player, skill:objectName())
				has = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "zujiannan0")
				room:doAnimate(1, player:objectName(), has:objectName())
				local choice = room:askForChoice(player, skill:objectName(), table.concat(choices, "+"), ToData(has))
				player:addMark(choice .. "-Clear")
				if choice == "zujiannan1" then
					room:askForDiscard(has, skill:objectName(), 2, 2, false, true)
				elseif choice == "zujiannan2" then
					has:drawCards(2, skill:objectName())
				elseif choice == "zujiannan3" then
					local dc = dummyCard()
					for _, h in sgs.qlist(has:getCards("he")) do
						if h:isKindOf("EquipCard") then
							dc:addSubcard(h)
						end
					end
					UseCardRecast(has, dc, skill:objectName())
				elseif choice == "zujiannan4" then
					local sc = room:askForCard(has, "TrickCard", "zujiannan4", ToData(player), sgs.Card_MethodNone)
					if sc then
						room:moveCardTo(sc, nil, sgs.Player_DrawPile, true)
					else
						room:loseHp(has, 1, true, player, skill:objectName())
					end
				end
				player:addMark("zujiannanUse-Clear")
			end
		end
	end,
}
zu_yangbiao:addSkill(zujiannan)
zuyichi = sgs.CreateTriggerSkillV2 {
	name = "zuyichi",
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Finish or player:getMark("zujiannanUse-Clear") < 1 then
				return
			end
			local tps = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if player:canPindian(p) then
					tps:append(p)
				end
			end
			local tp = room:askForPlayerChosen(player, tps, skill:objectName(), "zuyichi0", true, true)
			if tp then
				player:peiyin(skill)
				if player:pindian(tp, skill:objectName()) then
					for i = 1, math.min(4, player:getMark("zujiannanUse-Clear")) do
						if i == 1 then
							room:askForDiscard(tp, skill:objectName(), 2, 2, false, true)
						elseif i == 2 then
							tp:drawCards(2, skill:objectName())
						elseif i == 3 then
							local dc = dummyCard()
							for _, h in sgs.qlist(tp:getCards("he")) do
								if h:isKindOf("EquipCard") then
									dc:addSubcard(h)
								end
							end
							UseCardRecast(tp, dc, skill:objectName())
						elseif i == 4 then
							local sc = room:askForCard(tp, "TrickCard", "zujiannan4", ToData(player), sgs.Card_MethodNone)
							if sc then
								room:moveCardTo(sc, nil, sgs.Player_DrawPile, true)
							else
								room:loseHp(tp, 1, true, player, skill:objectName())
							end
						end
					end
				end
			end
		end
	end,
}
zu_yangbiao:addSkill(zuyichi)
zu_yangbiao:addSkill("zuquhuo")

sgs.LoadTranslationTable {
	["zu_yangbiao"] = "族杨彪",
	["#zu_yangbiao"] = "负荷履崎岖",
	--["designer:zu_yangbiao"] = "玄蝶既白",
	--["illustrator:zu_yangbiao"] = "官方",
	["information:zu_yangbiao"] = "宗族：[弘农·杨氏]",

	["zujiannan"] = "间难",
	[":zujiannan"] = "出牌阶段开始时，你可以摸两张牌。若如此做，此阶段一名角色失去所有“间难”牌或最后的手牌后，若无角色处于濒死状态，你令一名角色执行一项：1.弃置两张牌；2.摸两张牌；3.重铸所有装备牌；4.将一张锦囊牌置于牌堆顶或失去1点体力。每回合每个选项限一次。",
	["zuyichi"] = "义叱",
	[":zuyichi"] = "结束阶段，你可以拼点；若你赢，对方依次执行“间难”的前X项（X为你本回合发动“间难”的次数）。",
	["zujiannan1"] = "弃置两张牌",
	["zujiannan2"] = "摸两张牌",
	["zujiannan3"] = "重铸所有装备牌",
	["zujiannan4"] = "将一张锦囊牌置于牌堆顶或失去1点体力",
	["zuyichi0"] = "你可以发动“义叱”进行拼点",
	["$zujiannan1"] = "上既临危遘难，臣当尽节卫主",
	["$zujiannan2"] = "事君不避难，凛身危困间",
	["$zuyichi1"] = "黎民重迁，动易安难，遑论宗庙社稷！",
	["$zuyichi2"] = "捐宗庙，弃园陵，岂是为国事者所为！",
	["$zuquhuo5"] = "[杨彪]君子曰：“臣治烦去惑者也，是以伏死而争。”",
	["$zuquhuo6"] = "[杨彪]杨氏累世清德，当守家风，去三惑",
	["~zu_yangbiao"] = "见华岳松枯，闻五色鸟啼……",
}

zuhuntianyiTr = sgs.CreateTriggerSkillV2 {
	name = "_zuhuntianyi",
	events = { sgs.DamageInflicted },
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if player and player:hasTreasure("_zuhuntianyi") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local tc = player:getTreasure()
			if tc and tc:isKindOf("Huntianyi") then
				room:sendCompulsoryTriggerLog(player, "_zuhuntianyi")
				room:breakCard(tc, player)
				return player:damageRevises(data, -damage.damage)
			end
		end
		return false
	end,
}
zuhuntianyi = sgs.CreateTreasure {
	name = "_zuhuntianyi",
	class_name = "Huntianyi",
	target_fixed = true,
	equip_skill = zuhuntianyiTr,
	on_install = function(self, player)
		local room = player:getRoom()
		room:acquireSkill(player, zuhuntianyiTr, true, true, false)
		return false
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		if player:isAlive() then
			room:sendCompulsoryTriggerLog(player, "_zuhuntianyi")
			local ids = InsertList({}, room:getDrawPile())
			local dc = dummyCard()
			for _, id in sgs.list(RandomList(ids)) do
				local c = sgs.Sanguosha:getCard(id)
				if c:getNumber() == self:getNumber() and c:isKindOf("TrickCard") then
					dc:addSubcard(id)
					if dc:subcardsLength() > 1 then
						break
					end
				end
			end
			player:obtainCard(dc)
		end
		room:detachSkillFromPlayer(player, "_zuhuntianyi", true, true)
		return false
	end,
}
zuhuntianyi:clone(3, 1):setParent(extension)
zuhuntianyi:clone(3, 3):setParent(extension)
zuhuntianyi:clone(3, 10):setParent(extension)
zuhuntianyi:clone(3, 12):setParent(extension)

--吴郡陆氏
ol_clans.wujun_lu = { "luxun", "lumao", "luji", "luyusheng", "lukai" }
zu_luji = sgs.General(extension, "zu_luji", "wu", 3)
zugailan = sgs.CreateTriggerSkillV2 {
	name = "zugailan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.GameStart },
	waked_skills = "_zuhuntianyi",
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_RoundStart then
				return
			end
			room:sendCompulsoryTriggerLog(player, skill)
			local tps = sgs.SPlayerList()
			tps:append(player)
			for _, id in sgs.qlist(room:getDrawPile()) do
				local c = sgs.Sanguosha:getCard(id)
				if c:objectName() == "_zuhuntianyi" then
					room:moveCardTo(c, player, sgs.Player_PlaceTable, true)
					c:use(room, player, tps)
					return
				end
			end
			for _, id in sgs.qlist(room:getDiscardPile()) do
				local c = sgs.Sanguosha:getCard(id)
				if c:objectName() == "_zuhuntianyi" then
					room:moveCardTo(c, player, sgs.Player_PlaceTable, true)
					c:use(room, player, tps)
					return
				end
			end
		else
			local ids = sgs.IntList()
			room:sendCompulsoryTriggerLog(player, skill)
			for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
				if room:getCardOwner(id) == nil and sgs.Sanguosha:getCard(id):objectName() == "_zuhuntianyi" then
					ids:append(id)
				end
			end
			room:shuffleIntoDrawPile(player, ids, skill:objectName(), true)
		end
	end,
}
zu_luji:addSkill(zugailan)
zufennu = sgs.CreateTriggerSkillV2 {
	name = "zufennu",
	events = { sgs.EventPhaseStart, sgs.TargetSpecifying },
	can_trigger = function(skill, event, room, player, data)
		if not (player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Play and player:getPhase() ~= sgs.Player_Start then
				return false
			end
		elseif event == sgs.TargetSpecifying then
			return false
		end
		return skill:objectName()
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版限定持有者本人：TargetSpecifying 記點數
		if not ctx.owner or ctx.owner:objectName() ~= player:objectName() then return end
		if event == sgs.TargetSpecifying then
			local use = ctx.original_data:toCardUse()
			if use.card:getTypeId() > 0 and player:getPile("zufennu_yi"):length() > 0 then
				room:addPlayerMark(player, "&zufennu", use.card:getNumber())
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:getHp() > 0 then
				local tps = room:askForPlayersChosen(player, room:getAlivePlayers(), skill:objectName() .. "$-1", 0, player:getHp(), "zufennu0:" .. player:getHp(), true, true)
				for _, p in sgs.qlist(tps) do
					local dc = room:askForDiscard(p, skill:objectName(), 1, 1, false, true)
					if dc == nil or room:getCardOwner(dc:getEffectiveId()) then
						continue
					end
					player:addToPile("zufennu_yi", dc)
				end
			elseif player:getPhase() == sgs.Player_Start then
				local n = 0
				for _, id in sgs.qlist(player:getPile("zufennu_yi")) do
					n = n + sgs.Sanguosha:getCard(id):getNumber()
				end
				if player:getMark("&zufennu") > n then
					room:setPlayerMark(player, "&zufennu", 0)
					n = dummyCard()
					n:addSubcards(player:getPile("zufennu_yi"))
					player:obtainCard(n)
				end
			end
		end
	end,
}
zu_luji:addSkill(zufennu)
zuzelie = sgs.CreateTriggerSkillV2 {
	name = "zuzelie",
	events = { sgs.CardsMoveOneTime },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		local move = data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceDelayedTrick) then
			if move.from and move.from:getEquips():isEmpty() and move.from:getJudgingArea():isEmpty()
				and isSameClan(player, move.from) and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版無自定 can_trigger → 僅持有者本人觸發；摸牌/棄牌 buff 記帳
		if not ctx.owner or ctx.owner:objectName() ~= player:objectName() then return end
		local move = ctx.original_data:toMoveOneTime()
		if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
			if move.from and move.from:getMark("&zuzelie2Bf-Clear") > 0 then
				local from = BeMan(room, move.from)
				room:setPlayerMark(from, "&zuzelie2Bf-Clear", 0)
				room:askForDiscard(from, skill:objectName(), 1, 1, false, true)
			end
		elseif move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW then
			if move.to and move.to:getMark("&zuzelie1Bf-Clear") > 0 then
				local to = BeMan(room, move.to)
				room:setPlayerMark(to, "&zuzelie1Bf-Clear", 0)
				to:drawCards(1, skill:objectName())
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local move = data:toMoveOneTime()
		local tp = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "zuzelie0", true, true)
		if tp then
			local n = math.random(1, 2)
			if player:getGeneralName():endsWith("lujing") or player:getGeneral2Name():endsWith("lujing") then
				n = n + 2
			end
			player:peiyin(skill, n)
			if room:askForChoice(player, skill:objectName(), "zuzelie1+zuzelie2", data) == "zuzelie1" then
				room:setPlayerMark(tp, "&zuzelie1Bf-Clear", 1)
			else
				room:setPlayerMark(tp, "&zuzelie2Bf-Clear", 1)
			end
		end
	end,
}
zu_luji:addSkill(zuzelie)

sgs.LoadTranslationTable {
	["zu_luji"] = "族陆绩",
	["#zu_luji"] = "探赜执道",
	--["designer:zu_luji"] = "玄蝶既白",
	--["illustrator:zu_luji"] = "官方",
	["information:zu_luji"] = "宗族：[吴郡·陆氏]",

	["zugailan"] = "该览",
	[":zugailan"] = "锁定技，游戏开始时，你将4张【浑天仪】洗入牌堆。回合开始时，你将牌堆或弃牌堆一张【浑天仪】置入装备区。",
	["zufennu"] = "奋驽",
	[":zufennu"] = "出牌阶段开始时，你可以令至多X名角色各弃置一张牌（X为你的体力值），然后将这些牌置于你的武将牌上，称为“逸”。若你拥有“逸”，你使用牌指定目标时，记录此牌点数。准备阶段，若记录的点数大于“逸”的点数之和，你清除记录并获得所有“逸”。",
	["zuzelie"] = "泽烈",
	[":zuzelie"] = "宗族技，当同族角色失去其场上所有牌后，你可以令一名角色本回合下次摸牌/弃牌后，其再摸一张牌/弃一张牌。",
	["zufennu0"] = "你可以发动“奋驽”选择至多%src名角色各弃置一张牌",
	["zufennu_yi"] = "逸",
	["zuzelie0"] = "你可以发动“泽烈”选择一名角色",
	["zuzelie1"] = "其本回合下次摸牌后再摸一张牌",
	["zuzelie2"] = "其本回合下次弃牌后再弃一张牌",
	["zuzelie1Bf"] = "泽烈摸牌",
	["zuzelie2Bf"] = "泽烈弃牌",
	["$zugailan1"] = "春秋几梦聃周事，遘难而今注子云",
	["$zugailan2"] = "顽石哪比经籍重，满船学问压川河",
	["$zufennu1"] = "殚意儒学，功在不舍",
	["$zufennu2"] = "驽牛致远，驽马逸足，赖凤雏之前翱",
	["$zuzelie1"] = "[陆绩]遍览日月星辰，泽其光，沐其烈",
	["$zuzelie2"] = "[陆绩]为政以德，如北宸之烈烈",
	["~zu_luji"] = "郁林远花开正茂，何日魂归吴郡家……",

	["_zuhuntianyi"] = "浑天仪",
	[":_zuhuntianyi"] = "装备牌/宝物<br/><b>宝物技能</b>：锁定技，当你从装备区失去【浑天仪】时，从牌堆获得两张与此牌点数相同的锦囊牌；当你受到伤害时，你销毁此牌并防止此伤害。",
}

table.insert(ol_clans.wujun_lu, "lujing")
zu_lujing = sgs.General(extension, "zu_lujing", "wu", 4)
zutanfengCard = sgs.CreateSkillCard {
	name = "zutanfengCard",
	filter = function(self, targets, to_select, from)
		return #targets < 1 and from:canSlash(to_select)
	end,
	will_throw = false,
	about_to_use = function(self, room, use)
		use.card = dummyCard(nil, "zutanfeng")
		room:setCardFlag(use.card, "SlashIgnoreArmor")
		use.card:cardOnUse(room, use)
	end,
}
zutanfengvs = sgs.CreateViewAsSkillV2 {
	name = "zutanfeng",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not player:hasUsed("#zutanfengCard") and dummyCard():isAvailable(player)
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		return zutanfengCard:clone()
	end,
}
zutanfeng = sgs.CreateTriggerSkillV2 {
	name = "zutanfeng",
	view_as_skill = zutanfengvs,
	events = { sgs.CardFinished },
	can_trigger = function(skill, event, room, player, data)
		if not (player:isAlive() and player:hasSkill(skill:objectName())) then return false end
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and table.contains(use.card:getSkillNames(), skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		if use.card:hasFlag("DamageDone") then
			local n = math.abs(player:getEquips():length() - use.to:first():getEquips():length())
			player:drawCards(n, skill:objectName())
		else
			local dc = dummyCard(nil, "_zutanfeng")
			if use.to:first():isAlive() and use.to:first():canSlash(player, dc, false) and use.to:first():askForSkillInvoke(skill, player, false) then
				room:useCard(sgs.CardUseStruct(dc, use.to:first(), player))
			end
		end
	end,
}
zu_lujing:addSkill(zutanfeng)
zujuewei = sgs.CreateTriggerSkillV2 {
	name = "zujuewei",
	events = { sgs.CardFinished, sgs.TargetSpecified, sgs.TargetConfirmed },
	can_trigger = function(skill, event, room, player, data)
		if not (player and player:isAlive()) then return false end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag("zujuewei1Bf" .. player:objectName()) then
				return skill:objectName(), room:findPlayerBySkillName(skill:objectName())
			end
			for _, p in sgs.qlist(use.to) do
				if use.card:hasFlag("zujuewei1Bf" .. p:objectName()) then
					return skill:objectName(), room:findPlayerBySkillName(skill:objectName())
				end
			end
			return false
		else
			local use = data:toCardUse()
			if event == sgs.TargetConfirmed and not use.to:contains(player) then
				return false
			end
			if use.card:isDamageCard() and player:getCardCount() > 0 and player:hasTurn() and player:getMark("zujueweiUse-Clear") < 1 and player:hasSkill(skill:objectName()) then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag("zujuewei1Bf" .. player:objectName()) then
				room:setCardFlag(use.card, "-zujuewei1Bf" .. player:objectName())
				if room:getCardOwner(use.card:getEffectiveId()) then
					return
				end
				local tps = sgs.SPlayerList()
				for _, t in sgs.qlist(use.to) do
					if t == player or t:isDead() or player:isProhibited(t, use.card) then
						continue
					end
					tps:append(t)
				end
				local tp = room:askForPlayerChosen(player, tps, skill:objectName(), "zujuewei3:" .. use.card:objectName())
				if tp then
					room:useCard(sgs.CardUseStruct(use.card, player, tp))
				end
			end
			for _, p in sgs.qlist(use.to) do
				if room:getCardOwner(use.card:getEffectiveId()) then
					break
				end
				if use.card:hasFlag("zujuewei1Bf" .. p:objectName()) then
					room:setCardFlag(use.card, "-zujuewei1Bf" .. p:objectName())
					local tps = sgs.SPlayerList()
					for _, t in sgs.qlist(use.to) do
						if t == p or t:isDead() or p:isProhibited(t, use.card) then
							continue
						end
						tps:append(t)
					end
					local tp = room:askForPlayerChosen(p, tps, skill:objectName(), "zujuewei3:" .. use.card:objectName())
					if tp then
						room:useCard(sgs.CardUseStruct(use.card, p, tp))
					end
				end
			end
		else
			local use = data:toCardUse()
			local sc = room:askForCard(player, "EquipCard", "zujuewei0", data, sgs.Card_MethodNone)
			if sc then
				local choices = {}
				if not player:isCardLimited(sc, sgs.Card_MethodRecast) then
					table.insert(choices, "zujuewei1")
				end
				if player:canDiscard(player, sc:getEffectiveId()) then
					table.insert(choices, "zujuewei2")
				end
				if #choices < 1 then
					return
				end
				player:skillInvoked(skill, -1)
				player:addMark("zujueweiUse-Clear")
				if room:askForChoice(player, skill:objectName(), table.concat(choices, "+"), data) == "zujuewei1" then
					UseCardRecast(player, sc, skill:objectName())
					room:setCardFlag(use.card, "zujuewei1Bf" .. player:objectName())
				else
					room:throwCard(sc, skill:objectName(), player)
					local nullified_list = use.nullified_list
					table.insert(nullified_list, "_ALL_TARGETS")
					use.nullified_list = nullified_list
					data:setValue(use)
				end
			end
		end
	end,
}
zu_lujing:addSkill(zujuewei)
zu_lujing:addSkill("zuzelie")

sgs.LoadTranslationTable {
	["zu_lujing"] = "族陆景",
	["#zu_lujing"] = "毗陵侯",
	--["designer:zu_lujing"] = "玄蝶既白",
	--["illustrator:zu_lujing"] = "官方",
	["information:zu_lujing"] = "宗族：[吴郡·陆氏]",

	["zutanfeng"] = "探锋",
	[":zutanfeng"] = "出牌阶段限一次，你可以视为对一名其他角色使用一张无视防具且不计入次数的【杀】。若此【杀】造成了伤害，你摸X张牌（X为你与其装备区牌数的差）；若未造成伤害，其可以视为对你使用一张【杀】。",
	["zujuewei"] = "绝围",
	[":zujuewei"] = "每回合限一次，当你使用伤害牌指定目标后，或成为伤害牌目标后，你可以选择一项：重铸一张装备牌，此牌结算后，你视为对其中一名除自己以外的角色使用此牌；弃置一张装备牌，令此牌无效。",
	["zujuewei0"] = "你可以发动“绝围”选择一张装备牌进行重铸或弃置",
	["zujuewei1"] = "重铸此装备牌",
	["zujuewei2"] = "弃置此装备牌",
	["zujuewei3"] = "绝围：请选择此【%src】使用目标",
}

--颖川陈氏
ol_clans.yingchuan_chen = { "chenqun", "chentai", "chenshi", "chenji", "chenchen", "chenzhong", "chenzuo", "chentan" }
zu_chenqun = sgs.General(extension, "zu_chenqun", "wei", 3)
zugezhiCard = sgs.CreateSkillCard {
	name = "zugezhiCard",
	--target_fixed = true,
	filter = function(self, targets, to_select, from, x)
		return #targets < self:subcardsLength()
	end,
	feasible = function(self, targets, from)
		return #targets <= self:subcardsLength()
	end,
	about_to_use = function(self, room, use)
		if use.to:length() < self:subcardsLength() then
			room:giveCard(use.from, use.to:last(), self, "zugezhi")
		else
			for i, id in sgs.qlist(self:getSubcards()) do
				room:giveCard(use.from, use.to:at(i), sgs.Sanguosha:getCard(id), "zugezhi")
			end
		end
	end,
}
zugezhivs = sgs.CreateViewAsSkillV2 {
	name = "zugezhi",
	expand_pile = "#zugezhi",
	n = 2,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return request:getPattern() == "@@zugezhi"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		return player:getPileName(candidate:getId()) == "#zugezhi"
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 2
	end,
	create_card = function(skill, request)
		local sc = zugezhiCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			sc:addSubcard(id)
		end
		return sc
	end,
}
zugezhi = sgs.CreateTriggerSkillV2 {
	name = "zugezhi",
	events = { sgs.Damaged },
	view_as_skill = zugezhivs,
	can_trigger = function(skill, event, room, player, data)
		-- 舊版 can_trigger=alive：每名可發動持有者各自一次
		if not (player and player:isAlive()) then return false end
		local damage = data:toDamage()
		if not (damage.from and damage.from:isAlive()) then return false end
		local names, owners = {}, {}
		for _, p in sgs.qlist(room:getOtherPlayers(damage.from)) do
			if p:isAlive() and p:hasSkill(skill:objectName())
				and (p:objectName() == player:objectName() or p:inMyAttackRange(player))
				and p:getMark("zugezhiUse-Clear") < 1 and p:hasTurn() then
				table.insert(names, skill:objectName())
				table.insert(owners, p:objectName())
			end
		end
		if #names > 0 then
			return table.concat(names, "|"), table.concat(owners, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		-- 舊版每持有者在一次事件中各自詢問；V2 由 owner 各跑一次
		local p = ctx.owner
		local data = ctx.original_data
		local damage = data:toDamage()
		if not (p:isAlive() and p:hasSkill(skill:objectName())
			and (p:objectName() == player:objectName() or p:inMyAttackRange(player))
			and p:getMark("zugezhiUse-Clear") < 1 and p:hasTurn()) then
			return
		end
		if not p:askForSkillInvoke(skill:objectName() .. "$-1", data) then
			return
		end
		p:addMark("zugezhiUse-Clear")
		local ids = sgs.IntList()
		if p:canDiscard("he") then
			local dc = room:askForDiscard(p, skill:objectName(), 1, 1, true)
			if dc and room:getCardOwner(dc:getEffectiveId()) == nil then
				ids = dc:getSubcards()
			end
		end
		if p:canDiscard("he", damage.from) then
			local id = room:askForCardChosen(p, damage.from, "he", skill:objectName(), false, sgs.Card_MethodDiscard)
			if id >= 0 then
				room:throwCard(id, skill:objectName(), damage.from, p)
				if room:getCardOwner(id) == nil then
					ids:append(id)
				end
			end
		end
		if ids:isEmpty() then
			return
		end
		local ctypes = { "zugezhiCan" }
		local has = false
		for _, id in sgs.qlist(ids) do
			local ctype = sgs.Sanguosha:getCard(id):getType()
			if ctype ~= sgs.Sanguosha:getCard(ids:last()):getType() then
				has = true
			end
			table.insert(ctypes, ctype)
		end
		if has then
			has = table.concat(ctypes, "+") .. "-Clear"
			room:setPlayerMark(p, has, 1)
			room:setPlayerMark(damage.from, has, 1)
		end
		if p:isAlive() then
			room:notifyMoveToPile(p, ids, "zugezhi")
			room:askForUseCard(p, "@@zugezhi", "zugezhi0")
		end
	end,
}
zu_chenqun:addSkill(zugezhi)
zugezhibf = sgs.CreateCardLimitSkill {
	name = "#zugezhibf",
	limit_list = function(self, player)
		return "use"
	end,
	limit_pattern = function(self, player, card)
		if card:getTypeId() < 1 then
			return ""
		end
		local has = false
		for _, m in ipairs(player:getMarkNames()) do
			if string.find(m, "zugezhiCan+") then
				if string.find(m, card:getType()) then
					return ""
				end
				has = true
			end
		end
		if has then
			return card:toString()
		end
	end,
}
zu_chenqun:addSkill(zugezhibf)
zumingdianCard = sgs.CreateSkillCard {
	name = "zumingdianCard",
	will_throw = false,
	target_fixed = true,
	handling_method = sgs.Card_MethodRecast,
	on_use = function(self, room, player, targets)
		local has = false
		for i, id in sgs.qlist(self:getSubcards()) do
			local cn = sgs.Sanguosha:getCard(id):objectName()
			room:addPlayerMark(player, cn .. "zumingdianRecast_lun")
			if player:addMark(cn .. "zumingdianUse-Clear") then
				has = true
			end
		end
		UseCardRecast(player, self, "zumingdian", self:subcardsLength())
		if has and player:isAlive() then
			has = {}
			for i, h in sgs.qlist(player:getHandcards()) do
				table.insert(has, h:objectName())
			end
			local ids = room:getDiscardPile()
			for i, id in sgs.qlist(room:getDrawPile()) do
				ids:append(id)
			end
			RandomList(ids)
			for i, id in sgs.qlist(ids) do
				local c = sgs.Sanguosha:getCard(id)
				if c:getTypeId() > 0 or table.contains(has, c:objectName()) then
					continue
				end
				player:obtainCard(c)
				break
			end
		end
	end,
}
zumingdianvs = sgs.CreateViewAsSkillV2 {
	name = "zumingdian",
	n = 998,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@@zumingdian"
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:getHandcardNum() > 0
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		return candidate:isKindOf("BasicCard") and player:getMark(candidate:objectName() .. "zumingdianRecast_lun") < 1 and not player:isCardLimited(candidate, sgs.Card_MethodRecast)
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() >= 1
	end,
	create_card = function(skill, request)
		local card = zumingdianCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			card:addSubcard(id)
		end
		return card
	end,
}
zumingdian = sgs.CreateTriggerSkillV2 {
	name = "zumingdian",
	view_as_skill = zumingdianvs,
	events = { sgs.CardUsed, sgs.Damaged },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.Damaged and player:isAlive() and player:getHandcardNum() > 0 and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 can_trigger 只要求存活：CardUsed 記帳每事件一次，由首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		if event == sgs.CardUsed and player:isAlive() then
			local use = ctx.original_data:toCardUse()
			if use.card:getTypeId() > 0 then
				player:addMark(use.card:objectName() .. "zumingdianUse-Clear")
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:askForUseCard(player, "@@zumingdian", "zumingdian0", -1, sgs.Card_MethodRecast)
	end,
}
zu_chenqun:addSkill(zumingdian)
zushize = sgs.CreateTriggerSkillV2 {
	name = "zushize",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardUsed, sgs.DamageDone },
	waked_skills = "#zushizenf",
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId() > 0 and use.whocard then
				use = room:getUseStruct(use.whocard)
				-- 記帳先於觸發：on_record 已 addMark，故此處判定 < 2
				if use.from and use.from:isAlive() and use.from:getMark("zushizeNum-Clear") < 2
					and use.from:hasSkill(skill:objectName()) then
					return skill:objectName()
				end
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 can_trigger 只要求存活：記帳每事件一次，由首位持有者記錄
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		if not player:isAlive() then return end
		local data = ctx.original_data
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId() > 0 and use.whocard then
				use = room:getUseStruct(use.whocard)
				if use.from and use.from:isAlive() then
					use.from:addMark("zushizeNum-Clear")
				end
			end
		elseif player:getMark("&zushize") > 0 then
			room:setPlayerMark(player, "&zushize", 0)
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		use = room:getUseStruct(use.whocard)
		local tps = sgs.SPlayerList()
		for i, p in sgs.qlist(room:getAlivePlayers()) do
			if isSameClan(use.from, p) then
				tps:append(p)
			end
		end
		local n = math.random(1, 2)
		local tp = room:askForPlayerChosen(use.from, tps, skill:objectName() .. "$" .. n, "zushize0", false, true)
		if tp then
			room:addPlayerMark(tp, "&zushize")
		end
	end,
}
zu_chenqun:addSkill(zushize)
zushizenf = sgs.CreateAttackRangeSkillV2 {
	name = "#zushizenf",
	-- 舊版 AttackRangeSkill::getExtra 為全域修正（不依賴持有者）：用 System 每次查詢跑一次
	holder_selector = sgs.CorrectSkill_System,
	correct_func = function(skill, ctx)
		local primary = ctx:getPrimary()
		if not primary then return nil end
		return primary:getMark("&zushize")
	end,
}
zu_chenqun:addSkill(zushizenf)

sgs.LoadTranslationTable {
	["zu_chenqun"] = "族陈群",
	--["#zu_chenqun"] = "毗陵侯",
	--["designer:zu_chenqun"] = "玄蝶既白",
	--["illustrator:zu_chenqun"] = "官方",
	["information:zu_chenqun"] = "宗族：[颍川·陈氏]",

	["zugezhi"] = "革制",
	[":zugezhi"] = "每回合限一次，当你或你攻击范围内的角色受到伤害后，若伤害来源不为你，你可弃置你与伤害来源各一张牌，且可分配这些牌。若因此弃置牌的类别不同，你与伤害来源本回合只能使用这些类别的牌。",
	["zumingdian"] = "明典",
	[":zumingdian"] = "出牌阶段或当你受到伤害后，你可重铸任意张基本牌（每轮每个牌名限一次）。若你重铸了你本回合使用过的牌名，你获得一张手牌中未拥有牌名的基本牌。",
	["zushize"] = "士则",
	[":zushize"] = "宗族技，锁定技，你于回合内使用牌首次被响应后，你令一名同族角色攻击范围+1，直到其下次受到伤害。",
	["#zugezhi"] = "革制",
	["zugezhi0"] = "革制：你可以分配这些牌",
	["zumingdian0"] = "你可以发动“明典”重铸任意张基本牌",
	["zushize0"] = "士则：请选择令一名同族角色攻击范围+1",
}

table.insert(ol_clans.yingchuan_xun,"xunshi")
zu_xunshi = sgs.General(extension,"zu_xunshi","wei",3,false)
zuqingjueCard = sgs.CreateSkillCard{
	name = "zuqingjueCard",
	target_fixed = true,
	on_use = function(self,room,source,targets)
		local dc = dummyCard()
		local choices = {"zuqingjue2"}
		for _,id in sgs.qlist(self:getSubcards())do
			if room:getCardOwner(id) then continue end
			choices = {"zuqingjue1","zuqingjue2"}
			dc:addSubcard(id)
		end
		for i=1,self:subcardsLength()do
			if #choices<1 or source:isDead() then break end
			local choice = room:askForChoice(source,"zuqingjue",table.concat(choices,"+"))
			table.removeOne(choices,choice)
			if choice=="zuqingjue1" then
				local tp = room:askForPlayerChosen(source,room:getOtherPlayers(source),"zuqingjue","zuqingjue10")
				if tp then
					room:doAnimate(1,source:objectName(),tp:objectName())
					room:giveCard(source,tp,dc,"zuqingjue")
				end
			else
				choice = {}
				for _,h in sgs.qlist(source:getHandcards())do
					table.insert(choice,h:getSuit())
				end
				dc = dummyCard()
				local ids = room:getDiscardPile()
				for _,id in sgs.qlist(room:getDrawPile())do
					ids:append(id)
				end
				for _,id in sgs.qlist(RandomList(ids))do
					local c = sgs.Sanguosha:getCard(id)
					if table.contains(choice,c:getSuit()) then continue end
					table.insert(choice,c:getSuit())
					dc:addSubcard(id)
				end
				source:obtainCard(dc)
			end
		end
	end,
}
zuqingjuevs = sgs.CreateViewAsSkillV2{
	name = "zuqingjue",
	n = 999,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return request:getPattern() == "@@zuqingjue!"
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		if candidate:isEquipped() or player:isJilei(candidate) then return false end
		local x = 0
		for _,h in sgs.qlist(player:getHandcards())do
			if h:getSuit()==candidate:getSuit() then x = x+1 end
		end
		return x>1
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() >= 1
	end,
	create_card = function(skill, request)
		local sc = zuqingjueCard:clone()
		for _,id in sgs.qlist(request:getSelectedCardIds())do
			sc:addSubcard(id)
		end
		return sc
	end,
}
zuqingjue = sgs.CreateTriggerSkillV2{
	name = "zuqingjue",
	view_as_skill = zuqingjuevs,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.HpChanged},
	can_trigger = function(skill, event, room, player, data)
		-- 記帳先於觸發：on_record 已 addMark，故此處判定 < 2
		if player and player:isAlive() and player:getMark("zuqingjueHp-Clear") < 2 and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 can_trigger 只要求存活：每名存活玩家各自記錄 HpChanged 次數
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		if player:isAlive() then
			player:addMark("zuqingjueHp-Clear")
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local s2n = {}
		for _,h in sgs.qlist(player:getHandcards())do
			s2n[h:getSuitString()] = (s2n[h:getSuitString()] or 0)+1
			if s2n[h:getSuitString()]>1 and player:canDiscard(h:getId()) then
				room:askForUseCard(player,"@@zuqingjue!","zuqingjue0:")
				break
			end
		end
	end,
}
zu_xunshi:addSkill(zuqingjue)
zuqingjuebf = sgs.CreateCardLimitSkill{
	name = "#zuqingjuebf" ,
	limit_list = function(self,player)
		return "ignore"
	end,
	limit_pattern = function(self,player,card)
		if player:handCards():contains(card:getId()) and player:hasSkill("zuqingjue") then
			for _,h in sgs.qlist(player:getHandcards())do
				if h:getId()~=card:getId() and h:getSuit()==card:getSuit() then
					return ""
				end
			end
			return card:toString()
		end
	end
}
zu_xunshi:addSkill(zuqingjuebf)
zuxunyingxiang = sgs.CreateTriggerSkillV2{
	name = "zuxunyingxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(skill, event, room, player, data)
		-- 舊版 can_trigger=alive 且效果限定持有者：CardsMoveOneTime 對每位存活玩家逐一呼叫
		if player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceHand) then
				for i,id in sgs.qlist(move.card_ids)do
					local c = sgs.Sanguosha:getCard(id)
					if c:hasFlag("zuxunyingxiangBf"..player:objectName()) then
						if (move.reason.m_reason&sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_USE then
							room:sendCompulsoryTriggerLog(player,skill)
							local aps = sgs.SPlayerList()
							for _,p in sgs.qlist(room:getAllPlayers())do
								if p==player then
									aps:append(p)
								else
									for _,h in sgs.qlist(p:getHandcards())do
										if h:hasTip("zuxunyingxiang") then
											aps:append(p)
											break
										end
									end
								end
							end
							room:drawCards(aps,1,skill:objectName())
						else
							if player:isAlive() and player:getMark("zuxunyingxiangUse_lun")<1 then
								local ts = sgs.Sanguosha:getTriggerSkill("zuqingjue")
								player:addMark("zuxunyingxiangUse_lun")
								if ts then
									local x = player:getMark("zuqingjueHp-Clear")
									player:setMark("zuqingjueHp-Clear",0)
									ts:trigger(sgs.HpChanged,room,player,data)
									player:setMark("zuqingjueHp-Clear",x)
								end
							end
						end
						break
					end
				end
			end
			if move.to_place == sgs.Player_PlaceHand
			and (move.from and move.from:objectName()==player:objectName() or move.reason.m_playerId==player:objectName()) then
				local has = sgs.IntList()
				for i,id in sgs.qlist(move.card_ids)do
					if move.from_places:at(i)==sgs.Player_PlaceHand or move.from_places:at(i)==sgs.Player_PlaceEquip then
						if move.to:hasCard(id) then has:append(id) end
					end
				end
				if has:length()>0 then
					room:sendCompulsoryTriggerLog(player,skill)
					for i,id in sgs.qlist(has)do
						room:setCardTip(id,"zuxunyingxiang")
						room:setCardFlag(id,"zuxunyingxiangBf"..player:objectName())
					end
				end
			end
		end
	end,
}
zu_xunshi:addSkill(zuxunyingxiang)
zu_xunshi:addSkill("kezudaojie")
sgs.LoadTranslationTable{
	["zu_xunshi"] = "族荀莳",
	["#zu_xunshi"] = "屏后点香谱",
	--["designer:zu_xunshi"] = "玄蝶既白",
	--["illustrator:zu_xunshi"] = "鬼画府",
	["information:zu_xunshi"] = "宗族：[颍川·荀氏]",

	["zuqingjue"] = "清绝",
	[":zuqingjue"] = "锁定技，你手牌中每个花色仅一张的牌不计入手牌上限。当你每回合体力值首次变化后，你弃置手牌中任意张花色数量不唯一的牌，并执行等量项：1.将这些牌交给一名其他角色；2.获得手牌中未拥有花色的牌各一张。",
	["zuqingjue0"] = "清绝：请选择手牌弃置",
	["zuqingjue1"] = "将这些牌交给一名其他角色",
	["zuqingjue2"] = "获得手牌中未拥有花色的牌各一张",
	["zuqingjue10"] = "清绝：请选择交给的角色",

	["zuxunyingxiang"] = "萦香",
	[":zuxunyingxiang"] = "锁定技，当其他角色获得你的牌后，将这些牌标记为“萦香”牌。当“萦香”牌被使用后，你和手牌中有“萦香”牌的角色各摸一张牌；若不因使用失去，你发动一次“清绝”（每轮限一次）。",


	["$zuqingjue1"] = "芷兰生深林，非以无人而不芳",
	["$zuqingjue2"] = "节草长于绝涯，唯得清寒而自立",
	["$zuxunyingxiang1"] = "白马簪缨缄数语，明明公议，空留荀香",
	["$zuxunyingxiang2"] = "风丝寸缕轻柔肠，夜雨把盏，屏后萦香",

	["~zu_xunshi"] = "空奁满尘埃，闲愁旧恨一番新",
}


zu_luyusheng = sgs.General(extension,"zu_luyusheng","wu",3,false)
zushixiCard = sgs.CreateSkillCard{
	name = "zushixiCard",
	filter = function(self,targets,to_select,from)
		local dc = dummyCard(self:getUserString())
		if dc:targetFixed() then return false end
		local plist = sgs.PlayerList()
		for i = 1,#targets do plist:append(targets[i]) end
		return dc:targetFilter(plist,to_select,from)
	end,
	feasible = function(self,targets,from)
		local dc = dummyCard(self:getUserString())
		local plist = sgs.PlayerList()
		for i = 1,#targets do plist:append(targets[i]) end
		return dc:targetFixed() or dc:targetsFeasible(plist,from)
	end,
	on_validate = function(self,use)
		local room = use.from:getRoom()
		use.from:skillInvoked("zushixi")
		room:throwCard(self,"zushixi",use.from)
		return dummyCard(self:getUserString(),"_zushixi")
	end,
	on_validate_in_response = function(self,from)
		local room = from:getRoom()
		from:skillInvoked("zushixi")
		room:throwCard(self,"zushixi",from)
		return dummyCard(self:getUserString(),"_zushixi")
	end
}
zushixivs = sgs.CreateViewAsSkillV2{
	name = "zushixi",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			for _,m in sgs.list(player:getMarkNames())do
				if m:endsWith("#zushixi")
				then return true end
			end
			return false
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern() or ""
			for _,m in sgs.list(player:getMarkNames())do
				if m:endsWith("#zushixi") and m:contains(pattern)
				then return true end
			end
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if not player then return nil end
		local pattern = request:getPattern() or ""
		if pattern=="" then
			-- 出牌階段由 juguan 宣告（userString）取得牌名
			pattern = request:getUserString() or ""
			if pattern == "" then return nil end
		end
		local sc = zushixiCard:clone()
		sc:setUserString(pattern)
		for _,c in sgs.qlist(player:getHandcards())do
			if player:getMark("&"..pattern.."+"..c:getSuitString().."_char+#zushixi")>0
			then sc:addSubcard(c) end
		end
		for _,c in sgs.qlist(player:getEquips())do
			if player:getMark("&"..pattern.."+"..c:getSuitString().."_char+#zushixi")>0
			then sc:addSubcard(c) end
		end
		return sc
	end,
}
zushixi = sgs.CreateTriggerSkillV2{
	name = "zushixi",
	events = {sgs.CardUsed},
	juguan_type = "?",
	view_as_skill = zushixivs,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版預設觸發（持有者本人）：記錄使用過的單目標錦囊
		if not ctx.owner or ctx.owner:objectName() ~= player:objectName() then return end
		if (event == sgs.CardUsed) and player:isAlive() then
			local use = ctx.original_data:toCardUse()
			if use.card:isNDTrick() and use.card:isSingleTargetCard()
			and use.card:hasSuit() and player:getMark("zushixiSuit"..use.card:getSuitString())<0 then
				room:setPlayerMark(player,"&"..use.card:objectName().."+"..use.card:getSuitString().."_char+#zushixi",1)
				player:addMark("zushixiSuit"..use.card:getSuitString())
				local cns = player:property("juguan_names"):toString():split(",")
				table.insert(cns,use.card:objectName())
				room:setPlayerProperty(player,"juguan_names",table.concat(cns,","))
			end
		end
	end,
}
zu_luyusheng:addSkill(zushixi)
zujianbaiCard = sgs.CreateSkillCard{
	name = "zujianbaiCard",
	will_throw = false,
	filter = function(self,targets,to_select,from)
		return #targets<1 and to_select~=from
	end,
	on_use = function(self,room,player,targets)
		for _,tp in ipairs(targets)do
			local x = sgs.Sanguosha:getCard(self:getEffectiveId()):getMark("zujianbaiNum-Clear")
			room:giveCard(player,tp,self,"zujianbai")
			player:drawCards(x,"zujianbai")
		end
	end,
}
zujianbaivs = sgs.CreateViewAsSkillV2{
	name = "zujianbai",
	n = 1,
	can_activate = function(skill, request)
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return request:getPattern() == "@@zujianbai!"
	end,
	can_select_card = function(skill, request, candidate)
		return true
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() > 0 then
			local card = zujianbaiCard:clone()
			for _,id in sgs.qlist(ids)do
				card:addSubcard(id)
			end
			return card
		end
		return nil
	end,
}
zujianbai = sgs.CreateTriggerSkillV2{
	name = "zujianbai",
	events = {sgs.CardUsed,sgs.CardFinished,sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag("zujianbaiType") and player:hasSkill(skill:objectName()) and player:getCardCount()>0 then
				return skill:objectName()
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player and player:isAlive() then
				-- 回合結束時對所有有記錄的玩家詢問；舊版每次事件觸發一次
				local holder = room:findPlayerBySkillName(skill:objectName())
				if holder and holder:isAlive() then
					for _,p in sgs.qlist(room:getAllPlayers())do
						if p:getMark("zujianbaiUse-Clear")>0 and p:getCardCount()>0 then
							return skill:objectName(), holder
						end
					end
				end
			end
		end
		return false
	end,
	on_record = function(skill, event, room, player, ctx)
		-- 舊版 can_trigger=alive：每次事件記錄一次（卡上旗標/發動記錄為全域語義）
		local holder = room:findPlayerBySkillName(skill:objectName())
		if not holder or not ctx.owner or ctx.owner:objectName() ~= holder:objectName() then return end
		if (event == sgs.CardUsed) and player and player:isAlive() then
			local use = ctx.original_data:toCardUse()
			if use.card:getTypeId()>0 and player:getMark(use.card:getType().."zujianbaiType-Clear")<1 then
				player:addMark(use.card:getType().."zujianbaiType-Clear")
				room:setCardFlag(use.card,"zujianbaiType")
			end
		end
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			room:sendCompulsoryTriggerLog(player,skill)
			player:addMark("zujianbaiUse-Clear")
			local tc = room:askForCard(player,"..!","zujianbai0",data,sgs.Card_MethodNone)
			if(tc)then
				local dc = dummyCard()
				for _,c in sgs.qlist(player:getCards("he"))do
					if tc:getSuit()==c:getSuit() then
						room:addCardMark(c,"zujianbaiNum-Clear")
						continue
					end
					if player:isCardLimited(c,sgs.Card_MethodRecast) then continue end
					dc:addSubcard(c)
				end
				UseCardRecast(player,dc,skill:objectName())
			end
		else
			for _,p in sgs.qlist(room:getAllPlayers())do
				if p:getMark("zujianbaiUse-Clear")>0 and p:getCardCount()>0 then
					room:askForUseCard(p,"@@zujianbai!","zujianbai1")
				end
			end
		end
	end,
}
zu_luyusheng:addSkill(zujianbai)
zu_luyusheng:addSkill("zuzelie")

sgs.LoadTranslationTable{
	["zu_luyusheng"] = "族陆郁生",
	["#zu_luyusheng"] = "精心坚白",
	--["designer:zu_luyusheng"] = "玄蝶既白",
	--["illustrator:zu_luyusheng"] = "官方",
	["information:zu_luyusheng"] = "宗族：[吴郡·陆氏]",

	["zushixi"] = "拾昔",
	[":zushixi"] = "每局游戏每个花色限一次，你使用一个花色的单目标普通锦囊牌时，记录此牌牌名和花色。当你需要使用记录牌时，你可将你牌中所有对应花色的牌置入弃牌堆，然后视为使用记录牌。",
	["zujianbai"] = "坚白",
	[":zujianbai"] = "锁定技，每回合每种类别限一次，你使用一种类别的牌后，你保留你的牌中一个已有花色的所有牌并重铸其余牌。每回合结束时，若你本回合发动过此技能，你交给一名其他角色一张牌并摸X张牌（X为此牌本回合被保留的次数）。",
	["zujianbai0"] = "坚白：请选择一张牌，保留其花色",
	["zujianbai1"] = "坚白：请选择一张牌交给其他角色",

	["$zushixi1"] = "满枝橘子香，小女窗前贴花黄",
	["$zushixi2"] = "提裙扑流萤，囊灯一盏照夜读",
	["$zujianbai1"] = "阿耶答应我的事，一定能做到",
	["$zujianbai2"] = "花开有期，世间流水终会相逢",
	["~zu_luyusheng"] = "船儿总有码头，鸟儿总有窠，我又往何处去呢？",

	["$zuzelie5"] = "[陆郁生]不许哭，要做个大人",
	["$zuzelie6"] = "[陆郁生]转瞬之景，何故常忧我心",

}


zu_chentai = sgs.General(extension,"zu_chentai","wei",4)
zufenjianCard = sgs.CreateSkillCard{
	name = "zufenjianCard",
	will_throw = false,
	filter = function(self,targets,to_select,from)
		if #targets>0 then return false end
		local x = from:getAttackRange()-to_select:getAttackRange()
		if from:getMark("1zufenjianUse-PlayClear")>0 and x>0 then
			return false
		end
		if from:getMark("2zufenjianUse-PlayClear")>0 and x==0 then
			return false
		end
		if from:getMark("3zufenjianUse-PlayClear")>0 and x<0 then
			return false
		end
		return true
	end,
	on_use = function(self,room,player,targets)
		for i,p in sgs.list(targets)do
			local x = player:getAttackRange()-p:getAttackRange()
			if x>0 then
				room:setPlayerMark(player,"1zufenjianUse-PlayClear",1)
			elseif x==0 then
				room:setPlayerMark(player,"2zufenjianUse-PlayClear",1)
			else
				room:setPlayerMark(player,"3zufenjianUse-PlayClear",1)
			end
			local dc = room:askForDiscard(p,"zufenjian",1,1,false,true)
			if dc and sgs.Sanguosha:getEngineCard(dc:getEffectiveId()):isKindOf("Jink") then
				player:drawCards(1,"zufenjian")
			else
				room:addPlayerMark(player,"zufenjianBf-Clear")
			end
		end
	end,
}
zufenjian = sgs.CreateViewAsSkillV2{
	name = "zufenjian",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			for i=1,3 do
				if player:getMark(i.."zufenjianUse-PlayClear")<1 then
					return true
				end
			end
			return false
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@@zufenjian"
		end
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 0
	end,
	create_card = function(skill, request)
		return zufenjianCard:clone()
	end,
}
zu_chentai:addSkill(zufenjian)
zudongxuCard = sgs.CreateSkillCard{
	name = "zudongxuCard",
	will_throw = false,
	filter = function(self,targets,to_select,from)
		local c = sgs.Sanguosha:getCard(self:getEffectiveId())
		if c:getTypeId()<3 or to_select==from then return false end
		local x = c:getRealCard():toEquipCard():location()
		if not to_select:hasEquipArea(x) then return false end
		local dc = dummyCard()
		dc:setSkillName("zudongxu")
		local plist = sgs.PlayerList()
		for i = 1,#targets do plist:append(targets[i]) end
		return dc:targetFilter(plist,to_select,from)
	end,
	feasible = function(self,targets,from)
		local dc = dummyCard()
		dc:setSkillName("zudongxu")
		local plist = sgs.PlayerList()
		for i = 1,#targets do plist:append(targets[i]) end
		return dc:targetsFeasible(plist,from)
	end,
	on_validate = function(self,use)
		local room = use.from:getRoom()
		use.from:skillInvoked("zudongxu")
		room:setChangeSkillState(use.from,"zudongxu",2)
		local c = sgs.Sanguosha:getCard(self:getEffectiveId())
		local x = c:getRealCard():toEquipCard():location()
		local moves = sgs.CardsMoveList()
		if use.to:first():getEquip(x) then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP,use.to:first():objectName(),"zudongxu","")
			moves:append(sgs.CardsMoveStruct(use.to:first():getEquip(x):getId(),nil,sgs.Player_DiscardPile,reason))
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,use.from:objectName(),"zudongxu","")
		moves:append(sgs.CardsMoveStruct(self:getSubcards(),use.to:first(),sgs.Player_PlaceEquip,reason))
		room:moveCardsAtomic(moves,true)
		local use_card = dummyCard()
		use_card:setSkillName("_zudongxu")
		return use_card
	end,
	on_validate_in_response = function(self,from)
		local room = from:getRoom()
		
		local use_card = dummyCard()
		use_card:setSkillName("_zudongxu")
		return use_card
	end
}
zudongxuVS = sgs.CreateViewAsSkillV2{
	name = "zudongxu",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:getChangeSkillState("zudongxu")==1
			and player:hasEquip() and sgs.Slash_IsAvailable(player)
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = request:getPattern() or ""
			if pattern:contains("slash") and player:getChangeSkillState("zudongxu")==1 then
				return player:hasEquip()
			end
			if pattern:contains("jink") and player:getChangeSkillState("zudongxu")==2 then
				return player:getHandcardNum()<5 and player:getHandcardNum()<player:getAttackRange()
			end
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		return player:getChangeSkillState("zudongxu")==1
		and candidate:isEquipped()
	end,
	card_selection_feasible = function(skill, request)
		local pattern = request:getPattern() or ""
		if pattern:contains("jink") then
			return request:getSelectedCardIds():length() <= 1
		end
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local pattern = request:getPattern() or ""
		if pattern:contains("jink") then
			local dc = sgs.Sanguosha:cloneCard("jink")
			dc:setSkillName("_zudongxu")
			return dc
		end
		local ids = request:getSelectedCardIds()
		if ids:length()>0 then
			local sc = zudongxuCard:clone()
			sc:addSubcard(ids:first())
			return sc
		end
		return nil
	end,
}
zudongxu = sgs.CreateTriggerSkillV2{
	name = "zudongxu",
	view_as_skill = zudongxuVS,
	change_skill = true,
	events = {sgs.PreCardUsed},
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Jink") and table.contains(use.card:getSkillNames(),skill:objectName())
			and player and player:isAlive() and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		player:skillInvoked(skill)
		room:setChangeSkillState(player,"zudongxu",1)
		local x = math.min(5,player:getAttackRange())-player:getHandcardNum()
		player:drawCards(x,skill:objectName())
	end,
}
zu_chentai:addSkill(zudongxu)
zu_chentai:addSkill("zushize")

sgs.LoadTranslationTable{
	["zu_chentai"] = "族陈泰",
	["#zu_chentai"] = "岳峙渊渟",
	--["designer:zu_chentai"] = "玄蝶既白",
	--["illustrator:zu_chentai"] = "官方",
	["information:zu_chentai"] = "宗族：[颍川·陈氏]",

	["zufenjian"] = "奋剑",
	[":zufenjian"] = "出牌阶段每项限一次，你可以选择一名攻击范围：1.小于你；2.等于你；3.大于你的角色。其须弃置一张牌，若弃置的牌为【闪】，你摸一张牌，否则你本回合攻击范围-1。",
	["zudongxu"] = "动虚",
	[":zudongxu"] = "转换技，①你可以将你装备区一张牌置于其他角色装备区（可替换原装备），视为对其使用【杀】②你可以将手牌摸至X张（X为你的攻击范围数且至多为5），视为使用【闪】。",
	[":zudongxu1"] = "转换技，①你可以将你装备区一张牌置于其他角色装备区（可替换原装备），视为对其使用【杀】<font color='#01A5AF'><s>②你可以将手牌摸至X张（X为你的攻击范围数且至多为5），视为使用【闪】</s></font>。",
	[":zudongxu2"] = "转换技，<font color='#01A5AF'><s>①你可以将你装备区一张牌置于其他角色装备区（可替换原装备），视为对其使用【杀】</s></font>②你可以将手牌摸至X张（X为你的攻击范围数且至多为5），视为使用【闪】。",

}


--琅琊诸葛氏
--[[ol_clans.liangya_zhuge = {"zhugeliang","zhugejin","zhugeke","zhugeguo","zhugeshang","zhugedan","zhugejun","zhugezhan"}
zu_zhugeguo = sgs.General(extension,"zu_zhugeguo","shu",3,false)
zufuyaoCard = sgs.CreateSkillCard{
	name = "zufuyaoCard",
	will_throw = false,
	target_fixed = true,
	on_use = function(self,room,player,targets)
		if(player:getChangeSkillState("zufuyao")==1)then
			room:setChangeSkillState(player,"zufuyao",2)
			room:showCard(player,self:getSubcards())
		else
			room:setChangeSkillState(player,"zufuyao",1)
			room:throwCard(self,"zufuyao",player);
		end
		local ids = sgs.IntList()
		for i,id in sgs.qlist(sgs.Sanguosha:getCardNames("TrickCard+^DelayedTrick"))do
			local c = sgs.Sanguosha:getEngineCard(id)
			if c:isSingleTargetCard() and player:getMark(c:objectName().."zufuyaoBan-PlayClear")<1 then
				local dc = dummyCard(c:objectName(),"zufuyao")
				if dc:isAvailable(player) then
					ids:append(id)
				end
			end
		end
		if ids:isEmpty() then return end
		room:fillAG(ids,player)
		local id = room:askForAG(player,ids,false,"zufuyao")
		room:clearAG(player)
		room:setPlayerMark(player,"zufuyaoId",id)
		room:askForUseCard(player,"@@zufuyao","zufuyao0:"..sgs.Sanguosha:getEngineCard(id):objectName())
	end,
}
zufuyaovs = sgs.CreateViewAsSkillV2{
	name = "zufuyao",
	n = 998,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return player:getHandcardNum()>0
		end
		if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return request:getPattern() == "@@zufuyao"
		end
		return false
	end,
	can_select_card = function(skill, request, candidate)
		local player = request:getInitiator()
		if not player then return false end
		if player:getChangeSkillState(skill:objectName())==2 then
			if player:isJilei(candidate) then return false end
		end
		return not candidate:isEquipped()
	end,
	card_selection_feasible = function(skill, request)
		local pattern = request:getPattern() or ""
		if pattern == "@@zufuyao" then
			return request:getSelectedCardIds():length() == 0
		end
		local player = request:getInitiator()
		if not player then return false end
		local sel = {}
		for _,id in sgs.qlist(request:getSelectedCardIds())do
			sel[id] = true
		end
		if player:getChangeSkillState(skill:objectName())==1 then
			local x = 0
			for i,h in sgs.qlist(player:getHandcards())do
				if sel[h:getId()] or h:hasTip("zufuyao")
				then x = x+1 else x = x-1 end
			end
			if x~=0 then return false end
		else
			local x = 0
			for i,h in sgs.qlist(player:getHandcards())do
				if sel[h:getId()] then continue end
				if h:hasTip("zufuyao") then x = x+1 else x = x-1 end
			end
			if x~=0 then return false end
		end
		return request:getSelectedCardIds():length() > 0
	end,
	create_card = function(skill, request)
		local player = request:getInitiator()
		if not player then return nil end
		local pattern = request:getPattern() or ""
		if pattern=="@@zufuyao" then
			local dc = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getEngineCard(player:getMark("zufuyaoId")):objectName())
			dc:setSkillName("_zufuyao")
			return dc
		end
		local ids = request:getSelectedCardIds()
		if ids:length()>0 then
			local card = zufuyaoCard:clone()
			for _,id in sgs.qlist(ids)do
				card:addSubcard(id)
			end
			return card
		end
		return nil
	end,
}
zufuyao = sgs.CreateTriggerSkillV2{
	name = "zufuyao",
	view_as_skill = zufuyaovs,
	change_skill = true,
	events = {sgs.ShowCards},
	on_record = function(skill, event, room, player, ctx)
		-- 舊版預設觸發（持有者本人展示手牌時）：為展示的牌加 tip
		if not ctx.owner or ctx.owner:objectName() ~= player:objectName() then return end
		if (event == sgs.ShowCards) then
			local ids = ctx.original_data:toString():split("+")
			for _,id in ipairs(ids)do
				room:setCardTip(tonumber(id),"zufuyao")
			end
		end
	end,
}
zu_zhugeguo:addSkill(zufuyao)
zufenshi = sgs.CreateTriggerSkillV2{
	name = "zufenshi",
	events = {sgs.CardUsed},
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("TrickCard") and player:getMark("zufenshiUse-Clear")<1
			and player:hasSkill(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local data = ctx.original_data
		local use = data:toCardUse()
		local ks = {}
		for i,p in sgs.qlist(room:getAlivePlayers())do
			if table.contains(ks,p:getKingdom()) then continue end
			table.insert(ks,p:getKingdom())
		end
		for i,p in sgs.qlist(room:getAlivePlayers())do
			if isSameClan(player,p) and p:getHandcardNum()==#ks then
				local x = math.random(1,2)
				if player:askForSkillInvoke(skill:objectName().."$"..x,data) then
					use.extra_use = use.extra_use+1
					data:setValue(use)
				end
				break
			end
		end
	end,
}
zu_zhugeguo:addSkill(zufenshi)]]


return { extension }
