
-- 宿敌规则，函数君 
-- version 2.1


function getOEMark(player)
	if player:getMark("@LuaPublicEnemy") > 0 then return nil end
	local number = -1
	for num = 0, 8, 1 do
		if player:getMark("@LuaOldEnemy"..num) > 0 then number = num break end
	end
	if number == -1 then return nil end
	return "@LuaOldEnemy"..number
end

function findMyOE(player, room)
	local mark = getOEMark(player)
	if not mark then return nil end
	local others = player:getAliveSiblings()
	if room then others = room:getOtherPlayers(player) end
	for _,p in sgs.qlist(others) do
		if p:getMark(mark) > 0 then return p end
	end
	return nil
end

function getOEList(player, room)
	local OEs = sgs.PlayerList()
	local others = player:getAliveSiblings()
	if room then
		OEs = sgs.SPlayerList()
		others = room:getOtherPlayers(player)
	end
	local mark = getOEMark(player)
	for _,p in sgs.qlist(others) do
		if mark and p:getMark(mark) > 0 then OEs:append(p) end
		if p:getMark("@LuaPublicEnemy") > 0 then OEs:append(p) end
	end
	return OEs
end


establishOECard = sgs.CreateSkillCard{
	name = "#establishOECard", -- 宿敌关系建立的技能卡
	on_use = function(self, room, source, targets)
		local number
		for num = 8, 0, -1 do
			local numused = false
			for _,p in sgs.qlist(room:getAlivePlayers())do
				if p:getMark("@LuaOldEnemy"..num) ~= 0 then numused = true break end
			end
			if numused == true then continue end
			number = num
		end
		if not getOEMark(source) then source:gainMark("@LuaOldEnemy"..number) end
		if not getOEMark(targets[1]) then targets[1]:gainMark("@LuaOldEnemy"..number) end
		room:cardEffect(self, source, source)
		room:cardEffect(self, source, targets[1])
	end,
	on_effect = function(self, effect)
		effect.to:loseAllMarks("@LuaOldEnemyHermit")
		effect.from:getRoom():setPlayerFlag(effect.to, "OEHermit")
	end,
}

function establishOE(room, source, target)
	local card = establishOECard:clone()
	card:setSkillName("establishOECard")
	room:useCard(sgs.CardUseStruct(card, source, target, false), false)
	return
end

relieveOECard = sgs.CreateSkillCard{
	name = "#relieveOECard", -- 宿敌关系解除的技能卡
	on_use = function(self, room, source, targets)
		local mark = getOEMark(source)
		source:loseAllMarks(mark)
		targets[1]:loseAllMarks(mark)
		room:cardEffect(self, source, source)
		room:cardEffect(self, source, targets[1])
	end
}

function relieveOE(room, player)
	local OldEnemy = findMyOE(player, room)
	if OldEnemy then
		local card = relieveOECard:clone()
		card:setSkillName("relieveOECard")
		room:useCard(sgs.CardUseStruct(card, player, OldEnemy, false), false)
	end
	return
end

function setPublicEnemy(room, player)
	for _,p in sgs.qlist(room:getAlivePlayers()) do
		if p:getMark("@LuaPublicEnemy") > 0 then return end
	end
	player:gainMark("@LuaPublicEnemy")
	return
end












Chu2func = {} --以下为中二相关函数

function Chu2func.getChu2Depths(player) --判断中二度
	return player:getMark("FixedChu2") > 0 and player:getMark("FixedChu2") or math.max(player:getMark("@Chu2") - player:getMark("NoChu2") + player:getMark("ExtraChu2"), 0)
end

function Chu2func.JoinChu2(Splayer) --中二度+1
	Splayer:getRoom():useCard(sgs.CardUseStruct(JoinChu2Card:clone(), Splayer, nil, false), false)
end

function Chu2func.QuitChu2(Splayer) --设置0°中二
	Splayer:getRoom():useCard(sgs.CardUseStruct(QuitChu2Card:clone(), Splayer, nil, false), false)
end

function Chu2func.CanAblution(player) --判断是否有权进行中二仪式
	return Chu2func.getChu2Depths(player) == 0 or player:getMark("Chu2_Xiewang") > 0 or player:hasSkill("xiewang")
end













