-- Maneuvering package policy. Source: b6025acc ai/maneuvering-ai.lua.
local function known(value,key)
    if value==nil then ai_unsupported("maneuvering fact is unknown",key) end
    return value
end
local function query(object,method,...)
    if AIValue.isPlayer(object) then
        if method=="getMark" and type(object.getStrategyMark)=="function" then method="getStrategyMark" end
        if method=="hasFlag" and type(object.getStrategyFlag)=="function" then method="getStrategyFlag" end
    end
    if not object or type(object[method])~="function" then ai_unsupported("maneuvering method is unavailable",method) end
    return known(object[method](object,...),method)
end
local function fan_spec(card)
    return {name="fire_slash",skill="fan",suit=query(card,"getSuit"),number=query(card,"getNumber"),subcards={query(card,"getEffectiveId")}}
end

sgs.ai_view_as.fan=function(card,player,place)
    known(place,"fan card place")
    if place~=sgs.Player_PlaceSpecial and query(card,"isKindOf","Slash")
        and not query(card,"isKindOf","NatureSlash") then return fan_spec(card) end
end
sgs.ai_fill_skill.fan=function(self,inclusive,request)
    local cards=query(self,"sortByKeepValue",query(self,"addHandPile"),nil,"l")
    for _,card in ipairs(cards) do
        if query(card,"isKindOf","Slash") and not query(card,"isKindOf","NatureSlash") then
            -- Fixed source constructs the hypothesis before availability/payment.
            local slash=self:evaluateTurnConversion("fan","FireSlash",{
                name="fire_slash",skill="fan",suit=sgs.Card_NoSuit,number=0,
                subcards={query(card,"getEffectiveId")}},request)
            if query(slash,"isAvailable",self.player) then return slash end
        end
    end
end
sgs.ai_skill_invoke.fan=function(self,data)
    local use=query(data,"toCardUse")
    for _,target in ipairs(known(use.to,"fan use targets")) do
        local fire=self:getFanConversionProbe(known(use.card,"fan use card"))
        local damage=query(self,"ajustDamage",self.player,target,1,fire)
        if query(self,"isFriend",target) then
            if damage==0 or query(target,"isChained") and query(self,"isGoodChainTarget",target,fire) then return true end
        else
            if query(target,"isChained") then
                if query(self,"isGoodChainTarget",target,fire) then return true end
            elseif damage>=query(self,"ajustDamage",self.player,target,1,use.card) then return true end
        end
    end
    return false
end
sgs.ai_weapon_value.fan=function(self,enemy)
    if enemy and query(self,"ajustDamage",self.player,enemy,1,nil,"F")>1 then return 6 end
end
sgs.ai_armor_value.vine=function(player,self)
    if query(player,"getHandcardNum")==1 and query(self,"needKongcheng",player) then
        return query(player,"hasSkill","kongcheng") and 5 or 3.8
    end
    if query(player,"hasSkills",sgs.lose_equip_skill) then return 3.8 end
    if not query(self,"damageIsEffective",player,sgs.DamageStruct_Fire) and not player:getArmor() then return 6 end
    if query(self.player,"hasSkill","sizhan") then return 4.9 end
    if query(player,"getPhase")==sgs.Player_Play and not player:getArmor() then
        if #query(self,"getFriends",player,true)>0 and query(player,"hasSkill","jujian")
            or query(player,"hasSkill","diyyicong") then return 3 end
    end
    if query(player,"isChained") and not(self:isGoodChainTarget(player,query(self,"getEvaluationCard","fire_slash"))
        and self:isGoodChainTarget(player,query(self,"getEvaluationCard","thunder_slash"))) then return -2 end
    for _,enemy in ipairs(query(self,"getEnemies",player)) do
        if query(enemy,"canSlash",player) and query(enemy,"hasWeapon","Fan")
            or self:useKnowledgeEstimate(self:estimateKnownCards(enemy,"FireSlash,FireAttack,Fan",player,true),"vine.known_fire_cards")>0
            or query(enemy,"getMark","@flame")>0 and query(enemy,"hasSkill","yeyan")
            or query(enemy,"hasSkills","huoji|longhun|shaoying|zonghuo|wuling") then return -2 end
    end
    if #self.enemies<3 and query(self.room,"getTurnCount")>2 or query(player,"getHp")<=2 then return 5 end
    if query(player,"getPileCount","counter")>1 and query(player,"hasSkill","xiansi") then return 3 end
    return 0
