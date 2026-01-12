extension_heg = sgs.Package("new_heg", sgs.Package_GeneralPack)
extension_hegol = sgs.Package("heg_ol", sgs.Package_GeneralPack)
extension_hegmobile = sgs.Package("heg_mobile", sgs.Package_GeneralPack)
extension_hegtenyear = sgs.Package("heg_tenyear", sgs.Package_GeneralPack)
extension_hegbian = sgs.Package("heg_bian", sgs.Package_GeneralPack)
extension_hegquan = sgs.Package("heg_quan", sgs.Package_GeneralPack)
extension_heglordex = sgs.Package("heg_lordex", sgs.Package_GeneralPack)
extension_hegpurplecloud = sgs.Package("heg_purplecloud", sgs.Package_GeneralPack)
extension_goldenseal = sgs.Package("heg_goldenseal", sgs.Package_GeneralPack)
extension_hegcard = sgs.Package("hegemony_cards", sgs.Package_CardPack)
extension_hegadvantagecard = sgs.Package("strategic_advantage", sgs.Package_CardPack)
require "ExtraTurnUtils"

function ChangeGeneral(room, player, skill_onwer_general_name, kingdom)
	local generals = {}
	for _,name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
		local general = sgs.Sanguosha:getGeneral(name)
		if not sgs.Sanguosha:isGeneralHidden(name) and not table.contains(generals, name) then
			if not kingdom or general:getKingdom() == kingdom then
				table.insert(generals, name)
			end
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
	local num = 0
	for _, p in sgs.qlist(room:findPlayersBySkillName("heg_true_jiancai")) do
		if room:askForSkillInvoke(p, "heg_true_jiancai_change", ToData(player)) then
			num = num + 2
		end
	end
	if num == 0 then
		room:changeHero(player, generals[math.random(1, #generals)], false, false, player:getGeneral2Name() and player:getGeneral2Name() == skill_onwer_general_name)
	elseif player:getState() == "online" then
		local general = room:askForGeneral(player, table.concat(generals, "+"))
		room:changeHero(player, general, false, false, player:getGeneral2Name() and player:getGeneral2Name() == skill_onwer_general_name)
	else
		room:changeHero(player, generals[math.random(1, #generals)], false, false, player:getGeneral2Name() and player:getGeneral2Name() == skill_onwer_general_name)
	end
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


function IsBigKingdomPlayer(player)
	-- 判断某个角色是否为大势力角色
	-- 如果场上有人装备玉玺，则玉玺持有者为大势力，其他为小势力
	-- 否则按势力人数判断（人数>=2且为最多）
	local room = player:getRoom()
	
	-- 检查场上是否有人装备玉玺
	local jade_seal_owner = nil
	local alive_count = 0
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		alive_count = alive_count + 1
		if p:hasTreasure("heg_jade_seal") then
			jade_seal_owner = p
			break
		end
	end
	
	-- 如果场上人数少于4人，没有大势力概念
	if alive_count < 4 then
		return false
	end
	
	-- 如果有人装备玉玺，则只有玉玺持有者是大势力
	if jade_seal_owner then
		return player:objectName() == jade_seal_owner:objectName()
	end
	
	-- 否则按势力人数判断
	local kingdom_count = {}
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		local kingdom = p:getKingdom()
		if kingdom_count[kingdom] then
			kingdom_count[kingdom] = kingdom_count[kingdom] + 1
		else
			kingdom_count[kingdom] = 1
		end
	end
	
	local max_count = 0
	for _, count in pairs(kingdom_count) do
		if count > max_count then
			max_count = count
		end
	end
	
	local player_kingdom = player:getKingdom()
	local player_kingdom_count = kingdom_count[player_kingdom] or 0
	
	-- 大势力条件: 人数>=2 且 人数=最大人数
	return player_kingdom_count >= 2 and player_kingdom_count == max_count
end

function IsBigKingdomPlayerClient(player)
	-- 判断某个角色是否为大势力角色（不使用getRoom）
	-- 如果场上有人装备玉玺，则玉玺持有者为大势力，其他为小势力
	-- 否则按势力人数判断（人数>=2且为最多）
	
	-- 检查场上是否有人装备玉玺
	local jade_seal_owner = nil
	local alive_count = 0
	for _, p in sgs.qlist(player:getAliveSiblings(true)) do
		alive_count = alive_count + 1
		if p:hasTreasure("heg_jade_seal") then
			jade_seal_owner = p
			break
		end
	end
	
	-- 如果场上人数少于4人，没有大势力概念
	if alive_count < 4 then
		return false
	end
	
	-- 如果有人装备玉玺，则只有玉玺持有者是大势力
	if jade_seal_owner then
		return player:objectName() == jade_seal_owner:objectName()
	end
	
	-- 否则按势力人数判断
	local kingdom_count = {}
	for _, p in sgs.qlist(player:getAliveSiblings(true)) do
		local kingdom = p:getKingdom()
		if kingdom_count[kingdom] then
			kingdom_count[kingdom] = kingdom_count[kingdom] + 1
		else
			kingdom_count[kingdom] = 1
		end
	end
	
	local max_count = 0
	for _, count in pairs(kingdom_count) do
		if count > max_count then
			max_count = count
		end
	end
	
	local player_kingdom = player:getKingdom()
	local player_kingdom_count = kingdom_count[player_kingdom] or 0
	
	-- 大势力条件: 人数>=2 且 人数=最大人数
	return player_kingdom_count >= 2 and player_kingdom_count == max_count
end

function IsEncircled(player)
	-- 判断某个角色是否处于围攻关系中（被围攻角色）
	-- 围攻定义: 一名角色的上家与下家势力相同且与该角色不同
	local room = player:getRoom()
	local alive_count = room:alivePlayerCount()
	if alive_count < 3 then return false end  -- 至少需要3人才能形成围攻
	local prev_player = player:getNextAlive(alive_count - 1)  -- 上家
	local next_player = player:getNextAlive(1)   -- 下家
	
	if not prev_player or not next_player then
		return false
	end
	
	local player_kingdom = player:getKingdom()
	local prev_kingdom = prev_player:getKingdom()
	local next_kingdom = next_player:getKingdom()
	
	-- 上家与下家势力相同，且与该角色势力不同
	return prev_kingdom == next_kingdom and prev_kingdom ~= player_kingdom
end

function GetEncirclers(player)
	-- 获取围攻某个角色的所有围攻角色
	-- 返回围攻角色列表（上家和下家）
	local encirclers = {}
	
	if IsEncircled(player) then
		local room = player:getRoom()
		local alive_count = room:alivePlayerCount()
		local prev_player = player:getNextAlive(alive_count - 1)  -- 上家
		local next_player = player:getNextAlive(1)   -- 下家
		table.insert(encirclers, prev_player)
		table.insert(encirclers, next_player)
	end
	
	return encirclers
end

function GetEncirclersClient(player)
	-- Client版本: 获取围攻某个角色的所有围攻角色
	-- 返回围攻角色列表（上家和下家）
	local encirclers = {}
	
	-- 检查是否被围攻：上家与下家势力相同且与该角色不同
	local player_kingdom = player:getKingdom()
	local prev_player = nil
	local next_player = nil
	
	-- 遍历所有存活玩家找到上家和下家
	for _, p in sgs.qlist(player:getAliveSiblings()) do
		if not prev_player then
			-- 第一个不是自己的玩家可能是下家或其他玩家
			-- 需要通过完整遍历来确定
		end
	end
	
	-- 使用getAliveSiblings(true)包含自己，然后找相邻位置
	local all_players = {}
	for _, p in sgs.qlist(player:getAliveSiblings(true)) do
		table.insert(all_players, p)
	end
	
	if #all_players < 3 then return encirclers end
	
	-- 找到当前玩家的位置
	local my_pos = nil
	for i, p in ipairs(all_players) do
		if p:objectName() == player:objectName() then
			my_pos = i
			break
		end
	end
	
	if not my_pos then return encirclers end
	
	-- 获取上家和下家
	local prev_pos = my_pos - 1
	if prev_pos < 1 then prev_pos = #all_players end
	local next_pos = my_pos + 1
	if next_pos > #all_players then next_pos = 1 end
	
	prev_player = all_players[prev_pos]
	next_player = all_players[next_pos]
	
	if not prev_player or not next_player then return encirclers end
	
	local prev_kingdom = prev_player:getKingdom()
	local next_kingdom = next_player:getKingdom()
	
	-- 上家与下家势力相同，且与该角色势力不同，则被围攻
	if prev_kingdom == next_kingdom and prev_kingdom ~= player_kingdom then
		table.insert(encirclers, prev_player)
		table.insert(encirclers, next_player)
	end
	
	return encirclers
end

function GetEncircledPlayers(player)
	-- 获取某个角色参与围攻的所有被围攻角色
	-- 一名角色可以同时围攻其上家和下家（如果满足条件）
	local room = player:getRoom()
	local encircled = {}
	local alive_count = room:alivePlayerCount()
	
	if alive_count < 3 then return encircled end  -- 至少需要3人才能形成围攻
	
	local prev_player = player:getNextAlive(alive_count - 1)  -- 上家
	local next_player = player:getNextAlive(1)   -- 下家
	
	-- 检查上家是否被围攻（玩家和下家围攻上家）
	if prev_player and IsEncircled(prev_player) then
		local encirclers = GetEncirclers(prev_player)
		for _, encircler in ipairs(encirclers) do
			if encircler:objectName() == player:objectName() then
				table.insert(encircled, prev_player)
				break
			end
		end
	end
	
	-- 检查下家是否被围攻（上家和玩家围攻下家）
	if next_player and IsEncircled(next_player) then
		local encirclers = GetEncirclers(next_player)
		for _, encircler in ipairs(encirclers) do
			if encircler:objectName() == player:objectName() then
				table.insert(encircled, next_player)
				break
			end
		end
	end
	
	return encircled
end

function GetAllEncirclementRelations(room)
	-- 获取场上所有的围攻关系
	-- 返回一个表，每个元素包含 {encircled = 被围攻角色, encirclers = {围攻角色列表}}
	local relations = {}
	
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		if IsEncircled(p) then
			local encirclers = GetEncirclers(p)
		end
	end
	return relations
end

function IsInQueue(player)
	-- 判断某个角色是否处于队列中
	-- 队列定义: 连续相邻的若干名（至少2名）势力相同的角色
	local room = player:getRoom()
	local alive_count = room:alivePlayerCount()
	
	if alive_count < 2 then return false end
	
	local player_kingdom = player:getKingdom()
	local prev_player = player:getNextAlive(alive_count - 1)  -- 上家
	local next_player = player:getNextAlive(1)   -- 下家
	
	-- 只要上家或下家有一个势力相同，就处于队列中
	return (prev_player and prev_player:getKingdom() == player_kingdom) or 
	       (next_player and next_player:getKingdom() == player_kingdom)
end

function GetQueueMembers(player)
	-- 获取某个角色所在队列的所有成员（包括自己）
	-- 返回队列成员列表
	local room = player:getRoom()
	local alive_count = room:alivePlayerCount()
	
	if alive_count < 2 or not IsInQueue(player) then
		return {}
	end
	
	local player_kingdom = player:getKingdom()
	local queue = {}
	local visited = {}
	
	-- 从当前玩家开始向前查找队列起点
	local start = player
	visited[player:objectName()] = true
	local prev = start:getNextAlive(alive_count - 1)
	local count = 0
	
	while prev and count < alive_count do
		if prev:objectName() == player:objectName() or visited[prev:objectName()] then
			break
		end
		if prev:getKingdom() ~= player_kingdom then
			break
		end
		visited[prev:objectName()] = true
		start = prev
		prev = start:getNextAlive(alive_count - 1)
		count = count + 1
	end
	
	-- 从起点开始向后收集所有同势力的连续角色
	visited = {}
	local current = start
	table.insert(queue, current)
	visited[current:objectName()] = true
	local next = current:getNextAlive(1)
	count = 0
	
	while next and count < alive_count do
		if next:objectName() == start:objectName() or visited[next:objectName()] then
			break
		end
		if next:getKingdom() ~= player_kingdom then
			break
		end
		table.insert(queue, next)
		visited[next:objectName()] = true
		current = next
		next = current:getNextAlive(1)
		count = count + 1
	end
	
	return queue
end

function GetAllQueues(room)
	-- 获取场上所有的队列
	-- 返回一个表，每个元素是一个队列（成员列表）
	local queues = {}
	local processed = {}
	
	for _, p in sgs.qlist(room:getAlivePlayers()) do
		if not processed[p:objectName()] then
			local queue = GetQueueMembers(p)
			if #queue >= 2 then
				-- 标记该队列的所有成员为已处理
				for _, member in ipairs(queue) do
					processed[member:objectName()] = true
				end
				table.insert(queues, queue)
			end
		end
	end
	
	return queues
end

function GetQueueSize(player)
	-- 获取某个角色所在队列的大小
	-- 如果不在队列中返回0，否则返回队列人数
	local queue = GetQueueMembers(player)
	return #queue
end

function AreInSameQueue(player1, player2)
	-- 判断两个角色是否在同一个队列中
	if player1:getKingdom() ~= player2:getKingdom() then
		return false
	end
	
	local queue = GetQueueMembers(player1)
	if #queue < 2 then return false end
	
	for _, member in ipairs(queue) do
		if member:objectName() == player2:objectName() then
			return true
		end
	end
	
	return false
end


-- 合纵机制
function CardIsHezong(id)
	if type(id)~="number" then id = id:getId() end
	if id>=0 then
		local ec = sgs.Sanguosha:getEngineCard(id)
		return ec and ec:property("CharTag") and type(ec:property("CharTag"))~="userdata"
		and table.contains(ec:property("CharTag"):toStringList(),"transfer_card")
	end
end

heg_transferCard = sgs.CreateSkillCard{
	name = "heg_transfer",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self,targets,to_select,source)
		if #targets>0 or to_select==source then return false end
		-- 目标必须是与你势力不同的角色
		return to_select:getKingdom() ~= source:getKingdom()
	end,
	on_use = function(self,room,source,targets)
		local target = targets[1]
		room:doAnimate(1,source:objectName(),target:objectName())
		
		local ids = self:getSubcards()
		local count = ids:length()
		
		-- 将牌交给目标角色
		for _,id in sgs.list(ids) do
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,source:objectName(),target:objectName(),"heg_transfer","")
			room:obtainCard(target,id,reason,false)
		end
		
		-- 摸等量的牌
		source:drawCards(count)
		
		room:sendLog("#heg_transfer", source, "heg_transfer", targets, tostring(count))
	end
}

heg_transfer = sgs.CreateViewAsSkill{
	name = "heg_transfer&",
	n = 3,
	view_filter = function(self,selected,to_select)
		return not to_select:isEquipped() and CardIsHezong(to_select)
	end,
	view_as = function(self,cards)
		if #cards == 0 then return nil end
		local c = heg_transferCard:clone()
		for _,card in ipairs(cards) do
			c:addSubcard(card)
		end
		return c
	end,
	enabled_at_play = function(self,player)
		-- 检查是否有合纵牌
		for _,c in sgs.qlist(player:getHandcards()) do
			if CardIsHezong(c) then return true end
		end
		return false
	end,
}

-- 合纵触发器：当玩家获得或失去合纵牌时，自动附加或移除合纵技能
hezong_on_trigger = sgs.CreateTriggerSkill{
	name = "hezong_on_trigger",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseProceeding,sgs.EventPhaseEnd},
	priority = {4},
	global = true,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			-- 当玩家获得手牌时
			if move.to_place==sgs.Player_PlaceHand
			and player:objectName()==move.to:objectName() then
				for _,id in sgs.qlist(move.card_ids)do
					if player:handCards():contains(id) then
						if player:getPhase()==sgs.Player_Play
						and CardIsHezong(id) and not player:hasSkill("heg_transfer",true)
						then 
							room:attachSkillToPlayer(player,"heg_transfer")
							break
						end
					end
				end
			end
		elseif event==sgs.EventPhaseProceeding then
			-- 出牌阶段开始时检查是否有合纵牌
			if player:getPhase()==sgs.Player_Play then
				for _,c in sgs.qlist(player:getHandcards())do
					if CardIsHezong(c) and not player:hasSkill("heg_transfer",true)
					then 
						room:attachSkillToPlayer(player,"heg_transfer")
						break
					end
				end
			end
		elseif event==sgs.EventPhaseEnd then
			-- 回合结束时移除合纵技能
			if player:hasSkill("heg_transfer",true) then
				room:detachSkillFromPlayer(player,"heg_transfer",true,true)
			end
		end
		return false
	end
}


local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("heg_transfer") then skills:append(heg_transfer) end
if not sgs.Sanguosha:getSkill("hezong_on_trigger") then skills:append(hezong_on_trigger) end

heg_yinyangyuCard = sgs.CreateSkillCard{
	name = "heg_yinyangyu",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		source:drawCards(1, "heg_yinyangyu")
		room:removePlayerMark(source, "@heg_yinyangyu")
	end
}
heg_yinyangyuVS = sgs.CreateZeroCardViewAsSkill{
	name = "heg_yinyangyu",
	view_as = function(self)
		return heg_yinyangyuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@heg_yinyangyu") > 0
	end
}
heg_yinyangyu = sgs.CreateTriggerSkill{
	name = "heg_yinyangyu&",
	events = {sgs.EventPhaseStart},
	view_as_skill = heg_yinyangyuVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then
				if player:getMark("@heg_yinyangyu") > 0 and player:getHandcardNum() > player:getMaxCards() and room:askForSkillInvoke(player, self:objectName()) then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:removePlayerMark(player, "@heg_yinyangyu")
					room:addMaxCards(player, 2, true)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getMark("@heg_yinyangyu") > 0
	end
}

heg_xianquCard = sgs.CreateSkillCard{
	name = "heg_xianqu",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		source:drawCards(4 - source:getHandcardNum(), "heg_xianqu")
		local target = targets[1]
		local cards = target:handCards()
		room:removePlayerMark(source, "@heg_xianqu")
		room:showAllCards(target, source)
	end
}

heg_xianqu = sgs.CreateZeroCardViewAsSkill{
	name = "heg_xianqu&",
	view_as = function(self)
		return heg_xianquCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@heg_xianqu") > 0 and player:getHandcardNum() < 4
	end
}

hegMark = sgs.CreateTriggerSkill{
	name = "hegMark",
	events = {sgs.MarkChanged},
	global = true,
	on_trigger = function(self, event, player, data, room)
		local mark = data:toMark()
		if mark.name=="@heg_xianqu" and mark.gain > 0 and not player:hasSkill("heg_xianqu",true) then
			room:attachSkillToPlayer(player,"heg_xianqu")
		end
		if mark.name=="@heg_yinyangyu" and mark.gain > 0 and not player:hasSkill("heg_yinyangyu",true) then
			room:attachSkillToPlayer(player,"heg_yinyangyu")
		end
	end
}

if not sgs.Sanguosha:getSkill("hegMark") then skills:append(hegMark) end
if not sgs.Sanguosha:getSkill("heg_yinyangyu") then skills:append(heg_yinyangyu) end
if not sgs.Sanguosha:getSkill("heg_xianqu") then skills:append(heg_xianqu) end

heg_sujiang = sgs.General(extension_heg, "heg_sujiang", "qun", 3, true, true)
heg_sujiangf = sgs.General(extension_heg, "heg_sujiangf", "qun", 3, false, true)

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

heg_wushuang_buff = sgs.CreateTargetModSkill {
	name = "#heg_wushuang_buff",
	pattern = "Duel",
	extra_target_func = function(self,from,card)
		if from:hasSkill("heg_wushuang") and not card:isVirtualCard() then return 2 end
		return 0
	end,
}

heg_wushuang = sgs.CreateTriggerSkill{
	name = "heg_wushuang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if event == sgs.TargetSpecified then
			if use.card then
				if use.card:isKindOf("Slash") or use.card:isKindOf("Duel") then
					if player:hasSkill(self:objectName()) and player:objectName() == use.from:objectName() then
						local wushuang = sgs.Sanguosha:getTriggerSkill("wushuang")
						room:setPlayerProperty(player, "pingjian_triggerskill", sgs.QVariant("wushuang"))
						wushuang:trigger(event,room,player,data)	
						room:setPlayerProperty(player, "pingjian_triggerskill", sgs.QVariant(""))
					else
						if use.card:isKindOf("Duel") then
							for _, p in sgs.qlist(use.to) do
								if p:objectName() ~= player:objectName()  and p:hasSkill(self:objectName()) then
									local wushuang = sgs.Sanguosha:getTriggerSkill("wushuang")
									room:setPlayerProperty(p, "pingjian_triggerskill", sgs.QVariant("wushuang"))
									wushuang:trigger(event,room,p,data)	
									room:setPlayerProperty(p, "pingjian_triggerskill", sgs.QVariant(""))
								end
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
	end,
}

heg_lubu:addSkill(heg_wushuang)
heg_lubu:addSkill(heg_wushuang_buff)
extension_heg:insertRelatedSkills("heg_wushuang","#heg_wushuang_buff")


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
		local dc = sgs.Self:getTag("heg_nos_guishu"):toCard()
		if dc and originalCard then
			dc = sgs.Sanguosha:cloneCard(dc:objectName())
			dc:addSubcard(originalCard)
			dc:setSkillName("heg_nos_guishu")
			return dc
		end
	end,
	enabled_at_play = function(self, player)
		return true
	end,
}

heg_nos_guishu = sgs.CreateTriggerSkill{
	name = "heg_nos_guishu",
	events = {sgs.PreCardUsed},
	view_as_skill = heg_nos_guishuVS,
	juguan_type = "EXCard_YJJG,EXCard_ZJZB",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and table.contains(use.card:getSkillNames(), "heg_nos_guishu") then
			if player:getMark("heg_nos_guishu") == 1 then
				room:setPlayerMark(player, "heg_nos_guishu", 2)
				room:setPlayerMark(player, "heg_nos_guishu_juguan_remove_EXCard_YJJG", 1)
				room:setPlayerMark(player, "heg_nos_guishu_juguan_remove_EXCard_ZJZB", 0)
				room:changeTranslation(player, "heg_nos_guishu", 2)
			elseif player:getMark("heg_nos_guishu") == 2 then
				room:setPlayerMark(player, "heg_nos_guishu", 1)
				room:setPlayerMark(player, "heg_nos_guishu_juguan_remove_EXCard_YJJG", 0)
				room:setPlayerMark(player, "heg_nos_guishu_juguan_remove_EXCard_ZJZB", 1)
				room:changeTranslation(player, "heg_nos_guishu", 1)
			else
				if use.card:isKindOf("EXCard_YJJG") then
					room:setPlayerMark(player, "heg_nos_guishu", 2)
					room:setPlayerMark(player, "heg_nos_guishu_juguan_remove_EXCard_YJJG", 1)
					room:setPlayerMark(player, "heg_nos_guishu_juguan_remove_EXCard_ZJZB", 0)
					room:changeTranslation(player, "heg_nos_guishu", 2)
				elseif use.card:isKindOf("EXCard_ZJZB") then
					room:setPlayerMark(player, "heg_nos_guishu", 1)
					room:setPlayerMark(player, "heg_nos_guishu_juguan_remove_EXCard_YJJG", 0)
					room:setPlayerMark(player, "heg_nos_guishu_juguan_remove_EXCard_ZJZB", 1)
					room:changeTranslation(player, "heg_nos_guishu", 1)
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

heg_himiko = sgs.General(extension_heg, "heg_himiko", "qun", 3, false)


heg_guishuVS = sgs.CreateOneCardViewAsSkill {
	name = "heg_guishu",
	filter_pattern = ".|spade",
	response_or_use = true,
	view_as = function(self, originalCard)
		local dc = sgs.Self:getTag("heg_guishu"):toCard()
		if dc and originalCard then
			dc = sgs.Sanguosha:cloneCard(dc:objectName())
			dc:addSubcard(originalCard)
			dc:setSkillName("heg_guishu")
			return dc
		end
	end,
	enabled_at_play = function(self, player)
		return true
	end,
}

heg_guishu = sgs.CreateTriggerSkill{
	name = "heg_guishu",
	events = {sgs.PreCardUsed, sgs.EventPhaseChanging},
	view_as_skill = heg_guishuVS,
	juguan_type = "EXCard_YJJG,EXCard_ZJZB",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and table.contains(use.card:getSkillNames(), "heg_guishu") then
				if player:getMark("heg_guishu") == 1 then
					room:setPlayerMark(player, "heg_guishu-Clear", 2)
					room:changeTranslation(player, "heg_guishu", 2)
					room:setPlayerMark(player, "heg_guishu_juguan_remove_EXCard_YJJG", 1)
					room:setPlayerMark(player, "heg_guishu_juguan_remove_EXCard_ZJZB", 0)
				elseif player:getMark("heg_guishu") == 2 then
					room:setPlayerMark(player, "heg_guishu-Clear", 1)
					room:changeTranslation(player, "heg_guishu", 1)
					room:setPlayerMark(player, "heg_guishu_juguan_remove_EXCard_YJJG", 0)
					room:setPlayerMark(player, "heg_guishu_juguan_remove_EXCard_ZJZB", 1)
				else
					if use.card:isKindOf("EXCard_YJJG") then
						room:setPlayerMark(player, "heg_guishu-Clear", 2)
						room:setPlayerMark(player, "heg_guishu_juguan_remove_EXCard_YJJG", 1)
						room:setPlayerMark(player, "heg_guishu_juguan_remove_EXCard_ZJZB", 0)
						room:changeTranslation(player, "heg_guishu", 2)
					elseif use.card:isKindOf("EXCard_ZJZB") then
						room:setPlayerMark(player, "heg_guishu-Clear", 1)
						room:setPlayerMark(player, "heg_guishu_juguan_remove_EXCard_YJJG", 0)
						room:setPlayerMark(player, "heg_guishu_juguan_remove_EXCard_ZJZB", 1)
						room:changeTranslation(player, "heg_guishu", 1)
					end
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				room:changeTranslation(player, "heg_guishu", 0)
				room:setPlayerMark(player, "heg_guishu-Clear", 0)
			end
		end
	end,
}

heg_yuanyu = sgs.CreateTriggerSkill{
    name = "heg_yuanyu",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.from and not (damage.from:inMyAttackRange(player)) then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			player:damageRevises(data, -1)
        end
    end,
}

heg_himiko:addSkill(heg_guishu)
heg_himiko:addSkill(heg_yuanyu)

heg_yangwan = sgs.General(extension_heg, "heg_yangwan", "shu", 3, false)

heg_youyan = sgs.CreateTriggerSkill{
	name = "heg_youyan",
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and player:getPhase() ~= sgs.Player_NotActive and player:getMark("heg_youyan-Clear") == 0 then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:addPlayerMark(player, "heg_youyan-Clear")
				room:broadcastSkillInvoke(self:objectName())
				local ids = room:getNCards(4)
				room:fillAG(ids, player)
				local suit_set = {}
				for _,id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					suit_set[card:getSuitString()] = true
				end
				local to_obtain = dummyCard()
				for _,id in sgs.qlist(ids) do
					local card = sgs.Sanguosha:getCard(id)
					if not suit_set[card:getSuitString()] then
						to_obtain:addSubcard(id)
					end
				end
				if to_obtain:subcardsLength() > 0 then
					room:obtainCard(player, to_obtain, false)
				end
				room:clearAG(player)
			end
		end
		return false
	end
}

heg_zhuihuan_Clear = sgs.CreateTriggerSkill{
	name = "#heg_zhuihuan_Clear",
	events = {sgs.EventPhaseStart, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:hasSkill("heg_zhuihuan") then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				local choicelist = { "damage", "discard" }
				for _, choice in ipairs(choicelist) do
					if p:getMark("&heg_zhuihuan+to+#"..player:objectName()) > 0 then
						room:setPlayerMark(p, "&heg_zhuihuan+to+#"..player:objectName(), 0)
					end
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			for _, p in sgs.qlist(room:findPlayersBySkillName("heg_zhuihuan")) do
				local choicelist = { "damage", "discard" }
				for _, choice in ipairs(choicelist) do
					if p:getMark("heg_zhuihuan-"..choice.."-"..damage.to:objectName().."-Self"..sgs.Player_RoundStart.."Clear") > 0 then
						room:sendCompulsoryTriggerLog(p, "heg_zhuihuan", true)
						room:setPlayerMark(p, "heg_zhuihuan-"..choice.."-"..damage.to:objectName().."-Self"..sgs.Player_RoundStart.."Clear", 0)
						room:setPlayerMark(damage.to, "&heg_zhuihuan+to+#"..p:objectName(), 0)
						if damage.from and damage.from:isAlive() then
							if choice == "damage" then
								local newdamage = sgs.DamageStruct()
								newdamage.from = damage.to
								newdamage.to = damage.from
								newdamage.damage = 1
								room:damage(newdamage)
							elseif choice == "discard" and damage.from:canDiscard(damage.from, "h") then
								room:askForDiscard(damage.from, "heg_zhuihuan", 2, 2, false, true)
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
	

heg_zhuihuan = sgs.CreateTriggerSkill{
	name = "heg_zhuihuan",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				local targets = room:askForPlayersChosen(player, room:getAlivePlayers(), self:objectName(), 0, 2, "@heg_zhuihuan", true, true)
				if targets and targets:length() > 0 then
					local choicelist = { "damage", "discard" }
					local choice = room:askForChoice(player, self:objectName(), table.concat(choicelist, "+"), ToData(targets:first()))
					room:addPlayerMark(player, "heg_zhuihuan-"..choice.."-"..targets:first():objectName().."-Self"..sgs.Player_RoundStart.."Clear")
					room:addPlayerMark(targets:first(), "&heg_zhuihuan+to+#"..player:objectName())
					if targets:length() == 2 then
						table.removeOne(choicelist, choice)
						choice = choicelist[1]
						room:addPlayerMark(player, "heg_zhuihuan-"..choice.."-"..targets:last():objectName().."-Self"..sgs.Player_RoundStart.."Clear")
						room:addPlayerMark(targets:last(), "&heg_zhuihuan+to+#"..player:objectName())
					end

				end
			end
		end
	end
}

heg_yangwan:addSkill(heg_youyan)
heg_yangwan:addSkill(heg_zhuihuan)
heg_yangwan:addSkill(heg_zhuihuan_Clear)
extension_heg:insertRelatedSkills("heg_zhuihuan","#heg_zhuihuan_Clear")

heg_zongyu = sgs.General(extension_heg, "heg_zongyu", "shu", 3)

heg_qiao = sgs.CreateTriggerSkill{
	name = "heg_qiao",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("SkillCard") then return false end
		if use.to:contains(player) and player:objectName() ~= use.from:objectName() then
			if player:canDiscard(use.from, "he") and player:canDiscard(player, "h") and room:askForSkillInvoke(player, self:objectName(), ToData(use.from)) then
				local id = room:askForCardChosen(player, use.from, "he", self:objectName(), false, sgs.Card_MethodDiscard)
				room:throwCard(id, use.from, player)
				room:askForDiscard(player, self:objectName(), 1, 1, false, true)
			end
		end
		return false
	end
}
	
heg_chengshang = sgs.CreateTriggerSkill{
	name = "heg_chengshang",
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.from:objectName() ~= player:objectName() then return false end
		if use.to:isEmpty() then return false end
		if use.card:isKindOf("SkillCard") then return false end
		if use.card and not use.card:hasFlag("DamageDone") then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(use.to) do
				if not p:isNude() then
					targets:append(p)
				end
			end
			if targets:isEmpty() then return false end
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "@heg_chengshang", true, true)
			if target then
				room:broadcastSkillInvoke(self:objectName())
				local card = room:askForCard(target, ".!", self:objectName(), data, sgs.Card_MethodNone)
				room:showCard(target, card:getEffectiveId())
				room:obtainCard(player, card:getEffectiveId(), false)
				if card:getSuit() == use.card:getSuit() or card:getNumber() == use.card:getNumber() then
					room:detachSkillFromPlayer(player, self:objectName())
				end
			end
		end
		return false
	end
}
heg_zongyu:addSkill(heg_qiao)
heg_zongyu:addSkill(heg_chengshang)

heg_lvlingqi = sgs.General(extension_heg, "heg_lvlingqi", "qun", 3, false)

heg_guowu = sgs.CreateTriggerSkill {
	name = "heg_guowu",
	events = { sgs.EventPhaseStart, sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if (player:getPhase() == sgs.Player_Play) then
				if not player:isKongcheng() and player:askForSkillInvoke(self:objectName()) then
					room:showAllCards(player)
					local types = {}
					for _, card in sgs.qlist(player:getHandcards()) do
						if not table.contains(types, card:getTypeId()) then
							table.insert(types, card:getTypeId())
						end
					end
					local log = sgs.LogMessage()
					log.type  = "#GuoWuType"
					log.from  = player
					log.arg   = tonumber(#types)
					room:sendLog(log)
					room:addPlayerMark(player, "&heg_guowu-PlayClear", #types)
					if #types >= 1 then
						local ids = sgs.IntList()
						for _,id in sgs.list(room:getDiscardPile())do
							if sgs.Sanguosha:getCard(id):isKindOf("Slash")
							then ids:append(id) end
						end
						if not ids:isEmpty() then
							local id = ids:at(math.random(1, ids:length()));
							room:obtainCard(player, id)
						end
					end
					if #types >= 2 then
						room:addPlayerMark(player, "heg_guowu-PlayClear", #types)
					end
				end
			end
		elseif event == sgs.CardUsed then
			if player:getMark("heg_guowu-PlayClear") <= 2 then return false end
			if player:getMark("heg_guowu_extra-Clear") > 0 then return false end
			local use = data:toCardUse()
			if not use.card:isKindOf("Slash") then return false end
			local extra_targets = room:getCardTargets(player, use.card, use.to)
			if extra_targets:isEmpty() then return false end
			room:setTag("heg_guowu", data)
			local others = room:askForPlayersChosen(player, extra_targets, self:objectName(), 0, 2, "@heg_guowu", true, true)
			room:removeTag("heg_guowu")
			if others and others:length() > 0 then
				room:addPlayerMark(player, "heg_guowu_extra-Clear")
				for _, p in sgs.qlist(others) do
					use.to:append(p)
				end
				room:sortByActionOrder(use.to)
				data:setValue(use)
			end
		end
		return false
	end
}

heg_guowu_buff = sgs.CreateTargetModSkill {
	name = "#heg_guowu_buff",
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("heg_guowu") and player:getMark("heg_guowu-PlayClear") > 1 then
			return 1000
		end
	end,
}

heg_shenwei_draw = sgs.CreateDrawCardsSkill{
	name = "#heg_shenwei_draw" ,
	frequency = sgs.Skill_Compulsory ,
	draw_num_func = function(self, player, n, room)
		room:sendCompulsoryTriggerLog(player, "heg_shenwei")
		room:broadcastSkillInvoke("heg_shenwei")
		if player:hasSkill("heg_shenwei") then
			local max = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHp() > max then
					max = p:getHp()
				end
			end
			if player:getHp() == max then
				return n + 2
			end
		end
		return 0
	end
}
heg_shenwei = sgs.CreateMaxCardsSkill{
	name = "heg_shenwei",
	extra_func = function(self, target)
		if target:hasSkill(self:objectName()) then
			local max = 0
			for _, p in sgs.qlist(target:getAliveSiblings(true)) do
				if p:getHp() > max then
					max = p:getHp()
				end
			end
			if target:getHp() == max then
				return 2
			end
		else
			return 0
		end
	end
}

heg_zhuangrongCard = sgs.CreateSkillCard{
	name = "heg_zhuangrong",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local skill = sgs.Sanguosha:getSkill("heg_wushuang")
		if skill then
			room:acquireSkill(source, "heg_wushuang")
			room:addPlayerMark(source, "heg_zhuangrong-SelfPlayClear")
			room:addPlayerMark(source, "&heg_zhuangrong-SelfPlayClear")
		end
	end
}

heg_zhuangrongVS = sgs.CreateOneCardViewAsSkill{
	name = "heg_zhuangrong",
	filter_pattern = "TrickCard",
	view_as = function(self, card)
		local skill_card = heg_zhuangrongCard:clone()
		skill_card:addSubcard(card)
		skill_card:setSkillName(self:objectName())
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_zhuangrong")
	end
}
heg_zhuangrong = sgs.CreateTriggerSkill{
	name = "heg_zhuangrong",
	view_as_skill = heg_zhuangrongVS,
	events = {sgs.EventPhaseChanging},
	waked_skills = "heg_wushuang",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.from == sgs.Player_Play then
			if player:getMark("heg_zhuangrong-SelfPlayClear") > 0 then
				room:handleAcquireDetachSkills(player, "-heg_wushuang", true)
			end
		end
	end
}

heg_lvlingqi:addSkill(heg_guowu)
heg_lvlingqi:addSkill(heg_guowu_buff)
extension_heg:insertRelatedSkills("heg_guowu", "#heg_guowu_buff")
heg_lvlingqi:addSkill(heg_shenwei)
heg_lvlingqi:addSkill(heg_shenwei_draw)
extension_heg:insertRelatedSkills("heg_shenwei", "#heg_shenwei_draw")
heg_lvlingqi:addSkill(heg_zhuangrong)

heg_zhouyi = sgs.General(extension_heg, "heg_zhouyi", "wu", 3, false)

heg_zhukou = sgs.CreateTriggerSkill{
	name = "heg_zhukou",
	events = {sgs.Damage},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local current = room:getCurrent()
		if current and current:getPhase() == sgs.Player_Play then
			room:addPlayerMark(player, "heg_zhukou-Clear")
			if player:getMark("heg_zhukou-Clear") == 1 then
				local x = player:getMark("us-Clear")
				if x > 5 then x = 5 end
				if x > 0 then
					if player:askForSkillInvoke(self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(x)
					end
				end
			end
		end
		return false
	end
}

heg_duannian = sgs.CreateTriggerSkill{
	name = "heg_duannian",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			if player:canDiscard(player, "h") then
				if player:askForSkillInvoke(self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					player:throwAllHandCards(self:objectName())
					local x = player:getMaxHp() - player:getHandcardNum()
					if x > 0 then
						player:drawCards(x, self:objectName())
					end
				end
			end
		end
		return false
	end
}

heg_lianyou = sgs.CreateTriggerSkill{
	name = "heg_lianyou",
	events = {sgs.Death },
	waked_skills = "heg_xinghuo",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			local others = room:getOtherPlayers(player)
			if not others:isEmpty() then
				local target = room:askForPlayerChosen(player, others, self:objectName(), "heg_lianyou-invoke", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					room:acquireSkill(target, "heg_xinghuo")
				end
			end
		end
		return false
	end
}

heg_xinghuo = sgs.CreateTriggerSkill{
	name = "heg_xinghuo",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature == sgs.DamageStruct_Fire then
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
		return false
	end
}
	
heg_zhouyi:addSkill(heg_zhukou)
heg_zhouyi:addSkill(heg_duannian)
heg_zhouyi:addSkill(heg_lianyou)
if not sgs.Sanguosha:getSkill("heg_xinghuo") then skills:append(heg_xinghuo) end

heg_nanhualaoxian = sgs.General(extension_heg, "heg_nanhualaoxian", "qun", 3)

heg_gongxiu = sgs.CreateTriggerSkill{
	name = "heg_gongxiu",
	events = {sgs.DrawNCards, sgs.AfterDrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" then return false end
		if event == sgs.DrawNCards then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				draw.num = draw.num - 1
				data:setValue(draw)
				room:addPlayerMark(player, "heg_gongxiu-Clear")
			end
		elseif event == sgs.AfterDrawNCards then
			local choicelist = {}
			if player:getMark("heg_gongxiu_draw") == 0 then
				table.insert(choicelist, "draw")
			end
			if player:getMark("heg_gongxiu_discard") == 0 then
				table.insert(choicelist, "discard")
			end
			local choice = room:askForChoice(player, self:objectName(), table.concat(choicelist, "+"))
			local targets = sgs.SPlayerList()
			room:setPlayerMark(player, "heg_gongxiu_draw", 0)
			room:setPlayerMark(player, "heg_gongxiu_discard", 0)
			if choice == "draw" then
				targets = room:getAlivePlayers()
			else
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:canDiscard(p, "he") then
						targets:append(p)
					end
				end
			end
			if targets:isEmpty() then return false end
			room:addPlayerMark(player, "heg_gongxiu_"..choice, 1)
			local to_select = room:askForPlayersChosen(player, targets, self:objectName(), 1, player:getMaxHp(), "@heg_gongxiu-target:"..choice, true, true)
			if to_select and to_select:length() > 0 then
				room:broadcastSkillInvoke(self:objectName(), choice)
				for _, p in sgs.qlist(to_select) do
					if choice == "draw" then
						p:drawCards(1, self:objectName())
						room:changeTranslation(player, "heg_gongxiu", 2)
					elseif choice == "discard" then
						room:changeTranslation(player, "heg_gongxiu", 1)
						if not p:isNude() then
							room:askForDiscard(p, self:objectName(), 1, 1, false, true)
						end
					end
				end
			end
		end
		return false
	end
}

heg_taidan = sgs.CreateViewAsEquipSkill{
	name = "heg_taidan",
	view_as_equip = function(self,target)
		if target:getArmor()==nil and target:hasSkill("heg_taidan") then
	    	return "PeaceSpell"
		end
	end
}

heg_jingheCard = sgs.CreateSkillCard{
	name = "heg_jinghe",
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local tianshu = { "nosleiji", "nhyinbing", "nhhuoqi", "nhguizhu", "nhxianshou", "nhlundao", "nhguanyue", "nhyanzheng" }
		
		if #tianshu == 0 then return end
		local skill_name = tianshu[math.random(1, #tianshu)]
		local skills = target:getTag("heg_jinghe_GetSkills_"..source:objectName()):toString():split(",")
		if not table.contains(skills,skill_name) then
			table.insert(skills,skill_name)
			target:setTag("heg_jinghe_GetSkills_"..source:objectName(),sgs.QVariant(table.concat(skills,",")))
		end
		room:acquireSkill(target,skill_name)
	end
}
heg_jingheVS = sgs.CreateZeroCardViewAsSkill{
	name = "heg_jinghe",
	
	view_as = function(self, cards)
		return heg_jingheCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_jinghe")
	end
}
heg_jinghe = sgs.CreateTriggerSkill{
	name = "heg_jinghe",
	events = {sgs.EventPhaseStart,sgs.Death},
	view_as_skill = jingheVS,
	waked_skills = "nosleiji,nhyinbing,nhhuoqi,nhguizhu,nhxianshou,nhlundao,nhguanyue,nhyanzheng",
	can_trigger = function(self,player)
		return player
	end,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_RoundStart then return false end
		elseif event == sgs.Death then
			local death = data:toDeath()
			local who = death.who
			if who:objectName() ~= player:objectName() then return false end
		end
		
		for _,p in sgs.qlist(room:getAllPlayers())do
			if p:isDead() then continue end
			local skills = p:getTag("heg_jinghe_GetSkills_"..player:objectName()):toString():split(",")
			p:removeTag("heg_jinghe_GetSkills_"..player:objectName())
			if #skills == 0 or skills[1] == "" then continue end
			local lose = {}
			for _,sk in ipairs(skills)do
				if p:hasSkill(sk,true) then
					table.insert(lose,"-"..sk)
				end
			end
			if #lose > 0 then
				room:handleAcquireDetachSkills(p,table.concat(lose,"|"))
			end
		end
	end
}

heg_nanhualaoxian:addSkill(heg_gongxiu)
heg_nanhualaoxian:addSkill(heg_taidan)
heg_nanhualaoxian:addSkill(heg_jinghe)




heg_ol_dianwei = sgs.General(extension_hegol, "heg_ol_dianwei", "wei", 5)
heg_ol_dianwei:addSkill("qiangxi")

heg_ol_huangzhong = sgs.General(extension_hegol, "heg_ol_huangzhong", "shu")

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
extension_hegol:insertRelatedSkills("heg_ol_liegong","#heg_ol_liegong_Target")

heg_ol_lukang = sgs.General(extension_hegol, "heg_ol_lukang", "wu", 3)
	
heg_ol_lukang:addSkill("heg_mobile_keshou")
heg_ol_lukang:addSkill("heg_tenyear_zhuwei")


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
				ChangeGeneral(room, use.from, "bf_xunyou", use.from:getKingdom())
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
	local choice = room:askForChoice(from, "start_command_"..skill_name, table.concat(commands, "+"))

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

	local choice = room:askForChoice(to, "do_command", choices, ToData(from))

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
		local dest = room:askForPlayerChosen(from, targets, "command1", "#command1-damage:" .. to:objectName(), false, false)
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
				for _, card in sgs.qlist(cards:getSubcards()) do
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
			room:askForDiscard(to, "command6", equip_count-1, equip_count-1, false, true, "#command6-select", ".|.|.|equipped",  "command")
		else
			room:askForDiscard(to, "command6", hand_count-1, hand_count-1, false, false, "#command6-select", "",  "command")
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

heg_jieyue = sgs.CreateTriggerSkill{
	name = "heg_jieyue",
	events = {sgs.EventPhaseProceeding, sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseProceeding then
			if player:getPhase() == sgs.Player_Start then
				local card = room:askForCard(player, "..", "@heg_jieyue-give", sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "heg_jieyue-invoke", false, true)
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

heg_yujin:addSkill(heg_jieyue)

heg_cuiyanmaojie = sgs.General(extension_hegquan, "heg_cuiyanmaojie", "wei", 3)

heg_zhengbi_buff = sgs.CreateTargetModSkill{
	name = "#heg_zhengbi_buff",
	residue_func = function(self, from, card, to)
		if from:hasSkill("heg_zhengbi") and to:getMark("heg_zhengbi"..from:objectName().."-Clear") > 0 then
			return 1000
		end
		return 0
	end,
	distance_limit_func = function(self, from, card, to)
		if from:hasSkill("heg_zhengbi") and to:getMark("heg_zhengbi"..from:objectName().."-Clear") > 0 then
			return 1000
		end
		return 0
	end,
}

heg_zhengbiDiscard = sgs.CreateViewAsSkill{
	name = "#heg_zhengbiDiscard", 
	n = 2, 
	enabled_at_play = function(self, player)
		return  false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@zhengbidiscard!"
	end,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return to_select:isKindOf("BasicCard") or to_select:isKindOf("TrickCard")
		elseif #selected == 1 then
			if selected:first():getTypeId() == sgs.Card_TypeTrick then
				return false
			elseif selected:first():getTypeId() == sgs.Card_TypeBasic then
				return to_select:getTypeId() == sgs.Card_TypeBasic
			end
		else 
			return false
		end
	end, 
	view_as = function(self, cards) 
		local ok = false
		if #cards == 1 then
			ok = cards:first():getTypeId() == sgs.Card_TypeTrick 
		elseif #cards == 2 then
			ok = true
			for _,c in sgs.qlist(cards) do
				if c:getTypeId() == sgs.Card_TypeTrick then
					ok = false
				end
			end
		end
		if not ok then
			return nil
		end
		local dummy = sgs.Sanguosha:cloneCard("slash")
		dummy:addSubcards(cards)
		return dummy
	end
}

heg_zhengbiCard = sgs.CreateSkillCard{
	name = "heg_zhengbi",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:giveCard(effect.from,effect.to,self,"heg_zhengbi",true)
		local prompt = string.format("@heg_zhengbi-receive:%s", effect.from:objectName())
		local recv_card = room:askForCard(effect.to, "@@zhengbidiscard!", prompt)
		if (not recv_card) then
			for _, id in sgs.qlist(effect.to:getCards("he")) do
				local card = sgs.Sanguosha:getCard(id)
				if not card:isKindOf("BasicCard") then
					recv_card:addSubcard(card)
					break
				end
			end
			if recv_card:subcardsLength() < 2 then
				for _, id in sgs.qlist(effect.to:getCards("he")) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("BasicCard") and recv_card:subcardsLength() < 2 then
						recv_card:addSubcard(card)
					end
				end
			end
		end
		if recv_card then
			room:obtainCard(effect.from, recv_card, true)
		end
	end
}

heg_zhengbiVS = sgs.CreateViewAsSkill{
	name = "heg_zhengbi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local skillcard = heg_zhengbiCard:clone()
		skillcard:addSubcard(cards[1])
		skillcard:setSkillName(self:objectName())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@heg_zhengbi"
	end
}

heg_zhengbi = sgs.CreateTriggerSkill{
	name = "heg_zhengbi",
	events = {sgs.EventPhaseStart},
	view_as_skill = heg_zhengbiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, self:objectName(), data) then
			local choice = room:askForChoice(player, self:objectName(), "heg_zhengbi_distance+heg_zhengbi_give+cancel")
			if choice == "heg_zhengbi_distance" then
				local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "heg_zhengbi-distance", false, true)
				room:broadcastSkillInvoke(self:objectName())
				room:setPlayerMark(target, "heg_zhengbi"..player:objectName().."-Clear", 1)
				room:setPlayerMark(target, "&heg_zhengbi+to+#"..player:objectName().."-Clear", 1)
			elseif choice == "heg_zhengbi_give" then
					room:askForUseCard(player, "@@heg_zhengbi", "@heg_zhengbi-give")
			end
		end
	end
}

heg_fengyingVS = sgs.CreateZeroCardViewAsSkill{
	name = "heg_fengying",
	view_as = function()
		local skillcard = sgs.Sanguosha:cloneCard("threaten_emperor", sgs.Card_NoSuit, 0)
		skillcard:setSkillName("heg_fengying")
		skillcard:addSubcards(sgs.Self:handCards())
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@heg_fengying") > 0 and not player:isKongcheng()
	end
}
heg_fengying = sgs.CreateTriggerSkill{
	name = "heg_fengying",
	limit_mark = "@heg_fengying",
	frequency = sgs.Skill_Limited,
	events = {sgs.CardFinished},
	view_as_skill = heg_fengyingVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("threaten_emperor") and use.card:getSkillName() == self:objectName() then
			room:broadcastSkillInvoke(self:objectName())
			local targets = room:askForPlayersChosen(player, room:getAllPlayers(), self:objectName(), 1, 99, "@heg_fengying", true, true)
			for _, to in sgs.qlist(targets) do
				room:doAnimate(1, player:objectName(), to:objectName())
				to:drawCards(to:getMaxHp()-to:getHandcardNum(), self:objectName())
			end
		end
	end
}

heg_cuiyanmaojie:addSkill(heg_zhengbi)
heg_cuiyanmaojie:addSkill(heg_zhengbi_buff)
extension_hegquan:insertRelatedSkills("heg_zhengbi", "#heg_zhengbi_buff")
heg_cuiyanmaojie:addSkill(heg_fengying)


if not sgs.Sanguosha:getSkill("#heg_zhengbiDiscard") then skills:append(heg_zhengbiDiscard) end

heg_wangping = sgs.General(extension_hegquan, "heg_wangping", "shu", 4)

heg_jianglueCard = sgs.CreateSkillCard{
	name = "heg_jianglue",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@heg_jianglue")
		local command = startCommand(source, self:objectName())
		local players = room:askForPlayersChosen(source, room:getAlivePlayers(), self:objectName(), 1, 99, "@heg_jianglue", true, true)
		if players and players:length() > 0 then
			local invoke_count = 0
			local invoked_players = sgs.SPlayerList()
			for _, to in sgs.qlist(players) do
				local invoked = doCommand(to, self:objectName(), command, source)
				if invoked then
					invoked_players:append(to)
				end
			end
			room:gainMaxHp(source, 1, self:objectName())
			room:recover(source, sgs.RecoverStruct("heg_jianglue", source))
			if invoked_players:length() > 0 then
				room:broadcastSkillInvoke(self:objectName())
				for _, to in sgs.qlist(invoked_players) do
					room:gainMaxHp(to, 1, self:objectName())
					room:recover(to, sgs.RecoverStruct("heg_jianglue", source))
				end
				source:drawCards(source:getMark("heg_jianglue-Clear"), self:objectName())
			end
		end
	end
}

heg_jianglueVS = sgs.CreateViewAsSkill{
	name = "heg_jianglue",
	n = 0,
	view_as = function(self, cards)
		return heg_jianglueCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@heg_jianglue") > 0
	end
}
heg_jianglue = sgs.CreateTriggerSkill{
	name = "heg_jianglue",
	limit_mark = "@heg_jianglue",
	frequency = sgs.Skill_Limited,
	events = {sgs.HpRecover},
	view_as_skill = heg_jianglueVS,
	on_trigger = function(self, event, player, data)
		local recover = data:toRecover()
		if recover.reason == self:objectName() then
			if recover.who and recover.who:hasSkill(self:objectName()) then
				local room = player:getRoom()
				room:addPlayerMark(recover.who, "heg_jianglue-Clear")
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

heg_wangping:addSkill(heg_jianglue)

heg_fazheng = sgs.General(extension_hegquan, "heg_fazheng", "shu", 3)


heg_xuanhuoCard = sgs.CreateSkillCard{
	name = "heg_xuanhuo",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and to_select:hasSkill("heg_xuanhuo") and to_select:getMark("heg_xuanhuo"..sgs.Self:objectName().."-PlayClear") == 0
	end,
	on_use = function(self, room, source, targets)
		local skill_list, players = {"tenyearwusheng", "heg_paoxiao", "heg_longdan", "heg_liegong", "tieji", "tenyearkuanggu"}, source:getSiblings()
		players:append(source)
		for _, sib in sgs.qlist(players) do
		    for _, choice_list in ipairs(skill_list) do
			    if sib:hasSkill(choice_list) then
				    table.removeOne(skill_list, choice_list)
			    end
			end
		end
		if #skill_list > 0 then
			local choice = room:askForChoice(source, self:objectName(), table.concat(skill_list, "+"))
			room:giveCard(source, targets[1], self, self:getSkillName())
			if source:canDiscard(source, "he") then
				room:askForDiscard(source, self:objectName(), 1, 1, false, true)
			end
			room:acquireOneTurnSkills(source, "heg_xuanhuo",choice)
			room:setPlayerMark(targets[1], "heg_xuanhuo"..source:objectName().."-PlayClear", 1)
		end
	end,
}

heg_xuanhuoAttach = sgs.CreateViewAsSkill{
	name = "heg_xuanhuoAttach&",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end, 
	view_as = function(self, cards) 
		if #cards ~= 1 then return nil end
		local vscard = heg_xuanhuoCard:clone()
		for _, i in ipairs(cards) do
			vscard:addSubcard(i)
		end
		return vscard
	end,
	enabled_at_play = function(self, player)
		local skill_list, players = {"tenyearwusheng", "heg_paoxiao", "heg_longdan", "heg_liegong", "tieji", "tenyearkuanggu"}, player:getSiblings()
		players:append(player)
		for _, sib in sgs.qlist(players) do
		    for _, choice_list in ipairs(skill_list) do
			    if sib:hasSkill(choice_list) then
				    table.removeOne(skill_list, choice_list)
			    end
			end
		end
		if #skill_list > 0 then
			return not player:isKongcheng()
		end
	end,
}

heg_xuanhuo = sgs.CreateTriggerSkill{
	name = "heg_xuanhuo",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.EventAcquireSkill},
	waked_skills = "tenyearwusheng,heg_paoxiao,heg_longdan,heg_liegong,tieji,tenyearkuanggu",
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) or event == sgs.GameStart then
			if player:hasSkill("heg_xuanhuo") then    
				for _,p in sgs.qlist(room:getAllPlayers()) do
				    if not p:hasSkill("heg_xuanhuoAttach") then
					    room:attachSkillToPlayer(p, "heg_xuanhuoAttach")
					end
				end
			end
		end
	end,
}


heg_enyuan = sgs.CreateTriggerSkill{
	name = "heg_enyuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed, sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Peach") and use.to:contains(player) and use.from and use.from:objectName() ~= player:objectName() then
				room:broadcastSkillInvoke(self:objectName())
				use.from:drawCards(1, self:objectName())
			end
		elseif event == sgs.Damaged then
            local damage = data:toDamage()
            local source = damage.from
            if not source or source == player then return false end
			if source:isAlive() and player:isAlive() then
				local card = nil
				if not source:isKongcheng() then
					source:setTag("enyuan_data", data)
					card = room:askForExchange(source, self:objectName(), 1, 1, false, "EnyuanGive::" .. player:objectName(), true)
					source:removeTag("enyuan_data")
				end
				if (card) then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), player:objectName(), self:objectName(), nil)
					reason.m_playerId = player:objectName()
					room:moveCardTo(card, source, player, sgs.Player_PlaceHand, reason)
				else 
					room:loseHp(source, 1, true, player,self:objectName())
				end
			end
		end
		return false
	end
}


if not sgs.Sanguosha:getSkill("heg_xuanhuoAttach") then skills:append(heg_xuanhuoAttach) end
heg_fazheng:addSkill(heg_xuanhuo)
heg_fazheng:addSkill(heg_enyuan)

heg_lukang = sgs.General(extension_hegquan, "heg_lukang", "wu", 3)

heg_keshouCard = sgs.CreateSkillCard{
	name = "heg_keshou",
	will_throw = true,
	target_fixed = true,
	on_use = function(self, room, source, targets)
	end
}

heg_keshouVS = sgs.CreateViewAsSkill{
	name = "heg_keshou",
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected < 2 then
			if #selected > 0 then
				return to_select:getColor() == selected[1]:getColor()
			else
				return true
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local skillcard = heg_keshouCard:clone()
		skillcard:setSkillName(self:objectName())
		for _, card in ipairs(cards) do
			skillcard:addSubcard(card)
		end
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@heg_keshou"
	end
}

heg_keshou = sgs.CreateTriggerSkill{
	name = "heg_keshou",
	events = {sgs.DamageInflicted},
	view_as_skill = heg_keshouVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() then
				if player:getHandcardNum() + player:getEquips():length() < 2 then return false end
				room:setTag("heg_keshou", data)
				local cards = room:askForUseCard(player, "@@heg_keshou", "@heg_keshou-discard", -1, sgs.Card_MethodDiscard)
				room:removeTag("heg_keshou")
				if cards and cards:subcardsLength() == 2 then
					room:notifySkillInvoked(player, self:objectName())
					player:damageRevises(data, -1)
					local judge = sgs.JudgeStruct()
					judge.who = player
					judge.pattern = ".|red"
					judge.good = true
					judge.reason = self:objectName()
					room:judge(judge)
					if judge:isGood() then
						player:drawCards(1, self:objectName())
					end
				end
			end
		end
		return false
	end
}

heg_zhuwei = sgs.CreateTriggerSkill{
	name = "heg_zhuwei",
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local card = judge.card
		local card_data = sgs.QVariant()
		card_data:setValue(card)
		if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge and (card:isKindOf("Slash") or card:isKindOf("Duel")) and player:askForSkillInvoke(self:objectName(), card_data) then
			player:obtainCard(card)
			local current = room:getCurrent()
			if current and current:isAlive() and player:askForSkillInvoke(self:objectName(), ToData(current)) then
				room:broadcastSkillInvoke(self:objectName())
				room:addSlashCishu(current, 1, true)
				room:addMaxCards(current, 1, true)
				room:addPlayerMark(current, "&heg_zhuwei+to+#"..player:objectName().."-Clear", 1)
			end
		end
		return false
	end
}
heg_lukang:addSkill(heg_keshou)
heg_lukang:addSkill(heg_zhuwei)

heg_wuguotai = sgs.General(extension_hegquan, "heg_wuguotai", "wu", 3, false)

heg_buyi = sgs.CreateTriggerSkill{
	name = "heg_buyi",
	events = {sgs.QuitDying},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if not dying.damage or not dying.damage.from then return false end
		local from = dying.damage.from
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if from and from:isAlive() then
				if room:askForSkillInvoke(p, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local invoked = askCommandTo(p, from, self:objectName(), false)
					if not invoked then
						room:recover(player, sgs.RecoverStruct(self:objectName(), p))
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
heg_wuguotai:addSkill(heg_buyi)
heg_wuguotai:addSkill("ganlu")


heg_yuanshu = sgs.General(extension_hegquan, "heg_yuanshu", "qun", 4, true, true)

heg_yongsi = sgs.CreateViewAsEquipSkill{
	name = "heg_yongsi",
	view_as_equip = function(self, player)
		local can_invoke = true
		for _, p in sgs.qlist(player:getAliveSiblings(true)) do
			if p:getEquip("heg_jade_seal") then
				can_invoke = false
				break
			end
		end
		if can_invoke then
			return "heg_jade_seal"
		end
	end
}
	



heg_zhangxiu = sgs.General(extension_hegquan, "heg_zhangxiu", "qun", 4)

heg_fudi = sgs.CreateTriggerSkill{
	name = "heg_fudi",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local from = damage.from
		if from and from:isAlive() and from:objectName() ~= player:objectName() and not player:isKongcheng() then
			local card = room:askForCard(player, ".|.|.|hand", "@heg_fudi-give:" .. from:objectName(), data, sgs.Card_MethodNone)
			if card then
				room:giveCard(player, from, card, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				local targets = sgs.SPlayerList()
				local max = 0
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getHp() > max then
						max = p:getHp()
					end
				end
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getHp() == max and p:getHp() >= player:getHp() then
						targets:append(p)
					end
				end
				if targets:length() > 0 then
					local dest = room:askForPlayerChosen(player, targets, self:objectName(), "@heg_fudi-damage", false, true)
					if dest then
						room:doAnimate(1, from:objectName(), dest:objectName())
						local damage2 = sgs.DamageStruct()
						damage2.from = player
						damage2.to = dest
						damage2.damage = 1
						damage2.reason = "heg_fudi"
						room:damage(damage2)
					end
				end
			end
		end
		return false
	end
}

heg_congjian = sgs.CreateTriggerSkill{
	name = "heg_congjian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused, sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.DamageCaused then
			if damage.from and damage.from:objectName() == player:objectName() and player:getPhase() == sgs.Player_NotActive then
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
		elseif event == sgs.DamageInflicted then
			if damage.to and damage.to:objectName() == player:objectName() and player:getPhase() ~= sgs.Player_NotActive then
				player:damageRevises(data, 1)
			end
		end
		return false
	end
}

heg_zhangxiu:addSkill(heg_fudi)
heg_zhangxiu:addSkill(heg_congjian)

heg_mengda = sgs.General(extension_heglordex, "heg_mengda", "shu+wei", 4)

heg_qiuan = sgs.CreateTriggerSkill{
	name = "heg_qiuan",
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		
		if player:getPile("heg_qiuan_han"):isEmpty() and damage.card then
			local ids = sgs.IntList()
			if damage.card:isVirtualCard() then
				ids = damage.card:getSubcards()
			else
				ids:append(damage.card:getEffectiveId())
			end
			if ids:isEmpty() then return end
			for _, id in sgs.qlist(ids) do
				if room:getCardPlace(id) ~= sgs.Player_PlaceTable then return end
			end
			if damage.card and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				player:addToPile("heg_qiuan_han", ids, true)
				damage.prevented = true
				data:setValue(damage)
				return true
			end
		end
		return false
	end
}

heg_liangfan = sgs.CreateTriggerSkill{
	name = "heg_liangfan",
	events = {sgs.EventPhaseStart, sgs.Damage},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Start then
				if not player:getPile("heg_qiuan_han"):isEmpty() then
					room:broadcastSkillInvoke(self:objectName())
					local cards_ids = player:getPile("heg_qiuan_han")
					local dummy = sgs.Sanguosha:cloneCard("slash")
					dummy:addSubcards(player:getPile("heg_qiuan_han"))
					dummy:deleteLater()
					room:obtainCard(player, dummy)
					for _, id in sgs.qlist(cards_ids) do
						if room:getCardPlace(id) == sgs.Player_PlaceHand and room:getCardOwner(id):objectName() == player:objectName() then
							room:setCardTip(id, "heg_liangfan")
						end
					end
					room:loseHp(player, 1, true, player,self:objectName())
					for _, card in sgs.qlist(player:getHandcards()) do
				
						local flags = card:getFlags()
						room:writeToConsole("=== Card Flags Debug ===")
						room:writeToConsole("Card ID: " .. card:getEffectiveId())
						-- room:writeToConsole("Total flags: " .. flags:length())
						for _, flag in sgs.qlist(flags) do
							room:writeToConsole("Flag: " .. flag)
						end
						
						-- Get actual card object from Sanguosha
						local real_card = sgs.Sanguosha:getCard(card:getEffectiveId())
						if real_card then
							local real_flags = real_card:getFlags()
							room:writeToConsole("=== Real Card Flags ===")
							room:writeToConsole("Total real flags: " .. real_flags:length())
							for _, flag in sgs.qlist(real_flags) do
								room:writeToConsole("Real Flag: " .. flag)
							end
						end
					end
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card then
				if damage.card:hasTip("heg_liangfan", true) then
					player:gainMark("@hastip")
					if not damage.to:isNude() and room:askForSkillInvoke(player, self:objectName(), data) then
						local id = room:askForCardChosen(player, damage.to, "he", self:objectName())
						local card = sgs.Sanguosha:getCard(id)
						room:obtainCard(player, card, false)
						room:broadcastSkillInvoke(self:objectName(), 2)
					end
				end
			end
		end
		return false
	end
}

heg_mengda:addSkill(heg_qiuan)
heg_mengda:addSkill(heg_liangfan)

heg_liuqi = sgs.General(extension_heglordex, "heg_liuqi", "shu+qun", 3)

heg_wenji_buff = sgs.CreateTargetModSkill{
	name = "#heg_wenji_buff",
	residue_func = function(self, from, card, to)
		if from:hasSkill("heg_wenji") and card and from:getMark("heg_wenji"..card:getEffectiveId().."-Clear") > 0 then
			return 1000
		end
		return 0
	end,
	distance_limit_func = function(self, from, card, to)
		if from:hasSkill("heg_wenji") and card and from:getMark("heg_wenji"..card:getEffectiveId().."-Clear") > 0 then
			return 1000
		end
		return 0
	end,
}

heg_wenji = sgs.CreateTriggerSkill{
	name = "heg_wenji",
	events = {sgs.EventPhaseStart, sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if not p:isNude() then
						targets:append(p)
					end
				end
				if targets:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "heg_wenji-invoke", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					local card = room:askForCard(target, "..!", "@heg_wenji:" .. player:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
					if card then
						room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, target:objectName(), player:objectName(), self:objectName(), ""))
						if room:askForSkillInvoke(target, self:objectName(), ToData(player)) then
							room:setPlayerMark(player, "heg_wenji"..card:getEffectiveId().."-Clear", 1)
							room:setCardTip(card:getEffectiveId(), "heg_wenji-Clear")
						else
							local disable = sgs.IntList()
							disable:append(card:getEffectiveId())
							local id = room:askForCardChosen(player, player, "he", self:objectName(), true, sgs.Card_MethodNone, disable, false)
							if id > -1 then
								local give_card = sgs.Sanguosha:getCard(id)
								room:moveCardTo(give_card, target, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), target:objectName(), self:objectName(), ""))
							end
						end
					end
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.from and use.from:objectName() == player:objectName() then
				local card = use.card
				if player:getMark("heg_wenji"..card:getEffectiveId().."-Clear") > 0 then
					use.m_addHistory = false
					data:setValue(use)
					local log = sgs.LogMessage()
					log.type = "$NoRespond_All"
					log.from = use.from
					log.arg = self:objectName()
					log.card_str = use.card:toString()
					room:sendLog(log)
					local use = data:toCardUse()
					local no_respond_list = use.no_respond_list
					table.insert(no_respond_list, "_ALL_TARGETS")
					use.no_respond_list = no_respond_list
					data:setValue(use)
				end
			end
		end
		return false
	end
}
heg_tunjiang = sgs.CreateTriggerSkill{
	name = "heg_tunjiang",
	events = {sgs.CardUsed,sgs.EventPhaseStart},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("SkillCard") or player:getPhase() ~= sgs.Player_Play then return false end
			for _,p in sgs.qlist(use.to)do
				if p~=player then
					player:addMark("heg_tunjiang-Clear")
					break
				end
			end
		elseif player:getPhase() == sgs.Player_Finish and player:getMark("heg_tunjiang-Clear")<1 and player:hasSkill(self) and player:getMark("usedPlay-Clear") > 0 and player:askForSkillInvoke(self) then
			player:peiyin("tunjiang")
			local kingdoms = {}
			for _,p in sgs.qlist(room:getAlivePlayers())do
				local kingdom = p:getKingdom()
				if not table.contains(kingdoms,kingdom) then
					table.insert(kingdoms,kingdom)
				end
			end
			player:drawCards(#kingdoms,self:objectName())
		end
		return false
	end
}




heg_liuqi:addSkill(heg_wenji_buff)
heg_liuqi:addSkill(heg_wenji)
extension_heglordex:insertRelatedSkills("heg_wenji", "#heg_wenji_buff")
heg_liuqi:addSkill(heg_tunjiang)

heg_mifangfushiren = sgs.General(extension_heglordex,  "heg_mifangfushiren", "shu+wu", 4)

heg_fengshih_buff = sgs.CreateTriggerSkill{
	name = "#heg_fengshih_buff",
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:hasFlag("heg_fengshih") then
			player:damageRevises(data, 1)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

heg_fengshih = sgs.CreateTriggerSkill{
	name = "heg_fengshih",
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from and use.from:objectName() ~= use.to:first():objectName() and use.to:length() == 1 and (use.to:contains(player) or player:objectName() == use.from:objectName()) and not use.card:isKindOf("SkillCard") then
				if use.from:objectName() == player:objectName() then
					local target = use.to:first()
					if (target:getHandcardNum() < player:getHandcardNum() and not target:isNude() and not player:isNude() and player:canDiscard(player, "he") and player:canDiscard(target, "he")) then
							room:broadcastSkillInvoke(self:objectName(), 1)
							local from_card = room:askForCard(player, ".", "@heg_fengshih:" .. target:objectName(), data, self:objectName())
							if from_card then
								local id = room:askForCardChosen(player, target, "he", self:objectName(), false, sgs.Card_MethodDiscard)
								room:throwCard(id, target, player)
								room:setCardFlag(use.card, "heg_fengshih")
							end
						end
					end
				else
					target = use.from
					if (player:getHandcardNum() < target:getHandcardNum() and not target:isNude() and not player:isNude() and target:canDiscard(player, "he") and target:canDiscard(target, "he")) then
						room:broadcastSkillInvoke(self:objectName(), 1)
						local from_card = room:askForCard(target, ".", "@heg_fengshih:" .. player:objectName(), data, self:objectName())
						if from_card then
							local id = room:askForCardChosen(target, player, "he", self:objectName(), false, sgs.Card_MethodDiscard)
							room:throwCard(id, player, target)
							room:setCardFlag(use.card, "heg_fengshih")
						end
					end
				end
			end
		return false
	end,
}
heg_mifangfushiren:addSkill(heg_fengshih_buff)
heg_mifangfushiren:addSkill(heg_fengshih)
extension_heglordex:insertRelatedSkills("heg_fengshih", "#heg_fengshih_buff")

heg_zhanglu = sgs.General(extension_heglordex,  "heg_zhanglu", "qun+wei", 3)

heg_bushi = sgs.CreateTriggerSkill{
	name = "heg_bushi",
	events = {sgs.Damaged, sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() then
				for i = 1, damage.damage do
					local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "heg_bushi-invoke", true, true)
					if target then
						target:drawCards(1, self:objectName())
					else
						break
					end
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName() and damage.from:objectName() ~= damage.to:objectName() then
				local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "heg_bushi-invoke", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName(), 2)
					target:drawCards(1, self:objectName())
				end
			end
		end
		return false
	end
}

heg_midao = sgs.CreateTriggerSkill{
	name = "heg_midao",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetSpecifying, sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecifying then
			local use = data:toCardUse()
			if use.from and use.from:getMark("heg_midao-PlayClear") == 0 and (use.card:isKindOf("Slash") or (use.card:isKindOf("TrickCard") and use.card:isDamageCard())) and use.to:length() > 0 then
				local target = use.to:first()
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					local can_invoke = false
					if p:objectName() == use.from:objectName() then
						if room:askForSkillInvoke(p, self:objectName(), data) then
							can_invoke = true
						end
					elseif not use.from:isKongcheng() then
						local card = room:askForCard(use.from, ".|.|.|hand", "@heg_midao-give:" .. p:objectName(), data, sgs.Card_MethodNone)
						if card then
							room:giveCard(use.from, p, card, self:objectName())
							can_invoke = true
						end
					end
					if can_invoke then
						local suit = room:askForSuit(p, self:objectName())
						local nature = room:askForChoice(p, self:objectName(), "fire+thunder+ice+normal")
						ChoiceLog(p, nature)
						use.card:setTag("heg_midao_nature", sgs.QVariant(nature))
						room:setPlayerMark(use.from, "heg_midao-PlayClear", 1)
						if use.card:getSuit() ~= suit then
							room:sendCompulsoryTriggerLog(p, self:objectName())
							local log = sgs.LogMessage()
							log.type = "#heg_midao_suit"
							log.from = use.from
							log.card_str = use.card:toString()
							log.arg = sgs.Card_Suit2String(suit)
							room:sendLog(log)
							local wc = sgs.Sanguosha:getWrappedCard(use.card:getEffectiveId())
							wc:setSuit(suit)
							wc:setModified(true)
							room:broadcastUpdateCard(room:getPlayers(), use.card:getEffectiveId(), wc)

							-- use:changeCard(wc)
							-- data:setValue(use)
							
						end
					end
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:getTag("heg_midao_nature"):toString() ~= "" then
				local nature = damage.card:getTag("heg_midao_nature"):toString()
				
				damage.nature = sgs.DamageStruct_Normal
				if nature == "fire" then
					damage.nature = sgs.DamageStruct_Fire
				elseif nature == "thunder" then
					damage.nature = sgs.DamageStruct_Thunder
				elseif nature == "ice" then
					damage.nature = sgs.DamageStruct_Ice
				end
				data:setValue(damage)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

heg_zhanglu:addSkill(heg_bushi)
heg_zhanglu:addSkill(heg_midao)

heg_shixie = sgs.General(extension_heglordex,  "heg_shixie", "qun+wu", 3)

heg_lixia = sgs.CreateTriggerSkill{
	name = "heg_lixia",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if not player:inMyAttackRange(p) and p:objectName() ~= player:objectName() then
					room:sendCompulsoryTriggerLog(p, self:objectName())
					local choieclist = {}
					table.insert(choieclist, "draw="..p:objectName())
					if not p:getEquips():isEmpty() and player:canDiscard(p, "e") then
						table.insert(choieclist, "discard="..p:objectName())
					end
					local choice = room:askForChoice(player, self:objectName(), table.concat(choieclist, "+"), ToData(p))
					if string.startsWith(choice, "draw") then
						room:broadcastSkillInvoke(self:objectName(), 1)
						p:drawCards(1, self:objectName())
					elseif string.startsWith(choice, "discard") then
						room:broadcastSkillInvoke(self:objectName(), 2)
						if player:canDiscard(p, "e") then
							local id = room:askForCardChosen(player, p, "e", self:objectName(), false, sgs.Card_MethodDiscard)
							local card = sgs.Sanguosha:getCard(id)
							room:throwCard(card, p, player)
						end
						room:loseHp(player, 1, true, p,self:objectName())
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

heg_biluan = sgs.CreateDistanceSkill{
	name = "heg_biluan",
	correct_func = function(self, from, to)
        if to:hasSkill("heg_biluan") then
            return to:getEquips():length()
        end
	end
}

heg_shixie:addSkill(heg_lixia)
heg_shixie:addSkill(heg_biluan)

heg_nos_shixie = sgs.General(extension_heglordex,  "heg_nos_shixie", "qun+wu", 3)

heg_nos_lixia = sgs.CreateTriggerSkill{
	name = "heg_nos_lixia",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getEquips():length() > 0 and player:canDiscard(p, "e") then
					if room:askForSkillInvoke(player, self:objectName(), ToData(p)) then
						local id = room:askForCardChosen(player, p, "e", self:objectName(), false, sgs.Card_MethodDiscard, sgs.IntList(), true)
						if id > -1 then
							local card = sgs.Sanguosha:getCard(id)
							room:throwCard(card, p, player)
							local choieclist = {}
							table.insert(choieclist, "draw="..p:objectName())
							if player:getCardCount(true) >= 2 then
								table.insert(choieclist, "discard")
							end
							table.insert(choieclist, "losehp")
							local choice = room:askForChoice(player, self:objectName(), table.concat(choieclist, "+"), ToData(p))
							if string.startsWith(choice, "draw") then
								p:drawCards(2, self:objectName())
							elseif string.startsWith(choice, "discard") then
								room:askForDiscard(player, self:objectName(), 2, 2, false, true)
							elseif choice == "losehp" then
								room:loseHp(player, 1, true, p,self:objectName())
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

heg_nos_biluan = sgs.CreateDistanceSkill{
	name = "heg_nos_biluan",
	correct_func = function(self, from, to)
        if to:hasSkill("heg_nos_biluan") then
            return math.max(to:getEquips():length(), 1)
        end
	end
}

heg_nos_shixie:addSkill(heg_nos_lixia)
heg_nos_shixie:addSkill(heg_nos_biluan)

heg_tangzi = sgs.General(extension_heglordex,  "heg_tangzi", "wu+wei", 4)

heg_xingzhao_buff = sgs.CreateMaxCardsSkill{
	name = "#heg_xingzhao_buff",
	extra_func = function(self, target)
		if target:hasSkill("heg_xingzhao") then
			local kingdoms = {}
			for _,p in sgs.qlist(target:getAliveSiblings(true))do
				local kingdom = p:getKingdom()
				if not table.contains(kingdoms,kingdom) and p:isWounded() then
					table.insert(kingdoms,kingdom)
				end
			end
			if #kingdoms >=3 then
				return 4
			end
		end
		return 0
	end
}
heg_xingzhao_clear = sgs.CreateTriggerSkill{
	name = "#heg_xingzhao_clear",
	events = {sgs.HpChanged, sgs.MaxHpChanged, sgs.Death, sgs.KingdomChanged, sgs.EventAcquireSkill, sgs.EventLoseSkill, },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventLoseSkill and data:toString() == "heg_xingzhao" then
			local kingdoms = {}
			for _,p in sgs.qlist(room:getAlivePlayers())do
				local kingdom = p:getKingdom()
				if not table.contains(kingdoms,kingdom) and p:isWounded() then
					table.insert(kingdoms,kingdom)
				end
			end
			if #kingdoms >=1 then
				room:handleAcquireDetachSkills(player, "-xunxun", true)
			end
		else
			local kingdoms = {}
			for _,p in sgs.qlist(room:getAlivePlayers())do
				local kingdom = p:getKingdom()
				if not table.contains(kingdoms,kingdom) and p:isWounded() then
					table.insert(kingdoms,kingdom)
				end
			end
			if #kingdoms >=1 then
				for _, p in sgs.qlist(room:findPlayersBySkillName("heg_xingzhao")) do
					room:handleAcquireDetachSkills(p, "xunxun", true)
				end
			else
				for _, p in sgs.qlist(room:findPlayersBySkillName("heg_xingzhao")) do
					room:handleAcquireDetachSkills(p, "-xunxun", true)
				end
			end
		end
		
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

heg_xingzhao = sgs.CreateTriggerSkill{
	name = "heg_xingzhao",
	waked_skills = "xunxun",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged, sgs.CardsMoveOneTime },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() then
				local kingdoms = {}
				for _,p in sgs.qlist(room:getAlivePlayers())do
					local kingdom = p:getKingdom()
					if not table.contains(kingdoms,kingdom) and p:isWounded() then
						table.insert(kingdoms,kingdom)
					end
				end
				if #kingdoms >=2 then
					local target
					if damage.from and damage.from:isAlive() then
						if damage.from:getHandcardNum() < player:getHandcardNum() then
							target = damage.from
						elseif player:getHandcardNum() < damage.from:getHandcardNum() then
							target = player
						end
					else
						target = player
					end
					if target then
						room:broadcastSkillInvoke(self:objectName())
						target:drawCards(1, self:objectName())
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
				local kingdoms = {}
				for _,p in sgs.qlist(room:getAlivePlayers())do
					local kingdom = p:getKingdom()
					if not table.contains(kingdoms,kingdom) and p:isWounded() then
						table.insert(kingdoms,kingdom)
					end
				end
				if #kingdoms >=4 then
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1, self:objectName())
				end
			end
		end
		return false
	end
}

heg_tangzi:addSkill(heg_xingzhao_buff)
heg_tangzi:addSkill(heg_xingzhao_clear)
heg_tangzi:addSkill(heg_xingzhao)
extension_heglordex:insertRelatedSkills("heg_xingzhao", "#heg_xingzhao_buff")
extension_heglordex:insertRelatedSkills("heg_xingzhao", "#heg_xingzhao_clear")

heg_dongzhao = sgs.General(extension_heglordex,  "heg_dongzhao", "wei", 3)

heg_quanjinCard = sgs.CreateSkillCard{
	name = "heg_quanjin",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:getMark("heg_quanjin-PlayClear") > 0 and to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:giveCard(source, targets[1], self, "heg_quanjin")
		local target = targets[1]
		local invoked = askCommandTo(source, target, "heg_quanjin")
		if invoked then
			source:drawCards(1, "heg_quanjin")
		else
			local max = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHandcardNum() > max then
					max = p:getHandcardNum()
				end
			end
			local draw_num = math.min(5, max - source:getHandcardNum())
			if draw_num > 0 then
				source:drawCards(draw_num, "heg_quanjin")
			end
		end
	end
}

heg_quanjinVS = sgs.CreateViewAsSkill{
	name = "heg_quanjin",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = heg_quanjinCard:clone()
			card:addSubcard(cards[1])
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_quanjin")
	end
}
heg_quanjin = sgs.CreateTriggerSkill{
	name = "heg_quanjin",
	view_as_skill = heg_quanjinVS,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to and damage.to:objectName() == player:objectName() then
			room:setPlayerMark(player, "heg_quanjin-PlayClear", 1)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

heg_zaoyunCard = sgs.CreateSkillCard{
	name = "heg_zaoyun",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			local distance = sgs.Self:distanceTo(to_select)
			return distance > 1 and self:subcardsLength() == distance -1
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:setFixedDistance(source, target, 1)
		room:addPlayerMark(target, "&heg_zaoyun+to+#" .. source:objectName() .. "-Clear", 1)
		room:damage(sgs.DamageStruct("heg_zaoyun", source, target))
	end
}
heg_zaoyunVS = sgs.CreateViewAsSkill{
	name = "heg_zaoyun",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = heg_zaoyunCard:clone()
			for _, c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_zaoyun")
	end
}

heg_zaoyun = sgs.CreateTriggerSkill{
	name = "heg_zaoyun",
	view_as_skill = heg_zaoyunVS,
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("&heg_zaoyun+to+#" .. player:objectName() .. "-Clear") > 0 then
					room:removeFixedDistance(player, p, 1)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

heg_dongzhao:addSkill(heg_quanjin)
heg_dongzhao:addSkill(heg_zaoyun)

heg_xushu = sgs.General(extension_heglordex,  "heg_xushu", "shu", 3)

heg_qiance = sgs.CreateTriggerSkill{
	name = "heg_qiance",
	events = { sgs.TargetConfirmed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.from and use.card:isKindOf("TrickCard") then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(use.to) do
				if IsBigKingdomPlayer(p) then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					no_respond_list = use.no_respond_list
					for _, p in sgs.qlist(targets) do
						table.insert(no_respond_list, p:objectName())
					end
					use.no_respond_list = no_respond_list
					room:sendCompulsoryTriggerLog(player, self:objectName(), true)
					data:setValue(use)
					local log = sgs.LogMessage()
					log.type = "$NoRespond"
					log.from = use.from
					log.to = targets
					log.arg = self:objectName()
					log.card_str = use.card:toString()
					room:sendLog(log)
				end
			end
		end
		return false
	end,
}

heg_jujian = sgs.CreateTriggerSkill{
	name = "heg_jujian",
	events = { sgs.EnterDying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who and dying.who:objectName() == player:objectName() then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if room:askForSkillInvoke(p, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					room:recover(player, sgs.RecoverStruct(p, nil, 1-player:getHp(), self:objectName()))
					ChangeGeneral(room, p, "heg_xushu", p:getKingdom())
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

heg_xushu:addSkill(heg_qiance)
heg_xushu:addSkill(heg_jujian)

heg_yanbaihu = sgs.General(extension_heglordex,  "heg_yanbaihu", "qun", 3)

heg_zhidao_prohibit = sgs.CreateProhibitSkill{
	name = "#heg_zhidao_prohibit",
	is_prohibited = function(self, from, to, card)
		if from and from:hasSkill("heg_zhidao") and card and not card:isKindOf("SkillCard") then
			local invoke = false
			for _, p in sgs.qlist(from:getAliveSiblings()) do
				if p:getMark("&heg_zhidao+to+#" .. from:objectName() .. "-Clear") > 0 then
					invoke = true
					break
				end
			end
			if invoke and to and to:objectName() ~= from:objectName() and to:getMark("&heg_zhidao+to+#" .. from:objectName() .. "-Clear") == 0 then
				return true
			end
		end
	end
}

heg_zhidao_Clear = sgs.CreateTriggerSkill{
	name = "#heg_zhidao_Clear",
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("&heg_zhidao+to+#" .. player:objectName() .. "-Clear") > 0 then
					room:removeFixedDistance(player, p, 1)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

heg_zhidao = sgs.CreateTriggerSkill{
	name = "heg_zhidao",
	events = { sgs.EventPhaseStart, sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
				if target then
					room:addPlayerMark(target, "&heg_zhidao+to+#" .. player:objectName() .. "-Clear", 1)
					room:setFixedDistance(player, target, 1)
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to and damage.to:getMark("&heg_zhidao+to+#" .. player:objectName() .. "-Clear") > 0 and player:getMark("heg_zhidao-Clear") == 0 then
				if not damage.to:isAllNude() then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					local id = room:askForCardChosen(player, damage.to, "hej", self:objectName(), false, sgs.Card_MethodNone)
					local card = sgs.Sanguosha:getCard(id)
					room:obtainCard(player, card, false)
				end
				room:setPlayerMark(player, "heg_zhidao-Clear", 1)
			end
		end
		return false
	end,
}

heg_jilix_buff = sgs.CreateTriggerSkill{
	name = "#heg_jilix_buff",
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:hasFlag("heg_jilix") then
			room:setCardFlag(use.card, "-heg_jilix")
            if use.from:objectName() == player:objectName() then
                local targets = sgs.SPlayerList()
                for _,to in sgs.qlist(use.to) do
                    if to:isAlive() then
                        targets:append(to)
                    end
                end
                if (not targets:isEmpty()) then
                    local use_again = sgs.CardUseStruct(use.card,player,targets)
				    room:setTag("UseHistory"..use.card:toString(),ToData(use_again))
				    use.card:use(room,player,targets)
                end
            end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
heg_jilix = sgs.CreateTriggerSkill{
	name = "heg_jilix",
	events = { sgs.TargetConfirmed, sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.from and use.to:length() == 1 and use.to:contains(player) and use.card:isRed() and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then
				room:setCardFlag(use.card, "heg_jilix")
				room:sendCompulsoryTriggerLog(player, self:objectName())
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() then
				room:addPlayerMark(player, "heg_jilix-Clear", 1)
				if player:getMark("heg_jilix-Clear") >= 2 then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					local log = sgs.LogMessage()
					if player:getGeneralName() == "heg_yanbaihu" then
						log.type = "#YHXiandao1"
						log.arg = player:getGeneralName()
						log.from = player
						room:sendLog(log)
						if player:getGeneral2() then
							local name = player:getGeneral2Name()
							room:changeHero(player, "", false, false, true, false)
							room:changeHero(player, name, false, false, false, false)
						else
							local maxhp = player:getMaxHp()
							local hp = player:getHp()
							room:changeHero(player, "heg_sujiang", false, false, false, false)
							room:setPlayerProperty(player, "maxhp", sgs.QVariant(maxhp))
							room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
						end
					elseif player:getGeneral2Name() == "heg_yanbaihu" then
						log.type = "#YHXiandao2"
						log.arg = player:getGeneral2Name()
						log.from = player
						room:sendLog(log)
						room:changeHero(player, "", false, false, true, false)
					else
						room:handleAcquireDetachSkills(player, "-heg_zhidao")
						room:handleAcquireDetachSkills(player, "-heg_jilix")
					end
					damage.prevented = true
					data:setValue(damage)
					return true
				end
			end
		end
		return false
	end,
}

heg_yanbaihu:addSkill(heg_zhidao)
heg_yanbaihu:addSkill(heg_zhidao_prohibit)
heg_yanbaihu:addSkill(heg_zhidao_Clear)
heg_yanbaihu:addSkill(heg_jilix)
heg_yanbaihu:addSkill(heg_jilix_buff)
extension_heglordex:insertRelatedSkills("heg_zhidao", "#heg_zhidao_prohibit")
extension_heglordex:insertRelatedSkills("heg_zhidao", "#heg_zhidao_Clear")
extension_heglordex:insertRelatedSkills("heg_jilix", "#heg_jilix_buff")

heg_wenqin = sgs.General(extension_heglordex,  "heg_wenqin", "wei+wu", 4)

heg_jinfaCard = sgs.CreateSkillCard{
	name = "heg_jinfa",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isNude()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if not target:isNude() then
			local give_card = room:askForCard(target, "EquipCard", "@heg_jinfa:"..source:objectName(), ToData(source), sgs.Card_MethodNone) 
			if give_card then
				room:giveCard(target, source, give_card, "heg_jinfa")
				if give_card:getSuit() == sgs.Card_Spade then
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("heg_jinfa")
					slash:deleteLater()
					local use = sgs.CardUseStruct()
					use.card = slash
					use.from = target
					use.to:append(source)
					room:useCard(use)
				end
			else
				if not target:isNude() then
					local id = room:askForCardChosen(source, target, "he", "heg_jinfa", false, sgs.Card_MethodNone)
					local card = sgs.Sanguosha:getCard(id)
					room:obtainCard(source, card, false)
				end
			end
		end
	end
}

heg_jinfa = sgs.CreateViewAsSkill{
	name = "heg_jinfa",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = heg_jinfaCard:clone()
			card:addSubcard(cards[1])
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_jinfa")
	end
}

heg_wenqin:addSkill(heg_jinfa)

heg_xiahouba = sgs.General(extension_heglordex,  "heg_xiahouba", "shu", 4)

heg_baolie_buff = sgs.CreateTargetModSkill{
	name = "#heg_baolie_buff",
	pattern = "Slash",
	distance_limit_func = function(self, from, card, to)
		if from:hasSkill("heg_baolie") and to:getHp() >= from:getHp() then
			return 1000
		end
		return 0
	end,
	residue_func = function(self, from, card, to)
		if from:hasSkill("heg_baolie") and to:getHp() >= from:getHp() then
			return 1000
		end
		return 0
	end
}

heg_baolie = sgs.CreateTriggerSkill{
	name = "heg_baolie",
	events = { sgs.EventPhaseStart },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			local others = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:inMyAttackRange(player) then
					others:append(p)
				end
			end
			if others:isEmpty() then return false end
			local targets = room:askForPlayersChosen(player, others, self:objectName(), 1, others:length(), "@heg_baolie", true, true)
			for _, target in sgs.qlist(targets) do
				local use_slash = room:askForUseSlashTo(target,player,"@heg_baolie_slash:"..player:objectName(),false)
				if use_slash then
				else
					if player:canDiscard(target, "he") then
						local id = room:askForCardChosen(player, target, "he", "heg_baolie", false, sgs.Card_MethodDiscard)
						local card = sgs.Sanguosha:getCard(id)
						room:throwCard(card, target, player)
					end
				end
			end
		end
		return false
	end,
}

heg_xiahouba:addSkill(heg_baolie_buff)
heg_xiahouba:addSkill(heg_baolie)
extension_heglordex:insertRelatedSkills("heg_baolie", "#heg_baolie_buff")

heg_xuyou = sgs.General(extension_heglordex,  "heg_xuyou", "wei+qun", 3)

heg_shicai = sgs.CreateTriggerSkill{
	name = "heg_shicai",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		room:sendCompulsoryTriggerLog(player, self:objectName())
		if damage.damage == 1 then
			player:drawCards(1, self:objectName())
		else
			room:askForDiscard(player, self:objectName(), 2, 2, false, true)
		end
		return false
	end,
}

heg_chenglue = sgs.CreateTriggerSkill{
	name = "heg_chenglue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardFinished, sgs.Damaged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() and player:hasSkill(self:objectName()) and damage.card then
				room:setCardFlag(damage.card, "heg_chenglue".. player:objectName())
			end
			return false
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.to:length() > 1 and not use.card:isKindOf("SkillCard") then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if use.from:isAlive() and room:askForSkillInvoke(p, self:objectName(), ToData(use.from)) then
						room:doAnimate(1, p:objectName(), use.from:objectName())
						room:drawCards(use.from, 1, self:objectName())
					end
					if use.card:hasFlag("heg_chenglue".. p:objectName()) then
						local target = room:askForPlayerChosen(p, room:getAlivePlayers(), self:objectName(), "heg_chenglue-invoke", true, true)
						if target and target:getMark("@heg_yinyangyu") == 0 and target:getMark("@heg_xianqu") == 0 then
							room:broadcastSkillInvoke(self:objectName())
							target:gainMark("@heg_yinyangyu")
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

heg_xuyou:addSkill(heg_shicai)
heg_xuyou:addSkill(heg_chenglue)

heg_sufei = sgs.General(extension_heglordex,  "heg_sufei", "wu+qun", 4)

heg_lianpian_record = sgs.CreateTriggerSkill{
    name = "#heg_lianpian_record",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		local source = -1
		local players = room:findPlayersBySkillName("heg_lianpian")
		if players:isEmpty() then return false end
		if move.from and move.reason.m_playerId and move.to_place == sgs.Player_DiscardPile and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD then
			local player = room:findPlayerByObjectName(move.reason.m_playerId)
			if player and player:getPhase() ~= sgs.Player_NotActive then
				room:addPlayerMark(player, "heg_lianpian-Clear", move.card_ids:length())
			end
		end
	end
}

heg_lianpian = sgs.CreateTriggerSkill{
	name = "heg_lianpian",
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self, event, player, data, room)
		if player:getPhase() == sgs.Player_Finish then
			if player:hasSkill(self:objectName()) then
				local count = player:getMark("heg_lianpian-Clear")
				if count > player:getHp() then
					room:broadcastSkillInvoke(self:objectName())
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getHandcardNum() < p:getMaxHp() then
							targets:append(p)
						end
					end
					if targets:isEmpty() then return false end
					local target = room:askForPlayerChosen(player, targets, self:objectName(), "heg_lianpian-invoke", true, true)
					if target then
						room:doAnimate(1, player:objectName(), target:objectName())
						local max_hp = target:getMaxHp()
						if target:getHandcardNum() < max_hp then
							target:drawCards(max_hp - target:getHandcardNum(), self:objectName())
						end
					end
				end
			end
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:objectName() ~= player:objectName() then
					local count = player:getMark("heg_lianpian-Clear")
					if count > p:getHp() then
						room:broadcastSkillInvoke(self:objectName())
						local choicelist = {}
						if player:canDiscard(p, "he") then
							table.insert(choicelist, "discard=" .. p:objectName())
						end
						if p:isWounded() then
							table.insert(choicelist, "recover=" .. p:objectName())
						end
						if #choicelist == 0 then return false end
						table.insert(choicelist, "cancel")
						room:setPlayerFlag(p, "heg_lianpianTarget")
						local choice = room:askForChoice(player, self:objectName(), table.concat(choicelist, "+"), ToData(p))
						room:setPlayerFlag(p, "-heg_lianpianTarget")
						if string.startsWith(choice, "discard") then
							if player:canDiscard(p, "he") then
								local id = room:askForCardChosen(player, p, "he", self:objectName(), false, sgs.Card_MethodDiscard)
								local card = sgs.Sanguosha:getCard(id)
								room:throwCard(card, p, player)
							end
						elseif string.startsWith(choice, "recover") then
							room:recover(p, sgs.RecoverStruct(player, nil, 1, self:objectName()))
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
heg_sufei:addSkill(heg_lianpian_record)
heg_sufei:addSkill(heg_lianpian)
extension_heglordex:insertRelatedSkills("heg_lianpian", "#heg_lianpian_record")

heg_panjun = sgs.General(extension_heglordex,  "heg_panjun", "wu+shu", 3)

heg_congcha_buff = sgs.CreateTriggerSkill{
	name = "#heg_congcha_buff",
	events = {sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		for _, p in sgs.qlist(room:findPlayersBySkillName("heg_congcha")) do
			if player:getMark("&heg_congcha+to+#" .. p:objectName()) > 0 then
				if room:askForSkillInvoke(player, "heg_congcha", ToData(p)) then
					p:drawCards(2, "heg_congcha")
					player:drawCards(2, "heg_congcha")
				else
					room:loseHp(player, 1, true, p,"heg_congcha")
				end
				room:removePlayerMark(player, "&heg_congcha+to+#" .. p:objectName())
				room:removePlayerMark(player, "canDamageheg_congcha")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}
heg_congcha_Clear = sgs.CreateTriggerSkill{
	name = "#heg_congcha_Clear",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_RoundStart then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("&heg_congcha+to+#" .. player:objectName()) > 0 then
					room:removePlayerMark(p, "&heg_congcha+to+#" .. player:objectName())
					room:removePlayerMark(player, "canDamageheg_congcha")
				end
			end
		end
		return false
	end,
}

heg_congcha = sgs.CreateTriggerSkill{
	name = "heg_congcha",
	events = { sgs.EventPhaseProceeding, sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseProceeding then
			if player:getPhase() == sgs.Player_Start then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:getMark("heg_congcha".. p:objectName()) == 0 then
						targets:append(p)
					end
				end
				if targets:isEmpty() then return false end
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "heg_congcha-invoke", true, true)
				if target then
					room:addPlayerMark(target, "&heg_congcha+to+#"..player:objectName(), 1)
					room:addPlayerMark(player, "heg_congcha".. target:objectName())
					room:addPlayerMark(player, "heg_congcha-Clear")
					room:addPlayerMark(target, "canDamageheg_congcha")
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			if player:getMark("heg_congcha-Clear") ~= 0 then return false end
			if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
			draw.num = draw.num + 2
			data:setValue(draw)
		end
		return false
	end,
}

heg_panjun:addSkill("gongqing")
heg_panjun:addSkill(heg_congcha)
heg_panjun:addSkill(heg_congcha_buff)
heg_panjun:addSkill(heg_congcha_Clear)
extension_heglordex:insertRelatedSkills("heg_congcha", "#heg_congcha_buff")
extension_heglordex:insertRelatedSkills("heg_congcha", "#heg_congcha_Clear")

heg_pengyang = sgs.General(extension_heglordex,  "heg_pengyang", "shu+qun", 3)

heg_jinxian = sgs.CreateTriggerSkill{
	name = "heg_jinxian",
	events = { sgs.EventPhaseStart, sgs.Damaged },
	frequency = sgs.Skill_Limited,
	limit_mark = "@heg_jinxian",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart)
		or (event == sgs.Damaged) then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAllPlayers()) do
				if player:distanceTo(p) <= 1 then
					targets:append(p)
				end
			end
			if player:getMark("@heg_jinxian") > 0 and not targets:isEmpty() and room:askForSkillInvoke(player, self:objectName()) then
				room:removePlayerMark(player, "@heg_jinxian")
				room:broadcastSkillInvoke(self:objectName())
				for _, p in sgs.qlist(targets) do
					if p:canDiscard(p, "he") then
						room:askForDiscard(p, self:objectName(), 2, 2, false, true)
					end
				end
			end
			
		end
		return false
	end,
}

heg_tongling_prohibit = sgs.CreateProhibitSkill{
	name = "#heg_tongling_prohibit",
	is_prohibited = function(self, from, to, card)
		if from and from:hasFlag("heg_tongling_From") then
			if to and not to:hasFlag("heg_tongling_To") then
				return true
			end
		end
	end
}

heg_tongling_buff = sgs.CreateTriggerSkill{
	name = "#heg_tongling_buff",
	events = {sgs.CardFinished},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:hasFlag("heg_tongling") then
			if use.from:objectName() == player:objectName() then
				if use.card:hasFlag("DamageDone") then
					room:setPlayerFlag(player, "heg_tongling_damage")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

heg_tongling = sgs.CreateTriggerSkill{
	name = "heg_tongling",
	events = { sgs.Damage },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if player:getPhase() == sgs.Player_Play and damage.to and damage.to:objectName() ~= player:objectName() and damage.to:isAlive() and player:getMark("heg_tongling-PlayClear") == 0 then
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "heg_tongling-invoke", true, true)
			if target then
				room:setPlayerMark(player, "heg_tongling-PlayClear", 1)
				room:setPlayerFlag(target, "heg_tongling_From")
				room:setPlayerFlag(damage.to, "heg_tongling_To")
				local pattern = {}
				for _, card in sgs.qlist(target:getHandcards()) do
					if not sgs.Sanguosha:isProhibited(target, damage.to, card) and card:isAvailable(target) and CanToCard(card,target,damage.to) then
						table.insert(pattern, card:getEffectiveId())
					end
				end
				if #pattern > 0 then
					if room:askForUseCard(target, table.concat(pattern, ","), "@heg_tongling:"..damage.to:objectName(), -1, sgs.Card_MethodUse, false, player, nil, "heg_tongling") then
						if target:hasFlag("heg_tongling_damage") then
							room:setPlayerFlag(target, "-heg_tongling_damage")
							player:drawCards(2, self:objectName())
							target:drawCards(2, self:objectName())
						else
							local ids = sgs.IntList()
							if damage.card:isVirtualCard() then
								ids = damage.card:getSubcards()
							else
								ids:append(damage.card:getEffectiveId())
							end
							if not ids:isEmpty() then
								local invoke = true
								for _, id in sgs.qlist(ids) do
									if room:getCardPlace(id) ~= sgs.Player_PlaceTable then invoke = false break end
								end
								if invoke then
									damage.to:obtainCard(damage.card)
								end
							end
						end
					end
				end
				room:setPlayerFlag(target, "-heg_tongling_From")
				room:setPlayerFlag(damage.to, "-heg_tongling_To")
			end
		end
	end
}

heg_pengyang:addSkill(heg_jinxian)
heg_pengyang:addSkill(heg_tongling_prohibit)
heg_pengyang:addSkill(heg_tongling)
heg_pengyang:addSkill(heg_tongling_buff)
extension_heglordex:insertRelatedSkills("heg_tongling", "#heg_tongling_prohibit")
extension_heglordex:insertRelatedSkills("heg_tongling", "#heg_tongling_buff")

heg_nos_pengyang = sgs.General(extension_heglordex,  "heg_nos_pengyang", "shu+qun", 3)

heg_nos_daming = sgs.CreateTriggerSkill{
	name = "heg_nos_daming",
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				room:broadcastSkillInvoke(self:objectName())
				local card = room:askForCard(p, "TrickCard", "@heg_nos_daming", ToData(player), self:objectName())
				if card then
					local targets = sgs.SPlayerList()
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if not p:isChained() then
							targets:append(p)
						end
					end
					if targets:isEmpty() then return false end
					local target = room:askForPlayerChosen(p, targets, self:objectName())
					room:setPlayerChained(target)
					local x = 0
					local factions = {}
					for _, p in sgs.qlist(room:getAllPlayers()) do
						if p:isChained() then
							if not table.contains(factions, p:getKingdom()) then
								table.insert(factions, p:getKingdom())
								x = x + 1
							end
						end
					end
					p:drawCards(x, self:objectName())
					local choices = {}
					local current = room:getCurrent()
					local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
					peach:setSkillName(self:objectName())
					peach:deleteLater()
					if not sgs.Sanguosha:isProhibited(p, current, peach) and peach:isAvailable(p) then
						table.insert(choices, "peach")
					end 
					local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
					thunder_slash:setSkillName(self:objectName())
					thunder_slash:deleteLater()
					for _, q in sgs.qlist(room:getOtherPlayers(current)) do
						if not sgs.Sanguosha:isProhibited(current, q, thunder_slash) and thunder_slash:isAvailable(current) and current:canSlash(q, thunder_slash, false) then
							table.insert(choices,"thunder_slash")
							break
						end
					end
					local choice = room:askForChoice(p, self:objectName(), table.concat(choices, "+"), ToData(player))
					if choice == "peach" then
						local use = sgs.CardUseStruct()
						use.card = peach
						use.from = p
						use.to:append(current)
						room:useCard(use)
					elseif choice == "thunder_slash" then
						local targets = sgs.SPlayerList()
						for _, q in sgs.qlist(room:getOtherPlayers(current)) do
							if not sgs.Sanguosha:isProhibited(current, q, thunder_slash) and thunder_slash:isAvailable(current) and current:canSlash(q, thunder_slash, false) then
								targets:append(q)
							end
						end
						local use = sgs.CardUseStruct()
						use.card = thunder_slash
						use.from = current
						local to = room:askForPlayerChosen(p, targets, self:objectName().."_slash", "@heg_nos_daming-thunder_slash", false, true)
						if to then
							use.to:append(to)
							room:useCard(use)
						end
					end
				end
			end
		end
	end
}

heg_nos_xiaoni = sgs.CreateTriggerSkill{
	name = "heg_nos_xiaoni",
	events = { sgs.TargetConfirmed },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if ((use.to:contains(player)) or (use.from:objectName() == player:objectName())) and not use.card:isKindOf("SkillCard") then
			local x = 0
			local same_faction = true
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getKingdom() == player:getKingdom() then
					x = x + 1
					if p:getHandcardNum() > player:getHandcardNum() then
						same_faction = false
						break
					end
				end
			end
			if same_faction and x > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				local targets = sgs.SPlayerList()
				local no_respond_list = use.no_respond_list
				for _, p in sgs.qlist(use.to) do
					targets:append(p)
					table.insert(no_respond_list, p:objectName())
				end
				use.no_respond_list = no_respond_list
				data:setValue(use)
				if not targets:isEmpty() then
					local log = sgs.LogMessage()
					log.type = "$NoRespond"
					log.from = use.from
					log.to = targets
					log.arg = self:objectName()
					log.card_str = use.card:toString()
					room:sendLog(log)
				end
			end
			return false
		end
	end
}

heg_nos_pengyang:addSkill(heg_nos_daming)
heg_nos_pengyang:addSkill(heg_nos_xiaoni)

heg_zhuling = sgs.General(extension_heglordex,  "heg_zhuling", "wei", 4)

heg_juejue_record = sgs.CreateTriggerSkill{
	name = "#heg_juejue_record",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and player:getPhase() == sgs.Player_Discard and move.to_place == sgs.Player_DiscardPile and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD and player:getMark("heg_juejue-"..player:getPhase().."Clear") > 0 then
			room:addPlayerMark(player, "heg_juejue-Clear", move.card_ids:length())
		end
	end
}

heg_juejue = sgs.CreateTriggerSkill{
	name = "heg_juejue",
	events = { sgs.EventPhaseStart, sgs.EventPhaseEnd },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Discard then
				if room:askForSkillInvoke(player, self:objectName()) then
					room:broadcastSkillInvoke(self:objectName())
					room:loseHp(player, 1, true, player, self:objectName())
					room:addPlayerMark(player, "heg_juejue-"..player:getPhase().."Clear")
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Discard and player:getMark("heg_juejue-"..player:getPhase().."Clear") > 0 then
				local x = player:getMark("heg_juejue-Clear")
				if x > 0 then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						local card = room:askForExchange(p, self:objectName(), x, x, false, "@heg_juejue:"..x, true, "")
						if card then
							local log = sgs.LogMessage()
							log.type = "$EnterDiscardPile"
							log.card_str = card:toString()
							room:sendLog(log)
							room:moveCardTo(card, nil, sgs.Player_DiscardPile)
						else
							room:broadcastSkillInvoke(self:objectName())
							local damage = sgs.DamageStruct()
							damage.from = player
							damage.to = p
							damage.damage = 1
							damage.reason = self:objectName()
							room:damage(damage)
						end
						
					end
				end
			end
		end
		return false
	end,
}
heg_fangyuan_cardmax = sgs.CreateMaxCardsSkill{
    name = "#heg_fangyuan_cardmax",
    extra_func = function(self, target)
        for _, p in sgs.qlist(GetEncirclersClient(target)) do
			if p:hasSkill("heg_fangyuan") then
            	return -1
			end
        end
		local invoke = false
		local hasSkill = false
		for _, p in sgs.qlist(target:getAliveSiblings()) do
			for _, q in sgs.qlist(GetEncirclersClient(p)) do
				if q:objectName() == target:objectName() then
					invoke = true
				end
				if q:hasSkill("heg_fangyuan") then
					hasSkill = true
				end
			end
			if invoke and hasSkill then break end
			invoke = false
			hasSkill = false
		end
		if invoke and hasSkill then
			return 1
		end
		return 0
    end
}

heg_fangyuan = sgs.CreateTriggerSkill{
	name = "heg_fangyuan",
	events = { sgs.EventPhaseProceeding },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and IsEncircled(player) then
			local targets = sgs.SPlayerList()
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			slash:deleteLater()
			for _, p in sgs.qlist(GetEncirclers(player)) do
				if CanToCard(slash, player, p) and player:canSlash(p,slash,false) then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "heg_fangyuan-invoke", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					local use = sgs.CardUseStruct()
					use.card = slash
					use.from = player
					use.to:append(target)
					room:useCard(use)
				end
			end
		end
	end
}
heg_zhuling:addSkill(heg_juejue_record)
heg_zhuling:addSkill(heg_juejue)
extension_heglordex:insertRelatedSkills("heg_juejue", "#heg_juejue_record")
heg_zhuling:addSkill(heg_fangyuan_cardmax)
heg_zhuling:addSkill(heg_fangyuan)
extension_heglordex:insertRelatedSkills("heg_fangyuan", "#heg_fangyuan_cardmax")

heg_liuba = sgs.General(extension_heglordex,  "heg_liuba", "shu", 3)

heg_tongdu_record = sgs.CreateTriggerSkill{
	name = "#heg_tongdu_record",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and player:getPhase() == sgs.Player_Discard and move.to_place == sgs.Player_DiscardPile and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD then
			room:addPlayerMark(player, "heg_tongdu-Clear", move.card_ids:length())
		end
	end
}
heg_tongdu = sgs.CreateTriggerSkill{
	name = "heg_tongdu",
	events = { sgs.EventPhaseProceeding },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			local x = math.min(3, player:getMark("heg_tongdu-Clear"))
			if x > 0 then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if room:askForSkillInvoke(p, self:objectName(), ToData(player)) then
						room:doAnimate(1, p:objectName(), player:objectName())
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(x, self:objectName())
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

heg_qingyinCard = sgs.CreateSkillCard{
	name = "heg_qingyin",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return to_select:isWounded()
	end,
	on_use = function(self, room, source, targets)
		local log = sgs.LogMessage()
		local recover = sgs.RecoverStruct()
		recover.reason = self:objectName()
		recover.who = source
		for _, target in ipairs(targets) do
			recover.recover = target:getMaxHp() - target:getHp()
			room:recover(target, recover)
		end
		if source:getGeneralName() == "heg_liuba" then
			log.type = "#YHXiandao1"
			log.arg = source:getGeneralName()
			log.from = source
			room:sendLog(log)
			if source:getGeneral2() then
				local name = source:getGeneral2Name()
				room:changeHero(source, "", false, false, true, false)
				room:changeHero(source, name, false, false, false, false)
			else
				local maxhp = source:getMaxHp()
				local hp = source:getHp()
				local kingdom = source:getKingdom()
				room:changeHero(source, "heg_sujiang", false, false, false, false)
				room:setPlayerProperty(source, "maxhp", sgs.QVariant(maxhp))
				room:setPlayerProperty(source, "hp", sgs.QVariant(hp))
				room:setPlayerProperty(source, "kingdom", sgs.QVariant(kingdom))
			end
		elseif source:getGeneral2Name() == "heg_liuba" then
			log.type = "#YHXiandao2"
			log.arg = source:getGeneral2Name()
			log.from = source
			room:sendLog(log)
			room:changeHero(source, "", false, false, true, false)
		else
			room:handleAcquireDetachSkills(source, "-heg_tongdu")
			room:handleAcquireDetachSkills(source, "-heg_qingyin")
		end
	end
}

heg_qingyinVS = sgs.CreateViewAsSkill{
	name = "heg_qingyin",
	n = 0,
	view_as = function(self, cards)
		local card = heg_qingyinCard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("heg_qingyin")
	end
}
heg_qingyin = sgs.CreateTriggerSkill{
	name = "heg_qingyin",
	view_as_skill = heg_qingyinVS,
	limit_mark = "@heg_qingyin",
	frequency = sgs.Skill_Limited,
}
heg_liuba:addSkill(heg_tongdu_record)
heg_liuba:addSkill(heg_tongdu)
extension_heglordex:insertRelatedSkills("heg_tongdu", "#heg_tongdu_record")
heg_liuba:addSkill(heg_qingyin)

heg_zhugeke = sgs.General(extension_heglordex,  "heg_zhugeke", "wu", 3)

heg_duwuCard = sgs.CreateSkillCard{
	name = "heg_duwu",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return sgs.Self:inMyAttackRange(to_select)
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@heg_duwu")
		local command = startCommand(source, self:objectName())
		local invoke = false
		for _, target in ipairs(targets) do
			room:setPlayerFlag(target, "heg_duwu_target")
			local invoke = doCommand(target, self:objectName(), command, source)
			if not invoke then
				local damage = sgs.DamageStruct()
				damage.reason = self:objectName()
				damage.from = source
				damage.to = target
				damage.damage = 1
				room:damage(damage)
				source:drawCards(1, self:objectName())
			end
			room:setPlayerFlag(target, "-heg_duwu_target")
			if target:hasFlag("heg_duwu") then
				room:setPlayerFlag(target, "-heg_duwu")
				invoke = true
			end
		end
		if invoke then
			room:loseHp(source, 1, true, source, self:objectName())
		end
	end
}

heg_duwuVS = sgs.CreateViewAsSkill{
	name = "heg_duwu",
	n = 0,
	view_as = function(self, cards)
		local card = heg_duwuCard:clone()
		return card
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@heg_duwu") > 0
	end
}
heg_duwu = sgs.CreateTriggerSkill{
	name = "heg_duwu",
	view_as_skill = heg_duwuVS,
	frequency = sgs.Skill_Limited,
	limit_mark = "@heg_duwu",
	events = { sgs.QuitDying },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who and dying.who:isAlive() and dying.damage and dying.damage.from then
			room:setPlayerFlag(player, "heg_duwu")
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasFlag("heg_duwu_target")
	end
}


heg_zhugeke:addSkill("aocai")
heg_zhugeke:addSkill(heg_duwu)


heg_huangzu = sgs.General(extension_heglordex,  "heg_huangzu", "qun", 4)

heg_xishe = sgs.CreateTriggerSkill{
	name = "heg_xishe",
	events = { sgs.EventPhaseProceeding, sgs.Death, sgs.EventPhaseChanging, sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseProceeding then
			if player:getPhase() == sgs.Player_Start then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName(self:objectName())
					slash:deleteLater()
					if p:objectName() ~= player:objectName() and p:canSlash(player, slash, false) and p:getEquips():length() > 0 and p:canDiscard(p, "e") then
						while true do
							if p:canSlash(player, slash, false) and p:getEquips():length() > 0 and p:canDiscard(p, "e") then
								local card = room:askForCard(p, ".|.|.|equipped", "@heg_xishe:"..player:objectName(), ToData(player), sgs.Card_MethodDiscard, nil, false, self:objectName()) 
								if not card then break end
								local use = sgs.CardUseStruct()
								use.card = slash
								use.from = p
								use.to:append(player)
								room:useCard(use)
							else
								break
							end
							if player:isDead() then break end
						end
					end
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and table.contains(use.card:getSkillNames(), self:objectName()) and player:objectName() == use.from:objectName() and player:hasSkill(self:objectName()) then
				local no_respond_list = use.no_respond_list
                local targets = sgs.SPlayerList()
                for _, p in sgs.qlist(use.to) do
                    if p:getHp() < player:getHp() then
                        table.insert(no_respond_list, p:objectName())
                        targets:append(p)
                    end
                end
                if not targets:isEmpty() then
                    local log = sgs.LogMessage()
                    log.type = "$NoRespond"
                    log.from = use.from
                    log.to = targets
                    log.arg = self:objectName()
                    log.card_str = use.card:toString()
                    room:sendLog(log)
                    use.no_respond_list = no_respond_list
                    data:setValue(use)
                end
			end
		elseif event == sgs.Death then
			local death = data:toDeath()
			if death.who and death.damage and death.damage.card and table.contains(death.damage.card:getSkillNames(), self:objectName()) then
				room:addPlayerMark(death.damage.from, "heg_xishe_kill-Clear", 1)
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:getMark("heg_xishe_kill-Clear") > 0 then
						room:broadcastSkillInvoke(self:objectName())
						if room:askForSkillInvoke(p, self:objectName()) then
							local generals = {}
							for _,name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
								if not sgs.Sanguosha:isGeneralHidden(name) and not table.contains(generals, name) and sgs.Sanguosha:getGeneral(name):getKingdom() == p:getKingdom() then
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
							local new_general = generals[math.random(1, #generals)]
							if p:getGeneral2Name() == "heg_huangzu" then
								room:setPlayerProperty(p, "yinni_general2", sgs.QVariant(new_general))
								room:changeHero(p, "yinni_hide", false, false, true)
							elseif p:getGeneralName() == "heg_huangzu" then
								room:setPlayerProperty(p, "yinni_general", sgs.QVariant(new_general))
								room:changeHero(p, "yinni_hide", false, false, false)
							else
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

heg_huangzu:addSkill(heg_xishe)

heg_simazhao = sgs.General(extension_heglordex,  "heg_simazhao", "wei", 3)

heg_suzhi_buff = sgs.CreateTargetModSkill{
	name = "#heg_suzhi_buff",
	pattern = "TrickCard",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("heg_suzhi") and not card:isVirtualCard() and from:getMark("heg_suzhi-Clear") < 3 then
			return 1000
		end
		return 0
	end
}

heg_suzhi = sgs.CreateTriggerSkill{
	name = "heg_suzhi",
	events = { sgs.ConfirmDamage, sgs.CardUsed, sgs.CardsMoveOneTime, sgs.EventPhaseChanging },
	waked_skills = "fankui",
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				if player:getMark("heg_suzhi-Clear") >= 3 then
					return false
				end
				room:acquireNextTurnSkills(player, "heg_suzhi", "fankui")
			end
		end
		if player:getMark("heg_suzhi-Clear") >= 3 then
			return false
		end
		if player:getPhase() == sgs.Player_NotActive then
			return false
		end
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.from:objectName() == player:objectName() then
				if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) and damage.by_user then
					damage.damage = damage.damage + 1
					local log = sgs.LogMessage()
					log.type = "#skill_add_damage"
					log.from = damage.from
					log.to:append(damage.to)
					log.arg  = self:objectName()
					log.arg2 = damage.damage
					room:sendLog(log)
					data:setValue(damage)
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player, "heg_suzhi-Clear", 1)
					room:addPlayerMark(player, "&heg_suzhi-Clear", 1)
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.from:objectName() == player:objectName() then
				if use.card and use.card:isKindOf("TrickCard") then
					room:broadcastSkillInvoke(self:objectName())
					player:drawCards(1, self:objectName())
					room:addPlayerMark(player, "heg_suzhi-Clear", 1)
					room:addPlayerMark(player, "&heg_suzhi-Clear", 1)
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() ~= player:objectName() and move.to_place == sgs.Player_DiscardPile and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD and move.reason.m_playerId then
				local from = room:findPlayerByObjectName(move.from:objectName())
				if from and not from:isNude() then
					room:broadcastSkillInvoke(self:objectName())
					local id = room:askForCardChosen(player, from, "he", self:objectName(), false, sgs.Card_MethodNone)
					local card = sgs.Sanguosha:getCard(id)
					player:obtainCard(card, false)
					room:addPlayerMark(player, "heg_suzhi-Clear", 1)
					room:addPlayerMark(player, "&heg_suzhi-Clear", 1)
				end
			end
		end
		return false
	end,
}


heg_zhaoxin = sgs.CreateTriggerSkill{
	name = "heg_zhaoxin",
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if not player:isKongcheng() then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHandcardNum() <= player:getHandcardNum() and not p:isKongcheng() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "heg_zhaoxin-invoke", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					room:showAllCards(player)
					room:doAnimate(1, player:objectName(), target:objectName())
					local player_handcards = sgs.IntList()
					local exchangeMove = sgs.CardsMoveList()
					exchangeMove:append(sgs.CardsMoveStruct(player:handCards(), target, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), target:objectName(), self:objectName(), "")))
					exchangeMove:append(sgs.CardsMoveStruct(target:handCards(), player, sgs.Player_PlaceHand, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, target:objectName(), player:objectName(), self:objectName(), "")))
					room:moveCardsAtomic(exchangeMove, false)
				end
			end
		end
		return false
	end,
}

heg_simazhao:addSkill(heg_suzhi_buff)
heg_simazhao:addSkill(heg_suzhi)
heg_simazhao:addSkill(heg_zhaoxin)

heg_zhonghui = sgs.General(extension_heglordex,  "heg_zhonghui", "wei", 4)

heg_quanji_buff = sgs.CreateMaxCardsSkill{
	name = "#heg_quanji_buff",
	extra_func = function(self, target)
		return target:getPile("heg_quanji_power"):length()
	end
}

heg_quanji = sgs.CreateTriggerSkill{
	name = "heg_quanji",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damaged, sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local can_invoke = false
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() and player:getMark("heg_quanji-Inflicted-Clear") == 0 then
				can_invoke = true
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName() and player:getMark("heg_quanji-Caused-Clear") == 0 then
				can_invoke = true
			end
		end
		if can_invoke and room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			player:drawCards(1, self:objectName())
			if not player:isKongcheng() then
				local cards = room:askForExchange(player, self:objectName(), 1, 1, false, "QuanjiPush")
				local card_ids = cards:getSubcards()
				player:addToPile("heg_quanji_power", card_ids)
			end
			if event == sgs.Damaged then
				room:addPlayerMark(player, "heg_quanji-Inflicted-Clear", 1)
			elseif event == sgs.Damage then
				room:addPlayerMark(player, "heg_quanji-Caused-Clear", 1)
			end
		end
		return false
	end,
}

heg_paiyiCard = sgs.CreateSkillCard{
	name = "heg_paiyi",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
		room:throwCard(self, reason, nil)
		local target = targets[1]
		local x = source:getPile("heg_quanji_power"):length()
		if x > 7 then
			x = 7
		end
		target:drawCards(x, "heg_paiyi")
		if target:getHandcardNum() > source:getHandcardNum() then
			local damage = sgs.DamageStruct()
			damage.reason = "heg_paiyi"
			damage.from = source
			damage.to = target
			damage.damage = 1
			room:damage(damage)
		end
	end
}
heg_paiyi = sgs.CreateOneCardViewAsSkill{
	name = "heg_paiyi",
	expand_pile = "heg_quanji_power",
	filter_pattern = ".|.|.|heg_quanji_power",
	view_as = function(self, card)
		local skill_card = heg_paiyiCard:clone()
		skill_card:addSubcard(card)
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_paiyi") and player:getPile("heg_quanji_power"):length() > 0
	end
}

heg_zhonghui:addSkill(heg_quanji_buff)
heg_zhonghui:addSkill(heg_quanji)
extension_heglordex:insertRelatedSkills("heg_quanji", "#heg_quanji_buff")
heg_zhonghui:addSkill(heg_paiyi)

heg_nos_zhonghui = sgs.General(extension_heglordex,  "heg_nos_zhonghui", "wei", 4)

heg_nos_quanji = sgs.CreateTriggerSkill{
	name = "heg_nos_quanji",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Damaged, sgs.Damage },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local can_invoke = false
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() then
				can_invoke = true
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() == player:objectName() and damage.card and not damage.card:isKindOf("SkillCard") and damage.by_user then
				local use = room:getTag("UseHistory"..damage.card:toString()):toCardUse()
				if use.to:length() == 1 and use.to:contains(damage.to) then
					can_invoke = true
				end
			end
		end
		if can_invoke and room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			player:drawCards(1, self:objectName())
			if not player:isKongcheng() then
				local cards = room:askForExchange(player, self:objectName(), 1, 1, false, "QuanjiPush")
				local card_ids = cards:getSubcards()
				player:addToPile("heg_quanji_power", card_ids)
			end
		end
		return false
	end,
}
heg_nos_zhonghui:addSkill(heg_nos_quanji)
heg_nos_zhonghui:addSkill("#heg_quanji_buff")
extension_heglordex:insertRelatedSkills("heg_nos_quanji", "#heg_quanji_buff")
heg_nos_zhonghui:addSkill("heg_paiyi")

heg_sunchen = sgs.General(extension_heglordex,  "heg_sunchen", "wu", 4)

heg_shilus = sgs.CreateTriggerSkill{
	name = "heg_shilus",
	frequency = sgs.Skill_Frequent,
	events = { sgs.Death, sgs.EventPhaseProceeding },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Death then
			local death = data:toDeath()
			if death.who then
				if room:askForSkillInvoke(player, self:objectName()) then
					local general = death.who:getGeneralName()
					local general_list = player:property("heg_shilus_generals"):toString():split("+")
					if not table.contains(general_list, general) then
						table.insert(general_list, general)
						room:setPlayerProperty(player, "heg_shilus_generals", sgs.QVariant(table.concat(general_list, "+")))
					end
					if death.who:getGeneral2() then
						if not table.contains(general_list,  death.who:getGeneral2Name()) then
							table.insert(general_list, death.who:getGeneral2Name())
							room:setPlayerProperty(player, "heg_shilus_generals", sgs.QVariant(table.concat(general_list, "+")))
						end
					end
					room:setPlayerMark(player, "&heg_shilus", #general_list)
					room:doAnimate(4, player:objectName(), general)
					if death.damage and death.damage.from and death.damage.from:objectName() == player:objectName() then
						local all_generals = sgs.Sanguosha:getLimitedGeneralNames()
						for _, p in sgs.qlist(room:getAllPlayers(true)) do
							if table.contains(all_generals, p:getGeneralName()) then
								table.removeOne(all_generals, p:getGeneralName())
							end
						end
						local new_general = all_generals[math.random(1, #all_generals)]
						table.removeOne(all_generals, new_general)
						if not table.contains(general_list, new_general) then
							table.insert(general_list, new_general)
							room:setPlayerProperty(player, "heg_shilus_generals", sgs.QVariant(table.concat(general_list, "+")))
						end
						local new_general2 = all_generals[math.random(1, #all_generals)]
						if not table.contains(general_list, new_general2) then
							table.insert(general_list, new_general2)
							room:setPlayerProperty(player, "heg_shilus_generals", sgs.QVariant(table.concat(general_list, "+")))
						end
						room:setPlayerMark(player, "&heg_shilus", #general_list)
						room:doAnimate(4, player:objectName(), general)
						room:doAnimate(4, player:objectName(), general2)
					end
					player:setSkillDescriptionSwap("heg_shilus", "%arg1", table.concat(general_list, "+|+"))
					room:changeTranslation(player, "heg_shilus", 1)
				end
			end
		elseif event == sgs.EventPhaseProceeding then
			if player:getPhase() == sgs.Player_Start then
				if player:getMark("&heg_shilus") > 0 and room:askForSkillInvoke(player, self:objectName())  then
					local card = room:askForDiscard(player, self:objectName(), player:getMark("&heg_shilus"), 0, true, true, "@heg_shilus:"..player:getMark("&heg_shilus"), "", self:objectName())
					if card then
						local x = card:subcardsLength()
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(x, self:objectName())
					end
				end
			end
		end
		return false
	end,
}

heg_xiongnve_buff = sgs.CreateTargetModSkill{
	name = "#heg_xiongnve_buff",
	residue_func = function(self, from, card)
		if from:hasSkill("heg_xiongnve") and from:getMark("heg_xiongnve-Unlimit-Clear") > 0 and to then
			local kingdom = from:property("heg_xiongnve"):toString()
			if to:getKingdom() == kingdom then
				return 1000
			end
		end
		return 0
	end
}

heg_xiongnve = sgs.CreateTriggerSkill{
	name = "heg_xiongnve",
	events = { sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.Damaged, sgs.DamageCaused },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local general_list = player:property("heg_shilus_generals"):toString():split("+")
				if #general_list > 0 and player:canDiscard(player, "he") and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("start")) then
					local gn 
					if player:getState() == "online" then
						gn = room:askForGeneral(player, table.concat(general_list, "+"))
					else
						for _, name in ipairs(general_list) do
							if player:hasFlag("heg_xiongnve:"..name) then
								gn = name
								break
							end
						end
						if not gn then
							gn = general_list[math.random(1, #general_list)]
						end
					end
					local general = sgs.Sanguosha:getGeneral(gn)
					room:setPlayerProperty(player, "heg_xiongnve", sgs.QVariant(general:getKingdoms()))
					table.removeOne(general_list, gn)
					room:setPlayerProperty(player, "heg_shilus_generals", sgs.QVariant(table.concat(general_list, "+")))
					room:setPlayerMark(player, "&heg_shilus", #general_list)
					room:addPlayerMark(player, "&heg_xiongnve+:+"..general:getKingdom().."-Clear", 1)
					local choice = room:askForChoice(player, self:objectName(), "damage+obtain+unlimit")
					if choice == "damage" then
						room:addPlayerMark(player, "heg_xiongnve-Damage-Clear", 1)
					elseif choice == "obtain" then
						room:addPlayerMark(player, "heg_xiongnve-Obtain-Clear", 1)
					elseif choice == "unlimit" then
						room:addPlayerMark(player, "heg_xiongnve-Unlimit-Clear", 1)
					end
					room:changeTranslation(player, "heg_shilus")
					if #general_list > 0 then
						player:setSkillDescriptionSwap("heg_shilus", "%arg1", table.concat(general_list, "+|+"))
						room:changeTranslation(player, "heg_shilus", 1)
					end
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			local kingdom = player:property("heg_xiongnve"):toString()
			if string.find(kingdom, damage.to:getKingdom()) then
				if player:getMark("heg_xiongnve-Damage-Clear") > 0 then
					room:broadcastSkillInvoke(self:objectName())
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
				if not damage.to:isNude() and player:getMark("heg_xiongnve-Obtain-Clear") > 0 then
					local id = room:askForCardChosen(player, damage.to, "he", self:objectName(), false, sgs.Card_MethodNone)
					local card = sgs.Sanguosha:getCard(id)
					player:obtainCard(card, false)
				end
			end
			
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play then
				local general_list = player:property("heg_shilus_generals"):toString():split("+")
				if #general_list > 1 and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("end")) then
					local gn
					local gn2
					if player:getState() == "online" then
						gn = room:askForGeneral(player, table.concat(general_list, "+"))
						table.removeOne(general_list, gn)
						gn2 = room:askForGeneral(player, table.concat(general_list, "+"))
						table.removeOne(general_list, gn2)
					else
						gn = general_list[math.random(1, #general_list)]
						table.removeOne(general_list, gn)
						gn2 = general_list[math.random(1, #general_list)]
						table.removeOne(general_list, gn2)
					end
					room:setPlayerProperty(player, "heg_shilus_generals", sgs.QVariant(table.concat(general_list, "+")))
					room:setPlayerMark(player, "&heg_shilus", #general_list)
					room:setPlayerMark(player, "heg_xiongnve_reduce-Self"..sgs.Player_RoundStart.."Clear", 1)
					room:setPlayerMark(player, "&heg_xiongnve-Self"..sgs.Player_RoundStart.."Clear", 1)
					room:changeTranslation(player, "heg_shilus")
					if #general_list > 0 then
						player:setSkillDescriptionSwap("heg_shilus", "%arg1", table.concat(general_list, "+|+"))
						room:changeTranslation(player, "heg_shilus", 1)
					end
				end
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from and damage.from:objectName() ~= player:objectName() and player:getMark("heg_xiongnve_reduce-Self"..sgs.Player_RoundStart.."Clear") > 0 then
				player:damageRevises(data, -1)
				room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			end
		end
		return false
	end,
}

heg_sunchen:addSkill(heg_shilus)
heg_sunchen:addSkill(heg_xiongnve)
heg_sunchen:addSkill(heg_xiongnve_buff)
extension_heglordex:insertRelatedSkills("heg_xiongnve", "#heg_xiongnve_buff")

heg_gongsunyuan = sgs.General(extension_heglordex,  "heg_gongsunyuan", "qun", 4)

heg_huaiyiCard = sgs.CreateSkillCard{
	name = "heg_huaiyi",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:showAllCards(source)
		local red_cards = sgs.IntList()
		local black_cards = sgs.IntList()
		for _, c in sgs.qlist(source:getHandcards()) do
			if c:isRed() then
				red_cards:append(c:getId())
			else
				black_cards:append(c:getId())
			end
		end
		if red_cards:isEmpty() or black_cards:isEmpty() then
			return
		end
		local color = room:askForChoice(source, "heg_huaiyi", "red+black")
		local to_discard
		if color == "red" then
			to_discard = red_cards
		else
			to_discard = black_cards
		end
		room:throwCard(to_discard, self:objectName(), source, source)
		local x = to_discard:length()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if targets:length() < x and not p:isNude() then
				targets:append(p)
			else
				break
			end
		end
		local victim = room:askForPlayersChosen(source, targets, self:objectName(), 1, x, "heg_huaiyi-invoke:"..x, true, true)
		for _, p in sgs.qlist(victim) do
			local id = room:askForCardChosen(source, p, "he", self:objectName(), false, sgs.Card_MethodNone)
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("EquipCard") then
				source:addToPile("heg_zisui_yi", id)
				room:sendCompulsoryTriggerLog(source, "heg_zisui", true)
				room:broadcastSkillInvoke("heg_zisui")
			else
				source:obtainCard(card, false)
			end
		end
	end
}
heg_huaiyi = sgs.CreateViewAsSkill{
	name = "heg_huaiyi",
	n = 0,
	view_as = function(self, cards)
		local skill_card = heg_huaiyiCard:clone()
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_huaiyi") and not player:isKongcheng()
	end
}

heg_zisui = sgs.CreateTriggerSkill{
	name = "heg_zisui",
	events = { sgs.DrawNCards, sgs.EventPhaseProceeding },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
        	if draw.reason ~= "draw_phase" then return false end
			local x = player:getPile("heg_zisui_yi"):length()
			if x > 0 then
				room:broadcastSkillInvoke(self:objectName())
				draw.num = draw.num + x
				data:setValue(draw)
			end
		elseif event == sgs.EventPhaseProceeding then
			if player:getPhase() == sgs.Player_Finish then
				local x = player:getPile("heg_zisui_yi"):length()
				if x > player:getMaxHp() then
					room:killPlayer(player)
				end
			end
		end
		return false
	end,
}

heg_gongsunyuan:addSkill(heg_huaiyi)
heg_gongsunyuan:addSkill(heg_zisui)

heg_nos_gongsunyuan = sgs.General(extension_heglordex,  "heg_nos_gongsunyuan", "qun", 4)


heg_nos_huaiyiCard = sgs.CreateSkillCard{
	name = "heg_nos_huaiyi",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:showAllCards(source)
		local red_cards = sgs.IntList()
		local black_cards = sgs.IntList()
		for _, c in sgs.qlist(source:getHandcards()) do
			if c:isRed() then
				red_cards:append(c:getId())
			else
				black_cards:append(c:getId())
			end
		end
		if red_cards:isEmpty() or black_cards:isEmpty() then
			return
		end
		local color = room:askForChoice(source, "heg_nos_huaiyi", "red+black")
		local to_discard = sgs.IntList()
		if color == "red" then
			to_discard = red_cards
		else
			to_discard = black_cards
		end
		room:throwCard(to_discard, self:objectName(), source, source)
		local x = to_discard:length()
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(room:getOtherPlayers(source)) do
			if targets:length() < x and not p:isNude() then
				targets:append(p)
			else
				break
			end
		end
		local victim = room:askForPlayersChosen(source, targets, self:objectName(), 1, x, "heg_huaiyi-invoke:"..x, true, true)
		for _, p in sgs.qlist(victim) do
			local id = room:askForCardChosen(source, p, "he", self:objectName(), false, sgs.Card_MethodNone)
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("EquipCard") then
				source:addToPile("&heg_nos_zisui_yi", id)
				room:sendCompulsoryTriggerLog(source, "heg_nos_zisui", true)
				room:broadcastSkillInvoke("heg_nos_zisui")
			else
				source:obtainCard(card, false)
			end
		end
	end
}
heg_nos_huaiyi = sgs.CreateViewAsSkill{
	name = "heg_nos_huaiyi",
	n = 0,
	view_as = function(self, cards)
		local skill_card = heg_nos_huaiyiCard:clone()
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_nos_huaiyi") and not player:isKongcheng()
	end
}


heg_nos_zisui = sgs.CreateTriggerSkill{
	name = "heg_nos_zisui",
	events = { sgs.DrawNCards, sgs.EventPhaseProceeding },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
        	if draw.reason ~= "draw_phase" then return false end
			local x = player:getPile("&heg_nos_zisui_yi"):length()
			if x > 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName(), true)
				room:broadcastSkillInvoke(self:objectName())
				draw.num = draw.num + x
				data:setValue(draw)
			end
		elseif event == sgs.EventPhaseProceeding then
			if player:getPhase() == sgs.Player_Finish then
				local x = player:getPile("&heg_nos_zisui_yi"):length()
				if x > player:getMaxHp() then
					room:killPlayer(player)
				end
			end
		end
		return false
	end,
}

heg_nos_gongsunyuan:addSkill(heg_nos_huaiyi)
heg_nos_gongsunyuan:addSkill(heg_nos_zisui)

heg_zhangchunhua = sgs.General(extension_hegpurplecloud,  "heg_zhangchunhua", "jin", 3, false)

heg_ejue = sgs.CreateTriggerSkill{
	name = "heg_ejue",
	events = { sgs.DamageCaused },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
			if damage.to:getKingdom() ~= player:getKingdom() then
				room:broadcastSkillInvoke(self:objectName())
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
	end,
}

heg_shangshi = sgs.CreateTriggerSkill{
	name = "heg_shangshi",
	events = { sgs.EventPhaseChanging },
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getLostHp() > 0 and p:getHandcardNum() < p:getLostHp() then
					if room:askForSkillInvoke(p, self:objectName()) then
						room:broadcastSkillInvoke(self:objectName())
						p:drawCards(p:getLostHp() - p:getHandcardNum(), self:objectName())
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

heg_zhangchunhua:addSkill(heg_ejue)
heg_zhangchunhua:addSkill(heg_shangshi)

heg_simashi = sgs.General(extension_hegpurplecloud,  "heg_simashi", "jin", 4)

heg_yimie_prohibit = sgs.CreateProhibitSkill{
	name = "#heg_yimie_prohibit",
	is_prohibited = function(self, from, to, card)
		if card and card:isKindOf("Peach") then
			if to and to:hasFlag("Global_Dying") then
				local current
				for _,p in sgs.qlist(from:getAliveSiblings(true)) do 
					if p:hasFlag("CurrentPlayer") then
						current = p
						break
					end
				end
				if current and current:hasSkill("heg_yimie") then
					return from:getKingdom() == to:getKingdom()
				end		
			end
		end
		return false
	end
}


heg_yimie_attach = sgs.CreateViewAsSkill {
    name = "heg_yimie_attach&",
    n = 1,
    view_filter = function(self, selected, to_select)
        return to_select:getSuit() == sgs.Card_Heart
    end,
    view_as = function(self, cards)
        if #cards ~= 1 then return nil end
        local card = sgs.Sanguosha:cloneCard("peach", cards[1]:getSuit(), cards[1]:getNumber())
		card:setSkillName("heg_yimie")
        card:addSubcard(cards[1])
        return card
    end,
    enabled_at_play = function(self, player)
        return false
    end,
	enabled_at_response = function(self, player, pattern)
		for _, p in sgs.list(player:getAliveSiblings()) do
			if p:hasFlag("Global_Dying") then
				local current
				for _,pp in sgs.qlist(player:getAliveSiblings(true)) do 
					if pp:hasFlag("CurrentPlayer") then
						current = pp
						break
					end
				end
				if current:hasSkill("heg_yimie") then
					if player:getKingdom() == p:getKingdom() then
						return false
					end
					for _, p in sgs.list(pattern:split("+")) do
						local c = dummyCard(p)
						if c and c:isKindOf("Peach")
						then return true end
					end
				end		
			end
		end
	end,
}
heg_yimie = sgs.CreateTriggerSkill{
	name = "heg_yimie",
	events = { sgs.EventAcquireSkill, sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventAcquireSkill and data:toString() == "heg_yimie" or event == sgs.GameStart then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				room:attachSkillToPlayer(p, "heg_yimie_attach")
			end
		end
		return false
	end,
}


heg_ruilveCard = sgs.CreateSkillCard{
	name = "heg_ruilve",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasSkill("heg_ruilve") and to_select:getMark("heg_ruilve-PlayClear") == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:showCard(target, self:getSubcards():first())
		room:obtainCard(target, self:getSubcards():first(), true)
		source:drawCards(1, "heg_ruilve")
		room:addPlayerMark(target, "heg_ruilve-PlayClear", 1)
	end
}

heg_ruilve_attach = sgs.CreateViewAsSkill {
    name = "heg_ruilve_attach&",
    n = 1,
	view_filter = function(self, selected, to_select)
		return (to_select:isDamageCard() and to_select:isKindOf("TrickCard")) or to_select:isKindOf("Slash")
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = heg_ruilveCard:clone()
		card:addSubcard(cards[1])
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end,
}
heg_ruilve = sgs.CreateTriggerSkill{
	name = "heg_ruilve",
	events = { sgs.EventAcquireSkill, sgs.GameStart },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventAcquireSkill and data:toString() == "heg_ruilve" or event == sgs.GameStart then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				room:attachSkillToPlayer(p, "heg_ruilve_attach")
			end
		end
		return false
	end,
}

heg_simashi:addSkill(heg_yimie_prohibit)
heg_simashi:addSkill(heg_yimie)
extension_hegpurplecloud:insertRelatedSkills("heg_yimie", "heg_yimie_prohibit")
heg_simashi:addSkill(heg_ruilve)
if not sgs.Sanguosha:getSkill("heg_yimie_attach&") then skills:append(heg_yimie_attach) end
if not sgs.Sanguosha:getSkill("heg_ruilve_attach&") then skills:append(heg_ruilve_attach) end

heg_jin_simazhao = sgs.General(extension_hegpurplecloud,  "heg_jin_simazhao", "jin", 4)

heg_zhaoran = sgs.CreateTriggerSkill{
	name = "heg_zhaoran",
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Play then
			room:broadcastSkillInvoke(self:objectName())
			local x = 4 - getKingdoms(player)
			if x > 0 then
				player:drawCards(x, self:objectName())
			end
		end
		return false
	end,
}

heg_beiluan = sgs.CreateTriggerSkill{
	name = "heg_beiluan",
	events = { sgs.Damaged, sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			for _,p in sgs.qlist(room:getAlivePlayers())do
				local hw = sgs.CardList()
				for _,c in sgs.qlist(p:getHandcards())do
					if c:getSkillName()==self:objectName() then
						hw:append(c)
					end
				end
				room:filterCards(p,hw,true)
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and not damage.from:isKongcheng() and room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				for _,h in sgs.qlist(damage.from:getHandcards())do
					if not h:isKindOf("EquipCard") then
						local toc = sgs.Sanguosha:cloneCard("slash",h:getSuit(),h:getNumber())
						toc:setSkillName("heg_beiluan")
						local wrap = sgs.Sanguosha:getWrappedCard(h:getEffectiveId())
						wrap:takeOver(toc)
						room:notifyUpdateCard(player,h:getEffectiveId(),wrap)
					end
				end
			end
		end
		return false
	end,
}

heg_jin_simazhao:addSkill(heg_zhaoran)
heg_jin_simazhao:addSkill(heg_beiluan)

heg_simazhou = sgs.General(extension_hegpurplecloud,  "heg_simazhou", "jin", 4)

heg_pojingCard = sgs.CreateSkillCard{
	name = "heg_pojing",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local choicelist = { "damage"}
		if not target:isAllNude() then
			table.insert(choicelist, "obtain")
		end
		local choice = room:askForChoice(target, "heg_pojing", table.concat(choicelist, "+"), ToData(target))
		if choice == "obtain" then
			room:broadcastSkillInvoke("heg_pojing", 1)
			local id = room:askForCardChosen(source, target, "hej", "heg_pojing", false, sgs.Card_MethodNone)
			local card = sgs.Sanguosha:getCard(id)
			source:obtainCard(card, false)
		else
			local others = room:getOtherPlayers(target)
			others:removeOne(source)
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.to = target
			damage.damage = 1
			for _, other in sgs.qlist(others) do
				if room:askForSkillInvoke(other, "heg_pojing", ToData(target)) then
					damage.damage = damage.damage + 1
				end
			end
			room:broadcastSkillInvoke("heg_pojing", 2)
			room:damage(damage)
		end
	end
}
heg_pojing = sgs.CreateViewAsSkill{
	name = "heg_pojing",
	n = 0,
	view_as = function(self, cards)
		local skill_card = heg_pojingCard:clone()
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("heg_pojing")
	end
}
heg_simazhou:addSkill(heg_pojing)

heg_simaliang = sgs.General(extension_hegpurplecloud,  "heg_simaliang", "jin", 4)

heg_gongzhi = sgs.CreateTriggerSkill{
	name = "heg_gongzhi",
	events = { sgs.EventPhaseChanging },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Draw then
			if room:askForSkillInvoke(player, self:objectName()) then
				room:broadcastSkillInvoke(self:objectName())
				local targets = room:askForPlayersChosen(player, room:getAlivePlayers(), self:objectName(), 0, 4, "@heg_gongzhi", true, true)
				local x = 0
				for _, p in sgs.qlist(targets) do
					p:drawCards(1, self:objectName())
					x = x + 1
					if x >= 4 then
						break
					end
				end
				player:skip(sgs.Player_Draw)
			end
		end
		return false
	end,
}

heg_shejus = sgs.CreateTriggerSkill{
	name = "heg_shejus",
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to and damage.to:canDiscard(damage.to, "h") then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if damage.to:getMark("heg_shejus"..p:objectName()) == 0 and p:isWounded() then
					if room:askForSkillInvoke(damage.to, self:objectName(), ToData(p)) then
						room:broadcastSkillInvoke(self:objectName())
						room:recover(p, sgs.RecoverStruct(damage.to, nil, 1, self:objectName()))
						damage.to:throwAllHandCards(self:objectName())
						room:addPlayerMark(damage.to, "heg_shejus"..p:objectName(), 1)
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

heg_simaliang:addSkill(heg_gongzhi)
heg_simaliang:addSkill(heg_shejus)

heg_simalun = sgs.General(extension_hegpurplecloud,  "heg_simalun", "jin", 4)

heg_zhulan = sgs.CreateTriggerSkill{
	name = "heg_zhulan",
	events = { sgs.DamageInflicted },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and damage.from:getKingdom() == player:getKingdom() then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:canDiscard(p, "he") then
					if room:askForCard(p, ".",  "@heg_zhulan", data, sgs.Card_MethodDiscard, nil, false, self:objectName(),	false, nil) then
						room:broadcastSkillInvoke(self:objectName())
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
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

heg_luanchang_record = sgs.CreateTriggerSkill{
	name = "#heg_luanchang_record",
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "heg_luanchang-Clear", 1)
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

heg_luanchang = sgs.CreateTriggerSkill{
	name = "heg_luanchang",
	events = { sgs.EventPhaseProceeding },
	frequency = sgs.Skill_Limited,
	limit_mark = "@heg_luanchang",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive and not player:isKongcheng() then
			local invoke = false
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("heg_luanchang-Clear") > 0 then
					invoke = true
					break
				end
			end
			if invoke then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:getMark("@heg_luanchang")
						> 0 and room:askForSkillInvoke(p, self:objectName(), data) then
						local current = room:getCurrent()
						local card = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)
						card:setSkillName(self:objectName())
						card:addSubcards(current:getHandcards())
						local use = sgs.CardUseStruct()
						use.card = card
						use.from = current
						room:useCard(use)
						room:removePlayerMark(p, "@heg_luanchang", 1)
						break
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

heg_simalun:addSkill(heg_zhulan)
heg_simalun:addSkill(heg_luanchang_record)
heg_simalun:addSkill(heg_luanchang)
extension_hegpurplecloud:insertRelatedSkills("heg_luanchang", "#heg_luanchang_record")

heg_shibao = sgs.General(extension_hegpurplecloud,  "heg_shibao", "jin", 4)

heg_zhuosheng = sgs.CreateTriggerSkill {
    name = "heg_zhuosheng",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardsMoveOneTime, sgs.DamageCaused, sgs.PreCardUsed },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if not room:getTag("FirstRound"):toBool() and player:getPhase() ~= sgs.Player_NotActive and move.to and move.to:objectName() == player:objectName() then
                local ids = sgs.IntList()
                for _, id in sgs.qlist(move.card_ids) do
                    if room:getCardOwner(id) == player and room:getCardPlace(id) == sgs.Player_PlaceHand then
                        ids:append(id)
                    end
                end
                if ids:isEmpty() then return false end
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:setPlayerMark(player, "&heg_zhuosheng", 1)
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag(self:objectName()) then
                damage.damage = damage.damage + 1
                data:setValue(damage)
                local log = sgs.LogMessage()
                log.type = "#skill_add_damage"
                log.from = damage.from
                log.to:append(damage.to)
                log.arg  = self:objectName()
                log.arg2 = damage.damage
                room:sendLog(log)
            end
		 elseif event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card:isKindOf("SkillCard") then return false end
            if player:getMark("&heg_zhuosheng") > 0 then
                room:setCardFlag(use.card, self:objectName())
			end
        end
        return false
    end
}

heg_shibao:addSkill(heg_zhuosheng)

heg_yanghuiyu = sgs.General(extension_hegpurplecloud,  "heg_yanghuiyu", "jin", 3, false)


heg_ciwei_record = sgs.CreateTriggerSkill{
	name = "#heg_ciwei_record",
	events = { sgs.CardUsed, sgs.CardResponded },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			local resp = data:toCardResponse()
			card = resp.m_card
		end
		if card then
			local current = room:getCurrent()
			if current and current:hasSkill("heg_ciwei") then
				if player:objectName() ~= current:objectName() then
					room:setPlayerMark(player, "heg_ciwei-Clear", 1)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

heg_ciwei = sgs.CreateTriggerSkill{
	name = "heg_ciwei",
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local current = room:getCurrent()
		if current and current:hasSkill(self:objectName()) and player:objectName() ~= current:objectName() then
			local invoke = false
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("heg_ciwei-Clear") > 0 then
					invoke = true
					break
				end
			end
			if invoke and current:canDiscard(current, "he") then
				if room:askForCard(current, ".", "@heg_ciwei", data, sgs.Card_MethodDiscard, nil, false, self:objectName(),	false, nil) then
					room:broadcastSkillInvoke(self:objectName())
					local list = use.nullified_list
					table.insert(list, "_ALL_TARGETS")
					use.nullified_list = list
					data:setValue(use)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

heg_caiyuan = sgs.CreateTriggerSkill{
	name = "heg_caiyuan",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseStart, sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and player:getMark("&heg_caiyuan+fail-Self".. sgs.Player_Finish .. "Clear") == 0 then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(2, self:objectName())
			end
		elseif event == sgs.Damaged then
			room:setPlayerMark(player, "&heg_caiyuan+fail-Self".. sgs.Player_Finish .. "Clear", 1)
		end
		return false
	end,
}

heg_yanghuiyu:addSkill(heg_ciwei_record)
heg_yanghuiyu:addSkill(heg_ciwei)
extension_hegpurplecloud:insertRelatedSkills("heg_ciwei", "#heg_ciwei_record")
heg_yanghuiyu:addSkill(heg_caiyuan)

heg_wangyuanji = sgs.General(extension_hegpurplecloud,  "heg_wangyuanji", "jin", 3, false)

heg_yanxiCard = sgs.CreateSkillCard{
	name = "heg_yanxi",
	target_fixed = false,
	filter = function(self, targets, to_select)
		if #targets > 0 then
			for i = 1, #targets, 1 do
				target = targets[i]
				if target:getKingdom() == to_select:getKingdom() then
					return false
				end
			end
		end
		return #targets < 3 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		local to_obtain = sgs.CardList()
		local choices = patterns()
		local choiceslist
		for _, target in sgs.qlist(targets) do
			local id = room:askForCardChosen(source, target, "h", "heg_yanxi", false, sgs.Card_MethodNone)
			to_obtain:append(sgs.Sanguosha:getCard(id))
			local choice = room:askForChoice(target, "heg_yanxi", table.concat(choices, "+"), ToData(source))
			choiceslist[target:objectName()] = choice
		end
		for _, card in sgs.qlist(to_obtain) do
			room:showCard(source, sgs.IntList{card:getId()})
		end
		room:fillAG(to_obtain, source)
		local id = room:askForAG(source, to_obtain, false, self:objectName())
		room:clearAG(source)
		local from = room:getCardOwner(id)
		local declared = choiceslist[from:objectName()]
		local obtained_card = sgs.Sanguosha:getCard(id)
		source:obtainCard(id)
		if obtained_card:getClassName() ~= declared then
			for _, card in sgs.qlist(to_obtain) do
				if card:getId() ~= id then
					source:obtainCard(card, false)
				end
			end
		end
	end
}
    
heg_yanxiVS = sgs.CreateViewAsSkill{
	name = "heg_yanxi",
	n = 0,
	view_as = function(self, cards)
		local skill_card = heg_yanxiCard:clone()
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@heg_yanxi"
	end,
}

heg_yanxi = sgs.CreateTriggerSkill{
	name = "heg_yanxi",
	events = { sgs.EventPhaseStart },
	view_as_skill = heg_yanxiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			room:askForUseCard(player, "@@heg_yanxi", "@heg_yanxi")
		end
		return false
	end,
}

heg_shiren = sgs.CreateTriggerSkill{
	name = "heg_shiren",
	events = { sgs.Damaged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if p:getMark("heg_shiren-Clear") == 0 and p:objectName() ~= damage.to:objectName() then
				if room:askForSkillInvoke(p, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local to_give = room:askForExchange(p, self:objectName(), 2, 2, false, "@heg_shiren-give", true)
					damage.to:obtainCard(to_give)
					p:drawCards(2, self:objectName())
					room:addPlayerMark(p, "heg_shiren-Clear", 1)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

heg_wangyuanji:addSkill(heg_yanxi)
heg_wangyuanji:addSkill(heg_shiren)


heg_jiachong = sgs.General(extension_hegpurplecloud,  "heg_jiachong", "jin", 3)

heg_chujue_buff = sgs.CreateTargetModSkill{
	name = "heg_chujue_buff",
	residue_func = function(self, from, to)
		if from:hasSkill("heg_chujue") and to then
			for _, p in sgs.qlist(from:getSiblings(true)) do
				if p:isDead() and p:getKingdom() == to:getKingdom() then
					return 1000
				end
			end
		end
	end
}
heg_chujue = sgs.CreateTriggerSkill{
	name = "heg_chujue",
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and not use.card:isKindOf("SkillCard") then
			local targets = sgs.SPlayerList()
			local no_respond_list = use.no_respond_list
			for _, to in sgs.qlist(use.to) do
				for _, p in sgs.qlist(room:getAllPlayers(true)) do
					if p:isDead() and p:getKingdom() == to:getKingdom() then
						targets:append(to)
						table.insert(no_respond_list, to:objectName())
					end
				end
			end
			use.no_respond_list = no_respond_list
			data:setValue(use)
			if not targets:isEmpty() then
				local log = sgs.LogMessage()
				log.type = "$NoRespond"
				log.from = use.from
				log.to = targets
				log.arg = self:objectName()
				log.card_str = use.card:toString()
				room:sendLog(log)
			end
		end
		return false
	end,
}


heg_jianzhi = sgs.CreateTriggerSkill{
	name = "heg_jianzhi",
	events = { sgs.DamageCaused, sgs.DrawNCards },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.to and damage.to:isDead() and damage.to:getHp() <= 0 then
				if player:canDiscard(player, "h") and room:askForSkillInvoke(player, self:objectName(), data) then
					player:throwAllHandCards(self:objectName())
					room:addPlayerMark(player, "&heg_jianzhi-Clear", 1)
				end
			end
		elseif event == sgs.DrawNCards then
			if player:getMark("&heg_jianzhi-Clear") > 0 then
				local draw = data:toDraw()
				if draw.reason ~= "kill" then return false end
				draw.num = draw.num * 3
				data:setValue(draw)
			end
		end
		return false
	end,
}

heg_jiachong:addSkill(heg_chujue_buff)
heg_jiachong:addSkill(heg_chujue)
heg_jiachong:addSkill(heg_jianzhi)


heg_guohuaij = sgs.General(extension_hegpurplecloud,  "heg_guohuaij", "jin", 3, false)

heg_zhefu = sgs.CreateTriggerSkill{
	name = "heg_zhefu",
	events = { sgs.CardUsed, sgs.CardResponded },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			local resp = data:toCardResponse()
			card = resp.m_card
		end
		if card and card:isKindOf("BasicCard") and player:getPhase() == sgs.Player_NotActive then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHandcardNum() >= player:getHandcardNum() then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "@heg_zhefu", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					room:showAllCards(target, player)
					local disabled = sgs.IntList()
					local abled = sgs.IntList()
					for _, c in sgs.qlist(target:getHandcards()) do
						if not c:isKindOf("BasicCard") or not player:canDiscard(target, c:getEffectiveId()) then
							disabled:append(c:getId())
						else
							abled:append(c:getId())
						end
					end
					if abled:isEmpty() then return false end
					local to_discard = room:askForCardChosen(player, target, "h", self:objectName(), false, sgs.Card_MethodDiscard, disabled)
					local to_discard_card = sgs.Sanguosha:getCard(to_discard)
					if to_discard_card:isKindOf("BasicCard") then
						room:throwCard(to_discard_card, target, player)
					end
				end
			end
		end
		return false
	end,
}

heg_yidu = sgs.CreateTriggerSkill{
	name = "heg_yidu",
	events = { sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isDamageCard() then
			local targets = sgs.SPlayerList()
			for _, to in sgs.qlist(use.to) do
				if not use.card:hasFlag("DamageDone_" .. to:objectName()) then
					targets:append(to)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "@heg_yidu", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					local handcards = target:getHandcards()
					if handcards:isEmpty() then return false end
					local to_show = sgs.CardList()
					for i = 1, math.min(2, handcards:length()), 1 do
						local id = room:askForCardChosen(player, target, "h", self:objectName(), false, sgs.Card_MethodNone, to_show)
						local card = sgs.Sanguosha:getCard(id)
						to_show:append(card)
					end
					room:showCards(player, to_show, target)
					local same_color = true
					local first_color = to_show:first():getColor()
					for _, c in sgs.qlist(to_show) do
						if c:getColor() ~= first_color then
							same_color = false
							break
						end
					end
					if same_color then
						for _, c in sgs.qlist(to_show) do
							room:throwCard(c, target, player)
						end
					end
				end
			end
		end
		return false
	end,
}

heg_guohuaij:addSkill(heg_zhefu)
heg_guohuaij:addSkill(heg_yidu)

heg_wangjun = sgs.General(extension_hegpurplecloud,  "heg_wangjun", "jin", 4)

heg_chengliuCard = sgs.CreateSkillCard{
	name = "heg_chengliu",
	target_fixed = false,
	filter = function(self, targets, to_select)
		if #targets > 0 then return false end
		local source = sgs.Self
		return to_select:getEquips():length() < source:getEquips():length()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:broadcastSkillInvoke("heg_chengliu")
		local damage = sgs.DamageStruct()
		damage.from = source
		damage.to = target
		damage.damage = 1
		room:damage(damage)
		local source_equips = source:getEquips()
		local target_equips = target:getEquips()
		local source_ids = sgs.IntList()
		local target_ids = sgs.IntList()
		for _, c in sgs.qlist(source_equips) do
			source_ids:append(c:getId())
		end
		for _, c in sgs.qlist(target_equips) do
			target_ids:append(c:getId())
		end
		room:moveCardsAtomic(sgs.CardMoveStruct(source_ids, target, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, source:objectName(), self:objectName(), "")),
			sgs.CardMoveStruct(target_ids, source, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, target:objectName(), self:objectName(), "")), true)
		room:askForUseCard(source, "@@heg_chengliu", "@heg_chengliu")
	end,
}
heg_chengliu = sgs.CreateViewAsSkill{
	name = "heg_chengliu",
	n = 0,
	view_as = function(self, cards)
		local skill_card = heg_chengliuCard:clone()
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("heg_chengliu")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@heg_chengliu"
	end,
}

heg_wangjun:addSkill(heg_chengliu)

heg_malong = sgs.General(extension_hegpurplecloud,  "heg_malong", "jin", 4)

heg_zhuanzhan = sgs.CreateTargetModSkill{
	name = "heg_zhuanzhan",
	pattern = "Slash",
	distance_limit_func = function(self, from, card)
		if from:hasSkill(self:objectName()) then
			return 1000
		end
	end,
}
heg_zhuanzhan_prohibit = sgs.CreateProhibitSkill{
	name = "#heg_zhuanzhan_prohibit",
	is_prohibited = function(self, from, to, card)
		if from and from:hasSkill("heg_zhuanzhan") and card and card:isKindOf("Slash") then
			if to:getMark("damage_record") == 0 then
				return true
			end
		end
		return false
	end,
}

heg_xunjim = sgs.CreateTriggerSkill{
	name = "heg_xunjim",
	events = { sgs.PreCardUsed, sgs.CardFinished },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then
				local extra_targets = room:getCardTargets(player, use.card)
            	if not extra_targets:isEmpty() then 
					local targets = room:askForPlayersChosen(player, extra_targets, self:objectName(), 0, 2, "@heg_xunjim", true, true)
					for _, to in sgs.qlist(targets) do
						table.insert(use.to, to)
					end
					data:setValue(use)
					room:setCardFlag(use.card, "heg_xunjim")
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.card:hasFlag("heg_xunjim") then
				local all_damaged = true
				for _, to in sgs.qlist(use.to) do
					if to:isAlive() and not use.card:hasFlag("DamageDone_"..to:objectName()) then
						all_damaged = false
						break
					end
				end
				if all_damaged then
					room:broadcastSkillInvoke(self:objectName())
					room:addPlayerHistory(player, use.card:getClassName(), -1)
				end
			end
		end
		return false
	end,
}

heg_malong:addSkill(heg_zhuanzhan)
heg_malong:addSkill(heg_zhuanzhan_prohibit)
heg_malong:addSkill(heg_xunjim)
extension_hegpurplecloud:insertRelatedSkills("heg_zhuanzhan", "#heg_zhuanzhan_prohibit")


heg_zhanghuyuechen = sgs.General(extension_goldenseal,  "heg_zhanghuyuechen", "jin", 4)

heg_xijue = sgs.CreateTriggerSkill{
	name = "heg_xijue",
	waked_skills = "tenyeartuxi,xiaoguo",
	events = { sgs.DrawNCards, sgs.AfterDrawNCards, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DrawNCards and player:hasSkill(self:objectName()) and player:canDiscard(player, "he") then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			local tuxi = sgs.Sanguosha:getTriggerSkill("tenyeartuxi")
			local can_invoke = false
			local other_players = room:getOtherPlayers(player)
			for _, q in sgs.qlist(other_players) do
				if not q:isKongcheng() then
					can_invoke = true
					break
				end
			end
			if tuxi and can_invoke and room:askForCard(player, ".", "@heg_xijue-tenyeartuxi", data, sgs.Card_MethodDiscard, nil, false, self:objectName(), false, nil) then
				room:setPlayerMark(player, "tenyeartuxi", draw.num)
				room:notifySkillInvoked(player,self:objectName())
				tuxi:trigger(event,room,player,data)
				room:setPlayerMark(player, "tuxi", 0)
			end
		elseif event == sgs.AfterDrawNCards and player:hasSkill(self:objectName()) then
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			local tuxiAct = sgs.Sanguosha:getTriggerSkill("#tenyeartuxi")
			if tuxiAct then
				tuxiAct:trigger(event,room,player,data)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:canDiscard(p, "he") then
						if room:askForCard(p, ".", "@heg_xijue-xiaoguo", data, sgs.Card_MethodDiscard, nil, false, self:objectName(), false, nil) then
							room:setPlayerProperty(p, "pingjian_triggerskill", sgs.QVariant("xiaoguo"))
							local xiaoguo = sgs.Sanguosha:getTriggerSkill("xiaoguo")
							xiaoguo:trigger(event,room,player,data)
							room:setPlayerProperty(p, "pingjian_triggerskill", sgs.QVariant(""))
						end
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

heg_lvxian = sgs.CreateTriggerSkill{
    name = "heg_lvxian",
    events = { sgs.CardsMoveOneTime, sgs.EventPhaseChanging, sgs.Damaged },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) then
                if player:getPhase() ~= sgs.Player_NotActive then
                    local count = move.card_ids:length()
                    room:addPlayerMark(player, "heg_lvxian_lost", count)
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                local lost = player:getMark("heg_lvxian_lost")
                room:setPlayerMark(player, "heg_lvxian_lastlost", lost)
                room:setPlayerMark(player, "heg_lvxian_lost", 0)
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    room:setPlayerMark(p, "last_turn_player", 0)
                end
                room:setPlayerMark(player, "last_turn_player", 1)
            end
        elseif event == sgs.Damaged then
            if not player:hasSkill(self:objectName()) then return false end
			if not player:getGeneralName() == "heg_zhanghuyuechen" and player:getMark("gerenal_limit") == 0 then return false end
            room:addPlayerMark(player, "heg_lvxian_damaged-Clear")
            if player:getMark("heg_lvxian_damaged-Clear") > 1 then return false end
            
            if player:getMark("last_turn_player") > 0 then return false end
            
            local lost = player:getMark("heg_lvxian_lastlost")
            if lost > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                player:drawCards(lost, self:objectName())
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end
}

heg_yingwei = sgs.CreateTriggerSkill{
    name = "heg_yingwei",
    events = { sgs.Damage, sgs.DrawNCards, sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        
        if event == sgs.Damage then
            -- Track damage dealt
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() == player:objectName() then
                room:addPlayerMark(player, "heg_yingwei_damage-Clear", damage.damage)
            end
        elseif event == sgs.DrawNCards then
            -- Track cards drawn in draw phase
            local draw = data:toDraw()
            if draw.reason == "draw_phase" then
                room:addPlayerMark(player, "heg_yingwei_drawn-Clear", draw.num)
            end
        elseif event == sgs.EventPhaseStart then
            -- Trigger at end phase
            if player:getPhase() ~= sgs.Player_Finish then return false end
            if not player:hasSkill(self:objectName()) then return false end
            if not player:getGeneral2Name() == "heg_zhanghuyuechen" and player:getMark("gerenal_limit") == 0 then return false end
            local damage_dealt = player:getMark("heg_yingwei_damage-Clear")
            local cards_drawn = player:getMark("heg_yingwei_drawn-Clear")
            
            if damage_dealt > 0 and damage_dealt == cards_drawn and not player:isNude() then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())
                    -- Allow recasting up to 2 cards
                    for i = 1, 2 do
                        if player:isNude() then break end
                        local card = room:askForCard(player, ".", "@heg_yingwei", data, sgs.Card_MethodNone)
                        if card then
							local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName())
							reason.m_skillName = self:objectName()
							room:moveCardTo(card, player, nil, sgs.Player_DiscardPile, reason)
                            player:drawCards(1, "recast")
                        else
                            break
                        end
                    end
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end
}
	
heg_zhanghuyuechen:addSkill(heg_xijue)
heg_zhanghuyuechen:addSkill(heg_lvxian)
heg_zhanghuyuechen:addSkill(heg_yingwei)


heg_wenyang = sgs.General(extension_goldenseal,  "heg_wenyang", "jin", 5)

heg_duanqiu_buff = sgs.CreateTriggerSkill{
	name = "#heg_duanqiu_buff",
	events = { sgs.CardResponded },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local resp = data:toCardResponse()
		local card = resp.m_card
		if card and card:isKindOf("Slash") and resp.m_toCard and resp.m_toCard:isKindOf("Duel") and table.contains(resp.m_toCard:getSkillNames(), "heg_duanqiu") then
			if resp.m_who then
				room:addPlayerMark(resp.m_who, "heg_duanqiu_slash_count")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
heg_duanqiu_limit = sgs.CreateTriggerSkill{
	name = "#heg_duanqiu_limit",
	events = { sgs.CardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and not use.card:isKindOf("SkillCard") then
			local current = room:getCurrent()
			if current and current:hasSkill("heg_duanqiu") then
				room:removePlayerMark(current, "&heg_duanqiu-Clear")
				if current:getMark("&heg_duanqiu-Clear") == 0 then
					for _, p in sgs.qlist(room:getAllPlayers()) do
						room:setPlayerCardLimitation(p, "use", ".|.|.|hand", true)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

heg_duanqiu = sgs.CreateTriggerSkill{
  	name = "heg_duanqiu",
  	events = { sgs.EventPhaseProceeding },
  	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and room:askForSkillInvoke(player, self:objectName()) then
			local kingdom_list = {}
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				local k = p:getKingdom()
				if k ~= player:getKingdom() and not table.contains(kingdom_list, k) then
					table.insert(kingdom_list, k)
				end
			end
			if #kingdom_list == 0 then return false end
			local kingdom = room:askForKingdom(player,  self:objectName(), table.concat(kingdom_list, "+"), true)
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getKingdom() == kingdom then
					local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
					duel:setSkillName(self:objectName())
					local use = sgs.CardUseStruct()
					use.card = duel
					use.from = player
					use.to:append(p)
					room:useCard(use)
				end
			end
			room:addPlayerMark(player, "&heg_duanqiu-Clear", player:getMark("heg_duanqiu_slash_count"))
			room:setPlayerMark(player, "heg_duanqiu_slash_count", 0)
		end
	end
}

heg_wenyang:addSkill(heg_duanqiu_buff)
heg_wenyang:addSkill(heg_duanqiu_limit)
heg_wenyang:addSkill(heg_duanqiu)
extension_goldenseal:insertRelatedSkills("heg_duanqiu", "#heg_duanqiu_buff")
extension_goldenseal:insertRelatedSkills("heg_duanqiu", "#heg_duanqiu_limit")


heg_yanghu = sgs.General(extension_goldenseal,  "heg_yanghu", "jin", 4)

heg_huaiyuan = sgs.CreateTriggerSkill{
	name = "heg_huaiyuan",
	events = { sgs.EventPhaseProceeding },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if room:askForSkillInvoke(p, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					local choice = room:askForChoice(p, self:objectName(), "range+maxcard+slash", ToData(player))
					if choice == "range" then
						room:addAttackRange(player,  1, true)
					elseif choice == "maxcard" then
						room:addMaxCards(player, 1, true)
					elseif choice == "slash" then
						room:addSlashCishu(player, 1, true)
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

heg_fushou = sgs.CreateTriggerSkill{
  	name = "heg_fushou",
  	events = { sgs.GameStart, sgs.EventAcquireSkill, sgs.EventLoseSkill },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getKingdom() == player:getKingdom() then
					room:addPlayerMark(p, "gerenal_limit")
				end
			end
		elseif event == sgs.EventLoseSkill and data:toString() == self:objectName() then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getKingdom() == player:getKingdom() then
					room:removePlayerMark(p, "gerenal_limit")
				end
			end
		end
		return false
	end,
}

heg_yanghu:addSkill(heg_huaiyuan)
heg_yanghu:addSkill(heg_fushou)

heg_yangjun = sgs.General(extension_goldenseal,  "heg_yangjun", "jin", 4)

heg_neiji = sgs.CreateTriggerSkill{
  	name = "heg_neiji",
  	events = { sgs.EventPhaseStart },
  	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isKongcheng() then
					targets:append(p)
				end
			end
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "heg_neiji-invoke", true, true)
			if not target then return false end
			local source_cards = room:askForExchange(player, self:objectName(), 2, 2, false, "@heg_neiji-show", true)
			local target_cards = room:askForExchange(target, self:objectName(), 2, 2, false, "@heg_neiji-show", true)
			local slash_count = 0
			local from_count = 0
			local to_count = 0
			for _, id in sgs.qlist(source_cards) do
				local card = sgs.Sanguosha:getCard(id)
				room:showCard(player, id)
				if card:isKindOf("Slash") then
					slash_count = slash_count + 1
					room:throwCard(card, player, nil)
					from_count = from_count + 1
				end
			end
			for _, id in sgs.qlist(target_cards) do
				local card = sgs.Sanguosha:getCard(id)
				room:showCard(target, id)
				if card:isKindOf("Slash") then
					slash_count = slash_count + 1
					room:throwCard(card, target, nil)
					to_count = to_count + 1
				end
			end
			if slash_count > 1 then
				player:drawCards(3, self:objectName())
				target:drawCards(3, self:objectName())
			elseif slash_count == 1 then
				local to_use = target
				local to_target = player
				if from_count > to_count then
					to_use = player
					to_target = target
				end
				local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
				duel:setSkillName(self:objectName())
				duel:deleteLater()
				local use = sgs.CardUseStruct()
				use.card = duel
				use.from = to_use
				use.to:append(to_target)
				room:useCard(use)
			end
		end
		return false
	end,
}

heg_yangjun:addSkill(heg_neiji)

heg_bailingyun = sgs.General(extension_goldenseal,  "heg_bailingyun", "jin", 3, false)


heg_xiaceVS = sgs.CreateViewAsSkill{
	name = "heg_xiace",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local card = cards[1]
		local skill_card = sgs.Sanguosha:cloneCard("nullification", card:getSuit(), card:getNumber())
		skill_card:addSubcard(card)
		skill_card:setSkillName(self:objectName())
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		local invoke = false
		for _,p in sgs.list(pattern:split("+"))do
			local c = dummyCard(p)
			if c and c:isKindOf("Nullification") then invoke = true end
		end
		if invoke then
			local current
			for _, p in sgs.qlist(player:getAliveSiblings(true)) do
				if p:getPhase() ~= sgs.Player_NotActive then
					current = p
					break
				end
			end
			if current then
				return sgs.Slash_IsAvailable(current)
			end
		end
		return false
	end
}

heg_xiace = sgs.CreateTriggerSkill{
	name = "heg_xiace",
	events = { sgs.CardUsed },
	view_as_skill = heg_xiaceVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Nullification") and use.card:getSkillName() == self:objectName() then
			local current
			for _, p in sgs.qlist(player:getAliveSiblings(true)) do
				if p:getPhase() ~= sgs.Player_NotActive then
					current = p
					break
				end
			end
			if current then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerHistory(current, "Slash", 1)
				if room:askForSkillInvoke(player, self:objectName()) then
					ChangeGeneral(room, player, "heg_bailingyun")
				end
			end
		end
		return false
	end,
}

heg_limeng = sgs.CreateTriggerSkill{
	name = "heg_limeng",
	events = { sgs.EventPhaseProceeding },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if room:askForCard(player, "^BasicCard", "@heg_limeng", data, sgs.Card_MethodDiscard, nil, false, self:objectName(), false, nil) then
				room:broadcastSkillInvoke(self:objectName())
				local targets = room:askForPlayersChosen(player, room:getAlivePlayers(), self:objectName(), 2, 2, "@heg_limeng-target", true, true)
				if targets:length() < 2 then return false end
				local to1 = targets:first()
				local to2 = targets:last()
				local damage1 = sgs.DamageStruct()
				damage1.from = player
				damage1.to = to1
				damage1.damage = 1
				room:damage(damage1)
				local damage2 = sgs.DamageStruct()
				damage2.from = player
				damage2.to = to2
				damage2.damage = 1
				room:damage(damage2)
			end
		end
		return false
	end,
}

heg_bailingyun:addSkill(heg_xiace)
heg_bailingyun:addSkill(heg_limeng)


heg_wangxiang = sgs.General(extension_goldenseal,  "heg_wangxiang", "jin", 4)

heg_bingxinCard = sgs.CreateSkillCard{
	name = "heg_bingxin",
	will_throw = false,
	filter = function(self,targets,to_select,from)
		local pattern = self:getUserString()
		if pattern=="normal_slash" then pattern = "slash" end
		local plist = sgs.PlayerList()
		for i = 1,#targets do plist:append(targets[i]) end
		for _,cn in sgs.list(pattern:split("+"))do
			local dc = dummyCard(cn,"heg_bingxin")
			if dc then
				if dc:targetFixed() then return end
				return dc:targetFilter(plist,to_select,from)
			end
		end
	end,
	feasible = function(self,targets,from)
		local pattern = self:getUserString()
		if pattern=="normal_slash" then pattern = "slash" end
		local plist = sgs.PlayerList()
		for i = 1,#targets do plist:append(targets[i]) end
		for _,cn in sgs.list(pattern:split("+"))do
			local dc = dummyCard(cn,"heg_bingxin")
			if dc then
				if dc:targetFixed() then return true end
				return dc:targetsFeasible(plist,from)
			end
		end
	end,
	on_validate = function(self,use)
		local room = use.from:getRoom()
		local to_guhuo = self:getUserString()
		to_guhuo = room:askForChoice(use.from,"heg_bingxin",to_guhuo)
		if not use.from:isKongcheng() then
			room:showAllCards(use.from)
		end
		use.from:drawCards(1,"heg_bingxin")
		local use_card = sgs.Sanguosha:cloneCard(to_guhuo)
		use_card:setSkillName("_heg_bingxin")
		use_card:deleteLater()
		room:addPlayerMark(use.from,"heg_bingxin_guhuo_remove_"..to_guhuo.."-Clear")
		return use_card
	end,
	on_validate_in_response = function(self,yuji)
		local room = yuji:getRoom()
		NotifySkillInvoked("heg_bingxin",yuji)
		local to_guhuo = self:getUserString()
		room:addPlayerMark(yuji,"heg_bingxinUse-Clear")
		to_guhuo = room:askForChoice(yuji,"heg_bingxin",to_guhuo)
		if not yuji:isKongcheng() then
			room:showAllCards(yuji)
		end
		yuji:drawCards(1,"heg_bingxin")
		local use_card = sgs.Sanguosha:cloneCard(to_guhuo)
		use_card:setSkillName("_heg_bingxin")
		use_card:deleteLater()
		room:addPlayerMark(yuji,"heg_bingxin_guhuo_remove_"..to_guhuo.."-Clear")
		return use_card
	end
}
heg_bingxin = sgs.CreateZeroCardViewAsSkill{
	name = "heg_bingxin",
	view_as = function(self)
		local card = heg_bingxinCard:clone()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local dc = sgs.Self:getTag("heg_bingxin"):toCard()
			if dc==nil then return end
			pattern = dc:objectName()
		end
		card:setUserString(pattern)
		return card
	end,
	enabled_at_play = function(self, player)
		if player:getHandcardNum() ~= player:getHp() then return false end
		local first_color = nil
		for _,c in sgs.qlist(player:getHandcards())do
			if first_color==nil then
				first_color = c:getColor()
			elseif first_color~=c:getColor() then
				return false
			end
		end
		for _,c in sgs.list(PatternsCard("BasicCard",true))do
			if c:isAvailable(player) and player:getMark("heg_bingxin_guhuo_remove_"..c:objectName().."-Clear") == 0
			then return true end
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if player:getHandcardNum() ~= player:getHp() then return false end
		local first_color = nil
		for _,c in sgs.qlist(player:getHandcards())do
			if first_color==nil then
				first_color = c:getColor()
			elseif first_color~=c:getColor() then
				return false
			end
		end
		for _,pc in sgs.list(pattern:split("+"))do
			local dc = dummyCard(pc)
			if dc and dc:getTypeId()==1 and player:getMark("heg_bingxin_guhuo_remove_"..dc:objectName().."-Clear") == 0
			then return true end
		end
	end
}
heg_bingxin:setGuhuoDialog("l")
heg_wangxiang:addSkill(heg_bingxin)

heg_sunxiu = sgs.General(extension_goldenseal,  "heg_sunxiu", "jin", 4)

heg_xiejianCard = sgs.CreateSkillCard{
	name = "heg_xiejian",
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local allCommands = {"command1", "command2", "command3", "command4", "command5", "command6"}
		local num = 2
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

		local room = source:getRoom()
		local choice = room:askForChoice(source, "start_command", table.concat(commands, "+"))

		local log = sgs.LogMessage()
		log.type = "#CommandChoice"
		log.from = source
		log.arg = ":" .. choice
		room:sendLog(log)
		local x = 0
		for i = 1, #allCommands do
			if allCommands[i] == choice then
				x = i
				break
			end
		end
		local invoke = doCommand(target, "heg_xiejian", x, source)
		if not invoke then
			table.remove(commands, choice)
			local force = commands[1]
			local x = 0
			for i = 1, #allCommands do
				if allCommands[i] == force then
					x = i
					break
				end
			end
			doCommand(target, "heg_xiejian", x, source, true)
		end
	end,
}

heg_xiejian = sgs.CreateViewAsSkill{
	name = "heg_xiejian",
	n = 0,
	view_as = function(self, cards)
		return heg_xiejianCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_xiejian")
	end,
}

heg_yinshaVS = sgs.CreateViewAsSkill{
	name = "heg_yinsha",
	n = 0,
	view_as = function(self, cards)
		local card = sgs.Sanguosha:cloneCard("collateral", sgs.Card_NoSuit, 0)
		card:setSkillName(self:objectName())
		card:addSubcards(sgs.Self:getHandcards())
		return card
	end,
	enabled_at_play = function(self, player)
		return not player:isKongcheng()
	end,
}
heg_yinsha = sgs.CreateTriggerSkill{
	name = "heg_yinsha",
	view_as_skill = heg_yinshaVS,
	events = { sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		if effect.card:isKindOf("Collateral") and table.contains(effect.card:getSkillNames(),self:objectName()) then
			if effect.nullified then
				local log = sgs.LogMessage()
				log.type = "#CardNullified"
				log.from = effect.to
				log.card_str = effect.card:toString()
				room:sendLog(log)
				return true
			end
			if not effect.offset_card then
				effect.offset_card = room:isCanceled(effect)
			end
			if effect.offset_card then
				data:setValue(effect)
				if not room:getThread():trigger(sgs.CardOffset, room, effect.from, data) then
					effect.to:setFlags("Global_NonSkillNullify")
					return true
				end
			end
			room:getThread():trigger(sgs.CardOnEffect, room, effect.to, data)
			if effect.to:isAlive() then
				local target = effect.to:getTag("attachTarget"):toPlayer()
				effect.to:removeTag("attachTarget")
				local slash = "slash"
				for _, c in sgs.list(effect.to:getHandcards()) do
					if c:isKindOf("Slash") and not effect.to:isCardLimited(c,sgs.Card_MethodUse,true) then
						slash = "Slash!"
						break
					end
				end
				local useslash
				if slash == "Slash!" then
					useslash = room:askForCard(effect.to,"Slash","collateral-slash:"..target:objectName(),data,sgs.Card_MethodNone,effect.from,false,"collateral",false,effect.card)
					if not useslash and not effect.to:isKongcheng() then
						useslash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						useslash:setSkillName("heg_yinsha")
						useslash:deleteLater()
						useslash:addSubcards(effect.to:getHandcards())
					end
				elseif not effect.to:isKongcheng() then
					useslash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					useslash:setSkillName("heg_yinsha")
					useslash:deleteLater()
					useslash:addSubcards(effect.to:getHandcards())
				end
				if useslash then
					local use = sgs.CardUseStruct()
					use.card = useslash
					use.from = effect.to
					use.to:append(target)
					room:useCard(use)
				end
				
				
			end
			room:setTag("SkipGameRule",sgs.QVariant(event))
		end
	end
}
heg_sunxiu:addSkill(heg_xiejian)
heg_sunxiu:addSkill(heg_yinsha)

heg_duyu = sgs.General(extension_goldenseal,  "heg_duyu", "jin", 4)


heg_sanchenCard = sgs.CreateSkillCard{
	name = "heg_sanchen",
	target_fixed = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:getMark("heg_sanchen_target-PlayClear") == 0
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:addPlayerMark(effect.to, "heg_sanchen_target-PlayClear")
		room:drawCards(effect.to, 3, "heg_sanchen")
		local sc_cards = room:askForDiscard(effect.to, "heg_sanchen", 3, 3, false, true)
		if sc_cards then
			local b, t, e = 0, 0, 0
			for _, id in sgs.qlist(sc_cards:getSubcards()) do
				local cd = sgs.Sanguosha:getCard(id)
				if cd:isKindOf("BasicCard") then
					b = b + 1
				elseif cd:isKindOf("TrickCard") then
					t = t + 1
				elseif cd:isKindOf("EquipCard") then
					e = e + 1
				end
			end
			if b < 2 and t < 2 and e < 2 then
			else
				room:addPlayerMark(effect.from, "heg_sanchen-PlayClear")
			end
		end
	end,
}
heg_sanchen = sgs.CreateZeroCardViewAsSkill{
	name = "heg_sanchen",
	view_as = function()
		return heg_sanchenCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("heg_sanchen-PlayClear") == 0
	end,
}
heg_pozhuVS = sgs.CreateOneCardViewAsSkill {
	name = "heg_pozhu",
	filter_pattern = ".",
	response_pattern = "@@heg_pozhu",
	view_as = function(slef, card)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		slash:addSubcard(card)
		slash:setSkillName("heg_pozhu")
		return slash
	end,
}
heg_pozhu = sgs.CreateTriggerSkill{
  	name = "heg_pozhu",
  	events = { sgs.EventPhaseProceeding },
  	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local card_ids = sgs.IntList()
				local invoke = true
				while invoke do
					local slash = room:askForUseCard(player, "@@heg_pozhu", "@heg_pozhu-slash")
					if not slash then break end
					local use = room:getTag("UseHistory"..slash:toString()):toCardUse()
					if not use or not use.card or not use.card:isKindOf("Slash") or use.to:length() ~= 1 then break end
					local target = use.to:first()
					-- Show a random hand card of the target
					if not target:isKongcheng() then
						local id = room:askForCardChosen(player, target, "h", self:objectName())
						room:showCard(target, id)
						local suit_str = sgs.Sanguosha:getCard(id):getSuitString()
						if slash:getSuitString() ~= suit_str then
							invoke = true
						else
							invoke = false
						end
					else
						invoke = false
					end
				end
			end
		end
		return false
	end,
}
heg_duyu:addSkill(heg_sanchen)
heg_duyu:addSkill(heg_pozhu)

heg_mobile_zhanglu = sgs.General(extension_hegmobile,  "heg_mobile_zhanglu", "qun+wei", 3)

heg_mobile_bushi = sgs.CreateTriggerSkill{
  	name = "heg_mobile_bushi",
  	events = { sgs.EventPhaseProceeding, sgs.EventPhaseChanging },
  	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:hasSkill(self:objectName()) then
				room:addPlayerMark(player, "&heg_mobile_yishe", player:getHp())
			end
		elseif event == sgs.EventPhaseProceeding then
			if player:getPhase() == sgs.Player_Start then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:objectName() ~= player:objectName() and p:getMark("&heg_mobile_yishe") > 0 and room:askForSkillInvoke(p, self:objectName(), ToData(player)) then
						room:broadcastSkillInvoke(self:objectName())
						room:removePlayerMark(p, "&heg_mobile_yishe")
						local card = room:askForCard(p, "..!", "@heg_mobile_bushi:"..player:objectName(), data, sgs.Card_MethodNone, nil, false, self:objectName())
						if card then
							room:obtainCard(player, card, false)
							p:drawCards(2, self:objectName())
						end
					end
				end
				if player:hasSkill(self:objectName()) then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					room:setPlayerMark(player, "&heg_mobile_yishe", 0)
					local to_discard = math.max(0, (room:alivePlayerCount() - player:getHp() - 2))
					if to_discard > 0 then
						local discards = room:askForDiscard(player, self:objectName(), to_discard, to_discard, false, true)
						room:throwCard(discards, player, nil)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

heg_mobile_midao = sgs.CreateTriggerSkill{
  	name = "heg_mobile_midao",
	frequency = sgs.Skill_Frequent,
  	events = { sgs.EventPhaseProceeding, sgs.AskForRetrial },
  	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Finish then
			if player:hasSkill(self:objectName()) and player:getPile("heg_mobile_rice"):isEmpty() and room:askForSkillInvoke(player, self:objectName()) then
				local room = player:getRoom()
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(2, self:objectName())
				if not player:isNude() then
					local cards = room:askForExchange(player, self:objectName(), 2, 2, true, "@heg_mobile_midao_push", false)
					local ids = sgs.IntList()
					for _, id in sgs.qlist(cards:getSubcards()) do
						ids:append(id)
					end
					player:addToPile("heg_mobile_rice", ids)
				end
			end
		elseif event == sgs.AskForRetrial then
			local judge = data:toJudge()
			if judge.who:objectName() ~= player:objectName() and player:hasSkill(self:objectName()) and not player:getPile("heg_mobile_rice"):isEmpty() then
				local room = player:getRoom()
				room:broadcastSkillInvoke(self:objectName())
				local prompt = string.format("@heg_mobile_midao:%s:%s:%s", judge.who:objectName(), self:objectName(),  judge.reason)
				local card = room:askForCard(player, ".|.|.|heg_mobile_rice", prompt, data, sgs.Card_MethodResponse, judge.who, true)
				if card then
					room:retrial(card, player, judge, self:objectName(), true)
				end
			end
		end
		return false
	end,
}

heg_mobile_zhanglu:addSkill(heg_mobile_bushi)
heg_mobile_zhanglu:addSkill(heg_mobile_midao)
	
heg_mobile_xushu = sgs.General(extension_hegmobile,  "heg_mobile_xushu", "shu", 3)

heg_mobile_zhuhai = sgs.CreateTriggerSkill{
  	name = "heg_mobile_zhuhai",
  	events = { sgs.EventPhaseProceeding, sgs.PreCardUsed, sgs.CardOffset },
  	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseProceeding then
			if player:getPhase() == sgs.Player_Finish then
				local room = player:getRoom()
				if player:getMark("damage_point_turn-Clear") > 0 then
					for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
						room:askForUseSlashTo(p, player, "@heg_mobile_zhuhai:"..player:objectName(), false, false, false, nil, nil, "heg_mobile_zhuhai")
					end
				end
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.card:hasFlag("heg_mobile_zhuhai") then
				room:broadcastSkillInvoke(self:objectName())
				room:setCardFlag(use.card, "SlashIgnoreArmor")
			end
		elseif event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") and effect.card:hasFlag("heg_mobile_zhuhai") then
				if effect.to:canDiscard(effect.to, "he") then
					room:askForDiscard(effect.to, self:objectName(), 1, 1, false, true)
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

heg_mobile_jiancai = sgs.CreateTriggerSkill{
  	name = "heg_mobile_jiancai",
	frequency = sgs.Skill_Limited,
	limit_mark = "@heg_mobile_jiancai",
  	events = { sgs.RoundStart, sgs.DamageInflicted },
  	on_trigger = function(self, event, player, data, room)
		if event == sgs.RoundStart and player:hasSkill(self:objectName()) then
			local x = room:getTag("TurnLengthCount"):toInt() * 3
			local general_list = player:property("heg_mobile_jiancai_generals"):toString():split("+")
			if #general_list < x then
				local splist = sgs.SPlayerList()
				splist:append(player)
				while #general_list < x do
					local generals = {}
					for _,name in ipairs(sgs.Sanguosha:getLimitedGeneralNames("shu")) do
						if not sgs.Sanguosha:isGeneralHidden(name) and not table.contains(generals, name) and not table.contains(general_list, name) then
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
					local name = generals[math.random(1, #generals)]
					room:doAnimate(4,player:objectName(),"unknown",room:getOtherPlayers(player))
					table.insert(general_list, name)
					room:doAnimate(4,player:objectName(),name,splist)
				end
				room:setPlayerProperty(player, "heg_mobile_jiancai_generals", sgs.QVariant(table.concat(general_list, "+")))
				player:setSkillDescriptionSwap("heg_mobile_jiancai", "%arg1", table.concat(general_list, "+|+"))
				room:changeTranslation(player, "heg_mobile_jiancai", 1)
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.to:objectName() ~= player:objectName() then return false end
			if damage.damage < damage.to:getHp() then return false end
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getMark("@heg_mobile_jiancai") > 0 and room:askForSkillInvoke(p, self:objectName(), data) then
					room:removePlayerMark(p, "@heg_mobile_jiancai")
					local general_list = p:property("heg_mobile_jiancai_generals"):toString():split("+")
					local choices = {}
					for _, name in ipairs(general_list) do
						if not table.contains(choices, name) then
							table.insert(choices, name)
						end
					end
					local name
					if p:getState() == "online" then
						if room:askForSkillInvoke(p, self:objectName(), ToData("change")) then
							name = room:askForGeneral(p, table.concat(choices, "+"))
						else
							ChangeGeneral(room, player, "heg_mobile_xushu")
							damage.prevented = true
							data:setValue(damage)
							return true
						end
					else
						name = choices[math.random(1, #choices)]
					end
					local x = p:getMaxHp()
					local y = p:getHp()
					if p:getGeneral2Name() == "heg_mobile_xushu" then
						room:changeHero(p, name, false, false, true)
					elseif p:getGeneralName() == "heg_mobile_xushu" then
						room:changeHero(p, name, false, false, false)
					end

					room:setPlayerProperty(p, "maxhp", sgs.QVariant(x))
					room:setPlayerProperty(p, "hp", sgs.QVariant(y))
					damage.prevented = true
					data:setValue(damage)
					return true
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

heg_mobile_xushu:addSkill(heg_mobile_zhuhai)
heg_mobile_xushu:addSkill(heg_mobile_jiancai)

heg_mobile_zhonghui = sgs.General(extension_hegmobile,  "heg_mobile_zhonghui", "wei", 4)

heg_mobile_paiyiCard = sgs.CreateSkillCard{
	name = "heg_mobile_paiyi",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
		room:throwCard(self, reason, nil)
		target:drawCards(2, "heg_mobile_paiyi")
		if target:getHandcardNum() > source:getHandcardNum() then
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.to = target
			damage.damage = 1
			room:damage(damage)
		end
	end,
}
heg_mobile_paiyi = sgs.CreateOneCardViewAsSkill{
	name = "heg_mobile_paiyi",
	filter_pattern = ".|.|.|heg_quanji_power",
	expand_pile = "heg_quanji_power",
	view_as = function(self, card)
		local skill_card = heg_mobile_paiyiCard:clone()
		skill_card:addSubcard(card)
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#heg_mobile_paiyi") < 2 and player:getPile("heg_quanji_power"):length() > 0
	end,
}


heg_mobile_zhonghui:addSkill("heg_nos_quanji")
heg_mobile_zhonghui:addSkill(heg_mobile_paiyi)

heg_mobile_lukang = sgs.General(extension_hegmobile,  "heg_mobile_lukang", "wu", 3)

heg_mobile_keshouVS = sgs.CreateViewAsSkill{
	name = "heg_mobile_keshou",
	n = 2,
	view_filter = function(self, selected, to_select)
		if #selected < 2 then
			if #selected > 0 then
				return to_select:getColor() == selected[1]:getColor()
			else
				return true
			end
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if #cards ~= 2 then return nil end
		local skillcard = heg_keshouCard:clone()
		skillcard:setSkillName(self:objectName())
		for _, card in ipairs(cards) do
			skillcard:addSubcard(card)
		end
		return skillcard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@heg_mobile_keshou"
	end
}
heg_mobile_keshou = sgs.CreateTriggerSkill{
	name = "heg_mobile_keshou",
	events = {sgs.DamageInflicted},
	view_as_skill = heg_mobile_keshouVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.to and damage.to:objectName() == player:objectName() then
				if player:getHandcardNum() + player:getEquips():length() < 2 then return false end
				room:setTag("heg_mobile_keshou", data)
				local cards = room:askForUseCard(player, "@@heg_mobile_keshou", "@heg_mobile_keshou-discard", -1, sgs.Card_MethodDiscard)
				room:removeTag("heg_mobile_keshou")
				if cards and cards:subcardsLength() == 2 then
					room:notifySkillInvoked(player, self:objectName())
					player:damageRevises(data, -1)
					local judge = sgs.JudgeStruct()
					judge.who = player
					judge.pattern = ".|red"
					judge.good = true
					judge.reason = self:objectName()
					room:judge(judge)
					if judge:isGood() then
						player:drawCards(1, self:objectName())
					end
				end
			end
		end
		return false
	end
}
heg_mobile_zhuwei = sgs.CreateTriggerSkill{
	name = "heg_mobile_zhuwei",
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local card = judge.card
		local card_data = sgs.QVariant()
		card_data:setValue(card)
		if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge and player:askForSkillInvoke(self:objectName(), card_data) then
			player:obtainCard(card)
			local current = room:getCurrent()
			if current and current:isAlive() and player:askForSkillInvoke(self:objectName(), ToData(current)) then
				room:broadcastSkillInvoke(self:objectName())
				room:addSlashCishu(current, 1, true)
				room:addMaxCards(current, 1, true)
				room:addPlayerMark(current, "&heg_mobile_zhuwei+to+#"..player:objectName().."-Clear", 1)
			end
		end
		return false
	end
}
heg_mobile_lukang:addSkill(heg_mobile_keshou)
heg_mobile_lukang:addSkill(heg_mobile_zhuwei)

heg_mobile_huaxiong = sgs.General(extension_hegmobile,  "heg_mobile_huaxiong", "qun", 4)

heg_mobile_yaowu = sgs.CreateTriggerSkill{
  	name = "heg_mobile_yaowu",
	events = { sgs.Damage },
	frequency = sgs.Skill_Limited,
	limit_mark = "@heg_mobile_yaowu",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damage and player:getMark("@heg_mobile_yaowu") > 0 then
			local damage = data:toDamage()
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:removePlayerMark(player, "@heg_mobile_yaowu")
				room:gainMaxHp(player, 2, self:objectName())
				room:recover(player, sgs.RecoverStruct(self:objectName(), player, 2), true)
				room:addPlayerMark(player, "heg_mobile_yaowu", 1)
				room:changeTranslation(player, "heg_mobile_shiyong", 2)
			end
		end
	end
}

heg_mobile_shiyong = sgs.CreateTriggerSkill{
  	name = "heg_mobile_shiyong",
	events = { sgs.Damaged },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local card = damage.card
			if card and not card:isRed() and player:getMark("heg_mobile_yaowu") == 0 then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1, self:objectName())
			elseif (not card or not card:isBlack()) and player:getMark("heg_mobile_yaowu") > 0 then
				if damage.from then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					damage.from:drawCards(1, self:objectName())
				end
			end
		end
	end
}

heg_mobile_huaxiong:addSkill(heg_mobile_yaowu)
heg_mobile_huaxiong:addSkill(heg_mobile_shiyong)

heg_mobile_liaohua = sgs.General(extension_hegmobile,  "heg_mobile_liaohua", "shu", 4)

heg_mobile_dangxian = sgs.CreateTriggerSkill{
  	name = "heg_mobile_dangxian",
	events = { sgs.GameStart, sgs.EventPhaseStart },
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			player:gainMark("@heg_xianqu")
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart and player:getMark("heg_mobile_dangxian_used-Clear") == 0 then
				room:addPlayerMark(player, "heg_mobile_dangxian_used-Clear", 1)
				player:drawCards(1, self:objectName())
				player:insertPhase(sgs.Player_Play)
			end
		end
	end
}
heg_mobile_liaohua:addSkill(heg_mobile_dangxian)

heg_mobile_xiahoushang = sgs.General(extension_hegmobile,  "heg_mobile_xiahoushang", "wei", 4)

heg_mobile_tanfeng = sgs.CreateTriggerSkill{
	name = "heg_mobile_tanfeng",
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canDiscard(p, "hej") then
					targets:append(p)
				end
			end
			if not targets:isEmpty() then
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "@heg_mobile_tanfeng", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					local id = room:askForCardChosen(player, target, "hej", self:objectName())
					room:throwCard(id, target, player)
					if room:askForSkillInvoke(target, self:objectName(), ToData(player)) then
						local damage = sgs.DamageStruct()
						damage.from = player
						damage.to = target
						damage.nature = sgs.DamageStruct_Fire
						damage.damage = 1
						room:damage(damage)
						if target:isAlive() then
							local sp = {}
							if not player:isSkipped(sgs.Player_Judge)
							then table.insert(sp,"Player_Judge") end
							if not player:isSkipped(sgs.Player_Draw)
							then table.insert(sp,"Player_Draw") end
							if not player:isSkipped(sgs.Player_Play)
							then table.insert(sp,"Player_Play") end
							if not player:isSkipped(sgs.Player_Discard)
							then table.insert(sp,"Player_Discard") end
							if not player:isSkipped(sgs.Player_Finish)
							then table.insert(sp,"Player_Finish") end
							if #sp<1 then return end
							sp = room:askForChoice(to,"ov_tanfeng",table.concat(sp,"+"),ToData(player))
							player:skip(sgs[sp])
						end
					end
				end
			end
		end
	end
}
heg_mobile_xiahoushang:addSkill(heg_mobile_tanfeng)

heg_ov_tianyu = sgs.General(extension_heg,  "heg_ov_tianyu", "wei", 3)

heg_ov_zhenxi = sgs.CreateTriggerSkill{
	name = "heg_ov_zhenxi",
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.from and use.from:objectName() == player:objectName() and use.card:isKindOf("Slash") then
			for _, to in sgs.qlist(use.to) do
				if room:askForSkillInvoke(player, self:objectName(), ToData(to)) then
					room:broadcastSkillInvoke(self:objectName())
					local choicelist = {}
					if player:canDiscard(to, "he") then
						table.insert(choicelist, "discard")
					end
					local acard = sgs.Sanguosha:cloneCard("indulgence", sgs.Card_NoSuitRed, 0)
					acard:deleteLater()
					acard:setSkillName(self:objectName())
					local bcard = sgs.Sanguosha:cloneCard("supply_shortage", sgs.Card_NoSuitBlack, 0)
					bcard:setSkillName(self:objectName())
					bcard:deleteLater()
					local suits = {}
					if not player:isProhibited(to, acard) and acard:targetFilter(sgs.PlayerList(), to, player) then
						table.insert(suits, "diamond")
					end
					if not player:isProhibited(to, bcard) and bcard:targetFilter(sgs.PlayerList(), to, player) then
						table.insert(suits, "club")
					end
					if #suits > 0 then
						table.insert(choicelist, "use")
					end
					table.insert(choicelist, "cancel")
					local choice = room:askForChoice(player, self:objectName(), table.concat(choicelist, "+"), ToData(to))
					if choice == "discard" then
						local id = room:askForCardChosen(player, to, "he", self:objectName())
						room:throwCard(id, to, player)
					elseif choice == "use" then
						local card = room:askForCard(player, "^TrickCard|"..table.concat(suits, ",").."|.|.", "@heg_ov_zhenxi", ToData(to), sgs.Card_MethodNone, nil, false, self:objectName(), false)
						if card then
							if card:isRed() then
								acard = sgs.Sanguosha:cloneCard("indulgence", card:getSuit(), card:getNumber())
							else
								acard = sgs.Sanguosha:cloneCard("supply_shortage", card:getSuit(), card:getNumber())
							end
							acard:setSkillName(self:objectName())
							acard:addSubcard(card)
							room:useCard(sgs.CardUseStruct(acard, player, to))
						end
					end
				end
			end
		end
		return false
	end,
}

heg_ov_jiansuCard = sgs.CreateSkillCard{
	name = "heg_ov_jiansu",
	will_throw = true,
	filter = function(self, targets, to_select)
		local x = self:subcardsLength()
		return #targets == 0 and to_select:getHp() <= x and to_select:isWounded()
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke(self:objectName())
		local recover = sgs.RecoverStruct()
		recover.who = source
		recover.recover = 1
		recover.reason = self:objectName()
		room:recover(targets[1], recover)
	end
}
heg_ov_jiansuVS = sgs.CreateViewAsSkill{
	name = "heg_ov_jiansu",
	n = 999,
	view_filter = function(self, selected, to_select)
		return to_select:hasTip("heg_ov_jiansu")
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = heg_ov_jiansuCard:clone()
		for _, c in ipairs(cards) do
			card:addSubcard(c)
		end
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@heg_ov_jiansu"
	end
}
heg_ov_jiansu = sgs.CreateTriggerSkill{
	name = "heg_ov_jiansu",
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	view_as_skill = heg_ov_jiansuVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			-- 全局触发器会自动处理清理，这里只处理新获得卡牌的明置
			if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand 
			and player:getPhase() == sgs.Player_NotActive then
				local ids = sgs.IntList()
				for _, id in sgs.qlist(move.card_ids) do
					ids:append(id)
				end
				if ids:isEmpty() then return false end
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:broadcastSkillInvoke(self:objectName())
					-- 使用技能名作为property_name和pile_name，全局触发器会自动清理
					UniversalCardDisplayMove(ids, true, player, self:objectName())
				end
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local has_marked = false
				for _, card in sgs.qlist(player:getHandcards()) do
					if card:hasTip(self:objectName()) then
						has_marked = true
						break
					end
				end
				if has_marked then
					room:askForUseCard(player, "@@heg_ov_jiansu", "@heg_ov_jiansu")
				end
			end
		end
		return false
	end
}

heg_ov_tianyu:addSkill(heg_ov_zhenxi)
heg_ov_tianyu:addSkill(heg_ov_jiansu)
    
heg_ov_liufuren = sgs.General(extension_heg,  "heg_ov_liufuren", "qun", 3, false)

heg_ov_zhuidu = sgs.CreateTriggerSkill{
	name = "heg_ov_zhuidu",
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to and damage.to:isAlive() and player:getMark(self:objectName().."-PlayClear") == 0 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:addPlayerMark(player, self:objectName().."-PlayClear", 1)
				local choicelist = { "damage" }
				if damage.to:canDiscard(damage.to, "e") then
					table.insert(choicelist, "discard")
				end
				local choice
				if damage.to:isFemale() and table.contains(choicelist, "discard") and player:canDiscard(player, "he") then
					if room:askForCard(player, ".", "@heg_ov_zhuidu-beishui", data, sgs.Card_MethodDiscard, nil, false, self:objectName(), false, nil) then
						choice = "beishui"
					end
				end
				if not choice then
					choice = room:askForChoice(damage.to, self:objectName(), table.concat(choicelist, "+"), data)
				end
			
				if choice == "damage" or choice == "beishui" then
					damage.damage = damage.damage + 1
					local log = sgs.LogMessage()
					log.type = "#skill_add_damage"
					log.from = damage.from
					log.to:append(damage.to)
					log.arg = self:objectName()
					log.arg2 = damage.damage
					room:sendLog(log)
					data:setValue(damage)
				end
				if choice == "discard" or choice == "beishui" then
					damage.to:throwAllEquips(self:objectName())
				end
				if choice == "beishui" then
					room:askForDiscard(player, self:objectName(), 1, 1)
				end
			end
		end
	end
}

-- 检测技能是否没有技能类型（如锁定技、主公技、觉醒技等）
-- 参考 fuckYoka2 函数的实现，检查所有已知的技能类型标识
function hasNoSkillType(skill)
	local desc = skill:getDescription()
	if not desc or desc == "" then return true end
	
	-- 检查常见的技能类型标识（参考fuckYoka2的模式以及extensions和lang中的实际使用）
	local skill_type_keywords = {
		"锁定技",
		"主公技",
		"觉醒技",
		"限定技",
		"持恒技",
		"转换技",
		"主将技",
		"副将技",
		"君主技",      -- 国战君主技能
		"萌战技",      -- 萌战相关技能
		"唤醒技",      -- 唤醒类型技能
		"使命技",      -- 使命类型技能
		"蓄力技",      -- 蓄力类型技能
		"联动技",      -- 联动技能
	}
	
	-- 对每个技能类型关键词进行检查
	for _, keyword in ipairs(skill_type_keywords) do
		-- 模式1: 直接以关键词开头
		local i, j = string.find(desc, keyword)
		if i and i == 1 then
			return false
		end
		
		-- 模式2: <标签><b>关键词
		i, j = string.find(desc, "<(.-)><b>" .. keyword)
		if i and i == 1 then
			return false
		end
		
		-- 模式3: <标签><b>XX</b></font><标签><b>关键词（处理复杂的HTML标签嵌套）
		i, j = string.find(desc, "<(.-)><b>(.-)</b></font><(.-)><b>" .. keyword)
		if i and i == 1 then
			return false
		end
		
		-- 模式4: <font color=...><b>关键词（处理带颜色的技能类型标记）
		i, j = string.find(desc, "<font (.-)><b>" .. keyword)
		if i and i == 1 then
			return false
		end
	end
	
	-- 没有找到任何技能类型标识，返回true（没有技能类型）
	return true
end

heg_ov_shigong = sgs.CreateTriggerSkill{
	name = "heg_ov_shigong",
	events = {sgs.EnterDying},
	limit_mark = "@heg_ov_shigong",
	frequency = sgs.Skill_Limited,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who and dying.who:objectName() == player:objectName() and player:getGeneral2() and player:getMark("@heg_ov_shigong") > 0 then
			local current = room:getCurrent()
			if not current or current:isDead() then return false end
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:removePlayerMark(player, "@heg_ov_shigong")
				room:broadcastSkillInvoke(self:objectName())
				log.type = "#YHXiandao2"
				log.arg = player:getGeneral2Name()
				log.from = player
				room:sendLog(log)
				room:changeHero(player, "", false, false, true, true)

				local choices = {}
				for _, skill in sgs.qlist(player:getGeneral2():getVisibleSkillList()) do
					if skill:isAttachedLordSkill() then
						continue
					end
					-- 使用新的函数检测没有技能类型的技能
					if hasNoSkillType(skill) and not player:hasSkill(skill:objectName()) then
						table.insert(choices, skill:objectName())
					end
				end
				if #choices > 0 then
					if room:askForSkillInvoke(current, "heg_ov_shigong_gain", ToData(player)) then
						local choice = room:askForChoice(current, self:objectName(), table.concat(choices, "+"), data)
						room:acquireSkill(current, choice)
						local recover = sgs.RecoverStruct()
						recover.who = player
						recover.reason = self:objectName()
						recover.recover = player:getMaxHp() - player:getHp()
						room:recover(player, recover)
					else
						local recover = sgs.RecoverStruct()
						recover.who = player
						recover.reason = self:objectName()
						recover.recover = 1 - player:getHp()
						room:recover(player, recover)
					end
				else
					local recover = sgs.RecoverStruct()
					recover.who = player
					recover.reason = self:objectName()
					recover.recover = 1 - player:getHp()
					room:recover(player, recover)
				end
			end
		end
		return false
	end
}
heg_ov_liufuren:addSkill(heg_ov_zhuidu)
heg_ov_liufuren:addSkill(heg_ov_shigong)

heg_tenyear_yanghu = sgs.General(extension_hegtenyear, "heg_tenyear_yanghu", "wei", 3)

heg_tenyear_dechao = sgs.CreateTriggerSkill{
	name = "heg_tenyear_dechao",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.to:length() == 1 and use.to:contains(player) and use.card:isBlack() and use.from and use.from:isAlive() and use.from:objectName() ~= player:objectName() and player:getMark("heg_tenyear_dechao-Clear") < player:getHp() and not use.card:isKindOf("SkillCard") then
			if player:canDiscard(use.from, "he") and player:askForSkillInvoke(self:objectName(), data) then
				room:addPlayerMark(player, "heg_tenyear_dechao-Clear")
				room:addPlayerMark(player, "&heg_tenyear_dechao-Clear")
				room:broadcastSkillInvoke(self:objectName())
				local id = room:askForCardChosen(player, use.from, "he", self:objectName())
				room:throwCard(id, use.from, player)
			end
		end
		return false
	end,
}

heg_tenyear_mingfaCard = sgs.CreateSkillCard{
	name = "heg_tenyear_mingfa",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local target = effect.to
		room:addPlayerMark(target, "heg_tenyear_mingfa+to+#"..effect.from:objectName().."-SelfClear", 1)
		room:addPlayerMark(target, "&heg_tenyear_mingfa+to+#"..effect.from:objectName().."-SelfClear", 1)
	end,
}
heg_tenyear_mingfaVS = sgs.CreateZeroCardViewAsSkill{
	name = "heg_tenyear_mingfa",
	view_as = function()
		return heg_tenyear_mingfaCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_tenyear_mingfa")
	end,
}
heg_tenyear_mingfa = sgs.CreateTriggerSkill{
	name = "heg_tenyear_mingfa",
	events = {sgs.EventPhaseChanging, sgs.EventLoseSkill},
	view_as_skill = heg_tenyear_mingfaVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player:getMark("heg_tenyear_mingfa+to+#"..p:objectName().."-SelfClear") > 0 then
						room:broadcastSkillInvoke(self:objectName())
						room:removePlayerMark(player, "heg_tenyear_mingfa+to+#"..p:objectName().."-SelfClear")
						if player:getHandcardNum() < p:getHandcardNum() then
							local damage = sgs.DamageStruct()
							damage.from = p
							damage.to = player
							damage.damage = 1
							room:damage(damage)
							if not player:isKongcheng() then
								local card_id = room:askForCardChosen(p, player, "h", self:objectName())
								local card = sgs.Sanguosha:getCard(card_id)
								p:obtainCard(card)
							end
						else
							local to_draw = math.min(5, player:getHandcardNum() - p:getHandcardNum())
							if to_draw > 0 then
								p:drawCards(to_draw, self:objectName())
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
	end,
}

heg_tenyear_yanghu:addSkill(heg_tenyear_dechao)
heg_tenyear_yanghu:addSkill(heg_tenyear_mingfa)

heg_tenyear_dengzhi = sgs.General(extension_hegtenyear, "heg_tenyear_dengzhi", "shu", 3)

heg_tenyear_jianliang = sgs.CreateTriggerSkill{
	name = "heg_tenyear_jianliang",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			local min_hand = 1000
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				local num = p:getHandcardNum()
				if num < min_hand then
					min_hand = num
				end
			end
			if player:getHandcardNum() == min_hand then
				local targets = room:askForPlayersChosen(player, room:getAlivePlayers(), self:objectName(), 0, 99, "@heg_tenyear_jianliang", true, true)
				room:sortByActionOrder(targets)
				if targets and targets:length() > 0 then
					room:broadcastSkillInvoke(self:objectName())
					for _, p in sgs.qlist(targets) do
						p:drawCards(1, self:objectName())
					end
				end
			end
		end
		return false
	end,
}

heg_tenyear_weimengCard = sgs.CreateSkillCard{
	name = "heg_tenyear_weimeng",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local x = math.min(source:getHp(), target:getHandcardNum())
		if x > 0 then
			room:broadcastSkillInvoke("heg_tenyear_weimeng")
			if source:getMark("heg_tenyear_weimeng") > 0 then
				x = 1
			end
			local to_obtain = dummyCard()
			local remove = sgs.IntList()--创建不可选卡牌id表
			for i = 1, x do--进行多次执行
				local id = room:askForCardChosen(source, target, "h", self:objectName(),
					false,--选择卡牌时手牌不可见
					sgs.Card_MethodNone,--设置为弃置类型
					remove,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
					i>1)--只有执行过一次选择才可取消
				if id < 0 then break end--如果卡牌id无效就结束多次执行
				remove:append(id)--将选择的id添加到虚拟卡的子卡表
				to_obtain:addSubcard(id)
			end
			if to_obtain:subcardsLength() > 0 then
				source:obtainCard(to_obtain)
				local to_give = room:askForExchange(source, self:objectName(), to_obtain:subcardsLength(), to_obtain:subcardsLength(), false, "@heg_tenyear_weimeng-give:"..target:objectName())
				if to_give then
					target:obtainCard(to_give)
				end
			end
			if source:getMark("heg_tenyear_weimeng") > 0 then
				room:handleAcquireDetachSkills(source, "-heg_tenyear_weimeng")
				room:setPlayerMark(source, "heg_tenyear_weimeng", 0)
			else
				if not target:hasSkill("heg_tenyear_weimeng") and room:askForSkillInvoke(source, self:objectName(), ToData(target)) then
					room:changeTranslation(target, "heg_tenyear_weimeng", 2)
					room:handleAcquireDetachSkills(target, "heg_tenyear_weimeng")
					room:setPlayerMark(target, "heg_tenyear_weimeng", 1)
				end
			end
		end
	end,
}
heg_tenyear_weimengVS = sgs.CreateZeroCardViewAsSkill{
	name = "heg_tenyear_weimeng",
	view_as = function()
		return heg_tenyear_weimengCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_tenyear_weimeng")
	end,
}
heg_tenyear_weimeng = sgs.CreateTriggerSkill{
	name = "heg_tenyear_weimeng",
	events = {sgs.EventPhaseChanging},
	view_as_skill = heg_tenyear_weimengVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:getMark("heg_tenyear_weimeng") > 0 then
						room:handleAcquireDetachSkills(p, "-heg_tenyear_weimeng")
						room:setPlayerMark(p, "heg_tenyear_weimeng", 0)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

heg_tenyear_dengzhi:addSkill(heg_tenyear_jianliang)
heg_tenyear_dengzhi:addSkill(heg_tenyear_weimeng)

heg_tenyear_zongyu = sgs.General(extension_hegtenyear, "heg_tenyear_zongyu", "shu", 3)

heg_tenyear_chengshang = sgs.CreateTriggerSkill{
	name = "heg_tenyear_chengshang",
	events = {sgs.CardFinished},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.from:objectName() ~= player:objectName() then return false end
		if use.to:isEmpty() then return false end
		if use.card:isKindOf("SkillCard") then return false end
		if use.card and not use.card:hasFlag("DamageDone") then
			if player:getMark("heg_tenyear_chengshang-PlayClear") > 0 then
				return false
			end
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:addPlayerMark(player, "heg_tenyear_chengshang-PlayClear")
				local to_obtain = dummyCard()
				for _, id in sgs.qlist(room:getDrawPile()) do
					local card = sgs.Sanguosha:getCard(id)
					if card:getSuit() == use.card:getSuit() and card:getNumber() == use.card:getNumber() then
						to_obtain:addSubcard(id)
					end
				end
				if to_obtain:subcardsLength() > 0 then
					room:broadcastSkillInvoke(self:objectName())
					player:obtainCard(to_obtain)
				else
					room:setPlayerMark(player, "heg_tenyear_chengshang-PlayClear", 0)
					room:sendCompulsoryTriggerLog(player, self:objectName())
				end
			end
		end
		return false
	end
}
heg_tenyear_zongyu:addSkill("heg_qiao")
heg_tenyear_zongyu:addSkill(heg_tenyear_chengshang)

heg_tenyear_fengxi = sgs.General(extension_hegtenyear, "heg_tenyear_fengxi", "wu", 3)

heg_tenyear_boyanCard = sgs.CreateSkillCard{
	name = "heg_tenyear_boyan",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and (to_select:getHandcardNum() < to_select:getMaxHp() or player:getMark("heg_tenyear_boyan") > 0)
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:broadcastSkillInvoke("heg_tenyear_boyan")
		if source:getMark("heg_tenyear_boyan") <= 0 then
			local max_hp = target:getMaxHp()
			local hand_num = target:getHandcardNum()
			if hand_num < max_hp then
				target:drawCards(max_hp - hand_num, "heg_tenyear_boyan")
			end
		end
		room:setPlayerCardLimitation(target, "use,response", ".|.|.|hand", true)
		room:addPlayerMark(target, "&heg_tenyear_boyan+to+#"..source:objectName().."-Clear", 1)
		if source:getMark("heg_tenyear_boyan") > 0 then
			room:handleAcquireDetachSkills(source, "-heg_tenyear_boyan")
			room:setPlayerMark(source, "heg_tenyear_boyan", 0)
		else
			if not target:hasSkill("heg_tenyear_boyan") and room:askForSkillInvoke(source, self:objectName(), ToData(target)) then
				room:changeTranslation(target, "heg_tenyear_boyan", 2)
				room:handleAcquireDetachSkills(target, "heg_tenyear_boyan")
				room:setPlayerMark(target, "heg_tenyear_boyan", 1)
			end
		end
	end,
}
heg_tenyear_boyanVS = sgs.CreateZeroCardViewAsSkill{
	name = "heg_tenyear_boyan",
	view_as = function()
		return heg_tenyear_boyanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_tenyear_boyan")
	end,
}
heg_tenyear_boyan = sgs.CreateTriggerSkill{
	name = "heg_tenyear_boyan",
	events = {sgs.EventPhaseChanging},
	view_as_skill = heg_tenyear_boyanVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:getMark("heg_tenyear_boyan") > 0 then
						room:handleAcquireDetachSkills(p, "-heg_tenyear_boyan")
						room:setPlayerMark(p, "heg_tenyear_boyan", 0)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

heg_tenyear_fengxi:addSkill("yusui")
heg_tenyear_fengxi:addSkill(heg_tenyear_boyan)

heg_tenyear_miheng = sgs.General(extension_hegtenyear, "heg_tenyear_miheng", "qun", 3)

heg_tenyear_kuangcai_buff = sgs.CreateTargetModSkill{
	name = "#heg_tenyear_kuangcai_buff",
	distance_limit_func = function(self, from, card)
        if from:hasSkill(self:objectName()) and from:getPhase() ~= sgs.Player_NotActive then
            return 1000
        end
        return 0
    end,
	residue_func = function(self, from, card)
        if from:hasSkill(self:objectName()) and from:getPhase() ~= sgs.Player_NotActive then
            return 1000
        end
        return 0
    end,
}
heg_tenyear_kuangcai = sgs.CreateTriggerSkill{
	name = "heg_tenyear_kuangcai",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Discard then
			local room = player:getRoom()
			if player:getMark("used-Clear") > 0 then
				if player:getMark("damage_record-Clear") <= 0 then
					room:addMaxCards(player, -1, true)
				end
			else
				room:addMaxCards(player, 1, true)
			end
		end
	end
}
heg_tenyear_shejian = sgs.CreateTriggerSkill{
	name = "heg_tenyear_shejian",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.to:length() == 1 and use.to:contains(player) and use.from and use.from:isAlive() and use.from:objectName() ~= player:objectName() and player:canDiscard(player, "h") and not use.card:isKindOf("SkillCard") then
			local choicelist = {}
			if room:getCurrentDyingPlayer() == nil then
				table.insert(choicelist, "damage="..use.from:objectName())
			end
			if player:canDiscard(use.from, "he") then
				table.insert(choicelist, "discard="..use.from:objectName())
			end
			if #choicelist > 0 and player:askForSkillInvoke(self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				local choice = room:askForChoice(player, self:objectName(), table.concat(choicelist, "+"), data)
				local x = player:getHandcardNum()
				player:throwAllHandCards(self:objectName())
				if string.startsWith(choice, "damage") then
					local damage = sgs.DamageStruct()
					damage.from = player
					damage.to = use.from
					damage.damage = 1
					room:damage(damage)
				else
					local to_obtain = dummyCard()
					local max = math.min(x, use.from:getCardCount(true))
					local remove = sgs.IntList()--创建不可选卡牌id表
					for i = 1, max do--进行多次执行
						local id = room:askForCardChosen(player, use.from, "he", self:objectName(),
							false,--选择卡牌时手牌不可见
							sgs.Card_MethodDiscard,--设置为弃置类型
							remove,--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
							i>1)--只有执行过一次选择才可取消
						if id < 0 then break end--如果卡牌id无效就结束多次执行
						remove:append(id)--将选择的id添加到虚拟卡的子卡表
						to_obtain:addSubcard(id)
					end
					if to_obtain:subcardsLength() > 0 then
						room:throwCard(to_obtain, use.from, player)
					end
				end
			end
		end
	end
}

heg_tenyear_miheng:addSkill(heg_tenyear_kuangcai_buff)
heg_tenyear_miheng:addSkill(heg_tenyear_kuangcai)
extension_hegtenyear:insertRelatedSkills("heg_tenyear_kuangcai", "#heg_tenyear_kuangcai_buff")
heg_tenyear_miheng:addSkill(heg_tenyear_shejian)

heg_tenyear_xunchen = sgs.General(extension_hegtenyear, "heg_tenyear_xunchen", "qun", 3)

heg_tenyear_fenglueCard = sgs.CreateSkillCard{
	name = "heg_tenyear_fenglue",
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:objectName() ~= player:objectName() and player:canPindian(to_select)
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:broadcastSkillInvoke("heg_tenyear_fenglue")
		local success = source:pindian(target, "heg_tenyear_fenglue")
		local zongheng = source:getMark("heg_tenyear_fenglue") > 0
		
		if success then
			-- Source wins
			local get_count = zongheng and 1 or 2
			if not target:isNude() then
				local to_obtain = dummyCard()
				local remove = sgs.IntList()
				for i = 1, get_count do
					local id = room:askForCardChosen(source, target, "he", self:objectName(), false, sgs.Card_MethodNone, remove, i > 1)
					if id < 0 then break end
					remove:append(id)
					to_obtain:addSubcard(id)
				end
				if to_obtain:subcardsLength() > 0 then
					source:obtainCard(to_obtain)
				end
			end
		else
			-- Target wins
			local give_count = zongheng and 2 or 1
			if not source:isNude() then
				local to_give = dummyCard()
				local remove = sgs.IntList()
				for i = 1, give_count do
					local id = room:askForCardChosen(source, source, "he", self:objectName(), false, sgs.Card_MethodNone, remove, i > 1)
					if id < 0 then break end
					remove:append(id)
					to_give:addSubcard(id)
				end
				if to_give:subcardsLength() > 0 then
					target:obtainCard(to_give)
				end
			end
		end
		
		-- Handle zongheng transfer
		if zongheng then
			room:handleAcquireDetachSkills(source, "-heg_tenyear_fenglue")
			room:setPlayerMark(source, "heg_tenyear_fenglue", 0)
		else
			if not target:hasSkill("heg_tenyear_fenglue") and room:askForSkillInvoke(source, self:objectName(), ToData(target)) then
				room:changeTranslation(target, "heg_tenyear_fenglue", 2)
				room:handleAcquireDetachSkills(target, "heg_tenyear_fenglue")
				room:setPlayerMark(target, "heg_tenyear_fenglue", 1)
			end
		end
	end,
}

heg_tenyear_fenglueVS = sgs.CreateZeroCardViewAsSkill{
	name = "heg_tenyear_fenglue",
	view_as = function()
		return heg_tenyear_fenglueCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_tenyear_fenglue")
	end,
}
heg_tenyear_fenglue = sgs.CreateTriggerSkill{
	name = "heg_tenyear_fenglue",
	events = {sgs.EventPhaseChanging},
	view_as_skill = heg_tenyear_fenglueVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:getMark("heg_tenyear_fenglue") > 0 then
						room:handleAcquireDetachSkills(p, "-heg_tenyear_fenglue")
						room:setPlayerMark(p, "heg_tenyear_fenglue", 0)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}



heg_tenyear_anyong = sgs.CreateTriggerSkill{
	name = "heg_tenyear_anyong",
	events = {sgs.DamageCaused},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and damage.to and damage.from:objectName() ~= damage.to:objectName()  then
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if damage.to:objectName() ~= p:objectName()	and p:getMark("heg_tenyear_anyong-Clear") == 0 then
					if room:askForSkillInvoke(p, self:objectName(), data) then
						room:addPlayerMark(p, "heg_tenyear_anyong-Clear")
						room:broadcastSkillInvoke("heg_tenyear_anyong")
						damage.damage = damage.damage * 2
						data:setValue(damage)
						
						local choices = {"losehp="..p:objectName()}
						-- Can choose to make anyong player discard 2 cards if they have at least 2 hand cards
						if p:getHandcardNum() >= 2 and p:canDiscard(p, "h") then
							table.insert(choices, "discard="..p:objectName())
						end
						
						table.insert(choices, "cancel")
						local choice = room:askForChoice(damage.to, "heg_tenyear_anyong", table.concat(choices, "+"), ToData(p))
						
						if string.startsWith(choice, "losehp") then
							room:loseHp(p, 1, true, damage.to, self:objectName())
							room:handleAcquireDetachSkills(p, "-heg_tenyear_anyong")
						elseif string.startsWith(choice, "discard") then
							room:askForDiscard(p, "heg_tenyear_anyong", 2, 2, false, false)
						end
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

heg_tenyear_xunchen:addSkill(heg_tenyear_fenglue)
heg_tenyear_xunchen:addSkill(heg_tenyear_anyong)


heg_tenyear_nanhualaoxian = sgs.General(extension_hegtenyear, "heg_tenyear_nanhualaoxian", "qun", 3)

heg_tenyear_nanhualaoxian:addSkill("heg_gongxiu")
heg_tenyear_nanhualaoxian:addSkill("jinghe")


heg_tenyear_lukang = sgs.General(extension_hegtenyear,  "heg_tenyear_lukang", "wu", 4)

heg_tenyear_zhuwei = sgs.CreateTriggerSkill{
	name = "heg_tenyear_zhuwei",
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local card = judge.card
		local card_data = sgs.QVariant()
		card_data:setValue(card)
		if room:getCardPlace(card:getEffectiveId()) == sgs.Player_PlaceJudge and (card:isKindOf("Slash") or (card:isDamageCard() and card:isKindOf("TrickCard"))) and player:askForSkillInvoke(self:objectName(), card_data) then
			player:obtainCard(card)
			local current = room:getCurrent()
			if current and current:isAlive() and player:askForSkillInvoke(self:objectName(), ToData(current)) then
				room:broadcastSkillInvoke(self:objectName())
				room:addSlashCishu(current, 1, true)
				room:addMaxCards(current, 1, true)
				room:addPlayerMark(current, "&heg_mobile_zhuwei+to+#"..player:objectName().."-Clear", 1)
			end
		end
		return false
	end
}

heg_tenyear_lukang:addSkill("heg_keshou")
heg_tenyear_lukang:addSkill(heg_tenyear_zhuwei)

heg_fk_zhanglu = sgs.General(extension_heg,  "heg_fk_zhanglu", "qun+wei", 3)
heg_fk_bushi_record = sgs.CreateTriggerSkill{
  	name = "#heg_fk_bushi_record",
  	events = { sgs.Damaged, sgs.Damage },
  	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:addPlayerMark(player, "heg_fk_bushi_damage-Clear")
		return false
	end,
}
heg_fk_bushiCard = sgs.CreateSkillCard{
	name = "heg_fk_bushi",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < player:getMaxHp()
	end,
	on_use = function(self, room, source, targets)
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
		room:throwCard(self, reason, nil)
		for _, target in ipairs(targets) do
			target:drawCards(1, "heg_fk_bushi")
			if not target:isKongcheng() then
				local card = room:askForCard(target, ".", "@heg_fk_bushi-put:"..source:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
				if card then
					local splayer = sgs.SPlayerList()
					splayer:append(source)
					source:addToPile("heg_fk_rice", card:getEffectiveId(), false, splayer)
				end
			end
		end
	end,
}
heg_fk_bushiVS = sgs.CreateOneCardViewAsSkill {
	name = "heg_fk_bushi",
	filter_pattern = ".|.|.|heg_fk_rice",
	response_pattern = "@@heg_fk_bushi",
	view_as = function(slef, card)
		local slash = heg_fk_bushiCard:clone()
		slash:addSubcard(card)
		return slash
	end,
}

heg_fk_bushi = sgs.CreateTriggerSkill{
  	name = "heg_fk_bushi",
  	events = { sgs.EventPhaseProceeding },
	view_as_skill = heg_fk_bushiVS,
  	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if not p:getPile("heg_fk_rice"):isEmpty() and p:getMark("heg_fk_bushi_damage-Clear") > 0 then
					room:askForUseCard(p, "@@heg_fk_bushi", "@heg_fk_bushi")
				end
			end
		end
	end
}

heg_fk_midao = sgs.CreateTriggerSkill{
  	name = "heg_fk_midao",
  	events = { sgs.GameStart, sgs.AskForRetrial },
  	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:hasSkill(self:objectName()) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(2, self:objectName())
				if not player:isKongcheng() then
					local card = room:askForExchange(player, self:objectName(), 2, 2, true, "@heg_fk_midao", false)
					local ids = sgs.IntList()
					for _, id in sgs.qlist(card:getSubcards()) do
						ids:append(id)
					end
					local splayer = sgs.SPlayerList()
					splayer:append(player)
					player:addToPile("heg_fk_rice", ids, false, splayer)
				end
			end
		elseif event == sgs.AskForRetrial then
			local judge = data:toJudge()
			if judge.who:objectName() ~= player:objectName() and player:hasSkill(self:objectName()) and not player:getPile("heg_fk_rice"):isEmpty() then
				local prompt_list = {
					"@heg_fk_midao-card" ,
					judge.who:objectName() ,
					self:objectName() ,
					judge.reason ,
					tostring(judge.card:getEffectiveId())
				}
				local prompt = table.concat(prompt_list, ":")
				player:setTag("judgeData", data)
				local card = room:askForCard(player, ".|.|.|heg_fk_rice", prompt, data, sgs.Card_MethodResponse, judge.who, true)
				player:removeTag("judgeData")
				if card then
					room:broadcastSkillInvoke(self:objectName())
					room:retrial(card, player, judge, self:objectName(), true)
				end
			end
		end
		return false
	end,
}
heg_fk_zhanglu:addSkill(heg_fk_bushi_record)
heg_fk_zhanglu:addSkill(heg_fk_bushi)
heg_fk_zhanglu:addSkill(heg_fk_midao)
extension:insertRelatedSkills("heg_fk_bushi","#heg_fk_bushi_record")

heg_true_xushu = sgs.General(extension_heg,  "heg_true_xushu", "shu", 3)

heg_true_zhuhai = sgs.CreateTriggerSkill{
  	name = "heg_true_zhuhai",
  	events = { sgs.EventPhaseStart },
  	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player:getMark("damage_point_turn-Clear") > 0 then
					room:askForUseSlashTo(p, player, "@heg_true_zhuhai:"..player:objectName(), false, false, false, nil, nil, "heg_true_zhuhai")
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

heg_true_pozhen = sgs.CreateTriggerSkill{
  	name = "heg_true_pozhen",
	frequency = sgs.Skill_Limited,
	limit_mark = "@heg_true_pozhen",
  	events = { sgs.EventPhaseStart },
  	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_RoundStart then
				for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if p:getMark("@heg_true_pozhen") > 0 and p:objectName() ~= player:objectName() and room:askForSkillInvoke(p, self:objectName()) then
						room:removePlayerMark(p, "@heg_true_pozhen")
						room:setPlayerCardLimitation(player, "use,respond", ".|.|.|hand", true)
						if IsEncircled(player) then
							for _, q in sgs.list(GetEncirclers(player)) do
								if p:canDiscard(q, "he") then
									local id = room:askForCardChosen(p, q, "he", self:objectName())
									room:throwCard(id, q, p)
								end
							end
						end
						if IsInQueue(player) then
							for _, q in sgs.list(GetQueueMembers(player)) do
								if p:canDiscard(q, "he") then
									local id = room:askForCardChosen(p, q, "he", self:objectName())
									room:throwCard(id, q, p)
								end
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

heg_true_jiancai = sgs.CreateTriggerSkill{
  	name = "heg_true_jiancai",
	frequency = sgs.Skill_Limited,
	limit_mark = "@heg_true_jiancai",
  	events = { sgs.DamageInflicted },
  	on_trigger = function(self, event, player, data, room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.damage < damage.to:getHp() + damage.to:getHujia() then return false end
			for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if p:getMark("@heg_true_jiancai") > 0 and room:askForSkillInvoke(p, self:objectName(), data) then
					room:removePlayerMark(p, "@heg_true_jiancai")
					local old_kingdom = p:getKingdom()
					ChangeGeneral(room, p, "heg_true_xushu", old_kingdom)
					damage.prevented = true
					data:setValue(damage)
					return true
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

heg_true_xushu:addSkill(heg_true_zhuhai)
heg_true_xushu:addSkill(heg_true_pozhen)
heg_true_xushu:addSkill(heg_true_jiancai)


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
 --[[
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

]]

heg_lord_liubei = sgs.General(extension_heg,  "heg_lord_liubei", "shu", 4)


--专属武器：飞龙夺凤
DragonPhoenix = sgs.CreateWeapon{
	name = "DragonPhoenix",
	class_name = "DragonPhoenix",
	range = 2,
	suit = sgs.Card_Spade,
	number = 2,
	on_install = function(self, player)
		local room = player:getRoom()
        local skill = sgs.Sanguosha:getSkill("DragonPhoenix_skill")
        if skill then
            if skill:inherits("ViewAsSkill") then
                room:attachSkillToPlayer(player, "DragonPhoenix_skill")
            elseif skill:inherits("TriggerSkill") then
                local tirggerskill = sgs.Sanguosha:getTriggerSkill("DragonPhoenix_skill")
                room:getThread():addTriggerSkill(tirggerskill)
            end
        end
        local skill2 = sgs.Sanguosha:getSkill("DragonPhoenix_2_skill")
        if skill2 then
            if skill2:inherits("ViewAsSkill") then
                room:attachSkillToPlayer(player, "DragonPhoenix_2_skill")
            elseif skill2:inherits("TriggerSkill") then
                local tirggerskill = sgs.Sanguosha:getTriggerSkill("DragonPhoenix_2_skill")
                room:getThread():addTriggerSkill(tirggerskill)
            end
        end
	end,
	on_uninstall = function(self, player)
	end,
}
--
DragonPhoenix_skill = sgs.CreateTriggerSkill{
	name = "DragonPhoenix_skill",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecified},
	on_trigger = function(self, event, player, data, room)
	    if event == sgs.TargetSpecified then
		    local use = data:toCardUse()
		    if use.from:objectName() == player:objectName() and not use.to:contains(player)  then
			    if use.card:isKindOf("Slash") then
					for _, p in sgs.qlist(use.to) do
						if player:canDiscard(p, "he") and room:askForSkillInvoke(player, "DragonPhoenix", ToData(p)) then
						    room:askForDiscard(p, self:objectName(), 1, 1, false, true, "@dragonphoenix-discard")
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:hasWeapon("DragonPhoenix")
	end,
}
DragonPhoenix_2_skill = sgs.CreateTriggerSkill{
	name = "DragonPhoenix_2_skill",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EnterDying},
	on_trigger = function(self, event, player, data, room)
	    if event == sgs.EnterDying then
		    local dying = data:toDying()
		    if dying and dying.damage and dying.damage.from and dying.damage.card and dying.damage.card:isKindOf("Slash") and dying.damage.from:hasWeapon("DragonPhoenix") then
				if not player:isNude() and room:askForSkillInvoke(dying.damage.from, "DragonPhoenix", ToData(player)) then
					local to_obtain = room:askForCardChosen(dying.damage.from, player, "he", self:objectName())
					room:obtainCard(dying.damage.from, to_obtain, false)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}

if not sgs.Sanguosha:getSkill("DragonPhoenix_skill") then skills:append(DragonPhoenix_skill) end
if not sgs.Sanguosha:getSkill("DragonPhoenix_2_skill") then skills:append(DragonPhoenix_2_skill) end


DragonPhoenix:setParent(extension_heg)

heg_lord_zhangwu = sgs.CreateTriggerSkill{
	name = "heg_lord_zhangwu",
	frequency = sgs.Skill_Compulsory,
	waked_skills = "DragonPhoenix",
	events = {sgs.CardsMoveOneTime, sgs.BeforeCardsMove},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and not player:hasFlag("heg_lord_zhangwu") then
			    if (move.from_places:contains(sgs.Player_PlaceEquip) or (move.from_places:contains(sgs.Player_PlaceHand) and move.to_place ~= sgs.Player_PlaceEquip and move.to_place ~= sgs.Player_PlaceTable)) then
				    if move.from:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
					    for _, id in sgs.qlist(move.card_ids) do
						    local card = sgs.Sanguosha:getCard(id)
						    if card:isKindOf("DragonPhoenix") and (room:getCardPlace(id) == sgs.Player_PlaceEquip or room:getCardPlace(id) == sgs.Player_PlaceHand) then
								local ids = sgs.IntList()
								ids:append(id)
								move:removeCardIds(ids)
								data:setValue(move)
			                    room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
								room:setPlayerFlag(player, "heg_lord_zhangwu")
							    room:moveCardsInToDrawpile(player, id, self:objectName(), room:getDrawPile():length())
								room:showCard(player, id)
							    player:drawCards(2)
								room:setPlayerFlag(player, "-heg_lord_zhangwu")
								break
							end
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if ((move.to_place == sgs.Player_PlaceEquip and move.to and move.to:objectName() ~= player:objectName()) or move.to_place == sgs.Player_DiscardPile ) then			    
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("DragonPhoenix") then
						for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
							if not (move.to_place == sgs.Player_PlaceEquip and move.to and move.to:objectName() == player:objectName()) then
								room:sendCompulsoryTriggerLog(p, self:objectName(), true, true)
								room:obtainCard(p, card, false)
								break
							end
						end
					end
				end
			end
		end
	end,
}

heg_lord_shouyue_wusheng = sgs.CreateViewAsSkill{
	name = "heg_lord_shouyue_wusheng&",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local slash = sgs.Sanguosha:cloneCard("slash", cards[1]:getSuit(), cards[1]:getNumber())
		slash:addSubcard(cards[1])
		for _,sk in sgs.list(sgs.Self:getVisibleSkillList())do
			if sk:isAttachedLordSkill() then continue end
			if string.find(sk:objectName(), "wusheng") then
				slash:setSkillName(sk:objectName())
				break
			end
		end
		return slash
	end,
	enabled_at_play = function(self, player)
		local can_invoke = false
		local have_liubei = false
		for _,sk in sgs.list(player:getVisibleSkillList())do
			if sk:isAttachedLordSkill() then continue end
			if string.find(sk:objectName(), "wusheng") then
				can_invoke = true
				break
			end
		end
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:hasSkill("heg_lord_shouyue") then
				have_liubei = true
				break
			end
		end
		return can_invoke and have_liubei and sgs.Slash_IsAvailable(player) and player:getKingdom() == "shu"
	end,
	enabled_at_response = function(self, player, pattern)
		for _,pn in ipairs(pattern:split("+")) do
			local dc = dummyCard(pn)
			if dc and dc:isKindOf("Slash") then
				local can_invoke = false
				local have_liubei = false
				for _,sk in sgs.list(player:getVisibleSkillList())do
					if sk:isAttachedLordSkill() then continue end
					if string.find(sk:objectName(), "wusheng") then
						can_invoke = true
						break
					end
				end
				for _, p in sgs.qlist(player:getAliveSiblings()) do
					if p:hasSkill("heg_lord_shouyue") then
						have_liubei = true
						break
					end
				end
				return can_invoke and have_liubei and player:getKingdom() == "shu"
			end
		end
	end,
}

heg_lord_shouyue_liegong = sgs.CreateAttackRangeSkill{
	name = "heg_lord_shouyue_liegong&",
	extra_func = function(self, player)
		local n = 0
		for _,sk in sgs.list(player:getVisibleSkillList())do
			if sk:isAttachedLordSkill() then continue end
			if string.find(sk:objectName(), "liegong") then
				n = n + 1
			end
		end
		if n > 0 and player:getKingdom() == "shu" then
			for _, p in sgs.qlist(player:getAliveSiblings()) do
				if p:hasSkill("heg_lord_shouyue") then
					return n
				end
			end
		end
		return 0
	end,
}

heg_lord_shouyue = sgs.CreateTriggerSkill{
	name = "heg_lord_shouyue",
	events = {sgs.GameStart, sgs.EventAcquireSkill, sgs.PreCardUsed, sgs.CardUsed, sgs.CardResponded, sgs.StartJudge },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName())) then
			if player:hasSkill(self:objectName()) then
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					room:attachSkillToPlayer(p, "heg_lord_shouyue_wusheng&")
					room:attachSkillToPlayer(p, "heg_lord_shouyue_liegong&")
				end
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				local can_invoke = false
				for _,sk in sgs.list(player:getVisibleSkillList())do
					if sk:isAttachedLordSkill() then continue end
					if string.find(sk:objectName(), "paoxiao") then
						can_invoke = true
						break
					end
				end
				if can_invoke and player:getKingdom() == "shu" then
					for _, p in sgs.qlist(player:getAlivePlayers()) do
						if p:hasSkill("heg_lord_shouyue") then
							room:sendCompulsoryTriggerLog(p, self:objectName(), true, true)
							room:broadcastSkillInvoke(self:objectName())
							use.card:setFlags("SlashIgnoreArmor")
							break
						end
					end
				end
			end
		elseif event == sgs.CardUsed or event == sgs.CardResponded then
			local card
			if event == sgs.CardUsed then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			if card and table.contains(card:getSkillNames(), "longdan") and player:getKingdom() == "shu" then
				for _, p in sgs.qlist(player:getAlivePlayers()) do
					if p:hasSkill("heg_lord_shouyue") then
						room:sendCompulsoryTriggerLog(p, self:objectName(), true, true)
						room:broadcastSkillInvoke(self:objectName())
						player:drawCards(1, self:objectName())
						break
					end
				end
			end
		elseif event == sgs.StartJudge then
			local judge = data:toJudge()
			if judge.who:getKingdom() ~= "shu" then return false end
			local can_invoke = false
			for _,sk in sgs.list(judge.who:getVisibleSkillList())do
				if sk:isAttachedLordSkill() then continue end
				if string.find(sk:objectName(), "tieji") then
					can_invoke = true
					break
				end
			end
			if can_invoke then
				for _, p in sgs.qlist(judge.who:getAlivePlayers()) do
					if p:hasSkill("heg_lord_shouyue") then
						room:sendCompulsoryTriggerLog(p, self:objectName(), true, true)
						room:broadcastSkillInvoke(self:objectName())
						judge.pattern = ".|^spade"
						data:setValue(judge)
						break
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

heg_lord_jizhao = sgs.CreateTriggerSkill{
	name = "heg_lord_jizhao",
	frequency = sgs.Skill_Limited,
	events = {sgs.AskForPeaches},
	waked_skills = "tenyearrende",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() == player:objectName() and player:getMark(self:objectName().."_used") == 0 then
			if room:askForSkillInvoke(player, self:objectName(), data) then
				room:doSuperLightbox(player, "heg_lord_jizhao")
				room:broadcastSkillInvoke(self:objectName())
				if player:getHandcardNum() < player:getMaxHp() then
					player:drawCards(player:getMaxHp() - player:getHandcardNum())
				end
				room:detachSkillFromPlayer(player, "heg_lord_shouyue")
				room:recover(player, sgs.RecoverStruct(player, nil, 2 - player:getHp(), self:objectName()))
				room:acquireSkill(player, "tenyearrende")
				room:addPlayerMark(player, self:objectName().."_used")
			end
		end
	end,
}

heg_lord_liubei:addSkill(heg_lord_zhangwu)
heg_lord_liubei:addSkill(heg_lord_shouyue)
heg_lord_liubei:addSkill(heg_lord_jizhao)
if not sgs.Sanguosha:getSkill("heg_lord_shouyue_wusheng&") then skills:append(heg_lord_shouyue_wusheng) end
if not sgs.Sanguosha:getSkill("heg_lord_shouyue_liegong&") then skills:append(heg_lord_shouyue_liegong) end

heg_lord_zhangjiao = sgs.General(extension_heg,  "heg_lord_zhangjiao", "qun", 4)

PeaceSpell_Skill = sgs.CreateTriggerSkill{
	name = "PeaceSpell_Skill",
	events = { sgs.DamageInflicted },
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasArmorEffect("PeaceSpell")
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.nature == sgs.DamageStruct_Normal then return end
			local log = sgs.LogMessage()
			log.type = "#PeaceSpellNatureDamage"
			log.from = damage.to
			room:sendLog(log)
			room:setEmotion(damage.to, "/excard2014/PeaceSpell")
			damage.prevented = true
			data:setValue(damage)
			return true
		end
	end
}

PeaceSpell_MaxCardSkill = sgs.CreateMaxCardsSkill{
	name = "PeaceSpell_MaxCardSkill",
	extra_func = function(self, player)
		local players = player:getAliveSiblings()
		players:append(player)
		local extra = 0
		for _, p1 in sgs.qlist(players) do
			if p1:hasArmorEffect("PeaceSpell") and player:getKingdom() == p1:getKingdom() then
				for _, p2 in sgs.qlist(players) do
					if p1:getKingdom() == p2:getKingdom() then extra = extra + 1 end
				end
			end
		end
		if player:hasSkill("heg_lord_hongfa") then
			extra = extra + player:getPile("heg_lord_hongfa"):length()
		end
		if player:hasArmorEffect("PeaceSpell") then
			return extra
		end
		return 0
	end,
}

PeaceSpell = sgs.CreateArmor{
	name = "PeaceSpell",
	class_name = "PeaceSpell",
	suit = sgs.Card_Heart,
	number = 3,
	equip_skill = PeaceSpell_Skill,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("PeaceSpell_Skill")
		if skill then room:getThread():addTriggerSkill(skill) end
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		if player:getHp() > 1 then
			room:sendCompulsoryTriggerLog(player, "PeaceSpell", true, true)
			room:loseHp(player, 1, true, player, "PeaceSpell")
			if player:isAlive() then
				player:drawCards(2, self:objectName())
			end
		end
	end,
}

PeaceSpell:setParent(extension_heg)

if not sgs.Sanguosha:getSkill("PeaceSpell_MaxCardSkill") then skills:append(PeaceSpell_MaxCardSkill) end

heg_lord_hongfa_Attach = sgs.CreateOneCardViewAsSkill{
	name = "heg_lord_hongfa_Attach&",
	filter_pattern = ".|.|.|heg_lord_hongfa",
	expand_pile = "%heg_lord_hongfa,heg_lord_hongfa",
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card)
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		local can_invoke = false
		for _, p in sgs.qlist(player:getAliveSiblings(true)) do
			if p:hasSkill("heg_lord_hongfa") and p:getKingdom() == player:getKingdom() then
				can_invoke = true
				break
			end
		end
		return sgs.Slash_IsAvailable(player) and can_invoke
	end,
	enabled_at_response = function(self, player, pattern)
		for _,pn in ipairs(pattern:split("+")) do
			local dc = dummyCard(pn)
			if dc and dc:isKindOf("Slash") then
				local can_invoke = false
				for _, p in sgs.qlist(player:getAliveSiblings(true)) do
					if p:hasSkill("heg_lord_hongfa") and p:getKingdom() == player:getKingdom() then
						can_invoke = true
						break
					end
				end
				return can_invoke
			end
		end
		return false
	end,
}


heg_lord_hongfa = sgs.CreateTriggerSkill{
	name = "heg_lord_hongfa",
	events = { sgs.EventPhaseProceeding, sgs.PreHpLost, sgs.GameStart, sgs.EventAcquireSkill },
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseProceeding then
			if player:getPhase() == sgs.Player_Start then
				local room = player:getRoom()
				if player:hasSkill(self:objectName()) and player:getPile("heg_lord_hongfa"):isEmpty() then
					room:broadcastSkillInvoke(self:objectName())
					local x = 0
					for _, p in sgs.qlist(room:getAlivePlayers()) do
						if p:getKingdom() == "qun" then
							x = x + 1
						end
					end
					local ids = room:getNCards(x)
					player:addToPile("heg_lord_hongfa", ids)
				end
			end
		elseif event == sgs.PreHpLost then
			local lost = data:toHpLost()
			if lost.to:objectName() == player:objectName() and player:hasSkill(self:objectName()) and not player:getPile("heg_lord_hongfa"):isEmpty() and room:askForSkillInvoke(player, self:objectName()) then
				local room = player:getRoom()
				room:broadcastSkillInvoke(self:objectName())
				room:fillAG(player:getPile("heg_lord_hongfa"), player)
				local id = room:askForAG(player, player:getPile("heg_lord_hongfa"), false, self:objectName())
				room:clearAG(player)
				if id ~= -1 then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), "")
					local card = sgs.Sanguosha:getCard(id)
					room:throwCard(card, reason, nil)
					return true
				end
				
			end
		elseif (event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == self:objectName())) then
			if player:hasSkill(self:objectName()) then
				local room = player:getRoom()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					p:setSkillDescriptionSwap("heg_lord_hongfa_Attach", "%arg1", player:getKingdom())
					room:changeTranslation(p, "heg_lord_hongfa_Attach", 2)
					room:attachSkillToPlayer(p, "heg_lord_hongfa_Attach")
				end
			end
		end
		return false
	end,
}

heg_lord_wuxin = sgs.CreateTriggerSkill{
  	name = "heg_lord_wuxin",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseStart },
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Draw then
			local room = player:getRoom()
			local x = 0
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getKingdom() == "qun" then
					x = x + 1
				end
			end
			if player:hasSkill("heg_lord_hongfa") then
				x = x + player:getPile("heg_lord_hongfa"):length()
			end
			if x > 0 and room:askForSkillInvoke(player, self:objectName()) then
				room:broadcastSkillInvoke(self:objectName())
				room:askForGuanxing(player, room:getNCards(x, false), sgs.Room_GuanxingUpOnly)
			end
		end
		return false
	end,
}

heg_lord_wendaoCard = sgs.CreateSkillCard{
	name = "heg_lord_wendao",
	will_throw = true,
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local to_get
		for _, id in sgs.qlist(room:getDiscardPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf("PeaceSpell") then
				to_get = sgs.Sanguosha:getCard(id)
				break
			end
		end
		if not to_get then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				for _, c in sgs.qlist(p:getCards("ej")) do
					if c:isKindOf("PeaceSpell") then
						to_get = c
						break
					end
				end
				if to_get then break end
			end
		end
		if to_get then
			room:obtainCard(source, to_get, false)
		end
	end,
}
heg_lord_wendao = sgs.CreateOneCardViewAsSkill{
  	name = "heg_lord_wendao",
	filter_pattern = "red",
	waked_skills = "PeaceSpell",
	view_as = function(self, card)
		local skill_card = heg_lord_wendaoCard:clone()
		skill_card:addSubcard(card)
		return skill_card
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_lord_wendao")
	end,
}


heg_lord_zhangjiao:addSkill(heg_lord_hongfa)
heg_lord_zhangjiao:addSkill(heg_lord_wuxin)
heg_lord_zhangjiao:addSkill(heg_lord_wendao)
if not sgs.Sanguosha:getSkill("heg_lord_hongfa_Attach&") then skills:append(heg_lord_hongfa_Attach) end

-- heg_lord_sunquan
heg_lord_sunquan = sgs.General(extension_heg, "heg_lord_sunquan", "wu", 4)

-- LuminousPearl Treasure
LuminousPearl = sgs.CreateTreasure{
	name = "LuminousPearl",
	class_name = "LuminousPearl",
	suit = sgs.Card_Diamond,
	number = 6,
	on_install = function(self, player)
		local room = player:getRoom()
        if not player:hasSkill("heg_zhiheng") then
			room:acquireSkill(player, "heg_zhiheng", true, true, true)
		elseif player:getMark("LuminousPearl_zhiheng") == 0 then
			room:setPlayerMark(player, "LuminousPearl_zhiheng", 1)
		end
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		if player:getMark("LuminousPearl_zhiheng") == 0 then
			room:detachSkillFromPlayer(player, "heg_zhiheng", true, false)
		end
		room:setPlayerMark(player, "LuminousPearl_zhiheng", 0)
	end,
}

LuminousPearl:setParent(extension_heg)

-- heg_zhiheng
heg_zhihengCard = sgs.CreateSkillCard{
	name = "heg_zhiheng",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("heg_zhiheng")
		local count = self:subcardsLength()
		if source:isAlive() then
			room:drawCards(source, count, "heg_zhiheng")
		end
	end
}

heg_zhiheng = sgs.CreateViewAsSkill{
	name = "heg_zhiheng",
	n = 999,
	view_filter = function(self, selected, to_select)
		if sgs.Self:getMark("LuminousPearl_zhiheng") > 0 then
			return true
		end
		return #selected < sgs.Self:getMaxHp()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = heg_zhihengCard:clone()
			for _, c in pairs(cards) do
				card:addSubcard(c)
			end
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_zhiheng")
	end
}

heg_lord_jiahe_buff = sgs.CreateTriggerSkill{
	name = "#heg_lord_jiahe_buff",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.EventAcquireSkill},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == "heg_lord_jiahe") then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				room:attachSkillToPlayer(p, "heg_lord_jiahe_Attach")
			end
		end
	end
}

heg_lord_jiahe = sgs.CreateTriggerSkill{
	name = "heg_lord_jiahe",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.EventPhaseProceeding},
	waked_skills = "yingzi,haoshi,shelie,heg_duoshi",
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseProceeding then
			if player:getPhase() == sgs.Player_Start and player:getKingdom() == "wu" then
				for _, sunquan in sgs.qlist(room:findPlayersBySkillName("heg_lord_jiahe")) do
					if sunquan and sunquan:getPile("heg_lord_jiahe"):length() > 0 and room:askForSkillInvoke(player, "heg_lord_jiahe", ToData(sunquan)) then
						local fenghuo_count = sunquan:getPile("heg_lord_jiahe"):length()
						local choices = {}
						if fenghuo_count >= 1 and not player:hasSkill("yingzi") then table.insert(choices, "yingzi") end
						if fenghuo_count >= 2 and not player:hasSkill("haoshi") then table.insert(choices, "haoshi") end
						if fenghuo_count >= 3 and not player:hasSkill("shelie") then table.insert(choices, "shelie") end
						if fenghuo_count >= 4 and not player:hasSkill("heg_duoshi") then table.insert(choices, "heg_duoshi") end
						if fenghuo_count >= 5 then
							local choice1 = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
							room:acquireOneTurnSkills(player, "heg_lord_jiahe" ,choice1)
							table.removeOne(choices, choice1)
							local choice2 = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
							room:acquireOneTurnSkills(player, "heg_lord_jiahe" ,choice2)
						elseif #choices > 0 then
							local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
							room:acquireOneTurnSkills(player, "heg_lord_jiahe" ,choice)
						end
					end
				end
			end
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.to and damage.to:hasSkill(self:objectName()) and player:objectName() == damage.to:objectName() then
				if damage.card and (damage.card:isKindOf("Slash") or damage.card:isNDTrick()) then
					local fenghuo = damage.to:getPile("heg_lord_jiahe")
					if not fenghuo:isEmpty() then
						room:fillAG(fenghuo, damage.to)
						local card_id = room:askForAG(damage.to, fenghuo, false, self:objectName())
						room:clearAG(damage.to)
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "","heg_lord_jiahe", "")
                        local card = sgs.Sanguosha:getCard(card_id)
                        room:throwCard(card, reason, nil)
						room:sendCompulsoryTriggerLog(damage.to, self:objectName(), true, true)
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}

heg_lord_jiahe_AttachCard = sgs.CreateSkillCard{
	name = "heg_lord_jiahe_Attach",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets == 0 and to_select:hasSkill("heg_lord_jiahe") and to_select:getMark("heg_lord_jiahe-PlayClear") == 0
	end,
	on_use = function(self, room, source, targets)
		local sunquan = targets[1]
		if sunquan then
			sunquan:addToPile("heg_lord_jiahe", self)
			room:addPlayerMark(sunquan, "heg_lord_jiahe-PlayClear")
		end
	end
}

heg_lord_jiahe_Attach = sgs.CreateViewAsSkill{
	name = "heg_lord_jiahe_Attach&",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = heg_lord_jiahe_AttachCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:getKingdom() ~= "wu" then return false end
		local sunquan = nil
		for _, p in sgs.qlist(player:getAliveSiblings(true)) do
			if p:hasSkill("heg_lord_jiahe") and p:getMark("heg_lord_jiahe-PlayClear") == 0 then
				sunquan = p
				break
			end
		end
		return sunquan
	end
}



heg_lord_lianziCard = sgs.CreateSkillCard{
	name = "heg_lord_lianzi",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("heg_lord_lianzi")
		local discard_card = sgs.Sanguosha:getCard(self:getSubcards():first())
		local type_name = ""
		if discard_card:isKindOf("BasicCard") then
			type_name = "BasicCard"
		elseif discard_card:isKindOf("TrickCard") then
			type_name = "TrickCard"
		elseif discard_card:isKindOf("EquipCard") then
			type_name = "EquipCard"
		end
		
		local wu_equip_count = 0
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:getKingdom() == "wu" then
				wu_equip_count = wu_equip_count + p:getEquips():length()
			end
		end
		
		local fenghuo_count = 0
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasSkill("heg_lord_jiahe") then
				fenghuo_count = p:getPile("heg_lord_jiahe"):length()
				break
			end
		end
		
		local x = wu_equip_count + fenghuo_count
		local ids = room:showDrawPile(source, x, self:objectName(), true, true)
		local card_to_gotback = sgs.IntList()
		for _, id in sgs.qlist(ids) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf(type_name) then
				card_to_gotback:append(id)
			end
		end
		
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		dummy:deleteLater()
		if not card_to_gotback:isEmpty() then
			for _, id in sgs.qlist(card_to_gotback) do
				dummy:addSubcard(id)
			end
			room:obtainCard(source, dummy, false)
		end
		
		if card_to_gotback:length() > 3 and source:hasSkill("heg_lord_lianzi") then
			room:detachSkillFromPlayer(source, "heg_lord_lianzi", false, false)
			room:acquireSkill(source, "heg_zhiheng", true, true, true)
		end
	end
}

heg_lord_lianzi = sgs.CreateViewAsSkill{
	name = "heg_lord_lianzi",
	n = 1,
	waked_skills = "heg_zhiheng",
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = heg_lord_lianziCard:clone()
			card:addSubcard(cards[1])
			card:setSkillName(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_lord_lianzi")
	end
}

-- heg_lord_jubao
heg_lord_jubao = sgs.CreateTriggerSkill{
	name = "heg_lord_jubao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseProceeding},
	waked_skills = "LuminousPearl",
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.from:hasSkill(self:objectName()) then
				if move.from_places:contains(sgs.Player_PlaceEquip) then
					for _, id in sgs.qlist(move.card_ids) do
						local card = sgs.Sanguosha:getCard(id)
						if card:isKindOf("Treasure") and move.to and move.to:objectName() ~= player:objectName() then
							local ids = sgs.IntList()
							ids:append(id)
							move:removeCardIds(ids)
							room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
							data:setValue(move)
						end
					end
				end
			end
		elseif event == sgs.EventPhaseProceeding then
			if player:getPhase() == sgs.Player_Finish and player:hasSkill(self:objectName()) then
				local has_pearl = false
				local pearl_owner = nil
				
				for _, p in sgs.qlist(room:getAllPlayers()) do
					if p:getTreasure() and p:hasTreasure("LuminousPearl") then
						has_pearl = true
						pearl_owner = p
						break
					end
				end
				
				if not has_pearl then
					for _, id in sgs.qlist(room:getDiscardPile()) do
						local card = sgs.Sanguosha:getCard(id)
						if card:isKindOf("LuminousPearl") then
							has_pearl = true
							break
						end
					end
				end
				
				if has_pearl then
					room:sendCompulsoryTriggerLog(player, self:objectName(), true, true)
					player:drawCards(1, self:objectName())
					if pearl_owner and pearl_owner:objectName() ~= player:objectName() and not pearl_owner:isNude() then
						local card_id = room:askForCardChosen(player, pearl_owner, "he", self:objectName())
						room:obtainCard(player, card_id, false)
					end
				end
			end
		end
		return false
	end,
}

heg_lord_sunquan:addSkill(heg_lord_jiahe_buff)
heg_lord_sunquan:addSkill(heg_lord_jiahe)
extension_heg:insertRelatedSkills("heg_lord_jiahe", "#heg_lord_jiahe_buff")
heg_lord_sunquan:addSkill(heg_lord_lianzi)
heg_lord_sunquan:addSkill(heg_lord_jubao)

if not sgs.Sanguosha:getSkill("heg_zhiheng") then skills:append(heg_zhiheng) end
if not sgs.Sanguosha:getSkill("heg_lord_jiahe_Attach") then skills:append(heg_lord_jiahe_Attach) end

-- heg_lord_caocao
heg_lord_caocao = sgs.General(extension_heg, "heg_lord_caocao", "wei", 4)

-- SixDragons Horse (六龙骖驾)
SixDragons_Skill = sgs.CreateTriggerSkill{
	name = "#SixDragons_Skill",
	events = {sgs.BeforeCardsMove},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self,target)
		return target and target:hasDefensiveHorse("SixDragons")
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.BeforeCardsMove then
	     	local move = data:toMoveOneTime()
			if move.to and player:objectName()==move.to:objectName() and move.reason.m_skillName=="yj_zhengyu" then
				local ids = {}
				for _,id in sgs.list(move.card_ids)do
					if player:getTag("PresentCard"):toString()==tostring(id) and sgs.Sanguosha:getCard(id):isKindOf("Horse")
					then table.insert(ids,id) end
				end
				if #ids>0 then
					room:sendCompulsoryTriggerLog(player,"SixDragons",true)
					local tos = sgs.SPlayerList()
					if move.from then tos:append(BeMan(room,move.from)) end
					Log_message("$yj_zhanxiang",player,tos,table.concat(ids,"+"))
					move.reason.m_skillName = "yj_zhengyu_fail"
					move.to_place = sgs.Player_DiscardPile
					move.to = nil
					data:setValue(move)
				end
 	       	end
		end
		return false
	end
}
SixDragons_2_Skill = sgs.CreateTriggerSkill{
	name = "#SixDragons_2_Skill",
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self,target)
		return target 
	end,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and player:objectName()==move.from:objectName() and move.from_places:contains(sgs.Player_PlaceEquip) then
				local ids = sgs.IntList()
				for _,id in sgs.list(move.card_ids)do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("SixDragons") then
						ids:append(id)
					end
				end
				if not ids:isEmpty() then
					player:obtainEquipArea(2)
				end
			end
			if move.to and player:objectName()==move.to:objectName() and move.to_place==sgs.Player_PlaceEquip then
				local ids = sgs.IntList()
				for _,id in sgs.list(move.card_ids)do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("SixDragons") then
						ids:append(id)
					end
				end
				if not ids:isEmpty() then
					player:throwEquipArea(2)
				end
			end
		end
		return false
	end
}

SixDragons_DistanceSkill = sgs.CreateDistanceSkill{
	name = "SixDragons_Distance",
	correct_func = function(self, from, to)
		if to:hasOffensiveHorse("SixDragons") then
			return 1
		end
		return 0
	end
}

SixDragons_ProhibitSkill = sgs.CreateProhibitSkill{
	name = "SixDragons_Prohibit",
	is_prohibited = function(self, from, to, card)
		if to:hasOffensiveHorse("SixDragons") then
			if card:isKindOf("OffensiveHorse") or card:isKindOf("DefensiveHorse") then
				return true
			end
		end
		return false
	end
}

SixDragons = sgs.CreateOffensiveHorse{
	name = "SixDragons",
	class_name = "SixDragons",
	suit = sgs.Card_Heart,
	number = 13,
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,SixDragons_Skill,true,true,false)
		room:acquireSkill(player,SixDragons_2_Skill,true,true,false)
		return false
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,"SixDragons_Skill",true,true)
		room:detachSkillFromPlayer(player,"SixDragons_2_Skill",true,true)
	end,
}

SixDragons:setParent(extension_heg)

if not sgs.Sanguosha:getSkill("#SixDragons_Skill") then skills:append(SixDragons_Skill) end
if not sgs.Sanguosha:getSkill("#SixDragons_2_Skill") then skills:append(SixDragons_2_Skill) end
if not sgs.Sanguosha:getSkill("SixDragons_Distance") then skills:append(SixDragons_DistanceSkill) end
if not sgs.Sanguosha:getSkill("SixDragons_Prohibit") then skills:append(SixDragons_ProhibitSkill) end

-- heg_lord_jianan (Lord skill with Five Elite Generals Banner)
local function heg_lord_jianan_cleanup(room, lord_name)
	for _, p in sgs.qlist(room:getAllPlayers()) do
		for _, skill in sgs.list(p:getVisibleSkillList()) do
			local skill_name = skill:objectName()
			if p:getMark("heg_lord_jianan_" .. lord_name .. "_" .. skill_name) > 0 then
				room:detachSkillFromPlayer(p, skill_name, true, false)
				room:setPlayerMark(p, "heg_lord_jianan_" .. lord_name .. "_" .. skill_name, 0)
			end
		end
		-- Restore disabled skill
		if p:getMark("heg_lord_jianan_disabled_" .. lord_name) > 0 then
			local disabled_skill = room:getTag("heg_lord_jianan_disabled_" .. lord_name .. "_" .. p:objectName()):toString()
			if disabled_skill ~= "" then
				room:removePlayerMark(p, "Qingcheng"..disabled_skill)
			end
			room:setPlayerMark(p, "heg_lord_jianan_disabled_" .. lord_name, 0)
			room:setTag("heg_lord_jianan_disabled_" .. lord_name .. "_" .. p:objectName(), sgs.QVariant(""))
		end
	end
end

heg_lord_jianan_clear = sgs.CreateTriggerSkill{
	name = "#heg_lord_jianan_clear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventLoseSkill, sgs.Death},
	on_trigger = function(self, event, player, data, room)
		if (event == sgs.EventLoseSkill and data:toString() == "heg_lord_jianan") or
		   (event == sgs.Death and data:toDeath().who and data:toDeath().who:hasSkill("heg_lord_jianan")) then
			heg_lord_jianan_cleanup(room, player:objectName())
		end
		return false
	end,
}

heg_lord_jianan = sgs.CreateTriggerSkill{
	name = "heg_lord_jianan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseProceeding, sgs.EventPhaseStart},
	waked_skills = "tenyeartuxi,qiaobian,xiaoguo,heg_jieyue,heg_duanliang",
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Start then
			if player:getKingdom() == "wei" then
				for _, caocao in sgs.qlist(room:findPlayersBySkillName("heg_lord_jianan")) do
					local lord_name = caocao:objectName()
					local choices = {}
					local all_skills = {"tenyeartuxi", "qiaobian", "xiaoguo", "heg_jieyue", "heg_duanliang"}
					for _, skill in ipairs(all_skills) do
						local has_skill = false
						for _, p in sgs.qlist(room:getAllPlayers()) do
							if p:hasSkill(skill) then
								has_skill = true
								break
							end
						end
						if not has_skill then
							table.insert(choices, skill)
						end
					end
					if #choices > 0 and player:canDiscard(player, "he") and room:askForDiscard(player, self:objectName(), 1, 1, true, true, "@heg_lord_jianan-discard") then
						local player_skills = {}
						for _, skill in sgs.list(player:getVisibleSkillList()) do
							local skill_name = skill:objectName()
							if skill and skill:isAttachedLordSkill() then continue end
							if not skill_name:startsWith("#") and not skill_name:endsWith("&") and skill:getFrequency() ~= sgs.Skill_Wake and skill:getFrequency() ~= sgs.Skill_Limited then
								table.insert(player_skills, skill_name)
							end
						end
						if #player_skills > 0 then
							local to_disable = room:askForChoice(player, self:objectName(), table.concat(player_skills, "+"))
							ChoiceLog(player, to_disable)
							room:setPlayerMark(player, "heg_lord_jianan_disabled_" .. lord_name, 1)
							room:setTag("heg_lord_jianan_disabled_" .. lord_name .. "_" .. player:objectName(), sgs.QVariant(to_disable))
							room:addPlayerMark(player, "Qingcheng"..to_disable, 1)
						end
						local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
						local skill_name = choice
						room:acquireSkill(player, skill_name, true, true, true)
						room:setPlayerMark(player, "heg_lord_jianan_" .. lord_name .. "_" .. skill_name, 1)
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			if player:hasSkill("heg_lord_jianan") then
				heg_lord_jianan_cleanup(room, player:objectName())
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end
}

-- heg_lord_huibian
heg_lord_huibianCard = sgs.CreateSkillCard{
	name = "heg_lord_huibian",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:getKingdom() == "wei" 
		elseif #targets == 1 then
			return to_select:getKingdom() == "wei" and to_select:isWounded() and to_select:objectName() ~= targets[1]:objectName()
		end
		return false
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("heg_lord_huibian")
		local damage = sgs.DamageStruct()
		damage.from = source
		damage.to = targets[1]
		damage.damage = 1
		damage.reason = "heg_lord_huibian"
		room:damage(damage)
		if targets[1]:isAlive() then
			targets[1]:drawCards(2, "heg_lord_huibian")
		end
		if targets[2]:isAlive() and targets[2]:isWounded() then
			room:recover(targets[2], sgs.RecoverStruct(source, nil, 1, "heg_lord_huibian"))
		end
	end
}

heg_lord_huibian = sgs.CreateZeroCardViewAsSkill{
	name = "heg_lord_huibian",
	view_as = function(self)
		return heg_lord_huibianCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_lord_huibian")
	end
}

-- heg_lord_zongyu
heg_lord_zongyu = sgs.CreateTriggerSkill{
	name = "heg_lord_zongyu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime, sgs.CardFinished},
	waked_skills = "SixDragons",
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to and move.to:objectName() ~= player:objectName() and move.to_place == sgs.Player_PlaceEquip then
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("SixDragons") and player:hasSkill(self:objectName()) then
						local has_horse = false
						if player:getOffensiveHorse() or player:getDefensiveHorse() then
							has_horse = true
						end
						if has_horse and room:askForSkillInvoke(player, self:objectName(), data) then
							local to_exchange = sgs.IntList()
							if player:getOffensiveHorse() then
								to_exchange:append(player:getOffensiveHorse():getEffectiveId())
							end
							if player:getDefensiveHorse() then
								to_exchange:append(player:getDefensiveHorse():getEffectiveId())
							end
							if move.to:isAlive() then
								room:findPlayerByObjectName(move.to:objectName()):obtainEquipArea(2)
								
								-- 第一步：将双方卡牌移动到place_table
								local move_to_table1 = sgs.CardsMoveStruct()
								move_to_table1.card_ids = sgs.IntList()
								move_to_table1.card_ids:append(id)
								move_to_table1.to_place = sgs.Player_PlaceTable
								move_to_table1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), self:objectName(), "")
								
								local move_to_table2 = sgs.CardsMoveStruct()
								move_to_table2.card_ids = to_exchange
								move_to_table2.to_place = sgs.Player_PlaceTable
								move_to_table2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), self:objectName(), "")
								
								local moves_to_table = sgs.CardsMoveList()
								moves_to_table:append(move_to_table1)
								moves_to_table:append(move_to_table2)
								room:moveCardsAtomic(moves_to_table, true)
								
								-- 第二步：从place_table移动到各自的装备区
								local move1 = sgs.CardsMoveStruct()
								move1.card_ids = sgs.IntList()
								move1.card_ids:append(id)
								move1.to = player
								move1.to_place = sgs.Player_PlaceEquip
								move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), self:objectName(), "")
								
								local move2 = sgs.CardsMoveStruct()
								move2.card_ids = to_exchange
								move2.to = move.to
								move2.to_place = sgs.Player_PlaceEquip
								move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, player:objectName(), self:objectName(), "")
								
								local moves = sgs.CardsMoveList()
								moves:append(move1)
								moves:append(move2)
								room:moveCardsAtomic(moves, true)
							end
						end
					end
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Horse") then
				local has_sixdragons = false
				local sixdragons_id = -1
				-- Check on field
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getOffensiveHorse() and p:getOffensiveHorse():isKindOf("SixDragons") then
						has_sixdragons = true
						sixdragons_id = p:getOffensiveHorse():getEffectiveId()
						break
					end
					if p:getDefensiveHorse() and p:getDefensiveHorse():isKindOf("SixDragons") then
						has_sixdragons = true
						sixdragons_id = p:getDefensiveHorse():getEffectiveId()
						break
					end
				end
				-- Check in discard pile
				if not has_sixdragons then
					for _, id in sgs.qlist(room:getDiscardPile()) do
						local card = sgs.Sanguosha:getCard(id)
						if card:isKindOf("SixDragons") then
							has_sixdragons = true
							sixdragons_id = id
							break
						end
					end
				end
				if has_sixdragons then
					local sixdragons = sgs.Sanguosha:getCard(sixdragons_id)
					if sixdragons then
						if player:getOffensiveHorse() then
							local ids = sgs.IntList()
                            ids:append(player:getOffensiveHorse():getId())
                            local move2 = sgs.CardsMoveStruct()
                            move2.card_ids = ids
                            move2.to = nil
                            move2.to_place = sgs.Player_DiscardPile
                            move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP, player:objectName())
                            room:moveCardsAtomic(move2, true)
						end
						room:moveCardTo(sixdragons, player, sgs.Player_PlaceEquip, true)
					end
				end
			end
		end
		return false
	end,
}

heg_lord_caocao:addSkill(heg_lord_jianan)
heg_lord_caocao:addSkill(heg_lord_jianan_clear)
heg_lord_caocao:addSkill(heg_lord_huibian)
heg_lord_caocao:addSkill(heg_lord_zongyu)
extension_heg:insertRelatedSkills("heg_lord_jianan", "#heg_lord_jianan_clear")

-- heg_lord_simayi
heg_lord_simayi = sgs.General(extension_heg, "heg_lord_simayi", "jin", 3)

-- Scaly Wings weapon card
scaly_wings_prohibit = sgs.CreateCardLimitSkill {
	name = "scaly_wings_prohibit",
	limit_list = function(self, player)
		return "use"
    end,
	limit_pattern = function(self, player, card)
		if player:hasFlag("scaly_wings_prohibit") then
			return "."
		else
			return ""
		end
	end
}

scaly_wings_skill = sgs.CreateTriggerSkill{
	name = "scaly_wings_skill",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardFinished, sgs.HpChanged, sgs.MaxHpChanged},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardUsed or event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:hasWeapon("scaly_wings") then
				if event == sgs.CardUsed then
					for _, p in sgs.qlist(room:getOtherPlayers(player)) do
						if not use.to:contains(p) and player:inMyAttackRange(p) then
							room:setCardFlag(use.card, self:objectName())
							room:setPlayerFlag(p, "scaly_wings_prohibit")
						end
					end
				elseif event == sgs.CardFinished then
					if use.card:hasFlag(self:objectName()) then
						for _, p in sgs.qlist(room:getAllPlayers()) do
							if p:hasFlag("scaly_wings_prohibit") then
								room:setPlayerFlag(p, "-scaly_wings_prohibit")
							end
						end
					end
				end
			end
		else
			if player:hasWeapon("scaly_wings") then
				room:notifyWeaponRange("scaly_wings", player:getLostHp())
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end
}

scaly_wings = sgs.CreateWeapon{
	name = "scaly_wings",
	class_name = "scaly_wings",
	range = 0, -- Will be calculated dynamically
	suit = sgs.Card_Diamond,
	number = 1,
	equip_skill = scaly_wings_skill,
	on_install = function(self, player)
		local room = player:getRoom()
		room:acquireSkill(player, "scaly_wings_prohibit", false, true, false)
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "scaly_wings_prohibit", true, true)
	end,
}

scaly_wings:setParent(extension_heg)

if not sgs.Sanguosha:getSkill("scaly_wings_prohibit") then skills:append(scaly_wings_prohibit) end

heg_jiaping_AttachCard = sgs.CreateSkillCard{
	name = "heg_jiaping_Attach",
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasSkill("heg_jiaping") and to_select:getMark("heg_jiaping_lun") == 0
	end,
	on_use = function(self, room, source, targets)
		local lord = targets[1]
		if lord then
			room:setPlayerMark(lord, "heg_jiaping_lun", 1)
			local skills = {"heg_shunfu", "heg_fengying", "heg_jianglve", "heg_yongjin", "luanwu"}
			local available = {}
			for _, skill in ipairs(skills) do
				if room:getTag("heg_jiaping_used_" .. skill):toInt() == 0 then
					table.insert(available, skill)
				end
			end
			if #available > 0 and player:getGeneral2() and player:getGeneral2Name() ~= "" then
				local choice = room:askForChoice(player, self:objectName(), table.concat(available, "+"))
				room:acquireOneTurnSkills(player, "heg_jiaping", choice)
				room:setTag("heg_jiaping_used_" .. choice, sgs.QVariant(1))
			end
		end
	end
}

heg_jiaping_Attach = sgs.CreateViewAsSkill{
	name = "heg_jiaping_Attach&",
	n = 0,
	view_as = function(self, cards)
		return heg_jiaping_AttachCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_jiaping_Attach") and player:getKingdom() == "jin" and player:getGeneral2()
	end
}

-- heg_jiaping (Lord skill)
heg_jiaping = sgs.CreateTriggerSkill{
	name = "heg_jiaping",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart, sgs.EventAcquireSkill},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.GameStart or event == sgs.EventAcquireSkill and data:toString() == self:objectName() then
			for _, p in sgs.qlist(room:getAllPlayers()) do
				room:attachSkillToPlayer(p, "heg_jiaping_Attach")
			end
		end
		return false
	end,
}

heg_guikuangCard = sgs.CreateSkillCard{
	name = "heg_guikuang",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return true
		elseif #targets == 1 then
			return to_select:getKingdom() ~= targets[1]:getKingdom()
		end
	end,
	feasible = function(self, targets)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local pd = targets[1]:PinDian(targets[2], self:objectName())
		local both = false
		local loser = targets[1]
		if pd.from_number~=pd.to_number then
			loser = targets[1]
			if pd.success then loser = targets[2] end
		else
			both = true
		end
		if pd.from_card:isRed() then
			if both then
				for _, p in ipairs(targets) do
					local damage = sgs.DamageStruct()
					damage.from = targets[1]
					damage.to = p
					damage.damage = 1
					damage.reason = "heg_guikuang"
					room:damage(damage)
				end
			else
				local damage = sgs.DamageStruct()
				damage.from = targets[1]
				damage.to = loser
				damage.damage = 1
				damage.reason = "heg_guikuang"
				room:damage(damage)
			end
		end
        if pd.to_card:isRed() then
			if both then
				for _, p in ipairs(targets) do
					local damage = sgs.DamageStruct()
					damage.from = targets[2]
					damage.to = p
					damage.damage = 1
					damage.reason = "heg_guikuang"
					room:damage(damage)
				end
			else
				local damage = sgs.DamageStruct()
				damage.from = targets[2]
				damage.to = loser
				damage.damage = 1
				damage.reason = "heg_guikuang"
				room:damage(damage)
			end
		end
	end
}

heg_guikuang = sgs.CreateZeroCardViewAsSkill{
	name = "heg_guikuang",
	view_as = function(self)
		return heg_guikuangCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#heg_guikuang")
	end
}



-- heg_shujuan
heg_shujuan = sgs.CreateTriggerSkill{
	name = "heg_shujuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data, room)
		local move = data:toMoveOneTime()
		if move.to_place == sgs.Player_DiscardPile or (move.to and move.to_place == sgs.Player_PlaceEquip and move.to:objectName() ~= player:objectName()) then
			for _, id in sgs.qlist(move.card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("scaly_wings") and player:getMark("heg_shujuan-Clear") == 0 then
					room:setPlayerMark(player, "heg_shujuan-Clear", 1)
					room:obtainCard(player, id, false)
					if not player:isCardLimited(card, sgs.Card_MethodUse) then
						room:useCard(sgs.CardUseStruct(card, player, player))
					end
					break
				end
			end
		end
		return false
	end,
}



heg_lord_simayi:addSkill(heg_jiaping)
heg_lord_simayi:addSkill(heg_guikuang)
heg_lord_simayi:addSkill(heg_shujuan)


heg_known_both = sgs.CreateTrickCard{
	name = "heg_known_both",
	class_name = "heg_known_both",
	suit = 1,
	number = 1,
	target_fixed = false,
	can_recast = true,
	subtype = "single_target_trick",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	available = function(self,player)
    	for _,to in sgs.list(player:getAliveSiblings())do
			if CanToCard(self,player,to)
			then
				return self:cardIsAvailable(player)
			end
		end
    end,
	filter = function(self,targets,to_select,source)
		if source:isCardLimited(self,sgs.Card_MethodUse) then return #targets<1 end
		local total_num = 1
		if sgs.Self then
			total_num = total_num + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, player, self)
		end
		return not to_select:isKongcheng() and to_select:objectName() ~= source:objectName() and #targets < total_num and not source:isProhibited(to_select,self)
	end,
	feasible = function(self,targets,from)
		if from:isCardLimited(self,sgs.Card_MethodUse) then return #targets<1 end
		return #targets >= 0
	end,
	is_cancelable = function(self, effect)
		return true
	end,
	about_to_use = function(self, room, use)
		if use.to:isEmpty() then
			UseCardRecast(use.from, self, "heg_known_both")
		else
			self:cardOnUse(room, use)
		end
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:showAllCards(effect.to, effect.from)
		local log = sgs.LogMessage()
		log.type = "#heg_showhandcards"
		log.from = effect.from
		log.to:append(effect.to)
		room:sendLog(log)
		effect.from:drawCards(1, self:objectName())
	end,
}
local zjzb = heg_known_both:clone(1, 3)
zjzb:setParent(extension_hegcard)
local zjzb = heg_known_both:clone(1, 4)
zjzb:setParent(extension_hegcard)

heg_befriend_attacking = sgs.CreateTrickCard{
	name = "heg_befriend_attacking",
	class_name = "heg_befriend_attacking",
	suit = 2,
	number = 9,
	target_fixed = false,
	can_recast = false,
	subtype = "single_target_trick",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	filter = function(self, targets, to_select, player)
		local total_num = 1
		if sgs.Self then
			total_num = total_num + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, player, self)
		end
		return to_select:objectName() ~= player:objectName() and #targets < total_num and not player:isProhibited(to_select,self)
	end,
	feasible = function(self, targets)
		local total_num = 1
		if sgs.Self then
			total_num = total_num + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, self)
		end
		return #targets <= total_num and #targets > 0
	end,
	available = function(self, player)
		return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
	end,
	is_cancelable = function(self, effect)
		return true
	end,
	on_effect = function(self, effect)
		effect.to:drawCards(1)
		effect.from:drawCards(3)
	end,
}

heg_befriend_attacking:setParent(extension_hegcard)

heg_await_exhausted = sgs.CreateTrickCard{
	name = "heg_await_exhausted",
	class_name = "heg_await_exhausted",
	suit = 2,
	number = 9,
	target_fixed = false,
	can_recast = false,
	subtype = "multiple_target_trick",
	subclass = sgs.LuaTrickCard_LuaTrickCard_TypeNormal,
	available = function(self,player)
    	for _,to in sgs.list(player:getAliveSiblings())do
			if CanToCard(self,player,to)
			then
				return self:cardIsAvailable(player)
			end
		end
    end,
	filter = function(self,targets,to_select,source)
		if source:isProhibited(to_select,self) then return end
		return true
	end,
	feasible = function(self,targets,from)
		return #targets>0
	end,
	is_cancelable = function(self, effect)
		return true
	end,
	on_use = function(self, room, source, targets)
		for _, t in ipairs(targets) do
			room:cardEffect(self, source, t)
		end
		for _, t in ipairs(targets) do
			if t:hasFlag("EXCard_YYDL_effected") and t:canDiscard(t, "he") then
				local num = math.min(t:getCardCount(), 2)
				room:askForDiscard(t, self:objectName(), num, num, false, true)
			end
		end
		if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), "", self:getSkillName(), "")
			room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, reason, true)
		end
	end,
	on_effect = function(self, effect)
		effect.to:drawCards(2)
		effect.to:setFlags("EXCard_YYDL_effected")
	end,
}

local yydl = heg_await_exhausted:clone(3, 4)
yydl:setParent(extension_hegcard)
local yydl = heg_await_exhausted:clone(2, 11)
yydl:setParent(extension_hegcard)

heg_triblade_Skill = sgs.CreateTriggerSkill{
	name = "heg_triblade_Skill",
	events = { sgs.Damage },
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasWeapon("heg_triblade")
	end,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local room = player:getRoom()
		if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.from:objectName() == player:objectName()
			and not player:isKongcheng() and not damage.chain and not damage.transfer and damage.by_user then
			if room:askForDiscard(player, self:objectName(), 1, 1, true, false, "#heg_triblade_Skill_dis") then
				local targets = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(damage.to)) do
					if damage.to:distanceTo(p) == 1 then targets:append(p) end
				end
				if targets:isEmpty() then return end
				local sb = room:askForPlayerChosen(player, targets, self:objectName(), "#heg_triblade_Skill_chosen", true)
				if sb then
					room:setEmotion(player, "/excard2014/EXCard_SJLRD")
					room:damage(sgs.DamageStruct(self:objectName(), player, sb))
				end
			end
		end
	end
}

heg_triblade = sgs.CreateWeapon{
	name = "heg_triblade",
	class_name = "heg_triblade",
	suit = sgs.Card_Diamond,
	number = 12,
	range = 3,
	equip_skill = heg_triblade_Skill,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("heg_triblade_Skill")
		if skill then room:getThread():addTriggerSkill(skill) end
	end,
	on_uninstall = function(self, player)
	end,
}

heg_triblade:setParent(extension_hegcard)

heg_six_swordsCard = sgs.CreateSkillCard{
	name = "heg_six_swords",
	filter = function(self, targets, to_select)
		return true
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			p:loseAllMarks("@heg_six_swords")
		end
		for _, p in ipairs(targets) do
			p:gainMark("@heg_six_swords")
			room:setEmotion(p, "/excard2014/EXCard_WLJ")
		end
	end
}
heg_six_swords_Skill = sgs.CreateViewAsSkill{
	name = "heg_six_swords",
	view_as = function(self, cards)
		return heg_six_swordsCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:hasWeapon("heg_six_swords")
	end,
}
heg_six_swords_buff = sgs.CreateTargetModSkill{
	name = "heg_six_swords_buff",
	pattern = "Slash",
	distance_limit_func = function(self, from, card)
		if from:getMark("@heg_six_swords") > 0 then return 1 end
	end,
}
heg_six_swords = sgs.CreateWeapon{
	name = "heg_six_swords",
	class_name = "heg_six_swords",
	suit = sgs.Card_Diamond,
	number = 6,
	range = 2,
	equip_skill = heg_six_swords_Skill,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getSkill(self:objectName())
		if skill and skill:inherits("ViewAsSkill") then room:attachSkillToPlayer(player, skill:objectName()) end
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getSkill(self:objectName())
		if skill and skill:inherits("ViewAsSkill") then room:detachSkillFromPlayer(player, skill:objectName(), true) end
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			p:loseAllMarks("@heg_six_swords")
		end
	end,
}

heg_six_swords:setParent(extension_hegcard)
if not sgs.Sanguosha:getSkill("heg_six_swords_buff") then skills:append(heg_six_swords_buff) end

-- 【挟天子以令诸侯】Trick Card Implementation
heg_threaten_emperor = sgs.CreateTrickCard{
	name = "heg_threaten_emperor",
	class_name = "ThreatenEmperor",
	subclass = sgs.LuaTrickCard_TypeNormal,
	target_fixed = true,
	can_recast = false,
	is_cancelable = false,
	damage_card = false,
	available = function(self, player)
		-- 只有大势力角色才能使用
		if not IsBigKingdomPlayerClient(player) then
			return false
		end
		return self:cardIsAvailable(player) and player:getMark("heg_threaten_emperor_lun") == 0
	end,
	about_to_use = function(self, room, use)
		-- 目标为自己
		if use.to:isEmpty() then 
			use.to:append(use.from) 
		end
		self:cardOnUse(room, use)
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		-- 设置标记，表示该角色受到【挟天子以令诸侯】影响
		room:setPlayerMark(effect.to, "heg_threaten_emperor", 1)
		room:setPlayerMark(effect.to, "heg_threaten_emperor_lun", 1)
		return false
	end,
}

-- 【挟天子以令诸侯】效果触发技能
heg_threaten_emperor_effect = sgs.CreateTriggerSkill{
	name = "#heg_threaten_emperor_effect",
	events = {sgs.EventPhaseEnd},
	global = true,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getMark("heg_threaten_emperor") > 0
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Discard then
			room:setPlayerMark(player, "heg_threaten_emperor", 0)
			-- 询问是否弃置一张手牌以获得额外回合
			if not player:isKongcheng() then
				if room:askForDiscard(player, "heg_threaten_emperor", 1, 1, true, false, "@heg_threaten_emperor") then
					-- 设置标记用于在回合结束时授予额外回合
					room:setTag("heg_threaten_emperor_extra_turn", sgs.QVariant(player))
				end
			end
		end
		return false
	end,
}

-- 授予额外回合的技能
heg_threaten_emperor_give = CreateExtraTurnGiveSkill(
	"#heg_threaten_emperor_give",
	"heg_threaten_emperor_extra_turn",
	sgs.Player_NotActive,
	1
)

-- 添加卡牌到扩展包
heg_threaten_emperor:addCharTag("transfer_card")
heg_threaten_emperor:setParent(extension_hegadvantagecard)
if not sgs.Sanguosha:getSkill("#heg_threaten_emperor_effect") then 
	skills:append(heg_threaten_emperor_effect) 
end
if not sgs.Sanguosha:getSkill("#heg_threaten_emperor_give") then 
	skills:append(heg_threaten_emperor_give) 
end


--[[
heg_lure_tiger = sgs.CreateTrickCard{
	name = "heg_lure_tiger",
	class_name = "heg_lure_tiger",
	target_fixed = false,
	can_recast = false,
	subtype = "multiple_target_trick",
	subclass = sgs.LuaTrickCard_TypeNormal,
	available = function(self,player)
		for _,to in sgs.list(player:getAliveSiblings())do
			if CanToCard(self,player,to) then
				return self:cardIsAvailable(player)
			end
		end
		return false
	end,
	filter = function(self,targets,to_select,source)
		if source:isProhibited(to_select,self) then return false end
		local total_num = 2
		if sgs.Self then
			total_num = total_num + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, source, self)
		end
		return to_select:objectName() ~= source:objectName() and #targets < total_num
	end,
	feasible = function(self,targets,from)
		local total_num = 2
		if sgs.Self then
			total_num = total_num + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, from, self)
		end
		return #targets <= total_num and #targets > 0
	end,
	is_cancelable = function(self, effect)
		return true
	end,
	on_use = function(self, room, source, targets)
		for _, t in ipairs(targets) do
			room:cardEffect(self, source, t)
		end
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		-- 禁止使用和打出牌
		room:setPlayerCardLimitation(effect.to, "use,response", ".", true)
		-- 设置标记表示受到调虎离山影响
		room:addPlayerMark(effect.to, "&heg_lure_tiger-Clear")
	end,
}

-- 【调虎离山】效果：防止体力值改变
heg_lure_tiger_effect = sgs.CreateTriggerSkill{
	name = "#heg_lure_tiger_effect",
	events = {sgs.PreHpLost, sgs.Predamage, sgs.PreHpRecover},
	global = true,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		if event == sgs.PreHpLost then
			if player:getMark("&heg_lure_tiger-Clear") > 0 then
				return true
			end
		elseif event == sgs.Predamage then
			local damage = data:toDamage()
			if damage.to and damage.to:getMark("&heg_lure_tiger-Clear") > 0 then
				return true
			end
		elseif event == sgs.PreHpRecover then
			local recover = data:toRecover()
			if recover.who and recover.who:getMark("&heg_lure_tiger-Clear") > 0 then
				return true
			end
		end
		return false
	end,
}

-- 【调虎离山】禁止技能：使受影响角色不是牌的合法目标
heg_lure_tiger_prohibit = sgs.CreateProhibitSkill{
	name = "#heg_lure_tiger_prohibit",
	is_prohibited = function(self, from, to, card)
		if to and to:getMark("&heg_lure_tiger-Clear") > 0 and not card:isKindOf("SkillCard") then
			return true
		end
		return false
	end,
}

-- 【调虎离山】距离技能：不计入距离和座次计算
heg_lure_tiger_distance = sgs.CreateDistanceSkill{
	name = "#heg_lure_tiger_distance",
	correct_func = function(self, from, to)
		-- 如果from或to自己有调虎离山标记，其他角色无法计算到他们的距离
		if from:getMark("&heg_lure_tiger-Clear") > 0 or to:getMark("&heg_lure_tiger-Clear") > 0 then
			return 998
		end
		
		-- 计算from到to之间有多少被调虎离山影响的角色，将其从距离中减去
		local affected_count = 0
		local from_seat = from:getSeat()
		local to_seat = to:getSeat()
		
		-- 计算顺时针和逆时针距离
		local right = math.abs(from_seat - to_seat)
		local left = from:aliveCount() - right
		
		-- 统计两个路径上有调虎离山标记的角色数量
		local right_affected = 0
		local left_affected = 0
		
		-- 遍历所有存活角色，计算他们是否在from到to的路径上
		for _, p in sgs.qlist(from:getAliveSiblings()) do
			if p:getMark("&heg_lure_tiger-Clear") > 0 then
				local p_seat = p:getSeat()
				
				-- 判断p是否在from到to的顺时针路径上（右侧）
				if from_seat < to_seat then
					if p_seat > from_seat and p_seat < to_seat then
						right_affected = right_affected + 1
					else
						left_affected = left_affected + 1
					end
				elseif from_seat > to_seat then
					if p_seat > from_seat or p_seat < to_seat then
						right_affected = right_affected + 1
					else
						left_affected = left_affected + 1
					end
				end
			end
		end
		
		-- 返回修正值：如果最短路径会穿过被影响的角色，减去这些角色的数量
		if right <= left then
			return -right_affected
		else
			return -left_affected
		end
	end
}

local dhls = heg_lure_tiger:clone(3, 2)
dhls:addCharTag("transfer_card")
dhls:setParent(extension_hegcard)
local dhls = heg_lure_tiger:clone(4, 10)
dhls:addCharTag("transfer_card")
dhls:setParent(extension_hegcard)
if not sgs.Sanguosha:getSkill("#heg_lure_tiger_effect") then 
	skills:append(heg_lure_tiger_effect) 
end
if not sgs.Sanguosha:getSkill("#heg_lure_tiger_prohibit") then 
	skills:append(heg_lure_tiger_prohibit) 
end
if not sgs.Sanguosha:getSkill("#heg_lure_tiger_distance") then 
	skills:append(heg_lure_tiger_distance) 
end
]]

-- 【火烧连营】Trick Card Implementation
heg_burning_camps = sgs.CreateTrickCard{
	name = "heg_burning_camps",
	class_name = "heg_burning_camps",
	target_fixed = true,
	can_recast = false,
	subtype = "aoe_trick",
	subclass = sgs.LuaTrickCard_TypeNormal,
	damage_card = true,
	available = function(self, player)
		return self:cardIsAvailable(player)
	end,
	about_to_use = function(self, room, use)
		-- 自动选择目标：下家和其队列中的所有角色
		local alive_count = room:alivePlayerCount()
		if alive_count < 2 then
			return
		end
		
		-- 获取下家
		local next_player = use.from:getNextAlive(1)
		if not next_player then
			return
		end
		
		-- 添加下家为目标
		use.to:append(next_player)
		
		-- 获取下家所在队列的其他成员
		local queue = GetQueueMembers(next_player)
		if #queue >= 2 then
			for _, member in ipairs(queue) do
				-- 添加队列中除了下家之外的所有角色
				if member:objectName() ~= next_player:objectName() and not use.from:isProhibited(member, self) and member:objectName() ~= use.from:objectName() then
					use.to:append(member)
				end
			end
		end
		
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		for _, t in ipairs(targets) do
			room:cardEffect(self, source, t)
		end
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local damage = sgs.DamageStruct()
		damage.from = effect.from
		damage.to = effect.to
		damage.card = effect.card
		damage.damage = 1
		damage.nature = sgs.DamageStruct_Fire
		room:damage(damage)
	end,
}
local bc1 = heg_burning_camps:clone(1, 3)
bc1:addCharTag("transfer_card")
bc1:setParent(extension_hegadvantagecard)
local bc2 = heg_burning_camps:clone(2, 11)
bc2:addCharTag("transfer_card")
bc2:setParent(extension_hegadvantagecard)
local bc3 = heg_burning_camps:clone(3, 12)
bc3:addCharTag("transfer_card")
bc3:setParent(extension_hegadvantagecard)

-- 【勠力同心】Trick Card Implementation
heg_fight_together = sgs.CreateTrickCard{
	name = "heg_fight_together",
	class_name = "heg_fight_together",
	target_fixed = false,
	can_recast = true,
	subtype = "aoe_trick",
	subclass = sgs.LuaTrickCard_TypeNormal,
	filter = function(self, targets, to_select, player)
		-- 选择一名角色作为势力代表，需要检查至少有一个同势力类型的角色不被禁止
		if #targets > 0 then
			return false
		end
		
		-- 检查该势力类型是否有至少一个可以作为目标的角色
		local is_big = IsBigKingdomPlayerClient(to_select)
		local has_valid_target = false
		
		for _, p in sgs.qlist(player:getAliveSiblings(true)) do
			local p_is_big = IsBigKingdomPlayerClient(p)
			if is_big == p_is_big and not player:isProhibited(p, self) then
				has_valid_target = true
				break
			end
		end
		
		return has_valid_target
	end,
	feasible = function(self, targets)
		-- 必须选择一名角色
		return #targets <= 1
	end,
	about_to_use = function(self, room, use)
		if use.to:length()<2
		then UseCardRecast(use.from,self,"heg_fight_together")
		else 
			-- 选择一名角色后，自动扩展目标为该势力的所有角色
			if not use.to:isEmpty() then
				local chosen = use.to:at(0)
				local is_big = IsBigKingdomPlayer(chosen)
				
				-- 清空原有目标
				use.to = sgs.SPlayerList()
				
				-- 添加所有符合条件的角色为目标（排除被禁止的角色）
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if is_big then
						-- 如果选择的是大势力角色，目标为所有大势力角色
						if IsBigKingdomPlayer(p) and not use.from:isProhibited(p, self) then
							use.to:append(p)
						end
					else
						-- 如果选择的是小势力角色，目标为所有小势力角色
						if not IsBigKingdomPlayer(p) and not use.from:isProhibited(p, self) then
							use.to:append(p)
						end
					end
				end
			end
			self:cardOnUse(room,use) 
		end
	end,
	on_use = function(self, room, source, targets)
		for _, t in ipairs(targets) do
			room:cardEffect(self, source, t)
		end
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		if effect.to:isChained() then
			-- 处于连环状态，摸一张牌
			effect.to:drawCards(1, "heg_fight_together")
		else
			-- 不处于连环状态，横置
			room:setPlayerChained(effect.to)
		end
	end,
}
local ft1 = heg_fight_together:clone(1, 7)
ft1:setParent(extension_hegadvantagecard)
local ft2 = heg_fight_together:clone(2, 8)
ft2:setParent(extension_hegadvantagecard)

-- 【联军盛宴】Trick Card Implementation
heg_alliance_feast = sgs.CreateTrickCard{
	name = "heg_alliance_feast",
	class_name = "heg_alliance_feast",
	target_fixed = false,
	can_recast = false,
	subtype = "aoe_trick",
	subclass = sgs.LuaTrickCard_TypeNormal,
	filter = function(self, targets, to_select, player)
		-- 只能选择一名角色作为势力代表
		if #targets > 0 then
			return false
		end
		
		-- 玩家必须有势力
		local player_kingdom = player:getKingdom()
		if not player_kingdom or player_kingdom == "" then
			return false
		end
		
		-- 被选择的角色必须势力与玩家不同
		local target_kingdom = to_select:getKingdom()
		if not target_kingdom or target_kingdom == "" or target_kingdom == player_kingdom then
			return false
		end
		
		-- 检查该势力是否有至少一个可以作为目标的角色
		local has_valid_target = false
		for _, p in sgs.qlist(player:getAliveSiblings(true)) do
			if p:getKingdom() == target_kingdom and not player:isProhibited(p, self) then
				has_valid_target = true
				break
			end
		end
		
		return has_valid_target
	end,
	feasible = function(self, targets)
		-- 必须选择一名角色
		return #targets == 1
	end,
	about_to_use = function(self, room, use)
		-- 选择一名角色后，自动扩展目标为使用者+该势力的所有角色
		if not use.to:isEmpty() then
			local chosen = use.to:at(0)
			local chosen_kingdom = chosen:getKingdom()
			
			-- 存储选择的势力信息供effect阶段使用
			room:setTag("heg_alliance_feast_kingdom", sgs.QVariant(chosen_kingdom))
			
			-- 清空原有目标
			use.to = sgs.SPlayerList()
			
			-- 首先添加使用者
			if not use.from:isProhibited(use.from, self) then
				use.to:append(use.from)
			end
			
			-- 添加所选势力的所有角色为目标
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:getKingdom() == chosen_kingdom and not use.from:isProhibited(p, self) then
					use.to:append(p)
				end
			end
		end
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		for _, t in ipairs(targets) do
			room:cardEffect(self, source, t)
		end
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		
		-- 如果目标角色是使用者
		if effect.to:objectName() == effect.from:objectName() then
			-- 获取选择的势力信息
			local kingdom_tag = room:getTag("heg_alliance_feast_kingdom")
			local target_kingdom = kingdom_tag:toString()
			
			if target_kingdom and target_kingdom ~= "" then
				-- 计算该势力的角色数
				local kingdom_count = 0
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					if p:getKingdom() == target_kingdom then
						kingdom_count = kingdom_count + 1
					end
				end
				
				if kingdom_count > 0 then
					
					local choice = room:askForChoice(effect.from, "heg_alliance_feast", "draw+recover", sgs.QVariant(kingdom_count))
					-- 摸X张牌
					if choice == "draw" then
						if kingdom_count > 0 then
							effect.to:drawCards(kingdom_count, "heg_alliance_feast")
						end
					end
					
					-- 回复（Y-X）点体力
					if choice == "recover" then
						local recover = sgs.RecoverStruct()
						recover.who = effect.from
						recover.recover = kingdom_count
						recover.card = effect.card
						room:recover(effect.to, recover)
					end
				end
			end
		else
			-- 如果目标角色不是使用者
			-- 摸一张牌
			effect.to:drawCards(1, "heg_alliance_feast")
			
			-- 重置（解除横置）
			if effect.to:isChained() then
				room:setPlayerChained(effect.to, false)
			end
		end
	end,
}
local af1 = heg_alliance_feast:clone(1, 9)
af1:setParent(extension_hegadvantagecard)
local af2 = heg_alliance_feast:clone(2, 10)
af2:setParent(extension_hegadvantagecard)


-- 青龙偃月刀 (Green Dragon Crescent Blade)
heg_blade_Skill = sgs.CreateTriggerSkill{
	name = "heg_blade",
	events = {sgs.TargetSpecified},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasWeapon("heg_blade")
	end,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") then
				for _, to in sgs.qlist(use.to) do
					for _,sk in sgs.list(to:getSkillList())do
						if sk:isAttachedLordSkill() then continue end
						if to:getMark("Qingcheng"..sk:objectName()) == 0 then
							room:addPlayerMark(to, "Qingcheng"..sk:objectName(), 1)
							room:addPlayerMark(to, "heg_blade_"..sk:objectName(), 1)
						end
					end
					room:addPlayerMark(to, "heg_blade_invalid-Clear", 1)
				end
				room:setCardFlag(use.card, "heg_blade")
				room:setEmotion(player, "weapon/blade")
			end
		end
		return false
	end
}
heg_blade_Clear = sgs.CreateTriggerSkill{
	name = "#heg_blade_Clear",
	events = {sgs.CardFinished, sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data, room)
		local invoke = false
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and use.card:hasFlag("heg_blade") then
				invoke = true
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				invoke = true
			end
		end
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() then
				for _, id in sgs.qlist(move.card_ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card and card:isKindOf("heg_blade") then
						invoke = true
						break
					end
				end
			end
		end
		if invoke then
			for _, to in sgs.qlist(room:getAlivePlayers()) do
				if to:getMark("heg_blade_invalid-Clear") > 0 then
					room:setPlayerMark(to, "heg_blade_invalid-Clear", 0)
					for _,sk in sgs.list(to:getSkillList())do
						if sk:isAttachedLordSkill() then continue end
						if to:getMark("Qingcheng"..sk:objectName()) == 0 then
							room:setPlayerMark(to, "Qingcheng"..sk:objectName(), 0)
							room:setPlayerMark(to, "heg_blade_"..sk:objectName(), 0)
						end
					end
				end
			end
		end
		return false
	end
}


heg_blade = sgs.CreateWeapon{
	name = "heg_blade",
	class_name = "heg_blade",
	suit = sgs.Card_Spade,
	number = 5,
	range = 3,
	equip_skill = heg_blade_Skill,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("heg_blade_Skill")
		if skill then room:getThread():addTriggerSkill(skill) end
		local skill2 = sgs.Sanguosha:getTriggerSkill("#heg_blade_Clear")
		if skill2 then room:getThread():addTriggerSkill(skill2) end
	end,
	on_uninstall = function(self, player)
		local room = player:getRoom()
		-- Clear marks when weapon is uninstalled
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("heg_blade_invalid-Clear") > 0 then
				room:setPlayerMark(p, "heg_blade_invalid-Clear", 0)
				for _,sk in sgs.list(p:getSkillList())do
					if sk:isAttachedLordSkill() then continue end
					if p:getMark("Qingcheng"..sk:objectName()) == 0 then
						room:setPlayerMark(p, "Qingcheng"..sk:objectName(), 0)
						room:setPlayerMark(p, "heg_blade_"..sk:objectName(), 0)
					end
				end
			end
		end
	end,
}
heg_blade:setParent(extension_hegcard)
if not sgs.Sanguosha:getSkill("#heg_blade_Clear") then skills:append(heg_blade_Clear) end

-- 方天画戟 (Halberd of Heaven)
heg_halberd_Card = sgs.CreateSkillCard{
	name = "heg_halberd",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		if not player:hasWeapon("heg_halberd") then return false end
		local use = player:getTag("heg_halberd_use"):toCardUse()
		if not use.card or not use.card:isKindOf("Slash") then return false end
		
		-- Check if to_select is already a target
		for _, p in sgs.qlist(use.to) do
			if p:objectName() == to_select:objectName() then return false end
		end
		
		-- Check if to_select has different kingdom or no kingdom
		local target_kingdom = to_select:getKingdom()
		if target_kingdom == "" or target_kingdom == "god" then
			return true
		end
		
		-- Check if target's kingdom is different from all existing targets
		for _, p in sgs.qlist(use.to) do
			local p_kingdom = p:getKingdom()
			if p_kingdom ~= "" and p_kingdom ~= "god" and p_kingdom == target_kingdom then
				return false
			end
		end
		
		return true
	end,
	feasible = function(self, targets)
		return true
	end,
	on_use = function(self, room, source, targets)
		local use = source:getTag("heg_halberd_use"):toCardUse()
		for _, target in ipairs(targets) do
			use.to:append(target)
		end
		source:setTag("heg_halberd_use", sgs.QVariant_fromValue(use))
	end
}

heg_halberd_Skill = sgs.CreateTriggerSkill{
	name = "heg_halberd_Skill",
	events = {sgs.TargetSpecified, sgs.CardOffset, sgs.CardEffected},
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and player:hasWeapon("heg_halberd") then
				player:setTag("heg_halberd_use", sgs.QVariant_fromValue(use))
				room:askForUseCard(player, "@@heg_halberd", "@heg_halberd")
				player:removeTag("heg_halberd_use")
			end
		elseif event == sgs.CardOffset then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") then
				room:setCardFlag(effect.whocard, "heg_halberd")
			end
		elseif event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card and effect.card:isKindOf("Slash") and effect.card:hasFlag("heg_halberd") then
				local msg = sgs.LogMessage()
                msg.type = "#SkillNullify"
                msg.from = player
                msg.arg = self:objectName()
                msg.arg2 = effect.card:objectName()
                room:sendLog(msg)
                return true
			end
		end
		return false
	end
}

heg_halberd = sgs.CreateWeapon{
	name = "heg_halberd",
	class_name = "heg_halberd",
	suit = sgs.Card_Diamond,
	number = 12,
	range = 4,
	equip_skill = heg_halberd_Skill,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("heg_halberd_Skill")
		if skill then room:getThread():addTriggerSkill(skill) end
	end,
}
heg_halberd:setParent(extension_hegcard)

-- 明光铠 (Brilliant Armor)
heg_iron_armor_Skill = sgs.CreateTriggerSkill{
	name = "heg_iron_armor_Skill",
	events = {sgs.TargetConfirming, sgs.BeforeChained},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasArmorEffect("heg_iron_armor")
	end,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card then
				-- Cancel target for Fire Burning Camps, Fire Attack, or Fire Slash
				if use.card:isKindOf("FireAttack") or use.card:isKindOf("BurningCamps") or
				   (use.card:isKindOf("Slash") and use.card:isKindOf("FireSlash")) then
					for i = 0, use.to:length() - 1 do
						if use.to:at(i):objectName() == player:objectName() then
							use.to:removeAt(i)
							data = sgs.QVariant_fromValue(use)
							return false
						end
					end
				end
			end
		elseif event == sgs.BeforeChained then
			-- Prevent chaining if small kingdom player
			if not IsBigKingdomPlayer(player) then
				return true
			end
		end
		return false
	end
}

heg_iron_armor = sgs.CreateArmor{
	name = "heg_iron_armor",
	class_name = "heg_iron_armor",
	suit = sgs.Card_Heart,
	number = 2,
	equip_skill = heg_iron_armor_Skill,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill = sgs.Sanguosha:getTriggerSkill("heg_iron_armor_Skill")
		if skill then room:getThread():addTriggerSkill(skill) end
	end,
}
heg_iron_armor:setParent(extension_hegcard)

-- 惊帆 (Alarming Sail)
heg_jingfan = sgs.CreateOffensiveHorse{
	name = "heg_jingfan",
	class_name = "heg_jingfan",
	suit = sgs.Card_Heart,
	number = 3,
}
heg_jingfan:addCharTag("transfer_card")
heg_jingfan:setParent(extension_hegcard)


-- 玉玺 (Imperial Jade Seal)
heg_jade_seal_Skill = sgs.CreateTriggerSkill{
	name = "heg_jade_seal",
	events = {sgs.DrawNCards, sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:hasTreasure("heg_jade_seal")
	end,
	on_trigger = function(self, event, player, data, room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play then
				local knownboth = sgs.Sanguosha:cloneCard("heg_known_both", sgs.Card_NoSuit, 0)
				knownboth:setSkillName("heg_jade_seal")
				knownboth:deleteLater()
				local targets = room:getCardTargets(player, knownboth)
				if targets:isEmpty() then return false end
				local others = room:askForPlayersChosen(player, targets, "heg_jade_seal", 1, 1+sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, player, knownboth), "heg_jade_seal-invoke", true, true)
				if others:isEmpty() then return false end
				if knownboth then
					local use = sgs.CardUseStruct()
					use.card = knownboth
					use.to = others
					use.from = player
					room:useCard(use, false)
				end
			end
		else
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
			draw.num = draw.num + 1
			data:setValue(draw)
		end
		return false
	end
}

heg_jade_seal = sgs.CreateTreasure{
	name = "heg_jade_seal",
	class_name = "heg_jade_seal",
	suit = sgs.Card_Heart,
	number = 1,
	equip_skill = heg_jade_seal_Skill,
	on_install = function(self, player)
		local room = player:getRoom()
		local skill1 = sgs.Sanguosha:getTriggerSkill("heg_jade_seal")
		if skill1 then room:getThread():addTriggerSkill(skill1) end
	end,
}
heg_jade_seal:setParent(extension_hegcard)

sgs.Sanguosha:addSkills(skills)


sgs.LoadTranslationTable{
    ["new_heg"] = "新国战",
    ["heg_ol"] = "OL国战",
    ["heg_mobile"] = "手杀国战",
    ["heg_tenyear"] = "十周年国战",
    ["heg_bian"] = "君临天下-变",
    ["heg_quan"] = "君临天下·权",
    ["heg_lordex"] = "君临天下·EX/不臣篇",
    ["heg_purplecloud"] = "紫气东来",
    ["heg_goldenseal"] = "金印紫绶",
	["hegemony_cards"] = "国战标准版",
	["strategic_advantage"] = "君临天下·势备篇",
		
	-- 合纵机制
	["hezong"] = "合纵",
	[":hezong"] = "出牌阶段，你可以将至多三张牌（须带有「合纵」标识）交给与你势力不同的一名角色，然后摸等量的牌。",
	["#hezong"] = "%from 对 %to 发动了【%arg】，交给了 %arg2 张牌，然后摸了 %arg2 张牌",
	["transfer_card"] = "合纵",
	[":transfer_card"] = "此牌可用于合纵",


	["displayed"] = "明置",
	["@heg_xianqu"] = "先驱",
	["heg_xianqu"] = "先驱",
	[":heg_xianqu"] = "出牌阶段，你可以弃置此标记，然后将手牌摸至四张并观看一名其他角色的手牌。",
	["@heg_yinyangyu"] = "阴阳鱼",
	["heg_yinyangyu"] = "阴阳鱼",
	[":heg_yinyangyu"] = "出牌阶段，你可以弃置此标记，然后摸一张牌；弃牌阶段开始时，你可以弃置此标记，然后本回合手牌上限+2。",
	["heg_transfer"] = "合纵",
	[":heg_transfer"] = "出牌阶段限一次，你可以将至多三张“合纵”牌交给一名与你势力不同的角色，然后你摸等量的牌。",
	["#heg_transfer"] = "%from 发动了“<b><font color=\"yellow\">合纵</font></b>”，将 %arg 张牌交给了 %to ，并摸了 %arg 张牌",

	["heg_sujiang"] = "士兵(男)",
	["&heg_sujiang"] = "士兵",
	["heg_sujiangf"] = "士兵(女)",
	["&heg_sujiangf"] = "士兵",

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
	[":heg_tianxiang"] = "<font color=\"green\"><b>每回合每项限一次，</b></font>当你受到伤害时，你可以弃置一张红桃手牌防止此伤害并选择一名其他角色，你选择一项：1.令其受到同来源的1点伤害后摸X张牌（X为其已损失体力值且至多为5）；2.令其失去1点体力后获得你弃置的牌。",
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

	["heg_himiko"] = "卑弥呼-国",
    ["&heg_himiko"] = "卑弥呼",
	["#heg_himiko"] = " 邪马台的女王",
	["information:heg_himiko"] = "十年踪迹十年心",
	["~heg_himiko"] = "",
	["heg_guishu"] = "鬼术",
	[":heg_guishu"] = "出牌阶段，你可将一张♠手牌当【远交近攻】或【知己知彼】使用（不可与你此回合上一次以此法使用的牌相同）。",
	[":heg_guishu0"] = "出牌阶段，你可将一张♠手牌当【远交近攻】或【知己知彼】使用（不可与你此回合上一次以此法使用的牌相同）。",
	[":heg_guishu1"] = "出牌阶段，你可以将一张黑桃手牌当【远交近攻】<s>或【知己知彼】</s>使用（不可与你此回合上一次以此法使用的牌相同）。",
	[":heg_guishu2"] = "出牌阶段，你可以将一张黑桃手牌当<s>【远交近攻】或</s>【知己知彼】使用（不可与你此回合上一次以此法使用的牌相同）。",
	["heg_yuanyu"] = "远域",
	[":heg_yuanyu"] = "锁定技，当你受到伤害时，若有伤害来源且你不在伤害来源的攻击范围内，此伤害-1。",
	
	["heg_yangwan"] = "杨婉-国",
    ["&heg_yangwan"] = "杨婉",
	["#heg_yangwan"] = " 融沫之鲡",
	["illustrator:heg_yangwan"] = "木美人",
	["information:heg_yangwan"] = "十年踪迹十年心",
	["~heg_yangwan"] = "",
	["heg_youyan"] = "诱言",
  	[":heg_youyan"] = "<font color=\"green\"><b>回合内限一次，</b></font>当你的牌因弃置而置入弃牌堆时，你可以展示牌堆顶的四张牌，然后获得其中与你此次弃置的牌花色均不相同的牌。",
    ["heg_zhuihuan"] = "追还",
  	[":heg_zhuihuan"] = "回合结束时，你可以选择至多两名角色，直到你下回合开始，其中一名角色下一次受到伤害后，其对伤害来源造成1点伤害，另一名角色下一次受到伤害后，伤害来源弃置两张手牌。",
	["@heg_zhuihuan"] = "追还：你可以选择两名角色",
	["heg_zhuihuan:damage"] = "对伤害来源造成1点伤害",
	["heg_zhuihuan:discard"] = "伤害来源弃置两张手牌",

	["heg_zongyu"] = "宗预-国",
    ["&heg_zongyu"] = "宗预",
	["#heg_zongyu"] = " 九醞鸿胪",
	["illustrator:heg_zongyu"] = "铁杵文化",
	["information:heg_zongyu"] = "十年踪迹十年心",
	["heg_qiao"] = "气傲",
	[":heg_qiao"] = "<font color=\"green\"><b>每回合限两次，</b></font>当你成为其他角色使用牌的目标后，你可以弃置该角色一张牌，然后你弃置一张牌。",
	["heg_chengshang"] = "承赏",
	[":heg_chengshang"] = "当你对其他角色使用牌后，若此牌未造成伤害，你可以令其中一名目标角色展示并交给你一张牌，若其交给你的牌与你使用的牌花色或点数相同，你失去此技能。",
	["@heg_chengshang"] = "承赏：请选择一名目标角色交给你一张牌",

	["heg_lvlingqi"] = "吕玲绮-国",
    ["&heg_lvlingqi"] = "吕玲绮",
	["#heg_lvlingqi"] = "無雙虓姬",
	["illustrator:heg_lvlingqi"] = "",
	["information:heg_lvlingqi"] = "十年踪迹十年心",
	["heg_guowu"] = "帼武",
	[":heg_guowu"] = "出牌阶段开始时，你可以展示全部手牌，若牌的类别数不小于：1，你获得弃牌堆中的一张【杀】；2，此阶段你使用牌无距离限制；3，每回合限一次，本阶段你使用【杀】可以多指定两个目标。",
	["@heg_guowu"] = "帼武：你可以多指定两个目标",
	["heg_shenwei"] = "神威",
	[":heg_shenwei"] = "摸牌阶段，若你的体力值全场最大，你多摸两张牌；你的手牌上限+2。",
	["heg_zhuangrong"] = "妆戎",
	[":heg_zhuangrong"] = "出牌阶段限一次，你可以弃置一张锦囊牌，然后你本阶段视为拥有“无双”。",

	["heg_zhouyi"] = "周夷-国",
    ["&heg_zhouyi"] = "周夷",
	["#heg_zhouyi"] = "靛情雨黛",
	["illustrator:heg_zhouyi"] = "",
	["information:heg_zhouyi"] = "十年踪迹十年心",
	["heg_zhukou"] = "逐寇",
	[":heg_zhukou"] = "当你于一名角色的出牌阶段内第一次造成伤害后，你可以摸X张牌（X为本回合你使用过的牌数且至多为5）。",
	["heg_duannian"] = "断念",
	[":heg_duannian"] = "出牌阶段结束时，你可以弃置所有手牌（至少一张），然后将手牌摸至体力上限。",
	["heg_lianyou"] = "莲佑",
	[":heg_lianyou"] = "当你死亡时，你可以令一名其他角色获得“兴火”。",
	["heg_lianyou-invoke"] = "你可以发动“莲佑”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["heg_xinghuo"] = "兴火",
	[":heg_xinghuo"] = "锁定技，当你造成火焰伤害时，此伤害+1。",

	["heg_nanhualaoxian"] = "南华老仙-国",
    ["&heg_nanhualaoxian"] = "南华老仙",
	["#heg_nanhualaoxian"] = "虚步太清",
	["illustrator:heg_nanhualaoxian"] = "",
	["information:heg_nanhualaoxian"] = "国战典藏2023",
	["heg_gongxiu"] = "共修",
	[":heg_gongxiu"] = "摸牌阶段，你可以少摸一张牌，然后选择你上次未选择的一项：1. 令至多X名角色各摸一张牌；2. 令至多X名其他角色各弃置一张牌。（X为你的体力上限）",
	[":heg_gongxiu1"] = "摸牌阶段，你可以少摸一张牌，然后选择你上次未选择的一项：1. 令至多X名角色各摸一张牌；<s>2. 令至多X名其他角色各弃置一张牌。（X为你的体力上限）</s>",
	[":heg_gongxiu2"] = "摸牌阶段，你可以少摸一张牌，然后选择你上次未选择的一项：<s>1. 令至多X名角色各摸一张牌；</s>2. 令至多X名其他角色各弃置一张牌。（X为你的体力上限）",
	["heg_gongxiu:draw"] = "令至多X名角色各摸一张牌",
	["heg_gongxiu:discard"] = "令至多X名其他角色各弃置一张牌",
	["@heg_gongxiu-target"] = "共修： %src",
	["heg_taidan"] = "太丹",
	[":heg_taidan"] = "锁定技，若你的装备区里没有防具牌，则你视为装备着【太平要术】。",
	["heg_jinghe"] = "经合",
	[":heg_jinghe"] = "出牌阶段限一次，你可以转动“天书”，然后选择一名角色并令其获得“天书”向上一面所示的技能，直到你下一个回合开始时。",

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

	["heg_ol_lukang"] = "陆抗-国[OL]",
    ["&heg_ol_lukang"] = "陆抗",
    ["#heg_ol_lukang"] = "孤柱扶厦",
    ["~heg_ol_lukang"] = "",
    ["designer:heg_ol_lukang"] = "",
    ["cv:heg_ol_lukang"] = "",
    ["illustrator:heg_ol_lukang"] = "王立雄",

	["heg_known_both"] = "知己知彼",
	[":heg_known_both"] = "锦囊牌\
	出牌时机：出牌阶段\
	使用目标：一名其他角色\
	作用效果：你观看目标对应的角色的手牌，然后摸一张牌。\
	重铸：出牌阶段，你可将此牌置入弃牌堆，然后摸一张牌",
	["#heg_showhandcards"] = "%from 选择观看 %to 的<font color = 'gold'><b>【手牌】</b></font>",

	["heg_befriend_attacking"] = "远交近攻",
	[":heg_befriend_attacking"] = "锦囊牌\
	出牌时机：出牌阶段\
	使用目标：一名其他角色\
	作用效果：目标角色摸一张牌，然后你摸三张牌。",

	["heg_await_exhausted"] = "以逸待劳",
	[":heg_await_exhausted"] = "锦囊牌\
	出牌时机：出牌阶段\
	使用目标：任意角色\
	作用效果：目标角色摸两张牌，然后弃置两张牌。",

	["heg_nullification"] = "无懈可击·国",
	[":heg_nullification"] = "锦囊牌<br/><b>时机</b>：当锦囊牌对目标生效前<br/><b>目标</b>：此牌<br/><b>效果</b>：抵消此牌。你令对对应的角色为与其势力相同的角色的目标结算的此牌不是【无懈可击】的合法目标，当此牌对对应的角色为这些角色中的一名的目标生效前，抵消此牌。",
	--TODO

	["heg_triblade"] = "三尖两刃刀",
	[":heg_triblade"] = "装备牌·武器\
	攻击范围：3\
	攻击效果：每当你使用【杀】对目标角色造成伤害后，可弃置一张手牌，并对该角色距离1的另一名角色造成1点伤害。",
	["#heg_triblade_chosen"] = "【三尖两刃刀】你可以选择一角色，对其造成1点伤害。",
	["#heg_triblade_Skill_dis"] = "【三尖两刃刀】你可以弃置一张手牌。",

	["heg_six_swords"] = "吴六剑",
	[":heg_six_swords"] = "装备牌·武器\
	攻击范围：2\
	攻击效果：出牌阶段，你可以选择任意数量的其他角色，使用【杀】与其他角色攻击范围+1。",
	["@heg_six_swords"] = "吴六剑",

	--势备篇
	["heg_threaten_emperor"] = "挟天子以令诸侯",
	[":heg_threaten_emperor"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：为大势力角色的你。\n作用效果：每轮限一次，目标对应的角色结束出牌阶段→当前回合的弃牌阶段结束时，其可弃置一张手牌▷其获得一个额外回合。",
	["@heg_threaten_emperor"] = "受到【挟天子以令诸侯】影响，你可以弃置一张牌，获得一个额外的回合",
	
	["heg_lure_tiger"] = "调虎离山",
  	[":heg_lure_tiger"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一至两名其他角色<br/><b>效果</b>：目标角色于此回合内不计入距离和座次的计算，且不能使用牌，且不是牌的合法目标，且体力值不会改变。",
	
	["heg_burning_camps"] = "火烧连营",
  	[":heg_burning_camps"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：你的下家和除其外与其处于同一<a href='heg_formation'>队列</a>的所有角色<br/><b>效果</b>：目标角色受到你造成的1点火焰伤害。",

	["heg_fight_together"] = "戮力同心",
  	[":heg_fight_together"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：所有大势力角色或所有小势力角色<br/><b>效果</b>：若目标角色：不处于连环状态，其横置；处于连环状态，其摸一张牌。<br/><font color='grey'>操作提示：选择一名角色，若其为大势力角色，则目标为所有大势力角色；若其为小势力角色，则目标为所有小势力角色</font>",
  	["#heg_fight_together_skill"] = "选择所有大势力角色或小势力角色，若这些角色处于/不处于连环状态，其摸一张牌/横置",

	["heg_alliance_feast"] = "联军盛宴",
  	[":heg_alliance_feast"] = "锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：有势力的你和除你的势力外的一个势力的所有角色<br/><b>效果</b>：若目标角色：为你，你摸X张牌，回复X点体力（X为该势力的角色数）；不为你，其摸一张牌，重置。<br/><font color='grey'>操作提示：选择一名与你势力不同的角色，目标为你和该势力的所有角色</font>",

	["heg_blade"] = "青龙偃月刀",
  	[":heg_blade"] = "装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：锁定技，当你使用【杀】时，此牌的使用结算结束之前，此【杀】的目标角色技能失效。",

	["heg_halberd"] = "方天画戟",
  	[":heg_halberd"] = "装备牌·武器<br /><b>攻击范围</b>：４<br /><b>武器技能</b>：当你使用【杀】选择目标后，可以令任意名势力各不相同且与已选择的目标势力均不相同的角色和任意名没有势力的角色也成为目标，当此【杀】被【闪】抵消后，此【杀】对所有目标均无效。",

	["heg_iron_armor"] = "明光铠",
  	[":heg_iron_armor"] = "装备牌·防具<br/><b>防具技能</b>：锁定技，当你成为【火烧连营】、【火攻】或火【杀】的目标时，你取消此目标；当你横置前，若你是小势力角色，你防止此次横置。",

	["heg_jingfan"] = "惊帆",
  	[":heg_jingfan"] = "装备牌·坐骑<br /><b>坐骑技能</b>：你与其他角色的距离-1。",

	["heg_jade_seal"] = "玉玺",
  	[":heg_jade_seal"] = "装备牌·宝物<br/><b>宝物技能</b>：锁定技，你的势力为大势力，除你的势力外的所有势力均为小势力；摸牌阶段，你令额定摸牌数+1；出牌阶段开始时，你视为使用【知己知彼】。",

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
	["heg_jieyue"] = "节钺",
	[":heg_jieyue"] = "准备阶段，你可以将一张牌交给一名其他角色，然后令其执行一次“军令”。若其：执行，你摸一张牌；不执行，摸牌阶段，你多摸三张牌。",
	["@heg_jieyue-give"] = "你可以将一张牌交给一名其他角色，令其执行一次“军令”",
	["heg_jieyue-invoke"] = "你可以发动“节钺”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",

	["heg_cuiyanmaojie"] = "崔琰毛玠-国",
    ["&heg_cuiyanmaojie"] = "崔琰毛玠",
    ["#heg_cuiyanmaojie"] = "日出月盛",
    ["~heg_cuiyanmaojie"] = "",
    ["designer:heg_cuiyanmaojie"] = "Virgopaladin（韩旭）",
    ["cv:heg_cuiyanmaojie"] = "",
    ["illustrator:heg_cuiyanmaojie"] = "兴游",	
	["heg_zhengbi"] = "征辟",
	[":heg_zhengbi"] = "出牌阶段开始时，你可选择一项：1.选择一名角色，直至此回合结束，你对其使用牌无距离与次数限制；2.将一张基本牌交给一名角色，然后其交给你一张非基本牌或两张基本牌。",
	["heg_fengying"] = "奉迎",
  	[":heg_fengying"] = "限定技，出牌阶段，你可将所有手牌当【挟天子以令诸侯】（无视大势力限制）使用，然后你令任意名角色将手牌补至其体力上限。",

	["heg_wangping"] = "王平-国",
    ["&heg_wangping"] = "王平",
    ["#heg_wangping"] = "键闭剑门",
    ["~heg_wangping"] = "",
    ["designer:heg_wangping"] = "",
    ["cv:heg_wangping"] = "",
    ["illustrator:heg_wangping"] = "zoo",
	["@heg_jianglue"] = "将略：请选择“军令”的目标",
	["heg_jianglue"] = "将略",
  	[":heg_jianglue"] = "限定技，出牌阶段，你可选择一个“军令”。你对任意名角色发起此“军令”。你加1点体力上限，回复1点体力，所有执行“军令”的角色各加1点体力上限，回复1点体力。然后你摸X张牌（X为以此法回复体力的角色数）。",

	["heg_fazheng"] = "法正-国",
    ["&heg_fazheng"] = "法正",
    ["#heg_fazheng"] = "蜀汉的辅翼",
    ["~heg_fazheng"] = "",
    ["designer:heg_fazheng"] = "",
    ["cv:heg_fazheng"] = "",
    ["illustrator:heg_fazheng"] = "黑白画谱",
	["heg_xuanhuoAttach"] = "眩惑",
	[":heg_xuanhuoAttach"] = "出牌阶段限一次，你可交给法正一张手牌，然后你弃置一张牌，选择下列技能中的一个：“武圣”“咆哮”“龙胆”“铁骑”“烈弓”“狂骨”（场上已有的技能无法选择）。其可使你于此回合内拥有你以此法选择的技能。",
	["heg_xuanhuo"] = "眩惑",
  	[":heg_xuanhuo"] = "其他角色的出牌阶段限一次，其可交给你一张手牌，然后其弃置一张牌，选择下列技能中的一个：“武圣”“咆哮”“龙胆”“铁骑”“烈弓”“狂骨”（场上已有的技能无法选择）。你可使其于此回合内拥有其以此法选择的技能。",
	["heg_enyuan"] = "恩怨",
  	[":heg_enyuan"] = "锁定技，当你成为【桃】的目标后，若使用者不为你，其摸一张牌；当你受到伤害后，伤害来源需交给你一张手牌，否则失去1点体力。",

	["heg_lukang"] = "陆抗-国",
    ["&heg_lukang"] = "陆抗",
    ["#heg_lukang"] = "孤柱扶厦",
    ["~heg_lukang"] = "",
    ["designer:heg_lukang"] = "",
    ["cv:heg_lukang"] = "",
    ["illustrator:heg_lukang"] = "王立雄",
	["heg_keshou"] = "恪守",
  	[":heg_keshou"] = "当你受到伤害时，你可弃置两张颜色相同的牌▷伤害值-1。你判定，若结果为红色，你摸一张牌。",
	["heg_zhuwei"] = "筑围",
  	[":heg_zhuwei"] = "你的判定牌生效后，若此牌为【杀】或【决斗】，你可以获得之，然后你可以令当前回合角色本回合使用【杀】的次数上限+1，手牌上限+1。",

	["heg_wuguotai"] = "吴国太-国",
    ["&heg_wuguotai"] = "吴国太",
    ["#heg_wuguotai"] = "武烈皇后",
    ["~heg_wuguotai"] = "",
    ["designer:heg_wuguotai"] = "",
    ["cv:heg_wuguotai"] = "",
    ["illustrator:heg_wuguotai"] = "李秀森",
	["heg_buyi"] = "补益",
  	[":heg_buyi"] = "每回合限一次，当一名角色的濒死结算后，若其存活，你可对伤害来源发起“军令”。若来源不执行，则你令该角色回复1点体力。",

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
	--TODO

	["heg_zhangxiu"] = "张绣-国",
    ["&heg_zhangxiu"] = "张绣",
    ["#heg_zhangxiu"] = "北地枪王",
    ["~heg_zhangxiu"] = "",
    ["designer:heg_zhangxiu"] = "千幻",
    ["cv:heg_zhangxiu"] = "",
    ["illustrator:heg_zhangxiu"] = "青岛磐蒲",
	["heg_fudi"] = "附敌",
  	[":heg_fudi"] = "当你受到其他角色造成的伤害后，你可以交给伤害来源一张手牌。若如此做，你对体力值最多且不小于你的一名角色造成1点伤害。",
	["@heg_fudi-give"] = "附敌：你可以交给 %src 一张手牌",
	["@heg_fudi-damage"] = "附敌：你对体力值最多且不小于你的一名角色造成1点伤害",
    ["heg_congjian"] = "从谏",
  	[":heg_congjian"] = "锁定技，当你于回合外造成伤害时或于回合内受到伤害时，伤害值+1。",

	--君临天下·EX/不臣篇
	["heg_mengda"] = "孟达-国",
    ["&heg_mengda"] = "孟达",
    ["#heg_mengda"] = "怠军反复",
    ["~heg_mengda"] = "",
    ["designer:heg_mengda"] = "韩旭",
    ["cv:heg_mengda"] = "",
    ["illustrator:heg_mengda"] = "张帅",
	["heg_qiuan_han"] = "函",
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
	["@heg_wenji"] = "问计：交给 %src 一张牌",
	["heg_wenji-invoke"] = "你可以发动“问计”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
	["heg_wenji"] = "问计",
  	[":heg_wenji"] = "出牌阶段开始时，你可令一名其他角色交给你一张牌，然后其可以令你于此回合内使用此牌无距离与次数限制且不能被响应；否则，你交给其另一张牌。",
	["heg_tunjiang"] = "屯江",
  	[":heg_tunjiang"] = "结束阶段开始时，若你于出牌阶段内使用过牌且未对其他角色使用过牌，你可摸X张牌（X为势力数）。",

	["heg_mifangfushiren"] = "糜芳傅士仁-国",
    ["&heg_mifangfushiren"] = "糜芳傅士仁",
    ["#heg_mifangfushiren"] = "逐驾迎尘",
    ["~heg_mifangfushiren"] = "",
    ["designer:heg_mifangfushiren"] = "Loun老萌",
    ["cv:heg_mifangfushiren"] = "",
    ["illustrator:heg_mifangfushiren"] = "木美人",
	["@heg_fengshih"] = "锋势：你可以弃置你与 %src 各一张牌，然后此牌造成伤害值+1",
	["heg_fengshih"] = "锋势",
  	[":heg_fengshih"] = "①当你使用牌指定其他角色为唯一目标后，若其手牌数小于你且你与其均有牌，你可以弃置你与其各一张牌，然后此牌造成伤害值+1；②当你成为其他角色使用牌的唯一目标后，若你手牌数小于其且你与其均有牌，其可以令你弃置你与其各一张牌，然后此牌造成伤害值+1。",
	
	["heg_zhanglu"] = "张鲁-国",
    ["&heg_zhanglu"] = "张鲁",
    ["#heg_zhanglu"] = "政宽教惠",
    ["~heg_zhanglu"] = "",
    ["designer:heg_zhanglu"] = "",
    ["cv:heg_zhanglu"] = "",
    ["illustrator:heg_zhanglu"] = "磐蒲",
	["heg_bushi-invoke"] = "你可以发动“布施”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["heg_bushi"] = "布施",
  	[":heg_bushi"] = "当你受到1点伤害后，你可以令一名角色摸一张牌；当你对其他角色造成伤害后，你令一名角色摸一张牌。",
    ["@heg_midao-give"] = "米道：你可以交给 %src 一张手牌，令其声明一种花色和一种属性",
    ["#heg_midao_suit"] = "%from 使用的 %card 花色视为 %arg",
    ["heg_midao"] = "米道",
  	[":heg_midao"] = "一名角色的出牌阶段限一次，当其使用的【杀】或伤害类锦囊牌指定第一个目标时，其可以交给你一张手牌，令你声明一种花色和一种属性，然后其此次使用牌的花色与造成伤害的属性视为与你声明的相同。",

	["heg_shixie"] = "士燮-国",
    ["&heg_shixie"] = "士燮",
    ["#heg_shixie"] = "百粤灵欹",
    ["~heg_shixie"] = "",
    ["designer:heg_shixie"] = "韩旭",
    ["cv:heg_shixie"] = "",
    ["illustrator:heg_shixie"] = "磐蒲",	
	["heg_lixia:draw"] = "令 %src 摸一张牌",
	["heg_lixia:discard"] = "弃置 %src 装备区内的一张牌，你失去1点体力",
	["heg_lixia"] = "礼下",
  	[":heg_lixia"] = "锁定技，其他角色的准备阶段，若你不在其攻击范围内，该角色须选择一项：1.令你摸一张牌；2.弃置你装备区内的一张牌，该角色失去1点体力。",
	["heg_biluan"] = "避乱",
  	[":heg_biluan"] = "锁定技，其他角色计算与你的距离+X（X为你装备区内的牌数）。",

	["heg_nos_shixie"] = "士燮-国[旧]",
    ["&heg_nos_shixie"] = "士燮",
    ["#heg_nos_shixie"] = "百粤灵欹",
    ["~heg_nos_shixie"] = "",
    ["designer:heg_nos_shixie"] = "韩旭",
    ["cv:heg_nos_shixie"] = "",
    ["illustrator:heg_nos_shixie"] = "磐蒲",	
	["heg_nos_lixia:draw"] = "令 %src 摸一张牌",
	["heg_nos_lixia:discard"] = "弃置两张牌",
	["heg_nos_lixia:loseHp"] = "失去1点体力",
	["heg_nos_lixia"] = "礼下",
  	[":heg_nos_lixia"] = "其他角色的准备阶段，其可以弃置你装备区内的一张牌，若你以此法被弃置过牌，其选择：1.弃置两张牌；2.失去1点体力；3.令你摸两张牌。",
	["heg_nos_biluan"] = "避乱",
  	[":heg_nos_biluan"] = "锁定技，其他角色计算与你的距离+X（X为你装备区内的牌数且最少为1）。",

	["heg_tangzi"] = "唐咨-国",
    ["&heg_tangzi"] = "唐咨",
    ["#heg_tangzi"] = "得时识风",
    ["~heg_tangzi"] = "",
    ["designer:heg_tangzi"] = "荼蘼（韩旭）",
    ["cv:heg_tangzi"] = "",
    ["illustrator:heg_tangzi"] = "凝聚永恒",
	["heg_xingzhao"] = "兴棹",
  	[":heg_xingzhao"] = "锁定技，若场上受伤角色的势力数为：1个或以上，你拥有技能“恂恂”；2个或以上，你受到伤害后，你与伤害来源手牌数较少的角色摸一张牌；3个或以上，你的手牌上限+4；4个或以上，你失去装备区内的牌时，摸一张牌。",

	["heg_dongzhao"] = "董昭-国",
    ["&heg_dongzhao"] = "董昭",
    ["#heg_dongzhao"] = "移尊易鼎",
    ["~heg_dongzhao"] = "",
    ["designer:heg_dongzhao"] = "逍遥鱼叔",
    ["cv:heg_dongzhao"] = "",
    ["illustrator:heg_dongzhao"] = "小牛",
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
	["heg_qiance"] = "谦策",
  	[":heg_qiance"] = "一名角色使用锦囊牌指定目标后，你可令其中的大势力角色不能响应此牌。",
	["heg_jujian"] = "举荐",
  	[":heg_jujian"] = "一名角色进入濒死阶段时，你可令其将体力回复至1点，然后你变更武将牌。",

	["heg_wujing"] = "吴景-国",
    ["&heg_wujing"] = "吴景",
    ["#heg_wujing"] = "汗马鎏金",
    ["~heg_wujing"] = "",
    ["designer:heg_wujing"] = "逍遥鱼叔",
    ["cv:heg_wujing"] = "",
    ["illustrator:heg_wujing"] = "小牛",
  	["heg_diaogui"] = "调归",
  	[":heg_diaogui"] = "出牌阶段限一次，你可将一张装备牌当【调虎离山】使用，然后若你的势力形成队列，则你摸X张牌（X为此队列中的角色数）。",
	["heg_fengyang"] = "风扬",
  	[":heg_fengyang"] = "当你处于队列时，你装备区内的牌被其他角色弃置或获得时，取消之。",
	--TODO
	
	["heg_yanbaihu"] = "严白虎-国",
    ["&heg_yanbaihu"] = "严白虎",
    ["#heg_yanbaihu"] = "豺牙落涧",
    ["~heg_yanbaihu"] = "",
    ["designer:heg_yanbaihu"] = "逍遥鱼叔",
    ["cv:heg_yanbaihu"] = "",
    ["illustrator:heg_yanbaihu"] = "",	
	["heg_zhidao"] = "雉盗",
	[":heg_zhidao"] = "锁定技，出牌阶段开始时，你选择一名其他角色，你于此回合内：1.使用牌仅能指定你或其为目标；2.计算与其距离为1；3.首次对其造成伤害后，获得其区域内一张牌。",
	["heg_jilix"] = "寄篱",
  	[":heg_jilix"] = "锁定技，①当你成为红色基本牌或红色普通锦囊牌的唯一目标后，你令此牌结算两次；②当你于一回合内第二次受到伤害时，你移除此武将牌，防止之。",
	
	["heg_wenqin"] = "文钦-国",
    ["&heg_wenqin"] = "文钦",
    ["#heg_wenqin"] = "勇而无算",
    ["~heg_wenqin"] = "",
    ["designer:heg_wenqin"] = "逍遥鱼叔",
    ["cv:heg_wenqin"] = "",
    ["illustrator:heg_wenqin"] = "匠人绘-零二",		
	["@heg_jinfa"] = "矜伐：交给 %src 一张装备牌或令%src获得你一张牌",
	["heg_jinfa"] = "矜伐",
  	[":heg_jinfa"] = "出牌阶段限一次，你可弃置一张牌并选择一名其他角色，令其选择一项：1.令你获得其一张牌；2.交给你一张装备牌，若此装备牌为♠，其视为对你使用一张【杀】。",
	
	["heg_xiahouba"] = "夏侯霸-国",
    ["&heg_xiahouba"] = "夏侯霸",
    ["#heg_xiahouba"] = "棘途壮志",
    ["~heg_xiahouba"] = "",
    ["designer:heg_xiahouba"] = "逍遥鱼叔",
    ["cv:heg_xiahouba"] = "",
    ["illustrator:heg_xiahouba"] = "小牛",		
	["@heg_baolie_slash"] = "豹烈：对 %src 使用一张【杀】否则%src弃置你一张牌",
	["@heg_baolie"] = "豹烈：请选择“豹烈”的目标角色",
	["heg_baolie"] = "豹烈",
  	[":heg_baolie"] = "锁定技，①出牌阶段开始时，你选择攻击范围内含有你的任意名角色依次对你使用一张【杀】，否则你弃置其一张牌。②你对体力值不小于你的角色使用【杀】无距离与次数限制。",
	
	["heg_xuyou"] = "许攸-国",
    ["&heg_xuyou"] = "许攸",
    ["#heg_xuyou"] = "毕方矫翼",
    ["~heg_xuyou"] = "",
    ["designer:heg_xuyou"] = "逍遥鱼叔",
    ["cv:heg_xuyou"] = "",
    ["illustrator:heg_xuyou"] = "猎枭",	
	["heg_chenglue-invoke"] = "你可以发动“成略”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["heg_chenglue"] = "成略",
  	[":heg_chenglue"] = "当一名角色使用多目标的牌结算后，你可令其摸一张牌。若你受到过此牌造成的伤害，你可令一名没有国战标记的角色获得一个“阴阳鱼”标记<img src=\"image/mark/@heg_yinyangyu.png\">。",
	["heg_shicai"] = "恃才",
  	[":heg_shicai"] = "锁定技，当你受到伤害后，若此伤害为1点，你摸一张牌，否则你弃置两张牌。",

	["heg_sufei"] = "苏飞-国",
    ["&heg_sufei"] = "苏飞",
    ["#heg_sufei"] = "诤友投明",
    ["~heg_sufei"] = "",
    ["designer:heg_sufei"] = "逍遥鱼叔",
    ["cv:heg_sufei"] = "",
    ["illustrator:heg_sufei"] = "Domi",
	["heg_lianpian-invoke"] = "你可以发动“联翩”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["heg_lianpian:discard"] = "弃置%src的一张牌",
	["heg_lianpian:recover"] = "令%src回复1点体力",
	["heg_lianpian"] = "联翩",
  	[":heg_lianpian"] = "结束阶段，若你于此回合内弃置任意角色牌的总数大于你的体力值，你可以令一名角色将手牌摸至体力上限。其他角色的结束阶段，若其于此回合内弃置任意角色牌的总数大于你的体力值，其可以弃置你的一张牌或令你回复1点体力。",

	["heg_panjun"] = "潘濬-国",
    ["&heg_panjun"] = "潘濬",
    ["#heg_panjun"] = "逆鳞之砥",
    ["~heg_panjun"] = "",
    ["designer:heg_panjun"] = "逍遥鱼叔",
    ["cv:heg_panjun"] = "",
    ["illustrator:heg_panjun"] = "Domi",
	["heg_congcha-invoke"] = "你可以发动“聪察”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["heg_congcha"] = "聪察",
  	[":heg_congcha"] = "①<font color=\"green\"><b>每名角色限一次，</b></font>准备阶段，你可选择一名角色，然后直到你的下回合开始限一次，其受到伤害后，其可以令你与其各摸两张牌；否则其失去1点体力。②摸牌阶段，你若没有使用①，你可多摸两张牌。",

	["heg_pengyang"] = "彭羕-国",
    ["&heg_pengyang"] = "彭羕",
    ["#heg_pengyang"] = "误身的狂士",
    ["~heg_pengyang"] = "",
    ["designer:heg_pengyang"] = "韩旭",
    ["cv:heg_pengyang"] = "",
    ["illustrator:heg_pengyang"] = "匠人绘-零一",	
	["heg_jinxian"] = "近陷",
  	[":heg_jinxian"] = "限定技，回合开始时或当你受到伤害时，你可以令所有你计算距离不大于1的角色执行：其弃置两张牌。",
	["heg_tongling-invoke"] = "你可以发动“通令”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["@heg_tongling"] = "通令：对%src使用一张牌",
	["heg_tongling"] = "通令",
  	[":heg_tongling"] = "出牌阶段限一次，当你对其他角色造成伤害后，你可令一名角色对其使用一张牌，然后若此牌：造成伤害，你与其各摸两张牌；未造成伤害，其获得你对其造成伤害的牌。",
	
	["heg_nos_pengyang"] = "彭羕-国[旧]",
    ["&heg_nos_pengyang"] = "彭羕",
    ["#heg_nos_pengyang"] = "误身的狂士",
    ["~heg_nos_pengyang"] = "",
    ["designer:heg_nos_pengyang"] = "韩旭",
    ["cv:heg_nos_pengyang"] = "",
    ["illustrator:heg_nos_pengyang"] = "匠人绘-零一",
	["@heg_nos_daming-thunder_slash"] = "达命：令当前回合角色视为对你选择的另一名角色使用一张雷【杀】",
	["@heg_nos_daming"] = "达命：你可以弃置一张锦囊牌",
	["heg_nos_daming_slash"] = "达命",
	["heg_nos_daming"] = "达命",
  	[":heg_nos_daming"] = "一名角色出牌阶段开始时，你可以弃置一张锦囊牌，横置一名角色并摸X张牌（X为有横置角色的势力数），然后选择一项：1.视为对当前回合角色使用一张【桃】；2.令当前回合角色视为对你选择的另一名角色使用一张雷【杀】。",
	["heg_nos_xiaoni"] = "嚣逆",
  	[":heg_nos_xiaoni"] = "锁定技，当你使用牌指定目标或成为牌的目标后，若场上有与你势力相同的其他角色且这些角色手牌数均不大于你，目标角色不能响应此牌。",

	["heg_zhuling"] = "朱灵-国",
    ["&heg_zhuling"] = "朱灵",
    ["#heg_zhuling"] = "五子之亚",
    ["~heg_zhuling"] = "",
    ["designer:heg_zhuling"] = "",
    ["cv:heg_zhuling"] = "",
    ["illustrator:heg_zhuling"] = "YanBai",
	["@heg_juejue"] = "决绝：将%src张手牌置入弃牌堆或受到1点伤害",
	["heg_juejue"] = "决绝",
  	[":heg_juejue"] = "①弃牌阶段开始时，你可失去1点体力，若如此做，此阶段结束时，若你于此阶段内弃置过牌，你令所有其他角色选择一项：1.将X张手牌置入弃牌堆；2.受到你造成的1点伤害（X为你于此阶段内弃置的牌数）。",
	["heg_fangyuan-invoke"] = "你可以发动“方圆”<br/> <b>操作提示</b>: 选择一名围攻角色→点击确定<br/>",
	["heg_fangyuan"] = "方圆",
  	[":heg_fangyuan"] = "①若你是围攻角色，此围攻关系中围攻角色手牌上限+1，被围攻角色手牌上限-1。②结束阶段，若你是被围攻角色，你视为对此围攻关系中一名围攻角色使用一张无距离限制的【杀】。",

	["heg_liuba"] = "刘巴-国",
    ["&heg_liuba"] = "刘巴",
    ["#heg_liuba"] = "清河一鲲",
    ["~heg_liuba"] = "",
    ["designer:heg_liuba"] = "逍遥鱼叔",
    ["cv:heg_liuba"] = "",
    ["illustrator:heg_liuba"] = "Mr_Sleeping",
	["heg_tongdu"] = "统度",
  	[":heg_tongdu"] = "一名角色的结束阶段，你可令其摸X张牌（X为其于弃牌阶段弃置的牌数且至多为3）",
	["heg_qingyin"] = "清隐",
 	[":heg_qingyin"] = "限定技，出牌阶段，你可移除此武将牌，然后你令任意角色将体力回复至体力上限。",

	["heg_zhugeke"] = "诸葛恪-国",
    ["&heg_zhugeke"] = "诸葛恪",
    ["#heg_zhugeke"] = "兴家赤族",
    ["~heg_zhugeke"] = "",
    ["designer:heg_zhugeke"] = "逍遥鱼叔",
    ["cv:heg_zhugeke"] = "",
    ["illustrator:heg_zhugeke"] = "猎枭",
	["heg_duwu"] = "黩武",
  	[":heg_duwu"] = "限定技，出牌阶段，你可以选择一个“军令”，你对你攻击范围内任意角色发起此“军令”，若其不执行，你对其造成1点伤害并摸一张牌。此“军令”结算后，若存在进入濒死状态被救回的角色，你失去1点体力。",

	["heg_huangzu"] = "黄祖-国",
    ["&heg_huangzu"] = "黄祖",
    ["#heg_huangzu"] = "遮山扼江",
    ["~heg_huangzu"] = "",
    ["designer:heg_huangzu"] = "逍遥鱼叔",
    ["cv:heg_huangzu"] = "",
    ["illustrator:heg_huangzu"] = "YanBai",
	["@heg_xishe"] = "袭射：你可以弃置一张装备区内的牌，视为对 %src 使用一张【杀】",
	["heg_xishe"] = "袭射",
  	[":heg_xishe"] = "其他角色的准备阶段，你可以弃置一张装备区内的牌，视为对其使用一张【杀】（体力值小于你的角色不能响应），然后你可以重复此流程。此回合结束时，若你以此法杀死了一名角色，你可以变更武将牌且变更后的武将牌处于暗置状态。 ",

	["heg_simazhao"] = "司马昭-国",
    ["&heg_simazhao"] = "司马昭",
    ["#heg_simazhao"] = "嘲风开天",
    ["~heg_simazhao"] = "",
    ["designer:heg_simazhao"] = "韩旭",
    ["cv:heg_simazhao"] = "",
    ["illustrator:heg_simazhao"] = "凝聚永恒",
	["heg_suzhi"] = "夙智",
  	[":heg_suzhi"] = "锁定技，你的回合内：1.你执行【杀】或【决斗】的效果而造成伤害时，此伤害+1；2.你使用锦囊牌时摸一张牌且无距离限制；3.其他角色的牌被弃置后，你获得其一张牌。当你于一回合内触发上述效果三次后，此技能于此回合内失效。回合结束时，你获得“反馈”直至回合开始。",
	["heg_zhaoxin"] = "昭心",
  	[":heg_zhaoxin"] = "当你受到伤害后，你可展示所有手牌，然后与一名手牌数不大于你的角色交换手牌。",
	["heg_zhaoxin-invoke"] = "你可以发动“昭心”<br/> <b>操作提示</b>: 选择一名手牌数不大于你的角色→点击确定<br/>",

	["heg_zhonghui"] = "钟会-国",
    ["&heg_zhonghui"] = "钟会",
    ["#heg_zhonghui"] = "桀骜的野心家",
    ["~heg_zhonghui"] = "",
    ["designer:heg_zhonghui"] = "韩旭",
    ["cv:heg_zhonghui"] = "",
    ["illustrator:heg_zhonghui"] = "磐蒲",
	["heg_quanji_power"] = "权",
	["heg_quanji"] = "权计",
  	[":heg_quanji"] = "<font color=\"green\"><b>每回合各限一次，</b></font>当你受到伤害或造成伤害后，你可摸一张牌，然后将一张牌置于武将牌上，称为“权”；你的手牌上限+X（X为“权”的数量）。",
	["heg_paiyi"] = "排异",
  	[":heg_paiyi"] = "出牌阶段限一次，你可将一张“权”置入弃牌堆并选择一名角色，其摸X张牌，若其手牌数大于你，你对其造成1点伤害（X为“权”的数量且至多为7）。",

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
	["@heg_shilus"] = "嗜戮：你可以弃置至多%src张牌，摸等量的牌",
	["heg_shilus"] = "嗜戮",
  	[":heg_shilus"] = "当一名角色死亡时，你可将其所有武将牌置于你的武将牌旁（称为“戮”），若你为来源，你从剩余武将牌堆额外获得两张“戮”。准备阶段，你可以弃置至多X张牌（X为“戮”数），摸等量的牌。",
  	[":heg_shilus1"] = "当一名角色死亡时，你可将其所有武将牌置于你的武将牌旁（称为“戮”），若你为来源，你从剩余武将牌堆额外获得两张“戮”。准备阶段，你可以弃置至多X张牌（X为“戮”数），摸等量的牌。\
	<font color=\"red\"><b>武将牌：%arg1</b></font>	",
	["heg_xiongnve:start"] = "你可以发动“凶虐”，移去一张“戮”，令你本回合对此“戮”势力角色获得效果",
	["heg_xiongnve:end"] = "你可以发动“凶虐”，移去两张“戮”，然后直到你的下回合，当你受到其他角色造成的伤害时，此伤害-1。",
	["heg_xiongnve:damage"] = "对其造成伤害时，令此伤害+1",
	["heg_xiongnve:obtain"] = "对其造成伤害时，你获得其一张牌",
	["heg_xiongnve:unlimit"] = "对其使用牌无次数限制",
	["heg_xiongnve"] = "凶虐",
  	[":heg_xiongnve"] = "出牌阶段开始时，你可以移去一张“戮”，令你本回合对此“戮”势力角色获得下列效果中的一项：1.对其造成伤害时，令此伤害+1；2.对其造成伤害时，你获得其一张牌；3.对其使用牌无次数限制。出牌阶段结束时，你可以移去两张“戮”，然后直到你的下回合，当你受到其他角色造成的伤害时，此伤害-1。",

	["heg_gongsunyuan"] = "公孙渊-国",
    ["&heg_gongsunyuan"] = "公孙渊",
    ["#heg_gongsunyuan"] = "狡黠的投机者",
    ["~heg_gongsunyuan"] = "",
    ["designer:heg_gongsunyuan"] = "逍遥鱼叔",
    ["cv:heg_gongsunyuan"] = "",
    ["illustrator:heg_gongsunyuan"] = "猎枭",
	["heg_zisui_yi"] = "异",
	["heg_huaiyi-invoke"] = "怀异：你可以获得至多 %src 名角色的各一张牌",
	["heg_huaiyi"] = "怀异",
  	[":heg_huaiyi"] = "出牌阶段限一次，你可展示所有手牌，若其中包含两种颜色，则你弃置其中一种颜色的牌，然后获得至多X名角色的各一张牌（X为你以此法弃置的手牌数）。你将以此法获得的装备牌置于武将牌上，称为“异”。",
	["heg_zisui"] = "恣睢",
  	[":heg_zisui"] = "锁定技，①摸牌阶段，你多摸X张牌；②结束阶段，若X大于你的体力上限，你死亡（X为“异”的数量）。",

	["heg_nos_gongsunyuan"] = "公孙渊-国[旧]",
    ["&heg_nos_gongsunyuan"] = "公孙渊",
    ["#heg_nos_gongsunyuan"] = "狡黠的投机者",
    ["~heg_nos_gongsunyuan"] = "",
    ["designer:heg_nos_gongsunyuan"] = "逍遥鱼叔",
    ["cv:heg_nos_gongsunyuan"] = "",
    ["illustrator:heg_nos_gongsunyuan"] = "猎枭",
	["heg_nos_zisui_yi"] = "异",
	["&heg_nos_zisui_yi"] = "异",
	["heg_nos_huaiyi"] = "怀异",
  	[":heg_nos_huaiyi"] = "出牌阶段限一次，你可以展示所有手牌，若其中包含两种颜色，你弃置其中一种颜色的牌，然后获得至多等同于弃置牌数的其他角色各一张牌，将以此法获得的装备牌置于你的武将牌上，称为“异”。你可以将“异”如手牌般使用或打出。",
	["heg_nos_zisui"] = "恣睢",
  	[":heg_nos_zisui"] = "锁定技，①摸牌阶段，你多摸X张牌；②结束阶段，若X大于你的体力上限，你死亡。（X为“异”的数量）",

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
  	[":heg_shunfu"] = "限定技，出牌阶段，你可以令至多三名其他角色各摸两张牌，然后这些角色依次可以使用一张【杀】（无距离限制且不可被响应）。",
	--TODO

	["heg_zhangchunhua"] = "张春华-国",
    ["&heg_zhangchunhua"] = "张春华",
    ["#heg_zhangchunhua"] = "锋刃染霜",
    ["~heg_zhangchunhua"] = "",
    ["designer:heg_zhangchunhua"] = "",
    ["cv:heg_zhangchunhua"] = "",
    ["illustrator:heg_zhangchunhua"] = "小罗没想好",
	["heg_ejue"] = "扼绝",
  	[":heg_ejue"] = "锁定技，当你使用【杀】对其他势力的角色造成伤害时，此伤害+1。",
    ["heg_shangshi"] = "伤逝",
  	[":heg_shangshi"] = "每名角色的回合结束时，你可以将手牌摸至已损失体力值。",

	["heg_simashi"] = "司马师-国",
    ["&heg_simashi"] = "司马师",
    ["#heg_simashi"] = "睚眦侧目",
    ["~heg_simashi"] = "",
    ["designer:heg_simashi"] = "",
    ["cv:heg_simashi"] = "",
    ["illustrator:heg_simashi"] = "拉布拉卡",
	["heg_yimie"] = "夷灭",
  	[":heg_yimie"] = "锁定技，你的回合内，与处于濒死状态角色势力相同/势力不同的角色不能使用【桃】/可将一张<font color='red'>♥</font>手牌当【桃】对处于濒死状态的角色使用。",
	["heg_ruilve"] = "睿略",
  	[":heg_ruilve"] = "其他角色出牌阶段限一次，其可展示并交给你一张伤害类牌，然后其摸一张牌。",

	["heg_jin_simazhao"] = "司马昭-国",
    ["&heg_jin_simazhao"] = "司马昭",
    ["#heg_jin_simazhao"] = "天下畏威",
    ["~heg_jin_simazhao"] = "",
    ["designer:heg_jin_simazhao"] = "",
    ["cv:heg_jin_simazhao"] = "",
    ["illustrator:heg_jin_simazhao"] = "君桓文化",
	["heg_zhaoran"] = "昭然",
  	[":heg_zhaoran"] = "出牌阶段开始前，你可以摸X张牌（X为4-场上势力数）。",
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
  	[":heg_pojing"] = "出牌阶段限一次，你可以令一名其他角色选择一项：1.令你获得其区域内的一张牌；2.所有其他角色可以令伤害量+1，对其造成等量的伤害。",

	["heg_simaliang"] = "司马亮-国",
    ["&heg_simaliang"] = "司马亮",
    ["#heg_simaliang"] = "蒲牢惊啼",
    ["~heg_simaliang"] = "",
    ["designer:heg_simaliang"] = "",
    ["cv:heg_simaliang"] = "",
    ["illustrator:heg_simaliang"] = "小罗没想好",
	["heg_gongzhi"] = "共执",
  	[":heg_gongzhi"] = "你可以跳过摸牌阶段，任意角色依次摸一张牌，直到共计摸四张牌。",
	["heg_shejus"] = "慑惧",
  	[":heg_shejus"] = "每名角色限一次，当其他角色受到伤害后，其可以令你回复1点体力，然后弃置所有手牌。",

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
  	[":heg_luanchang"] = "限定技，一名角色受到过伤害的回合结束时，你可以令当前回合角色将所有手牌（至少一张）当【万箭齐发】使用。",

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
  	[":heg_ciwei"] = "你的回合内，当其他角色使用牌时，若场上有本回合使用或打出过牌的其他角色，你可以弃置一张牌令此牌无效（取消所有目标）。",
	["heg_caiyuan"] = "才媛",
  	[":heg_caiyuan"] = "锁定技，回合开始时，你摸两张牌；当你受到伤害后，此技能失效，直至你的下个结束阶段开始时。",

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
  	[":heg_shiren"] = "每回合限一次，当一名其他角色受到伤害后，你可以交给其两张牌并摸两张牌。",

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
	--TODO

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
  	[":heg_zhefu"] = "当你于回合外使用或打出基本牌后，你可以观看一名手牌数不小于你的角色的手牌，然后你可以弃置其中一张基本牌。",
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
  	[":heg_zhuanzhan"] = "锁定技，你使用【杀】无距离限制且不能指定未造成过伤害的角色为目标。",
	["heg_xunjim"] = "勋济",
  	[":heg_xunjim"] = "你使用【杀】可以多选择至多两名角色为目标，此【杀】结算结束后，若对所有目标角色均造成伤害，此【杀】不计次数。",


	--金印紫绶
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
    [":heg_huaiyuan"] = "一名角色的准备阶段，你可以令其以下项于本回合数值+1: 1.攻击范围；2.手牌上限；3.使用【杀】的次数上限。",
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
  	[":heg_neiji"] = "出牌阶段开始时，你可以选择一名其他角色，与其同时展示两张手牌，若如此做，你与其依次弃置以此法展示的【杀】，若以此法弃置【杀】的数量：大于1，你与其各摸三张牌；为1，以此法未弃置【杀】的角色视为对以此法弃置【杀】的角色使用一张【决斗】。",

	["heg_bailingyun"] = "柏夫人-国",
    ["&heg_bailingyun"] = "柏夫人",
    ["#heg_bailingyun"] = "玲珑心窍",
    ["~heg_bailingyun"] = "",
    ["designer:heg_bailingyun"] = "",
    ["cv:heg_bailingyun"] = "",
    ["illustrator:heg_bailingyun"] = "小罗没想好",
	["heg_xiace"] = "黠策",
	[":heg_xiace"] = "若当前回合角色有【杀】的剩余使用次数，你可以将一张牌当【无懈可击】使用，并令当前回合角色【杀】的剩余使用次数-1，然后你可以变更武将牌。",
	["heg_limeng"] = "离梦",
  	[":heg_limeng"] = "结束阶段，你可以弃置一张非基本牌并选择场上两名角色，则这些角色分别对另一名角色造成1点伤害。",

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
  	[":heg_yinsha"] = "你可以将所有手牌当【借刀杀人】使用，此牌目标必须使用【杀】或将所有手牌当【杀】使用。",

	["heg_duyu"] = "杜预-国",
    ["&heg_duyu"] = "杜预",
    ["#heg_duyu"] = "文成武德",
    ["~heg_duyu"] = "",
    ["designer:heg_duyu"] = "",
    ["cv:heg_duyu"] = "",
    ["illustrator:heg_duyu"] = "君桓文化",
	["heg_sanchen"] = "三陈",
  	[":heg_sanchen"] = "出牌阶段，对每名角色限一次，你可令一名角色摸三张牌然后弃置三张牌，若其因此弃置了类别相同的牌，此技能这阶段失效。",
	["heg_pozhu"] = "破竹",
  	[":heg_pozhu"] = "准备阶段，你可以将一张牌当【杀】使用，结算后你展示唯一目标一张手牌，若两张牌花色不同，你可以重复此流程。",
	
	["heg_lord_liubei"] = "君刘备-国",
    ["&heg_lord_liubei"] = "君刘备",
    ["#heg_lord_liubei"] = "龙横蜀汉",
    ["~heg_lord_liubei"] = "",
    ["designer:heg_lord_liubei"] = "",
    ["cv:heg_lord_liubei"] = "",
    ["illustrator:heg_lordliubei"] = "",
	["heg_lord_zhangwu"] = "章武",
  	[":heg_lord_zhangwu"] = "锁定技，当【飞龙夺凤】进入弃牌堆或其他角色的装备区后，你获得之。当你失去【飞龙夺凤】前，展示之，然后将此牌置于牌堆底并摸两张牌。",
	["heg_lord_shouyue"] = "授鉞",
	[":heg_lord_shouyue"] = "君主技，你拥有“五虎将大旗”。\
	“五虎将大旗”：存活的<font color=#cc081c><b>蜀势力</b></font>角色的技能按如下规则改动——\
	“武圣”：将“红色牌”改为“任意牌”；\
	“咆哮”：增加描述“你使用的【杀】无视其他角色的防具”；\
	“龙胆”：增加描述“你每发动一次“龙胆”便摸一张牌”；\
	“铁骑”：將“若結果為紅色”改為“若結果不為♤”.；\
	“烈弓”：增加描述“你的攻击范围+1”。",
	["heg_lord_jizhao"] = "激诏",
  	[":heg_lord_jizhao"] = "限定技，当你处于濒死状态时，你可以将手牌补至体力上限，体力回复至2点，失去“授钺”并获得“仁德”。",
	["DragonPhoenix"] = "飞龙夺凤",
	[":DragonPhoenix"] = "装备牌·武器\n\
		攻击范围：2\
			技能：\n" ..
			"1.当【杀】指定目标后，若使用者为你，你可令此目标对应的角色弃置一张牌。\n" ..
			"2.当一名角色因执行你使用的【杀】的效果而受到你造成的伤害而进入濒死状态后，你可获得其一张手牌。\n" ,
	["@dragonphoenix-discard"] = "受到【飞龙夺凤】效果影响，请弃置一张牌",

	["heg_lord_zhangjiao"] = "君张角-国",
    ["&heg_lord_zhangjiao"] = "君张角",
    ["#heg_lord_zhangjiao"] = "时代的先驱",
    ["~heg_lord_zhangjiao"] = "",
    ["designer:heg_lord_zhangjiao"] = "",
    ["cv:heg_lord_zhangjiao"] = "",
    ["illustrator:heg_lord_zhangjiao"] = "",
	["heg_lord_hongfa_Attach"] = "弘法",
	[":heg_lord_hongfa_Attach"] = "与张角势力相同的角色可以将一张“天兵”当【杀】使用或打出。",
	[":heg_lord_hongfa_Attach2"] = "%arg1 势力角色可以将一张“天兵”当【杀】使用或打出。",
	["heg_lord_hongfa"] = "弘法",
  	[":heg_lord_hongfa"] = "君主技，你拥有“黄巾天兵符”。准备阶段，若“黄巾天兵符”上没有牌，你将牌堆顶的X张牌置于“黄巾天兵符”上，称为“天兵”（X为存活<font color=#597359><b>群势力</b></font>角色数）。\
	“黄巾天兵符”：1.当你计算<font color=#597359><b>群势力</b></font>角色数时，每一张“天兵”均可视为一名<font color=#597359><b>群势力</b></font>角色。2.当你失去体力前，你可以改为将一张“天兵”置入弃牌堆。3.与你势力相同的角色可以将一张“天兵”当【杀】使用或打出。",
	["heg_lord_wuxin"] = "悟心",
  	[":heg_lord_wuxin"] = "摸牌阶段开始时，你可以观看牌堆顶的X张牌（X为存活<font color=#597359><b>群势力</b></font>角色数），然后将这些牌以任意顺序置于牌堆顶。",
	["heg_lord_wendao"] = "问道",
  	[":heg_lord_wendao"] = "出牌阶段限一次，你可以弃置一张红色牌，然后从弃牌堆或场上获得【太平要术】。",
	["PeaceSpell"] = "太平要术",
	[":PeaceSpell"] = "装备牌·防具\n\n技能：\n" ..
					"1. 锁定技，当你受到属性伤害时，你防止此伤害。\n" ..
					"2. 锁定技，你的手牌上限＋X（X为与你势力相同的角色数）。\n" ..
					"3. 锁定技，当你失去装备区里的【太平要术】后，若你的体力值大于1，你失去1点体力，然后摸两张牌。\n" ,
	["#PeaceSpellNatureDamage"] = "【<font color=\"yellow\"><b>太平要术</b></font>】的效果被触发，防止了 %from 对 %to 造成的 %arg 点 %arg2 伤害" ,
	["#PeaceSpellLost"] = "%from 失去了装备区中的【<font color=\"yellow\"><b>太平要术</b></font>】，须失去1点体力并摸两张牌" ,

	["heg_lord_sunquan"] = "君孙权-国",
    ["&heg_lord_sunquan"] = "君孙权",
    ["#heg_lord_sunquan"] = "虎踞江东",
    ["~heg_lord_sunquan"] = "",
    ["designer:heg_lord_sunquan"] = "",
    ["cv:heg_lord_sunquan"] = "",
    ["illustrator:heg_lord_sunquan"] = "",
	["heg_lord_jiahe_attach"] = "嘉禾",
	["heg_lord_jiahe_Attach"] = "嘉禾",
	[":heg_lord_jiahe_Attach"] = "出牌阶段限一次，你可以将一张装备牌置于“缘江烽火图”上，称为“烽火”。",
	["heg_lord_jiahe"] = "嘉禾",
  	[":heg_lord_jiahe"] = "君主技，你拥有“缘江烽火图”。\
	“缘江烽火图”：1.每名<font color=#04d01f><b>吴势力</b></font>角色的出牌阶段限一次，其可以将一张装备牌置于“缘江烽火图”上，称为“烽火”。 2.根据“烽火”的数量，所有<font color=#04d01f><b>吴势力</b></font>角色可以于其准备阶段选择并获得其中一个技能直到回合结束：至少一张，“英姿”；至少两张，“好施”；至少三张，“涉猎”；至少四张，“度势”；至少五张，可多选择一个技能。 3.锁定技，当你受到【杀】或锦囊牌造成的伤害后，你将一张“烽火”置入弃牌堆。",
	["heg_lord_lianzi"] = "敛资",
  	[":heg_lord_lianzi"] = "出牌阶段限一次，你可以弃置一张手牌，然后亮出牌堆顶的X张牌（X为吴势力角色装备区里的牌数和“烽火”数之和），获得其中所有与你弃置牌类别相同的牌。若此次获得的牌数大于3，你失去“敛资”并获得“制衡”。",
	["heg_lord_jubao"] = "聚宝",
  	[":heg_lord_jubao"] = "锁定技，你装备区里的宝物牌不能被其他角色获得。结束阶段，若场上或弃牌堆中有【定澜夜明珠】，你摸一张牌，然后获得装备区里有【定澜夜明珠】角色的一张牌。",
	["heg_zhiheng"] = "制衡",
	[":heg_zhiheng"] = "出牌阶段限一次，你可弃置至多X张牌（X为你的体力上限）▶你摸等量的牌。",
	["LuminousPearl"] = "定澜夜明珠",
	[":LuminousPearl"] = "装备牌·宝物\n\n技能：\n" ..
					"1.锁定技，若你未拥有“制衡”，你获得“制衡”；若你拥有不以此法获得的“制衡”，则取消“制衡”牌数限制。\n" ,

	["heg_lord_caocao"] = "君曹操-国",
    ["&heg_lord_caocao"] = "君曹操",
    ["#heg_lord_caocao"] = "凤舞九天",
    ["~heg_lord_caocao"] = "",
    ["designer:heg_lord_caocao"] = "",
    ["cv:heg_lord_caocao"] = "",
    ["illustrator:heg_lord_caocao"] = "",
	["@heg_lord_jianan-discard"] = "建安：你可以弃置一张牌并选择一个技能失效直到你下回合开始，然后获得以下技能之一直到你下回合开始：“突袭”、“巧变”、“骁果”、“节钺”、“断粮”",
	["heg_lord_jianan"] = "建安",
	[":heg_lord_jianan"] = "君主技，你拥有“五子良将纛”。\
	“五子良将纛”：<font color=#087cc9><b>魏势力</b></font>角色的准备阶段，该角色可以弃置一张牌并选择自己一个技能失效直到你下回合开始，然后获得以下技能之一直到你下回合开始：“突袭”、“巧变”、“骁果”、“节钺”、“断粮”。场上角色已有的技能无法选择。",
	["heg_lord_huibian"] = "挥鞭",
  	[":heg_lord_huibian"] = "出牌阶段限一次，你可以选择一名<font color=#087cc9><b>魏势力</b></font>角色和另一名已受伤的<font color=#087cc9><b>魏势力</b></font>角色，你对前者造成1点伤害并令其摸两张牌，然后令后者回复1点体力。",
	["heg_lord_zongyu"] = "总御",
  	[":heg_lord_zongyu"] = "当【六龙骖驾】进入其他角色装备区后，你可以用你装备区里的所有坐骑牌（至少一张）交换【六龙骖驾】；当你使用坐骑牌时，若场上或弃牌堆中有【六龙骖驾】，你将此牌置入你的装备区。",
	["SixDragons"] = "六龙骖驾",
	[":SixDragons"] = "装备牌·坐骑\n\n技能：\n" ..
		"锁定技，你与其他角色距离-1；其他角色与你距离+1；此牌置入你的装备区后，将你装备区其他坐骑牌置入弃牌堆；若此牌在你的装备牌，你不能使用其他坐骑牌且所有角色不能将坐骑牌置入你的装备区。" ,
	["heg_lord_jianan_tuxi"] = "突袭",
	["heg_lord_jianan_qiaobian"] = "巧变",
	["heg_lord_jianan_xiaoguo"] = "骁果",
	["heg_lord_jianan_jieyue"] = "节钺",
	["heg_lord_jianan_duanliang"] = "断粮",
	["head_general"] = "主将",
	["deputy_general"] = "副将",
	["@heg_lord_jianan-choose"] = "请选择一名拥有 建安 的角色",

	["heg_lord_simayi"] = "君司马懿-国",
    ["&heg_lord_simayi"] = "君司马懿",
    ["#heg_lord_simayi"] = "时代的归墟",
    ["~heg_lord_simayi"] = "",
    ["designer:heg_lord_simayi"] = "",
    ["cv:heg_lord_simayi"] = "",
    ["illustrator:heg_lord_simayi"] = "",
	["heg_jiaping"] = "嘉平",
  	[":heg_jiaping"] = "<b><font color='goldenrod'>君主技</font></b>，你拥有“八荒死士令”。<br>#<b>八荒死士令</b>：每轮限一次，晋势力角色可以移除其副将的武将牌并发动以下一个未以此法发动过的技能：“瞬覆”，“奉迎”，“将略”，“勇进”和“乱武”。",
	["heg_guikuang"] = "诡诳",
  	[":heg_guikuang"] = "出牌阶段限一次，你可以选择两名势力各不相同的角色，令这两名角色拼点，然后拼点牌为红色的角色依次对拼点没赢的角色造成1点伤害。",
	["heg_shujuan"] = "舒卷",
  	[":heg_shujuan"] = "锁定技，当每回合【戢鳞潜翼】首次置入弃牌堆或其他角色装备区后，你获得并使用之。",
	["scaly_wings"] = "戢鳞潜翼",
	[":scaly_wings"] = "装备牌·武器\
	攻击范围：X\
	技能：你使用【杀】的结算过程中，你攻击范围内的非目标角色不能使用牌（X为你的已损失的体力值）。",

	["heg_mobile_zhanglu"] = "张鲁-国[手杀]",
    ["&heg_mobile_zhanglu"] = "张鲁",
    ["#heg_mobile_zhanglu"] = "政宽教惠",
    ["~heg_mobile_zhanglu"] = "",
    ["designer:heg_mobile_zhanglu"] = "",
    ["cv:heg_mobile_zhanglu"] = "",
    ["illustrator:heg_mobile_zhanglu"] = "磐蒲",
	["heg_mobile_yishe"] = "义舍",
	["@heg_mobile_bushi"] = "布施：交给%src一张牌并摸两张牌",
	["heg_mobile_bushi"] = "布施",
  	[":heg_mobile_bushi"] = "回合结束时，你获得X枚“义舍”；其他角色的准备阶段，你可以弃1枚“义舍”，然后交给其一张牌并摸两张牌；准备阶段，你弃置Y-2张牌并移去所有“义舍”标记（X为你的体力值，Y为存活角色数-你的体力值）。",
	["@heg_mobile_midao_push"] = "米道：将两张牌置于你的武将牌上，称为“米”",
	["@heg_mobile_midao"] = "请发动“%dest”来修改 %src 的“%arg”判定",
	["heg_mobile_rice"] = "米",
	["heg_mobile_midao"] = "米道",
  	[":heg_mobile_midao"] = "结束阶段，若你没有“米”，你可以摸两张牌，然后将两张牌置于你的武将牌上，称为“米”；当一名角色的判定牌生效前，你可以打出一张“米”替换之。",

	["heg_mobile_xushu"] = "徐庶-国[手杀]",
    ["&heg_mobile_xushu"] = "徐庶",
    ["#heg_mobile_xushu"] = "难为完臣",
    ["~heg_mobile_xushu"] = "",
    ["designer:heg_mobile_xushu"] = "",
    ["cv:heg_mobile_xushu"] = "",
    ["illustrator:heg_mobile_xushu"] = "YanBai",
	["@heg_mobile_zhuhai"] = "诛害：你可以对%src使用一张【杀】",
	["heg_mobile_zhuhai"] = "诛害",
	[":heg_mobile_zhuhai"] = "其他角色的结束阶段，若其本回合造成过伤害，你可以对其使用一张【杀】，此【杀】无视其防具，且当其使用【闪】响应此【杀】后，其弃置一张牌。",
	["heg_mobile_jiancai:change"] = "你可以发动“荐才”，优先从你获知的武将中选择变更武将牌",
	["heg_mobile_jiancai"] = "荐才",
  	[":heg_mobile_jiancai"] = "限定技，每轮开始时，你获知的未登场同势力武将牌增加至X张（X为轮次数的三倍）。当一名角色受到致命伤害时，你可以防止此伤害，然后你变更武将牌，此次变更武将牌你可以优先从你获知的武将中选择。",
  	[":heg_mobile_jiancai1"] = "限定技，每轮开始时，你获知的未登场同势力武将牌增加至X张（X为轮次数的三倍）。当一名角色受到致命伤害时，你可以防止此伤害，然后你变更武将牌，此次变更武将牌你可以优先从你获知的武将中选择。\
	<font color=\"red\"><b>武将牌：%arg1</b></font>	",

	["heg_mobile_zhonghui"] = "钟会-国[手杀]",
    ["&heg_mobile_zhonghui"] = "钟会",
    ["#heg_mobile_zhonghui"] = "桀骜的野心家",
    ["~heg_mobile_zhonghui"] = "",
    ["designer:heg_mobile_zhonghui"] = "韩旭",
    ["cv:heg_mobile_zhonghui"] = "",
    ["illustrator:heg_mobile_zhonghui"] = "磐蒲",
	["heg_mobile_paiyi"] = "排异",
  	[":heg_mobile_paiyi"] = "出牌阶段限两次，你可以移去一张“权”并令一名角色摸两张牌。若其手牌多于你，你对其造成1点伤害。",

	["heg_mobile_lukang"] = "陆抗-国[手杀]",
    ["&heg_mobile_lukang"] = "陆抗",
    ["#heg_mobile_lukang"] = "孤柱扶厦",
    ["~heg_mobile_lukang"] = "",
    ["designer:heg_mobile_lukang"] = "",
    ["cv:heg_mobile_lukang"] = "",
    ["illustrator:heg_mobile_lukang"] = "王立雄",
	["@heg_mobile_keshou-discard"] = "恪守：你可选择两张颜色相同的牌弃置",
	["heg_mobile_keshou"] = "恪守",
  	[":heg_mobile_keshou"] = "当你受到伤害时，你可弃置两张颜色相同的牌，令此伤害值-1，然后你判定，若结果为红色，你摸一张牌。",
	["heg_mobile_zhuwei"] = "筑围",
  	[":heg_mobile_zhuwei"] = "当你的判定结果确定后，你可获得此判定牌，然后你可令当前回合角色手牌上限和使用【杀】的次数上限于此回合内+1。",

	["heg_mobile_huaxiong"] = "华雄-国[手杀]",
    ["&heg_mobile_huaxiong"] = "华雄",
    ["#heg_mobile_huaxiong"] = "魔将",
    ["~heg_mobile_huaxiong"] = "",
    ["designer:heg_mobile_huaxiong"] = "",
    ["cv:heg_mobile_huaxiong"] = "",
    ["illustrator:heg_mobile_huaxiong"] = "",
    ["heg_mobile_yaowu"] = "耀武",
    [":heg_mobile_yaowu"] = "限定技，当你造成伤害后，你可以加2点体力上限并回复2点体力，然后修改“恃勇”。",
    ["heg_mobile_shiyong"] = "恃勇",
    [":heg_mobile_shiyong"] = "锁定技，当你受到伤害后，若对你造成伤害的牌不为红色，你摸一张牌。",
    [":heg_mobile_shiyong2"] = "锁定技，当你受到伤害后，若对你造成伤害的牌不为黑色，伤害来源摸一张牌。",

    ["heg_mobile_liaohua"] = "廖化-国[手杀]",
    ["&heg_mobile_liaohua"] = "廖化",
    ["#heg_mobile_liaohua"] = "历尽沧桑",
    ["~heg_mobile_liaohua"] = "",
    ["designer:heg_mobile_liaohua"] = "",
    ["cv:heg_mobile_liaohua"] = "",
    ["illustrator:heg_mobile_liaohua"] = "",
    ["heg_mobile_dangxian"] = "当先",
    [":heg_mobile_dangxian"] = "锁定技，游戏开始时，你摸一张牌并获得1枚“先驱” <img src=\"image/mark/@heg_xianqu.png\">；回合开始时，你执行一个额外的出牌阶段。",

	["heg_mobile_xiahoushang"] = "夏侯尚-国[手杀]",
    ["&heg_mobile_xiahoushang"] = "夏侯尚",
    ["#heg_mobile_xiahoushang"] = "魏胤前驱",
    ["~heg_mobile_xiahoushang"] = "",
    ["designer:heg_mobile_xiahoushang"] = "",
    ["cv:heg_mobile_xiahoushang"] = "",
    ["illustrator:heg_mobile_xiahoushang"] = "",
    ["@heg_mobile_tanfeng"] = "探锋：你可以弃置一名其他角色区域内的一张牌",
    ["heg_mobile_tanfeng"] = "探锋",
    [":heg_mobile_tanfeng"] = "准备阶段，你可以弃置一名其他角色区域内的一张牌，然后其可以受到你造成的1点火焰伤害，令你跳过一个阶段。",

	["heg_ov_tianyu"] = "田豫-国[海外]",
    ["&heg_ov_tianyu"] = "田豫",
    ["#heg_ov_tianyu"] = "规略明练",
    ["~heg_ov_tianyu"] = "",
    ["designer:heg_ov_tianyu"] = "",
    ["cv:heg_ov_tianyu"] = "",
    ["illustrator:heg_ov_tianyu"] = "",
    ["@heg_ov_zhenxi"] = "震袭：你可以选择一项：1.弃置其一张牌；2.将一张方块/梅花非锦囊牌当【乐不思蜀】/【兵粮寸断】对其使用。",
    ["heg_ov_zhenxi"] = "震袭",
    [":heg_ov_zhenxi"] = "当你使用【杀】指定目标后，你可以选择一项：1.弃置其一张牌；2.将一张方块/梅花非锦囊牌当【乐不思蜀】/【兵粮寸断】对其使用。",
    ["@heg_ov_jiansu"] = "俭素：你可以弃置任意张因此技能明置的手牌，令一名体力值不大于X的角色回复1点体力（X为你以此法弃置的牌数）",
    ["heg_ov_jiansu"] = "俭素",
    [":heg_ov_jiansu"] = "当你于回合外获得牌后，你可以明置这些牌。出牌阶段开始时，你可以弃置任意张因此技能明置的手牌，令一名体力值不大于X的角色回复1点体力（X为你以此法弃置的牌数）。",

	["heg_ov_liufuren"] = "刘夫人-国[海外]",
    ["&heg_ov_liufuren"] = "刘夫人",
    ["#heg_ov_liufuren"] = "酷妒的海棠",
    ["~heg_ov_liufuren"] = "",
    ["designer:heg_ov_liufuren"] = "",
    ["cv:heg_ov_liufuren"] = "",
    ["illustrator:heg_ov_liufuren"] = "",
    ["@heg_ov_zhuidu-beishui"] = "追妒：你可以弃置一张牌发动“背水”",
    ["heg_ov_zhuidu"] = "追妒",
    [":heg_ov_zhuidu"] = "出牌阶段限一次，当你造成伤害时，你可以令受伤角色选择一项：1.此伤害+1；2.弃置装备区里的所有牌（至少一张）；若其为女性角色，则你可以背水：弃置一张牌。",
    ["heg_ov_shigong_gain"] = "示恭：你可以获得刘夫人移除的副将的一个没有技能类型的技能，令其体力回复至体力上限",
    ["heg_ov_shigong"] = "示恭",
    [":heg_ov_shigong"] = "限定技，当你于回合外进入濒死状态时，你可以移除副将，然后令当前回合角色选择一项：1.获得你移除的副将的一个没有技能类型的技能，令你体力回复至体力上限；2.令你体力回复至1点。",

	["heg_tenyear_yanghu"] = "羊祜-国[十周年]",
    ["&heg_tenyear_yanghu"] = "羊祜",
    ["#heg_tenyear_yanghu"] = "制纮同轨",
    ["~heg_tenyear_yanghu"] = "",
    ["designer:heg_tenyear_yanghu"] = "",
    ["cv:heg_tenyear_yanghu"] = "",
    ["illustrator:heg_tenyear_yanghu"] = "",
    ["heg_tenyear_dechao"] = "德劭",
    [":heg_tenyear_dechao"] = "<font color=\"green\"><b>每回合限X次（X为你的体力值），</b></font>当你成为其他角色使用黑色牌的唯一目标后，你可以弃置其一张牌。",
    ["heg_tenyear_mingfa"] = "明伐",
    [":heg_tenyear_mingfa"] = "出牌阶段限一次，你可以选择一名其他角色；该角色的下个回合结束时，若其手牌数小于你，你对其造成1点伤害，并获得其一张手牌，然后若其手牌数不小于你，你将手牌摸至与其相同（至多摸五张）。",

	["heg_tenyear_dengzhi"] = "邓芝-国[十周年]",
    ["&heg_tenyear_dengzhi"] = "邓芝",
    ["#heg_tenyear_dengzhi"] = "绝境的外交家",
    ["~heg_tenyear_dengzhi"] = "",
    ["designer:heg_tenyear_dengzhi"] = "",
    ["cv:heg_tenyear_dengzhi"] = "",
    ["illustrator:heg_tenyear_dengzhi"] = "",
    ["@heg_tenyear_jianliang"] = "简亮：你可以令任意名角色各摸一张牌",
    ["heg_tenyear_jianliang"] = "简亮",
    [":heg_tenyear_jianliang"] = "摸牌阶段开始时，若你的手牌数为全场最少，你可以令任意名角色各摸一张牌。",
    ["heg_tenyear_weimeng"] = "危盟",
    [":heg_tenyear_weimeng"] = "出牌阶段限一次，你可以获得一名其他角色的至多X张手牌，然后交给其等量的牌（X为你的体力值）。<br>◆纵横：将“危盟”描述中的X修改为1。",
    [":heg_tenyear_weimeng2"] = "出牌阶段限一次，你可以获得一名其他角色的至多1张手牌，然后交给其等量的牌。",
	["@heg_tenyear_weimeng-give"] = "危盟：请交给 %src 等量的牌",

	["heg_tenyear_zongyu"] = "宗预-国[十周年]",
    ["&heg_tenyear_zongyu"] = "宗预",
    ["#heg_tenyear_zongyu"] = "九酝鸿胪",
    ["~heg_tenyear_zongyu"] = "",
    ["designer:heg_tenyear_zongyu"] = "",
    ["cv:heg_tenyear_zongyu"] = "",
    ["illustrator:heg_tenyear_zongyu"] = "",
    ["heg_tenyear_chengshang"] = "承赏",
    [":heg_tenyear_chengshang"] = "出牌阶段限一次，当你对其他角色使用的牌结算结束后，若此牌未造成过伤害，你可以获得牌堆中所有与此牌花色点数均相同的牌。若你未因此获得牌，此技能视为未发动过。",

	["heg_tenyear_fengxi"] = "冯熙-国[十周年]",
    ["&heg_tenyear_fengxi"] = "冯熙",
    ["#heg_tenyear_fengxi"] = "东吴苏武",
    ["~heg_tenyear_fengxi"] = "",
    ["designer:heg_tenyear_fengxi"] = "",
    ["cv:heg_tenyear_fengxi"] = "",
    ["illustrator:heg_tenyear_fengxi"] = "",
    ["heg_tenyear_boyan"] = "驳言",
    [":heg_tenyear_boyan"] = "出牌阶段限一次，你可以令一名其他角色将手牌摸至体力上限，然后其本回合不能使用或打出手牌。<br>◆纵横：删去“驳言”描述中的「将手牌摸至体力上限」。",
	[":&heg_tenyear_boyan"] = "本回合不能使用或打出手牌",
    [":heg_tenyear_boyan2"] = "出牌阶段限一次，你可以令一名其他角色本回合不能使用或打出手牌。",

	["heg_tenyear_miheng"] = "祢衡-国[十周年]",
    ["&heg_tenyear_miheng"] = "祢衡",
    ["#heg_tenyear_miheng"] = "狂傲奇人",
    ["~heg_tenyear_miheng"] = "",
    ["designer:heg_tenyear_miheng"] = "",
    ["cv:heg_tenyear_miheng"] = "",
    ["illustrator:heg_tenyear_miheng"] = "",
    ["heg_tenyear_kuangcai"] = "狂才",
    [":heg_tenyear_kuangcai"] = "锁定技，你于回合内使用牌无距离和次数限制。弃牌阶段开始时，若你本回合：未使用过牌，本回合你的手牌上限+1；使用过牌且未造成过伤害，本回合你的手牌上限-1。",        
    ["heg_tenyear_shejian:damage"] = "对%src造成1点伤害",
    ["heg_tenyear_shejian:discard"] = "弃置%src等量牌",
    ["heg_tenyear_shejian"] = "舌剑",
    [":heg_tenyear_shejian"] = "当你成为其他角色使用牌的唯一目标后，你可以弃置所有手牌，然后选择一项：1.弃置其等量牌；2.若没有角色处于濒死状态，对其造成1点伤害。",

	["heg_tenyear_xunchen"] = "荀谌-国[十周年]",
    ["&heg_tenyear_xunchen"] = "荀谌",
    ["#heg_tenyear_xunchen"] = "三公谋主",
    ["~heg_tenyear_xunchen"] = "",
    ["designer:heg_tenyear_xunchen"] = "",
    ["cv:heg_tenyear_xunchen"] = "",
    ["illustrator:heg_tenyear_xunchen"] = "",
    ["heg_tenyear_fenglue"] = "锋略",
    [":heg_tenyear_fenglue"] = "出牌阶段限一次，你可以与一名角色拼点：若你赢，其将区域里的两张牌交给你；若其赢，你交给其一张牌。<br>◆纵横：交换“锋略”描述中的「一张」和「两张」。",
    [":heg_tenyear_fenglue2"] = "出牌阶段限一次，你可以与一名角色拼点：若你赢，其将区域里的一张牌交给你；若其赢，你交给其两张牌。",
    ["heg_tenyear_anyong:losehp"] = "令%src失去1点体力并失去此技能",
    ["heg_tenyear_anyong:discard"] = "令%src弃置两张手牌",
    ["heg_tenyear_anyong"] = "暗涌",
    [":heg_tenyear_anyong"] = "每回合限一次，当一名角色对另一名其他角色造成伤害时，你可以令此伤害值翻倍，然后受伤角色可以令你失去1点体力并失去此技能或令你弃置两张手牌。",
    ["anyong_losehp"] = "令其失去1点体力并失去此技能",
    ["anyong_discard"] = "令其弃置两张手牌",

	["heg_tenyear_nanhualaoxian"] = "南华老仙-国[十周年]",
    ["&heg_tenyear_nanhualaoxian"] = "南华老仙",
    ["#heg_tenyear_nanhualaoxian"] = "仙人指路",
    ["~heg_tenyear_nanhualaoxian"] = "",
    ["designer:heg_tenyear_nanhualaoxian"] = "",
    ["cv:heg_tenyear_nanhualaoxian"] = "",
    ["illustrator:heg_tenyear_nanhualaoxian"] = "",

	["heg_tenyear_lukang"] = "陆抗-国[十周年]",
    ["&heg_tenyear_lukang"] = "陆抗",
    ["#heg_tenyear_lukang"] = "孤柱扶厦",
    ["~heg_tenyear_lukang"] = "",
    ["designer:heg_tenyear_lukang"] = "",
    ["cv:heg_tenyear_lukang"] = "",
    ["illustrator:heg_tenyear_lukang"] = "王立雄",
	["heg_tenyear_zhuwei"] = "筑围",
  	[":heg_tenyear_zhuwei"] = "你的判定牌生效后，若此牌为【杀】或伤害类锦囊牌，你可以获得之，然后你可以令当前回合角色本回合使用【杀】的次数上限+1，手牌上限+1。",

	["heg_fk_zhanglu"] = "张鲁-国[新月]",
    ["&heg_fk_zhanglu"] = "张鲁",
    ["#heg_fk_zhanglu"] = "政宽教惠",
    ["~heg_fk_zhanglu"] = "",
    ["designer:heg_fk_zhanglu"] = "",
    ["cv:heg_fk_zhanglu"] = "",
    ["illustrator:heg_fk_zhanglu"] = "磐蒲",
	["heg_fk_rice"] = "米",
	["heg_fk_bushi"] = "布施",
  	[":heg_fk_bushi"] = "一名角色的结束阶段，若你于此回合内造成或受到过伤害，你可移去一张“米”，令至多X名角色各摸一张牌（X为你的体力上限），以此法摸牌的角色可依次将一张牌置于你武将牌上，称为“米”。",
	["@heg_fk_bushi"] = "布施：你可移去一张“米”",
	["@heg_fk_bushi-put"] = "布施：你可以将一张牌置于 %src 的武将牌上，称为“米”",
    ["@heg_fk_midao"] = "米道：将两张牌置于武将牌上",
    ["@heg_fk_midao-card"] = "请发动“%dest”来修改 %src 的“%arg”判定",
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
	["@heg_true_zhuhai"] = "诛害：你可以对 %src 使用一张【杀】（无距离限制）。",
	[":heg_true_zhuhai"] = "一名其他角色的结束阶段开始时，若该角色本回合造成过伤害，你可以对其使用一张【杀】（无距离限制）。",
	["heg_true_pozhen"] = "破阵",
  	[":heg_true_pozhen"] = "限定技，其他角色的回合开始时，你可以令其本回合不可使用、打出或重铸手牌；若其处于队列或围攻关系中，你可依次弃置此队列或参与围攻关系的其他角色的一张牌。",
	["heg_true_jiancai_change"] = "荐才",
	["heg_true_jiancai"] = "荐才",
  	[":heg_true_jiancai"] = "限定技，一名角色即将受到伤害而进入濒死状态时，你可以防止此伤害，若如此做，你须变更武将牌；与你势力相同的角色变更武将牌时，你可令其额外获得两张备选武将牌。",





}



return {extension_heg, extension_hegbian, extension_hegquan, extension_heglordex, extension_hegpurplecloud, extension_goldenseal, extension_hegol, extension_hegmobile, extension_hegtenyear, extension_hegcard, extension_hegadvantagecard}