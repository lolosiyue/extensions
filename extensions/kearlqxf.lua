--==《新武将》==--
extension_lq = sgs.Package("kearlqxf", sgs.Package_GeneralPack)

--buff集中
kelqxfslashmore = sgs.CreateTargetModSkill{
	name = "kelqxfslashmore",
	pattern = ".",
	residue_func = function(self, from, card, to)
		if table.contains(card:getSkillNames(), "kelqjuesui")
		then return 999 end
		if to and to:getHandcardNum()<1 and from:hasSkill("tyzhuiling")
		then return 999 end
		if to and from:hasSkill("tyxiongren") and to:distanceTo(from)<=1
		then return 999 end
		return 0
	end,
	extra_target_func = function(self, from, card)
		local n = 0
		if card:isKindOf("Slash") and card:getSuit() == sgs.Card_Heart and from:hasSkill("kelqjunshen")
		then n = n + 1 end
		return n
	end,
	distance_limit_func = function(self, from, card, to)
		if card:isKindOf("Slash") then
			if card:getSuit() == sgs.Card_Diamond and from:hasSkill("kelqjunshen")
			then return 999 end
			if from:getMark("tylengjianUse2-Clear")<1 and from:hasSkill("tylengjian")
			and not from:inMyAttackRange(to) then return 999 end
			if table.contains(card:getSkillNames(), "tyxingsha")
			then return 999 end
		end
		if to and to:getMark("&ty2chengshi+#"..from:objectName().."_lun")>1
		then return 999 end
		if to and to:getHandcardNum()<1 and from:hasSkill("tyzhuiling")
		then return 999 end
		if from:hasSkill("tyxiongren") and to and to:distanceTo(from)<=1
		then return 999 end
		return 0
	end
}
extension_lq:addSkills(kelqxfslashmore)


kelqguanyu = sgs.General(extension_lq, "kelqguanyu", "shu", 4)

kelqchaojue = sgs.CreateTriggerSkill{
	name = "kelqchaojue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging,sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	    if (event == sgs.Death) then
			local death = data:toDeath()
			local pattern = death.who:getTag("kelqchaojueLimitation"):toString()
			death.who:removeTag("kelqchaojueLimitation")
			for _, p in sgs.qlist(room:getAllPlayers()) do 
				if pattern~="" then
					room:removePlayerCardLimitation(p,"use,response",pattern)
				end
				local n = p:getMark(death.who:objectName().."kelqchaojue-Clear")
				if n > 0 then
					room:setPlayerMark(p,death.who:objectName().."kelqchaojue-Clear",0)
					room:removePlayerMark(p,"@skill_invalidity",n)
				end
			end
		end
		if (event == sgs.EventPhaseChanging) then
		    local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				local pattern = player:getTag("kelqchaojueLimitation"):toString()
				player:removeTag("kelqchaojueLimitation")
				for _, p in sgs.qlist(room:getAllPlayers()) do 
					if pattern~="" then
						room:removePlayerCardLimitation(p,"use,response",pattern)
					end
					local n = p:getMark(player:objectName().."kelqchaojue-Clear")
					if n > 0 then
						room:setPlayerMark(p,player:objectName().."kelqchaojue-Clear",0)
						room:removePlayerMark(p,"@skill_invalidity",n)
					end
				end
			end
		end
		if event == sgs.EventPhaseStart
        and player:getPhase() == sgs.Player_Start
        and player:isAlive() and player:hasSkill(self) then
            local discid = room:askForDiscard(player, self:objectName(), 1, 1, true, false, "kelqchaojueask", ".", self:objectName())
			if discid then
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerMark(player,"&kelqchaojue+:+"..discid:getSuitString().."_char-Clear",1)
				player:setTag("kelqchaojueLimitation",ToData(".|"..discid:getSuitString()))
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					room:setPlayerCardLimitation(p,"use,response",".|"..discid:getSuitString(),false)
					local todis = room:askForExchange(p, "kelqchaojue_show", 1, 1, false, "kelqchaojue_show:"..player:objectName().."::"..discid:getSuitString(),true, ".|"..discid:getSuitString())
					if todis then
						room:showCard(p,todis:getEffectiveId())
						room:giveCard(p,player,todis,self:objectName())
					else
						room:addPlayerMark(p,player:objectName().."kelqchaojue-Clear")
						room:addPlayerMark(p,"@skill_invalidity")
					end
				end  	    
            end					
		end
	end,
	can_trigger = function(self, player)
	    return player
	end,
}
kelqguanyu:addSkill(kelqchaojue)

kelqjunshenVS = sgs.CreateOneCardViewAsSkill{
	name = "kelqjunshen",
	response_or_use = true,
	view_filter = function(self, card)
		if not card:isRed() then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:setSkillName("kelqjunshen")
			slash:addSubcard(card)
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("kelqjunshen")
		slash:addSubcard(card)
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end
}

kelqjunshen = sgs.CreateTriggerSkill{
	name = "kelqjunshen",
	view_as_skill = kelqjunshenVS,
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DamageCaused) then
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),"kelqjunshen") then
				if damage.to:canDiscard(damage.to,"e") and room:askForChoice(damage.to,"kelqjunshen","qizhi+jiashang")=="qizhi" then
					damage.to:throwAllEquips("kelqjunshen")
				else
					damage.damage = damage.damage + 1
					data:setValue(damage)
				end
			end
		end	
	end,
}
kelqguanyu:addSkill(kelqjunshen)

sgs.LoadTranslationTable{
    ["kearlqxf"] = "龙起襄樊",

	["kelqguanyu"] = "关羽[龙]", 
	["&kelqguanyu"] = "关羽",
	["#kelqguanyu"] = "国士无双",
	["designer:kelqguanyu"] = "官方",
	["cv:kelqguanyu"] = "官方",
	["illustrator:kelqguanyu"] = "鬼画府",

	["kelqchaojue"] = "超绝",
	[":kelqchaojue"] = "准备阶段，你可以弃置一张手牌令所有其他角色本回合不能使用或打出与之花色相同的牌，然后这些角色依次选择一项：1.展示并交给你一张与此牌花色相同的手牌；2.其本回合所有非锁定技失效。",
	["kelqchaojueask"] = "超绝：你可以弃置一张手牌令所有其他角色本回合不能使用或打出与之花色相同的牌",
	["kelqchaojue_show"] = "超绝：你展示并交给%src一张%arg手牌；否则你本回合所有非锁定技失效",

	["kelqjunshen"] = "军神",
	[":kelqjunshen"] = "你可以将一张红色牌当【杀】使用或打出，当你以此法使用的【杀】对一名角色造成伤害时，其选择一项：1.弃置装备区里的所有牌；2.令此伤害+1。你使用的♦【杀】无距离限制、♥【杀】的目标数限制+1。",
	["kelqjunshen:qizhi"] = "弃置装备区的所有牌",
	["kelqjunshen:jiashang"] = "此伤害+1",
	[":kelqjunshen"] = "你可以将一张红色牌当【杀】使用或打出，当你以此法使用的【杀】对一名角色造成伤害时，其选择一项：1.弃置装备区里的所有牌；2.令此伤害+1。你使用的♦【杀】无距离限制、♥【杀】的目标数限制+1。",


	["$kelqchaojue1"] = "逃归君父，振古通义。",
	["$kelqchaojue2"] = "同休等戚，祸福共之。",
	["$kelqjunshen1"] = "将帅讲武，习射御角力！",
	["$kelqjunshen2"] = "万众之中，斩汝首而还。",

	["~kelqguanyu"] = "良将不怯死以苟免。",
}

kelqcaoren = sgs.General(extension_lq, "kelqcaoren", "wei", 4)

