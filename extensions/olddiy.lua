module("extensions.olddiy", package.seeall)
extension = sgs.Package("olddiy")

luadiyguanyu = sgs.General(extension, "luadiyguanyu", "shu", 4)

luajuaocard = sgs.CreateSkillCard{
	name = "luajuaocard",
	will_throw = false,
	target_fixed = false,
	once = true,
	filter = function(self, targets, to_select, player)
		if #targets > 0 then return false end
		return player:objectName() ~= to_select:objectName()
	end,
	on_use = function(self, room, source, targets)
		if(#targets ~= 1) then return end
		local to = targets[1]
        room:moveCardTo(self, to, sgs.Player_PlaceHand, false)
		if to:getHp()>=source:getHp() then
			source:drawCards(1)
		end
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:setSkillName("luajuao")
		local use = sgs.CardUseStruct()
		use.card = duel
		use.from = source
		local sp=sgs.SPlayerList()
		sp:append(to)
		use.to = sp
		room:useCard(use)
		room:setPlayerFlag(source, "luajuao_used")
        duel:deleteLater()
	end,
}

luajuao = sgs.CreateViewAsSkillV2{
	name = "luajuao",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("#luajuaocard")
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate or #request:getSelectedCardIds() >= 1 then return false end
		return candidate:isKindOf("Slash")
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if #ids ~= 1 then return nil end
		local lcard = luajuaocard:clone()
		lcard:addSubcard(ids[1])
		lcard:setSkillName(skill:objectName())
		return lcard
	end,
}


luadiyguanyu:addSkill("wusheng")
luadiyguanyu:addSkill(luajuao)

sgs.LoadTranslationTable{
	["olddiy"] = "懷舊DIY",
	
	["luadiyguanyu"] = "关羽",
	["#luadiyguanyu"] = "千里独行",
	["luajuao"] = "倨傲",
	["luajuaocard"] = "倨傲",
	[":luajuao"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以交给一名其他角色一张【杀】，视为你对其使用了一张【决斗】，若其体力值不少于你，在决斗结算前，你摸一张牌。",
	["designer:luadiyguanyu"] = "wubuchenzhou",
	["cv:luadiyguanyu"] = "",
	
	["$luajuao1"] = "以忠守心，以义规行。",
	["$luajuao2"] = "关某在此。来者~报上名来！",
}


diyzhangfei = sgs.General(extension, "diyzhangfei", "shu", 4)

zfduanhecard = sgs.CreateSkillCard {
	name = "zfduanhe",
	will_throw = false,
	target_fixed = false,
	once = true,
	filter = function(self, targets, to_select, player)
		return #targets < 2 and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		local judge = sgs.JudgeStruct()
		judge.who = source
		judge.reason = "zfduanhe"
		judge.pattern = ".|heart"
		judge.good = false
		judge.play_animation = true
		room:judge(judge)
		if judge:isBad() and source:canDiscard(source, "he") then
			room:askForDiscard(source, "zfduanhe", 1, 1, false, true, "zfduanhe", ".")
		elseif judge:isGood() then
			for _, tg in ipairs(targets) do
				room:setPlayerMark(tg, "&zfduanhe+to+#" .. source:objectName() .. "-Clear", 1)
				room:setPlayerMark(tg, "@zfduanhe-Clear", 1)
				--room:setPlayerCardLimitation(tg, "use,response", "BasicCard", false)
			end
		end
	end,
}
zfduanhevs = sgs.CreateViewAsSkillV2 {
	name = "zfduanhe",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("#zfduanhe")
	end,
	create_card = function(skill, request)
		return zfduanhecard:clone()
	end,
}
zfduanhe = sgs.CreateTriggerSkillV2 {
	name = "zfduanhe",
	view_as_skill = zfduanhevs,
	events = { sgs.Damaged, sgs.EventPhaseStart },
	on_record = function(skill, event, room, player, ctx)
		if event == sgs.Damaged then
			local damage = ctx.original_data:toDamage()
			if not damage.to or damage.to:isDead() then return end
			local markName = "&" .. skill:objectName() .. "+to+#" .. ctx.owner:objectName() .. "-Clear"
			if damage.to:getMark(markName) > 0 then
				room:setPlayerMark(damage.to, markName, 0)
				room:setPlayerMark(damage.to, "@zfduanhe-Clear", 0)
				--room:removePlayerCardLimitation(damage.to, "use,response", "BasicCard")
			end
		elseif event == sgs.EventPhaseStart
			and ctx.owner:objectName() == player:objectName()
			and player:getPhase() == sgs.Player_NotActive then
			for _, to in sgs.qlist(room:getAlivePlayers()) do
				local markName = "&" .. skill:objectName() .. "+to+#" .. player:objectName() .. "-Clear"
				if to:getMark(markName) > 0 then
					room:setPlayerMark(to, markName, 0)
					room:setPlayerMark(to, "@zfduanhe-Clear", 0)
					--room:removePlayerCardLimitation(to, "use,response", "BasicCard")
				end
			end
		end
	end,
}
zfduanhe_CardLimit = sgs.CreateCardLimitSkill {
	name = "#zfduanhe_CardLimit",
	limit_list = function(self, player)
		if player:getMark("@zfduanhe-Clear") > 0 then
			return "use,response"
		end
		return ""
	end,
	limit_pattern = function(self, player)
		if player:getMark("@zfduanhe-Clear") > 0 then
			return "BasicCard"
		end
		return ""
	end
}

diyzhangfei:addSkill(zfduanhe)
diyzhangfei:addSkill(zfduanhe_CardLimit)
extension:insertRelatedSkills("zfduanhe", "#zfduanhe_CardLimit")
sgs.LoadTranslationTable {
	["diyzhangfei"] = "张飞",

	["#diyzhangfei"] = "万夫莫敌",
	["zfduanhe"] = "断喝",
	[":zfduanhe"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以指定至多两名其他角色，然后你进行一次判定，若判定结果为红桃，你弃置一张牌。否则，被指定的角色不能使用或打出基本牌，直到其受到一次伤害或你的回合结束。",
	["$zfduanhe1"] = "燕人张飞在此！",
	["$zfduanhe2"] = "手下败将，还敢负隅顽抗！",

	["designer:diyzhangfei"] = "wubuchenzhou",
}

shanbao_liyu = sgs.General(extension, "shanbao_liyu", "qun", 3)

lydujicard = sgs.CreateSkillCard{
	name = "lyduji",
	will_throw = false,
	target_fixed = false,
	once = true,
	filter = function(self, targets, to_select, player)
		return #targets<1 and to_select:objectName()~=player:objectName()
	end,
	on_use = function(self, room, source, targets)
		--拿牌前
		room:moveCardTo(self, targets[1], sgs.Player_PlaceHand, true)
		local splist = sgs.SPlayerList()
		for _,sp in sgs.qlist(room:getOtherPlayers(targets[1])) do
			if not sp:isKongcheng() and targets[1]:canPindian(sp) then
				splist:append(sp)
			end
		end
		if splist:isEmpty() then return false end
		local pdto = room:askForPlayerChosen(source, splist, "lyduji")
		room:setPlayerFlag(source, "lyduji")
		local success = targets[1]:pindian(pdto, "lyduji", nil)
		room:setPlayerFlag(source, "-lyduji")
		-- --拼点前
		-- local pindian = sgs.PindianStruct()
		-- pindian.from = targets[1]
		-- pindian.from_card = room:askForPindian(targets[1], targets[1], "lyduji")
		-- pindian.to = pdto
		-- pindian.to_card = room:askForPindian(pdto, targets[1], "lyduji")
		-- pindian.reason = "lyduji"
		-- local data = sgs.QVariant()
		-- data:setValue(pindian)
		-- room:getThread():trigger(sgs.Pindian, room, targets[1], data)
		-- if pindian.from_card:getNumber()>pindian.to_card:getNumber() then
		-- 	if not room:askForDiscard(pdto, "lyduji", 2, 2, true, false) then
		-- 		room:loseHp(pdto)
		-- 		--拼点赢了之后
		-- 	end
		-- 	source:obtainCard(pindian.from_card)
		-- else
		-- 	if not room:askForDiscard(targets[1], "lyduji", 2, 2, true, false) then
		-- 		room:loseHp(targets[1])
		-- 		--拼点没赢
		-- 	end
		-- 	source:obtainCard(pindian.to_card)
		-- end
	end
}
lydujiVS = sgs.CreateViewAsSkillV2{
	name = "lyduji",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("#lyduji")
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate or #request:getSelectedCardIds() >= 1 then return false end
		return candidate:getSuit()==sgs.Card_Spade and not candidate:isEquipped()
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if #ids ~= 1 then return nil end
		local vscard = lydujicard:clone()
		vscard:addSubcard(ids[1])
		return vscard
	end,
}
lyduji = sgs.CreateTriggerSkillV2 {
	name = "lyduji",
	view_as_skill = lydujiVS,
	events = { sgs.Pindian },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.Pindian then return false end
		local pindian = data:toPindian()
		if pindian.reason ~= skill:objectName() then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _, liyu in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if liyu:hasFlag(skill:objectName()) then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, liyu:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local pindian = ctx.original_data:toPindian()
		local source = pindian.from
		local target = pindian.to
		if pindian.from_number > pindian.to_number then
			player:obtainCard(pindian.from_card)
			if not room:askForDiscard(target, skill:objectName(), 2, 2, true, false) then
				room:loseHp(target, 1, true, ctx.invoker, skill:objectName())
			end
		elseif pindian.from_number < pindian.to_number then
			player:obtainCard(pindian.to_card)
			if not room:askForDiscard(source, skill:objectName(), 2, 2, true, false) then
				room:loseHp(source, 1, true, ctx.invoker, skill:objectName())
				--拼点赢了之后
			end
		else
			player:obtainCard(pindian.from_card)
			player:obtainCard(pindian.to_card)
		end
		return false
	end,
}



lyxiancecard = sgs.CreateSkillCard{
	name = "lyxiance",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		--["$lyxiance1"] = "xxx"
		
		room:moveCardTo(self, room:getLord(), sgs.Player_PlaceHand, true)
	end,
}
lyxiance = sgs.CreateViewAsSkillV2{
	name = "lyxiance",
	n = 1,
	can_activate = function(skill, request)
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate or #request:getSelectedCardIds() >= 1 then return false end
		return candidate:isKindOf("TrickCard")
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if #ids ~= 1 then return nil end
		local vscard = lyxiancecard:clone()
		vscard:addSubcard(ids[1])
		return vscard
	end,
}

lybeixi = sgs.CreateTriggerSkillV2{
	name = "lybeixi",
	events = {sgs.Damaged},
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.Damaged or not player:hasSkill(skill:objectName()) then return false end
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.from then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if not damage.from then return false end
		room:broadcastSkillInvoke(skill:objectName())--然后把配音
		damage.from:turnOver()
		damage.from:drawCards(damage.from:getLostHp())
		return false
	end,
}

lymouduan = sgs.CreateProhibitSkill{
	name = "lymouduan",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill(self:objectName()) and (card:isKindOf("IronChain") or card:isKindOf("Duel"))
		--禁止技是没有配音的
	end,
}

shanbao_liyu:addSkill(lyduji)
shanbao_liyu:addSkill(lyxiance)
shanbao_liyu:addSkill(lybeixi)
shanbao_liyu:addSkill(lymouduan)

sgs.LoadTranslationTable{
	["shanbao"] = "山包DIY李儒",
	
	["#shanbao_liyu"] = "东汉末期的博士",
	["shanbao_liyu"] = "李儒",
	["lyduji"] = "毒计",
	[":lyduji"] = "出牌阶段限一次，你可以将一张黑桃手牌交给一名其他角色。若如此做，你令该角色与你指定的另一名有手牌的角色拼点。输方须弃置两张手牌或者流失一点体力，同时你获得此次拼点中，点数大的牌。",
	["lyxiance"] = "献策",
	[":lyxiance"] = "出牌阶段，你可以将一张锦囊牌交给主公。",
	["lybeixi"] = "悲兮",
	[":lybeixi"] = "每当你受到一次杀的伤害后，你可以令伤害来源武将牌翻面，然后伤害来源摸X张牌（X为伤害来源已损失的体力值）。",
	["lymouduan"] = "谋断",
	[":lymouduan"] = "锁定技，你不能成为铁索连环和决斗的目标。",

	["designer:shanbao_liyu"] = "洛神赋",
	
   ["cv:shanbao_liyu"] = "暂无",
   
   ["illustrator:shanbao_liyu"] = "洛神赋",
}

spshenguanyu=sgs.General(extension,"spshenguanyu","god",5,true)

spwushen=sgs.CreateTriggerSkillV2{
	name="spwushen",
	events={sgs.CardFinished,sgs.PostCardResponded,sgs.CardEffected},
	frequency=sgs.Skill_Frequent,
	can_trigger=function(skill,event,room,player,data)
		local card=nil
		if event==sgs.CardFinished then card=data:toCardUse().card
		elseif event==sgs.PostCardResponded then card=data:toCardResponse().m_card
		end
		if card and card:getSuit()==sgs.Card_Heart and player:hasSkill(skill:objectName()) and not player:hasFlag("spwushen") then
			return skill:objectName()
		end
		return false
	end,
	on_cost=function(skill,event,room,player,ctx)
		local card=sgs.Sanguosha:cloneCard("fire_slash",sgs.Card_Heart,0)
		card:setSkillName(skill:objectName())
		local players=sgs.SPlayerList()
		room:setPlayerFlag(player, "InfinityAttackRange")
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:canUse(card,p) then
			players:append(p) end
		end
		card:deleteLater()
		room:setPlayerFlag(player, "-InfinityAttackRange")
		if players:isEmpty() then return false end
		local playerx=room:askForPlayerChosen(player,players,skill:objectName(), "spwushen-invoke", true, true)
		if not playerx then return false end
		ctx.targets:append(playerx)
		return true
	end,
	on_effect=function(skill,event,room,player,ctx)
		local playerx=ctx.targets:first()
		if not playerx then return false end
		local card=sgs.Sanguosha:cloneCard("fire_slash",sgs.Card_Heart,0)
		card:setSkillName(skill:objectName())
		local use=sgs.CardUseStruct()
		use.from=player
		use.to:append(playerx)
		use.card=card
		room:setPlayerFlag(player,"spwushen")
		room:setPlayerFlag(player, "InfinityAttackRange")
		room:useCard(use,false)
		room:setPlayerFlag(player, "-InfinityAttackRange")
		room:setPlayerFlag(player,"-spwushen")
		card:deleteLater()
		return false
	end,
}

chihun=sgs.CreateFilterSkill{
	name="chihun",
	view_filter=function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return to_select:getSuit()~=sgs.Card_Heart and to_select:isKindOf("BasicCard") and place == sgs.Player_PlaceHand
	end,
	view_as=function(self,card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		new_card:setSuit(sgs.Card_Heart)
		new_card:setModified(true)
		return new_card
	end,	
}

spmengyan_distance=sgs.CreateDistanceSkillV2{
	name="#spmengyan_distance",
	holder_selector=sgs.CorrectSkill_AllHolders,
	correct_func=function(skill,ctx)
		local to = ctx:getSecondary()
		if to and to:getMark("@spnightmare") > 0 then
			return -to:getMark("@spnightmare")
		end
        return false
	end,
}

spmengyan=sgs.CreateTriggerSkillV2{
	name="spmengyan",
	events={sgs.Damage,sgs.Damaged},
	frequency=sgs.Skill_Compulsory,
	can_trigger=function(skill,event,room,player,data)
		if event~=sgs.Damage and event~=sgs.Damaged then return false end
		if not player:hasSkill(skill:objectName()) then return false end
		local damage=data:toDamage()
		local target=nil
		if event==sgs.Damage then target=damage.to else target=damage.from end
		if not target or target:objectName()==player:objectName() or player:isDead() or target:isDead() then return false end
		return skill:objectName()
	end,
	on_effect=function(skill,event,room,player,ctx)
		local damage=ctx.original_data:toDamage()
		local target=nil
		if event==sgs.Damage then target=damage.to else target=damage.from end
		if not target then return false end
		room:broadcastSkillInvoke(skill:objectName())
		target:gainMark("@spnightmare",damage.damage)
		return false
	end,
}
--EventLoseSkill觸發時技能實例已被移除，Lua V2無法從被移除實例取得ctx；
--改用同武將嘅隱藏關聯技喺record階段清理標記。
spmengyan_lose=sgs.CreateTriggerSkillV2{
	name="#spmengyan-lose",
	frequency=sgs.Skill_Compulsory,
	events={sgs.EventLoseSkill},
	on_record=function(skill,event,room,player,ctx)
		if event~=sgs.EventLoseSkill then return end
		if ctx.owner:objectName()~=player:objectName() then return end
		if ctx.original_data:toSkillChange().skillName~="spmengyan" then return end
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getMark("@spnightmare")>0 then
				p:loseAllMarks("@spnightmare")
			end
		end
	end,
}

spwuhun=sgs.CreateTriggerSkillV2{
	name="spwuhun",
	events={sgs.Death},
	frequency=sgs.Skill_Compulsory,
	can_trigger=function(skill,event,room,player,data)
		if event~=sgs.Death or not player:hasSkill(skill:objectName()) then return false end
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			return skill:objectName()
		end
		return false
	end,
	on_cost=function(skill,event,room,player,ctx)
		local maxspnightmare=0
		local players=sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getMark("@spnightmare")>maxspnightmare then
				maxspnightmare=p:getMark("@spnightmare")
			end
		end
		if maxspnightmare==0 then return false end
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getMark("@spnightmare")==maxspnightmare then
				players:append(p)
			end
		end
		local target=room:askForPlayerChosen(player,players,skill:objectName())
		if not target then return false end
		ctx.targets:append(target)
		return true
	end,
	on_effect=function(skill,event,room,player,ctx)
		local maxspnightmare=0
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getMark("@spnightmare")>maxspnightmare then
				maxspnightmare=p:getMark("@spnightmare")
			end
		end
		local target=ctx.targets:first()
		local judge=sgs.JudgeStruct()
		judge.who=player
		judge.good=false
		judge.pattern="Peach,GodSalvation"
		judge.reason=skill:objectName()
		room:judge(judge)
		if judge:isGood() then
			room:broadcastSkillInvoke(skill:objectName(),1)
			local log=sgs.LogMessage()
			log.type="#spwuhun"
			log.from=player
			log.to:append(target)
			log.arg=maxspnightmare
			room:sendLog(log)
			room:killPlayer(target)
		else
			room:broadcastSkillInvoke(skill:objectName(),2)
		end
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getMark("@spnightmare")>0 then
				room:loseHp(p,p:getMark("@spnightmare"), true, player, skill:objectName())
				p:loseAllMarks("@spnightmare")
			end
		end
		return false
	end,
}

spshenguanyu:addSkill(spwushen)
spshenguanyu:addSkill(chihun)
spshenguanyu:addSkill(spmengyan_distance)
spshenguanyu:addSkill(spmengyan)
spshenguanyu:addSkill(spmengyan_lose)
extension:insertRelatedSkills("spmengyan", "#spmengyan_distance")
extension:insertRelatedSkills("spmengyan", "#spmengyan-lose")
spshenguanyu:addSkill(spwuhun)

sgs.LoadTranslationTable{
	["spgod"] = "SP神",

	["spshenguanyu"] = "神关羽",
	["#spshenguanyu"] = "鬼神天降",

	["spwushen"] = "武神",
	["spwushen-invoke"] = "你可以发动“武神”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["$spwushen1"] = "武神现世，天下莫敌！",
	["$spwushen2"] = "战意，化为青龙翱翔吧！",
	[":spwushen"] = "你每使用或者打出一张红桃牌，在其结算后，你可以选择一名其他角色，视为对其使用一张红桃火【杀】",
	["chihun"]="赤魂",
	[":chihun"]="锁定技，你的基础牌均视为红桃牌。",
	["#spmengyan_distance"]="梦魇",
	["spmengyan"]="梦魇",
	[":spmengyan"]="锁定技，你每对其他角色造成1点伤害或者受到其他角色1点伤害，在其面前放置1枚梦魇标记。面前有梦魇标记的角色，每有1个梦魇标记其他角色与其计算距离时均-1",
	["$spmengyan"]="关某记下了", 
	["@spnightmare"]="梦魇",
	["spwuhun"]="武魂",
	[":spwuhun"]="锁定技，当你死亡时，选择一名持有最多梦魇标记的角色，令其判定，若结果不为桃或者桃园结义，则其立刻死亡。然后所有持有梦魇标记的角色，每有一个梦魇标记便失去1点体力",
	["#spwuhun"]="%from的【武魂】触发，带有最多梦魇印记(%arg枚)的%to死亡",
	["$spwuhun1"]="我生不能啖汝之肉，死当追汝之魂！",
	["$spwuhun2"]="桃园之梦，再也不会回来了……",
	["~spshenguanyu"]="吾一世英名，竟葬于小人之手！",
	["designer:spshenguanyu"]="Nutari",
}

luaHliubei = sgs.General(extension, "luaHliubei$", "god", 4)
dj = sgs.CreateTriggerSkillV2 {
	frequency = sgs.Skill_Frequent,
	name = "dj",
	events = { sgs.EventPhaseStart, sgs.FinishJudge },
	can_trigger = function(skill, event, room, player, data)
		if not player:hasSkill(skill:objectName()) then return false end
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start and player:getLostHp() >= 1 then
				return skill:objectName()
			end
		elseif event == sgs.FinishJudge then
			if data:toJudge().reason == skill:objectName() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			local x = player:getLostHp()
			local w = 0
			while (player:askForSkillInvoke("dj")) do
				room:broadcastSkillInvoke("jijiang", math.random(1, 2))
				w = w + 1
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.reason = "dj"
				judge.who = player
				room:judge(judge)
				if (w == x) then break end
			end
		elseif event == sgs.FinishJudge then
			local judge = ctx.original_data:toJudge()
			room:setPlayerMark(player, skill:objectName(), 1)
			if (judge.card:getSuit() == sgs.Card_Club) and (not player:hasSkill("paoxiao")) then
				room:acquireNextTurnSkills(player, skill:objectName(), "paoxiao")
			end
			if (judge.card:getSuit() == sgs.Card_Spade) and (not player:hasSkill("liegong")) then
				if (judge.card:getNumber() <= 6) then
					room:acquireNextTurnSkills(player, skill:objectName(), "liegong")
				elseif not player:hasSkill("tieji") then
					room:acquireNextTurnSkills(player, skill:objectName(), "tieji")
				end
			end

			if (judge.card:getSuit() == sgs.Card_Heart) and (not player:hasSkill("wusheng")) then
				room:acquireNextTurnSkills(player, skill:objectName(), "wusheng")
			end
			if (judge.card:getSuit() == sgs.Card_Diamond) and (not player:hasSkill("longdan")) then
				room:acquireNextTurnSkills(player, skill:objectName(), "longdan")
			end
		end
		return false
	end,
}
pj = sgs.CreateTriggerSkillV2 {
	frequency = sgs.Skill_Frequent,
	name = "pj",
	events = { sgs.EventPhaseChanging, sgs.FinishJudge },
	can_trigger = function(skill, event, room, player, data)
		if not player:hasSkill(skill:objectName()) then return false end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getLostHp() >= 1 then
				return skill:objectName()
			end
		elseif event == sgs.FinishJudge then
			if data:toJudge().reason == skill:objectName() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
			local x = player:getLostHp()
			local w = 0
			while (player:askForSkillInvoke("pj")) do
				room:broadcastSkillInvoke("rende")
				w = w + 1
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.reason = "pj"
				judge.who = player
				room:judge(judge)
				if (w == x) then break end
			end
		elseif event == sgs.FinishJudge then
			local judge = ctx.original_data:toJudge()
			room:setPlayerMark(player, skill:objectName(), 1)
			if (judge.card:getSuit() == sgs.Card_Club) and (not player:hasSkill("kongcheng")) then
				room:acquireNextTurnSkills(player, skill:objectName(), "kongcheng")
			end
			if (judge.card:getSuit() == sgs.Card_Spade) and (not player:hasSkill("wuyan")) then
				room:acquireNextTurnSkills(player, skill:objectName(), "wuyan")
			end

			if (judge.card:getSuit() == sgs.Card_Heart) and (not player:hasSkill("enyuan")) then
				room:acquireNextTurnSkills(player, skill:objectName(), "enyuan")
			end
			if (judge.card:getSuit() == sgs.Card_Diamond) and (not player:hasSkill("bazhen")) then
				room:acquireNextTurnSkills(player, skill:objectName(), "bazhen")
			end
		end
		return false
	end,
}
sgs.LoadTranslationTable {
	["Hliubei"] = "尘包",
	["luaHliubei"] = "刘备",
	["#luaHliubei"] = "蜀汉之主",
	["dj"] = "点将",
	[":dj"] = "回合开始时，若你已受伤，可以进行x次判定：♣~获得技能“咆哮”直到回合结束；♥~获得技能“武圣”直到回合结束；♦~获得技能“龙胆”直到回合结束；♠1~♠6获得技能“烈弓”直到回合结束 ；♠7~♠k获得技能“铁骑”（x为你已损失的体力值）。",
	["pj"] = "辅翼",
	[":pj"] = "回合结束时，若你已受伤，可以进行x次判定：♣~获得技能“空城”直到下回合开始；♥~获得技能“恩怨”直到下回合开始；♦~获得技能“八阵”直到下回合开始；♠~获得技能“无言”直到下回合开始（x为你已损失的体力值）。 ",
	["cv:luaHliubei"] = "",
	["designer:luaHliubei"] = "紫陌易尘",
	["~spmenghuo"] = "刘主阵亡",

}
luaHliubei:addSkill(dj)
luaHliubei:addSkill(pj)
luaHliubei:addRelateSkill("bazhen")
luaHliubei:addRelateSkill("wuyan")
luaHliubei:addRelateSkill("enyuan")
luaHliubei:addRelateSkill("kongcheng")
luaHliubei:addRelateSkill("longdan")
luaHliubei:addRelateSkill("wusheng")
luaHliubei:addRelateSkill("tieji")
luaHliubei:addRelateSkill("paoxiao")
luaHliubei:addRelateSkill("liegong")



Nzhaoyun = sgs.General(extension,"Nzhaoyun","qun","4")

fjsp_youlong = sgs.CreateTriggerSkillV2{
   name = "fjsp_youlong",
   frequency = sgs.Skill_NotFrequent,
   events = {sgs.DamageComplete,sgs.Damage},
   can_trigger = function(skill, event, room, player, data)
      if event == sgs.DamageComplete then
         local damage = data:toDamage()
         local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
         local trigger_list_skill, trigger_list_who = {}, {}
         for _, zhaoyun in sgs.qlist(room:getAlivePlayers()) do
            if zhaoyun:isAlive() and zhaoyun:hasSkill(skill:objectName()) and zhaoyun:canDiscard(zhaoyun, "he") and zhaoyun:getMark(skill:objectName().."using") == 0 then
               local targets = sgs.SPlayerList()
               if zhaoyun:canSlash(damage.from, slash, false) then
                  targets:append(damage.from)
               end
               if zhaoyun:canSlash(damage.to, slash, false) then
                  targets:append(damage.to)
               end
               if not targets:isEmpty() then
                  table.insert(trigger_list_skill, skill:objectName())
                  table.insert(trigger_list_who, zhaoyun:objectName())
               end
            end
         end
         slash:deleteLater()
         if #trigger_list_skill > 0 then
            return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
         end
      elseif event == sgs.Damage then
         local damage = data:toDamage()
         if damage.card and damage.card:getSkillName() == skill:objectName() then
            return skill:objectName()
         end
      end
      return false
   end,
   on_cost = function(skill, event, room, player, ctx)
      if event ~= sgs.DamageComplete then return true end
      return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
   end,
   on_pay = function(skill, event, room, player, ctx)
      if event ~= sgs.DamageComplete then return true end
      room:askForDiscard(player, skill:objectName(), 1, 1, false, true)
      room:addPlayerMark(player, skill:objectName().."using")
      return true
   end,
   on_effect = function(skill, event, room, player, ctx)
      if event == sgs.DamageComplete then
         local damage = ctx.original_data:toDamage()
         local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
         slash:setSkillName(skill:objectName())
         local targets = sgs.SPlayerList()
         if player:canSlash(damage.from, slash, false) then
            targets:append(damage.from)
         end
         if player:canSlash(damage.to, slash, false) then
            targets:append(damage.to)
         end
         if not targets:isEmpty() then
            local use = sgs.CardUseStruct()
            use.from = player
            use.card = slash
            local dest = room:askForPlayerChosen(player, targets, skill:objectName())
            use.to:append(dest)
            room:useCard(use)
         end
         room:setPlayerMark(player, skill:objectName().."using", 0)
         slash:deleteLater()
      elseif event == sgs.Damage then
         local damage = ctx.original_data:toDamage()
         if damage.card and damage.card:getSkillName() == skill:objectName() then
            local zhaoyun = damage.from
            room:drawCards(zhaoyun, 1, skill:objectName())
            zhaoyun:turnOver()
            room:handleAcquireDetachSkills(zhaoyun, "-"..skill:objectName())
            room:setPlayerFlag(zhaoyun, "youlong_lose")
         end
      end
      return false
   end,
   priority = -1,
}
fjsp_youlong_return = sgs.CreateTriggerSkillV2{
   name = "#fjsp_youlong_return",
   frequency = sgs.Skill_Compulsory,
   events = {sgs.EventPhaseChanging},
   on_record = function(skill, event, room, player, ctx)
      if event ~= sgs.EventPhaseChanging then return end
      local change = ctx.original_data:toPhaseChange()
      if change.to ~= sgs.Player_NotActive then return end
      local zhaoyun = ctx.owner
      if zhaoyun and zhaoyun:hasFlag("youlong_lose") then
         room:setPlayerFlag(zhaoyun, "-youlong_lose")
         room:handleAcquireDetachSkills(zhaoyun, "fjsp_youlong")
      end
   end,
}

dangqianCard = sgs.CreateSkillCard{
	name = "dangqianCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
    return #targets < player:getHp() and player:canDisCard(to_select, "he")
    end,
	feasible = function(self, targets, player)
	return #targets > 0
	end,
	on_effect = function(self,effect)
      local room = effect.from:getRoom()
      local id = room:askForCardChosen(effect.from,effect.to,"he","dangqian")
       room:throwCard(id,effect.to,effect.from)
	end
}
dangqianVS = sgs.CreateViewAsSkillV2{
	name = "dangqian",
	n = 0,
	can_activate = function(skill, request)
		if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return request:getPattern() == "@@dangqian"
	end,
	create_card = function(skill, request)
		return dangqianCard:clone()
	end,
}

dangqian = sgs.CreateTriggerSkillV2{
	name = "dangqian" ,
	events = {sgs.CardResponded, sgs.TargetConfirmed, sgs.CardUsed},
	view_as_skill = dangqianVS,
	can_trigger = function(skill, event, room, player, data)
		if not player:hasSkill(skill:objectName()) then return false end
		if event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if resp.m_card and table.contains(resp.m_card:getSkillNames(), "longdan") then
				return skill:objectName()
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName()
				and use.card and table.contains(use.card:getSkillNames(), "longdan") then
				return skill:objectName()
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and table.contains(use.card:getSkillNames(), "longdan") and use.card:isKindOf("Jink") then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForUseCard(player, "@@dangqian", "@dangqian") ~= nil
	end,
}

local Skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("dangqian") then
Skills:append(dangqian)
end
sgs.Sanguosha:addSkills(Skills)

guishu = sgs.CreateTriggerSkillV2{
	name = "guishu" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Wake ,
	waked_skills = "longdan,dangqian",
	can_trigger = function(skill, event, room, player, data)
		return player
			and player:getPhase() == sgs.Player_Start
			and player:getMark(skill:objectName()) < 1
			and player:hasSkill(skill:objectName())
			and skill:objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		local can_invoke = false
		local lord = room:getLord()
		if lord then
			if (string.find(lord:getGeneralName(),"liubei") or string.find(lord:getGeneral2Name(),"liubei"))
			or (string.find(lord:getGeneralName(),"liushan") or string.find(lord:getGeneral2Name(),"liushan"))  then
                can_invoke = true
            end
        end
		if can_invoke or player:canWake(skill:objectName()) then
			player:setMark("guishu", 1)
			if room:changeMaxHpForAwakenSkill(player, -1, skill:objectName()) then
				room:setPlayerProperty(player,"kingdom",sgs.QVariant("shu"))
				room:handleAcquireDetachSkills(player, "longdan")
				room:handleAcquireDetachSkills(player, "dangqian")
				room:handleAcquireDetachSkills(player,"-fjsp_youlong")
				room:handleAcquireDetachSkills(player,"-#youlong_return")
				room:doLightbox("$guishu")
			end
		end
		return false
	end,
}
Nzhaoyun:addSkill(fjsp_youlong)
Nzhaoyun:addSkill(fjsp_youlong_return)
extension:insertRelatedSkills("fjsp_youlong","#fjsp_youlong_return")
Nzhaoyun:addSkill(guishu)

sgs.LoadTranslationTable{
   ["jsp500"] = "界SP包",
   ["$guishu"] = "子龙一身是胆",
   ["Nzhaoyun"] = "界SP赵云",
   ["&Nzhaoyun"] = "界SP赵云",
   ["#Nzhaoyun"] = "常山的游侠",
   ["fjsp_youlong"] = "游龙",
   [":fjsp_youlong"] = "当一名角色受到伤害后，你可以于伤害结算结束后弃置一张牌，视为对其或伤害源角色使用一张杀，以此法使用的杀造成伤害后，你摸一张牌，将武将牌翻面，并失去“游龙”直到回合结束。",
   ["guishu"] = "归宿",
   [":guishu"] = "<font color=\"purple\"><b>觉醒技</b></font>，准备阶段开始时，若本局的主公为刘备或刘禅，你失去1点体力上限，失去“游龙”，获得“龙胆”，“当千”，并将势力变为蜀。",
   ["dangqian"] = "当千",
   [":dangqian"] = "当你发动龙胆时，你可以弃置x名角色各一张牌（x为你体力值）",
    ["@dangqian"] = "请选择“当千”的对象",
    ["~dangqian"] = "依次选择你要弃牌的对象",


} 











JXXSPZhaoyun = sgs.General(extension, "JXXSPZhaoyun", "shu", "3", true)



LuaZhaoyunFG = sgs.CreateTargetModSkillV2{
        name = "LuaZhaoyunFG",
        frequency = sgs.Skill_NotFrequent,
        pattern = "Slash",
        holder_selector = sgs.CorrectSkill_Primary,
        correct_func = function(skill, ctx)
            local card = ctx:getCard()
            local modType = ctx:getModType()
            if modType == sgs.TargetModSkill_Residue then
                return 1
            elseif modType == sgs.TargetModSkill_DistanceLimit then
                return card and card:isBlack() and 1000 or false
            elseif modType == sgs.TargetModSkill_ExtraTarget then
                return card and card:isRed() and 1 or false
            end
            return false
        end,
    }

LuaJuecaiA = sgs.CreateTriggerSkillV2{
	name = "LuaJuecaiA",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged,sgs.HpRecover},
	can_trigger = function(skill, event, room, player, data)
		local trigger_list_skill, trigger_list_who = {}, {}
		if event == sgs.Damaged then
			for _,p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if p:getMark(skill:objectName().."A".."-Clear") == 0 then
					table.insert(trigger_list_skill, skill:objectName())
					table.insert(trigger_list_who, p:objectName())
				end
			end
		elseif event == sgs.HpRecover then
			for _,p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
				if p:canDiscard(player, "he") and p:getMark(skill:objectName().."B".."-Clear") == 0 then
					table.insert(trigger_list_skill, skill:objectName())
					table.insert(trigger_list_who, p:objectName())
				end
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		if event == sgs.Damaged then
			return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
		elseif event == sgs.HpRecover then
			local dest = sgs.QVariant()
			dest:setValue(ctx.invoker)
			return player:askForSkillInvoke("LuaJuecaiB", dest)
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.Damaged then
			room:addPlayerMark(player, skill:objectName().."A".."-Clear")
			room:broadcastSkillInvoke("LuaJuecaiA", math.random(1,5))
			--room:drawCards(player, 1)
			player:drawCards(1, skill:objectName())
		elseif event == sgs.HpRecover then
			room:addPlayerMark(player, skill:objectName().."B".."-Clear")
			room:broadcastSkillInvoke("LuaJuecaiA",math.random(1,5))
			local id = room:askForCardChosen(player, ctx.invoker, "he", "LuaJuecaiA")
			room:throwCard(id, ctx.invoker, player)
		end
		return false
	end,
}


JXXSPZhaoyun:addSkill(LuaZhaoyunFG)
JXXSPZhaoyun:addSkill(LuaJuecaiA)

sgs.LoadTranslationTable{
--【武将相关】--

["JXXSP"]="界限☆SP",
["JXXSPZhaoyun"]="界限☆SP赵云",
["&JXXSPZhaoyun"]="赵云",
["#JXXSPZhaoyun"]="龙啸九天",
["designer:JXXSPZhaoyun"]="花飞羽落",
["cv:JXXSPZhaoyun"]="眼泪",
["illustrator:JXXSPZhaoyun"]="Feimo非墨",

["LuaZhaoyunFG"]="银枪",
[":LuaZhaoyunFG"]="你使用的红杀可以额外指定一个目标，你使用的黑杀无视距离，你可以额外使用一张杀。",
["LuaJuecaiA"]="绝才",
["LuaJuecaiB"]="绝才",
[":LuaJuecaiA"]="当一名角色恢复体力时，你可以弃置其一张牌，每个角色回合限一次；当一名角色受到伤害后，你可以摸一张牌，每个角色回合限一次。",


["$LuaZhaoyunFG1"]="龙啸九天，银枪破阵。",
["$LuaZhaoyunFG2"]="冲锋陷阵，谁与争锋。",
["$LuaJuecaiA1"]="破釜沉舟，背水一战。",
["$LuaJuecaiA2"]="此等把戏，不足为惧。",
["~JXXSPZhaoyun"]="孔明先生，子龙，尽力了......",
}

jz = sgs.General(extension, "jz", "shu", "4")
cuoyong = sgs.CreateTriggerSkillV2 {
	name = "cuoyong",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DrawNCards },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.DrawNCards or not player:hasSkill(skill:objectName()) then return false end
		local draw = data:toDraw()
		if draw.reason == "draw_phase" and player:isWounded() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local draw = ctx.original_data:toDraw()
		local n = math.min(player:getLostHp(), 2)
		draw.num = draw.num + n
		ctx.original_data:setValue(draw)
		room:broadcastSkillInvoke("juejing")
		return false
	end,
}
jz:addSkill(cuoyong)
jz:addSkill("longdan")
sgs.LoadTranslationTable {
	["jz"] = "赵云",
	["#jz"] = "顺平侯",
	["cuoyong"] = "挫勇",
	[":cuoyong"] = "摸牌阶段，你可额外摸X张牌（X为你已损失的体力值且至多为2） ",
	["$cuoyong"] = "龙战于野，其血玄黄",
	["$cuoyong2"] = "",
	["designer:jz"] = "轩辕夜",
	["cv:jz"] = "官方",
	["illustrator:jz"] = "官方",
}




LuaFangxianCard = sgs.CreateSkillCard{
	name = "LuaFangxianCard",
	skill_name = "LuaFangxian",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	
	on_use = function(self, room, source, targets)
		room:showCard(source, self:getSubcards():first())
		local ids = sgs.IntList()
		for _,other in sgs.qlist(room:getOtherPlayers(source)) do
			if other:isKongcheng() then continue end
			local id = room:askForCardChosen(source, other, "h", "LuaFangxian")
			room:showCard(other, id)
			if sgs.Sanguosha:getCard(id):getSuit() == self:getSuit() or sgs.Sanguosha:getCard(id):getNumber() == self:getNumber() then
				ids:append(id)
			end
		end
		if ids:isEmpty() then return false end
		room:fillAG(ids, source)
		local card = room:askForAG(source, ids, true, "LuaFangxian")
		room:clearAG(source)
		if card ~= -1 then room:obtainCard(source, card) end
		return false
	end,
}

LuaFangxian = sgs.CreateViewAsSkillV2{
	name = "LuaFangxian",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		return player
			and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
			and not player:hasUsed("#LuaFangxianCard")
	end,
	can_select_card = function(skill, request, candidate)
		if not candidate or #request:getSelectedCardIds() >= 1 then return false end
		return not candidate:isEquipped()
	end,
	card_selection_feasible = function(skill, request)
		return #request:getSelectedCardIds() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if #ids ~= 1 then return nil end
		local Skillcard = LuaFangxianCard:clone()
		Skillcard:addSubcard(ids[1])
		return Skillcard
	end,
}

LuaGaobiVS = sgs.CreateViewAsSkillV2{
	name = "LuaGaobi",
	n = 0,
	can_activate = function(skill, request)
		return false
	end,
}
LuaGaobi = sgs.CreateTriggerSkillV2{
	name = "LuaGaobi",
	view_as_skill = LuaGaobiVS,--强迫症表示只是为了让技能按钮不能按下去
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.CardFinished, sgs.EventPhaseChanging},

	on_record = function(skill, event, room, player, ctx)
		if ctx.owner:objectName() == player:objectName()
			and (event == sgs.PreCardUsed or event == sgs.CardResponded)
			and player:getPhase() == sgs.Player_Play then
			local card = nil
			if event == sgs.PreCardUsed then
				card = ctx.original_data:toCardUse().card
			else
				local response = ctx.original_data:toCardResponse()
				if response.m_isUse then card = response.m_card end
			end
			if card and (card:getHandlingMethod() == sgs.Card_MethodUse) then
				if card:isBlack() then room:setCardFlag(card, skill:objectName()) end
			end
		end
		if event == sgs.EventPhaseChanging then
			if ctx.original_data:toPhaseChange().to == sgs.Player_NotActive then
				player:loseAllMarks("@LuaGaobi")
			end
		end
	end,

	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.CardFinished or not player:hasSkill(skill:objectName()) then return false end
		local use = data:toCardUse()
		if use.card and use.card:hasFlag(skill:objectName()) then
			return skill:objectName()
		end
		return false
	end,

	on_cost = function(skill, event, room, player, ctx)
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), skill:objectName(), "@Gaobi-invoke", true, true)
		if not target then return false end
		ctx.targets:append(target)
		return true
	end,

	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.targets:first()
		if target then target:gainMark("@LuaGaobi") end
		return false
	end,
}

