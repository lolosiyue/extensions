module("extensions.mcompetition",package.seeall)
extension=sgs.Package("mcompetition")

sgs.LoadTranslationTable{
    ["mcompetition"] = "萌战competition",
}

sgs.addSkillToEngine = function(skill)
    local skill_list = sgs.SkillList()
    if type(skill) == "table" then
        for _,ski in pairs(skill)do
            if not sgs.Sanguosha:getSkill(ski:objectName()) then
                skill_list:append(ski)
            end
        end
        sgs.Sanguosha:addSkills(skill_list)
        return true
    end
    if not sgs.Sanguosha:getSkill(skill:objectName()) then
        skill_list:append(skill)
        sgs.Sanguosha:addSkills(skill_list)
        return true
    end
    return false
end

GlobalFakeMove = sgs.CreateTriggerSkill{
    name = "GlobalFakeMove" ,
    global = true,
    events = {sgs.BeforeCardsMove, sgs.CardsMoveOneTime} ,
    priority = 10 ,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _, p in sgs.qlist(room:getAllPlayers()) do
            if p:hasFlag("Global_InTempMoving") then return true end
        end
        return false
    end
}

sgs.addSkillToEngine(GlobalFakeMove)

haruhi=sgs.General(extension,"haruhi","real",3,false,false)

shenyi = sgs.CreateTriggerSkill{
    name = "shenyi" ,
    events = {sgs.EventPhaseStart,sgs.EventPhaseChanging} ,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local phase_names = {"start", "judge", "draw", "play", "discard", "finish", "not_active"}
        if event==sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                local choices = {}
                for _,phase in sgs.qlist(player:getPhases()) do
                    if phase == sgs.Player_Draw or phase == sgs.Player_Play or phase == sgs.Player_Discard then
                        table.insert(choices, phase_names[phase])
                    end
                end
                for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() ~= player:objectName() and p:getMark("zhuanshan") == 0 then continue end
                    if (not room:askForSkillInvoke(p,self:objectName(),data)) then continue end
                    local Phases = ""
                    while #choices > 0 do
                        local choice = room:askForChoice(p, self:objectName(), table.concat(choices, "+"), sgs.QVariant(Phases))
                        table.removeOne(choices,choice)
                        if Phases == "" then
                            Phases = choice
                        else
                            Phases = Phases.."+"..choice
                        end
                    end
                    player:setTag(self:objectName(), sgs.QVariant(Phases))
                end
            end
        elseif event==sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Draw or change.to == sgs.Player_Play or change.to == sgs.Player_Discard then
                local tochange = nil
                if player:getTag(self:objectName()):toString() ~= "" then
                    local Phases = player:getTag(self:objectName()):toString():split("+")
                    for i=1, #phase_names, 1 do
                        if Phases[1] == phase_names[i] then
                            tochange = i
                            table.remove(Phases,1)
                            break
                        end
                    end
                    if #Phases > 0 then
                        player:setTag(self:objectName(), sgs.QVariant(table.concat(Phases, "+")))
                    else
                        player:setTag(self:objectName(), sgs.QVariant())
                    end
                end
                if not tochange then return false end
                if change.to ~= tochange then
                    if not player:isSkipped(change.to) then
                        change.to = tochange
                        local log = sgs.LogMessage()
                        log.type = "#shenyi"
                        log.from = player
                        log.arg = phase_names[change.to]
                        room:sendLog(log)
                        data:setValue(change)
                    else
                        player:changePhase(change.to, tochange)
                    end
                end
            else
                return false
            end
            return false
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

zhuanshan = sgs.CreateTriggerSkill{
    name = "zhuanshan" ,
    events = {sgs.EventPhaseStart,sgs.EventPhaseChanging, sgs.Death, sgs.EventLoseSkill} ,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event==sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_RoundStart then
                for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:objectName() == player:objectName() or player:isKongcheng() or p:isKongcheng() then continue end
                    if p:canPindian(player) and room:askForSkillInvoke(p, self:objectName()) then
                        
                        local success = p:pindian(player, self:objectName(), nil)
                        local _playerdata = sgs.QVariant()
                        _playerdata:setValue(player)
                        p:setTag(self:objectName(), _playerdata)
                        if success then
                            room:addPlayerMark(p, "zhuanshan")
                            room:addPlayerMark(p, "&zhuanshan-Clear")
                            room:changeTranslation(player, "shenyi", 2)
                        else
                            if not player:hasSkill("shenyi") then
                                room:acquireOneTurnSkills(player, "zhuanshan", "shenyi")
                            end
                        end
                        
                    end
                end
            end
        else
            if event == sgs.EventPhaseChanging then
                local change = data:toPhaseChange()
                if change.to ~= sgs.Player_NotActive then return false end
            elseif event == sgs.Death then
                local death = data:toDeath()
                if death.who:objectName() ~= player:objectName() then return false end
            elseif event == sgs.EventLoseSkill then
                if data:toString() ~= self:objectName() then return false end
            end
            for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("zhuanshan") > 0 then
                    room:setPlayerMark(p, "zhuanshan",0)
                end
                p:setTag(self:objectName(), sgs.QVariant())
                room:changeTranslation(p, "shenyi", 1)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

haruhi:addSkill(shenyi)
haruhi:addSkill(zhuanshan)

sgs.LoadTranslationTable{
    ["#haruhi"] = "SOS团长",
    ["haruhi"] = "凉宫春日",
    ["designer:haruhi"] = "zengzouyu",
    ["cv:haruhi"] = "",
    ["illustrator:haruhi"] = "tosh、葱",
    ["shenyi"] = "神意",
    [":shenyi"] = "准备阶段，你可以调整本回合摸牌阶段、出牌阶段以及弃牌阶段的先后顺序。",
    [":shenyi1"] = "准备阶段，你可以调整本回合摸牌阶段、出牌阶段以及弃牌阶段的先后顺序。",
    [":shenyi2"] = "任意角色准备阶段，你可以调整本回合摸牌阶段、出牌阶段以及弃牌阶段的先后顺序。",
    ["#shenyi"] = "“<font color='yellow'><b>神意</b></font>”被触发，%from将执行<b><font color='#98fb98'>%arg</font></b>阶段",
    ["zhuanshan"] = "专擅",
    [":zhuanshan"] = "其他角色的回合开始时，你可以与该角色拼点，若你赢，你将“神意”描述中的“准备阶段”改为“任意角色准备阶段”直到回合结束；若你没赢该角色获得“神意”直到回合结束。",
}

lancelot = sgs.General(extension, "lancelot", "magic",4)

qishibusiyutushou = sgs.CreateTriggerSkill{
	name = "qishibusiyutushou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local lostall = false
		if event == sgs.EventLoseSkill then
			if data:toString() ~= self:objectName() then return false end
			lostall = true
		elseif player:getWeapon() then
			lostall = true
		end
		local players = room:getOtherPlayers(player)
		local range_list = sgs.IntList()
		local maxrange = 0
		local noweapon = true
		for _,p in sgs.qlist(players) do
			local range = 0
			if p:getWeapon() then
				local card = p:getWeapon():getRealCard():toWeapon()
				range = card:getRange()
				noweapon = false
			end
			range_list:append(range)
			maxrange = math.max(maxrange, range)
		end
		if lostall or noweapon then
			local marks = player:getMarkNames()
			local lost = {}
			for _,m in ipairs(marks) do--
				if string.find(m,self:objectName()) then
					table.insert(lost, m)
				end
			end
			for _,m in ipairs(lost) do
				if player:getMark(m) > 0 then
					room:removePlayerMark(player, m)
					local log= sgs.LogMessage()
	                log.type = "#qishibusiyutushou_lost"
                    log.from = player
                    log.arg = self:objectName()
                    room:sendLog(log)
				end
			end
            room:setPlayerProperty(player,"qishibusiyutushouEquips",ToData(""))
			return false
		else
			local weapons = {}
			local weapons2 = {}
			for i = 0, range_list:length() - 1, 1 do
				if range_list:at(i) == maxrange then
					local weapon = players:at(i):getWeapon()
					table.insert(weapons, self:objectName()..weapon:objectName())
					table.insert(weapons2, weapon:objectName())
				end
			end
			if event == sgs.EventAcquireSkill or event == sgs.CardsMoveOneTime then
				if not player:isAlive() or not player:hasSkill(self:objectName(), true) then return false end
				if event == sgs.EventAcquireSkill then
					if data:toString() ~= self:objectName() then return false end
				elseif event == sgs.CardsMoveOneTime then
					local move = data:toMoveOneTime()
					if move.to_place ~= sgs.Player_PlaceEquip and not move.from_places:contains(sgs.Player_PlaceEquip) then return false end
				end
				local marks = player:getMarkNames()
				local lost = {}
				for _,m in ipairs(marks) do--
					if string.find(m,self:objectName()) and not table.contains(weapons2, m) then
						table.insert(lost, m)
					end
				end
				for _,m in ipairs(lost) do--
					if player:getMark(m) > 0 then
						room:removePlayerMark(player, m)
					end
				end
				for _,m in ipairs(weapons) do--
					if player:getMark(m) == 0 then
						room:addPlayerMark(player, m)
						room:addPlayerMark(player, "&".. self:objectName() .. string.gsub(m, self:objectName(), "+"))
					end
				end
                room:setPlayerProperty(player,"qishibusiyutushouEquips",ToData(table.concat(weapons2,",")))
				return false
			end
		end
	end,
}
qishibusiyutushouEquips = sgs.CreateViewAsEquipSkill{
	name = "#qishibusiyutushouEquips",
	view_as_equip = function(self,player)
		return player:property("qishibusiyutushouEquips"):toString()
	end,
}

wuqiongdewulianCard = sgs.CreateSkillCard{
	name = "wuqiongdewulian",
	will_throw = false ,
	filter = function(self, targets, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
            card:deleteLater()
		end
		return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
			end
	end ,
	feasible = function(self, targets)
	if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name)
            card:deleteLater()
		end
		return card and card:targetsFeasible(plist, sgs.Self)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
			end
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(user)) do
				if not p:isAllNude() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then 
			local target = room:askForPlayerChosen(user, targets, self:objectName())
			if target then
			room:setPlayerFlag(user, self:objectName())
            room:addPlayerMark(user, "&"..self:objectName().. "-Clear")
			local card = room:askForCardChosen(user, target, "hej", self:objectName())
			local acard = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Sanguosha:getCard(card):getSuit(), sgs.Sanguosha:getCard(card):getNumber())
			acard:addSubcard(sgs.Sanguosha:getCard(card))
			acard:setSkillName("wuqiongdewulian")
		return acard
		end
		end
	end,
	on_validate = function(self, cardUse)
		cardUse.m_isOwnerUse = false
		local user = cardUse.from
		local room = user:getRoom()
	local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(user)) do
				if not p:isAllNude() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then 
			local target = room:askForPlayerChosen(user, targets, self:objectName())
			if target then
			room:setPlayerFlag(user, self:objectName())
            room:addPlayerMark(user, "&"..self:objectName().. "-Clear")
			local card = room:askForCardChosen(user, target, "hej", self:objectName())
			local acard = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Sanguosha:getCard(card):getSuit(), sgs.Sanguosha:getCard(card):getNumber())
			if (self:getUserString() == "Jink" and not sgs.Sanguosha:getCard(card):isKindOf("Jink")) or (self:getUserString() == "Slash" and not sgs.Sanguosha:getCard(card):isKindOf("Slash"))  then
			local cdata= sgs.QVariant()
						cdata:setValue(sgs.Sanguosha:getCard(card))
			user:setTag("wuqiongdewulian_different", cdata)
			end
			acard:addSubcard(sgs.Sanguosha:getCard(card))
			acard:setSkillName("wuqiongdewulian")
		return acard
		end
		end
		
	end
}