kelqlizhongcard = sgs.CreateSkillCard{
	name = "kelqlizhongcard",
	will_throw = false,
	filter = function(self,targets,to_selec,source)
		if self:subcardsLength()>0 then
			if self:subcardsLength()>#targets then
				local id = self:getSubcards():at(#targets)
				local n = sgs.Sanguosha:getCard(id):getRealCard():toEquipCard():location()
				return to_selec:hasEquipArea(n) and to_selec:getEquip(n)==nil
			end
		else
			if #targets>0 then
				return targets[1]:hasEquip() and to_selec:hasEquip()
			else
				return to_selec==source
				or to_selec:hasEquip()
			end
		end
	end,
	feasible = function(self,targets)
		if self:subcardsLength()>0 then
			return self:subcardsLength()==#targets
		else
			return #targets>0
		end
	end,
	about_to_use = function(self,room,use)
		use.from:setTag("kelqlizhongUse",ToData(use))
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,source,targets)
		local use = source:getTag("kelqlizhongUse"):toCardUse()
		for i,to in sgs.list(use.to)do
			if self:subcardsLength()>0 then
				room:setPlayerMark(source,"kelqlizhong1",1)
				local id = self:getSubcards():at(i)
				local c = sgs.Sanguosha:getCard(id)
				id = c:getRealCard():toEquipCard():location()
				if to:isAlive() and to:hasEquipArea(id) then
					room:moveCardTo(c,to,sgs.Player_PlaceEquip)
				end
			else
				room:setPlayerMark(source,"kelqlizhong1",2)
				to:drawCards(1,self:getSkillName())
				room:addMaxCards(to,2,false)
				room:attachSkillToPlayer(to,"kelqlizhongUse")
			end
		end
	end,
}
kelqlizhongvs = sgs.CreateViewAsSkill{
	name = "kelqlizhong",
	n = 998,
	view_filter = function(self,selected,to_select)
		return to_select:isKindOf("EquipCard")
		and sgs.Self:getMark("kelqlizhong1")~=1
	end,
	view_as = function(self,cards)
		if sgs.Self:getMark("kelqlizhong1")==2
		and #cards<1 then return end
		local new_card = kelqlizhongcard:clone()
		for _,c in ipairs(cards)do
			new_card:addSubcard(c)
		end
		return new_card
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern=="@@kelqlizhong"
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
kelqlizhong = sgs.CreateTriggerSkill{
	name = "kelqlizhong",
	view_as_skill = kelqlizhongvs,
	events = {sgs.EventPhaseStart,sgs.RoundEnd},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:hasSkill(self) then
			for i=1,2 do
				local pn = "kelqlizhong1"
				if i>1 then
					if player:getMark("kelqlizhong1")>0 then pn = "kelqlizhong3"
					else pn = "kelqlizhong2" end
				end
				if not room:askForUseCard(player,"@@kelqlizhong","kelqlizhong0:"..pn,-1,sgs.Card_MethodNone)
				then break end
			end
			room:setPlayerMark(player,"kelqlizhong1",0)
		elseif event == sgs.RoundEnd and player:hasSkill("kelqlizhongUse",true) then
			room:addMaxCards(player,-2,false)
			room:detachSkillFromPlayer(player,"kelqlizhongUse",true,true)
		end
	end,
}
kelqcaoren:addSkill(kelqlizhong)
kelqlizhongUse = sgs.CreateViewAsSkill{
	name = "kelqlizhongUse&",
	n = 1,
	view_filter = function(self,selected,to_select)
		return to_select:isEquipped()
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local new_card = sgs.Sanguosha:cloneCard("nullification")
		new_card:setSkillName("_kelqlizhong")
		for _,c in ipairs(cards)do
			new_card:addSubcard(c)
		end
		return new_card
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern=="nullification"
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
extension_lq:addSkills(kelqlizhongUse)
kelqjuesui = sgs.CreateTriggerSkill{
	name = "kelqjuesui",
	events = {sgs.Dying}, 
	on_trigger = function(self,event,player,data,room)
		if event==sgs.Dying then
			local dying = data:toDying()
			if dying.who:getTag("kelqjuesuiUse"):toBool() then return end
			if player:askForSkillInvoke(self,ToData(dying.who)) then
				room:broadcastSkillInvoke(self:objectName())
				dying.who:setTag("kelqjuesuiUse",ToData(true))
				if dying.who:askForSkillInvoke(self,data,false) then
					room:recover(dying.who,sgs.RecoverStruct(self:objectName(),player,1-dying.who:getHp()))
					dying.who:throwEquipArea()
					room:attachSkillToPlayer(dying.who,"kelqjuesuiUse")
				end
			end
		end
		return false
	end
}
kelqcaoren:addSkill(kelqjuesui)
kelqjuesuiUse = sgs.CreateViewAsSkill{
	name = "kelqjuesuiUse&",
	n = 1,
	view_filter = function(self,selected,to_select)
		return to_select:getTypeId()>1 and to_select:isBlack()
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local new_card = sgs.Sanguosha:cloneCard("slash")
		new_card:setSkillName("_kelqjuesui")
		for _,c in ipairs(cards)do
			new_card:addSubcard(c)
		end
		return new_card
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern=="slash"
	end,
	enabled_at_play = function(self,player)
		return sgs.Slash_IsAvailable(player)
	end,
}
extension_lq:addSkills(kelqjuesuiUse)


sgs.LoadTranslationTable{

	["kelqcaoren"] = "曹仁[龙]", 
	["&kelqcaoren"] = "曹仁",
	["#kelqcaoren"] = "玉钤奉国",
	["designer:kelqcaoren"] = "官方",
	["cv:kelqcaoren"] = "官方",
	["illustrator:kelqcaoren"] = "鬼画府",

	["kelqlizhong"] = "厉众",
	[":kelqlizhong"] = "结束阶段，你可以将任意张装备牌置入任意名角色的装备区；你可以令你或任意名装备区里有牌的角色各摸一张牌，直到本轮结束，这些角色的手牌上限+2且可以将装备区里的牌当【无懈可击】使用。",
	["kelqlizhongUse"] = "厉众",
	[":kelqlizhongUse"] = "你的手牌上限+2且可以将装备区里的牌当【无懈可击】使用。",
	["kelqlizhong0"] = "你可以发动“厉众”%src",
	["kelqlizhong1"] = "将任意张装备牌置入任意名角色的装备区；令你或任意名装备区里有牌的角色各摸一张牌",
	["kelqlizhong2"] = "将任意张装备牌置入任意名角色的装备区",
	["kelqlizhong3"] = "令你或任意名装备区里有牌的角色各摸一张牌",

	["kelqjuesui"] = "玦碎",
	[":kelqjuesui"] = "每名角色限一次，当一名角色进入濒死状态时，你可以令其选择是否回复体力至1点并废除装备区且其本局游戏可以将黑色非基本牌当无次数限制的【杀】使用。",
	["kelqjuesuiUse"] = "玦碎",
	[":kelqjuesuiUse"] = "你可以将黑色非基本牌当无次数限制的【杀】使用",

	["$kelqlizhong1"] = "倚我铁桶阵，敌军何以攻城？",
	["$kelqlizhong2"] = "严加防守，固若金汤，方处不败之地。",
	["$kelqjuesui1"] = "正是杀伐决断之时，将士们前进！",
	["$kelqjuesui2"] = "大敌当前，唯有死战，方能突围破敌！",

	["~kelqcaoren"] = "我誓与此城共存亡。",
}


kelqlvchang = sgs.General(extension_lq, "kelqlvchang", "wei", 3)

kelqjuwu = sgs.CreateTriggerSkill{
	name = "kelqjuwu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.TargetConfirmed) then
			local use = data:toCardUse()
			if use.card:objectName() == "slash" and use.to:contains(player) then
				local num = 0
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if use.from:inMyAttackRange(p) then
						num = num + 1
					end
				end
				if (num >= 3) then
					room:sendCompulsoryTriggerLog(player,self:objectName())
					local nullified_list = use.nullified_list
					table.insert(nullified_list, player:objectName())
					use.nullified_list = nullified_list
					data:setValue(use)
				end
			end
		end
	end,
}
kelqlvchang:addSkill(kelqjuwu)

kelqshouxiangcard = sgs.CreateSkillCard{
	name = "kelqshouxiangcard",
	will_throw = false,
	filter = function(self,targets,to_selec,source)
		return to_selec~=source and #targets<source:getMark("kelqshouxiangNum")
	end,
	feasible = function(self,targets)
		return self:subcardsLength()==#targets
	end,
	about_to_use = function(self,room,use)
		use.from:setTag("kelqshouxiangUse",ToData(use))
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,source,targets)
		local moves = sgs.CardsMoveList()
		local use = source:getTag("kelqshouxiangUse"):toCardUse()
		for i,to in sgs.list(use.to)do
			if to:isAlive() then
				local move = sgs.CardsMoveStruct(self:getSubcards():at(i),to,sgs.Player_PlaceHand,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW,source:objectName(),to:objectName(),self:getSkillName(),""))
				moves:append(move)
			end
		end
		room:moveCardsAtomic(moves,false)
	end,
}
kelqshouxiangvs = sgs.CreateViewAsSkill{
	name = "kelqshouxiang",
	n = 998,
	view_filter = function(self,selected,to_select)
		return #selected<sgs.Self:getMark("kelqshouxiangNum")
		and not to_select:isEquipped()
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local new_card = kelqshouxiangcard:clone()
		for _,c in ipairs(cards)do
			new_card:addSubcard(c)
		end
		return new_card
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern=="@@kelqshouxiang"
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}

kelqshouxiang = sgs.CreateTriggerSkill{
	name = "kelqshouxiang",
	view_as_skill = kelqshouxiangvs,
	events = {sgs.DrawNCards,sgs.EventPhaseChanging,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.DrawNCards) then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if player:askForSkillInvoke(self:objectName(), data) then
				local numt = 0
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:inMyAttackRange(player) then
						numt = numt + 1
					end
				end
				draw.num = draw.num + math.min(3,numt)
				data:setValue(draw)
				room:setPlayerMark(player,"kelqshouxiangskip-Clear",1)
			end
		elseif (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if player:getMark("kelqshouxiangskip-Clear")>0
			and change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) then
				player:skip(sgs.Player_Play)
			end
		elseif (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Discard)
			and (player:getMark("kelqshouxiangskip-Clear") > 0) then
				local numt = 0
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:inMyAttackRange(player) then
						numt = numt + 1
					end
				end
				if numt<1 then return end
				numt = math.min(3,numt)
				room:setPlayerMark(player,"kelqshouxiangNum",numt)
				room:askForUseCard(player,"@@kelqshouxiang","kelqshouxiang0:"..numt,-1,sgs.Card_MethodNone)
			end
		end
	end,
}
kelqlvchang:addSkill(kelqshouxiang)

sgs.LoadTranslationTable{

	["kelqlvchang"] = "吕常", 
	["#kelqlvchang"] = "险守襄阳",
	["designer:kelqlvchang"] = "官方",
	["cv:kelqlvchang"] = "官方",
	["illustrator:kelqlvchang"] = "威屹",

	["kelqjuwu"] = "拒武",
	[":kelqjuwu"] = "锁定技，当你成为普通【杀】的目标后，若使用者攻击范围内包含至少三名角色，则此【杀】对你无效。",

	["kelqshouxiang-ask"] = "你可以选择发动“守襄”交给牌的角色",
	["kelqshouxiang-give"] = "请选择交给其的牌",
	["kelqshouxiang"] = "守襄",
	[":kelqshouxiang"] = "摸牌阶段，你可以多摸X张牌，然后跳过本回合的出牌阶段，且本回合的弃牌阶段开始时，你可以交给至多X名角色各一张手牌（X为攻击范围内包含你的角色数且至多为3）。",
	["kelqshouxiang0"] = "守襄：你可以交给至多%src名角色各一张手牌",


	["$kelqjuwu1"] = "",
	["$kelqjuwu2"] = "",
	["$kelqshouxiang1"] = "",
	["$kelqshouxiang2"] = "",

	["~kelqlvchang"] = "",
}


extension_ty = sgs.Package("taoyuanwange", sgs.Package_GeneralPack)


ty_guanyu = sgs.General(extension_ty, "ty_guanyu", "shu", 4)
tywushengVS = sgs.CreateOneCardViewAsSkill{
	name = "tywusheng",
	response_or_use = true,
	view_filter = function(self,card)
		if not card:isRed() then return end
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = dummyCard()
			slash:setSkillName("tywusheng")
			slash:addSubcard(card)
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self,card)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("tywusheng")
		slash:addSubcard(card)
		return slash
	end,
	enabled_at_play = function(self,player)
		return ("slash"):cardAvailable(player,"wusheng")
	end,
	enabled_at_response = function(self,player,pattern)
		return string.find(pattern,"slash")
	end
}
tywusheng = sgs.CreateTriggerSkill{
	name = "tywusheng" ,
	events = {sgs.CardEffected,sgs.CardOnEffect,sgs.CardOffset},
	view_as_skill = tywushengVS,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardEffected then
	    	local effect = data:toCardEffect()
			if table.contains(effect.card:getSkillNames(),"tywusheng") then
				room:setPlayerCardLimitation(player,"use","Jink|^"..effect.card:getSuitString(),false)
				effect.card:setFlags("tywusheng")
			end
		else
	    	local effect = data:toCardEffect()
			if effect.card:hasFlag("tywusheng") then
				room:removePlayerCardLimitation(effect.to,"use","Jink|^"..effect.card:getSuitString())
				effect.card:setFlags("-tywusheng")
			end
		end
		return false
	end
}
ty_guanyu:addSkill(tywusheng)
tychengshi = sgs.CreateTriggerSkill{
	name = "tychengshi",
	events = {sgs.Damage,sgs.CardFinished},
	frequency = sgs.Skill_Compulsory,
	waked_skills = "#tychengshibf",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag("tychengshiBf") then
				use.m_addHistory = false
				data:setValue(use)
			end
		elseif player:getMark("tychengshiUse-Clear")<1 then
			local damage = data:toDamage()
			if damage.card and damage.card:isRed() and damage.card:isKindOf("Slash") then
				player:addMark("tychengshiUse-Clear")
				room:sendCompulsoryTriggerLog(player,self)
				if player:hasFlag("CurrentPlayer") then
					damage.card:setFlags("tychengshiBf")
				elseif damage.to:isAlive() then
					room:setPlayerMark(damage.to,"&tychengshi+#"..player:objectName().."-PlayClear",1)
				end
			end
		end	
	end,
}
ty_guanyu:addSkill(tychengshi)
tyfuwei = sgs.CreateTriggerSkill{
	name = "tyfuwei",
	events = {sgs.Damaged},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if player:isLord() or player:getGeneralName():contains("liubei") then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:hasSkill(self) and p:getMark("tyfuwei-Clear")<1 then
						if p~=player then
							local dc = room:askForExchange(p,self:objectName(),damage.damage,1,true,"tyfuwei0:"..player:objectName()..":"..damage.damage,true)
							if dc then p:addMark("tyfuwei-Clear") room:giveCard(p,player,dc,self:objectName()) end
						end
						for i=1,damage.damage do
							if p:isAlive() and damage.from and damage.from:isAlive() and p~=damage.from
							and room:askForUseSlashTo(p,damage.from,"tyfuwei1:"..damage.from:objectName(),false)
							then p:addMark("tyfuwei-Clear") else break end
						end
					end
				end
			end
		end	
	end,
}
ty_guanyu:addSkill(tyfuwei)
tychengshibf = sgs.CreateProhibitSkill{
	name = "#tychengshibf",
	is_prohibited = function(self,from,to,card)
		if card:isDamageCard() then
	    	for _, p in sgs.qlist(from:getAliveSiblings()) do
				if from:getMark("&tychengshi+#"..p:objectName().."-PlayClear")>0
				and to~=p then return true end
			end
		end
	end
}
ty_guanyu:addSkill(tychengshibf)

