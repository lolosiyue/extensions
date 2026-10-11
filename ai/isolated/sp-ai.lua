-- SP response policies from the effective fixed source b6025acc.
-- Native source scopes authorize cards; these callbacks only choose policy.
local function known(value, key)
    if AIUnsupported.is(value) then error(value, 0) end
    if value == nil then ai_unsupported("SP response fact is not projected", key) end
    return value
end
local function call(object, method, ...)
    if not object or type(object[method]) ~= "function" then
        ai_unsupported("SP response helper is unavailable", method)
    end
    local result = table.pack(object[method](object, ...))
    if AIUnsupported.is(result[1]) then error(result[1], 0) end
    return table.unpack(result, 1, result.n)
end
local function q(object, method, ...) return known(call(object, method, ...), method) end

-- sp-ai.lua:921. The SkillCard declaration belongs to the policy object;
-- the response resolver supplies the independently validated ordinary receipt.
sgs.ai_cardsview_valuable.aocai = function(self, class_name, player)
    local declaration
    if class_name == "Slash" then declaration = "slash"
    elseif class_name == "Peach" or class_name == "Analeptic" then
        local dying = call(self.room, "getCurrentDyingPlayer")
        if dying and q(dying, "objectName") == q(player, "objectName") then
            declaration = "peach+analeptic"
            if q(player, "getMark", "Global_PreventPeach") > 0 then declaration = "analeptic" end
        else declaration = class_name == "Analeptic" and "analeptic" or "peach" end
    end
    if declaration then
        return {skill="aocai",legacy_class="AocaiCard",subcards={},user_string=declaration}
    end
end

-- Both invoke writers are live under the fixed but package-dependent load
-- order. Capture their actual source once; never revive an overwritten body.
local function invoke_variant(self)
    local capture = self.world.strategy_facts and self.world.strategy_facts.audited_aliases
    local rows = type(capture) == "table" and capture.source_variants
    local row = type(rows) == "table" and rows["ai_skill_invoke.aocai"]
    if not capture or capture.captured ~= true or type(row) ~= "table" or row.known ~= true then
        ai_unsupported("Aocai effective invoke source is unknown", "aocai.invoke")
    end
    if row.present == false then return nil end
    local sources = {sp={"@lua/ai/sp-ai.lua",940},ol_qifu={"@lua/ai/ol_qifu-ai.lua",1}}
    local origin = sources[row.variant]
    if row.present ~= true or row.type ~= "function" or not origin
        or row.source ~= origin[1] or row.line ~= origin[2] then
        ai_unsupported("Aocai invoke source has no audited policy", "aocai.invoke")
    end
    return row.variant
end
sgs.ai_skill_invoke.aocai = function(self, data)
    local variant = invoke_variant(self)
    if variant == nil then
        if type(ai_skill_invoke_default) ~= "function" then
            ai_unsupported("Aocai absent-hook common default is unavailable", "aocai.invoke")
        end
        return known(ai_skill_invoke_default(self, self.request and self.request.options), "aocai.invoke.default")
    end
    if variant == "ol_qifu" then return true end
    local context = q(self, "getDecisionContext")
    local invocation = context.aocai_invoke
    if type(invocation) ~= "table" or invocation.known ~= true
        or not AIValue.isList(invocation.asked) then
        ai_unsupported("Aocai original string-list invocation is not projected", "aocai.invoke")
    end
    local asked = invocation.asked
    -- Common askForCard owns hooks, nullfilter and source ordering. The nested
    -- inquiry must not be replaced with a hand count or legal-candidate test.
    return q(self, "askForCard", asked[1], asked[2], 1) ~= "."
end

-- sp-ai.lua:947. Only this question's disclosed AG cards are inspected.
sgs.ai_skill_askforag.aocai = function(self, card_ids)
    local card = q(self, "getChoiceCard", card_ids[1])
    if q(card, "isKindOf", "Jink") and q(self.player, "hasFlag", "dahe") then
        for _, id in ipairs(card_ids) do
            if q(q(self, "getChoiceCard", id), "getSuit") == sgs.Card_Heart then return id end
        end
        return -1
    end
    return card_ids[1]
end

-- sp-ai.lua:958. Missing foreign flag knowledge remains explicit.
sgs.ai_skill_defense.aocai = function(self, player)
    if not q(player, "hasFlag", "CurrentPlayer") then return 0.5 end
    return 0
end

-- sp-ai.lua:3. Preserve the offered-domain defense ordering and first match.
sgs.weapon_range.SPMoonSpear = 3
sgs.ai_skill_playerchosen.sp_moonspear = function(self, targets)
    local ordered = {}
    for i, player in ipairs(targets) do ordered[i] = player end
    ordered = q(self, "sort", ordered, "defense")
    for _, target in ipairs(ordered) do
        if q(self, "isEnemy", target) and q(self, "damageIsEffective", target)
            and q(self, "isGoodTarget", target, ordered) then return target end
    end
end
sgs.ai_playerchosen_intention.sp_moonspear = 80

