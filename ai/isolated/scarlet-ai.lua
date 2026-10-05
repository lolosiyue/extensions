-- Scarlet 隔離 AI。共用 SmartAI 相等函式在 smart-ai-functions.lua，
-- 本檔只擴充技能名單、決鬥點數與各 s4 handler，不改基礎層。
-- 藏拙／志繼的獨立參考 handler 見本檔中段。
-- 以下 s4_sunjian（備陣／伐逆）對應舊版 lua/ai/scarlet-ai.lua 的
-- sgs.ai_skill_invoke／ai_skill_choice／ai_skill_cardchosen 與 getTurnUseCard。
-- s4_cloud_zhangliao（突襲／勇前）對應同檔原版 invoke／choice／discard／
-- playerchosen／cardneed／choicemade_filter，決策順序不變。
-- s4_cloud_huangzhong（烈弓／勇毅）對應同檔原版 invoke／cardneed／card_value／
-- ajustdamage／canliegong／activate 視為酒／card_priority／skill_defense。
-- s4_cloud_sunquan（英姿）對應同檔原版 notActive_cardneed／need_equip 標籤，
-- 並讀取英姿實例 state／公開 correct_state.x；制衡與救援屬其他包，
-- 未覆蓋時交回 SmartAI。
-- s4_lubu（先鋒／戟舞）對應同檔原版 cardneed／card_value／double_slash／
-- discard／choice；缺投影（含牌旗）回 unsupported。
-- s4_zhaoyun（救主）對應同檔原版 askforag／playerchosen／discard／invoke
-- 與留牌標籤；AG 選中的給牌目標用 ai_memory 跨問。
-- s4_huanzhaoyun（龍心／截戰）對應同檔原版 activate／invoke／choice／
-- slash_prohibit／card_priority／cardneed。
-- s4_zhurong（烈刃／巨象）對應同檔原版 fire_slash 出牌、target_revises、
-- invoke／playerchosen／pindian／choice／ajustdamage。
-- s4_guanyu（武聖／奔襲）對應同檔原版 view-as 殺、invoke、cardneed、ajustdamage。
-- s4_zhangfei（咆哮）對應同檔原版 use_revises／cardneed。
-- s4_machao（鐵騎）對應同檔原版 invoke／askforag。
-- s4_huangzhong（烈弓）對應同檔原版 canliegong／ajustdamage。
-- s4_2_zhaoyun（龍膽）對應同檔原版 activate／playerchosen／invoke／cardneed。
-- 全部改用快照與值型答案；快照查不到的資料回 nil（NotCovered）交回 legacy，
-- 不在這層編預設答案。

-- 這些名單是基礎層的擴充點，對應舊版 scarlet-ai.lua 的字串拼接。
sgs.append_skill_list("drawpeach_skill", "s4_cloud_tuxi")
sgs.append_skill_list("dont_kongcheng_skill", "s4_cloud_tuxi")
sgs.append_skill_list("dont_kongcheng_skill", "s4_jiuzhu")
sgs.append_skill_list("hit_skill", "s4_cloud_yongyi")
sgs.append_skill_list("hit_skill", "s4_jiwu")
sgs.append_skill_list("notActive_cardneed_skill", "s4_cloud_yingzi")
sgs.append_skill_list("notActive_cardneed_skill", "s4_jiuzhu")
sgs.append_skill_list("need_equip_skill", "s4_cloud_yingzi")
sgs.append_skill_list("double_slash_skill", "s4_xianfeng")
sgs.append_skill_list("bad_skills", "s4_neiji")

-- 天下霸武單挑點數。只加在 Scarlet，基礎層的 getMaxCard 不認識這些技能。
function SmartAIView:getGeneralDuelPoint(player, card)
    if not card then return nil end
    player = player or self.player
    local point = card:getNumber()
    if type(point) ~= "number" then return nil end
    if player:hasSkill("s4_txbw_motian") then
        point = point + (player:getMark("TurnLengthCount") or 0)
    end
    if player:hasSkill("s4_txbw_yizhong") then
        local hp = player:getHp()
        if type(hp) ~= "number" then return nil end
        point = point + hp / 2
    end
    if player:hasSkill("s4_txbw_wanpo") then point = point + 1 end
    if player:hasSkill("s4_txbw_wusheng") and card:isRed() then point = point + 2 end
    return point
end

function SmartAIView:getGeneralDuelCard(player, cards)
    player = player or self.player
    if cards == nil then
        cards = player:objectName() == self.player:objectName() and player:getHandcards() or player:getKnownCards()
    end
    if not cards then return nil end
    if player:hasSkill("s4_txbw_yishi") then
        -- The shared sorter leaves the input unchanged and can report unknown.
        cards = self:sortByUseValue(cards, true)
        if cards == nil then
            -- Callers use nil for no card; an unknown order must not become declined.
            ai_unsupported("general duel card order is unknown", "s4_txbw_yishi")
        end
        return cards[1]
    end
    local function pick(skip_valuable)
        local best, best_point
        for _, card in ipairs(cards) do
            local skip = false
            if skip_valuable and player:objectName() == self.player:objectName() then
                local valuable = self:isValuableCard(card, player)
                if valuable == nil then return nil, "unknown" end
                skip = valuable == true
            end
            if not skip then
                local point = self:getGeneralDuelPoint(player, card)
                if point == nil then return nil, "unknown" end
                if not best_point or point > best_point then best, best_point = card, point end
            end
        end
        return best
    end
    local card, status = pick(true)
    if status == "unknown" then return nil end
    if player:objectName() == self.player:objectName() and not card then
        card, status = pick(false)
        if status == "unknown" then return nil end
    end
    return card
end

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

-- s4_cloud_zhangliao：原版 lua/ai/scarlet-ai.lua 的勇前／突襲。
-- 勇前摸牌階段選人可取消；TargetConfirmed 的 invoke 原版恆 true。
ai_skill_invoke.s4_cloud_yongqian = function()
    return true
end

ai_skill_playerchosen.s4_cloud_yongqian = function(self, options, request)
    if type(options) ~= "table" or options.candidates_complete ~= true
        or not AIValue.isList(options.players) then
        return ai_unsupported("s4_cloud_yongqian requires complete candidates", "s4_cloud_yongqian")
    end
    if not self.enemies or not self.friends_noself then
        return ai_unsupported("s4_cloud_yongqian relations are unknown", "s4_cloud_yongqian")
    end
    local offered = {}
    for _, name in ipairs(options.players) do offered[name] = true end
    local sorted = self:sort(self.enemies, "handcard")
    if not sorted then
        return ai_unsupported("s4_cloud_yongqian enemy hand order is unknown", "s4_cloud_yongqian")
    end
    for _, enemy in ipairs(sorted) do
        if offered[enemy:objectName()] then
            local attack = self:canAttack(enemy, self.player)
            if attack == nil then
                return ai_unsupported("s4_cloud_yongqian canAttack is unknown", "s4_cloud_yongqian")
            end
            local liuli = self:canLiuli(enemy, self.friends_noself)
            if liuli == nil then
                return ai_unsupported("s4_cloud_yongqian canLiuli is unknown", "s4_cloud_yongqian")
            end
            local leiji = self:findLeijiTarget(enemy, 50, self.player)
            if attack and not liuli and not leiji then
                return enemy:objectName()
            end
        end
    end
    if options.optional then return {kind = "pass"} end
    return nil
end

sgs.ai_cardneed.s4_cloud_yongqian = function(to, card)
    local n = to:getHandcardNum()
    if type(n) ~= "number" then return nil end
    return n < 3 and card:isKindOf("Slash")
end

sgs.ai_cardneed.s4_cloud_tuxi = function(to)
    return to:isKongcheng()
end

-- 棄牌失敗後的失去體力；原版固定選 1。
ai_skill_choice.s4_cloud_tuxi = function(self, options, request)
    local items = type(options) == "table" and options.choices or nil
    if type(items) ~= "table" then
        return ai_unsupported("s4_cloud_tuxi choices are missing", "s4_cloud_tuxi")
    end
    for _, choice in ipairs(items) do
        if choice == "1" then return "1" end
    end
    return ai_unsupported("s4_cloud_tuxi choice 1 was not offered", "s4_cloud_tuxi")
end

-- 原版 data:toPlayer() 是當前回合角色；投影在 context.player，缺則讀 getCurrent。
ai_skill_invoke.s4_cloud_tuxi = function(self, options, request)
    local context = self:getDecisionContext()
    local target = context and context.player or self.room:getCurrent()
    if not target then
        return ai_unsupported("s4_cloud_tuxi target is not projected", "s4_cloud_tuxi")
    end
    local enemy = self:isEnemy(target)
    if enemy == nil then
        return ai_unsupported("s4_cloud_tuxi relation is unknown", "s4_cloud_tuxi")
    end
    if not enemy then return false end
    local hand, thand = self.player:getHandcardNum(), target:getHandcardNum()
    local hp, thp = self.player:getHp(), target:getHp()
    local equips, tequips = self.player:getEquips(), target:getEquips()
    if type(hand) ~= "number" or type(thand) ~= "number"
        or type(hp) ~= "number" or type(thp) ~= "number"
        or not equips or not tequips then
        return ai_unsupported("s4_cloud_tuxi visible counts are unknown", "s4_cloud_tuxi")
    end
    if hand <= thand then return true end
    if hp <= thp then return true end
    local can = self.player:canDiscard(self.player, "he")
    if can == nil then
        return ai_unsupported("s4_cloud_tuxi canDiscard is unknown", "s4_cloud_tuxi")
    end
    if #equips <= #tequips and can then return true end
    return false
end