LuaGaobiMaxCards = sgs.CreateMaxCardsSkillV2{
	name = "#LuaGaobiMaxCards",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		local holder = ctx:getHolder()
		if not holder then return false end
		return holder:getMark("@LuaGaobi")
	end,
}

sgs.LoadTranslationTable{
	["DoubleNinth"] = "酒祭重阳",
	["LuaHuanjing"] = "桓景",
	["#LuaHuanjing"] = "访仙除魔",
	["LuaFangxian"] = "访仙",["luafangxian"] = "访仙",
	[":LuaFangxian"] = "<font color=\"green\"><b>出牌阶段限一次</b></font>，你可展示一张手牌。若如此做，你依次展示其他角色的各一张手牌，然后你可选择其中一张与你展示的牌点数或花色相同的牌并获得之。",
	["LuaGaobi"] = "高避",
	["@LuaGaobi"] = "额外手牌上限",
	["@Gaobi-invoke"] = "你可对一名角色发动技能<font color=\"yellow\"><b>高避</b></font>", 
	[":LuaGaobi"] = "出牌阶段，每当你使用的黑色牌结算后，你可令一名角色手牌上限+1直到其回合结束。",
	["designer:LuaHuanjing"] = "Amira",
	["illustrator:LuaHuanjing"]	= "cj man",
}

