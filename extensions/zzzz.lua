extension = sgs.Package("zzzz")
local debug = true
savedata2 = "save2.json" --存档
readData2 = function()
    local json = require "json"
    local record = io.open(savedata2, "r")
    local t = { Record = {} }
    if record ~= nil then
        local content = record:read("*all")
        t = json.decode(content) or t
        record:close()
    end
    return t
end
writeData2 = function(t)
    local record = assert(io.open(savedata2, "w"))
    local order = { "Record" }
    setmetatable(order, { __index = table })
    local content = json.encode(t, { indent = true, level = 1, keyorder = order })
    record:write(content)
    record:close()
end
saveRecord2 = function(player, record_type) --record_type: 0. +1 gameplay , 1. +1 win , 2. +1 win & +1 gameplay
    assert(record_type >= 0 and record_type <= 2, "record_type should be 0, 1 or 2")

    local t = readData2()

    local all = sgs.Sanguosha:getLimitedGeneralNames()
    for _, name in pairs(all) do
        local general = sgs.Sanguosha:getGeneral(name)
        local package = general:getPackage()
        if t.Record[package] == nil then
            t.Record[package] = {}
        end
        if t.Record[package][name] == nil then
            t.Record[package][name] = { 0, 0, 0, 0, 0, 0, 0 }
        end
    end

    local name = player:getGeneralName()
    local package = player:getGeneral():getPackage()
    local list = { "lord", "loyalist", "rebel", "renegade" }
    local role = player:getRole()
    local roleIndex = nil

    for i, value in ipairs(list) do
        if value == role then
            roleIndex = i
            break
        end
    end
    roleIndex = roleIndex + 2
    local package2 = ""
    local name2 = ""
    if player:getGeneral2() then
        name2 = player:getGeneral2Name()
        package2 = player:getGeneral2():getPackage()
    end
    if record_type ~= 0 then -- record_type 1 or 2 +win
        if t.Record[package] == nil then
            t.Record[package] = {}
        end
        if t.Record[package][name] == nil then
            t.Record[package][name] = { 0, 0, 0, 0, 0, 0, 0 }
        end
        if t.Record[package2] == nil then
            t.Record[package2] = {}
        end
        if t.Record[package2][name2] == nil then
            t.Record[package2][name2] = { 0, 0, 0, 0, 0, 0, 0 }
        end
        if t.Record[package][name] then
            t.Record[package][name][1] = t.Record[package][name][1] + 1
            t.Record[package][name][roleIndex] = t.Record[package][name][roleIndex] + 1
        end
        if name2 ~= "" and name ~= name2 and t.Record[package2][name2] then
            t.Record[package2][name2][1] = t.Record[package2][name2][1] + 1
            t.Record[package2][name2][roleIndex] = t.Record[package2][name2][roleIndex] + 1
        end
    end
    if record_type ~= 1 then -- record_type 0 or 2 +win
        if t.Record[package] == nil then
            t.Record[package] = {}
        end
        if t.Record[package][name] == nil then
            t.Record[package][name] = { 0, 0, 0, 0, 0, 0, 0 }
        end
        if t.Record[package2] == nil then
            t.Record[package2] = {}
        end
        if t.Record[package2][name2] == nil then
            t.Record[package2][name2] = { 0, 0, 0, 0, 0, 0, 0 }
        end
        if t.Record[package][name] then
            t.Record[package][name][2] = t.Record[package][name][2] + 1
        end
        if name2 ~= "" and name ~= name2 and t.Record[package2][name2] then
            t.Record[package2][name2][2] = t.Record[package2][name2][2] + 1
        end
    end

    writeData2(t)
end
saveMvp2 = function(player) --record_type: 0. +1 gameplay , 1. +1 win , 2. +1 win & +1 gameplay
    local t = readData2()

    local all = sgs.Sanguosha:getLimitedGeneralNames()
    for _, name in pairs(all) do
        local general = sgs.Sanguosha:getGeneral(name)
        local package = general:getPackage()
        if t.Record[package] == nil then
            t.Record[package] = {}
        end
        if t.Record[package][name] == nil then
            t.Record[package][name] = { 0, 0, 0, 0, 0, 0, 0 }
        end
    end

    local name = player:getGeneralName()
    local package = player:getGeneral():getPackage()
    local roleIndex = 7
    local package2 = ""
    local name2 = ""
    if player:getGeneral2() then
        name2 = player:getGeneral2Name()
        package2 = player:getGeneral2():getPackage()
    end
    if record_type ~= 0 then -- record_type 1 or 2 +win
        if t.Record[package] == nil then
            t.Record[package] = {}
        end
        if t.Record[package][name] == nil then
            t.Record[package][name] = { 0, 0, 0, 0, 0, 0, 0 }
        end
        if t.Record[package2] == nil then
            t.Record[package2] = {}
        end
        if t.Record[package2][name2] == nil then
            t.Record[package2][name2] = { 0, 0, 0, 0, 0, 0, 0 }
        end
        if t.Record[package][name] then
            t.Record[package][name][roleIndex] = t.Record[package][name][roleIndex] + 1
        end
        if name2 ~= "" and name ~= name2 and t.Record[package2][name2] then
            t.Record[package2][name2][roleIndex] = t.Record[package2][name2][roleIndex] + 1
        end
    end

    writeData2(t)
