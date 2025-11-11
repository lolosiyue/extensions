extension = sgs.Package("olClan")

local ol_clans = {}
function isSameClan(first, second)
    if first:objectName() == second:objectName() then return true end
	for c,gs in pairs(ol_clans)do
		for _,gn in ipairs(gs)do
			if first:getGeneralName():endsWith(gn) then
				for _,gn2 in ipairs(gs)do
					if second:getGeneralName():endsWith(gn2)
					then return true end
				end
				return false
			end
		end
	end
	return false
end

--==颍川·钟氏==--

local function chsize(tmp)
	if not tmp then
		return 0
    elseif tmp > 240 then
        return 4
    elseif tmp > 225 then
        return 3
    elseif tmp > 192 then
        return 2
    else
        return 1
    end
end
function utf8len(str)
	if type(str)~="string" then str = sgs.Sanguosha:translate(str:objectName()) end
	local length,currentIndex = 0,1
	while currentIndex <= #str do
		local tmp = string.byte(str, currentIndex)
		currentIndex = currentIndex + chsize(tmp)
		length = length + 1
	end
	return length
end

ol_clans.yingchuan_zhong = {"zhonghui"}
zu_zhonghui = sgs.General(extension, "zu_zhonghui", "wei", 4, true, false, false, 3)
zuyuzhi = sgs.CreateTriggerSkill{
	name = "zuyuzhi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.RoundStart, sgs.RoundEnd, sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.RoundStart and not player:isKongcheng() then
		    room:sendCompulsoryTriggerLog(player, self)
			local dc = room:askForExchange(player, self:objectName(), 1, 1, false, "yuzhishow", false)
			local card = sgs.Sanguosha:getCard(dc:getEffectiveId())
			room:showCard(player, dc:getEffectiveId())
			local x = card:nameLength()
			player:drawCards(x,self:objectName())
			room:setPlayerMark(player, "zuyuzhiDraw_lun", x)
			room:setPlayerMark(player, "&zuyuzhi_lun", x)
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
			    room:addPlayerMark(player, "yuzhiUse_lun")
				room:removePlayerMark(player, "&zuyuzhi_lun")
			end
		elseif event == sgs.RoundEnd then
			local o = player:getMark("zuyuzhiNum")
		    local u = player:getMark("yuzhiUse_lun")
			local x = player:getMark("zuyuzhiDraw_lun")
			room:setPlayerMark(player, "zuyuzhiNum", x)
			if u < x or o < x and data:toInt()>1 then
		        room:sendCompulsoryTriggerLog(player, self)
			    local choices = {"losehps"}
				if player:hasSkill("zu_zhong_baozu",true) then
				    table.insert(choices, "removes_zu_zhong_baozu")
				end
				if room:askForChoice(player, "losehoorremoveskill", table.concat(choices, "+")) ~= "losehps"
				then room:detachSkillFromPlayer(player, "zu_zhong_baozu")
				else room:loseHp(player) end
			end
		end
	end,
}
zuxieshu = sgs.CreateTriggerSkill{
	name = "zuxieshu",
	events = {sgs.Damage, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.card and damage.card:getTypeId()>0 then
			local n = damage.card:nameLength()
			if room:askForDiscard(player, self:objectName(), n, n, true, true,"zuxieshuask:"..n..":"..player:getLostHp(),".", self:objectName()) then			
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(player:getLostHp(),self:objectName())
			end
		end
	end
}
zu_zhonghui:addSkill(zuyuzhi)
zu_zhonghui:addSkill(zuxieshu)
zu_zhong_baozu = sgs.CreateTriggerSkill{
	name = "zu_zhong_baozu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@zu_zhong_baozu",
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Dying then
			local dying = data:toDying()
			if isSameClan(player,dying.who)
			and player:getMark("@zu_zhong_baozu")>0
			and player:askForSkillInvoke(self, data) then
				local n = math.random(1,2)
				if player:getGeneralName():endsWith("zhonghui")
				or player:getGeneral2Name():endsWith("zhonghui") then n = math.random(1,6)
				elseif player:getGeneralName():endsWith("zhongyu")
				or player:getGeneral2Name():endsWith("zhongyu") then n = n+6
				elseif player:getGeneralName():endsWith("zhongyan")
				or player:getGeneral2Name():endsWith("zhongyan") then n = n+8
				elseif player:getGeneralName():endsWith("zhongyao")
				or player:getGeneral2Name():endsWith("zhongyao") then n = n+10 end
				room:broadcastSkillInvoke(self:objectName(),n,player)
				room:removePlayerMark(player, "@zu_zhong_baozu")
				room:doSuperLightbox(dying.who,"zu_zhong_baozu")
				room:setPlayerChained(dying.who,true)
				room:recover(dying.who, sgs.RecoverStruct("zu_zhong_baozu",player))
			end
		end
		return false
	end,
}
zu_zhonghui:addSkill(zu_zhong_baozu)
sgs.LoadTranslationTable{
    ["olClan"] = "门阀士族", 

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
	["cv:zu_zhonghui"] = "官方",
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

table.insert(ol_clans.yingchuan_zhong,"zhongyu")
zu_zhongyu = sgs.General(extension, "zu_zhongyu", "wei", 3)
zujiejian = sgs.CreateTriggerSkill{
	name = "zujiejian",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getTypeId()>0 then
			room:addPlayerMark(player, "&zujiejian-Clear")
			local id = use.card:getSubcards():first()
			local card = sgs.Sanguosha:getCard(id)
		    local n = card:nameLength()
			if use.card:getTypeId()<3 and n == player:getMark("&zujiejian-Clear") then
			    local target = room:askForPlayerChosen(player, use.to, self:objectName(), "zujiejian-invoke", true, true)
				if target then
				    room:broadcastSkillInvoke(self:objectName())
					target:drawCards(n,self:objectName())
				end
			end
		end
	end,
}
zuhuanghan = sgs.CreateTriggerSkill{
	name = "zuhuanghan",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		if damage.card and damage.card:getTypeId()>0 then
            if room:askForSkillInvoke(player, self:objectName(), data) then			
				room:broadcastSkillInvoke(self:objectName())
				local n = damage.card:nameLength()
				player:drawCards(n,self:objectName())
				room:askForDiscard(player, self:objectName(), player:getLostHp(), player:getLostHp(), false, true)
				room:addPlayerMark(player, "huanghan-Clear")
				if player:getMark("huanghan-Clear") > 1 and player:getMark("@zu_zhong_baozu")<1
				and player:hasSkill("zu_zhong_baozu",true) then
			        room:addPlayerMark(player, "@zu_zhong_baozu")
			    end
		    end
		end
	end,
}
zu_zhongyu:addSkill(zujiejian)
zu_zhongyu:addSkill(zuhuanghan)
zu_zhongyu:addSkill("zu_zhong_baozu")
sgs.LoadTranslationTable{
	["zu_zhongyu"] = "族钟毓",
	["#zu_zhongyu"] = "础润殷忧",
	["designer:zu_zhongyu"] = "玄蝶既白",
	["cv:zu_zhongyu"] = "官方",
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

table.insert(ol_clans.yingchuan_zhong,"zhongyan")
zu_zhongyan = sgs.General(extension, "zu_zhongyan", "jin", 3, false)
zuguanguCard = sgs.CreateSkillCard{
	name = "zuguanguCard",
	--target_fixed = true,
	filter = function(self, targets, to_select, from)
		return from:getChangeSkillState("zuguangu")==2
		and #targets<1
	end,
	feasible = function(self,targets,from)
		return from:getChangeSkillState("zuguangu")==1
		or #targets>0
	end,
	on_use = function(self, room, source, targets)
		local card_ids = sgs.IntList()
		if source:getChangeSkillState("zuguangu") == 1 then
			local choice = room:askForChoice(source,"zuguangunum","1+2+3+4")
			room:setChangeSkillState(source, "zuguangu", 2)
		    card_ids = room:getNCards(tonumber(choice))
		   	room:returnToTopDrawPile(card_ids)
		else
			room:setChangeSkillState(source, "zuguangu", 1)
			for i=1,4 do
				if card_ids:length()>=targets[1]:getHandcardNum() then break end
				local id = room:askForCardChosen(source,targets[1],"h","zuguangu",false,sgs.Card_MethodNone,card_ids,i>1)
			    if id<0 then break end
				card_ids:append(id)
			end
		end
		if card_ids:isEmpty() then return end
		room:setPlayerMark(source,"&zuguangu",card_ids:length())
		room:notifyMoveToPile(source,card_ids,"zuguangu")
		room:askForUseCard(source,"@@zuguangu","@zuguangu:")
		room:notifyMoveToPile(source,card_ids,"zuguangu",sgs.Player_PlaceUnknown,false)
	end,
}
zuguanguvs = sgs.CreateViewAsSkill{
	name = "zuguangu",
	expand_pile = "#zuguangu",
	n = 1,
	view_filter = function(self,selected,to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		return pattern=="@@zuguangu" and sgs.Self:getPileName(to_select:getEffectiveId())=="#zuguangu"
		and to_select:isAvailable(sgs.Self)
	end,
	view_as = function(self,cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@zuguangu" then
			if #cards<1 then return end
			return cards[1]
		end
		return zuguanguCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#zuguanguCard")<=player:getMark("zuguanguUse-Clear")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern:startsWith("@@zuguangu")
	end,
}
zuguangu = sgs.CreatePhaseChangeSkill{
	name = "zuguangu",
	view_as_skill = zuguanguvs,
	change_skill = true,
	on_phasechange = function(self, player)
	end,
}
zuxiaoyong = sgs.CreateTriggerSkill{
	name = "zuxiaoyong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getTypeId()>0 and player:hasFlag("CurrentPlayer") then
			local m = use.card:nameLength()
			player:addMark(m.."zuxiaoyong-Clear")
			if player:getMark(m.."zuxiaoyong-Clear") < 2 and m == player:getMark("&zuguangu") then
				room:sendCompulsoryTriggerLog(player, self)
				room:addPlayerMark(player, "zuguanguUse-Clear")
			end
		end
	end,
}
zu_zhongyan:addSkill(zuguangu)
zu_zhongyan:addSkill(zuxiaoyong)
zu_zhongyan:addSkill("zu_zhong_baozu")
sgs.LoadTranslationTable{
	["zu_zhongyan"] = "族钟琰",
	["#zu_zhongyan"] = "紫闼飞莺",
	["designer:zu_zhongyan"] = "玄蝶既白",
	["cv:zu_zhongyan"] = "官方",
	["illustrator:zu_zhongyan"] = "凡果",
	["information:zu_zhongyan"] = "宗族：[颍川·钟氏]",
	["zuguangu"] = "观骨",
	["zuguangunum"] = "观看牌数",
	["@zuguangu"] = "你可以使用观看的一张牌",
	["zuguangu-invoke"] = "你可以发动“观骨”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	[":zuguangu"] = "转换技，出牌阶段限一次，①你可以观看牌堆顶至多四张牌；②你可以观看一名角色至多四张手牌。然后你可以使用其中一张牌。",
	[":zuguangu1"] = "转换技，出牌阶段限一次，①你可以观看牌堆顶至多四张牌；<font color=\"#01A5AF\"><s>②你可以观看一名角色至多四张手牌</s></font>。然后你可以使用其中一张牌。",
	[":zuguangu2"] = "转换技，出牌阶段限一次，<font color=\"#01A5AF\"><s>①你可以观看牌堆顶至多四张牌；</s></font>②你可以观看一名角色至多四张手牌。然后你可以使用其中一张牌。",
	["#zuguangu"] = "观看牌",
	["$zuguangu1"] = "此才拔萃，然观其形骨，恐早夭。",
	["$zuguangu2"] = "绯衣者，汝所拔乎？",
	["zuxiaoyong"] = "啸咏",
    [":zuxiaoyong"] = "锁定技，当你回合内首次使用牌名字数为X的牌时（X为上次“观骨”观看牌数），你本回合发动“观骨”的次数限制+1。",
	["$zuxiaoyong1"] = "凉风萧条，露沾我衣。",
	["$zuxiaoyong2"] = "忧来多方，慨然永怀。",
	["~zu_zhongyan"] = "此间天下人，皆分一斗之才......",
}

table.insert(ol_clans.yingchuan_zhong,"zhongyao")
zu_zhongyao = sgs.General(extension, "zu_zhongyao", "wei", 3)
zuchengqiCard = sgs.CreateSkillCard{
	name = "zuchengqiCard",
	will_throw = false,
	target_fixed = true,
	on_validate_in_response = function(self,from)
		if self:getUserString():contains("+") then
			local choice = {}
			local n = 0
			for _,id in sgs.qlist(self:getSubcards())do
				n = n+sgs.Sanguosha:getCard(id):nameLength()
			end
			for _,pn in ipairs(self:getUserString():split("+")) do
				local dc = dummyCard(pn)
				if dc:nameLength()>n then continue end
				dc:setSkillName(self:getSkillName())
				dc:addSubcards(self:getSubcards())
				if from:getMark(pn.."zuchengqiUse-Clear")<1 and not from:isLocked(dc)
				then table.insert(choice,pn) end
			end
			if #choice<1 then return nil end
			local room = from:getRoom()
			choice = room:askForChoice(from,self:getSkillName(),table.concat(choice,"+"))
			local dc = dummyCard(choice)
			dc:setSkillName(self:getSkillName())
			dc:addSubcards(self:getSubcards())
			return dc
		end
		return self
	end,
	on_validate = function(self,use)
		if self:getUserString():contains("+") then
			local choice = {}
			local n = 0
			for _,id in sgs.qlist(self:getSubcards())do
				n = n+sgs.Sanguosha:getCard(id):nameLength()
			end
			for _,pn in ipairs(self:getUserString():split("+")) do
				local dc = dummyCard(pn)
				if dc:nameLength()>n then continue end
				dc:setSkillName(self:getSkillName())
				dc:addSubcards(self:getSubcards())
				if use.from:getMark(pn.."zuchengqiUse-Clear")<1 and not use.from:isLocked(dc)
				then table.insert(choice,pn) end
			end
			if #choice<1 then return nil end
			local room = use.from:getRoom()
			choice = room:askForChoice(use.from,self:getSkillName(),table.concat(choice,"+"))
			local dc = dummyCard(choice)
			dc:setSkillName(self:getSkillName())
			dc:addSubcards(self:getSubcards())
			return dc
		end
		return self
	end,
    about_to_use = function(self,room,use)
		local choice = {}
		local n = 0
		for _,id in sgs.qlist(self:getSubcards())do
			n = n+sgs.Sanguosha:getCard(id):nameLength()
		end
		for _,pn in ipairs(patterns()) do
			local dc = dummyCard(pn)
			if dc:nameLength()>n then continue end
			if dc and (dc:isNDTrick() or dc:getTypeId()==1)
			and use.from:getMark(pn.."zuchengqiUse-Clear")<1 then
				dc:setSkillName(self:getSkillName())
				dc:addSubcards(self:getSubcards())
				if dc:isAvailable(use.from)
				then table.insert(choice,pn) end
			end
		end
		if #choice<1 then return end
		choice = room:askForChoice(use.from,self:getSkillName(),table.concat(choice,"+"))
		local dc = dummyCard(choice)
		dc:setSkillName(self:getSkillName())
		dc:addSubcards(self:getSubcards())
		room:setPlayerProperty(use.from,"zuchengqiUse",ToData(dc:toString()))
		room:askForUseCard(use.from,"@@zuchengqi","zuchengqi0:"..choice)
	end,
}
zuchengqiVS = sgs.CreateViewAsSkill{
	name = "zuchengqi",
	n = 998,
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		return pattern~="@@zuchengqi" and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@zuchengqi" then
			local dc = sgs.Self:property("zuchengqiUse"):toString()
			dc = sgs.Card_Parse(dc)
			local card = sgs.Sanguosha:cloneCard(dc:objectName())
			card:setSkillName(self:objectName())
			card:addSubcards(dc:getSubcards())
			return card
		end
		if #cards<2 then return end
		if pattern=="" or pattern:contains("+") then
			local card = zuchengqiCard:clone()
			card:setUserString(pattern)
			for _, c in ipairs(cards)do
				card:addSubcard(c)
			end
			return card
		else
			local n = 0
			for _,c in ipairs(cards)do
				n = n+c:nameLength()
			end
			local card = sgs.Sanguosha:cloneCard(pattern)
			if n<card:nameLength() then card:deleteLater() return end
			card:setSkillName(self:objectName())
			for _,c in ipairs(cards)do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_response = function(self, player, pattern)
		for _,pn in ipairs(pattern:split("+"))do
			if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or player:getHandcardNum()<2 then break end
			local dc = dummyCard(pn)
			if dc and player:getMark(pn.."zuchengqiUse-Clear")<1
			and (dc:isNDTrick() or dc:getTypeId()==1)
			then return true end
		end
		return pattern:startsWith("@@zuchengqi")
	end,
	enabled_at_play = function(self, player)
		return player:getHandcardNum()>1
	end, 
}
zuchengqi = sgs.CreateTriggerSkill{
	name = "zuchengqi",
	view_as_skill = zuchengqiVS,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getTypeId()>0 then
			room:addPlayerMark(player, use.card:objectName().."zuchengqiUse-Clear")
			if table.contains(use.card:getSkillNames(),self:objectName()) then
				local m = use.card:nameLength()
				local n = 0
				for _,id in sgs.qlist(use.card:getSubcards())do
					n = n+sgs.Sanguosha:getCard(id):nameLength()
				end
				if n==m then
					local to = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"zuchengqi1:")
					if to then
						room:doAnimate(1,player:objectName(),to:objectName())
						to:drawCards(1,self:objectName())
					end
				end
			end
		end
	end,
}
zu_zhongyao:addSkill(zuchengqi)
zujieliCard = sgs.CreateSkillCard{
	name = "zujieliCard",
	will_throw = false,
	target_fixed = true,
    about_to_use = function(self,room,use)
	end,
}
zujieliVS = sgs.CreateViewAsSkill{
	name = "zujieli",
	n = 998,
	expand_pile = "#zujieliN,#zujieli",
	view_filter = function(self, selected, to_select)
		local ep = sgs.Self:getPileName(to_select:getEffectiveId())
		return ep=="#zujieliN" or ep=="#zujieli"
	end,
	view_as = function(self, cards)
		if #cards<2 then return end
		local x = 0
		for _, c in ipairs(cards)do
			if sgs.Self:getPileName(c:getEffectiveId())=="#zujieli"
			then x = x+1 else x = x-1 end
		end
		if x~=0 then return end
		local card = zujieliCard:clone()
		for _, c in ipairs(cards)do
			card:addSubcard(c)
		end
		return card
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern:startsWith("@@zujieli")
	end,
	enabled_at_play = function(self, player)
		return false
	end, 
}
zujieli = sgs.CreateTriggerSkill{
	name = "zujieli",
	view_as_skill = zujieliVS,
	events = {sgs.EventPhaseStart,sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				local m = use.card:nameLength()
				if m>player:getMark("&zujieli-Clear") then
					room:setPlayerMark(player,"&zujieli-Clear",m)
				end
			end
		elseif player:getPhase() == sgs.Player_Finish then
			local aps = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getHandcardNum() > 0 then
					aps:append(p)
				end
			end
			local target = room:askForPlayerChosen(player, aps, self:objectName(), "zujieli0:",  true,true)
			if target then
			    room:broadcastSkillInvoke(self:objectName())
				local n = 0
				for _, h in sgs.qlist(target:getHandcards()) do
					local x = h:nameLength()
					if x > n then n = x end
				end
				local ids = sgs.IntList()
				for _, h in sgs.qlist(target:getHandcards()) do
					local x = h:nameLength()
					if x >= n then ids:append(h:getId()) end
				end
				n = player:getMark("&zujieli-Clear")
				local cns = room:getNCards(n,false)
				room:notifyMoveToPile(player,cns,"zujieliN",sgs.Player_DrawPile,true)
				room:notifyMoveToPile(player,ids,"zujieli",sgs.Player_PlaceHand,true)
				local dc = room:askForUseCard(player,"@@zujieli","zujieli1:",-1,sgs.Card_MethodNone)
				room:notifyMoveToPile(player,cns,"zujieliN",sgs.Player_DrawPile,false)
				room:notifyMoveToPile(player,ids,"zujieli",sgs.Player_PlaceHand,false)
				room:returnToTopDrawPile(cns)
				if dc then
					local move1 = sgs.CardsMoveStruct()
					move1.to = target
					move1.to_place = sgs.Player_PlaceHand
					move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTBACK,player:objectName(),target:objectName(),self:objectName(),"")
					local move2 = sgs.CardsMoveStruct()
					move2.from = target
					move2.to = nil
					move2.to_place = sgs.Player_DrawPile
					move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE,player:objectName(),target:objectName(),self:objectName(),"")
					for _,id in sgs.qlist(dc:getSubcards()) do
						if cns:contains(id) then
							move1.card_ids:append(id)
						else
							move2.card_ids:append(id)
						end
					end
					local moves = sgs.CardsMoveList()
					moves:append(move1)
					moves:append(move2)
					room:moveCardsAtomic(moves,false)
				end
			end
		end
	end,
}
zu_zhongyao:addSkill(zujieli)
zu_zhongyao:addSkill("zu_zhong_baozu")
sgs.LoadTranslationTable{
	["zu_zhongyao"] = "族钟繇",
	["#zu_zhongyao"] = "开达理干",
	--["designer:zu_zhongyao"] = "玄蝶既白",
	["cv:zu_zhongyao"] = "官方",
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
ol_clans.chenliu_wu = {"wuban","wulan"}
zu_wuban = sgs.General(extension, "zu_wuban", "shu", 4, true)
zuzhandingVS = sgs.CreateViewAsSkill{
	name = "zuzhanding",
	n = 999,
	response_or_use = false,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:addSubcard(to_select:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash")
			for _, c in ipairs(cards) do
				slash:addSubcard(c)
			end
			slash:setSkillName(self:objectName())
			slash:setFlags(self:objectName())
			return slash
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end,
}
zuzhanding = sgs.CreateTriggerSkill{
	name = "zuzhanding",
	events = {sgs.CardUsed, sgs.CardFinished},
	view_as_skill = zuzhandingVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),self:objectName())
			or use.card:hasFlag(self:objectName()) then
				room:addMaxCards(player, -1, false)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),self:objectName())
			or use.card:hasFlag(self:objectName()) then
				room:sendCompulsoryTriggerLog(player, self)
				if use.card:hasFlag("DamageDone") then
					local n = player:getMaxCards()-player:getHandcardNum()
					if n>0 then room:drawCards(player, n, self:objectName())
					elseif n<0 then room:askForDiscard(player, self:objectName(), -n, -n) end
				else
					use.m_addHistory = false
					data:setValue(use)
				end
			end
		end
	end,
}
zu_wuban:addSkill(zuzhanding)
zu_wu_muyin = sgs.CreateTriggerSkill{
	name = "zu_wu_muyin",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
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
			local target = room:askForPlayerChosen(player, zuwu, self:objectName(), "zu_wu_muyin0:",  true,true)
			if target then
				local n = math.random(1,2)
				if player:getGeneralName():endsWith("wuxian")
				or player:getGeneral2Name():endsWith("wuxian") then n = n+2
				elseif player:getGeneralName():endsWith("wukuang")
				or player:getGeneral2Name():endsWith("wukuang") then n =n+4
				elseif player:getGeneralName():endsWith("wuqiao")
				or player:getGeneral2Name():endsWith("wuqiao") then n = n+6 end
				room:broadcastSkillInvoke(self:objectName(),n,player)
				room:addMaxCards(target, 1, false)
			end
		end
	end,
}
zu_wuban:addSkill(zu_wu_muyin)

--族吴苋
table.insert(ol_clans.chenliu_wu,"wuxian")
zu_wuxian = sgs.General(extension, "zu_wuxian", "shu", 3, false)
zuyirongCard = sgs.CreateSkillCard{
    name = "zuyirongCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
	    local hc, mxc = source:getHandcardNum(), source:getMaxCards()
		if hc < mxc then
			room:drawCards(source, mxc-hc, "zuyirong")
			room:addMaxCards(source, -1, false)
		elseif hc > mxc then
			room:askForDiscard(source, "zuyirong", hc-mxc, hc-mxc)
			room:addMaxCards(source, 1, false)
		end
	end,
}
zuyirong = sgs.CreateZeroCardViewAsSkill{
    name = "zuyirong",
    view_as = function()
		return zuyirongCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#zuyirongCard") < 2 and player:getHandcardNum() ~= player:getMaxCards()
	end,
}
zu_wuxian:addSkill(zuyirong)
zuguixiang = sgs.CreateTriggerSkill{
	name = "zuguixiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_RoundStart
		or change.to == sgs.Player_NotActive then return false end
		room:addPlayerMark(player, "zuguixiang-Clear") --记录进行到了第几个阶段
		if player:getMark("zuguixiang-Clear") == player:getMaxCards() then
			room:sendCompulsoryTriggerLog(player, self)
			change.to = sgs.Player_Play
			data:setValue(change)
		end
	end,
}
zu_wuxian:addSkill(zuguixiang)
zu_wuxian:addSkill("zu_wu_muyin")

--族吴匡
table.insert(ol_clans.chenliu_wu,"wukuang")
zu_wukuang = sgs.General(extension, "zu_wukuang", "qun", 4, true)
zulianzhu = sgs.CreateTriggerSkill{
	name = "zulianzhu",
	change_skill = true,
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.EventAcquireSkill, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Play then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill(self,true) and not player:hasSkill("zulianzhuvs",true) then
					room:attachSkillToPlayer(player, "zulianzhuvs")
					break
				end
			end
		elseif event == sgs.EventAcquireSkill and player:hasSkill(self,true) then
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getPhase()==sgs.Player_Play and not p:hasSkill("zulianzhuvs",true) then
					room:attachSkillToPlayer(p, "zulianzhuvs")
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase()>=sgs.Player_Play and player:hasSkill("zulianzhuvs",true) then
				room:detachSkillFromPlayer(player, "zulianzhuvs",true)
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
}
zu_wukuang:addSkill(zulianzhu)
--联诛卡--
zulianzhuCard = sgs.CreateSkillCard{
	name = "zulianzhuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if self:subcardsLength() > 0 then --阳
				return to_select:hasSkill("zulianzhu") and to_select:getChangeSkillState("zulianzhu") == 1
				and to_select:getCardCount()>0
			else --阴
				return to_select:hasSkill("zulianzhu") and to_select:getChangeSkillState("zulianzhu") == 2
			end
		end
	end,
	on_use = function(self, room, source, targets)
		local zwk = targets[1]
	    room:notifySkillInvoked(zwk,"zulianzhu")
		if self:subcardsLength() > 0 then
			local card2 = zwk~=source and room:askForCard(zwk, "..!", "@zulianzhuRecast", ToData(source), sgs.Card_MethodRecast)
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
				room:addMaxCards(zwk, 1,false)
			end
			room:setChangeSkillState(zwk, "zulianzhu", 2)
		else
		    local SlashTargets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(source)) do
				if p == zwk then continue end
				if source:canSlash(p,nil,false) and zwk:canSlash(p,nil,false) then
					SlashTargets:append(p)
				end
			end
			if SlashTargets:isEmpty() then return false end
			local target = room:askForPlayerChosen(zwk, SlashTargets, "zulianzhu", "@zulianzhu-slash:"..source:objectName())
			room:doAnimate(1,zwk:objectName(),target:objectName())
			local use_slash1 = room:askForUseSlashTo(source, target, "@zulianzhu-useslash:"..target:objectName(),false)
			local use_slash2 = room:askForUseSlashTo(zwk, target, "@zulianzhu-useslash:"..target:objectName(),false)
			if use_slash1 and use_slash2 and use_slash1:getColor()~=use_slash2:getColor()
			then room:addMaxCards(zwk, -1,false) end
			room:setChangeSkillState(zwk, "zulianzhu", 1)
		end
	end,
}
zulianzhuvs = sgs.CreateViewAsSkill{
	name = "zulianzhuvs&",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not sgs.Self:isCardLimited(to_select,sgs.Card_MethodRecast)
	end,
	view_as = function(self, cards)
		local lzvs_card = zulianzhuCard:clone()
		for _, c in ipairs(cards) do
			lzvs_card:addSubcard(c)
		end
		return lzvs_card
	end,
	enabled_at_play = function(self, player)
		local tos = player:getAliveSiblings()
		tos:append(player)
		for _, p in sgs.qlist(tos) do
			if p:hasSkill("zulianzhu") then
				return not player:hasUsed("#zulianzhuCard")
			end
		end
	end,
}
extension:addSkills(zulianzhuvs)
zu_wukuang:addSkill("zu_wu_muyin")