wuqiongdewulianVS = sgs.CreateZeroCardViewAsSkill{
	name = "wuqiongdewulian",

	enabled_at_play = function(self, player)
	local can_invoke = false
	for _, p in sgs.qlist(player:getSiblings()) do
	if p:objectName()~=player:objectName() and not p:isAllNude() then
	can_invoke = true
	break
	end
	end
		return can_invoke and sgs.Slash_IsAvailable(player) and not player:hasFlag("wuqiongdewulian")
	end,
	enabled_at_response = function(self, player, pattern)
	local can_invoke = false
	for _, p in sgs.qlist(player:getSiblings()) do
	if p:objectName()~=player:objectName() and not p:isAllNude() then
	can_invoke = true
	break
	end
	end
		if (pattern == "slash" or pattern == "jink") and not player:hasFlag("wuqiongdewulian") then
			return can_invoke 
		end
		return false
	end,
	view_as = function(self)
	if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or  sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
		local acard = wuqiongdewulianCard:clone()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		acard:setUserString(pattern)
		return acard
	end
	local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
	local acard = wuqiongdewulianCard:clone()
		acard:setUserString("Slash")
		return acard
		end
	end
}
wuqiongdewulian = sgs.CreateTriggerSkill{
	name = "wuqiongdewulian",
	view_as_skill = wuqiongdewulianVS,
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.CardResponded},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then 
		if player:getPhase() == sgs.Player_Finish then 
		for _,p in sgs.qlist(room:getAlivePlayers()) do
		room:setPlayerFlag(p, "-"..self:objectName())
		end
		end
		elseif event ==sgs.CardsMoveOneTime then 
		local move = data:toMoveOneTime()
		if player:hasSkill(self:objectName()) and player:getTag("wuqiongdewulian_different") then 
		local acard =  player:getTag("wuqiongdewulian_different"):toCard()
		if acard then
		if move.from_places:contains(sgs.Player_PlaceTable) and (move.to_place == sgs.Player_DiscardPile)--
				and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE or move.reason.m_reason == sgs.CardMoveReason_S_REASON_RESPONSE )  then
				for _, card_id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(card_id)
					if card:getId() == acard:getId() then
				room:loseHp(player)
				player:setTag("wuqiongdewulian_different", sgs.QVariant())
				end
				end
				end
		end
		end
		elseif event == sgs.CardResponded then 
		local card =  data:toCardResponse().m_card		
		if card and card:getSkillName()== "wuqiongdewulian" then
	
		if (card:isKindOf("Slash") and not sgs.Sanguosha:getCard(card:getSubcards():first()):isKindOf("Slash")) or (card:isKindOf("Jink") and not sgs.Sanguosha:getCard(card:getSubcards():first()):isKindOf("Jink")) then
			room:loseHp(player)
				player:setTag("wuqiongdewulian_different", sgs.QVariant())
				end
			end
		end
	end,
		can_trigger = function(self, target)
		return target
	end,
}



lancelot:addSkill(qishibusiyutushou)
lancelot:addSkill(qishibusiyutushouEquips)

lancelot:addSkill(wuqiongdewulian)
extension:insertRelatedSkills("qishibusiyutushou","#qishibusiyutushouEquips")

sgs.LoadTranslationTable{

	["lancelot"] = "兰斯洛特",
	["&lancelot"] = "兰斯洛特",
	["#lancelot"] = "墮落的湖上騎士",
	["cv:lancelot"] = "置鮎龍太郎",
	["designer:lancelot"] = "zengzouyu",
	["illustrator:lancelot"] = "sweetnano",
	
	["qishibusiyutushou"] = "骑士不死于徒手",
	[":qishibusiyutushou"] = "<font color=\"blue\"><b>锁定技，</b></font>当你没装备武器牌时，视为你装备有当前场上攻击范围最大的武器牌。",
	["#qishibusiyutushou"] = "现在 %from 的武器视为 %arg 攻击距离为 %arg2 ",
	["#qishibusiyutushou_lost"] = "现在 %from 失去了 %arg 的效果 ",
	
	["wuqiongdewulian"] = "无穷的武炼",
	[":wuqiongdewulian"] = "每名角色的回合限一次，你可将其他角色区域内的一张牌作为【杀】或【闪】使用或打出；以此法进入弃牌堆的牌若不为你想要使用或打出的牌，你须流失1点体力。",

	
}






gilgamesh = sgs.General(extension, "gilgamesh", "magic", 4)

Babylon_TM = sgs.CreateTargetModSkill{
	name = "#Babylon_TM" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, player, card)
		if player:hasSkill("Babylon") and (card:getSkillName() == "Babylon") then
			return 1000
		else
			return 0
		end
	end
}
BabylonCard = sgs.CreateSkillCard{
	name = "Babylon",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select) --必须
	local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
    card:deleteLater()
	card:setSkillName(self:objectName())
	local qtargets = sgs.PlayerList()
			for _, p in ipairs(targets) do
				qtargets:append(p)
			end
		if to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:canSlash(to_select, card,false) then
			return card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, qtargets)
		end
	end,
	on_validate = function(self,carduse)
	local source = carduse.from
		local source = carduse.from
		local target = carduse.to:first()
		local room = source:getRoom()
			local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)  
			local DiscardPile = room:getDiscardPile()
			local toGainList = sgs.IntList()
			for _,cid in sgs.qlist(DiscardPile) do
				local cd = sgs.Sanguosha:getCard(cid)
				if cd:isKindOf("EquipCard") then
					toGainList:append(cid)
				end
			end
			if not toGainList:isEmpty() then
			room:fillAG(toGainList, source)
				local card_id = room:askForAG(source, toGainList, false, "Babylon")
				if card_id ~= -1 then
					local gain_card = sgs.Sanguosha:getCard(card_id)
					room:moveCardTo(gain_card, source, nil,sgs.Player_DrawPile,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "Babylon", ""), true)
				end
				room:clearAG()
		if source:canSlash(target, nil, false) then
			card:setSkillName("Babylon")
			return card
			end
			end
		end
}
BabylonVS = sgs.CreateViewAsSkill{
	name = "Babylon",
	n = 0,
	view_as = function(self, cards)
	if #cards == 0 then
			local card = BabylonCard:clone()
			return card
			end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@Babylon" 
		end
}
Babylon = sgs.CreateTriggerSkill{
	name = "Babylon",
	events = {sgs.EventPhaseStart},
	view_as_skill = BabylonVS,
	on_trigger=function(self,event,player,data)
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			local DiscardPile = room:getDiscardPile()
			local toGainList = sgs.IntList()
			for _,cid in sgs.qlist(DiscardPile) do
				local cd = sgs.Sanguosha:getCard(cid)
				if cd:isKindOf("EquipCard") then
					toGainList:append(cid)
				end
			end
			if (not toGainList:isEmpty()) then
			local defense_str = {}
					for _,card_id in sgs.qlist(toGainList) do
						table.insert(defense_str, sgs.Sanguosha:getCard(card_id):toString())
					end	
					local msg = sgs.LogMessage()
					msg.type = "$Babylon_equip"
					msg.from = player
					msg.card_str = table.concat(defense_str, "+")
					room:sendLog(msg)
			room:askForUseCard(player, "@@Babylon", "@Babylon")
			end
		end
	end,
}

gilgamesh:addSkill(Babylon)
gilgamesh:addSkill(Babylon_TM)
extension:insertRelatedSkills("Babylon","#Babylon_TM")

sgs.LoadTranslationTable{

  ["gilgamesh"] = "闪闪",
  ["&gilgamesh"] = "闪闪",
  ["#gilgamesh"] = "英雄王",
  ["designer:gilgamesh"] = "zengzouyu",
  --["gilgamesh"] = "zengyouyu",

  ["Babylon"] = "王之财宝",
  [":Babylon"] = "准备阶段，你可以将弃牌堆内的一张装备牌置于牌堆顶，然后视为使用了一张【杀】。",
  ["@Babylon"] = "你可以发动“王之财宝”",
  ["~Babylon"]  = "选择一名其他角色→点击确定",
  ["$Babylon_equip"] = "弃牌堆内有 %card， %from 可以将弃牌堆内的一张装备牌置于牌堆顶 ",
  
}


RyougiShiki = sgs.General(extension, "RyougiShiki", "magic",4, false)


zhisimoyan = sgs.CreateTriggerSkill{
    name = "zhisimoyan",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseStart,sgs.TargetConfirmed},
    on_trigger=function(self,event,player,data)
        local room=player:getRoom()
        if event==sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                local duship = room:askForPlayerChosen(player, room:getOtherPlayers(player), "zhisimoyan", "zhisimoyan-invoke", true, true)
                if(duship~=nil and not duship:isKongcheng())  then
                    local cdid = room:askForCardChosen(player, duship,"h", self:objectName())
                    room:showCard(duship, cdid)
                    local dushic = sgs.Sanguosha:getCard(cdid)
                    room:setPlayerMark(player,"zhisimoyan",cdid)
                    room:broadcastSkillInvoke(self:objectName())
                    local value = sgs.QVariant()
                    value:setValue(duship)
                    room:setTag("zhisimoyan_target", value)
                    room:addPlayerMark(duship, "&zhisimoyan+to+:+"..dushic:getType().."+#"..player:objectName().."-Clear")
                end
            elseif player:getPhase() == sgs.Player_Finish then
                room:setPlayerMark(player,"zhisimoyan",0)
                room:setTag("zhisimoyan_target", sgs.QVariant(""))
            end
        elseif event==sgs.TargetConfirmed then 
        local use = data:toCardUse()
        local card = use.card
        local dest = room:getTag("zhisimoyan_target"):toPlayer()
        if dest and use.to:contains(dest) then
        if player:getMark("zhisimoyan") == 0  then return false end
        if use.from then
        local card_id=player:getMark("zhisimoyan")
        local carda=sgs.Sanguosha:getCard(card_id)
        if carda:getTypeId() == card:getTypeId() then 
             local choicelist = "cancel+zhisimoyan_damage"
             local cardb
                        local cards = room:getTag("zhisimoyan_target"):toPlayer():getHandcards()
                    if cards then
                        for _,acard in sgs.qlist(cards) do
                            if acard:toString() == sgs.Sanguosha:getCard(player:getMark("zhisimoyan")):toString() then 
                            choicelist = string.format("%s+%s", choicelist, "zhisimoyan_get")
                            cardb = acard
                            break
                        end
                    end
                        end
					local dest = sgs.QVariant()
					dest:setValue(player)
                local choice = room:askForChoice(player, "zhisimoyan", choicelist, dest)
                    if choice == "zhisimoyan_damage" then 
                    local damage = sgs.DamageStruct()
                        damage.from = player
                        damage.to = player
                        damage.damage = 1
                        room:damage(damage)
                    elseif choice == "zhisimoyan_get" then 
                    room:obtainCard(player,cardb)
                    end
                    end
                    end
                        
            end
        end
    end,
}
RyougiShiki:addSkill(zhisimoyan)


sgs.LoadTranslationTable{

  ["RyougiShiki"] = "两仪式",
  ["&RyougiShiki"] = "两仪式",
  ["#RyougiShiki"] = "空识珈蓝",
  ["cv:RyougiShiki"] = "坂本真绫",
  ["designer:RyougiShiki"] = "zengzouyu",
  ["illustrator:RyougiShiki"] = "五月福音",

  ["zhisimoyan"] = "直死魔眼",
  ["zhisimoyan_damage"] = "对该角色造成一点伤害",
  ["zhisimoyan_get"] = "获得该展示牌",
  ["zhisimoyan-invoke"] =  "你可以发动“直死魔眼”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
  ["$zhisimoyan"] = "只要是活着的东西，就算是神也杀给你看。",
  [":zhisimoyan"] = "准备阶段，你可展示其他角色的一张手牌直到回合结束，若如此做，该角色本回合成为与展示牌类别相同的牌的目标时，你可选择一项：获得该展示牌或对该角色造成一点伤害。",
  
}

fengbujue=sgs.General(extension,"fengbujue","real",4,true,false)