ty_sunquan = sgs.General(extension_ty, "ty_sunquan", "shu", 3)
tyfuhan = sgs.CreateTriggerSkill{
	name = "tyfuhan",
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_PlaceHand and move.from_places:contains(sgs.Player_PlaceHand) then
				if move.from:isAlive() and player:objectName()==move.to:objectName()
				and player:hasSkill(self) and player:hasEquipArea() then
					local ids = {}
					for i=0,4 do
						if player:hasEquipArea(i) then
							table.insert(ids,"EquipArea"..i)
						end
					end
					local from = BeMan(room,move.from)
					if #ids>0 and from:askForSkillInvoke("tyfuhan1",player) then
						local choice = room:askForChoice(from,"tyfuhan1",table.concat(ids,"+"),ToData(player))
						local n = tonumber(string.sub(choice,10,10))
						player:throwEquipArea(n)
						player:addMark("tyfuhan-Clear")
					end
				end
				if move.to:isAlive() and player:objectName()==move.from:objectName()
				and player:hasSkill(self) then
					local ids = {}
					for i=0,4 do
						if not player:hasEquipArea(i) then
							table.insert(ids,"EquipArea"..i)
						end
					end
					local to = BeMan(room,move.to)
					if #ids>0 and to:askForSkillInvoke("tyfuhan2",player) then
						local choice = room:askForChoice(to,"tyfuhan2",table.concat(ids,"+"),ToData(player))
						local n = tonumber(string.sub(choice,10,10))
						player:obtainEquipArea(n)
						player:addMark("tyfuhan-Clear")
					end
				end
			end
		else
	     	local change = data:toPhaseChange()
			if change.to~=sgs.Player_NotActive then return end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("tyfuhan-Clear")>0 and p:hasSkill(self) then
					room:sendCompulsoryTriggerLog(p,self)
					if player:getHandcardNum()<player:getMaxHp() then
						player:drawCards(player:getMaxHp()-player:getHandcardNum(),self:objectName())
					end
				end
			end
		end	
	end,
}
ty_sunquan:addSkill(tyfuhan)
tychendeCard = sgs.CreateSkillCard{
	name = "tychendeCard",
	will_throw = false,
	filter = function(self,targets,to_selec,source)
		return to_selec~=source and #targets<1
	end,
	on_use = function(self,room,source,targets)
		room:showCard(source,self:getSubcards())
		for i,to in sgs.list(targets)do
			room:giveCard(source,to,self,self:getSkillName())
		end
		local ids = sgs.IntList()
		for i,id in sgs.list(self:getSubcards())do
			local c = sgs.Sanguosha:getCard(id)
			if c:isNDTrick() or c:getTypeId()==1 then
				if dummyCard(c:objectName()):isAvailable(source)
				then ids:append(id) end
			end
		end
		if ids:length()>0 then
			room:fillAG(ids,source)
			local id = room:askForAG(source,ids,true,self:getSkillName())
			room:clearAG(source)
			if id>-1 then
				room:setPlayerMark(source,"tychendeId",id)
				room:askForUseCard(source,"@@tychende","tychende0:"..sgs.Sanguosha:getCard(id):objectName())
			end
		end
	end,
}
tychende = sgs.CreateViewAsSkill{
	name = "tychende",
	n = 998,
	view_filter = function(self,selected,to_select)
		if sgs.Sanguosha:getCurrentCardUsePattern()=="@@tychende"
		or to_select:isEquipped() then return false end
		return true
	end,
	view_as = function(self,cards)
		if sgs.Sanguosha:getCurrentCardUsePattern()=="@@tychende" then
			local c = sgs.Sanguosha:getEngineCard(sgs.Self:getMark("tychendeId"))
			local dc = sgs.Sanguosha:cloneCard(c:objectName())
			dc:setSkillName("tychende")
			return dc
		end
		if #cards<2 then return end
		local new_card = tychendeCard:clone()
		for _,c in ipairs(cards)do
			new_card:addSubcard(c)
		end
		return new_card
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern=="@@tychende"
	end,
	enabled_at_play = function(self,player)
		return player:getHandcardNum()>1
	end,
}
ty_sunquan:addSkill(tychende)
tywansu = sgs.CreateTriggerSkill{
	name = "tywansu",
	events = {sgs.CardUsed,sgs.Predamage},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and use.card:getEffectiveId()<0 then
				local list = use.no_respond_list
				local log = sgs.LogMessage()
				for _,p in sgs.qlist(room:getAllPlayers()) do
					for i=0,4 do
						if not p:hasEquipArea(i) then
							table.insert(list,p:objectName())
							log.to:append(p)
							break
						end
					end
				end
				if log.to:length()>0 then
					log.type = "#tywansuLog"
					log.card_str = use.card:toString()
					for _,p in sgs.qlist(room:getAllPlayers()) do
						if p:hasSkill(self) then
							room:sendCompulsoryTriggerLog(p,self)
							log.from = p
							room:sendLog(log)
							use.no_respond_list = list
							data:setValue(use)
						end
					end
				end
			end
		else
	     	local damage = data:toDamage()
			if damage.card and damage.card:getTypeId()>0 and damage.card:getEffectiveId()<0 then
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if p:hasSkill(self) then
						room:sendCompulsoryTriggerLog(p,self)
						room:loseHp(damage.to,damage.damage,true,p,self:objectName())
						return true
					end
				end
			end
		end	
	end,
}
ty_sunquan:addSkill(tywansu)

ty_tanxiong = sgs.General(extension_ty, "ty_tanxiong", "wu", 4)
tylengjian = sgs.CreateTriggerSkill{
    name = "tylengjian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage, sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("tylengjianBf"..damage.to:objectName()) then
		    	room:sendCompulsoryTriggerLog(player, self)
				player:damageRevises(data,1)
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				local has1,has2 = false,false
				for _,to in sgs.list(use.to)do
					if player:inMyAttackRange(to) then
						if player:getMark("tylengjianUse1-Clear")<1 then
							room:setCardFlag(use.card,"tylengjianBf"..to:objectName())
							has1 = true
						end
					else
						if player:getMark("tylengjianUse2-Clear")<1 then
							local no_respond_list = use.no_respond_list
							table.insert(no_respond_list,to:objectName())
							use.no_respond_list = no_respond_list
							data:setValue(use)
							has2 = true
						end
					end
				end
				if has1 then
					player:addMark("tylengjianUse1-Clear")
				elseif has2 then
					room:sendCompulsoryTriggerLog(player, self)
					room:addPlayerMark(player,"tylengjianUse2-Clear")
				end
			end
		end
	end,
}
ty_tanxiong:addSkill(tylengjian)
tysheju = sgs.CreateTriggerSkill{
    name = "tysheju",
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
		    	local tos = sgs.SPlayerList()
				for _,to in sgs.list(use.to)do
					if to:isAlive() and player:canDiscard(to,"he")
					then tos:append(to) end
				end
				local to = room:askForPlayerChosen(player,tos,self:objectName(),"tysheju0:",true,true)
				if to then
					local id = room:askForCardChosen(player,to,"he",self:objectName(),false,sgs.Card_MethodDiscard)
					if id>-1 then
						room:throwCard(id,self:objectName(),to,player)
						if sgs.Sanguosha:getEngineCard(id):isKindOf("Horse")
						or to:isDead() then return end
						room:addPlayerMark(to,"&tysheju-Clear")
						if to:inMyAttackRange(player) then
							room:askForUseSlashTo(to,player,"tysheju1:"..player:objectName())
						end
					end
				end
			end
		end
	end,
}
ty_tanxiong:addSkill(tysheju)
tyshejubf = sgs.CreateAttackRangeSkill{
	name = "#tyshejubf",
    extra_func = function(self,target)
		return target:getMark("&tysheju-Clear")
	end,
}
ty_tanxiong:addSkill(tyshejubf)

ty_liue = sgs.General(extension_ty, "ty_liue", "wu", 5)
tyxiyu = sgs.CreateTriggerSkill{
    name = "tyxiyu",
	events = {sgs.TargetSpecified},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and use.card:isVirtualCard() then
				for _,p in sgs.list(room:getAllPlayers())do
					if p:hasSkill(self) and p:askForSkillInvoke(self) then
						p:drawCards(1,self:objectName())
					end
				end
			end
		end
	end,
}
ty_liue:addSkill(tyxiyu)

ty_zhangda = sgs.General(extension_ty, "ty_zhangda", "wu", 4)
tyxingshaCard = sgs.CreateSkillCard{
	name = "tyxingshaCard",
	will_throw = false,
	target_fixed = true,
	on_use = function(self,room,source,targets)
		room:addPlayerMark(source,"tyxingshaUse-Clear")
		source:addToPile("tyyuan",self)
	end,
}
tyxingshavs = sgs.CreateViewAsSkill{
	name = "tyxingsha",
	n = 2,
	expand_pile = "tyyuan",
	view_filter = function(self,selected,to_select)
		if to_select:isEquipped() then return false end
		return sgs.Self:getPileName(to_select:getEffectiveId())~="tyyuan"
		or sgs.Sanguosha:getCurrentCardUsePattern()=="@@tyxingsha"
	end,
	view_as = function(self,cards)
		if sgs.Sanguosha:getCurrentCardUsePattern()=="@@tyxingsha" then
			if #cards<2 then return end
			local dc = sgs.Sanguosha:cloneCard("slash")
			for _,c in ipairs(cards)do
				dc:addSubcard(c)
			end
			dc:setSkillName("tyxingsha")
			return dc
		end
		if #cards<1 then return end
		local new_card = tyxingshaCard:clone()
		for _,c in ipairs(cards)do
			new_card:addSubcard(c)
		end
		return new_card
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern=="@@tyxingsha"
	end,
	enabled_at_play = function(self,player)
		return player:getCardCount()>1
		and player:getMark("tyxingshaUse-Clear")<1
	end,
}
tyxingsha = sgs.CreateTriggerSkill{
    name = "tyxingsha",
	view_as_skill = tyxingshavs,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase()==sgs.Player_Finish and player:getPile("tyyuan"):length()>1 then
			room:askForUseCard(player, "@@tyxingsha","tyxingsha0:")
		end
	end,
}
ty_zhangda:addSkill(tyxingsha)
tyxianshou = sgs.CreateTriggerSkill{
    name = "tyxianshou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			if death.damage and death.damage.from==player then
		    	local to = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"tyxianshou0",false,true)
				if to then
					room:recover(to,sgs.RecoverStruct(self:objectName(),player,2))
				end
			end
		end
	end,
}
ty_zhangda:addSkill(tyxianshou)
tyxiezhan = sgs.CreateTriggerSkill{
    name = "tyxiezhan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player, self)
			local gn = room:askForGeneral(player,"ty_fanjiang+ty_zhangda")
			if player:getGeneral2Name()=="ty_fanjiang" or player:getGeneral2Name()=="ty_zhangda" then
				room:changeHero(player,gn,false,false, true)
			else
				room:changeHero(player,gn,false,false)
			end
			
		elseif event == sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Play then
		    	room:sendCompulsoryTriggerLog(player, self)
				if player:getGeneralName()=="ty_fanjiang" then
					room:changeHero(player,"ty_zhangda",false,false)
				elseif player:getGeneralName()=="ty_zhangda" then
					room:changeHero(player,"ty_fanjiang",false,false)
				end
				if player:getGeneral2Name()=="ty_fanjiang" then
					room:changeHero(player,"ty_zhangda",false,false, true)
				elseif player:getGeneral2Name()=="ty_zhangda" then
					room:changeHero(player,"ty_fanjiang",false,false, true)
				end
			end
		end
	end,
}
ty_zhangda:addSkill(tyxiezhan)

