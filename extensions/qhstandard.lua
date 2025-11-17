---@diagnostic disable: lowercase-global
-- module("extensions.qhstandard", package.seeall)
extension = sgs.Package("qhstandard", sgs.Package_GeneralPack)      -- 标准版
extensionMyth = sgs.Package("mythology", sgs.Package_GeneralPack)   -- 神话降临
extensionWind = sgs.Package("qhwind", sgs.Package_GeneralPack)      -- 风包
extensionFire = sgs.Package("qhfire", sgs.Package_GeneralPack)      -- 火包
extensionCard = sgs.Package("qhstandardCard", sgs.Package_CardPack) -- 卡牌拓展

sgs.LoadTranslationTable {                                          -- 翻译表

    ["qhstandard"] = "标准版-强化",
    ["mythology"] = "神话降临",
    ["qhwind"] = "风包-强化",
    ["qhfire"] = "火包-强化",
    ["qhstandardCard"] = "标准卡牌-强化",
    ["qh"] = "强化",
}

-- 是否新增势力
local new_kingdom = 2
-- 为0势力为 魏蜀吴群， 为1 势力转变为 qh ，为2 势力转变为 qh 且游戏开始时将势力转变回 魏蜀吴群

local qhstandardWei
local qhstandardShu
local qhstandardWu
local qhstandardQun
local qhstandardGod
if new_kingdom == 1 or new_kingdom == 2 then
    qhstandardWei = "qh"
    qhstandardShu = "qh"
    qhstandardWu = "qh"
    qhstandardQun = "qh"
    qhstandardGod = "qh"
else
    qhstandardWei = "wei"
    qhstandardShu = "shu"
    qhstandardWu = "wu"
    qhstandardQun = "qun"
    qhstandardGod = "god"
end

----------------添加势力----------------

do
    require "lua.config"
    local cfg = config
    table.insert(cfg.kingdoms, "qh")
    cfg.kingdom_colors["qh"] = "#91ffb2"
end

----------------定义函数----------------

Table2IntList = function(theTable)
    local result = sgs.IntList()
    for i = 1, #theTable, 1 do
        result:append(theTable[i])
    end
    return result
end

----------------创建卡牌----------------

-- 乐不思蜀-强化
qhstandard_indulgence = sgs.CreateTrickCard {           -- 锦囊牌
    name = "qhstandard_indulgence",
    class_name = "QhstandardIndulgence",                -- 卡牌的类名
    subtype = "delayed_trick",                          -- 卡牌的子类型
    subclass = sgs.LuaTrickCard_TypeDelayedTrick,       -- 卡牌的类型 延时锦囊
    target_fixed = false,                               -- 选择目标
    can_recast = false,                                 -- 不能重铸
    is_cancelable = true,                               -- 可以无懈
    movable = false,                                    -- 不为天灾类
    filter = function(self, targets, to_select, player) -- 使用对象的约束条件
        return #targets == 0 and not to_select:containsTrick("qhstandard_indulgence") and to_select:objectName() ~=
            player:objectName()
    end,
    available = function(self, player) -- 主动使用
        return true
    end,
    on_use = function(self, room, source, targets) -- 使用卡牌时
        source:broadcastSkillInvoke("indulgence")        -- 播放卡牌配音
        -- if not room:CardInTable(self) then
        --     return
        -- end
        -- local nullified_list = room:getTag("CardUseNullifiedList"):toStringList()
        -- local all_nullified = table.contains(nullified_list, "_ALL_TARGETS")

        -- local targets = sgs.SPlayerList()
        -- for _, p in ipairs(targets_table) do
        --     targets:append(p)
        -- end

        -- if all_nullified or targets:isEmpty() or table.contains(nullified_list, targets:first():objectName()) or
        --     targets:first():isDead() or not targets:first():hasJudgeArea() or
        --     targets:first():containsTrick(self:objectName()) then
        --     if not room:CardInTable(self) then
        --         return
        --     end
        --     local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), "",
        --         self:getSkillName(), "")
        --     local use_data = sgs.QVariant()
        --     use_data:setValue(self:getRealCard())
        --     reason.m_extraData = use_data
        --     local use = sgs.CardUseStruct(self, source, targets)
        --     reason.m_useStruct = use
        --     room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, reason, true)
        -- else
        --     if not room:CardInTable(self) then
        --         return
        --     end
        --     local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(),
        --         targets:first():objectName(), self:getSkillName(), "")
        --     local use_data = sgs.QVariant()
        --     use_data:setValue(self:getRealCard())
        --     reason.m_extraData = use_data
        --     local use = sgs.CardUseStruct(self, source, targets)
        --     reason.m_useStruct = use
        --     room:moveCardTo(self, targets:first(), sgs.Player_PlaceDelayedTrick, reason, true)
        -- end
        local use = room:getTag("UseHistory"..self:toString()):toCardUse()
    	-- for _,to in sgs.list(table.copyFrom(targets))do
		-- 	local effect = sgs.CardEffectStruct()
		-- 	effect.from = source
		-- 	effect.card = self
		-- 	effect.multiple = #targets>1
	    --     effect.to = to
		-- 	effect.no_offset = table.contains(use.no_offset_list,"_ALL_TARGETS") or table.contains(use.no_offset_list,to:objectName())
		-- 	effect.no_respond = table.contains(use.no_respond_list,"_ALL_TARGETS") or table.contains(use.no_respond_list,to:objectName())
		-- 	effect.nullified = table.contains(use.nullified_list,"_ALL_TARGETS") or table.contains(use.nullified_list,to:objectName())
		-- 	if effect.nullified then room:setEmotion(to,"skill_nullify") continue end
		-- 	if to:getCardCount(true,true)>0 then
		-- 		if room:isCanceled(effect) then
		-- 			table.removeOne(targets,to)
		-- 			continue
		-- 		end
		-- 		self:onEffect(effect)
		-- 	end
        -- end
		use_DelayedTrick(self,room,source,targets)
    end,
    on_effect = function(self, effect) -- 延时锦囊判定时
        local to = effect.to
        local room = to:getRoom()
        local msg = sgs.LogMessage()   -- 创建消息
        msg.type = "#DelayedTrick"     -- 消息结构类型(发送的消息是什么)
        msg.from = to                  -- 行为发起对象
        msg.arg = self:objectName()    -- 参数1
        room:sendLog(msg)              -- 发送消息
        local judge = sgs.JudgeStruct()
        judge.pattern = ".|heart|3~10" -- 红桃3~10
        judge.good = true
        judge.reason = self:objectName()
        judge.who = to
        room:judge(judge)
        if not judge:isGood() then
            if not to:isSkipped(sgs.Player_Finish) then -- 如果阶段存在
                to:skip(sgs.Player_Play, false)         -- 跳过出牌阶段
            end
        end
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, to:objectName())
        room:throwCard(self, reason, nil) -- 弃牌
    end
}

----------------添加卡牌----------------

--for i = 1, 2 do
local qhstandard_indulgence = qhstandard_indulgence:clone()
qhstandard_indulgence:setSuit(math.random(0, 3))    -- 随机花色
qhstandard_indulgence:setNumber(math.random(1, 13)) -- 随机点数
qhstandard_indulgence:setParent(extensionCard)
--end

sgs.LoadTranslationTable { -- 翻译表

    ["qhstandard_indulgence"] = "乐不思蜀-强化",
    [":qhstandard_indulgence"] = "延时锦囊牌\
	<b>时机</b>：出牌阶段\
    <b>目标</b>：一名其他角色\
    <b>效果</b>：目标角色判定，若结果不为红桃3~10，其跳过出牌阶段。"

}

----------------创建武将----------------

-- 魏-标准版
qhstandardcaocao = sgs.General(extension, "qhstandardcaocao$", qhstandardWei, 5, true, false, false) -- 主公武将要在名字后加$
qhstandardsimayi = sgs.General(extension, "qhstandardsimayi", qhstandardWei, 4, true, false, false)
qhstandardxiahoudun = sgs.General(extension, "qhstandardxiahoudun", qhstandardWei, 5, true, false, false)
qhstandardzhangliao = sgs.General(extension, "qhstandardzhangliao", qhstandardWei, 5, true, false, false)
qhstandardxuchu = sgs.General(extension, "qhstandardxuchu", qhstandardWei, 5, true, false, false)
qhstandardguojia = sgs.General(extension, "qhstandardguojia", qhstandardWei, 4, true, false, false)
qhstandardzhenji = sgs.General(extension, "qhstandardzhenji", qhstandardWei, 4, false, false, false)

-- 魏-风林火山
qhwindxiahouyuan = sgs.General(extensionWind, "qhwindxiahouyuan", qhstandardWei, 5, true, false, false)
qhwindcaoren = sgs.General(extensionWind, "qhwindcaoren", qhstandardWei, 5, true, false, false)
qhfiredianwei = sgs.General(extensionFire, "qhfiredianwei", qhstandardWei, 5, true, false, false)
qhfirexunyu = sgs.General(extensionFire, "qhfirexunyu", qhstandardWei, 4, true, false, false)

-- 蜀-标准版
qhstandardliubei = sgs.General(extension, "qhstandardliubei$", qhstandardShu, 5, true, false, false) -- 主公武将要在名字后加$
qhstandardguanyu = sgs.General(extension, "qhstandardguanyu", qhstandardShu, 5, true, false, false)
qhstandardzhangfei = sgs.General(extension, "qhstandardzhangfei", qhstandardShu, 5, true, false, false)
qhstandardzhugeliang = sgs.General(extension, "qhstandardzhugeliang", qhstandardShu, 4, true, false, false)
qhstandardzhaoyun = sgs.General(extension, "qhstandardzhaoyun", qhstandardShu, 5, true, false, false)
qhstandardmachao = sgs.General(extension, "qhstandardmachao", qhstandardShu, 5, true, false, false)
qhstandardhuangyueying = sgs.General(extension, "qhstandardhuangyueying", qhstandardShu, 4, false, false, false)

-- 蜀-风林火山
qhwindhuangzhong = sgs.General(extensionWind, "qhwindhuangzhong", qhstandardShu, 5, true, false, false)
qhwindweiyan = sgs.General(extensionWind, "qhwindweiyan", qhstandardShu, 5, true, false, false)
qhfirepangtong = sgs.General(extensionFire, "qhfirepangtong", qhstandardShu, 4, true, false, false)
qhfirewolong = sgs.General(extensionFire, "qhfirewolong", qhstandardShu, 4, true, false, false)

-- 吴-标准版
qhstandardsunquan = sgs.General(extension, "qhstandardsunquan$", qhstandardWu, 5, true, false, false) -- 主公武将要在名字后加$
qhstandardganning = sgs.General(extension, "qhstandardganning", qhstandardWu, 5, true, false, false)
qhstandardlvmeng = sgs.General(extension, "qhstandardlvmeng", qhstandardWu, 5, true, false, false)
qhstandardhuanggai = sgs.General(extension, "qhstandardhuanggai", qhstandardWu, 5, true, false, false)
qhstandardzhouyu = sgs.General(extension, "qhstandardzhouyu", qhstandardWu, 4, true, false, false)
qhstandarddaqiao = sgs.General(extension, "qhstandarddaqiao", qhstandardWu, 4, false, false, false)
qhstandardluxun = sgs.General(extension, "qhstandardluxun", qhstandardWu, 4, true, false, false)
qhstandardsunshangxiang = sgs.General(extension, "qhstandardsunshangxiang", qhstandardWu, 4, false, false, false)

-- 吴-风林火山
qhwindxiaoqiao = sgs.General(extensionWind, "qhwindxiaoqiao", qhstandardWu, 4, false, false, false)
qhwindzhoutai = sgs.General(extensionWind, "qhwindzhoutai", qhstandardWu, 5, true, false, false)
qhfiretaishici = sgs.General(extensionFire, "qhfiretaishici", qhstandardWu, 5, true, false, false)

-- 群-标准版
qhstandardhuatuo = sgs.General(extension, "qhstandardhuatuo", qhstandardQun, 4, true, false, false)
qhstandardlvbu = sgs.General(extension, "qhstandardlvbu", qhstandardQun, 5, true, false, false)
qhstandarddiaochan = sgs.General(extension, "qhstandarddiaochan", qhstandardQun, 4, false, false, false)
qhstandardhuaxiong = sgs.General(extension, "qhstandardhuaxiong", qhstandardQun, 6, true, false, false)
qhstandardgongsunzan = sgs.General(extension, "qhstandardgongsunzan", qhstandardQun, 5, true, false, false)

-- 群-风林火山
qhwindzhangjiao = sgs.General(extensionWind, "qhwindzhangjiao$", qhstandardQun, 4, true, false, false) -- 主公武将要在名字后加$
qhwindyuji = sgs.General(extensionWind, "qhwindyuji", qhstandardQun, 4, true, false, false)
qhfireyuanshao = sgs.General(extensionFire, "qhfireyuanshao$", qhstandardQun, 5, true, false, false)   -- 主公武将要在名字后加$
qhfireyanliangwenchou = sgs.General(extensionFire, "qhfireyanliangwenchou", qhstandardQun, 5, true, false, false)
qhfirepangde = sgs.General(extensionFire, "qhfirepangde", qhstandardQun, 5, true, false, false)

-- 神-风林火山
qhwindshenguanyu = sgs.General(extensionWind, "qhwindshenguanyu", qhstandardGod, 5, true, false, false)
qhwindshenlvmeng = sgs.General(extensionWind, "qhwindshenlvmeng", qhstandardGod, 4, true, false, false)
qhfireshenzhouyu = sgs.General(extensionFire, "qhfireshenzhouyu", qhstandardGod, 5, true, false, false)
qhfireshenzhugeliang = sgs.General(extensionFire, "qhfireshenzhugeliang", qhstandardGod, 4, true, false, false)

-- 神话降临
mythhuangyueying = sgs.General(extensionMyth, "mythhuangyueying", qhstandardShu, 5, false, false, false)
mythcaiwenji = sgs.General(extensionMyth, "mythcaiwenji", qhstandardQun, 4, false, false, false)
mythtenggongzhu = sgs.General(extensionMyth, "mythtenggongzhu", qhstandardWu, 4, false, false, false)
mythtengfanglan = sgs.General(extensionMyth, "mythtengfanglan", qhstandardWu, 4, false, false, false)
mythcaojinyu = sgs.General(extensionMyth, "mythcaojinyu", qhstandardWei, 4, false, false, false)
mythsunluyu = sgs.General(extensionMyth, "mythsunluyu", qhstandardWu, 4, false, false, false)
mythwuzhuge = sgs.General(extensionMyth, "mythwuzhuge", qhstandardShu, 7, true, false, false, 4)
mythxuelingyun = sgs.General(extensionMyth, "mythxuelingyun", qhstandardWu, 4, false, false, false)

-- 特殊测试将
qhstandardtest = sgs.General(extension, "qhstandardtest", "qh", 10, true, true, true)


local general_table = { "qhstandardcaocao", "qhstandardsimayi", "qhstandardxiahoudun", "qhstandardzhangliao",
    "qhstandardxuchu", "qhstandardguojia", "qhstandardzhenji", "qhstandardliubei",
    "qhstandardguanyu", "qhstandardzhangfei", "qhstandardzhugeliang", "qhstandardzhaoyun",
    "qhstandardmachao", "qhstandardhuangyueying", "qhstandardsunquan", "qhstandardganning",
    "qhstandardlvmeng", "qhstandardhuanggai", "qhstandardzhouyu", "qhstandarddaqiao",
    "qhstandardluxun", "qhstandardsunshangxiang", "qhstandardhuatuo", "qhstandardlvbu",
    "qhstandarddiaochan", "qhstandardhuaxiong", "qhstandardgongsunzan",
    "qhwindxiahouyuan", "qhwindcaoren", "qhwindhuangzhong", "qhwindweiyan", "qhwindxiaoqiao",
    "qhwindzhoutai", "qhwindzhangjiao", "qhwindyuji", "qhwindshenguanyu", "qhwindshenlvmeng",
    "qhfiredianwei", "qhfirexunyu", "qhfirepangtong", "qhfirewolong", "qhfiretaishici",
    "qhfireyuanshao", "qhfireyanliangwenchou", "qhfirepangde", "qhfireshenzhouyu", "qhfireshenzhugeliang"
}
function getQhGeneral()
    local new_generaltable = {}
    local n = 0
    for i = 1, 30 do
        local name = general_table[math.random(1, #general_table)]
        if not table.contains(new_generaltable, name) then -- 不包含
            table.insert(new_generaltable, name)
            n = n + 1                                      -- 计数
            if n == 7 then
                break                                      -- 终止循环
            end
        end
    end
    return new_generaltable
end

qhstandardchangehero = sgs.CreateTriggerSkill {
    name = "qhstandardchangehero",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.GameStart },
    priority = 100,
    on_trigger = function(self, event, player, data, room)
        local playerlist = room:getAllPlayers()                                -- 获取所有角色名单
        room:handleAcquireDetachSkills(player, "-qhstandardchangehero", false) -- 失去此技能
        for _, play in sgs.qlist(playerlist) do                                -- 对名单中的所有角色进行扫描
            local start = false
            if play:getSeat() < player:getSeat() then                          -- 座位在自己之前，需重新进行游戏开始
                start = true
            end
            local new_generaltable = getQhGeneral()
            local new_general = room:askForGeneral(play, table.concat(new_generaltable, "+"))     -- 选将
            room:changeHero(play, new_general, true, start, false, true)                          -- 变身
            table.removeOne(general_table, new_general)                                           -- 移除
            local General2Name = play:getGeneral2Name()
            if General2Name and General2Name ~= "" then                                           -- 副将
                new_generaltable = getQhGeneral()
                local new_general = room:askForGeneral(play, table.concat(new_generaltable, "+")) -- 选将
                room:changeHero(play, new_general, true, start, true, true)                       -- 变身
                table.removeOne(general_table, new_general)                                       -- 移除
            end
        end
    end
}

--模式：兵精粮足
globalbingjing = sgs.CreateTriggerSkill {
    name = "globalbingjing",
    frequency = sgs.Skill_Frequent,
    events = { sgs.GameStart, sgs.DrawNCards },
    priority = -1,
    global = true,
    on_trigger = function(self, event, player, data, room)
        -- if event == sgs.GameStart then
        --     if room:getTag("globalbingjing"):toInt() ~= 1 then
        --         if player:getState() ~= "robot" then               --非机器人
        --             if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
        --             room:setTag("globalbingjing", sgs.QVariant(1)) --标记已启用
        --             local msg = sgs.LogMessage()                   -- 创建消息
        --             msg.type = "#globalbingjing"                   -- 消息结构类型
        --             room:sendLog(msg)
        --             for _, play in sgs.qlist(room:getAllPlayers()) do
        --                 room:gainMaxHp(play, 2, self:objectName());
        --                 local Recover = sgs.RecoverStruct() -- 定义恢复结构体
        --                 Recover.recover = 2
        --                 Recover.who = play
        --                 room:recover(play, Recover, true) -- 回血
        --             end
        --         end
        --     end
        -- elseif event == sgs.DrawNCards then
        --     if room:getTag("globalbingjing"):toInt() == 1 then
        --         local count = data:toInt()
        --         data:setValue(count + 3)
        --     end
        -- end
    end,
    can_trigger = function(self, target)
        if target then
            return true
        end
    end
}

qhstandardtest:addSkill(qhstandardchangehero)
qhstandardtest:addSkill(globalbingjing)

sgs.LoadTranslationTable { -- 翻译表
    ["qhstandardtest"] = "测试模式",
    ["#qhstandardtest"] = "测试模式",
    ["qhstandardchangehero"] = "全场变身",
    [":qhstandardchangehero"] = "游戏开始时，所有角色在指定武将中进行选将并变身。\
★标准版-强化 风包-强化 火包-强化 的全部武将",
    ["globalbingjing"] = "模式：兵精粮足",
    [":globalbingjing"] = "若启用本模式，所有角色体力上限+2，摸牌阶段，多摸3张牌。",
    ["#qhstandardtestmsg"] = "from = %from ， to = %to ， arg = %arg ， arg2 = %arg2 ，card = %card，",
    ["@qhstandardMaxcards"] = "qh手牌上限",
    ["qhDistance"] = "qh距离修正",
    ["qhstandardMaxCardsExtra"] = "qh手牌上限修正",
    ["qhMaxcards_sub"] = "qh手牌上限减少",
    ["qhDistance_add"] = "距离增加",
    ["#globalbingjing"] = "模式：<font color = 'blue'><b>兵精粮足</b></font>已启用。",
}

----------------创建技能----------------

----------------全局技能----------------

qhstandardMaxCardsExtra = sgs.CreateMaxCardsSkill { -- 手牌上限技
    name = "qhstandardMaxCardsExtra",
    extra_func = function(self, target)             -- 修改手牌上限
        local n = 0
        if target:getMark("@qhstandardMaxcards") > 0 then
            n = n + target:getMark("@qhstandardMaxcards")
        end
        if target:getMark("&qhMaxcards_sub-SelfClear") > 0 then
            n = n - target:getMark("&qhMaxcards_sub-SelfClear")
        end
        if target:getMark("&qhstandardluoshen-Clear") > 0 and target:hasSkill("qhstandardluoshen") then
            n = n + target:getMark("&qhstandardluoshen-Clear")
        end
        if target:getMark("qhstandardkeji-Clear") == 1 and target:hasSkill("qhstandardkeji") then
            n = n + 12
        end
        if target:hasSkill("mythliunian") then
            n = n + 4
            if target:getMark("&mythliunian_usedTimes") == 2 then
                n = n + 10
            end
        end
        if target:hasSkill("mythaichen") then
            n = n + 4
        end
        if target:hasSkill("mythyuqi") then
            local maxCard = target:getMark("SkillDescriptionArg6_mythyuqi")
            if maxCard == 0 then
                maxCard = 2
            end
            local m = math.max(maxCard, target:getMark("&mythyuqi_maxCard-SelfClear"))
            n = n + m
        end
        if target:hasSkill("mythxialei") then
            n = n + 4
        end
        return n
    end
}

qhstandardMaxCardFixed = sgs.CreateMaxCardsSkill { -- 手牌上限技
    name = "qhstandardMaxCardFixed",
    fixed_func = function(self, target)            -- 锁定手牌上限
        local n = -1                               -- 不锁定
        if target:hasSkill("qhstandardyingzi") then
            n = target:getMaxHp()
        end
        if target:hasSkill("qhwindbuqu") and target:getPile("qhwindbuqu"):length() > 0 then
            n = target:getMaxHp()
        end
        return n
    end
}

qhstandardTargetMod = sgs.CreateTargetModSkill {  -- 目标增强技
    name = "qhstandardTargetMod",
    pattern = ".",                                -- 全部类型
    residue_func = function(self, from, card, to) -- 卡牌使用次数
        local n = 0
        if from:hasSkill("qhstandardkurou") then
            if from:getMark("qhstandardkurou_residue") > 0 and card:isKindOf("Slash") then -- 苦肉 杀
                n = n + from:getMark("qhstandardkurou_residue")
            end
        end
        if from:hasSkill("mythbeifen") then
            if from:property("mythbeifen"):toInt() == 1 then
                n = n + 1000
            end
        end
        if from:hasSkill("mythliunian") then
            local usedTimes = from:getMark("&mythliunian_usedTimes")
            n = n + 1 + usedTimes
        end
        if from:hasSkill("qhwindwushen") then
            if card:isKindOf("Slash") and card:getSuit() == sgs.Card_Heart then
                n = n + 1000
            end
        end
        if from:hasSkill("mythmumu") and card:isKindOf("Slash") then --穆穆 杀
            local num = from:getMark("&mythmumu-Clear")
            if num == 1 then
                n = n - 1
            elseif num == 2 then
                n = n + 1
            end
        end
        if from:hasSkill("qhfiretianyi") then
            if from:getMark("qhfiretianyi_success-Clear") == 1 and card:isKindOf("Slash") then
                n = n + 1
            end
        end
        return n
    end,
    extra_target_func = function(self, from, card, to)                             -- 卡牌目标数量
        local n = 0
        if from:hasSkill("qhstandardqixi") and card:isKindOf("Dismantlement") then -- 奇袭 过河拆桥
            n = n + 1
        end
        if from:hasSkill("qhstandardkurou") and from:getMark("qhstandardkurou_extra_distance") > 0 and
            card:isKindOf("Slash") then -- 苦肉 杀
            n = n + 1
        end
        if from:hasSkill("qhfiretianyi") then
            if from:getMark("qhfiretianyi_success-Clear") == 1 and card:isKindOf("Slash") then
                n = n + 1
            end
        end
        return n
    end,
    distance_limit_func = function(self, from, card, to) -- 卡牌使用距离
        local n = 0
        if from:hasSkill("qhstandardkurou") and from:getMark("qhstandardkurou_extra_distance") > 0 and
            card:isKindOf("Slash") then -- 苦肉 杀
            n = n + 2
        end
        if from:hasSkill("qhwindshensu") and (card:getSkillName() == "qhwindshensu") then -- 神速杀
            n = n + 1000
        end
        if from:hasSkill("mythqicai") and card:isKindOf("TrickCard") then
            n = n + 1000
        end
        if from:hasSkill("mythbeifen") then
            if from:property("mythbeifen"):toInt() == 1 then
                n = n + 1000
            end
        end
        if from:hasSkill("qhwindwushen") then
            if card:isKindOf("Slash") and card:isRed() then
                n = n + 1000
            end
        end
        if from:hasSkill("qhfiretianyi") then
            if from:getMark("qhfiretianyi_success-Clear") == 1 and card:isKindOf("Slash") then
                n = n + 1000
            end
        end
        if from:hasSkill("qhfireyeyan") then
            if to and to:getMark("qhfireyeyanTarget-Clear") == 1 then
                n = n + 1000
            end
        end
        return n
    end
}

-- 攻击范围技
qhstandardAttackRange = sgs.CreateAttackRangeSkill {
    name = "qhstandardAttackRange",
    extra_func = function(self, target, include_weapon)
        local n = 0
        if target:hasSkill("qhwindgongshu") and not target:getWeapon() then
            n = n + 2
        end
        if target:hasSkill("qhstandardyanyue") then
            n = n + 2
        end
        return n
    end,
    fixed_func = function(self, target, include_weapon)
        local n = -1 -- 不锁定
        return n
    end
}

-- 距离修改技
qhDistance = sgs.CreateDistanceSkill {
    name = "qhDistance",
    correct_func = function(self, from, to)
        local number = 0
        if to:getMark("&qhDistance_add-Clear") > 0 then
            number = number + to:getMark("&qhDistance_add-Clear")
        end
        if from:hasSkill("mythshuangjia") then
            number = number - from:property("mythhujia"):toInt()
        end
        if to:hasSkill("mythshuangjia") then
            number = number + to:property("mythhujia"):toInt()
        end
        return number
    end
}

----------------添加全局技能----------------
local skills = sgs.SkillList()

if not sgs.Sanguosha:getSkill("qhstandardMaxCardsExtra") then
    skills:append(qhstandardMaxCardsExtra)
end
if not sgs.Sanguosha:getSkill("qhstandardMaxCardFixed") then
    skills:append(qhstandardMaxCardFixed)
end
if not sgs.Sanguosha:getSkill("qhstandardTargetMod") then
    skills:append(qhstandardTargetMod)
end
if not sgs.Sanguosha:getSkill("qhstandardAttackRange") then
    skills:append(qhstandardAttackRange)
end
if not sgs.Sanguosha:getSkill("qhDistance") then
    skills:append(qhDistance)
end


----------------转变势力技----------------

-- 魏国
qhstandardweiguo = sgs.CreateTriggerSkill {
    name = "qhstandardweiguo",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.GameStart },
    priority = 4,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom() -- 获取房间
        local Kd = player:getKingdom()
        local choice = "zhuanbianWeiguo"
        if player:hasSkill("qhstandardshuguo") then                -- 若拥有蜀国
            room:detachSkillFromPlayer(player, "qhstandardshuguo") -- 失去此技能
            choice = choice .. "+zhuanbianShuguo"
        end
        if player:hasSkill("qhstandardwuguo") then                -- 若拥有吴国
            room:detachSkillFromPlayer(player, "qhstandardwuguo") -- 失去此技能
            choice = choice .. "+zhuanbianWuguo"
        end
        if player:hasSkill("qhstandardqunguo") then                -- 若拥有群国
            room:detachSkillFromPlayer(player, "qhstandardqunguo") -- 失去此技能
            choice = choice .. "+zhuanbianQunguo"
        end
        local KdNew
        if choice == "zhuanbianWeiguo" then
            KdNew = "wei"
        else
            local KdChoice = room:askForChoice(player, self:objectName(), choice) -- 选择
            if KdChoice == "zhuanbianWeiguo" then                                 -- 选择魏国
                KdNew = "wei"
            end
            if KdChoice == "zhuanbianShuguo" then -- 选择蜀国
                KdNew = "shu"
            end
            if KdChoice == "zhuanbianWuguo" then -- 选择吴国
                KdNew = "wu"
            end
            if KdChoice == "zhuanbianQunguo" then -- 选择吴国
                KdNew = "qun"
            end
        end
        room:setPlayerProperty(player, "kingdom", sgs.QVariant(KdNew))         -- 设置国籍
        -- 设置属性类型必须小写,设置具体属性要加 sgs.QVariant
        local msg = sgs.LogMessage()                                           -- 创建消息
        msg.type = "#qhstandardweiguo"                                         -- 消息结构类型(发送的消息是什么)
        msg.from = player                                                      -- 行为发起对象
        msg.arg = Kd                                                           -- 参数1
        msg.arg2 = KdNew                                                       -- 参数2
        room:sendLog(msg)                                                      -- 发送消息
        if player:hasSkill(self:objectName()) then                             -- 如果有此技能
            room:handleAcquireDetachSkills(player, "-qhstandardweiguo", false) -- 失去此技能
        end
    end
}

-- 蜀国
qhstandardshuguo = sgs.CreateTriggerSkill {
    name = "qhstandardshuguo",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.GameStart },
    priority = 4,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom() -- 获取房间
        local Kd = player:getKingdom()
        local choice = "zhuanbianShuguo"
        if player:hasSkill("qhstandardweiguo") then                -- 若拥有魏国
            room:detachSkillFromPlayer(player, "qhstandardweiguo") -- 失去此技能
            choice = choice .. "+zhuanbianWeiguo"
        end
        if player:hasSkill("qhstandardwuguo") then                -- 若拥有吴国
            room:detachSkillFromPlayer(player, "qhstandardwuguo") -- 失去此技能
            choice = choice .. "+zhuanbianWuguo"
        end
        if player:hasSkill("qhstandardqunguo") then                -- 若拥有群国
            room:detachSkillFromPlayer(player, "qhstandardqunguo") -- 失去此技能
            choice = choice .. "+zhuanbianQunguo"
        end
        local KdNew
        if choice == "zhuanbianShuguo" then
            KdNew = "shu"
        else
            local KdChoice = room:askForChoice(player, self:objectName(), choice) -- 选择
            if KdChoice == "zhuanbianWeiguo" then                                 -- 选择魏国
                KdNew = "wei"
            end
            if KdChoice == "zhuanbianShuguo" then -- 选择蜀国
                KdNew = "shu"
            end
            if KdChoice == "zhuanbianWuguo" then -- 选择吴国
                KdNew = "wu"
            end
            if KdChoice == "zhuanbianQunguo" then -- 选择吴国
                KdNew = "qun"
            end
        end
        room:setPlayerProperty(player, "kingdom", sgs.QVariant(KdNew))         -- 设置国籍
        -- 设置属性类型必须小写,设置具体属性要加 sgs.QVariant
        local msg = sgs.LogMessage()                                           -- 创建消息
        msg.type = "#qhstandardshuguo"                                         -- 消息结构类型(发送的消息是什么)
        msg.from = player                                                      -- 行为发起对象
        msg.arg = Kd                                                           -- 参数1
        msg.arg2 = KdNew                                                       -- 参数2
        room:sendLog(msg)                                                      -- 发送消息
        if player:hasSkill(self:objectName()) then                             -- 如果有此技能
            room:handleAcquireDetachSkills(player, "-qhstandardshuguo", false) -- 失去此技能--失去此技能
        end
    end
}

-- 吴国
qhstandardwuguo = sgs.CreateTriggerSkill {
    name = "qhstandardwuguo",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.GameStart },
    priority = 4,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom() -- 获取房间
        local Kd = player:getKingdom()
        local choice = "zhuanbianWuguo"
        if player:hasSkill("qhstandardweiguo") then                -- 若拥有魏国
            room:detachSkillFromPlayer(player, "qhstandardweiguo") -- 失去此技能
            choice = choice .. "+zhuanbianWeiguo"
        end
        if player:hasSkill("qhstandardshuguo") then                -- 若拥有蜀国
            room:detachSkillFromPlayer(player, "qhstandardshuguo") -- 失去此技能
            choice = choice .. "+zhuanbianShuguo"
        end
        if player:hasSkill("qhstandardqunguo") then                -- 若拥有群国
            room:detachSkillFromPlayer(player, "qhstandardqunguo") -- 失去此技能
            choice = choice .. "+zhuanbianQunguo"
        end
        local KdNew
        if choice == "zhuanbianWuguo" then
            KdNew = "wu"
        else
            local KdChoice = room:askForChoice(player, self:objectName(), choice) -- 选择
            if KdChoice == "zhuanbianWeiguo" then                                 -- 选择魏国
                KdNew = "wei"
            end
            if KdChoice == "zhuanbianShuguo" then -- 选择蜀国
                KdNew = "shu"
            end
            if KdChoice == "zhuanbianWuguo" then -- 选择吴国
                KdNew = "wu"
            end
            if KdChoice == "zhuanbianQunguo" then -- 选择吴国
                KdNew = "qun"
            end
        end
        room:setPlayerProperty(player, "kingdom", sgs.QVariant(KdNew))        -- 设置国籍
        -- 设置属性类型必须小写,设置具体属性要加 sgs.QVariant
        local msg = sgs.LogMessage()                                          -- 创建消息
        msg.type = "#qhstandardwuguo"                                         -- 消息结构类型(发送的消息是什么)
        msg.from = player                                                     -- 行为发起对象
        msg.arg = Kd                                                          -- 参数1
        msg.arg2 = KdNew                                                      -- 参数2
        room:sendLog(msg)                                                     -- 发送消息
        if player:hasSkill(self:objectName()) then                            -- 如果有此技能
            room:handleAcquireDetachSkills(player, "-qhstandardwuguo", false) -- 失去此技能
        end
    end
}

-- 群国
qhstandardqunguo = sgs.CreateTriggerSkill {
    name = "qhstandardqunguo",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.GameStart },
    priority = 4,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom() -- 获取房间
        local Kd = player:getKingdom()
        local choice = "zhuanbianQunguo"
        if player:hasSkill("qhstandardweiguo") then                -- 若拥有魏国
            room:detachSkillFromPlayer(player, "qhstandardweiguo") -- 失去此技能
            choice = choice .. "+zhuanbianWeiguo"
        end
        if player:hasSkill("qhstandardshuguo") then                -- 若拥有蜀国
            room:detachSkillFromPlayer(player, "qhstandardshuguo") -- 失去此技能
            choice = choice .. "+zhuanbianShuguo"
        end
        if player:hasSkill("qhstandardwuguo") then                -- 若拥有吴国
            room:detachSkillFromPlayer(player, "qhstandardwuguo") -- 失去此技能
            choice = choice .. "+zhuanbianWuguo"
        end
        local KdNew
        if choice == "zhuanbianQunguo" then
            KdNew = "qun"
        else
            local KdChoice = room:askForChoice(player, self:objectName(), choice) -- 选择
            if KdChoice == "zhuanbianWeiguo" then                                 -- 选择魏国
                KdNew = "wei"
            end
            if KdChoice == "zhuanbianShuguo" then -- 选择蜀国
                KdNew = "shu"
            end
            if KdChoice == "zhuanbianWuguo" then -- 选择吴国
                KdNew = "wu"
            end
            if KdChoice == "zhuanbianQunguo" then -- 选择吴国
                KdNew = "qun"
            end
        end
        room:setPlayerProperty(player, "kingdom", sgs.QVariant(KdNew))         -- 设置国籍
        -- 设置属性类型必须小写,设置具体属性要加 sgs.QVariant
        local msg = sgs.LogMessage()                                           -- 创建消息
        msg.type = "#qhstandardqunguo"                                         -- 消息结构类型(发送的消息是什么)
        msg.from = player                                                      -- 行为发起对象
        msg.arg = Kd                                                           -- 参数1
        msg.arg2 = KdNew                                                       -- 参数2
        room:sendLog(msg)                                                      -- 发送消息
        if player:hasSkill(self:objectName()) then                             -- 如果有此技能
            room:handleAcquireDetachSkills(player, "-qhstandardqunguo", false) -- 失去此技能
        end
    end
}

----------------武将技能----------------

-- 标准版-强化 曹操-奸雄
qhstandardjianxiong = sgs.CreateTriggerSkill {
    name = "qhstandardjianxiong",
    frequency = sgs.Skill_Frequent,
    events = { sgs.Damaged, sgs.ConfirmDamage },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damaged then
            local damage = data:toDamage()                                       -- 获取伤害结构体
            local card = damage.card                                             -- 获取伤害牌
            local card_data = sgs.QVariant()                                     -- 构造一个空的 QVariant 对象
            card_data:setValue(card)                                             -- 为 QVariant 对象设置值:保存卡片信息
            if room:askForSkillInvoke(player, self:objectName(), card_data) then -- 询问发动技能
                if damage.damage > 1 then
                    local num = player:getMark("&qhstandardjianxiong")
                    if damage.damage - 1 > num then
                        room:setPlayerMark(player, "&qhstandardjianxiong", damage.damage - 1)
                    end
                end
                local count = player:getHandcardNum() -- 获取手牌数
                local drawCard
                local msg = sgs.LogMessage()          -- 创建消息
                msg.from = player                     -- 行为发起对象
                msg.arg = count                       -- 参数1
                if count <= 3 then                    -- 小于等于3
                    drawCard = 4 - count
                else                                  -- 不小于等于3
                    drawCard = 1
                end
                local canobtainCard = true
                local ids = sgs.IntList()
                if card then
                    if card:isVirtualCard() then -- 虚拟卡
                        ids = card:getSubcards()
                    else
                        ids:append(card:getEffectiveId())
                    end
                    if ids:isEmpty() then -- 没有牌
                        canobtainCard = false
                    else
                        for _, id in sgs.qlist(ids) do
                            if room:getCardPlace(id) ~= sgs.Player_PlaceTable and room:getCardPlace(id) ~=
                                sgs.Player_DiscardPile then -- 处理区 弃牌堆
                                canobtainCard = false
                            end
                        end
                    end
                else
                    canobtainCard = false
                end
                if canobtainCard then                         -- 如果有伤害牌
                    msg.type = "#qhstandardjianxionghavecard" -- 消息结构类型(发送的消息是什么)
                    msg.card_str = card:toString()
                else
                    msg.type = "#qhstandardjianxiongnilcard" -- 消息结构类型(发送的消息是什么)
                    drawCard = drawCard + 1
                end
                msg.arg2 = drawCard                                 -- 参数2
                room:sendLog(msg)                                   -- 发送消息
                room:broadcastSkillInvoke("jianxiong")              -- 播放配音
                room:drawCards(player, drawCard, self:objectName()) -- 摸牌
                if canobtainCard then                               -- 如果有伤害牌
                    player:obtainCard(card)                         -- 获得伤害牌
                end
            end
        elseif event == sgs.ConfirmDamage then
            local num = player:getMark("&qhstandardjianxiong")
            if num > 0 then
                room:setPlayerMark(player, "&qhstandardjianxiong", 0)
                room:broadcastSkillInvoke("jianxiong") -- 播放配音
                local damage = data:toDamage()
                local msg = sgs.LogMessage()           -- 创建消息
                msg.type = "#qhstandardjianxiongDamage"
                msg.from = player                      -- 行为发起对象
                msg.to:append(damage.to)
                msg.arg = damage.damage
                msg.arg2 = damage.damage + num
                room:sendLog(msg)
                damage.damage = damage.damage + num
                data:setValue(damage)
            end
        end
    end
}

-- 奋血
qhstandardfenxue = sgs.CreateTriggerSkill {
    name = "qhstandardfenxue",
    frequency = sgs.Skill_Frequent,
    events = { sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() ~= sgs.Player_Start then return end
        if player:getMark("@qhstandardfenxue") < 2 then
            player:gainMark("@qhstandardfenxue", 1)
        else
            local others = room:getOtherPlayers(player)
            local target = room:askForPlayerChosen(player, others, self:objectName(), "#qhstandardfenxue", true)
            if target then
                player:loseAllMarks("@qhstandardfenxue")
                local damagedata = sgs.QVariant()
                local damage = sgs.DamageStruct()
                damage.from = target
                damage.to = player
                damage.damage = 1
                damagedata:setValue(damage)
                local msg = sgs.LogMessage()
                msg.type = "#qhstandardfenxuemsg"
                msg.from = target
                msg.arg = self:objectName()
                msg.to:append(player)
                room:sendLog(msg)
                room:getThread():trigger(sgs.Damaged, room, player, damagedata) -- 触发额外时机
            end
        end
    end
}
-- 护驾
qhstandardhujia = sgs.CreateTriggerSkill {
    name = "qhstandardhujia$", -- 主公技，添加“$”符号
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardAsked },
    on_trigger = function(self, event, player, data, room)
        local pattern = data:toStringList()[1]
        local prompt = data:toStringList()[2]
        if pattern == "jink" then                                           -- 如果需要出闪
            if player:hasLordSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName(), data) then -- 询问发动技能
                room:broadcastSkillInvoke("hujia")                          -- 播放配音
                local playerlist = room:getOtherPlayers(player)             -- 获取其他角色名单
                local playerdata = sgs.QVariant()
                playerdata:setValue(player)
                for _, dest in sgs.qlist(playerlist) do                                                            -- 对名单中的所有角色进行扫描
                    local newprompt = ("#askForqhstandardhujia:%s"):format(player:objectName())
                    local Card = room:askForCard(dest, "jink", newprompt, playerdata, sgs.Card_MethodNone, player) -- 询问使用或打出卡牌
                    if Card then
                        room:provide(Card)                                                                         -- 提供了一张闪
                        if dest:getKingdom() == "wei" then                                                         -- 如果是魏势力
                            local msg = sgs.LogMessage()                                                           -- 创建消息
                            msg.type =
                            "#qhstandardhujiawei"                                                                  -- 消息结构类型(发送的消息是什么)
                            msg.from = dest
                            msg.to:append(player)
                            room:sendLog(msg) -- 发送消息
                            room:drawCards(player, 1, self:objectName())
                            room:drawCards(dest, 1, self:objectName())
                        else                                    -- 如果不是魏势力
                            local msg = sgs.LogMessage()        -- 创建消息
                            msg.type = "#qhstandardhujianotwei" -- 消息结构类型(发送的消息是什么)
                            msg.from = dest
                            msg.to:append(player)
                            room:sendLog(msg) -- 发送消息
                        end
                        break                 -- 终止循环
                    end
                end
            end
        end
    end
}

-- 标准版-强化 司马懿-反馈
qhstandardfankui = sgs.CreateTriggerSkill {
    name = "qhstandardfankui",
    frequency = sgs.Skill_Frequent,
    events = { sgs.Damaged },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()                                   -- 获取房间
        local damage = data:toDamage()                                  -- 获取伤害结构体
        local from = damage.from                                        -- 获取伤害来源
        local dianshu = damage.damage                                   -- 获取伤害点数
        if room:askForSkillInvoke(player, self:objectName(), data) then -- 询问发动技能
            room:broadcastSkillInvoke("fankui")                         -- 播放配音
            if not from or from:isNude() then                           -- 没牌
                room:drawCards(player, 2, self:objectName())
            else
                local id = room:askForCardChosen(player, from, "he", self:objectName())
                room:obtainCard(player, id, false) -- 获得
                room:drawCards(player, 1, self:objectName())
            end
            if dianshu > 1 then                   -- 伤害点数大于1
                if not from or from:isNude() then -- 没牌
                    room:drawCards(player, 2, self:objectName())
                else
                    local id = room:askForCardChosen(player, from, "he", self:objectName())
                    room:obtainCard(player, id, false) -- 获得
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
    end
}

-- 鬼才
qhstandardguicaiVS = sgs.CreateViewAsSkill {       -- 鬼才 视为技
    name = "qhstandardguicai",
    n = 0,                                         -- 不选择卡牌
    view_as = function(self, cards)
        local acard = qhstandardguicaiCARD:clone() -- 创建技能卡
        acard:setSkillName(self:objectName())      -- 技能名称
        return acard
    end,
    enabled_at_play = function(self, player)               -- 限制条件
        return not player:hasFlag("qhstandardguicai_used") -- 没有标志
    end
}

qhstandardguicaiCARD = sgs.CreateSkillCard {            -- 鬼才 技能卡
    name = "qhstandardguicaiCARD",
    target_fixed = false,                               -- 选择目标
    filter = function(self, targets, to_select, player) -- 使用对象的约束条件
        return #targets == 0                            -- 没有选择目标
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local start = target:getMark("Player_Start_used")
        local finish = target:getMark("Player_Finish_used")
        local phase
        if start == 0 and finish == 0 then                                                                   -- 上一次没选择过此角色
            phase = room:askForChoice(source, self:objectName(), "Guicai_Player_Start+Guicai_Player_Finish") -- 选择
        end
        if start == 1 then                                                                                   -- 上次选择准备阶段
            phase = "Guicai_Player_Finish"
        end
        if finish == 1 then -- 上次选择结束阶段
            phase = "Guicai_Player_Start"
        end
        local playerlist = room:getAllPlayers()                 -- 获取所有角色名单
        for _, dest in sgs.qlist(playerlist) do                 -- 对名单中的所有角色进行扫描
            room:setPlayerMark(dest, "Player_Start_used", 0)    -- 清除标记
            room:setPlayerMark(dest, "Player_Finish_used", 0)   -- 清除标记
        end
        if phase == "Guicai_Player_Finish" then                 -- 跳过结束阶段
            room:setPlayerMark(target, "Player_Finish", 1)      -- 获取标记,表示跳过结束阶段
            room:setPlayerMark(target, "Player_Finish_used", 1) -- 获取标记,表示已选择的阶段
        end
        if phase == "Guicai_Player_Start" then                  -- 跳过准备阶段
            room:setPlayerMark(target, "Player_Start", 1)       -- 获取标记,表示跳过准备阶段
            room:setPlayerMark(target, "Player_Start_used", 1)  -- 获取标记,表示已选择的阶段
        end
        room:broadcastSkillInvoke("guicai")                     -- 播放配音
        local msg = sgs.LogMessage()                            -- 创建消息
        msg.type = "#qhstandardguicai"                          -- 消息结构类型(发送的消息是什么)
        msg.from = source
        msg.to:append(target)
        msg.arg = self:objectName()
        msg.arg2 = phase
        room:sendLog(msg)                                   -- 发送消息
        room:setPlayerFlag(source, "qhstandardguicai_used") -- 设置标志
        room:addPlayerMark(target, "&qhstandardguicai+:+"..phase.."+to+#"..source:objectName().."-SelfClear")
    end
}

qhstandardguicai = sgs.CreateTriggerSkill { -- 鬼才 触发技
    name = "qhstandardguicai",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhstandardguicaiVS,
    events = { sgs.EventPhaseStart, sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()        -- 获取房间
        if event == sgs.EventPhaseStart then -- 阶段开始时
            if not player:hasSkill(self:objectName()) then
                return false
            end                                                    -- 若拥有此技能
            if player:getPhase() == sgs.Player_Start then          -- 若是准备阶段
                local playerlist = room:getAllPlayers()            -- 获取所有角色名单
                local SPlayerList = sgs.SPlayerList()              -- 新建 player list
                for _, dest in sgs.qlist(playerlist) do            -- 对名单中的所有角色进行扫描
                    local DelayedTrickCard = dest:getJudgingArea() -- 获取判定区卡牌
                    if DelayedTrickCard:length() > 0 then          -- 判定区有牌
                        SPlayerList:append(dest)                   -- 加入名单
                    end
                end
                if SPlayerList:length() == 0 then
                    return false
                end -- 如果判定区都没牌则结束
                if not room:askForSkillInvoke(player, self:objectName(), data) then
                    return false
                end -- 询问发动技能
                local prompt = "#qhstandardguicai_PlayerChosen1"
                local from = room:askForPlayerChosen(player, SPlayerList, "qhstandardguicai_PlayerChosen1", prompt,
                    false, true)                                   -- 询问角色
                local otherplayerlist = room:getOtherPlayers(from) -- 获取其他角色名单
                local prompt = "#qhstandardguicai_PlayerChosen2"
                local to = room:askForPlayerChosen(player, otherplayerlist, "qhstandardguicai_PlayerChosen2", prompt,
                    false, true)                                                          -- 询问角色
                room:broadcastSkillInvoke("guicai")                                       -- 播放配音
                local cards = from:getJudgingArea()                                       -- 获取判定区卡牌
                for _, card in sgs.qlist(cards) do                                        -- 对名单中的所有卡牌进行扫描
                    local reason = sgs.CardMoveReason()                                   -- 卡牌移动原因结构体
                    reason.m_reason = sgs.CardMoveReason_S_REASON_TRANSFER                -- 移动
                    reason.m_playerId = from:objectName()
                    room:moveCardTo(card, to, sgs.Player_PlaceDelayedTrick, reason, true) -- 移动到判定区
                end
            end
            if player:getPhase() == sgs.Player_Finish then                -- 若是结束阶段
                if not player:hasFlag("qhstandardguicai_used") then       -- 没有标志
                    local playerlist = room:getAllPlayers()               -- 获取所有角色名单
                    for _, dest in sgs.qlist(playerlist) do               -- 对名单中的所有角色进行扫描
                        room:setPlayerMark(dest, "Player_Start_used", 0)  -- 清除标记
                        room:setPlayerMark(dest, "Player_Finish_used", 0) -- 清除标记
                    end
                end
            end
        end
        if event == sgs.EventPhaseChanging then -- 阶段变更时
            local start = player:getMark("Player_Start")
            local finish = player:getMark("Player_Finish")
            if start == 0 and finish == 0 then
                return false
            end                                                   -- 没被选择则结束
            local change = data:toPhaseChange()                   -- 获得阶段交替结构体
            local phase = change.to                               -- 找到将要进入的回合阶段
            if start == 1 and phase == sgs.Player_Start then      -- 准备阶段
                if not player:isSkipped(sgs.Player_Start) then    -- 如果阶段存在
                    player:skip(phase, false)                     -- 跳过准备阶段
                    room:setPlayerMark(player, "Player_Start", 0) -- 清除标记
                end
            end
            if finish == 1 and phase == sgs.Player_Finish then     -- 结束阶段
                if not player:isSkipped(sgs.Player_Finish) then    -- 如果阶段存在
                    player:skip(phase, false)                      -- 跳过结束阶段
                    room:setPlayerMark(player, "Player_Finish", 0) -- 清除标记
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target -- 任何角色触发都能发动
    end
}

-- 天命
qhstandardtianming = sgs.CreateViewAsSkill { -- 天命 视为技
    name = "qhstandardtianming",
    n = 1,                                   -- 最大卡牌数
    view_filter = function(self, selected, to_select)
        if #selected == 0 and not to_select:isEquipped() then
            return true
        end -- 不是装备
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end                                          -- 一张卡牌也没选是不能发动技能的
        local acard = qhstandardtianmingCARD:clone() -- 创建技能卡
        local card = cards[1]                        -- 获得发动技能的卡牌
        local id = card:getId()                      -- 卡牌的编号
        acard:addSubcard(id)                         -- 加入技能卡
        acard:setSkillName(self:objectName())        -- 技能名称
        return acard
    end,
    enabled_at_play = function(self, player)                 -- 限制条件
        return not player:hasUsed("#qhstandardtianmingCARD") -- 没使用过技能卡
    end
}

qhstandardtianmingCARD = sgs.CreateSkillCard {                                 -- 天命 技能卡
    name = "qhstandardtianmingCARD",
    target_fixed = false,                                                      -- 选择目标
    will_throw = false,                                                        -- 不立即丢弃
    filter = function(self, targets, to_select, player)                        -- 使用对象的约束条件
        return #targets == 0 and to_select:objectName() ~= player:objectName() and to_select:hasJudgeArea() -- 不是自己
    end,
    on_use = function(self, room, source, targets)
        local judge = sgs.JudgeStruct()     -- 判定结构体
        judge.pattern = "."                 -- 判定规则
        judge.good = true                   -- 判定结果符合判断规则会更有利
        judge.reason = self:objectName()    -- 判定原因
        judge.who = source                  -- 判定对象
        room:judge(judge)                   -- 进行判定
        room:broadcastSkillInvoke("guicai") -- 播放配音
        local judgeSuit = judge.card:getSuit()
        if judgeSuit == sgs.Card_Diamond then
            room:throwCard(self, source)
            room:drawCards(source, 2, self:objectName()) -- 摸牌
        else
            local card = sgs.Sanguosha:getCard(self:getSubcards():first())
            local suit = card:getSuit()    -- 卡牌的花色
            local point = card:getNumber() -- 卡牌的点数
            local id = card:getId()        -- 卡牌的编号
            local usecard
            if judgeSuit == sgs.Card_Heart then
                usecard = sgs.Sanguosha:cloneCard("indulgence", suit, point)
            elseif judgeSuit == sgs.Card_Club then
                usecard = sgs.Sanguosha:cloneCard("supply_shortage", suit, point)
            elseif judgeSuit == sgs.Card_Spade then
                usecard = sgs.Sanguosha:cloneCard("lightning", suit, point)
            end
            usecard:addSubcard(id) -- 用被选择的卡牌填充虚构卡牌
            usecard:setSkillName("qhstandardtianming")
            room:useCard(sgs.CardUseStruct(usecard, source, targets[1]))
        end
    end
}
-- 标准版-强化 夏侯惇-刚烈
qhstandardganglie = sgs.CreateTriggerSkill {
    name = "qhstandardganglie",
    frequency = sgs.Skill_Frequent,
    events = { sgs.Damaged },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()  -- 获取房间
        local damage = data:toDamage() -- 获取伤害结构体
        local from = damage.from       -- 获取伤害来源
        local dianshu = damage.damage  -- 获取伤害点数
        if player:hasFlag("qhstandardganglie_using") then
            return false
        end                                                                           -- 若有标志则结束
        local from_data = sgs.QVariant()                                              -- 构造一个空的 QVariant 对象
        from_data:setValue(from)                                                      -- 为 QVariant 对象设置值:保存伤害来源信息
        if room:askForSkillInvoke(player, self:objectName(), from_data) then          -- 询问发动技能
            room:setPlayerFlag(player, "qhstandardganglie_using")                     -- 使用前获得标志
            room:broadcastSkillInvoke("ganglie")                                      -- 播放配音
            if from == nil or from:objectName() == player:objectName() then           -- 伤害无来源或为自己
                local playerlist = room:getOtherPlayers(player)                       -- 获取其他角色名单
                from = room:askForPlayerChosen(player, playerlist, self:objectName()) -- 询问角色
            end
            for i = 1, dianshu do
                local damage = sgs.DamageStruct()
                damage.from = player
                damage.to = from
                damage.damage = 1
                damage.nature = sgs.DamageStruct_Normal
                room:damage(damage)       -- 造成伤害
                if not from:isNude() then -- 有牌
                    local id = room:askForCardChosen(player, from, "he", self:objectName())
                    room:throwCard(id, from, player)
                end
            end
            room:setPlayerFlag(player, "-qhstandardganglie_using") -- 使用后失去标志
        end
    end
}

-- 标准版-强化 张辽-突袭
qhstandardtuxiCARD = sgs.CreateSkillCard {                  -- 突袭 技能卡
    name = "qhstandardtuxiCARD",
    target_fixed = false,                                   -- 选择目标
    filter = function(self, targets, to_select, player)     -- 使用对象的约束条件
        local Int = player:getMark("qhstandardtuxi_length") -- 获取标记
        Int = Int + 1                                       -- 加1
        if #targets >= Int then
            return false
        end                                                      -- 已选择目标数大于等于Int则结束
        if not to_select:isKongcheng() then                      -- 有手牌
            return to_select:objectName() ~= player:objectName() -- 不是自己
        end
    end,
    on_use = function(self, room, source, targets)          -- 具体使用效果
        local Int = source:getMark("qhstandardtuxi_length") -- 获取标记
        local targetsNum = #targets
        Int = Int - targetsNum + 1
        room:setPlayerMark(source, "qhstandardtuxi_length", Int) -- 获取标记
        room:broadcastSkillInvoke("tuxi")                        -- 播放配音
        local pattern = ""                                       -- 记录id
        for _, target in ipairs(targets) do                      -- 对被选择的所有角色进行扫描
            local id = room:askForCardChosen(source, target, "h", self:objectName())
            room:obtainCard(source, id, false)                   -- 获得
            pattern = pattern .. id .. ","
        end
        room:setPlayerProperty(source, "qhstandardtuxi_card", sgs.QVariant(pattern)) -- AI
        local cards = room:askForDiscard(source, self:objectName(), targetsNum, 1, true, false, "#qhstandardtuxidis",
            pattern)                                                                 -- 条件弃牌
        if cards and cards:getSubcards() then
            room:drawCards(source, cards:getSubcards():length(), self:objectName())  -- 摸牌
        end
    end
}

qhstandardtuxiVS = sgs.CreateViewAsSkill {       -- 突袭 视为技
    name = "qhstandardtuxi",
    n = 0,                                       -- 不选择卡牌
    view_as = function(self, cards)
        local acard = qhstandardtuxiCARD:clone() -- 创建技能卡
        acard:setSkillName(self:objectName())    -- 技能名称
        return acard
    end,
    enabled_at_play = function(self, player)              -- 主动使用
        return false                                      -- 不能
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        return pattern == "@qhstandardtuxi"               -- 询问使用突袭 视为技时,询问视为技的时机时前面要加@
    end
}

qhstandardtuxi = sgs.CreateTriggerSkill { -- 突袭 触发技
    name = "qhstandardtuxi",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhstandardtuxiVS,
    events = { sgs.DrawNCards },
    priority = -10,                                     -- 优先级为负,最后触发
    on_trigger = function(self, event, player, data, room)
        local draw = data:toDraw()
        if draw.reason ~= "draw_phase" then return false end
        local playerlist = room:getOtherPlayers(player) -- 获取其他角色名单
        local SPlayerList = sgs.SPlayerList()           -- 新建 player list
        for _, dest in sgs.qlist(playerlist) do         -- 对名单中的所有角色进行扫描
            if not dest:isKongcheng() then              -- 有手牌
                SPlayerList:append(dest)                -- 加入名单
            end
        end
        if SPlayerList:length() == 0 then
            return false
        end                                                      -- 如果都没手牌则结束
        room:setPlayerMark(player, "qhstandardtuxi_length", draw.num) -- 获取标记
        local prompt = string.format("#askForUseqhstandardtuxiVS:%s", draw.num + 1)
        room:askForUseCard(player, "@qhstandardtuxi", prompt, -1, sgs.Card_MethodNone)
        -- 询问使用突袭视为技
        draw.num = player:getMark("qhstandardtuxi_length") -- 获取标记
        data:setValue(draw)                            -- 设置摸牌数
    end
}

-- 标准版-强化 许褚-裸衣
qhstandardluoyi = sgs.CreateTriggerSkill {
    name = "qhstandardluoyi",
    frequency = sgs.Skill_Frequent,
    events = { sgs.DrawNCards, sgs.ConfirmDamage, sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DrawNCards then
            local draw = data:toDraw()
            if draw.reason ~= "draw_phase" then return false end
            if not room:askForSkillInvoke(player, self:objectName(), data) then
                return false
            end                                                                                       -- 询问是否发动技能
            local Choice = room:askForChoice(player, self:objectName(), "Luoyi_shao+Luoyi_duo", data) -- 选择
            if Choice == "Luoyi_shao" then                                                            -- 选择少摸
                room:setPlayerMark(player, "Luoyi_shao", 1)                                           -- 获取标记
                local msg = sgs.LogMessage()
                msg.type = "#Luoyi_shaomsg"                                                           -- 消息结构类型(发送的消息是什么)
                msg.to:append(player)                                                                 -- 行为接受对象(%to将被替换为什么)
                room:sendLog(msg)                                                                     -- 发送消息
                draw.num = draw.num - 1                                                              -- 计算摸牌数
                room:addPlayerMark(player, "&qhstandardluoyi")
            end
            if Choice == "Luoyi_duo" then                                                             -- 选择多摸
                room:setPlayerMark(player, "Luoyi_duo", 1)                                            -- 获取标记
                local msg = sgs.LogMessage()
                msg.type = "#Luoyi_duomsg"                                                            -- 消息结构类型(发送的消息是什么)
                msg.to:append(player)                                                                 -- 行为接受对象(%to将被替换为什么)
                room:sendLog(msg)                                                                     -- 发送消息
                draw.num = draw.num + 1                                                              -- 计算摸牌数
            end
            room:broadcastSkillInvoke("luoyi")                                                        -- 播放配音
            data:setValue(draw)                                                                      -- 保存摸牌数
        end
        if event == sgs.ConfirmDamage then                                                            -- 确定伤害的点数和属性时
            if player:getMark("Luoyi_shao") == 1 then                                                 -- 选择少摸
                local damage = data:toDamage()                                                        -- 获取伤害结构体
                if damage.card and (damage.card:isKindOf("BasicCard") or damage.card:isKindOf("TrickCard")) then
                    local hurt = damage.damage                                                        -- 获取伤害点数
                    damage.damage = hurt + 1                                                          -- 加伤害
                    data:setValue(damage)                                                             -- 保存伤害
                end
            end
        end
        if event == sgs.EventPhaseStart then                            -- 阶段开始时
            if player:getMark("Luoyi_duo") == 1 then                    -- 选择多摸
                if player:getPhase() == sgs.Player_Finish then          -- 若是结束阶段
                    local HandcardNum = player:getHandcardNum()         -- 手牌数
                    local MaxHp = player:getMaxHp()                     -- 体力上限
                    local MaxHpXin = MaxHp / 1.5                        -- 体力上限除以1.5
                    local MaxHpceil = math.ceil(MaxHpXin)
                    if HandcardNum < MaxHpceil then                     -- 如果手牌数<体力上限
                        local msg = sgs.LogMessage()
                        msg.type = "#Luoyi_Drawmsg"                     -- 消息结构类型(发送的消息是什么)
                        msg.from = player                               -- 行为发起对象(%from将被替换为什么)
                        msg.arg = MaxHpceil                             -- 参数1(%arg将被替换为什么)
                        room:sendLog(msg)                               -- 发送消息
                        room:drawCards(player, MaxHpceil - HandcardNum) -- 摸牌
                    end
                    room:setPlayerMark(player, "Luoyi_duo", 0)          -- 清除标记
                end
            end
            if player:getPhase() == sgs.Player_Start then 
                room:setPlayerMark(player, "Luoyi_shao", 0) -- 清除标记
                room:setPlayerMark(player, "&qhstandardluoyi", 0)
            end
        end
    end
}

-- 标准版-强化 郭嘉-天妒
qhstandardtiandu = sgs.CreateTriggerSkill {
    name = "qhstandardtiandu",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardFinished },
    priority = 1,
    on_trigger = function(self, event, player, data)
        local use = data:toCardUse()
        local card = use.card
        local source = use.from
        local targets = use.to
        if card:isKindOf("SkillCard") then
            return false
        end -- 是技能卡则结束
        if targets:length() ~= 1 then
            return false
        end -- 目标不唯一则结束
        local target = targets:at(0)
        if source:objectName() == target:objectName() then
            return false
        end                                        -- 使用者为目标则结束
        if target:hasSkill(self:objectName()) then ----若目标拥有此技能
            local room = player:getRoom()
            if room:askForSkillInvoke(target, self:objectName(), data) then
                local Invoke = false
                local prompt = ("#askForqhstandardtiandu:%s"):format(card:objectName())
                if target:getHandcardNum() < 3 then                                                  -- 手牌数
                    Invoke = true
                elseif room:askForDiscard(target, self:objectName(), 1, 1, true, false, prompt) then -- 询问弃牌 可不弃
                    Invoke = true
                end
                if Invoke then
                    room:broadcastSkillInvoke("tiandu") -- 播放配音
                    target:obtainCard(card)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target -- 任何角色触发都能发动
    end
}

-- 遗计
qhstandardyiji = sgs.CreateTriggerSkill {
    name = "qhstandardyiji",
    frequency = sgs.Skill_Frequent,
    events = { sgs.Damaged },
    priority = -2,
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()        -- 获取伤害结构体
        local dianshu = damage.damage         -- 获取伤害点数
        dianshu = math.min(3, dianshu)        -- 取小值
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke("yiji") -- 播放配音
            local cardlist = sgs.IntList()
            local n = dianshu * 3
            if room:getDrawPile():length() < n then
                room:swapPile()
            end                                        -- 牌不足则洗牌
            n = n - 1
            for i = 0, n do                            -- 从0到n
                local acard = room:getDrawPile():at(i) -- 获得牌
                cardlist:append(acard)
            end
            local MoveReason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEW, player:objectName(),
                self:objectName(), nil)
            local move = sgs.CardsMoveStruct()
            move.card_ids = cardlist
            move.to = player
            move.to_place = sgs.Player_PlaceHand
            move.reason = MoveReason
            room:moveCardsAtomic(move, false) -- 移动牌
            if not cardlist:isEmpty() then
                local ok = true
                while ok do -- 循环遗计
                    ok = room:askForYiji(player, cardlist, self:objectName(), true, false, true, -1,
                        room:getAlivePlayers())
                end
            end
            player:gainMark("@qhstandardyiji", dianshu)
            local Mark = player:getMark("@qhstandardyiji")
            if Mark >= 4 then
                local Recover = sgs.RecoverStruct() -- 定义恢复结构体
                Recover.recover = 1
                Recover.who = player
                room:recover(player, Recover, true) -- 回血
                player:loseMark("@qhstandardyiji", 4)
            end
        end
    end
}

-- 标准版-强化 甄姬-洛神
qhstandardluoshen = sgs.CreateTriggerSkill {
    name = "qhstandardluoshen",
    frequency = sgs.Skill_Frequent,
    events = { sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data)
        if player:getPhase() == sgs.Player_Start then -- 若是准备阶段
            local room = player:getRoom()
            local n = 0
            for i = 1, 10 do
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:broadcastSkillInvoke("luoshen") -- 播放配音
                    local judge = sgs.JudgeStruct()      -- 判定结构体
                    judge.pattern = ".|black"            -- 判定规则
                    judge.good = true                    -- 判定结果符合判断规则会更有利
                    judge.reason = self:objectName()     -- 判定原因
                    judge.who = player                   -- 判定对象
                    room:judge(judge)                    -- 进行判定
                    player:obtainCard(judge.card)
                    if judge:isGood() then               -- 判定成功
                        room:addPlayerMark(player, "&qhstandardluoshen-Clear", 1)
                    elseif n == 1 then
                        break -- 终止循环
                    elseif n == 0 then
                        n = n + 1
                    end
                else
                    break
                end
            end
        end
    end
}

-- 倾国
qhstandardqingguo = sgs.CreateViewAsSkill {
    name = "qhstandardqingguo",
    n = 1,                                           -- 最大卡牌数
    response_or_use = true,                          -- 可以选择木牛流马上的牌
    view_filter = function(self, selected, to_select)
        return to_select:getSuit() ~= sgs.Card_Heart -- 非红桃
    end,
    view_as = function(self, cards)
        if #cards == 0 then                                              -- 一张卡牌也没选是不能发动技能的
            return nil                                                   -- 直接返回，nil表示无效
        elseif #cards == 1 then                                          -- 选择了一张卡牌
            local card = cards[1]                                        -- 获得发动技能的卡牌
            local suit = card:getSuit()                                  -- 卡牌的花色
            local point = card:getNumber()                               -- 卡牌的点数
            local id = card:getId()                                      -- 卡牌的编号
            local vs_card = sgs.Sanguosha:cloneCard("jink", suit, point) -- 描述虚构闪卡牌的构成
            vs_card:addSubcard(id)                                       -- 用被选择的卡牌填充虚构卡牌
            vs_card:setSkillName(self:objectName())                      -- 创建虚构卡牌的技能名称
            return vs_card                                               -- 返回一张虚构的卡牌
        end
    end,
    enabled_at_play = function(self, player)              -- 主动使用
        return false                                      -- 不能主动使用
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        return pattern == "jink"                          -- 出闪时
    end
}

-- 风包-强化 夏侯渊-神速
qhwindshensuVS = sgs.CreateViewAsSkill {       -- 神速 视为技
    name = "qhwindshensu",
    n = 0,                                     -- 不选择卡牌
    view_as = function(self, cards)
        local acard = qhwindshensuCARD:clone() -- 创建技能卡
        acard:setSkillName(self:objectName())  -- 技能名称
        return acard
    end,
    enabled_at_play = function(self, player)              -- 主动使用
        return false                                      -- 不能
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        return pattern == "@qhwindshensu"                 -- 询问使用神速 视为技时
    end
}

qhwindshensuCARD = sgs.CreateSkillCard { -- 神速 技能卡
    name = "qhwindshensuCARD",
    target_fixed = false,                -- 选择目标
    filter = function(self, targets, to_select, player)
        local targets_list = sgs.PlayerList()
        for _, target in ipairs(targets) do
            targets_list:append(target)
        end
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName("qhwindshensu")
        slash:deleteLater()
        return slash:targetFilter(targets_list, to_select, player)
    end,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke("shensu") -- 播放配音
        local targets_list = sgs.SPlayerList()
        for _, target in ipairs(targets) do
            if source:canSlash(target, nil, false) then
                targets_list:append(target)
            end
        end
        if targets_list:length() > 0 then
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            slash:setSkillName("qhwindshensu")
            room:useCard(sgs.CardUseStruct(slash, source, targets_list))
        end
    end
}

qhwindshensu = sgs.CreateTriggerSkill { -- 神速 触发技
    name = "qhwindshensu",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseChanging, sgs.Damaged },
    view_as_skill = qhwindshensuVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge) and
                not player:isSkipped(sgs.Player_Draw) then
                if sgs.Slash_IsAvailable(player) and
                    room:askForUseCard(player, "@qhwindshensu", "#askForUseqhwindshensuVS1", -1, sgs.Card_MethodNone) then
                    -- 询问使用神速视为技
                    player:skip(sgs.Player_Judge)
                    player:skip(sgs.Player_Draw)
                    local AllPlayers = room:getAllPlayers()
                    local playerlist = sgs.SPlayerList()
                    for _, dest in sgs.qlist(AllPlayers) do -- 对名单中的所有角色进行扫描
                        if not dest:isAllNude() then        -- 有牌
                            playerlist:append(dest)         -- 加入名单
                        end
                    end
                    if playerlist:length() == 0 then
                        return false
                    end -- 如果都没手牌则结束
                    local play = room:askForPlayerChosen(player, playerlist, self:objectName(),
                        "#qhwindshensuPlayerChosen", true)
                    if play then
                        local Card = room:askForCardChosen(player, play, "hej", self:objectName())
                        room:throwCard(Card, play, player)
                    end
                end
            elseif change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) then
                if sgs.Slash_IsAvailable(player) and
                    room:askForUseCard(player, "@qhwindshensu", "#askForUseqhwindshensuVS2", -1, sgs.Card_MethodNone) then
                    -- 询问使用神速视为技
                    player:skip(sgs.Player_Play)
                end
            end
        elseif event == sgs.Damaged then
            if sgs.Slash_IsAvailable(player) and not player:hasFlag("qhwindshensu_using") then
                room:setPlayerFlag(player, "qhwindshensu_using")
                room:askForUseCard(player, "@qhwindshensu", "#askForUseqhwindshensuVS3", -1, sgs.Card_MethodNone)
                -- 询问使用神速视为技
                room:setPlayerFlag(player, "-qhwindshensu_using")
            end
        end
    end
}

-- 风包-强化 曹仁-据守
qhwindjushou = sgs.CreateTriggerSkill {
    name = "qhwindjushou",
    frequency = sgs.Skill_Frequent,
    events = { sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then                      -- 若是结束阶段
            if room:askForSkillInvoke(player, self:objectName(), data) then -- 询问发动技能
                room:broadcastSkillInvoke("jushou")                         -- 播放配音
                room:drawCards(player, 2, self:objectName())                -- 摸牌
                player:turnOver()
            end
        end
    end
}

-- 解围
qhwindjiewei = sgs.CreateTriggerSkill {
    name = "qhwindjiewei",
    frequency = sgs.Skill_Frequent,
    events = { sgs.TurnedOver },
    on_trigger = function(self, event, player, data, room)
        if not room:askForSkillInvoke(player, self:objectName()) then
            return false
        end
        room:broadcastSkillInvoke("jiewei")          -- 播放配音
        room:drawCards(player, 1, self:objectName()) -- 摸牌
        local card
        if player:getAI() then
            card = room:askForUseCard(player, "@qhwindjiewei-AI", "", -1, sgs.Card_MethodUse) -- AI用
        else
            local pattern = {}
            for _, c in sgs.qlist(player:getCards("h")) do
                if not player:isJilei(c) and c:isAvailable(player) then
                    table.insert(pattern, c:getEffectiveId())
                end
            end
            card = room:askForUseCard(player, table.concat(pattern, ","), "#qhwindjiewei", -1, sgs.Card_MethodUse)
        end
        if not card then
            return false
        end
        local AllPlayers = room:getAllPlayers()
        local playerlist = sgs.SPlayerList()
        for _, dest in sgs.qlist(AllPlayers) do -- 对名单中的所有角色进行扫描
            if not dest:isAllNude() then        -- 有牌
                playerlist:append(dest)         -- 加入名单
            end
        end
        if playerlist:length() == 0 then
            return false
        end -- 如果都没手牌则结束
        local play = room:askForPlayerChosen(player, playerlist, self:objectName(), "#qhwindjieweiPlayerChosen", true)
        if play then
            local Card = room:askForCardChosen(player, play, "hej", self:objectName())
            room:throwCard(Card, play, player)
        end
    end
}

--火包-强化 典韦-强袭
qhfireqiangxi = sgs.CreateViewAsSkill { -- 强袭 视为技
    name = "qhfireqiangxi",
    n = 1,                              -- 最大卡牌数
    view_filter = function(self, selected, to_select)
        if #selected == 0 and not sgs.Self:isJilei(to_select) and sgs.Self:getMark("qhfireqiangxi_card-Clear") == 0 then
            if to_select:isKindOf("EquipCard") then
                return true
            end
        end
    end,
    view_as = function(self, cards)
        if # cards == 0 and sgs.Self:getMark("qhfireqiangxi_lose-Clear") == 0 then
            return qhfireqiangxiCARD:clone()
        elseif # cards == 1 and sgs.Self:getMark("qhfireqiangxi_card-Clear") == 0 then
            local acard = qhfireqiangxiCARD:clone()
            acard:addSubcard(cards[1])
            return acard
        end
    end,
    enabled_at_play = function(self, player) -- 主动使用
        if player:getMark("qhfireqiangxi_lose-Clear") == 0 or player:getMark("qhfireqiangxi_card-Clear") == 0 then
            return true
        end
    end,
}

qhfireqiangxiCARD = sgs.CreateSkillCard { -- 强袭 技能卡
    name = "qhfireqiangxiCARD",
    target_fixed = false,                 -- 选择目标
    filter = function(self, targets, to_select, player)
        if to_select:objectName() ~= player:objectName() then
            return true
        end
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:broadcastSkillInvoke("qiangxi") -- 播放配音
        if self:getSubcards():isEmpty() then --无牌发动
            room:loseHp(effect.from, 1)
            room:setPlayerMark(effect.from, "qhfireqiangxi_lose-Clear", 1)
        else
            room:setPlayerMark(effect.from, "qhfireqiangxi_card-Clear", 1)
        end
        room:drawCards(effect.from, 1, self:objectName()) -- 摸牌
        local damage = sgs.DamageStruct()
        damage.from = effect.from
        damage.to = effect.to
        damage.damage = 1
        room:damage(damage) -- 造成伤害
    end
}

--荀彧-驱虎
qhfirequhu = sgs.CreateViewAsSkill { -- 驱虎 视为技
    name = "qhfirequhu",
    n = 1,                           -- 最大卡牌数
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if # cards == 1 then
            local acard = qhfirequhuCARD:clone()
            acard:addSubcard(cards[1])
            return acard
        end
    end,
    enabled_at_play = function(self, player)         -- 主动使用
        return not player:hasUsed("#qhfirequhuCARD") -- 没使用过技能卡
    end,
}

qhfirequhuCARD = sgs.CreateSkillCard { -- 驱虎 技能卡
    name = "qhfirequhuCARD",
    target_fixed = false,              -- 选择目标
    will_throw = false,                -- 不立即丢弃
    filter = function(self, targets, to_select, player)
        if to_select:objectName() ~= player:objectName() and not to_select:isKongcheng() and player:canPindian(to_select) then
            return true
        end
    end,
    on_effect = function(self, effect)
        local from, to = effect.from, effect.to
        local room = from:getRoom()
        room:broadcastSkillInvoke("quhu", 1) -- 播放配音
        local pindian = from:PinDian(to, "qhfirequhu", self)
        if pindian.success then
            local target = room:askForPlayerChosen(from, room:getAllPlayers(), "qhfirequhu",
                "#qhfirequhu:" .. to:objectName(), true)
            if target then
                room:broadcastSkillInvoke("quhu", 2)                    -- 播放配音
                room:damage(sgs.DamageStruct("qhfirequhu", to, target)) -- 造成伤害
            end
        else
            if not to:isAllNude() then
                local id = room:askForCardChosen(from, to, "hej", "qhfirequhu", false,
                    sgs.Card_MethodNone, sgs.IntList(), true)
                if id >= 0 then
                    room:throwCard(id, to, from)
                end
            end
            room:damage(sgs.DamageStruct("qhfirequhu", to, from)) -- 造成伤害
        end
    end
}

--节命
qhfirejieming = sgs.CreateTriggerSkill {
    name = "qhfirejieming",
    frequency = sgs.Skill_Frequent,
    events = { sgs.Damaged },
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()           -- 获取伤害结构体
        local dianshu = damage.damage            -- 获取伤害点数
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke("jieming") -- 播放配音
            for i = 1, dianshu, 1 do
                local target = room:askForPlayerChosen(player, room:getAllPlayers(), "qhfirejieming",
                    "#qhfirejieming", true)
                if not target then
                    break
                end
                room:drawCards(target, 4, self:objectName()) -- 摸牌
                if target:getHandcardNum() > 5 then
                    local num = math.min(target:getHandcardNum() - 5, 3)
                    room:askForDiscard(target, self:objectName(), num, num)
                end
            end
        end
    end
}


-- 标准版-强化 刘备-仁德
qhstandardrendeVS = sgs.CreateViewAsSkill { -- 仁德 视为技
    name = "qhstandardrende",
    n = 20,                                 -- 最大卡牌数
    view_filter = function(self, selected, to_select)
        if not to_select:isEquipped() then
            return true
        end -- 不是装备
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end                                       -- 一张卡牌也没选是不能发动技能的
        local acard = qhstandardrendeCARD:clone() -- 创建技能卡
        for _, card in ipairs(cards) do           -- 扫描卡牌名单
            local id = card:getId()               -- 卡牌的编号
            acard:addSubcard(id)                  -- 加入技能卡
        end
        acard:setSkillName(self:objectName())     -- 技能名称
        return acard
    end,
    enabled_at_play = function(self, player) -- 限制条件
        return not player:isKongcheng()      -- 有手牌
    end
}

qhstandardrendeCARD = sgs.CreateSkillCard {                                    -- 仁德 技能卡
    name = "qhstandardrendeCARD",
    target_fixed = false,                                                      -- 选择目标
    will_throw = false,                                                        -- 不立即丢弃
    handling_method = sgs.Card_MethodNone,                                     -- 执行的用途 无用途(被鸡肋的牌也可用)
    filter = function(self, targets, to_select, player)                        -- 使用对象的约束条件
        return #targets == 0 and to_select:objectName() ~= player:objectName() -- 没有选择目标且不是自己
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local MoveReason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, source:objectName(), self:objectName(),
            nil)
        local move = sgs.CardsMoveStruct()
        move.card_ids = self:getSubcards()
        move.to = target
        move.to_place = sgs.Player_PlaceHand
        move.reason = MoveReason
        room:moveCardsAtomic(move, false)         -- 移动牌
        local Cardn = self:getSubcards():length() -- 获取子卡数量
        Int = source:getMark("qhstandardrende")   -- 获取标记
        room:setPlayerMark(source, "qhstandardrende", Int + Cardn)
        Int = Int + Cardn
        room:broadcastSkillInvoke("rende") -- 播放配音
        if Int > 0 and not source:hasFlag("qhstandardrende_used1") then
            if math.random(1, 100) < 34 then
                room:drawCards(source, 1, self:objectName()) -- 摸牌
            end
            room:setPlayerFlag(source, "qhstandardrende_used1")
        end
        if Int > 1 and not source:hasFlag("qhstandardrende_used2") then
            if source:isWounded() then              -- 受伤
                local Recover = sgs.RecoverStruct() -- 定义恢复结构体
                Recover.recover = 1
                Recover.who = source
                Recover.card = self
                room:recover(source, Recover, true)          -- 回血
            else
                room:drawCards(source, 1, self:objectName()) -- 摸牌
            end
            room:setPlayerFlag(source, "qhstandardrende_used2")
        end
        if Int > 2 and not source:hasFlag("qhstandardrende_used3") then
            if math.random(1, 100) < 34 then
                room:drawCards(source, 1, self:objectName()) -- 摸牌
            end
            room:setPlayerFlag(source, "qhstandardrende_used3")
        end
        if Int > 3 and not source:hasFlag("qhstandardrende_used4") then
            room:drawCards(target, 1, self:objectName()) -- 摸牌
            room:drawCards(source, 1, self:objectName()) -- 摸牌
            room:setPlayerFlag(source, "qhstandardrende_used4")
        end
    end
}

qhstandardrende = sgs.CreateTriggerSkill { -- 仁德 触发技
    name = "qhstandardrende",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhstandardrendeVS,
    events = { sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive then
            if player:getMark("qhstandardrende") == 0 then
                room:broadcastSkillInvoke("rende") -- 播放配音
                room:drawCards(player, 2, self:objectName())
            else
                room:setPlayerMark(player, "qhstandardrende", 0) -- 清除标记(使用次数)
            end
        end
    end
}

-- 激将
qhstandardjijiangVS = sgs.CreateViewAsSkill {       -- 激将 视为技
    name = "qhstandardjijiang",
    n = 0,                                          -- 不选择卡牌
    view_as = function(self, cards)
        local acard = qhstandardjijiangCARD:clone() -- 创建技能卡
        acard:setSkillName(self:objectName())       -- 技能名称
        return acard
    end,
    enabled_at_play = function(self, player)                                                           -- 限制条件
        return not player:hasFlag("qhstandardjijiang_used") and player:hasLordSkill(self:objectName()) -- 没有标志 拥有此主公技
    end
}

qhstandardjijiangCARD = sgs.CreateSkillCard {           -- 激将 技能卡
    name = "qhstandardjijiangCARD",
    target_fixed = true,                                -- 不选择目标
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke("jijiang")            -- 播放配音
        local playerlist = room:getOtherPlayers(source) -- 获取其他角色名单
        for _, dest in sgs.qlist(playerlist) do         -- 对名单中的所有角色进行扫描
            local playerdata = sgs.QVariant()
            playerdata:setValue(source)
            local newprompt = ("#askForqhstandardjijiang:%s"):format(source:objectName())
            local Card = room:askForCard(dest, "slash", newprompt, playerdata, sgs.Card_MethodNone, source) -- 询问使用或打出卡牌
            if Card then                                                                                    -- 选择了卡牌
                local reason = sgs.CardMoveReason()                                                         -- 卡牌移动原因结构体
                reason.m_reason = sgs.CardMoveReason_S_REASON_TRANSFER                                      -- 移动
                reason.m_playerId = dest:objectName()
                room:moveCardTo(Card, source, sgs.Player_PlaceHand, reason, false)                          -- 移动到手牌
                if dest:getKingdom() == "shu" then                                                          -- 如果是蜀势力
                    local msg = sgs.LogMessage()                                                            -- 创建消息
                    msg.type =
                    "#qhstandardjijiangshu"                                                                 -- 消息结构类型(发送的消息是什么)
                    msg.from = dest
                    msg.to:append(source)
                    room:sendLog(msg) -- 发送消息
                    room:drawCards(source, 1, self:objectName())
                    room:drawCards(dest, 1, self:objectName())
                else                                      -- 如果不是蜀势力
                    local msg = sgs.LogMessage()          -- 创建消息
                    msg.type = "#qhstandardjijiangnotshu" -- 消息结构类型(发送的消息是什么)
                    msg.from = dest
                    msg.to:append(source)
                    room:sendLog(msg) -- 发送消息
                end
                break
            end
        end
        room:setPlayerFlag(source, "qhstandardjijiang_used") -- 设置标志
    end
}

qhstandardjijiang = sgs.CreateTriggerSkill {
    name = "qhstandardjijiang$", -- 主公技，添加“$”符号
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhstandardjijiangVS,
    events = { sgs.CardAsked },
    on_trigger = function(self, event, player, data)
        local pattern = data:toStringList()[1]
        local prompt = data:toStringList()[2]
        if pattern == "slash" then                                          -- 如果需要出杀
            local room = player:getRoom()                                   -- 获取房间
            if player:hasLordSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName(), data) then -- 询问发动技能
                room:broadcastSkillInvoke("jijiang")                        -- 播放配音
                local playerlist = room:getOtherPlayers(player)             -- 获取其他角色名单
                local playerdata = sgs.QVariant()
                playerdata:setValue(player)
                for _, dest in sgs.qlist(playerlist) do                                                             -- 对名单中的所有角色进行扫描
                    local newprompt = ("#askForqhstandardjijiang:%s"):format(player:objectName())
                    local Card = room:askForCard(dest, "slash", newprompt, playerdata, sgs.Card_MethodNone, player) -- 询问使用或打出卡牌
                    if Card then
                        room:provide(Card)                                                                          -- 提供了一张杀
                        if dest:getKingdom() == "shu" then                                                          -- 如果是蜀势力
                            local msg = sgs.LogMessage()                                                            -- 创建消息
                            msg.type =
                            "#qhstandardjijiangshu"                                                                 -- 消息结构类型(发送的消息是什么)
                            msg.from = dest
                            msg.to:append(player)
                            room:sendLog(msg) -- 发送消息
                            room:drawCards(player, 1, self:objectName())
                            room:drawCards(dest, 1, self:objectName())
                        else
                            local msg = sgs.LogMessage()          -- 创建消息
                            msg.type = "#qhstandardjijiangfeishu" -- 消息结构类型(发送的消息是什么)
                            msg.from = dest
                            msg.to:append(player)
                            room:sendLog(msg) -- 发送消息
                        end
                        break
                    end
                end
            end
        end
    end
}

-- 标准版-强化 关羽-武圣
qhstandardwushengVS = sgs.CreateViewAsSkill {                                                     -- 武圣 视为技
    name = "qhstandardwusheng",
    n = 1,                                                                                        -- 最大卡牌数
    response_or_use = true,                                                                       -- 可以选择木牛流马上的牌
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then -- 出牌阶段
            if sgs.Self:getMark("qhstandardwusheng-Clear") == 0 then
                return true
            end
            if sgs.Slash_IsAvailable(sgs.Self) then
                return to_select:isRed()
            else
                return false
            end
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then --响应
            if sgs.Self:getMark("qhstandardwusheng-Clear") == 0 then
                return true
            end
            return to_select:isRed()
        end
    end,
    view_as = function(self, cards)
        if #cards == 0 then                                                                                -- 一张卡牌也没选是不能发动技能的
            return nil                                                                                     -- 直接返回，nil表示无效
        end
        local card = cards[1]                                                                              -- 获得发动技能的卡牌
        local suit = card:getSuit()                                                                        -- 卡牌的花色
        local point = card:getNumber()                                                                     -- 卡牌的点数
        local id = card:getId()                                                                            -- 卡牌的编号
        local vs_card
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then          -- 出牌阶段
            if card:isRed() then
                vs_card = sgs.Sanguosha:cloneCard("slash", suit, point)                                    -- 杀
            elseif suit == sgs.Card_Club then
                vs_card = sgs.Sanguosha:cloneCard("analeptic", suit, point)                                -- 酒
            elseif suit == sgs.Card_Spade then
                vs_card = sgs.Sanguosha:cloneCard("peach", suit, point)                                    -- 桃
            end                                                                                            -- 返回一张虚构的卡牌
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then --响应
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == "slash" then
                vs_card = sgs.Sanguosha:cloneCard("slash", suit, point) -- 杀
            end
            if pattern == "jink" then
                vs_card = sgs.Sanguosha:cloneCard("jink", suit, point) -- 闪
            end
            if string.find(pattern, "peach") then
                vs_card = sgs.Sanguosha:cloneCard("peach", suit, point) -- 桃
            end
        end
        vs_card:addSubcard(id)                  -- 用被选择的卡牌填充虚构卡牌
        vs_card:setSkillName(self:objectName()) -- 创建虚构卡牌的技能名称
        return vs_card
    end,
    enabled_at_play = function(self, player) -- 主动使用
        if player:getMark("qhstandardwusheng-Clear") == 0 then
            return true
        end
        local flag = false
        if sgs.Slash_IsAvailable(player) then -- 判断是否可以继续出杀
            flag = true
        end
        return flag
    end,
    enabled_at_response = function(self, player, pattern)                                                                           -- 什么时候响应,若没有此值则不能响应
        if (pattern == "peach" or pattern == "peach+analeptic") and player:getMark("Global_PreventPeach") > 0 then return false end --禁止用桃
        if pattern == "slash" or pattern == "jink" or string.find(pattern, "peach") then
            return player:getMark("qhstandardwusheng-Clear") == 0
        end
        return pattern == "slash"
    end
}

qhstandardwusheng = sgs.CreateTriggerSkill { -- 武圣 触发技
    name = "qhstandardwusheng",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhstandardwushengVS,
    events = { sgs.CardUsed, sgs.CardResponded },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed or event == sgs.CardResponded then
            if not player:hasSkill(self:objectName()) then return false end
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card:getSkillName() == self:objectName() then
                room:broadcastSkillInvoke("wusheng") -- 播放配音
                if not card:isKindOf("Slash") or not card:isRed() then
                    local msg = sgs.LogMessage()     -- 创建消息
                    msg.type = "#qhstandardwusheng"  -- 消息结构类型(发送的消息是什么)
                    msg.from = player                -- 行为发起对象(%from将被替换为什么)
                    room:sendLog(msg)                -- 发送消息
                    room:setPlayerMark(player, "qhstandardwusheng-Clear", 1)
                    room:setPlayerMark(player, "&qhstandardwusheng-Clear", 1)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target -- 任何角色触发都能发动
    end
}

-- 偃月
qhstandardyanyue = sgs.CreateTriggerSkill { -- 偃月 触发技
    name = "qhstandardyanyue",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.CardUsed, sgs.CardResponded },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed or event == sgs.CardResponded then
            if player:getPhase() == sgs.Player_NotActive then return false end
            if player:getMark("qhstandardyanyue_used-Clear") > 0 then return false end
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card:isKindOf("Slash") then
                room:setPlayerMark(player, "qhstandardyanyue_used-Clear", 1)
                room:broadcastSkillInvoke("zhongyi") -- 播放配音
                local judge = sgs.JudgeStruct()      -- 判定结构体
                judge.who = player                   -- 判定对象
                judge.pattern = ".|red"              -- 判定规则
                judge.good = true                    -- 判定结果符合判断规则会更有利
                judge.reason = self:objectName()     -- 判定原因
                room:judge(judge)                    -- 进行判定
                local color = "black"
                if judge:isGood() then               -- 判定成功
                    color = "red"
                end
                local msg = sgs.LogMessage()   -- 创建消息
                msg.type = "#qhstandardyanyue" -- 消息结构类型(发送的消息是什么)
                msg.from = player              -- 行为发起对象(%from将被替换为什么)
                msg.arg = color
                msg.card_str = judge.card:toString()
                room:sendLog(msg) -- 发送消息
                player:obtainCard(judge.card)
                for _, play in sgs.qlist(room:getOtherPlayers(player)) do
                    room:setPlayerMark(play, "qhstandardyanyue_" .. color .. "-Clear", 1)
                end
                room:setPlayerMark(player, "&qhstandardyanyue+#record+"..judge.card:getSuitString().."_char-Clear", 1)
            end
        end
    end
}

qhstandardyanyueCardLimit = sgs.CreateCardLimitSkill { --偃月 卡牌限制技
    name = "qhstandardyanyueCardLimit",
    limit_list = function(self, player)
        if player:getMark("qhstandardyanyue_red-Clear") > 0 or player:getMark("qhstandardyanyue_black-Clear") > 0 then
            return "use,response"
        end
    end,
    limit_pattern = function(self, player)
        if player:getMark("qhstandardyanyue_red-Clear") > 0 then
            return ".|red"
        end
        if player:getMark("qhstandardyanyue_black-Clear") > 0 then
            return ".|black"
        end
    end
}

-- 青龙
qhstandardqinglong = sgs.CreateTriggerSkill {
    name = "qhstandardqinglong",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.CardsMoveOneTime, sgs.ConfirmDamage },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() then
                return false
            end                                          -- 如果从你的区域移来则结束
            local players = room:getOtherPlayers(player) -- 获取其他角色名单
            for _, play in sgs.qlist(players) do
                if play:hasSkill(self:objectName()) then ----若拥有此技能
                    return false                         -- 结束
                end
            end
            if move.card_ids:isEmpty() then
                return false
            end                                              -- 如果是空的则结束
            if move.to_place == sgs.Player_DiscardPile then  -- 如果将移动到弃牌堆
                for _, cardid in sgs.qlist(move.card_ids) do -- 扫描卡牌名单
                    if cardid == -1 then
                        return false
                    end                                        -- 如果卡牌是虚卡则结束
                    local card = sgs.Sanguosha:getCard(cardid) -- 获取卡牌信息
                    if card:isKindOf("Blade") then             -- 如果是青龙偃月刀
                        room:broadcastSkillInvoke("yijue")     -- 播放配音
                        room:obtainCard(player, card)          -- 获得
                    end
                end
            end
        end
        if event == sgs.ConfirmDamage then
            local damage = data:toDamage()                   -- 获取伤害结构体
            local card = damage.card                         -- 获取造成伤害的牌
            local from = damage.from                         -- 获取伤害来源
            local to = damage.to                             -- 获取受伤者
            if card then                                     -- 如果是牌造成的伤害
                if card:isKindOf("Slash") then               -- 如果是杀
                    if from:hasSkill(self:objectName()) then -- 若伤害来源拥有此技能
                        room:sendCompulsoryTriggerLog(player, self:objectName())
                        local useqinglong = false
                        if from:hasWeapon("Blade") then -- 如果装备了青龙偃月刀
                            useqinglong = true
                        else
                            local judge = sgs.JudgeStruct()  -- 判定结构体
                            judge.who = player               -- 判定对象
                            judge.pattern = ".|red"          -- 判定规则
                            judge.good = true                -- 判定结果符合判断规则会更有利
                            judge.reason = self:objectName() -- 判定原因
                            room:judge(judge)                -- 进行判定
                            if judge:isGood() then           -- 判定成功
                                useqinglong = true
                            end
                        end
                        if useqinglong then
                            local msg = sgs.LogMessage()     -- 创建消息
                            msg.type = "#qhstandardqinglong" -- 消息结构类型(发送的消息是什么)
                            msg.from = from                  -- 行为发起对象(%from将被替换为什么)
                            msg.to:append(to)                -- 行为接受对象(%to将被替换为什么)
                            msg.arg = damage.damage
                            msg.arg2 = damage.damage + 1
                            room:sendLog(msg)                  -- 发送消息
                            room:broadcastSkillInvoke("yijue") -- 播放配音
                            damage.damage = damage.damage + 1  -- 加伤害
                            data:setValue(damage)              -- 保存伤害
                        end
                    end
                end
            end
        end
    end
}

-- 止杀
qhstandardzhisha = sgs.CreateTriggerSkill {
    name = "qhstandardzhisha",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.PreCardUsed, sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PreCardUsed then
            if player:getPhase() == sgs.Player_Play then -- 出牌阶段
                local card = data:toCardUse().card
                if card:isKindOf("Slash") then
                    player:setFlags("qhstandardzhisha")
                end
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then
                if not player:hasFlag("qhstandardzhisha") then
                    room:sendCompulsoryTriggerLog(player, self:objectName()) -- 发送log
                    player:drawCards(1, self:objectName())
                end
            end
        end
    end
}

-- 标准版-强化 张飞-咆哮
qhstandardpaoxiao = sgs.CreateTargetModSkill {
    name = "qhstandardpaoxiao",
    pattern = "Slash",
    -- 可以额外使用2张杀
    residue_func = function(self, player)
        if player:hasSkill(self:objectName()) then
            return 2
        end
    end,
    -- 范围+2
    distance_limit_func = function(self, player)
        if player:hasSkill(self:objectName()) then
            return 2
        end
    end
}

-- 丈八
qhstandardzhangbaVS = sgs.CreateViewAsSkill { -- 丈八 视为技
    name = "qhstandardzhangba",
    n = 1,                                    -- 最大卡牌数
    view_filter = function(self, selected, to_select)
        return true
    end,
    view_as = function(self, cards)
        if #cards == 0 then                                               -- 一张卡牌也没选是不能发动技能的
            return nil                                                    -- 直接返回，nil表示无效
        elseif #cards == 1 then                                           -- 选择了一张卡牌
            local card = cards[1]                                         -- 获得发动技能的卡牌
            local suit = card:getSuit()                                   -- 卡牌的花色
            local point = card:getNumber()                                -- 卡牌的点数
            local id = card:getId()                                       -- 卡牌的编号
            local vs_card = sgs.Sanguosha:cloneCard("slash", suit, point) -- 描述虚构杀卡牌的构成
            vs_card:addSubcard(id)                                        -- 用被选择的卡牌填充虚构卡牌
            vs_card:setSkillName(self:objectName())                       -- 创建虚构卡牌的技能名称
            return vs_card                                                -- 返回一张虚构的卡牌
        end
    end,
    enabled_at_play = function(self, player) -- 限制条件
        return player:getMark("qhstandardzhangbaUsed-Clear") == 0 and sgs.Slash_IsAvailable(player)
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        if pattern == "slash" and player:getMark("qhstandardzhangbaUsed-Clear") == 0 then
            return true                                   -- 可被动使用
        end
    end
}

qhstandardzhangba = sgs.CreateTriggerSkill { -- 丈八 触发技
    name = "qhstandardzhangba",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardUsed, sgs.CardResponded, sgs.SlashMissed, sgs.ConfirmDamage, sgs.CardOffset},
    view_as_skill = qhstandardzhangbaVS,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed or event == sgs.CardResponded then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card:isKindOf("Slash") and card:getSkillName() == "qhstandardzhangba" then
                room:broadcastSkillInvoke("paoxiao") -- 播放配音
                room:addPlayerMark(player, "qhstandardzhangbaUsed-Clear", 1)
            end
        elseif event == sgs.SlashMissed then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke("paoxiao")         -- 播放配音
            room:drawCards(player, 1, self:objectName()) -- 摸牌
            room:setPlayerMark(player, "qhstandardzhangbaMiss-Clear", 1)
        elseif event == sgs.CardOffset then              --冬至版
            local effect = data:toCardEffect()
            if effect.card:isKindOf("Slash") then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke("paoxiao")         -- 播放配音
                room:drawCards(player, 1, self:objectName()) -- 摸牌
                room:setPlayerMark(player, "qhstandardzhangbaMiss-Clear", 1)
                room:setPlayerMark(player, "&qhstandardzhangba-Clear", 1)
            end
        elseif event == sgs.ConfirmDamage then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") then
                if player:getMark("qhstandardzhangbaMiss-Clear") == 1 then
                    room:broadcastSkillInvoke("paoxiao") -- 播放配音
                    local msg = sgs.LogMessage()
                    msg.type = "#qhstandardzhangba"
                    msg.from = player
                    msg.to:append(damage.to)
                    msg.arg = damage.damage
                    msg.arg2 = damage.damage + 1
                    room:sendLog(msg, player)
                    room:setPlayerMark(player, "qhstandardzhangbaMiss-Clear", 0)
                    room:setPlayerMark(player, "&qhstandardzhangba-Clear", 0)
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
        end
    end
}

-- 标准版-强化 诸葛亮-观星
qhstandardguanxingVS = sgs.CreateViewAsSkill {       -- 观星 视为技
    name = "qhstandardguanxing",
    n = 0,                                           -- 不选择卡牌
    view_as = function(self, cards)
        local fcard = qhstandardguanxingCARD:clone() -- 创建技能卡
        fcard:setSkillName(self:objectName())        -- 技能名称
        return fcard
    end,
    enabled_at_play = function(self, player)                 -- 限制条件
        return not player:hasUsed("#qhstandardguanxingCARD") -- 没使用过技能卡
    end
}

qhstandardguanxingCARD = sgs.CreateSkillCard {                   -- 观星 技能卡
    name = "qhstandardguanxingCARD",
    target_fixed = false,                                        -- 选择目标
    filter = function(self, targets, to_select, player)          -- 使用对象的约束条件
        return #targets == 0 and to_select:objectName() ~= player:objectName() and
            to_select:getMark("@qhstandardguanxing_target") == 0 -- 没有选择目标且目标不是自己且目标无标记
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        target:gainMark("@qhstandardguanxing_target", 1)                                -- 获得标记
        local name = target:objectName()
        room:setPlayerProperty(source, "qhstandardguanxing_target", sgs.QVariant(name)) -- 记录目标
        room:broadcastSkillInvoke("guanxing", 2)                                        -- 播放配音
        room:addPlayerMark(target, "&qhstandardguanxing+to+#"..source:objectName().."-SelfClear") 
    end
}

qhstandardguanxing = sgs.CreateTriggerSkill { -- 观星 触发技
    name = "qhstandardguanxing",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseStart },
    view_as_skill = qhstandardguanxingVS,
    on_trigger = function(self, event, player, data)
        if player:getPhase() == sgs.Player_Start then                 -- 若是准备阶段
            if player:getMark("@qhstandardguanxing_target") == 1 then -- 有标记
                local room = player:getRoom()
                local players = room:getOtherPlayers(player)
                for _, source in sgs.qlist(players) do
                    if source:hasSkill(self:objectName()) then                                          ----若拥有此技能
                        local name = player:objectName()
                        if source:property("qhstandardguanxing_target"):toString() == name then         -- 为目标
                            room:broadcastSkillInvoke("guanxing", 1)                                    -- 播放配音
                            room:broadcastInvoke("animate",
                                "indicate:" .. source:objectName() .. ":" .. player:objectName())       -- 指示线动画
                            room:getThread():delay(700)                                                 -- 等待
                            local cards = room:getNCards(7, false)                                      -- 获取摸牌堆顶 7 张牌，不更新摸牌堆
                            room:askForGuanxing(source, cards)                                          -- 观星
                            player:loseMark("@qhstandardguanxing_target", 1)                            -- 清除标记
                            room:setPlayerProperty(source, "qhstandardguanxing_target", sgs.QVariant()) -- 清楚目标
                        end
                    end
                end
            end
            if player:hasSkill(self:objectName()) then                          ----若拥有此技能
                local room = player:getRoom()
                if room:askForSkillInvoke(player, self:objectName(), data) then -- 询问是否发动技能
                    room:broadcastSkillInvoke("guanxing", 1)                    -- 播放配音
                    local cards = room:getNCards(7, false)                      -- 获取摸牌堆顶 7 张牌，不更新摸牌堆
                    room:askForGuanxing(player, cards)                          -- 观星
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target -- 任何角色触发都能发动
    end
}

-- 空城
qhstandardkongcheng = sgs.CreateTriggerSkill {
    name = "qhstandardkongcheng",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.TargetConfirming, sgs.CardAsked },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirming then -- 成为目标时
            if player:getHandcardNum() >= 2 then
                return false
            end -- 手牌数>=2则结束
            local use = data:toCardUse()
            local card = use.card
            if card and (card:isKindOf("Slash") or card:isKindOf("Duel")) then -- 牌为杀或决斗
                room:sendCompulsoryTriggerLog(player, self:objectName())
                local maxhp = player:getMaxHp()                                -- 获取体力上限
                room:broadcastSkillInvoke("kongcheng")                         -- 播放配音
                room:drawCards(player, maxhp-player:getHandcardNum())                                  -- 摸牌
                if card:isKindOf("Slash") then
                    room:setPlayerMark(player, "qhstandardkongcheng_jink", 1)  -- 标记
                end
                if card:isKindOf("Duel") then
                    room:setPlayerMark(player, "qhstandardkongcheng_slash", 1) -- 标记
                end
            end
        end
        if event == sgs.CardAsked then -- 被要求使用卡牌时
            local pattern = data:toStringList()[1]
            local prompt = data:toStringList()[2]
            local room = player:getRoom()
            if pattern == "jink" then                                                 -- 出闪
                if player:getMark("qhstandardkongcheng_jink") == 1 then               -- 有标记
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:setPlayerMark(player, "qhstandardkongcheng_jink", 0)         -- 清除标记
                    room:broadcastSkillInvoke("kongcheng")                            -- 播放配音
                    local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, -1) -- 无花色点数的闪
                    jink:setSkillName(self:objectName())                              -- 技能名称
                    room:provide(jink)                                                -- 提供了一张闪
                end
            end
            if pattern == "slash" then                                                  -- 出杀
                if player:getMark("qhstandardkongcheng_slash") == 1 then                -- 有标记
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:setPlayerMark(player, "qhstandardkongcheng_slash", 0)          -- 清除标记
                    room:broadcastSkillInvoke("kongcheng")                              -- 播放配音
                    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1) -- 无花色点数的杀
                    slash:setSkillName(self:objectName())                               -- 技能名称
                    room:provide(slash)                                                 -- 提供了一张杀
                end
            end
        end
    end
}

-- 标准版-强化 赵云-龙胆
qhstandardlongdan = sgs.CreateViewAsSkill {
    name = "qhstandardlongdan",
    n = 1,                                                                                        -- 最大卡牌数
    response_or_use = true,                                                                       -- 可以选择木牛流马上的牌
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then -- 出牌阶段
            if sgs.Self:isWounded() and to_select:isKindOf("Analeptic") then
                return true
            end
            if sgs.Slash_IsAvailable(sgs.Self) and to_select:isKindOf("Jink") then
                return true
            end
            local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, -1)
            newanal:deleteLater()
            if not (sgs.Self:isCardLimited(newanal, sgs.Card_MethodUse) or sgs.Self:isProhibited(sgs.Self, newanal)) and
                sgs.Self:usedTimes("Analeptic") <=
                sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, sgs.Self, newanal) and
                to_select:isKindOf("Peach") then
                return true
            end
        elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)          -- 响应
            or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then -- 使用
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == "slash" then
                return to_select:isKindOf("Jink")
            elseif pattern == "jink" then
                return to_select:isKindOf("Slash")
            elseif string.find(pattern, "analeptic") then
                return to_select:isKindOf("Peach")
            elseif string.find(pattern, "peach") then
                return to_select:isKindOf("Analeptic")
            end
        end
        return false
    end,
    view_as = function(self, cards)
        if #cards == 0 then                -- 一张卡牌也没选是不能发动技能的
            return nil                     -- 直接返回，nil表示无效
        elseif #cards == 1 then            -- 选择了一张卡牌
            local card = cards[1]          -- 获得发动技能的卡牌
            local suit = card:getSuit()    -- 卡牌的花色
            local point = card:getNumber() -- 卡牌的点数
            local id = card:getId()        -- 卡牌的编号
            local acard
            if card:isKindOf("Slash") then
                acard = sgs.Sanguosha:cloneCard("jink", suit, point)
            elseif card:isKindOf("Jink") then
                acard = sgs.Sanguosha:cloneCard("slash", suit, point)
            elseif card:isKindOf("Analeptic") then
                acard = sgs.Sanguosha:cloneCard("peach", suit, point)
            elseif card:isKindOf("Peach") then
                acard = sgs.Sanguosha:cloneCard("analeptic", suit, point)
            end
            acard:addSubcard(id)
            acard:setSkillName(self:objectName())
            return acard
        end
    end,
    enabled_at_play = function(self, player) -- 主动使用
        local qhstandardlongdan_slash = false
        local qhstandardlongdan_analeptic = false
        local qhstandardlongdan_peach = false
        if sgs.Slash_IsAvailable(player) then -- 可出杀
            qhstandardlongdan_slash = true
        end
        local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, -1)
        newanal:deleteLater()
        if not (player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal)) and -- 不能成为酒的目标
            player:usedTimes("Analeptic") <=
            sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, newanal) then                  -- 使用次数小于次数
            qhstandardlongdan_analeptic = true
        end
        if player:isWounded() then -- 受伤
            qhstandardlongdan_peach = true
        end
        if qhstandardlongdan_slash or qhstandardlongdan_analeptic or qhstandardlongdan_peach then
            return true -- 可主动使用
        end
        return false
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        if (pattern == "slash") or (pattern == "jink") or (string.find(pattern, "analeptic")) or
            (string.find(pattern, "peach")) then
            return true -- 可被动使用
        end
        return false
    end
}

-- 龙勇
qhstandardlongyong = sgs.CreateTriggerSkill {
    name = "qhstandardlongyong",
    frequency = sgs.Skill_Frequent,
    events = { sgs.EventPhaseStart, sgs.CardUsed, sgs.CardResponded },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed or event == sgs.CardResponded then
            if not player:hasSkill(self:objectName()) then
                return false
            end
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card and card:isKindOf("BasicCard") then                      -- 基本牌
                local number = player:getMark("qhstandardlongyong")
                room:setPlayerMark(player, "qhstandardlongyong", number + 1) -- 加标记
                room:setPlayerMark(player, "&qhstandardlongyong-Clear", player:getMark("qhstandardlongyong"))
                room:broadcastSkillInvoke("longdan")                         -- 播放配音
            end
        end
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then -- 结束阶段
                for _, play in sgs.qlist(room:getAllPlayers()) do
                    if play:hasSkill(self:objectName()) then
                        local number = play:getMark("qhstandardlongyong")
                        room:setPlayerMark(play, "qhstandardlongyong", 0) -- 清除标记
                        if number > 0 then
                            if not room:askForSkillInvoke(play, self:objectName(), data) then
                                return false
                            end                                  -- 询问是否发动技能
                            number = math.min(number, 3)         -- 最小值
                            room:broadcastSkillInvoke("longdan") -- 播放配音
                            room:drawCards(play, number)         -- 摸牌
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target -- 任何角色触发都能发动
    end
}

-- 标准版-强化 马超-铁骑
qhstandardtieqi = sgs.CreateTriggerSkill {
    name = "qhstandardtieqi",
    frequency = sgs.Skill_Frequent,
    events = { sgs.TargetConfirmed, sgs.TargetConfirming },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirmed then                -- 成为目标时
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") and use.from and use.from:objectName() == player:objectName() then
                local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
                local index = 1
                local targets = use.to
                room:setPlayerFlag(player, "use_from")
                for _, target in sgs.qlist(targets) do
                    local dest = sgs.QVariant()
                    dest:setValue(target)
                    
                    if room:askForSkillInvoke(player, self:objectName(), dest) then
                        room:broadcastSkillInvoke("tieji") -- 播放配音
                        local judge = sgs.JudgeStruct()    -- 判定结构体
                        judge.who = player                 -- 判定对象
                        judge.pattern = ".|red"          -- 判定规则
                        judge.good = true                  -- 判定结果符合判断规则会更有利
                        judge.reason = self:objectName()   -- 判定原因
                        room:judge(judge)                  -- 进行判定
                        if judge:isGood() then             -- 判定成功
                            local msg = sgs.LogMessage()
                            msg.type = "#qhstandardqiangming"
                            msg.from = use.from
                            msg.to:append(target)
                            msg.arg = self:objectName()
                            msg.card_str = use.card:toString()
                            room:sendLog(msg)             -- 发送消息
                            jink_table[index] = 0
                        elseif judge.card:isBlack() then
                            local num = player:getMark("qhstandardtieqi_lun")
                            if num < 3 then
                                room:setPlayerMark(player, "qhstandardtieqi_lun", num + 1) -- 加标记
                                room:drawCards(player, 1, self:objectName())           -- 摸牌
                                room:addPlayerMark(player, "&qhstandardtieqi_lun")
                            end
                        end
                    end
                    index = index + 1
                end
                room:setPlayerFlag(player, "-use_from")
                local jink_data = sgs.QVariant()
                jink_data:setValue(Table2IntList(jink_table))
                player:setTag("Jink_" .. use.card:toString(), jink_data)
            end
        elseif event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") then
                if use.to and use.to:contains(player) then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        room:broadcastSkillInvoke("tieji") -- 播放配音
                        local judge = sgs.JudgeStruct()    -- 判定结构体
                        judge.who = player                 -- 判定对象
                        judge.pattern = ".|heart"          -- 判定规则
                        judge.good = true                  -- 判定结果符合判断规则会更有利
                        judge.reason = self:objectName()   -- 判定原因
                        room:judge(judge)                  -- 进行判定
                        if judge:isGood() then             -- 判定成功
                            local list = use.nullified_list
							table.insert(list,player:objectName())
							use.nullified_list = list
							data:setValue(use)
                            local msg = sgs.LogMessage()
                            msg.type = "#qhstandardtieqi"
                            msg.from = use.from
                            msg.to:append(player)
                            msg.arg = self:objectName()
                            msg.card_str = use.card:toString()
                            room:sendLog(msg)             -- 发送消息
                        elseif judge.card:isBlack() then
                            player:drawCards(1)
                        end
                    end
                end
            end
        end
    end
}

-- 马术
qhstandardmashu = sgs.CreateDistanceSkill { -- 距离修改技
    name = "qhstandardmashu",
    correct_func = function(self, from, to)
        local others = from:getSiblings()        -- 其他角色
        local playernumber = others:length() + 1 -- 数量
        local number = -1
        if playernumber > 5 then
            number = number - 1
        end
        if from:hasSkill("qhstandardmashu") then
            return number
        end
    end
}

-- 标准版-强化 黄月英-集智
qhstandardjizhi = sgs.CreateTriggerSkill {
    name = "qhstandardjizhi",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardUsed, sgs.CardFinished },
    on_trigger = function(self, event, player, data)
        if event == sgs.CardUsed then
            local room = player:getRoom()
            local use = data:toCardUse()
            if player:hasFlag("qhstandardjizhi_using") then
                return false
            end                                    -- 不发动
            if use.card:isNDTrick() and room:askForSkillInvoke(player, self:objectName()) then
                room:broadcastSkillInvoke("jizhi") -- 播放配音
                room:drawCards(player, 1, self:objectName())
            end
        end
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if not use.to:isEmpty() and use.to:at(0):isDead() then
                return false
            end -- 不能对已死亡的角色使用
            if use.card:isKindOf("GodNihilo") then
                return false
            end -- 不能使用撒豆成兵
            if use.card:isKindOf("Nullification") then
                return false
            end -- 不能使用无懈可击
            if use.card:isKindOf("Collateral") then
                return false
            end -- 不能使用借刀杀人
            if use.card:isKindOf("IronChain") then
                return false
            end -- 不能使用铁索连环
            if use.card:isKindOf("GodFlower") and use.to and use.to:at(0):isNude() then
                return false
            end -- 不能对没牌的角色使用移花接木
            if (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement")) and use.to and
                use.to:at(0):getCards("hej"):isEmpty() then
                return false
            end                                                                         -- 不能对没牌的角色使用顺手牵羊和过河拆桥
            if use.card:isNDTrick() and not player:hasFlag("qhstandardjizhi_used") then -- 如果是非延时类锦囊且没有标志
                if player:getPhase() == sgs.Player_Play then                            -- 出牌阶段
                    local room = player:getRoom()
                    room:setPlayerFlag(player, "qhstandardjizhi_used")                  -- 获得标志
                    if not room:askForSkillInvoke(player, "qhstandardjizhi2", data) then
                        return false
                    end                                                 -- 询问是否发动技能
                    room:setPlayerFlag(player, "qhstandardjizhi_using") -- 获得标志
                    local newuse = sgs.CardUseStruct()                  -- 卡牌使用结构体
                    newuse.from = use.from                              -- 原使用者
                    for _, dest in sgs.qlist(use.to) do                 -- 对名单中的所有角色进行扫描
                        if dest:isAlive() then                          -- 如果存活
                            newuse.to:append(dest)                      -- 加入名单
                        end
                    end
                    newuse.card = use.card                               -- 原卡牌
                    room:broadcastSkillInvoke("jizhi")                   -- 播放配音
                    room:useCard(newuse)                                 -- 使用卡
                    room:setPlayerFlag(player, "-qhstandardjizhi_using") -- 失去标志
                end
            end
        end
    end
}

-- 奇才
qhstandardqicai = sgs.CreateTargetModSkill {
    name = "qhstandardqicai",
    pattern = "TrickCard", -- 锦囊牌
    -- 每张锦囊牌可额外指定1个目标
    extra_target_func = function(self, player)
        if player:hasSkill(self:objectName()) then
            return 1
        end
    end,
    -- 使用锦囊牌无距离限制
    distance_limit_func = function(self, player)
        if player:hasSkill(self:objectName()) then
            return 1000 -- 无距离限制
        end
    end
}

-- 风包-强化 黄忠-烈弓
qhwindliegong = sgs.CreateTriggerSkill {
    name = "qhwindliegong",
    frequency = sgs.Skill_Frequent,
    events = { sgs.TargetSpecified, sgs.ConfirmDamage },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if not use.card:isKindOf("Slash") then
                return false
            end
            local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
            local index = 1
            for _, p in sgs.qlist(use.to) do
                if player:getHp() <= p:getHandcardNum() or player:getAttackRange() >= p:getHandcardNum() then
                    local _data = sgs.QVariant()
                    _data:setValue(p)
                    room:setPlayerFlag(player, "qhwindliegong_TargetSpecified")
                    if player:askForSkillInvoke(self:objectName(), _data) then
                        local effect = data:toSlashEffect() -- 杀生效结构体
                        local msg = sgs.LogMessage()
                        msg.type = "#qhstandardqiangming"
                        msg.from = player
                        msg.to:append(p)
                        msg.arg = self:objectName()
                        msg.card_str = use.card:toString()
                        room:sendLog(msg)                    -- 发送消息
                        room:broadcastSkillInvoke("liegong") -- 播放配音
                        jink_table[index] = 0                -- 0张闪
                    end
                    room:setPlayerFlag(player, "-qhwindliegong_TargetSpecified")
                end
                index = index + 1
            end
            local jink_data = sgs.QVariant()
            jink_data:setValue(Table2IntList(jink_table))
            player:setTag("Jink_" .. use.card:toString(), jink_data)
        end
        if event == sgs.ConfirmDamage then
            local damage = data:toDamage()          -- 获取伤害结构体
            local card = damage.card                -- 获取造成伤害的牌
            if card and card:isKindOf("Slash") then -- 如果是杀造成的伤害
                if not player:askForSkillInvoke(self:objectName(), data) then
                    return false
                end
                room:broadcastSkillInvoke("liegong") -- 播放配音
                if player:getHp() >= damage.to:getHp() then
                    room:drawCards(player, 1)
                end
                if player:getHp() <= damage.to:getHp() then
                    local msg = sgs.LogMessage()
                    msg.type = "#qhwindliegong"
                    msg.from = player
                    msg.to:append(damage.to)
                    msg.arg = damage.damage
                    msg.arg2 = damage.damage + 1
                    room:sendLog(msg) -- 发送消息
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
        end
    end
}

-- 弓术
qhwindgongshu = sgs.CreateTriggerSkill {
    name = "qhwindgongshu",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.DrawNCards },
    on_trigger = function(self, event, player, data, room)
        local draw = data:toDraw()
        if draw.reason ~= "draw_phase" then return false end
        if player:getWeapon() then
            room:sendCompulsoryTriggerLog(player, self:objectName())
            draw.num = draw.num + 1 -- 摸牌数
            data:setValue(draw)
        end
    end
}

-- 风包-强化 魏延-狂骨
qhwindkuanggu = sgs.CreateTriggerSkill {
    name = "qhwindkuanggu",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.Damage, sgs.Damaged },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage then
            local damage = data:toDamage() -- 获取伤害结构体
            if not (player:distanceTo(damage.to) <= 2) then
                return false
            end                                  -- 距离<=2
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke("kuanggu") -- 播放配音
            local num = damage.damage
            local lostHp = player:getLostHp()
            if num > lostHp then
                local Recover = sgs.RecoverStruct() -- 定义恢复结构体
                Recover.recover = lostHp
                Recover.who = player
                room:recover(player, Recover, true) -- 回血
                local markN = player:getMark("qhwindkuanggu_lun")
                if markN < 4 then
                    local drawN = math.min(num - lostHp, 4 - markN)
                    room:drawCards(player, drawN) -- 摸牌
                    room:setPlayerMark(player, "qhwindkuanggu_lun", markN + drawN)
                    room:setPlayerMark(player, "&qhwindkuanggu_lun", markN + drawN)
                end
            else
                local Recover = sgs.RecoverStruct() -- 定义恢复结构体
                Recover.recover = num
                Recover.who = player
                room:recover(player, Recover, true) -- 回血
            end
        end
        if event == sgs.Damaged then
            local damage = data:toDamage()        -- 获取伤害结构体
            room:sendCompulsoryTriggerLog(player, self:objectName())
            room:broadcastSkillInvoke("kuanggu")  -- 播放配音
            room:drawCards(player, damage.damage) -- 摸牌
        end
    end
}

--风包-强化 神关羽-武神
qhwindwushen = sgs.CreateTriggerSkill {
    name = "qhwindwushen",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.CardUsed },
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") and use.card:getSuit() == sgs.Card_Heart then
            room:broadcastSkillInvoke("wushen") -- 播放配音
            local msg = sgs.LogMessage()        -- 创建消息
            msg.type = "#qhwindwushen"          -- 消息结构类型(发送的消息是什么)
            msg.from = player
            msg.to = use.to
            msg.arg = self:objectName()
            msg.card_str = use.card:toString()
            room:sendLog(msg)                             -- 发送消息
            local no_respond_list = use.no_respond_list
            table.insert(no_respond_list, "_ALL_TARGETS") -- 不可响应
            use.no_respond_list = no_respond_list
            if use.m_addHistory then
                room:addPlayerHistory(player, use.card:getClassName(), -1) --次数-1
                use.m_addHistory = false
            end
            data:setValue(use)
            for _, target in sgs.qlist(use.to) do
                target:addQinggangTag(use.card)
            end
        end
    end
}

qhwindwushenFilter = sgs.CreateFilterSkill {
    name = "#qhwindwushenFilter",
    view_filter = function(self, to_select)
        local room = sgs.Sanguosha:currentRoom()
        local place = room:getCardPlace(to_select:getEffectiveId())
        return (to_select:getSuit() == sgs.Card_Heart) and (place == sgs.Player_PlaceHand)
    end,
    view_as = function(self, card)
        local suit = card:getSuit()
        local point = card:getNumber()
        local id = card:getId()
        local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
        slash:setSkillName(self:objectName())
        local vs_card = sgs.Sanguosha:getWrappedCard(id)
        vs_card:takeOver(slash)
        return vs_card
    end
}

--武魂
qhwindwuhun = sgs.CreateTriggerSkill {
    name = "qhwindwuhun",
    frequency = sgs.Skill_Compulsory,
    limit_mark = "&qhwindwuhun_limit",
    events = { sgs.Damage, sgs.Damaged, sgs.AskForPeaches, sgs.Death },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.Damage or event == sgs.Damaged then
            if player:getMark("qhwindwuhun-Clear") < 2 then
                room:broadcastSkillInvoke("wuhun", 1) -- 播放配音
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:drawCards(1, self:objectName())
                player:addMark("qhwindwuhun-Clear", 1)
                player:addMark("&qhwindwuhun-Clear", 1)
            end
        elseif event == sgs.AskForPeaches then
            local dying = data:toDying()
            if dying.who:objectName() ~= player:objectName() then
                return false
            end
            if player:getHp() > 0 then
                return false
            end
            if player:getMark("&qhwindwuhun_limit") == 0 then
                return false
            end
            room:broadcastSkillInvoke("wuhun", math.random(3, 5)) -- 播放配音
            room:sendCompulsoryTriggerLog(player, self:objectName())
            player:loseMark("&qhwindwuhun_limit", 1)
            player:drawCards(3, self:objectName())
            local Recover = sgs.RecoverStruct() -- 定义恢复结构体
            Recover.recover = 3
            Recover.who = player
            room:recover(player, Recover)
            local others = room:getOtherPlayers(player)
            local target = room:askForPlayerChosen(player, others, self:objectName(), "#qhwindwuhun", true)
            if target then
                room:doSuperLightbox("shenguanyu", self:objectName()) --动画
                local hp = target:getHp()
                hp = math.max(hp, 2)
                local Lost = sgs.HpLostStruct() -- 定义流失结构体
                Lost.from = player
                Lost.to = target
                Lost.reason = self:objectName()
                Lost.lose = hp
                room:loseHp(Lost)
            end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() ~= player:objectName() then
                return false
            end
            if player:getMark("&qhwindwuhun_limit") == 0 then
                return false
            end
            room:broadcastSkillInvoke("wuhun", math.random(3, 5)) -- 播放配音
            room:sendCompulsoryTriggerLog(player, self:objectName())
            player:loseMark("&qhwindwuhun_limit", 1)
            local others = room:getOtherPlayers(player)
            local target = room:askForPlayerChosen(player, others, self:objectName(), "#qhwindwuhun", true)
            if target then
                room:doSuperLightbox("shenguanyu", self:objectName()) --动画
                local hp = target:getHp()
                hp = math.max(hp, 2)
                local Lost = sgs.HpLostStruct() -- 定义流失结构体
                Lost.from = player
                Lost.to = target
                Lost.reason = self:objectName()
                Lost.lose = hp
                room:loseHp(Lost)
            end
        end
    end,
    can_trigger = function(self, target)
        if target and target:hasSkill(self:objectName()) then --死亡也可发动
            return true
        end
    end
}

--火包-强化 庞统-连环
qhfirelianhuan = sgs.CreateViewAsSkill {
    name = "qhfirelianhuan",
    n = 1,                                                                                                      -- 最大卡牌数
    response_or_use = true,                                                                                     -- 可以选择木牛流马上的牌
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then               -- 出牌阶段
            return to_select:isBlack()                                                                          -- 黑色
        elseif (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)          -- 响应
            or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then -- 使用
            return to_select:getSuit() == sgs.Card_Spade
        end
    end,
    view_as = function(self, cards)
        if #cards == 0 then                -- 一张卡牌也没选是不能发动技能的
            return nil                     -- 直接返回，nil表示无效
        elseif #cards == 1 then            -- 选择了一张卡牌
            local card = cards[1]          -- 获得发动技能的卡牌
            local suit = card:getSuit()    -- 卡牌的花色
            local point = card:getNumber() -- 卡牌的点数
            local id = card:getId()        -- 卡牌的编号
            local name
            if card:getSuit() == sgs.Card_Club then
                name = "iron_chain"                                    --铁索连环
            elseif card:getSuit() == sgs.Card_Spade then
                name = "thunder_slash"                                 --雷杀
            end
            local vs_card = sgs.Sanguosha:cloneCard(name, suit, point) -- 描述虚构卡牌的构成
            vs_card:addSubcard(id)                                     -- 用被选择的卡牌填充虚构卡牌
            vs_card:setSkillName(self:objectName())                    -- 创建虚构卡牌的技能名称
            return vs_card                                             -- 返回一张虚构的卡牌
        end
    end,
    enabled_at_play = function(self, player) -- 主动使用
        return true
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        return pattern == "slash"                         -- 出杀时
    end
}

--漫卷
qhfiremanjuann = sgs.CreateTriggerSkill {
    name = "qhfiremanjuann",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardsMoveOneTime },
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() == player:objectName() and player:getPhase() ~= sgs.Player_Draw then
            if player:hasFlag("qhfiremanjuann_using") then return false end
            if player:getMark("qhfiremanjuann-Clear") == 2 then return false end
            if move.to_place == sgs.Player_PlaceHand then      -- 如果将移动到手牌
                local discardPile = room:getDiscardPile()      --弃牌堆
                for _, cardid in sgs.qlist(move.card_ids) do   -- 扫描卡牌名单
                    local card = sgs.Sanguosha:getCard(cardid) -- 获取卡牌信息
                    local num = card:getNumber()
                    local ids = sgs.IntList()
                    for _, discardid in sgs.qlist(discardPile) do        -- 扫描弃牌堆
                        local discard = sgs.Sanguosha:getCard(discardid) -- 获取卡牌信息
                        local disnum = discard:getNumber()
                        if num == disnum then
                            ids:append(discardid)
                        end
                    end
                    if ids:length() > 0 then
                        room:fillAG(ids, player)
                        local id = room:askForAG(player, ids, true, self:objectName(), "#qhfiremanjuann")
                        room:clearAG(player)
                        if id >= 0 then
                            room:setPlayerFlag(player, "qhfiremanjuann_using")
                            room:broadcastSkillInvoke("manjuan") -- 播放配音
                            local msg = sgs.LogMessage()         -- 创建消息
                            msg.type = "#InvokeSkill"
                            msg.from = player
                            msg.arg = self:objectName()
                            room:sendLog(msg) -- 发送消息
                            room:addPlayerMark(player, "qhfiremanjuann-Clear", 1)
                            room:addPlayerMark(player, "&qhfiremanjuann-Clear", 1)
                            room:obtainCard(player, id)
                            room:setPlayerFlag(player, "-qhfiremanjuann_using")
                            break
                        end
                    end
                end
            end
        end
    end
}

--涅槃
qhfireniepan = sgs.CreateTriggerSkill {
    name = "qhfireniepan",
    frequency = sgs.Skill_Limited,
    events = { sgs.AskForPeaches },
    limit_mark = "&qhfireniepan_limit",
    on_trigger = function(self, event, player, data, room)
        if event == sgs.AskForPeaches then
            local dying = data:toDying()
            if dying.who:objectName() ~= player:objectName() then
                return false
            end
            if player:getMark("&qhfireniepan_limit") == 0 then
                return false
            end
            if not room:askForSkillInvoke(player, self:objectName(), data) then
                return false
            end
            player:loseMark("&qhfireniepan_limit")
            room:broadcastSkillInvoke("niepan")                 -- 播放配音
            room:doSuperLightbox("pangtong", self:objectName()) --动画
            local maxhp = player:getMaxHp()
            local hp = player:getHp()
            local Recover = sgs.RecoverStruct() -- 定义恢复结构体
            Recover.recover = math.min(4, maxhp) - hp
            Recover.who = player
            room:recover(player, Recover)
            player:drawCards(5)
            if player:isChained() then --连环
                local damage = dying.damage
                if (damage == nil) or (damage.nature == sgs.DamageStruct_Normal) then
                    room:setPlayerProperty(player, "chained", sgs.QVariant(false))
                end
            end
            if not player:faceUp() then --翻面
                player:turnOver()
            end
            local current = room:getCurrent()
            if not current then
                return false
            end
            if current:getPhase() == sgs.Player_Play then
                if room:askForSkillInvoke(player, "qhfireniepan_endPlay", sgs.QVariant("endPlay")) then
                    current:endPlayPhase() --结束出牌阶段
                end
            end
        end
    end
}

--火包-强化 诸葛亮-火计
qhfirehuojiVS = sgs.CreateViewAsSkill {                                               -- 火计 视为技
    name = "qhfirehuoji",
    n = 0,                                                                            -- 不选择卡牌
    view_as = function(self, cards)
        local vs_card = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_NoSuitRed, 0) -- 描述虚构卡牌的构成
        vs_card:setSkillName(self:objectName())                                       -- 创建虚构卡牌的技能名称
        return vs_card                                                                -- 返回一张虚构的卡牌
    end,
    enabled_at_play = function(self, player)                                          -- 主动使用
        return player:getMark("qhfirehuoji-PlayClear") == 0                               --无标记
    end,
}

qhfirehuoji = sgs.CreateTriggerSkill { -- 火计 触发技
    name = "qhfirehuoji",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhfirehuojiVS,
    events = { sgs.CardUsed },
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:getSkillName() == self:objectName() then
            room:broadcastSkillInvoke("huoji") -- 播放配音
            room:setPlayerMark(player, "qhfirehuoji-PlayClear", 1)
            local no_offset_list = use.no_offset_list
            table.insert(no_offset_list, "_ALL_TARGETS") -- 不可抵消
            use.no_offset_list = no_offset_list
            data:setValue(use)
        end
    end
}

--看破
qhfirekanpoVS = sgs.CreateViewAsSkill { --看破 视为技
    name = "qhfirekanpo",
    n = 1,                              -- 最大卡牌数
    response_or_use = true,             -- 可以选择木牛流马上的牌
    view_filter = function(self, selected, to_select)
        return to_select:isBlack()
    end,
    view_as = function(self, cards)
        if #cards == 0 then                                                       -- 一张卡牌也没选是不能发动技能的
            return nil                                                            -- 直接返回，nil表示无效
        elseif #cards == 1 then                                                   -- 选择了一张卡牌
            local card = cards[1]                                                 -- 获得发动技能的卡牌
            local suit = card:getSuit()                                           -- 卡牌的花色
            local point = card:getNumber()                                        -- 卡牌的点数
            local id = card:getId()                                               -- 卡牌的编号
            local vs_card = sgs.Sanguosha:cloneCard("nullification", suit, point) -- 描述虚构卡牌的构成
            vs_card:addSubcard(id)                                                -- 用被选择的卡牌填充虚构卡牌
            vs_card:setSkillName(self:objectName())                               -- 创建虚构卡牌的技能名称
            return vs_card                                                        -- 返回一张虚构的卡牌
        end
    end,
    enabled_at_play = function(self, player) -- 主动使用
        return false
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        return pattern == "nullification"                 -- 无懈时
    end,
    enabled_at_nullification = function(self, player)
        for _, card in sgs.qlist(player:getCards("he")) do
            if card:isBlack() then return true end
        end
        return false
    end

}

qhfirekanpo = sgs.CreateTriggerSkill { -- 看破 触发技
    name = "qhfirekanpo",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhfirekanpoVS,
    events = { sgs.CardUsed },
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Nullification") then
            room:broadcastSkillInvoke("kanpo") -- 播放配音
            if player:getMark("qhfirekanpo-Clear") == 0 then
                if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
                room:setPlayerMark(player, "qhfirekanpo-Clear", 1)
                room:setPlayerMark(player, "&qhfirekanpo-Clear", 1)
                room:drawCards(player, 1, self:objectName())
            end
        end
    end
}

--八阵
qhfirebazhen = sgs.CreateTriggerSkill {
    name = "qhfirebazhen",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardAsked },
    on_trigger = function(self, event, player, data, room)
        local pattern = data:toStringList()[1]
        local prompt = data:toStringList()[2]
        if pattern == "jink" then
            if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
            local judge = sgs.JudgeStruct()                    -- 判定结构体
            judge.who = player                                 -- 判定对象
            judge.pattern = ".|black|3~10"                     -- 判定规则
            judge.good = false                                 -- 判定结果符合判断规则会更有利
            judge.negative = false                             -- 对进行判定的人是否不利
            judge.reason = self:objectName()                   -- 判定原因
            room:judge(judge)                                  -- 进行判定
            if judge:isGood() then                             -- 判定成功
                room:setEmotion(player, "armor/eight_diagram") --表情
                local card = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
                card:setSkillName(self:objectName())
                room:provide(card) --出闪
            end
        end
    end
}

-- 标准版-强化 孙权-制衡
qhstandardzhihengVS = sgs.CreateViewAsSkill { -- 制衡 视为技
    name = "qhstandardzhiheng",
    n = 99,                                   -- 最大卡牌数
    view_filter = function(self, selected, to_select)
        if #selected < 99 then
            return true
        end
    end,
    view_as = function(self, cards)
        if #cards < 1 then
            return nil
        end                                         -- 一张卡牌也没选是不能发动技能的
        local acard = qhstandardzhihengCARD:clone() -- 创建技能卡
        for _, card in ipairs(cards) do             -- 扫描卡牌名单
            local id = card:getId()                 -- 卡牌的编号
            acard:addSubcard(id)                    -- 加入技能卡
        end
        acard:setSkillName(self:objectName())       -- 技能名称
        return acard
    end,
    enabled_at_play = function(self, player) -- 限制条件
        local maxhp = player:getMaxHp()
        local hp = player:getHp()
        cishu = maxhp - hp + 2 -- 计算最大使用次数
        local Mark = player:getMark("@qhstandardzhiheng")
        return Mark < cishu    -- 使用次数小于次数
    end
}

qhstandardzhihengCARD = sgs.CreateSkillCard {         -- 制衡 技能卡
    name = "qhstandardzhihengCARD",
    target_fixed = true,                              -- 不选择目标
    will_throw = false,                               -- 不立即丢弃
    on_use = function(self, room, source, targets)
        room:throwCard(self, source)                  -- 弃置发动技能的卡牌
        if source:isAlive() then                      -- 如果存活
            local Cardn = self:getSubcards():length() -- 获取子卡数量
            room:broadcastSkillInvoke("zhiheng")      -- 播放配音
            room:drawCards(source, Cardn)             -- 摸牌
            -- source:gainMark("@qhstandardzhiheng")--获取标记,表示使用次数
            local Mark = source:getMark("@qhstandardzhiheng")
            local MarkN = Mark + 1
            room:setPlayerMark(source, "@qhstandardzhiheng", MarkN) -- 获取标记,表示使用次数
        end
    end
}

qhstandardzhiheng = sgs.CreateTriggerSkill { -- 制衡 触发技
    name = "qhstandardzhiheng",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhstandardzhihengVS,
    events = { sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive then
            if player:getMark("@qhstandardzhiheng") < 2 then        -- 没有标记
                local HandcardNum = player:getHandcardNum()         -- 手牌数
                local MaxHp = player:getMaxHp()                     -- 体力上限
                local MaxHpXin = MaxHp / 1.5                        -- 体力上限除以1.5
                local MaxHpceil = math.ceil(MaxHpXin)
                if HandcardNum < MaxHpceil then                     -- 如果手牌数<体力上限
                    room:drawCards(player, MaxHpceil - HandcardNum) -- 摸牌
                end
            end
            -- player:loseAllMarks("@qhstandardzhiheng")--清除标记(使用次数)
            room:setPlayerMark(player, "@qhstandardzhiheng", 0) -- 清除标记(使用次数)
        end
    end
}

-- 救援
qhstandardjiuyuan = sgs.CreateTriggerSkill {
    name = "qhstandardjiuyuan$",   -- 主公技，添加“$”符号
    frequency = sgs.Skill_Compulsory,
    events = { sgs.PreHpRecover }, -- 体力恢复前
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local recover = data:toRecover()                                   -- 获取恢复结构体
        local from = recover.who                                           -- 获取恢复来源
        local card = recover.card                                          -- 获取恢复牌
        if card and card:isKindOf("Peach") then                            -- 若有恢复牌且恢复牌为桃
            if not from or (from:objectName() ~= player:objectName()) and player:hasLordSkill(self:objectName()) then -- 若无恢复来源或恢复来源不是恢复目标
                local number = recover.recover                             -- 获取恢复量
                recover.recover = number + 1                               -- 恢复量+1
                data:setValue(recover)                                     -- 保存恢复量
                room:broadcastSkillInvoke("jiuyuan")                       -- 播放配音
                if from:getKingdom() == "wu" then                          -- 如果是吴势力
                    local msg = sgs.LogMessage()                           -- 创建消息
                    msg.type = "#qhstandardjiuyuanwu"                      -- 消息结构类型(发送的消息是什么)
                    msg.from = from
                    msg.to:append(player)
                    msg.arg = 1
                    room:sendLog(msg) -- 发送消息
                    room:drawCards(player, 1, self:objectName())
                    room:drawCards(from, 1, self:objectName())
                else                                     -- 如果不是吴势力
                    local msg = sgs.LogMessage()         -- 创建消息
                    msg.type = "#qhstandardjiuyuanfeiwu" -- 消息结构类型(发送的消息是什么)
                    msg.from = from
                    msg.to:append(player)
                    room:sendLog(msg) -- 发送消息
                end
            end
        end
    end
}

-- 标准版-强化 甘宁-奇袭
qhstandardqixi = sgs.CreateViewAsSkill {
    name = "qhstandardqixi",
    n = 1,                         -- 最大卡牌数
    response_or_use = true,        -- 可以选择木牛流马上的牌
    view_filter = function(self, selected, to_select)
        return to_select:isBlack() -- 黑色
    end,
    view_as = function(self, cards)
        if #cards == 0 then                                                       -- 一张卡牌也没选是不能发动技能的
            return nil                                                            -- 直接返回，nil表示无效
        elseif #cards == 1 then                                                   -- 选择了一张卡牌
            local card = cards[1]                                                 -- 获得发动技能的卡牌
            local suit = card:getSuit()                                           -- 卡牌的花色
            local point = card:getNumber()                                        -- 卡牌的点数
            local id = card:getId()                                               -- 卡牌的编号
            local vs_card = sgs.Sanguosha:cloneCard("dismantlement", suit, point) -- 描述虚构过河拆桥卡牌的构成
            vs_card:addSubcard(id)                                                -- 用被选择的卡牌填充虚构卡牌
            vs_card:setSkillName(self:objectName())                               -- 创建虚构卡牌的技能名称
            return vs_card                                                        -- 返回一张虚构的卡牌
        end
    end,
    enabled_at_play = function(self, player) -- 主动使用
        return true
    end
}

-- 破袭
qhstandardpoxiCARD = sgs.CreateSkillCard {              -- 破袭 技能卡
    name = "qhstandardpoxiCARD",
    target_fixed = false,                               -- 选择目标
    filter = function(self, targets, to_select, player) -- 使用对象的约束条件
        return to_select:objectName() ~= player:objectName() and to_select:isKongcheng()
    end,
    on_use = function(self, room, source, targets) -- 具体使用效果
        room:broadcastSkillInvoke("fenwei")        -- 播放配音
        local damage = sgs.DamageStruct()
        damage.from = source
        damage.to = targets[1]
        damage.damage = 1
        room:damage(damage)
    end
}

qhstandardpoxiVS = sgs.CreateViewAsSkill { -- 破袭 视为技
    name = "qhstandardpoxi",
    n = 1,                                 -- 最大卡牌数
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()  --不是装备
    end,
    view_as = function(self, cards)
        if sgs.Self:isKongcheng() then
            return qhstandardpoxiCARD:clone()        -- 创建技能卡
        elseif #cards == 1 then
            local acard = qhstandardpoxiCARD:clone() -- 创建技能卡
            for _, card in ipairs(cards) do          -- 扫描卡牌名单
                local id = card:getId()              -- 卡牌的编号
                acard:addSubcard(id)                 -- 加入技能卡
            end
            return acard
        end
    end,
    enabled_at_play = function(self, player)              -- 主动使用
        return false                                      -- 不能
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        return pattern == "@qhstandardpoxi"               -- 询问使用突袭 视为技时,询问视为技的时机时前面要加@
    end
}

qhstandardpoxi = sgs.CreateTriggerSkill { -- 破袭 触发技
    name = "qhstandardpoxi",
    frequency = sgs.Skill_Frequent,
    view_as_skill = qhstandardpoxiVS,
    events = { sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then -- 若是准备阶段
            local players = room:getAllPlayers()
            local SPlayerList = sgs.SPlayerList()
            for _, dest in sgs.qlist(players) do -- 对名单中的所有角色进行扫描
                if not dest:isAllNude() then     -- 有牌
                    SPlayerList:append(dest)     -- 加入名单
                end
            end
            if SPlayerList:length() == 0 then
                return false
            end
            local target = room:askForPlayerChosen(player, SPlayerList, self:objectName(), "#qhstandardpoxi1", true, true)
            if target then
                room:broadcastSkillInvoke("fenwei") -- 播放配音
                local id = room:askForCardChosen(player, target, "hej", self:objectName())
                room:throwCard(id, target, player)
            end
        elseif player:getPhase() == sgs.Player_Finish then -- 若是结束阶段
            local players = room:getOtherPlayers(player)
            for _, dest in sgs.qlist(players) do           -- 对名单中的所有角色进行扫描
                if dest:isKongcheng() then                 -- 没手牌
                    room:askForUseCard(player, "@qhstandardpoxi", "#qhstandardpoxi2", -1, sgs.Card_MethodNone)
                    -- 询问使用破袭视为技
                    break
                end
            end
        end
    end
}

-- 标准版-强化 吕蒙-克己
qhstandardkeji = sgs.CreateTriggerSkill {
    name = "qhstandardkeji",
    frequency = sgs.Skill_Frequent,
    events = { sgs.PreCardUsed, sgs.CardResponded, sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local cantrigger = true
            if player:hasFlag("qhstandardkejiSlashInPlayPhase") then
                cantrigger = false
                player:setFlags("-qhstandardkejiSlashInPlayPhase")
            end
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard then
                if cantrigger and room:askForSkillInvoke(player, self:objectName(), data) then
                    room:broadcastSkillInvoke("keji")                     -- 播放配音
                    room:drawCards(player, 3, self:objectName())          -- 摸牌
                    room:setPlayerMark(player, "qhstandardkeji-Clear", 1) -- 标记
                end
            end
        else
            if player:getPhase() == sgs.Player_Play then -- 出牌阶段
                local card = nil
                if event == sgs.PreCardUsed then
                    card = data:toCardUse().card
                else
                    card = data:toCardResponse().m_card
                end
                if card:isKindOf("Slash") then
                    player:setFlags("qhstandardkejiSlashInPlayPhase")
                end
            end
        end
    end
}

-- 标准版-强化 黄盖-苦肉
qhstandardkurouVS = sgs.CreateViewAsSkill {       -- 苦肉 视为技
    name = "qhstandardkurou",
    n = 0,                                        -- 不选择卡牌
    view_as = function(self, cards)
        local fcard = qhstandardkurouCARD:clone() -- 创建技能卡
        fcard:setSkillName(self:objectName())     -- 技能名称
        return fcard
    end,
    enabled_at_play = function(self, player)                -- 限制条件
        return player:usedTimes("#qhstandardkurouCARD") < 5 -- 使用次数小于5
    end
}

qhstandardkurouCARD = sgs.CreateSkillCard {                                     -- 苦肉 技能卡
    name = "qhstandardkurouCARD",
    target_fixed = true,                                                        -- 不选择目标
    on_use = function(self, room, source, targets)
        room:loseHp(source)                                                     -- 失去体力
        if source:isAlive() then                                                -- 存活
            room:drawCards(source, 3, self:objectName())
            room:broadcastSkillInvoke("kurou")                                  -- 播放配音
            room:addPlayerMark(source, "&qhstandardkurou-Clear")
            if source:usedTimes("#qhstandardkurouCARD") == 1 then
                room:setPlayerMark(source, "qhstandardkurou_extra_distance", 1) -- 获得标记(杀额外目标数量 杀额外使用距离)
            end
            if source:usedTimes("#qhstandardkurouCARD") == 2 or source:usedTimes("#qhstandardkurouCARD") == 3 then
                room:setPlayerMark(source, "qhstandardkurou_residue", source:getMark("qhstandardkurou_residue") + 1) -- 获得标记(杀额外使用次数)
            end
        end
    end
}

qhstandardkurou = sgs.CreateTriggerSkill { -- 苦肉 触发技
    name = "qhstandardkurou",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhstandardkurouVS,
    events = { sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive then
            room:setPlayerMark(player, "qhstandardkurou_extra_distance", 0) -- 清除标记
            room:setPlayerMark(player, "qhstandardkurou_residue", 0)        -- 清除标记
        end
    end
}

-- 标准版-强化 周瑜-英姿
qhstandardyingzi = sgs.CreateTriggerSkill {
    name = "qhstandardyingzi",
    frequency = sgs.Skill_Frequent,
    events = { sgs.DrawNCards, sgs.EventPhaseSkipping },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawNCards then -- 摸牌阶段摸牌时
            local draw = data:toDraw()
            if draw.reason ~= "draw_phase" then return false end
            if not room:askForSkillInvoke(player, self:objectName(), data) then
                return false
            end
            if player:getHandcardNum() < 4 then                        -- 手牌数 < 4
                draw.num = draw.num + 2
                room:broadcastSkillInvoke("yingzi", math.random(1, 2)) -- 播放配音
            else
                draw.num = draw.num + 1
                room:broadcastSkillInvoke("yingzi", math.random(3, 4)) -- 播放配音
            end
            data:setValue(draw)                                       -- 设置摸牌数
        end
        if event == sgs.EventPhaseSkipping then                        -- 跳过阶段时
            if player:getPhase() == sgs.Player_Draw then               -- 摸牌阶段
                if not room:askForSkillInvoke(player, self:objectName(), data) then
                    return false
                end
                room:broadcastSkillInvoke("yingzi", math.random(5, 6)) -- 播放配音
                player:drawCards(2, self:objectName())
            end
        end
    end
}

-- 反间
qhstandardfanjian = sgs.CreateViewAsSkill { -- 反间 视为技
    name = "qhstandardfanjian",
    n = 1,                                  -- 最大卡牌数
    view_filter = function(self, selected, to_select)
        if #selected == 0 and not to_select:isEquipped() then
            return true
        end -- 不是装备
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end                                         -- 一张卡牌也没选是不能发动技能的
        local acard = qhstandardfanjianCARD:clone() -- 创建技能卡
        local card = cards[1]                       -- 获得发动技能的卡牌
        local id = card:getId()                     -- 卡牌的编号
        acard:addSubcard(id)                        -- 加入技能卡
        acard:setSkillName(self:objectName())       -- 技能名称
        return acard
    end,
    enabled_at_play = function(self, player)                    -- 限制条件
        if not player:isKongcheng() then                        -- 有手牌
            return not player:hasUsed("#qhstandardfanjianCARD") -- 没使用过技能卡
        end
        return false
    end
}

qhstandardfanjianCARD = sgs.CreateSkillCard {                                  -- 反间 技能卡
    name = "qhstandardfanjianCARD",
    target_fixed = false,                                                      -- 选择目标
    will_throw = false,                                                        -- 不立即丢弃
    filter = function(self, targets, to_select, player)                        -- 使用对象的约束条件
        return #targets == 0 and to_select:objectName() ~= player:objectName() -- 没有选择目标且目标不是自己
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        local card_id = card:getEffectiveId()
        room:broadcastSkillInvoke("fanjian")                    -- 播放配音
        local suit = room:askForSuit(target, self:objectName()) -- 询问花色
        room:getThread():delay(800)                             -- 等待
        room:showCard(source, card_id)
        local msg = sgs.LogMessage()                            -- 创建消息
        msg.type = "#qhstandardfanjian"                         -- 消息结构类型(发送的消息是什么)
        msg.from = source
        msg.to:append(target)
        msg.arg = sgs.Card_Suit2String(suit) -- 转化为成对应的花色名称
        msg.card_str = card:toString()
        room:sendLog(msg)                    -- 发送消息
        if card:getSuit() ~= suit then       -- 花色不同
            target:obtainCard(self)
            local damage = sgs.DamageStruct()
            damage.card = nil
            damage.from = source
            damage.to = target
            room:damage(damage)
        else
            room:throwCard(self, source) -- 弃置发动技能的卡牌
            if source:canDiscard(target) then
                local id = room:askForCardChosen(source, target, "he", "qhstandardfanjian", false,
                    sgs.Card_MethodDiscard)
                room:throwCard(id, target, source)
            end
        end
    end
}

-- 标准版-强化 大乔-国色
qhstandardguoseVS = sgs.CreateViewAsSkill { -- 国色 视为技
    name = "qhstandardguose",
    n = 1,                                  -- 最大卡牌数
    response_or_use = true,                 -- 可以选择木牛流马上的牌
    view_filter = function(self, selected, to_select)
        if to_select:getSuit() == sgs.Card_Diamond then
            return true
        end -- 方片
    end,
    view_as = function(self, cards)
        if #cards == 0 then                                                               -- 一张卡牌也没选是不能发动技能的
            return nil                                                                    -- 直接返回，nil表示无效
        elseif #cards == 1 then                                                           -- 选择了一张卡牌
            local card = cards[1]                                                         -- 获得发动技能的卡牌
            local suit = card:getSuit()                                                   -- 卡牌的花色
            local point = card:getNumber()                                                -- 卡牌的点数
            local id = card:getId()                                                       -- 卡牌的编号
            local vs_card = sgs.Sanguosha:cloneCard("qhstandard_indulgence", suit, point) -- 描述虚构乐不思蜀卡牌的构成
            vs_card:addSubcard(id)                                                        -- 用被选择的卡牌填充虚构卡牌
            vs_card:setSkillName(self:objectName())                                       -- 创建虚构卡牌的技能名称
            return vs_card                                                                -- 返回一张虚构的卡牌
        end
    end
}

qhstandardguose = sgs.CreateTriggerSkill { -- 国色 触发技
    name = "qhstandardguose",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardUsed },
    view_as_skill = qhstandardguoseVS,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if player:hasFlag("qhstandardguose_used") then
            return false
        end                                                                                          -- 不发动
        if use.card:isKindOf("TrickCard") and room:askForSkillInvoke(player, self:objectName()) then -- 锦囊牌
            room:broadcastSkillInvoke("guose")                                                       -- 播放配音
            room:drawCards(player, 1, self:objectName())
            player:setFlags("qhstandardguose_used")
        end
    end
}

-- 流离
qhstandardliuliVS = sgs.CreateViewAsSkill { -- 流离 视为技
    name = "qhstandardliuli",
    n = 1,                                  -- 最大卡牌数
    view_filter = function(self, selected, to_select)
        return true                         -- 都可用
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end                                       -- 一张卡牌也没选是不能发动技能的
        local acard = qhstandardliuliCARD:clone() -- 创建技能卡
        local card = cards[1]                     -- 获得发动技能的卡牌
        local id = card:getId()                   -- 卡牌的编号
        acard:addSubcard(id)                      -- 加入技能卡
        acard:setSkillName(self:objectName())     -- 技能名称
        return acard
    end,
    enabled_at_play = function(self, player)              -- 限制条件
        return false                                      -- 不能
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        return pattern == "@qhstandardliuli"              -- 询问使用流离 视为技时
    end
}

qhstandardliuliCARD = sgs.CreateSkillCard {             -- 流离 技能卡
    name = "qhstandardliuliCARD",
    filter = function(self, targets, to_select, player) -- 使用对象的约束条件
        local canChoicefrom = false                     -- 低血可以选使用者
        if player:getHp() <= 2 then
            canChoicefrom = true
        end
        if not canChoicefrom and to_select:hasFlag("qhstandardLiuliSlashSource") then
            return false
        end -- 不能为来源
        if to_select:objectName() == player:objectName() then
            return false
        end -- 不能为自己
        local from
        for _, play in sgs.qlist(player:getSiblings()) do
            if play:hasFlag("qhstandardLiuliSlashSource") then
                from = play
                break
            end
        end
        local slash = sgs.Card_Parse(player:property("qhstandardliuli"):toString())
        if from and
            not ((canChoicefrom and to_select:hasFlag("qhstandardLiuliSlashSource")) or
                from:canSlash(to_select, slash, false)) then
            return false
        end -- 可以成为杀的目标
        local card_id = self:getSubcards():first()
        local range_fix = -1
        if player:getWeapon() and (player:getWeapon():getId() == card_id) then -- 选择武器
            local weapon = player:getWeapon():getRealCard():toWeapon()
            range_fix = range_fix + weapon:getRange() - 1
        elseif player:getOffensiveHorse() and (player:getOffensiveHorse():getId() == card_id) then -- 选择-1马
            range_fix = range_fix + 1
        end
        return player:distanceTo(to_select, range_fix) <= player:getAttackRange() -- 距离-1小于等于攻击范围
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:broadcastSkillInvoke("liuli") -- 播放配音
        effect.to:setFlags("qhstandardliuliTarget")
    end
}

qhstandardliuli = sgs.CreateTriggerSkill { -- 流离 触发技
    name = "qhstandardliuli",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.TargetConfirming },
    priority = 1,
    view_as_skill = qhstandardliuliVS,
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if not (use.card and use.card:isKindOf("Slash")) then
            return false
        end                         -- 若牌为杀
        local canChoicefrom = false -- 低血可以选使用者
        if player:getHp() <= 2 then
            canChoicefrom = true
        end
        if use.to:contains(player) and player:canDiscard(player, "he") and
            (canChoicefrom or (room:alivePlayerCount() > 2)) then
            local players = room:getOtherPlayers(player)
            if not canChoicefrom then
                players:removeOne(use.from) -- 移除来源
            end
            local can_invoke = false
            for _, play in sgs.qlist(players) do
                if canChoicefrom or use.from:canSlash(play, use.card, false) then  -- 可以成为杀的目标
                    if player:distanceTo(play, -1) <= player:getAttackRange() then -- 距离-1小于等于攻击范围
                        can_invoke = true
                        break
                    end
                end
            end
            if can_invoke then
                local prompt = ("#askForUseqhstandardliuliVS:%s"):format(use.from:objectName())
                room:setPlayerFlag(use.from, "qhstandardLiuliSlashSource")
                room:setPlayerProperty(player, "qhstandardliuli", sgs.QVariant(use.card:toString())) -- 保存卡片信息
                if room:askForUseCard(player, "@qhstandardliuli", prompt, -1, sgs.Card_MethodDiscard) then
                    -- 询问使用流离视为技
                    room:setPlayerProperty(player, "qhstandardliuli", sgs.QVariant())
                    room:setPlayerFlag(use.from, "-qhstandardLiuliSlashSource")
                    for _, play in sgs.qlist(players) do
                        if play:hasFlag("qhstandardliuliTarget") then
                            play:setFlags("-qhstandardliuliTarget")
                            use.to:removeOne(player)
                            use.to:append(play) -- 转移目标
                            room:sortByActionOrder(use.to)
                            data:setValue(use)
                            room:getThread():trigger(sgs.TargetConfirming, room, play, data) -- 触发额外时机
                        end
                    end
                else
                    room:setPlayerProperty(player, "qhstandardliuli", sgs.QVariant())
                    room:setPlayerFlag(use.from, "-qhstandardLiuliSlashSource")
                end
            end
        end
    end
}

-- 标准版-强化 陆逊-谦逊
qhstandardqianxun = sgs.CreateProhibitSkill { -- 禁止技
    name = "qhstandardqianxun",
    is_prohibited = function(self, from, to, card)
        if to:hasSkill(self:objectName()) then
            -- 顺手牵羊 乐不思蜀 决斗 万箭齐发
            return card:isKindOf("Snatch") or card:isKindOf("Indulgence") or card:isKindOf("QhstandardIndulgence") or
                card:isKindOf("Duel") or card:isKindOf("ArcheryAttack")
        end
    end
}

-- 连营
qhstandardlianying = sgs.CreateTriggerSkill {
    name = "qhstandardlianying",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardsMoveOneTime, sgs.EventPhaseChanging, sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            if not player:hasSkill(self:objectName()) then
                return false
            end
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() and
                move.from_places:contains(sgs.Player_PlaceHand) then
                if player:getHandcardNum() < 2 and player:getMark("@qhstandardlianying") < 4 then
                    if room:askForSkillInvoke(player, self:objectName(), data) then
                        room:broadcastSkillInvoke("lianying") -- 播放配音
                        player:gainMark("@qhstandardlianying", 2 - player:getHandcardNum())
                        player:drawCards(2 - player:getHandcardNum(), self:objectName())
                    end
                end
            end
        end
        if event == sgs.EventPhaseChanging then -- 可以在任意角色的回合清除标记
            local players = room:getAllPlayers()
            for _, play in sgs.qlist(players) do
                room:setPlayerMark(play, "@qhstandardlianying", 0) -- 清除标记
            end
        end
        if event == sgs.EventPhaseStart then
            if not player:hasSkill(self:objectName()) then
                return false
            end
            if player:getPhase() == sgs.Player_Finish then                                                       -- 若是结束阶段
                if room:askForDiscard(player, self:objectName(), 10, 1, true, false, "#qhstandardlianying") then -- 询问弃牌 可不弃
                    room:drawCards(player, 1, self:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target -- 任何角色触发都能发动
    end
}

-- 标准版-强化 孙尚香-结姻
qhstandardjieyin = sgs.CreateViewAsSkill { -- 结姻 视为技
    name = "qhstandardjieyin",
    n = 2,                                 -- 最大卡牌数
    view_filter = function(self, selected, to_select)
        if #selected < 2 then
            return true
        end -- 已选少于2张
    end,
    view_as = function(self, cards)
        if #cards < 2 then
            return nil
        end                                        -- 没选2张是不能发动技能的
        local acard = qhstandardjieyinCARD:clone() -- 创建技能卡
        for i = 1, 2, 1 do
            local card = cards[i]                  -- 获得发动技能的卡牌
            local id = card:getId()                -- 卡牌的编号
            acard:addSubcard(id)                   -- 加入技能卡
        end
        acard:setSkillName(self:objectName())      -- 技能名称
        return acard
    end,
    enabled_at_play = function(self, player)               -- 限制条件
        return not player:hasUsed("#qhstandardjieyinCARD") -- 没使用过技能卡
    end
}

qhstandardjieyinCARD = sgs.CreateSkillCard {            -- 结姻 技能卡
    name = "qhstandardjieyinCARD",
    target_fixed = false,                               -- 选择目标
    will_throw = true,                                  -- 立即丢弃
    filter = function(self, targets, to_select, player) -- 使用对象的约束条件
        return #targets == 0 and to_select:isWounded()  -- 没有选择目标且目标非满血
    end,
    feasible = function(self, targets)                  -- 技能卡可以使用的约束条件
        if #targets == 1 then
            return targets[1]:isWounded()
        end
        return #targets == 0 and sgs.Self:isWounded()
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1] or source
        for i = 1, 2, 1 do
            local effect = sgs.CardEffectStruct()
            effect.card = self
            effect.from = source
            if i == 1 then
                effect.to = target
            else
                effect.to = source
            end
            room:cardEffect(effect)
        end
        if target:isMale() then
            target:drawCards(1, self:objectName())
        end
    end,
    on_effect = function(self, effect)
        local dest = effect.to
        local source = effect.from
        local room = dest:getRoom()
        if dest:isWounded() then
            local Recover = sgs.RecoverStruct() -- 定义恢复结构体
            Recover.recover = 1
            Recover.who = source
            Recover.card = self
            room:recover(dest, Recover, true) -- 回血
        else
            dest:drawCards(1, self:objectName())
        end
        room:broadcastSkillInvoke("jieyin") -- 播放配音
    end
}

-- 枭姬
qhstandardxiaoji = sgs.CreateTriggerSkill {
    name = "qhstandardxiaoji",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardsMoveOneTime, sgs.TurnStart },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() and
                move.from_places:contains(sgs.Player_PlaceEquip) then
                for i = 0, move.card_ids:length() - 1, 1 do
                    if not player:isAlive() then
                        return false
                    end
                    local num = player:getMark("qhstandardxiaoji")
                    if num >= 4 then
                        return false
                    end
                    if move.from_places:at(i) == sgs.Player_PlaceEquip then
                        if room:askForSkillInvoke(player, self:objectName()) then
                            room:broadcastSkillInvoke("xiaoji") -- 播放配音
                            player:drawCards(3)
                            room:setPlayerMark(player, "qhstandardxiaoji", num + 1)
                        else
                            break
                        end
                    end
                end
            end
        end
        if event == sgs.TurnStart then                        -- 回合开始前
            room:setPlayerMark(player, "qhstandardxiaoji", 0) -- 清除标记
        end
    end
}

-- 风包-强化 小乔-红颜
qhwindhongyan = sgs.CreateTriggerSkill {
    name = "qhwindhongyan",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.ConfirmDamage, sgs.PreHpRecover, sgs.CardFinished },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.ConfirmDamage then
            local damage = data:toDamage()
            local card = damage.card
            if damage.from and damage.from:hasSkill(self:objectName()) then
                if card and card:getSuit() == sgs.Card_Heart then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:broadcastSkillInvoke("hongyan") -- 播放配音
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
        end
        if event == sgs.PreHpRecover then
            local recover = data:toRecover() -- 获取恢复结构体
            local card = recover.card        -- 获取恢复牌
            if recover.who and recover.who:hasSkill(self:objectName()) then
                if card and card:getSuit() == sgs.Card_Heart then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:broadcastSkillInvoke("hongyan") -- 播放配音
                    recover.recover = recover.recover + 1
                    data:setValue(recover)
                end
            end
        end
        if event == sgs.CardFinished then
            if not player:hasSkill(self:objectName()) then
                return false
            end
            local use = data:toCardUse()
            if use.card and not use.card:isKindOf("SkillCard") and use.card:getSuit() == sgs.Card_Heart then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke("hongyan") -- 播放配音
                local num = math.random(1, 2)
                room:drawCards(player, num, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target -- 任何角色触发都能发动
    end
}

-- 天香
qhwindtianxiangVS = sgs.CreateViewAsSkill { -- 天香 视为技
    name = "qhwindtianxiang",
    n = 1,
    view_filter = function(self, selected, to_select)
        if #selected == 0 and not to_select:isEquipped() then
            if to_select:getSuit() == sgs.Card_Heart or to_select:getSuit() == sgs.Card_Spade then
                return true
            end -- 红桃或黑桃
        end
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end                                       -- 一张卡牌也没选是不能发动技能的
        local acard = qhwindtianxiangCARD:clone() -- 创建技能卡
        acard:addSubcard(cards[1])                -- 加入技能卡
        acard:setSkillName(self:objectName())     -- 技能名称
        return acard
    end,
    enabled_at_play = function(self, player)
        return false -- 不能主动使用
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@qhwindtianxiang" -- 询问使用天香 视为技时
    end
}

qhwindtianxiangCARD = sgs.CreateSkillCard {                                    -- 天香 技能卡
    name = "qhwindtianxiangCARD",
    target_fixed = false,                                                      -- 选择目标
    filter = function(self, targets, to_select, player)                        -- 使用对象的约束条件
        return #targets == 0 and to_select:objectName() ~= player:objectName() -- 没有选择目标且目标不是自己
    end,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke("tianxiang") -- 播放配音
        local target = targets[1]
        local damage = source:property("qhwindtianxiangdata"):toDamage()
        damage.to = target
        damage.transfer = true
        damage.transfer_reason = "qhwindtianxiang"
        room:damage(damage)
    end
}

qhwindtianxiang = sgs.CreateTriggerSkill { -- 天香 触发技
    name = "qhwindtianxiang",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhwindtianxiangVS,
    events = { sgs.DamageInflicted, sgs.DamageComplete }, -- 受到伤害时 伤害结算完毕时
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageInflicted then
            if not player:hasSkill(self:objectName()) then
                return false
            end
            if not player:canDiscard(player, "h") then
                return false
            end
            local damage = data:toDamage()
            room:setPlayerProperty(player, "qhwindtianxiangdata", data)
            local fromName = "nil"
            if damage.from then
                fromName = damage.from:objectName()
            end
            local prompt = ("#askForqhwindtianxiang:%s:%d"):format(fromName, damage.damage)
            if room:askForUseCard(player, "@qhwindtianxiang", prompt, -1, sgs.Card_MethodDiscard) then
                return true
            end
        end
        if event == sgs.DamageComplete then
            local damage = data:toDamage()
            if player:isAlive() and damage.transfer and damage.transfer_reason == "qhwindtianxiang" then
                local num = math.min(player:getLostHp(), 2)
                room:drawCards(player, num, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target -- 任何角色触发都能发动
    end
}

-- 风包-强化 周泰-不屈
qhwindbuqu = sgs.CreateTriggerSkill {
    name = "qhwindbuqu",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.AskForPeaches },
    priority = 2,
    on_trigger = function(self, event, player, data, room)
        local dying = data:toDying()
        if dying.who:objectName() ~= player:objectName() then
            return false
        end
        if player:getHp() > 0 then
            return false
        end
        room:sendCompulsoryTriggerLog(player, self:objectName())
        local id = room:drawCard()
        local msg = sgs.LogMessage() -- 创建消息
        msg.type = "#qhwindbuqu"     -- 消息结构类型(发送的消息是什么)
        msg.from = player
        msg.card_str = sgs.Sanguosha:getCard(id):toString()
        room:sendLog(msg) -- 发送消息
        local num = sgs.Sanguosha:getCard(id):getNumber()
        local duplicate = false
        local qhwindbuquPile = player:getPile("qhwindbuqu")
        if qhwindbuquPile:length() > 5 then
            for _, card_id in sgs.qlist(qhwindbuquPile) do
                if sgs.Sanguosha:getCard(card_id):getNumber() == num then
                    duplicate = true
                    break
                end
            end
        end
        room:broadcastSkillInvoke("buqu") -- 播放配音
        if duplicate then
            player:obtainCard(sgs.Sanguosha:getCard(id))
        else
            player:addToPile("qhwindbuqu", id)
            local Recover = sgs.RecoverStruct() -- 定义恢复结构体
            Recover.recover = 1 - player:getHp()
            Recover.who = player
            room:recover(player, Recover)
        end
    end
}

--奋激
qhwindfenji = sgs.CreateTriggerSkill {
    name = "qhwindfenji",
    frequency = sgs.Skill_Frequent,
    events = { sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            if player:getMark("qhwindfenji") == 0 then
                room:setPlayerMark(player, "qhwindfenji", 1)
                local players = room:getAllPlayers()
                local SPlayerList = sgs.SPlayerList()
                for _, dest in sgs.qlist(players) do -- 对名单中的所有角色进行扫描
                    if player:canDiscard(dest, "he") then     -- 有牌
                        SPlayerList:append(dest)     -- 加入名单
                    end
                end
                if SPlayerList:length() == 0 then
                    return false
                end
                local target = room:askForPlayerChosen(player, SPlayerList, self:objectName(), "#qhwindfenjiDis", true,
                    true)
                if target then
                    room:broadcastSkillInvoke("fenji") -- 播放配音
                    local id = room:askForCardChosen(player, target, "he", self:objectName())
                    room:throwCard(id, target, player)
                end
            else
                room:setPlayerMark(player, "qhwindfenji", 0)
                if not room:askForSkillInvoke(player, self:objectName()) then
                    return false
                end
                room:broadcastSkillInvoke("fenji") -- 播放配音
                local qhwindbuquPile = player:getPile("qhwindbuqu")
                if qhwindbuquPile:length() == 0 then
                    player:drawCards(1, self:objectName())
                else
                    room:fillAG(qhwindbuquPile)
                    local card_id = room:askForAG(player, qhwindbuquPile, false, self:objectName())
                    local msg = sgs.LogMessage()
                    msg.type = "#qhwindfenji"
                    msg.from = player
                    msg.card_str = sgs.Sanguosha:getCard(card_id):toString()
                    room:sendLog(msg)
                    player:obtainCard(sgs.Sanguosha:getCard(card_id))
                    room:clearAG()
                end
            end
        end
    end
}

-- 风包-强化 神吕蒙-涉猎
qhwindshelie = sgs.CreateTriggerSkill {
    name = "qhwindshelie",
    frequency = sgs.Skill_Frequent,
    events = { sgs.DrawNCards, sgs.EventPhaseSkipping },
    priority = { -1, 1 },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DrawNCards or (event == sgs.EventPhaseSkipping and player:getPhase() == sgs.Player_Draw) then
            local draw = data:toDraw()
            if draw.reason ~= "draw_phase" then return false end
            local drawCardNum = draw.num
            if event == sgs.EventPhaseSkipping or drawCardNum >= 1 then
                if not room:askForSkillInvoke(player, self:objectName()) then
                    return false
                end
                room:broadcastSkillInvoke("shelie") -- 播放配音
                local card_ids = room:getNCards(7)
                local cardNum = card_ids:length()
                local SelectedNum = 0                                                       -- 计数
                local card_list = sgs.IntList()                                             -- 已选卡牌
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)          -- 被弃卡牌
                room:fillAG(card_ids)                                                       -- 填充AG
                for i = 1, 4, 1 do
                    local ag_id = room:askForAG(player, card_ids, false, self:objectName()) -- 询问AG
                    local suit = sgs.Sanguosha:getCard(ag_id):getSuit()
                    card_list:append(ag_id)
                    card_ids:removeOne(ag_id)
                    room:takeAG(player, ag_id, false) -- AG显示被选择
                    SelectedNum = SelectedNum + 1
                    for j = card_ids:length() - 1, 0, -1 do
                        local id = card_ids:at(j)
                        if id ~= ag_id then
                            if sgs.Sanguosha:getCard(id):getSuit() == suit then
                                card_ids:removeOne(id)
                                room:takeAG(nil, id, false) -- AG显示被选择(空)
                                SelectedNum = SelectedNum + 1
                                dummy:addSubcard(id)
                            end
                        end
                    end
                    if cardNum <= SelectedNum then -- 无可选的牌
                        break
                    end
                end
                room:clearAG()
                local MoveReason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DRAW, player:objectName(),
                    self:objectName(), nil)
                local move = sgs.CardsMoveStruct()
                move.card_ids = card_list
                move.to = player
                move.to_place = sgs.Player_PlaceHand
                move.reason = MoveReason
                room:moveCardsAtomic(move, true) -- 可见移动牌
                if not dummy:getSubcards():isEmpty() then
                    MoveReason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(),
                        self:objectName(), nil)
                    room:throwCard(dummy, MoveReason, player) -- 弃牌
                end
                dummy:deleteLater()
                if event == sgs.DrawNCards then
                    local draw = data:toDraw()
				    if draw.reason ~= "draw_phase" then return false end
                        draw.num = draw.num - 1
                    data:setValue(draw)
                end
            end
        end
    end
}

-- 攻心
qhwindgongxin = sgs.CreateViewAsSkill {         -- 攻心 视为技
    name = "qhwindgongxin",
    n = 0,                                      -- 不选择卡牌
    view_as = function(self, cards)
        local fcard = qhwindgongxinCARD:clone() -- 创建技能卡
        fcard:setSkillName(self:objectName())   -- 技能名称
        return fcard
    end,
    enabled_at_play = function(self, player)            -- 限制条件
        return not player:hasUsed("#qhwindgongxinCARD") -- 没使用过技能卡
    end
}

qhwindgongxinCARD = sgs.CreateSkillCard {                                                                    -- 攻心 技能卡
    name = "qhwindgongxinCARD",
    target_fixed = false,                                                                                    -- 选择目标
    filter = function(self, targets, to_select, player)                                                      -- 使用对象的约束条件
        return #targets == 0 and to_select:objectName() ~= player:objectName() and not to_select:isAllNude() -- 有牌的其他角色
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        room:broadcastSkillInvoke("gongxin") -- 播放配音
        local id = room:askForCardChosen(source, target, "hej", "qhwindgongxin", true)
        room:obtainCard(source, id, false)   -- 获得
    end
}

--火包-强化 太史慈-天义
qhfiretianyiVS = sgs.CreateViewAsSkill { -- 天义 视为技
    name = "qhfiretianyi",
    n = 1,                               -- 最大卡牌数
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if # cards == 0 then
            if sgs.Self:getMark("qhfiretianyi_slash-Clear") == 1 then
                local vs_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) -- 描述虚构卡牌的构成
                vs_card:setSkillName(self:objectName())                              -- 创建虚构卡牌的技能名称
                return vs_card                                                       -- 返回一张虚构的卡牌
            end
        elseif # cards == 1 then
            if not sgs.Self:hasUsed("#qhfiretianyiCARD") then
                local acard = qhfiretianyiCARD:clone()
                acard:addSubcard(cards[1])
                return acard
            end
        end
    end,
    enabled_at_play = function(self, player)            -- 主动使用
        if not player:hasUsed("#qhfiretianyiCARD") then -- 没使用过技能卡
            return true
        end
        if player:getMark("qhfiretianyi_slash-Clear") == 1 then
            return true
        end
    end,
}

qhfiretianyiCARD = sgs.CreateSkillCard { -- 天义 技能卡
    name = "qhfiretianyiCARD",
    target_fixed = false,                -- 选择目标
    will_throw = false,                  -- 不立即丢弃
    filter = function(self, targets, to_select, player)
        if to_select:objectName() ~= player:objectName() and not to_select:isKongcheng() and player:canPindian(to_select) then
            return true
        end
    end,
    on_effect = function(self, effect)
        local from, to = effect.from, effect.to
        local room = from:getRoom()
        room:broadcastSkillInvoke("tianyi", 1) -- 播放配音
        local pindian = from:PinDian(to, "qhfiretianyi", self)
        if pindian.success then
            room:broadcastSkillInvoke("tianyi", 2) -- 播放配音
            room:setPlayerMark(from, "qhfiretianyi_success-Clear", 1)
            room:setPlayerMark(from, "qhfiretianyi_slash-Clear", 1)
            room:setPlayerMark(from, "&qhfiretianyi-Clear", 1)
        else
            room:broadcastSkillInvoke("tianyi", 3) -- 播放配音
            room:obtainCard(from, pindian.to_card)
        end
    end
}

qhfiretianyi = sgs.CreateTriggerSkill { -- 天义 触发技
    name = "qhfiretianyi",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhfiretianyiVS,
    events = { sgs.CardUsed },
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:getSkillName() == self:objectName() then
            room:broadcastSkillInvoke("tianyi", 2) -- 播放配音
            room:setPlayerMark(player, "qhfiretianyi_slash-Clear", 0)
        end
        if player:getMark("qhfiretianyi_success-Clear") == 1 and use.card:isKindOf("Slash") then
            for _, target in sgs.qlist(use.to) do
                target:addQinggangTag(use.card)
            end
        end
    end
}

--酣战
qhfirehanzhan = sgs.CreateTriggerSkill {
    name = "qhfirehanzhan",
    frequency = sgs.Skill_Frequent,
    events = { sgs.Pindian },
    on_trigger = function(self, event, player, data, room)
        local pindian = data:toPindian()
        if pindian.from:hasSkill(self:objectName()) then
            if room:askForSkillInvoke(pindian.from, self:objectName()) then
                room:drawCards(pindian.from, 1, self:objectName()) -- 摸牌
            end
        end
        if pindian.to:hasSkill(self:objectName()) then
            if room:askForSkillInvoke(pindian.to, self:objectName()) then
                room:drawCards(pindian.to, 1, self:objectName()) -- 摸牌
            end
        end
    end,
    can_trigger = function(self, target)
        return target -- 任何角色触发都能发动
    end
}

--神周瑜-业炎
qhfireyeyan = sgs.CreateTriggerSkill {
    name = "qhfireyeyan",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.GameStart, sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            room:addPlayerMark(player, "&qhfireyeyan", 5)
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                local otherPlayers = room:getOtherPlayers(player)
                local max = player:getMark("&qhfireyeyan")
                if max == 0 then
                    return false
                end
                local targets = room:askForPlayersChosen(player, otherPlayers, self:objectName(), 0, max,
                    "#qhfireyeyanPlayersChosen:" .. max) --多角色询问
                if targets:length() > 0 then
                    local msg = sgs.LogMessage()         -- 创建消息
                    msg.type = "#qhfireyeyan"
                    msg.from = player
                    msg.to = targets
                    msg.arg = self:objectName()
                    room:sendLog(msg) -- 发送消息
                    room:broadcastSkillInvoke("yeyan")
                    player:loseMark("&qhfireyeyan", targets:length())
                    for _, target in sgs.qlist(targets) do
                        local damage = sgs.DamageStruct(self:objectName(), player, target, 1, sgs.DamageStruct_Fire)
                        room:damage(damage)
                        room:setPlayerMark(target, "qhfireyeyanTarget-Clear", 1)
                    end
                end
            end
        end
    end
}

--琴音
qhfireqinyin = sgs.CreateTriggerSkill {
    name = "qhfireqinyin",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardsMoveOneTime, sgs.EventPhaseEnd },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if player:hasSkill(self:objectName()) and move.from and move.from:objectName() == player:objectName() then
                --基础原因
                if (move.reason.m_reason % 16) == sgs.CardMoveReason_S_REASON_DISCARD then
                    room:addPlayerMark(player, "&qhfireqinyin", move.card_ids:length())
                end
            end
        elseif event == sgs.EventPhaseEnd then
            for _, play in sgs.qlist(room:getAllPlayers()) do
                local num = play:getMark("&qhfireqinyin")
                room:setPlayerMark(play, "&qhfireqinyin", 0)
                if num >= 1 then
                    if not room:askForSkillInvoke(play, self:objectName()) then
                        return false
                    end
                    room:broadcastSkillInvoke("qinyin")
                    local choice = room:askForChoice(play, self:objectName(), "lose+recover", data) -- 选择
                    room:setPlayerProperty(play, "qhfireqinyin-AI", sgs.QVariant(choice))
                    local except = room:askForPlayerChosen(play, room:getAllPlayers(), self:objectName(),
                        "#qhfireqinyinPlayerChosen:" .. choice)
                    local msg = sgs.LogMessage() -- 创建消息
                    msg.type = "#qhfireqinyin"
                    msg.from = play
                    msg.to:append(except)
                    msg.arg = choice
                    room:sendLog(msg) -- 发送消息
                    for _, target in sgs.qlist(room:getAllPlayers()) do
                        if target:objectName() ~= except:objectName() then
                            if choice == "lose" then
                                room:loseHp(sgs.HpLostStruct(target, 1, self:objectName(), play))
                            elseif choice == "recover" then
                                room:recover(target, sgs.RecoverStruct(play))
                            end
                        end
                    end
                    if num >= 2 then
                        room:drawCards(player, 1, self:objectName()) -- 摸牌
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target -- 任何角色触发都能发动
    end
}

--薪火
qhfirexinhuo = sgs.CreateTriggerSkill {
    name = "qhfirexinhuo",
    frequency = sgs.Skill_Frequent,
    events = { sgs.EventPhaseEnd, sgs.CardUsed },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Draw then
                if player:isKongcheng() then
                    return false
                end
                if not room:askForSkillInvoke(player, self:objectName()) then
                    return false
                end
                local card = room:askForCardShow(player, player, self:objectName())
                room:showCard(player, card:getId())
                if card:getSuit() < 4 then              --有花色
                    room:broadcastSkillInvoke("yingzi") --播放配音
                    local suit = card:getSuitString()
                    local suitrRecord = player:getTag("qhfirexinhuo"):toString():split("+")
                    local suitStrings = table.concat(suitrRecord, "+")
                    room:setPlayerMark(player, "&qhfirexinhuo_mark+" .. suitStrings, 0)
                    if not table.contains(suitrRecord, suit) then
                        table.insert(suitrRecord, suit)
                    else
                        room:drawCards(player, 1, self:objectName()) -- 摸牌
                    end
                    if #suitrRecord == 4 then
                        player:gainMark("&qhfireyeyan", 5)
                        player:setTag("qhfirexinhuo", sgs.QVariant())
                    else
                        suitStrings = table.concat(suitrRecord, "+")
                        player:setTag("qhfirexinhuo", sgs.QVariant(suitStrings))
                        room:setPlayerMark(player, "&qhfirexinhuo_mark+" .. suitStrings, 1)
                    end
                    player:setTag("qhfirexinhuo_hit", sgs.QVariant(suit))
                    room:setPlayerMark(player, "&qhfirexinhuo_hit+" .. suit .. "-Clear", 1)
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            local suit = player:getTag("qhfirexinhuo_hit"):toString()
            if use.card:getSuitString() == suit then
                room:broadcastSkillInvoke("yingzi")           --播放配音
                local no_respond_list = use.no_respond_list
                table.insert(no_respond_list, "_ALL_TARGETS") -- 不可响应
                use.no_respond_list = no_respond_list
                data:setValue(use)
            end
        end
    end
}


-- 标准版-强化 华佗-青囊
qhstandardqingnang = sgs.CreateViewAsSkill { -- 青囊 视为技
    name = "qhstandardqingnang",
    n = 1,                                   -- 最大卡牌数
    view_filter = function(self, selected, to_select)
        if #selected == 0 and not to_select:isEquipped() then
            return true
        end -- 不是装备
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end                                          -- 一张卡牌也没选是不能发动技能的
        local acard = qhstandardqingnangCARD:clone() -- 创建技能卡
        local card = cards[1]                        -- 获得发动技能的卡牌
        local id = card:getId()                      -- 卡牌的编号
        acard:addSubcard(id)                         -- 加入技能卡
        acard:setSkillName(self:objectName())        -- 技能名称
        return acard
    end,
    enabled_at_play = function(self, player)                                                    -- 限制条件
        return player:canDiscard(player, "h") and not player:hasUsed("#qhstandardqingnangCARD") -- 没使用过技能卡
    end
}

qhstandardqingnangCARD = sgs.CreateSkillCard {          -- 青囊 技能卡
    name = "qhstandardqingnangCARD",
    target_fixed = false,                               -- 选择目标
    will_throw = true,                                  -- 立即丢弃
    filter = function(self, targets, to_select, player) -- 使用对象的约束条件
        return #targets == 0 and to_select:isWounded()  -- 没有选择目标且目标非满血
    end,
    feasible = function(self, targets)                  -- 技能卡可以使用的约束条件
        if #targets == 1 then
            return targets[1]:isWounded()
        end
        return #targets == 0 and sgs.Self:isWounded()
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1] or source
        local effect = sgs.CardEffectStruct()
        effect.card = self
        effect.from = source
        effect.to = target
        room:cardEffect(effect)
    end,
    on_effect = function(self, effect)
        local dest = effect.to
        local source = effect.from
        local room = dest:getRoom()
        local Recover = sgs.RecoverStruct() -- 定义恢复结构体
        Recover.recover = 1
        Recover.who = source
        Recover.card = self
        room:recover(dest, Recover, true)               -- 回血
        room:broadcastSkillInvoke("qingnang")           -- 播放配音
        local X = math.random(1, 3)                     -- 随机
        if X == 1 then
            if source:isWounded() then                  -- 若非满血
                local msg = sgs.LogMessage()            -- 创建消息
                msg.type = "#qhstandardqingnangRecover" -- 消息结构类型(发送的消息是什么)
                msg.from = source
                msg.arg = self:objectName()
                room:sendLog(msg)                         -- 发送消息
                room:recover(source, Recover, true)       -- 回血
            else                                          -- 满血
                local msg = sgs.LogMessage()              -- 创建消息
                msg.type = "#qhstandardqingnangDrawCards" -- 消息结构类型(发送的消息是什么)
                msg.from = source
                msg.arg = self:objectName()
                room:sendLog(msg)                            -- 发送消息
                room:drawCards(source, 1, self:objectName()) -- 摸牌
            end
        elseif X == 2 then
            local msg = sgs.LogMessage()              -- 创建消息
            msg.type = "#qhstandardqingnangDrawCards" -- 消息结构类型(发送的消息是什么)
            msg.from = dest
            msg.arg = self:objectName()
            room:sendLog(msg)                          -- 发送消息
            room:drawCards(dest, 1, self:objectName()) -- 摸牌
        elseif X == 3 then
            local msg = sgs.LogMessage()               -- 创建消息
            msg.type = "#qhstandardqingnangMark"       -- 消息结构类型(发送的消息是什么)
            msg.from = dest
            msg.arg = self:objectName()
            room:sendLog(msg)
            source:gainMark("@qhstandardrenxin", 1)
        end
    end
}

-- 急救
qhstandardjijiu = sgs.CreateViewAsSkill {
    name = "qhstandardjijiu",
    n = 1,                  -- 最大卡牌数
    response_or_use = true, -- 可以选择木牛流马上的牌
    view_filter = function(self, selected, to_select)
        if to_select:isRed() then
            return true
        end
    end,
    view_as = function(self, cards)
        if #cards == 0 then                                               -- 一张卡牌也没选是不能发动技能的
            return nil                                                    -- 直接返回，nil表示无效
        elseif #cards == 1 then                                           -- 选择了一张卡牌
            local card = cards[1]                                         -- 获得发动技能的卡牌
            local suit = card:getSuit()                                   -- 卡牌的花色
            local point = card:getNumber()                                -- 卡牌的点数
            local id = card:getId()                                       -- 卡牌的编号
            local vs_card = sgs.Sanguosha:cloneCard("peach", suit, point) -- 描述虚构桃卡牌的构成
            vs_card:addSubcard(id)                                        -- 用被选择的卡牌填充虚构卡牌
            vs_card:setSkillName(self:objectName())                       -- 创建虚构卡牌的技能名称
            return vs_card                                                -- 返回一张虚构的卡牌
        end
    end,
    enabled_at_play = function(self, player)              -- 限制条件
        return false                                      -- 不能主动使用
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        return string.find(pattern, "peach")              -- 出桃时
    end
}

-- 仁心
qhstandardrenxinVS = sgs.CreateViewAsSkill {       -- 仁心 视为技
    name = "qhstandardrenxin",
    n = 0,                                         -- 不选择卡牌
    view_as = function(self, cards)
        local fcard = qhstandardrenxinCARD:clone() -- 创建技能卡
        fcard:setSkillName(self:objectName())      -- 技能名称
        return fcard
    end,
    enabled_at_play = function(self, player)                                                           -- 限制条件
        return player:getMark("@qhstandardrenxin") > 0 and not player:hasUsed("#qhstandardrenxinCARD") -- 仁心标记大于0且没使用过技能卡
    end
}

qhstandardrenxinCARD = sgs.CreateSkillCard {            -- 仁心 技能卡
    name = "qhstandardrenxinCARD",
    target_fixed = false,                               -- 选择目标
    filter = function(self, targets, to_select, player) -- 使用对象的约束条件
        return #targets == 0 and to_select:isWounded()  -- 没有选择目标且目标非满血
    end,
    on_use = function(self, room, source, targets)
        local mark = source:getMark("@qhstandardrenxin")
        source:loseAllMarks("@qhstandardrenxin")
        local dianshu = mark / 2
        local dianshufloor = math.floor(dianshu)
        local dest = targets[1]
        if dianshufloor > 0 then
            local Recover = sgs.RecoverStruct() -- 定义恢复结构体
            Recover.recover = dianshufloor
            Recover.who = source
            Recover.card = self
            room:recover(dest, Recover, true)                -- 回血
        end
        room:broadcastSkillInvoke("jijiu")                   -- 播放配音
        if dianshu ~= dianshufloor then                      -- 不能整除
            room:drawCards(dest, 1, self:objectName())       -- 摸牌
            if dest:objectName() ~= source:objectName() then -- 不是自己
                room:drawCards(source, 1, self:objectName()) -- 摸牌
            end
        end
    end
}

qhstandardrenxin = sgs.CreateTriggerSkill { -- 仁心 触发技
    name = "qhstandardrenxin",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhstandardrenxinVS,
    events = { sgs.CardUsed },
    on_trigger = function(self, event, player, data)
        local use = data:toCardUse()
        local card = use.card
        if card and card:isKindOf("Peach") then     -- 若有使用牌且恢复牌为桃
            player:gainMark("@qhstandardrenxin", 1) -- 获得标记
        end
    end
}

-- 标准版-强化 吕布-无双
qhstandardWushuang = sgs.CreateTriggerSkill {
    name = "qhstandardWushuang",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.TargetSpecified, sgs.CardEffected, sgs.TargetConfirming, sgs.SlashEffected },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then -- 卡牌指定目标后
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and player and player:isAlive() and player:hasSkill(self:objectName()) then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke("wushuang") -- 播放配音
                local jink_list = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
                for i = 0, use.to:length() - 1, 1 do
                    -- player:speak(jink_list[i + 1])
                    if jink_list[i + 1] == 1 then
                        jink_list[i + 1] = 2 -- 2张闪
                    end
                end
                local jink_data = sgs.QVariant()
                jink_data:setValue(Table2IntList(jink_list))
                player:setTag("Jink_" .. use.card:toString(), jink_data)
            end
        end
        if event == sgs.CardEffected then
            local effect = data:toCardEffect()
            local can_invoke = false
            if effect.card:isKindOf("Duel") then
                if effect.from and effect.from:isAlive() and effect.from:hasSkill(self:objectName()) then
                    can_invoke = true
                end
                if effect.to and effect.to:isAlive() and effect.to:hasSkill(self:objectName()) then
                    can_invoke = true
                end
            end
            if not can_invoke then
                return false
            end
            if effect.card:isKindOf("Duel") then
                if room:isCanceled(effect) then
                    effect.to:setFlags("Global_NonSkillNullify")
                    return true
                end
                if effect.to:isAlive() then
                    local second = effect.from
                    local first = effect.to
                    room:setEmotion(first, "duel")
                    room:setEmotion(second, "duel")
                    room:broadcastSkillInvoke("wushuang") -- 播放配音
                    while true do                         -- 循环决斗
                        if not first:isAlive() then
                            break
                        end
                        local slash
                        if second:hasSkill(self:objectName()) or second:hasSkill("wushuang") then
                            local newprompt = ("#askForqhstandardWushuang-1:%s"):format(second:objectName())
                            slash = room:askForCard(first, "slash", newprompt, data, sgs.Card_MethodResponse, second);
                            if slash == nil then
                                break
                            end
                            local newprompt2 = ("#askForqhstandardWushuang-2:%s"):format(second:objectName())
                            slash = room:askForCard(first, "slash", newprompt2, data, sgs.Card_MethodResponse, second);
                            if slash == nil then
                                break
                            end
                        else
                            local newprompt = ("duel-slash:%s"):format(second:objectName())
                            slash = room:askForCard(first, "slash", newprompt, data, sgs.Card_MethodResponse, second)
                            if slash == nil then
                                break
                            end
                        end
                        local temp = first
                        first = second
                        second = temp
                    end
                    local damage = sgs.DamageStruct()
                    damage.card = effect.card
                    if second:isAlive() then
                        damage.from = second
                    else
                        damage.from = nil
                    end
                    damage.to = first
                    if second:objectName() ~= effect.from:objectName() then
                        damage.by_user = false
                    end
                    room:damage(damage)
                end
                room:setTag("SkipGameRule", sgs.QVariant(tonumber(event)))
            end
        end
        if event == sgs.TargetConfirming then -- 成为目标时
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") and player and player:isAlive() and
                player:hasSkill(self:objectName()) then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:setMark("qhstandardWushuang", 0)
                local dataforai = sgs.QVariant()
                dataforai:setValue(player)
                if not room:askForCard(use.from, "slash", "#qhstandardWushuang-discard", dataforai,
                        sgs.Card_MethodDiscard, player) then
                    room:broadcastSkillInvoke("wushuang") -- 播放配音
                    player:addMark("qhstandardWushuang")
                end
            end
        end
        if event == sgs.SlashEffected then -- 杀生效后
            local effect = data:toSlashEffect()
            if player:getMark("qhstandardWushuang") > 0 then
                player:removeMark("qhstandardWushuang")
                return true -- 无效
            end
        end
    end,
    can_trigger = function(self, target)
        return target -- 任何角色触发都能发动
    end
}

-- 标准版-强化 貂蝉-离间
qhstandardLijian = sgs.CreateViewAsSkill { -- 离间 视为技
    name = "qhstandardLijian",
    n = 1,                                 -- 最大卡牌数
    view_filter = function(self, selected, to_select)
        if #selected == 0 then
            return true
        end
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end                                        -- 一张卡牌也没选是不能发动技能的
        local acard = qhstandardLijianCARD:clone() -- 创建技能卡
        local card = cards[1]                      -- 获得发动技能的卡牌
        local id = card:getId()                    -- 卡牌的编号
        acard:addSubcard(id)                       -- 加入技能卡
        acard:setSkillName(self:objectName())      -- 技能名称
        return acard
    end,
    enabled_at_play = function(self, player)
        return player:canDiscard(player, "he") and not player:hasUsed("#qhstandardLijianCARD")
    end
}

qhstandardLijianCARD = sgs.CreateSkillCard { -- 离间 技能卡
    name = "qhstandardLijianCARD",
    filter = function(self, targets, to_select)
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
        duel:deleteLater()
        if #targets == 0 and to_select:isProhibited(to_select, duel) then
            return false
        elseif #targets == 1 and to_select:isCardLimited(duel, sgs.Card_MethodUse) then
            return false
        end
        return #targets < 2
    end,
    feasible = function(self, targets)
        return #targets == 2
    end,
    about_to_use = function(self, room, card_use)
        local use = card_use
        local data = sgs.QVariant()
        data:setValue(card_use)
        local thread = room:getThread()
        thread:trigger(sgs.PreCardUsed, room, card_use.from, data)
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, card_use.from:objectName(), "",
            "qhstandardLijian", "")
        room:moveCardTo(self, card_use.from, nil, sgs.Player_DiscardPile, reason, true)
        thread:trigger(sgs.CardUsed, room, card_use.from, data)
        thread:trigger(sgs.CardFinished, room, card_use.from, data)
    end,
    on_use = function(self, room, source, targets)
        local to = targets[1]
        local from = targets[2]
        local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
        duel:toTrick():setCancelable(false)         -- 这里false改为true 就是新版技能
        duel:setSkillName("_" .. self:objectName()) -- 执行 离间 的效果
        if not from:isCardLimited(duel, sgs.Card_MethodUse) and not from:isProhibited(to, duel) then
            room:broadcastSkillInvoke("lijian")     -- 播放配音
            room:useCard(sgs.CardUseStruct(duel, from, to))
        else
            duel:deleteLater()
        end
    end
}

-- 闭月
qhstandardBiyue = sgs.CreatePhaseChangeSkill {
    name = "qhstandardBiyue",
    frequency = sgs.Skill_Frequent,
    on_phasechange = function(self, player)
        if player:getPhase() == sgs.Player_Finish then
            local room = player:getRoom()
            if room:askForSkillInvoke(player, self:objectName()) then
                player:drawCards(2, self:objectName())
            end
        end
    end
}

-- 标准版-强化 华雄-耀武
qhstandardyaowu = sgs.CreateTriggerSkill {
    name = "qhstandardyaowu",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.TargetConfirming, sgs.Damage, sgs.Damaged, sgs.CardUsed },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirming then                            -- 成为目标时
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("BasicCard") then          -- 基本牌
                room:sendCompulsoryTriggerLog(player, self:objectName()) -- 发送log
                player:drawCards(1, self:objectName())
            end
        elseif event == sgs.Damage then -- 造成伤害后
            local damage = data:toDamage()
            local card = damage.card
            if card and card:isKindOf("Slash") then                      -- 杀
                room:sendCompulsoryTriggerLog(player, self:objectName()) -- 发送log
                if card:isRed() then
                    if player:isWounded() then
                        local Recover = sgs.RecoverStruct() -- 定义恢复结构体
                        Recover.recover = 1
                        Recover.who = player
                        room:recover(player, Recover, true)          -- 回血
                    else
                        room:drawCards(player, 1, self:objectName()) -- 摸牌
                    end
                elseif card:isBlack() then
                    if damage.to and damage.to:isAlive() and not damage.to:isAllNude() then
                        local id = room:askForCardChosen(player, damage.to, "hej", self:objectName())
                        room:throwCard(id, damage.to, player)
                    end
                end
            end
        elseif event == sgs.Damaged then -- 受到伤害后
            if player:getMark("&qhstandardyaowu") < 3 then
                player:gainMark("&qhstandardyaowu", 1)
            end
        elseif event == sgs.CardUsed then -- 使用牌
            local use = data:toCardUse()
            if use.card:isKindOf("Slash") and player:getMark("&qhstandardyaowu") > 0 then
                local msg = sgs.LogMessage()  -- 创建消息
                msg.type = "#qhstandardyaowu" -- 消息结构类型(发送的消息是什么)
                msg.from = player
                msg.to = use.to
                msg.arg = self:objectName()
                msg.card_str = use.card:toString()
                room:sendLog(msg) -- 发送消息
                player:loseMark("&qhstandardyaowu", 1)
                local no_respond_list = use.no_respond_list
                table.insert(no_respond_list, "_ALL_TARGETS") -- 不可响应
                use.no_respond_list = no_respond_list
                if use.m_addHistory then
                    room:addPlayerHistory(player, use.card:getClassName(), -1) --次数-1
                    use.m_addHistory = false
                end
                data:setValue(use)
            end
        end
    end
}

--标准版-强化 公孙瓒-义从
qhstandardyicong = sgs.CreateDistanceSkill { -- 距离修改技
    name = "qhstandardyicong",
    correct_func = function(self, from, to)
        local number = 0
        if from:hasSkill(self:objectName()) then
            number = number - 1
        end
        if to:hasSkill(self:objectName()) then
            number = number + 1
        end
        return number
    end
}

--趫猛
qhstandardqiaomeng = sgs.CreateTriggerSkill {
    name = "qhstandardqiaomeng",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.TargetSpecified, sgs.TargetConfirming },
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.TargetSpecified then
            if use.card:isKindOf("Slash") then
                for _, target in sgs.qlist(use.to) do
                    if target:objectName() ~= player:objectName() then
                        local playerdata = sgs.QVariant()
                        playerdata:setValue(target)
                        if room:askForSkillInvoke(player, self:objectName(), playerdata) then
                            if player:canDiscard(target, "hej") then
                                room:broadcastSkillInvoke("qiaomeng")
                                local id = room:askForCardChosen(player, target, "hej", self:objectName())
                                local card = sgs.Sanguosha:getCard(id)
                                if card:isKindOf("EquipCard") then
                                    room:obtainCard(player, id, false) -- 获得
                                else
                                    room:throwCard(id, target, player) -- 弃牌
                                    if card:isKindOf("TrickCard") then
                                        player:drawCards(1, self:objectName())
                                    elseif card:isKindOf("BasicCard") then
                                        local no_respond_list = use.no_respond_list
                                        table.insert(no_respond_list, target:objectName()) -- 不可响应
                                        use.no_respond_list = no_respond_list
                                        data:setValue(use)
                                    end
                                end
                            else
                                player:drawCards(1, self:objectName())
                            end
                        end
                    end
                end
            end
        elseif event == sgs.TargetConfirming then
            if use.card:isKindOf("Slash") then
                if use.from:objectName() ~= player:objectName() then
                    local playerdata = sgs.QVariant()
                    playerdata:setValue(use.from)
                    if room:askForSkillInvoke(player, self:objectName(), playerdata) then
                        room:broadcastSkillInvoke("qiaomeng")
                        if player:canDiscard(use.from, "hej") then
                            local id = room:askForCardChosen(player, use.from, "hej", self:objectName())
                            local card = sgs.Sanguosha:getCard(id)
                            if card:isKindOf("BasicCard") then
                                room:obtainCard(player, id, false)   -- 获得
                            else
                                room:throwCard(id, use.from, player) -- 弃牌
                                if card:isKindOf("TrickCard") then
                                    player:drawCards(1, self:objectName())
                                elseif card:isKindOf("EquipCard") then
                                    room:addPlayerMark(use.from, "&qhMaxcards_sub-SelfClear", 1)
                                end
                            end
                        else
                            player:drawCards(1, self:objectName())
                        end
                    end
                end
            end
        end
    end

}

-- 风包-强化 张角-雷击
qhwindleiji = sgs.CreateTriggerSkill {
    name = "qhwindleiji",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardUsed, sgs.CardResponded },
    on_trigger = function(self, event, player, data, room)
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if card and card:isKindOf("Jink") then -- 若有使用牌且使用牌为闪
            if player:hasFlag("qhwindguidao_using") then
                return false
            end -- 不发动
            local others = room:getOtherPlayers(player)
            local target = room:askForPlayerChosen(player, others, self:objectName(), "#qhwindleiji", true)
            if target then
                room:broadcastSkillInvoke("leiji") -- 播放配音
                local msg = sgs.LogMessage()       -- 创建消息
                msg.type = "#qhwindleijimsg"       -- 消息结构类型(发送的消息是什么)
                msg.from = player
                msg.to:append(target)
                msg.arg = self:objectName()
                room:sendLog(msg)                                -- 发送消息
                local judge = sgs.JudgeStruct()                  -- 判定结构体
                judge.who = target                               -- 判定对象
                judge.pattern = ".|black"                        -- 判定规则
                judge.good = false                               -- 判定结果符合判断规则会更有利
                judge.negative = true                            -- 对进行判定的人是否不利
                judge.reason = self:objectName()                 -- 判定原因
                room:judge(judge)                                -- 进行判定
                if judge:isGood() then                           -- 判定成功
                    room:drawCards(player, 1, self:objectName()) -- 摸牌
                else
                    if judge.card:getSuit() == sgs.Card_Spade then
                        local damage = sgs.DamageStruct()
                        damage.from = player
                        damage.to = target
                        damage.damage = 2
                        damage.nature = sgs.DamageStruct_Thunder
                        room:damage(damage) -- 造成伤害
                    else
                        if player:isWounded() then
                            local Recover = sgs.RecoverStruct() -- 定义恢复结构体
                            Recover.recover = 1
                            Recover.who = player
                            room:recover(player, Recover, true)          -- 回血
                        else
                            room:drawCards(player, 1, self:objectName()) -- 摸牌
                        end
                        local damage = sgs.DamageStruct()
                        damage.from = player
                        damage.to = target
                        damage.damage = 1
                        damage.nature = sgs.DamageStruct_Thunder
                        room:damage(damage) -- 造成伤害
                    end
                end
            end
        end
    end
}

-- 鬼道
qhwindguidao = sgs.CreateTriggerSkill {
    name = "qhwindguidao",
    frequency = sgs.Skill_Frequent,
    events = { sgs.AskForRetrial },
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        local prompt_list = { "#askforqhwindguidao", judge.who:objectName(), judge.reason, judge.card:objectName(),
            judge.card:getLogName() }
        local prompt = table.concat(prompt_list, ":")
        local card = room:askForCard(player, ".|.|.|equipped,hand", prompt, data, sgs.Card_MethodResponse, judge.who,
            true, self:objectName())
        if card then
            room:broadcastSkillInvoke("guidao")
            room:setPlayerFlag(player, "qhwindguidao_using")
            room:retrial(card, player, judge, self:objectName(), true)
            room:setPlayerFlag(player, "-qhwindguidao_using")
        end
    end,
    can_trigger = function(self, target)
        if not (target and target:isAlive() and target:hasSkill(self:objectName())) then
            return false
        end
        return not target:isNude()
    end
}

-- 鬼兵
qhwindGuibingVS = sgs.CreateViewAsSkill { -- 鬼兵 视为技
    name = "qhwindGuibing",
    n = 1,                                -- 最大卡牌数
    response_or_use = true,               -- 可以选择木牛流马上的牌
    view_filter = function(self, selected, to_select)
        if to_select:isKindOf("Jink") then
            return true
        end -- 仅闪可选
    end,
    view_as = function(self, cards)
        if #cards == 0 then                         -- 一张卡牌也没选是不能发动技能的
            return nil                              -- 直接返回，nil表示无效
        elseif #cards == 1 then                     -- 选择了一张卡牌
            local acard = qhwindGuibingCARD:clone() -- 创建技能卡
            local card = cards[1]                   -- 获得发动技能的卡牌
            local id = card:getId()                 -- 卡牌的编号
            acard:addSubcard(id)                    -- 加入技能卡
            acard:setSkillName(self:objectName())   -- 技能名称
            return acard
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#qhwindGuibingCARD")
    end
}

qhwindGuibingCARD = sgs.CreateSkillCard { -- 鬼兵 技能卡
    name = "qhwindGuibingCARD",
    target_fixed = true,                  -- 不选择目标
    will_throw = false,                   -- 不立即丢弃
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke("huangtian")
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        room:useCard(sgs.CardUseStruct(card, source, source))
        if source:getMark("@qhwindGuibing") < 2 then
            source:gainMark("@qhwindGuibing", 1)
            room:setPlayerMark(source, "qhwindGuibingused", 1)
        end
    end
}

qhwindGuibing = sgs.CreateTriggerSkill { -- 鬼兵 触发技
    name = "qhwindGuibing",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhwindGuibingVS,
    events = { sgs.DamageInflicted, sgs.EventPhaseStart }, -- 杀命中时
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if not damage.card or not damage.card:isKindOf("Slash") then return end
            if damage.to:getMark("@qhwindGuibing") > 0 then
                local msg = sgs.LogMessage()   -- 创建消息
                msg.type = "#qhwindGuibingmsg" -- 消息结构类型(发送的消息是什么)
                msg.from = damage.from
                msg.to:append(damage.to)
                msg.arg = self:objectName()
                msg.card_str = damage.card:toString()
                room:sendLog(msg) -- 发送消息
                room:broadcastSkillInvoke("guidao")
                damage.to:loseMark("@qhwindGuibing", 1)
                damage.prevented = true
                return true -- 无效
            end
        end
        if event == sgs.EventPhaseStart then
            if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
                if player:getMark("qhwindGuibingused") == 0 then
                    if room:askForSkillInvoke(player, self:objectName()) then
                        room:broadcastSkillInvoke("huangtian")
                        room:drawCards(player, 1, self:objectName()) -- 摸牌
                    end
                end
                room:setPlayerMark(player, "qhwindGuibingused", 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target -- 任何角色触发都能发动
    end
}

-- 黄天
qhwindhuangtianVS = sgs.CreateViewAsSkill {                                         -- 黄天 视为技
    name = "qhwindhuangtianvs&",                                                    -- 附加技能加 & 号
    n = 1,                                                                          -- 最大卡牌数
    response_or_use = true,                                                         -- 可以选择木牛流马上的牌
    view_filter = function(self, selected, to_select)
        if to_select:isKindOf("Jink") or to_select:getSuit() == sgs.Card_Spade then -- 闪或黑桃
            return true
        end
    end,
    view_as = function(self, cards)
        if #cards == 0 then                             -- 一张卡牌也没选是不能发动技能的
            return nil                                  -- 直接返回，nil表示无效
        elseif #cards == 1 then                         -- 选择了一张卡牌
            local acard = qhwindhuangtianVSCARD:clone() -- 创建技能卡
            local card = cards[1]                       -- 获得发动技能的卡牌
            local id = card:getId()                     -- 卡牌的编号
            acard:addSubcard(id)                        -- 加入技能卡
            acard:setSkillName(self:objectName())       -- 技能名称
            return acard
        end
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#qhwindhuangtianVSCARD")
    end
}

qhwindhuangtianVSCARD = sgs.CreateSkillCard { -- 黄天 技能卡
    name = "qhwindhuangtianVSCARD",
    target_fixed = false,                     -- 选择目标
    will_throw = false,                       -- 不立即丢弃
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        if #targets > 0 then
            return false
        end
        if to_select:hasLordSkill("qhwindhuangtian") and to_select:objectName() ~= sgs.Self:objectName() then
            return true
        end
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        if target:hasLordSkill("qhwindhuangtian") then
            room:broadcastSkillInvoke("huangtian")
            target:obtainCard(self)
            if source:getKingdom() == "qun" then
                room:drawCards(source, 1, self:objectName()) -- 摸牌
            end
        end
    end
}

qhwindhuangtian = sgs.CreateTriggerSkill { -- 黄天 触发技
    name = "qhwindhuangtian$",             -- 主公技，添加“$”符号
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.GameStart, sgs.TurnStart, sgs.EventAcquireSkill, sgs.EventLoseSkill },
    on_trigger = function(self, event, player, data, room)
        local lords = room:findPlayersBySkillName(self:objectName())
        if (event == sgs.GameStart or event == sgs.TurnStart or
                (event == sgs.EventAcquireSkill and data:toString() == "qhwindhuangtian")) then
            if lords:isEmpty() then
                return false
            end
            local players
            if (lords:length() > 1) then
                players = room:getAlivePlayers()
            else
                players = room:getOtherPlayers(lords:first())
            end
            for _, p in sgs.qlist(players) do
                if not p:hasSkill("qhwindhuangtianvs") then
                    room:attachSkillToPlayer(p, "qhwindhuangtianvs")
                end
            end
        end
        if event == sgs.EventLoseSkill and data:toString() == "qhwindhuangtian" then
            if lords:length() > 2 then
                return false
            end
            local players
            if lords:isEmpty() then
                players = room:getAlivePlayers()
            else
                players:append(lords:first())
            end
            for _, p in sgs.qlist(players) do
                if p:hasSkill("qhwindhuangtianvs") then
                    room:detachSkillFromPlayer(p, "qhwindhuangtianvs", true)
                end
            end
        end
    end
}

-- 于吉 蛊惑
qhwindguhuoCard = sgs.CreateSkillCard {
    name = "qhwindguhuoCard",
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select)
        local players = sgs.PlayerList()
        for i = 1, #targets do
            players:append(targets[i])
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card = nil
            if self:getUserString() and self:getUserString() ~= "" then
                card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
                return card and card:targetFilter(players, to_select, sgs.Self) and
                    not sgs.Self:isProhibited(to_select, card, players)
            end
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return false
        end
        local _card = sgs.Self:getTag("qhwindguhuo"):toCard()
        if _card == nil then
            return false
        end
        local card = sgs.Sanguosha:cloneCard(_card)
        card:setCanRecast(false)
        card:deleteLater()
        return card and card:targetFilter(players, to_select, sgs.Self) and
            not sgs.Self:isProhibited(to_select, card, players)
    end,
    feasible = function(self, targets)
        local players = sgs.PlayerList()
        for i = 1, #targets do
            players:append(targets[i])
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card = nil
            if self:getUserString() and self:getUserString() ~= "" then
                card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
                return card and card:targetsFeasible(players, sgs.Self)
            end
        elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
            return true
        end
        local _card = sgs.Self:getTag("qhwindguhuo"):toCard()
        if _card == nil then
            return false
        end
        local card = sgs.Sanguosha:cloneCard(_card)
        card:setCanRecast(false)
        card:deleteLater()
        return card and card:targetsFeasible(players, sgs.Self)
    end,
    on_validate = function(self, card_use)
        local yuji = card_use.from
        local room = yuji:getRoom()
        local to_guhuo = self:getUserString()
        if to_guhuo == "slash" and sgs.Sanguosha:getCurrentCardUseReason() ==
            sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local guhuo_list = {}
            table.insert(guhuo_list, "slash")
            local sts = sgs.GetConfig("BanPackages", "")
            if not string.find(sts, "maneuvering") then
                table.insert(guhuo_list, "normal_slash")
                table.insert(guhuo_list, "thunder_slash")
                table.insert(guhuo_list, "fire_slash")
            end
            to_guhuo = room:askForChoice(yuji, "guhuo_slash", table.concat(guhuo_list, "+"))
        end
        local used_cards = sgs.IntList()
        local moves = sgs.CardsMoveList()
        for _, card_id in sgs.qlist(self:getSubcards()) do
            used_cards:append(card_id)
        end
        -- room:setTag("GuhuoType", self:getUserString())
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, yuji:objectName(), "", "qhwindguhuo")
        local move = sgs.CardsMoveStruct(used_cards, yuji, nil, sgs.Player_PlaceUnknown, sgs.Player_PlaceTable, reason)
        moves:append(move)
        room:moveCardsAtomic(moves, true)
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        local user_str = ""
        if to_guhuo == "slash" then
            if card:isKindOf("Slash") then
                user_str = card:objectName()
            else
                user_str = "slash"
            end
        elseif to_guhuo == "normal_slash" then
            user_str = "slash"
        else
            user_str = to_guhuo
        end
        local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
        use_card:setSkillName("qhwindguhuo")
        use_card:addSubcard(self:getSubcards():first())
        use_card:deleteLater()
        local tos = card_use.to
        for _, to in sgs.qlist(tos) do
            local skill = room:isProhibited(yuji, to, use_card)
            if skill then
                card_use.to:removeOne(to)
            end
        end
        return use_card
    end,
    on_validate_in_response = function(self, yuji)
        local room = yuji:getRoom()
        local qhwindguhuoused = yuji:property("qhwindguhuoused"):toString():split("+") -- 获取属性
        local to_guhuo = ""
        if self:getUserString() == "peach+analeptic" then
            local guhuo_list = {}
            if not table.contains(qhwindguhuoused, "peach") then
                table.insert(guhuo_list, "peach")
            end
            if not table.contains(qhwindguhuoused, "analeptic") then
                local sts = sgs.GetConfig("BanPackages", "")
                if not string.find(sts, "maneuvering") then
                    table.insert(guhuo_list, "analeptic")
                end
                to_guhuo = room:askForChoice(yuji, "guhuo_saveself", table.concat(guhuo_list, "+"))
            end
        elseif self:getUserString() == "slash" then
            local guhuo_list = {}
            if not table.contains(qhwindguhuoused, "slash") then
                table.insert(guhuo_list, "slash")
            end
            local sts = sgs.GetConfig("BanPackages", "")
            if not string.find(sts, "maneuvering") then
                if not table.contains(qhwindguhuoused, "normal_slash") then
                    table.insert(guhuo_list, "normal_slash")
                end
                if not table.contains(qhwindguhuoused, "thunder_slash") then
                    table.insert(guhuo_list, "thunder_slash")
                end
                if not table.contains(qhwindguhuoused, "fire_slash") then
                    table.insert(guhuo_list, "fire_slash")
                end
            end
            to_guhuo = room:askForChoice(yuji, "guhuo_slash", table.concat(guhuo_list, "+"))
        else
            to_guhuo = self:getUserString()
        end
        if to_guhuo == "" then
            return nil
        end -- 无可选择项则无效
        local used_cards = sgs.IntList()
        local moves = sgs.CardsMoveList()
        for _, card_id in sgs.qlist(self:getSubcards()) do
            used_cards:append(card_id)
        end
        -- room:setTag("GuhuoType", self:getUserString())
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, yuji:objectName(), "", "qhwindguhuo")
        local move = sgs.CardsMoveStruct(used_cards, yuji, nil, sgs.Player_PlaceUnknown, sgs.Player_PlaceTable, reason)
        moves:append(move)
        room:moveCardsAtomic(moves, true)
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        local user_str = ""
        if to_guhuo == "slash" then
            if card:isKindOf("Slash") then
                user_str = card:objectName()
            else
                user_str = "slash"
            end
        elseif to_guhuo == "normal_slash" then
            user_str = "slash"
        else
            user_str = to_guhuo
        end
        local use_card = sgs.Sanguosha:cloneCard(user_str, card:getSuit(), card:getNumber())
        use_card:setSkillName("qhwindguhuo")
        use_card:addSubcard(self)
        use_card:deleteLater()
        return use_card
    end
}

qhwindguhuo = sgs.CreateOneCardViewAsSkill {
    name = "qhwindguhuo",
    filter_pattern = ".|.|.|hand",
    response_or_use = true,
    enabled_at_response = function(self, player, pattern)
        local current = false
        local players = player:getAliveSiblings()
        players:append(player)
        for _, p in sgs.qlist(players) do
            if p:getPhase() ~= sgs.Player_NotActive then
                current = true
                break
            end
        end
        if not current then
            return false
        end
        if player:isKongcheng() or string.sub(pattern, 1, 1) == "." or string.sub(pattern, 1, 1) == "@" then
            return false
        end
        if pattern == "peach" and player:getMark("Global_PreventPeach") > 0 then
            return false
        end
        if string.find(pattern, "[%u%d]") then
            return false
        end                                                                              -- 这是个极其肮脏的黑客！！ 因此我们需要去阻止基本牌模式
        local qhwindguhuoused = player:property("qhwindguhuoused"):toString():split("+") -- 获取属性
        if table.contains(qhwindguhuoused, sgs.Sanguosha:getCurrentCardUsePattern()) then
            return nil
        end
        if sgs.Sanguosha:getCurrentCardUsePattern() == "peach+analeptic" then
            if table.contains(qhwindguhuoused, "peach") and table.contains(qhwindguhuoused, "analeptic") then
                return nil
            end
        end
        return true
    end,
    enabled_at_play = function(self, player)
        if player:getMark("qhwindguhuoNum") > 3 then -- 使用次数
            return false
        end
        local current = false
        local players = player:getAliveSiblings()
        players:append(player)
        for _, p in sgs.qlist(players) do
            if p:getPhase() ~= sgs.Player_NotActive then
                current = true
                break
            end
        end
        if not current then
            return false
        end
        return not player:isKongcheng()
    end,
    view_as = function(self, cards)
        local qhwindguhuoused = sgs.Self:property("qhwindguhuoused"):toString():split("+") -- 获取属性
        -- 响应
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card = qhwindguhuoCard:clone()
            card:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
            card:addSubcard(cards)
            return card
        end
        local c = sgs.Self:getTag("qhwindguhuo"):toCard()
        if table.contains(qhwindguhuoused, c:objectName()) then -- 已使用
            return nil
        end
        if c then
            local card = qhwindguhuoCard:clone()
            -- if not string.find(c:objectName(), "slash") then
            card:setUserString(c:objectName())
            --[[else
				card:setUserString(sgs.Self:getTag("qhwindguhuoSlash"):toString())
				card:setTargetFixed(c:targetFixed() or
					sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
			end]]
            card:addSubcard(cards)
            return card
        else
            return nil
        end
    end,
    enabled_at_nullification = function(self, player)
        local current = player:getRoom():getCurrent()
        if not current or current:isDead() or current:getPhase() == sgs.Player_NotActive then
            return false
        end
        local qhwindguhuoused = player:property("qhwindguhuoused"):toString():split("+") -- 获取属性
        if table.contains(qhwindguhuoused, "nullification") then
            return nil
        end
        return not player:isKongcheng()
    end
}

qhwindguhuo:setGuhuoDialog("lr") -- 设置蛊惑框

qhwindguhuoclear = sgs.CreateTriggerSkill {
    name = "#qhwindguhuoclear",
    events = { sgs.EventPhaseChanging, sgs.CardUsed, sgs.CardResponded },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:setPlayerProperty(p, "qhwindguhuoused", sgs.QVariant()) -- 清空
                    room:setPlayerMark(p, "qhwindguhuoNum", 0)
                end
            end
        elseif event == sgs.CardUsed or event == sgs.CardResponded then
            local card
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if card and card:getSkillName() == "qhwindguhuo" then                                -- 蛊惑卡
                room:broadcastSkillInvoke("guhuo")
                local qhwindguhuoused = player:property("qhwindguhuoused"):toString():split("+") -- 获取属性
                table.insert(qhwindguhuoused, card:objectName())
                --player:speak(table.concat(qhwindguhuoused, "+"))
                room:setPlayerProperty(player, "qhwindguhuoused", sgs.QVariant(table.concat(qhwindguhuoused, "+"))) -- 设置属性
                local num = player:getMark("qhwindguhuoNum")
                room:setPlayerMark(player, "qhwindguhuoNum", num + 1)
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

--火包-强化 袁绍-乱击
qhfireluanjiVS = sgs.CreateViewAsSkill {                         -- 乱击 视为技
    name = "qhfireluanji",
    n = 2,                                                       -- 最大卡牌数
    response_or_use = true,                                      -- 可以选择木牛流马上的牌
    view_filter = function(self, selected, to_select)
        if #selected == 0 then                                   --第一张牌
            return not to_select:isEquipped()
        elseif selected[1]:getSuit() == to_select:getSuit() then --第二张牌
            return not to_select:isEquipped()
        end
    end,
    view_as = function(self, cards)
        if #cards < 2 then
            return nil                                                                             -- 直接返回，nil表示无效
        elseif #cards == 2 then                                                                    -- 选择了2张卡牌
            local vs_card = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_SuitToBeDecided, 0) -- 描述虚构卡牌的构成
            vs_card:addSubcard(cards[1])                                                           -- 用被选择的卡牌填充虚构卡牌
            vs_card:addSubcard(cards[2])
            vs_card:setSkillName(self:objectName())                                                -- 创建虚构卡牌的技能名称
            return vs_card
        end
    end,
    enabled_at_play = function(self, player)
        return true
    end
}

qhfireluanji = sgs.CreateTriggerSkill {
    name = "qhfireluanji",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhfireluanjiVS,
    events = { sgs.CardUsed },
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("SkillCard") then return false end
        if use.card:getSkillName() == self:objectName() then
            room:broadcastSkillInvoke("luanji")
        end
        if use.to:length() > 1 then
            if player:getMark("qhfireluanji_" .. use.card:objectName() .. "-Clear") == 1 then
                return false
            end
            local max = math.floor(use.to:length() / 2)
            player:setTag("qhfireluanji-AI", data)
            local targets = room:askForPlayersChosen(player, use.to, self:objectName(), 0, max,
                "#qhfireluanjiPlayersChosen:" .. max) --多角色询问
            if targets:length() > 0 then
                room:broadcastSkillInvoke("luanji")
                local msg = sgs.LogMessage() -- 创建消息
                msg.type = "#QiaoshuiRemove"
                msg.from = player
                msg.to = targets
                msg.arg = self:objectName()
                msg.card_str = use.card:toString()
                room:sendLog(msg) -- 发送消息
                for _, target in sgs.qlist(targets) do
                    use.to:removeOne(target)
                end
                data:setValue(use)
                room:setPlayerMark(player, "qhfireluanji_" .. use.card:objectName() .. "-Clear", 1)
                local num = player:getMark("qhfireluanji-Clear")
                num = math.min(4 - num, targets:length())
                room:drawCards(player, num, self:objectName())
                room:addPlayerMark(player, "qhfireluanji-Clear", num)
                room:addPlayerMark(player, "&qhfireluanji-Clear", num)
            end
        end
    end

}

--积谋
qhfirejimou = sgs.CreateTriggerSkill {
    name = "qhfirejimou",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardUsed, sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:getPhase() == sgs.Player_Play then -- 出牌阶段
                if use.card:isKindOf("TrickCard") then
                    room:setPlayerMark(player, "qhfirejimou-Clear", 1)
                end
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish then -- 结束阶段
                if player:getMark("qhfirejimou-Clear") == 0 then
                    if room:askForSkillInvoke(player, self:objectName()) then
                        room:broadcastSkillInvoke("olluanji")
                        room:drawCards(player, 2, self:objectName())
                    end
                end
            end
        end
    end
}

--血裔
qhfirexueyi = sgs.CreateMaxCardsSkill { -- 手牌上限技
    name = "qhfirexueyi$",              -- 主公技，添加“$”符号
    extra_func = function(self, target) -- 修改手牌上限
        local n = 0
        if target:hasLordSkill(self:objectName()) then
            local players = target:getAliveSiblings()
            for _, player in sgs.qlist(players) do
                if player:getKingdom() == "qun" then
                    n = n + 2
                else
                    n = n + 1
                end
            end
        end
        return n
    end
}

--颜良文丑-双雄
qhfireshuangxiongVS = sgs.CreateViewAsSkill {                                                                   -- 双雄 视为技
    name = "qhfireshuangxiong",
    n = 1,                                                                                                      -- 最大卡牌数
    response_or_use = true,                                                                                     -- 可以选择木牛流马上的牌
    view_filter = function(self, selected, to_select)
        if (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)              -- 响应
            or (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then -- 使用
            local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
            if pattern == "slash" then
                if sgs.Self:getMark("&qhfireshuangxiong_red-Clear") == 1 then
                    return to_select:isRed()
                end
                if sgs.Self:getMark("&qhfireshuangxiong_black-Clear") == 1 then
                    return to_select:isBlack()
                end
            end
        else
            return not to_select:isEquipped()
        end
    end,
    view_as = function(self, cards)
        if #cards < 1 then
            return nil          -- 直接返回，nil表示无效
        elseif #cards == 1 then -- 选择了2张卡牌
            local color
            if sgs.Self:getMark("&qhfireshuangxiong_red-Clear") == 1 then
                color = sgs.Card_Red
            elseif sgs.Self:getMark("&qhfireshuangxiong_black-Clear") == 1 then
                color = sgs.Card_Black
            end
            local card = cards[1]
            local suit = card:getSuit()    -- 卡牌的花色
            local point = card:getNumber() -- 卡牌的点数
            local vs_card
            if card:getColor() == color then
                vs_card = sgs.Sanguosha:cloneCard("slash", suit, point) --颜色相同为杀
            else
                vs_card = sgs.Sanguosha:cloneCard("duel", suit, point)  --颜色不同为决斗
            end
            vs_card:addSubcard(card)                                    -- 用被选择的卡牌填充虚构卡牌
            vs_card:setSkillName(self:objectName())                     -- 创建虚构卡牌的技能名称
            return vs_card
        end
    end,
    enabled_at_play = function(self, player)
        if player:getMark("&qhfireshuangxiong_damage-Clear") == 2 then
            return false
        end
        if player:getMark("&qhfireshuangxiong_red-Clear") == 1 then
            return true
        end
        if player:getMark("&qhfireshuangxiong_black-Clear") == 1 then
            return true
        end
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        if player:getMark("&qhfireshuangxiong_damage-Clear") == 2 then
            return false
        end
        if player:getMark("&qhfireshuangxiong_red-Clear") == 1 then
            return pattern == "slash"
        end
        if player:getMark("&qhfireshuangxiong_black-Clear") == 1 then
            return pattern == "slash"
        end
    end
}

qhfireshuangxiong = sgs.CreateTriggerSkill { -- 双雄 触发技
    name = "qhfireshuangxiong",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhfireshuangxiongVS,
    events = { sgs.EventPhaseStart, sgs.Damage },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Draw then -- 摸牌阶段
                if player:getMark("qhfirejimou-Clear") == 0 then
                    if not room:askForSkillInvoke(player, self:objectName()) then
                        return false
                    end
                    room:broadcastSkillInvoke("shuangxiong")
                    local judge = sgs.JudgeStruct()  -- 判定结构体
                    judge.who = player               -- 判定对象
                    judge.pattern = "."              -- 判定规则
                    judge.good = true                -- 判定结果符合判断规则会更有利
                    judge.negative = false           -- 对进行判定的人是否不利
                    judge.reason = self:objectName() -- 判定原因
                    room:judge(judge)                -- 进行判定
                    if judge.card:isRed() then
                        room:setPlayerMark(player, "&qhfireshuangxiong_red-Clear", 1)
                    end
                    if judge.card:isBlack() then
                        room:setPlayerMark(player, "&qhfireshuangxiong_black-Clear", 1)
                    end
                    player:obtainCard(judge.card)
                end
            end
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:getSkillName() == self:objectName() then
                room:addPlayerMark(player, "&qhfireshuangxiong_damage-Clear", 1)
            end
        end
    end
}

--庞德-猛进
qhfiremengjin = sgs.CreateTriggerSkill {
    name = "qhfiremengjin",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.TargetSpecified },
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        for _, target in sgs.qlist(use.to) do
            if target:objectName() ~= player:objectName() then
                local playerdata = sgs.QVariant()
                playerdata:setValue(target)
                if target:canDiscard(target, "hej") then
                    player:setTag("qhfiremengjin-AI", data)
                    if use.card:isKindOf("Slash") then
                        if player:getMark("qhfiremengjin_slash-Clear") < 2 then
                            if room:askForSkillInvoke(player, self:objectName(), playerdata) then
                                room:broadcastSkillInvoke("mengjin")
                                local id = room:askForCardChosen(player, target, "hej", self:objectName())
                                room:obtainCard(player, id, false) -- 获得
                                room:addPlayerMark(player, "qhfiremengjin_slash-Clear", 1)
                            end
                        end
                    elseif use.card:isKindOf("TrickCard") then
                        if player:getMark("qhfiremengjin_trick-Clear") < 2 then
                            if room:askForSkillInvoke(player, self:objectName(), playerdata) then
                                room:broadcastSkillInvoke("mengjin")
                                local id = room:askForCardChosen(player, target, "hej", self:objectName(), false,
                                    sgs.Card_MethodDiscard)
                                room:throwCard(id, target, player) -- 弃牌
                                room:addPlayerMark(player, "qhfiremengjin_trick-Clear", 1)
                            end
                        end
                    end
                end
            end
        end
    end
}

--神诸葛亮-狂风
qhfirekuangfengCARD = sgs.CreateSkillCard { -- 狂风 技能卡
    name = "qhfirekuangfengCARD",
    target_fixed = false,                   -- 选择目标
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select, player) -- 使用对象的约束条件
        return #targets == 0
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:broadcastSkillInvoke("kuangfeng")
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "qhfirekuangfeng", "")
        room:throwCard(self, reason, nil)
        if effect.to:getMark("&qhfirekuangfeng") == 0 then
            effect.to:gainMark("&qhfirekuangfeng")
            effect.to:setTag("qhfirekuangfeng", sgs.QVariant(effect.from:objectName() .. "+2"))
        else
            local damage = sgs.DamageStruct("qhfirekuangfeng", effect.from, effect.to, 1, sgs.DamageStruct_Fire)
            room:damage(damage)
        end
    end
}

qhfirekuangfengVS = sgs.CreateViewAsSkill { -- 狂风 视为技
    name = "qhfirekuangfeng",
    n = 1,                                  -- 最大卡牌数
    expand_pile = "stars",                  --扩展牌堆
    view_filter = function(self, selected, to_select)
        --在牌堆里
        return sgs.Self:getPile("stars"):contains(to_select:getEffectiveId())
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local acard = qhfirekuangfengCARD:clone() -- 创建技能卡
        local id = cards[1]:getId()               -- 卡牌的编号
        acard:addSubcard(id)                      -- 加入技能卡
        return acard
    end,
    enabled_at_play = function(self, player)              -- 主动使用
        return false                                      -- 不能
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        return pattern == "@@qhfirekuangfeng"
    end
}

qhfirekuangfeng = sgs.CreateTriggerSkill { -- 狂风 触发技
    name = "qhfirekuangfeng",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhfirekuangfengVS,
    events = { sgs.EventPhaseStart, sgs.DamageForseen, sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start then
                if player:getPile("stars"):length() > 0 then
                    room:askForUseCard(player, "@@qhfirekuangfeng", "#askforqhfirekuangfeng", -1, sgs.Card_MethodNone)
                end
            end
        elseif event == sgs.DamageForseen then
            local damage = data:toDamage()
            if damage.to:getMark("&qhfirekuangfeng") > 0 then
                if damage.nature ~= sgs.DamageStruct_Normal then
                    room:broadcastSkillInvoke("kuangfeng")
                    local msg = sgs.LogMessage()
                    msg.type = "#qhfirekuangfeng"
                    msg.from = player
                    msg.arg = damage.damage
                    msg.arg2 = damage.damage + 1
                    room:sendLog(msg)
                    damage.damage = damage.damage + 1
                    data:setValue(damage)
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if player:hasSkill(self:objectName()) and change.to == sgs.Player_NotActive then
                for _, target in sgs.qlist(room:getAllPlayers()) do
                    if target:getMark("&qhfirekuangfeng") > 0 then
                        local from = target:getTag("qhfirekuangfeng"):toString():split("+")
                        if player:objectName() == from[1] then
                            if from[2] == "2" then
                                target:setTag("qhfirekuangfeng", sgs.QVariant(player:objectName() .. "+1"))
                            end
                            if from[2] == "1" then
                                target:loseAllMarks("&qhfirekuangfeng")
                            end
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

--大雾
qhfiredawuCARD = sgs.CreateSkillCard { -- 大雾 技能卡
    name = "qhfiredawuCARD",
    target_fixed = false,              -- 选择目标
    will_throw = false,
    handling_method = sgs.Card_MethodNone,
    filter = function(self, targets, to_select, player) -- 使用对象的约束条件
        return #targets < self:subcardsLength()
    end,
    feasible = function(self, targets) -- 技能卡可以使用的约束条件
        return #targets == self:subcardsLength()
    end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        room:broadcastSkillInvoke("dawu")
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "qhfiredawu", "")
        room:throwCard(self, reason, nil)
        room:recover(effect.to, sgs.RecoverStruct(effect.from))
        effect.to:gainMark("&qhfiredawu")
        effect.to:setTag("qhfiredawu", sgs.QVariant(effect.from:objectName()))
    end
}

qhfiredawuVS = sgs.CreateViewAsSkill { -- 大雾 视为技
    name = "qhfiredawu",
    n = 10,                            -- 最大卡牌数
    expand_pile = "stars",             --扩展牌堆
    view_filter = function(self, selected, to_select)
        --在牌堆里
        return sgs.Self:getPile("stars"):contains(to_select:getEffectiveId())
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local acard = qhfiredawuCARD:clone() -- 创建技能卡
        for _, card in ipairs(cards) do      -- 扫描卡牌名单
            local id = card:getId()          -- 卡牌的编号
            acard:addSubcard(id)             -- 加入技能卡
        end
        return acard
    end,
    enabled_at_play = function(self, player)              -- 主动使用
        return false                                      -- 不能
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        return pattern == "@@qhfiredawu"
    end
}

qhfiredawu = sgs.CreateTriggerSkill { -- 大雾 触发技
    name = "qhfiredawu",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = qhfiredawuVS,
    events = { sgs.EventPhaseStart, sgs.DamageForseen, sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
                if player:getPile("stars"):length() > 0 then
                    room:askForUseCard(player, "@@qhfiredawu", "#askforqhfiredawu", -1, sgs.Card_MethodNone)
                end
            end
        elseif event == sgs.DamageForseen then
            local damage = data:toDamage()
            if damage.to:getMark("&qhfiredawu") > 0 then
                if damage.nature ~= sgs.DamageStruct_Thunder then
                    room:broadcastSkillInvoke("dawu")
                    local msg = sgs.LogMessage()
                    msg.type = "#qhfiredawu"
                    msg.from = player
                    room:sendLog(msg)
                    return true
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if player:hasSkill(self:objectName()) and change.from == sgs.Player_NotActive then
                for _, target in sgs.qlist(room:getAllPlayers()) do
                    if target:getMark("&qhfiredawu") > 0 then
                        local from = target:getTag("qhfiredawu"):toString()
                        if player:objectName() == from then
                            target:loseAllMarks("&qhfiredawu")
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

--禳星
qhfirerangxing = sgs.CreateTriggerSkill {
    name = "qhfirerangxing",
    frequency = sgs.Skill_Frequent,
    events = { sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Judge then
            if not room:askForSkillInvoke(player, self:objectName(), data) then
                return false
            end
            room:broadcastSkillInvoke("guanxing")
            local cards = room:getNCards(1)
            local card = sgs.Sanguosha:getCard(cards:first())
            player:obtainCard(card)
            room:showCard(player, cards)
            if card:getNumber() < 7 then
                cards = room:getNCards(1)
                player:addToPile("stars", cards)
            end
            if card:getNumber() == 7 then
                cards = room:getNCards(3)
                player:addToPile("stars", cards)
                local num = player:getHandcardNum()
                if num < 7 then
                    player:drawCards(7 - num, self:objectName())
                end
            end
        end
    end
}

----------------神话降临----------------

-- 神话降临 黄月英--集智
mythjizhi = sgs.CreateTriggerSkill {
    name = "mythjizhi",
    frequency = sgs.Skill_Frequent,
    events = { sgs.GameStart },
    priority = 2,
    on_trigger = function(self, event, player, data, room)
        room:setPlayerProperty(player, "mythjizhi", sgs.QVariant(1))
    end
}

globaljizhi = sgs.CreateTriggerSkill {
    name = "globaljizhi",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardUsed, sgs.CardFinished },
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if player:hasFlag("mythjizhi_using") then
                return false
            end                                    -- 不发动
            if use.card:isNDTrick() and room:askForSkillInvoke(player, "mythjizhi") then
                room:broadcastSkillInvoke("jizhi") -- 播放配音
                room:drawCards(player, 1, "mythjizhi")
            end
        end
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if player:hasFlag("mythjizhi_using") then
                return false
            end -- 不发动
            if not use.to:isEmpty() and use.to:at(0):isDead() then
                return false
            end -- 不能对已死亡的角色使用
            if use.card:isKindOf("GodNihilo") then
                return false
            end -- 不能使用撒豆成兵
            if use.card:isKindOf("Nullification") then
                return false
            end -- 不能使用无懈可击
            if use.card:isKindOf("Collateral") then
                return false
            end -- 不能使用借刀杀人
            if use.card:isKindOf("IronChain") then
                return false
            end -- 不能使用铁索连环
            if use.card:isKindOf("GodFlower") and use.to and use.to:at(0):isNude() then
                return false
            end -- 不能对没牌的角色使用移花接木
            if (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement")) and use.to and
                use.to:at(0):getCards("hej"):isEmpty() then
                return false
            end                          -- 不能对没牌的角色使用顺手牵羊和过河拆桥
            if use.card:isNDTrick() then -- 如果是非延时类锦囊
                if not room:askForSkillInvoke(player, "qhstandardjizhi2", data) then
                    return false
                end                                           -- 询问是否发动技能
                room:setPlayerFlag(player, "mythjizhi_using") -- 获得标志
                local newuse = sgs.CardUseStruct()            -- 卡牌使用结构体
                newuse.from = use.from                        -- 原使用者
                for _, dest in sgs.qlist(use.to) do           -- 对名单中的所有角色进行扫描
                    if dest:isAlive() then                    -- 如果存活
                        newuse.to:append(dest)                -- 加入名单
                    end
                end
                newuse.card = use.card                         -- 原卡牌
                room:broadcastSkillInvoke("jizhi")             -- 播放配音
                room:useCard(newuse)                           -- 使用卡
                room:setPlayerFlag(player, "-mythjizhi_using") -- 失去标志
            end
        end
    end,
    can_trigger = function(self, target)
        if target:property("mythjizhi"):toInt() == 1 then
            return true
        end
    end
}

-- 奇才
mythqicai = sgs.CreateTriggerSkill {
    name = "mythqicai",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.EventPhaseStart, sgs.EventPhaseChanging, sgs.EventPhaseEnd },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then -- 出牌阶段
                local x = 0                              -- 计数
                for _, did in sgs.qlist(room:getDrawPile()) do
                    local dcard = sgs.Sanguosha:getCard(did)
                    if dcard:isNDTrick() and not dcard:isKindOf("Nullification") then
                        x = x + 1
                    end
                    if x >= 4 then
                        break
                    end
                end
                if x < 4 then
                    room:swapPile() -- 洗牌
                end
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:broadcastSkillInvoke("tenyearjizhi")                                    -- 播放配音
                local drawPile = room:getDrawPile()
                local num = drawPile:length()                                                -- 获取摸牌堆牌数
                x = 0                                                                        -- 计数
                local ids = {}
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)           -- 虚拟卡
                for i = 0, num do
                    local card = sgs.Sanguosha:getCard(drawPile:at(math.random(0, num - 1))) -- 获得牌
                    if card:isNDTrick() and not card:isKindOf("Nullification") and not table.contains(ids, card:getId()) then
                        dummy:addSubcard(card)
                        table.insert(ids, card:getId())
                        x = x + 1
                        if x == 2 then
                            break
                        end
                    end
                end
                player:obtainCard(dummy, false)
                dummy:deleteLater()
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()     -- 获得阶段交替结构体
            local lastphase = change.from           -- 刚结束的回合阶段
            if lastphase == sgs.Player_Start then   -- 如果是准备阶段
                local msg = sgs.LogMessage()        -- 创建消息
                msg.type = "#mythqicai"             -- 消息结构类型(发送的消息是什么)
                msg.from = player                   -- 行为发起对象
                msg.arg = self:objectName()         -- 参数1
                room:sendLog(msg)                   -- 发送消息
                change.to = sgs.Player_Play         -- 把将进入的改成出牌阶段
                data:setValue(change)               -- 更新阶段交替结构体
                player:insertPhase(sgs.Player_Play) -- 插入额外的出牌阶段
                player:setFlags("mythqicai_phase")
            end
        elseif event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Play then -- 出牌阶段
                if player:hasFlag("mythqicai_phase") then
                    player:setFlags("-mythqicai_phase")
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) -- 虚拟卡
                    local handcards = player:handCards()
                    if handcards:length() > 0 then
                        room:sendCompulsoryTriggerLog(player, self:objectName())
                        dummy:addSubcards(handcards)
                        room:throwCard(dummy, player, player) -- 弃牌
                        player:drawCards(handcards:length(), self:objectName())
                    end
                    dummy:deleteLater()
                end
            end
        end
    end
}

-- 机巧
mythjiqiaoCard = sgs.CreateSkillCard {
    name = "mythjiqiaoCard",
    target_fixed = false,
    filter = function(self, targets, to_select)
        local card = sgs.Self:getTag("mythjiqiao"):toCard()
        if not card then
            return false
        end

        local new_targets = sgs.PlayerList()
        for _, p in ipairs(targets) do
            new_targets:append(p)
        end

        local _card = sgs.Sanguosha:cloneCard(card:objectName())
        _card:setCanRecast(false)
        _card:setSkillName("mythjiqiao")
        _card:deleteLater()

        if _card and _card:targetFixed() then -- 因源码bug，不得已而为之
            return #targets == 0 and to_select:objectName() == sgs.Self:objectName() and
                not sgs.Self:isProhibited(to_select, _card, new_targets)
        end
        return _card and _card:targetFilter(new_targets, to_select, sgs.Self) and
            not sgs.Self:isProhibited(to_select, _card, new_targets)
    end,
    feasible = function(self, targets)
        local card = sgs.Self:getTag("mythjiqiao"):toCard()
        if not card then
            return false
        end

        local new_targets = sgs.PlayerList()
        for _, p in ipairs(targets) do
            new_targets:append(p)
        end

        local _card = sgs.Sanguosha:cloneCard(card:objectName())
        _card:setCanRecast(false)
        _card:setSkillName("mythjiqiao")
        _card:deleteLater()
        return _card and _card:targetsFeasible(new_targets, sgs.Self)
    end,
    on_validate = function(self, card_use)
        local user_string = self:getUserString()
        local use_card = sgs.Sanguosha:cloneCard(user_string)
        if not use_card then
            return nil
        end
        use_card:setSkillName("mythjiqiao")
        use_card:deleteLater()
        return use_card
    end
}

mythjiqiaoVS = sgs.CreateViewAsSkill {
    name = "mythjiqiao",
    n = 1,                  -- 最大卡牌数
    response_or_use = true, -- 可以选择木牛流马上的牌
    response_pattern = "nullification",
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then -- 出牌阶段
            return false
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            if to_select:isKindOf("TrickCard") then return true end
        end
        return false
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then -- 出牌阶段
            local _card = sgs.Self:getTag("mythjiqiao"):toCard()
            if _card and _card:isAvailable(sgs.Self) then
                local c = mythjiqiaoCard:clone()
                c:setUserString(_card:objectName())
                return c
            end
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            if #cards == 0 then
                return nil
            elseif #cards == 1 then
                local card = cards[1]
                local ncard = sgs.Sanguosha:cloneCard("nullification", card:getSuit(), card:getNumber())
                ncard:addSubcard(card)
                ncard:setSkillName(self:objectName())
                return ncard
            end
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#mythjiqiaoCard")
    end,
    enabled_at_nullification = function(self, player) --响应无懈
        for _, card in sgs.qlist(player:getHandcards()) do
            if card:isKindOf("TrickCard") then return true end
        end
        return false
    end
}

mythjiqiao = sgs.CreateTriggerSkill {
    name = "mythjiqiao",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = mythjiqiaoVS,
    guhuo_type = "r",
    events = { sgs.CardUsed },
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("TrickCard") then
            local no_offset_list = use.no_offset_list
            table.insert(no_offset_list, "_ALL_TARGETS") -- 不可抵消
            use.no_offset_list = no_offset_list
            data:setValue(use)
        end
    end
}

--玲珑
mythlinglong = sgs.CreateTriggerSkill {
    name = "mythlinglong",
    frequency = sgs.Skill_Frequent,
    events = { sgs.GameStart },
    priority = 2,
    on_trigger = function(self, event, player, data, room)
        local cards = room:getNCards(7)
        room:broadcastSkillInvoke("linglong")    -- 播放配音
        player:addToPile("&mythlinglong", cards) --木牛流马型
        room:setPlayerProperty(player, "mythlinglong", sgs.QVariant(1))
    end
}

globallinglong = sgs.CreateTriggerSkill {
    name = "globallinglong",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardsMoveOneTime, sgs.TargetConfirming },
    priority = 1,
    global = true,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            if player:getPhase() == sgs.Player_Discard then
                local move = data:toMoveOneTime()
                if move.reason.m_reason == sgs.CardMoveReason_S_REASON_RULEDISCARD then
                    local num = math.ceil(move.card_ids:length() / 2)
                    room:sendCompulsoryTriggerLog(player, "linglong")
                    room:broadcastSkillInvoke("linglong") -- 播放配音
                    local pile = player:getPile("&mythlinglong")
                    if pile:length() > 0 then
                        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) -- 虚拟卡
                        dummy:addSubcards(pile)
                        room:throwCard(dummy, player, nil)
                        dummy:deleteLater()
                    end
                    local cards = room:getNCards(num)
                    player:addToPile("&mythlinglong", cards) --木牛流马型
                    local otherPlayers = room:getOtherPlayers(player)
                    local playerlist = sgs.SPlayerList()
                    for _, dest in sgs.qlist(otherPlayers) do -- 对名单中的所有角色进行扫描
                        if not dest:isAllNude() then          -- 有牌
                            playerlist:append(dest)           -- 加入名单
                        end
                    end
                    if playerlist:length() == 0 then
                        return false
                    end -- 如果都没手牌则结束
                    prompt = ("#mythlinglongPlayerChosen:%d"):format(num)
                    local play = room:askForPlayerChosen(player, playerlist, "mythlinglong",
                        prompt, true)
                    if play then
                        local ids = sgs.IntList()
                        local places = sgs.PlaceList()
                        play:setFlags("qh_InTempMoving")
                        for i = 1, num, 1 do
                            if not player:canDiscard(play, "he") then return false end
                            local Card = room:askForCardChosen(player, play, "he", self:objectName(), false,
                                sgs.Card_MethodDiscard, sgs.IntList(), i ~= 1)
                            if Card < 0 then
                                break
                            end
                            ids:append(Card)
                            places:append(room:getCardPlace(Card))
                            play:addToPile("#mythlinglong", Card, false)
                        end
                        for i = 0, ids:length() - 1, 1 do
                            room:moveCardTo(sgs.Sanguosha:getCard(ids:at(i)), play, places:at(i), false)
                        end
                        play:setFlags("-qh_InTempMoving")
                        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) -- 虚拟卡
                        dummy:deleteLater()
                        dummy:addSubcards(ids)
                        room:throwCard(dummy, play, player)
                    end
                end
            end
        elseif event == sgs.TargetConfirming then
            local use = data:toCardUse()
            if use.from:objectName() == player:objectName() then return false end
            if use.card:isKindOf("SkillCard") then return false end
            if room:askForSkillInvoke(player, "mythlinglong") then
                room:broadcastSkillInvoke("linglong") -- 播放配音
                room:drawCards(player, 1, "mythlinglong")
                local card = room:askForUseCard(player, "TrickCard+^Nullification", "#mythlinglong", -1,
                    sgs.Card_MethodUse)
                if not card then
                    room:drawCards(player, 1, "mythlinglong")
                end
            end
        end
    end,
    can_trigger = function(self, target)
        if target:property("mythlinglong"):toInt() == 1 then
            return true
        end
    end
}

--乐蔡文姬-霜笳
mythshuangjia = sgs.CreateTriggerSkill {
    name = "mythshuangjia",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.GameStart, sgs.EventPhaseChanging, sgs.CardsMoveOneTime },
    priority = 2,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart or event == sgs.EventPhaseChanging then
            local trigger = false
            if event == sgs.GameStart then
                trigger = true
                room:setPlayerMark(player, "&mythshuangjia_count", 3)
            end
            if event == sgs.EventPhaseChanging then
                local change = data:toPhaseChange()
                if change.from == sgs.Player_NotActive then
                    local count = player:getMark("&mythshuangjia_count")
                    count = count - 1
                    if count == 0 then
                        trigger = true
                        room:setPlayerMark(player, "&mythshuangjia_count", 2)
                        local hands = player:getHandcards()
                        for i = 0, hands:length() - 1, 1 do
                            local card = hands:at(i)
                            if card:hasFlag("mythhujia") then
                                card:setFlags("-mythhujia")
                                room:setCardTip(card:getId(), "-mythhujia")
                            end
                        end
                    else
                        room:setPlayerMark(player, "&mythshuangjia_count", count)
                    end
                end
            end
            if trigger then
                local card_ids = room:getNCards(8)
                local cards = sgs.IntList()
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:fillAG(card_ids)                                                                         -- 填充AG 仅自己可见(冲突)
                for i = 1, 4, 1 do
                    local ag_id = room:askForAG(player, card_ids, false, self:objectName(), "#mythshuangjia") -- 询问AG
                    if ag_id then
                        card_ids:removeOne(ag_id)
                        cards:append(ag_id)
                        room:takeAG(player, ag_id, false) -- AG显示被选择
                    end
                end
                room:clearAG()
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) -- 虚拟卡
                dummy:deleteLater()
                dummy:addSubcards(cards)
                player:obtainCard(dummy, false)
                room:setPlayerProperty(player, "mythhujia", sgs.QVariant(4))
                for i = 0, 3, 1 do
                    local card = cards:at(i)
                    room:setCardTip(card, "mythhujia") --卡牌显示文字
                    sgs.Sanguosha:getCard(card):setFlags("mythhujia")
                end
                dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) -- 虚拟卡
                dummy:deleteLater()
                dummy:addSubcards(card_ids)
                MoveReason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(),
                    self:objectName(), nil)
                room:throwCard(dummy, MoveReason, player) -- 弃牌
            end
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.from == sgs.Player_NotActive then
                local hands = player:getHandcards()
                for i = 0, hands:length() - 1, 1 do
                    local card = hands:at(i)
                    if card:hasFlag("mythhujia") then
                        room:ignoreCards(player, card) --不计入手牌上限
                    end
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() then
                local hands = player:getHandcards()
                local num = 0
                for i = 0, hands:length() - 1, 1 do
                    local card = hands:at(i)
                    if card:hasFlag("mythhujia") then
                        num = num + 1
                    end
                end
                room:setPlayerProperty(player, "mythhujia", sgs.QVariant(num))
            end
        end
    end
}

--悲愤
mythbeifen = sgs.CreateTriggerSkill {
    name = "mythbeifen",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.CardsMoveOneTime, sgs.EventPhaseChanging },
    priority = 2,
    on_trigger = function(self, event, player, data, room)
        local trigger = false
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) then
                for i = 0, move.card_ids:length() - 1, 1 do
                    if move.from_places:at(i) == sgs.Player_PlaceHand then --手牌
                        local card = sgs.Sanguosha:getCard(move.card_ids:at(i))
                        if card:hasFlag("mythhujia") then
                            card:setFlags("-mythhujia") --清楚胡笳
                            if room:getDrawPile():length() < 15 then
                                room:swapPile()         -- 洗牌
                            end
                            room:sendCompulsoryTriggerLog(player, self:objectName())
                            local drawPile = room:getDrawPile()                                -- 获取摸牌堆牌数
                            local suits = {}
                            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) -- 虚拟卡
                            for i = 0, drawPile:length() do
                                local acard = sgs.Sanguosha:getCard(drawPile:at(i))
                                if not table.contains(suits, acard:getSuit()) then --判断花色
                                    dummy:addSubcard(acard)
                                    table.insert(suits, acard:getSuit())
                                    if #suits == 4 then
                                        break
                                    end
                                end
                            end
                            player:obtainCard(dummy, false)
                            dummy:deleteLater()
                        end
                    end
                end
            end
            if move.from and move.from:objectName() == player:objectName() or
                move.to and move.to:objectName() == player:objectName() then
                trigger = true
            end
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.from == sgs.Player_NotActive then
                trigger = true
            end
        end
        if trigger then
            local hands = player:getHandcards()
            local num = 0
            for i = 0, hands:length() - 1, 1 do
                local card = hands:at(i)
                if card:hasFlag("mythhujia") then
                    num = num + 1
                else
                    num = num - 1
                end
            end
            --player:speak(num)
            if num < 0 then
                room:setPlayerProperty(player, "mythbeifen", sgs.QVariant(1))
            else
                room:setPlayerProperty(player, "mythbeifen", sgs.QVariant(0))
            end
        end
    end
}

--滕公主-幸宠
mythxingchong = sgs.CreateTriggerSkill {
    name = "mythxingchong",
    frequency = sgs.Skill_Frequent,
    events = { sgs.RoundStart, sgs.CardsMoveOneTime },
    priority = 1,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.RoundStart then            --每轮开始时
            if not room:askForSkillInvoke(player, self:objectName()) then return false end
            room:broadcastSkillInvoke("xingchong") -- 播放配音
            local maxhp = player:getMaxHp()
            room:drawCards(player, maxhp, self:objectName())
            local prompt = ("#mythxingchong:%d"):format(maxhp)
            local card = room:askForExchange(player, self:objectName(), maxhp, 1, false, prompt, true)
            if not card then return false end
            local subcards = card:getSubcards()
            for _, subcard in sgs.qlist(subcards) do
                room:setPlayerMark(player, "mythxingchong_" .. subcard .. "_lun", 1)
                room:setCardTip(subcard, "mythxingchong_lun") --卡牌显示文字 每轮清除
            end
            room:showCard(player, subcards)
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.from and move.from:objectName() == player:objectName() then
                if move.from_places:contains(sgs.Player_PlaceHand) then
                    local num = 0
                    for i = 0, move.card_ids:length() - 1, 1 do
                        if move.from_places:at(i) == sgs.Player_PlaceHand then --手牌
                            local id = move.card_ids:at(i)
                            if player:getMark("mythxingchong_" .. id .. "_lun") == 1 then
                                room:setPlayerMark(player, "mythxingchong_" .. id .. "_lun", 0)
                                num = num + 1
                            end
                        end
                    end
                    if num > 0 then
                        room:broadcastSkillInvoke("xingchong") -- 播放配音
                        room:sendCompulsoryTriggerLog(player, self:objectName())
                        player:drawCards(num * 2, self:objectName())
                    end
                end
            end
        end
    end
}

--流年
mythliunian = sgs.CreateTriggerSkill {
    name = "mythliunian",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.GameStart, sgs.EventPhaseChanging, sgs.RoundStart },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            if player:getState() ~= "robot" then                    --非机器人
                if sgs.GetConfig("EnableCheat", false) == true then --启用作弊
                    local choice = room:askForChoice(player, self:objectName(), "no+yes", data, nil, "#mythliunian_cheat")
                    if choice == "yes" then
                        player:speak("启用完全体流年")
                        room:setPlayerMark(player, "mythliunian_cheat", 1)
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                local times = room:getTag("SwapPile"):toInt() --洗牌数
                local usedTimes = player:getMark("&mythliunian_usedTimes")
                local cheat = player:getMark("mythliunian_cheat")
                if usedTimes == 0 and (times >= 1 or cheat == 1) then
                    room:broadcastSkillInvoke("liunian") -- 播放配音
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:setPlayerMark(player, "&mythliunian_usedTimes", 1)
                    room:gainMaxHp(player, 2, self:objectName());
                    local Recover = sgs.RecoverStruct() -- 定义恢复结构体
                    Recover.recover = 2
                    Recover.who = player
                    room:recover(player, Recover, true)  -- 回血
                elseif usedTimes == 1 and (times >= 2 or cheat == 1) then
                    room:broadcastSkillInvoke("liunian") -- 播放配音
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:setPlayerMark(player, "&mythliunian_usedTimes", 2)
                    room:gainMaxHp(player, 1, self:objectName());
                    local Recover = sgs.RecoverStruct() -- 定义恢复结构体
                    Recover.recover = 2
                    Recover.who = player
                    room:recover(player, Recover, true) -- 回血
                end
            end
        elseif event == sgs.RoundStart then
            local usedTimes = player:getMark("&mythliunian_usedTimes")
            if player:getLostHp() >= usedTimes * 2 then
                room:broadcastSkillInvoke("liunian") -- 播放配音
                room:sendCompulsoryTriggerLog(player, self:objectName())
                if player:isWounded() then
                    local Recover = sgs.RecoverStruct() -- 定义恢复结构体
                    Recover.recover = 1
                    Recover.who = player
                    room:recover(player, Recover, true) -- 回血
                else
                    player:gainHujia(1, 5)              --获得护甲
                end
            end
        end
    end
}

--滕芳兰-落宠
mythluochong = sgs.CreateTriggerSkill {
    name = "mythluochong",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseStart, sgs.Damaged, sgs.HpLost, sgs.RoundStart },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            local phase = player:getPhase()
            if phase == sgs.Player_Start then
                for _, play in sgs.qlist(room:getOtherPlayers(player)) do
                    if play:hasSkill(self:objectName()) and play:property("mythluochong_target"):toString() == player:objectName() then
                        if not play:canDiscard(player, "he") then break end
                        room:broadcastSkillInvoke("luochong") -- 播放配音
                        room:sendCompulsoryTriggerLog(play, self:objectName())
                        local ids = sgs.IntList()
                        local places = sgs.PlaceList()
                        player:setFlags("qh_InTempMoving")
                        for j = 1, 4, 1 do
                            if not play:canDiscard(player, "he") then break end
                            local Card = room:askForCardChosen(play, player, "he", self:objectName(), false,
                                sgs.Card_MethodDiscard, sgs.IntList(), j ~= 1)
                            if Card < 0 then
                                break
                            end
                            ids:append(Card)
                            places:append(room:getCardPlace(Card))
                            player:addToPile("#mythluochong", Card, false)
                        end
                        for j = 0, ids:length() - 1, 1 do
                            room:moveCardTo(sgs.Sanguosha:getCard(ids:at(j)), player, places:at(j), false)
                        end
                        player:setFlags("-qh_InTempMoving")
                        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) -- 虚拟卡
                        dummy:deleteLater()
                        dummy:addSubcards(ids)
                        room:throwCard(dummy, player, play)
                    end
                end
            end
        end
        if event == sgs.EventPhaseStart or event == sgs.Damaged or event == sgs.HpLost then
            if player:hasSkill(self:objectName()) then
                local times = 1
                if event == sgs.EventPhaseStart then
                    local phase = player:getPhase()
                    if phase ~= sgs.Player_Start and phase ~= sgs.Player_Finish then return false end
                end
                if event == sgs.Damaged then
                    local damage = data:toDamage()
                    times = damage.damage
                end
                if event == sgs.HpLost then
                    local hpLost = data:toHpLost()
                    times = hpLost.lose
                end
                for i = 1, times, 1 do
                    local chosen = player:property("SkillDescriptionRecord_mythluochong"):toString():split("+") --描述记录
                    if #chosen == 4 then
                        chosen = {}
                    end
                    local choices = {}
                    if not table.contains(chosen, "mythluochong:recover") then
                        for _, play in sgs.qlist(room:getAllPlayers()) do
                            if play:isWounded() then
                                table.insert(choices, "recover")
                                break
                            end
                        end
                    end
                    if not table.contains(chosen, "mythluochong:draw") then
                        table.insert(choices, "draw")
                    end
                    if not table.contains(chosen, "mythluochong:discard") then
                        for _, play in sgs.qlist(room:getOtherPlayers(player)) do
                            if player:canDiscard(play, "he") then
                                table.insert(choices, "discard")
                                break
                            end
                        end
                    end
                    if not table.contains(chosen, "mythluochong:lose") then
                        table.insert(choices, "lose")
                    end
                    table.insert(choices, "cancel")
                    local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+")) --询问
                    if not choice or choice == "cancel" then return false end
                    room:broadcastSkillInvoke("luochong")                                                   -- 播放配音
                    table.insert(chosen, "mythluochong:" .. choice)
                    room:setPlayerProperty(player, "SkillDescriptionRecord_mythluochong",
                        sgs.QVariant(table.concat(chosen, "+")))
                    room:setPlayerProperty(player, "mythluochong_choice", sgs.QVariant(choice)) --AI
                    player:setSkillDescriptionSwap("mythluochong", "%arg11", table.concat(chosen, "+"))
                    room:changeTranslation(player, "mythluochong", 1)                           --更改翻译
                    local targets = sgs.SPlayerList()
                    if choice == "recover" then
                        for _, play in sgs.qlist(room:getAllPlayers()) do
                            if play:isWounded() then
                                targets:append(play)
                            end
                        end
                    end
                    if choice == "draw" then
                        targets = room:getAllPlayers()
                    end
                    if choice == "discard" then
                        for _, play in sgs.qlist(room:getOtherPlayers(player)) do
                            if player:canDiscard(play, "he") then
                                targets:append(play)
                            end
                        end
                    end
                    if choice == "lose" then
                        targets = room:getOtherPlayers(player)
                    end
                    local target = room:askForPlayerChosen(player, targets, self:objectName(), "#mythluochong-" .. choice,
                        false, false)
                    local msg = sgs.LogMessage()
                    msg.type = "#mythluochong"
                    msg.from = player
                    msg.to:append(target)
                    msg.arg = "mythluochong:" .. choice
                    room:sendLog(msg) -- 发送消息
                    if choice == "recover" then
                        room:recover(target, sgs.RecoverStruct(player))
                    end
                    if choice == "draw" then
                        target:drawCards(3, self:objectName())
                    end
                    if choice == "discard" then
                        local ids = sgs.IntList()
                        local places = sgs.PlaceList()
                        target:setFlags("qh_InTempMoving")
                        for j = 1, 3, 1 do
                            if not player:canDiscard(target, "he") then return false end
                            local Card = room:askForCardChosen(player, target, "he", self:objectName(), false,
                                sgs.Card_MethodDiscard, sgs.IntList(), j ~= 1)
                            if Card < 0 then
                                break
                            end
                            ids:append(Card)
                            places:append(room:getCardPlace(Card))
                            target:addToPile("#mythluochong", Card, false)
                        end
                        for j = 0, ids:length() - 1, 1 do
                            room:moveCardTo(sgs.Sanguosha:getCard(ids:at(j)), target, places:at(j), false)
                        end
                        target:setFlags("-qh_InTempMoving")
                        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) -- 虚拟卡
                        dummy:deleteLater()
                        dummy:addSubcards(ids)
                        room:throwCard(dummy, target, player)
                    end
                    if choice == "lose" then
                        room:loseHp(sgs.HpLostStruct(target, 1, self:objectName(), player))
                    end
                end
            end
        elseif event == sgs.RoundStart then
            if player:hasSkill(self:objectName()) then
                room:setPlayerProperty(player, "SkillDescriptionRecord_mythluochong", sgs.QVariant(""))
                room:changeTranslation(player, "mythluochong", 0)                                   --更改翻译
                room:setPlayerProperty(player, "mythluochong_choice", sgs.QVariant("delaydiscard")) --AI
                local targets = room:getOtherPlayers(player)
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "#mythluochong-mark",
                    true, false)
                if target then
                    local msg = sgs.LogMessage()
                    msg.type = "#mythluochong_target"
                    msg.from = player
                    msg.to:append(target)
                    room:sendLog(msg)                     -- 发送消息
                    room:broadcastSkillInvoke("luochong") -- 播放配音
                    room:doAnimate(1, player:objectName(), target:objectName());
                    room:setPlayerProperty(player, "mythluochong_target", sgs.QVariant(target:objectName()))
                else
                    room:setPlayerProperty(player, "mythluochong_target", sgs.QVariant(""))
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target -- 任何角色触发都能发动
    end
}

qhFakeMove = sgs.CreateTriggerSkill { --假移动
    name = "#qhFakeMove",
    events = { sgs.BeforeCardsMove, sgs.CardsMoveOneTime },
    priority = 100,
    global = true,
    on_trigger = function(self, event, player, data, room)
        for _, p in sgs.qlist(room:getAllPlayers()) do
            if p:hasFlag("qh_InTempMoving") then return true end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target -- 任何角色触发都能发动
    end
}

--哀尘
mythaichen = sgs.CreateTriggerSkill {
    name = "mythaichen",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.DamageInflicted, sgs.PreHpLost }, --受到伤害时 失去体力前
    priority = -5,
    on_trigger = function(self, event, player, data, room)
        room:broadcastSkillInvoke("aicheng") -- 播放配音
        room:sendCompulsoryTriggerLog(player, self:objectName())
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            local num = damage.damage / 2
            if math.floor(num) > 0 then
                player:gainHujia(math.floor(num))
            end
            if math.floor(num) ~= num then
                if damage.from and player:canDiscard(damage.from, "he") then
                    local id = room:askForCardChosen(player, damage.from, "he", self:objectName())
                    room:obtainCard(player, id, false) -- 获得
                else
                    player:drawCards(1, self:objectName())
                end
            end
        elseif event == sgs.PreHpLost then
            local hpLost = data:toHpLost()
            local num = hpLost.lose / 2
            hpLost.lose = math.ceil(num)
            data:setValue(hpLost)
            if math.floor(num) ~= num then
                player:drawCards(1, self:objectName())
            end
        end
    end
}

--曹金玉-隅泣
mythyuqiCARD = sgs.CreateSkillCard { -- 隅泣 技能卡
    name = "mythyuqiCARD",
    target_fixed = true,             -- 不选择目标
    will_throw = false,
    mute = true,
    about_to_use = function(self, room, card_use) --重写流程
        local use = card_use
        local data = sgs.QVariant()
        data:setValue(card_use)
        local thread = room:getThread()
        thread:trigger(sgs.PreCardUsed, room, card_use.from, data)
        thread:trigger(sgs.CardUsed, room, card_use.from, data)
        thread:trigger(sgs.CardFinished, room, card_use.from, data)
    end,
    on_use = function(self, room, source, targets)

    end
}

mythyuqiVS = sgs.CreateViewAsSkill { -- 隅泣 视为技
    name = "mythyuqi",
    n = 10,                          -- 最大卡牌数
    expand_pile = "#mythyuqi",       --扩展牌堆
    view_filter = function(self, selected, to_select)
        if #selected >= sgs.Self:getMark("mythyuqi_num") then
            return false
        end
        return sgs.Self:getPile("#mythyuqi"):contains(to_select:getEffectiveId()) --在牌堆里
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        if #cards > sgs.Self:getMark("mythyuqi_num") then return nil end
        local acard = mythyuqiCARD:clone() -- 创建技能卡
        for _, card in ipairs(cards) do    -- 扫描卡牌名单
            local id = card:getId()        -- 卡牌的编号
            acard:addSubcard(id)           -- 加入技能卡
        end
        return acard
    end,
    enabled_at_play = function(self, player)              -- 主动使用
        return false                                      -- 不能
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        return pattern == "@@mythyuqi"                    -- 询问使用隅泣 视为技时,询问视为技的时机时前面要加@
    end
}

--隅泣 获得标记数
function yuqi_getMark(player)
    local usableTimes = player:getMark("SkillDescriptionArg1_mythyuqi")
    if usableTimes == 0 then
        usableTimes = 2
    end
    local juli = player:getMark("SkillDescriptionArg2_mythyuqi")
    if juli == 0 then
        juli = 1
    end
    local guankan = player:getMark("SkillDescriptionArg3_mythyuqi")
    if guankan == 0 then
        guankan = 3
    end
    local geipai = player:getMark("SkillDescriptionArg4_mythyuqi")
    if geipai == 0 then
        geipai = 1
    end
    local huode = player:getMark("SkillDescriptionArg5_mythyuqi")
    if huode == 0 then
        huode = 1
    end
    local maxCard = player:getMark("SkillDescriptionArg6_mythyuqi")
    if maxCard == 0 then
        maxCard = 2
    end
    return usableTimes, juli, guankan, geipai, huode, maxCard
end

mythyuqi = sgs.CreateTriggerSkill { -- 隅泣 触发技
    name = "mythyuqi",
    frequency = sgs.Skill_Compulsory,
    view_as_skill = mythyuqiVS,
    events = { sgs.Damaged, sgs.HpLost },
    on_trigger = function(self, event, player, data, room)
        local times
        if event == sgs.Damaged then
            local damage = data:toDamage()
            times = damage.damage
        elseif event == sgs.HpLost then
            local hpLost = data:toHpLost()
            times = hpLost.lose
        end
        for _, play in sgs.qlist(room:getAllPlayers()) do
            local usableTimes, juli, guankan, geipai, huode, maxCard = yuqi_getMark(play)
            if play:hasSkill(self:objectName()) and play:distanceTo(player) <= juli then
                for i = 1, times do
                    if player:isDead() then return false end
                    if play:isAlive() then
                        if usableTimes > play:getMark("mythyuqi-Clear") then
                            room:broadcastSkillInvoke("yuqi") -- 播放配音
                            room:sendCompulsoryTriggerLog(play, self:objectName())
                            room:addPlayerMark(play, "mythyuqi-Clear")
                            local cards = room:getNCards(guankan, false)
                            room:returnToTopDrawPile(cards) --放回摸牌堆
                            room:setPlayerMark(play, "mythyuqi_num", geipai)
                            local cards_data = sgs.QVariant()
                            cards_data:setValue(cards)
                            room:setPlayerProperty(play, "mythyuqi_AI", cards_data)
                            room:notifyMoveToPile(play, cards, self:objectName(), sgs.Player_DrawPile, true) --通知移动来
                            local prompt = ("#mythyuqi1:%s:%d"):format(player:objectName(), geipai)
                            local card = room:askForUseCard(play, "@@mythyuqi", prompt, -1, sgs.Card_MethodNone)
                            room:notifyMoveToPile(play, cards, self:objectName(), sgs.Player_DrawPile, false) --通知移动回
                            if card then
                                local subcards = card:getSubcards()
                                if not subcards:isEmpty() then
                                    for _, subcard in sgs.qlist(subcards) do
                                        cards:removeOne(subcard)
                                    end
                                end
                            else
                                local subcard = cards:at(math.random(0, cards:length() - 1))
                                cards:removeOne(subcard)
                                card = sgs.Sanguosha:getCard(subcard)
                            end
                            room:giveCard(play, player, card, self:objectName()) --给牌
                            huode = math.min(huode, cards:length())
                            if huode > 0 then
                                room:setPlayerMark(play, "mythyuqi_num", huode)
                                cards_data:setValue(cards)
                                room:setPlayerProperty(play, "mythyuqi_AI", cards_data)
                                room:notifyMoveToPile(play, cards, self:objectName(), sgs.Player_DrawPile, true) --通知移动来
                                prompt = ("#mythyuqi2:%d"):format(huode)
                                card = room:askForUseCard(play, "@@mythyuqi", prompt, -1, sgs.Card_MethodNone)
                                room:notifyMoveToPile(play, cards, self:objectName(), sgs.Player_DrawPile, false) --通知移动回
                                if card then
                                    local subcards = card:getSubcards()
                                    if not subcards:isEmpty() then
                                        room:obtainCard(play, card, false)
                                    end
                                end
                            end
                            room:addPlayerMark(play, "&mythyuqi_maxCard-SelfClear", maxCard)
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target:isAlive() -- 任何角色触发都能发动
    end
}

--娴静
mythxianjing = sgs.CreateTriggerSkill {
    name = "mythxianjing",
    frequency = sgs.Skill_Frequent,
    events = { sgs.GameStart, sgs.RoundStart },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.GameStart then
            if player:getState() ~= "robot" then                    --非机器人
                if sgs.GetConfig("EnableCheat", false) == true then --启用作弊
                    local choice = room:askForChoice(player, self:objectName(), "no+yes", data, nil,
                        "#mythxianjing_cheat")
                    if choice == "yes" then
                        player:speak("启用究极体曹金玉")
                        room:setPlayerMark(player, "SkillDescriptionArg1_mythyuqi", 20)
                        room:setPlayerMark(player, "SkillDescriptionArg2_mythyuqi", 6)
                        room:setPlayerMark(player, "SkillDescriptionArg3_mythyuqi", 6)
                        room:setPlayerMark(player, "SkillDescriptionArg4_mythyuqi", 5)
                        room:setPlayerMark(player, "SkillDescriptionArg5_mythyuqi", 5)
                        room:setPlayerMark(player, "SkillDescriptionArg6_mythyuqi", 5)
                        player:setSkillDescriptionSwap("mythyuqi", "%arg1", player:getMark("SkillDescriptionArg1_mythyuqi"))
                        player:setSkillDescriptionSwap("mythyuqi", "%arg2", player:getMark("SkillDescriptionArg2_mythyuqi"))
                        player:setSkillDescriptionSwap("mythyuqi", "%arg3", player:getMark("SkillDescriptionArg3_mythyuqi"))
                        player:setSkillDescriptionSwap("mythyuqi", "%arg4", player:getMark("SkillDescriptionArg4_mythyuqi"))
                        player:setSkillDescriptionSwap("mythyuqi", "%arg5", player:getMark("SkillDescriptionArg5_mythyuqi"))
                        player:setSkillDescriptionSwap("mythyuqi", "%arg6", player:getMark("SkillDescriptionArg6_mythyuqi"))
                        room:changeTranslation(player, "mythyuqi", 1) --更改翻译
                    end
                end
            end
        elseif event == sgs.RoundStart then
            local usableTimes, juli, guankan, geipai, huode, maxCard = yuqi_getMark(player)
            if usableTimes >= 5 and juli >= 5 and guankan >= 5 and geipai >= 5 and huode >= 5 and maxCard >= 5 then
                return false
            end
            if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
            room:broadcastSkillInvoke("xianjing") -- 播放配音
            for i = 1, 3, 1 do
                local choices = {}
                if usableTimes < 5 then
                    table.insert(choices, "usableTimes=" .. usableTimes + 1)
                end
                if juli < 5 then
                    table.insert(choices, "juli=" .. juli + 1)
                end
                if guankan < 5 then
                    table.insert(choices, "guankan=" .. guankan + 1)
                end
                if geipai < 5 then
                    table.insert(choices, "geipai=" .. geipai + 1)
                end
                if huode < 5 then
                    table.insert(choices, "huode=" .. huode + 1)
                end
                if maxCard < 5 then
                    table.insert(choices, "maxCard=" .. maxCard + 1)
                end
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                --player:speak(choice)
                if choice:startsWith("usableTimes") then
                    usableTimes = usableTimes + 1
                end
                if choice:startsWith("juli") then
                    juli = juli + 1
                end
                if choice:startsWith("guankan") then
                    guankan = guankan + 1
                end
                if choice:startsWith("geipai") then
                    geipai = geipai + 1
                end
                if choice:startsWith("huode") then
                    huode = huode + 1
                end
                if choice:startsWith("maxCard") then
                    maxCard = maxCard + 1
                end
                room:setPlayerMark(player, "SkillDescriptionArg1_mythyuqi", usableTimes)
                room:setPlayerMark(player, "SkillDescriptionArg2_mythyuqi", juli)
                room:setPlayerMark(player, "SkillDescriptionArg3_mythyuqi", guankan)
                room:setPlayerMark(player, "SkillDescriptionArg4_mythyuqi", geipai)
                room:setPlayerMark(player, "SkillDescriptionArg5_mythyuqi", huode)
                room:setPlayerMark(player, "SkillDescriptionArg6_mythyuqi", maxCard)
            end
            player:setSkillDescriptionSwap("mythyuqi", "%arg1", player:getMark("SkillDescriptionArg1_mythyuqi"))
            player:setSkillDescriptionSwap("mythyuqi", "%arg2", player:getMark("SkillDescriptionArg2_mythyuqi"))
            player:setSkillDescriptionSwap("mythyuqi", "%arg3", player:getMark("SkillDescriptionArg3_mythyuqi"))
            player:setSkillDescriptionSwap("mythyuqi", "%arg4", player:getMark("SkillDescriptionArg4_mythyuqi"))
            player:setSkillDescriptionSwap("mythyuqi", "%arg5", player:getMark("SkillDescriptionArg5_mythyuqi"))
            player:setSkillDescriptionSwap("mythyuqi", "%arg6", player:getMark("SkillDescriptionArg6_mythyuqi"))
            room:changeTranslation(player, "mythyuqi", 1) --更改翻译
        end
    end
}

--善身
mythshanshenVS = sgs.CreateViewAsSkill { -- 善身 视为技
    name = "mythshanshen",
    n = 0,                               -- 不选择卡牌
    view_as = function(self, cards)
        return mythshanshenCARD:clone()
    end,
    enabled_at_play = function(self, player) -- 限制条件
        return not player:hasUsed("#mythshanshenCARD")
    end
}

mythshanshenCARD = sgs.CreateSkillCard {                -- 善身 技能卡
    name = "mythshanshenCARD",
    target_fixed = false,                               -- 选择目标
    filter = function(self, targets, to_select, player) -- 使用对象的约束条件
        return #targets == 0 and to_select:objectName() ~= player:objectName()
    end,
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke("shanshen") -- 播放配音
        local target = targets[1]
        local damage = sgs.DamageStruct()
        damage.from = source
        damage.to = source
        damage.damage = 1
        room:damage(damage) -- 造成伤害
        damage.to = target
        room:damage(damage) -- 造成伤害
        room:addPlayerMark(source, "mythshanshen", 1)
    end
}

mythshanshen = sgs.CreateTriggerSkill { -- 善身 触发技
    name = "mythshanshen",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = mythshanshenVS,
    events = { sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            if player:getMark("mythshanshen") == 0 and player:isWounded() then
                room:broadcastSkillInvoke("shanshen") -- 播放配音
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:recover(player, sgs.RecoverStruct(player))
            else
                room:setPlayerMark(player, "mythshanshen", 0)
            end
        end
    end
}

--孙鲁育-魅步
mythmeibu = sgs.CreateTriggerSkill {
    name = "mythmeibu",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Play then
            for _, play in sgs.qlist(room:getOtherPlayers(player)) do
                if play:hasSkill(self:objectName()) then
                    local pdata = sgs.QVariant()
                    pdata:setValue(player)
                    if room:askForSkillInvoke(play, self:objectName(), pdata) then
                        room:broadcastSkillInvoke("meibu") -- 播放配音
                        if not player:hasSkill("mythzhixi") then
                            room:setPlayerProperty(player, "mythzhixi", sgs.QVariant(play:objectName()))
                            room:acquireOneTurnSkills(player, "mythmeibu","mythzhixi")
                        end
                        room:loseHp(sgs.HpLostStruct(player, 1, self:objectName(), play))
                        break
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        if target then
            return true
        end
    end
}

--止息
mythzhixi = sgs.CreateTriggerSkill {
    name = "mythzhixi",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.CardFinished, sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardFinished and player:getPhase() == sgs.Player_Play then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") then
                local num = player:getMark("&mythzhixi-Clear") + 1
                room:setPlayerMark(player, "&mythzhixi-Clear", num)
                local hp = player:getHp()
                hp = math.min(hp, 4)
                if num >= hp then
                    room:sendCompulsoryTriggerLog(player, "mythzhixi")
                    room:broadcastSkillInvoke("meibu") -- 播放配音
                    player:endPlayPhase()              --结束出牌阶段
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                if player:hasSkill("mythzhixi") then
                    room:setPlayerProperty(player, "mythzhixi", sgs.QVariant(""))
                    room:detachSkillFromPlayer(player, "mythzhixi")
                end
            end
        end
    end
}

mythzhixiprohibit = sgs.CreateProhibitSkill { --止息 禁止技
    name = "mythzhixiprohibit",
    is_prohibited = function(self, from, to, card)
        if from:hasSkill("mythzhixi") and not card:isKindOf("SkillCard") then
            if card:getSubtype() == "aoe" or card:getSubtype() == "global_effect" then
                return false
            end
            if from:property("mythzhixi"):toString() ~= to:objectName() then
                return true
            end
        end
    end
}

--穆穆
mythmumu = sgs.CreateTriggerSkill {
    name = "mythmumu",
    frequency = sgs.Skill_Frequent,
    events = { sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Play then
            if not room:askForSkillInvoke(player, self:objectName()) then return false end
            room:broadcastSkillInvoke("mumu") -- 播放配音
            local choices = "mopai"
            local targets = sgs.SPlayerList()
            for _, play in sgs.qlist(room:getOtherPlayers(player)) do
                if player:canDiscard(play, "he") then
                    targets:append(play)
                    choices = "huode+mopai"
                end
            end
            local choice = room:askForChoice(player, self:objectName(), choices)
            if choice == "huode" then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "#mythmumu",
                    true, false)
                if target then
                    local ids = sgs.IntList()
                    local places = sgs.PlaceList()
                    target:setFlags("qh_InTempMoving")
                    for i = 1, 3, 1 do
                        if not target:canDiscard(target, "hej") then break end
                        local Card = room:askForCardChosen(player, target, "hej", self:objectName(), false,
                            sgs.Card_MethodDiscard, sgs.IntList(), i ~= 1)
                        if Card < 0 then
                            break
                        end
                        ids:append(Card)
                        places:append(room:getCardPlace(Card))
                        target:addToPile("#mythmumu", Card, false)
                    end
                    for i = 0, ids:length() - 1, 1 do
                        room:moveCardTo(sgs.Sanguosha:getCard(ids:at(i)), target, places:at(i), false)
                    end
                    target:setFlags("-qh_InTempMoving")
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) -- 虚拟卡
                    dummy:deleteLater()
                    dummy:addSubcards(ids)
                    room:obtainCard(player, dummy, false) -- 获得
                end
                room:setPlayerMark(player, "&mythmumu-Clear", 1)
            elseif choice == "mopai" then
                player:drawCards(3, self:objectName())
                room:setPlayerMark(player, "&mythmumu-Clear", 2)
            end
        end
    end
}

--武诸葛-尽瘁
mythjincui = sgs.CreateTriggerSkill {
    name = "mythjincui",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            local maxhp = player:getMaxHp()
            maxhp = math.min(maxhp, 7)
            local msg = sgs.LogMessage()           -- 创建消息
            msg.type = "#MYJincuiHp"               -- 消息结构类型(发送的消息是什么)
            msg.from = player                      -- 行为发起对象
            msg.arg = self:objectName()            -- 参数1
            msg.arg2 = maxhp                       -- 参数1
            room:sendLog(msg)                      -- 发送消息
            room:setPlayerProperty(player, "hp", sgs.QVariant(maxhp))
            room:broadcastSkillInvoke("myjincui")  -- 播放配音
            local cards = room:getNCards(7, false) -- 获取摸牌堆顶 7 张牌，不更新摸牌堆
            room:askForGuanxing(player, cards)     -- 观星
        end
    end
}

--薛灵芸-霞泪
mythxialei = sgs.CreateTriggerSkill {
    name = "mythxialei",
    frequency = sgs.Skill_Frequent,
    events = { sgs.CardsMoveOneTime, sgs.RoundStart },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if not move.from or move.from:objectName() ~= player:objectName() or move.to_place ~= sgs.Player_DiscardPile then
                return false
            end
            local red = 0 --计数
            for i = 0, move.card_ids:length() - 1, 1 do
                local id = move.card_ids:at(i)
                if sgs.Sanguosha:getCard(id):isRed() then                       --红色
                    if move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE or move.reason.m_reason == sgs.CardMoveReason_S_REASON_LETUSE then
                        if move.from_places:at(i) == sgs.Player_PlaceTable then --使用 处理区
                            red = red + 1
                        end
                    elseif move.from_places:at(i) == sgs.Player_PlaceHand or move.from_places:at(i) == sgs.Player_PlaceEquip then --装备区
                        red = red + 1
                    end
                end
            end
            if red > 0 then
                if not room:askForSkillInvoke(player, self:objectName()) then return false end
                room:broadcastSkillInvoke("xialei") -- 播放配音
                local usedTimes = player:getMark("&mythxialei-Clear")
                if usedTimes >= 3 then
                    player:drawCards(red, self:objectName())
                else
                    local card_ids = room:getNCards(red + 3 - usedTimes, false) -- 填充AG 仅自己可见
                    local msg = sgs.LogMessage()
                    msg.type = "$ViewDrawPile"
                    msg.from = player
                    msg.card_str = table.concat(sgs.QList2Table(card_ids), "+")
                    room:sendLog(msg, player)
                    msg.type = "#ViewDrawPile"
                    msg.arg = card_ids:length()
                    room:sendLog(msg, room:getOtherPlayers(player))
                    local cards = sgs.IntList()
                    for i = 1, red, 1 do
                        room:fillAG(card_ids, player)
                        local prompt = ("#mythxiale:%d:%d"):format(red, i)
                        local ag_id = room:askForAG(player, card_ids, false, self:objectName(), prompt) -- 询问AG
                        if ag_id then
                            card_ids:removeOne(ag_id)
                            cards:append(ag_id)
                        end
                        room:clearAG()
                    end
                    local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) -- 虚拟卡
                    dummy:deleteLater()
                    dummy:addSubcards(cards)
                    player:obtainCard(dummy, false)
                    if player:isDead() then
                        room:returnToTopDrawPile(card_ids) --放回摸牌堆
                    else
                        room:fillAG(card_ids, player)
                        local put = room:askForSkillInvoke(player, "xialei_put", sgs.QVariant("xialei_put"))
                        room:clearAG()
                        if put then
                            msg.type = "$XialeiPut"
                            msg.from = player
                            msg.card_str = table.concat(sgs.QList2Table(card_ids), "+")
                            room:sendLog(msg, player)
                            msg.type = "#XialeiPut"
                            msg.arg = card_ids:length()
                            room:sendLog(msg, room:getOtherPlayers(player))
                            room:returnToEndDrawPile(card_ids) --放回摸牌堆底
                        else
                            room:returnToTopDrawPile(card_ids) --放回摸牌堆
                        end
                    end
                    room:addPlayerMark(player, "&mythxialei-Clear", 1)
                end
            end
        elseif event == sgs.RoundStart then
            if not room:askForSkillInvoke(player, self:objectName()) then return false end
            room:broadcastSkillInvoke("xialei") -- 播放配音
            local cards = sgs.IntList()
            local n = 0
            for _, did in sgs.qlist(room:getDrawPile()) do
                local dcard = sgs.Sanguosha:getCard(did)
                if dcard:isRed() then
                    n = n + 1
                    if n == 3 then
                        break
                    end
                end
            end
            if n < 3 then
                room:swapPile() -- 洗牌
            end
            n = 0
            local drawPile = room:getDrawPile()
            local ids = {}
            for i = 0, drawPile:length(), 1 do
                local did = drawPile:at(math.random(0, drawPile:length() - 1))
                local dcard = sgs.Sanguosha:getCard(did)
                if dcard:isRed() and not table.contains(ids, did) then
                    cards:append(did)
                    table.insert(ids, did)
                    n = n + 1
                    if n == 3 then
                        break
                    end
                end
            end
            local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) -- 虚拟卡
            dummy:deleteLater()
            dummy:addSubcards(cards)
            player:obtainCard(dummy, false)
        end
    end
}

--暗织
mythanzhiVS = sgs.CreateViewAsSkill { -- 暗织 视为技
    name = "mythanzhi",
    n = 0,                            -- 不选择卡牌
    view_as = function(self, cards)
        return mythanzhiCARD:clone()
    end,
    enabled_at_play = function(self, player) -- 限制条件
        return player:getMark("&mythanzhi-Clear") == 0
    end,
    enabled_at_response = function(self, player, pattern) -- 什么时候响应,若没有此值则不能响应
        return pattern == "@mythanzhi"                    -- 询问使用暗织 视为技时,询问视为技的时机时前面要加@
    end
}

mythanzhiCARD = sgs.CreateSkillCard {    -- 暗织 技能卡
    name = "mythanzhiCARD",
    target_fixed = true,                 -- 不选择目标
    on_use = function(self, room, source, targets)
        local judge = sgs.JudgeStruct()  -- 判定结构体
        judge.who = source               -- 判定对象
        judge.pattern = ".|black"        -- 判定规则
        judge.good = true                -- 判定结果符合判断规则会更有利
        judge.negative = false           -- 对进行判定的人是否不利
        judge.reason = self:objectName() -- 判定原因
        room:judge(judge)                -- 进行判定
        if source:getPhase() == sgs.Player_NotActive then
            source:obtainCard(judge.card)
        end
        if judge:isGood() then -- 判定成功
            local target = room:askForPlayerChosen(source, room:getAllPlayers(), "mythanzhi", "#mythanzhi-obtain")
            if target then
                local mythanzhiRecord = sgs.QList2Table(room:getTag("mythanzhiRecord"):toIntList())
                local card_ids = {}
                for _, id in ipairs(mythanzhiRecord) do
                    if room:getCardPlace(id) == sgs.Player_DiscardPile then
                        table.insert(card_ids, id)
                    end
                end
                card_ids = Table2IntList(card_ids)
                local cards = sgs.IntList()
                for i = 1, 2, 1 do
                    if card_ids:length() == 0 then
                        break
                    end
                    room:fillAG(card_ids, source)
                    local prompt = ("#mythanzhi-ag:%s:%d"):format(target:objectName(), i)
                    local ag_id = room:askForAG(source, card_ids, false, self:objectName(), prompt) -- 询问AG
                    if ag_id then
                        card_ids:removeOne(ag_id)
                        cards:append(ag_id)
                    end
                    room:clearAG()
                end
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) -- 虚拟卡
                dummy:deleteLater()
                dummy:addSubcards(cards)
                target:obtainCard(dummy)
            end
            room:addPlayerMark(source, "&mythanzhi-Clear", 1)
        else
            room:setPlayerMark(source, "&mythxialei-Clear", 0)
            if source:getPhase() == sgs.Player_NotActive then
                source:drawCards(1, self:objectName())
            end
        end
    end
}

mythanzhi = sgs.CreateTriggerSkill { -- 暗织 触发技
    name = "mythanzhi",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = mythanzhiVS,
    events = { sgs.CardsMoveOneTime, sgs.EventPhaseChanging, sgs.Damaged },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if move.to_place ~= sgs.Player_DiscardPile then return false end
            local mythanzhiRecord = sgs.QList2Table(room:getTag("mythanzhiRecord"):toIntList())
            for _, id in sgs.qlist(move.card_ids) do
                if not table.contains(mythanzhiRecord, id) and room:getCardPlace(id) == sgs.Player_DiscardPile then
                    table.insert(mythanzhiRecord, id)
                end
            end
            local rdata = sgs.QVariant()
            rdata:setValue(Table2IntList(mythanzhiRecord))
            room:setTag("mythanzhiRecord", rdata)
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                room:setTag("mythanzhiRecord", sgs.QVariant())
            end
        elseif event == sgs.Damaged then
            if not player:hasSkill(self:objectName()) then return false end
            local num = 1
            if player:getPhase() == sgs.Player_NotActive then
                num = 2
            end
            if player:getMark("&mythanzhi-Clear") < num then
                room:askForUseCard(player, "@mythanzhi", "#mythanzhi", -1, sgs.Card_MethodNone)
                -- 询问使用暗织视为技
            else
                if not room:askForSkillInvoke(player, self:objectName()) then return false end
                local damage = data:toDamage()
                player:drawCards(damage.damage * 2, self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target:isAlive() -- 任何角色触发都能发动
    end
}


----------------添加技能----------------

if new_kingdom == 2 then -- 转变势力技
    -- 魏国
    qhstandardcaocao:addSkill(qhstandardweiguo)
    qhstandardsimayi:addSkill("qhstandardweiguo")
    qhstandardxiahoudun:addSkill("qhstandardweiguo")
    qhstandardzhangliao:addSkill("qhstandardweiguo")
    qhstandardxuchu:addSkill("qhstandardweiguo")
    qhstandardguojia:addSkill("qhstandardweiguo")
    qhstandardzhenji:addSkill("qhstandardweiguo")
    qhwindxiahouyuan:addSkill("qhstandardweiguo")

    qhwindcaoren:addSkill("qhstandardweiguo")
    qhfiredianwei:addSkill("qhstandardweiguo")
    qhfirexunyu:addSkill("qhstandardweiguo")

    mythcaojinyu:addSkill("qhstandardweiguo")
    mythxuelingyun:addSkill("qhstandardweiguo")

    -- 蜀国
    qhstandardliubei:addSkill(qhstandardshuguo)
    qhstandardguanyu:addSkill("qhstandardshuguo")
    qhstandardzhangfei:addSkill("qhstandardshuguo")
    qhstandardzhugeliang:addSkill("qhstandardshuguo")
    qhstandardzhaoyun:addSkill("qhstandardshuguo")
    qhstandardmachao:addSkill("qhstandardshuguo")
    qhstandardhuangyueying:addSkill("qhstandardshuguo")

    qhwindhuangzhong:addSkill("qhstandardshuguo")
    qhwindweiyan:addSkill("qhstandardshuguo")
    qhwindshenguanyu:addSkill("qhstandardshuguo")
    qhfirepangtong:addSkill("qhstandardshuguo")
    qhfirewolong:addSkill("qhstandardshuguo")
    qhfireshenzhugeliang:addSkill("qhstandardshuguo")

    mythhuangyueying:addSkill("qhstandardshuguo")
    mythwuzhuge:addSkill("qhstandardshuguo")

    -- 吴国
    qhstandardsunquan:addSkill(qhstandardwuguo)
    qhstandardganning:addSkill("qhstandardwuguo")
    qhstandardlvmeng:addSkill("qhstandardwuguo")
    qhstandardhuanggai:addSkill("qhstandardwuguo")
    qhstandardzhouyu:addSkill("qhstandardwuguo")
    qhstandarddaqiao:addSkill("qhstandardwuguo")
    qhstandardluxun:addSkill("qhstandardwuguo")
    qhstandardsunshangxiang:addSkill("qhstandardwuguo")

    qhwindxiaoqiao:addSkill("qhstandardwuguo")
    qhwindzhoutai:addSkill("qhstandardwuguo")
    qhwindshenlvmeng:addSkill("qhstandardwuguo")
    qhfiretaishici:addSkill("qhstandardwuguo")
    qhfireshenzhouyu:addSkill("qhstandardwuguo")

    mythsunluyu:addSkill("qhstandardwuguo")
    mythtenggongzhu:addSkill("qhstandardwuguo")
    mythtengfanglan:addSkill("qhstandardwuguo")

    -- 群国
    qhstandardhuatuo:addSkill(qhstandardqunguo)
    qhstandardlvbu:addSkill("qhstandardqunguo")
    qhstandarddiaochan:addSkill("qhstandardqunguo")
    qhstandardhuaxiong:addSkill("qhstandardqunguo")
    qhstandardgongsunzan:addSkill("qhstandardqunguo")

    qhwindzhangjiao:addSkill("qhstandardqunguo")
    qhwindyuji:addSkill("qhstandardqunguo")
    qhfireyuanshao:addSkill("qhstandardqunguo")
    qhfireyanliangwenchou:addSkill("qhstandardqunguo")
    qhfirepangde:addSkill("qhstandardqunguo")

    mythcaiwenji:addSkill("qhstandardqunguo")
end

----------------武将技能----------------

----------------魏----------------
-- 曹操
qhstandardcaocao:addSkill(qhstandardjianxiong)
qhstandardcaocao:addSkill(qhstandardhujia)
qhstandardcaocao:addSkill(qhstandardfenxue)
-- 司马懿
qhstandardsimayi:addSkill(qhstandardfankui)
qhstandardsimayi:addSkill(qhstandardguicai)
qhstandardsimayi:addSkill(qhstandardtianming)
qhstandardsimayi:addSkill("qhstandardfenxue")
-- 夏侯惇
qhstandardxiahoudun:addSkill(qhstandardganglie)
qhstandardxiahoudun:addSkill("qhstandardfenxue")
-- 张辽
qhstandardzhangliao:addSkill(qhstandardtuxi)
-- 许褚
qhstandardxuchu:addSkill(qhstandardluoyi)
-- 郭嘉
qhstandardguojia:addSkill(qhstandardtiandu)
qhstandardguojia:addSkill(qhstandardyiji)
qhstandardguojia:addSkill("qhstandardfenxue")
-- 甄姬
qhstandardzhenji:addSkill(qhstandardluoshen)
qhstandardzhenji:addSkill(qhstandardqingguo)
-- 夏侯渊
qhwindxiahouyuan:addSkill(qhwindshensu)
-- 曹仁
qhwindcaoren:addSkill(qhwindjushou)
qhwindcaoren:addSkill(qhwindjiewei)
--典韦
qhfiredianwei:addSkill(qhfireqiangxi)
--荀彧
qhfirexunyu:addSkill(qhfirequhu)
qhfirexunyu:addSkill(qhfirejieming)
qhfirexunyu:addSkill("qhstandardfenxue")

-----------------蜀----------------
-- 刘备
qhstandardliubei:addSkill(qhstandardrende)
qhstandardliubei:addSkill(qhstandardjijiang)
-- 关羽
qhstandardguanyu:addSkill(qhstandardwusheng)
qhstandardguanyu:addSkill(qhstandardyanyue)
qhstandardguanyu:addSkill(qhstandardqinglong)
qhstandardguanyu:addSkill(qhstandardzhisha)
-- 张飞
qhstandardzhangfei:addSkill(qhstandardpaoxiao)
qhstandardzhangfei:addSkill(qhstandardzhangba)
qhstandardzhangfei:addSkill("qhstandardzhisha")
-- 诸葛亮
qhstandardzhugeliang:addSkill(qhstandardguanxing)
qhstandardzhugeliang:addSkill(qhstandardkongcheng)
-- 赵云
qhstandardzhaoyun:addSkill(qhstandardlongdan)
qhstandardzhaoyun:addSkill(qhstandardlongyong)
qhstandardzhaoyun:addSkill("qhstandardzhisha")
-- 马超
qhstandardmachao:addSkill(qhstandardtieqi)
qhstandardmachao:addSkill(qhstandardmashu)
qhstandardmachao:addSkill("qhstandardzhisha")
-- 黄月英
qhstandardhuangyueying:addSkill(qhstandardjizhi)
qhstandardhuangyueying:addSkill(qhstandardqicai)
-- 黄忠
qhwindhuangzhong:addSkill(qhwindliegong)
qhwindhuangzhong:addSkill(qhwindgongshu)
qhwindhuangzhong:addSkill("qhstandardzhisha")
-- 魏延
qhwindweiyan:addSkill(qhwindkuanggu)
qhwindweiyan:addSkill("qhstandardzhisha")
--神关羽
qhwindshenguanyu:addSkill(qhwindwushen)
qhwindshenguanyu:addSkill(qhwindwushenFilter)
qhwindshenguanyu:addSkill(qhwindwuhun)
qhwindshenguanyu:addSkill("qhstandardzhisha")
extension:insertRelatedSkills("qhwindwushen", "#qhwindwushenFilter") --附加技能
--庞统
qhfirepangtong:addSkill(qhfirelianhuan)
qhfirepangtong:addSkill(qhfiremanjuann)
qhfirepangtong:addSkill(qhfireniepan)
--卧龙诸葛亮
qhfirewolong:addSkill(qhfirehuoji)
qhfirewolong:addSkill(qhfirekanpo)
qhfirewolong:addSkill(qhfirebazhen)
--神诸葛亮
qhfireshenzhugeliang:addSkill("qixing")
qhfireshenzhugeliang:addSkill(qhfirekuangfeng)
qhfireshenzhugeliang:addSkill(qhfiredawu)
qhfireshenzhugeliang:addSkill(qhfirerangxing)

----------------吴----------------
-- 孙权
qhstandardsunquan:addSkill(qhstandardzhiheng)
qhstandardsunquan:addSkill(qhstandardjiuyuan)
-- 甘宁
qhstandardganning:addSkill(qhstandardqixi)
qhstandardganning:addSkill(qhstandardpoxi)
-- 吕蒙
qhstandardlvmeng:addSkill(qhstandardkeji)
-- 黄盖
qhstandardhuanggai:addSkill(qhstandardkurou)
-- 周瑜
qhstandardzhouyu:addSkill(qhstandardyingzi)
qhstandardzhouyu:addSkill(qhstandardfanjian)
-- 大乔
qhstandarddaqiao:addSkill(qhstandardguose)
qhstandarddaqiao:addSkill(qhstandardliuli)
-- 陆逊
qhstandardluxun:addSkill(qhstandardqianxun)
qhstandardluxun:addSkill(qhstandardlianying)
-- 孙尚香
qhstandardsunshangxiang:addSkill(qhstandardjieyin)
qhstandardsunshangxiang:addSkill(qhstandardxiaoji)
-- 小乔
qhwindxiaoqiao:addSkill(qhwindhongyan)
qhwindxiaoqiao:addSkill(qhwindtianxiang)
-- 周泰
qhwindzhoutai:addSkill(qhwindbuqu)
qhwindzhoutai:addSkill(qhwindfenji)
-- 神吕蒙
qhwindshenlvmeng:addSkill(qhwindshelie)
qhwindshenlvmeng:addSkill(qhwindgongxin)
--太史慈
qhfiretaishici:addSkill(qhfiretianyi)
qhfiretaishici:addSkill(qhfirehanzhan)
qhfiretaishici:addSkill("qhstandardzhisha")
--神周瑜
qhfireshenzhouyu:addSkill(qhfireyeyan)
qhfireshenzhouyu:addSkill(qhfireqinyin)
qhfireshenzhouyu:addSkill(qhfirexinhuo)

----------------群----------------
-- 华佗
qhstandardhuatuo:addSkill(qhstandardqingnang)
qhstandardhuatuo:addSkill(qhstandardjijiu)
qhstandardhuatuo:addSkill(qhstandardrenxin)
-- 吕布
qhstandardlvbu:addSkill(qhstandardWushuang)
qhstandardlvbu:addSkill("qhstandardzhisha")
-- 貂蝉
qhstandarddiaochan:addSkill(qhstandardLijian)
qhstandarddiaochan:addSkill(qhstandardBiyue)
-- 华雄
qhstandardhuaxiong:addSkill(qhstandardyaowu)
qhstandardhuaxiong:addSkill("qhstandardzhisha")
--公孙瓒
qhstandardgongsunzan:addSkill(qhstandardyicong)
qhstandardgongsunzan:addSkill(qhstandardqiaomeng)
qhstandardgongsunzan:addSkill("qhstandardzhisha")
-- 张角
qhwindzhangjiao:addSkill(qhwindleiji)
qhwindzhangjiao:addSkill(qhwindguidao)
qhwindzhangjiao:addSkill(qhwindGuibing)
qhwindzhangjiao:addSkill(qhwindhuangtian)
qhwindzhangjiao:addRelateSkill("qhwindhuangtianvs") -- 联系技能
-- 于吉
qhwindyuji:addSkill(qhwindguhuo)
qhwindyuji:addSkill(qhwindguhuoclear)
--袁绍
qhfireyuanshao:addSkill(qhfireluanji)
qhfireyuanshao:addSkill(qhfirejimou)
qhfireyuanshao:addSkill(qhfirexueyi)
--颜良文丑
qhfireyanliangwenchou:addSkill(qhfireshuangxiong)
--庞德
qhfirepangde:addSkill("qhstandardmashu")
qhfirepangde:addSkill(qhfiremengjin)
qhfirepangde:addSkill("qhstandardzhisha")

----------------神话降临----------------
-- 黄月英
mythhuangyueying:addSkill(mythjizhi)
mythhuangyueying:addSkill(mythqicai)
mythhuangyueying:addSkill(mythjiqiao)
mythhuangyueying:addSkill(mythlinglong)
--乐蔡文姬
mythcaiwenji:addSkill(mythshuangjia)
mythcaiwenji:addSkill(mythbeifen)
--滕公主
mythtenggongzhu:addSkill(mythxingchong)
mythtenggongzhu:addSkill(mythliunian)
--滕芳兰
mythtengfanglan:addSkill(mythluochong)
mythtengfanglan:addSkill(mythaichen)
--曹金玉
mythcaojinyu:addSkill(mythyuqi)
mythcaojinyu:addSkill(mythxianjing)
mythcaojinyu:addSkill(mythshanshen)
--孙鲁育
mythsunluyu:addSkill(mythmeibu)
mythsunluyu:addSkill(mythmumu)
mythsunluyu:addRelateSkill("mythzhixi") -- 联系技能
--武诸葛
mythwuzhuge:addSkill(mythjincui)
mythwuzhuge:addSkill("qingshi")
mythwuzhuge:addSkill("zhizhe")
--薛灵芸
mythxuelingyun:addSkill(mythxialei)
mythxuelingyun:addSkill(mythanzhi)

----------------额外技能----------------

if not sgs.Sanguosha:getSkill("globaljizhi") then
    skills:append(globaljizhi)
end
if not sgs.Sanguosha:getSkill("globallinglong") then
    skills:append(globallinglong)
end
if not sgs.Sanguosha:getSkill("#qhFakeMove") then
    skills:append(qhFakeMove)
end
if not sgs.Sanguosha:getSkill("mythzhixi") then
    skills:append(mythzhixi)
end
if not sgs.Sanguosha:getSkill("mythzhixiprohibit") then
    skills:append(mythzhixiprohibit)
end
if not sgs.Sanguosha:getSkill("qhwindhuangtianvs") then
    skills:append(qhwindhuangtianVS)
end
if not sgs.Sanguosha:getSkill("qhstandardyanyueCardLimit") then
    skills:append(qhstandardyanyueCardLimit)
end

sgs.Sanguosha:addSkills(skills)

-- 翻译表
sgs.LoadTranslationTable {

    ----------------武将翻译----------------

    -- 魏
    ["qhstandardcaocao"] = "曹操-强化",
    ["&qhstandardcaocao"] = "曹操",
    ["#qhstandardcaocao"] = "魏武帝",
    ["~qhstandardcaocao"] = "霸业未成，未成啊……",

    ["qhstandardsimayi"] = "司马懿-强化",
    ["&qhstandardsimayi"] = "司马懿",
    ["#qhstandardsimayi"] = "狼顾之鬼",
    ["~qhstandardsimayi"] = "难道真是天命难违？",

    ["qhstandardxiahoudun"] = "夏侯惇-强化",
    ["&qhstandardxiahoudun"] = "夏侯惇",
    ["#qhstandardxiahoudun"] = "独眼的罗刹",
    ["~qhstandardxiahoudun"] = "两边都看不见啦……",

    ["qhstandardzhangliao"] = "张辽-强化",
    ["&qhstandardzhangliao"] = "张辽",
    ["#qhstandardzhangliao"] = "前将军",
    ["~qhstandardzhangliao"] = "真的没想到。",

    ["qhstandardxuchu"] = "许褚-强化",
    ["&qhstandardxuchu"] = "许褚",
    ["#qhstandardxuchu"] = "虎痴",
    ["~qhstandardxuchu"] = "冷，好冷啊……",

    ["qhstandardguojia"] = "郭嘉-强化",
    ["&qhstandardguojia"] = "郭嘉",
    ["#qhstandardguojia"] = "早终的先知",
    ["~qhstandardguojia"] = "咳，咳……",

    ["qhstandardzhenji"] = "甄姬-强化",
    ["&qhstandardzhenji"] = "甄姬",
    ["#qhstandardzhenji"] = "薄幸的美人",
    ["~qhstandardzhenji"] = "悼良会之永绝兮，哀一逝而异乡。",

    ["qhwindxiahouyuan"] = "夏侯渊-强化",
    ["&qhwindxiahouyuan"] = "夏侯渊",
    ["#qhwindxiahouyuan"] = "疾行的猎豹",
    ["~qhwindxiahouyuan"] = "竟然比我还…快……",

    ["qhwindcaoren"] = "曹仁-强化",
    ["&qhwindcaoren"] = "曹仁",
    ["#qhwindcaoren"] = "大将军",
    ["~qhwindcaoren"] = "长江以南再无王土矣……",

    ["qhfiredianwei"] = "典韦-强化",
    ["&qhfiredianwei"] = "典韦",
    ["#qhfiredianwei"] = "古之恶来",
    ["~qhfiredianwei"] = "主公，我就到这了",

    ["qhfirexunyu"] = "荀彧-强化",
    ["&qhfirexunyu"] = "荀彧",
    ["#qhfirexunyu"] = "王佐之才",
    ["~qhfirexunyu"] = "身为汉臣，至死不渝",

    -- 蜀
    ["qhstandardliubei"] = "刘备-强化",
    ["&qhstandardliubei"] = "刘备",
    ["#qhstandardliubei"] = "乱世的枭雄",
    ["~qhstandardliubei"] = "这就是桃园吗？",

    ["qhstandardguanyu"] = "关羽-强化",
    ["&qhstandardguanyu"] = "关羽",
    ["#qhstandardguanyu"] = "美髯公",
    ["~qhstandardguanyu"] = "什么？此地名叫麦城？",

    ["qhstandardzhangfei"] = "张飞-强化",
    ["&qhstandardzhangfei"] = "张飞",
    ["#qhstandardzhangfei"] = "万夫不当",
    ["~qhstandardzhangfei"] = "实在是杀不动啦……",

    ["qhstandardzhugeliang"] = "诸葛亮-强化",
    ["&qhstandardzhugeliang"] = "诸葛亮",
    ["#qhstandardzhugeliang"] = "迟暮的丞相",
    ["~qhstandardzhugeliang"] = "将星陨落，天命难违。",

    ["qhstandardzhaoyun"] = "赵云-强化",
    ["&qhstandardzhaoyun"] = "赵云",
    ["#qhstandardzhaoyun"] = "少年将军",
    ["~qhstandardzhaoyun"] = "这就是失败的滋味吗？",

    ["qhstandardmachao"] = "马超-强化",
    ["&qhstandardmachao"] = "马超",
    ["#qhstandardmachao"] = "一骑当千",
    ["~qhstandardmachao"] = "(马蹄声……)",

    ["qhstandardhuangyueying"] = "黄月英-强化",
    ["&qhstandardhuangyueying"] = "黄月英",
    ["#qhstandardhuangyueying"] = "归隐的杰女",
    ["~qhstandardhuangyueying"] = "亮……",

    ["qhwindhuangzhong"] = "黄忠-强化",
    ["&qhwindhuangzhong"] = "黄忠",
    ["#qhwindhuangzhong"] = "老当益壮",
    ["~qhwindhuangzhong"] = "不得不服老了……",

    ["qhwindweiyan"] = "魏延-强化",
    ["&qhwindweiyan"] = "魏延",
    ["#qhwindweiyan"] = "嗜血的独狼",
    ["~qhwindweiyan"] = "谁敢杀我！啊……",

    ["qhfirepangtong"] = "庞统-强化",
    ["&qhfirepangtong"] = "庞统",
    ["#qhfirepangtong"] = "凤雏",
    ["~qhfirepangtong"] = "落凤坡？此地不利于吾。",

    ["qhfirewolong"] = "卧龙诸葛亮-强化",
    ["&qhfirewolong"] = "诸葛亮",
    ["#qhfirewolong"] = "卧龙",
    ["~qhfirewolong"] = "悠悠苍天，曷此其极",

    -- 吴
    ["qhstandardsunquan"] = "孙权-强化",
    ["&qhstandardsunquan"] = "孙权",
    ["#qhstandardsunquan"] = "年轻的贤君",
    ["~qhstandardsunquan"] = "父亲，大哥，仲谋溃矣……",

    ["qhstandardganning"] = "甘宁-强化",
    ["&qhstandardganning"] = "甘宁",
    ["#qhstandardganning"] = "锦帆游侠",
    ["~qhstandardganning"] = "二十年后，又是一条好汉！",

    ["qhstandardlvmeng"] = "吕蒙-强化",
    ["&qhstandardlvmeng"] = "吕蒙",
    ["#qhstandardlvmeng"] = "白衣渡江",
    ["~qhstandardlvmeng"] = "被看穿了吗？",

    ["qhstandardhuanggai"] = "黄盖-强化",
    ["&qhstandardhuanggai"] = "黄盖",
    ["#qhstandardhuanggai"] = "轻身为国",
    ["~qhstandardhuanggai"] = "失血过多了……",

    ["qhstandardzhouyu"] = "周瑜-强化",
    ["&qhstandardzhouyu"] = "周瑜",
    ["#qhstandardzhouyu"] = "大都督",
    ["~qhstandardzhouyu"] = "既生瑜，何生……",

    ["qhstandarddaqiao"] = "大乔-强化",
    ["&qhstandarddaqiao"] = "大乔",
    ["#qhstandarddaqiao"] = "矜持之花",
    ["~qhstandarddaqiao"] = "伯符，我去了……",

    ["qhstandardluxun"] = "陆逊-强化",
    ["&qhstandardluxun"] = "陆逊",
    ["#qhstandardluxun"] = "儒生雄才",
    ["~qhstandardluxun"] = "我还是太年轻了……",

    ["qhstandardsunshangxiang"] = "孙尚香-强化",
    ["&qhstandardsunshangxiang"] = "孙尚香",
    ["#qhstandardsunshangxiang"] = "弓腰姬",
    ["~qhstandardsunshangxiang"] = "不可能！",

    ["qhwindxiaoqiao"] = "小乔-强化",
    ["&qhwindxiaoqiao"] = "小乔",
    ["#qhwindxiaoqiao"] = "矫情之花",
    ["~qhwindxiaoqiao"] = "公瑾…我先走一步……",

    ["qhwindzhoutai"] = "周泰-强化",
    ["&qhwindzhoutai"] = "周泰",
    ["#qhwindzhoutai"] = "历战之驱",
    ["~qhwindzhoutai"] = "敌众我寡，无力回天……",

    ["qhfiretaishici"] = "太史慈-强化",
    ["&qhfiretaishici"] = "太史慈",
    ["#qhfiretaishici"] = "笃烈之士",
    ["~qhfiretaishici"] = "无妄之灾，难以避免",

    -- 群
    ["qhstandardhuatuo"] = "华佗-强化",
    ["&qhstandardhuatuo"] = "华佗",
    ["#qhstandardhuatuo"] = "神医",
    ["~qhstandardhuatuo"] = "医者不能自医啊。",

    ["qhstandardlvbu"] = "吕布-强化",
    ["&qhstandardlvbu"] = "吕布",
    ["#qhstandardlvbu"] = "武的化身",
    ["~qhstandardlvbu"] = "不可能！",

    ["qhstandarddiaochan"] = "貂蝉-强化",
    ["&qhstandarddiaochan"] = "貂蝉",
    ["#qhstandarddiaochan"] = "绝世的舞姬",
    ["~qhstandarddiaochan"] = "父亲大人，对不起……",

    ["qhstandardhuaxiong"] = "华雄-强化",
    ["&qhstandardhuaxiong"] = "华雄",
    ["#qhstandardhuaxiong"] = "飞扬跋扈",
    ["~qhstandardhuaxiong"] = "太自负了么……",

    ["qhstandardgongsunzan"] = "公孙瓒-强化",
    ["&qhstandardgongsunzan"] = "公孙瓒",
    ["#qhstandardgongsunzan"] = "白马将军",
    ["~qhstandardgongsunzan"] = "皇图霸业梦，付之一炬中……",

    ["qhwindzhangjiao"] = "张角-强化",
    ["&qhwindzhangjiao"] = "张角",
    ["#qhwindzhangjiao"] = "天公将军",
    ["~qhwindzhangjiao"] = "黄天既覆，苍生何存……",

    ["qhwindyuji"] = "于吉-强化",
    ["&qhwindyuji"] = "于吉",
    ["#qhwindyuji"] = "太平道人",
    ["designer:qhwindyuji"] = "官方",
    ["cv:qhwindyuji"] = "官方",
    ["illustrator:qhwindyuji"] = "魔鬼鱼",
    ["~qhwindyuji"] = "道法玄机，竟被参破……",

    ["qhfireyuanshao"] = "袁绍-强化",
    ["&qhfireyuanshao"] = "袁绍",
    ["#qhfireyuanshao"] = "高贵的名门",
    ["~qhfireyuanshao"] = "天不助袁哪！",

    ["qhfireyanliangwenchou"] = "颜良＆文丑-强化",
    ["&qhfireyanliangwenchou"] = "颜良文丑",
    ["#qhfireyanliangwenchou"] = "虎狼兄弟",
    ["~qhfireyanliangwenchou"] = "生不逢时啊……",

    ["qhfirepangde"] = "庞德-强化",
    ["&qhfirepangde"] = "庞德",
    ["#qhfirepangde"] = "人马一体",
    ["~qhfirepangde"] = "宁做国家鬼，不为贼将也",


    -- 神

    ["qhwindshenguanyu"] = "神关羽-强化",
    ["&qhwindshenguanyu"] = "神关羽",
    ["#qhwindshenguanyu"] = "鬼神再临",
    ["~qhwindshenguanyu"] = "吾一世英名，竟葬于小人之手！",

    ["qhwindshenlvmeng"] = "神吕蒙-强化",
    ["&qhwindshenlvmeng"] = "神吕蒙",
    ["#qhwindshenlvmeng"] = "圣光之国士",
    ["~qhwindshenlvmeng"] = "死去方知万事空……",

    ["qhfireshenzhouyu"] = "神周瑜-强化",
    ["&qhfireshenzhouyu"] = "神周瑜",
    ["#qhfireshenzhouyu"] = "赤壁的火神",
    ["~qhfireshenzhouyu"] = "残炎黯然，弦歌不复",

    ["qhfireshenzhugeliang"] = "神诸葛亮-强化",
    ["&qhfireshenzhugeliang"] = "神诸葛亮",
    ["#qhfireshenzhugeliang"] = "赤壁的妖术师",
    ["~qhfireshenzhugeliang"] = "吾命将至，再不能临阵讨贼矣",

    -- 神话降临
    ["mythhuangyueying"] = "黄月英-神话",
    ["&mythhuangyueying"] = "黄月英",
    ["#mythhuangyueying"] = "百策的杰女",
    ["~mythhuangyueying"] = "亮……",

    ["mythcaiwenji"] = "乐蔡文姬-传说",
    ["&mythcaiwenji"] = "乐蔡文姬",
    ["#mythcaiwenji"] = "胡笳二十牌",
    ["~mythcaiwenji"] = "一生坎坷诉霜雪，一曲断肠付笳声。",

    ["mythtenggongzhu"] = "滕公主-传说",
    ["&mythtenggongzhu"] = "滕公主",
    ["#mythtenggongzhu"] = "芳华荟萃",
    ["~mythtenggongzhu"] = "已过江北，再无江南",

    ["mythtengfanglan"] = "滕芳兰-传说",
    ["&mythtengfanglan"] = "滕芳兰",
    ["#mythtengfanglan"] = "万战之驱",
    ["~mythtengfanglan"] = "封侯归命，夫妻同归。",

    ["mythcaojinyu"] = "曹金玉-传说",
    ["&mythcaojinyu"] = "曹金玉",
    ["#mythcaojinyu"] = "金乡大帝",
    ["~mythcaojinyu"] = "娘亲，雪人不怕冷吗？",

    ["mythsunluyu"] = "孙鲁育-传说",
    ["&mythsunluyu"] = "孙鲁育",
    ["#mythsunluyu"] = "止息完杀",
    ["~mythsunluyu"] = "姐姐，你且好自为之。",

    ["mythwuzhuge"] = "武诸葛-恒7版",
    ["&mythwuzhuge"] = "武诸葛亮",
    ["#mythwuzhuge"] = "忠武良弼",
    ["~mythwuzhuge"] = "天下事，了犹未了，终以不了了之。",

    ["mythxuelingyun"] = "薛灵芸-传说",
    ["&mythxuelingyun"] = "薛灵芸",
    ["#mythxuelingyun"] = "红泪无限连",
    ["~mythxuelingyun"] = "寒月隐幕，难作衣裳。",

    ----------------技能翻译----------------

    ----------------转变势力技----------------

    ["qhstandardweiguo"] = "魏国",
    [":qhstandardweiguo"] = "<b>转变势力技</b>，游戏开始时，你将势力设置为魏。\
★若你拥有其他转变势力技，可以在能转变的势力中任选其一。",
    ["zhuanbianWeiguo"] = "将势力设置为魏",
    ["#qhstandardweiguo"] = " %from 的技能 <font color = 'blue'><b>魏国</b></font> 发动， %from 将势力从 %arg 设置为 %arg2 。",
    ["qhstandardshuguo"] = "蜀国",
    [":qhstandardshuguo"] = "<b>转变势力技</b>，游戏开始时，你将势力设置为蜀。\
★若你拥有其他转变势力技，可以在能转变的势力中任选其一。",
    ["zhuanbianShuguo"] = "将势力设置为蜀",
    ["#qhstandardshuguo"] = " %from 的技能 <font color = 'red'><b>蜀国</b></font> 发动， %from 将势力从 %arg 设置为 %arg2 。",
    ["qhstandardwuguo"] = "吴国",
    [":qhstandardwuguo"] = "<b>转变势力技</b>，游戏开始时，你将势力设置为吴。\
★若你拥有其他转变势力技，可以在能转变的势力中任选其一。",
    ["zhuanbianWuguo"] = "将势力设置为吴",
    ["#qhstandardwuguo"] = " %from 的技能 <font color = 'green'><b>吴国</b></font> 发动， %from 将势力从 %arg 设置为 %arg2 。",
    ["qhstandardqunguo"] = "群国",
    [":qhstandardqunguo"] = "<b>转变势力技</b>，游戏开始时，你将势力设置为群。\
★若你拥有其他转变势力技，可以在能转变的势力中任选其一。",
    ["zhuanbianQunguo"] = "将势力设置为群",
    ["#qhstandardqunguo"] = " %from 的技能 <font color = 'grey'><b>群国</b></font> 发动， %from 将势力从 %arg 设置为 %arg2 。",

    ----------------武将技能----------------

    -- 魏-曹操
    ["qhstandardjianxiong"] = "奸雄",
    [":qhstandardjianxiong"] = "当你受到一次伤害后，若你的手牌数小于4，你可以将手牌补至4张，否则你摸1张牌。若有伤害牌且牌处于处理区或弃牌堆则获得对你造成伤害的牌，否则摸牌数+1。若伤害大于1点，你下次造成的伤害+[伤害点数-1]。（取最高不叠加）",
    ["#qhstandardjianxionghavecard"] = " %from 的技能 <font color=\"yellow\"><b>奸雄</b></font> 触发， %from 的手牌为 %arg 张，将摸 %arg2 张牌，然后获得对 %from 造成伤害的牌 %card 。",
    ["#qhstandardjianxiongnilcard"] = " %from 的技能 <font color=\"yellow\"><b>奸雄</b></font> 触发， %from 的手牌为 %arg 张，将摸 %arg2 张牌。",
    ["#qhstandardjianxiongDamage"] = " %from 的技能 <font color=\"yellow\"><b>奸雄</b></font> 触发， 对 %to 造成的伤害从 %arg 点增加至 %arg2 点",
    ["qhstandardfenxue"] = "奋血",
    ["@qhstandardfenxue"] = "奋血",
    [":qhstandardfenxue"] = "<font color = 'green'><b>每3轮限一次，</b></font>回合开始时，你可以选择一名角色，视为[此角色对你造成1点伤害]的受到伤害后情景。\
★并不会实际收到伤害或发动其他时机发动的技能，只会发动[当收到伤害后]发动的技能",
    ["#qhstandardfenxue"] = "选择一名角色，视为[此角色对你造成1点伤害]的受到伤害后情景",
    ["#qhstandardfenxuemsg"] = " %to 发动了 %arg ，将视为 %from 对 %to 造成了 <font color=\"yellow\"><b>1</b></font> 点伤害的受到伤害后情景",
    ["qhstandardhujia"] = "护驾",
    ["~qhstandardhujia"] = "护驾的效果",
    ["qhstandardhujia:jink"] = "是否发动技能【护驾】。",
    [":qhstandardhujia"] = "主公技，当你需要使用(或打出)一张【闪】时，你可以发动护驾。所有其它角色按行动顺序依次选择是否打出一张【闪】给你(视为由你使用或打出)，直到有一名角色或没有任何角色决定如此做时为止。额外的，若打出【闪】给你的角色是魏势力角色，在其使用(或打出)此【闪】后，你们各摸一张牌。\
★其它角色打出的【闪】需为实体卡。",
    ["#askForqhstandardhujia"] = " <font color = 'yellow'><b>%src</b></font> 想让你帮他使用(或打出)一张【闪】，若你是魏势力角色，在你使用(或打出)此【闪】后，你们各摸一张牌。",
    ["#qhstandardhujiawei"] = "魏势力角色 %from 替 %to 使用(或打出)了一张【闪】， %to 和 %from 将各摸一张牌。",
    ["#qhstandardhujianotwei"] = "非魏势力角色 %from 替 %to 使用(或打出)了一张【闪】。",
    -- 司马懿
    ["qhstandardfankui"] = "反馈",
    [":qhstandardfankui"] = "当你受到一次伤害后，你可以获得伤害来源的一张手牌或装备牌并摸一张牌，若伤害来源没有手牌和装备牌，改为摸2张牌，若伤害点数大于1，重复一次流程。\
★无来源伤害也可以发动，按伤害来源没有手牌和装备牌进行",
    ["qhstandardguicai"] = "鬼才",
    ["qhstandardguicaiCARD"] = "鬼才",
    ["qhstandardguicai_PlayerChosen1"] = "鬼才",
    ["#qhstandardguicai_PlayerChosen1"] = "请选择一名需要移动判定区的牌的角色",
    ["qhstandardguicai_PlayerChosen2"] = "鬼才",
    ["#qhstandardguicai_PlayerChosen2"] = "请选择一名卡牌的移动目标",
    ["Guicai_Player_Start"] = "跳过下一个准备阶段",
    ["Guicai_Player_Finish"] = "跳过下一个结束阶段",
    [":qhstandardguicai"] = "准备阶段开始时，你可以选择一名判定区有牌的角色，将此角色判定区的所有牌移动到另一名角色的判定区中。\
出牌阶段限一次，你可以选择一名角色并选择准备阶段或结束阶段，此角色跳过此阶段一次。(不能连续选择同一角色的同一阶段)\
★跳过阶段AI瞎选",
    ["#qhstandardguicai"] = " %from 的技能 %arg 发动， %to 将 %arg2 。",
    ["qhstandardtianming"] = "天命",
    ["qhstandardtianmingCARD"] = "天命",
    [":qhstandardtianming"] = "出牌阶段限一次，你可以选择一张手牌及一名其他角色，并进行一次判定，若判定结果为红桃，视为你将此牌当做【乐不思蜀】对其使用，为黑桃当做【闪电】，为梅花当做【兵粮寸段】，为方块你弃置此牌并摸2张牌。",
    -- 夏侯惇
    ["qhstandardganglie"] = "刚烈",
    [":qhstandardganglie"] = "每当你受到1点伤害后，可以对伤害来源造成1点伤害并弃置其一张牌。\
★无来源伤害或自己造成的伤害可以选择一名其它角色发动。为防止同技能互相循环发动，此技能造成伤害期间技能发动者不会再次触发此技能。",
    -- 张辽
    ["qhstandardtuxi"] = "突袭",
    ["#askForUseqhstandardtuxiVS"] = "你可以发动“突袭”选择至多 %src 名其他角色",
    ["#qhstandardtuxidis"] = "你可以弃置任意数量以此法获得的牌",
    ["~qhstandardtuxi"] = "选择若干名其他角色→点击确定",
    [":qhstandardtuxi"] = "摸牌阶段摸牌前，你可以获得至多[摸牌数+1]名其他角色的各一张手牌，且你可以弃置任意数量以此法获得的牌并摸等量张牌。若你发动了【突袭】，你的摸牌数-[选择的角色数-1]。\
★发动【突袭】的条件是其他角色至少有一名有手牌。",
    -- 许褚
    ["qhstandardluoyi"] = "裸衣",
    [":qhstandardluoyi"] = "摸牌阶段，你可以选择一项：1.少摸一张牌，若如此做，你使用基本牌或锦囊牌造成的伤害+1，直到你的下回合开始；2.多摸一张牌，若如此做，本回合的结束阶段，你将手牌补至[体力上限/1.5]张。(向上取整)",
    ["Luoyi_shao"] = "少摸一张牌，若如此做，你使用基本牌或锦囊牌造成的伤害+1，直到你的下回合开始",
    ["Luoyi_duo"] = "多摸一张牌，若如此做，本回合的结束阶段，你将手牌补至[体力上限/1.5]张",
    ["#Luoyi_shaomsg"] = " %to 选择少摸一张牌， %to 使用基本牌或锦囊牌造成的伤害将+1，直到 %to 的下回合开始。",
    ["#Luoyi_duomsg"] = " %to 选择多摸一张牌， %to 在本回合的结束阶段，将手牌补至[体力上限/1.5]张。",
    ["#Luoyi_Drawmsg"] = "因为 %from 在摸牌阶段时选择了多摸一张牌， %from 将手牌补至 %arg 张。",
    -- 郭嘉
    ["qhstandardtiandu"] = "天妒",
    [":qhstandardtiandu"] = "当你被指定为卡牌的目标后，若卡牌的使用者不是你且你是唯一目标，在其结算完后，你可弃1张手牌来获得之。\
★若你的手牌数小于3，无需弃牌也能获得",
    ["#askForqhstandardtiandu"] = "你可以弃置1张手牌，来获得 %src",
    ["qhstandardyiji"] = "遗计",
    ["@qhstandardyiji"] = "遗计触发次数",
    [":qhstandardyiji"] = "每当你受到1点伤害后，可以摸3张牌，可以将这些牌分给任意角色。\
★此技能每触发4点伤害，你回复1点体力。一次伤害至多触发3次技能",
    -- 甄姬
    ["qhstandardluoshen"] = "洛神",
    [":qhstandardluoshen"] = "准备阶段开始时，你可以进行一次判定，你获得此牌，若判定结果为黑色则本回合手牌上限+1，且若没有累计出现两次红色的判定结果，你可以重复此流程。 \
★至多判定10次",
    ["qhstandardqingguo"] = "倾国",
    [":qhstandardqingguo"] = "你可以将你的一张非红桃牌当【闪】使用或打出。",
    -- 夏侯渊
    ["qhwindshensu"] = "神速",
    [":qhwindshensu"] = "你可以分别作出下列选择：\
	1、跳过该回合的判定阶段和摸牌阶段并可以弃置一名角色的一张牌\
	2、跳过该回合出牌阶段\
你每做出上述之一项选择，视为对一名其他角色使用了一张【杀】（无距离限制）。\
当你受到一次伤害后，你可以视为对一名其他角色使用了一张【杀】（无距离限制）。\
★为防止同技能互相循环发动，此技能发动期间技能发动者不会再次触发此技能。",
    ["#askForUseqhwindshensuVS1"] = "跳过该回合的判定阶段和摸牌阶段发动'神速'",
    ["#askForUseqhwindshensuVS2"] = "跳过该回合的出牌阶段发动'神速'",
    ["#askForUseqhwindshensuVS3"] = "受到一次伤害后，可以发动'神速'",
    ["~qhwindshensu"] = "选择【杀】的目标角色→点击确定",
    ["#qhwindshensuPlayerChosen"] = "选择一名角色，弃置其一张牌",
    -- 曹仁
    ["qhwindjushou"] = "据守",
    [":qhwindjushou"] = "结束阶段开始时，你可以摸2张牌，然后翻面。",
    ["qhwindjiewei"] = "解围",
    [":qhwindjiewei"] = "当你翻面后，你可以摸一张牌，然后你可以使用一张牌，若如此做，你可以弃置一名角色的一张牌。",
    ["#qhwindjiewei"] = "你可以使用一张牌",
    ["#qhwindjieweiPlayerChosen"] = "选择一名角色，弃置其一张牌",
    --典韦
    ["qhfireqiangxi"] = "强袭",
    [":qhfireqiangxi"] = "<font color = 'green'><b>出牌阶段每项限一次，</b></font>你可以选择一项：1.失去1点体力；2.弃置一张装备牌。并选择一名其他角色，若如此做，你摸一张牌并对该角色造成1点伤害。 ",
    --荀彧
    ["qhfirequhu"] = "驱虎",
    [":qhfirequhu"] = "出牌阶段限一次，你可以与一名其他角色拼点：若你赢，该角色对一名由你选择的角色造成1点伤害；若你没赢，你可以弃置该角色一张牌，然后其对你造成1点伤害。",
    ["#qhfirequhu"] = "选择一名角色，令 %src 对其造成1点伤害",
    ["qhfirejieming"] = "节命",
    [":qhfirejieming"] = "当你受到1点伤害后，你可以令一名角色摸4张牌，然后将手牌弃置至5张（至多弃3张）。",
    ["#qhfirejieming"] = "选择一名角色，令其摸4张牌，然后将手牌弃置至5张（至多弃3张）",

    -- 蜀-刘备
    ["qhstandardrende"] = "仁德",
    ["qhstandardrendeCARD"] = "仁德",
    [":qhstandardrende"] = "出牌阶段，你可以将任意数量的手牌交给其他角色，此阶段你给出的牌张数首次达到2张或更多时，你回复1点体力(若你满血则摸1张牌)。首次达到4张或更多时，你与目标各摸一张牌。首次达到1张或更多以及3张或更多时，你有 33% 的概率摸一张牌；\
★若你本回合没使用仁德，你于此回合结束时摸2张牌。",
    ["qhstandardjijiang"] = "激将",
    ["~qhstandardjijiang"] = "激将的效果",
    ["qhstandardjijiang:slash"] = "是否发动技能【激将】。",
    [":qhstandardjijiang"] = "主公技，出牌阶段限一次/当你被要求打出一张【杀】时，你可以让所有其它角色按行动顺序依次选择是否交给你一张【杀】/是否打出一张【杀】(视为由你打出)，直到有一名角色或没有任何角色决定如此做时为止。额外的，若给你【杀】的角色是蜀势力角色，在其给你此【杀】后，你们各摸一张牌\
★其它角色打出的【杀】需为实体卡。",
    ["#askForqhstandardjijiang"] = " <font color = 'yellow'><b>%src</b></font> 想让你给他一张【杀】，若你是蜀势力角色，在你给 <font color = 'yellow'><b>%src</b></font> 此【杀】后，你们各摸一张牌。",
    ["#qhstandardjijiangshu"] = "蜀势力角色 %from 替 %to 使用(或打出)了一张【杀】， %to 和 %from 将各摸一张牌。",
    ["#qhstandardjijiangfeishu"] = "非蜀势力角色 %from 替 %to 使用(或打出)了一张【杀】。",
    -- 关羽
    ["qhstandardwusheng"] = "武圣",
    [":qhstandardwusheng"] = "你可以将一张红色牌当普通【杀】使用或打出，或将黑桃牌当【桃】使用，或将梅花牌当【酒】使用。你可以将你的一张牌当【杀】或【闪】或【桃】使用或打出（不能在出牌阶段主动使用）。\
★若你以此法转化后的牌不为杀或此牌不为红色，直到此回合结束，本技能只能发动红牌当杀的效果。",
    ["#qhstandardwusheng"] = " %from 以武圣转化后的牌不为杀或此牌不为红色，直到此回合结束， %from 的武圣只能发动红牌当杀的效果。",
    ["qhstandardyanyue"] = "偃月",
    [":qhstandardyanyue"] = "锁定技，你的攻击范围+2。<font color = 'green'><b>每回合限一次，</b></font>当你于自己的回合内使用或打出一张【杀】时，你进行一次判定，你获得判定牌，且你令所有其他角色于此回合内不能使用或打出颜色与之相同的牌。",
    ["#qhstandardyanyue"] = " %from 发动了偃月，判定结果为 %card，所有其他角色于此回合内不能使用或打出颜色为 %arg 的牌。",
    ["qhstandardqinglong"] = "青龙",
    [":qhstandardqinglong"] = "锁定技，你获得除你以外，其他原因弃入弃牌堆的<font color = 'green'><b>【青龙偃月刀】</b></font>。你使用【杀】造成伤害时，你进行一次判定，若判定结果为红色，造成的伤害+1。若你装备了<font color = 'green'><b>【青龙偃月刀】</b></font>，改为无条件造成的伤害+1 。\
★若场上存在多个角色拥有此技能，获得<font color = 'green'><b>【青龙偃月刀】</b></font>效果无效",
    ["#qhstandardqinglong"] = " %from 的技能 <font color = 'green'><b>青龙</b></font> 触发 ，对 %to 造成的伤害从 %arg 点增加至 %arg2 点 。",
    ["qhstandardzhisha"] = "止杀",
    [":qhstandardzhisha"] = "锁定技，若你未于此回合的出牌阶段内使用过【杀】，结束阶段开始时，你摸1张牌。",
    -- 张飞
    ["qhstandardpaoxiao"] = "咆哮",
    [":qhstandardpaoxiao"] = "锁定技，出牌阶段，你可以额外使用两张【杀】，你使用【杀】的范围+2。",
    ["qhstandardzhangba"] = "丈八",
    [":qhstandardzhangba"] = "<font color = 'green'><b>每回合限一次，</b></font>你可以将一张牌当普通【杀】使用或打出。\
若你使用的【杀】被【闪】抵消，你摸一张牌且本回合你下一次造成【杀】的伤害时，此伤害+1（不叠加）。 ",
    ["#qhstandardzhangba"] = "%from 的“<font color=\"yellow\"><b>丈八</b></font>”被触发，对 %to 的伤害由 %arg 点增加至 %arg2 点",
    -- 诸葛亮
    ["qhstandardguanxing"] = "观星",
    ["@qhstandardguanxing_target"] = "观星目标",
    [":qhstandardguanxing"] = "准备阶段开始时，你可以观看牌堆顶的7张牌，将其中任意数量的牌以任意顺序置于牌堆顶，其余以任意顺序置于牌堆底。出牌阶段限一次，你可以选择一名其他角色(不能选择已被本技能选择的角色)，在他的准备阶段开始时，你可以优先发动一次观星。",
    ["qhstandardkongcheng"] = "空城",
    [":qhstandardkongcheng"] = "锁定技，若你手牌数小于2，你成为【杀】或【决斗】的目标时，你将手牌补至[体力上限]张，且会发动一次空城计。\
★<b>空城计</b>：锁定技，若你因成为【杀】的目标而触发 空城 ，当你需要使用(或打出)一张【闪】时，视为你使用(或打出)了一张【闪】。若你因成为【决斗】的目标而触发 空城 ，当你需要使用(或打出)一张【杀】时，视为你使用(或打出)了一张【杀】。(只能因被要求使用卡牌而触发)",
    -- 赵云
    ["qhstandardlongdan"] = "龙胆",
    [":qhstandardlongdan"] = "你可以将一张【杀】当【闪】，一张【闪】当【杀】，一张【酒】当【桃】，一张【桃】当【酒】使用或打出。",
    ["qhstandardlongyong"] = "龙勇",
    [":qhstandardlongyong"] = "你每使用或打出一张基本牌，于此回合的结束阶段开始时，你可以摸一张牌(至多3张)。",
    -- 马超
    ["qhstandardtieqi"] = "铁骑",
    [":qhstandardtieqi"] = "当你使用【杀】指定一名角色为目标后，你可以进行一次判定，若判定结果为红色，该角色不可以使用【闪】对此【杀】进行响应，若判定结果为黑色，<font color=\"green\"><b>每轮限3次，</b></font>你摸一张牌。\
当你成为其他角色使用【杀】的目标时，你可以进行一次判定，若判定结果为红桃，此【杀】对你无效，若判定结果为黑色，你摸一张牌。 ",
    ["#qhstandardqiangming"] = " %from 的技能 %arg 触发， %from 对 %to 使用的 %card 不能被【闪】响应。",
    ["#qhstandardtieqi"] = " %to 的技能 铁骑 触发， %from 对 %to 使用的 %card 无效。",
    ["qhstandardmashu"] = "马术",
    [":qhstandardmashu"] = "锁定技，你与其他角色的距离 -1 ，若总人数大于5(包括已死亡角色)，改为你与其他角色的距离 -2 。",
    -- 黄月英
    ["qhstandardjizhi"] = "集智",
    ["qhstandardjizhi2"] = "集智 再次使用此牌",
    [":qhstandardjizhi"] = "当你使用非延时类锦囊牌选择目标后，你可以摸一张牌。你的出牌阶段中，你使用的第一张非延时类锦囊牌结算完后，你可以再次使用一次。(使用的对象与原来相同，此牌不会触发集智摸牌，不适合使用的牌不会触发技能的计数和发动)",
    ["qhstandardqicai"] = "奇才",
    [":qhstandardqicai"] = "锁定技，你使用锦囊牌时可以额外选择1个目标，你使用锦囊牌时无距离限制。",
    -- 黄忠
    ["qhwindliegong"] = "烈弓",
    [":qhwindliegong"] = "当你使用【杀】指定一名角色为目标后，若目标角色的手牌数大于或等于你的体力值，或目标角色的手牌数小于或等于你的攻击范围，你可以令该角色不能使用【闪】响应此【杀】。\
你使用【杀】造成伤害时，你可以发动此技能，若你的体力值小于等于其的体力值，造成的伤害+1，若你的体力值大于等于其的体力值，你摸一张牌。 ",
    ["#qhwindliegong"] = " %from 的技能 <font color = 'red'><b>烈弓</b></font> 触发 ，对 %to 造成的伤害从 %arg 点增加至 %arg2 点 。",
    ["qhwindgongshu"] = "弓术",
    [":qhwindgongshu"] = "锁定技，你没装备武器时，攻击范围+2。装备武器时，摸牌阶段你多摸1张牌。",
    -- 魏延
    ["qhwindkuanggu"] = "狂骨",
    [":qhwindkuanggu"] = "锁定技，当你对一名角色造成1点伤害后，若你与其的距离不大于2，你回复1点体力，若你满体力，<font color=\"green\"><b>每轮限4次，</b></font>则改为你摸1张牌。\
你每受到1点伤害，摸1张牌。",
    --神关羽
    ["qhwindwushen"] = "武神",
    ["#qhwindwushenFilter"] = "武神",
    [":qhwindwushen"] = "锁定技，你的♥手牌视为【杀】；你使用红色【杀】无距离限制；你使用♥【杀】不计入次数限制，无次数限制，不可被响应，且无视防具。",
    ["#qhwindwushen"] = " %from 的 %arg 被触发， 对 %to 使用的 %card 不可被响应，且无视防具",
    ["qhwindwuhun"] = "武魂",
    ["qhwindwuhun_limit"] = "武魂限定",
    [":qhwindwuhun"] = "锁定技，<font color = 'green'><b>每回合限两次，</b></font>当你受到或造成一次伤害后，摸一张牌。\
限定技，每当你处于濒死状态时，你摸三张牌并回复至3点体力，然后你可以使用追魂。你死亡时，你可以使用追魂。\
★追魂：选择一名其他角色，其失去当前所有体力（至少2点）",
    ["#qhwindwuhun"] = "请选择一名其他角色，其失去当前所有体力（至少2点）",
    --庞统
    ["qhfirelianhuan"] = "连环",
    [":qhfirelianhuan"] = "你可以将一张梅花牌当【铁索连环】使用或重铸，一张黑桃牌当【雷杀】使用或打出。",
    ["qhfiremanjuann"] = "漫卷",
    [":qhfiremanjuann"] = "<font color=\"green\"><b>每回合限2次，</b></font>当你不于自身的摸牌阶段或此技能获得一张手牌后，你可以获得弃牌堆中一张与此牌同点数的牌。",
    ["#qhfiremanjuann"] = "你可以获得弃牌堆中一张同点数的牌",
    ["qhfireniepan"] = "涅槃",
    ["qhfireniepan_limit"] = "涅槃限定",
    [":qhfireniepan"] = "限定技，每当你处于濒死状态时，你可以回复至4点体力并摸5张牌，将武将牌恢复至初始状态，然后你可令当前回合角色结束其出牌阶段。",
    ["qhfireniepan_endPlay:endPlay"] = "你可令当前回合角色结束其出牌阶段",
    --卧龙诸葛亮
    ["qhfirehuoji"] = "火计",
    [":qhfirehuoji"] = "出牌阶段限一次，你可以视为使用一张不可抵消的红色无点数【火攻】。",
    ["qhfirekanpo"] = "看破",
    [":qhfirekanpo"] = "你可以将一张黑色牌当【无懈可击】使用。<font color=\"green\"><b>每回合限一次，</b></font>每当你使用【无懈可击】时，你可以摸1张牌。",
    ["qhfirebazhen"] = "八阵",
    [":qhfirebazhen"] = "每当你需要使用或打出一张【闪】时，你可以进行判定：若结果不为黑色3-10，视为你使用或打出了一张【闪】。",
    --神诸葛亮
    ["qhfirekuangfeng"] = "狂风",
    [":qhfirekuangfeng"] = "准备阶段开始时，你可以将一张“星”置入弃牌堆并选择一名角色：若如此做，且其有狂风标记，其受到你造成的1点火焰伤害；没有狂风标记，其获得一个狂风标记直到你的下回合结束。\
★狂风标记：属性伤害结算开始时，此伤害+1",
    ["#askforqhfirekuangfeng"] = "选择一张“星”和一名角色发动狂风",
    ["#qhfirekuangfeng"] = "<font color=\"yellow\"><b>狂风</b></font> 效果被触发， %from 受到的属性伤害从 %arg 点增加至 %arg2 点。",
    ["qhfiredawu"] = "大雾",
    [":qhfiredawu"] = "结束阶段开始时，你可以将至少一张“星”置入弃牌堆并选择等量的角色：若如此做，这些角色各回复一点体力，并获得一个大雾标记直到你的下回合开始。\
★大雾标记：伤害结算开始时，防止非雷电属性的伤害",
    ["#askforqhfiredawu"] = "选择至少一张“星”和等量角色发动大雾",
    ["#qhfiredawu"] = "<font color=\"yellow\"><b>大雾</b></font> 效果被触发， %from 受到的非雷电属性被防止。",
    ["qhfirerangxing"] = "禳星",
    [":qhfirerangxing"] = "判定阶段开始时，你可以摸一张牌并展示之，若此牌的点数小于7，你将摸排堆顶的一张牌置于“星”中；等于7，你将摸排堆顶的三张牌置于“星”中且将手牌补至7张。",

    -- 吴-孙权
    ["qhstandardzhiheng"] = "制衡",
    ["@qhstandardzhiheng"] = "制衡使用次数",
    [":qhstandardzhiheng"] = "<font color=\"green\"><b>出牌阶段限[已损失体力值+2]次，</b></font>你可以弃掉任意张牌，并摸等量的牌。若你本回合制衡使用次数小于2，回合结束时将手牌补至[体力上限/1.5]张。(向上取整)",
    ["qhstandardjiuyuan"] = "救援",
    [":qhstandardjiuyuan"] = "主公技，锁定技，其他角色或无角色使用的【桃】指定你为目标后，你回复的体力+1。额外的，若使用【桃】给你的角色是吴势力角色，在其使用此【桃】后，你们各摸一张牌。",
    ["#qhstandardjiuyuanwu"] = "吴势力角色 %from 向 %to 使用了一张【桃】， %to 将多恢复一点体力， %to 和 %from 将各摸 %arg 张牌。",
    ["#qhstandardjiuyuanfeiwu"] = "非吴势力角色 %from 向 %to 使用了一张【桃】， %to 将多恢复一点体力",
    -- 甘宁
    ["qhstandardqixi"] = "奇袭",
    [":qhstandardqixi"] = "你可以将你的一张黑色牌当【过河拆桥】使用。锁定技，你使用【过河拆桥】时可以额外选择1个目标。",
    ["qhstandardpoxi"] = "破袭",
    ["#qhstandardpoxi1"] = "你可以选择一名角色，弃置其一张牌",
    ["#qhstandardpoxi2"] = "你可以弃置一张手牌，并对一名没有手牌的其他角色造成一点伤害",
    [":qhstandardpoxi"] = "准备阶段开始时，你可以弃置一名角色区域内一张牌。结束阶段开始时，你可以弃置一张手牌，并对一名没有手牌的其他角色造成一点伤害（无手牌也可发动）。",
    -- 吕蒙
    ["qhstandardkeji"] = "克己",
    [":qhstandardkeji"] = "若你未于此回合的出牌阶段内使用或打出过【杀】，你即将进入弃牌阶段时，你可以摸3张牌，若如此做，你的手牌上限+12直到回合结束。",
    -- 黄盖
    ["qhstandardkurou"] = "苦肉",
    [":qhstandardkurou"] = "<font color=\"green\"><b>出牌阶段限五次，</b></font>你可以失去1点体力，摸3张牌。本回合第1次使用此技能时，你使用【杀】时可以额外选择1个目标，你使用【杀】的范围+2，本回合第2次和第3次使用此技能时，你可以额外使用1张【杀】，此技能的效果仅在本回合生效。",
    -- 周瑜
    ["qhstandardyingzi"] = "英姿",
    [":qhstandardyingzi"] = "摸牌阶段，你可以多摸1张牌，若你的手牌数小于4，改为多摸2张牌。你的摸牌阶段被跳过时，你可以摸2张牌。锁定技，你的手牌上限为X。（X为你的体力上限）",
    ["qhstandardfanjian"] = "反间",
    [":qhstandardfanjian"] = "出牌阶段限一次，你可以选择一张手牌，令一名其他角色选择一种花色，然后你展示此牌，若此牌的花色与其所选的不同则其获得此牌并受到你对其造成的1点伤害，若此牌的花色与其所选的相同则你弃置此牌和其一张牌。",
    ["#qhstandardfanjian"] = " %to 选择了 %arg 花色， %from 用来发动 <font color = 'yellow'>反间</font> 的卡牌是 %card 。",
    -- 大乔
    ["qhstandardguose"] = "国色",
    [":qhstandardguose"] = "你可以将一张方块牌当【乐不思蜀-强化】使用。<font color=\"green\"><b>每回合限一次，</b></font>你使用锦囊牌后，你可以摸一张牌。",
    ["qhstandardliuli"] = "流离",
    [":qhstandardliuli"] = "当你成为【杀】的目标时，你可以弃置一张牌并选择你[攻击范围+1]内的一名角色，将此【杀】转移给该角色。(此【杀】的使用者除外)\
★你的体力值小于等于2时，可以选择此【杀】的使用者",
    ["#askForUseqhstandardliuliVS"] = " %src 对你使用【杀】，你可以弃置一张牌发动“流离”",
    ["~qhstandardliuli"] = "选择一张牌→选择一名其他角色→点击确定",
    -- 陆逊
    ["qhstandardqianxun"] = "谦逊",
    [":qhstandardqianxun"] = "你不能被选择为【顺手牵羊】和【乐不思蜀】和【乐不思蜀-强化】和【决斗】和【万箭齐发】的目标。",
    ["qhstandardlianying"] = "连营",
    ["@qhstandardlianying"] = "连营摸牌数",
    [":qhstandardlianying"] = "每当你失去手牌时，若此阶段你以此技能摸的牌少于4张，你将手牌补至2张。结束阶段开始时，你可以弃置任意数量的手牌，若弃置了牌则你可以摸1张牌。",
    ["#qhstandardlianying"] = "请弃置任意数量的手牌，若弃置了牌则你可以摸1张牌",
    -- 孙尚香
    ["qhstandardjieyin"] = "结姻",
    [":qhstandardjieyin"] = "出牌阶段限一次，你可以弃置两张牌并选择一名受伤的角色，你与其各回复1点体力，满血则改为摸一张牌，若你选择的是男性角色，其摸一张牌。",
    ["qhstandardxiaoji"] = "枭姬",
    [":qhstandardxiaoji"] = "<font color=\"green\"><b>每轮限四次，</b></font>当你失去装备区里的一张牌后，你可以摸3张牌。 ",
    -- 小乔
    ["qhwindhongyan"] = "红颜",
    [":qhwindhongyan"] = "锁定技，你使用红桃牌造成的伤害和回复+1。你使用的红桃牌结算完后，你随机摸1-2张牌。",
    ["qhwindtianxiang"] = "天香",
    [":qhwindtianxiang"] = " 当你受到伤害时，你可以弃置一张红桃或黑桃手牌并选择一名其他角色，将此伤害转移给其，若如此做，且其因此而受到伤害，在此伤害结算结束时，其摸X张牌（X为其已损失的体力值且至多为2）。",
    ["#askForqhwindtianxiang"] = "请选择天香的目标，转移 %src 造成的 %dest 点伤害",
    ["~qhwindtianxiang"] = "选择一张红桃或黑桃手牌→选择一名其他角色→点击确定",
    -- 周泰
    ["qhwindbuqu"] = "不屈",
    [":qhwindbuqu"] = "锁定技，当你处于濒死状态时，你展示牌堆顶的一张牌，然后若你的“不屈”数小于6或此牌与其他“不屈”点数均不同，你将此牌置于武将牌上，称为“不屈”，并将体力值回复至1点，否则你获得此牌。\
若你有“不屈”，你的手牌上限为X(X为你的体力上限)。",
    ["#qhwindbuqu"] = " %from 展示了 %card",
    ["qhwindfenji"] = "奋激",
    [":qhwindfenji"] = "准备阶段开始时，循环切换并执行一项：1.你可以弃置一名角色一张牌；2.你可以选择一张“不屈”并获得之（没有“不屈”则摸一张牌）。",
    ["#qhwindfenjiDis"] = "你可以选择一名角色，弃置其一张牌",
    ["#qhwindfenji"] = " %from 获得了不屈牌 %card",
    -- 神吕蒙
    ["qhwindshelie"] = "涉猎",
    [":qhwindshelie"] = "摸牌阶段摸牌前，你可以选择少摸一张牌并执行以下行动：从牌堆顶亮出七张牌，你获得其中每种花色的牌各一张，然后将其余的牌置入弃牌堆。\
★摸牌阶段被跳过时，也可以发动技能",
    ["qhwindgongxin"] = "攻心",
    ["qhwindgongxinCARD"] = "攻心",
    [":qhwindgongxin"] = "出牌阶段限一次，你可以选择一名其他角色，在可见其手牌的情况下获得其区域里的一张牌。",
    --太史慈
    ["qhfiretianyi"] = "天义",
    [":qhfiretianyi"] = "出牌阶段限一次，你可以与一名其他角色拼点：若你赢，本回合中，你可以额外使用一张【杀】，你使用【杀】可以额外选择一名目标且无距离限制、无视防具，本回合中限一次，你可以视为使用一张【杀】；若你没赢，你获得对方的拼点牌。",
    ["qhfirehanzhan"] = "酣战",
    [":qhfirehanzhan"] = "你与其他角色拼点，或其他角色与你拼点后，你可以摸一张牌。",
    --神周瑜
    ["qhfireyeyan"] = "业炎",
    [":qhfireyeyan"] = "游戏开始时，你获得5个“业炎”标记。准备阶段开始时，你可以弃置至少1个“业炎”标记并选择等量角色，若如此做，对被选择的角色各造成1点火焰伤害，本回合中你对被选择的角色使用牌无距离限制。",
    ["#qhfireyeyan"] = " %from 发动了 %arg ，将对 %to 各造成1点火焰伤害",
    ["#qhfireyeyanPlayersChosen"] = "你可以选择至多 %src 个目标，对其各造成1点火焰伤害",
    ["qhfireqinyin"] = "琴音",
    [":qhfireqinyin"] = "任意角色的阶段结束时，若至少一张你的牌在本阶段内被弃置，你可以选择一项：令一名你选择的角色之外的所有角色各回复1点体力，或令一名你选择的角色之外的所有角色各失去1点体力；若至少两张你的牌在本阶段内被弃置，你摸一张牌。",
    ["qhfireqinyin:recover"] = "令一名你选择的角色之外的所有角色各回复1点体力",
    ["qhfireqinyin:lose"] = "令一名你选择的角色之外的所有角色各失去1点体力",
    ["#qhfireqinyinPlayerChosen"] = "请选择%src体力的除外角色",
    ["#qhfireqinyin"] = " %from 发动了琴音，令 %to 之外的所有角色各 %arg 1点体力",
    ["lose"] = "失去",
    ["recover"] = "回复",
    ["qhfirexinhuo"] = "薪火",
    ["qhfirexinhuo_mark"] = "薪火-",
    [":qhfirexinhuo"] = "摸牌阶段结束时，你可以展示一张手牌，若此牌有花色，本回合你使用此花色的牌不可被响应，然后若此花色未被“薪火”记录，记录此花色，若4花色均已被记录，清除记录并获得5个“业炎”标记；若此花色已被记录，你摸一张牌。",
    ["qhfirexinhuo_hit"] = "薪火强命-",

    -- 群-华佗
    ["qhstandardqingnang"] = "青囊",
    ["qhstandardqingnangCARD"] = "青囊",
    [":qhstandardqingnang"] = "出牌阶段限一次，你可以弃置一张手牌，选择一名受伤的角色，此角色回复1点体力，然后随机触发一项：1.你回复1点体力(若你满血则摸1张牌)；2.你选择的角色摸一张牌；3.你获得1个仁心标记。",
    ["#qhstandardqingnangRecover"] = " %arg 的随机效果被触发， %from 将回复1点体力。",
    ["#qhstandardqingnangDrawCards"] = " %arg 的随机效果被触发， %from 将摸一张牌。",
    ["#qhstandardqingnangMark"] = " %arg 的随机效果被触发， %from 将获得1个仁心标记。",
    ["qhstandardjijiu"] = "急救",
    [":qhstandardjijiu"] = "你可以将一张红色牌当【桃】使用。\
★不能在出牌阶段主动使用",
    ["qhstandardrenxin"] = "仁心",
    ["@qhstandardrenxin"] = "仁心",
    [":qhstandardrenxin"] = "锁定技，你每使用一张【桃】,获得1个仁心标记。\
出牌阶段限一次，你可以弃置所有仁心标记，选择一名受伤的角色，此角色回复[仁心标记数量/2]点体力，不能整除则向下取整且此角色与你各摸一张牌(若你选择的角色是自己则摸牌时只摸一次)",
    -- 吕布
    ["qhstandardWushuang"] = "无双",
    [":qhstandardWushuang"] = "锁定技，当你使用【杀】指定一个目标后，该角色需连续使用两张【闪】才能抵消。锁定技，当你成为其他角色使用【杀】的目标时，你令其选择是否弃置一张【杀】，若其选择否或其已死亡，此【杀】对你无效；锁定技，与你进行【决斗】的角色每次需连续打出两张【杀】。",
    ["#askForqhstandardWushuang-1"] = "%src 对你【决斗】，你须连续打出两张【杀】",
    ["#askForqhstandardWushuang-2"] = "%src 对你【决斗】，你须再打出一张【杀】",
    ["#qhstandardWushuang-discard"] = "你须再弃置一张【杀】使此【杀】生效",
    -- 貂蝉
    ["qhstandardLijian"] = "离间",
    ["qhstandardLijianCARD"] = "离间",
    [":qhstandardLijian"] = " 出牌阶段限一次，你可以弃置一张牌并选择两名角色，令其中的一名角色视为对另一名角色使用【决斗】。（不能使用【无懈可击】响应此【决斗】）\
★选择的第一个角色为决斗的目标，第二个角色为决斗的使用者",
    ["qhstandardBiyue"] = "闭月",
    [":qhstandardBiyue"] = "结束阶段开始时，你可以摸2张牌。",
    -- 华雄
    ["qhstandardyaowu"] = "耀武",
    [":qhstandardyaowu"] = "锁定技，你成为基本牌的目标时，摸一张牌。当你使用红色/黑色【杀】造成伤害后，你回复1点体力（满血则摸一张牌）/弃置其一张牌。每当你受到一次伤害后，你使用的下一张【杀】不计入次数限制且不可被【闪】响应。（此效果可累计3次）",
    ["#qhstandardyaowu"] = " %from 的 %arg 被触发， 对 %to 使用的 %card 不计入次数限制且不可被响应",
    --公孙瓒
    ["qhstandardyicong"] = "义从",
    [":qhstandardyicong"] = "锁定技，你与其他角色的距离-1；其他角色与你的距离+1。",
    ["qhstandardqiaomeng"] = "趫猛",
    [":qhstandardqiaomeng"] = "当你使用【杀】指定一个其他目标后/当你成为其他角色【杀】的目标时，你可弃置其区域里的一张牌。若此牌为装备牌，改为你获得之/直到其的回合结束，其的手牌上限-1；若此牌为锦囊牌，你摸1张牌；若此牌为基本牌，此【杀】不可被【闪】响应/改为你获得之。无牌可弃时，你摸1张牌。",
    -- 张角
    ["qhwindleiji"] = "雷击",
    [":qhwindleiji"] = "当你使用或打出【闪】时，你可以令一名其他角色进行判定，若结果为：♠，你对其造成2点雷电伤害；♣，你回复1点体力(若你满血则摸1张牌)，然后对其造成1点雷电伤害；红色，你摸1张牌。\
★鬼道发动期间不会触发雷击",
    ["#qhwindleiji"] = "选择一名其他角色，发动“雷击”",
    ["#qhwindleijimsg"] = " %from 发动了 %arg ，目标是 %to ",
    ["qhwindguidao"] = "鬼道",
    [":qhwindguidao"] = "每当一名角色的判定牌生效前，你可以打出一张牌替换之。 ",
    ["#askforqhwindguidao"] = "请发动“雷击”来修改%src的%dest判定 %arg %arg2",
    ["qhwindGuibing"] = "鬼兵",
    ["qhwindguibing"] = "鬼兵",
    ["@qhwindGuibing"] = "鬼兵标记",
    ["#qhwindGuibingmsg"] = " %to 的 %arg 被触发，无效了 %from 使用的 %card",
    [":qhwindGuibing"] = "出牌阶段限一次，你可以主动使用一张闪，若如此做且你的鬼兵标记小于2，你获得一个鬼兵标记。当你被【杀】命中时，若你有鬼兵标记，需弃置1个鬼兵标记，使此【杀】对你无效。\
结束阶段开始时，若你没有在本回合出牌阶段获得鬼兵标记，你可以摸1张牌。",
    ["qhwindhuangtian"] = "黄天",
    ["qhwindhuangtianvs"] = "黄天给牌",
    [":qhwindhuangtian"] = "主公技，其他角色可发动技能“黄天给牌”。 ",
    [":qhwindhuangtianvs"] = "出牌阶段限一次，你可以交给拥有“黄天”主公技的角色一张【闪】或黑桃牌，若如此做且你是群势力角色，你摸1张牌。",
    --于吉
    ["qhwindguhuo"] = "蛊惑",
    [":qhwindguhuo"] = "你可以将一张手牌当做一张基本牌或非延时锦囊牌使用或打出。 \
★相同名称的卡牌每回合限一次，且本回合使用此技能大于4次后，不能在出牌阶段主动使用本技能\
★因lua局限，无法直接让相同名称的卡牌不可选择",
    --袁绍
    ["qhfireluanji"] = "乱击",
    [":qhfireluanji"] = "你可以将两张相同花色的手牌当【万箭齐发】使用。<font color=\"green\"><b>每种牌名每回合限一次，</b></font>当你使用牌时，若此牌的目标数大于1，你可以移除至多[此牌目标数/2（向下取整）]个目标，并摸等量的牌（每回合至多摸4张）。 ",
    ["#qhfireluanjiPlayersChosen"] = "你可以移除至多%src个目标",
    ["qhfirejimou"] = "积谋",
    [":qhfirejimou"] = "若你未于此回合的出牌阶段内使用过锦囊牌，结束阶段开始时，你可以摸2张牌。",
    ["qhfirexueyi"] = "血裔",
    [":qhfirexueyi"] = "主公技，锁定技，你的手牌上限+[2X+Y]（X为其他群势力角色数，Y为其他非群势力角色数）。",
    --颜良文丑
    ["qhfireshuangxiong"] = "双雄",
    [":qhfireshuangxiong"] = "摸牌阶段开始时，你可以进行判定：若如此做，判定牌生效后你获得之，本回合中你可以将与此牌颜色不同的手牌当【决斗】使用，将与此牌颜色相同的手牌当【杀】使用或打出。当你因此法造成2次伤害后，本回合此技能失效。",
    ["qhfireshuangxiong_red"] = "双雄-红",
    ["qhfireshuangxiong_black"] = "双雄-黑",
    ["qhfireshuangxiong_damage"] = "双雄-伤害",
    --庞德
    ["qhfiremengjin"] = "猛进",
    [":qhfiremengjin"] = "<font color = 'green'><b>每回合每项限2次，</b></font>当你使用【杀】指定一个其他目标后，你可以获得其一张牌。当你使用锦囊牌指定一个其他目标后，你可以弃置其一张牌。",

    -- 神话降临
    --黄月英
    ["mythjizhi"] = "集智",
    [":mythjizhi"] = "当你使用非延时锦囊牌选择目标后，你可以摸一张牌。你使用的非延时锦囊牌结算完后，你可以再次使用一次。(使用的对象与原来相同，此牌不会触发集智摸牌，不适合使用的牌不会触发技能) \
★此技能于游戏开始时发动后不会因任何效果失效",
    ["mythqicai"] = "奇才",
    [":mythqicai"] = "锁定技，出牌阶段开始时，你从摸牌堆中随机摸2张非【无懈可击】的非延时锦囊牌。你的准备阶段后，你执行一个额外的出牌阶段。此额外出牌阶段结束后，你重铸所有手牌。你使用锦囊牌时无距离限制。",
    ["#mythqicai"] = " %from 发动了 %arg ，将执行一个额外的出牌阶段。",
    ["mythjiqiao"] = "机巧",
    [":mythjiqiao"] = "出牌阶段限一次，你可视为使用一张非延时锦囊牌。你可以将一张锦囊牌当【无懈可击】使用。你使用的锦囊牌不可被抵消。",
    ["mythlinglong"] = "玲珑",
    ["&mythlinglong"] = "玲珑",
    ["#mythlinglongPlayerChosen"] = "选择一名角色，弃置其 %src 张牌",
    ["#mythlinglong"] = "你可以使用一张锦囊牌",
    [":mythlinglong"] = "游戏开始时，你将摸牌堆的7张牌置于武将牌上，称为“玲珑”，你可以将“玲珑”视为手牌使用或打出。\
弃牌阶段，你弃置超过手牌上限的牌后，你将“玲珑”替换为摸牌堆的X张牌，你可以弃置一名其他角色至多X张牌。（X为弃置牌数/2，向上取整）\
你成为其他角色使用的卡牌的目标时，你可以摸一张牌，然后你可以使用一张锦囊牌，没使用牌则你摸一张牌。\
★此技能于游戏开始时发动后不会因任何效果失效",
    --乐蔡文姬
    ["mythshuangjia"] = "霜笳",
    ["mythhujia"] = "胡笳",
    ["mythshuangjia_count"] = "霜笳倒计时",
    ["#mythshuangjia"] = "请选择4张胡笳牌",
    [":mythshuangjia"] = "锁定技，游戏开始时，你观看摸牌堆顶的8张牌，从中获得4张牌并为其添加“胡笳”标记，然后将其余的牌置入弃牌堆。“胡笳”不计入手牌上限，你每拥有一张“胡笳”，其他角色与你计算距离+1，你与其他角色计算距离-1。你的第3、5、7…个回合开始时你清除所有“胡笳”标记并重复此流程。 ",
    ["mythbeifen"] = "悲愤",
    [":mythbeifen"] = "锁定技，每当你失去一张“胡笳”后，你获得不同花色的牌各一张。你手中“胡笳”少于其他牌时，你使用牌无距离和次数限制。 ",
    --滕公主
    ["mythxingchong"] = "幸宠",
    [":mythxingchong"] = "每轮开始时，你可以摸X张牌并展示X张牌(X为你的体力上限)。若如此做，本轮内当你失去一张以此法展示的手牌后，你摸两张牌。",
    ["#mythxingchong"] = "请展示至多 %src 张幸宠牌",
    ["mythliunian"] = "流年",
    ["mythliunian_usedTimes"] = "流年觉醒",
    ["#mythliunian_cheat"] = "是否无视洗牌次数的限制",
    [":mythliunian"] = "锁定技，你的手牌上限+4。每轮开始时，若你已损失的体力值大于等于[“流年”标记数*2]，你回复1点体力，满血改为获得1点护甲（至多累计5点）。你可使用牌的次数+[“流年”标记数+1]。\
你的回合结束时，若洗牌次数等于：1，获得1个“流年”标记，你加2点体力上限，回复2点体力；2，获得1个“流年”标记，你加1点体力上限，回复2点体力，然后手牌上限+10（每局游戏均限一次）。 \
★若你启用了作弊，游戏开始时，你可以选择是否无视洗牌次数的限制",
    --滕芳兰
    ["mythluochong"] = "落宠",
    [":mythluochong"] = "<font color = 'green'><b>每轮每项限一次，</b></font>准备阶段开始时或结束阶段开始时或当你受到1点伤害后或当你失去1点体力后，你可选择一项：1.令一名角色回复1点体力；2.令一名其他角色失去1点体力；3.弃置一名其他角色至多3张牌；4.令一名角色摸3张牌。（若本轮4项均已选择过则重置所有选项）\
每轮开始时，你可以选择一名其他角色，其准备阶段开始时你弃置其至多4张牌。",
    [":mythluochong0"] = "<font color = 'green'><b>每轮每项限一次，</b></font>准备阶段开始时或结束阶段开始时或当你受到1点伤害后或当你失去1点体力后，你可选择一项：1.令一名角色回复1点体力；2.令一名其他角色失去1点体力；3.弃置一名其他角色至多3张牌；4.令一名角色摸3张牌。（若本轮4项均已选择过则重置所有选项）\
每轮开始时，你可以选择一名其他角色，其准备阶段开始时你弃置其至多4张牌。",
    [":mythluochong1"] = "<font color = 'green'><b>每轮每项限一次，</b></font>准备阶段开始时或结束阶段开始时或当你受到1点伤害后或当你失去1点体力后，你可选择一项：1.令一名角色回复1点体力；2.令一名其他角色失去1点体力；3.弃置一名其他角色至多3张牌；4.令一名角色摸3张牌。（若本轮4项均已选择过则重置所有选项）\
每轮开始时，你可以选择一名其他角色，其准备阶段开始时你弃置其至多4张牌。\
<font color=\"red\"><b>本轮已选：%arg11</b></font>",
    ["#mythluochong_target"] = " %from 发动了“落宠”选择了 %to ，将于 %to 准备阶段开始时弃置其至多4张牌",
    ["#mythluochong"] = " %from 发动了“落宠”选择了 %arg ，目标为 %to 。",
    ["mythluochong:recover"] = "令一名角色回复1点体力",
    ["mythluochong:lose"] = "令一名其他角色失去1点体力",
    ["mythluochong:discard"] = "弃置一名其他角色至多3张牌",
    ["mythluochong:draw"] = "令一名角色摸3张牌",
    ["#mythluochong-recover"] = "请选择一名角色回复1点体力",
    ["#mythluochong-lose"] = "请选择一名其他角色失去1点体力",
    ["#mythluochong-discard"] = "请选择一名其他角色弃置其至多3张牌",
    ["#mythluochong-draw"] = "请选择一名角色摸3张牌",
    ["#mythluochong-mark"] = "请选择一名角色，其准备阶段开始时你弃置其4张牌",
    ["mythaichen"] = "哀尘",
    [":mythaichen"] = "锁定技，你的手牌上限+4。每当你受到伤害时，你获得[伤害点数/2]点护甲（向下取整），不能整除则获得伤害来源一张牌，无牌可获得则改为摸一张牌。每当你失去体力前，你将失去体力的点数/2（向上取整），不能整除则摸一张牌。",
    --曹金玉
    ["mythyuqi"] = "隅泣",
    ["#mythyuqi"] = "隅泣",
    ["mythyuqi_maxCard"] = "隅泣手牌上限",
    [":mythyuqi"] = "锁定技，<font color = 'green'><b>每回合限【2】次，</b></font>当一名角色受到1点伤害后或当一名角色失去1点体力后，若你与其距离【1】以内，你观看牌堆顶的【3】张牌，将其中至多【1】张牌交给该角色，然后获得其余牌中至多【1】张牌，将剩余的牌置于牌堆顶，你的手牌上限+【2】直到你的回合结束。\
★至少交给其1张牌，不选择牌随机给1张\
★手牌上限加成至少具有1次隅泣的效果",
    [":mythyuqi1"] = "锁定技，<font color = 'green'><b>每回合限【%arg1】次，</b></font>当一名角色受到1点伤害后或当一名角色失去1点体力后，若你与其距离【%arg2】以内，你观看牌堆顶的【%arg3】张牌，将其中至多【%arg4】张牌交给该角色，然后获得其余牌中至多【%arg5】张牌，将剩余的牌置于牌堆顶，你的手牌上限+【%arg6】直到你的回合结束。\
★至少交给其1张牌，不选择牌随机给1张\
★手牌上限加成至少具有1次隅泣的效果",
    ["#mythyuqi1"] = "你可以将 %dest 张牌 交给 %src ",
    ["#mythyuqi2"] = "你可以获得至多 %src 张牌",
    ["mythxianjing"] = "娴静",
    ["#mythxianjing_cheat"] = "是否启用究极体曹金玉",
    [":mythxianjing"] = "每轮开始时，你可执行3次：令“隅泣”描述中“【】”内的一个数字+1（不能大于5）。 \
★若你启用了作弊，游戏开始时，你可以将“隅泣”描述中“【】”内的数字依次修改为20、6、6、5、5、5",
    ["mythxianjing:usableTimes"] = "修改为：每回合限%src次",
    ["mythxianjing:juli"] = "修改为：距离%src以内",
    ["mythxianjing:guankan"] = "修改为：观看牌堆顶的%src张牌",
    ["mythxianjing:geipai"] = "修改为：将其中至多%src张牌交给该角色",
    ["mythxianjing:huode"] = "修改为：获得其余牌中至多%src张牌",
    ["mythxianjing:maxCard"] = "修改为：你的手牌上限+%src直到你的回合结束",
    ["mythshanshen"] = "善身",
    [":mythshanshen"] = "出牌阶段限一次，你可以选择一名其他角色，你依次对自己和该角色造成1点伤害。结束阶段开始时，若你本回合中未使用过此技能，你回复1点体力。",
    --孙鲁育
    ["mythmeibu"] = "魅步",
    [":mythmeibu"] = "其他角色的出牌阶段开始时，你可令该角色获得“止息”，然后令其失去1点体力。\
★每个出牌阶段只能有一人发动魅步",
    ["mythzhixi"] = "止息",
    ["mythzhixiprohibit"] = "止息",
    [":mythzhixi"] = "锁定技，出牌阶段你使用的第X张牌结算后结束出牌阶段（X为你的体力值且至多为4）。你使用的[AOE]和[全局效果]之外的牌只能指定令你获得“止息”的角色为目标。你的回合结束时，你失去此技能。",
    ["mythmumu"] = "穆穆",
    [":mythmumu"] = "出牌阶段开始时，你可以选择一项：1.获得一名其他角色至多三张牌，然后你本回合可使用【杀】的次数-1；2.摸三张牌，然后你本回合可使用【杀】的次数+1。",
    ["mythmumu:huode"] = "获得一名其他角色至多三张牌",
    ["mythmumu:mopai"] = "摸三张牌",
    ["#mythmumu"] = "选择一名角色，获得其至多三张牌",
    --武诸葛
    ["mythjincui"] = "尽瘁",
    [":mythjincui"] = "锁定技，准备阶段开始时，你将体力值调整为7，观看牌堆顶7张牌，然后以任意顺序置于牌堆顶或牌堆底。",
    --薛灵芸
    ["mythxialei"] = "霞泪",
    [":mythxialei"] = "你的红色牌进入弃牌堆后，你可以观看牌堆顶X+3张牌，获得其中X张并可将其余牌置于牌堆底（X为进入弃牌堆的红色牌数），然后你本回合以此法观看的牌数-1（至多-3）。每轮开始时，你可以摸3张红色牌。你的手牌上限+4。",
    ["#mythxiale"] = "你可以观看并获得其中%src张牌（这是第%dest张）",
    ["mythanzhi"] = "暗织",
    ["mythanzhiCARD"] = "暗织",
    [":mythanzhi"] = "出牌阶段或当你受到伤害后，你可以进行一次判定且处于你的回合外时你获得判定牌，若结果为：红色，你重置“霞泪”的观看牌数，处于你的回合外时你摸一张牌；黑色，你可以令一名角色获得本回合置入弃牌堆且仍在弃牌堆内的你选择的两张牌，然后此技能本回合内改为[每当你受到1点伤害后摸2张牌]，处于你的回合外时本回合第二次判黑后技能更改。 ",
    ["#mythanzhi"] = "你想发动技能“暗织”吗",
    ["#mythanzhi-obtain"] = "你可以选择一名角色获得本回合置入弃牌堆的牌",
    ["#mythanzhi-ag"] = "请选择 %src 获得的两张牌（这是第%dest张）",
}

return { extension, extensionMyth, extensionWind, extensionFire, extensionCard } -- 返回拓展包
