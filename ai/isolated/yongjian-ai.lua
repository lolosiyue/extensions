-- Source: b6025acc ai/yongjian-ai.lua.
local known = AIValue.requireKnown

-- The donor's scoped values live on the viewer's own property and tags.
local own_scope={poison_use={"getPropertyValue","PoisonUse",""},tuixinzhifu_target={"getTag","yj_tuixinzhifu",""},
 caochuan_effect={"getTag","Caochuanjiejian",false},jinchan_use={"getTag","Jinchan",false}}
local function scope_value(self,key)
 local own=own_scope[key]
 if own then
  local value=self.player[own[1]](self.player,own[2])
  if value==nil then return own[3] end
  -- The donor reads these two as QVariant::toString.
  if type(own[3])=="string" then return tostring(value) end
  return value
 end
 local c=self:getDecisionContext().yongjian
 if type(c)~="table"then ai_unsupported("Yongjian context missing","yongjian")end
 return known(c[key],"scoped "..key)
end
-- Fulei room-tag counts and hasDefensiveHorse (equip
-- nullification/view-as) are not projected.
local function fact(self,key,index)
 if key=="card_is_present" then
  -- A gift card the viewer holds: its own card view says so.
  local card=self:getKnownCardById(tonumber(index))
  local gift=card and card._view.gift
  if type(gift)~="boolean" then ai_unsupported("Yongjian gift status is not projected",tostring(index)) end
  return gift
 end
 if key=="defensive_horse_zhanxiang" then
  -- Equipment is public; a view-as-equip skill leaves the armor basis (and this) unknown.
  local to=self.room:findPlayerByObjectName(index)
  if not to or type(to._view.active_armor_name)~="string" then
   ai_unsupported("Yongjian Zhanxiang basis is not projected",tostring(index))
  end
  local horse=to:getDefensiveHorse()
  return horse~=nil and horse:objectName()=="yj_zhanxiang"
 end
 ai_unsupported("Yongjian fact is not projected: "..key,"yongjian")
end
local function scope_player(self,key)
 local name=scope_value(self,key);if name==false or name==""then return nil end
 return known(self.room:findPlayerByObjectName(name),key)
end
local function scope_use(self,key)
 local row=scope_value(self,key);if row==false then return{}end
 if type(row)~="table"then ai_unsupported("Malformed Yongjian use: "..key,"yongjian")end
 local use={};for k,v in pairs(row)do use[k]=v end
 if type(row.card)=="table"then use.card=CardView.new(row.card);use.card._evaluation_candidate=row.card.evaluation_candidate end
 for _,k in ipairs({"from","to"})do
  if type(row[k])=="string"and row[k]~=""then use[k]=known(self.room:findPlayerByObjectName(row[k]),key.."."..k)end
 end
 return use
end
local function target_specified_history(self)
 local row=scope_value(self,"target_specified_use")
 if type(row)~="table" or row.known~=true then
  ai_unsupported("Latest legacy TargetSpecified history is not lawful for this viewer","yongjian.target_history")
 end
 local r=self.request
 if not r or r.kind~="skill_invoke" or not r.options or r.options.reason~="zd_zhungangshuo"
  or row.viewer~=self.player:objectName() or row.decision_id~=tostring(r.decision_id)
  or row.state_revision~=tostring(r.state_revision) then
  ai_unsupported("TargetSpecified history question is stale or mismatched","yongjian.target_history.scope")
 end
 -- Exact source-known absence is an ordinary nil dereference, not an optional
 -- absent value. This helper is called only after the positive-hand guard.
 if row.present==false then local absent;return absent:toCardUse()end
 if row.present~=true or row.from~=row.viewer or not AIValue.isList(row.nullified_list)then
  ai_unsupported("Malformed TargetSpecified history","yongjian.target_history.schema")
 end
 for _,name in ipairs(row.nullified_list)do
  if type(name)~="string"then ai_unsupported("Malformed nullification entry","yongjian.target_history.schema")end
 end
 return row
end
local function disclosed_card(self,id)
 local c=self:getChoiceCard(id)or self:getKnownCardById(id)
 return known(c,"disclosed card "..tostring(id))
end
local function disabled(self,id)
 local ids=self.disabled_ids
 if not ids then local value,present=self:getStrategyMemory("discard_disabled_ids");ids=present and value or{}end
 if not AIValue.isList(ids)then ai_unsupported("Discard cache malformed","yj_tuixinzhifu")end
 return table.contains(ids,id)
end
local function hidden_hand_choice(self,who)
 local sample=self:randomHandDiscardToken(who)
 if sample.empty or type(sample.disabled)~="boolean" or type(sample.selected_choice)~="table" then
  ai_unsupported("Tuixinzhifu selected hand receipt is unavailable","yj_tuixinzhifu")
 end
 return sample
