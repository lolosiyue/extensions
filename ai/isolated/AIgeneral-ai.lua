-- AIgeneral 隔離 AI。
-- 這裡只讀 viewer 可見的 value facade；角色私有資料、Engine 物件與 legacy
-- Card_Parse/cloneCard 均不會跨過 isolated 邊界。

local function unsupported(reason, key)
    return ai_unsupported(reason, key)
end

-- Unknown mode relations are not negative answers to friend/enemy questions.
local function relation(self, player)
    local value = self:relationTo(player)
    if value ~= "friend" and value ~= "enemy" and value ~= "neutral" then
        unsupported("player relation is unknown", "AIgeneral")
    end
    return value
end
local function is_friend(self, player) return relation(self, player) == "friend" end
local function is_enemy(self, player) return relation(self, player) == "enemy" end

local function offered(options)
    return type(options) == "table" and type(options.choices) == "table"
        and options.choices or nil
end

local function decision_context(self)
    return type(self.getDecisionContext) == "function" and self:getDecisionContext() or {}
end

local function context_player(self, event, key)
    local value = type(event) == "table" and event[key] or nil
    if AIValue.isPlayer(value) then return value end
    if type(value) == "string" then return self.room:findPlayerByObjectName(value, true) end
    return nil
end

local function context_targets(self, context)
    local targets = type(context) == "table" and context.to or nil
    if AIValue.isList(targets) then
        local result = AIList.new({})
        for _, value in ipairs(targets) do
            local player = AIValue.isPlayer(value) and value
                or type(value) == "string" and self.room:findPlayerByObjectName(value, true) or nil
            if not player then return nil end
            result:append(player)
        end
        return result
    end
    local target = context_player(self, context, "to")
    return target and AIList.new({target}) or nil
end

local function require_helper(self, name, key)
    if type(self[name]) ~= "function" then
        return unsupported("isolated helper is unavailable", key or name)
    end
    return true
end

local function call_value(object, method, key, ...)
    if type(object) ~= "table" or type(object[method]) ~= "function" then
        return unsupported("isolated value method is unavailable", key or method)
    end
    return object[method](object, ...)
end

-- 深度思考的舊版依賴 sgs.ai_role。isolated 沒有角色真值；關係記憶也不能
-- 被冒充成 lord/rebel/loyalist/renegade，因此兩個入口保留為明確缺口。
ai_skill_invoke.deep_seek = function(self, options, request)
    return unsupported("deep_seek requires viewer role prediction, not projected", "deep_seek")
end

ai_skill_choice.deep_seek = function(self, options, request)
    return unsupported("deep_seek role choice requires private role inference", "deep_seek")
end

-- KaiyuanShengshi is intentionally not registered: the legacy callback reads
-- private roles and mutates global roleValue. An unconditional unsupported
-- ChoiceMade hook would abort unrelated intention batches. This event gap has
-- no native fallback and remains documented as not ported.
-- tieba_zhili：保留兩輪目標分支與原順序。合法候選、敵我關係和 damage
-- effectiveness 必須由當次 card candidate／mode policy 提供。
ai_skill_activate.tieba_zhili = function(self, request)
    return unsupported("tieba_zhili needs a skill-card conversion and hurt policy", "tieba_zhili")
end

ai_card_use["tieba_zhiliCard"] = function(self, card, use)
    if not card or not use then return unsupported("tieba_zhili card request is incomplete", "tieba_zhili") end
    local candidate = self:getCardCandidate(card:getEffectiveId())
    if not candidate then return unsupported("tieba_zhili has no authorized card candidate", "tieba_zhili") end
    local legal = candidate:getLegalTargets()
    if not legal then return unsupported("tieba_zhili legal targets are unknown", "tieba_zhili") end
    if not require_helper(self, "cantbeHurt", "tieba_zhili")
        or not require_helper(self, "cantDamageMore", "tieba_zhili") then return nil end
    local allowed = {}
    for _, name in ipairs(legal) do allowed[name] = true end
    local enemies = self.enemies
    if not enemies then return unsupported("tieba_zhili enemy projection is unknown", "tieba_zhili") end
    local sorted = self:sort(enemies, "handcard", true)
    if not sorted then return unsupported("tieba_zhili enemy ordering is unknown", "tieba_zhili") end
    local function pick(strict)
        for _, enemy in ipairs(sorted) do
            local ehp, hp = enemy:getHp(), self.player:getHp()
            if allowed[enemy:objectName()] and type(ehp) == "number" and type(hp) == "number" and ehp < hp
                and self:cantbeHurt(enemy) ~= true
                and self:damageIsEffective(enemy, "N", self.player) == true
                and self:canDamage(enemy, self.player, nil) == true
                and (not strict or self:cantDamageMore(self.player, enemy) ~= true) then
                return enemy
            end
        end
    end
    local target = pick(true) or pick(false)
    if not target then return nil end
    use.card = card
    use.to:append(target)
