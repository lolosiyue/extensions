extension = sgs.Package("playtogether", sgs.Package_CardPack)

sgs.LoadTranslationTable {
	["playtogether"] = "角色陪玩系统",
	["#playtogether"] = "角色陪玩系统",
	["askPlayTogether"] = "请选择陪你玩的角色",
	["$ceshi1"] = "请选择陪你玩的角色",
	["ceshi2"] = "嚯哈哈哈哈:家我觉得:好啊666",
	["playtogether2"] = "陪玩",
}
function findPNGFiles()
	local cmd = 'dir /b "image\\large\\*.png"'
	local files = {}

	local handle = io.popen(cmd)
	if handle then
		for f in handle:lines() do
			-- 移除.png后缀（包括大小写情况）
			local name_without_ext = f:gsub("%.png$", ""):gsub("%.PNG$", "")
			table.insert(files, name_without_ext)
		end
		handle:close()
	end
	return files
end

function choseSeer(player)
	local room = player:getRoom()
	local targets = sgs.SPlayerList()
	targets:append(player)
	--	room:doAnimate(2,"skill=null:","aa",targets)
	local names = findPNGFiles()
	table.insert(names, "cancel")
	local choice = room:askForChoice(player, "#playtogether", table.concat(names, "+"), sgs.QVariant(), nil, "askPlayTogether")
	if choice ~= "cancel" then
		room:doAnimate(2, "skill=large:" .. choice .. ":", "aa", targets) --大图
	end
end

--这一段没啥用
playtogether2VS = sgs.CreateViewAsSkillV2 {
	name = "playtogether2&",
	n = 0,
	target_mode = sgs.ViewAsSkillV2_NoTarget,
	can_activate = function(skill, request)
		return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	on_effect = function(skill, ctx)
		local source = ctx.invoker or ctx.initiator
		if source then
			choseSeer(source)
		end
	end,
}
addToSkills(playtogether2VS)

playtogether = sgs.CreateTriggerSkillV2 {
	name = "#playtogether",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.GameReady },
	global = true,
	priority = -999,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.GameReady then return false end
		-- 掛技為強制後果（無「可以」）：sys_+_force 標記使 trigger-order 不可取消
		if not table.contains(sgs.Sanguosha:getBanPackages(), "playtogether") and player
			and player:getState() ~= "robot" and player:isAlive() then
			room:addPlayerMark(player, "#playtogether+sys_+_force")
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		room:setPlayerMark(player, "#playtogether+sys_+_force", 0)
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:getState() ~= "robot" then
			local name1 = player:getGeneralName()
			local targets = sgs.SPlayerList()
			targets:append(player)
			--	choseSeer(player)
			room:attachSkillToPlayer(player, "playtogether2")
			--	room:attachSkillToPlayer(player,"playtogether2")
			--	room:doAnimate(2,"skill=danmu:","ceshi2",targets)--大图
			--	room:doAnimate(2,"skill=Animate:"..name1,"yuanshao",targets)--大图

			--	room:doAnimate(2,"skill=test:"..name1..":","aa",targets)--骨骼图
			--	room:doAnimate(2,"skill=newAnimation:"..name1..":","aa",targets)--新特效图
		end
		return false
	end,
}

addToSkills(playtogether)

local generals = sgs.Sanguosha:getAllGenerals()
for _, name in sgs.qlist(generals) do
	name:addSkill("#playtogether")
end

return extension