ty_fanjiang = sgs.General(extension_ty, "ty_fanjiang", "wu", 4)
tybianwovs = sgs.CreateViewAsSkill{
	name = "tybianwo",
	n = 1,
	expand_pile = "tyyuan",
	view_filter = function(self,selected,to_select)
		return sgs.Self:getMark("tybianwoId")==to_select:getEffectiveId()
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		return cards[1]
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern=="@@tybianwo"
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
tybianwo = sgs.CreateTriggerSkill{
    name = "tybianwo",
	view_as_skill = tybianwovs,
	events = {sgs.TargetConfirmed,sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:isDamageCard() and use.to:contains(player) and player:getMark("tybianwoUse-Clear")<1
			and use.card:getEffectiveId()>0 and room:getCardOwner(use.card:getEffectiveId())==nil
			and player:askForSkillInvoke(self,data) then
				player:addMark("tybianwoUse-Clear")
				player:addToPile("tyyuan",use.card)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Finish then
				local ids = player:getPile("tyyuan")
				while player:isAlive() and ids:length()>0 do
					local c = nil
					for _,id in sgs.list(ids)do
						local dc = sgs.Sanguosha:getCard(id)
						if dc:isAvailable(player) then
							c = dc
							break
						end
					end
					if c then
						room:setPlayerMark(player,"tybianwoId",c:getId())
						if room:askForUseCard(player,"@@tybianwo","tybianwo0:"..c:objectName())
						then else break end
					else
						break
					end
					ids = player:getPile("tyyuan")
				end
			end
		end
	end,
}
ty_fanjiang:addSkill(tybianwo)
tybenxiang = sgs.CreateTriggerSkill{
    name = "tybenxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			if death.damage and death.damage.from==player then
		    	local to = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"tybenxiang0",false,true)
				if to then
					to:drawCards(3,self:objectName())
				end
			end
		end
	end,
}
ty_fanjiang:addSkill(tybenxiang)
ty_fanjiang:addSkill("tyxiezhan")

ty_chengji = sgs.General(extension_ty, "ty_chengji", "shu", 3)
tyzhongen = sgs.CreateTriggerSkill{
	name = "tyzhongen" ,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_PlaceHand and player:objectName()==move.to:objectName()
			then player:addMark("tyzhongen-Clear") end
			if move.from_places:contains(sgs.Player_PlaceHand) and player:objectName()==move.from:objectName()
			then player:addMark("tyzhongen-Clear") end
		elseif player:getPhase()==sgs.Player_Finish then
			for _,p in sgs.list(room:getAlivePlayers())do
				if p:getMark("tyzhongen-Clear")>0 and p:hasSkill(self) then
					for _,h in sgs.list(p:getHandcards())do
						if h:isKindOf("Slash") then
							if p:askForSkillInvoke(self,player) then
								local ids = {}
								local dc = dummyCard("ex_nihilo")
								dc:setSkillName("_tyzhongen")
								for _,c in sgs.list(p:getHandcards())do
									dc:addSubcard(c)
									if c:isKindOf("Slash") and p:canUse(dc,player) then
										table.insert(ids,c:getEffectiveId())
									end
									dc:clearSubcards()
								end
								local choice = "tyzhongen2"
								if #ids>0 then
									choice = "tyzhongen1+tyzhongen2"
								end
								if room:askForChoice(p,self:objectName(),choice,ToData(player))=="tyzhongen2" then
									room:askForUseSlashTo(p,room:getOtherPlayers(p),"tyzhongen0",false)
								else
									local dc2 = room:askForExchange(p,self:objectName(),1,1,false,"tyzhongen01:"..player:objectName(),false,table.concat(ids,","))
									if dc2 then
										dc:addSubcard(dc2:getEffectiveId())
										room:useCard(sgs.CardUseStruct(dc,p,player))
									end
								end
							end
							break
						end
					end
				end
			end
		end
		return false
	end
}
ty_chengji:addSkill(tyzhongen)
tyliebao = sgs.CreateTriggerSkill{
    name = "tyliebao",
	events = {sgs.TargetConfirming,sgs.CardFinished},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _,p in sgs.list(room:getAlivePlayers())do
					if player:getHandcardNum()>p:getHandcardNum()
					then return end
				end
				for _,p in sgs.list(room:getOtherPlayers(player))do
					if p:hasSkill(self) and p:askForSkillInvoke(self,player) then
						room:setCardFlag(use.card,player:objectName().."tyliebao"..p:objectName())
						p:drawCards(1,self:objectName())
						use.to:removeOne(player)
						use.to:append(p)
						room:sortByActionOrder(use.to)
						data:setValue(use)
					end
				end
			end
		else
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _,to in sgs.list(use.to)do
					for _,p in sgs.list(room:getAlivePlayers())do
						if use.card:hasFlag(p:objectName().."tyliebao"..to:objectName()) then
							if use.card:hasFlag("DamageDone_"..to:objectName()) then continue end
							room:recover(p,sgs.RecoverStruct(self:objectName(),to))
						end
					end
				end
			end
		end
	end,
}
ty_chengji:addSkill(tyliebao)

ty_zhangnan = sgs.General(extension_ty, "ty_zhangnan", "shu", 4)
tyfenwuvs = sgs.CreateViewAsSkill{
	name = "tyfenwu",
	n = 1,
	view_filter = function(self,selected,to_select)
		return sgs.Self:getMark("tyfenwuId")==to_select:getEffectiveId()
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local dc = sgs.Sanguosha:cloneCard(sgs.Self:property("tyfenwuDc"):toString())
		dc:setSkillName("_tyfenwu")
		dc:addSubcard(cards[1])
		return dc
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern=="@@tyfenwu"
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
tyfenwu = sgs.CreateTriggerSkill{
	name = "tyfenwu",
	view_as_skill = tyfenwuvs,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Start and player:askForSkillInvoke(self) then
			local ids = player:drawCardsList(1,self:objectName())
			room:showCard(player,ids)
			local c = sgs.Sanguosha:getCard(ids:at(0))
			local choices = {}
			for _,pn in sgs.list(patterns())do
				local dc = dummyCard(pn)
				if dc:nameLength()==c:nameLength() then
					if dc:getTypeId()==1 or dc:isKindOf("Duel") then
						table.insert(choices,pn)
					end
				end
			end
			if #choices>0 and player:hasCard(c) then
				table.insert(choices,"cancel")
				room:setPlayerMark(player,"tyfenwuId",c:getId())
				local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"))
				if choice=="cancel" then return end
				room:setPlayerProperty(player,"tyfenwuDc",ToData(choice))
				room:askForUseCard(player,"@@tyfenwu","tyfenwu0:"..choice)
			end
		end
		return false
	end
}
ty_zhangnan:addSkill(tyfenwu)

ty_fengxi = sgs.General(extension_ty, "ty_fengxi", "shu", 4)
tyqingkouvs = sgs.CreateViewAsSkill{
	name = "tyqingkou",
	n = 1,
	view_filter = function(self,selected,to_select)
		return sgs.Self:getMark("tyqingkouId")==to_select:getEffectiveId()
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local dc = sgs.Sanguosha:cloneCard(sgs.Self:property("tyqingkouDc"):toString())
		dc:setSkillName("tyqingkou")
		dc:addSubcard(cards[1])
		return dc
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern=="@@tyqingkou"
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
tyqingkou = sgs.CreateTriggerSkill{
	name = "tyqingkou",
	view_as_skill = tyqingkouvs,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()==sgs.Player_Finish and player:askForSkillInvoke(self) then
			local ids = player:drawCardsList(1,self:objectName(),false)
			room:showCard(player,ids)
			local c = sgs.Sanguosha:getCard(ids:at(0))
			local choices = {}
			for _,pn in sgs.list(patterns())do
				local dc = dummyCard(pn)
				if dc:nameLength()==player:getHp() then
					if dc:isNDTrick() then
						table.insert(choices,pn)
					end
				end
			end
			if player:getHp()==1 then
				table.insert(choices,"slash")
			end
			if #choices>0 and player:hasCard(c) then
				table.insert(choices,"cancel")
				room:setPlayerMark(player,"tyqingkouId",c:getId())
				local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"))
				if choice=="cancel" then return end
				room:setPlayerProperty(player,"tyqingkouDc",ToData(choice))
				room:askForUseCard(player,"@@tyqingkou","tyqingkou0:"..choice)
			end
		end
		return false
	end
}
ty_fengxi:addSkill(tyqingkou)

ty_zhaorong = sgs.General(extension_ty, "ty_zhaorong", "shu", 4)
tyyuantao = sgs.CreateTriggerSkill{
    name = "tyyuantao",
	events = {sgs.CardUsed,sgs.CardFinished,sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()==1 then
				for _,p in sgs.list(room:getAllPlayers())do
					if p:hasSkill(self) and p:getMark("tyyuantaoUse-Clear")<1
					and p:askForSkillInvoke(self,data) then
						use.card:addMark("tyyuantaoBf")
						p:addMark("tyyuantaoUse-Clear")
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local n = use.card:getMark("tyyuantaoBf")
			if n>0 then
				use.card:removeMark("tyyuantaoBf")
				local tos = sgs.SPlayerList()
				for _,p in sgs.list(use.to)do
					if p:isAlive() then tos:append(p) end
				end
				room:useCard(sgs.CardUseStruct(use.card,use.from,tos))
			end
		else
	     	local change = data:toPhaseChange()
			if change.to~=sgs.Player_NotActive then return end
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("tyyuantaoUse-Clear")>0 then
					room:loseHp(p,1,true,player,self:objectName())
				end
			end
		end
	end,
}
ty_zhaorong:addSkill(tyyuantao)

ty_guanxing = sgs.General(extension_ty, "ty_guanxing", "shu", 4)
tychonglong = sgs.CreateTriggerSkill{
    name = "tychonglong",
	events = {sgs.DamageCaused, sgs.CardUsed,sgs.EventPhaseChanging,sgs.CardsMoveOneTime},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:isRed() then
		    	for _,p in sgs.list(room:getAllPlayers())do
					if p:hasSkill(self) and p:canDiscard(p,"he")
					and room:askForCard(p,"EquipCard","tychonglong1",data,self:objectName()) then
						player:damageRevises(data,1)
					end
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isRed() and use.card:isKindOf("Slash") then
		    	for _,p in sgs.list(room:getAllPlayers())do
					if p:hasSkill(self) and p:canDiscard(p,"he")
					and room:askForCard(p,"TrickCard","tychonglong0",data,self:objectName()) then
						local no_respond_list = use.no_respond_list
						table.insert(no_respond_list,"_ALL_TARGETS")
						use.no_respond_list = no_respond_list
						data:setValue(use)
					end
				end
			end
		elseif event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD
			and move.from and move.from:objectName()==player:objectName() then
				player:addMark("tychonglongDis-Clear",move.card_ids:length())
			end
		else
	     	local change = data:toPhaseChange()
			if change.to~=sgs.Player_NotActive then return end
			for _,p in sgs.list(room:getAllPlayers())do
				if p:getMark("tychonglongDis-Clear")>1 and p:hasSkill(self) and p:askForSkillInvoke(self) then
					p:drawCards(1,self:objectName())
				end
			end
		end
	end,
}
ty_guanxing:addSkill(tychonglong)
ty2chengshicard = sgs.CreateSkillCard{
	name = "ty2chengshicard",
	will_throw = false,
	filter = function(self,targets,to_selec,source)
		if to_selec:getMark("&ty2chengshi+#"..source:objectName().."_lun")<1
		then return end
		local dc = dummyCard()
		dc:setSkillName("ty2chengshi")
		dc:addSubcard(self:getEffectiveId())
		if source:isLocked(dc) then return end
		local plist = sgs.PlayerList()
		for i = 1,#targets do plist:append(targets[i]) end
		return dc:targetFilter(plist,to_selec,source)
	end,
	on_validate = function(self,use)
		local dc = dummyCard()
		dc:setSkillName("ty2chengshi")
		dc:addSubcard(self:getEffectiveId())
		return dc
	end,
}
ty2chengshivs = sgs.CreateViewAsSkill{
	name = "ty2chengshi",
	n = 1,
	view_filter = function(self,selected,to_select)
		return to_select:isRed()
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local new_card = ty2chengshicard:clone()
		for _,c in ipairs(cards) do
			new_card:addSubcard(c)
		end
		return new_card
	end,
	enabled_at_response = function(self,player,pattern)
		for _,p in sgs.list(player:getAliveSiblings())do
			if p:getMark("&ty2chengshi+#"..player:objectName().."_lun")>0 then
				return player:getCardCount()>0 and pattern:contains("slash")
				and sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
			end
		end
	end,
	enabled_at_play = function(self,player)
		for _,p in sgs.list(player:getAliveSiblings())do
			if p:getMark("&ty2chengshi+#"..player:objectName().."_lun")>0 then
				return player:getCardCount()>0 and dummyCard():isAvailable(player)
			end
		end
	end,
}
ty2chengshi = sgs.CreateTriggerSkill{
	name = "ty2chengshi",
	events = {sgs.Damaged}, 
	view_as_skill = ty2chengshivs;
	on_trigger = function(self,event,player,data,room)
		if event==sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and damage.from~=player and damage.from:isAlive() and player:canDiscard(player,"he")
			and room:askForCard(player,"..","ty2chengshi0",data,self:objectName()) then
				room:setPlayerMark(damage.from,"&ty2chengshi+#"..player:objectName().."_lun",1)
			end
		end
		return false
	end
}
ty_guanxing:addSkill(ty2chengshi)

ty_luxun = sgs.General(extension_ty, "ty_luxun", "wu", 3)
tyqianshou = sgs.CreateTriggerSkill{
	name = "tyqianshou" ,
	events = {sgs.EventPhaseChanging,sgs.CardEffected,sgs.CardOnEffect,sgs.CardOffset},
	change_skill = true,
	waked_skills = "#tyqianshoubf",
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseChanging then
	     	local change = data:toPhaseChange()
			if change.from==sgs.Player_NotActive then
				for _,p in sgs.list(room:getOtherPlayers(player))do
					if p:hasSkill(self) and (player:getHp()>p:getHp() or not player:isChained()) then
						local n = p:getChangeSkillState(self:objectName())
						if n<2 then
							local c = room:askForCard(p,".|red","tyqianshou0:"..player:objectName(),ToData(player),sgs.Card_MethodNone)
							if c then
								p:skillInvoked(self)
								room:setChangeSkillState(p,self:objectName(),2)
								room:showCard(p,c:getEffectiveId())
								room:giveCard(p,player,c,self:objectName(),true)
								room:setPlayerCardLimitation(p,"use",".|.|.|hand",false)
								room:setPlayerMark(p,"&tyqianshou-Clear",1)
								room:setPlayerMark(player,"&tyqianshou-Clear",1)
							end
						else
							if player:getCardCount()>0 and p:askForSkillInvoke(self,player) then
								room:setChangeSkillState(p,self:objectName(),1)
								local c = room:askForCard(player,"..!","tyqianshou1:"..p:objectName(),ToData(p),sgs.Card_MethodNone)
								if not c then c = player:getCards("he"):first() end
								room:showCard(player,c:getEffectiveId())
								room:giveCard(player,p,c,self:objectName(),true)
								if not c:isBlack() then
									room:loseHp(p,1,true,player,self:objectName())
								end
							end
						end
					end
				end
			elseif change.from==sgs.Player_NotActive then
				for _,p in sgs.list(room:getOtherPlayers(player))do
					if p:getMark("&tyqianshou-Clear")>0 then
						room:removePlayerCardLimitation(p,"use",".|.|.|hand")
					end
				end
			end
		end
		return false
	end
}
tyqianshoubf = sgs.CreateProhibitSkill{
	name = "#tyqianshoubf",
	is_prohibited = function(self,from,to,card)
		return to:getMark("&tyqianshou-Clear")>0
	end
}
ty_luxun:addSkill(tyqianshou)
ty_luxun:addSkill(tyqianshoubf)
tytanlongCard = sgs.CreateSkillCard{
	name = "tytanlongCard",
	filter = function(self,targets,to_selec,source)
		return #targets<1 and source~=to_selec
		and source:canPindian(to_selec)
	end,
	on_use = function(self,room,source,targets)
		for _,to in sgs.list(targets)do
			if source:canPindian(to) then
				local pd = source:PinDian(to,self:getSkillName())
				if pd.success then
					if source:isAlive() and room:getCardOwner(pd.to_card:getEffectiveId())==nil
					and source:askForSkillInvoke(self:getSkillName(),ToData(pd.to_card),false) then
						source:obtainCard(pd.to_card)
						local dc = dummyCard("iron_chain")
						dc:setSkillName("_tytanlong")
						if source:isAlive() and source:canUse(dc,source) then
							room:useCard(sgs.CardUseStruct(dc,source,source))
						end
					end
				else
					if to:isAlive() and room:getCardOwner(pd.from_card:getEffectiveId())==nil
					and to:askForSkillInvoke(self:getSkillName(),ToData(pd.from_card),false) then
						to:obtainCard(pd.from_card)
						local dc = dummyCard("iron_chain")
						dc:setSkillName("_tytanlong")
						if to:isAlive() and to:canUse(dc,to) then
							room:useCard(sgs.CardUseStruct(dc,to,to))
						end
					end
				end
			end
		end
	end
}
tytanlong = sgs.CreateViewAsSkill{
	name = "tytanlong",
	view_as = function(self,cards)
		return tytanlongCard:clone()
	end,
	enabled_at_play = function(self,player)
		local n = 0
		for _,to in sgs.list(player:getAliveSiblings(true))do
			if to:isChained() then n = n+1 end
		end
		return player:usedTimes("#tytanlongCard")<=n
	end,
}
ty_luxun:addSkill(tytanlong)
tyxibei = sgs.CreateTriggerSkill{
    name = "tyxibei",
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_PlaceHand and player:objectName()~=move.to:objectName() then
		    	if move.from_places:contains(sgs.Player_DrawPile) then return end
				if player:hasSkill(self) and player:askForSkillInvoke(self,data) then
					player:drawCards(1,self:objectName())
					if player:getPhase()==sgs.Player_Play then
						local c = room:askForCard(player,"TrickCard","tyxibei0",data,sgs.Card_MethodNone)
						if c then
							room:showCard(player,c:getEffectiveId())
							if player:handCards():contains(c:getEffectiveId()) then
								local dc = sgs.Sanguosha:cloneCard("_tyhuoshaolianying",c:getSuit(),c:getNumber())
								if dc then
									dc:setSkillName(self:objectName())
									local wrap = sgs.Sanguosha:getWrappedCard(c:getEffectiveId())
									wrap:takeOver(dc)
									room:notifyUpdateCard(player,c:getEffectiveId(),wrap)
								end
							end
						end
					end
				end
			end
		else
	     	local change = data:toPhaseChange()
			if change.to~=sgs.Player_NotActive then return end
			for _,p in sgs.list(room:getAllPlayers())do
				local cs = sgs.CardList()
				for _,h in sgs.list(p:getHandcards())do
					if h:getSkillName()==self:objectName()
					then cs:append(h) end
				end
				room:filterCards(p,cs,true)
			end
		end
	end,
}
ty_luxun:addSkill(tyxibei)

_tyhuoshaolianying = sgs.CreateTrickCard{
	name = "_tyhuoshaolianying",
	class_name = "Huoshaolianying",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = true,
	damage_card = true,
    available = function(self,player)
    	for _,to in sgs.list(player:getAliveSiblings(true))do
			if CanToCard(self,player,to) then
				return self:cardIsAvailable(player)
			end
		end
    end,
	filter = function(self,targets,to_select,source)
	    return to_select:getCardCount()>0 and not source:isProhibited(to_select,self)
		and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
	end,
	feasible = function(self,targets,source)
		return #targets>0 or not source:isProhibited(source,self)
	end,
	about_to_use = function(self,room,use)
		if use.to:length()<1 then use.to:append(use.from) end
		self:cardOnUse(room,use)
		if use.from:hasFlag("_tyhuoshaolianyingObtain")
		and room:getCardPlace(self:getEffectiveId())==sgs.Player_Discard
		then use.from:obtainCard(self) end
		use.from:setFlags("-_tyhuoshaolianyingObtain")
	end,
	on_effect = function(self,effect)
		local from,to,room = effect.from,effect.to,effect.to:getRoom()
	   	if to:getCardCount()<1 or from:isDead() then return end
		local id = room:askForCardChosen(from,to,"he",self:objectName())
		if id<0 then return end
		room:showCard(to,id)
		local c = sgs.Sanguosha:getCard(id)
		if room:askForCard(from,".|"..c:getSuitString().."|.|hand","_tyhuoshaolianying0:"..to:objectName()..":"..c:getSuitString(),ToData(effect)) then
			if to:isChained() then
				from:setFlags("_tyhuoshaolianyingObtain")
			end
			if from:canDiscard(to,id) then
				room:throwCard(id,self:objectName(),to,from)
			end
			room:damage(sgs.DamageStruct(self,from,to,1,sgs.DamageStruct_Fire))
		end
		return false
	end,
}
_tyhuoshaolianying:clone(2,1):setParent(extension_ty)

ty_liubei = sgs.General(extension_ty, "ty_liubei$", "shu", 4)
tyqingshiCard = sgs.CreateSkillCard{
	name = "tyqingshiCard",
	will_throw = false,
	filter = function(self,targets,to_selec,source)
		return #targets<self:subcardsLength()
		and to_selec:hasFlag("tyqingshiBlack")
		and to_selec~=source
	end,
	feasible = function(self,targets)
		return #targets==self:subcardsLength()
	end,
	about_to_use = function(self,room,use)
		for i,p in sgs.list(use.to)do
			if p:isAlive() then
				room:giveCard(use.from,p,sgs.Sanguosha:getCard(self:getSubcards():at(i)),self:getSkillName())
			end
		end
	end,
}
tyqingshivs = sgs.CreateViewAsSkill{
	name = "tyqingshi",
	n = 998,
	view_filter = function(self,selected,to_select)
		return #selected<=sgs.Self:getAliveSiblings():length()
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local new_card = tyqingshiCard:clone()
		for _,c in ipairs(cards) do
			new_card:addSubcard(c)
		end
		return new_card
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern=="@@tyqingshi"
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
tyqingshi = sgs.CreateTriggerSkill{
    name = "tyqingshi",
	events = {sgs.EventPhaseStart},
	view_as_skill = tyqingshivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase()==sgs.Player_Start then
			local tos = room:askForPlayersChosen(player,room:getAlivePlayers(),self:objectName(),0,player:getHp(),"tyqingshi0:"..player:getHp(),true,true)
			if tos:length()>0 then
				local ys = {}
				ys.reason = self:objectName()
				ys.from = player
				ys.tos = tos
				ys.effect = function(ys_data)
					if ys_data.result=="red" then
						for i,pn in sgs.list(ys_data.tos)do
							if ys_data.to2color[pn]:match("red") then
								local to = room:findPlayerByObjectName(pn)
								room:setPlayerMark(to,"&tyqingshi_lun",1)
							end
						end
					elseif ys_data.result=="black" then
						local n = 0
						for i,pn in sgs.list(ys_data.tos)do
							if ys_data.to2color[pn]:match("black") then
								local to = room:findPlayerByObjectName(pn)
								room:setPlayerFlag(to,"tyqingshiBlack")
								n = n+1
							end
						end
						player:drawCards(n,self:objectName())
						room:askForUseCard(player,"@@tyqingshi","tyqingshi1")
						for i,pn in sgs.list(ys_data.tos)do
							if ys_data.to2color[pn]:match("black") then
								local to = room:findPlayerByObjectName(pn)
								room:setPlayerFlag(to,"-tyqingshiBlack")
							end
						end
					end
				end
				askYishi(ys)
			end
		end
	end,
}
ty_liubei:addSkill(tyqingshi)
tyqingshibf = sgs.CreateDistanceSkill{
	name = "#tyqingshibf",
	correct_func = function(self,from,to)
		local n = 0
		if from:getMark("&tyqingshi_lun")>0
		and to:getMark("&tyqingshi_lun")>0
		then n = n+1 end
		if to:getMark("tycangshen_lun")<1
		and to:hasSkill("tycangshen")
		then n = n+1 end
		return n
	end,
	fixed_func = function(self,from,to)
		if from:getMark(to:objectName().."tyansha_lun")>0
		then return 1 end
		return -1
	end
}
ty_liubei:addSkill(tyqingshibf)
tyyilin = sgs.CreateTriggerSkill{
    name = "tyyilin",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_PlaceHand
			and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceHand)) then
		    	if player:objectName()==move.to:objectName() then
					if player:getMark("tyyilinUse-Clear")>0 then return end
					local ids = {}
					for i,id in sgs.list(move.card_ids)do
						if player:handCards():contains(id) then
							table.insert(ids,id)
						end
					end
					if #ids>0 and player:askForSkillInvoke(self,data) then
						player:addMark("tyyilinUse-Clear")
						room:askForUseCard(player,table.concat(ids,","),"tyyilin0")
					end
				elseif player:objectName()==move.from:objectName() then
					if move.to:getMark("tyyilinUse-Clear")>0 then return end
					local ids = {}
					local to = BeMan(room,move.to)
					for i,id in sgs.list(move.card_ids)do
						if to:handCards():contains(id) then
							table.insert(ids,id)
						end
					end
					if #ids>0 and player:askForSkillInvoke(self,data) then
						to:addMark("tyyilinUse-Clear")
						room:askForUseCard(to,table.concat(ids,","),"tyyilin0")
					end
				end
			end
		end
	end,
}
ty_liubei:addSkill(tyyilin)
tychengming = sgs.CreateTriggerSkill{
    name = "tychengming$",
	frequency = sgs.Skill_Limited,
	events = {sgs.Dying},
	limit_mark = "@tychengming",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Dying then
			local dying = data:toDying()
			if dying.who==player and player:getMark("@tychengming")>0 then
		    	local to = room:askForPlayerChosen(player, room:getLieges("shu",player),self:objectName(),"tychengming0",true,true)
				if to then
					room:removePlayerMark(player,"@tychengming")
					room:doSuperLightbox(player,self:objectName())
					local dc = dummyCard()
					for _,c in sgs.list(player:getCards("hej"))do
						dc:addSubcard(c)
					end
					to:obtainCard(dc,false)
					room:recover(player,sgs.RecoverStruct(self:objectName(),player,1-player:getHp()))
					for _,s in sgs.list(to:getVisibleSkillList())do
						if s:isAttachedLordSkill() then continue end
						if s:getFrequency(to)==sgs.Skill_Compulsory and to:isAlive() then
							room:acquireSkill(to,"rende")
							break
						end
					end
				end
			end
		end
	end,
}
ty_liubei:addSkill(tychengming)

ty_shamoke = sgs.General(extension_ty, "ty_shamoke", "shu", 4)
ty_shamoke:addSkill("jili")
tymanyong = sgs.CreateTriggerSkill{
    name = "tymanyong",
	events = {sgs.EventPhaseChanging},
	waked_skills = "_tytiejiliguduo",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.from==sgs.Player_NotActive then 
			local w = player:getWeapon()
			if w and w:isKindOf("Tiejiliguduo") then return end
			for _,id in sgs.list(sgs.Sanguosha:getRandomCards(true))do
				w = sgs.Sanguosha:getCard(id)
				if w:isKindOf("Tiejiliguduo") and room:getCardOwner(id)==nil then
					if w:isAvailable(player) and player:askForSkillInvoke(self) then
						room:useCard(sgs.CardUseStruct(w,player))
					end
					break
				end
			end
		elseif change.to==sgs.Player_NotActive then
			local w = player:getWeapon()
			if w and w:isKindOf("Tiejiliguduo") and player:canDiscard(player,w:getEffectiveId())
			and player:askForSkillInvoke(self) then 
				room:throwCard(w,self:objectName(),player)
			end
		end
	end,
}
ty_shamoke:addSkill(tymanyong)

tytiejiliguduoTr = sgs.CreateTriggerSkill{
	name = "_tytiejiliguduo",
	events = {sgs.EventPhaseStart,sgs.BeforeCardsMove},
	priority = {2,0},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
   		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Start then
				if player:hasWeapon("_tytiejiliguduo") and player:askForSkillInvoke(self) then
					room:notifyWeaponRange("_tytiejiliguduo",player:getHp())
				end
			elseif player:getPhase()==sgs.Player_RoundStart then
				room:notifyWeaponRange("_tytiejiliguduo",2)
			end
		else
	     	local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceEquip) then
				for i,id in sgs.list(move.card_ids)do
					if move.from_places:at(i)==sgs.Player_PlaceEquip then
						local c = sgs.Sanguosha:getEngineCard(id)
						if c:isKindOf("Tiejiliguduo") then
							room:notifyWeaponRange("_tytiejiliguduo",2)
							if move.to_place~=sgs.Player_PlaceTable then
								local ids = sgs.IntList()
								ids:append(id)
								move:removeCardIds(ids)
								data:setValue(move)
								room:moveCardTo(c,nil,sgs.Player_PlaceTable,true)
							end
						end
					end
				end
			end
			if move.to_place==sgs.Player_Discard then
				for i,id in sgs.list(move.card_ids)do
					local c = sgs.Sanguosha:getEngineCard(id)
					if c:isKindOf("Tiejiliguduo") then
						room:notifyWeaponRange("_tytiejiliguduo",2)
						local ids = sgs.IntList()
						ids:append(id)
						move:removeCardIds(ids)
						data:setValue(move)
						room:moveCardTo(c,nil,sgs.Player_PlaceTable,true)
					end
				end
			end
		end
		return false
	end
}
tytiejiliguduo = sgs.CreateWeapon{
	name = "_tytiejiliguduo",
	class_name = "Tiejiliguduo",
	range = 2,
	equip_skill = tytiejiliguduoTr,
	on_install = function(self,player)
		local room = player:getRoom()
		room:attachSkillToPlayer(player,"_tytiejiliguduo")
		return false
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,"_tytiejiliguduo",true)
		return false
	end,
}
tytiejiliguduo:clone(1,1):setParent(extension_ty)

ty_huangzhong = sgs.General(extension_ty, "ty_huangzhong", "shu", 4)
ty_huangzhong:addSkill("tenyearliegong")
tyyizhuang = sgs.CreateTriggerSkill{
    name = "tyyizhuang",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getJudgingArea():length()>0
			and player:askForSkillInvoke(self) then
		    	room:damage(sgs.DamageStruct(self:objectName(),player,player))
				local dc = dummyCard()
				dc:addSubcards(player:getJudgingArea())
				room:throwCard(dc,self:objectName(),nil)
			end
		end
	end,
}
ty_huangzhong:addSkill(tyyizhuang)

ty_yanque = sgs.General(extension_ty, "ty_yanque", "qun", 4)
tysiji = sgs.CreateTriggerSkill{
	name = "tysiji" ,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceEquip)
			or move.from_places:contains(sgs.Player_PlaceHand) then
				if move.from:objectName()~=player:objectName()
				or move.reason.m_reason==sgs.CardMoveReason_S_REASON_RESPONSE
				or move.reason.m_reason==sgs.CardMoveReason_S_REASON_USE then return end
				player:addMark("tysiji-Clear")
			end
		else
	     	local change = data:toPhaseChange()
			if change.to~=sgs.Player_NotActive
			or player:getMark("tysiji-Clear")<1 then return end
			for _,p in sgs.list(room:getAllPlayers())do
				if p:hasSkill(self) and p:getCardCount()>0 then
					local ids = {}
					local dc = dummyCard("yj_stabs_slash")
					dc:setSkillName("tysiji")
					for _,c in sgs.list(p:getCards("he"))do
						dc:addSubcard(c)
						if p:canSlash(player,dc,false) then
							table.insert(ids,c:getEffectiveId())
						end
						dc:clearSubcards()
					end
					if #ids<1 then continue end
					local dt = room:askForExchange(p,self:objectName(),1,1,true,"tysiji0:"..player:objectName(),true,table.concat(ids,","))
					if dt then
						dc:addSubcard(dt:getEffectiveId())
						room:useCard(sgs.CardUseStruct(dc,p,player))
					end
				end
			end
		end
		return false
	end
}
ty_yanque:addSkill(tysiji)
tycangshen = sgs.CreateTriggerSkill{
    name = "tycangshen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:getMark("tycangshen_lun")<1 then
		    	room:sendCompulsoryTriggerLog(player, self)
				room:addPlayerMark(player, "tycangshen_lun")
			end
		end
	end,
}
ty_yanque:addSkill(tycangshen)

