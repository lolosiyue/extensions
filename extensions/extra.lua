extension = sgs.Package("extra", sgs.Package_GeneralPack)
extension_guandu = sgs.Package("fixandadd_guandu", sgs.Package_GeneralPack)
extension_heg = sgs.Package("new_heg", sgs.Package_GeneralPack)
extension_hegbian = sgs.Package("heg_bian", sgs.Package_GeneralPack)
extension_hegquan = sgs.Package("heg_quan", sgs.Package_GeneralPack)
extension_heglordex = sgs.Package("heg_lordex", sgs.Package_GeneralPack)
extension_twyj = sgs.Package("fixandadd_twyj", sgs.Package_GeneralPack)
local Guandu_event_only = false --OL官渡之战随机事件
local Guandu_event_reward = false 
function ChangeGeneral(room, player, skill_onwer_general_name)
	local generals = {}
	for _,name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
		if not sgs.Sanguosha:isGeneralHidden(name) and not table.contains(generals, name) then
			table.insert(generals, name)
		end
	end
	for _,p in sgs.qlist(room:getAlivePlayers()) do
		if table.contains(generals, p:getGeneralName()) then
			table.removeOne(generals, p:getGeneralName())
		end
		if table.contains(generals, p:getGeneral2Name()) then
			table.removeOne(generals, p:getGeneral2Name())
		end
	end
	local x = player:getMaxHp()
	local y = player:getHp()
	room:changeHero(player, generals[math.random(1, #generals)], false, false, player:getGeneral2Name() and player:getGeneral2Name() == skill_onwer_general_name)
	room:setPlayerProperty(player, "maxhp", sgs.QVariant(x))
	room:setPlayerProperty(player, "hp", sgs.QVariant(y))
end


function HeavenMove(player, id, movein, private_pile_name)  --将卡牌伪移动至&开头的私人牌堆中并限制使用或打出，以达到牌对你可见的效果
	local room = player:getRoom()		 --参数[ServerPlayer *player：可见角色; int id：伪移动卡牌id; bool movein：值true为进入私人牌堆，值false为移出私人牌堆; private_pile_name：私人牌堆名]
	pile_name = private_pile_name or "&talent"
	if movein then
		local move = sgs.CardsMoveStruct(id, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
		sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "guandu_shicai", ""))
		move.to_pile_name = pile_name
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _xuyou = sgs.SPlayerList()
		_xuyou:append(player)
		room:notifyMoveCards(true, moves, false, _xuyou)
		room:notifyMoveCards(false, moves, false, _xuyou)
		room:setPlayerCardLimitation(player, "use,response", "" .. id, true)
		player:setTag("HeavenMove", sgs.QVariant(id))
	else
		local move = sgs.CardsMoveStruct(id, player, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
		sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "guandu_shicai", ""))
		move.from_pile_name = pile_name
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _xuyou = sgs.SPlayerList()
		_xuyou:append(player)
		room:notifyMoveCards(true, moves, false, _xuyou)
		room:notifyMoveCards(false, moves, false, _xuyou)
		room:removePlayerCardLimitation(player, "use,response", "" .. id .. "$1")
	end
end

function SendComLog(self, player, n, invoke)
	if invoke == nil then invoke = true end
	if invoke then
		player:getRoom():sendCompulsoryTriggerLog(player, self:objectName())
		player:getRoom():broadcastSkillInvoke(self:objectName(), n)
	end
end
function ChoiceLog(player, choice, to)
	local log = sgs.LogMessage()
	log.type = "#choice"
	log.from = player
	log.arg = choice
	if to then
		log.to:append(to)
	end
	player:getRoom():sendLog(log)
end

card_used = sgs.CreateTriggerSkill{
	name = "card_used",
	events = {sgs.PreCardUsed, sgs.PreCardResponded},
	global = true,
	priority = -1,
	on_trigger = function(self, event, player, data, room)
		local card
		local invoke = true
		if event == sgs.PreCardUsed then
			card = data:toCardUse().card
		else
			if data:toCardResponse().m_isUse then
				card = data:toCardResponse().m_card
			else
				invoke = false
			end
		end
		if card and not card:isKindOf("SkillCard") then
			room:setPlayerMark(player, "used-before-suit-Clear", card:getSuit() + 1)
			if invoke then
				room:addPlayerMark(player, "used-Clear")
				if player:getPhase() == sgs.Player_Play then
					room:addPlayerMark(player, "used-PlayClear")
				end
			end
			room:addPlayerMark(player, "us-Clear")
			if player:getPhase() == sgs.Player_Play then
				room:addPlayerMark(player, "us-PlayClear")
			end
			if card:isKindOf("Slash") then
				room:addPlayerMark(player, "used_slash-Clear")
				room:addPlayerMark(player, "used_slashcount")
				if player:getPhase() == sgs.Player_Play then
					room:addPlayerMark(player, "used_slash-PlayClear")
					room:addPlayerMark(player, "used_slashPlay-Clear")
				end
			end
		end
		return false
	end
}
damage_record = sgs.CreateTriggerSkill{
	name = "damage_record",
	events = {sgs.DamageComplete},
	global = true,
	on_trigger = function(self, event, player, data, room)
		if data:toDamage().from then
			room:addPlayerMark(data:toDamage().from, self:objectName(), data:toDamage().damage)
			room:addPlayerMark(data:toDamage().from, self:objectName().."-Clear", data:toDamage().damage)
			if data:toDamage().from:getPhase() == sgs.Player_Play then
				room:addPlayerMark(data:toDamage().from, self:objectName().."play-Clear", data:toDamage().damage)
			end
		end
	end
}
card_clear = sgs.CreateTriggerSkill{
	name = "card_clear",
	global = true,
	events = {sgs.CardFinished, sgs.PostCardResponded},
	on_trigger = function(self, event, splayer, data, room)
		local usecard, usefrom, useto

		if event == sgs.CardFinished then
			local use = data:toCardUse()
			usecard = use.card
			useto = use.to
			usefrom = use.from
		elseif event == sgs.PostCardResponded and data:toCardResponse().m_isUse then
			usecard = data:toCardResponse().m_card
		end

		local function clearMarks(patterns, targets)
			for _, player in sgs.qlist(targets) do
				for _, mark in sgs.list(player:getMarkNames()) do
					for _, pattern in ipairs(patterns) do
						if string.find(mark, "Card") and string.find(mark, pattern) and player:getMark(mark) > 0 then
							room:setPlayerMark(player, mark, 0)
						end
					end
				end
			end
		end

		if usecard and not usecard:isKindOf("SkillCard") then
			local id = usecard:getEffectiveId()
			-- Clear targeted marks
			if useto then
				clearMarks({id .. "_targeted-Clear"}, useto)
			end
			-- Clear general and self marks
			local all_players = room:getAlivePlayers()
			local patterns = {id .. "-Clear"}
			if usefrom then
				table.insert(patterns, id .. "-SelfClear")
			end
			clearMarks(patterns, all_players)

			if event == sgs.CardFinished then
				-- Clear allcard targeted marks
				clearMarks({"_allcard_targeted-Clear"}, useto)
				-- Clear allcard and self allcard marks
				local extra_patterns = {"_allcard-Clear"}
				if usefrom then
					table.insert(extra_patterns, "_allcard-SelfClear")
				end
				clearMarks(extra_patterns, all_players)
			end
		elseif event == sgs.PostCardResponded then
			local card = data:toCardResponse().m_card
			local id = card:getEffectiveId()
			clearMarks({id .. "-Clear"}, room:getAlivePlayers())
		end
	end
}

IgnoreArmorLog = sgs.CreateTriggerSkill{
	name = "IgnoreArmorLog",
	events = {sgs.CardUsed},
	global = true,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.card:hasFlag("SlashIgnoreArmor") then
			local log = sgs.LogMessage()
			log.type = "#IgnoreArmor"
			log.from = player
			log.card_str = use.card:toString()
			room:sendLog(log)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}


local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("card_used") then skills:append(card_used) end
if not sgs.Sanguosha:getSkill("damage_record") then skills:append(damage_record) end
if not sgs.Sanguosha:getSkill("card_clear") then skills:append(card_clear) end
if not sgs.Sanguosha:getSkill("IgnoreArmorLog") then skills:append(IgnoreArmorLog) end

-- 武将：许攸（官渡之战身份版） --
guandu_xuyou = sgs.General(extension_guandu, "guandu_xuyou", "qun", "3", true)
-- 技能：【识才】牌堆顶的牌于你的出牌阶段内对你可见；出牌阶段，你可以弃置一张牌并获得牌堆顶的牌，若你的手牌中有此阶段内以此法获得的牌，你不能发动此技能。 --
guandu_shicaiCard = sgs.CreateSkillCard{
	name = "guandu_shicai",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local card = sgs.Sanguosha:getCard(room:getDrawPile():first())
		room:obtainCard(source, card, false)
		room:setCardFlag(card, self:objectName())
	end
}
guandu_shicaiVS = sgs.CreateOneCardViewAsSkill{
	name = "guandu_shicai",
	filter_pattern = ".",
	view_as = function(self, card)
		local skillcard = guandu_shicaiCard:clone()
		skillcard:addSubcard(card:getId())
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		for _, card in sgs.qlist(player:getHandcards()) do
			if card:hasFlag(self:objectName()) then
				return false
			end
		end
		return player:canDiscard(player, "he")
	end
}
guandu_shicai = sgs.CreateTriggerSkill{
	name = "guandu_shicai",
	view_as_skill = guandu_shicaiVS,
	events = {sgs.EventPhaseStart, sgs.BeforeCardsMove, sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		local id = room:getDrawPile():first()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				HeavenMove(player, id, true)
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if (move.from_places:contains(sgs.Player_DrawPile) and p:getPhase() == sgs.Player_Play and move.card_ids:contains(p:getTag("HeavenMove"):toInt()))
					or move.to_place == sgs.Player_DrawPile then
					HeavenMove(p, p:getTag("HeavenMove"):toInt(), false)
					p:setTag(self:objectName(), sgs.QVariant(true))
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getPhase() == sgs.Player_Play and p:getTag(self:objectName()):toBool() then
					HeavenMove(p, id, true)
					p:setTag(self:objectName(), sgs.QVariant(false))
				end
			end
		else
			if player:getPhase() == sgs.Player_Play then
				HeavenMove(player, player:getTag("HeavenMove"):toInt(), false)
				for _, card in sgs.qlist(player:getHandcards()) do
					if card:hasFlag(self:objectName()) then
						room:setCardFlag(card, "-" .. self:objectName())
					end
				end
			end
		end
		return false
	end
}
guandu_xuyou:addSkill(guandu_shicai)
-- 技能：【逞功】当一名角色使用牌指定目标后，若目标数不少于2，你可以令其摸一张牌。 --
chenggong = sgs.CreateTriggerSkill{
	name = "chenggong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if use.to:length() > 1 and not use.card:isKindOf("SkillCard") then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if use.from:isAlive() and room:askForSkillInvoke(p, self:objectName(), sgs.QVariant("to_draw:" .. use.from:objectName())) then
					room:doAnimate(1, p:objectName(), use.from:objectName())
					room:drawCards(use.from, 1, self:objectName())
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
guandu_xuyou:addSkill(chenggong)
--[[
	技能：【择主】出牌阶段限一次，你可以选择一至两名其他角色（若你不为主公，则其中必须有主公）。
				  你依次获得他们各一张牌（若目标角色没有牌，则改为你摸一张牌），然后分别将一张牌交给他们。
]]--
gd_zezhuCard = sgs.CreateSkillCard{
	name = "gd_zezhu",
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if sgs.Self:isLord() then
				return to_select:objectName() ~= sgs.Self:objectName()
			else
				return to_select:isLord()
			end
		elseif #targets == 1 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		for i = 1, 2 do
			for j = 1, #targets do
				local to = targets[j]
				if to:isDead() then continue end
				if i == 1 then
					if to:isNude() then
						room:drawCards(source, 1, self:objectName())
					else
						local id = room:askForCardChosen(source, to, "he", self:objectName())
						if id ~= -1 then
							room:obtainCard(source, id, false)
						end
					end
				elseif i == 2 then
					if source:isNude() then continue end
					local card = room:askForCard(source, "..!", "@gd_zezhu-give:" .. to:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
					if card then
						room:obtainCard(to, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), to:objectName(), self:objectName(), ""), false)
					end
				end
			end
		end
	end
}
gd_zezhu = sgs.CreateZeroCardViewAsSkill{
    name = "gd_zezhu",
    view_as = function()
        return gd_zezhuCard:clone()
    end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#gd_zezhu")
	end
}
guandu_xuyou:addSkill(gd_zezhu)

guandu_zangba = sgs.General(extension_guandu, "guandu_zangba", "wei", "4", true)


guandu_hengjiang = sgs.CreateMasochismSkill{
	name = "guandu_hengjiang",
	
	on_damaged = function(self,player,damage)
		local room = player:getRoom()
		for i = 1, damage.damage, 1 do 
			local current = room:getCurrent()
			if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then
		break 
	end		
			local value = sgs.QVariant()
				value:setValue(current)
			if room:askForSkillInvoke(player,self:objectName(),value) then
				room:addPlayerMark(current,"@hengjiang")
				room:addPlayerMark(player,"&guandu_hengjiang-Clear")
			end
		end
	end

}
guandu_hengjiangDraw = sgs.CreateTriggerSkill{
	name = "#guandu_hengjiangDraw",
	events = {sgs.TurnStart,sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TurnStart then
			room:setPlayerMark(player,"@hengjiang",0)
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and player:objectName() == move.from:objectName() and player:getPhase() == sgs.Player_Discard and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				player:setFlags("guandu_hengjiangDiscarded")
		end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			local zangba = room:findPlayerBySkillName("guandu_hengjiang")
			if not zangba then return false end
			if player:getMark("@hengjiang") > 0 then
			local invoke = false
			if not player:hasFlag("guandu_hengjiangDiscarded") then
				invoke = true
			end
				player:setFlags("-guandu_hengjiangDiscarded")
				room:setPlayerMark(player,"@hengjiang",0)
			if invoke then
				for _, zangba in sgs.qlist(room:findPlayersBySkillName("guandu_hengjiang")) do
					if zangba:getMark("&guandu_hengjiang-Clear") > 0 then
						zangba:drawCards(zangba:getMark("&guandu_hengjiang-Clear"), "guandu_hengjiang")	
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
guandu_hengjiangMaxCards = sgs.CreateMaxCardsSkill{
	name = "#guandu_hengjiangMaxCards",

	extra_func = function(self, target)
		return -target:getMark("@hengjiang")
	end
}
guandu_zangba:addSkill(guandu_hengjiang)
guandu_zangba:addSkill(guandu_hengjiangDraw)
guandu_zangba:addSkill(guandu_hengjiangMaxCards)
extension:insertRelatedSkills("guandu_hengjiang", "#guandu_hengjiangDraw")
extension:insertRelatedSkills("guandu_hengjiang", "#guandu_hengjiangMaxCards")


guandu_zhanghe = sgs.General(extension_guandu, "guandu_zhanghe", "qun", "4", true)

guandu_yuanlueCard = sgs.CreateSkillCard{
	name = "guandu_yuanlue" ,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
        room:obtainCard(effect.to, self)
        if room:askForUseCard(effect.to, ""..self:getSubcards():first(), "@guandu_yuanlue",-1,sgs.Card_MethodUse, false, effect.to, nil) then
			effect.from:drawCards(1, self:objectName())
		end
	end
}
guandu_yuanlue = sgs.CreateViewAsSkill{
	name = "guandu_yuanlue",
	n = 1 ,
	view_filter = function(self, selected, to_select)
		return not to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		local card = guandu_yuanlueCard:clone()
		if #cards ~= 1 then return nil end
		for _,p in ipairs(cards) do
			card:addSubcard(p)
		end
		return card
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#guandu_yuanlue")
	end
}

guandu_zhanghe:addSkill(guandu_yuanlue)

guandu_xinping = sgs.General(extension_guandu, "guandu_xinping", "qun", "3", true)
guandu_fuyuan = sgs.CreateTriggerSkill {
    name = "guandu_fuyuan",
    events = { sgs.CardUsed, sgs.CardResponded },
    on_trigger = function(self, event, player, data, room)
        local card = nil
        if (event == sgs.CardUsed) then
            local use = data:toCardUse()
            card = use.card
        elseif (event == sgs.CardResponded) then
            local res = data:toCardResponse()
            card = res.m_card
		end
		if card and not card:isKindOf("SkillCard") and player:getPhase() == sgs.Player_NotActive then
			local current = room:getCurrent()
			if current and current:isAlive() and room:askForSkillInvoke(player, self:objectName()) then
				if current:getHandcardNum() < player:getHandcardNum() then
					current:drawCards(1, self:objectName())
				else
					player:drawCards(1, self:objectName())
				end
			end
		end
	end
}

guandu_zhongjie = sgs.CreateTriggerSkill{
	name = "guandu_zhongjie" ,
	events = {sgs.Death} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local targets = room:getAlivePlayers()
		if targets:isEmpty() then return false end
		local target = room:askForPlayerChosen(player,targets,self:objectName(), "guandu_zhongjie-invoke", true, true)
		if not target then return false end
		room:gainMaxHp(target,1)
		local recover = sgs.RecoverStruct()
		recover.who = player
		recover.recover = 1
		room:recover(target, recover, true)
		target:drawCards(1, self:objectName())
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasSkill(self:objectName())
	end
}

guandu_xinping:addSkill(guandu_fuyuan)
guandu_xinping:addSkill(guandu_zhongjie)
guandu_xinping:addSkill("newyongdi")

sgs.Sanguosha:setAudioType("guandu_xinping","newyongdi","3,4")

guandu_hanmeng = sgs.General(extension_guandu, "guandu_hanmeng", "qun", "4", true)
guandu_jieliang_record = sgs.CreateTriggerSkill{
	name = "#guandu_jieliang_record",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		local source = move.from
		if source then
			if player:objectName() == source:objectName() and player:hasFlag("guandu_jieliang") then
				local hanmengs = room:findPlayersBySkillName(self:objectName())
				for _, hanmeng in sgs.qlist(hanmengs) do
					if hanmeng:getMark("guandu_jieliang-Clear") > 0 then
						if player:getPhase() == sgs.Player_Discard then
							local tag = room:getTag("GuzhengToGet")
							local guzhengToGet= tag:toString()
							if guzhengToGet == nil then
								guzhengToGet = ""
							end
							
							for _,card_id in sgs.qlist(move.card_ids) do
								local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
								if flag == sgs.CardMoveReason_S_REASON_DISCARD then
									if guzhengToGet == "" then
										guzhengToGet = tostring(card_id)
									else
										guzhengToGet = guzhengToGet.."+"..tostring(card_id)
									end
								end
							end
							if guzhengToGet then
								room:setTag("guandu_jieliangToGet", sgs.QVariant(guzhengToGet))
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
guandu_jieliang = sgs.CreateTriggerSkill {
	name = "guandu_jieliang",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart, sgs.DrawNCards, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local hanmengs = room:findPlayersBySkillName(self:objectName())
		if event == sgs.EventPhaseStart then
			if not player:isDead() and player:getPhase() == sgs.Player_Draw and not player:hasSkill(self:objectName()) then
				for _, hanmeng in sgs.qlist(hanmengs) do
					if not hanmeng:isNude() then
						local prompt = string.format("@guandu_jieliang:%s", player:objectName())
						if room:askForCard(hanmeng, ".", prompt, data, "guandu_jieliang") then
							room:setPlayerFlag(player, "guandu_jieliang")
							room:addMaxCards(player, -1, true)
							room:addPlayerMark(hanmeng, "guandu_jieliang-Clear")
							room:addPlayerMark(hanmeng, "&guandu_jieliang-Clear")
							room:addPlayerMark(player, "&guandu_jieliang+to+#".. hanmeng:objectName() .."-Clear")
						end
					end
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
        	if draw.reason ~= "draw_phase" then return false end
			if player:hasFlag("guandu_jieliang") then
				for _, hanmeng in sgs.qlist(hanmengs) do
					if hanmeng:getMark("guandu_jieliang-Clear") > 0 then
						draw.num = draw.num - 1
						if draw.num < 0 then
							draw.num = 0
						end
						data:setValue(draw)
					end
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Discard and player:hasFlag("guandu_jieliang") then
				local tag = room:getTag("guandu_jieliangToGet")
				local guzheng_cardsToGet
				if tag then
					guzheng_cardsToGet = tag:toString():split("+")
				else
					return false
				end
				local cardsToGet = sgs.IntList()
				local cards = sgs.IntList()
				for i=1,#guzheng_cardsToGet, 1 do
					local card_data = guzheng_cardsToGet[i]
					if card_data == nil then return false end
					if card_data ~= "" then --弃牌阶段没弃牌则字符串为""
						local card_id = tonumber(card_data)
						if room:getCardPlace(card_id) == sgs.Player_DiscardPile then
							cardsToGet:append(card_id)
							cards:append(card_id)
						end
					end
				end
				if cardsToGet:length() > 0 then
					local hanmengs = room:findPlayersBySkillName(self:objectName())
					for _, hanmeng in sgs.qlist(hanmengs) do
						if hanmeng:getMark("guandu_jieliang-Clear") > 0 then
							local ai_data = sgs.QVariant()
							ai_data:setValue(cards:length())
							if hanmeng:askForSkillInvoke(self:objectName(), ai_data) then
								room:fillAG(cards, hanmeng)
								local to_back = room:askForAG(hanmeng, cardsToGet, false, self:objectName())
								local backcard = sgs.Sanguosha:getCard(to_back)
								hanmeng:obtainCard(backcard)
								cards:removeOne(to_back)
								room:clearAG()
							end
						end
					end
				end
				room:removeTag("guandu_jieliangToGet")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

guandu_quanjiu = sgs.CreateFilterSkill{
	name = "guandu_quanjiu", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:isKindOf("Xujiu")) and (place == sgs.Player_PlaceHand)
	end,
	view_as = function(self, originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
		slash:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end
}
guandu_quanjiu_buff = sgs.CreateTargetModSkill{
	name = "#guandu_quanjiu_buff",
	residue_func = function(self, from, card, to)
        local n = 0
        if from:hasSkill("guandu_quanjiu") and (table.contains(card:getSkillNames(), "guandu_quanjiu")) then
            n = 999
        end
        return n
    end
}
guandu_quanjiu_buff2 = sgs.CreateTriggerSkill{
	name = "#guandu_quanjiu_buff2",
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and table.contains(use.card:getSkillNames(), "guandu_quanjiu") and use.m_addHistory then
				room:addPlayerHistory(player, use.card:getClassName(),-1)
			end
		end
	end,
}


guandu_hanmeng:addSkill(guandu_jieliang_record)
guandu_hanmeng:addSkill(guandu_jieliang)
guandu_hanmeng:addSkill(guandu_quanjiu)
guandu_hanmeng:addSkill(guandu_quanjiu_buff)
guandu_hanmeng:addSkill(guandu_quanjiu_buff2)
extension:insertRelatedSkills("guandu_jieliang", "#guandu_jieliang_record")
extension:insertRelatedSkills("guandu_quanjiu", "#guandu_quanjiu_buff")
extension:insertRelatedSkills("guandu_quanjiu", "#guandu_quanjiu_buff2")

guandu_chunyuqiong = sgs.General(extension_guandu, "guandu_chunyuqiong", "qun", "5", true)
guandu_cangchu = sgs.CreateTriggerSkill {
    name = "guandu_cangchu",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.GameStart, sgs.Damaged },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
		if event == sgs.GameStart then
        	room:addPlayerMark(player, "&ccliang", 3)
		else
			local damage = data:toDamage()
			if damage.nature ~= sgs.DamageStruct_Fire then return false end
			if damage.damage <= 0 then return false end
			room:removePlayerMark(player, "&ccliang")
		end
        return false
    end
}

guandu_sushou = sgs.CreateTriggerSkill{
	name = "guandu_sushou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards, sgs.MarkChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			for _, p in sgs.qlist(room:findPlayersBySkillName("guandu_sushou")) do
				if p:isYourFriend(player) and p:getMark("&ccliang") > 0 then
					room:sendCompulsoryTriggerLog(p, "guandu_sushou", true)
					room:broadcastSkillInvoke("guandu_sushou")
					draw.num = draw.num + 1
					data:setValue(draw)
				end
			end
		else
			local mark = data:toMark()
			if mark.name == "&ccliang" and mark.who:hasSkill(self:objectName()) and mark.who:objectName() == player:objectName() and mark.gain < 0 and player:getMark(mark.name) == 0 then
				room:loseMaxHp(player,1, self:objectName())
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if not p:isYourFriend(player) then
						p:drawCards(2, self:objectName())
					end
				end
			end
		end
	end,
    can_trigger = function(self, target)
        return (target ~= nil)
    end,
}
sgs.Sanguosha:setAudioType("guandu_chunyuqiong","liangying","3,4")

guandu_chunyuqiong:addSkill(guandu_cangchu)
guandu_chunyuqiong:addSkill("liangying")
guandu_chunyuqiong:addSkill(guandu_sushou)


gd_yuanjun = sgs.CreateTrickCard{
	name = "gd_yuanjun",
	class_name = "Yuanjun",
	subclass = sgs.LuaTrickCard_TypeNormal,
	target_fixed = false,
	can_recast = false,
	is_cancelable = true,
	damage_card = false,
    available = function(self,player)
    	for _,to in sgs.list(player:getAliveSiblings())do
			if CanToCard(self,player,to) then
				return self:cardIsAvailable(player)
			end
		end
    end,
	feasible = function(self,targets)
		return #targets<=2 and #targets>0
	end,
	filter = function(self,targets,to_select,source)
	    return to_select:isWounded() and to_select~=source
		and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
		and not source:isProhibited(to_select,self)
	end,
	on_effect = function(self,effect)
		local from,to,room = effect.from,effect.to,effect.to:getRoom()
		local recover = sgs.RecoverStruct()
		recover.who = from
		recover.recover = 1
		room:recover(to, recover)
		return false
	end,
}
gd_yuanjun:clone(2,12):setParent(extension_guandu)
gd_yuanjun:clone(2,1):setParent(extension_guandu)
gd_yuanjun:clone(0,1):setParent(extension_guandu)

gd_tunliang = sgs.CreateTrickCard{
	name = "gd_tunliang",
	class_name = "Tunliang",
	subclass = sgs.LuaTrickCard_TypeNormal,
	target_fixed = false,
	can_recast = false,
	is_cancelable = true,
	damage_card = false,
    available = function(self,player)
    	for _,to in sgs.list(player:getAliveSiblings())do
			if CanToCard(self,player,to) then
				return self:cardIsAvailable(player)
			end
		end
    end,
	feasible = function(self,targets)
		return #targets<=3 and #targets>0
	end,
	filter = function(self,targets,to_select,source)
	    return #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
		and not source:isProhibited(to_select,self)
	end,
	on_effect = function(self,effect)
		local from,to,room = effect.from,effect.to,effect.to:getRoom()
		to:drawCards(1, "Tunliang")
		return false
	end,
}
gd_tunliang:clone(2,3):setParent(extension_guandu)
gd_tunliang:clone(2,4):setParent(extension_guandu)



gd_xujiu = sgs.CreateBasicCard
{
    name = "gd_xujiu",
    class_name = "Xujiu",
    subtype = "buff_card",
    can_recast = false,
	damage_card = false,
    available = function(self,player)
    	for n,to in sgs.list(player:getAliveSiblings())do
			if self:cardIsAvailable(player)
			and CanToCard(self,player,to)
			then
				return true
			end
		end
    end,
	filter = function(self,targets,to_select,source)
		return to_select:getMark("gd_xujiu-Clear") < 1
	   	and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self)
		and not source:isProhibited(to_select,self)
	end,
	on_effect = function(self,effect)
		local room = effect.to:getRoom()
		room:addPlayerMark(effect.to, "gd_xujiu-Clear")
		room:addPlayerMark(effect.to, "&gd_xujiu-Clear")
	end,
}

gd_xujiu_on_trigger = sgs.CreateTriggerSkill{
	name = "gd_xujiu_on_trigger",
	frequency = sgs.Skill_Compulsory,
    priority = 4,
    global = true,
    events = {sgs.DamageInflicted},
    can_trigger = function(self,target)
        return target and target:isAlive() and target:getMark("gd_xujiu-Clear") > 0
    end,
    on_trigger = function(self,event,player,data)
        local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			player:damageRevises(data,1)
		end
    end,
}


gd_xujiu:clone(0,9):setParent(extension_guandu)
gd_xujiu:clone(1,9):setParent(extension_guandu)
gd_xujiu:clone(3,9):setParent(extension_guandu)
gd_xujiu:clone(0,3):setParent(extension_guandu)
gd_xujiu:clone(1,3):setParent(extension_guandu)
if not sgs.Sanguosha:getSkill("gd_xujiu_on_trigger") then skills:append(gd_xujiu_on_trigger) end

gd_jianshou_cardmax = sgs.CreateMaxCardsSkill{
    name = "#gd_jianshou_cardmax",
    extra_func = function(self, target)
        if target:getMark("gd_jianshoudaizhan-SelfClear") > 0 then
            return -target:getMark("gd_jianshoudaizhan-SelfClear")
        else
            return 0
        end
    end
}
gd_jianshou = sgs.CreateViewAsSkill{
	name = "gd_jianshou&" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if #selected > 0 then return false end
		local card = to_select
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return card:isKindOf("Jink")
		elseif (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return card:isKindOf("Jink")
			else
				return card:isKindOf("Slash")
			end
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local originalCard = cards[1]
		if originalCard:isKindOf("Slash") then
			local jink = sgs.Sanguosha:cloneCard("jink", originalCard:getSuit(), originalCard:getNumber())
			jink:addSubcard(originalCard)
			jink:setSkillName(self:objectName())
			return jink
		elseif originalCard:isKindOf("Jink") then
			local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
			slash:addSubcard(originalCard)
			slash:setSkillName(self:objectName())
			return slash
		else
			return nil
		end
	end ,
	enabled_at_play = function(self, target)
		return sgs.Slash_IsAvailable(target) and target:getMark("gd_jianshou_lun") == 0
	end,
	enabled_at_response = function(self, target, pattern)
		return (pattern == "slash") or (pattern == "jink") and target:getMark("gd_jianshou_lun") == 0
	end
}
if not sgs.Sanguosha:getSkill("gd_jianshou") then skills:append(gd_jianshou) end
if not sgs.Sanguosha:getSkill("#gd_jianshou_cardmax") then skills:append(gd_jianshou_cardmax) end
local banGuandu

GuanduOnTrigger = sgs.CreateTriggerSkill{
	name = "GuanduOnTrigger",
	frequency = sgs.Skill_Compulsory,
	global = true,
	events = {sgs.ConfirmDamage,sgs.GameReady,sgs.Death,sgs.CardsMoveOneTime, sgs.DamageCaused, sgs.RoundStart,
	sgs.EventPhaseChanging, sgs.DrawNCards, sgs.Damage, sgs.PreCardUsed, sgs.PreCardResponded, sgs.EventPhaseStart, sgs.CardUsed, sgs.CardFinished},
	priority = {5,5,5,5,5,5,5},
	can_trigger = function(self,target)
		if banGuandu==false or Guandu_event_only then return true elseif banGuandu then return end
		banGuandu = sgs.Sanguosha:currentRoom():getMode()~="08" or table.contains(sgs.Sanguosha:getBanPackages(),"fixandadd_guandu")
		return not banGuandu
	end,
	on_trigger = function(self,event,player,data,room)
		local log = sgs.LogMessage()
		log.type = "$jl_bingfen"
		log.from = room:getOwner()
		log.arg = "guandu"
		if event==sgs.GameReady then
			if not room:getLord() then return end
			if room:getTag("guandu"):toBool() then return end
			room:sendLog(log)
			room:setTag("guandu",ToData(true))
			if not Guandu_event_only then
				for _,p in sgs.list(room:getAlivePlayers())do
					if p:getRole()=="lord" then
						--room:setPlayerProperty(p,"hp",ToData(p:getHp()-1))
						--room:setPlayerProperty(p,"maxhp",ToData(p:getMaxHp()-1))
						p:setProperty("hp",ToData(p:getHp()-1))
						p:setProperty("maxhp",ToData(p:getMaxHp()-1))
						room:broadcastProperty(p,"hp")
						room:broadcastProperty(p,"maxhp")
					end
				end
				room:doLightbox("$guanduLightbox1",4333,77)
				local dc = dummyCard()
				for _,id in sgs.list(room:getDrawPile())do
					local c = sgs.Sanguosha:getEngineCard(id)
					log = c:getPackage()
					if log~="maneuvering"
					and log~="standard_cards"
					and log~="limitation_broken"
					then continue end
					if c:isKindOf("Lighting")
					or c:isKindOf("AmazingGrace")
					or c:isKindOf("GodSalvation")
					or c:isKindOf("SavageAssault")
					or c:isKindOf("Analeptic")
					then dc:addSubcard(id) end
				end
				log = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER,"","","ToTable","guandu")
				room:moveCardTo(dc,nil,sgs.Player_PlaceTable,log)
			end
			local sj = {"gd_liangcaokuifa","gd_xutuhuanjin","gd_yiruoshengqiang","gd_shicongerjiao","gd_huoshaowuchao","gd_liangjunxiangchi","gd_jianshoudaizhan", "gd_shishengshibai", "gd_zhanyanliangzhuwenchou"}
			sj = RandomList(sj)[1]
			log.arg = sj
			log.arg3 = ":"..sj
			log.arg2 = "guandu_sj"
			log.type = "$guandu_sj"
			room:sendLog(log)
			room:doSuperLightbox(sj,sj)
			room:setTag("guandu_sj",ToData(sj))
			if sj == "gd_jianshoudaizhan" then
				room:attachSkillToPlayer(player,"gd_jianshou")
			end
		elseif not room:getTag("guandu"):toBool()
		then return end
		if event==sgs.Death and Guandu_event_reward then
			log.type = "$guanduJISHA"
			local death = data:toDeath()
			log.to:append(death.who)
			local who = death.who
			death = death.damage
			if not death then return end
			death = death.from
			if not death or death:isDead()
			or death~=player then return end
			log.arg = "guandu_jisha"
			log.arg2 = "guandu_jiangli"
			log.from = death
			if who and death:isYourFriend(who) then
				death:throwAllHandCardsAndEquips()
			elseif not death:isYourFriend(who) then
			room:sendLog(log)
			room:obtainCard(death, who:wholeHandCards())
			end
		
		elseif event==sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.nature == sgs.DamageStruct_Normal then
				local sj = room:getTag("guandu_sj"):toString()
				if sj=="gd_huoshaowuchao" then
					log.type = "$guandu_event"
					log.arg = "gd_huoshaowuchao"
					log.arg2 = ":gd_huoshaowuchao"
					room:sendLog(log)
					damage.nature = sgs.DamageStruct_Fire
					data:setValue(damage)
				end
			end
        elseif event==sgs.RoundStart then
			local sj = room:getTag("guandu_sj"):toString()
			if sj=="gd_liangjunxiangchi" then
				local n = room:getTag("TurnLengthCount"):toInt()
				if n <= 4 then
					room:addMaxCards(player, 1, false)
				elseif player:getMark("gd_liangjunxiangchi") == 0 then
					room:addPlayerMark(player, "gd_liangjunxiangchi")
					room:addMaxCards(player, -n, false)
				end
			end
        elseif event==sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				local sj = room:getTag("guandu_sj"):toString()
				if sj=="gd_shicongerjiao" then
					local maxhp = 0
					local maxhandcard = 0
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if p:getHp() > maxhp then maxhp = p:getHp() end
						if p:getHandcardNum() > maxhandcard then maxhandcard = p:getHandcardNum() end
					end
					if player:getHp() > maxhp then
						log.type = "$guandu_event"
						log.arg = "gd_shicongerjiao"
						log.arg2 = ":gd_shicongerjiao"
						room:sendLog(log)
						room:askForDiscard(player, self:objectName(), 1, 1, false, true)
					end
					if player:getHandcardNum() >= maxhandcard then
						log.type = "$guandu_event"
						log.arg = "gd_shicongerjiao"
						log.arg2 = ":gd_shicongerjiao"
						room:sendLog(log)
						room:loseHp(player, 1, true, nil, "gd_shicongerjiao")
					end
				end
			elseif player:getPhase() == sgs.Player_Start then
				local sj = room:getTag("guandu_sj"):toString()
				if sj=="gd_zhanyanliangzhuwenchou" then
					local card = sgs.Sanguosha:cloneCard("Duel", sgs.Card_NoSuit, 0)
					card:setSkillName("gd_zhanyanliangzhuwenchou")
					card:deleteLater()
					local targets = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
						if not player:isCardLimited(card, sgs.Card_MethodUse) and not player:isProhibited(p, card) then
							targets:append(p)
						end
					end
					if targets:isEmpty() then room:loseHp(player, 1, true, nil, "gd_zhanyanliangzhuwenchou") return false end
					local target = room:askForPlayerChosen(player, targets, "gd_zhanyanliangzhuwenchou", "@gd_zhanyanliangzhuwenchou:"..card:objectName(), true, true)
					if target then
						local use = sgs.CardUseStruct()
						use.from = player
						use.card = card
						use.to:append(target)
						room:useCard(use, false)
					else
						room:loseHp(player, 1, true, nil, "gd_zhanyanliangzhuwenchou")
					end
				end
			end
        elseif event==sgs.EventPhaseChanging then
			if player:isDead() then return end
	     	local change = data:toPhaseChange()
			if change.to==sgs.Player_NotActive then
				local sj = room:getTag("guandu_sj"):toString()
				if sj == "gd_xutuhuanjin" then
					if not player:hasFlag("gd_xutuhuanjin") then
						room:addPlayerMark(player, "gd_xutuhuanjin")
						room:addPlayerMark(player, "&gd_xutuhuanjin")
					end
				end
			end
		elseif event==sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			local sj = room:getTag("guandu_sj"):toString()
			if sj == "gd_liangcaokuifa" then
				draw.num = draw.num - 1
				log.type = "$guandu_event"
				log.arg = "gd_liangcaokuifa"
				log.arg2 = ":gd_liangcaokuifa"
				room:sendLog(log)
				if draw.num < 0 then
					draw.num = 0
				end
			end
			if sj == "gd_xutuhuanjin" then
				if player:getMark("gd_xutuhuanjin") > 0 then
					room:setPlayerMark(player, "gd_xutuhuanjin", 0)
					room:setPlayerMark(player, "&gd_xutuhuanjin", 0)
					log.type = "$guandu_event"
					log.arg = "gd_xutuhuanjin"
					log.arg2 = ":gd_xutuhuanjin"
					room:sendLog(log)
					draw.num = draw.num + 1
				end
			end
			data:setValue(draw)
		elseif event==sgs.DamageCaused then
			local damage = data:toDamage()
			local sj = room:getTag("guandu_sj"):toString()
			if sj == "gd_yiruoshengqiang" then
				if damage.from and damage.to then
					if damage.to:getHp() > damage.from:getHp() then
						log.type = "$guandu_event"
						log.arg = "gd_yiruoshengqiang"
						log.arg2 = ":gd_yiruoshengqiang"
						room:sendLog(log)
						player:damageRevises(data,1)
					end
				end
			end
			if sj=="gd_liangjunxiangchi" then
				if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("gd_liangjunxiangchi") then
					log.type = "$guandu_event"
					log.arg = "gd_liangjunxiangchi"
					log.arg2 = ":gd_liangjunxiangchi"
					room:sendLog(log)
					player:damageRevises(data,1)
				end
			end
		elseif event==sgs.Damage then
			local damage = data:toDamage()
			local sj = room:getTag("guandu_sj"):toString()
			if sj == "gd_liangcaokuifa" then
				if damage.card and not damage.card:isKindOf("SkillCard") and player:getMark("gd_liangcaokuifa"..damage.card:objectName()) == 0 then
					room:addPlayerMark(player, "gd_liangcaokuifa"..damage.card:objectName())
					log.type = "$guandu_event"
					log.arg = "gd_liangcaokuifa"
					log.arg2 = ":gd_liangcaokuifa"
					room:sendLog(log)
					player:drawCards(1, "gd_liangcaokuifa")
				end
			end
			
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and not use.card:isKindOf("SkillCard") and use.card:hasFlag("gd_shishengshibai") then
				if not (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then return false end
				local sj = room:getTag("guandu_sj"):toString()
				if sj == "gd_shishengshibai" then
					local targets = sgs.SPlayerList()
					local useto = use.to
					for _,to in sgs.qlist(use.to) do
						if not to:isAlive() then
							return false
						end
					end
					if useto:isEmpty() then return false end
					room:useCard(sgs.CardUseStruct(use.card, player, use.to))
				end
			end
		elseif event == sgs.CardUsed then
			local sj = room:getTag("guandu_sj"):toString()
			if sj == "gd_liangjunxiangchi" then
				local use = data:toCardUse()
				if use.card and use.card:isKindOf("Slash") and player:getMark("gd_liangjunxiangchi") > 0 and player:getMark("gd_liangjunxiangchi_slash-Clear") == 0 then
					room:addPlayerMark(player, "gd_liangjunxiangchi_slash-Clear")
					room:setCardFlag(use.card, "gd_liangjunxiangchi")
				end
			end
		elseif event == sgs.PreCardUsed or event == sgs.PreCardResponded then
			local sj = room:getTag("guandu_sj"):toString()
			if sj == "gd_xutuhuanjin" or sj == "gd_xutuhuanjin" then
				local card
				if event == sgs.PreCardUsed then
					card = data:toCardUse().card
				else
					card = data:toCardResponse().m_card
				end
				if sj == "gd_xutuhuanjin" then
					if card and card:isKindOf("Slash") and player:getPhase() == sgs.Player_Play then
						room:setPlayerFlag(player, "gd_xutuhuanjin")
					end
				end
				if sj == "gd_jianshoudaizhan" then
					if card and table.contains(card:getSkillNames(), "gd_jianshou") then
						room:addPlayerMark(player, "&gd_jianshoudaizhan-SelfClear")
						room:addPlayerMark(player, "gd_jianshoudaizhan-SelfClear")
					end
				end
				if sj == "gd_shishengshibai" then
					if card and not card:isKindOf("SkillCard") then
						if event == sgs.PreCardResponded then
							if not data:toCardResponse().m_isUse then
								return false
							end
						end
						local usecardNum = room:getTag("gd_shishengshibai"):toInt() or 0
						usecardNum = usecardNum + 1
						room:setTag("gd_shishengshibai", ToData(usecardNum))
						if usecardNum % 10 == 0 then
							room:setCardFlag(card, "gd_shishengshibai")
						end
					end
				end
			end
		elseif event==sgs.GameOverJudge and not Guandu_event_only then
			log = room:getAlivePlayers()
			if log:length()>1 then return end
			room:gameOver(log:at(0):objectName())
		end
		return false
	end,
}
extension_guandu:addSkills(GuanduOnTrigger)



heg_ol_sunce = sgs.General(extension_heg, "heg_ol_sunce$", "wu", 3, true)
heg_ol_sunce:addSkill("jiang")
heg_ol_sunce:addSkill("yingyang")
--ol_hunshang = sgs.CreatePhaseChangeSkill{
--	name = "ol_hunshang",
--	frequency = sgs.Skill_Compulsory,
--	on_phasechange = function(self, player)
--		local room = player:getRoom()
--		if player:getPhase() == sgs.Player_Start and player:getHp() <= 1 then
--			room:sendCompulsoryTriggerLog(player, self:objectName())
--			room:addPlayerMark(player, self:objectName().."engine")
--			if player:getMark(self:objectName().."engine") > 0 then
--				room:addPlayerMark(player, self:objectName().."-Clear")
--				room:removePlayerMark(player, self:objectName().."engine")
--			end
--		end
--		return false
--	end
--}
function hunshangChange(room, player, hp, skill_name)
	local hunshang_skills = player:getTag("Hunshangskills"):toString():split("+")
	if player:getHp() <= hp then
		if not table.contains(hunshang_skills, skill_name) then
			room:notifySkillInvoked(player, "ol_hunshang")
			room:handleAcquireDetachSkills(player, skill_name)
			table.insert(hunshang_skills, skill_name)
		end
	else
		if table.contains(hunshang_skills, skill_name) then
			room:handleAcquireDetachSkills(player, "-"..skill_name)
			table.removeOne(hunshang_skills, skill_name)
		end
	end
	player:setTag("Hunshangskills", sgs.QVariant(table.concat(hunshang_skills, "+")))
end
ol_hunshang = sgs.CreateTriggerSkill{
	name = "ol_hunshang",
	events = {sgs.TurnStart, sgs.HpChanged, sgs.MaxHpChanged, sgs.EventAcquireSkill, sgs.EventLoseSkill},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TurnStart then
			local sunce = room:findPlayerBySkillName(self:objectName())
			if not sunce or not sunce:isAlive() then return false end
			hunshangChange(room, sunce, 1, "yinghun")
			hunshangChange(room, sunce, 1, "yingzi")
		end
		if event == sgs.EventLoseSkill then
			if data:toString() == self:objectName() then
				local hunshang_skills = player:getTag("Hunshangskills"):toString():split("+")
				local detachList = {}
				for _, skill_name in ipairs(hunshang_skills) do
					table.insert(detachList,"-"..skill_name)
				end
				room:handleAcquireDetachSkills(player, table.concat(detachList,"|"))
				player:setTag("Hunshangskills", sgs.QVariant())
			end
			return false
		elseif event == sgs.EventAcquireSkill then
			if data:toString() ~= self:objectName() then return false end
		end
		if not player:isAlive() or not player:hasSkill(self:objectName(), true) then return false end
		hunshangChange(room, player, 1, "yinghun")
		hunshangChange(room, player, 1, "yingzi")
		return false
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}
heg_ol_sunce:addSkill(ol_hunshang)
heg_ol_sunce:addSkill("zhiba")
heg_ol_sunce:addRelateSkill("yinghun")
heg_ol_sunce:addRelateSkill("yingzi")
sgs.Sanguosha:setAudioType("heg_ol_sunce","yinghun","3,4")
sgs.Sanguosha:setAudioType("heg_ol_sunce","yingzi","7,8")


heg_lvmeng = sgs.General(extension_heg, "heg_lvmeng", "wu", 4, true)
heg_keji = sgs.CreateTriggerSkill{
	name = "heg_keji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play and use.card and not use.card:isKindOf("SkillCard") then
				if use.card:getSuit() == sgs.Card_Spade then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Heart then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Club then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Diamond then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				end
				local suit = {}
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, self:objectName().."_") and player:getMark(mark) > 0 then
						table.insert(suit, mark:split("_")[4])
					end
				end
				if #suit >= 2 then
					room:setPlayerMark(player, self:objectName().."-Clear", 1)
				else
					room:setPlayerMark(player, self:objectName().."-Clear", 0)
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to and change.to == sgs.Player_Discard and player:hasSkill(self:objectName()) and player:getHandcardNum() >= player:getMaxCards() - 4 and player:getMark(self:objectName().."-Clear") == 0 then
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:addMaxCards(player, 4, true)
			end
		end
		return false
	end
}
heg_lvmeng:addSkill(heg_keji)
heg_mouduanCard = sgs.CreateSkillCard{
	name = "heg_mouduan",
	filter = function(self, targets, to_select)
		return #targets == 0 and (to_select:getJudgingArea():length() > 0 or to_select:getEquips():length() > 0)
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		if #targets == 0 then return end
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			if not targets[1]:hasEquip() and targets[1]:getJudgingArea():length() == 0 then return end
			local card_id = room:askForCardChosen(source, targets[1], "ej", self:objectName())
			local card = sgs.Sanguosha:getCard(card_id)
			local place = room:getCardPlace(card_id)
			local equip_index = -1
			if place == sgs.Player_PlaceEquip then
				local equip = card:getRealCard():toEquipCard()
				equip_index = equip:location()
			end
			local tos = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if equip_index ~= -1 then
					if not p:getEquip(equip_index) and p:hasEquipArea(equip_index) then
						tos:append(p)
					end
				else
					if not source:isProhibited(p, card) and not p:containsTrick(card:objectName()) and p:hasJudgeArea() then
						tos:append(p)
					end
				end
			end
			local tag = sgs.QVariant()
			tag:setValue(targets[1])
			room:setTag("heg_mouduanTarget", tag)
			--local to = room:askForPlayerChosen(source, tos, self:objectName(), "@qiaobian-to" .. card:objectName())
			local to = room:askForPlayerChosen(source, tos, self:objectName(), "@heg_mouduan-to")
			if to then
				room:moveCardTo(card, targets[1], to, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, source:objectName(), self:objectName(), ""))
			end
			room:removeTag("heg_mouduanTarget")
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
heg_mouduanVS = sgs.CreateZeroCardViewAsSkill{
	name = "heg_mouduan",
	view_as = function(self, cards)
		return heg_mouduanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@heg_mouduan"
	end
}
heg_mouduan = sgs.CreateTriggerSkill{
	name = "heg_mouduan",
	view_as_skill = heg_mouduanVS,
	events = {sgs.CardUsed, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play and use.card and not use.card:isKindOf("SkillCard") then
				
				room:addPlayerMark(player, self:objectName().."_type_"..use.card:getTypeId().."_-Clear")
				
				if use.card:getSuit() == sgs.Card_Spade then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Heart then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Club then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				elseif use.card:getSuit() == sgs.Card_Diamond then
					room:addPlayerMark(player, self:objectName().."_suit_"..use.card:getSuit().."_-Clear")
				end
				local suit = {}
				local types = {}
				for _, mark in sgs.list(player:getMarkNames()) do
					if string.find(mark, self:objectName().."_suit_") and player:getMark(mark) > 0 then
						table.insert(suit, mark:split("_")[4])
					end
					if string.find(mark, self:objectName().."_type_") and player:getMark(mark) > 0 then
						table.insert(types, mark:split("_")[4])
					end
				end
				if #suit >= 4 or #types >= 3 then
					room:setPlayerMark(player, self:objectName().."-Clear", 1)
				else
					room:setPlayerMark(player, self:objectName().."-Clear", 0)
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) and player:getMark(self:objectName().."-Clear") > 0 then
			room:askForUseCard(player, "@heg_mouduan", "@heg_mouduan")
		end
		return false
	end
}
heg_lvmeng:addSkill(heg_mouduan)



heg_zhangfei = sgs.General(extension_heg, "heg_zhangfei", "shu", 4, true)

heg_paoxiao = sgs.CreateTargetModSkill{
	name = "heg_paoxiao",
	pattern = "Slash" ,
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return 1000
		else
			return 0
		end
	end
}
heg_paoxiao_tr = sgs.CreateTriggerSkill{
	name = "#heg_paoxiao_tr",
	events = {sgs.CardUsed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event ==sgs.CardUsed then 
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and player:getMark("used_slash-Clear") > 0 and player:hasSkill("heg_paoxiao") then
                room:broadcastSkillInvoke("heg_paoxiao")
				if player:getMark("used_slash-Clear") == 2 then
					room:sendCompulsoryTriggerLog(player, "heg_paoxiao")
					player:drawCards(1)
				end
			end
		end
	end,
		can_trigger = function(self, target)
		return target
	end,
}





heg_zhangfei:addSkill(heg_paoxiao)
heg_zhangfei:addSkill(heg_paoxiao_tr)
extension_heg:insertRelatedSkills("heg_paoxiao","#heg_paoxiao_tr")


heg_new_zhugeliang = sgs.General(extension_heg, "heg_new_zhugeliang", "shu", 3, true)

heg_guanxing = sgs.CreateTriggerSkill{
	name = "heg_guanxing",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Start then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				local count = room:alivePlayerCount()
				if count > 5 then
					count = 5
				end
				local cards = room:getNCards(count)
                room:broadcastSkillInvoke(self:objectName())
                room:notifySkillInvoked(player, self:objectName())
				room:askForGuanxing(player,cards)
			end
		end
	end
}


heg_kongcheng = sgs.CreateTriggerSkill{
	name = "heg_kongcheng", 
	events = {sgs.TargetConfirming, sgs.BeforeCardsMove, sgs.EventPhaseStart}, 
    frequency  = sgs.Skill_Compulsory,
	on_trigger = function(self, triggerEvent, player, data)
		local room = player:getRoom()
		if triggerEvent == sgs.TargetConfirming then
            local use = data:toCardUse()
            if (not use.card)  then return false end
            if (not use.to:contains(player))  then return false end
            if (not player:isKongcheng())  then return false end
            if use.card:isKindOf("Slash") or use.card:isKindOf("Duel") then    
                room:broadcastSkillInvoke(self:objectName())
                SendComLog(self, player)
                use.to:removeOne(player)
                data:setValue(use)
            end
        elseif triggerEvent == sgs.BeforeCardsMove then
            local move = data:toMoveOneTime()
			if move.to and move.to:hasSkill(self:objectName()) and move.from and move.from:objectName() ~= player:objectName() and move.to and move.to:objectName() == player:objectName()
			and move.reason.m_reason == sgs.CardMoveReason_S_REASON_GIVE and player:isKongcheng() then
				
				--Player類型轉至ServerPlayer
				local move_from
				local move_to
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:objectName() == move.from:objectName() then
						move_from = p
					end
					if p:objectName() == move.to:objectName() then
						move_to = p
					end
				end
				
               if not move.card_ids:isEmpty() then
					for _, id in sgs.qlist(move.card_ids) do
						if move.card_ids:contains(id) then
							move.from_places:removeAt(listIndexOf(move.card_ids, id))
							move.card_ids:removeOne(id)
							data:setValue(move)
						end
                        player:addToPile("heg_kongcheng", sgs.Sanguosha:getCard(id))
						--room:moveCardTo(sgs.Sanguosha:getCard(id), player, sgs.Player_PlaceHand, move.reason, true)
						if not player:isAlive() then break end
					end
				end
			end
        elseif triggerEvent == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Draw and not player:getPile("heg_kongcheng"):isEmpty() then
                local dummy = sgs.Sanguosha:cloneCard("slash")
			 	for i=0, (player:getPile("heg_kongcheng"):length()-1), 1 do
                    dummy:addSubcard(player:getPile("heg_kongcheng"):at(i))
				end
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName(), "heg_kongcheng", "");
                room:obtainCard(player, dummy, reason, false)
            end
        end
        return false;
	end,
}

heg_new_zhugeliang:addSkill(heg_guanxing)
heg_new_zhugeliang:addSkill(heg_kongcheng)


heg_zhaoyun = sgs.General(extension_heg, "heg_zhaoyun", "shu", 4, true)

heg_longdan = sgs.CreateViewAsSkill{
	name = "heg_longdan" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if #selected > 0 then return false end
		local card = to_select
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return card:isKindOf("Jink")
		elseif (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return card:isKindOf("Jink")
			else
				return card:isKindOf("Slash")
			end
		else
			return false
		end
	end ,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local originalCard = cards[1]
		if originalCard:isKindOf("Slash") then
			local jink = sgs.Sanguosha:cloneCard("jink", originalCard:getSuit(), originalCard:getNumber())
			jink:addSubcard(originalCard)
			jink:setSkillName(self:objectName())
			return jink
		elseif originalCard:isKindOf("Jink") then
			local slash = sgs.Sanguosha:cloneCard("slash", originalCard:getSuit(), originalCard:getNumber())
			slash:addSubcard(originalCard)
			slash:setSkillName(self:objectName())
			return slash
		else
			return nil
		end
	end ,
	enabled_at_play = function(self, target)
		return sgs.Slash_IsAvailable(target)
	end,
	enabled_at_response = function(self, target, pattern)
		return (pattern == "slash") or (pattern == "jink")
	end
}

heg_longdan_tr = sgs.CreateTriggerSkill{
	name = "#heg_longdan_tr",
	events = {sgs.CardOffset, sgs.TargetSpecified},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardOffset then 
            local effect = data:toCardEffect()
			if effect.card and not effect.card:isKindOf("Slash") then return false end
            if  effect.to:hasSkill("heg_longdan") or effect.from:hasSkill("heg_longdan")  then
                if effect.from:hasSkill("heg_longdan") and effect.card and table.contains(effect.card:getSkillNames(), "heg_longdan") and player:objectName() == effect.from:objectName() then
                    local target = room:askForPlayerChosen(player, room:getOtherPlayers(effect.to), "heg_longdan", "heg_longdan-invoke", true, true)
                    if not target then return false end
                    local damage = sgs.DamageStruct()
						damage.from = player
						damage.to = target
						damage.damage = 1
						room:damage(damage)
                end
                if effect.to:hasSkill("heg_longdan") and effect.offset_card and table.contains(effect.offset_card:getSkillNames(), "heg_longdan") then
                    local target = room:askForPlayerChosen(effect.to, room:getOtherPlayers(effect.from), "heg_longdan_recover", "heg_longdan-invoke", true, true)
                    if not target then return false end
                    local recover = sgs.RecoverStruct()
					recover.who = effect.to
					room:recover(target,recover)
                end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = -99
}


heg_zhaoyun:addSkill(heg_longdan)
heg_zhaoyun:addSkill(heg_longdan_tr)
extension_heg:insertRelatedSkills("heg_longdan","#heg_longdan_tr")

heg_caoren = sgs.General(extension_heg, "heg_caoren", "wei")

heg_jushou = sgs.CreateTriggerSkill{
	name = "heg_jushou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player, self:objectName()) then
				local draw = getKingdoms(player)
				player:drawCards(draw)
				if player:canDiscard(player, "h") then
					local list = {}
					for _, c in sgs.qlist(player:getCards("h")) do
						if c:isKindOf("EquipCard") and c:isAvailable(player) and not player:isCardLimited(c, sgs.Card_MethodUse) then
							table.insert(list, c:toString())
						elseif not c:isKindOf("EquipCard") and player:canDiscard(player, c:getEffectiveId()) then
							table.insert(list, c:toString())
						end
					end
					if #list == 0 then
						local log = sgs.LogMessage()
						log.type = "$TenyearjushouShow"
						log.from = player
						room:sendLog(log)
						room:showAllCards(player)
					else
						local pattern = table.concat(list, ",")
						if not string.endsWith(pattern, "!") then
							pattern = pattern .. "!"
						end
						local card = room:askForCard(player, pattern, "@tenyearjushou", sgs.QVariant(), sgs.Card_MethodNone)
						if not card then
							card = sgs.Sanguosha:getCard(player:getRandomHandCardId())
						end
						if card:isKindOf("EquipCard") then
							room:useCard(sgs.CardUseStruct(card, player))
						else
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), self:objectName(), nil)
							room:throwCard(card, reason, player, nil)
						end
					end
				end
				if draw > 2 then
					player:turnOver()
				end
			end
		end
		return false
	end
}
heg_caoren:addSkill(heg_jushou)

heg_xuhuang = sgs.General(extension_heg, "heg_xuhuang", "wei")

heg_duanliangVS = sgs.CreateOneCardViewAsSkill{
	name = "heg_duanliang",
	filter_pattern = "BasicCard,EquipCard|black",
	response_or_use = true,
	view_as = function(self, card)
		local shortage = sgs.Sanguosha:cloneCard("supply_shortage",card:getSuit(),card:getNumber())
		shortage:setSkillName(self:objectName())
		shortage:addSubcard(card)
		return shortage
	end,
	enabled_at_play = function(self, player)
		return player:getMark("heg_duanliang-Clear") == 0
	end
}
heg_duanliang = sgs.CreateTriggerSkill {
	name = "heg_duanliang",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = heg_duanliangVS,
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local card = use.card
		if card:isKindOf("SupplyShortage") then
			for _, target in sgs.qlist(use.to) do
				if player:distanceTo(target) >= 2 then
					room:addPlayerMark(player, "heg_duanliang-Clear")
					room:addPlayerMark(player, "&heg_duanliang+fail-Clear")
				end
			end
		end
	end
}


heg_duanliangTargetMod = sgs.CreateTargetModSkill{
	name = "#heg_duanliangTargetMod",
	pattern = "SupplyShortage",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("heg_duanliang") and card and table.contains(card:getSkillNames(), "heg_duanliang") then
			return 999
		else
			return 0
		end
	end
}

heg_xuhuang:addSkill(heg_duanliang)
heg_xuhuang:addSkill(heg_duanliangTargetMod)
extension_heg:insertRelatedSkills("heg_duanliang", "#heg_duanliangTargetMod")


heg_huanggai = sgs.General(extension_heg, "heg_huanggai", "wu")
heg_kurouCard = sgs.CreateSkillCard{
	name = "heg_kurou",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:loseHp(source, 1, true, source, self:objectName())
		room:drawCards(source, 3, self:objectName())
		room:addSlashCishu(source, 1, true)
		room:addPlayerMark(source, "&heg_kurou-Clear")
	end
}
heg_kurou = sgs.CreateOneCardViewAsSkill{
	name = "heg_kurou",
	filter_pattern = ".!",
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_kurou")
	end, 
	view_as = function(self, originalCard) 
		local card = heg_kurouCard:clone()
		card:addSubcard(originalCard)
		card:setSkillName(self:objectName())
		return card
	end
}
heg_huanggai:addSkill(heg_kurou)

heg_zoushi = sgs.General(extension_heg, "heg_zoushi", "qun", 3, false)
local json = require ("json")
heg_qingchengCard = sgs.CreateSkillCard{
	name = "heg_qingcheng", 
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select) 
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	about_to_use = function(self,room,card_use)
		local player,to = card_use.from,card_use.to:first()
		local log = sgs.LogMessage()
		log.from = player
		log.to = card_use.to
		log.type = "#UseCard"
		log.card_str = card_use.card:toString()
		room:sendLog(log)
		local skill_list = {}
		local Qingchenglist = to:getTag("Qingcheng"):toString():split("+") or {}
		for _,skill in sgs.qlist(to:getVisibleSkillList()) do
			if (not table.contains(skill_list,skill:objectName())) and not skill:isAttachedLordSkill() then
				table.insert(skill_list,skill:objectName())
			end
		end
		table.removeTable(skill_list,Qingchenglist)
		local skill_qc = ""
		if (#skill_list > 0) then
			local dest = sgs.QVariant()
			dest:setValue(to)
			skill_qc = room:askForChoice(player, "heg_qingcheng", table.concat(skill_list,"+"), dest)
		end
		if (skill_qc ~= "") then
			ChoiceLog(player, skill_qc)
			table.insert(Qingchenglist,skill_qc)
			to:setTag("Qingcheng",sgs.QVariant(table.concat(Qingchenglist,"+")))
			room:addPlayerMark(to, "Qingcheng" .. skill_qc)
			for _,p in sgs.qlist(room:getAllPlayers())do
				room:filterCards(p, p:getCards("he"), true)
			end
			local jsonValue = {
				8
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		end
		local data = sgs.QVariant()
		data:setValue(card_use)
		local thread = room:getThread()
		thread:trigger(sgs.PreCardUsed, room, player, data)
		card_use = data:toCardUse()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), "", card_use.card:getSkillName(), "")
		room:moveCardTo(self, player, nil, sgs.Player_DiscardPile, reason, true)
		thread:trigger(sgs.CardUsed, room, player, data)
		thread:trigger(sgs.CardFinished, room, player, data)
		if sgs.Sanguosha:getCard(self:getSubcards():first()):isKindOf("EquipCard") then
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(to), "heg_qingcheng", "heg_qingcheng-invoke", true, true)
			if target then
				local skill_list = {}
				local Qingchenglist = target:getTag("Qingcheng"):toString():split("+") or {}
				for _,skill in sgs.qlist(target:getVisibleSkillList()) do
					if (not table.contains(skill_list,skill:objectName())) and not skill:isAttachedLordSkill() then
						table.insert(skill_list,skill:objectName())
					end
				end
				table.removeTable(skill_list,Qingchenglist)
				local skill_qc = ""
				if (#skill_list > 0) then
					skill_qc = room:askForChoice(player, "heg_qingcheng", table.concat(skill_list,"+"))
				end
				if (skill_qc ~= "") then
					ChoiceLog(player, skill_qc)
					table.insert(Qingchenglist,skill_qc)
					target:setTag("Qingcheng",sgs.QVariant(table.concat(Qingchenglist,"+")))
					room:addPlayerMark(target, "Qingcheng" .. skill_qc)
					for _,p in sgs.qlist(room:getAllPlayers())do
						room:filterCards(p, p:getCards("he"), true)
					end
					local jsonValue = {
						8
					}
					room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
				end
			end
		end
	end,
}
heg_qingchengVS = sgs.CreateOneCardViewAsSkill{
	name = "heg_qingcheng", 
	filter_pattern = ".|black",
	view_as = function(self, card) 
		local qcc = heg_qingchengCard:clone()
		qcc:addSubcard(card)
		qcc:setSkillName(self:objectName())
		return qcc
	end, 
	enabled_at_play = function(self, player)
		return player:canDiscard(player, "he")
	end, 
}
heg_qingcheng = sgs.CreateTriggerSkill{
	name = "heg_qingcheng", 
	events = {sgs.EventPhaseStart},
	view_as_skill = heg_qingchengVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_RoundStart then
			local room = player:getRoom()
            local Qingchenglist = player:getTag("Qingcheng"):toString():split("+")
            if #Qingchenglist == 0 then return false end
            for _,skill_name in pairs(Qingchenglist)do
                room:setPlayerMark(player, "Qingcheng" .. skill_name, 0);
            end
            player:removeTag("Qingcheng")
            for _,p in sgs.qlist(room:getAllPlayers())do
                room:filterCards(p, p:getCards("he"), true)
			end
            local jsonValue = {
				8
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
        end
        return false
	end,
	can_trigger = function(self, target)
		return target
	end,
	priority = 6
}
heg_huoshui = sgs.CreateTriggerSkill{
	name = "heg_huoshui",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.Death,
			sgs.MaxHpChanged, sgs.EventAcquireSkill,
			sgs.EventLoseSkill,sgs.PreHpLost},
	on_trigger = function(self, triggerEvent, player, data)
		if player == nil or player:isDead() then return end
		local room = player:getRoom()
		local triggerable = function(target)
			return target and target:isAlive() and target:hasSkill(self:objectName())
		end
		if not triggerable(room:getCurrent()) then
			for _,p in sgs.qlist(room:getAlivePlayers())do --在重新加mark之前先全部消除掉……
				for _,skill in sgs.qlist(p:getVisibleSkillList())do
					room:removePlayerMark(p,"Qingcheng"..skill:objectName())
					room:removePlayerCardLimitation(player, "use,response", "Jink$1");
				end
			end
		end
		local jsonValue = {
			8
		}
		room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		if triggerEvent == sgs.EventPhaseStart then
			if (not triggerable(player)) or (player:getPhase() ~= sgs.Player_RoundStart and player:getPhase() ~= sgs.Player_NotActive) then
				return false
			end
		elseif triggerEvent == sgs.Death then
			local death = data:toDeath()
			if death.who:objectName() ~= player:objectName() or (not player:hasSkill(self:objectName())) then 
				return false 
			end
		elseif triggerEvent == sgs.EventLoseSkill then
			if data:toString() ~= self:objectName() or player:getPhase() == sgs.Player_NotActive then return false end
		elseif (triggerEvent == sgs.EventAcquireSkill) then
			if data:toString() ~= self:objectName() or (not player:hasSkill(self:objectName())) or player:getPhase() == sgs.Player_NotActive then
				return false
			end
		elseif triggerEvent == sgs.MaxHpChanged or triggerEvent == sgs.HpChanged then
			if not(room:getCurrent() and room:getCurrent():hasSkill(self:objectName())) then
				return false 
			end
		end
		
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			if p:getHp() >= (p:getMaxHp()/2) then
				room:filterCards(p,p:getCards("he"),true)
				for _,skill in sgs.qlist(p:getVisibleSkillList())do
					room:addPlayerMark(p,"Qingcheng"..skill:objectName())
				end
				room:setPlayerCardLimitation(player, "use,response", "Jink", true);
			end
		end
		local jsonValue = {
			8
		}
		room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
	end,
	can_trigger = function(self, player)
		return player
	end,
	priority = 5
}

heg_zoushi:addSkill(heg_qingcheng)
heg_zoushi:addSkill(heg_huoshui)

heg_xiahouyuan = sgs.General(extension_heg, "heg_xiahouyuan", "wei", 5)
heg_shensuCard = sgs.CreateSkillCard{
	name = "heg_shensu" ,
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("heg_shensu")
		slash:deleteLater()
		return slash:targetFilter(targets_list, to_select, sgs.Self)
	end ,
	on_use = function(self, room, source, targets)
		local targets_list = sgs.SPlayerList()
		for _, target in ipairs(targets) do
			if source:canSlash(target, nil, false) then
				targets_list:append(target)
			end
		end
		if targets_list:length() > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:deleteLater()
			slash:setSkillName("heg_shensu")
			room:useCard(sgs.CardUseStruct(slash, source, targets_list))
		end
	end
}
heg_shensuVS = sgs.CreateViewAsSkill{
	name = "heg_shensu" ,
	n = 1 ,
	view_filter = function(self, selected, to_select)
		if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "1") or string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "3") then 
			return false
		else
			return #selected == 0 and to_select:isKindOf("EquipCard") and not sgs.Self:isJilei(to_select)
		end
	end ,
	view_as = function(self, cards)
		if string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "1") or string.endsWith(sgs.Sanguosha:getCurrentCardUsePattern(), "3") then
			return #cards == 0 and heg_shensuCard:clone() or nil
		else
			if #cards ~= 1 then
				return nil
			end
			local card = heg_shensuCard:clone()
			for _, cd in ipairs(cards) do
				card:addSubcard(cd)
			end
			return card
		end
	end ,
	enabled_at_play = function()
		return false
	end ,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@heg_shensu")
	end
}
heg_shensu = sgs.CreateTriggerSkill{
	name = "heg_shensu" ,
	events = {sgs.EventPhaseChanging} ,
	view_as_skill = heg_shensuVS ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge) 
			and not player:isSkipped(sgs.Player_Draw) then
			if sgs.Slash_IsAvailable(player) and room:askForUseCard(player, "@@heg_shensu1", "@tenyearshensu1", 1) then
				player:skip(sgs.Player_Judge)
				player:skip(sgs.Player_Draw)
			end
		elseif sgs.Slash_IsAvailable(player) and change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) then
			if player:canDiscard(player, "he") and room:askForUseCard(player, "@@heg_shensu2", "@tenyearshensu2", 2, sgs.Card_MethodDiscard) then
				player:skip(sgs.Player_Play)
			end
		elseif sgs.Slash_IsAvailable(player) and change.to == sgs.Player_Discard and not player:isSkipped(sgs.Player_Discard) then
			if player:canDiscard(player, "he") and room:askForUseCard(player, "@@heg_shensu3", "@tenyearshensu3", 2, sgs.Card_MethodDiscard) then
				room:loseHp(player, 1, true, player, self:objectName())
				player:skip(sgs.Player_Discard)
			end
		end
		return false
	end
}
heg_shensuSlash = sgs.CreateTargetModSkill{
	name = "#heg_shensuSlash" ,
	pattern = "Slash" ,
	distance_limit_func = function(self, player, card)
		if player:hasSkill("heg_shensu") and (table.contains(card:getSkillNames(), "heg_shensu")) then
			return 1000
		else
			return 0
		end
	end
}
heg_xiahouyuan:addSkill(heg_shensu)
heg_xiahouyuan:addSkill(heg_shensuSlash)
extension_heg:insertRelatedSkills("heg_shensu", "#heg_shensuSlash")