--族吴乔
table.insert(ol_clans.chenliu_wu,"wuqiao")
zu_wuqiao = sgs.General(extension, "zu_wuqiao", "qun", 4, true)
local function fcjyzCandiscard(player) --借用一下界老于禁的黑牌可弃判定
	for _, c in sgs.qlist(player:getCards("he")) do
		if c:isBlack() and player:canDiscard(player, c:getEffectiveId())
		then return true end
	end
end
zuqiajue = sgs.CreateTriggerSkill{
	name = "zuqiajue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Draw then return false end
		if event == sgs.EventPhaseStart then
			if fcjyzCandiscard(player) and room:askForCard(player,".|black","@zuqiajue-invoke",data,self:objectName()) then
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerFlag(player, self:objectName())
			end
		elseif event == sgs.EventPhaseEnd then
			if player:hasFlag(self:objectName()) then
				room:setPlayerFlag(player, "-"..self:objectName())
				room:showAllCards(player)
				local num = 0
				for _, c in sgs.qlist(player:getHandcards()) do
					num = num + c:getNumber()
				end
				if num > 30 then room:addMaxCards(player, -2, false)
				else
					player:setPhase(sgs.Player_Draw)
					room:broadcastProperty(player, "phase")
					if not room:getThread():trigger(sgs.EventPhaseStart,room,player) then
						room:getThread():trigger(sgs.EventPhaseProceeding,room,player)
					end
					room:getThread():trigger(sgs.EventPhaseEnd,room,player)
					player:setPhase(sgs.Player_Draw)
					room:broadcastProperty(player, "phase")
				end
			end
		end
	end,
}
zu_wuqiao:addSkill(zuqiajue)
zu_wuqiao:addSkill("zu_wu_muyin")

sgs.LoadTranslationTable{
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
	["cv:zu_wuban"] = "官方",
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
	["cv:zu_wuxian"] = "官方",
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
	["cv:zu_wukuang"] = "官方",
	["illustrator:zu_wukuang"] = "匠人绘",
	["information:zu_wukuang"] = "宗族：[陈留·吴氏]",
	--联诛
	["zulianzhu"] = "联诛",
	[":zulianzhu"] = "转换技，每名角色的出牌阶段限一次，①其可以与你各重铸一张牌，若这两张牌颜色相同，你的手牌上限+1；" ..
	"②其可以令你选择（除其之外的）另一名其他角色，然后其与你可以依次对该角色使用一张【杀】，若这两张【杀】颜色不同，你的手牌上限-1。",
	[":zulianzhu1"] = "转换技，每名角色的出牌阶段限一次，①其可以与你各重铸一张牌，若这两张牌颜色相同，你的手牌上限+1。" ..
	"<font color=\"#01A5AF\"><s>②其可以令你选择（除其之外的）另一名其他角色，然后其与你可以依次对该角色使用一张【杀】（无距离限制），若这两张【杀】颜色不同，你的手牌上限-1。</s></font>",
	[":zulianzhu2"] = "转换技，每名角色的出牌阶段限一次，<font color=\"#01A5AF\"><s>①其可以与你各重铸一张牌，若这两张牌颜色相同，你的手牌上限+1。</s></font>" ..
	"②其可以令你选择（除其之外的）另一名其他角色，然后其与你可以依次对该角色使用一张【杀】，若这两张【杀】颜色不同，你的手牌上限-1。",
	["zulianzhuvs"] = "联诛卡",
	[":zulianzhuvs"] = "转换技，出牌阶段限一次，①你可以与拥有“联诛”的角色各重铸一张牌，若这两张牌颜色相同，其手牌上限+1；" ..
	"②你可以令拥有“联诛”的角色选择（不为你二人的）另一名其他角色，然后你与其可以依次对该角色使用一张【杀】，若这两张【杀】颜色不同，其手牌上限-1。",
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
	["cv:zu_wuqiao"] = "官方",
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
ol_clans.yingchuan_xun = {"xunshu","xunyu"}
nyzu_xunshu = sgs.General(extension, "nyzu_xunshu", "qun", 3, true, false, false)

ny_balongCard = sgs.CreateSkillCard{
    name = "ny_balong",
    will_throw = false,
    target_fixed = true,
    about_to_use = function(self,room,use)
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
    end
}
ny_balongVS = sgs.CreateZeroCardViewAsSkill{
    name = "ny_balong",
    frequency = sgs.Skill_Compulsory,
    view_as = function(self)
        return ny_balongCard:clone()
    end,
    enabled_at_play = function(self, player)
        return true
    end
}
ny_balong = sgs.CreateTriggerSkill{
    name = "ny_balong",
    events = {sgs.HpChanged},
    frequency = sgs.Skill_Compulsory,
    view_as_skill = ny_balongVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:isDead() then return false end
        if player:getMark("ny_balong-Clear") > 0 then return false end
        room:addPlayerMark(player, "ny_balong-Clear", 1)
        if player:isKongcheng() then return false end
        local trick = 0
        local equip = 0
        local basic = 0
        local show = sgs.IntList()
        for _,card in sgs.qlist(player:getHandcards()) do
            show:append(card:getId())
            if card:isKindOf("TrickCard") then trick = trick + 1
            elseif card:isKindOf("BasicCard") then basic = basic + 1
            elseif card:isKindOf("EquipCard") then equip = equip + 1 end
        end
        if trick > equip and trick > basic then
            room:sendCompulsoryTriggerLog(player, self)
            room:showCard(player, show)
            local n = room:getAlivePlayers():length()
            if player:getMark("ny_balong_old") > 0 then n = 8 end
            if player:getHandcardNum() < n then
                player:drawCards(n - player:getHandcardNum(), self:objectName())
            end
        end
    end,
}

ny_shenjunVS = sgs.CreateViewAsSkill{
    name = "ny_shenjun",
    n = 999,
    response_pattern = "@@ny_shenjun",
    view_filter = function(self, selected, to_select)
        return #selected < sgs.Self:getMark("ny_shenjun")
    end,
    view_as = function(self, cards)
        local pattern = sgs.Self:property("ny_shenjun"):toString()
        if pattern~="" and #cards == sgs.Self:getMark("ny_shenjun") then
            local card = sgs.Sanguosha:cloneCard(pattern)
            card:setSkillName("ny_shenjun")
            card:setFlags("ny_shenjun")
            for _,cc in ipairs(cards) do
                card:addSubcard(cc)
            end
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return false 
    end,

}

ny_shenjunCard = sgs.CreateSkillCard{
	name = "ny_shenjun",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select,from)
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
	feasible = function(self, targets,from)
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

ny_shenjun = sgs.CreateTriggerSkill{
    name = "ny_shenjun",
    events = {sgs.CardUsed,sgs.CardResponded,sgs.EventPhaseEnd},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = ny_shenjunVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
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
            if card and (card:isKindOf("Slash") or card:isNDTrick()) then else return false end
            if table.contains(card:getSkillNames(),self:objectName()) then return false end
            for _,pl in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if pl:isAlive() then
                    local show = sgs.IntList()
                    for _,cc in sgs.qlist(pl:getHandcards()) do
                        if cc:sameNameWith(card) then
                            show:append(cc:getId())
                        end
                    end
                    if not show:isEmpty() then
                        room:sendCompulsoryTriggerLog(pl, self)
                        room:setPlayerFlag(pl, "ny_shenjun")
                        room:showCard(pl, show)
                        for _,id in sgs.qlist(show) do
                            room:setCardTip(id, "ny_shenjun")
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseEnd then
            for _,pl in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if pl:isAlive() and pl:hasFlag("ny_shenjun") then
                    room:setPlayerFlag(pl, "-ny_shenjun")
                    local count = 0
                    local choices = {}
                    for _,cc in sgs.qlist(pl:getHandcards()) do
                        if cc:hasTip("ny_shenjun") then
                            count = count + 1
                            if (not table.contains(choices, cc:objectName())) then
                                local dc = sgs.Sanguosha:cloneCard(cc:objectName())
								dc:setSkillName("ny_shenjun")
								dc:deleteLater()
								if dc:isAvailable(pl) then
									table.insert(choices, cc:objectName())
								end
                            end
                        end
                    end
                    if count > 0 and #choices>0 then
                        table.insert(choices, "cancel")
                        room:setPlayerMark(pl, "ny_shenjun", count)
                        local choice = room:askForChoice(pl, self:objectName(), table.concat(choices, "+"))
                        if choice~="cancel" then
                            room:setPlayerProperty(pl, "ny_shenjun", sgs.QVariant(choice))
                            local prompt = string.format("@ny_shenjun:%s::%s:", count, choice)
                            room:askForUseCard(pl, "@@ny_shenjun", prompt)
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

nyzu_xunshu:addSkill(ny_shenjun)
nyzu_xunshu:addSkill(ny_shenjunVS)
nyzu_xunshu:addSkill(ny_balong)
nyzu_xunshu:addSkill(ny_balongVS)
kezudaojie = sgs.CreateTriggerSkill{
    name = "kezudaojie",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getMark("kezudaojie-Clear") > 0 then return false end
        local use = data:toCardUse()
        if use.card:isKindOf("TrickCard")
        and (not use.card:isDamageCard()) then
            room:addPlayerMark(player, "kezudaojie-Clear")
			if room:getCardOwner(use.card:getEffectiveId()) then return false end
            local n = math.random(1,2)
			if player:getGeneralName():endsWith("xunchen")
			or player:getGeneral2Name():endsWith("xunchen") then n = n+2
			elseif player:getGeneralName():endsWith("xunyou")
			or player:getGeneral2Name():endsWith("xunyou") then n = n+4
			elseif player:getGeneralName():endsWith("xuncan")
			or player:getGeneral2Name():endsWith("xuncan") then n = n+6
			elseif player:getGeneralName():endsWith("xuncai")
			or player:getGeneral2Name():endsWith("xuncai") then n = n+8 end
            room:sendCompulsoryTriggerLog(player, self, n)
			local choice = {"hp"}
			for _,skill in sgs.qlist(player:getVisibleSkillList()) do
				if (not skill:isAttachedLordSkill()) and (skill:getFrequency(player) == sgs.Skill_Compulsory) then
					table.insert(choice, "skill="..skill:objectName())
				end
			end
			choice = room:askForChoice(player, self:objectName(), table.concat(choice, "+"), data)
            if choice == "hp" then
                room:loseHp(player, 1, true, player, self:objectName())
            else
                local skill = choice:split("=")[2]
                room:detachSkillFromPlayer(player, skill)
            end
            if player:isAlive() then
                local targets = sgs.SPlayerList()
                for _,pl in sgs.qlist(room:getAlivePlayers()) do
                    if isSameClan(player, pl) then
                        targets:append(pl)
                    end
                end
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "@kezudaojie:"..use.card:objectName())
                if target then
					room:doAnimate(1,player:objectName(),target:objectName())
                    room:obtainCard(target, use.card, true)
                end
            end
        end
    end,
}
nyzu_xunshu:addSkill(kezudaojie)

table.insert(ol_clans.yingchuan_xun,"xunchen")
nyzu_xunchen = sgs.General(extension, "nyzu_xunchen", "qun", 3, true, false, false)

ny_sankuang = sgs.CreateTriggerSkill{
    name = "ny_sankuang",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if player:getMark(use.card:getType().."ny_sankuang_lun")>0
		or use.card:getTypeId()<1 then return false end
        room:addPlayerMark(player, use.card:getType().."ny_sankuang_lun")
        room:sendCompulsoryTriggerLog(player, self)
        player:setTag("ny_sankuang_use", data)
        local prompt = string.format("@ny_sankuang:%s:", use.card:objectName())
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), prompt, false, true)
        if player:getMark("ny_beishi_used")<1 then
            room:setPlayerMark(player, "ny_beishi_used", 1)
            local viewers = sgs.SPlayerList()
            viewers:append(player)
            room:setPlayerMark(target, "&ny_beishi", 1, viewers)
            room:setPlayerMark(target, "ny_beishi_from"..player:objectName(), 1)
        end
        local min = 0
        if target:getCards("ej"):length()>0 then min = min + 1 end
        if target:isWounded() then min = min + 1 end
        if target:getHandcardNum() > target:getHp() then min = min + 1 end
        if target:getCardCount()>0 then
            local give_pro = string.format("ny_sankuang_give:%s::%s:",player:objectName(),min)
            local give = room:askForExchange(target, self:objectName(), 999, min, true, give_pro, false)
            if give then room:giveCard(target, player, give, self:objectName(), false) end
        end
        if target:isAlive() and (room:getCardOwner(use.card:getEffectiveId())==nil or player:hasCard(use.card)) then
            room:obtainCard(target, use.card, true)
        end
    end,
}