end
sgs.weapon_range.fan=4
sgs.ai_use_priority.Fan=2.655
sgs.ai_use_priority.Vine=0.95

-- maneuvering-ai.lua:398–410. These revise the recast decision before the
-- shared IronChain target planner; an empty pile is a count, not private IDs.
sgs.ai_use_revises.yinbing=function(self,card,use)
    if query(card,"isKindOf","IronChain")
        and query(self.player,"getPileCount","yinbing")==0
        and query(self.player,"getHandcardNum")-query(self,"getCardsNum","BasicCard")==1
        and not query(self,"isWeak") then use.card=card end
end
sgs.ai_use_revises.manjuan=function(self,card,use)
    if query(card,"isKindOf","IronChain") and query(self,"getOverflow")<=0 then use.card=card end
end

local function fire_effect_card(self)
    local context=query(self,"getDecisionContext")
    local effect=context.effect
    if effect==nil then
        local known_effect
        effect,known_effect=self:getEventMemory("card_effect")
        if known_effect~=true then ai_unsupported("FireAttack effect memory is unknown","@fire-attack") end
    end
    local card=effect and effect.card
    if not card then ai_unsupported("FireAttack effect card is absent","@fire-attack") end
    if type(card.isKindOf)~="function" then card=CardView.new(card) end
    return card
end

-- The legacy registry adapter validates the selected physical ID against the
-- request's offered cards after this complete policy has chosen it.
sgs.ai_skill_cardask["@fire-attack"]=function(self,data,pattern,target)
    local cards=query(self,"sortByUseValue",query(self.player,"getCards","h"),true)
    local convert={[".S"]="spade",[".D"]="diamond",[".H"]="heart",[".C"]="club",[".N"]="no_shit"}
    for index,card in ipairs(cards) do
        if query(card,"getSuitString")==convert[pattern] then
            if query(self,"isFriend",target) then
                if not(query(target,"isChained") or query(self,"needToLoseHp",target,self.player,fire_effect_card(self))) then break end
            end
            if not query(self.player,"isJilei",card) then
                if index>#cards/2 and isCard("Peach",card,self.player) then
                    if query(target,"isChained") then
                        if self:isGoodChainTarget(target,fire_effect_card(self)) then return query(card,"getId") end
                    elseif not query(self,"isWeak",nil,false)
                        or query(self,"ajustDamage",self.player,target,1,fire_effect_card(self))>1 then return query(card,"getId") end
                elseif query(target,"isChained") then
                    if self:isGoodChainTarget(target,fire_effect_card(self)) then return query(card,"getId") end
                else return query(card,"getId") end
            end
        end
    end
    return "."
end

sgs.ai_cardshow.fire_attack=function(self,requestor)
    local cards=query(self,"sortByUseValue",query(self.player,"getHandcards"),true)
    if query(requestor,"objectName")==query(self.player,"objectName") then return cards[1] end
    local priority={no_shit=5,heart=4,spade=3,club=2,diamond=1}
    local index,result=-1,cards[1]
    for _,card in ipairs(cards) do
        local suit=query(card,"hasSuit") and query(card,"getSuitString") or "no_shit"
        local value=known(priority[suit],"fire_attack show suit")
        local filtered=query(self,"CardFilter",card,requestor,sgs.Player_PlaceHand)
        local filtered_suit=query(filtered,"hasSuit") and query(filtered,"getSuitString") or "no_shit"
        if filtered_suit~=suit then value=value+5 end
        if value>index then result,index=card,value end
    end
    return result
end