LuaHuanjing = sgs.General(extension, "LuaHuanjing", "god", 3, false)
LuaHuanjing:addSkill(LuaFangxian)
LuaHuanjing:addSkill(LuaGaobi)
LuaHuanjing:addSkill(LuaGaobiMaxCards)
extension:insertRelatedSkills("LuaGaobi", "#LuaGaobiMaxCards")


caoxueyang = sgs.General(extension, "caoxueyang", "shu", "4", false)

--技能生效用隐藏武将
caoxueyang123 = sgs.General(extension, "caoxueyang123", "shu", "4", false, true, true)



--距离
--疾驱。相互-2
LuaChi = sgs.CreateDistanceSkillV2 {
	name = "LuaChi",
	holder_selector = sgs.CorrectSkill_Participants,
	correct_func = function(skill, ctx)
		local from = ctx:getPrimary()
		local to = ctx:getSecondary()
		local holder = ctx:getHolder()
		if from and from:hasSkill(skill:objectName()) then
			return holder == from and -2 or false
		end
		if to and to:hasSkill(skill:objectName()) then
			return holder == to and -2 or false
		end
		return false
	end
}
--驰骋，相互+1，回合内疾驱
LuaCheng = sgs.CreateDistanceSkillV2 {
	name = "LuaCheng",
	holder_selector = sgs.CorrectSkill_Participants,
	correct_func = function(skill, ctx)
		local from = ctx:getPrimary()
		local to = ctx:getSecondary()
		local holder = ctx:getHolder()
		if from and from:hasSkill(skill:objectName()) then
			return holder == from and 1 or false
		end
		if to and to:hasSkill(skill:objectName()) then
			return holder == to and 1 or false
		end
		return false
	end
}
--驰骋+咆哮，ORZ
LuaChicheng = sgs.CreateTriggerSkillV2 {
	name = "#LuaChicheng",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseStart or not player:hasSkill(skill:objectName()) then return false end
		if player:getPhase() == sgs.Player_Start and player:hasSkill("LuaCheng") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		--room:handleAcquireDetachSkills(player, "LuaChi")
		room:acquireOneTurnSkills(player, "LuaCheng", "LuaChi")
		room:addPlayerMark(player, "&LuaChi-Clear")
		return false
	end,
}


