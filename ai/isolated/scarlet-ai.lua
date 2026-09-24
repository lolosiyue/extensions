-- Scarlet 隔離 AI；藏拙／志繼的獨立參考 handler 見本檔末尾。
-- 以下 s4_sunjian（備陣／伐逆）對應舊版 lua/ai/scarlet-ai.lua 的
-- sgs.ai_skill_invoke／ai_skill_choice／ai_skill_cardchosen 與 getTurnUseCard。
-- 全部改用快照與值型答案；快照查不到的資料回 nil（NotCovered）交回 legacy，
-- 不在這層編預設答案。

-- 完殺下隊友的桃救不了自己；模式未覆蓋時只算自己看得見的桃酒。
local function peach_supply(self)
    local total = (self:getCardsNum("Peach") or 0) + (self:getCardsNum("Analeptic") or 0)
    local friends = self:getFriends()
    if friends then
        local current = self.room:getCurrent()
        local wansha = current ~= nil and current:hasSkill("wansha") or false
        for _, friend in ipairs(friends) do
            if friend:objectName() ~= self.player:objectName() and not wansha then
                total = total + (self:getCardsNum("Peach", friend) or 0)
            end
        end
    end
    return total
end

-- 備陣發動與否：有 hej 牌就能重鑄（技能的 isAllNude 已在詢問前擋掉空手）。
ai_skill_invoke["s4_beizhen"] = function(self, options, request)
    local cards = self.player:getCards("hej")
    if cards == nil then return nil end
    return #cards > 0
end