zhiluanCard = sgs.CreateSkillCard{
    name = "zhiluanCard" ,
    filter = function(self, targets, to_select)
        return (#targets == 0) and (to_select:objectName() ~= sgs.Self:objectName()) and not to_select:isNude()
        end ,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local x = source:getTag("zhiluan"):toInt()
        if x == 0 then x = 1 end
        local dummy = sgs.Sanguosha:cloneCard("jink")
        if target:getCardCount() <= x then
            dummy:addSubcards(target:getCards("he"))
        else 
            for i = 1,x do--进行多次执行
                local id = room:askForCardChosen(source,target,"he","zhiluan",
                    false,--选择卡牌时手牌不可见
                    sgs.Card_MethodNone,--设置为弃置类型
                    dummy:getSubcards(),--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
                    false)
                if id < 0 then break end--如果卡牌id无效就结束多次执行
                dummy:addSubcard(id)--将选择的id添加到虚拟卡的子卡表
            end
        end
        source:obtainCard(dummy,false)
        local _data = sgs.QVariant()
        _data:setValue(target)
        local choice = room:askForChoice(source,"zhiluan","add+reset",_data)
        if choice == "add" then
            x = x + 1
        else 
            x = 1
        end
        dummy:clearSubcards()
        if source:getCardCount() <= x then
            dummy:addSubcards(source:getCards("he"))
        else
            dummy:addSubcards(room:askForExchange(source, "zhiluan", x, x, true, "@zhiluan-give", false, "."):getSubcards())
        end
        target:obtainCard(dummy,false)
        dummy:deleteLater()
        source:setTag("zhiluan",sgs.QVariant(x))
        source:setSkillDescriptionSwap("zhiluan","%arg1", x)
        room:changeTranslation(source, "zhiluan", 2)
    end
}

zhiluan = sgs.CreateViewAsSkill{
name = "zhiluan",
n = 0,
view_filter = function(self, selected, to_select)
return false
end,
view_as = function(self)
return zhiluanCard:clone()
end,
enabled_at_play = function(self, player)
return not player:hasUsed("#zhiluanCard")
end,
}

fengbujue:addSkill(zhiluan)
sgs.LoadTranslationTable{
    ["#fengbujue"] = "莫测的狂徒",
    ["fengbujue"] = "封不觉",
    ["designer:fengbujue"] = "zengzouyu",
    ["cv:fengbujue"] = "",
    ["illustrator:fengbujue"] = "恶果果果果",
    ["zhiluan"] = "智乱",
    [":zhiluan"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以获得一名其他角色的X张牌并选择一项:1、令X的数值+1;2、重置X为1。选择完成后你需交给该角色X张牌。(X初始为1)",
    [":zhiluan2"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以获得一名其他角色的 X [ <font color='#590CC5'><b> %arg1</b></font> ] 张牌并选择一项:1、令X的数值+1;2、重置X为1。选择完成后你需交给该角色X张牌。(X初始为1)",
}

yibanyouyu=sgs.General(extension,"yibanyouyu","real",4,true,false)

caoduoCard = sgs.CreateSkillCard{
    name = "caoduoCard" ,
    will_throw = false,
    filter = function(self, targets, to_select)
        if #targets > 0 then
            if #targets == 2 then return false end
            return targets[1]:canSlash(to_select)
        else
            if to_select:objectName() == sgs.Self:objectName() then
                return false
            end
            for _,p in sgs.qlist(to_select:getAliveSiblings()) do
                if to_select:canSlash(p) then return true end
            end
        end
        return false
    end ,
    feasible = function(self, targets)
        return #targets == 2
    end ,
    on_validate = function(self,card_use)
        local aC = sgs.Sanguosha:cloneCard("collateral")
        aC:addSubcard(self:getEffectiveId())
        aC:setSkillName("caoduo")
        local room = card_use.from:getRoom()
        if card_use.to:at(0):getWeapon() then room:addPlayerHistory(card_use.from,"#caoduoCard",-1) end
        return aC
    end,
}

caoduoVS = sgs.CreateViewAsSkill{
    name = "caoduo",
    n = 1,
    response_pattern = "@@caoduo",
	response_or_use = true,
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUsePattern() == "@@caoduo" then
            return to_select:hasFlag("caoduo")
        end
        if to_select:isEquipped() then return false end
        if sgs.Self:hasUsed("#caoduoCard")then
            return to_select:getSuit() == sgs.Card_Club
        else
            return to_select:getSuit() == sgs.Card_Club or to_select:isKindOf("Collateral")
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        elseif #cards == 1 then
            if sgs.Sanguosha:getCurrentCardUsePattern() == "@@caoduo" then
                local acard = sgs.Sanguosha:cloneCard(cards[1]:objectName(), cards[1]:getSuit(), cards[1]:getNumber())
                acard:setSkillName("caoduo")
                acard:addSubcard(cards[1])
                return acard
            end
            if sgs.Self:hasUsed("#caoduoCard")then
                local collateral = sgs.Sanguosha:cloneCard("collateral")
                collateral:addSubcard(cards[1])
                collateral:setSkillName(self:objectName())
                return collateral
            else
                local card = caoduoCard:clone()
                card:addSubcard(cards[1])
                return card
            end
        end
    end,
    enabled_at_play = function(self, player)
        for _, card in sgs.qlist(player:getHandcards()) do
            if card:getSuit() == sgs.Card_Club then return true end
        end
        return false
    end,
}

caoduo = sgs.CreateTriggerSkill{
    name = "caoduo" ,
    events = {sgs.ChoiceMade,sgs.PreCardUsed} ,
    view_as_skill = caoduoVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event==sgs.ChoiceMade then
            local decision = data:toString():split(":")
            local current = room:getCurrent()
            if player:getWeapon() or not current:hasSkill(self:objectName()) then return false end
            --cardUsed:slash:collateral-slash:sgs3:sgs1:nil
            if decision[1] ~= "cardUsed" or decision[2] ~= "slash" or decision[3] ~= "collateral-slash" or decision[6] ~= "" then return false end
            if (not room:askForSkillInvoke(current,"caoduo",data)) then return false end
            if not player:isAllNude() then
                local ids = player:handCards()
                local card_str = ""
                for _,id in sgs.qlist(ids) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:isAvailable(current) then
                        room:setCardFlag(card, "caoduo")
                    end
                    if card_str == "" then
                        card_str = card:toString()
                    else
                        card_str = card_str .. "#" .. card:toString()
                    end
                end
                room:setPlayerFlag(current, "Global_InTempMoving")--清除移动广播
                local SPlayer = sgs.SPlayerList()
                SPlayer:append(current)
                local fake_moveA = sgs.CardsMoveList()
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, current:objectName())
                local moveA = sgs.CardsMoveStruct(ids, nil, current, sgs.Player_PlaceTable, sgs.Player_PlaceHand, reason)
                fake_moveA:append(moveA)
                room:notifyMoveCards(true, fake_moveA, true, SPlayer)
                room:notifyMoveCards(false, fake_moveA, true, SPlayer)
                room:setPlayerFlag(current, "LuaTaoxiUsed")
                local zongxuantable = sgs.QList2Table(ids)
                current:setTag("LuaZongxuan", sgs.QVariant(table.concat(zongxuantable, "+")))
                local acard = room:askForUseCard(current, "@@caoduo", "@xinji-use")
                -- local acard = room:askForUseCard(current, card_str, "@xinji-use")
                if not acard then
                    local fake_moveB = sgs.CardsMoveList()
                    local moveB = sgs.CardsMoveStruct(ids, current, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable, reason)
                    fake_moveB:append(moveB)
                    room:notifyMoveCards(true, fake_moveB, true, SPlayer)
                    room:notifyMoveCards(false, fake_moveB, true, SPlayer)
                end
                room:setPlayerFlag(current, "-LuaTaoxiUsed")
                current:removeTag("LuaZongxuan")
                room:setPlayerFlag(current, "-Global_InTempMoving")
                for _,id in sgs.qlist(ids) do
                    local card = sgs.Sanguosha:getCard(id)
                    room:setCardFlag(card, "-caoduo")
                end
                if not acard then
                    local to_throw = room:askForCardChosen(current, player, "h", self:objectName(), true, sgs.Card_MethodDiscard)
                    room:throwCard(sgs.Sanguosha:getCard(to_throw), player, current)
                end
            end
        elseif event==sgs.PreCardUsed and player:hasFlag("LuaTaoxiUsed") then
            local use = data:toCardUse()
            if use.card:isVirtualCard() and (use.card:subcardsLength() ~= 1) then return false end
            if sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()) then
                local subcards = sgs.IntList()
                local subcards_variant = player:getTag("LuaZongxuan"):toString():split("+")
                if #subcards_variant>0 then
                    for _,id in ipairs(subcards_variant) do 
                        subcards:append(tonumber(id)) 
                    end
                    subcards:removeOne(use.card:getEffectiveId())
                    local SPlayer = sgs.SPlayerList()
                    SPlayer:append(player)
                    local fake_moveB = sgs.CardsMoveList()
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName())
                    local reasonU = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, player:objectName())
                    local moveB = sgs.CardsMoveStruct(subcards, player, nil, sgs.Player_PlaceHand, sgs.Player_DiscardPile, reason)
                    local moveC = sgs.CardsMoveStruct(use.card:getEffectiveId(), player, nil, sgs.Player_PlaceHand, sgs.Player_DiscardPile, reasonU)
                    fake_moveB:append(moveB)
                    fake_moveB:append(moveC)
                    room:notifyMoveCards(true, fake_moveB, true, SPlayer)
                    room:notifyMoveCards(false, fake_moveB, true, SPlayer)
                    player:removeTag("LuaZongxuan")
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}
yibanyouyu:addSkill(caoduo)
sgs.LoadTranslationTable{
    ["#yibanyouyu"] = "独眼的死神",
    ["yibanyouyu"] = "乙坂有宇",
    ["designer:yibanyouyu"] = "zengzouyu",
    ["cv:yibanyouyu"] = "",
    ["illustrator:yibanyouyu"] = "",
    ["caoduo:cardUsed"] = "操夺：你观看其手牌并可以使用或弃置其中一张牌",
    ["caoduo"] = "操夺",
    [":caoduo"] = "你可以将你的梅花手牌当做借刀杀人使用；<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以对未装备武器的角色使用借刀杀人，若其未使用杀，你观看其手牌并可以使用或弃置其中一张牌。",

}

izayoi=sgs.General(extension,"izayoi","magic",3,false,false)

shengkongCard = sgs.CreateSkillCard{
    name = "shengkongCard",
    will_throw = false ,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        local name = ""
        local card
        local plist = sgs.PlayerList()
        for i = 1, #targets do plist:append(targets[i]) end
        local aocaistring = self:getUserString()
        if aocaistring ~= "" then
            local uses = aocaistring:split("+")
            name = uses[1]
            card = sgs.Sanguosha:cloneCard(name)
            card:deleteLater()
        end
        if card and card:targetFixed() then
            return false
        end
        return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
    end ,
    feasible = function(self, targets)
        local name = ""
        local card
        local plist = sgs.PlayerList()
        for i = 1, #targets do plist:append(targets[i]) end
        local aocaistring = self:getUserString()
        if aocaistring ~= "" then
            local uses = aocaistring:split("+")
            name = uses[1]
            card = sgs.Sanguosha:cloneCard(name)
            card:deleteLater()
        end
        return card and card:targetsFeasible(plist, sgs.Self)
    end,
    on_validate_in_response = function(self, user)
        local room = user:getRoom()
        local sta = self:getUserString()
        if sta ~= "" then
            local uses = sta:split("+")
            local stb = ""
            if sta == "analeptic" then
                sta = "analeptic,Analeptic"
            end
            local num = self:subcardsLength()
            local target = room:askForPlayerChosen(user, room:getOtherPlayers(user), "shengkong")
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, user:objectName(), target:objectName(), "shengkong","")
            room:moveCardTo(self,target,sgs.Player_PlaceHand,reason)
            local dest = sgs.QVariant()
            dest:setValue(user)
            local card = room:askForCard(target, sta, "@shengkong-use:" .. user:objectName(), dest, sgs.Card_MethodResponse, user)
            if card then
                card:setSkillName("shengkong")
                return card
            else
                local _data = sgs.QVariant()
                _data:setValue(target)
                if room:askForSkillInvoke(user,"shengkong",_data) then
                    local card_ids = sgs.IntList()
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                    dummy:deleteLater()
                    local plus = target:getCardCount(true,false)
                    while plus > 0 and num > 0 do
                        plus = target:getCardCount(true,false)
                        for _, card in sgs.qlist(target:getCards("he")) do
                            if card_ids:contains(card:getEffectiveId()) then
                                plus = plus - 1
                            end
                        end
                        if plus == 0 then break end
                        num = num - 1
                        local card_id = room:askForCardChosen(user, target, "he", "shengkong", false, sgs.Card_MethodNone, card_ids)
                        card_ids:append(card_id)
                        dummy:addSubcard(card_id)
                    end
                    room:moveCardTo(dummy, user, sgs.Player_PlaceHand, false)
                end
                room:setPlayerFlag(user, "Global_shengkongFailed")
            end
            return nil
        end
    end,
    on_validate = function(self, cardUse)
        cardUse.m_isOwnerUse = false
        local user = cardUse.from
        local room = user:getRoom()
        local sta = self:getUserString()
        if sta ~= "" then
            local uses = sta:split("+")
            local stb = ""
            if sta == "analeptic" then
                sta = "analeptic,Analeptic"
            end
            local num = self:subcardsLength()
            local target = room:askForPlayerChosen(user, room:getOtherPlayers(user), "shengkong")
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, user:objectName(), target:objectName(), "shengkong","")
            room:moveCardTo(self,target,sgs.Player_PlaceHand,reason)
            local dest = sgs.QVariant()
            dest:setValue(user)
            local card = room:askForCard(target, sta, "@shengkong-use:" .. user:objectName(), dest, sgs.Card_MethodResponse, user)
            if card then
                card:setSkillName("shengkong")
                return card
            else
                local _data = sgs.QVariant()
                _data:setValue(target)
                if room:askForSkillInvoke(user,"shengkong",_data) then
                    local card_ids = sgs.IntList()
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                    dummy:deleteLater()
                    local plus = target:getCardCount(true,false)
                    if num >= plus then
                        for _,card in sgs.qlist(target:getCards("he")) do
                            dummy:addSubcard(card)
                        end
                    else
                        while plus > 0 and num > 0 do
                            plus = target:getCardCount(true,false)
                            for _, card in sgs.qlist(target:getCards("he")) do
                                if card_ids:contains(card:getEffectiveId()) then
                                    plus = plus - 1
                                end
                            end
                            if plus == 0 then break end
                            num = num - 1
                            local card_id = room:askForCardChosen(user, target, "he", "shengkong", false, sgs.Card_MethodNone, card_ids)
                            card_ids:append(card_id)
                            dummy:addSubcard(card_id)
                        end
                    end
                    room:moveCardTo(dummy, user, sgs.Player_PlaceHand, false)
                end
                room:setPlayerFlag(user, "Global_shengkongFailed")
            end
            return nil
        end
    end
}