end

-- 會員神力 target revise：getCardsNum 對自己只使用已知手牌，符合 viewer
-- 可見性；不可把他人的未知手牌當成零。
sgs.ai_target_revises = sgs.ai_target_revises or {}
sgs.ai_target_revises.huiyuanshenli = function(to, card, self, use)
    if not card or card:isKindOf("SkillCard") then return nil end
    local hand, peach = self.player:getHandcardNum(), self:getCardsNum("Peach")
    if type(hand) ~= "number" or type(peach) ~= "number" then
        return unsupported("huiyuanshenli viewer hand projection is unknown", "huiyuanshenli")
    end
    if hand - peach < 1 then return true end
end

-- Preserve the legacy marked-target gate and branch order. Unsupported policy
-- stays at the branch that needs it; generic low-keep selection is not the
-- legacy askForDiscard decision, and boolean true is not a cardask answer.
ai_skill_cardask["@huiyuanshenli"] = function(self, options, request)
    local use = decision_context(self).use
    if not use or not AIValue.isCard(use.card) then
        return unsupported("huiyuanshenli CardUse is not projected", "@huiyuanshenli")
    end
    local targets = context_targets(self, use)
    if not targets then return unsupported("huiyuanshenli targets are unknown", "@huiyuanshenli") end
    local function discard_branch()
        return unsupported("huiyuanshenli needs the legacy dummy-reason hand-only discard policy", "@huiyuanshenli")
    end
    local function affirmative_branch()
        return unsupported("legacy huiyuanshenli boolean cardask needs an explicit response-card policy", "@huiyuanshenli")
    end
    for _, target in ipairs(targets) do
        if target:getMark("huiyuanshenli-Clear") > 0 then
            local friend = is_friend(self, target)
            if friend == nil then return unsupported("huiyuanshenli relation is unknown", "@huiyuanshenli") end
            if friend then
                if use.card:isKindOf("AmazingGrace") then
                    local current = self.room:getCurrent()
                    local seat = call_value(target, "getSeat", "@huiyuanshenli")
                    local current_seat = call_value(current, "getSeat", "@huiyuanshenli")
                    local alive = self.room:getAlivePlayers()
                    if type(seat) ~= "number" or type(current_seat) ~= "number" or not alive or #alive == 0 then
                        return unsupported("huiyuanshenli seat order is unknown", "@huiyuanshenli")
                    end
                    if (seat - current_seat) % #alive < #alive / 2 then return discard_branch() end
                end
                if use.card:isKindOf("GodSalvation") then
                    local hp = call_value(target, "getHp", "@huiyuanshenli")
                    local maxhp = call_value(target, "getMaxHp", "@huiyuanshenli")
                    if type(hp) ~= "number" or type(maxhp) ~= "number" then
                        return unsupported("huiyuanshenli wounded state is unknown", "@huiyuanshenli")
                    end
                    if hp < maxhp then return discard_branch() end
                elseif use.card:isKindOf("ExNihilo") then return discard_branch() end
                if use.card:isKindOf("IronChain") then
                    local chained = call_value(target, "isChained", "@huiyuanshenli")
                    if chained == nil then return unsupported("huiyuanshenli chain state is unknown", "@huiyuanshenli") end
                    if chained then
                        require_helper(self, "isGoodChainTarget", "@huiyuanshenli")
                        local good = self:isGoodChainTarget(target)
                        if good == nil then return unsupported("huiyuanshenli chain policy is unknown", "@huiyuanshenli") end
                        if not good then return discard_branch() end
                    end
                end
                if use.card:isKindOf("Peach") then return affirmative_branch() end
            end
            local enemy = is_enemy(self, target)
            if enemy == nil then return unsupported("huiyuanshenli relation is unknown", "@huiyuanshenli") end
            if not enemy and friend then
                -- Original short-circuit next reads the friend's private role.
                return unsupported("huiyuanshenli loyalist-sacrifice role policy is not projected", "@huiyuanshenli")
            end
            if enemy then
                if use.card:isKindOf("AOE") then
                    return unsupported("huiyuanshenli AOE source, response estimates and Jueqing policy are unavailable", "@huiyuanshenli")
                elseif use.card:isKindOf("FireAttack") then
                    return unsupported("huiyuanshenli FireAttack effectiveness and Hongyan known-spade policy are unavailable", "@huiyuanshenli")
                elseif use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement")
                    or use.card:isKindOf("Zhujinqiyuan") or use.card:isKindOf("ZdShengdongjixi") then
                    local hand = target:getHandcardNum()
                    if type(hand) ~= "number" then return unsupported("huiyuanshenli hand count is unknown", "@huiyuanshenli") end
                    if hand > 0 then return unsupported("huiyuanshenli trick effectiveness is unavailable", "@huiyuanshenli") end
                elseif use.card:isKindOf("Duel") or use.card:isKindOf("chuqibuyi") then
                    return unsupported("huiyuanshenli trick effectiveness is unavailable", "@huiyuanshenli")
                elseif use.card:isKindOf("IronChain") then
                    require_helper(self, "isGoodChainTarget", "@huiyuanshenli")
                    local good = self:isGoodChainTarget(target)
                    if good == nil then return unsupported("huiyuanshenli chain policy is unknown", "@huiyuanshenli") end
                    if good then return affirmative_branch() end
                else
                    local damage = call_value(use.card, "isDamageCard", "@huiyuanshenli")
                    if damage == nil then return unsupported("huiyuanshenli damage-card classification is unknown", "@huiyuanshenli") end
                    if damage then return affirmative_branch() end
                end
            end
        end
    end
    return {kind = "pass"}