ty_wangque = sgs.General(extension_ty, "ty_wangque", "qun", 3)
tydaifa = sgs.CreateTriggerSkill{
	name = "tydaifa" ,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceEquip)
			or move.from_places:contains(sgs.Player_PlaceHand) then
				if move.to_place~=sgs.Player_PlaceHand or move.from==move.to
				or move.to:objectName()~=player:objectName() then return end
				player:addMark("tydaifa-Clear")
			end
		else
	     	local change = data:toPhaseChange()
			if change.to~=sgs.Player_NotActive
			or player:getMark("tydaifa-Clear")<1 then return end
			for _,p in sgs.list(room:getAllPlayers())do
				if p:hasSkill(self) and p:getCardCount()>0 then
					local ids = {}
					local dc = dummyCard("yj_stabs_slash")
					dc:setSkillName("tydaifa")
					for _,c in sgs.list(p:getCards("he"))do
						dc:addSubcard(c)
						if p:canSlash(player,dc,false) then
							table.insert(ids,c:getEffectiveId())
						end
						dc:clearSubcards()
					end
					if #ids<1 then continue end
					local dt = room:askForExchange(p,self:objectName(),1,1,true,"tydaifa0:"..player:objectName(),true,table.concat(ids,","))
					if dt then
						dc:addSubcard(dt:getEffectiveId())
						room:useCard(sgs.CardUseStruct(dc,p,player))
					end
				end
			end
		end
		return false
	end
}
ty_wangque:addSkill(tydaifa)
ty_wangque:addSkill("tycangshen")

