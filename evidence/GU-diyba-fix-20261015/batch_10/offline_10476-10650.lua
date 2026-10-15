-- ===== diyba b20 =====
do
-- b20: diyba 东雪莲 (3DRE0)
local function diyba20_trigger(name, events, effect, frequency)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        frequency = frequency or sgs.Skill_NotFrequent,
        can_trigger = function(self, event, room, player, data)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then return self:objectName(), p end
            end
            return false
        end,
        on_effect = function(self, event, room, player, ctx)
            local cancelled = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then
                    cancelled = effect(self, event, room, player, ctx.original_data, p) or cancelled
                end
            end
            return cancelled
        end,
    }
end

-- 东雪莲
diyba_re0_dongxuelian = sgs.General(extension, "diyba_re0_dongxuelian", "qun", 3)

local diyba20_phases = { sgs.Player_Draw, sgs.Player_Play, sgs.Player_Discard }

-- 花海赤途 (+ 藕节铸骨 / 碧血丹心 bookkeeping is in the sibling skills)
diyba_huahai = diyba20_trigger("diyba_huahai", { sgs.DamageCaused, sgs.PreHpRecover, sgs.EventPhaseStart }, function(self, event, room, p, data, owner)
    if event == sgs.EventPhaseStart then
        if p ~= owner or owner:getPhase() ~= sgs.Player_RoundStart then return end
        local n = owner:getMark("diyba_huahai_skip")
        if n > 0 then
            for i = 1, math.min(n, 3) do owner:skip(diyba20_phases[i]) end
            room:setPlayerMark(owner, "diyba_huahai_skip", 0)
            room:setPlayerMark(owner, "diyba_bxdx_cut", 1)
        end
        return
    end
    local card
    local damage, recover
    if event == sgs.DamageCaused then
        damage = data:toDamage(); card = damage.card
    else
        recover = data:toRecover(); card = recover.card
    end
    if not card or not card:isRed() then return end
    if owner:getMark("diyba_huahai_used-Clear") > 0 then return end
    if owner:getMark("diyba_huahai_skip") >= 3 then return end
    if not owner:askForSkillInvoke("diyba_huahai", data) then return end
    room:setPlayerMark(owner, "diyba_huahai_used-Clear", 1)
    room:addPlayerMark(owner, "diyba_huahai_skip", 1)
    if damage then
        damage.damage = damage.damage + 1
        data:setValue(damage)
    else
        recover.recover = recover.recover + 1
        data:setValue(recover)
    end
    if room:getCurrent() == owner then room:setPlayerMark(owner, "diyba_huahai_inturn", 1) end
    if owner:getMark("diyba_ougezhu_done") == 0 and room:getCurrent() == owner and owner:isWounded()
        and owner:getMark("@diyba_ougezhu") == 0 and owner:getMark("diyba_ougezhu_used") == 0
        and owner:askForSkillInvoke("diyba_ougezhu", ToData(owner)) then
        room:setPlayerMark(owner, "diyba_ougezhu_used", 1)
        room:setPlayerMark(owner, "diyba_chongzheng", 1)
        room:setPlayerMark(owner, "@diyba_chongzheng", 1)
    end
    return false
end)

-- 藕节铸骨: limited; invoked from within 花海赤途 resolution above (approximation)
diyba_ougezhu = sgs.CreateTriggerSkillV2 {
    name = "diyba_ougezhu",
    frequency = sgs.Skill_Limited,
    events = {},
    can_trigger = function() return false end,
}