--穿云
LuaChuanyun = sgs.CreateTriggerSkillV2 {
	name = "LuaChuanyun",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardUsed, sgs.CardResponded },
	can_trigger = function(skill, event, room, player, data)
		if not player:hasSkill(skill:objectName()) then return false end
		local card = nil
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end
		if card and card:isKindOf("Slash") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local count = player:getMark("&zhican")
		if player:hasSkill("LuaPaoxiaoC") then
			room:broadcastSkillInvoke("LuaPaoxiaoC")
		end
		if count < 6 then
			player:gainMark("&zhican", 2)
		elseif count == 6 then
			player:gainMark("&zhican", 1)
		end
		return false
	end,
}
LuaChuanyun_skill = sgs.CreateTriggerSkillV2 {
	name = "#LuaChuanyun_skill",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseStart or not player:hasSkill(skill:objectName()) then return false end
		if player:getPhase() == sgs.Player_Start and player:hasSkill("LuaChuanyun") and player:getMark("&zhican") > 2 then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		--room:handleAcquireDetachSkills(player, "LuaPaoxiaoC")
		room:acquireOneTurnSkills(player, "LuaChuanyun", "LuaPaoxiaoC")
		room:addPlayerMark(player, "&LuaPaoxiaoC-Clear")
		return false
	end,
}