ty_wuque = sgs.General(extension_ty, "ty_wuque", "qun", 4)
tyansha = sgs.CreateTriggerSkill{
	name = "tyansha" ,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseChanging then
	     	local change = data:toPhaseChange()
			if change.from~=sgs.Player_NotActive then return end
			for _,p in sgs.list(room:getAllPlayers())do
				if p:hasSkill(self) and p:getCardCount()>0 then
					local ids = {}
					local dc = dummyCard("yj_stabs_slash")
					dc:setSkillName("tyansha")
					for _,c in sgs.list(p:getCards("he"))do
						dc:addSubcard(c)
						if p:canSlash(player,dc) then
							table.insert(ids,c:getEffectiveId())
						end
						dc:clearSubcards()
					end
					if #ids<1 then continue end
					local dt = room:askForExchange(p,self:objectName(),1,1,true,"tyansha0:"..player:objectName(),true,table.concat(ids,","))
					if dt then
						dc:addSubcard(dt:getEffectiveId())
						room:useCard(sgs.CardUseStruct(dc,p,player))
						room:addPlayerMark(player,p:objectName().."tyansha_lun")
					end
				end
			end
		end
		return false
	end
}
ty_wuque:addSkill(tyansha)
ty_wuque:addSkill("tycangshen")
tyxiongren = sgs.CreateTriggerSkill{
    name = "tyxiongren",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.to:distanceTo(player)>1 then
				room:sendCompulsoryTriggerLog(player, self)
				player:damageRevises(data,1)
			end
		end
	end,
}
ty_wuque:addSkill(tyxiongren)


