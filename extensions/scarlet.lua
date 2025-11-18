extension = sgs.Package("scarlet")
extension_soldier = sgs.Package("s4_soldier")
sgs.LoadTranslationTable {
    ["scarlet"] = "時語",
    ["s4_soldier"] = "百万雄兵"
}
-- useful function


function RIGHT(self, player)
    if player and player:isAlive() and player:hasSkill(self:objectName()) then
        return true
    else
        return false
    end
end

---@param room room
---@return int輪次數
function getRoundCount(room)
    local n = 15
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        n = math.min(p:getSeat(), n)
    end
    for _, player in sgs.qlist(room:getAlivePlayers()) do
        if player:getSeat() == n then
            local x = player:getMark("Global_TurnCount") + 1
            return x
        end
    end
end

---@param self string_boolean_number
---@return sgs.QVariant
function ToQVData(self)
    local data = sgs.QVariant()
    if type(self) == "string" or type(self) == "boolean" or type(self) == "number" then
        data = sgs.QVariant(self)
    elseif self ~= nil then
        data:setValue(self)
    end
    return data
end

listIndexOf = function(theqlist, theitem)
    local index = 0
    for _, item in sgs.qlist(theqlist) do
        if item == theitem then
            return index
        end
        index = index + 1
    end
end

function getCardDamageNature(from, to, card)
    local nature = sgs.DamageStruct_Normal
    if card then
        if card:isKindOf("FireAttack") or card:isKindOf("FireSlash") then
            nature = sgs.DamageStruct_Fire
        elseif card:isKindOf("drowning") or card:isKindOf("ThunderSlash") then
            nature = sgs.DamageStruct_Thunder
        elseif card:isKindOf("IceSlash") then
            nature = sgs.DamageStruct_Ice
        end
    end
    if hasWulingEffect("@fire") then
        nature = sgs.DamageStruct_Fire
    end
    return nature
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

function GetColor(card)
    if card:isRed() then return "red" elseif card:isBlack() then return "black" else return "nosuitcolor" end
end

-- common prompt
sgs.LoadTranslationTable {
    ["#skill_add_damage"] = "%from的技能【<font color=\"yellow\"><b> %arg </b></font>】被触发，%from对%to造成的伤害增加至%arg2点。", -- add
    ["#skill_add_damage_byother1"] = "%from的技能【<font color=\"yellow\"><b> %arg </b></font>】被触发，", -- add
    ["#skill_add_damage_byother2"] = "%from 对%to造成的伤害增加至%arg点。", -- add
    ["#skill_cant_jink"] = "%from的技能【<font color=\"yellow\"><b> %arg </b></font>】被触发，%to 不能使用【闪】响应 %from 对 %to 使用的【杀】。", -- add
    ["#BecomeTargetBySkill"] = "%from的技能【<font color=\"yellow\"><b> %arg </b></font>】被触发，%to 成为了 %card 的目标", -- add
    ["#ArmorNullifyDamage"] = "%from 的防具【%arg】效果被触发，抵消 %arg2 点伤害", -- add
    ["#SkillNullifyDamage"] = "%from 的技能【%arg】效果被触发，抵消 %arg2 点伤害", -- add
    ["#ChooseSkill"] = "%from 的技能 %arg 选择了 %arg2",
    ["#choice"] = "%from 选择了 %arg",
}
s4_cloud_zhangliao = sgs.General(extension, "s4_cloud_zhangliao", "wei", 4, false, false, false, 3)

s4_cloud_tuxi = sgs.CreateTriggerSkill {
    name = "s4_cloud_tuxi",
    events = { sgs.EventPhaseStart },
    -- events = { sgs.EventPhaseStart, sgs.CardFinished },
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data, room)
        local room = player:getRoom()
        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if p and p:objectName() ~= player:objectName() and
                room:askForSkillInvoke(p, self:objectName(), ToQVData(player)) then
                room:broadcastSkillInvoke(self:objectName())
                if room:askForDiscard(p, self:objectName(), 999, 1, true, true, "@s4_cloud_tuxi:" .. player:objectName()) then
                else
                    local lose_num = {}
                    for i = 1, p:getHp() do
                        table.insert(lose_num, tostring(i))
                    end
                    local choice = room:askForChoice(p, "s4_cloud_tuxi", table.concat(lose_num, "+"))
                    room:loseHp(p, tonumber(choice), true, p, self:objectName())
                end
                if p:isAlive() then
                    if player:getHandcardNum() >= p:getHandcardNum() and not player:isKongcheng() then
                        local card_id = room:askForCardChosen(p, player, "h", self:objectName())
                        room:obtainCard(p, card_id)
                    end
                    if player:getEquips():length() >= p:getEquips():length() and p:canDiscard(player, "he") then
                        local card_id = room:askForCardChosen(p, player, "he", self:objectName())
                        room:throwCard(sgs.Sanguosha:getCard(card_id), player, p)
                    end
                    if player:getHp() >= p:getHp() then
                        p:gainHujia(1)
                        local damage = sgs.DamageStruct()
                        damage.from = p
                        damage.to = player
                        room:damage(damage)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:getPhase() == sgs.Player_Play and target:isAlive()
    end
}

s4_cloud_yongqian = sgs.CreateTriggerSkill {
    name = "s4_cloud_yongqian",
    events = { sgs.DrawNCards, sgs.TargetConfirmed },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DrawNCards and RIGHT(self, player) then
            local draw = data:toDraw()
            if draw.reason ~= "draw_phase" then return false end
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
                "s4_cloud_yongqian-invoke", true, true)
            if target then
                room:broadcastSkillInvoke(self:objectName())
                draw.num = draw.num - 1
                data:setValue(draw)
                room:setFixedDistance(player, target, 1);
                room:setPlayerMark(player, self:objectName() .. target:objectName(), 1)
                room:addPlayerMark(target, "&" .. self:objectName() .. "+to+#" .. player:objectName())
            end
        elseif event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.card and not use.card:isKindOf("SkillCard") and use.from and player:objectName() ==
                use.from:objectName() then
                for _, p in sgs.qlist(use.to) do
                    if p:objectName() ~= use.from:objectName() and p:getMark(self:objectName() .. player:objectName()) >
                        0 and room:askForSkillInvoke(p, self:objectName()) then
                        p:drawCards(1)
                        room:broadcastSkillInvoke(self:objectName())
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}

s4_cloud_yongqianClear = sgs.CreateTriggerSkill {
    name = "#s4_cloud_yongqianClear",
    events = { sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_Start then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if player:getMark("s4_cloud_yongqian" .. p:objectName()) > 0 then
                        table.removeOne(assignee_list, p:objectName())
                        room:removeFixedDistance(player, p, 1)
                        room:setPlayerMark(player, "s4_cloud_yongqian" .. p:objectName(), 0)
                        room:setPlayerMark(p, "&s4_cloud_yongqian+to+#" .. player:objectName(), 0)
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
s4_cloud_yongqian_buff = sgs.CreateTargetModSkill{
    name = "#s4_cloud_yongqian_buff",
    pattern = ".",
    residue_func = function(self, from, card, to)
        if from:hasSkill("s4_cloud_yongqian") and to and from:getMark("s4_cloud_yongqian" .. to:objectName()) > 0 then return 1000 end
        return 0
    end,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("s4_cloud_yongqian") and to and from:getMark("s4_cloud_yongqian" .. to:objectName()) > 0 then return 1000 end
        return 0
    end,
}
s4_cloud_zhangliao:addSkill(s4_cloud_tuxi)
s4_cloud_zhangliao:addSkill(s4_cloud_yongqian)
s4_cloud_zhangliao:addSkill(s4_cloud_yongqianClear)
s4_cloud_zhangliao:addSkill(s4_cloud_yongqian_buff)
extension:insertRelatedSkills("s4_cloud_yongqian", "#s4_cloud_yongqianClear")
extension:insertRelatedSkills("s4_cloud_yongqian", "#s4_cloud_yongqian_buff")

sgs.LoadTranslationTable {
    ["s4_cloud_zhangliao"] = "张辽",
    ["&s4_cloud_zhangliao"] = "张辽",
    ["#s4_cloud_zhangliao"] = "威震江东",
    ["~s4_cloud_zhangliao"] = "孙权小儿",
    ["designer:s4_cloud_zhangliao"] = "终极植物",
    ["cv:s4_cloud_zhangliao"] = "三国杀瑞宝",
    ["illustrator:s4_cloud_zhangliao"] = "云崖",

    ["@s4_cloud_tuxi"] = "你可以弃置至少一张牌或失去至少1点体力，对 %src 使用突襲",
    ["s4_cloud_tuxi"] = "突襲",
    -- [":s4_cloud_tuxi"] = "当一名其他角色出牌阶段开始时或当一名其他角色于其出牌阶段使用的一张牌结算结束后，你可以弃置至少一张牌或失去至少1点体力，然后若其手牌数不小于你，你获得其一张手牌；若其装备数不小于你，你弃置其一张牌；若其体力值不小于你，你获得1点护甲，对其造成1点伤害。",
    [":s4_cloud_tuxi"] = "当一名其他角色出牌阶段开始时，你可以弃置至少一张牌或失去至少1点体力，然后若其手牌数不小于你，你获得其一张手牌；若其装备数不小于你，你弃置其一张牌；若其体力值不小于你，你获得1点护甲，对其造成1点伤害。",
    ["$s4_cloud_tuxi1"] = "江东小儿，安敢啼哭？",
    ["$s4_cloud_tuxi2"] = "八百虎贲踏江去，十万吴兵丧胆还！",

    ["s4_cloud_yongqian-invoke"] = "你可以发动“勇前”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
    ["s4_cloud_yongqian"] = "勇前",
    [":s4_cloud_yongqian"] = "摸牌阶段，你可以少摸一张牌，然后选择一名其他角色，直到你下回合开始，你对其使用牌无距离和次数限制，当其使用牌指定你为目标后，你可以摸一张牌。",
    ["$s4_cloud_yongqian1"] = "千围万困，吾亦能来去自如！",
    ["$s4_cloud_yongqian2"] = "敌军虽百倍于我，破之易而。"

}

s4_cloud_huangzhong = sgs.General(extension, "s4_cloud_huangzhong", "shu", 3, false)

s4_cloud_liegong = sgs.CreateTriggerSkill {
    name = "s4_cloud_liegong",
    events = { sgs.TargetConfirmed, sgs.DamageCaused },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if not use.from or (player:objectName() ~= use.from:objectName()) or not use.card:isKindOf("Slash") then
                return false
            end
            local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
            local index = 1
            for _, p in sgs.qlist(use.to) do
                if p:getHandcardNum() >= player:getHp() or p:getHandcardNum() <= player:getAttackRange() then
                    if player:askForSkillInvoke(self:objectName(), ToQVData(p)) then
                        room:broadcastSkillInvoke(self:objectName())
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
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.by_user and (not damage.chain) and
                (not damage.transfer) then
                if damage.to and (damage.to:getHp() >= player:getHp() or damage.to:getHp() <= player:getAttackRange()) then
                    if player:askForSkillInvoke(self:objectName(), ToQVData(damage.to)) then
                        room:broadcastSkillInvoke(self:objectName())
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
                end
            end
        end
    end
}

s4_cloud_yongyiAttackRange = sgs.CreateAttackRangeSkill {
    name = "#s4_cloud_yongyiAttackRange",
    extra_func = function(self, target)
        local record = target:property("s4_cloud_yongyiRecords"):toString():split(",")
        local x = math.max(#record, 1)
        if target:hasSkill("s4_cloud_yongyi") then
            return x
        else
            return 0
        end
    end
}
s4_cloud_yongyiAnaleptic = sgs.CreateTargetModSkill {
    name = "#s4_cloud_yongyiAnaleptic",
    pattern = "Analeptic",
    residue_func = function(self, player, card)
        if player:hasSkill(self:objectName()) and table.contains(card:getSkillNames(), "s4_cloud_yongyi") then
            return 1000
        end
    end
}
s4_cloud_yongyiCard = sgs.CreateSkillCard {
    name = "s4_cloud_yongyi",
    handling_method = sgs.Card_MethodUse,
    filter = function(self, targets, to_select, player)
        local qtargets = sgs.PlayerList()
        for _, p in ipairs(targets) do
            qtargets:append(p)
        end
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local card = nil
            card = sgs.Sanguosha:cloneCard("analeptic")
            card:setSkillName("_s4_cloud_yongyi")
            return card and card:targetFilter(qtargets, to_select, player) and
                not player:isProhibited(to_select, card, qtargets)
        end

        local card = sgs.Sanguosha:cloneCard("analeptic")
        card:setSkillName("_s4_cloud_yongyi")
        if card and card:targetFixed() then
            return card:isAvailable(player)
        end
        return card and card:targetFilter(qtargets, to_select, player) and
            not player:isProhibited(to_select, card, qtargets)
    end,
    feasible = function(self, targets, player)
        local card = sgs.Sanguosha:cloneCard("analeptic")
        if card then
            card:setSkillName("_s4_cloud_yongyi")
        end
        local qtargets = sgs.PlayerList()
        for _, p in ipairs(targets) do
            qtargets:append(p)
        end
        return card and card:targetsFeasible(qtargets, player)
    end,
    on_validate = function(self, cardUse)
        local source = cardUse.from
        local room = source:getRoom()
        local user_string = self:getUserString()
        local use_card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
        if not use_card then
            return nil
        end
        use_card:setSkillName("s4_cloud_yongyi")
        -- use_card:deleteLater()
        room:setCardFlag(use_card, "RemoveFromHistory")
        room:addPlayerHistory(source, use_card:getClassName(), -1)
        room:addPlayerMark(source, "s4_cloud_yongyi_used-Clear")
        local record = source:property("s4_cloud_yongyiRecords"):toString()
        local records
        if (record) then
            records = record:split(",")
        end
        local suit = room:askForChoice(source, "s4_cloud_yongyi", table.concat(records, "+"), sgs.QVariant())
        if records and (table.contains(records, suit)) then
            table.removeOne(records, suit)
        end
        room:setPlayerProperty(source, "s4_cloud_yongyiRecords", sgs.QVariant(table.concat(records, ",")));
        for _, mark in sgs.list(source:getMarkNames()) do
            if (string.startsWith(mark, "&s4_cloud_yongyi+#record") and source:getMark(mark) > 0) then
                room:setPlayerMark(source, mark, 0)
            end
        end
        local mark = "&s4_cloud_yongyi+#record"
        for _, suit in ipairs(records) do
            mark = mark .. "+" .. suit .. "_char"
        end
        room:setPlayerMark(source, mark, 1)
        return use_card
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()
        local use_card = sgs.Sanguosha:cloneCard("analeptic")
        if not use_card then
            return nil
        end
        use_card:setSkillName("s4_cloud_yongyi")
        room:setCardFlag(use_card, "RemoveFromHistory")
        room:addPlayerMark(source, "s4_cloud_yongyi_used-Clear")
        room:addPlayerHistory(source, use_card:getClassName(), -1)

        local record = source:property("s4_cloud_yongyiRecords"):toString()
        local records
        if (record) then
            records = record:split(",")
        end
        local suit = room:askForChoice(source, "s4_cloud_yongyi", table.concat(records, "+"), sgs.QVariant())
        if records and (table.contains(records, suit)) then
            table.removeOne(records, suit)
        end
        room:setPlayerProperty(source, "s4_cloud_yongyiRecords", sgs.QVariant(table.concat(records, ",")));
        for _, mark in sgs.list(source:getMarkNames()) do
            if (string.startsWith(mark, "&s4_cloud_yongyi+#record") and source:getMark(mark) > 0) then
                room:setPlayerMark(source, mark, 0)
            end
        end
        local mark = "&s4_cloud_yongyi+#record"
        for _, suit in ipairs(records) do
            mark = mark .. "+" .. suit .. "_char"
        end
        room:setPlayerMark(source, mark, 1)
        return use_card
    end
}

s4_cloud_yongyiVS = sgs.CreateZeroCardViewAsSkill {
    name = "s4_cloud_yongyi",
    view_as = function(self, card)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or
            sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local c = s4_cloud_yongyiCard:clone()
            c:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
            return c
        end

        local ccc = sgs.Sanguosha:cloneCard("analeptic")
        ccc:setSkillName("s4_cloud_yongyi")
        if ccc and ccc:isAvailable(sgs.Self) then
            local c = s4_cloud_yongyiCard:clone()
            c:setUserString(ccc:objectName())
            return c
        end
        return nil
    end,
    enabled_at_play = function(self, player)
        local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
        newanal:setSkillName(self:objectName())
        newanal:deleteLater()
        return #player:property("s4_cloud_yongyiRecords"):toString():split(",") > 0 and
            player:getMark("s4_cloud_yongyi_used-Clear") == 0 and player:usedTimes("Analeptic") <=
            sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, newanal)
    end,
    enabled_at_response = function(self, player, pattern)
        return #player:property("s4_cloud_yongyiRecords"):toString():split(",") > 0 and
            string.find(pattern, "analeptic") and player:getMark("s4_cloud_yongyi_used-Clear") == 0
    end
}

s4_cloud_yongyi = sgs.CreateTriggerSkill {
    name = "s4_cloud_yongyi",
    view_as_skill = s4_cloud_yongyiVS,
    events = { sgs.CardUsed, sgs.CardResponded, sgs.TargetConfirmed },
    on_trigger = function(self, event, player, data, room)
        local card = nil
        if (event == sgs.CardUsed) then
            local use = data:toCardUse()
            card = use.card
        elseif (event == sgs.CardResponded) then
            local res = data:toCardResponse()
            if (not res.m_isUse) then
                return false
            end
            card = res.m_card
        elseif (event == sgs.TargetConfirmed) then
            local use = data:toCardUse()
            if (use.from == player or not use.to:contains(player)) then
                return false
            end
            card = use.card;
        end
        if (not card or card:isKindOf("SkillCard")) then
            return false
        end
        local record = player:property("s4_cloud_yongyiRecords"):toString()
        local suit = card:getSuitString()
        local records
        if (record) then
            records = record:split(",")
        end
        if records and (table.contains(records, suit) or not card:hasSuit()) then
            local x = math.max(1, #records)
            if player:askForSkillInvoke(self:objectName(), ToQVData(card)) then
                player:drawCards(x)
                room:broadcastSkillInvoke(self:objectName())
                if card:hasSuit() then
                    table.removeOne(records, suit)
                end
            end
        else
            table.insert(records, suit)
        end
        room:setPlayerProperty(player, "s4_cloud_yongyiRecords", sgs.QVariant(table.concat(records, ",")));
        for _, mark in sgs.list(player:getMarkNames()) do
            if (string.startsWith(mark, "&s4_cloud_yongyi+#record") and player:getMark(mark) > 0) then
                room:setPlayerMark(player, mark, 0)
            end
        end
        local mark = "&s4_cloud_yongyi+#record"
        for _, suit in ipairs(records) do
            mark = mark .. "+" .. suit .. "_char"
        end
        room:setPlayerMark(player, mark, 1)
        return false
    end
}
s4_cloud_huangzhong:addSkill(s4_cloud_liegong)
s4_cloud_huangzhong:addSkill(s4_cloud_yongyi)
s4_cloud_huangzhong:addSkill(s4_cloud_yongyiAnaleptic)
s4_cloud_huangzhong:addSkill(s4_cloud_yongyiAttackRange)
extension:insertRelatedSkills("s4_cloud_yongyi", "#s4_cloud_yongyiAttackRange")
extension:insertRelatedSkills("s4_cloud_yongyi", "#s4_cloud_yongyiAnaleptic")
sgs.LoadTranslationTable {
    ["s4_cloud_huangzhong"] = "谋黄忠",
    ["#s4_cloud_huangzhong"] = "没金铩羽",
    ["~s4_cloud_huangzhong"] = "弦断弓藏，将老孤亡。",
    ["designer:s4_cloud_huangzhong"] = "终极植物",
    ["cv:s4_cloud_huangzhong"] = "予安",
    ["illustrator:s4_cloud_huangzhong"] = "云崖",

    ["$s4_cloud_liegong"] = "矢贯坚石，劲冠三军。",
    ["s4_cloud_liegong"] = "烈弓",
    [":s4_cloud_liegong"] = "当你使用【杀】指定目标后，你可以根据下列条件执行相应的效果：1.若其手牌数不小于你的体力值或不大于你的攻击范围，你可以令其不能响应此【杀】；2.若其体力值不小于你的体力值或不大于你的攻击范围，你可以令此【杀】伤害+1。",
    ["$s4_cloud_yongyi"] = "吾虽年迈，箭矢犹锋。",
    ["s4_cloud_yongyi"] = "勇毅",
    [":s4_cloud_yongyi"] = "你使用牌时或成为其他角色使用牌的目标后，若此牌有花色且花色未被“勇毅”记录，则记录此花色；否则，你可以摸X张牌，若如此做，移除此花色记录。你的攻击范围加X（X为“勇毅”记录的花色数且至少为1）。每回合限一次，你可以移除一种花色记录，视为使用一张无次数限制的【酒】。"
}

s4_cloud_sunquan = sgs.General(extension, "s4_cloud_sunquan", "wu", 3, false)

s4_cloud_yingzi = sgs.CreateTriggerSkill {
    name = "s4_cloud_yingzi",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.DrawNCards },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local draw = data:toDraw()
        if draw.reason ~= "draw_phase" then return false end
        local x = 0
        if player:getHandcardNum() >= 2 then
            x = x + 1
        end
        if player:getHp() >= 2 then
            x = x + 1
        end
        if player:getEquips():length() >= 1 then
            x = x + 1
        end
        if x > 0 then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
            draw.num = draw.num + x
            data:setValue(draw)
            room:addMaxCards(player, x, true)
            room:addPlayerMark(player, "&s4_cloud_yingzi-Clear", x)
        end
    end
}

s4_cloud_sunquan:addSkill(s4_cloud_yingzi)
s4_cloud_sunquan:addSkill("tenyearzhiheng")
s4_cloud_sunquan:addSkill("mobilemoujiuyuan")

sgs.LoadTranslationTable {
    ["s4_cloud_sunquan"] = "孙权",
    ["#s4_cloud_sunquan"] = "东吴大帝",
    ["~s4_cloud_sunquan"] = "",
    ["designer:s4_cloud_sunquan"] = "终极植物",
    ["cv:s4_cloud_sunquan"] = "",
    ["illustrator:s4_cloud_sunquan"] = "云崖",

    ["s4_cloud_yingzi"] = "英姿",
    [":s4_cloud_yingzi"] = "锁定技，摸牌阶段，你多摸X张牌且你本回合的手牌上限+X（X为你满足的条件数：手牌数不小于2、体力值不小于2、装备区的牌数不小于1）。"
}
----------------------------------------------------------------
-- https://tieba.baidu.com/p/8501081538
----------------------------------------------------------------

s4_lubu = sgs.General(extension, "s4_lubu", "qun", 5)
s4_xianfeng = sgs.CreateTriggerSkill {
    name = "s4_xianfeng",
    events = { sgs.TargetSpecified },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") then
                local invoke = false
                for _, to in sgs.qlist(use.to) do
                    if player:distanceTo(to) <= 1 then
                        invoke = true
                        break
                    end
                end
                if invoke then
                    room:broadcastSkillInvoke(self:objectName())
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:addPlayerHistory(player, use.card:getClassName(), -1)
                end
            end
        end
        return false
    end
}
s4_xianfeng_TM = sgs.CreateTargetModSkill {
    name = "#s4_xianfeng_TM",
    pattern = "Slash",
    residue_func = function(self, from, card, to)
        local n = 0
        if from:hasSkill("s4_xianfeng") and to and from:distanceTo(to) <= 1 then
            n = 999
        end
        return n
    end
}
s4_xianfeng_D = sgs.CreateDistanceSkill {
    name = "#s4_xianfeng_D",
    correct_func = function(self, from, to)
        if from:hasSkill("s4_xianfeng") then
            return -1
        end
    end
}

s4_jiwu = sgs.CreateTriggerSkill {
    name = "s4_jiwu",
    events = { sgs.TargetConfirmed, sgs.CardFinished },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.from and use.from:isAlive() and use.card and
                (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and use.from:objectName() ==
                player:objectName() then
                for _, lubu in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if lubu and lubu:distanceTo(use.from) <= 1 then
                        local choicelist = {}
                        table.insert(choicelist, "s4_jiwu_no_respond_list")
                        table.insert(choicelist, "s4_jiwu_draw")

                        if lubu:getMark("&s4_jiwu_used+analeptic") == 0 then
                            table.insert(choicelist, "s4_jiwu_nullified")
                        end
                        table.insert(choicelist, "cancel")
                        room:setTag("CurrentUseStruct", data)
                        local x = 0
                        while #choicelist > 1 do
                            local choice = room:askForChoice(lubu, self:objectName(), table.concat(choicelist, "+"),
                                data)
                            if choice == "cancel" then
                                break
                            end
                            x = x + 1
                            if choice == "s4_jiwu_no_respond_list" then
                                local no_respond_list = use.no_respond_list
                                table.insert(no_respond_list, "_ALL_TARGETS")
                                use.no_respond_list = no_respond_list
                                room:setCardFlag(use.card, "s4_jiwu_no_respond")
                                table.removeOne(choicelist, "s4_jiwu_no_respond_list")
                                room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
                                local log= sgs.LogMessage()
                                log.type = "#skill_add_damage_byother1"
                                log.from = lubu
                                log.arg = self:objectName()
                                room:sendLog(log)
                                local log = sgs.LogMessage()
                                log.type = "$NoRespond"
                                log.from = use.from
                                log.to = targets
                                log.arg = self:objectName()
                                log.card_str = use.card:toString()
                                room:sendLog(log)
                            elseif choice == "s4_jiwu_draw" then
                                room:setCardFlag(use.card, self:objectName())
                                room:setPlayerMark(lubu, "s4_jiwu_" .. use.card:getEffectiveId(), 1)
                                table.removeOne(choicelist, "s4_jiwu_draw")
                                room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
                                lubu:drawCards(2)
                            elseif choice == "s4_jiwu_nullified" then
                                room:broadcastSkillInvoke(self:objectName(), 3)
                                local nullified_list = use.nullified_list
                                table.insert(nullified_list, "_ALL_TARGETS")
                                use.nullified_list = nullified_list
                                room:addPlayerMark(lubu, "&s4_jiwu_used+analeptic")
                                table.removeOne(choicelist, "s4_jiwu_nullified")
                                local analeptic = sgs.Sanguosha:cloneCard("analeptic")
                                analeptic:setSkillName(self:objectName())
                                analeptic:deleteLater()
                                local useEX = sgs.CardUseStruct()
                                useEX.from = lubu
                                useEX.card = analeptic
                                room:useCard(useEX, false)
                                useEX.from = use.from
                                room:useCard(useEX, false)
                                room:setCardFlag(use.card, "s4_jiwu_nullified")
                                local log= sgs.LogMessage()
                                log.type = "#skill_add_damage_byother1"
                                log.from = lubu
                                log.arg = self:objectName()
                                room:sendLog(log)
                            end
                            local log = sgs.LogMessage()
                            log.type = "#ChooseSkill"
                            log.from = lubu
                            log.arg = self:objectName()
                            log.arg2 = choice
                            room:sendLog(log)
                        end
                        if x > 0 then
                            local card = room:askForDiscard(lubu, "s4_jiwu_invoke", x, x, true, true, "@s4_jiwu:" .. x)
                            if card then
                            else
                                room:loseHp(lubu, 1, true, lubu, self:objectName())
                            end
                        end
                        data:setValue(use)
                        room:notifySkillInvoked(player, self:objectName())
                        room:removeTag("CurrentUseStruct")
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
s4_jiwuClear = sgs.CreateTriggerSkill {
    name = "#s4_jiwuClear",
    events = { sgs.EventPhaseStart, sgs.CardOffset },
    can_trigger = function(self, target)
        return target
    end,
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start and player:hasSkill("s4_jiwu") then
                if player:getMark("&s4_jiwu_used+analeptic") > 0 then
                    room:setPlayerMark(player, "&s4_jiwu_used+analeptic", 0)
                end
            end
        elseif event == sgs.CardOffset then
            local effect = data:toCardEffect()
            if effect.card and (effect.card:isKindOf("Slash") or effect.card:isKindOf("Duel")) and effect.card:hasFlag("s4_jiwu") then
                for _, lubu in sgs.qlist(room:findPlayersBySkillName("s4_jiwu")) do
                    if lubu and lubu:getMark("s4_jiwu_" .. effect.card:getEffectiveId()) > 0 then
                        room:setPlayerMark(lubu, "s4_jiwu_" .. effect.card:getEffectiveId(), 0)
                        room:sendCompulsoryTriggerLog(lubu, "s4_jiwu")
                        room:askForDiscard(lubu, "s4_jiwu", 2, 2, false, true)
                        room:broadcastSkillInvoke("s4_jiwu", 4)
                    end
                end
            end
        end
        return false
    end
}
s4_lubu:addSkill(s4_xianfeng)
s4_lubu:addSkill(s4_xianfeng_TM)
s4_lubu:addSkill(s4_xianfeng_D)
extension:insertRelatedSkills("s4_xianfeng", "#s4_xianfeng_TM")
extension:insertRelatedSkills("s4_xianfeng", "#s4_xianfeng_D")
s4_lubu:addSkill(s4_jiwu)
s4_lubu:addSkill(s4_jiwuClear)
extension:insertRelatedSkills("s4_jiwu", "#s4_jiwuClear")

sgs.LoadTranslationTable {
    ["s4_lubu"] = "吕布",
    ["#s4_lubu"] = "飛將",
    ["~s4_lubu"] = "",
    ["designer:s4_lubu"] = "终极植物",
    ["cv:s4_lubu"] = "",
    ["illustrator:s4_lubu"] = "",

    ["s4_xianfeng"] = "陷锋",
    ["#s4_xianfeng_D"] = "陷锋",
    [":s4_xianfeng"] = "锁定技，你计算与其他角色的距离-1；你对距离1以内的角色使用【杀】不计入限制的次数且无次数限制。",
    ["$s4_xianfeng1"] = "",
    ["$s4_xianfeng2"] = "",

    ["@s4_jiwu"] = "你可以发动“极武”弃置 %src 张牌或失去1点体力",
    ["s4_jiwu_used"] = "极武",
    ["s4_jiwu_invoke"] = "极武",
    ["s4_jiwu_no_respond_list"] = "此【杀】或【决斗】不能被响应",
    ["s4_jiwu_draw"] = "摸两张牌，当此【杀】或【决斗】被抵消时，你弃置两张牌",
    ["s4_jiwu_nullified"] = "此【杀】或【决斗】无效，你与此牌使用者各视为使用一张无次数限制的【酒】，然后移除此选项直到你下回合开始。",
    ["s4_jiwu"] = "极武",
    [":s4_jiwu"] = "当距离1以内的一名角色使用【杀】或【决斗】指定目标时，你可以选择任意项并弃置等量张牌或失去1点体力：1.此【杀】或【决斗】不能被响应；2.摸两张牌，当此【杀】或【决斗】被抵消时，你弃置两张牌；3.此【杀】或【决斗】无效，你与此牌使用者各视为使用一张无次数限制的【酒】，然后移除此选项直到你下回合开始。",
    ["$s4_jiwu1"] = "",
    ["$s4_jiwu2"] = "",
    ["$s4_jiwu3"] = "",
    ["$s4_jiwu4"] = ""

}
----------------------------------------------------------------
-- https://tieba.baidu.com/p/8519622496
----------------------------------------------------------------

s4_zhaoyun = sgs.General(extension, "s4_zhaoyun", "shu", 4)

s4_jiuzhu = sgs.CreateTriggerSkill {
    name = "s4_jiuzhu",
    events = { sgs.CardsMoveOneTime, sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local current = room:getCurrent()
            if not player or not player:hasSkill(self:objectName()) then return false end
            if not current or current:getPhase() == sgs.Player_NotActive then return false end
            if player:getMark("s4_jiuzhu-using") > 0 then return false end
            local move = data:toMoveOneTime()
            if move.to_place == sgs.Player_DiscardPile then
                local ids, disabled = sgs.IntList(), sgs.IntList()
                local all_ids = move.card_ids
                for _, id in sgs.qlist(move.card_ids) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card and card:isKindOf("BasicCard") and room:getCardPlace(id) == sgs.Player_DiscardPile and player:getMark("&s4_jiuzhu-Clear") == 0 then
                        ids:append(id)
                    else
                        disabled:append(id)
                    end
                end
                if ids:isEmpty() then return false end
                if not ids:isEmpty() then
                    room:fillAG(all_ids, player, disabled)
                    local card_id = room:askForAG(player, ids, true, self:objectName())
                    room:clearAG(player)
                    if card_id == -1 then return false end
                    if not room:askForSkillInvoke(player, self:objectName()) then return false end
                    room:setPlayerMark(player, "s4_jiuzhu-using", 1)
                        player:setMark("YanyuOnlyId", card_id + 1)
                    local card = sgs.Sanguosha:getCard(card_id)
                    local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
                        string.format("@yanyu-give:::%s:%s\\%s", card:objectName(), card:getSuitString() .. "_char"
                        , card:getNumberString()), true, true)
                    player:setMark("YanyuOnlyId", 0)
                    if target then
                        local discard = room:askForDiscard(player, "s4_jiuzhu_invoke", 1, 1, true, true,
                            "@s4_jiuzhu:" .. target:objectName())
                        if discard then
                        else
                            room:loseHp(player, 1, true, player, self:objectName())
                        end
                        if not player:isAlive() then return false end
                        target:obtainCard(card)
                        room:addPlayerMark(player, "&s4_jiuzhu-Clear")
                        room:setPlayerMark(player, "s4_jiuzhu-using", 0)
                        if player:getPhase() ~= sgs.Player_NotActive then
                            if room:askForSkillInvoke(player, self:objectName()) then
                                player:drawCards(2, self:objectName())
                            end
                        else
                            if not current:isNude() then
                                local targets = sgs.SPlayerList()
                                targets:append(current)
                                room:setPlayerFlag(player, "s4_jiuzhu_current")
                                local target = room:askForPlayerChosen(player, targets, self:objectName(), "s4_jiuzhu-invoke", true, true)
                                room:setPlayerFlag(player, "-s4_jiuzhu_current")
                                if target then
                                    local id = room:askForCardChosen(player, current, "he", self:objectName())
                                    if id ~= -1 then
                                        room:obtainCard(player, id, false)
                                    end
                                end
                            end
                        end
                    else
                        return false
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
s4_zhaoyun:addSkill(s4_jiuzhu)

sgs.LoadTranslationTable {
    ["s4_zhaoyun"] = "赵云",
    ["#s4_zhaoyun"] = "七進七出",
    ["~s4_zhaoyun"] = "",
    ["designer:s4_zhaoyun"] = "终极植物",
    ["cv:s4_zhaoyun"] = "",
    ["illustrator:s4_zhaoyun"] = "",

    ["s4_jiuzhu-invoke"] = "你可以发动“救主”<br/> <b>操作提示</b>: 选择当前回合角色→点击确定<br/>",
    ["@s4_jiuzhu"] = "你可以发动“救主”弃置一张牌或失去1点体力",
    ["s4_jiuzhu"] = "救主",
    [":s4_jiuzhu"] = "每回合限一次，当一张基本牌进入弃牌堆后，你可以弃置一张牌或失去1点体力，令一名角色获得此基本牌。然后若此时是你的回合，你可以摸两张牌；若不是，你可以获得当前回合角色一张牌。",
    ["$s4_jiuzhu1"] = "",
    ["$s4_jiuzhu2"] = "",

}
----------------------------------------------------------------
-- https://tieba.baidu.com/p/8628062146
----------------------------------------------------------------



local s4_skillList = sgs.SkillList()

s4_txbw_disgeneralCard = sgs.CreateSkillCard {
    name = "s4_txbw_disgeneral",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        room:setPlayerMark(source, "@s4_txbw_general_1", 0)
        room:setPlayerMark(source, "@s4_txbw_general_2", 0)
    end
}
s4_txbw_disgeneral = sgs.CreateViewAsSkill {
    name = "s4_txbw_disgeneral&",
    n = 0,
    view_as = function(self, cards)
        if #cards == 0 then
            local card = s4_txbw_disgeneralCard:clone()
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@s4_txbw_general_1") > 0 or player:getMark("@s4_txbw_general_2") > 0
    end
}

s4_txbw_general_gain = sgs.CreateTriggerSkill {
    name = "s4_txbw_general_gain&",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.GameStart },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:addPlayerMark(player, "@s4_txbw_general_1")
        return false
    end
}

s4_txbw_general_limit = sgs.CreateCardLimitSkill {
    name = "s4_txbw_general_limit",
    limit_list = function(self, player)
        if player and (player:getMark("@s4_txbw_general_1") > 0 or player:getMark("@s4_txbw_general_2") > 0) and player:getPhase() == sgs.Player_Play and
            not player:hasFlag("s4_txbw_general_duel") then
            return "use"
        end
    end,
    limit_pattern = function(self, player)
        if player and (player:getMark("@s4_txbw_general_1") > 0 or player:getMark("@s4_txbw_general_2") > 0) and player:getPhase() == sgs.Player_Play and
            not player:hasFlag("s4_txbw_general_duel") then
            return "Slash"
        end
    end
}

s4_txbw_general = sgs.CreateTriggerSkill {
    name = "s4_txbw_general",
    global = true,
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.GameStart },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart then
            --for _, p in sgs.qlist(room:getAlivePlayers()) do
                if player:getMark("@s4_txbw_general_1") > 0 then
                    room:attachSkillToPlayer(player, "s4_txbw_disgeneral")
                    room:attachSkillToPlayer(player, "s4_txbw_general_duel")
                    room:attachSkillToPlayer(player, "s4_txbw_general_duel_rule")
                end
            --end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}


-- Helper: Trigger event for players with timing name
local function triggerDuelEvent(room, eventName, from, tos, player, extraData)
    local data = sgs.QVariant(eventName..":"..from:objectName()..":"..table.concat(tos,"+")..(extraData or ""))
    room:getThread():trigger(sgs.EventForDiy, room, player, data)
    return data
end

-- Helper: Send log message with player point information
local function sendPlayerPointLog(room, logType, players, dueldata)
    local log = sgs.LogMessage()
    log.type = logType
    room:sendLog(log)
    
    for _, p in sgs.list(players) do
        local num = dueldata.toNum[p:objectName()]
        if type(num) == "number" then
            local msg = sgs.LogMessage()
            msg.type = logType.."_point"
            msg.from = p
            msg.arg = num
            room:sendLog(msg)
        end
    end
end

-- Helper: Get duel card for player (from hand or deck top)
local function getDuelCardForPlayer(room, player)
    if player:isKongcheng() then
        -- 无手牌的角色改为将牌堆顶的一张牌作为对决牌扣置
        return sgs.Sanguosha:getCard(room:getNCards(1):first())
    else
        return room:askForExchange(player, "s4_txbw_general_duel", 1, 1, false)
    end
end

-- Helper: Apply reward for players with marks
local function applyRewardForMarkedPlayers(room, from, player)
    if player:getMark("@s4_txbw_general_1") > 0 or player:getMark("@s4_txbw_general_2") > 0 then
        local drawCount = from:isKongcheng() and 2 or 1
        from:drawCards(drawCount)
    end
end

-- Phase 1: Initialize duel and apply rewards
local function initializeDuel(dueldata, log, room)
    local duelcards = {}
    
    for _, p in sgs.list(log.to) do
        table.insert(dueldata.tos, p:objectName())
        room:doAnimate(1, dueldata.from:objectName(), p:objectName())
        applyRewardForMarkedPlayers(room, dueldata.from, p)
    end
    
    -- Set duel flag and occupy slash count
    room:setPlayerFlag(dueldata.from, "s4_txbw_general_duel")
    if dueldata.from:getMark("s4_txbw_general_duel_slash-Clear") == 0 then
        room:addPlayerMark(dueldata.from, "s4_txbw_general_duel_slash-Clear")
        room:addPlayerHistory(dueldata.from, "Slash", 1)
    end
    
    -- Trigger: DuelStart
    triggerDuelEvent(room, "s4_txbw_DuelStart", dueldata.from, dueldata.tos, dueldata.from, "")
    
    return duelcards
end

-- Phase 2: Choose and collect duel cards
local function collectDuelCards(dueldata, log, room)
    local duelcards = {}
    
    log.type = "#s4_txbw_general_duel_choose"
    room:sendLog(log)
    
    for _, p in sgs.list(log.to) do
        -- Trigger: DuelChoose - allow skill to provide card
        local data = triggerDuelEvent(room, "s4_txbw_DuelChoose", dueldata.from, dueldata.tos, p, "")
        local ask = data:toString():split(":")
        
        if #ask > 3 then
            duelcards[p:objectName()] = sgs.Card_Parse(ask[4])
            p:setTag("s4_txbw_general_duel_card", sgs.QVariant(duelcards[p:objectName()]))
        end
        
        -- Get card from player if not provided by skill
        if type(duelcards[p:objectName()]) ~= "userdata" then
            duelcards[p:objectName()] = getDuelCardForPlayer(room, p)
            p:setTag("s4_txbw_general_duel_card", sgs.QVariant(duelcards[p:objectName()]))
        end
    end
    
    -- Trigger: DuelAfterChoose - allow modification after all cards chosen
    for _, p in sgs.list(log.to) do
        triggerDuelEvent(room, "s4_txbw_DuelAfterChoose", dueldata.from, dueldata.tos, p, "")
        for _, q in sgs.list(log.to) do
            duelcards[q:objectName()] = q:getTag("s4_txbw_general_duel_card"):toCard()
        end
    end
    
    return duelcards
end

-- Phase 3: Show and record duel cards
local function showDuelCards(dueldata, log, room, duelcards)
    log.type = "#s4_txbw_general_duel_show"
    room:sendLog(log)
    
    dueldata.ids = {}
    dueldata.tos = {}
    dueldata.toNum = {}
    room:getThread():delay(800)
    
    for _, p in sgs.list(log.to) do
        local dc = duelcards[p:objectName()]
        if type(dc) == "userdata" then
            local msg = sgs.LogMessage()
            msg.type = "#s4_txbw_general_duel_show_card"
            msg.from = p
            msg.card_str = dc:toString()
            room:sendLog(msg)
            
            room:showCard(p, dc:getSubcards())
            room:moveCardTo(dc, nil, nil, sgs.Player_DiscardPile, 
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RULEDISCARD, "", "s4_txbw_general_duel", ""))
            
            table.insert(dueldata.ids, dc:toString())
            table.insert(dueldata.tos, p:objectName())
            dueldata.toNum[p:objectName()] = dc:getNumber()
        end
    end
    
    -- Trigger: AfterShow - allow modification of points after showing
    for _, p in sgs.list(log.to) do
        local extra = ":"..dueldata.toNum[dueldata.from:objectName()]..":"..dueldata.toNum[p:objectName()]
        local data = triggerDuelEvent(room, "s4_txbw_AfterShow", dueldata.from, dueldata.tos, p, extra)
        local ask = data:toString():split(":")
        dueldata.toNum[dueldata.from:objectName()] = ask[4]
        dueldata.toNum[p:objectName()] = ask[5]
    end
end

-- Phase 4: Calculate final points
local function calculatePoints(dueldata, log, room)
    sendPlayerPointLog(room, "#s4_txbw_general_duel_cal", log.to, dueldata)
    
    -- Trigger: Cal - allow point adjustments
    for _, p in sgs.list(log.to) do
        local extra = ":"..dueldata.toNum[dueldata.from:objectName()]..":"..dueldata.toNum[p:objectName()]
        local data = triggerDuelEvent(room, "s4_txbw_Cal", dueldata.from, dueldata.tos, p, extra)
        local ask = data:toString():split(":")
        
        if #ask > 5 then
            dueldata.toNum[p:objectName()] = dueldata.toNum[p:objectName()] + tonumber(ask[6])
        end
    end
    
    sendPlayerPointLog(room, "#s4_txbw_general_duel_result", log.to, dueldata)
end

-- Phase 5: Determine winner and losers
local function determineWinner(dueldata, log)
    local winner, losers, notwin = nil, {}, {}
    local draw = false
    
    -- Check for forced winner
    for _, p in sgs.list(log.to) do
        if p:hasFlag("s4_txbw_general_duel_force_win") then
            winner = p
            for _, q in sgs.list(log.to) do
                if not q:hasFlag("s4_txbw_general_duel_force_win") then
                    table.insert(losers, q)
                    table.insert(notwin, q)
                else
                    draw = true
                    break
                end
            end
            break
        end
    end
    
    -- Calculate winner by points
    if not winner then
        local maxnum = -1
        for _, p in sgs.list(log.to) do
            local num = dueldata.toNum[p:objectName()]
            if type(num) == "number" and num > maxnum then
                maxnum = num
                winner = p
            end
        end
        
        for _, p in sgs.list(log.to) do
            local num = dueldata.toNum[p:objectName()]
            if type(num) == "number" then
                if num < maxnum and p:objectName() ~= winner:objectName() then
                    table.insert(losers, p)
                    table.insert(notwin, p)
                elseif num == maxnum and p:objectName() ~= winner:objectName() then
                    draw = true
                    break
                end
            end
        end
    end
    
    -- Handle draw
    if draw then
        winner = nil
        for _, p in sgs.list(log.to) do
            table.insert(notwin, p)
        end
    end
    
    return winner, losers, notwin
end

-- Phase 6: Process winner and trigger win events
local function processWinner(dueldata, log, room, duelcards, winner, notwin)
    if not winner then return nil, false end
    
    local msg = sgs.LogMessage()
    msg.type = "#s4_txbw_general_duel_Success"
    msg.from = winner
    for _, p in sgs.list(notwin) do
        msg.to:append(p)
    end
    room:sendLog(msg)
    room:setEmotion(winner, "success")
    
    local winCard = duelcards[winner:objectName()]
    
    -- Trigger: Win
    local data = triggerDuelEvent(room, "s4_txbw_Win", dueldata.from, dueldata.tos, winner, 
        ":"..winner:objectName()..":"..winCard:toString())
    local ask = data:toString():split(":")
    winCard = sgs.Sanguosha:getCard(ask[5])
    
    local throwEvent = false
    -- Trigger: Notwin
    for _, p in sgs.list(notwin) do
        local data = triggerDuelEvent(room, "s4_txbw_Notwin", dueldata.from, dueldata.tos, p,
            ":"..winner:objectName()..":"..winCard:toString())
        
        if not room:getThread():trigger(sgs.EventForDiy, room, p, data) then
            winner = data:toString():split(":")[4]
            winCard = sgs.Sanguosha:getCard(data:toString():split(":")[5])
        else
            throwEvent = true
        end
    end
    
    return winCard, throwEvent
end

-- Phase 7: Apply damage to losers
local function applyDamageToLosers(room, winner, losers, winCard)
    for _, loser in sgs.list(losers) do
        local jink = room:askForCard(loser, "jink", "@s4_txbw_general_duel-jink:"..winner:objectName(),
            sgs.QVariant(), sgs.Card_MethodResponse, nil, false, "", true)
        
        if not jink then
            local damage = sgs.DamageStruct()
            damage.card = nil
            damage.from = winner
            damage.to = loser
            damage.reason = "s4_txbw_general_duel"
            damage.damage = 1
            
            if winCard:isKindOf("ThunderSlash") or winCard:isKindOf("Lighting") then
                damage.nature = sgs.DamageStruct_Thunder
            elseif winCard:isKindOf("FireSlash") or winCard:isKindOf("FireAttack") then
                damage.nature = sgs.DamageStruct_Fire
            end
            
            room:damage(damage)
        end
    end
end

-- Phase 8: Cleanup and final trigger
local function finalizeDuel(dueldata, log, room, winner, winCard)
    -- Trigger: Result
    for _, p in sgs.list(log.to) do
        local extra = ":"..dueldata.toNum[dueldata.from:objectName()]..":"..dueldata.toNum[p:objectName()]
        triggerDuelEvent(room, "s4_txbw_Result", dueldata.from, dueldata.tos, p, extra)
    end
    
    log.type = "#s4_txbw_general_duel_finish"
    room:sendLog(log)
    
    -- Trigger: Duelresult (final event)
    local extra = ":"..table.concat(dueldata.ids, "+")..":"..(winner and winner:objectName() or "nil")..
        ":"..(winCard and winCard:toString() or "nil")
    triggerDuelEvent(room, "s4_txbw_Duelresult", dueldata.from, dueldata.tos, dueldata.from, extra)
    
    -- Clear flags and tags
    for _, p in sgs.list(log.to) do
        room:setPlayerFlag(p, "-s4_txbw_general_duel_force_win")
        p:removeTag("s4_txbw_general_duel_card")
    end
end

-- Main function: Orchestrates the duel process
function askforDuel(dueldata)
    if type(dueldata.from) ~= "userdata" then return end
    
    -- Setup
    local log = sgs.LogMessage()
    log.type = "$s4_txbw_general_duel_start"
    log.from = dueldata.from
    for _, p in sgs.list(dueldata.tos) do
        log.to:append(p)
    end
    dueldata.tos = {}
    dueldata.result = "no_result"
    
    if log.to:isEmpty() then return dueldata end
    
    local room = dueldata.from:getRoom()
    room:sortByActionOrder(log.to)
    room:sendLog(log)
    
    -- Execute duel phases
    local duelcards = initializeDuel(dueldata, log, room)
    duelcards = collectDuelCards(dueldata, log, room)
    showDuelCards(dueldata, log, room, duelcards)
    calculatePoints(dueldata, log, room)
    
    local winner, losers, notwin = determineWinner(dueldata, log)
    local winCard, throwEvent = processWinner(dueldata, log, room, duelcards, winner, notwin)
    
    if not throwEvent and winner then
        applyDamageToLosers(room, winner, losers, winCard)
    end
    
    finalizeDuel(dueldata, log, room, winner, winCard)
    
    return dueldata
end


s4_txbw_general_duelCard = sgs.CreateSkillCard {
    name = "s4_txbw_general_duel_start",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if to_select:objectName() ~= sgs.Self:objectName() then
            return #targets == 0
        end
        return false
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        room:setPlayerFlag(target, "s4_txbw_general_duel_victim")
        room:setPlayerFlag(source, "s4_txbw_general_duel_start")
        room:setPlayerFlag(source, "s4_txbw_general_duel")
        source:setTag("s4_txbw_general_duel", ToQVData(target))
        target:setTag("s4_txbw_general_duel", ToQVData(source))
        
        local targets = sgs.SPlayerList()
        targets:append(target)
        local dueldata = {}
		dueldata.from = player
		dueldata.tos = targets
        askforDuel(dueldata)
    end
}
s4_txbw_general_duel_chooseCard = sgs.CreateSkillCard {
    name = "s4_txbw_general_duel_choose",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if to_select:objectName() ~= sgs.Self:objectName() then
            return #targets == 0
        end
        return false
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        local msg = sgs.LogMessage()
        msg.type = "#s4_txbw_general_duel_choose"
        msg.from = source
        msg.to:append(target)
        room:sendLog(msg)

        local card_s
        local card_v
        if source:isKongcheng() then
            card_s = sgs.Sanguosha:getCard(room:getNCards(1):first())
        else
            card_s = room:askForCard(source, ".|.|.|hand!", "s4_txbw_general_duel", sgs.QVariant(), sgs.Card_MethodNone,
                source,
                false, "s4_txbw_general_duel", true)
        end
        room:setTag("s4_txbw_general_duel_s", sgs.QVariant(card_s:getId()))
        if target:isKongcheng() then
            --card_v = room:drawCards(1)
            card_v = sgs.Sanguosha:getCard(room:getNCards(1):first())
        else
            card_v = room:askForCard(target, ".|.|.|hand!", "s4_txbw_general_duel", sgs.QVariant(), sgs.Card_MethodNone,
                source,
                false, "s4_txbw_general_duel", true)
        end
        room:setTag("s4_txbw_general_duel_v", sgs.QVariant(card_v:getId()))
    end
}
s4_txbw_general_duel_showCard = sgs.CreateSkillCard {
    name = "s4_txbw_general_duel_show",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if to_select:objectName() ~= sgs.Self:objectName() then
            return #targets == 0
        end
        return false
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        local msg = sgs.LogMessage()
        msg.type = "#s4_txbw_general_duel_show"
        msg.from = source
        msg.to:append(target)
        room:sendLog(msg)

        local card_s = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_s"):toInt())
        local card_v = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_v"):toInt())
        room:setPlayerMark(source, "s4_txbw_general_duel", card_s:getNumber())
        room:setPlayerMark(target, "s4_txbw_general_duel", card_v:getNumber())
        local msg1 = sgs.LogMessage()
        msg1.type = "#s4_txbw_general_duel_show_card"
        msg1.from = source
        msg1.card_str = card_s:objectName()
        room:sendLog(msg1)
        local msg2 = sgs.LogMessage()
        msg2.type = "#s4_txbw_general_duel_show_card"
        msg2.from = target
        msg2.card_str = card_v:objectName()
        room:sendLog(msg2)
        room:moveCardTo(card_s, nil, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(
            sgs.CardMoveReason_S_REASON_RULEDISCARD, "", "s4_txbw_general_duel", ""))
        room:moveCardTo(card_v, nil, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(
            sgs.CardMoveReason_S_REASON_RULEDISCARD, "", "s4_txbw_general_duel", ""))
    end
}
s4_txbw_general_duel_calCard = sgs.CreateSkillCard {
    name = "s4_txbw_general_duel_cal",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if to_select:objectName() ~= sgs.Self:objectName() then
            return #targets == 0
        end
        return false
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        local msg = sgs.LogMessage()
        msg.type = "#s4_txbw_general_duel_cal"
        msg.from = source
        msg.to:append(target)
        room:sendLog(msg)

        local start = source:getMark("s4_txbw_general_duel")
        local victim = target:getMark("s4_txbw_general_duel")
        local msg1 = sgs.LogMessage()
        msg1.type = "#s4_txbw_general_duel_cal_point"
        msg1.from = source
        msg1.arg = start
        room:sendLog(msg1)
        local msg2 = sgs.LogMessage()
        msg2.type = "#s4_txbw_general_duel_cal_point"
        msg2.from = target
        msg2.arg = victim
        room:sendLog(msg2)
    end
}
s4_txbw_general_duel_resultCard = sgs.CreateSkillCard {
    name = "s4_txbw_general_duel_result",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if to_select:objectName() ~= sgs.Self:objectName() then
            return #targets == 0
        end
        return false
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        local msg = sgs.LogMessage()
        msg.type = "#s4_txbw_general_duel_result"
        msg.from = source
        msg.to:append(target)
        room:sendLog(msg)

        local start = source:getMark("s4_txbw_general_duel")
        local victim = target:getMark("s4_txbw_general_duel")
        local msg1 = sgs.LogMessage()
        msg1.type = "#s4_txbw_general_duel_result_point"
        msg1.from = source
        msg1.arg = start
        local msg2 = sgs.LogMessage()
        msg2.type = "#s4_txbw_general_duel_result_point"
        msg2.from = target
        msg2.arg = victim
        room:sendLog(msg1)
        room:sendLog(msg2)
        local winner = sgs.QVariant()
        local loser = sgs.QVariant()
        local winCard
        if (start > victim) or source:hasFlag("s4_txbw_general_duel_force_win") then
            winner:setValue(source)
            loser:setValue(target)
            winCard = room:getTag("s4_txbw_general_duel_s"):toInt()
            local msg = sgs.LogMessage()
            msg.type = "#s4_txbw_general_duel_Success"
            msg.from = source
            msg.to:append(target)
            room:sendLog(msg)
            room:setEmotion(source, "success")
        elseif start < victim or source:hasFlag("s4_txbw_general_duel_force_win") then
            winCard = room:getTag("s4_txbw_general_duel_v"):toInt()
            winner:setValue(target)
            loser:setValue(source)
            local msg = sgs.LogMessage()
            msg.type = "#s4_txbw_general_duel_Success"
            msg.from = target
            msg.to:append(source)
            room:sendLog(msg)
            room:setEmotion(target, "success")
            room:setPlayerFlag(source, "s4_txbw_general_duel_not_win")
        else
            room:setPlayerFlag(source, "s4_txbw_general_duel_not_win")
        end
        room:setTag("s4_txbw_general_duel_winner", winner)
        room:setTag("s4_txbw_general_duel_wincard", sgs.QVariant(winCard))
        room:setTag("s4_txbw_general_duel_loser", loser)
    end
}
s4_txbw_general_duel_finishCard = sgs.CreateSkillCard {
    name = "s4_txbw_general_duel_finish",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select)
        if to_select:objectName() ~= sgs.Self:objectName() then
            return #targets == 0
        end
        return false
    end,
    on_effect = function(self, effect)
        local source = effect.from
        local target = effect.to
        local room = source:getRoom()
        local msg = sgs.LogMessage()
        msg.type = "#s4_txbw_general_duel_finish"
        msg.from = source
        msg.to:append(target)
        room:sendLog(msg)
        local winner = room:getTag("s4_txbw_general_duel_winner"):toPlayer()
        local loser = room:getTag("s4_txbw_general_duel_loser"):toPlayer()
        if winner and winner:isAlive() and loser and loser:isAlive() then
            local jink = room:askForCard(loser, "jink", "@s4_txbw_general_duel-jink:" .. winner:objectName(),
                sgs.QVariant(), sgs.Card_MethodResponse, nil, false, "", true)
            if jink then
            else
                local duel_damage = 1 + winner:getMark("s4_txbw_general_duel_damage") +
                    winner:getMark("s4_txbw_general_duel_damage-Clear")
                local damage = sgs.DamageStruct()
                damage.card = nil
                damage.from = winner
                damage.to = loser
                damage.reason = "s4_txbw_general_duel"
                damage.damage = duel_damage

                local winCard = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_wincard"):toInt())
                if winCard:isKindOf("ThunderSlash") or winCard:isKindOf("Lighting") then
                    damage.nature = sgs.DamageStruct_Thunder
                end
                if winCard:isKindOf("FireSlash") or winCard:isKindOf("FireAttack") then
                    damage.nature = sgs.DamageStruct_Fire
                end
                room:damage(damage)
            end
        end
    end
}

s4_txbw_general_duel = sgs.CreateViewAsSkill {
    name = "s4_txbw_general_duel&",
    n = 0,
    view_as = function(self, cards)
        if #cards == 0 then
            local card = s4_txbw_general_duelCard:clone()
            card:setSkillName("s4_txbw_general_duel_start")
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return (player:getMark("@s4_txbw_general_1") > 0 or player:getMark("@s4_txbw_general_2") > 0) and player:usedTimes("#s4_txbw_general_duel_start") < 1 +
            player:getMark("s4_txbw_general_duel_extra") + player:getMark("s4_txbw_general_duel_extra-Clear")
    end
}

s4_txbw_general_duel_rule = sgs.CreateTriggerSkill {
    name = "s4_txbw_general_duel_rule&",
    global = true,
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_start") then
                    local card = s4_txbw_general_duel_chooseCard:clone()
                    card:setSkillName("s4_txbw_general_duel_choose")
                    local use_ex = sgs.CardUseStruct()
                    use_ex.card = card
                    use_ex.from = player
                    use_ex.to = use.to
                    room:useCard(use_ex)
                elseif table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_choose") then
                    local card = s4_txbw_general_duel_showCard:clone()
                    card:setSkillName("s4_txbw_general_duel_show")
                    local use_ex = sgs.CardUseStruct()
                    use_ex.card = card
                    use_ex.from = player
                    use_ex.to = use.to
                    room:useCard(use_ex)
                elseif table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_show") then
                    local card = s4_txbw_general_duel_calCard:clone()
                    card:setSkillName("s4_txbw_general_duel_cal")
                    local use_ex = sgs.CardUseStruct()
                    use_ex.card = card
                    use_ex.from = player
                    use_ex.to = use.to
                    room:useCard(use_ex)
                elseif table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_cal") then
                    local card = s4_txbw_general_duel_resultCard:clone()
                    card:setSkillName("s4_txbw_general_duel_result")
                    local use_ex = sgs.CardUseStruct()
                    use_ex.card = card
                    use_ex.from = player
                    use_ex.to = use.to
                    room:useCard(use_ex)
                elseif table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_result") then
                    local card = s4_txbw_general_duel_finishCard:clone()
                    card:setSkillName("s4_txbw_general_duel_finish")
                    local use_ex = sgs.CardUseStruct()
                    use_ex.card = card
                    use_ex.from = player
                    use_ex.to = use.to
                    room:useCard(use_ex)
                elseif table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_finish") then
                    room:setPlayerMark(use.from, "s4_txbw_general_duel", 0)
                    room:setPlayerMark(use.to:first(), "s4_txbw_general_duel", 0)
                    room:removeTag("s4_txbw_general_duel_s")
                    room:removeTag("s4_txbw_general_duel_v")
                    room:removeTag("s4_txbw_general_duel_winner")
                    room:removeTag("s4_txbw_general_duel_loser")
                    room:removeTag("s4_txbw_general_duel_wincard")
                    use.from:removeTag("s4_txbw_general_duel")
                    use.to:first():removeTag("s4_txbw_general_duel")
                    room:setPlayerFlag(use.from, "-s4_txbw_general_duel_not_win")
                    room:setPlayerFlag(use.to:first(), "-s4_txbw_general_duel_not_win")
                    room:setPlayerFlag(use.from, "-s4_txbw_general_duel_force_win")
                    room:setPlayerFlag(use.to:first(), "-s4_txbw_general_duel_force_win")
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

local skill = sgs.Sanguosha:getSkill("s4_txbw_general_gain")
if not skill then
    local skillList = sgs.SkillList()
    skillList:append(s4_txbw_general_gain)
    sgs.Sanguosha:addSkills(skillList)
end
local skill = sgs.Sanguosha:getSkill("s4_txbw_general")
if not skill then
    local skillList = sgs.SkillList()
    skillList:append(s4_txbw_general)
    sgs.Sanguosha:addSkills(skillList)
end
local skill = sgs.Sanguosha:getSkill("s4_txbw_disgeneral")
if not skill then
    local skillList = sgs.SkillList()
    skillList:append(s4_txbw_disgeneral)
    sgs.Sanguosha:addSkills(skillList)
end
local skill = sgs.Sanguosha:getSkill("s4_txbw_general_duel_rule")
if not skill then
    local skillList = sgs.SkillList()
    skillList:append(s4_txbw_general_duel_rule)
    sgs.Sanguosha:addSkills(skillList)
end
local skill = sgs.Sanguosha:getSkill("s4_txbw_general_duel")
if not skill then
    local skillList = sgs.SkillList()
    skillList:append(s4_txbw_general_duel)
    sgs.Sanguosha:addSkills(skillList)
end
local skill = sgs.Sanguosha:getSkill("s4_txbw_general_limit")
if not skill then
    local skillList = sgs.SkillList()
    skillList:append(s4_txbw_general_limit)
    sgs.Sanguosha:addSkills(skillList)
end
sgs.LoadTranslationTable {
    ["s4_txbw_general_gain"] = "武将",
    ["@s4_txbw_general_1"] = "武将",
    ["@s4_txbw_general_2"] = "武将",
    ["s4_txbw_disgeneral"] = "弃武从文",
    [":s4_txbw_disgeneral"] = "出牌阶段，你可以移除武将标签。若如此做，你不再是武将，失去所有和对决相关的技能。",
    ["s4_txbw_general_duel_rule"] = "武将規則",
    [":s4_txbw_general_duel_rule"] = "1.发起对决:\
    ①武将A指定一名目标B。\
    ②若B也为武将，执行犒赏:\
    若此时你有至少一张手牌，摸1张牌;\
    若此时你没有手牌，摸2张牌。\
    双方各将一张手牌背面向上置于桌面。这张牌称为对决牌。\
    无手牌的角色改为将牌堆顶的一张牌作为对决牌扣置。\
    根据双方的对决点数，判定对决胜负。\
若A的对决点数大于B的对决点数，视为A赢，B没赢，A执行胜利效果。\
若A的对决点数等于B的对决点数，视为A、B都没赢，不执行胜利效果。\
    ",
    ["s4_txbw_general_duel"] = "对决",
    [":s4_txbw_general_duel"] = "出牌阶段，你可以指定一名其他角色，发起对决。 \
    出牌阶段，\
    ①如果未发起对决，便不能使用【杀】。\
    ②如无特殊说明，发起对决的次数限制为1。\
    ③发起对决(无论多少次)会占用一次使用【杀】的次数。\
    双方各将一张手牌背面向上置于桌面。这张牌称为对决牌。\
    无手牌的角色改为将牌堆顶的一张牌作为对决牌扣置。\
    若A赢，B需使用一张【闪】，若B不如此做，受到A对其造成的1点对决伤害。\
    若A的对决牌为【火杀】【火攻】，该对决伤害为火属性。\
    若A的对决牌为【雷杀】【闪电】，该对决伤害为雷属性。",

    
    ["$s4_txbw_general_duel_start"] = "%from 向 %to 发起了对决",

    ["#s4_txbw_general_duel_start"] = "%from 向 %to 发起了对决",
    ["s4_txbw_general_duel_start"] = "发起对决",
    ["#s4_txbw_general_duel_choose"] = "%from 和 %to 扣置对决牌",
    ["s4_txbw_general_duel_choose"] = "扣置对决牌",
    ["#s4_txbw_general_duel_show"] = "%from 和 %to 亮出对决牌",
    ["s4_txbw_general_duel_show"] = "亮出对决牌",
    ["#s4_txbw_general_duel_show_card"] = "%from 的对决牌为 %card ",
    ["#s4_txbw_general_duel_cal"] = "%from 和 %to 计算对决牌点数",
    ["s4_txbw_general_duel_cal"] = "计算对决牌点数",
    ["#s4_txbw_general_duel_cal_point"] = "%from 的对决牌点数为 %arg ",
    ["#s4_txbw_general_duel_result"] = "%from 和 %to 判定对决胜负。",
    ["s4_txbw_general_duel_result"] = "判定对决胜负",
    ["#s4_txbw_general_duel_result_point"] = "%from 的对决牌点数为 %arg ",
    ["#s4_txbw_general_duel_Success"] = "%from 在 %to 对决中获胜。",
    ["#s4_txbw_general_duel_finish"] = "%from 和 %to 执行对决胜利效果。",
    ["s4_txbw_general_duel_finish"] = "执行对决胜利效果",
    ["#s4_txbw_general_duel_cal_point_add"] = "%from 的技能 %arg 被触发，对决牌点数上升至 %arg2 点",

    ["@s4_txbw_general_duel-jink"] = " %src 对决中获胜，你需使用一张【闪】，否则受到 %src 对你造成的1点对决伤害。"

}

s4_txbw_xuchu = sgs.General(extension, "s4_txbw_xuchu", "wei", 4, true)

s4_txbw_luoyiBuff = sgs.CreateTriggerSkill {
    name = "#s4_txbw_luoyiBuff",
    frequency = sgs.Skill_Frequent,
    events = { sgs.DamageCaused, sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.chain or damage.transfer or (not damage.by_user) then
                return false
            end
            local reason = damage.reason
            if reason and reason == "s4_txbw_general_duel" then
                room:sendCompulsoryTriggerLog(player, "s4_txbw_luoyi", true)
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Start then
                room:setPlayerMark(player, "&s4_txbw_luoyi", 0)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:getMark("&s4_txbw_luoyi") > 0 and target:isAlive()
    end
}
s4_txbw_luoyi = sgs.CreateTriggerSkill {
    name = "s4_txbw_luoyi",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Draw and not player:isSkipped(sgs.Player_Draw) and
            player:askForSkillInvoke(self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            player:skip(change.to)
            local ids = room:showDrawPile(player, 3, self:objectName())

            room:fillAG(ids, player)
            room:clearAG(player)
            local max = 0
            for _, id in sgs.qlist(ids) do
                local card = sgs.Sanguosha:getCard(id);
                if card:getNumber() > max then
                    max = card:getNumber()
                end
            end
            local card_to_throw = sgs.IntList()
            local card_to_gotback = sgs.IntList()
            for _, id in sgs.qlist(ids) do
                local card = sgs.Sanguosha:getCard(id);
                if (card:isKindOf("Weapon") or card:getNumber() == max) then
                    card_to_gotback:append(id)
                else
                    if (room:getCardPlace(id) == sgs.Player_PlaceTable) then
                        card_to_throw:append(id)
                    end
                end
            end
            if (not card_to_throw:isEmpty()) then
                local dummy = dummyCard()
                for _, id in sgs.qlist(card_to_throw) do
                    dummy:addSubcard(id)
                end
                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(),
                    "jianyan", nil)
                room:throwCard(dummy, reason, nil)
            end
            if (not card_to_gotback:isEmpty()) then
                local dummy = dummyCard()
                for _, id in sgs.qlist(card_to_gotback) do
                    dummy:addSubcard(id)
                end

                room:obtainCard(player, dummy)
            end
            room:addPlayerMark(player, "&" .. self:objectName())
        end
    end
}

s4_txbw_xuchu:addSkill("s4_txbw_general_gain")
--s4_txbw_xuchu:addSkill("s4_txbw_general")
s4_txbw_xuchu:addSkill(s4_txbw_luoyi)
s4_txbw_xuchu:addSkill(s4_txbw_luoyiBuff)
extension:insertRelatedSkills("s4_txbw_luoyi", "#s4_txbw_luoyiBuff")

sgs.LoadTranslationTable {
    ["s4_txbw_xuchu"] = "许褚",
    ["&s4_txbw_xuchu"] = "许褚",
    ["#s4_txbw_xuchu"] = "虎痴",
    ["~s4_txbw_xuchu"] = "",
    ["designer:s4_txbw_xuchu"] = "",
    ["cv:s4_txbw_xuchu"] = "",
    ["illustrator:s4_txbw_xuchu"] = "",

    ["s4_txbw_luoyi"] = "裸衣",
    [":s4_txbw_luoyi"] = "你可以跳过摸牌阶段。若如此做，亮出牌堆顶三张牌，然后获得其中点数最大的牌和武器牌，直到你的下回合开始，你的对决伤害+1。"

}

s4_txbw_dianwei = sgs.General(extension, "s4_txbw_dianwei", "wei", 4, true)

s4_txbw_feidang = sgs.CreateTriggerSkill {
    name = "s4_txbw_feidang",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_result") then
                    if player:hasFlag("s4_txbw_general_duel_not_win") and player:hasSkill(self:objectName()) then
                        if room:askForSkillInvoke(player, self:objectName(), ToQVData(winner)) then
                            if room:askForCard(player, "Weapon", "s4_txbw_feidang:" .. winner:objectName(),
                                    ToQVData(winner)) then
                            else
                                room:loseHp(player, 1, true, player, self:objectName())
                            end
                            local damage = sgs.DamageStruct()
                            damage.card = nil
                            damage.from = player
                            damage.to = winner
                            damage.reason = "s4_txbw_general_duel"
                            damage.damage = 1
                            room:damage(damage)
                            room:removeTag("s4_txbw_general_duel_wincard")
                            room:removeTag("s4_txbw_general_duel_winner")
                            room:removeTag("s4_txbw_general_duel_loser")
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
s4_txbw_dianwei:addSkill("s4_txbw_general_gain")
s4_txbw_dianwei:addSkill(s4_txbw_feidang)
sgs.LoadTranslationTable {
    ["s4_txbw_dianwei"] = "典韦",
    ["&s4_txbw_dianwei"] = "典韦",
    ["#s4_txbw_dianwei"] = "淯水芳魂",
    ["~s4_txbw_dianwei"] = "",
    ["designer:s4_txbw_dianwei"] = "",
    ["cv:s4_txbw_dianwei"] = "",
    ["illustrator:s4_txbw_dianwei"] = "",

    ["s4_txbw_feidang"] = "飞当",
    [":s4_txbw_feidang"] = "若对决没赢，你可以失去1点体力或弃置一张武器牌。若如此做，该对决无效，你对对方造成1点对决伤害。"

}

s4_txbw_zhangliao = sgs.General(extension, "s4_txbw_zhangliao", "wei", 4, true)

s4_txbw_tuxiClear = sgs.CreateTriggerSkill {
    name = "#s4_txbw_tuxiClear",
    events = { sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            if data:toPhaseChange().to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAllPlayers()) do
                    if player:getMark("s4_txbw_tuxi" .. p:objectName()) > 0 then
                        room:removeFixedDistance(player, p, 1)
                        room:setPlayerMark(player, "s4_txbw_tuxi" .. p:objectName(), 0)
                        room:setPlayerMark(p, "&s4_txbw_tuxi+to+#" .. player:objectName(), 0)
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
s4_txbw_tuxi = sgs.CreateTriggerSkill {
    name = "s4_txbw_tuxi",
    events = { sgs.DrawNCards },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DrawNCards then
            local draw = data:toDraw()
            if draw.reason ~= "draw_phase" then return false end
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if not p:isKongcheng() then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "s4_txbw_tuxi-invoke", true,
                    true)
                if target then
                    local card_id = room:askForCardChosen(player, target, "h", "s4_txbw_tuxi")
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, self:objectName())
                    room:moveCardTo(sgs.Sanguosha:getCard(card_id), player, sgs.Player_PlaceHand, reason)
                    draw.num = draw.num - 1
                    data:setValue(draw)
                    room:setFixedDistance(player, target, 1);
                    room:setPlayerMark(player, self:objectName() .. target:objectName(), 1)
                    room:addPlayerMark(target, "&" .. self:objectName() .. "+to+#" .. player:objectName())
                end
            end
        end
    end
}
s4_txbw_husha = sgs.CreateTriggerSkill {
    name = "s4_txbw_husha",
    events = { sgs.PreCardUsed, sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_start") then
                    room:addPlayerMark(player, "s4_txbw_general_duel_slash-Clear")
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Play and not player:isSkipped(sgs.Player_Play) then
                room:setPlayerFlag(player, "s4_txbw_general_duel")
            end
        end
    end
}

s4_txbw_zhangliao:addSkill("s4_txbw_general_gain")
s4_txbw_zhangliao:addSkill(s4_txbw_tuxi)
s4_txbw_zhangliao:addSkill(s4_txbw_husha)
sgs.LoadTranslationTable {
    ["s4_txbw_zhangliao"] = "张辽",
    ["&s4_txbw_zhangliao"] = "张辽",
    ["#s4_txbw_zhangliao"] = "雷奔云谲",
    ["~s4_txbw_zhangliao"] = "",
    ["designer:s4_txbw_zhangliao"] = "",
    ["cv:s4_txbw_zhangliao"] = "",
    ["illustrator:s4_txbw_zhangliao"] = "",

    ["s4_txbw_tuxi"] = "突袭",
    [":s4_txbw_tuxi"] = "摸牌阶段，你可以少摸一张牌并获得一名其他角色一张手牌。若如此做，本回合你计算与其的距离视为1。",
    ["s4_txbw_tuxi-invoke"] = "你可以发动“突袭”，获得一名其他角色一张手牌",
    ["s4_txbw_husha"] = "虎杀",
    [":s4_txbw_husha"] = "锁定技，你发起的对决不计入【杀】的使用次数，你使用【杀】不受对决发起的限制。"

}

s4_txbw_pangde = sgs.General(extension, "s4_txbw_pangde", "wei", 4, true)

s4_txbw_juesi = sgs.CreateTriggerSkill {
    name = "s4_txbw_juesi",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_result") then
                    local winner = room:getTag("s4_txbw_general_duel_winner"):toPlayer()
                    local loser = room:getTag("s4_txbw_general_duel_loser"):toPlayer()
                    if winner and loser and winner:isAlive() and loser:isAlive() and loser:objectName() ==
                        player:objectName() and player:hasSkill(self:objectName()) then
                        local card_s = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_s"):toInt())
                        local card_v = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_v"):toInt())
                        local card
                        if player:hasFlag("s4_txbw_general_duel_victim") then
                            card = card_v
                        elseif player:hasFlag("s4_txbw_general_duel_start") then
                            card = card_s
                        end
                        if card then
                            room:obtainCard(player, card)
                            if player:hasFlag("s4_txbw_general_duel_start") and
                                player:usedTimes("#s4_txbw_general_duel") == 0 then
                                room:addPlayerMark(player, "s4_txbw_general_duel_extra-Clear")
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
s4_txbw_pangde:addSkill("s4_txbw_general_gain")
s4_txbw_pangde:addSkill(s4_txbw_juesi)
s4_txbw_pangde:addSkill("mashu")
sgs.LoadTranslationTable {
    ["s4_txbw_pangde"] = "庞德",
    ["&s4_txbw_pangde"] = "庞德",
    ["#s4_txbw_pangde"] = "戎昭果毅",
    ["~s4_txbw_pangde"] = "",
    ["designer:s4_txbw_pangde"] = "",
    ["cv:s4_txbw_pangde"] = "",
    ["illustrator:s4_txbw_pangde"] = "",

    ["s4_txbw_juesi"] = "决死",
    [":s4_txbw_juesi"] = "锁定技，若对决没赢，你获得你的对决牌，若之为你出牌阶段发起的第一次对决，本回合你发起对决的次数限制+1。"

}

s4_txbw_dengai = sgs.General(extension, "s4_txbw_dengai", "wei", 4, true)
s4_txbw_motian = sgs.CreateTriggerSkill {
    name = "s4_txbw_motian",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_cal") then
                    local card_s = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_s"):toInt())
                    local card_v = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_v"):toInt())
                    local card
                    if player and player:hasSkill(self:objectName()) then
                        if player:hasFlag("s4_txbw_general_duel_victim") then
                            card = card_v
                        elseif player:hasFlag("s4_txbw_general_duel_start") then
                            card = card_s
                        end
                        if card then
                            local n = room:getTag("TurnLengthCount"):toInt();
                            room:addPlayerMark(player, "s4_txbw_general_duel", n)
                            local msg = sgs.LogMessage()
                            msg.type = "#s4_txbw_general_duel_cal_point_add"
                            msg.from = player
                            msg.arg = self:objectName()
                            msg.arg2 = player:getMark("s4_txbw_general_duel")
                            room:sendLog(msg)
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
s4_txbw_zhenyueCard = sgs.CreateSkillCard {
    name = "s4_txbw_zhenyue",
    will_throw = true,
    target_fixed = true,
    on_use = function(self, room, source, targets)
        source:drawCards(source:getMark("&s4_txbw_zhenyue"))
        room:addPlayerMark(source, "&s4_txbw_zhenyue")
    end
}
s4_txbw_zhenyueVS = sgs.CreateOneCardViewAsSkill {
    name = "s4_txbw_zhenyue",
    -- response_or_use = true,
    view_filter = function(self, card)
        local x = sgs.Self:getMark("&s4_txbw_zhenyue")
        return card:getNumber() == x
    end,
    view_as = function(self, card)
        local cards = s4_txbw_zhenyueCard:clone()
        cards:addSubcard(card)
        return cards
    end,
    enabled_at_play = function(self, player)
        local n = 0
        local players = player:getAliveSiblings()
        players:append(player)
        for _, p in sgs.qlist(players) do
            if p:getMark("Global_TurnCount") > 0 then
                n = p:getMark("Global_TurnCount")
                break
            end
        end
        return player:canDiscard(player, "he") and player:getMark("&s4_txbw_zhenyue") <= n + 1
    end
}
s4_txbw_zhenyue = sgs.CreateTriggerSkill {
    name = "s4_txbw_zhenyue",
    view_as_skill = s4_txbw_zhenyueVS,
    events = { sgs.GameStart },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart then
            room:addPlayerMark(player, "&s4_txbw_zhenyue")
        end
    end
}
s4_txbw_dengai:addSkill("s4_txbw_general_gain")
s4_txbw_dengai:addSkill(s4_txbw_motian)
s4_txbw_dengai:addSkill(s4_txbw_zhenyue)
sgs.LoadTranslationTable {
    ["s4_txbw_dengai"] = "邓艾",
    ["&s4_txbw_dengai"] = "邓艾",
    ["#s4_txbw_dengai"] = "彼岸无明",
    ["~s4_txbw_dengai"] = "",
    ["designer:s4_txbw_dengai"] = "",
    ["cv:s4_txbw_dengai"] = "",
    ["illustrator:s4_txbw_dengai"] = "",

    ["s4_txbw_motian"] = "摩天",
    [":s4_txbw_motian"] = "锁定技，对决点数+X（X为轮次数）。",
    ["s4_txbw_zhenyue"] = "震岳",
    [":s4_txbw_zhenyue"] = "出牌阶段，若括号中的数字不大于轮次数，你可以弃置一张点数为（1）的牌，然后摸（1）张牌，并令括号中的数字+1。"

}

s4_txbw_caocao = sgs.General(extension, "s4_txbw_caocao$", "wei", 4, true)

s4_txbw_huibianCard = sgs.CreateSkillCard {
    name = "s4_txbw_huibian",
    filter = function(self, targets, to_select)
        if #targets == 0 then
            return to_select:getHp() > 1
        elseif #targets == 1 then
            return to_select:isWounded() and to_select:objectName() ~= #targets[1]:objectName()
        end
        return #targets < 2
    end,
    feasible = function(self, targets)
        return #targets == 2
    end,
    on_use = function(self, room, source, targets)
        local first = targets[1]
        local second = targets[2]
        local damage = sgs.DamageStruct()
        damage.from = source
        damage.to = first
        room:damage(damage)
        first:drawCards(2)
        local recover = sgs.RecoverStruct()
        recover.who = source
        recover.recover = 1
        room:recover(second, recover, true)
    end
}
s4_txbw_huibian = sgs.CreateZeroCardViewAsSkill {
    name = "s4_txbw_huibian",
    view_as = function(self, card)
        local s4_txbw_huibian_card = s4_txbw_huibianCard:clone()
        return s4_txbw_huibian_card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#s4_txbw_huibian") and player:getAliveSiblings():length() > 0
    end
}
s4_txbw_hujia = sgs.CreateTriggerSkill {
    name = "s4_txbw_hujia$",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.PreCardUsed },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel") then
                    for _, to in sgs.qlist(use.to) do
                        if to:hasLordSkill(self:objectName()) then
                            local plist = room:getLieges("wei", to)
                            for _, p in sgs.list(plist) do
                                if room:askForSkillInvoke(p, self:objectName(), ToQVData(to)) then
                                    use.to:removeOne(to)
                                    use.to:append(p)
                                    data:setValue(use)
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
    end
}

s4_txbw_caocao:addSkill(s4_txbw_huibian)
s4_txbw_caocao:addSkill(s4_txbw_hujia)
s4_txbw_caocao:addSkill("hujia")


sgs.LoadTranslationTable {
    ["s4_txbw_caocao"] = "曹操",
    ["&s4_txbw_caocao"] = "曹操",
    ["#s4_txbw_caocao"] = "挟天负绝",
    ["~s4_txbw_caocao"] = "",
    ["designer:s4_txbw_caocao"] = "",
    ["cv:s4_txbw_caocao"] = "",
    ["illustrator:s4_txbw_caocao"] = "",

    ["s4_txbw_huibian"] = "挥鞭",
    [":s4_txbw_huibian"] = "出牌阶段限一次，你可以选择一名体力值大于1的角色和另一名已受伤的角色，你对前者造成1点伤害并令其摸两张牌，然后令后者回复1点体力。",
    ["s4_txbw_hujia"] = "护驾",
    [":s4_txbw_hujia"] = "主公技，魏势力角色可以替你出【闪】；魏武将可以替你成为对决目标。"

}

s4_txbw_yujin = sgs.General(extension, "s4_txbw_yujin", "wei", 4, true)

s4_txbw_yizhong = sgs.CreateTriggerSkill {
    name = "s4_txbw_yizhong",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.CardEffected },
    on_trigger = function(self, event, player, data)
        local effect = data:toCardEffect()
        if effect.card and effect.card:isKindOf("Slash") and effect.card:isBlack() then
            player:getRoom():notifySkillInvoked(player, self:objectName())
            return true
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil and target:isAlive() and target:hasSkill(self:objectName()) and (target:getArmor() == nil)
    end
}
s4_txbw_yizhong_duel = sgs.CreateTriggerSkill {
    name = "#s4_txbw_yizhong",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_cal") then
                    local card_s = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_s"):toInt())
                    local card_v = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_v"):toInt())
                    local card
                    if player:hasFlag("s4_txbw_general_duel_victim") then
                        card = card_s
                    elseif player:hasFlag("s4_txbw_general_duel_start") then
                        card = card_v
                    end
                    if card and card:isBlack() then
                        local msg = sgs.LogMessage()
                        msg.type = "#s4_txbw_general_duel_cal_point_add"
                        msg.from = player
                        msg.arg = self:objectName()
                        msg.arg2 = player:getMark("s4_txbw_general_duel")
                        room:addPlayerMark(player, "s4_txbw_general_duel", player:getHp())
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
s4_txbw_niansheng = sgs.CreateTriggerSkill {
    name = "s4_txbw_niansheng",
    events = { sgs.EnterDying },
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data, room)
        local target = room:getCurrentDyingPlayer()
        if not target then
            return false
        end
        for _, yujin in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            if yujin:getMark("@s4_txbw_general") > 0 then
                if room:askForSkillInvoke(yujin, self:objectName(), ToQVData(target)) then
                    yujin:peiyin(self)
                    room:setPlayerMark(yujin, "@s4_txbw_general", 0)
                    room:addPlayerMark(target, "&s4_txbw_niansheng+to+#" .. yujin:objectName())
                    local recover = sgs.RecoverStruct()
                    recover.who = yujin
                    recover.recover = 1 - target:getHp()
                    room:recover(target, recover)
                end
            end
        end

        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}
s4_txbw_nianshengClear = sgs.CreateTriggerSkill {
    name = "#s4_txbw_nianshengClear",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.DamageInflicted, sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if damage.to and damage.to:isAlive() then
                for _, p in sgs.list(room:getAlivePlayers()) do
                    if damage.to:getMark("&s4_txbw_niansheng+to+#" .. p:objectName()) > 0 then
                        room:sendCompulsoryTriggerLog(p, "s4_txbw_niansheng")
                        local log = sgs.LogMessage()
                        log.type = "$DamageRevises2"
                        log.from = p
                        log.arg = damage.damage
                        log.arg3 = "normal_nature"
                        if damage.nature == sgs.DamageStruct_Fire then
                            log.arg3 = "fire_nature"
                        elseif damage.nature == sgs.DamageStruct_Thunder then
                            log.arg3 = "thunder_nature"
                        elseif damage.nature == sgs.DamageStruct_Ice then
                            log.arg3 = "ice_nature"
                        end
                        room:sendLog(log)
                        return true
                    end
                end
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start then
                for _, p in sgs.list(room:getAlivePlayers()) do
                    if player:getMark("&s4_txbw_niansheng+to+#" .. p:objectName()) > 0 then
                        room:setPlayerMark(player, "&s4_txbw_niansheng+to+#" .. p:objectName(), 0)
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


s4_txbw_yujin:addSkill("s4_txbw_general_gain")
s4_txbw_yujin:addSkill(s4_txbw_yizhong)
s4_txbw_yujin:addSkill(s4_txbw_yizhong_duel)
extension:insertRelatedSkills("s4_txbw_yizhong", "#s4_txbw_yizhong_duel")
s4_txbw_yujin:addSkill(s4_txbw_niansheng)
s4_txbw_yujin:addSkill(s4_txbw_nianshengClear)
extension:insertRelatedSkills("s4_txbw_niansheng", "#s4_txbw_nianshengClear")
sgs.LoadTranslationTable {
    ["s4_txbw_yujin"] = "于禁",
    ["&s4_txbw_yujin"] = "于禁",
    ["#s4_txbw_yujin"] = "难终良将",
    ["~s4_txbw_yujin"] = "",
    ["designer:s4_txbw_yujin"] = "",
    ["cv:s4_txbw_yujin"] = "",
    ["illustrator:s4_txbw_yujin"] = "",

    ["s4_txbw_yizhong"] = "毅重",
    [":s4_txbw_yizhong"] = "锁定技，黑色【杀】对你无效。若对方对决牌为黑色，对决点数+X（X为你的体力值）。",
    ["s4_txbw_niansheng"] = "念生",
    [":s4_txbw_niansheng"] = "当一名角色进入濒死状态时，你可以移除武将标签并令其体力值回复至1，然后防止其受到的所有伤害直到其下回合开始。"

}

s4_txbw_simayi = sgs.General(extension, "s4_txbw_simayi", "wei", 3, true)

s4_txbw_jingzhe = sgs.CreateTriggerSkill {
    name = "s4_txbw_jingzhe",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.DamageInflicted, sgs.GameStart, sgs.TurnStart },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if damage.to and damage.to:isAlive() and damage.to:hasSkill(self:objectName()) then
                local n = 15
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    n = math.min(p:getSeat(), n)
                end
                if player:getSeat() == n then
                    local x = getRoundCount(room)
                    if x < 5 then
                        for _, simayi in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                            if simayi:objectName() == damage.to:objectName() then
                                local ids = room:showDrawPile(simayi, 1, self:objectName())
                                local card_to_throw = sgs.IntList()
                                card_to_throw:append(ids:first())

                                if (not card_to_throw:isEmpty()) then
                                    local dc = dummyCard()
                                    dc:addSubcard(sgs.Sanguosha:getCard(card_to_throw:first()))
                                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER,
                                        simayi:objectName(), "s4_txbw_jingzhe", nil)
                                    room:throwCard(dc, reason, nil)
                                end
                                if sgs.Sanguosha:getCard(ids:first()):isBlack() then
                                    damage.damage = damage.damage - 1
                                    damage.prevented = damage.damage < 1
                                    data:setValue(damage)
                                    if damage.damage < 1 then
                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        elseif event == sgs.TurnStart then
            local x = getRoundCount(room)
            if x > 5 then
                for _, simayi in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    room:handleAcquireDetachSkills(simayi, "s4_txbw_lianpo")
                end
            end
        elseif event == sgs.GameStart then
            local n = 15
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                n = math.min(p:getSeat(), n)
            end
            if player:getSeat() == n and not room:getTag("ExtraTurn"):toBool() then
                for _, simayi in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    room:addPlayerMark(player, "Global_TurnCount")
                    if (room:getTag("TurnLengthCount") ~= nil) then
                        room:setTag("TurnLengthCount", ToQVData(room:getTag("TurnLengthCount"):toInt() + 1));
                    else
                        room:setTag("TurnLengthCount", 1)
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
s4_txbw_taohui = sgs.CreateTriggerSkill {
    name = "s4_txbw_taohui",
    events = { sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        if change.to ~= sgs.Player_Play then
            return false
        end
        if player:isSkipped(sgs.Player_Play) then
            return false
        end
        if player:isSkipped(sgs.Player_Discard) then
            return false
        end
        local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(),
            "s4_txbw_taohui-invoke", true, true)
        if not target then
            return false
        end
        player:skip(sgs.Player_Play)
        player:skip(sgs.Player_Discard)
        room:setTag("s4_txbw_taohui", ToQVData(target))
        return false
    end
}
s4_txbw_taohuiGive = sgs.CreateTriggerSkill {
    name = "#s4_txbw_taohuiGive",
    events = { sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("s4_txbw_taohui") then
            local target = room:getTag("s4_txbw_taohui"):toPlayer()
            room:removeTag("s4_txbw_taohui")
            if target and target:isAlive() then
                local phslist = sgs.PhaseList()
                phslist:append(sgs.Player_Play)
                target:play(phslist)
                --target:play(sgs.Player_Play)
                local phslist2 = sgs.PhaseList()
                phslist2:append(sgs.Player_Discard)
                target:play(phslist2)
                --target:play(sgs.Player_Discard)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and (target:getPhase() == sgs.Player_NotActive)
    end,
    priority = 1
}

s4_txbw_lianpo = sgs.CreateTriggerSkill {
    name = "s4_txbw_lianpo",
    events = { sgs.EventPhaseChanging, sgs.EventAcquireSkill, sgs.GameStart },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart or (event == sgs.EventAcquireSkill and data:toString() == "s4_txbw_lianpo") then
            room:setPlayerMark(player, "&s4_txbw_lianpo", 1)
        else
            local change = data:toPhaseChange()
            if change.to ~= sgs.Player_NotActive then
                return false
            end
            local x = getRoundCount(room)
            if player:getMark("&s4_txbw_lianpo") <= x then
                local card = room:askForCard(player, ".|.|" .. player:getMark("&s4_txbw_lianpo"),
                    "@s4_txbw_lianpo:" .. player:getMark("&s4_txbw_lianpo"), data, sgs.Card_MethodDiscard)
                if card then
                    room:setTag("s4_txbw_lianpo", ToQVData(player))
                    room:addPlayerMark(player, "&s4_txbw_lianpo")
                end
            end
        end

        return false
    end
}
s4_txbw_lianpoGive = sgs.CreateTriggerSkill {
    name = "#s4_txbw_lianpoGive",
    events = { sgs.EventPhaseStart },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("s4_txbw_lianpo") then
            local target = room:getTag("s4_txbw_lianpo"):toPlayer()
            room:removeTag("s4_txbw_lianpo")
            if target and target:isAlive() then
                target:gainAnExtraTurn()
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and (target:getPhase() == sgs.Player_NotActive)
    end,
    priority = 1
}

s4_txbw_simayi:addSkill(s4_txbw_jingzhe)
s4_txbw_simayi:addSkill(s4_txbw_taohui)
s4_txbw_simayi:addSkill(s4_txbw_taohuiGive)
extension:insertRelatedSkills("s4_txbw_taohui", "#s4_txbw_taohuiGive")
if not sgs.Sanguosha:getSkill("s4_txbw_lianpo") then
    s4_skillList:append(s4_txbw_lianpo)
end
if not sgs.Sanguosha:getSkill("#s4_txbw_lianpoGive") then
    s4_skillList:append(s4_txbw_lianpoGive)
end
extension:insertRelatedSkills("s4_txbw_lianpo", "#s4_txbw_lianpoGive")
s4_txbw_simayi:addRelateSkill("s4_txbw_lianpo")


sgs.LoadTranslationTable {
    ["s4_txbw_simayi"] = "司马懿",
    ["&s4_txbw_simayi"] = "司马懿",
    ["#s4_txbw_simayi"] = "时雨上方谷",
    ["~s4_txbw_simayi"] = "",
    ["designer:s4_txbw_simayi"] = "",
    ["cv:s4_txbw_simayi"] = "",
    ["illustrator:s4_txbw_simayi"] = "",

    ["s4_txbw_jingzhe"] = "惊蛰",
    [":s4_txbw_jingzhe"] = "锁定技，本局游戏轮次数+1。轮次数不大于5时，你受到伤害时从牌堆里亮出一张牌，若为黑色，此伤害-1；轮次数大于5时，你获得“连破”。",
    ["s4_txbw_taohui"] = "韬晦",
    [":s4_txbw_taohui"] = "你可以跳过出牌阶段和弃牌阶段，令一名其他角色依次执行一个出牌阶段和弃牌阶段。",
    ["s4_txbw_lianpo"] = "连破",
    [":s4_txbw_lianpo"] = "回合结束时，若括号中的数字不大于轮次数，你可以弃置一张点数为（1）的牌，然后开始一个新的回合，并令括号中的数字+1。"

}

s4_txbw_xuhuang = sgs.General(extension, "s4_txbw_xuhuang", "wei", 4, true)

s4_txbw_wanpo = sgs.CreateTriggerSkill {
    name = "s4_txbw_wanpo",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished, sgs.DamageCaused },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_cal") then
                    local target = player:getTag("s4_txbw_general_duel"):toPlayer()

                    if target and not target:isWounded() then
                        local x = 0
                        for _, p in sgs.qlist(room:getAlivePlayers()) do
                            if target:inMyAttackRange(p) then
                                x = x + 1
                            end
                        end

                        room:addPlayerMark(player, "s4_txbw_general_duel", x)
                        local msg = sgs.LogMessage()
                        msg.type = "#s4_txbw_general_duel_cal_point_add"
                        msg.from = player
                        msg.arg = self:objectName()
                        msg.arg2 = player:getMark("s4_txbw_general_duel")
                        room:sendLog(msg)
                    end
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.chain or damage.transfer or (not damage.by_user) then
                return false
            end
            local reason = damage.reason
            if reason and reason == "s4_txbw_general_duel"
                and damage.from and RIGHT(self, player) and damage.from:objectName() == player:objectName()
                and damage.to and not damage.to:isWounded() then
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
    can_trigger = function(self, target)
        return target
    end
}

s4_txbw_yanglei = sgs.CreateTriggerSkill {
    name = "s4_txbw_yanglei",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.Damage },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.to and damage.from and damage.from:isAlive() then
                for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                    if p:distanceTo(damage.from) <= 1 then
                        local choicelist = "cancel"
                        choicelist = string.format("%s+%s", choicelist,
                            "s4_txbw_yanglei_recover=" .. damage.from:objectName())
                        choicelist = string.format("%s+%s", choicelist,
                            "s4_txbw_yanglei_draw=" .. damage.from:objectName())
                        local choice = room:askForChoice(p, "s4_txbw_yanglei", choicelist, data)
                        if choice ~= "cancel" then
                            if string.startsWith(choice, "s4_txbw_yanglei_recover") then
                                local recover = sgs.RecoverStruct()
                                recover.who = p

                                room:recover(damage.from, recover)
                            elseif string.startsWith(choice, "s4_txbw_yanglei_draw") then
                                damage.from:drawCards(2)
                            end

                            local card = sgs.Sanguosha:getCard(room:getNCards(1):first())
                            local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage", card:getSuit(),
                                card:getNumber())
                            supply_shortage:addSubcard(card)
                            supply_shortage:setSkillName("s4_txbw_yanglei")
                            supply_shortage:deleteLater()
                            room:useCard(sgs.CardUseStruct(supply_shortage, p, damage.from))
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
s4_txbw_xuhuang:addSkill("s4_txbw_general_gain")
s4_txbw_xuhuang:addSkill(s4_txbw_wanpo)
s4_txbw_xuhuang:addSkill(s4_txbw_yanglei)

sgs.LoadTranslationTable {
    ["s4_txbw_xuhuang"] = "徐晃",
    ["&s4_txbw_xuhuang"] = "徐晃",
    ["#s4_txbw_xuhuang"] = "进驱襄樊",
    ["~s4_txbw_xuhuang"] = "",
    ["designer:s4_txbw_xuhuang"] = "",
    ["cv:s4_txbw_xuhuang"] = "",
    ["illustrator:s4_txbw_xuhuang"] = "",

    ["s4_txbw_wanpo"] = "完破",
    [":s4_txbw_wanpo"] = "锁定技，若对方未受伤，对决点数+X（X为其攻击范围内角色数），且你的对决伤害+1。",
    ["s4_txbw_yanglei"] = "佯垒",
    [":s4_txbw_yanglei"] = "每当你距离1以内的角色造成伤害后，你可以令其回复1点体力或摸两张牌，然后将牌堆顶的一张牌当【兵粮寸断】置于其判定区内。",
    ["s4_txbw_yanglei_recover"] = "令 %src 回复1点体力",
    ["s4_txbw_yanglei_draw"] = "令 %src 摸两张牌",

}

s4_txbw_caoren = sgs.General(extension, "s4_txbw_caoren", "wei", 4, true)

s4_txbw_jushou = sgs.CreatePhaseChangeSkill {
    name = "s4_txbw_jushou",

    on_phasechange = function(self, player)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Finish then
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(),
                "s4_txbw_jushou-invoke", true, true)
            if target then
                local x = 2
                if player:hasFlag("s4_txbw_general_duel") and player:hasFlag("s4_txbw_general_duel_lose") then
                    x = 3
                end
                target:drawCards(x)
                player:turnOver()
            end
        end
    end
}
s4_txbw_jushouClear = sgs.CreateTriggerSkill {
    name = "#s4_txbw_jushouClear",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_result") then
                    local winner = room:getTag("s4_txbw_general_duel_winner"):toPlayer()
                    local loser = room:getTag("s4_txbw_general_duel_loser"):toPlayer()
                    if ((winner and loser and winner:isAlive() and loser:isAlive() and loser:objectName() ==
                            player:objectName()) or (not winner and not loser)) and player:hasSkill("s4_txbw_jushou") then
                        room:setPlayerFlag(player, "s4_txbw_general_duel_lose")
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

s4_txbw_chiliVS = sgs.CreateViewAsSkill {
    name = "s4_txbw_chili",
    n = 0,
    view_as = function(self, cards)
        local c = sgs.Sanguosha:cloneCard("nullification")
        c:setSkillName("s4_txbw_chili")
        return c
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        if pattern ~= "nullification" then
            return
        end
        return player:getMark("@s4_txbw_general") > 0
    end,
    enabled_at_nullification = function(self, player)
        return player:getMark("@s4_txbw_general") > 0
    end
}
s4_txbw_chili = sgs.CreateTriggerSkill {
    name = "s4_txbw_chili",
    events = { sgs.TurnedOver, sgs.CardUsed },
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = s4_txbw_chiliVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TurnedOver then
            if not player:faceUp() then
                return false
            end
            if not room:askForSkillInvoke(player, self:objectName()) then
                return false
            end
            room:setPlayerMark(player, "@s4_txbw_general", 1)

            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if player:canDiscard(p, "je") then
                    targets:append(p)
                end
            end

            if targets:isEmpty() then
                return false
            end
            local to_discard = room:askForPlayerChosen(player, targets, self:objectName(), "@s4_txbw_chili-discard",
                true)
            if to_discard then
                local id = room:askForCardChosen(player, to_discard, "ej", self:objectName(), false,
                    sgs.Card_MethodDiscard)
                room:throwCard(id, to_discard, player)
            end
        elseif (event == sgs.CardUsed) then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Nullification") and use.card:getSkillName() == self:objectName() then
                room:setPlayerMark(player, "@s4_txbw_general", 0)
                local list = use.no_offset_list
                table.insert(list, "_ALL_TARGETS")
                use.no_offset_list = list
                data:setValue(use)
            end
        end

        return false
    end
}

s4_txbw_caoren:addSkill("s4_txbw_general_gain")
s4_txbw_caoren:addSkill(s4_txbw_jushou)
s4_txbw_caoren:addSkill(s4_txbw_jushouClear)
extension:insertRelatedSkills("s4_txbw_jushou", "#s4_txbw_jushouClear")
s4_txbw_caoren:addSkill(s4_txbw_chili)

sgs.LoadTranslationTable {
    ["s4_txbw_caoren"] = "曹仁",
    ["&s4_txbw_caoren"] = "曹仁",
    ["#s4_txbw_caoren"] = "天将临城",
    ["~s4_txbw_caoren"] = "",
    ["designer:s4_txbw_caoren"] = "",
    ["cv:s4_txbw_caoren"] = "",
    ["illustrator:s4_txbw_caoren"] = "",

    ["s4_txbw_jushou"] = "据守",
    [":s4_txbw_jushou"] = "结束阶段，你可以翻面并令一名角色摸两张牌，若你该回合发起的对决没赢，改为摸三张牌。",
    ["s4_txbw_chili"] = "饬厉",
    [":s4_txbw_chili"] = "你可以扣置武将标签并视为使用一张无法被抵消的【无懈可击】。当你从背面翻至正面时，你可以重置武将标签并弃置场上一张牌。"

}

s4_txbw_zhanghe = sgs.General(extension, "s4_txbw_zhanghe", "wei", 4, true)

s4_txbw_yishi = sgs.CreateTriggerSkill {
    name = "s4_txbw_yishi",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") and RIGHT(self, player) then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_choose") then
                    local card_v = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_v"):toInt())
                    local card_s = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_s"):toInt())
                    if room:askForSkillInvoke(player, self:objectName()) then
                        room:removeTag("s4_txbw_general_duel_v")
                        room:removeTag("s4_txbw_general_duel_s")
                        room:setTag("s4_txbw_general_duel_s", sgs.QVariant(card_v:getId()))
                        room:setTag("s4_txbw_general_duel_v", sgs.QVariant(card_s:getId()))
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

s4_txbw_zhanghe:addSkill("s4_txbw_general_gain")
s4_txbw_zhanghe:addSkill(s4_txbw_yishi)

sgs.LoadTranslationTable {
    ["s4_txbw_zhanghe"] = "张郃",
    ["&s4_txbw_zhanghe"] = "张郃",
    ["#s4_txbw_zhanghe"] = "弹指千钧",
    ["~s4_txbw_zhanghe"] = "",
    ["designer:s4_txbw_zhanghe"] = "",
    ["cv:s4_txbw_zhanghe"] = "",
    ["illustrator:s4_txbw_zhanghe"] = "",

    ["s4_txbw_yishi"] = "易势",
    [":s4_txbw_yishi"] = "对决牌扣置后，你可以与对方交换之。",
    ["s4_txbw_qiaobian"] = "巧变",
    [":s4_txbw_qiaobian"] = "出牌阶段限X次，你可以交换两名角色相同区域里一张牌（X为你已损失的体力值）。"

}

s4_txbw_yuejin = sgs.General(extension, "s4_txbw_yuejin", "wei", 4, true)

s4_txbw_hongwu = sgs.CreateTriggerSkill {
    name = "s4_txbw_hongwu",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_start") then
                    if use.from and use.from:isAlive() then
                        for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                            local card = room:askForCard(p, ".Basic", self:objectName(), ToQVData(use.from),
                                sgs.Card_MethodDiscard,
                                p,
                                false, "@s4_txbw_hongwu", true)
                            if card then
                                room:setPlayerMark(use.from, "&" .. self:objectName() .. "+to+#" .. p:objectName(),
                                    card:getNumber())
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
s4_txbw_hongwuClear = sgs.CreateTriggerSkill {
    name = "#s4_txbw_hongwuClear",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_cal") then
                    for _, p in sgs.qlist(room:findPlayersBySkillName("s4_txbw_hongwu")) do
                        if player:getMark("&s4_txbw_hongwu+to+#" .. p:objectName()) > 0 then
                            room:sendCompulsoryTriggerLog(p, "s4_txbw_hongwu")

                            room:addPlayerMark(player, "s4_txbw_general_duel",
                                player:getMark("&s4_txbw_hongwu+to+#" .. p:objectName()))
                            room:setPlayerMark(player, "&s4_txbw_hongwu+to+#" .. p:objectName(), 0)
                            local msg = sgs.LogMessage()
                            msg.type = "#s4_txbw_general_duel_cal_point_add"
                            msg.from = player
                            msg.arg = self:objectName()
                            msg.arg2 = player:getMark("s4_txbw_general_duel")
                            room:sendLog(msg)
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


s4_txbw_xiaoguo = sgs.CreatePhaseChangeSkill {
    name = "s4_txbw_xiaoguo",
    frequency = sgs.Skill_NotFrequent,
    on_phasechange = function(self, player)
        if player:getPhase() == sgs.Player_Finish then
            local room = player:getRoom()
            if room:askForSkillInvoke(player, self:objectName()) then
                room:showAllCards(player)
                local can_invoke = true
                local cards = player:getHandcards()
                for _, card in sgs.qlist(cards) do
                    if card:isKindOf("BasicCard") then
                        can_invoke = false
                        break
                    end
                end
                if can_invoke then
                    if player:getHandcardNum() < player:getMaxHp() then
                        player:drawCards(player:getMaxHp() - player:getHandcardNum())
                    end
                end
            end
        end
        return false
    end
}

s4_txbw_yuejin:addSkill("s4_txbw_general_gain")
s4_txbw_yuejin:addSkill(s4_txbw_hongwu)
s4_txbw_yuejin:addSkill(s4_txbw_hongwuClear)
extension:insertRelatedSkills("s4_txbw_hongwu", "#s4_txbw_hongwuClear")
s4_txbw_yuejin:addSkill(s4_txbw_xiaoguo)

sgs.LoadTranslationTable {
    ["s4_txbw_yuejin"] = "乐进",
    ["&s4_txbw_yuejin"] = "乐进",
    ["#s4_txbw_yuejin"] = "奋强突固",
    ["~s4_txbw_yuejin"] = "",
    ["designer:s4_txbw_yuejin"] = "",
    ["cv:s4_txbw_yuejin"] = "",
    ["illustrator:s4_txbw_yuejin"] = "",

    ["s4_txbw_hongwu"] = "弘武",
    [":s4_txbw_hongwu"] = "一名角色发起对决后，你可以弃置一张基本牌。若如此做，其本次对决点数+X（X为你弃置牌的点数）。",

    ["s4_txbw_xiaoguo"] = "骁果",
    [":s4_txbw_xiaoguo"] = "结束阶段，你可以展示所有手牌，若不含基本牌，你将手牌补至体力上限。",


}

s4_txbw_wei_guanyu = sgs.General(extension, "s4_txbw_wei_guanyu", "wei", 5, true)

s4_txbw_shenwei = sgs.CreateTriggerSkill {
    name = "s4_txbw_shenwei",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.PreCardUsed, sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") and RIGHT(self, player) then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_show") then
                    local target = player:getTag("s4_txbw_general_duel"):toPlayer()

                    local dest = sgs.QVariant()
                    dest:setValue(target)
                    local choice = room:askForChoice(player, self:objectName(), "red+black+cancel", dest)
                    if choice ~= "cancel" then
                        room:setPlayerMark(player, "&" .. self:objectName() .. "+" .. choice, 1)
                    end
                end
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_show") then
                    local card_s = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_s"):toInt())
                    local card_v = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_v"):toInt())
                    local card
                    if player and player:hasSkill(self:objectName()) then
                        if player:hasFlag("s4_txbw_general_duel_victim") then
                            card = card_v
                        elseif player:hasFlag("s4_txbw_general_duel_start") then
                            card = card_s
                        end
                        if card then
                            if (card:isRed() and player:getMark("&" .. self:objectName() .. "+red")) or
                                (card:isBlack() and player:getMark("&" .. self:objectName() .. "+black")) then
                                room:sendCompulsoryTriggerLog(player, self:objectName())
                                room:setPlayerFlag(player, "s4_txbw_general_duel_force_win")
                                room:setPlayerMark(player, "&" .. self:objectName() .. "+red", 0)
                                room:setPlayerMark(player, "&" .. self:objectName() .. "+black", 0)
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

s4_txbw_tianjian = sgs.CreateTriggerSkill {
    name = "s4_txbw_tianjian",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_result") then
                    if not player:hasFlag("s4_txbw_general_duel_not_win") and player:hasSkill(self:objectName()) then
                        room:sendCompulsoryTriggerLog(player, self:objectName())
                        local target = player:getTag("s4_txbw_general_duel"):toPlayer()

                        if target and target:isAlive() then
                            local result = room:askForChoice(target, self:objectName(), "hp+maxhp")
                            if result == "hp" then
                                room:loseHp(target, 1, true, player, self:objectName())
                            else
                                room:loseMaxHp(target)
                            end
                            room:removeTag("s4_txbw_general_duel_wincard")
                            room:removeTag("s4_txbw_general_duel_winner")
                            room:removeTag("s4_txbw_general_duel_loser")
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

s4_txbw_wei_guanyu:addSkill("s4_txbw_general_gain")
s4_txbw_wei_guanyu:addSkill(s4_txbw_shenwei)
s4_txbw_wei_guanyu:addSkill(s4_txbw_tianjian)
sgs.LoadTranslationTable {
    ["s4_txbw_wei_guanyu"] = "关羽",
    ["&s4_txbw_wei_guanyu"] = "关羽",
    ["#s4_txbw_wei_guanyu"] = "义薄云天",
    ["~s4_txbw_wei_guanyu"] = "",
    ["designer:s4_txbw_wei_guanyu"] = "",
    ["cv:s4_txbw_wei_guanyu"] = "",
    ["illustrator:s4_txbw_wei_guanyu"] = "",

    ["s4_txbw_shenwei"] = "神威",
    [":s4_txbw_shenwei"] = "对决牌亮出前，你可以声明一种颜色。对方的对决牌亮出后，若颜色与之相同，视为你已在对决中获胜。",

    ["s4_txbw_tianjian"] = "天鉴",
    [":s4_txbw_tianjian"] = "锁定技，对决获胜时，改为令对方选择一项：失去1点体力；减1点体力上限。",


}


s4_txbw_guohuai = sgs.General(extension, "s4_txbw_guohuai", "wei", 4, true)


s4_txbw_zhisun = sgs.CreateTriggerSkill {
    name = "s4_txbw_zhisun",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_show") then
                    local card_s = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_s"):toInt())
                    local card_v = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_v"):toInt())
                    local card
                    if player and player:hasSkill(self:objectName()) then
                        if player:hasFlag("s4_txbw_general_duel_victim") then
                            card = card_v
                        elseif player:hasFlag("s4_txbw_general_duel_start") then
                            card = card_s
                        end
                        if card then
                            if not player:isNude() then
                                local new_card = room:askForCard(player, ".|.|.|hand", "s4_txbw_zhisun", sgs.QVariant(),
                                    sgs.Card_MethodNone,
                                    player,
                                    false, "s4_txbw_general_duel", true)
                                if new_card then
                                    if player:hasFlag("s4_txbw_general_duel_victim") then
                                        room:removeTag("s4_txbw_general_duel_v")
                                        room:setTag("s4_txbw_general_duel_v", sgs.QVariant(new_card:getId()))
                                    elseif player:hasFlag("s4_txbw_general_duel_start") then
                                        room:removeTag("s4_txbw_general_duel_s")
                                        room:setTag("s4_txbw_general_duel_s", sgs.QVariant(new_card:getId()))
                                    end
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
    end
}


s4_txbw_guohuai:addSkill("s4_txbw_general_gain")
s4_txbw_guohuai:addSkill(s4_txbw_zhisun)
s4_txbw_guohuai:addSkill("jingce")


sgs.LoadTranslationTable {
    ["s4_txbw_guohuai"] = "郭淮",
    ["&s4_txbw_guohuai"] = "郭淮",
    ["#s4_txbw_guohuai"] = "垂问秦雍",
    ["~s4_txbw_guohuai"] = "",
    ["designer:s4_txbw_guohuai"] = "",
    ["cv:s4_txbw_guohuai"] = "",
    ["illustrator:s4_txbw_guohuai"] = "",

    ["s4_txbw_zhisun"] = "止损",
    [":s4_txbw_zhisun"] = "对决牌亮出后，你可以打出一张牌替换之。",


}


s4_txbw_zhangfei = sgs.General(extension, "s4_txbw_zhangfei", "shu", 4, true)

s4_txbw_paoxiao = sgs.CreateTriggerSkill {
    name = "s4_txbw_paoxiao",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.CardsMoveOneTime },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if (move.from and (move.from:objectName() == player:objectName()) and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))) and not (move.to and (move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip))) then
                room:addPlayerMark(player, "s4_txbw_paoxiao-Clear", move.card_ids:length())
                if player:getMark("s4_txbw_paoxiao-Clear") >= player:getHp() then
                    room:setPlayerMark(player, "&s4_txbw_paoxiao-Clear", 1)
                    room:addPlayerMark(player, "s4_txbw_general_duel_extra-Clear")
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
            and target:hasSkill(self:objectName())
            and target:getPhase() == sgs.Player_Play
            and target:getMark("&s4_txbw_paoxiao-Clear") == 0
    end
}


s4_txbw_duanhe = sgs.CreateTriggerSkill {
    name = "s4_txbw_duanhe",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.CardFinished, sgs.EventLoseSkill, sgs.CardsMoveOneTime },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_show") then
                    local card_s = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_s"):toInt())
                    local card_v = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_v"):toInt())
                    local card
                    if player and player:hasSkill(self:objectName()) then
                        if player:hasFlag("s4_txbw_general_duel_victim") then
                            card = card_v
                        elseif player:hasFlag("s4_txbw_general_duel_start") then
                            card = card_s
                        end
                        if card then
                            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                                room:setPlayerCardLimitation(p, "use,response", ".|" .. card:getSuitString() .. "|.|.|",
                                    true)
                            end
                            room:setPlayerMark(player, "&" .. self:objectName() .. "+" .. card:getSuitString() ..
                                "+-Clear", 1)
                        end
                    end
                end
            end
        elseif event == sgs.EventLoseSkill
        then
            if data:toString() == "s4_txbw_duanhe"
            then
                for _, mark in sgs.list(player:getMarkNames()) do
                    if string.find(mark, "s4_txbw_duanhe") and player:getMark(mark) > 0 then
                        local suit = mark:split("+")[2]
                        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                            local hw = sgs.CardList()
                            for _, c in sgs.list(player:getHandcards()) do
                                if c:getSuitString() == suit or table.contains(c:getSkillNames(), "s4_txbw_duanhe")
                                then
                                    hw:append(c)
                                end
                            end
                            if hw:length() > 0
                            then
                                room:filterCards(p, hw, true)
                                room:removePlayerCardLimitation(p, "use,response", ".|" .. suit .. "|.|.|")
                            end
                        end
                    end
                end
            end
        else
            for _, mark in sgs.list(player:getMarkNames()) do
                if string.find(mark, "s4_txbw_duanhe") and player:getMark(mark) > 0 then
                    local suit = mark:split("+")[2]
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        local hw = sgs.CardList()
                        for _, c in sgs.list(player:getHandcards()) do
                            if c:getSuitString() == suit or table.contains(c:getSkillNames(), "s4_txbw_duanhe")
                            then
                                hw:append(c)
                            end
                        end
                        if hw:length() > 0
                        then
                            for _, c in sgs.list(hw) do
                                --local toc = sgs.Sanguosha:cloneCard(can, c:getSuit(), c:getNumber())
                                --toc:setSkillName("jl_sstj")
                                --local wrap = sgs.Sanguosha:getWrappedCard(c:getEffectiveId())
                                --wrap:takeOver(toc)

                                local id = c:getEffectiveId()
                                local new_card = sgs.Sanguosha:getWrappedCard(id)
                                new_card:setSkillName(self:objectName())
                                new_card:setNumber(1)
                                new_card:setModified(true)
                                room:notifyUpdateCard(player, c:getEffectiveId(), wrap)
                            end
                            --[[local toc = sgs.Sanguosha:cloneCard("slash", 2, c:getNumber())
                            toc:setSkillName("s4_txbw_duanhe")
                            local wrap = sgs.Sanguosha:getWrappedCard(c:getEffectiveId())
                            wrap:takeOver(toc)
                            room:notifyUpdateCard(player, c:getEffectiveId(), wrap)]]
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

s4_txbw_zhangfei:addSkill("s4_txbw_general_gain")
--s4_txbw_zhangfei:addSkill(s4_txbw_paoxiao)
--s4_txbw_zhangfei:addSkill(s4_txbw_duanhe)


sgs.LoadTranslationTable {
    ["s4_txbw_zhangfei"] = "张飞",
    ["&s4_txbw_zhangfei"] = "张飞",
    ["#s4_txbw_zhangfei"] = "万夫之雄",
    ["~s4_txbw_zhangfei"] = "",
    ["designer:s4_txbw_zhangfei"] = "",
    ["cv:s4_txbw_zhangfei"] = "",
    ["illustrator:s4_txbw_zhangfei"] = "",

    ["s4_txbw_paoxiao"] = "咆哮",
    [":s4_txbw_paoxiao"] = "锁定技，若你于出牌阶段失去的牌数不小于你的体力值，本回合发起对决的次数限制+1。",

    ["s4_txbw_duanhe"] = "断喝",
    [":s4_txbw_duanhe"] = "锁定技，对决牌亮出后，直到该回合结束，其他角色与之相同花色的牌点数均视为1，且无法使用或打出这些牌。",

}


s4_txbw_guanyu = sgs.General(extension, "s4_txbw_guanyu", "shu", 5, true)


s4_txbw_wusheng = sgs.CreateTriggerSkill {
    name = "s4_txbw_wusheng",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_cal") then
                    local card_s = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_s"):toInt())
                    local card_v = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_v"):toInt())
                    local card
                    if player:hasFlag("s4_txbw_general_duel_victim") then
                        card = card_v
                    elseif player:hasFlag("s4_txbw_general_duel_start") then
                        card = card_s
                    end
                    local target = player:getTag("s4_txbw_general_duel"):toPlayer()
                    if card and card:isRed() and target then
                        room:addPlayerMark(player, "s4_txbw_general_duel", target:getHp())
                        local msg = sgs.LogMessage()
                        msg.type = "#s4_txbw_general_duel_cal_point_add"
                        msg.from = player
                        msg.arg = self:objectName()
                        msg.arg2 = player:getMark("s4_txbw_general_duel")
                        room:sendLog(msg)
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

s4_txbw_yijue = sgs.CreateTriggerSkill {
    name = "s4_txbw_yijue",
    frequency = sgs.Skill_Compulsory,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_result") then
                    if not player:hasFlag("s4_txbw_general_duel_not_win") and player:hasSkill(self:objectName()) then
                        local target = player:getTag("s4_txbw_general_duel"):toPlayer()

                        if target and target:isAlive() then
                            if room:askForSkillInvoke(player, self:objectName()) then
                                if target:getHp() >= player:getHp() then
                                    room:setPlayerMark(target, "&" .. self:objectName() .. "+to+#" .. player:objectName(),
                                        1)
                                    room:addPlayerMark(target, "@skill_invalidity")
                                    room:setPlayerCardLimitation(target, "use,response", ".|.|.|hand", false)
                                else
                                    local recover = sgs.RecoverStruct()
                                    recover.who = player
                                    room:recover(target, recover)
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
    end
}
s4_txbw_yijueClear = sgs.CreateTriggerSkill {
    name = "#s4_txbw_yijueClear",
    frequency = sgs.Skill_Frequent,
    events = { sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("&s4_txbw_yijue+to+#" .. player:objectName()) > 0 then
                        room:setPlayerMark(p, "&s4_txbw_yijue+to+#" .. player:objectName(), 0)
                        room:setPlayerMark(p, "@skill_invalidity", 0)
                        room:removePlayerCardLimitation(p, "use,response", ".|.|.|hand")
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


s4_txbw_huwei = sgs.CreateTriggerSkill {
    name = "s4_txbw_huwei",
    frequency = sgs.Skill_Frequent,
    events = { sgs.PreCardUsed },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_finish") then
                    if not player:hasFlag("s4_txbw_general_duel_not_win") and player:hasSkill(self:objectName()) then
                        local target = player:getTag("s4_txbw_general_duel"):toPlayer()

                        if target and target:isAlive() then
                            local result = room:askForChoice(target, self:objectName(),
                                "s4_txbw_huwei_fire+s4_txbw_huwei_thunder+cancel")
                            if result ~= "cancel" then
                                --local winCard = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_wincard"):toInt())
                                room:removeTag("s4_txbw_general_duel_wincard")
                                if result == "s4_txbw_huwei_fire" then
                                    local fire_slash = sgs.Sanguosha:cloneCard("fire_slash")
                                    room:setTag("s4_txbw_general_duel_wincard", ToQVData(fire_slash:getEffectiveId()))
                                elseif result == "s4_txbw_huwei_thunder" then
                                    local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash")
                                    room:setTag("s4_txbw_general_duel_wincard", ToQVData(thunder_slash:getEffectiveId()))
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
    end
}


s4_txbw_guanyu:addSkill("s4_txbw_general_gain")
s4_txbw_guanyu:addSkill(s4_txbw_wusheng)
s4_txbw_guanyu:addSkill(s4_txbw_yijue)
s4_txbw_guanyu:addSkill(s4_txbw_yijueClear)
extension:insertRelatedSkills("s4_txbw_yijue", "#s4_txbw_yijueClear")
s4_txbw_guanyu:addSkill(s4_txbw_huwei)

sgs.LoadTranslationTable {
    ["s4_txbw_guanyu"] = "关羽",
    ["&s4_txbw_guanyu"] = "关羽",
    ["#s4_txbw_guanyu"] = "威震华夏",
    ["~s4_txbw_guanyu"] = "",
    ["designer:s4_txbw_guanyu"] = "",
    ["cv:s4_txbw_guanyu"] = "",
    ["illustrator:s4_txbw_guanyu"] = "",

    ["s4_txbw_wusheng"] = "武圣",
    [":s4_txbw_wusheng"] = "锁定技，你的对决牌若为红色，对决点数+X（X为对方体力值）。",

    ["s4_txbw_yijue"] = "义绝",
    [":s4_txbw_yijue"] = "对决获胜时，若对方体力值不小于你，你可以令其非锁定技失效且无法使用或打出牌直到当前回合结束；若对方体力值不大于你，你可以改为令其回复1点体力。",

    ["s4_txbw_huwei"] = "虎威",
    [":s4_txbw_huwei"] = "你可以令你的对决伤害为火属性或雷属性。",
    ["s4_txbw_huwei_thunder"] = "虎威:雷属性",
    ["s4_txbw_huwei_fire"] = "虎威:火属性",

}


s4_txbw_zhaoyun = sgs.General(extension, "s4_txbw_zhaoyun", "shu", 4, true)

s4_txbw_longdan = sgs.CreateTriggerSkill {
    name = "s4_txbw_longdan",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished },
    priority = -3,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_cal") then
                    local card_s = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_s"):toInt())
                    local card_v = sgs.Sanguosha:getCard(room:getTag("s4_txbw_general_duel_v"):toInt())
                    local card
                    if player:hasFlag("s4_txbw_general_duel_victim") then
                        card = card_v
                    elseif player:hasFlag("s4_txbw_general_duel_start") then
                        card = card_s
                    end
                    local target = room:getTag("s4_txbw_general_duel"):toPlayer()
                    if card and target then
                        if room:askForSkillInvoke(player, self:objectName()) then
                            --room:addPlayerMark(player, "s4_txbw_general_duel", target:getHp())
                            local start_point = player:getMark("s4_txbw_general_duel")
                            local victim_point = target:getMark("s4_txbw_general_duel")
                            room:setPlayerMark(player, "s4_txbw_general_duel", victim_point)
                            room:setPlayerMark(target, "s4_txbw_general_duel", start_point)
                            room:loseMaxHp(player, 1)
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

s4_txbw_nilinCard = sgs.CreateSkillCard {
    name = "s4_txbw_nilin",
    will_throw = false,
    filter = function(self, targets, to_select)
        return #targets < 0
    end,
    on_use = function(self, room, source, targets)
        if sgs.Sanguosha:getCurrentCardUsePattern() == "@@s4_txbw_nilin" then
            for _, id in sgs.qlist(self:getSubcards()) do
                room:setCardFlag(sgs.Sanguosha:getCard(id), "s4_txbw_nilin")
            end
        end
    end,
}
s4_txbw_nilinVS = sgs.CreateViewAsSkill {
    name = "s4_txbw_nilin",
    n = 999,
    view_filter = function(self, selected, to_select, player)
        if sgs.Sanguosha:getCurrentCardUsePattern() == "@@s4_txbw_nilin" then
            local x = player:getMark("s4_txbw_nilin_dis")
            local suits = {}

            for _, c in sgs.list(selected) do
                if not table.contains(suits, c:getSuitString()) then
                    table.insert(suits, c:getSuitString())
                end
            end
            if #suits == x then
                for _, c in sgs.list(selected) do
                    if c:getSuit() ~= to_select:getSuit() then return false end
                end
            end
            return not to_select:isEquipped() and not sgs.Self:isJilei(to_select)
        end
        return true
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUsePattern() == "@@s4_txbw_nilin" then
            if #cards > 0 then
                local skillcard = s4_txbw_nilinCard:clone()
                local suits = {}
                for _, c in ipairs(cards) do
                    if not table.contains(suits, c:getSuitString()) then
                        table.insert(suits, c:getSuitString())
                    end
                end
                for _, c in ipairs(cards) do
                    skillcard:addSubcard(c)
                end
                if #suits == sgs.Self:getMark("s4_txbw_nilin_dis") then
                    return skillcard
                end
            end
        end
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@@s4_txbw_nilin"
    end,
}
s4_txbw_nilin = sgs.CreateTriggerSkill {
    name = "s4_txbw_nilin",
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = s4_txbw_nilinVS,
    events = { sgs.TargetSpecified, sgs.EventPhaseChanging },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card and not use.card:isKindOf("SkillCard") and use.from:objectName() == player:objectName() and player:hasSkill(self:objectName()) then
                if use.from:getMark("used-Clear") == player:getMaxHp() then
                    if not use.from:isAllNude() then
                        if room:askForSkillInvoke(player, self:objectName()) then
                            local card_id = room:askForCardChosen(player, use.from, "hej", self:objectName())
                            if card_id then
                                if room:getCardPlace(id) == sgs.Player_PlaceHand then
                                    room:obtainCard(player, card_id)
                                else
                                    room:throwCard(card_id, use.from, player)
                                end
                            end
                        end
                    end
                end
            end
        elseif event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Discard then
                if not player:isSkipped(sgs.Player_Discard) then
                    if room:askForSkillInvoke(player, self:objectName()) then
                        player:skip(sgs.Player_Discard)
                        room:showAllCards(player)
                        local suits = {}
                        for _, id in sgs.qlist(player:handCards()) do
                            local card = sgs.Sanguosha:getCard(id)
                            if not table.contains(suits, card:getSuitString()) then
                                table.insert(suits, card:getSuitString())
                            end
                        end
                        if #suits > player:getHp() then
                            room:setPlayerMark(player, "s4_txbw_nilin_dis", #suits - player:getHp())
                            local invoke = room:askForUseCard(player, "@@s4_txbw_nilin", "@s4_txbw_nilin")
                            room:setPlayerMark(player, "s4_txbw_nilin_dis", 0)
                            if invoke then
                                local dummy = sgs.Sanguosha:cloneCard("slash")
                                dummy:deleteLater()
                                for _, id in sgs.qlist(player:handCards()) do
                                    if sgs.Sanguosha:getCard(id):hasFlag("s4_txbw_nilin") then
                                        dummy:addSubcard(id)
                                        room:setCardFlag(sgs.Sanguosha:getCard(id), "-s4_txbw_nilin")
                                    end
                                end
                                if dummy:subcardsLength() > 0 then
                                    room:throwCard(dummy, player)
                                end
                            end
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, player)
        return player
    end,
}

s4_txbw_zhaoyun:addSkill("s4_txbw_general_gain")
s4_txbw_zhaoyun:addSkill(s4_txbw_longdan)
s4_txbw_zhaoyun:addSkill(s4_txbw_nilin)

sgs.LoadTranslationTable {
    ["s4_txbw_zhaoyun"] = "赵云",
    ["&s4_txbw_zhaoyun"] = "赵云",
    ["#s4_txbw_zhaoyun"] = "见龙卸甲",
    ["~s4_txbw_zhaoyun"] = "",
    ["designer:s4_txbw_zhaoyun"] = "",
    ["cv:s4_txbw_zhaoyun"] = "",
    ["illustrator:s4_txbw_zhaoyun"] = "",

    ["s4_txbw_longdan"] = "龙胆",
    [":s4_txbw_longdan"] = "对决胜负判定前，你可以失去1点体力上限，然后与对方交换点数。",

    ["s4_txbw_nilin"] = "逆鳞",
    [":s4_txbw_nilin"] = "其他角色于其回合内使用第X张牌时，你可以弃置其场上的一张牌或获得其一张手牌。你可以跳过弃牌阶段，然后展示手牌并弃置至最多含X种花色（X为你的体力上限）。",


}

s4_txbw_weiyan = sgs.General(extension, "s4_txbw_weiyan", "shu", 4, true)



function generateAllCardObjectNameTablePatterns()
	local patterns = {}
	for i = 0, 10000 do
		local card = sgs.Sanguosha:getEngineCard(i)
		if card == nil then break end
		if (card:isKindOf("BasicCard") or card:isKindOf("TrickCard")) and not table.contains(patterns, card:objectName()) then
			table.insert(patterns, card:objectName())
		end
	end
	return patterns
end

function getPos(table, value)
	for i, v in ipairs(table) do
		if v == value then
			return i
		end
	end
	return 0
end

local pos = 0
s4_txbw_cangying_select = sgs.CreateSkillCard {
	name = "s4_txbw_cangying",
	will_throw = true,
	target_fixed = false,
    filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        local target = targets[1]
        local suit = card:getSuitString()
        local pattern = string.format(".|%s|.|hand",suit)
        local data = sgs.QVariant()
        data:setValue(source)
        local to_give = room:askForCard(target, pattern, "@s4_txbw_cangying", data, sgs.Card_MethodNone)
        room:addPlayerMark(source, "s4_txbw_cangying-Clear")
        if to_give then
            local cd = to_give:getEffectiveId()
            room:showCard(target, cd)
            room:obtainCard(source, to_give, true)
            local patterns = generateAllCardObjectNameTablePatterns()
            local choices = {}
            for i = 0, 10000 do
                local card = sgs.Sanguosha:getEngineCard(i)
                if card == nil then break end
                if (not (Set(sgs.Sanguosha:getBanPackages()))[card:getPackage()]) and not (table.contains(choices, card:objectName())) then
                    if card:isAvailable(source) and card:isNDTrick() then
                        table.insert(choices, card:objectName())
                    end
                end
            end

            if next(choices) ~= nil then
                table.insert(choices, "cancel")
                local pattern = room:askForChoice(source, "s4_txbw_cangying", table.concat(choices, "+"))
                if pattern and pattern ~= "cancel" then
                    local poi = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
                    if poi:targetFixed() then
                        poi:setSkillName("s4_txbw_cangying")
                        if self:subcardsLength() == 1 then
                            poi:addSubcard(self:getSubcards():first())
                        end
                        room:useCard(sgs.CardUseStruct(poi, source, source), true)
                    else
                        pos = getPos(patterns, pattern)
                        room:setPlayerMark(source, "s4_txbw_cangyingpos", pos)
                        room:askForUseCard(source, "@@s4_txbw_cangying", "@s4_txbw_cangying:" .. pattern) --%src
                    end
                end
            end
        else
            room:setPlayerMark(source, "&s4_txbw_cangying+s4_txbw_general_duel+-Clear", card:getNumber())
            room:acquireOneTurnSkills(source, "s4_txbw_cangying", "s4_txbw_juanzhuo")
        end
	end
}
s4_txbw_cangyingCard = sgs.CreateSkillCard {
	name = "s4_txbw_cangyingCard",
	will_throw = false,
	filter = function(self, targets, to_select)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			if card and card:targetFixed() then
				return false
			else
				return card and card:targetFilter(plist, to_select, sgs.Self) and
					not sgs.Self:isProhibited(to_select, card, plist)
			end
		end
		return true
	end,
	target_fixed = function(self)
		local name = ""
		local card
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)
		local name = ""
		local card
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local aocaistring = self:getUserString()
		if aocaistring ~= "" then
			local uses = aocaistring:split("+")
			name = uses[1]
			card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate_in_response = function(self, user)
		local room = user:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+") then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				table.insert(uses, name)
			end
			local name = room:askForChoice(user, "s4_txbw_cangying", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		use_card:setSkillName("s4_txbw_cangying")
		return use_card
	end,
	on_validate = function(self, card_use)
		local room = card_use.from:getRoom()
		local aocaistring = self:getUserString()
		local use_card = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, -1)
		if string.find(aocaistring, "+") then
			local uses = {}
			for _, name in pairs(aocaistring:split("+")) do
				table.insert(uses, name)
			end
			local name = room:askForChoice(card_use.from, "s4_txbw_cangying", table.concat(uses, "+"))
			use_card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		end
		if use_card == nil then return false end
		use_card:setSkillName("s4_txbw_cangying")
		local available = true
		for _, p in sgs.qlist(card_use.to) do
			if card_use.from:isProhibited(p, use_card) then
				available = false
				break
			end
		end
		if not available then return nil end
		return use_card
	end
}
s4_txbw_cangyingVS = sgs.CreateViewAsSkill {
	name = "s4_txbw_cangying",
	n = 1,
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern and pattern == "@@s4_txbw_cangying" then
			return false
		else
			return not to_select:isEquipped()
		end
	end,
	view_as = function(self, cards)
		local patterns = generateAllCardObjectNameTablePatterns()
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 1 then
				local acard = s4_txbw_cangying_select:clone()
				acard:addSubcard(cards[1]:getId())
				return acard
			end
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			local acard = s4_txbw_cangyingCard:clone()
			if pattern and pattern == "@@s4_txbw_cangying" then
				pattern = patterns[sgs.Self:getMark("s4_txbw_cangyingpos")]
				if #cards ~= 0 then return end
			end
			acard:setUserString(pattern)
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		local patterns = generateAllCardObjectNameTablePatterns()
		local choices = {}
		for _, name in ipairs(patterns) do
			local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
			if poi:isAvailable(player) and poi:isNDTrick() then
				table.insert(choices, name)
			end
		end
		return next(choices) and player:getMark("s4_txbw_cangying-Clear") == 0
	end,
	enabled_at_response = function(self, player, pattern)
		if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return false end
		return pattern == "@@s4_txbw_cangying"
	end,
}

s4_txbw_cangying = sgs.CreateTriggerSkill {
	name = "s4_txbw_cangying",
	view_as_skill = s4_txbw_cangyingVS,
	events = { sgs.EventPhaseEnd, sgs.PreCardUsed },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			for _, mygod in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				room:setPlayerMark(mygod, "s4_txbw_cangying-Clear", 0)
				room:setPlayerMark(mygod, "&s4_txbw_cangying-Clear", 0)
			end
		end
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(), "s4_txbw_cangying") and use.card:getTypeId() ~= 0 then
				room:addPlayerMark(player, "s4_txbw_cangying-Clear")
				room:addPlayerMark(player, "&s4_txbw_cangying-Clear")
			end
		end
	end,
	can_trigger = function(self, target)
		return target ~= nil
	end,
}
s4_txbw_cangying_duel = sgs.CreateTriggerSkill {
    name = "#s4_txbw_cangying_duel",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_cal") then
                    if player:getMark("&s4_txbw_cangying+s4_txbw_general_duel+-Clear") > 0 then
                        local msg = sgs.LogMessage()
                        msg.type = "#s4_txbw_general_duel_cal_point_add"
                        msg.from = player
                        msg.arg = "s4_txbw_cangying"
                        msg.arg2 = player:getMark("s4_txbw_general_duel")
                        room:addPlayerMark(player, "s4_txbw_general_duel", player:getMark("&s4_txbw_cangying+s4_txbw_general_duel+-Clear"))
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


s4_txbw_juanzhuoCard = sgs.CreateSkillCard{
	name = "s4_txbw_juanzhuo" ,
	filter = function(self, targets, to_select)
		return #targets == 0 and sgs.Self:inMyAttackRange(to_select) and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
	end ,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local card_id = room:askForCardChosen(effect.from, effect.to, "h", self:objectName())
        room:obtainCard(effect.from, card_id)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:inMyAttackRange(effect.from) then
                room:askForUseSlashTo(p,effect.from, "@s4_txbw_juanzhuo-slash:" .. effect.from:objectName())
            end
        end
	end
}
s4_txbw_juanzhuo = sgs.CreateViewAsSkill{
	name = "s4_txbw_juanzhuo",
	n = 0 ,
	view_as = function()
		return s4_txbw_juanzhuoCard:clone()
	end ,
	enabled_at_play = function(self, player)
		return player:isKongcheng()
	end
}


s4_txbw_weiyan:addSkill("s4_txbw_general_gain")
s4_txbw_weiyan:addSkill(s4_txbw_cangying)
s4_txbw_weiyan:addSkill(s4_txbw_cangying_duel)
extension:insertRelatedSkills("s4_txbw_cangying", "#s4_txbw_cangying_duel")
if not sgs.Sanguosha:getSkill("s4_txbw_juanzhuo") then
    s4_skillList:append(s4_txbw_juanzhuo)
end

s4_txbw_weiyan:addRelateSkill("s4_txbw_juanzhuo")

sgs.LoadTranslationTable {
    ["s4_txbw_weiyan"] = "魏延",
    ["&s4_txbw_weiyan"] = "魏延",
    ["#s4_txbw_weiyan"] = "璞瑶隙逆",
    ["~s4_txbw_weiyan"] = "",
    ["designer:s4_txbw_weiyan"] = "",
    ["cv:s4_txbw_weiyan"] = "",
    ["illustrator:s4_txbw_weiyan"] = "",

    ["s4_txbw_cangying"] = "藏缨",
    [":s4_txbw_cangying"] = "出牌阶段限一次，你可以弃置一张手牌并令一名其他角色选择一项：交给你一张同花色的手牌，你视为使用一张普通锦囊；本回合内，你获得“狷浊”，对决点数+X（X为你弃置牌的点数）。",

    ["s4_txbw_juanzhuo"] = "狷浊",
    [":s4_txbw_juanzhuo"] = "出牌阶段，若你没有手牌，你可以获得攻击范围内一名其他角色一张手牌，然后攻击范围内包含你的角色可以依次对你使用一张【杀】。",


}


s4_txbw_huangzhong = sgs.General(extension, "s4_txbw_huangzhong", "shu", 4, true)

s4_txbw_zaoying = sgs.CreateTriggerSkill {
    name = "s4_txbw_zaoying",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.CardFinished },
    priority = -1,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SkillCard") then
                if table.contains(use.card:getSkillNames(), "s4_txbw_general_duel_start") then
                    if player:getMark("@s4_txbw_general_1") > 0 then
                        local card = room:askForCard(player, ".Basic", self:objectName(), ToQVData(use.from),
                            sgs.Card_MethodDiscard,
                            player,
                            false, "@s4_txbw_zaoying", true)
                        if card then
                            room:setPlayerMark(player, "@s4_txbw_general_1", 0)
                            room:setPlayerMark(player, "@s4_txbw_general_2", 1)
                            
                            room:setPlayerMark(player, "&" .. self:objectName() .. "-Clear", 1)
                        end
                    end
                end
            end
        end
        return false
    end,
}

s4_txbw_liegong = sgs.CreateAttackRangeSkill{
	name = "s4_txbw_liegong",
	fixed_func = function(self, player, include_weapon)
		if player:hasSkill("s4_txbw_liegong") and player:getMark("@s4_txbw_general_2") > 0 then
			return 998
		end
	end,
}


sgs.LoadTranslationTable {
    ["s4_txbw_huangzhong"] = "黄忠",
    ["&s4_txbw_huangzhong"] = "黄忠",
    ["#s4_txbw_huangzhong"] = "神弓定军",
    ["~s4_txbw_huangzhong"] = "",
    ["designer:s4_txbw_huangzhong"] = "",
    ["cv:s4_txbw_huangzhong"] = "",
    ["illustrator:s4_txbw_huangzhong"] = "",

    ["s4_txbw_zaoying"] = "噪营",
    [":s4_txbw_zaoying"] = "发起对决后，你可以弃置一张基本牌并扣置武将标签。若如此做，防止你于该对决受到的对决伤害。",

    ["s4_txbw_liegong"] = "烈弓",
    [":s4_txbw_liegong"] = "锁定技，若武将标签已扣置，你的攻击范围无限。发起对决后，改为重置武将标签并对对方造成2点对决伤害。",


}













--[[
function addWeiTerritoryPile(card, player, self)
    local room = player:getRoom()
    card = type(card) == "number" and sgs.Sanguosha:getCard(card) or card
    self = type(self) == "string" and self or self and self:objectName() or ""
    if card:getEffectiveId() < 0 then
        return
    end

    local WeiTerritoryPile = room:getTag("WeiTerritoryPile"):toString():split("+")
    if #WeiTerritoryPile >= 13 then
        local log = sgs.LogMessage()
        log.type = "$addWeiTerritoryPileFailture"
        log.from = player
        log.arg = "WeiTerritoryPile"
        local toids = {}
        local c = dummyCard()
        for _, id in sgs.list(card:getSubcards()) do
            table.insert(toids, id)
            c:addSubcard(id)
        end
        log.card_str = table.concat(toids, "+")
        room:sendLog(log)
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, nil, nil,
            "addWeiTerritoryPileFailture", nil)
        room:throwCard(c, reason, nil)
        return
    end
    local log = sgs.LogMessage()
    log.type = "$addWeiTerritoryPile"
    log.from = player
    log.arg = "WeiTerritoryPile"
    local toids = {}
    local c = dummyCard()
    for _, id in sgs.list(card:getSubcards()) do
        table.insert(WeiTerritoryPile, id)
        table.insert(toids, id)
        c:addSubcard(id)
    end
    log.card_str = table.concat(toids, "+")
    room:sendLog(log)
    room:setTag("WeiTerritoryPile", sgs.QVariant(table.concat(WeiTerritoryPile, "+")))
    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName(), "", self,
        "addWeiTerritoryPile")
    room:moveCardTo(c, nil, sgs.Player_PlaceTable, reason, true)
    WeiTerritoryPile = room:getTag("WeiTerritoryPile"):toString():split("+")
    for _, p in sgs.list(room:getAlivePlayers()) do
        if p:getMark("&WeiTerritoryPile") > 0 then
            room:setPlayerMark(p, "&WeiTerritoryPile", #WeiTerritoryPile)
            return
        end
    end
    room:setPlayerMark(player, "&WeiTerritoryPile", #WeiTerritoryPile)
end

function getWeiTerritoryPile(player)
    local WeiTerritoryPile = player:getRoom():getTag("WeiTerritoryPile"):toString():split("+")
    local toid = sgs.IntList()
    for _, id in sgs.list(WeiTerritoryPile) do
        toid:append(id)
    end
    return toid
end

function gainWeiTerritoryPile(cards, player, self)
    if player:getKingdom() == "wei" then
        local room = player:getRoom()
        room:fillAG(cards, player)
        local card_id = room:askForAG(player, cards, false, self:objectName())
        room:obtainCard(player, card_id, false)
        room:clearAG(player)
    end
end

s4_weiT_lord = sgs.CreateTriggerSkill {
    name = "s4_weiT_lord&",
    events = sgs.EventPhaseStart,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Start and player:askForSkillInvoke(self:objectName()) then
            addWeiTerritoryPile(room:getNCards(2), player, self)
        end
    end
}
addToSkills(s4_weiT_lord)

s4_weiT_adviser = sgs.CreateTriggerSkill {
    name = "s4_weiT_adviser&",
    events = sgs.CardUsed,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if (use.card and use.card:getTypeId() == sgs.Card_TypeTrick and player:getMark("&s4_weiT_adviser-Clear") == 0 and
                getWeiTerritoryPile(player):length() > 0) and player:askForSkillInvoke(self:objectName()) then
            gainWeiTerritoryPile(getWeiTerritoryPile(player), player, self)
            room:addPlayerMark(player, "&s4_weiT_adviser-Clear")
        end
    end
}
addToSkills(s4_weiT_adviser)
s4_weiT_gerenal = sgs.CreateTriggerSkill {
    name = "s4_weiT_gerenal&",
    events = sgs.Damage,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if not damage.card or not damage.card:isKindOf("Slash") then
            return false
        end
        if player:getMark("&s4_weiT_gerenal-Clear") == 0 and getWeiTerritoryPile(player):length() > 0 and
            player:askForSkillInvoke(self:objectName()) then
            gainWeiTerritoryPile(getWeiTerritoryPile(player), player, self)
            room:addPlayerMark(player, "&s4_weiT_gerenal-Clear")
        end
    end
}
addToSkills(s4_weiT_gerenal)

sgs.LoadTranslationTable {
    ["addWeiTerritoryPile"] = "添加至魏领土",
    ["WeiTerritoryPile"] = "魏领土",
    ["$addWeiTerritoryPile"] = "%from 将 %card 置入“%arg”区",

    ["s4_weiT_lord"] = "君主",
    [":s4_weiT_lord"] = "天赋技，回合开始时，可将牌堆顶两牌置于【魏领土】。",
    ["s4_weiT_adviser"] = "谋臣",
    [":s4_weiT_adviser"] = "天赋技，每回合一次，当你使用一张锦囊牌时，可从【魏领土】中获得一张牌。",
    ["s4_weiT_gerenal"] = "功勋",
    [":s4_weiT_gerenal"] = "天赋技，每回合一次，当你使用【杀】造成伤害后，你可以从【魏领土】中获得一张牌。"

}

s4_weiT_caocao = sgs.General(extension, "s4_weiT_caocao", "wei", 4, true)
s4_weiT_naxian = sgs.CreateTriggerSkill {
    name = "s4_weiT_naxian",
    events = { sgs.Damaged, sgs.DrawNCards, sgs.GameStart },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damaged then
            local damage = data:toDamage()
            room:setPlayerMark(player, "&" .. self:objectName(),
                math.max(math.min(player:getHp(), player:getMark("&" .. self:objectName())), 2))
        elseif event == sgs.DrawNCards then
            local x = player:getMark("&" .. self:objectName())
            if room:askForSkillInvoke(player, self:objectName()) then
                local card_ids = room:getNCards(x)
                local obtained = sgs.IntList()
                room:fillAG(card_ids, player)
                local id1 = room:askForAG(player, card_ids, false, self:objectName())
                card_ids:removeOne(id1)
                obtained:append(id1)
                room:takeAG(player, id1, false)
                local id2 = room:askForAG(player, card_ids, true, self:objectName())
                if id2 ~= -1 then
                    card_ids:removeOne(id2)
                    obtained:append(id2)
                end
                room:clearAG(player)
                addWeiTerritoryPile(card_ids, player, self)
                local dummy = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
                for _, id in sgs.qlist(obtained) do
                    dummy:addSubcard(id)
                end
                player:obtainCard(dummy, false)
                dummy:deleteLater()
            end
        elseif event == sgs.GameStart then
            room:setPlayerMark(player, "&" .. self:objectName(), player:getHp())
        end
    end
}
s4_weiT_xionglue = sgs.CreateTriggerSkill {
    name = "s4_weiT_xionglue",
    events = { sgs.Damaged },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if getWeiTerritoryPile(player):length() > 0 and player:askForSkillInvoke(self:objectName()) then
                gainWeiTerritoryPile(getWeiTerritoryPile(player), player, self)
            end
        end
    end
}

s4_weiT_caocao:addSkill(s4_weiT_naxian)
s4_weiT_caocao:addSkill(s4_weiT_xionglue)
s4_weiT_caocao:addSkill("s4_weiT_lord")

sgs.LoadTranslationTable {
    ["s4_weiT_caocao"] = "曹操",
    ["#s4_weiT_caocao"] = "",

    ["s4_weiT_naxian"] = "纳贤",
    [":s4_weiT_naxian"] = "摸牌阶段，你可以改为观看牌堆顶X张牌，然后你可以获得其中至多两张牌，并将其余的牌置于【魏领土】。X为你本局游戏体力最小值且至少为2。",
    ["s4_weiT_xionglue"] = "雄略",
    [":s4_weiT_xionglue"] = "当你受到一次伤害后，你可以从【魏领土】中获得一张牌。"

}

s4_weiT_xiahoudun = sgs.General(extension, "s4_weiT_xiahoudun", "wei", 4, true)

s4_weiT_ganglie = sgs.CreateTriggerSkill {
    name = "s4_weiT_ganglie",
    events = { sgs.Damage, sgs.Damaged },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        local target = nil
        if event == sgs.Damage then
            target = damage.to
        else
            target = damage.from
        end
        if not target or target:objectName() == player:objectName() then
            return false
        end
        if not damage.card or not damage.card:isKindOf("Slash") then
            return false
        end
        local players = sgs.SPlayerList()
        if room:askForSkillInvoke(player, self:objectName(), ToQVData(target)) then
            local judge = sgs.JudgeStruct()
            judge.pattern = ".|black"
            judge.good = true
            judge.reason = self:objectName()
            judge.who = player
            room:judge(judge)
            if judge:isGood() and target:isAlive() and not target:isNude() then
                local card_id = room:askForCardChosen(player, target, "he", self:objectName())
                room:obtainCard(player, card_id)
            elseif judge:isBad() and damage.to:isAlive() and damage.from and damage.from:isAlive() then
                room:damage(sgs.DamageStruct(self, damage.to, damage.from, 1, sgs.DamageStruct_Normal))
            end
        end
    end
}

s4_weiT_qingjian = sgs.CreateTriggerSkill {
    name = "s4_weiT_qingjian",
    events = { sgs.CardsMoveOneTime },
    on_trigger = function(self, event, player, data)
        local move = data:toMoveOneTime()
        local room = player:getRoom()
        if not room:getTag("FirstRound"):toBool() and player:getPhase() ~= sgs.Player_Draw and move.to and
            move.to:objectName() == player:objectName() then
            local ids = sgs.IntList()
            for _, id in sgs.qlist(move.card_ids) do
                if room:getCardOwner(id) == player and room:getCardPlace(id) == sgs.Player_PlaceHand then
                    ids:append(id)
                end
            end
            if ids:isEmpty() then
                return false
            end
            local cards = room:askForExchange(player, self:objectName(), 1, 999, false, "@s4_weiT_qingjian")
                :getSubcards()
            if cards then
                addWeiTerritoryPile(cards, player, self)
            end
        end
        return false
    end
}

s4_weiT_xiahoudun:addSkill(s4_weiT_ganglie)
s4_weiT_xiahoudun:addSkill(s4_weiT_qingjian)
s4_weiT_xiahoudun:addSkill("s4_weiT_gerenal")

sgs.LoadTranslationTable {
    ["s4_weiT_xiahoudun"] = "夏侯惇",
    ["#s4_weiT_xiahoudun"] = "",

    ["s4_weiT_ganglie"] = "刚烈",
    [":s4_weiT_ganglie"] = "当你使用【杀】造成伤害或受到【杀】造成的伤害后，你可以作一次判定，若结果为黑色，你获得其一张牌，否则受伤角色对对方造成1点伤害。",
    ["s4_weiT_qingjian"] = "清俭",
    [":s4_weiT_qingjian"] = "你可将摸牌阶段外获得的牌置于【魏领土】中。"

}]]


s4_huaxiong = sgs.General(extension, "s4_huaxiong", "qun", 6, true)


s4_shiyong = sgs.CreateTriggerSkill {
    name = "s4_shiyong",
    frequency = sgs.Skill_NotFrequent,
    events = { sgs.Damage, sgs.CardsMoveOneTime },
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damage then
            local current = room:getCurrent()
            if not current or current:getPhase() == sgs.Player_NotActive then return end
            local x = player:getHp() - player:getHandcardNum()
            if player:getMark("&" .. self:objectName() .. "damage" .. "-"..current:getPhase().."Clear") > 0 then return end

            if x > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
                room:addPlayerMark(player, "&" .. self:objectName() .. "damage" .. "-"..current:getPhase().."Clear")
                player:drawCards(x)
                room:broadcastSkillInvoke(self:objectName())
            end
        elseif event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            local dest = move.to
            local hand = move.to_place
            local fromplace = move.from_places
            local cards = move.card_ids
            local reason = move.reason
            local count = cards:length()
            local current = room:getCurrent()
            if not current or current:getPhase() == sgs.Player_NotActive then return end
            if player:getPhase() == sgs.Player_Draw then return end
            if player:getMark("&" .. self:objectName().. "-"..current:getPhase().."Clear") > 0 then return end

            if not room:getTag("FirstRound"):toBool() then
                if (dest and dest:objectName() == player:objectName() and hand == sgs.Player_PlaceHand) or
                    (move.from and move.from:objectName() == player:objectName() and
                        (fromplace:contains(sgs.Player_PlaceEquip) or fromplace:contains(sgs.Player_PlaceHand))
                        and not (hand == sgs.Player_PlaceEquip or hand == sgs.Player_PlaceHand)) then
                    if count >= 2 then
                        local x = count / 2

                        room:sendCompulsoryTriggerLog(player, self:objectName(), true)
                        for i = 0, x - 1, 1 do
                            room:loseHp(player, 1, true, player, self:objectName())
                            break
                        end
                        
                        room:addPlayerMark(player, "&" .. self:objectName() .. "-"..current:getPhase().."Clear")

                        room:broadcastSkillInvoke(self:objectName())
                    end
                end
            end
        end
    end,
}
s4_huaxiong:addSkill(s4_shiyong)

--https://tieba.baidu.com/p/3472257233#61764205069l
sgs.LoadTranslationTable {
    ["s4_huaxiong"] = "华雄",
    ["&s4_huaxiong"] = "华雄",
    ["#s4_huaxiong"] = "魔将",
    ["~s4_huaxiong"] = "",
    ["designer:s4_huaxiong"] = "联合复兴",
    ["cv:s4_huaxiong"] = "",
    ["illustrator:s4_huaxiong"] = "",

    ["s4_shiyongdamage"] = "恃勇:造成伤害",
    ["s4_shiyong"] = "恃勇",
    [":s4_shiyong"] = "<font color=\"green\"><b>每阶段各限一次，</b></font>你每造成一次伤害，可以将手牌数补充至与体力值相同的张数。锁定技，摸牌阶段以外，你每获得或失去不少于两张牌，你失去一点体力。",

}
s4_sunjian = sgs.General(extension, "s4_sunjian", "wu", 4)

s4_beizhen_cardmax = sgs.CreateMaxCardsSkill{
    name = "#s4_beizhen_cardmax",
    fixed_func = function(self, target)
        if target:hasSkill("s4_beizhen") then
            return target:getMaxHp()
        else
            return -1
        end
    end
}
s4_beizhenVS = sgs.CreateViewAsSkill{
	name = "s4_beizhen",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected<1 and (to_select:isKindOf("Jink") or to_select:isKindOf("Peach"))
    end,
	view_as = function(self,cards)
		if #cards == 1 then
			local acard = sgs.Sanguosha:cloneCard("duel", cards[1]:getSuit(), cards[1]:getNumber())
			acard:addSubcard(cards[1])
			acard:setSkillName("s4_beizhen")
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return player:hasFlag("s4_beizhen_buff")
	end,
}
s4_beizhen = sgs.CreateTriggerSkill{
	name = "s4_beizhen",
	events = {sgs.EventPhaseStart, sgs.DamageInflicted},
	view_as_skill = s4_beizhenVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
            room:setPlayerMark(player, "s4_beizhen", 0)
            room:setPlayerMark(player, "&s4_beizhen", 0)
			if not player:isAllNude() and room:askForSkillInvoke(player, self:objectName()) then 
                local x = 0
                while not player:isAllNude() do
                    local id = room:askForCardChosen(player, player, "hej", self:objectName(), false, sgs.Card_MethodRecast, sgs.IntList(), x > 0)
                    if id == -1 then break end
                    x = x + 1
                    local card = sgs.Sanguosha:getCard(id)
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, player:objectName())
                    reason.m_skillName = self:objectName()
                    room:moveCardTo(card, player, nil, sgs.Player_DiscardPile, reason);
                    player:broadcastSkillInvoke("@recast")
                    local log = sgs.LogMessage()
                    log.type = "#UseCard_Recast"
                    log.from = player
                    log.card_str = card:getNumberString()
                    room:sendLog(log)
                    player:drawCards(1, "recast")
                end
                
                local choice = room:askForChoice(player, self:objectName(), "losehp+damage+cancel")
                if choice ~= "cancel" then
                    room:setPlayerFlag(player, "s4_beizhen_buff")
                    if choice == "damage" then
                        room:addPlayerMark(player, "s4_beizhen")
                        room:addPlayerMark(player, "&s4_beizhen")
                    else
                        room:loseHp(player, 1, true, player, self:objectName())
                        player:drawCards(1, self:objectName())
                    end
                end
            end
        elseif event == sgs.DamageInflicted then
            if player:getMark("s4_beizhen") > 0 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                room:setPlayerMark(player, "s4_beizhen", 0)
                room:setPlayerMark(player, "&s4_beizhen", 0)
                local damage = data:toDamage()
                damage.damage = damage.damage + 1
                data:setValue(damage)
            end
		end
	end
}
s4_fani = sgs.CreateTriggerSkill{
	name = "s4_fani",  
	frequency = sgs.Skill_Frequent, 
	events = {sgs.TargetSpecified, sgs.Death}, 
	on_trigger = function(self, event, player, data) 
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card and use.card:isDamageCard() and player:getMark("s4_fani-Clear") == 0 then
                for _,p in sgs.qlist(use.to) do
                    if p:getHp() > player:getHp() then
                        local choicelist = {}
                        table.insert(choicelist, "cancel")
                        table.insert(choicelist, "draw")
                        if player:canDiscard(p, "he") then
                            table.insert(choicelist, "discard")
                            table.insert(choicelist, "bieshui")
                        end
                        local choice = room:askForChoice(player, self:objectName(), table.concat(choicelist, "+"), ToData(p))
                        if choice ~= "cancel" then
                            if choice == "draw" or choice == "bieshui" then
                                player:drawCards(1, self:objectName())
                            end
                            if choice == "discard" or choice == "bieshui" then
                                local id = room:askForCardChosen(player,p, "he", self:objectName())
                                local card = sgs.Sanguosha:getCard(id)
                                room:throwCard(card, player, p)
                            end
                            if choice == "bieshui" then
                                room:addPlayerMark(player, "s4_fani-Clear")
                                room:addPlayerMark(player, "&s4_fani-Clear")
                                use.m_addHistory = false
                                data:setValue(use)
                            end
                        end
                    end
				end
			end
        elseif event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() ~= player:objectName() then return false end
            local killer
            if death.damage then
                killer = death.damage.from
            else
                killer = nil
            end
            if killer and killer:objectName() == player:objectName() then
                room:setPlayerMark(player, "s4_fani-Clear", 0)
                room:setPlayerMark(player, "&s4_fani-Clear", 0)
            end
		end
	end,
}



s4_sunjian:addSkill(s4_beizhen_cardmax)
s4_sunjian:addSkill(s4_beizhen)
s4_sunjian:addSkill(s4_fani)
extension:insertRelatedSkills("s4_beizhen","#s4_beizhen_cardmax")

sgs.LoadTranslationTable {
    ["s4_sunjian"] = "孙坚",
    ["&s4_sunjian"] = "孙坚",
    ["#s4_sunjian"] = "破虜將軍",
    ["~s4_sunjian"] = "",
    ["designer:s4_sunjian"] = "终极植物",
    ["cv:s4_sunjian"] = "",
    ["illustrator:s4_sunjian"] = "",

    ["s4_beizhen:losehp"] = "失去1点体力并摸一张牌",
    ["s4_beizhen:damage"] = "你下一次受到的伤害+1直到你下回合开始",
    ["s4_beizhen"] = "备阵",
    [":s4_beizhen"] = "你的手牌上限等于体力上限。回合开始时，你可以重铸你区域里的任意张牌，然后你可以选择一项并令你本回合可以将一张【闪】或【桃】当【决斗】使用：1.失去1点体力并摸一张牌；2.你下一次受到的伤害+1直到你下回合开始。",

    ["s4_fani:draw"] = "摸一张牌",
    ["s4_fani:throw"] = "弃置其一张牌",
    ["s4_fani"] = "伐逆",
    [":s4_fani"] = "当你使用伤害类牌指定一名体力值大于你的其他角色为目标后，你可以选择一项：1.摸一张牌；2.弃置其一张牌；背水：此次使用的牌不计入次数限制且此技能失效直到本回合结束或你杀死一名角色。",

}
--https://tieba.baidu.com/p/9092138125?pid=150600234453&cid=#150600234453

s4_godzhaoyun = sgs.General(extension, "s4_godzhaoyun", "god", 3, true, false, false, 1)

s4_juejingcard = sgs.CreateSkillCard{
	name = "s4_juejing",
	target_fixed = false,
	will_throw = false,
	mute = true,
    filter = function(self, targets, to_select, player)
         return #targets < 1 and to_select:objectName() ~= player:objectName()
        and to_select:hasFlag("s4_juejing")
    end,
	on_use = function(self,room,source,targets)
        local target = targets[1]	
	    local cardid = self:getSubcards():first()
	    local card = sgs.Sanguosha:getCard(cardid)
	    if card:isRed() then
	    	local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,card:getNumber())
	    	indulgence:addSubcard(card)
	    	indulgence:setSkillName("s4_juejing")
	    	room:useCard(sgs.CardUseStruct(indulgence,source,target))
            indulgence:deleteLater()
	    elseif card:isBlack() then
	    	local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage",sgs.Card_Club,card:getNumber())
	    	supply_shortage:addSubcard(card)
	    	supply_shortage:setSkillName("s4_juejing")
	    	room:useCard(sgs.CardUseStruct(supply_shortage,source,target))
            supply_shortage:deleteLater()
	    end
	end	    
}

s4_juejingVS = sgs.CreateViewAsSkill{
	name = "s4_juejing",
	n=1,
	view_filter = function(self,selected,to_select)
		if #selected >0 then return false end		
        local color_string =  sgs.Self:property("s4_juejing_suit"):toString():split("+")
        if #color_string > 0 then
			return table.contains(color_string, to_select:getColorString())
		end
		return false	
	end,	
	view_as = function(self,cards)
		if #cards ~= 1 then return nil end		
		local acard = s4_juejingcard:clone()
		acard:addSubcard(cards[1])
		acard:setSkillName("s4_juejing")		
		return acard
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
        return pattern == "@@s4_juejing" 
    end
}
s4_juejing = sgs.CreateTriggerSkill{
    name = "s4_juejing",
	events = {sgs.EnterDying},
    view_as_skill = s4_juejingVS,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local dying = data:toDying()
		local victim = dying.who
        local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,0)
		indulgence:deleteLater()
		local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage",sgs.Card_Club,0)
		supply_shortage:deleteLater()
        for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
            local colors = {}
            if not (p:isProhibited(victim,indulgence) or victim:containsTrick("indulgence")) then
                table.insert(colors, "red")
            end
            if not (p:isProhibited(victim,supply_shortage) or victim:containsTrick("supply_shortage")) then
                table.insert(colors, "black")
            end
            if #colors > 0 then
                room:setPlayerProperty(p, "s4_juejing_suit", sgs.QVariant(table.concat(colors, "+")))
            end
            room:setPlayerFlag(victim, "s4_juejing")
            if #colors > 0 and room:askForUseCard(p, "@@s4_juejing", "@s4_juejing") then
                room:setPlayerFlag(victim, "-s4_juejing")
                local re = sgs.RecoverStruct()
                re.who = p
                re.recover = 1 - victim:getHp()
                room:recover(victim, re)
                room:addPlayerMark(victim, "&s4_juejing+to+#"..p:objectName().."-Clear")
                break
            end
            room:setPlayerFlag(victim, "-s4_juejing")
        end
		return false
	end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

s4_juejing_buff = sgs.CreateTriggerSkill{
    name = "#s4_juejing_buff",
    events = {sgs.DamageInflicted},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if damage.to then
                local names = damage.to:getMarkNames()
                local can_invoke = false
                for _,name in ipairs(names) do
                    if damage.to:getMark(name) > 0 and name:startsWith("&s4_juejing") then
                        room:setPlayerMark(damage.to, name, 0)
                        can_invoke = true
                        break
                    end
                end
                if can_invoke then
                    return player:damageRevises(data,-damage.damage)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target 
    end,
}

s4_longhun = sgs.CreateTriggerSkill{
	name = "s4_longhun",
	events = {sgs.Damaged, sgs.DrawNCards},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        if event == sgs.Damaged then
            if room:canMoveField("ej") then
                room:moveField(player, self:objectName(), true, "ej")
            else
                player:drawCards(player:getLostHp(), self:objectName())
            end
        elseif event == sgs.DrawNCards then
            local draw = data:toDraw()
            if draw.reason ~= "draw_phase" then return false end
            room:sendCompulsoryTriggerLog(player, self:objectName())
            draw.num = draw.num + player:getLostHp()
            data:setValue(draw)
        end
	end
}
s4_longhun_cardmax = sgs.CreateMaxCardsSkill {
	name = "#s4_longhun_cardmax",
	extra_func = function(self, target)
		if target:hasSkill("s4_longhun") then
			return target:getLostHp()
		else
			return 0
		end
	end
}


s4_godzhaoyun:addSkill(s4_juejing)
s4_godzhaoyun:addSkill(s4_juejing_buff)
extension:insertRelatedSkills("s4_juejing","#s4_juejing_buff")

s4_godzhaoyun:addSkill(s4_longhun)
s4_godzhaoyun:addSkill(s4_longhun_cardmax)
extension:insertRelatedSkills("s4_longhun","#s4_longhun_cardmax")



sgs.LoadTranslationTable {
    ["s4_godzhaoyun"] = "赵云",
    ["&s4_godzhaoyun"] = "赵云",
    ["#s4_godzhaoyun"] = "神威如龙",
    ["~s4_godzhaoyun"] = "",
    ["designer:s4_godzhaoyun"] = "九九六♬",
    ["cv:s4_godzhaoyun"] = "",
    ["illustrator:s4_godzhaoyun"] = "",

    ["s4_juejing"] = "绝境",
    [":s4_juejing"] = "一名角色进入濒死时，你可将一张红色/黑色牌当【乐不思蜀】/【兵粮寸断】对其使用，然后其回复体力至1点并防止其本回合下次受到的伤害。",
    ["@s4_juejing"] = "绝境：你可将一张红色/黑色牌当【乐不思蜀】/【兵粮寸断】对其使用",

    ["s4_longhun"] = "龙魂",
    [":s4_longhun"] = "锁定技，你受到伤害后，你移动埸上一张牌，若没有可移动的牌，你摸x张牌。你的手牌上限和摸牌阶段摸牌数+x。 （x为你已损失体力值）",

}

--https://tieba.baidu.com/p/9685722584

s4_wenyang = sgs.General(extension, "s4_wenyang", "jin", 3)




s4_chiyuanCard = sgs.CreateSkillCard{
    name = "s4_chiyuan",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:addPlayerMark(source, "s4_chiyuan")
        source:enterYinniState(0)
    end
}
s4_chiyuanVS = sgs.CreateZeroCardViewAsSkill{
    name = "s4_chiyuan",
    view_as = function(self)
        return s4_chiyuanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#s4_chiyuan")
    end
}
s4_chiyuan = sgs.CreateTriggerSkill{
	name = "s4_chiyuan",
	events = {sgs.Appear},
    hide_skill = true,
    view_as_skill = s4_chiyuanVS,
	on_trigger = function(self, event, player, data, room)
        player:drawCards(1, self:objectName())
        room:notifySkillInvoked(player, self:objectName())
	end
}

s4_chiyuan_buff = sgs.CreateTriggerSkill{
	name = "#s4_chiyuan_buff",
	events = {sgs.EventPhaseChanging},
    global = true,
	on_trigger = function(self, event, player, data, room)
        local change = data:toPhaseChange()
        if change.to == sgs.Player_NotActive then
            if player:getMark("s4_chiyuan") > 0 then
                room:setPlayerMark(player, "s4_chiyuan", 0)
                player:breakYinniState()
            end
        end
	end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

s4_gangluCard = sgs.CreateSkillCard{
	name = "s4_ganglu",
	will_throw = false,
	filter = function(self, targets, to_select)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		local rangefix = 0
		if not self:getSubcards():isEmpty() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == self:getSubcards():first() then
			local card = sgs.Self:getWeapon():getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - sgs.Self:getAttackRange(false)
		end
		if not self:getSubcards():isEmpty() and sgs.Self:getOffensiveHorse() and sgs.Self:getOffensiveHorse():getId() == self:getSubcards():first() then
			rangefix = rangefix + 1
		end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
				and (card:isKindOf("Slash") and sgs.Self:canSlash(to_select, true, rangefix))
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local card = sgs.Self:getTag("s4_ganglu"):toCard()
		return card and card:targetFilter(plist, to_select, sgs.Self) and not sgs.Self:isProhibited(to_select, card, plist)
			and (card:isKindOf("Slash") and sgs.Self:canSlash(to_select, true, rangefix))
	end,
	target_fixed = function(self)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetFixed()
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = sgs.Self:getTag("s4_ganglu"):toCard()
		return card and card:targetFixed()
	end,
	feasible = function(self, targets)
		local plist = sgs.PlayerList()
		for i = 1, #targets do plist:append(targets[i]) end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card, user_str = nil, self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetsFeasible(plist, sgs.Self)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = sgs.Self:getTag("s4_ganglu"):toCard()
		return card and card:targetsFeasible(plist, sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
		local room, to_xin_zhayi_jiben = player:getRoom(), self:getUserString()
		if self:getUserString() == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local xin_zhayi_jiben_list = {}
			table.insert(xin_zhayi_jiben_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(xin_zhayi_jiben_list, "normal_slash")
				table.insert(xin_zhayi_jiben_list, "thunder_slash")
				table.insert(xin_zhayi_jiben_list, "fire_slash")
			end
			to_xin_zhayi_jiben = room:askForChoice(player, "s4_ganglu_slash", table.concat(xin_zhayi_jiben_list, "+"))
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_xin_zhayi_jiben == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_xin_zhayi_jiben == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_xin_zhayi_jiben
		end
        room:addPlayerMark(player, "s4_ganglu-Clear")
        room:addPlayerMark(player, "&s4_ganglu-Clear")
		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("s4_ganglu")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
        room:setCardFlag(use_card, "RemoveFromHistory")
		return use_card
	end,
	on_validate_in_response = function(self, user)
		local room, user_str = user:getRoom(), self:getUserString()
		local to_xin_zhayi_jiben
		if user_str == "peach+analeptic" then
			local xin_zhayi_jiben_list = {}
			table.insert(xin_zhayi_jiben_list, "peach")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(xin_zhayi_jiben_list, "analeptic")
			end
			to_xin_zhayi_jiben = room:askForChoice(user, "s4_ganglu_saveself", table.concat(xin_zhayi_jiben_list, "+"))
		elseif user_str == "slash" then
			local xin_zhayi_jiben_list = {}
			table.insert(xin_zhayi_jiben_list, "slash")
			if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
				table.insert(xin_zhayi_jiben_list, "normal_slash")
				table.insert(xin_zhayi_jiben_list, "thunder_slash")
				table.insert(xin_zhayi_jiben_list, "fire_slash")
			end
			to_xin_zhayi_jiben = room:askForChoice(user, "s4_ganglu_slash", table.concat(xin_zhayi_jiben_list, "+"))
		else
			to_xin_zhayi_jiben = user_str
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_xin_zhayi_jiben == "slash" then
			if card and card:isKindOf("Slash") then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		elseif to_xin_zhayi_jiben == "normal_slash" then
			user_str = "slash"
		else
			user_str = to_xin_zhayi_jiben
		end
        room:addPlayerMark(user, "s4_ganglu-Clear")
        room:addPlayerMark(user, "&s4_ganglu-Clear")
		local use_card = sgs.Sanguosha:cloneCard(user_str, card and card:getSuit() or sgs.Card_SuitToBeDecided, card and card:getNumber() or -1)
		use_card:setSkillName("s4_ganglu")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
        room:setCardFlag(use_card, "RemoveFromHistory")
		return use_card
	end
}
s4_ganglu = sgs.CreateViewAsSkill{
	name = "s4_ganglu",
	n=1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
            return true
	    end
	end,
	view_as = function(self, cards)
		if #cards ~= 1 then return nil end
		local skillcard = s4_gangluCard:clone()
		skillcard:setSkillName(self:objectName())
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
			or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			skillcard:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
			for _, card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		end
		local c = sgs.Self:getTag("s4_ganglu"):toCard()
		if c then
			skillcard:setUserString(c:objectName())
			for _, card in ipairs(cards) do
				skillcard:addSubcard(card)
			end
			return skillcard
		else
			return nil
		end
	end,
	enabled_at_play = function(self, player)
		if player:getMark("s4_ganglu-Clear") > 0 then return false end
		for _,patt in ipairs(patterns())do
			local dc = dummyCard(patt)
			if dc and dc:isKindOf("BasicCard") then
				dc:setSkillName(self:objectName())
				if dc:isAvailable(player)
				then return true end
			end
		end
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		if player:getMark("s4_ganglu-Clear") > 0 then return false end
        for _,pt in sgs.list(pattern:split("+"))do
			local dc = dummyCard(pt)
			if dc and dc:isKindOf("BasicCard") then
				return true
			end
		end
	end
}

s4_ganglu_buff = sgs.CreateTargetModSkill{
	name = "#s4_ganglu_buff",
	distance_limit_func = function(self, from, card)
		if from:hasSkill("s4_ganglu") and card and table.contains(card:getSkillNames(), "s4_ganglu") then
			return 1000
		else
			return 0
		end
	end
}
s4_ganglu:setGuhuoDialog("l")

s4_pinglu = sgs.CreateFilterSkill{
    name = "s4_pinglu", 
    view_filter = function(self,to_select)
        local room = sgs.Sanguosha:currentRoom()
        local place = room:getCardPlace(to_select:getEffectiveId())
        return (to_select:isKindOf("TrickCard")) and (place == sgs.Player_PlaceHand)
    end,
    view_as = function(self, originalCard)
        local duel = sgs.Sanguosha:cloneCard("duel", originalCard:getSuit(), originalCard:getNumber())
        duel:setSkillName(self:objectName())
        local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
        card:takeOver(duel)
        return card
    end
}
s4_pinglu_buff = sgs.CreateTriggerSkill{
    name = "#s4_pinglu_buff",
    events = {sgs.CardUsed},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Duel") then
                for _, p in sgs.qlist(room:findPlayersBySkillName("s4_pinglu")) do
                    if p:hasSkill("s4_ganglu") then
                        room:setPlayerMark(p, "s4_ganglu-Clear", 0)
                        room:setPlayerMark(p, "&s4_ganglu-Clear", 0)
                    end
                    if p:objectName() ~= use.from:objectName() then
                        p:drawCards(1, "s4_pinglu")
                        room:notifySkillInvoked(p, "s4_pinglu")
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}

s4_wenyang:addSkill(s4_chiyuan)
s4_wenyang:addSkill(s4_chiyuan_buff)
s4_wenyang:addSkill(s4_ganglu)
s4_wenyang:addSkill(s4_ganglu_buff)
extension:insertRelatedSkills("s4_ganglu","#s4_ganglu_buff")
s4_wenyang:addSkill(s4_pinglu)
s4_wenyang:addSkill(s4_pinglu_buff)
extension:insertRelatedSkills("s4_pinglu","#s4_pinglu_buff")

sgs.LoadTranslationTable {
    ["s4_wenyang"] = "文鸯",
    ["&s4_wenyang"] = "文鸯",
    ["#s4_wenyang"] = "骁勇金衔",
    ["~s4_wenyang"] = "",
    ["designer:s4_wenyang"] = "阿尔德法咒",
    ["cv:s4_wenyang"] = "",
    ["illustrator:s4_wenyang"] = "",

    ["s4_chiyuan"] = "驰援",
    [":s4_chiyuan"] = "隐匿。当你登埸时，你摸一张牌。出牌阶段限一次，你可以隐匿至回合结束时登埸。",

    ["s4_ganglu_saveself"] = "刚膂",
    ["s4_ganglu_slash"] = "刚膂",
    ["s4_ganglu"] = "刚膂",
    [":s4_ganglu"] = "每回合限一次，你可以将一张牌当不计入限制次数且无距离限制的任意基本牌使用或打出。",

    ["s4_pinglu"] = "平虏",
    [":s4_pinglu"] = "锁定技，你的锦囊牌视为决斗。当有角色使用决斗后，你视为未发动过刚膂，且若使用者不为你，你摸一张牌。",

}

--https://tieba.baidu.com/p/9681042164



s4_huanzhaoyun = sgs.General(extension, "s4_huanzhaoyun", "shu", 4, true, false, false, 3)

s4_longxinVS = sgs.CreateViewAsSkill{
	name = "s4_longxin" ,
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
		return sgs.Slash_IsAvailable(target) and not target:isWounded()
	end,
	enabled_at_response = function(self, target, pattern)
		return not target:isWounded() and ((pattern == "slash") or (pattern == "jink"))
	end
}
s4_longxin = sgs.CreateTriggerSkill{
	name = "s4_longxin" ,
    view_as_skill = s4_longxinVS,
	events = {sgs.CardResponded, sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardResponded then
	        	local resp = data:toCardResponse()
	        	if table.contains(resp.m_card:getSkillNames(), "s4_longxin") and resp.m_who and (not resp.m_who:isKongcheng()) then
		            	local _data = sgs.QVariant()
				_data:setValue(resp.m_who)
		                if player:askForSkillInvoke(self:objectName(), _data) then
		                	local card_id = room:askForCardChosen(player, resp.m_who, "h", self:objectName())
		                	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
		                	room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
		                end
	        	end
	        else
	            local use = data:toCardUse()
	            if table.contains(use.card:getSkillNames(), "s4_longxin") then
	                for _, p in sgs.qlist(use.to) do
	                	if p:isKongcheng() then continue end
	                	local _data = sgs.QVariant()
                        _data:setValue(p)
                        p:setFlags("s4_longxinTarget")
	                	local invoke = player:askForSkillInvoke(self:objectName(), _data)
	                	p:setFlags("-s4_longxinTarget")
	                	if invoke then
                            local card_id = room:askForCardChosen(player, p, "h", self:objectName())
                            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
                            room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
                        end
	                end
                    if use.to:isEmpty() and use.who and use.who:objectName() ~= player:objectName() and not use.who:isKongcheng() then
                        if player:askForSkillInvoke(self:objectName(), ToData(use.who)) then
                            local card_id = room:askForCardChosen(player, p, "h", self:objectName())
                            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
                            room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
                        end
                    end
	            end
	        end
	        return false
	end
}

s4_jiezhan = sgs.CreateTriggerSkill{
	name = "s4_jiezhan",
	events = {sgs.EventPhaseStart, sgs.DamageCaused},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
        if event == sgs.EventPhaseStart then
            if player:getPhase()==sgs.Player_Play then
                for _,p in sgs.list(room:getOtherPlayers(player))do
                    if p:hasSkill(self) then 
                        local choicelist = {"slash"}
                        if p:inMyAttackRange(player) then
                            table.insert(choicelist, "draw")
                            table.insert(choicelist, "bieshui")
                        end
                        table.insert(choicelist, "cancel")
                        local choice = room:askForChoice(p, self:objectName(), table.concat(choicelist, "+"), ToData(player))
                        if choice == "bieshui" then
                            room:loseMaxHp(p)
                        end
                        if choice == "draw" or choice == "bieshui" then
                            p:peiyin(self)
                            p:drawCards(1,self:objectName())
                            local dc = dummyCard()
                            dc:setSkillName("_s4_jiezhan")
                            if player:canSlash(p,dc,false) then
                                room:useCard(sgs.CardUseStruct(dc,player,p),true)
                            end
                        end
                        if choice == "slash" or choice == "bieshui" then
                            local dc = room:askForUseSlashTo(p,player,"@s4_jiezhan:"..player:objectName(), false, false, false, nil, nil, "s4_jiezhan")
                        end
                    end
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("s4_jiezhan") and player:objectName() == damage.from:objectName() then
                local choicelist = {"damage"}
                if not damage.to:isNude() then
                    table.insert(choicelist, "obtain")
                end
                room:setTag("s4_jiezhan", data)
                local choice = room:askForChoice(player, self:objectName(), table.concat(choicelist, "+"), ToData(damage.to))
                room:removeTag("s4_jiezhan")
                if choice == "damage" then
                    damage.damage = damage.damage + 1
                    local log = sgs.LogMessage()
                    log.type = "#skill_add_damage"
                    log.from = damage.from
                    log.to:append(damage.to)
                    log.arg  = self:objectName()
                    log.arg2 = damage.damage
                    room:sendLog(log)
                    data:setValue(data)
                else
                    local card = room:askForCardChosen(player, damage.to, "he", self:objectName())
                    room:obtainCard(player, card, false)
                end
            end
		end
		return false
	end
}
s4_huanzhaoyun:addSkill(s4_longxin)
s4_huanzhaoyun:addSkill(s4_jiezhan)



sgs.LoadTranslationTable {
    ["s4_huanzhaoyun"] = "幻赵云",
    ["&s4_huanzhaoyun"] = "幻赵云",
    ["#s4_huanzhaoyun"] = "灭武耆龙",
    ["~s4_huanzhaoyun"] = "",
    ["designer:s4_huanzhaoyun"] = "终极植物",
    ["cv:s4_huanzhaoyun"] = "",
    ["illustrator:s4_huanzhaoyun"] = "",

    ["s4_longxin"] = "龙心",
    [":s4_longxin"] = "若你没有受伤，你可以将一张【杀】当【闪】或一张【闪】当【杀】使用或打出，若如此做，你可以获得对方的一张手牌。",

    ["s4_jiezhan:damage"] = "你令此伤害+1",
    ["s4_jiezhan:obtain"] = "你获得其一张牌",
    ["s4_jiezhan:draw"] = "你摸一张牌，然后其视为对你使用一张计入次数限制的【杀】",
    ["s4_jiezhan:slash"] = "你可以对其使用一张无距离限制的【杀】",
    ["s4_jiezhan"] = "竭战",
    [":s4_jiezhan"] = "其他角色的出牌阶段开始时，你可以选择一项：1.你摸一张牌，然后其视为对你使用一张计入次数限制的【杀】；2.你可以对其使用一张无距离限制的【杀】，此【杀】对其造成伤害时，你令此伤害+1或获得其一张牌；背水：你减1点体力上限。",
    ["@s4_jiezhan"] = "你可以发动“竭战”对 %src 使用一张【杀】",

}

--https://tieba.baidu.com/p/9183378404?pid=150962307870&cid=#150962307870

s4_zujiangwei = sgs.General(extension, "s4_zujiangwei", "shu", 4)

s4_daoli = sgs.CreateTriggerSkill{
	name = "s4_daoli",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Judge then
                room:sendCompulsoryTriggerLog(player,self)
                change.to = sgs.Player_Play
                data:setValue(change)
                room:addPlayerMark(player, "s4_daoli-Clear")
                room:addPlayerMark(player, "&s4_daoli-PlayClear")
            end
            if player:getMark("s4_daoliNoDmg-Clear") > 0 then
                room:setPlayerMark(player, "s4_daoliNoDmg-Clear", 0)
                room:sendCompulsoryTriggerLog(player,self)
                change.to = sgs.Player_Play
                data:setValue(change)
            end
        elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and player:getMark("s4_daoli-Clear") > 0 then
            room:setPlayerMark(player, "s4_daoli-Clear",0)
            if player:getMark("damage_point_play_phase") == 0 then
                room:sendCompulsoryTriggerLog(player,self)
                room:loseHp(player, 1, true, player, self:objectName())
                player:drawCards(2, self:objectName())
                if player:getMark("s4_daoliUsing-Clear") == 0 then
                    room:setPlayerMark(player, "s4_daoliUsing-Clear", 1)
                    room:setPlayerMark(player, "s4_daoliNoDmg-Clear", 1)
                end
            end
        end
	end,
}
s4_xingguRecord = sgs.CreateTriggerSkill{
    name = "#s4_xingguRecord",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.from == sgs.Player_Play then
                local card = room:getTag("s4_xinggu")
                if card then
                    room:removeTag("s4_xinggu")
                end
            end
        else
            local current = room:getCurrent()
            if current and current:hasSkill("s4_xinggu") then
                local use = data:toCardUse()
                if use.card and not use.card:isKindOf("SkillCard") then
                    if use.card:isVirtualCard() then
                        if use.card:subcardsLength() > 0 then
                        else
                            room:removeTag("s4_xinggu")
                        end
                    end
                    room:setTag("s4_xinggu", ToData(use.card))
                    for _, mark in sgs.list(current:getMarkNames()) do
						if string.find(mark, "s4_xinggu") and current:getMark(mark) > 0 then
							room:setPlayerMark(current, mark, 0)
						end
					end
					room:setPlayerMark(current, "&s4_xinggu+:+" .. use.card:objectName() .. "-".. current:getPhase() .."Clear", 1)
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target ~= nil
    end,
}
s4_xinggu = sgs.CreateTriggerSkill{
	name = "s4_xinggu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
            room:sendCompulsoryTriggerLog(player,self)
            local card = room:getTag("s4_xinggu"):toCard()
            room:removeTag("s4_xinggu")
            if card then
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                dummy:deleteLater()
                for _,id in sgs.qlist(card:getSubcards()) do
                    if room:getCardPlace(id) == sgs.Player_DiscardPile then
                        dummy:addSubcard(sgs.Sanguosha:getCard(id))
                    end
                end
                if dummy:subcardsLength() > 0 then
                    local targets = sgs.SPlayerList()
                    targets:append(player)
                    local target = room:askForPlayerChosen(player,targets,self:objectName(),"s4_xinggu-invoke",true,true)
                    if not target then player:drawCards(1, self:objectName()) return false end
                    room:obtainCard(target, dummy, true)
                else
                    player:drawCards(1, self:objectName())
                end
            else
                player:drawCards(1, self:objectName())
            end
        end
	end,
}
s4_zujiangwei:addSkill(s4_daoli)
s4_zujiangwei:addSkill(s4_xinggu)
s4_zujiangwei:addSkill(s4_xingguRecord)
extension:insertRelatedSkills("s4_xinggu","#s4_xingguRecord")
sgs.LoadTranslationTable {
    ["s4_zujiangwei"] = "族姜维",
    ["&s4_zujiangwei"] = "族姜维",
    ["#s4_zujiangwei"] = "劬劳之师",
    ["~s4_zujiangwei"] = "",
    ["designer:s4_zujiangwei"] = "弦惊⊙∀⊙",
    ["cv:s4_zujiangwei"] = "",
    ["illustrator:s4_zujiangwei"] = "",

    ["s4_daoli"] = "蹈砺",
    [":s4_daoli"] = "锁定技，你的判定阶段改为出牌阶段，若此阶段你未造成伤害，你失去一点体力并摸兩张牌，然后将本回合下一个阶段改为出牌阶段。",

    ["s4_xinggu-invoke"] = "你可以发动“星孤”<br/> <b>操作提示</b>: 选择一名同族角色→点击确定<br/>",
    ["s4_xinggu"] = "星孤",
    [":s4_xinggu"] = "宗族技，锁定技，出牌阶段结束时，你令一名同族角色获得此阶段被使用的最后一张牌或摸一张牌。",

}
--https://tieba.baidu.com/p/9517174830


s4_hansimayi = sgs.General(extension, "s4_hansimayi", "shu", 3)


s4_jianghulimit = sgs.CreateProhibitSkill{
    name = "#s4_jianghulimit",
    is_prohibited = function(self, from, to, card)
        if table.contains(card:getSkillNames(), "s4_jianghu") and not to:hasFlag("s4_jianghu") then
            return true
        end
        return false
    end,
}
s4_jianghuCard = sgs.CreateSkillCard {
	name = "s4_jianghu",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	target_fixed = true,
	mute = true,
	on_use = function(self, room, source, targets)
        local choices = {}
        local target
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasFlag("s4_jianghu") then
                target = p
                break
            end
        end
        if not target then return end
		for _, cd in ipairs(patterns()) do
			local card = sgs.Sanguosha:cloneCard(cd, sgs.Card_NoSuit, 0)
			if card and card:isNDTrick() then
				card:deleteLater()
				if card:isAvailable(source) and not table.contains(choices, cd) and CanToCard(card,source,target) then
					table.insert(choices, cd)
				end
			end
		end
		if #choices<1 then return end
		local pattern = room:askForChoice(source, "s4_jianghu", table.concat(choices, "+"), ToData(target))
		if pattern then
            local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
			if card then
				card:deleteLater()
            end
            room:setPlayerProperty(source, "s4_jianghu", sgs.QVariant(card:objectName()))
			room:askForUseCard(source,"@@jianghuUsing","@s4_jianghuUsing:"..card:objectName())
		end
	end,
}
s4_jianghuVS = sgs.CreateViewAsSkill{
	name = "s4_jianghu",
	n = 0,
	view_as = function(self,cards)
		if #cards~=0 then return end
		if sgs.Sanguosha:getCurrentCardUsePattern()=="@@jianghuUsing" then
			local pattern = sgs.Self:property("s4_jianghu"):toString()
            local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1) 
			card:setSkillName("s4_jianghu")
			return card
        else
            return s4_jianghuCard:clone()
		end
		
	end,
	enabled_at_play = function(self,player)
		return false
	end,
    enabled_at_response = function(self,player,pattern)
		return string.find(pattern,"jianghu") or pattern:startsWith("@@jianghu")
	end,
}
s4_jianghu = sgs.CreateTriggerSkill{
    name = "s4_jianghu",
    events = {sgs.Damage,sgs.Damaged},
    view_as_skill = s4_jianghuVS,
    --guhuo_type = "lr",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local target
        local damage = data:toDamage()
        if event == sgs.Damage then
            if damage.to and damage.to:isAlive() and not damage.to:isNude() then
                target = damage.to
            end
        end
        if event == sgs.Damaged then
            if damage.from and damage.from:isAlive() and not player:isNude() then
                target = damage.from
            end
        end
        if damage.from and damage.from:objectName() == damage.to:objectName() then return false end
        if player:getMark("s4_jianghu-Clear") > 0 then return false end
        if target and room:askForSkillInvoke(player, self:objectName(), data) then
            room:addPlayerMark(player, "s4_jianghu-Clear")
            room:addPlayerMark(player, "&s4_jianghu-Clear")
            room:broadcastSkillInvoke(self:objectName())
            if event == sgs.Damage then
                local card = room:askForCardChosen(player, target, "he", self:objectName())
                room:obtainCard(player, card, false)
                room:setPlayerFlag(player, self:objectName())
            elseif event == sgs.Damaged then
                room:setPlayerFlag(target, self:objectName())
                local card = room:askForExchange(player, "s4_jianghu", 1, 1, true, "@s4_jianghu-give:"..target:getGeneralName(), false)
                if card then
                    room:obtainCard(target, card, false)
                end
            end
            local choices = {}
            for _, cd in ipairs(patterns()) do
                local card = sgs.Sanguosha:cloneCard(cd, sgs.Card_NoSuit, 0)
                if card and card:isNDTrick() then
                    card:deleteLater()
                    if card:isAvailable(player) and not table.contains(choices, cd) and CanToCard(card,player,target) then
                        table.insert(choices, cd)
                    end
                end
            end
            if #choices<1 then return end
            room:setTag("s4_jianghu_cards", sgs.QVariant(table.concat(choices, "+")))
            room:askForUseCard(player, "@@jianghu", "@s4_jianghu")
            room:setPlayerFlag(player, "-"..self:objectName())
            room:setPlayerFlag(target, "-"..self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
        and target:isAlive()
    end,
}

s4_zuolong = sgs.CreateTriggerSkill{
    name = "s4_zuolong",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if not (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then return false end
        if player:isDead() then return false end
        local targets = sgs.SPlayerList()
        local useto = use.to
        for _,to in sgs.qlist(use.to) do
            if not to:isAlive() then
                useto:removeOne(to)
            end
        end
        if useto:isEmpty() then return false end
        
        for _,p in sgs.qlist(room:getOtherPlayers(player)) do
            for _,to in sgs.qlist(useto) do
                if not p:isCardLimited(use.card, sgs.Card_MethodUse) and not p:isProhibited(to, use.card) then
                    targets:append(p)
                    break
                end
            end
        end
        if targets:isEmpty() then return false end
        room:setTag("s4_zuolong", data)
        local target = room:askForPlayerChosen(player, targets, self:objectName(), "@s4_zuolong:"..use.card:objectName(), true, true)
        room:removeTag("s4_zuolong")
        if not target then return end
        room:broadcastSkillInvoke(self:objectName())
        room:useCard(sgs.CardUseStruct(use.card, target, useto))
    end,
}

s4_hansimayi:addSkill(s4_jianghulimit)
s4_hansimayi:addSkill(s4_jianghu)
extension:insertRelatedSkills("s4_jianghu", "#s4_jianghulimit")
s4_hansimayi:addSkill(s4_zuolong)
--https://tieba.baidu.com/p/9491705552
sgs.LoadTranslationTable {
    ["s4_hansimayi"] = "司马懿",
    ["&s4_hansimayi"] = "司马懿",
    ["#s4_hansimayi"] = "末炎助焰",
    ["~s4_hansimayi"] = "",
    ["designer:s4_hansimayi"] = "亚当（吾日三省吾身）",
    ["cv:s4_hansimayi"] = "",
    ["illustrator:s4_hansimayi"] = "",
    ["information:s4_hansimayi"] = "建兴十二年秋·汉水北岸\
    夜露凝在司马懿的甲胄上，渭水涛声在十里外的黑暗中轰鸣。他握着那卷浸透血渍的密信，指节泛白——洛阳昨夜的血月，终究还是照进了祁山大营。\
    大将军！斥候撞开帐门时带进一股腥风，武卫营哗变！二公子...二公子被乱箭射死在永宁宫阶前！\
    铜雀灯台上的火苗突然爆出青焰，映得司马懿半边脸如同青铜面具。案头那方镇纸玉虎裂开细纹，这是他上月特意命人从河内送来的。\
    “曹氏一族，终究还是下手了么…吾等，又该何去何从？”司马懿那儿近乎昏暗的双眼微微合上，在心中盘算着最坏的打算。\
    “父亲…孩儿有一计。”司马师的声音在身旁响起，司马懿睁开双眼，望了过去。“也许，我们可以…”\
    ……\
    帐外忽起喧哗，亲卫统领焦灼的声音刺破雨幕：“丞相！不可...”话音未落，数盏气死风灯已挑开帐帘。诸葛亮素衣纶巾，手握朱雀羽扇。\
    “仲达来此何意？”诸葛亮的嗓音比渭水寒冰更冷，“你我皆为敌人，如今大战在即，你这次突然到访，怕是没安什么好心吧？”\
    司马懿霍然起身，腰间环首刀锵然出鞘三寸。帐外三百陌刀卫的甲叶声如骤雨初歇，二十张诸葛连弩的机括声却似寒蝉振翅。\
    “孔明好手段。”他忽然低笑，跪了下来，“我已无路可去，不得出此下策，还望孔明放下往日之恩怨，老夫任由处置。”\
    诸葛亮羽扇轻摇，帐中烛火竟齐齐转向西北。司马懿瞳孔微缩——那是长安的方向。\
    “我已知晓，你跟我来吧。”诸葛亮开口道，“我会收留你们的，希望你们，不要辜负了我的心意。”\
    “是…”\
    “我蜀汉之舟，未必不能载得动两条蛟龙。古人有云：蛟龙入海方显本色。”诸葛亮将羽扇轻轻放在案上，“仲达可曾见过汉水的虹鳟？每逢惊蛰，必逆流而上，纵使鳞甲尽褪亦不回头。”\
    帐外忽有流星划过天际，将司马懿的影子拉得老长。他想起二十年前许昌城头，自己与杨修对弈时说过的话：这乱世如棋，执黑执白皆是劫。\
    三更梆响时，渭北魏营燃起冲天火光。司马懿单骑渡河，身后跟着司马师青自率领的三千名死士。诸葛亮立在五丈原观星台上，看着对岸渐次熄灭的营火，忽然剧烈咳嗽起来。\
    姜维急欲搀扶，却被羽扇拦住。“伯约，速去准备西城粮仓的钥匙。”诸葛亮望着汉水对岸新起的蜀字旌旗，“司马仲达要的，可不是空头大将军印。”\
    ……\
    晨雾中，两匹白马并辔而行。司马懿摩挲着新制的蜀锦战袍，忽道：“孔明知我要什么？”\
    “八百里秦川。”诸葛亮扬鞭指向前方若隐若现的秦岭，“还有...青史丹书。”\
    两人相视而笑，惊起一群白鹭。汉水在他们脚下奔涌，冲碎了倒映多年的残月。”",

    ["@s4_jianghuUsing"] = "降虎：<b>你视为使用【%src】",
    ["@s4_jianghu"] = "降虎：<b>你可以视为对自己使用一张普通锦囊牌",
    ["@s4_jianghu-give"] = "降虎：<b>你可以交给 %src 一张牌并视为对其使用一张普通锦囊牌",
    ["s4_jianghu"] = "降虎",
    [":s4_jianghu"] = "每回合限一次，当你对其他角色造成/受到其他角色造成的伤害后，你可以获得其/交给其一张牌并视为对自己/其使用一张普通锦囊牌。",

    ["s4_zuolong"] = "佐龙",
    [":s4_zuolong"] = "你使用的基本牌或普通锦囊牌结算后，你可以令一名其他角色视为对相同角色使用此牌。",
    ["@s4_zuolong"] = "你可以令一名其他角色视为对相同角色使用【%src】",

}
--[[
s4_caopi = sgs.General(extension, "s4_caopi", "wei", 3)

s4_xingshang_buff = sgs.CreateTriggerSkill{
	name = "#s4_xingshang_buff",
	events = {sgs.EventForDiy},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventForDiy) then
			local str = data:toString()
			if str:startsWith("askyishicard:") then
                local tid = player:getMark("s4_xingshang")
                if tid<1 then return end
                tid = tid-1
                data:setValue(str..":"..tid)
			end
		end
	end ,
}
s4_xingshang = sgs.CreateTriggerSkill{
    name = "s4_xingshang",
    events = {sgs.Damaged, sgs.Death},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who:objectName() == player:objectName() then return false end
        end
        if not player:isKongcheng() and room:askForSkillInvoke(player, self:objectName(), data) then
            local card = room:askForCardShow(player, player, "s4_xingshang")
            room:showCard(player, card:getEffectiveId())
            room:setPlayerMark(player, "s4_xingshang",card:getEffectiveId()+1)
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player))do
                if not p:isKongcheng() then
                    targets:append(p)
                end
            end
            if targets:isEmpty() then return false end
            local selected = room:askForPlayersChosen(player, targets,
                        self:objectName(), 0, 999, "@s4_xingshang", true, true)
            local ys = {}
            ys.reason = self:objectName()
            ys.from = player
            ys.tos = {player}
            if selected and (not selected:isEmpty()) then
                for _,target in sgs.qlist(selected) do
                    table.insert(ys.tos,target)
                end
            end
            ys.effect = function(ys_data)
                if (ys_data.result == card:getColorString()) then
                    local x = 0
                    for i,pn in sgs.list(ys_data.tos)do
                        if ys_data.to2color[pn]:match(card:getColorString()) then
                            x = x + 1
                        end
                    end
                    player:drawCards(x, self:objectName())
                end
            end
            askYishi(ys)
            room:setPlayerMark(player, "s4_xingshang",0)
        end
    end,
}

s4_fangzhu = sgs.CreateTriggerSkill{
	name = "s4_fangzhu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventForDiy},
	can_trigger = function(self,target)
		return target~=nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.EventForDiy) then
			local ys = data:toString()
			if ys:startsWith("yishiresult:") then
				local sts = ys:split(":")
				local tos = sts[4]:split("+")
				local ids = sts[5]:split("+")
				for i,pn in sgs.list(tos) do
					local to = room:findPlayerByObjectName(pn)
					if to:isAlive() and to:hasSkill(self) then
                        room:writeToConsole("ids[i]"..ids[i])
                        local colors1 = {}
                        if string.find(ids[i], "$") then

                        end
						if type(ids[i])=="userdata" then
                            for _,id in sgs.list(ids[i]:getSubcards())do
                                local cs = sgs.Sanguosha:getCard(id):getColorString()
                                room:writeToConsole("colors1CS"..cs)
                                table.insert(colors1,cs)
                            end
                        end
						local players = sgs.SPlayerList()
						for n,qn in sgs.list(tos) do
							local q = room:findPlayerByObjectName(qn)
							local colors2 = {}
                            room:writeToConsole("ids[n]"..ids[n])
							if type(ids[n])=="userdata" then
                                for _,id in sgs.list(ids[n]:getSubcards())do
                                    local cs = sgs.Sanguosha:getCard(id):getColorString()
                                    table.insert(colors2,cs)
                                    room:writeToConsole("colors2CS"..cs)
                                end
                            end
                            room:writeToConsole("colors2"..table.concat(colors2, "+"))
							if q:isAlive() then
                                for _,c in ipairs(colors1) do
                                    if not table.contains(colors2, c) then
                                        room:writeToConsole("colors2C"..c)
                                        players:append(q) 
                                        break
                                    end
                                end
                            end
						end
                        room:writeToConsole("colors1"..table.concat(colors1, "+"))
                        if not players:isEmpty() then
                            local target = room:askForPlayerChosen(to, players, self:objectName(), "s4_fangzhu-invoke", true, true)
                            if target then
                                room:broadcastSkillInvoke(self:objectName())
                                target:turnOver()
                            end
                        end
					end
				end
			end
		end
	end,
}


s4_songwei = sgs.CreateTriggerSkill{
	name = "s4_songwei$",
	events = {sgs.EventForDiy},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target~=nil
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        local str = data:toString()
        if str:startsWith("yishiresult:") then
            local strs = str:split(":")
            for _, pn in sgs.list(strs[4]:split("+"))do
                local p = room:findPlayerByObjectName(pn)
                local id = p:getMark("s4_songweiTid")
                if id>0 then
                    local cs = sgs.CardList()
                    cs:append(sgs.Sanguosha:getCard(id-1))
                    room:filterCards(p,cs,true)
                    p:setMark("s4_songweiTid",0)
                end
                p:setMark("s4_songweiFid",0)
                if p:hasFlag("s4_songwei_lose") then
                    room:setPlayerFlag(p, "-s4_songwei_lose")
                    room:loseHp(p, 1)
                end
            end
        elseif str:startsWith("askyishicard:") then
            local strs = str:split(":")
            local players = sgs.SPlayerList()
            local can_invoke = false
            local dest
            for _, pn in sgs.list(strs[4]:split("+"))do
                local p = room:findPlayerByObjectName(pn)
                if p then
                    players:append(p)
                    if p:getMark("s4_songweiFid") > 0 then
                        can_invoke = true
                        dest = p
                    end
                end
            end
            if not players:isEmpty() and ((can_invoke and dest) or player:hasLordSkill(self)) then
                room:sortByActionOrder(players)
                if player:objectName() == players:last():objectName() then
                    if #strs<5 then
                        local dc = room:askForExchange(player, strs[2].."_yishi", 1, 1, false, "askyishicard")
                        table.insert(strs,dc:getEffectiveId())
                    end
                    if player:hasLordSkill(self) and not dest then
                        dest = player
                        player:setMark("s4_songweiFid",strs[5]+1)
                    end
                    if dest then
                        dest:gainMark("@1")
                        local fid = dest:getMark("s4_songweiFid")
                        if fid<1 then return false end
                        fid = fid-1
                        local c = sgs.Sanguosha:getCard(fid)
                        room:sendCompulsoryTriggerLog(dest,self)
                        local targets = sgs.SPlayerList()
                        local wei = room:getLieges("wei",dest)
                        for _, p in sgs.qlist(wei)do
                            if table.contains(strs[4]:split("+"),p:objectName())  then
                                local tid = p:getMark("s4_songweiTid")
                                if tid<1 then continue end
                                tid = tid-1
                                local wc = sgs.Sanguosha:getWrappedCard(tid)
                                wc:setSkillName(self:objectName())
                                if wc:getColor() ~= c:getColor() then
                                    targets:append(p)
                                end
                            end
                        end
                        local selected = room:askForPlayersChosen(dest, targets,
                        self:objectName(), 0, 999, "@s4_songwei", true, true)
                        if selected and (not selected:isEmpty()) then
                            for _,target in sgs.qlist(selected) do
                                local tid = target:getMark("s4_songweiTid")
                                if tid<1 then room:setPlayerFlag(target, "s4_songwei_lose") continue end
                                tid = tid-1
                                local wc = sgs.Sanguosha:getWrappedCard(tid)
                                wc:setSkillName(self:objectName())
                                if room:askForSkillInvoke(target, self:objectName(), data) then
                                    wc:setSuit(c:getSuit())
                                else
                                    room:setPlayerFlag(target, "s4_songwei_lose")
                                end
                                room:broadcastUpdateCard(room:getPlayers(),tid,wc)
                            end
                        end
                    end
                else
                    if player:hasLordSkill(self) then
                        if #strs<5 then
                            local dc = room:askForExchange(player, strs[2].."_yishi", 1, 1, false, "askyishicard")
                            table.insert(strs,dc:getEffectiveId())
                        end
                        player:setMark("s4_songweiFid",strs[5]+1)
                    end
                end
            end
            
            for _, p in sgs.qlist(room:getAllPlayers())do
                if p:hasLordSkill(self) and table.contains(strs[4]:split("+"),p:objectName())
                and player:getKingdom() == "wei" then
                    if #strs<5 then
                        local dc = room:askForExchange(player, strs[2].."_yishi", 1, 1, false, "askyishicard")
                        table.insert(strs,dc:getEffectiveId())
                    end
                    player:setMark("s4_songweiTid",strs[5]+1)
                end
            end
            data:setValue(table.concat(strs,":"))
        end
	end	
}

s4_caopi:addSkill(s4_xingshang_buff)
s4_caopi:addSkill(s4_xingshang)
extension:insertRelatedSkills("s4_xingshang", "#s4_xingshang_buff")
s4_caopi:addSkill(s4_fangzhu)
-- s4_caopi:addSkill(s4_songwei)

--https://tieba.baidu.com/p/9248983668?pn=1
sgs.LoadTranslationTable {
    ["s4_caopi"] = "曹丕",
    ["&s4_caopi"] = "曹丕",
    ["#s4_caopi"] = "魏文帝",
    ["~s4_caopi"] = "",
    ["designer:s4_caopi"] = "TwinkleYellow",
    ["cv:s4_caopi"] = "",
    ["illustrator:s4_caopi"] = "",

    ["@s4_xingshang"] = "行殇：你可以与任意名其他角色议事",
    ["s4_xingshang"] = "行殇",
    [":s4_xingshang"] = "当其他角色死亡后或当你受到伤害后，你可以展示一张手牌并用此牌与任意名其他角色议事，若结果与你意见相同，你摸X张牌（X为意见与你相同的角色数）。",
    ["s4_fangzhu"] = "放逐",
    [":s4_fangzhu"] = "当你参与议事结束后，你可以令一名意见与你不同的角色翻面。",
    ["s4_fangzhu-invoke"] = "你可以发动“放逐”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
    ["s4_songwei"] = "颂威",
    [":s4_songwei"] = "主公技，当你参与议事结果确定前，你可以令任意名意见与你不同的魏势力角色选择一项：1.修改意见视为与你相同；2.于议事结束后失去1点体力。",

}
]]

s4_yuanshao = sgs.General(extension, "s4_yuanshao", "qun", 4)

s4_mingmen_cardmax = sgs.CreateMaxCardsSkill{
    name = "#s4_mingmen_cardmax",
    extra_func = function(self, target)
        if target:hasSkill("s4_mingmen") and target:getMark("TurnLengthCount") < 5 then
            return (4 - target:getMark("TurnLengthCount"))
        else
            return 0
        end
    end
}
s4_mingmen = sgs.CreateTriggerSkill{
    name = "s4_mingmen",
    events = {sgs.DrawNCards},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DrawNCards then
            local draw = data:toDraw()
            if draw.reason ~= "draw_phase" then return false end
            local x = room:getTag("TurnLengthCount"):toInt()
            if x < 5 then
                room:sendCompulsoryTriggerLog(player, self:objectName())
                draw.num = draw.num + 4 - x
                data:setValue(draw)
            end
        end
    end,
}



s4_zhaotaoUse = sgs.CreateViewAsSkill{
    name = "s4_zhaotaoUse",
    n = 1,
    response_pattern = "@@s4_zhaotao",
    view_filter = function(self, selected, to_select)
        return sgs.Self:getHandcards():contains(to_select) and #selected < 1
    end,
    view_as = function(self, cards)
        if #cards == 0 then return nil end
        local card_id = sgs.Self:getMark("s4_zhaotao")
		local card = sgs.Sanguosha:getCard(card_id)
        local acard = cards[1]
        local new_card = sgs.Sanguosha:cloneCard(card:objectName(), acard:getSuit(), acard:getNumber())
        new_card:setSkillName(self:objectName())
        return new_card
    end,
    enabled_at_play = function(self, player)
        return false
    end
}
s4_zhaotao = sgs.CreateTriggerSkill{
    name = "s4_zhaotao",
    events = {sgs.CardFinished, sgs.EnterDying},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if not use.card:isNDTrick() then return false end
            if use.to:length() ~= 1 then return false end
            if player:isDead() then return false end
            if player:hasSkill(self:objectName()) and player:getMark("s4_zhaotaoUse") == 0 then
                room:setTag("s4_zhaotao", data)
                local targets = room:askForPlayersChosen(player,room:getOtherPlayers(player),self:objectName(),0,99,"@s4_zhaotao_target:"..use.card:objectName(), true, true)
                if targets and targets:length() > 0 then
                    room:setPlayerMark(player,"s4_zhaotaoUse",1)
                    room:setPlayerMark(player,"&s4_zhaotao",1)
                    for _,p in sgs.qlist(targets)do
                        local card_id = use.card:getEffectiveId()
					    room:setPlayerMark(p, "s4_zhaotao", card_id)
                        room:askForUseCard(p, "@@s4_zhaotao", "@s4_zhaotao:"..use.card:objectName())
                        room:setPlayerMark(p, "s4_zhaotao", 0)
                    end
                end
                room:removeTag("s4_zhaotao")
            end
        else
            local dying = data:toDying()
            if dying.who and dying.who:isLord() then return false end
            for _, p in sgs.qlist(room:findPlayersBySkillName("s4_zhaotao")) do
                if p:getMark("s4_zhaotaoUse") > 0 then
                    room:setPlayerMark(p,"s4_zhaotaoUse",0)
                    room:setPlayerMark(p,"&s4_zhaotao",0)
                end
            end
        end

    end,
    can_trigger = function(self, target)
        return target and target:isAlive()
    end,
}



s4_yuanshao:addSkill(s4_mingmen_cardmax)
s4_yuanshao:addSkill(s4_mingmen)
s4_yuanshao:addSkill(s4_zhaotao)
if not sgs.Sanguosha:getSkill("s4_zhaotaoUse") then  s4_skillList:append(s4_zhaotaoUse) end


extension:insertRelatedSkills("s4_mingmen", "#s4_mingmen_cardmax")

--https://tieba.baidu.com/p/9000876226?pid=150208550065&cid=0#150208550065
sgs.LoadTranslationTable {
    ["s4_yuanshao"] = "袁绍",
    ["&s4_yuanshao"] = "袁绍",
    ["#s4_yuanshao"] = "举剑讨董",
    ["~s4_yuanshao"] = "",
    ["designer:s4_yuanshao"] = "不知道叫什么™",
    ["cv:s4_yuanshao"] = "",
    ["illustrator:s4_yuanshao"] = "",

    ["s4_mingmen"] = "名门",
    [":s4_mingmen"] = "锁定技，游戏前四轮，你手牌上限加5-x，摸牌阶段摸牌数加4-x。 （x为游戏轮数）",
    ["@s4_zhaotao"] = "召讨：你可以将一张手牌当作【%src】使用",
    ["@s4_zhaotao_target"] = "召讨：你可以选择任意名其他角色，令其将一张手牌当作【%src】使用",
    ["s4_zhaotao"] = "召讨",
    [":s4_zhaotao"] = "昂扬技，当你使用单目标普通锦囊牌结算后，你可选择任意名其他角色，其可将一张手牌当作你使用的牌使用。激昂：一名非主公角色进入濒死。",

}

s4_wuhu = sgs.General(extension, "s4_wuhu", "shu", 5)
s4_wuhu_guanyu = sgs.General(extension, "s4_wuhu_guanyu", "shu", 1, true, true)
s4_wuhu_zhangfei = sgs.General(extension, "s4_wuhu_zhangfei", "shu", 1, true, true)
s4_wuhu_machao = sgs.General(extension, "s4_wuhu_machao", "shu", 1, true, true)
s4_wuhu_huangzhong = sgs.General(extension, "s4_wuhu_huangzhong", "shu", 1, true, true)
s4_wuhu_zhaoyun = sgs.General(extension, "s4_wuhu_zhaoyun", "shu", 1, true, true)


s4_baijiang = sgs.CreateTriggerSkill {
	name = "s4_baijiang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.EventPhaseChanging, sgs.GameStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        local huashenss = {"s4_wuhu_guanyu", "s4_wuhu_zhangfei", "s4_wuhu_machao", "s4_wuhu_huangzhong", "s4_wuhu_zhaoyun"}
        if (event == sgs.GameStart) then
			if player:hasSkill(self:objectName()) then
               local hidden = {}
                for i = 1,5,1 do
                    table.insert(hidden,"unknown")
                end
                for _,p in sgs.qlist(room:getAllPlayers())do
                    local splist = sgs.SPlayerList()
                    splist:append(p)
                    if p:objectName() == player:objectName() then
                        room:doAnimate(4, player:objectName(), table.concat(huashenss,":"), splist)
                    else
                        room:doAnimate(4, player:objectName(),table.concat(hidden,":"),splist);
                    end
                end
                huashenss = RandomList(huashenss)
                local choose_general = { huashenss[1], huashenss[2] }
				local general = room:askForGeneral(player, table.concat(choose_general, "+"))
                player:setTag("s4_baijiang_general",sgs.QVariant(general))
                table.removeOne(choose_general, general)
                general = sgs.Sanguosha:getGeneral(general)
                local skill_names = {}
		        local skill_name
                assert(general)
                for _,skill in sgs.qlist(general:getVisibleSkillList())do
                    if skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
                        continue
                    end
                    if not table.contains(skill_names,skill:objectName()) then
                        table.insert(skill_names,skill:objectName())
                    end
                end
                if #skill_names > 0 then
                    skill_name = room:askForChoice(player, "s4_baijiang",table.concat(skill_names,"+"))
                end
                
                if skill_name ~= "" then
                    room:changeTranslation(player, skill_name)
                    room:handleAcquireDetachSkills(player, skill_name, true)
                end
				local general2 = room:askForGeneral(player, table.concat(choose_general, "+"))
                player:setTag("s4_baijiang_general2",sgs.QVariant(general2))
                general = sgs.Sanguosha:getGeneral(general2)
                local skill_names = {}
		        local skill_name
                assert(general)
                for _,skill in sgs.qlist(general:getVisibleSkillList())do
                    if skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
                        continue
                    end
                    if not table.contains(skill_names,skill:objectName()) then
                        table.insert(skill_names,skill:objectName())
                    end
                end
                if #skill_names > 0 then
                    skill_name = room:askForChoice(player, "s4_baijiang",table.concat(skill_names,"+"))
                    if skill_name ~= "" then
                        room:changeTranslation(player, skill_name, 2)
                        room:handleAcquireDetachSkills(player, skill_name, true)
                    end
                end
			end
		end
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) or change.from == sgs.Player_NotActive then
                local general = player:getTag("s4_baijiang_general"):toString()
                local general2 = player:getTag("s4_baijiang_general2"):toString()
                table.removeOne(huashenss, general)
                table.removeOne(huashenss, general2)
                local skill_names = {}
                general = sgs.Sanguosha:getGeneral(general)
                for _,skill in sgs.qlist(general:getVisibleSkillList())do
                    if skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
                        continue
                    end
                    if not table.contains(skill_names,skill:objectName()) then
                        table.insert(skill_names,skill:objectName())
                    end
                end
                general2 = sgs.Sanguosha:getGeneral(general2)
                for _,skill in sgs.qlist(general2:getVisibleSkillList())do
                    if skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
                        continue
                    end
                    if not table.contains(skill_names,skill:objectName()) then
                        table.insert(skill_names,skill:objectName())
                    end
                end
                
                room:handleAcquireDetachSkills(player, "-"..table.concat(skill_names, "|-"))
                huashenss = RandomList(huashenss)
                local choose_general = { huashenss[1], huashenss[2] }

                local general = room:askForGeneral(player, table.concat(choose_general, "+"))
                player:setTag("s4_baijiang_general",sgs.QVariant(general))
                table.removeOne(choose_general, general)
				general = sgs.Sanguosha:getGeneral(general)
                local skill_names = {}
		        local skill_name
                assert(general)
                for _,skill in sgs.qlist(general:getVisibleSkillList())do
                    if skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
                        continue
                    end
                    if not table.contains(skill_names,skill:objectName()) then
                        table.insert(skill_names,skill:objectName())
                    end
                end
                if #skill_names > 0 then
                    skill_name = room:askForChoice(player, "s4_baijiang",table.concat(skill_names,"+"))
                end
                
                
                if skill_name ~= "" then
                    room:handleAcquireDetachSkills(player, skill_name, true)
                end

                local general2 = room:askForGeneral(player, table.concat(choose_general, "+"))
                player:setTag("s4_baijiang_general2",sgs.QVariant(general2))
				general2 = sgs.Sanguosha:getGeneral(general2)
                local skill_names = {}
		        local skill_name
                assert(general2)
                for _,skill in sgs.qlist(general2:getVisibleSkillList())do
                    if skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
                        continue
                    end
                    if not table.contains(skill_names,skill:objectName()) then
                        table.insert(skill_names,skill:objectName())
                    end
                end
                if #skill_names > 0 then
                    skill_name = room:askForChoice(player, "s4_baijiang",table.concat(skill_names,"+"))
                end
                
                
                if skill_name ~= "" then
                    room:handleAcquireDetachSkills(player, skill_name, true)
                end
			end
		end
	end,
}


s4_wuhu_wushengVS = sgs.CreateViewAsSkill{
    name = "s4_wuhu_wusheng",
    n = 1,
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
        return #selected < 1
    end,
    view_as = function(self, cards)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            return s4_wuhu_wusheng_selectCard:clone()
        else
            if #cards == 1 then
                local pattern
                if sgs.Sanguosha:getCurrentCardUsePattern() == "@@s4_wuhu_wusheng" then
                    pattern = sgs.Self:property("s4_wuhu_wusheng_card"):toString()
                else
                    pattern = "Slash"
                end
                local cc = s4_wuhu_wushengCard:clone()
                cc:addSubcard(cards[1])
                cc:setUserString(pattern)
                return cc
            end
        end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("s4_wuhu_wusheng_Used-Clear") == 0
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@@s4_wuhu_wusheng"
        or ((string.find(pattern, "slash") or string.find(pattern, "Slash"))
        and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
        and player:getMark("s4_wuhu_wusheng_Slash-Clear") == 0 and player:getMark("s4_wuhu_wusheng_Used-Clear") == 0)
    end,
}

s4_wuhu_wusheng_selectCard = sgs.CreateSkillCard{
    name = "s4_wuhu_wusheng_select",
    will_throw = false,
    target_fixed = true,
    about_to_use = function(self,room,use)
        local player = use.from
        local names = {"_ny_tenth_shuiyanqijun"}
        for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
            local card = sgs.Sanguosha:getEngineCard(id)
            if card:isKindOf("BasicCard") or card:isNDTrick() then
                if card:isDamageCard() then
                    if (not table.contains(names, card:objectName())) then
                        table.insert(names, card:objectName())
                    end
                end
            end
        end
        local able = {}
        local enable = {}
        for _,name in ipairs(names) do
            local card = sgs.Sanguosha:cloneCard(name)
            card:deleteLater()
            local mark = string.format("s4_wuhu_wusheng_%s-Clear", card:objectName())
            if card:isKindOf("Slash") then mark = "s4_wuhu_wusheng_Slash-Clear" end
            if player:getMark(mark) == 0 and card:isAvailable(player) then
                table.insert(able, name)
            else
                table.insert(enable, name)
            end
        end
        if #able <= 0 then
            room:askForChoice(player, "s4_wuhu_wusheng", "disable+cancel")
            return false
        end
        table.insert(able, "cancel")
        local pattern = room:askForChoice(player, "s4_wuhu_wusheng", table.concat(able, "+"), sgs.QVariant(), table.concat(enable, "+"))
        if pattern == "cancel" then return false end
        room:setPlayerProperty(player, "s4_wuhu_wusheng_card", sgs.QVariant(pattern))
        room:askForUseCard(player, "@@s4_wuhu_wusheng", "@s4_wuhu_wusheng:"..pattern)
    end
}

s4_wuhu_wushengCard = sgs.CreateSkillCard{
    name = "s4_wuhu_wusheng",
    will_throw = false,
    filter = function(self, targets, to_select,player)
        local pattern = self:getUserString()
		if pattern == "Slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        card:addSubcards(self:getSubcards())
        card:deleteLater()

		if card:targetFixed() then
			return false
		end
		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets, to_select, player)
	end,
	feasible = function(self, targets,player)
		local pattern = self:getUserString()
		if pattern == "Slash" then pattern = "slash" end

		local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:setSkillName(self:objectName())
        card:addSubcards(self:getSubcards())
        card:deleteLater()

		local qtargets = sgs.PlayerList()
		for _, p in ipairs(targets) do
			qtargets:append(p)
		end
		if card:canRecast() and #targets == 0 then
			return false
		end
		return card:targetsFeasible(qtargets, player) --and card:isAvailable(sgs.Self)
	end,
	on_validate = function(self, card_use)
		local player = card_use.from
        local room = player:getRoom()

        local pattern = self:getUserString()
        if pattern == "Slash" then
            pattern = room:askForChoice(player, "s4_wuhu_wusheng_slash", "fire_slash+thunder_slash+slash")
        end
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName(self:objectName())
        local mark = string.format("s4_wuhu_wusheng_%s-Clear", card:objectName())
        if card:isKindOf("Slash") then mark = "s4_wuhu_wusheng_Slash-Clear" end
        room:setPlayerMark(player, mark, 1)
        room:setPlayerMark(player, "s4_wuhu_wusheng_Used-Clear", 1)

        if sgs.Sanguosha:getCard(self:getSubcards():at(0)):hasFlag("s4_wuhu_wusheng") then
            room:setCardFlag(sgs.Sanguosha:getCard(self:getSubcards():at(0)), "-s4_wuhu_wusheng")
        end
        card:deleteLater()
        return card
	end,
    on_validate_in_response = function(self, player)
        local room = player:getRoom()
        local pattern = self:getUserString()
        if pattern == "Slash" then
            pattern = room:askForChoice(player, "s4_wuhu_wusheng_slash", "fire_slash+thunder_slash+slash")
        end
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        card:addSubcards(self:getSubcards())
        card:setSkillName(self:objectName())
        local mark = string.format("s4_wuhu_wusheng_%s-Clear", card:objectName())
        if card:isKindOf("Slash") then mark = "s4_wuhu_wusheng_Slash-Clear" end
        room:setPlayerMark(player, mark, 1)
        room:setPlayerMark(player, "s4_wuhu_wusheng_Used-Clear", 1)

        if sgs.Sanguosha:getCard(self:getSubcards():at(0)):hasFlag("s4_wuhu_wusheng") then
            room:setCardFlag(sgs.Sanguosha:getCard(self:getSubcards():at(0)), "-s4_wuhu_wusheng")
        end
        card:deleteLater()
        return card
    end
}

s4_wuhu_wusheng = sgs.CreateTriggerSkill{
    name = "s4_wuhu_wusheng",
    events = {sgs.CardUsed, sgs.CardResponded},
    frequency = sgs.Skill_NotFrequent,
    view_as_skill = s4_wuhu_wushengVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        else
            card = data:toCardResponse().m_card
        end
        if (not card) or (card:isKindOf("SkillCard")) then return false end
        local can_invoke = false
        local g = sgs.Sanguosha:getGeneral(player:getGeneralName())
        for _, sk in sgs.qlist(g:getVisibleSkillList()) do
            if sk:objectName() == "s4_wuhu_wusheng" then
                can_invoke = true
                break
            end
        end
        local general = player:getTag("s4_baijiang_general"):toString()
        if table.contains(card:getSkillNames(), "s4_wuhu_wusheng") and player:getMark("&s4_wuhu_wusheng-Clear") == 0 and ((gerenal and gerenal == "s4_wuhu_guanyu") or can_invoke) then
            room:setPlayerMark(player, "&s4_wuhu_wusheng-Clear", 1)
            local c = sgs.Sanguosha:getCard(card:getSubcards():first())
            local x = c:nameLength()
            player:drawCards(x,self:objectName())
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}


s4_wuhu_heduanbuff = sgs.CreateTargetModSkill{
    name = "#s4_wuhu_heduanbuff",
    pattern = "Slash",
    residue_func = function(self, from, card)
        if card:objectName() == "slash" and from:hasSkill("s4_wuhu_heduan") then
            if from:hasUsed("#s4_wuhu_heduan") then return 999 end
            return 1
        end
        return 0
    end,
}
s4_wuhu_heduanCard = sgs.CreateSkillCard{
	name = "s4_wuhu_heduan",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		room:loseHp(source, 1, true, source, self:objectName())
        room:addPlayerMark(source, "&s4_wuhu_heduan-Clear")
	end
}
s4_wuhu_heduanVS = sgs.CreateViewAsSkill{
	n = 0,
	name = "s4_wuhu_heduan",
	view_as = function(self, cards)
		return s4_wuhu_heduanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#s4_wuhu_heduan")
	end
}

s4_wuhu_heduan = sgs.CreateTriggerSkill{
    name = "s4_wuhu_heduan",
    events = {sgs.CardFinished, sgs.CardResponded, sgs.CardUsed},
    view_as_skill = s4_wuhu_heduanVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.from:objectName() ~= player:objectName() then return false end
            if not use.card:isKindOf("TrickCard") then return false end
            if not player:hasUsed("#s4_wuhu_heduan") then return false end
            room:addPlayerHistory(player, "TrickCard", 1)
            if player:usedTimes("TrickCard") > sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, dummyCard()) then
                room:setPlayerCardLimitation(player, "use","TrickCard", true)
            end
        else
            local card = nil
            if event == sgs.CardUsed then
                card = data:toCardUse().card
            else
                card = data:toCardResponse().m_card
            end
            if player:getMark("s4_wuhu_heduan_draw-Clear") > 0 then return false end
            if card and card:isKindOf("Slash") then
                local gerenal = player:getTag("s4_baijiang_general"):toString()
                local can_invoke = false
                local g = sgs.Sanguosha:getGeneral(player:getGeneralName())
                for _, sk in sgs.qlist(g:getVisibleSkillList()) do
                    if sk:objectName() == "s4_wuhu_heduan" then
                        can_invoke = true
                        break
                    end
                end
                if (gerenal and gerenal == "s4_wuhu_zhangfei") or can_invoke then
                    if player:getHandcardNum() < player:getMaxHp() and player:askForSkillInvoke(self:objectName(), data) then
                        player:drawCards(player:getMaxHp()-player:getHandcardNum(), self:objectName())
                        room:addPlayerMark(player, "s4_wuhu_heduan_draw-Clear")
                        room:addPlayerMark(player, "&s4_wuhu_heduan+:+draw-Clear")
                    end
                end
            end
        end
    end,
}

s4_wuhu_fuyong = sgs.CreateTriggerSkill{
	name = "s4_wuhu_fuyong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecified, sgs.CardUsed, sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") and use.card:isDamageCard() then
                for _, p in sgs.qlist(use.to) do
                    if use.from:isAlive() and room:askForSkillInvoke(player, self:objectName(), ToData(p)) then
                        room:addPlayerMark(p, "s4_wuhu_fuyong"..player:objectName())
                        room:addPlayerMark(p, "&s4_wuhu_fuyong+to+#"..player:objectName().."-Clear")
                        room:addPlayerMark(p, "@skill_invalidity")
                    end
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if not use.card:isKindOf("SkillCard") and use.card:isDamageCard() then
                local gerenal = player:getTag("s4_baijiang_general"):toString()
                local can_invoke = false
                local g = sgs.Sanguosha:getGeneral(player:getGeneralName())
                for _, sk in sgs.qlist(g:getVisibleSkillList()) do
                    if sk:objectName() == "s4_wuhu_fuyong" then
                        can_invoke = true
                        break
                    end
                end
                if (gerenal and gerenal == "s4_wuhu_machao") or can_invoke then
                    if player:getMark("s4_wuhu_fuyong-Clear") == 1 then
                        local no_respond_list = use.no_respond_list
                        table.insert(no_respond_list, "_ALL_TARGETS")
                        use.no_respond_list = no_respond_list
                        data:setValue(use)
                        local log = sgs.LogMessage()
                        log.type = "$NoRespond"
                        log.from = use.from
                        log.to = use.to
                        log.arg = self:objectName()
                        log.card_str = use.card:toString()
                        room:sendLog(log)
                    end
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:hasFlag("s4_wuhu_fuyong") then
                local gerenal = player:getTag("s4_baijiang_general"):toString()
                local can_invoke = false
                local g = sgs.Sanguosha:getGeneral(player:getGeneralName())
                for _, sk in sgs.qlist(g:getVisibleSkillList()) do
                    if sk:objectName() == "s4_wuhu_fuyong" then
                        can_invoke = true
                        break
                    end
                end
                if (gerenal and gerenal == "s4_wuhu_machao") or can_invoke then
                    player:damageRevises(data,1)
                end
            end
        end
		return false
	end,
}
s4_wuhu_fuyong_record = sgs.CreateTriggerSkill{
	name = "#s4_wuhu_fuyong_record",
	events = {sgs.PreCardUsed, sgs.PreCardResponded, sgs.EventPhaseChanging, sgs.EventLoseSkill, sgs.Death},
	priority = -1,
	on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if player:getMark("s4_wuhu_fuyong"..p:objectName()) > 0 then
                    room:setPlayerMark(player, "s4_wuhu_fuyong"..p:objectName(), 0)
                    room:setPlayerMark(player, "@skill_invalidity", 0)
                end
            end
        elseif event == sgs.PreCardResponded or event == sgs.PreCardUsed then
            local card
            if event == sgs.PreCardUsed then
                card = data:toCardUse().card
            else
                if data:toCardResponse().m_isUse then
                    card = data:toCardResponse().m_card
                end
            end
            if card and not card:isKindOf("SkillCard") and player:hasSkill("s4_wuhu_fuyong") then
                if card:isDamageCard() then
                    room:addPlayerMark(player, "s4_wuhu_fuyong-Clear")
                    if player:getMark("s4_wuhu_fuyong-Clear") == 2 then
                        room:setCardFlag(card, "s4_wuhu_fuyong")
                    end
                end
            end
        elseif (event == sgs.EventLoseSkill and data:toString() == "s4_wuhu_fuyong") or (event == sgs.Death and data:toDeath().who:objectName() == player:objectName() and data:toDeath().who:hasSkill("s4_wuhu_fuyong"))  then
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("s4_wuhu_fuyong"..player:objectName()) > 0 then
                    room:setPlayerMark(p, "s4_wuhu_fuyong"..p:objectName(), 0)
                    room:setPlayerMark(p, "@skill_invalidity", 0)
                end
            end
        end
		return false
    end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

s4_wuhu_liegong = sgs.CreateTriggerSkill {
	name = "s4_wuhu_liegong",
	events = { sgs.TargetSpecified },
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
        local gerenal = player:getTag("s4_baijiang_general"):toString()
        local can_invoke = false
        local g = sgs.Sanguosha:getGeneral(player:getGeneralName())
        for _, sk in sgs.qlist(g:getVisibleSkillList()) do
            if sk:objectName() == "s4_wuhu_liegong" then
                can_invoke = true
                break
            end
        end
        if (gerenal and gerenal == "s4_wuhu_huangzhong") or can_invoke then
            if player:askForSkillInvoke(self:objectName(), data) then
                local shows = room:showDrawPile(player, 4, self:objectName(), true)
                room:getThread():delay(1000)
                local to_obtain = dummyCard()
                local to_discard = shows
                local x = 0
                for _,id in sgs.qlist(shows) do
                    if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
                        to_obtain:addSubcard(sgs.Sanguosha:getCard(id))
                        to_discard:removeOne(id)
                    else
                        x = x + 1
                    end
                end
                if to_obtain:subcardsLength() > 0 then
                    player:obtainCard(to_obtain)
                end
                if to_discard:length() > 0 then
                    local names = sgs.QList2Table(to_discard)
                    local log = sgs.LogMessage()
                    log.type = "$MoveToDiscardPile"
                    log.from = player
                    log.card_str = table.concat(names, "+")
                    room:sendLog(log)
                    local reason1 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), self:objectName(),"")
                    local move1 = sgs.CardsMoveStruct(to_discard, nil, nil, sgs.Player_PlaceTable, sgs.Player_DiscardPile, reason1)
                    room:moveCardsAtomic(move1,true)
                end
                if x > 0 then
                    room:setCardFlag(use.card, "liegongAddDamage_" .. tostring(x))
                end
                room:setCardFlag(use.card, "s4_wuhu_liegongUsed");
            end
        end
		return false
	end
}
s4_wuhu_liegong_Target = sgs.CreateTargetModSkill {
	name = "#s4_wuhu_liegong_Target",
	distance_limit_func = function(self, player, card)
		if player:hasSkill("s4_wuhu_liegong") and card and not card:isVirtualCard() then
			return card:getNumber()
		end
	end,
}
s4_wuhu_liegong_buff = sgs.CreateTriggerSkill{
	name = "#s4_wuhu_liegong_buff",
	events = {sgs.ConfirmDamage},
	priority = -1,
	on_trigger = function(self, event, player, data, room)
        if event == sgs.ConfirmDamage then
            local damage = data:toDamage()
            if (not damage.card or not damage.card:hasFlag("s4_wuhu_liegongUsed") or not damage.to or damage.to:isDead()) then return false end
            local d = 0
            for _,flag in sgs.list(damage.card:getFlags()) do
                if (not string.startsWith(flag, "liegongAddDamage_")) then continue end
                d = tonumber(flags[#flags])
                if d > 0 then
                    break
                end
            end
            
            if (d <= 0) then return false end
            player:damageRevises(data,d)
        end
		return false
    end,
	can_trigger = function(self, target)
		return target ~= nil
	end
}

s4_wuhu_longdanVS = sgs.CreateViewAsSkill{
	name = "s4_wuhu_longdan" ,
	n = 1 ,
    response_or_use = true,
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
			elseif pattern == "jink" then
				return card:isKindOf("Slash")
			elseif pattern == "nullification" then
				return not card:isKindOf("BasicCard")
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
			local nullification = sgs.Sanguosha:cloneCard("nullification", originalCard:getSuit(), originalCard:getNumber())
			nullification:addSubcard(originalCard)
			nullification:setSkillName(self:objectName())
			return nullification
		end
	end ,
	enabled_at_play = function(self, target)
		return sgs.Slash_IsAvailable(target)
	end,
	enabled_at_response = function(self, target, pattern)
		return (pattern == "slash") or (pattern == "jink") or (pattern == "nullification")
	end
}


s4_wuhu_longdan = sgs.CreateTriggerSkill{
	name = "s4_wuhu_longdan" ,
    view_as_skill = s4_wuhu_longdanVS,
	events = {sgs.CardResponded, sgs.CardUsed, sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        if player:getMark("s4_wuhu_longdan-Clear") >= 2 then return false end
        if event == sgs.CardUsed or event == sgs.CardResponded then
            local card = nil
            local target = nil
            if event == sgs.CardUsed then
                card = data:toCardUse().card
                target = data:toCardUse().who
            else
                card = data:toCardResponse().m_card
                target = data:toCardUse().m_who
            end
            if not card or not target then return false end
            if card:isKindOf("SkillCard") then return false end
            if card:getSkillName() ~= "s4_wuhu_longdan" then return false end
            local gerenal = player:getTag("s4_baijiang_general"):toString()
            local can_invoke = false
            local g = sgs.Sanguosha:getGeneral(player:getGeneralName())
            for _, sk in sgs.qlist(g:getVisibleSkillList()) do
                if sk:objectName() == "s4_wuhu_longdan" then
                    can_invoke = true
                    break
                end
            end
            if (gerenal and gerenal == "s4_wuhu_zhaoyun") or can_invoke then
                if (not target:isKongcheng()) then
                    local _data = sgs.QVariant()
                    _data:setValue(target)
                    if player:askForSkillInvoke(self:objectName(), _data) then
                        local card_id = room:askForCardChosen(player, target, "h", self:objectName())
                        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
                        room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
                        room:addPlayerMark(player, "s4_wuhu_longdan-Clear", 1)
                        room:addPlayerMark(player, "&s4_wuhu_longdan-Clear", 1)
                    end
                end
            end
        else
            local use = data:toCardUse()
            if table.contains(use.card:getSkillNames(), "s4_wuhu_longdan") then
                local log = sgs.LogMessage()
				log.type = "#IgnoreArmor"
				log.from = player
				log.card_str = use.card:toString()
				room:sendLog(log)
                player:addQinggangTag(use.card)
                local gerenal = player:getTag("s4_baijiang_general"):toString()
                local can_invoke = false
                local g = sgs.Sanguosha:getGeneral(player:getGeneralName())
                for _, sk in sgs.qlist(g:getVisibleSkillList()) do
                    if sk:objectName() == "s4_wuhu_longdan" then
                        can_invoke = true
                        break
                    end
                end
                if (gerenal and gerenal == "s4_wuhu_zhaoyun") or can_invoke then
                    for _, p in sgs.qlist(use.to) do
                        if p:isKongcheng() then continue end
                        local _data = sgs.QVariant()
                        _data:setValue(p)
                        p:setFlags("s4_wuhu_longdanTarget")
                        local invoke = player:askForSkillInvoke(self:objectName(), _data)
                        p:setFlags("-s4_wuhu_longdanTarget")
                        if invoke then
                            room:addPlayerMark(player, "s4_wuhu_longdan-Clear", 1)
                            room:addPlayerMark(player, "&s4_wuhu_longdan-Clear", 1)
                            local card_id = room:askForCardChosen(player, p, "h", self:objectName())
                            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
                            room:obtainCard(player, sgs.Sanguosha:getCard(card_id), reason, false)
                        end
                    end
                end
            end
        end
        return false
	end
}
s4_wuhu:addSkill(s4_baijiang)
s4_wuhu_guanyu:addSkill(s4_wuhu_wusheng)
s4_wuhu_zhangfei:addSkill(s4_wuhu_heduan)
s4_wuhu_machao:addSkill(s4_wuhu_fuyong)
s4_wuhu_machao:addSkill(s4_wuhu_fuyong_record)
extension:insertRelatedSkills("s4_wuhu_fuyong", "#s4_wuhu_fuyong_record")
s4_wuhu_huangzhong:addSkill(s4_wuhu_liegong)
s4_wuhu_huangzhong:addSkill(s4_wuhu_liegong_Target)
s4_wuhu_huangzhong:addSkill(s4_wuhu_liegong_buff)
extension:insertRelatedSkills("s4_wuhu_liegong", "#s4_wuhu_liegong_Target")
extension:insertRelatedSkills("s4_wuhu_liegong", "#s4_wuhu_liegong_buff")
s4_wuhu_zhaoyun:addSkill(s4_wuhu_longdan)

--https://tieba.baidu.com/p/9729902662
sgs.LoadTranslationTable {
    ["s4_wuhu"] = "五虎将",
    ["&s4_wuhu"] = "五虎将",
    ["#s4_wuhu"] = "戮力扶汉",
    ["~s4_wuhu"] = "",
    ["designer:s4_wuhu"] = "贴吧用户_53ZbMyG",
    ["cv:s4_wuhu"] = "",
    ["illustrator:s4_wuhu"] = "",
    ["s4_baijiang"] = "拜将",
    [":s4_baijiang"] = "锁定技，游戏开始时，你获得五张不同的虎将，然后你从中选择两张虎将牌分别作为主将与副将亮出。你的回合开始与结束时，你选择一至两张未亮出的虎将牌替换当前亮出的虎将并重新分配主将与副将（不可由同一虎将连续作为主将）。你视为拥有你亮出虎将的技能。",

    ["s4_wuhu_guanyu"] = "关羽",
    ["&s4_wuhu_guanyu"] = "关羽",
    ["#s4_wuhu_guanyu"] = "骁勇飘杰",
    ["~s4_wuhu_guanyu"] = "",
    ["designer:s4_wuhu_guanyu"] = "贴吧用户_53ZbMyG",
    ["s4_wuhu_wusheng"] = "武圣",
    [":s4_wuhu_wusheng"] = "每回合限一次，你可以将一张牌当任意伤害牌使用。作为主将时，你以此法使用或打出牌时，你摸X张牌（X为转化前此牌的牌名字数），每回合限一次。",
    [":s4_wuhu_wusheng2"] = "每回合限一次，你可以将一张牌当任意伤害牌使用。",
    ["@s4_wuhu_wusheng"] = "请将一张牌当作 【%src】 使用",

    ["s4_wuhu_zhangfei"] = "张飞",
    ["&s4_wuhu_zhangfei"] = "张飞",
    ["#s4_wuhu_zhangfei"] = "喝断却敌",
    ["~s4_wuhu_zhangfei"] = "",
    ["designer:s4_wuhu_zhangfei"] = "贴吧用户_53ZbMyG",
    ["s4_wuhu_heduan"] = "喝断",
    [":s4_wuhu_heduan"] = "出牌阶段，你可以多使用一张【杀】。出牌阶段限一次，你可以失去1点体力，然后本回合你使用【杀】与锦囊牌的次数交换。作为主将时，你使用或打出杀后，你可以将手牌补至体力上限，每回合限一次。",
    [":s4_wuhu_heduan2"] = "出牌阶段，你可以多使用一张【杀】。出牌阶段限一次，你可以失去1点体力，然后本回合你使用【杀】与锦囊牌的次数交换。",

    ["s4_wuhu_machao"] = "马超",
    ["&s4_wuhu_machao"] = "马超",
    ["#s4_wuhu_machao"] = "抗扬虓虎",
    ["~s4_wuhu_machao"] = "",
    ["designer:s4_wuhu_machao"] = "贴吧用户_53ZbMyG",
    ["s4_wuhu_fuyong"] = "负勇",
    [":s4_wuhu_fuyong"] = "你用伤害牌指定一名角色后，你可以令其本回合非锁定技失效。作为主将时，你每回合使用的第一张伤害牌不可被响应且第二张伤害牌伤害+1。",
    [":s4_wuhu_fuyong2"] = "你用伤害牌指定一名角色后，你可以令其本回合非锁定技失效。",

    ["s4_wuhu_huangzhong"] = "黄忠",
    ["&s4_wuhu_huangzhong"] = "黄忠",
    ["#s4_wuhu_huangzhong"] = "摧峰登难",
    ["~s4_wuhu_huangzhong"] = "",
    ["designer:s4_wuhu_huangzhong"] = "贴吧用户_53ZbMyG",
    ["s4_wuhu_liegong"] = "烈弓",
    [":s4_wuhu_liegong"] = "你使用牌可以选择距离不大于此牌点数的角色为目标。作为主将时，你使用【杀】时，你可以展示牌堆顶的四张牌，若其中有：基本牌，你获得之；非基本牌，此【杀】伤害+X（X为其中非基本牌的数目）。",
    [":s4_wuhu_liegong2"] = "你使用牌可以选择距离不大于此牌点数的角色为目标。",

    ["s4_wuhu_zhaoyun"] = "赵云",
    ["&s4_wuhu_zhaoyun"] = "赵云",
    ["#s4_wuhu_zhaoyun"] = "缱绻御侮",
    ["~s4_wuhu_zhaoyun"] = "",
    ["designer:s4_wuhu_zhaoyun"] = "贴吧用户_53ZbMyG",
    ["s4_wuhu_longdan"] = "龙胆",
    [":s4_wuhu_longdan"] = "你可以将一张【杀】当【闪】/【闪】当【杀】，非基本牌当作无懈可击使用​​或打出。你使用转化的牌无视防具。作为主将时，你以此法使用牌时，你可以获得对方一张牌，每回合限两次。",
    [":s4_wuhu_longdan2"] = "你可以将一张【杀】当【闪】/【闪】当【杀】，非基本牌当作无懈可击使用​​或打出。你使用转化的牌无视防具。",

}

s4_zhurong = sgs.General(extension, "s4_zhurong", "shu", 4, false)


s4_lieren_buff = sgs.CreateTargetModSkill{
    name = "#s4_lieren_buff",
    pattern = "Slash",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("s4_lieren") and card and table.contains(card:getSkillNames(), "s4_lieren") then return 1000 end
        return 0
    end,
}
s4_lierenVS = sgs.CreateViewAsSkill{
    name = "s4_lieren",
    n = 999,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards > 0 then
            local card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
            card:setSkillName(self:objectName())
            for _,cc in ipairs(cards) do
                card:addSubcard(cc)
            end
            return card
        end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("s4_lieren_Used-Clear") == 0
    end,
}
s4_lieren = sgs.CreateTriggerSkill{
    name = "s4_lieren",
    events = {sgs.CardUsed, sgs.CardOffset, sgs.EventPhaseStart},
    view_as_skill = s4_lierenVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and table.contains(use.card:getSkillNames(), "s4_lieren") then
                room:addPlayerMark(player, "s4_lieren_Used-Clear")
                room:setPlayerMark(player, "s4_lieren-Clear", use.card:subcardsLength())
                room:setPlayerMark(player, "&s4_lieren-Clear", use.card:subcardsLength())
            end
        elseif event == sgs.CardOffset then
            local effect = data:toCardEffect()
            if effect.card and effect.card:isKindOf("Slash") and table.contains(effect.card:getSkillNames(), "s4_lieren") then
                room:setPlayerMark(player, "s4_lieren-Clear", 0)
            end
        elseif event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Finish and player:getMark("s4_lieren-Clear") > 0 then
                player:drawCards(player:getMark("s4_lieren-Clear"), self:objectName())
            end
        end
    end,
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end,
}

s4_juxiang = sgs.CreateTriggerSkill {
	name = "s4_juxiang",
	frequency = sgs.Skill_Compulsory,
	events = { sgs.CardsMoveOneTime, sgs.BeforeCardsMove, sgs.CardUsed, sgs.DamageCaused, sgs.TargetSpecified, sgs.Pindian },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				if use.card:isVirtualCard()
					and (use.card:subcardsLength() == 0) then
					return false
				end
				if use.card:isKindOf("SavageAssault") then
					room:setCardFlag(use.card:getEffectiveId(), "real_SA")
				end
			end
		elseif event == sgs.BeforeCardsMove then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				local move = data:toMoveOneTime()
				if (move.card_ids:length() >= 1)
					and move.from_places:contains(sgs.Player_PlaceTable)
					and (move.to_place == sgs.Player_DiscardPile)
					and (move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE) then
					local card = sgs.Sanguosha:getCard(move.card_ids:first())
					if card:hasFlag("real_SA")
						and (player:objectName() ~= move.from:objectName()) then
						for _, id in sgs.qlist(move.card_ids) do
							player:obtainCard(sgs.Sanguosha:getCard(id))
							room:broadcastSkillInvoke("s4_juxiang", 1)
						end
						move.card_ids = sgs.IntList()
						data:setValue(move)
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and (move.from:objectName() ~= player:objectName())
				and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
				and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD)
				and player and player:isAlive() and player:hasSkill(self:objectName()) then
				for _, id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(id):isKindOf("SavageAssault") then
						player:obtainCard(sgs.Sanguosha:getCard(id))
						room:broadcastSkillInvoke("s4_juxiang", 2)
					end
				end
			end
		elseif event == sgs.DamageCaused then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				local damage = data:toDamage()
				if damage.from == player and damage.card and (damage.card:isKindOf("SavageAssault") or damage.card:isKindOf("Slash")) and player:getMark("s4_juxiang"..damage.to:objectName()..damage.card:getEffectiveId().."Card-SelfClear") > 0 then
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
			end
		elseif event == sgs.TargetSpecified then
            local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") or use.card:isKindOf("Slash") then
                if use.from and use.from:isAlive() and use.from:hasSkill(self:objectName()) then
                    local targets = sgs.SPlayerList()
                    for _,p in sgs.qlist(use.to) do
                        if use.from:canPindian(p) then
                            targets:append(p)
                        end
                    end
                    if not targets:isEmpty() then
                        local target = room:askForPlayerChosen(player, targets, self:objectName(),
						"s4_juxiang-invoke", true, true)
                        if not target then return false end
                        local success = player:pindian(target, self:objectName())
		                if success then
                            local choicelist = "damage"
                            if not target:isNude() then
                                choicelist = string.format("%s+%s", choicelist, "obtain")
                            end
                            choicelist = string.format("%s+%s", choicelist, "cancel")
                            local choice = room:askForChoice(player, self:objectName(), choicelist)
				            if choice == "damage" then
                                room:addPlayerMark(player, "s4_juxiang"..target:objectName()..use.card:getEffectiveId().."Card-SelfClear")
                            elseif choice == "obtain" then
                                if not target:isNude() then
                                    local id = room:askForCardChosen(player, target, "he", self:objectName())
                                    room:obtainCard(player, id, false)
                                end
                            end
                        end
                    end
                end
            end
        elseif player:isAlive() and event == sgs.Pindian
			and player:hasSkill(self:objectName()) then
			local pindian = data:toPindian()
			if pindian.reason == "s4_juxiang" and not pindian.success and room:askForSkillInvoke(player, self:objectName(), data) then
				player:obtainCard(pindian.to_card)
			end
        end
	end,
	can_trigger = function(self, target)
		return target
	end
}
s4_juxiang_Avoid = sgs.CreateTriggerSkill {
	name = "#s4_juxiang_Avoid",
	events = { sgs.CardEffected },
	on_trigger = function(self, event, player, data)
		local effect = data:toCardEffect()
		if effect.card:isKindOf("SavageAssault") then
			return true
		else
			return false
		end
	end
}

s4_zhurong:addSkill(s4_lieren_buff)
s4_zhurong:addSkill(s4_lieren)
extension:insertRelatedSkills("s4_lieren", "#s4_lieren_buff")
s4_zhurong:addSkill(s4_juxiang_Avoid)
s4_zhurong:addSkill(s4_juxiang)
extension:insertRelatedSkills("s4_juxiang", "#s4_juxiang_Avoid")
--https://tieba.baidu.com/p/8628062146
sgs.LoadTranslationTable {
    ["s4_zhurong"] = "祝融",
    ["&s4_zhurong"] = "祝融",
    ["~s4_zhurong"] = "",
    ["designer:s4_zhurong"] = "终极植物",
    ["cv:s4_zhurong"] = "",
    ["illustrator:s4_zhurong"] = "",

    ["s4_lieren"] = "烈刃",
    [":s4_lieren"] = "出牌阶段限一次，你可以将至少一张手牌当无距离限制的火【杀】使用，若没有被抵消，结束阶段，你摸等量牌。",
    ["s4_juxiang:obtain"] = "获得其一张牌",
    ["s4_juxiang:damage"] = "令此牌对其造成的伤害+1",
    ["s4_juxiang"] = "巨象",
    [":s4_juxiang"] = "【南蛮入侵】对你无效。当其他角色的【南蛮入侵】因使用或弃置进入弃牌堆后，你可以获得之。当你使用【杀】或【南蛮入侵】指定目标后，你可以摸一张牌，然后与其中一个目标拼点，若你：赢，你可以令此牌对其造成的伤害+1或获得其一张牌；没赢，你可以获得其拼点的牌。",
    ["s4_juxiang-invoke"] = "你可以发动“巨象”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",


}

s4_guanyu = sgs.General(extension, "s4_guanyu", "shu", 4)
s4_benxi_buff = sgs.CreateDistanceSkill {
    name = "#s4_benxi_buff",
    correct_func = function(self, from, to)
        if from:hasSkill("s4_benxi") then
            return -1
        end
    end
}
s4_benxi = sgs.CreateTriggerSkill{
    name = "s4_benxi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage, sgs.PreCardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("s4_benxi"..damage.to:objectName()) then
		    	room:sendCompulsoryTriggerLog(player, self)
				player:damageRevises(data,1)
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:getMark("used_slash-Clear") == 0 then
				local has1 = false
				for _,to in sgs.list(use.to)do
					if player:distanceTo(to) <= 1 then
						if player:getMark("s4_benxiUse1-Clear")<1 then
							room:setCardFlag(use.card,"s4_benxi"..to:objectName())
							has1 = true
						end
					end
				end
				if has1 then
					player:addMark("s4_benxiUse1-Clear")
				end
			end
		end
	end,
}
s4_wushengVS = sgs.CreateOneCardViewAsSkill{
    name = "s4_wusheng",
    response_or_use = true,
    view_filter = function(self, card)
        if not card:isRed() then return false end
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        slash:addSubcard(card:getEffectiveId())
        slash:deleteLater()
        return slash:isAvailable(sgs.Self)
    end,
    view_as = function(self, card)
        if card:isRed() then
            local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
            slash:addSubcard(card:getId())
            slash:setSkillName(self:objectName())
            return slash
        end
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player)
    end, 
    enabled_at_response = function(self, player, pattern)
        return pattern == "slash"
    end
}
s4_wusheng = sgs.CreateTriggerSkill{
    name = "s4_wusheng",
	view_as_skill = s4_wushengVS,
	events = {sgs.TargetSpecified, sgs.CardUsed},
	on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if event == sgs.TargetSpecified then
            if use.card and table.contains(use.card:getSkillNames(), "s4_wusheng") and player:hasSkill(self:objectName()) then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:setCardFlag(player, self:objectName())
                end
            end
        elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Jink") and use.whocard and table.contains(use.whocard:getSkillNames(), "s4_wusheng") and use.whocard:hasFlag(self:objectName()) then
				if use.card:getSuit() == use.whocard:getSuit() then
					local nullified_list = use.nullified_list
					table.insert(nullified_list, "_ALL_TARGETS")
					use.nullified_list = nullified_list
					data:setValue(use)
				end
			end
        end
    end,
    can_trigger = function(self, target)
		return target
	end
}


s4_guanyu:addSkill(s4_benxi_buff)
s4_guanyu:addSkill(s4_benxi)
extension:insertRelatedSkills("s4_benxi", "#s4_benxi_buff")
s4_guanyu:addSkill(s4_wusheng)

s4_zhangfei = sgs.General(extension, "s4_zhangfei", "shu", 4)

s4_paoxiao_buff = sgs.CreateTargetModSkill{
	name = "#s4_paoxiao_buff",
	pattern = "Slash" ,
	residue_func = function(self, player)
		if player:hasSkill("s4_paoxiao") then
			return 1000
		else
			return 0
		end
	end,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("s4_paoxiao") then return 1000 end
        return 0
    end,
}
s4_paoxiao = sgs.CreateTriggerSkill{
	name = "s4_paoxiao",
    frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event ==sgs.CardUsed then 
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and player:getMark("used_slash-Clear") > 0 and player:hasSkill(self:objectName()) then
                room:broadcastSkillInvoke("s4_paoxiao")
				if player:getMark("used_slash-Clear") == 2 then
					room:sendCompulsoryTriggerLog(player, "s4_paoxiao")
                    local x = 0
                    local targets = sgs.SPlayerList()
                    for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                        if p:inMyAttackRange(player) then
                            x = x + 1
                        end
                    end
                    x = math.ceil(x/2)
					player:drawCards(x, self:objectName())
				end
			end
		end
	end,
		can_trigger = function(self, target)
		return target
	end,
}


s4_zhangfei:addSkill(s4_paoxiao_buff)
s4_zhangfei:addSkill(s4_paoxiao)
extension:insertRelatedSkills("s4_paoxiao","#s4_paoxiao_buff")

s4_machao = sgs.General(extension, "s4_machao", "shu", 4)
s4_tieji = sgs.CreateTriggerSkill{
	name = "s4_tieji" ,
	events = {sgs.TargetSpecified} ,
	on_trigger = function(self, event, player, data, room)
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") then return false end
        local no_respond_list = use.no_respond_list
		for _, p in sgs.qlist(use.to) do
			if not player:isAlive() then break end
			local _data = sgs.QVariant()
			_data:setValue(p)
			if player:askForSkillInvoke(self:objectName(), _data) then
                local ids = room:getNCards(2, false)
                             
                room:fillAG(ids, player)
                local choice_id = room:askForAG(player, ids, false, self:objectName())
                if choice_id ~= -1 then
                    local card = sgs.Sanguosha:getCard(choice_id)
                    ids:removeOne(choice_id)
                    room:obtainCard(player, card, false)
                end
                room:clearAG()
                room:returnToTopDrawPile(ids)
				local judge = sgs.JudgeStruct()
				judge.pattern = ".|red"
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
                local log = sgs.LogMessage()
                log.type = "$NoRespond"
                log.from = use.from
                log.to = use.to
                log.arg = self:objectName()
                log.card_str = use.card:toString()
                room:sendLog(log)
				if judge:isGood() then
					table.insert(no_respond_list, p:objectName())
				end
			end
		end
        use.no_respond_list = no_respond_list
        data:setValue(use)
		return false
	end
}
s4_machao:addSkill("mashu")
s4_machao:addSkill(s4_tieji)

s4_huangzhong = sgs.General(extension, "s4_huangzhong", "shu", 4)
s4_liegong_buff = sgs.CreateAttackRangeSkill{
	name = "#s4_liegong_buff",
	extra_func = function(self, player, include_weapon)
		if player:hasSkill("s4_liegong") then
			return 1
		end
	end,
}

s4_liegong = sgs.CreateTriggerSkill {
	name = "s4_liegong",
	events = { sgs.TargetConfirmed, sgs.CardFinished, sgs.DamageCaused},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if (player:objectName() ~= use.from:objectName()) or (not use.card:isKindOf("Slash")) then return false end
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				local handcardnum = p:getHandcardNum()
			    if (player:getHp() <= handcardnum) or (player:getAttackRange() >= handcardnum) then
                    local log = sgs.LogMessage()
                    log.type = "#skill_cant_jink"
                    log.from = player
                    log.to:append(p)
                    log.arg = self:objectName()
                    room:sendLog(log)
                    jink_table[index] = 0
				end
                if p:getHp() <= player:getAttackRange() or p:getHp() >= player:getHp() then
                    room:setCardFlag(use.card, self:objectName())
                    room:setPlayerFlag(p, self:objectName())
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
s4_huangzhong:addSkill(s4_liegong_buff)
s4_huangzhong:addSkill(s4_liegong)
extension:insertRelatedSkills("s4_liegong","#s4_liegong_buff")

s4_2_zhaoyun = sgs.General(extension, "s4_2_zhaoyun", "shu", 4)
s4_longdan_buff = sgs.CreateTargetModSkill{
	name = "#s4_longdan_buff",
	pattern = "Slash" ,
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("s4_longdan") and card and table.contains(card:getSkillNames(), "s4_longdan") then return 1000 end
        return 0
    end,
}
s4_longdanVS = sgs.CreateViewAsSkill{
	name = "s4_longdan" ,
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
s4_longdan = sgs.CreateTriggerSkill{
	name = "s4_longdan",
	events = {sgs.CardResponded, sgs.CardUsed},
    view_as_skill = s4_longdanVS,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        local card
        if event == sgs.CardResponded then
            card = data:toCardResponse().m_card
        elseif event == sgs.CardUsed then
            card = data:toCardUse().card
        end
        if card:isKindOf("BasicCard") then
            if player:getPhase() == sgs.Player_NotActive then
                local targets = sgs.SPlayerList()
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if player:canDiscard(p, "hej") then
                        targets:append(p)
                    end
                end
                if not targets:isEmpty() then
                    local target = room:askForPlayerChosen(player, targets, self:objectName(), "s4_longdan-invoke")
                    if not target then return false end
                    local to_throw = room:askForCardChosen(player, target, "hej", self:objectName())
					local card = sgs.Sanguosha:getCard(to_throw)
					room:throwCard(card, target, player)
                end
            else
                if player:askForSkillInvoke(self:objectName()) then
                    player:drawCards(1, self:objectName())
                end
            end
        end
	end,
}
s4_2_zhaoyun:addSkill(s4_longdan_buff)
s4_2_zhaoyun:addSkill(s4_longdan)
extension:insertRelatedSkills("s4_longdan","#s4_longdan_buff")


--https://tieba.baidu.com/p/8876899970
sgs.LoadTranslationTable {
    ["s4_guanyu"] = "关羽",
    ["&s4_guanyu"] = "关羽",
    ["#s4_guanyu"] = "美髯公",
    ["~s4_guanyu"] = "",
    ["designer:s4_guanyu"] = "终极植物",
    ["cv:s4_guanyu"] = "",
    ["illustrator:s4_guanyu"] = "",
    ["s4_benxi_buff"] = "奔袭",
    ["s4_benxi"] = "奔袭",
    [":s4_benxi"] = "锁定技，你计算与其他角色的距离-1。每回合你首次使用【杀】对距离1以内的其他角色造成伤害时，此伤害+1。",
    ["s4_wusheng"] = "武圣",
    [":s4_wusheng"] = "你可以将一张红色牌当【杀】使用或打出。你使用【杀】指定目标后，你可以令此【杀】不能被同花色的闪响应。",

    ["s4_zhangfei"] = "张飞",
    ["&s4_zhangfei"] = "张飞",
    ["#s4_zhangfei"] = "万夫不当",
    ["~s4_zhangfei"] = "",
    ["designer:s4_zhangfei"] = "终极植物",
    ["cv:s4_zhangfei"] = "",
    ["illustrator:s4_zhangfei"] = "",
    ["s4_paoxiao"] = "咆哮",
    [":s4_paoxiao"] = "锁定技，你使用【杀】无距离和次数限制。当你在每回合使用第二张【杀】时，你摸X张牌（X为攻击范围内含有你的其他角色数的一半，向上取整）。",

    ["s4_machao"] = "马超",
    ["&s4_machao"] = "马超",
    ["#s4_machao"] = "一骑当千",
    ["~s4_machao"] = "",
    ["designer:s4_machao"] = "终极植物",
    ["cv:s4_machao"] = "",
    ["illustrator:s4_machao"] = "",
    ["s4_tieji"] = "铁骑",
    [":s4_tieji"] = "当你使用【杀】指定目标后，你可以观看牌堆顶的两张牌并获得其中一张牌，然后进行判定，若结果为红色，其不能响应此【杀】。",

    ["s4_huangzhong"] = "黄忠",
    ["&s4_huangzhong"] = "黄忠",
    ["#s4_huangzhong"] = "老当益壮",
    ["~s4_huangzhong"] = "",
    ["designer:s4_huangzhong"] = "终极植物",
    ["cv:s4_huangzhong"] = "",
    ["illustrator:s4_huangzhong"] = "",
    ["s4_liegong"] = "烈弓",
    [":s4_liegong"] = "锁定技，你的攻击范围+1。当你使用【杀】指定目标后：1.若其手牌数不大于你的攻击范围或不少于你的体力值，其不能使用【闪】响应此【杀】；2.若其体力值不大于你的攻击范围或不少于你的体力值，此【杀】伤害+1。",

    ["s4_2_zhaoyun"] = "赵云",
    ["&s4_2_zhaoyun"] = "赵云",
    ["#s4_2_zhaoyun"] = "少年将军",
    ["~s4_2_zhaoyun"] = "",
    ["designer:s4_2_zhaoyun"] = "终极植物",
    ["cv:s4_2_zhaoyun"] = "",
    ["illustrator:s4_2_zhaoyun"] = "",
    ["s4_longdan"] = "龙胆",
    [":s4_longdan"] = "你可以将一张【杀】当【闪】、【闪】当【杀】使用或打出，以此法使用的【杀】无距离限制。当你使用或打出基本牌时，若此时是你的回合内，你可以摸一张牌；否则，你可以弃置一名角色区域里的一张牌。",
    ["s4_longdan-invoke"] = "你可以发动“龙胆”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",

}

s4_lord_zhugeliang = sgs.General(extension, "s4_lord_zhugeliang$", "shu", 4, true, false, false, 3)

s4_xianxingDiscardCard = sgs.CreateSkillCard{
	name = "s4_xianxingDiscard",
    target_fixed = true,
    will_throw = false,
	on_use = function(self, room, source, targets)
		for _,id in sgs.qlist(self:getSubcards()) do
		    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName())
            reason.m_skillName = self:objectName()
            room:moveCardTo(sgs.Sanguosha:getCard(id), source, nil, sgs.Player_DiscardPile, reason)
            source:broadcastSkillInvoke("@recast")
            local log = sgs.LogMessage()
            log.type = "#UseCard_Recast"
            log.from = source
            log.card_str = sgs.Sanguosha:getCard(id):toString()
            room:sendLog(log)
            source:drawCards(1, "recast")
        end
	end
}
s4_xianxingDiscard = sgs.CreateViewAsSkill{
	name = "#s4_xianxingDiscard", 
	n = 999, 
	enabled_at_play = function(self, player)
		return  false
	end,
	enabled_at_response = function(self, player, pattern)
        return pattern == "@@s4_xianxingDiscard"
	end,
	view_filter = function(self, selected, to_select)
        for _, ca in sgs.list(selected) do
			if ca:getSuit() ~= to_select:getSuit() then return false end
		end
        local suits = sgs.Self:property("s4_xianxing"):toString():split(",")
        return not table.contains(suits,to_select:getSuitString())
    end,
	view_as = function(self, cards) 
        if #cards == 0 then return nil end
		local dummy = s4_xianxingDiscardCard:clone()
		dummy:addSubcards(cards)
		return dummy
	end
}
s4_xianxing = sgs.CreateTriggerSkill{
    name = "s4_xianxing",
    events = {sgs.Damage, sgs.Damaged, sgs.EventPhaseChanging},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if (event == sgs.Damage or event == sgs.Damaged) and player:hasSkill(self:objectName()) then
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if not p:isChained() then
                    targets:append(p)
                end
            end
            if targets:isEmpty() then return false end
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "s4_xianxing-invoke", true, true)
            if target then
                local record = player:property("s4_xianxingRecords"):toString()
                local records
                if (record) then
                    records = record:split(",")
                end
                room:setPlayerProperty(target, "s4_xianxing", sgs.QVariant(table.concat(records, ",")))
                local card = room:askForUseCard(target, "@@s4_xianxingDiscard", "@s4_xianxing-discard", 5, sgs.Card_MethodRecast, false)
                room:setPlayerProperty(target, "s4_xianxing", sgs.QVariant(""))
                if card then
                    for _,c in sgs.qlist(card:getSubcards()) do
                        if not table.contains(records,sgs.Sanguosha:getCard(c):getSuitString()) then
                            table.insert(records,sgs.Sanguosha:getCard(c):getSuitString())
                        end
                    end
                    room:setPlayerProperty(player, "s4_xianxingRecords", sgs.QVariant(table.concat(records, ",")))

                    for _, mark in sgs.list(player:getMarkNames()) do
                        if (string.startsWith(mark, "&s4_xianxing+#record") and player:getMark(mark) > 0) then
                            room:setPlayerMark(player, mark, 0)
                        end
                    end
                    local mark = "&s4_xianxing+#record"
                    for _, suit in ipairs(records) do
                        mark = mark .. "+" .. suit .. "_char"
                    end
                    room:setPlayerMark(player, mark.."-Clear", 1)

                else
                    local num = 0
                    if records then
                        num = #records
                    end
                    local x = 4 - num
                    player:drawCards(x, self:objectName())
                    room:setPlayerChained(target)
                end
            end
        elseif (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				for _, p in sgs.qlist(room:getAllPlayers()) do
					room:setPlayerProperty(p,"s4_xianxingRecords",sgs.QVariant())
				end
			end
		end
    end,
    can_trigger = function(self, target)
		return target
	end
}

s4_zhuochenVS = sgs.CreateViewAsSkill{
	name = "s4_zhuochen",
	view_as = function(self, cards)
		local fireattack = sgs.Sanguosha:cloneCard("fire_attack")
		fireattack:setSkillName("s4_zhuochen")
		fireattack:setFlags("s4_zhuochen")
		return fireattack
	end,
	enabled_at_play = function(self, player)
		return player:getMark("uses4_zhuochen-PlayClear") == 0
	end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "@@s4_zhuochen"
	end,
}
s4_zhuochen = sgs.CreateTriggerSkill{
	name = "s4_zhuochen",
	view_as_skill = s4_zhuochenVS,
	events = {sgs.CardUsed,sgs.Damage,sgs.CardFinished,sgs.Death},
	can_trigger = function(self, target)
		return target
	end ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:isKindOf("FireAttack") and (table.contains(use.card:getSkillNames(),"s4_zhuochen") or use.card:hasFlag("s4_zhuochen")) then
				room:addPlayerMark(player,"uses4_zhuochen-PlayClear")
                room:setPlayerMark(player, "s4_zhuochen-Clear", 0)
			end
		end
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("FireAttack") and (table.contains(damage.card:getSkillNames(),"s4_zhuochen")) then
                room:addPlayerMark(player, "s4_zhuochen-Clear")
			end
		end
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:isKindOf("FireAttack") and (table.contains(use.card:getSkillNames(),"s4_zhuochen")) and player:hasSkill(self:objectName()) then
                if use.card:hasFlag("DamageDone") then
                    room:setPlayerFlag(player, "s4_zhuochen")
                    room:askForUseCard(player,"@@s4_zhuochen","@s4_zhuochen")
                end
                room:setPlayerFlag(player, "-s4_zhuochen")
				room:setPlayerMark(player, "s4_zhuochen-Clear", 0)
			end
		end
        if (event == sgs.Death) then
            local death = data:toDeath()
            if death.who:objectName() ~= player:objectName() then return false end
            if not player:hasSkill(self:objectName()) then return false end
            room:askForUseCard(player,"@@s4_zhuochen","@s4_zhuochen")
        end
	end ,
}
s4_zhuochen_buff = sgs.CreateTargetModSkill{
	name = "#s4_zhuochen_buff",
	pattern = "FireAttack",
    extra_target_func = function(self,from,card)--目标数
		if not from:hasFlag("s4_zhuochen")
		and from:hasSkill("s4_zhuochen") then return 999 end
		if from:hasFlag("s4_zhuochen")
		and from:hasSkill("s4_zhuochen") then return from:getMark("s4_zhuochen-Clear") end
		return 0
	end
}

s4_chenzhu = sgs.CreateTriggerSkill {
	name = "s4_chenzhu$",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.PreHpRecover },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        local recover = data:toRecover()
        if recover.recover >= player:getLostHp() then
            local lieges = room:getLieges("shu", player)
            if player:getKingdom() == "shu" then
                lieges:append(player)
            end
            local others = room:askForPlayersChosen(player, lieges, self:objectName(), 0, 99, "@s4_chenzhu", true, true)
            if others and others:length() > 0 then
                room:broadcastSkillInvoke("s4_chenzhu")
                for _,p in sgs.qlist(others) do
                    p:drawCards(2, self:objectName())
                end
                return true
            end
		end
	end,
}

s4_lord_zhugeliang:addSkill(s4_xianxing)
s4_lord_zhugeliang:addSkill(s4_zhuochen)
s4_lord_zhugeliang:addSkill(s4_zhuochen_buff)
extension:insertRelatedSkills("s4_zhuochen","#s4_zhuochen_buff")
s4_lord_zhugeliang:addSkill(s4_chenzhu)

if not sgs.Sanguosha:getSkill("#s4_xianxingDiscard") then
	s4_skillList:append(s4_xianxingDiscard)
end
--https://tieba.baidu.com/p/9767592768
sgs.LoadTranslationTable {
    ["s4_lord_zhugeliang"] = "主诸葛亮",
    ["&s4_lord_zhugeliang"] = "主诸葛亮",
    ["#s4_lord_zhugeliang"] = "大梦谁先觉",
    ["~s4_lord_zhugeliang"] = "",
    ["designer:s4_lord_zhugeliang"] = "鋁",
    ["cv:s4_lord_zhugeliang"] = "",
    ["illustrator:s4_lord_zhugeliang"] = "",

    ["s4_xianxing"] = "衔星",
    ["s4_xianxingdis"] = "衔星",
    ["s4_xianxingDiscard"] = "衔星",
    [":s4_xianxing"] = "<font color=\"green\"><b>每回合每种花色限重铸一张，</b></font>你造成或受到伤害后，可以令一名未横置的角色重铸任意张牌：若其不能重铸，你摸此技能剩余花色数张牌，横置其。",
    ["s4_xianxing-invoke"] = "你可以发动“衔星”<br/> <b>操作提示</b>: 选择一名未横置的角色→点击确定<br/>",
    ["@s4_xianxing-discard"] = "衔星: 你可以重铸任意张牌",
    ["s4_zhuochen"] = "灼辰",
    [":s4_zhuochen"] = "<font color=\"green\"><b>出牌阶段限一次</b></font>或当你死亡时，你可以连续视为使用【火攻】，首张无目标数限制，此后每张的目标数为上张造成的伤害值。",
    ["@s4_zhuochen"] = "灼辰: 你可以视为使用【火攻】",
    ["s4_chenzhu"] = "臣主",
    [":s4_chenzhu"] = "主公技，你回复体力至上限时，可以改为令任意名蜀势力角色各摸两张牌。",
    ["@s4_chenzhu"] = "臣主：你可以改为令任意名蜀势力角色各摸两张牌。",

}

s4_liuguanzhang = sgs.General(extension, "s4_liuguanzhang", "shu", 8)

s4_xingyiCard = sgs.CreateSkillCard {
	name = "s4_xingyi",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
        if sgs.Self:getMark("s4_yanshi") > 1 or sgs.Sanguosha:getCurrentCardUsePattern() == "@@s4_xingyi" then
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            slash:deleteLater()
            local plist = sgs.PlayerList()
            for i = 1, #targets, 1 do
                plist:append(targets[i])
            end
            return slash:targetFilter(plist, to_select, sgs.Self)
        else
            return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
        end
	end,
    feasible = function(self,targets,player)
        if player:getMark("s4_yanshi") > 1 or sgs.Sanguosha:getCurrentCardUsePattern() == "@@s4_xingyi" then
            local plist = sgs.PlayerList()
            for i = 1,#targets do plist:append(targets[i]) end
            local dc = dummyCard("slash","s4_xingyi")
            if dc then
                if dc:targetFixed() then return true end
                return dc:targetsFeasible(plist,player)
            end
        end
        return #targets > 0
	end,
    on_validate = function(self,use)
		local yuji = use.from
		local room = yuji:getRoom()
        if yuji:getMark("s4_yanshi") > 1 or sgs.Sanguosha:getCurrentCardUsePattern() == "@@s4_xingyi" then
            local use_card = dummyCard("slash")
            use_card:setSkillName("s4_xingyi")
            room:setCardFlag(use_card, "RemoveFromHistory")
            if self:subcardsLength() == 0 and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
                local result = room:askForChoice(yuji, self:objectName(), "hp+maxhp")
                if result == "hp" then
                    room:loseHp(yuji, 1, true, yuji, self:objectName())
                else
                    room:loseMaxHp(yuji)
                end
            end
            return use_card
        else
            return use.card
        end
	end,
    on_effect = function(self, effect)
        local room = effect.from:getRoom()
        if effect.from:getMark("s4_yanshi") < 2 then
            if effect.from:getMark("s4_yanshi") > 0 then
                room:giveCard(effect.from,effect.to,self,"s4_xingyi",true)
            else
                room:giveCard(effect.from,effect.to,self,"s4_xingyi",false)
            end
            room:askForUseCard(effect.from, "@@s4_xingyi", "@s4_xingyi")
        end
    end,
}
s4_xingyiVS = sgs.CreateViewAsSkill {
	name = "s4_xingyi",
	n = 1,
    response_pattern = "@@s4_xingyi",
    view_filter = function(self, selected, to_select)
        if sgs.Sanguosha:getCurrentCardUsePattern() == "@@s4_xingyi" then return false end
        if sgs.Self:getMark("s4_yanshi") > 1 then return false end
        return to_select:isBlack() and sgs.Self:getMark("s4_yanshi") > 0 or sgs.Self:getMark("s4_yanshi") == 0
    end,
	view_as = function(self, cards) 
		local dummy = s4_xingyiCard:clone()
        if sgs.Sanguosha:getCurrentCardUsePattern() == "@@s4_xingyi" then
        else
            if #cards > 0 then
                dummy:addSubcard(cards[1])
            end
            if sgs.Self:getMark("s4_yanshi") < 2 and #cards == 0 then return nil end
        end
        
		return dummy
	end,
	enabled_at_play = function(self, player)
		if player:getMark("s4_xingyi-PlayClear") == 0 then
			return true
		end
		return false
	end
}
s4_xingyi = sgs.CreateTriggerSkill {
	name = "s4_xingyi",
	frequency = sgs.Skill_NotFrequent,
	events = { sgs.Dying },
	view_as_skill = s4_xingyiVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.Dying then
            local current = room:getCurrent()
            if not current or current:getPhase() ~= sgs.Player_Play then return false end
            local dying = data:toDying()
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                room:addPlayerMark(p, "s4_xingyi-PlayClear")
            end
		end
	end,
	can_trigger = function(self, target)
		return target
	end
}
s4_yanshi = sgs.CreateTriggerSkill {
	name = "s4_yanshi",
	events = { sgs.HpChanged, sgs.MaxHpChanged },
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getLostHp() >= 2 then
            if player:getMark("s4_yanshi") < 2 then
                room:addPlayerMark(player,"s4_yanshi")
                room:changeTranslation(player,"s4_xingyi",player:getMark("s4_yanshi"))
                room:loseMaxHp(player, 2, self:objectName())
                local log = sgs.LogMessage()
                log.type = "#JiexunChange"
                log.from = player
                log.arg = "s4_xingyi"
                room:sendLog(log)
            end
        end 
	end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}


s4_liuguanzhang:addSkill(s4_xingyi)
s4_liuguanzhang:addSkill(s4_yanshi)

sgs.LoadTranslationTable {
    ["s4_liuguanzhang"] = "刘备&关羽&张飞",
    ["&s4_liuguanzhang"] = "刘关张",
    ["#s4_liuguanzhang"] = "桃园结义",
    ["~s4_liuguanzhang"] = "",
    ["designer:s4_liuguanzhang"] = "企鹅🐧爱你如初",
    ["cv:s4_liuguanzhang"] = "",
    ["illustrator:s4_liuguanzhang"] = "LEO",

    ["s4_xingyi"] = "行义",
    ["s4_xingyi:hp"] = "失去1点体力",
    ["s4_xingyi:maxhp"] = "减1点体力上限",
    ["s4_xingyi-invoke"] = "你发动“行义”，将一张牌交给其他角色<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
    [":s4_xingyi"] = "出牌阶段，若本阶段没有角色进入过濒死，你可以将一张牌交给其他角色，视为使用一张【杀】。",
    [":s4_xingyi1"] = "出牌阶段，若本阶段没有角色进入过濒死，你可以将一张黑色牌交给其他角色，视为使用一张【杀】。",
    [":s4_xingyi2"] = "出牌阶段，若本阶段没有角色进入过濒死，你可以失去1点体力或减1点体力上限，视为使用一张【杀】。",
    ["@s4_xingyi"] = "行义：视为使用一张【杀】",
    ["s4_yanshi"] = "雁逝",
    [":s4_yanshi"] = "锁定技，<font color=\"green\"><b>每局游戏限两次，</b></font>当你已损失体力值不少于2时，减2点体力上限，然后依次修改“行义”：1.将“牌”修改为“黑色牌”；2.“将一张黑色牌交给其他角色”修改为“失去1点体力或减1点体力上限”。",

}

s4_s_xiliangjun = sgs.General(extension_soldier, "s4_s_xiliangjun", "shu", 4)

s4_s_changqiang = sgs.CreateTriggerSkill{
    name = "s4_s_changqiang",
    events = {sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getWeapon() then return false end
        if player:getPhase() ~= sgs.Player_NotActive then return false end
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        elseif event == sgs.CardResponded then
            card = data:toCardResponse().m_card
        end
        if card and card:isBlack() then
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "s4_s_changqiang-invoke", true, true)
            if target then
                local jink = room:askForCard(target, "jink", "@s4_s_changqiang:"..player:objectName(), data, sgs.Card_MethodResponse, player, false, self:objectName(), false, nil)
                if not jink then
                    room:loseHp(target, 1, true, player, self:objectName())
                end
            end
        end
        return false
    end,
}

s4_s_jixing = sgs.CreateTargetModSkill{
    name = "s4_s_jixing",
    pattern = "TrickCard",
    distance_limit_func = function(self, from, card, to)
        if from:hasSkill("s4_s_jixing") and (from:getOffensiveHorse() ~= nil or from:getDefensiveHorse() ~= nil) then return 1000 end
        return 0
    end,
}

s4_s_xiliangjun:addSkill(s4_s_changqiang)
s4_s_xiliangjun:addSkill(s4_s_jixing)
sgs.LoadTranslationTable {
    ["s4_s_xiliangjun"] = "西凉军",
    ["&s4_s_xiliangjun"] = "西凉军",
    ["#s4_s_xiliangjun"] = "势如破竹",
    ["~s4_s_xiliangjun"] = "",
    ["designer:s4_s_xiliangjun"] = "",
    ["cv:s4_s_xiliangjun"] = "",
    ["illustrator:s4_s_xiliangjun"] = "",

    ["s4_s_changqiang"] = "长枪",
    [":s4_s_changqiang"] = "当你没装备武器时，你的回合外，当你使用或打出一张黑色牌，你可以令一名其他角色打出一张【闪】，否则失去1点体力。",
    ["s4_s_changqiang-invoke"] = "你可以发动“长枪”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
    ["@s4_s_changqiang"] = "长枪: %src 令你打出一张【闪】，否则失去1点体力",

    ["s4_s_jixing"] = "急行",
    [":s4_s_jixing"] = "锁定技，当你装备马时，你使用锦囊牌无距离限制。",
}

s4_s_wudangfeijun = sgs.General(extension_soldier, "s4_s_wudangfeijun", "shu", 3)

s4_s_yuanshe = sgs.CreateTriggerSkill{
    name = "s4_s_yuanshe",
    events = {sgs.EventPhaseChanging, sgs.DamageCaused},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge) and not player:isSkipped(sgs.Player_Draw) then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())
                    player:skip(sgs.Player_Judge)
                    player:skip(sgs.Player_Draw)
                    local card = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)
                    card:setSkillName(self:objectName())
                    card:deleteLater()
                    local use = sgs.CardUseStruct()
                    use.card = card
                    use.from = player
                    room:useCard(use)
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("ArcheryAttack") and damage.card:getSkillName() == self:objectName() then
                damage.nature = sgs.DamageStruct_Thunder
                data:setValue(damage)
            end
        end
        return false
    end,
}

s4_s_sizhan = sgs.CreateTargetModSkill{
    name = "s4_s_sizhan",
    pattern = "Slash",
    residue_func = function(self, from, card, to)
        if from:hasSkill("s4_s_sizhan") and from:getHp() == 1 and from:getPhase() == sgs.Player_Play then return 1000 end
        return 0
    end,
}

s4_s_wudangfeijun:addSkill(s4_s_yuanshe)
s4_s_wudangfeijun:addSkill(s4_s_sizhan)

sgs.LoadTranslationTable {
    ["s4_s_wudangfeijun"] = "无当飞军",
    ["&s4_s_wudangfeijun"] = "无当飞军",
    ["#s4_s_wudangfeijun"] = "飞箭如雨",
    ["~s4_s_wudangfeijun"] = "",
    ["designer:s4_s_wudangfeijun"] = "",
    ["cv:s4_s_wudangfeijun"] = "",
    ["illustrator:s4_s_wudangfeijun"] = "",
    ["s4_s_yuanshe"] = "远射",
    [":s4_s_yuanshe"] = "你可以跳过你的判定阶段和摸牌阶段，视为你使用一张【万箭齐发】，该【万箭齐发】造成雷电伤害。",
    ["s4_s_sizhan"] = "死战",
    [":s4_s_sizhan"] = "若你的体力值为1时，出牌阶段，你可以使用任意数量的【杀】。",
}


s4_s_baierbing = sgs.General(extension_soldier, "s4_s_baierbing", "shu", 4)

s4_s_youdiCard = sgs.CreateSkillCard{
    name = "s4_s_youdi",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return #targets == 0 and to_select:objectName() ~= player:objectName() and player:inMyAttackRange(to_select)
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        if room:askForUseSlashTo(target, source, "@s4_s_youdi-slash:"..source:objectName(), false, false, false, source, nil, "s4_s_youdi") then
        else
            room:loseHp(target, 1, true, source, "s4_s_youdi")
            target:drawCards(1, "s4_s_youdi")
        end
    end,
}

s4_s_youdiVS = sgs.CreateZeroCardViewAsSkill{
    name = "s4_s_youdi",
    view_as = function(self, cards)
        return s4_s_youdiCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#s4_s_youdi")
    end,
}
s4_s_youdi = sgs.CreateTriggerSkill{
    name = "s4_s_youdi",
    view_as_skill = s4_s_youdiVS,
    events = {sgs.CardOffset},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local effect = data:toCardEffect()
        if effect.offset_card and effect.to and effect.to:hasSkill(self:objectName()) and effect.card:hasFlag("s4_s_youdi") then
            effect.to:drawCards(2, self:objectName())
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}

s4_s_jianshou = sgs.CreateProhibitSkill{
    name = "s4_s_jianshou",
    is_prohibited = function(self, from, to, card)
        if to:hasSkill(self:objectName()) and card and (card:isKindOf("SupplyShortage") or card:isKindOf("IronChain")) then
            if to:getArmor() then
                return true
            end
        end
        return false
    end,
}


s4_s_baierbing:addSkill(s4_s_youdi)
s4_s_baierbing:addSkill(s4_s_jianshou)

sgs.LoadTranslationTable {
    ["s4_s_baierbing"] = "白耳兵",
    ["&s4_s_baierbing"] = "白耳兵",
    ["#s4_s_baierbing"] = "战功赫赫",
    ["~s4_s_baierbing"] = "",
    ["designer:s4_s_baierbing"] = "",
    ["cv:s4_s_baierbing"] = "",
    ["illustrator:s4_s_baierbing"] = "",
    ["@s4_s_youdi-slash"] = "诱敌：你可以对 %src 使用一张【杀】否则失去1点体力摸一张牌",
    ["s4_s_youdi"] = "诱敌",
    [":s4_s_youdi"] = "出牌阶段限一次，你可以选择你攻击范围内的一名其他角色，令该角色选择一项：对你使用一张【杀】，若你使用【闪】响应此【杀】，则你摸两张牌；失去1点体力摸一张牌。",
    ["s4_s_jianshou"] = "坚守",
    [":s4_s_jianshou"] = "锁定技，当你装备区内有防具牌时，你不能成为【兵粮寸断】和【铁索连环】的目标。",
}

s4_s_yexiaxing = sgs.General(extension_soldier, "s4_s_yexiaxing", "shu", 3)

s4_s_yexi = sgs.CreateTriggerSkill{
    name = "s4_s_yexi",
    events = {sgs.CardFinished},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card and use.card:isKindOf("Slash") and use.card:isBlack() and use.card:hasFlag("DamageDone") then
            for _, p in sgs.qlist(use.to) do
                if player:canDiscard(p, "h") and room:askForSkillInvoke(player, self:objectName(), ToData(p)) then
                    room:broadcastSkillInvoke(self:objectName())
                    local id = room:askForCardChosen(player, p, "h", self:objectName())
                    room:throwCard(id, p, player)
                end
            end
        end
        return false
    end,
    
}

s4_s_touxi = sgs.CreateTriggerSkill{
    name = "s4_s_touxi",
    events = {sgs.CardUsed, sgs.CardResponded},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local card
        if event == sgs.CardUsed then
            card = data:toCardUse().card
        elseif event == sgs.CardResponded then
            card = data:toCardResponse().m_card
        end
        if card and card:isKindOf("Jink") then
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:inMyAttackRange(p) then
                    targets:append(p)
                end
            end
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(player, targets, self:objectName(), "s4_s_touxi-invoke", true, true)
                if target then
                    local damage = sgs.DamageStruct()
                    damage.from = player
                    damage.to = target
                    damage.damage = 1
                    damage.nature = sgs.DamageStruct_Fire
                    damage.card = card
                    room:damage(damage)
                end
            end
        end
        return false
    end,
}

s4_s_yexiaxing:addSkill(s4_s_yexi)
s4_s_yexiaxing:addSkill(s4_s_touxi)

sgs.LoadTranslationTable {
    ["s4_s_yexiaxing"] = "夜叉行",
    ["&s4_s_yexiaxing"] = "夜叉行",
    ["#s4_s_yexiaxing"] = "夤夜之影",
    ["~s4_s_yexiaxing"] = "",
    ["designer:s4_s_yexiaxing"] = "",
    ["cv:s4_s_yexiaxing"] = "",
    ["illustrator:s4_s_yexiaxing"] = "",
    ["s4_s_yexi"] = "夜袭",
    [":s4_s_yexi"] = "当你使用黑色【杀】造成伤害，则结算完成后，你可以弃置目标角色一张手牌。",
    ["s4_s_touxi-invoke"] = "你可以发动“偷袭”<br/> <b>操作提示</b>: 选择你攻击范围内的一名其他角色→点击确定<br/>",
    ["s4_s_touxi"] = "偷袭",
    [":s4_s_touxi"] = "每当你使用或打出一张【闪】时，你可以对攻击范围内一名其他角色造成1点火焰伤害。。",
}


s4_s_nanmandajun = sgs.General(extension_soldier, "s4_s_nanmandajun", "shu", 4)

s4_s_ruqin = sgs.CreateTriggerSkill{
    name = "s4_s_ruqin",
    events = {sgs.EventPhaseStart, sgs.CardUsed},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then
                local card = room:askForCard(player, "TrickCard|black", "@s4_s_ruqin", data, sgs.Card_MethodUse, player, false, self:objectName(), true, nil)
                if card then
                    local SavageAssault = sgs.Sanguosha:cloneCard("SavageAssault", card:getSuit(), card:getNumber())
                    SavageAssault:setSkillName(self:objectName())
                    SavageAssault:addSubcard(card)
                    SavageAssault:deleteLater()
                    local use = sgs.CardUseStruct()
                    use.card = SavageAssault
                    use.from = player
                    room:useCard(use)
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("SavageAssault") then
                room:setTag("s4_s_ruqin", data)
                local target = room:askForPlayerChosen(player, use.to, self:objectName(), "s4_s_ruqin-invoke", true, true)
                room:removeTag("s4_s_ruqin")
                if target then
                    local log = sgs.LogMessage()
                    log.type = "#SkillAvoidFrom"
                    log.from = player
                    log.to:append(target)
                    log.arg = self:objectName()
                    log.arg2 = use.card:objectName()
                    room:sendLog(log)
                    use.to:removeOne(target)
                    data:setValue(use)
                end
            end
        end
        return false
    end,
}

s4_s_tengjia = sgs.CreateViewAsEquipSkill{
    name = "s4_s_tengjia",
	view_as_equip = function(self,target)
		if target:getArmor() then
	    	return "vine"
		end
	end 
}
s4_s_tengjia_equip = sgs.CreateCardLimitSkill{
    name = "#s4_s_tengjia_equip",
    limit_list = function(self, player)
        if player:hasSkill("s4_s_tengjia") then 
            return "effect"
        else
            return ""
        end
    end,
    limit_pattern = function(self, player)
        if player:hasSkill("s4_s_tengjia") then 
            return "Armor|.|.|."
        end
    end,
}

s4_s_nanmandajun:addSkill(s4_s_ruqin)
-- s4_s_nanmandajun:addSkill(s4_s_tengjia)
-- s4_s_nanmandajun:addSkill(s4_s_tengjia_equip)
-- extension_soldier:insertRelatedSkills("s4_s_tengjia","#s4_s_tengjia_equip")

sgs.LoadTranslationTable {
    ["s4_s_nanmandajun"] = "南蛮大军",
    ["&s4_s_nanmandajun"] = "南蛮大军",
    ["#s4_s_nanmandajun"] = "凶猛如兽",
    ["~s4_s_nanmandajun"] = "",
    ["designer:s4_s_nanmandajun"] = "",
    ["cv:s4_s_nanmandajun"] = "",
    ["illustrator:s4_s_nanmandajun"] = "",
    ["@s4_s_ruqin"] = "入侵: 你可以将一张黑色锦囊牌当【南蛮入侵】使用",
    ["s4_s_ruqin-invoke"] = "你可以发动“入侵”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
    ["s4_s_ruqin"] = "入侵",
    [":s4_s_ruqin"] = "回合开始阶段和回合结束阶段，你可以将一张黑色锦囊牌当【南蛮入侵】使用；当你使用【南蛮入侵】时，你可以声明一名其他角色不成为【南蛮入侵】的目标。",
    ["s4_s_tengjia"] = "藤甲",
    [":s4_s_tengjia"] = "锁定技，你所装备的任何防具，都视为【藤甲】。",
    --TODO
}

s4_s_yulinwei = sgs.General(extension_soldier, "s4_s_yulinwei", "wu", 4)

s4_s_wanqiang = sgs.CreateTriggerSkill{
    name = "s4_s_wanqiang",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:sendCompulsoryTriggerLog(player, self:objectName(), true)
        if player:canDiscard(player, "he") then
        room:askForDiscard(player, self:objectName(), 1, 1, false, true)
        if room:askForSkillInvoke(player, self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            local judge = sgs.JudgeStruct()
            judge.who = player
            judge.pattern = ".|red"
            judge.good = true
            judge.reason = self:objectName()
            room:judge(judge)
            if judge:isGood() then
                room:recover(player,sgs.RecoverStruct(self:objectName(),player, 1))
            end
        end
        end
        return false
    end,
}

s4_s_gedang = sgs.CreateTriggerSkill{
    name = "s4_s_gedang",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.damage > 1 then
            room:broadcastSkillInvoke(self:objectName())
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
            damage.damage = 1
            data:setValue(damage)
        end
        return false
    end,
}

s4_s_yulinwei:addSkill(s4_s_wanqiang)
s4_s_yulinwei:addSkill(s4_s_gedang)

sgs.LoadTranslationTable {
    ["s4_s_yulinwei"] = "羽林卫",
    ["&s4_s_yulinwei"] = "羽林卫",
    ["#s4_s_yulinwei"] = "固若金汤",
    ["~s4_s_yulinwei"] = "",
    ["designer:s4_s_yulinwei"] = "",
    ["cv:s4_s_yulinwei"] = "",
    ["illustrator:s4_s_yulinwei"] = "",
    ["s4_s_wanqiang"] = "顽强",
    [":s4_s_wanqiang"] = "当你进入濒死状态时，你需要弃置一张牌，然后你可以进行一次判定，若为红色，你回复1点体力。",
    ["s4_s_gedang"] = "格挡",
    [":s4_s_gedang"] = "锁定技，当你受到伤害时，若此伤害大于1点，则伤害减至1点。",
}

s4_s_duchilinguan = sgs.General(extension_soldier, "s4_s_duchilinguan", "wu", 3)

s4_s_dujian = sgs.CreateTriggerSkill{
    name = "s4_s_dujian",
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card and use.card:isKindOf("Slash") and use.to:length() == 1 then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local judge = sgs.JudgeStruct()
                judge.who = player
                judge.pattern = ".|"..use.card:getSuitString()
                judge.good = true
                judge.reason = self:objectName()
                judge.throw_card = false
                room:judge(judge)
                if judge:isGood() then
                    room:broadcastSkillInvoke(self:objectName())
                    local target = use.to:first()
                    room:notifySkillInvoked(player, self:objectName())
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:doAnimate(1, player:objectName(), target:objectName())
                    target:turnOver()
                    room:obtainCard(target, judge.card, false)
                    local nullified_list = use.nullified_list
                    table.insert(nullified_list, "_ALL_TARGETS")
                    use.nullified_list = nullified_list
                    data:setValue(use)
                end
            end
        end
        return false
    end,
}

s4_s_roubo = sgs.CreateTriggerSkill{
    name = "s4_s_roubo",
    events = {sgs.Damaged},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if player:isKongcheng() and damage.from and damage.from:isAlive() then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
            room:broadcastSkillInvoke(self:objectName())
            room:loseHp(damage.from, 1, true, player, self:objectName())
        end
        return false
    end,
}

s4_s_duchilinguan:addSkill(s4_s_dujian)
s4_s_duchilinguan:addSkill(s4_s_roubo)

sgs.LoadTranslationTable {
    ["s4_s_duchilinguan"] = "毒齿林官",
    ["&s4_s_duchilinguan"] = "毒齿林官",
    ["#s4_s_duchilinguan"] = "阴毒至骨",
    ["~s4_s_duchilinguan"] = "",
    ["designer:s4_s_duchilinguan"] = "",
    ["cv:s4_s_duchilinguan"] = "",
    ["illustrator:s4_s_duchilinguan"] = "",
    ["s4_s_dujian"] = "毒箭",
    [":s4_s_dujian"] = "当你使用【杀】指定唯一目标后，你可以进行一次判定，判定结果的花色与你使用的【杀】的花色相同，此【杀】无效，该角色武将牌翻面并获得判定牌。",
    ["s4_s_roubo"] = "肉搏",
    [":s4_s_roubo"] = "锁定技，每当你受到一次伤害后，若你没有手牌，伤害来源失去1点体力。",
}


s4_s_suweihuqi = sgs.General(extension_soldier, "s4_s_suweihuqi", "wu", 4)

s4_s_jianta = sgs.CreateTriggerSkill{
    name = "s4_s_jianta",
    events = {sgs.CardUsed, sgs.DamageCaused},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") and use.from:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play then
                if room:askForCard(player, ".|"..use.card:getSuitString().."|.|hand" , "@s4_s_jianta:"..use.card:getSuitString(), data, sgs.Card_MethodDiscard, player, false, self:objectName(), false, nil) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:setCardFlag(use.card, "s4_s_jianta")
                end
            end
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:isKindOf("Slash") and damage.card:hasFlag("s4_s_jianta") then
                damage.damage = damage.damage + 1
                data:setValue(damage)
                local log = sgs.LogMessage()
                log.type = "#skill_add_damage"
                log.from = player
                log.to:append(damage.to)
                log.arg2 = damage.damage
                log.arg = self:objectName()
                room:sendLog(log)
            end
        end
        return false
    end,
}

s4_s_mading = sgs.CreateProhibitSkill{
    name = "s4_s_mading",
    is_prohibited = function(self, from, to, card)
        if to:hasSkill(self:objectName()) and card and (card:isKindOf("FireAttack") or card:isKindOf("Duel")) then
            if to:getOffensiveHorse() or to:getDefensiveHorse() then
                return true
            end
        end
        return false
    end,
}

s4_s_suweihuqi:addSkill(s4_s_jianta)
s4_s_suweihuqi:addSkill(s4_s_mading)

sgs.LoadTranslationTable {
    ["s4_s_suweihuqi"] = "宿卫虎骑",
    ["&s4_s_suweihuqi"] = "宿卫虎骑",
    ["#s4_s_suweihuqi"] = "势不可挡",
    ["~s4_s_suweihuqi"] = "",
    ["designer:s4_s_suweihuqi"] = "",
    ["cv:s4_s_suweihuqi"] = "",
    ["illustrator:s4_s_suweihuqi"] = "",
    ["@s4_s_jianta"] = "践踏：你可以弃置一张 %src 手牌，令此【杀】伤害+1",
    ["s4_s_jianta"] = "践踏",
    [":s4_s_jianta"] = "当你于出牌阶段使用【杀】时，你可以弃置一张与【杀】花色相同的手牌，令此【杀】伤害+1。",
    ["s4_s_mading"] = "马锭",
    [":s4_s_mading"] = "锁定技，当你装备马时，你不能成为【火攻】和【决斗】的目标。",
}

s4_s_danyangbing = sgs.General(extension_soldier, "s4_s_danyangbing", "wu", 4)

s4_s_peifa = sgs.CreateTriggerSkill{
    name = "s4_s_peifa",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Draw and room:askForSkillInvoke(player, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
            local ids = room:getNCards(4)
            local cards = sgs.IntList()
            for _, id in sgs.qlist(ids) do
                cards:append(id)
            end
            room:fillAG(cards, player)
            local to_gain = sgs.IntList()
            local to_obtain = sgs.IntList()
            local to_throw = sgs.IntList()
            for _, id in sgs.qlist(cards) do
                local card = sgs.Sanguosha:getCard(id)
                if (card:isKindOf("EquipCard") or (card:isKindOf("BasicCard") and card:isRed())) then
                    to_gain:append(id)
                else
                    to_throw:append(id)
                end
            end
            room:clearAG(player)
            if to_gain:length() > 2 then
                room:fillAG(cards, player, to_throw)
                for i = 1, 2 do
                    local id = room:askForAG(player, to_gain, false, self:objectName())
                    to_obtain:append(id)
                    to_gain:removeOne(id)
                end
                room:clearAG(player)
            else
                to_obtain = to_gain
            end
            
            if not to_obtain:isEmpty() then
                room:showCard(player, to_obtain)
                local move = sgs.CardsMoveStruct()
                move.card_ids = to_obtain
                move.to = player
                move.to_place = sgs.Player_PlaceHand
                move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GOTCARD, player:objectName(), self:objectName(), "")
                room:moveCardsAtomic(move, true)
            end
            if not to_throw:isEmpty() then
                local move = sgs.CardsMoveStruct()
                move.card_ids = to_throw
                move.to = nil
                move.to_place = sgs.Player_DiscardPile
                move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, player:objectName(), self:objectName(), "")
                room:moveCardsAtomic(move, true)
            end
            return true
        end
        return false
    end,
}
s4_s_zhongzhuang_limit = sgs.CreateCardLimitSkill{
    name = "#s4_s_zhongzhuang_limit",
    limit_list = function(self, player)
        if player:hasSkill("s4_s_zhongzhuang") then 
            return "discard"
        else
            return ""
        end
    end,
    limit_pattern = function(self, player, card)
        if card:isKindOf("Horse") or card:isKindOf("Treasure") then return "" end
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            if p:hasSkill("s4_s_zhongzhuang") then 
                if p:getEquipsId():contains(card:getId()) then
                    return card:toString()
        end
            end
        end
        return ""
    end,
}


s4_s_zhongzhuang = sgs.CreateTriggerSkill{
    name = "s4_s_zhongzhuang",
    events = { sgs.BeforeCardsMove, sgs.CardsMoveOneTime },

    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local move = data:toMoveOneTime()
        if event == sgs.BeforeCardsMove then
            local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceEquip) and move.reason.m_skillName~="BreakCard"
			and move.from:objectName()==player:objectName() then
                local reason = move.reason.m_reason
                if reason ~= sgs.CardMoveReason_S_REASON_CHANGE_EQUIP then
                    for i,id in sgs.list(move.card_ids)do
                        if move.from_places:at(i)==sgs.Player_PlaceEquip
                        and sgs.Sanguosha:getCard(id):isKindOf("Weapon") or sgs.Sanguosha:getCard(id):isKindOf("Armor") then
                            local ids = sgs.IntList()
                            ids:append(id)
                            move:removeCardIds(ids)
                            data:setValue(move)
                            room:breakCard(id,player)
                            player:setTag("s4_s_zhongzhuang"..sgs.Sanguosha:getEngineCard(id):getRealCard():toEquipCard():location(), sgs.QVariant(id))
                        end
                    end
                end
            end
        elseif event == sgs.CardsMoveOneTime then
            if player:hasFlag("s4_s_zhongzhuangUsing") then return false end
            -- if not move.from then return false end
            -- if move.from:objectName() ~= player:objectName() then return false end
            -- if not move.from_places:contains(sgs.Player_PlaceEquip) then return false end
            local reason = move.reason.m_reason
            if reason ~= sgs.CardMoveReason_S_REASON_CHANGE_EQUIP then
                local id = player:getTag("s4_s_zhongzhuang0"):toInt()
                if id and id ~= 0 then
                    room:setPlayerFlag(player, "s4_s_zhongzhuangUsing")
                    local equip = sgs.Sanguosha:getCard(id)
                    local i = sgs.Sanguosha:getEngineCard(id):getRealCard():toEquipCard():location()
                    if player:hasEquipArea(i) then
                        if player:getEquip(i) then
                            local ids = sgs.IntList()
                            ids:append(player:getEquip(i):getId())
                            local move2 = sgs.CardsMoveStruct()
                            move2.card_ids = ids
                            move2.to = nil
                            move2.to_place = sgs.Player_DiscardPile
                            move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP, player:objectName())
                            room:moveCardsAtomic(move2, true)
                        end
                        room:moveCardTo(equip, player, sgs.Player_PlaceEquip, true)
                    end
                    room:setPlayerFlag(player, "-s4_s_zhongzhuangUsing")
                    player:removeTag("s4_s_zhongzhuang0")
                end
                local id = player:getTag("s4_s_zhongzhuang1"):toInt()
                if id and id ~= 0 then
                    room:setPlayerFlag(player, "s4_s_zhongzhuangUsing")
                    local equip = sgs.Sanguosha:getCard(id)
                    local i = sgs.Sanguosha:getEngineCard(id):getRealCard():toEquipCard():location()
                    if player:hasEquipArea(i) then
                        if player:getEquip(i) then
                            local ids = sgs.IntList()
                            ids:append(player:getEquip(i):getId())
                            local move2 = sgs.CardsMoveStruct()
                            move2.card_ids = ids
                            move2.to = nil
                            move2.to_place = sgs.Player_DiscardPile
                            move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_CHANGE_EQUIP, player:objectName())
                            room:moveCardsAtomic(move2, true)
                        end
                        room:moveCardTo(equip, player, sgs.Player_PlaceEquip, true)
                        

                    end
                    room:setPlayerFlag(player, "-s4_s_zhongzhuangUsing")
                    player:removeTag("s4_s_zhongzhuang1")
                end
            end
        end
    end,
}

s4_s_danyangbing:addSkill(s4_s_peifa)
s4_s_danyangbing:addSkill(s4_s_zhongzhuang)
s4_s_danyangbing:addSkill(s4_s_zhongzhuang_limit)
extension_soldier:insertRelatedSkills("s4_s_zhongzhuang","#s4_s_zhongzhuang_limit")

sgs.LoadTranslationTable {
    ["s4_s_danyangbing"] = "丹阳兵",
    ["&s4_s_danyangbing"] = "丹阳兵",
    ["#s4_s_danyangbing"] = "巍然如山",
    ["~s4_s_danyangbing"] = "",
    ["designer:s4_s_danyangbing"] = "",
    ["cv:s4_s_danyangbing"] = "",
    ["illustrator:s4_s_danyangbing"] = "",
    ["s4_s_peifa"] = "配发",
    [":s4_s_peifa"] = "摸牌阶段，你可以改为观看牌堆顶的四张牌，然后展示其中的装备牌和红色基本牌并最多获得两张，其余牌则弃置。",
    ["s4_s_zhongzhuang"] = "重装",
    [":s4_s_zhongzhuang"] = "锁定技，你装备区内的武器和防具牌，不能被移动或弃置。",
    --實際上是在卡牌移動時改為移出遊戲，然後移動後再裝上
    --[[ ["s4_s_zhongzhuang"] = "重装",
    [":s4_s_zhongzhuang"] = "锁定技，你装备区内的武器和防具牌，不能成为卡牌，武器特效或武将技能的目标。", ]]
    --TODO 不能被移动 CreateCardLimitSkill
}

s4_s_jiaoejun = sgs.General(extension_soldier, "s4_s_jiaoejun", "wu", 4)

s4_s_zhanchuan_distance = sgs.CreateDistanceSkill{
    name = "#s4_s_zhanchuan_distance",
    correct_func = function(self, from, to)
        if from:hasSkill("s4_s_zhanchuan") and from:getPile("s4_s_zhanchuan"):length() > 0 then
            return -2
        end
        return 0
    end,
}
s4_s_zhanchuan_prohibit = sgs.CreateProhibitSkill{
    name = "#s4_s_zhanchuan_prohibit",
    is_prohibited = function(self, from, to, card)
        if from:hasSkill("s4_s_zhanchuan") and from:getPile("s4_s_zhanchuan"):length() > 0 then
            if card and (card:isKindOf("ArcheryAttack") or card:isKindOf("SupplyShortage")) then
                return true
            end
        end
        return false
    end,
}

s4_s_zhanchuanCard = sgs.CreateSkillCard{
    name = "s4_s_zhanchuan",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        source:addToPile("s4_s_zhanchuan", self:getSubcards())
    end,
}

s4_s_zhanchuanVS = sgs.CreateOneCardViewAsSkill{
    name = "s4_s_zhanchuan",
    filter_pattern = "BasicCard",
    view_as = function(self, card)
        local zhanchuan_card = s4_s_zhanchuanCard:clone()
        zhanchuan_card:addSubcard(card)
        return zhanchuan_card
    end,
    enabled_at_play = function(self, player)
        return player:getPile("s4_s_zhanchuan"):length() == 0
    end,
}

s4_s_zhanchuan = sgs.CreateTriggerSkill{
    name = "s4_s_zhanchuan",
    events = {sgs.Damaged, sgs.PreCardUsed},
    view_as_skill = s4_s_zhanchuanVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damaged then
            if player:getPile("s4_s_zhanchuan"):length() > 0 then
                room:broadcastSkillInvoke(self:objectName())
                room:sendCompulsoryTriggerLog(player, self:objectName(), true)
                player:clearOnePrivatePile("s4_s_zhanchuan")
            end
        elseif event == sgs.PreCardUsed then
            local use = data:toCardUse()
            if use.card and not use.card:isKindOf("SkillCard") and player:getPile("s4_s_zhanchuan"):length() > 0 then
                local log = sgs.LogMessage()
				log.type = "#IgnoreArmor"
				log.from = player
				log.card_str = use.card:toString()
				room:sendLog(log)
                player:addQinggangTag(use.card)
            end
        end
        return false
    end,
}


s4_s_jiaoejun:addSkill(s4_s_zhanchuan)
s4_s_jiaoejun:addSkill(s4_s_zhanchuan_distance)
s4_s_jiaoejun:addSkill(s4_s_zhanchuan_prohibit)
extension_soldier:insertRelatedSkills("s4_s_zhanchuan","#s4_s_zhanchuan_distance")
extension_soldier:insertRelatedSkills("s4_s_zhanchuan","#s4_s_zhanchuan_prohibit")

sgs.LoadTranslationTable {
    ["s4_s_jiaoejun"] = "蛟鳄军",
    ["&s4_s_jiaoejun"] = "蛟鳄军",
    ["#s4_s_jiaoejun"] = "岳镇渊停",
    ["~s4_s_jiaoejun"] = "",
    ["designer:s4_s_jiaoejun"] = "",
    ["cv:s4_s_jiaoejun"] = "",
    ["illustrator:s4_s_jiaoejun"] = "",
    ["s4_s_zhanchuan"] = "战船",
    [":s4_s_zhanchuan"] = "出牌阶段，你可以将一张基本牌置于你的武将牌上，称为“船”，当你有“船”时，你计算与所有其他角色的距离时-2；你无视目标角色的防具，你不能成为【万箭齐发】和【兵粮寸断】的目标，每当你受到伤害后，你须弃置“船”。你至多只能放置一张“船”。",
}

s4_s_qingzhoubing = sgs.General(extension_soldier, "s4_s_qingzhoubing", "wei", 4)

s4_s_weigong = sgs.CreateTriggerSkill{
    name = "s4_s_weigong",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.CardEffected, sgs.CardResponded, sgs.CardFinished},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.CardEffected then
            local effect = data:toCardEffect()
            local card = effect.card
            if card and card:isKindOf("Slash") then
                local target = effect.to
                if target and effect.from:hasSkill("s4_s_weigong") then
                    room:sendCompulsoryTriggerLog(effect.from, self:objectName(), true)
                    room:setPlayerCardLimitation(target, "use", "Jink|.|1~"..card:getNumber(), false)
                    room:setPlayerFlag(target, "s4_s_weigongSlash")
                    room:setCardFlag(card, "s4_s_weigong")
                end
            end
        elseif event == sgs.CardResponded then
            local resp = data:toCardResponse()
            if resp.m_toCard and resp.m_toCard:isKindOf("Duel") then
                if player:hasSkill("s4_s_weigong") then
                    local slash = resp.m_card
                    local target = resp.m_who
                    if target and slash and slash:isKindOf("Slash") then
                        room:sendCompulsoryTriggerLog(player, self:objectName(), true)
                        room:setCardFlag(resp.m_toCard, "s4_s_weigong")
                        if target:getMark("s4_s_weigongDuel-Clear") > 0 then
                            room:removePlayerCardLimitation(target, "response", "Slash|.|1~"..target:getMark("s4_s_weigongDuel-Clear"))
                        end
                        room:setPlayerCardLimitation(target, "response", "Slash|.|1~"..slash:getNumber(), false)
                        room:setPlayerMark(target, "s4_s_weigongDuel-Clear", slash:getNumber())
                    end
                end
            end
        elseif event == sgs.CardFinished then
            local card = data:toCardUse().card
            if card and card:hasFlag("s4_s_weigong") then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:hasFlag("s4_s_weigongSlash") then
                        room:setPlayerFlag(p, "-s4_s_weigongSlash")
                        room:removePlayerCardLimitation(p, "use", "Jink|.|1~"..card:getNumber())
                    end
                end
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark("s4_s_weigongDuel-Clear") > 0 then
                        room:removePlayerCardLimitation(p, "response", "Slash|.|1~"..p:getMark("s4_s_weigongDuel-Clear"))
                        room:setPlayerMark(p, "s4_s_weigongDuel-Clear", 0)
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

s4_s_qingzhoubing:addSkill(s4_s_weigong)

sgs.LoadTranslationTable {
    ["s4_s_qingzhoubing"] = "青州兵",
    ["&s4_s_qingzhoubing"] = "青州兵",
    ["#s4_s_qingzhoubing"] = "雄兵百万",
    ["~s4_s_qingzhoubing"] = "",
    ["designer:s4_s_qingzhoubing"] = "",
    ["cv:s4_s_qingzhoubing"] = "",
    ["illustrator:s4_s_qingzhoubing"] = "",
    ["s4_s_weigong"] = "围攻",
    [":s4_s_weigong"] = "锁定技，你使用【杀】时，目标角色必须使用点数大于【杀】的【闪】进行响应。决斗中，你打出【杀】时，目标角色必须打出点数大于你的【杀】。",
}

s4_s_hubaoqi = sgs.General(extension_soldier, "s4_s_hubaoqi", "wei", 4)

s4_s_zhuizhan = sgs.CreateTriggerSkill{
    name = "s4_s_zhuizhan",
    events = {sgs.Damaged},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.to and damage.to:isAlive() and damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel") or damage.card:isKindOf("FireAttack")) then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:inMyAttackRange(damage.to) and p:getPhase() == sgs.Player_NotActive then
                   room:askForUseSlashTo(p, damage.to, "@s4_s_zhuizhan:"..damage.to:objectName(), false, false, false, nil, nil)
                   if not damage.to:isAlive() then
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

s4_s_yuanzheng = sgs.CreateTargetModSkill{
    name = "s4_s_yuanzheng",
    pattern = "Slash",
    distance_limit_func = function(self, from, card)
        if from:hasSkill(self:objectName()) and (from:getOffensiveHorse() or from:getDefensiveHorse()) then
            return 1000
        end
        return 0
    end,
}

s4_s_hubaoqi:addSkill(s4_s_zhuizhan)
s4_s_hubaoqi:addSkill(s4_s_yuanzheng)

sgs.LoadTranslationTable {
    ["s4_s_hubaoqi"] = "虎豹骑",
    ["&s4_s_hubaoqi"] = "虎豹骑",
    ["#s4_s_hubaoqi"] = "战无不胜",
    ["~s4_s_hubaoqi"] = "",
    ["designer:s4_s_hubaoqi"] = "",
    ["cv:s4_s_hubaoqi"] = "",
    ["illustrator:s4_s_hubaoqi"] = "",
    ["@s4_s_zhuizhan"] = "追斩：你可以对 %src 使用一张【杀】",
    ["s4_s_zhuizhan"] = "追斩",
    [":s4_s_zhuizhan"] = "你的回合外，每当你攻击范围内的角色被【杀】、【决斗】或【火攻】造成伤害后，你可对该角色使用一张【杀】。",
    ["s4_s_yuanzheng"] = "远征",
    [":s4_s_yuanzheng"] = "锁定技，当你装备马时，你使用的【杀】无距离限制。",
}

s4_s_baibasishi = sgs.General(extension_soldier, "s4_s_baibasishi", "wei", 4)

s4_s_xuezhan = sgs.CreateTriggerSkill{
    name = "s4_s_xuezhan",
    events = {sgs.Damaged, sgs.FinishJudge},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.Damaged then
        local damage = data:toDamage()
        if damage.from and damage.from:isAlive() then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                local judge = sgs.JudgeStruct()
                judge.who = player
                judge.pattern = ".|diamond,club"
                    judge.good = true
                judge.reason = self:objectName()
                judge.throw_card = false
                room:judge(judge)
                if damage.from:hasJudgeArea() and judge:isGood() then
                        local id = player:getTag("s4_s_xuezhan"):toInt()
                        player:removeTag("s4_s_xuezhan")
                        
                    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "s4_s_xuezhan", "");
                    if judge.card:isRed() then
                        local indulgence = sgs.Sanguosha:cloneCard("indulgence", judge.card:getSuit(), judge.card:getNumber())
                        indulgence:setSkillName(self:objectName())
                            local c = sgs.Sanguosha:getWrappedCard(id)
                        c:takeOver(indulgence)
                            room:notifyUpdateCard(player, id, c)
                            room:moveCardTo(c, damage.from, sgs.Player_PlaceDelayedTrick, reason, true)
                    elseif judge.card:isBlack() then
                        local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage", judge.card:getSuit(), judge.card:getNumber())
                        supply_shortage:setSkillName(self:objectName())
                            local c = sgs.Sanguosha:getWrappedCard(id)
                        c:takeOver(supply_shortage)
                            room:notifyUpdateCard(player, id, c)
                            room:moveCardTo(c, damage.from, sgs.Player_PlaceDelayedTrick, reason, true)
                        else
                            if (room:getCardPlace(judge.card:getEffectiveId())==sgs.Player_PlaceJudge) then
                                local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), "judge", "")
                                room:moveCardTo(judge.card, nil, sgs.Player_DiscardPile, reason, true)
                            end
                        end
                    else
                        if (room:getCardPlace(judge.card:getEffectiveId())==sgs.Player_PlaceJudge) then
                            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName(), "judge", "")
                            room:moveCardTo(judge.card, nil, sgs.Player_DiscardPile, reason, true)
                    end
                    end
                end
            end
        elseif event == sgs.FinishJudge then
            local judge = data:toJudge()
            if judge.reason == self:objectName() then
                if judge:isGood() then
                    player:setTag("s4_s_xuezhan", sgs.QVariant(judge.card:getEffectiveId()))
                end
            end
        end
        return false
    end,
}

s4_s_tuji = sgs.CreateTriggerSkill{
    name = "s4_s_tuji",
    frequency = sgs.Skill_Wake,
    waked_skills = "tenyeartuxi",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local min_hp = 1000
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getHp() < min_hp then
                min_hp = p:getHp()
            end
        end
        if player:getHp() == min_hp or player:canWake(self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
            if room:changeMaxHpForAwakenSkill(player, -1, self:objectName()) then
                room:addPlayerMark(player, self:objectName())
                room:acquireSkill(player, "tenyeartuxi")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:getPhase() == sgs.Player_Start and target:getMark(self:objectName()) == 0 and target:hasSkill(self:objectName())
    end,
}

s4_s_baibasishi:addSkill(s4_s_xuezhan)
s4_s_baibasishi:addSkill(s4_s_tuji)


sgs.LoadTranslationTable {
    ["s4_s_baibasishi"] = "八百死士",
    ["&s4_s_baibasishi"] = "八百死士",
    ["#s4_s_baibasishi"] = "视死如归",
    ["~s4_s_baibasishi"] = "",
    ["designer:s4_s_baibasishi"] = "",
    ["cv:s4_s_baibasishi"] = "",
    ["illustrator:s4_s_baibasishi"] = "",
    ["s4_s_tuji"] = "突击",
    [":s4_s_tuji"] = "觉醒技，回合开始阶段开始时，若你的体力值是全场最少的，你须减1点体力上限，并获得技能“突袭”。",
    ["s4_s_xuezhan"] = "血战",
    [":s4_s_xuezhan"] = "每当你受到一次伤害后，你可以进行一次判定，若为方片，判定牌置于伤害来源的判定区内，并视为【乐不思蜀】；若为梅花，判定牌置于伤害来源的判定区内，并视为【兵粮寸断】。",
}

s4_s_taishanjun = sgs.General(extension_soldier, "s4_s_taishanjun", "wei", 4)

s4_s_yuangong = sgs.CreateTriggerSkill{
    name = "s4_s_yuangong",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseChanging},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local change = data:toPhaseChange()
        if change.to == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge) and not player:isSkipped(sgs.Player_Draw) and not player:isSkipped(sgs.Player_Play) then
            local slash = dummyCard("thunder_slash")
            slash:setSkillName(self:objectName())
            local extra_targets = room:getCardTargets(player, slash)
            if extra_targets:isEmpty() then return false end
            room:setTag("s4_s_yuangong", data)
            local others = room:askForPlayersChosen(player, extra_targets, self:objectName(), 0, 3, "@s4_s_yuangong", true, true)
            room:removeTag("s4_s_yuangong")
            if others and others:length() > 0 then
                player:skip(sgs.Player_Judge)
                player:skip(sgs.Player_Draw)
                player:skip(sgs.Player_Play)
                local use = sgs.CardUseStruct()
                use.from = player
                use.card = slash
                for _, p in sgs.qlist(others) do
                    use.to = sgs.SPlayerList()
                    use.to:append(p)
                    room:useCard(use, false)
                end
            end
        end
        return false
    end,
}

s4_s_chuqiCard = sgs.CreateSkillCard{
    name = "s4_s_chuqi",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local choices = {}
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            for _, c in sgs.qlist(p:getEquips()) do
                if c:isKindOf("Weapon") and not table.contains(choices, c:objectName()) then
                    table.insert(choices, c:objectName())
                end
            end
        end
        if #choices == 0 then return end
        local choice = room:askForChoice(source, "s4_s_chuqi", table.concat(choices, "+"))
        local old = source:property("s4_s_chuqi"):toString()
        room:setPlayerMark(source, "&s4_s_chuqi+" .. old, 0)
        room:setPlayerProperty(source, "s4_s_chuqi", sgs.QVariant(choice))
        room:setPlayerMark(source, "&s4_s_chuqi+" .. choice, 1)
    end,
}
s4_s_chuqi_equip = sgs.CreateViewAsEquipSkill {
	name = "#s4_s_chuqi_equip",
	view_as_equip = function(self, player)
		return "" .. player:property("s4_s_chuqi"):toString()
	end,
}
s4_s_chuqiVS = sgs.CreateOneCardViewAsSkill{
    name = "s4_s_chuqi",
    filter_pattern = ".|.|.|hand",
    view_as = function(self, card)
        local chuqi_card = s4_s_chuqiCard:clone()
        chuqi_card:addSubcard(card)
        return chuqi_card
    end,
    enabled_at_play = function(self, player)
        local can_invoke = false
        for _, p in sgs.qlist(player:getAliveSiblings()) do
            for _, c in sgs.qlist(p:getEquips()) do
                if c:isKindOf("Weapon") then
                    can_invoke = true
                    break
                end
            end
        end
        if not can_invoke then return false end
        return not player:getWeapon() and not player:hasUsed("#s4_s_chuqi")
    end,
}
s4_s_chuqi = sgs.CreateTriggerSkill{
    name = "s4_s_chuqi",
    view_as_skill = s4_s_chuqiVS,
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
            local old = player:property("s4_s_chuqi"):toString()
            if old ~= "" then
                room:setPlayerMark(player, "&s4_s_chuqi+" .. old, 0)
                room:setPlayerProperty(player, "s4_s_chuqi", sgs.QVariant(""))
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end,
}


s4_s_taishanjun:addSkill(s4_s_yuangong)
s4_s_taishanjun:addSkill(s4_s_chuqi)
s4_s_taishanjun:addSkill(s4_s_chuqi_equip)
extension_soldier:insertRelatedSkills("s4_s_chuqi","#s4_s_chuqi_equip")


sgs.LoadTranslationTable {
    ["s4_s_taishanjun"] = "泰山军",
    ["&s4_s_taishanjun"] = "泰山军",
    ["#s4_s_taishanjun"] = "骁勇善战",
    ["~s4_s_taishanjun"] = "",
    ["designer:s4_s_taishanjun"] = "",
    ["cv:s4_s_taishanjun"] = "",
    ["illustrator:s4_s_taishanjun"] = "",
    ["s4_s_yuangong"] = "远攻",
    [":s4_s_yuangong"] = "你可以跳过判定阶段，摸牌阶段和出牌阶段，视为对一至三名角色各使用一张【雷杀】。",
    ["s4_s_chuqi"] = "出奇",
    [":s4_s_chuqi"] = "出牌阶段限一次，若你的装备区没有武器牌，你可以弃置一张手牌，声明获得场上一名其他角色已装备的武器牌的效果，直到本阶段结束。",
}

s4_s_qiangwangjun = sgs.General(extension_soldier, "s4_s_qiangwangjun", "qun", 3)

s4_s_lumang = sgs.CreateTriggerSkill{
    name = "s4_s_lumang",
    events = {sgs.CardOffset, sgs.CardUsed},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardOffset then
            local effect = data:toCardEffect()
            if effect.card and effect.card:isKindOf("Slash") and effect.to and effect.to:isAlive() then
                if effect.from:hasSkill(self:objectName()) and room:askForSkillInvoke(player, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())
                    local duel = sgs.Sanguosha:cloneCard("duel", effect.card:getSuit(), effect.card:getNumber())
                    duel:setSkillName(self:objectName())
                    duel:deleteLater()
                    room:useCard(sgs.CardUseStruct(duel, player, effect.to), false)
                end
            end
        elseif event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Duel") and use.card:getSkillName() == self:objectName() then
                if use.from:hasSkill(self:objectName()) then
                    local no_offset_list = use.no_offset_list
                    table.insert(no_offset_list, "_ALL_TARGETS")
                    use.no_offset_list = no_offset_list
                    data:setValue(use)
                end
            end
        end
        return false
    end,
}

s4_s_mengzhanVS = sgs.CreateOneCardViewAsSkill{
    name = "s4_s_mengzhan",
    filter_pattern = "Slash,EquipCard",
    view_as = function(self, card)
        local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        slash:setSkillName(self:objectName())
        slash:addSubcard(card)
        return slash
    end,
    enabled_at_play = function(self, player)
        return false
    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE and player:getMark("s4_s_mengzhan") > 0
    end
}
s4_s_mengzhan = sgs.CreateTriggerSkill{
    name = "s4_s_mengzhan",
    view_as_skill = s4_s_mengzhanVS,
    events = {sgs.CardAsked, sgs.CardFinished},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardAsked and player:hasSkill(self:objectName()) then
            local pattern = data:toStringList()[1]
            local prompt = data:toStringList()[2]
            if pattern == "slash" and prompt == "duel-slash" then
                if data:toStringList()[4] then
                    local use = room:getTag("UseHistory"..data:toStringList()[4]):toCardUse()
                    if use and use.card and use.card:isKindOf("Duel") then
                        room:setCardFlag(use.card, "s4_s_mengzhan")
                        room:addPlayerMark(player, self:objectName())
                    end
                end
            end
        elseif event == sgs.CardFinished then
            local card = data:toCardUse().card
            if card and card:hasFlag("s4_s_mengzhan") then
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getMark(self:objectName()) > 0 then
                        room:removePlayerMark(p, self:objectName())
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

s4_s_qiangwangjun:addSkill(s4_s_lumang)
s4_s_qiangwangjun:addSkill(s4_s_mengzhan)

sgs.LoadTranslationTable {
    ["s4_s_qiangwangjun"] = "羌王军",
    ["&s4_s_qiangwangjun"] = "羌王军",
    ["#s4_s_qiangwangjun"] = "踏破千军",
    ["~s4_s_qiangwangjun"] = "",
    ["designer:s4_s_qiangwangjun"] = "",
    ["cv:s4_s_qiangwangjun"] = "",
    ["illustrator:s4_s_qiangwangjun"] = "",
    ["s4_s_lumang"] = "鲁莽",
    [":s4_s_lumang"] = "当你使用的【杀】被【闪】抵消时，你可以视为对目标角色使用一张【决斗】，此【决斗】不能被【无懈可击】响应。",
    ["s4_s_mengzhan"] = "猛战",
    [":s4_s_mengzhan"] = "决斗中，你可以将【闪】和装备牌当【杀】打出。",
}

s4_s_xinmubing = sgs.General(extension_soldier, "s4_s_xinmubing", "qun", 4)

s4_s_qiezhan = sgs.CreateTriggerSkill{
    name = "s4_s_qiezhan",
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if room:askForCard(player, ".|red|.|hand", "@s4_s_qiezhan", data, self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
            player:damageRevises(data, -damage.damage)
        end
        return false
    end,
}

s4_s_xinmubing:addSkill(s4_s_qiezhan)
-- s4_s_xinmubing:addSkill(s4_s_pantao)

sgs.LoadTranslationTable {
    ["s4_s_xinmubing"] = "新募兵",
    ["&s4_s_xinmubing"] = "新募兵",
    ["#s4_s_xinmubing"] = "初出茅庐",
    ["~s4_s_xinmubing"] = "",
    ["designer:s4_s_xinmubing"] = "",
    ["cv:s4_s_xinmubing"] = "",
    ["illustrator:s4_s_xinmubing"] = "",
    ["s4_s_qiezhan"] = "怯战",
    ["@s4_s_qiezhan"] = "怯战：你可以弃置一张红色手牌，防止此伤害",
    [":s4_s_qiezhan"] = "每当你受到伤害时，你可以弃置一张红色手牌，防止此伤害。",
    ["s4_s_pantao"] = "叛逃",
    [":s4_s_pantao"] = "锁定技，你可以响应任何势力主公的主公技。",
    --TODO
}

s4_s_xianzhenying = sgs.General(extension_soldier, "s4_s_xianzhenying", "qun", 4)

s4_s_2_xuezhanCard = sgs.CreateSkillCard{
    name = "s4_s_2_xuezhan",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return #targets == 0 and to_select:isAlive() and to_select:objectName() ~= player:objectName() and player:canPindian(to_select)
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        room:broadcastSkillInvoke("s4_s_2_xuezhan")
        local pindian = source:PinDian(target, self:objectName())
        if pindian.success then
            local damage = sgs.DamageStruct()
            damage.from = source
            damage.to = target
            damage.damage = 1
            damage.nature = sgs.DamageStruct_Thunder
            damage.card = nil
            room:damage(damage)
        else
            if pindian.from_card then
                room:obtainCard(target, pindian.from_card, false)
            end
            if pindian.to_card then
                room:obtainCard(target, pindian.to_card, false)
            end
        end
    end,
}
s4_s_2_xuezhan = sgs.CreateViewAsSkill{
    name = "s4_s_2_xuezhan",
    n = 0,
    view_as = function(self, cards)
        return s4_s_2_xuezhanCard:clone()
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#s4_s_2_xuezhan")
    end,
}

s4_s_gongpoCard = sgs.CreateSkillCard{
    name = "s4_s_gongpo",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        room:setPlayerMark(source, "s4_s_gongpo-"..sgs.Player_Play.."Clear", 1)
        room:setPlayerMark(source, "&s4_s_gongpo-"..sgs.Player_Play.."Clear", 1)
    end,
}
s4_s_gongpoVS = sgs.CreateOneCardViewAsSkill{
    name = "s4_s_gongpo",
    filter_pattern = "black|.|.|hand",
    view_as = function(self, card)
        local gongpo_card = s4_s_gongpoCard:clone()
        gongpo_card:addSubcard(card)
        return gongpo_card
    end,
    enabled_at_play = function(self, player)
        return player:canDiscard(player, "h")
    end,
}
s4_s_gongpo = sgs.CreateTriggerSkill{
    name = "s4_s_gongpo",
    view_as_skill = s4_s_gongpoVS,
    events = {sgs.Predamage},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.from and damage.from:isAlive() and damage.from:objectName() == player:objectName()
            and player:getMark("s4_s_gongpo-"..sgs.Player_Play.."Clear") > 0 then
            room:sendCompulsoryTriggerLog(player, objectName())
            room:loseHp(damage.to, damage.damage, true, player, self:objectName())
            return true
        end
        return false
    end,
}

s4_s_xianzhenying:addSkill(s4_s_2_xuezhan)
s4_s_xianzhenying:addSkill(s4_s_gongpo)

sgs.LoadTranslationTable {
    ["s4_s_xianzhenying"] = "陷阵营",
    ["&s4_s_xianzhenying"] = "陷阵营",
    ["#s4_s_xianzhenying"] = "攻无不破",
    ["~s4_s_xianzhenying"] = "",
    ["designer:s4_s_xianzhenying"] = "",
    ["cv:s4_s_xianzhenying"] = "",
    ["illustrator:s4_s_xianzhenying"] = "",
    ["s4_s_2_xuezhan"] = "血战",
    [":s4_s_2_xuezhan"] = "出牌阶段限一次，你可以和一名角色拼点。若你赢，对该角色造成1点雷电伤害。若你没赢，目标角色获得双方拼点的牌。",
    ["s4_s_gongpo"] = "攻破",
    [":s4_s_gongpo"] = "出牌阶段，你可以弃置一张黑色手牌，令你造成的伤害视为体力流失，直到本阶段结束。",
}

s4_s_baimayicong = sgs.General(extension_soldier, "s4_s_baimayicong", "qun", 3)

s4_s_liangju = sgs.CreateDistanceSkill{
    name = "s4_s_liangju",
    correct_func = function(self, from, to)
        if from:hasSkill(self:objectName()) then
            return -1
        end
        if to:hasSkill(self:objectName()) then
            return 1
        end
        return 0
    end,
}
s4_s_qishe = sgs.CreateTriggerSkill{
    name = "s4_s_qishe",
    events = {sgs.ChangeSlash},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card and use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() and player:getPhase() == sgs.Player_Play then
            if player:isLastHandCard(use.card) and room:askForSkillInvoke(player, self:objectName(), data) then
                room:broadcastSkillInvoke(self:objectName())
                local nature = patterns("Slash")
                local choice = room:askForChoice(player, self:objectName(), table.concat(nature, "+"))
                local slash = sgs.Sanguosha:cloneCard(choice, use.card:getSuit(), use.card:getNumber())
                slash:setSkillName(self:objectName())
                local choices = {"diamond", "heart", "spade", "club"}
                local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
                if choice == "diamond" then
                    slash:setSuit(sgs.Card_Diamond)
                elseif choice == "heart" then
                    slash:setSuit(sgs.Card_Heart)
                elseif choice == "spade" then
                    slash:setSuit(sgs.Card_Spade)
                elseif choice == "club" then
                    slash:setSuit(sgs.Card_Club)
                end
                use:changeCard(slash)
                data:setValue(use)
            end
        end
        return false
    end,
}

s4_s_baimayicong:addSkill(s4_s_liangju)
s4_s_baimayicong:addSkill(s4_s_qishe)

sgs.LoadTranslationTable {
    ["s4_s_baimayicong"] = "白马义从",
    ["&s4_s_baimayicong"] = "白马义从",
    ["#s4_s_baimayicong"] = "兵贵神速",
    ["~s4_s_baimayicong"] = "",
    ["designer:s4_s_baimayicong"] = "",
    ["cv:s4_s_baimayicong"] = "",
    ["illustrator:s4_s_baimayicong"] = "",
    ["s4_s_liangju"] = "良驹",
    [":s4_s_liangju"] = "锁定技，你计算与所有其他角色的距离-1，其他角色计算与你的距离+1。",
    ["s4_s_qishe"] = "骑射",
    [":s4_s_qishe"] = "当你於出牌阶段使用的【杀】是你的最后一张手牌时，你可为此【杀】指定任意属性及花色。",
}

s4_s_xiandengsishi = sgs.General(extension_soldier, "s4_s_xiandengsishi", "qun", 4)

s4_s_2_yuanshe = sgs.CreateAttackRangeSkill{
    name = "s4_s_2_yuanshe",
    extra_func = function(self, from)
        if from:hasSkill(self:objectName()) and from:getWeapon() then
            return 2
        end
        return 0
    end,
}

s4_s_jinggong = sgs.CreateTriggerSkill{
    name = "s4_s_jinggong",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetConfirmed},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card and use.card:isKindOf("Slash") and use.from:objectName() == player:objectName() then
            local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
            local index = 1
            for _, p in sgs.qlist(use.to) do
                if (p:getArmor() or p:getDefensiveHorse() or p:getOffensiveHorse()) then
                    local log = sgs.LogMessage()
                    log.type = "#skill_cant_jink"
                    log.from = player
                    log.to:append(p)
                    log.arg = self:objectName()
                    room:sendLog(log)
                    jink_table[index] = 0
                end
                index = index + 1
            end
            local jink_data = sgs.QVariant()
            jink_data:setValue(Table2IntList(jink_table))
            player:setTag("Jink_" .. use.card:toString(), jink_data)
        end
        return false
    end,
}

s4_s_xiandengsishi:addSkill(s4_s_2_yuanshe)
s4_s_xiandengsishi:addSkill(s4_s_jinggong)

sgs.LoadTranslationTable {
    ["s4_s_xiandengsishi"] = "先登死士",
    ["&s4_s_xiandengsishi"] = "先登死士",
    ["#s4_s_xiandengsishi"] = "百步穿杨",
    ["~s4_s_xiandengsishi"] = "",
    ["designer:s4_s_xiandengsishi"] = "",
    ["cv:s4_s_xiandengsishi"] = "",
    ["illustrator:s4_s_xiandengsishi"] = "",
    ["s4_s_2_yuanshe"] = "远射",
    [":s4_s_2_yuanshe"] = "锁定技，你所装备武器的攻击范围始终+2。",
    ["s4_s_jinggong"] = "精弓",
    [":s4_s_jinggong"] = "锁定技，当你使用的【杀】指定的目标角色已装备马或防具，此【杀】不可被【闪】响应。",
}

s4_s_dajishi = sgs.General(extension_soldier, "s4_s_dajishi", "qun", 4)

s4_s_changji = sgs.CreateAttackRangeSkill{
    name = "s4_s_changji",
    fixed_func = function(self, from)
        if from:hasSkill(self:objectName()) then
            return 3
        end
        return -1
    end,
}

s4_s_jingjiaCard = sgs.CreateSkillCard{
    name = "s4_s_jingjia",
    target_fixed = true,
    will_throw = false,
    on_use = function(self, room, source, targets)
        for _,id in sgs.qlist(self:getSubcards()) do
            local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, source:objectName())
            reason.m_skillName = self:objectName()
            room:moveCardTo(sgs.Sanguosha:getCard(id), source, nil, sgs.Player_DiscardPile, reason)
            source:broadcastSkillInvoke("@recast")
            local log = sgs.LogMessage()
            log.type = "#UseCard_Recast"
            log.from = source
            log.card_str = sgs.Sanguosha:getCard(id):toString()
            room:sendLog(log)
            source:drawCards(1, "recast")
        end
    end,
}
s4_s_jingjia = sgs.CreateViewAsSkill{
    name = "s4_s_jingjia",
    n = 999,
    view_filter = function(self, selected, to_select)
        return to_select:isKindOf("EquipCard") and sgs.Self:getHandcards():contains(to_select)
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end
        local jingjia_card = s4_s_jingjiaCard:clone()
        for _, c in ipairs(cards) do
            jingjia_card:addSubcard(c)
        end
        return jingjia_card
    end,
    enabled_at_play = function(self, player)
        return true
    end,
}

s4_s_dajishi:addSkill(s4_s_changji)
s4_s_dajishi:addSkill(s4_s_jingjia)

sgs.LoadTranslationTable {
    ["s4_s_dajishi"] = "大戟士",
    ["&s4_s_dajishi"] = "大戟士",
    ["#s4_s_dajishi"] = "重甲精兵",
    ["~s4_s_dajishi"] = "",
    ["designer:s4_s_dajishi"] = "",
    ["cv:s4_s_dajishi"] = "",
    ["illustrator:s4_s_dajishi"] = "",
    ["s4_s_changji"] = "长戟",
    [":s4_s_changji"] = "锁定技，你的攻击范围始终为3。",
    ["s4_s_jingjia"] = "精甲",
    [":s4_s_jingjia"] = "出牌阶段，你可以将手牌中的装备牌重铸。",
}

s4_s_huangjinjun = sgs.General(extension_soldier, "s4_s_huangjinjun", "qun", 4)

s4_s_lueduo = sgs.CreateViewAsSkill{
    name = "s4_s_lueduo",
    n = 1,
    view_filter = function(self, selected, to_select)
        return to_select:isKindOf("Dismantlement") or to_select:isKindOf("Snatch")
    end,
    view_as = function(self, cards)
        if #cards ~= 1 then
            return nil
        end
        local card = cards[1]
        local lueduo_card = nil
        if card:isKindOf("Snatch") then
            lueduo_card = sgs.Sanguosha:cloneCard("dismantlement", card:getSuit(), card:getNumber())
        else
            lueduo_card = sgs.Sanguosha:cloneCard("snatch", card:getSuit(), card:getNumber())
        end
        lueduo_card:setSkillName(self:objectName())
        lueduo_card:addSubcard(card)
        return lueduo_card
    end,
    enabled_at_play = function(self, player)
        return true
    end,
}

s4_s_zonghuoVS = sgs.CreateViewAsSkill{
    name = "s4_s_zonghuo",
    n = 1,
    view_filter = function(self, selected, to_select)
        return to_select:isKindOf("FireAttack") or to_select:isKindOf("FireSlash")
    end,
    view_as = function(self, cards)
        if #cards ~= 1 then
            return nil
        end
        local card = cards[1]
        local zonghuo_card = nil
        if card:isKindOf("FireSlash") then
            zonghuo_card = sgs.Sanguosha:cloneCard("fire_attack", card:getSuit(), card:getNumber())
        else
            zonghuo_card = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())
        end
        zonghuo_card:setSkillName(self:objectName())
        zonghuo_card:addSubcard(card)
        return zonghuo_card
    end,
    enabled_at_play = function(self, player)
        return true
    end,
}
s4_s_zonghuo = sgs.CreateTriggerSkill{
    name = "s4_s_zonghuo",
    view_as_skill = s4_s_zonghuoVS,
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data)
        if event == sgs.TargetSpecified then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("FireSlash") then
                local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
                local index = 1
                for _, p in sgs.qlist(use.to) do
                    local log = sgs.LogMessage()
                    log.type = "#skill_cant_jink"
                    log.from = player
                    log.to:append(p)
                    log.arg = self:objectName()
                    room:sendLog(log)
                    jink_table[index] = 0
                    index = index + 1
                end
                local jink_data = sgs.QVariant()
                jink_data:setValue(Table2IntList(jink_table))
                player:setTag("Jink_" .. use.card:toString(), jink_data)
            end
        end
    end
}

s4_s_huangjinjun:addSkill(s4_s_lueduo)
s4_s_huangjinjun:addSkill(s4_s_zonghuo)

sgs.LoadTranslationTable {
    ["s4_s_huangjinjun"] = "黄巾军",
    ["&s4_s_huangjinjun"] = "黄巾军",
    ["#s4_s_huangjinjun"] = "黄天当立",
    ["~s4_s_huangjinjun"] = "",
    ["designer:s4_s_huangjinjun"] = "",
    ["cv:s4_s_huangjinjun"] = "",
    ["illustrator:s4_s_huangjinjun"] = "",
    ["s4_s_lueduo"] = "掠夺",
    [":s4_s_lueduo"] = "你可以将【顺手牵羊】当做【过河拆桥】使用，你可以将【过河拆桥】当做【顺手牵羊】使用。",
    ["s4_s_zonghuo"] = "纵火",
    [":s4_s_zonghuo"] = "你可以将【火杀】当做【火攻】使用，你可以将【火攻】当做【火杀】使用。你的【火杀】不可被【闪】响应。",
}


s4_s_bingzhoutieqi = sgs.General(extension_soldier, "s4_s_bingzhoutieqi", "qun", 4)

s4_s_yongwu_buff = sgs.CreateTargetModSkill{
    name = "s4_s_yongwu_buff",
    pattern = "Slash",
    distance_limit_func = function(self, from, card)
        if from:getMark("s4_s_yongwured-PlayClear") > 0 then
            return 1000
        end
        return 0
    end,
}
s4_s_yongwuCard = sgs.CreateSkillCard{
    name = "s4_s_yongwu",
    target_fixed = true,
    will_throw = true,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        for _, id in sgs.qlist(self:getSubcards()) do
            local card = sgs.Sanguosha:getCard(id)
            if card:isRed() then
                room:setPlayerMark(source, "s4_s_yongwured-PlayClear", 1)
                room:setPlayerMark(source, "&s4_s_yongwu+red-PlayClear", 1)
            elseif card:isBlack() then
                room:setPlayerMark(source, "s4_s_yongwublack-PlayClear", 1)
                room:setPlayerMark(source, "&s4_s_yongwu+black-PlayClear", 1)
            end
        end
    end,
}
s4_s_yongwuVS = sgs.CreateViewAsSkill{
    name = "s4_s_yongwu",
    n = 2,
    view_filter = function(self, selected, to_select)
        if #selected > 0 then
            return selected[1]:getColor() ~= to_select:getColor() and sgs.Self:getHandcards():contains(to_select)
        end
        return sgs.Self:getHandcards():contains(to_select)
    end,
    view_as = function(self, cards)
        if #cards == 0 then
            return nil
        end
        local yongwu_card = s4_s_yongwuCard:clone()
        for _, c in ipairs(cards) do
            yongwu_card:addSubcard(c)
        end
        return yongwu_card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#s4_s_yongwu")
    end,
}
s4_s_yongwu = sgs.CreateTriggerSkill{
    name = "s4_s_yongwu",
    view_as_skill = s4_s_yongwuVS,
    events = {sgs.TargetSpecified},
    on_trigger = function(self, event, player, data)
        local use = data:toCardUse()
        if use.from and use.from:hasSkill(self:objectName()) and use.from:getMark("s4_s_yongwublack-PlayClear") > 0 then
            if use.card and use.card:isKindOf("Slash") then
                if use.from:objectName() == player:objectName() then
                    for _, p in sgs.qlist(use.to) do
                        p:addQinggangTag(use.card)
                    end
                end
            end
        end
    end
}

s4_s_baonu = sgs.CreateTriggerSkill{
    name = "s4_s_baonu",
    frequency = sgs.Skill_Wake,
    waked_skills = "shenji",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        room:broadcastSkillInvoke(self:objectName())
        room:sendCompulsoryTriggerLog(player, self:objectName())
        if room:changeMaxHpForAwakenSkill(player, -1, self:objectName()) then
            room:acquireSkill(player, "shenji")
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getMark(self:objectName()) == 0 and target:getPhase() == sgs.Player_RoundStart and (target:getHp() == 1 or target:canWake(self:objectName()))
    end,
}

s4_s_bingzhoutieqi:addSkill(s4_s_yongwu)
s4_s_bingzhoutieqi:addSkill(s4_s_baonu)

sgs.LoadTranslationTable {
    ["s4_s_bingzhoutieqi"] = "并州铁骑",
    ["&s4_s_bingzhoutieqi"] = "并州铁骑",
    ["#s4_s_bingzhoutieqi"] = "万马奔腾",
    ["~s4_s_bingzhoutieqi"] = "",
    ["designer:s4_s_bingzhoutieqi"] = "",
    ["cv:s4_s_bingzhoutieqi"] = "",
    ["illustrator:s4_s_bingzhoutieqi"] = "",
    ["s4_s_yongwu"] = "勇武",
    [":s4_s_yongwu"] = "出牌阶段限一次，你可以弃置一张红色手牌，你的使用【杀】无视距离限制，你可以弃置一张黑色手牌，你无视目标角色防具，直到该阶段结束。",
    ["s4_s_baonu"] = "暴怒",
    [":s4_s_baonu"] = "觉醒技，回合开始阶段开始时，若你的体力为1，你须减1点体力上限，并获得技能“神戟”。",
}

s4_s_feixiongjun = sgs.General(extension_soldier, "s4_s_feixiongjun", "qun", 4)

s4_s_xianneng = sgs.CreateTriggerSkill{
    name = "s4_s_xianneng",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Finish and player:getMark("s4_s_xiannengExtraTurn") == 0 and player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
            room:loseHp(player, 1, true, player, self:objectName())
            if player:isAlive() then
                local playerdata = sgs.QVariant()
                playerdata:setValue(player)
                room:setTag("s4_s_xiannengTarget", playerdata)
            end
        end
        return false
    end,
}
s4_s_xianneng_buff = sgs.CreateTriggerSkill{
	name = "#s4_s_xianneng_buff" ,
	events = {sgs.EventPhaseStart} ,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:getTag("s4_s_xiannengTarget") then
			local target = room:getTag("s4_s_xiannengTarget"):toPlayer()
			room:removeTag("s4_s_xiannengTarget")
			if target and target:isAlive() then
                room:setPlayerMark(target, "s4_s_xiannengExtraTurn", 1)
				target:gainAnExtraTurn()
                room:setPlayerMark(target, "s4_s_xiannengExtraTurn", 0)
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and (target:getPhase() == sgs.Player_NotActive)
	end,
	priority = 1
}

s4_s_tongyin = sgs.CreateTriggerSkill{
    name = "s4_s_tongyin",
    frequency = sgs.Skill_Wake,
    events = {sgs.QuitDying},
    waked_skills = "jiuchi",
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local dying = data:toDying()
        if dying.who and dying.who:isAlive() and dying.who:objectName() == player:objectName() then
            room:broadcastSkillInvoke(self:objectName())
            room:sendCompulsoryTriggerLog(player, self:objectName())
            if room:changeMaxHpForAwakenSkill(player, -1, self:objectName()) then
                room:addPlayerMark(player, self:objectName())
                room:acquireSkill(player, "jiuchi")
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:hasSkill(self:objectName()) and target:getMark(self:objectName()) == 0
    end,
}

s4_s_feixiongjun:addSkill(s4_s_xianneng)
s4_s_feixiongjun:addSkill(s4_s_xianneng_buff)
extension_soldier:insertRelatedSkills("s4_s_xianneng", "#s4_s_xianneng_buff")
s4_s_feixiongjun:addSkill(s4_s_tongyin)

sgs.LoadTranslationTable {
    ["s4_s_feixiongjun"] = "飞熊军",
    ["&s4_s_feixiongjun"] = "飞熊军",
    ["#s4_s_feixiongjun"] = "精锐之师",
    ["~s4_s_feixiongjun"] = "",
    ["designer:s4_s_feixiongjun"] = "",
    ["cv:s4_s_feixiongjun"] = "",
    ["illustrator:s4_s_feixiongjun"] = "",
    ["s4_s_xianneng"] = "贤能",
    [":s4_s_xianneng"] = "回合结束阶段开始时，你可以失去1点体力，你于本回合结束后执行一个额外的回合，该回合结束时不能再发动“贤能”。",
    ["s4_s_tongyin"] = "痛饮",
    [":s4_s_tongyin"] = "觉醒技，当你脱离濒死状态时，你须减1点体力上限，并获得技能“酒池”。",
}


s4_s_fangshi = sgs.General(extension_soldier, "s4_s_fangshi", "god", 3)

s4_s_jijiuCard = sgs.CreateSkillCard{
    name = "s4_s_jijiu",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return #targets == 0
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        target:addToPile("s4_s_jijiu", self)
        room:addPlayerMark(target, "s4_s_jijiu"..source:objectName())
    end,
}
s4_s_jijiuVS = sgs.CreateViewAsSkill{
    name = "s4_s_jijiu",
    n = 1,
    view_filter = function(self, selected, to_select)
        return to_select:getSuit() == sgs.Card_Diamond and not to_select:isEquipped()
    end,
    view_as = function(self, cards)
        if #cards ~= 1 then
            return nil
        end
        local jijiu_card = s4_s_jijiuCard:clone()
        jijiu_card:addSubcard(cards[1])
        return jijiu_card
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#s4_s_jijiu")
    end,
}
s4_s_jijiu = sgs.CreateTriggerSkill{
    name = "s4_s_jijiu",
    view_as_skill = s4_s_jijiuVS,
    events = {sgs.EnterDying},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local dying = data:toDying()
        local card_id = player:getPile("s4_s_jijiu"):first()
        local card = sgs.Sanguosha:getCard(card_id)
        room:broadcastSkillInvoke(self:objectName())
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, nil, "sfofl_nujian", nil)
        room:throwCard(card, reason, nil)
        if player:isAlive() then
            for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
                if p:getMark("s4_s_jijiu"..p:objectName()) > 0 then
                    room:removePlayerMark(p, "s4_s_jijiu"..p:objectName())
                    room:recover(player,sgs.RecoverStruct(self:objectName(),p, 1))
                    break
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and not target:getPile("s4_s_jijiu"):isEmpty()
    end,
}

s4_s_liaoshang_godSalvation = sgs.CreateViewAsSkill{
    name = "s4_s_liaoshang_godSalvation&",
    n = 1,
    view_filter = function(self, selected, to_select)
        return to_select:getSuit() == sgs.Card_Heart
    end,
    view_as = function(self, cards)
        if #cards ~= 1 then
            return nil
        end
        local god_salvation = sgs.Sanguosha:cloneCard("god_salvation", cards[1]:getSuit(), cards[1]:getNumber())
        god_salvation:setSkillName("s4_s_liaoshang")
        god_salvation:addSubcard(cards[1])
        return god_salvation
    end,
    enabled_at_play = function(self, player)
        return true
    end,
}

s4_s_liaoshang = sgs.CreateFilterSkill{
    name = "s4_s_liaoshang",
    view_filter = function(self,to_select)
        local room = sgs.Sanguosha:currentRoom()
        local place = room:getCardPlace(to_select:getEffectiveId())
        return (to_select:getSuit() == sgs.Card_Heart) and (place == sgs.Player_PlaceHand)
    end,
    view_as = function(self, originalCard)
        local peach = sgs.Sanguosha:cloneCard("peach", originalCard:getSuit(), originalCard:getNumber())
        peach:setSkillName(self:objectName())
        local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
        card:takeOver(peach)
        return card
    end,
}

s4_s_xingyiCard = sgs.CreateSkillCard{
    name = "s4_s_xingyi",
    target_fixed = false,
    will_throw = false,
    filter = function(self, targets, to_select, player)
        return #targets == 0 and to_select:isWounded() and to_select:objectName() ~= player:objectName()
    end,
    on_use = function(self, room, source, targets)
        local target = targets[1]
        room:removePlayerMark(source, "@s4_s_xingyi")
        room:gainMaxHp(target, 1, self:objectName())
    end,
}

s4_s_xingyiVS = sgs.CreateViewAsSkill{
    name = "s4_s_xingyi",
    n = 0,
    view_as = function(self, cards)
        local xingyi_card = s4_s_xingyiCard:clone()
        xingyi_card:setSkillName(self:objectName())
        return xingyi_card
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@s4_s_xingyi") > 0
    end,
}

s4_s_xingyi = sgs.CreateTriggerSkill{
    name = "s4_s_xingyi",
    frequency = sgs.Skill_Limited,
    limit_mark = "@s4_s_xingyi",
    view_as_skill = s4_s_xingyiVS,
    events = {},
}


s4_s_fangshi:addSkill(s4_s_jijiu)
s4_s_fangshi:addSkill(s4_s_liaoshang)
s4_s_fangshi:addSkill(s4_s_liaoshang_godSalvation)
extension_soldier:insertRelatedSkills("s4_s_liaoshang", "s4_s_liaoshang_godSalvation&")
s4_s_fangshi:addSkill(s4_s_xingyi)

sgs.LoadTranslationTable {
    ["s4_s_fangshi"] = "方士",
    ["&s4_s_fangshi"] = "方士",
    ["#s4_s_fangshi"] = "救死扶伤",
    ["~s4_s_fangshi"] = "",
    ["designer:s4_s_fangshi"] = "",
    ["cv:s4_s_fangshi"] = "",
    ["illustrator:s4_s_fangshi"] = "",
    ["s4_s_jijiu"] = "急救",
    [":s4_s_jijiu"] = "出牌阶段限一次，你可以将一张方片手牌置于一名角色的武将牌上，当该角色进入濒死状态时，弃置此牌，你令其回复1点体力。",
    ["s4_s_liaoshang_godSalvation"] = "疗伤",
    [":s4_s_liaoshang_godSalvation"] = "你可以将一张红桃手牌当【桃园结义】使用。",
    ["s4_s_liaoshang"] = "疗伤",
    [":s4_s_liaoshang"] = "锁定技，你的红桃牌视为【桃】或【桃园结义】。",
    ["s4_s_xingyi"] = "行医",
    [":s4_s_xingyi"] = "限定技，出牌阶段，你可以令一名已受伤的其他角色体力上限+1。",
}

s4_s_xizuo = sgs.General(extension_soldier, "s4_s_xizuo", "god", 3, true, false, false, 3)

s4_s_anqi_buff = sgs.CreateTargetModSkill{
    name = "#s4_s_anqi_buff",
    pattern = "Slash",
    distance_limit_func = function(self, from, card)
        if card and table.contains(card:getSkillNames(), "s4_s_anqi") then
            return 1000
        end
        return 0
    end,
    residue_func = function(self, from, card)
        if card and table.contains(card:getSkillNames(), "s4_s_anqi") then
            return 1000
        end
        return 0
    end,
}

s4_s_anqiVS = sgs.CreateViewAsSkill{
    name = "s4_s_anqi",
    n = 1,
    view_filter = function(self, selected, to_select)
        return to_select:isKindOf("Weapon")
    end,
    view_as = function(self, cards)
        if #cards ~= 1 then
            return nil
        end
        local slash = sgs.Sanguosha:cloneCard("slash", cards[1]:getSuit(), cards[1]:getNumber())
        slash:setSkillName(self:objectName())
        slash:addSubcard(cards[1])
        return slash
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player)
    end,
}
s4_s_anqi = sgs.CreateTriggerSkill{
    name = "s4_s_anqi",
    view_as_skill = s4_s_anqiVS,
    events = { sgs.CardUsed },
    on_trigger = function(self, event, player, data)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") and use.card:getSkillName() == self:objectName() then
                use.m_addHistory = false
                data:setValue(use)
            end
        end
        return false
    end,
}

s4_s_citan = sgs.CreateTriggerSkill{
    name = "s4_s_citan",
    frequency = sgs.Skill_Frequent,
    events = {sgs.EventPhaseProceeding},
    on_trigger = function(self, event, player, data)
        if player:getPhase() == sgs.Player_Draw then
            local room = player:getRoom()
            local targets = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
                if player:inMyAttackRange(p) and not p:isKongcheng() then
                    targets:append(p)
                end
            end
            if targets:isEmpty() then
                return false
            end
            local target = room:askForPlayerChosen(player, targets, self:objectName(), "s4_s_citan-invoke", true, true)
            if target then
                local handcards = target:getHandcards()
                room:showAllCards(target, player)
                room:fillAG(handcards, player)
                local to_obtain = dummyCard()
                local id = room:askForAG(player, handcards, false, self:objectName())
                local card_ids = sgs.IntList()
                local disable = sgs.IntList()
                card_ids:append(id)
                room:clearAG(player)
                for _, c in sgs.qlist(handcards) do
                    if c:getId() ~= id and c:getSuit() == sgs.Sanguosha:getCard(id):getSuit() then
                        card_ids:append(c:getId())
                    else
                        disable:append(c:getId())
                    end
                end
                if card_ids:subcardsLength() < 4 then
                    to_obtain:addSubcards(card_ids)
                    room:obtainCard(player, to_obtain, false)
                else
                    room:fillAG(handcards, player, disable)
                    for i = 1, 3 do
                        local id = room:askForAG(player, card_ids, false, self:objectName())
                        to_obtain:addSubcard(id)
                        room:clearAG(player)
                    end
                    room:obtainCard(player, to_obtain, false)
                end
                
                return true
            end
            
        end
        return false
    end,
}

s4_s_qianfu = sgs.CreateTriggerSkill{
    name = "s4_s_qianfu",
    events = {sgs.Damaged, sgs.CardEffected},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardEffected then
            local effect = data:toCardEffect()
            if player:getMark("s4_s_qianfu"..effect.card:getColorString().."-Clear") > 0 then
                local log = sgs.LogMessage()
                log.type = "#SkillNullify"
                log.from = player
                log.arg = self:objectName()
                log.arg2 = effect.card:toString()
                room:sendLog(log)
                return true
            end
        elseif event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.card and player:getPhase() == sgs.Player_NotActive then
                room:addPlayerMark(player, "s4_s_qianfu"..damage.card:getColorString().."-Clear")
                room:addPlayerMark(player, "&s4_s_qianfu+:+"..damage.card:getColorString().."-Clear")
            end
        end
        return false
    end,
}

s4_s_xizuo:addSkill(s4_s_anqi)
s4_s_xizuo:addSkill(s4_s_anqi_buff)
extension_soldier:insertRelatedSkills("s4_s_anqi", "#s4_s_anqi_buff")
s4_s_xizuo:addSkill(s4_s_citan)
s4_s_xizuo:addSkill(s4_s_qianfu)

sgs.LoadTranslationTable {
    ["s4_s_xizuo"] = "细作",
    ["&s4_s_xizuo"] = "细作",
    ["#s4_s_xizuo"] = "无影无踪",
    ["~s4_s_xizuo"] = "",
    ["designer:s4_s_xizuo"] = "",
    ["cv:s4_s_xizuo"] = "",
    ["illustrator:s4_s_xizuo"] = "",
    ["s4_s_anqi"] = "暗器",
    [":s4_s_anqi"] = "出牌阶段，你可以将武器牌当【杀】使用，你使用武器牌当做【杀】时无距离限制，并且不计入每回合的使用限制。",
    ["s4_s_citan"] = "刺探",
    [":s4_s_citan"] = "摸牌阶段，你可以改为观看攻击范围内的一名其他角色手牌，获得其一种花色的手牌，最多四张。",
    ["s4_s_citan-invoke"] = "你可以发动“刺探”<br/> <b>操作提示</b>: 选择一名其他角色→点击确定<br/>",
    ["s4_s_qianfu"] = "潜伏",
    [":s4_s_qianfu"] = "你的回合外，每当你受到一次牌造成的伤害后，相同颜色的牌对你无效，直到回合结束。",
}


s4_s_cike = sgs.General(extension_soldier, "s4_s_cike", "god", 4, true, false, false, 4)

s4_s_cisha = sgs.CreateTriggerSkill{
    name = "s4_s_cisha",
    frequency = sgs.Skill_Frequent,
    events = {sgs.DamageCaused, sgs.GameStart},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart then
            room:setPlayerMark(player, "&s4_s_cisha", 3)
            return false
        elseif event == sgs.DamageCaused then
             local damage = data:toDamage()
            if damage.card and (damage.card:isKindOf("Slash") or damage.card:isKindOf("Duel")) then
                if room:askForSkillInvoke(player, self:objectName(), data) then
                    room:broadcastSkillInvoke(self:objectName())
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    room:addPlayerMark(player, "&s4_s_cisha", damage.damage)
                end
            end
        end
        return false
    end,
}
s4_s_shangwuCard = sgs.CreateSkillCard{
    name = "s4_s_shangwu",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local shensimayi = source
        local choices = {}
        if not shensimayi:hasFlag("s4_s_shangwuTianyi") then
            table.insert(choices,"tianyi")
        end
        if not shensimayi:hasFlag("s4_s_shangwuQiangxi") then
            table.insert(choices,"qiangxi")
        end
        table.insert(choices,"cancel")
        if #choices == 1 then return end
        local choice = room:askForChoice(shensimayi, "s4_s_shangwu", table.concat(choices,"+"))
        if choice == "cancel" then
            room:addPlayerHistory(shensimayi, "#s4_s_shangwu", -1)
            return
        end
        shensimayi:loseMark("&s4_s_cisha")
        room:notifySkillInvoked(shensimayi, "s4_s_shangwu")
        room:setPlayerFlag(shensimayi, "s4_s_shangwu"..choice)
        room:acquireOneTurnSkills(shensimayi, "s4_s_shangwu",choice)
    end
}
s4_s_shangwuVS = sgs.CreateZeroCardViewAsSkill{
    name = "s4_s_shangwu",
    enabled_at_play = function(self,player)
        return player:usedTimes("#s4_s_shangwu") < 2 and player:getMark("&s4_s_cisha") > 0
    end,
    view_as = function()
        return s4_s_shangwuCard:clone()
    end
}


s4_s_shangwu = sgs.CreateTriggerSkill{
    name = "s4_s_shangwu",
    view_as_skill = s4_s_shangwuVS,
    events = {sgs.TargetSpecified, sgs.DrawNCards, sgs.AfterDrawNCards},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.TargetSpecified then
            if player:getMark("&s4_s_cisha") > 0 then
                if room:askForSkillInvoke(player, "s4_s_shangwu_liegong", data) then
                    room:removePlayerMark(player, "&s4_s_cisha")
                    room:broadcastSkillInvoke(self:objectName())
                    local liegong = sgs.Sanguosha:getTriggerSkill("liegong")
                    liegong:trigger(event, room, player, data)
                end
            end
        elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
            if draw.reason ~= "draw_phase" then return false end
            if player:getMark("&s4_s_cisha") > 0 then
                local tuxi = sgs.Sanguosha:getTriggerSkill("tenyeartuxi")
                if tuxi then
                    room:setPlayerMark(player, "tenyeartuxi", draw.num)
                    if player:askForSkillInvoke("s4_s_shangwu_tuxi",data)  then
                
                    room:notifySkillInvoked(player,self:objectName())
                    player:loseMark("&s4_s_cisha")
                    tuxi:trigger(event,room,player,data)
                    end
                    room:setPlayerMark(player, "tuxi", 0)
                end
            end
		elseif event == sgs.AfterDrawNCards then
			local draw = data:toDraw()
            if draw.reason ~= "draw_phase" then return false end
			local tuxiAct = sgs.Sanguosha:getTriggerSkill("#tenyeartuxi")
            if tuxiAct  then
                tuxiAct:trigger(event,room,player,data)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and target:isAlive() and target:hasSkill(self:objectName())
    end,
}

s4_s_yinghun = sgs.CreateTriggerSkill{
    name = "s4_s_yinghun",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageInflicted},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if player:isAlive() and not player:faceUp() then
                room:broadcastSkillInvoke(self:objectName())
                room:sendCompulsoryTriggerLog(player, self:objectName())
                player:damageRevises(data, -damage.damage)
                return true
            end
        end
        return false
    end,
}


s4_s_cike:addSkill(s4_s_cisha)
s4_s_cike:addSkill(s4_s_shangwu)
s4_s_cike:addSkill(s4_s_yinghun)

sgs.LoadTranslationTable {
    ["s4_s_cike"] = "刺客",
    ["&s4_s_cike"] = "刺客",
    ["#s4_s_cike"] = "暗影杀手",
    ["~s4_s_cike"] = "",
    ["designer:s4_s_cike"] = "",
    ["cv:s4_s_cike"] = "",
    ["illustrator:s4_s_cike"] = "",
    ["s4_s_cisha"] = "刺杀",
    [":s4_s_cisha"] = "游戏开始时，你拥有3枚“忍”标记。当你使用的【杀】或【决斗】造成伤害时，你可以获得同等于造成伤害数量的“忍”。",
    ["s4_s_shangwu"] = "尚武",
    [":s4_s_shangwu"] = "你可以弃1枚“忍”并发动以下技能之一：“突袭”、“天义”、“强袭”、“烈弓”。",
    ["s4_s_yinghun"] = "影魂",
    [":s4_s_yinghun"] = "锁定技，当你的武将牌背面朝上时，防止你受到伤害。",
}

--https://zhuanlan.zhihu.com/p/100584130






sgs.Sanguosha:addSkills(s4_skillList)
return { extension, extension_soldier }
