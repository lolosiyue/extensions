extension = sgs.Package("playtogether",sgs.Package_CardPack)


sgs.LoadTranslationTable{
["playtogether"]="角色陪玩系统",
["#playtogether"]="角色陪玩系统",
["askPlayTogether"]="请选择陪你玩的角色",
["$ceshi1"]="请选择陪你玩的角色",
["ceshi2"]="嚯哈哈哈哈:家我觉得:好啊666",
["playtogether2"]="陪玩",
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
	local targets =sgs.SPlayerList()
	targets:append(player)
--	room:doAnimate(2,"skill=null:","aa",targets)	
	local names = findPNGFiles()
	table.insert(names,"cancel")
	local choice = room:askForChoice(player,"#playtogether", table.concat(names,"+"),sgs.QVariant(),nil,"askPlayTogether")
	if choice ~= "cancel" then
		
		room:doAnimate(2,"skill=large:"..choice..":","aa",targets)--大图
	end

end

--这一段没啥用
playtogether2Card = sgs.CreateSkillCard{
	name = "playtogether2Card",
	target_fixed = true,
	on_use = function(self, room, source)
		choseSeer(source)
	end
}
playtogether2VS = sgs.CreateZeroCardViewAsSkill{
	name = "playtogether2&",
	view_as = function()
		return playtogether2Card:clone()
	end,
	enabled_at_play = function(self, player)
		return true
	end
}
addToSkills(playtogether2VS)


playtogether = sgs.CreateTriggerSkill{
	name = "#playtogether",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameReady},
	global = true,
	priority = -999,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getState() ~= "robot" then
			local name1 = player:getGeneralName()
			local targets =sgs.SPlayerList()
			targets:append(player)
		--	choseSeer(player)
			room:attachSkillToPlayer(player,"playtogether2")
		--	room:attachSkillToPlayer(player,"playtogether2")
		--	room:doAnimate(2,"skill=danmu:","ceshi2",targets)--大图
		--	room:doAnimate(2,"skill=Animate:"..name1,"yuanshao",targets)--大图
			
		--	room:doAnimate(2,"skill=test:"..name1..":","aa",targets)--骨骼图
		--	room:doAnimate(2,"skill=newAnimation:"..name1..":","aa",targets)--新特效图
		end
	end,
	can_trigger = function(self,target)
		if not table.contains(sgs.Sanguosha:getBanPackages(),"playtogether") and target and  target:getState()~="robot" then 
			return target:isAlive()
		end
	end,
}

addToSkills(playtogether)

local generals = sgs.Sanguosha:getAllGenerals()
for _,name in sgs.qlist(generals) do
	name:addSkill("#playtogether")
end

return extension