-- 原版：敵方且體力>1 就拒棄（改失體力）；體力<=1 才 dummy 棄 1。非敵或無當前回合拒棄。
ai_skill_discard.s4_cloud_tuxi = function(self, options, request)
    local target = self.room:getCurrent()
    if not target then return {kind = "pass"} end
    local enemy = self:isEnemy(target)
    if enemy == nil then
        return ai_unsupported("s4_cloud_tuxi discard relation is unknown", "s4_cloud_tuxi")
    end
    if not enemy then return {kind = "pass"} end
    local hp = self.player:getHp()
    if type(hp) ~= "number" then
        return ai_unsupported("s4_cloud_tuxi hp is unknown", "s4_cloud_tuxi")
    end
    if hp > 1 then return {kind = "pass"} end
    if type(options) ~= "table" or options.candidates_complete ~= true then
        return ai_unsupported("s4_cloud_tuxi discard candidates are incomplete", "s4_cloud_tuxi")
    end
    local ids = options.card_ids
    if type(ids) ~= "table" or #ids == 0 then return {kind = "pass"} end
    local cards = self.player:getCards("he")
    if not cards then
        return ai_unsupported("s4_cloud_tuxi discard cards are unknown", "s4_cloud_tuxi")
    end
    local offered, pool = {}, AIList.new({})
    for _, id in ipairs(ids) do offered[id] = true end
    for _, card in ipairs(cards) do
        if offered[card:getEffectiveId()] then pool:append(card) end
    end
    if #pool == 0 then return {kind = "pass"} end
    local sorted = self:sortByKeepValue(pool, false)
    if not sorted then
        return ai_unsupported("s4_cloud_tuxi keep values are unknown", "s4_cloud_tuxi")
    end
    return {sorted[1]:getEffectiveId()}
end