end


allrecord3 = sgs.CreateTriggerSkill {
    --[[Rule: 1. single mode +1 gameplay when game STARTED & +1 win (if win) when game FINISHED;
		2. online mode +1 gameplay & +1 win (if win) simultaneously when game FINISHED;
		3. single mode escape CAN +1 gameplay, online mode escape CANNOT +1 gameplay;
		4. +1 win (if win) when game FINISHED (no escape);
		5. online mode trust when game FINISHED CANNOT +1 neither gameplay nor win
		
	规则：1. 单机模式在游戏开始时+1游玩次数 & 在游戏结束时+1胜利次数（如果胜利）；
		2. 联机模式在游戏结束时同时+1游玩次数 & +1胜利次数（如果胜利）；
		3. 单机模式逃跑可以+1游玩次数，联机模式逃跑则不能+1游玩次数；
		4. 游戏结束时依然存在的玩家（没有逃跑）才会+1胜利次数（如果胜利）；
		5. 联机模式在游戏结束时托管的玩家不会记录游玩次数和胜利次数
]]
    name = "allrecord3",
    events = { sgs.GameOverJudge },
    global = true,
    priority = 0,
    can_trigger = function(self, player)
        return true
    end,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if debug then return end
        if room:getMode() ~= "02p" then return end
        local t = getWinner(room, player)
        if not t then return end
        local function loser(role)
            local tt = t:split("+")
            if not table.contains(tt, role) then return true end
            return false
        end

        local owner = room:getOwner()
        local ip = owner:getIp()
        --if ip ~= "" and string.find(ip, "127.0.0.1") and player:objectName() == owner:objectName() then
        for _, p in sgs.qlist(room:getAllPlayers(true)) do
            if loser(p:getRole()) then
                saveRecord2(p, 0)
            else
                saveRecord2(p, 2)
            end
        end
        --end

        local players = sgs.QList2Table(room:getAllPlayers())
        for _, p in ipairs(players) do
            if loser(p) then
                table.removeOne(players, p)
            end
        end
        local comp = function(a, b)
            return a:getMark("mvpexp") > b:getMark("mvpexp")
        end
        if #players > 1 then
            table.sort(players, comp)
        end
        if #players > 0 then
            saveMvp2(players[1])
        end
    end
}


addToSkills(allrecord3)
winshow3 = sgs.General(extension, "winshow3", "", 0, true, true, false)
winshow3:setGender(sgs.General_Sexless)
winrate3 = sgs.CreateMasochismSkill {
    name = "winrate3",
    on_damaged = function()
    end
}
winshow3:addSkill(winrate3)

--【显示胜率】（置于页底以确保武将名翻译成功）
local g_property = "<font color='red'><b>胜率</b></font>"


local t = readData2()

if next(t.Record) ~= nil then
    local round = function(num, idp)
        local mult = 10 ^ (idp or 0)
        return math.floor(num * mult + 0.5) / mult
    end
    for package, contents in pairs(t.Record) do
        for key, rate in pairs(contents) do
            local general = sgs.Sanguosha:getGeneral(key)
            local text = rate[1] .. "/" .. rate[2]
            if rate[2] == 0 then
                rate = "未知"
            else
                rate = round(rate[1] / rate[2] * 100) .. "%"
            end
            if key ~= "GameTimes" then
                local translateName = sgs.Sanguosha:translate(key)

                local translatePackage = sgs.Sanguosha:translate(package)

                g_property = g_property .. "\n" .. translateName
                g_property = g_property .. "[" .. translatePackage .. "]"

                g_property = g_property .. " = " .. text .. " <b>(" .. rate .. ")</b>"
            end
        end
    end
end
sgs.LoadTranslationTable {
    ["zzzz"] = "胜率",
    ["winshow3"] = "胜率(2人局)",
    ["#winshow3"] = "角色资讯",
    ["designer:winshow3"] = "高达杀制作组",
    ["cv:winshow3"] = "贴吧：高达杀s吧",
    ["illustrator:winshow3"] = "QQ群：565837324",
    ["winrate3"] = "胜率",
    [":winrate3"] = g_property
}
return { extension }
