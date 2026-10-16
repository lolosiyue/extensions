-- Fixed b6025acc AIgeneral strategy bodies. Native authorization is separate
-- from source planning; foreign private roles use an explicit viewer estimate.
local function known(v,key)
    if v==nil then ai_unsupported("AIgeneral value is unknown",key)end
    return v
end

local function visible_role(self,player)
    local role=player:getRole()
    if role~=nil then return role end
    role=self:getRoleEstimate(player)
    return self:useKnowledgeEstimate({value=role,status="estimate",basis="AIgeneral:viewer_inference_replaces_foreign_private_role",viewer=self.player:objectName(),observer=player:objectName()},"AIgeneral.role")
end
local function known_card(...)return known(getKnownCard(...),"getKnownCard")end
local function known_count(...)return known(getCardsNum(...),"getCardsNum")end
local function sort_enemies(self,...)
    self.enemies=self:sort(known(self.enemies,"enemies"), ...)
end
local function wounded_friends(self)
    local first,second=self:getWoundedFriend(false)
    return known(first,"wounded friend first group"),known(second,"wounded friend second group")
end
local function bind_tiaojiao(self,source)
    local costs={}
    for _,card in ipairs(self.player:getHandcards())do costs[#costs+1]=card:getKnownEffectiveId()end
    return self:bindSkillCard("tiaojiaoCMT",costs,nil,nil,"#tiaojiaoCMTCard")
end
local function tongyi_evaluation(self,name)
    local card=self:evaluateOwnerViewAsCard({source_key="tongyiTQ",skill="tongyiAIWJ",name=name,suit=sgs.Card_NoSuit,number=0,subcards={}})
    -- Donor calls setSkillName before its nil check. Missing clone is an
    -- ordinary source error, never a successful pass or fabricated card.
    if card==nil then error("attempt to index a nil value (local 'c')",0)end
    return card
end

--深度思考
sgs.ai_skill_invoke.deep_seek = function(self, data)
    local target = data:toDamage().to
    if  self:getRoleEstimate(target) ~= "neutral" or target:isLord()  then
        return true
    end
    return false
end

sgs.ai_skill_choice.deep_seek = function(self, choices, data)
    local target = data:toPlayer()
    local items = choices:split("+")

    if self:getRoleEstimate(target)== "rebel" and table.contains(items, "rebel")  then
        return "rebel"
    elseif target:isLord() and table.contains(items, "lord")  then
        return "lord"
    elseif self:getRoleEstimate(target)== "loyalist" and table.contains(items, "loyalist")  then
        return "loyalist"
    elseif self:getRoleEstimate(target)== "renegade" and table.contains(items, "renegade")  then
        return "renegade"
    end
    return items[1]
end

sgs.ai_fill_skill.tieba_zhili = function(self,inclusive,request)
    return self:legacySkillSeed("tieba_zhili", "#tieba_zhiliCard", request)
end

sgs.ai_skill_use_func["#tieba_zhiliCard"] = function(card, use, self)
    sort_enemies(self,"handcard",true)
    local target
    for _,enemy in sgs.list(self.enemies)do
        if enemy:getHp()<self.player:getHp() then
            if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, "N", self.player) and self:canDamage(enemy, self.player, nil) and not self:cantDamageMore(self.player, enemy) then
                target = enemy
                break
            end
        end
    end
    if not target then
        for _,enemy in sgs.list(self.enemies)do
            if enemy:getHp()<self.player:getHp() then
                if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, "N", self.player) and self:canDamage(enemy, self.player, nil) then
                    target = enemy
                    break
                end
            end
        end
    end
    if target then
        use.card = self:bindSkillCard("tieba_zhili", {}, nil, nil, "#tieba_zhiliCard")
        use.to:append(target)
    return
    end
end

--会员神力
sgs.ai_target_revises.huiyuanshenli = function(to,card,self,use)
    if not card:isKindOf("SkillCard")
    and self.player:getHandcardNum()-self:getCardsNum("Peach")<1
    then return true end
end