ty_anying = sgs.General(extension_ty, "ty_anying", "qun", 3)
tyliupo = sgs.CreateTriggerSkill{
    name = "tyliupo",
	change_skill = true,
	events = {sgs.Predamage, sgs.EventPhaseChanging},
	can_trigger = function(self,target)
		return true
	end,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Predamage then
			local damage = data:toDamage()
			for _,p in sgs.list(room:getAllPlayers())do
				if p:getMark("tyliupo2_lun")>0 then
					room:sendCompulsoryTriggerLog(p,self)
					room:loseHp(damage.to,damage.damage,true,damage.from,damage.reason)
					return true
				end
			end
		else
	     	local change = data:toPhaseChange()
			if change.from==sgs.Player_NotActive and player
			and player:isAlive() and player:hasSkill(self) then
				local n = player:getChangeSkillState(self:objectName())
				room:sendCompulsoryTriggerLog(player,self)
				if n<2 then
					room:setChangeSkillState(player,self:objectName(),2)
					room:addPlayerMark(player,"tyliupo1_lun")
				else
					room:setChangeSkillState(player,self:objectName(),1)
					room:addPlayerMark(player,"tyliupo2_lun")
				end
			end
		end
	end,
}
tyliupobf = sgs.CreateCardLimitSkill{
	name = "#tyliupobf" ,
	limit_list = function(self,player)
		return "use"
	end,
	limit_pattern = function(self,player)
		for _,p in sgs.list(player:getAliveSiblings(true))do
			if p:getMark("tyliupo1_lun")>0
			then return "Peach" end
		end
	end
}
ty_anying:addSkill(tyliupo)
ty_anying:addSkill(tyliupobf)
tyzhuiling = sgs.CreateTriggerSkill{
	name = "tyzhuiling" ,
	events = {sgs.HpLost},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.HpLost then
			local lose = data:toHpLost()
			for _,p in sgs.list(room:getAllPlayers())do
				if p:getMark("&tyhun")<3 and p:hasSkill(self) then
					room:sendCompulsoryTriggerLog(p,self)
					local n = math.min(lose.lose,3-p:getMark("&tyhun"))
					p:gainMark("&tyhun",n)
				end
			end
		end
		return false
	end
}
ty_anying:addSkill(tyzhuiling)
tyxihun = sgs.CreateTriggerSkill{
    name = "tyxihun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.RoundEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.RoundEnd then
			room:sendCompulsoryTriggerLog(player, self)
			for _,p in sgs.list(room:getOtherPlayers(player))do
				room:doAnimate(1,player:objectName(),p:objectName())
			end
			for _,p in sgs.list(room:getOtherPlayers(player))do
				if p:getHandcardNum()>1
				and room:askForDiscard(p,self:objectName(),2,2,true,false,"tyxihun0")
				then else room:loseHp(p,1,true,player,self:objectName()) end
			end
			local choice = {}
			for i=1,player:getMark("&tyhun") do
				table.insert(choice,"tyxi_hun="..i)
			end
			if #choice>0 and player:getLostHp()>0 then
				choice = room:askForChoice(player,self:objectName(),table.concat(choice,"+"))
				choice = choice:split("=")
				room:recover(player,sgs.RecoverStruct(self:objectName(),player,tonumber(choice[2])))
			end
		end
	end,
}
ty_anying:addSkill(tyxihun)
tyxianqicard = sgs.CreateSkillCard{
	name = "tyxianqicard",
	--will_throw = false,
	filter = function(self,targets,to_selec,source)
		return #targets<1 and to_selec~=source
		and to_selec:hasSkill("tyxianqi")
	end,
	on_use = function(self,room,source,targets)
		if self:subcardsLength()<1 then
			room:damage(sgs.DamageStruct(self:getSkillName(),source,source))
		end
		for _,p in ipairs(targets) do
			room:damage(sgs.DamageStruct(self:getSkillName(),nil,p))
		end
	end
}
tyxianqivs = sgs.CreateViewAsSkill{
	name = "tyxianqivs&",
	n = 2,
	view_filter = function(self,selected,to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self,cards)
		if #cards==1 then return end
		local new_card = tyxianqicard:clone()
		for _,c in ipairs(cards) do
			new_card:addSubcard(c)
		end
		return new_card
	end,
	enabled_at_play = function(self,player)
		for _,p in sgs.list(player:getAliveSiblings()) do
			if p:hasSkill("tyxianqi") then
				return player:usedTimes("#tyxianqicard")<1
			end
		end
		return false
	end,
}
extension_ty:addSkills(tyxianqivs)
tyxianqi = sgs.CreateTriggerSkill{
	name = "tyxianqi" ,
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd,sgs.EventAcquireSkill},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Play then
				for _,p in sgs.list(room:getOtherPlayers(player))do
					if p:hasSkill(self,true) and not player:hasSkill("tyxianqivs",true) then
						room:attachSkillToPlayer(player,"tyxianqivs")
					end
				end
			end
		elseif event==sgs.EventPhaseEnd then
			if player:getPhase()>=sgs.Player_Play and player:hasSkill("tyxianqivs",true) then
				room:detachSkillFromPlayer(player,"tyxianqivs",true)
			end
		else
			if player:hasSkill(self,true) then
				for _,p in sgs.list(room:getOtherPlayers(player))do
					if p:getPhase()==sgs.Player_Play and not p:hasSkill("tyxianqivs",true) then
						room:attachSkillToPlayer(p,"tyxianqivs")
					end
				end
			end
		end
		return false
	end
}
ty_anying:addSkill(tyxianqi)









