--《太阳神三国杀·天才包》2024龙年新春专属：🐲《龙行天下》武将扩展包
extension = sgs.Package("Loong", sgs.Package_GeneralPack)
---------------------------------
sgs.LoadTranslationTable{
    ["Loong"] = "🐲龙行天下",
}
---------------------------------
local skills = sgs.SkillList()
---------------------------------
--/内容一览/
--[[
{门面}单尽瘁武诸葛亮
【魏】曹休、曹彰、崔琰＆毛玠
【蜀】刘备(+专武“飞龙夺凤”)、关羽＆张飞、赵统＆赵广
【吴】庞统、孙皓
【群】高顺、马超、张鲁
<双势力> 许攸(群+魏)
《神》神-周瑜＆诸葛亮
]]
--===================--
---------------------------------
--单尽瘁武诸葛亮
lxtx_jincui_wuzhugeliang = sgs.General(extension, "lxtx_jincui_wuzhugeliang", "shu", 7, true, false, false, 4)

lxtx_jincui_wuzhugeliang:addSkill("myjincui")

sgs.LoadTranslationTable{
	["lxtx_jincui_wuzhugeliang"] = "单尽瘁武诸葛亮",
	["&lxtx_jincui_wuzhugeliang"] = "尽武诸葛亮",
	["#lxtx_jincui_wuzhugeliang"] = "龙行天下",
	["designer:lxtx_jincui_wuzhugeliang"] = "三国杀单挑组", --然后拿出来依旧拿捏大鬼
	["cv:lxtx_jincui_wuzhugeliang"] = "官方",
	["illustrator:lxtx_jincui_wuzhugeliang"] = "梦回唐朝",
	["information:lxtx_jincui_wuzhugeliang"] = "“昔云南僻在万里，山川险固，历代罕有能平，惟诸葛孔明以天下奇才、忠信智谋，南征北伐，功盖一时，遂艾夷之。" ..
	"循至后世，叛服不常，莫能制驭。” ——[明]成祖文皇帝·朱棣", --本应是明太宗文皇帝
    ["~lxtx_jincui_wuzhugeliang"] = "天下事，了犹未了，终以不了了之......",
}
---------------------------------
--曹休
lxtx_caoxiu = sgs.General(extension, "lxtx_caoxiu", "wei")
local taoxi = {}
lxtx_taoxivs = sgs.CreateViewAsSkill{
	name = "lxtx_taoxi",
	n = 0,
	view_filter = function(self, selected, to_select)
	    return false
	end,
	view_as = function(self, cards)
	    local c = sgs.Sanguosha:getEngineCard(sgs.Self:getMark("taoxiName-Clear"))
		local list = sgs.Sanguosha:cloneCard(c:objectName(), sgs.Card_SuitToBeDecided, 0)
		list:setSkillName("_"..self:objectName())
		return list
	end,
	enabled_at_play = function(self, player)
		return player:getMark("taoxiName-Clear") > 0
	end,
}
lxtx_taoxi = sgs.CreateTriggerSkill{
	name = "lxtx_taoxi",
	--global = true,
	events = {sgs.TargetSpecifying, sgs.EventPhaseChanging, sgs.CardUsed, sgs.CardResponded, sgs.PreCardUsed},
	view_as_skill = lxtx_taoxivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecifying then
		    local use = data:toCardUse()
			if use.card and not use.card:isKindOf("SkillCard") and use.from:objectName() == player:objectName() and not use.to:contains(player) and use.to:length() == 1 and player:getPhase() == sgs.Player_Play
			and player:hasSkill(self:objectName()) then
			    for _, p in sgs.qlist(use.to) do
					local dest = sgs.QVariant()
					dest:setValue(p)
				    if not p:isKongcheng() and player:getMark(self:objectName().."-SelfPlayClear") < 1 and #taoxi < 1 and room:askForSkillInvoke(player, self:objectName(), dest) then
				        room:broadcastSkillInvoke(self:objectName())
			            local ids = sgs.IntList()
			            for _, card in sgs.qlist(p:getHandcards()) do
				            if not card:isKindOf("EquipCard") then
					            ids:append(card:getEffectiveId())
				            end
			            end
		                room:fillAG(ids, player)
		                local id = room:askForAG(player, ids, false, self:objectName())
		                room:clearAG(player)
                        room:showCard(p, id)
						room:setPlayerMark(player, "taoxiName-Clear", id)
						room:setPlayerMark(player, "&lxtx_taoxi+:+"..sgs.Sanguosha:getCard(id):objectName().."-Clear", 1)
				        table.insert(taoxi, sgs.Sanguosha:getCard(id):objectName())
						room:addPlayerMark(player, self:objectName().."-SelfPlayClear")
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive or not player:hasSkill(self:objectName()) or #taoxi < 1 then
				return false
			end
			for _, name in ipairs(taoxi) do
			    room:sendCompulsoryTriggerLog(player, self)
				room:loseHp(player, 1, true, player, self:objectName())
				table.removeOne(taoxi, name)
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local skill = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n
				if skill == "lxtx_taoxi" then
					room:broadcastSkillInvoke(skill)
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
			if not player:hasSkill(self:objectName()) or not card or card:getSkillName() ~= "lxtx_taoxi" or player:getMark("taoxiName-Clear") < 1 or #taoxi < 1 then
				return false
			end
			for _, name in ipairs(taoxi) do
			    if name == card:objectName() then
				    table.removeOne(taoxi, card:objectName())
					room:setPlayerMark(player, "taoxiName-Clear", 0)
					room:setPlayerMark(player, "&lxtx_taoxi+:+"..name.."-Clear", 0)
			    end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
lxtx_caoxiu:addSkill(lxtx_taoxi)
lxtx_caoxiu:addSkill("qianju")
sgs.LoadTranslationTable{
	["lxtx_caoxiu"] = "曹休[龙行天下]",
	["&lxtx_caoxiu"] = "曹休",
	["#lxtx_caoxiu"] = "滑铲过龙门",
	["designer:lxtx_caoxiu"] = "俺的西木野Maki",
	["cv:lxtx_caoxiu"] = "官方",
	["illustrator:lxtx_caoxiu"] = "枭瞳", --皮肤：烽火连天
	["lxtx_taoxi"] = "讨袭",
    [":lxtx_taoxi"] = "出牌阶段限一次，你使用牌指定一名其他角色为唯一目标时，你可以亮出其一张手牌并记录之，且直到回合结束前你可以视为使用（点击技能按钮即可）此牌名的牌，" ..
	"然后以此法使用或打出牌后清除相同牌名的记录。回合结束时，若牌名仍然被记录，则你失去1点体力。",
	["$lxtx_taoxi1"] = "敌军勇不可挡，当以奇兵胜之。",
	["$lxtx_taoxi2"] = "虎豹骑下，可没有孬种！",
    ["~lxtx_caoxiu"] = "吾不用公之言，今日果遭此一败......",
}
---------------------------------
--曹彰
lxtx_caozhang = sgs.General(extension, "lxtx_caozhang", "wei")
lxtx_jiangchi = sgs.CreateTriggerSkill{
	name = "lxtx_jiangchi",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Draw and player:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName(), data) then
				if player:isKongcheng() then room:broadcastSkillInvoke(self:objectName(), 2) player:drawCards(1) room:addPlayerMark(player, "lxtx_jiangchi_draw-Clear") end
				local card_id = room:askForExchange(player, self:objectName(), 1, 1, true, "@lxtx_jiangchi-invoke", true)
				if card_id then
		            room:broadcastSkillInvoke(self:objectName(), 2)
					room:moveCardTo(sgs.Sanguosha:getCard(card_id:getSubcards():first()), player, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName(), self:objectName(), ""))
		            room:broadcastSkillInvoke("@recast")
		            local log = sgs.LogMessage()
		            log.type = "#UseCard_Recast"
		            log.from = player
		            log.card_str = ""..sgs.Sanguosha:getCard(card_id:getSubcards():first()):toString()
		            room:sendLog(log)
		            player:drawCards(1, "recast")
					room:addPlayerMark(player, "lxtx_jiangchi_recast-Clear")
					room:changeTranslation(player, "lxtx_zhangwu", 2)
				else
		            room:broadcastSkillInvoke(self:objectName(), 1)
				    player:drawCards(1)
					room:addPlayerMark(player, "lxtx_jiangchi_draw-Clear")
					room:changeTranslation(player, "lxtx_zhangwu", 1)
				end
			elseif player:getPhase() == sgs.Player_Finish then
				room:changeTranslation(player, "lxtx_zhangwu", 0)
			end
		end
		return false
	end,
}
lxtx_jiangchi_maxcards = sgs.CreateMaxCardsSkill{
	name = "lxtx_jiangchi_maxcards",
	frequency = sgs.Skill_Compulsory,
	extra_func = function(self, target)
		local n = 0
		if target:hasSkill("lxtx_jiangchi") and target:getMark("lxtx_jiangchi_draw-Clear") > 0 then
			local ids = sgs.IntList()
			for _,card in sgs.qlist(target:getHandcards()) do
			    if card:isKindOf("Slash") then
				    ids:append(card:getEffectiveId())
				end
			end
			if not ids:isEmpty() then
			    n = n + ids:length()
			end
		end
		return n
	end,
}
lxtx_jiangchi_slash = sgs.CreateTargetModSkill{
    name = "lxtx_jiangchi_slash",
	pattern = "Card",
	frequency = sgs.Skill_Compulsory,
	distance_limit_func = function(self, from, card, to)
	    local n = 0
		if from:hasSkill("lxtx_zhangwu") and card:isKindOf("Slash") and from:getMark("lxtx_jiangchi_draw-Clear") > 0 and table.contains(card:getSkillNames(), "lxtx_zhangwuu") then
			n = 1000
		end
		return n
	end,
	residue_func = function(self, from, card, to)
	    local n = 0
		if from:hasSkill("lxtx_jiangchi") and card:isKindOf("Slash") and from:getMark("lxtx_jiangchi_recast-Clear") > 0 then
			n = n + 1
		end
		if from:hasSkill("lxtx_jiangchi") and card:isKindOf("Slash") and from:getMark("lxtx_jiangchi_draw-Clear") > 0 then
			n = n - 1
		end
		if from:hasSkill("lxtx_zhangwu") and card:isKindOf("Slash") and table.contains(card:getSkillNames(), "lxtx_zhangwuu") and from:getMark("lxtx_jiangchi_draw-Clear") > 0 then
			n = 1000
		end
		return n
	end,
}
lxtx_zhangwu_use = sgs.CreateTriggerSkill{
    name = "lxtx_zhangwu_use",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        local card = nil
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else 
			local resp = data:toCardResponse()
			if resp.m_isUse then
				card = resp.m_card
			end
		end
		if card and table.contains(card:getSkillNames(), "lxtx_zhangwuu") then
			room:addPlayerMark(player, card:getSkillName().."-SelfPlayClear")
			if player:getMark("lxtx_jiangchi_draw-Clear") > 0 then
				room:broadcastSkillInvoke("lxtx_zhangwu", 1)
			elseif player:getMark("lxtx_jiangchi_recast-Clear") > 0 then
				room:broadcastSkillInvoke("lxtx_zhangwu", 2)
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:hasSkill("lxtx_zhangwu")
	end,
}
lxtx_zhangwu = sgs.CreateViewAsSkill{
	name = "lxtx_zhangwu",
	n = 999,
	view_filter = function(self, selected, to_select)
		if sgs.Self:getMark("lxtx_jiangchi_recast-Clear") > 0 then
			return not to_select:isEquipped()
		else
			return false
		end
	end,
	view_as = function(self, cards)
		local new_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
		if new_card then
			if sgs.Self:getMark("lxtx_jiangchi_recast-Clear") > 0 then
			    for _, c in ipairs(cards) do
				    new_card:addSubcard(c)
				end
			elseif sgs.Self:getMark("lxtx_jiangchi_draw-Clear") > 0 then
			    for _, card in sgs.qlist(sgs.Self:getHandcards()) do
				    if card:isKindOf("BasicCard") and not (card:isKindOf("Peach") or card:isKindOf("Analeptic")) then
					    new_card:addSubcard(card:getEffectiveId())
					end
				    if card:isKindOf("EquipCard") then
					    new_card:addSubcard(card:getEffectiveId())
					end
				end
			else
			    new_card:addSubcards(sgs.Self:getHandcards())
			end
		end
		new_card:setSkillName("lxtx_zhangwuu") --防止乱播报语音
		return new_card
	end,
	enabled_at_play = function(self, player)
		if player:isKongcheng() then return false end
		if player:getMark("lxtx_jiangchi_draw-Clear") > 0 then
		    local ids = sgs.IntList()
			for _, card in sgs.qlist(player:getHandcards()) do
				if card:isKindOf("BasicCard") and not (card:isKindOf("Peach") or card:isKindOf("Analeptic")) then
					ids:append(card:getEffectiveId())
				end
				if card:isKindOf("EquipCard") then
					ids:append(card:getEffectiveId())
				end
			end
		    if ids:isEmpty() then return false end
		end
		return player:getMark("lxtx_zhangwuu-SelfPlayClear") < 1
	end,
}
lxtx_caozhang:addSkill(lxtx_jiangchi)
if not sgs.Sanguosha:getSkill("lxtx_jiangchi_maxcards") then skills:append(lxtx_jiangchi_maxcards) end
if not sgs.Sanguosha:getSkill("lxtx_jiangchi_slash") then skills:append(lxtx_jiangchi_slash) end
if not sgs.Sanguosha:getSkill("lxtx_zhangwu_use") then skills:append(lxtx_zhangwu_use) end
lxtx_caozhang:addSkill(lxtx_zhangwu)
sgs.LoadTranslationTable{
	["lxtx_caozhang"] = "曹彰[龙行天下]",
	["&lxtx_caozhang"] = "曹彰",
	["#lxtx_caozhang"] = "龙争虎斗",
	["designer:lxtx_caozhang"] = "俺的西木野Maki",
	["cv:lxtx_caozhang"] = "官方",
	["illustrator:lxtx_caozhang"] = "梦回唐朝", --皮肤：勇斗英武
	["lxtx_jiangchi"] = "将驰", --语音为原版
	["@lxtx_jiangchi-invoke"] = "你可以发动“将驰”<br/> <b>操作提示</b>: [不选/选择]手牌→点击[取消→摸牌/确定→重铸]<br/>",
	[":lxtx_jiangchi"] = "摸牌阶段结束时，你可以选择一项：" ..
	"1.摸一张牌，你本回合使用【杀】的次数-1，且【杀】不计入手牌上限；" ..
	"2.重铸一张手牌，你本回合使用【杀】的次数+1，且使用【杀】无距离限制。",
	["$lxtx_jiangchi1"] = "谨遵父训，不可逞匹夫之勇。", --摸牌
	["$lxtx_jiangchi2"] = "吾定当身先士卒，振魏武雄风！", --重铸
	["lxtx_zhangwu"] = "彰武",
	["lxtx_zhangwuu"] = "彰武",
	[":lxtx_zhangwu"] = "出牌阶段限一次，你可以将所有手牌当【杀】使用。若你发动“将驰”：" ..
	"摸牌，你将“所有手牌”中的“手牌”改为非【桃】和【酒】的基本牌和装备牌，且以此法使用的【杀】无距离和次数限制；" ..
	"重铸牌，你将“所有手牌”中的“所有”改为“任意张”。",
	[":lxtx_zhangwu1"] = "出牌阶段限一次，你可以将所有非【桃】和【酒】的基本牌和装备牌当【杀】使用，且以此法使用的【杀】无距离和次数限制。",
	[":lxtx_zhangwu2"] = "出牌阶段限一次，你可以将任意张手牌当【杀】使用。",
	["$lxtx_zhangwu1"] = "展吾之风，捍吾军威！", --摸牌
	["$lxtx_zhangwu2"] = "收敛锋芒，蓄势待敌。", --重铸
	["~lxtx_caozhang"] = "黄须坚甲，也难敌骨肉毒心......",
}
---------------------------------
--崔琰＆毛玠
lxtx_cuiyanmaojie = sgs.General(extension, "lxtx_cuiyanmaojie", "wei", 3)
lxtx_zhengpiCard = sgs.CreateSkillCard{
	name = "lxtx_zhengpi",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets < 1 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
	    room:obtainCard(targets[1], self, false)
		if targets[1]:getState() == "online" then
			if not room:askForDiscard(targets[1], self:objectName(), 1, 1, true, true, "TrickCard,EquipCard") then
		    	room:askForDiscard(targets[1], self:objectName(), 2, 2, false, true, "BasicCard")
			end
		else
			local basic, unbasic, throw = {}, {}, nil
			for _, c in sgs.qlist(targets[1]:getCards("he")) do
				if c:isKindOf("BasicCard") then
					table.insert(basic, c)
				else
					table.insert(unbasic, c)
				end
			end
			if #unbasic > 0 then
				throw = unbasic[math.random(1, #unbasic)]
				room:throwCard(throw, targets[1], targets[1])
			else
				if #basic < 2 then
					throw = basic[math.random(1, #basic)]
					room:throwCard(throw, targets[1], targets[1])
				else
					local throw1 = basic[math.random(1, #basic)]
					room:throwCard(throw1, targets[1], targets[1])
					table.removeOne(basic, throw1)
					local throw2 = basic[math.random(1, #basic)]
					room:throwCard(throw2, targets[1], targets[1])
				end
			end
		end
	end,
}
lxtx_zhengpi = sgs.CreateViewAsSkill{
	name = "lxtx_zhengpi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		if #cards == 0 then return false end
		local card = lxtx_zhengpiCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#lxtx_zhengpi") < 1
	end,
}
lxtx_fengying = sgs.CreateTriggerSkill{
    name = "lxtx_fengying",
	--global = true,
	frequency = sgs.Skill_Limited,
	events = {sgs.EventPhaseChanging, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("fengying-Clear") > 0 and not player:isNude() and room:askForDiscard(player, self:objectName(), 1, 1, true, true) then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				player:gainAnExtraTurn()
			end
		else
			if player:getPhase() == sgs.Player_Play and not player:skip(sgs.Player_Play) and player:getMark(self:objectName()) == 0 and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				player:throwAllHandCards()--room:throwCard(player:getHandcards(), player, nil)
				player:drawCards(player:getMaxHp() - player:getHandcardNum())
				room:addPlayerMark(player, "fengying-Clear")
				room:addPlayerMark(player, "&fengying-Clear")
				room:setPlayerMark(player, self:objectName(), 1)
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:isAlive() and player:hasSkill(self:objectName())
	end,
}
lxtx_cuiyanmaojie:addSkill(lxtx_zhengpi)
lxtx_cuiyanmaojie:addSkill(lxtx_fengying)
sgs.LoadTranslationTable{
	["lxtx_cuiyanmaojie"] = "崔琰＆毛玠[龙行天下]",
	["&lxtx_cuiyanmaojie"] = "崔琰毛玠",
	["#lxtx_cuiyanmaojie"] = "龙章凤姿",
	["designer:lxtx_cuiyanmaojie"] = "俺的西木野Maki",
	["cv:lxtx_cuiyanmaojie"] = "官方",
	["illustrator:lxtx_cuiyanmaojie"] = "猎枭", --皮肤：直言劝谏
	["lxtx_zhengpi"] = "征辟",
	[":lxtx_zhengpi"] = "出牌阶段限一次，你可以将一张基本牌交给一名角色，然后其选择是否弃置一张不为基本牌的牌，若其选择否，其弃置两张基本牌。",
	--["$rushB_zhengpi1"] = "盖非常之功，必待非常之人。",
	--["$rushB_zhengpi2"] = "马或奔踶而致千里，士或有负俗之累而立功名。",
	["$lxtx_zhengpi1"] = "贤良方正，举荐征辟。",
	["$lxtx_zhengpi2"] = "相征召者，助事佐事。",
	["lxtx_fengying"] = "奉迎",
	[":lxtx_fengying"] = "限定技，出牌阶段开始时，你可以弃置所有手牌，然后将手牌补至体力上限，若如此做，此回合结束时，你可以弃置一张牌，然后执行一个额外的回合。",
	--["$rushB_fengying1"] = "奉迎砥砺名节之士，使天下自治。",
	--["$rushB_fengying2"] = "迎贤良方正者，以奉社稷。",
	["$lxtx_fengying1"] = "奉迎之人，叩头为贺。",
	["$lxtx_fengying2"] = "皇嗣回翔，即出奉迎。",
	--["~rushB_cuiyanmaojie"] = "虬须直视，因有所瞋......",
	["~lxtx_cuiyanmaojie"] = "枉费心力分疏......",
}
---------------------------------
--刘备
lxtx_liubei = sgs.General(extension, "lxtx_liubei$", "shu")
--专属武器：飞龙夺凤
LxtxFeiLongDuoFeng = sgs.CreateWeapon{
	name = "_lxtx_feilongduofeng",
	class_name = "LxtxFeiLongDuoFeng",
	range = 2,
	on_install = function(self, player)
		local room = player:getRoom()
		room:addPlayerMark(player, "&"..self:objectName())
		room:acquireSkill(player, lxtx_feilongduofengskill, false, true, false)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:removePlayerMark(player, "&"..self:objectName())
		room:detachSkillFromPlayer(player, "lxtx_feilongduofengskill", true, true)
	end,
}
--
lxtx_feilongduofengskill = sgs.CreateTriggerSkill{
	name = "lxtx_feilongduofengskill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified, sgs.Death},
	on_trigger = function(self, event, player, data, room)
	    if event == sgs.TargetSpecified then
		    local use = data:toCardUse()
			local fldf = false
		    if use.from:objectName() == player:objectName() and not use.to:contains(player) then
			    if use.card:isKindOf("Slash") then
					for _, p in sgs.qlist(use.to) do
						if not p:isNude() then
							fldf = true
						end
					end
					if fldf and room:askForSkillInvoke(player, "_lxtx_feilongduofeng", data) then
					    for _, p in sgs.qlist(use.to) do
						    room:askForDiscard(p, self:objectName(), 1, 1, false, true, "@_lxtx_feilongduofeng-discard")
						end
					end
				end
			end
		else
		    local death = data:toDeath()
		    if death.who:objectName() ~= player:objectName() and death.damage.from:objectName() == player:objectName() and death.damage.card:isKindOf("Slash") and death.who:getMark("_lxtx_feilongduofeng_limited") < 1 then
				room:setPlayerFlag(death.who, "LxtxFeiLongDuoFeng")
				if room:askForSkillInvoke(player, "_lxtx_feilongduofeng_re", data) then
					room:revivePlayer(death.who)
					room:setPlayerProperty(death.who, "hp", sgs.QVariant(death.who:getMaxHp()))
					room:addPlayerMark(death.who, "_lxtx_feilongduofeng_limited")
					room:setPlayerMark(death.who, "&"..death.who:getRole(), 0)
					if player:getRole() == "rebel" or player:getRole() == "loyalist" or player:getRole() == "renegade" then
						local role = player:getRole()
						room:setPlayerProperty(death.who, "role", sgs.QVariant(role))
						room:setPlayerMark(death.who, "&"..death.who:getRole(), 1)
					elseif player:isLord() then
						room:setPlayerProperty(death.who, "role", sgs.QVariant("loyalist"))
						room:setPlayerMark(death.who, "&"..death.who:getRole(), 1)
					end
				end
				room:setPlayerFlag(death.who, "-LxtxFeiLongDuoFeng")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getMark("&_lxtx_feilongduofeng") > 0
	end,
}
lxtx_zhangwu_lb = sgs.CreateTriggerSkill{
	name = "lxtx_zhangwu_lb",
	--global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:hasSkill(self:objectName()) then
				local cards = sgs.IntList()
		        for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
			        if sgs.Sanguosha:getEngineCard(id):isKindOf("LxtxFeiLongDuoFeng") then
				        cards:append(id)
			        end
		        end
		        if not cards:isEmpty() then
			        room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
					for _, id in sgs.qlist(cards) do
		 	            room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getEngineCard(id), player, player), false)
						break
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() then
			    local can_invoke = false
			    for _, id in sgs.qlist(move.card_ids) do
				    local card = sgs.Sanguosha:getEngineCard(id)
				    if card:isKindOf("LxtxFeiLongDuoFeng") then
					    can_invoke = true
				    end
			    end
			    if not can_invoke then return false end
			    if move.from_places:contains(sgs.Player_PlaceEquip) then
				    if move.from:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
					    for _, id in sgs.qlist(move.card_ids) do
						    local card = sgs.Sanguosha:getCard(id)
						    if card:isKindOf("LxtxFeiLongDuoFeng") then
			                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
							    room:moveCardsInToDrawpile(player, id, self:objectName(), room:getDrawPile():length())
							    player:drawCards(2)
						        break
							end
						end
					end
				end
			elseif move.to and move.to:objectName() == player:objectName() then
			    local can_invoke = false
			    for _, id in sgs.qlist(move.card_ids) do
				    local card = sgs.Sanguosha:getEngineCard(id)
				    if card:isKindOf("DoubleSword") then
					    can_invoke = true
				    end
			    end
			    if not can_invoke then return false end
			    if move.to_place == sgs.Player_PlaceEquip then
				    if move.to:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				        local cards = sgs.IntList()
		                for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
			                if sgs.Sanguosha:getEngineCard(id):isKindOf("LxtxFeiLongDuoFeng") then
				                cards:append(id)
			                end
		                end
		                if not cards:isEmpty() then
			                room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
					        for _, id in sgs.qlist(cards) do
		 	                    room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getEngineCard(id), player, player), false)
						        break
					        end
				        end
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
lxtx_jizhao = sgs.CreateTriggerSkill{
	name = "lxtx_jizhao",
	frequency = sgs.Skill_Limited,
	events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() == player:objectName() and player:getMark(self:objectName()) == 0 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
		        room:recover(player, sgs.RecoverStruct(player, nil, 2 - player:getHp()))
				if player:getHandcardNum() < player:getMaxHp() then
					player:drawCards(player:getMaxHp() - player:getHandcardNum())
				end
				if player:hasSkill("lxtx_shouyue") then
					room:detachSkillFromPlayer(player, "lxtx_shouyue")
				end
				room:acquireSkill(player, "lxtx_rende")
				if player:isLord() then
					room:acquireSkill(player, "oljijiang")
				end
				room:addPlayerMark(player, self:objectName())
			end
		end
	end,
}
lxtx_shouyue = sgs.CreateTriggerSkill{
	name = "lxtx_shouyue$",
	--global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.EventAcquireSkill},
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) or event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
			if not player:hasSkill("lxtx_shouyue_wusheng") then
				room:acquireSkill(player, "lxtx_shouyue_wusheng")
			end
			if not player:hasSkill("lxtx_shouyue_paoxiao") then
				room:acquireSkill(player, "lxtx_shouyue_paoxiao")
			end
			if not player:hasSkill("lxtx_shouyue_longdan") then
				room:acquireSkill(player, "lxtx_shouyue_longdan")
			end
			if not player:hasSkill("lxtx_shouyue_liegong") then
				room:acquireSkill(player, "lxtx_shouyue_liegong")
			end
			if not player:hasSkill("lxtx_shouyue_tieqi") then
				room:acquireSkill(player, "lxtx_shouyue_tieqi")
			end
		end
	end,
	can_trigger = function(self, player)
		return player and player:hasLordSkill("lxtx_shouyue") and player:getMark("Qingcheng".."lxtx_shouyue") < 1
	end,
}
lxtx_shouyue_skill = sgs.CreateTriggerSkill{
	name = "lxtx_shouyue_skill",
	global = true,
	events = {sgs.EventLoseSkill},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventLoseSkill then
			if data:toString() == "lxtx_shouyue" then
				if player:hasSkill("lxtx_shouyue_wusheng") then
					room:detachSkillFromPlayer(player, "lxtx_shouyue_wusheng", false, true)
				end
				if player:hasSkill("lxtx_shouyue_paoxiao") then
					room:detachSkillFromPlayer(player, "lxtx_shouyue_paoxiao", false, true)
				end
				if player:hasSkill("lxtx_shouyue_longdan") then
					room:detachSkillFromPlayer(player, "lxtx_shouyue_longdan", false, true)
				end
				if player:hasSkill("lxtx_shouyue_liegong") then
					room:detachSkillFromPlayer(player, "lxtx_shouyue_liegong", false, true)
				end
				if player:hasSkill("lxtx_shouyue_tieqi") then
					room:detachSkillFromPlayer(player, "lxtx_shouyue_tieqi", false, true)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
lxtx_shouyue_use_skill = sgs.CreateTriggerSkill{
	name = "lxtx_shouyue_use_skill",
	events = {sgs.PreCardUsed, sgs.CardUsed, sgs.CardResponded},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local skill = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n
				if skill == "lxtx_shouyue_wusheng" or skill == "lxtx_shouyue_longdan" or skill == "lxtx_shouyue_wusheng" or skill == "lxtx_shouyue_longdan" then
					room:broadcastSkillInvoke("lxtx_shouyue", math.random(1, 2))
				end
			end
		else
			local card = nil
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				local resp = data:toCardResponse()
				card = resp.m_card
			end
			if card and table.contains(card:getSkillNames(), "lxtx_shouyue_longdan") and player:hasSkill("lxtx_shouyue_longdan") then
				player:drawCards(1)
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
lxtx_shouyue_slash = sgs.CreateTargetModSkill{
	name = "lxtx_shouyue_slash",
	pattern = "Card",
	frequency = sgs.Skill_Compulsory,
	residue_func = function(self, player, card)
		if player:hasSkill("lxtx_shouyue_paoxiao") and card:isKindOf("Slash") then
		    return 1000
		else
			return 0
		end
	end,
    distance_limit_func = function(self, player, card)
		if player:hasSkill("lxtx_shouyue_liegong") and card:isKindOf("Slash") then
		    return 1
		else
			return 0
		end
	end,
--	extra_target_func = function(self, player, card)
--	    if card and (card:isKindOf("Slash") or card:isNDTrick()) and player:getMark("chongjian3-Clear") > 0 then
--		    return 2
--		else
--			return 0
--		end
--	end,
}
lxtx_shouyue_wusheng = sgs.CreateOneCardViewAsSkill{
	name = "lxtx_shouyue_wusheng&",
	response_or_use = true,
	view_filter = function(self, card)
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card)
		slash:setSkillName("lxtx_shouyue_wusheng")
		return slash
	end,
	enabled_at_play = function(self, player)
		return true
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end,
}
lxtx_shouyue_paoxiao = sgs.CreateTriggerSkill{
	name = "lxtx_shouyue_paoxiao&",
	events = {sgs.CardUsed, sgs.CardFinished, sgs.MarkChanged, sgs.TargetSpecified},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "lxtx_shouyue_paoxiao-Clear" and player:getMark("lxtx_shouyue_paoxiao-Clear") > 1 then
				room:sendCompulsoryTriggerLog(player, "lxtx_shouyue", true, true)
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			local card = use.card
			if card and card:isKindOf("Slash") then
				room:addPlayerMark(player, "lxtx_shouyue_paoxiao-Clear")
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local card = use.card
			if card and card:isKindOf("Slash") then
			    for _, p in sgs.qlist(use.to) do
				    room:removePlayerMark(p, "Armor_Nullified")
			    end
			end
		else
			local use = data:toCardUse()
			local card = use.card
			if card and card:isKindOf("Slash") and player:getMark("lxtx_shouyue_paoxiao-Clear") > 1 then
			    for _, p in sgs.qlist(use.to) do
				    room:addPlayerMark(p, "Armor_Nullified")
			    end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
lxtx_shouyue_longdan = sgs.CreateOneCardViewAsSkill{
	name = "lxtx_shouyue_longdan&",
	response_or_use = true,
	view_filter = function(self, card)
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return card:isKindOf("Jink")
		elseif usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return card:isKindOf("Jink")
			else
				return card:isKindOf("Slash")
			end
		else
			return false
		end
	end,
	view_as = function(self, card)
		if card:isKindOf("Slash") then
			local jink = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			jink:addSubcard(card)
			jink:setSkillName(self:objectName())
			return jink
		elseif card:isKindOf("Jink") then
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			slash:addSubcard(card)
			slash:setSkillName("lxtx_shouyue_longdan")
			return slash
		else
			return nil
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash" or pattern == "jink")
	end,
}
Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end
lxtx_shouyue_liegong = sgs.CreateTriggerSkill{
	name = "lxtx_shouyue_liegong&",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if player:getPhase() ~= sgs.Player_Play or not use.card:isKindOf("Slash") then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			if player:getHp() <= p:getHandcardNum() or player:getAttackRange() >= p:getHandcardNum() then
				local _data = sgs.QVariant()
				_data:setValue(p)
				if player:askForSkillInvoke(self:objectName(), _data) then
					room:broadcastSkillInvoke("lxtx_shouyue")
					jink_table[index] = 0
				end
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end,
}
lxtx_shouyue_tieqi = sgs.CreateTriggerSkill{
	name = "lxtx_shouyue_tieqi&",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		if not use.card:isKindOf("Slash") then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			if not player:isAlive() then break end
			local _data = sgs.QVariant()
			_data:setValue(p)
			if player:askForSkillInvoke(self:objectName(), _data) then
				room:broadcastSkillInvoke("lxtx_shouyue")
				p:setFlags("lxtx_shouyue_tieqi")
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|spade"
				judge.good = false
				judge.reason = self:objectName()
				judge.who = player
				player:getRoom():judge(judge)
				if judge:isGood() then
					jink_table[index] = 0
				end
				p:setFlags("-lxtx_shouyue_tieqi")
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end,
}
lxtx_rende_basicCard = sgs.CreateSkillCard{
	name = "lxtx_rende_basic",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local card =  sgs.Sanguosha:cloneCard(sgs.Self:property("lxtx_rende"):toString(), sgs.Card_NoSuit, 0)
		card:deleteLater()
		card:setSkillName("_"..self:objectName())
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) 
			and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local card =  sgs.Sanguosha:cloneCard(sgs.Self:property("lxtx_rende"):toString(), sgs.Card_NoSuit, 0)
		card:deleteLater()
		card:setSkillName("_"..self:objectName())
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,	
	on_validate = function(self, card_use)
		local player = card_use.from
		local room = player:getRoom()
		-- local use_card = sgs.Sanguosha:cloneCard(self:getUserString())
		local name = player:property("lxtx_rende"):toString()
		local use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
		use_card:setSkillName("_"..self:objectName())
		local available = true
		for _,p in sgs.qlist(card_use.to) do
			if player:isProhibited(p,use_card)	then
				available = false
				break
			end
		end
		available = available and use_card:isAvailable(player)
		if not available then return nil end
		return use_card		
	end,
}
lxtx_rendeCard = sgs.CreateSkillCard{
	name = "lxtx_rende",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, selected, to_select)
		return (#selected == 0) and (to_select:objectName() ~= sgs.Self:objectName())
	end,
	on_use = function(self, room, source, targets)
		room:obtainCard(targets[1], self, false)
		local old_value = source:getMark("lxtx_rende-Clear")
		local new_value = old_value + 1
		if old_value < 1 then
		    room:setPlayerMark(source, "lxtx_rende-Clear", new_value)
			local Set = function(list)
				local set = {}
				for _, l in ipairs(list) do set[l] = true end
				return set
			end
			local basic = {"slash", "peach"}
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(basic, 2, "thunder_slash")
				table.insert(basic, 2, "fire_slash")
				table.insert(basic, 2, "ice_slash")
				table.insert(basic, "analeptic")
			end
			table.insert(basic, "cancel")
			for _, patt in ipairs(basic) do
				local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, -1)
				if poi and (not poi:isAvailable(source)) or (patt == "peach" and not source:isWounded()) then
				    table.removeOne(basic, patt)
					--[[if patt == "slash" then
						table.removeOne(basic, "thunder_slash")
						table.removeOne(basic, "fire_slash")
					end]]
				end
			end
			local choice = room:askForChoice(source, self:objectName(), table.concat(basic, "+"))
			if choice ~= "cancel" then
				room:setPlayerProperty(source, "lxtx_rende", sgs.QVariant(choice))
				local usecard = room:askForUseCard(source, "@@lxtx_rende", "@lxtx_rende")
				room:setPlayerProperty(source, "lxtx_rende", sgs.QVariant())
				if not usecard then
		            room:setPlayerMark(source, "lxtx_rende-Clear", 0)
				end
			else
				room:setPlayerMark(source, "lxtx_rende-Clear", 0)
			end
		end
	end,
}
lxtx_rendevs = sgs.CreateViewAsSkill{
	name = "lxtx_rende",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
		    if #cards == 0 then return nil end
		    local rende_card = lxtx_rendeCard:clone()
		    for _, c in ipairs(cards) do
			    rende_card:addSubcard(c)
		    end
		    return rende_card
		end
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if string.find(pattern, "@@lxtx_rende") then 
		    if #cards ~= 0 then return nil end  
			local name = sgs.Self:property("lxtx_rende"):toString()
			local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
			card:setSkillName("_lxtx_rende_basic")
			return card
		end
		
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@lxtx_rende")
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end,
}
lxtx_rende = sgs.CreateTriggerSkill{
	name = "lxtx_rende",
	events = {sgs.PreCardUsed},
	view_as_skill = lxtx_rendevs,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local skill = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n
				if skill == "lxtx_rende" then
					room:broadcastSkillInvoke(skill, 3)
					return true
				end
				if skill == "_lxtx_rende_basic" then
					room:broadcastSkillInvoke(skill, math.random(1, 2))
					return true
				end
			end
		end
	end,
}
LxtxFeiLongDuoFeng:clone(sgs.Card_Spade, 2):setParent(extension)
if not sgs.Sanguosha:getSkill("lxtx_rende") then skills:append(lxtx_rende) end
if not sgs.Sanguosha:getSkill("lxtx_shouyue_skill") then skills:append(lxtx_shouyue_skill) end
if not sgs.Sanguosha:getSkill("lxtx_shouyue_use_skill") then skills:append(lxtx_shouyue_use_skill) end
if not sgs.Sanguosha:getSkill("lxtx_feilongduofengskill") then skills:append(lxtx_feilongduofengskill) end
if not sgs.Sanguosha:getSkill("lxtx_shouyue_wusheng") then skills:append(lxtx_shouyue_wusheng) end
if not sgs.Sanguosha:getSkill("lxtx_shouyue_paoxiao") then skills:append(lxtx_shouyue_paoxiao) end
if not sgs.Sanguosha:getSkill("lxtx_shouyue_longdan") then skills:append(lxtx_shouyue_longdan) end
if not sgs.Sanguosha:getSkill("lxtx_shouyue_liegong") then skills:append(lxtx_shouyue_liegong) end
if not sgs.Sanguosha:getSkill("lxtx_shouyue_tieqi") then skills:append(lxtx_shouyue_tieqi) end
if not sgs.Sanguosha:getSkill("lxtx_shouyue_slash") then skills:append(lxtx_shouyue_slash) end
lxtx_liubei:addSkill(lxtx_zhangwu_lb)
lxtx_liubei:addSkill(lxtx_jizhao)
lxtx_liubei:addSkill(lxtx_shouyue)
lxtx_liubei:addRelateSkill("lxtx_rende")
lxtx_liubei:addRelateSkill("oljijiang")
sgs.LoadTranslationTable{
	["lxtx_liubei"] = "刘备[龙行天下]",
	["&lxtx_liubei"] = "刘备",
	["#lxtx_liubei"] = "龙御天下",
	["designer:lxtx_liubei"] = "俺的西木野Maki",
	["cv:lxtx_liubei"] = "官方",
	["illustrator:lxtx_liubei"] = "无鳏", --皮肤正确
	["lxtx_zhangwu_lb"] = "章武",
	[":lxtx_zhangwu_lb"] = "锁定技，游戏开始时，你将【飞龙夺凤】置入你的装备栏；锁定技，当【飞龙夺凤】离开你的装备区时，你将【飞龙夺凤】置于牌堆底，然后摸两张牌。" ..
	"当一张【雌雄双股剑】进入你的装备栏时，你将此牌替换为【飞龙夺凤】并将【飞龙夺凤】置入你的装备栏。",
	["$lxtx_zhangwu_lb1"] = "飨神祚，承汉统，昭烈日，筑永安！",
	["$lxtx_zhangwu_lb2"] = "掣玄纛，彰戎武，鸣锋镝，讨血仇！",
	["lxtx_jizhao"] = "激诏",
	[":lxtx_jizhao"] = "限定技，当你处于濒死状态时，你可以将手牌补至体力上限，体力回复至2点，失去“授钺”并获得技能“仁德”。若你的身份为主公，则获得技能“激将”。",
	["$lxtx_jizhao1"] = "诸位将军，可愿与我共匡汉室？",
	["$lxtx_jizhao2"] = "汉家国祚，百姓攸业，皆系诸位将军！",
	["lxtx_shouyue"] = "授钺",
	["lxtx_shouyue_wusheng"] = "武圣",
	["lxtx_shouyue_paoxiao"] = "咆哮",
	["lxtx_shouyue_longdan"] = "龙胆",
	["lxtx_shouyue_liegong"] = "烈弓",
	["lxtx_shouyue_tieqi"] = "铁骑",
	[":lxtx_shouyue"] = "主公技，锁定技，你拥有\"五虎将大旗\"。\n\n#\"五虎将大旗\"\n" ..
					"你获得技能〖武圣〗、〖咆哮〗、〖龙胆〗、〖铁骑〗、〖烈弓〗：\n" ..
					"武圣：你可以将一张牌当【杀】使用或打出。\n" ..
					"咆哮：锁定技，你使用【杀】无次数限制；当你使用【杀】指定一个目标后，你无视其防具。\n" ..
					"龙胆：你可以将一张【杀】当【闪】、【闪】当【杀】使用或打出。当你发动“龙胆”时，你可以摸一张牌。\n" ..
					"烈弓：当你于出牌阶段内使用【杀】指定一个目标后，若该角色的手牌数不小于你的体力值或不大于你的攻击范围，则你可以令其不能使用【闪】响应此【杀】；你的攻击范围+1。\n" ..
					"铁骑：当你使用【杀】指定目标后，你可以进行判定，若结果不为黑桃，该角色不能使用【闪】。",
	["$lxtx_shouyue1"] = "铸剑章武，昭朕肃烈之志！",
	["$lxtx_shouyue2"] = "起誓鸣戎，决吾共死之意！",
	["lxtx_rende"] = "仁德",
	["lxtx_rende_basic"] = "仁德",
	["@lxtx_rende"] = "你可以发动“仁德”<br/> <b>操作提示</b>: 点击确定：使用牌→点击取消：不使用牌<br/>",
	[":lxtx_rende"] = "出牌阶段，你可以将任意张牌交给一名其他角色，然后若你以此法第一次交出手牌，你可以视为使用一张基本牌。若未以此法使用基本牌，则重置交出手牌的次数。",
	["$lxtx_rende1"] = "修德累仁，则汉道克昌！",
	["$lxtx_rende2"] = "迈仁树德，焘宇内无疆！",
	["$lxtx_rende3"] = "逐鹿四十载，今终致太平！", --其实是胜利语音
	["~lxtx_liubei"] = "朕躬德薄，望吾儿切勿效之......",
	
	["_lxtx_feilongduofeng_re"] = "飞龙夺凤",
	["_lxtx_feilongduofeng"] = "飞龙夺凤",
	[":_lxtx_feilongduofeng"] = "装备牌·<b>武器</b>\n<b>攻击范围</b>：２\n<b>技能</b>：\n" ..
					"1.当【杀】指定目标后，若使用者为你，你可令此目标对应的角色弃置一张牌。\n" ..
					"2.当一名角色因执行你使用的【杀】的效果而死亡时，你可以令其复活，然后将身份调整至与你所处的阵营相同。\n",
	["@_lxtx_feilongduofeng-discard"] = "受到【飞龙夺凤】效果影响，请弃置一张牌",
}
---------------------------------
--关羽＆张飞
lxtx_guanyuzhangfei = sgs.General(extension, "lxtx_guanyuzhangfei", "shu")
lxtx_wupao = sgs.CreateViewAsSkill{
	name = "lxtx_wupao",
	n = 1,
	response_or_use = true,
	frequency = sgs.Skill_Compulsory,
	view_filter = function(self, selected, to_select)
		return to_select:isRed()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return false end
		local slash = sgs.Sanguosha:cloneCard("slash")
		for _, c in ipairs(cards) do
			slash:addSubcard(c)
		end
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "slash")
	end,
}
lxtx_wupao_slash = sgs.CreateTargetModSkill{
	name = "lxtx_wupao_slash",
	pattern = "Card",
	frequency = sgs.Skill_Compulsory,
	residue_func = function(self, player, card)
		if player:hasSkill("lxtx_wupao") and card:isKindOf("Slash") then
		    return 1000
		else
			return 0
		end
	end,
    distance_limit_func = function(self, player, card)
	    if player:hasSkill("lxtx_wupao") and card:isKindOf("Slash") and player:getMark("lxtx_wupao-Clear") > 0 then
		    return 1000
		else
			return 0
		end
	end,
	extra_target_func = function(self, player, card)
		if table.contains(card:getSkillNames(), "lxtx_wupao") then
			return 1
		else
			return 0
		end
	end,
}
lxtx_wupao_use = sgs.CreateTriggerSkill{
	name = "lxtx_wupao_use",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and use.from:hasSkill("lxtx_wupao") and use.from:getPhase() == sgs.Player_Play then
			room:addPlayerMark(use.from, "lxtx_wupao-Clear")
	        if use.from:getMark("lxtx_wupao-Clear") > 1 then
		        room:sendCompulsoryTriggerLog(player, "lxtx_wupao", true, true)
		    end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
if not sgs.Sanguosha:getSkill("lxtx_wupao_slash") then skills:append(lxtx_wupao_slash) end
if not sgs.Sanguosha:getSkill("lxtx_wupao_use") then skills:append(lxtx_wupao_use) end
lxtx_guanyuzhangfei:addSkill(lxtx_wupao)
sgs.LoadTranslationTable{
    ["lxtx_guanyuzhangfei"] = "关羽＆张飞[龙行天下]",
    ["&lxtx_guanyuzhangfei"] = "关羽张飞",
    ["#lxtx_guanyuzhangfei"] = "门神迎新春",
	["designer:lxtx_guanyuzhangfei"] = "俺的西木野Maki",
	["cv:lxtx_guanyuzhangfei"] = "官方",
	["illustrator:lxtx_guanyuzhangfei"] = "凡果", --皮肤：桃园结义
	["lxtx_wupao"] = "武咆",
	[":lxtx_wupao"] = "你可以将一张红色牌当【杀】使用或打出，你以此法使用的【杀】可以额外选择一名其他角色为目标。" ..
	"锁定技，你使用【杀】无次数限制；若你在出牌阶段使用过【杀】，则你使用【杀】无距离限制。",
	["$lxtx_wupao1"] = "协力克敌建功业，黄巾扫尽佐炎刘！", --关羽
	["$lxtx_wupao2"] = "好汉当沙场建功，何惜八尺之躯？！", --张飞
    ["~lxtx_guanyuzhangfei"] = "大哥......",
}
---------------------------------
--赵统＆赵广
lxtx_zhaotongzhaoguang = sgs.General(extension, "lxtx_zhaotongzhaoguang", "shu")
lxtx_yizan = sgs.CreateViewAsSkill{
	name = "lxtx_yizan",
	n = 2,
	mute = true,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "analeptic" then
				return to_select:getSuit() == sgs.Card_Spade
			elseif pattern == "jink" then
				return to_select:getSuit() == sgs.Card_Club
			elseif string.find(pattern, "peach") then
				return to_select:getSuit() == sgs.Card_Heart
			elseif pattern == "slash" then
				return to_select:getSuit() == sgs.Card_Diamond
			end
			if sgs.Self:isWounded() then
			    return to_select:getSuit() ~= sgs.Card_Club
			else
			    return to_select:getSuit() ~= sgs.Card_Heart and to_select:getSuit() ~= sgs.Card_Club
			end
		elseif #selected == 1 then
			if selected[1]:getSuit() == sgs.Card_Spade or selected[1]:getSuit() == sgs.Card_Diamond or selected[1]:getSuit() == sgs.Card_Heart or selected[1]:getSuit() == sgs.Card_Club then
				return true
			else
			    local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			    if pattern == "analeptic" then
				    return to_select:getSuit() == sgs.Card_Spade
			    elseif pattern == "jink" then
				    return to_select:getSuit() == sgs.Card_Club
			    elseif string.find(pattern, "peach") then
				    return (to_select:getSuit() == sgs.Card_Heart and not sgs.Self:hasFlag("Global_PreventPeach"))
					or (to_select:getSuit() == sgs.Card_Spade and sgs.Self:hasFlag("Global_Dying")) --用酒自救
			    elseif pattern == "slash" then
				    return to_select:getSuit() == sgs.Card_Diamond
			    end
			    if sgs.Self:isWounded() then
			        return to_select:getSuit() ~= sgs.Card_Club
			    else
			        return to_select:getSuit() ~= sgs.Card_Heart and to_select:getSuit() ~= sgs.Card_Club
			    end
			end
		end
		return false
	end,
	view_as = function(self, cards)
		if (sgs.Self:getMark("lxtx_longyuan") > 0 and #cards ~= 1) or (sgs.Self:getMark("lxtx_longyuan") == 0 and #cards ~= 2) then return nil end
		local card = cards[1]
		local new_card = nil
		if card:getSuit() == sgs.Card_Spade then
			new_card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Club then
			new_card = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Heart then
			new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, 0)
		elseif card:getSuit() == sgs.Card_Diamond then
			new_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, 0)
		end
		if new_card then
			new_card:setSkillName(self:objectName())
			for _, c in ipairs(cards) do
				new_card:addSubcard(c)
			end
		end
		return new_card
	end,
	enabled_at_play = function(self, player)
		return player:isWounded() or sgs.Slash_IsAvailable(player) or sgs.Analeptic_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash")
			or (pattern == "jink")
			or (string.find(pattern, "peach")) --and (not player:hasFlag("Global_PreventPeach")))
	end,
}
lxtx_yizan_extra = sgs.CreateTriggerSkill{
	name = "lxtx_yizan_extra",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and table.contains(card:getSkillNames(), "lxtx_yizan") then
			room:addPlayerMark(player, "lxtx_yizan-Clear")
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
lxtx_longyuan = sgs.CreateTriggerSkill{
	name = "lxtx_longyuan",
	frequency = sgs.Skill_Wake,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.MarkChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "&lxtx_yizan" and mark.who and mark.who:objectName() == player:objectName() and (player:getMark("&lxtx_yizan") >= 3 or player:canWake(self:objectName())) and player:getMark("lxtx_longyuan") < 1 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
			    room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
                room:addPlayerMark(player, "lxtx_longyuan")
                room:changeTranslation(player, "lxtx_yizan", sgs.Sanguosha:translate(":lxtx_yizan_extra"))
			end
		else
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			if card and table.contains(card:getSkillNames(), "lxtx_yizan") then
				room:addPlayerMark(player, "&lxtx_yizan")
			end
		end
	end,
}
lxtx_qingren = sgs.CreateTriggerSkill{
	name = "lxtx_qingren",
	--global = true,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
	    if event == sgs.EventPhaseChanging then
		    if data:toPhaseChange().to ~= sgs.Player_Finish then return false end
		    for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			    if p:getMark("lxtx_yizan-Clear") == 0 then return false end
		        if not room:askForSkillInvoke(p, self:objectName(), data) then return false end
				room:broadcastSkillInvoke(self:objectName())
				p:drawCards(p:getMark("lxtx_yizan-Clear"), self:objectName())
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
if not sgs.Sanguosha:getSkill("lxtx_yizan_extra") then skills:append(lxtx_yizan_extra) end
lxtx_zhaotongzhaoguang:addSkill(lxtx_yizan)
lxtx_zhaotongzhaoguang:addSkill(lxtx_longyuan)
lxtx_zhaotongzhaoguang:addSkill(lxtx_qingren)
sgs.LoadTranslationTable{
	["lxtx_zhaotongzhaoguang"] = "赵统＆赵广[龙行天下]",
	["&lxtx_zhaotongzhaoguang"] = "赵统赵广",
	["#lxtx_zhaotongzhaoguang"] = "龙威承泽",
	["designer:lxtx_zhaotongzhaoguang"] = "俺的西木野Maki",
	["cv:lxtx_zhaotongzhaoguang"] = "官方",
	["illustrator:lxtx_zhaotongzhaoguang"] = "alien", --皮肤正确
	["lxtx_yizan"] = "翊赞",
	[":lxtx_yizan"] = "你可以将两张牌当一张基本牌使用。你以此法使用【桃】/【杀】/【闪】/【酒】时，第一张牌需选择[红桃/方块/梅花/黑桃]牌。",
	[":lxtx_yizan_extra"] = "你可以将一张牌按以下规则使用或打出：红桃当【桃】；方块当【杀】；梅花当【闪】；黑桃当【酒】。",
	["$lxtx_yizan1"] = "擎龙胆枪锋砺天，抱青釭霜刃谁试！",
	["$lxtx_yizan2"] = "束坚甲以拥豹尾，立长戈而伐不臣。",
	["lxtx_longyuan"] = "龙渊",
	[":lxtx_longyuan"] = "觉醒技，当你因“翊赞”使用或打出一张牌时，若你发动过至少三次“翊赞”，则你修改“翊赞”。",
	["$lxtx_longyuan1"] = "尔等不闻九霄雷鸣，亦不闻渊龙之啸乎？",
	["$lxtx_longyuan2"] = "双龙战于玄黄地，渊潭浪涌惊四方。",
	["lxtx_qingren"] = "青刃",
	[":lxtx_qingren"] = "每个回合结束时，你可以摸X张牌。（X为当前回合发动“翊赞”的次数）",
	["$lxtx_qingren1"] = "父凭长枪行四海，子承父志卫江山。",
	["$lxtx_qingren2"] = "纵至天涯海角，亦当忠义相随。",
	["~lxtx_zhaotongzhaoguang"] = "汉室存亡之际，岂敢撒手人寰......",
}
---------------------------------
--吴庞统
lxtx_pangtong = sgs.General(extension, "lxtx_pangtong", "wu", 3)
lxtx_manjuanCard = sgs.CreateSkillCard{
	name = "lxtx_manjuan",
	will_throw = false,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		source:addToPile("manjuan", room:getDrawPile():first())
	end,
}
lxtx_manjuanvs = sgs.CreateViewAsSkill{
	name = "lxtx_manjuan",
	n = 0,
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self, cards)
		return lxtx_manjuanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lxtx_manjuan")
	end,
}
lxtx_manjuan = sgs.CreateTriggerSkill{
	name = "lxtx_manjuan",
	view_as_skill = lxtx_manjuanvs,
	events = {sgs.CardUsed, sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
		    local use = data:toCardUse()
		    if (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard")) and not use.card:isKindOf("SkillCard") and not use.card:isKindOf("Nullification") and use.from:objectName() == player:objectName() and not use.to:contains(use.from) and not use.to:contains(player) and not player:getPile("manjuan"):isEmpty() and use.card:getSkillName() ~= "lxtx_manjuan" and room:askForSkillInvoke(player, self:objectName(), data) then
			    room:broadcastSkillInvoke(self:objectName())
			    room:throwCard(sgs.Sanguosha:getCard(player:getPile("manjuan"):first()), player, nil)
			    local choices = {"1", "2", "3"}
			    if player:getPile("manjuan"):isEmpty() then table.removeOne(choices, "3") end
		        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
				if choice == "1" then
					local can = use.no_respond_list
					for _,to in sgs.list(use.to) do
						table.insert(can, to:objectName())
					end
					use.no_respond_list = can
					data:setValue(use)
				elseif choice == "2" then
				    room:setCardFlag(use.card, "manjuan")
				elseif choice == "3" then
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:addSubcards(player:getPile("manjuan"))
					room:throwCard(dummy, player, nil)
					dummy:deleteLater()
					local can = use.no_respond_list
					for _,to in sgs.list(use.to) do
						table.insert(can, to:objectName())
					end
					use.no_respond_list = can
					data:setValue(use)
				    room:setCardFlag(use.card, "manjuan")
				end
			end
		else
		    local use = data:toCardUse()
			if use.card:hasFlag("manjuan") then
				for _, p in sgs.list(use.to) do
					if (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") or use.card:isKindOf("Zhujinqiyuan")) and p:isAllNude() then
					    return false
					end
					if use.card:isKindOf("Collateral") and p:getWeapon() == nil then
					    return false
					end
					if (use.card:isKindOf("FireAttack") or use.card:isKindOf("Chuqibuyi")) and p:isKongcheng() then
					    return false
					end
					if p:isDead() then
					    return false
					end
				end
		        local cards = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, 0)
		        cards:setSkillName("_"..self:objectName())
		        room:useCard(sgs.CardUseStruct(cards, player, use.to), false)
			end
		end
	end,
}
lxtx_lianhengCard = sgs.CreateSkillCard{
	name = "lxtx_lianheng",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:objectName() ~= sgs.Self:objectName() and not to_select:isChained()
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerChained(targets[1])
	end,
}
lxtx_lianheng = sgs.CreateViewAsSkill{
	name = "lxtx_lianheng",
	n = 0,
	frequency = sgs.Skill_Compulsory,
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self, cards)
		return lxtx_lianhengCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lxtx_lianheng")
	end,
}
lxtx_lianheng_useto = sgs.CreateProhibitSkill{
	name = "lxtx_lianheng_useto",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("lxtx_lianheng") and from:isChained() and from:objectName() ~= to:objectName()
	end,
}
if not sgs.Sanguosha:getSkill("lxtx_lianheng_useto") then skills:append(lxtx_lianheng_useto) end
lxtx_pangtong:addSkill(lxtx_manjuan)
lxtx_pangtong:addSkill(lxtx_lianheng)
sgs.LoadTranslationTable{
	["lxtx_pangtong"] = "庞统[龙行天下]",
	["&lxtx_pangtong"] = "庞统",
	["#lxtx_pangtong"] = "凤舞龙飞",
	["designer:lxtx_pangtong"] = "俺的西木野Maki",
	["cv:lxtx_pangtong"] = "官方",
	["illustrator:lxtx_pangtong"] = "光域", --皮肤：携友同游
	["lxtx_manjuan"] = "漫卷",
	["lxtx_manjuan:1"] = "令此牌无法被响应",
	["lxtx_manjuan:2"] = "于此牌结算完成时额外执行一次效果",
	["lxtx_manjuan:3"] = "背水",
	[":lxtx_manjuan:3"] = "弃置所有“漫卷”，执行以上两项",
	[":lxtx_manjuan"] = "出牌阶段限一次，你可以将牌堆顶一张牌置于武将牌上，称为“漫卷”。当你使用牌后，你可以弃置一张“漫卷”，选择一项：" ..
	"1.令此牌无法被响应；2.于此牌结算完成时额外执行一次效果；背水：若你有“漫卷”，你可以弃置所有“漫卷”，执行以上两项。",
	["$lxtx_manjuan1"] = "雏凤展翼，当一飞冲天。",
	["$lxtx_manjuan2"] = "浴火而生，可期凤舞九天。",
	["lxtx_lianheng"] = "连横",
	["lxtx_lianheng_useto"] = "连横",
    [":lxtx_lianheng"] = "出牌阶段限一次，你可以选择一名未进入横置状态的其他角色，令其进入横置状态。锁定技，处于横置状态的角色使用的牌不能指定你为目标。",
	["$lxtx_lianheng1"] = "拔石助长，智者自力。",
	["$lxtx_lianheng2"] = "卿欲使我评点一二乎？",
	["~lxtx_pangtong"] = "世人皆以貌取人......",
}
---------------------------------
--孙皓
lxtx_sunhao = sgs.General(extension, "lxtx_sunhao$", "wu", 4, true, false, false, 3)
lxtx_canshi = sgs.CreateTriggerSkill{
	name = "lxtx_canshi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards, sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
			    local n = 0
			    for _,p in sgs.qlist(room:getAlivePlayers()) do
				    if p:isWounded() then
					    n = n + 1
					end
			    end
			   	draw.num = draw.num + n + player:getMark("lxtx_guiming-Clear")
			    data:setValue(draw)
				room:setPlayerFlag(player, "canshi")
				room:addPlayerMark(player, "&lxtx_canshi-Clear")
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.from:hasFlag("canshi") and player:getPhase() ~= sgs.Player_NotActive then
				room:askForDiscard(player, self:objectName(), 1, 1, false, true, "@canshi-discard")
			end
		end
	end,
}
lxtx_guiming = sgs.CreateTriggerSkill{
	name = "lxtx_guiming$",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:hasLordSkill(self:objectName()) and player:getPhase() == sgs.Player_Draw then
			    local n, targets = 0, sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
				    if p:getKingdom() == "wu" or p:getMark("&mwu") > 0 then n = n + 1 targets:append(p) end
			    end
				if n < 1 or targets:length() < 1 then return false end
				local log = sgs.LogMessage()
				log.type = "#lxtx_guiming"
				log.arg = self:objectName()
				log.arg2 = n
				log.from = player
				for _,p in sgs.qlist(targets) do
					log.to:append(p)
			    end
				room:sendLog(log)
				room:broadcastSkillInvoke(self:objectName(), math.random(3,4))
				room:setPlayerMark(player, "lxtx_guiming-Clear", n)
			end
		end
	end,
}
lxtx_sunhao:addSkill(lxtx_canshi)
lxtx_sunhao:addSkill("chouhai")
lxtx_sunhao:addSkill(lxtx_guiming)
sgs.LoadTranslationTable{
	["lxtx_sunhao"] = "孙皓[龙行天下]",
	["&lxtx_sunhao"] = "孙皓",
	["#lxtx_sunhao"] = "龙眉凤目",
	["designer:lxtx_sunhao"] = "俺的西木野Maki",
	["cv:lxtx_sunhao"] = "官方",
	["illustrator:lxtx_sunhao"] = "MUMU", --皮肤：皓露沁兰
	["lxtx_canshi"] = "残蚀",
	[":lxtx_canshi"] = "你可以令额定摸牌数+X（X为已受伤的角色数）。若如此做，当你于此回合内使用牌时，你弃置一张牌。",
	--多摸
	["$lxtx_canshi1"] = "今夜相思月有缺，皆因回首不见卿。",
	["$lxtx_canshi2"] = "人有悲欢与离合，得卿相伴皆圆晴。",
	--弃牌（仇海语音）
	["$lxtx_canshi3"] = "心海无波，然见卿，即起骇浪惊涛。",
	["$lxtx_canshi4"] = "伊人在畔，纵三千弱水，亦好逑之。",
	--
	["lxtx_guiming"] = "归命",
	["#lxtx_guiming"] = "%from 的 %arg 被触发，%to 是吴势力角色，被计入已受伤的角色数，本回合已受伤的角色数为 %arg2 ，本回合额外的摸牌数为 %arg2 。",
    [":lxtx_guiming"] = "主公技，锁定技，其他吴势力角色于你的回合内视为已受伤的角色。",
	["$lxtx_guiming1"] = "姻缘天定，此间红线系于我与卿心头。",
	["$lxtx_guiming2"] = "朕乃卿之真命天子，勿疑之，勿离之。",
	["~lxtx_sunhao"] = "山无陵、天地合，乃敢与卿绝......",
}
---------------------------------
--高顺
lxtx_gaoshun = sgs.General(extension, "lxtx_gaoshun", "qun")
lxtx_xianzhenCard = sgs.CreateSkillCard{
	name = "lxtx_xianzhen",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < 1 + player:getMark("lxtx_xianzhenDrew-Clear") and not to_select:isKongcheng() and to_select:objectName() ~= player:objectName()
		and player:canPindian(to_select)
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		if #targets == 1 then
		    source:pindian(targets[1], self:objectName(), self)
		else
		    for _,p in ipairs(targets) do
				source:pindian(p, self:objectName(), self)
			end
		end
	end,
}
lxtx_xianzhenvs = sgs.CreateViewAsSkill{
	name = "lxtx_xianzhen",
	n = 1,
	frequency = sgs.Skill_Compulsory,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards) 
		if #cards ~= 1 then return nil end
		local skillcard = lxtx_xianzhenCard:clone()
		for _, c in ipairs(cards) do
			skillcard:addSubcard(c)
		end
		return skillcard
	end, 
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end, 
}
lxtx_xianzhen = sgs.CreateTriggerSkill{
	name = "lxtx_xianzhen",
    --global = true,
	events = {sgs.Pindian, sgs.EventPhaseChanging, sgs.CardUsed},
	view_as_skill = lxtx_xianzhenvs, 
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Pindian then    
			local pindian = data:toPindian()
		    if pindian.reason == self:objectName() then
			    local winner = pindian.from
			    local loser = pindian.to
			    if pindian.from_card:getNumber() < pindian.to_card:getNumber() then
				    winner = pindian.to
				    loser = pindian.from
				    if loser:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				        room:setPlayerFlag(player, "xianzhenSource")
				    end
			    elseif pindian.from_card:getNumber() == pindian.to_card:getNumber() and player:hasSkill(self:objectName()) then
				    room:addPlayerMark(player, "lxtx_xianzhenDrew-Clear")
			    elseif pindian.from_card:getNumber() > pindian.to_card:getNumber() then
				    winner = pindian.from
				    loser = pindian.to
				    if winner:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				        room:setPlayerFlag(loser, "xianzhenTarget")
					    room:addPlayerMark(loser, "Armor_Nullified")
				        room:setPlayerFlag(player, "xianzhenCard")
				    end
			    end
			    if room:askForSkillInvoke(player, self:objectName()) then
			        room:broadcastSkillInvoke(self:objectName())
		            room:obtainCard(pindian.to, pindian.from_card, false)
				    room:obtainCard(pindian.to, pindian.to_card, false)
				end
		    end
		elseif event == sgs.CardUsed then
		    local use = data:toCardUse()
			if use.from:objectName() == player:objectName() and not use.to:contains(player) and player:hasSkill(self:objectName()) and not use.card:isKindOf("SkillCard") and use.card:isKindOf("Slash") then
				room:addPlayerMark(player, "lxtx_xianzhen-Clear")
			end
		else
		    local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
		    	for _, p in sgs.qlist(room:getAllPlayers()) do
				    if p:getMark("Armor_Nullified") > 0 then
					    room:setPlayerMark(p, "Armor_Nullified", 0)
				    end
			    end
		    end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
lxtx_xianzhen_extra = sgs.CreateProhibitSkill{
	name = "lxtx_xianzhen_extra",
	is_prohibited = function(self, from, to, card)
		if from:hasSkill("lxtx_xianzhen") and from:hasFlag("xianzhenCard") and from:getMark("lxtx_xianzhen-Clear") > 0 then
		    return from:objectName() ~= to:objectName() and card:isKindOf("Slash") and not card:isKindOf("SkillCard") and not to:hasFlag("xianzhenTarget")
		end
		if from:hasSkill("lxtx_xianzhen") and from:hasFlag("xianzhenSource") then
		    return from:objectName() ~= to:objectName() and card:isKindOf("Slash") and not card:isKindOf("SkillCard")
		end
	end,
}
lxtx_jinjiu = sgs.CreateFilterSkill{
	name = "lxtx_jinjiu",
	frequency = sgs.Skill_Compulsory,
	view_filter = function(self, to_select)
		return to_select:isKindOf("Analeptic") or to_select:isKindOf("Slash")
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), 13)
		if card:isKindOf("Analeptic") then
		    slash:setSkillName(self:objectName())
		elseif card:isKindOf("Slash") then
		    slash = sgs.Sanguosha:cloneCard(card:objectName(), card:getSuit(), 13)
			slash:setSkillName(self:objectName().."_extra")
		end
		local new = sgs.Sanguosha:getWrappedCard(card:getId())
		new:takeOver(slash)
		return new
	end,
}
lxtx_gaoshun_extra = sgs.CreateTargetModSkill{
	name = "lxtx_gaoshun_extra",
	pattern = "Card",
	frequency = sgs.Skill_Compulsory,
	residue_func = function(self, from, card, to)
		if from:hasSkill("lxtx_jinjiu") and (table.contains(card:getSkillNames(), "lxtx_jinjiu") or table.contains(card:getSkillNames(), "lxtx_jinjiu_extra")) and card:objectName() == "slash" then
		    return 1000
		else
			return 0
		end
		if from:hasSkill("lxtx_xianzhen") and card:isKindOf("Slash") and to:hasFlag("xianzhenTarget") then
		    return 1000
		else
			return 0
		end
	end,
    distance_limit_func = function(self, from, card, to)
		if from:hasSkill("lxtx_jinjiu") and (table.contains(card:getSkillNames(), "lxtx_jinjiu") or table.contains(card:getSkillNames(), "lxtx_jinjiu_extra")) and card:objectName() == "slash" then
		    return 1000
		else
			return 0
		end
		if from:hasSkill("lxtx_xianzhen") and card:isKindOf("Slash") and to:hasFlag("xianzhenTarget") then
		    return 1000
		else
			return 0
		end
	end,
	extra_target_func = function(self, from, card, to)
	    if from:hasSkill("lxtx_jinjiu") and (table.contains(card:getSkillNames(), "lxtx_jinjiu") or table.contains(card:getSkillNames(), "lxtx_jinjiu_extra")) and card:objectName() == "slash" then
		    return 1000
		else
			return 0
		end
		--[[if from:hasSkill("lxtx_xianzhen") and card:isKindOf("Slash") and to:hasFlag("xianzhenTarget") then
		    return 1000
		else
			return 0
		end]]
	end,
}
lxtx_jinjiu_extra = sgs.CreateTriggerSkill{
	name = "lxtx_jinjiu_extra",
	events = {sgs.PreCardUsed},
	frequency = sgs.Skill_Compulsory,
	global = true,
	priority = 1,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local skill = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n
				if skill == "lxtx_jinjiu" then
					room:broadcastSkillInvoke("lxtx_jinjiu", 2)
					return true
				end
				if skill == "lxtx_jinjiu_extra" then
					room:broadcastSkillInvoke("lxtx_jinjiu", 1)
					return true
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
if not sgs.Sanguosha:getSkill("lxtx_xianzhen_extra") then skills:append(lxtx_xianzhen_extra) end
if not sgs.Sanguosha:getSkill("lxtx_jinjiu_extra") then skills:append(lxtx_jinjiu_extra) end
if not sgs.Sanguosha:getSkill("lxtx_gaoshun_extra") then skills:append(lxtx_gaoshun_extra) end
lxtx_gaoshun:addSkill(lxtx_xianzhen)
lxtx_gaoshun:addSkill(lxtx_jinjiu)
sgs.LoadTranslationTable{
	["lxtx_gaoshun"] = "高顺[龙行天下]",
	["&lxtx_gaoshun"] = "高顺",
	["#lxtx_gaoshun"] = "龙骧虎步",
	["designer:lxtx_gaoshun"] = "俺的西木野Maki",
	["cv:lxtx_gaoshun"] = "官方",
	["illustrator:lxtx_gaoshun"] = "枭瞳", --皮肤：九州河山
	["lxtx_xianzhen"] = "陷阵",
	["lxtx_xianzhen_extra"] = "陷阵",
	[":lxtx_xianzhen"] = "出牌阶段，你可以选择一张手牌并与一名角色拼点（若可选择的角色数大于1则改为你可以选择一张手牌并与至少一名角色拼点），若你拼点结果为：" ..
	"胜，则你于此阶段内无视其防具且对其使用牌无距离和次数限制；平，“陷阵”可额外指定一名角色；负，你此阶段内无法使用【杀】指定其他角色为目标。然后你可以选择令目标获得两张拼点牌。",
	["$lxtx_xianzhen1"] = "踏阵无归，至死方休！",
	["$lxtx_xianzhen2"] = "陷阵营，哪里去不得？",
	["lxtx_jinjiu"] = "禁酒",
	["lxtx_jinjiu_extra"] = "禁酒",
	[":lxtx_jinjiu"] = "锁定技，你的【酒】视为点数为K的【杀】，未转化的【杀】、雷【杀】、火【杀】、冰【杀】视为点数为K的同名牌。" ..
	"你使用以此法转化的<font color='blue'><b>普通</b></font>【杀】无次数、距离和目标数限制。",
	["$lxtx_jinjiu1"] = "劝君莫贪杯，空曰凌云志。",
	["$lxtx_jinjiu2"] = "饮酒误事，恕顺不能共饮。",
	["~lxtx_gaoshun"] = "陷阵之后，再无精旅......",
}
---------------------------------
--马超
lxtx_machao = sgs.General(extension, "lxtx_machao", "qun")
lxtx_zhuiji = sgs.CreateTriggerSkill{
	name = "lxtx_zhuiji",
	events = {sgs.CardUsed, sgs.EventPhaseChanging},
	--global = true,
	priority = 1,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.from:hasSkill(self:objectName()) and not use.to:contains(use.from) and not use.card:isKindOf("SkillCard") and use.card:isDamageCard() and use.to:length() == 1 then
				room:sendCompulsoryTriggerLog(use.from, self:objectName())
			    room:broadcastSkillInvoke(self:objectName())
		        for _,p in sgs.qlist(use.to) do
				    room:addPlayerMark(p, "@skill_invalidity")
					local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.good = true
					judge.reason = self:objectName()
					judge.who = p
					room:judge(judge)
					local card_id = nil
					if judge.card:getSuit() == sgs.Card_Heart then
					    card_id = room:askForCard(p, ".|heart|.|hand", "@zhuiji-heart", data, sgs.Card_MethodNone)
					elseif judge.card:getSuit() == sgs.Card_Diamond then
					    card_id = room:askForCard(p, ".|diamond|.|hand", "@zhuiji-diamond", data, sgs.Card_MethodNone)
					elseif judge.card:getSuit() == sgs.Card_Spade then
					    card_id = room:askForCard(p, ".|spade|.|hand", "@zhuiji-spade", data, sgs.Card_MethodNone)
					elseif judge.card:getSuit() == sgs.Card_Club then
					    card_id = room:askForCard(p, ".|club|.|hand", "@zhuiji-club", data, sgs.Card_MethodNone)
					end
					if not card_id then
					    local can = use.no_respond_list
					    table.insert(can, p:objectName())
					    use.no_respond_list = can
					    data:setValue(use)
					else
					    room:throwCard(card_id, player, nil)
					end
			    end
			end
		elseif event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
			    for _, p in sgs.qlist(room:getAllPlayers()) do
				    if p:getMark("@skill_invalidity") > 0 then
					    room:setPlayerMark(p, "@skill_invalidity", 0)
				    end
			    end
		    end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
lxtx_zhuiji_extra = sgs.CreateDistanceSkill{
	name = "lxtx_zhuiji_extra",
	correct_func = function(self, from, to)
		local n = 0
		if from:hasSkill("lxtx_zhuiji") then
			if from:getHp() >= to:getHp() then
				n = -1000
			else
				n = -1
			end
		end
		return n
	end,
}
lxtx_shichouCard = sgs.CreateSkillCard{
	name = "lxtx_shichou",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return to_select:objectName() ~= sgs.Self:objectName() and not to_select:hasFlag("shichou") and #targets < math.max(1, sgs.Self:getLostHp())
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		for _, p in ipairs(targets) do
			room:setPlayerFlag(p, "shichouTarget")
		end
	end,
}
lxtx_shichouvs = sgs.CreateViewAsSkill{
    name = "lxtx_shichou",
	n = 0,
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self, cards)
		return lxtx_shichouCard:clone()
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@lxtx_shichou")
	end,
	enabled_at_play = function(self, player)
		return false
	end,
}
lxtx_shichou = sgs.CreateTriggerSkill{
	name = "lxtx_shichou",
	view_as_skill = lxtx_shichouvs,
	events = {sgs.CardUsed, sgs.Damage, sgs.CardFinished},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if player:hasSkill(self:objectName()) and not use.to:contains(player) and not use.card:isKindOf("SkillCard") and use.card:isDamageCard() and use.to:length() == 1 and use.card:getSkillName() ~= "tieji" then
				for _,p in sgs.qlist(use.to) do
		            local n = 0
					for _,pe in sgs.qlist(room:getOtherPlayers(p)) do
					    n = n + 1
					end
		            if n < 2 then return false end
		        	room:setPlayerFlag(p, "shichou")
			    end
				room:setCardFlag(use.card, "shichou")
				player:setTag("lxtx_shichou_data", data)
			    room:askForUseCard(player, "@@lxtx_shichou", "@lxtx_shichou")
				player:removeTag("lxtx_shichou_data")
		        for _,splayer in sgs.qlist(room:getOtherPlayers(player)) do
		        	if splayer:hasFlag("shichouTarget") then
		        	    room:setPlayerFlag(splayer, "-shichouTarget")
			            use.to:append(splayer)
					end
			    end
		        for _,p in sgs.qlist(use.to) do
		        	room:setPlayerFlag(p, "-shichou")
			    end
				room:sortByActionOrder(use.to)
				data:setValue(use)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if player:hasSkill(self:objectName()) and use.card:hasFlag("shichou") then
		        room:sendCompulsoryTriggerLog(player, self:objectName())
			    room:broadcastSkillInvoke(self:objectName())
				room:setCardFlag(use.card, "-shichou")
				room:obtainCard(player, use.card, false)
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("shichou") then
				room:setCardFlag(damage.card, "-shichou")
			end
		end
		return false
	end,
}
if not sgs.Sanguosha:getSkill("lxtx_zhuiji_extra") then skills:append(lxtx_zhuiji_extra) end
lxtx_machao:addSkill(lxtx_zhuiji)
lxtx_machao:addSkill(lxtx_shichou)
sgs.LoadTranslationTable{
	["lxtx_machao"] = "马超[龙行天下]",
	["&lxtx_machao"] = "马超",
	["#lxtx_machao"] = "龙马精神",
	["designer:lxtx_machao"] = "俺的西木野Maki",
	["cv:lxtx_machao"] = "官方",
	["illustrator:lxtx_machao"] = "君桓文化", --皮肤：折花心动
	["lxtx_zhuiji"] = "追击", --语音：马啸龙吟
	["@zhuiji-heart"] = "请弃置一张红桃手牌",
	["@zhuiji-diamond"] = "请弃置一张方块手牌",
	["@zhuiji-club"] = "请弃置一张梅花手牌",
	["@zhuiji-spade"] = "请弃置一张黑桃手牌",
	[":lxtx_zhuiji"] = "锁定技，你计算与其他角色的距离-1，你与体力值不大于你的角色的距离视为1；当你使用单目标伤害类牌后，你令目标非锁定技无效至回合结束时，" ..
	"然后令其进行判定，若其未弃置与判定牌花色相同的手牌，则其不能响应此牌。",
	["$lxtx_zhuiji1"] = "你们一个都别想跑！",
	["$lxtx_zhuiji2"] = "新仇旧恨，一并结算！",
	["lxtx_shichou"] = "誓仇",
	["@lxtx_shichou"] = "你可以为此牌选择额外目标",
	[":lxtx_shichou"] = "锁定技，你使用单目标伤害类牌可以多选择X名角色为目标（X为你已损失的体力值且至少为1），然后若此牌没有造成伤害，你获得之。",
	["$lxtx_shichou1"] = "以尔等之血，祭我族人！",
	["$lxtx_shichou2"] = "去地下忏悔你们的罪行吧！",
	["~lxtx_machao"] = "西凉众将离心，父仇难报......",
}
---------------------------------
--张鲁
lxtx_zhanglu = sgs.General(extension, "lxtx_zhanglu", "qun")
lxtx_yishe = sgs.CreateTriggerSkill{
	name = "lxtx_yishe",
	--global = true,
	events = {sgs.GameStart, sgs.EventPhaseChanging, sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getPile("rice"):isEmpty() and player:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName()) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(2)
			    local card_id = room:askForExchange(player, self:objectName(), 2, 2, true, "", false)
			    player:addToPile("rice", card_id)
			end
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			    if change.to ~= sgs.Player_RoundStart or p:objectName() == player:objectName() or not player:isWounded() or player:isNude() then return false end
			    local players, targets = sgs.SPlayerList(), sgs.SPlayerList()
			    for _, p in sgs.qlist(room:getAlivePlayers()) do
				    if p:getMark("zhanglu") > 0 then
				        players:append(p)
				    else
		                if p:hasSkill(self:objectName()) then
			                targets:append(p)
			            end
				    end
			    end
				local target = nil
				if not players:isEmpty() then
				    target = room:askForPlayerChosen(player, players, "lxtx_yisheAsk", "~shuangren", true, true)
				else
				    if not targets:isEmpty() then
				        target = room:askForPlayerChosen(player, targets, "lxtx_yisheAsk", "~shuangren", true, true)
					end
				end
				if not target then return false end
			    room:broadcastSkillInvoke(self:objectName())
			    local card_id = room:askForExchange(player, self:objectName(), 1, 1, true, "", false)
				p:addToPile("rice", card_id)
			    room:recover(player, sgs.RecoverStruct(player, nil, 1))
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player:hasSkill(self:objectName()) and move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceSpecial)
			and table.contains(move.from_pile_names, "rice") and player:getPile("rice"):length() == 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:recover(player, sgs.RecoverStruct(player, nil, 1))
			end
		else
		    if player:getState() == "online" and player:hasSkill(self:objectName()) then
			    room:addPlayerMark(player, "zhanglu")
			end
		end
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
lxtx_zhanglu:addSkill(lxtx_yishe)
lxtx_zhanglu:addSkill("bushi")
lxtx_zhanglu:addSkill("midao")
sgs.LoadTranslationTable{
	["lxtx_zhanglu"] = "张鲁[龙行天下]",
	["&lxtx_zhanglu"] = "张鲁",
	["#lxtx_zhanglu"] = "龙盘虎踞",
	["designer:lxtx_zhanglu"] = "俺的西木野Maki",
	["cv:lxtx_zhanglu"] = "官方",
	["illustrator:lxtx_zhanglu"] = "君桓文化", --皮肤：登坛布道
	["lxtx_yishe"] = "义舍",
	["lxtx_yisheAsk"] = "义舍送牌",
	[":lxtx_yishe"] = "锁定技，其他角色的回合开始时，若其已受伤，则其可以将一张牌置于你的武将牌上，称为“米”，然后其恢复1点体力；当你失去最后的“米”牌时，你恢复1点体力；" ..
	"回合结束时，若你武将牌上没有“米”牌，则你可以摸两张牌，然后将两张牌置于武将牌上，称为“米”。",
	["$lxtx_yishe1"] = "为义而舍，以从天道。",
	["$lxtx_yishe2"] = "尊天道，行义举。",
	["~lxtx_zhanglu"] = "抛却人生悲欢，只为道生......",
}
---------------------------------
--许攸
lxtx_xuyou = sgs.General(extension, "lxtx_xuyou", "qun+wei", 3)
lxtx_shicai = sgs.CreateTriggerSkill{
	name = "lxtx_shicai",
	--global = true,
	events = {sgs.CardUsed, sgs.CardResponded, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
		    local move = data:toMoveOneTime()
		    if not room:getTag("FirstRound"):toBool() and player:hasSkill(self:objectName()) and move.to and move.to:objectName() == player:objectName() and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW then
			    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
			    room:addPlayerMark(player, self:objectName().."engine")
			    if player:getMark(self:objectName().."engine") > 0 then  
				    for _,id in sgs.qlist(move.card_ids) do
				        room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_DrawPile)
				    end
		            for i = 0, move.card_ids:length() - 1, 1 do
				        local card_id = room:getDrawPile():last()
				        room:obtainCard(player, card_id, false)
		            end
				    room:removePlayerMark(player, self:objectName().."engine")
			    end
		    end
		else
		    local card
		    if event == sgs.CardUsed then
			    card = data:toCardUse().card
		    else
			    card = data:toCardResponse().m_card
		    end
		    if not card:isKindOf("SkillCard") and player:hasSkill(self:objectName()) and player:getMark("&"..self:objectName().."+"..card:getSuitString().."-Clear") < 1 and room:askForSkillInvoke(player, self:objectName(), data) then
			    room:broadcastSkillInvoke(self:objectName())
			    room:moveCardTo(card, player, sgs.Player_DrawPile)
			    player:drawCards(1, self:objectName())
		    	room:addPlayerMark(player, "&"..self:objectName().."+"..card:getSuitString().."-Clear")
		    end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
lxtx_chenggong = sgs.CreateTriggerSkill{
	name = "lxtx_chenggong",
	events = {sgs.CardUsed},
	--global = true,
	priority = 1,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
		    if not use.card:isKindOf("SkillCard") and use.to:length() > 1 and player:hasSkill(self:objectName()) then
			    local players = sgs.SPlayerList()
		    	players:append(use.from)
				if players:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, players, self:objectName(), self:objectName().."-invoke", true, true)
				if not target then return false end
				room:broadcastSkillInvoke(self:objectName())
				target:drawCards(1)
				if (target:objectName() ~= player:objectName() and player:getKingdom() == "qun")
				or (target:objectName() == player:objectName() and player:getKingdom() == "wei") then
					player:drawCards(1)
				end
			end
		end
	end,
	can_trigger = function(self, player)
		return player
	end,
}
lxtx_fushiCard = sgs.CreateSkillCard{
	name = "lxtx_fushi",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if sgs.Self:isLord() then
		    return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
		else
		    return #targets == 0 and to_select:isLord()
		end
	end,
	on_use = function(self, room, source, targets)
		if not targets[1]:isNude() then
		    local id = room:askForCardChosen(source, targets[1], "he", self:objectName())
		    room:obtainCard(source, id, false)
		else
		    source:drawCards(1)
		end
		local card_id = room:askForExchange(source, self:objectName(), 1, 1, true, "", false)
		room:obtainCard(targets[1], card_id, false)
	end,
}
lxtx_fushi = sgs.CreateViewAsSkill{
	name = "lxtx_fushi",
	n = 0,
	view_as = function(self, cards)
		return lxtx_fushiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#lxtx_fushi") < 1
	end,
}
lxtx_xuyou:addSkill(lxtx_shicai)
lxtx_xuyou:addSkill(lxtx_chenggong)
lxtx_xuyou:addSkill(lxtx_fushi)
sgs.LoadTranslationTable{
	["lxtx_xuyou"] = "许攸[龙行天下]",
	["&lxtx_xuyou"] = "许攸",
	["#lxtx_xuyou"] = "龙蛇飞动",
	["designer:lxtx_xuyou"] = "Maki,FC",
	["cv:lxtx_xuyou"] = "官方",
	["illustrator:lxtx_xuyou"] = "YOKO", --皮肤：盛气凌人
	["lxtx_shicai"] = "恃才",
	[":lxtx_shicai"] = "当你使用非装备牌结算完毕后或使用装备牌置入装备区之前，若此牌花色未被记录，则你可以将之置于牌堆顶，然后摸一张牌并记录此牌花色（该回合结束后清除）。" ..
	"每当你摸一张牌后，你将这些牌置于牌堆顶，然后改为依次从牌堆底获得等量的牌。",
	["$lxtx_shicai1"] = "若不是我许子远，阿瞒焉能进这邺城？",
	["$lxtx_shicai2"] = "阿瞒帐下谋臣如云，哪个有我这般功绩？",
	["lxtx_chenggong"] = "逞功",
	["lxtx_chenggong-invoke"] = "你可以发动“逞功”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	[":lxtx_chenggong"] = "当一名角色使用牌后，若目标数不少于2，你可以令其摸一张牌，" ..
	"且若该角色[不为/为]你且你为[<b><font color='grey'>群</font>/<font color='blue'>魏</font></b>]势力，你摸一张牌。",
	["$lxtx_chenggong1"] = "妙计良策，片刻既出。",
	["$lxtx_chenggong2"] = "得胜之略，已在我心中！",
	["lxtx_fushi"] = "附势",
	[":lxtx_fushi"] = "出牌阶段限一次，你可以【获得〖主公〗的一张牌】，然后交给其一张牌。" ..
	"（若你为主公，则将“〖〗”内容改为“其他角色”；若此技能发动的目标角色没有牌，则将“【】”内容改为“摸一张牌”）",
	["$lxtx_fushi1"] = "我既有功，赏赐自然要取。",
	["$lxtx_fushi2"] = "袁氏既败，天下既定！",
	["~lxtx_xuyou"] = "大胆许褚，便是你家主公也...啊！......",
}
---------------------------------
--神-周瑜＆诸葛亮
lxtx_shenzhouyuzhugeliang = sgs.General(extension, "lxtx_shenzhouyuzhugeliang", "god", 3, true, false, false, 2, 2)
lxtx_yanpoCard = sgs.CreateSkillCard{
	name = "lxtx_yanpo",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets < 1 and not to_select:isKongcheng() and sgs.Self:objectName() ~= to_select:objectName()
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local id = nil
		for _, c in sgs.qlist(self:getSubcards()) do
			room:showCard(source, c)
			room:setCardFlag(c, "lxtx_yanpo_showcard")
		end
		local n = self:subcardsLength()
		while n > 0 do
			if targets[1]:isDead() or targets[1]:isKongcheng() then return false end
			id = room:askForCardChosen(source, targets[1], "h", self:objectName())
			room:showCard(targets[1], id)
		    local card, card_id = sgs.Sanguosha:getCard(id), nil
		    if card:getSuit() == sgs.Card_Heart then
		        card_id = room:askForUseCard(source, "@@lxtx_yanpoheart", "@lxtx_yanpoheart")
		    elseif card:getSuit() == sgs.Card_Diamond then
		        card_id = room:askForUseCard(source, "@@lxtx_yanpodiamond", "@lxtx_yanpodiamond")
		    elseif card:getSuit() == sgs.Card_Spade then
		        card_id = room:askForUseCard(source, "@@lxtx_yanpospade", "@lxtx_yanpospade")
		    elseif card:getSuit() == sgs.Card_Club then
		        card_id = room:askForUseCard(source, "@@lxtx_yanpoclub", "@lxtx_yanpoclub")
		    end
		    if card_id then
		        room:damage(sgs.DamageStruct(self:objectName(), source, targets[1], 1, sgs.DamageStruct_Fire))
		    end
			n = n - 1
		end
	end,
}
lxtx_yanpo = sgs.CreateViewAsSkill{
    name = "lxtx_yanpo",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return false end
		local skillcard = lxtx_yanpoCard:clone()
		for _, c in ipairs(cards) do
			skillcard:addSubcard(c)
		end
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng() and player:usedTimes("#lxtx_yanpo") < 1
	end,
}
lxtx_yanpo_extra = sgs.CreateTriggerSkill{
	name = "lxtx_yanpo_extra",
	events = {sgs.PreCardUsed},
	frequency = sgs.Skill_Compulsory,
	global = true,
	priority = 1,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card then
				local skill = use.card:getSkillName()
				local name = use.from:getGeneralName()
				local n
				if skill == "lxtx_yanpoheart" or skill == "lxtx_yanpodiamond" or skill == "lxtx_yanpoclub" or skill == "lxtx_yanpospade" then
					room:broadcastSkillInvoke("lxtx_yanpo", 2)
					return true
				end
				if skill == "lxtx_yanpo" then
					room:broadcastSkillInvoke("lxtx_yanpo", 1)
					return true
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}
lxtx_yanpoheartCard = sgs.CreateSkillCard{
	name = "lxtx_yanpoheart",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local n, m, x = 0, 0, 0
		for _,card in sgs.qlist(source:getHandcards()) do
		    if card:getSuit() == sgs.Card_Diamond then
			    n = 1
			end
		    if card:getSuit() == sgs.Card_Club then
			    m = 1
			end
		    if card:getSuit() == sgs.Card_Spade then
			    x = 1
			end
		end
		source:drawCards(n + m + x)
	end,
}
lxtx_yanpoheart = sgs.CreateViewAsSkill{
	name = "lxtx_yanpoheart",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Heart and to_select:hasFlag("lxtx_yanpo_showcard")
	end,
	view_as = function(self, cards)
		if #cards == 0 then return false end
		local new_card = lxtx_yanpoheartCard:clone()	
		for _, c in ipairs(cards) do
			new_card:addSubcard(c)
		end
		new_card:setSkillName(self:objectName())
		return new_card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@lxtx_yanpoheart")
	end,
}
lxtx_yanpodiamondCard = sgs.CreateSkillCard{
	name = "lxtx_yanpodiamond",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local n, m, x = 0, 0, 0
		for _,card in sgs.qlist(source:getHandcards()) do
		    if card:getSuit() == sgs.Card_Club then
			    n = 1
			end
		    if card:getSuit() == sgs.Card_Spade then
			    m = 1
			end
		    if card:getSuit() == sgs.Card_Heart then
			    x = 1
			end
		end
		source:drawCards(n + m + x)
	end,
}
lxtx_yanpodiamond = sgs.CreateViewAsSkill{
	name = "lxtx_yanpodiamond",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Diamond and to_select:hasFlag("lxtx_yanpo_showcard")
	end,
	view_as = function(self, cards)
		if #cards == 0 then return false end
		local new_card = lxtx_yanpospadeCard:clone()	
		for _, c in ipairs(cards) do
			new_card:addSubcard(c)
		end
		new_card:setSkillName(self:objectName())
		return new_card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@lxtx_yanpodiamond")
	end,
}
lxtx_yanpoclubCard = sgs.CreateSkillCard{
	name = "lxtx_yanpoclub",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local n, m, x = 0, 0, 0
		for _,card in sgs.qlist(source:getHandcards()) do
		    if card:getSuit() == sgs.Card_Spade then
			    n = 1
			end
		    if card:getSuit() == sgs.Card_Heart then
			    m = 1
			end
		    if card:getSuit() == sgs.Card_Diamond then
			    x = 1
			end
		end
		source:drawCards(n + m + x)
	end,
}
lxtx_yanpoclub = sgs.CreateViewAsSkill{
	name = "lxtx_yanpoclub",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Club and to_select:hasFlag("lxtx_yanpo_showcard")
	end,
	view_as = function(self, cards)
		if #cards == 0 then return false end
		local new_card = lxtx_yanpoclubCard:clone()	
		for _, c in ipairs(cards) do
			new_card:addSubcard(c)
		end
		new_card:setSkillName(self:objectName())
		return new_card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@lxtx_yanpoclub")
	end,
}
lxtx_yanpospadeCard = sgs.CreateSkillCard{
	name = "lxtx_yanpospade",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local n, m, x = 0, 0, 0
		for _,card in sgs.qlist(source:getHandcards()) do
		    if card:getSuit() == sgs.Card_Heart then
			    n = 1
			end
		    if card:getSuit() == sgs.Card_Diamond then
			    m = 1
			end
		    if card:getSuit() == sgs.Card_Club then
			    x = 1
			end
		end
		source:drawCards(n + m + x)
	end,
}
lxtx_yanpospade = sgs.CreateViewAsSkill{
	name = "lxtx_yanpospade",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Spade and to_select:hasFlag("lxtx_yanpo_showcard")
	end,
	view_as = function(self, cards)
		if #cards == 0 then return false end
		local new_card = lxtx_yanpospadeCard:clone()	
		for _, c in ipairs(cards) do
			new_card:addSubcard(c)
		end
		new_card:setSkillName(self:objectName())
		return new_card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "@@lxtx_yanpospade")
	end,
}
if not sgs.Sanguosha:getSkill("lxtx_yanpo_extra") then skills:append(lxtx_yanpo_extra) end
if not sgs.Sanguosha:getSkill("lxtx_yanpoheart") then skills:append(lxtx_yanpoheart) end
if not sgs.Sanguosha:getSkill("lxtx_yanpodiamond") then skills:append(lxtx_yanpodiamond) end
if not sgs.Sanguosha:getSkill("lxtx_yanpoclub") then skills:append(lxtx_yanpoclub) end
if not sgs.Sanguosha:getSkill("lxtx_yanpospade") then skills:append(lxtx_yanpospade) end
lxtx_shenzhouyuzhugeliang:addSkill(lxtx_yanpo)
sgs.LoadTranslationTable{
	["lxtx_shenzhouyuzhugeliang"] = "神-周瑜＆诸葛亮[龙行天下]",
	["&lxtx_shenzhouyuzhugeliang"] = "神瑜亮",
	["#lxtx_shenzhouyuzhugeliang"] = "龙凤呈祥",
	["designer:lxtx_shenzhouyuzhugeliang"] = "Maki,FC",
	["cv:lxtx_shenzhouyuzhugeliang"] = "官方",
	["illustrator:lxtx_shenzhouyuzhugeliang"] = "君桓文化", --皮肤：合纵破曹
	["information:lxtx_shenzhouyuzhugeliang"] = "李太白有诗赞曰：\
	二龙争战决雌雄，赤壁楼船扫地空；烈火初张照云海，周瑜曾此破曹公。\
	鱼水三顾合，风云四海生；武侯立岷蜀，壮志吞咸京。",
	["lxtx_yanpo"] = "焰破",
	["lxtx_yanpoheart"] = "焰破",
	["lxtx_yanpodiamond"] = "焰破",
	["lxtx_yanpospade"] = "焰破",
	["lxtx_yanpoclub"] = "焰破",
	["@lxtx_yanpoheart"] = "请弃置一张红桃牌",
	["@lxtx_yanpodiamond"] = "请弃置一张方块牌",
	["@lxtx_yanpospade"] = "请弃置一张黑桃牌",
	["@lxtx_yanpoclub"] = "请弃置一张梅花牌",
	[":lxtx_yanpo"] = "出牌阶段限一次，你可以选择一名有手牌的角色并展示任意张手牌，【然后展示该角色的一张手牌：" ..
	"若你展示的牌中有与其展示的牌花色相同的牌，则你可以弃置其中一张，对其造成1点火焰伤害】，然后重复“【】”内的流程直到累计执行X次（X为你展示的牌数）。" ..
	"你每以此法弃置一张牌，摸取手牌中与你弃置的牌花色不同的牌数。",
	["$lxtx_yanpo1"] = "神火天降，樯橹灰飞烟灭！", --神周瑜（对应展示）
	["$lxtx_yanpo2"] = "巧用星象，则万事可成！", --卧龙诸葛（对应弃牌）
	["~lxtx_shenzhouyuzhugeliang"] = "弦断人陨，环佩空鸣....../再不能，临阵讨贼矣......",
}
---------------------------------
sgs.Sanguosha:addSkills(skills)
---------------------------------
return {extension}