--龙牙：每当你对目标角色造成伤害，或使用杀指定一名角色为目标后，你可以消耗3层破甲进行一次判定
--红：目标流失一点体力；黑：你摸一张牌
LuaLongya = sgs.CreateTriggerSkillV2 {
	name = "LuaLongya",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damage },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.Damage or not player:hasSkill(skill:objectName()) then return false end
		local damage = data:toDamage()
		if player:getMark("&zhican") > 2 and damage.from
			and damage.from:objectName() == player:objectName() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_pay = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		player:loseMark("&zhican", 3)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		local victim = damage.to
		if not victim or victim:isDead() then return false end
		local judge = sgs.JudgeStruct()
		judge.pattern = "."
		judge.good = true
		judge.who = victim
		judge.reason = skill:objectName()
		room:judge(judge)
		local suit = judge.card:getSuit()
		if suit == sgs.Card_Spade or suit == sgs.Card_Club then
			player:drawCards(1)
		elseif suit == sgs.Card_Heart or suit == sgs.Card_Diamond then
			if victim:isAlive() then
				room:loseHp(victim, 1, true, player, skill:objectName())
			end
		end
		return false
	end,
}

LuaLongyaT = sgs.CreateTriggerSkillV2 {
	name = "#LuaLongyaT",
	events = { sgs.TargetConfirmed },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.TargetConfirmed or not player:hasSkill(skill:objectName()) then return false end
		local use = data:toCardUse()
		if player:getMark("&zhican") > 2 and use.from
			and player:objectName() == use.from:objectName()
			and use.card and use.card:isKindOf("Slash") then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		for _, p in sgs.qlist(use.to) do
			local _data = sgs.QVariant()
			_data:setValue(p)
			if player:askForSkillInvoke("#LuaLongyaT", _data) then
				ctx.targets:append(p)
			end
		end
		return not ctx.targets:isEmpty()
	end,
	on_effect_target = function(skill, event, room, player, ctx, p)
		room:broadcastSkillInvoke(skill:objectName())
		player:loseMark("&zhican", 3)
		p:setFlags("LuaTiejiTarget")
		local judge = sgs.JudgeStruct()
		judge.pattern = "."
		judge.good = true
		judge.reason = skill:objectName()
		judge.who = player
		room:judge(judge)
		local kind = judge.card:getSuit()
		if kind == sgs.Card_Spade or kind == sgs.Card_Club then
			player:drawCards(1)
		elseif kind == sgs.Card_Heart or kind == sgs.Card_Diamond then
			if p:isAlive() then
				room:loseHp(p, 1, true, player, "LuaLongya")
			end
		end
		p:setFlags("-LuaTiejiTarget")
		return false
	end,
}


