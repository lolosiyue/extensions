-- Fixed b6025acc AIgeneral strategy bodies. Native authorization is separate
-- from source planning; foreign private roles use an explicit viewer estimate.
local function known(v,key)
    if v==nil then ai_unsupported("AIgeneral value is unknown",key)end
    return v
end
local function q(object,method,...)
    if not object or type(object[method])~="function"then ai_unsupported("AIgeneral method is unavailable",method)end
    if AIValue.isPlayer(object)then
        if method=="getMark"then method="getStrategyMark"
        elseif method=="hasFlag"then method="getStrategyFlag"end
    end
    if method=="findPlayerBySkillName"then
        local all=known(object:findPlayersBySkillName(...),method)
        return all[1]or false
    end
    return known(object[method](object,...),method)
end
local function visible_role(self,player)
    local role=player:getRole()
    if role~=nil then return role end
    role=q(self,"getRoleEstimate",player)
    return self:useKnowledgeEstimate({value=role,status="estimate",basis="AIgeneral:viewer_inference_replaces_foreign_private_role",viewer=q(self.player,"objectName"),observer=q(player,"objectName")},"AIgeneral.role")
end
local function known_card(...)return known(getKnownCard(...),"getKnownCard")end
local function known_count(...)return known(getCardsNum(...),"getCardsNum")end
local function sort_enemies(self,...)
    self.enemies=q(self,"sort",known(self.enemies,"enemies"),...)
end
local function wounded_friends(self)
    local first,second=self:getWoundedFriend(false)
    return known(first,"wounded friend first group"),known(second,"wounded friend second group")
end
local function bind_tiaojiao(self,source)
    local costs={}
    for _,card in ipairs(q(self.player,"getHandcards"))do costs[#costs+1]=q(card,"getEffectiveId")end
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
    local target = q(data,"toDamage").to
    if  q(self,"getRoleEstimate",target) ~= "neutral" or q(target,"isLord")  then
        return true
    end
    return false
end

sgs.ai_skill_choice.deep_seek = function(self, choices, data)
    local target = q(data,"toPlayer")
    local items = q(choices,"split","+")

    if q(self,"getRoleEstimate",target)== "rebel" and table.contains(items, "rebel")  then
        return "rebel"
    elseif q(target,"isLord") and table.contains(items, "lord")  then
        return "lord"
    elseif q(self,"getRoleEstimate",target)== "loyalist" and table.contains(items, "loyalist")  then
        return "loyalist"
    elseif q(self,"getRoleEstimate",target)== "renegade" and table.contains(items, "renegade")  then
        return "renegade"
    end
    return items[1]
end

sgs.ai_fill_skill.tieba_zhili = function(self,inclusive,request)
    return q(self,"legacySkillSeed","tieba_zhili","#tieba_zhiliCard",request)
end

sgs.ai_skill_use_func["#tieba_zhiliCard"] = function(card, use, self)
    sort_enemies(self,"handcard",true)
    local target
    for _,enemy in sgs.list(self.enemies)do
        if q(enemy,"getHp")<q(self.player,"getHp") then
            if not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy, "N", self.player) and q(self,"canDamage",enemy,self.player,nil) and not q(self,"cantDamageMore",self.player, enemy) then
                target = enemy
                break
            end
        end
    end
    if not target then
        for _,enemy in sgs.list(self.enemies)do
            if q(enemy,"getHp")<q(self.player,"getHp") then
                if not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy, "N", self.player) and q(self,"canDamage",enemy,self.player,nil) then
                    target = enemy
                    break
                end
            end
        end
    end
    if target then
        use.card = q(self,"bindSkillCard","tieba_zhili",{},nil,nil,"#tieba_zhiliCard")
        use.to:append(target)
    return
    end
end

--会员神力
sgs.ai_target_revises.huiyuanshenli = function(to,card,self,use)
    if not q(card,"isKindOf","SkillCard")
    and q(self.player,"getHandcardNum")-q(self,"getCardsNum","Peach")<1
    then return true end
end