ny_beishi = sgs.CreateTriggerSkill{
    name = "ny_beishi",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from_places:contains(sgs.Player_PlaceHand)
			and move.from:getMark("ny_beishi_from"..player:objectName())>0
			and move.is_last_handcard and player:isWounded() then
                room:sendCompulsoryTriggerLog(player, self)
                room:recover(player, sgs.RecoverStruct(self:objectName(), player))
			end
        end
    end,
}


nyzu_xunchen:addSkill(ny_sankuang)
nyzu_xunchen:addSkill(ny_beishi)
nyzu_xunchen:addSkill("kezudaojie")

table.insert(ol_clans.yingchuan_xun,"xunyou")
nyzu_xunyou = sgs.General(extension, "nyzu_xunyou", "wei", 3, true, false, false)

ny_baichu = sgs.CreateTriggerSkill{
    name = "ny_baichu",
    events = {sgs.CardFinished,sgs.RoundEnd},
    frequency = sgs.Skill_NotFrequent,
    waked_skills = "qice",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished and player:hasSkill(self) then
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            local suits = {"spade", "diamond", "club", "heart"}
            local suit = use.card:getSuitString()
            local ckind = use.card:getType()

            local groups = player:getTag("ny_baichu_groups"):toString():split("+")
            local records = player:getTag("ny_baichu_records"):toString():split("+")
            local invoke = true

            if table.contains(suits, suit) then
                local group = string.format("%s_%s", ckind, suit)
                if table.contains(groups, group) then
                    if not player:hasSkill("qice",true) then
                        room:sendCompulsoryTriggerLog(player, self)
                        invoke = false
                        room:addPlayerMark(player, "ny_zuqice_lun")
                        room:acquireSkill(player, "qice")
                    end
                else
                    room:sendCompulsoryTriggerLog(player, self)
                    invoke = false

                    table.insert(groups, group)
                    player:setTag("ny_baichu_groups", sgs.QVariant(table.concat(groups, "+")))

                    local all = {}
                    for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
                        local card = sgs.Sanguosha:getEngineCard(id)
                        if card:isNDTrick() then
                            if (not table.contains(all, card:objectName())) and (not table.contains(records, card:objectName())) then
                                table.insert(all, card:objectName())
                            end
                        end
                    end
                    if #all > 0 then
                        local choice = room:askForChoice(player, self:objectName(), table.concat(all,"+"), data, table.concat(records,"+"), "ny_baichu_record")

                        table.insert(records, choice)
                        player:setTag("ny_baichu_records", sgs.QVariant(table.concat(records, "+")))
						local sts = player:getTag("ny_baichu_sts"):toString():split("+")
						table.insert(sts, suit)
						table.insert(sts, ckind)
						table.insert(sts, choice)
						table.insert(sts, "|")
                        player:setTag("ny_baichu_sts", sgs.QVariant(table.concat(sts, "+")))
						player:setSkillDescriptionSwap(self:objectName(),"%arg11",table.concat(sts, "+"))
						room:changeTranslation(player, self:objectName())
                    end
                end
            end

            if table.contains(records, use.card:objectName()) then
                if invoke then
                    room:sendCompulsoryTriggerLog(player, self)
                end

                local choice = "draw"
                if player:isWounded() then
                    choice = room:askForChoice(player, self:objectName(), "draw+recover", data)
                end
                if choice == "draw" then
                    player:drawCards(1, self:objectName())
                else
                    room:recover(player, sgs.RecoverStruct(self:objectName(), player))
                end
            end
        elseif event == sgs.RoundEnd then
            if player:getMark("ny_zuqice_lun") > 0 and player:hasSkill("qice",true) then
                room:detachSkillFromPlayer(player, "qice", false, true)
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}

nyzu_xunyou:addSkill(ny_baichu)
nyzu_xunyou:addSkill("kezudaojie")

table.insert(ol_clans.yingchuan_xun,"xuncan")
kezu_xuncan = sgs.General(extension, "kezu_xuncan", "wei", 3, true, false, false)

kezuyunshenCard = sgs.CreateSkillCard{
	name = "kezuyunshenCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return (#targets == 0) and (to_select:objectName() ~= player:objectName()) 
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:recover(target, sgs.RecoverStruct(self:getSkillName(),player))
		local slash = sgs.Sanguosha:cloneCard("ice_slash")
		slash:setSkillName("_kezuyunshen")
		slash:deleteLater()
		if room:askForChoice(player, "kezuyunshen","self+he") == "self" then
			if target:canSlash(player,slash,false) then
				room:useCard(sgs.CardUseStruct(slash,target,player),true)
			end
		else
			if player:canSlash(target,slash,false) then
				room:useCard(sgs.CardUseStruct(slash,player,target),true)
			end
		end
	end
}

kezuyunshen = sgs.CreateZeroCardViewAsSkill{
	name = "kezuyunshen",
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kezuyunshenCard") 
	end,
	view_as = function()
		return kezuyunshenCard:clone()
	end
}
kezu_xuncan:addSkill(kezuyunshen)

kezushangshen = sgs.CreateTriggerSkill{
	name = "kezushangshen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if (damage.nature ~= sgs.DamageStruct_Normal) then
				for _, wc in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do   
					room:addPlayerMark(wc,"bankezushangshen-Clear",1)
				end
				for _, wc in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do   
					if (wc:getMark("bankezushangshen-Clear") <= 1) then
						if wc:askForSkillInvoke(self, data) then 
							room:broadcastSkillInvoke(self:objectName())
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
								damage.to:drawCards(cha, self:objectName())
							end
						end
					end
				end
			end
		end	
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
kezu_xuncan:addSkill(kezushangshen)

kezufenchai = sgs.CreateTriggerSkill{
	name = "kezufenchai",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ChoiceMade,sgs.CardUsed,sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_PlaceJudge
			and move.to:objectName()==player:objectName() then
			--and move.reason.m_reason==sgs.CardMoveReason_S_REASON_JUDGE then
				local to = player:getTag("fenchaiPlayer"):toPlayer()
				if to then
					for _, id in sgs.list(move.card_ids) do
						local c = sgs.Sanguosha:getCard(id)
						local toc = sgs.Sanguosha:cloneCard(c:objectName(),c:getSuit(),c:getNumber())
						if to:isAlive() then toc:setSuit(sgs.Card_Heart)
						else toc:setSuit(sgs.Card_Spade) end
						toc:setSkillName("kezufenchai")
						local wrap = sgs.Sanguosha:getWrappedCard(id)
						wrap:takeOver(toc)
						room:broadcastUpdateCard(room:getAlivePlayers(),id,wrap)
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
			if struct=="" then return end
			local to = player:getTag("fenchaiPlayer"):toPlayer()
			if to then return end
			local promptlist = struct:split(":")
			if promptlist[1]=="skillInvoke" and table.contains(promptlist,"yer")
			or promptlist[1]=="playerChosen"
			or promptlist[1]=="cardChosen"
			or promptlist[1]=="Yiji" then
				for _, pn in sgs.list(promptlist) do
					if pn:startsWith("sgs") then
						for _, pt in sgs.list(pn:split("+")) do
							local to = room:findPlayerByObjectName(pt)
							if to and to:getGender()~=player:getGender() then
								player:setTag("fenchaiPlayer",ToData(to))
								room:setPlayerMark(to,"&kezufenchai-Keep",1)
								return
							end
						end
					end
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("SkillCard") and use.to:length()>0 then
				local to = player:getTag("fenchaiPlayer"):toPlayer()
				if to then return end
				for _, p in sgs.list(use.to) do
					if p:getGender()~=player:getGender() then
						player:setTag("fenchaiPlayer",ToData(p))
						room:setPlayerMark(p,"&kezufenchai-Keep",1)
						return
					end
				end
			end
		end
	end,
}
kezu_xuncan:addSkill(kezufenchai)
kezu_xuncan:addSkill("kezudaojie")

table.insert(ol_clans.yingchuan_xun,"xuncai")
kezu_xuncai = sgs.General(extension, "kezu_xuncai", "qun", 3, false, false, false)

kezulieshiCard = sgs.CreateSkillCard{
	name = "kezulieshiCard",
	target_fixed = true,
	on_use = function(self, room, player, targets)
		local choices = {}
		if player:hasJudgeArea() then
		    table.insert(choices, "lieshidamage="..player:objectName())
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
		local choice = room:askForChoice(player, "kezulieshi", table.concat(choices,"+"))
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
			if dummy:subcardsLength()>0 then
				--UseCardRecast(player,dummy,"kezulieshi",dummy:subcardsLength())
				room:throwCard(dummy,"kezulieshi",player)
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
			if dummy:subcardsLength()>0 then
				--UseCardRecast(player,dummy,"kezulieshi",dummy:subcardsLength())
				room:throwCard(dummy,"kezulieshi",player)
			end
		end
		if player:isDead() then return end
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "kezulieshi", "kezulieshi-ask",false,true)
		if not target:hasJudgeArea() and table.contains(choices, "lieshidamage="..player:objectName()) then
		    table.removeOne(choices, "lieshidamage="..player:objectName())
		end
		local s,j = false,false
		for _,c in sgs.qlist(target:getHandcards()) do
			if c:isKindOf("Jink") then j = true end
			if c:isKindOf("Slash") then s = true end
		end
		if table.contains(choices, "slash") and s==false
		then table.removeOne(choices, "slash") end
		if table.contains(choices, "jink") and j==false
		then table.removeOne(choices, "jink") end
		if #choices<1 then return end
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
			if dummy:subcardsLength()>0 then
				--UseCardRecast(target,dummy,"kezulieshi",dummy:subcardsLength())
				room:throwCard(dummy,"kezulieshi",target)
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
			if dummy:subcardsLength()>0 then
				--UseCardRecast(target,dummy,"kezulieshi",dummy:subcardsLength())
				room:throwCard(dummy,"kezulieshi",target)
			end
		end
	end,
}
kezulieshi = sgs.CreateViewAsSkill{
	name = "kezulieshi",
	view_as = function(self,cards)
		return kezulieshiCard:clone()
	end,
	enabled_at_play = function(self,player)
		for _, c in sgs.qlist(player:getHandcards()) do
			if c:isKindOf("Jink") or c:isKindOf("Slash")
			then return true end
		end
		return player:hasJudgeArea()
	end,
}
kezu_xuncai:addSkill(kezulieshi)

kezudianzhan = sgs.CreateTriggerSkill{
	name = "kezudianzhan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and player:getMark(use.card:getSuitString().."dianzhan_lun")<1 then
				room:broadcastSkillInvoke(self:objectName())
				player:addMark(use.card:getSuitString().."dianzhan_lun")
				MarkRevises(player,"&kezudianzhan_lun",use.card:getSuitString().."_char")
				local chain = 0
				if (use.to:length() == 1) then
					if not use.to:at(0):isChained() then
						room:setPlayerChained(use.to:at(0))
						chain = 1
					end
				end
				local dummy = sgs.Sanguosha:cloneCard("slash")
				for _, c in sgs.qlist(player:getCards("h")) do
					if c:getSuit() == use.card:getSuit()
					and not player:isCardLimited(c,sgs.Card_MethodRecast)
					then dummy:addSubcard(c) end
				end
				if dummy:subcardsLength()>0 then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), "kezudianzhan", "")
					--重铸
					room:moveCardTo(dummy, nil, sgs.Player_DiscardPile, reason)
					--标记摸的牌
					player:drawCards(dummy:subcardsLength(),"recast")
					chain = chain+1
				end
				dummy:deleteLater()
				if chain == 2 then
					player:drawCards(1,self:objectName())
				end
			end
		end
	end,
}
kezu_xuncai:addSkill(kezudianzhan)

kezuhuanyin = sgs.CreateTriggerSkill{
	name = "kezuhuanyin",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EnterDying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EnterDying then
			local dying = data:toDying()
			if dying.who == player then
				local cha = 4-player:getHandcardNum()
				if cha > 0 then
					room:sendCompulsoryTriggerLog(player,self)
					player:drawCards(cha,self:objectName())
				end
			end
		end
	end,
}
kezu_xuncai:addSkill(kezuhuanyin)
kezu_xuncai:addSkill("kezudaojie")