sgs.LoadTranslationTable{
	["taoyuanwange"] = "桃园挽歌", 




	["ty_wuque"] = "乌鹊", 
	["#ty_wuque"] = "密执生死",
	["illustrator:ty_wuque"] = "Mir_Sleeping",

	["tyansha"] = "暗杀",
	[":tyansha"] = "其他角色回合开始时，你可以将一张牌当做刺【杀】对其使用；此牌结算后，其对你的距离视为1直到本轮结束。",
	["tyxiongren"] = "凶刃",
	[":tyxiongren"] = "锁定技，你对计算与你距离大于1/不大于1的角色使用【杀】造成的伤害+1/无距离与次数限制。",
	["tyansha0"] = "暗杀：你可将一张牌当做刺【杀】对%src使用",

	["ty_wangque"] = "亡鹊", 
	["#ty_wangque"] = "神鬼莫测",
	["illustrator:ty_wangque"] = "黑羽",

	["tydaifa"] = "待发",
	[":tydaifa"] = "其他角色回合结束时，若其本回合获得过除其以外的角色的牌，你可以将一张牌当做无距离限制的刺【杀】对其使用。",
	["tydaifa0"] = "待发：你可将一张牌当做刺【杀】对%src使用",

	["ty_anying"] = "暗影", 
	["#ty_anying"] = "暗影射沙",
	["illustrator:ty_anying"] = "黑白画谱",

	["tyliupo"] = "流魄",
	[":tyliupo"] = "转换技，回合开始时，你令本轮①所有角色不能使用【桃】②所有伤害均视为体力流失。",
	[":tyliupo1"] = "转换技，回合开始时，你令本轮①所有角色不能使用【桃】<font color=\"#01A5AF\"><s>②所有伤害均视为体力流失</s></font>。",
	[":tyliupo2"] = "转换技，回合开始时，你令本轮<font color=\"#01A5AF\"><s>①所有角色不能使用【桃】</s></font>②所有伤害均视为体力流失。",
	["tyzhuiling"] = "追灵",
	[":tyzhuiling"] = "锁定技，当一名角色失去体力后，你获得等量“魂”标记（至多拥有3枚）；你对没有手牌的角色使用牌无距离与次数限制。",
	["tyxihun"] = "吸魂",
	[":tyxihun"] = "锁定技，每轮结束时，所有其他角色选择失去1点体力或弃置两张手牌，然后你移去任意“魂”标记并回复等量体力。",
	["tyxianqi"] = "献气",
	[":tyxianqi"] = "其他角色出牌阶段限一次，其可以对自己造成1点伤害或弃置两张手牌，然后你受到1点伤害。",
	["tyxi_hun"] = "移去%src枚“魂”并回复%src点体力",
	["tyhun"] = "魂",
	["tyxianqivs"] = "献气",
	[":tyxianqivs"] = "出牌阶段限一次，你可以对自己造成1点伤害或弃置两张手牌，然后“献气”角色受到1点伤害。",

	["ty_yanque"] = "阎鹊", 
	["#ty_yanque"] = "神出鬼没",
	["illustrator:ty_yanque"] = "紫芒小侠",

	["tysiji"] = "伺机",
	[":tysiji"] = "其他角色回合结束时，若其本回合不因使用和打出而失去牌，你可以将一张牌当做无距离限制的刺【杀】对其使用。",
	["tycangshen"] = "藏身",
	[":tycangshen"] = "锁定技，其他角色计算与你的距离+1；当你使用【杀】结算后，“藏身”于本轮内失效。",
	["tysiji0"] = "伺机：你可将一张牌当做刺【杀】对%src使用",

	["ty_huangzhong"] = "黄忠[桃园]", 
	["#ty_huangzhong"] = "炎汉后将军",
	["illustrator:ty_huangzhong"] = "吴涛",

	["tyyizhuang"] = "益壮",
	[":tyyizhuang"] = "准备阶段，若你判定区有牌，你可以对自己造成1点伤害，然后弃置判定区所有的牌。",

	["_tytiejiliguduo"] = "铁蒺藜骨朵",
	[":_tytiejiliguduo"] = "装备牌/武器<br/><b>攻击范围</b>：2<br/><b>武器技能</b>：准备阶段，你可以将此牌本回合的攻击范围改为X（X为你的体力值），直到此牌离开你的装备区。",
	[":_tytiejiliguduo1"] = "装备牌/武器<br/><b>攻击范围</b>：%src<br/><b>武器技能</b>：准备阶段，你可以将此牌本回合的攻击范围改为X（X为你的体力值），直到此牌离开你的装备区。",

	["ty_shamoke"] = "沙摩柯[桃园]", 
	["#ty_shamoke"] = "狂喜胜战",
	["illustrator:ty_shamoke"] = "铁杵文化",

	["tymanyong"] = "蛮勇",
	[":tymanyong"] = "回合开始时，若你未装备【铁蒺藜骨朵】，你可以从游戏外获得并使用之。回合结束时，你可以弃置装备的【铁蒺藜骨朵】。",

	["ty_liubei"] = "刘备[桃园]", 
	["#ty_liubei"] = "见龙渊献",
	["illustrator:ty_liubei"] = "鬼画府",

	["tyqingshi"] = "倾师",
	[":tyqingshi"] = "准备阶段，你可以令至多等同你体力值数量的角色进行议事，若结果为：红色，直到本轮结束前，意见为红色的角色各与其余角色互相计算距离+1；黑色，你摸意见为黑色的角色数量的牌，然后你可以交给任意名意见为黑色角色各一张牌。",
	["tyyilin"] = "夷临",
	[":tyyilin"] = "每回合每名角色限一次，当你获得其他角色的牌后，或其他角色获得你的牌后，你可以令获得牌的角色选择是否使用其中一张牌。",
	["tychengming"] = "承命",
	[":tychengming"] = "主公技，限定技，当你进入濒死状态时，你可以令一名其他蜀势力角色获得你区域内所有牌，然后你将体力回复至1点，若其拥有锁定技，其获得“仁德”。",
	["tyqingshi0"] = "倾师：你可以令至多%src名角色进行议事",
	["tyqingshi1"] = "倾师：你可以交给任意名意见为黑色角色各一张牌<br/><br/>操作说明：依次选择等量的牌与角色后点击确定",
	["tychengming0"] = "你可以发动“承命”选择一名其他蜀势力角色获得你区域内所有牌",
	["tyyilin0"] = "夷临：你可以使用一张牌",

	["ty_luxun"] = "陆逊[桃园]", 
	["#ty_luxun"] = "社稷心膂",
	["illustrator:ty_luxun"] = "鬼画府",

	["tyqianshou"] = "谦守",
	[":tyqianshou"] = "转换技，其他角色回合开始时，若其体力值大于你或其未处于横置状态，①你可以展示并交给其一张红色牌，本回合你不能使用手牌且你与其不能成为牌的目标②你可以令其展示一张牌并交给你，若此牌不为黑色，你失去1点体力。",
	[":tyqianshou1"] = "转换技，其他角色回合开始时，若其体力值大于你或其未处于横置状态，①你可以展示并交给其一张红色牌，本回合你不能使用手牌且你与其不能成为牌的目标<font color=\"#01A5AF\"><s>②你可以令其展示一张牌并交给你，若此牌不为黑色，你失去1点体力</s></font>。",
	[":tyqianshou2"] = "转换技，其他角色回合开始时，若其体力值大于你或其未处于横置状态，<font color=\"#01A5AF\"><s>①你可以展示并交给其一张红色牌，本回合你不能使用手牌且你与其不能成为牌的目标</s></font>②你可以令其展示一张牌并交给你，若此牌不为黑色，你失去1点体力。",
	["tytanlong"] = "探龙",
	[":tytanlong"] = "出牌阶段限X+1次，你可以与一名其他角色拼点。赢的角色可以获得对方拼点牌，然后视为对自己使用一张【铁索连环】（X为场上横置角色数）。",
	["tyxibei"] = "袭惫",
	[":tyxibei"] = "当其他角色从牌堆外获得牌后，你可以摸一张牌，若此时为你的出牌阶段，你可以展示一张锦囊牌，然后此牌本回合内视为【火烧连营】直到离开你的手牌。",
	["tyqianshou0"] = "你可以发动“谦守”展示并交给%src一张红色牌",
	["tyqianshou1"] = "谦守：请选择展示并交给%src一张牌",
	["tyxibei0"] = "袭惫：你可以展示一张锦囊牌视为【火烧连营】",

	["_tyhuoshaolianying"] = "火烧连营",
	[":_tyhuoshaolianying"] = "锦囊牌·单目标锦囊<br/><b>时机</b>：出牌阶段，对一名有牌的角色使用<br/><b>效果</b>：你展示目标一张牌，然后你可以弃置一张与之花色相同的手牌。若如此做，你弃置其展示的牌并对其造成1点火焰伤害；若其处于横置状态，你从弃牌堆中获得此牌。",
	["_tyhuoshaolianying0"] = "火烧连营：你可以弃置一张%dest手牌对%src造成一点火焰伤害",

	["ty_guanxing"] = "关兴", 
	["#ty_guanxing"] = "少有令问",
	["illustrator:ty_guanxing"] = "君桓文化",

	["tychonglong"] = "从龙",
	[":tychonglong"] = "当红色【杀】被使用时，你可以弃置一张锦囊牌，令此【杀】不能被响应。当红色【杀】对目标造成伤害时，你可以弃置一张装备牌，令此伤害+1。每个回合结束时，若你本回合弃置了至少两张牌，你可以摸一张牌。",
	["ty2chengshi"] = "乘势",
	[":ty2chengshi"] = "当你受到其他角色的伤害后，你可以弃置一张牌。若如此做，你直到本轮结束，你可以将一张红色牌当做【杀】对其使用，且你对其使用牌无距离限制。",
	["tychonglong0"] = "你可以发动“从龙”弃置一张锦囊牌，令此【杀】不能被响应",
	["tychonglong1"] = "你可以发动“从龙”弃置一张装备牌，令此【杀】伤害+1",
	["ty2chengshi0"] = "乘势：你可以弃置一张牌",

	["ty_zhaorong"] = "赵融", 
	["#ty_zhaorong"] = "从龙别督",
	["illustrator:ty_zhaorong"] = "荆芥",

	["tyyuantao"] = "援讨",
	[":tyyuantao"] = "每回合限一次，一名角色使用基本牌时，你可以令此牌额外使用一次，然后当前回合结束时，你失去一点体力。",

	["ty_fengxi"] = "冯习", 
	["#ty_fengxi"] = "赤胆的忠魂",
	["illustrator:ty_fengxi"] = "陈鑫",

	["tyqingkou"] = "轻寇",
	[":tyqingkou"] = "结束阶段，你可以从牌堆底摸一张牌并展示之，然后你可以将此牌当做牌名字数与你体力相同的普通锦囊牌或【杀】使用。",
	["tyqingkou0"] = "奋武：你可以将此牌当做【%src】使用",

	["ty_zhangnan"] = "张南", 
	["#ty_zhangnan"] = "澄辉的义烈",
	["illustrator:ty_zhangnan"] = "Aaron",

	["tyfenwu"] = "奋武",
	[":tyfenwu"] = "准备阶段，你可以摸一张牌并展示之，然后你可以将此牌当做牌名字数与之相同的基本牌或【决斗】使用。",
	["tyfenwu0"] = "奋武：你可以将此牌当做【%src】使用",

	["ty_chengji"] = "程畿", 
	["#ty_chengji"] = "大义之诚",
	["illustrator:ty_chengji"] = "荆芥",

	["tyzhongen"] = "忠恩",
	[":tyzhongen"] = "当前回合结束阶段，若你的手牌本回合发生过变化，你可以将一张【杀】当做【无中生有】对其使用，或使用一张无距离限制的【杀】。",
	["tyliebao"] = "烈报",
	[":tyliebao"] = "手牌数最少的角色成为【杀】的目标后，你可以摸一张牌并代替其成为目标，此【杀】结算后若你未因此受到伤害，其回复1点体力。",
	["tyzhongen1"] = "将一张【杀】当做【无中生有】对其使用",
	["tyzhongen2"] = "使用一张无距离限制的【杀】",
	["tyzhongen01"] = "忠恩：请将一张【杀】当做【无中生有】对其使用",
	["tyzhongen0"] = "忠恩：请使用一张无距离限制的【杀】",

	["ty_fanjiang"] = "范疆", 
	["#ty_fanjiang"] = "有死无生",
	["illustrator:ty_fanjiang"] = "Qiyi",

	["tybianwo"] = "鞭挝",
	[":tybianwo"] = "每回合限一次，当你成为伤害牌的目标后，你可以将此牌置于你的武将牌上，称为“怨”。结束阶段，你可以将“怨”依次使用之。",
	["tybenxiang"] = "奔降",
	[":tybenxiang"] = "锁定技，你杀死一名角色后，你令一名其他角色摸3张牌。",
	["tybianwo0"] = "鞭挝：你可以使用此“怨”牌【%src】",
	["tybenxiang0"] = "奔降：请选择令一名其他角色摸3张牌",

	["ty_zhangda"] = "张达", 
	["#ty_zhangda"] = "有死无生",
	["illustrator:ty_zhangda"] = "Qiyi",

	["tyxingsha"] = "刑杀",
	[":tyxingsha"] = "每回合限一次，你可以将至多两张牌置于你武将牌上，称为“怨”。结束阶段，你可以将两张“怨”当做无距离限制的【杀】使用。",
	["tyxianshou"] = "献首",
	[":tyxianshou"] = "锁定技，你杀死一名角色后，你令一名其他角色回复2点体力。",
	["tyxiezhan"] = "协战",
	[":tyxiezhan"] = "锁定技，游戏开始时，你选择范疆或张达；出牌阶段开始时，你变更武将牌。",
	["tyxingsha0"] = "刑杀：你可以将两张“怨”当做无距离限制的【杀】使用",
	["tyxianshou0"] = "献首：请选择令一名其他角色回复2点体力",
	["tyyuan"] = "怨",

	["ty_liue"] = "刘阿", 
	["#ty_liue"] = "西抵怒龙",
	["illustrator:ty_liue"] = "荆芥",

	["tyxiyu"] = "西御",
	[":tyxiyu"] = "一名角色使用转化牌或虚拟牌指定目标后，你可以摸一张牌。",

	["ty_tanxiong"] = "谭雄", 
	["#ty_tanxiong"] = "暗箭难防",
	["illustrator:ty_tanxiong"] = "荆芥",

	["tylengjian"] = "冷箭",
	[":tylengjian"] = "锁定技，你对攻击范围内/外的角色每回合首次使用的【杀】造成的伤害+1/无距离限制且不能被响应。",
	["tysheju"] = "射驹",
	[":tysheju"] = "当你使用【杀】结算后，你可以弃置其中一名目标角色的一张牌，若此牌不为坐骑牌，其本回合攻击范围+1，然后若你在其攻击范围内，其可以对你使用一张【杀】。",
	["tysheju0"] = "你可以发动“射驹”弃置其中一名目标角色的一张牌",
	["tysheju1"] = "射驹：你可以对%src使用【杀】",

	["ty_sunquan"] = "孙权[桃园]", 
	["#ty_sunquan"] = "大汉吴王",
	["illustrator:ty_sunquan"] = "荆芥",

	["tyfuhan"] = "辅汉",
	[":tyfuhan"] = "当你/其他角色获得其他角色/你的手牌后，该角色可以废除/恢复你的一个装备栏。每回合结束时，若此技能本回合发动过，当前回合角色将手牌摸至体力上限。",
	["tychende"] = "臣德",
	[":tychende"] = "出牌阶段，你可以展示并交给其他角色至少两张手牌，然后你可以视为使用其中一张基本牌或普通锦囊牌。",
	["tywansu"] = "完夙",
	[":tywansu"] = "锁定技，装备栏有废除的角色不能响应虚拟牌；虚拟牌即将造成的伤害视为体力流失。",
	["tyfuhan1"] = "辅汉",
	["tyfuhan2"] = "辅汉",
	["tychende0"] = "臣德：你可以视为使用【%src】",
	["#tywansuLog"] = "%to 不能响应 %card",

	["ty_guanyu"] = "神秘将军", 
	["#ty_guanyu"] = "卷土重来",
	["illustrator:ty_guanyu"] = "MUMU",

	["tywusheng"] = "武圣",
	[":tywusheng"] = "你可以将一张红色牌当做【杀】使用或打出，以此法使用的【杀】只能被此牌花色相同的【闪】抵消。",
	["tychengshi"] = "乘势",
	[":tychengshi"] = "锁定技，每回合限一次，当你于回合内/回合外使用红色【杀】造成伤害后，你令此【杀】不计入次数/受伤角色此阶段不能使用伤害牌指定除你以外的角色为目标。",
	["tyfuwei"] = "扶危",
	[":tyfuwei"] = "每回合限一次，当主公或刘备受到伤害后，你可以交给其至多X张牌，然后你可以对伤害来源依次使用至多X张【杀】（X为此次伤害值）。",
	["tyfuwei0"] = "你可以发动“扶危”交给%src至多%dest张牌",
	["tyfuwei1"] = "扶危：你可以对%src使用【杀】",


}



return {extension_lq,extension_ty}