-- 碧血丹心
diyba_bixue = diyba20_trigger("diyba_bixue", { sgs.RoundStart, sgs.EventPhaseStart, sgs.EventPhaseEnd }, function(self, event, room, p, data, owner)
    if event == sgs.RoundStart then
        -- approximation of "一轮结束时": evaluated when the next round begins
        if owner:getMark("diyba_bxdx_seen") > 0 then
            if owner:getMark("diyba_bxdx_full") == 0 or owner:getMark("diyba_bxdx_cut") > 0 then
                room:broadcastSkillInvoke("diyba_bixue")
                -- 涉猎
                local ids = room:getNCards(5)
                room:fillAG(ids)
                local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                local pool = sgs.IntList()
                for _, id in sgs.qlist(ids) do pool:append(id) end
                local drop = sgs.IntList()
                while pool:length() > 0 do
                    local id = room:askForAG(owner, pool, false, "diyba_bixue")
                    dummy:addSubcard(id)
                    room:takeAG(owner, id, false)
                    for _, o in sgs.qlist(ids) do
                        if pool:contains(o) and o ~= id and sgs.Sanguosha:getCard(o):getSuit() == sgs.Sanguosha:getCard(id):getSuit() then
                            drop:append(o); room:takeAG(nil, o, false); pool:removeOne(o)
                        end
                    end
                    pool:removeOne(id)
                end
                room:clearAG()
                owner:obtainCard(dummy)
                dummy:deleteLater()
                if not drop:isEmpty() then room:throwCard(drop, "diyba_bixue", nil) end
                -- 弃牌阶段
                local n = owner:getHandcardNum() - owner:getMaxCards()
                if n > 0 then room:askForDiscard(owner, "diyba_bixue", n, n, false, false) end
            end
        end
        room:setPlayerMark(owner, "diyba_bxdx_seen", 1)
        room:setPlayerMark(owner, "diyba_bxdx_full", 0)
        room:setPlayerMark(owner, "diyba_bxdx_cut", 0)
    elseif event == sgs.EventPhaseStart then
        if p ~= owner or owner:getPhase() ~= sgs.Player_RoundStart then return end
        if owner:getMark("diyba_chongzheng") > 0 then
            -- 重整 approximation: skip all phases, recover 1 hp per own turn until full
            for _, ph in ipairs({ sgs.Player_Judge, sgs.Player_Draw, sgs.Player_Play, sgs.Player_Discard }) do owner:skip(ph) end
            room:setPlayerMark(owner, "diyba_bxdx_cut", 1)
            local r = sgs.RecoverStruct(); r.who = owner; r.recover = 1
            room:recover(owner, r)
            if not owner:isWounded() then
                room:setPlayerMark(owner, "diyba_chongzheng", 0)
                room:setPlayerMark(owner, "@diyba_chongzheng", 0)
                room:setPlayerMark(owner, "diyba_bixue_extra", 1)
                owner:gainAnExtraTurn()
            end
        elseif owner:getMark("diyba_bixue_extra") > 0 then
            room:setPlayerMark(owner, "diyba_bixue_extra", 0)
            room:setPlayerMark(owner, "diyba_bixue_redfree", 1)
        end
    else
        if p ~= owner or owner:getPhase() ~= sgs.Player_Finish then return end
        room:setPlayerMark(owner, "diyba_bxdx_full", 1)
        room:setPlayerMark(owner, "diyba_bixue_redfree", 0)
    end
    return false
end, sgs.Skill_Compulsory)

diyba_bixue_mod = sgs.CreateTargetModSkillV2 {
    name = "#diyba_bixue_mod", pattern = ".", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local from, card = ctx:getPrimary(), ctx:getCard()
        if from and card and card:isRed() and from:getMark("diyba_bixue_redfree") > 0 then
            if ctx:getModType() == sgs.TargetModSkill_DistanceLimit then return 999 end
            if ctx:getModType() == sgs.TargetModSkill_Residue then return 999 end
        end
        return 0
    end,
}

diyba_re0_dongxuelian:addSkill(diyba_huahai)
diyba_re0_dongxuelian:addSkill(diyba_ougezhu)
diyba_re0_dongxuelian:addSkill(diyba_bixue)
diyba_re0_dongxuelian:addSkill(diyba_bixue_mod)

sgs.LoadTranslationTable {
    ["diyba_re0_dongxuelian"] = "东雪莲",
    ["#diyba_re0_dongxuelian"] = "玉池莲绽",
    ["designer:diyba_re0_dongxuelian"] = "秦心",
    ["diyba_huahai"] = "花海赤途",
    [":diyba_huahai"] = "每回合限一次，你可按顺序跳过你下回合的一个主要阶段来令一张红色牌的伤害值或回复值+1。",
    ["diyba_ougezhu"] = "藕节铸骨",
    [":diyba_ougezhu"] = "限定技，你于你的回合内发动【花海赤途】后，若你已受伤，你可以进入重整状态直到你回复所有体力。",
    ["@diyba_chongzheng"] = "重整",
    ["diyba_bixue"] = "碧血丹心",
    [":diyba_bixue"] = "锁定技，一轮结束时，若你本轮未执行完整的额定回合，你发动一次“涉猎”并执行一个弃牌阶段。你脱离重整状态后，执行一个使用红色牌仅受目标数限制的额外回合。",
}
end

