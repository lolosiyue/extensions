extension = sgs.Package("extra", sgs.Package_GeneralPack)
extension_guandu = sgs.Package("fixandadd_guandu", sgs.Package_GeneralPack)
extension_twyj = sgs.Package("fixandadd_twyj", sgs.Package_GeneralPack)
require "ExtraTurnUtils"

local Guandu_event_only = false --OL官渡之战随机事件
local Guandu_event_reward = false 

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

function Table2IntList(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

function SendComLog(self, player, n, invoke)
	if invoke == nil then invoke = true end
	if invoke then
		player:getRoom():sendCompulsoryTriggerLog(player, self:objectName())
		player:getRoom():broadcastSkillInvoke(self:objectName(), n)
	end
end
function ChoiceLog(player, choice, to, skillName)
	local log = sgs.LogMessage()
	log.type = "#choice"
	log.from = player
	
	-- Don't translate in Lua (encoding issue), send the key and let C++ translate it
	-- Check if skillName:choice translation exists
	if skillName then
		local full_key = skillName .. ":" .. choice
		local full_translated = sgs.Sanguosha:translate(full_key)
		-- If translation exists for skillName:choice, send the full key
		if full_translated ~= full_key then
			log.arg = full_key
		else
			-- Otherwise just send the choice
			log.arg = choice
		end
	else
		log.arg = choice
	end
	
	if to then
		log.to:append(to)
	end
	player:getRoom():sendLog(log)
end

-- 通用明置牌机制 (Universal Card Display Mechanism)
-- 用于将手牌明置为可见的虚拟牌堆，所有玩家可见可查看，但不进行真实的卡牌移动
-- 
-- 使用方法示例:
--   1. 明置手牌: UniversalCardDisplayMove(ids_list, true, player, "myskill")
--   2. 取消明置: UniversalCardDisplayMove(ids_list, false, player, "myskill")
--
-- 注意: 
--   - property_name固定为"display_cards"，所有明置牌统一使用此property存储
--   - 不要在调用后手动setPlayerProperty，函数内部已自动处理
--   - 必须配合universal_card_display_global触发器使用，自动清理离开手牌的卡牌
--
-- 参数:
--   ids: sgs.IntList 或 QList，要明置/取消明置的卡牌ID列表
--   movein: bool，true=显示为pile，false=取消显示
--   player: ServerPlayer，卡牌所属玩家
--   pile_name: string (可选)，显示牌堆名称，默认"cardshow"，建议用技能名
function UniversalCardDisplayMove(ids, movein, player, pile_name)
	local room = player:getRoom()
	pile_name = pile_name or "cardshow"  -- 技能名，仅用于cardTip
	local property_name = "display_cards"
	local unified_pile_name = "displayed"  -- 统一的pile显示名称
	
	if movein then
		-- 检查是否有卡牌已经是明置牌，过滤掉已明置的卡牌
		local existing_list = player:property(property_name):toString():split("+")
		local existing_set = {}
		for _, v in pairs(existing_list) do
			if v ~= "" then
				existing_set[tonumber(v)] = true
			end
		end
		
		-- 过滤出真正需要新增的卡牌
		local new_ids = sgs.IntList()
		for _, id in sgs.qlist(ids) do
			if not existing_set[id] then
				new_ids:append(id)
			end
		end
		
		-- 如果没有新卡牌需要明置，直接返回
		if new_ids:isEmpty() then
			return
		end
		
		-- 更新property，添加新卡牌
		local list = existing_list
		for _, id in sgs.qlist(new_ids) do
			table.insert(list, tostring(id))
		end
		-- 去重并去除空字符串
		local unique_list = {}
		local seen = {}
		for _, v in pairs(list) do
			if v ~= "" and not seen[v] then
				table.insert(unique_list, v)
				seen[v] = true
			end
		end
		room:setPlayerProperty(player, property_name, sgs.QVariant(table.concat(unique_list, "+")))
		
		-- 构建所有需要显示的卡牌ID列表
		local all_ids = sgs.IntList()
		for _, v in pairs(unique_list) do
			all_ids:append(tonumber(v))
		end
		
		-- 先清空旧的pile显示（如果有的话）
		if #unique_list > new_ids:length() then
			-- 不是第一次添加，需要先清空
			local old_ids = sgs.IntList()
			for _, v in pairs(unique_list) do
				local id_num = tonumber(v)
				local is_new = false
				for _, new_id in sgs.qlist(new_ids) do
					if id_num == new_id then
						is_new = true
						break
					end
				end
				if not is_new then
					old_ids:append(id_num)
				end
			end
			if not old_ids:isEmpty() then
				local clear_move = sgs.CardsMoveStruct(old_ids, player, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
					sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON, player:objectName(), "display", ""))
				clear_move.from_pile_name = unified_pile_name
				local clear_moves = sgs.CardsMoveList()
				clear_moves:append(clear_move)
				local all_players = room:getAllPlayers(true)
				room:notifyMoveCards(true, clear_moves, false, all_players)
				room:notifyMoveCards(false, clear_moves, false, all_players)
			end
		end
		
		-- 然后添加所有卡牌（包括新的和旧的）
		local move = sgs.CardsMoveStruct(all_ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName()))
		move.to_pile_name = unified_pile_name
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local all_players = room:getAllPlayers(true)
		room:notifyMoveCards(true, moves, false, all_players)
		room:notifyMoveCards(false, moves, false, all_players)
		
		-- 设置牌堆对所有玩家可见
		player:setPileOpen(unified_pile_name, ".")
		for _, p in sgs.qlist(all_players) do
			player:setPileOpen(unified_pile_name, p:objectName())
		end
		
		-- 设置卡牌标记（只为新增的卡牌设置tip，使用技能名）
		for _, id in sgs.qlist(new_ids) do
			room:setCardTip(id, pile_name)
		end
		
		-- 明置卡牌，让所有玩家看到牌面
		room:showCard(player, all_ids)
	else
		-- 从property中移除
		local list = player:property(property_name):toString():split("+")
		local new_list = {}
		for _, l in pairs(list) do
			local should_keep = true
			for _, id in sgs.qlist(ids) do
				if tonumber(l) == id then
					should_keep = false
					break
				end
			end
			if should_keep and l ~= "" then
				table.insert(new_list, l)
			end
		end
		
		-- 更新property
		local pattern = sgs.QVariant()
		if #new_list > 0 then
			pattern = sgs.QVariant(table.concat(new_list, "+"))
		end
		room:setPlayerProperty(player, property_name, pattern)
		
		-- 构建剩余卡牌列表
		local remaining_ids = sgs.IntList()
		for _, v in pairs(new_list) do
			remaining_ids:append(tonumber(v))
		end
		
		local all_players = room:getAllPlayers(true)
		
		-- 先清空整个pile
		local old_ids = sgs.IntList()
		for _, l in pairs(list) do
			if l ~= "" then
				old_ids:append(tonumber(l))
			end
		end
		if not old_ids:isEmpty() then
			local clear_move = sgs.CardsMoveStruct(old_ids, player, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
				sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON, player:objectName()))
				clear_move.from_pile_name = unified_pile_name
			room:notifyMoveCards(false, clear_moves, false, all_players)
			
			-- 清除被移除卡牌的tip
			for _, id in sgs.qlist(ids) do
				room:clearCardTip(id)
			end
		end
		
		-- 如果还有剩余卡牌，重新显示
		if not remaining_ids:isEmpty() then
			local move = sgs.CardsMoveStruct(remaining_ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName()))
			move.to_pile_name = unified_pile_name
			local moves = sgs.CardsMoveList()
			moves:append(move)
			room:notifyMoveCards(true, moves, false, all_players)
			room:notifyMoveCards(false, moves, false, all_players)
			
			-- 重新设置可见性
			player:setPileOpen(unified_pile_name, ".")
			for _, p in sgs.qlist(all_players) do
				player:setPileOpen(unified_pile_name, p:objectName())
			end
			
			-- 剩余卡牌的tip保持不变（不需要重新设置）
			
			-- 重新明置剩余卡牌
			room:showCard(player, remaining_ids)
		end
	end
