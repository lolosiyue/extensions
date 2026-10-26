-- Source: b6025acc ai/sp-ai.lua.
local known = AIValue.requireKnown
-- Each V2 response keeps its own plan and binds its own native action receipt.
for _,skill in ipairs({"jijiang","oljijiang"})do
    local entry=skill
    ai_skill_use["@"..entry]=function(self, prompt, request)
        local method = request and request.handling_method
        local pattern = request and request.pattern
        if not AIValue.isSkillActionRequest(request) then return "." end
        local card=(self:bindSkillCard(request.skill_action.activation_skill,{},request))
        local plan=AIUsePlan.new()
        plan.isDummy=true
        self:planJijiang(card,plan)
        if not plan.card or plan.to:length()==0 then return "." end
        return plan:toAnswer()
    end
end

-- sp-ai.lua:921. The SkillCard declaration belongs to the policy object;
-- the response resolver supplies the independently validated ordinary receipt.
sgs.ai_cardsview_valuable.aocai = function(self, class_name, player)
    local declaration
    if class_name == "Slash" then declaration = "slash"
    elseif class_name == "Peach" or class_name == "Analeptic" then
        local dying = self.room:getCurrentDyingPlayer()
        if dying and (dying:objectName()) == (player:objectName()) then
            declaration = "peach+analeptic"
            if (player:getMark("Global_PreventPeach")) > 0 then declaration = "analeptic" end
        else declaration = class_name == "Analeptic" and "analeptic" or "peach" end
    end
    if declaration then
        return {skill="aocai",legacy_class="AocaiCard",subcards={},user_string=declaration}
    end
end

-- Both invoke writers are live under the fixed but package-dependent load
-- order. Capture their actual source once; never revive an overwritten body.
local function invoke_variant(self)
    -- The winner depends on the gameplay VM's load order, which is not projected.
    ai_unsupported("Aocai effective invoke source is unknown", "aocai.invoke")
end
ai_skill_invoke.aocai = function(self, native_options, native_request)
    local data = native_request and self:getDecisionData(native_request) or nil
    local variant = invoke_variant(self)
    if variant == nil then
        if type(ai_skill_invoke_default) ~= "function" then
            ai_unsupported("Aocai absent-hook common default is unavailable", "aocai.invoke")
        end
        return (known(ai_skill_invoke_default(self, self.request and self.request.options), "aocai.invoke.default")) or false
    end
    if variant == "ol_qifu" then return (true) or false end
    local context = (self:getDecisionContext())
    local invocation = context.aocai_invoke
    if type(invocation) ~= "table" or invocation.known ~= true
        or not AIValue.isList(invocation.asked) then
        ai_unsupported("Aocai original string-list invocation is not projected", "aocai.invoke")
    end
    local asked = invocation.asked
    -- Common askForCard owns hooks, nullfilter and source ordering. The nested
    -- inquiry must not be replaced with a hand count or legal-candidate test.
    return ((self:askForCard(asked[1],asked[2],1)) ~= ".") or false
end

-- sp-ai.lua:947. Only this question's disclosed AG cards are inspected.
sgs.ai_skill_askforag.aocai = function(self, card_ids)
    local card = (self:getChoiceCard(card_ids[1]))
    if (card:isKindOf("Jink")) and (self.player:hasFlag("dahe")) then
        for _, id in ipairs(card_ids) do
            if ((self:getChoiceCard(id)):getSuit()) == sgs.Card_Heart then return id end
        end
        return -1
    end
    return card_ids[1]
end

-- sp-ai.lua:958. Missing foreign flag knowledge remains explicit.
sgs.ai_skill_defense.aocai = function(self, player)
    if not (player:hasFlag("CurrentPlayer")) then return 0.5 end
    return 0
end

-- sp-ai.lua:3. Preserve the offered-domain defense ordering and first match.
sgs.weapon_range.SPMoonSpear = 3
sgs.ai_skill_playerchosen.sp_moonspear = function(self, targets)
    local ordered = {}
    for i, player in ipairs(targets) do ordered[i] = player end
    ordered = (self:sort(ordered,"defense"))
    for _, target in ipairs(ordered) do
        if (self:isEnemy(target)) and (self:damageIsEffective(target))
            and (self:isGoodTarget(target,ordered)) then return target end
    end
end
sgs.ai_playerchosen_intention.sp_moonspear = 80

