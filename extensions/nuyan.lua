-- 怒焰三国杀. Sole rules source: finaldebug-md-ascii/nuyan.md.
-- Stars and the (unspecified) rage cap are supplied by the host through marks.
-- A zero cap means no cap has been configured; no numeric cap is invented here.
local extension = sgs.Package("nuyan")
local translations = {nuyan = "怒焰三国杀", ["@nuyan_nuqi"] = "怒气",
    ["@nuyan_star"] = "星级", ["nuyan_nuqi_cap"] = "怒气上限",
    ["@nuyan_quan"] = "权", ["@nuyan_chou"] = "仇", ["@nuyan_ling"] = "灵",
    nuyan_pojun = "破军", nuyan_kong = "箜", nuyan_choose = "选择角色",
    nuyan_give = "请选择交出的牌", nuyan_discard = "请选择弃置的牌",
    nuyan_strengthen = "是否消耗1点怒气强化此杀？", nuyan_damage = "伤害",
    nuyan_draw = "摸牌", nuyan_recover = "回复体力", nuyan_losehp = "失去体力",
    nuyan_move = "移动场上牌", nuyan_slash = "使用杀", nuyan_cancel = "取消",
    nuyan_red = "红色", nuyan_black = "黑色"}
local specs, skills, handlers = {}, {}, {}
local function list(q) local t = {}; for _, x in sgs.qlist(q) do t[#t + 1] = x end; return t end
local function ints(t) local q = sgs.IntList(); for _, x in ipairs(t) do q:append(x) end; return q end
local function players(t) local q = sgs.SPlayerList(); for _, x in ipairs(t) do q:append(x) end; return q end
local function star(p) return p:getMark("@nuyan_star") end
local function rage(p) return p:getMark("@nuyan_nuqi") end
local function cap(p) return p:getMark("nuyan_nuqi_cap") end
local function full(p) return cap(p) > 0 and rage(p) >= cap(p) end
local function invoke(room, p, name, data) return room:askForSkillInvoke(p, name, data or sgs.QVariant()) end
local function draw(p, n, name) if n > 0 and p:isAlive() then p:drawCards(n, name) end end
local function recover(room, p, n, from, name)
    if n > 0 and p:isAlive() then local r = sgs.RecoverStruct(); r.who = from; r.recover = n; room:recover(p, r) end
end
local function damage(room, from, to, n, name, nature)
    if to and to:isAlive() and n > 0 then
        local d = sgs.DamageStruct(); d.from = from; d.to = to; d.damage = n; d.reason = name
        d.nature = nature or sgs.DamageStruct_Normal; room:damage(d)
    end
end
local function dummy(ids) local c = sgs.Sanguosha:cloneCard("slash"); c:addSubcards(ints(ids)); return c end
local function obtain(room, p, ids, name)
    if #ids == 0 then return end
    local c = dummy(ids); room:obtainCard(p, c, name, false); c:deleteLater()
end
local function random_ids(q, n)
    local t, out = list(q), {}
    for i = 1, math.min(n, #t) do local k = math.random(#t); out[#out + 1] = table.remove(t, k) end
    return out
end
local function random_discard(room, p, n, zone, name)
    local ids = {}; for _, c in sgs.qlist(p:getCards(zone)) do
        if p:canDiscard(p, c:getEffectiveId()) then ids[#ids + 1] = c:getEffectiveId() end
    end
    local chosen = random_ids(ints(ids), n)
    if #chosen > 0 then local c = dummy(chosen); room:throwCard(c, p, p); c:deleteLater() end
    return chosen
end
local function take(room, from, to, n, zone, name, discard)
    for i = 1, n do
        if not from:isAlive() or to:getCards(zone):isEmpty() then break end
        if discard and not from:canDiscard(to, zone) then break end
        if not discard and not from:canGet(to, zone) then break end
        local id = room:askForCardChosen(from, to, zone, name, false, discard and sgs.Card_MethodDiscard or sgs.Card_MethodGet)
        if id < 0 then break end
        if discard then room:throwCard(id, to, from) else
            if not from:canGet(to, id) then break end
            room:obtainCard(from, id, name, false)
        end
    end
end
local function choose(room, p, name, predicate, optional)
    local t = {}; for _, q in sgs.qlist(room:getAlivePlayers()) do if not predicate or predicate(q) then t[#t + 1] = q end end
    if #t == 0 then return nil end
    return room:askForPlayerChosen(p, players(t), name, "nuyan_choose", optional or false, true)
end
local function give(room, p, to, n, name)
    n = math.min(n, p:getHandcardNum()); if n <= 0 or not to:isAlive() then return end
    local c = room:askForExchange(p, name, n, n, false, "nuyan_give", false)
    if c then room:obtainCard(to, c, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), to:objectName(), name, ""), false); c:deleteLater() end
end
local function deck_card(room, p, name, predicate, n, discard_too)
    local ids = {}; for _, id in sgs.qlist(room:getDrawPile()) do
        if predicate(sgs.Sanguosha:getCard(id)) then ids[#ids + 1] = id end
    end
    if discard_too then for _, id in sgs.qlist(room:getDiscardPile()) do
        if predicate(sgs.Sanguosha:getCard(id)) then ids[#ids + 1] = id end
    end end
    local out = random_ids(ints(ids), n or 1); obtain(room, p, out, name); return out
end
local function single(c) return c and c:isNDTrick() and c:isKindOf("SingleTargetTrick") and not c:isKindOf("Nullification") end
local function attack(c) return c and (c:isKindOf("Slash") or single(c)) end
local function usecard(room, p, to, card, name, enhanced, unlimited)
    local c = type(card) == "string" and sgs.Sanguosha:cloneCard(card) or card
    if not c then return false end
    c:setSkillName(name)
    if enhanced then c:setFlags("nuyan_enhanced") end
    if unlimited then c:setFlags("nuyan_unlimited") end
    local u = sgs.CardUseStruct(); u.card = c; u.from = p
    if to then u.to:append(to) end
    room:useCard(u, not unlimited); c:deleteLater(); return true
end
local function add_rage(room, p, n, source)
    if not p or not p:isAlive() or n == 0 then return false end
    local old = rage(p); local value = math.max(0, old + n)
    local overflow = n > 0 and cap(p) > 0 and value > cap(p)
    if cap(p) > 0 then value = math.min(value, cap(p)) end
    room:setPlayerMark(p, "@nuyan_nuqi", value)
    room:addPlayerMark(p, "nuyan_rage_changed-Clear")
    if overflow then
        for id, sp in pairs(specs) do
            if sp.mode == "shouxi" and p:hasSkill(id) and rage(p) >= 2 and invoke(room, p, id) then
                local q = choose(room, p, id, function(t) return t ~= p end, true)
                if q then add_rage(room, p, -2, p); room:loseHp(q, rage(p) + 1, true, p, id) end
            end
        end
    end
    return overflow
end
local function pay(room, p, n) if rage(p) < n then return false end; add_rage(room, p, -n, p); return true end
local function phase(p, f) return p and p:getPhase() == f end
local function norespond(data, q)
    local u = data:toCardUse(); local t = u.no_respond_list
    table.insert(t, q:objectName()); u.no_respond_list = t; data:setValue(u)
end
local function nullify(data, q)
    local u = data:toCardUse(); local t = u.nullified_list
    table.insert(t, q:objectName()); u.nullified_list = t; data:setValue(u)
end
local function judge(room, p, name)
    local j = sgs.JudgeStruct(); j.who = p; j.reason = name; j.pattern = "."; j.good = true; room:judge(j); return j.card
end
local function hasmode(p, mode)
    for id, sp in pairs(specs) do if sp.mode == mode and p:hasSkill(id) then return sp, id end end
end
local function swap_equips(room, a, b, name)
    local aa, bb = list(a:getEquips()), list(b:getEquips())
    local aid, bid = {}, {}; for _, c in ipairs(aa) do aid[#aid+1] = c:getEffectiveId() end
    for _, c in ipairs(bb) do bid[#bid+1] = c:getEffectiveId() end
    -- Stage both sides on the table before filling their slots.
    for _, c in ipairs(aa) do room:moveCardTo(c, a, nil, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, a:objectName(), name, ""), true) end
    for _, c in ipairs(bb) do room:moveCardTo(c, b, nil, sgs.Player_PlaceTable, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, b:objectName(), name, ""), true) end
    for _, c in ipairs(aa) do if b:hasEquipArea(c:getRealCard():toEquipCard():location()) then room:moveCardTo(c, b, sgs.Player_PlaceEquip, true) else room:throwCard(c, nil) end end
    for _, c in ipairs(bb) do if a:hasEquipArea(c:getRealCard():toEquipCard():location()) then room:moveCardTo(c, a, sgs.Player_PlaceEquip, true) else room:throwCard(c, nil) end end
    return #aid, #bid
end
local function move_field(room, p, name)
    local a = choose(room, p, name, function(q) return p:canMove(q, "ej") end, true)
    if not a then return end
    local id = room:askForCardChosen(p, a, "ej", name, false, sgs.Card_MethodMove); local c = sgs.Sanguosha:getCard(id)
    if not p:canMove(a, id) then return end
    local place = room:getCardPlace(id)
    local b = choose(room, p, name, function(q)
        if q == a then return false end
        if place == sgs.Player_PlaceEquip then local eq = c:getRealCard():toEquipCard(); return q:hasEquipArea(eq:location()) and not q:getEquip(eq:location()) end
        return not q:containsTrick(c:objectName()) and not p:isProhibited(q, c)
    end, true)
    if b then room:moveCardTo(c, a, b, place, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, p:objectName(), name, ""), true) end
end
-- Active skills share card plumbing, but each mode retains its printed cost/limit.
local active_modes = {qiangxi=true, xuanhuo=true, kurou=true, luoyi=true, renxin=true,
    zhiman=true, baoli=true, quhu=true, zhenjun=true, zhilue=true, quanji=true,
    jizhen=true, qiangwu=true, xuehen=true, zhiheng=true, duwu=true, zhijian=true,
    lihun=true, xianzhen=true, xianzhou=true, zhongjian=true, pianchong=true,
    jitian=true, dulie=true, canshi=true, luanwu=true, fencheng=true, fenxin=true,
    yanyu=true, wenji=true}
local function limit(sp, p)
    local m = sp.mode
    if m == "qiangxi" then return sp.classic and math.huge or 1 end
    if m == "kurou" then return sp.classic and 2 or star(p) end
    if m == "quhu" or m == "luanwu" then return sp.classic and 2 or star(p) + 1 end
    if m == "xuehen" then return sp.classic and p:getMark("nuyan_xuehen_limit") or star(p) end
    if m == "zhijian" then return sp.classic and 4 or star(p) end
    if m == "fenxin" then return cap(p) > 0 and cap(p) or 0 end
    if m == "luoyi" and sp.jie then return 3 end
    if m == "baoli" or m == "zhilue" or m == "jitian" or m == "fencheng" or m == "yanyu" or m == "duwu" or m == "wenji" then return math.huge end
    return 1
end
local function active_count(sp, selected, p)
    local m = sp.mode; local n = #selected
    if m == "qiangxi" then return n == 1 or (sp.classic and n == 0) end
    if m == "zhiheng" then return sp.jie or sp.classic or n <= 4 end
    if m == "duwu" then return sp.jie and n == 1 or not sp.jie end
    if m == "kurou" or m == "renxin" or m == "baoli" or m == "quhu" or m == "zhilue" or m == "quanji" or m == "jizhen" or m == "qiangwu" or m == "lihun" or m == "xianzhen" or m == "xianzhou" or m == "pianchong" or m == "dulie" or m == "canshi" or m == "luanwu" or m == "fencheng" or m == "fenxin" or m == "wenji" then return n == 0 end
    return n == 1
end
local function active_select(sp, c, selected, p)
    local m = sp.mode
    if m == "zhiheng" or m == "duwu" then return (m ~= "zhiheng" or sp.jie or sp.classic or #selected < 4) and not p:isJilei(c) end
    if #selected > 0 then return false end
    if m == "qiangxi" then return c:isKindOf("EquipCard") and not p:isJilei(c) end
    if m == "xuanhuo" then return not c:isEquipped() and c:getSuit() == sgs.Card_Diamond end
    if m == "luoyi" then return not p:isJilei(c) and (sp.jie and not c:isEquipped() and p:getMark(sp.id .. "_type" .. c:getTypeId() .. "-PlayClear") == 0 or not sp.jie and c:isKindOf("EquipCard")) end
    if m == "xuehen" then return c:getSuit() == sgs.Card_Heart and not p:isJilei(c) end
    if m == "zhijian" or m == "zhongjian" then return not c:isEquipped() and not p:isJilei(c) end
    if m == "yanyu" then return c:isKindOf("Slash") and not p:isJilei(c) end
    if m == "zhenjun" then return true end
    return not p:isJilei(c)
end
local function active_target(sp, card, from, q)
    local m = sp.mode
    if m == "kurou" or m == "luoyi" or m == "baoli" or m == "zhilue" or m == "quanji" or m == "zhiheng" or m == "pianchong" or m == "canshi" or m == "luanwu" or m == "fencheng" or m == "yanyu" then return false end
    if m == "renxin" or m == "jitian" or m == "fenxin" or m == "dulie" then return true end
    if q == from then return m == "zhiman" or (m == "jizhen" or m == "qiangwu") and from:canDiscard(q, m == "jizhen" and "hej" or "he") end
    if m == "qiangxi" then return not sp.classic or q:getMark(sp.id .. "_hit-PlayClear") == 0 end
    if m == "quhu" or m == "xianzhen" then return from:canPindian(q) end
    if m == "xianzhou" then return not q:getEquips():isEmpty() end
    if m == "lihun" or m == "zhongjian" then return not q:isKongcheng() end
    if m == "jizhen" or m == "qiangwu" then return from:canDiscard(q, m == "jizhen" and "hej" or "he") end
    if m == "wenji" then return not q:isNude() and q:getMark(sp.id .. "_hit-PlayClear") == 0 end
    if m == "duwu" then return card:subcardsLength() == (sp.jie and 1 or math.max(0, math.ceil(q:getHp()/2))) end
    return true
end
local function active_effect(sp, room, p, targets, card)
    local m, id, q = sp.mode, sp.id, targets[1]; local selected = list(card:getSubcards())
    room:addPlayerMark(p, id .. "_used-PlayClear")
    if m == "qiangxi" then
        room:addPlayerMark(q, id .. "_hit-PlayClear"); if #selected == 0 then room:loseHp(p, 1, true, p, id) end
        damage(room, p, q, sp.classic and 1 or 2, id)
    elseif m == "xuanhuo" then room:obtainCard(q, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), q:objectName(), id, ""), false); take(room, p, q, rage(q), "he", id)
    elseif m == "kurou" then
        room:loseHp(p, 1, true, p, id); draw(p, 2, id)
        if sp.classic then room:setPlayerMark(p, "nuyan_kurou-Clear", 1) else room:addPlayerMark(p, "nuyan_slash-PlayClear") end
    elseif m == "luoyi" then
        if sp.jie then room:addPlayerMark(p, id .. "_type" .. sgs.Sanguosha:getCard(selected[1]):getTypeId() .. "-PlayClear") end
        room:addPlayerMark(p, "nuyan_luoyi-Clear"); if sp.jie then room:addPlayerMark(p, "nuyan_luoyi_others-Clear") end
    elseif m == "renxin" then add_rage(room, q, -1, p); recover(room, q, rage(q), p, id)
    elseif m == "zhiman" then room:loseHp(q, 1,true,p,id)
    elseif m == "baoli" then room:loseHp(p, 1, true, p, id); if p:isAlive() then add_rage(room, p, 2, p) end
    elseif m == "quhu" then if p:pindian(q, id, nil) then damage(room, p, q, 1, id) end
    elseif m == "zhenjun" then
        room:obtainCard(q, card, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), q:objectName(), id, ""), false)
        local slash = room:askForUseSlashTo(q, room:getOtherPlayers(q), "nuyan_slash", true, false, false)
        -- A non-black response is enforced by a temporary limitation at request time (see factory).
        if slash then draw(p, 1, id) else
            local t = choose(room, p, id, function(t) return t == q or q:inMyAttackRange(t) end, true)
            if t then damage(room, p, t, 1, id) end
        end
    elseif m == "zhilue" then
        if not pay(room, p, 1) then return end
        if room:askForChoice(p, id, "nuyan_move+nuyan_slash") == "nuyan_move" then move_field(room, p, id) else
            draw(p, 2, id); local t = choose(room, p, id, function(t)
                local c = sgs.Sanguosha:cloneCard("slash"); c:setFlags("nuyan_unlimited"); local ok = t ~= p and p:canSlash(t, c, false); c:deleteLater(); return ok
            end, true)
            if t then usecard(room, p, t, "slash", id, false, true) end
        end
    elseif m == "quanji" then local n = p:getMark("@nuyan_quan"); room:setPlayerMark(p, "@nuyan_quan", 0); draw(p, 2*n, id)
    elseif m == "jizhen" or m == "qiangwu" then
        local zone = m == "jizhen" and "hej" or "he"
        local cid = room:askForCardChosen(p, q, zone, id, false, sgs.Card_MethodDiscard); local c = sgs.Sanguosha:getCard(cid)
        room:throwCard(cid, q, p)
        if m == "qiangwu" then room:setPlayerMark(p, "nuyan_qiangwu-Clear", 1) else
            room:setPlayerMark(p, id .. "_jizhen-Clear", 1)
            if c:isKindOf("EquipCard") then add_rage(room, p, 1, p) elseif c:isKindOf("BasicCard") then
                if invoke(room, p, id) and room:getCardPlace(cid) == sgs.Player_DiscardPile then room:obtainCard(p, cid, id) end
            else draw(p, 1, id) end
        end
    elseif m == "xuehen" then
        room:setPlayerMark(q, "nuyan_xuehen_" .. p:objectName() .. "-Clear", 1); damage(room, p, q, 1, id)
    elseif m == "zhiheng" then
        local extra = 0
        if sp.jie or sp.classic then
            -- Counts are captured before the engine discards subcards.
            if p:getMark(id .. "_allhand") > 0 or sp.jie and p:getMark(id .. "_allequip") > 0 then extra=1 end
        end
        draw(p, #selected + extra, id)
    elseif m == "duwu" then
        damage(room, p, q, 1, id)
        if q:getMark(id .. "_dying") > 0 then
            room:setPlayerMark(q, id .. "_dying", 0)
            if q:isAlive() then room:loseHp(p, 1, true, p, id); room:setPlayerMark(p, id .. "_ban-Clear", 1) end
        end
    elseif m == "zhijian" then
        local ids = {}; for _, pile in ipairs({room:getDrawPile(),room:getDiscardPile()}) do for _, cid in sgs.qlist(pile) do
            local c=sgs.Sanguosha:getCard(cid); if c:isKindOf("EquipCard") and q:hasEquipArea(c:getRealCard():toEquipCard():location()) then ids[#ids+1]=cid end
        end end
        if #ids>0 then local c=sgs.Sanguosha:getCard(ids[math.random(#ids)]); local old=q:getEquip(c:getRealCard():toEquipCard():location()); if old then room:throwCard(old,q) end; room:moveCardTo(c,q,sgs.Player_PlaceEquip,true) end
        draw(p,1,id)
    elseif m == "lihun" then
        if not pay(room,p,1) then return end
        take(room,p,q,sp.classic and q:getHandcardNum() or star(p),"h",id)
        p:setTag(id .. "_target",sgs.QVariant(q:objectName())); if not sp.classic then room:setPlayerMark(p,"nuyan_no_switch-Clear",1) end
    elseif m == "xianzhen" then
        if p:pindian(q,id,nil) then room:setPlayerMark(q,"nuyan_xianzhen_" .. p:objectName() .. "-PlayClear", sp.classic and 2 or 1)
        else room:setPlayerCardLimitation(p,"use","Slash",true) end
    elseif m == "xianzhou" then
        local sent,got=swap_equips(room,p,q,id)
        if got>sent then room:addPlayerMark(p,"nuyan_slash-Clear") elseif sent>got then recover(room,p,1,p,id) else draw(p,1,id);add_rage(room,p,1,p) end
    elseif m == "zhongjian" then
        local c=sgs.Sanguosha:getCard(selected[1]); local ids=random_ids(q:handCards(),sp.classic and 4 or star(p)); local matches={}
        room:showCard(p,selected[1],sgs.SPlayerList(),id); for _,cid in ipairs(ids) do room:showCard(q,cid,sgs.SPlayerList(),id); local t=sgs.Sanguosha:getCard(cid)
            if (sp.classic and c:isRed()==t:isRed()) or (not sp.classic and c:getSuit()==t:getSuit()) then matches[#matches+1]=cid end
        end
        if #matches>0 then local d=dummy(matches);room:throwCard(d,q,p);d:deleteLater() else
            local gettable={}; for _,cid in ipairs(ids) do if p:canGet(q,cid) then gettable[#gettable+1]=cid end end
            local pool=ints(gettable); for i=1,math.min(2,#gettable) do room:fillAG(pool,p);local cid=room:askForAG(p,pool,false,id);room:clearAG(p);pool:removeOne(cid);room:obtainCard(p,cid,id,false) end
        end
    elseif m == "pianchong" then
        local choice=room:askForChoice(p,id,"nuyan_red+nuyan_black");room:setPlayerMark(p,"nuyan_pianchong",choice=="nuyan_red" and 1 or 2)
    elseif m == "jitian" then
        add_rage(room,q,1,p)
        for _,t in ipairs({q:getNextAlive(),q:getLastAlive()}) do if not (sp.classic and t==p) then add_rage(room,t,-1,p) end end
    elseif m == "dulie" then
        local c=room:askForCard(q,".|.|.|hand","nuyan_give",sgs.QVariant(p),sgs.Card_MethodNone)
        if c then
            local v=sgs.Sanguosha:cloneCard("ex_nihilo",c:getSuit(),c:getNumber());v:addSubcard(c);usecard(room,q,q,v,id,not sp.classic,false)
            room:setPlayerMark(q,"nuyan_dulie",sp.classic and 2 or star(p))
        end
    elseif m == "canshi" then
        local n=p:getMark("@nuyan_chou");local assigned={};room:setPlayerMark(p,"@nuyan_chou",0)
        while n>0 and p:isAlive() do
            local t=choose(room,p,id,function(t)return t~=p and (assigned[t:objectName()] or 0)<2 end,true);if not t then break end
            local max=math.min(n,2-(assigned[t:objectName()] or 0)); local choices={};for i=1,max do choices[#choices+1]=tostring(i) end
            local k=tonumber(room:askForChoice(p,id,table.concat(choices,"+")));assigned[t:objectName()]=(assigned[t:objectName()] or 0)+k;n=n-k;damage(room,p,t,k,id)
        end
    elseif m == "luanwu" then
        if pay(room,p,1) then for _,t in sgs.qlist(room:getOtherPlayers(p)) do if not room:askForCard(t,"Slash","nuyan_discard",sgs.QVariant(p),sgs.Card_MethodDiscard) then room:loseHp(t,1,true,p,id) end end end
    elseif m == "fencheng" then
        local n=p:getMark(id .. "_times-Clear");if not pay(room,p,n) then return end;room:addPlayerMark(p,id .. "_times-Clear")
        local count=1;local order={p};for _,t in sgs.qlist(room:getOtherPlayers(p)) do order[#order+1]=t end
        for _,t in ipairs(order) do
            local c=room:askForExchange(t,id,t:getCardCount(true),count,true,"nuyan_discard",true)
            if c and c:subcardsLength()>=count then count=c:subcardsLength()+1;room:throwCard(c,t,t);c:deleteLater() else
                if c then c:deleteLater() end;count=1;if t~=p then room:loseHp(t,sp.classic and 1 or 2,true,p,id) end
            end
        end
    elseif m == "fenxin" then if pay(room,p,1) then room:addPlayerMark(q,"nuyan_fenxin") end
    elseif m == "wenji" then
        room:setPlayerMark(q,id .. "_hit-PlayClear",1)
        local c=room:askForExchange(q,id,1,1,true,"nuyan_give",false)
        if c then local t=sgs.Sanguosha:getCard(c:getSubcards():first()); room:addPlayerMark(p,"nuyan_wenji" .. t:getTypeId() .. "-Clear");room:obtainCard(p,c,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,q:objectName(),p:objectName(),id,""),false);c:deleteLater() end
    end
end
local function make_active(sp)
    local no_target = {kurou=true,luoyi=true,baoli=true,zhilue=true,quanji=true,zhiheng=true,pianchong=true,canshi=true,luanwu=true,fencheng=true,yanyu=true}
    local proto=sgs.CreateSkillCard{
        name=sp.id .. "Card", target_fixed=no_target[sp.mode] or false,
        will_throw=sp.mode~="xuanhuo" and sp.mode~="zhenjun",
        handling_method=(sp.mode=="xuanhuo" or sp.mode=="zhenjun") and sgs.Card_MethodNone or sgs.Card_MethodDiscard,
        filter=function(self,ts,q,p) return #ts==0 and active_target(sp,self,p,q) end,
        feasible=function(self,ts,p) return no_target[sp.mode] and #ts==0 or not no_target[sp.mode] and #ts==1 end,
        about_to_use=function(self,room,use)
            if sp.mode=="zhiheng" then
                local h,e=0,0
                for _,cid in sgs.qlist(self:getSubcards()) do local place=room:getCardPlace(cid);if place==sgs.Player_PlaceHand then h=h+1 elseif place==sgs.Player_PlaceEquip then e=e+1 end end
                room:setPlayerMark(use.from,sp.id .. "_allhand",h>0 and h==use.from:getHandcardNum() and 1 or 0)
                room:setPlayerMark(use.from,sp.id .. "_allequip",e>0 and e==use.from:getEquips():length() and 1 or 0)
            elseif sp.mode=="zhongjian" then room:showCard(use.from,self:getSubcards():first(),sgs.SPlayerList(),sp.id) end
            self:cardOnUse(room,use)
        end,
        on_use=function(self,room,p,ts)
            if sp.mode=="zhenjun" then room:setPlayerCardLimitation(ts[1],"use","Slash|black",false) end
            active_effect(sp,room,p,ts,self)
            if sp.mode=="zhenjun" then room:removePlayerCardLimitation(ts[1],"use","Slash|black$0") end
        end
    }
    local va=sgs.CreateViewAsSkillV2{
        name=sp.id,n=999,history_key="#" .. sp.id .. "Card",
        can_activate=function(self,req)
            local p=req:getInitiator();if req:getReason()~=sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
            if p:getMark(sp.id .. "_used-PlayClear")>=limit(sp,p) then return false end
            if sp.mode=="jizhen" and p:getMark(sp.id .. "_jizhen-Clear")>0 then return false end
            if sp.mode=="baoli" then return not full(p) end
            if sp.mode=="duwu" then return p:getMark(sp.id .. "_ban-Clear")==0 end
            if sp.mode=="quanji" then return p:getMark("@nuyan_quan")>0 end
            if sp.mode=="canshi" then return p:getMark("@nuyan_chou")>0 end
            if sp.mode=="fencheng" then return rage(p)>=p:getMark(sp.id .. "_times-Clear") end
            if sp.mode=="lihun" or sp.mode=="luanwu" or sp.mode=="zhilue" or sp.mode=="fenxin" then return rage(p)>=1 end
            return true
        end,
        can_select_card=function(self,req,c)
            local t=list(req:getSelectedCardIds());return active_select(sp,c,t,req:getInitiator())
        end,
        card_selection_feasible=function(self,req) return active_count(sp,list(req:getSelectedCardIds()),req:getInitiator()) end,
        create_card=function(self,req) local c=proto:clone();c:addSubcards(req:getSelectedCardIds());c:setSkillName(sp.id);return c end
    }
    return va
end
local conversions = {
    qixi={card="dismantlement"}, jixi={card="snatch"}, luanji={card="archery_attack",n=3,enhanced=true},
    shensu={card="slash",n=0,cost=2,enhanced=true,unlimited=true}, jiushi={card="analeptic",response=true},
    tianxiang={card="nuyan_fudichouxin",enhanced=true}, gongxin={card="snatch",n=0,cost=1},
    langxing={card="duel"}, hubu={card="duel",n=0,cost=1}, duanliang={card="indulgence",cost=1,enhanced=true},
    qice={n=999}, wusheng={card="slash",response=true}, fengpo={card="nuyan_nufachongguan",enhanced=true},
    zhanji={card="nuyan_fudichouxin"}, fanjian={card="drowning"}, guose={card="indulgence"},
    manyi={card="savage_assault",n=0,cost=1}, jijiu={card="peach",response=true},
    leifa={card="jink",response=true}, luoshen={card="jink",response=true},
    jinghongmeiying={response=true}, wuhushangjiang={n=2,response=true}, miaojian={}, kanpo_native={card="nuyan_kanpo",response=true}
}
local function conversion_name(sp,req)
    local cfg=conversions[sp.mode]
    if sp.mode=="qice" then local c=req:getInitiator():getTag(sp.id):toCard(); return c and c:isNDTrick() and c:objectName() or nil end
    if sp.mode=="jinghongmeiying" then return req:getPattern()=="jink" and "jink" or "slash" end
    if sp.mode=="wuhushangjiang" then
        local ids=req:getSelectedCardIds();if ids:isEmpty() then return nil end
        local suit=sgs.Sanguosha:getCard(ids:first()):getSuit()
        return ({[sgs.Card_Heart]="peach",[sgs.Card_Diamond]="slash",[sgs.Card_Club]="jink",[sgs.Card_Spade]="nullification"})[suit]
    end
    if sp.mode=="miaojian" then
        local ids=req:getSelectedCardIds()
        if req:getInitiator():getMark("nuyan_miaojian_level")>=3 then
            local c=req:getInitiator():getTag(sp.id):toCard()
            return c and (c:isKindOf("Slash") or c:isKindOf("Drowning")) and c:objectName() or nil
        end
        if ids:isEmpty() then return nil end
        return sgs.Sanguosha:getCard(ids:first()):isKindOf("BasicCard") and "slash" or "drowning"
    end
    return cfg.card
end
local function conversion_filter(sp,c,p,ids,req)
    if c:isEquipped() and sp.mode~="wuhushangjiang" and sp.mode~="miaojian" then return false end
    local m=sp.mode
    if m=="qixi" then return sp.classic and c:isBlack() or not sp.classic and c:getSuit()==sgs.Card_Club end
    if m=="jixi" then return c:isKindOf("Jink") end
    if m=="kanpo_native" then return c:isKindOf("Slash") and c:isBlack() end
    if m=="jiushi" or m=="luoshen" or m=="zhanji" then return c:isBlack() end
    if m=="tianxiang" then return c:isRed() end
    if m=="langxing" then return c:isKindOf("BasicCard") end
    if m=="duanliang" then return c:isBlack() and (c:isKindOf("BasicCard") or c:isKindOf("EquipCard")) end
    if m=="fengpo" or m=="jijiu" then return c:getSuit()==sgs.Card_Heart end
    if m=="fanjian" then return c:getSuit()==sgs.Card_Spade end
    if m=="guose" or m=="leifa" then return c:getSuit()==sgs.Card_Diamond end
    if m=="jinghongmeiying" then return req:getPattern()=="jink" and c:isKindOf("Slash") or req:getPattern()~="jink" and c:isKindOf("Jink") end
    if m=="wuhushangjiang" and #ids>0 then return c:getSuit()==sgs.Sanguosha:getCard(ids[1]):getSuit() end
    return true
end
local function make_conversion(sp)
    local cfg=conversions[sp.mode];local count=cfg.n or 1
    local function create(req)
        local ids=list(req:getSelectedCardIds());if sp.mode~="qice" and #ids~=(sp.mode=="miaojian" and req:getInitiator():getMark("nuyan_miaojian_level")>=3 and 0 or count) then return nil end
        local name=conversion_name(sp,req);if not name then return nil end
        local suit,number=sgs.Card_NoSuit,0
        if #ids==1 then local c=sgs.Sanguosha:getCard(ids[1]);suit=c:getSuit();number=c:getNumber() end
        local c=sgs.Sanguosha:cloneCard(name,suit,number);if not c then return nil end
        c:addSubcards(ints(ids));c:setSkillName(sp.id)
        if cfg.enhanced then c:setFlags("nuyan_enhanced") end
        if cfg.unlimited or sp.mode=="wusheng" and sp.jie and suit==sgs.Card_Diamond then c:setFlags("nuyan_unlimited") end
        if sp.mode=="wusheng" and suit==sgs.Card_Heart then c:setFlags("nuyan_free_enhance") end
        if sp.mode=="wusheng" and sp.extreme and #ids==1 and sgs.Sanguosha:getCard(ids[1]):isKindOf("TrickCard") then c:setFlags("nuyan_unlimited") end
        if sp.mode=="miaojian" then c:setFlags("nuyan_unlimited");if req:getInitiator():getMark("nuyan_miaojian_level")>=2 then c:setFlags("nuyan_enhanced") end end
        return c
    end
    local va=sgs.CreateViewAsSkillV2{
        name=sp.id,n=count,
        can_activate=function(self,req)
            local p=req:getInitiator();local reason=req:getReason();local pattern=req:getPattern()
            if cfg.cost and rage(p)<cfg.cost then return false end
            if sp.mode=="qice" and p:getMark(sp.id .. "_used-PlayClear")>0 then return false end
            if sp.mode=="manyi" and p:getMark(sp.id .. "_used-PlayClear")>=3 then return false end
            if sp.mode=="miaojian" then
                if p:getMark("nuyan_miaojian_level")>=3 then if p:getMark("@nuyan_ling")<1 then return false end
                elseif p:getMark(sp.id .. "_used-PlayClear")>=star(p) then return false end
            end
            if reason==sgs.CardUseStruct_CARD_USE_REASON_PLAY then
                if cfg.card=="jink" then return false end
                if cfg.card then local c=sgs.Sanguosha:cloneCard(cfg.card);if not c then return false end;c:setSkillName(sp.id);if cfg.unlimited then c:setFlags("nuyan_unlimited") end;local ok=c:isAvailable(p);c:deleteLater();return ok end
                return sp.mode=="qice" or not p:isKongcheng()
            end
            if not cfg.response then return false end
            if sp.mode=="wuhushangjiang" then return pattern=="slash" or pattern=="jink" or pattern=="peach" or pattern=="nullification" or pattern=="peach+analeptic" end
            if sp.mode=="jinghongmeiying" then return pattern=="slash" or pattern=="jink" end
            if sp.mode=="kanpo_native" and pattern=="nullification" then
                local c=sgs.Sanguosha:cloneCard(cfg.card);if not c then return false end;local ok=c:isKindOf("Nullification");c:deleteLater();return ok
            end
            return pattern==cfg.card or cfg.card=="peach" and pattern=="peach+analeptic"
        end,
        can_select_card=function(self,req,c)
            local ids=list(req:getSelectedCardIds());if sp.mode=="miaojian" and req:getInitiator():getMark("nuyan_miaojian_level")>=3 then return false end;return #ids<count and conversion_filter(sp,c,req:getInitiator(),ids,req)
        end,
        card_selection_feasible=function(self,req)
            local c=create(req);if not c then return false end
            local pattern=req:getPattern();local ok=req:getReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY or sgs.Sanguosha:matchExpPattern(pattern,req:getInitiator(),c)
            c:deleteLater();return ok
        end,
        create_card=function(self,req) return create(req) end
    }
    if sp.mode=="qice" then va:setGuhuoDialog("r") elseif sp.mode=="miaojian" then va:setGuhuoDialog("lr") end
    if sp.mode=="wuhushangjiang" or sp.mode=="kanpo_native" then va.response_pattern="nullification" end
    return va
end
local function draw_count(data) return data:toDraw().num end
local function set_draw_count(data,n) local x=data:toDraw();x.num=n;data:setValue(x) end
-- Trigger handlers are selected by the printed mode, with explicit event predicates.
local function handler(mode,events,eligible,effect) handlers[mode]={events=events,eligible=eligible,effect=effect} end
local function own(event,room,p,o,data) return p==o end
local function start(event,room,p,o,data) return p==o and phase(p,sgs.Player_Start) end
local function finish(event,room,p,o,data) return p==o and phase(p,sgs.Player_Finish) end
local function playstart(event,room,p,o,data) return p==o and phase(p,sgs.Player_Play) end
local function damaged_source(event,room,p,o,data) local d=data:toDamage();return p==o and d.from and d.from~=o and d.from:isAlive() end
local function target(event,room,p,o,data) local u=data:toCardUse();return p==o and u.from and u.from~=o and u.to:contains(o) and attack(u.card) end
local function dealt(event,room,p,o,data) local d=data:toDamage();return d.from==o end
handler("ganglie",{sgs.Damaged},function(e,r,p,o,d)return p==o and d:toDamage().from and d:toDamage().from:isAlive() end,function(sp,e,r,p,o,d)
    local q=d:toDamage().from;local options=q:getHandcardNum()>=2 and "nuyan_discard+nuyan_losehp" or "nuyan_losehp"
    if r:askForChoice(q,sp.id,options)=="nuyan_discard" then random_discard(r,q,2,"h",sp.id) else r:loseHp(q,1,true,o,sp.id) end
end)
handler("yiji",{sgs.Damaged},own,function(sp,e,r,p,o,d)local q=choose(r,o,sp.id);if q then draw(q,2*d:toDamage().damage,sp.id) end end)
handler("mengjin",{sgs.SlashMissed},function(e,r,p,o,d)return d:toSlashEffect().from==o end,function(sp,e,r,p,o,d)
    local s=d:toSlashEffect();if s.to:isAlive() and invoke(r,o,sp.id,d) then take(r,o,s.to,math.max(1,o:getMark("nuyan_jinks_" .. s.to:objectName())),"he",sp.id,true) end
end)
handler("kuanggu",{sgs.Damage},function(e,r,p,o,d)return dealt(e,r,p,o,d) and phase(o,sgs.Player_Play) end,function(sp,e,r,p,o,d)
    if not sp.classic then recover(r,o,1,o,sp.id) elseif d:toDamage().to~=o and invoke(r,o,sp.id,d) then
        if r:askForChoice(o,sp.id,"nuyan_recover+nuyan_draw")=="nuyan_recover" then recover(r,o,1,o,sp.id) else draw(o,1,sp.id) end
    end
end)
handler("lianying",{sgs.CardsMoveOneTime},function(e,r,p,o,d)local m=d:toMoveOneTime();return m.from and m.from:objectName()==o:objectName() and m.is_last_handcard and m.from_places:contains(sgs.Player_PlaceHand) end,function(sp,e,r,p,o,d)draw(o,2,sp.id) end)
handler("xuanfeng",{sgs.CardsMoveOneTime},function(e,r,p,o,d)local m=d:toMoveOneTime();return m.from and m.from:objectName()==o:objectName() and m.from_places:contains(sgs.Player_PlaceEquip) and phase(o,sgs.Player_Play) end,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_used-PlayClear")>0 then return end
    local q=choose(r,o,sp.id,function(q)return q~=o and o:canDiscard(q,"hej") end,true)
    if q then r:addPlayerMark(o,sp.id .. "_used-PlayClear");take(r,o,q,2,"hej",sp.id,true) end
end)
handler("shiyong",{sgs.TargetConfirmed},function(e,r,p,o,d)return target(e,r,p,o,d) and d:toCardUse().card:isBlack() end,function(sp,e,r,p,o,d)draw(o,1,sp.id) end)
handler("fankui",{sgs.Damaged},function(e,r,p,o,d)return p==o and d:toDamage().from and d:toDamage().from:isAlive() end,function(sp,e,r,p,o,d)
    if invoke(r,o,sp.id,d) then take(r,o,d:toDamage().from,d:toDamage().damage,"he",sp.id) end
end)
handler("jushou",{sgs.EventPhaseChanging},function(e,r,p,o,d)return p==o and d:toPhaseChange().to==sgs.Player_NotActive and rage(o)>0 end,function(sp,e,r,p,o,d)
    if invoke(r,o,sp.id,d) then local n=rage(o);add_rage(r,o,-n,o);draw(o,math.min(4,2*n),sp.id) end
end)
handler("jianxiong",{sgs.Damaged},own,function(sp,e,r,p,o,d)
    local x=d:toDamage();if x.card then local ids=x.card:isVirtualCard() and list(x.card:getSubcards()) or {x.card:getEffectiveId()};local available={}
        for _,id in ipairs(ids) do if r:getCardPlace(id)==sgs.Player_PlaceTable then available[#available+1]=id end end;obtain(r,o,available,sp.id)
    end
    -- Base rage gain is handled by the runtime; add the second half here.
    local overflow=add_rage(r,o,x.damage,x.from)
    if sp.jie and (overflow or o:getMark("nuyan_damage_overflow")>0) and x.from and x.from:isAlive() then
        if x.from:isNude() then damage(r,o,x.from,1,sp.id) else random_discard(r,x.from,1,"he",sp.id) end
    end
end)
handler("tuxi",{sgs.DrawNCards},own,function(sp,e,r,p,o,d)
    local n=draw_count(d);local used={};local count=0
    for i=1,n do local q=choose(r,o,sp.id,function(q)return q~=o and o:canGet(q,"h") and not used[q:objectName()] end,true)
        if not q then break end;used[q:objectName()]=true;take(r,o,q,1,"h",sp.id);count=count+1
    end
    set_draw_count(d,n-count)
end)
handler("shangshi",{sgs.CardsMoveOneTime,sgs.GameStart},function(e,r,p,o,d)
    if e==sgs.GameStart then return p==o end
    local m=d:toMoveOneTime();return m.from and m.from:objectName()==o:objectName() or m.to and m.to:objectName()==o:objectName()
end,function(sp,e,r,p,o,d)
    local n=sp.classic and (sp.jie and 4 or 3) or star(o)+(sp.jie and 1 or 0)
    if o:getHandcardNum()<n then draw(o,n-o:getHandcardNum(),sp.id) end
end)
handler("jiangchi",{sgs.DrawNCards},own,function(sp,e,r,p,o,d)
    if r:askForChoice(o,sp.id,"nuyan_draw+nuyan_slash")=="nuyan_draw" then set_draw_count(d,draw_count(d)+2)
    else r:addPlayerMark(o,"nuyan_slash-Clear",2);r:setPlayerMark(o,"nuyan_distance-Clear",1) end
end)
handler("miji",{sgs.TargetConfirmed},target,function(sp,e,r,p,o,d)
    if invoke(r,o,sp.id,d) then local from=d:toCardUse().from;r:loseHp(o,1,true,o,sp.id);nullify(d,o);if o:isAlive() and from:isAlive() then take(r,o,from,2,"he",sp.id,true) end end
end)
handler("duanliang",{sgs.EventPhaseSkipping},function(e,r,p,o,d)return phase(p,sgs.Player_Draw) end,function(sp,e,r,p,o,d)draw(o,1,sp.id) end)
handler("kangkai",{sgs.TargetConfirmed},function(e,r,p,o,d)local u=d:toCardUse();return u.card:isKindOf("Slash") and u.to:contains(p) and o:distanceTo(p)<=1 end,function(sp,e,r,p,o,d)
    if invoke(r,o,sp.id,d) then
        draw(o,1,sp.id);local c=r:askForExchange(o,sp.id,1,1,true,"nuyan_give",false)
        if c then local cid=c:getSubcards():first();r:obtainCard(p,c,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,o:objectName(),p:objectName(),sp.id,""),false);c:deleteLater();r:showCard(p,cid,sgs.SPlayerList(),sp.id)
            local eq=sgs.Sanguosha:getCard(cid);if eq:isKindOf("EquipCard") and eq:isAvailable(p) and invoke(r,p,sp.id) then local u=sgs.CardUseStruct();u.from=p;u.card=eq;r:useCard(u) end
        end
    end
end)
handler("qizhi",{sgs.TargetSpecified},function(e,r,p,o,d)local u=d:toCardUse();return u.from==o and o:getPhase()~=sgs.Player_NotActive and (u.card:isKindOf("BasicCard") or u.card:isKindOf("TrickCard")) end,function(sp,e,r,p,o,d)
    local u=d:toCardUse();local q=choose(r,o,sp.id,function(q)return not u.to:contains(q) and o:canDiscard(q,"he") end,true)
    if q then take(r,o,q,1,"he",sp.id,true);add_rage(r,q,1,o);if q==o then draw(o,1,sp.id) end end
end)
handler("renwang",{sgs.TargetConfirmed},target,function(sp,e,r,p,o,d)
    local q=d:toCardUse().from;add_rage(r,q,-1,o);r:askForDiscard(q,sp.id,1,1,false,true)
end)
handler("jizhi",{sgs.CardUsed},function(e,r,p,o,d)local c=d:toCardUse().card;return p==o and c and c:isKindOf("TrickCard") end,function(sp,e,r,p,o,d)
    if sp.jie or d:toCardUse().card:isNDTrick() then draw(o,1,sp.id) end
end)
handler("liegong",{sgs.TargetSpecified},function(e,r,p,o,d)local u=d:toCardUse();return u.from==o and u.card:isKindOf("Slash") end,function(sp,e,r,p,o,d)
    local u=d:toCardUse();for _,q in sgs.qlist(u.to) do if q:getHp()>=o:getHp() or sp.jie and q:getHandcardNum()>=o:getHandcardNum() then
        if sp.jie then norespond(d,q) else local l=o:getTag("Jink_" .. u.card:toString()):toIntList();local ts=list(u.to);for i,t in ipairs(ts) do if t==q then l:replace(i-1,0) end end;o:setTag("Jink_" .. u.card:toString(),sgs.QVariant(l)) end
    end end
end)
handler("tieqi",{sgs.TargetSpecified},function(e,r,p,o,d)local u=d:toCardUse();return u.from==o and u.card:isKindOf("Slash") end,function(sp,e,r,p,o,d)
    local u=d:toCardUse();local l=o:getTag("Jink_" .. u.card:toString()):toIntList()
    for i,q in ipairs(list(u.to)) do
        r:addPlayerMark(q,"Armor_Nullified");q:setTag("nuyan_armor_" .. u.card:toString(),sgs.QVariant(q:getTag("nuyan_armor_" .. u.card:toString()):toInt()+1))
        local c=judge(r,o,sp.id)
        local blocked=sp.jie and c:isBlack()
        if not blocked then blocked=not r:askForCard(q,".|" .. c:getSuitString(),"nuyan_discard",d,sgs.Card_MethodDiscard) end
        if blocked then l:replace(i-1,0) end
    end
    o:setTag("Jink_" .. u.card:toString(),sgs.QVariant(l))
end)
handler("lieren",{sgs.Damage},function(e,r,p,o,d)return dealt(e,r,p,o,d) and phase(o,sgs.Player_Play) and d:toDamage().to:isAlive() end,function(sp,e,r,p,o,d)
    if invoke(r,o,sp.id,d) then local x=d:toDamage();take(r,o,x.to,1,"he",sp.id);if sp.jie and x.damage>1 then draw(o,1,sp.id) end end
end)
handler("juejing",{sgs.DrawNCards},own,function(sp,e,r,p,o,d)set_draw_count(d,draw_count(d)+o:getLostHp()) end)
handler("xiaoji",{sgs.CardsMoveOneTime},function(e,r,p,o,d)local m=d:toMoveOneTime();return m.from and m.from:objectName()==o:objectName() and m.from_places:contains(sgs.Player_PlaceEquip) end,function(sp,e,r,p,o,d)
    local n=0;for _,place in sgs.qlist(d:toMoveOneTime().from_places) do if place==sgs.Player_PlaceEquip then n=n+1 end end
    for i=1,n do if invoke(r,o,sp.id,d) then if r:askForChoice(o,sp.id,"nuyan_draw+nuyan_recover")=="nuyan_draw" then draw(o,2,sp.id) else recover(r,o,1,o,sp.id) end end end
end)
handler("dujin",{sgs.DrawNCards},own,function(sp,e,r,p,o,d)set_draw_count(d,draw_count(d)+o:getEquips():length()) end)
handler("yinghun",{sgs.HpChanged},function(e,r,p,o,d)return p==o and o:getMark("nuyan_hp_delta")<0 end,function(sp,e,r,p,o,d)
    local q=choose(r,o,sp.id,function(q)return q~=o end,true)
    if q then if r:askForChoice(q,sp.id,"nuyan_draw+nuyan_discard")=="nuyan_draw" then draw(o,2,sp.id) else random_discard(r,q,2,"he",sp.id) end end
end)
handler("fenji",{sgs.CardsMoveOneTime},function(e,r,p,o,d)
    local m=d:toMoveOneTime();return m.from and m.from:getPhase()==sgs.Player_NotActive and m.from_places:contains(sgs.Player_PlaceHand)
end,function(sp,e,r,p,o,d)
    local q=r:findPlayerByObjectName(d:toMoveOneTime().from:objectName());if not q or not q:isAlive() or not invoke(r,o,sp.id,d) then return end
    r:loseHp(o,1,true,o,sp.id);if not o:isAlive() then return end
    local c=judge(r,o,sp.id);draw(q,c:isRed() and 2 or 1,sp.id);if o:getHp()<q:getHp() then draw(o,1,sp.id) end
end)
handler("haoshi",{sgs.DrawNCards,sgs.EventPhaseEnd},function(e,r,p,o,d)return p==o and (e==sgs.DrawNCards or phase(o,sgs.Player_Draw)) end,function(sp,e,r,p,o,d)
    if e==sgs.DrawNCards then set_draw_count(d,draw_count(d)+2) elseif o:getHandcardNum()>6 then
        local q=choose(r,o,sp.id,function(q)return q~=o and q:getHandcardNum()<o:getHandcardNum() end,true)
        if q then give(r,o,q,math.floor(o:getHandcardNum()/2),sp.id) end
    end
end)
handler("pojun",{sgs.TargetSpecified},function(e,r,p,o,d)local u=d:toCardUse();return u.from==o and u.card:isKindOf("Slash") end,function(sp,e,r,p,o,d)
    for _,q in sgs.qlist(d:toCardUse().to) do
        if not q:isKongcheng() and invoke(r,o,sp.id,sgs.QVariant(q)) then
            local n=math.min(q:getHandcardNum(),sp.classic and 4 or star(o)+1);local chosen={}
            for i=1,n do
                if i>1 and r:askForChoice(o,sp.id,"continue+nuyan_cancel")=="nuyan_cancel" then break end
                local cid=r:askForCardChosen(o,q,"h",sp.id);chosen[#chosen+1]=cid;q:addToPile("nuyan_pojun",cid,false)
            end
            if sp.classic then local eq,hastrick={},false;for _,cid in ipairs(chosen) do local c=sgs.Sanguosha:getCard(cid)
                if c:isKindOf("EquipCard") then eq[#eq+1]=cid elseif c:isKindOf("TrickCard") then hastrick=true end
            end
                if #eq>0 then local cid=eq[math.random(#eq)];r:throwCard(cid,nil,o) end;if hastrick then draw(o,1,sp.id) end
            end
        end
    end
end)
handler("ganlu",{sgs.EventPhaseStart},function(e,r,p,o,d)return p~=o and phase(p,sgs.Player_Finish) end,function(sp,e,r,p,o,d)
    local n=o:getMark("nuyan_cards_lost-Clear");if cap(o)>0 and n<=cap(o) and invoke(r,o,sp.id,d) then draw(o,n,sp.id) end
end)
handler("leifa",{sgs.CardUsed,sgs.CardResponded},function(e,r,p,o,d)
    local c=e==sgs.CardUsed and d:toCardUse().card or d:toCardResponse().m_card;return p==o and c and c:isKindOf("Jink")
end,function(sp,e,r,p,o,d)
    if sp.jie or invoke(r,o,sp.id,d) then local q=choose(r,o,sp.id);if q then r:loseHp(q,1,true,o,sp.id);if sp.jie then add_rage(r,o,1,o) end end end
end)
handler("tianming",{sgs.TargetConfirmed},function(e,r,p,o,d)local u=d:toCardUse();return p==o and u.card:isKindOf("Slash") and u.to:contains(o) end,function(sp,e,r,p,o,d)
    if not invoke(r,o,sp.id,d) then return end
    if not r:askForDiscard(o,sp.id,2,2,false,true) then return end;draw(o,2,sp.id)
    if sp.classic then local q=choose(r,o,sp.id,nil,true);if q then draw(q,1,sp.id);if q~=o then add_rage(r,o,1,o) end end
    else local q=choose(r,o,sp.id,function(q)return q~=o end,true);if q then give(r,o,q,1,sp.id) end end
end)
handler("zhichi",{sgs.DamageInflicted},function(e,r,p,o,d)return p==o and phase(o,sgs.Player_NotActive) and o:getMark("nuyan_rage_changed-Clear")>0 and d:toDamage().damage>1 end,function(sp,e,r,p,o,d)local x=d:toDamage();x.damage=x.damage-1;d:setValue(x) end)
handler("yicong",{sgs.PreHpLost,sgs.DamageCaused},own,function(sp,e,r,p,o,d)
    local n=sp.classic and 3 or star(o)
    if e==sgs.PreHpLost then return o:getHp()<=n end
    local x=d:toDamage()
    if sp.jie then if o:getHp()>n then r:loseHp(x.to,x.damage,true,o,sp.id);return true end
    elseif o:getHp()<=n then x.damage=x.damage+1;d:setValue(x) end
end)
handler("yongsi",{sgs.DrawNCards,sgs.EventPhaseStart},function(e,r,p,o,d)return p==o and (e==sgs.DrawNCards or phase(o,sgs.Player_Discard)) end,function(sp,e,r,p,o,d)
    if e==sgs.DrawNCards then local kingdoms={};for _,q in sgs.qlist(r:getAlivePlayers()) do kingdoms[q:getKingdom()]=true end;local n=1;for _ in pairs(kingdoms) do n=n+1 end;set_draw_count(d,draw_count(d)+n)
    else local options=o:canDiscard(o,"he") and "nuyan_discard+nuyan_losehp" or "nuyan_losehp"
        if r:askForChoice(o,sp.id,options)=="nuyan_discard" then r:askForDiscard(o,sp.id,1,1,false,true) else r:loseHp(o,1,true,o,sp.id) end
    end
end)
handler("xiahui",{sgs.CardsMoveOneTime},function(e,r,p,o,d)local m=d:toMoveOneTime();return m.from and m.from:objectName()==o:objectName() and m.to and m.to:objectName()~=o:objectName() and m.to_place==sgs.Player_PlaceHand end,function(sp,e,r,p,o,d)
    local m=d:toMoveOneTime();local q=r:findPlayerByObjectName(m.to:objectName())
    if not q then return end
    for _,cid in sgs.qlist(m.card_ids) do if sgs.Sanguosha:getCard(cid):isBlack() then
        r:setPlayerCardLimitation(q,"use,response,discard",tostring(cid),false);q:setTag("nuyan_xiahui_" .. cid,sgs.QVariant(true))
    end end
end)
handler("jianying",{sgs.CardUsed},function(e,r,p,o,d)return p==o and phase(o,sgs.Player_Play) and d:toCardUse().card:getTypeId()>0 end,function(sp,e,r,p,o,d)
    local c=d:toCardUse().card;local suit=o:getMark(sp.id .. "_suit-PlayClear");local num=o:getMark(sp.id .. "_number-PlayClear")
    local same=o:getMark(sp.id .. "_seen-PlayClear")>0 and (suit==c:getSuit()+1 or num==c:getNumber())
    r:setPlayerMark(o,sp.id .. "_suit-PlayClear",c:getSuit()+1);r:setPlayerMark(o,sp.id .. "_number-PlayClear",c:getNumber());r:setPlayerMark(o,sp.id .. "_seen-PlayClear",1)
    if same then draw(o,1,sp.id) end
end)
handler("luoshen",{sgs.EventPhaseStart},function(e,r,p,o,d)return p==o and phase(p,sgs.Player_RoundStart) end,function(sp,e,r,p,o,d)
    repeat local c=judge(r,o,sp.id);if r:getCardPlace(c:getEffectiveId())==sgs.Player_DiscardPile or r:getCardPlace(c:getEffectiveId())==sgs.Player_PlaceJudge then r:obtainCard(o,c,sp.id) end
        if not c:isBlack() or not o:isAlive() then break end
    until false
end)
handler("fangzhu",{sgs.HpChanged},function(e,r,p,o,d)return p==o and o:getMark("nuyan_hp_delta")<0 end,function(sp,e,r,p,o,d)
    local q=choose(r,o,sp.id,function(q)return q~=o end,true);if q then add_rage(r,q,-1,o);random_discard(r,q,2,"h",sp.id) end
end)
handler("chouce",{sgs.HpChanged},function(e,r,p,o,d)return p==o end,function(sp,e,r,p,o,d)
    local delta=o:getMark("nuyan_hp_delta");if delta==0 or not sp.classic and delta>0 or not invoke(r,o,sp.id,d) then return end
    local n=math.abs(delta);local c=judge(r,o,sp.id)
    if c:isBlack() then local q=choose(r,o,sp.id,function(q)return q~=o and o:canDiscard(q,"hej") end,true);if q then take(r,o,q,n+1,"hej",sp.id,true) end
    else local q=choose(r,o,sp.id);if q then draw(q,2*n,sp.id) end
        if not sp.classic then local t=r:findPlayerByObjectName(o:getTag("nuyan_xianfu_target"):toString());if t and t:isAlive() then draw(t,n,sp.id) end end
    end
end)
handler("shefu",{sgs.EventPhaseStart,sgs.CardUsed,sgs.CardResponded},function(e,r,p,o,d)
    if e==sgs.EventPhaseStart then return p==o and phase(o,sgs.Player_Finish) end
    return p~=o and phase(o,sgs.Player_NotActive)
end,function(sp,e,r,p,o,d)
    if e==sgs.EventPhaseStart then
        if not r:askForCard(o,".|.|.|hand","nuyan_discard",d,sgs.Card_MethodDiscard) then return end
        local choices,seen={},{}
        for cid=0,sgs.Sanguosha:getCardCount()-1 do
            local c=sgs.Sanguosha:getEngineCard(cid)
            if c and (c:isKindOf("BasicCard") or c:isKindOf("TrickCard")) and not seen[c:objectName()] then
                seen[c:objectName()]=true;choices[#choices+1]=c:objectName()
            end
        end
        if #choices==0 then return end
        table.sort(choices)
        for i=1,2 do local name=r:askForChoice(o,sp.id,table.concat(choices,"+"));r:addPlayerMark(o,sp.id .. "_ambush_" .. name) end
    else
        local c=e==sgs.CardUsed and d:toCardUse().card or d:toCardResponse().m_card;if not c or c:getTypeId()==0 then return end
        local mark=sp.id .. "_ambush_" .. c:objectName()
        if o:getMark(mark)>0 and invoke(r,o,sp.id,d) then
            r:removePlayerMark(o,mark)
            if e==sgs.CardUsed then local u=d:toCardUse();local t=u.nullified_list;table.insert(t,"_ALL_TARGETS");u.nullified_list=t;d:setValue(u)
            else local response=d:toCardResponse();response.nullified=true;d:setValue(response) end
        end
    end
end)
handler("pianchong",{sgs.EventPhaseStart,sgs.CardsMoveOneTime},function(e,r,p,o,d)
    if e==sgs.EventPhaseStart then return p==o and phase(o,sgs.Player_RoundStart) end
    local m=d:toMoveOneTime();return m.from and m.from:objectName()==o:objectName() and o:getMark("nuyan_pianchong")>0
end,function(sp,e,r,p,o,d)
    if e==sgs.EventPhaseStart then r:setPlayerMark(o,"nuyan_pianchong",0);return end
    local m=d:toMoveOneTime();local n=0
    for i,cid in ipairs(list(m.card_ids)) do local c=sgs.Sanguosha:getCard(cid)
        if list(m.from_places)[i]==sgs.Player_PlaceHand and (o:getMark("nuyan_pianchong")==1 and c:isRed() or o:getMark("nuyan_pianchong")==2 and c:isBlack()) then n=n+1 end
    end
    deck_card(r,o,sp.id,function(c)return o:getMark("nuyan_pianchong")==1 and c:isBlack() or o:getMark("nuyan_pianchong")==2 and c:isRed() end,n,false)
end)
handler("zhengnan",{sgs.HpChanged},function(e,r,p,o,d)return p and p:getMark("nuyan_hp_delta")<0 end,function(sp,e,r,p,o,d)
    local threshold=sp.classic and 2 or star(o);local mark=sp.id .. "_seen_" .. p:objectName()
    if p:getHp()>threshold or o:getMark(mark)>0 then return end;r:setPlayerMark(o,mark,1)
    local choices={};for _,id in ipairs({"nuyan_wusheng","nuyan_dangxian","nuyan_xinzhan"}) do
        local actual=o:hasSkill("nuyan_jichinanzheng") and id .. "_ji" or id
        if not o:hasSkill(actual) then choices[#choices+1]=actual end
    end
    if #choices==0 then draw(o,3,sp.id) else draw(o,1,sp.id);r:acquireSkill(o,r:askForChoice(o,sp.id,table.concat(choices,"+"))) end
end)
handler("xinzhan",{sgs.DamageCaused},function(e,r,p,o,d)return d:toDamage().from==o and d:toDamage().to~=o end,function(sp,e,r,p,o,d)
    if invoke(r,o,sp.id,d) then take(r,o,d:toDamage().to,1,"hej",sp.id);return true end
end)
handler("wuniang",{sgs.CardFinished},function(e,r,p,o,d)local u=d:toCardUse();return u.from==o and o:getPhase()~=sgs.Player_NotActive and u.card:isKindOf("Slash") end,function(sp,e,r,p,o,d)
    for _,q in sgs.qlist(d:toCardUse().to) do if q~=o and q:isAlive() and invoke(r,o,sp.id,sgs.QVariant(q)) then
        if r:askForUseSlashTo(q,o,"nuyan_slash",false) then draw(o,1,sp.id);r:addPlayerMark(o,"nuyan_slash-Clear") else draw(o,2,sp.id) end
    end end
end)
handler("fanghun",{sgs.TargetSpecified,sgs.TargetConfirmed},function(e,r,p,o,d)local u=d:toCardUse();return u.card:isKindOf("Slash") and (e==sgs.TargetSpecified and u.from==o or e==sgs.TargetConfirmed and p==o and u.to:contains(o)) end,function(sp,e,r,p,o,d)
    if full(o) then draw(o,1,sp.id) else add_rage(r,o,1,o) end
end)
handler("jiangang",{sgs.CardUsed,sgs.CardResponded,sgs.TargetConfirmed},function(e,r,p,o,d)
    local c=e==sgs.CardResponded and d:toCardResponse().m_card or d:toCardUse().card
    return p==o and c and (c:isKindOf("Slash") or c:isKindOf("Duel")) and (e~=sgs.TargetConfirmed or d:toCardUse().to:contains(o))
end,function(sp,e,r,p,o,d)add_rage(r,o,1,o) end)
handler("anxu",{sgs.HpChanged},function(e,r,p,o,d)return p and p:getMark("nuyan_hp_delta")<0 and (p==o or p==o:getNextAlive() or p==o:getLastAlive()) end,function(sp,e,r,p,o,d)
    if o:isNude() or not invoke(r,o,sp.id,d) then return end;random_discard(r,o,1,"he",sp.id);local q=choose(r,o,sp.id);if q then add_rage(r,q,-2,o) end
end)
handler("fenyin",{sgs.CardUsed},function(e,r,p,o,d)return p==o and o:getPhase()~=sgs.Player_NotActive and d:toCardUse().card:getTypeId()>0 end,function(sp,e,r,p,o,d)
    local c=d:toCardUse().card;local color=c:isRed() and 1 or c:isBlack() and 2 or 3
    local old=o:getMark(sp.id .. "_color-Clear");r:setPlayerMark(o,sp.id .. "_color-Clear",color);if old>0 and old~=color then draw(o,1,sp.id) end
end)
handler("hongyuan",{sgs.CardsMoveOneTime},function(e,r,p,o,d)
    local m=d:toMoveOneTime();if not m.to or m.to:objectName()~=o:objectName() or m.to_place~=sgs.Player_PlaceHand or m.reason.m_skillName=="nuyan_hongyuan" then return false end
    for _,cid in sgs.qlist(m.card_ids) do if sgs.Sanguosha:getCard(cid):isRed() then return true end end;return false
end,function(sp,e,r,p,o,d)
    if d:toMoveOneTime().reason.m_skillName==sp.id or o:getMark("nuyan_hongyuan_busy")>0 then return end
    r:setPlayerMark(o,"nuyan_hongyuan_busy",1)
    local q=choose(r,o,sp.id,function(q)return q~=o end,true);if q then draw(q,2,sp.id) else draw(o,1,sp.id) end
    r:setPlayerMark(o,"nuyan_hongyuan_busy",0)
end)
handler("shenwei",{sgs.DamageCaused},function(e,r,p,o,d)local x=d:toDamage();return x.from==o and x.card and x.card:isKindOf("Slash") end,function(sp,e,r,p,o,d)
    local x=d:toDamage();x.damage=x.damage+(sp.classic and rage(o) or math.max(0,rage(o)-rage(x.to)));d:setValue(x)
end)
handler("beige",{sgs.Damaged},damaged_source,function(sp,e,r,p,o,d)
    local c=r:askForCard(o,"..","nuyan_discard",d,sgs.Card_MethodDiscard);if c then if c:isRed() then draw(o,3,sp.id) else take(r,o,d:toDamage().from,2,"hej",sp.id,true) end end
end)
handler("guhuo",{sgs.TargetSpecified,sgs.DamageCaused},function(e,r,p,o,d)
    if e==sgs.DamageCaused then local x=d:toDamage();return x.from==o and x.card and x.card:isKindOf("Slash") end
    local u=d:toCardUse();return u.from==o and single(u.card)
end,function(sp,e,r,p,o,d)
    if e==sgs.DamageCaused then local x=d:toDamage();x.damage=x.damage+1;d:setValue(x)
    else local u=d:toCardUse();for _,q in sgs.qlist(r:getAlivePlayers()) do
        local pat=".|^" .. u.card:getSuitString();r:setPlayerCardLimitation(q,"response",pat,false)
        r:setPlayerCardLimitation(q,"use","Nullification|^" .. u.card:getSuitString(),false)
        q:setTag("nuyan_guhuo_" .. u.card:toString(),sgs.QVariant(u.card:getSuitString()))
    end end
end)
local function extra_target(room,o,u,id)
    local q=choose(room,o,id,function(q)
        return q~=u.from and not u.to:contains(q) and not u.from:isProhibited(q,u.card) and u.card:targetFilter(sgs.SPlayerList(),q,u.from)
    end,true)
    if q then u.to:append(q);room:sortByActionOrder(u.to);return true end
    return false
end
handler("bingzheng",{sgs.TargetSpecifying},function(e,r,p,o,d)local u=d:toCardUse();return u.from==o and o:getPhase()~=sgs.Player_NotActive and single(u.card) end,function(sp,e,r,p,o,d)
    local u=d:toCardUse();local mark=sp.id .. "_name_" .. u.card:objectName() .. "-Clear";if o:getMark(mark)>0 then return end
    r:setPlayerMark(o,mark,1)
    if not extra_target(r,o,u,sp.id) then u.card:setFlags("nuyan_effect_plus") end;d:setValue(u)
end)
handler("zenhui",{sgs.TargetSpecifying},function(e,r,p,o,d)local u=d:toCardUse();return u.from==o and phase(o,sgs.Player_Play) and attack(u.card) and u.to:length()==1 end,function(sp,e,r,p,o,d)
    local max=sp.classic and cap(o) or star(o);if o:getMark(sp.id .. "_used-PlayClear")>=max then return end
    local u=d:toCardUse();local q=choose(r,o,sp.id,function(q)return q~=o and not u.to:contains(q) and not o:isProhibited(q,u.card) end,true)
    if not q then
        local exists=false;for _,t in sgs.qlist(r:getOtherPlayers(o)) do if not u.to:contains(t) and not o:isProhibited(t,u.card) then exists=true end end
        if not exists then draw(o,1,sp.id) end;return
    end
    r:addPlayerMark(o,sp.id .. "_used-PlayClear")
    local opt=q:isKongcheng() and "target" or "give+target"
    if r:askForChoice(q,sp.id,opt)=="give" then local gid=random_ids(q:handCards(),1);if #gid>0 then local gc=dummy(gid);r:obtainCard(o,gc,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,q:objectName(),o:objectName(),sp.id,""),false);gc:deleteLater() end;u.from=q else u.to:append(q);r:sortByActionOrder(u.to) end
    d:setValue(u)
end)
handler("meibu",{sgs.EventPhaseStart},function(e,r,p,o,d)return p~=o and phase(p,sgs.Player_Play) end,function(sp,e,r,p,o,d)
    if r:askForCard(o,"..","nuyan_discard",d,sgs.Card_MethodDiscard) then r:addPlayerMark(p,"nuyan_meibu-PlayClear") end
end)
handler("longyin",{sgs.CardUsed},function(e,r,p,o,d)local u=d:toCardUse();return p and phase(p,sgs.Player_Play) and u.card:isKindOf("Slash") end,function(sp,e,r,p,o,d)
    local u=d:toCardUse();if r:askForCard(o,"..","nuyan_discard",d,sgs.Card_MethodDiscard) then
        if u.m_addHistory then r:addPlayerHistory(u.from,"Slash",-1);u.m_addHistory=false;d:setValue(u) end
        if u.card:isRed() then draw(o,1,sp.id) end
    end
end)
handler("zhuandui",{sgs.TargetSpecified,sgs.TargetConfirmed},function(e,r,p,o,d)local u=d:toCardUse();return u.card:isKindOf("Slash") and (e==sgs.TargetSpecified and u.from==o or e==sgs.TargetConfirmed and p==o and u.to:contains(o)) end,function(sp,e,r,p,o,d)
    local u=d:toCardUse();local targets=e==sgs.TargetSpecified and list(u.to) or {u.from}
    for _,q in ipairs(targets) do if q~=o and q:isAlive() and invoke(r,o,sp.id,sgs.QVariant(q)) then
        draw(o,1,sp.id);if o:canPindian(q) and o:pindian(q,sp.id,nil) then if e==sgs.TargetSpecified then norespond(d,q) else nullify(d,o) end end
    end end
end)
handler("yanyu",{sgs.CardsMoveOneTime},function(e,r,p,o,d)return o:getPhase()~=sgs.Player_NotActive and d:toMoveOneTime().to_place==sgs.Player_DiscardPile end,function(sp,e,r,p,o,d)
    local n=0;for _,cid in sgs.qlist(d:toMoveOneTime().card_ids) do if sgs.Sanguosha:getCard(cid):isKindOf("Slash") then n=n+1 end end
    for i=1,n do local q=choose(r,o,sp.id,nil,true);if q then add_rage(r,q,1,o);draw(o,1,sp.id);if q~=o then draw(o,1,sp.id);draw(q,1,sp.id) end end end
end)
handler("shicai",{sgs.CardFinished,sgs.CardResponded,sgs.DrawNCards},function(e,r,p,o,d)
    if e==sgs.DrawNCards then return p==o end
    local c=e==sgs.CardFinished and d:toCardUse().card or d:toCardResponse().m_card;return p==o and c and c:getTypeId()>0
end,function(sp,e,r,p,o,d)
    if e==sgs.DrawNCards then local x=d:toDraw();x.top=false;d:setValue(x);return end
    local c=e==sgs.CardFinished and d:toCardUse().card or d:toCardResponse().m_card
    local mark=sp.id .. "_type" .. c:getTypeId() .. "-Clear";if o:getMark(mark)>0 then return end;r:setPlayerMark(o,mark,1)
    local ids=c:isVirtualCard() and list(c:getSubcards()) or {c:getEffectiveId()};local available={}
    for _,cid in ipairs(ids) do local place=r:getCardPlace(cid);if place==sgs.Player_PlaceTable or place==sgs.Player_DiscardPile or place==sgs.Player_PlaceEquip and r:getCardOwner(cid)==o then available[#available+1]=cid end end
    if #available>0 and invoke(r,o,sp.id,d) then local v=dummy(available);r:moveCardTo(v,o,nil,sgs.Player_DrawPile,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,o:objectName(),sp.id,""),true);v:deleteLater();draw(o,1,sp.id) end
end)
handler("kongsheng",{sgs.EventPhaseStart,sgs.EventPhaseChanging},function(e,r,p,o,d)return p==o and (e==sgs.EventPhaseChanging and d:toPhaseChange().to==sgs.Player_NotActive or e==sgs.EventPhaseStart and (phase(o,sgs.Player_Start) or phase(o,sgs.Player_Finish))) end,function(sp,e,r,p,o,d)
    if e==sgs.EventPhaseChanging then obtain(r,o,list(o:getPile("nuyan_kong")),sp.id);return end
    if phase(o,sgs.Player_Start) then
        if o:isNude() then return end
        local c=r:askForExchange(o,sp.id,o:getCardCount(true),1,true,"nuyan_give",true)
        if not c then return end;local n=c:subcardsLength();o:addToPile("nuyan_kong",c,false);c:deleteLater()
        local q=choose(r,o,sp.id,function(q)return q~=o and o:canMove(q,"he") end,true)
        if q then local ids={};for _,t in sgs.qlist(q:getCards("he")) do if o:canMove(q,t:getEffectiveId()) then ids[#ids+1]=t:getEffectiveId() end end
            local taken=random_ids(ints(ids),n);o:addToPile("nuyan_kong",ints(taken),false);o:setTag(sp.id .. "_target",sgs.QVariant(q:objectName()));r:setPlayerMark(o,sp.id .. "_return",#taken)
        end
    else local q=r:findPlayerByObjectName(o:getTag(sp.id .. "_target"):toString());local n=o:getMark(sp.id .. "_return");local pool=o:getPile("nuyan_kong");local out={}
        if q and q:isAlive() then for i=1,math.min(n,pool:length()) do r:fillAG(pool,o);local cid=r:askForAG(o,pool,false,sp.id);r:clearAG(o);pool:removeOne(cid);out[#out+1]=cid end;if #out>0 then local gc=dummy(out);r:obtainCard(q,gc,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,o:objectName(),q:objectName(),sp.id,""),false);gc:deleteLater() end end
        r:setPlayerMark(o,sp.id .. "_return",0);o:removeTag(sp.id .. "_target")
    end
end)
handler("huituo",{sgs.Damaged},own,function(sp,e,r,p,o,d)
    local q=choose(r,o,sp.id,nil,true);if q then local c=judge(r,q,sp.id);local n=d:toDamage().damage;draw(q,c:isRed() and 1 or n,sp.id);recover(r,q,c:isRed() and n or 1,o,sp.id) end
end)
handler("xiaoguo",{sgs.EventPhaseStart},function(e,r,p,o,d)return p~=o and phase(p,sgs.Player_Finish) end,function(sp,e,r,p,o,d)
    local max=sp.classic and 3 or star(o);if max<=0 then return end
    local selected={};for i=1,max do local c=r:askForCard(o,"BasicCard","nuyan_discard",d,sgs.Card_MethodDiscard);if not c then break end;selected[#selected+1]=c end
    local n=#selected;if n>0 and not r:askForDiscard(p,sp.id,n,n,true,true) then damage(r,o,p,n,sp.id) end
end)
handler("benxi",{sgs.CardUsed,sgs.CardResponded,sgs.TargetSpecifying},function(e,r,p,o,d)return p==o and o:getPhase()~=sgs.Player_NotActive end,function(sp,e,r,p,o,d)
    if e~=sgs.TargetSpecifying then local c=e==sgs.CardUsed and d:toCardUse().card or d:toCardResponse().m_card;if c and c:getTypeId()>0 then r:addPlayerMark(o,"nuyan_benxi-Clear") end;return end
    local u=d:toCardUse();if u.to:length()~=1 or not (u.card:isKindOf("Slash") or u.card:isNDTrick()) then return end
    for _,q in sgs.qlist(r:getOtherPlayers(o)) do r:addPlayerMark(q,"Armor_Nullified");q:setTag("nuyan_armor_" .. u.card:toString(),sgs.QVariant(q:getTag("nuyan_armor_" .. u.card:toString()):toInt()+1)) end
    if not extra_target(r,o,u,sp.id) then take(r,o,u.to:first(),1,"he",sp.id) end;d:setValue(u)
end)
handler("qinzheng",{sgs.CardUsed,sgs.CardResponded},function(e,r,p,o,d)local c=e==sgs.CardUsed and d:toCardUse().card or d:toCardResponse().m_card;return p==o and c and c:getTypeId()>0 end,function(sp,e,r,p,o,d)
    r:addPlayerMark(o,sp.id .. "_count");local n=o:getMark(sp.id .. "_count")
    for _,rule in ipairs({{3,"Slash","Jink"},{5,"Peach","Analeptic"},{8,"ExNihilo","ExNihilo"}}) do if n%rule[1]==0 then deck_card(r,o,sp.id,function(c)return c:isKindOf(rule[2]) or c:isKindOf(rule[3]) end,1,true) end end
end)
handler("huiling",{sgs.CardUsed,sgs.CardResponded,sgs.CardFinished},function(e,r,p,o,d)local c=e==sgs.CardResponded and d:toCardResponse().m_card or d:toCardUse().card;return p==o and c and c:getTypeId()>0 end,function(sp,e,r,p,o,d)
    local red,black=0,0;for _,cid in sgs.qlist(r:getDiscardPile()) do local c=sgs.Sanguosha:getCard(cid);if c:isRed() then red=red+1 elseif c:isBlack() then black=black+1 end end
    local c=e==sgs.CardResponded and d:toCardResponse().m_card or d:toCardUse().card
    if e~=sgs.CardFinished then
        if red>black then if sp.classic then draw(o,1,sp.id) end;recover(r,o,1,o,sp.id) elseif black>red then if sp.classic then draw(o,1,sp.id) end;add_rage(r,o,1,o) end
    end
    if not sp.classic and (e==sgs.CardFinished or e==sgs.CardResponded and not d:toCardResponse().m_isUse) and (c:isRed() and red<=black or c:isBlack() and black<=red) then
        r:addPlayerMark(o,"@nuyan_ling");r:addPlayerMark(o,"nuyan_ling_gained")
        if o:getMark("nuyan_ling_gained")%3==0 then
            local choices={};if o:hasSkill("nuyan_lianhua") and o:getMark("nuyan_lianhua_level")<2 then choices[#choices+1]="nuyan_lianhua" end
            if o:hasSkill("nuyan_miaojian") and o:getMark("nuyan_miaojian_level")<2 then choices[#choices+1]="nuyan_miaojian" end
            if #choices>0 then local id=r:askForChoice(o,sp.id,table.concat(choices,"+"));r:setPlayerMark(o,id .. "_level",2) end
        end
    end
end)
handler("xizhan",{sgs.EventPhaseStart},function(e,r,p,o,d)return p~=o and phase(p,sgs.Player_RoundStart) end,function(sp,e,r,p,o,d)
    local c=r:askForCard(o,".|.|.|hand","nuyan_discard",d,sgs.Card_MethodDiscard);if not c then return end
    if c:getSuit()==sgs.Card_Spade then usecard(r,o,nil,"savage_assault",sp.id,true,false)
    elseif c:getSuit()==sgs.Card_Heart then local used={};for i=1,3 do local ids=deck_card(r,o,sp.id,function(t)return not used[t:getSuit()] end,1,false);if #ids>0 then used[sgs.Sanguosha:getCard(ids[1]):getSuit()]=true end end
    elseif c:getSuit()==sgs.Card_Club then random_discard(r,p,2,"h",sp.id)
    else local slash=sgs.Sanguosha:cloneCard("slash");slash:setFlags("nuyan_unlimited");if o:canSlash(p,slash,false) then usecard(r,o,p,slash,sp.id,true,true) else slash:deleteLater() end end
end)
handler("guowu",{sgs.EventPhaseStart},playstart,function(sp,e,r,p,o,d)
    if o:isKongcheng() or not invoke(r,o,sp.id,d) then return end;r:showAllCards(o);local types={};for _,c in sgs.qlist(o:getHandcards()) do types[c:getTypeId()]=true end
    local n=0;for _ in pairs(types) do n=n+1 end
    if n>=1 then r:setPlayerMark(o,"nuyan_no_enhanced_jink-PlayClear",1) end
    if n>=2 then r:addPlayerMark(o,"nuyan_slash-PlayClear",sp.classic and 5 or star(o)) end
    if n>=3 then deck_card(r,o,sp.id,function(c)return c:isKindOf("Slash") end,math.max(1,o:getLostHp()),true) end
end)
local function draw_until_slash(room,p,id)
    local collected={};local slash
    while p:isAlive() do
        local ids=room:getNCards(1);if ids:isEmpty() then break end
        local cid=ids:first();local c=sgs.Sanguosha:getCard(cid);collected[#collected+1]=cid
        room:moveCardTo(c,nil,nil,sgs.Player_PlaceTable,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER,p:objectName(),id,""),true)
        if c:isKindOf("Slash") then slash=c;break end
    end
    local kept,discarded={},{}
    for _,cid in ipairs(collected) do local c=sgs.Sanguosha:getCard(cid)
        if slash and c:getColor()==slash:getColor() then kept[#kept+1]=cid else discarded[#discarded+1]=cid end
    end
    obtain(room,p,kept,id);if #discarded>0 then local c=dummy(discarded);room:throwCard(c,nil,p);c:deleteLater() end
end
handler("dangxian",{sgs.EventPhaseStart},function(e,r,p,o,d)return p==o and phase(p,sgs.Player_RoundStart) end,function(sp,e,r,p,o,d)
    draw(o,1,sp.id);local phases=sgs.PhaseList();phases:append(sgs.Player_Play);o:play(phases)
    if sp.extreme and invoke(r,o,sp.id,d) then r:loseHp(o,1,true,o,sp.id);draw_until_slash(r,o,sp.id) end
end)
handler("jizhen",{sgs.EventPhaseStart},function(e,r,p,o,d)return p==o and phase(p,sgs.Player_RoundStart)  end,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_jizhen-Clear")>0 then return end
    local q=choose(r,o,sp.id,function(q)return o:canDiscard(q,"hej") end,true)
    if q then local c=sgs.Sanguosha:cloneCard("slash");active_effect(sp,r,o,{q},c);c:deleteLater() end
end)
-- Tian-shu levels are related skills; no undocumented upgrade rule is assumed.
local book_names={"changsheng","yinbing","xianshou","guizhou","leifa_book","shouyi","fue","chengshan"}
local function book_choices(o)
    local out={"changsheng","yinbing","xianshou","guizhou"}
    if o:hasSkill("nuyan_daitianxuanhua") then out[#out+1]="leifa_book" end
    if o:hasSkill("nuyan_fengxuyufeng") then for _,s in ipairs({"shouyi","fue","chengshan"}) do out[#out+1]=s end end
    return out
end
local function grant_book(room,o,name,first)
    local q=choose(room,o,name,nil,true);if not q then return false end
    local choices={};for _,s in ipairs(book_choices(o)) do if not q:hasSkill("nuyan_ts_" .. s) and (type(first)~="table" or not first["nuyan_ts_" .. s]) then choices[#choices+1]="nuyan_ts_" .. s end end
    if #choices==0 then return false end
    local skill=room:askForChoice(o,name,table.concat(choices,"+"));room:acquireSkill(q,skill);room:setPlayerMark(q,skill .. "_level",1)
    if type(first)=="table" then first[skill]=true end
    if o:hasSkill("nuyan_daitianxuanhua") then add_rage(room,o,1,o) end
    if o:hasSkill("nuyan_fengxuyufeng") then draw(o,1,name) end
    return true
end
handler("tianshu",{sgs.GameStart,sgs.EventAcquireSkill,sgs.EventPhaseStart,sgs.HpChanged},function(e,r,p,o,d)return p==o and (e==sgs.GameStart or e==sgs.EventAcquireSkill and o:getMark("nuyan_tianshu_entered")==0 or e==sgs.EventPhaseStart and phase(o,sgs.Player_Start) or e==sgs.HpChanged and o:getMark("nuyan_hp_delta")<0) end,function(sp,e,r,p,o,d)
    if e==sgs.GameStart or e==sgs.EventAcquireSkill then
        if o:getMark("nuyan_tianshu_entered")>0 then return end;r:setPlayerMark(o,"nuyan_tianshu_entered",1)
        local selected={}
        for i=1,(sp.classic and 3 or math.ceil(star(o)/2+1)) do if not grant_book(r,o,sp.id,selected) then break end end
    elseif invoke(r,o,sp.id,d) then grant_book(r,o,sp.id,false) end
end)
handler("ts_changsheng",{sgs.AskForPeaches},function(e,r,p,o,d)return d:toDying().who==o end,function(sp,e,r,p,o,d)
    local level=o:getMark(sp.id .. "_level");local mark=level>=2 and sp.id .. "-Clear" or sp.id .. "_lun"
    if o:getMark(mark)==0 then r:setPlayerMark(o,mark,1);recover(r,o,(level>=2 and 2 or 1)-o:getHp(),o,sp.id) end
end)
handler("ts_yinbing",{sgs.DamageCaused},dealt,function(sp,e,r,p,o,d)
    local x=d:toDamage();x.damage=x.damage-1;if o:getMark(sp.id .. "_level")>=2 then add_rage(r,o,-1,o) end
    if x.damage<=0 then return true end;d:setValue(x)
end)
handler("ts_xianshou",{sgs.CardsMoveOneTime},function(e,r,p,o,d)local m=d:toMoveOneTime();return m.to and m.to:objectName()==o:objectName() and m.to_place==sgs.Player_PlaceHand and m.reason.m_skillName~="nuyan_ts_xianshou" end,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_busy")>0 then return end
    local n=o:getMark(sp.id .. "_count")+d:toMoveOneTime().card_ids:length();local step=o:getMark(sp.id .. "_level")>=2 and 3 or 4
    r:setPlayerMark(o,sp.id .. "_count",n%step);r:setPlayerMark(o,sp.id .. "_busy",1);draw(o,math.floor(n/step),sp.id);r:setPlayerMark(o,sp.id .. "_busy",0)
end)
handler("ts_guizhou",{sgs.CardsMoveOneTime},function(e,r,p,o,d)local m=d:toMoveOneTime();return m.from and m.from:objectName()==o:objectName() and m.reason.m_skillName~="nuyan_ts_guizhou" end,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_busy")>0 then return end
    local n=o:getMark(sp.id .. "_count")+d:toMoveOneTime().card_ids:length();local step=o:getMark(sp.id .. "_level")>=2 and 3 or 4
    r:setPlayerMark(o,sp.id .. "_count",n%step);r:setPlayerMark(o,sp.id .. "_busy",1);random_discard(r,o,math.floor(n/step),"he",sp.id);r:setPlayerMark(o,sp.id .. "_busy",0)
end)
handler("ts_leifa_book",{sgs.CardUsed,sgs.CardResponded},function(e,r,p,o,d)local c=e==sgs.CardUsed and d:toCardUse().card or d:toCardResponse().m_card;return p==o and c and c:getSuit()==sgs.Card_Diamond end,function(sp,e,r,p,o,d)
    local q=choose(r,o,sp.id,function(q)return q~=o end);if q then if o:getMark(sp.id .. "_level")>=2 then r:loseHp(q,1,true,o,sp.id) else damage(r,o,q,1,sp.id,sgs.DamageStruct_Thunder) end end
end)
handler("ts_shouyi",{sgs.EventPhaseStart,sgs.EventPhaseEnd},function(e,r,p,o,d)return p==o and phase(o,sgs.Player_Play) end,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_level")>=2 then r:loseHp(o,1,true,o,sp.id) else damage(r,nil,o,1,sp.id,sgs.DamageStruct_Thunder) end
end)
handler("ts_fue",{sgs.DamageInflicted,sgs.PreHpLost},own,function(sp,e,r,p,o,d)
    if e==sgs.PreHpLost then if o:getMark(sp.id .. "_level")>=2 then local x=d:toHpLost();x.lose=x.lose+1;d:setValue(x) end
    else local x=d:toDamage();if x.nature==sgs.DamageStruct_Thunder then x.damage=x.damage+1;d:setValue(x) end end
end)
handler("ts_chengshan",{sgs.DamageCaused},dealt,function(sp,e,r,p,o,d)
    local x=d:toDamage();if o:getMark(sp.id .. "_level")>=2 then r:loseHp(x.to,x.damage,true,o,sp.id);return true else x.nature=sgs.DamageStruct_Thunder;d:setValue(x) end
end)
handler("lianhua",{sgs.TargetConfirmed},function(e,r,p,o,d)local u=d:toCardUse();return p==o and u.from~=o and u.card:isKindOf("Slash") and u.to:contains(o) end,function(sp,e,r,p,o,d)
    draw(o,1,sp.id);local level=o:getMark("nuyan_lianhua_level")
    if level>=3 then if judge(r,o,sp.id):isBlack() then nullify(d,o) end
    elseif level>=2 then if not r:askForCard(d:toCardUse().from,"..","nuyan_discard",d,sgs.Card_MethodDiscard) then nullify(d,o) end end
end)
-- Optional bonds: effect-only IDs. Their printed star/partner unlock conditions are
-- deliberately not auto-granted; hosts may acquire these related skills explicitly.
handler("bond_hand",{sgs.GameStart},function()return false end,function()end)
handler("bond_initial_rage",{sgs.GameStart},own,function(sp,e,r,p,o,d)add_rage(r,o,1,o) end)
handler("bond_initial_hp",{sgs.GameStart},own,function(sp,e,r,p,o,d)r:setPlayerProperty(o,"maxhp",sgs.QVariant(o:getMaxHp()+1));r:setPlayerProperty(o,"hp",sgs.QVariant(o:getHp()+1)) end)
handler("bond_judge",{sgs.FinishJudge},function(e,r,p,o,d)return d:toJudge().who==o end,function(sp,e,r,p,o,d)
    local c=d:toJudge().card;if c and (r:getCardPlace(c:getEffectiveId())==sgs.Player_PlaceJudge or r:getCardPlace(c:getEffectiveId())==sgs.Player_DiscardPile) then r:obtainCard(o,c,sp.id) end
    if sp.extra_rage then add_rage(r,o,1,o) end
end)
handler("bond_hplost_draw",{sgs.HpLost},own,function(sp,e,r,p,o,d)draw(o,1,sp.id) end)
handler("bond_slash_rage",{sgs.Damage},function(e,r,p,o,d)local x=d:toDamage();return x.from==o and x.card and x.card:isKindOf("Slash") end,function(sp,e,r,p,o,d)add_rage(r,o,1,o) end)
handler("bond_immune",{sgs.DamageInflicted},function(e,r,p,o,d,sp)return p==o and d:toDamage().card and d:toDamage().card:isKindOf(sp.card_kind) end,function(sp,e,r,p,o,d)
    return d:toDamage().card:isKindOf(sp.card_kind)
end)
handler("bond_end_attack",{sgs.EventPhaseStart},finish,function(sp,e,r,p,o,d)
    local q=choose(r,o,sp.id,function(q)return q~=o and (sp.jie and q:getHandcardNum()<=o:getHandcardNum() or not sp.jie and q:getHandcardNum()<o:getHandcardNum()) end,true)
    if q then if sp.jie then r:loseHp(q,1,true,o,sp.id) else damage(r,o,q,1,sp.id) end end
end)
handler("bond_draw_slash",{sgs.DrawNCards},own,function(sp,e,r,p,o,d)deck_card(r,o,sp.id,function(c)return c:isKindOf("Slash") end,1,false) end)
handler("bond_death_heal",{sgs.Death},function(e,r,p,o,d)return d:toDeath().who~=o and o:isWounded() end,function(sp,e,r,p,o,d)recover(r,o,1,o,sp.id) end)
handler("bond_niepan",{sgs.AskForPeaches},function(e,r,p,o,d)return d:toDying().who==o end,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_spent")>0 or not invoke(r,o,sp.id,d) then return end
    r:setPlayerMark(o,sp.id .. "_spent",1);o:throwAllHandCards();add_rage(r,o,-rage(o),o);recover(r,o,star(o)-o:getHp(),o,sp.id);draw(o,star(o),sp.id)
end)
handler("bond_dying_heal",{sgs.AskForPeaches},function(e,r,p,o,d)return d:toDying().who==o end,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_spent")>0 or not invoke(r,o,sp.id,d) then return end
    r:setPlayerMark(o,sp.id .. "_spent",1);recover(r,o,(sp.value or 3)-o:getHp(),o,sp.id)
end)
handler("bond_gender",{sgs.Damage,sgs.DamageInflicted},function(e,r,p,o,d)local x=d:toDamage();return e==sgs.Damage and x.from==o and x.to:isFemale() or e==sgs.DamageInflicted and x.to==o and x.from and x.from:isFemale() and x.card and x.card:isKindOf("Slash") end,function(sp,e,r,p,o,d)
    if e==sgs.Damage then recover(r,o,1,o,sp.id) else local x=d:toDamage();x.damage=x.damage-1;if x.damage<=0 then return true end;d:setValue(x) end
end)
handler("bond_discard_all",{sgs.EventPhaseStart},playstart,function(sp,e,r,p,o,d)
    if invoke(r,o,sp.id,d) then for _,q in sgs.qlist(r:getOtherPlayers(o)) do r:askForDiscard(q,sp.id,1,1,false,true) end end
end)
handler("bond_colour_draw",{sgs.EventPhaseChanging},function(e,r,p,o,d)return p==o and d:toPhaseChange().to==sgs.Player_NotActive end,function(sp,e,r,p,o,d)
    if o:isKongcheng() then return end;local red,black=false,false
    for _,c in sgs.qlist(o:getHandcards()) do if c:isRed() then red=true elseif c:isBlack() then black=true end end
    if not (red and black) then draw(o,2,sp.id) end
end)
handler("bond_thunder_immune",{sgs.DamageInflicted,sgs.DamageCaused},function(e,r,p,o,d)local x=d:toDamage();return x.to==o and x.card and x.card:isKindOf("Lightning") or x.from==o and x.card and x.card:isKindOf("Slash") end,function(sp,e,r,p,o,d)
    local x=d:toDamage();if e==sgs.DamageInflicted then return true end
    if x.to:containsTrick("lightning") then x.damage=x.damage+1;d:setValue(x) end
end)
handler("bond_lightning_get",{sgs.CardsMoveOneTime},function(e,r,p,o,d)return d:toMoveOneTime().to_place==sgs.Player_DiscardPile end,function(sp,e,r,p,o,d)
    local ids={};for _,cid in sgs.qlist(d:toMoveOneTime().card_ids) do if sgs.Sanguosha:getCard(cid):isKindOf("Lightning") and r:getCardPlace(cid)==sgs.Player_DiscardPile then ids[#ids+1]=cid end end;obtain(r,o,ids,sp.id)
end)
handler("bond_card_slash_draw",{sgs.CardUsed,sgs.CardResponded,sgs.TargetConfirmed},function(e,r,p,o,d)local c=e==sgs.CardResponded and d:toCardResponse().m_card or d:toCardUse().card;return p==o and c and c:isKindOf("Slash") and (e~=sgs.TargetConfirmed or d:toCardUse().to:contains(o)) end,function(sp,e,r,p,o,d)draw(o,1,sp.id) end)
handler("bond_qijin",{sgs.CardUsed,sgs.CardResponded},function(e,r,p,o,d)local c=e==sgs.CardUsed and d:toCardUse().card or d:toCardResponse().m_card;return p==o and phase(o,sgs.Player_NotActive) and c and c:subcardsLength()>0 end,function(sp,e,r,p,o,d)draw(o,1,sp.id) end)
handler("bond_xianfu",{sgs.GameStart,sgs.Damaged,sgs.HpRecover},function(e,r,p,o,d)return e==sgs.GameStart and p==o or p==o or p and p:objectName()==o:getTag("nuyan_xianfu_target"):toString() end,function(sp,e,r,p,o,d)
    if e==sgs.GameStart then local q=choose(r,o,sp.id,function(q)return q~=o end);if q then o:setTag("nuyan_xianfu_target",sgs.QVariant(q:objectName())) end
    elseif e==sgs.Damaged then if p~=o then damage(r,nil,o,1,sp.id) end
    else
        local rec=d:toRecover();if o:getMark(sp.id .. "_busy")>0 then return end
        r:setPlayerMark(o,sp.id .. "_busy",1)
        if p==o then local q=r:findPlayerByObjectName(o:getTag("nuyan_xianfu_target"):toString());if q and invoke(r,o,sp.id,d) then recover(r,q,1,o,sp.id) end
        else recover(r,o,rec.recover,p,sp.id) end;r:setPlayerMark(o,sp.id .. "_busy",0)
    end
end)
handler("chengxiang",{sgs.Damaged},own,function(sp,e,r,p,o,d)
    local ids=r:getNCards(4);local pool=ids;local selected={};local sum=0
    local reveal=dummy(list(ids));r:moveCardTo(reveal,nil,nil,sgs.Player_PlaceTable,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER,o:objectName(),sp.id,""),true);reveal:deleteLater()
    r:fillAG(pool);r:clearAG()
    while not pool:isEmpty() do
        local disabled=sgs.IntList();for _,cid in sgs.qlist(pool) do if sum+sgs.Sanguosha:getCard(cid):getNumber()>13 then disabled:append(cid) end end
        if disabled:length()==pool:length() then break end
        r:clearAG(o);r:fillAG(pool,o,disabled);local cid=r:askForAG(o,pool,true,sp.id);if cid<0 then break end
        sum=sum+sgs.Sanguosha:getCard(cid):getNumber();selected[#selected+1]=cid;pool:removeOne(cid)
    end
    r:clearAG(o);obtain(r,o,selected,sp.id)
    if not pool:isEmpty() then local c=dummy(list(pool));r:throwCard(c,nil,o);c:deleteLater() end
end)
-- Enjoyment is checked after the whole targeting card, rather than once for
-- every individual damage event (one card can cause more than one damage).
handler("xiangle",{sgs.TargetConfirmed,sgs.Damaged,sgs.CardFinished},function(e,r,p,o,d)
    if e==sgs.Damaged then return p==o and d:toDamage().card~=nil end
    local u=d:toCardUse();return e==sgs.TargetConfirmed and p==o and u.from~=o and u.to:contains(o) and attack(u.card) or e==sgs.CardFinished and u.card and o:getTag("nuyan_xiangle_" .. u.card:toString()):toBool()
end,function(sp,e,r,p,o,d)
    if e==sgs.TargetConfirmed then o:setTag("nuyan_xiangle_" .. d:toCardUse().card:toString(),sgs.QVariant(true))
    elseif e==sgs.Damaged then local x=d:toDamage();local key="nuyan_xiangle_damage_" .. x.card:toString();o:setTag(key,sgs.QVariant(o:getTag(key):toInt()+x.damage))
    else local u=d:toCardUse();local key="nuyan_xiangle_damage_" .. u.card:toString();local n=o:getTag(key):toInt();o:removeTag(key);o:removeTag("nuyan_xiangle_" .. u.card:toString())
        if n<(sp.jie and 2 or 1) and u.from and u.from:isAlive() then damage(r,nil,u.from,1,sp.id) end
    end
end)
handler("zhuhai",{sgs.MarkChanged},function(e,r,p,o,d)local m=d:toMark();return p~=o and p and p:getPhase()~=sgs.Player_NotActive and m.name=="@nuyan_nuqi" and m.gain>0 end,function(sp,e,r,p,o,d)
    if r:askForCard(o,"..","nuyan_discard",d,sgs.Card_MethodDiscard) then r:loseHp(p,1,true,o,sp.id) end
end)
handler("bond_dying_maxhp",{sgs.AskForPeaches},function(e,r,p,o,d)return d:toDying().who==o end,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_spent")>0 then return end;r:setPlayerMark(o,sp.id .. "_spent",1)
    r:loseMaxHp(o,1);recover(r,o,3-o:getHp(),o,sp.id)
end)
handler("bond_round_basic",{sgs.Damaged},own,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_lun")>0 then return end;r:setPlayerMark(o,sp.id .. "_lun",1)
    deck_card(r,o,sp.id,function(c)return c:isKindOf("Slash") end,1,false)
    deck_card(r,o,sp.id,function(c)return c:isKindOf("Jink") end,1,false)
end)
handler("bond_damage_hand",{sgs.Damage},dealt,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_used-Clear")>0 or not invoke(r,o,sp.id,d) then return end;r:setPlayerMark(o,sp.id .. "_used-Clear",1)
    local q=d:toDamage().to;local n=math.min(10,math.abs(q:getHandcardNum()-q:getHp()));draw(o,n,sp.id);r:addPlayerMark(o,"nuyan_bonus_hand-Clear",n)
end)
handler("bond_last_hand",{sgs.CardsMoveOneTime},function(e,r,p,o,d)local m=d:toMoveOneTime();return m.from and m.from:objectName()==o:objectName() and m.is_last_handcard end,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_spent")==0 then r:setPlayerMark(o,sp.id .. "_spent",1);draw(o,2,sp.id) end
end)
handler("bond_first_damage_draw",{sgs.Damaged},own,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_spent")==0 then r:setPlayerMark(o,sp.id .. "_spent",1);draw(o,1,sp.id) end
end)
handler("bond_first_damage_one",{sgs.DamageInflicted},own,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_spent")==0 then r:setPlayerMark(o,sp.id .. "_spent",1);local x=d:toDamage();x.damage=1;d:setValue(x) end
end)
handler("bond_first_slash_duel",{sgs.Damaged},function(e,r,p,o,d)local x=d:toDamage();return p==o and x.card and (x.card:isKindOf("Slash") or x.card:isKindOf("Duel")) end,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_spent")==0 then r:setPlayerMark(o,sp.id .. "_spent",1)
        local c=d:toDamage().card;local ids=c:isVirtualCard() and list(c:getSubcards()) or {c:getEffectiveId()};local out={}
        for _,cid in ipairs(ids) do if r:getCardPlace(cid)==sgs.Player_PlaceTable then out[#out+1]=cid end end;obtain(r,o,out,sp.id)
    end
end)
handler("bond_double_rage",{sgs.Damaged},own,function(sp,e,r,p,o,d)add_rage(r,o,d:toDamage().damage,d:toDamage().from) end)
handler("bond_lost_rage",{sgs.HpLost},own,function(sp,e,r,p,o,d)add_rage(r,o,d:toHpLost().lose,o) end)
handler("bond_repeat_slash",{sgs.SlashMissed},function(e,r,p,o,d)return d:toSlashEffect().from==o end,function(sp,e,r,p,o,d)
    local q=d:toSlashEffect().to;if q:isAlive() and invoke(r,o,sp.id,d) then r:askForUseSlashTo(o,q,"nuyan_slash",false) end
end)
handler("bond_heart_give",{sgs.Damaged},damaged_source,function(sp,e,r,p,o,d)
    if sp.limited and o:getMark(sp.id .. "_spent")>0 then return end
    if sp.limited then r:setPlayerMark(o,sp.id .. "_spent",1) end
    local q=d:toDamage().from;local c=r:askForCard(q,".|diamond|.|hand","nuyan_give",d,sgs.Card_MethodNone)
    if c then r:obtainCard(o,c,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,q:objectName(),o:objectName(),sp.id,""),false) else r:loseHp(q,1,true,o,sp.id) end
end)
handler("bond_red_judge",{sgs.CardsMoveOneTime},function(e,r,p,o,d)local m=d:toMoveOneTime();return phase(o,sgs.Player_NotActive) and m.from and m.from:objectName()==o:objectName() end,function(sp,e,r,p,o,d)
    if invoke(r,o,sp.id,d) then local c=judge(r,o,sp.id);if c:getSuit()==sgs.Card_Heart then r:obtainCard(o,c,sp.id) end end
end)
handler("bond_recover_draw",{sgs.HpRecover},function(e,r,p,o,d)return p and phase(p,sgs.Player_Play) end,function(sp,e,r,p,o,d)
    if invoke(r,o,sp.id,d) then if r:askForChoice(o,sp.id,"other+self")=="other" then draw(p,2,sp.id) else draw(o,1,sp.id) end end
end)
handler("bond_end_hpdamage",{sgs.EventPhaseStart},finish,function(sp,e,r,p,o,d)
    local q=choose(r,o,sp.id,function(q)return q~=o and q:getHandcardNum()<o:getHandcardNum() end,true);if q then damage(r,o,q,1,sp.id) end
end)
handler("bond_end_destroy",{sgs.EventPhaseStart},finish,function(sp,e,r,p,o,d)
    if not invoke(r,o,sp.id,d) then return end
    for _,q in sgs.qlist(r:getOtherPlayers(o)) do if q:getMark("nuyan_cards_lost-Clear")>0 then damage(r,o,q,1,sp.id) end end
end)
handler("bond_end_star_heal",{sgs.EventPhaseChanging},function(e,r,p,o,d)return d:toPhaseChange().to==sgs.Player_NotActive and (o:getHp()<=star(o) or o:getHandcardNum()<=star(o)) end,function(sp,e,r,p,o,d)recover(r,o,1,o,sp.id);draw(o,1,sp.id) end)
handler("bond_fenxin_gender",{sgs.CardUsed},function(e,r,p,o,d)return p==o and d:toCardUse().card:getSkillName():find("fenxin",1,true)~=nil end,function(sp,e,r,p,o,d)
    local q=d:toCardUse().to:first();if q and q:isFemale() then add_rage(r,o,1,o) end
    if q and (q:getGeneralName():find("lvlingqi",1,true) or q:getGeneral2Name():find("lvlingqi",1,true)) then draw(o,1,sp.id) end
end)
handler("bond_gender_maxhp",{sgs.GameStart,sgs.Death,sgs.EventAcquireSkill},function()return true end,function(sp,e,r,p,o,d)
    local n=0;for _,q in sgs.qlist(r:getOtherPlayers(o)) do
        if q:getGeneral():isFemale() then n=n+1 end
        if q:getGeneral2() and q:getGeneral2():isFemale() then n=n+1 end
    end
    local old=o:getMark(sp.id .. "_female");if n~=old then r:setPlayerProperty(o,"maxhp",sgs.QVariant(o:getMaxHp()+n-old));r:setPlayerMark(o,sp.id .. "_female",n) end
end)
handler("bond_shield_nuqi",{sgs.DamageInflicted},own,function(sp,e,r,p,o,d)
    if rage(o)>=1 and invoke(r,o,sp.id,d) then pay(r,o,1);local x=d:toDamage();x.damage=x.damage-1;if x.damage<=0 then return true end;d:setValue(x) end
end)
handler("bond_initial_extra_draw",{sgs.DrawNCards},own,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_spent")==0 then r:setPlayerMark(o,sp.id .. "_spent",1);set_draw_count(d,draw_count(d)+1) end
end)
handler("bond_end_empty_draw",{sgs.EventPhaseStart},finish,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_spent")==0 and invoke(r,o,sp.id,d) then r:setPlayerMark(o,sp.id .. "_spent",1);draw(o,o:isKongcheng() and 2 or 1,sp.id) end
end)
handler("bond_first_turn_draw",{sgs.EventPhaseChanging},function(e,r,p,o,d)return p==o and d:toPhaseChange().to==sgs.Player_NotActive end,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_spent")==0 then r:setPlayerMark(o,sp.id .. "_spent",1);draw(o,2,sp.id) end
end)
handler("bond_prepare_random",{sgs.EventPhaseStart},function(e,r,p,o,d)return p==o and phase(o,sgs.Player_Draw) end,function(sp,e,r,p,o,d)
    if math.random(2)==1 then r:addPlayerMark(o,"nuyan_extra_draw-DrawClear") else add_rage(r,o,1,o) end
end)
handler("bond_return_clubs",{sgs.CardsMoveOneTime},function(e,r,p,o,d)local m=d:toMoveOneTime();local reason=bit32.band(m.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON);return (m.from and m.from:objectName()~=o:objectName() or not m.from and m.reason.m_playerId~=o:objectName()) and m.to_place==sgs.Player_DiscardPile and (reason==sgs.CardMoveReason_S_REASON_DISCARD or reason==sgs.CardMoveReason_S_REASON_JUDGEDONE) end,function(sp,e,r,p,o,d)
    if sp.limited and o:getMark(sp.id .. "_spent")>0 then return end
    local ids={};for _,cid in sgs.qlist(d:toMoveOneTime().card_ids) do if sgs.Sanguosha:getCard(cid):getSuit()==sgs.Card_Club and r:getCardPlace(cid)==sgs.Player_DiscardPile then ids[#ids+1]=cid end end
    if #ids>0 and invoke(r,o,sp.id,d) then if sp.limited then r:setPlayerMark(o,sp.id .. "_spent",1) end;obtain(r,o,ids,sp.id) end
end)
handler("bond_weapon_gender",{sgs.TargetSpecified},function(e,r,p,o,d)local u=d:toCardUse();return u.from==o and u.card:isKindOf("Slash") and o:getWeapon() end,function(sp,e,r,p,o,d)
    if o:getMark(sp.id .. "_spent")>0 then return end
    for _,q in sgs.qlist(d:toCardUse().to) do if q:isFemale() then r:setPlayerMark(o,sp.id .. "_spent",1)
        if r:askForChoice(q,sp.id,"nuyan_discard+nuyan_draw")=="nuyan_discard" then r:askForDiscard(q,sp.id,1,1,false,true) else draw(o,1,sp.id) end;break
    end end
end)
handler("bond_end_thunder",{sgs.EventPhaseEnd},function(e,r,p,o,d)return p==o and phase(o,sgs.Player_Play) end,function(sp,e,r,p,o,d)
    if o:getHandcardNum()%2==1 then local q=choose(r,o,sp.id,function(q)return q~=o end);if q then damage(r,o,q,1,sp.id,sgs.DamageStruct_Thunder) end
    else local q=choose(r,o,sp.id,function(q)return q~=o and o:canDiscard(q,"h") end,true);if q then take(r,o,q,1,"h",sp.id,true) end end
end)
handler("bond_damage_colours",{sgs.EventPhaseChanging},function(e,r,p,o,d)return p==o and d:toPhaseChange().to==sgs.Player_NotActive end,function(sp,e,r,p,o,d)
    local colors={};for _,c in sgs.qlist(o:getHandcards()) do if c:isRed() then colors.red=true elseif c:isBlack() then colors.black=true end end
    local n=0;for _ in pairs(colors) do n=n+1 end;local q=choose(r,o,sp.id,function(q)return q~=o and o:canGet(q,"h") end,true)
    if q then local gettable={};for _,cid in sgs.qlist(q:handCards()) do if o:canGet(q,cid) then gettable[#gettable+1]=cid end end;obtain(r,o,random_ids(ints(gettable),n),sp.id) end
end)
handler("bond_nuqi_guowu",{sgs.DamageCaused},function(e,r,p,o,d)local x=d:toDamage();return x.from==o and x.card and x.card:isKindOf("Slash") end,function(sp,e,r,p,o,d)
    local x=d:toDamage();x.damage=x.damage+math.max(0,o:getMark("nuyan_play_slashes-PlayClear"));d:setValue(x)
end)

handler("bond_hanhua_grant",{sgs.GameStart,sgs.EventAcquireSkill},own,function(sp,e,r,p,o,d)
    local id=sp.label=="莲华熠熠" and "nuyan_lianhua" or "nuyan_miaojian"
    if not o:hasSkill(id) then r:acquireSkill(o,id) end
    if o:getMark(id .. "_level")==0 then r:setPlayerMark(o,id .. "_level",1) end
end)
handler("xinzhan_ji",{sgs.Damage},function(e,r,p,o,d)return dealt(e,r,p,o,d) and d:toDamage().to:isAlive() end,function(sp,e,r,p,o,d)
    if invoke(r,o,sp.id,d) then take(r,o,d:toDamage().to,1,"hej",sp.id) end
end)
handler("bond_guansuo_upgrade",{sgs.GameStart,sgs.EventAcquireSkill},own,function(sp,e,r,p,o,d)
    for _,id in ipairs({"nuyan_wusheng","nuyan_dangxian","nuyan_xinzhan"}) do
        if o:hasSkill(id) then r:detachSkillFromPlayer(o,id);r:acquireSkill(o,id .. "_ji") end
    end
end)
local function make_trigger(sp,hidden)
    local h=handlers[sp.mode]
    local spec={
        name=hidden and "#" .. sp.id .. "_trigger" or sp.id,
        events=h and h.events or {},
        frequency=sp.compulsory and sgs.Skill_Compulsory or sgs.Skill_NotFrequent,
        can_trigger=function(self,event,room,p,data)
            if not h then return false end
            if event==sgs.DrawNCards and sp.mode~="shicai" and data:toDraw().reason~="draw_phase" then return false end
            local names,owners={},{}
            for _,o in sgs.qlist(room:findPlayersBySkillName(sp.id)) do
                if o:isAlive() and h.eligible(event,room,p,o,data,sp) then names[#names+1]=self:objectName();owners[#owners+1]=o:objectName() end
            end
            if #names>0 then return table.concat(names,"|"),table.concat(owners,"|") end
            return false
        end,
        on_effect=function(self,event,room,p,ctx)
            local delta=event==sgs.HpChanged and p and p:getMark("nuyan_hp_delta") or nil
            local result=h.effect(sp,event,room,p,ctx.owner or ctx.invoker or p,ctx.original_data) or false
            if delta then room:setPlayerMark(p,"nuyan_hp_delta",delta) end
            return result
        end
    }
    return sgs.CreateTriggerSkillV2(spec)
end
local function register(sp)
    specs[sp.id]=sp
    local skill
    if active_modes[sp.mode] then skill=make_active(sp) elseif conversions[sp.mode] then skill=make_conversion(sp) else skill=make_trigger(sp,false) end
    skills[sp.id]=skill
    if handlers[sp.mode] and (active_modes[sp.mode] or conversions[sp.mode]) then
        local related=make_trigger(sp,true);skills[related:objectName()]=related;extension:insertRelatedSkills(sp.id,related:objectName())
    end
    translations[sp.id]=sp.label;translations[":" .. sp.id]=sp.text
    return skill
end
-- Shared event records are installed on all players so a rage mark works on
-- targets with generals from other packs, too. No SmartAI code lives here.
local global_names={"#nuyan_runtime"}
local ensuring=false
local function ensure_runtime(room)
    if ensuring or room:getTag("nuyan_runtime_installed"):toBool() then return end;ensuring=true
    for _,p in sgs.qlist(room:getAllPlayers(true)) do
        for _,id in ipairs(global_names) do if p:getSkillInstanceIds(id):isEmpty() then room:attachSkillToPlayer(p,id) end end
    end
    room:setTag("nuyan_runtime_installed",sgs.QVariant(true));ensuring=false
end
local runtime=sgs.CreateTriggerSkillV2{
    name="#nuyan_runtime",global=true,priority=10,
    events={sgs.GameStart,sgs.EventPhaseStart,sgs.EventPhaseChanging,sgs.HpChanged,
        sgs.Damaged,sgs.Dying,sgs.CardsMoveOneTime,sgs.PreCardUsed,sgs.CardUsed,
        sgs.PreCardResponded,sgs.CardResponded,sgs.CardFinished,sgs.TargetSpecified,
        sgs.DamageCaused,sgs.CardEffected,sgs.EventAcquireSkill,sgs.JinkEffect,sgs.DrawNCards,sgs.MarkChanged,sgs.PostCardEffected},
    on_record=function(self,event,room,p,ctx)
        if event==sgs.EventAcquireSkill then room:removeTag("nuyan_runtime_installed") end
        ensure_runtime(room)
        -- V2 records once per holder instance. Use one stable coordinator.
        if ctx.owner and ctx.owner~=room:getAllPlayers(true):first() then return end
        local data=ctx.original_data
        if event==sgs.GameStart then
            for _,q in sgs.qlist(room:getAllPlayers(true)) do q:setTag("nuyan_last_hp",sgs.QVariant(q:getHp()));room:setPlayerMark(q,"nuyan_hp_initialized",1) end
        elseif event==sgs.HpChanged and p then
            local old=p:getTag("nuyan_last_hp"):toInt();local delta=p:getMark("nuyan_hp_initialized")>0 and p:getHp()-old or 0
            p:setTag("nuyan_last_hp",sgs.QVariant(p:getHp()));room:setPlayerMark(p,"nuyan_hp_initialized",1);room:setPlayerMark(p,"nuyan_hp_delta",delta)
            if delta<0 then for _,c in sgs.qlist(p:getHandcards()) do local cid=c:getEffectiveId();if p:getTag("nuyan_xiahui_" .. cid):toBool() then
                room:removePlayerCardLimitation(p,"use,response,discard",tostring(cid) .. "$0");p:removeTag("nuyan_xiahui_" .. cid)
            end end end
        elseif event==sgs.CardEffected then
            local x=data:toCardEffect();local previous=room:getTag("nuyan_zhanji_source"):toString()
            local depth=room:getTag("nuyan_zhanji_depth"):toInt()+1
            room:setTag("nuyan_zhanji_depth",sgs.QVariant(depth));room:setTag("nuyan_zhanji_previous_" .. depth,sgs.QVariant(previous))
            local sp=x.card and specs[x.card:getSkillName()]
            room:setTag("nuyan_zhanji_source",sgs.QVariant(sp and sp.mode=="zhanji" and x.from and x.from:objectName() or ""))
        elseif event==sgs.PostCardEffected then
            local depth=room:getTag("nuyan_zhanji_depth"):toInt()
            room:setTag("nuyan_zhanji_source",room:getTag("nuyan_zhanji_previous_" .. depth));room:removeTag("nuyan_zhanji_previous_" .. depth);room:setTag("nuyan_zhanji_depth",sgs.QVariant(math.max(0,depth-1)))
        elseif event==sgs.MarkChanged and p then
            local m=data:toMark()
            if m.name=="@nuyan_nuqi" then
                room:setPlayerMark(p,"nuyan_rage_changed-Clear",1)
                local from=room:findPlayerByObjectName(room:getTag("nuyan_zhanji_source"):toString())
                if m.gain<0 and from and from~=p then add_rage(room,from,-m.gain,p) end
            end
        elseif event==sgs.DrawNCards and p then
            local x=data:toDraw();if x.reason=="draw_phase" then x.num=x.num+p:getMark("nuyan_extra_draw-DrawClear");room:setPlayerMark(p,"nuyan_extra_draw-DrawClear",0);data:setValue(x) end
        elseif event==sgs.Damaged and p then
            local d=data:toDamage();local overflow=add_rage(room,p,d.damage,d.from);room:setPlayerMark(p,"nuyan_damage_overflow",overflow and 1 or 0)
            if d.card then d.card:setFlags("nuyan_caused_damage") end
            if hasmode(p,"quanji") then local n=p:getMark("@nuyan_quan")+1;if cap(p)>0 then n=math.min(n,cap(p)) end;room:setPlayerMark(p,"@nuyan_quan",n) end
            if hasmode(p,"canshi") and d.damage>1 then room:addPlayerMark(p,"@nuyan_chou") end
        elseif event==sgs.Dying and p then
            local dying=data:toDying();if dying.damage then local name=dying.damage.reason;local sp=specs[name];if sp and sp.mode=="duwu" then room:setPlayerMark(p,name .. "_dying",1) end end
        elseif event==sgs.EventPhaseStart and p then
            if phase(p,sgs.Player_Draw) and hasmode(p,"quanji") then local n=p:getMark("@nuyan_quan")+1;if cap(p)>0 then n=math.min(n,cap(p)) end;room:setPlayerMark(p,"@nuyan_quan",n) end
            if phase(p,sgs.Player_RoundStart) then room:setPlayerMark(p,"nuyan_xuehen_limit",math.max(1,p:getLostHp())) end
        elseif event==sgs.EventPhaseChanging and p then
            local change=data:toPhaseChange()
            if change.from==sgs.Player_Play then
                for id,sp in pairs(specs) do if sp.mode=="lihun" and p:hasSkill(id) then local q=room:findPlayerByObjectName(p:getTag(id .. "_target"):toString());if q and q:isAlive() then give(room,p,q,rage(q),id) end;p:removeTag(id .. "_target") end end
            end
            if change.to==sgs.Player_NotActive then
                room:setPlayerMark(p,"nuyan_dulie",0)
                for _,q in sgs.qlist(room:getAllPlayers(true)) do obtain(room,q,list(q:getPile("nuyan_pojun")),"nuyan_pojun") end
            end
        elseif event==sgs.CardsMoveOneTime then
            local m=data:toMoveOneTime();if m.from then local q=room:findPlayerByObjectName(m.from:objectName());if q then room:addPlayerMark(q,"nuyan_cards_lost-Clear",m.card_ids:length()) end end
        elseif event==sgs.PreCardUsed and p then
            local u=data:toCardUse();local c=u.card;if not c then return end;local sp=specs[c:getSkillName()]
            if sp and conversions[sp.mode] then local cfg=conversions[sp.mode]
                if cfg.cost then pay(room,p,cfg.cost) end
                if cfg.enhanced then c:setFlags("nuyan_enhanced") end
                if cfg.unlimited or sp.mode=="wusheng" and sp.jie and c:getSuit()==sgs.Card_Diamond then c:setFlags("nuyan_unlimited") end
                if sp.mode=="wusheng" and c:getSuit()==sgs.Card_Heart then c:setFlags("nuyan_free_enhance") end
                if sp.mode=="wusheng" and sp.extreme and c:subcardsLength()==1 and sgs.Sanguosha:getCard(c:getSubcards():first()):isKindOf("TrickCard") then c:setFlags("nuyan_unlimited") end
                room:addPlayerMark(p,sp.id .. "_used-PlayClear")
                if sp.mode=="luanji" then add_rage(room,p,1,p) end
                if sp.mode=="miaojian" then
                    if p:getMark("nuyan_miaojian_level")>=3 then room:removePlayerMark(p,"@nuyan_ling") end
                    c:setFlags("nuyan_unlimited");if p:getMark("nuyan_miaojian_level")>=2 then c:setFlags("nuyan_enhanced") end
                end
                if sp.mode=="qice" and sp.jie then local suits={};for _,cid in sgs.qlist(c:getSubcards()) do suits[sgs.Sanguosha:getCard(cid):getSuit()]=true end;local n=0;for _ in pairs(suits) do n=n+1 end;draw(p,n,sp.id) end
                if sp.mode=="wuhushangjiang" then if c:isRed() then add_rage(room,p,1,p) else local q=choose(room,p,sp.id,function(q)return q~=p and p:canDiscard(q,"he") end,true);if q then take(room,p,q,1,"he",sp.id,true) end end end
            end
            if c:hasFlag("nuyan_unlimited") and u.m_addHistory then u.m_addHistory=false;data:setValue(u) end
        elseif event==sgs.CardUsed and p then
            local u=data:toCardUse();local c=u.card
            if c and hasmode(p,"canshi") and (c:isKindOf("Slash") or c:isNDTrick()) then room:addPlayerMark(p,"@nuyan_chou") end
            if c and attack(c) then for i=1,p:getMark("nuyan_meibu-PlayClear") do random_discard(room,p,1,"h","nuyan_meibu") end end
            if c and c:isKindOf("Slash") and phase(p,sgs.Player_Play) then room:addPlayerMark(p,"nuyan_play_slashes-PlayClear") end
            if c and c:isKindOf("Slash") then for _,q in sgs.qlist(u.to) do
                room:setPlayerMark(p,"nuyan_jinks_" .. q:objectName(),0)
                q:setTag("nuyan_slash_source",sgs.QVariant(p:objectName()))
                q:setTag("nuyan_current_slash",sgs.QVariant(c:toString()))
            end end
        elseif event==sgs.PreCardResponded and p then
            local response=data:toCardResponse();local c=response.m_card;local sp=c and specs[c:getSkillName()]
            if sp and conversions[sp.mode] and conversions[sp.mode].enhanced then c:setFlags("nuyan_enhanced") end
        elseif event==sgs.CardResponded and p then
            local response=data:toCardResponse();local c=response.m_card
            if c and c:isKindOf("Jink") then
                local source=room:findPlayerByObjectName(p:getTag("nuyan_slash_source"):toString())
                if source then room:addPlayerMark(source,"nuyan_jinks_" .. p:objectName()) end
            end
        elseif event==sgs.TargetSpecified and p then
            local u=data:toCardUse();if u.card and u.card:isKindOf("Slash") then
                for _,q in sgs.qlist(u.to) do
                    local n=q:getMark("nuyan_xianzhen_" .. p:objectName() .. "-PlayClear")
                    if n>0 then room:addPlayerMark(q,"Armor_Nullified");q:setTag("nuyan_armor_" .. u.card:toString(),sgs.QVariant(q:getTag("nuyan_armor_" .. u.card:toString()):toInt()+1)) end
                end
            end
        elseif event==sgs.CardFinished then
            local u=data:toCardUse();local c=u.card;if not c then return end
            local sp=specs[c:getSkillName()]
            if sp and sp.mode=="qixi" and sp.jie then for _,q in sgs.qlist(u.to) do random_discard(room,q,1,"e",sp.id) end end
            if sp and sp.mode=="luanji" and sp.classic and not c:hasFlag("nuyan_caused_damage") then draw(u.from,2,sp.id) end
            for _,q in sgs.qlist(room:getAllPlayers(true)) do
                if q:getTag("nuyan_current_slash"):toString()==c:toString() then q:removeTag("nuyan_current_slash");q:removeTag("nuyan_slash_source") end
                local key="nuyan_armor_" .. c:toString();local n=q:getTag(key):toInt();if n>0 then room:removePlayerMark(q,"Armor_Nullified",n);q:removeTag(key) end
                local suit=q:getTag("nuyan_guhuo_" .. c:toString()):toString();if suit~="" then
                    room:removePlayerCardLimitation(q,"response",".|^" .. suit .. "$0");room:removePlayerCardLimitation(q,"use","Nullification|^" .. suit .. "$0");q:removeTag("nuyan_guhuo_" .. c:toString())
                end
            end
            for _,flag in ipairs({"nuyan_caused_damage","nuyan_enhanced","nuyan_unlimited","nuyan_free_enhance","nuyan_effect_plus"}) do c:setFlags("-" .. flag) end
        end
    end,
    can_trigger=function(self,event,room,p,data)
        if not p then return false end
        if event==sgs.JinkEffect then
            local c=data:toCard();local from=room:findPlayerByObjectName(p:getTag("nuyan_slash_source"):toString())
            if c and c:hasFlag("nuyan_enhanced") and from and (hasmode(from,"shenwei") or from:getMark("nuyan_no_enhanced_jink-PlayClear")>0) then return self:objectName(),p end
        elseif event==sgs.DamageCaused then
            local d=data:toDamage();if d.from and d.card and (d.card:hasFlag("nuyan_enhanced") or d.card:hasFlag("nuyan_effect_plus") or (d.card:isKindOf("Slash") or d.card:isKindOf("Duel")) and (d.from:getMark("nuyan_luoyi-Clear")>0 or d.from:getMark("nuyan_fenxin")>0 or hasmode(d.from,"shangshi"))) then return self:objectName(),p end
        elseif event==sgs.CardEffected then local x=data:toCardEffect();if x.card and x.card:hasFlag("nuyan_effect_plus") then return self:objectName(),p end
        end
        return false
    end,
    on_effect=function(self,event,room,p,ctx)
        local data=ctx.original_data
        if event==sgs.JinkEffect then return true end
        if event==sgs.DamageCaused then
            local d=data:toDamage();local from=d.from
            if d.card:hasFlag("nuyan_enhanced") and d.card:isKindOf("Slash") then d.damage=d.damage+1 end
            if d.card:hasFlag("nuyan_effect_plus") then d.damage=d.damage+1 end
            if d.card:isKindOf("Slash") or d.card:isKindOf("Duel") then
                local regular=from:getMark("nuyan_luoyi-Clear")-from:getMark("nuyan_luoyi_others-Clear")
                d.damage=d.damage+regular+(d.to~=from and from:getMark("nuyan_luoyi_others-Clear") or 0)
            end
            if d.card:isKindOf("Slash") and from:getPhase()~=sgs.Player_NotActive and from:getMark("nuyan_fenxin")>0 then
                d.damage=d.damage+from:getMark("nuyan_fenxin");room:setPlayerMark(from,"nuyan_fenxin",0)
            end
            local sp=specs["nuyan_jd_jie_shangshi"];if not from:hasSkill("nuyan_jd_jie_shangshi") then sp=nil end
            if sp and sp.classic and sp.jie and phase(from,sgs.Player_Play) and d.card:isKindOf("Slash") and from:getMark(sp.id .. "_lost-PlayClear")==0 then
                room:setPlayerMark(from,sp.id .. "_lost-PlayClear",1);room:loseHp(d.to,d.damage,true,from,sp.id);return true
            end
            data:setValue(d)
        else
            local x=data:toCardEffect();local c=x.card
            -- A numeric effect +1 is not a second complete resolution of a
            -- multi-point effect. Extraction tricks each move one card.
            if c:isKindOf("ExNihilo") then draw(x.to,1,"nuyan_bingzheng")
            elseif c:isKindOf("Snatch") or c:isKindOf("Dismantlement") then x.extra_effect=x.extra_effect+1;data:setValue(x) end
        end
        return false
    end
}
skills[runtime:objectName()]=runtime
local xizhan_limit=sgs.CreateCardLimitSkill{
    name="#nuyan_xizhan_limit",
    limit_list=function(self,p) return p:getPhase()~=sgs.Player_NotActive and "use" or "" end,
    limit_pattern=function(self,p,c) return c and c:isDamageCard() and c:toString() or "" end
}
local xiahui_ignore=sgs.CreateCardLimitSkill{
    name="#nuyan_xiahui_ignore",
    limit_list=function(self,p) return "ignore" end,
    limit_pattern=function(self,p,c) return c and c:isBlack() and c:toString() or "" end
}
skills[xizhan_limit:objectName()]=xizhan_limit;skills[xiahui_ignore:objectName()]=xiahui_ignore
for _,id in ipairs({"nuyan_xizhan","nuyan_jd_xizhan"}) do extension:insertRelatedSkills(id,"#nuyan_xizhan_limit") end
for _,id in ipairs({"nuyan_xiahui","nuyan_jd_xiahui"}) do extension:insertRelatedSkills(id,"#nuyan_xiahui_ignore") end
local bond_limit=sgs.CreateCardLimitSkill{
    name="#nuyan_bond_limit",
    limit_list=function(self,p) return "use" end,
    limit_pattern=function(self,p,c)
        local current=p:getRoom():getCurrent()
        if not current or current==p or not c then return "" end
        if c:isKindOf("Analeptic") and hasmode(current,"bond_no_analeptic") then return c:toString() end
        if c:isKindOf("Peach") and p:getHp()<=0 and hasmode(current,"bond_no_self_peach") then return c:toString() end
        return ""
    end
}
skills[bond_limit:objectName()]=bond_limit
global_names[#global_names+1]=bond_limit:objectName()
local function add_correct_skills()
    local gate={"mark:nuyan_bonus_hand-Clear","mark:nuyan_wenji1-Clear","mark:nuyan_wenji2-Clear","mark:nuyan_wenji3-Clear","mark:nuyan_slash-Clear","mark:nuyan_slash-PlayClear","mark:nuyan_qiangwu-Clear","mark:nuyan_kurou-Clear","mark:nuyan_distance-Clear","mark:nuyan_dulie","mark:nuyan_benxi-Clear","card_flag:nuyan_unlimited"}
    for id in pairs(specs) do gate[#gate+1]="skill:" .. id end
    local prohibition=sgs.CreateProhibitSkillV2{
        name="#nuyan_prohibit",holder_selector=sgs.CorrectSkill_System,gate=gate,
        is_prohibited=function(self,ctx)
            local q,c=ctx:getTo(),ctx:getCard()
            return q and c and c:isKindOf("Indulgence") and hasmode(q,"bond_indulgence")~=nil
        end
    }
    skills[prohibition:objectName()]=prohibition
    local mod=sgs.CreateTargetModSkillV2{
        name="#nuyan_target",pattern=".",holder_selector=sgs.CorrectSkill_System,gate=gate,
        correct_func=function(self,ctx)
            local p,c,q=ctx:getPrimary(),ctx:getCard(),ctx:getSecondary();if not p or not c then return false end
            local kind=ctx:getModType()
            if c:hasFlag("nuyan_unlimited") and (kind==sgs.TargetModSkill_DistanceLimit or kind==sgs.TargetModSkill_Residue) then return 1000 end
            if kind==sgs.TargetModSkill_Residue and p:getMark("nuyan_wenji" .. c:getTypeId() .. "-Clear")>0 then return 1000 end
            if not c:isKindOf("Slash") then return false end
            local paoxiao=hasmode(p,"paoxiao")
            if kind==sgs.TargetModSkill_Residue then
                if paoxiao or p:getMark("nuyan_qiangwu-Clear")>0 then return 1000 end
                if q and q:getMark("nuyan_xuehen_" .. p:objectName() .. "-Clear")>0 then return 1000 end
                if q then local n=q:getMark("nuyan_xianzhen_" .. p:objectName() .. "-PlayClear");if n==2 or n==1 and c:isBlack() then return 1000 end end
                return p:getMark("nuyan_slash-Clear")+p:getMark("nuyan_slash-PlayClear")+p:getMark("nuyan_kurou-Clear")+p:getMark("nuyan_dulie")
            elseif kind==sgs.TargetModSkill_DistanceLimit then
                if paoxiao and paoxiao.jie or p:getMark("nuyan_qiangwu-Clear")>0 or p:getMark("nuyan_distance-Clear")>0 then return 1000 end
                if q then local n=q:getMark("nuyan_xianzhen_" .. p:objectName() .. "-PlayClear");if n==2 or n==1 and c:isBlack() then return 1000 end end
            end
            return false
        end
    }
    local max=sgs.CreateMaxCardsSkillV2{
        name="#nuyan_maxcards",holder_selector=sgs.CorrectSkill_System,gate=gate,
        correct_func=function(self,ctx)
            local p=ctx:getPrimary();if not p then return false end;local n=p:getMark("nuyan_bonus_hand-Clear")
            for id,sp in pairs(specs) do if p:hasSkill(id) then
                if sp.mode=="jiushi" then n=n+2*rage(p)
                elseif sp.mode=="juejing" then n=n+(sp.classic and 5 or star(p))
                elseif sp.mode=="bond_hand" then n=n+1 end
            end end
            return n
        end
    }
    local dist=sgs.CreateDistanceSkillV2{
        name="#nuyan_distance",holder_selector=sgs.CorrectSkill_System,gate=gate,
        correct_func=function(self,ctx)
            local p,q=ctx:getPrimary(),ctx:getSecondary();if not p then return false end
            local n=-p:getMark("nuyan_benxi-Clear");if q and hasmode(q,"bond_benxi_distance") then n=n+rage(q) end;return n
        end
    }
    skills[mod:objectName()]=mod;skills[max:objectName()]=max;skills[dist:objectName()]=dist
end
handler("yingyuan",{sgs.CardsMoveOneTime},function(e,r,p,o,d)
    local m=d:toMoveOneTime();return m.from and m.from:objectName()==o:objectName() and o:getPhase()~=sgs.Player_NotActive and m.to_place==sgs.Player_DiscardPile and bit32.band(m.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_USE
end,function(sp,e,r,p,o,d)
    local m=d:toMoveOneTime();local byname={}
    for _,cid in sgs.qlist(m.card_ids) do local c=sgs.Sanguosha:getCard(cid)
        if not c:isKindOf("EquipCard") and r:getCardPlace(cid)==sgs.Player_DiscardPile then local name=c:objectName();byname[name]=byname[name] or {};byname[name][#byname[name]+1]=cid end
    end
    for name,ids in pairs(byname) do if o:getMark(sp.id .. "_name_" .. name .. "-Clear")==0 then
        local q=choose(r,o,sp.id,function(q)return q~=o end,true);if q then r:setPlayerMark(o,sp.id .. "_name_" .. name .. "-Clear",1);obtain(r,q,ids,sp.id) end
    end end
end)
register({id = "nuyan_wusheng_ji", mode = "wusheng", label = "武圣·极", text = "你可以将任意1张手牌当做【杀】使用或打出。若此牌为红桃，则转化的【杀】强化使用时不消耗怒气。你使用锦囊牌转化的【杀】不计入限制的使用次数。", extreme = true})
register({id = "nuyan_dangxian_ji", mode = "dangxian", label = "当先·极", text = "回合开始时，你获得1张牌并执行一个额外的出牌阶段，然后你可以失去1点体力并开始摸牌，直到摸到【杀】为止，你可以获得这些牌中和【杀】颜色相同的牌（包括【杀】）。", extreme = true})
register({id = "nuyan_xinzhan_ji", mode = "xinzhan_ji", label = "心战·极", text = "当你造成伤害后，你可以获得受伤角色任意区域里的1张牌。", extreme = true})
register({id = "nuyan_jichinanzheng", mode = "bond_guansuo_upgrade", label = "疾驰南征", text = "锁定技，你的'武圣'修改为'武圣·极'；你的'当先'修改为'当先·极'；你的'心战'修改为'心战·极'。", compulsory = true})
extension:insertRelatedSkills("nuyan_zhengnan","nuyan_jichinanzheng")
extension:insertRelatedSkills("nuyan_jd_zhengnan","nuyan_jichinanzheng")
extension:insertRelatedSkills("nuyan_jichinanzheng","nuyan_wusheng_ji")
extension:insertRelatedSkills("nuyan_jichinanzheng","nuyan_dangxian_ji")
extension:insertRelatedSkills("nuyan_jichinanzheng","nuyan_xinzhan_ji")
register({id = "nuyan_jd_kanpo_card", mode = "kanpo_native", label = "乱武·看破", text = "你可以将黑色【杀】当做【看破】使用。"})
-- 夏侯惇 常规
do
    local general = sgs.General(extension, "nuyan_xiahoudun", "wei", 4, true)
    translations["nuyan_xiahoudun"] = "夏侯惇"
    translations["#nuyan_xiahoudun"] = "怒焰·常规"
    if not skills["nuyan_ganglie"] then register({id = "nuyan_ganglie", mode = "ganglie", classic = false, jie = false, label = "刚烈", text = "锁定技，当你受到伤害后，伤害来源选择一项：1.随机弃置2张手牌；2.流失1点体力。", compulsory = true}) end
    general:addSkill(skills["nuyan_ganglie"])
    general:addSkill(runtime)
end

-- 夏侯惇 经典
do
    local general = sgs.General(extension, "nuyan_jd_xiahoudun", "wei", 4, true)
    translations["nuyan_jd_xiahoudun"] = "夏侯惇"
    translations["#nuyan_jd_xiahoudun"] = "怒焰·经典"
    if not skills["nuyan_jd_ganglie"] then register({id = "nuyan_jd_ganglie", mode = "ganglie", classic = true, jie = false, label = "刚烈", text = "锁定技，当你受到伤害后，伤害来源选择一项：1.随机弃置2张手牌；2.流失1点体力。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_ganglie"])
    general:addSkill(runtime)
end

-- 典韦 常规
do
    local general = sgs.General(extension, "nuyan_dianwei", "wei", 4, true)
    translations["nuyan_dianwei"] = "典韦"
    translations["#nuyan_dianwei"] = "怒焰·常规"
    if not skills["nuyan_qiangxi"] then register({id = "nuyan_qiangxi", mode = "qiangxi", classic = false, jie = false, label = "强袭", text = "出牌阶段限一次，你可以弃置1张装备牌，无视距离对一名其他角色造成2点伤害。", compulsory = false}) end
    general:addSkill(skills["nuyan_qiangxi"])
    general:addSkill(runtime)
end

-- 典韦 经典
do
    local general = sgs.General(extension, "nuyan_jd_dianwei", "wei", 4, true)
    translations["nuyan_jd_dianwei"] = "典韦"
    translations["#nuyan_jd_dianwei"] = "怒焰·经典"
    if not skills["nuyan_jd_qiangxi"] then register({id = "nuyan_jd_qiangxi", mode = "qiangxi", classic = true, jie = false, label = "强袭", text = "出牌阶段对每名角色限一次，你可以失去1点体力或弃置1张装备牌，无视距离对一名其他角色造成1点伤害。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_qiangxi"])
    general:addSkill(runtime)
end

-- 法正 常规
do
    local general = sgs.General(extension, "nuyan_fazheng", "shu", 4, true)
    translations["nuyan_fazheng"] = "法正"
    translations["#nuyan_fazheng"] = "怒焰·常规"
    if not skills["nuyan_xuanhuo"] then register({id = "nuyan_xuanhuo", mode = "xuanhuo", classic = false, jie = false, label = "眩惑", text = "出牌阶段限一次，你可以将1张方块手牌交给一名其他角色，然后获得其X张牌（X为该角色怒气值）。", compulsory = false}) end
    general:addSkill(skills["nuyan_xuanhuo"])
    general:addSkill(runtime)
end

-- 法正 经典
do
    local general = sgs.General(extension, "nuyan_jd_fazheng", "shu", 4, true)
    translations["nuyan_jd_fazheng"] = "法正"
    translations["#nuyan_jd_fazheng"] = "怒焰·经典"
    if not skills["nuyan_jd_xuanhuo"] then register({id = "nuyan_jd_xuanhuo", mode = "xuanhuo", classic = true, jie = false, label = "眩惑", text = "出牌阶段限一次，你可以将1张方块手牌交给一名其他角色，然后获得其X张牌（X为该角色怒气值）。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_xuanhuo"])
    general:addSkill(runtime)
end

-- 甘宁 常规
do
    local general = sgs.General(extension, "nuyan_ganning", "wu", 4, true)
    translations["nuyan_ganning"] = "甘宁"
    translations["#nuyan_ganning"] = "怒焰·常规"
    if not skills["nuyan_qixi"] then register({id = "nuyan_qixi", mode = "qixi", classic = false, jie = false, label = "奇袭", text = "出牌阶段，你可以将1张梅花手牌当做【过河拆桥】使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_qixi"])
    general:addSkill(runtime)
end

-- 甘宁 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_ganning", "wu", 4, true)
    translations["nuyan_jie_ganning"] = "甘宁"
    translations["#nuyan_jie_ganning"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_qixi"] then register({id = "nuyan_jie_qixi", mode = "qixi", classic = false, jie = true, label = "奇袭", text = "出牌阶段，你可以将1张梅花手牌当做【过河拆桥】使用，若目标装备区有装备牌，则随机弃置其1张装备牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jie_qixi"])
    general:addSkill(runtime)
end

-- 甘宁 经典
do
    local general = sgs.General(extension, "nuyan_jd_ganning", "wu", 4, true)
    translations["nuyan_jd_ganning"] = "甘宁"
    translations["#nuyan_jd_ganning"] = "怒焰·经典"
    if not skills["nuyan_jd_qixi"] then register({id = "nuyan_jd_qixi", mode = "qixi", classic = true, jie = false, label = "奇袭", text = "出牌阶段，你可以将1张黑色手牌当做【过河拆桥】使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_qixi"])
    general:addSkill(runtime)
end

-- 甘宁 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_ganning", "wu", 4, true)
    translations["nuyan_jd_jie_ganning"] = "甘宁"
    translations["#nuyan_jd_jie_ganning"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_qixi"] then register({id = "nuyan_jd_jie_qixi", mode = "qixi", classic = true, jie = true, label = "奇袭", text = "出牌阶段，你可以将1张黑色手牌当做【过河拆桥】使用，若目标装备区有装备牌，则随机弃置其1张装备牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_jie_qixi"])
    general:addSkill(runtime)
end

-- 黄盖 常规
do
    local general = sgs.General(extension, "nuyan_huanggai", "wu", 4, true)
    translations["nuyan_huanggai"] = "黄盖"
    translations["#nuyan_huanggai"] = "怒焰·常规"
    if not skills["nuyan_kurou"] then register({id = "nuyan_kurou", mode = "kurou", classic = false, jie = false, label = "苦肉", text = "出牌阶段限X次，你可以失去1点体力，然后摸2张牌（X为你的星级）。若如此做，此阶段你使用【杀】的次数上限+1。", compulsory = false}) end
    general:addSkill(skills["nuyan_kurou"])
    general:addSkill(runtime)
end

-- 黄盖 经典
do
    local general = sgs.General(extension, "nuyan_jd_huanggai", "wu", 4, true)
    translations["nuyan_jd_huanggai"] = "黄盖"
    translations["#nuyan_jd_huanggai"] = "怒焰·经典"
    if not skills["nuyan_jd_kurou"] then register({id = "nuyan_jd_kurou", mode = "kurou", classic = true, jie = false, label = "苦肉", text = "出牌阶段限两次，你可以失去1点体力，然后摸2张牌，若你此回合进行过'苦肉'，你可以额外使用1张【杀】。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_kurou"])
    general:addSkill(runtime)
end

-- 庞德 常规
do
    local general = sgs.General(extension, "nuyan_pangde", "qun", 4, true)
    translations["nuyan_pangde"] = "庞德"
    translations["#nuyan_pangde"] = "怒焰·常规"
    if not skills["nuyan_mengjin"] then register({id = "nuyan_mengjin", mode = "mengjin", classic = false, jie = false, label = "猛进", text = "你使用的【杀】被目标角色的【闪】抵消后，你可以弃置其X张牌（X为其使用【闪】的数量）。", compulsory = false}) end
    general:addSkill(skills["nuyan_mengjin"])
    general:addSkill(runtime)
end

-- 庞德 经典
do
    local general = sgs.General(extension, "nuyan_jd_pangde", "qun", 4, true)
    translations["nuyan_jd_pangde"] = "庞德"
    translations["#nuyan_jd_pangde"] = "怒焰·经典"
    if not skills["nuyan_jd_mengjin"] then register({id = "nuyan_jd_mengjin", mode = "mengjin", classic = true, jie = false, label = "猛进", text = "你使用的【杀】被目标角色的【闪】抵消后，你可以弃置其X张牌（X为其使用【闪】的数量）。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_mengjin"])
    general:addSkill(runtime)
end

-- 袁绍 常规
do
    local general = sgs.General(extension, "nuyan_yuanshao", "qun", 4, true)
    translations["nuyan_yuanshao"] = "袁绍"
    translations["#nuyan_yuanshao"] = "怒焰·常规"
    if not skills["nuyan_luanji"] then register({id = "nuyan_luanji", mode = "luanji", classic = false, jie = false, label = "乱击", text = "出牌阶段，你可以将3张手牌当做【万箭齐发】强化使用。若如此做，你获得1点怒气。", compulsory = false}) end
    general:addSkill(skills["nuyan_luanji"])
    general:addSkill(runtime)
end

-- 袁绍 经典
do
    local general = sgs.General(extension, "nuyan_jd_yuanshao", "qun", 4, true)
    translations["nuyan_jd_yuanshao"] = "袁绍"
    translations["#nuyan_jd_yuanshao"] = "怒焰·经典"
    if not skills["nuyan_jd_luanji"] then register({id = "nuyan_jd_luanji", mode = "luanji", classic = true, jie = false, label = "乱击", text = "出牌阶段，你可以将3张手牌当做强化【万箭齐发】使用，若如此做，你获得1点怒气。若没有角色受到此【万箭齐发】的伤害，你摸2张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_luanji"])
    general:addSkill(runtime)
end

-- 郭嘉 常规
do
    local general = sgs.General(extension, "nuyan_guojia", "wei", 4, true)
    translations["nuyan_guojia"] = "郭嘉"
    translations["#nuyan_guojia"] = "怒焰·常规"
    if not skills["nuyan_yiji"] then register({id = "nuyan_yiji", mode = "yiji", classic = false, jie = false, label = "遗计", text = "锁定技，当你受到伤害后，令一名角色摸2X张牌（X为伤害量）。", compulsory = true}) end
    general:addSkill(skills["nuyan_yiji"])
    general:addSkill(runtime)
end

-- 郭嘉 经典
do
    local general = sgs.General(extension, "nuyan_jd_guojia", "wei", 4, true)
    translations["nuyan_jd_guojia"] = "郭嘉"
    translations["#nuyan_jd_guojia"] = "怒焰·经典"
    if not skills["nuyan_jd_yiji"] then register({id = "nuyan_jd_yiji", mode = "yiji", classic = true, jie = false, label = "遗计", text = "锁定技，当你受到伤害后，令一名角色摸2X张牌（X为伤害量）。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_yiji"])
    general:addSkill(runtime)
end

-- 夏侯渊 常规
do
    local general = sgs.General(extension, "nuyan_xiahouyuan", "wei", 4, true)
    translations["nuyan_xiahouyuan"] = "夏侯渊"
    translations["#nuyan_xiahouyuan"] = "怒焰·常规"
    if not skills["nuyan_shensu"] then register({id = "nuyan_shensu", mode = "shensu", classic = false, jie = false, label = "神速", text = "出牌阶段，你可以消耗2点怒气，视为你使用1张无距离限制的强化【杀】，且此【杀】不计入出牌阶段使用次数。", compulsory = false}) end
    general:addSkill(skills["nuyan_shensu"])
    general:addSkill(runtime)
end

-- 夏侯渊 经典
do
    local general = sgs.General(extension, "nuyan_jd_xiahouyuan", "wei", 4, true)
    translations["nuyan_jd_xiahouyuan"] = "夏侯渊"
    translations["#nuyan_jd_xiahouyuan"] = "怒焰·经典"
    if not skills["nuyan_jd_shensu"] then register({id = "nuyan_jd_shensu", mode = "shensu", classic = true, jie = false, label = "神速", text = "出牌阶段，你可以消耗2点怒气，视为你使用1张无距离限制的强化【杀】，且此【杀】不计入出牌阶段使用次数。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_shensu"])
    general:addSkill(runtime)
end

-- 邓艾 常规
do
    local general = sgs.General(extension, "nuyan_dengai", "wei", 4, true)
    translations["nuyan_dengai"] = "邓艾"
    translations["#nuyan_dengai"] = "怒焰·常规"
    if not skills["nuyan_jixi"] then register({id = "nuyan_jixi", mode = "jixi", classic = false, jie = false, label = "急袭", text = "出牌阶段，你可以将手牌中的【闪】当做【顺手牵羊】使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jixi"])
    general:addSkill(runtime)
end

-- 邓艾 经典
do
    local general = sgs.General(extension, "nuyan_jd_dengai", "wei", 4, true)
    translations["nuyan_jd_dengai"] = "邓艾"
    translations["#nuyan_jd_dengai"] = "怒焰·经典"
    if not skills["nuyan_jd_jixi"] then register({id = "nuyan_jd_jixi", mode = "jixi", classic = true, jie = false, label = "急袭", text = "出牌阶段，你可以将手牌中的【闪】当做【顺手牵羊】使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_jixi"])
    general:addSkill(runtime)
end

-- 许褚 常规
do
    local general = sgs.General(extension, "nuyan_xuchu", "wei", 4, true)
    translations["nuyan_xuchu"] = "许褚"
    translations["#nuyan_xuchu"] = "怒焰·常规"
    if not skills["nuyan_luoyi"] then register({id = "nuyan_luoyi", mode = "luoyi", classic = false, jie = false, label = "裸衣", text = "出牌阶段限一次，你可以弃置1张装备牌，然后本回合你使用【杀】或【决斗】时伤害+1。", compulsory = false}) end
    general:addSkill(skills["nuyan_luoyi"])
    general:addSkill(runtime)
end

-- 许褚 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_xuchu", "wei", 4, true)
    translations["nuyan_jie_xuchu"] = "许褚"
    translations["#nuyan_jie_xuchu"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_luoyi"] then register({id = "nuyan_jie_luoyi", mode = "luoyi", classic = false, jie = true, label = "裸衣", text = "出牌阶段每种类别限一次，你可以弃置1张手牌，然后本回合你使用【杀】或【决斗】对其他角色造成的伤害+1。", compulsory = false}) end
    general:addSkill(skills["nuyan_jie_luoyi"])
    general:addSkill(runtime)
end

-- 许褚 经典
do
    local general = sgs.General(extension, "nuyan_jd_xuchu", "wei", 4, true)
    translations["nuyan_jd_xuchu"] = "许褚"
    translations["#nuyan_jd_xuchu"] = "怒焰·经典"
    if not skills["nuyan_jd_luoyi"] then register({id = "nuyan_jd_luoyi", mode = "luoyi", classic = true, jie = false, label = "裸衣", text = "出牌阶段限一次，你可以弃置1张装备牌，然后本回合你使用【杀】或【决斗】时伤害+1。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_luoyi"])
    general:addSkill(runtime)
end

-- 许褚 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_xuchu", "wei", 4, true)
    translations["nuyan_jd_jie_xuchu"] = "许褚"
    translations["#nuyan_jd_jie_xuchu"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_luoyi"] then register({id = "nuyan_jd_jie_luoyi", mode = "luoyi", classic = true, jie = true, label = "裸衣", text = "出牌阶段每种类别限一次，你可以弃置1张手牌，然后本回合你使用【杀】或【决斗】对其他角色造成的伤害+1。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_jie_luoyi"])
    general:addSkill(runtime)
end

-- 曹植 常规
do
    local general = sgs.General(extension, "nuyan_caozhi", "wei", 4, true)
    translations["nuyan_caozhi"] = "曹植"
    translations["#nuyan_caozhi"] = "怒焰·常规"
    if not skills["nuyan_jiushi"] then register({id = "nuyan_jiushi", mode = "jiushi", classic = false, jie = false, label = "酒诗", text = "你的黑色手牌可以当做【酒】使用；弃牌阶段，你的手牌上限+2X（X为你当前怒气值）。", compulsory = false}) end
    general:addSkill(skills["nuyan_jiushi"])
    general:addSkill(runtime)
end

-- 曹植 经典
do
    local general = sgs.General(extension, "nuyan_jd_caozhi", "wei", 4, true)
    translations["nuyan_jd_caozhi"] = "曹植"
    translations["#nuyan_jd_caozhi"] = "怒焰·经典"
    if not skills["nuyan_jd_jiushi"] then register({id = "nuyan_jd_jiushi", mode = "jiushi", classic = true, jie = false, label = "酒诗", text = "你的黑色手牌可以当做【酒】使用；弃牌阶段，你的手牌上限+2X（X为你当前怒气值）。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_jiushi"])
    general:addSkill(runtime)
end

-- 曹冲 常规
do
    local general = sgs.General(extension, "nuyan_caochong", "wei", 4, true)
    translations["nuyan_caochong"] = "曹冲"
    translations["#nuyan_caochong"] = "怒焰·常规"
    if not skills["nuyan_renxin"] then register({id = "nuyan_renxin", mode = "renxin", classic = false, jie = false, label = "仁心", text = "出牌阶段限一次，你可以令一名角色失去1点怒气，然后其回复X点体力（X为其当前怒气值）。", compulsory = false}) end
    general:addSkill(skills["nuyan_renxin"])
    general:addSkill(runtime)
end

-- 曹冲 经典
do
    local general = sgs.General(extension, "nuyan_jd_caochong", "wei", 4, true)
    translations["nuyan_jd_caochong"] = "曹冲"
    translations["#nuyan_jd_caochong"] = "怒焰·经典"
    if not skills["nuyan_jd_chengxiang"] then register({id = "nuyan_jd_chengxiang", mode = "chengxiang", classic = true, jie = false, label = "称象", text = "锁定技，当你受到伤害后，你亮出牌堆顶的4张牌，然后获得其中的任意张点数之和小于等于13的牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_chengxiang"])
    general:addSkill(runtime)
end

-- 黄忠 常规
do
    local general = sgs.General(extension, "nuyan_huangzhong", "shu", 4, true)
    translations["nuyan_huangzhong"] = "黄忠"
    translations["#nuyan_huangzhong"] = "怒焰·常规"
    if not skills["nuyan_liegong"] then register({id = "nuyan_liegong", mode = "liegong", classic = false, jie = false, label = "烈弓", text = "锁定技，当你使用【杀】指定一个目标后，若该角色体力值不小于你的体力值，则其不能使用【闪】响应此【杀】。", compulsory = true}) end
    general:addSkill(skills["nuyan_liegong"])
    general:addSkill(runtime)
end

-- 黄忠 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_huangzhong", "shu", 4, true)
    translations["nuyan_jie_huangzhong"] = "黄忠"
    translations["#nuyan_jie_huangzhong"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_liegong"] then register({id = "nuyan_jie_liegong", mode = "liegong", classic = false, jie = true, label = "烈弓", text = "锁定技，当你使用【杀】指定目标后，若目标体力值不小于你的体力值或目标手牌数不小于你的手牌数，则此【杀】不可被响应。", compulsory = true}) end
    general:addSkill(skills["nuyan_jie_liegong"])
    general:addSkill(runtime)
end

-- 黄忠 经典
do
    local general = sgs.General(extension, "nuyan_jd_huangzhong", "shu", 4, true)
    translations["nuyan_jd_huangzhong"] = "黄忠"
    translations["#nuyan_jd_huangzhong"] = "怒焰·经典"
    if not skills["nuyan_jd_liegong"] then register({id = "nuyan_jd_liegong", mode = "liegong", classic = true, jie = false, label = "烈弓", text = "锁定技，当你使用【杀】指定一个目标后，若该角色体力值不小于你的体力值，则其不能使用【闪】响应此【杀】。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_liegong"])
    general:addSkill(runtime)
end

-- 黄忠 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_huangzhong", "shu", 4, true)
    translations["nuyan_jd_jie_huangzhong"] = "黄忠"
    translations["#nuyan_jd_jie_huangzhong"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_liegong"] then register({id = "nuyan_jd_jie_liegong", mode = "liegong", classic = true, jie = true, label = "烈弓", text = "锁定技，当你使用【杀】指定目标后，若目标体力值不小于你的体力值或目标手牌数不小于你的手牌数，则此【杀】不可被响应。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_jie_liegong"])
    general:addSkill(runtime)
end

-- 张飞 常规
do
    local general = sgs.General(extension, "nuyan_zhangfei", "shu", 4, true)
    translations["nuyan_zhangfei"] = "张飞"
    translations["#nuyan_zhangfei"] = "怒焰·常规"
    if not skills["nuyan_paoxiao"] then register({id = "nuyan_paoxiao", mode = "paoxiao", classic = false, jie = false, label = "咆哮", text = "锁定技，出牌阶段，你使用【杀】无次数限制。", compulsory = true}) end
    general:addSkill(skills["nuyan_paoxiao"])
    general:addSkill(runtime)
end

-- 张飞 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_zhangfei", "shu", 4, true)
    translations["nuyan_jie_zhangfei"] = "张飞"
    translations["#nuyan_jie_zhangfei"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_paoxiao"] then register({id = "nuyan_jie_paoxiao", mode = "paoxiao", classic = false, jie = true, label = "咆哮", text = "锁定技，出牌阶段，你使用【杀】无次数与距离限制。", compulsory = true}) end
    general:addSkill(skills["nuyan_jie_paoxiao"])
    general:addSkill(runtime)
end

-- 张飞 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhangfei", "shu", 4, true)
    translations["nuyan_jd_zhangfei"] = "张飞"
    translations["#nuyan_jd_zhangfei"] = "怒焰·经典"
    if not skills["nuyan_jd_paoxiao"] then register({id = "nuyan_jd_paoxiao", mode = "paoxiao", classic = true, jie = false, label = "咆哮", text = "锁定技，出牌阶段，你使用【杀】无次数限制。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_paoxiao"])
    general:addSkill(runtime)
end

-- 张飞 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_zhangfei", "shu", 4, true)
    translations["nuyan_jd_jie_zhangfei"] = "张飞"
    translations["#nuyan_jd_jie_zhangfei"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_paoxiao"] then register({id = "nuyan_jd_jie_paoxiao", mode = "paoxiao", classic = true, jie = true, label = "咆哮", text = "锁定技，出牌阶段，你使用【杀】无次数与距离限制。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_jie_paoxiao"])
    general:addSkill(runtime)
end

-- 魏延 常规
do
    local general = sgs.General(extension, "nuyan_weiyan", "shu", 4, true)
    translations["nuyan_weiyan"] = "魏延"
    translations["#nuyan_weiyan"] = "怒焰·常规"
    if not skills["nuyan_kuanggu"] then register({id = "nuyan_kuanggu", mode = "kuanggu", classic = false, jie = false, label = "狂骨", text = "锁定技，出牌阶段，当你造成伤害后，立即回复1点体力。", compulsory = true}) end
    general:addSkill(skills["nuyan_kuanggu"])
    general:addSkill(runtime)
end

-- 魏延 经典
do
    local general = sgs.General(extension, "nuyan_jd_weiyan", "shu", 4, true)
    translations["nuyan_jd_weiyan"] = "魏延"
    translations["#nuyan_jd_weiyan"] = "怒焰·经典"
    if not skills["nuyan_jd_kuanggu"] then register({id = "nuyan_jd_kuanggu", mode = "kuanggu", classic = true, jie = false, label = "狂骨", text = "出牌阶段，当你对一名其他角色造成伤害后，你可以选择一项：1.回复1点体力；2.摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_kuanggu"])
    general:addSkill(runtime)
end

-- 刘禅 常规
do
    local general = sgs.General(extension, "nuyan_liushan", "shu", 4, true)
    translations["nuyan_liushan"] = "刘禅"
    translations["#nuyan_liushan"] = "怒焰·常规"
    if not skills["nuyan_xiangle"] then register({id = "nuyan_xiangle", mode = "xiangle", classic = false, jie = false, label = "享乐", text = "锁定技，其他角色的【杀】或单体非延时锦囊指定你为目标后，若未对你造成伤害，其受到1点无来源伤害。", compulsory = true}) end
    general:addSkill(skills["nuyan_xiangle"])
    general:addSkill(runtime)
end

-- 刘禅 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_liushan", "shu", 4, true)
    translations["nuyan_jie_liushan"] = "刘禅"
    translations["#nuyan_jie_liushan"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_xiangle"] then register({id = "nuyan_jie_xiangle", mode = "xiangle", classic = false, jie = true, label = "享乐", text = "锁定技，若其他角色的【杀】或单体非延时锦囊对你造成的伤害小于2点，其受到1点无来源伤害。", compulsory = true}) end
    general:addSkill(skills["nuyan_jie_xiangle"])
    general:addSkill(runtime)
end

-- 刘禅 经典
do
    local general = sgs.General(extension, "nuyan_jd_liushan", "shu", 4, true)
    translations["nuyan_jd_liushan"] = "刘禅"
    translations["#nuyan_jd_liushan"] = "怒焰·经典"
    if not skills["nuyan_jd_xiangle"] then register({id = "nuyan_jd_xiangle", mode = "xiangle", classic = true, jie = false, label = "享乐", text = "锁定技，其他角色的【杀】或单体非延时锦囊指定你为目标后，若未对你造成伤害，其受到1点无来源伤害。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_xiangle"])
    general:addSkill(runtime)
end

-- 刘禅 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_liushan", "shu", 4, true)
    translations["nuyan_jd_jie_liushan"] = "刘禅"
    translations["#nuyan_jd_jie_liushan"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_xiangle"] then register({id = "nuyan_jd_jie_xiangle", mode = "xiangle", classic = true, jie = true, label = "享乐", text = "锁定技，若其他角色的【杀】或单体非延时锦囊对你造成的伤害小于2点，其受到1点无来源伤害。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_jie_xiangle"])
    general:addSkill(runtime)
end

-- 马谡 常规
do
    local general = sgs.General(extension, "nuyan_masu", "shu", 4, true)
    translations["nuyan_masu"] = "马谡"
    translations["#nuyan_masu"] = "怒焰·常规"
    if not skills["nuyan_zhiman"] then register({id = "nuyan_zhiman", mode = "zhiman", classic = false, jie = false, label = "制蛮", text = "出牌阶段限一次，你可以弃置1张牌，选择一名角色并对其造成1点体力流失。", compulsory = false}) end
    general:addSkill(skills["nuyan_zhiman"])
    general:addSkill(runtime)
end

-- 马谡 经典
do
    local general = sgs.General(extension, "nuyan_jd_masu", "shu", 4, true)
    translations["nuyan_jd_masu"] = "马谡"
    translations["#nuyan_jd_masu"] = "怒焰·经典"
    if not skills["nuyan_jd_zhiman"] then register({id = "nuyan_jd_zhiman", mode = "zhiman", classic = true, jie = false, label = "制蛮", text = "出牌阶段限一次，你可以弃置1张牌，选择一名角色并对其造成1点体力流失。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_zhiman"])
    general:addSkill(runtime)
end

-- 小乔 常规
do
    local general = sgs.General(extension, "nuyan_xiaoqiao", "wu", 4, true)
    translations["nuyan_xiaoqiao"] = "小乔"
    translations["#nuyan_xiaoqiao"] = "怒焰·常规"
    if not skills["nuyan_tianxiang"] then register({id = "nuyan_tianxiang", mode = "tianxiang", classic = false, jie = false, label = "天香", text = "出牌阶段，你可以将1张红色手牌当做【釜底抽薪】强化使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_tianxiang"])
    general:addSkill(runtime)
end

-- 小乔 经典
do
    local general = sgs.General(extension, "nuyan_jd_xiaoqiao", "wu", 4, true)
    translations["nuyan_jd_xiaoqiao"] = "小乔"
    translations["#nuyan_jd_xiaoqiao"] = "怒焰·经典"
    if not skills["nuyan_jd_tianxiang"] then register({id = "nuyan_jd_tianxiang", mode = "tianxiang", classic = true, jie = false, label = "天香", text = "出牌阶段，你可以将1张红色手牌当做【釜底抽薪】强化使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_tianxiang"])
    general:addSkill(runtime)
end

-- 吕蒙 常规
do
    local general = sgs.General(extension, "nuyan_lvmeng", "wu", 4, true)
    translations["nuyan_lvmeng"] = "吕蒙"
    translations["#nuyan_lvmeng"] = "怒焰·常规"
    if not skills["nuyan_gongxin"] then register({id = "nuyan_gongxin", mode = "gongxin", classic = false, jie = false, label = "攻心", text = "出牌阶段，你可以消耗1点怒气，视为你使用1张普通【顺手牵羊】。", compulsory = false}) end
    general:addSkill(skills["nuyan_gongxin"])
    general:addSkill(runtime)
end

-- 吕蒙 经典
do
    local general = sgs.General(extension, "nuyan_jd_lvmeng", "wu", 4, true)
    translations["nuyan_jd_lvmeng"] = "吕蒙"
    translations["#nuyan_jd_lvmeng"] = "怒焰·经典"
    if not skills["nuyan_jd_gongxin"] then register({id = "nuyan_jd_gongxin", mode = "gongxin", classic = true, jie = false, label = "攻心", text = "出牌阶段，你可以消耗1点怒气，视为你使用1张普通【顺手牵羊】。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_gongxin"])
    general:addSkill(runtime)
end

-- 陆逊 常规
do
    local general = sgs.General(extension, "nuyan_luxun", "wu", 4, true)
    translations["nuyan_luxun"] = "陆逊"
    translations["#nuyan_luxun"] = "怒焰·常规"
    if not skills["nuyan_lianying"] then register({id = "nuyan_lianying", mode = "lianying", classic = false, jie = false, label = "连营", text = "锁定技，当你失去最后的手牌时，你摸2张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_lianying"])
    general:addSkill(runtime)
end

-- 陆逊 经典
do
    local general = sgs.General(extension, "nuyan_jd_luxun", "wu", 4, true)
    translations["nuyan_jd_luxun"] = "陆逊"
    translations["#nuyan_jd_luxun"] = "怒焰·经典"
    if not skills["nuyan_jd_lianying"] then register({id = "nuyan_jd_lianying", mode = "lianying", classic = true, jie = false, label = "连营", text = "锁定技，当你失去最后的手牌时，你摸2张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_lianying"])
    general:addSkill(runtime)
end

-- 凌统 常规
do
    local general = sgs.General(extension, "nuyan_lingtong", "wu", 4, true)
    translations["nuyan_lingtong"] = "凌统"
    translations["#nuyan_lingtong"] = "怒焰·常规"
    if not skills["nuyan_xuanfeng"] then register({id = "nuyan_xuanfeng", mode = "xuanfeng", classic = false, jie = false, label = "旋风", text = "出牌阶段限一次，当你失去装备区中的1张牌时，你可以选择一名其他角色，弃置目标任意区域2张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_xuanfeng"])
    general:addSkill(runtime)
end

-- 凌统 经典
do
    local general = sgs.General(extension, "nuyan_jd_lingtong", "wu", 4, true)
    translations["nuyan_jd_lingtong"] = "凌统"
    translations["#nuyan_jd_lingtong"] = "怒焰·经典"
    if not skills["nuyan_jd_xuanfeng"] then register({id = "nuyan_jd_xuanfeng", mode = "xuanfeng", classic = true, jie = false, label = "旋风", text = "出牌阶段限一次，当你失去装备区中的1张牌时，你可以选择一名其他角色，弃置目标任意区域2张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_xuanfeng"])
    general:addSkill(runtime)
end

-- 董卓 常规
do
    local general = sgs.General(extension, "nuyan_dongzhuo", "qun", 4, true)
    translations["nuyan_dongzhuo"] = "董卓"
    translations["#nuyan_dongzhuo"] = "怒焰·常规"
    if not skills["nuyan_baoli"] then register({id = "nuyan_baoli", mode = "baoli", classic = false, jie = false, label = "暴戾", text = "出牌阶段，若你的怒气值未满，你可以失去1点体力，然后获得2点怒气。", compulsory = false}) end
    general:addSkill(skills["nuyan_baoli"])
    general:addSkill(runtime)
end

-- 董卓 经典
do
    local general = sgs.General(extension, "nuyan_jd_dongzhuo", "qun", 4, true)
    translations["nuyan_jd_dongzhuo"] = "董卓"
    translations["#nuyan_jd_dongzhuo"] = "怒焰·经典"
    if not skills["nuyan_jd_baoli"] then register({id = "nuyan_jd_baoli", mode = "baoli", classic = true, jie = false, label = "暴戾", text = "出牌阶段，若你的怒气值未满，你可以失去1点体力，然后获得2点怒气。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_baoli"])
    general:addSkill(runtime)
end

-- 华雄 常规
do
    local general = sgs.General(extension, "nuyan_huaxiong", "qun", 4, true)
    translations["nuyan_huaxiong"] = "华雄"
    translations["#nuyan_huaxiong"] = "怒焰·常规"
    if not skills["nuyan_shiyong"] then register({id = "nuyan_shiyong", mode = "shiyong", classic = false, jie = false, label = "恃勇", text = "锁定技，当你成为【杀】或单体非延时锦囊的目标后，若此牌为黑色，你摸1张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_shiyong"])
    general:addSkill(runtime)
end

-- 华雄 经典
do
    local general = sgs.General(extension, "nuyan_jd_huaxiong", "qun", 4, true)
    translations["nuyan_jd_huaxiong"] = "华雄"
    translations["#nuyan_jd_huaxiong"] = "怒焰·经典"
    if not skills["nuyan_jd_shiyong"] then register({id = "nuyan_jd_shiyong", mode = "shiyong", classic = true, jie = false, label = "恃勇", text = "锁定技，当你成为【杀】或单体非延时锦囊的目标后，若此牌为黑色，你摸1张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_shiyong"])
    general:addSkill(runtime)
end

-- 颜良 常规
do
    local general = sgs.General(extension, "nuyan_yanliang", "qun", 4, true)
    translations["nuyan_yanliang"] = "颜良"
    translations["#nuyan_yanliang"] = "怒焰·常规"
    if not skills["nuyan_langxing"] then register({id = "nuyan_langxing", mode = "langxing", classic = false, jie = false, label = "狼行", text = "出牌阶段，你可以将1张基本牌当做【决斗】使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_langxing"])
    general:addSkill(runtime)
end

-- 颜良 经典
do
    local general = sgs.General(extension, "nuyan_jd_yanliang", "qun", 4, true)
    translations["nuyan_jd_yanliang"] = "颜良"
    translations["#nuyan_jd_yanliang"] = "怒焰·经典"
    if not skills["nuyan_jd_langxing"] then register({id = "nuyan_jd_langxing", mode = "langxing", classic = true, jie = false, label = "狼行", text = "出牌阶段，你可以将1张基本牌当做【决斗】使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_langxing"])
    general:addSkill(runtime)
end

-- 文丑 常规
do
    local general = sgs.General(extension, "nuyan_wenchou", "qun", 4, true)
    translations["nuyan_wenchou"] = "文丑"
    translations["#nuyan_wenchou"] = "怒焰·常规"
    if not skills["nuyan_hubu"] then register({id = "nuyan_hubu", mode = "hubu", classic = false, jie = false, label = "虎步", text = "出牌阶段，你可以失去1点怒气并指定一名角色，视为你对其使用1张普通【决斗】。", compulsory = false}) end
    general:addSkill(skills["nuyan_hubu"])
    general:addSkill(runtime)
end

-- 文丑 经典
do
    local general = sgs.General(extension, "nuyan_jd_wenchou", "qun", 4, true)
    translations["nuyan_jd_wenchou"] = "文丑"
    translations["#nuyan_jd_wenchou"] = "怒焰·经典"
    if not skills["nuyan_jd_hubu"] then register({id = "nuyan_jd_hubu", mode = "hubu", classic = true, jie = false, label = "虎步", text = "出牌阶段，你可以失去1点怒气并指定一名角色，视为你对其使用1张普通【决斗】。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_hubu"])
    general:addSkill(runtime)
end

-- 司马懿 常规
do
    local general = sgs.General(extension, "nuyan_simayi", "wei", 4, true)
    translations["nuyan_simayi"] = "司马懿"
    translations["#nuyan_simayi"] = "怒焰·常规"
    if not skills["nuyan_fankui"] then register({id = "nuyan_fankui", mode = "fankui", classic = false, jie = false, label = "反馈", text = "当你受到1次伤害后，你可以获得伤害来源的X张牌（X为伤害量）。", compulsory = false}) end
    general:addSkill(skills["nuyan_fankui"])
    general:addSkill(runtime)
end

-- 司马懿 经典
do
    local general = sgs.General(extension, "nuyan_jd_simayi", "wei", 4, true)
    translations["nuyan_jd_simayi"] = "司马懿"
    translations["#nuyan_jd_simayi"] = "怒焰·经典"
    if not skills["nuyan_jd_fankui"] then register({id = "nuyan_jd_fankui", mode = "fankui", classic = true, jie = false, label = "反馈", text = "当你受到1次伤害后，你可以获得伤害来源的X张牌（X为伤害量）。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_fankui"])
    general:addSkill(runtime)
end

-- 曹仁 常规
do
    local general = sgs.General(extension, "nuyan_caoren", "wei", 4, true)
    translations["nuyan_caoren"] = "曹仁"
    translations["#nuyan_caoren"] = "怒焰·常规"
    if not skills["nuyan_jushou"] then register({id = "nuyan_jushou", mode = "jushou", classic = false, jie = false, label = "据守", text = "回合结束时，若你有怒气，你可以选择消耗所有怒气，然后你摸X张牌（X为消耗的怒气的2倍，且最多为4）。", compulsory = false}) end
    general:addSkill(skills["nuyan_jushou"])
    general:addSkill(runtime)
end

-- 曹仁 经典
do
    local general = sgs.General(extension, "nuyan_jd_caoren", "wei", 4, true)
    translations["nuyan_jd_caoren"] = "曹仁"
    translations["#nuyan_jd_caoren"] = "怒焰·经典"
    if not skills["nuyan_jd_jushou"] then register({id = "nuyan_jd_jushou", mode = "jushou", classic = true, jie = false, label = "据守", text = "回合结束时，若你有怒气，你可以选择消耗所有怒气，然后你摸X张牌（X为消耗的怒气的2倍，且最多为4）。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_jushou"])
    general:addSkill(runtime)
end

-- 曹操 常规
do
    local general = sgs.General(extension, "nuyan_caocao", "wei", 4, true)
    translations["nuyan_caocao"] = "曹操"
    translations["#nuyan_caocao"] = "怒焰·常规"
    if not skills["nuyan_jianxiong"] then register({id = "nuyan_jianxiong", mode = "jianxiong", classic = false, jie = false, label = "奸雄", text = "锁定技，当你受到伤害后，你获得造成此伤害的牌并获得双倍怒气。", compulsory = true}) end
    general:addSkill(skills["nuyan_jianxiong"])
    general:addSkill(runtime)
end

-- 曹操 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_caocao", "wei", 4, true)
    translations["nuyan_jie_caocao"] = "曹操"
    translations["#nuyan_jie_caocao"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_jianxiong"] then register({id = "nuyan_jie_jianxiong", mode = "jianxiong", classic = false, jie = true, label = "奸雄", text = "锁定技，当你受到伤害后，你获得造成此伤害的牌并获得双倍怒气，若此时你的怒气溢出，则随机弃置伤害来源的1张牌，若其没有牌则改为对其造成1点伤害。", compulsory = true}) end
    general:addSkill(skills["nuyan_jie_jianxiong"])
    general:addSkill(runtime)
end

-- 曹操 经典
do
    local general = sgs.General(extension, "nuyan_jd_caocao", "wei", 4, true)
    translations["nuyan_jd_caocao"] = "曹操"
    translations["#nuyan_jd_caocao"] = "怒焰·经典"
    if not skills["nuyan_jd_jianxiong"] then register({id = "nuyan_jd_jianxiong", mode = "jianxiong", classic = true, jie = false, label = "奸雄", text = "锁定技，当你受到伤害后，你获得造成此伤害的牌并获得双倍怒气。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_jianxiong"])
    general:addSkill(runtime)
end

-- 曹操 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_caocao", "wei", 4, true)
    translations["nuyan_jd_jie_caocao"] = "曹操"
    translations["#nuyan_jd_jie_caocao"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_jianxiong"] then register({id = "nuyan_jd_jie_jianxiong", mode = "jianxiong", classic = true, jie = true, label = "奸雄", text = "锁定技，当你受到伤害后，你获得造成此伤害的牌并获得双倍怒气，若此时你的怒气溢出，则随机弃置伤害来源的1张牌，若其没有牌则改为对其造成1点伤害。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_jie_jianxiong"])
    general:addSkill(runtime)
end

-- 张辽 常规
do
    local general = sgs.General(extension, "nuyan_zhangliao", "wei", 4, true)
    translations["nuyan_zhangliao"] = "张辽"
    translations["#nuyan_zhangliao"] = "怒焰·常规"
    if not skills["nuyan_tuxi"] then register({id = "nuyan_tuxi", mode = "tuxi", classic = false, jie = false, label = "突袭", text = "摸牌阶段，你可以少摸任意张牌改为获得等量名其他角色各1张手牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_tuxi"])
    general:addSkill(runtime)
end

-- 张辽 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhangliao", "wei", 4, true)
    translations["nuyan_jd_zhangliao"] = "张辽"
    translations["#nuyan_jd_zhangliao"] = "怒焰·经典"
    if not skills["nuyan_jd_tuxi"] then register({id = "nuyan_jd_tuxi", mode = "tuxi", classic = true, jie = false, label = "突袭", text = "摸牌阶段，你可以少摸任意张牌改为获得等量名其他角色各1张手牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_tuxi"])
    general:addSkill(runtime)
end

-- 张春华 常规
do
    local general = sgs.General(extension, "nuyan_zhangchunhua", "wei", 4, true)
    translations["nuyan_zhangchunhua"] = "张春华"
    translations["#nuyan_zhangchunhua"] = "怒焰·常规"
    if not skills["nuyan_shangshi"] then register({id = "nuyan_shangshi", mode = "shangshi", classic = false, jie = false, label = "伤逝", text = "锁定技，当你的手牌数小于X时，你将手牌摸至X张（X为你的星级）。", compulsory = true}) end
    general:addSkill(skills["nuyan_shangshi"])
    general:addSkill(runtime)
end

-- 张春华 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_zhangchunhua", "wei", 4, true)
    translations["nuyan_jie_zhangchunhua"] = "张春华"
    translations["#nuyan_jie_zhangchunhua"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_shangshi"] then register({id = "nuyan_jie_shangshi", mode = "shangshi", classic = false, jie = true, label = "伤逝", text = "锁定技，当你的手牌数小于X+1时，你将手牌摸至X+1张（X为你的星级）。", compulsory = true}) end
    general:addSkill(skills["nuyan_jie_shangshi"])
    general:addSkill(runtime)
end

-- 张春华 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhangchunhua", "wei", 4, true)
    translations["nuyan_jd_zhangchunhua"] = "张春华"
    translations["#nuyan_jd_zhangchunhua"] = "怒焰·经典"
    if not skills["nuyan_jd_shangshi"] then register({id = "nuyan_jd_shangshi", mode = "shangshi", classic = true, jie = false, label = "伤逝", text = "当你的手牌数小于3时，你将手牌摸至3张。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_shangshi"])
    general:addSkill(runtime)
end

-- 张春华 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_zhangchunhua", "wei", 4, true)
    translations["nuyan_jd_jie_zhangchunhua"] = "张春华"
    translations["#nuyan_jd_jie_zhangchunhua"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_shangshi"] then register({id = "nuyan_jd_jie_shangshi", mode = "shangshi", classic = true, jie = true, label = "伤逝", text = "锁定技，当你的手牌数小于4时，你将手牌摸至4张。出牌阶段，你首次使用【杀】造成的伤害视为体力流失。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_jie_shangshi"])
    general:addSkill(runtime)
end

-- 曹彰 常规
do
    local general = sgs.General(extension, "nuyan_caozhang", "wei", 4, true)
    translations["nuyan_caozhang"] = "曹彰"
    translations["#nuyan_caozhang"] = "怒焰·常规"
    if not skills["nuyan_jiangchi"] then register({id = "nuyan_jiangchi", mode = "jiangchi", classic = false, jie = false, label = "将驰", text = "锁定技，摸牌阶段，你选择一项：1.多摸2张牌；2.此回合你使用【杀】无距离限制，且出杀次数+2。", compulsory = true}) end
    general:addSkill(skills["nuyan_jiangchi"])
    general:addSkill(runtime)
end

-- 曹彰 经典
do
    local general = sgs.General(extension, "nuyan_jd_caozhang", "wei", 4, true)
    translations["nuyan_jd_caozhang"] = "曹彰"
    translations["#nuyan_jd_caozhang"] = "怒焰·经典"
    if not skills["nuyan_jd_jiangchi"] then register({id = "nuyan_jd_jiangchi", mode = "jiangchi", classic = true, jie = false, label = "将驰", text = "锁定技，摸牌阶段，你选择一项：1.多摸2张牌；2.此回合你使用【杀】无距离限制，且出杀次数+2。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_jiangchi"])
    general:addSkill(runtime)
end

-- 王异 常规
do
    local general = sgs.General(extension, "nuyan_wangyi", "wei", 4, true)
    translations["nuyan_wangyi"] = "王异"
    translations["#nuyan_wangyi"] = "怒焰·常规"
    if not skills["nuyan_miji"] then register({id = "nuyan_miji", mode = "miji", classic = false, jie = false, label = "秘计", text = "当你成为其他角色的【杀】或单体非延时锦囊牌的目标后，你可以失去1点体力使此牌失效，然后你弃置其2张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_miji"])
    general:addSkill(runtime)
end

-- 王异 经典
do
    local general = sgs.General(extension, "nuyan_jd_wangyi", "wei", 4, true)
    translations["nuyan_jd_wangyi"] = "王异"
    translations["#nuyan_jd_wangyi"] = "怒焰·经典"
    if not skills["nuyan_jd_miji"] then register({id = "nuyan_jd_miji", mode = "miji", classic = true, jie = false, label = "秘计", text = "当你成为其他角色的【杀】或单体非延时锦囊牌的目标后，你可以失去1点体力使此牌失效，然后你弃置其2张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_miji"])
    general:addSkill(runtime)
end

-- 荀彧 常规
do
    local general = sgs.General(extension, "nuyan_xunyu", "wei", 4, true)
    translations["nuyan_xunyu"] = "荀彧"
    translations["#nuyan_xunyu"] = "怒焰·常规"
    if not skills["nuyan_quhu"] then register({id = "nuyan_quhu", mode = "quhu", classic = false, jie = false, label = "驱虎", text = "出牌阶段限X+1次（X为你的星级），你可以令一名其他角色与你进行拼点，若你赢则对方受到1点伤害，若你没赢则对方不受伤害。", compulsory = false}) end
    general:addSkill(skills["nuyan_quhu"])
    general:addSkill(runtime)
end

-- 荀彧 经典
do
    local general = sgs.General(extension, "nuyan_jd_xunyu", "wei", 4, true)
    translations["nuyan_jd_xunyu"] = "荀彧"
    translations["#nuyan_jd_xunyu"] = "怒焰·经典"
    if not skills["nuyan_jd_quhu"] then register({id = "nuyan_jd_quhu", mode = "quhu", classic = true, jie = false, label = "驱虎", text = "出牌阶段限两次，你可以令一名其他角色与你进行拼点，若你赢则对方受到1点伤害，若你没赢则对方不受伤害。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_quhu"])
    general:addSkill(runtime)
end

-- 徐晃 常规
do
    local general = sgs.General(extension, "nuyan_xuhuang", "wei", 4, true)
    translations["nuyan_xuhuang"] = "徐晃"
    translations["#nuyan_xuhuang"] = "怒焰·常规"
    if not skills["nuyan_duanliang"] then register({id = "nuyan_duanliang", mode = "duanliang", classic = false, jie = false, label = "断粮", text = "出牌阶段，你可以消耗1点怒气，将1张黑色基本牌或黑色装备牌当做【乐不思蜀】强化使用。若一名角色跳过摸牌阶段，则你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_duanliang"])
    general:addSkill(runtime)
end

-- 徐晃 经典
do
    local general = sgs.General(extension, "nuyan_jd_xuhuang", "wei", 4, true)
    translations["nuyan_jd_xuhuang"] = "徐晃"
    translations["#nuyan_jd_xuhuang"] = "怒焰·经典"
    if not skills["nuyan_jd_duanliang"] then register({id = "nuyan_jd_duanliang", mode = "duanliang", classic = true, jie = false, label = "断粮", text = "出牌阶段，你可以消耗1点怒气，将1张黑色基本牌或黑色装备牌当做【乐不思蜀】强化使用。若一名角色跳过摸牌阶段，则你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_duanliang"])
    general:addSkill(runtime)
end

-- 荀攸 常规
do
    local general = sgs.General(extension, "nuyan_xunyou", "wei", 4, true)
    translations["nuyan_xunyou"] = "荀攸"
    translations["#nuyan_xunyou"] = "怒焰·常规"
    if not skills["nuyan_qice"] then register({id = "nuyan_qice", mode = "qice", classic = false, jie = false, label = "奇策", text = "出牌阶段限一次，你可以将任意张手牌当1张非延时锦囊牌使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_qice"])
    general:addSkill(runtime)
end

-- 荀攸 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_xunyou", "wei", 4, true)
    translations["nuyan_jie_xunyou"] = "荀攸"
    translations["#nuyan_jie_xunyou"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_qice"] then register({id = "nuyan_jie_qice", mode = "qice", classic = false, jie = true, label = "奇策", text = "出牌阶段限一次，你可以将任意张手牌当1张非延时锦囊牌使用，然后摸等同于这些手牌花色数量的牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jie_qice"])
    general:addSkill(runtime)
end

-- 荀攸 经典
do
    local general = sgs.General(extension, "nuyan_jd_xunyou", "wei", 4, true)
    translations["nuyan_jd_xunyou"] = "荀攸"
    translations["#nuyan_jd_xunyou"] = "怒焰·经典"
    if not skills["nuyan_jd_qice"] then register({id = "nuyan_jd_qice", mode = "qice", classic = true, jie = false, label = "奇策", text = "出牌阶段限一次，你可以将任意张手牌当1张非延时锦囊牌使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_qice"])
    general:addSkill(runtime)
end

-- 荀攸 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_xunyou", "wei", 4, true)
    translations["nuyan_jd_jie_xunyou"] = "荀攸"
    translations["#nuyan_jd_jie_xunyou"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_qice"] then register({id = "nuyan_jd_jie_qice", mode = "qice", classic = true, jie = true, label = "奇策", text = "出牌阶段限一次，你可以将任意张手牌当1张非延时锦囊牌使用，然后摸等同于这些手牌花色数量的牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_jie_qice"])
    general:addSkill(runtime)
end

-- 于禁 常规
do
    local general = sgs.General(extension, "nuyan_yujin", "wei", 4, true)
    translations["nuyan_yujin"] = "于禁"
    translations["#nuyan_yujin"] = "怒焰·常规"
    if not skills["nuyan_zhenjun"] then register({id = "nuyan_zhenjun", mode = "zhenjun", classic = false, jie = false, label = "镇军", text = "出牌阶段限一次，你可以将1张牌交给一名其他角色，令其使用1张不为黑色的【杀】。若其执行，此【杀】结算后你摸1张牌；若其不执行，你可以对其或其攻击范围内的一名角色造成1点伤害。", compulsory = false}) end
    general:addSkill(skills["nuyan_zhenjun"])
    general:addSkill(runtime)
end

-- 于禁 经典
do
    local general = sgs.General(extension, "nuyan_jd_yujin", "wei", 4, true)
    translations["nuyan_jd_yujin"] = "于禁"
    translations["#nuyan_jd_yujin"] = "怒焰·经典"
    if not skills["nuyan_jd_zhenjun"] then register({id = "nuyan_jd_zhenjun", mode = "zhenjun", classic = true, jie = false, label = "镇军", text = "出牌阶段限一次，你可以将1张牌交给一名其他角色，令其使用1张不为黑色的【杀】。若其执行，此【杀】结算后你摸1张牌；若其不执行，你可以对其或其攻击范围内的一名角色造成1点伤害。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_zhenjun"])
    general:addSkill(runtime)
end

-- 张郃 常规
do
    local general = sgs.General(extension, "nuyan_zhanghe", "wei", 4, true)
    translations["nuyan_zhanghe"] = "张郃"
    translations["#nuyan_zhanghe"] = "怒焰·常规"
    if not skills["nuyan_zhilue"] then register({id = "nuyan_zhilue", mode = "zhilue", classic = false, jie = false, label = "知略", text = "出牌阶段，你可以消耗1点怒气并选择一项：1.你移动场上1张牌；2.你摸2张牌并视为使用1张无距离限制且不计入次数限制的【杀】。", compulsory = false}) end
    general:addSkill(skills["nuyan_zhilue"])
    general:addSkill(runtime)
end

-- 张郃 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhanghe", "wei", 4, true)
    translations["nuyan_jd_zhanghe"] = "张郃"
    translations["#nuyan_jd_zhanghe"] = "怒焰·经典"
    if not skills["nuyan_jd_zhilue"] then register({id = "nuyan_jd_zhilue", mode = "zhilue", classic = true, jie = false, label = "知略", text = "出牌阶段，你可以消耗1点怒气并选择一项：1.你移动场上1张牌；2.你摸2张牌并视为使用1张无距离限制且不计入次数限制的【杀】。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_zhilue"])
    general:addSkill(runtime)
end

-- 钟会 常规
do
    local general = sgs.General(extension, "nuyan_zhonghui", "wei", 4, true)
    translations["nuyan_zhonghui"] = "钟会"
    translations["#nuyan_zhonghui"] = "怒焰·常规"
    if not skills["nuyan_quanji"] then register({id = "nuyan_quanji", mode = "quanji", classic = false, jie = false, label = "权计", text = "出牌阶段限一次，你可以消耗所有的'权'，摸2倍'权'数量的牌（'权'来源：当你受到伤害或进入摸牌阶段时，你获得1枚'权'），'权'的上限为你的怒气上限。", compulsory = false}) end
    general:addSkill(skills["nuyan_quanji"])
    general:addSkill(runtime)
end

-- 钟会 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhonghui", "wei", 4, true)
    translations["nuyan_jd_zhonghui"] = "钟会"
    translations["#nuyan_jd_zhonghui"] = "怒焰·经典"
    if not skills["nuyan_jd_quanji"] then register({id = "nuyan_jd_quanji", mode = "quanji", classic = true, jie = false, label = "权计", text = "出牌阶段限一次，你可以消耗所有的'权'，摸2倍'权'数量的牌（'权'来源：当你受到伤害或进入摸牌阶段时，你获得1枚'权'），'权'的上限为你的怒气上限。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_quanji"])
    general:addSkill(runtime)
end

-- 曹昂 常规
do
    local general = sgs.General(extension, "nuyan_caoang", "wei", 4, true)
    translations["nuyan_caoang"] = "曹昂"
    translations["#nuyan_caoang"] = "怒焰·常规"
    if not skills["nuyan_kangkai"] then register({id = "nuyan_kangkai", mode = "kangkai", classic = false, jie = false, label = "慷忾", text = "当一名角色成为【杀】的目标后，若你与其距离不大于1，则你可以摸1张牌，然后交给其1张牌并展示之。若此牌为装备牌，该角色可以使用此牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_kangkai"])
    general:addSkill(runtime)
end

-- 曹昂 经典
do
    local general = sgs.General(extension, "nuyan_jd_caoang", "wei", 4, true)
    translations["nuyan_jd_caoang"] = "曹昂"
    translations["#nuyan_jd_caoang"] = "怒焰·经典"
    if not skills["nuyan_jd_kangkai"] then register({id = "nuyan_jd_kangkai", mode = "kangkai", classic = true, jie = false, label = "慷忾", text = "当一名角色成为【杀】的目标后，若你与其距离不大于1，则你可以摸1张牌，然后交给其1张牌并展示之。若此牌为装备牌，该角色可以使用此牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_kangkai"])
    general:addSkill(runtime)
end

-- 王基 常规
do
    local general = sgs.General(extension, "nuyan_wangji", "wei", 4, true)
    translations["nuyan_wangji"] = "王基"
    translations["#nuyan_wangji"] = "怒焰·常规"
    if not skills["nuyan_qizhi"] then register({id = "nuyan_qizhi", mode = "qizhi", classic = false, jie = false, label = "奇制", text = "当你于回合内使用基本牌或锦囊牌指定目标后，你可以弃置非目标角色的1张牌。若如此做，其增加1点怒气。若弃置的目标是你自己，你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_qizhi"])
    general:addSkill(runtime)
end

-- 王基 经典
do
    local general = sgs.General(extension, "nuyan_jd_wangji", "wei", 4, true)
    translations["nuyan_jd_wangji"] = "王基"
    translations["#nuyan_jd_wangji"] = "怒焰·经典"
    if not skills["nuyan_jd_qizhi"] then register({id = "nuyan_jd_qizhi", mode = "qizhi", classic = true, jie = false, label = "奇制", text = "当你于回合内使用基本牌或锦囊牌指定目标后，你可以弃置非目标角色的1张牌。若如此做，其增加1点怒气。若弃置的目标是你自己，你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_qizhi"])
    general:addSkill(runtime)
end

-- 刘备 常规
do
    local general = sgs.General(extension, "nuyan_liubei", "shu", 4, true)
    translations["nuyan_liubei"] = "刘备"
    translations["#nuyan_liubei"] = "怒焰·常规"
    if not skills["nuyan_renwang"] then register({id = "nuyan_renwang", mode = "renwang", classic = false, jie = false, label = "仁望", text = "锁定技，当你成为其他角色使用【杀】或单体非延时锦囊的目标后，该角色失去1点怒气，且弃置1张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_renwang"])
    general:addSkill(runtime)
end

-- 刘备 经典
do
    local general = sgs.General(extension, "nuyan_jd_liubei", "shu", 4, true)
    translations["nuyan_jd_liubei"] = "刘备"
    translations["#nuyan_jd_liubei"] = "怒焰·经典"
    if not skills["nuyan_jd_renwang"] then register({id = "nuyan_jd_renwang", mode = "renwang", classic = true, jie = false, label = "仁望", text = "锁定技，当你成为其他角色使用【杀】或单体非延时锦囊的目标后，该角色失去1点怒气，且弃置1张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_renwang"])
    general:addSkill(runtime)
end

-- 关羽 常规
do
    local general = sgs.General(extension, "nuyan_guanyu", "shu", 4, true)
    translations["nuyan_guanyu"] = "关羽"
    translations["#nuyan_guanyu"] = "怒焰·常规"
    if not skills["nuyan_wusheng"] then register({id = "nuyan_wusheng", mode = "wusheng", classic = false, jie = false, label = "武圣", text = "你可以将任意1张手牌当做【杀】使用或打出。若此牌为红桃，则转化的【杀】强化使用时不消耗怒气。", compulsory = false}) end
    general:addSkill(skills["nuyan_wusheng"])
    general:addSkill(runtime)
end

-- 关羽 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_guanyu", "shu", 4, true)
    translations["nuyan_jie_guanyu"] = "关羽"
    translations["#nuyan_jie_guanyu"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_wusheng"] then register({id = "nuyan_jie_wusheng", mode = "wusheng", classic = false, jie = true, label = "武圣", text = "你可以将任意1张手牌当做【杀】使用或打出。若此牌为方块，其不计入使用次数限制；若此牌为红桃，转化的【杀】强化使用时不消耗怒气。", compulsory = false}) end
    general:addSkill(skills["nuyan_jie_wusheng"])
    general:addSkill(runtime)
end

-- 关羽 经典
do
    local general = sgs.General(extension, "nuyan_jd_guanyu", "shu", 4, true)
    translations["nuyan_jd_guanyu"] = "关羽"
    translations["#nuyan_jd_guanyu"] = "怒焰·经典"
    if not skills["nuyan_jd_wusheng"] then register({id = "nuyan_jd_wusheng", mode = "wusheng", classic = true, jie = false, label = "武圣", text = "你可以将任意1张手牌当做【杀】使用或打出。若此牌为红桃，则转化的【杀】强化使用时不消耗怒气。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_wusheng"])
    general:addSkill(runtime)
end

-- 关羽 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_guanyu", "shu", 4, true)
    translations["nuyan_jd_jie_guanyu"] = "关羽"
    translations["#nuyan_jd_jie_guanyu"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_wusheng"] then register({id = "nuyan_jd_jie_wusheng", mode = "wusheng", classic = true, jie = true, label = "武圣", text = "你可以将任意1张手牌当做【杀】使用或打出。若此牌为方块，其不计入使用次数限制；若此牌为红桃，转化的【杀】强化使用时不消耗怒气。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_jie_wusheng"])
    general:addSkill(runtime)
end

-- 黄月英 常规
do
    local general = sgs.General(extension, "nuyan_huangyueying", "shu", 4, true)
    translations["nuyan_huangyueying"] = "黄月英"
    translations["#nuyan_huangyueying"] = "怒焰·常规"
    if not skills["nuyan_jizhi"] then register({id = "nuyan_jizhi", mode = "jizhi", classic = false, jie = false, label = "集智", text = "锁定技，当你使用1张非延时锦囊牌时，你摸1张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_jizhi"])
    general:addSkill(runtime)
end

-- 黄月英 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_huangyueying", "shu", 4, true)
    translations["nuyan_jie_huangyueying"] = "黄月英"
    translations["#nuyan_jie_huangyueying"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_jizhi"] then register({id = "nuyan_jie_jizhi", mode = "jizhi", classic = false, jie = true, label = "集智", text = "锁定技，当你使用1张锦囊牌时，你摸1张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_jie_jizhi"])
    general:addSkill(runtime)
end

-- 黄月英 经典
do
    local general = sgs.General(extension, "nuyan_jd_huangyueying", "shu", 4, true)
    translations["nuyan_jd_huangyueying"] = "黄月英"
    translations["#nuyan_jd_huangyueying"] = "怒焰·经典"
    if not skills["nuyan_jd_jizhi"] then register({id = "nuyan_jd_jizhi", mode = "jizhi", classic = true, jie = false, label = "集智", text = "锁定技，当你使用1张非延时锦囊牌时，你摸1张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_jizhi"])
    general:addSkill(runtime)
end

-- 黄月英 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_huangyueying", "shu", 4, true)
    translations["nuyan_jd_jie_huangyueying"] = "黄月英"
    translations["#nuyan_jd_jie_huangyueying"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_jizhi"] then register({id = "nuyan_jd_jie_jizhi", mode = "jizhi", classic = true, jie = true, label = "集智", text = "锁定技，当你使用1张锦囊牌时，你摸1张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_jie_jizhi"])
    general:addSkill(runtime)
end

-- 马超 常规
do
    local general = sgs.General(extension, "nuyan_machao", "shu", 4, true)
    translations["nuyan_machao"] = "马超"
    translations["#nuyan_machao"] = "怒焰·常规"
    if not skills["nuyan_tieqi"] then register({id = "nuyan_tieqi", mode = "tieqi", classic = false, jie = false, label = "铁骑", text = "锁定技，当你使用【杀】指定一个目标后，你的【杀】无视其防具和防御系符石，然后你进行判定，除非该角色弃置1张与判定结果花色相同的牌，否则其不能使用【闪】响应此【杀】。", compulsory = true}) end
    general:addSkill(skills["nuyan_tieqi"])
    general:addSkill(runtime)
end

-- 马超 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_machao", "shu", 4, true)
    translations["nuyan_jie_machao"] = "马超"
    translations["#nuyan_jie_machao"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_tieqi"] then register({id = "nuyan_jie_tieqi", mode = "tieqi", classic = false, jie = true, label = "铁骑", text = "锁定技，当你使用【杀】指定一个目标后，你的【杀】无视其防具和防御系符石，然后你进行判定，若结果为黑色，该角色不能使用【闪】，若结果为红色，除非该角色弃置1张与判定结果花色相同的牌，否则其不能使用【闪】响应此【杀】。", compulsory = true}) end
    general:addSkill(skills["nuyan_jie_tieqi"])
    general:addSkill(runtime)
end

-- 马超 经典
do
    local general = sgs.General(extension, "nuyan_jd_machao", "shu", 4, true)
    translations["nuyan_jd_machao"] = "马超"
    translations["#nuyan_jd_machao"] = "怒焰·经典"
    if not skills["nuyan_jd_tieqi"] then register({id = "nuyan_jd_tieqi", mode = "tieqi", classic = true, jie = false, label = "铁骑", text = "锁定技，当你使用【杀】指定一个目标后，你的【杀】无视其防具，然后你进行判定，除非该角色弃置1张与判定结果花色相同的牌，否则其不能使用【闪】响应此【杀】。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_tieqi"])
    general:addSkill(runtime)
end

-- 马超 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_machao", "shu", 4, true)
    translations["nuyan_jd_jie_machao"] = "马超"
    translations["#nuyan_jd_jie_machao"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_tieqi"] then register({id = "nuyan_jd_jie_tieqi", mode = "tieqi", classic = true, jie = true, label = "铁骑", text = "锁定技，当你使用【杀】指定一个目标后，你的【杀】无视其防具，然后你进行判定，若结果为黑色，该角色不能使用【闪】，若结果为红色，除非该角色弃置1张与判定结果花色相同的牌，否则其不能使用【闪】响应此【杀】。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_jie_tieqi"])
    general:addSkill(runtime)
end

-- 姜维 常规
do
    local general = sgs.General(extension, "nuyan_jiangwei", "shu", 4, true)
    translations["nuyan_jiangwei"] = "姜维"
    translations["#nuyan_jiangwei"] = "怒焰·常规"
    if not skills["nuyan_jizhen"] then register({id = "nuyan_jizhen", mode = "jizhen", classic = false, jie = false, label = "激阵", text = "回合开始时或出牌阶段共限一次，你可以弃置一名角色任意区域内的1张牌：若是装备牌，则你的怒气+1；若是基本牌，则你可以获得之；若是锦囊牌，则你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jizhen"])
    general:addSkill(runtime)
end

-- 姜维 经典
do
    local general = sgs.General(extension, "nuyan_jd_jiangwei", "shu", 4, true)
    translations["nuyan_jd_jiangwei"] = "姜维"
    translations["#nuyan_jd_jiangwei"] = "怒焰·经典"
    if not skills["nuyan_jd_jizhen"] then register({id = "nuyan_jd_jizhen", mode = "jizhen", classic = true, jie = false, label = "激阵", text = "回合开始时或出牌阶段共限一次，你可以弃置一名角色任意区域内的1张牌：若是装备牌，则你的怒气+1；若是基本牌，则你可以获得之；若是锦囊牌，则你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_jizhen"])
    general:addSkill(runtime)
end

-- 张星彩 常规
do
    local general = sgs.General(extension, "nuyan_zhangxingcai", "shu", 4, true)
    translations["nuyan_zhangxingcai"] = "张星彩"
    translations["#nuyan_zhangxingcai"] = "怒焰·常规"
    if not skills["nuyan_qiangwu"] then register({id = "nuyan_qiangwu", mode = "qiangwu", classic = false, jie = false, label = "枪舞", text = "出牌阶段限一次，你可以弃置一名角色手牌区或装备区内的1张牌，若如此做，本回合你使用【杀】无距离与次数限制。", compulsory = false}) end
    general:addSkill(skills["nuyan_qiangwu"])
    general:addSkill(runtime)
end

-- 张星彩 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhangxingcai", "shu", 4, true)
    translations["nuyan_jd_zhangxingcai"] = "张星彩"
    translations["#nuyan_jd_zhangxingcai"] = "怒焰·经典"
    if not skills["nuyan_jd_qiangwu"] then register({id = "nuyan_jd_qiangwu", mode = "qiangwu", classic = true, jie = false, label = "枪舞", text = "出牌阶段限一次，你可以弃置一名角色手牌区或装备区内的1张牌，若如此做，本回合你使用【杀】无距离与次数限制。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_qiangwu"])
    general:addSkill(runtime)
end

-- 马云禄 常规
do
    local general = sgs.General(extension, "nuyan_mayunlu", "shu", 4, true)
    translations["nuyan_mayunlu"] = "马云禄"
    translations["#nuyan_mayunlu"] = "怒焰·常规"
    if not skills["nuyan_fengpo"] then register({id = "nuyan_fengpo", mode = "fengpo", classic = false, jie = false, label = "凤魄", text = "出牌阶段，你可以将1张红桃手牌当做强化【怒发冲冠】使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_fengpo"])
    general:addSkill(runtime)
end

-- 马云禄 经典
do
    local general = sgs.General(extension, "nuyan_jd_mayunlu", "shu", 4, true)
    translations["nuyan_jd_mayunlu"] = "马云禄"
    translations["#nuyan_jd_mayunlu"] = "怒焰·经典"
    if not skills["nuyan_jd_fengpo"] then register({id = "nuyan_jd_fengpo", mode = "fengpo", classic = true, jie = false, label = "凤魄", text = "出牌阶段，你可以将1张红桃手牌当做强化【怒发冲冠】使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_fengpo"])
    general:addSkill(runtime)
end

-- 庞统 常规
do
    local general = sgs.General(extension, "nuyan_pangtong", "shu", 4, true)
    translations["nuyan_pangtong"] = "庞统"
    translations["#nuyan_pangtong"] = "怒焰·常规"
    if not skills["nuyan_zhanji"] then register({id = "nuyan_zhanji", mode = "zhanji", classic = false, jie = false, label = "展骥", text = "出牌阶段，你可以将1张黑色手牌当做普通【釜底抽薪】使用，若如此做，你立即获得其他角色因【釜底抽薪】所失去的全部怒气。", compulsory = false}) end
    general:addSkill(skills["nuyan_zhanji"])
    general:addSkill(runtime)
end

-- 庞统 经典
do
    local general = sgs.General(extension, "nuyan_jd_pangtong", "shu", 4, true)
    translations["nuyan_jd_pangtong"] = "庞统"
    translations["#nuyan_jd_pangtong"] = "怒焰·经典"
    if not skills["nuyan_jd_zhanji"] then register({id = "nuyan_jd_zhanji", mode = "zhanji", classic = true, jie = false, label = "展骥", text = "出牌阶段，你可以将1张黑色手牌当做普通【釜底抽薪】使用，若如此做，你立即获得其他角色因【釜底抽薪】所失去的全部怒气。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_zhanji"])
    general:addSkill(runtime)
end

-- 徐庶 常规
do
    local general = sgs.General(extension, "nuyan_xushu", "shu", 4, true)
    translations["nuyan_xushu"] = "徐庶"
    translations["#nuyan_xushu"] = "怒焰·常规"
    if not skills["nuyan_zhuhai"] then register({id = "nuyan_zhuhai", mode = "zhuhai", classic = false, jie = false, label = "诛害", text = "其他角色于其回合内怒气增加时，你可以弃置1张牌，令其流失1点体力。", compulsory = false}) end
    general:addSkill(skills["nuyan_zhuhai"])
    general:addSkill(runtime)
end

-- 徐庶 经典
do
    local general = sgs.General(extension, "nuyan_jd_xushu", "shu", 4, true)
    translations["nuyan_jd_xushu"] = "徐庶"
    translations["#nuyan_jd_xushu"] = "怒焰·经典"
    if not skills["nuyan_jd_zhuhai"] then register({id = "nuyan_jd_zhuhai", mode = "zhuhai", classic = true, jie = false, label = "诛害", text = "其他角色于其回合内怒气增加时，你可以弃置1张牌，令其流失1点体力。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_zhuhai"])
    general:addSkill(runtime)
end

-- 廖化 常规
do
    local general = sgs.General(extension, "nuyan_liaohua", "shu", 4, true)
    translations["nuyan_liaohua"] = "廖化"
    translations["#nuyan_liaohua"] = "怒焰·常规"
    if not skills["nuyan_dangxian"] then register({id = "nuyan_dangxian", mode = "dangxian", classic = false, jie = false, label = "当先", text = "锁定技，回合开始时，你获得1张牌并执行一个额外的出牌阶段。", compulsory = true}) end
    general:addSkill(skills["nuyan_dangxian"])
    general:addSkill(runtime)
end

-- 廖化 经典
do
    local general = sgs.General(extension, "nuyan_jd_liaohua", "shu", 4, true)
    translations["nuyan_jd_liaohua"] = "廖化"
    translations["#nuyan_jd_liaohua"] = "怒焰·经典"
    if not skills["nuyan_jd_dangxian"] then register({id = "nuyan_jd_dangxian", mode = "dangxian", classic = true, jie = false, label = "当先", text = "锁定技，回合开始时，你获得1张牌并执行一个额外的出牌阶段。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_dangxian"])
    general:addSkill(runtime)
end

-- 关银屏 常规
do
    local general = sgs.General(extension, "nuyan_guanyinping", "shu", 4, true)
    translations["nuyan_guanyinping"] = "关银屏"
    translations["#nuyan_guanyinping"] = "怒焰·常规"
    if not skills["nuyan_xuehen"] then register({id = "nuyan_xuehen", mode = "xuehen", classic = false, jie = false, label = "雪恨", text = "出牌阶段限X次（X为你的星级），你可以弃置1张红桃牌，对一名其他角色造成1点伤害，然后本回合你对其使用【杀】无次数限制。", compulsory = false}) end
    general:addSkill(skills["nuyan_xuehen"])
    general:addSkill(runtime)
end

-- 关银屏 经典
do
    local general = sgs.General(extension, "nuyan_jd_guanyinping", "shu", 4, true)
    translations["nuyan_jd_guanyinping"] = "关银屏"
    translations["#nuyan_jd_guanyinping"] = "怒焰·经典"
    if not skills["nuyan_jd_xuehen"] then register({id = "nuyan_jd_xuehen", mode = "xuehen", classic = true, jie = false, label = "雪恨", text = "出牌阶段限X次（X为回合开始前你已损失的体力值且至少为1），你可以弃置1张红桃牌，对一名其他角色造成1点伤害，然后本回合你对其使用【杀】无次数限制。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_xuehen"])
    general:addSkill(runtime)
end

-- 马良 常规
do
    local general = sgs.General(extension, "nuyan_maliang", "shu", 4, true)
    translations["nuyan_maliang"] = "马良"
    translations["#nuyan_maliang"] = "怒焰·常规"
    if not skills["nuyan_yingyuan"] then register({id = "nuyan_yingyuan", mode = "yingyuan", classic = false, jie = false, label = "应援", text = "当你于回合内使用的牌置入弃牌堆时，你可以将之交给一名其他角色（装备牌无法触发'应援'，相同牌名的牌每回合限一次）。", compulsory = false}) end
    general:addSkill(skills["nuyan_yingyuan"])
    general:addSkill(runtime)
end

-- 马良 经典
do
    local general = sgs.General(extension, "nuyan_jd_maliang", "shu", 4, true)
    translations["nuyan_jd_maliang"] = "马良"
    translations["#nuyan_jd_maliang"] = "怒焰·经典"
    if not skills["nuyan_jd_yingyuan"] then register({id = "nuyan_jd_yingyuan", mode = "yingyuan", classic = true, jie = false, label = "应援", text = "当你于回合内使用的牌置入弃牌堆时，你可以将之交给一名其他角色（装备牌无法触发'应援'，相同牌名的牌每回合限一次）。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_yingyuan"])
    general:addSkill(runtime)
end

-- 周瑜 常规
do
    local general = sgs.General(extension, "nuyan_zhouyu", "wu", 4, true)
    translations["nuyan_zhouyu"] = "周瑜"
    translations["#nuyan_zhouyu"] = "怒焰·常规"
    if not skills["nuyan_fanjian"] then register({id = "nuyan_fanjian", mode = "fanjian", classic = false, jie = false, label = "反间", text = "出牌阶段，你可以将1张黑桃手牌当做【水淹七军】使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_fanjian"])
    general:addSkill(runtime)
end

-- 周瑜 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhouyu", "wu", 4, true)
    translations["nuyan_jd_zhouyu"] = "周瑜"
    translations["#nuyan_jd_zhouyu"] = "怒焰·经典"
    if not skills["nuyan_jd_fanjian"] then register({id = "nuyan_jd_fanjian", mode = "fanjian", classic = true, jie = false, label = "反间", text = "出牌阶段，你可以将1张黑桃手牌当做【水淹七军】使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_fanjian"])
    general:addSkill(runtime)
end

-- 孙尚香 常规
do
    local general = sgs.General(extension, "nuyan_sunshangxiang", "wu", 4, true)
    translations["nuyan_sunshangxiang"] = "孙尚香"
    translations["#nuyan_sunshangxiang"] = "怒焰·常规"
    if not skills["nuyan_xiaoji"] then register({id = "nuyan_xiaoji", mode = "xiaoji", classic = false, jie = false, label = "枭姬", text = "当你失去装备区里的1张牌时，你可以选择一项：1.摸2张牌；2.回复1点体力。", compulsory = false}) end
    general:addSkill(skills["nuyan_xiaoji"])
    general:addSkill(runtime)
end

-- 孙尚香 经典
do
    local general = sgs.General(extension, "nuyan_jd_sunshangxiang", "wu", 4, true)
    translations["nuyan_jd_sunshangxiang"] = "孙尚香"
    translations["#nuyan_jd_sunshangxiang"] = "怒焰·经典"
    if not skills["nuyan_jd_xiaoji"] then register({id = "nuyan_jd_xiaoji", mode = "xiaoji", classic = true, jie = false, label = "枭姬", text = "当你失去装备区里的1张牌时，你可以选择一项：1.摸2张牌；2.回复1点体力。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_xiaoji"])
    general:addSkill(runtime)
end

-- 大乔 常规
do
    local general = sgs.General(extension, "nuyan_daqiao", "wu", 4, true)
    translations["nuyan_daqiao"] = "大乔"
    translations["#nuyan_daqiao"] = "怒焰·常规"
    if not skills["nuyan_guose"] then register({id = "nuyan_guose", mode = "guose", classic = false, jie = false, label = "国色", text = "出牌阶段，你可以将1张方块手牌当做【乐不思蜀】普通使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_guose"])
    general:addSkill(runtime)
end

-- 大乔 经典
do
    local general = sgs.General(extension, "nuyan_jd_daqiao", "wu", 4, true)
    translations["nuyan_jd_daqiao"] = "大乔"
    translations["#nuyan_jd_daqiao"] = "怒焰·经典"
    if not skills["nuyan_jd_guose"] then register({id = "nuyan_jd_guose", mode = "guose", classic = true, jie = false, label = "国色", text = "出牌阶段，你可以将1张方块手牌当做【乐不思蜀】普通使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_guose"])
    general:addSkill(runtime)
end

-- 孙权 常规
do
    local general = sgs.General(extension, "nuyan_sunquan", "wu", 4, true)
    translations["nuyan_sunquan"] = "孙权"
    translations["#nuyan_sunquan"] = "怒焰·常规"
    if not skills["nuyan_zhiheng"] then register({id = "nuyan_zhiheng", mode = "zhiheng", classic = false, jie = false, label = "制衡", text = "出牌阶段限一次，你可以弃置至多4张牌，然后摸等量的牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_zhiheng"])
    general:addSkill(runtime)
end

-- 孙权 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_sunquan", "wu", 4, true)
    translations["nuyan_jie_sunquan"] = "孙权"
    translations["#nuyan_jie_sunquan"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_zhiheng"] then register({id = "nuyan_jie_zhiheng", mode = "zhiheng", classic = false, jie = true, label = "制衡", text = "出牌阶段限一次，你可以弃置任意张牌，然后摸等量的牌。若你以此法弃置的牌中包括所有手牌或所有装备区的牌，你多摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jie_zhiheng"])
    general:addSkill(runtime)
end

-- 孙权 经典
do
    local general = sgs.General(extension, "nuyan_jd_sunquan", "wu", 4, true)
    translations["nuyan_jd_sunquan"] = "孙权"
    translations["#nuyan_jd_sunquan"] = "怒焰·经典"
    if not skills["nuyan_jd_zhiheng"] then register({id = "nuyan_jd_zhiheng", mode = "zhiheng", classic = true, jie = false, label = "制衡", text = "出牌阶段限一次，你可以弃置任意张牌，然后摸等量的牌。若你以此法弃置的牌中包括所有手牌，你多摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_zhiheng"])
    general:addSkill(runtime)
end

-- 孙权 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_sunquan", "wu", 4, true)
    translations["nuyan_jd_jie_sunquan"] = "孙权"
    translations["#nuyan_jd_jie_sunquan"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_zhiheng"] then register({id = "nuyan_jd_jie_zhiheng", mode = "zhiheng", classic = true, jie = true, label = "制衡", text = "出牌阶段限一次，你可以弃置任意张牌，然后摸等量的牌。若你以此法弃置的牌中包括所有手牌或所有装备区的牌，你多摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_jie_zhiheng"])
    general:addSkill(runtime)
end

-- 凌操 常规
do
    local general = sgs.General(extension, "nuyan_lingcao", "wu", 4, true)
    translations["nuyan_lingcao"] = "凌操"
    translations["#nuyan_lingcao"] = "怒焰·常规"
    if not skills["nuyan_dujin"] then register({id = "nuyan_dujin", mode = "dujin", classic = false, jie = false, label = "独进", text = "锁定技，摸牌阶段，摸牌数+X（X为你装备区牌数）。", compulsory = true}) end
    general:addSkill(skills["nuyan_dujin"])
    general:addSkill(runtime)
end

-- 凌操 经典
do
    local general = sgs.General(extension, "nuyan_jd_lingcao", "wu", 4, true)
    translations["nuyan_jd_lingcao"] = "凌操"
    translations["#nuyan_jd_lingcao"] = "怒焰·经典"
    if not skills["nuyan_jd_dujin"] then register({id = "nuyan_jd_dujin", mode = "dujin", classic = true, jie = false, label = "独进", text = "锁定技，摸牌阶段，摸牌数+X（X为你装备区牌数）。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_dujin"])
    general:addSkill(runtime)
end

-- 孙坚 常规
do
    local general = sgs.General(extension, "nuyan_sunjian", "wu", 4, true)
    translations["nuyan_sunjian"] = "孙坚"
    translations["#nuyan_sunjian"] = "怒焰·常规"
    if not skills["nuyan_yinghun"] then register({id = "nuyan_yinghun", mode = "yinghun", classic = false, jie = false, label = "英魂", text = "当你的体力值减少时，你可以选择一名其他角色，令其选择一项：1.令你摸2张牌；2.其随机弃置2张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_yinghun"])
    general:addSkill(runtime)
end

-- 孙坚 经典
do
    local general = sgs.General(extension, "nuyan_jd_sunjian", "wu", 4, true)
    translations["nuyan_jd_sunjian"] = "孙坚"
    translations["#nuyan_jd_sunjian"] = "怒焰·经典"
    if not skills["nuyan_jd_yinghun"] then register({id = "nuyan_jd_yinghun", mode = "yinghun", classic = true, jie = false, label = "英魂", text = "当你的体力值减少时，你可以选择一名其他角色，令其选择一项：1.令你摸2张牌；2.其随机弃置2张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_yinghun"])
    general:addSkill(runtime)
end

-- 周泰 常规
do
    local general = sgs.General(extension, "nuyan_zhoutai", "wu", 4, true)
    translations["nuyan_zhoutai"] = "周泰"
    translations["#nuyan_zhoutai"] = "怒焰·常规"
    if not skills["nuyan_fenji"] then register({id = "nuyan_fenji", mode = "fenji", classic = false, jie = false, label = "奋激", text = "当一名角色于回合外失去手牌后，你可以失去1点体力，然后进行判定：若为黑色，则失去手牌的角色摸1张牌；若为红色，则其摸2张牌。此时，若你的体力小于该角色的体力，你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_fenji"])
    general:addSkill(runtime)
end

-- 周泰 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhoutai", "wu", 4, true)
    translations["nuyan_jd_zhoutai"] = "周泰"
    translations["#nuyan_jd_zhoutai"] = "怒焰·经典"
    if not skills["nuyan_jd_fenji"] then register({id = "nuyan_jd_fenji", mode = "fenji", classic = true, jie = false, label = "奋激", text = "当一名角色于回合外失去手牌后，你可以失去1点体力，然后进行判定：若为黑色，则失去手牌的角色摸1张牌；若为红色，则其摸2张牌。此时，若你的体力小于该角色的体力，你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_fenji"])
    general:addSkill(runtime)
end

-- 鲁肃 常规
do
    local general = sgs.General(extension, "nuyan_lusu", "wu", 4, true)
    translations["nuyan_lusu"] = "鲁肃"
    translations["#nuyan_lusu"] = "怒焰·常规"
    if not skills["nuyan_haoshi"] then register({id = "nuyan_haoshi", mode = "haoshi", classic = false, jie = false, label = "好施", text = "锁定技，摸牌阶段，你多摸2张牌，然后若你的手牌数大于6，则你可以将一半手牌交给手牌少于你的一名其他角色（向下取整）。", compulsory = true}) end
    general:addSkill(skills["nuyan_haoshi"])
    general:addSkill(runtime)
end

-- 鲁肃 经典
do
    local general = sgs.General(extension, "nuyan_jd_lusu", "wu", 4, true)
    translations["nuyan_jd_lusu"] = "鲁肃"
    translations["#nuyan_jd_lusu"] = "怒焰·经典"
    if not skills["nuyan_jd_haoshi"] then register({id = "nuyan_jd_haoshi", mode = "haoshi", classic = true, jie = false, label = "好施", text = "锁定技，摸牌阶段，你多摸2张牌，然后若你的手牌数大于6，则你可以将一半手牌交给手牌少于你的一名其他角色（向下取整）。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_haoshi"])
    general:addSkill(runtime)
end

-- 徐盛 常规
do
    local general = sgs.General(extension, "nuyan_xusheng", "wu", 4, true)
    translations["nuyan_xusheng"] = "徐盛"
    translations["#nuyan_xusheng"] = "怒焰·常规"
    if not skills["nuyan_pojun"] then register({id = "nuyan_pojun", mode = "pojun", classic = false, jie = false, label = "破军", text = "当你使用【杀】指定一个目标后，你可以将其至多X+1张手牌扣置于该角色的武将牌旁（X为你的星级）。当前回合结束后，该角色获得这些牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_pojun"])
    general:addSkill(runtime)
end

-- 徐盛 经典
do
    local general = sgs.General(extension, "nuyan_jd_xusheng", "wu", 4, true)
    translations["nuyan_jd_xusheng"] = "徐盛"
    translations["#nuyan_jd_xusheng"] = "怒焰·经典"
    if not skills["nuyan_jd_pojun"] then register({id = "nuyan_jd_pojun", mode = "pojun", classic = true, jie = false, label = "破军", text = "当你使用【杀】指定一个目标后，你可以将其至多4张手牌扣置于该角色的武将牌旁：若其中有装备牌，随机弃置其中1张；若其中有锦囊牌，你摸1张牌。当前回合结束后，该角色获得这些牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_pojun"])
    general:addSkill(runtime)
end

-- 诸葛恪 常规
do
    local general = sgs.General(extension, "nuyan_zhugeke", "wu", 4, true)
    translations["nuyan_zhugeke"] = "诸葛恪"
    translations["#nuyan_zhugeke"] = "怒焰·常规"
    if not skills["nuyan_duwu"] then register({id = "nuyan_duwu", mode = "duwu", classic = false, jie = false, label = "黩武", text = "出牌阶段，你可以选择任意一名其他角色并弃置X张牌（X为该角色体力值的一半向上取整），然后对其造成1点伤害。若其因受到此伤害而进入濒死状态，当此濒死结算结束后，若其存活，你失去1点体力，此技能于此回合内不可再次使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_duwu"])
    general:addSkill(runtime)
end

-- 诸葛恪 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_zhugeke", "wu", 4, true)
    translations["nuyan_jie_zhugeke"] = "诸葛恪"
    translations["#nuyan_jie_zhugeke"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_duwu"] then register({id = "nuyan_jie_duwu", mode = "duwu", classic = false, jie = true, label = "黩武", text = "出牌阶段，你可以弃置1张牌，然后对一名其他角色造成1点伤害。若其因'黩武'而进入濒死状态，当此濒死结算结束后，若其存活，你失去1点体力，此技能于此回合内不可再次使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jie_duwu"])
    general:addSkill(runtime)
end

-- 诸葛恪 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhugeke", "wu", 4, true)
    translations["nuyan_jd_zhugeke"] = "诸葛恪"
    translations["#nuyan_jd_zhugeke"] = "怒焰·经典"
    if not skills["nuyan_jd_duwu"] then register({id = "nuyan_jd_duwu", mode = "duwu", classic = true, jie = false, label = "黩武", text = "出牌阶段，你可以选择任意一名其他角色并弃置X张牌（X为该角色体力值的一半向上取整），然后对其造成1点伤害。若其因受到此伤害而进入濒死状态，当此濒死结算结束后，若其存活，你失去1点体力，此技能于此回合内不可再次使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_duwu"])
    general:addSkill(runtime)
end

-- 诸葛恪 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_zhugeke", "wu", 4, true)
    translations["nuyan_jd_jie_zhugeke"] = "诸葛恪"
    translations["#nuyan_jd_jie_zhugeke"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_duwu"] then register({id = "nuyan_jd_jie_duwu", mode = "duwu", classic = true, jie = true, label = "黩武", text = "出牌阶段，你可以弃置1张牌，然后对一名其他角色造成1点伤害。若其因'黩武'而进入濒死状态，当此濒死结算结束后，若其存活，你失去1点体力，此技能于此回合内不可再次使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_jie_duwu"])
    general:addSkill(runtime)
end

-- 吴国太 常规
do
    local general = sgs.General(extension, "nuyan_wuguotai", "wu", 4, true)
    translations["nuyan_wuguotai"] = "吴国太"
    translations["#nuyan_wuguotai"] = "怒焰·常规"
    if not skills["nuyan_ganlu"] then register({id = "nuyan_ganlu", mode = "ganlu", classic = false, jie = false, label = "甘露", text = "其他角色的结束阶段，若你于此回合失去的牌不大于你的怒气上限，你可以摸等同于失去数量的牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_ganlu"])
    general:addSkill(runtime)
end

-- 吴国太 经典
do
    local general = sgs.General(extension, "nuyan_jd_wuguotai", "wu", 4, true)
    translations["nuyan_jd_wuguotai"] = "吴国太"
    translations["#nuyan_jd_wuguotai"] = "怒焰·经典"
    if not skills["nuyan_jd_ganlu"] then register({id = "nuyan_jd_ganlu", mode = "ganlu", classic = true, jie = false, label = "甘露", text = "其他角色的结束阶段，若你于此回合失去的牌不大于你的怒气上限，你可以摸等同于失去数量的牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_ganlu"])
    general:addSkill(runtime)
end

-- 张昭 常规
do
    local general = sgs.General(extension, "nuyan_zhangzhao", "wu", 4, true)
    translations["nuyan_zhangzhao"] = "张昭"
    translations["#nuyan_zhangzhao"] = "怒焰·常规"
    if not skills["nuyan_zhijian"] then register({id = "nuyan_zhijian", mode = "zhijian", classic = false, jie = false, label = "直谏", text = "出牌阶段限X次，你可以弃置1张手牌并选择一名其他角色，然后随机将牌堆或弃牌堆中的1张装备牌置于其装备区，然后你摸1张牌（X为你的星级）。", compulsory = false}) end
    general:addSkill(skills["nuyan_zhijian"])
    general:addSkill(runtime)
end

-- 张昭 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhangzhao", "wu", 4, true)
    translations["nuyan_jd_zhangzhao"] = "张昭"
    translations["#nuyan_jd_zhangzhao"] = "怒焰·经典"
    if not skills["nuyan_jd_zhijian"] then register({id = "nuyan_jd_zhijian", mode = "zhijian", classic = true, jie = false, label = "直谏", text = "出牌阶段限4次，你可以弃置1张手牌并选择一名其他角色，然后随机将牌堆或弃牌堆中的1张装备牌置于其装备区，然后你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_zhijian"])
    general:addSkill(runtime)
end

-- 貂蝉 常规
do
    local general = sgs.General(extension, "nuyan_diaochan", "qun", 4, true)
    translations["nuyan_diaochan"] = "貂蝉"
    translations["#nuyan_diaochan"] = "怒焰·常规"
    if not skills["nuyan_lihun"] then register({id = "nuyan_lihun", mode = "lihun", classic = false, jie = false, label = "离魂", text = "出牌阶段限一次，你可以失去1点怒气，然后获得一名其他角色的X张手牌（X为你的星级），若如此做本回合内你不能换将。出牌阶段结束时，你交给该角色Y张手牌（Y为其怒气值）。", compulsory = false}) end
    general:addSkill(skills["nuyan_lihun"])
    general:addSkill(runtime)
end

-- 貂蝉 经典
do
    local general = sgs.General(extension, "nuyan_jd_diaochan", "qun", 4, true)
    translations["nuyan_jd_diaochan"] = "貂蝉"
    translations["#nuyan_jd_diaochan"] = "怒焰·经典"
    if not skills["nuyan_jd_lihun"] then register({id = "nuyan_jd_lihun", mode = "lihun", classic = true, jie = false, label = "离魂", text = "出牌阶段限一次，你可以失去1点怒气，然后获得一名其他角色的所有手牌。出牌阶段结束时，你交给该角色X张手牌（X为其怒气值）。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_lihun"])
    general:addSkill(runtime)
end

-- 张角 常规
do
    local general = sgs.General(extension, "nuyan_zhangjiao", "qun", 4, true)
    translations["nuyan_zhangjiao"] = "张角"
    translations["#nuyan_zhangjiao"] = "怒焰·常规"
    if not skills["nuyan_leifa"] then register({id = "nuyan_leifa", mode = "leifa", classic = false, jie = false, label = "雷罚", text = "你的方块手牌可以当做【闪】使用或打出。你使用或打出【闪】后，可以令一名角色流失1点体力。", compulsory = false}) end
    general:addSkill(skills["nuyan_leifa"])
    general:addSkill(runtime)
end

-- 张角 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_zhangjiao", "qun", 4, true)
    translations["nuyan_jie_zhangjiao"] = "张角"
    translations["#nuyan_jie_zhangjiao"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_leifa"] then register({id = "nuyan_jie_leifa", mode = "leifa", classic = false, jie = true, label = "雷罚", text = "你的方块手牌可以当做【闪】使用或打出。你使用或打出【闪】后，选择一名角色流失1点体力且你获得1点怒气。", compulsory = false}) end
    general:addSkill(skills["nuyan_jie_leifa"])
    general:addSkill(runtime)
end

-- 张角 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhangjiao", "qun", 4, true)
    translations["nuyan_jd_zhangjiao"] = "张角"
    translations["#nuyan_jd_zhangjiao"] = "怒焰·经典"
    if not skills["nuyan_jd_leifa"] then register({id = "nuyan_jd_leifa", mode = "leifa", classic = true, jie = false, label = "雷罚", text = "你的方块手牌可以当做【闪】使用或打出。你使用或打出【闪】后，可以令一名角色流失1点体力。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_leifa"])
    general:addSkill(runtime)
end

-- 张角 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_zhangjiao", "qun", 4, true)
    translations["nuyan_jd_jie_zhangjiao"] = "张角"
    translations["#nuyan_jd_jie_zhangjiao"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_leifa"] then register({id = "nuyan_jd_jie_leifa", mode = "leifa", classic = true, jie = true, label = "雷罚", text = "你的方块手牌可以当做【闪】使用或打出。你使用或打出【闪】后，选择一名角色流失1点体力且你获得1点怒气。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_jie_leifa"])
    general:addSkill(runtime)
end

-- 祝融 常规
do
    local general = sgs.General(extension, "nuyan_zhurong", "qun", 4, true)
    translations["nuyan_zhurong"] = "祝融"
    translations["#nuyan_zhurong"] = "怒焰·常规"
    if not skills["nuyan_lieren"] then register({id = "nuyan_lieren", mode = "lieren", classic = false, jie = false, label = "烈刃", text = "出牌阶段，当你造成伤害后，你可以获得受伤角色的1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_lieren"])
    general:addSkill(runtime)
end

-- 祝融 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_zhurong", "qun", 4, true)
    translations["nuyan_jie_zhurong"] = "祝融"
    translations["#nuyan_jie_zhurong"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_lieren"] then register({id = "nuyan_jie_lieren", mode = "lieren", classic = false, jie = true, label = "烈刃", text = "出牌阶段，当你造成伤害后，你可以获得受伤角色的1张牌，若该伤害值大于1，你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jie_lieren"])
    general:addSkill(runtime)
end

-- 祝融 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhurong", "qun", 4, true)
    translations["nuyan_jd_zhurong"] = "祝融"
    translations["#nuyan_jd_zhurong"] = "怒焰·经典"
    if not skills["nuyan_jd_lieren"] then register({id = "nuyan_jd_lieren", mode = "lieren", classic = true, jie = false, label = "烈刃", text = "出牌阶段，当你造成伤害后，你可以获得受伤角色的1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_lieren"])
    general:addSkill(runtime)
end

-- 祝融 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_zhurong", "qun", 4, true)
    translations["nuyan_jd_jie_zhurong"] = "祝融"
    translations["#nuyan_jd_jie_zhurong"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_lieren"] then register({id = "nuyan_jd_jie_lieren", mode = "lieren", classic = true, jie = true, label = "烈刃", text = "出牌阶段，当你造成伤害后，你可以获得受伤角色的1张牌，若该伤害值大于1，你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_jie_lieren"])
    general:addSkill(runtime)
end

-- 孟获 常规
do
    local general = sgs.General(extension, "nuyan_menghuo", "qun", 4, true)
    translations["nuyan_menghuo"] = "孟获"
    translations["#nuyan_menghuo"] = "怒焰·常规"
    if not skills["nuyan_manyi"] then register({id = "nuyan_manyi", mode = "manyi", classic = false, jie = false, label = "蛮裔", text = "出牌阶段限3次，你可以消耗1点怒气，视为使用1张普通【南蛮入侵】。", compulsory = false}) end
    general:addSkill(skills["nuyan_manyi"])
    general:addSkill(runtime)
end

-- 孟获 经典
do
    local general = sgs.General(extension, "nuyan_jd_menghuo", "qun", 4, true)
    translations["nuyan_jd_menghuo"] = "孟获"
    translations["#nuyan_jd_menghuo"] = "怒焰·经典"
    if not skills["nuyan_jd_manyi"] then register({id = "nuyan_jd_manyi", mode = "manyi", classic = true, jie = false, label = "蛮裔", text = "出牌阶段限3次，你可以消耗1点怒气，视为使用1张普通【南蛮入侵】。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_manyi"])
    general:addSkill(runtime)
end

-- 华佗 常规
do
    local general = sgs.General(extension, "nuyan_huatuo", "qun", 4, true)
    translations["nuyan_huatuo"] = "华佗"
    translations["#nuyan_huatuo"] = "怒焰·常规"
    if not skills["nuyan_jijiu"] then register({id = "nuyan_jijiu", mode = "jijiu", classic = false, jie = false, label = "急救", text = "你可以将1张红桃手牌当做【桃】使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jijiu"])
    general:addSkill(runtime)
end

-- 华佗 经典
do
    local general = sgs.General(extension, "nuyan_jd_huatuo", "qun", 4, true)
    translations["nuyan_jd_huatuo"] = "华佗"
    translations["#nuyan_jd_huatuo"] = "怒焰·经典"
    if not skills["nuyan_jd_jijiu"] then register({id = "nuyan_jd_jijiu", mode = "jijiu", classic = true, jie = false, label = "急救", text = "你可以将1张红桃手牌当做【桃】使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_jijiu"])
    general:addSkill(runtime)
end

-- 曹节 常规
do
    local general = sgs.General(extension, "nuyan_caojie", "qun", 4, true)
    translations["nuyan_caojie"] = "曹节"
    translations["#nuyan_caojie"] = "怒焰·常规"
    if not skills["nuyan_shouxi"] then register({id = "nuyan_shouxi", mode = "shouxi", classic = false, jie = false, label = "守玺", text = "当你的怒气溢出时，你可以消耗2点怒气，令一名其他角色流失X+1点体力（X为你当前的怒气值）。", compulsory = false}) end
    general:addSkill(skills["nuyan_shouxi"])
    general:addSkill(runtime)
end

-- 曹节 经典
do
    local general = sgs.General(extension, "nuyan_jd_caojie", "qun", 4, true)
    translations["nuyan_jd_caojie"] = "曹节"
    translations["#nuyan_jd_caojie"] = "怒焰·经典"
    if not skills["nuyan_jd_shouxi"] then register({id = "nuyan_jd_shouxi", mode = "shouxi", classic = true, jie = false, label = "守玺", text = "当你的怒气溢出时，你可以消耗2点怒气，令一名其他角色流失X+1点体力（X为你当前的怒气值）。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_shouxi"])
    general:addSkill(runtime)
end

-- 刘协 常规
do
    local general = sgs.General(extension, "nuyan_liuxie", "qun", 4, true)
    translations["nuyan_liuxie"] = "刘协"
    translations["#nuyan_liuxie"] = "怒焰·常规"
    if not skills["nuyan_tianming"] then register({id = "nuyan_tianming", mode = "tianming", classic = false, jie = false, label = "天命", text = "当你成为【杀】的目标后，你可以弃置2张牌再摸2张牌。然后，你可以将自己的1张手牌交给一名其他角色。", compulsory = false}) end
    general:addSkill(skills["nuyan_tianming"])
    general:addSkill(runtime)
end

-- 刘协 经典
do
    local general = sgs.General(extension, "nuyan_jd_liuxie", "qun", 4, true)
    translations["nuyan_jd_liuxie"] = "刘协"
    translations["#nuyan_jd_liuxie"] = "怒焰·经典"
    if not skills["nuyan_jd_tianming"] then register({id = "nuyan_jd_tianming", mode = "tianming", classic = true, jie = false, label = "天命", text = "当你成为【杀】的目标后，你可以弃置2张牌再摸2张牌。然后，你可以令一名角色摸1张牌，若此角色不是你，你获得1点怒气。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_tianming"])
    general:addSkill(runtime)
end

-- 陈宫 常规
do
    local general = sgs.General(extension, "nuyan_chengong", "qun", 4, true)
    translations["nuyan_chengong"] = "陈宫"
    translations["#nuyan_chengong"] = "怒焰·常规"
    if not skills["nuyan_zhichi"] then register({id = "nuyan_zhichi", mode = "zhichi", classic = false, jie = false, label = "智迟", text = "锁定技，其他角色的回合，若你的怒气值变化过，当你受到大于1的伤害时，伤害-1。", compulsory = true}) end
    general:addSkill(skills["nuyan_zhichi"])
    general:addSkill(runtime)
end

-- 陈宫 经典
do
    local general = sgs.General(extension, "nuyan_jd_chengong", "qun", 4, true)
    translations["nuyan_jd_chengong"] = "陈宫"
    translations["#nuyan_jd_chengong"] = "怒焰·经典"
    if not skills["nuyan_jd_zhichi"] then register({id = "nuyan_jd_zhichi", mode = "zhichi", classic = true, jie = false, label = "智迟", text = "锁定技，其他角色的回合，若你的怒气值变化过，当你受到大于1的伤害时，伤害-1。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_zhichi"])
    general:addSkill(runtime)
end

-- 公孙瓒 常规
do
    local general = sgs.General(extension, "nuyan_gongsunzan", "qun", 4, true)
    translations["nuyan_gongsunzan"] = "公孙瓒"
    translations["#nuyan_gongsunzan"] = "怒焰·常规"
    if not skills["nuyan_yicong"] then register({id = "nuyan_yicong", mode = "yicong", classic = false, jie = false, label = "义从", text = "锁定技，若你的体力值不大于你的星级，你免疫体力流失，且你造成伤害时，伤害+1。", compulsory = true}) end
    general:addSkill(skills["nuyan_yicong"])
    general:addSkill(runtime)
end

-- 公孙瓒 常规·界限突破
do
    local general = sgs.General(extension, "nuyan_jie_gongsunzan", "qun", 4, true)
    translations["nuyan_jie_gongsunzan"] = "公孙瓒"
    translations["#nuyan_jie_gongsunzan"] = "怒焰·常规·界限突破"
    if not skills["nuyan_jie_yicong"] then register({id = "nuyan_jie_yicong", mode = "yicong", classic = false, jie = true, label = "义从", text = "锁定技，若你的体力值不大于你的星级，你免疫体力流失；若你的体力值大于你的星级，你造成的伤害均改为体力流失。", compulsory = true}) end
    general:addSkill(skills["nuyan_jie_yicong"])
    general:addSkill(runtime)
end

-- 公孙瓒 经典
do
    local general = sgs.General(extension, "nuyan_jd_gongsunzan", "qun", 4, true)
    translations["nuyan_jd_gongsunzan"] = "公孙瓒"
    translations["#nuyan_jd_gongsunzan"] = "怒焰·经典"
    if not skills["nuyan_jd_yicong"] then register({id = "nuyan_jd_yicong", mode = "yicong", classic = true, jie = false, label = "义从", text = "锁定技，若你的体力值不大于3，你免疫体力流失，且你造成伤害时，伤害+1。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_yicong"])
    general:addSkill(runtime)
end

-- 公孙瓒 经典·界限突破
do
    local general = sgs.General(extension, "nuyan_jd_jie_gongsunzan", "qun", 4, true)
    translations["nuyan_jd_jie_gongsunzan"] = "公孙瓒"
    translations["#nuyan_jd_jie_gongsunzan"] = "怒焰·经典·界限突破"
    if not skills["nuyan_jd_jie_yicong"] then register({id = "nuyan_jd_jie_yicong", mode = "yicong", classic = true, jie = true, label = "义从", text = "锁定技，若你的体力值不大于3，你免疫体力流失；若你的体力值大于3，你造成的伤害均改为体力流失。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_jie_yicong"])
    general:addSkill(runtime)
end

-- 高顺 常规
do
    local general = sgs.General(extension, "nuyan_gaoshun", "qun", 4, true)
    translations["nuyan_gaoshun"] = "高顺"
    translations["#nuyan_gaoshun"] = "怒焰·常规"
    if not skills["nuyan_xianzhen"] then register({id = "nuyan_xianzhen", mode = "xianzhen", classic = false, jie = false, label = "陷阵", text = "出牌阶段限一次，你可以与一名其他角色拼点：若你赢，此出牌阶段你无视该角色的防具，对其使用黑色【杀】无距离和次数限制；若你没赢，此出牌阶段你不能使用【杀】。", compulsory = false}) end
    general:addSkill(skills["nuyan_xianzhen"])
    general:addSkill(runtime)
end

-- 高顺 经典
do
    local general = sgs.General(extension, "nuyan_jd_gaoshun", "qun", 4, true)
    translations["nuyan_jd_gaoshun"] = "高顺"
    translations["#nuyan_jd_gaoshun"] = "怒焰·经典"
    if not skills["nuyan_jd_xianzhen"] then register({id = "nuyan_jd_xianzhen", mode = "xianzhen", classic = true, jie = false, label = "陷阵", text = "出牌阶段限一次，你可以与一名其他角色拼点：若你赢，此出牌阶段你无视该角色的防具，对其使用【杀】无距离和次数限制；若你没赢，此出牌阶段你不能使用【杀】。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_xianzhen"])
    general:addSkill(runtime)
end

-- 蔡夫人 常规
do
    local general = sgs.General(extension, "nuyan_caifuren", "qun", 4, true)
    translations["nuyan_caifuren"] = "蔡夫人"
    translations["#nuyan_caifuren"] = "怒焰·常规"
    if not skills["nuyan_xianzhou"] then register({id = "nuyan_xianzhou", mode = "xianzhou", classic = false, jie = false, label = "献州", text = "出牌阶段限一次，你可以将装备区里的所有牌与一名有装备的其他角色交换：若你得到的装备多，你此回合出【杀】次数+1；若你送出的装备多，你回复1点体力；若双方交换的装备一样多，你摸1张牌且怒气+1。", compulsory = false}) end
    general:addSkill(skills["nuyan_xianzhou"])
    general:addSkill(runtime)
end

-- 蔡夫人 经典
do
    local general = sgs.General(extension, "nuyan_jd_caifuren", "qun", 4, true)
    translations["nuyan_jd_caifuren"] = "蔡夫人"
    translations["#nuyan_jd_caifuren"] = "怒焰·经典"
    if not skills["nuyan_jd_xianzhou"] then register({id = "nuyan_jd_xianzhou", mode = "xianzhou", classic = true, jie = false, label = "献州", text = "出牌阶段限一次，你可以将装备区里的所有牌与一名有装备的其他角色交换：若你得到的装备多，你此回合出【杀】次数+1；若你送出的装备多，你回复1点体力；若双方交换的装备一样多，你摸1张牌且怒气+1。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_xianzhou"])
    general:addSkill(runtime)
end

-- 袁术 常规
do
    local general = sgs.General(extension, "nuyan_yuanshu", "qun", 4, true)
    translations["nuyan_yuanshu"] = "袁术"
    translations["#nuyan_yuanshu"] = "怒焰·常规"
    if not skills["nuyan_yongsi"] then register({id = "nuyan_yongsi", mode = "yongsi", classic = false, jie = false, label = "庸肆", text = "锁定技，摸牌阶段，你多摸X+1张牌（X为场上的势力数）；弃牌阶段开始时，你选择一项：1.多弃置1张牌；2.失去1点体力。", compulsory = true}) end
    general:addSkill(skills["nuyan_yongsi"])
    general:addSkill(runtime)
end

-- 袁术 经典
do
    local general = sgs.General(extension, "nuyan_jd_yuanshu", "qun", 4, true)
    translations["nuyan_jd_yuanshu"] = "袁术"
    translations["#nuyan_jd_yuanshu"] = "怒焰·经典"
    if not skills["nuyan_jd_yongsi"] then register({id = "nuyan_jd_yongsi", mode = "yongsi", classic = true, jie = false, label = "庸肆", text = "锁定技，摸牌阶段，你多摸X+1张牌（X为场上的势力数）；弃牌阶段开始时，你选择一项：1.多弃置1张牌；2.失去1点体力。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_yongsi"])
    general:addSkill(runtime)
end

-- 董白 常规
do
    local general = sgs.General(extension, "nuyan_dongbai", "qun", 4, true)
    translations["nuyan_dongbai"] = "董白"
    translations["#nuyan_dongbai"] = "怒焰·常规"
    if not skills["nuyan_xiahui"] then register({id = "nuyan_xiahui", mode = "xiahui", classic = false, jie = false, label = "黠慧", text = "锁定技，你的黑色牌不占用手牌上限；其他角色获得你的黑色牌时，其不能使用、打出、弃置这些牌直至其体力值减少为止。", compulsory = true}) end
    general:addSkill(skills["nuyan_xiahui"])
    general:addSkill(runtime)
end

-- 董白 经典
do
    local general = sgs.General(extension, "nuyan_jd_dongbai", "qun", 4, true)
    translations["nuyan_jd_dongbai"] = "董白"
    translations["#nuyan_jd_dongbai"] = "怒焰·经典"
    if not skills["nuyan_jd_xiahui"] then register({id = "nuyan_jd_xiahui", mode = "xiahui", classic = true, jie = false, label = "黠慧", text = "锁定技，你的黑色牌不占用手牌上限；其他角色获得你的黑色牌时，其不能使用、打出、弃置这些牌直至其体力值减少为止。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_xiahui"])
    general:addSkill(runtime)
end

-- 沮授 常规
do
    local general = sgs.General(extension, "nuyan_jushou", "qun", 4, true)
    translations["nuyan_jushou"] = "沮授"
    translations["#nuyan_jushou"] = "怒焰·常规"
    if not skills["nuyan_jianying"] then register({id = "nuyan_jianying", mode = "jianying", classic = false, jie = false, label = "渐营", text = "锁定技，当你于出牌阶段内使用牌时，若此牌与你使用的上一张牌点数或花色相同，则你摸1张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_jianying"])
    general:addSkill(runtime)
end

-- 沮授 经典
do
    local general = sgs.General(extension, "nuyan_jd_jushou", "qun", 4, true)
    translations["nuyan_jd_jushou"] = "沮授"
    translations["#nuyan_jd_jushou"] = "怒焰·经典"
    if not skills["nuyan_jd_jianying"] then register({id = "nuyan_jd_jianying", mode = "jianying", classic = true, jie = false, label = "渐营", text = "锁定技，当你于出牌阶段内使用牌时，若此牌与你使用的上一张牌点数或花色相同，则你摸1张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_jianying"])
    general:addSkill(runtime)
end

-- 甄姬 常规
do
    local general = sgs.General(extension, "nuyan_zhenji", "wei", 4, true)
    translations["nuyan_zhenji"] = "甄姬"
    translations["#nuyan_zhenji"] = "怒焰·常规"
    if not skills["nuyan_luoshen"] then register({id = "nuyan_luoshen", mode = "luoshen", classic = false, jie = false, label = "洛神", text = "回合开始时，你进行判定并获得判定牌，若判定牌为黑色，重复此流程。你可以将1张黑色手牌当做【闪】使用或打出。", compulsory = false}) end
    general:addSkill(skills["nuyan_luoshen"])
    general:addSkill(runtime)
end

-- 甄姬 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhenji", "wei", 4, true)
    translations["nuyan_jd_zhenji"] = "甄姬"
    translations["#nuyan_jd_zhenji"] = "怒焰·经典"
    if not skills["nuyan_jd_luoshen"] then register({id = "nuyan_jd_luoshen", mode = "luoshen", classic = true, jie = false, label = "洛神", text = "回合开始时，你进行判定并获得判定牌，若判定牌为黑色，重复此流程。你可以将1张黑色手牌当做【闪】使用或打出。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_luoshen"])
    general:addSkill(runtime)
end

-- 曹丕 常规
do
    local general = sgs.General(extension, "nuyan_caopi", "wei", 4, true)
    translations["nuyan_caopi"] = "曹丕"
    translations["#nuyan_caopi"] = "怒焰·常规"
    if not skills["nuyan_fangzhu"] then register({id = "nuyan_fangzhu", mode = "fangzhu", classic = false, jie = false, label = "放逐", text = "当你的体力减少后，你可以令一名其他角色失去1点怒气，并随机失去2张手牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_fangzhu"])
    general:addSkill(runtime)
end

-- 曹丕 经典
do
    local general = sgs.General(extension, "nuyan_jd_caopi", "wei", 4, true)
    translations["nuyan_jd_caopi"] = "曹丕"
    translations["#nuyan_jd_caopi"] = "怒焰·经典"
    if not skills["nuyan_jd_fangzhu"] then register({id = "nuyan_jd_fangzhu", mode = "fangzhu", classic = true, jie = false, label = "放逐", text = "当你的体力减少后，你可以令一名其他角色失去1点怒气，并随机失去2张手牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_fangzhu"])
    general:addSkill(runtime)
end

-- 辛宪英 常规
do
    local general = sgs.General(extension, "nuyan_xinxianying", "wei", 4, true)
    translations["nuyan_xinxianying"] = "辛宪英"
    translations["#nuyan_xinxianying"] = "怒焰·常规"
    if not skills["nuyan_zhongjian"] then register({id = "nuyan_zhongjian", mode = "zhongjian", classic = false, jie = false, label = "忠鉴", text = "出牌阶段限一次，你可以展示1张手牌并弃置之，选择一名其他角色随机展示其X张手牌（X为你的星级），弃置其中花色相同的手牌；若没有花色相同的牌，则你选择获得其中2张。", compulsory = false}) end
    general:addSkill(skills["nuyan_zhongjian"])
    general:addSkill(runtime)
end

-- 辛宪英 经典
do
    local general = sgs.General(extension, "nuyan_jd_xinxianying", "wei", 4, true)
    translations["nuyan_jd_xinxianying"] = "辛宪英"
    translations["#nuyan_jd_xinxianying"] = "怒焰·经典"
    if not skills["nuyan_jd_zhongjian"] then register({id = "nuyan_jd_zhongjian", mode = "zhongjian", classic = true, jie = false, label = "忠鉴", text = "出牌阶段限一次，你可以展示1张手牌并弃置之，选择一名其他角色随机展示其至多4张手牌，弃置其中颜色相同的手牌；若没有颜色相同的牌，则你选择获得其中2张。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_zhongjian"])
    general:addSkill(runtime)
end

-- 戏志才 常规
do
    local general = sgs.General(extension, "nuyan_xizhicai", "wei", 4, true)
    translations["nuyan_xizhicai"] = "戏志才"
    translations["#nuyan_xizhicai"] = "怒焰·常规"
    if not skills["nuyan_chouce"] then register({id = "nuyan_chouce", mode = "chouce", classic = false, jie = false, label = "筹策", text = "当你体力减少时，你可以进行判定，若结果为：黑色，你弃置一名其他角色区域里的X+1张牌；红色，你令一名角色摸2X张牌，先辅的角色摸X张（X为你体力减少值）。", compulsory = false}) end
    general:addSkill(skills["nuyan_chouce"])
    general:addSkill(runtime)
end

-- 戏志才 经典
do
    local general = sgs.General(extension, "nuyan_jd_xizhicai", "wei", 4, true)
    translations["nuyan_jd_xizhicai"] = "戏志才"
    translations["#nuyan_jd_xizhicai"] = "怒焰·经典"
    if not skills["nuyan_jd_chouce"] then register({id = "nuyan_jd_chouce", mode = "chouce", classic = true, jie = false, label = "筹策", text = "当你体力变化时，你可以进行判定，若结果为：黑色，你弃置一名其他角色区域里的X+1张牌；红色，你令一名角色摸2X张牌（X为你体力变化值）。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_chouce"])
    general:addSkill(runtime)
end

-- 程昱 常规
do
    local general = sgs.General(extension, "nuyan_chengyu", "wei", 4, true)
    translations["nuyan_chengyu"] = "程昱"
    translations["#nuyan_chengyu"] = "怒焰·常规"
    if not skills["nuyan_shefu"] then register({id = "nuyan_shefu", mode = "shefu", classic = false, jie = false, label = "设伏", text = "结束阶段，你可以弃置1张手牌并记录2个基本牌或锦囊牌的名称，称为'伏兵'。当其他角色于你的回合外使用或打出牌时，你可以移去1个记录名称相同的'伏兵'，然后此牌无效。直至使用者的回合结束，其触发的技能符石失效。", compulsory = false}) end
    general:addSkill(skills["nuyan_shefu"])
    general:addSkill(runtime)
end

-- 程昱 经典
do
    local general = sgs.General(extension, "nuyan_jd_chengyu", "wei", 4, true)
    translations["nuyan_jd_chengyu"] = "程昱"
    translations["#nuyan_jd_chengyu"] = "怒焰·经典"
    if not skills["nuyan_jd_shefu"] then register({id = "nuyan_jd_shefu", mode = "shefu", classic = true, jie = false, label = "设伏", text = "结束阶段，你可以弃置1张手牌并记录2个基本牌或锦囊牌的名称，称为'伏兵'。当其他角色于你的回合外使用或打出牌时，你可以移去1个记录名称相同的'伏兵'，然后此牌无效。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_shefu"])
    general:addSkill(runtime)
end

-- 郭照 常规
do
    local general = sgs.General(extension, "nuyan_guozhao", "wei", 4, true)
    translations["nuyan_guozhao"] = "郭照"
    translations["#nuyan_guozhao"] = "怒焰·常规"
    if not skills["nuyan_pianchong"] then register({id = "nuyan_pianchong", mode = "pianchong", classic = false, jie = false, label = "偏宠", text = "出牌阶段限一次，你选择一项直到你的下回合开始：1.你每失去1张红色手牌时摸1张黑色牌；2.你每失去1张黑色手牌时摸1张红色牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_pianchong"])
    general:addSkill(runtime)
end

-- 郭照 经典
do
    local general = sgs.General(extension, "nuyan_jd_guozhao", "wei", 4, true)
    translations["nuyan_jd_guozhao"] = "郭照"
    translations["#nuyan_jd_guozhao"] = "怒焰·经典"
    if not skills["nuyan_jd_pianchong"] then register({id = "nuyan_jd_pianchong", mode = "pianchong", classic = true, jie = false, label = "偏宠", text = "出牌阶段限一次，你选择一项直到你的下回合开始：1.你每失去1张红色手牌时摸1张黑色牌；2.你每失去1张黑色手牌时摸1张红色牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_pianchong"])
    general:addSkill(runtime)
end

-- 赵云 常规
do
    local general = sgs.General(extension, "nuyan_zhaoyun", "shu", 4, true)
    translations["nuyan_zhaoyun"] = "赵云"
    translations["#nuyan_zhaoyun"] = "怒焰·常规"
    if not skills["nuyan_juejing"] then register({id = "nuyan_juejing", mode = "juejing", classic = false, jie = false, label = "绝境", text = "锁定技，摸牌阶段，你多摸等同于你已损失的体力值数的牌；你的手牌上限始终+X（X为你的星级）。", compulsory = true}) end
    general:addSkill(skills["nuyan_juejing"])
    general:addSkill(runtime)
end

-- 赵云 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhaoyun", "shu", 4, true)
    translations["nuyan_jd_zhaoyun"] = "赵云"
    translations["#nuyan_jd_zhaoyun"] = "怒焰·经典"
    if not skills["nuyan_jd_juejing"] then register({id = "nuyan_jd_juejing", mode = "juejing", classic = true, jie = false, label = "绝境", text = "锁定技，摸牌阶段，你多摸等同于你已损失的体力值数的牌；你的手牌上限始终+5。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_juejing"])
    general:addSkill(runtime)
end

-- 诸葛亮 常规
do
    local general = sgs.General(extension, "nuyan_zhugeliang", "shu", 4, true)
    translations["nuyan_zhugeliang"] = "诸葛亮"
    translations["#nuyan_zhugeliang"] = "怒焰·常规"
    if not skills["nuyan_jitian"] then register({id = "nuyan_jitian", mode = "jitian", classic = false, jie = false, label = "祭天", text = "出牌阶段，你可以弃置1张牌，令一名角色获得1点怒气，然后其相邻角色失去1点怒气。", compulsory = false}) end
    general:addSkill(skills["nuyan_jitian"])
    general:addSkill(runtime)
end

-- 诸葛亮 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhugeliang", "shu", 4, true)
    translations["nuyan_jd_zhugeliang"] = "诸葛亮"
    translations["#nuyan_jd_zhugeliang"] = "怒焰·经典"
    if not skills["nuyan_jd_jitian"] then register({id = "nuyan_jd_jitian", mode = "jitian", classic = true, jie = false, label = "祭天", text = "出牌阶段，你可以弃置1张牌，令一名角色获得1点怒气，然后其相邻角色失去1点怒气。若失去怒气的目标是自己，则免于失去怒气。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_jitian"])
    general:addSkill(runtime)
end

-- 董允 常规
do
    local general = sgs.General(extension, "nuyan_dongyun", "shu", 4, true)
    translations["nuyan_dongyun"] = "董允"
    translations["#nuyan_dongyun"] = "怒焰·常规"
    if not skills["nuyan_bingzheng"] then register({id = "nuyan_bingzheng", mode = "bingzheng", classic = false, jie = false, label = "秉正", text = "你的回合内，当你使用单体非延时锦囊时，可以增加一个额外的目标，若不增加则该锦囊牌效果+1，相同锦囊牌每回合限一次。", compulsory = false}) end
    general:addSkill(skills["nuyan_bingzheng"])
    general:addSkill(runtime)
end

-- 董允 经典
do
    local general = sgs.General(extension, "nuyan_jd_dongyun", "shu", 4, true)
    translations["nuyan_jd_dongyun"] = "董允"
    translations["#nuyan_jd_dongyun"] = "怒焰·经典"
    if not skills["nuyan_jd_bingzheng"] then register({id = "nuyan_jd_bingzheng", mode = "bingzheng", classic = true, jie = false, label = "秉正", text = "你的回合内，当你使用单体非延时锦囊时，可以增加一个额外的目标，若不增加则该锦囊牌效果+1，相同锦囊牌每回合限一次。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_bingzheng"])
    general:addSkill(runtime)
end

-- 关索 常规
do
    local general = sgs.General(extension, "nuyan_guansuo", "shu", 4, true)
    translations["nuyan_guansuo"] = "关索"
    translations["#nuyan_guansuo"] = "怒焰·常规"
    if not skills["nuyan_zhengnan"] then register({id = "nuyan_zhengnan", mode = "zhengnan", classic = false, jie = false, label = "征南", text = "锁定技，每名角色限一次，当一名角色体力值降低至X及以下时（X为你的星级），你摸1张牌并选择获得其中一个技能：武圣、当先、心战（若技能均已获得则改为摸3张牌）。", compulsory = true}) end
    general:addSkill(skills["nuyan_zhengnan"])
    general:addSkill(runtime)
end

-- 关索 经典
do
    local general = sgs.General(extension, "nuyan_jd_guansuo", "shu", 4, true)
    translations["nuyan_jd_guansuo"] = "关索"
    translations["#nuyan_jd_guansuo"] = "怒焰·经典"
    if not skills["nuyan_jd_zhengnan"] then register({id = "nuyan_jd_zhengnan", mode = "zhengnan", classic = true, jie = false, label = "征南", text = "锁定技，每名角色限一次，当一名角色体力值降低至2及以下时，你摸1张牌并选择获得其中一个技能：武圣、当先、心战（若技能均已获得则改为摸3张牌）。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_zhengnan"])
    general:addSkill(runtime)
end

-- 鲍三娘 常规
do
    local general = sgs.General(extension, "nuyan_baosanniang", "shu", 4, true)
    translations["nuyan_baosanniang"] = "鲍三娘"
    translations["#nuyan_baosanniang"] = "怒焰·常规"
    if not skills["nuyan_wuniang"] then register({id = "nuyan_wuniang", mode = "wuniang", classic = false, jie = false, label = "武娘", text = "每当你于回合内对一名其他角色使用1张【杀】结算后，你可令其对你使用1张【杀】。若其出【杀】，你摸1张牌且本回合你的【杀】的使用次数+1；若其不出【杀】，你摸2张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_wuniang"])
    general:addSkill(runtime)
end

-- 鲍三娘 经典
do
    local general = sgs.General(extension, "nuyan_jd_baosanniang", "shu", 4, true)
    translations["nuyan_jd_baosanniang"] = "鲍三娘"
    translations["#nuyan_jd_baosanniang"] = "怒焰·经典"
    if not skills["nuyan_jd_wuniang"] then register({id = "nuyan_jd_wuniang", mode = "wuniang", classic = true, jie = false, label = "武娘", text = "每当你于回合内对一名其他角色使用1张【杀】结算后，你可令其对你使用1张【杀】。若其出【杀】，你摸1张牌且本回合你的【杀】的使用次数+1；若其不出【杀】，你摸2张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_wuniang"])
    general:addSkill(runtime)
end

-- 赵襄 常规
do
    local general = sgs.General(extension, "nuyan_zhaoxiang", "shu", 4, true)
    translations["nuyan_zhaoxiang"] = "赵襄"
    translations["#nuyan_zhaoxiang"] = "怒焰·常规"
    if not skills["nuyan_fanghun"] then register({id = "nuyan_fanghun", mode = "fanghun", classic = false, jie = false, label = "芳魂", text = "锁定技，当你使用【杀】指定目标后或当你成为【杀】的目标后，你获得1点怒气，若怒气已满，则改为摸1张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_fanghun"])
    general:addSkill(runtime)
end

-- 赵襄 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhaoxiang", "shu", 4, true)
    translations["nuyan_jd_zhaoxiang"] = "赵襄"
    translations["#nuyan_jd_zhaoxiang"] = "怒焰·经典"
    if not skills["nuyan_jd_fanghun"] then register({id = "nuyan_jd_fanghun", mode = "fanghun", classic = true, jie = false, label = "芳魂", text = "锁定技，当你使用【杀】指定目标后或当你成为【杀】的目标后，你获得1点怒气，若怒气已满，则改为摸1张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_fanghun"])
    general:addSkill(runtime)
end

-- 孙策 常规
do
    local general = sgs.General(extension, "nuyan_sunce", "wu", 4, true)
    translations["nuyan_sunce"] = "孙策"
    translations["#nuyan_sunce"] = "怒焰·常规"
    if not skills["nuyan_jiangang"] then register({id = "nuyan_jiangang", mode = "jiangang", classic = false, jie = false, label = "激昂", text = "锁定技，当你使用或打出【杀】、【决斗】，或者当你成为【杀】、【决斗】的目标后，你获得1点怒气。", compulsory = true}) end
    general:addSkill(skills["nuyan_jiangang"])
    general:addSkill(runtime)
end

-- 孙策 经典
do
    local general = sgs.General(extension, "nuyan_jd_sunce", "wu", 4, true)
    translations["nuyan_jd_sunce"] = "孙策"
    translations["#nuyan_jd_sunce"] = "怒焰·经典"
    if not skills["nuyan_jd_jiangang"] then register({id = "nuyan_jd_jiangang", mode = "jiangang", classic = true, jie = false, label = "激昂", text = "锁定技，当你使用或打出【杀】、【决斗】，或者当你成为【杀】、【决斗】的目标后，你获得1点怒气。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_jiangang"])
    general:addSkill(runtime)
end

-- 步练师 常规
do
    local general = sgs.General(extension, "nuyan_bulianshi", "wu", 4, true)
    translations["nuyan_bulianshi"] = "步练师"
    translations["#nuyan_bulianshi"] = "怒焰·常规"
    if not skills["nuyan_anxu"] then register({id = "nuyan_anxu", mode = "anxu", classic = false, jie = false, label = "安恤", text = "你或相邻角色体力减少时，你可以随机弃置1张牌，令一名角色怒气-2。", compulsory = false}) end
    general:addSkill(skills["nuyan_anxu"])
    general:addSkill(runtime)
end

-- 步练师 经典
do
    local general = sgs.General(extension, "nuyan_jd_bulianshi", "wu", 4, true)
    translations["nuyan_jd_bulianshi"] = "步练师"
    translations["#nuyan_jd_bulianshi"] = "怒焰·经典"
    if not skills["nuyan_jd_anxu"] then register({id = "nuyan_jd_anxu", mode = "anxu", classic = true, jie = false, label = "安恤", text = "你或相邻角色体力减少时，你可以随机弃置1张牌，令一名角色怒气-2。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_anxu"])
    general:addSkill(runtime)
end

-- 太史慈 常规
do
    local general = sgs.General(extension, "nuyan_taishici", "wu", 4, true)
    translations["nuyan_taishici"] = "太史慈"
    translations["#nuyan_taishici"] = "怒焰·常规"
    if not skills["nuyan_dulie"] then register({id = "nuyan_dulie", mode = "dulie", classic = false, jie = false, label = "笃烈", text = "出牌阶段限一次，你可以令一名角色将任意1张手牌当做强化【无中生有】使用，然后该角色出杀次数增加至X+1次，直至其换将或者其回合结束（X为你的星级）。", compulsory = false}) end
    general:addSkill(skills["nuyan_dulie"])
    general:addSkill(runtime)
end

-- 太史慈 经典
do
    local general = sgs.General(extension, "nuyan_jd_taishici", "wu", 4, true)
    translations["nuyan_jd_taishici"] = "太史慈"
    translations["#nuyan_jd_taishici"] = "怒焰·经典"
    if not skills["nuyan_jd_dulie"] then register({id = "nuyan_jd_dulie", mode = "dulie", classic = true, jie = false, label = "笃烈", text = "出牌阶段限一次，你可以令一名角色将任意1张手牌当做【无中生有】使用，然后该角色出杀次数+2，直至其换将或者其回合结束。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_dulie"])
    general:addSkill(runtime)
end

-- 孙皓 常规
do
    local general = sgs.General(extension, "nuyan_sunhao", "wu", 4, true)
    translations["nuyan_sunhao"] = "孙皓"
    translations["#nuyan_sunhao"] = "怒焰·常规"
    if not skills["nuyan_canshi"] then register({id = "nuyan_canshi", mode = "canshi", classic = false, jie = false, label = "残蚀", text = "出牌阶段限一次，你可以将所有'仇'标记转化为等量伤害，对其他角色各造成至多2点伤害（'仇'标记来源：当你使用【杀】或非延时锦囊时，以及当你受到伤害大于1时，你获得1枚'仇'标记）。", compulsory = false}) end
    general:addSkill(skills["nuyan_canshi"])
    general:addSkill(runtime)
end

-- 孙皓 经典
do
    local general = sgs.General(extension, "nuyan_jd_sunhao", "wu", 4, true)
    translations["nuyan_jd_sunhao"] = "孙皓"
    translations["#nuyan_jd_sunhao"] = "怒焰·经典"
    if not skills["nuyan_jd_canshi"] then register({id = "nuyan_jd_canshi", mode = "canshi", classic = true, jie = false, label = "残蚀", text = "出牌阶段限一次，你可以将所有'仇'标记转化为等量伤害，对其他角色各造成至多2点伤害（'仇'标记来源：当你使用【杀】或非延时锦囊时，以及当你受到伤害大于1时，你获得1枚'仇'标记）。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_canshi"])
    general:addSkill(runtime)
end

-- 留赞 常规
do
    local general = sgs.General(extension, "nuyan_liuzan", "wu", 4, true)
    translations["nuyan_liuzan"] = "留赞"
    translations["#nuyan_liuzan"] = "怒焰·常规"
    if not skills["nuyan_fenyin"] then register({id = "nuyan_fenyin", mode = "fenyin", classic = false, jie = false, label = "奋音", text = "锁定技，你的回合内，当你使用1张与上一张颜色不同的牌时，你摸1张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_fenyin"])
    general:addSkill(runtime)
end

-- 留赞 经典
do
    local general = sgs.General(extension, "nuyan_jd_liuzan", "wu", 4, true)
    translations["nuyan_jd_liuzan"] = "留赞"
    translations["#nuyan_jd_liuzan"] = "怒焰·经典"
    if not skills["nuyan_jd_fenyin"] then register({id = "nuyan_jd_fenyin", mode = "fenyin", classic = true, jie = false, label = "奋音", text = "锁定技，你的回合内，当你使用1张与上一张颜色不同的牌时，你摸1张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_fenyin"])
    general:addSkill(runtime)
end

-- 诸葛瑾 常规
do
    local general = sgs.General(extension, "nuyan_zhugejin", "wu", 4, true)
    translations["nuyan_zhugejin"] = "诸葛瑾"
    translations["#nuyan_zhugejin"] = "怒焰·常规"
    if not skills["nuyan_hongyuan"] then register({id = "nuyan_hongyuan", mode = "hongyuan", classic = false, jie = false, label = "弘援", text = "当你不因'弘援'效果获得红色牌后，你令一名其他角色摸2张牌或者你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_hongyuan"])
    general:addSkill(runtime)
end

-- 诸葛瑾 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhugejin", "wu", 4, true)
    translations["nuyan_jd_zhugejin"] = "诸葛瑾"
    translations["#nuyan_jd_zhugejin"] = "怒焰·经典"
    if not skills["nuyan_jd_hongyuan"] then register({id = "nuyan_jd_hongyuan", mode = "hongyuan", classic = true, jie = false, label = "弘援", text = "当你不因'弘援'效果获得红色牌后，你令一名其他角色摸2张牌或者你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_hongyuan"])
    general:addSkill(runtime)
end

-- 吕布 常规
do
    local general = sgs.General(extension, "nuyan_lvbu", "qun", 4, true)
    translations["nuyan_lvbu"] = "吕布"
    translations["#nuyan_lvbu"] = "怒焰·常规"
    if not skills["nuyan_shenwei"] then register({id = "nuyan_shenwei", mode = "shenwei", classic = false, jie = false, label = "神威", text = "锁定技，你使用的【杀】不能被强化【闪】响应，你的【杀】造成伤害时，若你的怒气值大于目标角色的怒气值，此【杀】伤害+X（X为你与其的怒气差值）。", compulsory = true}) end
    general:addSkill(skills["nuyan_shenwei"])
    general:addSkill(runtime)
end

-- 吕布 经典
do
    local general = sgs.General(extension, "nuyan_jd_lvbu", "qun", 4, true)
    translations["nuyan_jd_lvbu"] = "吕布"
    translations["#nuyan_jd_lvbu"] = "怒焰·经典"
    if not skills["nuyan_jd_shenwei"] then register({id = "nuyan_jd_shenwei", mode = "shenwei", classic = true, jie = false, label = "神威", text = "锁定技，你使用的【杀】不能被强化【闪】响应，你的【杀】造成伤害时，此【杀】伤害+X（X为你的怒气值）。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_shenwei"])
    general:addSkill(runtime)
end

-- 蔡文姬 常规
do
    local general = sgs.General(extension, "nuyan_caiwenji", "qun", 4, true)
    translations["nuyan_caiwenji"] = "蔡文姬"
    translations["#nuyan_caiwenji"] = "怒焰·常规"
    if not skills["nuyan_beige"] then register({id = "nuyan_beige", mode = "beige", classic = false, jie = false, label = "悲歌", text = "其他角色对你造成伤害后，你可以弃置1张牌，若此牌：为红色，你摸3张牌；为黑色，你弃置该角色任意区域2张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_beige"])
    general:addSkill(runtime)
end

-- 蔡文姬 经典
do
    local general = sgs.General(extension, "nuyan_jd_caiwenji", "qun", 4, true)
    translations["nuyan_jd_caiwenji"] = "蔡文姬"
    translations["#nuyan_jd_caiwenji"] = "怒焰·经典"
    if not skills["nuyan_jd_beige"] then register({id = "nuyan_jd_beige", mode = "beige", classic = true, jie = false, label = "悲歌", text = "其他角色对你造成伤害后，你可以弃置1张牌，若此牌：为红色，你摸3张牌；为黑色，你弃置该角色任意区域2张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_beige"])
    general:addSkill(runtime)
end

-- 贾诩 常规
do
    local general = sgs.General(extension, "nuyan_jiaxu", "qun", 4, true)
    translations["nuyan_jiaxu"] = "贾诩"
    translations["#nuyan_jiaxu"] = "怒焰·常规"
    if not skills["nuyan_luanwu"] then register({id = "nuyan_luanwu", mode = "luanwu", classic = false, jie = false, label = "乱武", text = "出牌阶段限X+1次（X为你的星级），你可以消耗1点怒气，令场上其他角色依次弃置1张【杀】，否则流失1点体力。", compulsory = false}) end
    general:addSkill(skills["nuyan_luanwu"])
    general:addSkill(runtime)
end

-- 贾诩 经典
do
    local general = sgs.General(extension, "nuyan_jd_jiaxu", "qun", 4, true)
    translations["nuyan_jd_jiaxu"] = "贾诩"
    translations["#nuyan_jd_jiaxu"] = "怒焰·经典"
    if not skills["nuyan_jd_luanwu"] then register({id = "nuyan_jd_luanwu", mode = "luanwu", classic = true, jie = false, label = "乱武", text = "出牌阶段限2次，你可以消耗1点怒气，令场上其他角色依次弃置1张【杀】，否则流失1点体力。你可以将黑色【杀】当做【看破】使用。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_luanwu"])
    general:addSkill(skills["nuyan_jd_kanpo_card"])
    general:addSkill(runtime)
end

-- 于吉 常规
do
    local general = sgs.General(extension, "nuyan_yuji", "qun", 4, true)
    translations["nuyan_yuji"] = "于吉"
    translations["#nuyan_yuji"] = "怒焰·常规"
    if not skills["nuyan_guhuo"] then register({id = "nuyan_guhuo", mode = "guhuo", classic = false, jie = false, label = "蛊惑", text = "锁定技，你使用的单体非延时锦囊牌需要相同花色的牌才能响应；你使用的【杀】指定目标后，若其没有使用花色相同的【闪】响应，则此伤害+1。", compulsory = true}) end
    general:addSkill(skills["nuyan_guhuo"])
    general:addSkill(runtime)
end

-- 于吉 经典
do
    local general = sgs.General(extension, "nuyan_jd_yuji", "qun", 4, true)
    translations["nuyan_jd_yuji"] = "于吉"
    translations["#nuyan_jd_yuji"] = "怒焰·经典"
    if not skills["nuyan_jd_guhuo"] then register({id = "nuyan_jd_guhuo", mode = "guhuo", classic = true, jie = false, label = "蛊惑", text = "锁定技，你使用的单体非延时锦囊牌需要相同花色的牌才能响应；你使用的【杀】指定目标后，若其没有使用花色相同的【闪】响应，则此伤害+1。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_guhuo"])
    general:addSkill(runtime)
end

-- 李儒 常规
do
    local general = sgs.General(extension, "nuyan_liru", "qun", 4, true)
    translations["nuyan_liru"] = "李儒"
    translations["#nuyan_liru"] = "怒焰·常规"
    if not skills["nuyan_fencheng"] then register({id = "nuyan_fencheng", mode = "fencheng", classic = false, jie = false, label = "焚城", text = "出牌阶段，你可以令所有角色依次选择一项：1.弃置至少X张牌（若上一名进行选择的角色以此法弃置过牌，X为其以此法弃置的牌数+1，否则X为1）；2.受到你造成的2点体力流失（对你自己无效）。此技能每回合首次发动时不消耗怒气，同一回合再次发动时怒气消耗+1。", compulsory = false}) end
    general:addSkill(skills["nuyan_fencheng"])
    general:addSkill(runtime)
end

-- 李儒 经典
do
    local general = sgs.General(extension, "nuyan_jd_liru", "qun", 4, true)
    translations["nuyan_jd_liru"] = "李儒"
    translations["#nuyan_jd_liru"] = "怒焰·经典"
    if not skills["nuyan_jd_fencheng"] then register({id = "nuyan_jd_fencheng", mode = "fencheng", classic = true, jie = false, label = "焚城", text = "出牌阶段，你可以令所有角色依次选择一项：1.弃置至少X张牌（若上一名进行选择的角色以此法弃置过牌，X为其以此法弃置的牌数+1，否则X为1）；2.受到你造成的1点体力流失（对你自己无效）。此技能每回合首次发动时不消耗怒气，同一回合再次发动时怒气消耗+1。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_fencheng"])
    general:addSkill(runtime)
end

-- 灵雎 常规
do
    local general = sgs.General(extension, "nuyan_lingju", "qun", 4, true)
    translations["nuyan_lingju"] = "灵雎"
    translations["#nuyan_lingju"] = "怒焰·常规"
    if not skills["nuyan_fenxin"] then register({id = "nuyan_fenxin", mode = "fenxin", classic = false, jie = false, label = "焚心", text = "出牌阶段限X次（X为你的怒气上限），你可以消耗1点怒气并选择一名角色，令其在回合内下一次使用【杀】造成伤害+1。", compulsory = false}) end
    general:addSkill(skills["nuyan_fenxin"])
    general:addSkill(runtime)
end

-- 灵雎 经典
do
    local general = sgs.General(extension, "nuyan_jd_lingju", "qun", 4, true)
    translations["nuyan_jd_lingju"] = "灵雎"
    translations["#nuyan_jd_lingju"] = "怒焰·经典"
    if not skills["nuyan_jd_fenxin"] then register({id = "nuyan_jd_fenxin", mode = "fenxin", classic = true, jie = false, label = "焚心", text = "出牌阶段限X次（X为你的怒气上限），你可以消耗1点怒气并选择一名角色，令其在回合内下一次使用【杀】造成伤害+1。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_fenxin"])
    general:addSkill(runtime)
end

-- 吕玲绮 常规
do
    local general = sgs.General(extension, "nuyan_lvlingqi", "qun", 4, true)
    translations["nuyan_lvlingqi"] = "吕玲绮"
    translations["#nuyan_lvlingqi"] = "怒焰·常规"
    if not skills["nuyan_guowu"] then register({id = "nuyan_guowu", mode = "guowu", classic = false, jie = false, label = "帼武", text = "出牌阶段开始时，你可以展示所有手牌，若展示牌的类型数大于等于：1.你使用的【杀】不能被强化【闪】响应；2.此阶段你可以额外使用X张【杀】（X为你的星级）；3.你从牌堆或弃牌堆中获得Y张【杀】（Y为你已损失的体力值且至少为1）。", compulsory = false}) end
    general:addSkill(skills["nuyan_guowu"])
    general:addSkill(runtime)
end

-- 吕玲绮 经典
do
    local general = sgs.General(extension, "nuyan_jd_lvlingqi", "qun", 4, true)
    translations["nuyan_jd_lvlingqi"] = "吕玲绮"
    translations["#nuyan_jd_lvlingqi"] = "怒焰·经典"
    if not skills["nuyan_jd_guowu"] then register({id = "nuyan_jd_guowu", mode = "guowu", classic = true, jie = false, label = "帼武", text = "出牌阶段开始时，你可以展示所有手牌，若展示牌的类型数大于等于：1.你使用的【杀】不能被强化【闪】响应；2.此阶段你可以额外使用5张【杀】；3.你从牌堆或弃牌堆中获得X张【杀】（X为你已损失的体力值且至少为1）。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_guowu"])
    general:addSkill(runtime)
end

-- 孙鲁班 常规
do
    local general = sgs.General(extension, "nuyan_sunluban", "wu", 4, true)
    translations["nuyan_sunluban"] = "孙鲁班"
    translations["#nuyan_sunluban"] = "怒焰·常规"
    if not skills["nuyan_zenhui"] then register({id = "nuyan_zenhui", mode = "zenhui", classic = false, jie = false, label = "谮毁", text = "出牌阶段限X次（X为你的星级），当你使用【杀】或单体非延时锦囊牌指定一个目标时，你可以令此目标以外的一名其他角色选择一项：1.随机交给你1张手牌，然后代替你成为此牌的使用者；2.也成为此牌的目标。若没有适合执行选择的目标时，你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_zenhui"])
    general:addSkill(runtime)
end

-- 孙鲁班 经典
do
    local general = sgs.General(extension, "nuyan_jd_sunluban", "wu", 4, true)
    translations["nuyan_jd_sunluban"] = "孙鲁班"
    translations["#nuyan_jd_sunluban"] = "怒焰·经典"
    if not skills["nuyan_jd_zenhui"] then register({id = "nuyan_jd_zenhui", mode = "zenhui", classic = true, jie = false, label = "谮毁", text = "出牌阶段限X次（X为你的怒气上限），当你使用【杀】或单体非延时锦囊牌指定一个目标时，你可以令此目标以外的一名其他角色选择一项：1.随机交给你1张手牌，然后代替你成为此牌的使用者；2.也成为此牌的目标。若没有适合执行选择的目标时，你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_zenhui"])
    general:addSkill(runtime)
end

-- 孙鲁育 常规
do
    local general = sgs.General(extension, "nuyan_sunluyu", "wu", 4, true)
    translations["nuyan_sunluyu"] = "孙鲁育"
    translations["#nuyan_sunluyu"] = "怒焰·常规"
    if not skills["nuyan_meibu"] then register({id = "nuyan_meibu", mode = "meibu", classic = false, jie = false, label = "魅步", text = "其他角色的出牌阶段开始时，你可以弃置1张牌，令该角色于其本阶段内使用【杀】或单体非延时锦囊牌时随机弃置1张手牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_meibu"])
    general:addSkill(runtime)
end

-- 孙鲁育 经典
do
    local general = sgs.General(extension, "nuyan_jd_sunluyu", "wu", 4, true)
    translations["nuyan_jd_sunluyu"] = "孙鲁育"
    translations["#nuyan_jd_sunluyu"] = "怒焰·经典"
    if not skills["nuyan_jd_meibu"] then register({id = "nuyan_jd_meibu", mode = "meibu", classic = true, jie = false, label = "魅步", text = "其他角色的出牌阶段开始时，你可以弃置1张牌，令该角色于其本阶段内使用【杀】或单体非延时锦囊牌时随机弃置1张手牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_meibu"])
    general:addSkill(runtime)
end

-- 关平 常规
do
    local general = sgs.General(extension, "nuyan_guanping", "shu", 4, true)
    translations["nuyan_guanping"] = "关平"
    translations["#nuyan_guanping"] = "怒焰·常规"
    if not skills["nuyan_longyin"] then register({id = "nuyan_longyin", mode = "longyin", classic = false, jie = false, label = "龙吟", text = "当一名角色于其出牌阶段内使用【杀】时，你可以弃置1张牌，令此【杀】不计入出牌阶段的使用次数，然后若此【杀】为红色，你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_longyin"])
    general:addSkill(runtime)
end

-- 关平 经典
do
    local general = sgs.General(extension, "nuyan_jd_guanping", "shu", 4, true)
    translations["nuyan_jd_guanping"] = "关平"
    translations["#nuyan_jd_guanping"] = "怒焰·经典"
    if not skills["nuyan_jd_longyin"] then register({id = "nuyan_jd_longyin", mode = "longyin", classic = true, jie = false, label = "龙吟", text = "当一名角色于其出牌阶段内使用【杀】时，你可以弃置1张牌，令此【杀】不计入出牌阶段的使用次数，然后若此【杀】为红色，你摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_longyin"])
    general:addSkill(runtime)
end

-- 秦宓 常规
do
    local general = sgs.General(extension, "nuyan_qinmi", "shu", 4, true)
    translations["nuyan_qinmi"] = "秦宓"
    translations["#nuyan_qinmi"] = "怒焰·常规"
    if not skills["nuyan_zhuandui"] then register({id = "nuyan_zhuandui", mode = "zhuandui", classic = false, jie = false, label = "专对", text = "当你使用【杀】指定目标后，你可以摸1张牌并与其拼点，若你赢，其不能响应此【杀】；当你成为【杀】的目标后，你可以摸1张牌并与其拼点，若你赢，此【杀】对你无效。", compulsory = false}) end
    general:addSkill(skills["nuyan_zhuandui"])
    general:addSkill(runtime)
end

-- 秦宓 经典
do
    local general = sgs.General(extension, "nuyan_jd_qinmi", "shu", 4, true)
    translations["nuyan_jd_qinmi"] = "秦宓"
    translations["#nuyan_jd_qinmi"] = "怒焰·经典"
    if not skills["nuyan_jd_zhuandui"] then register({id = "nuyan_jd_zhuandui", mode = "zhuandui", classic = true, jie = false, label = "专对", text = "当你使用【杀】指定目标后，你可以摸1张牌并与其拼点，若你赢，其不能响应此【杀】；当你成为【杀】的目标后，你可以摸1张牌并与其拼点，若你赢，此【杀】对你无效。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_zhuandui"])
    general:addSkill(runtime)
end

-- 夏侯氏 常规
do
    local general = sgs.General(extension, "nuyan_xiahoushi", "shu", 4, true)
    translations["nuyan_xiahoushi"] = "夏侯氏"
    translations["#nuyan_xiahoushi"] = "怒焰·常规"
    if not skills["nuyan_yanyu"] then register({id = "nuyan_yanyu", mode = "yanyu", classic = false, jie = false, label = "燕语", text = "出牌阶段，你可以弃置【杀】；你的回合内，有【杀】进入弃牌堆后，你可以选择一名角色，其获得1点怒气，你摸1张牌，然后若该角色不是你，则你与其再各摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_yanyu"])
    general:addSkill(runtime)
end

-- 夏侯氏 经典
do
    local general = sgs.General(extension, "nuyan_jd_xiahoushi", "shu", 4, true)
    translations["nuyan_jd_xiahoushi"] = "夏侯氏"
    translations["#nuyan_jd_xiahoushi"] = "怒焰·经典"
    if not skills["nuyan_jd_yanyu"] then register({id = "nuyan_jd_yanyu", mode = "yanyu", classic = true, jie = false, label = "燕语", text = "出牌阶段，你可以弃置【杀】；你的回合内，有【杀】进入弃牌堆后，你可以选择一名角色，其获得1点怒气，你摸1张牌，然后若该角色不是你，则你与其再各摸1张牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_yanyu"])
    general:addSkill(runtime)
end

-- 许攸 常规
do
    local general = sgs.General(extension, "nuyan_xuyou", "wei", 4, true)
    translations["nuyan_xuyou"] = "许攸"
    translations["#nuyan_xuyou"] = "怒焰·常规"
    if not skills["nuyan_shicai"] then register({id = "nuyan_shicai", mode = "shicai", classic = false, jie = false, label = "恃才", text = "当你使用或打出1张牌后，若你本回合未使用或打出过与此牌相同类型的牌（包括装备牌），则你可以将此牌置于牌堆顶，然后摸1张牌。你摸牌时，改为从牌堆底摸牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_shicai"])
    general:addSkill(runtime)
end

-- 许攸 经典
do
    local general = sgs.General(extension, "nuyan_jd_xuyou", "wei", 4, true)
    translations["nuyan_jd_xuyou"] = "许攸"
    translations["#nuyan_jd_xuyou"] = "怒焰·经典"
    if not skills["nuyan_jd_shicai"] then register({id = "nuyan_jd_shicai", mode = "shicai", classic = true, jie = false, label = "恃才", text = "当你使用或打出1张牌后，若你本回合未使用或打出过与此牌相同类型的牌（包括装备牌），则你可以将此牌置于牌堆顶，然后摸1张牌。你摸牌时，改为从牌堆底摸牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_shicai"])
    general:addSkill(runtime)
end

-- 周妃 常规
do
    local general = sgs.General(extension, "nuyan_zhoufei", "wu", 4, true)
    translations["nuyan_zhoufei"] = "周妃"
    translations["#nuyan_zhoufei"] = "怒焰·常规"
    if not skills["nuyan_kongsheng"] then register({id = "nuyan_kongsheng", mode = "kongsheng", classic = false, jie = false, label = "箜声", text = "准备阶段，你可以将任意张牌置于你的武将牌旁，称为'箜'，然后你可以选择一名其他角色，随机将其等量的牌置入'箜'。结束阶段，你从'箜'中选择X张牌交给其（X为其置入'箜'的牌数）。你的回合结束时，你获得所有的'箜'。", compulsory = false}) end
    general:addSkill(skills["nuyan_kongsheng"])
    general:addSkill(runtime)
end

-- 周妃 经典
do
    local general = sgs.General(extension, "nuyan_jd_zhoufei", "wu", 4, true)
    translations["nuyan_jd_zhoufei"] = "周妃"
    translations["#nuyan_jd_zhoufei"] = "怒焰·经典"
    if not skills["nuyan_jd_kongsheng"] then register({id = "nuyan_jd_kongsheng", mode = "kongsheng", classic = true, jie = false, label = "箜声", text = "准备阶段，你可以将任意张牌置于你的武将牌旁，称为'箜'，然后你可以选择一名其他角色，随机将其等量的牌置入'箜'。结束阶段，你从'箜'中选择X张牌交给其（X为其置入'箜'的牌数）。你的回合结束时，你获得所有的'箜'。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_kongsheng"])
    general:addSkill(runtime)
end

-- 曹叡 常规
do
    local general = sgs.General(extension, "nuyan_caorui", "wei", 4, true)
    translations["nuyan_caorui"] = "曹叡"
    translations["#nuyan_caorui"] = "怒焰·常规"
    if not skills["nuyan_huituo"] then register({id = "nuyan_huituo", mode = "huituo", classic = false, jie = false, label = "恢拓", text = "每当你受到伤害后，你可以令一名角色进行一次判定。若结果为：红色，其摸1张牌并回复X点体力；黑色，其摸X张牌并回复1点体力。（X为此次伤害的伤害值）", compulsory = false}) end
    general:addSkill(skills["nuyan_huituo"])
    general:addSkill(runtime)
end

-- 曹叡 经典
do
    local general = sgs.General(extension, "nuyan_jd_caorui", "wei", 4, true)
    translations["nuyan_jd_caorui"] = "曹叡"
    translations["#nuyan_jd_caorui"] = "怒焰·经典"
    if not skills["nuyan_jd_huituo"] then register({id = "nuyan_jd_huituo", mode = "huituo", classic = true, jie = false, label = "恢拓", text = "每当你受到伤害后，你可以令一名角色进行一次判定。若结果为：红色，其摸1张牌并回复X点体力；黑色，其摸X张牌并回复1点体力。（X为此次伤害的伤害值）", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_huituo"])
    general:addSkill(runtime)
end

-- 南华老仙 常规
do
    local general = sgs.General(extension, "nuyan_nanhualaoxian", "qun", 4, true)
    translations["nuyan_nanhualaoxian"] = "南华老仙"
    translations["#nuyan_nanhualaoxian"] = "怒焰·常规"
    if not skills["nuyan_tianshu"] then register({id = "nuyan_tianshu", mode = "tianshu", classic = false, jie = false, label = "天书", text = "你首次登场时，从以下'天书技能'中选择至多X个令任意角色获得之（X为你的星级数的一半+1，向上取整）：长生，阴兵，仙授，鬼咒。准备阶段或当你的体力值减少后，你可以令一名角色获得一个其未拥有的'天书技能'。", compulsory = false}) end
    general:addSkill(skills["nuyan_tianshu"])
    general:addSkill(runtime)
end

-- 南华老仙 经典
do
    local general = sgs.General(extension, "nuyan_jd_nanhualaoxian", "qun", 4, true)
    translations["nuyan_jd_nanhualaoxian"] = "南华老仙"
    translations["#nuyan_jd_nanhualaoxian"] = "怒焰·经典"
    if not skills["nuyan_jd_tianshu"] then register({id = "nuyan_jd_tianshu", mode = "tianshu", classic = true, jie = false, label = "天书", text = "你首次登场时，从以下'天书技能'中选择至多3个令任意角色获得之：长生，阴兵，仙授，鬼咒。准备阶段或当你的体力值减少后，你可以令一名角色获得一个其未拥有的'天书技能'。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_tianshu"])
    general:addSkill(runtime)
end

-- 乐进 常规
do
    local general = sgs.General(extension, "nuyan_yuejin", "wei", 4, true)
    translations["nuyan_yuejin"] = "乐进"
    translations["#nuyan_yuejin"] = "怒焰·常规"
    if not skills["nuyan_xiaoguo"] then register({id = "nuyan_xiaoguo", mode = "xiaoguo", classic = false, jie = false, label = "骁果", text = "其他角色的结束阶段，你可以至多弃置X张基本牌，然后该角色选择一项：1.受到你造成的弃置牌数量的伤害；2.弃置等量的牌。（X为你的星级）", compulsory = false}) end
    general:addSkill(skills["nuyan_xiaoguo"])
    general:addSkill(runtime)
end

-- 乐进 经典
do
    local general = sgs.General(extension, "nuyan_jd_yuejin", "wei", 4, true)
    translations["nuyan_jd_yuejin"] = "乐进"
    translations["#nuyan_jd_yuejin"] = "怒焰·经典"
    if not skills["nuyan_jd_xiaoguo"] then register({id = "nuyan_jd_xiaoguo", mode = "xiaoguo", classic = true, jie = false, label = "骁果", text = "其他角色的结束阶段，你可以至多弃置3张基本牌，然后该角色选择一项：1.受到你造成的弃置牌数量的伤害；2.弃置等量的牌。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_xiaoguo"])
    general:addSkill(runtime)
end

-- 刘琦 常规
do
    local general = sgs.General(extension, "nuyan_liuqi", "qun", 4, true)
    translations["nuyan_liuqi"] = "刘琦"
    translations["#nuyan_liuqi"] = "怒焰·常规"
    if not skills["nuyan_wenji"] then register({id = "nuyan_wenji", mode = "wenji", classic = false, jie = false, label = "问计", text = "出牌阶段每名其他角色限一次，你可以令一名其他角色交给你一张牌。你于本回合内使用或打出与通过此法获得的同类型的牌无次数限制。", compulsory = false}) end
    general:addSkill(skills["nuyan_wenji"])
    general:addSkill(runtime)
end

-- 刘琦 经典
do
    local general = sgs.General(extension, "nuyan_jd_liuqi", "qun", 4, true)
    translations["nuyan_jd_liuqi"] = "刘琦"
    translations["#nuyan_jd_liuqi"] = "怒焰·经典"
    if not skills["nuyan_jd_wenji"] then register({id = "nuyan_jd_wenji", mode = "wenji", classic = true, jie = false, label = "问计", text = "出牌阶段每名其他角色限一次，你可以令一名其他角色交给你一张牌。你于本回合内使用或打出与通过此法获得的同类型的牌无次数限制。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_wenji"])
    general:addSkill(runtime)
end

-- 吴懿 常规
do
    local general = sgs.General(extension, "nuyan_wuyi", "shu", 4, true)
    translations["nuyan_wuyi"] = "吴懿"
    translations["#nuyan_wuyi"] = "怒焰·常规"
    if not skills["nuyan_benxi"] then register({id = "nuyan_benxi", mode = "benxi", classic = false, jie = false, label = "奔袭", text = "锁定技，当你于回合内使用或打出牌时，本回合你计算与其他角色的距离-1。你使用仅指定一个目标的【杀】或非延时锦囊牌时，此牌无视其他角色的防具且可以额外指定一个目标，若你未额外指定目标，则你获得此牌的目标一张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_benxi"])
    general:addSkill(runtime)
end

-- 吴懿 经典
do
    local general = sgs.General(extension, "nuyan_jd_wuyi", "shu", 4, true)
    translations["nuyan_jd_wuyi"] = "吴懿"
    translations["#nuyan_jd_wuyi"] = "怒焰·经典"
    if not skills["nuyan_jd_benxi"] then register({id = "nuyan_jd_benxi", mode = "benxi", classic = true, jie = false, label = "奔袭", text = "锁定技，当你于回合内使用或打出牌时，本回合你计算与其他角色的距离-1。你使用仅指定一个目标的【杀】或非延时锦囊牌时，此牌无视其他角色的防具且可以额外指定一个目标，若你未额外指定目标，则你获得此牌的目标一张牌。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_benxi"])
    general:addSkill(runtime)
end

-- 骆统 常规
do
    local general = sgs.General(extension, "nuyan_luotong", "wu", 4, true)
    translations["nuyan_luotong"] = "骆统"
    translations["#nuyan_luotong"] = "怒焰·常规"
    if not skills["nuyan_qinzheng"] then register({id = "nuyan_qinzheng", mode = "qinzheng", classic = false, jie = false, label = "勤政", text = "锁定技，你每使用或打出：3张牌时，你从牌堆或弃牌堆随机获得一张【杀】或【闪】；5张牌时，你从牌堆或弃牌堆随机获得一张【桃】或【酒】；8张牌时，你从牌堆或弃牌堆随机获得一张【无中生有】。其他内容不变。", compulsory = true}) end
    general:addSkill(skills["nuyan_qinzheng"])
    general:addSkill(runtime)
end

-- 骆统 经典
do
    local general = sgs.General(extension, "nuyan_jd_luotong", "wu", 4, true)
    translations["nuyan_jd_luotong"] = "骆统"
    translations["#nuyan_jd_luotong"] = "怒焰·经典"
    if not skills["nuyan_jd_qinzheng"] then register({id = "nuyan_jd_qinzheng", mode = "qinzheng", classic = true, jie = false, label = "勤政", text = "锁定技，你每使用或打出：3张牌时，你从牌堆或弃牌堆随机获得一张【杀】或【闪】；5张牌时，你从牌堆或弃牌堆随机获得一张【桃】或【酒】；8张牌时，你从牌堆或弃牌堆随机获得一张【无中生有】。其他内容不变。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_qinzheng"])
    general:addSkill(runtime)
end

-- 孙寒华 常规
do
    local general = sgs.General(extension, "nuyan_sunhanhua", "wu", 4, true)
    translations["nuyan_sunhanhua"] = "孙寒华"
    translations["#nuyan_sunhanhua"] = "怒焰·常规"
    if not skills["nuyan_huiling"] then register({id = "nuyan_huiling", mode = "huiling", classic = false, jie = false, label = "汇灵", text = "锁定技，当弃牌堆中的：红色牌数量多于黑色牌数量时，你使用或打出牌时回复1点体力；黑色牌数量多于红色牌数量时，你使用或打出牌时获得1点怒气。你使用或打出牌结算结束后，若其颜色在弃牌堆中不为最多，你获得一个'灵'标记。你每获得3个'灵'，将'莲华熠熠'或'妙剑宣威'升至2级。", compulsory = true}) end
    general:addSkill(skills["nuyan_huiling"])
    general:addSkill(runtime)
end

-- 孙寒华 经典
do
    local general = sgs.General(extension, "nuyan_jd_sunhanhua", "wu", 4, true)
    translations["nuyan_jd_sunhanhua"] = "孙寒华"
    translations["#nuyan_jd_sunhanhua"] = "怒焰·经典"
    if not skills["nuyan_jd_huiling"] then register({id = "nuyan_jd_huiling", mode = "huiling", classic = true, jie = false, label = "汇灵", text = "锁定技，当弃牌堆中的：红色牌数量多于黑色牌数量时，你使用或打出牌时摸1张牌并回复1点体力；黑色牌数量多于红色牌数量时，你使用或打出牌时摸1张牌并获得1点怒气。", compulsory = true}) end
    general:addSkill(skills["nuyan_jd_huiling"])
    general:addSkill(runtime)
end

-- 花鬘 常规
do
    local general = sgs.General(extension, "nuyan_huaman", "shu", 4, true)
    translations["nuyan_huaman"] = "花鬘"
    translations["#nuyan_huaman"] = "怒焰·常规"
    if not skills["nuyan_xizhan"] then register({id = "nuyan_xizhan", mode = "xizhan", classic = false, jie = false, label = "嬉战", text = "你于你的回合内无法使用伤害牌。其他角色回合开始时，你可以弃置一张手牌并执行相应效果：黑桃，视为你强化使用一张【南蛮入侵】；红桃，你从牌堆获得三张不同花色的牌；梅花，你随机弃置其两张手牌；方块，视为你对其强化使用一张【杀】。", compulsory = false}) end
    general:addSkill(skills["nuyan_xizhan"])
    general:addSkill(runtime)
end

-- 花鬘 经典
do
    local general = sgs.General(extension, "nuyan_jd_huaman", "shu", 4, true)
    translations["nuyan_jd_huaman"] = "花鬘"
    translations["#nuyan_jd_huaman"] = "怒焰·经典"
    if not skills["nuyan_jd_xizhan"] then register({id = "nuyan_jd_xizhan", mode = "xizhan", classic = true, jie = false, label = "嬉战", text = "你于你的回合内无法使用伤害牌。其他角色回合开始时，你可以弃置一张手牌并执行相应效果：黑桃，视为你强化使用一张【南蛮入侵】；红桃，你从牌堆获得三张不同花色的牌；梅花，你随机弃置其两张手牌；方块，视为你对其强化使用一张【杀】。", compulsory = false}) end
    general:addSkill(skills["nuyan_jd_xizhan"])
    general:addSkill(runtime)
end

if not skills["nuyan_xinzhan"] then register({id = "nuyan_xinzhan", mode = "xinzhan", label = "心战", text = "当你对其他角色造成伤害时，你可以防止此伤害，然后获得其区域里的1张牌。"}) end
if not skills["nuyan_lianhua"] then register({id = "nuyan_lianhua", mode = "lianhua", label = "莲华", text = "一级=当你成为其他角色使用【杀】的目标时，你摸一张牌；二级=当你成为其他角色使用【杀】的目标时，你摸一张牌，然后除非该角色弃置一张牌，否则抵消此伤害；三级=当你成为其他角色使用【杀】的目标时，你摸一张牌，然后进行一次判定，若判定结果为黑色，则抵消此伤害。"}) end
if not skills["nuyan_miaojian"] then register({id = "nuyan_miaojian", mode = "miaojian", label = "妙剑", text = "一级=出牌阶段限X次（X为你的武将星级），你可以将一张基本牌当【杀】普通使用（不计入次数限制），或者将一张非基本牌当【水淹七军】普通使用；二级=出牌阶段限X次（X为你的武将星级），你可以将一张基本牌当【杀】强化使用（不计入次数限制），或者将一张非基本牌当【水淹七军】强化使用；三级=你可以移除一个'灵'，视为强化使用一张无距离限制的【杀】（不计入次数限制），或者视为强化使用一张【水淹七军】。"}) end
register({id = "nuyan_ts_changsheng", mode = "ts_changsheng", label = "长生", text = "一级=锁定技，每轮限一次，你进入濒死状态时，回复体力至1点；二级=锁定技，每回合限一次，你进入濒死状态时，回复体力至2点。", compulsory = true})
register({id = "nuyan_ts_yinbing", mode = "ts_yinbing", label = "阴兵", text = "一级=锁定技，你造成伤害时，此伤害-1；二级=锁定技，你造成伤害时，此伤害-1且你失去1点怒气。", compulsory = true})
register({id = "nuyan_ts_xianshou", mode = "ts_xianshou", label = "仙授", text = "一级=锁定技，你每非因此效果获得四张牌，你便摸一张牌；二级=锁定技，你每非因此效果获得三张牌，你便摸一张牌。", compulsory = true})
register({id = "nuyan_ts_guizhou", mode = "ts_guizhou", label = "鬼咒", text = "一级=锁定技，你每非因此效果失去四张牌，你便随机弃置一张牌；二级=锁定技，你每非因此效果失去三张牌，你便随机弃置一张牌。", compulsory = true})
register({id = "nuyan_ts_leifa_book", mode = "ts_leifa_book", label = "雷法", text = "一级=锁定技，你使用或打出方块牌后，对一名其他角色造成1点闪电伤害；二级=锁定技，你使用或打出方块牌后，对一名其他角色造成1点体力流失。", compulsory = true})
register({id = "nuyan_ts_shouyi", mode = "ts_shouyi", label = "守一", text = "一级=锁定技，出牌阶段开始时与出牌阶段结束时，你受到1点闪电伤害；二级=锁定技，出牌阶段开始时与出牌阶段结束时，你流失1点体力。", compulsory = true})
register({id = "nuyan_ts_fue", mode = "ts_fue", label = "负恶", text = "一级=锁定技，你受到的闪电伤害+1；二级=锁定技，你受到的闪电伤害和体力流失效果+1。", compulsory = true})
register({id = "nuyan_ts_chengshan", mode = "ts_chengshan", label = "承善", text = "一级=你造成的伤害视为闪电伤害；二级=你造成的伤害视为体力流失。", compulsory = true})
register({id = "nuyan_bond_dianwei_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_qiangxi", "nuyan_bond_dianwei_2")
extension:insertRelatedSkills("nuyan_jd_qiangxi", "nuyan_bond_dianwei_2")
register({id = "nuyan_bond_yuanshao_1", mode = "bond_immune", label = "毫发无伤", text = "锁定技，在游戏中你免疫【万箭齐发】的伤害。", compulsory = true, card_kind = "ArcheryAttack"})
extension:insertRelatedSkills("nuyan_luanji", "nuyan_bond_yuanshao_1")
extension:insertRelatedSkills("nuyan_jd_luanji", "nuyan_bond_yuanshao_1")
register({id = "nuyan_bond_yuanshao_2", mode = "bond_initial_hp", label = "体力大师", text = "锁定技，你的初始体力和体力上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_luanji", "nuyan_bond_yuanshao_2")
extension:insertRelatedSkills("nuyan_jd_luanji", "nuyan_bond_yuanshao_2")
register({id = "nuyan_bond_guojia_1", mode = "bond_judge", label = "魏之奇佐", text = "锁定技，当你的判定牌生效后，你获得此判定牌，并获得1点怒气。", compulsory = true, extra_rage = true})
extension:insertRelatedSkills("nuyan_yiji", "nuyan_bond_guojia_1")
extension:insertRelatedSkills("nuyan_jd_yiji", "nuyan_bond_guojia_1")
register({id = "nuyan_bond_guojia_3", mode = "bond_hplost_draw", label = "智策奇佐", text = "锁定技，当你受到体力流失时，摸1张牌。", compulsory = true})
extension:insertRelatedSkills("nuyan_yiji", "nuyan_bond_guojia_3")
extension:insertRelatedSkills("nuyan_jd_yiji", "nuyan_bond_guojia_3")
register({id = "nuyan_bond_xiahouyuan_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_shensu", "nuyan_bond_xiahouyuan_2")
extension:insertRelatedSkills("nuyan_jd_shensu", "nuyan_bond_xiahouyuan_2")
register({id = "nuyan_bond_xiahouyuan_3", mode = "bond_slash_rage", label = "风驰电掣", text = "锁定技，你的【杀】造成伤害后，你获得1点怒气。", compulsory = true})
extension:insertRelatedSkills("nuyan_shensu", "nuyan_bond_xiahouyuan_3")
extension:insertRelatedSkills("nuyan_jd_shensu", "nuyan_bond_xiahouyuan_3")
register({id = "nuyan_bond_caozhi_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_jiushi", "nuyan_bond_caozhi_2")
extension:insertRelatedSkills("nuyan_jd_jiushi", "nuyan_bond_caozhi_2")
register({id = "nuyan_bond_huangzhong_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_liegong", "nuyan_bond_huangzhong_2")
extension:insertRelatedSkills("nuyan_jie_liegong", "nuyan_bond_huangzhong_2")
extension:insertRelatedSkills("nuyan_jd_liegong", "nuyan_bond_huangzhong_2")
extension:insertRelatedSkills("nuyan_jd_jie_liegong", "nuyan_bond_huangzhong_2")
register({id = "nuyan_bond_zhangfei_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_paoxiao", "nuyan_bond_zhangfei_2")
extension:insertRelatedSkills("nuyan_jie_paoxiao", "nuyan_bond_zhangfei_2")
extension:insertRelatedSkills("nuyan_jd_paoxiao", "nuyan_bond_zhangfei_2")
extension:insertRelatedSkills("nuyan_jd_jie_paoxiao", "nuyan_bond_zhangfei_2")
register({id = "nuyan_bond_weiyan_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_kuanggu", "nuyan_bond_weiyan_2")
extension:insertRelatedSkills("nuyan_jd_kuanggu", "nuyan_bond_weiyan_2")
register({id = "nuyan_bond_liushan_2", mode = "bond_initial_rage", label = "初始产怒", text = "初始怒气+1。", compulsory = false})
extension:insertRelatedSkills("nuyan_xiangle", "nuyan_bond_liushan_2")
extension:insertRelatedSkills("nuyan_jie_xiangle", "nuyan_bond_liushan_2")
extension:insertRelatedSkills("nuyan_jd_xiangle", "nuyan_bond_liushan_2")
extension:insertRelatedSkills("nuyan_jd_jie_xiangle", "nuyan_bond_liushan_2")
register({id = "nuyan_bond_xiaoqiao_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_tianxiang", "nuyan_bond_xiaoqiao_2")
extension:insertRelatedSkills("nuyan_jd_tianxiang", "nuyan_bond_xiaoqiao_2")
register({id = "nuyan_bond_lvmeng_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_gongxin", "nuyan_bond_lvmeng_2")
extension:insertRelatedSkills("nuyan_jd_gongxin", "nuyan_bond_lvmeng_2")
register({id = "nuyan_bond_dongzhuo_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_baoli", "nuyan_bond_dongzhuo_2")
extension:insertRelatedSkills("nuyan_jd_baoli", "nuyan_bond_dongzhuo_2")
register({id = "nuyan_bond_dongzhuo_3", mode = "bond_gender", label = "酒池肉林", text = "锁定技，你对女性角色造成伤害后回复1点体力，女性角色对你使用【杀】造成的伤害-1。", compulsory = true})
extension:insertRelatedSkills("nuyan_baoli", "nuyan_bond_dongzhuo_3")
extension:insertRelatedSkills("nuyan_jd_baoli", "nuyan_bond_dongzhuo_3")
register({id = "nuyan_bond_yanliang_3", mode = "bond_discard_all", label = "勇冠三军", text = "出牌阶段开始时，你可以令所有其他角色各弃置1张牌。", compulsory = false})
extension:insertRelatedSkills("nuyan_langxing", "nuyan_bond_yanliang_3")
extension:insertRelatedSkills("nuyan_jd_langxing", "nuyan_bond_yanliang_3")
register({id = "nuyan_bond_simayi_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_fankui", "nuyan_bond_simayi_2")
extension:insertRelatedSkills("nuyan_jd_fankui", "nuyan_bond_simayi_2")
register({id = "nuyan_bond_xunyu_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_quhu", "nuyan_bond_xunyu_2")
extension:insertRelatedSkills("nuyan_jd_quhu", "nuyan_bond_xunyu_2")
register({id = "nuyan_bond_xunyou_1", mode = "bond_colour_draw", label = "妙计百出", text = "锁定技，回合结束时，若你手牌颜色均相同，则你摸2张牌。", compulsory = true})
extension:insertRelatedSkills("nuyan_qice", "nuyan_bond_xunyou_1")
extension:insertRelatedSkills("nuyan_jie_qice", "nuyan_bond_xunyou_1")
extension:insertRelatedSkills("nuyan_jd_qice", "nuyan_bond_xunyou_1")
extension:insertRelatedSkills("nuyan_jd_jie_qice", "nuyan_bond_xunyou_1")
register({id = "nuyan_bond_liubei_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_renwang", "nuyan_bond_liubei_2")
extension:insertRelatedSkills("nuyan_jd_renwang", "nuyan_bond_liubei_2")
register({id = "nuyan_bond_huangyueying_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_jizhi", "nuyan_bond_huangyueying_2")
extension:insertRelatedSkills("nuyan_jie_jizhi", "nuyan_bond_huangyueying_2")
extension:insertRelatedSkills("nuyan_jd_jizhi", "nuyan_bond_huangyueying_2")
extension:insertRelatedSkills("nuyan_jd_jie_jizhi", "nuyan_bond_huangyueying_2")
register({id = "nuyan_bond_jiangwei_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_jizhen", "nuyan_bond_jiangwei_2")
extension:insertRelatedSkills("nuyan_jd_jizhen", "nuyan_bond_jiangwei_2")
register({id = "nuyan_bond_mayunlu_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_fengpo", "nuyan_bond_mayunlu_2")
extension:insertRelatedSkills("nuyan_jd_fengpo", "nuyan_bond_mayunlu_2")
register({id = "nuyan_bond_pangtong_1", mode = "bond_death_heal", label = "入川献计", text = "锁定技，当其他玩家的武将阵亡时，若你已受伤，你回复1点体力。", compulsory = true})
extension:insertRelatedSkills("nuyan_zhanji", "nuyan_bond_pangtong_1")
extension:insertRelatedSkills("nuyan_jd_zhanji", "nuyan_bond_pangtong_1")
register({id = "nuyan_bond_pangtong_3", mode = "bond_niepan", label = "涅槃重生", text = "限定技，当你进入濒死时，你失去所有手牌和怒气，体力回复至X，然后摸X张牌（回复体力不超过体力上限，X为你的星级）。", compulsory = false})
extension:insertRelatedSkills("nuyan_zhanji", "nuyan_bond_pangtong_3")
extension:insertRelatedSkills("nuyan_jd_zhanji", "nuyan_bond_pangtong_3")
register({id = "nuyan_bond_xushu_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_zhuhai", "nuyan_bond_xushu_2")
extension:insertRelatedSkills("nuyan_jd_zhuhai", "nuyan_bond_xushu_2")
register({id = "nuyan_bond_liaohua_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_dangxian", "nuyan_bond_liaohua_2")
extension:insertRelatedSkills("nuyan_jd_dangxian", "nuyan_bond_liaohua_2")
register({id = "nuyan_bond_sunquan_3", mode = "bond_end_attack", label = "东吴大帝", text = "出牌阶段结束时，你可以对一名手牌数比你少的其他角色造成1点伤害。", compulsory = false})
extension:insertRelatedSkills("nuyan_zhiheng", "nuyan_bond_sunquan_3")
extension:insertRelatedSkills("nuyan_jie_zhiheng", "nuyan_bond_sunquan_3")
extension:insertRelatedSkills("nuyan_jd_zhiheng", "nuyan_bond_sunquan_3")
extension:insertRelatedSkills("nuyan_jd_jie_zhiheng", "nuyan_bond_sunquan_3")
register({id = "nuyan_bond_lingcao_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_dujin", "nuyan_bond_lingcao_2")
extension:insertRelatedSkills("nuyan_jd_dujin", "nuyan_bond_lingcao_2")
register({id = "nuyan_bond_sunjian_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_yinghun", "nuyan_bond_sunjian_2")
extension:insertRelatedSkills("nuyan_jd_yinghun", "nuyan_bond_sunjian_2")
register({id = "nuyan_bond_zhoutai_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_fenji", "nuyan_bond_zhoutai_2")
extension:insertRelatedSkills("nuyan_jd_fenji", "nuyan_bond_zhoutai_2")
register({id = "nuyan_bond_zhugeke_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_duwu", "nuyan_bond_zhugeke_2")
extension:insertRelatedSkills("nuyan_jie_duwu", "nuyan_bond_zhugeke_2")
extension:insertRelatedSkills("nuyan_jd_duwu", "nuyan_bond_zhugeke_2")
extension:insertRelatedSkills("nuyan_jd_jie_duwu", "nuyan_bond_zhugeke_2")
register({id = "nuyan_bond_diaochan_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_lihun", "nuyan_bond_diaochan_2")
extension:insertRelatedSkills("nuyan_jd_lihun", "nuyan_bond_diaochan_2")
register({id = "nuyan_bond_zhangjiao_1", mode = "bond_thunder_immune", label = "悬壶济世", text = "锁定技，你免疫【闪电】的伤害，当有【闪电】在一名角色的判定区时，你的【杀】对其伤害+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_leifa", "nuyan_bond_zhangjiao_1")
extension:insertRelatedSkills("nuyan_jie_leifa", "nuyan_bond_zhangjiao_1")
extension:insertRelatedSkills("nuyan_jd_leifa", "nuyan_bond_zhangjiao_1")
extension:insertRelatedSkills("nuyan_jd_jie_leifa", "nuyan_bond_zhangjiao_1")
register({id = "nuyan_bond_zhangjiao_3", mode = "bond_lightning_get", label = "驱雷策电", text = "锁定技，当【闪电】进入弃牌堆时，你获得之。", compulsory = true})
extension:insertRelatedSkills("nuyan_leifa", "nuyan_bond_zhangjiao_3")
extension:insertRelatedSkills("nuyan_jie_leifa", "nuyan_bond_zhangjiao_3")
extension:insertRelatedSkills("nuyan_jd_leifa", "nuyan_bond_zhangjiao_3")
extension:insertRelatedSkills("nuyan_jd_jie_leifa", "nuyan_bond_zhangjiao_3")
register({id = "nuyan_bond_zhurong_1", mode = "bond_immune", label = "南蛮豪杰", text = "锁定技，你在游戏中免疫【南蛮入侵】的伤害。", compulsory = true, card_kind = "SavageAssault"})
extension:insertRelatedSkills("nuyan_lieren", "nuyan_bond_zhurong_1")
extension:insertRelatedSkills("nuyan_jie_lieren", "nuyan_bond_zhurong_1")
extension:insertRelatedSkills("nuyan_jd_lieren", "nuyan_bond_zhurong_1")
extension:insertRelatedSkills("nuyan_jd_jie_lieren", "nuyan_bond_zhurong_1")
register({id = "nuyan_bond_zhurong_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_lieren", "nuyan_bond_zhurong_2")
extension:insertRelatedSkills("nuyan_jie_lieren", "nuyan_bond_zhurong_2")
extension:insertRelatedSkills("nuyan_jd_lieren", "nuyan_bond_zhurong_2")
extension:insertRelatedSkills("nuyan_jd_jie_lieren", "nuyan_bond_zhurong_2")
register({id = "nuyan_bond_menghuo_1", mode = "bond_immune", label = "南蛮首领", text = "锁定技，你在游戏中免疫【南蛮入侵】的伤害。", compulsory = true, card_kind = "SavageAssault"})
extension:insertRelatedSkills("nuyan_manyi", "nuyan_bond_menghuo_1")
extension:insertRelatedSkills("nuyan_jd_manyi", "nuyan_bond_menghuo_1")
register({id = "nuyan_bond_menghuo_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_manyi", "nuyan_bond_menghuo_2")
extension:insertRelatedSkills("nuyan_jd_manyi", "nuyan_bond_menghuo_2")
register({id = "nuyan_bond_huatuo_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_jijiu", "nuyan_bond_huatuo_2")
extension:insertRelatedSkills("nuyan_jd_jijiu", "nuyan_bond_huatuo_2")
register({id = "nuyan_bond_chengong_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_zhichi", "nuyan_bond_chengong_2")
extension:insertRelatedSkills("nuyan_jd_zhichi", "nuyan_bond_chengong_2")
register({id = "nuyan_bond_caifuren_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_xianzhou", "nuyan_bond_caifuren_2")
extension:insertRelatedSkills("nuyan_jd_xianzhou", "nuyan_bond_caifuren_2")
register({id = "nuyan_bond_yuanshu_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_yongsi", "nuyan_bond_yuanshu_2")
extension:insertRelatedSkills("nuyan_jd_yongsi", "nuyan_bond_yuanshu_2")
register({id = "nuyan_bond_jushou_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_jianying", "nuyan_bond_jushou_2")
extension:insertRelatedSkills("nuyan_jd_jianying", "nuyan_bond_jushou_2")
register({id = "nuyan_bond_zhenji_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_luoshen", "nuyan_bond_zhenji_2")
extension:insertRelatedSkills("nuyan_jd_luoshen", "nuyan_bond_zhenji_2")
register({id = "nuyan_bond_caopi_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_fangzhu", "nuyan_bond_caopi_2")
extension:insertRelatedSkills("nuyan_jd_fangzhu", "nuyan_bond_caopi_2")
register({id = "nuyan_bond_xinxianying_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_zhongjian", "nuyan_bond_xinxianying_2")
extension:insertRelatedSkills("nuyan_jd_zhongjian", "nuyan_bond_xinxianying_2")
register({id = "nuyan_bond_xizhicai_1", mode = "bond_judge", label = "逸志俊才", text = "锁定技，当你的判定牌生效后，你获得此牌。", compulsory = true})
extension:insertRelatedSkills("nuyan_chouce", "nuyan_bond_xizhicai_1")
extension:insertRelatedSkills("nuyan_jd_chouce", "nuyan_bond_xizhicai_1")
register({id = "nuyan_bond_xizhicai_3", mode = "bond_xianfu", label = "先辅契约", text = "游戏开始时，你选择一名其他角色，当其受到伤害后，你受到1点伤害；当其不因'先辅契约'回复体力后，你回复等量体力；当你不因'先辅契约'回复体力后，你可以令其回复1点体力。", compulsory = false})
extension:insertRelatedSkills("nuyan_chouce", "nuyan_bond_xizhicai_3")
extension:insertRelatedSkills("nuyan_jd_chouce", "nuyan_bond_xizhicai_3")
register({id = "nuyan_bond_zhaoyun_1", mode = "bond_qijin", label = "七进七出", text = "锁定技，当你于回合外使用或打出手牌时，你摸1张牌。", compulsory = true})
extension:insertRelatedSkills("nuyan_juejing", "nuyan_bond_zhaoyun_1")
extension:insertRelatedSkills("nuyan_jd_juejing", "nuyan_bond_zhaoyun_1")
register({id = "nuyan_bond_zhaoyun_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_juejing", "nuyan_bond_zhaoyun_2")
extension:insertRelatedSkills("nuyan_jd_juejing", "nuyan_bond_zhaoyun_2")
register({id = "nuyan_bond_sunce_3", mode = "bond_card_slash_draw", label = "吴国栋梁", text = "锁定技，当你使用或打出【杀】，或者当你成为【杀】的目标时，你摸1张牌。", compulsory = true})
extension:insertRelatedSkills("nuyan_jiangang", "nuyan_bond_sunce_3")
extension:insertRelatedSkills("nuyan_jd_jiangang", "nuyan_bond_sunce_3")
register({id = "nuyan_bond_bulianshi_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_anxu", "nuyan_bond_bulianshi_2")
extension:insertRelatedSkills("nuyan_jd_anxu", "nuyan_bond_bulianshi_2")
register({id = "nuyan_bond_taishici_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_dulie", "nuyan_bond_taishici_2")
extension:insertRelatedSkills("nuyan_jd_dulie", "nuyan_bond_taishici_2")
register({id = "nuyan_bond_sunhao_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_canshi", "nuyan_bond_sunhao_2")
extension:insertRelatedSkills("nuyan_jd_canshi", "nuyan_bond_sunhao_2")
register({id = "nuyan_bond_lvbu_2", mode = "bond_initial_rage", label = "初始产怒", text = "锁定技，初始怒气+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_shenwei", "nuyan_bond_lvbu_2")
extension:insertRelatedSkills("nuyan_jd_shenwei", "nuyan_bond_lvbu_2")
register({id = "nuyan_bond_caiwenji_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_beige", "nuyan_bond_caiwenji_2")
extension:insertRelatedSkills("nuyan_jd_beige", "nuyan_bond_caiwenji_2")
register({id = "nuyan_bond_jiaxu_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_luanwu", "nuyan_bond_jiaxu_2")
extension:insertRelatedSkills("nuyan_jd_luanwu", "nuyan_bond_jiaxu_2")
register({id = "nuyan_bond_yuji_2", mode = "bond_hand", label = "手牌大师", text = "锁定技，手牌上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_guhuo", "nuyan_bond_yuji_2")
extension:insertRelatedSkills("nuyan_jd_guhuo", "nuyan_bond_yuji_2")
register({id = "nuyan_bond_yuji_3", mode = "bond_dying_heal", label = "幻惑众心", text = "限定技，当你进入濒死时，你将体力回复至3点。", compulsory = false})
extension:insertRelatedSkills("nuyan_guhuo", "nuyan_bond_yuji_3")
extension:insertRelatedSkills("nuyan_jd_guhuo", "nuyan_bond_yuji_3")
register({id = "nuyan_bond_liuqi_2", mode = "bond_initial_hp", label = "坚韧不拔", text = "锁定技，初始体力和体力上限+1。", compulsory = true})
extension:insertRelatedSkills("nuyan_wenji", "nuyan_bond_liuqi_2")
extension:insertRelatedSkills("nuyan_jd_wenji", "nuyan_bond_liuqi_2")
register({id = "nuyan_daitianxuanhua", mode = "bond_hand_dummy", label = "代天宣化", text = "你的'天书'中额外拥有以下的'天书技能'：雷法。一名角色获得或升级'天书技能'时，你获得1点怒气。"})
extension:insertRelatedSkills("nuyan_tianshu","nuyan_daitianxuanhua")
extension:insertRelatedSkills("nuyan_jd_tianshu","nuyan_daitianxuanhua")
register({id = "nuyan_fengxuyufeng", mode = "bond_hand_dummy", label = "冯虚御风", text = "你的'天书'中额外拥有以下的'天书技能'：守一，负恶，承善。一名角色获得或升级'天书技能'时，你摸一张牌。"})
extension:insertRelatedSkills("nuyan_tianshu","nuyan_fengxuyufeng")
extension:insertRelatedSkills("nuyan_jd_tianshu","nuyan_fengxuyufeng")
register({id = "nuyan_bond_xiahoudun_1", mode = "bond_repeat_slash", label = "决不后退", text = "当你使用的【杀】被目标角色使用的【闪】全部抵消时，你可以对其继续使用【杀】，直到造成伤害（无距离限制）。", compulsory = false})
extension:insertRelatedSkills("nuyan_ganglie", "nuyan_bond_xiahoudun_1")
extension:insertRelatedSkills("nuyan_jd_ganglie", "nuyan_bond_xiahoudun_1")
register({id = "nuyan_bond_fazheng_1", mode = "bond_heart_give", label = "益州奇谋", text = "限定技，当你受到其他角色造成的伤害后，你令其选择一项：1.将1张方块手牌交给你；2.失去1点体力。", compulsory = false, limited = true})
extension:insertRelatedSkills("nuyan_xuanhuo", "nuyan_bond_fazheng_1")
extension:insertRelatedSkills("nuyan_jd_xuanhuo", "nuyan_bond_fazheng_1")
register({id = "nuyan_bond_fazheng_3", mode = "bond_heart_give", label = "股肱谋臣", text = "锁定技，当你受到其他角色造成的伤害后，你令其选择一项：1.将1张方块手牌交给你；2.失去1点体力。", compulsory = true})
extension:insertRelatedSkills("nuyan_xuanhuo", "nuyan_bond_fazheng_3")
extension:insertRelatedSkills("nuyan_jd_xuanhuo", "nuyan_bond_fazheng_3")
register({id = "nuyan_bond_dengai_3", mode = "bond_red_judge", label = "远见卓识", text = "当你于回合外失去牌后，你可以进行判定，若为红桃，则你获得此判定牌。", compulsory = false})
extension:insertRelatedSkills("nuyan_jixi", "nuyan_bond_dengai_3")
extension:insertRelatedSkills("nuyan_jd_jixi", "nuyan_bond_dengai_3")
register({id = "nuyan_bond_caozhi_1", mode = "bond_return_clubs", label = "落英缤纷", text = "限定技，当其他角色的梅花牌因弃置或判定而置入弃牌堆后，你可以获得这些牌。", compulsory = false, limited = true})
extension:insertRelatedSkills("nuyan_jiushi", "nuyan_bond_caozhi_1")
extension:insertRelatedSkills("nuyan_jd_jiushi", "nuyan_bond_caozhi_1")
register({id = "nuyan_bond_caozhi_3", mode = "bond_return_clubs", label = "八斗之才", text = "当其他角色的梅花牌因弃置或判定而置入弃牌堆后，你可以获得这些牌。", compulsory = false})
extension:insertRelatedSkills("nuyan_jiushi", "nuyan_bond_caozhi_3")
extension:insertRelatedSkills("nuyan_jd_jiushi", "nuyan_bond_caozhi_3")
register({id = "nuyan_bond_liushan_1", mode = "bond_indulgence", label = "尽享安乐", text = "锁定技，游戏中你不能成为【乐不思蜀】的目标。", compulsory = true})
extension:insertRelatedSkills("nuyan_xiangle", "nuyan_bond_liushan_1")
extension:insertRelatedSkills("nuyan_jd_xiangle", "nuyan_bond_liushan_1")
register({id = "nuyan_bond_dongzhuo_1", mode = "bond_gender_maxhp", label = "筋骨惊奇", text = "锁定技，场上其他角色的每名女性武将都会令你提升1点体力上限。", compulsory = true})
extension:insertRelatedSkills("nuyan_baoli", "nuyan_bond_dongzhuo_1")
extension:insertRelatedSkills("nuyan_jd_baoli", "nuyan_bond_dongzhuo_1")
register({id = "nuyan_bond_caocao_1", mode = "bond_first_damage_draw", label = "乱世奸雄", text = "限定技，当你首次受到伤害后，你摸1张牌。", compulsory = false, limited = true})
extension:insertRelatedSkills("nuyan_jianxiong", "nuyan_bond_caocao_1")
extension:insertRelatedSkills("nuyan_jd_jianxiong", "nuyan_bond_caocao_1")
register({id = "nuyan_bond_yujin_1", mode = "bond_shield_nuqi", label = "临危不惧", text = "当你受到伤害时，你可以失去1点怒气，然后令此伤害-1。", compulsory = false})
extension:insertRelatedSkills("nuyan_zhenjun", "nuyan_bond_yujin_1")
extension:insertRelatedSkills("nuyan_jd_zhenjun", "nuyan_bond_yujin_1")
register({id = "nuyan_bond_liubei_1", mode = "bond_weapon_gender", label = "桃园三杰", text = "限定技，若你装备了武器，当你的【杀】首次指定女性角色为目标后，令对方选择一项：1.弃置1张牌；2.令你摸1张牌。", compulsory = false, limited = true})
extension:insertRelatedSkills("nuyan_renwang", "nuyan_bond_liubei_1")
extension:insertRelatedSkills("nuyan_jd_renwang", "nuyan_bond_liubei_1")
register({id = "nuyan_bond_jiangwei_1", mode = "bond_dying_maxhp", label = "蜀汉再起", text = "限定技，当你首次进入濒死状态时，你减少1点体力上限并将体力回复至3点。", compulsory = false, limited = true})
extension:insertRelatedSkills("nuyan_jizhen", "nuyan_bond_jiangwei_1")
extension:insertRelatedSkills("nuyan_jd_jizhen", "nuyan_bond_jiangwei_1")
register({id = "nuyan_bond_xushu_1", mode = "bond_initial_extra_draw", label = "折节学问", text = "限定技，你的首个摸牌阶段，多摸1张牌。", compulsory = false, limited = true})
extension:insertRelatedSkills("nuyan_zhuhai", "nuyan_bond_xushu_1")
extension:insertRelatedSkills("nuyan_jd_zhuhai", "nuyan_bond_xushu_1")
register({id = "nuyan_bond_sunshangxiang_3", mode = "bond_recover_draw", label = "广结良缘", text = "当一名角色于其出牌阶段回复体力时，你可以选择一项：1.令该角色摸2张牌；2.你摸1张牌。", compulsory = false})
extension:insertRelatedSkills("nuyan_xiaoji", "nuyan_bond_sunshangxiang_3")
extension:insertRelatedSkills("nuyan_jd_xiaoji", "nuyan_bond_sunshangxiang_3")
register({id = "nuyan_bond_diaochan_1", mode = "bond_end_empty_draw", label = "妙计连环", text = "限定技，结束阶段，你可以摸1张牌，若你没有手牌，则改为摸2张牌。", compulsory = false, limited = true})
extension:insertRelatedSkills("nuyan_lihun", "nuyan_bond_diaochan_1")
extension:insertRelatedSkills("nuyan_jd_lihun", "nuyan_bond_diaochan_1")
register({id = "nuyan_bond_liuxie_1", mode = "bond_first_turn_draw", label = "落困天子", text = "限定技，你的首个回合结束时，你摸2张牌。", compulsory = false, limited = true})
extension:insertRelatedSkills("nuyan_tianming", "nuyan_bond_liuxie_1")
extension:insertRelatedSkills("nuyan_jd_tianming", "nuyan_bond_liuxie_1")
register({id = "nuyan_bond_gongsunzan_3", mode = "bond_lost_rage", label = "白马将军", text = "锁定技，你受到体力流失时，获得等量的怒气。", compulsory = true})
extension:insertRelatedSkills("nuyan_yicong", "nuyan_bond_gongsunzan_3")
extension:insertRelatedSkills("nuyan_jd_yicong", "nuyan_bond_gongsunzan_3")
register({id = "nuyan_bond_gaoshun_1", mode = "bond_no_analeptic", label = "骁勇忠烈", text = "锁定技，你的回合内，其他角色无法使用【酒】。", compulsory = true})
extension:insertRelatedSkills("nuyan_xianzhen", "nuyan_bond_gaoshun_1")
extension:insertRelatedSkills("nuyan_jd_xianzhen", "nuyan_bond_gaoshun_1")
register({id = "nuyan_bond_jushou_3", mode = "bond_damage_colours", label = "鸿鹄志哉", text = "回合结束时，你可以选择一名其他角色随机获得其X张手牌（X为你手牌中颜色数）。", compulsory = false})
extension:insertRelatedSkills("nuyan_jianying", "nuyan_bond_jushou_3")
extension:insertRelatedSkills("nuyan_jd_jianying", "nuyan_bond_jushou_3")
register({id = "nuyan_bond_zhenji_3", mode = "bond_end_thunder", label = "腹有诗书", text = "出牌阶段结束时，若你的手牌数量为奇数，你选择一名其他角色受到1点闪电伤害；若你的手牌数量为偶数，你可以弃置一名其他角色1张手牌。", compulsory = false})
extension:insertRelatedSkills("nuyan_luoshen", "nuyan_bond_zhenji_3")
extension:insertRelatedSkills("nuyan_jd_luoshen", "nuyan_bond_zhenji_3")
register({id = "nuyan_bond_caopi_1", mode = "bond_first_damage_one", label = "后顾之忧", text = "限定技，你首次受到的伤害锁定为1点。", compulsory = false, limited = true})
extension:insertRelatedSkills("nuyan_fangzhu", "nuyan_bond_caopi_1")
extension:insertRelatedSkills("nuyan_jd_fangzhu", "nuyan_bond_caopi_1")
register({id = "nuyan_bond_xinxianying_1", mode = "bond_prepare_random", label = "未雨绸缪", text = "锁定技，摸牌阶段开始时，你随机选择一项：1.多摸1张牌；2.获得1点怒气。", compulsory = true})
extension:insertRelatedSkills("nuyan_zhongjian", "nuyan_bond_xinxianying_1")
extension:insertRelatedSkills("nuyan_jd_zhongjian", "nuyan_bond_xinxianying_1")
register({id = "nuyan_bond_zhaoyun_3", mode = "wuhushangjiang", label = "五虎上将", text = "你可以将2张同花色的牌按以下规则使用或打出：红桃当【桃】；方块当【杀】；梅花当【闪】；黑桃当【看破】。若你以此法使用了2张红色牌，则你获得1点怒气；若你以此法使用了2张黑色牌，则你弃置一名其他角色的1张牌。", compulsory = false})
extension:insertRelatedSkills("nuyan_juejing", "nuyan_bond_zhaoyun_3")
extension:insertRelatedSkills("nuyan_jd_juejing", "nuyan_bond_zhaoyun_3")
register({id = "nuyan_bond_zhaoxiang_1", mode = "jinghongmeiying", label = "惊鸿魅影", text = "你可以将1张【杀】当【闪】、1张【闪】当【杀】使用或打出。", compulsory = false})
extension:insertRelatedSkills("nuyan_fanghun", "nuyan_bond_zhaoxiang_1")
extension:insertRelatedSkills("nuyan_jd_fanghun", "nuyan_bond_zhaoxiang_1")
register({id = "nuyan_bond_sunce_1", mode = "bond_first_slash_duel", label = "江东双绝", text = "限定技，你首次受到【决斗】或【杀】的伤害后，你获得此牌。", compulsory = false, limited = true})
extension:insertRelatedSkills("nuyan_jiangang", "nuyan_bond_sunce_1")
extension:insertRelatedSkills("nuyan_jd_jiangang", "nuyan_bond_sunce_1")
register({id = "nuyan_bond_taishici_1", mode = "bond_no_self_peach", label = "江东重臣", text = "锁定技，你的回合内，处于濒死状态的其他角色无法使用【桃】回复体力。", compulsory = true})
extension:insertRelatedSkills("nuyan_dulie", "nuyan_bond_taishici_1")
extension:insertRelatedSkills("nuyan_jd_dulie", "nuyan_bond_taishici_1")
register({id = "nuyan_bond_sunhao_1", mode = "bond_double_rage", label = "吴主之威", text = "锁定技，当你受到伤害时，你获得双倍怒气。", compulsory = true})
extension:insertRelatedSkills("nuyan_canshi", "nuyan_bond_sunhao_1")
extension:insertRelatedSkills("nuyan_jd_canshi", "nuyan_bond_sunhao_1")
register({id = "nuyan_bond_caiwenji_1", mode = "bond_last_hand", label = "才华横溢", text = "限定技，你首次失去最后1张手牌后，你摸2张牌。", compulsory = false, limited = true})
extension:insertRelatedSkills("nuyan_beige", "nuyan_bond_caiwenji_1")
extension:insertRelatedSkills("nuyan_jd_beige", "nuyan_bond_caiwenji_1")
register({id = "nuyan_bond_liru_3", mode = "bond_end_destroy", label = "绝世之策", text = "结束阶段，你可以对本回合失去过牌的其他角色均造成1点伤害。", compulsory = false})
extension:insertRelatedSkills("nuyan_fencheng", "nuyan_bond_liru_3")
extension:insertRelatedSkills("nuyan_jd_fencheng", "nuyan_bond_liru_3")
register({id = "nuyan_bond_lingju_1", mode = "bond_fenxin_gender", label = "蒹葭之思", text = "锁定技，当你发动'焚心'时，若目标为女性角色，你获得1点怒气；若目标为吕玲绮，你额外摸1张牌。", compulsory = true})
extension:insertRelatedSkills("nuyan_fenxin", "nuyan_bond_lingju_1")
extension:insertRelatedSkills("nuyan_jd_fenxin", "nuyan_bond_lingju_1")
register({id = "nuyan_bond_lvlingqi_1", mode = "bond_end_star_heal", label = "神威再现", text = "锁定技，每名角色回合结束时，若你的体力值或手牌数不大于你的星级，你回复1点体力并摸1张牌。", compulsory = true})
extension:insertRelatedSkills("nuyan_guowu", "nuyan_bond_lvlingqi_1")
extension:insertRelatedSkills("nuyan_jd_guowu", "nuyan_bond_lvlingqi_1")
register({id = "nuyan_bond_lvlingqi_3", mode = "bond_nuqi_guowu", label = "无双虓姬", text = "锁定技，你的【杀】的伤害+X（X为出牌阶段你已主动使用【杀】的次数）。", compulsory = true})
extension:insertRelatedSkills("nuyan_guowu", "nuyan_bond_lvlingqi_3")
extension:insertRelatedSkills("nuyan_jd_guowu", "nuyan_bond_lvlingqi_3")
register({id = "nuyan_bond_yuejin_1", mode = "bond_round_basic", label = "奋强突固", text = "锁定技，每轮限一次，当你受到伤害后，你从牌堆中随机获得【杀】和【闪】各一张。", compulsory = true})
extension:insertRelatedSkills("nuyan_xiaoguo", "nuyan_bond_yuejin_1")
extension:insertRelatedSkills("nuyan_jd_xiaoguo", "nuyan_bond_yuejin_1")
register({id = "nuyan_bond_yuejin_3", mode = "bond_damage_hand", label = "碧眼梦惊", text = "每回合限一次，当你造成伤害后，你可以摸Y张牌，然后你本回合手牌上限+Y（Y为受伤角色手牌数与体力值差值的绝对值，且不超过10）。", compulsory = false})
extension:insertRelatedSkills("nuyan_xiaoguo", "nuyan_bond_yuejin_3")
extension:insertRelatedSkills("nuyan_jd_xiaoguo", "nuyan_bond_yuejin_3")
register({id = "nuyan_bond_wuyi_1", mode = "bond_benxi_distance", label = "奔袭千里", text = "锁定技，当其他角色计算与你的距离时，始终+X（X为你的怒气值）。", compulsory = true})
extension:insertRelatedSkills("nuyan_benxi", "nuyan_bond_wuyi_1")
extension:insertRelatedSkills("nuyan_jd_benxi", "nuyan_bond_wuyi_1")
register({id = "nuyan_lianhuayiyi", mode = "bond_hanhua_grant", label = "莲华熠熠", text = "锁定技，你获得'莲华'。", compulsory = true})
extension:insertRelatedSkills("nuyan_huiling","nuyan_lianhuayiyi")
register({id = "nuyan_miaojianxuanwei", mode = "bond_hanhua_grant", label = "妙剑宣威", text = "锁定技，你获得'妙剑'。", compulsory = true})
extension:insertRelatedSkills("nuyan_huiling","nuyan_miaojianxuanwei")
for _,parent in ipairs({"nuyan_zhengnan","nuyan_jd_zhengnan"}) do
    for _,related in ipairs({"nuyan_wusheng","nuyan_dangxian","nuyan_xinzhan"}) do extension:insertRelatedSkills(parent,related) end
end
for _,parent in ipairs({"nuyan_tianshu","nuyan_jd_tianshu"}) do
    for _,related in ipairs(book_names) do extension:insertRelatedSkills(parent,"nuyan_ts_" .. related) end
end
extension:insertRelatedSkills("nuyan_huiling","nuyan_lianhua")
extension:insertRelatedSkills("nuyan_huiling","nuyan_miaojian")
add_correct_skills()
local pending = sgs.SkillList()
for id, skill in pairs(skills) do
    if not sgs.Sanguosha:getSkill(id) then pending:append(skill) end
end
sgs.Sanguosha:addSkills(pending)
for _, general in sgs.qlist(sgs.Sanguosha:getAllGenerals()) do
    for _,id in ipairs(global_names) do if not general:hasSkill(id) then general:addSkill(id) end end
end
sgs.LoadTranslationTable(translations)
return extension