end

-- 全局触发器：统一处理所有明置牌的清理和选择逻辑
universal_card_display_global = sgs.CreateTriggerSkill{
	name = "#universal_card_display_global",
	events = {sgs.CardsMoveOneTime, sgs.BeforeCardsMove},
	frequency = sgs.Skill_Compulsory,
	global = true,
	can_trigger = function(self, player)
		return player ~= nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			-- 检查卡牌是否从手牌离开
			if move.from then
				local prop_value = move.from:property("display_cards"):toString()
				if prop_value ~= "" then
					local list = prop_value:split("+")
					local to_remove = sgs.IntList()
					
					-- 遍历所有移动的卡牌，收集需要清理的明置牌
					for i = 0, move.card_ids:length() - 1 do
						local card_id = move.card_ids:at(i)
						local from_place = move.from_places:at(i)
						
						-- 只处理从手牌离开的卡牌
						if from_place == sgs.Player_PlaceHand then
							-- 检查这张卡是否在明置牌列表中
							for _, l in pairs(list) do
								if l ~= "" and tonumber(l) == card_id then
									to_remove:append(card_id)
									break
								end
							end
						end
					end
					
					-- 一次性清理所有需要移除的明置牌
					if not to_remove:isEmpty() then
						-- 获取ServerPlayer对象
						local from = room:findPlayerByObjectName(move.from:objectName())
						if not from then return false end
						
						-- 直接从property中移除这些卡牌
						local new_list = {}
						for _, l in pairs(list) do
							local should_keep = true
							for _, id in sgs.qlist(to_remove) do
								if tonumber(l) == id then
									should_keep = false
									break
								end
							end
							if should_keep and l ~= "" then
								table.insert(new_list, l)
							end
						end
						
						-- 更新property
						local pattern = sgs.QVariant()
						if #new_list > 0 then
							pattern = sgs.QVariant(table.concat(new_list, "+"))
						end
						room:setPlayerProperty(from, "display_cards", pattern)
						
						-- 清空整个pile并重建
						local all_players = room:getAllPlayers(true)
						local old_ids = sgs.IntList()
						for _, l in pairs(list) do
							if l ~= "" then
								old_ids:append(tonumber(l))
							end
						end
						
						if not old_ids:isEmpty() then
							local clear_move = sgs.CardsMoveStruct(old_ids, from, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
								sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON, from:objectName()))
							clear_move.from_pile_name = "displayed"
							local clear_moves = sgs.CardsMoveList()
							clear_moves:append(clear_move)
							room:notifyMoveCards(true, clear_moves, false, all_players)
							room:notifyMoveCards(false, clear_moves, false, all_players)
							
							-- 清除被移除卡牌的tip
							for _, id in sgs.qlist(to_remove) do
								room:clearCardTip(id)
							end
						end
						
						-- 如果还有剩余卡牌，重新显示
						if #new_list > 0 then
							local remaining_ids = sgs.IntList()
							for _, v in pairs(new_list) do
								remaining_ids:append(tonumber(v))
							end
							
							local rebuild_move = sgs.CardsMoveStruct(remaining_ids, nil, from, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
								sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, from:objectName()))
							rebuild_move.to_pile_name = "displayed"
							local moves = sgs.CardsMoveList()
							moves:append(rebuild_move)
							room:notifyMoveCards(true, moves, false, all_players)
							room:notifyMoveCards(false, moves, false, all_players)
							
							-- 重新设置可见性
							from:setPileOpen("displayed", ".")
							for _, p in sgs.qlist(all_players) do
								from:setPileOpen("displayed", p:objectName())
							end
							
							-- 重新明置剩余卡牌
							room:showCard(from, remaining_ids)
						end
					end
				end
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			local source = move.reason.m_playerId
			-- 当其他角色获得此玩家的手牌时，处理明置牌的选择逻辑
			if source and move.from and move.from:objectName() ~= source and player:objectName() == source
				and move.from_places:contains(sgs.Player_PlaceHand) and move.reason.m_skillName ~= "longqi"
				and not(room:getTag("Dongchaer"):toString() == player:objectName()
				and room:getTag("Dongchaee"):toString() == move.from:objectName()) then
				local list = move.from:property("display_cards"):toString():split("+")
				if #list > 0 then
					if #list == 1 and move.from:getHandcards():length() == 1 then return false end
					local ids = sgs.IntList()
					for _,l in pairs(list) do
						ids:append(tonumber(l))
					end
					local to_move = move.card_ids
					local invisible_hands = move.from:getHandcards()
					for _,k in sgs.qlist(move.from:getHandcards()) do
						if ids:contains(k:getId()) then
							invisible_hands:removeOne(k)
						end
					end
					-- 如果所有手牌都是明置的
					if invisible_hands:length() == 0 then
						local poi = ids
						for _,x in sgs.qlist(move.card_ids) do
							if ids:contains(x) then
								room:fillAG(poi)
								local id = room:askForAG(player, poi, false, "display_cards")
								if id ~= -1 then
									to_move:append(id)
									to_move:removeOne(x)
									poi:removeOne(id)
								end
								room:clearAG()
							end
						end
					else
						-- 混合明置牌和暗牌的情况
						local hands = sgs.IntList()
						for _,i in sgs.qlist(move.card_ids) do
							if room:getCardPlace(i) == sgs.Player_PlaceHand then
								if ids:contains(i) then
									local rand = invisible_hands:at(math.random(0, invisible_hands:length() - 1)):getId()
									to_move:append(rand)
									to_move:removeOne(i)
									i = rand
								end
								hands:append(i)
							end
						end
						if hands:length() == move.from:getHandcardNum() or hands:length() == 0 then return false end
						local view = ids
						for _,j in sgs.qlist(hands) do
							if view:length() == 0 then break end
							local choice = room:askForChoice(player, "display_cards", "displaypile+displayhand", data)
							if choice == "displaypile" then
								if view:length() == 1 then
									local id = view:first()
									to_move:append(id)
									to_move:removeOne(j)
									view:removeOne(id)
								else
									room:fillAG(view)
									local id = room:askForAG(player, view, false, "display_cards")
									if id ~= -1 then
										to_move:append(id)
										to_move:removeOne(j)
										view:removeOne(id)
									end
									room:clearAG()
								end
							else
								break
							end
						end
					end
					local bools = sgs.BoolList()
					for _,t in sgs.qlist(to_move) do
						bools:append(ids:contains(t))
					end
					move.card_ids = to_move
					move.open = bools
					data:setValue(move)
				end
			end
		end
	end
}


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
					room:addPlayerMark(player, "usedPlay-Clear")
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

