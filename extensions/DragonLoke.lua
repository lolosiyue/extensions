extension = sgs.Package("DragonLoke", sgs.Package_GeneralPack)
---------------------------------
sgs.LoadTranslationTable{
    ["DragonLoke"] = "龙飞腾天",
    ["_dl_xumoucard"] = "蓄谋牌",
}
---------------------------------
local skills = sgs.SkillList()
---------------------------------
dl_chenqun = sgs.General(extension, "dl_chenqun", "qun", 3, true)
dl_chajuCard = sgs.CreateSkillCard{
	name = "dl_chaju",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	on_use = function(self, room, player, targets)
		local to = targets[1] 
		room:showAllCards(to, player)
		if player:getHandcardNum() ~= to:getHandcardNum() then
		    local target = nil
			if player:getHandcardNum() > to:getHandcardNum() then
			    target = to
			elseif player:getHandcardNum() < to:getHandcardNum() then
			    target = player
			end
			if target then
			    if player:getHandcardNum() > to:getHandcardNum() then
			        room:addPlayerMark(player, "&dl_chaju_add")
			    end
			    local card_id = room:askForExchange(player, self:objectName(), target:getHandcardNum(), 1, false, "", false)
			    local id = room:askForExchange(to, self:objectName(), target:getHandcardNum(), 1, false, "", false)
			    room:obtainCard(player, id, false)
			    room:obtainCard(to, card_id, false)
			end
		else
			local dest = sgs.QVariant()
			dest:setValue(player)
		    local choice = room:askForChoice(to, self:objectName(), "1+2", dest)
			if choice == "1" then
			    local card_id = room:askForExchange(player, self:objectName(), to:getHandcardNum(), 1, false, "", false)
			    local id = room:askForExchange(to, self:objectName(), player:getHandcardNum(), 1, false, "", false)
			    room:obtainCard(player, id, false)
			    room:obtainCard(to, card_id, false)
			else
			    room:throwCard(player:wholeHandCards(), player, nil)
			    room:throwCard(to:wholeHandCards(), to, nil)
				player:drawCards(player:getMaxHp() - player:getHandcardNum())
				to:drawCards(to:getMaxHp() - to:getHandcardNum())
				room:addPlayerMark(player, "&dl_chaju_remove")
			end
		end
	end,
}
dl_chajuvs = sgs.CreateZeroCardViewAsSkill{
	name = "dl_chaju",
    view_as = function()
		return dl_chajuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#dl_chaju") and not player:isKongcheng() and player:getMark("dl_chaju_success") == 0 and player:getMark("dl_chaju_fail") == 0
	end,
}
dl_chaju = sgs.CreateTriggerSkill{
	name = "dl_chaju",
    shiming_skill = true,
	view_as_skill = dl_chajuvs,
	events = {sgs.Dying, sgs.EventPhaseEnd, sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish and (player:getMark("&dl_chaju_add") >= 3 or player:getMark("&dl_chaju_remove") >= 3) and player:getMark("dl_chaju_success") == 0 and player:getMark("dl_chaju_fail") == 0 then
				room:sendShimingLog(player, self)
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
		        room:acquireSkill(player, "dl_pindi")
		        room:acquireSkill(player, "faen")
			    room:setPlayerProperty(player, "kingdom", sgs.QVariant("shu"))
		        room:setPlayerMark(player, "&dl_chaju_add", 0)
		        room:setPlayerMark(player, "&dl_chaju_remove", 0)
			    room:addPlayerMark(player, "dl_chaju_success")
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(), "dl_chaju") then
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			end
		else
			local who = room:getCurrentDyingPlayer()
		    if not who or who:objectName() ~= player:objectName() or not who:hasSkill(self:objectName()) or who:getMark("dl_chaju_success") > 0 or who:getMark("dl_chaju_fail") > 0 then return false end
		    room:sendShimingLog(player, self, false)
			room:broadcastSkillInvoke(self:objectName(), 3)
		    local recover = math.min(1- player:getHp(), player:getMaxHp() - player:getHp())
		    room:recover(player, sgs.RecoverStruct(player, nil, recover))
		    room:acquireSkill(player, "dingpin")
		    room:acquireSkill(player, "faen")
			room:setPlayerProperty(player, "kingdom", sgs.QVariant("wei"))
		    room:setPlayerMark(player, "&dl_chaju_add", 0)
		    room:setPlayerMark(player, "&dl_chaju_remove", 0)
			room:addPlayerMark(player, "dl_chaju_fail")
		end
	end,
}
dl_pindiCard = sgs.CreateSkillCard{
	name = "dl_pindi",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local marks = {"upup", "upover", "updown", "overup", "overover", "overdown", "downup", "downover", "downdown"}
		for _, p in sgs.qlist(room:getAlivePlayers()) do
		    local mark = marks[math.random(1, #marks)]
			p:gainMark("&dl_"..mark)
		end
	end,
}
dl_pindi = sgs.CreateZeroCardViewAsSkill{
	name = "dl_pindi",
    view_as = function()
		return dl_pindiCard:clone()
	end,
	enabled_at_play = function(self, player)
	    return player:usedTimes("#dl_pindi") < 1
	end,
}
dl_pindi_extra = sgs.CreateTriggerSkill{
	name = "dl_pindi_extra",
	global = true,
	events = {sgs.MarkChanged, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "&dl_upup" and mark.who:getMark(mark.name) >= 1 then
		    	mark.who:drawCards(3)
			elseif mark.name == "&dl_upover" and mark.who:getMark(mark.name) >= 1 then
		    	mark.who:drawCards(2)
			elseif mark.name == "&dl_updown" and mark.who:getMark(mark.name) >= 1 then
		    	mark.who:drawCards(1)
			elseif mark.name == "&dl_overup" and mark.who:getMark(mark.name) >= 1 and not mark.who:isNude() then
		    	local card_id = room:askForExchange(mark.who, self:objectName(), 3, 1, true, "", false)
				for _, id in sgs.qlist(card_id:getSubcards()) do
				    room:moveCardTo(sgs.Sanguosha:getCard(id), mark.who, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, mark.who:objectName(), self:objectName(), ""))
		        end
		        mark.who:drawCards(card_id:getSubcards():length(), "recast")
			elseif mark.name == "&dl_overover" and mark.who:getMark(mark.name) >= 1 and not mark.who:isNude() then
		    	local card_id = room:askForExchange(mark.who, self:objectName(), 2, 1, true, "", false)
				for _, id in sgs.qlist(card_id:getSubcards()) do
				    room:moveCardTo(sgs.Sanguosha:getCard(id), mark.who, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, mark.who:objectName(), self:objectName(), ""))
		        end
		        mark.who:drawCards(card_id:getSubcards():length(), "recast")
			elseif mark.name == "&dl_overdown" and mark.who:getMark(mark.name) >= 1 and not mark.who:isNude() then
		    	local card_id = room:askForExchange(mark.who, self:objectName(), 1, 1, true, "", false)
				for _, id in sgs.qlist(card_id:getSubcards()) do
				    room:moveCardTo(sgs.Sanguosha:getCard(id), mark.who, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, mark.who:objectName(), self:objectName(), ""))
		        end
		        mark.who:drawCards(card_id:getSubcards():length(), "recast")
			elseif mark.name == "&dl_downup" and mark.who:getMark(mark.name) >= 1 and not mark.who:isNude() then
		    	room:askForDiscard(mark.who, self:objectName(), 1, 1, false, true)
			elseif mark.name == "&dl_downover" and mark.who:getMark(mark.name) >= 1 and not mark.who:isNude() then
		    	room:askForDiscard(mark.who, self:objectName(), 2, 2, false, true)
			elseif mark.name == "&dl_downdown" and mark.who:getMark(mark.name) >= 1 and not mark.who:isNude() then
		    	room:askForDiscard(mark.who, self:objectName(), 3, 3, false, true)
			end
		else
		    if player:getPhase() == sgs.Player_Finish then
		    	local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAllPlayers(true)) do
			    	if p:getMark("&dl_upup") > 0 or p:getMark("&dl_upover") > 0 or p:getMark("&dl_updown") > 0 or p:getMark("&dl_overip") > 0 or p:getMark("&dl_overover") > 0
					or p:getMark("&dl_overdown") > 0 or p:getMark("&dl_downup") > 0 or p:getMark("&dl_downover") > 0 or p:getMark("&dl_downdown") > 0 then
				    	players:append(p)
			    	end
				end
				if not players:isEmpty() then
					for _, p in sgs.qlist(room:findPlayersBySkillName("dl_pindi")) do
					    room:sendCompulsoryTriggerLog(p, "dl_pindi")
			            room:broadcastSkillInvoke("dl_pindi")
					end
					local n = players:length()
					while n > 0 do
					    for _, splayer in sgs.qlist(players) do
						    local choice = room:askForChoice(splayer, "dl_pindi", "1+2")
							if choice == "1" then
							    room:setPlayerChained(splayer)
							else
							    splayer:turnOver()
							end
							players:removeOne(splayer)
						end
						n = n - 1
					end
				end
			elseif player:getPhase() == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAllPlayers(true)) do
			    	if p:getMark("&dl_upup") > 0 then
				    	room:setPlayerMark(p, "&dl_upup", 0)
			    	end
			    	if p:getMark("&dl_upover") > 0 then
				    	room:setPlayerMark(p, "&dl_upover", 0)
			    	end
			    	if p:getMark("&dl_updown") > 0 then
				    	room:setPlayerMark(p, "&dl_updown", 0)
			    	end
			    	if p:getMark("&dl_overup") > 0 then
				    	room:setPlayerMark(p, "&dl_overup", 0)
			    	end
			    	if p:getMark("&dl_overover") > 0 then
				    	room:setPlayerMark(p, "&dl_overover", 0)
			    	end
			    	if p:getMark("&dl_overdown") > 0 then
				    	room:setPlayerMark(p, "&dl_overdown", 0)
			    	end
			    	if p:getMark("&dl_downup") > 0 then
				    	room:setPlayerMark(p, "&dl_downup", 0)
			    	end
			    	if p:getMark("&dl_downover") > 0 then
				    	room:setPlayerMark(p, "&dl_downover", 0)
			    	end
			    	if p:getMark("&dl_downdown") > 0 then
				    	room:setPlayerMark(p, "&dl_downdown", 0)
			    	end
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
if not sgs.Sanguosha:getSkill("dl_pindi_extra") then skills:append(dl_pindi_extra) end
dl_chenqun:addSkill(dl_chaju)
if not sgs.Sanguosha:getSkill("dl_pindi") then skills:append(dl_pindi) end
dl_chenqun:addRelateSkill("dl_pindi")
dl_chenqun:addRelateSkill("newdingpin")
dl_chenqun:addRelateSkill("faen")
sgs.LoadTranslationTable{
	["dl_chenqun"] = "陈群",
	["designer:dl_chenqun"] = "Maki",
	["#dl_chenqun"] = "握卷之臣",
	["illustrator:dl_chenqun"] = "",
	["dl_chaju"] = "察举",
	["dl_chaju:1"] = "交换至少一张手牌",
	["dl_chaju:2"] = "各弃置所有手牌",
	["dl_chaju_add"] = "察举选项1",
	["dl_chaju_remove"] = "察举选项2",
	[":dl_chaju"] = "使命技，出牌阶段限一次，若你有手牌，则你可以选择一名有手牌的其他角色的手牌，然后若两方手牌数不相等，则各交换至多X张手牌（X为手牌数较少的一方的手牌数），否则其选择一项：1.交换至少一张手牌；2.各弃置所有手牌，然后将手牌补至体力上限。\
	成功：回合结束后，若一名角色成为过“察举”选项2的目标至少三次或一名角色一名角色成为过“察举”选项1的目标至少三次且每次目标角色的手牌数均小于你的手牌数，则使命成功，获得“定品”和“法恩”并将势力修改为“蜀”；\
	失败：若你在成功达成使命前进入濒死状态，则使命失效，然后你将体力值回复至1点，获得“品第”和“法恩”并将势力修改为“魏”。",
	["$dl_chaju1"] = "观其风气，察其品行。",
	["$dl_chaju2"] = "推举贤才，兴盛大魏。",
	["$dl_chaju3"] = "三朝如一日，弹指一挥间。",
	["dl_pindi"] = "品第",
	["dl_upup"] = "上上",
	["dl_upover"] = "上中",
	["dl_updown"] = "上下",
	["dl_overup"] = "中上",
	["dl_overover"] = "中中",
	["dl_overdown"] = "中下",
	["dl_downup"] = "下上",
	["dl_downover"] = "下中",
	["dl_downdown"] = "下下",
	["dl_pindi:1"] = "横置",
	["dl_pindi:2"] = "翻面",
	[":dl_pindi"] = "出牌阶段限一次，你可以令所有角色随机获得一个“九品中正制”的品级。\
	上上：摸三张牌；上中：摸两张牌；上下：摸一张牌；\
	中上：重铸至多三张牌；中中：重铸至多两张牌；中下：重铸至多一张牌；\
	下上：弃置一张牌；下中：弃置两张牌；下下：弃置三张牌。回合结束时，你令所有成为过“品第”目标的角色选择一项：1.横置；2.翻面。",
	["$dl_pindi1"] = "王法威仪，恩泽天下。",
	["$dl_pindi2"] = "法外有情，恩威并举。",
	["~dl_chenqun"] = "吾身虽陨，典律昭昭……",
}
---------------------------------
dl_daqiao = sgs.General(extension, "dl_daqiao", "wu", 3, false)
--[[DlXumouCard = sgs.CreateTrickCard{
	name = "_dl_xumoucard",
	class_name = "DlXumouCard",
	subtype = "delayed_trick",--卡牌的子类型
	subclass = sgs.LuaTrickCard_TypeDelayedTrick,--卡牌的类型 延时锦囊
	target_fixed = true,
	can_recast = false,
	is_cancelable = false,
	movable = false,
	damage_card = false,
}
DlXumouCard:setParent(extension)]]
dl_yanxiaoCard = sgs.CreateSkillCard{
	name = "dl_yanxiao",
	target_fixed = true,
	will_throw = false,
	about_to_use = function(self, room, use)
		room:addPlayerMark(use.from, self:objectName().."engine")
		if use.from:getMark(self:objectName().."engine") > 0 then
			local c = sgs.Sanguosha:getCard(self:getSubcards():first())
			-- local card = sgs.Sanguosha:cloneCard("_dl_xumoucard", c:getSuit(), c:getNumber())
			-- card:addSubcard(c:getEffectiveId())
			-- card:setSkillName(self:getSkillName())
			-- room:useCard(sgs.CardUseStruct(card, use.from, use.from), true)
			-- room:recover(use.from, sgs.RecoverStruct(use.from))
			xumouCard(use.from,c)
			room:removePlayerMark(use.from, self:objectName().."engine")
		end
	end

}
dl_yanxiaovs = sgs.CreateOneCardViewAsSkill{
	name = "dl_yanxiao",
	filter_pattern = ".|red",
	view_as = function(self, originalCard)
		local yanxiao = dl_yanxiaoCard:clone()
		yanxiao:addSubcard(originalCard:getId())
		yanxiao:setSkillName(self:objectName())
		return yanxiao
	end,
	enabled_at_play = function(self, player)
		local can_invoke = true
		for _,c in sgs.qlist(player:getJudgingArea())do
			if string.find(c:objectName(),"kehexumou") then 
				can_invoke = false
				break
			end
		end
		return can_invoke 
	end
}
dl_yanxiao = sgs.CreateTriggerSkill{
	name = "dl_yanxiao",
	view_as_skill = dl_yanxiaovs,
	events = {sgs.EventPhaseStart, sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
		    if player:getPhase() == sgs.Player_Judge then
				local can_invoke = false
				for _,c in sgs.qlist(player:getJudgingArea())do
					if string.find(c:objectName(),"xumou") then
						can_invoke = true
						break
					end
				end
				if can_invoke then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					for _,card in sgs.qlist(player:getJudgingArea()) do
						if card:isKindOf("Xumou") then
							room:setPlayerMark(player, "dl_yanxiao", 1)
							room:obtainCard(player, card, true)			
						else
							room:throwCard(card, player, nil)
						end						
					end
				end
			end		
        else
		    local draw = data:toDraw()
			if draw.reason ~= "draw_phase" or player:getMark("dl_yanxiao") == 0 then return false end
			room:sendCompulsoryTriggerLog(player, self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			local n = player:getMark("dl_yanxiao")
			room:setPlayerMark(player, "dl_yanxiao", 0)
			draw.num = draw.num + n
			data:setValue(draw)
		end
	end,
}
dl_liuliCard = sgs.CreateSkillCard{
	name = "dl_liuli",
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:getMark("dl_liuli_usefrom") < 1 and sgs.Self:distanceTo(to_select) <= sgs.Self:getAttackRange()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(targets[1], "dl_liuli_useto", 1)
	end,
}
dl_liulivs = sgs.CreateViewAsSkill{
	name = "dl_liuli",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local skillcard = dl_liuliCard:clone()
			for _, c in ipairs(cards) do
				skillcard:addSubcard(c)
			end
			return skillcard
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@dl_liuli"
	end,
}
dl_liuli = sgs.CreateTriggerSkill{
	name = "dl_liuli" ,
	events = {sgs.TargetConfirming} ,
	view_as_skill = dl_liulivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and (use.card:isKindOf("Xumou") or use.card:isKindOf("Slash")) and not player:isNude() and use.to:contains(player) then
			room:setTag("dl_liuli", data)
			room:setPlayerMark(use.from, "dl_liuli_usefrom", 1)
			local invoke = room:askForUseCard(player, "@@dl_liuli", "dl_liuli-invoke")
			room:setPlayerMark(use.from, "dl_liuli_usefrom", 0)
			room:removeTag("dl_liuli")
			if not invoke then return false end
			use.to:removeOne(player)
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			    if p:getMark("dl_liuli_useto") > 0 then
			        room:setPlayerMark(p, "dl_liuli_useto", 0)
					use.to:append(p)
				end
			end
			room:sortByActionOrder(use.to)
			data:setValue(use)
		end
		return false
	end
}
dl_yanxiao_extra = sgs.CreateMaxCardsSkill{
	name = "dl_yanxiao_extra",
	extra_func = function(self, player)
		local n = 0
		if player:hasSkill("dl_yanxiao") then
		    for _,card in sgs.qlist(player:getJudgingArea()) do
				if card:isKindOf("Xumou") then
				    n = n + 1
		        end
			end
		end
		return n
	end,
}
if not sgs.Sanguosha:getSkill("dl_yanxiao_extra") then skills:append(dl_yanxiao_extra) end
dl_daqiao:addSkill(dl_yanxiao)
dl_daqiao:addSkill(dl_liuli)
sgs.LoadTranslationTable{
	["dl_daqiao"] = "大乔",
	["#dl_daqiao"] = "国色芳华",
	["designer:dl_daqiao"] = "Maki",
	["cv:dl_daqiao"] = "官方",
	["illustrator:dl_daqiao"] = "佚名",
	["dl_yanxiao"] = "言笑",
	[":dl_yanxiao"] = "出牌阶段，若你的判定区没有蓄谋牌，则你可以将一张红色牌当蓄谋牌置于你的判定区；判定阶段开始时，若你的判定区内有蓄谋牌，则你获得蓄谋牌并弃置所有判定区内的延时类锦囊牌。你的手牌上限+1，你的额定摸牌数+1。",
	["$dl_yanxiao1"] = "倾心一笑，愿君驻足。",
	["$dl_yanxiao2"] = "英雄壮志，红颜无怨。",
	["dl_liuli"] = "流离",
	["dl_liuli-invoke"] = "你可以发动“流离”<br/> <b>操作提示</b>: 选择一张牌→选择一名攻击范围内的角色→点击确定<br/>",
	[":dl_liuli"] = "当你成为一张【杀】或蓄谋牌的目标后，你可以弃置一张牌并令此牌指定你攻击范围内的一名其他角色。（不能为此牌的使用者）",
	["$dl_liuli1"] = "光彩照人，仍敌不过岁月流年。",
	["$dl_liuli2"] = "流离天香色，最美少年时。",
	["~dl_daqiao"] = "恨不能，常侍君左右……",
}
---------------------------------
sgs.Sanguosha:addSkills(skills)
---------------------------------
return {extension}