heg_xuchu = sgs.General(extension_heg, "heg_xuchu", "wei", 4)

heg_luoyi = sgs.CreateTriggerSkill{
	name = "heg_luoyi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			if player:canDiscard(player, "he") then
				local card = room:askForCard(player, ".", "@heg_luoyi", sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), self:objectName(), nil)
					room:throwCard(card, reason, player, nil)
					room:setPlayerFlag(player, "heg_luoyi")
					room:addPlayerMark(player, "&heg_luoyi-Clear")
				end
			end
		end
		return false
	end
}
heg_luoyiBuff = sgs.CreateTriggerSkill{
	name = "#heg_luoyiBuff",
	frequency = sgs.Skill_Frequent,
	events = {sgs.ConfirmDamage},
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local reason = damage.card
		if reason then
			if reason:isKindOf("Slash") or reason:isKindOf("Duel") then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:hasFlag("heg_luoyi") then
				return target:isAlive()
			end
		end
		return false
	end
}
heg_xuchu:addSkill(heg_luoyi)
heg_xuchu:addSkill(heg_luoyiBuff)
extension_heg:insertRelatedSkills("heg_luoyi", "#heg_luoyiBuff")

heg_dianwei = sgs.General(extension_heg, "heg_dianwei", "wei", 4)

heg_qiangxiCard = sgs.CreateSkillCard{
	name = "heg_qiangxi", 
	filter = function(self, targets, to_select) 
		if #targets ~= 0 or to_select:objectName() == sgs.Self:objectName() then return false end--根据描述应该可以选择自己才对
		return true
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		if self:getSubcards():isEmpty() then 
			room:loseHp(effect.from, 1, true, effect.from, self:objectName())
		end
		room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
	end
}
heg_qiangxi = sgs.CreateViewAsSkill{
	name = "heg_qiangxi", 
	n = 1, 
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_qiangxi")
	end,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isKindOf("Weapon") and not sgs.Self:isJilei(to_select)
	end, 
	view_as = function(self, cards) 
		if #cards == 0 then
			return heg_qiangxiCard:clone()
		elseif #cards == 1 then
			local card = heg_qiangxiCard:clone()
			card:addSubcard(cards[1])
			return card
		else 
			return nil
		end
	end
}
heg_dianwei:addSkill(heg_qiangxi)

