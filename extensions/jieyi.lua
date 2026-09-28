-- Source: TODO/HUMAN/extensions/jieyi.lua; V2 room/scenario lifecycle port.
-- The mode ID is namespaced because htms already owns the general/translation jieyi.
--local ListCount = 3
-- Donor mode state is kept per invocation/room; module globals would leak across rooms.

local function assignName(room,role,last_Name,used_Name)
--	room:writeToConsole("身份"..role)
	local last_Name_list = last_Name:split(":")
	local last_Name_Pinyin = last_Name_list[2]
	local last_Name_Hanzi = last_Name_list[1]
	local GeneralList =sgs.Sanguosha:getLimitedGeneralNames()

	local characters = {}

	for _,name in ipairs(GeneralList) do
		--[[
local result = string.match(name,last_Name)
--结果result = AB
if result ~= nil then
    table.insert(characters,name)
end
]]--
		local isOJBK = true
		local fanyi = sgs.Sanguosha:translate(name)
		if string.match(fanyi,last_Name_Hanzi) ==nil then		
			isOJBK = false
		end
		
		local list = name:split("_")
		for i = 1, #list,1 do
			if list[i]:startsWith(last_Name_Pinyin) then 
				if table.contains(used_Name,list[i]) then	
					isOJBK = false 
				else
					table.insert(used_Name,list[i])
				end
				break
			end
		end
		if isOJBK == true then
			table.insert(characters,name)
		end
--[[		local isTrue = false
		local list = name:split("_")
		local n = #list
	--	room:writeToConsole(name.."拆成"..n)
		for i = 1, n,1 do
		--room:writeToConsole(list[i])
			if list[i]:startsWith(last_Name) and not table.contains(used_Name,list[i]) then
				table.insert(used_Name,list[i])
				isTrue = true 
				break
			end
		end
		if isTrue ==true then
			table.insert(characters,name)
		end
		]]--
	end
		--room:writeToConsole("characters"..#characters)
	local players = room:getAllPlayers(true)
	for _,p in sgs.qlist(players) do
		if p:getRole()== role and #characters > 0 then
			local newCharacter = characters[math.random(1,#characters)]
			table.removeOne(characters,newCharacter)
			room:changeHero(p,newCharacter, true, true, false, false)
		end
	end
end

JieYiKill = sgs.CreateRuleSkillV2{
    name = "JieYiKill", events = {sgs.Death}, frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if room:getMode() ~= "human_jieyi" then return end
        local death = data:toDeath()
        -- Death is delivered to all seats; only its victim's dispatch grants the reward.
        if death and death.who and player and player:objectName() == death.who:objectName() and death.damage and death.damage.from then
            return self:objectName(), death.damage.from
        end
    end,
    on_effect = function(self, event, room, player, ctx)
        ctx.owner:drawCards(3 * self:getEffectiveAmount(ctx), self:objectName())
        return false
    end,
}
addToSkills(JieYiKill)

JieYiScenario = sgs.CreateScenario{--创建剧情模式
	name = "human_jieyi",
	expose = true,--身份是否可见
	roles = {
		["lord"]="mobile_zhangfei",
		["loyalist1"] = "liubei",
		["loyalist2"] = "liuyan",
		["loyalist3"] = "liubiao",
		["rebel1"] = "guanyu",
		["rebel2"] = "guanping",
		["rebel3"] = "guanyinping",
		["renegade1"] = "zhangjiao",
		["renegade2"]="zhangchunhua",
	}
}

-- Registered on the existing Scenario, so its native startup and rule order are retained.
JieYiRule = sgs.CreateRuleSkillV2{
    name = "human_jieyi", scenario = JieYiScenario,
    events = {sgs.GameReady, sgs.GameOverJudge, sgs.GameStart}, priority = -3,
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if room:getMode() ~= "human_jieyi" then return end
        if event == sgs.GameReady and room:getTag("jieyiMode"):toBool() then return end
        if event == sgs.GameStart and room:getTag("JieYiAIReady"):toBool() then return end
        return self:objectName(), player or room:getAllPlayers(true):first()
    end,
    on_record = function(self, event, room, player, ctx)
        if room:getMode() == "human_jieyi" and event == sgs.GameOverJudge then
            room:setTag("SkipGameRule", sgs.QVariant(event))
        end
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
		if event==sgs.GameReady then
			local tag = room:getTag("jieyiMode")
			if not tag:toBool() then
				room:setTag("jieyiMode", sgs.QVariant(true))
				for _,p in sgs.list(room:getAlivePlayers())do
					if p:getRole() == "lord" then
					room:setTag("JieYiMode", sgs.QVariant(true))
					room:setTag("SkipNormalDeathProcess", sgs.QVariant(true))
					p:setRole("renegade")
					room:setPlayerProperty(p, "role", sgs.QVariant("renegade"))
					room:updateStateItem()
                -- One invocation owns the three distinct surnames and shared general-name deduplication.
                local last_names = {"刘:liu", "关:guan", "张:zhang"}
                local used_names = {}
                for _, role in ipairs({"rebel", "renegade", "loyalist"}) do
                    local surname = table.remove(last_names, math.random(1, #last_names))
                    assignName(room, role, surname, used_names)
                end
					end
				end
				room:writeToConsole("进入结义模式")
			end
		elseif event==sgs.GameOverJudge then
			local renegadeCount = 0
			local rebelCount = 0
			local loyalistCount = 0
			for _,p in sgs.list(room:getAlivePlayers())do
				if p:getRole() == "rebel" then
					rebelCount = rebelCount+1
				elseif p:getRole() == "renegade" then
					renegadeCount = renegadeCount+1
				elseif p:getRole() == "loyalist" then
					loyalistCount = loyalistCount +1
				end
			end	
			if renegadeCount == 1 and rebelCount ==1 and loyalistCount ==1 then
					local winners ={}

					for _,p in sgs.list(room:getAlivePlayers())do
						table.insert(winners,p:getGeneralName())
						p:setRole("lord")
						room:setPlayerProperty(p, "role", sgs.QVariant("lord"))
					end
					room:doLightbox("$JieYiWin1", 3000)	--特效
					for i=1,3 do
						room:doLightbox(winners[i],1000)
					end
					room:doLightbox("$JieYiWin2", 2000)

					room:gameOver("lord")
				end
				local players = room:getAllPlayers(true)
				if renegadeCount == 0 then
					for _,p in sgs.list(players)do
						if p:getRole() == "renegade" then
							room:revivePlayer(p)
						end
					end
				elseif loyalistCount == 0 then
					for _,p in sgs.list(players)do
						if p:getRole() == "loyalist" then
							room:revivePlayer(p)
						end
					end
				elseif rebelCount == 0 then
					for _,p in sgs.list(players)do
						if p:getRole() == "rebel" then
							room:revivePlayer(p)
						end
					end
				end
		elseif event==sgs.GameStart then
            room:setTag("JieYiAIReady", sgs.QVariant(true))
			for _,p in sgs.list(room:getAlivePlayers())do
				room:resetAI(p)
			end	
		end
        return false
    end,
}
JieYiScenario:setRule(JieYiRule)

sgs.Sanguosha:addScenario(JieYiScenario)


sgs.LoadTranslationTable{
["human_jieyi"]="结义模式",

["$JieYiWin1"]="众所周知，刘关张桃园三结义，指的是",

["$JieYiWin2"]="他们仨结义的故事",



}