end
ai_skill_invoke.huiyuanshenli = function(self, options, request)
    local target = context_player(self, decision_context(self), "player")
    if not target then return unsupported("huiyuanshenli player is not projected", "huiyuanshenli") end
    local enemy = is_enemy(self, target)
    if enemy == nil then return unsupported("huiyuanshenli relation is unknown", "huiyuanshenli") end
    if enemy then
        require_helper(self, "cantbeHurt", "huiyuanshenli")
        local protected = self:cantbeHurt(target)
        if protected == nil then return unsupported("huiyuanshenli hurt policy is unknown", "huiyuanshenli") end
        if not protected then
            local effective = self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player)
            if effective == nil then return unsupported("huiyuanshenli damage policy is unknown", "huiyuanshenli") end
            if effective then
                local lose = self:needToLoseHp(target, self.player, nil)
                if lose == nil then return unsupported("huiyuanshenli HP-loss policy is unknown", "huiyuanshenli") end
                if not lose then return true end
            end
        end
    end
    local friend = is_friend(self, target)
    if friend == nil then return unsupported("huiyuanshenli relation is unknown", "huiyuanshenli") end
    if friend then
        local lose = self:needToLoseHp(target, self.player, nil)
        if lose == nil then return unsupported("huiyuanshenli HP-loss policy is unknown", "huiyuanshenli") end
        if lose then return true end
    end
    return false