-- Static metadata belongs to the package registry as well as the shared
-- planner's printed defaults. Nature values are already normalized by hooks.
for name,values in pairs({ThunderSlash={4.55,3.66,2.7},FireSlash={4.6,3.63,2.7},
    Analeptic={5.98,4.1,3},SupplyShortage={7,3.48,0.5},IronChain={5.4,3.34,9.1},
    FireAttack={4.8,3.3,(sgs.ai_use_priority.Dismantlement or 9.4)+0.1}}) do
    sgs.ai_use_value[name],sgs.ai_keep_value[name],sgs.ai_use_priority[name]=values[1],values[2],values[3]
end
sgs.dynamic_value.benefit.Analeptic=true
sgs.dynamic_value.control_usecard.SupplyShortage=true
sgs.dynamic_value.damage_card.FireAttack=true
sgs.ai_card_intention.SupplyShortage=120
sgs.ai_card_intention.FireAttack=80
-- Slash/IronChain intentions are complete in event-intention.lua; the core
-- class dispatcher routes both NatureSlash classes to the common Slash policy.

-- Kept as a public helper even though the fixed ordinary-mode source has no
-- direct caller; the original-hegemony variant has a different signature.
function SmartAIView:searchForAnaleptic(slash,enemy)
    if query(self,"isFriend",enemy)
        or query(enemy,"hasSkills","zhenlie|mobilejxtpjinjiu")
        or query(enemy,"hasSkill","anxian") and query(enemy,"getHandcardNum")>0 and query(self,"getOverflow")<0
        or query(self.room,"getTurnCount")<=1 and self.role=="renegade" and query(self,"isLordHealthy") and query(self,"getOverflow")<2
        or query(self.player,"hasFlag","canshi") and query(self.player,"getHandcardNum")<3 then return end
    if not(query(enemy,"hasArmorEffect","SilverLion") and query(self.player,"hasWeapon","QinggangSword")) then
        local damage=query(self,"ajustDamage",self.player,enemy,2,slash)
        if damage==0 or damage==1 then return end
    end
    for _,wine in ipairs(query(self,"getCard","Analeptic",true)) do
        local skip=false
        if query(wine,"isKindOf","SkillCard") then
            skip=not known(nil,"Analeptic static availability") -- Not projected for a skill-card wine.
        end
        if not skip and query(wine,"getEffectiveId")~=query(slash,"getEffectiveId") and query(wine,"isAvailable",self.player) then
            local planned={}
            for _,card in ipairs(known(self.toUse,"planned cards")) do
                if query(card,"isKindOf","Slash") or query(card,"isKindOf","SkillCard") and query(card,"toString"):match("slash") then
                    planned[#planned+1]=query(card,"getEffectiveId")
                end
            end
            local residue=query(wine,"getTargetResidue",self.player)
            if not(residue<1 and planned[#planned]~=query(slash,"getEffectiveId") or residue>0 and residue<#planned) then
                local count=query(enemy,"getHandcardNum")
                if query(enemy,"hasFlag","dahe") or query(self.player,"hasSkill","tieji")
                    or query(self.player,"getCardCount")>4 and query(self.player,"hasWeapon","Axe")
                    or query(self,"canLiegong",enemy,self.player)
                    or count>=query(self.player,"getHp") and query(self.player,"hasSkill","kofliegong")
                    or (count>=query(self.player,"getHp") or count<=query(self.player,"getAttackRange")) and query(self.player,"hasSkill","liegong") then return wine end
                count=known(getKnownCard(enemy,self.player,"Jink",true,"he"),"known enemy Jink")
                if query(enemy,"isFemale") and query(self.player,"hasSkill","roulin")
                    or query(self.player,"isFemale") and query(enemy,"hasSkill","roulin")
                    or query(self.player,"hasSkill","wushuang") then if count<2 then return wine end end
                if count<1 or query(self,"getOverflow")>1 then return wine else return end
            end
        end
    end
end
function SmartAIView:useCardThunderSlash(...)
    local result = self:useCardSlash(...)
    if AIUnsupported.is(result) then error(result, 0) end
end
function SmartAIView:useCardFireSlash(...)
    local result = self:useCardSlash(...)
    if AIUnsupported.is(result) then error(result, 0) end
end