heg_guanyu = sgs.General(extension_heg, "heg_guanyu", "shu", 5)

heg_guanyu:addSkill("tenyearwusheng")

heg_huangzhong = sgs.General(extension_heg, "heg_huangzhong", "shu", 4)

heg_liegong = sgs.CreateTriggerSkill {
	name = "heg_liegong",
	events = { sgs.TargetConfirmed, sgs.CardFinished, sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				if (p:getHp() >= player:getHp()) then
					local _data = sgs.QVariant()
					_data:setValue(p)
					local choice = room:askForChoice(player, self:objectName(), "heg_liegong_cantjink+heg_liegong_addDamage+cancel",_data)
					if choice == "heg_liegong_cantjink" then
						local log = sgs.LogMessage()
						log.type = "#skill_cant_jink"
						log.from = player
						log.to:append(p)
						log.arg = self:objectName()
						room:sendLog(log)
						jink_table[index] = 0
					elseif choice == "heg_liegong_addDamage" then
						room:setCardFlag(use.card, self:objectName())
						room:setPlayerFlag(p, self:objectName())
					end
				end
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:hasFlag(self:objectName()) then
				for _, p in sgs.qlist(use.to) do
					room:setPlayerFlag(p, "-"..self:objectName())
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
            if damage.card and damage.card:hasFlag(self:objectName()) and damage.to and damage.to:hasFlag(self:objectName()) then
				damage.damage = damage.damage + 1
				local log = sgs.LogMessage()
				log.type = "#skill_add_damage"
				log.from = damage.from
				log.to:append(damage.to)
				log.arg  = self:objectName()
				log.arg2 = damage.damage
				room:sendLog(log)
				data:setValue(damage)
			end
		end
			return false
	end
}
heg_liegong_Target = sgs.CreateTargetModSkill {
	name = "#heg_liegong_Target",
	pattern = "Slash",
	distance_limit_func = function(self, player, card, to)
		if player:hasSkill("heg_liegong") and to:getHandcardNum() <= player:getHandcardNum() then
			return 999
		end
	end,
}

heg_huangzhong:addSkill(heg_liegong)
heg_huangzhong:addSkill(heg_liegong_Target)
extension_heg:insertRelatedSkills("heg_liegong","#heg_liegong_Target")

heg_sunjian = sgs.General(extension_heg, "heg_sunjian", "wu", 5)
heg_yinghun = sgs.CreateTriggerSkill{
	name = "heg_yinghun",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "heg_yinghun", "heg_yinghun-invoke", true, true)
		if target then
			local x = player:getLostHp()
			local dest = sgs.QVariant()
			dest:setValue(target)
			local choice = room:askForChoice(player, self:objectName(), "d1tx+dxt1", dest)
			if choice == "d1tx" then
				target:drawCards(1)
				x = math.min(x, target:getCardCount(true))
				room:askForDiscard(target, self:objectName(), x, x, false, true)
			else
				target:drawCards(x)
				room:askForDiscard(target, self:objectName(), 1, 1, false, true)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target then
			if target:isAlive() and target:hasSkill(self:objectName()) then
				if target:getPhase() == sgs.Player_Start then
					return true
				end
			end
		end
		return false
	end
}
heg_sunjian:addSkill(heg_yinghun)

heg_sunshangxiang = sgs.General(extension_heg, "heg_sunshangxiang", "wu", 3, false)

heg_xiaoji = sgs.CreateTriggerSkill{
	name = "heg_xiaoji" ,
	frequency = sgs.Skill_Frequent ,
	events = {sgs.CardsMoveOneTime} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
			for i = 0, move.card_ids:length() - 1, 1 do
				if not player:isAlive() then return false end
				if move.from_places:at(i) == sgs.Player_PlaceEquip then
					if room:askForSkillInvoke(player, self:objectName()) then
						if player:getPhase() == sgs.Player_NotActive then
							player:drawCards(3)
						else
							player:drawCards(1)
						end
					else
						break
					end
				end
			end
		end
		return false
	end
}

heg_sunshangxiang:addSkill(heg_xiaoji)
heg_sunshangxiang:addSkill("jieyin")

heg_new_xiaoqiao = sgs.General(extension_heg, "heg_new_xiaoqiao", "wu", 3, false)

heg_tianxiangCard = sgs.CreateSkillCard{
	name = "heg_tianxiang",
	filter = function(self, selected, to_select)
		return #selected == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local damage = source:getTag("heg_tianxiangDamage"):toDamage()	--yun
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 and damage.from then
			local choices = {"cancel"}
			if source:getMark("heg_tianxiang_one-Clear") == 0 then
				table.insert(choices, "heg_tianxiang1")
			end
			if targets[1]:getHp() > 0 and source:getMark("heg_tianxiang_two-Clear") == 0 then
				table.insert(choices, "heg_tianxiang2")
			end
			local choice = room:askForChoice(source, self:objectName(), table.concat(choices, "+"))
			if choice == "heg_tianxiang1" then
				--room:damage(sgs.DamageStruct(self:objectName(), source, targets[1]))
				room:addPlayerMark(source, "heg_tianxiang_one-Clear")
				room:damage(sgs.DamageStruct(self:objectName(), damage.from, targets[1]))
				targets[1]:drawCards(math.min(targets[1]:getLostHp(), 5), "tianxiang")
			elseif choice == "heg_tianxiang2" then
				room:addPlayerMark(source, "heg_tianxiang_two-Clear")
				room:loseHp(targets[1], 1, true, source, self:objectName())
				if targets[1]:isAlive() then
					room:obtainCard(targets[1], self)
				end
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
heg_tianxiangVS = sgs.CreateOneCardViewAsSkill{
	name = "heg_tianxiang",
	view_filter = function(self, selected)
		return not selected:isEquipped() and selected:getSuit() == sgs.Card_Heart and not sgs.Self:isJilei(selected)
	end,
	view_as = function(self, card)
		local tianxiangCard = heg_tianxiangCard:clone()
		tianxiangCard:addSubcard(card)
		return tianxiangCard
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@heg_tianxiang"
	end
}
heg_tianxiang = sgs.CreateTriggerSkill{
	name = "heg_tianxiang",
	events = {sgs.DamageInflicted},
	view_as_skill = heg_tianxiangVS,
	on_trigger = function(self, event, player, data, room)
		if player:canDiscard(player, "h") then
			local choices = {"cancel"}
			if player:getMark("heg_tianxiang_one-Clear") == 0 then
				table.insert(choices, "heg_tianxiang1")
			end
			if player:getMark("heg_tianxiang_two-Clear") == 0 then
				table.insert(choices, "heg_tianxiang2")
			end
			if #choices == 1 then return false end
			player:setTag("heg_tianxiangDamage", data)	--yun
			return room:askForUseCard(player, "@@heg_tianxiang", "@heg_tianxiang", -1, sgs.Card_MethodDiscard)
		end
		return false
	end
}
heg_hongyan = sgs.CreateFilterSkill{
	name = "heg_hongyan",
	view_filter = function(self, to_select)
		return to_select:getSuit() == sgs.Card_Spade
	end,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		new_card:setSkillName(self:objectName())
		new_card:setSuit(sgs.Card_Heart)
		new_card:setModified(true)
		return new_card
	end
}
heg_hongyanKeep = sgs.CreateMaxCardsSkill {
	name = "#heg_hongyanKeep",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			for _, equip in sgs.qlist(target:getEquips()) do
				if equip:getSuit() == sgs.Card_Heart then
					return 1
				end
			end
		end
		return 0
	end
}
heg_new_xiaoqiao:addSkill(heg_tianxiang)
heg_new_xiaoqiao:addSkill(heg_hongyan)
heg_new_xiaoqiao:addSkill(heg_hongyanKeep)
extension_heg:insertRelatedSkills("heg_hongyan","#heg_hongyanKeep")

heg_lubu = sgs.General(extension_heg, "heg_lubu", "qun", 5)

heg_wushuang = sgs.CreateTargetModSkill {
	name = "heg_wushuang",
	pattern = "Duel",
	extra_target_func = function(self,from,card)
		if from:hasSkill("heg_wushuang") and not card:isVirtualCard() then return 2 end
		return 0
	end,
}

heg_lubu:addSkill(heg_wushuang)
heg_lubu:addSkill("wushuang")

heg_jiling = sgs.General(extension_heg, "heg_jiling", "qun", 4)
heg_shuangrenCard = sgs.CreateSkillCard{
	name = "heg_shuangren",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodPindian,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if not to_select:isKongcheng() then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
		end
		return false
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local success = effect.from:pindian(effect.to, "heg_shuangren")
		if success then
			local targets = sgs.SPlayerList()
			local others = room:getOtherPlayers(effect.from)
			for _,target in sgs.qlist(others) do
				if effect.from:canSlash(target, nil, false) then
					targets:append(target)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(effect.from, targets, "shuangren-slash")
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("heg_shuangren")
				slash:deleteLater()
				local card_use = sgs.CardUseStruct()
				card_use.card = slash
				card_use.from = effect.from
				card_use.to:append(target)
				room:useCard(card_use, false)
			end
		else
			room:setPlayerFlag(effect.from, "heg_shuangren")
		end
	end
}
heg_shuangrenVS = sgs.CreateZeroCardViewAsSkill{
	name = "heg_shuangren",
	response_pattern = "@@heg_shuangren",
	view_as = function(self) 
		return heg_shuangrenCard:clone()
	end, 
}
heg_shuangren = sgs.CreateTriggerSkill{
	name = "heg_shuangren",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = heg_shuangrenVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Play then
			local room = player:getRoom()
			local can_invoke = false
			local other_players = room:getOtherPlayers(player)
			for _,p in sgs.qlist(other_players) do
				if not player:isKongcheng() then
					can_invoke = true
					break
				end
			end
			if can_invoke and not player:isKongcheng() then
				room:askForUseCard(player, "@@heg_shuangren", "@shuangren-card", -1, sgs.Card_MethodPindian)
			end
			
		end
		return false
	end
}
heg_shuangrenProhibit = sgs.CreateProhibitSkill{
	name = "#heg_shuangrenProhibit",
	is_prohibited = function(self, from, to, card)
		return from:hasFlag("heg_shuangren") and from:objectName() ~= to:objectName()
	end
}
heg_jiling:addSkill(heg_shuangren)
heg_jiling:addSkill(heg_shuangrenProhibit)
extension_heg:insertRelatedSkills("heg_shuangren","#heg_shuangrenProhibit")

heg_panfeng = sgs.General(extension_heg, "heg_panfeng", "qun", 4)

heg_kuangfu = sgs.CreateTriggerSkill{
	name = "heg_kuangfu",
	events = {sgs.CardFinished, sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:hasFlag(self:objectName()) and not use.card:hasFlag("DamageDone") then
				room:askForDiscard(player, self:objectName(), 2, 2, false, false)
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
			if player:getMark("heg_kuangfu-PlayClear") > 0 then return false end
			for _, p in sgs.qlist(use.to) do
				if p:getEquips():length() > 0 then
					local dest = sgs.QVariant()
					dest:setValue(p)
                    if player:askForSkillInvoke(self:objectName(), dest) then
						local cardid = room:askForCardChosen(player, p, "e", self:objectName())
						room:obtainCard(player, cardid)
						room:setCardFlag(use.card, self:objectName())
						room:addPlayerMark(player, "heg_kuangfu-PlayClear")
						room:addPlayerMark(player, "&heg_kuangfu-PlayClear")
						break
					end
				end
			end
		end
	end
}
heg_panfeng:addSkill(heg_kuangfu)

heg_new_ganfuren = sgs.General(extension_heg, "heg_new_ganfuren", "shu", 3, false)

heg_shushen = sgs.CreateTriggerSkill{
	name = "heg_shushen" ,
	events = {sgs.HpRecover} ,
	on_trigger = function(self, event, player, data)
		local recover_struct = data:toRecover()
		local recover = recover_struct.recover
		local room = player:getRoom()
		for i = 0, recover - 1, 1 do
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "shushen-invoke", true, true)
			if target then
				if target:isKongcheng() then
					target:drawCards(2)
				else
					target:drawCards(1)
				end
			else
				break
			end
		end
		return false
	end
}

heg_new_ganfuren:addSkill(heg_shushen)
heg_new_ganfuren:addSkill("shenzhi")


heg_new_xusheng = sgs.General(extension_heg, "heg_new_xusheng", "wu", 4)

heg_yicheng = sgs.CreateTriggerSkill{
	name = "heg_yicheng",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") then return false end
		local d = sgs.QVariant()
		d:setValue(use.from)
		if room:askForSkillInvoke(player,self:objectName(),d) then
			use.from:drawCards(1)
			if use.from:isAlive() and use.from:canDiscard(use.from,"he") then
				room:askForDiscard(use.from,self:objectName(),1,1,false,true)
			end
		end
		for _,p in sgs.qlist(use.to) do
			local d = sgs.QVariant()
			d:setValue(p)
			if room:askForSkillInvoke(player,self:objectName(),d) then
				p:drawCards(1)
				if p:isAlive() and p:canDiscard(p,"he") then
					room:askForDiscard(p,self:objectName(),1,1,false,true)
				end
				if not player:isAlive() then
					break
				end
			end
		end
		return false
	end
}
heg_new_xusheng:addSkill(heg_yicheng)

heg_new_zangba = sgs.General(extension_heg, "heg_new_zangba", "wei", 4)

heg_hengjiang = sgs.CreateMasochismSkill{
	name = "heg_hengjiang",
	
	on_damaged = function(self,player,damage)
		local room = player:getRoom()
		for i = 1, damage.damage, 1 do 
			local current = room:getCurrent()
			if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then
		break 
	end		
			local value = sgs.QVariant()
				value:setValue(current)
			if current:getMaxCards() > 0 and room:askForSkillInvoke(player,self:objectName(),value) then
				room:addPlayerMark(current,"&heg_hengjiang-Clear",math.max(1, current:getEquips():length()))
				room:addPlayerMark(player, "heg_hengjiang-Clear")
			end
		end
	end

}
heg_hengjiangDraw = sgs.CreateTriggerSkill{
	name = "#heg_hengjiangDraw",
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseChanging},
	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and player:objectName() == move.from:objectName() and player:getPhase() == sgs.Player_Discard and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
				player:setFlags("heg_hengjiangDiscarded")
		end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			if player:getMark("&hengjiang-Clear") > 0 then
			local invoke = false
			if not player:hasFlag("heg_hengjiangDiscarded") then
				invoke = true
			end
				player:setFlags("-heg_hengjiangDiscarded")
				if invoke then
					for _, zangba in sgs.qlist(room:findPlayersBySkillName("heg_hengjiang")) do
						if zangba:getMark("heg_hengjiang-Clear") > 0 then
							room:setPlayerFlag(zangba, "-heg_hengjiang")
							local x = zangba:getMaxHp() - zangba:getHandcardNum()
							zangba:drawCards(x)	
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
heg_hengjiangMaxCards = sgs.CreateMaxCardsSkill{
	name = "#heg_hengjiangMaxCards",

	extra_func = function(self, target)
		return -target:getMark("&hengjiang-Clear")
	end
}
heg_new_zangba:addSkill(heg_hengjiang)
heg_new_zangba:addSkill(heg_hengjiangDraw)
heg_new_zangba:addSkill(heg_hengjiangMaxCards)
extension_heg:insertRelatedSkills("heg_hengjiang","#heg_hengjiangDraw")
extension_heg:insertRelatedSkills("heg_hengjiang","#heg_hengjiangMaxCards")

heg_new_luxun = sgs.General(extension_heg, "heg_new_luxun", "wu", 3)
heg_duoshi = sgs.CreateTriggerSkill{
	name = "heg_duoshi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			local card = sgs.Sanguosha:cloneCard("EXCard_YYDL", sgs.Card_NoSuit, 0)
			card:setSkillName(self:objectName())
			card:deleteLater()
			
			-- use.to:append(dest)
			local others = room:askForPlayersChosen(player, room:getAlivePlayers(), self:objectName(), 0, room:getAlivePlayers():length(), "@heg_duoshi:"..card:objectName(), true, true)
			if others and others:length() > 0 then
				local use = sgs.CardUseStruct()
				use.from = player
				use.card = card
				use.to = others
				room:useCard(use, false)
			end
			
		end
		return false
	end
}
heg_new_luxun:addSkill("nosqianxun")
heg_new_luxun:addSkill(heg_duoshi)


heg_new_caohong = sgs.General(extension_heg, "heg_new_caohong", "wei", 4)



heg_huyuanCard = sgs.CreateSkillCard{
	name = "heg_huyuan",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	
	filter = function(self, targets, to_select)
		if not #targets == 0 then return false end
		return true
	end,
	
	on_effect = function(self, effect)
		local caohong = effect.from
		local room = caohong:getRoom()
		local card = sgs.Sanguosha:getCard(self:getEffectiveId())
		if card:isKindOf("EquipCard") then
			local equip = card:getRealCard():toEquipCard()
			local index = equip:location()
			if effect.to:getEquip(index) == nil then
				room:moveCardTo(self, caohong, effect.to, sgs.Player_PlaceEquip,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, caohong:objectName(), "heg_huyuan", ""))
				local card = sgs.Sanguosha:getCard(self:getEffectiveId())
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAllPlayers()) do
					if caohong:canDiscard(p, "ej") then
						targets:append(p)
					end
				end
				if not targets:isEmpty() then
				local to_dismantle = room:askForPlayerChosen(caohong, targets, "heg_huyuan", "@huyuan-discard:" .. effect.to:objectName())
				local card_id = room:askForCardChosen(caohong, to_dismantle, "he", "heg_huyuan", false,sgs.Card_MethodDiscard)
					room:throwCard(sgs.Sanguosha:getCard(card_id), to_dismantle, caohong)
				end
			end
		else
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, caohong:objectName(), effect.to:objectName(), "heg_huyuan","")
			room:moveCardTo(self,effect.to,sgs.Player_PlaceHand,reason)
		end
	end
}
heg_huyuanVS = sgs.CreateOneCardViewAsSkill{
	name = "heg_huyuan",
	filter_pattern = ".",
	response_pattern = "@@heg_huyuan",
	view_as = function(self, card)
		local first = heg_huyuanCard:clone()
			first:addSubcard(card:getId())
			first:setSkillName(self:objectName())
		return first
	end,

}
heg_huyuan = sgs.CreatePhaseChangeSkill{
	name = "heg_huyuan",
	view_as_skill = heg_huyuanVS,
	on_phasechange = function(self,target)
		local room = target:getRoom()
		if target:getPhase() == sgs.Player_Finish and not target:isNude() then
			room:askForUseCard(target, "@@heg_huyuan", "@huyuan-equip", -1, sgs.Card_MethodNone)
		end
	end
}
heg_new_caohong:addSkill(heg_huyuan)
heg_new_caohong:addSkill("heyi")

heg_new_chenwudongxi = sgs.General(extension_heg, "heg_new_chenwudongxi", "wu", 4)

heg_duanxieCard = sgs.CreateSkillCard{
	name = "heg_duanxie",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	
	filter = function(self, targets, to_select, player)
		if #targets >= math.max(1, player:getLostHp()) then return false end
		return to_select:objectName() ~= player:objectName() and not to_select:isChained()
	end,
	
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:setPlayerChained(effect.to)
		if not effect.from:isChained() then 
			room:setPlayerChained(effect.from)
		end
	end
}
heg_duanxie = sgs.CreateZeroCardViewAsSkill{
	name = "heg_duanxie",
	view_as = function(self, cards)
		return heg_duanxieCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_duanxie")
	end
}


heg_new_chenwudongxi:addSkill(heg_duanxie)
heg_new_chenwudongxi:addSkill("fenming")

heg_nos_himiko = sgs.General(extension_heg, "heg_nos_himiko", "qun", 3, false)

heg_nos_guishuVS = sgs.CreateOneCardViewAsSkill {
	name = "heg_nos_guishu",
	filter_pattern = ".|spade",
	response_or_use = true,
	view_as = function(self, originalCard)
		local dummy  = sgs.Sanguosha:cloneCard("EXCard_YJJG", originalCard:getSuit(), originalCard:getNumber())
		if sgs.Self:getMark("heg_nos_guishu") == 1 then
			dummy = sgs.Sanguosha:cloneCard("EXCard_YJJG", sgs.Card_NoSuit, 0)
		elseif sgs.Self:getMark("heg_nos_guishu") == 2 then
			dummy = sgs.Sanguosha:cloneCard("EXCard_ZJZB", sgs.Card_NoSuit, 0)
		end
		dummy:addSubcard(originalCard:getId())
		dummy:setSkillName(self:objectName())
		return dummy
	end,
	enabled_at_play = function(self, player)
		return true
	end,
}

heg_nos_guishu = sgs.CreateTriggerSkill{
	name = "heg_nos_guishu",
	events = {sgs.PreCardUsed},
	view_as_skill = heg_nos_guishuVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and table.contains(use.card:getSkillNames(), "heg_nos_guishu") then
			if player:getMark("heg_nos_guishu") == 1 then
				room:setPlayerMark(player, "heg_nos_guishu", 2)
				room:changeTranslation(player, "heg_nos_guishu", 2)
			elseif player:getMark("heg_nos_guishu") == 2 then
				room:setPlayerMark(player, "heg_nos_guishu", 1)
				room:changeTranslation(player, "heg_nos_guishu", 1)
			else
				local choice = room:askForChoice(player, self:objectName(), "EXCard_YJJG+EXCard_ZJZB")
				if choice == "EXCard_YJJG" then
                    room:setPlayerMark(player, "heg_nos_guishu", 2)
					room:changeTranslation(player, "heg_nos_guishu", 2)
				else
					room:setPlayerMark(player, "heg_nos_guishu", 1)
					room:changeTranslation(player, "heg_nos_guishu", 1)
					local new_card = sgs.Sanguosha:cloneCard("EXCard_ZJZB")
					new_card:setSkillName(self:objectName())
					new_card:deleteLater()
					new_card:addSubcards(use.card:getSubcards())
					use.card = new_card	
					data:setValue(use)
				end
			end
		end
	end
}
heg_nos_yuanyu = sgs.CreateTriggerSkill{
    name = "heg_nos_yuanyu",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.from and not (damage.from:getNextAlive():objectName() == player:objectName() or damage.from:getNextAlive(room:alivePlayerCount() - 1):objectName() == player:objectName() ) then
            damage.prevented = true
			data:setValue(damage)
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			return true
        end
    end,
}
heg_nos_himiko:addSkill(heg_nos_guishu)
heg_nos_himiko:addSkill(heg_nos_yuanyu)


heg_ol_dianwei = sgs.General(extension, "heg_ol_dianwei", "wei", 5)
heg_ol_dianwei:addSkill("qiangxi")

heg_ol_huangzhong = sgs.General(extension, "heg_ol_huangzhong", "shu")

heg_ol_liegong = sgs.CreateTriggerSkill {
	name = "heg_ol_liegong",
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if (player:objectName() ~= use.from:objectName()) or (player:getPhase() ~= sgs.Player_Play) or (not use.card:isKindOf("Slash")) then return false end
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			local handcardnum = p:getHandcardNum()
			if (player:getHp() <= handcardnum) or (player:getAttackRange() >= handcardnum) then
				local _data = sgs.QVariant()
				_data:setValue(p)
				if player:askForSkillInvoke(self:objectName(), _data) then
					local log = sgs.LogMessage()
					log.type = "#skill_cant_jink"
					log.from = player
					log.to:append(p)
					log.arg = self:objectName()
					room:sendLog(log)
					jink_table[index] = 0
				end
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end
}
heg_ol_liegong_Target = sgs.CreateTargetModSkill {
	name = "#heg_ol_liegong_Target",
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("heg_ol_liegong") and card and not card:isVirtualCard() then
			return card:getNumber()
		end
	end,
}

heg_ol_huangzhong:addSkill(heg_ol_liegong)
heg_ol_huangzhong:addSkill(heg_ol_liegong_Target)
extension:insertRelatedSkills("heg_ol_liegong","#heg_ol_liegong_Target")