end
-- 通義選擇：保留 Jink／Nullification 優先與最後的等機率 RNG。
ai_skill_choice.tongyiAIWJ = function(self, options, request)
    local choices = offered(options)
    local context, target = decision_context(self), nil
    target = context_player(self, context, "to")
    target = target or context_player(self, context, "player")
    if not choices or #choices == 0 or not target then
        return unsupported("tongyiAIWJ choices or target are not projected", "tongyiAIWJ")
    end
    local function answer(kind, flag)
        if not self.player:hasFlag(flag) then return nil end
        if target == self.player then
            local count = self:getCardsNum(kind)
            if type(count) ~= "number" then return unsupported("tongyiAIWJ known card count is unknown", "tongyiAIWJ") end
            return count > 0 and "yes" or "no"
        end
        local count = self:getCardsNum(kind, target)
        if type(count) ~= "number" then return unsupported("tongyiAIWJ known cards are unknown", "tongyiAIWJ") end
        if count > 0 then return "yes" end
    end
    local result = answer("Jink", "Jink") or answer("Nullification", "Nullification")
    if result then return result end
    return choices[math.random(1, #choices)]
end

-- tongyiTQ 是 legacy guhuo：原 callback 可任意製造宣稱牌，當次 isolated
-- request 若沒有 conversion ticket 便不能安全改寫成 card_spec。
ai_skill_activate.tongyiAIWJ = function(self, request)
    return unsupported("tongyiTQ requires an authorized conversion ticket", "tongyiTQ")
end

ai_skill_invoke.tiaojiaoCMT = function(self, options, request)
    local damage = decision_context(self).damage
    if type(damage) ~= "table" then return unsupported("tiaojiaoCMT damage is not projected", "tiaojiaoCMT") end
    local from = context_player(self, damage, "from")
    local target = context_player(self, damage, "to")
    if from ~= self.player then return false end
    if not target then return unsupported("tiaojiaoCMT damage target is unknown", "tiaojiaoCMT") end
    local friend, enemy = is_friend(self, target), is_enemy(self, target)
    if friend == nil or enemy == nil then return unsupported("tiaojiaoCMT relation is unknown", "tiaojiaoCMT") end
    local hp, maxhp = target:getHp(), target:getMaxHp()
    if type(hp) ~= "number" or type(maxhp) ~= "number" then return unsupported("tiaojiaoCMT HP is unknown", "tiaojiaoCMT") end
    if friend and hp < maxhp then
        local best = self:getBestHp(target)
        local hp = target:getHp()
        if type(best) ~= "number" or type(hp) ~= "number" then return unsupported("tiaojiaoCMT HP estimate is unknown", "tiaojiaoCMT") end
        if best < hp then return true end
    end
    if enemy then
        if type(damage.damage) ~= "number" then return unsupported("tiaojiaoCMT damage amount is unknown", "tiaojiaoCMT") end
        if damage.damage > 1 then return false end
        if hp < maxhp then
            local weak = self:isWeak(target)
            if weak == nil then return unsupported("tiaojiaoCMT weakness is unknown", "tiaojiaoCMT") end
            if weak then return false end
        end
        local discard = self:doDisCard(target, "h", true)
        if discard == nil then return unsupported("tiaojiaoCMT discard policy is unknown", "tiaojiaoCMT") end
        if hp >= maxhp then return discard end
        return discard and math.random() < 0.5
    end
    return false
end

ai_skill_invoke.daduanCMT = function(self, options, request)
    return true
end

-- getWoundedFriend／canDamageHp／needBear 不是目前 isolated core 的 ABI；保留
-- 原 callback 的技能鍵，等 authority 補齊純值 helper 後由本 handler 接通。
ai_skill_activate.tiaojiaoCMT = function(self, request)
    local hand = self.player:getHandcardNum()
    if type(hand) ~= "number" then return unsupported("tiaojiaoCMT hand count is unknown", "tiaojiaoCMT") end
    if hand > 2 then return nil end
    return unsupported("tiaojiaoCMT activation needs wounded-friend and conversion projections", "tiaojiaoCMT")
end

sgs.ai_use_priority.tiaojiaoCMTCard = 2.8

if type(ai_coverage) == "table" then
    ai_coverage.declare("AIgeneral", function()
        return {"deep_seek", "tieba_zhili", "huiyuanshenli", "tongyiAIWJ",
            "tongyiTQ", "tiaojiaoCMT", "daduanCMT"}
    end)
end
