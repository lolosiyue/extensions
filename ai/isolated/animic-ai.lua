-- Source: b6025acc ai/animic-ai.lua.
local known = AIValue.requireKnown

local function copy(xs)local out={};for _,v in ipairs(known(xs,"card/player list"))do out[#out+1]=v end return out end
local function material(card)return{name="analeptic",skill="guihao",suit=card:getSuit(),number=card:getNumber(),subcards={card:getKnownEffectiveId()}}end
local function huayuan_answer(self,names)
    local card=self:bindSkillCard("huayuan",{},self.request,nil,"#huayuanCard")
    local use=AIUsePlan.new();use.card=card
    for _,name in ipairs(names)do use.to:append(known(self.room:findPlayerByObjectName(name),"huayuan target"))end
    return use:toAnswer()
end
ai_skill_invoke["modao"] = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    if #self.enemies == 0 then return (false) or false end
    return (true) or false
end

ai_skill_choice["modao"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    if self.player:isKongcheng() then return ai_choice_result(("1"), options) end
    for _, c in ipairs(self.player:getHandcards()) do
            if c:isKindOf("Duel") then
                local dummy_use = self:aiUseCard(c)
                if not dummy_use.to:isEmpty() then
                    return ai_choice_result(("2"), options)
                end
            end
            if c:isKindOf("FireAttack") and self.player:getHandcardNum() > 2 then
                local dummy_use = self:aiUseCard(c)
                if not dummy_use.to:isEmpty() then
                    return ai_choice_result(("2"), options)
                end
            end

        local x = nil
        if isCard("ArcheryAttack", c, self.player) then
            x = self:getEvaluationCard("ArcheryAttack")
        elseif isCard("SavageAssault", c, self.player) then
            x = self:getEvaluationCard("SavageAssault")
        else continue end
        if x then
            local du = self:aiUseCard(x)
            if (du.card) then return ai_choice_result(("3"), options) end
        end
    end
    return ai_choice_result(("1"), options)
end

sgs.ai_skill_playerchosen.modao = function(self, targets)
    targets = copy(targets)
    targets = self:sort(targets, "handcard_defense")
    for _, target in ipairs(targets) do
        if self:isEnemy(target) and self:doDisCard(target, "h", true, tonumber(self.player:getTag("modao")) or 0) then
            return target
        end
    end
    for _, target in ipairs(targets) do
        if self:isEnemy(target) and self:doDisCard(target, "h", true) then
            return target
        end
    end

    return targets[1]
end

ai_skill_invoke["cuisheng"] = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local current = self.room:getCurrent()
    return (current and self:isFriend(current)) or false
end
sgs.ai_choicemade_filter.skillInvoke.cuisheng = function(self, player, promptlist)
    if promptlist[#promptlist] == "yes" then
        local current = self.room:getCurrent()
        self:updateIntention(player, current, -50)
    end
end


ai_skill_use["@@huayuan"]=function(self, prompt, request)
    local method = request and request.handling_method
    self:updatePlayers()
    local enemytargets = {}
        for _, enemy in ipairs(self.enemies) do
            if  not enemy:isChained()
                and not enemy:hasSkill("danlao")
                --不要對董允敵人使用
                and not enemy:hasSkill("sheyan")
                --不要對陸抗敵人使用
                and not enemy:hasSkill("qianjie")
                --不要對司馬徽敵人使用
                and not enemy:hasSkills("chenghao+yinshi")

                --add dongmanbao enemy
                and not enemy:hasSkill("Tianhuo")

                --add fate
                and not enemy:hasSkill("fatefapao")


                and not (self:objectiveLevel(enemy) <= 3)
                and not self:needToLoseHp(enemy) and self:isGoodTarget(enemy, self.enemies, nil)
                and #enemytargets < 2  then
                table.insert(enemytargets, enemy:objectName())
            end
        end
        for _, friend in ipairs(self.friends) do
            if not friend:isChained()
                and self:needToLoseHp(friend)
                and #enemytargets < 2  then
                table.insert(enemytargets, friend:objectName())
            end
        end
        if #enemytargets > 0 then
            if #enemytargets > 1 then
                return huayuan_answer(self,enemytargets)
            end
            return huayuan_answer(self,enemytargets)
        end
    return "."
end


sgs.ai_card_intention["huayuanCard"] = function(self,card,from,to)
    local callback=sgs.ai_card_intention.IronChain
    if type(callback)~="function" then ai_unsupported("IronChain intention unavailable","huayuanCard") end
    return callback(self,card,from,to)
end

sgs.ai_skill_playerchosen["jiaosha"] = function(self, targets)
    targets = copy(targets)
    targets = self:sort(targets, "handcard")
    for _,p in ipairs(targets) do
        if self:isFriend(p) then
            if not self:willSkipPlayPhase(p) then
                if self:needToLoseHp(p) or not self:damageIsEffective(p, sgs.DamageStruct_Normal) then
                    return p
                end
            end
        end
    end
    for _,p in ipairs(targets) do
        if self:isEnemy(p) then
            if self:willSkipPlayPhase(p) and self:damageIsEffective(p, sgs.DamageStruct_Normal)
            and not self:needToLoseHp(p) and self:isGoodTarget(p, self.enemies, nil)   then
                return p
            end
        end
    end
    return nil
end

sgs.ai_skill_cardask["@huanglue"] = function(self, data, pattern, target, target2)
    local use = data:toCardUse()
    local handcards = copy(self.player:getCards("he"))
    handcards = self:sortByKeepValue(handcards)
    if use.card:isKindOf("Jink") or use.card:isKindOf("Nullification") then
        if use.from and self:isEnemy(use.from) then
            for _, card in ipairs(handcards) do
                if card:getNumber() > use.card:getNumber() then
                    return "$" .. card:getKnownEffectiveId()
                end
            end
        end
    elseif use.card:isKindOf("Peach") then
        if use.from and self:isEnemy(use.from) then
            for _, p in ipairs(use.to) do
                if self:isEnemy(p) then
                    for _, card in ipairs(handcards) do
                        if card:getNumber() > use.card:getNumber() then
                            return "$" .. card:getKnownEffectiveId()
                        end
                    end
                end
            end
        end
    else
        if not self:isWeak() and use.from and not self:isFriend(use.from) then
            for _, p in ipairs(use.to) do
                if self:isFriend(p) then
                    for _, card in ipairs(handcards) do
                        if card:getNumber() > use.card:getNumber() then
                            return "$" .. card:getKnownEffectiveId()
                        end
                    end
                end
            end
        end
    end
    return "."
end


sgs.ai_skill_playerchosen.luafenwei = function(self, targets)
    if self:needKongcheng(self.player, true) then
        return nil
    end
    targets = copy(targets)
    targets = self:sort(targets, "defense")
    for _, target in ipairs(targets) do
        if self:isFriend(target) and ( target:getJudgingArea():length() > 0  and not target:containsTrick("YanxiaoCard")) then return target end
    end
    for _, target in ipairs(targets) do
        if self:isEnemy(target) and (( target:getJudgingArea():length() > 0  and  target:containsTrick("YanxiaoCard"))) then return target end
    end
    for _, target in ipairs(targets) do
        if self:isEnemy(target) and not ( target:hasSkills(sgs.lose_equip_skill) or self:doDisCard(target, "ej", true)) then
            return target
        end
    end
    for _, target in ipairs(targets) do
        if self:isFriend(target) and ((target:hasSkills(sgs.lose_equip_skill) and target:getEquips():length() > 0) or self:needToThrowArmor(target)) then return target end
    end

    return targets[1]
end

sgs.ai_skill_cardchosen["luafenwei"] = function(self, who, flags)
    self:updatePlayers()
            if flags:match("e") then
                if self:isEnemy(who) then
                    if not  who:hasSkills(sgs.lose_equip_skill) then
                        for _, e in ipairs(copy(who:getCards("e"))) do
                            local equip_index = e:location()
                            return e:getEffectiveId()
                        end
                    end
                else
                    if  who:hasSkills(sgs.lose_equip_skill) then
                        for _, e in ipairs(copy(who:getCards("e"))) do
                            local equip_index = e:location()
                            return e:getEffectiveId()
                        end
                    end
                end
            end
            if flags:match("j") then
                if self:isEnemy(who) then
                    local judges = who:getJudgingArea()
                    if who:containsTrick("YanxiaoCard") then
                        for _, judge in ipairs(judges) do
                            if judge:isKindOf("YanxiaoCard") then
                                return judge:getEffectiveId()
                            end
                        end
                    end
                elseif self:isFriend(who) then
                    local judges = who:getJudgingArea()
                    for _, judge in ipairs(judges) do
                        if not judge:isKindOf("YanxiaoCard") then
                            return judge:getEffectiveId()
                        end
                    end
                end
            end
end
sgs.need_kongcheng = sgs.need_kongcheng .. "|luafenwei"




ai_fill_skill.guihao=function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("h")
    cards=copy(cards)

    if self.player:getPile("wooden_ox"):length() > 0 then
        for _, id in ipairs(self.player:getPile("wooden_ox")) do
            table.insert(cards, known(self:getKnownCardById(id),"guihao wooden-ox card"))
        end
    end

    local card

    cards = self:sortByUseValue(cards,true)

    for _,acard in ipairs(cards)  do
        if acard:isBlack() then
            card = acard
            break
        end
    end

    if not card then return nil end
    if  self.player:getStrategyMark("guihao") == 0 then return nil end
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getKnownEffectiveId()
    local analeptic = self:evaluateOwnerViewAsCard({source_key="guihao",skill="guihao",name="analeptic",suit=card:getSuit(),number=card:getNumber(),subcards={card_id}})

    if analeptic:isAvailable(self.player) then
        assert(analeptic)
        return self:bindTurnConversion("guihao","Analeptic",material(card),request)
    end
end

sgs.ai_view_as.guihao = function(card, player, card_place)
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getKnownEffectiveId()
    if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
        if card:isBlack() and player:getMark("guihao") > 0 then
            return material(card)
        end
    end
end

function sgs.ai_cardneed.guihao(to, card, self)
    return card:isBlack() and (getKnownCard(to, self.player, "club", false) + getKnownCard(to, self.player, "spade", false)) == 0
end



ai_skill_invoke.guihao = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    if self:isWeak(self.player) and self:getAllPeachNum() == 0 then return (false) or false end
    if self:willSkipPlayPhase(self.player) then return (false) or false end
    for _,card in ipairs(self.player:getHandcards()) do
        if card:isKindOf("Peach") or card:isKindOf("Analeptic") or card:isKindOf("Slash") then
            return (true) or false
        end
    end
    if math.random()<0.6 then return (true) or false end
    return (false) or false
end

ai_skill_use["@@caiduan"] = function(self, prompt, request)
    local cards = self.player:getCards("h")
    cards = copy(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
    for _,h in ipairs(cards)do
        if h and not h:targetFixed() then
            local dummy_use = self:aiUseCard(h)
            if dummy_use.card and dummy_use.to  then
                local tos = {}
                for _,p in ipairs(dummy_use.to)do
                    table.insert(tos,p:objectName())
                end
                local plan=AIUsePlan.new();plan.card=h
                for _,name in ipairs(tos)do plan.to:append(known(self.room:findPlayerByObjectName(name),"caiduan target"))end
                return plan:toAnswer()
            end
        end
    end
end

ai_skill_invoke["caiduan"] = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local current = self.room:getCurrent()
    return (current and self:isEnemy(current) and not self:isWeak()) or false
end
sgs.ai_choicemade_filter.skillInvoke.caiduan = function(self, player, promptlist)
    if promptlist[#promptlist] == "yes" then
        local current = self.room:getCurrent()
        self:updateIntention(player, current, 50)
    end
end

ai_skill_invoke["shenni"] = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local move = data:toMoveOneTime()
    for _,card_id in ipairs(move.card_ids) do
        if (known(self:getKnownCardById(card_id),"shenni disclosed moved card")):isKindOf("Peach") then
            return (true) or false
        end
    end
    return (not self:isWeak()) or false
end


sgs.ai_skill_playerchosen.yui_changxin = function(self, targets)
    return self:findPlayerToDiscard("he", true, true, targets, false)[1]
end