--[[
	技能名：咆哮（锁定技）曹雪阳
	]]
--
LuaPaoxiaoC = sgs.CreateTargetModSkillV2 {
	name = "LuaPaoxiaoC",
	pattern = "Slash",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		if ctx:getModType() == sgs.TargetModSkill_Residue then
			return 1000
		end
		return false
	end,
}

--技能生效用隐藏武将
caoxueyang123:addSkill(LuaChi)
caoxueyang123:addSkill(LuaPaoxiaoC)

--曹雪阳·穿云龙牙驰骋

caoxueyang:addSkill(LuaChuanyun)
caoxueyang:addSkill(LuaChuanyun_skill)
extension:insertRelatedSkills("LuaChuanyun", "#LuaChuanyun_skill")


caoxueyang:addSkill(LuaLongya)
caoxueyang:addSkill(LuaLongyaT)
extension:insertRelatedSkills("LuaLongya", "#LuaLongyaT")

caoxueyang:addSkill(LuaCheng)
caoxueyang:addSkill(LuaChicheng)
extension:insertRelatedSkills("LuaCheng", "#LuaChicheng")

caoxueyang:addRelateSkill("LuaPaoxiaoC")
caoxueyang:addRelateSkill("LuaChi")




sgs.LoadTranslationTable {
	["xiake"] = "侠客包",

	["caoxueyang"] = "曹雪阳",
	["&caoxueyang"] = "曹雪阳",
	["#caoxueyang"] = "宣威将军",
	["LuaChuanyun"] = "穿云",
	[":LuaChuanyun"] = "每当你使用或打出【杀】时，获得2层【破甲】（至多7层）。准备阶段开始时，若你持有3层或以上的“破甲”，此回合内你获得【咆哮】",
	["LuaPaoxiaoC"] = "咆哮",
	["$LuaPaoxiaoC1"] = "喝！！",
	["$LuaPaoxiaoC2"] = "呀啊啊！！",
	["$LuaPaoxiaoC3"] = "敢挡我？！",
	["$LuaPaoxiaoC4"] = "杀！",
	[":LuaPaoxiaoC"] = "你在出牌阶段内使用【杀】时无次数限制。",
	["LuaLongya"] = "龙牙",
	["$LuaLongya1"] = "就是现在！",
	["$LuaLongya2"] = "这招如何？",
	[":LuaLongya"] = "当你对其他角色造成伤害，或使用【杀】指定其他角色为目标时，你可以消耗3层【破甲】进行一次判定。红：该角色流失一点体力；黑：你摸一张牌",
	["#LuaLongyaT"] = "龙牙",
	["$LuaLongyaT1"] = "当心啊",
	["$LuaLongyaT2"] = "接招啦",
	["LuaChicheng"] = "驰骋",
	[":LuaChicheng"] = "<font color=\"blue\"><b>锁定技，</b></font>你与其他角色相互计算距离时，始终+1；你在回合内获得技能【疾驱】",
	["LuaCheng"] = "驰骋",
	[":LuaCheng"] = "<font color=\"blue\"><b>锁定技，</b></font>你与其他角色相互计算距离时，始终+1；你在回合内获得技能【疾驱】",
	["LuaChi"] = "疾驱",
	[":LuaChi"] = "你与其他角色相互计算距离时，始终-2",
	["@zhican"] = "破甲",
	["zhican"] = "破甲",

	["designer:caoxueyang"] = "Caelamza",
	["illustrator:caoxueyang"] = "伊吹五月",

}

diaochanchan = sgs.General(extension, "diaochanchan", "qun", 3, false)
qingyue = sgs.CreateTriggerSkillV2 {
	name = "qingyue",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DamageCaused },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.DamageCaused or not player:hasSkill(skill:objectName()) then return false end
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash")
			and damage.to and damage.to:isMale() and not damage.to:isNude() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if not damage.to then return false end
		local allcard = sgs.Sanguosha:cloneCard("slash")
		local cards = damage.to:getCards("h")
		for _, card in sgs.qlist(cards) do
			allcard:addSubcard(card)
		end
		room:obtainCard(player, allcard, false)
		allcard:deleteLater()
		room:broadcastSkillInvoke("qingyue", math.random(2))
		return false
	end,
}

cqingxin = sgs.CreateProhibitSkill {
	name = "cqingxin",
	is_prohibited = function(self, from, to, card)
		if to:hasSkill(self:objectName()) then
			return card:isKindOf("TrickCard") and not card:isNDTrick()
		end
	end,
}
biyuechan = sgs.CreateTriggerSkillV2 {
	name = "biyuechan",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseStart or not player:hasSkill(skill:objectName()) then return false end
		if player:getPhase() == sgs.Player_Finish then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName(), math.random(2))
		local x = player:getLostHp() + 1
		player:drawCards(x)
		room:askForDiscard(player, skill:objectName(), 1, 1, false, true)
		return false
	end,
}
diaochanchan:addSkill(qingyue)
diaochanchan:addSkill(cqingxin)
diaochanchan:addSkill(biyuechan)
sgs.LoadTranslationTable {
	["chanbao"] = "蝉包",
	["diaochanchan"] = "貂蝉",
	["qingyue"] = "倾月",
	[":qingyue"] = "当你使用【杀】对男性角色造成伤害后，你可立即获得其所有手牌。",
	["cqingxin"] = "倾心",
	[":cqingxin"] = "<font color=\"blue\"><b>锁定技，</b></font>你不能成为其他角色延时锦囊目标。",
	["biyuechan"] = "蔽月",
	[":biyuechan"] = "回合结束阶段，你可摸1+等同于你已损失的体力的牌数，然后弃1张牌。",
	["~diaochanchan"] = "义父，来世再做您的好女儿。",
	["#diaochanchan"] = "闭月天仙",

	["$biyuechan1"] = "月垂蔽，情依旧。",
	["$biyuechan2"] = "妾身..美吗？",

	["$qingyue1"] = "嗯~就是他！",
	["$qingyue2"] = "都是他的错！",
}


chongmei = sgs.General(extension, 'chongmei', 'god', 3, false)

--[[
要修改杀或者锦囊的目标个数， 
直接修改下面这些函数的return值即可
以下开牌不适用： 
无中，延时锦囊，借刀，AOE, 桃园，五谷，技能卡(比如突袭:TuxuCard)
]]

--同时杀两个玩家
slash_ex1 = sgs.CreateTargetModSkillV2{
	name = "slash_ex1",
	pattern = "Slash",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		if ctx:getModType() == sgs.TargetModSkill_ExtraTarget then
			return 1
		end
		return false
	end,
}

--杀的无距离限制,
--[[
	对于【杀】来说有个bug，目前0224版本的return值小于1000的话是没有效果的,
	所以暂且无法实现“攻击范围为3”这样的效果，只能实现无距离限制的效果
	这个bug在最新的git开发代码上已经修复
]]
slash_ex2 = sgs.CreateTargetModSkillV2{
	name = "slash_ex2",
	pattern = "Slash",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		if ctx:getModType() == sgs.TargetModSkill_DistanceLimit then
			return 1000
		end
		return false
	end,
}


--可使用两张杀，也就是额外使用一张杀
slash_ex3 = sgs.CreateTargetModSkillV2{
	name = "slash_ex3",
	pattern = "Slash",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		if ctx:getModType() == sgs.TargetModSkill_Residue then
			return 1
		end
		return false
	end,
}


--同时顺两个玩家
snatch_ex1 = sgs.CreateTargetModSkillV2{
	name = "snatch_ex1",
	pattern = "Snatch",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		if ctx:getModType() == sgs.TargetModSkill_ExtraTarget then
			return 1
		end
		return false
	end,
}

--可以顺距离为2的人
snatch_ex2 = sgs.CreateTargetModSkillV2{
	name = "snatch_ex2",
	pattern = "Snatch",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		if ctx:getModType() == sgs.TargetModSkill_DistanceLimit then
			return 1
		end
		return false
	end,
}

--可同时拆2个玩家
dismantlement_ex1 = sgs.CreateTargetModSkillV2{
	name = "dismantlement_ex1",
	pattern = "Dismantlement",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		if ctx:getModType() == sgs.TargetModSkill_ExtraTarget then
			return 1
		end
		return false
	end,
}


-- 决斗可同时决斗两个玩家
duel_ex1 = sgs.CreateTargetModSkillV2{
	name = "duel_ex1",
	pattern = "Duel",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		if ctx:getModType() == sgs.TargetModSkill_ExtraTarget then
			return 1
		end
		return false
	end,
}

-- 火攻可同时火攻2个玩家
fireattack_ex1 = sgs.CreateTargetModSkillV2{
	name = "fireattack_ex1",
	pattern = "FireAttack",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		if ctx:getModType() == sgs.TargetModSkill_ExtraTarget then
			return 1
		end
		return false
	end,
}

-- 铁锁可同时指定三个玩家
ironchain_ex1 = sgs.CreateTargetModSkillV2{
	name = "ironchain_ex1",
	pattern = "IronChain",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		if ctx:getModType() == sgs.TargetModSkill_ExtraTarget then
			return 1
		end
		return false
	end,
}

--多喝一次酒，且每次酒都能伤害+1
analeptic_ex1 = sgs.CreateTargetModSkillV2{
	name = "analeptic_ex1",
	pattern = "Analeptic",
	holder_selector = sgs.CorrectSkill_Primary,
	correct_func = function(skill, ctx)
		if ctx:getModType() == sgs.TargetModSkill_Residue then
			return 1
		end
		return false
	end,
}

