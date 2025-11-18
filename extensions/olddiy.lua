module("extensions.olddiy", package.seeall)
extension = sgs.Package("olddiy")

luadiyguanyu = sgs.General(extension, "luadiyguanyu", "shu", 4)

luajuaocard = sgs.CreateSkillCard{
	name = "luajuaocard",
	will_throw = false,
	target_fixed = false,
	once = true,
	filter = function(self, targets, to_select)
		if #targets > 0 then return false end
		return sgs.Self:objectName() ~= to_select:objectName()
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

luajuao = sgs.CreateViewAsSkill{
	name = "luajuao",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Slash")
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local lcard = luajuaocard:clone()
		lcard:addSubcard(cards[1])
		lcard:setSkillName(self:objectName())
		return lcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#luajuaocard")
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
zfduanhevs = sgs.CreateViewAsSkill {
	name = "zfduanhe",
	n = 0,
	view_as = function(self, cards)
		return zfduanhecard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#zfduanhe")
	end,
	enabled_at_response = function()
		return false
	end,
}
zfduanhe = sgs.CreateTriggerSkill {
	name = "zfduanhe",
	view_as_skill = zfduanhevs,
	events = { sgs.Damaged, sgs.EventPhaseStart },
	can_trigger = function(self, target)
		return target ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if not damage.to or damage.to:isDead() then return false end
			for _, zhangfei in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if damage.to:getMark("&" .. self:objectName() .. "+to+#" .. zhangfei:objectName() .. "-Clear") > 0 then
					room:setPlayerMark(damage.to, "&zfduanhe+to+#" .. zhangfei:objectName() .. "-Clear", 0)
					room:setPlayerMark(damage.to, "@zfduanhe-Clear", 0)
					--room:removePlayerCardLimitation(damage.to, "use,response", "BasicCard")
				end
			end
		elseif event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_NotActive then
			for _, to in sgs.qlist(room:getAlivePlayers()) do
				if to:getMark("&" .. self:objectName() .. "+to+#" .. player:objectName() .. "-Clear") > 0 then
					room:setPlayerMark(to, "&zfduanhe+to+#" .. player:objectName() .. "-Clear", 0)
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
lydujiVS = sgs.CreateViewAsSkill{
	name = "lyduji",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:getSuit()==sgs.Card_Spade and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards~=1 then return nil end
		local vscard = lydujicard:clone()
		vscard:addSubcard(cards[1])
		return vscard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#lyduji")
	end,
	enabled_at_response = function()
		return false
	end,
}
lyduji = sgs.CreateTriggerSkill {
	name = "lyduji",
	view_as_skill = lydujiVS,
	events = { sgs.Pindian },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Pindian then
			local pindian = data:toPindian()
			if not pindian.reason == "lyduji" then return  end
			local source = pindian.from
			local target = pindian.to
			for _, liyu in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if liyu:hasFlag("lyduji") then
					if pindian.from_number > pindian.to_number then
						liyu:obtainCard(pindian.from_card)
						if not room:askForDiscard(target, "lyduji", 2, 2, true, false) then
							room:loseHp(target, 1, true, player, self:objectName())
						end
					elseif pindian.from_number < pindian.to_number then
						liyu:obtainCard(pindian.to_card)
						if not room:askForDiscard(source, "lyduji", 2, 2, true, false) then
							room:loseHp(source, 1, true, player, self:objectName())
							--拼点赢了之后
						end
					else
						liyu:obtainCard(pindian.from_card)
						liyu:obtainCard(pindian.to_card)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
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
lyxiance = sgs.CreateViewAsSkill{
	name = "lyxiance",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("TrickCard")
	end,
	view_as = function(self, cards)
		if #cards~=1 then return nil end
		local vscard = lyxiancecard:clone()
		vscard:addSubcard(cards[1])
		return vscard
	end,
	enabled_at_play = function()
		return true
	end,
	enabled_at_response = function()
		return false
	end,
}

lybeixi = sgs.CreateTriggerSkill{
	name = "lybeixi",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.from then
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			room:broadcastSkillInvoke(self:objectName())--然后把配音
			damage.from:turnOver()
			damage.from:drawCards(damage.from:getLostHp())
		end
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

spwushen=sgs.CreateTriggerSkill{
	name="spwushen",
	events={sgs.CardFinished,sgs.PostCardResponded,sgs.CardEffected},
	frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local card=nil
		if event==sgs.CardFinished then card=data:toCardUse().card 
		elseif event==sgs.PostCardResponded then card=data:toCardResponse().m_card 
		end
		if card and card:getSuit()==sgs.Card_Heart and player:hasSkill("spwushen") and not player:hasFlag("spwushen") then
			local card=sgs.Sanguosha:cloneCard("fire_slash",sgs.Card_Heart,0)
			card:deleteLater()
			card:setSkillName("spwushen")
			local players=sgs.SPlayerList()
			room:setPlayerFlag(player, "InfinityAttackRange")
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canUse(card,p) then
				players:append(p) end
			end	
			if players:isEmpty() then return end
			local playerx=room:askForPlayerChosen(player,players,"spwushen", "spwushen-invoke", true, true)
			if playerx then
				local use=sgs.CardUseStruct()
				use.from=player
				use.to:append(playerx)
				use.card=card
				room:setPlayerFlag(player,"spwushen")
				room:useCard(use,false)
				room:setPlayerFlag(player,"-spwushen")	
			end
			room:setPlayerFlag(player, "-InfinityAttackRange")
		end
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

spmengyan_distance=sgs.CreateDistanceSkill{
	name="#spmengyan_distance",
	correct_func=function(self,from,to)
		if to:getMark("@spnightmare") > 0 then
			return -to:getMark("@spnightmare")
		end
        return 0
	end,
}

spmengyan=sgs.CreateTriggerSkill{
	name="spmengyan",
	events={sgs.Damage,sgs.Damaged,sgs.EventLoseSkill},
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if event==sgs.Damage or event==sgs.Damaged then 
			local damage=data:toDamage()
			local target=nil
			if not player:hasSkill(self:objectName()) then return false end
			if event==sgs.Damage then target=damage.to else target=damage.from end
			if not target or target:objectName()==player:objectName() or player:isDead() or target:isDead() then return false end
			room:broadcastSkillInvoke(self:objectName())
			target:gainMark("@spnightmare",damage.damage)
		end
		if event==sgs.EventLoseSkill and data:toString()==self:objectName() then
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("@spnightmare")>0 then
					p:loseAllMarks("@spnightmare")
				end
			end
		end	
	end,	
}

spwuhun=sgs.CreateTriggerSkill{
	name="spwuhun",
	events={sgs.Death},
	frequency=sgs.Skill_Compulsory,
	can_trigger=function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if not player:hasSkill("spwuhun") then return end
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then
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
			local target=room:askForPlayerChosen(player,players,"spwuhun")
			local judge=sgs.JudgeStruct()
			judge.who=player
			judge.good=false
			judge.pattern="Peach,GodSalvation"
			judge.reason=self:objectName()
			room:judge(judge)
			if judge:isGood() then
				room:broadcastSkillInvoke(self:objectName(),1)
				local log=sgs.LogMessage()
				log.type="#spwuhun"
				log.from=player
				log.to:append(target)
				log.arg=maxspnightmare
				room:sendLog(log)			
				room:killPlayer(target)
			else
				room:broadcastSkillInvoke(self:objectName(),2)
			end	
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getMark("@spnightmare")>0 then
					room:loseHp(p,p:getMark("@spnightmare"), true, player, self:objectName())
					p:loseAllMarks("@spnightmare")
				end
			end
		end
	end,
}

spshenguanyu:addSkill(spwushen)
spshenguanyu:addSkill(chihun)
spshenguanyu:addSkill(spmengyan_distance)
spshenguanyu:addSkill(spmengyan)
extension:insertRelatedSkills("spmengyan", "#spmengyan_distance")
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
dj = sgs.CreateTriggerSkill {
	frequency = sgs.Skill_Frequent,
	name = "dj",
	events = { sgs.EventPhaseStart, sgs.FinishJudge },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = player:getLostHp()
		local w = 0
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start) and (x >= 1) then
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
		end
		if (event == sgs.FinishJudge) then
			judge = data:toJudge()
			if (judge.reason == "dj") then
				room:setPlayerMark(player, self:objectName(), 1)
				if (judge.card:getSuit() == sgs.Card_Club) and (not player:hasSkill("paoxiao")) then
					room:acquireNextTurnSkills(player, self:objectName(), "paoxiao")
				end
				if (judge.card:getSuit() == sgs.Card_Spade) and (not player:hasSkill("liegong")) then
					if (judge.card:getNumber() <= 6) then
						room:acquireNextTurnSkills(player, self:objectName(), "liegong")
					elseif not player:hasSkill("tieji") then
						room:acquireNextTurnSkills(player, self:objectName(), "tieji")
					end
				end

				if (judge.card:getSuit() == sgs.Card_Heart) and (not player:hasSkill("wusheng")) then
					room:acquireNextTurnSkills(player, self:objectName(), "wusheng")
				end
				if (judge.card:getSuit() == sgs.Card_Diamond) and (not player:hasSkill("longdan")) then
					room:acquireNextTurnSkills(player, self:objectName(), "longdan")
				end
			end
		end
	end,
}
pj = sgs.CreateTriggerSkill {
	frequency = sgs.Skill_Frequent,
	name = "pj",
	events = { sgs.EventPhaseChanging, sgs.FinishJudge },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local x = player:getLostHp()
		local w = 0
		if (event == sgs.EventPhaseChanging) and (x >= 1) then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
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
		end
		if (event == sgs.FinishJudge) then
			judge = data:toJudge()
			if (judge.reason == "pj") then
				room:setPlayerMark(player, self:objectName(), 1)
				if (judge.card:getSuit() == sgs.Card_Club) and (not player:hasSkill("kongcheng")) then
					room:acquireNextTurnSkills(player, self:objectName(), "kongcheng")
				end
				if (judge.card:getSuit() == sgs.Card_Spade) and (not player:hasSkill("wuyan")) then
					room:acquireNextTurnSkills(player, self:objectName(), "wuyan")
				end

				if (judge.card:getSuit() == sgs.Card_Heart) and (not player:hasSkill("enyuan")) then
					room:acquireNextTurnSkills(player, self:objectName(), "enyuan")
				end
				if (judge.card:getSuit() == sgs.Card_Diamond) and (not player:hasSkill("bazhen")) then
					room:acquireNextTurnSkills(player, self:objectName(), "bazhen")
				end
			end
		end
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

fjsp_youlong = sgs.CreateTriggerSkill{
   name = "fjsp_youlong",
   frequency = sgs.Skill_NotFrequent,
   events = {sgs.DamageComplete,sgs.Damage},
   on_trigger = function (self,event,player,data)
   local room = player:getRoom()
   local list = room:getAlivePlayers()
   if event == sgs.DamageComplete then      
      for _, zhaoyun in sgs.qlist(list) do
         if zhaoyun:isAlive() and zhaoyun:hasSkill(self:objectName()) and zhaoyun:canDiscard(zhaoyun, "he") and zhaoyun:getMark(self:objectName().."using") == 0 then 
			local damage = data:toDamage()
			local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
        	slash:setSkillName(self:objectName())
			slash:deleteLater()
            local targets = sgs.SPlayerList()
			if zhaoyun:canSlash(damage.from, slash, false) then
				targets:append(damage.from)
			end
			if zhaoyun:canSlash(damage.to, slash, false) then
				targets:append(damage.to)
			end
        	if not targets:isEmpty() and room:askForSkillInvoke(zhaoyun,self:objectName(),data) then 
        		room:askForDiscard(zhaoyun,"fjsp_youlong",1,1,false,true) 
                room:addPlayerMark(zhaoyun, self:objectName().."using")
        		local use = sgs.CardUseStruct()       		
        		use.from = zhaoyun
        		use.card = slash 
        		local dest = room:askForPlayerChosen(zhaoyun,targets,self:objectName())
        		use.to:append(dest)
        		room:useCard(use)    
                room:setPlayerMark(zhaoyun, self:objectName().."using", 0)
        	end
         end
      end
    elseif event == sgs.Damage then 
    	local damage = data:toDamage()
    	if damage.card and damage.card:getSkillName()== self:objectName() then 
    	   local zhaoyun = damage.from
           room:drawCards(zhaoyun,1,self:objectName())
           zhaoyun:turnOver()
           room:handleAcquireDetachSkills(zhaoyun, "-"..self:objectName())
   	       room:setPlayerFlag(zhaoyun,"youlong_lose")
   	   end 
   	   return false
   end
   end,
   can_trigger = function(self,target)
   	 return target ~= nil 
   end,
   priority = -1,
}
fjsp_youlong_return = sgs.CreateTriggerSkill{
   name = "#fjsp_youlong_return",
   frequency = sgs.Skill_Compulsory,
   events = {sgs.EventPhaseChanging},
   on_trigger = function (self,event,player,data)
     local room = player:getRoom()
     local list = room:getAlivePlayers()
   	 local change = data:toPhaseChange()
   	 if change.to ~= sgs.Player_NotActive then return false end
   	 for _, zhaoyun in sgs.qlist(list) do
           if zhaoyun:hasFlag("youlong_lose")  then 
              room:setPlayerFlag(zhaoyun,"-youlong_lose")
              room:handleAcquireDetachSkills(zhaoyun,"fjsp_youlong")
           end
       end
    end, 
   can_trigger = function(self,target)
   	 return target ~= nil 
   end,
   }

dangqianCard = sgs.CreateSkillCard{
	name = "dangqianCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
    local player = sgs.Self 	
    return #targets < player:getHp() and player:canDisCard(to_select, "he")
    end,
	feasible = function(self,targets)
	return #targets > 0
	end,
	on_effect = function(self,effect)
      local room = effect.from:getRoom()
      local id = room:askForCardChosen(effect.from,effect.to,"he","dangqian")
       room:throwCard(id,effect.to,effect.from)
	end
}
dangqianVS = sgs.CreateViewAsSkill{
	name = "dangqian",
	n = 0,
	view_as = function(self, cards)
		return dangqianCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@dangqian"
	end
	}

dangqian = sgs.CreateTriggerSkill{
	name = "dangqian" ,
	events = {sgs.CardResponded, sgs.TargetConfirmed, sgs.CardUsed},
	view_as_skill = dangqianVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local arg = player:getHp()
		if event == sgs.CardResponded then
			local resp = data:toCardResponse()
			if (table.contains(resp.m_card:getSkillNames(), "longdan"))  then
				room:askForUseCard(player, "@@dangqian", "@dangqian")
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (use.from:objectName() == player:objectName()) and (table.contains(use.card:getSkillNames(), "longdan")) then
				room:askForUseCard(player, "@@dangqian", "@dangqian")
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if (table.contains(use.card:getSkillNames(), "longdan")) and use.card:isKindOf("Jink")  then
				room:askForUseCard(player, "@@dangqian", "@dangqian")
			end
		end
		return false
	end
}

local Skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("dangqian") then
Skills:append(dangqian)
end
sgs.Sanguosha:addSkills(Skills)

guishu = sgs.CreateTriggerSkill{
	name = "guishu" ,
	events = {sgs.EventPhaseStart} ,
	frequency = sgs.Skill_Wake ,
	waked_skills = "longdan,dangqian",
	on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        player:setMark("guishu", 1)
        local room = player:getRoom()
        if room:changeMaxHpForAwakenSkill(player, -1, self:objectName()) then
            room:setPlayerProperty(player,"kingdom",sgs.QVariant("shu")) 
            room:handleAcquireDetachSkills(player, "longdan")
            room:handleAcquireDetachSkills(player, "dangqian")
            room:handleAcquireDetachSkills(player,"-fjsp_youlong")
            room:handleAcquireDetachSkills(player,"-#youlong_return")
            room:doLightbox("$guishu") 
        end			
		return false
	end ,
    can_wake = function(self, event, player, data, room)
	if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
	if player:canWake(self:objectName()) then return true end
	local lord = room:getLord()
		if lord then
			if (string.find(lord:getGeneralName(),"liubei") or string.find(lord:getGeneral2Name(),"liubei"))
			or (string.find(lord:getGeneralName(),"liushan") or string.find(lord:getGeneral2Name(),"liushan"))  then
                return true
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



LuaZhaoyunFG = sgs.CreateTargetModSkill{
        name = "LuaZhaoyunFG",
        frequency = sgs.Skill_NotFrequent,
        pattern = "Slash",
        extra_target_func = function(self, player, card)
            if player:hasSkill(self:objectName()) and card:isRed() then
                return 1
            else
                return 0
            end
        end,
        distance_limit_func = function(self, player,card)
            if player:hasSkill(self:objectName()) and card:isBlack() then
                return 1000
            else
                return 0
            end
        end,

        residue_func = function(self, player)
            if player:hasSkill(self:objectName()) then
                return 1
            else
                return 0
            end
        end,
    }

LuaJuecaiA = sgs.CreateTriggerSkill{
	name = "LuaJuecaiA",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged,sgs.HpRecover},
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if event == sgs.Damaged then
		local damage = data:toDamage()
		local victim = damage.to
		if damage then
			local list = room:findPlayersBySkillName(self:objectName())
			for _,p in sgs.qlist(list) do
			if p:getMark(self:objectName().."A".."-Clear") == 0 then
					if p:askForSkillInvoke(self:objectName(), data) then
						room:addPlayerMark(p, self:objectName().."A".."-Clear")
						room:broadcastSkillInvoke("LuaJuecaiA", math.random(1,5))
						--room:drawCards(p, 1)
                        p:drawCards(1, self:objectName())
						end
				end
			end
		end
	elseif event == sgs.HpRecover then
		local recover = data:toRecover()
		if recover then
			local room = player:getRoom()
			local list = room:findPlayersBySkillName(self:objectName())
			for _,p in sgs.qlist(list) do
				if p:canDiscard(player, "he") then --裸的
					if p:getMark(self:objectName().."B".."-Clear") == 0 then
						local dest = sgs.QVariant()
						dest:setValue(player)
						if p:askForSkillInvoke("LuaJuecaiB", dest) then
						room:addPlayerMark(p, self:objectName().."B".."-Clear")
							room:broadcastSkillInvoke("LuaJuecaiA",math.random(1,5))
							local id = room:askForCardChosen(p,player,"he","LuaJuecaiA")
							room:throwCard(id,player,p)
						end
					end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
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
cuoyong = sgs.CreateTriggerSkill {
	name = "cuoyong",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		local n = math.min(player:getLostHp(), 2)
		if player:isWounded() then
			if room:askForSkillInvoke(player, "cuoyong", data) then
				draw.num = draw.num + n
				data:setValue(draw)
				room:broadcastSkillInvoke("juejing")
			end
		end
	end
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

LuaFangxian = sgs.CreateOneCardViewAsSkill{
	name = "LuaFangxian",
	filter_pattern = ".|.|.|hand",
	view_as = function(self, card)
		local Skillcard = LuaFangxianCard:clone()
		Skillcard:addSubcard(card)
		return Skillcard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#LuaFangxianCard")
	end, 
}

LuaGaobiVS = sgs.CreateZeroCardViewAsSkill{
	name = "LuaGaobi",
	enabled_at_play = function(self, player)
		return false
	end, 
}
LuaGaobi = sgs.CreateTriggerSkill{
	name = "LuaGaobi",
	view_as_skill = LuaGaobiVS,--强迫症表示只是为了让技能按钮不能按下去
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.CardFinished, sgs.EventPhaseChanging},
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		
		if player:hasSkill(self:objectName()) and (event == sgs.PreCardUsed or event == sgs.CardResponded) and player:getPhase() == sgs.Player_Play then
			local card = nil
			if event == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				local response = data:toCardResponse()
				if response.m_isUse then card = response.m_card end
			end
			if card and (card:getHandlingMethod() == sgs.Card_MethodUse) then
				if card:isBlack() then room:setCardFlag(card, self:objectName()) end
			end
		end
		
		if player:hasSkill(self:objectName()) and event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:hasFlag(self:objectName()) then
				local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "@Gaobi-invoke", true, true)
				if target then target:gainMark("@LuaGaobi") end
			end
		end
		
		if event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_NotActive then
				player:loseAllMarks("@LuaGaobi")
			end
		end
	end,
	
	can_trigger = function(self, target)
		return target:isAlive()
	end,
}

LuaGaobiMaxCards = sgs.CreateMaxCardsSkill{
	name = "#LuaGaobiMaxCards",
	
	extra_func = function(self, target) 
		return target:getMark("@LuaGaobi")
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
LuaChi = sgs.CreateDistanceSkill {
	name = "LuaChi",
	correct_func = function(self, from, to)
		if from:hasSkill("LuaChi") then
			return -2
		end
		if to:hasSkill("LuaChi") then
			return -2
		end
	end
}
--驰骋，相互+1，回合内疾驱
LuaCheng = sgs.CreateDistanceSkill {
	name = "LuaCheng",
	correct_func = function(self, from, to)
		if from:hasSkill("LuaCheng") then
			return 1
		end
		if to:hasSkill("LuaCheng") then
			return 1
		end
	end
}
--驰骋+咆哮，ORZ
LuaChicheng = sgs.CreateTriggerSkill {
	name = "#LuaChicheng",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		if phase == sgs.Player_Start then
			local room = player:getRoom()
			if player:hasSkill("LuaCheng") then
				--room:handleAcquireDetachSkills(player, "LuaChi")
				room:acquireOneTurnSkills(player, "LuaCheng", "LuaChi")
				room:addPlayerMark(player, "&LuaChi-Clear")
			end
		end
	end
}


--穿云
LuaChuanyun = sgs.CreateTriggerSkill {
	name = "LuaChuanyun",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardUsed, sgs.CardResponded },
	on_trigger = function(self, event, player, data)
		local card = nil
		local room = player:getRoom()
		if event == sgs.CardUsed then
			use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			card = data:toCardResponse().m_card
		end
		if card:isKindOf("Slash") then
			local count = player:getMark("&zhican")
			if player:hasSkill("LuaPaoxiaoC") then
				room:broadcastSkillInvoke("LuaPaoxiaoC")
			end
			if count < 6 then
				player:gainMark("&zhican", 2)
			elseif count == 6 then
				player:gainMark("&zhican", 1)
			end
		end
	end
}
LuaChuanyun_skill = sgs.CreateTriggerSkill {
	name = "#LuaChuanyun_skill",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local phase = player:getPhase()
		if phase == sgs.Player_Start then
			local room = player:getRoom()
			local count = player:getMark("&zhican")
			if (player:hasSkill("LuaChuanyun")) and (count > 2) then
				--room:handleAcquireDetachSkills(player, "LuaPaoxiaoC")
				room:acquireOneTurnSkills(player, "LuaChuanyun", "LuaPaoxiaoC")
				room:addPlayerMark(player, "&LuaPaoxiaoC-Clear")
			end
		end
	end
}

--龙牙：每当你对目标角色造成伤害，或使用杀指定一名角色为目标后，你可以消耗3层破甲进行一次判定
--红：目标流失一点体力；黑：你摸一张牌
LuaLongya = sgs.CreateTriggerSkill {
	name = "LuaLongya",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Damage },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		local count = player:getMark("&zhican")
		if count > 2 then
			if damage.from and damage.from:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName(), data) then
				local victim = damage.to
				if not victim:isDead() then
					room:broadcastSkillInvoke(self:objectName())
					player:loseMark("&zhican", 3)
					local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.good = true
					judge.who = victim
					judge.reason = self:objectName()
					room:judge(judge)
					local suit = judge.card:getSuit()
					if suit == sgs.Card_Spade or suit == sgs.Card_Club then
						player:drawCards(1)
					elseif suit == sgs.Card_Heart or suit == sgs.Card_Diamond then
						if victim:isAlive() then
							room:loseHp(victim, 1, true, player, self:objectName())
						end
					end
				end
			end
		end
	end
}

LuaLongyaT = sgs.CreateTriggerSkill {
	name = "#LuaLongyaT",
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local use = data:toCardUse()
		local room = player:getRoom()
		local count = player:getMark("&zhican")
		if count > 2 then
			if not use.from or (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end

			for _, p in sgs.qlist(use.to) do
				local _data = sgs.QVariant()
				_data:setValue(p)
				if player:askForSkillInvoke("#LuaLongyaT", _data) then
					room:broadcastSkillInvoke(self:objectName())
					player:loseMark("&zhican", 3)
					p:setFlags("LuaTiejiTarget")
					local judge = sgs.JudgeStruct()
					judge.pattern = "."
					judge.good = true
					judge.reason = self:objectName()
					judge.who = player
					player:getRoom():judge(judge)
					local kind = judge.card:getSuit()
					if kind == sgs.Card_Spade or kind == sgs.Card_Club then
						player:drawCards(1)
					elseif kind == sgs.Card_Heart or kind == sgs.Card_Diamond then
						if p:isAlive() then
							room:loseHp(p, 1, true, player, "LuaLongya")
						end
					end
					p:setFlags("-LuaTiejiTarget")
				end
			end
		end
	end
}


--[[
	技能名：咆哮（锁定技）曹雪阳
	]]
--
LuaPaoxiaoC = sgs.CreateTargetModSkill {
	name = "LuaPaoxiaoC",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1000
		end
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
qingyue = sgs.CreateTriggerSkill {
	name = "qingyue",
	frequency = sgs.Skill_Frequent,
	events = { sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local reason = damage.card
		if reason and not damage.to:isNude() then
			if reason:isKindOf("Slash") and damage.to:isMale() then
				if not damage.to:isNude() then
					if player:askForSkillInvoke(self:objectName(), data) then
						local allcard = sgs.Sanguosha:cloneCard("slash")
						local cards = damage.to:getCards("h")
						for _, card in sgs.qlist(cards) do
							allcard:addSubcard(card)
						end
						allcard:deleteLater()
						player:getRoom():obtainCard(player, allcard, false)
						player:getRoom():broadcastSkillInvoke("qingyue", math.random(2))
					end
				end
			end
		end
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
biyuechan = sgs.CreateTriggerSkill {
	name = "biyuechan",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	can_trigger = function(self, target)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and player:hasSkill("biyuechan") then
			if not room:askForSkillInvoke(player, "biyuechan", data) then return false end
			room:broadcastSkillInvoke("biyuechan", math.random(2))
			local x = player:getLostHp() + 1
			player:drawCards(x)
			room:askForDiscard(player, self:objectName(), 1, 1, false, true)
		end
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
slash_ex1 = sgs.CreateTargetModSkill{
	name = "slash_ex1",
	pattern = "Slash",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

--杀的无距离限制,  
--[[
	对于【杀】来说有个bug，目前0224版本的return值小于1000的话是没有效果的, 
	所以暂且无法实现“攻击范围为3”这样的效果，只能实现无距离限制的效果
	这个bug在最新的git开发代码上已经修复
]]
slash_ex2 = sgs.CreateTargetModSkill{
	name = "slash_ex2",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1000
		end
	end,
}


--可使用两张杀，也就是额外使用一张杀
slash_ex3 = sgs.CreateTargetModSkill{
	name = "slash_ex3",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}


--同时顺两个玩家
snatch_ex1 = sgs.CreateTargetModSkill{
	name = "snatch_ex1",
	pattern = "Snatch",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

--可以顺距离为2的人
snatch_ex2 = sgs.CreateTargetModSkill{
	name = "snatch_ex2",
	pattern = "Snatch",
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

--可同时拆2个玩家
dismantlement_ex1 = sgs.CreateTargetModSkill{
	name = "dismantlement_ex1",
	pattern = "Dismantlement",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}


-- 决斗可同时决斗两个玩家
duel_ex1 = sgs.CreateTargetModSkill{
	name = "duel_ex1",
	pattern = "Duel",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

-- 火攻可同时火攻2个玩家
fireattack_ex1 = sgs.CreateTargetModSkill{
	name = "fireattack_ex1",
	pattern = "FireAttack",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

-- 铁锁可同时指定三个玩家
ironchain_ex1 = sgs.CreateTargetModSkill{
	name = "ironchain_ex1",
	pattern = "IronChain",
	extra_target_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
	end,
}

--多喝一次酒，且每次酒都能伤害+1
analeptic_ex1 = sgs.CreateTargetModSkill{
	name = "analeptic_ex1",
	pattern = "Analeptic",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1
		end
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

xhjxianiao = sgs.CreateTriggerSkill
{
	name = "xhjxianiao",
	events = sgs.Damage,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:inMyAttackRange(p) and p:hasSkill(self:objectName()) then
				room:broadcastSkillInvoke(self:objectName())
				
				room:notifySkillInvoked(p, self:objectName())
				local log = sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = player
				log.to:append(p)
				log.arg = self:objectName()
				room:sendLog(log)
				
				p:throwAllHandCards()
				p:drawCards(player:getHp())
			end
		end
		return false
	end
}

xiahoujie_scared:addSkill(xhjxianiao)

xhjtangqiang = sgs.CreateTriggerSkill
{
	name = "xhjtangqiang",
	events = sgs.Death,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		if not death.damage or not death.damage.from or death.damage.from:isDead() then return false end
		room:broadcastSkillInvoke(self:objectName())
		
		room:notifySkillInvoked(player, self:objectName())
		local log = sgs.LogMessage()
		log.type = "#TriggerSkill"
		log.from = death.damage.from
		log.to:append(player)
		log.arg = self:objectName()
		room:sendLog(log)
		
		room:loseMaxHp(death.damage.from)
		room:acquireSkill(death.damage.from, self:objectName())
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





local function CreateDamageLog(damage, changenum, reason, up)
    if up == nil then up = true end
    local log = sgs.LogMessage()
    if damage.from then
        log.type = "$nyarzdamagechange"
        log.from = damage.from
        log.arg5 = damage.to:getGeneralName()
    else
        log.type = "$nyarzdamagechangenofrom"
        log.from = damage.to
    end
    log.arg = reason
    log.arg2 = damage.damage
    if up then
        log.arg3 = "nyarzdamageup"
        log.arg4 = damage.damage + changenum
    else
        log.arg3 = "nyarzdamagedown"
        log.arg4 = damage.damage - changenum
    end
    return log
end

sgs.LoadTranslationTable 
{
    ["$nyarzdamagechange"] = "%from 对 %arg5 造成的伤害因 %arg 的效果由 %arg2 点 %arg3 到了 %arg4 点。",
    ["$nyarzdamagechangenofrom"] = "%from 受到的伤害因 %arg 的效果由 %arg2 点 %arg3 到了 %arg4 点。",
    ["nyarzdamageup"] = "增加",
    ["nyarzdamagedown"] = "减少",
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

bu_s2_jiashe = sgs.CreateTriggerSkill{
    name = "bu_s2_jiashe",
    events = {sgs.DamageInflicted,sgs.EventPhaseStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if damage.from and damage.from:hasSkill(self:objectName())
            and damage.damage > player:getHp() and damage.from:objectName() ~= player:objectName() then
                room:sendCompulsoryTriggerLog(damage.from, self:objectName(), true, true, 1)
                room:setPlayerMark(player, "&bu_s2_jiashe+#"..damage.from:objectName(), 1)
                room:sendLog(CreateDamageLog(damage, damage.damage, self:objectName(), false))
				damage.prevented = true
				data:setValue(damage)
                return true
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Finish then return false end
            local target
            for _,p in sgs.qlist(room:getAllPlayers(true)) do
                if player:getMark("&bu_s2_jiashe+#"..p:objectName()) > 0 then
                    target = p
                    break
                end
            end
            if (not target) then return false end
            room:sendCompulsoryTriggerLog(target, self:objectName(), true, true, 2)
            room:killPlayer(player, sgs.DamageStruct(self:objectName(), nil, player, 0, sgs.DamageStruct_Normal))
            room:getThread():delay(800)
            if target and target:isAlive() and (not target:isNude()) then
                room:broadcastSkillInvoke(self:objectName(), 3)
                local card_ids = sgs.IntList()
                for _,card in sgs.qlist(target:getCards("he")) do
                    card_ids:append(card:getEffectiveId())
                end
                local log = sgs.LogMessage()
                log.type = "$DiscardCard"
                log.from = target
                log.card_str = table.concat(sgs.QList2Table(card_ids), "+")
                room:sendLog(log)

                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, target:objectName(), self:objectName(), "")
                local move = sgs.CardsMoveStruct(card_ids, nil, sgs.Player_DiscardPile, reason)
                room:moveCardsAtomic(move, true)
                if target:isAlive() then target:drawCards(card_ids:length(), self:objectName()) end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target ~= nil
    end,
}

bu_s2_benxiVS = sgs.CreateZeroCardViewAsSkill
{
    name = "bu_s2_benxi",
    view_as = function(self)
        return bu_s2_benxiCard:clone()
    end,
    enabled_at_play = function(self, player)
        if (player:hasUsed("#bu_s2_benxi")) then return false end
        if (not player:getJudgingArea():isEmpty()) then return true end
        for _,other in sgs.qlist(player:getAliveSiblings()) do
            if (not other:getJudgingArea():isEmpty()) then return true end
        end
        return false
    end
}

bu_s2_benxiCard = sgs.CreateSkillCard
{
    name = "bu_s2_benxi",
    filter = function(self, targets, to_select)
        return #targets < 1 and to_select:objectName() ~= sgs.Self:objectName()
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

bu_s2_benxi_distance = sgs.CreateDistanceSkill{
    name = "#bu_s2_benxi_distance",
    correct_func = function(self, from, to)
        if from and to and to:getMark("&bu_s2_benxi+#"..from:objectName().."-Clear") > 0 then return -1000 end
        return 0
    end,
}

bu_s2_benxi = sgs.CreateTriggerSkill{
    name = "bu_s2_benxi",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = bu_s2_benxiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.to:getMark("&bu_s2_benxi+#"..player:objectName().."-Clear") > 0 then
            local n = damage.to:getMark("&bu_s2_benxi+#"..player:objectName().."-Clear")
            room:sendLog(CreateDamageLog(damage, n, self:objectName(), true))
            room:broadcastSkillInvoke(self:objectName())
            damage.damage = damage.damage + n
            data:setValue(damage)
        end
            
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

bu_stwo_guicaiVS = sgs.CreateZeroCardViewAsSkill
{
    name = "bu_stwo_guicai",
    response_pattern = "@@bu_stwo_guicai",
    view_as = function(self)
        return bu_stwo_guicaiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return false
    end
}

bu_stwo_guicaiCard = sgs.CreateSkillCard
{
    name = "bu_stwo_guicai",
    will_throw = false,
    filter = function(self, targets, to_select)
        local card = sgs.Sanguosha:getCard(sgs.Self:getMark("bu_stwo_guicai"))

		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
	end,
	feasible = function(self, targets)
		local card = sgs.Sanguosha:getCard(sgs.Self:getMark("bu_stwo_guicai"))

        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
        and (not card:isAvailable(sgs.Self)) then return false end

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card and card:canRecast() and #targets == 0 then
			return false
		end
		return card and card:targetsFeasible(qtargets, sgs.Self) --and card:isAvailable(sgs.Self)
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

bu_stwo_guicai = sgs.CreateTriggerSkill{
    name = "bu_stwo_guicai",
    events = {sgs.EventPhaseStart,sgs.HpChanged},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = bu_stwo_guicaiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start then return false end
            if (player:getJudgingArea():isEmpty()) then return false end
            for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:isAlive() and (not p:isNude()) then
                    if room:askForDiscard(p, self:objectName(), 1, 1, true, true, "@bu_stwo_guicai-discard:"..player:getGeneralName(), ".", self:objectName()) then
                        local choice = room:askForChoice(p, self:objectName(), "effect+skip")
                        local log = sgs.LogMessage()
                        log.type = "$bu_stwo_guicai_chosen"
                        log.from = p
                        log.arg = "bu_stwo_guicai:"..choice
                        room:sendLog(log)
                        if choice == "skip" then
                            player:skip(sgs.Player_Judge)
                        else
                            for _,card in sgs.qlist(player:getJudgingArea()) do
                                if card:objectName() == "lightning" then
                                    local log2 = sgs.LogMessage()
                                    log2.type = "$bu_stwo_guicai_judge"
                                    log2.from = player
                                    log2.card_str = card:toString()
                                    room:sendLog(log2)

                                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), "")
                                    local move = sgs.CardsMoveStruct(card:getEffectiveId(), nil, sgs.Player_DiscardPile, reason)
                                    room:moveCardsAtomic(move, true)

                                    room:damage(sgs.DamageStruct(card, nil, player, 3, sgs.DamageStruct_Thunder))
                                elseif card:objectName() == "indulgence" then
                                    local log2 = sgs.LogMessage()
                                    log2.type = "$bu_stwo_guicai_judge"
                                    log2.from = player
                                    log2.card_str = card:toString()
                                    room:sendLog(log2)

                                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), "")
                                    local move = sgs.CardsMoveStruct(card:getEffectiveId(), nil, sgs.Player_DiscardPile, reason)
                                    room:moveCardsAtomic(move, true)

                                    player:skip(sgs.Player_Play)
                                elseif card:objectName() == "supply_shortage" then
                                    local log2 = sgs.LogMessage()
                                    log2.type = "$bu_stwo_guicai_judge"
                                    log2.from = player
                                    log2.card_str = card:toString()
                                    room:sendLog(log2)

                                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), self:objectName(), "")
                                    local move = sgs.CardsMoveStruct(card:getEffectiveId(), nil, sgs.Player_DiscardPile, reason)
                                    room:moveCardsAtomic(move, true)

                                    player:skip(sgs.Player_Draw)
                                end
                            end
                            return false
                        end
                    end
                end
            end
        end
        if event == sgs.HpChanged then
            if (not player:hasSkill(self:objectName())) then return false end
            if room:askForSkillInvoke(player, self:objectName(), data, false) then
                for _,id in sgs.qlist(room:getDrawPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:isKindOf("DelayedTrick") then
                        room:setPlayerMark(player, "bu_stwo_guicai", id)
                        room:askForUseCard(player, "@@bu_stwo_guicai", "@bu_stwo_guicai:"..card:objectName())
                        break
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
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








