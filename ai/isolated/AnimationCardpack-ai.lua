-- Complete fixed b6025acc AnimationCardpack source bodies. All generated
-- material costs remain explicit proposals until native source validation.
local function known(v,k)if v==nil then ai_unsupported("AnimationCardpack value is unknown",k)end return v end
local function q(o,k,...)
    if not o then ai_unsupported("AnimationCardpack object is unknown",k)end
    if k=="getMark"and type(o.getStrategyMark)=="function"then k="getStrategyMark"end
    if type(o[k])~="function"then ai_unsupported("AnimationCardpack helper unavailable",k)end
    return known(o[k](o,...),k)
end
local function copy(t)local out={};for _,v in ipairs(known(t,"card list"))do out[#out+1]=v end return out end
local function reverse(t)local out={};for i=#t,1,-1 do out[#out+1]=t[i]end return out end
local function event_value(self,key,row)
    row=known(row,key)
    if row==false then return{to=AIList.new({})}end
    if type(row)~="table"then ai_unsupported("invalid public event",key)end
    local out={};for k,v in pairs(row)do out[k]=v end
    for _,field in ipairs{"from","to"}do
        local value=out[field]
        if type(value)=="string"then out[field]=known(self.room:findPlayerByObjectName(value,true),key..field)
        elseif value==false then out[field]=nil
        elseif type(value)=="table"and not AIValue.isPlayer(value)then local ps=AIList.new({});for _,name in ipairs(value)do ps:append(AIValue.isPlayer(name)and name or known(self.room:findPlayerByObjectName(name,true),key..field))end;out[field]=ps end
    end
    for _,field in ipairs{"card","from_card","to_card"}do
        if out[field]and not AIValue.isCard(out[field])then out[field]=known(CardView.new(out[field]),key..field)end
    end
    return out
end
local function chopper_spec(player)
    local cards=known(player:getHandcards(),"chopper complete owner hand")
    local spec={name="slash",skill="chopper",suit=sgs.Card_NoSuit,number=0,subcards={}}
    for _,card in ipairs(cards)do spec.subcards[#spec.subcards+1]=q(card,"getEffectiveId")end
    if #cards==1 then spec.suit=q(cards[1],"getSuit");spec.number=q(cards[1],"getNumber")
    elseif #cards>1 then
        local red,black=true,true
        for _,card in ipairs(cards)do red=red and q(card,"isRed");black=black and q(card,"isBlack")end
        spec.suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit
    end
    return spec
end
--武器攻击范围
sgs.weapon_range.Elucidator = 2

sgs.ai_skill_invoke.Elucidator = function(self, data)
    local damage = data:toDamage()
    if self:isFriend(damage.to) and self:canDraw(damage.to, self.player) then
        return true
    end
    local slash = self:getCard("Slash")
    if slash then
        local dummy_use = self:aiUseCard(slash,{isDummy=true,extra_target=0,current_targets={},to=AIList.new({})})

        if dummy_use.card and not dummy_use.to:isEmpty() then
            return true
        end
    end

    return false
end

sgs.ai_skill_invoke.htms_rishi = function(self, data)
    local target = data:toPlayer()
    if target and self:isEnemy(target) then
        return true
    end
    return false
end

sgs.ai_canliegong_skill.htms_rishi = function(self, from, to)
    return q(from,"getHandcardNum") < q(to,"getHandcardNum")
end

sgs.weapon_range.chopper = 3


sgs.ai_fill_skill.chopper = function(self,inclusive,request)
    if q(self.player,"getHandcardNum")>q(self.player,"getHp")
    or q(self.player,"isKongcheng") then return end
    local spec=chopper_spec(self.player)
    return self:bindTurnConversion("chopper","Slash",spec,request)
end

function sgs.ai_cardsview.chopper(self, class_name, player)
    if q(player,"getPhase") ~= sgs.Player_NotActive then return end
    if class_name == "Slash"then
        local slashs = {}
        for _, c in ipairs(player:getCards("h")) do
            if c:isKindOf("Slash") then
                table.insert(slashs, c)
            end
        end
        if #slashs == 0 then
            return chopper_spec(player)
        end
    end
end

--使用优先级
sgs.ai_use_priority.Rho_Aias = 2.6

sgs.ai_skill_discard.Rho_Aias_trigger = function(self,discard_num,optional,include_equip)
    if self.player:getPile("ring"):length() >= 2 then return {} end
    local cards = copy(self.player:getHandcards())
    local to_discard = {}
    local compare_func = function(a,b)
        return self:getKeepValue(a)<self:getKeepValue(b)
    end
    table.sort(cards,compare_func)
    for _,card in ipairs(cards)do
        if #to_discard>=1 then break end
        table.insert(to_discard,q(card,"getId"))
    end

    return to_discard
end
sgs.ai_view_as.Rho_Aias = function(card,player,card_place)
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    if player:getPile("ring"):contains(card_id) then
        return{name="jink",skill="Rho_Aias",suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={card_id}}
    end
end
--使用结构

function SmartAIView:useCardmouthgun(card, use)
    if q(self.player,"hasSkill","noswuyan") then return end
    --暂且忽略对队友使用嘴炮的可能性

    --注意的技能：【屯田】，【纵适】，【鹰扬】

    --拼点事宜
    local cards = AIList.new({})
    local peach = 0
    for _, c in ipairs(self.player:getHandcards()) do
        if isCard("Peach", c, self.player) and peach < 2 then
            peach = peach + 1
        else
            cards:append(c)
        end
    end
    local max_card = self:getMaxCard(self.player, cards)
    if not max_card then return end
    local max_point = q(max_card,"getNumber")

    --目标选择
    self.enemies = self:sort(self.enemies, "handcard")
    self.enemies = reverse(self.enemies)
    for _, enemy in ipairs(self.enemies) do
        if q(enemy,"getHandcardNum") < 5 and not q(enemy,"isKongcheng") and q(self.player,"distanceTo",enemy) <= math.max(1, q(self.player,"getHp")) then
            use.card = card
            if use.to then use.to:append(enemy) end
            return
        end
    end

--  use.card = card
    return
end

function sgs.ai_skill_pindian.mouthgun(minusecard, self, requestor)
    if q(requestor,"getHandcardNum") == 1 then
        local cards = copy(self.player:getHandcards())
        cards = self:sortByKeepValue(cards)
        return cards[1]
    end
    local maxcard = self:getMaxCard()
    return self:isFriend(requestor) and self:getMinCard() or ( q(maxcard,"getNumber") < 6 and  minusecard or maxcard )
end
sgs.ai_skill_choice["mouthgun"] = function(self, choices, data)
    local card = self:getEvaluationCard("mouthgun")

    local pindian = event_value(self,"pindian",self:getDecisionContext().pindian)
    local fromNumber = q(pindian.from_card,"getNumber")
    local toNumber = q(pindian.to_card,"getNumber")
    local winner, loser
    if fromNumber ~= toNumber then
        if fromNumber > toNumber then
            winner = pindian.from
            loser = pindian.to
        else
            winner = pindian.to
            loser = pindian.from
        end
    end
    if self:ajustDamage(winner, self.player, 1, card) == 0 then
        return "mouthgun_fail"
    end
    if self:isWeak() then
        return "mouthgun_qp"
    end
    if self:needToLoseHp(self.player, winner)  then return "mouthgun_fail" end
    return "mouthgun_qp"
end


sgs.ai_skill_cardask["@murasameself"] = function(self,data,pattern,target)
    local card_list = self.player:getHandcards()
    local cards = copy(card_list)
    cards = self:sortByKeepValue(cards,false)
    return "$"..cards[1]:getEffectiveId()
end
sgs.ai_skill_cardask["@murasamekilla"] = function(self,data,pattern)
    local colour = pattern:split("|")[2]
    local use = data:toCardUse()
    if self:needToThrowArmor() and self.player:getArmor():getColorString()==colour then return "$"..self.player:getArmor():getEffectiveId() end
    if not self:slashIsEffective(use.card,self.player,use.from)
    or (self:ajustDamage(use.from,self.player,1,use.card)<2
    and self:needToLoseHp(self.player,use.from,use.card)) then return "." end
    if self:ajustDamage(use.from,self.player,1,use.card) and self:getCardsNum("Peach")>0 then return "." end
    if self:getCardsNum("Jink")==0 or not sgs.isJinkAvailable(use.from,self.player,use.card,true) then return "." end
    local jiangqin = self.room:findPlayerBySkillName("niaoxiang")
    local need_double_jink = q(use.from,"hasSkill","wushuang")
        or (q(use.from,"hasSkill","roulin") and q(self.player,"isFemale"))
        or (q(self.player,"hasSkill","roulin") and q(use.from,"isFemale"))
        or (jiangqin and jiangqin:isAdjacentTo(self.player) and q(use.from,"isAdjacentTo",self.player) and self:isEnemy(jiangqin))
    local cards = copy(self.player:getHandcards())
    cards = self:sortByKeepValue(cards)
    for _,card in ipairs(cards)do
        if q(card,"getColorString")~=colour or (not self:isWeak() and (self:getKeepValue(card)>8 or self:isValuableCard(card)))
            or (isCard("Jink",card,self.player) and self:getCardsNum("Jink")-1<(need_double_jink and 2 or 1)) then continue end
        return "$"..card:getEffectiveId()
    end
end

sgs.ai_skill_cardask["@murasamekillb"] = sgs.ai_skill_cardask["@murasamekilla"]
sgs.ai_skill_cardask["@murasamekillc"] = sgs.ai_skill_cardask["@murasamekilla"]
sgs.ai_skill_invoke.Murasame = function(self, data)
    local target = data:toPlayer()
    if target and self:isEnemy(target) then
        return true
    end
    return false
end
sgs.weapon_range.Murasame = 2

sgs.weapon_range.tywz = 2

sgs.ai_skill_invoke.tywz = function(self, data)
    local target = data:toDamage().to
    if target and self:isEnemy(target) then
        return true
    end
    return false
end
sgs.ai_choicemade_filter.skillInvoke.tywz = function(self,player,promptlist)
    local facts=self.world.strategy_facts
    local damage=event_value(self,"CurrentDamageStruct",facts and facts.standard and facts.standard.current_damage)
    if damage.from and promptlist[3]=="yes" then
        self:updateIntention(player,damage.to,40)
    end
end

sgs.weapon_range.hqiangwei = 2
sgs.ai_skill_discard.hqiangwei = function(self,discard_num,optional,include_equip)
    local facts=self.world.strategy_facts
    local name=known(facts and facts.animation_cardpack and facts.animation_cardpack.hqiangwei_target,"owner hqiangwei target")
    local target=name~=false and known(self.room:findPlayerByObjectName(name,true),"hqiangwei target")or nil
    if not target or self:isFriend(target) then return {} end
    local cards = copy(self.player:getHandcards())
    local to_discard = {}
    local compare_func = function(a,b)
        return self:getKeepValue(a)<self:getKeepValue(b)
    end
    table.sort(cards,compare_func)
    for _,card in ipairs(cards)do
        if #to_discard>=1 then break end
        table.insert(to_discard,q(card,"getId"))
    end

    return to_discard
end

--收藏价值
sgs.ai_keep_value.mouthgun = 3.16
sgs.ai_keep_value.shuugakulyukou = 3.21
sgs.ai_keep_value.rotenburo = 3.25
sgs.ai_keep_value.bunkasai = 3.35
sgs.ai_keep_value.strike_the_death = 3.24

--使用价值
sgs.ai_use_value.mouthgun = 4.9

sgs.ai_ajustdamage_from["@std"] = function(self, from, to, card, nature)
    return q(from,"getMark","@std")
end

sgs.ai_skill_use["@strike_the_death"] = function(self, prompt)
    local dying = self.room:getCurrentDyingPlayer()
    if dying then
        local peaches = 1-q(dying,"getHp")
        if self:getCardsNum("Peach")+self:getCardsNum("Analeptic")<peaches then
            local cards = copy(self.player:getCards("he"))
            cards = self:sortByKeepValue(cards)
            local cards = self.player:getHandcards()
            local card
            cards = copy(cards)

            for _,acard in ipairs(cards)  do
                if q(acard,"isKindOf","strike_the_death") then
                    card = acard
                    break
                end
            end
            if not card then
                return "."
            end
            local use=AIUsePlan.new();use.card=card;return use:toAnswer()
        end
    end

    return "."
end

function SmartAIView:useCardstrike_the_death(card,use)
    if self:isWeak() then return end
    use.card = card
    return
end


function SmartAIView:useCardrotenburo(card,use)
    local n = 0
    for _,p in ipairs(self.room:getAlivePlayers())do
        if q(self.player,"canUse",card,p) then
            if self:isFriend(p) then
                n = n+1
                if self:isWeak(p) then
                    n = n+1
                end
            elseif self:isEnemy(p) then
                n = n-1
                if self:isWeak(p) then
                    n = n-1
                end
            end
        end
    end
    if n>=0 then
        use.card = card
    end
end
sgs.ai_use_priority.rotenburo = 1.4
sgs.ai_keep_value.rotenburo = 4
sgs.ai_use_value.rotenburo = 2.7


function SmartAIView:useCardbunkasai(card,use)
    local min = 999
    local target
    for _,p in ipairs(self.room:getAlivePlayers())do
        if q(self.player,"canUse",card,p) then
            if q(p,"getHandcardNum") < min then
                min = q(p,"getHandcardNum")
                target = p
            end
        end
    end
    if target and self:isEnemy(target) and self:hasTrickEffective(card,target,self.player) and self:isGoodTarget(target) then
        use.card = card
    end
end
sgs.ai_skill_discard.bunkasai = function(self,discard_num,optional,include_equip)
    local cards = copy(self.player:getHandcards())
    local to_discard = {}
    local suit = {}
    -- local use = sgs.filterData[sgs.CardUsed]:toCardUse()
    local context=self:getDecisionContext()
    if known(context.bunkasai_card_present,"bunkasai public card tag presence")==false then error("donor bunkasai: absent usecard tag before toString",0)end
    local use=event_value(self,"bunkasai UseHistory",context.bunkasai_use)
    if use then
        if self:needToLoseHp(self.player,use.from,use.card,true)then return to_discard end
        local min = 999
        local target
        for _,p in ipairs(use.to)do
            if q(p,"getHandcardNum") < min then
                min = q(p,"getHandcardNum")
                target = p
            end
        end
        if target and self:isFriend(target) and self:hasTrickEffective(use.card,target,use.from) and self:isWeak(target) then
            return to_discard
        end
    end
    for _,card in ipairs(cards)do
        if #to_discard>=discard_num then break end
        if table.contains(suit,q(card,"getSuitString")) then continue end
        table.insert(to_discard,q(card,"getId"))
        table.insert(suit,q(card,"getSuitString"))
    end

    return to_discard
end

function SmartAIView:useCardtogether_go_die(card,use)
    local slashcount = self:getCardsNum("Slash")
    local cards = copy(self.player:getCards("he"))
    cards = self:sortByUseValue(cards, true)
    if slashcount > 0  then
        local slash = self:getCard("Slash")
        assert(slash)
        local dummy_use = self:aiUseCard(slash,{isDummy=true,extra_target=0,current_targets={},to=AIList.new({})})
        if dummy_use and dummy_use.card and not dummy_use.to:isEmpty() then
            for _, p in ipairs(dummy_use.to) do
                if q(p,"getHandcardNum") >= q(self.player,"getHandcardNum") then
                    use.card = card
                    if use.to then use.to:append(p) end
                        return
                end
            end
        end
    end
end
sgs.ai_use_priority.together_go_die = sgs.ai_use_priority.Slash + 2

function SmartAIView:useCardshuugakulyukou(card,use)
    self.friends_noself = self:sort(self.friends_noself,"defense")
    for _,friend in ipairs(self.friends_noself)do
        if  not q(friend,"containsTrick","shuugakulyukou")
        then
            use.card = card
            use.to:append(friend)
            return
        end
    end
end

sgs.ai_card_intention.shuugakulyukou = -40

--[[Elucidator
shuugakulyukou
rotenburo
chopper
bunkasai
mouthgun
Rho_Aias
strike_the_death
kotatsu]]

ai_card_use.mouthgun=function(self,card,use)return self:useCardmouthgun(card,use)end
ai_card_use.strike_the_death=function(self,card,use)return self:useCardstrike_the_death(card,use)end
ai_card_use.rotenburo=function(self,card,use)return self:useCardrotenburo(card,use)end
ai_card_use.bunkasai=function(self,card,use)return self:useCardbunkasai(card,use)end
ai_card_use.together_go_die=function(self,card,use)return self:useCardtogether_go_die(card,use)end
ai_card_use.shuugakulyukou=function(self,card,use)return self:useCardshuugakulyukou(card,use)end