chongmei:addSkill(slash_ex1)
chongmei:addSkill(slash_ex2)
chongmei:addSkill(slash_ex3)

chongmei:addSkill(snatch_ex1)
chongmei:addSkill(snatch_ex2)
chongmei:addSkill(dismantlement_ex1)

chongmei:addSkill(duel_ex1)
chongmei:addSkill(fireattack_ex1)
chongmei:addSkill(ironchain_ex1)
chongmei:addSkill(analeptic_ex1)



sgs.LoadTranslationTable {
	["chongmei"] = "虫妹",
	['#chongmei'] ='女王受*虫',

	['slash_ex1'] ='双杀',
	[':slash_ex1'] ='你的杀可额外指定一个目标',

	['slash_ex2'] ='强击',
	[':slash_ex2'] ='你的杀无距离限制',

	['slash_ex3'] ='突击',
	[':slash_ex3'] ='你可额外使用一张杀',

	['snatch_ex1'] ='偷梁',
	[':snatch_ex1'] ='你的顺可额外指定一个目标',

	['snatch_ex2'] ='飞贼',
	[':snatch_ex2'] ='你可顺与你距离为2的玩家',

	['dismantlement_ex1'] ='拆迁',
	[':dismantlement_ex1'] ='你的拆可额外指定一个目标',

	['duel_ex1'] ='领导',
	[':duel_ex1'] ='你的决斗可额外指定一目标',

	['fireattack_ex1'] ='火烧',
	[':fireattack_ex1'] ='你的火攻可额外指定一目标',

	['ironchain_ex1'] ='银锁',
	[':ironchain_ex1'] ='你的铁锁可额外指定一目标',

	['analeptic_ex1'] ='贪杯',
	[':analeptic_ex1'] ='出牌阶段你可以多喝一杯酒，且每次酒杀都能伤害+1',
}



xiahoujie_scared = sgs.General(extension, "xiahoujie_scared", "wei", 3)

xhjxianiao = sgs.CreateTriggerSkillV2
{
	name = "xhjxianiao",
	events = sgs.Damage,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.Damage or not player then return false end
		local trigger_list_skill, trigger_list_who = {}, {}
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:inMyAttackRange(p) and p:hasSkill(skill:objectName()) then
				table.insert(trigger_list_skill, skill:objectName())
				table.insert(trigger_list_who, p:objectName())
			end
		end
		if #trigger_list_skill > 0 then
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|")
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())

		room:notifySkillInvoked(player, skill:objectName())
		local log = sgs.LogMessage()
		log.type = "#TriggerSkill"
		log.from = ctx.invoker
		log.to:append(player)
		log.arg = skill:objectName()
		room:sendLog(log)

		player:throwAllHandCards()
		player:drawCards(ctx.invoker:getHp())
		return false
	end
}

xiahoujie_scared:addSkill(xhjxianiao)

xhjtangqiang = sgs.CreateTriggerSkillV2
{
	name = "xhjtangqiang",
	events = sgs.Death,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.Death or not player or not player:hasSkill(skill:objectName()) then return false end
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		if not death.damage or not death.damage.from or death.damage.from:isDead() then return false end
		return skill:objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		local death = ctx.original_data:toDeath()
		if not death.damage or not death.damage.from then return false end
		room:broadcastSkillInvoke(skill:objectName())

		room:notifySkillInvoked(player, skill:objectName())
		local log = sgs.LogMessage()
		log.type = "#TriggerSkill"
		log.from = death.damage.from
		log.to:append(player)
		log.arg = skill:objectName()
		room:sendLog(log)

		room:loseMaxHp(death.damage.from)
		room:acquireSkill(death.damage.from, skill:objectName())
		return false
	end
}

xiahoujie_scared:addSkill(xhjtangqiang)

sgs.LoadTranslationTable{
	["#xiahoujie_scared"] = "神将",
	["xiahoujie_scared"] = "夏侯杰",
	
	["xhjtangqiang"] = "躺枪",
	[":xhjtangqiang"] = "锁定技，杀死你的角色失去1点体力上限并获得技能“躺枪”。",
	
	["xhjxianiao"] = "吓尿",
	[":xhjxianiao"] = "<font color=\"blue\"><b>锁定技，</b></font>当其他角色造成一次伤害时，若你在其攻击范围内，你须弃置所有手牌，然后摸等同于该角色体力值张数的牌。 ",
	["$xhjtangqiang"] = "不是吧？躺着也中枪？",
	["$xhjxianiao"] = "唉呀妈呀，吓死爹了",
	["~xiahoujie_scared"] = "编剧，这不公平",
}


local function cardsChosen(room, player, target, reason, flag, num)
    local maxhand = target:getHandcardNum()
    local hand = 0
    local chosen = sgs.IntList()
    local cards = sgs.QList2Table(target:getCards(flag))
    local max = math.min(#cards, num)
    for i = 1, max, 1 do
        if hand >= maxhand then
            local newflag
            if string.find(flag, "e") then
                if string.find(flag, "j") then
                    newflag = "ej"
                else
                    newflag = "e"
                end
            else
                newflag = "j"
            end

            local id = room:askForCardChosen(player, target, newflag, reason, false, sgs.Card_MethodNone, chosen)
            chosen:append(id)
        else
            local id = room:askForCardChosen(player, target, flag, reason, false, sgs.Card_MethodNone, chosen)
            if room:getCardPlace(id) == sgs.Player_PlaceHand then
                hand = hand + 1
            else
                if not chosen:contains(id) then
                    chosen:append(id)
                else
                    if hand < maxhand then
                        hand = hand + 1
                    else
                        local newflag
                        if string.find(flag, "e") then
                            if string.find(flag, "j") then
                                newflag = "ej"
                            else
                                newflag = "e"
                            end
                        else
                            newflag = "j"
                        end
                        for _,card in sgs.qlist(target:getCards(newflag)) do
                            if not chosen:contains(card:getId()) then
                                chosen:append(card:getId())
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    if hand > 0 then
        cards = sgs.QList2Table(target:getHandcards())
        for i = 1, hand, 1 do
            chosen:append(cards[i]:getId())
        end
    end
    return chosen
end

bu_s2_simayi = sgs.General(extension, "bu_s2_simayi", "wei", 4, true, false, false)

bu_s2_jiashe = sgs.CreateTriggerSkillV2{
    name = "bu_s2_jiashe",
    events = {sgs.DamageInflicted,sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(skill, event, room, player, data)
        if event == sgs.DamageInflicted then
            if not player then return false end
            local damage = data:toDamage()
            if damage.from and damage.from:hasSkill(skill:objectName())
            and damage.damage > player:getHp() and damage.from:objectName() ~= player:objectName() then
                return skill:objectName(), damage.from:objectName()
            end
            return false
        end
        if event == sgs.EventPhaseStart then
            if not player or player:getPhase() ~= sgs.Player_Finish then return false end
            for _,p in sgs.qlist(room:getAllPlayers(true)) do
                if player:getMark("&bu_s2_jiashe+#"..p:objectName()) > 0 then
                    if p:hasSkill(skill:objectName()) then
                        return skill:objectName(), p:objectName()
                    end
                    return skill:objectName()
                end
            end
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        if event == sgs.DamageInflicted then
            local damage = ctx.original_data:toDamage()
            room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true, 1)
            room:setPlayerMark(ctx.invoker, "&bu_s2_jiashe+#"..player:objectName(), 1)
            room:sendLog(CreateDamageLog(damage, damage.damage, skill:objectName(), false))
            damage.prevented = true
            ctx.original_data:setValue(damage)
            return true
        end
        if event == sgs.EventPhaseStart then
            room:sendCompulsoryTriggerLog(player, skill:objectName(), true, true, 2)
            room:killPlayer(ctx.invoker, sgs.DamageStruct(skill:objectName(), nil, ctx.invoker, 0, sgs.DamageStruct_Normal))
            room:getThread():delay(800)
            if player and player:isAlive() and (not player:isNude()) then
                room:broadcastSkillInvoke(skill:objectName(), 3)
                local card_ids = sgs.IntList()
                for _,card in sgs.qlist(player:getCards("he")) do
                    card_ids:append(card:getEffectiveId())
                end
                local log = sgs.LogMessage()
                log.type = "$DiscardCard"
                log.from = player
                log.card_str = table.concat(sgs.QList2Table(card_ids), "+")
                room:sendLog(log)

                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, player:objectName(), skill:objectName(), "")
                local move = sgs.CardsMoveStruct(card_ids, nil, sgs.Player_DiscardPile, reason)
                room:moveCardsAtomic(move, true)
                if player:isAlive() then player:drawCards(card_ids:length(), skill:objectName()) end
            end
        end
        return false
    end,
}

bu_s2_benxiVS = sgs.CreateViewAsSkillV2
{
    name = "bu_s2_benxi",
    n = 0,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        if not player or request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
        if (player:hasUsed("#bu_s2_benxi")) then return false end
        if (not player:getJudgingArea():isEmpty()) then return true end
        for _,other in sgs.qlist(player:getAliveSiblings()) do
            if (not other:getJudgingArea():isEmpty()) then return true end
        end
        return false
    end,
    card_selection_feasible = function(skill, request)
        return #request:getSelectedCardIds() == 0
    end,
    create_card = function(skill, request)
        return bu_s2_benxiCard:clone()
    end,
}

bu_s2_benxiCard = sgs.CreateSkillCard
{
    name = "bu_s2_benxi",
    filter = function(self, targets, to_select, player)
        return #targets < 1 and to_select:objectName() ~= player:objectName()
        and (not to_select:isNude())
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        local n = 0
        for _,player in sgs.qlist(room:getAlivePlayers()) do
            n = n + player:getJudgingArea():length()
        end
        room:addPlayerMark(effect.to, "&bu_s2_benxi+#"..effect.from:objectName().."-Clear", n)
        local card_ids = cardsChosen(room, effect.from, effect.to, self:objectName(), "he", n)
        room:giveCard(effect.to, effect.from, card_ids, self:objectName(), false)
    end,
}