bf_lingtong = sgs.General(extension_hegbian, "bf_lingtong", "wu", 4, true)
bf_xuanlve = sgs.CreateTriggerSkill{
	name = "bf_xuanlve",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canDiscard(p, "he") then
					targets:append(p)
				end
			end
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "bf_xuanlve-invoke", true, true)
			if target then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:broadcastSkillInvoke(self:objectName())
					local id = room:askForCardChosen(player, target, "he", self:objectName(), false, sgs.Card_MethodDiscard)
					room:throwCard(id, target, player)
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		end
		return false
	end
}
bf_lingtong:addSkill(bf_xuanlve)
bf_yongjinCard = sgs.CreateSkillCard{
	name = "bf_yongjin",
	will_throw = false,
	filter = function(self, targets, to_select)
		if self:subcardsLength() == 0 or #targets == 1 then return false end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil and to_select:hasEquipArea(equip_index)
	end,
	feasible = function(self, targets)
--		if sgs.Self:hasFlag("bf_yongjin") then
		if sgs.Self:getMark(self:objectName().."engine") > 0 then
			return #targets == 1
		end
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		if source:hasFlag("bf_yongjin") then
			room:moveCardTo(self, source, targets[1], sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), self:objectName(), ""))
		else
			--room:doSuperLightbox("bf_lingtong", self:objectName())
			room:addPlayerMark(source, self:objectName().."engine")
			if source:getMark(self:objectName().."engine") > 0 then
				room:removePlayerMark(source, "@bf_yongjin")
				local ids = sgs.IntList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					for _, card in sgs.qlist(p:getCards("e")) do
					ids:append(card:getId())
					end
				end
				room:fillAG(ids)
				local t = 0
				for i = 1, 3 do
					local id = room:askForAG(source, ids, i ~= 1, self:objectName())
					if id == -1 then break end
					ids:removeOne(id)
					source:obtainCard(sgs.Sanguosha:getCard(id))
					room:takeAG(source, id, false)
					room:setCardFlag(sgs.Sanguosha:getCard(id), "bf_yongjin")
					t = i
					if ids:isEmpty() then break end
				end
				room:clearAG()
				room:setPlayerFlag(source, "bf_yongjin")
				for i = 1, t do
					room:askForUseCard(source, "@@bf_yongjin!", "@bf_yongjin")
				end
				room:setPlayerFlag(source, "-bf_yongjin")
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					for _, card in sgs.qlist(p:getCards("he")) do
						if card:hasFlag("bf_yongjin") then
							room:setCardFlag(card, "-bf_yongjin")
						end
					end
				end
				room:removePlayerMark(source, self:objectName().."engine")
			end
		end
	end
}
bf_yongjinVS = sgs.CreateViewAsSkill{
	name = "bf_yongjin",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:hasFlag("bf_yongjin")
	end,
	view_as = function(self, cards)
		local card = bf_yongjinCard:clone()
--		if sgs.Self:hasFlag("bf_yongjin") and cards[1] then
		if sgs.Self:getMark(self:objectName().."engine") > 0 and cards[1] then
			card:addSubcard(cards[1])
		end
		return card
	end,
	enabled_at_play = function(self, player)
		if player:getMark("@bf_yongjin") > 0 then
			for _, p in sgs.qlist(player:getAliveSiblings()) do
				if p:hasEquip() then
					return true
				end
			end
			return player:hasEquip()
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return string.startsWith(pattern, "@@bf_yongjin")
	end
}
bf_yongjin = sgs.CreateTriggerSkill{
	name = "bf_yongjin",
	frequency = sgs.Skill_Limited,
	view_as_skill = bf_yongjinVS,
	limit_mark = "@bf_yongjin",
	on_trigger = function()
	end
}
bf_lingtong:addSkill(bf_yongjin)
bf_lvfan = sgs.General(extension_hegbian, "bf_lvfan", "wu", 3, true)



bf_tiaodu = sgs.CreateTriggerSkill{
	name = "bf_tiaodu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()		
			if use.card:isKindOf("EquipCard")
			and (player:getMark("bf_tiaodu-Clear") == 0) then
				room:addPlayerMark(player,"bf_tiaodu-Clear",1)
				local dest = sgs.QVariant()
				dest:setValue(player)
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if room:askForSkillInvoke(p, self:objectName(), dest) then
						if room:askForSkillInvoke(player, self:objectName(), dest) then
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(1)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) then
				local list = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getEquips():length() > 0 then
						list:append(p)
					end
				end
				if list:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, list, self:objectName(), "bf_tiaodu-invoke", true, true)
				if not target then return false end
				local dest = sgs.QVariant()
				dest:setValue(player)
				if room:askForSkillInvoke(target, self:objectName(), dest) then
					local id = room:askForCardChosen(player, target, "e", self:objectName())
					local target2 = room:askForPlayerChosen(player, room:getOtherPlayers(target), self:objectName(), "bf_tiaodu-invoke", true, true)
					if not target2 then return false end
					room:obtainCard(target2, id)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

bf_lvfan:addSkill(bf_tiaodu)
bf_lvfan:addSkill("bf_diancai")


bf_nos_lvfan = sgs.General(extension_hegbian, "bf_nos_lvfan", "wu", 3, true)
bf_nos_tiaoduCard = sgs.CreateSkillCard{
	name = "bf_nos_tiaodu",
	filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:objectName() == sgs.Self:objectName()
		end
		return to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		room:addPlayerMark(effect.from, self:objectName().."engine")
		if effect.from:getMark(self:objectName().."engine") > 0 then
		local card = room:askForCard(effect.to, ".Equip", "@bf_nos_tiaodu", sgs.QVariant(), sgs.Card_MethodNone)
		if card then
			if room:getCardPlace(card:getId()) == sgs.Player_PlaceHand then
				room:useCard(sgs.CardUseStruct(card, effect.to, effect.to))
			else
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(effect.to)) do
					for i = 1, 5 do
						if p:getEquip(i) ~= card and not targets:contains(p) and p:hasEquipArea(i) then
							targets:append(p)
						end
					end
				end
				if not targets:isEmpty() then
					local target = room:askForPlayerChosen(effect.to, targets, self:objectName(), "bf_nos_tiaodu-invoke", true, true)
					if target then
						room:moveCardTo(card, target, sgs.Player_PlaceEquip)
					end
				end
			end
		end
			room:removePlayerMark(effect.from, self:objectName().."engine")
		end
	end
}
bf_nos_tiaodu = sgs.CreateZeroCardViewAsSkill{
	name = "bf_nos_tiaodu",
	view_as = function()
		return bf_nos_tiaoduCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#bf_nos_tiaodu")
	end
}
bf_nos_lvfan:addSkill(bf_nos_tiaodu)
bf_diancai = sgs.CreateTriggerSkill{
	name = "bf_diancai",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if (move.from and move.from:objectName() == p:objectName() and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))) and not (move.to and (move.to:objectName() == p:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
					room:addPlayerMark(p, self:objectName().."-Clear")
				end
			elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and player:objectName() ~= p:objectName() and p:getMark(self:objectName().."-Clear") >= p:getHp() and p:getMaxHp() > p:getHandcardNum() and room:askForSkillInvoke(p, self:objectName(), data) then
				room:addPlayerMark(p, self:objectName().."engine")
				if p:getMark(self:objectName().."engine") > 0 then
					p:drawCards(p:getMaxHp() - p:getHandcardNum(), self:objectName())
					if room:askForSkillInvoke(p, "ChangeGeneral", data) then
						room:broadcastSkillInvoke(self:objectName())
						ChangeGeneral(room, p, "bf_lvfan")
					end
					room:removePlayerMark(p, self:objectName().."engine")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
bf_nos_lvfan:addSkill(bf_diancai)

bf_sec_lvfan = sgs.General(extension_hegbian, "bf_sec_lvfan", "wu", 3, true)
bf_sec_tiaodu = sgs.CreateTriggerSkill{
	name = "bf_sec_tiaodu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()		
			if use.card:isKindOf("EquipCard") then
				local dest = sgs.QVariant()
				dest:setValue(player)
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if room:askForSkillInvoke(p, self:objectName(), dest) then
						if room:askForSkillInvoke(player, self:objectName(), dest) then
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(1)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) then
				local list = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getEquips():length() > 0 then
						list:append(p)
					end
				end
				if list:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, list, self:objectName(), "bf_tiaodu-invoke", true, true)
				if not target then return false end
				local dest = sgs.QVariant()
				dest:setValue(player)
				if room:askForSkillInvoke(target, self:objectName(), dest) then
					local id = room:askForCardChosen(player, target, "e", self:objectName())
					local target2 = room:askForPlayerChosen(player, room:getOtherPlayers(target), self:objectName(), "bf_tiaodu-invoke", true, true)
					if not target2 then return false end
					room:obtainCard(target2, id)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

bf_sec_lvfan:addSkill(bf_sec_tiaodu)
bf_sec_lvfan:addSkill("bf_diancai")

bf_third_lvfan = sgs.General(extension_hegbian, "bf_third_lvfan", "wu", 3, true)
bf_third_tiaodu = sgs.CreateTriggerSkill{
	name = "bf_third_tiaodu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()		
			if use.card:isKindOf("EquipCard") then
				local dest = sgs.QVariant()
				dest:setValue(player)
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if room:askForSkillInvoke(p, self:objectName(), dest) then
						if room:askForSkillInvoke(player, self:objectName(), dest) then
							room:broadcastSkillInvoke(self:objectName())
							player:drawCards(1)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) then
				local list = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getEquips():length() > 0 then
						list:append(p)
					end
				end
				if list:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, list, self:objectName(), "bf_tiaodu-invoke", true, true)
				if not target then return false end
				local dest = sgs.QVariant()
				dest:setValue(player)
				if room:askForSkillInvoke(target, self:objectName(), dest) then
					local id = room:askForCardChosen(player, target, "e", self:objectName())
					local target2 = room:askForPlayerChosen(player, room:getOtherPlayers(target), self:objectName(), "bf_tiaodu-invoke")
					room:obtainCard(target2, id)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
bf_third_lvfan:addSkill(bf_third_tiaodu)
bf_third_lvfan:addSkill("bf_diancai")

bf_xunyou = sgs.General(extension_hegbian, "bf_xunyou", "wei", 3, true)
bf_qiceCard = sgs.CreateSkillCard{
	name = "bf_qice",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local card = sgs.Self:getTag("bf_qice"):toCard()
		card:addSubcards(sgs.Self:getHandcards())
		card:setSkillName(self:objectName())
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		--return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(card, qtargets)
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
	end,
	feasible = function(self, targets)
		local card = sgs.Self:getTag("bf_qice"):toCard()
		card:addSubcards(sgs.Self:getHandcards())
		card:setSkillName(self:objectName())
		local qtargets = sgs.PlayerList()
		local n = #targets
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if n == 0 then
			if not sgs.Self:isProhibited(sgs.Self, card) and card:isKindOf("GlobalEffect") then n = 1 end
			for _, p in sgs.qlist(sgs.Self:getAliveSiblings()) do
				if not sgs.Self:isProhibited(p, card) and (card:isKindOf("AOE") or card:isKindOf("GlobalEffect")) then
					n = n + 1
				end
			end
		end
		if card and ((card:canRecast() and n == 0) or (n > sgs.Self:getHandcardNum())) then
			return false
		end
		return card and card:targetsFeasible(qtargets, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString())
		use_card:addSubcards(card_use.from:getHandcards())
		use_card:setSkillName(self:objectName())
		local available = true
		for _,p in sgs.qlist(card_use.to) do
			if card_use.from:isProhibited(p,use_card) then
				available = false
				break
			end
		end
		available = available and use_card:isAvailable(card_use.from)
		if not available then return nil end
		return use_card
	end
}
bf_qiceVS = sgs.CreateZeroCardViewAsSkill{
	name = "bf_qice",
	view_as = function(self)
		local c = sgs.Self:getTag("bf_qice"):toCard()
		if c then
			local card = bf_qiceCard:clone()
			card:setUserString(c:objectName())
			card:addSubcards(sgs.Self:getHandcards())
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#bf_qice") and not player:isKongcheng()
	end
}
bf_qice = sgs.CreateTriggerSkill{
	name = "bf_qice",
	view_as_skill = bf_qiceVS,
	global = true,
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if table.contains(use.card:getSkillNames(), "bf_qice") and use.card:getTypeId() ~= 0 and use.from then
			if room:askForSkillInvoke(use.from, "ChangeGeneral", data) then
				ChangeGeneral(room, use.from, "bf_xunyou")
			end
		end
	end
}
bf_qice:setGuhuoDialog("r")
bf_xunyou:addSkill(bf_qice)
bf_xunyou:addSkill("zhiyu")
bf_bianhuanghou = sgs.General(extension_hegbian, "bf_bianhuanghou", "wei", 3, false, false, false)
--[[bf_wanwei = sgs.CreateTriggerSkill{
	name = "bf_wanwei",
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISMANTLE and move.reason.m_playerId ~= move.reason.m_targetId then
			local i = 0
			local lirang_card = sgs.IntList()
			for _,id in sgs.qlist(move.card_ids) do
				if room:getCardOwner(id):objectName() == move.from:objectName() and (move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip) then
					lirang_card:append(id)
				end
				i = i + 1
			end
			if not lirang_card:isEmpty() then
				local card = room:askForExchange(player, self:objectName(), lirang_card:length(), lirang_card:length(), true, "bf_wanwei-invoke", true)
				if not card:getSubcards():isEmpty() then
					move:removeCardIds(move.card_ids)
					for _,id in sgs.qlist(card:getSubcards()) do
						move.card_ids:append(id)
						move.from_places:append(room:getCardPlace(id))
					end
					data:setValue(move)
				end
			end
		end
	end
}]]--
bf_wanwei = sgs.CreateTriggerSkill{
	name = "bf_wanwei",
	events = {sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data)
    local move = data:toMoveOneTime()
    local room = player:getRoom()
		--if move.from and move.from:objectName() == player:objectName() and ((move.to_place == sgs.Player_DiscardPile and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISMANTLE and move.reason.m_playerId ~= move.reason.m_targetId) or (move.to and move.to:isAlive() and move.from:objectName() ~= move.to:objectName() and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_GIVE and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_SWAP)) then
		if move.from and move.from:objectName() == player:objectName() and room:getCurrent():objectName() ~= player:objectName()
		and (
		(move.to_place == sgs.Player_DiscardPile and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISMANTLE
		and move.reason.m_playerId ~= move.reason.m_targetId)
		or
		(
		move.to and move.to:isAlive() and move.from:objectName() ~= move.to:objectName()
		and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE
		and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_GIVE
		and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_SWAP
		--and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_USE
		--and move.reason.m_reason ~= sgs.CardMoveReason_S_REASON_TRANSFER
		)
		) then
			local toReplace = sgs.IntList()
			local i = 0
			local ids = sgs.IntList()
			if move.card_ids:length() > 0 then
				for _, id in sgs.qlist(move.card_ids) do
					if room:getCardOwner(id):objectName() == move.from:objectName() and (move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip) then
						toReplace:append(id)
					end
					i = i + 1
				end
			end
      --if not toReplace:isEmpty() then
      if toReplace and not toReplace:isEmpty() then
          local card = room:askForExchange(player, self:objectName(), toReplace:length(), toReplace:length(), true, "bf_wanwei-invoke", true)
          if card and not card:getSubcards():isEmpty() then
              --move:removeCardIds(toReplace)
              --myetyet按：removeCardIds有毒，如果真的需要用请把源码Lua化
              room:notifySkillInvoked(player, self:objectName())
			  room:broadcastSkillInvoke(self:objectName())
			  for _, p in sgs.qlist(toReplace) do
                  local i = move.card_ids:indexOf(p)
                  if i >= 0 then
                      move.card_ids:removeAt(i)
                      move.from_places:removeAt(i)
                      --move.from_pile_names:removeAt(i)
                      --move.open:removeAt(i)
                      --myetyet按：以上两句有毒，请勿使用
                  end
              end
              for _, p in sgs.qlist(card:getSubcards()) do
                  move.card_ids:append(p)
                  move.from_places:append(room:getCardPlace(p))
              end
              data:setValue(move)
          end
      end
    end
    return false
	end
}
bf_bianhuanghou:addSkill(bf_wanwei)
bf_yuejian = sgs.CreatePhaseChangeSkill{
	name = "bf_yuejian",
	global = true,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			--if player:getPhase() == sgs.Player_Discard and player:getMark("qieting") == 0 and room:askForSkillInvoke(p, self:objectName()) then
			if player:getPhase() == sgs.Player_Discard and player:getMark("bf_yuejian_use_"..p:objectName().."-Clear") == 0 and room:askForSkillInvoke(p, self:objectName()) then
				room:addPlayerMark(p, self:objectName().."engine")
				if p:getMark(self:objectName().."engine") > 0 then
					room:broadcastSkillInvoke(self:objectName())
					player:setFlags("bf_yuejian_buff")
					room:removePlayerMark(p, self:objectName().."engine")
				end
			end
		end
	end
}
bf_yuejian_buff = sgs.CreateMaxCardsSkill{
	name = "#bf_yuejian",
	fixed_func = function(self, target)
		if target:hasFlag("bf_yuejian_buff") then
			return target:getMaxHp()
		end
		return -1
	end
}
bf_bianhuanghou:addSkill(bf_yuejian)
bf_bianhuanghou:addSkill(bf_yuejian_buff)
extension_hegbian:insertRelatedSkills("bf_yuejian", "#bf_yuejian")
bf_masu = sgs.General(extension_hegbian, "bf_masu", "shu", 3, true)
bf_masu:addSkill("sanyao")
bf_zhiman = sgs.CreateTriggerSkill{
	name = "bf_zhiman",
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		local damage = data:toDamage()
		local dest = sgs.QVariant()
		dest:setValue(damage.to)
		if room:askForSkillInvoke(player, self:objectName(), dest) then
			local log = sgs.LogMessage()
			log.from = player
			log.to:append(damage.to)
			log.arg = self:objectName()
			log.type = "#Yishi"
			room:sendLog(log)
			room:addPlayerMark(player, self:objectName().."engine")
			room:broadcastSkillInvoke(self:objectName())
			if player:getMark(self:objectName().."engine") > 0 then
				if damage.to:hasEquip() or damage.to:getJudgingArea():length() > 0 then
					local card = room:askForCardChosen(player, damage.to, "ej", self:objectName())
					room:obtainCard(player, card, false)
				end
				if room:askForSkillInvoke(damage.to, "ChangeGeneral", data) then
					ChangeGeneral(room, damage.to)
				end
				room:removePlayerMark(player, self:objectName().."engine")
				damage.prevented = true
				data:setValue(damage)
				return true
			end
		end
		return false
	end
}
bf_masu:addSkill(bf_zhiman)
bf_shamoke = sgs.General(extension_hegbian, "bf_shamoke", "shu", 4, true, true)
-- bf_jili = sgs.CreateTriggerSkill{
-- 	name = "bf_jili",
-- 	global = true,
-- 	frequency = sgs.Skill_Frequent,
-- 	events = {sgs.CardUsed, sgs.CardResponded},
-- 	on_trigger = function(self, event, player, data, room)
-- 		local card
-- 		if event == sgs.CardUsed then
-- 			card = data:toCardUse().card
-- 		else
-- 			card = data:toCardResponse().m_card
-- 		end
-- 		if card and not card:isKindOf("SkillCard") then
-- 			room:addPlayerMark(player, self:objectName().."-Clear")
-- 			if player:getMark(self:objectName().."-Clear") == player:getAttackRange() and RIGHT(self, player) and room:askForSkillInvoke(player, self:objectName(), data) then
-- 				room:broadcastSkillInvoke(self:objectName())
-- 				player:drawCards(player:getAttackRange(), self:objectName())
-- 			end
-- 		end
-- 	end
-- }
bf_shamoke:addSkill("jili")
bf_lijueguosi = sgs.General(extension_hegbian, "bf_lijueguosi", "qun", 4, true, true)
bf_xiongsuanCard = sgs.CreateSkillCard{
	name = "bf_xiongsuan",
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source, self:objectName().."engine")
		if source:getMark(self:objectName().."engine") > 0 then
			room:removePlayerMark(source, "@scary")
			room:damage(sgs.DamageStruct(self:objectName(), source, targets[1]))
			source:drawCards(3, self:objectName())
			local SkillList = {}
			for _,skill in sgs.qlist(targets[1]:getVisibleSkillList()) do
				if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and skill:getFrequency() == sgs.Skill_Limited then
					table.insert(SkillList, skill:objectName())
				end
			end
			if #SkillList > 0 then
				local choice = room:askForChoice(source, self:objectName(), table.concat(SkillList, "+"))
				ChoiceLog(source, choice)
				room:addPlayerMark(targets[1], self:objectName()..choice)
			end
			room:removePlayerMark(source, self:objectName().."engine")
		end
	end
}
bf_xiongsuanVS = sgs.CreateOneCardViewAsSkill{
	name = "bf_xiongsuan",
	filter_pattern = ".",
	view_as = function(self, card)
		local cards = bf_xiongsuanCard:clone()
		cards:addSubcard(card)
		return cards
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@scary") > 0
	end
}
bf_xiongsuan = sgs.CreatePhaseChangeSkill{
	name = "bf_xiongsuan",
	view_as_skill = bf_xiongsuanVS,
	frequency = sgs.Skill_Limited,
	limit_mark = "@scary",
	on_phasechange = function(self, player)
		local room = player:getRoom()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			for _,skill in sgs.qlist(p:getVisibleSkillList()) do
				if p:getMark(self:objectName()..skill:objectName()) > 0 and player:getPhase() == sgs.Player_Finish then
					room:handleAcquireDetachSkills(p, "-"..skill:objectName().."|"..skill:objectName())
				end
			end
		end
	end
}
bf_lijueguosi:addSkill(bf_xiongsuan)

