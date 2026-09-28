
extension = sgs.Package("Shijia",sgs.Package_CardPack)
extension_more = sgs.Package("ShijiaMore",sgs.Package_CardPack)
local function shijiaMode(room)
    return sgs.Sanguosha:getModeGroup(room:getMode()) == "世家模式"
end
local function shijiaCardsEnabled()
    local banned = sgs.Sanguosha:getBanPackages()
    return not table.contains(banned, "Shijia") and not table.contains(banned, "ShijiaMore")
end
local used_Mode = {"06p","06pd","06pz","07p","08p","08pd","08pz","09p","10p","10pd","10pz"}--可以使用的模式
local CharacterCount=6
--技能暗将
ShijiaAnjiang = sgs.General(extension, "ShijiaAnjiang", "god", 99, true,true,true)
local can_kingdoms = sgs.Sanguosha:getKingdoms()

sgs.LoadTranslationTable{
["Shijia"]="世家模式-基础包",
["ShijiaMore"]="世家模式-进阶包",
["ShijiaAnjiang"]="关闭",
["#ShiJiaStart"]="世家模式",
["WelcomeShijia"]="想要尝试【世家模式】吗？",
["$WelcomeShijiaMode"]="【世家模式】~启动！",
["OK"]="好呀好呀！",
["remove_card"]="移除卡牌",
["#ShiJiaStartDesCription"]="世家模式规则：游戏开始后，除主公外所有角色变成内奸，当主公的回合开始时(第二回合起),若场上没有反贼,则主公和忠臣获得胜利",
["RebellionShijia"]="<s>你想要造反吗？</s><br/>你想要起义吗？",
["#ShiJiaRebel"]="是否起义",
["Rebellion"]="为自由而战！",
["#ShiJiaRebellion"]="那一年，%arg揭竿而起。公然反抗%arg2王朝的统治，史称<font color=\"#FFFF00\">【%arg<b>起义</b>】。",
["LordKillRenegade-invoke"]="你可以令一名内奸变成忠臣",
["#ShijiaChooseCouple"]="配偶",

["RengadeChange"]="反贼投诚",
["TurnRengade"]="投诚！",
["NoTurnRengade"]="鸟他个蛋！",
["AskForTurnRengade"]="新王朝建立，你的选择是......",
["#ShiJiaRengadeChange"]="%arg 前来投诚！",

[":ShijiaChooseCouple"]="回合开始和结束阶段，你可以选择你的一名配偶以副将的形式出现",
["#ShijiaChooseCouple-msg"]="%arg 选择妻妾 %arg2 出战！",
["#ShiJiaKill"]="新王朝建立",

["ShijiaSee"]="查看",
["ShijiaSeeCard"]="查看自己的配偶或孩子",
["shijiasee"]="查看",
[":ShijiaSee"]="你可以查看你的配偶和子嗣。回合开始和结束阶段，你可以选择你的一名配偶以副将的形式出现",
["ShijiaSeeChoice"]="你要看老婆还是看孩子",
["ShijiaLP"]="俺滴老婆",
["ShijiaHZ"]="俺滴娃子",

["#ShijiaLordSkill"]="天子诏令",
["@ShijiaLordSkill-TaoZei"]="你可以对目标角色使用一张【杀】并摸1张牌。",
["ShijiaLordSkillChoice"]="汝为君主，可颁布诏令",
["ShiJiaXuanFei"]="【选妃】：你从X名异性中选择一位为配偶（X为场上非反贼数）",
["ShiJiaChongWen"]="【崇文】：你选择一个势力,该势力的所有角色摸1张牌",
["~ShiJiaTaoZei"]="【讨贼】：你选择一位反贼，所有角色可对其使用一张【杀】并摸1张牌。",
["ShiJiaTaoZei"]="【讨贼】：你选择一位反贼，所有角色可对其使用一张【杀】并摸1张牌。",
["~ShiJiaPingYuan"]="【平冤】：你选择一位死亡角色,将其变为【忠臣】",
["ShiJiaPingYuan"]="【平冤】：你选择一位死亡角色,将其变为【忠臣】",
["~ShiJiaYaoYi"]="【徭役】：其他非【反贼】角色交给你1张牌",
["ShiJiaYaoYi"]="【徭役】：其他非【反贼】角色交给你1张牌",
["#yaoyi"] = "受【徭役】影响,请交给 %src 1张牌",
["LordSkill-TaoZei-invoke"]="请选择【讨贼】对象",
["chongwen"]="崇文",
["choosekingdom"]="选择一个势力",
["#ShijiaLordSkill-msg-xuanfei"]="<b>天子诏令，天子 %arg 现决定选妃</b>",
["#ShijiaLordSkill-msg-taozei-yes"]="<b>天子诏令，天子 %arg 现决定诛讨国贼 %arg2 </b>",
["#ShijiaLordSkill-msg-taozei-no"]="<b>四海寰宇,尽皆臣服 </b>",
["#ShijiaLordSkill-msg-chongwen"]="<b>天子诏令，天子 %arg 现决定大兴文墨</b>",
["#ShijiaLordSkill-msg-pingyuan-yes"]="<b>天子诏令，天子 %arg 现决定为 %arg2 翻案</b>",
["#ShijiaLordSkill-msg-pingyuan-no"]="<b>天下太平,无甚冤屈</b>",
["#ShijiaLordSkill-msg-yaoyi"]="<b>天子诏令，天子 %arg 决定征兵徭役</b>",

["#AddChild-msg"]="%arg 获得子嗣 %arg2",
["#AddCouple-msg"]="%arg 获得配偶 %arg2",
["#RemoveCouple-msg"]="%arg 失去了配偶 %arg2 ",
["#RemoveChild-msg"]="%arg 失去了子嗣 %arg2 ",

["#ShiJiaChildAgain"]="%arg 死亡，%arg 之子 %arg2 子承父业",

}
local shijia = createMode{
	name= "世家模式",
	class = "shijia",
	roles = {"ZNNNNN","ZNNNNNN","ZNNNNNNN","ZNNNNNNNN","ZNNNNNNNNN"},
	skipChooseGeneral = true,
	showRole = true,
}

local isFC = false --判断是否是天才包
if sgs.Sanguosha:getVersion():sub(1, 2) == "66" then 
	isFC = true 
end

function addRule(target)
    local room = target:getRoom()
    -- MingLingZhiZi explicitly grants these rules even outside the Shijia mode.
    target:setTag("ShijiaRuleParticipant", sgs.QVariant(true))
    room:setTag("ShijiaRulesActive", sgs.QVariant(true))
	room:acquireSkill(target,"#ShiJiaRebel")
--	room:acquireSkill(target,"#ShijiaChooseCouple")--这个功能外放了,其他模式也能用
	room:acquireSkill(target,"#ShijiaLordSkill")
--	room:attachSkillToPlayer(target,"ShijiaSee")--这个功能改成在每一次变更时检测
end

--子嗣再战
ShiJiaDeath = sgs.CreateRuleSkillV2{
    name = "ShiJiaDeath", events = {sgs.Death}, priority = -5, frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        -- Families created by the card pack also survive outside its dedicated mode.
        if player and data:toDeath().who == player and (shijiaMode(room)
            or player:getTag("Children"):toString() ~= "" or player:getTag("Couples"):toString() ~= "") then
            return self:objectName(), player
        end
        return ""
    end,
    on_cost = function(self, event, room, player, ctx)
        local children = GetMaleFromStr(player:getTag("Children"):toString())
        ctx.choice = children ~= "" and room:askForGeneral(player, children) or ""
        return true
    end,
    on_effect = function(self, event, room, player, ctx)
        room:changeHero(player, nil, false, false, true, false)
        player:setTag("Couples", sgs.QVariant("")); player:setTag("Children", sgs.QVariant(""))
        if ctx.choice ~= "" then
            local msg = sgs.LogMessage(); msg.type = "#ShiJiaChildAgain"
            msg.arg = player:getGeneralName(); msg.arg2 = ctx.choice; room:sendLog(msg)
            room:revivePlayer(player); room:changeHero(player, ctx.choice, true, true, false, false)
        end
        return false
    end,
}

addToSkills(ShiJiaDeath)

--模式启动
ShiJiaStart = sgs.CreateRuleSkillV2{
    name = "#ShiJiaStart", events = {sgs.GameReady},

    can_trigger = function(self, event, room, player, data)
        if not shijiaMode(room) or room:getTag("ShijiaMode"):toBool() then return "" end
        -- GameReady may be a room event without an actor.
        local decision = player or room:getAllPlayers():first()
        if decision then return self:objectName(), decision end
        return ""
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        if not room:getTag("ShijiaMode"):toBool() then
            room:setTag("ShijiaMode", sgs.QVariant(true)); EnterShijiaMode(room, player)
        end
        return false
    end,
}

ShijiaAnjiang:addSkill(ShiJiaStart)


local allzizhi ={"riyueruhuai","diwangzhixiang","pingpingwuqi","fanfanzhibei","tianshenxiafan","ziqidonglai","bainiaochaofeng"}

sgs.LoadTranslationTable{
["tizhi"]="体质",
["qianli"]="潜力",
["zhongcheng"]="忠诚",
["peiyang"]="请给你的孩子加点",
["zizhi"]="资质",
["#MakeChild-msg1"]="%arg 和 %arg2 有了一个孩子\
正在培育中~~~",
["#MakeChild-msg2"]="%arg 和 %arg2 一个不小心把孩子养死了",
["#MakeChild-msg3"]="天冷了, %arg 和 %arg2 的新孩子偶染风寒,不幸去世",
["#MakeChild-msg4"]="%arg 和 %arg2 的新孩子不小心中暑去世了",
[allzizhi[1]]="日月入怀",
[allzizhi[2]]="帝王之相",
[allzizhi[3]]="平平无奇",
[allzizhi[4]]="泛泛之辈",
[allzizhi[5]]="天神下凡",
[allzizhi[6]]="紫气东来",
[allzizhi[7]]="百鸟朝凤",
}