bu_s2_benxi_distance = sgs.CreateDistanceSkillV2{
    name = "#bu_s2_benxi_distance",
    holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(skill, ctx)
        local holder = ctx:getHolder()
        local to = ctx:getSecondary()
        if holder and to and to:getMark("&bu_s2_benxi+#"..holder:objectName().."-Clear") > 0 then return -1000 end
        return false
    end,
}

bu_s2_benxi = sgs.CreateTriggerSkillV2{
    name = "bu_s2_benxi",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = bu_s2_benxiVS,
    can_trigger = function(skill, event, room, player, data)
        if event ~= sgs.DamageCaused or not player or not player:hasSkill(skill:objectName()) then return false end
        local damage = data:toDamage()
        if damage.to and damage.to:getMark("&bu_s2_benxi+#"..player:objectName().."-Clear") > 0 then
            return skill:objectName()
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local damage = ctx.original_data:toDamage()
        local n = damage.to:getMark("&bu_s2_benxi+#"..player:objectName().."-Clear")
        room:sendLog(CreateDamageLog(damage, n, skill:objectName(), true))
        room:broadcastSkillInvoke(skill:objectName())
        damage.damage = damage.damage + n
        ctx.original_data:setValue(damage)
        return false
    end,
}

bu_stwo_guicaiVS = sgs.CreateViewAsSkillV2
{
    name = "bu_stwo_guicai",
    n = 0,
    can_activate = function(skill, request)
        return request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY
            and request:getPattern() == "@@bu_stwo_guicai"
    end,
    card_selection_feasible = function(skill, request)
        return #request:getSelectedCardIds() == 0
    end,
    create_card = function(skill, request)
        return bu_stwo_guicaiCard:clone()
    end,
}

bu_stwo_guicaiCard = sgs.CreateSkillCard
{
    name = "bu_stwo_guicai",
    will_throw = false,
    filter = function(self, targets, to_select, player)
        local card = sgs.Sanguosha:getCard(player:getMark("bu_stwo_guicai"))

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, player) and not player:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets, player)
		local card = sgs.Sanguosha:getCard(player:getMark("bu_stwo_guicai"))

        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
        and (not card:isAvailable(player)) then return false end

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, player) --and card:isAvailable(player)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()

        local log = sgs.LogMessage()
        log.type = "#InvokeSkill"
        log.from = player
        log.arg = self:objectName()
        room:sendLog(log)
        room:broadcastSkillInvoke(self:objectName(), math.random(1,2))

        local card = sgs.Sanguosha:getCard(player:getMark("bu_stwo_guicai"))
        room:obtainCard(player, card, true)
		return card
	end,
}

bu_stwo_guicai = sgs.CreateTriggerSkillV2{
    name = "bu_stwo_guicai",
    events = {sgs.EventPhaseStart,sgs.HpChanged},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = bu_stwo_guicaiVS,
    can_trigger = function(skill, event, room, player, data)
        if event == sgs.EventPhaseStart then
            if not player or player:getPhase() ~= sgs.Player_Start then return false end
            if (player:getJudgingArea():isEmpty()) then return false end
            local trigger_list_skill, trigger_list_who = {}, {}
            for _,p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
                if p:isAlive() and (not p:isNude()) then
                    table.insert(trigger_list_skill, skill:objectName())
                    table.insert(trigger_list_who, p:objectName())
                end
            end
            if #trigger_list_skill > 0 then
                return table.concat(trigger_list_skill, "|"),
                       table.concat(trigger_list_who, "|")
            end
            return false
        end
        if event == sgs.HpChanged then
            if player and player:hasSkill(skill:objectName()) then
                return skill:objectName()
            end
        end
        return false
    end,
    on_cost = function(skill, event, room, player, ctx)
        if event == sgs.EventPhaseStart then
            return room:askForDiscard(player, skill:objectName(), 1, 1, true, true,
                "@bu_stwo_guicai-discard:"..ctx.invoker:getGeneralName(), ".", skill:objectName())
        end
        if event == sgs.HpChanged then
            return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data, false)
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        if event == sgs.EventPhaseStart then
            local choice = room:askForChoice(player, skill:objectName(), "effect+skip")
            local log = sgs.LogMessage()
            log.type = "$bu_stwo_guicai_chosen"
            log.from = player
            log.arg = "bu_stwo_guicai:"..choice
            room:sendLog(log)
            if choice == "skip" then
                ctx.invoker:skip(sgs.Player_Judge)
            else
                for _,card in sgs.qlist(ctx.invoker:getJudgingArea()) do
                    if card:objectName() == "lightning" then
                        local log2 = sgs.LogMessage()
                        log2.type = "$bu_stwo_guicai_judge"
                        log2.from = ctx.invoker
                        log2.card_str = card:toString()
                        room:sendLog(log2)

                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, ctx.invoker:objectName(), skill:objectName(), "")
                        local move = sgs.CardsMoveStruct(card:getEffectiveId(), nil, sgs.Player_DiscardPile, reason)
                        room:moveCardsAtomic(move, true)

                        room:damage(sgs.DamageStruct(card, nil, ctx.invoker, 3, sgs.DamageStruct_Thunder))
                    elseif card:objectName() == "indulgence" then
                        local log2 = sgs.LogMessage()
                        log2.type = "$bu_stwo_guicai_judge"
                        log2.from = ctx.invoker
                        log2.card_str = card:toString()
                        room:sendLog(log2)

                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, ctx.invoker:objectName(), skill:objectName(), "")
                        local move = sgs.CardsMoveStruct(card:getEffectiveId(), nil, sgs.Player_DiscardPile, reason)
                        room:moveCardsAtomic(move, true)

                        ctx.invoker:skip(sgs.Player_Play)
                    elseif card:objectName() == "supply_shortage" then
                        local log2 = sgs.LogMessage()
                        log2.type = "$bu_stwo_guicai_judge"
                        log2.from = ctx.invoker
                        log2.card_str = card:toString()
                        room:sendLog(log2)

                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, ctx.invoker:objectName(), skill:objectName(), "")
                        local move = sgs.CardsMoveStruct(card:getEffectiveId(), nil, sgs.Player_DiscardPile, reason)
                        room:moveCardsAtomic(move, true)

                        ctx.invoker:skip(sgs.Player_Draw)
                    end
                end
                return false
            end
        end
        if event == sgs.HpChanged then
            for _,id in sgs.qlist(room:getDrawPile()) do
                local card = sgs.Sanguosha:getCard(id)
                if card:isKindOf("DelayedTrick") then
                    room:setPlayerMark(player, "bu_stwo_guicai", id)
                    room:askForUseCard(player, "@@bu_stwo_guicai", "@bu_stwo_guicai:"..card:objectName())
                    break
                end
            end
        end
        return false
    end,
}

bu_s2_simayi:addSkill(bu_s2_jiashe)
bu_s2_simayi:addSkill(bu_s2_benxi)
bu_s2_simayi:addSkill(bu_s2_benxiVS)
bu_s2_simayi:addSkill(bu_s2_benxi_distance)
bu_s2_simayi:addSkill(bu_stwo_guicai)
bu_s2_simayi:addSkill(bu_stwo_guicaiVS)
extension:insertRelatedSkills("bu_s2_benxi", "#bu_s2_benxi_distance")

sgs.LoadTranslationTable 
{
    ["budiy"] = "吧友DIY",

    ["bu_s2_simayi"] = "谋司马懿",
    ["&bu_s2_simayi"] = "司马懿",
    ["#bu_s2_simayi"] = "三分一统",
    ["designer:bu_s2_simayi"] = "爱好者S2(设计),Nyarz(lua)",
    ["information:bu_s2_simayi"] = "吧友DIY",

    ["bu_s2_jiashe"] = "假赦",
    [":bu_s2_jiashe"] = "锁定技，你对其他角色造成大于其体力值的伤害时，防止此伤害。该角色的下个结束阶段，你令其死亡，然后你弃置所有牌并摸等量的牌。",
    ["bu_s2_benxi"] = "奔袭",
    [":bu_s2_benxi"] = "出牌阶段限一次，你可以获得一名其他角色的X张牌（X为场上的延时锦囊数）。本回合中：①你与该角色的距离视为1；②你对该角色造成的伤害+X。",
    ["bu_stwo_guicai"] = "鬼才",
    [":bu_stwo_guicai"] = "一名角色的准备阶段，若其判定区内存在延时锦囊，你可以弃置一张牌，选择一项：①令其依次结算其判定区内<font color=\"red\"><b>标准+军争模式中</b></font>延时锦囊的生效效果：②跳过其下个判定阶段。\
    你的体力值变化时，你可以从牌堆中获得并使用一张延时锦囊牌。",
    ["@bu_stwo_guicai"] = "请使用【%src】",
    ["@bu_stwo_guicai-discard"] = "你可以弃置一张牌对 %src 发动“鬼才”",
    ["bu_stwo_guicai:effect"] = "令其依次结算延时锦囊的生效效果",
    ["bu_stwo_guicai:skip"] = "跳过其下个判定阶段",
    ["$bu_stwo_guicai_chosen"] = "%from 选择了 %arg",
    ["$bu_stwo_guicai_judge"] = "%from 的 %card 判定生效",

    ["$bu_s2_benxi1"] = "一鼓作气，破敌制胜！",
    ["$bu_s2_benxi2"] = "受命于天，既寿永昌！",
    ["$bu_s2_jiashe1"] = "赦你死罪，你去吧！",
    ["$bu_s2_jiashe2"] = "天要亡你，谁人能救？",
    ["$bu_s2_jiashe3"] = "天之道，轮回也。",
    ["$bu_stwo_guicai1"] = "忍一时，风平浪静。",
    ["$bu_stwo_guicai2"] = "退一步，海阔天空。",
    ["$bu_stwo_guicai3"] = "老夫，即是天命！",
    ["~bu_s2_simayi"] = "鼎足三分已成梦，一切都结束了。",
}