sgs.ai_skill_cardask["@huiyuanshenli"] = function(self, data)
    local use = data:toCardUse()
    local current = self.room:getCurrent()
    for _, p in sgs.qlist(use.to) do
        if p:getStrategyMark("huiyuanshenli-Clear") > 0 then
            if self:isFriend(p) then
                if use.card:isKindOf("AmazingGrace") and
                    (p:getSeat() - current:getSeat()) % (self.room:alivePlayerCount()) < self.room:alivePlayerCount() / 2 then
                    local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
                    if #to_discard > 0 then return "$" .. to_discard[1] end
                end
                if use.card:isKindOf("GodSalvation") and p:isWounded() or use.card:isKindOf("ExNihilo") then
                    local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")

                    if #to_discard > 0 then return "$" .. to_discard[1] end
                end
                if use.card:isKindOf("IronChain") then
                    if p:isChained() and not self:isGoodChainTarget(p) then
                        local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
                        if #to_discard > 0 then return "$" .. to_discard[1] end
                    end
                end
                if use.card:isKindOf("Peach") then
                    return true
                end
            end
            if self:isEnemy(p) or (self:isFriend(p) and visible_role(self,p) == "loyalist" and not self:hasJueqingEffect(self.player, p, sgs.card_damage_nature[use.card:getClassName()]) and self.player:isLord() and p:getHp() == 1) then
                if use.card:isKindOf("AOE") then
                    local from = use.from
                    if use.card:isKindOf("SavageAssault") then
                        local menghuo = (self.room:findPlayerBySkillName("huoshou") or false)
                        if menghuo then from = menghuo end
                    end

                    local friend_null = 0
                    for _, other in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                        if self:isFriend(other) then friend_null = friend_null + known_count("Nullification", other, self.player) end
                        if self:isEnemy(other) then friend_null = friend_null - known_count("Nullification", other, self.player) end
                    end
                    friend_null = friend_null + self:getCardsNum("Nullification")
                    local sj_num = self:getCardsNum(use.card:isKindOf("SavageAssault") and "Slash" or "Jink")

                    if self:hasTrickEffective(use.card, p, from) then
                        if self:damageIsEffective(p, sgs.DamageStruct_Normal, from) then
                            if sj_num == 0 and friend_null <= 0 then
                                if self:isEnemy(from) and self:hasJueqingEffect(from, p, sgs.card_damage_nature[use.card:getClassName()]) then

                                    local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
                                    if #to_discard > 0 then return "$" .. to_discard[1] end
                                end
                                if self:isFriend(from) and visible_role(self,p) == "loyalist" and from:isLord() and p:getHp() == 1 and not self:hasJueqingEffect(from, p, sgs.card_damage_nature[use.card:getClassName()]) then
                                    return "."
                                end
                                if (not (self:hasSkills(sgs.masochism_skill, p) or (self.player:hasSkills("tianxiang|ol_tianxiang") and known_card(self.player, self.player, "heart") > 0)) or self:hasJueqingEffect(use.from, p, sgs.card_damage_nature[use.card:getClassName()])) then
                                    return "."
                                end
                            end
                        end
                    end
                elseif self:isEnemy(p) then
                    if use.card:isKindOf("FireAttack") then
                        if self:hasTrickEffective(use.card, p) then
                            if self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player) then
                                if (p:hasArmorEffect("vine") or p:getStrategyMark("@gale") > 0) and self.player:getHandcardNum() > 3
                                    and not (self.player:hasSkill("hongyan") and known_card(p, p, "spade") > 0) then

                                    return true
                                elseif p:isChained() and not self:isGoodChainTarget(p, use.from) then

                                    return true
                                end
                            end
                        end
                    elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") or use.card:isKindOf("Zhujinqiyuan") or use.card:isKindOf("ZdShengdongjixi")) and not p:isKongcheng() then
                        if self:hasTrickEffective(use.card, p) then
                            return true
                        end
                    elseif use.card:isKindOf("Duel") or use.card:isKindOf("chuqibuyi") then
                        if self:hasTrickEffective(use.card, p) then
                            if self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
                                return true
                            end
                        end
                    elseif use.card:isKindOf("IronChain") then
                        if self:isGoodChainTarget(p) then
                            return true
                        end
                    elseif use.card:isDamageCard() then
                        return true
                    end
                end
            end
        end
    end

    return "."
end

sgs.ai_skill_invoke.huiyuanshenli = function(self, data)
    local target = data:toPlayer()
    if self:isEnemy(target) and not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) and not self:needToLoseHp(target, self.player, nil) then
        return true
    end
    if self:isFriend(target) and self:needToLoseHp(target, self.player, nil) then
        return true
    end
    return false
end

--通义

