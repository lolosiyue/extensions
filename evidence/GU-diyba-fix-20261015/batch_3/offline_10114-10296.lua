-- ===== diyba b17 =====
do
-- b17: diyba_19j_yanzhenqing (canggu, xuanwen)
local function diyba_rule(name, events, can, effect, frequency)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true, frequency = frequency or sgs.Skill_NotFrequent,
        can_trigger = function(self, event, room, player, data)
            local owner = can(self, event, room, player, data)
            if owner then return self:objectName(), owner end
            return false
        end,
        on_effect = function(self, event, room, player, ctx)
            return effect(self, event, room, player, ctx.original_data, ctx) or false
        end,
    }
end

diyba_19j_yanzhenqing = sgs.General(extension, "diyba_19j_yanzhenqing", "qun", 3)

diyba_canggu = diyba_rule("diyba_canggu", { sgs.Damaged },
    function(self, event, room, player, data)
        local damage = data:toDamage()
        if not damage.from or damage.from:isDead() or damage.from:objectName() == player:objectName() then return nil end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasSkill(self:objectName()) and p:objectName() ~= damage.from:objectName()
                and p:objectName() ~= player:objectName() and not p:inMyAttackRange(player) and not p:isNude() then
                return p
            end
        end
        return nil
    end,
    function(self, event, room, player, data, ctx)
        local owner = room:findPlayerBySkillName(self:objectName())
        local damage = data:toDamage()
        if not owner or not damage.from then return false end
        if not room:askForSkillInvoke(owner, self:objectName(), data) then return false end
        local c = room:askForCard(owner, ".|black", "@diyba_canggu", data, sgs.Card_MethodDiscard, nil, false, self:objectName())
        if not c then return false end
        local choice = room:askForChoice(owner, self:objectName(), "diyba_canggu_recover+diyba_canggu_damage", data)
        if choice == "diyba_canggu_recover" then
            room:setPlayerMark(damage.from, "@diyba_canggu_norecover", 1)
        else
            room:setPlayerMark(damage.from, "@diyba_canggu_nodamage", 1)
        end
        return false
    end)

diyba_canggu_effect = diyba_rule("#diyba_canggu_effect", { sgs.PreHpRecover, sgs.DamageCaused, sgs.Damage, sgs.HpRecover },
    function(self, event, room, player, data)
        if player and player:isAlive() and (player:getMark("@diyba_canggu_norecover") > 0 or player:getMark("@diyba_canggu_nodamage") > 0) then
            return player
        end
        return nil
    end,
    function(self, event, room, player, data, ctx)
        if event == sgs.PreHpRecover then
            return player:getMark("@diyba_canggu_norecover") > 0
        elseif event == sgs.DamageCaused then
            local damage = data:toDamage()
            return damage.from and damage.from:objectName() == player:objectName() and player:getMark("@diyba_canggu_nodamage") > 0
        elseif event == sgs.Damage then
            local damage = data:toDamage()
            if damage.from and damage.from:objectName() == player:objectName() then
                room:setPlayerMark(player, "@diyba_canggu_norecover", 0)
            end
        elseif event == sgs.HpRecover then
            room:setPlayerMark(player, "@diyba_canggu_nodamage", 0)
        end
        return false
    end)

-- xuanwen: track hand/hp from 0 via marks. APPROXIMATION: card chosen by translated-name char count.
local function diyba_len(s)
    local n = 0
    for _ in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do n = n + 1 end
    return n
end
local diyba_xuanwen_names = { "slash", "jink", "peach", "analeptic", "ex_nihilo", "snatch", "dismantlement", "duel",
    "collateral", "nullification", "indulgence", "supply_shortage", "amazing_grace", "god_salvation",
    "savage_assault", "archery_attack", "iron_chain", "fire_attack", "fire_slash", "thunder_slash" }