-- sp-ai.lua:66. This comparator deliberately keeps donor call order, including
-- the first out-of-range GudingBlade break and repeated auxiliary evaluations.
sgs.ai_skill_discard.yongsi = function(self, discard_num, min_num, optional, include_equip)
    if optional then return {} end
    local flag = "h"
    local equips = (self.player:getEquips())
    if include_equip and not (#equips == 0 or (self.player:isJilei(equips[1]))) then flag = flag .. "e" end
    local cards = {}
    for i, card in ipairs((self.player:getCards(flag))) do cards[i] = card end
    local function auxiliary(card)
        local place = (self.room:getCardPlace((card:getKnownEffectiveId())))
        if place == sgs.Player_PlaceEquip then
            if (card:isKindOf("SilverLion")) then
                for _, player in ipairs((self.room:getOtherPlayers(self.player))) do
                    local blade = player:getWeapon()
                    if blade and (blade:isKindOf("GudingBlade")) then
                        if (player:inMyAttackRange(self.player)) then
                            if (self:isEnemy(player,self.player)) then return 6 end
                        else break end
                    end
                end
                if (self.player:isWounded()) then return -2 end
            elseif (card:isKindOf("Weapon")) and (self.player:getHandcardNum()) < discard_num + 2
                and not (self:needKongcheng()) then return 0
            elseif (card:isKindOf("OffensiveHorse")) and (self.player:getHandcardNum()) < discard_num + 2
                and not (self:needKongcheng()) then return 0
            elseif (card:isKindOf("OffensiveHorse")) then return 1
            elseif (card:isKindOf("Weapon")) then return 2
            elseif (card:isKindOf("DefensiveHorse")) then return 3
            elseif (self:hasSkills("bazhen|yizhong")) and (card:isKindOf("Armor")) then return 0
            elseif (card:isKindOf("Armor")) then return 4 end
        elseif (self:hasSkills(known(sgs.lose_equip_skill, "lose_equip_skill"))) then return 5
        else return 0 end
        return 0
    end
    table.sort(cards, function(a, b)
        if auxiliary(a) ~= auxiliary(b) then return auxiliary(a) < auxiliary(b) end
        return (self:getKeepValue(a)) < (self:getKeepValue(b))
    end)
    local least = min_num
    if discard_num - min_num > 1 then least = discard_num - 1 end
    local selected = {}
    for _, card in ipairs(cards) do
        if not (self.player:isJilei(card)) then selected[#selected + 1] = (card:getKnownId()) end
        if ((self.player:hasSkill("qinyin")) and #selected >= least) or #selected >= discard_num then break end
    end
    return selected
end
sgs.ai_skill_defense.yongsi = -2

-- sp-ai.lua:133. The use descriptor is from this inquiry; turn order uses the
-- original seat difference modulo the complete living-player count.
ai_skill_invoke.danlao = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local effect = (data:toCardUse())
    local current = (self.room:getCurrent())
    local card = known(effect.card, "danlao.use.card")
    if (card:isKindOf("GodSalvation")) and (self.player:isWounded())
        or (card:isKindOf("ExNihilo")) then return (false) or false
    elseif (card:isKindOf("AmazingGrace"))
        and ((self.player:getSeat()) - (current:getSeat())) % (self.room:alivePlayerCount())
            < (self.room:alivePlayerCount()) / 2 then return (false) or false end
    return (true) or false
end

-- sp-ai.lua:146/153. The observed damage source belongs to this AI's cache;
-- foreign private limitations are an explicitly recorded knowledge estimate.
ai_skill_invoke.jilei = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local damage = data:toDamage()
    if AIUnsupported.is(damage) then error(damage, 0) end
    if damage == nil then
        local context = (self:getDecisionContext())
        if context.damage_present == false then return (false) or false end
        ai_unsupported("Jilei inquiry damage presence is not projected", "jilei.damage")
    end
    local source = known(damage.from, "jilei.damage.from")
    self:setStrategyMemory("sp.jilei_source",(source:objectName()))
    return ((self:isEnemy(source))) or false
end
ai_skill_choice.jilei = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    local name, present = self:getStrategyMemory("sp.jilei_source")
    if AIUnsupported.is(name) then error(name, 0) end
    if present ~= true or type(name) ~= "string" then
        ai_unsupported("Jilei previous damage source is not known to this AI", "jilei.source")
    end
    local source = (self.room:findPlayerByObjectName(name,true))
    if (self:hasCrossbowEffect(source)) and (source:inMyAttackRange(self.player)) then return ai_choice_result(("BasicCard"), options) end
    local limited
    if name == (self.player:objectName()) then
        -- Donor: source:isCardLimited(ex_nihilo, MethodUse, true) on the viewer's own rules.
        limited = known(self.player:isCardLimited((self:getEvaluationCard("ex_nihilo")),sgs.Card_MethodUse,true), "jilei.owner_hand_limit")
    else
        -- Fixed sp.cpp writes the public mark together with the matching
        -- TrickCard|.|.|hand limit; zero never proves other limits absent.
        local mark
        if AIValue.isPlayer(source) then
            -- Only an observed positive mark proves the paired public writer.
            -- Strict getMark correctly throws for unprojected absence; do not
            -- query it merely to choose the explicitly estimated inactive prior.
            local view = rawget(source, "_view")
            local marks = type(view) == "table" and view.public_marks
            mark = type(marks) == "table" and marks["@jilei_trick"] or nil
        else
            mark = source:getMark("@jilei_trick")
        end
        if AIUnsupported.is(mark) then error(mark, 0) end
        if type(mark) == "number" and mark > 0 then limited = true
        else
            limited = (self:useKnowledgeEstimate({
                status="estimate",value=false,player=name,
                basis="unobserved_private_card_limitation_inactive_prior"
            },"sp.jilei.foreign_hand_limit"))
        end
    end
    return ai_choice_result((limited and "BasicCard" or "TrickCard"), options)
end

-- sp-ai.lua:1757–1818. Planning deliberately receives the original ordinary
-- Slash: useCardThunderSlash is the donor's thin useCardSlash forwarding method.
local function fulu_spec(card, id)
    if id == nil then
        card:getSuitString(); card:getNumberString(); id = (card:getKnownEffectiveId())
    end
    return {name="thunder_slash",skill="fulu",suit=(card:getSuit()),
        number=(card:getNumber()),subcards={id}}
end
sgs.ai_view_as.fulu = function(card, player, place)
    card:getSuitString(); card:getNumberString(); local id = (card:getKnownEffectiveId())
    known(place, "fulu.place")
    if place ~= sgs.Player_PlaceSpecial and (card:getClassName()) == "Slash"
        and not (card:hasFlag("using")) then return fulu_spec(card, id) end
end
ai_skill_invoke.fulu = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = (data:toCardUse())
    for _, player in ipairs(known(use.to, "fulu.targets")) do
        if (self:isEnemy(player)) and (self:isGoodTarget(player,self.enemies,known(use.card, "fulu.card"))) then return (true) or false end
    end
    return (false) or false
end
ai_fill_skill.fulu = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = (self:sortByUseValue((self:addHandPile()),true))
    local slash
    for _, card in ipairs(cards) do
        if (card:getClassName()) == "Slash" then slash = card; break end
    end
    if not slash then return nil end
    local use = AIUsePlan.new(); use.isDummy = true
    self:useCardThunderSlash(slash,use)
    if not use.card or #use.to == 0 then return nil end
    if not ai_skill_invoke.fulu(self, self:inquiryInput("skill_invoke","fulu",{use={from=self.player,to=use.to,card=slash}})) then return nil end
    return (self:bindTurnConversion("fulu","ThunderSlash",fulu_spec(slash),request))
end
ai_skill_invoke.zhuji = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local damage = (data:toDamage())
    if (self:isFriend(known(damage.from, "zhuji.from")))
        and not (self:isFriend(known(damage.to, "zhuji.to"))) then return (true) or false end
    return (false) or false
end

-- SP Xueji connected policy group; append after the shared SP local q/call.
-- Original donor sp-ai.lua:321–461, with authority binding and lawful knowledge.
local function xueji_q(self, object, method, ...)
    if method == "getMark" and AIValue.isPlayer(object) then method = "getStrategyMark" end
    local value = AIValue.callKnown(object, method, ...)
    if (value == false or value == nil) and (method == "hasSkill" or method == "hasSkills") and AIValue.isPlayer(object) then
        local view = rawget(object, "_view")
        if view.skills_complete ~= true then
            if (object:objectName()) == (self.player:objectName()) then
                ai_unsupported("Xueji owner skill roster is incomplete", "xueji.skills")
            end
            return (self:useKnowledgeEstimate({status="estimate",value=false,player=(object:objectName()),
                basis="sp.xueji.undisclosed_skill_uses_visible_roster"},"xueji.skills"))
        end
    end
    return known(value, method)
end
local function xueji_healer(self, room)
    -- Native findPlayerBySkillName scans orderedFrom(current,false), not
    -- raw alive seat order. Multiple healers can change target/intention policy.
    -- Incomplete foreign skill absence remains an explicit prior.
    for _, player in ipairs((room:getAllPlayers(false))) do
        if xueji_q(self, player, "hasSkill", "jijiu") then return player end
    end
end
sgs.ai_cardneed.xueji = function(to, card)
    return (to:getHandcardNum()) < 3 and (card:isRed())
end
ai_fill_skill.xueji = function(self, options, request)
    local inclusive = options and options.inclusive

    if not (self.player:isWounded()) then return nil end
    local cards = (self:sortByUseValue((self.player:getCards("he")),true))
    for _, card in ipairs(cards) do
        if (card:isRed()) then
            return (self:bindSkillCard("xueji",{(card:getKnownEffectiveId())},request,nil,"XuejiCard"))
        end
    end
end
local function xueji_target(self, card, who)
    local weapon = self.player:getWeapon()
    local distance
    if weapon and (weapon:getKnownEffectiveId()) == (card:getKnownEffectiveId()) then
        -- Donor formula: distance with the paid weapon's range as fix, against the current range.
        local row = AICardCatalog.get((weapon:objectName()))
        local range = known(row and row.weapon_range, "xueji.weapon_distance")
        distance = (self.player:distanceTo(who,range - (self.player:getAttackRange(false))))
    else
        local horse = self.player:getOffensiveHorse()
        if horse and (horse:getKnownEffectiveId()) == (card:getKnownEffectiveId()) then
            distance = (self.player:distanceTo(who,1))
        else distance = (self.player:distanceTo(who)) end
    end
    if distance and distance > (self.player:getAttackRange()) then return false end
    local function p(object, method, ...) return xueji_q(self, object, method, ...) end
    if (self:isEnemy(who)) and (self:damageIsEffective(who))
        and not (self:cantbeHurt(who)) and not (self:needToLoseHp(who)) then
        if not p(self.player, "hasSkills", "jueqing|gangzhi") then
            if p(who,"hasSkill","guixin") and (self.room:getAliveCount() >= 4 or not p(who,"faceUp"))
                and not p(who,"hasSkill","manjuan") then return false end
            if (p(who,"hasSkill","ganglie") or p(who,"hasSkill","neoganglie"))
                and (self.player:getHp()) == 1 and (self.player:getHandcardNum()) <= 2 then return false end
            if p(who,"hasSkill","jieming") then
                for _, enemy in ipairs(self.enemies) do
                    if p(enemy,"getHandcardNum") <= p(enemy,"getMaxHp") - 2 and not p(enemy,"hasSkill","manjuan") then return false end
                end
            end
            if p(who,"hasSkill","fangzhu") then
                for _, enemy in ipairs(self.enemies) do if not p(enemy,"faceUp") then return false end end
            end
            if p(who,"hasSkill","yiji") then
                local healer = xueji_healer(self,self.room)
                if healer and (self:isEnemy(healer)) and p(healer,"getHandcardNum") >= 3 then return false end
            end
        end
        return true
    elseif (self:isFriend(who)) then
        if p(who,"hasSkill","yiji") and not p(self.player,"hasSkills","jueqing|gangzhi") then
            local healer = xueji_healer(self,self.room)
            if (healer and (self:isFriend(healer)) and p(healer,"getHandcardNum") >= 3 and healer ~= self.player)
                or (p(who,"getLostHp") == 0 and p(who,"getMaxHp") >= 3) then return true end
        end
        if p(who,"hasSkill","hunzi") and p(who,"getMark","hunzi") == 0
            and p(who,"objectName") == ((self.player:getNextAlive()):objectName()) and p(who,"getHp") == 2 then return true end
        if (self:cantbeHurt(who)) and not (self:damageIsEffective(who))
            and not (p(who,"hasSkill","manjuan") and p(who,"getPhase") == sgs.Player_NotActive)
            and not (p(who,"hasSkill","kongcheng") and p(who,"isKongcheng")) then return true end
        return false
    end
    return false
end
ai_card_use.XuejiCard = function(self, card, use, request)
    if (self.player:getLostHp()) == 0 then return end
    local sorted = (self:sort(self.enemies))
    for i, enemy in ipairs(sorted) do self.enemies[i] = enemy end
    local choose = false
    for _, enemy in ipairs(self.enemies) do if xueji_target(self,card,enemy) then choose = true; break end end
    if not choose then
        for _, friend in ipairs(self.friends_noself) do if xueji_target(self,card,friend) then choose = true; break end end
    end
    if choose then
        use.card = card
        for _, enemy in ipairs(self.enemies) do
            if xueji_target(self,card,enemy) then
                use.to:append(enemy)
                if #use.to == (self.player:getLostHp()) then return end
            end
        end
        for _, friend in ipairs(self.friends_noself) do
            if xueji_target(self,card,friend) then
                use.to:append(friend)
                if #use.to == (self.player:getLostHp()) then return end
            end
        end
    end
end
sgs.ai_card_intention.XuejiCard = function(self, card, from, tos)
    local healer = xueji_healer(self,(from:getRoom()))
    local function p(object,method,...)return xueji_q(self,object,method,...)end
    for _, target in ipairs(tos) do
        local intention = 60
        if p(target,"hasSkill","yiji") and not p(from,"hasSkill","jueqing") then
            if healer and (self:isFriend(healer)) and p(healer,"getHandcardNum") >= 3
                and p(healer,"objectName") ~= p(from,"objectName") then intention = -30 end
            if p(target,"getLostHp") == 0 and p(target,"getMaxHp") >= 3 then intention = -10 end
        end
        if p(target,"hasSkill","hunzi") and p(target,"getMark","hunzi") == 0 then
            if p(target,"objectName") == ((from:getNextAlive()):objectName()) and p(target,"getHp") == 2 then intention = -20 end
        end
        if (self:cantbeHurt(target)) and not (self:damageIsEffective(target)) then intention = -20 end
        self:updateIntention(from,target,intention)
    end
end
sgs.ai_use_value.XuejiCard = 3
sgs.ai_use_priority.XuejiCard = 2.35

-- SP Bifa/Songci source sp-ai.lua:464–548. Append after SP local q/call.
local function sp_skill_request(self, request)
    if request and type(request.getActivationSkillName) ~= "function" then
        return AILegacyRequest.new(request,self.room)
    end
    return request
end
ai_skill_use["@@bifa"] = function(self,prompt,request)
    local cards = (self:sortByKeepValue((self.player:getHandcards())))
    self:sortInPlace(self.enemies, "hp")
    -- Source's #enemies<0 guard can never hold; retain its fall-through nil.
    for _, enemy in ipairs(self.enemies) do
        -- The source only reads pile cardinality. Closed pile IDs stay private.
        if (enemy:getPileCount("bifa")) == 0
            and not ((self:needToLoseHp(enemy)) and not (self:hasSkills(sgs.masochism_skill,enemy))) then
            local selected
            for _, card in ipairs(cards) do if (card:isKindOf("EquipCard")) then selected=card;break end end
            if not selected then
                for _, card in ipairs(cards) do
                    if (card:isKindOf("TrickCard")) and not ((card:isKindOf("Nullification")) and (self:getCardsNum("Nullification"))==1) then selected=card;break end
                end
            end
            if not selected then
                for _, card in ipairs(cards) do if (card:isKindOf("Slash")) then selected=card;break end end
            end
            if selected then
                local paid=(self:bindSkillCard("bifa",{(selected:getKnownEffectiveId())},sp_skill_request(self,request),nil,"BifaCard"))
                local use=AIUsePlan.new();use.card=paid;use.to:append(enemy)
                return (use:toAnswer())
            end
        end
    end
end
sgs.ai_skill_cardask["@bifa-give"] = function(self,data)
    local class=(data:toString())
    local cards=(self.player:getHandcards())
    if (self:needToLoseHp()) and not (self:hasSkills(sgs.masochism_skill)) then return "." end
    cards=(self:sortByUseValue(cards))
    for _,card in ipairs(cards) do
        if (card:isKindOf(class)) and not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) then
            return "$"..(card:getKnownEffectiveId())
        end
    end
    return "."
end
sgs.ai_card_intention.BifaCard=30
sgs.bifa_keep_value={Peach=6,Jink=5.1,Nullification=5,EquipCard=4.9,TrickCard=4.8}
ai_fill_skill.songci = function(self, options, request)
    local inclusive = options and options.inclusive

    return (self:bindSkillCard("songci",{},request,nil,"SongciCard"))
end
local function songci_mark(self,player)
    -- The per-giver key has a fixed public writer; getMark raises when its absence is not visible.
    return (player:getMark("songci"..(self.player:objectName())))
end
local function songci_card(self)
    local context=(self:getFillSkillContext("songci"))
    return (self:bindSkillCard("songci",{},context.request,nil,"SongciCard"))
end
ai_card_use.SongciCard = function(self, card, use, request)
    self:sortInPlace(self.friends, "handcard")
    for _,friend in ipairs(self.friends) do
        if songci_mark(self,friend)==0 and (friend:getHandcardNum())<(friend:getHp()) and (self:canDraw(friend)) then
            use.card=songci_card(self);use.to:append(friend);return
        end
    end
    self:sortInPlace(self.enemies, "handcard")
    -- Unlike sort, donor reverse replaces the list identity.
    local reverse={};for i=#self.enemies,1,-1 do reverse[#reverse+1]=self.enemies[i] end
    self.enemies=reverse
    for _,enemy in ipairs(self.enemies) do
        if songci_mark(self,enemy)==0 and (enemy:getHandcardNum())>(enemy:getHp()) and not (enemy:isNude())
            and (self:doDisCard(enemy,"he",true,2)) then
            use.card=songci_card(self);use.to:append(enemy);return
        end
    end
end
sgs.ai_use_value.SongciCard=3
sgs.ai_use_priority.SongciCard=3
sgs.ai_card_intention.SongciCard=function(self,card,from,tos)
    self:updateIntention(from,tos[1],(tos[1]:getHandcardNum())>(tos[1]:getHp()) and 80 or -80)
end

-- Fixed SP Xingwu response group: sp-ai.lua:550–657,674–728.
local function xingwu_skills(self, player, names)
    local value = player:hasSkills(names)
    if value ~= true and AIValue.isPlayer(player) then
        local view = rawget(player,"_view")
        if view.skills_complete ~= true then
            if (player:objectName())==(self.player:objectName()) then
                ai_unsupported("Xingwu owner skills are incomplete","xingwu.skills")
            end
            return (self:useKnowledgeEstimate({status="estimate",value=false,player=(player:objectName()),
                basis="sp.xingwu.undisclosed_skill_uses_visible_roster"},"xingwu.skills"))
        end
    end
    return known(value,"xingwu.skills")
end
local function xingwu_cost(self, include_equip)
    local cards = include_equip and (self.player:getCards("he")) or (self.player:getHandcards())
    if #cards<=1 and (self.player:getPileCount("xingwu"))==1 then return "." end
    local good_enemies={}
    for _,enemy in ipairs(self.enemies)do
        if (enemy:isMale()) and (((self:damageIsEffective(enemy)) and not (self:cantbeHurt(enemy,self.player,2)))
            or (not (self:damageIsEffective(enemy)) and #(enemy:getEquips())>0
                and not (#(enemy:getEquips())==1 and enemy:getArmor() and (self:needToThrowArmor(enemy)))))then
            good_enemies[#good_enemies+1]=enemy
        end
    end
    if #good_enemies==0 and ((self.player:getPileCount("xingwu"))>0
        or not xingwu_skills(self,self.player,"luoyan|olluoyan"))then return "." end
    local mark=(self.player:getMark("xingwu"))
    if type(mark)~="number"or mark~=math.floor(mark)then ai_unsupported("Xingwu colour mark is malformed","xingwu.mark")end
    -- Source bit32.band for low two bits; native marks are signed integers.
    local red_avail=math.floor(mark/2)%2==0
    local black_avail=mark%2==0
    cards=(self:sortByKeepValue(cards))
    local chosen,heart,to_save=nil,0,0
    for _,card in ipairs(cards)do
        if xingwu_skills(self,self.player,"tianxiang|oltianxiang") and (card:getSuit())==sgs.Card_Heart
            and heart<math.min((self.player:getHp()),2)then heart=heart+1
        elseif isCard("Jink",card,self.player)then
            if (self.player:hasSkill("liuli")) and (self.room:alivePlayerCount())>2 then
                for _,player in ipairs((self.room:getOtherPlayers(self.player)))do
                    if (self:canLiuli(self.player,player))then chosen=card;break end
                end
            end
            if not chosen and (self:getCardsNum("Jink"))>=2 then chosen=card end
        elseif to_save>(self.player:getMaxCards())
            or (not isCard("Peach",card,self.player) and not((self:isWeak()) and isCard("Analeptic",card,self.player)))then
            chosen=card
        else to_save=to_save+1 end
        if chosen then
            if (red_avail and (chosen:isRed()))or(black_avail and (chosen:isBlack()))then break
            else chosen=nil;to_save=to_save+1 end
        end
    end
    return chosen and "$"..(chosen:getKnownEffectiveId())or"."
end
sgs.ai_skill_cardask["@xingwu"]=function(self,data)return xingwu_cost(self,false)end
sgs.ai_skill_cardask["@tenyearxingwu-card"]=function(self,data)return sgs.ai_skill_cardask["@xingwu"](self,data)end
sgs.ai_skill_cardask["@olxingwu-card"]=function(self,data)return xingwu_cost(self,true)end
sgs.ai_skill_playerchosen.xingwu=function(self,targets)
    local enemies={}
    for _,enemy in ipairs(self.enemies)do if (enemy:isMale())then enemies[#enemies+1]=enemy end end
    if #enemies==0 then return targets[1]end
    local function score(enemy)
        local value=0
        if (self:damageIsEffective(enemy))then
            local damage=(enemy:hasArmorEffect("SilverLion"))and 1 or 2
            local hp=(enemy:getHp())
            if hp<=damage then value=5 else value=value+hp/(hp-damage)end
            if not (self:isGoodTarget(enemy,self.enemies))then value=value-2 end
            if (self:cantbeHurt(enemy,self.player,damage))then value=value-5 end
            if (enemy:isLord())then value=value+2 end
            if (enemy:hasArmorEffect("SilverLion"))then value=value-1.5 end
            if xingwu_skills(self,enemy,known(sgs.exclusive_skill,"exclusive_skill"))then value=value-1 end
            if xingwu_skills(self,enemy,known(sgs.masochism_skill,"masochism_skill"))then value=value-0.5 end
        end
        local equips=(enemy:getEquips())
        if #equips>0 then
            if xingwu_skills(self,enemy,known(sgs.lose_equip_skill,"lose_equip_skill"))then value=value-0.6*#equips end
            -- Donor intentionally asks needToThrowArmor() for self here.
            if enemy:getArmor()and (self:needToThrowArmor())then value=value-1.5 end
            if (enemy:hasArmorEffect("SilverLion"))then value=value-0.5 end
            if enemy:getWeapon()then value=value+0.8 end
            if enemy:getArmor()then value=value+1 end
            if enemy:getDefensiveHorse()then value=value+0.9 end
            if enemy:getOffensiveHorse()then value=value+0.7 end
            if self:getDangerousCard(enemy)then value=value+0.3 end
            if self:getValuableCard(enemy)then value=value+0.15 end
        end
        return value
    end
    local values={}
    for _,enemy in ipairs(enemies)do values[(enemy:objectName())]=score(enemy)end
    table.sort(enemies,function(a,b)return values[(a:objectName())]>values[(b:objectName())]end)
    return enemies[1]
end
sgs.ai_playerchosen_intention.xingwu=80
sgs.ai_playerchosen_intention.tenyearxingwu=80
sgs.ai_playerchosen_intention.olxingwu=80

-- sp-ai.lua:3981/3983. Count only the owner's actual Heart cards; preserve
-- the strict damage threshold and the Peach/ExNihilo-before-damage ordering.
ai_skill_invoke.andong = true
ai_skill_choice.andong = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local damage = (data:toDamage())
    local target = known(damage.to, "andong.damage.to")
    if (self:isFriend(target)) then return ai_choice_result(("prevent"), options) end
    local heart = 0
    for _, card in ipairs((self.player:getCards("h"))) do
        if (card:getSuit()) == sgs.Card_Heart then
            heart = heart + 1
            if (card:isKindOf("Peach")) or (card:isKindOf("ExNihilo")) then
                heart = heart + 1
            elseif (card:isDamageCard()) then heart = heart + 0.5 end
        end
    end
    if heart < 2 * (self:ajustDamage(damage.from,target,known(damage.damage, "andong.damage.damage"))) then return ai_choice_result(("get"), options) end
    return ai_choice_result(("prevent"), options)
end

-- sp-ai.lua:3975. Preserve the nested reason, nil pattern, and first result.
sgs.ai_skill_cardask["tuifeng-put"] = function(self, data)
    local selected = (self:askForDiscard("dummy",1,1,false,true))
    return #selected > 0 and ("$" .. selected[1]) or "."
end
-- sp-ai.lua:2213. This callback intentionally ignores its own optional flag
-- when delegating; it does not fabricate an outer inquiry's offered domain.
sgs.ai_skill_discard.jieyue = function(self, discard_num, min_num, optional, include_equip)
    local source = self.room:getCurrent()
    if source and (self:isEnemy(source)) then return {} end
    return (self:askForDiscard("dummy",discard_num,min_num,false,include_equip))
end

-- sp-ai.lua:1821/1838. Protection is chosen before paying one exact discard;
-- preserve the nested discard reason and the donor's first-result Peach veto.
sgs.ai_skill_cardask["@sp_zhenwei"] = function(self, data)
    local use = (data:toCardUse())
    local targets = known(use.to, "sp_zhenwei.targets")
    if #targets ~= 1 or not use.from or not use.card then return "." end
    local target, card = targets[1], use.card
    if not (self:isFriend(target)) or (self:isFriend(use.from)) then return "." end
    if (target:hasSkills("liuli|tianxiang")) and (card:isKindOf("Slash"))
        and (target:getHandcardNum()) > 1 then return "." end
    if (card:isKindOf("Slash")) and not (self:slashIsEffective(card,target,use.from)) then return "." end
    if (target:hasSkills(known(sgs.masochism_skill, "masochism_skill")))
        and not (self:isWeak(target)) then return "." end
    if (self.player:getHandcardNum()) + #(self.player:getEquips()) < 2
        and not (self:isWeak(target)) then return "." end
    local selected = self:askForDiscard("sp_zhenwei",1,1,false,true)
    if #selected == 0 then return "." end
    if not ((card:isKindOf("Slash")) and (self:isWeak(target))) then
        local cost = (self:getKnownCardById(selected[1]))
        if (cost:isKindOf("Peach")) then return "." end
    end
    return "$" .. selected[1]
end

ai_skill_choice.spzhenwei = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local use = (data:toCardUse())
    if (self:isWeak()) or (self.player:getHandcardNum()) < 2 then return ai_choice_result(("null"), options) end
    local card = known(use.card, "spzhenwei.card")
    local from = use.from
    if (card:isKindOf("TrickCard")) and (from:hasSkill("jizhi")) then return ai_choice_result(("draw"), options) end
    if (card:isKindOf("Slash")) and ((from:hasSkills("paoxiao|tianyi|xianzhen|jiangchi|fuhun|qiangwu"))
        or (from:getWeapon() and ((from:getWeapon()):isKindOf("Crossbow"))))
        and (self:getCardsNum("Jink")) == 0 then return ai_choice_result(("null"), options) end
    if (card:isKindOf("SupplyShortage")) then return ai_choice_result(("null"), options) end
    if (card:isKindOf("Slash")) and (self:getCardsNum("Jink")) == 0
        and (self.player:getLostHp()) > 0 then return ai_choice_result(("null"), options) end
    if (card:isKindOf("Indulgence")) and (self.player:getHandcardNum()) + 1 > (self.player:getHp()) then return ai_choice_result(("null"), options) end
    if (card:isKindOf("Slash")) and (from:hasSkills("tieqi|wushuang|yijue|liegong|mengjin|qianxi"))
        and not (from:getWeapon() and ((from:getWeapon()):isKindOf("Crossbow"))) then return ai_choice_result(("null"), options) end
    return ai_choice_result(("draw"), options)
end

-- sp-ai.lua:905–919. The random draw belongs to invoke, including a nil
-- Huashen answer; choice consumes the viewer-local handoff without another draw.
ai_skill_invoke.xiaode = function(self, options, request)
    local context = self:getDecisionContext()
    local skills = known(context.choice_body and context.choice_body.xiaode_skills, "xiaode.skills")
    if type(skills) ~= "table" then ai_unsupported("Xiaode skills are not a string list", "xiaode.skills") end
    for _, skill in ipairs(skills) do
        if type(skill) ~= "string" then ai_unsupported("Xiaode skill name is malformed", "xiaode.skills") end
    end
    local round = (self:playerGetRound(self.player))
    local chooser = ai_skill_choice.huashen
    if type(chooser) ~= "function" then ai_unsupported("Xiaode Huashen policy is unavailable", "xiaode.huashen") end
    local skill = chooser(self,{reason="huashen",choices=skills,xiaode_choice=math.random(1-round, 7-round),inquiry_scope="nested"},nil)
    if AIUnsupported.is(skill) then error(skill, 0) end
    self:setStrategyMemory("sp.xiaode_choice", skill or false)
    return (skill and true or false) or false
end
ai_skill_choice.xiaode = function(self, options, request)
    local skill, present = self:getStrategyMemory("sp.xiaode_choice")
    if not present then return ai_choice_result((nil), options) end -- donor initializes this global to nil
    return ai_choice_result((skill or nil), options)
end

-- Fixed sp-ai.lua:5306. Intention keeps its source short-circuit order.
sgs.ai_card_intention.FumanCard = function(self, card, from, tos)
    local to=tos[1]
    local intention=-70
    if hasManjuanEffect(to) then
        intention=0
    elseif self:needKongcheng(to,true) then
        intention=0
    end
    sgs.updateIntention(from,to,intention)
end

-- Registry values are continuity observations, never callback closures.
ai_response_scalar_choices=ai_response_scalar_choices or{}
local scalar_choices=ai_response_scalar_choices
local function scalar_host(op,key,row,from)
 if key~='xuhe'and key~='olxuhe'then ai_unsupported('Unaudited scalar choice name',key)end
 -- The donor keeps this choice in the gameplay VM's registry, which its SmartAI also
 -- writes; the isolated VM can neither read nor write it.
 ai_unsupported('gameplay SmartAI scalar choice registry is not available',key)
end
function scalar_choices.read(self,key)return scalar_host('read',key)end
function scalar_choices.write(self,key,row)scalar_host('record',key,row)end
function scalar_choices.copy(self,to,from)scalar_host('copy',to,nil,from)end
function scalar_choices.answer(self,key)
 local row=scalar_choices.read(self,key)
 if type(row.present)~='boolean'or(row.present and type(row.value)~='string')then ai_unsupported('Malformed scalar choice observation',key)end
 if row.present then return row.value end
end
ai_skill_choice.xuhe=function(self, options, request)return ai_choice_result((scalar_choices.answer(self,'xuhe')), options)end
-- The fixed doDisCard provider has legitimate bare-nil predicate branches.
-- Missing inputs and arbitrary replacement providers retain typed unknown.
local function xuhe_discard(self,player)
    local provider=self.doDisCard
    if type(provider)~="function"then ai_unsupported("SP response helper is unavailable","doDisCard")end
    local result=provider(self,player,"he")
    if AIUnsupported.is(result)then error(result,0)end
    if result==nil and SmartAIView.isKnownNilStrategyResult(self,"doDisCard",provider)then return nil end
    return known(result,"doDisCard")
end
-- sp-ai.lua8508: no write on either false path; preserve both scoring loops,
-- including friend/enemy predicate and canDraw short-circuit order.
ai_skill_invoke.xuhe=function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    if (self.player:getMaxHp())<=3 then return (false) or false end
    local num=0
    self.xuhe_choice=nil
    local can_dis=false
    for _,p in ipairs((self.room:getAlivePlayers()))do
        if (self.player:distanceTo(p))<=1 then
            if (self.player:canDiscard(p,'he'))then
                can_dis=true
                if (self:isFriend(p))then
                    num=num+1
                    if xuhe_discard(self,p)then num=num-2 end
                elseif (self:isEnemy(p))then
                    num=num-1
                    if xuhe_discard(self,p)then num=num+2 end
                end
            end
        end
    end
    if num<=0 and can_dis then
        scalar_choices.write(self,'xuhe',{known=true,present=true,value='discard'})
        return (true) or false
    end
    num=0
    for _,p in ipairs((self.room:getAlivePlayers()))do
        if (self.player:distanceTo(p))<=1 then
            if (self:isFriend(p))and (self:canDraw(p))then num=num+1
            elseif (self:isEnemy(p))and (self:canDraw(p))then num=num-1 end
        end
    end
    if num>=0 then
        scalar_choices.write(self,'xuhe',{known=true,present=true,value='draw'})
        return (true) or false
    end
    return (false) or false
end

-- Fixed sp-ai.lua9683–9733; only finite constructors differ from native userdata.
do
 local function req(object,name,...)
  if not object or type(object[name])~='function'then ai_unsupported('Faqi/Limu source helper missing',name)end
   local value=AIValue.callKnown(object,name,...)
  if AIUnsupported.is(value)then error(value,0)end
  if value==nil then ai_unsupported('Faqi/Limu source fact unknown',name)end
  return value
 end
 local function optional(self,name,...)
  if type(self[name])~='function'then ai_unsupported('Faqi/Limu source provider missing',name)end
   local value=AIValue.callKnown(self,name,...);if AIUnsupported.is(value)then error(value,0)end;return value
 end
 sgs.ai_use_revises.limu=function(self,card,use)
  if req(self.player,'hasWeapon','spear') and req(card,'isKindOf','Weapon')then return false end
  if req(card,'objectName')=='spear'then use.card=card;return true end
  if req(self,'getCardsNum','BasicCard','h')<1 then
   local ge=optional(self,'getCard','GlobalEffect')or optional(self,'getCard','AOE')
   if ge and req(ge,'isAvailable',self.player)then use.card=ge;return true end
  end
  if req(self.player,'hasWeapon','spear')then
   local cards=req(self.player,'getCards','he')
   cards=req(self,'sortByKeepValue',cards,nil,true)
   for _,c1 in sgs.list(cards)do
    if req(c1,'getSuit')==3 and req(self.player,'hasJudgeArea')and req(req(self.player,'getJudgingArea'),'isEmpty')then
     use.card=optional(self,'evaluateLimuSourceCard','limu',{req(c1,'getEffectiveId')})
     return true
    end
    if(req(c1,'isKindOf','Peach')or req(c1,'isKindOf','Analeptic'))and req(c1,'isAvailable',self.player)then
     use.card=c1;return true
    end
    if req(c1,'getTypeId')~=1 or req(c1,'isKindOf','Slash')or req(c1,'isAvailable',self.player)
      or req(req(self.player,'getEquips'),'contains',c1)then continue end
    for _,c2 in sgs.list(cards)do
     if req(c1,'getEffectiveId')==req(c2,'getEffectiveId')or req(req(self.player,'getEquips'),'contains',c2)then continue end
     local slash=req(self,'evaluateLimuSourceCard','spear',{req(c1,'getEffectiveId'),req(c2,'getEffectiveId')})
     if req(slash,'isAvailable',self.player)and req(self,'getUseValue',c2)<=req(self,'getUseValue',slash)then
      card=slash;return -- The fixed source assigns the local, NOT use.card.
     end
    end
   end
  end
 end
end

-- Fixed sp-ai.lua9634–9803; constructors remain readonly until selection.
do
  local function limu_query(o,k,...)
  if not o or type(o[k])~='function'then ai_unsupported('Limu source provider missing',k)end
   local v=AIValue.callKnown(o,k,...);if AIUnsupported.is(v)then error(v,0)end
  if v==nil then ai_unsupported('Limu source fact unknown',k)end;return v
 end
 local function opt(o,k,...)
  if not o or type(o[k])~='function'then ai_unsupported('Limu source provider missing',k)end
   local v=AIValue.callKnown(o,k,...);if AIUnsupported.is(v)then error(v,0)end;return v
 end
 ai_fill_skill.limu=function(self, options, request)
    local inclusive = options and options.inclusive

  local cards,peach={},0
  for _,c in sgs.list((self:addHandPile()))do
   if peach<2 and isCard('Peach',c,self.player)then peach=peach+1
   elseif (c:getSuit())==3 then
    local i=(self:evaluateLimuSourceCard('indulgence',{(c:getKnownEffectiveId())}))
    if not (self.player:isLocked(i))then table.insert(cards,c)end
   end
  end
  if #cards<1 then return end
   self:sortByKeepValue(cards)
  if (self:isWeak())then
   self:setPriorityValue('Peach',self:getSourcePriorityValue('LimuCard')+0.1,'limu')
   if (cards[1]:isKindOf('Peach'))and (cards[1]:isAvailable(self.player))then return cards[1]end
   return opt(self,'evaluateLimuSourceCard','limu',{(cards[1]:getKnownEffectiveId())},request)
  end
  local id=-1
  for _,c in ipairs(cards)do
   if isCard('Slash',c,self.player)then else id=(c:getKnownEffectiveId());break end
  end
  local slash_num=(self:getCardsNum('Slash'))
  if id<0 then id=(cards[1]:getKnownEffectiveId());slash_num=slash_num-1 end
  if slash_num>1 then
   for _,slash in ipairs((self:getCards('Slash')))do
    if (self:aiUseCard(slash)).card then return opt(self,'evaluateLimuSourceCard','limu',{id},request)end
   end
  end
 end
 ai_card_use.LimuCard=function(self, card, use, request)use.card=card end
 sgs.ai_use_priority.LimuCard=2.5
 sgs.ai_use_value.LimuCard=2.5
 -- ai_use_revises.limu retains the complete R41 body. Only its constructor
 -- adapter dispatches current Activate versus original Faqi AG context.
 sgs.ai_skill_carduse.limu=function(self,card,use)
  if not (card:isKindOf('Weapon'))then return false end
  local has_xuanjian=(self.player:hasWeapon('_xuanjian'))
  local has_spear=(self.player:hasWeapon('spear'))
  if has_xuanjian then return true end
  if has_spear then
   if (card:objectName())=='_xuanjian'then use.card=card;return true else return true end
  end
  if (card:objectName())=='_xuanjian'or (card:objectName())=='spear'then use.card=card;return true end
  return false
 end
 sgs.ai_card_priority.limu=function(self,card,v)
  if (card:objectName())=='_xuanjian'then return v+5 end
  if (card:objectName())=='spear'then return v+4 end
  if (self.player:hasWeapon('_xuanjian'))or (self.player:hasWeapon('spear'))then
   if (card:isKindOf('Slash'))then return v+3 end
  end
  if((self.player:hasWeapon('_xuanjian'))or (self.player:hasWeapon('spear')))and (card:getSuit())==sgs.Card_Diamond then return v+2 end
  return v
 end
end

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, owner, max_hp, query, context)
        if query(owner, "hasSkill", "xueji") then
            local lord
            if type(owner.isLord) == "function" then lord = owner:isLord() end
            if type(lord) ~= "boolean" then
                local role = type(owner.getRole) == "function" and owner:getRole() or nil
                if role == nil then return nil, true end
                lord = role == "lord"
            end
            return math.max(lord and 3 or 2, max_hp - (1)), true
        end
        return max_hp
    end
    local function policy_2(self, owner, max_hp, query, context)
        if query(owner, "hasSkill", "baobian") then
            local lord
            if type(owner.isLord) == "function" then lord = owner:isLord() end
            if type(lord) ~= "boolean" then
                local role = type(owner.getRole) == "function" and owner:getRole() or nil
                if role == nil then return nil, true end
                lord = role == "lord"
            end
            return math.max(lord and 3 or 2, max_hp - (math.max(0,max_hp-3))), true
        end
        return max_hp
    end
    local function policy_3(self, player, m, query, context)
        if query(player, "getPhase") < sgs.Player_Finish and query(player, "hasSkill", "yongsi")
            and not (query(player, "hasSkill", "keji") and not query(player, "hasFlag", "KejiSlashInPlayPhase"))
            and not query(player, "hasSkill", "conghui") then
            local kingdom_num = {}
            for _, ap in sgs.qlist(query(self.room, "getAlivePlayers")) do
                if table.contains(kingdom_num, query(ap, "getKingdom")) then continue end
                table.insert(kingdom_num, query(ap, "getKingdom"))
            end
            kingdom_num = #kingdom_num
            if kingdom_num > 0 then
                if query(player, "getCardCount") > kingdom_num then m = math.min(m, query(player, "getCardCount") - kingdom_num)
                else m = 0 end
            end
        end
        return m
    end
    local previous_1 = sgs.ai_getBestHp_skill["xueji"]
    sgs.ai_getBestHp_skill["xueji"] = function(owner, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "base" and context.rule == "xueji" then
                return policy_1(context.self, owner, context.value, context.query, context)
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(owner) end
    end
    sgs.declareValueHookStages("ai_getBestHp_skill", "xueji", {
        {phase="base", rule="xueji", order=2500, pairs_group="best_hp"},
    })
    local previous_2 = sgs.ai_getBestHp_skill["baobian"]
    sgs.ai_getBestHp_skill["baobian"] = function(owner, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "base" and context.rule == "baobian" then
                return policy_2(context.self, owner, context.value, context.query, context)
            end
            return context.value
        end
        if type(previous_2) == "function" then return previous_2(owner) end
    end
    sgs.declareValueHookStages("ai_getBestHp_skill", "baobian", {
        {phase="base", rule="baobian", order=2500, pairs_group="best_hp"},
    })
    local previous_3 = sgs.ai_getOverflow_skill["yongsi"]
    sgs.ai_getOverflow_skill["yongsi"] = function(self, player, m, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "after_max" and context.rule == "yongsi" then
                return policy_3(self, player, context.value, context.query, context)
            end
            return context.value
        end
        if type(previous_3) == "function" then return previous_3(self, player, m) end
    end
    sgs.declareValueHookStages("ai_getOverflow_skill", "yongsi", {
        {phase="after_max", rule="yongsi", order=2900},
    })
end)()

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["can_lose_hostile.flyuqing"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(self, "isWeak", to) then
                    if damage_call(from, "getMark", "@flyuqing") > 0
                        and damage_call(from, "hasSkill", "zhenyi") then return nil, true end
                    if damage_call(from, "hasSkill", "pojun") then return nil, true end
                end
        return value
    end
    sgs.ai_need_damaged["can_lose_hostile.flyuqing"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "can_lose_hostile" and context.rule == "flyuqing" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "can_lose_hostile.flyuqing", {
        {phase="can_lose_hostile", order=3, rule="flyuqing"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_need_damaged["jiedao"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(from, "getMark", "jiedao-Clear") > 0
                    and damage_call(from, "getLostHp") >= damage_call(to, "getHp")
                    and damage_call(from, "hasSkill", "jiedao") then return nil, true end
        return value
    end
    sgs.ai_need_damaged["jiedao"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "can_lose_hostile" and context.rule == "jiedao_Clear" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "jiedao", {
        {phase="can_lose_hostile", order=4, rule="jiedao_Clear"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_need_damaged["shanzhuan"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if #damage_call(to, "getJudgingArea") < 1
                    and damage_call(from, "hasSkill", "shanzhuan") then return nil, true end
        return value
    end
    sgs.ai_need_damaged["shanzhuan"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "can_lose_hostile" and context.rule == "shanzhuan" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "shanzhuan", {
        {phase="can_lose_hostile", order=5, rule="shanzhuan"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_need_damaged["xionghuo"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(to, "getMark", "@brutal") > 0
                    and damage_call(from, "hasSkill", "xionghuo") then return nil, true end
        return value
    end
    sgs.ai_need_damaged["xionghuo"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "can_lose_weak" and context.rule == "brutal" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "xionghuo", {
        {phase="can_lose_weak", order=1, rule="brutal"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_need_damaged["kannan"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if card and damage_call(card, "isKindOf", "Slash")
                and damage_call(from, "getMark", "&kannan") >= damage_call(to, "getHp") then return nil, true end
        return value
    end
    sgs.ai_need_damaged["kannan"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "can_lose_after_lethal" and context.rule == "kannan" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "kannan", {
        {phase="can_lose_after_lethal", order=1, rule="kannan"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_need_damaged["need_hp_active_best.qinxue_canshi"]
    local policy = function(self, from, to, card, context)
        local bh, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        local count = damage_call(self.room,"getModePlayerCount")
        if damage_call(to,"hasSkill","qinxue") and (damage_call(self,"getOverflow")==1 and count>=7 or damage_call(self,"getOverflow")==2 and count<7)
        		or damage_call(to,"hasSkill","canshi") and count>=3 then bh = math.min(bh,damage_call(to,"getMaxHp")-1) end
        return bh
    end
    sgs.ai_need_damaged["need_hp_active_best.qinxue_canshi"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_active_best" and context.rule == "qinxue_canshi" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "need_hp_active_best.qinxue_canshi", {
        {phase="need_hp_active_best", order=2, rule="qinxue_canshi"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["good_survival.ganglie_group"]
    local policy = function(self, to, context)
        local value, good_query = context.value, context.query
        local card, damageNum, apn, value_known = context.extra[1], context.extra[2], context.extra[3], context.extra[4]
        if good_query(to, "hasSkills", "neoganglie|xuehen|xueji")
        		and good_query(self, "isWeak", self.friends) then return nil, true end
        return value
    end
    sgs.ai_target_damage["good_survival.ganglie_group"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "good_survival" and context.rule == "ganglie_group" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "good_survival.ganglie_group", {
        {phase="good_survival", order=4, rule="ganglie_group"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["just_damage_after_relation.zhiman"]
    local policy = function(self, to, context)
        local value, strategy_call = context.value, context.query
        local from, is_slash, lock, same_player, strategy_known = context.extra[1], context.extra[2], context.extra[3], context.extra[4], context.extra[5]
        if strategy_call(from, "hasSkills", "zhiman|tenyearzhiman") and strategy_call(self, "doDisCard", to, "e") then return true, true end
        return value
    end
    sgs.ai_target_damage["just_damage_after_relation.zhiman"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "just_damage_after_relation" and context.rule == "zhiman" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "just_damage_after_relation.zhiman", {
        {phase="just_damage_after_relation", order=6, rule="zhiman"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_defense_slash["aocai"]
    local policy = function(self, to, observer, context)
        local call, state = context.query, context.extra[1]
        local defense = context.value
        if call(to, "getPhase") == sgs.Player_NotActive and call(to, "hasSkill", "aocai") then defense = defense + .5 end
        return defense
    end
    sgs.ai_defense_slash["aocai"] = function(self, to, observer, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "after_known_jink" and context.rule == "slash_defense.aocai" then
                return policy(self, to, observer, context)
            end
            if type(previous) == "function" then return previous(self, to, observer, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to, observer) end
    end
    sgs.declareValueHookStages("ai_defense_slash", "aocai", {
        {phase="after_known_jink", order=11, rule="slash_defense.aocai"},
    })
end)()
end