-- 瀕死邊緣才選 damage（救不回來就換加傷害）；其餘在 cancel 以外隨機。
ai_skill_choice["s4_beizhen"] = function(self, options, request)
    local items = type(options) == "table" and options.choices or nil
    if type(items) ~= "table" then return nil end
    local pool, has_damage = {}, false
    for _, choice in ipairs(items) do
        if choice == "damage" then has_damage = true end
        if choice ~= "cancel" then pool[#pool + 1] = choice end
    end
    if has_damage and (self.player:getHp() or 0) + peach_supply(self) - 1 <= 0 then
        return "damage"
    end
    if #pool == 0 then return nil end
    return pool[math.random(1, #pool)]
end

-- 備陣重鑄選牌：只會被要求選自己的牌；判定區延遲錦囊優先（言笑等增益除外），
-- 其餘按 use value 升冪取低於 6 的。沒有低價值牌回 nil，由 legacy 決定收手（-1）。
ai_skill_cardchosen["s4_beizhen"] = function(self, options, request)
    if type(options) ~= "table" then return nil end
    local players = options.players
    if type(players) ~= "table" or players[1] ~= self.player:objectName() then
        return nil
    end
    local judging = self.player:getJudgingArea()
    if judging then
        for _, card in ipairs(judging) do
            if not card:isKindOf("YanxiaoCard") then
                return card:getEffectiveId()
            end
        end
    end
    local flags = "hej"
    if type(options.choices) == "table" and #options.choices > 0 then
        flags = table.concat(options.choices)
    end
    local cards = self.player:getCards(flags)
    if cards == nil then return nil end
    local sorted = self:sortByUseValue(cards, true)
    if sorted then
        for _, card in ipairs(sorted) do
            if (self:getUseValue(card) or 0) < 6 then
                return card:getEffectiveId()
            end
        end
    end
    return nil
end

-- 伐逆選項：discard=<objectName> 只在伺服器驗過 canDiscard 時才出現；
-- 有背水機會一半機率直上，否則棄目標一牌，都不行就摸牌。
ai_skill_choice["s4_fani"] = function(self, options, request)
    local items = type(options) == "table" and options.choices or nil
    if type(items) ~= "table" then return nil end
    local discard_choice, has_bieshui, has_draw
    for _, choice in ipairs(items) do
        if type(choice) == "string" then
            if string.sub(choice, 1, 8) == "discard=" then
                discard_choice = choice
            elseif choice == "bieshui" then
                has_bieshui = true
            elseif choice == "draw" then
                has_draw = true
            end
        end
    end
    if discard_choice then
        local target = self.room:findPlayerByObjectName(string.sub(discard_choice, 9))
        local equips = target and target:getEquips() or nil
        if target and ((target:getHandcardNum() or 0) > 0 or (equips and #equips > 0)) then
            if has_bieshui and math.random() < 0.5 then return "bieshui" end
            return discard_choice
        end
    end
    if has_draw then return "draw" end
    return nil
end

-- 出牌階段：備陣 buff 生效時把【閃】/【桃】轉【決鬥】打最弱的敵人；
-- 模式未覆蓋時不猜敵我。掛進 decision-core 的 per-skill registry，
-- 一般 activate 與逐實例探測都會分派到這裡；實例請求的 context 由 C++ 回填，
-- result 不用帶 skill_action。其餘狀況回 nil 落到下一個技能或通用規劃。
ai_skill_activate["s4_beizhen"] = function(self, request)
    local probe = type(request.skill_action) == "table" and request.skill_action or nil
    local action = self:getSkillAction("s4_beizhen")
    if not (probe or (action and action:isValid())) then return nil end
    if not self.enemies then return nil end
    local hand = self.player:getHandcards()
    if not hand then return nil end
    for _, card in ipairs(hand) do
        if card:isKindOf("Jink") or card:isKindOf("Peach") then
            local target
            for _, enemy in ipairs(self.enemies) do
                if not target then target = enemy end
                if self:isWeak(enemy) == true then
                    target = enemy
                    break
                end
            end
            if target then
                return {
                    kind = "use_card",
                    skill_action = action and action:toAnswer() or nil,
                    cards = {card:getEffectiveId()},
                    targets = {target:objectName()}
                }
            end
            break
        end
    end
    return nil
end

-- 原版 Scarlet SmartAI 的藏拙：推薦評分 -> 摸牌 helper -> 好友 -> 首名候選。
-- fallback 仍是 isolated 策略；候選必須限於本次 authority 提供的集合。
ai_skill_playerchosen.s4_cangzhuo = function(self, options, request)
    if type(options) ~= "table" or options.candidates_complete ~= true
        or not AIValue.isList(options.players) or #options.players == 0 then
        return ai_unsupported("s4_cangzhuo requires complete candidates", "s4_cangzhuo")
    end
    local targets, offered = AIList.new({}), {}
    for _, name in ipairs(options.players) do
        local target = self.room:findPlayerByObjectName(name)
        if not target then
            return ai_unsupported("s4_cangzhuo candidate is not visible", "s4_cangzhuo")
        end
        targets:append(target)
        offered[name] = true
    end
    local target = self:getBestTargetOr(targets, "s4_cangzhuo", self.player, function(ai)
        local drawn = ai:findPlayerToDraw(false, 1, nil, targets)
        if drawn then return drawn end
        local friends = ai.friends_noself
        if not friends then
            return ai_unsupported("s4_cangzhuo friends are unknown", "s4_cangzhuo")
        end
        for _, friend in ipairs(friends) do
            if offered[friend:objectName()] then
                local can_draw = ai:canDraw(friend, ai.player)
                if can_draw == nil then
                    return ai_unsupported("s4_cangzhuo draw status is unknown", "s4_cangzhuo")
                end
                if can_draw then return friend end
            end
        end
        return targets:first()
    end)
    if not target or not offered[target:objectName()] then
        return ai_unsupported("s4_cangzhuo returned an unoffered target", "s4_cangzhuo")
    end
    return target:objectName()
end

-- 原版把藏拙登記為 draw；雖然實際獲得【影】，此處保留原 AI 評分語義。
sgs.registerSkillCardType("s4_cangzhuo", "draw")

-- 志繼保留原版順序、短路及 RNG 次數：背水 40%/20%，看破 60%，觀星 70%。
ai_skill_choice.s4_zhiji = function(self, options, request)
    if type(options) ~= "table" or not AIValue.isList(options.choices)
        or #options.choices == 0 then
        return ai_unsupported("s4_zhiji requires offered choices", "s4_zhiji")
    end
    local items, offered = options.choices, {}
    for _, choice in ipairs(items) do offered[choice] = true end
    local cards, judging = self:addHandPile("he"), self.player:getJudgingArea()
    if not cards or not judging then
        return ai_unsupported("s4_zhiji requires own cards", "s4_zhiji")
    end
    local black_count = 0
    for _, card in ipairs(cards) do
        local black = card:isBlack()
        if type(black) ~= "boolean" then
            return ai_unsupported("s4_zhiji card color is unknown", "s4_zhiji")
        end
        if black then black_count = black_count + 1 end
    end
    local has_judge = #judging > 0
    if offered.beishui then
        local can_damage = self:canDamage(self.player, self.player, nil)
        if can_damage == nil then return ai_unsupported("unknown self damage", "s4_zhiji") end
        if can_damage then
            local can_lose = self:canLoseHp(self.player, nil, self.player)
            if can_lose == nil then return ai_unsupported("unknown HP loss", "s4_zhiji") end
            if can_lose then
                local hp, hand = self.player:getHp(), self.player:getHandcardNum()
                local rescue = self:getAllPeachNum()
                local damage = self:ajustDamage(self.player, self.player, 1, nil)
                if type(hp) ~= "number" or type(hand) ~= "number"
                    or type(rescue) ~= "number" or type(damage) ~= "number" then
                    return ai_unsupported("unknown survival estimate", "s4_zhiji")
                end
                if hp + rescue - damage > 0 then
                    if (has_judge or hand <= 2) and math.random() < 0.4 then return "beishui" end
                    if math.random() < 0.2 then return "beishui" end
                end
            end
        end
    end
    if offered.kanpo and black_count >= 2 and math.random() < 0.6 then return "kanpo" end
    if offered.guanxing and has_judge and math.random() < 0.7 then return "guanxing" end
    local valid = {}
    for _, item in ipairs(items) do
        if item == "guanxing" or item == "kanpo" then valid[#valid + 1] = item end
    end
    if #valid > 0 then return valid[math.random(1, #valid)] end
    return items[1]
end
