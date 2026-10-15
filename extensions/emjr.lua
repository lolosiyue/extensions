--[[
E鸣惊人扩展包 v1.0
制作：天气真好(QQ:114534941)
首发：天气真好的三国杀主页（http://gltjk.com/sgs）
鸣谢：Paracel_007、女王受·虫
版权：马峰窝工作室（http://www.mafengwoo.com）
技能来源：Excel杀E鸣惊人武将DIY大赛
适用版本：太阳神三国杀V2版0610（http://tieba.baidu.com/p/2384878594）
使用方法：将所有文件解压缩到QSanguosha-0610目录里即可。
更新记录：
	20131110 根据最新修改的牌面更改【危城】【护武】【持内】【急思】【傲才】，增加【强辩】，张皇后改名张星彩
	20131020 更新【危城】描述和结算
	20130627 修复数个bug，调整描述。
	20130626 修复陆抗【堰守】少摸一张牌的问题
	20130625 紧急修复刘璋【图守】不能正常防止伤害的bug
	20130625 补全所有配音，坑爹程昱独立成补丁
	20130623 增加触发技的技能配音代码（虽然配音还没全）
	20130621 诸葛恪和刘璋的台词补全，增加【傲才】发动时的全屏信息
	20130618 陆抗和诸葛恪制作完毕
	20130617 周仓和张皇后制作完毕，修复刘璋的一处bug
	20130616 王允和刘璋制作完毕
	20130614 李典制作完毕，附赠坑爹程昱
	20130613 程昱制作完毕
常见问题：
	Q: AI李典为啥会乱发动【郄縠】？
	A: 貌似0610的AI碰到了askForCard就不出牌不舒服斯基……等李典的AI写好了应该没问题吧。
	
	Q: 关羽发动【武圣】将【桃】当【杀】对曹操和1体力的A使用，曹操受到伤害后发动【奸雄】获得【桃】，再对濒死的A使用，【杀】结算后周仓仍能拿到弃牌堆里的【桃】……
	A: 因神杀架构不同，周仓发动【护武】的时机比牌置入弃牌堆后更晚，目前仅通过判断弃牌堆里是否有相应的牌决定是否发动。在BeforeCardsMove时机加标记或许可行？反正我没试出来= =
	
	Q：角色在其出牌阶段非空闲时间点使用红【杀】，也能发动【护武】？
	A：暂时没想出消灭这个bug的方法。
	
	Q: 诸葛恪【强辩】怎么不会触发？
	A: 我不知道怎么写……貌似找不到合适的时机= = 等我问para吧。
	
	Q: 诸葛恪在武将一览界面里无法显示【专权】的台词（同时保证左边的技能描述里不出现单独的专权）。
	A: 据传LUA法无解，等我问para吧。
	
	Q: 诸葛恪和刘璋的技能肿么这么眼熟……如虎添翼包？！
	A: （表面回答）这两个武将都是从E鸣惊人武将比赛投稿里选出来的，并未找到侵权的证据，也尚未有人来宣称版权，因而判断投稿有效。
	A：（真实回答）看看他们的技能设计是谁吧……你懂的……
	
	Q: 插画坑爹，配音生硬，有些台词的播放没按照技能的具体情况来……
	A: 插画临时找的，配音合成的，我一个人多辛苦啊……大家帮忙吧！之所以有些配音放乱了是因为视为技的特定配音没法用lua实现……
	
	Q: 这个lua包里怎么还有lua目录，里面竟然有神杀自带的文件sgs_ex.lua，不会是破坏神杀的吧？
	A: 因为0610里那个文件略有问题，第157行“card.”被错写成了“card_”，导致【急思】实现不了……现在改过来了，没动其他地方。
	
	Q: 为啥有不懂的问题都去问para……
	A: 因为他是神将啊……就是这样，喵~
	
本人为神杀LUA初学者，欢迎交流探讨！
程序有很多冗余代码（以及各种bug），希望大家一起优化！
]]
--

module("extensions.emjr", package.seeall)
extension = sgs.Package("emjr")

