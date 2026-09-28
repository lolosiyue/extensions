-- TODO/HUMAN system supplement. Existing Engine modes and createMode remain authoritative.
-- Register the role before modes: Engine rejects an unknown role abbreviation.
if sgs.Sanguosha:getRoleAbbreviation("villager") == "" then
    sgs.Sanguosha:addRoleMapping("villager", "V")
end
local extraModes = {
    {"11p", "11人局", "ZCCCFFFFFNN"},
    {"12p", "12人局", "ZCCCFFFFFFNN"},
    {"13p", "13人局", "ZCCCFFFFFFNNN"},
    {"14p", "14人局", "ZCCCCFFFFFFFNN"},
    {"15p", "15人局", "ZCCCFFFFFFFNNNN"},
    {"16p", "16人局", "ZCCCCFFFFFFFFNNN"},
    {"06pv", "6人局（平民）", "ZCFFVN"},
    {"08pv", "8人局（平民）", "ZCCFFFVN"},
    -- Donor labelled nine seats but supplied ten; replace one loyalist in 09p.
    {"09pv", "9人局（平民）", "ZCCVFFFFN"},
    {"10pv", "10人局（平民）", "ZCCCCFFFFV"},
}
local addedModes = {}
for _, spec in ipairs(extraModes) do
    if sgs.Sanguosha:getModeGroup(spec[1]) == "" then
        if sgs.Sanguosha:addModes(spec[1], spec[2], spec[3]) then
            table.insert(addedModes, spec[1])
        end
    end
end
if #addedModes > 0 then sgs.Sanguosha:addModeGroup("身份模式", addedModes) end

-- Use the existing GameRule mode callback before gameOver publishes its winner.
-- Changing the GameOver event QVariant would not change that native winner string.
local function villagerWinner(victim)
    local room = victim:getRoom()
    local alive, roles, villagers = {}, {}, {}
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        if p:objectName() ~= victim:objectName() then
            table.insert(alive, p)
            roles[p:getRole()] = true
            if p:getRole() == "villager" then table.insert(villagers, p:objectName()) end
        end
    end
    local winner = ""
    local role = victim:getRole()
    -- Match current GameRule identity winner ordering, including lone-renegade victory.
    if (role == "lord" or role == "loyalist" or role == "rebel")
        and #alive == 1 and alive[1]:getRole() == "renegade" then
        winner = alive[1]:objectName()
    elseif role == "lord" then
        winner = "rebel"
    elseif role == "loyalist" then
        if not roles.lord and not roles.loyalist and not roles.renegade then winner = "rebel" end
    elseif role == "rebel" or role == "renegade" then
        if not roles.rebel and not roles.renegade then winner = "lord+loyalist" end
    end
    if winner ~= "" and #villagers > 0 then winner = winner .. "+" .. table.concat(villagers, "+") end
    return winner
end
local function villagerReward(killer, victim)
    if victim:getRole() ~= "villager" then return false end
    if killer and killer:isAlive() then killer:drawCards(2, "#VillagerReward") end
    return true -- Already paid; native identity rewards must not pay it again.
end
sgs.GameModeCallbacks = sgs.GameModeCallbacks or {}
for _, id in ipairs({"06pv", "08pv", "09pv", "10pv"}) do
    -- Each Room VM re-registers its callbacks, while definitions register only once.
    local callbacks = sgs.GameModeCallbacks[id] or {}
    callbacks.reward = callbacks.reward or villagerReward
    callbacks.getWinner = callbacks.getWinner or villagerWinner
    sgs.GameModeCallbacks[id] = callbacks
end

-- Current translations win; import missing donor keys without overwriting revised skills.
local function loadMissingTranslations(entries)
    local missing = {}
    for key, value in pairs(entries) do
        if sgs.Sanguosha:translate(key) == key then missing[key] = value end
    end
    sgs.LoadTranslationTable(missing)
end