--造孩子用
function MakeChild(player,couple)
	if player:isMale() then  
		local room =player:getRoom()
		local GeneralList =sgs.Sanguosha:getLimitedGeneralNames()
		local SelectRange={}
		local CoupleGeneral = sgs.Sanguosha:getGeneral(couple)
		local kingdom1 = player:getKingdom()
		local kingdom2 = CoupleGeneral:getKingdom()

		local zizhi = allzizhi[math.random(1,#allzizhi)]--获取资质
	
		local msg = sgs.LogMessage()
		msg.type = "#MakeChild-msg1"
		msg.arg = player:getGeneralName()
		msg.arg2= couple
		room:sendLog(msg) 
		--根据资质进行不同方式的查找
		
		--日月入怀:要双将
		if zizhi == "riyueruhuai" then
			for _,name in ipairs(GeneralList) do--接下来是造娃的条件
				if not isNoticed(name,room) then--首先得是未记录的
					local fanyi = sgs.Sanguosha:translate(name)
					if string.match(fanyi,"＆") ~= nil or string.match(fanyi,"&") ~= nil then		
						table.insert(SelectRange,name)
					end			
				end
			end
		--帝王之相:要主公
		elseif zizhi == "diwangzhixiang" then
			for _,name in ipairs(GeneralList) do--接下来是造娃的条件
				if not isNoticed(name,room) then--首先得是未记录的
					local general = sgs.Sanguosha:getGeneral(name)
					if general:isLord() or string.match(name,"jinyu") ~= nil then
						table.insert(SelectRange,name)
					end			
				end
			end
			
		--天神下凡:要神	
		elseif zizhi =="tianshenxiafan" then
			for _,name in ipairs(GeneralList) do--接下来是造娃的条件
				if not isNoticed(name,room) then--首先得是未记录的
					local general = sgs.Sanguosha:getGeneral(name)
					if general:getKingdom() == "god" then
						table.insert(SelectRange,name)
					end			
				end
			end
			
		--紫气东来:群晋
		elseif zizhi =="ziqidonglai" then
			for _,name in ipairs(GeneralList) do--接下来是造娃的条件
				if not isNoticed(name,room) then--首先得是未记录的
					local general = sgs.Sanguosha:getGeneral(name)
					if general:getKingdom() == "qun" or general:getKingdom() == "jin" then
						table.insert(SelectRange,name)
					end			
				end
			end
	
		--百鸟朝凤:要女
		elseif zizhi =="ziqidonglai" then
			for _,name in ipairs(GeneralList) do--接下来是造娃的条件
				if not isNoticed(name,room) then--首先得是未记录的
					local general = sgs.Sanguosha:getGeneral(name)
					if general:isFemale() then
						table.insert(SelectRange,name)
					end			
				end
			end
		else	--剩下的全部随机
		
			for _,name in ipairs(GeneralList) do--接下来是造娃的条件
				if not isNoticed(name,room) then--首先得是未记录的
						table.insert(SelectRange,name)	
				end
			end
			
		end
		
		
		--加点(不一定准)
		local choice = room:askForChoice(player, "peiyang", "tizhi+qianli+zhongcheng+cancel",sgs.QVariant(),nil,zizhi)
		if choice == "tizhi" then
			for i,name in ipairs(SelectRange) do
				local general = sgs.Sanguosha:getGeneral(name)
				if general:getMaxHp() < 4 then
					table.remove(SelectRange,i)
				end
			end
		elseif choice == "qianli" then
			for i,name in ipairs(SelectRange) do
				local general = sgs.Sanguosha:getGeneral(name)
				if general:getVisibleSkillList():length() < 2 then
					table.remove(SelectRange,i)
				end
			end
		elseif choice == "zhongcheng" then--国籍随父母的一方
			for i,name in ipairs(SelectRange) do
				--room:writeToConsole("正在处理"..name)
				local general = sgs.Sanguosha:getGeneral(name)
				local kingdom = general:getKingdom()
				if kingdom ~= kingdom1 and kingdom ~= kingdom2 then
					table.remove(SelectRange,i)
					--room:writeToConsole("移除"..name)
				end
			end
		elseif choice == "cancel" then
		
		end
			
	
		
		if #SelectRange > 0 then
			local index=math.random(1,#SelectRange)
			local target = SelectRange[index]
			room:writeToConsole(target)
			NoticeHero(target,room)--标记新角色
			AddChild(player,target)
		else
			room:writeToConsole("已无符合条件角色")
			options = {"2","3","4"}
			msg.type = "#MakeChild-msg"..options[math.random(1,#options)]
			room:sendLog(msg) 
		end
	end
end

function isNoticed(name,room)
	local list = room:getTag("used_character"):toString():split("+")
	if not table.contains(list,name) then
		return false
	else
		return true
	end
end

function NoticeHero(name,room)--记录一个武将
	local list = room:getTag("used_character"):toString():split("+")
	if not table.contains(list,name) then
		table.insert(list,name)
	end
	local newstr = table.concat(list,"+")
	room:setTag("used_character",sgs.QVariant(newstr))
end

function AddUpStr(str1,str2)--合并字符串

	local list1 =str1:split("+")
	local list2 = str2:split("+")
	for i=1,#list2,1 do
		if not table.contains(list1,list2[i]) then
			table.insert(list1,list2[i])
		end
	end
	local result = table.concat(list1,"+")

	return result
end

function GetFemaleFromStr(str)--获取一窜字符串武将中的女性字符串
	local list = str:split("+")
	local new = {}
	for i=1,#list,1 do
		if sgs.Sanguosha:getGeneral(list[i]):isFemale() then
			table.insert(new,list[i])
		end
	end
	return table.concat(new,"+")
end

function GetMaleFromStr(str)--获取一窜字符串武将中的男性字符串
	local list = str:split("+")
	local new = {}
	for i=1,#list,1 do
		if sgs.Sanguosha:getGeneral(list[i]):isMale() then
			table.insert(new,list[i])
		end
	end
	return table.concat(new,"+")
end


function NewHero(room,player,male,count)--从武将堆里选择一个新将，返回武将名字
	local GeneralList =sgs.Sanguosha:getLimitedGeneralNames()
	local SelectRange={}
	local targets={}
	for _,name in ipairs(GeneralList) do
		if not isNoticed(name,room) then
			local general = sgs.Sanguosha:getGeneral(name)
			if male == true then
				if general:isMale() then
					table.insert(SelectRange,name)
				end
			elseif male == false then
				if general:isFemale() then
					table.insert(SelectRange,name)
				end
			elseif male == nil then
				table.insert(SelectRange,name)
			end
		end
	end
	for i=1,count,1 do
		local index=math.random(1,#SelectRange)
		table.insert(targets,SelectRange[index])
		table.removeOne(SelectRange,SelectRange[index])
	end
	local target =room:askForGeneral(player,table.concat(targets,"+"))
	NoticeHero(target,room)--标记该角色
	return target
end

function RemoveHero(str,name)--从一个字符串里删除一个武将
	local list = str:split("+")
	table.removeOne(list,name)
	return table.concat(list,"+")
end

function AddHero(str,name)--从字符串里加入一个武将
	local list = str:split("+")
	table.insert(list,name)
	return table.concat(list,"+")
end

function CheckShijiaBtn(player)
	local room =player:getRoom()
	local couples = player:getTag("Couples"):toString():split("+")
	local children = player:getTag("Children"):toString():split("+")
	local count = #couples + #children
	if count > 0 then
		room:attachSkillToPlayer(player,"ShijiaSee")
	else
		room:detachSkillFromPlayer(player,"ShijiaSee")
	end
end

function AddCouple(player,name)--给一名角色增加一个妻子
	if name~="" then
	local room =player:getRoom()
	local couples = player:getTag("Couples"):toString()
	local str = AddHero(couples,name)
	player:setTag("Couples",sgs.QVariant(str))
	
	local all = room:getAllPlayers(true)
	room:doAnimate(4, player:objectName(),name,all)
	
	--记录武将
	NoticeHero(name,room)
		if couples~= str then
	--消息提示
			local msg = sgs.LogMessage()
			msg.type = "#AddCouple-msg"
			msg.arg = player:getGeneralName()
			msg.arg2= name
			room:sendLog(msg) 
		end
	end
	CheckShijiaBtn(player)
end

function RemoveCouple(player,name)--给一名角色删除一个妻子
	if name ~="" then
		local room =player:getRoom()
		NoticeHero(name,room)
		local couples = player:getTag("Couples"):toString()
		local str = RemoveHero(couples,name)
		player:setTag("Couples",sgs.QVariant(str))
	
		if player:getGeneral2Name() == name then
			player:setTag("MaxHp",sgs.QVariant(player:getMaxHp()))
			player:setTag("Hp",sgs.QVariant(player:getHp()))
		
			room:changeHero(player,nil,false, false,true,false)--移除副将
			
			player:setMaxHp(player:getTag("MaxHp"):toInt())
			room:broadcastProperty(player, "maxhp");
			player:setHp(player:getTag("Hp"):toInt())
			room:broadcastProperty(player, "hp");
			
		end
	--消息提示
		if couples~= str then--这里是进行判断移除前和移除后是否一样
			local msg = sgs.LogMessage()
			msg.type = "#RemoveCouple-msg"
			msg.arg = player:getGeneralName()
			msg.arg2= name
			room:sendLog(msg) 
		end
	end
	CheckShijiaBtn(player)
end
function RemoveChild(player,name)--给一名角色删除一个子嗣
	if  name ~="" then
		
		local room= player:getRoom()
		NoticeHero(name,room)
		local children = player:getTag("Children"):toString()
		local str = RemoveHero(children,name)

	--消息提示
		if children ~= str then
			local msg = sgs.LogMessage()
			msg.type = "#RemoveChild-msg"
			msg.arg = player:getGeneralName()
			msg.arg2 = name
			room:sendLog(msg) 
		end
	--room:writeToConsole("子嗣"..str)
		player:setTag("Children",sgs.QVariant(str))
	end
	CheckShijiaBtn(player)
end

function AddChild(player,name)--给一名角色增加一个子嗣
	local room= player:getRoom()
	NoticeHero(name,room)
	local children = player:getTag("Children"):toString()
	local str = AddHero(children,name)
	
	local all = room:getAllPlayers(true)
	room:doAnimate(4, player:objectName(),name,all)
	
	--消息提示
	if children ~= str then
		local msg = sgs.LogMessage()
		msg.type = "#AddChild-msg"
		msg.arg = player:getGeneralName()
		msg.arg2= name
		room:sendLog(msg) 
	end
	--room:writeToConsole("子嗣"..str)
	player:setTag("Children",sgs.QVariant(str))
	CheckShijiaBtn(player)
end

function changeCoupleShow(player, selectedCouple)
	local couples = player:getTag("Couples"):toString()
	local room = player:getRoom()
--	room:writeToConsole(player:getMaxHp())
	player:setTag("MaxHp",sgs.QVariant(player:getMaxHp()))
	player:setTag("Hp",sgs.QVariant(player:getHp()))
	--room:changeHero(player,nil,false, false,true,false)--移除副将
	local couple = selectedCouple
    if couple == nil then couple = room:askForGeneral(player,couples) end
	local oldname = player:getGeneral2Name()
	local max_hp = player:getTag("MaxHp"):toInt()
		local hp = player:getTag("Hp"):toInt()
	if couple~="" and couple ~= oldname then
		room:changeHero(player,couple, false, false,true,false)
		
		--room:writeToConsole(max_hp)

		local msg = sgs.LogMessage()
		msg.type = "#ShijiaChooseCouple-msg"
		msg.arg=player:getGeneralName()
		msg.arg2=couple
		room:sendLog(msg)
	end
	player:setMaxHp(max_hp)
	room:broadcastProperty(player, "maxhp");
	player:setHp(hp)
	room:broadcastProperty(player, "hp");
	CheckShijiaBtn(player)
end

function RebelDraw(player,room)--跳反摸牌
	local players = room:getAlivePlayers()
	local n =0
	for _,p in sgs.qlist(players) do
		if p:getRole()=="rebel" then
			n=n+1
		end
	end
	room:drawCards(player,n,"TiaoFan")
end

function RengadeChange(players,room)--反贼投诚
	for _,p in sgs.qlist(players) do--其余反选择变内
		if p:getRole() =="rebel" and p:isAlive() then
			local choice = room:askForChoice(p, "RengadeChange", "TurnRengade+NoTurnRengade",sgs.QVariant(),nil,"AskForTurnRengade")
			if choice == "TurnRengade" then	
				p:setRole("renegade")
				room:setPlayerProperty(p, "role", sgs.QVariant("renegade"))
					local msg = sgs.LogMessage()
					msg.type = "#ShiJiaRengadeChange"

				msg.arg=p:getGeneralName()
				room:sendLog(msg)
			end							
		elseif p:getRole() =="loyalist" then--忠变内
			p:setRole("renegade")
			room:setPlayerProperty(p, "role", sgs.QVariant("renegade"))
		end
		room:resetAI(p)
	end

end

ShiJiaRebel = sgs.CreateTriggerSkillV2{
    name = "#ShiJiaRebel", events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if not player or not player:isAlive()
            or player:getPhase() ~= sgs.Player_RoundStart or player:getRole() ~= "renegade" then return "" end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getRole() == "lord" then return self:objectName(), player end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, ctx)
        return room:askForChoice(player, self:objectName(), "Rebellion+cancel", sgs.QVariant(), nil, "RebellionShijia") == "Rebellion"
    end,
    on_effect = function(self, event, room, player, ctx)
        player:setRole("rebel"); room:setPlayerProperty(player, "role", sgs.QVariant("rebel")); room:updateStateItem()
        RebelDraw(player, room)
        local msg = sgs.LogMessage(); msg.type = "#ShiJiaRebellion"
        msg.arg = player:getGeneralName(); msg.arg2 = room:getLord():getGeneralName(); room:sendLog(msg)
        return false
    end,
}

ShijiaAnjiang:addSkill(ShiJiaRebel)

-- Inheritance uses a DummyCard move container, not a SkillCard ability shell.
ShiJiaKill = sgs.CreateRuleSkillV2{
    name = "#ShiJiaKill", events = {sgs.Death},
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        local death = data:toDeath()
        if player and death.who == player and (shijiaMode(room) or player:getTag("ShijiaRuleParticipant"):toBool()) then
            return self:objectName(), (death.damage and death.damage.from) or player
        end
        return ""
    end,
    on_cost = function(self, event, room, player, ctx)
        local death = ctx.original_data:toDeath()
        local killer = death.damage and death.damage.from
        ctx.choice = ""
        if killer and killer:getRole() == "lord" and death.who:getRole() == "renegade" then
            local targets = sgs.SPlayerList()
            for _, target in sgs.qlist(room:getAlivePlayers()) do
                if target:getRole() == "renegade" then targets:append(target) end
            end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(killer, targets, self:objectName(), "LordKillRenegade-invoke", true, false)
                if target then ctx.choice = target:objectName() end
            end
        end
        return true
    end,
    on_effect = function(self, event, room, decision, ctx)
        local data = ctx.original_data
        -- The decision maker may be the killer; inheritance and role changes use the victim.
        local player = data:toDeath().who
		local death = data:toDeath()
		if death.who:objectName() ~= player:objectName() then return false end
		local room = player:getRoom()
	--	local tag = room:getTag("ShijiaMode"):toBool()
	--身份变更结算
		if death.damage then
			local killer = death.damage.from
			if killer then
				if killer:getRole() == "renegade" and player:getRole()=="rebel" then--内杀反，变忠臣并摸2张
					killer:setRole("loyalist")
					room:drawCards(killer,2,self:objectName())
					room:setPlayerProperty(killer, "role", sgs.QVariant("loyalist"))
				elseif killer:getRole() == "lord" and player:getRole()=="loyalist" then--主杀忠，其他忠变内
					local players = room:getOtherPlayers(player,false)
					for _,p in sgs.qlist(players) do
						if p:getRole() =="loyalist" then
							p:setRole("renegade")
							room:setPlayerProperty(p, "role", sgs.QVariant("renegade"))	
						end
					end
				elseif killer:getRole() == "loyalist" and player:getRole()=="rebel" then--忠杀反摸3张
					room:drawCards(killer,3,self:objectName())
				elseif killer:getRole() == "lord" and player:getRole()=="rebel" then--主杀反摸3张
					room:drawCards(killer,3,self:objectName())	 
				elseif killer:getRole() == "lord" and player:getRole()=="renegade" then--主杀内，选一名其他内变忠臣
                    local target = ctx.choice ~= "" and room:findPlayerByObjectName(ctx.choice) or nil
                    if target then
                        target:setRole("loyalist")
                        room:setPlayerProperty(target, "role", sgs.QVariant("loyalist"))
                    end

				elseif killer:getRole() == "renegade" and player:getRole()=="renegade" then--内杀内获取对方所有牌
					local cards = player:getCards("he")
					if cards:length() > 0 then
						local allcard = sgs.DummyCard()
						for _,card in sgs.qlist(cards) do
							allcard:addSubcard(card)
						end
						room:obtainCard(killer, allcard)
                        allcard:deleteLater()
					end
				elseif killer:getRole() == "rebel" and player:getRole()=="rebel" then--反杀反获取对方所有牌
					local cards = player:getCards("he")
					if cards:length() > 0 then
						local allcard = sgs.DummyCard()
						for _,card in sgs.qlist(cards) do
							allcard:addSubcard(card)
						end
						room:obtainCard(killer, allcard)
                        allcard:deleteLater()
					end
				--elseif killer:getRole() == "rebel" and player:getRole()=="lord" then--反杀主身份互换，朝代更迭
				elseif player:getRole()=="lord" then
					killer:setRole("lord")
					room:setPlayerProperty(killer, "role", sgs.QVariant("lord"))--凶手变主
					--local players = room:getPlayers()
					local players = room:getAlivePlayers()
					RengadeChange(players,room)--反贼投诚，忠臣变内
					
					player:setRole("rebel")--主变反
					room:setPlayerProperty(player, "role", sgs.QVariant("rebel"))
					
					
				end
				
				room:updateStateItem()
			end		
		end
	
		

	return false
    end,
}


ShijiaAnjiang:addSkill(ShiJiaKill)



-- ShijiaSee uses the native V2 ActiveSkillCard custom action.
ShijiaSeeVS = sgs.CreateViewAsSkillV2{
    name = "ShijiaSee&", n = 0, target_mode = sgs.ViewAsSkillV2_NoTarget,
    can_activate = function(self, request)
        local player = request:getInitiator()
        return player and player:isAlive() and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
    end,
    cost = function(self, room, ctx, request)
        ctx.choice = ctx.invoker:getRoom():askForChoice(ctx.invoker, "ShijiaSeeCard", "ShijiaLP+ShijiaHZ+cancel", sgs.QVariant(), nil, "ShijiaSeeChoice")
        return ctx.choice ~= "cancel"
    end,
    on_effect = function(self, ctx)
        local source = ctx.invoker
        local names = source:getTag(ctx.choice == "ShijiaLP" and "Couples" or "Children"):toString():split("+")
        table.insert(names, "ShijiaAnjiang")
        source:getRoom():askForGeneral(source, table.concat(names, "+"))
        return sgs.ViewAsSkillV2_FinishSkill
    end,
}


ShijiaAnjiang:addSkill(ShijiaSeeVS)



ShijiaChooseCouple = sgs.CreateRuleSkillV2{
    name = "#ShijiaChooseCouple", events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and (player:getPhase() == sgs.Player_RoundStart or player:getPhase() == sgs.Player_Finish) then
            return self:objectName(), player
        end
        return ""
    end,
    on_cost = function(self, event, room, player, ctx)
        local couples = player:getTag("Couples"):toString()
        ctx.choice = couples ~= "" and room:askForGeneral(player, couples) or ""
        return true
    end,
    on_effect = function(self, event, room, player, ctx)
        changeCoupleShow(player, ctx.choice)
        return false
    end,
}

ShijiaAnjiang:addSkill(ShijiaChooseCouple)

ShijiaLordSkill = sgs.CreateTriggerSkillV2{
    name = "#ShijiaLordSkill", events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:getRole() == "lord"
            and player:getPhase() == sgs.Player_RoundStart then return self:objectName(), player end
        return ""
    end,
    on_cost = function(self, event, room, player, ctx)
			--确认能用指令
				local allCommand = {"ShiJiaXuanFei","ShiJiaChongWen"}--主公能用指令
				local yuxi = player:getTreasure()
				if yuxi and yuxi:isKindOf("ChuanShiYuXi") then--玉玺加指令
					table.insert(allCommand,"ShiJiaTaoZei")--讨贼
					table.insert(allCommand,"ShiJiaPingYuan")--平冤
					table.insert(allCommand,"ShiJiaYaoYi")--徭役
				else 
					table.insert(allCommand,"~ShiJiaTaoZei")--讨贼
					table.insert(allCommand,"~ShiJiaPingYuan")--平冤
					table.insert(allCommand,"~ShiJiaYaoYi")--徭役
				end
			--	table.insert(allCommand,"cancel")
				
			ctx.choice = room:askForChoice(player, self:objectName(), table.concat(allCommand,"+"),sgs.QVariant(),nil,"ShijiaLordSkillChoice")
        if ctx.choice == "ShiJiaChongWen" then
            ctx.extra_data = sgs.QVariant(room:askForChoice(player, "chongwen", table.concat(can_kingdoms, "+"), sgs.QVariant(), nil, "choosekingdom"))
        elseif ctx.choice == "ShiJiaTaoZei" then
            local targets = sgs.SPlayerList()
            for _, target in sgs.qlist(room:getAlivePlayers()) do
                if target:getRole() == "rebel" then targets:append(target) end
            end
            ctx.extra_data = sgs.QVariant(not targets:isEmpty())
            if not targets:isEmpty() then
                ctx.preferredTarget = room:askForPlayerChosen(player, targets, self:objectName(), "LordSkill-TaoZei-invoke", true, false)
            end
        elseif ctx.choice == "ShiJiaPingYuan" then
            local names = {}
            for _, target in sgs.qlist(room:getAllPlayers(true)) do
                if not target:isAlive() and target:getRole() ~= "loyalist" then table.insert(names, target:getGeneralName()) end
            end
            ctx.extra_data = sgs.QVariant(#names > 0 and room:askForGeneral(player, table.concat(names, "+")) or "")
        end
        return ctx.choice ~= "cancel"
    end,
    on_effect = function(self, event, room, player, ctx)
		if player:getPhase() == sgs.Player_RoundStart and player:getRole()=="lord" then	
			local room = player:getRoom()
			local choice = ctx.choice
			local msg = sgs.LogMessage()	
				msg.arg=player:getGeneralName()
			if choice =="ShiJiaXuanFei" then--选妃
				msg.type = "#ShijiaLordSkill-msg-xuanfei"
				room:sendLog(msg)
				local n = 0
				local players = room:getAlivePlayers()
				for _,p in sgs.qlist(players) do
					if p:getRole()~="rebel" then
						n=n+1
					end
				end
				local couple = NewHero(room,player,false,n)
				AddCouple(player,couple)
			elseif choice =="ShiJiaChongWen" then --崇文
				msg.type = "#ShijiaLordSkill-msg-chongwen"
				room:sendLog(msg)
				local kingdom = ctx.extra_data:toString()
				local players = room:getAlivePlayers()
				for _,p in sgs.qlist(players) do
					if p:getKingdom() == kingdom then
						p:drawCards(1)
					end
				end
			elseif choice  =="ShiJiaTaoZei" then--讨贼
				
                local players = room:getAlivePlayers()
                if ctx.extra_data:toBool() then
                    local target = ctx.preferredTarget
					if target then
						msg.type = "#ShijiaLordSkill-msg-taozei-yes"
						msg.arg2 = target:getGeneralName()
						room:sendLog(msg)
						for _,p in sgs.qlist(players) do
							if p:canSlash(target) then
							
								if room:askForUseSlashTo(p,target, "@ShijiaLordSkill-TaoZei" ) then
									p:drawCards(1)
								end
							end
						end
						
					end
				else
					msg.type = "#ShijiaLordSkill-msg-taozei-no"
					room:sendLog(msg)
				--	room:writeToConsole("列表为空")
				end
			elseif choice  =="ShiJiaPingYuan" then--平冤
                local targetName = ctx.extra_data:toString()
                if targetName ~= "" then
                    msg.type = "#ShijiaLordSkill-msg-pingyuan-yes"
					msg.arg2 = targetName
					local  target = room:findPlayer(targetName,true)
					target:setRole("loyalist")
					room:setPlayerProperty(target, "role", sgs.QVariant("loyalist"))
					
				else
					msg.type = "#ShijiaLordSkill-msg-pingyuan-no"
					--如果没人
				end
				room:sendLog(msg)
			elseif choice  =="ShiJiaYaoYi" then--徭役
				local players = room:getOtherPlayers(player)
				for _,p in sgs.qlist(players) do
					if p:isAlive() and p:getRole() ~="rebel" then
						--给牌
						local card = room:askForExchange(p, self:objectName(), 1, 1, true, "#yaoyi:".. player:getGeneralName())
							if card then
								room:obtainCard(player, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName(), p:objectName(), self:objectName(), ""), false)
							end
					end
				end
				msg.type = "#ShijiaLordSkill-msg-yaoyi"
				room:sendLog(msg)
			end
		end
        return false
    end,
}

ShijiaAnjiang:addSkill(ShijiaLordSkill)



ShijiaLordWin = sgs.CreateRuleSkillV2{
    name = "#ShijiaLordWin", events = {sgs.TurnStart},

    can_trigger = function(self, event, room, player, data)
        -- Donor SkipNormalWin accepts every death once the rules are installed.
        -- Keep its replacement victory rule active for the same whole-room lifetime.
        if player and player:isAlive() and (shijiaMode(room) or room:getTag("ShijiaRulesActive"):toBool()) then return self:objectName(), player end
        return ""
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
		local room = player:getRoom()
		local TurnCount=player:getMark("Global_TurnCount")
		local players = room:getAlivePlayers()
		--正常结局：主公结束，主忠胜利
		if TurnCount > 0 and player:getRole()=="lord" then
			local canWin =true
			for _,p in sgs.qlist(players) do
				if p:getRole() =="rebel" then
					canWin = false
				end
			end
			if canWin==true then
				local list = {}
				for _,p in sgs.qlist(players) do
					if p:getRole() == "lord" or  p:getRole() == "loyalist" then
						table.insert(list,p:objectName())
					end
				end
				room:gameOver(table.concat(list,"+"))
			end
		end
		--全反平局
		local isAllRebel =true 
		for _,p in sgs.qlist(players) do
			if p:getRole() ~="rebel" then	
				isAllRebel = false
				break
			end
		end
		if isAllRebel then 
		--	room:writeToConsole("反贼结局")
			room:gameOver(".")
		end
		
		--只剩一个，默认你赢
		if room:alivePlayerCount() == 1 then
			room:gameOver(player:objectName())
		end
        return false
    end,
}

ShijiaAnjiang:addSkill(ShijiaLordWin)


ShijiaSkipNormalWin = sgs.CreateRuleSkillV2{
    name = "#ShijiaSkipNormalWin", events = {sgs.GameOverJudge},
    frequency = sgs.Skill_Compulsory, priority = 3,
    can_trigger = function(self, event, room, player, data)
        if not shijiaMode(room) and not room:getTag("ShijiaRulesActive"):toBool() then return "" end
        return self:objectName(), player or room:getAllPlayers():first()
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        room:setTag("SkipGameRule", sgs.QVariant(event))
        return false
    end,
}

ShijiaAnjiang:addSkill(ShijiaSkipNormalWin)

ShijiaSkipNormalDeath = sgs.CreateRuleSkillV2{
    name = "ShijiaSkipNormalDeath", events = {sgs.BuryVictim},
    frequency = sgs.Skill_Compulsory, priority = 10,
    can_trigger = function(self, event, room, player, data)
        if not shijiaMode(room) or table.contains(sgs.Sanguosha:getBanPackages(), "Shijia") then return "" end
        return self:objectName(), player or room:getAllPlayers():first()
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        room:setTag("SkipNormalDeathProcess", sgs.QVariant(true))
        return false
    end,
}
addToSkills(ShijiaSkipNormalDeath)

function EnterShijiaMode(room, current)

	room:doLightbox("$WelcomeShijiaMode", 1000)	--特效
	local msg = sgs.LogMessage()
	msg.type = "$AppendSeparator"
	room:sendLog(msg) --分割线
	msg.type = "#ShiJiaStartDesCription"
	room:sendLog(msg)
	msg.type = "$AppendSeparator"
	room:sendLog(msg) --分割线
	local lord = room:getLord()
	room:setTag("SkipNormalDeathProcess", sgs.QVariant(true))
	local  players = room:getAllPlayers()
	for _,p in sgs.qlist(players) do
		if p:getRole()~="lord" then	--如果不是主公就设置成内奸	
			p:setRole("renegade")
			room:setPlayerProperty(p, "role", sgs.QVariant("renegade"))
		end
		local target = NewHero(room,p,true,CharacterCount)
		room:changeHero(p,target, true, false, false, false)
		p:setTag("MaxHp",sgs.QVariant(p:getMaxHp()))
		p:setTag("Hp",sgs.QVariant(p:getHp()))
		addRule(p)
		room:resetAI(p)
	end
	room:updateStateItem()

end



---------------------------------------------------------------卡牌分界线--------------------------------------------

--三茶六礼
sgs.LoadTranslationTable{
["SanChaLiuLi"]="三茶六礼",
[":SanChaLiuLi"]=" 锦囊牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你\
   <b>效果</b>：目标角色从武将牌堆抽取X+1张女性角色，并从中选择一位纳为配偶。（x为目标角色当前体力值）",
}

SanChaLiuLi = sgs.CreateTrickCard{
	class_name = "SanChaLiuLi",
	subtype = "Shijia",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = true,
	can_recast = false,
	is_cancelable = true,
	on_use = function(self, room, source, targets)
		if not table.contains(targets,source) then
			table.insert(targets,source)
		end
		local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
    	for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
	    	room:cardEffect(effect)
        end
	end,
	on_effect = function(self,effect)
		local source = effect.to
		local room = source:getRoom()
		local hp = source:getHp()
		if hp >= 0 then
			local couple = NewHero(room,source,false,hp+1)
			AddCouple(source,couple)
		end
	end,
}

for i=0,16,1 do
	local card = SanChaLiuLi:clone()
	card:setSuit(i%4)
	card:setNumber((i%13)+1)
	card:setParent(extension)
end



--周公之礼
sgs.LoadTranslationTable{
["ZhouGongZhiLi"]="周公之礼",
[":ZhouGongZhiLi"]=" 锦囊牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你\
   <b>效果</b>：目标角色从配偶中选择一位进行洞房。（你必须是一名男性）\
   【洞房】：你随机获得0-2个子嗣",
["#ZhouGongZhiLi-msg-haswife"]="<br/>%arg与%arg2行了周公之礼。正所谓：<font color=\"#FFFF00\"><br/><b>    鸳鸯被里成双夜，一树梨花压海棠。</b>",
["#ZhouGongZhiLi-msg-nowife"]="<br/>%arg欲行周公之礼，怎奈孤枕难眠，终是索然无味。",
["#ZhouGongZhiLi-msg-hasmale"]="<br/>%arg欲行鱼水之事，怎奈茕然一身，已无牵挂。",
}
ZhouGongZhiLi = sgs.CreateTrickCard{
	class_name = "ZhouGongZhiLi",
	subtype = "Shijia",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = true,
	can_recast = false,
	is_cancelable = true,
	on_use = function(self, room, source, targets)
		if not table.contains(targets,source) then
			table.insert(targets,source)
		end
		local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
    	for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
	    	room:cardEffect(effect)
        end
	end,
	on_effect = function(self,effect)
		local source = effect.to
		local room = source:getRoom()	
		local list ={0,1,1,2}--为了实现概率
		local count = list[math.random(1,#list)]
		room:writeToConsole("总计"..count)
		
		local couples = source:getTag("Couples"):toString()
		local couple = room:askForGeneral(source,couples)
		
		local msg = sgs.LogMessage()
		msg.arg=source:getGeneralName()
		msg.arg2=couple
		
		if couple ~="" then
			if source:isMale() then 
				msg.type = "#ZhouGongZhiLi-msg-haswife"
				room:sendLog(msg)
				for i=1,count,1 do
					room:writeToConsole("造一个")	
					MakeChild(source,couple)
				end
			else
				msg.type = "#ZhouGongZhiLi-msg-hasmale"
				room:sendLog(msg)
			
			end
		else
			msg.type = "#ZhouGongZhiLi-msg-nowife"
			room:sendLog(msg)
		end		
	end,
}

for i=0,11,1 do
	local card = ZhouGongZhiLi:clone()
	card:setSuit(i%4)
	card:setNumber((i%13)+1)
	card:setParent(extension)
end


--与虎谋皮

sgs.LoadTranslationTable{
["YuHuMouPi"]="与虎谋皮",
[":YuHuMouPi"]=" 锦囊牌（可重铸）\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你\
   <b>效果</b>：若你不是主公，则你向主公发起拼点，赢的角色获得没赢角色的所有手牌.",
}
YuHuMouPi = sgs.CreateTrickCard{
	class_name = "YuHuMouPi",
	subtype = "Shijia",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = true,
	can_recast = true,
	is_cancelable = true,
	on_use = function(self, room, source, targets)
		local choices ="recast"
		if source:getRole()~="lord" then 
			choices=choices.."+use"
		end
		
		local choice = room:askForChoice(source, self:objectName(), choices,sgs.QVariant())
		if choice =="recast" then
		--	source:drawCards(1)
		UseCardRecast(source,self,"",1)
		end
		if choice =="use" then
			if not table.contains(targets,source) then
				table.insert(targets,source)
			end
			local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
			for _,to in sgs.list(targets)do
				local effect = sgs.CardEffectStruct()
				effect.from = source
				effect.card = self
				effect.multiple = #targets>1
				effect.to = to
				effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
				effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
				effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
				room:cardEffect(effect)
			end
		end
		return
	end,
	on_effect = function(self,effect)
		local to = effect.to
		local room = to:getRoom()	
		local  players = room:getAllPlayers()
		for _,p in sgs.qlist(players) do
			if p:getRole()=="lord" then
				if to:canPindian(p) then
					local result= to:pindianInt(p, self:objectName())
					if result == -1  then
						room:obtainCard(p, to:wholeHandCards(), false)
						--p:drawCards(2)
					end
					if result == 1 then
						--to:drawCards(2)
						room:obtainCard(to, p:wholeHandCards(), false)
					end		
				end
			end		
		end

	end,
}


for i=0,2,1 do
	local card = YuHuMouPi:clone()
	card:setSuit(i%4)
	card:setNumber(i+1)
	card:setParent(extension)
end


--俯首称臣


sgs.LoadTranslationTable{
["FuShouChengChen"]="俯首称臣",
[":FuShouChengChen"]=" 锦囊牌（可重铸）\
   <b>时机</b>：当你受到伤害后\
   <b>目标</b>：你\
   <b>效果</b>：【主公】->【反贼】->【内奸】->【忠臣】，当你受到下一阶级身份角色造成的伤害后，你可以使用此牌将你的身份转变为下一阶级身份。",
["#FuShouChengChen-msg"]="%arg将身份转变为<font color=\"#FFFF00\">【%arg2】",
["ShiJia-FuShouChengChen"]="你可以使用【俯首称臣】将身份变成【%src】",
}

local FuShouChengChenList ={"lord","rebel","renegade","loyalist"}
function findIndex(array, value)
    for index, v in ipairs(array) do
        if v == value then
            return index
        end
    end
    return nil
end

FuShouChengChen = sgs.CreateTrickCard{
	class_name = "FuShouChengChen",
	subtype = "Shijia",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = true,
	can_recast = true,
	is_cancelable = true,
	available = function(self,player)
		return false
    end,
	on_use = function(self, room, source, targets)
		if not table.contains(targets,source) then
			table.insert(targets,source)
		end
		local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
		for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
			room:cardEffect(effect)
		end

		return
	end,
	on_effect = function(self,effect)
		local source = effect.to
		local role = source:getRole()
		local room = source:getRoom()	
		if role ~= "loyalist" then
			
			local index = findIndex(FuShouChengChenList, role)
			source:setRole(FuShouChengChenList[index+1])
			room:setPlayerProperty(source, "role", sgs.QVariant(FuShouChengChenList[index+1]))
			
			room:updateStateItem()
		
			local msg = sgs.LogMessage()
			msg.arg=source:getGeneralName()
			msg.arg2 = source:getRole()
			msg.type = "#FuShouChengChen-msg"
			room:sendLog(msg)
			room:resetAI(source)		
		end
		
		
	end,
}


for i=0,3,1 do
	local card = FuShouChengChen:clone()
	card:setSuit(i%4)
	card:setNumber(i+1)
	card:setParent(extension)
end


--落草为寇

sgs.LoadTranslationTable{
["LuoCaoWeiKou"]="落草为寇",
[":LuoCaoWeiKou"]=" 锦囊牌\
   <b>时机</b>：（当你不为反贼时）出牌阶段或当你进入濒死状态\
   <b>目标</b>：你\
   <b>效果</b>：你将身份变为【反贼】，若此时在你的回合内则你摸X张牌，否则回复X点体力（X为场上反贼数）。",
["#LuoCaoWeiKou-msg"]="%arg 将身份变为<font color=\"#FFFF00\">【反贼】",
["ShiJia-LuoCaoWeiKou"]="你可以使用【落草为寇】将身份变为【反贼】",
}
LuoCaoWeiKou = sgs.CreateTrickCard{
	class_name = "LuoCaoWeiKou",
	subtype = "Shijia",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = true,
	can_recast = false,
	is_cancelable = true,
	available = function(self,player)
		return player:getRole() ~="rebel"
    end,
	on_use = function(self, room, source, targets)
		if not table.contains(targets,source) then
			table.insert(targets,source)
		end
		local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
    	for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
	    	room:cardEffect(effect)
        end
	end,
	on_effect = function(self,effect)
		local to = effect.to
		local room = to:getRoom()	
			to:setRole("rebel")
			room:setPlayerProperty(to, "role", sgs.QVariant("rebel"))
			room:updateStateItem()
			room:resetAI(to)
		--消息
			local msg = sgs.LogMessage()
			msg.arg=to:getGeneralName()
			msg.type = "#LuoCaoWeiKou-msg"
			room:sendLog(msg)
			
			local players = room:getAlivePlayers()
			local n = 0
			for _,p in sgs.qlist(players) do
				if p:getRole()=="rebel" then
					n=n+1
				end
			end
			
			if to:getPhase() == sgs.Player_NotActive then--回合外回复体力	
				local recover = sgs.RecoverStruct()
				recover.who = to
				recover.recover = math.min(n, to:getMaxHp() - to:getHp())
				room:recover(to,recover)
			else
				to:drawCards(n)	
			end
	end,
}


for i=0,3,1 do
	local card = LuoCaoWeiKou:clone()
	card:setSuit(i%4)
	card:setNumber(i+1)
	card:setParent(extension)
end


--窃玉偷香

sgs.LoadTranslationTable{
["QieYuTouXiang"]="窃玉偷香",
["@QieYu-msg"]="请打出1张【杀】，否则被抢走一名配偶",
[":QieYuTouXiang"]=" 锦囊牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你\
   <b>效果</b>：你指定一名其他角色，除非其打出一张【杀】,否则你将其的一名配偶改为你的配偶。",
["#QieYuTouXiang-msg-no"]="月黑风高，%arg向%arg2窃玉偷香，不料%arg2竟无一妻妾，只得无奈离去",
["#QieYuTouXiang-msg-yes"]="%arg行至一所，忽逢桃花林，夹岸数百步。中无杂树，芳草鲜美，落英缤纷。\
有一俏妇人亭亭玉立，其人面如桃花，眸若秋水，举止颦笑间尽显风情。\
原是%arg2妻妾%arg3，%arg见之甚爱之，乃窃之而走。"
}
QieYuTouXiang = sgs.CreateTrickCard{
	class_name = "QieYuTouXiang",
	subtype = "Shijia",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = false,
	filter = function(self, targets,to_select)
		local player = sgs.Self
		if player and  #targets < 1 then
			return to_select:objectName() ~= player:objectName()
		end
		
	end,
	feasible = function(self,targets)--表示可以点确定的情况
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		
		local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
    	for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
	    	room:cardEffect(effect)
        end
	end,
	on_effect = function(self,effect)
		local from = effect.from
		local target = effect.to
		local room = from:getRoom()	

		if not room:askForCard(effect.to, "slash", "@QieYu-msg", sgs.QVariant(), self:objectName()) then
			local couples = target:getTag("Couples"):toString()
			local couple = room:askForGeneral(from,couples)
			
			local msg = sgs.LogMessage()
			msg.arg=from:getGeneralName()
			msg.arg2= target:getGeneralName()
			msg.arg3 = couple
			if couple =="" then
				msg.type = "#QieYuTouXiang-msg-no"
				room:sendLog(msg)
			else
				msg.type = "#QieYuTouXiang-msg-yes"
				room:sendLog(msg)
				RemoveCouple(target,couple)
				AddCouple(from,couple)
				
			end
		
		end
		
	end,
}


for i=0,5,1 do
	local card = QieYuTouXiang:clone()
	card:setSuit(i%4)
	card:setNumber(i+1)
	card:setParent(extension)
end


--易子而食

sgs.LoadTranslationTable{
["YiZiErShi"]="易子而食",
[":YiZiErShi"]=" 锦囊牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你\
   <b>效果</b>：你指定一名其他角色，你与其各将自己的任意名子嗣投入锅中，享用后各摸X张牌(X为锅中孩子数量)",
["#YiZiErShi-msg"]="%arg与%arg2吃掉了对方的子嗣，并回复一点体力",
["YiZiErShi-text"]="你要继续投入孩子吗?",
["touru"]="投入",
["butou"]="不投",

["#YiZiErShi-msg4"]="%arg 与 %arg2 都没有将孩子丢入锅中,大家都饿了肚子",
["#YiZiErShi-msg3"]="%arg 与 %arg2 开始享用这场子嗣盛宴",
["#YiZiErShi-msg2"]="%arg2 将孩子 %arg4 投入锅中",
["#YiZiErShi-msg1"]="%arg 将孩子 %arg3 投入锅中",
["#YiZiErShi-msg0"]="%arg 和 %arg2 架起大锅",
}



YiZiErShi = sgs.CreateTrickCard{
	class_name = "YiZiErShi",
	subtype = "Shijia",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = false,
	filter = function(self, targets,to_select)
		local player = sgs.Self
		if player and  #targets < 1 then
			return to_select:objectName() ~= player:objectName()
		end
		
	end,
	feasible = function(self,targets)--表示可以点确定的情况
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local effect = sgs.CardEffectStruct()
		effect.from = source
		effect.card = self
		local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
		for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
	    	room:cardEffect(effect)
        end
		return
	end,
	on_effect = function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()	
		local n = 0

		local msg = sgs.LogMessage()
		msg.arg=from:getGeneralName()
		msg.arg2= to:getGeneralName()
		msg.type="#YiZiErShi-msg0"
		room:sendLog(msg)	
		
		while #(from:getTag("Children"):toString():split("+")) > 0 and  room:askForChoice(from, self:objectName(), "touru+butou",sgs.QVariant(),nil,"YiZiErShi-text") == "touru"  do
			local children1 = from:getTag("Children"):toString()
			local child1 = room:askForGeneral(from,children1)
			if child1 ~= "" then
				n = n+1
				
				msg.type="#YiZiErShi-msg1"
				msg.arg3 = child1
				room:sendLog(msg)
				
				RemoveChild(from,child1)
			end
		end
		while #(to:getTag("Children"):toString():split("+")) > 0 and room:askForChoice(to, self:objectName(), "touru+butou",sgs.QVariant(),nil,"YiZiErShi-text") == "touru" do
			local children2 = to:getTag("Children"):toString()		
			local child2 = room:askForGeneral(to,children2)
			if child2 ~= "" then
				n = n+1
				msg.type="#YiZiErShi-msg2"		
				msg.arg4 = child2
				room:sendLog(msg)
				RemoveChild(to,child2)
			end
		end
		if n > 0 then
			msg.type="#YiZiErShi-msg3"
			room:sendLog(msg)	
			from:drawCards(n)
			to:drawCards(n)
		else
			msg.type="#YiZiErShi-msg4"
			room:sendLog(msg)
		end
	end,
}
for i=0,2,1 do
	local card = YiZiErShi:clone()
	card:setSuit(i%4)
	card:setNumber(i+1)
	card:setParent(extension)
end

--秦晋之好

sgs.LoadTranslationTable{
["QinJinZhiHao"]="秦晋之好",
[":QinJinZhiHao"]=" 锦囊牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你指定的一名身份相同其他角色\
   <b>效果</b>：你与目标交换所有配偶。",
--["#QinJinZhiHao-msg"]="%arg将子嗣%arg3许配给%arg2，愿他们能永结同好！",
["#QinJinZhiHao-msg"]="%arg 与 %arg2 永结同好，交换所有配偶！",
}
QinJinZhiHao = sgs.CreateTrickCard{
	class_name = "QinJinZhiHao",
	subtype = "Shijia",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = true,
	filter = function(self, targets,to_select)
		local player = sgs.Self
		if player and  #targets < 1 then
				return to_select:getRole() == player:getRole() and to_select:objectName() ~= player:objectName() 
		end
		
	end,
	feasible = function(self,targets)--表示可以点确定的情况
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local effect = sgs.CardEffectStruct()
		effect.from = source
		effect.card = self
		local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
		for _, to in ipairs(targets) do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
	    	room:cardEffect(effect)
		end
		return
	end,
	on_effect = function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()	
		
		local female1 = from:getTag("Couples"):toString()
		local female2 = to:getTag("Couples"):toString()
		
		from:setTag("Couples",sgs.QVariant(female2))
		to:setTag("Couples",sgs.QVariant(female1))
		
		--动画
		local all = room:getAllPlayers(true)
		local list1 = female1:split("+")
		local list2 = female2:split("+")
		if #list1 > 0 then
			room:doAnimate(4, to:objectName(),table.concat(list1,":"),all)
		else
			to:speak("三十年河东，三十年河西。莫欺少年穷！")
		end
		if #list2 > 0 then
			room:doAnimate(4, from:objectName(),table.concat(list2,":"),all)
		else
			from:speak("三十年河东，三十年河西。莫欺少年穷！")
		end
		--移除副将
		from:setTag("MaxHp",sgs.QVariant(from:getMaxHp()))
		from:setTag("Hp",sgs.QVariant(from:getHp()))
		to:setTag("MaxHp",sgs.QVariant(to:getMaxHp()))
		to:setTag("Hp",sgs.QVariant(to:getHp()))
		
		room:changeHero(from,nil,false, false,true,false)
		room:changeHero(to,nil,false, false,true,false)
		


		from:setMaxHp(from:getTag("MaxHp"):toInt())
		room:broadcastProperty(from, "maxhp");
		from:setHp(from:getTag("Hp"):toInt())
		room:broadcastProperty(from, "hp");
	
		to:setMaxHp(to:getTag("MaxHp"):toInt())
		room:broadcastProperty(to, "maxhp");
		to:setHp(to:getTag("Hp"):toInt())
		room:broadcastProperty(to, "hp");	
	
		local msg = sgs.LogMessage()
			msg.type="#QinJinZhiHao-msg"
			msg.arg=to:getGeneralName()
			msg.arg2= from:getGeneralName()
			room:sendLog(msg)
			
		CheckShijiaBtn(from)
		CheckShijiaBtn(to)
	end,
}


for i=0,3,1 do
	local card = QinJinZhiHao:clone()
	card:setSuit(i%4)
	card:setNumber(i+1)
	card:setParent(extension)
end


--美人计

sgs.LoadTranslationTable{
["MeiRenJi"]="美人计",
[":MeiRenJi"]=" 锦囊牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你\
   <b>效果</b>：你从你的配偶或女性子嗣中选择一位交给其他角色并成为其配偶。然后该角色武将牌翻面。",
["#MeiRenJi-msg-yes"]="%arg将%arg3赠予%arg2，%arg2笑纳之。",
["#MeiRenJi-msg-no"]="%arg欲使美人计，怎奈身边竟无一美人，只得作罢。",
}
MeiRenJi = sgs.CreateTrickCard{
	class_name = "MeiRenJi",
	subtype = "Shijia",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = false,
	filter = function(self, targets,to_select)
		local player = sgs.Self
		if player and  #targets < 1 then
			return to_select:objectName() ~= player:objectName()
		end
		
	end,
	feasible = function(self,targets)--表示可以点确定的情况
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		local effect = sgs.CardEffectStruct()
		effect.from = source
		effect.card = self
		local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
		for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
	    	room:cardEffect(effect)
        end
		return
	end,
	on_effect = function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()	
		local children = from:getTag("Children"):toString()
		local femaleChildren = GetFemaleFromStr(children) 
		local couples = from:getTag("Couples"):toString()
		
		local all = AddUpStr(femaleChildren,couples)
	--	room:writeToConsole(all)
		local TheSelect = room:askForGeneral(from,all)
		
		local msg = sgs.LogMessage()
		msg.arg = from:getGeneralName()
		msg.arg2= to:getGeneralName()
		msg.arg3 = TheSelect

		
		if TheSelect ~="" then
			RemoveChild(from,TheSelect)
			RemoveCouple(from,TheSelect)
			AddCouple(to,TheSelect)
		
			to:turnOver()
			msg.type="#MeiRenJi-msg-yes"
			room:sendLog(msg)
		else

			msg.type="#MeiRenJi-msg-no"
			room:sendLog(msg)
		end
		
	end,
}


for i=0,3,1 do
	local card = MeiRenJi:clone()
	card:setSuit(i%4)
	card:setNumber(i+1)
	card:setParent(extension)
end

--阉刀
sgs.LoadTranslationTable{
["YanDao"]="阉刀",
[":YanDao"]=" 装备牌\
   <b>距离</b>：1\
   <b>效果</b>：锁定技，当你距离1以内的角色受到伤害后，你弃置阉刀并对其进行阉割。\
   【阉割】效果：目标角色将性别改为中性，并获得技能【宦权】<br/>\
   【宦权】：回合开始阶段，你失去一名配偶并摸1张牌，若你无配偶，则改为摸2张牌。",
["HuanQuanSkill"]="宦权",
[":HuanQuanSkill"]="回合开始阶段，你失去一名配偶并摸1张牌，若你已无配偶，则改为摸2张牌。",
["YanDaoSkill"]="阉刀",
["BeiYan"]="被阉",
["#YanDaoSkill-msg"]="【阉刀】效果发动<br/>%arg 被 %arg2 阉了！",
["#MeiRenJi-msg-no"]="%arg欲使美人计，怎奈身边竟无一美人，只得作罢。",
}

HuanQuanSkill = sgs.CreateTriggerSkillV2{
    name = "HuanQuanSkill", events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:getPhase() == sgs.Player_RoundStart then return self:objectName(), player end
        return ""
    end,
    on_cost = function(self, event, room, player, ctx)
        local couples = player:getTag("Couples"):toString()
        ctx.choice = couples ~= "" and room:askForGeneral(player, couples) or ""
        return true
    end,
    on_pay = function(self, event, room, player, ctx)
        if ctx.choice ~= "" then RemoveCouple(player, ctx.choice) end
        return true
    end,
    on_effect = function(self, event, room, player, ctx)
        room:notifySkillInvoked(player, "HuanQuanSkill"); player:drawCards((ctx.choice ~= "" and 1 or 2) * self:getEffectiveAmount(ctx))
        return false
    end,
}

ShijiaAnjiang:addSkill(HuanQuanSkill)

YanDaoSkill = sgs.CreateEquipSkillV2{
    name = "#YanDaoSkill", equipment = "YanDao", equipment_type = "weapon",
    events = {sgs.Damaged}, frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        local victim = data:toDamage().to
        if not victim then return "" end
        -- Only the first nearby physical blade resolves, in the donor's room order.
        for _, owner in sgs.qlist(room:getAlivePlayers()) do
            local weapon = owner:getWeapon()
            if owner:distanceTo(victim) <= 1 and weapon and weapon:objectName() == "YanDao"
                and owner:hasWeapon("YanDao") then return self:objectName(), owner end
        end
        return ""
    end,
    on_effect = function(self, event, room, player, ctx)
        local victim = ctx.original_data:toDamage().to
        local weapon = player:getWeapon()
        if not victim or not weapon or weapon:objectName() ~= "YanDao" then return false end
        local msg = sgs.LogMessage(); msg.type = "#YanDaoSkill-msg"
        msg.arg = victim:getGeneralName(); msg.arg2 = player:getGeneralName(); room:sendLog(msg)
        victim:setGender(sgs.General_Neuter); room:acquireSkill(victim, "HuanQuanSkill")
        -- Donor consumes the blade after its result; paying first invalidates the equip source.
        -- Keep the selected physical blade across the acquireSkill callbacks.
        room:throwCard(weapon, player)
        return false
    end,
}


ShijiaAnjiang:addSkill(YanDaoSkill)

YanDao = sgs.CreateWeapon{
    name = "YanDao", subtype = "Shijia", range = 1,
}

for i=0,1,1 do
	local card = YanDao:clone()
	card:setSuit(i%4)
	card:setNumber(i+1)
	card:setParent(extension)
end





--君临天下


sgs.LoadTranslationTable{
["JunLinTianXia"]="君临天下",
[":JunLinTianXia"]=" 锦囊牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你\
   <b>效果</b>：你增加1点体力上限。若此时场上没有【主公】，你将身份变为【主公】，然后进行【朝代更迭】。\
   \
   【朝代更迭】：所有【忠臣】变成【内奸】，所有【反贼】可选择变成【内奸】",
["#JunLinTianXia-msg-loyalist"]=" <font color=\"#FFFF00\"><b>汉室倾颓，奸臣当道。山河破碎，万民流冗。<br/>  <br/>臣 %arg 不才愿横刀立马，血荐轩辕！凭手中三尺之剑，重整山河！</b>",
["#JunLinTianXia-msg-rebel"]=" <font color=\"#FFFF00\"> <b>天地不仁，万民失所。<br/>今我 %arg 横扫宇内，君临天下。受命于天，既寿永昌！</b>",
["#JunLinTianXia-msg-renegade"]=" <font color=\"#FFFF00\"><b>神器更易，再造乾坤。 <br/>吾 %arg 天命所归，万民景从。威加海内，四海升平！</b>",

}

JunLinTianXia = sgs.CreateTrickCard{
	class_name = "JunLinTianXia",
	subtype = "Shijia",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = true,
	can_recast = false,
	is_cancelable = true,
	on_use = function(self, room, source, targets)
		if not table.contains(targets,source) then
			table.insert(targets,source)
		end
		local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
		for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
	    	room:cardEffect(effect)
        end
		return
	end,
	
	on_effect = function(self,effect)
		local to = effect.to
		local room = to:getRoom()	
		local role = to:getRole()
		
		room:gainMaxHp(to, 1, self:objectName())
		
		local players= room:getAlivePlayers()
		local hasLord =false
		for _,p in sgs.qlist(players) do
			if p:getRole()=="lord" then
				hasLord =true
				break
			end 
		end
		
		if hasLord ==false then
			local msg = sgs.LogMessage()
				msg.arg= to:getGeneralName()
			if role== "rebel" then
				msg.type="#JunLinTianXia-msg-rebel"		
			elseif role == "renegade" then
				msg.type="#JunLinTianXia-msg-renegade"	
			elseif role=="loyalist" then 
				msg.type="#JunLinTianXia-msg-loyalist"	
			end
			room:sendLog(msg)
		
			to:setRole("lord")
			room:setPlayerProperty(to, "role", sgs.QVariant("lord"))
			room:updateStateItem()
			--local players = room:getPlayers(to,false)
			local Aliveplayers = room:getAlivePlayers()
			RengadeChange(Aliveplayers,room)	
	
		
		end
		

		
	end,
}


for i=0,3,1 do
	local card = JunLinTianXia:clone()
	card:setSuit(i%4)
	card:setNumber(i+1)
	card:setParent(extension)
end



--引兵入关
sgs.LoadTranslationTable{
["YinBingRuGuan"]="引兵入关",
[":YinBingRuGuan"]=" 锦囊牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你指定的一名已死亡【反贼】角色\
   <b>效果</b>：目标角色复活并重新选将。\
   ",
["#YinBingRuGuan-msg-true"]="<b>%arg 引兵入关，召 %arg2 进京！</b>",
["#YinBingRuGuan-msg-false"]="<b>%arg 欲引兵入关，但引了半天并无卵用。</b>",

}


YinBingRuGuan = sgs.CreateTrickCard{
	class_name = "YinBingRuGuan",
	subtype = "Shijia",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = true,
	can_recast = false,
	is_cancelable = false,
	on_use = function(self, room, source, targets)
		local effect = sgs.CardEffectStruct()
		effect.from = source
		effect.card = self
		if not table.contains(targets,source) then
			table.insert(targets,source)
		end
		local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
		for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
	    	room:cardEffect(effect)
        end
		return
	end,
	on_effect = function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()	
		local players = room:getAllPlayers(true)
		local list ={}	
		for _,p in sgs.qlist(players) do
			if not p:isAlive() and p:getRole()=="rebel" then
				table.insert(list,p:getGeneralName())
			end
		end
		local msg = sgs.LogMessage()
		msg.arg= to:getGeneralName()
			
		

		if #list ~= 0 then 
			local targetName = room:askForGeneral(to,table.concat(list,"+"))
			local  target = room:findPlayer(targetName,true)
			if target then
				room:revivePlayer(target)
				local NewGeneral = NewHero(room,target,true,CharacterCount)
				room:changeHero(target,NewGeneral, true, true, false, false)
				addRule(target)
				msg.type="#YinBingRuGuan-msg-true"
				msg.arg2 = NewGeneral
			end
		else
			msg.type="#YinBingRuGuan-msg-false"	
		end
		room:sendLog(msg)	
	end,
}


for i=0,2,1 do
	local card = YinBingRuGuan:clone()
	card:setSuit(i%4)
	card:setNumber(i+1)
	card:setParent(extension_more)
end




--倒反天罡
sgs.LoadTranslationTable{
["DaoFanTianGang"]="倒反天罡",
[":DaoFanTianGang"]=" 锦囊牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你指定的一名已死亡角色\
   <b>效果</b>：目标角色将身份改成【反贼】,然后其变为【反贼】的摸牌奖励改为由你执行。",
["#DaoFanTianGang-msg-true"]="<b>%arg 倒反天罡，使 %arg2 为反！</b>",
["#DaoFanTianGang-msg-false"]="<b> %arg 欲倒反天罡，然朗朗乾坤，沉冤得雪，正道不孤。</b>",

}


DaoFanTianGang = sgs.CreateTrickCard{
	class_name = "DaoFanTianGang",
	subtype = "Shijia",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = true,
	can_recast = false,
	is_cancelable = false,
    available = function(self,player)
    	local tos = player:getSiblings()
		tos:append(player)
		for _,to in sgs.list(tos)do
			if not to:isAlive() and to:getRole() ~= "rebel" then
				return self:cardIsAvailable(player)
			end
		end
    end,
	on_use = function(self, room, source, targets)
		local effect = sgs.CardEffectStruct()
		effect.from = source
		effect.card = self
		if not table.contains(targets,source) then
			table.insert(targets,source)
		end
		local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
		for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
	    	room:cardEffect(effect)
        end
		return
	end,
	on_effect = function(self,effect)
		local from = effect.from
		local to = effect.to
		local room = from:getRoom()	
		local players = room:getAllPlayers(true)
		local list ={}	
		for _,p in sgs.qlist(players) do
			if not p:isAlive() and p:getRole() ~= "rebel" then
				table.insert(list,p:getGeneralName())
			end
		end
		local msg = sgs.LogMessage()
		msg.arg= to:getGeneralName()
		

		if #list ~= 0 then 
			local targetName = room:askForGeneral(to,table.concat(list,"+"))
			local  target = room:findPlayer(targetName,true)
			if target then
				msg.type = "#DaoFanTianGang-msg-true"	
				msg.arg2 = target:getGeneralName()
				target:setRole("rebel")
				room:setPlayerProperty(target, "role", sgs.QVariant("rebel"))
			--	room:broadcastProperty(target, "alive");
			--	room:broadcastProperty(target, "role");
			--	room:doBroadcastNotify(players, 44,sgs.QVariant(target:objectName()))
				RebelDraw(from,room)
			end
		else
			msg.type="#DaoFanTianGang-msg-false"	
		end
		room:sendLog(msg)	
		room:updateStateItem()
	end,
}

for i=0,3,1 do
	local card = DaoFanTianGang:clone()
	card:setSuit(i%4)
	card:setNumber(i+1)
	card:setParent(extension_more)
end





--螟蛉之子
sgs.LoadTranslationTable{
["MingLingZhiZi"]="螟蛉之子",
[":MingLingZhiZi"]=" 锦囊牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你\
   <b>效果</b>：目标角色从武将牌堆抽取X+1名角色，并从中选择一位收为子嗣。（x为目标角色当前体力值）",
}

MingLingZhiZi = sgs.CreateTrickCard{
	class_name = "MingLingZhiZi",
	subtype = "Shijia",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = true,
	can_recast = false,
	is_cancelable = true,
	on_use = function(self, room, source, targets)
		if not table.contains(targets,source) then
			table.insert(targets,source)
		end
		local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
    	for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
	    	room:cardEffect(effect)
        end
	end,
	on_effect = function(self,effect)
		local source = effect.to
		local room = source:getRoom()
		local hp = source:getHp()
		if hp >= 0 then
			local child = NewHero(room,source,nil,hp+1)
			AddChild(source,child)
		end
	end,
}

for i=0,2,1 do
	local card = MingLingZhiZi:clone()
	card:setSuit(i%4)
	card:setNumber((i%13)+1)
	card:setParent(extension)
end



--血荐轩辕
sgs.LoadTranslationTable{
["XueJianXuanYuan"]="血荐轩辕",
[":XueJianXuanYuan"]=" 锦囊牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你\
   <b>效果</b>：目标角色选择杀光自己的所有配偶或子嗣,并摸等量的牌",
["shashasha"]="杀！杀！杀！",
["XueJianXuanYuan-tip"]="天不仁兮降乱离!",
["shaqi"]="杀妻证道",
["shazi"]="杀子证道",
["#XueJianXuanYuan-msg0"]="%arg 选择了 %arg2",
["#XueJianXuanYuan-msg1"]=" %arg2 被杀掉了~",
["#XueJianXuanYuan-kill"]="%arg ：%arg2 ",

}

XueJianXuanYuan = sgs.CreateTrickCard{
	class_name = "XueJianXuanYuan",
	subtype = "Shijia",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = true,
	can_recast = false,
	is_cancelable = true,
	on_use = function(self, room, source, targets)
		if not table.contains(targets,source) then
			table.insert(targets,source)
		end
		local use = room:getTag("cardUseStruct"..self:toString()):toCardUse()
    	for _,to in sgs.list(targets)do
			local effect = sgs.CardEffectStruct()
			effect.from = source
			effect.card = self
			effect.multiple = #targets>1
			effect.to = to
			effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
			effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
			effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
	    	room:cardEffect(effect)
        end
	end,
	on_effect = function(self,effect)
		local to = effect.to
		local room = to:getRoom()
		local choice = room:askForChoice(to,"shashasha", "shaqi+shazi",sgs.QVariant(),nil,"XueJianXuanYuan-tip")
		local death 
		local list
		local msg = sgs.LogMessage()
		local msg2 = sgs.LogMessage()
		msg.type = "#XueJianXuanYuan-msg0"
		msg2.type = "#XueJianXuanYuan-kill"
		msg.arg = to:getGeneralName()	
		msg.arg2= choice
		room:sendLog(msg) 
		msg.type = "#XueJianXuanYuan-msg1"
		if choice == "shaqi" then 
			death = to:getTag("Couples"):toString()
			list = death:split("+")
			room:getThread():delay(2000)
			for _,name in ipairs(list) do	
				msg.arg2 = name
				msg2.arg = name
				msg2.arg2 = "~"..name
				room:sendLog(msg)
				room:sendLog(msg2)
				
				room:getThread():delay(2000)
			end
			
			to:setTag("Couples",sgs.QVariant(""))
		else
			death = to:getTag("Children"):toString()
			list = death:split("+")
			room:getThread():delay(2000)
			for _,name in ipairs(list) do
				msg.arg2 = name
				msg2.arg = name
				msg2.arg2 = "~"..name
				room:sendLog(msg)
				room:sendLog(msg2)
			end
			to:setTag("Children",sgs.QVariant(""))
		end
		
		to:drawCards(#list)
		
		
	end,
}

for i=0,1,1 do
	local card = XueJianXuanYuan:clone()
	card:setSuit(i%4)
	card:setNumber((i%13)+1)
	card:setParent(extension_more)
end



--传世玉玺


sgs.LoadTranslationTable{
["ChuanShiYuXi"]="传世玉玺",
[":ChuanShiYuXi"]=" 宝物牌（可赠予）\
	<b>效果</b>：1.游戏开始时,【主公】自动装备\
				 2.装备时,视为使用一张【君临天下】\
				 3.扩充【天子诏令】",
}
ChuanShiYuXi = sgs.CreateTreasure{
	name = "ChuanShiYuXi",
	class_name = "ChuanShiYuXi",
	target_fixed = false,
	filter = function(self, targets,to_select)
		local player = sgs.Self
		if player and  #targets < 1 then
			return true
		end
		
	end,
	feasible = function(self,targets)--表示可以点确定的情况
		return #targets == 1
	end,
	on_install = function(self,player)
		local room = player:getRoom()
		local jun = sgs.Sanguosha:cloneCard("JunLinTianXia", sgs.Card_NoSuit, 0)
		jun:setSkillName(self:objectName())
		room:useCard(sgs.CardUseStruct(jun,player, player), false)
		--room:acquireSkill(player,"#XiangSkill")
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		--room:detachSkillFromPlayer(player, "#XiangSkill")
	end,
}


	local card = ChuanShiYuXi:clone()
	card:setSuit(2)
	card:setNumber(13)
	card:setParent(extension_more)



--狸猫换子(没做完)

sgs.LoadTranslationTable{
["ShijiaLiMao"]="狸猫",
["LiMaoHuanZi"]="狸猫换子",
[":LiMaoHuanZi"]=" 宝物牌（可赠予）\
	<b>效果</b>：1.装备时,视为使用一张【君临天下】\
				 2.扩充【天子诏令】",
}
--ShijiaLiMao = sgs.General(extension, "ShijiaLiMao", "god", 1,true,true)


------------卡牌使用部分------------------------


ShiJia_on_trigger = sgs.CreateRuleSkillV2{
    name = "ShiJia_on_trigger", events = {sgs.Dying, sgs.Damaged, sgs.GameStart},
    frequency = sgs.Skill_Compulsory, priority = 4,
    can_trigger = function(self, event, room, player, data)
        if not shijiaCardsEnabled() then return "" end
        if event == sgs.GameStart then
            local lord = room:getLord()
            if lord and lord:isAlive() and not lord:getTreasure() and (not player or player == lord) then return self:objectName(), lord end
        elseif player and player:isAlive() then return self:objectName(), player end
        return ""
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
		local room = player:getRoom()
		if event==sgs.Dying then
			local dying = data:toDying()
			local to = dying.who
			if player:objectName() == to:objectName() and player:getRole() ~= "rebel" then
				local ids = {}
				for _,id in sgs.list(player:handCards())do
					if sgs.Sanguosha:getCard(id):isKindOf("LuoCaoWeiKou") then 
						table.insert(ids,id)
					end
				end
				if #ids>0 then
					room:askForUseCard(player,table.concat(ids,","),"ShiJia-LuoCaoWeiKou:")
				end
			end
		elseif event==sgs.Damaged then

			local damage = data:toDamage()
			local from = damage.from
			local to = damage.to
			
			if to:getRole() ~= "loyalist" then

				local index = findIndex(FuShouChengChenList,to:getRole())
				if from and from:getRole() == FuShouChengChenList[index+1] then

					local ids = {}
					for _,id in sgs.list(player:handCards())do
						if sgs.Sanguosha:getCard(id):isKindOf("FuShouChengChen") then 
							table.insert(ids,id)
						end
					end
					if #ids> 0 then
						room:askForUseCard(player,table.concat(ids,","),"ShiJia-FuShouChengChen:"..FuShouChengChenList[index+1])
					end
				end
			end
		elseif event==sgs.GameStart then
			--穿玉玺
			if player:getRole() == "lord" then
				if player:getTreasure() then return end
				--room:sendCompulsoryTriggerLog(p,self:objectName(),true,true,1)
				local cs = sgs.CardList()
				for c,id in sgs.list(room:getDrawPile())do
					c = sgs.Sanguosha:getCard(id)
					if c:isKindOf("ChuanShiYuXi")
					then cs:append(c) end
				end
				cs = RandomList(cs)
				if cs:length()>0
				then
					cs = cs:at(0)
					player:obtainCard(cs)
					if room:getCardOwner(cs:getEffectiveId())==player then
						room:moveCardTo(cs,player,sgs.Player_PlaceEquip)
					end
				end
			end
		end
        return false
    end,
}
	
	
addToSkills(ShiJia_on_trigger)

----启动按钮-------




return {extension,extension_more}