shengkong = sgs.CreateViewAsSkill{
    name = "shengkong",
    n = 998,
    view_filter = function(self, selected, to_select)
        return true
    end,
    enabled_at_play = function()
        return false
    end ,
    enabled_at_response = function(self, player, pattern)
        if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
        if player:getPhase() ~= sgs.Player_NotActive or player:hasFlag("Global_shengkongFailed") then return false end
        if pattern == "peach" then
            return not player:hasFlag("Global_PreventPeach")
        else
            return true
        end
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return nil end
        local acard = shengkongCard:clone()
        for _,card in pairs(cards) do
            acard:addSubcard(card)
        end
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        if pattern == "peach+analeptic" and sgs.Self:hasFlag("Global_PreventPeach") then
            pattern = "analeptic"
        end
        acard:setUserString(pattern)
        return acard
    end,
}

tianlaiCard = sgs.CreateSkillCard{
    name = "tianlaiCard" ,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        if #targets ~= 0 or to_select:objectName() == player:objectName() then return false end
        return not to_select:isKongcheng() and not player:hasUsed("#tianlai"..to_select:objectName())
    end ,
    on_effect = function(self, effect)
        local source = effect.from
        local room = source:getRoom()
        local target = effect.to
        local card_id = self:getSubcards():first()
        local card = room:askForCardShow(target,source,"tianlai")
        room:showCard(source, card_id)
        room:showCard(target, card:getEffectiveId())
        room:throwCard(sgs.Sanguosha:getCard(card_id), source)
        if card:sameColorWith(sgs.Sanguosha:getCard(card_id)) then
            room:recover(target, sgs.RecoverStruct(source))
        else
            room:drawCards(target, 1, "tianlai")
            room:addPlayerHistory(source, "#tianlai"..target:objectName())
            room:addPlayerHistory(source, "#tianlaiCard",-1)
        end
    end
}

tianlai = sgs.CreateViewAsSkill{
    name = "tianlai",
    n = 1,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        elseif #cards == 1 then
            local card = tianlaiCard:clone()
            card:addSubcard(cards[1])
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#tianlaiCard")
    end,
}

izayoi:addSkill(shengkong)
izayoi:addSkill(tianlai)
sgs.LoadTranslationTable{
    ["#izayoi"] = "破军歌姬",
    ["izayoi"] = "诱宵美九",
    ["designer:izayoi"] = "陆丿伯言",
    ["cv:izayoi"] = "",
    ["illustrator:izayoi"] = "梁星",
    ["shengkong"] = "声控",
    [":shengkong"] = "每当你于回合外需使用一张基本牌时，你可以将至少一张牌交给一名其他角色，令其替你使用此基本牌，否则你可以获得其等量的牌。",
    ["tianlai"] = "天籁",
    [":tianlai"] = "出牌阶段对每名其他角色限一次，你可以令一名其他角色与你同时展示一张手牌然后你弃置你的展示牌，若两牌颜色相同，你令其回复一点体力且你此回合内不能再发动天籁；若不同，你令其摸一张牌。",
}

zzy_sakura=sgs.General(extension,"zzy_sakura","magic",3,false,false)

lingbianCard = sgs.CreateSkillCard{
    name = "lingbianCard",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        local card = sgs.Self:getTag("lingbian"):toCard()
        if card:isKindOf("Peach") then card = sgs.Sanguosha:cloneCard("ExNihilo") end
        card:addSubcards(sgs.Self:getHandcards())
        card:setSkillName("lingbian")
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
        local card = sgs.Self:getTag("lingbian"):toCard()
        if card:isKindOf("Peach") then card = sgs.Sanguosha:cloneCard("ExNihilo") end
        card:addSubcards(sgs.Self:getHandcards())
        card:setSkillName("lingbian")
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
        local xunyou = card_use.from
        local room = xunyou:getRoom()
        local use_card = sgs.Sanguosha:cloneCard(self:getUserString())
        use_card:addSubcards(xunyou:getHandcards())
        use_card:setSkillName("lingbian")
        local available = true
        for _,p in sgs.qlist(card_use.to) do
            if xunyou:isProhibited(p,use_card)  then
                available = false
                break
            end
        end
        available = available and use_card:isAvailable(xunyou)
        if not available then return nil end
        return use_card     
    end,
}
lingbian = sgs.CreateViewAsSkill{
    name = "lingbian",
    n = 0,
    view_filter = function(self, selected, to_select)
        return false
    end,
    view_as = function(self, cards)
        local c = sgs.Self:getTag("lingbian"):toCard()
        if c then
            if c:isKindOf("Peach") then c = sgs.Sanguosha:cloneCard("ExNihilo") end
            local card = lingbianCard:clone()
            card:setUserString(c:objectName())  
            return card
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return (not player:hasUsed("#lingbianCard")) and (not player:isKongcheng())
    end,
}
lingbian:setGuhuoDialog("lrps")--lrpsd

xingyou = sgs.CreateTriggerSkill{
    name = "xingyou" ,
    events = {sgs.DamageInflicted} ,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local current = room:getCurrent()
        room:addPlayerHistory(current, "#xingyou"..player:objectName())
        if player:getMark("xingyou-Clear") > 0 then return false end
        if player:getHandcardNum() >= current:usedTimes("#xingyou"..player:objectName()) then return false end
        if (not room:askForSkillInvoke(player,self:objectName(),data)) then return false end
        room:drawCards(player, 1, self:objectName())
        room:addPlayerMark(player, "xingyou-Clear")
        room:addPlayerMark(player, "&xingyou-Clear")
        return true
    end
}

zzy_sakura:addSkill(lingbian)
zzy_sakura:addSkill(xingyou)