end
local function public_random_card(self,who)
 local cards
 if who~=self.player and who:getHandcardNum()>0 then
  local row=self:getDecisionContext().yongjian_third_pass
  if type(row)~="table"or row.known~=true or row.target~=who:objectName()or not AIValue.isList(row.ordered_card_ids)then
   ai_unsupported("Tuixinzhifu third-pass ordered hand domain is not completely disclosed","yj_tuixinzhifu.third_pass")
  end
  cards=AIList.new({})
  local seen={}
  for _,id in ipairs(row.ordered_card_ids)do
   if type(id)~="number"or id<0 or id%1~=0 or seen[id]then
    ai_unsupported("Malformed disclosed third-pass domain","yj_tuixinzhifu.third_pass")
   end
   seen[id]=true;cards:append(disclosed_card(self,id))
  end
 else cards=who:getCards("hej")end
 if who==self.player then
  for _,c in ipairs(self:sortByKeepValue(cards))do local id=c:getKnownEffectiveId();if not disabled(self,id)then return id end end
  return -1
 end
 local ids,byid={},{}
 for _,c in ipairs(cards)do local id=c:getKnownEffectiveId();byid[id]=c;if not disabled(self,id)then ids[#ids+1]=id end end
 if #ids==0 then return -1 end
 local mr=math.random(1,#ids);local id=ids[mr]
 if byid[id]:isKindOf("SilverLion")and who:isWounded()and self:isEnemy(who)and who:hasArmorEffect("SilverLion")then
  if mr~=#ids then id=ids[mr+1]elseif mr>1 then id=ids[mr-1]end
 end
 return id
end
local function incompatible_jinhe(self,id)
 ai_unsupported("Fixed source zl_jinhe proposes one pile cost; native createCard produces a zero-cost SkillCard","zl_jinhe")
end
local function other_ag(self,to,ids)
 if #ids==0 then return -1 end
 if to==self.player then return self:askForAG(ids,false,"zl_zhulutianxia")end
 ai_unsupported("Zhulutianxia invokes another AI's private AG policy","Zhulutianxia")
end
local function other_poison(self,to,ids)
 if #ids==0 then return{}end
 if to==self.player then return self:poisonCards(ids)end
 ai_unsupported("Zhulutianxia requires another AI's poison-card policy","Zhulutianxia")
end
local function other_armor(self,to,c)
 if to==self.player then return self:evaluateArmor(c)end
 ai_unsupported("Zhulutianxia requires another AI's current armor evaluation and skill callbacks","Zhulutianxia")
end

function SmartAIView:useCardPoison(card,use)
    local recommend = self:targetRecommendScorer(card)
    if not table.contains(scope_value(self,"poison_use"):split(","),card:getLegacyStringKey())
    then return end
    self:sort(self.enemies)
    local lower_half = {}
    for i, ep in sgs.list(self.enemies) do
        if i > #self.enemies / 2 then lower_half[#lower_half + 1] = ep end
    end
    for _,ep in sgs.list(self:orderTargetsByRecommend(lower_half, recommend))do
        if self:cardTargetFilter(card, use.to, ep) then
            use.card = card
            use.to:append(ep)
        end
    end
    for _,ep in sgs.list(self:orderTargetsByRecommend(self:sort(self.room:getAlivePlayers(),nil,true), recommend))do
        if not self:isFriend(ep) and self:cardTargetFilter(card, use.to, ep) then
            use.card = card
            use.to:append(ep)
        end
    end
end
sgs.registerSkillCardType("Poison", "debuff")

sgs.ai_use_priority.Poison = 4.4
sgs.ai_keep_value.Poison = 4
sgs.ai_use_value.Poison = 1.7

--直接给【毒】设定为负面卡牌（无论任何情况）
--ai会优先将负面卡牌给对手，五谷选择牌时也不会优先选择这些牌
sgs.ai_poison_card.yj_poison = true

table.insert(sgs.ai_voluntary_give_skills,"yj_tuixinzhifu")

table.insert(sgs.ai_voluntary_give_skills,"zd_shengdongjixi")


sgs.ai_skill_discard.yj_stabs_slash = function(self,max,min)
    local to_cards = {}
    local cards = self.player:getCards("h")
    cards = self:sortByKeepValue(cards,nil,"j")
    for _,h in sgs.list(cards)do
        if #to_cards>=min then break end
        table.insert(to_cards,h:getKnownEffectiveId())
    end
    return to_cards
end

function SmartAIView:useCardChenhuodajie(card,use)
    local recommend = self:targetRecommendScorer(card)
    self:sort(self.enemies)
    local extraTarget = card:getTargetModExtra(self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,ep in sgs.list(self:orderTargetsByRecommend(self.enemies, recommend))do
        if isCurrent(use,ep) then continue end
        if self.player:canUse(card, ep)
        and self:isGoodTarget(ep, self.enemies, card) then
            use.card = card
            use.to:append(ep)
            if use.to:length()>extraTarget
            then return end
        end
    end
    for _,ep in sgs.list(self:orderTargetsByRecommend(self.friends_noself, recommend))do
        if isCurrent(use,ep) then continue end
        if self.player:canUse(card, ep)
        and self:needToLoseHp(ep, self.player, card) then
            use.card = card
            use.to:append(ep)
            if use.to:length()>extraTarget
            then return end
        end
    end
end
sgs.ai_use_priority.Chenhuodajie = 5.4
sgs.ai_keep_value.Chenhuodajie = 2
sgs.ai_use_value.Chenhuodajie = 3.7
sgs.ai_card_intention.Chenhuodajie = 44

sgs.ai_nullification.Chenhuodajie = function(self,trick,from,to,positive)
    return positive and self:isFriend(to) and not self:isFriend(from)
    and (to==self.player or self:isWeak(to))
end

sgs.ai_skill_cardask["yj_chenhuodajie0"] = function(self,data,pattern)
    local c = self:getKnownCardById(tonumber(pattern))
    if c then
        local effect = data:toCardEffect()
        local n = self:ajustDamage(effect.from, effect.to, 1, effect.card)
        if n==0 or n<2 and (self:isWeak() and isCard("Peach,Analeptic",c,self.player) or self:getKeepValue(c)>6 and c:isAvailable(self.player))
        then return "." end
        return pattern
    end
end

function SmartAIView:useCardGuaguliaodu(card,use)
    local recommend = self:targetRecommendScorer(card)
    self:sort(self.friends,"hp")
    local extraTarget = card:getTargetModExtra(self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,ep in sgs.list(self:orderTargetsByRecommend(self.friends, recommend))do
        if isCurrent(use,ep) then continue end
        if self.player:canUse(card, ep) then
            use.card = card
            use.to:append(ep)
            if use.to:length()>extraTarget
            then return end
        end
    end
end
sgs.registerSkillCardType("Guaguliaodu", "recover")
sgs.ai_use_priority.Guaguliaodu = 2.4
sgs.ai_keep_value.Guaguliaodu = 2.2
sgs.ai_use_value.Guaguliaodu = 4.7
sgs.ai_card_intention.Guaguliaodu = -33

sgs.ai_nullification.Guaguliaodu = function(self,trick,from,to,positive)
    if positive then
        return self:isEnemy(to) and to:isWounded()
        and (self:isWeak(to) or self:getCardsNum("Nullification")>1)
    else
        return self:isFriend(to) and to:isWounded()
        and (self:isWeak(to) or self:getCardsNum("Nullification")>1)
    end
end

sgs.ai_skill_cardask["yj_guaguliaodu0"] = function(self,data,pattern)
    return true
end

sgs.ai_skill_cardask["yj_yitianjian0"] = function(self,data,pattern)
    return true
end

sgs.ai_use_priority.Yitianjian = 3

function SmartAIView:useCardShushangkaihua(card,use)
    local n = #self:poisonCards("e")
    for _,c in sgs.list(self.player:getHandcards())do
        if self:wasPreviouslyPlannedCard(c)
        or self:getKeepValue(c)>7
        then else n = n+1 end
        if n>1 then use.card = card return end
    end
    if self:getPriorTurnUseCount()<2 and (self.player:getCardCount()>4 or self:getOverflow()>0) then
        use.card = card
    end
end
sgs.ai_use_priority.Shushangkaihua = 3.4
sgs.ai_keep_value.Shushangkaihua = 2.2
sgs.ai_use_value.Shushangkaihua = 4.7
sgs.ai_card_intention.Shushangkaihua = -22

sgs.ai_skill_discard.yj_shushangkaihua = function(self)
    local cards = self.player:getCards("h")
    cards = self:sortByCardNeed(cards,nil,"j")
    local discard = {}
    for i,c in sgs.list(cards)do
        if #discard<2 and self.player:hasEquip(c) and self:evaluateArmor(c)<-5
        then table.insert(discard,c:getKnownEffectiveId()) continue end
        if #cards/2>i and #discard<1 and c:isKindOf("EquipCard")
        then table.insert(discard,c:getKnownEffectiveId()) end
    end
    cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards,nil,"j")
    for i,c in sgs.list(cards)do
        if table.contains(discard,c:getKnownEffectiveId()) then continue end
        if #discard<2 then table.insert(discard,c:getKnownEffectiveId()) end
    end
    return discard
end

function SmartAIView:useCardTuixinzhifu(card,use)
    local recommend = self:targetRecommendScorer(card)
    self:sort(self.friends_noself,"hp")
    local extraTarget = card:getTargetModExtra(self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,p in sgs.list(self:orderTargetsByRecommend(self.friends_noself, recommend))do
        if isCurrent(use,p) or use.to:contains(p) then continue end
        if self:cardTargetFilter(card, {}, p)
        and self:doDisCard(p, "ej") then
            use.card = card
            use.to:append(p)
            if use.to:length()>extraTarget
            then return end
        end
    end
    self:sort(self.enemies,"hp")
    for _,p in sgs.list(self:orderTargetsByRecommend(self.enemies, recommend))do
        if isCurrent(use,p) or use.to:contains(p) then continue end
        if self:cardTargetFilter(card, {}, p)
        and self:doDisCard(p, "ej") then
            use.card = card
            use.to:append(p)
            if use.to:length()>extraTarget
            then return end
        end
    end
    for _,p in sgs.list(self:orderTargetsByRecommend(self.enemies, recommend))do
        if isCurrent(use,p) or use.to:contains(p) then continue end
        if self:cardTargetFilter(card, {}, p)
        and self:doDisCard(p, "hej") then
            use.card = card
            use.to:append(p)
            if use.to:length()>extraTarget
            then return end
        end
    end
    local tos = self.room:getAlivePlayers()
    tos = self:sort(tos,"card",true)
    for _,p in sgs.list(self:orderTargetsByRecommend(tos, recommend))do
        if isCurrent(use,p) or use.to:contains(p) then continue end
        if self:cardTargetFilter(card, {}, p)
        and p:getCardCount()>1 then
            use.card = card
            use.to:append(p)
            if use.to:length()>extraTarget
            then return end
        end
    end
end
sgs.registerSkillCardType("Tuixinzhifu", "decrease")
sgs.ai_use_priority.Tuixinzhifu = 5.4
sgs.ai_keep_value.Tuixinzhifu = 2.2
sgs.ai_use_value.Tuixinzhifu = 4.7

sgs.ai_skill_cardchosen.yj_tuixinzhifu = function(self,who)
    for _,c in sgs.list(who:getCards("ej"))do
        if self:doDisCard(who, c:getKnownEffectiveId(), true)
        then return c:getKnownEffectiveId() end
    end
    for i=1,who:getHandcardNum()do
        local sample = hidden_hand_choice(self,who)
        if sample.disabled then continue end
        return {kind="answer",random_card_choice=sample.selected_choice}
    end
    for i=1,99 do
        local id = public_random_card(self,who)
        if self:doDisCard(who, id, true)
        then return id end
    end
    return -1
end

sgs.ai_skill_discard.yj_tuixinzhifu = function(self,x,n)
    local to_cards = {}
    local target = scope_player(self,"tuixinzhifu_target")
    local cards = self.player:getHandcards()
    cards = self:sortByKeepValue(cards)
    for _,h in sgs.list(cards)do
        if #to_cards>=n then return to_cards end
        if table.contains(self:poisonCards(),h) and not self:isFriend(target)
        then table.insert(to_cards,h:getKnownEffectiveId()) end
    end
    for i,h in sgs.list(cards)do
        if #to_cards>=n then return to_cards end
        if table.contains(to_cards,h:getKnownEffectiveId()) then continue end
        if i>=#cards/2 and self:isFriend(target)
        then table.insert(to_cards,h:getKnownEffectiveId()) end
    end
    for _,h in sgs.list(cards)do
        if #to_cards>=n then return to_cards end
        if table.contains(to_cards,h:getKnownEffectiveId()) then continue end
        table.insert(to_cards,h:getKnownEffectiveId())
    end
end

sgs.ai_nullification.Tuixinzhifu = function(self,trick,from,to,positive)
    local n = self:getCardsNum("Nullification")
    if n>1 and (to:hasEquip() or to:getJudgingArea():length()>0) then
        if positive then
            return self:isFriend(to)
            and self:isEnemy(from)
        else
            return self:isEnemy(to)
            and self:isEnemy(from)
        end
    elseif to:getCardCount(true, true)>0
    and (to:getArmor() or to:getDefensiveHorse() or to:getHandcardNum()<2 or to:getJudgingArea():length()>0) then
        if positive then
            return self:isFriend(to)
            and self:isEnemy(from)
        else
            return self:isEnemy(to)
            and self:isEnemy(from)
        end
    end
end

function SmartAIView:useCardNvzhuang(card,use)
    return true
end

function SmartAIView:useCardYinfengyi(card,use)
    return true
end

function SmartAIView:useCardZheji(card,use)
    return true
end

function SmartAIView:useCardQixingbaodao(card,use)
    if self.player:getEquips():isEmpty() then use.card = nil end
    if self.player:getEquips():length()<=self.player:getJudgingArea():length()
    then use.card = card end
    return true
end

function SmartAIView:useCardOffensiveHorse(card,use)
    if card:objectName()=="yj_numa"
    then return true end
end

--给在装备区特定的牌设定为负面卡牌；需要设定的值小于-5
--ai会优先将负面装备卸掉，ai队友也会优先帮你拆顺掉这些装备
--同时对手也不会优先去卸掉你的这些装备
sgs.ai_armor_value.yj_yinfengyi = -9
sgs.ai_armor_value.yj_zheji = -7.6
sgs.ai_armor_value.yj_numa = -7
sgs.ai_armor_value.yj_nvzhuang = -8

ai_fill_skill.yj_xinge = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getHandcards()
    self.yjxg_to = nil
    self:sort(self.enemies,"hp")
    self:sort(self.friends_noself,"hp")
    local pcs = self:poisonCards(cards)
    for _,c in sgs.list(self:sortByKeepValue(cards))do
        if table.contains(pcs,c)
        then self.yjxg_to = self.enemies[1]
        elseif c:isKindOf("Slash") then
            if self:wasPreviouslyPlannedCard(c)
            or self.player:getHandcardNum()<2 then continue end
            self.yjxg_to = self.friends_noself[1]
        elseif c:isKindOf("Jink") then
            if self:getCardsNum("Jink", "h")<1 then continue end
            self.yjxg_to = self.friends_noself[1]
        elseif c:isKindOf("Peach") then
            if self:isWeak() and self:wasPreviouslyPlannedCard(c) then continue end
            self.yjxg_to = self.friends_noself[1]
        elseif self.player:getHandcardNum()>self.player:getMaxCards()
        then self.yjxg_to = self.friends_noself[1] end
        if not self.yjxg_to then continue end
        return self:bindSkillCard("yj_xinge", {c:getKnownEffectiveId()}, request, nil, "#yj_xingecard")
    end
    local c,p = self:getCardNeedPlayer()
    if c and p then
        self.yjxg_to = p
        return self:bindSkillCard("yj_xinge", {c:getKnownEffectiveId()}, request, nil, "#yj_xingecard")
    end
end

ai_card_use["#yj_xingecard"] = function(self, card, use, request)
    if self.yjxg_to:isAlive() then
        use.card = card
        use.to:append(self.yjxg_to)
    end
end

sgs.ai_use_value.yj_xingecard = 5.4
sgs.ai_use_priority.yj_xingecard = 3.8

sgs.ai_armor_value.zl_yinfengjia = -8
sgs.ai_armor_value.zl_wufengjian = -6

sgs.ai_poison_card.zl_wufengjian = function(self,c,player)
    if player:hasEquip(c) then return getCardsNum("Slash",player,self.player)>0 end
end

sgs.ai_poison_card.zl_jinhe = function(self,c,player)
    if player:hasEquip(c) then return player:getHandcardNum()<1 end
end

sgs.ai_poison_card.zl_nvzhuang = function(self,c,player)
    if not player:hasEquip(c) then return player:isMale() end
end

sgs.ai_poison_card.zl_numa = function(self,c,player)
    return not player:hasEquip(c) and player:hasEquip()
end

function SmartAIView:useCardCaochuanjiejian(card,use)
    local ce = scope_use(self,"caochuan_effect")
    if ce and ce.card and not known(ce.nullified,"Caochuanjiejian nullified")
    and self:hasTrickEffective(ce.card, ce.to, ce.from)
    and not self:canDamageHp(ce.from, ce.card, ce.to)
    then use.card = card end
end
sgs.ai_keep_value.Caochuanjiejian = 9.6
sgs.ai_use_value.Caochuanjiejian = 6.9
sgs.ai_use_priority.Caochuanjiejian = 6.6

sgs.ai_nullification.Caochuanjiejian = function(self,trick,from,to,positive,null_num)
    if positive then
        return self:isEnemy(from)
        and (self:isWeak(from) or null_num>1)
    else
        return self:isFriend(from)
        and self:isWeak(from)
    end
end

function SmartAIView:useCardJiejiaguitian(card,use)
    local recommend = self:targetRecommendScorer(card)
    self:sort(self.friends,"hp")
    local extraTarget = card:getTargetModExtra(self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,ep in sgs.list(self:orderTargetsByRecommend(self.friends, recommend))do
        if isCurrent(use,ep) then continue end
        if self:cardTargetFilter(card, {}, ep)
        and #self:poisonCards("e",ep)>=ep:getEquips():length()/2 then
            use.card = card
            use.to:append(ep)
            if use.to:length()>extraTarget
            then return end
        end
    end
    local function equipValue(p)
        local x = p:getEquips():length()
        local pc = self:poisonCards("e",p)
        for _,e in sgs.list(p:getEquips())do
            if table.contains(pc,e)
            then x = x-2 continue end
            if e:isKindOf("Weapon")
            or e:isKindOf("OffensiveHorse") then x = x+2
            elseif e:isKindOf("Armor") then x = x+4
            elseif e:isKindOf("DefensiveHorse") then x = x+3
            else x = x+1+p:getPile("wooden_ox"):length() end
        end
        return x
    end
    local function func(a,b)
        return equipValue(a)>equipValue(b)
    end
    table.sort(self.enemies,func)
    for _,ep in sgs.list(self:orderTargetsByRecommend(self.enemies, recommend))do
        if isCurrent(use,ep) then continue end
        if self:cardTargetFilter(card, {}, ep)
        and #self:poisonCards("e",ep)<=ep:getEquips():length()/2 then
            use.card = card
            use.to:append(ep)
            if use.to:length()>extraTarget
            then return end
        end
    end
    local tos = self.room:getAlivePlayers()
    tos = self:sort(tos,"card",true)
    table.sort(tos,func)
    for _,ep in sgs.list(self:orderTargetsByRecommend(tos, recommend))do
        if isCurrent(use,ep) then continue end
        if self:cardTargetFilter(card, {}, ep)
        and #self:poisonCards("e",ep)<ep:getEquips():length()/2
        and not self:isFriend(ep)
        then
            use.card = card
            use.to:append(ep)
            if use.to:length()>extraTarget
            then return end
        end
    end
end
sgs.registerSkillCardType("Jiejiaguitian", "decrease")
sgs.ai_use_priority.Jiejiaguitian = 4.4
sgs.ai_keep_value.Jiejiaguitian = 1.2
sgs.ai_use_value.Jiejiaguitian = 2.7
sgs.ai_card_intention.Jiejiaguitian = function(self,card,from,tos)
    for _,to in sgs.list(tos)do
        local pc,e = self:poisonCards("e",to),to:getEquips():length()/2
        local n = 0
        if #pc>e then n = 33 elseif #pc<=e then n = -22 end
        self:updateIntention(from,to,n)
    end
end

function SmartAIView:useCardZhulutianxia(card,use)
    self:useCardAmazingGrace(card,use)
end
sgs.ai_use_priority.Zhulutianxia = 2.4
sgs.ai_keep_value.Zhulutianxia = 1.2
sgs.ai_use_value.Zhulutianxia = 4.7

sgs.ai_nullification.Zhulutianxia = function(self,trick,from,to,positive,null_num)
    if positive then
        local ids = scope_value(self,"zhulutianxia_ids")
        if self:isEnemy(to) then
            local NP = to:getNextAlive()
            if not self:isEnemy(NP) then
                for _,id in sgs.list(ids)do
                    local c = disclosed_card(self,id)
                    if isCard("Crossbow",c,NP)
                    and to:hasEquipArea(0) then
                        for _,enemy in sgs.list(self.enemies)do
                            if getCardsNum("Slash",enemy,self.player)>1 then
                                local slash = self:getEvaluationCard("slash")
                                for _,friend in sgs.list(self.friends)do
                                    if enemy:distanceTo(friend)==1
                                    and self:slashIsEffective(slash, friend, enemy)
                                    then return true end
                                end
                            end
                        end
                    end
                end
            end
        elseif self:isFriend(to) then
            local c = other_ag(self,to,ids)
            c = c and c>=0 and disclosed_card(self,c)or nil
            local pc = other_poison(self,to,ids)
            if table.contains(pc,c) or other_armor(self,to,c)<-5
            then return self:isWeak(to) or null_num>1 end
        end
    else
    end
end

sgs.ai_skill_askforag.zl_zhulutianxia = function(self,card_ids)
    local pc = self:poisonCards(card_ids)
    local cs = {}
    for _,id in sgs.list(card_ids)do
        local c = disclosed_card(self,id)
        c = self:getAcquiredCardEvaluation(c)or c
        local n = c:getEquipSlot()
        if self.player:hasEquipArea(n)
        then table.insert(cs,c) end
    end
    self:sortByUseValue(cs)
    for _,c in sgs.list(cs)do
        if table.contains(pc,c)
        or self:evaluateArmor(c)<-5
        then continue end
        local n = c:getEquipSlot()
        n = self.player:getEquip(n)
        if n and self:evaluateArmor(n)>-5
        then continue end
        if n and self:evaluateArmor(n)<-5
        then return c:getKnownEffectiveId() end
    end
    for _,c in sgs.list(cs)do
        if table.contains(pc,c)
        or self:evaluateArmor(c)<-5
        then continue end
        local n = c:getEquipSlot()
        n = self.player:getEquip(n)
        if n and self:evaluateArmor(n)>-5
        then continue end
        if self:evaluateAcquiredCard(c).card
        then return c:getKnownEffectiveId() end
    end
    for _,c in sgs.list(cs)do
        if table.contains(pc,c)
        or self:evaluateArmor(c)<-5
        then continue end
        if self.player:getPhase()<=sgs.Player_Play
        and self:evaluateAcquiredCard(c).card
        then return c:getKnownEffectiveId() end
    end
    for _,c in sgs.list(cs)do
        if table.contains(pc,c)
        or self:evaluateArmor(c)<-5
        then continue end
        local n = c:getEquipSlot()
        n = self.player:getEquip(n)
        if n and self:evaluateArmor(n)>-5
        then continue end
        return c:getKnownEffectiveId()
    end
    for _,c in sgs.list(cs)do
        if table.contains(pc,c)
        or self:evaluateArmor(c)<-5
        then continue end
        return c:getKnownEffectiveId()
    end
    return #cs>0 and cs[1]:getEffectiveId()
end

sgs.ai_target_revises.zl_yexingyi = function(to,card)
    if card:isKindOf("TrickCard") and card:isBlack()
    then return true end
end

ai_skill_invoke.zl_yajiaoqiang = true
sgs.ai_armor_value.zl_yajiaoqiang = 2
sgs.ai_card_priority.zl_yajiaoqiang = function(self,card)
    if self.player:getPhase()==sgs.Player_NotActive
    and card:isBlack() and self.player:getStrategyMark("zl_yajiaoqiang-Clear")<1
    then return 3 end
end

ai_fill_skill.zl_jinhe = function(self, options, request)
    local inclusive = options and options.inclusive

    local zl_li = self.player:getPile("zl_li")
    if zl_li:length()>0 and #self.enemies>0
    and (self.player:getHandcardNum()<2 or self.player:getHandcardNum()>self.player:getMaxCards())
    then return incompatible_jinhe(self,zl_li:at(0)) end
end

ai_card_use["#zl_jinheCard"] = function(self, card, use, request)
    use.card = card
end

sgs.ai_use_value.zl_jinheCard = -5.4
sgs.ai_use_priority.zl_jinheCard = -4.8



ai_skill_invoke.zd_xunzhi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (not self:isWeak() and self:getOverflow()>1) or false
end

ai_fill_skill.zd_fenyue = function(self, options, request)
    local inclusive = options and options.inclusive

    return self:legacySkillSeed("zd_fenyue", "#zd_fenyueCard", request)
end

ai_card_use["#zd_fenyueCard"] = function(self, card, use, request)
    local mc = self:getMaxCard()
    if mc then
        self:sort(self.enemies,"handcard")
        for _,p in sgs.list(self.enemies)do
            local emc = self:getMaxCard(p)
            if emc and emc:getNumber()<mc:getNumber()
            then
                use.card = self:bindSkillCard("zd_fenyue", {mc:getKnownEffectiveId()}, request, nil, "#zd_fenyueCard")
                use.to:append(p)
                return
            end
        end
    end
end

sgs.ai_use_value.zd_fenyueCard = 3.4
sgs.ai_use_priority.zd_fenyueCard = 5.2

ai_skill_choice.zd_fenyue = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local target = data:toPlayer()
    local items = choices:split("+")
    if table.contains(items,"zd_fenyue2") then
        local d = self:evaluateSkillCard("_zd_fenyue", "slash", {})
        local use = AIUsePlan.new()
        use.card = d
        use.from = self.player
        if self:canCanmou(target,use)
        then
            return ai_choice_result(("zd_fenyue2"), options)
        end
    end
    if target:getHandcardNum()>0 then
        return ai_choice_result(("zd_fenyue1"), options)
    end

    return ai_choice_result(nil, options)
end

sgs.ai_skill_playerchosen.zd_dongcha = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
        if self:doDisCard(target, "ej", true)
        then return target end
    end
end


function SmartAIView:useCardShengdongjixi(card,use)
    local recommend = self:targetRecommendScorer(card)
    local receive = self:targetRecommendScorer(card, self.player, {notDraw = true}, "draw")
    if self.player:getHandcardNum()<2 then return end
    local toList = self:sort(self.room:getAlivePlayers(),"handcard",true)
    local fromList = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    local extraTarget = card:getTargetModExtra(self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    extraTarget = extraTarget*2
    for _,enemy in ipairs(self:orderTargetsByRecommend(fromList, recommend))do
        if isCurrent(use,enemy) or use.to:contains(enemy) then continue end
        if self:cardTargetFilter(card, {}, enemy) and self:objectiveLevel(enemy)>=0
        and not(enemy:hasEquip() and self:loseEquipEffect(enemy) or enemy:hasSkill("tuntian+zaoxian"))
        and #self:poisonCards("he",enemy)<1
        and enemy:getCardCount()>0 then
            for _,p in ipairs(self:orderTargetsByRecommend(toList, receive))do
                if enemy~=p and (p~=self.player or enemy:getCardCount()>0) and self:isFriend(p) then
                    use.card = card
                    use.to:append(enemy)
                    use.to:append(p)
                    if use.to:length()>extraTarget
                    then return end
                    break
                end
            end
        end
    end
    for _,friend in ipairs(self:orderTargetsByRecommend(fromList, recommend))do
        if isCurrent(use,friend) or use.to:contains(friend) then continue end
        if self:cardTargetFilter(card, {}, friend) and self:objectiveLevel(friend)<0
        and #self:poisonCards("h",friend)>0 then
            for _,enemy in ipairs(self:orderTargetsByRecommend(toList, receive))do
                if enemy~=friend and (p~=self.player or friend:getCardCount()>0)
                and self:objectiveLevel(enemy)>1 then
                    use.card = card
                    use.to:append(friend)
                    use.to:append(enemy)
                    if use.to:length()>extraTarget
                    then return end
                    break
                end
            end
        end
    end
    for _,friend in ipairs(self:orderTargetsByRecommend(fromList, recommend))do
        if isCurrent(use,friend) or use.to:contains(friend) then continue end
        if self:cardTargetFilter(card, {}, friend) and self:objectiveLevel(friend)<0
        and #self:poisonCards("e",friend)>0 then
            for _,p in sgs.list(self:orderTargetsByRecommend(self.room:getAlivePlayers(), receive))do
                if p~=friend and (p~=self.player or friend:getCardCount()>0)
                and self:objectiveLevel(p)<=0  then
                    use.card = card
                    use.to:append(friend)
                    use.to:append(p)
                    if use.to:length()>extraTarget
                    then return end
                    break
                end
            end
        end
    end
    for _,friend in ipairs(self:orderTargetsByRecommend(fromList, recommend))do
        if isCurrent(use,friend) or use.to:contains(friend) then continue end
        if self:cardTargetFilter(card, {}, friend) and self:objectiveLevel(friend)<=0
        and #self:poisonCards("h",friend)<1 then
            for _,p in ipairs(self:orderTargetsByRecommend(toList, receive))do
                if p~=friend and (p~=self.player or friend:getCardCount()>0)
                and self:objectiveLevel(p)<0 then
                    use.card = card
                    use.to:append(friend)
                    use.to:append(p)
                    if use.to:length()>extraTarget
                    then return end
                    break
                end
            end
        end
    end
end
sgs.registerSkillCardType("Shengdongjixi", "decrease")

sgs.ai_use_value.Shengdongjixi = 5.8
sgs.ai_use_priority.Shengdongjixi = 4.75
sgs.ai_keep_value.Shengdongjixi = 3.40

sgs.ai_nullification.Shengdongjixi = function(self,trick,from,to,positive,null_num)
    if positive then
        if self:isEnemy(from) and (self:isFriend(to) or self:isEnemy(to))
        and (null_num>1 or self:isWeak(to) or to==self.player)
        then return true end
    else

    end
end

sgs.ai_skill_playerchosen.zd_shengdongjixi = function(self,players)
    local destlist = self:sort(players)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        and self:canDraw(target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not self:isEnemy(target)
        and self:canDraw(target)
        then return target end
    end
    return destlist[#destlist]
end


function SmartAIView:useCardCaomujiebing(card,use)
    local recommend = self:targetRecommendScorer(card)
    self:sort(self.enemies,"hp",true)
    for _,ep in sgs.list(self:orderTargetsByRecommend(self.enemies, recommend))do
        if isCurrent(use,ep) then continue end
        if self:cardTargetFilter(card, {}, ep)
        and not ep:containsTrick("supply_shortage") then
            use.card = card
            use.to:append(ep)
            return
        end
    end
    for _,ep in sgs.list(self:orderTargetsByRecommend(self.enemies, recommend))do
        if isCurrent(use,ep) then continue end
        if self:cardTargetFilter(card, {}, ep) then
            use.card = card
            use.to:append(ep)
            return
        end
    end
end
sgs.registerSkillCardType("Caomujiebing", "debuff")
sgs.ai_use_priority.Caomujiebing = 0.4
sgs.ai_keep_value.Caomujiebing = 2
sgs.ai_use_value.Caomujiebing = 5.7
sgs.ai_card_intention.Caomujiebing = 66
sgs.ai_judgestring.zd_caomujiebing = ".|club"

sgs.ai_nullification.Caomujiebing = function(self,trick,from,to,positive,null_num)
    if positive then
        if to==self.player
        or self:isFriend(to) and (null_num>1 or self:isWeak(to))
        then return true end
    else
        if self:isEnemy(to)
        and (null_num>1 or self:isWeak(to))
        then return true end
    end
end

function SmartAIView:useCardZengbingjianzao(card,use)
    local recommend = self:targetRecommendScorer(card)
    self:sort(self.friends,nil,true)
    local extraTarget = card:getTargetModExtra(self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,fp in sgs.list(self:orderTargetsByRecommend(self.friends, recommend))do
        if isCurrent(use,fp) or use.to:contains(fp) then continue end
        if self:cardTargetFilter(card, {}, fp)
        and self:canDraw(fp) and self:isWeak(fp) then
            use.card = card
            use.to:append(fp)
            if use.to:length()>extraTarget
            then return end
        end
    end
    if recommend(self.player, 0) ~= nil and not isCurrent(use,self.player) and self:getCardsNum("EquipCard,TrickCard", "he")>1 then
        if CanToCard(card,self.player,self.player) and not use.to:contains(self.player) then
            use.card = card
            use.to:append(self.player)
            if use.to:length()>extraTarget
            then return end
        end
    end
    self:sort(self.friends)
    for _,fp in sgs.list(self:orderTargetsByRecommend(self.friends, recommend))do
        if isCurrent(use,fp) or use.to:contains(fp) then continue end
        if self:cardTargetFilter(card, {}, fp)
        and self:canDraw(fp) then
            use.card = card
            use.to:append(fp)
            if use.to:length()>extraTarget
            then return end
        end
    end
end
sgs.registerSkillCardType("Zengbingjianzao", "draw")
sgs.ai_use_priority.Zengbingjianzao = 9.4
sgs.ai_keep_value.Zengbingjianzao = 6
sgs.ai_use_value.Zengbingjianzao = 5.7
sgs.ai_card_intention.Zengbingjianzao = -66

sgs.ai_nullification.Zengbingjianzao = function(self,trick,from,to,positive,null_num)
    if positive then
        if self:isEnemy(to)
        and (null_num>1 or self:isWeak(to))
        then return true end
    else
        if to==self.player
        or self:isFriend(to) and (null_num>1 or self:isWeak(to))
        then return true end
    end
end

ai_skill_use["@@Zengbing!"] = function(self, prompt, request)
    for _,h in sgs.list(self:sortByKeepValue(self.player:getCards("he"),nil,"j"))do
        if h:getTypeId()<2 then continue end
        return "#ZengbingCard:"..h:getKnownId()..":"
    end
end

function SmartAIView:useCardQijiayebing(card,use)
    local recommend = self:targetRecommendScorer(card)
    self:sort(self.enemies,"equip",true)
    local extraTarget = card:getTargetModExtra(self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,ep in sgs.list(self:orderTargetsByRecommend(self.enemies, recommend))do
        if isCurrent(use,ep) then continue end
        if self.player:canUse(card, ep) and not use.to:contains(ep)
        and (ep:getTreasure()==nil or ep:getEquips():length()>1)
        and ep:getEquips():length()/2>#self:poisonCards("e",ep)
        and self:isWeak(ep) then
            use.card = card
            use.to:append(ep)
            if use.to:length()>extraTarget
            then return end
        end
    end
    for _,ep in sgs.list(self:orderTargetsByRecommend(self.enemies, recommend))do
        if isCurrent(use,ep) then continue end
        if self.player:canUse(card, ep) and not use.to:contains(ep)
        and (ep:getTreasure()==nil or ep:getEquips():length()>1)
        and ep:getEquips():length()/2>#self:poisonCards("e",ep) then
            use.card = card
            use.to:append(ep)
            if use.to:length()>extraTarget
            then return end
        end
    end
end
sgs.registerSkillCardType("Qijiayebing", "decrease")
sgs.ai_use_priority.Qijiayebing = 8.4
sgs.ai_keep_value.Qijiayebing = 3
sgs.ai_use_value.Qijiayebing = 5.7
sgs.ai_card_intention.Qijiayebing = 99

ai_skill_choice.zd_qijiayebing = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    if self:getCardsNum("Weapon,OffensiveHorse", "he")>self:getCardsNum("Armor,DefensiveHorse", "he")
    then return ai_choice_result(("Qijia2"), options) end
    return ai_choice_result(("Qijia1"), options)
end

sgs.ai_nullification.Qijiayebing = function(self,trick,from,to,positive,null_num)
    if positive then
        if self:isFriend(to)
        and (null_num>1 or self:isWeak(to) or to==self.player)
        then return true end
    else
        if self:isEnemy(to) and (null_num>1 or self:isWeak(to))
        then return true end
    end
end

ai_skill_use["Jinchan0"] = function(self, prompt, request)
    local use = scope_use(self,"jinchan_use")
    if use.card:isDamageCard() or self:isEnemy(use.from) and not use.card:isKindOf("GlobalEffect") then
        if table.contains(use.nullified_list,self.player:objectName())
        or not self:hasTrickEffective(use.card, self.player, use.from)
        or table.contains(use.nullified_list,"_ALL_TARGETS") then return end
        for _,h in sgs.list(self:getCard("Jinchantuoqiao",true))do
            return h:getLegacyStringKey()
        end
    end
end

sgs.ai_nullification.Jinchantuoqiao = function(self,trick,from,to,positive,null_num)
    if positive then
        if self:isEnemy(from)
        and (null_num>1 or self:isWeak(from))
        then return true end
    else
        if from==self.player
        or self:isFriend(from) and (null_num>1 or self:isWeak(from))
        then return true end
    end
end

sgs.ai_keep_value.Jinchantuoqiao = 2
sgs.ai_use_value.Jinchantuoqiao = 9.7
sgs.ai_card_intention.Jinchantuoqiao = -99

function SmartAIView:useCardFulei(card,use)
    if self:willUseLightning(card)
    then use.card = card end
end
sgs.ai_use_priority.Fulei = -4
sgs.ai_keep_value.Fulei = 1
sgs.ai_use_value.Fulei = 1.7
sgs.ai_card_intention.Fulei = 77

sgs.ai_judgestring.zd_fulei = {".|spade",false}

sgs.ai_poison_card.zd_fulei = function(self,c,owner)
    local n = fact(self,"fulei_counts",c:getLegacyStringKey())
    if self:isFriend(owner) or #self.friends_noself>0 and not self:isEnemy(owner)
    then return n>=owner:getHp() end
end

sgs.ai_view_as.zd_lanyinjia = function(card,player,card_place,class_name)
    if card_place==sgs.Player_PlaceHand and class_name=="Jink" then
        return "jink:zd_lanyinjia[no_suit:0]="..card:getLegacyStringKey()
    end
end

ai_skill_invoke.zd_zhungangshuo = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    if target and target:getHandcardNum()>0 then
        local use = target_specified_history(self)
        if table.contains(use.nullified_list,target:objectName())
        or table.contains(use.nullified_list,"_ALL_TARGETS")
        then return (false) or false end
        if type(self.doDisCard)~="function"then ai_unsupported("doDisCard provider missing","yongjian.target_history")end
        local result=self:doDisCard(target,"h")
        if AIUnsupported.is(result)then error(result,0)end
        return (result) or false -- the fixed source may return nil when discard is unavailable
    end
    return false

end



function SmartAIView:useCardLuanwu(card,use)
    if #self.enemies>#self.friends_noself
    or self:isWeak(self.enemies)
    then use.card = card end
end
sgs.ai_use_priority.Luanwu = 4
sgs.ai_keep_value.Luanwu = 1
sgs.ai_use_value.Luanwu = 1.7

function SmartAIView:useCardDouzhuanxingyi(card,use)
    local recommend = self:targetRecommendScorer(card)
    local extraTarget = card:getTargetModExtra(self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,ep in sgs.list(self:orderTargetsByRecommend(self.enemies, recommend))do
        if isCurrent(use,ep) then continue end
        if self.player:canUse(card, ep)
        and not use.to:contains(ep)
        and ep:getHp()>self.player:getHp()
        and self.player:isWounded()
        and self:isWeak(ep) then
            use.card = card
            use.to:append(ep)
            if use.to:length()>extraTarget
            then return end
        end
    end
    for _,ep in sgs.list(self:orderTargetsByRecommend(self.enemies, recommend))do
        if isCurrent(use,ep) then continue end
        if self.player:canUse(card, ep)
        and not use.to:contains(ep)
        and ep:getHp()>=self.player:getHp()
        and self.player:isWounded()
        and self:isWeak(ep) then
            use.card = card
            use.to:append(ep)
            if use.to:length()>extraTarget
            then return end
        end
    end
end
sgs.registerSkillCardType("Douzhuanxingyi", "debuff")
sgs.ai_use_priority.Douzhuanxingyi = 4.5
sgs.ai_keep_value.Douzhuanxingyi = 1
sgs.ai_use_value.Douzhuanxingyi = 1.7

function SmartAIView:useCardLidaitaojing(card,use)
    local recommend = self:targetRecommendScorer(card)
    local extraTarget = card:getTargetModExtra(self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,ep in sgs.list(self:orderTargetsByRecommend(self.enemies, recommend))do
        if isCurrent(use,ep) then continue end
        if self.player:canUse(card, ep) and not use.to:contains(ep)
        and ep:getHandcardNum()>self.player:getHandcardNum()
        and self:isWeak(ep) then
            use.card = card
            use.to:append(ep)
            if use.to:length()>extraTarget
            then return end
        end
    end
    for _,ep in sgs.list(self:orderTargetsByRecommend(self.enemies, recommend))do
        if isCurrent(use,ep) then continue end
        if self.player:canUse(card, ep) and not use.to:contains(ep)
        and ep:getHandcardNum()>=self.player:getHandcardNum() then
            use.card = card
            use.to:append(ep)
            if use.to:length()>extraTarget
            then return end
        end
    end
end
sgs.registerSkillCardType("Lidaitaojing", "debuff")
sgs.ai_use_priority.Lidaitaojing = 5.5
sgs.ai_keep_value.Lidaitaojing = 3
sgs.ai_use_value.Lidaitaojing = 1.7

function SmartAIView:useCardToulianghuanzhu(card,use)
    for _,ep in sgs.list(self.enemies)do
        if ep:getEquips():length()>self.player:getEquips():length() then
            use.card = card
            break
        end
    end
end
sgs.ai_use_priority.Toulianghuanzhu = 3.5
sgs.ai_keep_value.Toulianghuanzhu = 2
sgs.ai_use_value.Toulianghuanzhu = 1.7









function SmartAIView:AlPresentCardTo(c,enemie)
    local tos = enemie and self.enemies or self.friends_noself
    self:sort(tos,nil,enemie)
    for _,to in sgs.list(tos)do
        if math.random()<0.8 and fact(self,"defensive_horse_zhanxiang",to:objectName()) then continue end
        if c:isKindOf("EquipCard") then
            local e = c:getEquipSlot()
            if to:hasEquipArea(e) then else continue end
            e = to:getEquip(e)
            if e then
                e = self:evaluateArmor(e, to)
                if e<=-5 and enemie
                then continue end
            end
        elseif hasManjuanEffect(to)
        or not enemie and not self:canDraw(to)
        then continue end
        if c:isKindOf("Qixingbaodao") then
            if enemie and to:getEquips():isEmpty() then continue end
            if not enemie and to:getEquips():length()>to:getJudgingArea():length() then continue end
        end
        if c:objectName()=="zl_numa"
        and to:getEquips():length()<2
        then continue end
        if c:isKindOf("Poison") then
            if enemie and to:getTreasure()
            and to:getTreasure():isKindOf("Xinge") then continue end
        end
        if c:isKindOf("Nvzhuang") then
            if to:isMale() then else continue end
            if c:objectName()=="zl_nvzhuang" and to:getCardCount()<1 then continue end
        end
        return to
    end
    if enemie then
        tos = self.room:getOtherPlayers(self.player)
        self:sort(tos,nil,enemie)
        for _,to in sgs.list(tos)do
            if math.random()<0.8 and fact(self,"defensive_horse_zhanxiang",to:objectName()) or self:isFriend(to) then continue end
            if c:isKindOf("EquipCard") then
                local e = c:getEquipSlot()
                if to:hasEquipArea(e) then else continue end
                e = to:getEquip(e)
                if e then
                    e = self:evaluateArmor(e, to)
                    if e<=-5 and enemie
                    then continue end
                end
            elseif hasManjuanEffect(to)
            and not(enemie or self:canDraw(to))
            then continue end
            if c:isKindOf("Qixingbaodao") then
                if enemie and to:getEquips():isEmpty() then continue end
                if not enemie and to:getEquips():length()>to:getJudgingArea():length() then continue end
            end
            if c:objectName()=="zl_numa"
            and to:getEquips():length()<2
            then continue end
            if c:isKindOf("Poison") then
                if enemie and to:getTreasure()
                and to:getTreasure():isKindOf("Xinge") then continue end
            end
            if c:isKindOf("Nvzhuang") then
                if to:isMale() then else continue end
                if c:objectName()=="zl_nvzhuang" and to:getCardCount()<1 then continue end
            end
            return to
        end
    end
end

ai_fill_skill.yj_zhengyu = function(self, options, request)
    local inclusive = options and options.inclusive

    self:setPriorityValue("yj_zhengyuCard",0.8,"yj_zhengyu")
    self.yjzy_to = nil
    for _,c in sgs.list(self:sortByKeepValue(self.player:getHandcards()))do
        if fact(self,"card_is_present",tostring(c:getKnownId())) then
            if c:isKindOf("Slash") then
                if self:wasPreviouslyPlannedCard(c)
                or self:getCardsNum("Slash")<2 and self:getOverflow()<1
                then continue end
                self.yjzy_to = self:AlPresentCardTo(c)
            elseif c:isKindOf("Jink") then
                if self:getCardsNum("Jink", "h")<1 then continue end
                self.yjzy_to = self:AlPresentCardTo(c)
            elseif c:isKindOf("Peach") then
                if self:getCardsNum("Peach")<2
                and self:wasPreviouslyPlannedCard(c)
                then continue end
                self.yjzy_to = self:AlPresentCardTo(c)
            elseif c:isKindOf("Poison") then
                local can = self:isWeak() and math.random()<0.97
                local n = self:getOverflow()
                if n>0 then
                    n = self:askForDiscard("Poison",n,n,false,false)
                    if table.contains(n,c:getKnownId()) then can = false end
                end
                if can then continue end
                if self.player:hasArmorEffect("yj_yinfengyi")
                and (self.player:getHp()<4 or self.player:getMaxCards()>=self.player:getHandcardNum()/2)
                and math.random()<0.9 then continue end
                self.yjzy_to = self:AlPresentCardTo(c,true)
                self:setPriorityValue("yj_zhengyuCard",0.8,"yj_zhengyu")
            elseif c:isKindOf("Qixingbaodao")
            then self.yjzy_to = self:AlPresentCardTo(c,true) or self:AlPresentCardTo(c)
            elseif c:isKindOf("EquipCard") then
                if self:wasPreviouslyPlannedCard(c) then continue end
                local enemie = sgs.ai_poison_card[c:objectName()] or self:evaluateArmor(c)<-5
                self.yjzy_to = self:AlPresentCardTo(c,enemie)
                self:setPriorityValue("yj_zhengyuCard",8,"yj_zhengyu")
            else
                if self:wasPreviouslyPlannedCard(c) then continue end
                self.yjzy_to = self:AlPresentCardTo(c,sgs.ai_poison_card[c:objectName()])
            end
            if not self.yjzy_to or self.player:getStrategyFlag(self.yjzy_to:objectName().."yj_zhengyuUse"..c:getKnownId()) then continue end
            return self:bindSkillCard("yj_zhengyu&", {c:getKnownId()}, request, nil, "#yj_zhengyuCard")
        end
    end
end

ai_card_use["#yj_zhengyuCard"] = function(self, card, use, request)
    if self.yjzy_to then
        use.card = card
        use.to:append(self.yjzy_to)
        if use.from then
            self:setStrategyPlayerFlag(use.from,self.yjzy_to:objectName().."yj_zhengyuUse"..card:getKnownEffectiveId(),true)
        end
    end
end

sgs.ai_use_value.yj_zhengyuCard = 5.4
sgs.ai_use_priority.yj_zhengyuCard = 0.8

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, from, to, dmg, card, nature, damage_call, helpers, context)
        local damage_card_flag=helpers.card_flag
        if damage_card_flag(self,card,"yj_nvzhuang_debuff") then dmg=dmg+1 end
        return dmg, nature
    end
    local previous_1 = sgs.ai_ajustdamage_from["yj_nvzhuang"]
    sgs.ai_ajustdamage_from["yj_nvzhuang"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "slash_card" and context.rule == "yj_nvzhuang" then
                local damage, next_nature, terminal = policy_1(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_from", "yj_nvzhuang", {
        {phase="slash_card", rule="yj_nvzhuang", order=5206},
    })
end)()