bf_zuoci = sgs.General(extension_hegbian, "bf_zuoci", "qun", 3, true)
bf_yiguiCard = sgs.CreateSkillCard{
	name = "bf_yigui",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		local card = sgs.Self:getTag("bf_yigui"):toCard()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local user_str = self:getUserString()
			card = sgs.Sanguosha:cloneCard(user_str)
		end
		card:setSkillName(self:objectName())
		local kingdoms = {}
		local generals = sgs.Sanguosha:getLimitedGeneralNames()
		for _,name in pairs (generals) do
			if sgs.Self:getMark("bf_yigui"..name) > 0 and not table.contains(kingdoms, sgs.Sanguosha:getGeneral(name):getKingdom()) then
				table.insert(kingdoms, sgs.Sanguosha:getGeneral(name):getKingdom())
			end
		end
		if card and card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card and card:targetFilter(qtargets, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card) and table.contains(kingdoms, to_select:getKingdom())
	end,
	feasible = function(self,targets,user)
		local kingdoms = {}
		local generals = sgs.Sanguosha:getLimitedGeneralNames()
		for _,name in pairs (generals) do
			if sgs.Self:getMark("bf_yigui"..name) > 0 and not table.contains(kingdoms, sgs.Sanguosha:getGeneral(name):getKingdom()) then
				table.insert(kingdoms, sgs.Sanguosha:getGeneral(name):getKingdom())
			end
		end
		local plist = sgs.PlayerList()
		for i = 1,#targets do if table.contains(kingdoms, targets[i]:getKingdom()) then plist:append(targets[i]) end end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card,user_str = nil,self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetsFeasible(plist,user)
		end
		local card = user:getTag("bf_yigui"):toCard()
		return card and card:targetsFeasible(plist,user) 
	end,
	on_validate = function(self,card_use)
		local player = card_use.from
		local room,aocaistring = player:getRoom(),self:getUserString()
		local generals = sgs.Sanguosha:getLimitedGeneralNames()
		local huashenss = {}
		for _,name in pairs (generals) do
			if player:getMark("bf_yigui"..name) > 0 then
				table.removeOne(generals, name)
				table.insert(huashenss, name)
			end
		end
		if #huashenss == 0 then return nil end
		if #huashenss > 0 then
			table.insert(huashenss, "cancel")
		end
		local general = room:askForGeneral(player, table.concat(huashenss, "+"))
		if general == "cancel" then return false end
		room:setPlayerMark(player, "bf_yigui"..general, 0)
		table.removeOne(huashenss, general)
		local kingdom = sgs.Sanguosha:getGeneral(general):getKingdom()
		if self:getUserString() == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local bf_yigui_list = {}
			table.insert(bf_yigui_list,"slash")
			table.insert(bf_yigui_list,"fire_slash")
			table.insert(bf_yigui_list,"thunder_slash")
			table.insert(bf_yigui_list,"ice_slash")
			aocaistring = room:askForChoice(player,"bf_yigui_slash",table.concat(bf_yigui_list,"+"))
		end
		local user_str = aocaistring
		local use_card = sgs.Sanguosha:cloneCard(user_str)
		use_card:setSkillName("bf_yigui")
		use_card:deleteLater()
		room:setCardFlag(use_card, "bf_yiguiusing")
		room:setCardFlag(use_card, kingdom)
		local available = true
		for _,p in sgs.qlist(card_use.to) do
			if card_use.from:isProhibited(p,use_card) then
				available = false
				break
			end
		end
		available = available and use_card:isAvailable(card_use.from)
		if not available then return nil end
		room:addPlayerMark(player,"bf_yigui_guhuo_remove_"..use_card:objectName().."-Clear")
		return use_card
	end,
	on_validate_in_response = function(self,user)
		local room,user_str = user:getRoom(),self:getUserString()
		local generals = sgs.Sanguosha:getLimitedGeneralNames()
		local huashenss = {}
		for _,name in pairs (generals) do
			if user:getMark("bf_yigui"..name) > 0 then
				table.removeOne(generals, name)
				table.insert(huashenss, name)
			end
		end
		if #huashenss == 0 then return nil end
		if #huashenss > 0 then
			table.insert(huashenss, "cancel")
		end
		local general = room:askForGeneral(user, table.concat(huashenss, "+"))
		if general == "cancel" then return false end
		room:setPlayerMark(user, "bf_yigui"..general, 0)
		table.removeOne(huashenss, general)
		local kingdom = sgs.Sanguosha:getGeneral(general):getKingdom()
		local aocaistring
		if user_str == "peach+analeptic" then
			local bf_yigui_list = {}
			table.insert(bf_yigui_list,"peach")
			table.insert(bf_yigui_list,"analeptic")
			aocaistring = room:askForChoice(user,"bf_yigui_saveself",table.concat(bf_yigui_list,"+"))
		elseif user_str == "slash" then
			local bf_yigui_list = {}
			table.insert(bf_yigui_list,"slash")
			table.insert(bf_yigui_list,"fire_slash")
			table.insert(bf_yigui_list,"thunder_slash")
			table.insert(bf_yigui_list,"ice_slash")
			aocaistring = room:askForChoice(user,"bf_yigui_slash",table.concat(bf_yigui_list,"+"))
		else
			aocaistring = user_str
		end
		local user_str = aocaistring
		local use_card = sgs.Sanguosha:cloneCard(user_str)
		use_card:setSkillName("bf_yigui")
		use_card:deleteLater()
		room:setCardFlag(use_card, "bf_yiguiusing")
		room:setCardFlag(use_card, kingdom)
		room:addPlayerMark(user,"bf_yigui_guhuo_remove_"..use_card:objectName().."-Clear")
		return use_card
	end,
}
bf_yiguiVS = sgs.CreateZeroCardViewAsSkill{
	name = "bf_yigui",
	view_as = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
				local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
				local sc = sgs.Sanguosha:cloneCard(pattern:split("+")[1])
				local card = bf_yiguiCard:clone()
				card:setUserString(sc:objectName())
				return card
			end
		local c = sgs.Self:getTag("bf_yigui"):toCard()
		if c then
			local card = bf_yiguiCard:clone()
			card:setUserString(c:objectName())
			return card
		end
		return nil
	end,
	enabled_at_play = function(self,player)
		local generals = sgs.Sanguosha:getLimitedGeneralNames()
		local huashenss = {}
		for _,name in pairs (generals) do
			if player:getMark("bf_yigui"..name) > 0 then
				table.removeOne(generals, name)
				table.insert(huashenss, name)
			end
		end
		if #huashenss == 0 then return false end
		for _,patt in ipairs(patterns())do
			local dc = dummyCard(patt)
			if dc and player:getMark("bf_yigui_guhuo_remove_"..patt.."-Clear")<1 then
				dc:setSkillName(self:objectName())
				if dc:isAvailable(player)
				then return true end
			end
		end
	end,
	enabled_at_response = function(self,player,pattern)
		if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		
		local generals = sgs.Sanguosha:getLimitedGeneralNames()
		local huashenss = {}
		for _,name in pairs (generals) do
			if player:getMark("bf_yigui"..name) > 0 then
				table.removeOne(generals, name)
				table.insert(huashenss, name)
			end
		end
		if #huashenss == 0 then return false end
		for _,pt in sgs.list(pattern:split("+"))do
			local dc = dummyCard(pt)
			if dc:isKindOf("Nullification") then return false end
			if dc and player:getMark("bf_yigui_guhuo_remove_"..pt.."-Clear")<1 then
				return true
			end
		end
	end,
}
bf_yigui = sgs.CreateTriggerSkill{
	name = "bf_yigui",
	events = {sgs.GameStart},
	view_as_skill = bf_yiguiVS,
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		local generals = sgs.Sanguosha:getLimitedGeneralNames()
		for _,name in pairs (generals) do
			if player:getMark("bf_yigui"..name) > 0 then
				table.removeOne(generals, name)
			end
		end
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if table.contains(generals, p:getGeneralName()) then
				table.removeOne(generals, p:getGeneralName())
			end
			if table.contains(generals, p:getGeneral2Name()) then
				table.removeOne(generals, p:getGeneral2Name())
			end
		end
		if #generals > 0 then
			room:broadcastSkillInvoke(self:objectName())
			local general = generals[math.random(1, #generals)]
			ChoiceLog(player, general, player)
			room:addPlayerMark(player, "bf_yigui"..general)
			room:doAnimate(4, player:objectName(), general)
			table.removeOne(generals, general)
			local general2 = generals[math.random(1, #generals)]
			ChoiceLog(player, general2, player)
			room:addPlayerMark(player, "bf_yigui"..general2)
			room:doAnimate(4, player:objectName(), general2)
		end
		return false
	end
}
bf_yigui_prohibit = sgs.CreateProhibitSkill{
    name = "#bf_yigui_prohibit",
    is_prohibited = function(self, from, to, card)
		if from:hasSkill("bf_yigui") and card and table.contains(card:getSkillNames(), "bf_yigui") and to and card:hasFlag("bf_yiguiusing") then
        	return not card:hasFlag(to:getKingdom())
		end
    end,
}

bf_jihun = sgs.CreateTriggerSkill{
	name = "bf_jihun",
	events = {sgs.Damaged, sgs.QuitDying},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		if event == sgs.Damaged then
            local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
				local generals = sgs.Sanguosha:getLimitedGeneralNames()
				for _,name in pairs (generals) do
					if player:getMark("bf_yigui"..name) > 0 then
						table.removeOne(generals, name)
					end
				end
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if table.contains(generals, p:getGeneralName()) then
						table.removeOne(generals, p:getGeneralName())
					end
					if table.contains(generals, p:getGeneral2Name()) then
						table.removeOne(generals, p:getGeneral2Name())
					end
				end
				if #generals > 0  and room:askForSkillInvoke(player, self:objectName()) then
					room:broadcastSkillInvoke(self:objectName())
					local general = generals[math.random(1, #generals)]
					ChoiceLog(player, general, player)
					room:addPlayerMark(player, "bf_yigui"..general)
					room:doAnimate(4, player:objectName(), general)
				end
			end
		elseif event == sgs.QuitDying then
			local dying = data:toDying()
			if dying.who:isAlive() then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:objectName() ~= dying.who:objectName() and p:getKingdom() ~= dying.who:getKingdom() then
						local generals = sgs.Sanguosha:getLimitedGeneralNames()
						for _,name in pairs (generals) do
							if p:getMark("bf_yigui"..name) > 0 then
								table.removeOne(generals, name)
							end
						end
						for _,p in sgs.qlist(room:getAlivePlayers()) do
							if table.contains(generals, p:getGeneralName()) then
								table.removeOne(generals, p:getGeneralName())
							end
							if table.contains(generals, p:getGeneral2Name()) then
								table.removeOne(generals, p:getGeneral2Name())
							end
						end
						if #generals > 0  and room:askForSkillInvoke(p, self:objectName()) then
							room:broadcastSkillInvoke(self:objectName())
							local general = generals[math.random(1, #generals)]
							ChoiceLog(p, general, p)
							room:addPlayerMark(p, "bf_yigui"..general)
							room:doAnimate(4, p:objectName(), general)
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
bf_yigui:setGuhuoDialog("lr")
bf_zuoci:addSkill(bf_yigui)
bf_zuoci:addSkill(bf_yigui_prohibit)
bf_zuoci:addSkill(bf_jihun)

bf_nos_zuoci = sgs.General(extension_hegbian, "bf_nos_zuoci", "qun", 3, true)
cancel = sgs.General(extension_hegbian, "cancel", "qun", 3, true, true, true)
bf_nos_huashen = sgs.CreateTriggerSkill{
	name = "bf_nos_huashen",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart, sgs.MarkChanged},
	on_trigger = function(self, event, player, data, room)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			local generals = sgs.Sanguosha:getLimitedGeneralNames()
			local huashenss = {}
			for _,name in pairs (generals) do
				if player:getMark("bf_nos_huashen"..name) > 0 then
					table.removeOne(generals, name)
					table.insert(huashenss, name)
				end
			end
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if table.contains(generals, p:getGeneralName()) then
					table.removeOne(generals, p:getGeneralName())
				end
				if table.contains(generals, p:getGeneral2Name()) then
					table.removeOne(generals, p:getGeneral2Name())
				end
			end
			if player:getPhase() == sgs.Player_Start and #generals > 0 and room:askForSkillInvoke(player, self:objectName()) then
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:broadcastSkillInvoke(self:objectName())
					local SkillList = {}
					if #huashenss < 2 then
						local huashens = {}
						for i = 1, 5 do
							local name = generals[math.random(1, #generals)]
							table.insert(huashens, name)
							table.removeOne(generals, name)
						end
						for i = 1, 2 do
							huashenss = {}
							for _,name in pairs (generals) do
								if player:getMark("bf_nos_huashen"..name) > 0 then
									table.removeOne(generals, name)
									table.insert(huashenss, name)
								end
							end
							if #huashenss > 0 then
								table.insert(huashens, "cancel")
							end
							local general = room:askForGeneral(player, table.concat(huashens, "+"))
							if general == "cancel" then return false end
							room:addPlayerMark(player, "bf_nos_huashen"..general)
							table.removeOne(huashens, general)
							for _,skill in sgs.qlist(sgs.Sanguosha:getGeneral(general):getVisibleSkillList()) do
								if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited and skill:getFrequency() ~= sgs.Skill_Compulsory then
									table.insert(SkillList, skill:objectName())
								end
							end
						end
					else
						local name = generals[math.random(1, #generals)]
						local choice = room:askForGeneral(player, name.."+cancel")
						if choice ~= "cancel" then
							room:addPlayerMark(player, "bf_nos_huashen"..name)
							local general = room:askForGeneral(player, table.concat(huashenss, "+"))
							room:removePlayerMark(player, "bf_nos_huashen"..general)
							for _,skill in sgs.qlist(sgs.Sanguosha:getGeneral(general):getVisibleSkillList()) do
								if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited and skill:getFrequency() ~= sgs.Skill_Compulsory then
									table.insert(SkillList, "-"..skill:objectName())
								end
							end
							for _,skill in sgs.qlist(sgs.Sanguosha:getGeneral(name):getVisibleSkillList()) do
								if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited and skill:getFrequency() ~= sgs.Skill_Compulsory then
									table.insert(SkillList, skill:objectName())
								end
							end
						end
					end
					if #SkillList > 0 then
						room:handleAcquireDetachSkills(player, table.concat(SkillList,"|"))
					end
					room:removePlayerMark(player, self:objectName().."engine")
				end
			end
		else
			local mark = data:toMark()
			if string.find(mark.name, "engine") and mark.gain > 0 then
				for _, m in sgs.list(player:getMarkNames()) do
					if player:getMark(m) > 0 and string.find(m, "bf_nos_huashen") then
						local SkillList = {}
						if sgs.Sanguosha:getGeneral(string.sub(m, 11, string.len(m))) then
							for _,skill in sgs.qlist(sgs.Sanguosha:getGeneral(string.sub(m, 11, string.len(m))):getVisibleSkillList()) do
								if skill:objectName().."engine" == mark.name or skill:objectName().."Cardengine" == mark.name or skill:objectName().."cardengine" == mark.name or "#"..skill:objectName().."engine" == mark.name or string.upper(string.sub(skill:objectName(), 1, 1))..string.sub(skill:objectName(), 2, string.len(skill:objectName())).."engine" == mark.name  then
									room:removePlayerMark(player, "bf_nos_huashen"..string.sub(m, 11, string.len(m)))
									for _,s in sgs.qlist(sgs.Sanguosha:getGeneral(string.sub(m, 11, string.len(m))):getVisibleSkillList()) do
										if not s:inherits("SPConvertSkill") and not s:isAttachedLordSkill() and not s:isLordSkill() and s:getFrequency() ~= sgs.Skill_Wake and s:getFrequency() ~= sgs.Skill_Limited and s:getFrequency() ~= sgs.Skill_Compulsory then
											table.insert(SkillList, "-"..s:objectName())
										end
									end
								end
							end
						end
						room:handleAcquireDetachSkills(player, table.concat(SkillList,"|"))
					end
				end
			end
		end
		return false
	end
}
bf_nos_zuoci:addSkill(bf_nos_huashen)
bf_nos_xinsheng = sgs.CreateMasochismSkill{
	name = "bf_nos_xinsheng",
	frequency = sgs.Skill_Frequent,
	on_damaged = function(self, player, damage)
		local room = player:getRoom()
		local generals = sgs.Sanguosha:getLimitedGeneralNames()
		for _,name in pairs (generals) do
			if player:getMark("bf_nos_huashen"..name) > 0 then
				table.removeOne(generals, name)
			end
		end
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if table.contains(generals, p:getGeneralName()) then
				table.removeOne(generals, p:getGeneralName())
			end
			if table.contains(generals, p:getGeneral2Name()) then
				table.removeOne(generals, p:getGeneral2Name())
			end
		end
		if #generals > 0 and room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			room:addPlayerMark(player, self:objectName().."engine")
			if player:getMark(self:objectName().."engine") > 0 then
				local general = generals[math.random(1, #generals)]
				ChoiceLog(player, general, player)
				room:addPlayerMark(player, "bf_nos_huashen"..general)
				local SkillList = {}
				for _,skill in sgs.qlist(sgs.Sanguosha:getGeneral(general):getVisibleSkillList()) do
					if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and not skill:isLordSkill() and skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited and skill:getFrequency() ~= sgs.Skill_Compulsory then
						table.insert(SkillList, skill:objectName())
					end
				end
				room:handleAcquireDetachSkills(player, table.concat(SkillList,"|"))
				room:removePlayerMark(player, self:objectName().."engine")
			end
		end
		return false
	end
}
bf_nos_zuoci:addSkill(bf_nos_xinsheng)


twyj_caohong = sgs.General(extension_twyj, "twyj_caohong", "wei", 4, true)
twyj_huzhuCard = sgs.CreateSkillCard{
	name = "twyj_huzhu",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		local card = room:askForCard(targets[1], ".|.|.|hand!", "@twyj_huzhu:" .. source:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
		if card then
			room:moveCardTo(card, source, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, targets[1]:objectName(), source:objectName(), self:objectName(), ""))
			local ids = sgs.IntList()
			for _, e in sgs.qlist(source:getCards("e")) do
				ids:append(e:getEffectiveId())
			end
			if ids:length() > 0 then
				room:fillAG(ids)
				local card_id = room:askForAG(targets[1], ids, false, self:objectName())
				if card_id ~= -1 then
					room:obtainCard(targets[1], card_id, true)
				end
				room:clearAG()
				local _data = sgs.QVariant()
				_data:setValue(targets[1])
				if targets[1]:getHp() <= source:getHp() and targets[1]:isWounded() and room:askForSkillInvoke(source, self:objectName(), _data) then
					room:recover(targets[1], sgs.RecoverStruct(targets[1]))
				end
			end
		end
	end
}
twyj_huzhu = sgs.CreateZeroCardViewAsSkill{
	name = "twyj_huzhu",
	view_as = function(self, cards)
		return twyj_huzhuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#twyj_huzhu") and not player:getEquips():isEmpty()
	end
}
twyj_caohong:addSkill(twyj_huzhu)
twyj_liancai = sgs.CreateTriggerSkill{
	name = "twyj_liancai",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.TurnOver},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName(), data) then
			player:turnOver()
			local ids = sgs.IntList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				for _, e in sgs.qlist(p:getCards("e")) do
					ids:append(e:getEffectiveId())
				end
			end
			if ids:length() > 0 then
				room:fillAG(ids)
				local card_id = room:askForAG(player, ids, false, self:objectName())
				if card_id ~= -1 then
					room:obtainCard(player, card_id, true)
				end
				room:clearAG()
			end
		elseif event == sgs.TurnOver then
			if player:hasSkill(self:objectName()) and player:getHp() - player:getHandcardNum() > 0 and room:askForSkillInvoke(player, "twyj_liancai_turnover", data) then
				room:broadcastSkillInvoke(self:objectName())
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:notifySkillInvoked(player, self:objectName())
				player:drawCards(player:getHp() - player:getHandcardNum(), self:objectName())
			end
		end
		return false
	end
}
twyj_caohong:addSkill(twyj_liancai)
twyj_dingfeng = sgs.General(extension_twyj, "twyj_dingfeng", "wu", 4, true)
twyj_qijiaCard = sgs.CreateSkillCard{
	name = "twyj_qijia",
	will_throw = true,
	filter = function(self, targets, to_select)
		local rangefix = 0
		if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
		end
		if not self:getSubcards():isEmpty() and sgs.Self:getOffensiveHorse() and sgs.Self:getOffensiveHorse():getId() == self:getSubcards():first() then
			rangefix = rangefix + 1
		end
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and sgs.Self:inMyAttackRange(to_select) and sgs.Self:canSlash(to_select, true, rangefix)
	end,
	about_to_use = function(self, room, use)
		local id = self:getSubcards():first()
		local card = sgs.Sanguosha:getCard(id)
		local equip_index = card:getRealCard():toEquipCard():location()
		room:setPlayerMark(use.from, self:objectName().."_"..equip_index.."-Clear", 1)
		room:throwCard(id, use.from, use.from)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
		slash:setSkillName(self:objectName())
		room:useCard(sgs.CardUseStruct(slash, use.from, use.to))
	end
}
twyj_qijia = sgs.CreateOneCardViewAsSkill{
	name = "twyj_qijia",
	view_filter = function(self, card)
		if card:isEquipped() then
			local equip_index = card:getRealCard():toEquipCard():location()
			return card:isEquipped() and not sgs.Self:isJilei(card) and sgs.Self:canDiscard(sgs.Self, "e") and sgs.Self:getMark(self:objectName().."_"..equip_index.."-Clear") == 0
		end
		return false
	end,
	view_as = function(self, card)
		local skillcard = twyj_qijiaCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return true
	end
}
twyj_dingfeng:addSkill(twyj_qijia)
twyj_zhuchenCard = sgs.CreateSkillCard{
	name = "twyj_zhuchen",
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(targets[1], "twyj_zhuchen_dis_fix")
	end
}
twyj_zhuchen = sgs.CreateOneCardViewAsSkill{
	name = "twyj_zhuchen",
	view_filter = function(self, card)
		return card:isKindOf("Peach") or card:isKindOf("Analeptic")
	end,
	view_as = function(self, card)
		local skillcard = twyj_zhuchenCard:clone()
		skillcard:addSubcard(card)
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return true
	end
}
twyj_dingfeng:addSkill(twyj_zhuchen)
twyj_maliang = sgs.General(extension_twyj, "twyj_maliang", "shu", 3, true)
twyj_rangyiUseCard = sgs.CreateSkillCard{
	name = "twyj_rangyiUse",
	filter = function(self, targets, to_select)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		return card and not card:targetFixed() and card:targetFilter(targets_list, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card)
	end, 
	feasible = function(self, targets)
		local targets_list = sgs.PlayerList()
		for _, target in ipairs(targets) do
			targets_list:append(target)
		end
		local card = sgs.Sanguosha:getCard(self:getSubcards():first())
		return card and card:targetsFeasible(targets_list, sgs.Self)
	end,
	about_to_use = function(self, room, use)
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		for _, card in sgs.list(use.from:getHandcards()) do
			if card:hasFlag("twyj_rangyi") and card:getEffectiveId() ~= self:getSubcards():first() then
				dummy:addSubcard(card:getEffectiveId())
			end
		end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("twyj_rangyi_source") > 0 then
				room:obtainCard(p, dummy, false)
				break
			end
		end
		local card_for_use = sgs.Sanguosha:getCard(self:getSubcards():first())
		local targets_list = sgs.SPlayerList()
		for _, p in sgs.qlist(use.to) do
			if not use.from:isProhibited(p, card_for_use) then
				targets_list:append(p)
			end
		end
		room:useCard(sgs.CardUseStruct(card_for_use, use.from, targets_list))
	end
}
twyj_rangyiCard = sgs.CreateSkillCard{
	name = "twyj_rangyi",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "twyj_rangyi_source", 1)
		local ids = sgs.IntList()
		for _, card in sgs.list(source:getHandcards()) do
			ids:append(card:getEffectiveId())
		end
		for _, id in sgs.qlist(ids) do
			room:setCardFlag(sgs.Sanguosha:getCard(id), self:objectName())
		end
		room:obtainCard(targets[1], source:wholeHandCards(), sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), targets[1]:objectName(), self:objectName(), ""), false)
		if not room:askForUseCard(targets[1], "@@twyj_rangyi", "@twyj_rangyi") then
			room:damage(sgs.DamageStruct(self:objectName(), source, targets[1], 1))
		end
		for _, id in sgs.qlist(ids) do
			room:setCardFlag(sgs.Sanguosha:getCard(id), "-"..self:objectName())
		end
		room:setPlayerMark(source, "twyj_rangyi_source", 0)
	end
}
twyj_rangyi = sgs.CreateViewAsSkill{
	n = 1,
	name = "twyj_rangyi",
	response_pattern = "@@twyj_rangyi",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@twyj_rangyi" then
			return to_select:hasFlag(self:objectName()) and to_select:isAvailable(sgs.Self)
		end
		return false
	end,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@twyj_rangyi" then
			if #cards ~= 1 then return nil end
			local skillcard = twyj_rangyiUseCard:clone()
			skillcard:addSubcard(cards[1])
			return skillcard
		end
		if #cards ~= 0 then return nil end
		return twyj_rangyiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng() and not player:hasUsed("#twyj_rangyi")
	end
}
twyj_maliang:addSkill(twyj_rangyi)
twyj_baimei = sgs.CreateTriggerSkill{
	name = "twyj_baimei",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data, room)
		if player:isKongcheng() then
			local damage = data:toDamage()
			if (damage.nature ~= sgs.DamageStruct_Normal or (damage.card and damage.card:isKindOf("TrickCard"))) and damage.to and damage.to:objectName() == player:objectName() then
				local msg = sgs.LogMessage()
				msg.type = "#twyj_baimei_Protect"
				msg.from = player
				msg.arg = damage.damage
				if damage.nature == sgs.DamageStruct_Fire then
					msg.arg2 = "fire_nature"
				elseif damage.nature == sgs.DamageStruct_Thunder then
					msg.arg2 = "thunder_nature"
				elseif damage.nature == sgs.DamageStruct_Normal then
					msg.arg2 = "normal_nature"
				end
				room:sendLog(msg)
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, self:objectName().."engine")
				if player:getMark(self:objectName().."engine") > 0 then
					room:removePlayerMark(player, self:objectName().."engine")
					damage.prevented = true
					data:setValue(damage)
					return true
				end
			end
		end
	end
}
twyj_maliang:addSkill(twyj_baimei)

sunjian_po = sgs.General(extension, "sunjian_po", "wu")
yinghun_po = sgs.CreatePhaseChangeSkill{
	name = "yinghun_po", 
	on_phasechange = function(self, player)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:isWounded() then
			local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "yinghun-invoke", true, true)
			local x = player:getLostHp()
			if player:getEquips():length() >= player:getHp() then
				x = player:getMaxHp()
			end
			local choices = {"yinghun1"}
			if to then
				if not to:isNude() and x ~= 1 then
					table.insert(choices, "yinghun2")
				end
                room:setPlayerFlag(player, "yinghun_poTarget")
				local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                room:setPlayerFlag(player, "-yinghun_poTarget")
				ChoiceLog(player, choice)
				if choice == "yinghun1" then
					to:drawCards(1)
					room:askForDiscard(to, self:objectName(), x, x, false, true)
				else
					to:drawCards(x)
					room:askForDiscard(to, self:objectName(), 1, 1, false, true)
				end
				room:broadcastSkillInvoke(self:objectName())
			end
		end
		return false
	end
}
sunjian_po:addSkill(yinghun_po)



sijyuoffline_zhaoyun = sgs.General(extension, "sijyuoffline_zhaoyun", "shu", 3, true)

sijyuoffline_zhaoyun:addSkill("longdan")
sijyuoffline_zhaoyun:addSkill("chongzhen")


-- 军令

--- 对某角色发起军令（抽取、选择、询问）
---@param from ServerPlayer @ 军令发起者
---@param to ServerPlayer @ 军令执行者
---@param skill_name string @ 技能名
---@param forced? boolean @ 是否强制执行
---@return boolean @ 是否执行
function askCommandTo(from, to, skill_name, forced)
	if from:isDead() or to:isDead() then return false end
	local room = from:getRoom()
	local log = sgs.LogMessage()
	log.type = "#AskCommandTo"
	log.from = from
	log.to = sgs.SPlayerList()
	log.to:append(to)
	log.arg = skill_name
	room:sendLog(log)

	local index = startCommand(from, skill_name)
	local invoke = doCommand(to, skill_name, index, from, forced)
	return invoke
end

--- 军令发起者抽取并选择军令
---@param from ServerPlayer @ 军令发起者
---@param skill_name? string @ 技能名
---@param num? integer @ 抽取数量
---@return integer @ 选择的军令序号
function startCommand(from, skill_name, num)
	local allCommands = {"command1", "command2", "command3", "command4", "command5", "command6"}
	num = num or 2
	local commands = {}
	local indices = {}
	for i = 1, #allCommands do
		table.insert(indices, i)
	end
	for i = 1, num do
		local idx = math.random(1, #indices)
		table.insert(commands, allCommands[indices[idx]])
		table.remove(indices, idx)
	end

	local room = from:getRoom()
	local choice = room:askForChoice(from, "start_command", table.concat(commands, "+"))

	local log = sgs.LogMessage()
	log.type = "#CommandChoice"
	log.from = from
	log.arg = ":" .. choice
	room:sendLog(log)

	for i = 1, #allCommands do
		if allCommands[i] == choice then
		return i
		end
	end
	return 1
end

--- 询问军令执行者是否执行军令（执行效果也在这里）
---@param to ServerPlayer @ 军令执行者
---@param skill_name string @ 技能名
---@param index integer @ 军令序数
---@param from ServerPlayer @ 军令发起者
---@param forced? boolean @ 是否强制执行
---@return boolean @ 是否执行
function doCommand(to, skill_name, index, from, forced)
	if to:isDead() or from:isDead() then return false end
	local room = to:getRoom()

	local allCommands = {"command1", "command2", "command3", "command4", "command5", "command6"}
	local choices = forced and allCommands[index] or (allCommands[index] .. "+cancel")

	local choice = room:askForChoice(to, "do_command", choices)

	local result = choice == "cancel" and "#commandselect_no" or "#commandselect_yes"
	local log = sgs.LogMessage()
	log.type = "#CommandChoice"
	log.from = to
	log.arg = result
	room:sendLog(log)

	local commandData = "AfterCommandUse:"..from:objectName() .. ":" .. to:objectName() .. ":" .. skill_name .. ":" .. tostring(index) .. ":" .. choice
	if choice == "cancel" then
		room:getThread():trigger(sgs.EventForDiy, room, to, sgs.QVariant(commandData))
		return false
	end
	local ChooseDoCommandData = "ChooseDoCommand:"..from:objectName() .. ":" .. to:objectName() .. ":" .. skill_name .. ":" .. tostring(index) .. ":" .. choice
	if room:getThread():trigger(sgs.EventForDiy, room, to, sgs.QVariant(ChooseDoCommandData)) then
		room:getThread():trigger(sgs.EventForDiy, room, to, sgs.QVariant(commandData))
		return true
	end

  	if index == 1 then
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			targets:append(p)
		end
		local dest = room:askForPlayerChosen(from, targets, skill_name, "#command1-damage:" .. to:objectName(), false, false)
		local log2 = sgs.LogMessage()
		log2.type = "#Command1Damage"
		log2.from = from
		log2.to = sgs.SPlayerList()
		log2.to:append(dest)
		room:sendLog(log2)
		room:doAnimate(1, from:objectName(), dest:objectName())
		local damage = sgs.DamageStruct()
		damage.from = to
		damage.to = dest
		damage.damage = 1
		damage.reason = "command"
		room:damage(damage)
  	elseif index == 2 then
		to:drawCards(1, "command")
		if to:objectName() == from:objectName() or to:isNude() then return true end
		local card_count = to:getHandcardNum() + to:getEquips():length()
		if card_count == 1 then
			local cards = to:getCards("he")
			local dummy = dummyCard()
			for _, card in sgs.qlist(cards) do
				dummy:addSubcard(card)
			end
			room:obtainCard(from, dummy, false)
			dummy:deleteLater()
		else
			local min_num = math.min(2, card_count)
			local cards = room:askForExchange(to, "command", min_num, min_num, true,"#command2-give:" .. from:objectName(), false)
			if cards then
				local dummy = dummyCard()
				local count = 0
				for _, card in sgs.qlist(cards) do
					if count < min_num then
						dummy:addSubcard(card)
						count = count + 1
					end
				end
				room:obtainCard(from, dummy, false)
				dummy:deleteLater()
			end
		end
  	elseif index == 3 then
    	room:loseHp(to, 1, true, to, "command")
  	elseif index == 4 then
		room:setPlayerMark(to, "@skill_invalidity", 1)
		room:setPlayerMark(to, "command4_invalidity", 1)
		room:setPlayerMark(to, "&command4_effect-Clear", 1)
		room:setPlayerCardLimitation(to, "use,response", ".|.|.|hand", true)
  	elseif index == 5 then
		to:turnOver()
		room:setPlayerMark(to, "command5_recover-Clear", 1)
		room:setPlayerMark(to, "&command5_effect-Clear", 1)
  	elseif index == 6 then
		local hand_count = to:getHandcardNum()
		local equip_count = to:getEquips():length()
		if hand_count < 2 and equip_count < 2 then return true end
		if equip_count > 1 and hand_count > 1 then
			room:askForCard(to, "@@command6!", "#command6-select")
		elseif equip_count > 1 then
			room:askForDiscard(to, "command", equip_count-1, equip_count-1, false, true, "#command6-select", ".|.|.|equipped",  "command")
		else
			room:askForDiscard(to, "command", hand_count-1, hand_count-1, false, false, "#command6-select", "",  "command")
		end
  	end
	room:getThread():trigger(sgs.EventForDiy, room, to, sgs.QVariant(commandData))
  	return true
end

command_skill = sgs.CreateTriggerSkill{
	name = "command",
	events = {sgs.HpRecover, sgs.EventPhaseChanging},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.HpRecover then
			local recover = data:toRecover()
			if player:getMark("command5_recover-Clear") > 0 then
				return true
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("command4_invalidity") > 0 then
						room:removePlayerMark(p, "command4_invalidity")
						room:removePlayerMark(p, "@skill_invalidity")
					end
				end
			end
		end
		return false
	end
}
command_discard = sgs.CreateViewAsSkill{
	name = "command6",
	n = 999,
	response_pattern = "@@command6!",
	view_filter = function(self, selected, to_select)
		local hand_count = sgs.Self:getHandcardNum()
		local equip_count = sgs.Self:getEquips():length()
		if #selected > 0 then
			local hand_discard = 0
			local equip_discard = 0
			local card
			for i = 1, #selected, 1 do
				card = selected[i]
				if sgs.Self:getHandcards():contains(card) then
					hand_discard = hand_discard + 1
				else
					equip_discard = equip_discard + 1
				end
			end
			if hand_discard < hand_count - 1 then
				return sgs.Self:getHandcards():contains(to_select)
			elseif equip_discard < equip_count - 1 then
				return sgs.Self:getEquips():contains(to_select)
			else
				return false
			end
		end
		if equip_count > 1 and hand_count > 1 then
			return true
		elseif equip_count > 1 then
			return to_select:isEquipped()
		else
			return sgs.Self:getHandcards():contains(to_select)
		end
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local skillcard = DummyCard():clone()
		for _, card in ipairs(cards) do
			skillcard:addSubcard(card)
		end
		local hand_count = sgs.Self:getHandcardNum()
		local equip_count = sgs.Self:getEquips():length()
		local hand_discard = 0
		local equip_discard = 0
		local card
		for i = 1, #selected, 1 do
			card = cards[i]
			if sgs.Self:getHandcards():contains(card) then
				hand_discard = hand_discard + 1
			else
				equip_discard = equip_discard + 1
			end
		end
		if equip_discard == equip_count - 1 and hand_discard == hand_count - 1 then
			return skillcard
		end
		return nil
	end
}
if not sgs.Sanguosha:getSkill("command") then skills:append(command_skill) end
if not sgs.Sanguosha:getSkill("command6") then skills:append(command_discard) end


heg_yujin = sgs.General(extension_hegquan, "heg_yujin", "wei", 4)

heg_jueyue = sgs.CreateTriggerSkill{
	name = "heg_jueyue",
	events = {sgs.EventPhaseProceeding, sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseProceeding then
			if player:getPhase() == sgs.Player_Start then
				local card = room:askForCard(player, "..", "@heg_jueyue-give", sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "heg_jueyue-invoke", false, true)
					room:obtainCard(to, card, false)
					room:broadcastSkillInvoke(self:objectName())
					local invoked = askCommandTo(player, to, self:objectName())
					if invoked then
						player:drawCards(1, self:objectName())
					else
						room:addPlayerMark(player, self:objectName().."-Clear")
					end
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if player:getMark(self:objectName().."-Clear") > 0 then
				draw.num = draw.num + 3
				data:setValue(draw)
				room:removePlayerMark(player, self:objectName().."-Clear")
			end
		end
	end
}

heg_yujin:addSkill(heg_jueyue)

--[[
	技能名：虎翼
	技能描述：你使用【杀】对目标造成属性伤害时，你可以横置至多两名角色。
	引用：sfofl_yice

	
    ["sijyuoffline_huyi"] = "虎翼",
    [":sijyuoffline_huyi"] = "装备牌·武器\
	攻击范围：3\
	攻击效果：你使用【杀】对目标造成属性伤害时，你可以横置至多两名角色。",
    ["@sijyuoffline_huyi"] = "虎翼：你可以横置至多两名角色",

    --徐荣礼盒
]] --
--[[sijyuoffline_huyi_skill = sgs.CreateTriggerSkill{
    name = "sijyuoffline_huyi", --一般的话，技能的objectName()和武器的objectName(）用一样的名字
    frequency = sgs.Skill_Compulsory,
    events = { sgs.DamageCaused },
    can_trigger = function(self, target)
        return target and target:hasWeapon(self:objectName())
    end,
    on_trigger = function(self, event, player, data)
        local damage = data:toDamage()
        local room = player:getRoom()
        if damage.card and damage.card:isKindOf("Slash") and damage.card:isKindOf("NatureSlash") and not damage.transfer and not damage.chain then
            if damage.from:objectName() == player:objectName() then
                local others = room:askForPlayersChosen(player, room:getAlivePlayers(), self:objectName(), 0, 2, "@sijyuoffline_huyi", true, true)
                if others and others:length() > 0 then
                    for _,enemy in sgs.qlist(others) do
                        if not enemy:isChained() then
                        room:setPlayerChained(enemy)
                        end
                    end
                end
            end
        end
        return false
    end
}
sijyuoffline_huyi = sgs.CreateWeapon{
    name = "sijyuoffline_huyi",
    class_name = "Huyi",
    suit = sgs.Card_Spade,
    number = 11,
    range = 3,
    equip_skill = sijyuoffline_huyi_skill,
    on_install = function(self, player)
        local room = player:getRoom()
        local skill = sgs.Sanguosha:getSkill(self:objectName())
        if skill then
            if skill:inherits("ViewAsSkill") then
                room:attachSkillToPlayer(player, self:objectName())
            elseif skill:inherits("TriggerSkill") then
                local tirggerskill = sgs.Sanguosha:getTriggerSkill(self:objectName())
                room:getThread():addTriggerSkill(tirggerskill)
            end
        end
        end,
    on_uninstall = function(self, player) --卸下时移除技能
        local room = player:getRoom()
        local skill = sgs.Sanguosha:getSkill(self:objectName())
        if skill and skill:inherits("ViewAsSkill") then
            room:detachSkillFromPlayer(player, self:objectName(), true)
        end
    end,
}
sijyuoffline_huyi:setParent(extension_2card)
]]


sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
    ["fixandadd_guandu"] = "官渡之战",
    ["new_heg"] = "新国战",
    ["heg_bian"] = "君临天下-变",
    ["heg_quan"] = "君临天下·权",
    ["heg_lordex"] = "君临天下·EX/不臣篇",
    ["fixandadd_twyj"] = "台湾一将成名",

    ["guandu_xuyou"] = "许攸[官渡]",
    ["&guandu_xuyou"] = "许攸",
    ["#guandu_xuyou"] = "恃才傲物",
    ["guandu_shicai"] = "识才",
    ["&talent"] = "识才",
    [":guandu_shicai"] = "牌堆顶的牌于你的出牌阶段内对你可见；出牌阶段，你可以弃置一张牌并获得牌堆顶的牌，若你的手牌中有此阶段内以此法获得的牌，你不能发动此技能。",
    ["$guandu_shicai1"] = "遣轻骑以袭许都，大事可成。",
    ["$guandu_shicai2"] = "主公不听吾之言，实乃障目不见泰山也！",
    ["chenggong"] = "逞功",
    [":chenggong"] = "当一名角色使用牌指定目标后，若目标数不少于2，你可以令其摸一张牌。",
    ["chenggong:to_draw"] = "你可以发动“逞功”，令 %src 摸一张牌",
    ["$chenggong1"] = "吾与主公，患难之交也。",
    ["$chenggong2"] = "我豫州人才济济，元皓之辈不堪大用",
    ["gd_zezhu"] = "择主",
    [":gd_zezhu"] = "出牌阶段限一次，你可以选择一至两名其他角色（若你不为主公，则其中必须有主公）。你依次获得他们各一张牌（若目标角色没有牌，则改为你摸一张牌），然后分别将一张牌交给他们。",
    ["@gd_zezhu-give"] = "请将一张牌交给 %src",
    ["~guandu_xuyou"] = "我军之所以败，皆因尔等指挥不当！",

	["guandu_zangba"] = "臧霸[官渡]",
    ["&guandu_zangba"] = "臧霸",
	["guandu_hengjiang"] = "横江",
	[":guandu_hengjiang"] = "当你受到1点伤害后，你可以令当前回合角色本回合的手牌上限-1。然后若其弃牌阶段内没有弃牌，则你摸X张牌。X为你本回合发动横江的次数。",

	["guandu_zhanghe"] = "张郃[官渡]",
    ["&guandu_zhanghe"] = "张郃",
    ["#guandu_zhanghe"] = "名门的梁柱",
	["~guandu_zhanghe"] = "袁公不听吾之言，乃至今日。",
	["guandu_yuanlue"] = "远略",
	[":guandu_yuanlue"] = "出牌阶段限一次，你可以将一张非装备牌交给一名角色，然后该角色可以使用该牌并令你摸一张牌。",
	["$guandu_yuanlue1"] = "若不引兵救乌巢，则主公危矣！",
	["$guandu_yuanlue2"] = "此番攻之不破，吾属尽成俘虏。",
	
	["guandu_xinping"] = "辛评[官渡]",
    ["&guandu_xinping"] = "辛评",
    ["#guandu_xinping"] = "全忠折节",
	["~guandu_xinping"] = "老臣，尽力了……",

	["guandu_fuyuan"] = "辅袁",
	[":guandu_fuyuan"] = "当你在回合外使用或打出牌时，若当前回合的角色手牌数少于你的手牌数，你可令其摸1张牌；若当前回合的角色手牌数大于等于你，你可以摸1张牌。",

	["guandu_zhongjie"] = "忠节",
	[":guandu_zhongjie"] = "当你死亡时，你可以令一名其他角色增加1点体力上限，回复1点体力，并摸一张牌。",

	["$guandu_fuyuan1"] = "袁门一体，休戚与共。",
	["$guandu_fuyuan2"] = "袁氏荣光，俯仰唯卿。",
	["$guandu_zhongjie1"] = "义士有忠节，可杀不可量！",
	["$guandu_zhongjie2"] = "愿以骨血为饲，事汝君临天下。",
	["$newyongdi3"] = "袁门当兴，兴在明公！",
	["$newyongdi4"] = "主公之位，非君莫属。",

	["guandu_hanmeng"] = "韩猛[官渡]",
    ["&guandu_hanmeng"] = "韩猛",
    ["#guandu_hanmeng"] = "锥锋不虞",
	["~guandu_hanmeng"] = "曹操狡诈，防不胜防……",

	["guandu_jieliang"] = "截粮",
	[":guandu_jieliang"] = "其他角色的摸牌阶段开始时，你可以弃置一张牌，令其本回合的摸牌阶段摸牌数-1，本回合手牌上限-1。若如此做，若其本回合的弃牌阶段结束时有弃牌，你可以从其弃置的牌中选择一张获得。",
	["guandu_quanjiu"] = "劝酒",
	[":guandu_quanjiu"] = "锁定技，你的【酗酒】均视为【杀】，你使用【酗酒】转化的【杀】不计入【杀】的使用次数。",

	["$guandu_jieliang1"] = "伏兵起，粮道绝！",
	["$guandu_jieliang2"] = "粮草根本，截之破敌！",
	["$guandu_quanjiu1"] = "大敌当前，怎可松懈畅饮？",
	["$guandu_quanjiu2"] = "乌巢重地，不宜饮酒！",

	["guandu_chunyuqiong"] = "淳于琼[官渡]",
    ["&guandu_chunyuqiong"] = "淳于琼",
    ["#guandu_chunyuqiong"] = "昔袍今臣",
	["~guandu_chunyuqiong"] = "子远老贼，吾死当追汝之魂！",

	["guandu_cangchu"] = "仓储",
	[":guandu_cangchu"] = "锁定技，游戏开始时，你获得3枚「粮」；当你受到1点火焰伤害后，你弃1枚「粮」。",
	-- ["guandu_sushou"] = "宿守",
	-- [":guandu_sushou"] = "弃牌阶段开始时，你可以摸X+1张牌（X为「粮」数），然后可以交给任意名友方角色各一张牌。",
	["guandu_sushou"] = "宿守",
	[":guandu_sushou"] = "锁定技，若你有「粮」，友方角色摸牌阶段摸牌数+1；当你失去所有「粮」后，你减1点体力上限，然后令敌方角色各摸两张牌。",
	-- ["guandu_liangying"] = "粮营",
	-- [":guandu_liangying"] = "锁定技，若你有「粮」，友方角色摸牌阶段摸牌数+1；当你失去所有「粮」后，你减1点体力上限，然后令敌方角色各摸两张牌。",
	["$guandu_cangchu1"] = "敌袭！速度整军，坚守营寨！",
	["$guandu_cangchu2"] = "袁公所托，琼，必当死守！",
	["$liangying3"] = "吾军之所守，为重中之重，尔等、切莫懈怠！",
	["$liangying4"] = "今夜，需再加强巡逻，不要出了差池。",


	["guandu"] = "官渡",
	["$guanduLightbox1"] = "欢迎进入 <<官渡>>",
	["$guanduJISHA"] = "%from %arg了 %to ，获得 %arg2",
	["guandu_jisha"] = "击杀",
	["guandu_jiangli"] = "击杀奖励",
	["$guandu_sj"] = "本局 %arg2 为 %arg",
	["guandu_sj"] = "随机事件",
	["$guandu_event"] = "%arg 效果触发：%arg2",
	["gd_liangcaokuifa"] = "粮草匮乏",
	[":gd_liangcaokuifa"] = "本局游戏中，所有角色摸牌阶段摸牌数-1。所有角色使用牌造成伤害后，其摸一张牌（每张牌限一次）。",
	["gd_xutuhuanjin"] = "徐图缓进",
	[":gd_xutuhuanjin"] = "本局游戏中，若本回合的出牌阶段，你未使用或打出过【杀】，则你下回合的摸牌阶段摸牌数+1。",
	["gd_yiruoshengqiang"] = "以弱胜强",
	[":gd_yiruoshengqiang"] = "造成伤害时，若受伤角色体力值大于伤害来源，此伤害+1。",
	["gd_shicongerjiao"] = "恃宠而骄",
	[":gd_shicongerjiao"] = "你的结束阶段，若你的体力值为全场唯一最多，你弃一张牌；若你的手牌数为全场最多，你失去1点体力。",
	["gd_huoshaowuchao"] = "火烧乌巢",
	[":gd_huoshaowuchao"] = "本局游戏中，所有无属性伤害均视为火属性伤害。",
	["gd_liangjunxiangchi"] = "两军相持",
	[":gd_liangjunxiangchi"] = "本局游戏中，游戏轮数小于等于4时，所有角色每轮手牌上限+1（比如第3轮则手牌上限+3）；轮数大于4时，你于自己的回合内首次使用【杀】造成的伤害+1。",
	["gd_jianshou"] = "坚守待战",
	[":gd_jianshou"] = "你可以将一张【杀】当【闪】使用或打出；每轮限一次，你如此做后，你的下个弃牌阶段手牌上限-1。",
	["gd_jianshoudaizhan"] = "坚守待战",
	[":gd_jianshoudaizhan"] = "你可以将一张【杀】当【闪】使用或打出；每轮限一次，你如此做后，你的下个弃牌阶段手牌上限-1。",
	["gd_shishengshibai"] = "十胜十败",
	[":gd_shishengshibai"] = "本局游戏中，使用的第整十张牌，若其不是装备牌、延时性锦囊，且之前选择的目标依然符合条件，则在前一次结算完毕后再结算一次。",
	["gd_zhanyanliangzhuwenchou"] = "斩颜良诛文丑",
	[":gd_zhanyanliangzhuwenchou"] = "本局游戏中，所有角色回合开始时，需要选择一名其他角色，视为对其进行决斗，否则失去一点体力。",
	["@gd_zhanyanliangzhuwenchou"] = "斩颜良诛文丑：<b>你可以视为对一名其他角色进行决斗，否则失去一点体力",
	--沒有語音
	--[[十胜十败：今绍有十败，公有十胜！(郭嘉)
	粮草匮乏：休要瞒我，军中已无粮！(许攸)
	火烧乌巢：嗯？何故喧嚣？火！火啊！(淳于琼)
	斩颜良诛文丑：吾观颜良，乃插标卖首尔！(魏关羽)]]

	-- 戮力同心（替换【南蛮入侵】）

	-- 出牌阶段，对己方所有角色或敌方所有角色使用，令己方所有被横置角色各摸一张牌或横置敌方所有角色。重铸：你可以将此牌置入弃牌堆，然后摸一张牌。 
	["gd_yuanjun"] = "援军",
	[":gd_yuanjun"] = "锦囊牌·多目标锦囊<br/><b>时机</b>：出牌阶段，对至多两名已受伤的其他角色使用。<br/><b>效果</b>：每名目标角色各回复1点体力。",

	["gd_tunliang"] = "屯粮",
	[":gd_tunliang"] = "锦囊牌·多目标锦囊<br/><b>时机</b>：出牌阶段，对至多三名角色使用。<br/><b>效果</b>：每名目标角色各摸一张牌。",

	["gd_xujiu"] = "酗酒",
	[":gd_xujiu"] = "【酗酒】 基本牌\
	时机：出牌阶段限一次，对一名角色使用\
	效果：。目标角色本回合内受到的伤害+1（每回合同一目标限一次）。 ",

    ["heg_ol_sunce"] = "孙策-国",
	["illustrator:heg_ol_sunce"] = "",
	["ol_hunshang"] = "魂殇",
	[":ol_hunshang"] = "锁定技，准备阶段开始时，若你的体力值不大于1，你于此回合内拥有“英魂”和“英姿”。",
	["~heg_ol_sunce"] = "",

    ["#heg_lvmeng"] = "士别三日",
	["heg_lvmeng"] = "吕蒙-国",
	["&heg_lvmeng"] = "吕蒙",
	["illustrator:heg_lvmeng"] = "樱花闪乱",
	["heg_keji"] = "克己",
	[":heg_keji"] = "锁定技，若你未于出牌阶段内使用过颜色不同的牌，则你本回合的手牌上限+4。",
	["$heg_keji1"] = "不是不报，时候未到！",
	["$heg_keji2"] = "留得青山在，不怕没柴烧！",
	["heg_mouduan"] = "谋断",
	[":heg_mouduan"] = "结束阶段，若你于出牌阶段内使用过四种花色或三种类别的牌，则你可以移动场上的一张牌。",
	["@heg_mouduan"] = "你可以移动场上的一张牌",
	["~heg_mouduan"] = "选择一名角色→点击确定",
	["@heg_mouduan-to"] = "请选择移动此卡牌的目标角色",
	["$heg_mouduan1"] = "当断不断，必守其乱。",
	["$heg_mouduan2"] = "识谋善断，国士之风。",
	["~heg_lvmeng"] = "被看穿了吗？",

	["heg_zhangfei"] = "张飞-国",
    ["&heg_zhangfei"] = "张飞",
	["#heg_zhangfei"] = "万夫不当",
	["~heg_zhangfei"] = "实在是杀不动了……",
	["heg_paoxiao"] = "咆哮",
	[":heg_paoxiao"] = "锁定技，你于出牌阶段内使用【杀】无次数限制；当你于当前回合内使用第二张【杀】时，摸一张牌。",
    ["$heg_paoxiao1"] = "呃啊！",
    ["$heg_paoxiao2"] = "燕人张飞在此！！！",

    ["heg_new_zhugeliang"] = "诸葛亮-国",
    ["&heg_new_zhugeliang"] = "诸葛亮",
	["#heg_new_zhugeliang"] = "迟暮的丞相",
	["~heg_new_zhugeliang"] = "将星陨落，天命难违……",
    ["heg_guanxing"] = "观星",
    [":heg_guanxing"] = "准备阶段，你可以观看牌堆顶的X张牌（X为存活角色数且至多为5），然后将其中任意数量的牌置于牌堆顶，将其余的牌置于牌堆底。",
    ["heg_kongcheng"] = "空城",
    [":heg_kongcheng"] = "锁定技，当你成为【杀】或【决斗】的目标时，若你没有手牌，取消之。当其他角色于你的回合外交给你牌时，若你没有手牌，你改为将之正面朝上置于你的武将牌上，摸牌阶段开始时，你获得武将牌上的牌。",
    ["$heg_guanxing1"] = "观今夜天象，知天下大事。",
    ["$heg_guanxing2"] = "知天易，逆天难。",
    ["$heg_kongcheng1"] = "（抚琴声）",
    ["$heg_kongcheng2"] = "（抚琴声）",

    ["heg_zhaoyun"] = "赵云-国",
    ["&heg_zhaoyun"] = "赵云",
	["#heg_zhaoyun"] = "少年将军",
	["~heg_zhaoyun"] = "这，就是失败的滋味吗？",
    ["heg_longdan"] = "龙胆",
    ["heg_longdan_recover"] = "龙胆",
    [":heg_longdan"] = "你可以将【杀】当【闪】、【闪】当【杀】使用或打出。当你通过发动“龙胆”使用的【杀】被一名角色使用的【闪】抵消时，你可以对另一名角色造成1点伤害。当一名角色使用的【杀】被你通过发动“龙胆”使用的【闪】抵消时，你可以令另一名其他角色回复1点体力。",
    ["heg_longdan-invoke"] = "你可以发动“龙胆”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["$heg_longdan1"] = "吾乃常山赵子龙也！",
    ["$heg_longdan2"] = "能进能退，乃真正法器！",

    ["heg_caoren"] = "曹仁-国",
    ["&heg_caoren"] = "曹仁",
	["#heg_caoren"] = "大将军",
	["~heg_caoren"] = "",
	["heg_jushou"] = "据守",
    [":heg_jushou"] = "结束阶段，你可摸X张牌（X为势力数）然后弃置一张手牌，若以此法弃置的是装备牌，则改为使用之。若X大于2，你翻面。 ",

    ["heg_xuhuang"] = "徐晃-国",
    ["&heg_xuhuang"] = "徐晃",
	["#heg_xuhuang"] = "周亚夫之风",
	["~heg_xuhuang"] = "",
	["heg_duanliang"] = "断粮",
    [":heg_duanliang"] = "出牌阶段，你可将一张黑色基本牌或装备牌当做【兵粮寸断】无视距离使用。你对距离大于2的角色使用【兵粮寸断】后，“断粮”失效直到回合结束。",

    ["heg_huanggai"] = "黄盖-国",
    ["&heg_huanggai"] = "黄盖",
	["#heg_huanggai"] = "轻身为国",
	["~heg_huanggai"] = "",
	["heg_kurou"] = "苦肉",
    [":heg_kurou"] = "出牌阶段限一次，你可弃置一张牌。若如此做，你失去1点体力，然后摸三张牌，此阶段你使用【杀】的次数上限+1。",

    ["heg_zoushi"] = "邹氏-国",
    ["&heg_zoushi"] = "邹氏",
	["#heg_zoushi"] = "惑心之魅",
	["illustrator:heg_zoushi"] = "Tuu.",
	["~heg_zoushi"] = "",
	["heg_qingcheng"] = "倾城",
    [":heg_qingcheng"] = "出牌阶段，你可以弃置一张黑色牌，令一名其他角色的一项武将技能无效，然后若你以此法弃置的牌是装备牌，则你可以选择另一名其他角色的一项武将技能无效，直到其回合开始时。",
	["heg_qingcheng-invoke"] = "你可以发动“倾城”<br/> <b>操作提示</b>: 选择另一名角色→点击确定<br/>",
	["heg_huoshui"] = "祸水",
    [":heg_huoshui"] = "锁定技，你的回合内，体力值不少于体力上限一半的其他角色所有武将技能无效且不能使用或打出【闪】响应你使用的牌。",

	["heg_xiahouyuan"] = "夏侯渊-国",
    ["&heg_xiahouyuan"] = "夏侯渊",
	["#heg_xiahouyuan"] = "虎步关右",
	["illustrator:heg_xiahouyuan"] = "凡果",
	["~heg_xiahouyuan"] = "",
	["heg_shensu"] = "神速",
    [":heg_shensu"] = "你可以执行以下一至三项：1.跳过判定阶段和摸牌阶段；2.跳过出牌阶段并弃置一张装备区；3.跳过弃牌阶段并失去1点体力。你执行一项后，便视为使用一张无距离限制的【杀】。",

	["heg_xuchu"] = "许褚-国",
    ["&heg_xuchu"] = "许褚",
	["#heg_xuchu"] = "虎痴",
	-- ["illustrator:heg_xuchu"] = "凡果",
	["~heg_xuchu"] = "",
	["heg_luoyi"] = "裸衣",
	[":heg_luoyi"] = "摸牌阶段结束时，你可以弃置一张牌，本回合你使用【杀】或【决斗】造成的伤害+1。",
	
	["heg_dianwei"] = "典韦-国",
    ["&heg_dianwei"] = "典韦",
	["#heg_dianwei"] = "古之恶来",
	["illustrator:heg_dianwei"] = "凡果",
	["~heg_dianwei"] = "",
	["heg_qiangxi"] = "强袭",
	[":heg_qiangxi"] = "出牌阶段限一次，你可以失去1点体力或弃置一张武器牌，对一名其他角色造成1点伤害。",

	["heg_guanyu"] = "关羽-国",
    ["&heg_guanyu"] = "关羽",
	["#heg_guanyu"] = "威震华夏",
	["illustrator:heg_guanyu"] = "凡果",
	["~heg_guanyu"] = "",

	["heg_huangzhong"] = "黄忠-国",
    ["&heg_huangzhong"] = "黄忠",
	["#heg_huangzhong"] = "老当益壮",
	["illustrator:heg_huangzhong"] = "凡果",
	["~heg_huangzhong"] = "",
	["heg_liegong"] = "烈弓",
	[":heg_liegong"] = "你对手牌数不大于你的角色使用【杀】无距离限制；当你使用【杀】指定一名角色为目标后，若其体力值不小于你，你可以令其不能响应此【杀】或令此【杀】对其造成的伤害+1。",
	["heg_liegong_cantjink"] = "令其不能响应此【杀】",
	["heg_liegong_addDamage"] = "令此【杀】对其造成的伤害+1",

	["heg_sunjian"] = "孙坚-国",
    ["&heg_sunjian"] = "孙坚",
	["#heg_sunjian"] = "魂佑江东",
	["illustrator:heg_sunjian"] = "凡果",
	["~heg_sunjian"] = "",
	["heg_yinghun-invoke"] = "你可以发动“英魂”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["heg_yinghun"] = "英魂",
	[":heg_yinghun"] = "准备阶段，你可以令一名其他角色执行以下一项：1.摸X张牌，弃置一张牌；2.摸一张牌，弃置X张牌。（X为你已损失体力值）",

	["heg_sunshangxiang"] = "孙尚香-国",
    ["&heg_sunshangxiang"] = "孙尚香",
	["#heg_sunshangxiang"] = "弓腰姬",
	["illustrator:heg_sunshangxiang"] = "凡果",
	["~heg_sunshangxiang"] = "",
	["heg_xiaoji"] = "枭姬",
	[":heg_xiaoji"] = "当你失去装备区里的牌后，若此时为你的回合外，你可以摸三张牌。否则你可以摸一张牌。 ",

	["heg_new_xiaoqiao"] = "小乔-国",
    ["&heg_new_xiaoqiao"] = "小乔",
	["#heg_new_xiaoqiao"] = "矫情之花",
	-- ["illustrator:heg_new_xiaoqiao"] = "凡果",
	["~heg_new_xiaoqiao"] = "",
	["heg_tianxiang"] = "天香",
	[":heg_tianxiang"] = "每回合每项限一次，当你受到伤害时，你可以弃置一张红桃手牌防止此伤害并选择一名其他角色，你选择一项：1.令其受到同来源的1点伤害后摸X张牌（X为其已损失体力值且至多为5）；2.令其失去1点体力后获得你弃置的牌。",
	["@heg_tianxiang"] = "请选择“天香”的目标",
	["~heg_tianxiang"] = "选择一张<font color=\"red\">♥</font>手牌→选择一名其他角色→点击确定",
	["heg_tianxiang1"] = "其摸X张牌",
	["heg_tianxiang2"] = "其失去1点体力，获得你以此法弃置的牌。",
	["heg_hongyan"] = "红颜",
	[":heg_hongyan"] = "锁定技，你的♤牌和♤判定牌花色均视为红桃；若你的装备区里有红桃牌，你的手牌上限+1。",

	["heg_lubu"] = "吕布-国",
    ["&heg_lubu"] = "吕布",
	["#heg_lubu"] = "戟指中原",
	["illustrator:heg_lubu"] = "凡果",
	["~heg_lubu"] = "",
	["heg_wushuang"] = "无双",
	[":heg_wushuang"] = "锁定技，你使用的【杀】需依次使用两张【闪】才能抵消；与你进行【决斗】的角色每次需依次打出两张【杀】；你使用非转化的【决斗】可以多选择至多两个目标。",

	["heg_jiling"] = "纪灵-国",
    ["&heg_jiling"] = "纪灵",
	["#heg_jiling"] = "仲家的主将",
	-- ["illustrator:heg_jiling"] = "凡果",
	["~heg_jiling"] = "",
	["heg_shuangren"] = "双刃",
	[":heg_shuangren"] = "出牌阶段开始时，你可以与一名其他角色拼点。若你：赢，你视为对与一名其他角色使用一张不计入次数的【杀】；没赢，本回合你不能对其他角色使用牌。",
	
	["heg_panfeng"] = "潘凤-国",
    ["&heg_panfeng"] = "潘凤",
	["#heg_panfeng"] = "联军上将",
	["illustrator:heg_panfeng"] = "凡果",
	["~heg_panfeng"] = "",
	["heg_kuangfu"] = "狂斧",
	[":heg_kuangfu"] = "出牌阶段限一次，你使用【杀】指定一名角色为目标后，可以获得其装备区里的一张牌。若此【杀】未造成伤害，你弃置两张手牌。",

	
	["heg_new_ganfuren"] = "甘夫人-国",
    ["&heg_new_ganfuren"] = "甘夫人",
	["#heg_new_ganfuren"] = "昭烈皇后",
	-- ["illustrator:heg_new_ganfuren"] = "凡果",
	["~heg_new_ganfuren"] = "",
	["heg_shushen"] = "淑慎",
	[":heg_shushen"] = "当你回复1点体力后，你可以令一名其他角色摸一张牌。若其没有手牌，改为摸两张牌。 ",

	["heg_new_xusheng"] = "徐盛-国",
    ["&heg_new_xusheng"] = "徐盛",
	["#heg_new_xusheng"] = "江东的铁壁",
	["illustrator:heg_new_xusheng"] = "天信",
	["~heg_new_xusheng"] = "",
	["heg_yicheng"] = "疑城",
	[":heg_yicheng"] = "当一名角色使用【杀】指定目标后或成为【杀】的目标后，你可以令其摸一张牌并弃置一张牌。 ",

	["heg_new_zangba"] = "臧霸-国",
    ["&heg_new_zangba"] = "臧霸",
	["#heg_new_zangba"] = "节度青徐",
	["illustrator:heg_new_zangba"] = "HOOO",
	["~heg_new_zangba"] = "",
	["heg_hengjiang"] = "横江",
	[":heg_hengjiang"] = "当你受到1点伤害后若当前回合角色手牌上限大于0，你可以令其本回合手牌上限-X（X为其装备区里的牌数且至少为1）。则此回合结束时，若其未于本回合弃牌阶段弃置过其牌，你将手牌摸至体力上限。",

	["heg_new_luxun"] = "陆逊-国",
    ["&heg_new_luxun"] = "陆逊",
	["#heg_new_luxun"] = "擎天之柱",
	["~heg_new_luxun"] = "",
	["heg_duoshi"] = "度势",
	[":heg_duoshi"] = "出牌阶段开始时，你可以视为使用一张【以逸待劳】。",
	["@heg_duoshi"] = "度势：请选择【以逸待劳】的目标",

	["heg_new_caohong"] = "曹洪-国",
    ["&heg_new_caohong"] = "曹洪",
	["#heg_new_caohong"] = "魏之福将",
	["~heg_new_caohong"] = "",
	["heg_huyuan"] = "护援",
	[":heg_huyuan"] = "结束阶段，你可以选择一名其他角色并选择一项：1.将一张非装备牌交给其；2.将一张装备牌置入其装备区，你可以弃置场上一张牌。",
	
	["heg_new_chenwudongxi"] = "陈武董袭-国",
    ["&heg_new_chenwudongxi"] = "陈武董袭",
	["#heg_new_chenwudongxi"] = "壮怀激烈",
	["~heg_new_chenwudongxi"] = "",
	["heg_duanxie"] = "断绁",
	[":heg_duanxie"] = "出牌阶段限一次，你可以横置至多X名其他角色，你横置。（X为你已损失体力值且至少为1）",
	
	["heg_nos_himiko"] = "卑弥呼-国[旧]",
    ["&heg_nos_himiko"] = "卑弥呼",
	["#heg_nos_himiko"] = " 邪马台的女王",
	["~heg_nos_himiko"] = "",
	["heg_nos_guishu"] = "鬼术",
	[":heg_nos_guishu"] = "出牌阶段，你可以将一张黑桃手牌当【远交近攻】或【知己知彼】使用（不得与你以此法使用的上一张牌相同）。",
	[":heg_nos_guishu1"] = "出牌阶段，你可以将一张黑桃手牌当【远交近攻】<s>或【知己知彼】</s>使用（不得与你以此法使用的上一张牌相同）。",
	[":heg_nos_guishu2"] = "出牌阶段，你可以将一张黑桃手牌当<s>【远交近攻】或</s>【知己知彼】使用（不得与你以此法使用的上一张牌相同）。",
	["heg_nos_yuanyu"] = "远域",
	[":heg_nos_yuanyu"] = "锁定技，当你受到伤害时，若伤害来源不为你的上家或下家，防止此伤害。",
	
	
	

    ["bf_xunyou"] = "荀攸-国",
	["#bf_xunyou"] = "曹魏的谋主",--编一个
	["illustrator:bf_xunyou"] = "心中一凛",
	["bf_qice"] = "奇策",
	[":bf_qice"] = "出牌阶段限一次，你可以将所有手牌当目标数不大于X的非延时类锦囊牌使用(X为你的手牌数)，若如此做，你可以变更武将牌。",
	["$bf_qice1"] = "倾力为国，算无遗策。",
	["$bf_qice2"] = "奇策在此，谁与争锋。",
	["~bf_xunyou"] = "主公，臣下先行告退。",

	["bf_bianhuanghou"] = "卞夫人-国",
	["#bf_bianhuanghou"] = "奕世之雍容",
	["illustrator:bf_bianhuanghou"] = "雪君S",
	["bf_wanwei"] = "挽危",
	["@bf_wanwei"] = "请弃置等量的牌",
	--[":bf_wanwei"] = "你可以选择被其他角色弃置或获得的牌。",
	[":bf_wanwei"] = "当你因被其他角色获得或弃置而失去牌时，你可以改为自己选择失去的牌。 ",
	["$bf_wanwei1"] = "梁、沛之间，非子廉无有今日。",
	["$bf_wanwei2"] = "正使祸至，共死何苦！",
	["bf_yuejian"] = "约俭",
	[":bf_yuejian"] = "一名角色的弃牌阶段开始时，若其于此回合内未使用过确定目标包括除其和你外的角色的牌，你可以令其于此回合内手牌上限视为体力上限。",
	["$bf_yuejian1"] = "无纹绣珠玉，器皆黑漆。",
	["$bf_yuejian2"] = "性情约俭，不尚华丽。",
	["~bf_bianhuanghou"] = "心肝涂地，惊愕断绝",

	["bf_shamoke"] = "沙摩柯-国",
	["#bf_shamoke"] = "五溪蛮王",
	["illustrator:bf_shamoke"] = "Liuheng",

	["bf_masu"] = "马谡-国",
	["#bf_masu"] = "帷幄经谋",
	["illustrator:bf_masu"] = "蚂蚁君",
	["bf_zhiman"] = "制蛮",
	[":bf_zhiman"] = "当你对其他角色造成伤害时，你可以防止此伤害，获得其装备区或判定区里的一张牌，然后其可以变更武将牌。",
	["$bf_zhiman1"] = "兵法谙熟于心，取胜千里之外。",
	["$bf_zhiman2"] = "丞相多虑，且看我的。",
	["~bf_masu"] = "败军之罪，万死难赎。",

	["bf_lingtong"] = "凌统-国",
	["#bf_lingtong"] = "豪情烈胆",
	["illustrator:bf_lingtong"] = "F.源",
	["bf_xuanlve"] = "旋略",
	[":bf_xuanlve"] = "当你失去装备区里的牌后，你可以弃置一名其他角色一张牌。",
	["$bf_xuanlve1"] = "舍辎减装，袭略如风！",
	["$bf_xuanlve2"] = "卸甲奔袭，摧枯拉朽！",
	["bf_yongjin"] = "勇进",
	[":bf_yongjin"] = "限定技，出牌阶段，你可以获得场上的最多三张装备区里的牌，然后将这些牌置入一至三名角色的装备区。",
	["$bf_yongjin1"] = "长缨缚敌，先登夺旗！",
	["$bf_yongjin2"] = "激流勇进，覆戈倒甲！",
	["~bf_lingtong"] = "",
	
	["bf_lvfan"] = "吕范-国",
	["#bf_lvfan"] = "忠笃亮直",
	["illustrator:bf_lvfan"] = "銘zmy",
	["information:bf_lvfan"] = "2025吕范",
	["bf_tiaodu"] = "调度",
	[":bf_tiaodu"] = "当每回合首次有角色使用装备牌时，你可以令其选择是否摸一张牌。出牌阶段开始时，你可以选择一名装备区有牌其他角色选择令你是否获得其装备区里的一张牌，并可以将之交给另一名角色。",
	["bf_tiaodu-invoke"] = "你可以发动“调度”<br/> <b>操作提示</b>: 选择一名装备区有牌其他角色→点击确定<br/>",
	["$bf_tiaodu1"] = "开源节流，作法于凉。",
	["$bf_tiaodu2"] = "调度征求，省刑薄敛。",
	-- ["bf_diancai"] = "典财",
	-- [":bf_diancai"] = "其他角色的出牌阶段结束时，若你于此阶段内失去过不少于X张牌（X为你体力值），你可以将手牌摸至体力上限。每局限一次，以此法摸牌后你可以变更副将。 ",
	["$bf_diancai1"] = "天下熙攘，皆为利往。",
	["$bf_diancai2"] = "量入为出，利析秋毫。",
	["~bf_lvfan"] = "印绶未下，疾病已发......",
	
	["bf_sec_lvfan"] = "吕范-国[二版]",
	["#bf_sec_lvfan"] = "忠笃亮直",
	["illustrator:bf_sec_lvfan"] = "銘zmy",
	["information:bf_sec_lvfan"] = "2019吕范",
	["bf_sec_tiaodu"] = "调度",
	[":bf_sec_tiaodu"] = "一名角色使用装备牌时你可以令其选择是否摸一张牌。出牌阶段开始时，你可以选择一名装备区有牌其他角色选择令你是否获得其装备区里的一张牌，然后可以将此牌交给另一名角色。",

	["~bf_sec_lvfan"] = "印绶未下，疾病已发......",

	["bf_third_lvfan"] = "吕范-国[三版]",
	["#bf_third_lvfan"] = "忠笃亮直",
	["illustrator:bf_third_lvfan"] = "銘zmy",
	["information:bf_third_lvfan"] = "2023吕范",
	["bf_third_tiaodu"] = "调度",
	[":bf_third_tiaodu"] = "一名角色使用装备牌时你可以令其选择是否摸一张牌。出牌阶段开始时，你可以获得与你势力相同的一名角色装备区里的一张牌，然后将此牌交给另一名角色。",

	["~bf_third_lvfan"] = "印绶未下，疾病已发......",

	["bf_nos_lvfan"] = "吕范-国[旧]",
	["#bf_nos_lvfan"] = "忠笃亮直",
	["illustrator:bf_nos_lvfan"] = "銘zmy",
	["information:bf_nos_lvfan"] = "2017初版吕范",
	["bf_nos_tiaodu"] = "调度",
	[":bf_nos_tiaodu"] = "出牌阶段限一次，你可以选择包括你在内的至少一名角色，这些角色各可以选择一项：1.使用装备牌；2.将装备区里的一张牌置入一名角色的装备区内。",

	["bf_diancai"] = "典财",
	[":bf_diancai"] = "其他角色的出牌阶段结束时，若你于此阶段内失去过至少X张牌，你可以将手牌补至上限，然后可以变更武将牌。（X为你的体力值）",
	["~bf_nos_lvfan"] = "印绶未下，疾病已发......",

	["bf_lijueguosi"] = "李傕&郭汜-国",
	["&bf_lijueguosi"] = "李傕郭汜",
	["#bf_lijueguosi"] = "犯祚倾祸",
	["illustrator:bf_lijueguosi"] = "旭",
	["cv:bf_lijueguosi"] = "《三国演义》",
	["bf_xiongsuan"] = "凶算",
	[":bf_xiongsuan"] = "限定技，出牌阶段，你可以弃置一张牌并选择一名角色，对其造成1点伤害，然后你摸三张牌，若其拥有限定技，你可以令其中一个限定技于此回合结束后视为未发动。",
	--["$bf_xiongsuan1"] = "让他看看我的箭法~",
	--["$bf_xiongsuan2"] = "我们是太师的人，太师不平反，我们就不能名正言顺！ 郭将军所言极是！",
	--["~bf_lijueguosi"] = "李傕郭汜二贼火拼，两败俱伤~",
	["$bf_xiongsuan1"] = "此战虽凶，得益颇高！",
	["$bf_xiongsuan2"] = "谋算计策，吾二人尚有险招！",
	["~bf_lijueguosi"] = "一心相争，兵败战损......",

	["bf_zuoci"] = "左慈-国",
	["#bf_zuoci"] = "迷之仙人",
	["illustrator:bf_zuoci"] = "吕阳",
	["bf_yigui"] = "役鬼",
	["#bf_yigui_prohibit"] = "役鬼",
	[":bf_yigui"] = "游戏开始前，你将剩余武将牌堆中的两张牌扣置于武将牌上，称为“魂”牌；你可以展示并移去一张“魂”牌，视为使用任意一张你本回合未以此法使用过的基本牌或普通锦囊牌，且目标必须是与“魂”牌势力相同的角色。",
	["$bf_yigui1"] = "魂聚则生，魂散则弃。",
	["$bf_yigui2"] = "魂羽化游，以辅四方。",


	["bf_jihun"] = "汲魂",
	[":bf_jihun"] = "当你受到伤害后，或与你势力不同的角色的濒死结算结束且存活后，你可以将剩余武将牌堆中的一张牌扣置于你的武将牌上，称为“魂”牌。",
	["$bf_jihun1"] = "百鬼众魅，自缚见形。",
	["$bf_jihun2"] = "来去无踪，众谓诡异。",

	-- ["~bf_zuoci"] = "仙人转世，一去无返",

	["bf_nos_zuoci"] = "左慈-国-初版",
	["#bf_nos_zuoci"] = "迷之仙人",--编一个
	["illustrator:bf_nos_zuoci"] = "吕阳",
	["information:bf_nos_zuoci"] = "变包初稿左慈",
	["bf_nos_huashen"] = "化身",
	[":bf_nos_huashen"] = "准备阶段开始时，若“化身”数：小于2，你可以观看武将牌堆顶五张牌，将其中一至两张牌扣置于你的武将牌上，称为“化身”；不小于2，你可以观看武将牌堆顶一张牌，然后将之与其中一张“化身”替换。你可以发动“化身”拥有的技能（除锁定技、转换技、限定技、觉醒技、主公技），若如此做，将那张武将牌置入武将牌堆。",
	["$bf_nos_huashen1"] = "为仙之道,飘渺莫测~",
	["$bf_nos_huashen2"] = "仙人之力,昭于世间~",
	["bf_nos_xinsheng"] = "新生",
	[":bf_nos_xinsheng"] = "当你受到伤害后，你可以将武将牌堆顶一张牌扣置于武将牌上，称为“化身”。",
	["$bf_nos_xinsheng1"] = "感觉到了新的魂魄~",
	["$bf_nos_xinsheng2"] = "神光不灭,仙力不绝~",
	["~bf_nos_zuoci"] = "仙人转世，一去无返",
	-- 權

    ["twyj_caohong"] = "TW曹洪",
	["&twyj_caohong"] = "曹洪",
	["#twyj_caohong"] = "骠骑将军",
	["illustrator:twyj_caohong"] = "黄人尤",
	["twyj_huzhu"] = "护主",
	[":twyj_huzhu"] = "出牌阶段限一次，若你的装备区有牌，你可以指定一名其他角色，交给你一张手牌，并获得你装备区的一张牌。若其体力值不大于你，你可以令其回复1点体力。",
	["@twyj_huzhu"] = "请交给 %src 一张手牌",
	["twyj_liancai"] = "敛财",
	[":twyj_liancai"] = "结束阶段，你可以翻面，并获得一名角色装备区里的一张牌；每当你翻面时，你可以将手牌补至体力值。",
	["twyj_liancai_turnover"] = "手牌补至体力值",
	
	["twyj_dingfeng"] = "TW丁奉",
	["&twyj_dingfeng"] = "丁奉",
	["#twyj_dingfeng"] = "勇冠全军",
	["illustrator:twyj_dingfeng"] = "柯郁萍",
	["twyj_qijia"] = "弃甲",
	[":twyj_qijia"] = "出牌阶段（装备区每个位置限一次），你可以弃置一张在装备区的牌，视为对一名攻击范围内的其他角色使用【杀】（你以此法使用的【杀】不计入出牌阶段【杀】的使用次数）。",
	["twyj_zhuchen"] = "诛綝",
	[":twyj_zhuchen"] = "出牌阶段，你可以弃置一张【酒】或【桃】并指定一名角色，此阶段视为与该角色距离为1。",

	["twyj_maliang"] = "TW马良",
	["&twyj_maliang"] = "马良",
	["#twyj_maliang"] = "白眉令士",
	["illustrator:twyj_maliang"] = "廖昌翊",
	["twyj_rangyi"] = "攘夷",
	--[":twyj_rangyi"] = "出牌阶段限一次，你可以将所有手牌（至少一张）交给一名其他角色，该角色可以从你给的手牌中合理使用一张手牌，即目标获得使用一张手牌的额外出牌阶段。该张牌结算前，需把剩余手牌还给你，若其不使用手牌，则视为你对其造成1点伤害且手牌不能还给你。",
	[":twyj_rangyi"] = "出牌阶段限一次，你可以将所有手牌（至少一张）交给一名其他角色，该角色可以从你给的手牌中合理使用一张手牌（即目标获得使用一张手牌的额外出牌阶段），该张牌结算前，需把剩余手牌还给你。若其不使用手牌，则视为你对其造成1点伤害且手牌不能还给你。",
	["@twyj_rangyi"] = "请使用一张手牌",
	["~twyj_rangyi"] = "选择一张牌→选择目标→点击确定",
	["twyj_baimei"] = "白眉",
	[":twyj_baimei"] = "锁定技，若你没有手牌，你防止你受到的任何的锦囊牌的伤害和属性的伤害。",
	["#twyj_baimei_Protect"] = "%from 的“<font color=\"yellow\"><b>白眉</b></font>”效果被触发，防止了 %arg 点伤害[%arg2]",

    ["sunjian_po"] = "孙坚",
	["#sunjian_po"] = "武烈帝",
	["yinghun_po"] = "英魂",
	[":yinghun_po"] = " 准备阶段开始时，若你已受伤，你可以选择一名其他角色，然后选择一项：1.令其摸一张牌，然后弃置X张牌；2.令其摸X张牌，然后弃置一张牌。（若你的装备区里的牌数不小于体力值，X为你的体力上限，否则X为你已损失的体力值）",
    ["yinghun1"] = "令其摸一张牌，然后弃置X张牌",
	["yinghun2"] = "令其摸X张牌，然后弃置一张牌",
	["$yinghun_po1"] = "宝剑出鞘，踏平贼营！",
	["$yinghun_po2"] = "乱世清君侧，挥师复江山",
	["~sunjian_po"] = "呃...空留余恨哪！",

	["heg_ol_dianwei"] = "典韦-国[OL]",
    ["&heg_ol_dianwei"] = "典韦",
	["#heg_ol_dianwei"] = "古之恶来",
	-- ["~heg_ol_dianwei"] = "",

	["heg_ol_huangzhong"] = "黄忠-国[OL]",
    ["&heg_ol_huangzhong"] = "黄忠",
	["#heg_ol_huangzhong"] = "老当益壮",
	-- ["~heg_ol_huangzhong"] = "",
	["heg_ol_liegong"] = "烈弓",
	[":heg_ol_liegong"] = "你使用【杀】可以选择距离不大于此【杀】点数的角色为目标。当你于出牌阶段内使用【杀】指定一名角色为目标后，若其手牌数不小于你的体力值或不大于你的攻击范围，你可以令其不能使用【闪】响应此【杀】。",

	["sijyuoffline_zhaoyun"] = "赵云[联想]",
    ["&sijyuoffline_zhaoyun"] = "赵云",
    ["#sijyuoffline_zhaoyun"] = "白马先锋",
    ["~sijyuoffline_zhaoyun"] = "",
    ["designer:sijyuoffline_zhaoyun"] = "",
    ["cv:sijyuoffline_zhaoyun"] = "",
    ["illustrator:sijyuoffline_zhaoyun"] = "VINCENT",

	--君临天下·权
	["command"] = "军令",

	["#StartCommand"] = "%arg：请选择一项军令<br>%arg2；<br>%arg3",
	["command1"] = "军令一",
	["command2"] = "军令二",
	["command3"] = "军令三",
	["command4"] = "军令四",
	["command5"] = "军令五",
	["command6"] = "军令六",

	[":command1"] = "军令一：对发起者指定的角色造成1点伤害",
	[":command2"] = "军令二：摸一张牌，然后交给发起者两张牌",
	[":command3"] = "军令三：失去1点体力",
	[":command4"] = "军令四：本回合不能使用或打出手牌且所有非锁定技失效",
	[":command5"] = "军令五：叠置，本回合不能回复体力",
	[":command6"] = "军令六：选择一张手牌和一张装备区里的牌，弃置其余的牌",

	["start_command"] = "发起军令",
	["#AskCommandTo"] = "%from 发动了 “%arg”，对 %to 发起了 <font color='#0598BC'><b>军令",
	["#CommandChoice"] = "%from 选择了 %arg",
	["chose"] = "选择了",

	["do_command"] = "执行军令",
	["#commandselect_yes"] = "执行军令",
	["#commandselect_no"] = "不执行军令",

	["#command1-damage"] = "军令：请选择 %dest 伤害的目标",
	["#Command1Damage"] = "%from 选择对 %to 造成伤害",
	["#command2-give"] = "军令：请选择两张牌交给 %dest",
	["command4_effect"] = "军令禁出牌技能",
	["command5_effect"] = "军令 不能回血",
	["#command6-select"] = "军令：请选择要保留的一张手牌和一张装备",

	["heg_yujin"] = "于禁-国",
    ["&heg_yujin"] = "于禁",
    ["#heg_yujin"] = "讨暴坚垒",
    ["~heg_yujin"] = "",
    ["designer:heg_yujin"] = "Virgopaladin（韩旭）",
    ["cv:heg_yujin"] = "",
    ["illustrator:heg_yujin"] = "biou09",
	["heg_jueyue"] = "节钺",
	[":heg_jueyue"] = "准备阶段，你可以将一张牌交给一名其他角色，然后令其执行一次“军令”。若其：执行，你摸一张牌；不执行，摸牌阶段，你多摸三张牌。",
	["@heg_jueyue-give"] = "你可以将一张牌交给一名其他角色，令其执行一次“军令”",
	["heg_jueyue-invoke"] = "你可以发动“节钺”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",

	["heg_cuiyanmaojie"] = "崔琰毛玠-国",
    ["&heg_cuiyanmaojie"] = "崔琰毛玠",
    ["#heg_cuiyanmaojie"] = "日出月盛",
    ["~heg_cuiyanmaojie"] = "",
    ["designer:heg_cuiyanmaojie"] = "Virgopaladin（韩旭）",
    ["cv:heg_cuiyanmaojie"] = "",
    ["illustrator:heg_cuiyanmaojie"] = "兴游",	
	["heg_zhengbi"] = "征辟",
	[":heg_zhengbi"] = "出牌阶段开始时，你可选择一项：1.选择一名角色，直至此回合结束，你对其使用牌无距离与次数限制；2.将一张基本牌交给一名角色，然后其交给你一张非基本牌或两张基本牌。",
	["#heg_fengying"] = "奉迎",
  	[":#heg_fengying"] = "限定技，出牌阶段，你可将所有手牌当【挟天子以令诸侯】（无视大势力限制）使用，然后所有与你势力相同的角色将手牌补至其体力上限。",

	["heg_wangping"] = "王平-国",
    ["&heg_wangping"] = "王平",
    ["#heg_wangping"] = "键闭剑门",
    ["~heg_wangping"] = "",
    ["designer:heg_wangping"] = "",
    ["cv:heg_wangping"] = "",
    ["illustrator:heg_wangping"] = "zoo",
	["heg_jianglue"] = "将略",
  	[":heg_jianglue"] = "限定技，出牌阶段，你可选择一个“军令”。你对任意名角色发起此“军令”。你加1点体力上限，回复1点体力，所有执行“军令”的角色各加1点体力上限，回复1点体力。然后你摸X张牌（X为以此法回复体力的角色数）。",
	--4

	["heg_fazheng"] = "法正-国",
    ["&heg_fazheng"] = "法正",
    ["#heg_fazheng"] = "蜀汉的辅翼",
    ["~heg_fazheng"] = "",
    ["designer:heg_fazheng"] = "",
    ["cv:heg_fazheng"] = "",
    ["illustrator:heg_fazheng"] = "黑白画谱",
	["heg_xuanhuo"] = "眩惑",
  	[":heg_xuanhuo"] = "其他角色的出牌阶段限一次，其可交给你一张手牌，然后其弃置一张牌，选择下列技能中的一个：“武圣”“咆哮”“龙胆”“铁骑”“烈弓”“狂骨”（场上已有的技能无法选择）。其于此回合内或明置有其以此法选择的技能的武将牌之前拥有其以此法选择的技能。",
	["heg_enyuan"] = "恩怨",
  	[":heg_enyuan"] = "锁定技，当你成为【桃】的目标后，若使用者不为你，其摸一张牌；当你受到伤害后，伤害来源需交给你一张手牌，否则失去1点体力。",
	--3

	["heg_lukang"] = "陆抗-国",
    ["&heg_lukang"] = "陆抗",
    ["#heg_lukang"] = "孤柱扶厦",
    ["~heg_lukang"] = "",
    ["designer:heg_lukang"] = "",
    ["cv:heg_lukang"] = "",
    ["illustrator:heg_lukang"] = "王立雄",
	["heg_keshou"] = "恪守",
  	[":heg_keshou"] = "当你受到伤害时，你可弃置两张颜色相同的牌，令此伤害值-1，然后你判定，若结果为红色，你摸一张牌。",
	["heg_zhuwei"] = "筑围",
  	[":heg_zhuwei"] = "当你的判定结果确定后，你可获得此判定牌，然后你可令当前回合角色手牌上限和使用【杀】的次数上限于此回合内+1。",
	--3

	["heg_wuguotai"] = "吴国太-国",
    ["&heg_wuguotai"] = "吴国太",
    ["#heg_wuguotai"] = "武烈皇后",
    ["~heg_wuguotai"] = "",
    ["designer:heg_wuguotai"] = "",
    ["cv:heg_wuguotai"] = "",
    ["illustrator:heg_wuguotai"] = "李秀森",
	["heg_buyi"] = "补益",
  	[":heg_buyi"] = "每回合限一次，当一名角色的濒死结算后，若其存活，你可对伤害来源发起“军令”。若来源不执行，则你令该角色回复1点体力。",
	--3

	["heg_yuanshu"] = "袁术-国",
    ["&heg_yuanshu"] = "袁术",
    ["#heg_yuanshu"] = "仲家帝",
    ["~heg_yuanshu"] = "",
    ["designer:heg_yuanshu"] = "",
    ["cv:heg_yuanshu"] = "",
    ["illustrator:heg_yuanshu"] = "YanBai",
	["heg_yongsi"] = "庸肆",
  	[":heg_yongsi"] = "锁定技，①若所有角色的装备区里均没有【玉玺】，你视为装备着【玉玺】；②当你成为【知己知彼】的目标后，展示所有手牌。",
    ["heg_weidi"] = "伪帝",
  	[":heg_weidi"] = "出牌阶段限一次，你可选择一名本回合从牌堆获得过牌的其他角色，对其发起“军令”。若其不执行，则你获得其所有手牌，然后交给其等量的牌。",
	--4

	["heg_zhangxiu"] = "张绣-国",
    ["&heg_zhangxiu"] = "张绣",
    ["#heg_zhangxiu"] = "北地枪王",
    ["~heg_zhangxiu"] = "",
    ["designer:heg_zhangxiu"] = "千幻",
    ["cv:heg_zhangxiu"] = "",
    ["illustrator:heg_zhangxiu"] = "青岛磐蒲",
	["heg_fudi"] = "附敌",
  	[":heg_fudi"] = "当你受到其他角色造成的伤害后，你可以交给伤害来源一张手牌。若如此做，你对体力值最多且不小于你的一名角色造成1点伤害。",
    ["heg_congjian"] = "从谏",
  	[":heg_congjian"] = "锁定技，当你于回合外造成伤害时或于回合内受到伤害时，伤害值+1。",
	--4

	--君临天下·EX/不臣篇
	["heg_mengda"] = "孟达-国",
    ["&heg_mengda"] = "孟达",
    ["#heg_mengda"] = "怠军反复",
    ["~heg_mengda"] = "",
    ["designer:heg_mengda"] = "韩旭",
    ["cv:heg_mengda"] = "",
    ["illustrator:heg_mengda"] = "张帅",
	["heg_qiuan"] = "求安",
  	[":heg_qiuan"] = "当你受到伤害时，若没有“函”，你可将造成此伤害的牌置于武将牌上，称为“函”，然后防止此伤害。",
	["heg_liangfan"] = "量反",
  	[":heg_liangfan"] = "锁定技，准备阶段，若你有“函”，你获得之，然后失去1点体力，当你于此回合内使用以此法获得的牌造成伤害后，你可以获得受伤角色的一张牌。",

	["heg_liuqi"] = "刘琦-国",
    ["&heg_liuqi"] = "刘琦",
    ["#heg_liuqi"] = "居外而安",
    ["~heg_liuqi"] = "",
    ["designer:heg_liuqi"] = "荼蘼（韩旭）",
    ["cv:heg_liuqi"] = "",
    ["illustrator:heg_liuqi"] = "绘聚艺堂",
	["heg_wenji"] = "问计",
  	[":heg_wenji"] = "出牌阶段开始时，你可令一名角色交给你一张牌，然后若其：与你势力相同或未确定势力，你于此回合内使用此牌无距离与次数限制且不能被响应；与你势力不同，你交给其另一张牌。",
	--secondtunjiang

	["heg_mifangfushiren"] = "糜芳傅士仁-国",
    ["&heg_mifangfushiren"] = "糜芳傅士仁",
    ["#heg_mifangfushiren"] = "逐驾迎尘",
    ["~heg_mifangfushiren"] = "",
    ["designer:heg_mifangfushiren"] = "Loun老萌",
    ["cv:heg_mifangfushiren"] = "",
    ["illustrator:heg_mifangfushiren"] = "木美人",
	["heg_fengshih"] = "锋势",
  	[":heg_fengshih"] = "①当你使用牌指定其他角色为唯一目标后，若其手牌数小于你且你与其均有牌，你可以弃置你与其各一张牌，然后此牌造成伤害值+1；②当你成为其他角色使用牌的唯一目标后，若你手牌数小于其且你与其均有牌，其可以令你弃置你与其各一张牌，然后此牌造成伤害值+1。",
	
	["heg_zhanglu"] = "张鲁-国",
    ["&heg_zhanglu"] = "张鲁",
    ["#heg_zhanglu"] = "政宽教惠",
    ["~heg_zhanglu"] = "",
    ["designer:heg_zhanglu"] = "",
    ["cv:heg_zhanglu"] = "",
    ["illustrator:heg_zhanglu"] = "磐蒲",
	["heg_bushi"] = "布施",
  	[":heg_bushi"] = "当你受到1点伤害后，你可以令一名角色摸一张牌；当你对其他角色造成伤害后，你令一名角色摸一张牌。",
    ["heg_midao"] = "米道",
  	[":heg_midao"] = "一名角色的出牌阶段限一次，当其使用的【杀】或伤害类锦囊牌指定第一个目标时，其可以交给你一张手牌，令你声明一种花色和一种属性，然后其此次使用牌的花色与造成伤害的属性视为与你声明的相同。",

	["heg_shixie"] = "士燮-国",
    ["&heg_shixie"] = "士燮",
    ["#heg_shixie"] = "百粤灵欹",
    ["~heg_shixie"] = "",
    ["designer:heg_shixie"] = "韩旭",
    ["cv:heg_shixie"] = "",
    ["illustrator:heg_shixie"] = "磐蒲",	
	["heg_lixia"] = "礼下",
  	[":heg_lixia"] = "锁定技，其他势力角色的准备阶段，若你不在其攻击范围内，该角色须选择一项：1.令你摸一张牌；2.弃置你装备区内的一张牌，该角色失去1点体力。",
	["heg_biluan"] = "避乱",
  	[":heg_biluan"] = "锁定技，其他角色计算与你的距离+X（X为你装备区内的牌数）。",

	["heg_tangzi"] = "唐咨-国",
    ["&heg_tangzi"] = "唐咨",
    ["#heg_tangzi"] = "得时识风",
    ["~heg_tangzi"] = "",
    ["designer:heg_tangzi"] = "荼蘼（韩旭）",
    ["cv:heg_tangzi"] = "",
    ["illustrator:heg_tangzi"] = "凝聚永恒",
	["heg_xingzhao"] = "兴棹",
  	[":heg_xingzhao"] = "锁定技，若场上受伤角色的势力数为：1个或以上，你拥有技能〖恂恂〗；2个或以上，你受到伤害后，你与伤害来源手牌数较少的角色摸一张牌；3个或以上，你的手牌上限+4；4个或以上，你失去装备区内的牌时，摸一张牌。",

	["heg_tangzi"] = "董昭-国",
    ["&heg_tangzi"] = "董昭",
    ["#heg_tangzi"] = "移尊易鼎",
    ["~heg_tangzi"] = "",
    ["designer:heg_tangzi"] = "逍遥鱼叔",
    ["cv:heg_tangzi"] = "",
    ["illustrator:heg_tangzi"] = "小牛",
	["heg_quanjin"] = "劝进",
  	[":heg_quanjin"] = "出牌阶段限一次，你可将一张手牌交给一名此阶段受到过伤害的角色，对其发起“军令”。若其执行，你摸一张牌；若其不执行，你将手牌摸至与手牌最多的角色相同（最多摸五张）。",
    ["heg_zaoyun"] = "凿运",
  	[":heg_zaoyun"] = "出牌阶段限一次，你可选择一名至其距离大于1的角色并弃置X张手牌（X为你至其的距离-1），令你至其的距离此回合视为1，然后你对其造成1点伤害。",

	["heg_xushu"] = "徐庶-国",
    ["&heg_xushu"] = "徐庶",
    ["#heg_xushu"] = "难为完臣",
    ["~heg_xushu"] = "",
    ["designer:heg_xushu"] = "",
    ["cv:heg_xushu"] = "",
    ["illustrator:heg_xushu"] = "YanBai",
	["ld__qiance"] = "谦策",
  	[":ld__qiance"] = "与你势力相同的角色使用锦囊牌指定目标后，其可令其中的大势力角色不能响应此牌。",
	["ld__jujian"] = "举荐",
  	[":ld__jujian"] = "锁定技，当与你势力相同的角色进入濒死阶段时，你令其将体力回复至1点，然后你变更副将。",

	["heg_wujing"] = "吴景-国",
    ["&heg_wujing"] = "吴景",
    ["#heg_wujing"] = "汗马鎏金",
    ["~heg_wujing"] = "",
    ["designer:heg_wujing"] = "逍遥鱼叔",
    ["cv:heg_wujing"] = "",
    ["illustrator:heg_wujing"] = "小牛",
  	["ld__diaogui"] = "调归",
  	[":ld__diaogui"] = "出牌阶段限一次，你可将一张装备牌当【调虎离山】使用，然后若你的势力形成<a href='heg_formation'>队列</a>，则你摸X张牌（X为此队列中的角色数）。",
	["ld__fengyang"] = "风扬",
  	[":ld__fengyang"] = "阵法技，与你处于同一<a href='heg_formation'>队列</a>的角色装备区内的牌被与你势力不同的角色弃置或获得时，取消之。",
	
	["heg_yanbaihu"] = "严白虎-国",
    ["&heg_yanbaihu"] = "严白虎",
    ["#heg_yanbaihu"] = "豺牙落涧",
    ["~heg_yanbaihu"] = "",
    ["designer:heg_yanbaihu"] = "逍遥鱼叔",
    ["cv:heg_yanbaihu"] = "",
    ["illustrator:heg_yanbaihu"] = "",	
	["ld__zhidao"] = "雉盗",
	[":ld__zhidao"] = "锁定技，出牌阶段开始时，你选择一名其他角色，你于此回合内：1.使用牌仅能指定你或其为目标；2.计算与其距离为1；3.首次对其造成伤害后，获得其区域内一张牌。",
	["ld__jilix"] = "寄篱",
  	[":ld__jilix"] = "锁定技，①当你成为红色基本牌或红色普通锦囊牌的唯一目标后，你令此牌结算两次；②当你于一回合内第二次受到伤害时，你移除此武将牌，防止之。",
	
	["heg_wenqin"] = "文钦-国",
    ["&heg_wenqin"] = "文钦",
    ["#heg_wenqin"] = "勇而无算",
    ["~heg_wenqin"] = "",
    ["designer:heg_wenqin"] = "逍遥鱼叔",
    ["cv:heg_wenqin"] = "",
    ["illustrator:heg_wenqin"] = "匠人绘-零二",		
	["ld__jinfa"] = "矜伐",
  	[":ld__jinfa"] = "出牌阶段限一次，你可弃置一张牌并选择一名其他角色，令其选择一项：1.令你获得其一张牌；2.交给你一张装备牌，若此装备牌为♠，其视为对你使用一张【杀】。",
	
	["heg_xiahouba"] = "夏侯霸-国",
    ["&heg_xiahouba"] = "夏侯霸",
    ["#heg_xiahouba"] = "棘途壮志",
    ["~heg_xiahouba"] = "",
    ["designer:heg_xiahouba"] = "逍遥鱼叔",
    ["cv:heg_xiahouba"] = "",
    ["illustrator:heg_xiahouba"] = "小牛",		
	["ld__baolie"] = "豹烈",
  	[":ld__baolie"] = "锁定技，①出牌阶段开始时，你令所有与你势力不同且攻击范围内含有你的角色依次对你使用一张【杀】，否则你弃置其一张牌。②你对体力值不小于你的角色使用【杀】无距离与次数限制。",
	
	["heg_xuyou"] = "许攸-国",
    ["&heg_xuyou"] = "许攸",
    ["#heg_xuyou"] = "毕方矫翼",
    ["~heg_xuyou"] = "",
    ["designer:heg_xuyou"] = "逍遥鱼叔",
    ["cv:heg_xuyou"] = "",
    ["illustrator:heg_xuyou"] = "猎枭",	
	["ld__chenglue"] = "成略",
  	[":ld__chenglue"] = "当与你势力相同的角色使用多目标的牌结算后，你可令其摸一张牌。若你受到过此牌造成的伤害，你可令一名与你势力相同、武将牌均明置且没有国战标记的角色获得一个“阴阳鱼”标记。",
	["ld__shicai"] = "恃才",
  	[":ld__shicai"] = "锁定技，当你受到伤害后，若此伤害为1点，你摸一张牌，否则你弃置两张牌。",

	["heg_sufei"] = "苏飞-国",
    ["&heg_sufei"] = "苏飞",
    ["#heg_sufei"] = "诤友投明",
    ["~heg_sufei"] = "",
    ["designer:heg_sufei"] = "逍遥鱼叔",
    ["cv:heg_sufei"] = "",
    ["illustrator:heg_sufei"] = "Domi",
	["ld__lianpian"] = "联翩",
  	[":ld__lianpian"] = "结束阶段，若你于此回合内弃置任意角色牌的总数大于你的体力值，你可以令一名与你势力相同的角色将手牌摸至体力上限。其他角色的结束阶段，若其于此回合内弃置任意角色牌的总数大于你的体力值，其可以弃置你的一张牌或令你回复1点体力。",

	["heg_panjun"] = "潘濬-国",
    ["&heg_panjun"] = "潘濬",
    ["#heg_panjun"] = "逆鳞之砥",
    ["~heg_panjun"] = "",
    ["designer:heg_panjun"] = "逍遥鱼叔",
    ["cv:heg_panjun"] = "",
    ["illustrator:heg_panjun"] = "Domi",
	["ld__congcha"] = "聪察",
  	[":ld__congcha"] = "①准备阶段，你可选择一名未确定势力的角色，然后直到你的下回合开始，当其明置武将牌后，若其确定势力且势力与你：相同，你与其各摸两张牌；不同，其失去1点体力。②摸牌阶段，若场上不存在未确定势力的角色，你可多摸两张牌。",
	--gongqing

	["heg_pengyang"] = "彭羕-国",
    ["&heg_pengyang"] = "彭羕",
    ["#heg_pengyang"] = "误身的狂士",
    ["~heg_pengyang"] = "",
    ["designer:heg_pengyang"] = "韩旭",
    ["cv:heg_pengyang"] = "",
    ["illustrator:heg_pengyang"] = "匠人绘-零一",	
	["ld__jinxian"] = "近陷",
  	[":ld__jinxian"] = "当你明置此武将牌后，你令所有你计算距离不大于1的角色执行：若其武将牌均明置，暗置一张武将牌；否则其弃置两张牌。",
	["ld__tongling"] = "通令",
  	[":ld__tongling"] = "每阶段限一次，当你于出牌阶段内对其它势力角色造成伤害后，你可令一名与你势力相同的角色对其使用一张牌，然后若此牌：造成伤害，你与其各摸两张牌；未造成伤害，其获得你对其造成伤害的牌。",
	
	["heg_nos_pengyang"] = "彭羕-国[旧]",
    ["&heg_nos_pengyang"] = "彭羕",
    ["#heg_nos_pengyang"] = "误身的狂士",
    ["~heg_nos_pengyang"] = "",
    ["designer:heg_nos_pengyang"] = "韩旭",
    ["cv:heg_nos_pengyang"] = "",
    ["illustrator:heg_nos_pengyang"] = "匠人绘-零一",
	["heg_nos_daming"] = "达命",
  	[":heg_nos_daming"] = "与你势力相同的角色出牌阶段开始时，你可以弃置一张锦囊牌，横置一名角色并摸X张牌（X为有横置角色的势力数），然后选择一项：1.视为对当前回合角色使用一张【桃】；2.令当前回合角色视为对你选择的另一名角色使用一张雷【杀】。",
	["heg_nos_xiaoni"] = "嚣逆",
  	[":heg_nos_xiaoni"] = "锁定技，当你使用牌指定目标或成为牌的目标后，若场上有与你势力相同的其他角色且这些角色手牌数均不大于你，目标角色不能响应此牌。",

	["heg_zhuling"] = "朱灵-国",
    ["&heg_zhuling"] = "朱灵",
    ["#heg_zhuling"] = "五子之亚",
    ["~heg_zhuling"] = "",
    ["designer:heg_zhuling"] = "",
    ["cv:heg_zhuling"] = "",
    ["illustrator:heg_zhuling"] = "YanBai",
	["ld__juejue"] = "决绝",
  	[":ld__juejue"] = "①弃牌阶段开始时，你可失去1点体力，若如此做，此阶段结束时，若你于此阶段内弃置过牌，你令所有其他角色选择一项：1.将X张手牌置入弃牌堆；2.受到你造成的1点伤害（X为你于此阶段内弃置的牌数）；②你杀死与你势力相同的角色不执行奖惩。",
	["ld__fangyuan"] = "方圆",
  	[":ld__fangyuan"] = "阵法技，①若你是围攻角色，此围攻关系中围攻角色手牌上限+1，被围攻角色手牌上限-1。②结束阶段，若你是被围攻角色，你视为对此围攻关系中一名围攻角色使用一张无距离限制的【杀】。",

	["heg_liuba"] = "刘巴-国",
    ["&heg_liuba"] = "刘巴",
    ["#heg_liuba"] = "清河一鲲",
    ["~heg_liuba"] = "",
    ["designer:heg_liuba"] = "逍遥鱼叔",
    ["cv:heg_liuba"] = "",
    ["illustrator:heg_liuba"] = "Mr_Sleeping",
	["ld__tongdu"] = "统度",
  	[":ld__tongdu"] = "与你势力相同的角色的结束阶段，其可摸X张牌（X为其于弃牌阶段弃置的牌数且至多为3）",
	["ld__qingyin"] = "清隐",
 	[":ld__qingyin"] = "限定技，出牌阶段，你可移除此武将牌，然后与你势力相同的角色将体力回复至体力上限。",

	["heg_zhugeke"] = "诸葛恪-国",
    ["&heg_zhugeke"] = "诸葛恪",
    ["#heg_zhugeke"] = "兴家赤族",
    ["~heg_zhugeke"] = "",
    ["designer:heg_zhugeke"] = "逍遥鱼叔",
    ["cv:heg_zhugeke"] = "",
    ["illustrator:heg_zhugeke"] = "猎枭",
	--aocai
	["ld__duwu"] = "黩武",
  	[":ld__duwu"] = "限定技，出牌阶段，你可以选择一个“军令”，你对你攻击范围内所有与你势力不同或未确定势力的角色发起此“军令”，若其不执行，你对其造成1点伤害并摸一张牌。此“军令”结算后，若存在进入濒死状态被救回的角色，你失去1点体力。",

	["heg_huangzu"] = "黄祖-国",
    ["&heg_huangzu"] = "黄祖",
    ["#heg_huangzu"] = "遮山扼江",
    ["~heg_huangzu"] = "",
    ["designer:heg_huangzu"] = "逍遥鱼叔",
    ["cv:heg_huangzu"] = "",
    ["illustrator:heg_huangzu"] = "YanBai",
	["ld__xishe"] = "袭射",
  	[":ld__xishe"] = "其他角色的准备阶段，你可以弃置一张装备区内的牌，视为对其使用一张【杀】（体力值小于你的角色不能响应），然后你可以重复此流程。此回合结束时，若你以此法杀死了一名角色，你可以变更副将且变更后的副将处于暗置状态。 ",

	["heg_simazhao"] = "司马昭-国",
    ["&heg_simazhao"] = "司马昭",
    ["#heg_simazhao"] = "嘲风开天",
    ["~heg_simazhao"] = "",
    ["designer:heg_simazhao"] = "韩旭",
    ["cv:heg_simazhao"] = "",
    ["illustrator:heg_simazhao"] = "凝聚永恒",
	["ld__suzhi"] = "夙智",
  	[":ld__suzhi"] = "锁定技，你的回合内：1.你执行【杀】或【决斗】的效果而造成伤害时，此伤害+1；2.你使用非转化锦囊牌时摸一张牌且无距离限制；3.其他角色的牌被弃置后，你获得其一张牌。当你于一回合内触发上述效果三次后，此技能于此回合内失效。回合结束时，你获得“反馈”直至回合开始。",
	["ld__zhaoxin"] = "昭心",
  	[":ld__zhaoxin"] = "当你受到伤害后，你可展示所有手牌，然后与一名手牌数不大于你的角色交换手牌。",

	["heg_zhonghui"] = "钟会-国",
    ["&heg_zhonghui"] = "钟会",
    ["#heg_zhonghui"] = "桀骜的野心家",
    ["~heg_zhonghui"] = "",
    ["designer:heg_zhonghui"] = "韩旭",
    ["cv:heg_zhonghui"] = "",
    ["illustrator:heg_zhonghui"] = "磐蒲",
	["ld__quanji"] = "权计",
  	[":ld__quanji"] = "每回合各限一次，当你受到伤害或造成伤害后，你可摸一张牌，然后将一张牌置于武将牌上，称为“权”；你的手牌上限+X（X为“权”的数量）。",
	["ld__paiyi"] = "排异",
  	[":ld__paiyi"] = "出牌阶段限一次，你可将一张“权”置入弃牌堆并选择一名角色，其摸X张牌，若其手牌数大于你，你对其造成1点伤害（X为“权”的数量且至多为7）。",

	["heg_nos_zhonghui"] = "钟会-国[旧]",
    ["&heg_nos_zhonghui"] = "钟会",
    ["#heg_nos_zhonghui"] = "桀骜的野心家",
    ["~heg_nos_zhonghui"] = "",
    ["designer:heg_nos_zhonghui"] = "韩旭",
    ["cv:heg_nos_zhonghui"] = "",
    ["illustrator:heg_nos_zhonghui"] = "磐蒲",
	["heg_nos_quanji"] = "权计",
  	[":heg_nos_quanji"] = "当你受到伤害后或使用牌指定唯一目标并对其造成伤害后，你可以摸一张牌，然后将一张牌置于武将牌上，称为“权”；你的手牌上限+X（X为“权”的数量）。",

	["heg_sunchen"] = "孙綝-国",
    ["&heg_sunchen"] = "孙綝",
    ["#heg_sunchen"] = "食髓的朝堂客",
    ["~heg_sunchen"] = "",
    ["designer:heg_sunchen"] = "逍遥鱼叔",
    ["cv:heg_sunchen"] = "",
    ["illustrator:heg_sunchen"] = "depp",
	["heg_shilus"] = "嗜戮",
  	[":heg_shilus"] = "当一名角色死亡时，你可将其所有武将牌置于你的武将牌旁（称为“戮”），若你为来源，你从剩余武将牌堆额外获得两张“戮”。准备阶段，你可以弃置至多X张牌（X为“戮”数），摸等量的牌。",
	["heg_xiongnve"] = "凶虐",
  	[":heg_xiongnve"] = "出牌阶段开始时，你可以移去一张“戮”，令你本回合对此“戮”势力角色获得下列效果中的一项：1.对其造成伤害时，令此伤害+1；2.对其造成伤害时，你获得其一张牌；3.对其使用牌无次数限制。出牌阶段结束时，你可以移去两张“戮”，然后直到你的下回合，当你受到其他角色造成的伤害时，此伤害-1。",

	["heg_gongsunyuan"] = "公孙渊-国",
    ["&heg_gongsunyuan"] = "公孙渊",
    ["#heg_gongsunyuan"] = "狡黠的投机者",
    ["~heg_gongsunyuan"] = "",
    ["designer:heg_gongsunyuan"] = "逍遥鱼叔",
    ["cv:heg_gongsunyuan"] = "",
    ["illustrator:heg_gongsunyuan"] = "猎枭",
	["ld__huaiyi"] = "怀异",
  	[":ld__huaiyi"] = "出牌阶段限一次，你可展示所有手牌，若其中包含两种颜色，则你弃置其中一种颜色的牌，然后获得至多X名角色的各一张牌（X为你以此法弃置的手牌数）。你将以此法获得的装备牌置于武将牌上，称为“异”。",
	["ld__zisui"] = "恣睢",
  	[":ld__zisui"] = "锁定技，①摸牌阶段，你多摸X张牌；②结束阶段，若X大于你的体力上限，你死亡（X为“异”的数量）。",

	["heg_nos_gongsunyuan"] = "公孙渊-国[旧]",
    ["&heg_nos_gongsunyuan"] = "公孙渊",
    ["#heg_nos_gongsunyuan"] = "狡黠的投机者",
    ["~heg_nos_gongsunyuan"] = "",
    ["designer:heg_nos_gongsunyuan"] = "逍遥鱼叔",
    ["cv:heg_nos_gongsunyuan"] = "",
    ["illustrator:heg_nos_gongsunyuan"] = "猎枭",
	["heg_nos_huaiyi"] = "怀异",
  	[":heg_nos_huaiyi"] = "出牌阶段限一次，你可以展示所有手牌，若其中包含两种颜色，你弃置其中一种颜色的牌，然后获得至多等同于弃置牌数的其他角色各一张牌，将以此法获得的装备牌置于你的武将牌上，称为“异”。你可以将“异”如手牌般使用或打出。",

	--紫气东来

	["heg_simayi"] = "司马懿-国",
    ["&heg_simayi"] = "司马懿",
    ["#heg_simayi"] = "应期佐命",
    ["~heg_simayi"] = "",
    ["designer:heg_simayi"] = "",
    ["cv:heg_simayi"] = "",
    ["illustrator:heg_simayi"] = "小罗没想好",
	["heg_yingshi"] = "鹰视",
  	[":heg_yingshi"] = "出牌阶段开始时，你可以令一名角色视为对你指定的另一名角色使用一张【知己知彼】，然后若使用者不为你，你摸一张牌。",
	["heg_shunfu"] = "瞬覆",
  	[":heg_shunfu"] = "限定技，出牌阶段，你可以令至多三名未确定势力的其他角色各摸两张牌，然后这些角色依次可以使用一张【杀】（无距离限制且不可被响应）。",

	["heg_zhangchunhua"] = "张春华-国",
    ["&heg_zhangchunhua"] = "张春华",
    ["#heg_zhangchunhua"] = "锋刃染霜",
    ["~heg_zhangchunhua"] = "",
    ["designer:heg_zhangchunhua"] = "",
    ["cv:heg_zhangchunhua"] = "",
    ["illustrator:heg_zhangchunhua"] = "小罗没想好",
	["heg_ejue"] = "扼绝",
  	[":heg_ejue"] = "锁定技，当你使用【杀】对未确定势力的角色造成伤害时，此伤害+1。",
    ["heg_shangshi"] = "伤逝",
  	[":heg_shangshi"] = "每名角色的回合结束时，你可以将手牌摸至已损失体力值。",

	["heg_simashi"] = "司马师-国",
    ["&heg_simashi"] = "司马师",
    ["#heg_simashi"] = "睚眥侧目",
    ["~heg_simashi"] = "",
    ["designer:heg_simashi"] = "",
    ["cv:heg_simashi"] = "",
    ["illustrator:heg_simashi"] = "拉布拉卡",
	["heg_yimie"] = "夷灭",
  	[":heg_yimie"] = "锁定技，你的回合内，与处于濒死状态角色势力相同/势力不同的角色不能使用【桃】/可将一张<font color='red'>♥</font>手牌当【桃】对处于濒死状态的角色使用。",
	["heg_ruilve"] = "睿略",
  	[":heg_ruilve"] = "未确定势力的其他角色出牌阶段限一次，其可展示并交给你一张伤害类牌，然后其摸一张牌。",

	["heg_simazhao"] = "司马昭-国",
    ["&heg_simazhao"] = "司马昭",
    ["#heg_simazhao"] = "天下畏威",
    ["~heg_simazhao"] = "",
    ["designer:heg_simazhao"] = "",
    ["cv:heg_simazhao"] = "",
    ["illustrator:heg_simazhao"] = "君桓文化",
	["heg_zhaoran"] = "昭然",
  	[":heg_zhaoran"] = "出牌阶段开始前，你可以摸X张牌（X为4-场上势力数），然后未确定势力的角色可以明置一张武将牌，令你结束此回合。",
	["heg_beiluan"] = "备乱",
  	[":heg_beiluan"] = "当你受到伤害后，你可以令伤害来源所有非装备手牌视为【杀】直到当前回合结束。",

	["heg_simazhou"] = "司马伷-国",
    ["&heg_simazhou"] = "司马伷",
    ["#heg_simazhou"] = "温恭的狻猊",
    ["~heg_simazhou"] = "",
    ["designer:heg_simazhou"] = "",
    ["cv:heg_simazhou"] = "",
    ["illustrator:heg_simazhou"] = "凝聚永恒",
	["heg_pojing"] = "迫境",
  	[":heg_pojing"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.令你获得其区域内的一张牌；2.所有与你势力相同的角色可以明置任意张武将牌，对其造成等量的伤害。",

	["heg_simaliang"] = "司马亮-国",
    ["&heg_simaliang"] = "司马亮",
    ["#heg_simaliang"] = "蒲牢惊啼",
    ["~heg_simaliang"] = "",
    ["designer:heg_simaliang"] = "",
    ["cv:heg_simaliang"] = "",
    ["illustrator:heg_simaliang"] = "小罗没想好",
	["heg_gongzhi"] = "共执",
  	[":heg_gongzhi"] = "你可以跳过摸牌阶段，令势力与你相同的角色依次摸一张牌，直到共计摸四张牌。",
	["heg_shejus"] = "慑惧",
  	[":heg_shejus"] = "锁定技，当其他角色明置武将牌后，若其势力与你相同，你回复1点体力，然后弃置所有手牌。",

	["heg_simalun"] = "司马伦-国",
    ["&heg_simalun"] = "司马伦",
    ["#heg_simalun"] = "螭吻裂冠",
    ["~heg_simalun"] = "",
    ["designer:heg_simalun"] = "",
    ["cv:heg_simalun"] = "",
    ["illustrator:heg_simalun"] = "荆芥",
	["heg_zhulan"] = "助澜",
  	[":heg_zhulan"] = "当一名其他角色受到伤害时，若伤害来源与其势力相同，你可以弃置一张牌令此伤害+1。",
	["heg_luanchang"] = "乱常",
  	[":heg_luanchang"] = "限定技，与你势力相同的角色受到过伤害的回合结束时，你可以令当前回合角色将所有手牌（至少一张）当【万箭齐发】使用。",

	["heg_shibao"] = "石苞-国",
    ["&heg_shibao"] = "石苞",
    ["#heg_shibao"] = "经国之才",
    ["~heg_shibao"] = "",
    ["designer:heg_shibao"] = "",
    ["cv:heg_shibao"] = "",
    ["illustrator:heg_shibao"] = "凝聚永恒",
	["heg_zhuosheng"] = "擢升",
  	[":heg_zhuosheng"] = "当你得到牌后，你可以令你本回合使用的下一张牌的伤害值基数+1（不能叠加）。",

	["heg_yanghuiyu"] = "羊徽瑜-国",
    ["&heg_yanghuiyu"] = "羊徽瑜",
    ["#heg_yanghuiyu"] = "克明礼教",
    ["~heg_yanghuiyu"] = "",
    ["designer:heg_yanghuiyu"] = "",
    ["cv:heg_yanghuiyu"] = "",
    ["illustrator:heg_yanghuiyu"] = "Jzeo",
	["heg_ciwei"] = "慈威",
  	[":heg_ciwei"] = "你的回合内，当其他角色使用牌时，若场上有本回合使用或打出过牌且不与其势力相同的其他角色，你可以弃置一张牌令此牌无效（取消所有目标）。",

	["heg_wangyuanji"] = "王元姬-国",
    ["&heg_wangyuanji"] = "王元姬",
    ["#heg_wangyuanji"] = "垂心万物",
    ["~heg_wangyuanji"] = "",
    ["designer:heg_wangyuanji"] = "",
    ["cv:heg_wangyuanji"] = "",
    ["illustrator:heg_wangyuanji"] = "六道目",
	["heg_yanxi"] = "宴戏",
  	[":heg_yanxi"] = "准备阶段，你可以选择至多三名其他势力的角色各一张手牌，这些角色依次声明一个牌名，然后你展示并获得其中一张牌，若获得的牌与其声明的牌名不同，你再获得其余被选择的牌。",
	["heg_shiren"] = "识人",
  	[":heg_shiren"] = "每回合限一次，当一名未确定势力的其他角色受到伤害后，你可以交给其两张牌并摸两张牌。",

	["heg_weiguan"] = "卫瓘-国",
    ["&heg_weiguan"] = "卫瓘",
    ["#heg_weiguan"] = "忠允清识",
    ["~heg_weiguan"] = "",
    ["designer:heg_weiguan"] = "",
    ["cv:heg_weiguan"] = "",
    ["illustrator:heg_weiguan"] = "Karneval",
	["heg_chengxi"] = "乘隙",
  	[":heg_chengxi"] = "准备阶段，你可以令一名角色视为使用一张【以逸待劳】，结算结束后，若因此【以逸待劳】弃置的牌中包含非基本牌，此【以逸待劳】的使用者对目标各造成1点伤害。",
	["heg_jiantong"] = "监统",
  	[":heg_jiantong"] = "当你受到伤害后，你可以观看一名角色的手牌，然后你可以用装备区内的一张牌交换其中至多两张牌。",

	["heg_jiachong"] = "贾充-国",
    ["&heg_jiachong"] = "贾充",
    ["#heg_jiachong"] = "悖逆篡弑",
    ["~heg_jiachong"] = "",
    ["designer:heg_jiachong"] = "",
    ["cv:heg_jiachong"] = "",
    ["illustrator:heg_jiachong"] = "游漫美绘",
	["heg_chujue"] = "除绝",
  	[":heg_chujue"] = "锁定技，你对有角色死亡的势力的角色使用牌无次数限制且不能被这些角色响应。",
	["heg_jianzhi"] = "奸志",
  	[":heg_jianzhi"] = "当你造成致命伤害时，你可以弃置所有手牌（至少一张），然后本回合下次击杀奖励改为三倍。",

	["heg_guohuaij"] = "郭槐-国",
    ["&heg_guohuaij"] = "郭槐",
    ["#heg_guohuaij"] = "嫉贤妒能",
    ["~heg_guohuaij"] = "",
    ["designer:heg_guohuaij"] = "",
    ["cv:heg_guohuaij"] = "",
    ["illustrator:heg_guohuaij"] = "凝聚永恒",
	["heg_zhefu"] = "哲妇",
  	[":heg_zhefu"] = "当你于回合外使用或打出基本牌后，你可以观看一名同势力角色数不小于你的角色的手牌，然后你可以弃置其中一张基本牌。",
	["heg_yidu"] = "遗毒",
  	[":heg_yidu"] = "当你使用伤害类牌后，你可以展示一名未受到此牌伤害的目标角色至多两张手牌，若颜色均相同，你弃置这些牌。",

	["heg_wangjun"] = "王濬-国",
    ["&heg_wangjun"] = "王濬",
    ["#heg_wangjun"] = "顺流长驱",
    ["~heg_wangjun"] = "",
    ["designer:heg_wangjun"] = "",
    ["cv:heg_wangjun"] = "",
    ["illustrator:heg_wangjun"] = "荆芥",
	["heg_chengliu"] = "乘流",
  	[":heg_chengliu"] = "出牌阶段限一次，你可以对一名装备区牌数小于你的角色造成1点伤害，然后你可以与其交换装备区的所有牌并重复此流程。",

	["heg_malong"] = "马隆-国",
    ["&heg_malong"] = "马隆",
    ["#heg_malong"] = "困局诡阵",
    ["~heg_malong"] = "",
    ["designer:heg_malong"] = "",
    ["cv:heg_malong"] = "",
    ["illustrator:heg_malong"] = "荆芥",
	["heg_zhuanzhan"] = "转战",
  	[":heg_zhuanzhan"] = "锁定技，若场上有未确定势力的角色，你使用【杀】无距离限制且不能指定未确定势力的角色为目标。",
	["heg_xunjim"] = "勋济",
  	[":heg_xunjim"] = "你使用【杀】可以多选择至多两名角色为目标，此【杀】结算结束后，若对所有目标角色均造成伤害，此【杀】不计次数。",


	--金印紫授
	["heg_zhanghuyuechen"] = "张虎乐綝-国",
    ["&heg_zhanghuyuechen"] = "张虎乐綝",
    ["#heg_zhanghuyuechen"] = "文成武德",
    ["~heg_zhanghuyuechen"] = "",
    ["designer:heg_zhanghuyuechen"] = "",
    ["cv:heg_zhanghuyuechen"] = "",
    ["illustrator:heg_zhanghuyuechen"] = "凝聚永恒",
	["heg_xijue"] = "袭爵",
  	[":heg_xijue"] = "你可以弃置一张牌以发动〖突袭〗或〖骁果〗。",
	["heg_lvxian"] = "履险",
  	[":heg_lvxian"] = "主将技，当你每回合首次受到伤害后，若执行上回合的角色不为你，你可以摸X张牌（X为你上回合失去的牌数）。",
	["heg_yingwei"] = "盈威",
  	[":heg_yingwei"] = "副将技，结束阶段，若你本回合造成伤害数等于摸牌数，你可以重铸至多两张牌。",

	["heg_wenyang"] = "文鸯-国",
    ["&heg_wenyang"] = "文鸯",
    ["#heg_wenyang"] = "勇冠三军",
    ["~heg_wenyang"] = "",
    ["designer:heg_wenyang"] = "",
    ["cv:heg_wenyang"] = "",
    ["illustrator:heg_wenyang"] = "小罗没想好",	
	["heg_duanqiu"] = "断虬",
  	[":heg_duanqiu"] = "准备阶段，你可以选择一个其他势力，视为对该势力的所有角色使用一张【决斗】，此牌结算后，你令所有角色本回合内至多共计再使用X张手牌（X为此【决斗】结算过程中打出的【杀】数量）。",

	["heg_yanghu"] = "羊祜-国",
    ["&heg_yanghu"] = "羊祜",
    ["#heg_yanghu"] = "静水沧笙",
    ["~heg_yanghu"] = "",
    ["designer:heg_yanghu"] = "",
    ["cv:heg_yanghu"] = "",
    ["illustrator:heg_yanghu"] = "白",
	["heg_huaiyuan"] = "怀远",
    [":heg_huaiyuan"] = "与你势力相同角色的准备阶段，你可以令其以下项于本回合数值+1: 1.攻击范围；2.手牌上限；3.使用【杀】的次数上限。",
	["heg_fushou"] = "付授",
  	[":heg_fushou"] = "锁定技，与你势力相同的角色无视主副将条件拥有其武将牌上的所有主将技和副将技（计算阴阳鱼的效果除外）。",

	["heg_yangjun"] = "杨骏-国",
    ["&heg_yangjun"] = "杨骏",
    ["#heg_yangjun"] = "阶缘佞宠",
    ["~heg_yangjun"] = "",
    ["designer:heg_yangjun"] = "",
    ["cv:heg_yangjun"] = "",
    ["illustrator:heg_yangjun"] = "荆芥",
	["heg_neiji"] = "内忌",
  	[":heg_neiji"] = "出牌阶段开始时，你可以选择一名其他势力角色，与其同时展示两张手牌，若如此做，你与其依次弃置以此法展示的【杀】，若以此法弃置【杀】的数量：大于1，你与其各摸三张牌；为1，以此法未弃置【杀】的角色视为对以此法弃置【杀】的角色使用一张【决斗】。",

	["heg_bailingyun"] = "柏夫人-国",
    ["&heg_bailingyun"] = "柏夫人",
    ["#heg_bailingyun"] = "玲珑心窍",
    ["~heg_bailingyun"] = "",
    ["designer:heg_bailingyun"] = "",
    ["cv:heg_bailingyun"] = "",
    ["illustrator:heg_bailingyun"] = "小罗没想好",
	["heg_xiace"] = "黠策",
	[":heg_xiace"] = "若当前回合角色有【杀】的剩余使用次数，你可以将一张牌当【无懈可击】使用，" ..
    "并令当前回合角色【杀】的剩余使用次数-1，然后你可以变更副将。",
	["heg_limeng"] = "离梦",
  	[":heg_limeng"] = "结束阶段，你可以弃置一张非基本牌并选择场上两张珠联璧合的武将牌，" ..
    "若不为同一名角色的武将，则这些角色分别对另一名角色造成1点伤害。",

	["heg_wangxiang"] = "王祥-国",
    ["&heg_wangxiang"] = "王祥",
    ["#heg_wangxiang"] = "沂川跃鲤",
    ["~heg_wangxiang"] = "",
    ["designer:heg_wangxiang"] = "",
    ["cv:heg_wangxiang"] = "",
    ["illustrator:heg_wangxiang"] = "KY",
	["heg_bingxin"] = "冰心",
  	[":heg_bingxin"] = "若你手牌的数量等于体力值且颜色相同，你可以展示手牌（无则跳过）并摸一张牌，视为使用一张本回合未以此法使用过牌名的基本牌。",

	["heg_sunxiu"] = "孙秀-国",
    ["&heg_sunxiu"] = "孙秀",
    ["#heg_sunxiu"] = "黄钟毁弃",
    ["~heg_sunxiu"] = "",
    ["designer:heg_sunxiu"] = "",
    ["cv:heg_sunxiu"] = "",
    ["illustrator:heg_sunxiu"] = "荆芥",
	["heg_xiejian"] = "挟奸",
    [":heg_xiejian"] = "出牌阶段限一次，你可以对一名其他角色发起“军令”，且你以此法抽取的备选“军令”对其他角色不可见，若其不执行，其强制执行你抽取的备选“军令”。",
	["heg_yinsha"] = "引杀",
  	[":heg_yinsha"] = "你可以将所有手牌当【借刀杀人】使用，此牌目标必须使用【杀】或将所有手牌当【杀】使用以响应此牌。",

	["heg_duyu"] = "杜预-国",
    ["&heg_duyu"] = "杜预",
    ["#heg_duyu"] = "文成武德",
    ["~heg_duyu"] = "",
    ["designer:heg_duyu"] = "",
    ["cv:heg_duyu"] = "",
    ["illustrator:heg_duyu"] = "君桓文化",
	["heg_sanchen"] = "三陈",
  	[":heg_sanchen"] = "出牌阶段，对每名角色限一次，若你的武将牌均明置，你可令一名角色摸三张牌然后弃置三张牌，若其因此弃置了类别相同的牌，你暗置此武将牌。",
	["heg_pozhu"] = "破竹",
  	[":heg_pozhu"] = "主将技，你计算体力上限时减少1个单独的阴阳鱼。准备阶段，你可以将一张牌当【杀】使用，"..
    "结算后你展示唯一目标一张手牌，若两张牌花色不同，你可以重复此流程。",


	
	["heg_lordliubei"] = "君刘备-国",
    ["&heg_lordliubei"] = "君刘备",
    ["#heg_lordliubei"] = "龙横蜀汉",
    ["~heg_lordliubei"] = "",
    ["designer:heg_lordliubei"] = "",
    ["cv:heg_lordliubei"] = "",
    ["illustrator:heg_lordliubei"] = "",
	["heg_lord_zhangwu"] = "章武",
  	[":heg_lord_zhangwu"] = "锁定技，当【飞龙夺凤】进入弃牌堆或其他角色的装备区后，你获得之。当你失去【飞龙夺凤】前，展示之，然后将此牌置于牌堆底并摸两张牌。",
	["heg_lord_shouyue"] = "君主技，你拥有“五虎将大旗”。",
	[":heg_lord_shouyue"] = "君主技，你拥有“五虎将大旗”。\
	“五虎将大旗”：存活的蜀势力角色的技能按如下规则改动——\
	〖武圣〗：将“红色牌”改为“任意牌”；\
	〖咆哮〗：增加描述“你使用的【杀】无视其他角色的防具”；\
	〖龙胆〗：增加描述“你每发动一次〖龙胆〗便摸一张牌”；\
	〖铁骑〗：将“一张明置的武将牌的非锁定技失效”改为“所有明置的武将牌的非锁定技失效”；\
	〖烈弓〗：增加描述“你的攻击范围+1”。",
	["heg_lord_jizhao"] = "激诏",
  	[":heg_lord_jizhao"] = "限定技，当你处于濒死状态时，你可以将手牌补至体力上限，体力回复至2点，失去〖授钺〗并获得〖仁德〗。",
	--飞龙夺凤♤2
	--当你使用【杀】指定一名角色为目标后，你可以令其弃置一张牌；你使用【杀】令一名角色进入濒死状态时，你可以获得其一张牌。

	["heg_lordzhangjiao"] = "君张角-国",
    ["&heg_lordzhangjiao"] = "君张角",
    ["#heg_lordzhangjiao"] = "时代的先驱",
    ["~heg_lordzhangjiao"] = "",
    ["designer:heg_lordzhangjiao"] = "",
    ["cv:heg_lordzhangjiao"] = "",
    ["illustrator:heg_lordzhangjiao"] = "",
	["heg_lord_hongfa"] = "弘法",
  	[":heg_lord_hongfa"] = "君主技，你拥有“黄巾天兵符”。准备阶段，若“黄巾天兵符”上没有牌，你将牌堆顶的X张牌置于“黄巾天兵符”上，称为“天兵”（X为存活群势力角色数）。\
	“黄巾天兵符”：1.当你计算群势力角色数时，每一张“天兵”均可视为一名群势力角色。2.当你失去体力前，你可以改为将一张“天兵”置入弃牌堆。3.与你势力相同的角色可以将一张“天兵”当【杀】使用或打出。",
	["heg_lord_wuxin"] = "悟心",
  	[":heg_lord_wuxin"] = "摸牌阶段开始时，你可以观看牌堆顶的X张牌（X为存活群势力角色数），然后将这些牌以任意顺序置于牌堆顶。",
	["heg_lord_wendao"] = "问道",
  	[":heg_lord_wendao"] = "出牌阶段限一次，你可以弃置一张红色牌，然后从弃牌堆或场上获得【太平要术】。",

	["heg_lordsunquan"] = "君孙权-国",
    ["&heg_lordsunquan"] = "君孙权",
    ["#heg_lordsunquan"] = "虎踞江东",
    ["~heg_lordsunquan"] = "",
    ["designer:heg_lordsunquan"] = "",
    ["cv:heg_lordsunquan"] = "",
    ["illustrator:heg_lordsunquan"] = "",
	["heg_lord_jiahe"] = "嘉禾",
  	[":heg_lord_jiahe"] = "君主技，你拥有“缘江烽火图”。\
	“缘江烽火图”：1.每名吴势力角色的出牌阶段限一次，其可以将一张装备牌置于“缘江烽火图”上，称为“烽火”。 2.根据“烽火”的数量，所有吴势力角色可以于其准备阶段选择并获得其中一个技能直到回合结束：至少一张，〖英姿〗；至少两张，〖好施〗；至少三张，〖涉猎〗；至少四张，〖度势〗；至少五张，可多选择一个技能。 3.锁定技，当你受到【杀】或锦囊牌造成的伤害后，你将一张“烽火”置入弃牌堆。",
	["heg_lord_lianzi"] = "敛资",
  	[":heg_lord_lianzi"] = "出牌阶段限一次，你可以弃置一张手牌，然后亮出牌堆顶的X张牌（X为吴势力角色装备区里的牌数和“烽火”数之和），获得其中所有与你弃置牌类别相同的牌。若此次获得的牌数大于3，你失去〖敛资〗并获得〖制衡〗。",
	["heg_lord_jubao"] = "聚宝",
  	[":heg_lord_jubao"] = "锁定技，你装备区里的宝物牌不能被其他角色获得。结束阶段，若场上或弃牌堆中有【定澜夜明珠】，你摸一张牌，然后获得装备区里有【定澜夜明珠】角色的一张牌。",
	--定澜夜明珠♢6
	--锁定技，若你未拥有“制衡”，你获得“制衡”；若你拥有不以此法获得的“制衡”，则取消“制衡”牌数限制。

	["heg_lordcaocao"] = "君曹操-国",
    ["&heg_lordcaocao"] = "君曹操",
    ["#heg_lordcaocao"] = "凤舞九天",
    ["~heg_lordcaocao"] = "",
    ["designer:heg_lordcaocao"] = "",
    ["cv:heg_lordcaocao"] = "",
    ["illustrator:heg_lordcaocao"] = "",
	["heg_lord_jianan"] = "建安",
	[":heg_lord_jianan"] = "君主技，你拥有“五子良将纛”。\
	“五子良将纛”：魏势力角色的准备阶段，该角色可以弃置一张牌并选择自己暗置的一张武将牌（没有暗置的武将牌则选择一张暗置），然后获得以下技能之一直到你下回合开始：〖突袭〗、〖巧变〗、〖骁果〗、〖节钺〗、〖断粮〗。场上角色已有的技能无法选择，且在此期间该角色不能明置因此选择的武将牌。",
	["heg_lord_huibian"] = "挥鞭",
  	[":heg_lord_huibian"] = "出牌阶段限一次，你可以选择一名魏势力角色和另一名已受伤的魏势力角色，你对前者造成1点伤害并令其摸两张牌，然后令后者回复1点体力。",
	["heg_lord_zongyu"] = "总御",
  	[":heg_lord_zongyu"] = "当【六龙骖驾】进入其他角色装备区后，你可以用你装备区里的所有坐骑牌（至少一张）交换【六龙骖驾】；当你使用坐骑牌时，若场上或弃牌堆中有【六龙骖驾】，你将此牌置入你的装备区。",
	--六龙骖驾♡K
	--锁定技，你与其他角色距离-1；其他角色与你距离+1；此牌置入你的装备区后，将你装备区其他坐骑牌置入弃牌堆；若此牌在你的装备牌，你不能使用其他坐骑牌且所有角色不能将坐骑牌置入你的装备区。

	["heg_lordsimayi"] = "君司马懿-国",
    ["&heg_lordsimayi"] = "君司马懿",
    ["#heg_lordsimayi"] = "时代的归墟",
    ["~heg_lordsimayi"] = "",
    ["designer:heg_lordsimayi"] = "",
    ["cv:heg_lordsimayi"] = "",
    ["illustrator:heg_lordsimayi"] = "",
	["heg_jiaping"] = "嘉平",
  	[":heg_jiaping"] = "<b><font color='goldenrod'>君主技</font></b>，你拥有“八荒死士令”。<br>#<b>八荒死士令</b>：每轮限一次，所有本轮明置过武将牌的晋势力角色可以移除其副将的武将牌并发动以下一个未以此法发动过的技能：“瞬覆”，“奉迎”，“将略”，“勇进”和“乱武”。",
	["heg_guikuang"] = "诡诳",
  	[":heg_guikuang"] = "出牌阶段限一次，你可以选择两名势力各不相同的角色，令这两名角色拼点，然后拼点牌为红色的角色依次对拼点没赢的角色造成1点伤害。",
	["heg_shujuan"] = "舒卷",
  	[":heg_shujuan"] = "锁定技，当每回合【戢鳞潜翼】首次置入弃牌堆或其他角色装备区后，你获得并使用之。",
	--戢鳞潜翼黑桃6 攻击范围X
	--你使用【杀】的结算过程中，你攻击范围内的非目标角色不能使用牌（X为你的已损失的体力值）。




	["heg_mobile_zhanglu"] = "张鲁-国[手杀]",
    ["&heg_mobile_zhanglu"] = "张鲁",
    ["#heg_mobile_zhanglu"] = "政宽教惠",
    ["~heg_mobile_zhanglu"] = "",
    ["designer:heg_mobile_zhanglu"] = "",
    ["cv:heg_mobile_zhanglu"] = "",
    ["illustrator:heg_mobile_zhanglu"] = "磐蒲",
	["heg_mobile_bushi"] = "布施",
  	[":heg_mobile_bushi"] = "回合结束时，你获得X枚“义舍”；其他角色的准备阶段，你可以弃1枚“义舍”，然后交给其一张牌并摸两张牌；准备阶段，你弃置Y-2张牌并移去所有“义舍”标记（X为你的体力值，Y为存活角色数-你的体力值）。",
	["heg_mobile_midao"] = "米道",
  	[":heg_mobile_midao"] = "结束阶段，若你没有“米”，你可以摸两张牌，然后将两张牌置于你的武将牌上，称为“米”；当一名角色的判定牌生效前，你可以打出一张“米”替换之。",

	["heg_mobile_xushu"] = "徐庶-国[手杀]",
    ["&heg_mobile_xushu"] = "徐庶",
    ["#heg_mobile_xushu"] = "难为完臣",
    ["~heg_mobile_xushu"] = "",
    ["designer:heg_mobile_xushu"] = "",
    ["cv:heg_mobile_xushu"] = "",
    ["illustrator:heg_mobile_xushu"] = "YanBai",
	["heg_mobile_zhuhai"] = "诛害",
	[":heg_mobile_zhuhai"] = "其他角色的结束阶段，若其本回合造成过伤害，你可以对其使用一张【杀】。若其本回合对与你势力相同的角色造成过伤害，此【杀】无视其防具，且当其使用【闪】响应此【杀】后，其弃置一张牌。",
	["heg_mobile_jiancai"] = "荐才",
  	[":heg_mobile_jiancai"] = "每轮开始时，你获知的未登场同势力武将牌增加至X张（X为轮次数的三倍）。当与你势力相同的角色受到致命伤害时，你可以防止此伤害，然后你变更副将；若你所属的势力不为唯一大势力，此次变更副将你可以优先从你获知的武将中选择。",

	["heg_mobile_zhonghui"] = "钟会-国[手杀]",
    ["&heg_mobile_zhonghui"] = "钟会",
    ["#heg_mobile_zhonghui"] = "桀骜的野心家",
    ["~heg_mobile_zhonghui"] = "",
    ["designer:heg_mobile_zhonghui"] = "韩旭",
    ["cv:heg_mobile_zhonghui"] = "",
    ["illustrator:heg_mobile_zhonghui"] = "磐蒲",
	["heg_mobile_paiyi"] = "排异",
  	[":heg_mobile_paiyi"] = "出牌阶段限两次，你可以移去一张“权”并令一名角色摸两张牌。若其手牌多于你，你对其造成1点伤害。",

	["heg_fk_zhanglu"] = "张鲁-国[新月]",
    ["&heg_fk_zhanglu"] = "张鲁",
    ["#heg_fk_zhanglu"] = "政宽教惠",
    ["~heg_fk_zhanglu"] = "",
    ["designer:heg_fk_zhanglu"] = "",
    ["cv:heg_fk_zhanglu"] = "",
    ["illustrator:heg_fk_zhanglu"] = "磐蒲",
	["heg_fk_bushi"] = "布施",
  	[":heg_fk_bushi"] = "一名角色的结束阶段，若你于此回合内造成或受到过伤害，你可移去一张“米”，令至多X名角色各摸一张牌（X为你的体力上限），以此法摸牌的角色可依次将一张牌置于你武将牌上，称为“米”。",
    ["heg_fk_midao"] = "米道",
  	[":heg_fk_midao"] = "①游戏开始时，你摸两张牌，然后将两张牌置于武将牌上，称为“米”②一名角色的判定牌生效前，你可以打出一张“米”替换之。",

	["heg_true_xushu"] = "徐庶-国[萌剪]",
    ["&heg_true_xushu"] = "徐庶",
    ["#heg_true_xushu"] = "难为完臣",
    ["~heg_true_xushu"] = "",
    ["designer:heg_true_xushu"] = "",
    ["cv:heg_true_xushu"] = "",
    ["illustrator:heg_true_xushu"] = "YanBai",
	["heg_true_zhuhai"] = "诛害",
	[":heg_true_zhuhai"] = "一名其他角色的结束阶段开始时，若该角色本回合造成过伤害，你可以对其使用一张【杀】（无距离限制）。",
	["heg_true_pozhen"] = "破阵",
  	[":heg_true_pozhen"] = "限定技，其他角色的回合开始时，你可以令其本回合不可使用、打出或重铸手牌；若其处于队列或围攻关系中，你可依次弃置此队列或参与围攻关系的其他角色的一张牌。",
	["heg_true_jiancai"] = "荐才",
  	[":heg_true_jiancai"] = "你势力相同的角色即将受到伤害而进入濒死状态时，你可以防止此伤害，若如此做，你须变更副将；与你势力相同的角色变更副将时，你可令其额外获得两张备选武将牌。",



}

return {extension, extension_heg, extension_hegbian, extension_hegquan, extension_heglordex,extension_guandu, extension_twyj}