sgs.LoadTranslationTable{
    ["#zzy_sakura"] = "百变小樱",
    ["zzy_sakura"] = "木之本樱",
    ["designer:zzy_sakura"] = "zengzouyu",
    ["cv:zzy_sakura"] = "",
    ["illustrator:zzy_sakura"] = "",
    ["lingbian"] = "灵变",
    [":lingbian"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将所有手牌(至少一张)当任意一张基本牌或非延时锦囊牌使用，以此法使用桃视为使用无中生有。",
    ["xingyou"] = "星佑",
    [":xingyou"] = "每名角色的回合限一次，每当你受到伤害时，若此伤害是你本回合受到的第X次伤害，你可以防止之并摸一张牌(X大于你当前手牌数)。",
}

makishima=sgs.General(extension,"makishima","real",4,true,false)

zuiyou = sgs.CreateTriggerSkill{
    name = "zuiyou",
    --global = true,
    events = {sgs.TargetSpecified,sgs.CardFinished},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if event == sgs.TargetSpecified then
            if not use.card or use.to:length() ~= 1 or use.to:contains(player) then return false end
            if use.card:isKindOf("DelayedTrick") or use.card:isKindOf("Peach") then return false end
                        if use.card:getEffectiveId() == -1 then return false end
                        room:setCardFlag(use.card:getEffectiveId(), "zuiyou_obtain")
        elseif event == sgs.CardFinished then
            if not use.card or use.to:length() ~= 1 or use.to:contains(player) then return false end
            if use.card:isKindOf("DelayedTrick") or use.card:isKindOf("Peach") then return false end
                        if use.card:getEffectiveId() == -1 then return false end
            if not use.card:hasFlag("zuiyou_obtain") then return false end
            local targets = sgs.SPlayerList()
            targets:append(player)
            if use.to:first():isAlive() then
                targets:append(use.to:first())
            end
            local to = room:askForPlayerChosen(player, targets, self:objectName(), "zuiyou-invoke", true, true)
            if to then
                to:obtainCard(use.card)
                if targets:length() > 1 then
                    targets:removeOne(to)
                    if targets:first():isNude() then return false end
                    local to_throw = room:askForCardChosen(targets:first(), to, "he", self:objectName(), false, sgs.Card_MethodDiscard)
                    room:throwCard(sgs.Sanguosha:getCard(to_throw), to, targets:first())
                end
            end
        end
        return false
    end
}

makishima:addSkill(zuiyou)
sgs.LoadTranslationTable{
    ["#makishima"] = "纯白的原罪",
    ["makishima"] = "槙岛圣护",
    ["designer:makishima"] = "zengzouyu",
    ["cv:makishima"] = "",
    ["illustrator:makishima"] = "沉沂",
    ["zuiyou"] = "罪诱",
    [":zuiyou"] = "你使用的仅指定一名其他角色为目标的牌结算后，若此牌不为延时锦囊或桃，你可令你或该角色获得该牌，则未获得牌的角色弃置对方一张牌。",
	["zuiyou-invoke"] = "你可以发动“罪诱”",
}

lucifer=sgs.General(extension,"lucifer","magic",4,false,false)

duotian = sgs.CreateTriggerSkill{
    name = "duotian" ,
    events = {sgs.EventPhaseStart} ,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event==sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                local targets = sgs.SPlayerList()
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getCards("ej"):length()==0 then continue end
                    for _, card in sgs.qlist(p:getCards("ej")) do
                        if card:isRed() then
                            targets:append(p)
                            break
                        end
                    end
                end
                if targets:isEmpty() then return false end
                local to = room:askForPlayerChosen(player, targets, self:objectName(), "duotian-invoke", true, true)
                if to then
                    local DiscardPile = room:getDiscardPile()
                    local toGainList = sgs.IntList()
                    for _,card_id in sgs.qlist(DiscardPile) do
                        local card = sgs.Sanguosha:getCard(card_id)
                        if card:isBlack() then
                            toGainList:append(card_id)
                        end
                    end
                    if toGainList:isEmpty() then return false end
                    room:fillAG(toGainList, player)
                    local card_id = room:askForAG(player, toGainList, false, self:objectName())
                    room:clearAG(player)
                    if card_id ~= -1 then
                        to:obtainCard(sgs.Sanguosha:getCard(card_id))
                        local card_ids = sgs.IntList()
                        for _, card in sgs.qlist(to:getCards("ej")) do
                            if not card:isRed() then
                                card_ids:append(card:getEffectiveId())
                            end
                        end
                        local card_id = room:askForCardChosen(player, to, "ej", self:objectName(), false, sgs.Card_MethodNone, card_ids)
                        player:obtainCard(sgs.Sanguosha:getCard(card_id))
                    end
                end
            end
            return false
        end
    end,
}
lucifer:addSkill(duotian)
sgs.LoadTranslationTable{
    ["#lucifer"] = "路西法之女",
    ["lucifer"] = "嘉莉丝·露西菲尔",
    ["designer:lucifer"] = "亚里亚",
    ["cv:lucifer"] = "",
    ["illustrator:lucifer"] = "きらばがに",
    ["duotian"] = "堕天",
    [":duotian"] = "准备阶段开始时，你可以选择一名区域里有红牌的角色，若如此做你选择弃牌堆内的一张黑色牌令其获得之，你获得其区域里的一张红色牌。",
	["duotian-invoke"] = "你可以发动“堕天”<br/> <b>操作提示</b>: 选择一名区域里有红牌的角色→点击确定<br/>",
}

akisearu=sgs.General(extension,"akisearu","real",3,true,false)

pomouCard = sgs.CreateSkillCard{
    name = "pomou",
    will_throw = false ,
    target_fixed = true,
    filter = function(self, targets, to_select)
        return false
    end ,
    feasible = function(self, targets)
        return false
    end,
    on_validate_in_response = function(self, user)
        local room = user:getRoom()
        local targets = sgs.SPlayerList()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if not p:isKongcheng() then
                targets:append(p)
            end
        end
        if not targets:isEmpty() then 
            local target = room:askForPlayerChosen(user, targets, self:objectName(),"pomou-invoke")
            if not target then return false end
            if target then
                room:setPlayerFlag(user, self:objectName())
                local card
                if target:getMark("dongxi") > 0 then
                    room:notifySkillInvoked(user, "dongxi")
                    card = room:askForCardChosen(user, target, "h", self:objectName(),true)
                else
                    card = room:askForCardChosen(user, target, "h", self:objectName())
                end
                local acard = sgs.Sanguosha:cloneCard(self:getUserString())
                if self:getUserString() == "nullification" and sgs.Sanguosha:getCard(card):isKindOf("BasicCard") then
                    local cdata= sgs.QVariant()
                    cdata:setValue(sgs.Sanguosha:getCard(card))
                    user:setTag("pomou_different", cdata)
                end
                acard:addSubcard(sgs.Sanguosha:getCard(card))
                acard:setSkillName("pomou")
                room:setPlayerFlag(user, self:objectName())
                room:addPlayerMark(user, "&pomou-Clear")
                return acard
            end
        end
    end,
    on_validate = function(self, cardUse)
        cardUse.m_isOwnerUse = false
        local user = cardUse.from
        local room = user:getRoom()
        local targets = sgs.SPlayerList()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if not p:isKongcheng() then
                targets:append(p)
            end
        end
        if not targets:isEmpty() then 
        local target = room:askForPlayerChosen(user, targets, self:objectName())
        if target then
        room:setPlayerFlag(user, self:objectName())
        local card
        if target:getMark("dongxi") > 0 then
            room:notifySkillInvoked(user, "dongxi")
            card = room:askForCardChosen(user, target, "h", self:objectName(),true)
        else
            card = room:askForCardChosen(user, target, "h", self:objectName())
        end
        local acard = sgs.Sanguosha:cloneCard(self:getUserString())
        if self:getUserString() == "nullification" and sgs.Sanguosha:getCard(card):isKindOf("BasicCard") then
            local cdata= sgs.QVariant()
            cdata:setValue(sgs.Sanguosha:getCard(card))
            user:setTag("pomou_different", cdata)
        end
        acard:addSubcard(sgs.Sanguosha:getCard(card))
        acard:setSkillName("pomou")
        room:setPlayerFlag(user, self:objectName())
        room:addPlayerMark(user, "&pomou-Clear")
        return acard
        end
        end
        
    end
}

pomouVS = sgs.CreateZeroCardViewAsSkill{
    name = "pomou",

    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        local can_invoke = false
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if not p:isKongcheng() then
                can_invoke = true
                break
            end
        end
        if pattern == "nullification" then
            return can_invoke and not player:hasFlag(self:objectName())
        end
        return false
    end,
    enabled_at_nullification = function(self, player)
        local can_invoke = false
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if  not p:isKongcheng() then
                can_invoke = true
                break
            end
        end
        return can_invoke and not player:hasFlag(self:objectName())
    end,
    view_as = function(self)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == "nullification" then
                local acard = pomouCard:clone()
                acard:setUserString(pattern)
                return acard
            end
        end
    end
}
pomou = sgs.CreateTriggerSkill{
    name = "pomou",
    view_as_skill = pomouVS,
    events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    on_trigger = function(self,event,player,data)
        local room = player:getRoom()
        if event ==sgs.CardsMoveOneTime then 
            local move = data:toMoveOneTime()
            if player:hasSkill(self:objectName()) and player:getTag("pomou_different") then 
                local acard =  player:getTag("pomou_different"):toCard()
                if acard then
                    if move.from_places:contains(sgs.Player_PlaceTable) and (move.to_place == sgs.Player_DiscardPile)and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE or move.reason.m_reason == sgs.CardMoveReason_S_REASON_RESPONSE )  then
                        for _, card_id in sgs.qlist(move.card_ids) do
                            local card = sgs.Sanguosha:getCard(card_id)
                            if card:getId() == acard:getId() then
                                room:loseHp(player)
                                player:setTag("pomou_different", sgs.QVariant())
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseStart then 
            if player:getPhase() == sgs.Player_Finish then
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerFlag(p, "-"..self:objectName())
                end     
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end,
}

jilian = sgs.CreateTriggerSkill{
    name = "jilian",
    events = {sgs.Death} ,
    frequency = sgs.Skill_Compulsory ,
    can_trigger = function(self, target)
        return target ~= nil and target:hasSkill(self:objectName())
    end ,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local death = data:toDeath()
        if death.who:objectName() ~= player:objectName() then return false end
        local killer
        if death.damage then
            killer = death.damage.from
        else
            killer = nil
        end
        if killer and killer:objectName() ~= player:objectName() then
            room:sendCompulsoryTriggerLog(player, self:objectName(),true)
            room:notifySkillInvoked(player, self:objectName())
            killer:throwEquipArea()
        end
        return false
    end
}

dongxiCard = sgs.CreateSkillCard{
    name = "dongxi" ,
    will_throw = false ,
    handling_method = sgs.Card_MethodNone ,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    on_use = function(self, room, source, targets)
        targets[1]:obtainCard(self)
        room:setPlayerMark(targets[1],"&dongxi+to+#"..source:objectName(),1)
        room:setPlayerMark(targets[1],"dongxi",1)
        room:setPlayerMark(source,"HandcardVisible_"..targets[1]:objectName(),1)
    end
}
dongxiVS = sgs.CreateViewAsSkill{
    name = "dongxi" ,
    n = 1 ,
    view_filter = function(self, selected, to_select)
        return #selected == 0
    end ,
    view_as = function(self, cards)
        if #cards ~= 1 then return nil end
        local mingcecard = dongxiCard:clone()
        mingcecard:addSubcard(cards[1])
        return mingcecard
    end ,
    enabled_at_play = function(self, player)
        return not player:isNude()
    end
}
dongxi = sgs.CreateTriggerSkill{
    name = "dongxi",
    events = {sgs.EventPhaseStart},
    view_as_skill = dongxiVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() ~= sgs.Player_Start then return false end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMark("dongxi") > 0 then
                room:setPlayerMark(p,"dongxi",0)
                room:setPlayerMark(p,"&dongxi+to+#"..player:objectName(),0)
                room:setPlayerMark(player,"HandcardVisible_"..p:objectName(),0)
            end
        end
    end
}



akisearu:addSkill(dongxi)
akisearu:addSkill(pomou)
akisearu:addSkill(jilian)



sgs.LoadTranslationTable{

    ["akisearu"] = "秋赖或",
    ["&akisearu"] = "秋赖或",
    ["#akisearu"] = "神之觀察者",
    ["cv:akisearu"] = "石田彰",
    ["designer:akisearu"] = "zengzouyu",
    ["illustrator:akisearu"] = "沉沂",
    
    
    ["pomou"] = "破谋",
    [":pomou"] = "每名角色的回合限一次，你可将任意一名角色的一张手牌作为【无懈可击】使用，以此法进入弃牌堆的牌若为基本牌，你失去1点体力。",
    ["pomou-invoke"] = "你可以发动“破谋”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
    
    ["jilian"] = "畸恋",
    [":jilian"] = "<font color=\"blue\"><b>锁定技，</b></font>杀死你的角色失去装备区。",
    
    ["dongxi"] = "洞悉",
    [":dongxi"] = "出牌阶段，你可将一张牌交给其他角色，直到你的下个回合开始前，该角色的所有牌均对你可见。",	
}

tomorinao=sgs.General(extension,"tomorinao","real",3,false,false)

zzy_weimianCard = sgs.CreateSkillCard{
	name = "zzy_weimianCard" ,
	filter = function(self, targets, to_select)
		return #targets == 0
	end ,
	on_effect = function(self, effect)
		local source = effect.from
		local room = source:getRoom()
		local target = effect.to
		local subcard = sgs.Sanguosha:getCard(self:getEffectiveId())
        local available_ids = {}
        for _,c in sgs.list(target:getHandcards()) do
            if c:isAvailable(target) then table.insert(available_ids,c:getEffectiveId()) end
        end
        local pattern = table.concat(available_ids,",")
        --当你需要写AI的时候，你大概会写成这样的代码：
        --sgs.ai_skill_use[xxx] = function 
        --...
        --end
        --然后你将下个位置的代码的注释去掉：
        --sgs.ai_skill_use[pattern] = sgs.ai_skill_use[xxx] 
        --xxx应该换成你需要的字符串
		local card = room:askForUseCard(target, pattern, "@zzy_weimian")
        --同时这个位置下面的代码注释也应该去掉：
        --sgs.ai_skill_use[pattern] = nil
		if card then
			if card:getTypeId() == subcard:getTypeId() then
				room:drawCards(target, 2, "zzy_weimian")
			end
		end
	end
}

zzy_weimian = sgs.CreateViewAsSkill{
	name = "zzy_weimian",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			return nil
		elseif #cards == 1 then
			local card = zzy_weimianCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#zzy_weimianCard")
	end,
}

huanxingProhibit = sgs.CreateProhibitSkill{
	name = "#huanxing-Prohibit",
	is_prohibited = function(self, from, to, card)
		return to:hasSkill("huanxing") and card:isKindOf("Slash") and from:hasFlag("huanxing")
	end
}