sgs.ai_skill_cardask["@huiyuanshenli"] = function(self, data)
    local use = q(data,"toCardUse")
    local current = q(self.room,"getCurrent")
    for _, p in sgs.qlist(use.to) do
        if q(p,"getMark","huiyuanshenli-Clear") > 0 then
            if q(self,"isFriend",p) then
                if q(use.card,"isKindOf","AmazingGrace") and
                    (q(p,"getSeat") - q(current,"getSeat")) % (q(self.room,"alivePlayerCount")) < q(self.room,"alivePlayerCount") / 2 then
                    local to_discard = q(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")
                    if #to_discard > 0 then return "$" .. to_discard[1] end
                end
                if q(use.card,"isKindOf","GodSalvation") and q(p,"isWounded") or q(use.card,"isKindOf","ExNihilo") then
                    local to_discard = q(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")

                    if #to_discard > 0 then return "$" .. to_discard[1] end
                end
                if q(use.card,"isKindOf","IronChain") then
                    if q(p,"isChained") and not q(self,"isGoodChainTarget",p) then
                        local to_discard = q(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")
                        if #to_discard > 0 then return "$" .. to_discard[1] end
                    end
                end
                if q(use.card,"isKindOf","Peach") then
                    return true
                end
            end
            if q(self,"isEnemy",p) or (q(self,"isFriend",p) and visible_role(self,p) == "loyalist" and not hasJueqingEffect(self.player, p, sgs.card_damage_nature[q(use.card,"getClassName")]) and q(self.player,"isLord") and q(p,"getHp") == 1) then
                if q(use.card,"isKindOf","AOE") then
                    local from = use.from
                    if q(use.card,"isKindOf","SavageAssault") then
                        local menghuo = q(self.room,"findPlayerBySkillName","huoshou")
                        if menghuo then from = menghuo end
                    end

                    local friend_null = 0
                    for _, other in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
                        if q(self,"isFriend",other) then friend_null = friend_null + known_count("Nullification", other, self.player) end
                        if q(self,"isEnemy",other) then friend_null = friend_null - known_count("Nullification", other, self.player) end
                    end
                    friend_null = friend_null + q(self,"getCardsNum","Nullification")
                    local sj_num = q(self,"getCardsNum",q(use.card,"isKindOf","SavageAssault") and "Slash" or "Jink")

                    if q(self,"hasTrickEffective",use.card, p, from) then
                        if q(self,"damageIsEffective",p, sgs.DamageStruct_Normal, from) then
                            if sj_num == 0 and friend_null <= 0 then
                                if q(self,"isEnemy",from) and hasJueqingEffect(from, p, sgs.card_damage_nature[q(use.card,"getClassName")]) then

                                    local to_discard = q(self,"askForDiscard","dummyreason", 1, 1, false, false, ".")
                                    if #to_discard > 0 then return "$" .. to_discard[1] end
                                end
                                if q(self,"isFriend",from) and visible_role(self,p) == "loyalist" and q(from,"isLord") and q(p,"getHp") == 1 and not hasJueqingEffect(from, p, sgs.card_damage_nature[q(use.card,"getClassName")]) then
                                    return "."
                                end
                                if (not (q(self,"hasSkills",sgs.masochism_skill, p) or (q(self.player,"hasSkills","tianxiang|ol_tianxiang") and known_card(self.player, self.player, "heart") > 0)) or hasJueqingEffect(use.from, p, sgs.card_damage_nature[q(use.card,"getClassName")])) then
                                    return "."
                                end
                            end
                        end
                    end
                elseif q(self,"isEnemy",p) then
                    if q(use.card,"isKindOf","FireAttack") then
                        if q(self,"hasTrickEffective",use.card, p) then
                            if q(self,"damageIsEffective",p, sgs.DamageStruct_Fire, self.player) then
                                if (q(p,"hasArmorEffect","vine") or q(p,"getMark","@gale") > 0) and q(self.player,"getHandcardNum") > 3
                                    and not (q(self.player,"hasSkill","hongyan") and known_card(p, p, "spade") > 0) then

                                    return true
                                elseif q(p,"isChained") and not q(self,"isGoodChainTarget",p, use.from) then

                                    return true
                                end
                            end
                        end
                    elseif (q(use.card,"isKindOf","Snatch") or q(use.card,"isKindOf","Dismantlement") or q(use.card,"isKindOf","Zhujinqiyuan") or q(use.card,"isKindOf","ZdShengdongjixi")) and not q(p,"isKongcheng") then
                        if q(self,"hasTrickEffective",use.card, p) then
                            return true
                        end
                    elseif q(use.card,"isKindOf","Duel") or q(use.card,"isKindOf","chuqibuyi") then
                        if q(self,"hasTrickEffective",use.card, p) then
                            if q(self,"damageIsEffective",p, sgs.DamageStruct_Normal, self.player) then
                                return true
                            end
                        end
                    elseif q(use.card,"isKindOf","IronChain") then
                        if q(self,"isGoodChainTarget",p) then
                            return true
                        end
                    elseif q(use.card,"isDamageCard") then
                        return true
                    end
                end
            end
        end
    end

    return "."
end

sgs.ai_skill_invoke.huiyuanshenli = function(self, data)
    local target = q(data,"toPlayer")
    if q(self,"isEnemy",target) and not q(self,"cantbeHurt",target) and q(self,"damageIsEffective",target, sgs.DamageStruct_Normal, self.player) and not q(self,"needToLoseHp",target, self.player, nil) then
        return true
    end
    if q(self,"isFriend",target) and q(self,"needToLoseHp",target, self.player, nil) then
        return true
    end
    return false
end

--通义

sgs.ai_skill_choice["tongyiAIWJ"]    = function(self, choices, data)
    local items = q(choices,"split","+")
    local target = q(data,"toPlayer")
    if q(self.player,"hasFlag","Jink") then
        if q(self.player,"objectName") == q(target,"objectName") and q(self,"getCardsNum","Jink") > 0 then
            return "yes"
        elseif q(self.player,"objectName") == q(target,"objectName") and q(self,"getCardsNum","Jink") == 0 then
            return "no"
        end
        if known_card(target, self.player, "Jink") > 0 then
            return "yes"
        end
    end
    if q(self.player,"hasFlag","Nullification") then
        if q(self.player,"objectName") == q(target,"objectName") and q(self,"getCardsNum","Nullification") > 0 then
            return "yes"
        elseif q(self.player,"objectName") == q(target,"objectName") and q(self,"getCardsNum","Nullification") == 0 then
            return "no"
        end
        if known_card(target, self.player, "Nullification") > 0 then
            return "yes"
        end
    end
    return items[math.random(1,#items)]
end

sgs.ai_guhuo_card.tongyiTQ = function(self, toname, class_name)
    if class_name and q(self,"getCardsNum",class_name) > 0 then return end
    if q(self.player,"hasFlag","Global_tongyiAIWJ_Failed") then return false end
    if q(self.player,"getMark","tongyiTQ-using") > 0 then return false end
    if q(self.player,"getMark","tongyiTQ_allcard-Clear") > 0 then return false end
    local c = tongyi_evaluation(self,toname)
    if (not c) then return end
    if q(c,"isKindOf","BasicCard") or q(c,"isNDTrick") then
        for _, p in sgs.qlist(q(self.room,"findPlayersBySkillName","tongyiAIWJ")) do
            if not q(self,"isEnemy",p) then
                return {skill="tongyiTQ",legacy_class="#tongyiTQ",subcards={},user_string=toname}
            end
        end
    end
end




--千问
sgs.ai_skill_invoke.tiaojiaoCMT = function(self, data)
    local damage = q(data,"toDamage")
    if damage.from and q(self.player,"objectName") == q(damage.from,"objectName") then
        if q(self,"isFriend",damage.to) and q(damage.to,"isWounded") and known(getBestHp(damage.to),"getBestHp") < q(damage.to,"getHp") then
            return true
        end
        if q(self,"isEnemy",damage.to) then
            if damage.damage > 1 then return false end
            if not q(damage.to,"isWounded") then
                return q(self,"doDisCard",damage.to, "h", true)
            end
            if q(self,"isWeak",damage.to) then
                return false
            end
            return q(self,"doDisCard",damage.to, "h", true) and math.random() < 0.5
        end
    end
    return false
end

sgs.ai_skill_invoke.daduanCMT = true

sgs.ai_fill_skill.tiaojiaoCMT=function(self,inclusive,request)
    if q(self.player,"getHandcardNum") > 2 then return nil end
    if q(self,"needBear") and not q(self.player,"isWounded") and q(self,"isWeak") then return nil end
    if q(self,"getPriorTurnUseCount") < 2 then return nil end
    return q(self,"legacySkillSeed","tiaojiaoCMT","#tiaojiaoCMTCard",request)
end
sgs.ai_skill_use_func["#tiaojiaoCMTCard"] = function(card,use,self)
    local arr1,arr2 = wounded_friends(self)
    local target = nil

    repeat
        if #arr1>0 and (q(self,"isWeak",arr1[1]) or q(self,"isWeak") or q(self,"getOverflow")>=1) then
            target = arr1[1]
            break
        end
        if #arr2>0 and q(self,"isWeak") then
            target = arr2[1]
            break
        end
    until true

    if not target then
        for _,friend in sgs.list(self.friends_noself)do
            if q(self,"canDamageHp",self.player, nil, friend) or q(self,"needToLoseHp",friend, self.player, nil, true, true) then
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

-- ChoiceMade peach results precede the public card use. Native provides this
-- witness only to the actual asking viewer; no response card identity is exposed.
local choice_made=sgs.ChoiceMade or "ChoiceMade"
sgs.ai_event_callback[choice_made]=sgs.ai_event_callback[choice_made]or{}
sgs.ai_event_callback[choice_made].KaiyuanShengshi=function(self,player,event)
    local facts=self.world.strategy_facts
    local witness=known(facts and facts.kaiyuan_role_witness,"Kaiyuan ChoiceMade witness")
    if witness==false then return end
    if type(witness)~="table"or type(witness.player)~="string"or not AIValue.isList(witness.sources)then
        ai_unsupported("Kaiyuan witness is malformed","KaiyuanShengshi")
    end
    local target=known(self.room:findPlayerByObjectName(witness.player,true),"Kaiyuan target")
    local roles={lord=true,loyalist=true,rebel=true,renegade=true}
    for _,name in ipairs(witness.sources)do
        local source=known(self.room:findPlayerByObjectName(name,true),"Kaiyuan source")
        local source_role=visible_role(self,source)
        if not roles[source_role]then ai_unsupported("Kaiyuan source role inference is unresolved","KaiyuanShengshi")end
        local target_role=visible_role(self,target)
        if not roles[target_role]then ai_unsupported("Kaiyuan target role inference is unresolved","KaiyuanShengshi")end
        -- The donor's local rebel->loyalist/-1000 calculation is dead code:
        -- its actual assignment still writes source_role = 1000.
        self:emitStrategyEffect({kind="kaiyuan_role",player=witness.player,source_player=name,source_role=source_role,target_role=target_role})
        self:updatePlayers()
    end
end