sgs.ai_choicemade_filter = sgs.ai_choicemade_filter or {}
sgs.ai_choicemade_filter.skillInvoke = sgs.ai_choicemade_filter.skillInvoke or {}
sgs.ai_choicemade_filter.skillInvoke.s4_cloud_tuxi = function(self, player, promptlist)
    local current = self.room:getCurrent()
    if not current or not player or type(promptlist) ~= "table" then return end
    if promptlist[#promptlist] ~= "yes" then return end
    local need = self:needToLoseHp(current, player, nil)
    if need == false then
        sgs.updateIntention(player, current, 40)
    end
end

sgs.drawpeach_skill = sgs.drawpeach_skill or "tuxi|qiaobian"
if not sgs.drawpeach_skill:find("s4_cloud_tuxi", 1, true) then
    sgs.drawpeach_skill = sgs.drawpeach_skill .. "|s4_cloud_tuxi"
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill or ""
if not sgs.dont_kongcheng_skill:find("s4_cloud_tuxi", 1, true) then
    sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|s4_cloud_tuxi"
end

-- s4_cloud_huangzhong：原版 lua/ai/scarlet-ai.lua 的烈弓／勇毅。
local function s4_cloud_yongyi_contains(list, item)
    if type(list) ~= "table" then return false end
    for _, value in ipairs(list) do
        if value == item then return true end
    end
    return false
end

local function s4_cloud_yongyi_ai_parse_records(raw)
    local records = {}
    if not raw or raw == "" then return records end
    if type(raw) ~= "string" then return records end
    for suit in string.gmatch(raw, "[^,]+") do
        if suit ~= "" and suit ~= "no_suit" and not s4_cloud_yongyi_contains(records, suit) then
            records[#records + 1] = suit
        end
    end
    return records
end

local function s4_cloud_yongyi_ai_records_from_marks(player, instance_id)
    local names = player:getMarkNames()
    if not names then return nil end
    local id = tostring(instance_id)
    local prefixes = {
        "&s4_cloud_yongyi+#record+" .. id .. "+",
        "&s4_cloud_yongyi+#record+sys_" .. id .. "+"
    }
    local records = {}
    for _, mark in ipairs(names) do
        if player:getMark(mark) > 0 then
            for _, prefix in ipairs(prefixes) do
                if mark:sub(1, #prefix) == prefix then
                    local rest = mark:sub(#prefix + 1)
                    for token in string.gmatch(rest, "[^+]+") do
                        local suit = token:match("^(.*)_char$") or token
                        if suit ~= "" and suit ~= "no_suit"
                            and not s4_cloud_yongyi_contains(records, suit) then
                            records[#records + 1] = suit
                        end
                    end
                end
            end
        end
    end
    return records
end

local function s4_cloud_yongyi_ai_get_records(player, instance_id)
    if not player or not instance_id or instance_id <= 0 then return {} end
    local ids = player:getSkillInstanceIds("s4_cloud_yongyi")
    if not ids then return nil end
    local raw = player:getSkillInstanceStateValue(
        "s4_cloud_yongyi", instance_id, "records", "")
    if type(raw) == "string" and raw ~= "" then
        return s4_cloud_yongyi_ai_parse_records(raw)
    end
    local from_marks = s4_cloud_yongyi_ai_records_from_marks(player, instance_id)
    if from_marks == nil then return nil end
    if #from_marks > 0 then return from_marks end
    return s4_cloud_yongyi_ai_parse_records(raw)
end

local function s4_cloud_yongyi_ai_valid_instance_ids(player)
    local ids = {}
    if not player then return ids end
    local listed = player:getSkillInstanceIds("s4_cloud_yongyi")
    if not listed then return nil end
    for _, instance_id in ipairs(listed) do
        if instance_id > 0 then
            local has = player:hasSkillInstance("s4_cloud_yongyi", instance_id)
            local invalid = player:isSkillInvalid("s4_cloud_yongyi", instance_id)
            if has == nil or invalid == nil then return nil end
            if has and not invalid then ids[#ids + 1] = instance_id end
        end
    end
    return ids
end

local function s4_cloud_yongyi_ai_max_records(player)
    local ids = s4_cloud_yongyi_ai_valid_instance_ids(player)
    if not ids then return nil end
    local max_records = 0
    for _, instance_id in ipairs(ids) do
        local records = s4_cloud_yongyi_ai_get_records(player, instance_id)
        if not records then return nil end
        if #records > max_records then max_records = #records end
    end
    return max_records
end

ai_skill_invoke.s4_cloud_liegong = function(self)
    local context = self:getDecisionContext()
    local target = context and context.player
    if not target then
        return ai_unsupported("s4_cloud_liegong target is not projected", "s4_cloud_liegong")
    end
    local friend = self:isFriend(target)
    if friend == nil then
        return ai_unsupported("s4_cloud_liegong relation is unknown", "s4_cloud_liegong")
    end
    return not friend
end

sgs.ai_cardneed.s4_cloud_liegong = function(to, card)
    local n = to:getHandcardNum()
    if type(n) ~= "number" then return nil end
    return n < 3 and card:isKindOf("Slash")
end

sgs.card_value = sgs.card_value or {}
sgs.card_value.s4_cloud_liegong = {
    Analeptic = 4.9,
    Slash = 7.2
}

sgs.ai_ajustdamage_from = sgs.ai_ajustdamage_from or {}
sgs.ai_ajustdamage_from.s4_cloud_liegong = function(self, from, to, card)
    if not (card and card:isKindOf("Slash") and to and from) then return end
    local to_hp, from_hp, from_range = to:getHp(), from:getHp(), from:getAttackRange()
    if type(to_hp) ~= "number" or type(from_hp) ~= "number"
        or type(from_range) ~= "number" then
        return nil
    end
    if to_hp >= from_hp or to_hp <= from_range then
        local friend = self:isFriend(to, from)
        if friend == nil then return nil end
        if not friend then return 1 end
    end
end

sgs.ai_canliegong_skill = sgs.ai_canliegong_skill or {}
sgs.ai_canliegong_skill.s4_cloud_liegong = function(self, from, to)
    local to_hand, from_hp, from_range = to:getHandcardNum(), from:getHp(), from:getAttackRange()
    if type(to_hand) ~= "number" or type(from_hp) ~= "number"
        or type(from_range) ~= "number" then
        return nil
    end
    return to_hand >= from_hp or to_hand <= from_range
end

ai_skill_invoke.s4_cloud_yongyi = function(self)
    local max_records = s4_cloud_yongyi_ai_max_records(self.player)
    if max_records == nil then
        return ai_unsupported("s4_cloud_yongyi records are unknown", "s4_cloud_yongyi")
    end
    local weak = self:isWeak()
    if weak == nil then
        return ai_unsupported("s4_cloud_yongyi weakness is unknown", "s4_cloud_yongyi")
    end
    if weak and max_records <= 2 then return false end
    return true
end

sgs.ai_card_priority = sgs.ai_card_priority or {}
sgs.ai_card_priority.s4_cloud_yongyi = function(self, card)
    if not card or card:isKindOf("SkillCard") then return 0 end
    local ids = s4_cloud_yongyi_ai_valid_instance_ids(self.player)
    if not ids then
        return ai_unsupported("s4_cloud_yongyi instances are unknown", "s4_cloud_yongyi")
    end
    local suit = card:getSuitString()
    for _, instance_id in ipairs(ids) do
        local records = s4_cloud_yongyi_ai_get_records(self.player, instance_id)
        if not records then
            return ai_unsupported("s4_cloud_yongyi records are unknown", "s4_cloud_yongyi")
        end
        if not card:hasSuit() or not s4_cloud_yongyi_contains(records, suit) then
            return 5
        end
    end
    return 0
end

ai_skill_activate.s4_cloud_yongyi = function(self, request)
    local key = "s4_cloud_yongyi"
    local action = self:getSkillAction(key)
    if not action then
        local actions = self:getSkillActions()
        if not actions then
            return ai_unsupported("s4_cloud_yongyi actions are unknown", key)
        end
        for _, candidate in ipairs(actions) do
            if candidate:getActivationSkillName() == key then
                if action then
                    return ai_unsupported("s4_cloud_yongyi activation instance is ambiguous", key)
                end
                action = candidate
            end
        end
    end
    if not action or not action:isValid() or action:getActivationSkillName() ~= key then
        return nil
    end
    if action:isActivationQuotaAvailable() ~= true then return nil end
    local instance_id = action:getActivationInstanceId()
    local records = s4_cloud_yongyi_ai_get_records(self.player, instance_id)
    if records == nil then
        return ai_unsupported("s4_cloud_yongyi records are unknown", key)
    end
    if #records == 0 then return nil end
    local conversions = self:getConversions()
    if not conversions then
        return ai_unsupported("s4_cloud_yongyi conversions are unknown", key)
    end
    for _, conversion in ipairs(conversions) do
        if conversion:getActivationSkillName() == key
            and conversion:getActivationOwner() == action:getActivationOwner()
            and conversion:getActivationInstanceId() == instance_id
            and conversion:getClassName() == "Analeptic" then
            local costs = conversion:getSubcards()
            if costs and #costs == 0 then
                local plan, status = self:tryUseCard(conversion)
                if status == "unsupported" then error(plan, 0) end
                if status == "planned" then return plan:toAnswer() end
                return nil
            end
        end
    end
    return ai_unsupported("s4_cloud_yongyi has no authorized Analeptic conversion", key)
end

sgs.ai_use_priority = sgs.ai_use_priority or {}
sgs.ai_use_priority.s4_cloud_yongyi = (sgs.ai_use_priority.Analeptic or 4.5) + 1

sgs.ai_skill_defense = sgs.ai_skill_defense or {}
sgs.ai_skill_defense.s4_cloud_yongyi = function(self, to)
    return s4_cloud_yongyi_ai_max_records(to)
end

sgs.hit_skill = sgs.hit_skill or ""
if not sgs.hit_skill:find("s4_cloud_yongyi", 1, true) then
    sgs.hit_skill = sgs.hit_skill .. "|s4_cloud_yongyi"
end

-- s4_cloud_sunquan：原版 lua/ai/scarlet-ai.lua 只登記英姿的留牌／需裝備標籤。
-- 摸牌時寫入的條件數供 overflow／留牌讀取；缺投影回 unsupported。
local function s4_cloud_yingzi_ai_state(player)
    if not player then return nil end
    local ids = player:getSkillInstanceIds("s4_cloud_yingzi")
    if not ids then return nil end
    for _, instance_id in ipairs(ids) do
        if instance_id > 0 then
            local x = player:getSkillInstanceStateValue("s4_cloud_yingzi", instance_id, "x")
            if x ~= nil then
                return {
                    instance_id = instance_id,
                    x = tonumber(x) or 0,
                    hand = player:getSkillInstanceStateValue("s4_cloud_yingzi", instance_id, "hand") == true,
                    hp = player:getSkillInstanceStateValue("s4_cloud_yingzi", instance_id, "hp") == true,
                    equip = player:getSkillInstanceStateValue("s4_cloud_yingzi", instance_id, "equip") == true
                }
            end
        end
    end
    local mark = player:getMark("&s4_cloud_yingzi-Clear")
    if type(mark) == "number" then
        return { x = mark }
    end
    return { x = 0 }
end

sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill or ""
if not sgs.notActive_cardneed_skill:find("s4_cloud_yingzi", 1, true) then
    sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|s4_cloud_yingzi"
end
sgs.need_equip_skill = sgs.need_equip_skill or ""
if not sgs.need_equip_skill:find("s4_cloud_yingzi", 1, true) then
    sgs.need_equip_skill = sgs.need_equip_skill .. "|s4_cloud_yingzi"
end

-- s4_lubu：原版 lua/ai/scarlet-ai.lua 的先鋒／戟舞。
sgs.card_value = sgs.card_value or {}
sgs.card_value.s4_xianfeng = { Slash = 7.2 }
sgs.double_slash_skill = sgs.double_slash_skill or ""
if not sgs.double_slash_skill:find("s4_xianfeng", 1, true) then
    sgs.double_slash_skill = sgs.double_slash_skill .. "|s4_xianfeng"
end
sgs.ai_cardneed = sgs.ai_cardneed or {}
sgs.ai_cardneed.s4_xianfeng = function(_, card)
    return card:isKindOf("Slash")
end

local function s4_jiwu_dummy_discard(self, options, key)
    if type(options) ~= "table" or options.candidates_complete ~= true then
        return ai_unsupported(key .. " discard candidates are incomplete", key)
    end
    local min_num = options.min_count
    if type(min_num) ~= "number" or min_num < 1 then
        return ai_unsupported(key .. " discard minimum is unknown", key)
    end
    local ids = options.card_ids
    if type(ids) ~= "table" then
        return ai_unsupported(key .. " discard candidates are unknown", key)
    end
    local cards = self.player:getCards("he")
    if not cards then
        return ai_unsupported(key .. " discard cards are unknown", key)
    end
    local offered, pool = {}, AIList.new({})
    for _, id in ipairs(ids) do offered[id] = true end
    for _, card in ipairs(cards) do
        if offered[card:getEffectiveId()] then pool:append(card) end
    end
    if #pool < min_num then
        if options.optional then return {kind = "pass"} end
        return ai_unsupported(key .. " offered cards cannot satisfy the discard minimum", key)
    end
    local sorted = self:sortByKeepValue(pool, false)
    if not sorted then
        return ai_unsupported(key .. " keep values are unknown", key)
    end
    local result = {}
    for i = 1, min_num do result[i] = sorted[i]:getEffectiveId() end
    return result
end

ai_skill_discard.s4_jiwu_invoke = function(self, options)
    local key = "s4_jiwu_invoke"
    local min_num = type(options) == "table" and options.min_count or nil
    if type(min_num) ~= "number" then
        return ai_unsupported(key .. " discard minimum is unknown", key)
    end
    if min_num <= 0 then return {kind = "pass"} end
    local count = self.player:getCardCount()
    if type(count) ~= "number" then
        return ai_unsupported(key .. " card count is unknown", key)
    end
    if count >= 2 then return s4_jiwu_dummy_discard(self, options, key) end
    local weak = self:isWeak()
    if weak == nil then
        return ai_unsupported(key .. " weakness is unknown", key)
    end
    if weak then return s4_jiwu_dummy_discard(self, options, key) end
    return {kind = "pass"}
end

local function s4_jiwu_flag(card, name, key)
    if type(card.hasFlag) ~= "function" then
        ai_unsupported(key .. " card flags are unknown", key)
    end
    local flagged = card:hasFlag(name)
    if type(flagged) ~= "boolean" then
        ai_unsupported(key .. " card flags are unknown", key)
    end
    return flagged
end

local function s4_jiwu_known_cards(self, class_name, player, key)
    local n = self:getCardsNum(class_name, player)
    if type(n) ~= "number" then
        ai_unsupported(key .. " " .. class_name .. " count is unknown", key)
    end
    return n
end

local function s4_jiwu_has_choice(items, name)
    for _, choice in ipairs(items) do
        if choice == name then return true end
    end
    return false
end

ai_skill_choice.s4_jiwu = function(self, options)
    local key = "s4_jiwu"
    local items = type(options) == "table" and options.choices or nil
    if type(items) ~= "table" then
        return ai_unsupported(key .. " choices are unknown", key)
    end
    local context = self:getDecisionContext()
    local use = context and context.use
    if not (use and use.card and use.to) then
        return ai_unsupported(key .. " card use is not projected", key)
    end
    if s4_jiwu_has_choice(items, "s4_jiwu_nullified") then
        for _, to in ipairs(use.to) do
            local friend = self:isFriend(to)
            if friend == nil then
                return ai_unsupported(key .. " target relation is unknown", key)
            end
            local from_friend = use.from and self:isFriend(use.from)
            if use.from and from_friend == nil then
                return ai_unsupported(key .. " user relation is unknown", key)
            end
            if friend and use.from and not from_friend then
                local weak = self:isWeak(to)
                if weak == nil then
                    return ai_unsupported(key .. " target weakness is unknown", key)
                end
                local heavy = self:hasHeavyDamage(use.from, use.card, to)
                if heavy == nil then
                    return ai_unsupported(key .. " heavy damage is unknown", key)
                end
                if weak or heavy then
                    local crossbow = self:hasCrossbowEffect(use.from)
                    if crossbow == nil then
                        return ai_unsupported(key .. " crossbow effect is unknown", key)
                    end
                    local double = use.from:hasSkills(sgs.double_slash_skill or "")
                    if double == nil then
                        return ai_unsupported(key .. " double slash skills are unknown", key)
                    end
                    local slashes = s4_jiwu_known_cards(self, "Slash", use.from, key)
                    if not (crossbow or double) or slashes < 1 then
                        return "s4_jiwu_nullified"
                    end
                end
            end
        end
    end
    if s4_jiwu_has_choice(items, "s4_jiwu_draw") then
        if not s4_jiwu_flag(use.card, "s4_jiwu_nullified", key) then
            local invoke = true
            for _, to in ipairs(use.to) do
                local need_lose = self:needToLoseHp(to, use.from, use.card)
                if need_lose == nil then
                    return ai_unsupported(key .. " needToLoseHp is unknown", key)
                end
                if use.card:isKindOf("Slash") then
                    if s4_jiwu_known_cards(self, "Jink", to, key) > 0 and not need_lose then
                        invoke = false
                        break
                    end
                elseif use.card:isKindOf("Duel") then
                    if s4_jiwu_known_cards(self, "Nullification", to, key) > 0 and not need_lose then
                        invoke = false
                        break
                    end
                end
            end
            if invoke or s4_jiwu_flag(use.card, "s4_jiwu_no_respond", key) then
                return "s4_jiwu_draw"
            end
        end
    end
    if s4_jiwu_has_choice(items, "s4_jiwu_no_respond_list") then
        local from_friend = use.from and self:isFriend(use.from)
        if use.from and from_friend == nil then
            return ai_unsupported(key .. " user relation is unknown", key)
        end
        if use.from and from_friend and not s4_jiwu_flag(use.card, "s4_jiwu_nullified", key) then
            for _, to in ipairs(use.to) do
                local enemy = self:isEnemy(to)
                if enemy == nil then
                    return ai_unsupported(key .. " target relation is unknown", key)
                end
                if enemy then
                    local weak = self:isWeak(to)
                    if weak == nil then
                        return ai_unsupported(key .. " target weakness is unknown", key)
                    end
                    local heavy = self:hasHeavyDamage(use.from, use.card, to)
                    if heavy == nil then
                        return ai_unsupported(key .. " heavy damage is unknown", key)
                    end
                    if weak or heavy or s4_jiwu_flag(use.card, "s4_jiwu", key) then
                        if use.card:isKindOf("Slash") then
                            local liegong = self:canLiegong(to, use.from)
                            if liegong == nil then
                                return ai_unsupported(key .. " canLiegong is unknown", key)
                            end
                            if s4_jiwu_known_cards(self, "Jink", to, key) > 0 and not liegong then
                                return "s4_jiwu_no_respond_list"
                            end
                        elseif use.card:isKindOf("Duel") then
                            if s4_jiwu_known_cards(self, "Slash", to, key) > 0 then
                                return "s4_jiwu_no_respond_list"
                            end
                        end
                    end
                end
            end
        end
    end
    if s4_jiwu_has_choice(items, "cancel") then return "cancel" end
    return ai_unsupported(key .. " has no offered cancel", key)
end

sgs.ai_cardneed.s4_jiwu = function(to, card)
    local n = to:getHandcardNum()
    if type(n) ~= "number" then return nil end
    return n < 3 and card:isKindOf("Slash")
end

sgs.card_value.s4_jiwu = { Slash = 7.2 }
sgs.hit_skill = sgs.hit_skill or ""
if not sgs.hit_skill:find("s4_jiwu", 1, true) then
    sgs.hit_skill = sgs.hit_skill .. "|s4_jiwu"
end

-- s4_zhaoyun：原版 lua/ai/scarlet-ai.lua 的救主。
local S4_JIUZHU_NEED = "s4_jiuzhu_need_player"

local function s4_jiuzhu_choice_card(self, id)
    if type(self.getChoiceCard) == "function" then
        local card = self:getChoiceCard(id)
        if card then return card end
    end
    local discard = self.room and self.room:getDiscardCards()
    if discard then
        for _, card in ipairs(discard) do
            if card:getEffectiveId() == id then return card end
        end
    end
end

ai_skill_askforag.s4_jiuzhu = function(self, options)
    local key = "s4_jiuzhu"
    if type(options) ~= "table" or options.candidates_complete ~= true then
        return ai_unsupported(key .. " AG candidates are incomplete", key)
    end
    local ids = options.card_ids
    if type(ids) ~= "table" then
        return ai_unsupported(key .. " AG candidates are unknown", key)
    end
    if #ids == 0 then
        return options.optional and {kind = "pass"}
            or ai_unsupported(key .. " AG candidates are empty", key)
    end
    local basics = AIList.new({})
    for _, id in ipairs(ids) do
        local card = s4_jiuzhu_choice_card(self, id)
        if not card then
            return ai_unsupported(key .. " AG card metadata is incomplete", key)
        end
        if card:isKindOf("BasicCard") then basics:append(card) end
    end
    if #basics > 0 then
        local card, player = self:getCardNeedPlayer(basics, true)
        if card and player then
            ai_memory.remember(self.player:objectName(), S4_JIUZHU_NEED, player:objectName())
            return card:getEffectiveId()
        end
        return basics[1]:getEffectiveId()
    end
    return ids[1]
end

ai_skill_playerchosen.s4_jiuzhu = function(self, options)
    local key = "s4_jiuzhu"
    if type(options) ~= "table" or options.candidates_complete ~= true
        or not AIValue.isList(options.players) then
        return ai_unsupported(key .. " requires complete candidates", key)
    end
    local function offered(name)
        for _, item in ipairs(options.players) do
            if item == name then return true end
        end
        return false
    end
    local current_flag = self.player:hasFlag("s4_jiuzhu_current")
    if current_flag == nil then
        return ai_unsupported(key .. " current flag is unknown", key)
    end
    if current_flag then
        local current = self.room:getCurrent()
        if current and offered(current:objectName()) then
            local take = self:doDisCard(current, "he", true)
            if take == nil then
                return ai_unsupported(key .. " doDisCard is unknown", key)
            end
            if take then return current:objectName() end
        end
        return options.optional and {kind = "pass"}
            or ai_unsupported(key .. " current target is not offered", key)
    end
    local only_id = (self.player:getMark("YanyuOnlyId") or 0) - 1
    if only_id < 0 then
        local remembered = ai_memory.recall(self.player:objectName(), S4_JIUZHU_NEED)
        if type(remembered) == "string" and offered(remembered) then
            return remembered
        end
    else
        local card = s4_jiuzhu_choice_card(self, only_id)
        if not card then
            return ai_unsupported(key .. " YanyuOnlyId card is unknown", key)
        end
        local _, player = self:getCardNeedPlayer(AIList.new({card}), true)
        if player and offered(player:objectName()) then
            return player:objectName()
        end
    end
    local pool = AIList.new({})
    for _, name in ipairs(options.players) do
        local player = self.room:findPlayerByObjectName(name, true)
        if not player then
            return ai_unsupported(key .. " candidate is absent from the visible roster", key)
        end
        pool:append(player)
    end
    local sorted = self:sort(pool, "defense")
    if not sorted then
        return ai_unsupported(key .. " defense order is unknown", key)
    end
    for _, player in ipairs(sorted) do
        local friend = self:isFriend(player)
        if friend == nil then
            return ai_unsupported(key .. " relation is unknown", key)
        end
        if friend then
            local draw = self:canDraw(player)
            if draw == nil then
                return ai_unsupported(key .. " canDraw is unknown", key)
            end
            if draw then return player:objectName() end
        end
    end
    if offered(self.player:objectName()) then return self.player:objectName() end
    return options.optional and {kind = "pass"}
        or ai_unsupported(key .. " self is not offered", key)
end

ai_skill_discard.s4_jiuzhu_invoke = function(self, options)
    local key = "s4_jiuzhu_invoke"
    local min_num = type(options) == "table" and options.min_count or nil
    if type(min_num) ~= "number" then
        return ai_unsupported(key .. " discard minimum is unknown", key)
    end
    if min_num <= 0 then return {kind = "pass"} end
    local hp = self.player:getHp()
    local best = self:getBestHp(self.player)
    if type(hp) ~= "number" or type(best) ~= "number" then
        return ai_unsupported(key .. " hp is unknown", key)
    end
    if hp < best then return s4_jiwu_dummy_discard(self, options, key) end
    return {kind = "pass"}
end

ai_skill_invoke.s4_jiuzhu = function(self)
    local key = "s4_jiuzhu"
    local weak = self:isWeak()
    if weak == nil then
        return ai_unsupported(key .. " weakness is unknown", key)
    end
    if weak then
        local can = self.player:canDiscard(self.player, "he")
        if can == nil then
            return ai_unsupported(key .. " canDiscard is unknown", key)
        end
        if not can then return false end
    end
    return true
end

sgs.ai_choicemade_filter = sgs.ai_choicemade_filter or {}
sgs.ai_choicemade_filter.cardChosen = sgs.ai_choicemade_filter.cardChosen or {}
if type(sgs.ai_choicemade_filter.cardChosen.snatch) == "function" then
    sgs.ai_choicemade_filter.cardChosen.s4_jiuzhu = sgs.ai_choicemade_filter.cardChosen.snatch
end
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill or ""
if not sgs.notActive_cardneed_skill:find("s4_jiuzhu", 1, true) then
    sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|s4_jiuzhu"
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill or ""
if not sgs.dont_kongcheng_skill:find("s4_jiuzhu", 1, true) then
    sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|s4_jiuzhu"
end
sgs.ai_playerchosen_intention = sgs.ai_playerchosen_intention or {}
sgs.ai_playerchosen_intention.s4_jiuzhu = function(self, from, to)
    local current = self.player:hasFlag("s4_jiuzhu_current")
    if current == nil then return end
    if current then
        sgs.updateIntention(from, to, 40)
    else
        sgs.updateIntention(from, to, -40)
    end
end

-- s4_huanzhaoyun：原版 lua/ai/scarlet-ai.lua 的龍心／截戰。
local function s4_choice_has(items, name)
    for _, choice in ipairs(items) do
        if choice == name or choice:sub(1, #name + 1) == name .. "=" then
            return choice
        end
    end
end

ai_skill_activate.s4_longxin = function(self)
    local key = "s4_longxin"
    if self.player:isWounded() then return nil end
    local conversions = self:getConversions()
    if not conversions then
        return ai_unsupported(key .. " conversions are unknown", key)
    end
    local jinks = AIList.new({})
    local by_id = {}
    for _, conversion in ipairs(conversions) do
        if conversion:getActivationSkillName() == key
            and conversion:getClassName() == "Slash" then
            local costs = conversion:getSubcards()
            if costs and #costs == 1 then
                local card = self.player:getHandcards()
                if not card then
                    return ai_unsupported(key .. " hand is unknown", key)
                end
                for _, owned in ipairs(card) do
                    if owned:getEffectiveId() == costs[1] and owned:isKindOf("Jink") then
                        jinks:append(owned)
                        by_id[owned:getEffectiveId()] = conversion
                    end
                end
            end
        end
    end
    if #jinks == 0 then return nil end
    local sorted = self:sortByUseValue(jinks, true)
    if not sorted then
        return ai_unsupported(key .. " use values are unknown", key)
    end
    local conversion = by_id[sorted[1]:getEffectiveId()]
    if not conversion then return nil end
    local plan, status = self:tryUseCard(conversion)
    if status == "unsupported" then error(plan, 0) end
    if status == "planned" then return plan:toAnswer() end
    return nil
end

ai_skill_invoke.s4_longxin = function(self)
    local key = "s4_longxin"
    local context = self:getDecisionContext()
    local target = context and context.player
    if not target then
        return ai_unsupported(key .. " target is not projected", key)
    end
    ai_memory.remember(self.player:objectName(), "s4_longxinTarget", target:objectName())
    local friend = self:isFriend(target)
    if friend == nil then
        return ai_unsupported(key .. " relation is unknown", key)
    end
    local hand = target:getHandcardNum()
    if type(hand) ~= "number" then
        return ai_unsupported(key .. " hand count is unknown", key)
    end
    local need_empty = self:needKongcheng(target)
    if need_empty == nil then
        return ai_unsupported(key .. " needKongcheng is unknown", key)
    end
    if friend then
        local manjuan = self:hasManjuanEffect(self.player)
        if manjuan == nil then
            return ai_unsupported(key .. " manjuan is unknown", key)
        end
        if manjuan then return false end
        local overflow = self:getOverflow(target)
        if overflow == nil then
            return ai_unsupported(key .. " overflow is unknown", key)
        end
        if (need_empty and hand == 1) or overflow > 2 then return true end
        return false
    end
    return not (need_empty and hand == 1)
end

sgs.ai_choicemade_filter = sgs.ai_choicemade_filter or {}
sgs.ai_choicemade_filter.skillInvoke = sgs.ai_choicemade_filter.skillInvoke or {}
sgs.ai_choicemade_filter.skillInvoke.s4_longxin = function(self, player, promptlist)
    local remembered = ai_memory.recall(self.player:objectName(), "s4_longxinTarget")
    if type(remembered) ~= "string" then return end
    local target = self.room:findPlayerByObjectName(remembered, true)
    if not target then return end
    local intention = 60
    if promptlist[3] == "yes" then
        local lose = self:hasLoseHandcardEffective(target)
        local need_empty = self:needKongcheng(target)
        local hand = target:getHandcardNum()
        local overflow = self:getOverflow(target)
        if lose == false or (need_empty and hand == 1) then intention = 0 end
        if overflow and overflow > 2 then intention = 0 end
        sgs.updateIntention(player, target, intention)
    else
        local need_empty = self:needKongcheng(target)
        local hand = target:getHandcardNum()
        if need_empty and hand == 1 then intention = 0 end
        sgs.updateIntention(player, target, -intention)
    end
end

sgs.ai_slash_prohibit = sgs.ai_slash_prohibit or {}
sgs.ai_slash_prohibit.s4_longxin = function(self, from, to)
    local friend = self:isFriend(to, from)
    if friend == nil then return nil end
    if friend then return false end
    local liegong = self:canLiegong(to, from)
    if liegong == nil then return nil end
    if liegong then return false end
    if not to:hasSkill("s4_longxin") then return false end
    local to_hand, from_hand = to:getHandcardNum(), from:getHandcardNum()
    if type(to_hand) ~= "number" or type(from_hand) ~= "number" then return nil end
    local wounded = to:isWounded()
    if type(wounded) ~= "boolean" then return nil end
    return to_hand >= 3 and from_hand > 1 and not wounded
end

sgs.ai_card_priority = sgs.ai_card_priority or {}
sgs.ai_card_priority.s4_longxin = function(self, card)
    if not card or card:getSkillName() ~= "s4_longxin" then return end
    local wounded = self.player:isWounded()
    if type(wounded) ~= "boolean" then return nil end
    if wounded then return end
    if self.useValue then return 1 end
    return 0.08
end

sgs.ai_cardneed = sgs.ai_cardneed or {}
sgs.ai_cardneed.s4_longxin = function(_, card)
    return card:isKindOf("Jink") or card:isKindOf("Slash")
end
sgs.ai_choicemade_filter.cardChosen = sgs.ai_choicemade_filter.cardChosen or {}
if type(sgs.ai_choicemade_filter.cardChosen.snatch) == "function" then
    sgs.ai_choicemade_filter.cardChosen.s4_longxin = sgs.ai_choicemade_filter.cardChosen.snatch
end

ai_skill_invoke.s4_jiezhan = function(self)
    local key = "s4_jiezhan"
    local context = self:getDecisionContext()
    local cp = context and context.player
    if not cp then
        return ai_unsupported(key .. " current player is not projected", key)
    end
    local draw = self:canDraw()
    if draw == nil then
        return ai_unsupported(key .. " canDraw is unknown", key)
    end
    local enemy = self:isEnemy(cp)
    if enemy == nil then
        return ai_unsupported(key .. " relation is unknown", key)
    end
    local jinks = self:getCardsNum("Jink")
    if type(jinks) ~= "number" then
        return ai_unsupported(key .. " Jink count is unknown", key)
    end
    local weak = self:isWeak()
    if weak == nil then
        return ai_unsupported(key .. " weakness is unknown", key)
    end
    return draw and enemy and (jinks > 0 or not weak)
end

ai_skill_choice.s4_jiezhan = function(self, options)
    local key = "s4_jiezhan"
    local items = type(options) == "table" and options.choices or nil
    if type(items) ~= "table" then
        return ai_unsupported(key .. " choices are unknown", key)
    end
    local context = self:getDecisionContext()
    local target = context and context.player
    local draw_choice = s4_choice_has(items, "draw")
    if draw_choice then
        if not target then
            return ai_unsupported(key .. " current player is not projected", key)
        end
        local draw = self:canDraw()
        if draw == nil then
            return ai_unsupported(key .. " canDraw is unknown", key)
        end
        local enemy = self:isEnemy(target)
        if enemy == nil then
            return ai_unsupported(key .. " relation is unknown", key)
        end
        local jinks = self:getCardsNum("Jink")
        if type(jinks) ~= "number" then
            return ai_unsupported(key .. " Jink count is unknown", key)
        end
        local weak = self:isWeak()
        if weak == nil then
            return ai_unsupported(key .. " weakness is unknown", key)
        end
        if draw and enemy and (jinks > 0 or not weak) then
            local lost, max_hp = self.player:getLostHp(), self.player:getMaxHp()
            if type(lost) ~= "number" or type(max_hp) ~= "number" then
                return ai_unsupported(key .. " hp is unknown", key)
            end
            if lost >= 1 and max_hp > 1 and s4_choice_has(items, "bieshui") then
                return "bieshui"
            end
            return draw_choice
        end
    end
    local slash_choice = s4_choice_has(items, "slash")
    if slash_choice then return slash_choice end
    local damage_choice = s4_choice_has(items, "damage")
    local obtain_choice = s4_choice_has(items, "obtain")
    if damage_choice then
        if not target then
            return ai_unsupported(key .. " damage target is not projected", key)
        end
        local enemy = self:isEnemy(target)
        if enemy == nil then
            return ai_unsupported(key .. " relation is unknown", key)
        end
        local capped = self:cantDamageMore(self.player, target)
        if capped == nil then
            return ai_unsupported(key .. " cantDamageMore is unknown", key)
        end
        if enemy and not capped then
            local effective = self:damageIsEffective(target, nil, self.player)
            if effective == nil then
                return ai_unsupported(key .. " damageIsEffective is unknown", key)
            end
            if effective then return damage_choice end
        end
    end
    if obtain_choice then
        if not target then
            return ai_unsupported(key .. " obtain target is not projected", key)
        end
        local take = self:doDisCard(target, "he", true)
        if take == nil then
            return ai_unsupported(key .. " doDisCard is unknown", key)
        end
        if take then return obtain_choice end
        local friend = self:isFriend(target)
        if friend == nil then
            return ai_unsupported(key .. " relation is unknown", key)
        end
        if friend then return obtain_choice end
    end
    if damage_choice and obtain_choice then return obtain_choice end
    if s4_choice_has(items, "cancel") then return "cancel" end
    return ai_unsupported(key .. " has no offered cancel", key)
end

if type(sgs.ai_choicemade_filter.cardChosen.snatch) == "function" then
    sgs.ai_choicemade_filter.cardChosen.s4_jiezhan = sgs.ai_choicemade_filter.cardChosen.snatch
end

-- s4_zhurong：原版 lua/ai/scarlet-ai.lua 的烈刃／巨象。
ai_skill_activate.s4_lieren = function(self)
    local key = "s4_lieren"
    local hand = self.player:getHandcards()
    if not hand then
        return ai_unsupported(key .. " hand is unknown", key)
    end
    if #hand < 1 then return nil end
    local sorted = self:sortByKeepValue(hand, nil, true)
    if not sorted then
        return ai_unsupported(key .. " keep values are unknown", key)
    end
    local ids = {}
    for _, card in ipairs(sorted) do
        local keep = self:getKeepValue(card)
        if type(keep) ~= "number" then
            return ai_unsupported(key .. " keep values are unknown", key)
        end
        if keep > 3 or #ids >= #sorted / 2 then break end
        ids[#ids + 1] = card:getEffectiveId()
    end
    if #ids < 1 and #sorted > 1 then
        ids[1] = sorted[1]:getEffectiveId()
    end
    if #ids < 1 then return nil end
    local conversions = self:getConversions()
    if not conversions then
        return ai_unsupported(key .. " conversions are unknown", key)
    end
    for _, conversion in ipairs(conversions) do
        if conversion:getActivationSkillName() == key
            and (conversion:getClassName() == "FireSlash" or conversion:objectName() == "fire_slash") then
            local bound = conversion
            if type(conversion.withSubcards) == "function" then
                bound = conversion:withSubcards(ids) or conversion
            end
            local plan, status = self:tryUseCard(bound)
            if status == "unsupported" then error(plan, 0) end
            if status == "planned" then return plan:toAnswer() end
        end
    end
    return nil
end

sgs.ai_target_revises = sgs.ai_target_revises or {}
sgs.ai_target_revises.s4_juxiang = function(_, card)
    if card:isKindOf("SavageAssault") then return true end
end

ai_skill_invoke.s4_juxiang = function(self)
    local key = "s4_juxiang"
    local context = self:getDecisionContext()
    local pindian = context and context.pindian
    local card = pindian and pindian.to_card
    if card then
        local poison = sgs.ai_poison_card
        if type(poison) == "table" and poison[card:objectName()] then return false end
    end
    return true
end

ai_skill_playerchosen.s4_juxiang = function(self, options)
    local key = "s4_juxiang"
    if type(options) ~= "table" or options.candidates_complete ~= true
        or not AIValue.isList(options.players) then
        return ai_unsupported(key .. " requires complete candidates", key)
    end
    local pool = AIList.new({})
    for _, name in ipairs(options.players) do
        local player = self.room:findPlayerByObjectName(name, true)
        if not player then
            return ai_unsupported(key .. " candidate is absent from the visible roster", key)
        end
        pool:append(player)
    end
    local sorted = self:sort(pool, "defense")
    if not sorted then
        return ai_unsupported(key .. " defense order is unknown", key)
    end
    for _, enemy in ipairs(sorted) do
        local relation = self:isEnemy(enemy)
        if relation == nil then
            return ai_unsupported(key .. " relation is unknown", key)
        end
        if relation and enemy:isAlive() then
            local hand = self.player:getHandcardNum()
            if type(hand) ~= "number" then
                return ai_unsupported(key .. " hand count is unknown", key)
            end
            if hand == 1 then
                local need_empty = self:needKongcheng()
                local lose = self:hasLoseHandcardEffective()
                local weak = self:isWeak()
                if need_empty == nil or lose == nil or weak == nil then
                    return ai_unsupported(key .. " kongcheng policy is unknown", key)
                end
                if (need_empty or not lose) and not weak then return enemy:objectName() end
                local cards = self.player:getHandcards()
                if not cards or #cards < 1 then
                    return ai_unsupported(key .. " last card is unknown", key)
                end
                if cards[1]:isKindOf("Jink") or cards[1]:isKindOf("Peach") then
                    return options.optional and {kind = "pass"} or nil
                end
            end
            local take = self:doDisCard(enemy, "he", true)
            if take == nil then
                return ai_unsupported(key .. " doDisCard is unknown", key)
            end
            if take then return enemy:objectName() end
        end
    end
    return options.optional and {kind = "pass"} or nil
end

sgs.ai_playerchosen_intention = sgs.ai_playerchosen_intention or {}
sgs.ai_playerchosen_intention.s4_juxiang = 60

ai_skill_pindian.s4_juxiang = function(self, options, request)
    local key = "s4_juxiang"
    local cards = self.player:getHandcards()
    if not cards or #cards == 0 then
        return ai_unsupported(key .. " pindian hand is unknown", key)
    end
    local sorted = self:sortByKeepValue(cards)
    if not sorted then
        return ai_unsupported(key .. " keep values are unknown", key)
    end
    local requestor = options and (options.requestor or options.who)
    if type(requestor) == "table" and requestor.object_name then
        requestor = requestor.object_name
    elseif AIValue.isPlayer(requestor) then
        requestor = requestor:objectName()
    end
    if type(requestor) == "string" and requestor == self.player:objectName() then
        return sorted[1]:getId()
    end
    local best, best_number
    for _, card in ipairs(cards) do
        local number = card:getNumber()
        if type(number) ~= "number" then
            return ai_unsupported(key .. " card number is unknown", key)
        end
        if not best or number > best_number then
            best, best_number = card, number
        end
    end
    return best:getId()
end

sgs.ai_skill_pindian = sgs.ai_skill_pindian or {}
sgs.ai_skill_pindian.s4_juxiang = function(minusecard, self, requestor)
    local key = "s4_juxiang"
    local cards = self.player:getHandcards()
    if not cards or #cards == 0 then
        return ai_unsupported(key .. " pindian hand is unknown", key)
    end
    local sorted = self:sortByKeepValue(cards)
    if not sorted then
        return ai_unsupported(key .. " keep values are unknown", key)
    end
    if requestor and requestor:objectName() == self.player:objectName() then
        return sorted[1]:getId()
    end
    local best, best_number
    for _, card in ipairs(cards) do
        local number = card:getNumber()
        if type(number) ~= "number" then
            return ai_unsupported(key .. " card number is unknown", key)
        end
        if not best or number > best_number then
            best, best_number = card, number
        end
    end
    return best:getId()
end

ai_skill_choice.s4_juxiang = function(self, options)
    local key = "s4_juxiang"
    local items = type(options) == "table" and options.choices or nil
    if type(items) ~= "table" then
        return ai_unsupported(key .. " choices are unknown", key)
    end
    local context = self:getDecisionContext()
    local target = context and context.player
    local damage_choice = s4_choice_has(items, "damage")
    local obtain_choice = s4_choice_has(items, "obtain")
    if obtain_choice then
        if not target then
            return ai_unsupported(key .. " target is not projected", key)
        end
        local capped = self:cantDamageMore(target, self.player)
        if capped == nil then
            return ai_unsupported(key .. " cantDamageMore is unknown", key)
        end
        if math.random() < 0.4 and not capped and damage_choice then return damage_choice end
        local take = self:doDisCard(target, "he", true)
        if take == nil then
            return ai_unsupported(key .. " doDisCard is unknown", key)
        end
        if take then return obtain_choice end
    end
    if target then
        local enemy = self:isEnemy(target)
        if enemy == nil then
            return ai_unsupported(key .. " relation is unknown", key)
        end
        if enemy and damage_choice then return damage_choice end
    end
    if s4_choice_has(items, "cancel") then return "cancel" end
    return ai_unsupported(key .. " has no offered cancel", key)
end

sgs.ai_ajustdamage_from = sgs.ai_ajustdamage_from or {}
sgs.ai_ajustdamage_from.s4_juxiang = function(_, from, to, card)
    if not (card and from and to) then return end
    if not (card:isKindOf("SavageAssault") or card:isKindOf("Slash")) then return end
    local mark = "s4_juxiang" .. to:objectName() .. card:getEffectiveId() .. "Card-SelfClear"
    if from:getMark(mark) > 0 then return 1 end
end

sgs.ai_ajustdamage_from.s4_benxi = function(_, from, to, card)
    if not (card and from and to and card:isKindOf("Slash")) then return end
    local flagged = card:hasFlag("s4_benxi" .. to:objectName())
    if flagged == nil then return end
    local first = from:getMark("used_slash-Clear") == 0
    local distance = from:distanceTo(to)
    if type(distance) ~= "number" then return end
    if (flagged or first) and distance <= 1 then return 1 end
end

-- s4_guanyu：原版 lua/ai/scarlet-ai.lua 的武聖。
ai_skill_activate.s4_wusheng = function(self)
    local key = "s4_wusheng"
    local conversions = self:getConversions()
    if not conversions then
        return ai_unsupported(key .. " conversions are unknown", key)
    end
    local enemies = self.enemies
    if not enemies then
        return ai_unsupported(key .. " enemies are unknown", key)
    end
    local sorted_enemies = self:sort(enemies, "defense")
    if not sorted_enemies then
        return ai_unsupported(key .. " defense order is unknown", key)
    end
    local use_all = false
    local range = self.player:getAttackRange()
    if type(range) ~= "number" then
        return ai_unsupported(key .. " attack range is unknown", key)
    end
    for _, enemy in ipairs(sorted_enemies) do
        local hp = enemy:getHp()
        local diagram = enemy:hasArmorEffect("EightDiagram")
        local distance = self.player:distanceTo(enemy)
        local weak = self:isWeak(enemy)
        if type(hp) ~= "number" or type(distance) ~= "number" or weak == nil then
            return ai_unsupported(key .. " enemy state is unknown", key)
        end
        if diagram == nil then
            return ai_unsupported(key .. " EightDiagram is unknown", key)
        end
        if hp < 2 and not diagram and distance <= range and weak then
            local jink = self:getCardsNum("Jink", enemy)
            local peach = self:getCardsNum("Peach", enemy)
            local wine = self:getCardsNum("Analeptic", enemy)
            if type(jink) ~= "number" or type(peach) ~= "number" or type(wine) ~= "number" then
                return ai_unsupported(key .. " enemy card counts are unknown", key)
            end
            if jink + peach + wine < 1 then
                use_all = true
                break
            end
        end
    end
    local slash_num = self:getCardsNum("Slash")
    if type(slash_num) ~= "number" then
        return ai_unsupported(key .. " Slash count is unknown", key)
    end
    local paoxiao = self.player:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao")
    if paoxiao == nil then
        return ai_unsupported(key .. " paoxiao is unknown", key)
    end
    local dis_crossbow = slash_num < 2 or paoxiao
    local slash_value = type(sgs.ai_use_value) == "table" and sgs.ai_use_value.Slash or 4
    local owned = {}
    local hand = self.player:getCards("he")
    if not hand then
        return ai_unsupported(key .. " cards are unknown", key)
    end
    for _, card in ipairs(hand) do owned[card:getEffectiveId()] = card end
    local reds = AIList.new({})
    for _, conversion in ipairs(conversions) do
        if conversion:getActivationSkillName() == key
            and conversion:getClassName() == "Slash" then
            local costs = conversion:getSubcards()
            local card = costs and #costs == 1 and owned[costs[1]] or nil
            if card and card:isRed() and not card:isKindOf("Slash") then
                if not use_all and (card:isKindOf("Peach") or card:isKindOf("ExNihilo")) then
                    card = nil
                elseif card:isKindOf("Crossbow") and not dis_crossbow then
                    card = nil
                else
                    local value = self:getUseValue(card)
                    if type(value) ~= "number" then
                        return ai_unsupported(key .. " use values are unknown", key)
                    end
                    if value < slash_value then
                        reds:append(conversion)
                    end
                end
            end
        end
    end
    if #reds == 0 then return nil end
    for _, conversion in ipairs(reds) do
        local plan, status = self:tryUseCard(conversion)
        if status == "unsupported" then error(plan, 0) end
        if status == "planned" then return plan:toAnswer() end
    end
    return nil
end

ai_skill_invoke.s4_wusheng = function(self)
    local key = "s4_wusheng"
    local context = self:getDecisionContext()
    local use = context and context.use
    if not (use and use.to) then
        return ai_unsupported(key .. " card use is not projected", key)
    end
    for _, player in ipairs(use.to) do
        local friend = self:isFriend(player)
        if friend == nil then
            return ai_unsupported(key .. " relation is unknown", key)
        end
        if friend then return false end
    end
    return true
end

sgs.ai_cardneed = sgs.ai_cardneed or {}
sgs.ai_cardneed.s4_wusheng = function(_, card)
    return card:isRed()
end

-- s4_zhangfei：原版 lua/ai/scarlet-ai.lua 的咆哮。
sgs.ai_use_revises = sgs.ai_use_revises or {}
sgs.ai_use_revises.s4_paoxiao = function(_, card)
    if card:isKindOf("Crossbow") then return false end
end

sgs.ai_cardneed.s4_paoxiao = function(to, card)
    local cards = to:getHandcards()
    if not cards then return nil end
    local weapon = to:getWeapon()
    local has_weapon = weapon and not weapon:isKindOf("Crossbow")
    local slash_num = 0
    for _, owned in ipairs(cards) do
        if owned:isKindOf("Weapon") and not owned:isKindOf("Crossbow") then
            has_weapon = true
        end
        if owned:isKindOf("Slash") then slash_num = slash_num + 1 end
    end
    if not has_weapon then
        return card:isKindOf("Weapon") and not card:isKindOf("Crossbow")
    end
    local spear = to:hasWeapon("Spear")
    if spear == nil then spear = to:hasWeapon("spear") end
    return spear or card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic"))
end

-- s4_machao：原版 lua/ai/scarlet-ai.lua 的鐵騎。
ai_skill_invoke.s4_tieji = function(self)
    local key = "s4_tieji"
    local context = self:getDecisionContext()
    local target = context and context.player
    if not target then
        return ai_unsupported(key .. " target is not projected", key)
    end
    local friend = self:isFriend(target)
    if friend == nil then
        return ai_unsupported(key .. " relation is unknown", key)
    end
    if friend then return false end
    return true
end

ai_skill_askforag.s4_tieji = function(self, options)
    local key = "s4_tieji"
    if type(options) ~= "table" or options.candidates_complete ~= true then
        return ai_unsupported(key .. " AG candidates are incomplete", key)
    end
    local ids = options.card_ids
    if type(ids) ~= "table" or #ids == 0 then
        return options.optional and {kind = "pass"}
            or ai_unsupported(key .. " AG candidates are unknown", key)
    end
    local cards = AIList.new({})
    local red = 0
    for _, id in ipairs(ids) do
        local card = s4_jiuzhu_choice_card(self, id)
        if not card then
            return ai_unsupported(key .. " AG card metadata is incomplete", key)
        end
        cards:append(card)
        if card:isRed() then red = red + 1 end
    end
    if red == 1 then
        for _, card in ipairs(cards) do
            if card:isBlack() then return card:getEffectiveId() end
        end
    end
    local sorted = self:sortByUseValue(cards, true)
    if not sorted then
        return ai_unsupported(key .. " use values are unknown", key)
    end
    return sorted[1]:getEffectiveId()
end

-- s4_huangzhong：原版 lua/ai/scarlet-ai.lua 的烈弓。
sgs.ai_canliegong_skill = sgs.ai_canliegong_skill or {}
sgs.ai_canliegong_skill.s4_liegong = function(_, from, to)
    local to_hand, from_hp, from_range = to:getHandcardNum(), from:getHp(), from:getAttackRange()
    if type(to_hand) ~= "number" or type(from_hp) ~= "number"
        or type(from_range) ~= "number" then
        return nil
    end
    return to_hand >= from_hp or to_hand <= from_range
end

sgs.ai_ajustdamage_from = sgs.ai_ajustdamage_from or {}
sgs.ai_ajustdamage_from.s4_liegong = function(_, from, to, card)
    if not (card and from and to and card:isKindOf("Slash")) then return end
    local card_flag = card:hasFlag("s4_liegong")
    local to_flag = to:hasFlag("s4_liegong")
    if card_flag == true and to_flag == true then return 1 end
    local hp, range = to:getHp(), from:getAttackRange()
    if type(hp) ~= "number" or type(range) ~= "number" then return end
    local from_hp = from:getHp()
    if type(from_hp) ~= "number" then return end
    if hp <= range or hp >= from_hp then return 1 end
end

-- s4_2_zhaoyun：原版 lua/ai/scarlet-ai.lua 的龍膽。
ai_skill_playerchosen.s4_longdan = function(self, options)
    local key = "s4_longdan"
    if type(options) ~= "table" or options.candidates_complete ~= true
        or not AIValue.isList(options.players) then
        return ai_unsupported(key .. " requires complete candidates", key)
    end
    local pool = AIList.new({})
    for _, name in ipairs(options.players) do
        local player = self.room:findPlayerByObjectName(name, true)
        if not player then
            return ai_unsupported(key .. " candidate is absent from the visible roster", key)
        end
        pool:append(player)
    end
    local found = self:findPlayerToDiscard("hej", true, false, pool)
    if not found then
        return ai_unsupported(key .. " findPlayerToDiscard is unknown", key)
    end
    if #found > 0 and found[1] then return found[1]:objectName() end
    return options.optional and {kind = "pass"}
        or ai_unsupported(key .. " has no discard target", key)
end

sgs.ai_cardneed.s4_longdan = function(_, card)
    return card:isKindOf("Jink") or card:isKindOf("Slash")
end

if type(sgs.ai_choicemade_filter.cardChosen.snatch) == "function" then
    sgs.ai_choicemade_filter.cardChosen.s4_longdan = sgs.ai_choicemade_filter.cardChosen.snatch
end

ai_skill_invoke.s4_longdan = function()
    return true
end

ai_skill_activate.s4_longdan = function(self)
    local key = "s4_longdan"
    local conversions = self:getConversions()
    if not conversions then
        return ai_unsupported(key .. " conversions are unknown", key)
    end
    local jinks = AIList.new({})
    local by_id = {}
    local hand = self.player:getHandcards()
    if not hand then
        return ai_unsupported(key .. " hand is unknown", key)
    end
    for _, conversion in ipairs(conversions) do
        if conversion:getActivationSkillName() == key
            and conversion:getClassName() == "Slash" then
            local costs = conversion:getSubcards()
            if costs and #costs == 1 then
                for _, owned in ipairs(hand) do
                    if owned:getEffectiveId() == costs[1] and owned:isKindOf("Jink") then
                        jinks:append(owned)
                        by_id[owned:getEffectiveId()] = conversion
                    end
                end
            end
        end
    end
    if #jinks == 0 then return nil end
    local sorted = self:sortByUseValue(jinks, true)
    if not sorted then
        return ai_unsupported(key .. " use values are unknown", key)
    end
    local conversion = by_id[sorted[1]:getEffectiveId()]
    if not conversion then return nil end
    local plan, status = self:tryUseCard(conversion)
    if status == "unsupported" then error(plan, 0) end
    if status == "planned" then return plan:toAnswer() end
    return nil
end

-- 以下出牌原先 Card_Parse／cloneCard。現在只挑權威端發票；目標由牌族策略或 fill 決定。
-- 龍心已有自己的轉化票處理，這裡不覆寫。
local function parsed_activate(skill, options)
    ai_skill_activate[skill] = function(self)
        return self:playAuthorizedConversion(skill, options)
    end
end

local function use_as_is(_, card, use)
    use.card = card
end

parsed_activate("s4_chiyuan", {fill = use_as_is})
parsed_activate("s4_moubei", {fill = use_as_is})

parsed_activate("s4_wuhu_heduan", {
    gate = function(self)
        local bear = self:needBear()
        local slashes = self:getCardsNum("Slash")
        if bear == nil or type(slashes) ~= "number" then return nil end
        return not bear and slashes > 1
    end,
    fill = use_as_is
})

parsed_activate("s4_suihuai", {
    gate = function(self)
        if not self.player:hasSkill("s4_neiji") then return true end
        local hand = self.player:getHandcardNum()
        if type(hand) ~= "number" then return nil end
        return hand <= 6
    end,
    fill = use_as_is
})

parsed_activate("s4_zhimeng", {
    gate = function(self)
        if self.player:isKongcheng() then return false end
        if not self.friends_noself or not self.enemies then return nil end
        local mine = self.player:getHandcardNum()
        if type(mine) ~= "number" then return nil end
        local good = 2
        for _, friend in ipairs(self.friends_noself) do
            local count = friend:getHandcardNum()
            if type(count) ~= "number" then return nil end
            if count >= mine then good = good + 1 end
        end
        for _, enemy in ipairs(self.enemies) do
            local count = enemy:getHandcardNum()
            if type(count) ~= "number" then return nil end
            if count >= mine then good = good - 1 end
        end
        return good > 0
    end,
    fill = use_as_is
})

parsed_activate("s4_beizhen", {
    kind = "Duel",
    gate = function(self)
        return self.player:getMark("s4_beizhen_buff-Clear") > 0
    end,
    accept = function(self, conversion)
        local card = self:conversionSubcard(conversion)
        if card == nil then return nil end
        if not card then return false end
        return card:isKindOf("Jink") or card:isKindOf("Peach")
    end
})

parsed_activate("s4_fuhan", {
    kind = "Slash",
    gate = function(self)
        return self.player:getMark("&s4_fuhan-Clear") > 0
    end,
    accept = function(self, conversion)
        local card = self:conversionSubcard(conversion)
        if card == nil then return nil end
        if not card or card:isKindOf("BasicCard") then return false end
        local value = self:getUseValue(card)
        if type(value) ~= "number" then return nil end
        local slash = type(sgs.ai_use_value) == "table" and sgs.ai_use_value.Slash or 4
        return value < slash
    end
})

parsed_activate("s4_ganglu", {
    accept = function(self, conversion)
        local basic = conversion:isKindOf("BasicCard")
        if basic == nil then return nil end
        if not basic then return false end
        local class_name = conversion:getClassName()
        if type(class_name) ~= "string" then return nil end
        local count = self:getCardsNum(class_name)
        if type(count) ~= "number" then return nil end
        return count < 1
    end
})

parsed_activate("s4_txbw_zhenyue", {
    accept = function(self, conversion)
        local card = self:conversionSubcard(conversion)
        if card == nil then return nil end
        if not card then return false end
        local number = card:getNumber()
        if type(number) ~= "number" then return nil end
        if number ~= self.player:getMark("&s4_txbw_zhenyue") then return false end
        local will = self:willUse(self.player, card)
        if will == nil then return nil end
        return not will
    end,
    fill = use_as_is
})

parsed_activate("s4_xingyi", {
    gate = function(self)
        if self.player:getMark("s4_yanshi") < 2 then
            if not self.friends_noself then return nil end
            return #self.friends_noself > 0
        end
        local slash = self:getCard("Slash")
        if slash == nil then return nil end
        if not slash then return false end
        local _, status = self:tryUseCard(slash)
        if status == "unsupported" then return nil end
        return status == "planned"
    end,
    fill = use_as_is
})

parsed_activate("s4_txbw_huibian", {
    fill = function(self, card, use)
        if not self.friends_noself or not self.enemies then
            ai_unsupported("s4_txbw_huibian relations are unknown", "s4_txbw_huibian")
        end
        local friends = self:sort(self.friends_noself, "hp")
        if not friends then
            ai_unsupported("s4_txbw_huibian friend order is unknown", "s4_txbw_huibian")
        end
        local function hurt_friend(target)
            local hp = target:getHp()
            if type(hp) ~= "number" then
                ai_unsupported("s4_txbw_huibian hp is unknown", "s4_txbw_huibian")
            end
            if hp <= 1 then return false end
            local can = self:canDamage(target, self.player, nil)
            if can == nil then
                ai_unsupported("s4_txbw_huibian damage is unknown", "s4_txbw_huibian")
            end
            if not can then return false end
            local draw = self:canDraw(target)
            if draw == nil then
                ai_unsupported("s4_txbw_huibian draw is unknown", "s4_txbw_huibian")
            end
            return draw == true
        end
        local first
        for _, target in ipairs(friends) do
            if hurt_friend(target) then first = target break end
        end
        if not first then
            for _, target in ipairs(self.enemies) do
                local hp = target:getHp()
                if type(hp) ~= "number" then
                    ai_unsupported("s4_txbw_huibian hp is unknown", "s4_txbw_huibian")
                end
                if hp > 1 then
                    local can = self:canDamage(target, self.player, nil)
                    if can == nil then
                        ai_unsupported("s4_txbw_huibian damage is unknown", "s4_txbw_huibian")
                    end
                    if can then first = target break end
                end
            end
        end
        if not first then return end
        local second
        for index = #friends, 1, -1 do
            local friend = friends[index]
            if friend:isWounded() and friend:objectName() ~= first:objectName() then
                second = friend
                break
            end
        end
        if not second then return end
        if card:canTarget(first:objectName()) ~= true or card:canTarget(second:objectName()) ~= true then
            return
        end
        use.card = card
        use.to:append(first)
        use.to:append(second)
    end
})

parsed_activate("s4_txbw_qiaobian", {
    fill = function(self, card, use)
        if self.player:isKongcheng() then return end
        local others = self.room:getOtherPlayers(self.player)
        if not others then ai_unsupported("s4_txbw_qiaobian roster is unknown", "s4_txbw_qiaobian") end
        for _, target in ipairs(others) do
            if target:objectName() ~= self.player:objectName() then
                local hand = target:getHandcardNum()
                if type(hand) ~= "number" then
                    ai_unsupported("s4_txbw_qiaobian hand count is unknown", "s4_txbw_qiaobian")
                end
                if hand > 0 then
                    local discard = self:doDisCard(target, "h", true)
                    if discard == nil then
                        ai_unsupported("s4_txbw_qiaobian discard value is unknown", "s4_txbw_qiaobian")
                    end
                    if discard and card:canTarget(self.player:objectName()) == true
                        and card:canTarget(target:objectName()) == true then
                        use.card = card
                        use.to:append(self.player)
                        use.to:append(target)
                        return
                    end
                end
            end
        end
    end
})

parsed_activate("s4_txbw_general_duel", {
    fill = function(self, card, use)
        if not self.enemies then
            ai_unsupported("s4_txbw_general_duel relations are unknown", "s4_txbw_general_duel")
        end
        local own = self.player:getHandcards()
        if not own then
            ai_unsupported("s4_txbw_general_duel hand is unknown", "s4_txbw_general_duel")
        end
        local max_card = self:getGeneralDuelCard()
        if not max_card then return end
        local max_point = self:getGeneralDuelPoint(self.player, max_card)
        if type(max_point) ~= "number" then
            ai_unsupported("s4_txbw_general_duel point is unknown", "s4_txbw_general_duel")
        end
        local enemies = self:sort(self.enemies, "handcard")
        if not enemies then
            ai_unsupported("s4_txbw_general_duel enemy order is unknown", "s4_txbw_general_duel")
        end
        local function beats(enemy, loose)
            local damage = self:damageStruct({from = self.player, to = enemy, damage = 1,
                reason = "s4_txbw_general_duel"})
            if damage == nil then return nil end
            if not damage then return false end
            local known = enemy:getKnownCards()
            if known == nil then return nil end
            local enemy_card = self:getGeneralDuelCard(enemy, known)
            local enemy_point = 100
            if enemy_card then
                enemy_point = self:getGeneralDuelPoint(enemy, enemy_card)
                if type(enemy_point) ~= "number" then return nil end
            end
            local win = enemy_card and max_point > enemy_point
            if not loose then
                if not win then return false end
                local capped = self:cantDamageMore(enemy, self.player)
                if capped == nil then return nil end
                if capped then
                    if self.player:getMark("&s4_txbw_luoyi") > 0 then return false end
                    if self.player:hasSkill("s4_txbw_wanpo") and not enemy:isWounded() then return false end
                end
                return true
            end
            return win or max_point > 7 or self.player:hasSkill("s4_txbw_yishi")
                or self.player:hasSkill("s4_txbw_shenwei")
        end
        for _, loose in ipairs({false, true}) do
            for _, enemy in ipairs(enemies) do
                local ok = beats(enemy, loose)
                if ok == nil then
                    ai_unsupported("s4_txbw_general_duel target is unknown", "s4_txbw_general_duel")
                end
                if ok and card:canTarget(enemy:objectName()) == true then
                    self:remember("s4_txbw_general_duel_card", max_card:getEffectiveId())
                    use.card = card
                    use.to:append(enemy)
                    return
                end
            end
        end
    end
})

ai_skill_discard.s4_txbw_general_duel = function(self, options)
    local id = self:recall("s4_txbw_general_duel_card")
    if type(id) ~= "number" then
        local card = self:getGeneralDuelCard()
        id = card and card:getEffectiveId() or nil
    end
    if type(id) ~= "number" then return nil end
    local offered = type(options) == "table" and options.card_ids or nil
    if type(offered) == "table" then
        for _, card_id in ipairs(offered) do
            if card_id == id then return {id} end
        end
        return nil
    end
    return {id}
end