huanxing = sgs.CreateTriggerSkill{
	name = "huanxing" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					room:removeAttackRangePair(player, p)--不能移除出攻击范围
					if p:objectName() == player:objectName() or p:isKongcheng() then continue end
					local used = p:getTag(self:objectName()):toBool()
					if used then
						if player:inMyAttackRange(p) then continue end
					else
						if not player:inMyAttackRange(p) then continue end
					end 
					if used then
						if (not room:askForSkillInvoke(p,self:objectName(),data)) then continue end
						room:drawCards(p, 1, "huanxing")
						room:insertAttackRangePair(player, p)
						p:setTag(self:objectName(), sgs.QVariant(false))
					else
						if p:canDiscard(p, "he") and room:askForCard(p, "..", "@huanxing", data, self:objectName()) then
							p:setTag(self:objectName(), sgs.QVariant(true))
							if player:inMyAttackRange(p) then
								room:setPlayerFlag(player, "huanxing")
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

tomorinao:addSkill(zzy_weimian)
tomorinao:addSkill(huanxing)
tomorinao:addSkill(huanxingProhibit)
extension:insertRelatedSkills("huanxing","#huanxing-Prohibit")
sgs.LoadTranslationTable{
	["#tomorinao"] = "勉励的希望",
	["tomorinao"] = "友利奈绪",
	["designer:tomorinao"] = "zengzouyu",
	["cv:tomorinao"] = "",
	["illustrator:tomorinao"] = "kazenokaze",
	["zzy_weimian"] = "慰勉",
	[":zzy_weimian"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以弃置一张手牌，令一名角色使用一张牌，若其使用的牌与你弃置的牌类型相同，其摸两张牌。",
	["huanxing"] = "幻形",
	[":huanxing"] = "其他角色的回合开始时，若你在其攻击范围内，你可以弃置一张牌，令你不在其攻击范围内。然后交换此技能中的“在”与“不在”，将“弃”改为“摸”“摸”改为“弃”",
}

luahuojianzhuixiCard = sgs.CreateSkillCard{
	name = "luahuojianzhuixiCard",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("luahuojianzhuixi")
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, sgs.Self)
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@luahuojianzhuixi")
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            slash:deleteLater()
			slash:setSkillName("luahuojianzhuixi")
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		end
	end
}
luahuojianzhuixiVS = sgs.CreateZeroCardViewAsSkill{
	name = "luahuojianzhuixi",
	view_as = function(self, cards)
		return luahuojianzhuixiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@luahuojianzhuixi") >= 1
	end
}
luahuojianzhuixi = sgs.CreateTriggerSkill{
	name = "luahuojianzhuixi",
	frequency = sgs.Skill_Limited,
	events = {sgs.Death},
	view_as_skill = luahuojianzhuixiVS,
	limit_mark = "@luahuojianzhuixi",
	on_trigger = function(self, event, player, data, room)
		local msg = sgs.LogMessage()
		msg.type = "#luahuojianzhuixi"
        msg.from = player
		room:sendLog(msg)
		room:setPlayerMark(player, "@luahuojianzhuixi", 1)
	end
}

luabaozhahuohua = sgs.CreateTriggerSkill{
	name = "luabaozhahuohua",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damage then
			local damage = data:toDamage()
			local target = damage.to
			if damage.card and damage.card:isKindOf("Slash") and (not damage.chain) and (not damage.transfer) then
				if not target:isAlive() then
					return false
				end
				if room:askForSkillInvoke(player, self:objectName(), data) then					
					local addLimit = false
					local nextTarget = target:getNextAlive()
					local beforeTarget = target:getNextAlive()
					while beforeTarget:getNextAlive() ~= target do
						beforeTarget = beforeTarget:getNextAlive()
					end

					local single = (beforeTarget == nextTarget)


					--一个人弃牌
					if single then
						--弃零张不能触发效果
						if beforeTarget:isNude() then
							return false
						else
							room:askForDiscard(beforeTarget, self:objectName(), 1, 1, false, true)
							addLimit = true
						end
					end

					--两个人弃牌
					if not single then
						local nudeCount = 0
						if beforeTarget:isNude() then
							single = true
							beforeTarget = nextTarget
							nudeCount = nudeCount + 1
						end
						if nextTarget:isNude() then
							single = true
							nudeCount = nudeCount + 1
						end
						--弃一张必触发效果
						if nudeCount == 1 then
							room:askForDiscard(beforeTarget, self:objectName(), 1, 1, false, true)
							addLimit = true
						end
						--弃零张不能触发效果
						if nudeCount == 2 then
							return false
						end
					end

					if addLimit then
                        room:addSlashCishu(player, 1, true)
                        room:addPlayerMark(player, "&luabaozhahuohua-Clear")
						return false
					end


					local card = sgs.Sanguosha:getCard(room:askForDiscard(beforeTarget, self:objectName(), 1, 1, false, true):getSubcards():first())
					if not single then
						local nextDiscard = sgs.Sanguosha:getCard(room:askForDiscard(nextTarget, self:objectName(), 1, 1, false, true):getSubcards():first())
                        if card:sameColorWith(nextDiscard) then
                            room:addSlashCishu(player, 1, true)
                            room:addPlayerMark(player, "&luabaozhahuohua-Clear")
                        end
					end
                    
				end
			end
		end
		return false
	end
}

cuisitana = sgs.General(extension, "cuisitana", "wu", 4, false)
cuisitana:addSkill(luahuojianzhuixi)
cuisitana:addSkill(luabaozhahuohua)
sgs.LoadTranslationTable{
	["#cuisitana"] = "麦林炮手",
	["cuisitana"] = "崔丝塔娜",
	["designer:cuisitana"] = "zengzouyu",
	["illustrator:cuisitana"] = "英雄联盟",
	["luahuojianzhuixi"] = "火箭追袭",
	[":luahuojianzhuixi"] = "<font color=\"red\"><b>限定技，</b></font>出牌阶段你可以视为使用一张【杀】（不计入次数限制）；当有角色死亡时，重置该技能的使用次数。",
	["#luahuojianzhuixi"] = "%from 的技能 <font color=yellow><b>火箭追袭</b></font> 被触发，技能使用次数重置",
	
	["luabaozhahuohua"] = "爆炸火花",
	[":luabaozhahuohua"] = "你使用【杀】对一名角色造成伤害后，可令与其相邻的角色依次弃置一张牌，若以此法进入弃牌堆的牌仅有一种颜色，你本回合使用杀的上限数+1。"
}


siminai = sgs.General(extension, "siminai", "magic", 3, false)
ruanhua = sgs.CreateTriggerSkill{
	name = "ruanhua" ,
	events = {sgs.Damage,sgs.Damaged} ,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local target = nil
		if event == sgs.Damage then
			target = damage.to
		else
			target = damage.from
		end
		if not target  then return false end
			if not target:isAlive() then return false end
			local x = 0
			if  player:isKongcheng() then
			x = x + 1 
			end
			if player:getEquips():length() == 0 then 
			x = x + 1 
			end
			if player:getJudgingArea():length() == 0 then 
			x = x + 1 
			end
			
			if x > 0 then
			if target:getCardCount(true, false) <= x then
				target:throwAllCards()
				elseif  target:getCardCount(true, false) >  x then
				room:askForDiscard(target,self:objectName(),x,x,false,true,"ruanhua",".") 
			end
			end
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
				room:drawCards(target,3-x,self:objectName())
	end
}

containsTable = function(t, tar)
	for _, i in ipairs(t) do
		if i == tar then return true end
	end
	return false
end
xuezou = sgs.CreateTriggerSkill{
	name = "xuezou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if player:hasFlag("xuezou_using") then return false end
		if move.from_places:contains(sgs.Player_PlaceEquip) or move.to_place == sgs.Player_PlaceEquip or move.to_place == sgs.Player_PlaceDelayedTrick then
		local suits = {}
			local players = room:getAllPlayers()
			for _,p in sgs.qlist(players) do
				for _,eq in sgs.qlist(p:getEquips()) do 
					if not containsTable(suits, eq:getSuitString()) then
					table.insert(suits, eq:getSuitString())
				end
				end
				for  _,judgec in sgs.qlist(p:getJudgingArea()) do 
				if not containsTable(suits, judgec:getSuitString()) then
					table.insert(suits, judgec:getSuitString())
				end
				end
			end
			if #suits == 4 and room:askForSkillInvoke(player, self:objectName()) then
			room:setPlayerFlag(player, "xuezou_using")
			local suit = room:askForSuit(player, "xuezou")
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, player:objectName(), self:objectName(), nil)
			for _,p in sgs.qlist(players) do
			local card = sgs.Sanguosha:cloneCard("Slash") 
				for _,eq in sgs.qlist(p:getEquips()) do 
					if eq:getSuit() == suit then
					card:addSubcard(eq)
					end
				end
				for  _,judgec in sgs.qlist(p:getJudgingArea()) do 
				if judgec:getSuit() == suit then
					card:addSubcard(judgec)
					end
				end
				if card:subcardsLength() > 0 then 
				room:throwCard(card, reason, nil)
				end
			end
			room:setPlayerFlag(player, "-xuezou_using")
			end
		end
	end
} 



siminai:addSkill(ruanhua)
siminai:addSkill(xuezou)

sgs.LoadTranslationTable{

	["siminai"] = "四糸乃",
	["&siminai"] = "四糸乃",
	["#siminai"] = "隱居者",
	["cv:siminai"] = "野水伊織",
	["designer:siminai"] = "无限连の伯言",
	["illustrator:siminai"] = "tsunako",
	
	["xuezou"] = "雪走",
	[":xuezou"] = "每當場上牌的花色數達到四種時，你可以棄置其中一種花色的所有牌。",
	
	["ruanhua"] = "軟化",
	[":ruanhua"] = "<font color=\"blue\"><b>锁定技，</b></font>对你造成伤害或受到你伤害的角色须弃置等同於你无牌的区域数的牌，然後摸等同於你有牌的区域数的牌。",
}



akari_mamiya=sgs.General(extension,"akari_mamiya","science",4,false,false)

zhanmeiqiyuecard = sgs.CreateSkillCard{
    name = "zhanmeiqiyuecard",
    target_fixed = false,
    will_throw = true,
    filter = function(self, targets, to_select)
        if #targets ~= 0 then return false end
        if not to_select:isFemale() then return false end
        return true
    end,
    feasible = function(self, targets)
        return #targets == 1 
    end,
    on_use = function(self, room, source, targets)
        local victim = targets[1]
        victim:drawCards(1)
        if victim:getMark("zhanmeiqiyue_originer") == 0 then
            if not victim:hasSkill("zhanmeiqiyue") then
                room:acquireSkill(victim, "zhanmeiqiyue")
                room:handleAcquireDetachSkills(source,"-zhanmeiqiyue")
            end
        end
    end
}
zhanmeiqiyuevs = sgs.CreateZeroCardViewAsSkill{
    name = "zhanmeiqiyue",
    view_as = function()
        return zhanmeiqiyuecard:clone()
    end,
    enabled_at_play = function()
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@@zhanmeiqiyue"
    end
}

zhanmeiqiyue = sgs.CreateTriggerSkill{
    name = "zhanmeiqiyue",
    events = {sgs.Damaged, sgs.Damage},
    view_as_skill = zhanmeiqiyuevs,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:askForUseCard(player, "@@zhanmeiqiyue", "@zhanmeiqiyue", -1, sgs.Card_MethodNone) 
        return false
    end,
}
zhanmeiqiyueAux = sgs.CreateTriggerSkill{
    name = "zhanmeiqiyueAux",
    global = true,
    events = {sgs.GameStart,sgs.Death,sgs.EventPhaseStart,sgs.EventAcquireSkill},
    on_trigger = function(self, event, player, data)
        local room = sgs.Sanguosha:currentRoom()
        if event == sgs.GameStart then
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill("zhanmeiqiyue") then room:addPlayerMark(p,"zhanmeiqiyue_originer") end
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:getMark("zhanmeiqiyue_originer") > 0 then
                for _,p in sgs.qlist(room:getAlivePlayers())do
                    if p:hasSkill("zhanmeiqiyue") then room:handleAcquireDetachSkills(p,"-zhanmeiqiyue") end
                end
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start and player:getMark("zhanmeiqiyue_originer") > 0 then
                for _,p in sgs.qlist(room:getOtherPlayers(player))do
                    if p:hasSkill("zhanmeiqiyue") then room:handleAcquireDetachSkills(p,"-zhanmeiqiyue") end
                end
                if not player:hasSkill("zhanmeiqiyue") then
                    room:acquireSkill(player,"zhanmeiqiyue")
                end
            end
        elseif event == sgs.EventAcquireSkill then
            if room:findPlayersBySkillName("zhanmeiqiyue"):length() == 1 then
                room:setPlayerMark(room:findPlayersBySkillName("zhanmeiqiyue"):first(),"zhanmeiqiyue_originer",1)
            end
        end
        return false
    end,
    can_trigger = function()
        return true
    end
}

akari_mamiya:addSkill(zhanmeiqiyue)

sgs.addSkillToEngine(zhanmeiqiyueAux)

sgs.LoadTranslationTable{

	["#akari_mamiya"] = "抑制の杀意",
	["akari_mamiya"] = "间宫明里",
	["designer:akari_mamiya"] = "完美同调士",
	["cv:akari_mamiya"] = "佐仓绫音",
	["illustrator:akari_mamiya"] = "kubo mariko",
	["zhanmeiqiyue"] = "战妹契约",
	[":zhanmeiqiyue"] = "你造成或受到伤害后，可令一名女性角色摸一张牌，然后你将此技能转移给该角色。“间宫明里”的准备阶段，其获得该技能，然后其他角色失去此技能。“间宫明里”死亡时，所有角色失去该技能。",
}

Kanzaki_H_Aria=sgs.General(extension,"Kanzaki_H_Aria","science",4,false,false)