loadMissingTranslations {
 ["2 players"]        = "2人局",
  ["2 players (KOF style)"]     = "KOF模式（2人局）",
  ["3 players"]        = "3人局",
  
  ["3 players (Dou Di Zhu)"]     = "普通版",
  ["3 players (TY Dou Di Zhu)"]     = "十周年版",
   
  ["4 players"]        = "4人局",
  ["4 players (Hulao Pass)"]     = "虎牢关模式（4人局）",
  ["4 players(Boss)"]    = "驱鬼逐邪（4人局）",
  ["4 players (Happy)"]     = "欢乐成双（4人局）",
  ["5 players"]        = "5人局",
  ["5 人局 [诸侯伐董]"]      = "诸侯伐董（5人局）",
  ["6 人局 [神武在世]"]      = "神武在世（6人局）",
  ["6 players"]        = "6人局",
  ["6 players (2 renegades)"]       = "6人局（2内奸）",
  ["6 players (3v3)"]     = "3v3模式",
  ["6 players (XMode)"]   = "血战到底（6人局）",
  ["7 players"]        = "7人局",
  ["8 players"]        = "8人局",
  ["8 players (2 renegades)"]       = "8人局（2内奸）",
  ["8 players (0 renegade)"]       = "8人局（0内奸）",
  ["8 players (JianGe Defense)"] = "剑阁守卫（8人局）",
  ["9 players"]        = "9人局",
  ["10 players"]       = "10人局",
  ["10 players (1 renegade)"]        = "10人局（1内奸）",
  ["10 players (0 renegade)"]       = "10人局（0内奸）",
  
  -- 平民局翻译（替换一个身份为平民）
  ["6 players (villager)"]  = "6人局（平民）",
  ["8 players (villager)"]  = "8人局（平民）",
  ["9 players (villager)"]  = "9人局（平民）",
  ["10 players (villager)"] = "10人局（平民）",
  
  -- 平民规则翻译
  ["#VillagerReward"] = "平民奖励",
  ["#VillagerVictory"] = "平民胜利",
  ["villager"] = "平民",
  ["Enter custom answer"]="填空",
  ["Confirm"]="确定",

}


loadMissingTranslations {["skin_dialog"] = "武将皮肤选择"}
loadMissingTranslations {["default_skin"] = "默认皮肤"}

for i = 1, 10 do
    loadMissingTranslations {["skin_" .. tostring(i)] = "皮肤" .. tostring(i)}
end


-- Villager reward/victory are registered through the native mode policy above.

sgs.Sanguosha:addShowRoleMode("06_ol")
sgs.Sanguosha:addShowRoleMode("05_ol")
sgs.Sanguosha:addShowRoleMode("04_1v3")
sgs.Sanguosha:addShowRoleMode("04_boss")
sgs.Sanguosha:addShowRoleMode("08_defense")
sgs.Sanguosha:addShowRoleMode("03_1v2")
sgs.Sanguosha:addShowRoleMode("04_2v2")

--sgs.Sanguosha:addBanPackage("Shijia")

local caocao = sgs.Sanguosha:getGeneral("nos_caocao")
--caocao:setRealName("caocao")
--caocao:setStartHp(2)

animationMax = sgs.CreateRuleSkillV2{
	name = "animationMax",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TurnStarted},
	global = true,
	on_effect = function(self, event, room, player, ctx)
		local players = room:getPlayers()
		local thread = room:getThread()
		local targets =sgs.SPlayerList()
			targets:append(player)
		local general = player:getGeneral()
		local realName = general:getRealName()
		local skin = general:getSkin()
		room:writeToConsole(realName)
		room:writeToConsole(skin)

		-- 检测特效图片是否存在
		local effectPath = "image/dynamic/general/" .. realName .. "/" .. skin .. "/idle"
		local hasEffectImages = false

		-- 检查是否有序列帧图片（检查前几帧）
		for i = 1, 5 do
			local frameNumber = string.format("%04d", i)
			local imagePath = effectPath .. "/" .. frameNumber .. ".png"
			local file = io.open(imagePath, "r")
			if file then
				file:close()
				hasEffectImages = true
		--		room:writeToConsole("找到特效图片: " .. imagePath)
				break
			end
		end

		-- 只有找到特效图片才触发动画
		if hasEffectImages then
		--	room:writeToConsole("触发generalMax特效: " .. realName .. "/" .. skin)
			room:doAnimate(2,"ghost=generalMax:"..realName.."/"..skin.."/idle","",players)
		else
		--	room:writeToConsole("未找到特效图片，跳过generalMax: " .. effectPath)
		end

	--	room:doAnimate(2,"skill=game/zhengjing/zhengjing:","game_zhengjing",targets)
	--	room:writeToConsole(room:getMode())
	--	room:setLoopEmotion(player:getNext(),"damage")
	end,

	can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() then return self:objectName(), player end
    end,
}
--addToSkills(animationMax)