sgs.LoadTranslationTable{
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

    --族荀淑

    ["nyzu_xunshu"] = "族荀淑",
    ["#nyzu_xunshu"] = "长儒赡宗",
	["designer:nyzu_xunshu"] = "玄蝶既白",
	["cv:nyzu_xunshu"] = "官方",
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
	["cv:nyzu_xunchen"] = "官方",
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
	["cv:nyzu_xunyou"] = "官方",
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
	["cv:kezu_xuncai"] = "官方",
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
	["cv:kezu_xuncan"] = "官方",
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

table.insert(ol_clans.yingchuan_xun,"xunshuang")
zu_xunshuang = sgs.General(extension,"zu_xunshuang","qun",3)

zuyangji = sgs.CreateTriggerSkill{
	name = "zuyangji",
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging,sgs.HpChanged,sgs.DamageDone},
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("zuyangjiHpChanged-Clear")>0
					and p:getHandcardNum()>0 and p:hasSkill(self)
					and p:askForSkillInvoke(self,data) then
						p:peiyin(self)
						room:showAllCards(p)
						local lc = nil
						room:removeTag("zuyangjiDamage")
						while p:isAlive() do
							local has = false
							for _,h in sgs.qlist(p:getHandcards()) do
								has = h:isBlack() and h:isAvailable(p)
								if has then break end
							end
							if has then
								has = room:askForUseCard(p,"$.|black|.|hand!","zuyangji0",-1,sgs.Card_MethodUse,false,nil,nil,"zuyangjiUse")
								if has then lc = has else break end
								if room:getTag("zuyangjiDamage"):toBool() then break end
							else
								break
							end
						end
						if lc and lc:getSuit()==0 and room:getCardOwner(lc:getEffectiveId())==nil then
							local dc = dummyCard("indulgence")
							dc:setSkillName("zuyangji")
							dc:addSubcard(lc)
							if p:isProhibited(player,dc) then continue end
							room:moveCardTo(dc,p,sgs.Player_PlaceTable,true)
							lc = sgs.SPlayerList()
							lc:append(player)
							dc:use(room,p,lc)
						end
					end
				end
			end
		elseif (event == sgs.DamageDone) then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("zuyangjiUse") then
				room:setTag("zuyangjiDamage",ToData(true))
			end
		elseif (event == sgs.HpChanged) then
			player:addMark("zuyangjiHpChanged-Clear")
		elseif (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Start) then
			if player:getHandcardNum()>0 and player:hasSkill(self)
			and player:askForSkillInvoke(self,data) then
				player:peiyin(self)
				room:showAllCards(player)
				local lc = nil
				room:removeTag("zuyangjiDamage")
				while player:isAlive() do
					local has = false
					for _,h in sgs.qlist(player:getHandcards()) do
						has = h:isBlack() and h:isAvailable(player)
						if has then break end
					end
					if has then
						has = room:askForUseCard(player,"$.|black|.|hand!","zuyangji0",-1,sgs.Card_MethodUse,false,nil,nil,"zuyangjiUse")
						if has then lc = has else break end
						if room:getTag("zuyangjiDamage"):toBool() then break end
					else
						break
					end
				end
				if lc and lc:getSuit()==0 and room:getCardOwner(lc:getEffectiveId())==nil then
					local dc = dummyCard("indulgence")
					dc:setSkillName("zuyangji")
					dc:addSubcard(lc)
					if player:isProhibited(player,dc) then return end
					room:moveCardTo(dc,player,sgs.Player_PlaceTable,true)
					lc = sgs.SPlayerList()
					lc:append(player)
					dc:use(room,player,lc)
				end
			end
		end
	end,
}
zu_xunshuang:addSkill(zuyangji)
zudandao = sgs.CreateTriggerSkill{
	name = "zudandao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.FinishRetrial},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.FinishRetrial then
			room:sendCompulsoryTriggerLog(player,self)
			local cp = room:getCurrent()
			if cp:isAlive() then
				room:addMaxCards(cp,3,true)
			end
		end
	end,
}
zu_xunshuang:addSkill(zudandao)
zuqingli = sgs.CreateTriggerSkill{
	name = "zuqingli",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					local n = p:getMaxCards()-p:getHandcardNum()
					if n>0 and p:hasSkill(self) then
						if n>5 then n = 5 end
						room:sendCompulsoryTriggerLog(p,self)
						p:drawCards(n,self:objectName())
					end
				end
			end
		end
	end,
}
zu_xunshuang:addSkill(zuqingli)
zu_xunshuang:addSkill("kezudaojie")
sgs.LoadTranslationTable{
	["zu_xunshuang"] = "族荀爽",
	["#zu_xunshuang"] = "分投急所",
	--["designer:zu_xunshuang"] = "玄蝶既白",
	--["cv:zu_xunshuang"] = "官方",
	--["illustrator:zu_xunshuang"] = "鬼画府",
	["information:zu_xunshuang"] = "宗族：[颍川·荀氏]",

	["zuyangji"] = "佯疾",
	[":zuyangji"] = "准备阶段，或你的体力值变化过的回合结束时，你可以展示所有手牌，然后依次使用其中的黑色牌，直到你无法使用或造成了伤害，然后若以此法使用的最后一张牌为♠，你将之当做【乐不思蜀】置于当前回合角色判定区。",

	["zudandao"] = "耽道",
	[":zudandao"] = "锁定技，你判定后，当前回合角色本回合手牌上限+3。",

	["zuqingli"] = "清励",
	[":zuqingli"] = "锁定技，每回合结束时，你将手牌摸至手牌上限（至多摸5张）。",

	["zuyangji0"] = "佯疾：请使用手牌中的黑色牌",

	--["$zuyangji1"] = "百姓罹灾，当施粮以赈。",
	--["$zuyangji2"] = "开仓放粮，以赈灾民。",
	--["$zudandao1"] = "当逐千里之驹，情深可留嬴城。",
	--["$zudandao2"] = "乡老十里相送，此驹可彰吾情。",
	--["$zuqingli1"] = "[韩韶] 民者居野而多艰，不可不恤。",
	--["$zuqingli2"] = "[韩韶] 天下之本，上为君，下为民。",

	--["~zu_xunshuang"] = "天地不仁，万物何辜……",

}


--颍川韩氏
sgs.LoadTranslationTable{

    ["ke_yinchuanhanshi"] = "颍川韩氏",
    ["kezuxumin"] = "恤民",
	["kezuxuminex"] = "恤民",
    [":kezuxumin"] = "宗族技，限定技，你可以将一张牌当【五谷丰登】对任意名其他角色使用。",
}

ol_clans.yingchuan_han = {"hanshao","hanfu"}
kezu_hanshao = sgs.General(extension, "kezu_hanshao", "qun", 3, true, false, false)

kezufangzhen = sgs.CreateTriggerSkill{
	name = "kezufangzhen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.RoundStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.RoundStart) then
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
			local fri = room:askForPlayerChosen(player, aps, self:objectName(), "kezufangzhen-ask",true,true)
			if fri then
				local tl = player:getTag("kezufangzhenTL"):toIntList()
				tl:append(fri:getSeat())
				player:setTag("kezufangzhenTL",ToData(tl))
				room:setPlayerChained(fri,true)
				if room:askForChoice(player,"kezufangzhen","mopai+rec", ToData(fri)) == "mopai" then
					player:drawCards(2,self:objectName())
					local cards = room:askForExchange(player, self:objectName(), 2, 2, true, "kezufangzhenchoose",false)
					room:obtainCard(fri, cards, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), player:objectName(), self:objectName(), ""), false)
				else
					room:recover(fri, sgs.RecoverStruct(self:objectName(),player))
				end
			end
		end
	end,
}
kezu_hanshao:addSkill(kezufangzhen)

kezuliujuVS = sgs.CreateOneCardViewAsSkill{
	name = "kezuliuju",
	expand_pile = "#kezuliuju",
	response_pattern = "@@kezuliuju",
	view_filter = function(self, to_select)
		return to_select:isAvailable(sgs.Self) 
		and sgs.Self:getPile("#kezuliuju"):contains(to_select:getEffectiveId())
	end,
	view_as = function(self, card)
		return card
	end
}
kezuliuju = sgs.CreateTriggerSkill{
	name = "kezuliuju",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = kezuliujuVS,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			local targets = sgs.SPlayerList()
			for _, p in sgs.list(room:getOtherPlayers(player)) do
				if player:canPindian(p) then 
					targets:append(p) 
				end
			end
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "kezuliuju-ask", true, true)
			if target then
				room:broadcastSkillInvoke(self:objectName()) 
				local fm,tm = player:distanceTo(target),target:distanceTo(player)
				local pd = player:PinDian(target, self:objectName())
				if pd.from_number~=pd.to_number then
				local loser = player
				if pd.success then loser = target end
				local ids = sgs.IntList()
				if pd.from_card:getTypeId()~=1 then
					ids:append(pd.from_card:getEffectiveId())
				end
				if pd.to_card:getTypeId()~=1 then
					ids:append(pd.to_card:getEffectiveId())
				end
				while ids:length()>0 and loser:isAlive() do
					loser:setTag("kezuliujuIds",ToData(ids))
					room:notifyMoveToPile(loser, ids, self:objectName(), room:getCardPlace(ids:at(0)), true)
					local card = room:askForUseCard(loser, "@@kezuliuju", "kezuliuju-use")
					room:notifyMoveToPile(loser, ids, self:objectName(), room:getCardPlace(ids:at(0)), false)
					if card then ids:removeOne(card:getEffectiveId())
					else break end
				end
				end
				if (fm~=player:distanceTo(target) or tm~=target:distanceTo(player))
				and player:hasSkill("kezuxumin",true) and player:getMark("@kezuxumin")<1
				then room:setPlayerMark(player,"@kezuxumin",1) end
			end
		end
	end,
}
kezu_hanshao:addSkill(kezuliuju)

kezuxuminCard = sgs.CreateSkillCard{
	name = "kezuxuminCard",
    target_fixed = false,
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select, source)
		local wgfd = sgs.Sanguosha:cloneCard("amazing_grace")
		wgfd:setSkillName("kezuxumin")
		wgfd:addSubcard(self)
		wgfd:deleteLater()
		return to_select ~= source
		and not source:isProhibited(to_select,wgfd)
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source,"@kezuxumin")
		room:doSuperLightbox(source,"kezuxumin")
		local wgfd = sgs.Sanguosha:cloneCard("amazing_grace")
		wgfd:setSkillName("_kezuxumin")
		wgfd:addSubcard(self)
		wgfd:deleteLater()
		local n = math.random(1,2)
		if source:getGeneralName():endsWith("hanrong")
		or source:getGeneral2Name():endsWith("hanrong") then n = n+2 end
		room:broadcastSkillInvoke("kezuxumin",n,source)
		local use = sgs.CardUseStruct(wgfd,source)
		for _, p in ipairs(targets)do
			use.to:append(p)
		end
		room:useCard(use, true)
	end
}
kezuxumin = sgs.CreateViewAsSkill{
	name = "kezuxumin",
	frequency = sgs.Skill_Limited,
	limit_mark = "@kezuxumin",
	n = 1,
	view_filter = function(self, selected, to_select)
		local wgfd = sgs.Sanguosha:cloneCard("amazing_grace")
		wgfd:setSkillName("kezuxumin")
		wgfd:addSubcard(to_select)
		wgfd:deleteLater()
        return not sgs.Self:isLocked(wgfd)
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = kezuxuminCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@kezuxumin") > 0
	end,
}
kezu_hanshao:addSkill(kezuxumin)

sgs.LoadTranslationTable{
	["kezu_hanshao"] = "族韩韶",
	["#kezu_hanshao"] = "分投急所",
	["designer:kezu_hanshao"] = "玄蝶既白",
	["cv:kezu_hanshao"] = "官方",
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

table.insert(ol_clans.yingchuan_han,"hanrong")
kezu_hanrong = sgs.General(extension, "kezu_hanrong", "qun", 3, true, false, false)

kezulianhe = sgs.CreateTriggerSkill{
	name = "kezulianhe",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_PlaceHand
			and move.to:objectName() == player:objectName()
			and player:getPhase() == sgs.Player_Play
			and player:getMark("&beusekezulianhe-SelfPlayClear")>0 then
				if move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW
				or player:getMark("&hasdrawlianhe-PlayClear")>0 then
					room:setPlayerMark(player,"&hasdrawlianhe-PlayClear",1)
					room:setPlayerMark(player,"&lianhenum-PlayClear",0)
				else
				    room:addPlayerMark(player,"&lianhenum-PlayClear",move.card_ids:length())
				end
			end
		end
		if event == sgs.EventPhaseStart
		and player:getPhase() == sgs.Player_Play
		and player:hasSkill(self:objectName()) then
			local aps = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if not p:isChained() then
					aps:append(p)
				end
			end
			if (aps:length() >= 2) then
				if player:askForSkillInvoke(self,ToData("kezulianhe0"),false) then
					local ones = room:askForPlayersChosen(player, aps, self:objectName(), 2, 2, "kezulianhe-ask", true, true)
					if ones:length() == 2 then
						room:broadcastSkillInvoke(self:objectName())
						for _, p in sgs.qlist(ones) do
							room:setPlayerChained(p)
							room:setPlayerMark(p,player:objectName().."kezulianhe-SelfPlayClear",1)
							room:setPlayerMark(p,"&beusekezulianhe-SelfPlayClear",1)
						end
					end
				end
			end
		end
		if (event == sgs.EventPhaseEnd) and (player:getPhase() == sgs.Player_Play) then
			local n = player:getMark("&lianhenum-PlayClear")
			if n>0 then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if player:getMark(p:objectName().."kezulianhe-SelfPlayClear")>0 then
						room:sendCompulsoryTriggerLog(player,self)
						n = math.min(3,n)
						local givenum = n - 1
						local drawnum = n + 1
						if givenum>0 and player~=p then
							player:setTag("kezulianheFrom",ToData(p))
							local card = room:askForExchange(player,self:objectName(),givenum,givenum,true,"kezulianhegive:"..p:objectName()..":"..givenum..":"..drawnum,true)
							if card then
								local log = sgs.LogMessage()
								log.type = "$kezulianheloggive"
								log.from = player
								log.to:append(p)
								room:sendLog(log)
								room:giveCard(player,p,card,self:objectName())
								continue
							end
						end
						local log = sgs.LogMessage()
						log.type = "$kezulianhelogdraw"
						log.from = player
						log.to:append(p)
						room:sendLog(log)
						p:drawCards(drawnum,self:objectName())
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
}
kezu_hanrong:addSkill(kezulianhe)

kezuhuanjiaVS = sgs.CreateOneCardViewAsSkill{
	name = "kezuhuanjia",
	expand_pile = "#kezuhuanjia",
	response_pattern = "@@kezuhuanjia",
	view_filter = function(self, to_select)
		return to_select:isAvailable(sgs.Self) 
		and sgs.Self:getPile("#kezuhuanjia"):contains(to_select:getEffectiveId())
	end,
	view_as = function(self, card)
		return card
	end
}

kezuhuanjia = sgs.CreateTriggerSkill{
	name = "kezuhuanjia",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = kezuhuanjiaVS,
	events = {sgs.EventPhaseEnd,sgs.Pindian,sgs.DamageDone},
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DamageDone) then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("huanjiacard") then
				room:setPlayerMark(damage.from,damage.card:toString().."huanjiada-Clear",1)
			end
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play
		and player:hasSkill(self) then
			local targets = sgs.SPlayerList()
			for _, p in sgs.list(room:getOtherPlayers(player))do
				if player:canPindian(p) then targets:append(p) end
			end
			if targets:length() > 0 then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "kezuliuju-ask", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName()) 
				    local pd = player:PinDian(target, self:objectName()) 
					local winner = target
					if pd.success then winner = player end
					local ids = sgs.IntList()
					ids:append(pd.from_card:getEffectiveId())
					ids:append(pd.to_card:getEffectiveId())
					winner:setTag("kezuhuanjiaIds",ToData(ids))
					room:notifyMoveToPile(winner, ids, self:objectName(), room:getCardPlace(ids:at(0)), true)
					local card = room:askForUseCard(winner, "@@kezuhuanjia","kezuhuanjia-use",-1,sgs.Card_MethodUse,true,nil,nil,"huanjiacard")
					room:notifyMoveToPile(winner, ids, self:objectName(), room:getCardPlace(ids:at(0)), false)
					if card then
						if winner:getMark(card:toString().."huanjiada-Clear")>0 then
							ids = {}
							for _,sk in sgs.list(player:getVisibleSkillList())do
								if sk:isAttachedLordSkill() then continue end
								table.insert(ids,sk:objectName())
							end
							if #ids<1 then return end
							ids = table.concat(ids,"+")
							ids = room:askForChoice(player,self:objectName(),ids)
							room:detachSkillFromPlayer(player,ids)
						else
							ids:removeOne(card:getEffectiveId())
							room:obtainCard(player,ids:first())
						end
					end
			    end
			end
		end
	end,
}
kezu_hanrong:addSkill(kezuhuanjia)

kezu_hanrong:addSkill("kezuxumin")

sgs.LoadTranslationTable{
	["kezu_hanrong"] = "族韩融",
	["#kezu_hanrong"] = "虎口扳渡",
	["designer:kezu_hanrong"] = "玄蝶既白",
	["cv:kezu_hanrong"] = "官方",
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



--太原王氏
ol_clans.taiyuan_wang = {"wangyun","wanglie"}
kezu_wangyun = sgs.General(extension, "kezu_wangyun", "qun", 3, true, false, false)

kezujiexuanVS = sgs.CreateViewAsSkill{
	name = "kezujiexuan",
	n = 1,
	view_filter = function(self, selected, to_select)
		local n = sgs.Self:getChangeSkillState("kezujiexuan")
		return (to_select:isRed() and n == 1)
		or (to_select:isBlack() and n == 2)
	end,
	view_as = function(self, cards)
		if #cards<1 then return end
		local n = sgs.Self:getChangeSkillState("kezujiexuan")
		if n==1 then
			local ssqy = sgs.Sanguosha:cloneCard("snatch")
			ssqy:addSubcard(cards[1])
			ssqy:setSkillName("kezujiexuan")
			return ssqy
		elseif n==2 then
			local ghcq = sgs.Sanguosha:cloneCard("dismantlement")
			ghcq:addSubcard(cards[1])
			ghcq:setSkillName("kezujiexuan")
			return ghcq
		end
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@kezujiexuan")>0
	end
}
kezujiexuan = sgs.CreateTriggerSkill{
	name = "kezujiexuan",
	frequency = sgs.Skill_Limited,
	events = {sgs.PreCardUsed},
	limit_mark = "@kezujiexuan",
	change_skill = true,
	view_as_skill = kezujiexuanVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.PreCardUsed) then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"kezujiexuan") then
				room:removePlayerMark(player,"@kezujiexuan")
				if (player:getChangeSkillState("kezujiexuan") == 1) then
					room:setChangeSkillState(player, "kezujiexuan", 2)
				else
					room:setChangeSkillState(player, "kezujiexuan", 1)
				end
			end
		end
	end
}
kezu_wangyun:addSkill(kezujiexuan)

