-- Source: b6025acc ai/arknights-ai.lua.
local known = AIValue.requireKnown

local function missing_source_prototype(self,name)
    -- Whether the source's skill-card class is registered (Card_Parse) is engine
    -- registry state, not projected.
    ai_unsupported("skill-card registry is not projected",name)
end
--过载

ai_fill_skill.ark_guozai = function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyMark("&ark_guozai-PlayClear") >= self.player:getMaxHp() then return end
    local card = self:evaluateSkillCard("ark_guozai","slash",{})
    local d = self:aiUseCard(card)
    local names=false
    if d.to then names={};for _,p in ipairs(d.to)do names[#names+1]=p:objectName()end end
    self:setStrategyMemory("ark_guozai_to",names)
    if d.card and d.to
        and card:isAvailable(self.player)
    then
        return missing_source_prototype(self,"#ark_guozai")
    end
end

ai_card_use["#ark_guozai"] = function(self, card, use, request)
    local cached,present=self:getStrategyMemory("ark_guozai_to")
    local targets
    if present and cached~=false then
        targets=AIList.new({});for _,name in ipairs(cached)do targets:append(known(self.room:findPlayerByObjectName(name),"Guozai cached target"))end
    end
    if targets then
        use.card = card
        if use.to then use.to = targets end
    end
end

sgs.ai_use_priority.ark_guozai = 8


sgs.ai_ajustdamage_from.ark_douzheng = function(self, from, to, card, nature)
    if to:objectName() ~= from:objectName()
    then
        return 1
    end
end


--共振

sgs.ai_skill_playerchosen.ark_gongzhen = function(self, targets)
    local en = {}
    for _, p in ipairs(targets) do
        if self:isEnemy(p) then
            table.insert(en, p)
        end
    end
    if #en == 0 then return nil end
    en = self:sort(en, "defense")
    if self.player:getStrategyFlag("ark_gongzhenBasicCard") then
        for _, p in ipairs(en) do
            if p:getStrategyMark("&ark_gongzhen_recordtypeBasicCard") == 0 or p:getHandcardNum() >= 3 then return p end
        end
    elseif self.player:getStrategyFlag("ark_gongzhenTrickCard") then
        -- Source ignores sgs.reverse(en)'s newly allocated return; keep order.
        for _, p in ipairs(en) do
            if p:getStrategyMark("&ark_gongzhen_recordtypeTrickCard") == 0 then return p end
        end
    elseif self.player:getStrategyFlag("ark_gongzhenEquipCard") then
        for _, p in ipairs(en) do
            if p:getStrategyMark("&ark_gongzhen_recordtypeTrickCard") == 0 then return p end
        end
    end
    return en[math.random(1, #en)]
end

--缄默

ai_skill_invoke.ark_jianmo = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local name=known(self:getDecisionContext().ark_jianmo_target,"public ark_jianmotarget")
    local target=name~=false and known(self.room:findPlayerByObjectName(name),"Jianmo target")or nil
    return (target and self:isEnemy(target)) or false
end

sgs.ai_skill_playerschosen.ark_jianmo = function(self, targets, max, min)
    local enemy = AIList.new({})
    for _, p in ipairs(targets) do
        if self:isEnemy(p) then
            enemy:append(p)
        end
    end
    return enemy
end

--剑雨

sgs.ai_skill_playerschosen.ark_jianyu = function(self, targets, max, min)
    local enemy = AIList.new({})
    for _, p in ipairs(targets) do
        if not self:isEnemy(p) then
            enemy:append(p)
        end
    end
    return enemy
end

sgs.ai_ajustdamage_from.ark_chujue = function(self, from, to, card, nature)
    if to:objectName() ~= from:objectName()
    then
        return to:getLostHp() - 1
    end
end

--追猎

ai_fill_skill.ark_zhuilie = function(self, options, request)
    local inclusive = options and options.inclusive

    return missing_source_prototype(self,"#ark_zhuilie")
end

ai_card_use["#ark_zhuilie"] = function(self, card, use, request)
    local target
    self.enemies = self:sort(self.enemies, "hp")
    if #self.enemies == 0 then return "." end
    for _, enemy in ipairs(self.enemies) do
        if self.player:getHp() > 1
            or (not enemy:canSlash(self.player, nil, true, 0))
            or (self:getCardsNum("Peach") + self:getCardsNum("Analpetic") + self:getCardsNum("Jink") > 0)
            or enemy:getHandcardNum() == 0
            or enemy:getStrategyMark("&ark_guodu_cant") > 0 then
            target = enemy
            break
        end
    end
    if target then
        use.card = card
        if use.to then use.to:append(target) end
    end
end

--坍缩

sgs.ai_skill_playerschosen.ark_tanshuo = function(self, targets, max, min)
    local enemy = AIList.new({})
    for _, p in ipairs(targets) do
        if self:isEnemy(p) then
            enemy:append(p)
        end
    end
    if enemy:length() <= 0 then
        for _, p in ipairs(targets) do
            if not self:isFriend(p) then
                enemy:append(p)
            end
        end
    end
    if enemy:length() <= 0 then
        targets = targets
        enemy:append(targets[math.random(1, #targets)])
    end
    return enemy
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|ark_tanshuo"

--止戈

ai_skill_invoke.ark_zhige = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    return (target and self:isEnemy(target)) or false
end

--万象

ai_skill_choice["ark_wanxiang"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    if self.player:getStrategyMark("&ark_chongying") > 0 then table.removeOne(items, "ark_chongying") end
    if self.player:getStrategyMark("&ark_fuchen") > 0 then table.removeOne(items, "ark_fuchen") end
    if math.random(1, 2) == 1 then return ai_choice_result(("ark_wowu"), options) end
    return ai_choice_result((items[math.random(1, #items)]), options)
end

sgs.ai_ajustdamage_from["&ark_chongying"] = function(self, from, to, card, nature)
    if to:objectName() ~= from:objectName()
    then
        return math.min(to:getStrategyMark("&ark_chongying"), 3)
    end
end


--逐夜

ai_skill_invoke.ark_zhuye = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local n = 1 - self.player:getHp()
    return ((self:getCardsNum("Peach") + self:getCardsNum("Analeptic")) < n) or false
end

--破晓

sgs.ai_skill_playerchosen.ark_poxiao = function(self, targets)
    local selected = {}
    for _, p in ipairs(targets) do
        if self:isEnemy(p) then
            table.insert(selected, p)
        end
    end
    if #selected == 0 then return nil end
    selected = self:sort(selected, "hp")
    return selected[1]
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|ark_yaoyang"

sgs.ai_use_revises.ark_yaoyang = function(self,card,use)
    if card:isKindOf("Slash") then
        self:setStrategyCardFlag(card,"Qinggang",true)
    end
end

sgs.ai_ajustdamage_from.ark_zhuye = function(self, from, to, card, nature)
    if from:getStrategyMark("&ark_zhuye") > 0
    then
        return 1
    end
end

sgs.ai_canNiepan_skill.ark_zhuye = function(player)
    return player:getStrategyMark("@ark_zhuye_mark") > 0
end

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, from, to, dmg, card, nature, damage_call, helpers, context)
        if damage_call(to, "hasSkill", "ark_kewang") and dmg > 1 then
            dmg = 0
        end
        return dmg, nature
    end
    local previous_1 = sgs.ai_ajustdamage_to["ark_kewang"]
    sgs.ai_ajustdamage_to["ark_kewang"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "after_to" and context.rule == "ark_kewang" then
                local damage, next_nature, terminal = policy_1(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_to", "ark_kewang", {
        {phase="after_to", rule="ark_kewang", order=6700},
    })
end)()