local function diyba_xuanwen_use(room, owner, x)
    local lens = { x }
    local black, red = 0, 0
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        for _, c in sgs.qlist(p:getCards("ej")) do
            if c:isBlack() then black = black + 1 else red = red + 1 end
        end
    end
    if black > red then table.insert(lens, x + 1); if x > 1 then table.insert(lens, x - 1) end end
    local names = {}
    for _, n in ipairs(diyba_xuanwen_names) do
        local card = sgs.Sanguosha:cloneCard(n, sgs.Card_NoSuit, 0)
        if card then
            local l = diyba_len(sgs.Sanguosha:translate(n))
            for _, w in ipairs(lens) do
                if l == w and card:isAvailable(owner) then table.insert(names, n) break end
            end
            card:deleteLater()
        end
    end
    if #names == 0 then return end
    local name = room:askForChoice(owner, "diyba_xuanwen", table.concat(names, "+"))
    local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
    card:setSkillName("diyba_xuanwen")
    local use = sgs.CardUseStruct()
    use.from = owner
    use.card = card
    if card:targetFixed() then
        room:useCard(use, false)
    else
        local tos = sgs.PlayerList()
        local cands = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if card:targetFilter(tos, p, owner) and not owner:isProhibited(p, card) then cands:append(p) end
        end
        if cands:isEmpty() then card:deleteLater() return end
        local t = room:askForPlayerChosen(owner, cands, "diyba_xuanwen", "@diyba_xuanwen", false)
        use.to:append(t)
        room:useCard(use, false)
    end
    card:deleteLater()
end

diyba_xuanwen = diyba_rule("diyba_xuanwen", { sgs.CardsMoveOneTime, sgs.HpChanged, sgs.HpRecover },
    function(self, event, room, player, data)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasSkill(self:objectName()) then return p end
        end
        return nil
    end,
    function(self, event, room, player, data, ctx)
        for _, owner in sgs.qlist(room:getAlivePlayers()) do
            if owner:hasSkill(self:objectName()) then
                local hand, hp = owner:getHandcardNum(), owner:getHp()
                local ph, php = owner:getMark("diyba_xuanwen_hand"), owner:getMark("diyba_xuanwen_hp")
                room:setPlayerMark(owner, "diyba_xuanwen_hand", hand)
                room:setPlayerMark(owner, "diyba_xuanwen_hp", hp)
                local red_more = false
                local black, red = 0, 0
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    for _, c in sgs.qlist(p:getCards("ej")) do
                        if c:isBlack() then black = black + 1 else red = red + 1 end
                    end
                end
                red_more = red > black
                local from_ok = function(v) return v == 0 or (red_more and v == 1) end
                local x = 0
                if from_ok(ph) and hand > ph then x = hand - ph
                elseif from_ok(php) and hp > php then x = hp - php end
                if x > 0 and hand > 0 and hp > 0 then
                    local dying = false
                    for _, p in sgs.qlist(room:getAlivePlayers()) do if p:getHp() <= 0 then dying = true end end
                    if not dying and room:askForSkillInvoke(owner, self:objectName(), data) then
                        diyba_xuanwen_use(room, owner, x)
                    end
                end
            end
        end
        return false
    end)

diyba_19j_yanzhenqing:addSkill(diyba_canggu)
diyba_19j_yanzhenqing:addSkill(diyba_canggu_effect)
diyba_19j_yanzhenqing:addSkill(diyba_xuanwen)

sgs.LoadTranslationTable {
    ["diyba_19j_yanzhenqing"] = "颜真卿",
    ["#diyba_19j_yanzhenqing"] = "翰墨忠烈",
    ["designer:diyba_19j_yanzhenqing"] = "Doctrine",
    ["diyba_canggu"] = "苍骨",
    [":diyba_canggu"] = "当其他角色对你攻击范围外的角色造成伤害后，你可以弃置一张黑色牌并选择一项：1.防止其体力回复直到其造成伤害；2.防止其造成伤害直到其回复体力。",
    ["@diyba_canggu"] = "苍骨：请弃置一张黑色牌",
    ["diyba_canggu_recover"] = "防止其体力回复直到其造成伤害",
    ["diyba_canggu_damage"] = "防止其造成伤害直到其回复体力",
    ["@diyba_canggu_norecover"] = "苍骨·禁回复",
    ["@diyba_canggu_nodamage"] = "苍骨·禁伤害",
    ["diyba_xuanwen"] = "玄文",
    [":diyba_xuanwen"] = "当你的手牌数或体力值由０变至不为０后，若没有角色处于濒死状态，你可以视为使用一张字数为X的牌（X为此次变动值）。若场上：黑色牌更多，X值可灵活变动１；红色牌更多，首句时机中的值可灵活变动１。",
    ["@diyba_xuanwen"] = "玄文：请选择目标",
}
end