feitianshuangzhancard = sgs.CreateSkillCard{
name = "feitianshuangzhancard",
target_fixed = false,
will_throw = false,
filter = function(self, targets, to_select)
return #targets == 0
end,
feasible = function(self, targets)
return #targets == 1 
end,
on_use = function(self, room, player, targets)
local victim = targets[1]
local card = sgs.Sanguosha:getCard(self:getSubcards():first())
local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
slash:deleteLater()
slash:addSubcard(card) 
slash:setSkillName("feitianshuangzhan")
local use = sgs.CardUseStruct()
use.card = slash
use.from = player
use.to:append(victim)
room:useCard(use)
end
}
feitianshuangzhan = sgs.CreateViewAsSkill{
name = "feitianshuangzhan",
n = 1,
response_or_use = true,
view_filter = function(self, selected, to_select)
if sgs.Self:hasFlag("feitianshuangzhan_RedUsed") then
return to_select:isBlack()
elseif sgs.Self:hasFlag("feitianshuangzhan_BlackUsed") then
return to_select:isRed()
else
return true
end
return false
end,
view_as = function(self, cards)
if #cards == 1 then
if sgs.Slash_IsAvailable(sgs.Self) then
local card = cards[1]
local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
slash:addSubcard(card)
slash:setSkillName(self:objectName())
return slash
else
local card = feitianshuangzhancard:clone()
card:setSkillName(self:objectName())
card:addSubcard(cards[1])
return card
end
end
end,
enabled_at_play = function(self, player)
return not player:hasFlag("feitianshuangzhan_BlackUsed") or not player:hasFlag("feitianshuangzhan_RedUsed")
end,
enabled_at_response = function(self, player, pattern)
if not player:hasFlag("feitianshuangzhan_BlackUsed") or not player:hasFlag("feitianshuangzhan_RedUsed") then
return pattern == "slash"
end
end
}
feitianshuangzhanflag = sgs.CreateTriggerSkill{
name = "feitianshuangzhanflag",
frequency = sgs.Skill_Compulsory,
events = {sgs.EventPhaseChanging, sgs.CardUsed, sgs.PreCardUsed},
global = true,
on_trigger = function(self, event, player, data)
local room = player:getRoom()
if event == sgs.CardUsed then
local use = data:toCardUse()
if use.card:getSkillName() == "feitianshuangzhan" or use.from:hasSkill("feitianshuangzhan") then
    room:setPlayerMark(player, "&feitianshuangzhan+:+"..use.card:getColorString().."-Clear", 1)
if use.card:isRed() then
room:setPlayerFlag(use.from, "feitianshuangzhan_RedUsed")
elseif use.card:isBlack() then
room:setPlayerFlag(use.from, "feitianshuangzhan_BlackUsed")
end
end
elseif event == sgs.EventPhaseChanging then
if data:toPhaseChange().to == sgs.Player_NotActive then
for _, p in sgs.qlist(room:getAlivePlayers()) do
if p:hasFlag("feitianshuangzhan_BlackUsed") then
room:setPlayerFlag(p, "-feitianshuangzhan_BlackUsed")
end
if p:hasFlag("feitianshuangzhan_RedUsed") then
room:setPlayerFlag(p, "-feitianshuangzhan_RedUsed")
end
end
end
elseif event == sgs.PreCardUsed then 
local use = data:toCardUse()
if use.card and use.card:getSkillName() == "feitianshuangzhan" then
if (use.m_addHistory) then
room:addPlayerHistory(player, "Slash", -1)
use.m_addHistory = false
data:setValue(use)
end
end
end
return false
end,
can_trigger = function(self, target)
return target
end
}
feitianshuangzhanmod = sgs.CreateTargetModSkill{
name = "feitianshuangzhanmod",
global = true,
distance_limit_func = function(self, player, card)
if card:getSkillName() == "feitianshuangzhan" then
return 998 
end
return 0
end
}

local ymab_skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("feitianshuangzhanflag") then
ymab_skills:append(feitianshuangzhanflag)
end
if not sgs.Sanguosha:getSkill("feitianshuangzhanmod") then
ymab_skills:append(feitianshuangzhanmod)
end

sgs.Sanguosha:addSkills(ymab_skills)

Kanzaki_H_Aria:addSkill(feitianshuangzhan)

sgs.LoadTranslationTable{

	["#Kanzaki_H_Aria"] = "双剑双枪",
	["Kanzaki_H_Aria"] = "神崎·H·亚里亚",
	["designer:Kanzaki_H_Aria"] = "命运",
	["cv:Kanzaki_H_Aria"] = "钉宫理惠",
	["illustrator:Kanzaki_H_Aria"] = "NAbyssor",
	["feitianshuangzhan"] = "绯天双战",
	[":feitianshuangzhan"] = "你可将本回合内一张未使用过的颜色的牌当【杀】使用或打出（不计入出牌阶段使用限制），你以此法使用的红色杀无距离限制。",
}

Eucliwood_Hellscythe=sgs.General(extension,"Eucliwood_Hellscythe","magic",3,false,false)

jinyanmofa = sgs.CreateTriggerSkill{
name = "jinyanmofa",
events = {sgs.CardUsed},
on_trigger = function(self, event, player, data)
local room = player:getRoom()
local use = data:toCardUse()
local card, source, suit = use.card, use.from, use.card:getSuit()
if card and card:isKindOf("BasicCard") and source:hasSkill(self:objectName()) then
local targets = sgs.SPlayerList()
for _, p in sgs.qlist(room:getAlivePlayers()) do
local can = false
for _, judge in sgs.qlist(p:getJudgingArea()) do
if (judge:getSuit() == suit) and (source:canDiscard(p, judge:getEffectiveId())) then
can = true 
break
end
end
if can then 
targets:append(p)
else
if (not p:getEquips():isEmpty()) and (source:canDiscard(p, "e")) then
for _, equips_id in sgs.qlist(p:getEquips()) do
if sgs.Sanguosha:getEngineCard(equips_id:getEffectiveId()):getSuit() == suit and source:canDiscard(p, equips_id:getEffectiveId()) then
targets:append(p)
break
end
end
end
end
end
if not targets:isEmpty() then
if not room:askForSkillInvoke(source, self:objectName(), data) then return false end
local victim = room:askForPlayerChosen(source, targets, self:objectName(), "@jinyanmofa-discard", true, true)
if victim then
local disabled_ids = sgs.IntList()
for _, c in sgs.qlist(victim:getCards("ej")) do
if c:getSuit() ~= suit then
disabled_ids:append(c:getEffectiveId())
end
end
local id = room:askForCardChosen(source, victim, "ej", self:objectName(), false, sgs.Card_MethodDiscard, disabled_ids)
room:throwCard(id, victim, source)
end
end
end
return false
end,
can_trigger = function(self, target)
return target
end
}


busizhixue = sgs.CreateTriggerSkill{
name = "busizhixue",
events = {sgs.DamageInflicted},
on_trigger = function(self, event, player, data)
local room = player:getRoom() 
local damage = data:toDamage()
local victim = damage.to
for _, source in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
if victim and victim:getHp() <= source:getHp() then 
room:setTag("busizhixue", data)
if room:askForSkillInvoke(source, self:objectName(), data) then
    room:removeTag("busizhixue")
room:loseHp(source)
source:drawCards(source:getLostHp())

damage.prevented = true
						data:setValue(damage)
						return true
end
room:removeTag("busizhixue")
end
end
return false
end,
can_trigger = function(self, target)
return target
end
}

Eucliwood_Hellscythe:addSkill(jinyanmofa)

Eucliwood_Hellscythe:addSkill(busizhixue)

sgs.LoadTranslationTable{

	["#Eucliwood_Hellscythe"] = "死灵法师",
	["Eucliwood_Hellscythe"] = "优克莉伍德·海尔赛兹",
	["designer:Eucliwood_Hellscythe"] = "神域",
	["cv:Eucliwood_Hellscythe"] = "月宫绿",
	["illustrator:Eucliwood_Hellscythe"] = "Uxiaerng",
	["jinyanmofa"] = "禁言魔法",
	[":jinyanmofa"] = "每当你使用一张基本牌后，你可以弃置场上一张与该牌花色相同的牌。",
    ["busizhixue"] = "不死之血",
	[":busizhixue"] = "每当一名角色受到伤害时，若其体力值不大于你，你可以失去一点体力并令此伤害无效，然后摸X张牌（X为你已损失的体力值）",
}

Arthur=sgs.General(extension,"Arthur","real",4,true,false)

boyi = sgs.CreateTriggerSkill{
name = "boyi",
events = {sgs.TargetConfirmed},
on_trigger = function(self, event, player, data)
local room = player:getRoom()
if event == sgs.TargetConfirmed then
local use = data:toCardUse()
local card, killer = use.card, use.from
if card:isKindOf("Slash") then
-- for _, p in sgs.qlist(room:getAlivePlayers()) do
if (use.to:contains(player)) or (killer:objectName() == player:objectName()) then
if not player:hasSkill(self:objectName()) then return false end
if not player:isNude() and player:canDiscard(player, "he") then
if room:askForSkillInvoke(player, self:objectName(), data) then
if room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@boyi-discard") then
room:setCardFlag(use.card, "boyi_use")
room:addPlayerMark(player, use.card:getEffectiveId().."-Clear")
end
end
end
end
--end 
end
end
return false
end 
}
boyidraw = sgs.CreateTriggerSkill{
name = "boyidraw",
global = true,
frequency = sgs.Skill_Compulsory,
events = {sgs.CardOffset},
on_trigger = function(self, event, player, data) 
local room = player:getRoom()
if event == sgs.CardOffset then
local effect = data:toCardEffect()
if effect.card and effect.card:isKindOf("Slash") then
for _, p in sgs.qlist(room:findPlayersBySkillName("boyi")) do
if p:getMark(effect.card:getEffectiveId().."-Clear") > 0  then
if effect.card:hasFlag("boyi_use") then
p:drawCards(2)
end
end
end
end
end
return false
end,
can_trigger = function(self, target)
return target
end
}

Arthur:addSkill(boyi)

sgs.LoadTranslationTable{

	["#Arthur"] = "赌博师",
	["Arthur"] = "亚瑟",
	["designer:Arthur"] = "辰木",
	["cv:Arthur"] = "……",
	["illustrator:Arthur"] = "218",
	["boyi"] = "博弈",
	[":boyi"] = "当你使用一张【杀】或成为一张【杀】的目标时，你可以弃置一张牌，然后若此【杀】被【闪】抵消，你摸两张牌。",
}

Tanuma_Kaname=sgs.General(extension,"Tanuma_Kaname","real",4,true,false)

lingyincard = sgs.CreateSkillCard{
name = "lingyincard",
target_fixed = false,
will_throw = true,
filter = function(self, targets, to_select)
return #targets <= 0 
end,
feasible = function(self, targets)
return #targets == 1
end,
on_use = function(self, room, source, targets)
local victim = targets[1]
room:recover(victim, sgs.RecoverStruct(victim))
room:drawCards(victim, 1, self:objectName())
room:setPlayerMark(victim, "lingyin_victim", 1)
room:setPlayerMark(victim, "&lingyin+to+#"..source:objectName(), 1)
for _, p in sgs.qlist(room:getAlivePlayers()) do
room:insertAttackRangePair(p, victim)
end
end
}
lingyin = sgs.CreateZeroCardViewAsSkill{
name = "lingyin",
view_as = function()
return lingyincard:clone()
end,
enabled_at_play = function(self, player)
return not player:hasUsed("#lingyincard")
end
}
lingyinclear = sgs.CreateTriggerSkill{
name = "lingyinclear",
global = true,
events = {sgs.EventPhaseChanging},
on_trigger = function(self, event, player, data)
local room = player:getRoom()
if (data:toPhaseChange().to == sgs.Player_Start) and (player:hasSkill("lingyin")) then 
for _, p in sgs.qlist(room:getAlivePlayers()) do
for _, victim in sgs.qlist(room:getAlivePlayers()) do
if victim:getMark("lingyin_victim") >= 1 then 
room:removeAttackRangePair(p, victim)
end
end
end
for _, p in sgs.qlist(room:getAlivePlayers()) do
if p:getMark("lingyin_victim") > 0 then
room:setPlayerMark(p, "lingyin_victim", 0)
room:setPlayerMark(p, "&lingyin+to+#"..player:objectName(), 0)
end
end
end
return false
end
} 

Tanuma_Kaname:addSkill(lingyin)