loadMissingTranslations {
	["mobilemou_caopi"] = "谋曹丕",
	["#mobilemou_caopi"] = "魏我独尊",
	["illustrator:mobilemou_caopi"] = "",
	["mobilemouxingshang"] = "行殇",
	[":mobilemouxingshang"] = "当其他角色死亡时，或一名角色受到伤害后（每回合限一次），你获得2枚“颂”（你至多拥有9枚颂”）。出牌阶段限两次，你可以选择一名角色并移去任意枚“颂”，然后你令其执行对应的一项：2枚，摸X张牌（X为已死亡角色数，至少为2且至多为5），复原武将牌。5枚，回复1点体力并增加1点体力上限，然后随机恢复一个被废除的装备栏（体力上限不大于9的目标可执行此效果）或追思一名未被追思过的已阵亡角色的武将牌上的技能，然后你失去技能“行殇”、“放逐”和“颂威”（若该角色为你且你拥有技能“行殇”）。",
	["mobilemoufangzhu"] = "放逐",
	[":mobilemoufangzhu"] = "出牌阶段限一次，若你有“行殇”，你可以选择一名其他角色，移去任意枚“颂”并令其执行对应的选项：1枚，直到其下回合结束，其不能使用除基本牌以外的手牌；2枚，直到其下回合结束，其武将技能失效，其不可响应另一名角色使用的牌，其不能使用除锦囊牌以外的手牌；3枚，令其翻面，直到其下回合结束前，其不能使用除装备牌以外的手牌。",
	["mobilemousongwei"] = "颂威",
	[":mobilemousongwei"] = "主公技，出牌阶段开始时，若你有“行殇”，你获得X枚“颂”（X为其他魏势力角色数的两倍）。每局游戏限一次，出牌阶段，你可以令一名其他魏势力角色失去所有技能。",
	["mobilemouxingshang_song"] = "颂",
	["2mobilemouxingshang"] = "其摸%src张牌并复原武将牌",
	["5mobilemouxingshang"] = "【回复1点体力和体力上限，随机恢复一个装备栏】或【追思角色】",
	["5mobilemouxingshang1"] = "回复1点体力并增加1点体力上限，随机恢复一个装备栏或追思角色",
	["5mobilemouxingshang2"] = "行殇：请选择一名死亡角色追思",
	["mobilemoufangzhu:1"] = "移去1枚“颂”",
	["mobilemoufangzhu:2"] = "移去2枚“颂”",
	["mobilemoufangzhu:3"] = "移去3枚“颂”",
	["$mobilemouxingshang1"] = "哼哼哼，纵是身死，仍要为我所用。",
	["$mobilemouxingshang2"] = "汝九泉之下，定会感朕之情。",
	["$mobilemoufangzhu1"] = "战败而降，辱我国威，岂能轻饶。",
	["$mobilemoufangzhu2"] = "此等过错，不杀已是承了朕恩。",
	["$mobilemousongwei1"] = "江山锦绣，尽在朕手。",
	["$mobilemousongwei2"] = "成功建业，扬我魏威！",
	["~mobilemou_caopi"] = "大魏如何踏破吴蜀，就全看叡儿了……",
	["mobilemouxingshangZhuisi"] = "行殇追思",
	["ZhuisiPlayer"] = "追思%src",
	}