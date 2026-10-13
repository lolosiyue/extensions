-- Fixed b6025acc Yongjian bodies. No legacy VM objects or hidden card identities enter this module.
local function known(v,key)
 if AIUnsupported.is(v)then error(v,0)end
 if v==nil then ai_unsupported("Yongjian requires "..key,"yongjian")end;return v
end
local function q(o,m,...)
 if AIValue.isPlayer(o)then if m=="getMark"then m="getStrategyMark"elseif m=="hasFlag"then m="getStrategyFlag"end end
 if not o or type(o[m])~="function"then ai_unsupported("Yongjian method unavailable: "..m,"yongjian")end
 return known(o[m](o,...),m)
end
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
 local c=q(self,"getDecisionContext").yongjian
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
  or row.viewer~=q(self.player,"objectName") or row.decision_id~=tostring(r.decision_id)
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
 local sample=q(self,"randomHandDiscardToken",who)
 if sample.empty or type(sample.disabled)~="boolean" or type(sample.selected_choice)~="table" then
  ai_unsupported("Tuixinzhifu selected hand receipt is unavailable","yj_tuixinzhifu")
 end
 return sample
end
local function public_random_card(self,who)
 local cards
 if who~=self.player and q(who,"getHandcardNum")>0 then
  local row=q(self,"getDecisionContext").yongjian_third_pass
  if type(row)~="table"or row.known~=true or row.target~=q(who,"objectName")or not AIValue.isList(row.ordered_card_ids)then
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
 else cards=q(who,"getCards","hej")end
 if who==self.player then
  for _,c in ipairs(self:sortByKeepValue(cards))do local id=q(c,"getEffectiveId");if not disabled(self,id)then return id end end
  return -1
 end
 local ids,byid={},{}
 for _,c in ipairs(cards)do local id=q(c,"getEffectiveId");byid[id]=c;if not disabled(self,id)then ids[#ids+1]=id end end
 if #ids==0 then return -1 end
 local mr=math.random(1,#ids);local id=ids[mr]
 if q(byid[id],"isKindOf","SilverLion")and q(who,"isWounded")and q(self,"isEnemy",who)and q(who,"hasArmorEffect","SilverLion")then
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
 if to==self.player then return q(self,"evaluateArmor",c)end
 ai_unsupported("Zhulutianxia requires another AI's current armor evaluation and skill callbacks","Zhulutianxia")
end

function SmartAIView:useCardPoison(card,use)
    if not table.contains(scope_value(self,"poison_use"):split(","),q(card,"getLegacyStringKey"))
    then return end
    self:sort(self.enemies)
    for i,ep in sgs.list(self.enemies)do
        if i>#self.enemies/2 and q(self,"cardTargetFilter",card,use.to,ep) then
            use.card = card
            use.to:append(ep)
        end
    end
    for _,ep in sgs.list(self:sort(self.room:getAlivePlayers(),nil,true))do
        if not q(self,"isFriend",ep) and q(self,"cardTargetFilter",card,use.to,ep) then
            use.card = card
            use.to:append(ep)
        end
    end
end

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
        table.insert(to_cards,q(h,"getEffectiveId"))
    end
    return to_cards
end

function SmartAIView:useCardChenhuodajie(card,use)
    self:sort(self.enemies)
    local extraTarget = q(card,"getTargetModExtra",self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,ep in sgs.list(self.enemies)do
        if isCurrent(use,ep) then continue end
        if q(self.player,"canUse",card,ep)
        and q(self,"isGoodTarget",ep,self.enemies,card) then
            use.card = card
            use.to:append(ep)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
    for _,ep in sgs.list(self.friends_noself)do
        if isCurrent(use,ep) then continue end
        if q(self.player,"canUse",card,ep)
        and q(self,"needToLoseHp",ep,self.player,card) then
            use.card = card
            use.to:append(ep)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
end
sgs.ai_use_priority.Chenhuodajie = 5.4
sgs.ai_keep_value.Chenhuodajie = 2
sgs.ai_use_value.Chenhuodajie = 3.7
sgs.ai_card_intention.Chenhuodajie = 44

sgs.ai_nullification.Chenhuodajie = function(self,trick,from,to,positive)
    return positive and q(self,"isFriend",to) and not q(self,"isFriend",from)
    and (to==self.player or q(self,"isWeak",to))
end

sgs.ai_skill_cardask["yj_chenhuodajie0"] = function(self,data,pattern)
    local c = self:getKnownCardById(tonumber(pattern))
    if c then
        local effect = data:toCardEffect()
        local n = q(self,"ajustDamage",effect.from,effect.to,1,effect.card)
        if n==0 or n<2 and (q(self,"isWeak") and isCard("Peach,Analeptic",c,self.player) or q(self,"getKeepValue",c)>6 and q(c,"isAvailable",self.player))
        then return "." end
        return pattern
    end
end

function SmartAIView:useCardGuaguliaodu(card,use)
    self:sort(self.friends,"hp")
    local extraTarget = q(card,"getTargetModExtra",self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,ep in sgs.list(self.friends)do
        if isCurrent(use,ep) then continue end
        if q(self.player,"canUse",card,ep) then
            use.card = card
            use.to:append(ep)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
end
sgs.ai_use_priority.Guaguliaodu = 2.4
sgs.ai_keep_value.Guaguliaodu = 2.2
sgs.ai_use_value.Guaguliaodu = 4.7
sgs.ai_card_intention.Guaguliaodu = -33

sgs.ai_nullification.Guaguliaodu = function(self,trick,from,to,positive)
    if positive then
        return q(self,"isEnemy",to) and q(to,"isWounded")
        and (q(self,"isWeak",to) or q(self,"getCardsNum","Nullification")>1)
    else
        return q(self,"isFriend",to) and q(to,"isWounded")
        and (q(self,"isWeak",to) or q(self,"getCardsNum","Nullification")>1)
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
        if q(self,"wasPreviouslyPlannedCard",c)
        or q(self,"getKeepValue",c)>7
        then else n = n+1 end
        if n>1 then use.card = card return end
    end
    if q(self,"getPriorTurnUseCount")<2 and (q(self.player,"getCardCount")>4 or q(self,"getOverflow")>0) then
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
        if #discard<2 and q(self.player,"hasEquip",c) and q(self,"evaluateArmor",c)<-5
        then table.insert(discard,q(c,"getEffectiveId")) continue end
        if #cards/2>i and #discard<1 and q(c,"isKindOf","EquipCard")
        then table.insert(discard,q(c,"getEffectiveId")) end
    end
    cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards,nil,"j")
    for i,c in sgs.list(cards)do
        if table.contains(discard,q(c,"getEffectiveId")) then continue end
        if #discard<2 then table.insert(discard,q(c,"getEffectiveId")) end
    end
    return discard
end

function SmartAIView:useCardTuixinzhifu(card,use)
    self:sort(self.friends_noself,"hp")
    local extraTarget = q(card,"getTargetModExtra",self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,p in sgs.list(self.friends_noself)do
        if isCurrent(use,p) or use.to:contains(p) then continue end
        if q(self,"cardTargetFilter",card,{},p)
        and q(self,"doDisCard",p,"ej") then
            use.card = card
            use.to:append(p)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
    self:sort(self.enemies,"hp")
    for _,p in sgs.list(self.enemies)do
        if isCurrent(use,p) or use.to:contains(p) then continue end
        if q(self,"cardTargetFilter",card,{},p)
        and q(self,"doDisCard",p,"ej") then
            use.card = card
            use.to:append(p)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
    for _,p in sgs.list(self.enemies)do
        if isCurrent(use,p) or use.to:contains(p) then continue end
        if q(self,"cardTargetFilter",card,{},p)
        and q(self,"doDisCard",p,"hej") then
            use.card = card
            use.to:append(p)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
    local tos = self.room:getAlivePlayers()
    tos = self:sort(tos,"card",true)
    for _,p in sgs.list(tos)do
        if isCurrent(use,p) or use.to:contains(p) then continue end
        if q(self,"cardTargetFilter",card,{},p)
        and q(p,"getCardCount")>1 then
            use.card = card
            use.to:append(p)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
end
sgs.ai_use_priority.Tuixinzhifu = 5.4
sgs.ai_keep_value.Tuixinzhifu = 2.2
sgs.ai_use_value.Tuixinzhifu = 4.7

sgs.ai_skill_cardchosen.yj_tuixinzhifu = function(self,who)
    for _,c in sgs.list(who:getCards("ej"))do
        if q(self,"doDisCard",who,q(c,"getEffectiveId"),true)
        then return q(c,"getEffectiveId") end
    end
    for i=1,q(who,"getHandcardNum")do
        local sample = hidden_hand_choice(self,who)
        if sample.disabled then continue end
        return {kind="answer",random_card_choice=sample.selected_choice}
    end
    for i=1,99 do
        local id = public_random_card(self,who)
        if q(self,"doDisCard",who,id,true)
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
        if table.contains(self:poisonCards(),h) and not q(self,"isFriend",target)
        then table.insert(to_cards,q(h,"getEffectiveId")) end
    end
    for i,h in sgs.list(cards)do
        if #to_cards>=n then return to_cards end
        if table.contains(to_cards,q(h,"getEffectiveId")) then continue end
        if i>=#cards/2 and q(self,"isFriend",target)
        then table.insert(to_cards,q(h,"getEffectiveId")) end
    end
    for _,h in sgs.list(cards)do
        if #to_cards>=n then return to_cards end
        if table.contains(to_cards,q(h,"getEffectiveId")) then continue end
        table.insert(to_cards,q(h,"getEffectiveId"))
    end
end

sgs.ai_nullification.Tuixinzhifu = function(self,trick,from,to,positive)
    local n = q(self,"getCardsNum","Nullification")
    if n>1 and (q(to,"hasEquip") or to:getJudgingArea():length()>0) then
        if positive then
            return q(self,"isFriend",to)
            and q(self,"isEnemy",from)
        else
            return q(self,"isEnemy",to)
            and q(self,"isEnemy",from)
        end
    elseif q(to,"getCardCount",true,true)>0
    and (to:getArmor() or to:getDefensiveHorse() or q(to,"getHandcardNum")<2 or to:getJudgingArea():length()>0) then
        if positive then
            return q(self,"isFriend",to)
            and q(self,"isEnemy",from)
        else
            return q(self,"isEnemy",to)
            and q(self,"isEnemy",from)
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
    if q(card,"objectName")=="yj_numa"
    then return true end
end

--给在装备区特定的牌设定为负面卡牌；需要设定的值小于-5
--ai会优先将负面装备卸掉，ai队友也会优先帮你拆顺掉这些装备
--同时对手也不会优先去卸掉你的这些装备
sgs.ai_armor_value.yj_yinfengyi = -9
sgs.ai_armor_value.yj_zheji = -7.6
sgs.ai_armor_value.yj_numa = -7
sgs.ai_armor_value.yj_nvzhuang = -8

sgs.ai_fill_skill.yj_xinge = function(self,inclusive,request)
    local cards = self.player:getHandcards()
    self.yjxg_to = nil
    self:sort(self.enemies,"hp")
    self:sort(self.friends_noself,"hp")
    local pcs = self:poisonCards(cards)
    for _,c in sgs.list(self:sortByKeepValue(cards))do
        if table.contains(pcs,c)
        then self.yjxg_to = self.enemies[1]
        elseif q(c,"isKindOf","Slash") then
            if q(self,"wasPreviouslyPlannedCard",c)
            or q(self.player,"getHandcardNum")<2 then continue end
            self.yjxg_to = self.friends_noself[1]
        elseif q(c,"isKindOf","Jink") then
            if q(self,"getCardsNum","Jink","h")<1 then continue end
            self.yjxg_to = self.friends_noself[1]
        elseif q(c,"isKindOf","Peach") then
            if q(self,"isWeak") and q(self,"wasPreviouslyPlannedCard",c) then continue end
            self.yjxg_to = self.friends_noself[1]
        elseif q(self.player,"getHandcardNum")>q(self.player,"getMaxCards")
        then self.yjxg_to = self.friends_noself[1] end
        if not self.yjxg_to then continue end
        return q(self,"bindSkillCard","yj_xinge",{q(c,"getEffectiveId")},request,nil,"#yj_xingecard")
    end
    local c,p = self:getCardNeedPlayer()
    if c and p then
        self.yjxg_to = p
        return q(self,"bindSkillCard","yj_xinge",{q(c,"getEffectiveId")},request,nil,"#yj_xingecard")
    end
end

sgs.ai_skill_use_func["#yj_xingecard"] = function(card,use,self,request)
    if q(self.yjxg_to,"isAlive") then
        use.card = card
        use.to:append(self.yjxg_to)
    end
end

sgs.ai_use_value.yj_xingecard = 5.4
sgs.ai_use_priority.yj_xingecard = 3.8

sgs.ai_armor_value.zl_yinfengjia = -8
sgs.ai_armor_value.zl_wufengjian = -6

sgs.ai_poison_card.zl_wufengjian = function(self,c,player)
    if q(player,"hasEquip",c) then return getCardsNum("Slash",player,self.player)>0 end
end

sgs.ai_poison_card.zl_jinhe = function(self,c,player)
    if q(player,"hasEquip",c) then return q(player,"getHandcardNum")<1 end
end

sgs.ai_poison_card.zl_nvzhuang = function(self,c,player)
    if not q(player,"hasEquip",c) then return q(player,"isMale") end
end

sgs.ai_poison_card.zl_numa = function(self,c,player)
    return not q(player,"hasEquip",c) and q(player,"hasEquip")
end

function SmartAIView:useCardCaochuanjiejian(card,use)
    local ce = scope_use(self,"caochuan_effect")
    if ce and ce.card and not known(ce.nullified,"Caochuanjiejian nullified")
    and q(self,"hasTrickEffective",ce.card,ce.to,ce.from)
    and not q(self,"canDamageHp",ce.from,ce.card,ce.to)
    then use.card = card end
end
sgs.ai_keep_value.Caochuanjiejian = 9.6
sgs.ai_use_value.Caochuanjiejian = 6.9
sgs.ai_use_priority.Caochuanjiejian = 6.6

sgs.ai_nullification.Caochuanjiejian = function(self,trick,from,to,positive,null_num)
    if positive then
        return q(self,"isEnemy",from)
        and (q(self,"isWeak",from) or null_num>1)
    else
        return q(self,"isFriend",from)
        and q(self,"isWeak",from)
    end
end

function SmartAIView:useCardJiejiaguitian(card,use)
    self:sort(self.friends,"hp")
    local extraTarget = q(card,"getTargetModExtra",self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,ep in sgs.list(self.friends)do
        if isCurrent(use,ep) then continue end
        if q(self,"cardTargetFilter",card,{},ep)
        and #self:poisonCards("e",ep)>=ep:getEquips():length()/2 then
            use.card = card
            use.to:append(ep)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
    local function equipValue(p)
        local x = p:getEquips():length()
        local pc = self:poisonCards("e",p)
        for _,e in sgs.list(p:getEquips())do
            if table.contains(pc,e)
            then x = x-2 continue end
            if q(e,"isKindOf","Weapon")
            or q(e,"isKindOf","OffensiveHorse") then x = x+2
            elseif q(e,"isKindOf","Armor") then x = x+4
            elseif q(e,"isKindOf","DefensiveHorse") then x = x+3
            else x = x+1+p:getPile("wooden_ox"):length() end
        end
        return x
    end
    local function func(a,b)
        return equipValue(a)>equipValue(b)
    end
    table.sort(self.enemies,func)
    for _,ep in sgs.list(self.enemies)do
        if isCurrent(use,ep) then continue end
        if q(self,"cardTargetFilter",card,{},ep)
        and #self:poisonCards("e",ep)<=ep:getEquips():length()/2 then
            use.card = card
            use.to:append(ep)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
    local tos = self.room:getAlivePlayers()
    tos = self:sort(tos,"card",true)
    table.sort(tos,func)
    for _,ep in sgs.list(tos)do
        if isCurrent(use,ep) then continue end
        if q(self,"cardTargetFilter",card,{},ep)
        and #self:poisonCards("e",ep)<ep:getEquips():length()/2
        and not q(self,"isFriend",ep)
        then
            use.card = card
            use.to:append(ep)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
end
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
        if q(self,"isEnemy",to) then
            local NP = to:getNextAlive()
            if not q(self,"isEnemy",NP) then
                for _,id in sgs.list(ids)do
                    local c = disclosed_card(self,id)
                    if isCard("Crossbow",c,NP)
                    and q(to,"hasEquipArea",0) then
                        for _,enemy in sgs.list(self.enemies)do
                            if getCardsNum("Slash",enemy,self.player)>1 then
                                local slash = q(self,"getEvaluationCard","slash")
                                for _,friend in sgs.list(self.friends)do
                                    if q(enemy,"distanceTo",friend)==1
                                    and q(self,"slashIsEffective",slash,friend,enemy)
                                    then return true end
                                end
                            end
                        end
                    end
                end
            end
        elseif q(self,"isFriend",to) then
            local c = other_ag(self,to,ids)
            c = c and c>=0 and disclosed_card(self,c)or nil
            local pc = other_poison(self,to,ids)
            if table.contains(pc,c) or other_armor(self,to,c)<-5
            then return q(self,"isWeak",to) or null_num>1 end
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
        local n = q(c,"getEquipSlot")
        if q(self.player,"hasEquipArea",n)
        then table.insert(cs,c) end
    end
    self:sortByUseValue(cs)
    for _,c in sgs.list(cs)do
        if table.contains(pc,c)
        or q(self,"evaluateArmor",c)<-5
        then continue end
        local n = q(c,"getEquipSlot")
        n = self.player:getEquip(n)
        if n and q(self,"evaluateArmor",n)>-5
        then continue end
        if n and q(self,"evaluateArmor",n)<-5
        then return q(c,"getEffectiveId") end
    end
    for _,c in sgs.list(cs)do
        if table.contains(pc,c)
        or q(self,"evaluateArmor",c)<-5
        then continue end
        local n = q(c,"getEquipSlot")
        n = self.player:getEquip(n)
        if n and q(self,"evaluateArmor",n)>-5
        then continue end
        if q(self,"evaluateAcquiredCard",c).card
        then return q(c,"getEffectiveId") end
    end
    for _,c in sgs.list(cs)do
        if table.contains(pc,c)
        or q(self,"evaluateArmor",c)<-5
        then continue end
        if q(self.player,"getPhase")<=sgs.Player_Play
        and q(self,"evaluateAcquiredCard",c).card
        then return q(c,"getEffectiveId") end
    end
    for _,c in sgs.list(cs)do
        if table.contains(pc,c)
        or q(self,"evaluateArmor",c)<-5
        then continue end
        local n = q(c,"getEquipSlot")
        n = self.player:getEquip(n)
        if n and q(self,"evaluateArmor",n)>-5
        then continue end
        return q(c,"getEffectiveId")
    end
    for _,c in sgs.list(cs)do
        if table.contains(pc,c)
        or q(self,"evaluateArmor",c)<-5
        then continue end
        return q(c,"getEffectiveId")
    end
    return #cs>0 and cs[1]:getEffectiveId()
end

sgs.ai_target_revises.zl_yexingyi = function(to,card)
    if q(card,"isKindOf","TrickCard") and q(card,"isBlack")
    then return true end
end

sgs.ai_skill_invoke.zl_yajiaoqiang = true
sgs.ai_armor_value.zl_yajiaoqiang = 2
sgs.ai_card_priority.zl_yajiaoqiang = function(self,card)
    if q(self.player,"getPhase")==sgs.Player_NotActive
    and q(card,"isBlack") and q(self.player,"getMark","zl_yajiaoqiang-Clear")<1
    then return 3 end
end

sgs.ai_fill_skill.zl_jinhe = function(self,inclusive,request)
    local zl_li = self.player:getPile("zl_li")
    if q(zl_li,"length")>0 and #self.enemies>0
    and (q(self.player,"getHandcardNum")<2 or q(self.player,"getHandcardNum")>q(self.player,"getMaxCards"))
    then return incompatible_jinhe(self,zl_li:at(0)) end
end

sgs.ai_skill_use_func["#zl_jinheCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value.zl_jinheCard = -5.4
sgs.ai_use_priority.zl_jinheCard = -4.8



sgs.ai_skill_invoke.zd_xunzhi = function(self,data)
    return not q(self,"isWeak") and q(self,"getOverflow")>1
end

sgs.ai_fill_skill.zd_fenyue = function(self,inclusive,request)
    return q(self,"legacySkillSeed","zd_fenyue","#zd_fenyueCard",request)
end

sgs.ai_skill_use_func["#zd_fenyueCard"] = function(card,use,self,request)
    local mc = self:getMaxCard()
    if mc then
        self:sort(self.enemies,"handcard")
        for _,p in sgs.list(self.enemies)do
            local emc = self:getMaxCard(p)
            if emc and q(emc,"getNumber")<q(mc,"getNumber")
            then
                use.card = q(self,"bindSkillCard","zd_fenyue",{q(mc,"getEffectiveId")},request,nil,"#zd_fenyueCard")
                use.to:append(p)
                return
            end
        end
    end
end

sgs.ai_use_value.zd_fenyueCard = 3.4
sgs.ai_use_priority.zd_fenyueCard = 5.2

sgs.ai_skill_choice.zd_fenyue = function(self,choices,data)
    local target = data:toPlayer()
    local items = choices:split("+")
    if table.contains(items,"zd_fenyue2") then
        local d = q(self,"evaluateSkillCard","_zd_fenyue","slash",{})
        local use = AIUsePlan.new()
        use.card = d
        use.from = self.player
        if self:canCanmou(target,use)
        then
            return "zd_fenyue2"
        end
    end
    if q(target,"getHandcardNum")>0 then
        return "zd_fenyue1"
    end
end

sgs.ai_skill_playerchosen.zd_dongcha = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
        if q(self,"doDisCard",target,"ej",true)
        then return target end
    end
end


function SmartAIView:useCardShengdongjixi(card,use)
    if q(self.player,"getHandcardNum")<2 then return end
    local toList = self:sort(self.room:getAlivePlayers(),"handcard",true)
    local fromList = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    local extraTarget = q(card,"getTargetModExtra",self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    extraTarget = extraTarget*2
    for _,enemy in ipairs(fromList)do
        if isCurrent(use,enemy) or use.to:contains(enemy) then continue end
        if q(self,"cardTargetFilter",card,{},enemy) and q(self,"objectiveLevel",enemy)>=0
        and not(q(enemy,"hasEquip") and q(self,"loseEquipEffect",enemy) or q(enemy,"hasSkill","tuntian+zaoxian"))
        and #self:poisonCards("he",enemy)<1
        and q(enemy,"getCardCount")>0 then
            for _,p in ipairs(toList)do
                if enemy~=p and (p~=self.player or q(enemy,"getCardCount")>0) and q(self,"isFriend",p) then
                    use.card = card
                    use.to:append(enemy)
                    use.to:append(p)
                    if q(use.to,"length")>extraTarget
                    then return end
                    break
                end
            end
        end
    end
    for _,friend in ipairs(fromList)do
        if isCurrent(use,friend) or use.to:contains(friend) then continue end
        if q(self,"cardTargetFilter",card,{},friend) and q(self,"objectiveLevel",friend)<0
        and #self:poisonCards("h",friend)>0 then
            for _,enemy in ipairs(toList)do
                if enemy~=friend and (p~=self.player or q(friend,"getCardCount")>0)
                and q(self,"objectiveLevel",enemy)>1 then
                    use.card = card
                    use.to:append(friend)
                    use.to:append(enemy)
                    if q(use.to,"length")>extraTarget
                    then return end
                    break
                end
            end
        end
    end
    for _,friend in ipairs(fromList)do
        if isCurrent(use,friend) or use.to:contains(friend) then continue end
        if q(self,"cardTargetFilter",card,{},friend) and q(self,"objectiveLevel",friend)<0
        and #self:poisonCards("e",friend)>0 then
            for _,p in sgs.list(self.room:getAlivePlayers())do
                if p~=friend and (p~=self.player or q(friend,"getCardCount")>0)
                and q(self,"objectiveLevel",p)<=0  then
                    use.card = card
                    use.to:append(friend)
                    use.to:append(p)
                    if q(use.to,"length")>extraTarget
                    then return end
                    break
                end
            end
        end
    end
    for _,friend in ipairs(fromList)do
        if isCurrent(use,friend) or use.to:contains(friend) then continue end
        if q(self,"cardTargetFilter",card,{},friend) and q(self,"objectiveLevel",friend)<=0
        and #self:poisonCards("h",friend)<1 then
            for _,p in ipairs(toList)do
                if p~=friend and (p~=self.player or q(friend,"getCardCount")>0)
                and q(self,"objectiveLevel",p)<0 then
                    use.card = card
                    use.to:append(friend)
                    use.to:append(p)
                    if q(use.to,"length")>extraTarget
                    then return end
                    break
                end
            end
        end
    end
end

sgs.ai_use_value.Shengdongjixi = 5.8
sgs.ai_use_priority.Shengdongjixi = 4.75
sgs.ai_keep_value.Shengdongjixi = 3.40

sgs.ai_nullification.Shengdongjixi = function(self,trick,from,to,positive,null_num)
    if positive then
        if q(self,"isEnemy",from) and (q(self,"isFriend",to) or q(self,"isEnemy",to))
        and (null_num>1 or q(self,"isWeak",to) or to==self.player)
        then return true end
    else

    end
end

sgs.ai_skill_playerchosen.zd_shengdongjixi = function(self,players)
    local destlist = self:sort(players)
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target)
        and q(self,"canDraw",target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not q(self,"isEnemy",target)
        and q(self,"canDraw",target)
        then return target end
    end
    return destlist[#destlist]
end


function SmartAIView:useCardCaomujiebing(card,use)
    self:sort(self.enemies,"hp",true)
    for _,ep in sgs.list(self.enemies)do
        if isCurrent(use,ep) then continue end
        if q(self,"cardTargetFilter",card,{},ep)
        and not q(ep,"containsTrick","supply_shortage") then
            use.card = card
            use.to:append(ep)
            return
        end
    end
    for _,ep in sgs.list(self.enemies)do
        if isCurrent(use,ep) then continue end
        if q(self,"cardTargetFilter",card,{},ep) then
            use.card = card
            use.to:append(ep)
            return
        end
    end
end
sgs.ai_use_priority.Caomujiebing = 0.4
sgs.ai_keep_value.Caomujiebing = 2
sgs.ai_use_value.Caomujiebing = 5.7
sgs.ai_card_intention.Caomujiebing = 66
sgs.ai_judgestring.zd_caomujiebing = ".|club"

sgs.ai_nullification.Caomujiebing = function(self,trick,from,to,positive,null_num)
    if positive then
        if to==self.player
        or q(self,"isFriend",to) and (null_num>1 or q(self,"isWeak",to))
        then return true end
    else
        if q(self,"isEnemy",to)
        and (null_num>1 or q(self,"isWeak",to))
        then return true end
    end
end

function SmartAIView:useCardZengbingjianzao(card,use)
    self:sort(self.friends,nil,true)
    local extraTarget = q(card,"getTargetModExtra",self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,fp in sgs.list(self.friends)do
        if isCurrent(use,fp) or use.to:contains(fp) then continue end
        if q(self,"cardTargetFilter",card,{},fp)
        and q(self,"canDraw",fp) and q(self,"isWeak",fp) then
            use.card = card
            use.to:append(fp)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
    if not isCurrent(use,self.player) and q(self,"getCardsNum","EquipCard,TrickCard","he")>1 then
        if CanToCard(card,self.player,self.player) and not use.to:contains(self.player) then
            use.card = card
            use.to:append(self.player)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
    self:sort(self.friends)
    for _,fp in sgs.list(self.friends)do
        if isCurrent(use,fp) or use.to:contains(fp) then continue end
        if q(self,"cardTargetFilter",card,{},fp)
        and q(self,"canDraw",fp) then
            use.card = card
            use.to:append(fp)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
end
sgs.ai_use_priority.Zengbingjianzao = 9.4
sgs.ai_keep_value.Zengbingjianzao = 6
sgs.ai_use_value.Zengbingjianzao = 5.7
sgs.ai_card_intention.Zengbingjianzao = -66

sgs.ai_nullification.Zengbingjianzao = function(self,trick,from,to,positive,null_num)
    if positive then
        if q(self,"isEnemy",to)
        and (null_num>1 or q(self,"isWeak",to))
        then return true end
    else
        if to==self.player
        or q(self,"isFriend",to) and (null_num>1 or q(self,"isWeak",to))
        then return true end
    end
end

sgs.ai_skill_use["@@Zengbing!"] = function(self,prompt)
    for _,h in sgs.list(self:sortByKeepValue(self.player:getCards("he"),nil,"j"))do
        if q(h,"getTypeId")<2 then continue end
        return "#ZengbingCard:"..q(h,"getId")..":"
    end
end

function SmartAIView:useCardQijiayebing(card,use)
    self:sort(self.enemies,"equip",true)
    local extraTarget = q(card,"getTargetModExtra",self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,ep in sgs.list(self.enemies)do
        if isCurrent(use,ep) then continue end
        if q(self.player,"canUse",card,ep) and not use.to:contains(ep)
        and (ep:getTreasure()==nil or ep:getEquips():length()>1)
        and ep:getEquips():length()/2>#self:poisonCards("e",ep)
        and q(self,"isWeak",ep) then
            use.card = card
            use.to:append(ep)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
    for _,ep in sgs.list(self.enemies)do
        if isCurrent(use,ep) then continue end
        if q(self.player,"canUse",card,ep) and not use.to:contains(ep)
        and (ep:getTreasure()==nil or ep:getEquips():length()>1)
        and ep:getEquips():length()/2>#self:poisonCards("e",ep) then
            use.card = card
            use.to:append(ep)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
end
sgs.ai_use_priority.Qijiayebing = 8.4
sgs.ai_keep_value.Qijiayebing = 3
sgs.ai_use_value.Qijiayebing = 5.7
sgs.ai_card_intention.Qijiayebing = 99

sgs.ai_skill_choice.zd_qijiayebing = function(self,choices)
    if q(self,"getCardsNum","Weapon,OffensiveHorse","he")>q(self,"getCardsNum","Armor,DefensiveHorse","he")
    then return "Qijia2" end
    return "Qijia1"
end

sgs.ai_nullification.Qijiayebing = function(self,trick,from,to,positive,null_num)
    if positive then
        if q(self,"isFriend",to)
        and (null_num>1 or q(self,"isWeak",to) or to==self.player)
        then return true end
    else
        if q(self,"isEnemy",to) and (null_num>1 or q(self,"isWeak",to))
        then return true end
    end
end

sgs.ai_skill_use["Jinchan0"] = function(self,prompt)
    local use = scope_use(self,"jinchan_use")
    if q(use.card,"isDamageCard") or q(self,"isEnemy",use.from) and not q(use.card,"isKindOf","GlobalEffect") then
        if table.contains(use.nullified_list,q(self.player,"objectName"))
        or not q(self,"hasTrickEffective",use.card,self.player,use.from)
        or table.contains(use.nullified_list,"_ALL_TARGETS") then return end
        for _,h in sgs.list(self:getCard("Jinchantuoqiao",true))do
            return q(h,"getLegacyStringKey")
        end
    end
end

sgs.ai_nullification.Jinchantuoqiao = function(self,trick,from,to,positive,null_num)
    if positive then
        if q(self,"isEnemy",from)
        and (null_num>1 or q(self,"isWeak",from))
        then return true end
    else
        if from==self.player
        or q(self,"isFriend",from) and (null_num>1 or q(self,"isWeak",from))
        then return true end
    end
end

sgs.ai_keep_value.Jinchantuoqiao = 2
sgs.ai_use_value.Jinchantuoqiao = 9.7
sgs.ai_card_intention.Jinchantuoqiao = -99

function SmartAIView:useCardFulei(card,use)
    if q(self,"willUseLightning",card)
    then use.card = card end
end
sgs.ai_use_priority.Fulei = -4
sgs.ai_keep_value.Fulei = 1
sgs.ai_use_value.Fulei = 1.7
sgs.ai_card_intention.Fulei = 77

sgs.ai_judgestring.zd_fulei = {".|spade",false}

sgs.ai_poison_card.zd_fulei = function(self,c,owner)
    local n = fact(self,"fulei_counts",q(c,"getLegacyStringKey"))
    if q(self,"isFriend",owner) or #self.friends_noself>0 and not q(self,"isEnemy",owner)
    then return n>=q(owner,"getHp") end
end

sgs.ai_view_as.zd_lanyinjia = function(card,player,card_place,class_name)
    if card_place==sgs.Player_PlaceHand and class_name=="Jink" then
        return "jink:zd_lanyinjia[no_suit:0]="..q(card,"getLegacyStringKey")
    end
end

sgs.ai_skill_invoke.zd_zhungangshuo = function(self,data)
    local target = data:toPlayer()
    if target and q(target,"getHandcardNum")>0 then
        local use = target_specified_history(self)
        if table.contains(use.nullified_list,q(target,"objectName"))
        or table.contains(use.nullified_list,"_ALL_TARGETS")
        then return false end
        if type(self.doDisCard)~="function"then ai_unsupported("doDisCard provider missing","yongjian.target_history")end
        local result=self:doDisCard(target,"h")
        if AIUnsupported.is(result)then error(result,0)end
        return result -- the fixed source may return nil when discard is unavailable
    end
end



function SmartAIView:useCardLuanwu(card,use)
    if #self.enemies>#self.friends_noself
    or q(self,"isWeak",self.enemies)
    then use.card = card end
end
sgs.ai_use_priority.Luanwu = 4
sgs.ai_keep_value.Luanwu = 1
sgs.ai_use_value.Luanwu = 1.7

function SmartAIView:useCardDouzhuanxingyi(card,use)
    local extraTarget = q(card,"getTargetModExtra",self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,ep in sgs.list(self.enemies)do
        if isCurrent(use,ep) then continue end
        if q(self.player,"canUse",card,ep)
        and not use.to:contains(ep)
        and q(ep,"getHp")>q(self.player,"getHp")
        and q(self.player,"isWounded")
        and q(self,"isWeak",ep) then
            use.card = card
            use.to:append(ep)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
    for _,ep in sgs.list(self.enemies)do
        if isCurrent(use,ep) then continue end
        if q(self.player,"canUse",card,ep)
        and not use.to:contains(ep)
        and q(ep,"getHp")>=q(self.player,"getHp")
        and q(self.player,"isWounded")
        and q(self,"isWeak",ep) then
            use.card = card
            use.to:append(ep)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
end
sgs.ai_use_priority.Douzhuanxingyi = 4.5
sgs.ai_keep_value.Douzhuanxingyi = 1
sgs.ai_use_value.Douzhuanxingyi = 1.7

function SmartAIView:useCardLidaitaojing(card,use)
    local extraTarget = q(card,"getTargetModExtra",self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,ep in sgs.list(self.enemies)do
        if isCurrent(use,ep) then continue end
        if q(self.player,"canUse",card,ep) and not use.to:contains(ep)
        and q(ep,"getHandcardNum")>q(self.player,"getHandcardNum")
        and q(self,"isWeak",ep) then
            use.card = card
            use.to:append(ep)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
    for _,ep in sgs.list(self.enemies)do
        if isCurrent(use,ep) then continue end
        if q(self.player,"canUse",card,ep) and not use.to:contains(ep)
        and q(ep,"getHandcardNum")>=q(self.player,"getHandcardNum") then
            use.card = card
            use.to:append(ep)
            if q(use.to,"length")>extraTarget
            then return end
        end
    end
end
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
        if math.random()<0.8 and fact(self,"defensive_horse_zhanxiang",q(to,"objectName")) then continue end
        if q(c,"isKindOf","EquipCard") then
            local e = q(c,"getEquipSlot")
            if q(to,"hasEquipArea",e) then else continue end
            e = to:getEquip(e)
            if e then
                e = q(self,"evaluateArmor",e,to)
                if e<=-5 and enemie
                then continue end
            end
        elseif hasManjuanEffect(to)
        or not enemie and not q(self,"canDraw",to)
        then continue end
        if q(c,"isKindOf","Qixingbaodao") then
            if enemie and to:getEquips():isEmpty() then continue end
            if not enemie and to:getEquips():length()>to:getJudgingArea():length() then continue end
        end
        if q(c,"objectName")=="zl_numa"
        and to:getEquips():length()<2
        then continue end
        if q(c,"isKindOf","Poison") then
            if enemie and to:getTreasure()
            and to:getTreasure():isKindOf("Xinge") then continue end
        end
        if q(c,"isKindOf","Nvzhuang") then
            if q(to,"isMale") then else continue end
            if q(c,"objectName")=="zl_nvzhuang" and q(to,"getCardCount")<1 then continue end
        end
        return to
    end
    if enemie then
        tos = self.room:getOtherPlayers(self.player)
        self:sort(tos,nil,enemie)
        for _,to in sgs.list(tos)do
            if math.random()<0.8 and fact(self,"defensive_horse_zhanxiang",q(to,"objectName")) or q(self,"isFriend",to) then continue end
            if q(c,"isKindOf","EquipCard") then
                local e = q(c,"getEquipSlot")
                if q(to,"hasEquipArea",e) then else continue end
                e = to:getEquip(e)
                if e then
                    e = q(self,"evaluateArmor",e,to)
                    if e<=-5 and enemie
                    then continue end
                end
            elseif hasManjuanEffect(to)
            and not(enemie or q(self,"canDraw",to))
            then continue end
            if q(c,"isKindOf","Qixingbaodao") then
                if enemie and to:getEquips():isEmpty() then continue end
                if not enemie and to:getEquips():length()>to:getJudgingArea():length() then continue end
            end
            if q(c,"objectName")=="zl_numa"
            and to:getEquips():length()<2
            then continue end
            if q(c,"isKindOf","Poison") then
                if enemie and to:getTreasure()
                and to:getTreasure():isKindOf("Xinge") then continue end
            end
            if q(c,"isKindOf","Nvzhuang") then
                if q(to,"isMale") then else continue end
                if q(c,"objectName")=="zl_nvzhuang" and q(to,"getCardCount")<1 then continue end
            end
            return to
        end
    end
end

sgs.ai_fill_skill.yj_zhengyu = function(self,inclusive,request)
    self:setPriorityValue("yj_zhengyuCard",0.8,"yj_zhengyu")
    self.yjzy_to = nil
    for _,c in sgs.list(self:sortByKeepValue(self.player:getHandcards()))do
        if fact(self,"card_is_present",tostring(q(c,"getId"))) then
            if q(c,"isKindOf","Slash") then
                if q(self,"wasPreviouslyPlannedCard",c)
                or q(self,"getCardsNum","Slash")<2 and q(self,"getOverflow")<1
                then continue end
                self.yjzy_to = self:AlPresentCardTo(c)
            elseif q(c,"isKindOf","Jink") then
                if q(self,"getCardsNum","Jink","h")<1 then continue end
                self.yjzy_to = self:AlPresentCardTo(c)
            elseif q(c,"isKindOf","Peach") then
                if q(self,"getCardsNum","Peach")<2
                and q(self,"wasPreviouslyPlannedCard",c)
                then continue end
                self.yjzy_to = self:AlPresentCardTo(c)
            elseif q(c,"isKindOf","Poison") then
                local can = q(self,"isWeak") and math.random()<0.97
                local n = q(self,"getOverflow")
                if n>0 then
                    n = self:askForDiscard("Poison",n,n,false,false)
                    if table.contains(n,q(c,"getId")) then can = false end
                end
                if can then continue end
                if q(self.player,"hasArmorEffect","yj_yinfengyi")
                and (q(self.player,"getHp")<4 or q(self.player,"getMaxCards")>=q(self.player,"getHandcardNum")/2)
                and math.random()<0.9 then continue end
                self.yjzy_to = self:AlPresentCardTo(c,true)
                self:setPriorityValue("yj_zhengyuCard",0.8,"yj_zhengyu")
            elseif q(c,"isKindOf","Qixingbaodao")
            then self.yjzy_to = self:AlPresentCardTo(c,true) or self:AlPresentCardTo(c)
            elseif q(c,"isKindOf","EquipCard") then
                if q(self,"wasPreviouslyPlannedCard",c) then continue end
                local enemie = sgs.ai_poison_card[q(c,"objectName")] or q(self,"evaluateArmor",c)<-5
                self.yjzy_to = self:AlPresentCardTo(c,enemie)
                self:setPriorityValue("yj_zhengyuCard",8,"yj_zhengyu")
            else
                if q(self,"wasPreviouslyPlannedCard",c) then continue end
                self.yjzy_to = self:AlPresentCardTo(c,sgs.ai_poison_card[q(c,"objectName")])
            end
            if not self.yjzy_to or q(self.player,"hasFlag",q(self.yjzy_to,"objectName").."yj_zhengyuUse"..q(c,"getId")) then continue end
            return q(self,"bindSkillCard","yj_zhengyu&",{q(c,"getId")},request,nil,"#yj_zhengyuCard")
        end
    end
end

sgs.ai_skill_use_func["#yj_zhengyuCard"] = function(card,use,self,request)
    if self.yjzy_to then
        use.card = card
        use.to:append(self.yjzy_to)
        if use.from then
            self:setStrategyPlayerFlag(use.from,q(self.yjzy_to,"objectName").."yj_zhengyuUse"..q(card,"getEffectiveId"),true)
        end
    end
end

sgs.ai_use_value.yj_zhengyuCard = 5.4
sgs.ai_use_priority.yj_zhengyuCard = 0.8