sgs.ai_skill_choice["tongyiAIWJ"]    = function(self, choices, data)
    local items = choices:split("+")
    local target = data:toPlayer()
    if self.player:getStrategyFlag("Jink") then
        if self.player:objectName() == target:objectName() and self:getCardsNum("Jink") > 0 then
            return "yes"
        elseif self.player:objectName() == target:objectName() and self:getCardsNum("Jink") == 0 then
            return "no"
        end
        if known_card(target, self.player, "Jink") > 0 then
            return "yes"
        end
    end
    if self.player:getStrategyFlag("Nullification") then
        if self.player:objectName() == target:objectName() and self:getCardsNum("Nullification") > 0 then
            return "yes"
        elseif self.player:objectName() == target:objectName() and self:getCardsNum("Nullification") == 0 then
            return "no"
        end
        if known_card(target, self.player, "Nullification") > 0 then
            return "yes"
        end
    end
    return items[math.random(1,#items)]
end

sgs.ai_guhuo_card.tongyiTQ = function(self, toname, class_name)
    if class_name and self:getCardsNum(class_name) > 0 then return end
    if self.player:getStrategyFlag("Global_tongyiAIWJ_Failed") then return false end
    if self.player:getStrategyMark("tongyiTQ-using") > 0 then return false end
    if self.player:getStrategyMark("tongyiTQ_allcard-Clear") > 0 then return false end
    local c = tongyi_evaluation(self,toname)
    if (not c) then return end
    if c:isKindOf("BasicCard") or c:isNDTrick() then
        for _, p in sgs.qlist(self.room:findPlayersBySkillName("tongyiAIWJ")) do
            if not self:isEnemy(p) then
                return {skill="tongyiTQ",legacy_class="#tongyiTQ",subcards={},user_string=toname}
            end
        end
    end
end




--千问
sgs.ai_skill_invoke.tiaojiaoCMT = function(self, data)
    local damage = data:toDamage()
    if damage.from and self.player:objectName() == damage.from:objectName() then
        if self:isFriend(damage.to) and damage.to:isWounded() and known(getBestHp(damage.to),"getBestHp") < damage.to:getHp() then
            return true
        end
        if self:isEnemy(damage.to) then
            if damage.damage > 1 then return false end
            if not damage.to:isWounded() then
                return self:doDisCard(damage.to, "h", true)
            end
            if self:isWeak(damage.to) then
                return false
            end
            return self:doDisCard(damage.to, "h", true) and math.random() < 0.5
        end
    end
    return false
end

sgs.ai_skill_invoke.daduanCMT = true

sgs.ai_fill_skill.tiaojiaoCMT=function(self,inclusive,request)
    if self.player:getHandcardNum() > 2 then return nil end
    if self:needBear() and not self.player:isWounded() and self:isWeak() then return nil end
    if self:getPriorTurnUseCount() < 2 then return nil end
    return self:legacySkillSeed("tiaojiaoCMT", "#tiaojiaoCMTCard", request)
end
sgs.ai_skill_use_func["#tiaojiaoCMTCard"] = function(card,use,self)
    local arr1,arr2 = wounded_friends(self)
    local target = nil

    repeat
        if #arr1>0 and (self:isWeak(arr1[1]) or self:isWeak() or self:getOverflow()>=1) then
            target = arr1[1]
            break
        end
        if #arr2>0 and self:isWeak() then
            target = arr2[1]
            break
        end
    until true

    if not target then
        for _,friend in sgs.list(self.friends_noself)do
            if self:canDamageHp(self.player, nil, friend) or self:needToLoseHp(friend, self.player, nil, true, true) then
                target = friend
                break
            end
        end
    end

    if target then
        use.card = bind_tiaojiao(self,card)
        use.to:append(target)
        return
    end
end

sgs.ai_use_priority.tiaojiaoCMTCard = 2.8

-- ChoiceMade peach results precede the public card use. The event DTO's toString()
-- raises unsupported for choice strings it does not project; Kaiyuan flags are public.
local choice_made=sgs.ChoiceMade or "ChoiceMade"
sgs.ai_event_callback[choice_made]=sgs.ai_event_callback[choice_made]or{}
sgs.ai_event_callback[choice_made].KaiyuanShengshi=function(self,player,event)
    local datastr=event:toString()
    if datastr:sub(1,6)~="peach:"then return end
    local target_name=datastr:split(":")[2]
    local target=known(self.room:findPlayerByObjectName(target_name,true),"Kaiyuan target")
    local roles={lord=true,loyalist=true,rebel=true,renegade=true}
    for _,source in ipairs(known(self.room:findPlayersBySkillName("KaiyuanShengshi"),"Kaiyuan sources"))do
        if known(source:hasFlag("KaiyuanShengshi"),"KaiyuanShengshi flag")then
            local name=source:objectName()
            local source_role=visible_role(self,source)
            if not roles[source_role]then ai_unsupported("Kaiyuan source role inference is unresolved","KaiyuanShengshi")end
            local target_role=visible_role(self,target)
            if not roles[target_role]then ai_unsupported("Kaiyuan target role inference is unresolved","KaiyuanShengshi")end
            -- The donor's local rebel->loyalist/-1000 calculation is dead code:
            -- its actual assignment still writes source_role = 1000.
            self:emitStrategyEffect({kind="kaiyuan_role",player=target_name,source_player=name,source_role=source_role,target_role=target_role})
            self:updatePlayers()
        end
    end
end