sgs.LoadTranslationTable{

	["#Tanuma_Kaname"] = "八原的怪人",
	["Tanuma_Kaname"] = "田沼要",
	["designer:Tanuma_Kaname"] = "无限连的陆伯言",
	["cv:Tanuma_Kaname"] = "堀江一真",
	["illustrator:Tanuma_Kaname"] = "葎",
	["lingyin"] = "灵音",
	[":lingyin"] = "<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以令一名其他角色回复１点体力并摸一张牌，然后直到你下回合开始前，其在所有人的攻击范围内。",
}

local ymab_skills = sgs.SkillList() --替换掉原来的这里...
if not sgs.Sanguosha:getSkill("feitianshuangzhanflag") then
ymab_skills:append(feitianshuangzhanflag)
end
if not sgs.Sanguosha:getSkill("feitianshuangzhanmod") then
ymab_skills:append(feitianshuangzhanmod)
end
if not sgs.Sanguosha:getSkill("boyidraw") then
ymab_skills:append(boyidraw)
end
if not sgs.Sanguosha:getSkill("lingyinclear") then
ymab_skills:append(lingyinclear)
end
sgs.Sanguosha:addSkills(ymab_skills) --...到这里，这里有的技能均不用角色添加。。。




Mine = sgs.General(extension,"Mine","magic",4,false)


langmanpaotai = sgs.CreateTriggerSkill{
	name = "langmanpaotai",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
	local room = player:getRoom()
	if  event == sgs.CardUsed then
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			local targets = sgs.SPlayerList()
			local others = room:getOtherPlayers(player)
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            slash:deleteLater()
			for _,p in sgs.qlist(others) do
				if p:getAttackRange() <= player:getAttackRange() then
					if not use.to:contains(p) then
						if not sgs.Sanguosha:isProhibited(player, p, slash) then
							targets:append(p)
						end
					end
				end
			end
			if not targets:isEmpty() then
            room:setTag("langmanpaotai", data)
			local target = room:askForPlayerChosen(player,targets, self:objectName(), "langmanpaotai-invoke", true, true)
            room:removeTag("langmanpaotai")
				if target then
					use.to:append(target)
					room:sortByActionOrder(use.to)
					room:setCardFlag(use.card, self:objectName())
					data:setValue(use)
				end
			end
		end
	elseif event == sgs.DamageCaused then 
	local damage = data:toDamage()
	if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag(self:objectName()) then 
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			if not damage.to:isNude() then 
			local card_id = room:askForCardChosen(player,damage.to,"he",self:objectName())
						room:obtainCard(player,sgs.Sanguosha:getCard(card_id), false)
			end
            damage.prevented = true
            data:setValue(damage)
			return true
			end
		end
	end,
}

Mine:addSkill(langmanpaotai)


sgs.LoadTranslationTable{

	["#Mine"] = "定式的狙击",
	["Mine"] = "玛茵",
	["designer:Mine"] = "神域+七哀",
	["cv:Mine"] = "田村由香里",
	["illustrator:Mine"] = "swd3e2",
	
	["langmanpaotai"] = "浪漫炮台",
	[":langmanpaotai"] = "你使用杀时可以额外指定一名攻击范围不大于你的角色为目标，若如此做，该杀对任意目标造成伤害时，防止之，改为获得目标角色的一张牌。",
	["langmanpaotai-invoke"]  =  "你可以发动“浪漫炮台”<br/> <b>操作提示</b>: 选择一名攻击范围不大于你的角色→点击确定<br/>",
	
}


Gaim = sgs.General(extension,"Gaim","magic",4,true,false)

DuriNokocard = sgs.CreateSkillCard{
name = "DuriNokocard",
target_fixed = false,
will_throw = true,
filter = function(self, targets, to_select)
if sgs.Self:objectName() == to_select:objectName() then return false end
if to_select:isAllNude() then return false end
return sgs.Self:distanceTo(to_select) <= 1 
end,
feasible = function(self, targets)
return #targets >= 1 
end,
on_use = function(self, room, source, targets)
local cardcount = 0
for _, p in ipairs(targets) do
room:throwCard(room:askForCardChosen(source, p, "hej", "DuriNoko"), p, source)
cardcount = cardcount + 1 
end
if cardcount > source:getLostHp() then
room:loseHp(source)
end
end
}
DuriNoko = sgs.CreateZeroCardViewAsSkill{
name = "DuriNoko",
view_as = function()
return DuriNokocard:clone()
end,
enabled_at_play = function(self, player)
return not player:hasUsed("#DuriNokocard")
end
}

Gaim:addSkill(DuriNoko)

sgs.LoadTranslationTable{

	["#Gaim"] = "bravo DurianArms",
	["Gaim"] = "风莲严之介",
	["designer:Gaim"] = "神域",
	["cv:Gaim"] = "佐野岳",
	["illustrator:Gaim"] = "命",
	["DuriNoko"] = "DuriNoko",
	[":DuriNoko"] = "出牌阶段限一次，你可弃置一张牌并弃置任意名与你距离为１的角色各一张牌，若你以此法弃置的其他角色的牌的数量大于Ｘ，你失去１点体力（Ｘ为你已损失的体力值）。",
}

satoshi = sgs.General(extension,"satoshi","real",3, true, true, true)
listIndexOf = function(theqlist, theitem)
	local index = 0
	for _, item in sgs.qlist(theqlist) do
		if item == theitem then return index end
		index = index + 1
	end
end
zzy_shoufu = sgs.CreateTriggerSkill{
	name = "zzy_shoufu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self,event,player,data)
		if event == sgs.BeforeCardsMove then
			local room = player:getRoom()
			local move = data:toMoveOneTime()
			if (move.from == nil) or (move.from:objectName() == player:objectName()) then return false end
			if move.to_place ~= sgs.Player_DiscardPile then return false end
			if (move.to_place == sgs.Player_DiscardPile)
				and ((bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)) then
			local card_ids = sgs.IntList()
			local i = 0
			for _, card_id in sgs.qlist(move.card_ids) do
				if ((bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
						and (room:getCardOwner(card_id):objectName() == move.from:objectName())
						and ((move.from_places:at(i) == sgs.Player_PlaceHand) or (move.from_places:at(i) == sgs.Player_PlaceEquip))) then
					card_ids:append(card_id)
				end
				i = i + 1
			end
			if card_ids:isEmpty() then
				return false
			else
			local choice = room:askForChoice(player,self:objectName(),"cancel+zzy_shoufu_obtain+zzy_shoufu_draw")
			if choice == "zzy_shoufu_obtain" then
			local obtain = sgs.IntList()
				if not card_ids:isEmpty() then
					room:fillAG(card_ids, player)
					local id = room:askForAG(player, card_ids, false, self:objectName())
					card_ids:removeOne(id)
					obtain:append(id)
					room:clearAG(player)
				end
				if not obtain:isEmpty() then
					for _, id in sgs.qlist(obtain) do
						if move.card_ids:contains(id) then
							move.from_places:removeAt(listIndexOf(move.card_ids, id))
							move.card_ids:removeOne(id)
							data:setValue(move)
						end
						room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
						if not player:isAlive() then break end
						end
					end
				elseif choice == "zzy_shoufu_draw" then 
					player:drawCards(1)
				end
				if choice ~= "cancel" then
					if player:getHandcardNum() > player:getMaxHp() then 
					room:askForDiscard(player, self:objectName(), player:getHandcardNum() - player:getMaxHp(),player:getHandcardNum() - player:getMaxHp(), false,false)
					end
				end
			end
		end
			return false
		end
	end,
}
satoshi:addSkill(zzy_shoufu)

sgs.LoadTranslationTable{
	["satoshi"] = "小智",
	["#satoshi"] = "永無止境",
	["designer:satoshi"] = "辰本",
	["cv:satoshi"] = "松本梨香",
	["illustrator:satoshi"] = "チャネ子",
	
	["zzy_shoufu"] = "收服",
	[":zzy_shoufu"] = "当其他角色的牌因弃置进入弃牌堆时，你可选择一项：1、摸一张牌；2、获得其中一张。然后若你的手牌数大于X，你须将手牌弃至X（X为你的体力上限）。",
	["zzy_shoufu_draw"] = "摸一张牌",
	["zzy_shoufu_obtain"] = "获得其中一张",
	
}

gasaiyuno = sgs.General(extension,"gasaiyuno","real",4, false, true, true)

liantu = sgs.CreateTriggerSkill{
	name = "liantu" ,
	events = {sgs.Damage,sgs.Damaged, sgs.EventPhaseEnd, sgs.TargetConfirmed, sgs.CardFinished},
	frequency = sgs.Skill_NotFrequent, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local yuno = room:findPlayerBySkillName(self:objectName())
		if not yuno then return false end
		if event == sgs.Damage or event == sgs.Damaged then 
		local damage = data:toDamage()
		local target = nil
		if event == sgs.Damage then
			target = damage.to
		else
			target = damage.from
		end
		if not target or target:objectName() == player:objectName() or yuno:objectName() ~= player:objectName() or target:isDead() then return false end
		if not  (target:getMark(self:objectName()) > 0) then return false end
		local ids = sgs.IntList()
		if damage.card and damage.card:hasFlag(self:objectName()) then
			if damage.card:isVirtualCard() then
				ids = damage.card:getSubcards()
			else
				ids:append(damage.card:getEffectiveId())
			end
			end
			local all_place_table = true
			if ids:length() > 0 then
				for _, id in sgs.qlist(ids) do
					if room:getCardPlace(id) ~= sgs.Player_PlaceTable then
						all_place_table = false
						break
						end
						end
			else return false 
						end
						local dest = sgs.QVariant()
						dest:setValue(target)
            if all_place_table and room:askForSkillInvoke(yuno, self:objectName(), dest) then
			room:setPlayerFlag(yuno, self:objectName())
                target:obtainCard(damage.card)
				room:setPlayerFlag(target, "Global_InTempMoving");
		local original_places = sgs.PlaceList()
		local card_ids = sgs.IntList()
		local dummy = sgs.Sanguosha:cloneCard("slash")
			for i = 1,damage.damage,1 do
				if target:isNude() then break end
				card_ids:append(room:askForCardChosen(player, target, "eh", self:objectName()))
				original_places:append(room:getCardPlace(card_ids:at(i-1)))
				dummy:addSubcard(card_ids:at(i-1))
				target:addToPile("#liantu", card_ids:at(i-1), false)
			end
			if dummy:subcardsLength() > 0 then
				for i = 1,dummy:subcardsLength(),1 do
					room:moveCardTo(sgs.Sanguosha:getCard(card_ids:at(i-1)), target, original_places:at(i-1), false)
				end
			end
			room:setPlayerFlag(target, "-Global_InTempMoving")
				yuno:obtainCard(dummy)
		end
		elseif event ==sgs.EventPhaseEnd then 
		if player:getPhase() == sgs.Player_Finish then 
		for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasFlag("liantu") then
					room:setPlayerFlag(p, "-liantu")
				end
			end
		end
		elseif event == sgs.TargetConfirmed then 
		local use = data:toCardUse()
		if use.from and use.from:hasSkill(self:objectName()) then 
			room:setCardFlag(use.card, self:objectName())
			for _,p in sgs.qlist(use.to) do
					if p:objectName() ~= use.from:objectName()   then
						room:setPlayerMark(p, self:objectName(), 1)
					end
				end
			end
		if use.to:contains(player) and player:hasSkill(self:objectName()) and  player:objectName() ~= use.from:objectName() then
			room:setCardFlag(use.card, self:objectName())
			room:setPlayerMark(use.from, self:objectName(), 1)
		end
		elseif event == sgs.CardFinished then 
		local use = data:toCardUse()
		if use.card and use.card:hasFlag(self:objectName()) then 
		for _,p in sgs.qlist(room:getAlivePlayers()) do
						room:setPlayerMark(p, self:objectName(), 0)
				end
		end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

gasaiyuno:addSkill(liantu)

sgs.LoadTranslationTable{
	["gasaiyuno"] = "我妻由乃",
	["&gasaiyuno"] = "由乃",
	["#gasaiyuno"] = "猩红的绝恋",
	["designer:gasaiyuno"] = "zengzouyu",
	["cv:gasaiyuno"] = "村田知沙",
	["illustrator:gasaiyuno"] = "猫杉☆",
	
	["liantu"] = "恋屠",
	[":liantu"] = "每名角色的回合限一次，你对其他角色，其他角色对你使用的牌造成伤害结算后，你可令其获得造成伤害的牌，然后你获得其等量的牌。",
	
	
}