-- sp-ai.lua:66. This comparator deliberately keeps donor call order, including
-- the first out-of-range GudingBlade break and repeated auxiliary evaluations.
sgs.ai_skill_discard.yongsi = function(self, discard_num, min_num, optional, include_equip)
    if optional then return {} end
    local flag = "h"
    local equips = q(self.player, "getEquips")
    if include_equip and not (#equips == 0 or q(self.player, "isJilei", equips[1])) then flag = flag .. "e" end
    local cards = {}
    for i, card in ipairs(q(self.player, "getCards", flag)) do cards[i] = card end
    local function auxiliary(card)
        local place = q(self.room, "getCardPlace", q(card, "getEffectiveId"))
        if place == sgs.Player_PlaceEquip then
            if q(card, "isKindOf", "SilverLion") then
                for _, player in ipairs(q(self.room, "getOtherPlayers", self.player)) do
                    local blade = call(player, "getWeapon")
                    if blade and q(blade, "isKindOf", "GudingBlade") then
                        if q(player, "inMyAttackRange", self.player) then
                            if q(self, "isEnemy", player, self.player) then return 6 end
                        else break end
                    end
                end
                if q(self.player, "isWounded") then return -2 end
            elseif q(card, "isKindOf", "Weapon") and q(self.player, "getHandcardNum") < discard_num + 2
                and not q(self, "needKongcheng") then return 0
            elseif q(card, "isKindOf", "OffensiveHorse") and q(self.player, "getHandcardNum") < discard_num + 2
                and not q(self, "needKongcheng") then return 0
            elseif q(card, "isKindOf", "OffensiveHorse") then return 1
            elseif q(card, "isKindOf", "Weapon") then return 2
            elseif q(card, "isKindOf", "DefensiveHorse") then return 3
            elseif q(self, "hasSkills", "bazhen|yizhong") and q(card, "isKindOf", "Armor") then return 0
            elseif q(card, "isKindOf", "Armor") then return 4 end
        elseif q(self, "hasSkills", known(sgs.lose_equip_skill, "lose_equip_skill")) then return 5
        else return 0 end
        return 0
    end
    table.sort(cards, function(a, b)
        if auxiliary(a) ~= auxiliary(b) then return auxiliary(a) < auxiliary(b) end
        return q(self, "getKeepValue", a) < q(self, "getKeepValue", b)
    end)
    local least = min_num
    if discard_num - min_num > 1 then least = discard_num - 1 end
    local selected = {}
    for _, card in ipairs(cards) do
        if not q(self.player, "isJilei", card) then selected[#selected + 1] = q(card, "getId") end
        if (q(self.player, "hasSkill", "qinyin") and #selected >= least) or #selected >= discard_num then break end
    end
    return selected
end
sgs.ai_skill_defense.yongsi = -2

-- sp-ai.lua:133. The use descriptor is from this inquiry; turn order uses the
-- original seat difference modulo the complete living-player count.
sgs.ai_skill_invoke.danlao = function(self, data)
    local effect = q(data, "toCardUse")
    local current = q(self.room, "getCurrent")
    local card = known(effect.card, "danlao.use.card")
    if q(card, "isKindOf", "GodSalvation") and q(self.player, "isWounded")
        or q(card, "isKindOf", "ExNihilo") then return false
    elseif q(card, "isKindOf", "AmazingGrace")
        and (q(self.player, "getSeat") - q(current, "getSeat")) % q(self.room, "alivePlayerCount")
            < q(self.room, "alivePlayerCount") / 2 then return false end
    return true
end

-- sp-ai.lua:146/153. The observed damage source belongs to this AI's cache;
-- foreign private limitations are an explicitly recorded knowledge estimate.
sgs.ai_skill_invoke.jilei = function(self, data)
    local damage = call(data, "toDamage")
    if AIUnsupported.is(damage) then error(damage, 0) end
    if damage == nil then
        local context = q(self, "getDecisionContext")
        if context.damage_present == false then return false end
        ai_unsupported("Jilei inquiry damage presence is not projected", "jilei.damage")
    end
    local source = known(damage.from, "jilei.damage.from")
    call(self, "setStrategyMemory", "sp.jilei_source", q(source, "objectName"))
    return q(self, "isEnemy", source)
end
sgs.ai_skill_choice.jilei = function(self, choices)
    local name, present = call(self, "getStrategyMemory", "sp.jilei_source")
    if AIUnsupported.is(name) then error(name, 0) end
    if present ~= true or type(name) ~= "string" then
        ai_unsupported("Jilei previous damage source is not known to this AI", "jilei.source")
    end
    local source = q(self.room, "findPlayerByObjectName", name, true)
    if q(self, "hasCrossbowEffect", source) and q(source, "inMyAttackRange", self.player) then return "BasicCard" end
    local limited
    if name == q(self.player, "objectName") then
        local facts = self.world.strategy_facts and self.world.strategy_facts.sp_jilei
        if type(facts) ~= "table" then ai_unsupported("Jilei owner hand limitation is missing", "jilei.owner_hand_limit") end
        limited = known(facts.owner_ex_nihilo_hand_limited, "jilei.owner_hand_limit")
        if type(limited) ~= "boolean" then ai_unsupported("Jilei owner hand limitation is malformed", "jilei.owner_hand_limit") end
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
            mark = call(source, "getMark", "@jilei_trick")
        end
        if AIUnsupported.is(mark) then error(mark, 0) end
        if type(mark) == "number" and mark > 0 then limited = true
        else
            limited = q(self, "useKnowledgeEstimate", {
                status="estimate",value=false,player=name,
                basis="unobserved_private_card_limitation_inactive_prior"
            }, "sp.jilei.foreign_hand_limit")
        end
    end
    return limited and "BasicCard" or "TrickCard"
end

-- sp-ai.lua:1757–1818. Planning deliberately receives the original ordinary
-- Slash: useCardThunderSlash is the donor's thin useCardSlash forwarding method.
local function fulu_spec(card, id)
    if id == nil then
        q(card, "getSuitString"); q(card, "getNumberString"); id = q(card, "getEffectiveId")
    end
    return {name="thunder_slash",skill="fulu",suit=q(card,"getSuit"),
        number=q(card,"getNumber"),subcards={id}}
end
sgs.ai_view_as.fulu = function(card, player, place)
    q(card, "getSuitString"); q(card, "getNumberString"); local id = q(card, "getEffectiveId")
    known(place, "fulu.place")
    if place ~= sgs.Player_PlaceSpecial and q(card, "getClassName") == "Slash"
        and not q(card, "hasFlag", "using") then return fulu_spec(card, id) end
end
sgs.ai_skill_invoke.fulu = function(self, data)
    local use = q(data, "toCardUse")
    for _, player in ipairs(known(use.to, "fulu.targets")) do
        if q(self, "isEnemy", player) and q(self, "isGoodTarget", player, self.enemies,
            known(use.card, "fulu.card")) then return true end
    end
    return false
end
sgs.ai_fill_skill.fulu = function(self, inclusive, request)
    local cards = q(self, "sortByUseValue", q(self, "addHandPile"), true)
    local slash
    for _, card in ipairs(cards) do
        if q(card, "getClassName") == "Slash" then slash = card; break end
    end
    if not slash then return nil end
    local use = AIUsePlan.new(); use.isDummy = true
    call(self, "useCardThunderSlash", slash, use)
    if not use.card or #use.to == 0 then return nil end
    local data = {toCardUse=function()return {from=self.player,to=use.to,card=slash}end}
    if not sgs.ai_skill_invoke.fulu(self, data) then return nil end
    return q(self, "bindTurnConversion", "fulu", "ThunderSlash", fulu_spec(slash), request)
end
sgs.ai_skill_invoke.zhuji = function(self, data)
    local damage = q(data, "toDamage")
    if q(self, "isFriend", known(damage.from, "zhuji.from"))
        and not q(self, "isFriend", known(damage.to, "zhuji.to")) then return true end
    return false
end

-- SP Xueji connected policy group; append after the shared SP local q/call.
-- Original donor sp-ai.lua:321–461, with authority binding and lawful knowledge.
local function xueji_q(self, object, method, ...)
    if method == "getMark" and AIValue.isPlayer(object) then method = "getStrategyMark" end
    local value = call(object, method, ...)
    if (value == false or value == nil) and (method == "hasSkill" or method == "hasSkills") and AIValue.isPlayer(object) then
        local view = rawget(object, "_view")
        if view.skills_complete ~= true then
            if q(object, "objectName") == q(self.player, "objectName") then
                ai_unsupported("Xueji owner skill roster is incomplete", "xueji.skills")
            end
            return q(self, "useKnowledgeEstimate", {status="estimate",value=false,player=q(object,"objectName"),
                basis="sp.xueji.undisclosed_skill_uses_visible_roster"}, "xueji.skills")
        end
    end
    return known(value, method)
end
local function xueji_healer(self, room)
    -- Native findPlayerBySkillName scans orderedFrom(current,false), not
    -- raw alive seat order. Multiple healers can change target/intention policy.
    -- Incomplete foreign skill absence remains an explicit prior.
    for _, player in ipairs(q(room, "getAllPlayers", false)) do
        if xueji_q(self, player, "hasSkill", "jijiu") then return player end
    end
end
sgs.ai_cardneed.xueji = function(to, card)
    return q(to, "getHandcardNum") < 3 and q(card, "isRed")
end
sgs.ai_fill_skill.xueji = function(self, inclusive, request)
    if not q(self.player, "isWounded") then return nil end
    local cards = q(self, "sortByUseValue", q(self.player, "getCards", "he"), true)
    for _, card in ipairs(cards) do
        if q(card, "isRed") then
            return q(self, "bindSkillCard", "xueji", {q(card,"getEffectiveId")}, request, nil, "XuejiCard")
        end
    end
end
local function xueji_target(self, card, who)
    local weapon = call(self.player, "getWeapon")
    local distance
    if weapon and q(weapon, "getEffectiveId") == q(card, "getEffectiveId") then
        local facts = self.world.strategy_facts and self.world.strategy_facts.sp_xueji
        local row = type(facts) == "table" and facts.weapon_cost_distance
        if type(row) ~= "table" or row.known ~= true or row.cost_id ~= q(weapon,"getEffectiveId")
            or type(row.exceeds_range) ~= "table" or not self.request or self.request.kind ~= "activate" then
            ai_unsupported("Xueji source weapon-cost distance formula is not projected", "xueji.weapon_distance")
        end
        local exceeds = known(row.exceeds_range[q(who,"objectName")], "xueji.weapon_distance")
        if type(exceeds) ~= "boolean" then ai_unsupported("Xueji weapon-cost reach fact is not boolean", "xueji.weapon_distance") end
        if exceeds then return false end
    else
        local horse = call(self.player, "getOffensiveHorse")
        if horse and q(horse, "getEffectiveId") == q(card, "getEffectiveId") then
            distance = q(self.player, "distanceTo", who, 1)
        else distance = q(self.player, "distanceTo", who) end
    end
    if distance and distance > q(self.player, "getAttackRange") then return false end
    local function p(object, method, ...) return xueji_q(self, object, method, ...) end
    if q(self, "isEnemy", who) and q(self, "damageIsEffective", who)
        and not q(self, "cantbeHurt", who) and not q(self, "needToLoseHp", who) then
        if not p(self.player, "hasSkills", "jueqing|gangzhi") then
            if p(who,"hasSkill","guixin") and (self.room:getAliveCount() >= 4 or not p(who,"faceUp"))
                and not p(who,"hasSkill","manjuan") then return false end
            if (p(who,"hasSkill","ganglie") or p(who,"hasSkill","neoganglie"))
                and q(self.player,"getHp") == 1 and q(self.player,"getHandcardNum") <= 2 then return false end
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
                if healer and q(self,"isEnemy",healer) and p(healer,"getHandcardNum") >= 3 then return false end
            end
        end
        return true
    elseif q(self,"isFriend",who) then
        if p(who,"hasSkill","yiji") and not p(self.player,"hasSkills","jueqing|gangzhi") then
            local healer = xueji_healer(self,self.room)
            if (healer and q(self,"isFriend",healer) and p(healer,"getHandcardNum") >= 3 and healer ~= self.player)
                or (p(who,"getLostHp") == 0 and p(who,"getMaxHp") >= 3) then return true end
        end
        if p(who,"hasSkill","hunzi") and p(who,"getMark","hunzi") == 0
            and p(who,"objectName") == q(q(self.player,"getNextAlive"),"objectName") and p(who,"getHp") == 2 then return true end
        if q(self,"cantbeHurt",who) and not q(self,"damageIsEffective",who)
            and not (p(who,"hasSkill","manjuan") and p(who,"getPhase") == sgs.Player_NotActive)
            and not (p(who,"hasSkill","kongcheng") and p(who,"isKongcheng")) then return true end
        return false
    end
    return false
end
sgs.ai_skill_use_func.XuejiCard = function(card, use, self)
    if q(self.player,"getLostHp") == 0 then return end
    local sorted = q(self,"sort",self.enemies)
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
                if #use.to == q(self.player,"getLostHp") then return end
            end
        end
        for _, friend in ipairs(self.friends_noself) do
            if xueji_target(self,card,friend) then
                use.to:append(friend)
                if #use.to == q(self.player,"getLostHp") then return end
            end
        end
    end
end
sgs.ai_card_intention.XuejiCard = function(self, card, from, tos)
    local healer = xueji_healer(self,q(from,"getRoom"))
    local function p(object,method,...)return xueji_q(self,object,method,...)end
    for _, target in ipairs(tos) do
        local intention = 60
        if p(target,"hasSkill","yiji") and not p(from,"hasSkill","jueqing") then
            if healer and q(self,"isFriend",healer) and p(healer,"getHandcardNum") >= 3
                and p(healer,"objectName") ~= p(from,"objectName") then intention = -30 end
            if p(target,"getLostHp") == 0 and p(target,"getMaxHp") >= 3 then intention = -10 end
        end
        if p(target,"hasSkill","hunzi") and p(target,"getMark","hunzi") == 0 then
            if p(target,"objectName") == q(q(from,"getNextAlive"),"objectName") and p(target,"getHp") == 2 then intention = -20 end
        end
        if q(self,"cantbeHurt",target) and not q(self,"damageIsEffective",target) then intention = -20 end
        call(self,"updateIntention",from,target,intention)
    end
end
sgs.ai_use_value.XuejiCard = 3
sgs.ai_use_priority.XuejiCard = 2.35

-- SP Bifa/Songci source sp-ai.lua:464–548. Append after SP local q/call.
local function sp_sort_players(self, players, key)
    local ordered = q(self,"sort",players,key)
    for i, player in ipairs(ordered) do players[i] = player end
    return players
end
local function sp_skill_request(self, request)
    if request and type(request.getActivationSkillName) ~= "function" then
        return AILegacyRequest.new(request,self.room)
    end
    return request
end
ai_skill_use["@@bifa"] = function(self,prompt,request)
    local cards = q(self,"sortByKeepValue",q(self.player,"getHandcards"))
    sp_sort_players(self,self.enemies,"hp")
    -- Source's #enemies<0 guard can never hold; retain its fall-through nil.
    for _, enemy in ipairs(self.enemies) do
        -- The source only reads pile cardinality. Closed pile IDs stay private.
        if q(enemy,"getPileCount","bifa") == 0
            and not (q(self,"needToLoseHp",enemy) and not q(self,"hasSkills",sgs.masochism_skill,enemy)) then
            local selected
            for _, card in ipairs(cards) do if q(card,"isKindOf","EquipCard") then selected=card;break end end
            if not selected then
                for _, card in ipairs(cards) do
                    if q(card,"isKindOf","TrickCard") and not (q(card,"isKindOf","Nullification") and q(self,"getCardsNum","Nullification")==1) then selected=card;break end
                end
            end
            if not selected then
                for _, card in ipairs(cards) do if q(card,"isKindOf","Slash") then selected=card;break end end
            end
            if selected then
                local paid=q(self,"bindSkillCard","bifa",{q(selected,"getEffectiveId")},sp_skill_request(self,request),nil,"BifaCard")
                local use=AIUsePlan.new();use.card=paid;use.to:append(enemy)
                return q(use,"toAnswer")
            end
        end
    end
end
sgs.ai_skill_cardask["@bifa-give"] = function(self,data)
    local class=q(data,"toString")
    local cards=q(self.player,"getHandcards")
    if q(self,"needToLoseHp") and not q(self,"hasSkills",sgs.masochism_skill) then return "." end
    cards=q(self,"sortByUseValue",cards)
    for _,card in ipairs(cards) do
        if q(card,"isKindOf",class) and not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) then
            return "$"..q(card,"getEffectiveId")
        end
    end
    return "."
end
sgs.ai_card_intention.BifaCard=30
sgs.bifa_keep_value={Peach=6,Jink=5.1,Nullification=5,EquipCard=4.9,TrickCard=4.8}
sgs.ai_fill_skill.songci = function(self,inclusive,request)
    return q(self,"bindSkillCard","songci",{},request,nil,"SongciCard")
end
local function songci_mark(self,player)
    -- The per-giver key has a fixed public writer. Read only this viewer's
    -- projected column; foreign prefixes and private V2 recipient state stay out.
    if AIValue.isPlayer(player) then
        local facts=self.world.strategy_facts and self.world.strategy_facts.sp_songci
        local marks=type(facts)=="table" and facts.given_marks
        local mark=type(marks)=="table" and marks[q(player,"objectName")]
        if type(mark)~="number" or mark~=math.floor(mark) then
            ai_unsupported("Songci public per-giver mark is not projected","songci.mark")
        end
        return mark
    end
    return q(player,"getMark","songci"..q(self.player,"objectName"))
end
local function songci_card(self)
    local context=q(self,"getFillSkillContext","songci")
    return q(self,"bindSkillCard","songci",{},context.request,nil,"SongciCard")
end
sgs.ai_skill_use_func.SongciCard = function(card,use,self)
    sp_sort_players(self,self.friends,"handcard")
    for _,friend in ipairs(self.friends) do
        if songci_mark(self,friend)==0 and q(friend,"getHandcardNum")<q(friend,"getHp") and q(self,"canDraw",friend) then
            use.card=songci_card(self);use.to:append(friend);return
        end
    end
    sp_sort_players(self,self.enemies,"handcard")
    -- Unlike sort, donor reverse replaces the list identity.
    local reverse={};for i=#self.enemies,1,-1 do reverse[#reverse+1]=self.enemies[i] end
    self.enemies=reverse
    for _,enemy in ipairs(self.enemies) do
        if songci_mark(self,enemy)==0 and q(enemy,"getHandcardNum")>q(enemy,"getHp") and not q(enemy,"isNude")
            and q(self,"doDisCard",enemy,"he",true,2) then
            use.card=songci_card(self);use.to:append(enemy);return
        end
    end
end
sgs.ai_use_value.SongciCard=3
sgs.ai_use_priority.SongciCard=3
sgs.ai_card_intention.SongciCard=function(self,card,from,tos)
    call(self,"updateIntention",from,tos[1],q(tos[1],"getHandcardNum")>q(tos[1],"getHp") and 80 or -80)
end

-- Fixed SP Xingwu response group: sp-ai.lua:550–657,674–728.
local function xingwu_skills(self, player, names)
    local value = call(player,"hasSkills",names)
    if value ~= true and AIValue.isPlayer(player) then
        local view = rawget(player,"_view")
        if view.skills_complete ~= true then
            if q(player,"objectName")==q(self.player,"objectName") then
                ai_unsupported("Xingwu owner skills are incomplete","xingwu.skills")
            end
            return q(self,"useKnowledgeEstimate",{status="estimate",value=false,player=q(player,"objectName"),
                basis="sp.xingwu.undisclosed_skill_uses_visible_roster"},"xingwu.skills")
        end
    end
    return known(value,"xingwu.skills")
end
local function xingwu_cost(self, include_equip)
    local cards = include_equip and q(self.player,"getCards","he") or q(self.player,"getHandcards")
    if #cards<=1 and q(self.player,"getPileCount","xingwu")==1 then return "." end
    local good_enemies={}
    for _,enemy in ipairs(self.enemies)do
        if q(enemy,"isMale") and ((q(self,"damageIsEffective",enemy) and not q(self,"cantbeHurt",enemy,self.player,2))
            or (not q(self,"damageIsEffective",enemy) and #q(enemy,"getEquips")>0
                and not (#q(enemy,"getEquips")==1 and call(enemy,"getArmor") and q(self,"needToThrowArmor",enemy))))then
            good_enemies[#good_enemies+1]=enemy
        end
    end
    if #good_enemies==0 and (q(self.player,"getPileCount","xingwu")>0
        or not xingwu_skills(self,self.player,"luoyan|olluoyan"))then return "." end
    local mark=q(self.player,"getMark","xingwu")
    if type(mark)~="number"or mark~=math.floor(mark)then ai_unsupported("Xingwu colour mark is malformed","xingwu.mark")end
    -- Source bit32.band for low two bits; native marks are signed integers.
    local red_avail=math.floor(mark/2)%2==0
    local black_avail=mark%2==0
    cards=q(self,"sortByKeepValue",cards)
    local chosen,heart,to_save=nil,0,0
    for _,card in ipairs(cards)do
        if xingwu_skills(self,self.player,"tianxiang|oltianxiang") and q(card,"getSuit")==sgs.Card_Heart
            and heart<math.min(q(self.player,"getHp"),2)then heart=heart+1
        elseif isCard("Jink",card,self.player)then
            if q(self.player,"hasSkill","liuli") and q(self.room,"alivePlayerCount")>2 then
                for _,player in ipairs(q(self.room,"getOtherPlayers",self.player))do
                    if q(self,"canLiuli",self.player,player)then chosen=card;break end
                end
            end
            if not chosen and q(self,"getCardsNum","Jink")>=2 then chosen=card end
        elseif to_save>q(self.player,"getMaxCards")
            or (not isCard("Peach",card,self.player) and not(q(self,"isWeak") and isCard("Analeptic",card,self.player)))then
            chosen=card
        else to_save=to_save+1 end
        if chosen then
            if (red_avail and q(chosen,"isRed"))or(black_avail and q(chosen,"isBlack"))then break
            else chosen=nil;to_save=to_save+1 end
        end
    end
    return chosen and "$"..q(chosen,"getEffectiveId")or"."
end
sgs.ai_skill_cardask["@xingwu"]=function(self,data)return xingwu_cost(self,false)end
sgs.ai_skill_cardask["@tenyearxingwu-card"]=function(self,data)return sgs.ai_skill_cardask["@xingwu"](self,data)end
sgs.ai_skill_cardask["@olxingwu-card"]=function(self,data)return xingwu_cost(self,true)end
sgs.ai_skill_playerchosen.xingwu=function(self,targets)
    local enemies={}
    for _,enemy in ipairs(self.enemies)do if q(enemy,"isMale")then enemies[#enemies+1]=enemy end end
    if #enemies==0 then return targets[1]end
    local function score(enemy)
        local value=0
        if q(self,"damageIsEffective",enemy)then
            local damage=q(enemy,"hasArmorEffect","SilverLion")and 1 or 2
            local hp=q(enemy,"getHp")
            if hp<=damage then value=5 else value=value+hp/(hp-damage)end
            if not q(self,"isGoodTarget",enemy,self.enemies)then value=value-2 end
            if q(self,"cantbeHurt",enemy,self.player,damage)then value=value-5 end
            if q(enemy,"isLord")then value=value+2 end
            if q(enemy,"hasArmorEffect","SilverLion")then value=value-1.5 end
            if xingwu_skills(self,enemy,known(sgs.exclusive_skill,"exclusive_skill"))then value=value-1 end
            if xingwu_skills(self,enemy,known(sgs.masochism_skill,"masochism_skill"))then value=value-0.5 end
        end
        local equips=q(enemy,"getEquips")
        if #equips>0 then
            if xingwu_skills(self,enemy,known(sgs.lose_equip_skill,"lose_equip_skill"))then value=value-0.6*#equips end
            -- Donor intentionally asks needToThrowArmor() for self here.
            if call(enemy,"getArmor")and q(self,"needToThrowArmor")then value=value-1.5 end
            if q(enemy,"hasArmorEffect","SilverLion")then value=value-0.5 end
            if call(enemy,"getWeapon")then value=value+0.8 end
            if call(enemy,"getArmor")then value=value+1 end
            if call(enemy,"getDefensiveHorse")then value=value+0.9 end
            if call(enemy,"getOffensiveHorse")then value=value+0.7 end
            if call(self,"getDangerousCard",enemy)then value=value+0.3 end
            if call(self,"getValuableCard",enemy)then value=value+0.15 end
        end
        return value
    end
    local values={}
    for _,enemy in ipairs(enemies)do values[q(enemy,"objectName")]=score(enemy)end
    table.sort(enemies,function(a,b)return values[q(a,"objectName")]>values[q(b,"objectName")]end)
    return enemies[1]
end
sgs.ai_playerchosen_intention.xingwu=80
sgs.ai_playerchosen_intention.tenyearxingwu=80
sgs.ai_playerchosen_intention.olxingwu=80

-- sp-ai.lua:3981/3983. Count only the owner's actual Heart cards; preserve
-- the strict damage threshold and the Peach/ExNihilo-before-damage ordering.
sgs.ai_skill_invoke.andong = true
sgs.ai_skill_choice.andong = function(self, choices, data)
    local damage = q(data, "toDamage")
    local target = known(damage.to, "andong.damage.to")
    if q(self, "isFriend", target) then return "prevent" end
    local heart = 0
    for _, card in ipairs(q(self.player, "getCards", "h")) do
        if q(card, "getSuit") == sgs.Card_Heart then
            heart = heart + 1
            if q(card, "isKindOf", "Peach") or q(card, "isKindOf", "ExNihilo") then
                heart = heart + 1
            elseif q(card, "isDamageCard") then heart = heart + 0.5 end
        end
    end
    if heart < 2 * q(self, "ajustDamage", damage.from, target,
        known(damage.damage, "andong.damage.damage")) then return "get" end
    return "prevent"
end

-- sp-ai.lua:3975. Preserve the nested reason, nil pattern, and first result.
sgs.ai_skill_cardask["tuifeng-put"] = function(self, data)
    local selected = q(self, "askForDiscard", "dummy", 1, 1, false, true)
    return #selected > 0 and ("$" .. selected[1]) or "."
end
-- sp-ai.lua:2213. This callback intentionally ignores its own optional flag
-- when delegating; it does not fabricate an outer inquiry's offered domain.
sgs.ai_skill_discard.jieyue = function(self, discard_num, min_num, optional, include_equip)
    local source = call(self.room, "getCurrent")
    if source and q(self, "isEnemy", source) then return {} end
    return q(self, "askForDiscard", "dummy", discard_num, min_num, false, include_equip)
end

-- sp-ai.lua:1821/1838. Protection is chosen before paying one exact discard;
-- preserve the nested discard reason and the donor's first-result Peach veto.
sgs.ai_skill_cardask["@sp_zhenwei"] = function(self, data)
    local use = q(data, "toCardUse")
    local targets = known(use.to, "sp_zhenwei.targets")
    if #targets ~= 1 or not use.from or not use.card then return "." end
    local target, card = targets[1], use.card
    if not q(self, "isFriend", target) or q(self, "isFriend", use.from) then return "." end
    if q(target, "hasSkills", "liuli|tianxiang") and q(card, "isKindOf", "Slash")
        and q(target, "getHandcardNum") > 1 then return "." end
    if q(card, "isKindOf", "Slash") and not q(self, "slashIsEffective", card, target, use.from) then return "." end
    if q(target, "hasSkills", known(sgs.masochism_skill, "masochism_skill"))
        and not q(self, "isWeak", target) then return "." end
    if q(self.player, "getHandcardNum") + #q(self.player, "getEquips") < 2
        and not q(self, "isWeak", target) then return "." end
    local selected = call(self, "askForDiscard", "sp_zhenwei", 1, 1, false, true)
    if #selected == 0 then return "." end
    if not (q(card, "isKindOf", "Slash") and q(self, "isWeak", target)) then
        local cost = q(self, "getKnownCardById", selected[1])
        if q(cost, "isKindOf", "Peach") then return "." end
    end
    return "$" .. selected[1]
end

sgs.ai_skill_choice.spzhenwei = function(self, choices, data)
    local use = q(data, "toCardUse")
    if q(self, "isWeak") or q(self.player, "getHandcardNum") < 2 then return "null" end
    local card = known(use.card, "spzhenwei.card")
    local from = use.from
    if q(card, "isKindOf", "TrickCard") and q(from, "hasSkill", "jizhi") then return "draw" end
    if q(card, "isKindOf", "Slash") and (q(from, "hasSkills", "paoxiao|tianyi|xianzhen|jiangchi|fuhun|qiangwu")
        or (call(from, "getWeapon") and q(q(from, "getWeapon"), "isKindOf", "Crossbow")))
        and q(self, "getCardsNum", "Jink") == 0 then return "null" end
    if q(card, "isKindOf", "SupplyShortage") then return "null" end
    if q(card, "isKindOf", "Slash") and q(self, "getCardsNum", "Jink") == 0
        and q(self.player, "getLostHp") > 0 then return "null" end
    if q(card, "isKindOf", "Indulgence") and q(self.player, "getHandcardNum") + 1 > q(self.player, "getHp") then return "null" end
    if q(card, "isKindOf", "Slash") and q(from, "hasSkills", "tieqi|wushuang|yijue|liegong|mengjin|qianxi")
        and not (call(from, "getWeapon") and q(q(from, "getWeapon"), "isKindOf", "Crossbow")) then return "null" end
    return "draw"
end

-- sp-ai.lua:905–919. The random draw belongs to invoke, including a nil
-- Huashen answer; choice consumes the viewer-local handoff without another draw.
sgs.ai_skill_invoke.xiaode = function(self)
    local context = self:getDecisionContext()
    local skills = known(context.choice_body and context.choice_body.xiaode_skills, "xiaode.skills")
    if type(skills) ~= "table" then ai_unsupported("Xiaode skills are not a string list", "xiaode.skills") end
    for _, skill in ipairs(skills) do
        if type(skill) ~= "string" then ai_unsupported("Xiaode skill name is malformed", "xiaode.skills") end
    end
    local round = q(self, "playerGetRound", self.player)
    local chooser = sgs.ai_skill_choice.huashen
    if type(chooser) ~= "function" then ai_unsupported("Xiaode Huashen policy is unavailable", "xiaode.huashen") end
    local skill = chooser(self, table.concat(skills, "+"), nil, math.random(1-round, 7-round))
    if AIUnsupported.is(skill) then error(skill, 0) end
    self:setStrategyMemory("sp.xiaode_choice", skill or false)
    return skill and true or false
end
sgs.ai_skill_choice.xiaode = function(self)
    local skill, present = self:getStrategyMemory("sp.xiaode_choice")
    if not present then return nil end -- donor initializes this global to nil
    return skill or nil
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

-- R41 finite source scalar registry; values are native continuity observations,
-- never callback closures or viewer-memory guesses.
ai_response_scalar_choices=ai_response_scalar_choices or{}
local scalar_choices=ai_response_scalar_choices
local function scalar_host(op,key,row,from)
 if key~='xuhe'and key~='olxuhe'then ai_unsupported('Unaudited scalar choice name',key)end
 if type(ai_response_choice_continuity)~='function'then ai_unsupported('Scalar continuation host missing',key)end
 local value=ai_response_choice_continuity({op=op,key=key,row=row,from=from})
 if AIUnsupported.is(value)then error(value,0)end
 if type(value)~='table'or value.known~=true then ai_unsupported('Source scalar registry continuity unknown',key)end
 if op~='read'and value.recorded~=true then ai_unsupported('Source scalar registry write unconfirmed',key)end
 return value
end
function scalar_choices.read(self,key)return scalar_host('read',key)end
function scalar_choices.write(self,key,row)scalar_host('record',key,row)end
function scalar_choices.copy(self,to,from)scalar_host('copy',to,nil,from)end
function scalar_choices.answer(self,key)
 local row=scalar_choices.read(self,key)
 if type(row.present)~='boolean'or(row.present and type(row.value)~='string')then ai_unsupported('Malformed scalar choice observation',key)end
 if row.present then return row.value end
end
sgs.ai_skill_choice.xuhe=function(self)return scalar_choices.answer(self,'xuhe')end
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
sgs.ai_skill_invoke.xuhe=function(self,data)
    if q(self.player,'getMaxHp')<=3 then return false end
    local num=0
    self.xuhe_choice=nil
    local can_dis=false
    for _,p in ipairs(q(self.room,'getAlivePlayers'))do
        if q(self.player,'distanceTo',p)<=1 then
            if q(self.player,'canDiscard',p,'he')then
                can_dis=true
                if q(self,'isFriend',p)then
                    num=num+1
                    if xuhe_discard(self,p)then num=num-2 end
                elseif q(self,'isEnemy',p)then
                    num=num-1
                    if xuhe_discard(self,p)then num=num+2 end
                end
            end
        end
    end
    if num<=0 and can_dis then
        scalar_choices.write(self,'xuhe',{known=true,present=true,value='discard'})
        return true
    end
    num=0
    for _,p in ipairs(q(self.room,'getAlivePlayers'))do
        if q(self.player,'distanceTo',p)<=1 then
            if q(self,'isFriend',p)and q(self,'canDraw',p)then num=num+1
            elseif q(self,'isEnemy',p)and q(self,'canDraw',p)then num=num-1 end
        end
    end
    if num>=0 then
        scalar_choices.write(self,'xuhe',{known=true,present=true,value='draw'})
        return true
    end
    return false
end

-- Fixed sp-ai.lua9683–9733; only finite constructors differ from native userdata.
do
 local function req(object,name,...)
  if not object or type(object[name])~='function'then ai_unsupported('Faqi/Limu source helper missing',name)end
  local value=object[name](object,...)
  if AIUnsupported.is(value)then error(value,0)end
  if value==nil then ai_unsupported('Faqi/Limu source fact unknown',name)end
  return value
 end
 local function optional(self,name,...)
  if type(self[name])~='function'then ai_unsupported('Faqi/Limu source provider missing',name)end
  local value=self[name](self,...);if AIUnsupported.is(value)then error(value,0)end;return value
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
 local function q(o,k,...)
  if not o or type(o[k])~='function'then ai_unsupported('Limu source provider missing',k)end
  local v=o[k](o,...);if AIUnsupported.is(v)then error(v,0)end
  if v==nil then ai_unsupported('Limu source fact unknown',k)end;return v
 end
 local function opt(o,k,...)
  if not o or type(o[k])~='function'then ai_unsupported('Limu source provider missing',k)end
  local v=o[k](o,...);if AIUnsupported.is(v)then error(v,0)end;return v
 end
 sgs.ai_fill_skill.limu=function(self,inclusive,request)
  local cards,peach={},0
  for _,c in sgs.list(q(self,'addHandPile'))do
   if peach<2 and isCard('Peach',c,self.player)then peach=peach+1
   elseif q(c,'getSuit')==3 then
    local i=q(self,'evaluateLimuSourceCard','indulgence',{q(c,'getEffectiveId')})
    if not q(self.player,'isLocked',i)then table.insert(cards,c)end
   end
  end
  if #cards<1 then return end
  q(self,'sortByKeepValue',cards)
  if q(self,'isWeak')then
   self:setPriorityValue('Peach',self:getSourcePriorityValue('LimuCard')+0.1,'limu')
   if q(cards[1],'isKindOf','Peach')and q(cards[1],'isAvailable',self.player)then return cards[1]end
   return opt(self,'evaluateLimuSourceCard','limu',{q(cards[1],'getEffectiveId')},request)
  end
  local id=-1
  for _,c in ipairs(cards)do
   if isCard('Slash',c,self.player)then else id=q(c,'getEffectiveId');break end
  end
  local slash_num=q(self,'getCardsNum','Slash')
  if id<0 then id=q(cards[1],'getEffectiveId');slash_num=slash_num-1 end
  if slash_num>1 then
   for _,slash in ipairs(q(self,'getCards','Slash'))do
    if q(self,'aiUseCard',slash).card then return opt(self,'evaluateLimuSourceCard','limu',{id},request)end
   end
  end
 end
 sgs.ai_skill_use_func.LimuCard=function(card,use,self)use.card=card end
 sgs.ai_use_priority.LimuCard=2.5
 sgs.ai_use_value.LimuCard=2.5
 -- ai_use_revises.limu retains the complete R41 body. Only its constructor
 -- adapter dispatches current Activate versus original Faqi AG context.
 sgs.ai_skill_carduse.limu=function(self,card,use)
  if not q(card,'isKindOf','Weapon')then return false end
  local has_xuanjian=q(self.player,'hasWeapon','_xuanjian')
  local has_spear=q(self.player,'hasWeapon','spear')
  if has_xuanjian then return true end
  if has_spear then
   if q(card,'objectName')=='_xuanjian'then use.card=card;return true else return true end
  end
  if q(card,'objectName')=='_xuanjian'or q(card,'objectName')=='spear'then use.card=card;return true end
  return false
 end
 sgs.ai_card_priority.limu=function(self,card,v)
  if q(card,'objectName')=='_xuanjian'then return v+5 end
  if q(card,'objectName')=='spear'then return v+4 end
  if q(self.player,'hasWeapon','_xuanjian')or q(self.player,'hasWeapon','spear')then
   if q(card,'isKindOf','Slash')then return v+3 end
  end
  if(q(self.player,'hasWeapon','_xuanjian')or q(self.player,'hasWeapon','spear'))and q(card,'getSuit')==sgs.Card_Diamond then return v+2 end
  return v
 end
end