RemoveFromHistoryAndIgnoreArmorLog = sgs.CreateTriggerSkill{
	name = "RemoveFromHistoryAndIgnoreArmorLog",
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
		for _, skill_name in sgs.qlist(use.card:getSkillNames()) do
			if string.find(skill_name, "RemoveFromHistory") then
				local name = skill_names:split("_")[1]
				use.card:setSkillName(name)
				use.m_addHistory = false
				data:setValue(use)
				break
			end
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
if not sgs.Sanguosha:getSkill("RemoveFromHistoryAndIgnoreArmorLog") then skills:append(RemoveFromHistoryAndIgnoreArmorLog) end
if not sgs.Sanguosha:getSkill("universal_card_display_global") then skills:append(universal_card_display_global) end

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

--[[
	技能名：虎翼
	技能描述：你使用【杀】对目标造成属性伤害时，你可以横置至多两名角色。
	引用：sfofl_yice

    --徐荣礼盒
]] --

sijyuoffline_huyi_skill = sgs.CreateTriggerSkill{
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
sijyuoffline_huyi:setParent(extension)



--[[
-- God Sun Quan [OL]
ol_god_sunquan = sgs.General(extension, "ol_god_sunquan", "god", 4, true)

-- Fate lines data structure
local fate_lines = {
	{name = "line1", skills = {"yinghun", "hongde", "bingyi"}},
	{name = "line2", skills = {"guanwei", "bizheng", "anguo"}},
	{name = "line3", skills = {"shelie", "wengua", "botu"}},
	{name = "line4", skills = {"zhiheng", "jie xun", "anxu"}},
	{name = "line5", skills = {"xiashu", "jieyin", "dimeng"}},
	{name = "line6", skills = {"guanchao", "jueyan", "lanjiang"}}
}

local fate_line_meta_skills = {
	line1 = "ol_god_shengzhi",
	line2 = "ol_god_chigang",
	line3 = "ol_god_qionglan",
	line4 = "ol_god_quandao",
	line5 = "ol_god_jiaohui",
	line6 = "ol_god_yuanlu"
}

-- 帝力 (Dili) - Locked skill, randomly open one fate line at game start
ol_god_dili = sgs.CreateTriggerSkill{
	name = "ol_god_dili",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart then
			-- Randomly select a fate line
			local line_num = math.random(1, 6)
			room:setPlayerMark(player, "ol_god_dili_line" .. line_num, 1)
			room:setPlayerMark(player, "&fate_line" .. line_num, 1)
			-- Acquire the meta skill for this line
			local meta_skill = fate_line_meta_skills["line" .. line_num]
			if meta_skill then
				room:acquireSkill(player, meta_skill, false, false, false)
			end
		end
		return false
	end
}

-- 驭衡 (Yuheng) - Complex skill management
ol_god_yuheng = sgs.CreateTriggerSkill{
	name = "ol_god_yuheng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			room:setPlayerMark(player, "ol_god_yuheng_used", 0)
			room:setPlayerMark(player, "ol_god_other_skill_used", 0)
			
			if room:askForSkillInvoke(player, self:objectName()) then
				room:setPlayerMark(player, "ol_god_yuheng_used", 1)
				
				-- Lose all non-locked skills
				local skills_to_remove = {}
				for _, skill in sgs.list(player:getVisibleSkillList()) do
					local skill_name = skill:objectName()
					if skill:getFrequency() ~= sgs.Skill_Compulsory and 
					   not skill_name:startsWith("#") and 
					   not skill_name:startsWith("ol_god_dili") and
					   not skill_name:startsWith("ol_god_yuheng") and
					   not skill_name:startsWith("ol_god_shengzhi") and
					   not skill_name:startsWith("ol_god_chigang") and
					   not skill_name:startsWith("ol_god_qionglan") and
					   not skill_name:startsWith("ol_god_quandao") and
					   not skill_name:startsWith("ol_god_jiaohui") and
					   not skill_name:startsWith("ol_god_yuanlu") then
						table.insert(skills_to_remove, skill_name)
					end
				end
				for _, skill_name in ipairs(skills_to_remove) do
					room:detachSkillFromPlayer(player, skill_name, true, false)
				end
				
				-- Gain a random skill from any fate line that hasn't been gained
				local all_skills = {}
				for _, line in ipairs(fate_lines) do
					for _, skill in ipairs(line.skills) do
						if room:getTag("ol_god_yuheng_gained_" .. skill):toInt() == 0 then
							table.insert(all_skills, skill)
						end
					end
				end
				
				if #all_skills == 0 then
					-- Reset if all skills have been gained
					for _, line in ipairs(fate_lines) do
						for _, skill in ipairs(line.skills) do
							room:setTag("ol_god_yuheng_gained_" .. skill, sgs.QVariant(0))
						end
					end
					all_skills = {}
					for _, line in ipairs(fate_lines) do
						for _, skill in ipairs(line.skills) do
							table.insert(all_skills, skill)
						end
					end
				end
				
				if #all_skills > 0 then
					local random_skill = all_skills[math.random(1, #all_skills)]
					room:acquireSkill(player, random_skill, false, false, false)
					room:setTag("ol_god_yuheng_gained_" .. random_skill, sgs.QVariant(1))
				end
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			if player:getMark("ol_god_yuheng_used") == 0 then
				-- Lose 1 HP if didn't use Yuheng this turn
				room:loseHp(player, 1)
			elseif player:getMark("ol_god_other_skill_used") == 0 then
				-- If used Yuheng but no other non-locked skills, gain extra skill from opened fate line
				for line_num = 1, 6 do
					if player:getMark("ol_god_dili_line" .. line_num) > 0 then
						local line = fate_lines[line_num]
						local line_skills = {}
						for _, skill in ipairs(line.skills) do
							if room:getTag("ol_god_yuheng_line" .. line_num .. "_gained_" .. skill):toInt() == 0 then
								table.insert(line_skills, skill)
							end
						end
						
						if #line_skills == 0 then
							-- Reset line skills
							for _, skill in ipairs(line.skills) do
								room:setTag("ol_god_yuheng_line" .. line_num .. "_gained_" .. skill, sgs.QVariant(0))
							end
							line_skills = {}
							for _, skill in ipairs(line.skills) do
								table.insert(line_skills, skill)
							end
						end
						
						if #line_skills > 0 then
							local random_skill = line_skills[math.random(1, #line_skills)]
							room:acquireSkill(player, random_skill, false, false, false)
							room:setTag("ol_god_yuheng_line" .. line_num .. "_gained_" .. random_skill, sgs.QVariant(1))
						end
						break
					end
				end
			end
		end
		return false
	end
}

-- 圣质 (Shengzhi) - Cards with prime number cannot be responded if gained specific skills
ol_god_shengzhi = sgs.CreateTriggerSkill{
	name = "ol_god_shengzhi",
	frequency = sgs.Skill_Compulsory,
	events = {},
	on_trigger = function(self, event, player, data, room)
		return false
	end
}

ol_god_shengzhi_prohibit = sgs.CreateProhibitSkill{
	name = "#ol_god_shengzhi_prohibit",
	is_prohibited = function(self, from, to, card)
		if not from:hasSkill("ol_god_shengzhi") then return false end
		-- Check if player has gained all three skills
		if from:hasSkill("yinghun") and from:hasSkill("hongde") and from:hasSkill("bingyi") then
			local number = card:getNumber()
			local primes = {2, 3, 5, 7, 11, 13}
			for _, p in ipairs(primes) do
				if number == p then
					return true
				end
			end
		end
		return false
	end
}

-- 持纲 (Chigang) - Change judge phase to draw phase if gained specific skills
ol_god_chigang = sgs.CreateTriggerSkill{
	name = "ol_god_chigang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data, room)
		if player:hasSkill("guanwei") and player:hasSkill("bizheng") and player:hasSkill("anguo") then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Judge then
				player:skip(sgs.Player_Judge)
				player:insertPhase(sgs.Player_Draw)
			end
		end
		return false
	end
}

-- 穹览 (Qionglan) - Open two other random fate lines if gained specific skills
ol_god_qionglan = sgs.CreateTriggerSkill{
	name = "ol_god_qionglan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AcquireSkill},
	on_trigger = function(self, event, player, data, room)
		if player:hasSkill("shelie") and player:hasSkill("wengua") and player:hasSkill("botu") then
			if player:getMark("ol_god_qionglan_triggered") == 0 then
				room:setPlayerMark(player, "ol_god_qionglan_triggered", 1)
				-- Open two other random fate lines
				local unopened_lines = {}
				for i = 1, 6 do
					if player:getMark("ol_god_dili_line" .. i) == 0 then
						table.insert(unopened_lines, i)
					end
				end
				
				for i = 1, math.min(2, #unopened_lines) do
					local random_idx = math.random(1, #unopened_lines)
					local line_num = unopened_lines[random_idx]
					table.remove(unopened_lines, random_idx)
					room:setPlayerMark(player, "ol_god_dili_line" .. line_num, 1)
					room:setPlayerMark(player, "&fate_line" .. line_num, 1)
					local meta_skill = fate_line_meta_skills["line" .. line_num]
					if meta_skill then
						room:acquireSkill(player, meta_skill, false, false, false)
					end
				end
			end
		end
		return false
	end
}

-- 权道 (Quandao) - Letter number hand cards are viewed as Tiaojiyenmei
ol_god_quandao = sgs.CreateViewAsSkill{
	name = "ol_god_quandao",
	n = 0,
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self, cards)
		return nil
	end,
	enabled_at_play = function(self, player)
		return player:hasSkill("zhiheng") and player:hasSkill("jiexun") and player:hasSkill("anxu")
	end
}

-- 交辉 (Jiaohui) - Last hand card is viewed as Yuanjiaojingong
ol_god_jiaohui = sgs.CreateViewAsSkill{
	name = "ol_god_jiaohui",
	n = 0,
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self, cards)
		return nil
	end,
	enabled_at_play = function(self, player)
		return player:hasSkill("xiashu") and player:hasSkill("jieyin") and player:hasSkill("dimeng") and player:getHandcardNum() == 1
	end
}

-- 渊虑 (Yuanlu) - Equipment cards used are changed to Changandajian
ol_god_yuanlu = sgs.CreateTriggerSkill{
	name = "ol_god_yuanlu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed},
	on_trigger = function(self, event, player, data, room)
		if player:hasSkill("guanchao") and player:hasSkill("jueyan") and player:hasSkill("lanjiang") then
			local use = data:toCardUse()
			if use.card:isKindOf("EquipCard") then
				-- Transform to Changandajian of appropriate type
				-- This would require more complex card transformation logic
			end
		end
		return false
	end
}

-- Changandajian Weapon
ol_god_changandajian_weapon = sgs.CreateWeapon{
	name = "ol_god_changandajian_weapon",
	class_name = "ChangandajianWeapon",
	range = 6,
	suit = sgs.Card_Spade,
	number = 10,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		-- Destroy and choose a card on field
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if not p:isAllNude() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, "ol_god_changandajian_weapon")
			if target then
				local card_id = room:askForCardChosen(player, target, "hej", "ol_god_changandajian_weapon")
				local card = sgs.Sanguosha:getCard(card_id)
				if card:getNumber() > 10 or card:getNumber() == 1 then -- Letter (A, J, Q, K)
					room:obtainCard(player, card_id, false)
				else
					room:throwCard(card_id, target, player)
				end
			end
		end
	end
}
ol_god_changandajian_weapon:clone(1, 10):setParent(extension_heg)

-- Changandajian Armor
ol_god_changandajian_armor = sgs.CreateArmor{
	name = "ol_god_changandajian_armor",
	class_name = "ChangandajianArmor",
	suit = sgs.Card_Heart,
	number = 10,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		-- Recover 1 HP
		local recover = sgs.RecoverStruct()
		recover.who = player
		recover.recover = 1
		room:recover(player, recover)
		
		-- Choose a card on field
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if not p:isAllNude() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, "ol_god_changandajian_armor")
			if target then
				local card_id = room:askForCardChosen(player, target, "hej", "ol_god_changandajian_armor")
				local card = sgs.Sanguosha:getCard(card_id)
				if card:getNumber() > 10 or card:getNumber() == 1 then
					room:obtainCard(player, card_id, false)
				else
					room:throwCard(card_id, target, player)
				end
			end
		end
	end
}
ol_god_changandajian_armor:setParent(extension_heg)

-- Changandajian OffensiveHorse
ol_god_changandajian_offensive = sgs.CreateOffensiveHorse{
	name = "ol_god_changandajian_offensive",
	class_name = "ChangandajianOffensive",
	suit = sgs.Card_Spade,
	number = 10,
	correct_func = function(self, from, to)
		return -2
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if not p:isAllNude() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, "ol_god_changandajian_offensive")
			if target then
				local card_id = room:askForCardChosen(player, target, "hej", "ol_god_changandajian_offensive")
				local card = sgs.Sanguosha:getCard(card_id)
				if card:getNumber() > 10 or card:getNumber() == 1 then
					room:obtainCard(player, card_id, false)
				else
					room:throwCard(card_id, target, player)
				end
			end
		end
	end
}
ol_god_changandajian_offensive:setParent(extension_heg)

-- Changandajian DefensiveHorse
ol_god_changandajian_defensive = sgs.CreateDefensiveHorse{
	name = "ol_god_changandajian_defensive",
	class_name = "ChangandajianDefensive",
	suit = sgs.Card_Heart,
	number = 10,
	correct_func = function(self, from, to)
		return 2
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if not p:isAllNude() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, "ol_god_changandajian_defensive")
			if target then
				local card_id = room:askForCardChosen(player, target, "hej", "ol_god_changandajian_defensive")
				local card = sgs.Sanguosha:getCard(card_id)
				if card:getNumber() > 10 or card:getNumber() == 1 then
					room:obtainCard(player, card_id, false)
				else
					room:throwCard(card_id, target, player)
				end
			end
		end
	end
}
ol_god_changandajian_defensive:setParent(extension_heg)

-- Changandajian Treasure (using CreateTreasure if available, otherwise CreateDefensiveHorse as placeholder)
ol_god_changandajian_treasure = sgs.CreateDefensiveHorse{
	name = "ol_god_changandajian_treasure",
	class_name = "ChangandajianTreasure",
	suit = sgs.Card_Diamond,
	number = 10,
	on_install = function(self, player)
		local room = player:getRoom()
		room:setPlayerMark(player, "ol_god_changandajian_treasure_mark", 2)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:setPlayerMark(player, "ol_god_changandajian_treasure_mark", 0)
		
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if not p:isAllNude() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			local target = room:askForPlayerChosen(player, targets, "ol_god_changandajian_treasure")
			if target then
				local card_id = room:askForCardChosen(player, target, "hej", "ol_god_changandajian_treasure")
				local card = sgs.Sanguosha:getCard(card_id)
				if card:getNumber() > 10 or card:getNumber() == 1 then
					room:obtainCard(player, card_id, false)
				else
					room:throwCard(card_id, target, player)
				end
			end
		end
	end
}
ol_god_changandajian_treasure:setParent(extension_heg)

-- MaxCards skill for treasure
ol_god_changandajian_maxcards = sgs.CreateMaxCardsSkill{
	name = "ol_god_changandajian_maxcards",
	extra_func = function(self, player)
		if player:getMark("ol_god_changandajian_treasure_mark") > 0 then
			return player:getMark("ol_god_changandajian_treasure_mark")
		end
		return 0
	end
}

if not sgs.Sanguosha:getSkill("ol_god_changandajian_maxcards") then 
	skills:append(ol_god_changandajian_maxcards) 
end

-- Add skills to general
ol_god_sunquan:addSkill(ol_god_dili)
ol_god_sunquan:addSkill(ol_god_yuheng)
ol_god_sunquan:addSkill(ol_god_shengzhi)
ol_god_sunquan:addSkill(ol_god_shengzhi_prohibit)
ol_god_sunquan:addSkill(ol_god_chigang)
ol_god_sunquan:addSkill(ol_god_qionglan)
ol_god_sunquan:addSkill(ol_god_quandao)
ol_god_sunquan:addSkill(ol_god_jiaohui)
ol_god_sunquan:addSkill(ol_god_yuanlu)

extension:insertRelatedSkills("ol_god_shengzhi", "#ol_god_shengzhi_prohibit")]]


sgs.Sanguosha:addSkills(skills)


sgs.LoadTranslationTable{
    ["fixandadd_guandu"] = "官渡之战",
    ["fixandadd_twyj"] = "台湾一将成名",

	["displayed"] = "明置",

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
	[":guandu_cangchu"] = "锁定技，游戏开始时，你获得3枚“粮”；当你受到1点火焰伤害后，你弃1枚“粮”。",
	-- ["guandu_sushou"] = "宿守",
	-- [":guandu_sushou"] = "弃牌阶段开始时，你可以摸X+1张牌（X为「粮」数），然后可以交给任意名友方角色各一张牌。",
	["guandu_sushou"] = "宿守",
	[":guandu_sushou"] = "锁定技，若你有“粮”，友方角色摸牌阶段摸牌数+1；当你失去所有“粮”后，你减1点体力上限，然后令敌方角色各摸两张牌。",
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
	
	["gd_yuanjun"] = "援军",
	[":gd_yuanjun"] = "锦囊牌·多目标锦囊<br/><b>时机</b>：出牌阶段，对至多两名已受伤的其他角色使用。<br/><b>效果</b>：每名目标角色各回复1点体力。",

	["gd_tunliang"] = "屯粮",
	[":gd_tunliang"] = "锦囊牌·多目标锦囊<br/><b>时机</b>：出牌阶段，对至多三名角色使用。<br/><b>效果</b>：每名目标角色各摸一张牌。",

	["gd_xujiu"] = "酗酒",
	[":gd_xujiu"] = "【酗酒】 基本牌\
	时机：出牌阶段限一次，对一名角色使用\
	效果：。目标角色本回合内受到的伤害+1（每回合同一目标限一次）。 ",

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

	["sijyuoffline_zhaoyun"] = "赵云[联想]",
    ["&sijyuoffline_zhaoyun"] = "赵云",
    ["#sijyuoffline_zhaoyun"] = "白马先锋",
    ["~sijyuoffline_zhaoyun"] = "",
    ["designer:sijyuoffline_zhaoyun"] = "",
    ["cv:sijyuoffline_zhaoyun"] = "",
    ["illustrator:sijyuoffline_zhaoyun"] = "VINCENT",

	["sijyuoffline_huyi"] = "虎翼",
    [":sijyuoffline_huyi"] = "装备牌·武器\
	攻击范围：3\
	攻击效果：你使用【杀】对目标造成属性伤害时，你可以横置至多两名角色。",
    ["@sijyuoffline_huyi"] = "虎翼：你可以横置至多两名角色",

	-- God Sun Quan [OL]
	["ol_god_sunquan"] = "神孙权[OL][旧]",
	["&ol_god_sunquan"] = "神孙权",
	["#ol_god_sunquan"] = "东吴命运之主",
	["~ol_god_sunquan"] = "",
	["designer:ol_god_sunquan"] = "",
	["cv:ol_god_sunquan"] = "",
	["illustrator:ol_god_sunquan"] = "",
	
	["ol_god_dili"] = "帝力",
	[":ol_god_dili"] = "锁定技，游戏开始时，你随机开启一条“东吴命运线”。",
	
	["ol_god_yuheng"] = "驭衡",
	[":ol_god_yuheng"] = "出牌阶段限一次，你可以失去其他所有非锁定技并随机获得你未以此法获得过的“东吴命运线”中的一个技能（若全部以此法获得过则重置），若你本阶段未发动其他非锁定技，你额外随机获得你开启的“东吴命运线”中一个未以此法获得过的技能（若该线技能全部以此法获得过则重置）。出牌阶段结束时，若你本阶段未发动本技能，你失去1点体力。",
	
	["ol_god_shengzhi"] = "圣质",
	[":ol_god_shengzhi"] = "锁定技，若你获得过“英魂”、“弘德”、“秉壹”，你点数为质数的牌不能被响应。",
	
	["ol_god_chigang"] = "持纲",
	[":ol_god_chigang"] = "锁定技，若你获得过“观微”、“弼政”、“安国”，你的判定阶段改为摸牌阶段。",
	
	["ol_god_qionglan"] = "穹览",
	[":ol_god_qionglan"] = "锁定技，若你获得过“涉猎”、“问卦”、“博图”，你视为随机开启其他两条东吴命运线。",
	
	["ol_god_quandao"] = "权道",
	[":ol_god_quandao"] = "锁定技，若你获得过“制衡”、“诫训”、“安恤”，你点数为字母的手牌视为【调剂盐梅】。",
	
	["ol_god_jiaohui"] = "交辉",
	[":ol_god_jiaohui"] = "锁定技，若你获得过“下书”、“结姻”、“缔盟”，你最后一张手牌视为【远交近攻】。",
	
	["ol_god_yuanlu"] = "渊虑",
	[":ol_god_yuanlu"] = "锁定技，若你获得过“观潮”、“决堰”、“澜疆”，你使用的装备牌改为【长安大舰】。",
	
	["&fate_line2"] = "东吴命运线二",
	["&fate_line3"] = "东吴命运线三",
	["&fate_line1"] = "东吴命运线一",
	["&fate_line4"] = "东吴命运线四",
	["&fate_line5"] = "东吴命运线五",
	["&fate_line6"] = "东吴命运线六",
	
	-- Equipment cards
	["heg_ol_god_changandajian_weapon"] = "长安大舰",
	["ChangandajianWeapon"] = "长安大舰",
	[":heg_ol_god_changandajian_weapon"] = "装备牌·武器\
	攻击范围：6\
	锁定技，当你失去装备区里的此牌时，你销毁之并选择场上一张牌，若点数为字母，你获得之，否则弃置之。",
	
	["heg_ol_god_changandajian_armor"] = "长安大舰",
	["ChangandajianArmor"] = "长安大舰",
	[":heg_ol_god_changandajian_armor"] = "装备牌·防具\
	锁定技，当你失去装备区里的此牌时，你销毁之，回复1点体力并选择场上一张牌，若点数为字母，你获得之，否则弃置之。",
	
	["heg_ol_god_changandajian_offensive"] = "长安大舰",
	["ChangandajianOffensive"] = "长安大舰",
	[":heg_ol_god_changandajian_offensive"] = "装备牌·坐骑\
	距离：-1\
	锁定技，你计算与其他角色的距离-2。当你失去装备区里的此牌时，你销毁之并选择场上一张牌，若点数为字母，你获得之，否则弃置之。",
	
	["heg_ol_god_changandajian_defensive"] = "长安大舰",
	["ChangandajianDefensive"] = "长安大舰",
	[":heg_ol_god_changandajian_defensive"] = "装备牌·坐骑\
	距离：+1\
	锁定技，其他角色计算与你的距离+2。当你失去装备区里的此牌时，你销毁之并选择场上一张牌，若点数为字母，你获得之，否则弃置之。",
	
	["heg_ol_god_changandajian_treasure"] = "长安大舰",
	["ChangandajianTreasure"] = "长安大舰",
	[":heg_ol_god_changandajian_treasure"] = "装备牌·宝物\
	锁定技，你的手牌上限+2。当你失去装备区里的此牌时，你销毁之并选择场上一张牌，若点数为字母，你获得之，否则弃置之。",
	
	-- 通用明置牌机制翻译
	["display_cards"] = "明置",
	["displaypile"] = "明置牌",
	["displayhand"] = "暗牌",
	["cardshow"] = "明置",
	
}



return {extension, extension_guandu, extension_twyj}