kezumingjieCard = sgs.CreateSkillCard{
	name = "kezumingjieCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:removePlayerMark(source,"@kezumingjie")
		room:setPlayerMark(target,"&kezumingjie+#"..source:objectName(),1)
		room:addPlayerMark(target,source:objectName().."kezumingjie-Clear")
	end
}
kezumingjieVS = sgs.CreateZeroCardViewAsSkill{
	name = "kezumingjie",
	enabled_at_play = function(self, player)
		return player:getMark("@kezumingjie") > 0
	end,
	view_as = function()
		return kezumingjieCard:clone()
	end
}
kezumingjie = sgs.CreateTriggerSkill{
	name = "kezumingjie",
	view_as_skill = kezumingjieVS,
	events = {sgs.CardOffset,sgs.TargetSpecifying,sgs.CardUsed,sgs.EventPhaseChanging},
	frequency = sgs.Skill_Limited,
	limit_mark = "@kezumingjie",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        if (event == sgs.CardOffset) then
            local effect = data:toCardEffect()
			local tag = player:getTag("kezumingjieToGet"):toIntList()
			tag:append(effect.card:getEffectiveId())
			player:setTag("kezumingjieToGet", ToData(tag))
        elseif (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				--先询问使用再清除之
				for _,wy in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player:getMark(wy:objectName().."kezumingjie-Clear")>0 then continue end
					if player:getMark("&kezumingjie+#"..wy:objectName())<1 then continue end
					room:setPlayerMark(player,"&kezumingjie+#"..wy:objectName(),0)
					local tag = player:getTag("kezumingjieToGet"):toIntList()
					while player:isAlive() and tag:length()>0 do
						local canusecards = sgs.IntList()
						for _,id in sgs.qlist(tag) do
							if not canusecards:contains(id)
							and room:getCardPlace(id)==sgs.Player_DiscardPile
							and sgs.Sanguosha:getCard(id):isAvailable(wy)
							then canusecards:append(id) end
						end
						if canusecards:isEmpty() then break end
						room:fillAG(canusecards, wy)
						local to_back = room:askForAG(wy, canusecards, true, self:objectName())
						room:clearAG(wy)
						if to_back<0 then break end
						tag:removeOne(to_back)
						room:addPlayerMark(wy, "kezumingjie-PlayClear", to_back)
						room:askForUseCard(wy, "@@kezumingjiemark", "kezumingjieuseask:"..sgs.Sanguosha:getCard(to_back):objectName())
					end
				end
				player:removeTag("kezumingjieToGet")
			end
		elseif (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and use.card:getSuit() == sgs.Card_Spade then
				local tag = player:getTag("kezumingjieToGet"):toIntList()
				tag:append(use.card:getEffectiveId())
				player:setTag("kezumingjieToGet", ToData(tag))
			end
		elseif event == sgs.TargetSpecifying and player:hasSkill(self) then
			local use = data:toCardUse()
			if use.card:isKindOf("BasicCard") or use.card:isNDTrick() then
				room:setTag("kezumingjieData",data)
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getMark("&kezumingjie+#"..player:objectName())>0 and not use.to:contains(p)
					and player:askForSkillInvoke(self,ToData("kezumingjie0:"..p:objectName())) then
						room:broadcastSkillInvoke(self:objectName())
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
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}
kezu_wangyun:addSkill(kezumingjie)

kezumingjiemark = sgs.CreateZeroCardViewAsSkill{
	name = "kezumingjiemark",
	response_pattern = "@@kezumingjiemark",
	enabled_at_play = function(self, player)
		return false
	end,
	view_as = function()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if (pattern == "@@kezumingjiemark") then
			local id = sgs.Self:getMark("kezumingjie-PlayClear")
			return sgs.Sanguosha:getEngineCard(id)
		end
	end
}
extension:addSkills(kezumingjiemark)

kezuzhongliu = sgs.CreateTriggerSkill{
	name = "kezuzhongliu",
	events = {sgs.PreCardUsed,sgs.CardUsed},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event==sgs.CardUsed then
			if use.card:hasFlag("kezuzhongliuBf") then
				room:sendCompulsoryTriggerLog(player,self:objectName())
				local n = math.random(1,2)
				if player:getGeneralName():endsWith("wangling")
				or player:getGeneral2Name():endsWith("wangling") then n = n+2
				elseif player:getGeneralName():endsWith("wanghun")
				or player:getGeneral2Name():endsWith("wanghun") then n = n+4
				elseif player:getGeneralName():endsWith("wanglun")
				or player:getGeneral2Name():endsWith("wanglun") then n = n+6
				elseif player:getGeneralName():endsWith("wangchang")
				or player:getGeneral2Name():endsWith("wangchang") then n = n+8
				elseif player:getGeneralName():endsWith("wangshen")
				or player:getGeneral2Name():endsWith("wangshen") then n = n+10 end
				room:broadcastSkillInvoke(self:objectName(),n,player)
				local sks = {}
				for _,sk in sgs.qlist(player:getVisibleSkillList()) do
					if player:hasInnateSkill(sk:objectName()) then
						if sk:isLimitedSkill() then
							room:setPlayerMark(player,sk:getLimitMark(),1)
						else
							local translate = sgs.Sanguosha:translate(":"..sk:objectName())
							if string.find(translate,"限") and string.find(translate,"次")
							or string.find(translate,"发动次数")
							then table.insert(sks,sk:objectName()) end
						end
					end
				end
				local ms,fs = player:getMarkNames(),player:getFlagList()
				for _,skn in sgs.list(sks)do
					for _,m in sgs.list(ms) do
						if string.find(m,skn) and not string.find(m,"sgs")
						and (m:endsWith("-PlayClear") or m:endsWith("-Clear") or m:endsWith("_lun") or m:startsWith("&"..skn))
						then room:setPlayerMark(player,m,0) end
					end
					for _,f in sgs.list(fs) do
						if f:startsWith("kezuzhongliuUse:")
						and string.find(f,skn) then
							local fsp = f:split(":")
							room:addPlayerHistory(player,fsp[2],0)
							room:setPlayerFlag(player,"-"..f)
						end
					end
				end
			end
		elseif event == sgs.PreCardUsed then
			if use.card:getTypeId()<1 then
				local cn = use.card:getClassName()
				if use.card:inherits("LuaSkillCard")
				then cn = "#"..use.card:objectName() end
				room:setPlayerFlag(player,"kezuzhongliuUse:"..cn)
				return
			end
			local owner = room:getCardOwner(use.card:getEffectiveId())
			--若使用的牌没有主人，或有主人但不是同族的角色，就可以重置
			if not(owner and isSameClan(player, owner) and use.m_isHandcard)--或者不是手牌
			then room:setCardFlag(use.card,"kezuzhongliuBf") end
		end
	end,
}
kezu_wangyun:addSkill(kezuzhongliu)

sgs.LoadTranslationTable{
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
	["cv:kezu_wangyun"] = "官方",
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

table.insert(ol_clans.taiyuan_wang,"wangling")
kezu_wangling = sgs.General(extension, "kezu_wangling", "wei", 4, true, false, false)

kezubolongCard = sgs.CreateSkillCard{
	name = "kezubolongCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select ~= player
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local choices = {}
		if (player:getCardCount() > 0) then
			table.insert(choices, "give")
		end
		local n = player:getHandcardNum()
		if (target:getCardCount() >= n) then
			table.insert(choices, "jiu")
		end
		if #choices > 0 then
			if room:askForChoice(target,"kezubolong",table.concat(choices, "+")) == "give" then
				local card = room:askForExchange(player, "kezubolong", 1, 1, true, "kezubolongchoose:1:"..target:objectName(),false)
				if card then room:giveCard(player, target, card, "kezubolong") end
				local dc = sgs.Sanguosha:cloneCard("thunder_slash")
				dc:setSkillName("_kezubolong")
				if player:canUse(dc,target) then
					room:useCard(sgs.CardUseStruct(dc,player,target),true)
				end
				dc:deleteLater()
			else
				local card = room:askForExchange(target, "kezubolong", n, n, true, "kezubolongchoose:"..n..":"..player:objectName(),false)
				if card then room:giveCard(target, player, card, "kezubolong") end
				local dc = sgs.Sanguosha:cloneCard("analeptic")
				dc:setSkillName("_kezubolong")
				if target:canUse(dc,player) then
					room:useCard(sgs.CardUseStruct(dc,target,player),true)
				end
				dc:deleteLater()
			end
		end	
	end
}

kezubolong = sgs.CreateZeroCardViewAsSkill{
	name = "kezubolong",
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#kezubolongCard"))
	end,
	view_as = function()
		return kezubolongCard:clone()
	end
}
kezu_wangling:addSkill(kezubolong)
kezu_wangling:addSkill("kezuzhongliu")

sgs.LoadTranslationTable{
	["kezu_wangling"] = "族王凌",
	["#kezu_wangling"] = "荧惑守斗",
	["designer:kezu_wangling"] = "玄蝶既白",
	["cv:kezu_wangling"] = "官方",
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

table.insert(ol_clans.taiyuan_wang,"wanghun")
kezu_wanghun = sgs.General(extension, "kezu_wanghun", "jin", 3, true, false, false)

kezufuxunCard = sgs.CreateSkillCard{
	name = "kezufuxunCard",
	will_throw = false,
	filter = function(self, targets, to_select, source)
		if source:objectName()==to_select:objectName() then return false end
		if self:subcardsLength()>0 then return true end
		return to_select:getHandcardNum()>0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local tri = target:getMark("&kezufuxunmove-PlayClear")<1
		if (self:subcardsLength()<1) then
			local card_id = room:askForCardChosen(source, target, "h", "kezufuxun")
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
			room:obtainCard(source, sgs.Sanguosha:getCard(card_id), reason, room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
		else
			room:giveCard(source, target, self, "kezufuxun")
		end
		if (target:getHandcardNum() == source:getHandcardNum()) and tri then
			local ids = room:getAvailableCardList(source,"basic","kezufuxun")
			if ids:isEmpty() then return end
			room:fillAG(ids,source)
			local id = room:askForAG(source,ids,true,"kezufuxun","kezufuxun0:")
			room:clearAG(source)
			if id<0 then return end
			room:setPlayerMark(source, "kezufuxunbasic", id)
			room:askForUseCard(source, "@@kezufuxunbasic", "kezufuxunvs-ask")
		end
	end,
}
kezufuxunVS = sgs.CreateViewAsSkill{
	name = "kezufuxun",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return kezufuxunCard:clone()
		elseif #cards == 1 then
			local card = kezufuxunCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kezufuxunCard")
	end, 
}
kezufuxun = sgs.CreateTriggerSkill{
	name = "kezufuxun",
	view_as_skill = kezufuxunVS,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if (player:getPhase() == sgs.Player_Play) then
				if move.to_place == sgs.Player_PlaceHand and player:objectName() ~= move.to:objectName() then
					local to = room:findPlayerByObjectName(move.to:objectName())
					room:setPlayerMark(to,"&kezufuxunmove-PlayClear",1)
				end
				if move.from_places:contains(sgs.Player_PlaceHand) and player:objectName() ~= move.from:objectName() then
					local from = room:findPlayerByObjectName(move.from:objectName())
					room:setPlayerMark(from,"&kezufuxunmove-PlayClear",1)
				end
			end
		end
	end,
}
kezu_wanghun:addSkill(kezufuxun)

kezufuxunbasic = sgs.CreateViewAsSkill{
	name = "kezufuxunbasic",
	n = 1,
	response_pattern = "@@kezufuxunbasic",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@kezufuxunbasic" then return true end
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards<1 then return end
		local id = sgs.Self:getMark("kezufuxunbasic")
		local c = sgs.Sanguosha:getCard(id)
		c = sgs.Sanguosha:cloneCard(c:objectName())
		c:setSkillName("_kezufuxun")
		c:addSubcard(cards[1])
		return c
	end,
	enabled_at_play = function(self, player)
		return false
	end, 
}
extension:addSkills(kezufuxunbasic)

kezuchenya = sgs.CreateTriggerSkill{
	name = "kezuchenya",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.ChoiceMade,sgs.SkillTriggered,sgs.CardFinished},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.ChoiceMade) then
			local struct = data:toString()
			if struct=="" then return end
			local promptlist = struct:split(":")
			if promptlist[1]~="notifyInvoked"
			or player:hasEquipSkill(promptlist[2]) then return end
			local translation = sgs.Sanguosha:translate(":"..promptlist[2])
			if translation~=":"..promptlist[2] then
				for _,t in ipairs(translation:split("，")) do
					if t:endsWith("出牌阶段限一次") then
						--[[for _,owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
							if owner:isAlive() and owner:askForSkillInvoke(self,player) then
								room:broadcastSkillInvoke(self:objectName())
								room:askForUseCard(player, "@@kezuchenyacz", "kezuchenya-ask",-1,sgs.Card_MethodRecast)
							end
						end--]]
						player:setFlags("kezuchenya_"..promptlist[2])
						break
					end
				end
			end
		elseif (event == sgs.CardFinished) then
			local use = data:toCardUse()
			for _,s in ipairs(use.card:getSkillNames()) do
				if player:hasFlag("kezuchenya_"..s) then
					player:setFlags("-kezuchenya_"..s)
					for _,owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						if owner:isAlive() and player:getHandcardNum()>0
						and owner:askForSkillInvoke(self,player) then
							room:broadcastSkillInvoke(self:objectName())
							room:askForUseCard(player, "@@kezuchenyacz", "kezuchenya-ask",-1,sgs.Card_MethodRecast)
						end
					end
				end
			end
		elseif (event == sgs.SkillTriggered) then
			if player:hasFlag("kezuchenya_"..data:toString()) then
				player:setFlags("-kezuchenya_"..data:toString())
				for _,owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if owner:isAlive() and player:getHandcardNum()>0
					and owner:askForSkillInvoke(self,player) then
						room:broadcastSkillInvoke(self:objectName())
						room:askForUseCard(player, "@@kezuchenyacz", "kezuchenya-ask",-1,sgs.Card_MethodRecast)
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
kezu_wanghun:addSkill(kezuchenya)

kezuchenyaCard = sgs.CreateSkillCard{
	name = "kezuchenyaCard",
	target_fixed = true,
	will_throw = false,
	mute = true,
	handling_method = sgs.Card_MethodRecast,
    about_to_use = function(self,room,use)
		UseCardRecast(use.from,self,self:getSkillName(),self:subcardsLength())
	end,
}

--重铸
kezuchenyacz = sgs.CreateViewAsSkill{
	name = "kezuchenyacz",
	n = 99,
	response_pattern = "@@kezuchenyacz",
	view_filter = function(self, selected, to_select)
		return to_select:nameLength() == sgs.Self:getHandcardNum()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = kezuchenyaCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end, 
}
extension:addSkills(kezuchenyacz)

kezu_wanghun:addSkill("kezuzhongliu")

sgs.LoadTranslationTable{
	["kezu_wanghun"] = "族王浑",
	["#kezu_wanghun"] = "献捷横江",
	["designer:kezu_wanghun"] = "玄蝶既白",
	["cv:kezu_wanghun"] = "官方",
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

table.insert(ol_clans.taiyuan_wang,"wanglun")
kezu_wanglun = sgs.General(extension, "kezu_wanglun", "wei", 3, true, false, false)

kezuqiuxinCard = sgs.CreateSkillCard{
	name = "kezuqiuxinCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, from)
		return (#targets < 1) and (to_select:objectName() ~= from:objectName())
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local result = room:askForChoice(target,"kezuqiuxin","sha+jinnang")
		if result == "sha" then
			room:setPlayerMark(target,"&kezuqiuxinsha+#"..player:objectName(),1)
		else
			room:setPlayerMark(target,"&kezuqiuxinjinnang+#"..player:objectName(),1)
		end
	end
}
--主技能
kezuqiuxinVS = sgs.CreateViewAsSkill{
	name = "kezuqiuxin",
	n = 0,
	view_as = function(self, cards)
		return kezuqiuxinCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kezuqiuxinCard") 
	end, 
}

kezuqiuxin = sgs.CreateTriggerSkill{
	name = "kezuqiuxin",
	view_as_skill = kezuqiuxinVS,
	events = {sgs.TargetSpecified},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			for _, p in sgs.qlist(use.to)do
				local ids = sgs.IntList()
				if use.card:isKindOf("Slash") and p:getMark("&kezuqiuxinsha+#"..player:objectName())>0 then
					room:setPlayerMark(p,"&kezuqiuxinsha+#"..player:objectName(),0)
					ids = room:getAvailableCardList(player,"trick","kezuqiuxin")
				elseif use.card:isNDTrick() and p:getMark("&kezuqiuxinjinnang+#"..player:objectName())>0 then
					room:setPlayerMark(p,"&kezuqiuxinjinnang+#"..player:objectName(),0)
					for _,id in sgs.qlist(room:getAvailableCardList(player,"basic","kezuqiuxin")) do
						if sgs.Sanguosha:getCard(id):isKindOf("Slash") then ids:append(id) end
					end
				end
				if ids:length()>0 then
					player:setTag("kezuqiuxinTo",ToData(p))
					room:fillAG(ids,player)
					local id = room:askForAG(player,ids,true,"kezuqiuxin","kezuqiuxinask")
					room:clearAG(player)
					if id>=0 then
						ids:removeOne(id)
						local c = sgs.Sanguosha:getCard(id)
						local dc = sgs.Sanguosha:cloneCard(c:objectName())
						dc:setSkillName("_kezuqiuxin")
						dc:deleteLater()
						if player:canUse(dc,p) then
							room:useCard(sgs.CardUseStruct(dc,player,p))
						end
					end
				end
			end
		end
	end,
}
kezu_wanglun:addSkill(kezuqiuxin)

kezujianyuan = sgs.CreateTriggerSkill{
	name = "kezujianyuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardFinished,sgs.ChoiceMade,sgs.SkillTriggered},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				room:addPlayerMark(player,"sgsjianyuantimes-PlayClear")
			end
			for _,s in ipairs(use.card:getSkillNames()) do
				if player:hasFlag("kezujianyuan_"..s) then
					player:setFlags("-kezujianyuan_"..s)
					local n = player:getMark("sgsjianyuantimes-PlayClear")
					for _,owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						if owner:isAlive() and n>0 and owner:askForSkillInvoke(self,player) then
							room:broadcastSkillInvoke(self:objectName())
							room:askForUseCard(player, "@@kezujianyuancz", "kezujianyuan-ask:"..n,-1,sgs.Card_MethodRecast)
						end
					end
				end
			end
		elseif (event == sgs.ChoiceMade) then
			local skill = data:toString()
			if skill=="" then return end
			local promptlist = skill:split(":")
			if promptlist[1]~="notifyInvoked"
			or player:hasEquipSkill(promptlist[2]) then return end
			local translation = sgs.Sanguosha:translate(":"..promptlist[2])
			local n = player:getMark("sgsjianyuantimes-PlayClear")
			if n>0 and translation~=":"..promptlist[2] then
				for _,t in ipairs(translation:split("，")) do
					if t:endsWith("出牌阶段限一次") then
						--[[for _,owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
							if owner:isAlive() and owner:askForSkillInvoke(self,ToData(player)) then
								room:broadcastSkillInvoke(self:objectName())
								room:askForUseCard(player, "@@kezujianyuancz", "kezujianyuan-ask:"..n,-1,sgs.Card_MethodRecast)
							end
						end--]]
						player:setFlags("kezujianyuan_"..promptlist[2])
						break
					end
				end
			end
		elseif (event == sgs.SkillTriggered) then
			if player:hasFlag("kezujianyuan_"..data:toString()) then
				player:setFlags("-kezujianyuan_"..data:toString())
				local n = player:getMark("sgsjianyuantimes-PlayClear")
				for _,owner in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if owner:isAlive() and n>0 and owner:askForSkillInvoke(self,player) then
						room:broadcastSkillInvoke(self:objectName())
						room:askForUseCard(player, "@@kezujianyuancz", "kezujianyuan-ask:"..n,-1,sgs.Card_MethodRecast)
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
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
kezu_wanglun:addSkill(kezujianyuan)

kezujianyuanCard = sgs.CreateSkillCard{
	name = "kezujianyuanCard",
	target_fixed = true,
	will_throw = false,
	mute = true,
	handling_method = sgs.Card_MethodRecast,
	about_to_use = function(self,room,use)
		UseCardRecast(use.from,self,self:getSkillName(),self:subcardsLength())
	end,
}

--重铸
kezujianyuancz = sgs.CreateViewAsSkill{
	name = "kezujianyuancz",
	n = 99,
	response_pattern = "@@kezujianyuancz",
	view_filter = function(self, selected, to_select)
		return to_select:nameLength() == sgs.Self:getMark("sgsjianyuantimes-PlayClear")
		and not sgs.Self:isCardLimited(to_select,sgs.Card_MethodRecast)
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = kezujianyuanCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end, 
}
extension:addSkills(kezujianyuancz)

kezu_wanglun:addSkill("kezuzhongliu")

sgs.LoadTranslationTable{
	["kezu_wanglun"] = "族王沦",
	["#kezu_wanglun"] = "半缘修道",
	["designer:kezu_wanglun"] = "玄蝶既白",
	["cv:kezu_wanglun"] = "官方",
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

table.insert(ol_clans.taiyuan_wang,"wangguang")
kezu_wangguang = sgs.General(extension, "kezu_wangguang", "wei", 3, true, false, false)

kezulilunCard = sgs.CreateSkillCard{
	name = "kezulilunCard",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodRecast,
	on_use = function(self, room, player, targets)
		room:setPlayerMark(player,"zhongliulilun",0)
		local mcard = sgs.Sanguosha:getCard(self:getSubcards():first())
		room:setPlayerMark(player,mcard:objectName().."lilun-Clear",1)
		UseCardRecast(player,self,self:getSkillName(),self:subcardsLength())
		local ids = sgs.IntList()
		for _, card_id in sgs.qlist(self:getSubcards()) do
			if room:getCardPlace(card_id)==sgs.Player_DiscardPile
			and sgs.Sanguosha:getCard(card_id):isAvailable(player)
			then ids:append(card_id) end
		end
		if (ids:length() > 0) then
			room:fillAG(ids, player)
			local to_back = room:askForAG(player, ids, true, self:getSkillName())
			room:clearAG(player)
			if (to_back > -1) then
				room:setPlayerMark(player, "kezulilunuse", to_back)
				room:askForUseCard(player, "@@kezulilunuse", "kezulilunask:"..sgs.Sanguosha:getCard(to_back):objectName())
			end
		end
	end,
}

kezulilun = sgs.CreateViewAsSkill{
	name = "kezulilun",
	n = 2,
	view_filter = function(self, selected, to_select)
		if sgs.Self:getMark(to_select:objectName().."lilun-Clear")>0
		or sgs.Self:isCardLimited(to_select,sgs.Card_MethodRecast) then return false end
		return #selected<1 or selected[1]:sameNameWith(to_select)
	end,
	view_as = function(self, cards)
		if #cards > 1 then
			local card = kezulilunCard:clone()
			for _,c in pairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#kezulilunCard")
	end,  
}
kezu_wangguang:addSkill(kezulilun)

kezulilunuse = sgs.CreateZeroCardViewAsSkill{
	name = "kezulilunuse",
	response_pattern = "@@kezulilunuse",
	enabled_at_play = function(self, player)
		return false
	end,
	view_as = function()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if (pattern == "@@kezulilunuse") then
			return sgs.Sanguosha:getCard(sgs.Self:getMark("kezulilunuse"))
		end
	end
}
extension:addSkills(kezulilunuse)

kezujianjiCard = sgs.CreateSkillCard{
	name = "kezujianjiCard",
	filter = function(self, targets, to_select,player)
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
			room:removePlayerMark(source,"@kezujianji")
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		end
	end
}
kezujianjiVS = sgs.CreateViewAsSkill{
	name = "kezujianji",
	n = 0,
	view_as = function(self, cards)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("kezujianji")
		return slash
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern:startsWith("@@kezujianji")
	end
}

kezujianji = sgs.CreateTriggerSkill{
	name = "kezujianji",
	view_as_skill = kezujianjiVS,
	frequency = sgs.Skill_Limited,
	limit_mark = "@kezujianji",
	events = {sgs.EventPhaseChanging,sgs.CardUsed,sgs.CardResponded,sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	    if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				for _, wg in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if (wg:getMark("@kezujianji") > 0) then
						if (player:getMark("&kezujianjiuse-Clear") == 0) then
							if wg:askForSkillInvoke(self,ToData("kezujianji01:"..player:objectName())) then
								wg:peiyin(self)
								room:removePlayerMark(wg,"@kezujianji")
								wg:drawCards(1,self:objectName())
								player:drawCards(1,self:objectName())
							end
						end
						if (player:getMark("&kezujianjitar-Clear") == 0) then
							room:askForUseCard(wg, "@@kezujianji", "kezujianji02")
						end
					end
				end
			end
		end
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				local cur = room:getCurrent()
				if use.from ~= cur and cur:isAdjacentTo(use.from) then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:hasSkill(self,true) then
							room:setPlayerMark(cur,"&kezujianjiuse-Clear",1)
							break
						end
					end
				end
				if table.contains(use.card:getSkillNames(),self:objectName()) then
					room:removePlayerMark(use.from,"@kezujianji")
				end
			end
		end
		if (event == sgs.CardResponded) then
			local response = data:toCardResponse()
			if response.m_isUse and response.m_card:getTypeId()>0 then
				local cur = room:getCurrent()
				if player~=cur and cur:isAdjacentTo(player) then
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:hasSkill(self,true) then
							room:setPlayerMark(cur,"&kezujianjiuse-Clear",1)
							break
						end
					end
				end
			end
		end
		if (event == sgs.TargetConfirmed) then
			local use = data:toCardUse()
			local cur = room:getCurrent()
			if use.card:getTypeId()>0 and use.to:contains(player)
			and player ~= cur and cur:isAdjacentTo(player) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasSkill(self,true) then
						room:setPlayerMark(cur,"&kezujianjitar-Clear",1)
						break
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:isAlive()
	end,
}
kezu_wangguang:addSkill(kezujianji)
kezu_wangguang:addSkill("kezuzhongliu")

sgs.LoadTranslationTable{
	["kezu_wangguang"] = "族王广",
	["#kezu_wangguang"] = "才性离异",
	["designer:kezu_wangguang"] = "玄蝶既白",
	["cv:kezu_wangguang"] = "官方",
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
	[":kezujianji"] = "限定技，一名角色的回合结束时，若与其相邻的角色于此回合：没有使用过牌，你可以与其各摸一张牌；没有成为过牌的目标，你可以视为使用一张【杀】。",

	["$kezulilun1"] = "",
	["$kezulilun2"] = "",
	["$kezujianji1"] = "",
	["$kezujianji2"] = "",
	--["$kezuzhongliu9"] = "[王广] ",
	--["$kezuzhongliu10"] = "[王广] ",

	["~kezu_wangguang"] = "",

}

table.insert(ol_clans.taiyuan_wang,"wangmingshan")
kezu_wangmingshan = sgs.General(extension, "kezu_wangmingshan", "wei", 4, true, false, false)

kezutanque = sgs.CreateTriggerSkill{
	name = "kezutanque",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getNumber()>0 and use.card:getTypeId()>0 and player:getMark("kezutanque-Clear")<1 then
				local cha = use.card:getNumber() - player:getMark("&kezutanque")
				if cha < 0 then cha = -cha end
				local players = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getHp() == cha and player:getMark("&kezutanque")>0 then
						players:append(p)
					end
				end
				local eny = room:askForPlayerChosen(player, players, self:objectName(), "kezutanque-ask",true,true)
			    if eny then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player,"kezutanque-Clear")
					room:damage(sgs.DamageStruct(self:objectName(), player, eny))
				end
				room:setPlayerMark(player,"&kezutanque",use.card:getNumber())
			end
		end
	end,
}
kezu_wangmingshan:addSkill(kezutanque)

kezushengmoCard = sgs.CreateSkillCard{
	name = "kezushengmoCard",
	will_throw = false,
	filter = function(self,targets,to_select,from)
		local pattern = self:getUserString()
		local use_card = dummyCard(pattern:split("+")[1])
		if use_card:targetFixed() then return false end
		use_card:setSkillName("kezushengmo")
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		return use_card:targetFilter(plist,to_select,from)
	end,
	feasible = function(self,targets,from)
		local pattern = self:getUserString()
		local dc = dummyCard(pattern:split("+")[1])
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		return dc:targetFixed() or dc:targetsFeasible(plist, from)
	end,
	on_validate = function(self,use)
		local room = use.from:getRoom()
		local cards = {}
		for _,id in sgs.list(room:getDiscardPile())do
			if use.from:getMark(id.."shengmoDP-Clear")>0 then
				table.insert(cards,sgs.Sanguosha:getCard(id))
			end
		end
		local cmp = function(a,b)
			return a:getNumber()<b:getNumber()
		end
		table.sort(cards,cmp)
		local theids = sgs.IntList()
		for _,c in sgs.list(cards)do
			if c:getNumber()~=cards[1]:getNumber()
			and c:getNumber()~=cards[#cards]:getNumber()
			then theids:append(c:getEffectiveId()) end
		end
		room:fillAG(theids,use.from)
		local id = room:askForAG(use.from, theids, true, "kezushengmo","kezushengmoask")
		room:clearAG(use.from)
	    if id<0 then return nil end
		room:obtainCard(use.from, id, true)
		local pattern = {}
		for _,pn in sgs.list(self:getUserString():split("+"))do
			if use.from:getMark("kezushengmo_guhuo_remove_"..pn)<1
			then table.insert(pattern,pn) end
		end
		pattern = room:askForChoice(use.from,"kezushengmo",table.concat(pattern,"+"))
		room:addPlayerMark(use.from,"kezushengmo_guhuo_remove_"..pattern)
		local use_card = dummyCard(pattern)
		use_card:setSkillName("_kezushengmo")
		return use_card
	end,
	on_validate_in_response = function(self,from)
		local room = from:getRoom()
		local cards = {}
		for _,id in sgs.list(room:getDiscardPile())do
			if from:getMark(id.."shengmoDP-Clear")>0 then
				table.insert(cards,sgs.Sanguosha:getCard(id))
			end
		end
		local cmp = function(a,b)
			return a:getNumber()<b:getNumber()
		end
		table.sort(cards,cmp)
		local theids = sgs.IntList()
		for _,c in sgs.list(cards)do
			if c:getNumber()~=cards[1]:getNumber()
			and c:getNumber()~=cards[#cards]:getNumber()
			then theids:append(c:getEffectiveId()) end
		end
		room:fillAG(theids,from)
		local id = room:askForAG(from, theids, true, "kezushengmo","kezushengmoask")
		room:clearAG(from)
	    if id<0 then return nil end
		room:obtainCard(from, id, true)
		local pattern = {}
		for _,pn in sgs.list(self:getUserString():split("+"))do
			if from:getMark("kezushengmo_guhuo_remove_"..pn)<1
			then table.insert(pattern,pn) end
		end
		pattern = room:askForChoice(from,"kezushengmo",table.concat(pattern,"+"))
		room:addPlayerMark(from,"kezushengmo_guhuo_remove_"..pattern)
		local use_card = dummyCard(pattern)
		use_card:setSkillName("_kezushengmo")
		return use_card
	end
}
kezushengmoVS = sgs.CreateViewAsSkill{
	name = "kezushengmo",
	--guhuo_type = "l",
	view_as = function(self,cards)
		local new_card = kezushengmoCard:clone()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="" then
			local dc = sgs.Self:getTag("kezushengmo"):toCard()
			if dc==nil then return end
			pattern = dc:objectName()
		end
		new_card:setUserString(pattern)
		return new_card
	end,
	enabled_at_response = function(self,player,pattern)
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		then return false end
		local can = false
		for _,p in sgs.list(pattern:split("+"))do
			local dc = dummyCard(p)
			if dc and dc:getTypeId()==1 and player:getMark("kezushengmo_guhuo_remove_"..p)<1 then
				dc:setSkillName("kezushengmo")
				if not player:isLocked(dc)
				then can = true break end
			end
		end
		if can==false then return false end
		local cards = {}
		for i = 0, sgs.Sanguosha:getCardCount()-1 do
			if player:getMark(i.."shengmoDP-Clear")>0 then
				table.insert(cards,sgs.Sanguosha:getCard(i))
			end
		end
		if #cards<3 then return false end
		local cmp = function(a,b)
			return a:getNumber()<b:getNumber()
		end
		table.sort(cards,cmp)
		for _,c in sgs.list(cards)do
			if c:getNumber()~=cards[1]:getNumber()
			and c:getNumber()~=cards[#cards]:getNumber()
			then return true end
		end
	end,
	enabled_at_play = function(self,player)
		local can = false
		for _,p in sgs.list(patterns())do
			local dc = dummyCard(p)
			if dc and dc:getTypeId()==1 and player:getMark("kezushengmo_guhuo_remove_"..p)<1 then
				dc:setSkillName("kezushengmo")
				if dc:isAvailable(player)
				then can = true break end
			end
		end
		if can==false then return false end
		local cards = {}
		for i = 0, sgs.Sanguosha:getCardCount()-1 do
			if player:getMark(i.."shengmoDP-Clear")>0 then
				table.insert(cards,sgs.Sanguosha:getCard(i))
			end
		end
		if #cards<3 then return false end
		local cmp = function(a,b)
			return a:getNumber()<b:getNumber()
		end
		table.sort(cards,cmp)
		for _,c in sgs.list(cards)do
			if c:getNumber()~=cards[1]:getNumber()
			and c:getNumber()~=cards[#cards]:getNumber()
			then return true end
		end
	end,
}
kezushengmo = sgs.CreateTriggerSkill{
	name = "kezushengmo",
	view_as_skill = kezushengmoVS,
	guhuo_type = "l",
	priority = {0,2},
	events = {sgs.CardsMoveOneTime,sgs.SwappedPile},
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if (move.to_place == sgs.Player_DiscardPile) then
				for _,id in sgs.qlist(move.card_ids) do
					if room:getCardPlace(id)==sgs.Player_DiscardPile then
						room:addPlayerMark(player,id.."shengmoDP-Clear")
					end
				end
			end
			if move.from_places:contains(sgs.Player_DiscardPile) then
				for _,id in sgs.qlist(move.card_ids) do
					room:setPlayerMark(player,id.."shengmoDP-Clear",0)
				end
			end
		else
			for _,m in sgs.list(player:getMarkNames()) do
				if m:endsWith("shengmoDP-Clear") then
					room:setPlayerMark(player,m,0)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self,true)
	end
}
kezu_wangmingshan:addSkill(kezushengmo)

kezu_wangmingshan:addSkill("kezuzhongliu")
sgs.LoadTranslationTable{
	["kezu_wangmingshan"] = "族王明山",
	["#kezu_wangmingshan"] = "擅书多艺",
	["designer:kezu_wangmingshan"] = "玄蝶既白",
	["cv:kezu_wangmingshan"] = "官方",
	["illustrator:kezu_wangmingshan"] = "官方",
	["information:kezu_wangmingshan"] = "宗族：[太原·王氏]",

	["kezutanque"] = "弹雀",
	["kezutanque-ask"] = "你可以发动“弹雀”对一名角色造成1点伤害",
	[":kezutanque"] = "每回合限一次，当你使用有点数的牌结算后，你可以对一名体力值为X的角色造成1点伤害（X为此牌与你上一张使用的牌的点数差且不为0）。",

	["kezushengmo"] = "剩墨",
	[":kezushengmo"] = "你可以获得一张当前回合置入弃牌堆中的点数不是最大且不是最小的牌，视为使用一张本局游戏你未以此法使用过的基本牌。",
	["kezushengmoask"] = "剩墨：你可以获得一张牌",

	["$kezutanque1"] = "",
	["$kezutanque2"] = "",
	["$kezushengmo1"] = "",
	["$kezushengmo2"] = "",
	["$kezuzhongliu11"] = "[王明山] ",
	["$kezuzhongliu12"] = "[王明山] ",

	["~kezu_wangmingshan"] = "",

}

table.insert(ol_clans.taiyuan_wang,"wangchang")
zu_wangchang = sgs.General(extension, "zu_wangchang", "wei", 4)
zukaijiCard = sgs.CreateSkillCard{
	name = "zukaijiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, from)
		return #targets<1 and to_select:getMark("sgszukaijiTo_lun")<1
		and to_select:canDiscard(from,"h")
	end,
	on_use = function(self, room, player, targets)
		for _,p in sgs.list(targets)do
			room:addPlayerMark(p,"sgszukaijiTo_lun")
			if p:canDiscard(player,"h") then
				local id = room:askForCardChosen(p,player,"h",self:getSkillName(),false,sgs.Card_MethodDiscard)
				if id<0 then continue end
				room:throwCard(id,self:getSkillName(),player,p)
				if room:getCardOwner(id) or player:isDead() then continue end
				local c = sgs.Sanguosha:getCard(id)
				if c:isAvailable(player) then
					local ids = sgs.IntList()
					ids:append(id)
					room:notifyMoveToPile(player,ids,"zukaiji")
					if room:askForUseCard(player,"@@zukaiji","zukaiji0:"..c:objectName()) then
						player:drawCards(1,self:getSkillName())
					end
					room:notifyMoveToPile(player,ids,"zukaiji",sgs.Player_DiscardPile,false)
				end
			end
		end
	end
}
zukaiji = sgs.CreateViewAsSkill{
	name = "zukaiji",
	expand_pile = "#zukaiji",
	response_pattern = "@@zukaiji",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern()=="@@zukaiji" then
			return sgs.Self:getPileName(to_select:getEffectiveId())=="#zukaiji"
		end
		return false
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUsePattern()=="@@zukaiji" then
			if #cards<1 then return end
			return cards[1]
		end
		return zukaijiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#zukaijiCard")<1
		and player:getHandcardNum()>0
	end, 
}
zu_wangchang:addSkill(zukaiji)
zu_wangchang:addSkill("kezuzhongliu")

sgs.LoadTranslationTable{
	["zu_wangchang"] = "族王昶",
	["#zu_wangchang"] = "治论识度",
	--["designer:zu_wangchang"] = "玄蝶既白",
	--["cv:zu_wangchang"] = "官方",
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

table.insert(ol_clans.taiyuan_wang,"wangshen")
zu_wangshen = sgs.General(extension, "zu_wangshen", "wei", 3)

zuanran = sgs.CreateTriggerSkill{
	name = "zuanran",
	events = {sgs.EventPhaseStart,sgs.Damaged,sgs.PreCardUsed},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase()~=sgs.Player_Play then return end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				for _,p in sgs.list(room:getAlivePlayers())do
					room:setPlayerMark(p,"sgszuanranTo-Clear",0)
				end
			end
			return
		end
		if player:hasSkill(self) and player:askForSkillInvoke(self,data) then
			player:peiyin(self)
			room:addPlayerMark(player,"&zuanran+#num")
			local n = math.min(4,player:getMark("&zuanran+#num"))
			local tos = room:askForPlayersChosen(player,room:getAlivePlayers(),self:objectName(),0,n,"zuanran0:"..n)
			if tos:isEmpty() then
				room:addPlayerMark(player,"sgszuanranTo-Clear")
				for _,id in sgs.list(player:drawCardsList(n,self:objectName()))do
					room:addPlayerMark(player,id.."sgszuanranId-Clear")
				end
			else
				for _,p in sgs.list(tos)do
					room:addPlayerMark(p,"sgszuanranTo-Clear")
					room:doAnimate(1,player:objectName(),p:objectName())
					for _,id in sgs.list(p:drawCardsList(1,self:objectName()))do
						room:addPlayerMark(p,id.."sgszuanranId-Clear")
					end
				end
			end
		end
	end,
}
zu_wangshen:addSkill(zuanran)
zuanranbf = sgs.CreateCardLimitSkill{
	name = "#zuanranbf" ,
	limit_list = function(self,player)
		return "use"
	end,
	limit_pattern = function(self,player,card)
		if player:getMark("sgszuanranTo-Clear")>0
		and player:getMark(card:toString().."sgszuanranId-Clear")>0
		then return card:toString() end
	end
}
zu_wangshen:addSkill(zuanranbf)

zugaobianvs = sgs.CreateViewAsSkill{
	name = "zugaobian",
	expand_pile = "#zugaobian",
	response_pattern = "@@zugaobian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return sgs.Self:getPileName(to_select:getEffectiveId())=="#zugaobian"
		and to_select:isAvailable(sgs.Self)
	end,
	view_as = function(self, cards)
		if #cards<1 then return end
		return cards[1]
	end,
	enabled_at_play = function(self, player)
		return false
	end, 
}
zugaobian = sgs.CreateTriggerSkill{
	name = "zugaobian",
	view_as_skill = zugaobianvs,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging,sgs.CardsMoveOneTime,sgs.DamageDone},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				local dps = room:getTag("zugaobianDamage"):toString():split("+")
				if #dps~=1 then return end
				for _,p in sgs.list(room:getAlivePlayers())do
					if p:objectName()==dps[1] then
						for _,q in sgs.list(room:findPlayersBySkillName(self:objectName()))do
							if q==player then continue end
							room:sendCompulsoryTriggerLog(q,self)
							local ids = sgs.IntList()
							for _,id in sgs.qlist(room:getDiscardPile()) do
								if p:getMark(id.."zugaobianId-Clear")>0 and sgs.Sanguosha:getCard(id):isKindOf("Slash") then
									ids:append(id)
								end
							end
							if ids:length()>0 then
								room:notifyMoveToPile(p,ids,"zugaobian")
								if room:askForUseCard(p,"@@zugaobian","zugaobian0") then continue end
							end
							room:loseHp(p,1,true,q,self:objectName())
						end
					end
				end
			elseif (change.from == sgs.Player_NotActive) then
				room:removeTag("zugaobianDamage")
			end
		elseif (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if (move.to_place == sgs.Player_DiscardPile) then
				for _,id in sgs.qlist(move.card_ids) do
					player:addMark(id.."zugaobianId-Clear")
				end
			end
		else
			local dps = room:getTag("zugaobianDamage"):toString():split("+")
			if table.contains(dps,player:objectName()) then return end
			table.insert(dps,player:objectName())
			room:setTag("zugaobianDamage",ToData(table.concat(dps,"+")))
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
zu_wangshen:addSkill(zugaobian)
zu_wangshen:addSkill("kezuzhongliu")

sgs.LoadTranslationTable{
	["zu_wangshen"] = "族王沈",
	["#zu_wangshen"] = "崇虎田光",
	--["designer:zu_wangshen"] = "玄蝶既白",
	--["cv:zu_wangshen"] = "官方",
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
ol_clans.hongnong_yang = {"yangzhen","yangbiao","yangci","yangzhi","yangyan"}
zu_yangci = sgs.General(extension,"zu_yangci","qun",3)
zuqieyi = sgs.CreateTriggerSkill{
	name = "zuqieyi",
	events = {sgs.EventPhaseStart,sgs.CardFinished},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventPhaseStart then
			if player:getPhase()~=sgs.Player_Play then return end
			if player:askForSkillInvoke(self,data) then
				player:peiyin(self)
				local ids = room:getNCards(2)
				room:fillAG(ids,player)
				room:askForAG(player,ids,true,self:objectName())
				room:clearAG(player)
				player:addMark("zuqieyi-Clear")
				room:returnToTopDrawPile(ids)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and player:getMark("zuqieyi-Clear")>0 then
				player:addMark(use.card:getSuitString().."zuqieyiSuit-Clear")
				if player:getMark(use.card:getSuitString().."zuqieyiSuit-Clear")==1 then
					player:addMark("zuqieyi-Clear")
					local ids = room:showDrawPile(player,1,self:objectName(),false)
					local c = sgs.Sanguosha:getCard(ids:first())
					if c:getColor()==use.card:getColor() or c:getType()==use.card:getType() then
						player:obtainCard(c)
					else
						c = room:askForExchange(player,self:objectName(),1,1,true,"zuqieyi0")
						if c then
							room:moveCardTo(c,nil,sgs.Player_DrawPile,false)
						end
					end
				end
			end
		end
	end,
}
zu_yangci:addSkill(zuqieyi)
zujianzhi = sgs.CreateTriggerSkill{
	name = "zujianzhi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart,sgs.CardUsed},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()~=sgs.Player_Finish then return end
			local n = player:getMark("zuqieyi-Clear")
			if n>0 and player:hasSkill(self) then
				room:sendCompulsoryTriggerLog(player,self)
				local choices = {}
				for i=1,n do
					table.insert(choices,i)
				end
				local x = room:askForChoice(player,self:objectName(),table.concat(choices,"+"),data)
				choices = {}
				for _,m in sgs.list(player:getMarkNames())do
					if m:contains("_zujianzhiSuit-Clear") and player:getMark(m)>0 then
						local ms = m:split("_")
						table.insert(choices,ms[1])
					end
				end
				local ids = sgs.IntList()
				for i=1,tonumber(x) do
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|"..table.concat(choices,",")
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					room:judge(judge)
					if judge:isGood() then
						if room:getCardOwner(judge.card:getEffectiveId())==nil
						then ids:append(judge.card:getEffectiveId()) end
					else
						n = -1
					end
					if player:isDead() then return false end
				end
				if n<0 then
					room:damage(sgs.DamageStruct(self:objectName(),nil,player,1,sgs.DamageStruct_Thunder))
				end
				if player:isAlive() then
					player:assignmentCards(ids,"zujianzhi|zujianzhi0",room:getAlivePlayers(),ids:length(),ids:length())
				end
			end
		elseif (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				player:addMark(use.card:getSuitString().."_zujianzhiSuit-Clear")
			end
		end
	end,
}
zu_yangci:addSkill(zujianzhi)
zuquhuo = sgs.CreateTriggerSkill{
	name = "zuquhuo",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data,room)
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceHand)
			and move.from:objectName()==player:objectName() and player:getMark("zuquhuo-Clear")<1 then
				if move.reason.m_reason==sgs.CardMoveReason_S_REASON_USE or move.reason.m_reason==sgs.CardMoveReason_S_REASON_RESPONSE
				or bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD
				then return false end
				for i,id in sgs.qlist(move.card_ids) do
					if move.from_places:at(i)==sgs.Player_PlaceHand then
						local c = sgs.Sanguosha:getCard(id)
						if c:isKindOf("Analeptic") or c:isKindOf("EquipCard") then
							player:addMark("zuquhuo-Clear")
							local tps = sgs.SPlayerList()
							for _,p in sgs.list(room:getAlivePlayers())do
								if p:isWounded() and isSameClan(player,p)
								then tps:append(p) end
							end
							local tp = room:askForPlayerChosen(player,tps,self:objectName(),"zuquhuo0",true,true)
							if tp then
								local n = math.random(1,2)
								if player:getGeneralName():endsWith("yangxiu")
								or player:getGeneral2Name():endsWith("yangxiu")
								then n = n+2 end
								player:peiyin(self,n)
								room:recover(tp,sgs.RecoverStruct(self:objectName(),player))
							end
						end
					end
				end
			end
		end
	end,
}
zu_yangci:addSkill(zuquhuo)

sgs.LoadTranslationTable{
	["zu_yangci"] = "族杨赐",
	["#zu_yangci"] = "固世笃忠贞",
	--["designer:zu_yangci"] = "玄蝶既白",
	--["cv:zu_yangci"] = "官方",
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

table.insert(ol_clans.hongnong_yang,"yangxiu")
zu_yangxiu = sgs.General(extension,"zu_yangxiu","wei",3)
zujiewu = sgs.CreateTriggerSkill{
	name = "zujiewu",
	events = {sgs.EventPhaseStart,sgs.TargetSpecified},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventPhaseStart then
			if player:getPhase()~=sgs.Player_Play then return end
			local tp = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"zujiewu0",true,true)
			if tp then
				player:peiyin(self)
				player:addMark("zujiewuUse-Clear")
				room:setPlayerMark(tp,"&zujiewu+#"..player:objectName().."-PlayClear",1)
				room:setPlayerMark(player,"HandcardVisible_"..tp:objectName().."-PlayClear",1)
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:getTypeId()<1 or player:getMark("zujiewuUse-Clear")<1 then return end
			for _,p in sgs.list(use.to)do
				if p==player then continue end
				for _,p in sgs.list(room:getAllPlayers())do
					if p:getMark("&zujiewu+#"..player:objectName().."-PlayClear")>0
					and p:getHandcardNum()>0 and player:askForSkillInvoke(self,data) then
						player:peiyin(self)
						local id = room:askForCardChosen(player,p,"h",self:objectName())
						player:addMark("zujiewuUse-Clear")
						if id<0 then break end
						room:showCard(p,id)
						local c = sgs.Sanguosha:getCard(id)
						if c:getSuit()==use.card:getSuit() then
							player:drawCards(1,self:objectName())
						end
						if c:hasTip("zujiewu") then
							c = nil
							if player:getHandcardNum()>=p:getHandcardNum() then
								local prompt = "zujiewu1:"..p:objectName()
								if player:getHandcardNum()>p:getHandcardNum() then prompt = "zujiewu2" end
								c = room:askForExchange(player,self:objectName(),1,1,true,prompt,prompt~="zujiewu2")
							end
							if c==nil then
								local id2 = room:askForCardChosen(player,p,"h",self:objectName())
								c = sgs.Sanguosha:getCard(id2)
							end
							if c then
								room:moveCardTo(c,nil,sgs.Player_DrawPile,false)
							end
						end
						room:setCardTip(id,"zujiewu-Clear")
						break
					end
				end
				break
			end
		end
	end,
}
zu_yangxiu:addSkill(zujiewu)
zugaoshivs = sgs.CreateViewAsSkill{
	name = "zugaoshi",
	expand_pile = "#zugaoshi",
	response_pattern = "@@zugaoshi",
	n = 1,
	view_filter = function(self,selected,to_select)
		return sgs.Self:getPileName(to_select:getEffectiveId())=="#zugaoshi"
		and to_select:isAvailable(sgs.Self)
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		return cards[1]
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
zugaoshi = sgs.CreateTriggerSkill{
	name = "zugaoshi",
	view_as_skill = zugaoshivs,
	events = {sgs.EventPhaseStart,sgs.CardUsed},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()~=sgs.Player_Finish then return end
			local n = player:getMark("zujiewuUse-Clear")
			if n>0 and player:hasSkill(self) and player:askForSkillInvoke(self,data) then
				player:peiyin(self)
				local ids = sgs.IntList()
				for i=1,n do
					local id = room:showDrawPile(player,1,self:objectName()):first()
					ids:append(id)
					if player:getMark(sgs.Sanguosha:getCard(id):objectName().."zugaoshiName-Clear")>0
					or player:isDead() then break end
					room:getThread():delay()
				end
				while ids:length()>0 and player:isAlive() do
					room:notifyMoveToPile(player,ids,"zugaoshi")
					local c = room:askForUseCard(player,"@@zugaoshi","zugaoshi0")
					if c then ids:removeOne(c:getEffectiveId()) else break end
				end
				if ids:isEmpty() then
					player:drawCards(2,self:objectName())
				end
				for _,id in sgs.list(ids)do
					if room:getCardPlace(id)==sgs.Player_PlaceTable then
						room:throwCard(id,self:objectName(),nil)
					end
				end
			end
		elseif (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				player:addMark(use.card:objectName().."zugaoshiName-Clear")
			end
		end
	end,
}
zu_yangxiu:addSkill(zugaoshi)
zu_yangxiu:addSkill("zuquhuo")

sgs.LoadTranslationTable{
	["zu_yangxiu"] = "族杨修",
	["#zu_yangxiu"] = "皓首邀终始",
	--["designer:zu_yangxiu"] = "玄蝶既白",
	--["cv:zu_yangxiu"] = "官方",
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

table.insert(ol_clans.hongnong_yang,"yangzhong")
zu_yangzhong = sgs.General(extension,"zu_yangzhong","qun",4)
zujuetuCard = sgs.CreateSkillCard{
	name = "zujuetuCard",
	target_fixed = true,
	will_throw = false,
    about_to_use = function(self,room,use)
	end,
}
zujuetuvs = sgs.CreateViewAsSkill{
	name = "zujuetu",
	n = 4,
	view_filter = function(self,selected,to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern()=="@@zujuetu!" then
			for _,c in sgs.list(selected)do
				if c:getSuit()==to_select:getSuit()
				then return false end
			end
			return not to_select:isEquipped()
		end
	end,
	view_as = function(self,cards)
		if sgs.Sanguosha:getCurrentCardUsePattern()=="@@zujuetu!" then
			if #cards<1 then return end
			for _,h in sgs.list(sgs.Self:getHandcards())do
				local has = false
				for _,c in sgs.list(cards)do
					if c:getSuit()==h:getSuit()
					then has = true end
				end
				if has==false then return end
			end
			local sc = zujuetuCard:clone()
			for _,c in sgs.list(cards)do
				sc:addSubcard(c)
			end
			return sc
		end
		local dc = sgs.Sanguosha:cloneCard("dismantlement")
		dc:addSubcard(sgs.Self:getMark("zujuetuId"))
		dc:setSkillName("_zujuetu")
		return dc
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern:contains("@@zujuetu")
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
zujuetu = sgs.CreateTriggerSkill{
	name = "zujuetu",
	view_as_skill = zujuetuvs,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()~=sgs.Player_Discard or player:isKongcheng() then return end
			room:sendCompulsoryTriggerLog(player,self)
			local sc = room:askForUseCard(player,"@@zujuetu!","zujuetu0")
			if sc==nil then
				sc = zujuetuCard:clone()
				local suits = sgs.IntList()
				for _,h in sgs.list(player:getHandcards())do
					if suits:contains(h:getSuit()) then continue end
					suits:append(h:getSuit())
					sc:addSubcard(h)
				end
			end
			local dc = dummyCard()
			for _,id in sgs.list(player:handCards())do
				if sc:getSubcards():contains(id) then continue end
				dc:addSubcard(id)
			end
			room:throwCard(dc,self:objectName(),player)
			local tps = sgs.SPlayerList()
			for _,p in sgs.list(room:getAlivePlayers())do
				if p:getHandcardNum()>0 then tps:append(p) end
			end
			local tp = room:askForPlayerChosen(player,tps,self:objectName(),"zujuetu1")
			if tp then
				room:doAnimate(1,player:objectName(),tp:objectName())
				dc = room:askForCardShow(tp,player,self:objectName())
				room:showCard(tp,dc:getEffectiveId())
				for _,h in sgs.list(player:getHandcards())do
					if h:getSuit()==dc:getSuit() then sc = false end
				end
				if sc then
					room:damage(sgs.DamageStruct(self:objectName(),player,tp))
				else
					sc = dummyCard("dismantlement","zujuetu")
					sc:addSubcard(dc)
					if sc:isAvailable(player) then
						room:setPlayerMark(player,"zujuetuId",dc:getEffectiveId())
						room:askForUseCard(player,"@@zujuetu1!","zujuetu2")
					end
				end
			end
		end
	end,
}
zu_yangzhong:addSkill(zujuetu)
zukuduCard = sgs.CreateSkillCard{
	name = "zukuduCard",
	will_throw = false,
	handling_method = sgs.Card_MethodRecast,
	filter = function(self,targets,to_select,from)
		return #targets<1
	end,
	on_use = function(self,room,player,targets)
		room:removePlayerMark(player,"@zukudu")
		room:doSuperLightbox(player,"zukudu")
		UseCardRecast(player,self,self:getSkillName(),self:subcardsLength())
		local n = sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber()-sgs.Sanguosha:getCard(self:getSubcards():last()):getNumber()
		n = math.min(5,math.abs(n))
		for _,tp in ipairs(targets) do
			room:setPlayerMark(tp,"&zukudu",n)
		end
	end,
}
zukuduvs = sgs.CreateViewAsSkill{
	name = "zukudu",
	n = 2,
	view_filter = function(self,selected,to_select)
		return not sgs.Self:isCardLimited(to_select,sgs.Card_MethodRecast)
	end,
	view_as = function(self,cards)
		if #cards > 1 then
			local card = zukuduCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@zukudu")>0 and player:getCardCount()>0
	end, 
}
zukudu = sgs.CreateTriggerSkill{
	name = "zukudu",
	view_as_skill = zukuduvs,
	frequency = sgs.Skill_Limited,
	limit_mark = "@zukudu",
	events = {sgs.EventPhaseChanging,sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				if player:getMark("&zukudu")>0 then
					room:removePlayerMark(player,"&zukudu")
					player:drawCards(1,self:objectName())
					if player:getMark("&zukudu")<1 then
						player:addMark("zukuduBf")
					end
				end
			end
		elseif player:getPhase()==sgs.Player_NotActive and player:getMark("zukuduBf")>0 then
			player:removeMark("zukuduBf")
			player:gainAnExtraTurn()
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
zu_yangzhong:addSkill(zukudu)
zu_yangzhong:addSkill("zuquhuo")

sgs.LoadTranslationTable{
	["zu_yangzhong"] = "族杨众",
	["#zu_yangzhong"] = "同舟而济",
	--["designer:zu_yangzhong"] = "玄蝶既白",
	--["cv:zu_yangzhong"] = "官方",
	--["illustrator:zu_yangzhong"] = "官方",
	["information:zu_yangzhong"] = "宗族：[弘农·杨氏]",

	["zujuetu"] = "绝途",
	[":zujuetu"] = "锁定技，弃牌阶段开始时，你选择手牌中每种花色的牌各一张，将其余的手牌置入弃牌堆，然后令一名角色展示一张手牌。若你手牌中没有此花色的牌，则你对其造成1点伤害，否则你将此牌当【过河拆桥】使用。",
	["zukudu"] = "苦渡",
	[":zukudu"] = "限定技，出牌阶段，你可以重铸两张牌，令一名角色于其回合结束时摸一张牌直到其以此法获得了X张牌（X为你重铸的牌的点数之差且至多为5），然后其于最后一个以此法获得牌的回合结束后执行一个额外的回合。",
	["zujuetu0"] = "绝途：请选择保留的各花色牌",
	["zujuetu1"] = "绝途：请选择令一名角色展示牌",
	["zujuetu2"] = "绝途：请选择【过河拆桥】使用目标",


}

zu_yangbiao = sgs.General(extension,"zu_yangbiao","qun",3)
zujiannan = sgs.CreateTriggerSkill{
	name = "zujiannan",
	events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()~=sgs.Player_Play then return end
			if player:askForSkillInvoke(self,data) then
				player:peiyin(self)
				player:addMark("zujiannanBf-PlayClear")
				for i,id in sgs.qlist(player:drawCardsList(2,self:objectName()))do
					if player:handCards():contains(id) then
						room:setCardTip(id,"zujiannan-PlayClear")
						room:setCardFlag(id,"zujiannanBf")
					end
				end
				player:addMark("zujiannanUse-Clear")
			end
		else
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceHand)
			and player:getMark("zujiannanBf-PlayClear")>0 then
				local has = move.is_last_handcard
				for _,p in sgs.qlist(room:getAlivePlayers())do
					if p:hasFlag("Global_Dying") then return end
				end
				for i,id in sgs.qlist(move.card_ids)do
					if has then break end
					if sgs.Sanguosha:getCard(id):hasFlag("zujiannanBf") then
						for _,h in sgs.qlist(move.from:getHandcards())do
							if h:hasFlag("zujiannanBf") then has = false end
						end
						break
					end
				end
				if has then
					local choices = {}
					for _,t in ipairs({"zujiannan1","zujiannan2","zujiannan3","zujiannan4"}) do
						if player:getMark(t.."-Clear")<1 then table.insert(choices,t) end
					end
					if #choices<1 then return end
					room:sendCompulsoryTriggerLog(player,self:objectName())
					has = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"zujiannan0")
					room:doAnimate(1,player:objectName(),has:objectName())
					local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"),ToData(has))
					player:addMark(choice.."-Clear")
					if choice=="zujiannan1" then
						room:askForDiscard(has,self:objectName(),2,2,false,true)
					elseif choice=="zujiannan2" then
						has:drawCards(2,self:objectName())
					elseif choice=="zujiannan3" then
						local dc = dummyCard()
						for _,h in sgs.qlist(has:getCards("he"))do
							if h:isKindOf("EquipCard") then dc:addSubcard(h) end
						end
						UseCardRecast(has,dc,self:objectName())
					elseif choice=="zujiannan4" then
						local sc = room:askForCard(has,"TrickCard","zujiannan4",ToData(player),sgs.Card_MethodNone)
						if sc then room:moveCardTo(sc,nil,sgs.Player_DrawPile,true)
						else room:loseHp(has,1,true,player,self:objectName()) end
					end
					player:addMark("zujiannanUse-Clear")
				end
			end
		end
	end,
}
zu_yangbiao:addSkill(zujiannan)
zuyichi = sgs.CreateTriggerSkill{
	name = "zuyichi",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()~=sgs.Player_Finish or player:getMark("zujiannanUse-Clear")<1 then return end
			local tps = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers())do
				if player:canPindian(p) then tps:append(p) end
			end
			local tp = room:askForPlayerChosen(player,tps,self:objectName(),"zuyichi0",true,true)
			if tp then
				player:peiyin(self)
				if player:pindian(tp,self:objectName()) then
					for i=1,math.min(4,player:getMark("zujiannanUse-Clear")) do
						if i==1 then
							room:askForDiscard(tp,self:objectName(),2,2,false,true)
						elseif i==2 then
							tp:drawCards(2,self:objectName())
						elseif i==3 then
							local dc = dummyCard()
							for _,h in sgs.qlist(tp:getCards("he"))do
								if h:isKindOf("EquipCard") then dc:addSubcard(h) end
							end
							UseCardRecast(tp,dc,self:objectName())
						elseif i==4 then
							local sc = room:askForCard(tp,"TrickCard","zujiannan4",ToData(player),sgs.Card_MethodNone)
							if sc then room:moveCardTo(sc,nil,sgs.Player_DrawPile,true)
							else room:loseHp(tp,1,true,player,self:objectName()) end
						end
					end
				end
			end
		end
	end,
}
zu_yangbiao:addSkill(zuyichi)
zu_yangbiao:addSkill("zuquhuo")

sgs.LoadTranslationTable{
	["zu_yangbiao"] = "族杨彪",
	["#zu_yangbiao"] = "负荷履崎岖",
	--["designer:zu_yangbiao"] = "玄蝶既白",
	--["cv:zu_yangbiao"] = "官方",
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







zuhuntianyiTr = sgs.CreateTriggerSkill{
	name = "_zuhuntianyi",
	events = {sgs.DamageInflicted},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self,target)
		return target and target:hasTreasure("_zuhuntianyi")
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.DamageInflicted then
		    local damage = data:toDamage()
			local tc = player:getTreasure()
			if tc and tc:isKindOf("Huntianyi") then
            room:sendCompulsoryTriggerLog(player,"_zuhuntianyi")
				room:breakCard(tc,player)
			return player:damageRevises(data,-damage.damage)
		end
		end
		return false
	end,
}
zuhuntianyi = sgs.CreateTreasure{
	name = "_zuhuntianyi",
	class_name = "Huntianyi",
	target_fixed = true,
	equip_skill = zuhuntianyiTr,
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,zuhuntianyiTr,true,true,false)
		return false
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		if player:isAlive() then
			room:sendCompulsoryTriggerLog(player,"_zuhuntianyi")
			local ids = InsertList({},room:getDrawPile())
			local dc = dummyCard()
			for _,id in sgs.list(RandomList(ids))do
				local c = sgs.Sanguosha:getCard(id)
				if c:getNumber()==self:getNumber() and c:isKindOf("TrickCard") then
					dc:addSubcard(id)
					if dc:subcardsLength()>1 then break end
				end
			end
			player:obtainCard(dc)
		end
		room:detachSkillFromPlayer(player,"_zuhuntianyi",true,true)
		return false
	end,
}
zuhuntianyi:clone(3,1):setParent(extension)
zuhuntianyi:clone(3,3):setParent(extension)
zuhuntianyi:clone(3,10):setParent(extension)
zuhuntianyi:clone(3,12):setParent(extension)

--吴郡陆氏
ol_clans.wujun_lu = {"luxun","lumao","luji","luyusheng","lukai"}
zu_luji = sgs.General(extension,"zu_luji","wu",3)
zugailan = sgs.CreateTriggerSkill{
	name = "zugailan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart,sgs.GameStart},
	waked_skills = "_zuhuntianyi",
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()~=sgs.Player_RoundStart then return end
			room:sendCompulsoryTriggerLog(player,self)
			local tps = sgs.SPlayerList()
			tps:append(player)
			for _,id in sgs.qlist(room:getDrawPile())do
				local c = sgs.Sanguosha:getCard(id)
				if c:objectName()=="_zuhuntianyi" then
					room:moveCardTo(c,player,sgs.Player_PlaceTable,true)
					c:use(room,player,tps)
					return
				end
			end
			for _,id in sgs.qlist(room:getDiscardPile())do
				local c = sgs.Sanguosha:getCard(id)
				if c:objectName()=="_zuhuntianyi" then
					room:moveCardTo(c,player,sgs.Player_PlaceTable,true)
					c:use(room,player,tps)
					return
				end
			end
		else
			local ids = sgs.IntList()
			room:sendCompulsoryTriggerLog(player,self)
			for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true))do
				if room:getCardOwner(id)==nil and sgs.Sanguosha:getCard(id):objectName()=="_zuhuntianyi"
				then ids:append(id) end
			end
			room:shuffleIntoDrawPile(player,ids,self:objectName(),true)
		end
	end,
}
zu_luji:addSkill(zugailan)
zufennu = sgs.CreateTriggerSkill{
	name = "zufennu",
	events = {sgs.EventPhaseStart,sgs.TargetSpecifying},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) then
			if player:getPhase()==sgs.Player_Play and player:getHp()>0 then
				local tps = room:askForPlayersChosen(player,room:getAlivePlayers(),self:objectName(),0,player:getHp(),"zufennu0:"..player:getHp(),true,true)
				if tps:length()>0 then
					player:peiyin(self)
					for _,p in sgs.qlist(tps)do
						local dc = room:askForDiscard(p,self:objectName(),1,1,false,true)
						if dc==nil or room:getCardOwner(dc:getEffectiveId()) then continue end
						player:addToPile("zufennu_yi",dc)
					end
				end
			elseif player:getPhase()==sgs.Player_Start then
				local ids = player:getPile("zufennu_yi")
				if ids:isEmpty() then return end
				local n = 0
				for _,id in sgs.qlist(ids)do
					n = n+sgs.Sanguosha:getCard(id):getNumber()
				end
				if player:getMark("&zufennu")>n then
					room:setPlayerMark(player,"&zufennu",0)
					n = dummyCard()
					n:addSubcards(ids)
					player:obtainCard(n)
				end
			end
		else
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and player:getPile("zufennu_yi"):length()>0 then
				room:addPlayerMark(player,"&zufennu",use.card:getNumber())
			end
		end
	end,
}
zu_luji:addSkill(zufennu)
zuzelie = sgs.CreateTriggerSkill{
	name = "zuzelie",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD then
				if move.from and move.from:getMark("&zuzelie2Bf-Clear")>0 then
					local from = BeMan(room,move.from)
					room:setPlayerMark(from,"&zuzelie2Bf-Clear",1)
					room:askForDiscard(from,self:objectName(),1,1,false,true)
				end
			elseif move.reason.m_reason==sgs.CardMoveReason_S_REASON_DRAW then
				if move.from and move.from:getMark("&zuzelie1Bf-Clear")>0 then
					local from = BeMan(room,move.from)
					room:setPlayerMark(from,"&zuzelie1Bf-Clear",1)
					from:drawCards(1,self:objectName())
				end
			end
			if move.from_places:contains(sgs.Player_PlaceEquip)
			or move.from_places:contains(sgs.Player_PlaceDelayedTrick) then
				if move.from:getCards("ej"):isEmpty() and isSameClan(player,move.from) then
					local tp = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"zuzelie0",true,true)
					if tp then
						if room:askForChoice(player,self:objectName(),"zuzelie1+zuzelie2",data)=="zuzelie1" then
							room:setPlayerMark(tp,"&zuzelie1Bf-Clear",1)
						else
							room:setPlayerMark(tp,"&zuzelie2Bf-Clear",1)
						end
					end
				end
			end
		end
	end,
}
zu_luji:addSkill(zuzelie)

sgs.LoadTranslationTable{
	["zu_luji"] = "族陆绩",
	["#zu_luji"] = "浑天玄意",
	--["designer:zu_luji"] = "玄蝶既白",
	--["cv:zu_luji"] = "官方",
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

	["_zuhuntianyi"] = "浑天仪",
	[":_zuhuntianyi"] = "装备牌/宝物<br/><b>宝物技能</b>：锁定技，当你从装备区失去【浑天仪】时，从牌堆获得两张与此牌点数相同的锦囊牌；当你受到伤害时，你销毁此牌并防止此伤害。",

}

table.insert(ol_clans.wujun_lu,"lujing")
zu_lujing = sgs.General(extension,"zu_lujing","wu",4)
zutanfengCard = sgs.CreateSkillCard{
	name = "zutanfengCard",
	filter = function(self,targets,to_select,from)
		return #targets<1 and from:canSlash(to_select)
	end,
	will_throw = false,
    about_to_use = function(self,room,use)
		use.card = dummyCard(nil,"zutanfeng")
		room:setCardFlag(use.card,"SlashIgnoreArmor")
		use.card:cardOnUse(room,use)
	end,
}
zutanfengvs = sgs.CreateViewAsSkill{
	name = "zutanfeng",
	view_as = function(self,cards)
		return zutanfengCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#zutanfengCard")
		and dummyCard():isAvailable(player)
	end,
}
zutanfeng = sgs.CreateTriggerSkill{
	name = "zutanfeng",
	view_as_skill = zutanfengvs,
	events = {sgs.CardFinished},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and table.contains(use.card:getSkillNames(),self:objectName()) then
				if use.card:hasFlag("DamageDone") then
					local n = math.abs(player:getEquips():length()-use.to:first():getEquips():length())
					player:drawCards(n,self:objectName())
				else
					local dc = dummyCard(nil,"_zutanfeng")
					if use.to:first():isAlive() and use.to:first():canSlash(player,dc,false)
					and use.to:first():askForSkillInvoke(self,player,false) then
						room:useCard(sgs.CardUseStruct(dc,use.to:first(),player))
					end
				end
			end
		end
	end,
}
zu_lujing:addSkill(zutanfeng)
zujuewei = sgs.CreateTriggerSkill{
	name = "zujuewei",
	events = {sgs.CardFinished,sgs.TargetSpecified,sgs.TargetConfirmed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:hasFlag("zujuewei1Bf"..player:objectName()) then
				room:setCardFlag(use.card,"-zujuewei1Bf"..player:objectName())
				if room:getCardOwner(use.card:getEffectiveId()) then return end
				local tps = sgs.SPlayerList()
				for _,t in sgs.qlist(use.to)do
					if t==player or t:isDead()
					or player:isProhibited(t,use.card)
					then continue end
					tps:append(t)
				end
				local tp = room:askForPlayerChosen(player,tps,self:objectName(),"zujuewei3:"..use.card:objectName())
				if tp then
					room:useCard(sgs.CardUseStruct(use.card,player,tp))
				end
			end
			for _,p in sgs.qlist(use.to)do
				if room:getCardOwner(use.card:getEffectiveId()) then break end
				if use.card:hasFlag("zujuewei1Bf"..p:objectName()) then
					room:setCardFlag(use.card,"-zujuewei1Bf"..p:objectName())
					local tps = sgs.SPlayerList()
					for _,t in sgs.qlist(use.to)do
						if t==p or t:isDead()
						or p:isProhibited(t,use.card)
						then continue end
						tps:append(t)
					end
					local tp = room:askForPlayerChosen(p,tps,self:objectName(),"zujuewei3:"..use.card:objectName())
					if tp then
						room:useCard(sgs.CardUseStruct(use.card,p,tp))
					end
				end
			end
		else
			local use = data:toCardUse()
			if event==sgs.TargetConfirmed and not use.to:contains(player) then return end
			if use.card:isDamageCard() and player:getCardCount()>0
			and player:getMark("zujueweiUse-Clear")<1 and player:hasSkill(self) then
				local sc = room:askForCard(player,"EquipCard","zujuewei0",data,sgs.Card_MethodNone)
				if sc then
					local choices = {}
					if not player:isCardLimited(sc,sgs.Card_MethodRecast())
					then table.insert(choices,"zujuewei1") end
					if player:canDiscard(player,sc:getEffectiveId())
					then table.insert(choices,"zujuewei2") end
					if #choices<1 then return end
					player:skillInvoked(self,-1)
					player:addMark("zujueweiUse-Clear")
					if room:askForChoice(player,self:objectName(),table.concat(choices,"+"),data)=="zujuewei1" then
						UseCardRecast(player,sc,self:objectName())
						room:setCardFlag(use.card,"zujuewei1Bf"..player:objectName())
					else
						room:throwCard(sc,self:objectName(),player)
						local nullified_list = use.nullified_list
						table.insert(nullified_list,"_ALL_TARGETS")
						use.nullified_list = nullified_list
						data:setValue(use)
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
zu_lujing:addSkill(zujuewei)
zu_lujing:addSkill("zuzelie")

sgs.LoadTranslationTable{
	["zu_lujing"] = "族陆景",
	["#zu_lujing"] = "毗陵侯",
	--["designer:zu_lujing"] = "玄蝶既白",
	--["cv:zu_lujing"] = "官方",
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




return {extension}