-- Keep the campaign self-contained in the externally managed extension.
-- Local closures isolate its data, skills and progress from the original generals.
do
    local caocao_catalog = (function()
        -- Keep this file as data only; scenario logic consumes these stable seat indices.
        -- A '*' entry is resolved from the corresponding episode-specific general pool.
        return {
            stages = {
                { name = '颖川之战', allies = { 'caocao', 'emjr_cc_bubing' }, enemies = { '*', 'zhangjiao', '*' }, commander = 1, protect = { 1 }, target = 'zhangjiao' },
                { name = '汜水关之战', allies = { 'caocao', 'sunjian' }, enemies = { '*', 'yuanshao', '*' }, commander = 1, protect = { 1 } },
                { name = '虎牢关之战', allies = { 'caocao', '*' }, enemies = { '*', 'lvbu', '*' }, commander = 1, protect = { 1 } },
                { name = '董卓追击战', allies = { 'caocao', '*' }, enemies = { 'emjr_cc_liru', 'dongzhuo', 'lvbu' }, commander = 1, protect = { 1 } },
                { name = '徐州复仇战', allies = { '*', 'caocao', '*' }, enemies = { 'zhangfei', 'guanyu', 'jiaxu', 'liubei', 'zhaoyun' }, commander = 2, protect = { 2 } },
                { name = '濮阳之战', allies = { 'caocao', '*' }, enemies = { 'lvbu', 'zhangliao', '*' }, commander = 1, protect = { 1 } },
                { name = '献帝救出战', allies = { 'emjr_cc_xiandi', 'caocao', '*' }, enemies = { '*', 'xuhuang', '*' }, commander = 2, protect = { 1, 2 } },
                { name = '张绣讨伐战', allies = { 'caocao', 'dianwei' }, enemies = { 'emjr_cc_hucheer', 'emjr_cc_zhangxiu', '*' }, commander = 1, protect = { 1 }, loss = 'dianwei' },
                { name = '徐州入侵战', allies = { 'caocao', '*' }, enemies = { 'zhangfei', 'guanyu', 'liubei' }, commander = 1, protect = { 1 } },
                { name = '白马之战', allies = { 'caocao', 'guanyu' }, enemies = { '*', 'yanliangwenchou', '*' }, commander = 1, protect = { 1 } },
                { name = '官渡之战', allies = { 'caocao', '*' }, enemies = { 'diaochan', 'yuanshao', '*' }, commander = 1, protect = { 1 } },
                { name = '仓亭之战', allies = { 'caocao', 'xuchu' }, enemies = { 'jiaxu', 'yuanshao', '*' }, commander = 1, protect = { 1 } },
                { name = '穰山之战', allies = { '*', 'caocao', '*' }, enemies = { '*', 'guanyu', 'liubei', 'zhangfei', '*' }, commander = 2, protect = { 2 } },
                { name = '黎阳之战', allies = { 'caocao', 'guojia' }, enemies = { 'huatuo', 'yuanshao', '*' }, commander = 1, protect = { 1 } },
                { name = '邺城之战', allies = { 'caocao', '*' }, enemies = { 'zhangjiao', 'yuanshao', '*' }, commander = 1, protect = { 1 } },
                { name = '柳城平定战', allies = { 'caocao', 'guojia' }, enemies = { 'lvbu', 'yuanshao', '*' }, commander = 1, protect = { 1 }, loss = 'guojia' },
                { name = '博望坡之战', allies = { 'xiahoudun', '*' }, enemies = { 'zhangfei', 'wolong', 'guanyu' }, commander = 1, protect = { 1 } },
                { name = '长坂坡之战', allies = { 'caocao', '*' }, enemies = { 'zhangfei', 'zhaoyun', 'guanyu' }, commander = 1, protect = { 1 } },
                { name = '赤壁之战', allies = { '*', 'caocao', '*' }, enemies = { 'zhangfei', 'zhouyu', 'huanggai', 'lvmeng', 'zhaoyun' }, commander = 2, protect = { 2 } },
                { name = '合淝之战', allies = { 'caocao', '*' }, enemies = { 'sunquan', 'taishici', '*' }, commander = 1, protect = { 1 } },
                { name = '逍遥津之战', allies = { 'zhangliao', '*' }, enemies = { 'lvmeng', 'sunquan', 'ganning' }, commander = 1, protect = { 1 } },
                { name = '濡须口之战', allies = { 'caocao', '*' }, enemies = { 'luxun', 'sunquan', 'daqiao' }, commander = 1, protect = { 1 } },
                { name = '定军山之战', allies = { '*', 'caocao', 'xiahouyuan' }, enemies = { 'machao', 'zhaoyun', 'huangzhong', 'zhangfei', '*' }, commander = 2, protect = { 2 } },
                { name = '汉水之战', allies = { 'caocao', '*' }, enemies = { 'guanyu', 'liubei', '*' }, commander = 1, protect = { 1 } },
                { name = '斜谷之战', allies = { 'caocao', '*' }, enemies = { 'zhangfei', 'zhugeliang', '*' }, commander = 1, protect = { 1 } },
                { name = '樊城救援战', allies = { 'caocao', 'pangde' }, enemies = { 'zhaoyun', 'guanyu', '*' }, commander = 1, protect = { 1 } },
                { name = '阳平关之战', allies = { 'caocao', 'simayi' }, enemies = { 'zhaoyun', 'weiyan', '*' }, commander = 1, protect = { 1 } },
                { name = '剑阁之战', allies = { '*', 'caocao', '*' }, enemies = { 'weiyan', 'zhurong', 'menghuo', 'zhaoyun', 'pangtong' }, commander = 2, protect = { 2 } },
                { name = '成都侵攻战', allies = { '*', 'caocao', '*' }, enemies = { 'huangyueying', 'guanyu', 'liubei', 'zhangfei', 'wolong' }, commander = 2, protect = { 2 } },
                { name = '建业入侵战', allies = { '*', 'caocao', '*' }, enemies = { 'sunshangxiang', 'lvmeng', 'sunquan', 'luxun', 'taishici' }, commander = 2, protect = { 2 } },
            },
            allies = {
                'xiahoudun', 'zhangliao', 'xuchu', 'guojia', 'dianwei', 'caoren', 'xiahouyuan', 'xuhuang',
                'zhanghe', 'zhangchunhua', 'yujin', 'yuejin', 'simayi', 'pangde', 'emjr_cc_bubing', 'emjr_cc_gongbing',
            },
            enemies = {
                'emjr_cc_bubing', 'emjr_cc_gongbing', 'emjr_cc_huangjin', 'emjr_cc_menghu',
                'emjr_cc_qibing', 'emjr_cc_qiangbing', 'emjr_cc_tengjia', 'emjr_cc_tieqi',
            },
            beast_chance = 20,
        }
    end)()
    local caocao_skills = (function()
        -- E鸣惊人曹操传 skills. Loaded only when the host extension calls install().
        local M = {}

        local slashAttributeFlags = {
            poison = "emjr_cc_poison_slash",
            curse = "emjr_cc_curse_slash",
            paralysis = "emjr_cc_paralysis_slash",
        }

        function M.flagSlashAttribute(card, attribute)
            local flag = slashAttributeFlags[attribute]
            assert(card and flag, "invalid E鸣惊人 Slash attribute")
            card:setFlags(flag)
        end

        M.generals = {
            { key = "emjr_cc_bubing", skills = { "emjr_cc_renwang" } },
            { key = "emjr_cc_gongbing", skills = { "emjr_cc_yuanshe" }, hp = 3, female = true },
            { key = "emjr_cc_hucheer", skills = { "emjr_cc_duji", "emjr_cc_fanji" } },
            { key = "emjr_cc_huangjin", skills = { "emjr_cc_duji" } },
            { key = "emjr_cc_liru", skills = { "emjr_cc_baoyan" }, hp = 3 },
            { key = "emjr_cc_menghu", skills = { "emjr_cc_chuanji" } },
            { key = "emjr_cc_qibing", skills = { "emjr_cc_jingkai" } },
            { key = "emjr_cc_qiangbing", skills = { "emjr_cc_huiqiang" } },
            { key = "emjr_cc_tengjia", skills = { "emjr_cc_vine" } },
            { key = "emjr_cc_tieqi", skills = { "emjr_cc_tiebi" } },
            { key = "emjr_cc_xiandi", skills = { "emjr_cc_huangming", "#emjr_cc_huangming-heal", "emjr_cc_yuanshi" } },
            { key = "emjr_cc_zhangxiu", skills = { "emjr_cc_duji", "emjr_cc_huiqiang" } },
        }

        M.beasts = {
            { key = "emjr_cc_qinglong", skill = "emjr_cc_jinglei", immunity = "emjr_cc_qinglong_guard" },
            { key = "emjr_cc_baihu", skill = "emjr_cc_diyou", immunity = "emjr_cc_baihu_guard" },
            { key = "emjr_cc_zhuque", skill = "emjr_cc_tianhuo", immunity = "emjr_cc_zhuque_guard" },
            { key = "emjr_cc_xuanwu", skill = "emjr_cc_hundun", immunity = "emjr_cc_xuanwu_guard" },
        }

        local function sideOf(player)
            return player and player:getMark("emjr_cc_side") or 0
        end

        local function onBoard(player)
            return player and player:isAlive() and sideOf(player) > 0
        end

        local function noArmor(player)
            return player and not player:getArmor()
        end

        local function makeDamage(room, source, target, amount, nature, skillName)
            local damage = sgs.DamageStruct(skillName, source, target, amount, nature)
            room:damage(damage)
        end

        local function isMarkedBeast(player)
            return player and player:getMark("emjr_cc_beast") == 1
        end

        local function hasTreasureAccess(player, treasureId)
            if not onBoard(player) then return false end
            return isMarkedBeast(player) or player:getMark("emjr_cc_treasure") == treasureId
        end

        local function canSpendSpirit(player)
            return isMarkedBeast(player) or player:getMark("@emjr_cc_spirit") > 0
        end

        local function loseSpirit(room, player)
            if not isMarkedBeast(player) then
                room:removePlayerMark(player, "@emjr_cc_spirit")
            end
        end

        local function allLiving(room)
            local result = {}
            for _, player in sgs.qlist(room:getAllPlayers()) do
                if player:isAlive() then result[#result + 1] = player end
            end
            return result
        end

        local function isSlashCard(card)
            return card and card:isKindOf("Slash")
        end

        local function makeGeneral(extension, key, hp, female)
            local general = sgs.General(extension, key, "qun", hp or 4, not female, true)
            return general
        end

        local function createSkillCard(className, targetFixed, onUse)
            return sgs.CreateSkillCard {
                name = className,
                target_fixed = targetFixed,
                will_throw = true,
                on_use = onUse,
            }
        end

        local function activeTreasureSkill(name, cardClass, treasureId, cardKind, onUse, canActivateExtra)
            local card = createSkillCard(cardClass, true, onUse)
            return sgs.CreateViewAsSkillV2 {
                name = name,
                n = 1,
                limit_scope = sgs.Skill_Limit_Phase,
                max_usage_limit = 1,
                can_activate = function(skill, request)
                    local player = request:getInitiator()
                    if not player or request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
                    return hasTreasureAccess(player, treasureId) and canSpendSpirit(player)
                        and (not canActivateExtra or canActivateExtra(player, request))
                end,
                can_select_card = function(skill, request, candidate)
                    return candidate and candidate:isKindOf(cardKind)
                        and request:getSelectedCardIds():isEmpty()
                end,
                card_selection_feasible = function(skill, request)
                    return request:getSelectedCardIds():length() == 1
                end,
                create_card = function(skill, request)
                    local ids = request:getSelectedCardIds()
                    if ids:length() ~= 1 then return nil end
                    local result = card:clone()
                    result:addSubcard(ids:first())
                    result:setSkillName(skill:objectName())
                    return result
                end,
                pay = function(skill, room, ctx, request)
                    local player = ctx.owner or ctx.invoker or request:getInitiator()
                    if not player or not hasTreasureAccess(player, treasureId) or not canSpendSpirit(player) then
                        return false
                    end
                    loseSpirit(room, player)
                    return true
                end,
            }
        end

        local function groupTargets(room, source, sameSide)
            local result = {}
            local side = sideOf(source)
            if side <= 0 then return result end
            for _, player in ipairs(allLiving(room)) do
                if sideOf(player) > 0 and (sideOf(player) == side) == sameSide then
                    result[#result + 1] = player
                end
            end
            return result
        end

        local function hitFlag(target)
            return "emjr_cc_hit_" .. target:objectName()
        end

        local function applyTurnRestriction(room, player, attribute)
            local mark = "@emjr_cc_state_" .. attribute
            if player:getMark(mark) == 0 then room:setPlayerMark(player, mark, 1) end
            local pendingMark = "emjr_cc_state_" .. attribute .. "_pending"
            if player:getPhase() == sgs.Player_NotActive then
                -- Effects inflicted outside the victim's turn begin next RoundStart.
                room:setPlayerMark(player, pendingMark, 1)
                return
            end
            -- Effects inflicted during the victim's turn apply now and expire at its end.
            room:setPlayerMark(player, pendingMark, 0)
            room:setPlayerCardLimitation(player, attribute == "curse" and "use,recast" or "use",
                attribute == "curse" and "TrickCard" or "Slash", true, "emjr_cc_state_" .. attribute)
            room:setPlayerMark(player, "emjr_cc_state_" .. attribute .. "_active", 1)
        end

        local function treasureDamageRule()
            local function qualifyingSlash(card, treasureId)
                if not isSlashCard(card) then return false end
                local kind = card:objectName()
                return kind == "slash" or (treasureId == 1 and kind == "thunder_slash")
                    or (treasureId == 3 and kind == "fire_slash")
            end
            return sgs.CreateRuleSkillV2 {
                name = "emjr_cc_damage_dispatcher",
                events = { sgs.Damage, sgs.CardFinished },
                global = true,
                on_record = function(skill, event, room, player, ctx)
                    if event == sgs.Damage then
                        local damage = ctx.original_data:toDamage()
                        if damage.card and isSlashCard(damage.card) and damage.from and sideOf(damage.from) > 0
                            and damage.to and sideOf(damage.to) > 0 then
                            room:setCardFlag(damage.card, hitFlag(damage.to))
                        end
                    end
                end,
                can_trigger = function(skill, event, room, player, data)
                    if event ~= sgs.CardFinished then return "" end
                    local use = data:toCardUse()
                    if not use.card or not isSlashCard(use.card) or not use.from or sideOf(use.from) <= 0 then return "" end
                    for _, target in sgs.qlist(room:getAllPlayers(true)) do
                        if sideOf(target) > 0 and use.card:hasFlag(hitFlag(target)) then
                            local decisionPlayer = use.from or player or room:getAllPlayers():first()
                            return skill:objectName(), decisionPlayer
                        end
                    end
                    return ""
                end,
                on_effect = function(skill, event, room, player, ctx)
                    if event ~= sgs.CardFinished then return false end
                    local use = ctx.original_data:toCardUse()
                    local source, hitTargets, hitEnemies = use.from, {}, {}
                    for _, target in sgs.qlist(room:getAllPlayers(true)) do
                        if use.card:hasFlag(hitFlag(target)) then
                            hitTargets[#hitTargets + 1] = target
                            if source and sideOf(source) > 0 and sideOf(target) > 0 and sideOf(target) ~= sideOf(source) then
                                hitEnemies[#hitEnemies + 1] = target
                            end
                        end
                    end
                    if source and source:isAlive() and sideOf(source) > 0 and source:hasSkill("emjr_cc_chuanji") then
                        for _, damaged in ipairs(hitTargets) do
                            if not source:isAlive() then break end
                            local candidates = sgs.SPlayerList()
                            local seen = {}
                            for _, neighbor in ipairs({ damaged:getNextAlive(), damaged:getPreviousAlive() }) do
                                if neighbor and neighbor ~= source and sideOf(neighbor) > 0 and not seen[neighbor:objectName()]
                                    and source:canSlash(neighbor, use.card, false) then
                                    seen[neighbor:objectName()] = true
                                    candidates:append(neighbor)
                                end
                            end
                            if not candidates:isEmpty() and room:askForSkillInvoke(source, "emjr_cc_chuanji", ToData(damaged)) then
                                local chosen = room:askForPlayerChosen(source, candidates, "emjr_cc_chuanji",
                                    "@emjr_cc_chuanji:" .. damaged:objectName(), true, true)
                                if chosen then
                                    local followup = sgs.Sanguosha:cloneCard(use.card:objectName(), use.card:getSuit(), use.card:getNumber())
                                    followup:setSkillName("_emjr_cc_chuanji")
                                    room:useCard(sgs.CardUseStruct(followup, source, chosen), false)
                                    followup:deleteLater()
                                end
                            end
                        end
                    end
                    for _, damaged in ipairs(hitTargets) do
                        if damaged:hasSkill("emjr_cc_fanji") and damaged:isAlive() and source and source:isAlive()
                            and sideOf(damaged) > 0 and sideOf(source) > 0
                            and source ~= damaged and damaged:inMyAttackRange(source)
                            and damaged:canSlash(source, nil, false)
                            and room:askForSkillInvoke(damaged, "emjr_cc_fanji", ToData(source)) then
                            room:askForUseSlashTo(damaged, source,
                                "@emjr_cc_fanji:" .. source:objectName(), true, false, true)
                        end
                    end
                    local id = source and source:getMark("emjr_cc_treasure") or 0
                    if id == 0 and source and isMarkedBeast(source) then
                        if source:hasSkill("emjr_cc_jinglei") then id = 1
                        elseif source:hasSkill("emjr_cc_tianhuo") then id = 3 end
                    end
                    local skillName, nature
                    if id == 1 then skillName, nature = "emjr_cc_jinglei", sgs.DamageStruct_Thunder
                    elseif id == 3 then skillName, nature = "emjr_cc_tianhuo", sgs.DamageStruct_Fire end
                    if skillName and qualifyingSlash(use.card, id) then
                        for _, damaged in ipairs(hitEnemies) do
                            if source:isAlive() and source:hasSkill(skillName) and hasTreasureAccess(source, id)
                                and canSpendSpirit(source) and room:askForSkillInvoke(source, skillName, ToData(damaged)) then
                                loseSpirit(room, source)
                                for _, target in ipairs(groupTargets(room, source, false)) do
                                    if target ~= damaged then makeDamage(room, nil, target, 1, nature, skillName) end
                                end
                            end
                        end
                    end
                    for _, target in sgs.qlist(room:getAllPlayers()) do
                        room:setCardFlag(use.card, "-" .. hitFlag(target))
                    end
                    return false
                end,
            }
        end

        local function createStatusRule()
            return sgs.CreateRuleSkillV2 {
                name = "emjr_cc_status_rule",
                events = { sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.EventPhaseChanging, sgs.Damage, sgs.CardFinished },
                global = true,
                on_record = function(skill, event, room, player, ctx)
                    if event == sgs.Damage then
                        local damage = ctx.original_data:toDamage()
                        if damage.card and isSlashCard(damage.card) and damage.from and sideOf(damage.from) > 0
                            and damage.to and sideOf(damage.to) > 0 then
                            for attribute, flag in pairs(slashAttributeFlags) do
                                if damage.card:hasFlag(flag) then
                                    local mark = "@emjr_cc_state_" .. attribute
                                    if damage.to:getMark(mark) == 0 then
                                        if attribute == "curse" or attribute == "paralysis" then
                                            applyTurnRestriction(room, damage.to, attribute)
                                        else
                                            room:setPlayerMark(damage.to, mark, 1)
                                        end
                                    end
                                end
                            end
                        end
                    elseif event == sgs.CardFinished then
                        local use = ctx.original_data:toCardUse()
                        if use.card and use.from and sideOf(use.from) > 0 then
                            for _, flag in pairs(slashAttributeFlags) do room:setCardFlag(use.card, "-" .. flag) end
                        end
                    end
                end,
                can_trigger = function(skill, event, room, player, data)
                    if not onBoard(player) then return "" end
                    if event == sgs.EventPhaseStart then
                        if player:getPhase() == sgs.Player_RoundStart and
                            (player:getMark("@emjr_cc_state_curse") > 0 or player:getMark("@emjr_cc_state_paralysis") > 0) then
                            return skill:objectName(), player
                        end
                    elseif event == sgs.EventPhaseEnd then
                        if player:getPhase() == sgs.Player_Judge and player:getMark("@emjr_cc_state_poison") > 0 then
                            return skill:objectName(), player
                        end
                    elseif event == sgs.EventPhaseChanging then
                        local change = data:toPhaseChange()
                        if change.to == sgs.Player_NotActive and
                            ((player:getMark("@emjr_cc_state_curse") > 0 and player:getMark("emjr_cc_state_curse_pending") == 0)
                            or (player:getMark("@emjr_cc_state_paralysis") > 0 and player:getMark("emjr_cc_state_paralysis_pending") == 0)) then
                            return skill:objectName(), player
                        end
                    end
                    return ""
                end,
                on_effect = function(skill, event, room, player, ctx)
                    -- Status timers only belong to the story-mode sides; ordinary mode
                    -- players must never have restrictions or marks changed by this rule.
                    if not onBoard(player) then return false end
                    if event == sgs.EventPhaseStart then
                        if player:getMark("@emjr_cc_state_curse") > 0 then
                            room:setPlayerMark(player, "emjr_cc_state_curse_pending", 0)
                            room:setPlayerCardLimitation(player, "use,recast", "TrickCard", true, "emjr_cc_state_curse")
                            room:setPlayerMark(player, "emjr_cc_state_curse_active", 1)
                        end
                        if player:getMark("@emjr_cc_state_paralysis") > 0 then
                            room:setPlayerMark(player, "emjr_cc_state_paralysis_pending", 0)
                            room:setPlayerCardLimitation(player, "use", "Slash", true, "emjr_cc_state_paralysis")
                            room:setPlayerMark(player, "emjr_cc_state_paralysis_active", 1)
                        end
                        return false
                    end
                    if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Judge then
                        if player:getMark("@emjr_cc_state_poison") > 0 then
                            local judge = sgs.JudgeStruct()
                            judge.who = player
                            judge.reason = skill:objectName()
                            judge.pattern = ".|club"
                            judge.good = true
                            room:judge(judge)
                            room:setPlayerMark(player, "@emjr_cc_state_poison", 0)
                            if judge:isGood() then makeDamage(room, nil, player, 1, sgs.DamageStruct_Normal, skill:objectName()) end
                        end
                        return false
                    end
                    local change = ctx.original_data:toPhaseChange()
                    if change.to == sgs.Player_NotActive then
                        if player:getMark("@emjr_cc_state_curse") > 0 then
                            if player:getMark("emjr_cc_state_curse_pending") == 0 and player:getMark("emjr_cc_state_curse_active") > 0 then
                                room:removePlayerCardLimitationByReason(player, "emjr_cc_state_curse")
                                room:setPlayerMark(player, "@emjr_cc_state_curse", 0)
                                room:setPlayerMark(player, "emjr_cc_state_curse_active", 0)
                            end
                        end
                        if player:getMark("@emjr_cc_state_paralysis") > 0 then
                            if player:getMark("emjr_cc_state_paralysis_pending") == 0 and player:getMark("emjr_cc_state_paralysis_active") > 0 then
                                room:removePlayerCardLimitationByReason(player, "emjr_cc_state_paralysis")
                                room:setPlayerMark(player, "@emjr_cc_state_paralysis", 0)
                                room:setPlayerMark(player, "emjr_cc_state_paralysis_active", 0)
                            end
                        end
                    end
                    return false
                end,
            }
        end

        function M.install(extension)
            assert(extension, "M.install requires the host extension Package")
            if M._installed then return M.generals, M.beasts end

            local generals = {}
            for _, spec in ipairs(M.generals) do
                local hp = spec.hp or (spec.key == "emjr_cc_xiandi" and 3 or 4)
                generals[spec.key] = makeGeneral(extension, spec.key, hp, spec.female)
            end

            local function attach(generalKey, skill)
                generals[generalKey]:addSkill(skill)
            end

            -- A virtual Renwang Shield is supplied only while the armor slot is empty.
            local renwangArmor = sgs.CreateViewAsEquipSkill {
                name = "emjr_cc_renwang",
                view_as_equip = function(self, player)
                    if onBoard(player) and noArmor(player) then return "renwang_shield" end
                    return ""
                end,
            }
            attach("emjr_cc_bubing", renwangArmor)

            local longRange = sgs.CreateTargetModSkillV2 {
                name = "emjr_cc_yuanshe",
                pattern = "Slash",
                holder_selector = sgs.CorrectSkill_Primary,
                correct_func = function(skill, ctx)
                    local holder = ctx:getPrimary()
                    if onBoard(holder) and holder:hasSkill("emjr_cc_yuanshe")
                        and ctx:getModType() == sgs.TargetModSkill_DistanceLimit then
                        return 1000
                    end
                    return nil
                end,
            }
            attach("emjr_cc_gongbing", longRange)

            local poisonSlash = sgs.CreateTriggerSkillV2 {
                name = "emjr_cc_duji",
                frequency = sgs.Skill_Compulsory,
                events = { sgs.DamageCaused },
                can_trigger = function(skill, event, room, player, data)
                    if not onBoard(player) or not player:hasSkill(skill:objectName()) then return false end
                    local damage = data:toDamage()
                    if damage.from ~= player or not isSlashCard(damage.card) then
                        return false
                    end
                    return skill:objectName()
                end,
                on_effect = function(skill, event, room, player, ctx)
                    local damage = ctx.original_data:toDamage()
                    if damage.card then M.flagSlashAttribute(damage.card, "poison") end
                    if damage.nature == sgs.DamageStruct_Normal then damage.nature = sgs.DamageStruct_Poison end
                    ctx.original_data:setValue(damage)
                    return false
                end,
            }
            attach("emjr_cc_hucheer", poisonSlash)
            attach("emjr_cc_huangjin", poisonSlash)
            attach("emjr_cc_zhangxiu", poisonSlash)

            local counterSlash = sgs.CreateTriggerSkillV2 {
                name = "emjr_cc_fanji", events = { sgs.GameStart },
                can_trigger = function() return false end,
            }
            attach("emjr_cc_hucheer", counterSlash)

            local fireSlash = sgs.CreateFilterSkill {
                name = "emjr_cc_baoyan",
                view_filter = function(skill, card)
                    return card and card:objectName() == "slash"
                end,
                view_as = function(skill, card)
                    local fire = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())
                    fire:addSubcard(card:getId())
                    fire:setSkillName(skill:objectName())
                    return fire
                end,
            }
            attach("emjr_cc_liru", fireSlash)

            local piercingSlash = sgs.CreateTriggerSkillV2 {
                name = "emjr_cc_chuanji", events = { sgs.GameStart },
                can_trigger = function() return false end,
            }
            attach("emjr_cc_menghu", piercingSlash)

            local goldenArmorSkill = sgs.CreateEquipSkillV2 {
                name = "emjr_cc_golden_armor",
                equipment = "_emjr_cc_golden_armor",
                equipment_type = "armor",
                frequency = sgs.Skill_Compulsory,
                events = { sgs.DamageInflicted },
                can_trigger = function(skill, event, room, player, data)
                    local damage = data:toDamage()
                    if onBoard(player) and damage.nature ~= sgs.DamageStruct_Normal then
                        return skill:objectName(), player
                    end
                    return ""
                end,
                on_effect = function(skill, event, room, player, ctx)
                    room:sendCompulsoryTriggerLog(player, skill:objectName())
                    return true
                end,
            }
            local goldenArmor = sgs.CreateArmor {
                name = "_emjr_cc_golden_armor", class_name = "_emjr_cc_golden_armor",
                suit = sgs.Card_Spade, number = 2, equip_skill = goldenArmorSkill,
            }
            goldenArmor:setParent(sgs.Sanguosha:getPackage("exclusive_cards"))
            M._goldenArmor = goldenArmor -- Match the existing exclusive_cards virtual-armor registration.
            local mirrorArmor = sgs.CreateViewAsEquipSkill {
                name = "emjr_cc_jingkai",
                view_as_equip = function(self, player)
                    if onBoard(player) and noArmor(player) then return "_emjr_cc_golden_armor" end
                    return ""
                end,
            }
            attach("emjr_cc_qibing", mirrorArmor)

            local returnSpear = sgs.CreateTriggerSkillV2 {
                name = "emjr_cc_huiqiang",
                frequency = sgs.Skill_NotFrequent,
                events = { sgs.SlashMissed },
                can_trigger = function(skill, event, room, player, data)
                    if not onBoard(player) or not player:hasSkill(skill:objectName()) then return false end
                    local effect = data:toSlashEffect()
                    return effect.from == player and effect.to and effect.to:isAlive() and skill:objectName() or false
                end,
                on_cost = function(skill, event, room, player, ctx)
                    local effect = ctx.original_data:toSlashEffect()
                    return room:askForSkillInvoke(player, skill:objectName(), ToData(effect.to))
                end,
                on_effect = function(skill, event, room, player, ctx)
                    if not player:isAlive() then return false end
                    local effect = ctx.original_data:toSlashEffect()
                    local target = effect.to
                    if not target or not target:isAlive() then return false end
                    room:setPlayerFlag(player, "emjr_cc_huiqiang_active")
                    room:askForUseSlashTo(player, target,
                        "@emjr_cc_huiqiang:" .. target:objectName(), true, false, true)
                    room:setPlayerFlag(player, "-emjr_cc_huiqiang_active")
                    return false
                end,
            }
            attach("emjr_cc_qiangbing", returnSpear)
            attach("emjr_cc_zhangxiu", returnSpear)

            local returnSpearRange = sgs.CreateTargetModSkillV2 {
                name = "#emjr_cc_huiqiang_range",
                pattern = "Slash",
                holder_selector = sgs.CorrectSkill_Primary,
                correct_func = function(skill, ctx)
                    local holder = ctx:getPrimary()
                    if onBoard(holder) and holder:hasSkill("emjr_cc_huiqiang")
                        and holder:hasFlag("emjr_cc_huiqiang_active")
                        and ctx:getModType() == sgs.TargetModSkill_DistanceLimit then
                        return 1000
                    end
                    return nil
                end,
            }
            attach("emjr_cc_qiangbing", returnSpearRange)
            attach("emjr_cc_zhangxiu", returnSpearRange)
            extension:insertRelatedSkills("emjr_cc_huiqiang", "#emjr_cc_huiqiang_range")

            local vineArmor = sgs.CreateViewAsEquipSkill {
                name = "emjr_cc_vine",
                view_as_equip = function(self, player)
                    if onBoard(player) and noArmor(player) then return "vine" end
                    return ""
                end,
            }
            attach("emjr_cc_tengjia", vineArmor)

            local ironWall = sgs.CreateDistanceSkillV2 {
                name = "emjr_cc_tiebi",
                holder_selector = sgs.CorrectSkill_Participants,
                correct_func = function(skill, ctx)
                    local holder = ctx:getHolder()
                    if not onBoard(holder) then return nil end
                    if ctx:getPrimary() == holder then return -1 end
                    if ctx:getSecondary() == holder then return 1 end
                    return nil
                end,
            }
            attach("emjr_cc_tieqi", ironWall)

            local prohibitSlashAndTrick = sgs.CreateProhibitSkillV2 {
                name = "emjr_cc_huangming",
                holder_selector = sgs.CorrectSkill_Primary,
                is_prohibited = function(skill, ctx)
                    local holder = ctx:getHolder()
                    local from = ctx:getFrom()
                    local card = ctx:getCard()
                    if not onBoard(holder) or from ~= holder or not card then return false end
                    return card:isKindOf("Slash") or (card:isKindOf("TrickCard") and card:isDamageCard())
                end,
            }
            attach("emjr_cc_xiandi", prohibitSlashAndTrick)

            local emperorHeal = sgs.CreateTriggerSkillV2 {
                name = "#emjr_cc_huangming-heal",
                frequency = sgs.Skill_Compulsory,
                events = { sgs.EventPhaseStart },
                can_trigger = function(skill, event, room, player, data)
                    if onBoard(player) and player:hasSkill(skill:objectName())
                        and player:getPhase() == sgs.Player_Start and player:isWounded() then
                        return skill:objectName()
                    end
                    return false
                end,
                on_effect = function(skill, event, room, player, ctx)
                    room:sendCompulsoryTriggerLog(player, "emjr_cc_huangming")
                    local recover = sgs.RecoverStruct()
                    recover.who = player
                    recover.recover = 1
                    room:recover(player, recover)
                    return false
                end,
            }
            attach("emjr_cc_xiandi", emperorHeal)
            extension:insertRelatedSkills("emjr_cc_huangming", "#emjr_cc_huangming-heal")

            local emperorVision = sgs.CreateDistanceSkillV2 {
                name = "emjr_cc_yuanshi",
                holder_selector = sgs.CorrectSkill_Secondary,
                correct_func = function(skill, ctx)
                    local holder = ctx:getSecondary()
                    if onBoard(holder) and holder:hasSkill("emjr_cc_yuanshi") then return 1 end
                    return nil
                end,
            }
            attach("emjr_cc_xiandi", emperorVision)

            local genericBeastGuard = {}
            local function createBeastGuard(spec, nature, cap)
                return sgs.CreateTriggerSkillV2 {
                    name = spec.immunity,
                    frequency = sgs.Skill_Compulsory,
                    events = { sgs.DamageInflicted },
                    can_trigger = function(skill, event, room, player, data)
                        if not onBoard(player) or not isMarkedBeast(player)
                            or not player:hasSkill(spec.skill) then return false end
                        local damage = data:toDamage()
                        if nature and damage.nature ~= nature then return false end
                        if cap and damage.damage <= cap then return false end
                        if spec.key == "emjr_cc_xuanwu" and
                            (not damage.card or damage.card:objectName() ~= "slash"
                                or damage.nature ~= sgs.DamageStruct_Normal) then return false end
                        return skill:objectName()
                    end,
                    on_effect = function(skill, event, room, player, ctx)
                        local damage = ctx.original_data:toDamage()
                        room:sendCompulsoryTriggerLog(player, spec.skill)
                        if cap then
                            damage.damage = cap
                            ctx.original_data:setValue(damage)
                            return false
                        end
                        damage.prevented = true
                        ctx.original_data:setValue(damage)
                        return true
                    end,
                }
            end

            local qinglongGuard = createBeastGuard(M.beasts[1], sgs.DamageStruct_Thunder)
            local baihuGuard = createBeastGuard(M.beasts[2], nil, 1)
            local zhuqueGuard = createBeastGuard(M.beasts[3], sgs.DamageStruct_Fire)
            local xuanwuGuard = createBeastGuard(M.beasts[4], nil)
            genericBeastGuard = { qinglongGuard, baihuGuard, zhuqueGuard, xuanwuGuard }

            local damageDispatcher = treasureDamageRule()
            local jinglei = sgs.CreateTriggerSkillV2 {
                name = "emjr_cc_jinglei", events = { sgs.GameStart }, can_trigger = function() return false end,
            }
            local tianhuo = sgs.CreateTriggerSkillV2 {
                name = "emjr_cc_tianhuo", events = { sgs.GameStart }, can_trigger = function() return false end,
            }

            local function healFriends(cardName)
                return function(card, room, source)
                    if not hasTreasureAccess(source, 2) then return end
                    for _, target in ipairs(groupTargets(room, source, true)) do
                        if target:isWounded() then
                            local recover = sgs.RecoverStruct()
                            recover.who = source
                            recover.recover = 1
                            room:recover(target, recover)
                        end
                    end
                end
            end

            local diyou = activeTreasureSkill("emjr_cc_diyou", "emjr_cc_diyouCard", 2, "BasicCard",
                healFriends("emjr_cc_diyouCard"), function(player, request)
                    if player:isWounded() then return true end
                    -- Activation also runs in clients, whose Player has no server Room.
                    for _, friend in sgs.qlist(player:getAliveSiblings()) do
                        if sideOf(friend) == sideOf(player) and friend:isWounded() then return true end
                    end
                    return false
                end)

            local stateChoices = {
                "@emjr_cc_state_poison", "@emjr_cc_state_curse", "@emjr_cc_state_paralysis",
                "@emjr_cc_state_chain", "@emjr_cc_state_flip",
            }
            local hundun = activeTreasureSkill("emjr_cc_hundun", "emjr_cc_hundunCard", 4, "TrickCard",
                function(card, room, source)
                    if not hasTreasureAccess(source, 4) then return end
                    for _, target in ipairs(groupTargets(room, source, false)) do
                        local available = {}
                        for _, mark in ipairs(stateChoices) do
                            local eligible = target:getMark(mark) == 0
                            if mark == "@emjr_cc_state_chain" then
                                eligible = not target:isChained()
                                if eligible then room:setPlayerMark(target, mark, 0) end
                            elseif mark == "@emjr_cc_state_flip" then
                                eligible = target:faceUp()
                                if eligible then room:setPlayerMark(target, mark, 0) end
                            end
                            if eligible then available[#available + 1] = mark end
                        end
                        if #available > 0 then
                            local mark = available[math.random(#available)]
                            room:setPlayerMark(target, mark, 1)
                            if mark == "@emjr_cc_state_curse" or mark == "@emjr_cc_state_paralysis" then
                                local attribute = mark == "@emjr_cc_state_curse" and "curse" or "paralysis"
                                applyTurnRestriction(room, target, attribute)
                            end
                            if mark == "@emjr_cc_state_chain" then room:setPlayerChained(target, true) end
                            if mark == "@emjr_cc_state_flip" then target:turnOver() end
                        end
                    end
                end)

            local treasureSkills = sgs.SkillList()
            for _, skill in ipairs({ damageDispatcher, jinglei, tianhuo, diyou, hundun, createStatusRule() }) do
                treasureSkills:append(skill)
            end
            for _, skill in ipairs(genericBeastGuard) do treasureSkills:append(skill) end
            sgs.Sanguosha:addSkills(treasureSkills)

            for _, spec in ipairs(M.beasts) do
                local general = sgs.General(extension, spec.key, "god", 6, false, true)
                general:addSkill(spec.skill)
                general:addSkill(spec.immunity)
                -- Game mode setup owns the side/beast marks; the general provides its matching item skill.
            end

            sgs.LoadTranslationTable {
                ["emjr_cc_bubing"] = "曹操傳步兵",
                ["emjr_cc_gongbing"] = "曹操傳弓兵",
                ["emjr_cc_hucheer"] = "曹操傳胡車兒",
                ["emjr_cc_huangjin"] = "曹操傳黃巾賊",
                ["emjr_cc_liru"] = "曹操傳李儒",
                ["emjr_cc_menghu"] = "曹操傳猛虎兵",
                ["emjr_cc_qibing"] = "曹操傳騎兵",
                ["emjr_cc_qiangbing"] = "曹操傳槍兵",
                ["emjr_cc_tengjia"] = "曹操傳藤甲兵",
                ["emjr_cc_tieqi"] = "曹操傳鐵騎兵",
                ["emjr_cc_xiandi"] = "獻帝",
                ["emjr_cc_zhangxiu"] = "張繡",
                ["emjr_cc_qinglong"] = "青龍",
                ["emjr_cc_baihu"] = "白虎",
                ["emjr_cc_zhuque"] = "朱雀",
                ["emjr_cc_xuanwu"] = "玄武",

                ["emjr_cc_renwang"] = "仁王",
                [":emjr_cc_renwang"] = "鎖定技，若你的防具欄沒有牌，你視為裝備【仁王盾】。",
                ["emjr_cc_yuanshe"] = "遠射",
                [":emjr_cc_yuanshe"] = "鎖定技，你使用【殺】無距離限制。",
                ["emjr_cc_duji"] = "毒擊",
                [":emjr_cc_duji"] = "鎖定技，你使用【殺】造成傷害後，目標獲得中毒；普通傷害改為毒傷，原有火焰或雷電屬性保留。",
                ["emjr_cc_fanji"] = "反擊",
                [":emjr_cc_fanji"] = "其他角色使用【殺】結算結束後，若此【殺】對你造成傷害且該角色在你的攻擊範圍內，你可以對其使用一張【殺】。",
                ["@emjr_cc_fanji"] = "你可以對 %src 使用一張【殺】",
                ["emjr_cc_baoyan"] = "爆炎",
                [":emjr_cc_baoyan"] = "鎖定技，你使用普通【殺】時，將其視為火【殺】。",
                ["emjr_cc_chuanji"] = "穿擊",
                [":emjr_cc_chuanji"] = "你使用【殺】結算結束後，若此【殺】對目標角色造成傷害，你可以視為對該角色座次上家或下家使用一張相同的【殺】。",
                ["@emjr_cc_chuanji"] = "你可以發動「穿擊」，選擇 %src 座次相鄰的一名角色",
                ["emjr_cc_jingkai"] = "鏡鎧",
                [":emjr_cc_jingkai"] = "鎖定技，若你的防具欄沒有牌，你視為裝備【黃金鎧】。",
                ["_emjr_cc_golden_armor"] = "黃金鎧",
                [":emjr_cc_golden_armor"] = "鎖定技，防止你受到的屬性傷害。",
                ["emjr_cc_huiqiang"] = "回槍",
                [":emjr_cc_huiqiang"] = "你使用的【殺】被【閃】抵消後，可以再使用一張【殺】；此【殺】無距離限制。",
                ["@emjr_cc_huiqiang"] = "你可以對 %src 再使用一張【殺】",
                ["emjr_cc_vine"] = "藤甲",
                [":emjr_cc_vine"] = "鎖定技，若你的防具欄沒有牌，你視為裝備【藤甲】。",
                ["emjr_cc_tiebi"] = "鐵壁",
                [":emjr_cc_tiebi"] = "鎖定技，其他角色計算與你的距離時+1；你計算與其他角色的距離時-1。",
                ["emjr_cc_huangming"] = "皇命",
                [":emjr_cc_huangming"] = "鎖定技，你不能使用【殺】或能造成傷害的錦囊牌；準備階段開始時，若你已受傷，你回復1點體力。",
                ["#emjr_cc_huangming-heal"] = "皇命",
                ["emjr_cc_yuanshi"] = "遠視",
                [":emjr_cc_yuanshi"] = "鎖定技，其他角色計算與你的距離時+1。",

                ["emjr_cc_jinglei"] = "驚雷",
                [":emjr_cc_jinglei"] = "你使用普通【殺】或雷【殺】結算完且實際對敵方造成傷害後，可以消耗1點靈氣，對除受傷敵方外的所有敵方角色各造成1點無來源雷電傷害。神獸發動此技能不消耗靈氣。",
                ["emjr_cc_diyou"] = "地佑",
                [":emjr_cc_diyou"] = "出牌階段限一次，你可以棄置一張基本牌，消耗1點靈氣，令所有友方角色各回復1點體力。神獸發動此技能不消耗靈氣。",
                ["emjr_cc_tianhuo"] = "天火",
                [":emjr_cc_tianhuo"] = "你使用普通【殺】或火【殺】結算完且實際對敵方造成傷害後，可以消耗1點靈氣，對除受傷敵方外的所有敵方角色各造成1點無來源火焰傷害。神獸發動此技能不消耗靈氣。",
                ["emjr_cc_hundun"] = "混沌",
                [":emjr_cc_hundun"] = "出牌階段限一次，你可以棄置一張錦囊牌，消耗1點靈氣，令所有敵方角色各隨機獲得一種其尚未有的狀態。神獸發動此技能不消耗靈氣。",
                ["emjr_cc_qinglong_guard"] = "青龍護佑",
                [":emjr_cc_qinglong_guard"] = "鎖定技，你防止雷電傷害。",
                ["emjr_cc_baihu_guard"] = "白虎護佑",
                [":emjr_cc_baihu_guard"] = "鎖定技，你受到的每次傷害至多為1點。",
                ["emjr_cc_zhuque_guard"] = "朱雀護佑",
                [":emjr_cc_zhuque_guard"] = "鎖定技，你防止火焰傷害。",
                ["emjr_cc_xuanwu_guard"] = "玄武護佑",
                [":emjr_cc_xuanwu_guard"] = "鎖定技，你防止普通【殺】造成的傷害。",
                ["emjr_cc_status_rule"] = "狀態結算",
                ["emjr_cc_damage_dispatcher"] = "曹操傳傷害結算",
                ["emjr_cc_diyouCard"] = "地佑",
                ["emjr_cc_hundunCard"] = "混沌",
                ["emjr_cc_chain_added"] = "連環狀態",
                ["@emjr_cc_spirit"] = "靈氣",
                ["@emjr_cc_treasure"] = "所持寶物",
                ["@emjr_cc_state_poison"] = "中毒",
                ["@emjr_cc_state_curse"] = "禁咒",
                ["@emjr_cc_state_paralysis"] = "麻痹",
                ["@emjr_cc_state_chain"] = "連環",
                ["@emjr_cc_state_flip"] = "翻面",
                ["@emjr_cc_state_poison.effect"] = "下個判定階段結束時進行判定：若結果為梅花，受到1點無來源普通傷害；然後移除此狀態",
                ["@emjr_cc_state_curse.effect"] = "若在你回合內施加，立即生效；否則於下回合開始生效。不能使用或重鑄錦囊牌（不限制回應），持續至下回合結束後解除",
                ["@emjr_cc_state_paralysis.effect"] = "若在你回合內施加，立即生效；否則於下回合開始生效。不能使用【殺】（不限制回應），持續至下回合結束後解除",
                ["@emjr_cc_state_chain.effect"] = "立即橫置；不會在回合結束時自動解除",
                ["@emjr_cc_state_flip.effect"] = "立即翻面；不會在回合結束時自動翻回",
            }

            M._installed = true
            return M.generals, M.beasts
        end

        return M
    end)()
    local caocao_campaign = (function()
        -- Cao Cao campaign rules. All mutable battle state belongs to the Room.
        local M = {}
        local catalog = caocao_catalog
        local treasures = { "emjr_cc_jinglei", "emjr_cc_diyou", "emjr_cc_tianhuo", "emjr_cc_hundun" }
        local beasts = { "emjr_cc_qinglong", "emjr_cc_baihu", "emjr_cc_zhuque", "emjr_cc_xuanwu" }
        local mode_stages = {}
        local hidden_mode = "3_emjr_cc_beast"

        local function has_bit(value, bit)
            return math.floor(value / bit) % 2 == 1
        end

        local function add_bit(value, bit)
            return has_bit(value, bit) and value or value + bit
        end

        local function log(room, kind, from, arg, arg2)
            local message = sgs.LogMessage()
            message.type, message.from = kind, from
            message.arg, message.arg2 = tostring(arg or ""), tostring(arg2 or "")
            room:sendLog(message)
        end

        local function profile_key(owner)
            -- Screen names are encoded so punctuation cannot create QSettings subgroups.
            local name = owner:screenName()
            local encoded = name:gsub(".", function(c) return string.format("%02x", string.byte(c)) end)
            return "EmjrCaocao/v1/" .. encoded
        end

        local function read_profile(key)
            local raw = sgs.GetConfig(key, "1:0:0:0:0")
            local version, cleared, lost, owned, pending = raw:match("^(%d+):(%d+):(%d+):(%d+):(%d+)$")
            version, cleared, lost, owned, pending = tonumber(version), tonumber(cleared), tonumber(lost), tonumber(owned), tonumber(pending)
            if version ~= 1 or not cleared or cleared > 30 or lost > 3 or owned > 15 or pending > 4 then
                return nil -- Preserve unknown/corrupt saves; never silently reset progress.
            end
            return { cleared = cleared, lost = lost, owned = owned, pending = pending, raw = raw }
        end

        local function write_profile(key, profile)
            -- Bit masks can come from exponentiation (a Lua float); save integer fields.
            profile.raw = string.format("1:%d:%d:%d:%d", profile.cleared, profile.lost, profile.owned, profile.pending)
            sgs.SetConfig(key, profile.raw)
        end

        local function eligible(name, profile)
            return not ((name == "dianwei" and has_bit(profile.lost, 1))
                or (name == "guojia" and has_bit(profile.lost, 2)))
        end

        local function resolve_roster(room, commander, stage, profile)
            local friends, enemies, used = {}, {}, {}
            -- Reserve fixed generals before choices, so a deputy cannot duplicate one.
            for _, list in ipairs({ stage.allies, stage.enemies }) do
                for _, name in ipairs(list) do
                    if name ~= "*" then
                        if not sgs.Sanguosha:getGeneral(name) then return nil, name end
                        used[name] = true
                    end
                end
            end
            for i, name in ipairs(stage.allies) do
                if name == "*" then
                    local choices = {}
                    for _, candidate in ipairs(catalog.allies) do
                        if not used[candidate] and eligible(candidate, profile) and sgs.Sanguosha:getGeneral(candidate) then
                            choices[#choices + 1] = candidate
                        end
                    end
                    if #choices == 0 then return nil, "emjr_cc_deputy" end
                    name = room:askForGeneral(commander, table.concat(choices, "+"))
                    local valid = false
                    for _, candidate in ipairs(choices) do if candidate == name then valid = true end end
                    if not valid then name = choices[1] end
                    used[name] = true
                end
                friends[i] = name
            end
            for i, name in ipairs(stage.enemies) do
                if name == "*" then
                    local choices = {}
                    for _, candidate in ipairs(catalog.enemies) do
                        if sgs.Sanguosha:getGeneral(candidate) then choices[#choices + 1] = candidate end
                    end
                    if #choices == 0 then return nil, "emjr_cc_soldier" end
                    name = choices[math.random(#choices)]
                end
                enemies[i] = name
            end
            return { friends = friends, enemies = enemies }
        end

        local function equip_treasure(room, commander, profile)
            local choices = { "emjr_cc_none" }
            for i, name in ipairs(treasures) do
                if has_bit(profile.owned, 2 ^ (i - 1)) then choices[#choices + 1] = name end
            end
            local choice = #choices > 1 and room:askForChoice(commander, "emjr_cc_treasure", table.concat(choices, "+")) or choices[1]
            room:setPlayerMark(commander, "@emjr_cc_spirit", 0)
            for i, name in ipairs(treasures) do
                if name == choice then
                    room:setPlayerMark(commander, "emjr_cc_treasure", i)
                    room:handleAcquireDetachSkills(commander, name)
                    log(room, "#EmjrCcTreasure", commander, name)
                end
            end
        end

        local function prepare(room, index)
            local owner = room:getOwner() or room:getLord()
            if not owner then return false end
            local key = profile_key(owner)
            local profile = read_profile(key)
            if not profile then
                log(room, "#EmjrCcSaveInvalid", owner)
                room:gameOver(".")
                return false
            end
            local hidden = room:getMode() == hidden_mode
            if (hidden and profile.pending == 0) or (not hidden and profile.cleared < 30 and index ~= profile.cleared + 1) then
                log(room, hidden and "#EmjrCcNoEncounter" or "#EmjrCcLocked", owner, math.min(30, profile.cleared + 1))
                room:gameOver(".")
                return false
            end
            local stage = hidden and { allies = { "caocao", "*" }, enemies = { beasts[profile.pending] }, commander = 1, protect = { 1 } }
                or catalog.stages[index]
            local roster, missing = resolve_roster(room, owner, stage, profile)
            if not roster then
                log(room, "#EmjrCcMissingGeneral", owner, missing)
                room:gameOver(".")
                return false
            end
            local players = sgs.QList2Table(room:getPlayers())
            if #players ~= #roster.friends + #roster.enemies then
                log(room, "#EmjrCcRosterInvalid", owner)
                room:gameOver(".")
                return false
            end
            -- The host controls the protected commander, including the middle-seat maps.
            if players[stage.commander]:objectName() ~= owner:objectName() then
                room:swapSeat(owner, players[stage.commander])
                players = sgs.QList2Table(room:getPlayers())
            end
            room:setTag("emjr_cc_profile_key", sgs.QVariant(key))
            room:setTag("emjr_cc_stage", sgs.QVariant(index or 0))
            room:setTag("emjr_cc_encounter", sgs.QVariant(hidden and profile.pending or 0))
            room:setTag("emjr_cc_commander", sgs.QVariant(owner:objectName()))
            room:setTag("emjr_cc_lost", sgs.QVariant(0))
            if not hidden and profile.pending > 0 then
                log(room, "#EmjrCcSkipEncounter", owner, beasts[profile.pending])
                profile.pending = 0
                write_profile(key, profile)
            end
            room:setTag("emjr_cc_profile_snapshot", sgs.QVariant(profile.raw))
            for i, player in ipairs(players) do
                local friendly = i <= #roster.friends
                local name = friendly and roster.friends[i] or roster.enemies[i - #roster.friends]
                local role = friendly and (i == stage.commander and "lord" or "loyalist") or "rebel"
                room:setPlayerProperty(player, "role", sgs.QVariant(role))
                room:setPlayerMark(player, "emjr_cc_side", friendly and 1 or 2)
                room:setPlayerMark(player, "emjr_cc_treasure", 0)
                room:setPlayerMark(player, "@emjr_cc_spirit", 0)
                room:changeHero(player, name, true, false, false, false)
                if friendly then
                    for _, protected in ipairs(stage.protect) do
                        if protected == i then room:setPlayerMark(player, "emjr_cc_protected", 1) end
                    end
                    if stage.loss and name == stage.loss then
                        room:setPlayerMark(player, "emjr_cc_retirement", stage.loss == "dianwei" and 1 or 2)
                    end
                else
                    if hidden then
                        room:setPlayerMark(player, "emjr_cc_beast", 1)
                        room:setPlayerMark(player, "emjr_cc_treasure", profile.pending)
                    end
                    if stage.target == name then room:setPlayerMark(player, "emjr_cc_target", 1) end
                end
            end
            room:updateStateItem()
            equip_treasure(room, owner, profile)
            room:setTag("emjr_cc_ready", sgs.QVariant(true))
            log(room, "#EmjrCcStage", owner, hidden and beasts[profile.pending] or "emjr_cc_stage_" .. index,
                tostring(profile.cleared) .. "/30")
            log(room, "#EmjrCcObjective", owner, stage.target and "emjr_cc_kill_target" or "emjr_cc_eliminate",
                not hidden and index == 7 and "emjr_cc_protect_emperor" or "emjr_cc_protect_commander")
            return true
        end

        local function record_death(room, death)
            if not death or not death.who then return end
            local victim = death.who
            local token = "emjr_cc_death_" .. victim:objectName()
            if room:getTag(token):toBool() then return end
            room:setTag(token, sgs.QVariant(true))
            local loss = victim:getMark("emjr_cc_retirement")
            if loss > 0 then
                room:setTag("emjr_cc_lost", sgs.QVariant(add_bit(room:getTag("emjr_cc_lost"):toInt(), loss)))
            end
            local killer = death.damage and death.damage.from
            if killer and killer:objectName() ~= victim:objectName() and killer:getMark("emjr_cc_treasure") > 0
                and killer:getMark("emjr_cc_beast") == 0 then
                room:setPlayerMark(killer, "@emjr_cc_spirit", math.min(3, killer:getMark("@emjr_cc_spirit") + 1))
            end
        end

        local function winner(room)
            local enemies, target_alive, target_exists = 0, false, false
            -- Check every protected seat before accepting a completed victory objective.
            for _, player in sgs.qlist(room:getAllPlayers(true)) do
                if player:getMark("emjr_cc_protected") > 0 and player:isDead() then return "rebel" end
                if player:getMark("emjr_cc_side") == 2 and player:isAlive() then enemies = enemies + 1 end
                if player:getMark("emjr_cc_target") > 0 then
                    target_exists = true
                    target_alive = player:isAlive()
                end
            end
            if enemies == 0 or (target_exists and not target_alive) then return "lord+loyalist" end
            return ""
        end

        local function settle(room, result)
            if room:getTag("emjr_cc_saved"):toBool() then return end
            room:setTag("emjr_cc_saved", sgs.QVariant(true))
            local key = room:getTag("emjr_cc_profile_key"):toString()
            local profile = read_profile(key)
            if not profile or profile.raw ~= room:getTag("emjr_cc_profile_snapshot"):toString() then
                log(room, "#EmjrCcSaveConflict", nil)
                return
            end
            local encounter = room:getTag("emjr_cc_encounter"):toInt()
            -- Only a result produced by the campaign objective can grant progress/rewards.
            local won = result == "lord+loyalist" and room:getTag("emjr_cc_result"):toString() == result
            if encounter > 0 then
                if result == "." or result == "" then return end
                profile.pending = 0
                if won then
                    profile.owned = add_bit(profile.owned, 2 ^ (encounter - 1))
                    log(room, "#EmjrCcReward", nil, treasures[encounter])
                end
            elseif won then
                local index = room:getTag("emjr_cc_stage"):toInt()
                if profile.cleared < 30 then
                    if index ~= profile.cleared + 1 then return end
                    profile.cleared = index
                    local loss = room:getTag("emjr_cc_lost"):toInt()
                    for _, bit in ipairs({ 1, 2 }) do
                        if has_bit(loss, bit) then profile.lost = add_bit(profile.lost, bit) end
                    end
                end
                -- Unspecified encounter probability defaults to 20%; never roll on defeat.
                if index < 30 and math.random(100) <= catalog.beast_chance then
                    local candidates = {}
                    for i = 1, 4 do if not has_bit(profile.owned, 2 ^ (i - 1)) then candidates[#candidates + 1] = i end end
                    if #candidates > 0 then
                        profile.pending = candidates[math.random(#candidates)]
                        log(room, "#EmjrCcEncounter", nil, beasts[profile.pending])
                    end
                end
                log(room, profile.cleared == 30 and "#EmjrCcComplete" or "#EmjrCcNext", nil,
                    math.min(profile.cleared + 1, 30))
            else
                return -- Defeat/abort cannot advance a normal stage or retire a deputy.
            end
            write_profile(key, profile)
        end

        function M.install(extension)
            caocao_skills.install(extension)
            local translations = {
                emjr_cc_campaign = "曹操传", emjr_cc_beast = "曹操传·神兽挑战",
                emjr_cc_treasure = "宝物", emjr_cc_none = "不装备宝物",
                emjr_cc_deputy = "副将", emjr_cc_soldier = "兵种",
                emjr_cc_kill_target = "击败张角", emjr_cc_eliminate = "全歼敌人",
                emjr_cc_protect_commander = "主将阵亡即失败", emjr_cc_protect_emperor = "曹操或献帝阵亡即失败",
                ["#EmjrCcStage"] = "%from 进入【%arg】（已通关 %arg2）。",
                ["#EmjrCcObjective"] = "胜利条件：%arg；失败条件：%arg2。",
                ["#EmjrCcLocked"] = "%from 尚未解锁此关，请先挑战第 %arg 关；全部通关后可自由选关。",
                ["#EmjrCcNoEncounter"] = "%from 目前没有待挑战的神兽。",
                ["#EmjrCcTreasure"] = "%from 装备宝物【%arg】，初始灵气为0，上限为3。",
                ["#EmjrCcReward"] = "神兽挑战成功，获得宝物【%arg】。",
                ["#EmjrCcEncounter"] = "发现神兽【%arg】！开始下一普通关前，可在曹操传分组选择「神兽挑战」。",
                ["#EmjrCcSkipEncounter"] = "%from 开始普通关卡，跳过本次【%arg】挑战。",
                ["#EmjrCcNext"] = "进度已保存，下次请选择曹操传第 %arg 关。",
                ["#EmjrCcComplete"] = "曹操传30关全部通关！现可自由选择任意关卡。",
                ["#EmjrCcSaveInvalid"] = "%from 的曹操传存档格式无法识别，已保留原存档并停止开局。",
                ["#EmjrCcSaveConflict"] = "曹操传进度已被另一房间修改，本局结果未覆盖存档。",
                ["#EmjrCcMissingGeneral"] = "曹操传所需武将【%arg】未加载，已停止开局。",
                ["#EmjrCcRosterInvalid"] = "曹操传房间人数与本关阵容不符，已停止开局。",
            }
            for i, stage in ipairs(catalog.stages) do translations["emjr_cc_stage_" .. i] = stage.name end
            sgs.LoadTranslationTable(translations)
            local ids = {}
            for i, stage in ipairs(catalog.stages) do
                local roles = {}
                for seat = 1, #stage.allies do roles[#roles + 1] = seat == stage.commander and "Z" or "C" end
                for _ = 1, #stage.enemies do roles[#roles + 1] = "F" end
                createMode {
                    name = string.format("曹操传·%02d %s", i, stage.name), class = string.format("emjr_cc%02d", i),
                    roles = table.concat(roles), skipChooseGeneral = true, shuffleSeats = false,
                    showRole = true, lordWelfare = false, rewardPolicy = "none",
                    teams = { friendly = { "lord", "loyalist" }, hostile = { "rebel" } },
                    getWinner = function() return "" end,
                }
                -- createMode writes callbacks even when Room VM registration finds an existing ID.
                local id = (#stage.allies + #stage.enemies) .. "_" .. string.format("emjr_cc%02d", i)
                mode_stages[id] = i
                ids[#ids + 1] = id
            end
            createMode {
                name = sgs.Sanguosha:translate("emjr_cc_beast"), class = "emjr_cc_beast", roles = "ZCF",
                skipChooseGeneral = true, shuffleSeats = false, showRole = true, lordWelfare = false,
                rewardPolicy = "none", teams = { friendly = { "lord", "loyalist" }, hostile = { "rebel" } },
                getWinner = function() return "" end,
            }
            ids[#ids + 1] = hidden_mode
            if not sgs.Sanguosha:isGameLuaRuntime() then
                sgs.Sanguosha:addModeGroup(sgs.Sanguosha:translate("emjr_cc_campaign"), ids)
            end
            local rule = sgs.CreateRuleSkillV2 {
                name = "#emjr_cc_campaign_rule", global = true, priority = 5, frequency = sgs.Skill_Compulsory,
                events = { sgs.GameReady, sgs.GameOverJudge, sgs.GameOver },
                can_trigger = function(self, event, room, player, data)
                    if not mode_stages[room:getMode()] and room:getMode() ~= hidden_mode then return end
                    if event == sgs.GameReady then
                        if player or room:getTag("emjr_cc_ready"):toBool() then return end
                    elseif not room:getTag("emjr_cc_ready"):toBool() then return end
                    return self:objectName(), player or room:getOwner() or room:getAllPlayers(true):first()
                end,
                on_record = function(self, event, room, player, ctx)
                    if event == sgs.GameOverJudge and room:getTag("emjr_cc_ready"):toBool()
                        and (mode_stages[room:getMode()] or room:getMode() == hidden_mode) then
                        record_death(room, ctx.original_data:toDeath())
                    end
                end,
                on_effect = function(self, event, room, player, ctx)
                    if event == sgs.GameReady then
                        prepare(room, mode_stages[room:getMode()])
                    elseif event == sgs.GameOverJudge then
                        local result = winner(room)
                        if result ~= "" then
                            room:setTag("emjr_cc_result", sgs.QVariant(result))
                            room:gameOver(result)
                        end
                    elseif event == sgs.GameOver then
                        settle(room, ctx.original_data:toString())
                    end
                    return false
                end,
            }
            local skills = sgs.SkillList()
            if not sgs.Sanguosha:getSkill(rule:objectName()) then skills:append(rule) end
            sgs.Sanguosha:addSkills(skills)
        end

        return M
    end)()
    caocao_campaign.install(extension)
end

--程昱
echengyu = sgs.General(extension, "echengyu", "wei", "3")
--程昱【伏杀】
--出牌阶段限一次，你可以将一张手牌背面朝上移出游戏并选择一名其他角色，
--若如此做，该角色的回合开始时，其选择一种花色后将此牌置入弃牌堆，
--若此牌的花色与其所选的不同，你视为对其使用一张【杀】。
efushaCard = sgs.CreateSkillCard {
	name = "efusha",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if #targets == 0 then
			local efushalist = to_select:getPile("efusha")
			if efushalist:isEmpty() then
				return to_select:objectName() ~= player:objectName()
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local cards = self:getSubcards()
		for _, id in sgs.qlist(cards) do
			local keystr = string.format("EFushaSource%d", id)
			local tag = sgs.QVariant()
			tag:setValue(source)
			room:setTag(keystr, tag)
			target:addToPile("efusha", id, false)
		end
	end,
}
efushaVS = sgs.CreateViewAsSkillV2 {
	name = "efusha",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not (player:hasUsed("#efusha") or player:hasUsed("efusha"))
	end,
	can_select_card = function(skill, request, candidate)
		return candidate and not candidate:isEquipped() and request:getSelectedCardIds():isEmpty()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		if request:getSelectedCardIds():length() ~= 1 then return nil end
		local acard = efushaCard:clone()
		for _, id in sgs.qlist(request:getSelectedCardIds()) do
			acard:addSubcard(id)
		end
		acard:setSkillName(skill:objectName())
		return acard
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then
			room:addPlayerHistory(source, "#efusha")
		end
		return true
	end,
}
efusha = sgs.CreateTriggerSkillV2 {
	name = "efusha",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = efushaVS,
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_RoundStart then return false end
		if player:getPile("efusha"):isEmpty() then return false end
		local holders = room:findPlayersBySkillName(skill:objectName())
		if holders:isEmpty() then return false end
		return skill:objectName(), holders:first():objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		local efusha_list = target:getPile("efusha")
		if efusha_list:length() > 0 then
			if target:getGeneralName() == "yuanshao" then
				room:broadcastSkillInvoke(skill:objectName(), 3)
			else
				room:broadcastSkillInvoke(skill:objectName(), 2)
			end
			while not efusha_list:isEmpty() do
				local card_id = efusha_list:first()
				local keystr = string.format("EFushaSource%d", card_id)
				local tag = room:getTag(keystr)
				local chengyu = tag:toPlayer()
				local cd = sgs.Sanguosha:getCard(card_id)
				local suit = room:askForSuit(target, skill:objectName())
				local suit_str = { "spade", "club", "heart", "diamond" }
				local log = sgs.LogMessage()
				log.type = "#efusha"
				log.from = target
				log.arg = skill:objectName()
				log.arg2 = suit_str[suit + 1]
				room:sendLog(log)
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", skill:objectName(), "")
				room:throwCard(cd, reason, nil)
				if cd:getSuit() ~= suit then
					if chengyu:canSlash(target, nil, false) then
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
						slash:setSkillName("_efusha")
						local card_use = sgs.CardUseStruct()
						card_use.from = chengyu
						card_use.to:append(target)
						card_use.card = slash
						room:useCard(card_use, false)
						slash:deleteLater()
					end
				end
				efusha_list:removeOne(card_id)
				room:removeTag(keystr)
			end
		end
		return false
	end,
}
--程昱【危城】
--每当你成为其他角色使用的【杀】或非延时类锦囊牌的目标后，若你有手牌，
--你可以依次弃置该角色的X张牌（X为你已损失的体力值且至少为1）。
eweichengDummyCard = sgs.CreateSkillCard {
	name = "eweichengDummyCard",
}
eweicheng = sgs.CreateTriggerSkillV2 {
	name = "eweicheng",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.TargetConfirmed },
	can_trigger = function(skill, event, room, player, data)
		local use = data:toCardUse()
		local card = use.card
		if not (card:isKindOf("Slash") or card:isNDTrick()) then return false end
		if not player:isAlive() or not player:hasSkill(skill:objectName()) then return false end
		local source = use.from
		if not source or source:objectName() == player:objectName() then return false end
		if not use.to:contains(player) then return false end
		if player:isKongcheng() then return false end
		if not player:canDiscard(source, "he") then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		return room:askForSkillInvoke(player, skill:objectName(), ToData(use.from))
	end,
	on_effect = function(skill, event, room, player, ctx)
		local use = ctx.original_data:toCardUse()
		local source = use.from
		if source:getGeneralName() == "yuanshao" then
			room:broadcastSkillInvoke(skill:objectName(), 2)
		else
			room:broadcastSkillInvoke(skill:objectName(), 1)
		end
		local losthp = math.max(player:getLostHp(), 1)
		local count = 0
		while count < losthp and player:canDiscard(source, "he") do
			local to_throw = room:askForCardChosen(player, source, "he", skill:objectName(), false, sgs.Card_MethodDiscard)
			local card = sgs.Sanguosha:getCard(to_throw)
			room:throwCard(card, source, player)
			count = count + 1
		end
		return false
	end,
}
echengyu:addSkill(efusha)
echengyu:addSkill(eweicheng)

--李典
elidian = sgs.General(extension, "elidian", "wei", "4")
--李典【郄縠】
--其他角色的摸牌阶段结束后，你可以弃置一张基本牌，令该角色摸两张牌；
--其他角色的弃牌阶段结束后，你可以弃置一张非基本牌，令该角色弃置两张牌。
eqiehu = sgs.CreateTriggerSkillV2 {
	name = "eqiehu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		if player:isDead() or player:hasSkill(skill:objectName()) then return false end
		local change = data:toPhaseChange()
		if change.from ~= sgs.Player_Draw and change.from ~= sgs.Player_Discard then return false end
		local names, owners = {}, {}
		for _, lidian in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if not lidian:isNude() then
				names[#names + 1] = skill:objectName()
				owners[#owners + 1] = lidian:objectName()
			end
		end
		if #names == 0 then return false end
		return table.concat(names, "|"), table.concat(owners, "|")
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		local change = ctx.original_data:toPhaseChange()
		if change.from == sgs.Player_Draw then
			local prompt = string.format("@eqiehu1:%s", target:objectName())
			return room:askForCard(player, "BasicCard", prompt, ctx.original_data, "eqiehu") ~= nil
		elseif change.from == sgs.Player_Discard then
			local prompt = string.format("@eqiehu2:%s", target:objectName())
			return room:askForCard(player, "EquipCard,TrickCard", prompt, ctx.original_data, "eqiehu") ~= nil
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		local change = ctx.original_data:toPhaseChange()
		if change.from == sgs.Player_Draw then
			if target:getGeneralName() == "zhangliao" or target:getGeneralName() == "kof_zhangliao" then
				room:broadcastSkillInvoke(skill:objectName(), 2)
			else
				room:broadcastSkillInvoke(skill:objectName(), 1)
			end
			room:drawCards(target, 2, "eqiehu")
		elseif change.from == sgs.Player_Discard then
			if target:getGeneralName() == "sunquan" or target:getGeneralName() == "zhiba_sunquan" then
				room:broadcastSkillInvoke(skill:objectName(), 4)
			else
				room:broadcastSkillInvoke(skill:objectName(), 3)
			end
			room:askForDiscard(target, "eqiehu", 2, 2, false, true)
		end
		return false
	end,
}
elidian:addSkill(eqiehu)

--周仓
ezhoucang = sgs.General(extension, "ezhoucang", "shu", "4")
--周仓【护武】
--护武——每当其他角色主动使用的红色的【杀】和红色非延时类锦囊牌结算结束后，你可以进行判定，
--若判定结果不为红桃，你选择一项：1.获得处理区里的此牌；2.令该角色摸一张牌。
ehuwu = sgs.CreateTriggerSkillV2 {
	name = "ehuwu",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.CardUsed, sgs.CardFinished },
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.CardFinished then return false end
		if player:hasSkill(skill:objectName()) then return false end
		local use = data:toCardUse()
		if not use.card:hasFlag("ehuwuable") then return false end
		local names, owners = {}, {}
		for _, zhoucang in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			names[#names + 1] = skill:objectName()
			owners[#owners + 1] = zhoucang:objectName()
		end
		if #names == 0 then return false end
		return table.concat(names, "|"), table.concat(owners, "|")
	end,
	on_record = function(skill, event, room, player, ctx)
		if event ~= sgs.CardUsed then return end
		if player:hasSkill(skill:objectName()) then return end
		if player:getPhase() ~= sgs.Player_Play then return end
		local card = ctx.original_data:toCardUse().card
		if card:isRed() and (card:isKindOf("Slash") or card:isNDTrick()) and not card:isKindOf("Nullification") then
			room:setCardFlag(card, "ehuwuable")
		end
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local user = ctx.invoker
		local use = ctx.original_data:toCardUse()
		local card = use.card
		local userName = user:getGeneralName()
		if userName == "guanyu" or userName == "sp_guanyu" or userName == "shenguanyu" or userName == "neo_guanyu" then
			room:broadcastSkillInvoke(skill:objectName(), 3)
		elseif card:isNDTrick() then
			room:broadcastSkillInvoke(skill:objectName(), 2)
		else
			room:broadcastSkillInvoke(skill:objectName(), 1)
		end
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|heart"
		judge.good = false
		judge.reason = skill:objectName()
		judge.who = player
		room:judge(judge)
		if judge:isGood() then
			local id = card:getEffectiveId()
			local choice
			if not (room:getCardPlace(id) ~= sgs.Player_DiscardPile or user:isDead()) then
				choice = room:askForChoice(player, skill:objectName(), "ehuwu1=" .. card:objectName() .. "+ehuwu2=" .. user:objectName(), ctx.original_data)
			elseif user:isDead() then
				choice = "ehuwu1=" .. card:objectName()
			else
				choice = "ehuwu2=" .. user:objectName()
			end
			if choice:startsWith("ehuwu1") then
				player:obtainCard(card)
			elseif choice:startsWith("ehuwu2") then
				user:drawCards(1)
			end
		end
		return false
	end,
}
ezhoucang:addSkill(ehuwu)

--张星彩
ezhangxingcai = sgs.General(extension, "ezhangxingcai", "shu", "3", false)
--张星彩【持内】
--摸牌阶段，若你已受伤，你可以少摸一张牌，亮出牌堆顶的X+1张牌（X为你已损失的体力值），
--你将其中任意数量的牌交给一名其他角色，然后获得其余的牌。
echineiGive = sgs.CreateTriggerSkillV2 {
	name = "#echineiGive",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.AfterDrawNCards },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() and player:hasFlag("echinei") then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if player:hasFlag("echinei") then
			player:setFlags("-echinei")
			local x = player:getLostHp() + 1
			local card_ids = room:getNCards(x)
			room:fillAG(card_ids)
			local to_give = sgs.IntList()
			while true do
				if card_ids:isEmpty() then
					break
				end
				local card_id = room:askForAG(player, card_ids, true, "echinei")
				if card_id == -1 then
					break
				end
				card_ids:removeOne(card_id)
				to_give:append(card_id)
				room:takeAG(player, card_id, false)
				if card_ids:isEmpty() then
					break
				end
			end
			local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if not to_give:isEmpty() then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "echinei")
				for _, id in sgs.qlist(to_give) do
					dummy:addSubcard(id)
				end
				target:obtainCard(dummy)
			end
			dummy:clearSubcards()
			if not card_ids:isEmpty() then
				for _, id in sgs.qlist(card_ids) do
					dummy:addSubcard(id)
				end
				player:obtainCard(dummy)
			end
			dummy:deleteLater()
			room:clearAG()
		end
		return false
	end,
}
echinei = sgs.CreateTriggerSkillV2 {
	name = "echinei",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.DrawNCards },
	can_trigger = function(skill, event, room, player, data)
		if not player:isAlive() or not player:isWounded() then return false end
		local draw = data:toDraw()
		if draw.reason ~= "draw_phase" or draw.num <= 0 then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName())
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		local draw = ctx.original_data:toDraw()
		draw.num = draw.num - 1
		player:setFlags(skill:objectName())
		ctx.original_data:setValue(draw)
		return false
	end,
}
--张星彩【攘外】
--一名角色的结束阶段开始时，若该角色于此回合内未使用过基本牌和锦囊牌，
--你可以弃置一张基本牌，视为对其攻击范围内的另一名其他角色使用一张【杀】。
erangwaiCard = sgs.CreateSkillCard {
	name = "erangwaiCard",
	filter = function(self, targets, to_select, player)
		local players = player:getSiblings()
		local current
		players:append(player)
		for _, p in sgs.qlist(players) do
			if p:getPhase() ~= sgs.Player_NotActive then
				current = p
				break
			end
		end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("erangwai")
		local extra = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, player, slash) + 1
		slash:deleteLater()
		return player:canSlash(to_select, slash, false) and #targets < extra and current:distanceTo(to_select) <= current:getAttackRange() and current:distanceTo(to_select) > 0
	end,
	on_use = function(self, room, source, targets)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local change = sgs.SPlayerList()
		slash:setSkillName("_erangwai")
		for _, play in ipairs(targets) do
			change:append(play)
		end
		local use = sgs.CardUseStruct()
		use.card = slash
		use.to = change
		use.from = source
		local current = room:getCurrent()
		if current:getGeneralName() == "liushan" then
			room:broadcastSkillInvoke("erangwai", 3)
		else
			room:broadcastSkillInvoke("erangwai", math.random(1, 2))
		end
		room:useCard(use)
		slash:deleteLater()
	end,
}
erangwaiVS = sgs.CreateViewAsSkillV2 {
	name = "erangwai",
	n = 1,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		local reason = request:getReason()
		if reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			and reason ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			return false
		end
		return request:getPattern() == "@@erangwai" and sgs.Slash_IsAvailable(player)
	end,
	can_select_card = function(skill, request, candidate)
		return candidate and candidate:isKindOf("BasicCard") and request:getSelectedCardIds():isEmpty()
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():length() == 1
	end,
	create_card = function(skill, request)
		local ids = request:getSelectedCardIds()
		if ids:length() ~= 1 then return nil end
		local card = erangwaiCard:clone()
		card:addSubcard(ids:first())
		return card
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then
			room:addPlayerHistory(source, "#erangwaiCard")
		end
		return true
	end,
}
-- "未使用过基本牌和锦囊牌" is a journal fact; query it instead of self-marking a flag.
-- Unknown (incomplete history) is not proof of a clean turn, so the skill stays silent.
local function erangwaiUsedCleanCard(room, player)
	local turn = room:historyScopes().turn_id
	if not turn or turn == "0" then return true end
	local filter = { kind = "use_card", turn_id = turn, from = player:objectName(), limit = 64 }
	while true do
		local page = room:queryHistoryFacts(filter)
		if page.error or not page.complete then return true end
		for _, fact in ipairs(page.items) do
			local card = fact.data and fact.data.card
			if not card or not card.classes then return true end
			if table.contains(card.classes, "BasicCard") or table.contains(card.classes, "TrickCard") then
				return true
			end
		end
		if not page.has_more then return false end
		filter.watermark = filter.watermark or page.watermark
		filter.after = page.next_after
	end
end
erangwai = sgs.CreateTriggerSkillV2 {
	name = "erangwai",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	view_as_skill = erangwaiVS,
	can_trigger = function(skill, event, room, player, data)
		if event ~= sgs.EventPhaseStart then return false end
		if player:getPhase() ~= sgs.Player_Finish then return false end
		if erangwaiUsedCleanCard(room, player) then return false end
		local names, owners = {}, {}
		for _, zhangxingcai in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			names[#names + 1] = skill:objectName()
			owners[#owners + 1] = zhangxingcai:objectName()
		end
		if #names == 0 then return false end
		return table.concat(names, "|"), table.concat(owners, "|")
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseStart then
			room:askForUseCard(player, "@@erangwai", "@erangwai", -1, sgs.Card_MethodDiscard)
		end
		return false
	end,
}
ezhangxingcai:addSkill(echinei)
ezhangxingcai:addSkill(echineiGive)
extension:insertRelatedSkills("echinei", "#echineiGive")
ezhangxingcai:addSkill(erangwai)

--陆抗
elukang = sgs.General(extension, "elukang", "wu", "3")
--陆抗【堰守】
--出牌阶段限一次，你可以令一名角色弃置其装备区里的所有牌，然后该角色摸X+1张牌（X为其以此法弃置的装备牌数量）。
eyanshouCard = sgs.CreateSkillCard {
	name = "eyanshouCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets < 1
	end,
	on_effect = function(self, effect)
		local target = effect.to
		local equips = target:getEquips()
		local x = equips:length()
		target:throwAllEquips()
		target:drawCards(x + 1)
	end,
}
eyanshou = sgs.CreateViewAsSkillV2 {
	name = "eyanshou",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not (player:hasUsed("#eyanshouCard") or player:hasUsed("eyanshou"))
	end,
	can_select_card = function(skill, request, candidate)
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local card = eyanshouCard:clone()
		card:setSkillName(skill:objectName())
		return card
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then
			room:addPlayerHistory(source, "#eyanshouCard")
		end
		return true
	end,
}
--陆抗【克构】
--若有其他角色手牌不比你少，你可以跳过你的弃牌阶段。
ekegou = sgs.CreateTriggerSkillV2 {
	name = "ekegou",
	frequency = sgs.Skill_Frequent,
	events = { sgs.EventPhaseChanging },
	can_trigger = function(skill, event, room, player, data)
		if not player:isAlive() then return false end
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Discard then return false end
		for _, p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getHandcardNum() >= player:getHandcardNum() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName())
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		player:skip(sgs.Player_Discard)
		return false
	end,
}
elukang:addSkill(eyanshou)
elukang:addSkill(ekegou)

--诸葛恪
ezhugeke = sgs.General(extension, "ezhugeke", "wu", "4")
--诸葛恪【急思】
--每当你需要使用【无懈可击】时，你可以与当前回合角色拼点。若你赢，你视为使用一张【无懈可击】。每回合限一次。
ejisiCard = sgs.CreateSkillCard {
	name = "ejisiCard",
	target_fixed = true,
	will_throw = false,
	on_validate_in_response = function(self, player)
		local room = player:getRoom()
		local target = room:getCurrent()
		room:setPlayerFlag(player, "ejisiUsed")
		if target and player:pindian(target, "ejisi", nil) then
			room:broadcastSkillInvoke("ejisi", math.random(2, 3))
			local nullification = sgs.Sanguosha:cloneCard("nullification", sgs.Card_NoSuit, 0)
			nullification:toTrick():setCancelable(false)
			nullification:setSkillName("_ejisi")
			return nullification
		else
			room:broadcastSkillInvoke("ejisi", 4)
		end
		return nil
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local room = player:getRoom()
		local target = room:getCurrent()
		room:setPlayerFlag(player, "ejisiUsed")
		if target and player:pindian(target, "ejisi", nil) then
			room:broadcastSkillInvoke("ejisi", math.random(2, 3))
			local nullification = sgs.Sanguosha:cloneCard("nullification", sgs.Card_NoSuit, 0)
			nullification:toTrick():setCancelable(false)
			nullification:setSkillName("_ejisi")
			return nullification
		else
			room:broadcastSkillInvoke("ejisi", 4)
		end
		return nil
	end,
}
-- DEFER:ejisi:view-as stays legacy — it only answers "nullification" asks, which are gated
-- by ServerPlayer::hasNullification() calling ViewAsSkill::isEnabledAtResponse;
-- LuaViewAsSkillV2 cannot set response_pattern, so migrating would silently drop holders
-- from nullification races. Its validate also mixes the ejisiUsed flag, a pindian and a
-- card replacement (LegacyValidateLimited). Deferred until a V2 nullification-response path exists.
ejisiVS = sgs.CreateViewAsSkill {
	name = "ejisi",
	n = 0,
	view_as = function(self, cards)
		local card = ejisiCard:clone()
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		for _, target in sgs.list(player:getAliveSiblings()) do
			if target:hasFlag("CurrentPlayer") and target:getPhase() ~= sgs.Player_NotActive then
				if player:canPindian(target) then
					if target:objectName() ~= player:objectName() then
						return not player:hasFlag("ejisiUsed") and pattern == "nullification"
					end
				end
			end
		end
		return false
	end,
	enabled_at_nullification = function(self, player)
		local room = player:getRoom()
		local target = room:getCurrent()
		if not target or target:isDead() or target:getPhase() == sgs.Player_NotActive then
			return false
		end
		if player:canPindian(target) then
			if target:objectName() ~= player:objectName() then
				return not player:hasFlag("ejisiUsed")
			end
		end
		return false
	end,
}
ejisi = sgs.CreateTriggerSkillV2 {
	name = "ejisi",
	events = { sgs.EventPhaseChanging },
	view_as_skill = ejisiVS,
	can_trigger = function(skill, event, room, player, data)
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		local holders = room:findPlayersBySkillName(skill:objectName())
		if holders:isEmpty() then return false end
		return skill:objectName(), holders:first():objectName()
	end,
	on_effect = function(skill, event, room, player, ctx)
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasFlag("ejisiUsed") then
				room:setPlayerFlag(p, "-ejisiUsed")
			end
		end
		return false
	end,
}
--诸葛恪【强辩】
--锁定技，每当你与一名角色拼点时，你令该角色用你选择的其一张手牌拼点。
--[[eqiangbian = sgs.CreateTriggerSkill{
	name = "eqiangbian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Pindian},
	on_trigger = function(self, event, player, data)
		
	end
}]]

eqiangbian = sgs.CreateTriggerSkillV2 {
	name = "eqiangbian",
	events = { sgs.AskforPindianCard },
	can_trigger = function(skill, event, room, player, data)
		if not player:isAlive() then return false end
		local pindian = data:toPindian()
		if not pindian then return false end
		local names, owners = {}, {}
		for _, p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasSkill(skill:objectName())
				and ((pindian.from and pindian.from:objectName() == p:objectName())
					or (pindian.to and pindian.to:objectName() == p:objectName())) then
				names[#names + 1] = skill:objectName()
				owners[#owners + 1] = p:objectName()
			end
		end
		if #names == 0 then return false end
		return table.concat(names, "|"), table.concat(owners, "|")
	end,
	on_cost = function(skill, event, room, player, ctx)
		local pindian = ctx.original_data:toPindian()
		if not pindian then return false end
		if pindian.from and pindian.from:objectName() == player:objectName() then
			if pindian.to_card then return false end
			if pindian.to:isDead() or pindian.to:isKongcheng() then return false end
			return player:askForSkillInvoke(skill:objectName(), pindian.to)
		end
		if pindian.to and pindian.to:objectName() == player:objectName() then
			if pindian.from_card then return false end
			if pindian.from:isDead() or pindian.from:isKongcheng() then return false end
			return player:askForSkillInvoke(skill:objectName(), pindian.from)
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local pindian = ctx.original_data:toPindian()
		if not pindian then return false end
		if pindian.from and pindian.from:objectName() == player:objectName() then
			if pindian.to_card then return false end
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			pindian.to_card = pindian.to:getRandomHandCard()
		elseif pindian.to and pindian.to:objectName() == player:objectName() then
			if pindian.from_card then return false end
			room:sendCompulsoryTriggerLog(player, skill:objectName())
			pindian.from_card = pindian.from:getRandomHandCard()
		end
		return false
	end,
}

--诸葛恪【傲才】
--限定技，回合结束时，你可以令手牌比你多的所有角色各选择一项：1.交给你一张牌；2.弃置两张牌。然后你获得技能“专权”（其他角色的弃牌阶段开始时，你可以弃置该角色的X张手牌（X为其超过手牌上限的手牌张数））。
eaocai = sgs.CreateTriggerSkillV2 {
	name = "eaocai",
	frequency = sgs.Skill_Limited,
	events = { sgs.EventPhaseChanging },
	limit_mark = "@talent",
	can_trigger = function(skill, event, room, player, data)
		if not player:isAlive() then return false end
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		if player:getMark("@talent") <= 0 then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		return player:askForSkillInvoke(skill:objectName(), ctx.original_data)
	end,
	on_effect = function(skill, event, room, player, ctx)
		local players = room:getOtherPlayers(player)
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(players) do
			if p:getHandcardNum() > player:getHandcardNum() then
				targets:append(p)
			end
		end
		room:broadcastSkillInvoke(skill:objectName())
		room:doLightbox("$eaocai", 5000)
		player:loseMark("@talent")
		for _, p in sgs.qlist(targets) do
			local equips = p:getEquips()
			local cardsNum = p:getHandcardNum() + equips:length()
			if cardsNum >= 2 then
				if not room:askForDiscard(p, skill:objectName(), 2, 2, true, true) then
					if not p:isKongcheng() then
						local id = room:askForCardChosen(p, p, "he", "eaocai")
						local card = sgs.Sanguosha:getCard(id)
						room:moveCardTo(card, player, sgs.Player_PlaceHand, false)
					end
				end
			else
				if not p:isKongcheng() then
					local id = room:askForCardChosen(p, p, "he", "eaocai")
					local card = sgs.Sanguosha:getCard(id)
					room:moveCardTo(card, player, sgs.Player_PlaceHand, false)
				end
			end
		end
		room:acquireSkill(player, "ezhuanquan")
		return false
	end,
}
--[[
eaocaiStart = sgs.CreateTriggerSkill{
	name = "#eaocaiStart",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart},
	on_trigger = function(self, event, player, data)
		player:gainMark("@talent")
	end
}]]
--诸葛恪【专权】
--其他角色的弃牌阶段开始时，你可以弃置其X张手牌（X为其超过手牌上限的手牌张数）。
ezhuanquanDummyCard = sgs.CreateSkillCard {
	name = "ezhuanquanDummyCard",
}
ezhuanquan = sgs.CreateTriggerSkillV2 {
	name = "ezhuanquan",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_Discard then return false end
		if player:hasSkill(skill:objectName()) then return false end
		if player:getHandcardNum() - player:getMaxCards() <= 0 then return false end
		local names, owners = {}, {}
		for _, zhugeke in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			names[#names + 1] = skill:objectName()
			owners[#owners + 1] = zhugeke:objectName()
		end
		if #names == 0 then return false end
		return table.concat(names, "|"), table.concat(owners, "|")
	end,
	on_cost = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		if target:getHandcardNum() - target:getMaxCards() <= 0 then return false end
		return room:askForSkillInvoke(player, skill:objectName())
	end,
	on_effect = function(skill, event, room, player, ctx)
		local target = ctx.invoker
		local x = target:getHandcardNum() - target:getMaxCards()
		if x <= 0 then return false end
		room:broadcastSkillInvoke(skill:objectName())
		room:setPlayerFlag(target, "ezhuanquanTarget_InTempMoving")
		local dummy = ezhuanquanDummyCard:clone()
		local card_ids = {}
		local original_places = {}
		local count = 0
		for i = 1, x, 1 do
			local id = room:askForCardChosen(player, target, "h", skill:objectName())
			table.insert(card_ids, id)
			local place = room:getCardPlace(id)
			table.insert(original_places, place)
			dummy:addSubcard(id)
			player:addToPile("#ezhuanquan", id, false)
			count = count + 1
		end
		for i = 1, count, 1 do
			local card = sgs.Sanguosha:getCard(card_ids[i])
			room:moveCardTo(card, target, original_places[i], false)
		end
		room:setPlayerFlag(target, "-ezhuanquanTarget_InTempMoving")
		if count > 0 then
			room:throwCard(dummy, target, player)
		end
		return false
	end,
}
ezhuanquanAvoidTriggeringCardsMove = sgs.CreateTriggerSkillV2 {
	name = "#ezhuanquanAvoidTriggeringCardsMove",
	frequency = sgs.Skill_Frequent,
	events = { sgs.CardsMoveOneTime },
	priority = 10,
	can_trigger = function(skill, event, room, player, data)
		for _, p in sgs.qlist(room:getAllPlayers()) do
			if p:hasFlag("ezhuanquanTarget_InTempMoving") then
				local holders = room:findPlayersBySkillName(skill:objectName())
				if holders:isEmpty() then return false end
				return skill:objectName(), holders:first():objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		return true
	end,
}
ezhugeke:addSkill(ejisi)
ezhugeke:addSkill(eqiangbian)
ezhugeke:addSkill(eaocai)
--ezhugeke:addSkill(eaocaiStart)
--extension:insertRelatedSkills("eaocai","#eaocaiStart")
ezhugeke_0 = sgs.General(extension, "ezhugeke_f", "wu", "4", true, true, true)
ezhugeke_0:addSkill(ezhuanquan)
ezhugeke:addSkill(ezhuanquanAvoidTriggeringCardsMove)
extension:insertRelatedSkills("ezhuanquan", "#ezhuanquanAvoidTriggeringCardsMove")
ezhugeke:addRelateSkill("ezhuanquan")

--刘璋
eliuzhang = sgs.General(extension, "eliuzhang", "qun", "4")
--刘璋【图守】
--准备阶段开始时，你可以选择一项：1.将一张手牌交给当前的体力值最大的一名其他角色，
--若如此做，你将你拥有的牌补至X张（X为你的体力上限），且每当你于此回合内造成伤害时，你防止此伤害；
--2.弃置两张牌，若如此做，你回复1点体力，且每当你于此回合内受到伤害时，你防止此伤害。
etushou = sgs.CreateTriggerSkillV2 {
	name = "etushou",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.EventPhaseStart },
	can_trigger = function(skill, event, room, player, data)
		if not player:isAlive() then return false end
		if player:getPhase() ~= sgs.Player_Start then return false end
		local equips = player:getEquips()
		local cardsNum = player:getHandcardNum() + equips:length()
		if player:isKongcheng() and cardsNum < 2 then return false end
		return skill:objectName()
	end,
	on_cost = function(skill, event, room, player, ctx)
		local equips = player:getEquips()
		local cardsNum = player:getHandcardNum() + equips:length()
		local choice
		if cardsNum < 2 then
			choice = room:askForChoice(player, skill:objectName(), "etushou1+cancel")
		elseif player:isKongcheng() then
			choice = room:askForChoice(player, skill:objectName(), "etushou2+cancel")
		else
			choice = room:askForChoice(player, skill:objectName(), "etushou1+etushou2+cancel")
		end
		if choice == "cancel" then return false end
		ctx.choice = choice
		return true
	end,
	on_effect = function(skill, event, room, player, ctx)
		if ctx.choice == "etushou1" then
			room:addPlayerMark(player, "&" .. skill:objectName() .. "+etushou_damageCause-Clear")
			room:broadcastSkillInvoke(skill:objectName(), 1)
			local maxHp = -1000
			local to_givelist0 = room:getOtherPlayers(player)
			for _, p in sgs.qlist(to_givelist0) do
				if p:getHp() > maxHp then
					maxHp = p:getHp()
				end
			end
			local to_givelist = sgs.SPlayerList()
			for _, p in sgs.qlist(to_givelist0) do
				if p:getHp() == maxHp then
					to_givelist:append(p)
				end
			end
			local to_give = room:askForPlayerChosen(player, to_givelist, skill:objectName())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, player:objectName())
			reason.m_playerId = to_give:objectName()
			local id = room:askForCardChosen(player, player, "h", skill:objectName())
			local card = sgs.Sanguosha:getCard(id)
			room:moveCardTo(card, to_give, sgs.Player_PlaceHand, false)
			local equips = player:getEquips()
			local cardsNum = player:getHandcardNum() + equips:length()
			local x = player:getMaxHp() - cardsNum
			if x > 0 then
				player:drawCards(x)
			end
			room:setPlayerFlag(player, "etushou1")
		elseif ctx.choice == "etushou2" then
			room:addPlayerMark(player, "&" .. skill:objectName() .. "+etushou_damageInflicte-Clear")
			room:broadcastSkillInvoke(skill:objectName(), 2)
			room:askForDiscard(player, skill:objectName(), 2, 2, false, true)
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover)
			room:setPlayerFlag(player, "etushou2")
		end
		return false
	end,
}
etushouEffect = sgs.CreateTriggerSkillV2 {
	name = "#etushouEffect",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused, sgs.DamageInflicted },
	can_trigger = function(skill, event, room, player, data)
		if event == sgs.DamageInflicted then
			if player:hasFlag("etushou2") then
				return skill:objectName()
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			local source = damage.from
			if source and source:isAlive() and source:hasFlag("etushou1")
				and source:objectName() == player:objectName() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local damage = ctx.original_data:toDamage()
		if event == sgs.DamageInflicted then
			if player:hasFlag("etushou2") then
				room:broadcastSkillInvoke("etushou", 4)
				damage.prevented = true
				ctx.original_data:setValue(damage)
				return true
			end
		end
		if event == sgs.DamageCaused then
			local source = damage.from
			if source then
				if source:isAlive() then
					if source:hasFlag("etushou1") then
						room:broadcastSkillInvoke("etushou", 3)
						damage.prevented = true
						ctx.original_data:setValue(damage)
						return true
					end
				end
			end
		end
		return false
	end,
}
--刘璋【宗室】
--锁定技，你的手牌上限+X（X为现存势力数）。
eliuzhang:addSkill(etushou)
eliuzhang:addSkill(etushouEffect)
extension:insertRelatedSkills("etushou", "#etushouEffect")
eliuzhang:addSkill("zongshi")

--王允
ewangyun = sgs.General(extension, "ewangyun", "qun", "3")
--王允【挑拨】
--出牌阶段限一次，你可以令两名其他角色同时展示一张手牌。
--若花色不同，其中手牌少的角色视为对手牌多的角色使用一张【杀】；若花色相同，你失去1点体力。
etiaoboCard = sgs.CreateSkillCard {
	name = "etiaoboCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		if #targets < 2 then
			if to_select:objectName() ~= player:objectName() then
				if not to_select:isKongcheng() then
					return true
				end
			end
		end
		return false
	end,
	feasible = function(self, targets, player)
		return #targets == 2
	end,
	on_use = function(self, room, source, targets)
		local playerA = targets[1]
		local playerB = targets[2]
		local id1 = room:askForCardChosen(playerA, playerA, "h", self:objectName())
		local card1 = sgs.Sanguosha:getCard(id1)
		local id2 = room:askForCardChosen(playerB, playerB, "h", self:objectName())
		local card2 = sgs.Sanguosha:getCard(id2)
		room:showCard(playerA, id1)
		room:showCard(playerB, id2)
		if card1:getSuit() ~= card2:getSuit() then
			if playerA:getHandcardNum() ~= playerB:getHandcardNum() then
				local from
				local to
				if playerA:getHandcardNum() < playerB:getHandcardNum() then
					from = playerA
					to = playerB
				else
					from = playerB
					to = playerA
				end
				if from:canSlash(to, nil, false) then
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					slash:setSkillName("_etiaobo")
					local card_use = sgs.CardUseStruct()
					card_use.from = from
					card_use.to:append(to)
					card_use.card = slash
					room:setPlayerFlag(from, "ZenhuiUser_" .. slash:toString())
					room:useCard(card_use, false)
					room:setPlayerFlag(from, "-ZenhuiUser_" .. slash:toString())
					slash:deleteLater()
				end
			end
		else
			room:loseHp(source, 1, true, source, self:objectName())
		end
	end,
}
etiaobo = sgs.CreateViewAsSkillV2 {
	name = "etiaobo",
	n = 0,
	can_activate = function(skill, request)
		local player = request:getInitiator()
		if not player then return false end
		if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		return not (player:hasUsed("#etiaoboCard") or player:hasUsed("etiaobo"))
	end,
	can_select_card = function(skill, request, candidate)
		return false
	end,
	card_selection_feasible = function(skill, request)
		return request:getSelectedCardIds():isEmpty()
	end,
	create_card = function(skill, request)
		local card = etiaoboCard:clone()
		card:setSkillName(skill:objectName())
		return card
	end,
	pay = function(skill, room, ctx, request)
		local source = ctx.invoker or ctx.initiator
		if source then
			room:addPlayerHistory(source, "#etiaoboCard")
		end
		return true
	end,
}
--王允【持重】
--每当你扣减或回复体力后，你可以摸一张牌。
echizhong = sgs.CreateTriggerSkillV2 {
	name = "echizhong",
	frequency = sgs.Skill_Frequent,
	events = { sgs.HpChanged },
	can_trigger = function(skill, event, room, player, data)
		if player:isAlive() then
			return skill:objectName()
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName())
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke(skill:objectName())
		room:drawCards(player, 1, "echizhong")
		return false
	end,
}
ewangyun:addSkill(etiaobo)
ewangyun:addSkill(echizhong)

--文字信息显示
sgs.LoadTranslationTable {
	["emjr"] = "E鸣惊人",

	["echengyu"] = "程昱",
	["&echengyu"] = "程昱",
	["#echengyu"] = "狠戾的谋士",
	["designer:echengyu"] = "小A",
	["cv:echengyu"] = "NeoSpeech Liang",
	["illustrator:echengyu"] = "三国在线",
	["efusha"] = "伏杀",
	[":efusha"] = '<font color="green"><b>出牌阶段限一次，</b></font>你可以将一张手牌背面朝上移出游戏并选择一名其他角色，若如此做，该角色的回合开始时，其选择一种花色后将此牌置入弃牌堆，若此牌的花色与其所选的不同，你视为对其使用一张【杀】。',
	["#efusha"] = "%from执行了“%arg”的效果，选择了花色%arg2",
	["eweicheng"] = "危城",
	[":eweicheng"] = "每当你成为其他角色使用的【杀】或非延时类锦囊牌的目标后，若你有手牌，你可以依次弃置该角色的X张牌（X为你已损失的体力值且至少为1）。",
	-- ["$efusha1"] = "十面埋伏，定能重创敌军。", --发动
	-- ["$efusha2"] = "前无去路，诸军何不死战？", --执行效果
	-- ["$efusha3"] = "决一死战，生擒袁绍！", --袁绍执行效果
	-- ["$eweicheng1"] = "今汝见吾兵少，必轻易不来攻。",
	-- ["$eweicheng2"] = "四世三公也就这点胆量。", --对袁绍
	-- ["~echengyu"] = "知足不辱，吾可以退矣。",

	["elidian"] = "李典",
	["&elidian"] = "李典",
	["#elidian"] = "恂恂之风",
	["designer:elidian"] = "llmoon",
	["cv:elidian"] = "NeoSpeech Liang",
	["illustrator:elidian"] = "真三国无双7",
	["eqiehu"] = "郄縠",
	[":eqiehu"] = "其他角色的摸牌阶段结束后，你可以弃置一张基本牌，令该角色摸两张牌；其他角色的弃牌阶段结束后，你可以弃置一张非基本牌，令该角色弃置两张牌。",
	["@eqiehu1"] = "你可以弃置一张基本牌发动“郄縠”，令 %src 摸两张牌",
	["@eqiehu2"] = "你可以弃置一张非基本牌发动“郄縠”，令 %src 弃置两张牌",
	-- ["$eqiehu1"] = "典岂敢以私憾而忘公义乎？", --前半段
	-- ["$eqiehu2"] = "文远兄，我来助你！", --前半段，对张辽
	-- ["$eqiehu3"] = "苟利国家，专之可也，宜亟击之。", --后半段
	-- ["$eqiehu4"] = "活捉孙权，当在今日！", --后半段，对孙权
	-- ["~elidian"] = "可惜看不到曹魏大军横扫江东了。",

	["ezhoucang"] = "周仓",
	["&ezhoucang"] = "周仓",
	["#ezhoucang"] = "武圣护卫",
	["designer:ezhoucang"] = "金皆居士",
	["cv:ezhoucang"] = "NeoSpeech Liang",
	["illustrator:ezhoucang"] = "三国智",
	["ehuwu"] = "护武",
	[":ehuwu"] = "每当其他角色主动使用的红色的【杀】和红色非延时类锦囊牌结算结束后，你可以进行判定，若判定结果不为红桃，你选择一项：1.获得处理区里的此牌；2.令该角色摸一张牌。",
	["ehuwu:ehuwu1"] = "获得处理区里的 %src",
	["ehuwu:ehuwu2"] = "令 %src 摸一张牌",
	-- ["$ehuwu1"] = "好刀法！", --红杀
	-- ["$ehuwu2"] = "好计策！", --红锦囊
	-- ["$ehuwu3"] = "仓跟随将军，虽万里不辞也。", --对关羽
	-- ["~ezhoucang"] = "关将军已死，仓岂能独生……",

	["ezhangxingcai"] = "张星彩",
	["&ezhangxingcai"] = "张星彩",
	["#ezhangxingcai"] = "敬哀皇后",
	["designer:ezhangxingcai"] = "惘ワ記",
	["cv:ezhangxingcai"] = "Microsoft Huihui",
	["illustrator:ezhangxingcai"] = "地狱许",
	["echinei"] = "持内",
	[":echinei"] = "摸牌阶段，若你已受伤，你可以少摸一张牌，亮出牌堆顶的X+1张牌（X为你已损失的体力值），你将其中任意数量的牌交给一名其他角色，然后获得其余的牌。",
	["erangwai"] = "攘外",
	[":erangwai"] = "一名角色的结束阶段开始时，若该角色于此回合内未使用过基本牌和锦囊牌，你可以弃置一张基本牌，视为对其攻击范围内的另一名其他角色使用一张【杀】。",
	["@erangwai"] = "你可以弃置一张基本牌发动“攘外”",
	["~erangwai"] = "选择一张基本牌→选择【杀】的目标角色→点击确定",
	-- ["$echinei1"] = "以我微薄之力，免除陛下后顾之忧。",
	-- ["$echinei2"] = "攘外必先安内。",
	-- ["$erangwai1"] = "车骑将军之女在此，何人敢犯我蜀境？！",
	-- ["$erangwai2"] = "蜀中无大将，女子上战场。",
	-- ["$erangwai3"] = "臣妾愿为陛下而战！", --对刘禅
	-- ["~ezhangxingcai"] = "只愿陛下与蜀汉平安……",

	["elukang"] = "陆抗",
	["&elukang"] = "陆抗",
	["#elukang"] = "镇军之将",
	["designer:elukang"] = "雪寂人心",
	["cv:elukang"] = "NeoSpeech Liang",
	["illustrator:elukang"] = "三国志12",
	["eyanshou"] = "堰守",
	[":eyanshou"] = '<font color="green"><b>出牌阶段限一次，</b></font>你可以令一名角色弃置其装备区里的所有牌，然后该角色摸X+1张牌（X为其以此法弃置的装备牌数量）。',
	["ekegou"] = "克构",
	[":ekegou"] = "若有其他角色手牌不比你少，你可以跳过你的弃牌阶段。",
	-- ["$eyanshou1"] = "筑此堰，可淹敌军。",
	-- ["$eyanshou2"] = "毁此堰，可断敌粮。",
	-- ["$ekegou1"] = "父亲，我不会辜负江东陆家的荣耀。",
	-- ["$ekegou2"] = "隐忍克己，静待时机，此伐晋之道。",
	-- ["~elukang"] = "抗存则吴存，抗亡则吴亡……",

	["ezhugeke_f"] = "诸葛恪",
	["&ezhugeke_f"] = "诸葛恪",
	["#ezhugeke_f"] = "矜己陵人",
	["designer:ezhugeke_f"] = "大道岂可修",
	["cv:ezhugeke_f"] = "NeoSpeech Liang",
	["illustrator:ezhugeke_f"] = "LiuHeng",

	["ezhugeke"] = "诸葛恪",
	["&ezhugeke"] = "诸葛恪",
	["#ezhugeke"] = "矜己陵人",
	["designer:ezhugeke"] = "大道岂可修",
	["cv:ezhugeke"] = "NeoSpeech Liang",
	["illustrator:ezhugeke"] = "LiuHeng",
	["ejisi"] = "急思",
	[":ejisi"] = "每当你需要使用【无懈可击】时，你可以与当前回合角色拼点，若你赢，你视为使用一张【无懈可击】。每回合限一次。",
	["eqiangbian"] = "强辩",
	[":eqiangbian"] = '<font color="blue"><b>锁定技，</b></font>每当你与一名角色拼点时，你令该角色用你选择的其一张手牌拼点。',
	["eaocai"] = "傲才",
	[":eaocai"] = '<font color="red"><b>限定技，</b></font>回合结束时，你可以令手牌比你多的所有角色各选择一项：1.交给你一张牌；2.弃置两张手牌。然后你获得技能“专权”（其他角色的弃牌阶段开始时，你可以弃置其X张手牌（X为其超过手牌上限的手牌张数））。',
	["@talent"] = "傲才",
	["ezhuanquan"] = "专权",
	[":ezhuanquan"] = "其他角色的弃牌阶段开始时，你可以弃置其X张手牌（X为其超过手牌上限的手牌张数）。",
	-- ["$ejisi1"] = "爰植梧桐，以待凤皇。", --发动
	-- ["$ejisi2"] = "有何燕雀，自称来翔？", --拼点赢1
	-- ["$ejisi3"] = "此乃诸葛子瑜之驴。", --拼点赢2
	-- ["$ejisi4"] = "竟能难倒我！", --拼点没赢
	-- ["$eaocai"] = "父亲，你看到了么，我就要超越叔父了。",
	-- ["$ezhuanquan1"] = "汝等休要妄为！",
	-- ["$ezhuanquan2"] = "这事我说了算！",
	-- ["~ezhugeke"] = "父亲的预言竟然成真了。",

	["eliuzhang"] = "刘璋",
	["&eliuzhang"] = "刘璋",
	["#eliuzhang"] = "蹯踞西川",
	["designer:eliuzhang"] = "小猪翼么么哒",
	["cv:eliuzhang"] = "NeoSpeech Liang",
	["illustrator:eliuzhang"] = "三国志12",
	["etushou"] = "图守",
	[":etushou"] = "准备阶段开始时，你可以选择一项：1.将一张手牌交给当前的体力值最大的一名其他角色，若如此做，你将你拥有的牌补至X张（X为你的体力上限），且每当你于此回合内造成伤害时，你防止此伤害；2.弃置两张牌，若如此做，你回复1点体力，且每当你于此回合内受到伤害时，你防止此伤害。",
	["etushou:etushou1"] = "将一张手牌交给当前的体力值最大的一名其他角色",
	["etushou:etushou2"] = "弃置两张牌",
	["etushou_damageInflicte"] = "防止受到伤害",
	["etushou_damageCause"] = "防止造成伤害",
	-- ["$etushou1"] = "速搬救兵！", --给牌
	-- ["$etushou2"] = "只有如此方可保全西川百姓。", --弃牌
	-- ["$etushou3"] = "此非鸿门会，何用舞剑？", --效果1防止伤害
	-- ["$etushou4"] = "我等同为汉臣，公等勿虑也。", --效果2防止伤害
	-- ["~eliuzhang"] = "望玄德公以西川百姓为重！",

	["ewangyun"] = "王允",
	["&ewangyun"] = "王允",
	["#ewangyun"] = "除暴卫汉",
	["designer:ewangyun"] = "LcDreamer",
	["cv:ewangyun"] = "NeoSpeech Liang",
	["illustrator:ewangyun"] = "三国志12",
	["etiaobo"] = "挑拨",
	[":etiaobo"] = '<font color="green"><b>出牌阶段限一次，</b></font>你可以令两名其他角色同时展示一张手牌。若花色不同，其中手牌少的角色视为对手牌多的角色使用一张【杀】；若花色相同，你失去1点体力。',
	["echizhong"] = "持重",
	[":echizhong"] = "每当你扣减或回复体力后，你可以摸一张牌。",
	-- ["$etiaobo1"] = "此计可化百姓倒悬之危，解君臣累卵之急。",
	-- ["$etiaobo2"] = "反贼至此，武士何在？",
	-- ["$echizhong1"] = "事若泄漏，我灭门矣！",
	-- ["$echizhong2"] = "但恐事或不成，反招大祸。",
	-- ["~ewangyun"] = "臣本为社稷计，事已至此……",
}

--[[ 武将：郝昭（群，4体力）
技能：
【死守】【锁定技】：若你的装备区里没有防具牌，红色的杀（含火杀）对你无效，每当你受到一次杀的伤害，你摸一张牌。
【破计】在你的回合外，当你成为非延时锦囊的目标时，你可以弃置一张与此锦囊相同花色的手牌令其无效。
==========================================================
武将：张翼（蜀，4体力）
技能：
【廷争】其他角色于其回合内使用第一张【杀】时，你可以与其拼点：若你赢，取消此【杀】，你获得双方拼点的牌，其摸两张牌；若你没赢，其获得双方拼点的牌，于此【杀】结算结束后你视为对相同目标使用【杀】。每轮限一次。 ]]
