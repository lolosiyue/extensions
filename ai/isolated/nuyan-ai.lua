-- Nuyan package policies.
local active = {
    qiangxi=true,xuanhuo=true,kurou=true,luoyi=true,renxin=true,zhiman=true,
    baoli=true,quhu=true,zhenjun=true,zhilue=true,quanji=true,jizhen=true,
    qiangwu=true,xuehen=true,zhiheng=true,duwu=true,zhijian=true,lihun=true,
    xianzhen=true,xianzhou=true,zhongjian=true,pianchong=true,jitian=true,
    dulie=true,canshi=true,luanwu=true,fencheng=true,fenxin=true,yanyu=true,wenji=true
}
local card_names = {qixi="dismantlement",jixi="snatch",luanji="archery_attack",shensu="slash",
    jiushi="analeptic",gongxin="snatch",langxing="duel",hubu="duel",duanliang="indulgence",
    wusheng="slash",fanjian="drowning",guose="indulgence",manyi="savage_assault",jijiu="peach",
    leifa="jink",luoshen="jink"}
local costs={shensu=2,gongxin=1,hubu=1,duanliang=1,manyi=1,lihun=1,zhilue=1,luanwu=1,fenxin=1}
local function cards_of(p)
    local t={};for _,c in sgs.qlist(p:getCards("he")) do t[#t+1]=c end;return t
end
local function selected_ids(t)
    local ids={};for _,c in ipairs(t) do ids[#ids+1]=tostring(c:getEffectiveId()) end
    return #ids>0 and table.concat(ids,"+") or "."
end
local function maxuses(sp,p)
    if sp.mode=="qiangxi" and sp.classic then return math.huge end
    if sp.mode=="kurou" then return sp.classic and 2 or p:getMark("@nuyan_star") end
    if sp.mode=="quhu" or sp.mode=="luanwu" then return sp.classic and 2 or p:getMark("@nuyan_star")+1 end
    if sp.mode=="xuehen" then return sp.classic and p:getMark("nuyan_xuehen_limit") or p:getMark("@nuyan_star") end
    if sp.mode=="zhijian" then return sp.classic and 4 or p:getMark("@nuyan_star") end
    if sp.mode=="fenxin" then return p:getMark("nuyan_nuqi_cap") end
    if sp.mode=="luoyi" and sp.jie then return 3 end
    if sp.mode=="duwu" or sp.mode=="baoli" or sp.mode=="zhilue" or sp.mode=="jitian" or sp.mode=="fencheng" or sp.mode=="yanyu" or sp.mode=="wenji" then return math.huge end
    return 1
end
local function selection(self,sp)
    local m,p=sp.mode,self.player;local t=cards_of(p);self:sortByKeepValue(t)
    local chosen={}
    if m=="zhiheng" then
        for _,c in ipairs(t) do if not p:isJilei(c) and not c:isKindOf("Peach") and self:getKeepValue(c)<4 and (sp.jie or sp.classic or #chosen<4) then chosen[#chosen+1]=c end end
        return chosen
    end
    for _,c in ipairs(t) do
        local ok=not p:isJilei(c)
        if m=="qiangxi" then ok=ok and c:isKindOf("EquipCard")
        elseif m=="xuanhuo" then ok=not c:isEquipped() and c:getSuit()==sgs.Card_Diamond
        elseif m=="luoyi" then ok=ok and (sp.jie and not c:isEquipped() and p:getMark(sp.id .. "_type" .. c:getTypeId() .. "-PlayClear")==0 or not sp.jie and c:isKindOf("EquipCard"))
        elseif m=="xuehen" then ok=ok and c:getSuit()==sgs.Card_Heart
        elseif m=="zhongjian" or m=="zhijian" then ok=ok and not c:isEquipped()
        elseif m=="yanyu" then ok=ok and c:isKindOf("Slash") end
        if ok then chosen[1]=c;break end
    end
    return chosen
end
local no_cards={kurou=true,renxin=true,baoli=true,quhu=true,zhilue=true,quanji=true,
    jizhen=true,qiangwu=true,lihun=true,xianzhen=true,xianzhou=true,pianchong=true,
    dulie=true,canshi=true,luanwu=true,fencheng=true,fenxin=true,wenji=true}
local friendly={renxin=true,zhenjun=true,zhijian=true,dulie=true,fenxin=true}
local fixed={kurou=true,luoyi=true,baoli=true,zhilue=true,quanji=true,zhiheng=true,
    pianchong=true,canshi=true,luanwu=true,fencheng=true,yanyu=true}
local function register_ai(sp)
    local id,m=sp.id,sp.mode
    ai_skill_invoke[id]=function(self, options, request)
        local data = request and self:getDecisionData(request) or nil
        if m=="fenji" then return (self.player:getHp()>2) or false end
        if m=="miji" then local u=data:toCardUse();return (u.from and self:isEnemy(u.from) and self.player:getHp()>1) or false end
        if m=="kuanggu" then return (true) or false end
        return (true) or false
    end
    ai_skill_choice[id]=function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

        if choices:find("nuyan_recover",1,true) and self.player:isWounded() then return ai_choice_result(("nuyan_recover"), options) end
        if choices:find("nuyan_slash",1,true) and self:getCardsNum("Slash")>1 then return ai_choice_result(("nuyan_slash"), options) end
        if choices:find("nuyan_losehp",1,true) and self.player:getHp()<=2 and choices:find("nuyan_discard",1,true) then return ai_choice_result(("nuyan_discard"), options) end
        if choices:find("nuyan_draw",1,true) then return ai_choice_result(("nuyan_draw"), options) end
        if choices:find("nuyan_black",1,true) then
            local red,black=0,0;for _,c in sgs.qlist(self.player:getHandcards()) do if c:isRed() then red=red+1 else black=black+1 end end
            return ai_choice_result((red>=black and "nuyan_red" or "nuyan_black"), options)
        end
        local first=choices:match("[^+]+");return ai_choice_result((first), options)
    end
    sgs.ai_skill_playerchosen[id]=function(self,targets)
        local t=sgs.QList2Table(targets);self:sort(t,"defense")
        local benefit=m=="yiji" or m=="huituo" or m=="kangkai" or m=="tianshu" or m=="zhengnan" or m=="yanyu" or friendly[m]
        for _,p in ipairs(t) do if benefit and self:isFriend(p) or not benefit and self:isEnemy(p) then return p end end
        return t[1]
    end
    if active[m] then
        local skill={name=id};table.insert(sgs.ai_skills,skill)
        skill.getTurnUseCard=function(self, options, request)
            local p=self.player
            if p:getMark(id .. "_used-PlayClear")>=maxuses(sp,p) then return end
            if costs[m] and p:getMark("@nuyan_nuqi")<costs[m] then return end
            if m=="jizhen" and p:getMark(id .. "_jizhen-Clear")>0 then return end
            if (m=="kurou" or m=="baoli" or m=="qiangxi" and sp.classic) and p:getHp()<=2 then return end
            if m=="baoli" and p:getMark("nuyan_nuqi_cap")>0 and p:getMark("@nuyan_nuqi")>=p:getMark("nuyan_nuqi_cap") then return end
            if m=="quanji" and p:getMark("@nuyan_quan")==0 or m=="canshi" and p:getMark("@nuyan_chou")==0 then return end
            if m=="duwu" and p:getMark(id .. "_ban-Clear")>0 then return end
            if m=="fencheng" and (#self.enemies<=#self.friends-1 or p:getMark("@nuyan_nuqi")<p:getMark(id .. "_times-Clear")) then return end
            local chosen=no_cards[m] and {} or selection(self,sp)
            if not no_cards[m] and #chosen==0 and not (m=="qiangxi" and sp.classic) then return end
            if m=="zhiheng" and #chosen==0 then return end
            return sgs.Card_Parse("#" .. id .. "Card:" .. selected_ids(chosen) .. ":")
        end
        ai_card_use["#" .. id .. "Card"]=function(self, card, use, request)
            if fixed[m] then use.card=card;return end
            local p=self.player;local pool=friendly[m] and self.friends or self.enemies
            self:sort(pool,"defense")
            for _,q in ipairs(pool) do
                local ok=q~=p or m=="renxin" or m=="dulie" or m=="fenxin"
                if m=="qiangxi" and sp.classic then ok=ok and q:getMark(id .. "_hit-PlayClear")==0 end
                if m=="quhu" or m=="xianzhen" then ok=ok and p:canPindian(q) end
                if m=="renxin" then ok=q:isWounded() and q:getMark("@nuyan_nuqi")>1 end
                if m=="xianzhou" then ok=ok and not q:getEquips():isEmpty() end
                if m=="lihun" or m=="zhongjian" then ok=ok and not q:isKongcheng() end
                if m=="jizhen" or m=="qiangwu" then ok=ok and p:canDiscard(q,m=="jizhen" and "hej" or "he") end
                if m=="wenji" then ok=ok and not q:isNude() and q:getMark(id .. "_hit-PlayClear")==0 end
                if m=="duwu" then
                    local n=sp.jie and 1 or math.max(0,math.ceil(q:getHp()/2));local t=cards_of(p);self:sortByKeepValue(t);local chosen={}
                    for _,c in ipairs(t) do if not p:isJilei(c) and not c:isKindOf("Peach") and #chosen<n then chosen[#chosen+1]=c end end
                    ok=ok and #chosen==n
                    if ok then card=sgs.Card_Parse("#" .. id .. "Card:" .. selected_ids(chosen) .. ":") end
                end
                if ok then use.card=card;if use.to then use.to:append(q) end;return end
            end
        end
        sgs.ai_use_priority["#" .. id .. "Card"]=3
        sgs.ai_use_value["#" .. id .. "Card"]=5
    elseif card_names[m] then
        local skill={name=id};table.insert(sgs.ai_skills,skill)
        skill.getTurnUseCard=function(self, options, request)
            local p=self.player;local name=card_names[m]
            if name=="jink" then return end
            if costs[m] and p:getMark("@nuyan_nuqi")<costs[m] then return end
            if m=="manyi" and p:getMark(id .. "_used-PlayClear")>=3 then return end
            if m=="shensu" or m=="gongxin" or m=="hubu" or m=="manyi" then return sgs.Card_Parse(name .. ":" .. id .. "[no_suit:0]=.") end
            local t=cards_of(p);self:sortByUseValue(t,true);local chosen={}
            for _,c in ipairs(t) do
                local ok=not c:isEquipped()
                if m=="qixi" then ok=ok and (sp.classic and c:isBlack() or not sp.classic and c:getSuit()==sgs.Card_Club)
                elseif m=="jixi" then ok=ok and c:isKindOf("Jink")
                elseif m=="jiushi" then ok=ok and c:isBlack()
                elseif m=="langxing" then ok=ok and c:isKindOf("BasicCard")
                elseif m=="duanliang" then ok=ok and c:isBlack() and (c:isKindOf("BasicCard") or c:isKindOf("EquipCard"))
                elseif m=="fanjian" then ok=ok and c:getSuit()==sgs.Card_Spade
                elseif m=="guose" then ok=ok and c:getSuit()==sgs.Card_Diamond
                elseif m=="jijiu" then ok=ok and c:getSuit()==sgs.Card_Heart end
                if ok and not c:isKindOf("Peach") then chosen[#chosen+1]=c;if #chosen==(m=="luanji" and 3 or 1) then break end end
            end
            if #chosen~=(m=="luanji" and 3 or 1) then return end
            return sgs.Card_Parse(name .. ":" .. id .. "[" .. (#chosen==1 and chosen[1]:getSuitString() or "no_suit") .. ":" .. (#chosen==1 and chosen[1]:getNumber() or 0) .. "]=" .. selected_ids(chosen))
        end
        sgs.ai_view_as[id]=function(card,player,place,class_name)
            local requested={Slash="slash",Jink="jink",Peach="peach",Analeptic="analeptic"}
            local name=card_names[m];if requested[class_name]~=name or place~=sgs.Player_PlaceHand then return end
            local ok=m=="wusheng" or m=="leifa" and card:getSuit()==sgs.Card_Diamond or m=="luoshen" and card:isBlack() or m=="jijiu" and card:getSuit()==sgs.Card_Heart or m=="jiushi" and card:isBlack()
            if ok then return name .. ":" .. id .. "[" .. card:getSuitString() .. ":" .. card:getNumber() .. "]=" .. card:getEffectiveId() end
        end
    end
end
register_ai({id = "nuyan_ganglie", mode = "ganglie", classic = false, jie = false})
register_ai({id = "nuyan_jd_ganglie", mode = "ganglie", classic = true, jie = false})
register_ai({id = "nuyan_qiangxi", mode = "qiangxi", classic = false, jie = false})
register_ai({id = "nuyan_jd_qiangxi", mode = "qiangxi", classic = true, jie = false})
register_ai({id = "nuyan_xuanhuo", mode = "xuanhuo", classic = false, jie = false})
register_ai({id = "nuyan_jd_xuanhuo", mode = "xuanhuo", classic = true, jie = false})
register_ai({id = "nuyan_qixi", mode = "qixi", classic = false, jie = false})
register_ai({id = "nuyan_jie_qixi", mode = "qixi", classic = false, jie = true})
register_ai({id = "nuyan_jd_qixi", mode = "qixi", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_qixi", mode = "qixi", classic = true, jie = true})
register_ai({id = "nuyan_kurou", mode = "kurou", classic = false, jie = false})
register_ai({id = "nuyan_jd_kurou", mode = "kurou", classic = true, jie = false})
register_ai({id = "nuyan_mengjin", mode = "mengjin", classic = false, jie = false})
register_ai({id = "nuyan_jd_mengjin", mode = "mengjin", classic = true, jie = false})
register_ai({id = "nuyan_luanji", mode = "luanji", classic = false, jie = false})
register_ai({id = "nuyan_jd_luanji", mode = "luanji", classic = true, jie = false})
register_ai({id = "nuyan_yiji", mode = "yiji", classic = false, jie = false})
register_ai({id = "nuyan_jd_yiji", mode = "yiji", classic = true, jie = false})
register_ai({id = "nuyan_shensu", mode = "shensu", classic = false, jie = false})
register_ai({id = "nuyan_jd_shensu", mode = "shensu", classic = true, jie = false})
register_ai({id = "nuyan_jixi", mode = "jixi", classic = false, jie = false})
register_ai({id = "nuyan_jd_jixi", mode = "jixi", classic = true, jie = false})
register_ai({id = "nuyan_luoyi", mode = "luoyi", classic = false, jie = false})
register_ai({id = "nuyan_jie_luoyi", mode = "luoyi", classic = false, jie = true})
register_ai({id = "nuyan_jd_luoyi", mode = "luoyi", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_luoyi", mode = "luoyi", classic = true, jie = true})
register_ai({id = "nuyan_jiushi", mode = "jiushi", classic = false, jie = false})
register_ai({id = "nuyan_jd_jiushi", mode = "jiushi", classic = true, jie = false})
register_ai({id = "nuyan_renxin", mode = "renxin", classic = false, jie = false})
register_ai({id = "nuyan_jd_chengxiang", mode = "chengxiang", classic = true, jie = false})
register_ai({id = "nuyan_liegong", mode = "liegong", classic = false, jie = false})
register_ai({id = "nuyan_jie_liegong", mode = "liegong", classic = false, jie = true})
register_ai({id = "nuyan_jd_liegong", mode = "liegong", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_liegong", mode = "liegong", classic = true, jie = true})
register_ai({id = "nuyan_paoxiao", mode = "paoxiao", classic = false, jie = false})
register_ai({id = "nuyan_jie_paoxiao", mode = "paoxiao", classic = false, jie = true})
register_ai({id = "nuyan_jd_paoxiao", mode = "paoxiao", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_paoxiao", mode = "paoxiao", classic = true, jie = true})
register_ai({id = "nuyan_kuanggu", mode = "kuanggu", classic = false, jie = false})
register_ai({id = "nuyan_jd_kuanggu", mode = "kuanggu", classic = true, jie = false})
register_ai({id = "nuyan_xiangle", mode = "xiangle", classic = false, jie = false})
register_ai({id = "nuyan_jie_xiangle", mode = "xiangle", classic = false, jie = true})
register_ai({id = "nuyan_jd_xiangle", mode = "xiangle", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_xiangle", mode = "xiangle", classic = true, jie = true})
register_ai({id = "nuyan_zhiman", mode = "zhiman", classic = false, jie = false})
register_ai({id = "nuyan_jd_zhiman", mode = "zhiman", classic = true, jie = false})
register_ai({id = "nuyan_tianxiang", mode = "tianxiang", classic = false, jie = false})
register_ai({id = "nuyan_jd_tianxiang", mode = "tianxiang", classic = true, jie = false})
register_ai({id = "nuyan_gongxin", mode = "gongxin", classic = false, jie = false})
register_ai({id = "nuyan_jd_gongxin", mode = "gongxin", classic = true, jie = false})
register_ai({id = "nuyan_lianying", mode = "lianying", classic = false, jie = false})
register_ai({id = "nuyan_jd_lianying", mode = "lianying", classic = true, jie = false})
register_ai({id = "nuyan_xuanfeng", mode = "xuanfeng", classic = false, jie = false})
register_ai({id = "nuyan_jd_xuanfeng", mode = "xuanfeng", classic = true, jie = false})
register_ai({id = "nuyan_baoli", mode = "baoli", classic = false, jie = false})
register_ai({id = "nuyan_jd_baoli", mode = "baoli", classic = true, jie = false})
register_ai({id = "nuyan_shiyong", mode = "shiyong", classic = false, jie = false})
register_ai({id = "nuyan_jd_shiyong", mode = "shiyong", classic = true, jie = false})
register_ai({id = "nuyan_langxing", mode = "langxing", classic = false, jie = false})
register_ai({id = "nuyan_jd_langxing", mode = "langxing", classic = true, jie = false})
register_ai({id = "nuyan_hubu", mode = "hubu", classic = false, jie = false})
register_ai({id = "nuyan_jd_hubu", mode = "hubu", classic = true, jie = false})
register_ai({id = "nuyan_fankui", mode = "fankui", classic = false, jie = false})
register_ai({id = "nuyan_jd_fankui", mode = "fankui", classic = true, jie = false})
register_ai({id = "nuyan_jushou", mode = "jushou", classic = false, jie = false})
register_ai({id = "nuyan_jd_jushou", mode = "jushou", classic = true, jie = false})
register_ai({id = "nuyan_jianxiong", mode = "jianxiong", classic = false, jie = false})
register_ai({id = "nuyan_jie_jianxiong", mode = "jianxiong", classic = false, jie = true})
register_ai({id = "nuyan_jd_jianxiong", mode = "jianxiong", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_jianxiong", mode = "jianxiong", classic = true, jie = true})
register_ai({id = "nuyan_tuxi", mode = "tuxi", classic = false, jie = false})
register_ai({id = "nuyan_jd_tuxi", mode = "tuxi", classic = true, jie = false})
register_ai({id = "nuyan_shangshi", mode = "shangshi", classic = false, jie = false})
register_ai({id = "nuyan_jie_shangshi", mode = "shangshi", classic = false, jie = true})
register_ai({id = "nuyan_jd_shangshi", mode = "shangshi", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_shangshi", mode = "shangshi", classic = true, jie = true})
register_ai({id = "nuyan_jiangchi", mode = "jiangchi", classic = false, jie = false})
register_ai({id = "nuyan_jd_jiangchi", mode = "jiangchi", classic = true, jie = false})
register_ai({id = "nuyan_miji", mode = "miji", classic = false, jie = false})
register_ai({id = "nuyan_jd_miji", mode = "miji", classic = true, jie = false})
register_ai({id = "nuyan_quhu", mode = "quhu", classic = false, jie = false})
register_ai({id = "nuyan_jd_quhu", mode = "quhu", classic = true, jie = false})
register_ai({id = "nuyan_duanliang", mode = "duanliang", classic = false, jie = false})
register_ai({id = "nuyan_jd_duanliang", mode = "duanliang", classic = true, jie = false})
register_ai({id = "nuyan_qice", mode = "qice", classic = false, jie = false})
register_ai({id = "nuyan_jie_qice", mode = "qice", classic = false, jie = true})
register_ai({id = "nuyan_jd_qice", mode = "qice", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_qice", mode = "qice", classic = true, jie = true})
register_ai({id = "nuyan_zhenjun", mode = "zhenjun", classic = false, jie = false})
register_ai({id = "nuyan_jd_zhenjun", mode = "zhenjun", classic = true, jie = false})
register_ai({id = "nuyan_zhilue", mode = "zhilue", classic = false, jie = false})
register_ai({id = "nuyan_jd_zhilue", mode = "zhilue", classic = true, jie = false})
register_ai({id = "nuyan_quanji", mode = "quanji", classic = false, jie = false})
register_ai({id = "nuyan_jd_quanji", mode = "quanji", classic = true, jie = false})
register_ai({id = "nuyan_kangkai", mode = "kangkai", classic = false, jie = false})
register_ai({id = "nuyan_jd_kangkai", mode = "kangkai", classic = true, jie = false})
register_ai({id = "nuyan_qizhi", mode = "qizhi", classic = false, jie = false})
register_ai({id = "nuyan_jd_qizhi", mode = "qizhi", classic = true, jie = false})
register_ai({id = "nuyan_renwang", mode = "renwang", classic = false, jie = false})
register_ai({id = "nuyan_jd_renwang", mode = "renwang", classic = true, jie = false})
register_ai({id = "nuyan_wusheng", mode = "wusheng", classic = false, jie = false})
register_ai({id = "nuyan_jie_wusheng", mode = "wusheng", classic = false, jie = true})
register_ai({id = "nuyan_jd_wusheng", mode = "wusheng", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_wusheng", mode = "wusheng", classic = true, jie = true})
register_ai({id = "nuyan_jizhi", mode = "jizhi", classic = false, jie = false})
register_ai({id = "nuyan_jie_jizhi", mode = "jizhi", classic = false, jie = true})
register_ai({id = "nuyan_jd_jizhi", mode = "jizhi", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_jizhi", mode = "jizhi", classic = true, jie = true})
register_ai({id = "nuyan_tieqi", mode = "tieqi", classic = false, jie = false})
register_ai({id = "nuyan_jie_tieqi", mode = "tieqi", classic = false, jie = true})
register_ai({id = "nuyan_jd_tieqi", mode = "tieqi", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_tieqi", mode = "tieqi", classic = true, jie = true})
register_ai({id = "nuyan_jizhen", mode = "jizhen", classic = false, jie = false})
register_ai({id = "nuyan_jd_jizhen", mode = "jizhen", classic = true, jie = false})
register_ai({id = "nuyan_qiangwu", mode = "qiangwu", classic = false, jie = false})
register_ai({id = "nuyan_jd_qiangwu", mode = "qiangwu", classic = true, jie = false})
register_ai({id = "nuyan_fengpo", mode = "fengpo", classic = false, jie = false})
register_ai({id = "nuyan_jd_fengpo", mode = "fengpo", classic = true, jie = false})
register_ai({id = "nuyan_zhanji", mode = "zhanji", classic = false, jie = false})
register_ai({id = "nuyan_jd_zhanji", mode = "zhanji", classic = true, jie = false})
register_ai({id = "nuyan_zhuhai", mode = "zhuhai", classic = false, jie = false})
register_ai({id = "nuyan_jd_zhuhai", mode = "zhuhai", classic = true, jie = false})
register_ai({id = "nuyan_dangxian", mode = "dangxian", classic = false, jie = false})
register_ai({id = "nuyan_jd_dangxian", mode = "dangxian", classic = true, jie = false})
register_ai({id = "nuyan_xuehen", mode = "xuehen", classic = false, jie = false})
register_ai({id = "nuyan_jd_xuehen", mode = "xuehen", classic = true, jie = false})
register_ai({id = "nuyan_yingyuan", mode = "yingyuan", classic = false, jie = false})
register_ai({id = "nuyan_jd_yingyuan", mode = "yingyuan", classic = true, jie = false})
register_ai({id = "nuyan_fanjian", mode = "fanjian", classic = false, jie = false})
register_ai({id = "nuyan_jd_fanjian", mode = "fanjian", classic = true, jie = false})
register_ai({id = "nuyan_xiaoji", mode = "xiaoji", classic = false, jie = false})
register_ai({id = "nuyan_jd_xiaoji", mode = "xiaoji", classic = true, jie = false})
register_ai({id = "nuyan_guose", mode = "guose", classic = false, jie = false})
register_ai({id = "nuyan_jd_guose", mode = "guose", classic = true, jie = false})
register_ai({id = "nuyan_zhiheng", mode = "zhiheng", classic = false, jie = false})
register_ai({id = "nuyan_jie_zhiheng", mode = "zhiheng", classic = false, jie = true})
register_ai({id = "nuyan_jd_zhiheng", mode = "zhiheng", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_zhiheng", mode = "zhiheng", classic = true, jie = true})
register_ai({id = "nuyan_dujin", mode = "dujin", classic = false, jie = false})
register_ai({id = "nuyan_jd_dujin", mode = "dujin", classic = true, jie = false})
register_ai({id = "nuyan_yinghun", mode = "yinghun", classic = false, jie = false})
register_ai({id = "nuyan_jd_yinghun", mode = "yinghun", classic = true, jie = false})
register_ai({id = "nuyan_fenji", mode = "fenji", classic = false, jie = false})
register_ai({id = "nuyan_jd_fenji", mode = "fenji", classic = true, jie = false})
register_ai({id = "nuyan_haoshi", mode = "haoshi", classic = false, jie = false})
register_ai({id = "nuyan_jd_haoshi", mode = "haoshi", classic = true, jie = false})
register_ai({id = "nuyan_pojun", mode = "pojun", classic = false, jie = false})
register_ai({id = "nuyan_jd_pojun", mode = "pojun", classic = true, jie = false})
register_ai({id = "nuyan_duwu", mode = "duwu", classic = false, jie = false})
register_ai({id = "nuyan_jie_duwu", mode = "duwu", classic = false, jie = true})
register_ai({id = "nuyan_jd_duwu", mode = "duwu", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_duwu", mode = "duwu", classic = true, jie = true})
register_ai({id = "nuyan_ganlu", mode = "ganlu", classic = false, jie = false})
register_ai({id = "nuyan_jd_ganlu", mode = "ganlu", classic = true, jie = false})
register_ai({id = "nuyan_zhijian", mode = "zhijian", classic = false, jie = false})
register_ai({id = "nuyan_jd_zhijian", mode = "zhijian", classic = true, jie = false})
register_ai({id = "nuyan_lihun", mode = "lihun", classic = false, jie = false})
register_ai({id = "nuyan_jd_lihun", mode = "lihun", classic = true, jie = false})
register_ai({id = "nuyan_leifa", mode = "leifa", classic = false, jie = false})
register_ai({id = "nuyan_jie_leifa", mode = "leifa", classic = false, jie = true})
register_ai({id = "nuyan_jd_leifa", mode = "leifa", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_leifa", mode = "leifa", classic = true, jie = true})
register_ai({id = "nuyan_lieren", mode = "lieren", classic = false, jie = false})
register_ai({id = "nuyan_jie_lieren", mode = "lieren", classic = false, jie = true})
register_ai({id = "nuyan_jd_lieren", mode = "lieren", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_lieren", mode = "lieren", classic = true, jie = true})
register_ai({id = "nuyan_manyi", mode = "manyi", classic = false, jie = false})
register_ai({id = "nuyan_jd_manyi", mode = "manyi", classic = true, jie = false})
register_ai({id = "nuyan_jijiu", mode = "jijiu", classic = false, jie = false})
register_ai({id = "nuyan_jd_jijiu", mode = "jijiu", classic = true, jie = false})
register_ai({id = "nuyan_shouxi", mode = "shouxi", classic = false, jie = false})
register_ai({id = "nuyan_jd_shouxi", mode = "shouxi", classic = true, jie = false})
register_ai({id = "nuyan_tianming", mode = "tianming", classic = false, jie = false})
register_ai({id = "nuyan_jd_tianming", mode = "tianming", classic = true, jie = false})
register_ai({id = "nuyan_zhichi", mode = "zhichi", classic = false, jie = false})
register_ai({id = "nuyan_jd_zhichi", mode = "zhichi", classic = true, jie = false})
register_ai({id = "nuyan_yicong", mode = "yicong", classic = false, jie = false})
register_ai({id = "nuyan_jie_yicong", mode = "yicong", classic = false, jie = true})
register_ai({id = "nuyan_jd_yicong", mode = "yicong", classic = true, jie = false})
register_ai({id = "nuyan_jd_jie_yicong", mode = "yicong", classic = true, jie = true})
register_ai({id = "nuyan_xianzhen", mode = "xianzhen", classic = false, jie = false})
register_ai({id = "nuyan_jd_xianzhen", mode = "xianzhen", classic = true, jie = false})
register_ai({id = "nuyan_xianzhou", mode = "xianzhou", classic = false, jie = false})
register_ai({id = "nuyan_jd_xianzhou", mode = "xianzhou", classic = true, jie = false})
register_ai({id = "nuyan_yongsi", mode = "yongsi", classic = false, jie = false})
register_ai({id = "nuyan_jd_yongsi", mode = "yongsi", classic = true, jie = false})
register_ai({id = "nuyan_xiahui", mode = "xiahui", classic = false, jie = false})
register_ai({id = "nuyan_jd_xiahui", mode = "xiahui", classic = true, jie = false})
register_ai({id = "nuyan_jianying", mode = "jianying", classic = false, jie = false})
register_ai({id = "nuyan_jd_jianying", mode = "jianying", classic = true, jie = false})
register_ai({id = "nuyan_luoshen", mode = "luoshen", classic = false, jie = false})
register_ai({id = "nuyan_jd_luoshen", mode = "luoshen", classic = true, jie = false})
register_ai({id = "nuyan_fangzhu", mode = "fangzhu", classic = false, jie = false})
register_ai({id = "nuyan_jd_fangzhu", mode = "fangzhu", classic = true, jie = false})
register_ai({id = "nuyan_zhongjian", mode = "zhongjian", classic = false, jie = false})
register_ai({id = "nuyan_jd_zhongjian", mode = "zhongjian", classic = true, jie = false})
register_ai({id = "nuyan_chouce", mode = "chouce", classic = false, jie = false})
register_ai({id = "nuyan_jd_chouce", mode = "chouce", classic = true, jie = false})
register_ai({id = "nuyan_shefu", mode = "shefu", classic = false, jie = false})
register_ai({id = "nuyan_jd_shefu", mode = "shefu", classic = true, jie = false})
register_ai({id = "nuyan_pianchong", mode = "pianchong", classic = false, jie = false})
register_ai({id = "nuyan_jd_pianchong", mode = "pianchong", classic = true, jie = false})
register_ai({id = "nuyan_juejing", mode = "juejing", classic = false, jie = false})
register_ai({id = "nuyan_jd_juejing", mode = "juejing", classic = true, jie = false})
register_ai({id = "nuyan_jitian", mode = "jitian", classic = false, jie = false})
register_ai({id = "nuyan_jd_jitian", mode = "jitian", classic = true, jie = false})
register_ai({id = "nuyan_bingzheng", mode = "bingzheng", classic = false, jie = false})
register_ai({id = "nuyan_jd_bingzheng", mode = "bingzheng", classic = true, jie = false})
register_ai({id = "nuyan_zhengnan", mode = "zhengnan", classic = false, jie = false})
register_ai({id = "nuyan_jd_zhengnan", mode = "zhengnan", classic = true, jie = false})
register_ai({id = "nuyan_wuniang", mode = "wuniang", classic = false, jie = false})
register_ai({id = "nuyan_jd_wuniang", mode = "wuniang", classic = true, jie = false})
register_ai({id = "nuyan_fanghun", mode = "fanghun", classic = false, jie = false})
register_ai({id = "nuyan_jd_fanghun", mode = "fanghun", classic = true, jie = false})
register_ai({id = "nuyan_jiangang", mode = "jiangang", classic = false, jie = false})
register_ai({id = "nuyan_jd_jiangang", mode = "jiangang", classic = true, jie = false})
register_ai({id = "nuyan_anxu", mode = "anxu", classic = false, jie = false})
register_ai({id = "nuyan_jd_anxu", mode = "anxu", classic = true, jie = false})
register_ai({id = "nuyan_dulie", mode = "dulie", classic = false, jie = false})
register_ai({id = "nuyan_jd_dulie", mode = "dulie", classic = true, jie = false})
register_ai({id = "nuyan_canshi", mode = "canshi", classic = false, jie = false})
register_ai({id = "nuyan_jd_canshi", mode = "canshi", classic = true, jie = false})
register_ai({id = "nuyan_fenyin", mode = "fenyin", classic = false, jie = false})
register_ai({id = "nuyan_jd_fenyin", mode = "fenyin", classic = true, jie = false})
register_ai({id = "nuyan_hongyuan", mode = "hongyuan", classic = false, jie = false})
register_ai({id = "nuyan_jd_hongyuan", mode = "hongyuan", classic = true, jie = false})
register_ai({id = "nuyan_shenwei", mode = "shenwei", classic = false, jie = false})
register_ai({id = "nuyan_jd_shenwei", mode = "shenwei", classic = true, jie = false})
register_ai({id = "nuyan_beige", mode = "beige", classic = false, jie = false})
register_ai({id = "nuyan_jd_beige", mode = "beige", classic = true, jie = false})
register_ai({id = "nuyan_luanwu", mode = "luanwu", classic = false, jie = false})
register_ai({id = "nuyan_jd_luanwu", mode = "luanwu", classic = true, jie = false})
register_ai({id = "nuyan_guhuo", mode = "guhuo", classic = false, jie = false})
register_ai({id = "nuyan_jd_guhuo", mode = "guhuo", classic = true, jie = false})
register_ai({id = "nuyan_fencheng", mode = "fencheng", classic = false, jie = false})
register_ai({id = "nuyan_jd_fencheng", mode = "fencheng", classic = true, jie = false})
register_ai({id = "nuyan_fenxin", mode = "fenxin", classic = false, jie = false})
register_ai({id = "nuyan_jd_fenxin", mode = "fenxin", classic = true, jie = false})
register_ai({id = "nuyan_guowu", mode = "guowu", classic = false, jie = false})
register_ai({id = "nuyan_jd_guowu", mode = "guowu", classic = true, jie = false})
register_ai({id = "nuyan_zenhui", mode = "zenhui", classic = false, jie = false})
register_ai({id = "nuyan_jd_zenhui", mode = "zenhui", classic = true, jie = false})
register_ai({id = "nuyan_meibu", mode = "meibu", classic = false, jie = false})
register_ai({id = "nuyan_jd_meibu", mode = "meibu", classic = true, jie = false})
register_ai({id = "nuyan_longyin", mode = "longyin", classic = false, jie = false})
register_ai({id = "nuyan_jd_longyin", mode = "longyin", classic = true, jie = false})
register_ai({id = "nuyan_zhuandui", mode = "zhuandui", classic = false, jie = false})
register_ai({id = "nuyan_jd_zhuandui", mode = "zhuandui", classic = true, jie = false})
register_ai({id = "nuyan_yanyu", mode = "yanyu", classic = false, jie = false})
register_ai({id = "nuyan_jd_yanyu", mode = "yanyu", classic = true, jie = false})
register_ai({id = "nuyan_shicai", mode = "shicai", classic = false, jie = false})
register_ai({id = "nuyan_jd_shicai", mode = "shicai", classic = true, jie = false})
register_ai({id = "nuyan_kongsheng", mode = "kongsheng", classic = false, jie = false})
register_ai({id = "nuyan_jd_kongsheng", mode = "kongsheng", classic = true, jie = false})
register_ai({id = "nuyan_huituo", mode = "huituo", classic = false, jie = false})
register_ai({id = "nuyan_jd_huituo", mode = "huituo", classic = true, jie = false})
register_ai({id = "nuyan_tianshu", mode = "tianshu", classic = false, jie = false})
register_ai({id = "nuyan_jd_tianshu", mode = "tianshu", classic = true, jie = false})
register_ai({id = "nuyan_xiaoguo", mode = "xiaoguo", classic = false, jie = false})
register_ai({id = "nuyan_jd_xiaoguo", mode = "xiaoguo", classic = true, jie = false})
register_ai({id = "nuyan_wenji", mode = "wenji", classic = false, jie = false})
register_ai({id = "nuyan_jd_wenji", mode = "wenji", classic = true, jie = false})
register_ai({id = "nuyan_benxi", mode = "benxi", classic = false, jie = false})
register_ai({id = "nuyan_jd_benxi", mode = "benxi", classic = true, jie = false})
register_ai({id = "nuyan_qinzheng", mode = "qinzheng", classic = false, jie = false})
register_ai({id = "nuyan_jd_qinzheng", mode = "qinzheng", classic = true, jie = false})
register_ai({id = "nuyan_huiling", mode = "huiling", classic = false, jie = false})
register_ai({id = "nuyan_jd_huiling", mode = "huiling", classic = true, jie = false})
register_ai({id = "nuyan_xizhan", mode = "xizhan", classic = false, jie = false})
register_ai({id = "nuyan_jd_xizhan", mode = "xizhan", classic = true, jie = false})
ai_skill_invoke["nuyan_bond_dianwei_2"] = true
ai_skill_invoke["nuyan_bond_yuanshao_1"] = true
ai_skill_invoke["nuyan_bond_yuanshao_2"] = true
ai_skill_invoke["nuyan_bond_guojia_1"] = true
ai_skill_invoke["nuyan_bond_guojia_3"] = true
ai_skill_invoke["nuyan_bond_xiahouyuan_2"] = true
ai_skill_invoke["nuyan_bond_xiahouyuan_3"] = true
ai_skill_invoke["nuyan_bond_caozhi_2"] = true
ai_skill_invoke["nuyan_bond_huangzhong_2"] = true
ai_skill_invoke["nuyan_bond_zhangfei_2"] = true
ai_skill_invoke["nuyan_bond_weiyan_2"] = true
ai_skill_invoke["nuyan_bond_liushan_2"] = true
ai_skill_invoke["nuyan_bond_xiaoqiao_2"] = true
ai_skill_invoke["nuyan_bond_lvmeng_2"] = true
ai_skill_invoke["nuyan_bond_dongzhuo_2"] = true
ai_skill_invoke["nuyan_bond_dongzhuo_3"] = true
ai_skill_invoke["nuyan_bond_yanliang_3"] = true
ai_skill_invoke["nuyan_bond_simayi_2"] = true
ai_skill_invoke["nuyan_bond_xunyu_2"] = true
ai_skill_invoke["nuyan_bond_xunyou_1"] = true
ai_skill_invoke["nuyan_bond_liubei_2"] = true
ai_skill_invoke["nuyan_bond_huangyueying_2"] = true
ai_skill_invoke["nuyan_bond_jiangwei_2"] = true
ai_skill_invoke["nuyan_bond_mayunlu_2"] = true
ai_skill_invoke["nuyan_bond_pangtong_1"] = true
ai_skill_invoke["nuyan_bond_pangtong_3"] = true
ai_skill_invoke["nuyan_bond_xushu_2"] = true
ai_skill_invoke["nuyan_bond_liaohua_2"] = true
ai_skill_invoke["nuyan_bond_sunquan_3"] = true
ai_skill_invoke["nuyan_bond_lingcao_2"] = true
ai_skill_invoke["nuyan_bond_sunjian_2"] = true
ai_skill_invoke["nuyan_bond_zhoutai_2"] = true
ai_skill_invoke["nuyan_bond_zhugeke_2"] = true
ai_skill_invoke["nuyan_bond_diaochan_2"] = true
ai_skill_invoke["nuyan_bond_zhangjiao_1"] = true
ai_skill_invoke["nuyan_bond_zhangjiao_3"] = true
ai_skill_invoke["nuyan_bond_zhurong_1"] = true
ai_skill_invoke["nuyan_bond_zhurong_2"] = true
ai_skill_invoke["nuyan_bond_menghuo_1"] = true
ai_skill_invoke["nuyan_bond_menghuo_2"] = true
ai_skill_invoke["nuyan_bond_huatuo_2"] = true
ai_skill_invoke["nuyan_bond_chengong_2"] = true
ai_skill_invoke["nuyan_bond_caifuren_2"] = true
ai_skill_invoke["nuyan_bond_yuanshu_2"] = true
ai_skill_invoke["nuyan_bond_jushou_2"] = true
ai_skill_invoke["nuyan_bond_zhenji_2"] = true
ai_skill_invoke["nuyan_bond_caopi_2"] = true
ai_skill_invoke["nuyan_bond_xinxianying_2"] = true
ai_skill_invoke["nuyan_bond_xizhicai_1"] = true
ai_skill_invoke["nuyan_bond_xizhicai_3"] = true
ai_skill_invoke["nuyan_bond_zhaoyun_1"] = true
ai_skill_invoke["nuyan_bond_zhaoyun_2"] = true
ai_skill_invoke["nuyan_bond_sunce_3"] = true
ai_skill_invoke["nuyan_bond_bulianshi_2"] = true
ai_skill_invoke["nuyan_bond_taishici_2"] = true
ai_skill_invoke["nuyan_bond_sunhao_2"] = true
ai_skill_invoke["nuyan_bond_lvbu_2"] = true
ai_skill_invoke["nuyan_bond_caiwenji_2"] = true
ai_skill_invoke["nuyan_bond_jiaxu_2"] = true
ai_skill_invoke["nuyan_bond_yuji_2"] = true
ai_skill_invoke["nuyan_bond_yuji_3"] = true
ai_skill_invoke["nuyan_bond_liuqi_2"] = true
sgs.ai_skill_cardask["nuyan_discard"] = function(self, data, pattern, target)
    local t = cards_of(self.player); self:sortByKeepValue(t)
    for _, c in ipairs(t) do
        if not self.player:isJilei(c) and not c:isKindOf("Peach") and sgs.Sanguosha:matchExpPattern(pattern, self.player, c) then return "$" .. c:getEffectiveId() end
    end
    return "."
end
ai_skill_invoke["nuyan_bond_xiahoudun_1"] = true
ai_skill_invoke["nuyan_bond_fazheng_1"] = true
ai_skill_invoke["nuyan_bond_fazheng_3"] = true
ai_skill_invoke["nuyan_bond_dengai_3"] = true
ai_skill_invoke["nuyan_bond_caozhi_1"] = true
ai_skill_invoke["nuyan_bond_caozhi_3"] = true
ai_skill_invoke["nuyan_bond_liushan_1"] = true
ai_skill_invoke["nuyan_bond_dongzhuo_1"] = true
ai_skill_invoke["nuyan_bond_caocao_1"] = true
ai_skill_invoke["nuyan_bond_yujin_1"] = true
ai_skill_invoke["nuyan_bond_liubei_1"] = true
ai_skill_invoke["nuyan_bond_jiangwei_1"] = true
ai_skill_invoke["nuyan_bond_xushu_1"] = true
ai_skill_invoke["nuyan_bond_sunshangxiang_3"] = true
ai_skill_invoke["nuyan_bond_diaochan_1"] = true
ai_skill_invoke["nuyan_bond_liuxie_1"] = true
ai_skill_invoke["nuyan_bond_gongsunzan_3"] = true
ai_skill_invoke["nuyan_bond_gaoshun_1"] = true
ai_skill_invoke["nuyan_bond_jushou_3"] = true
ai_skill_invoke["nuyan_bond_zhenji_3"] = true
ai_skill_invoke["nuyan_bond_caopi_1"] = true
ai_skill_invoke["nuyan_bond_xinxianying_1"] = true
ai_skill_invoke["nuyan_bond_zhaoyun_3"] = true
ai_skill_invoke["nuyan_bond_zhaoxiang_1"] = true
ai_skill_invoke["nuyan_bond_sunce_1"] = true
ai_skill_invoke["nuyan_bond_taishici_1"] = true
ai_skill_invoke["nuyan_bond_sunhao_1"] = true
ai_skill_invoke["nuyan_bond_caiwenji_1"] = true
ai_skill_invoke["nuyan_bond_liru_3"] = true
ai_skill_invoke["nuyan_bond_lingju_1"] = true
ai_skill_invoke["nuyan_bond_lvlingqi_1"] = true
ai_skill_invoke["nuyan_bond_lvlingqi_3"] = true
ai_skill_invoke["nuyan_bond_yuejin_1"] = true
ai_skill_invoke["nuyan_bond_yuejin_3"] = true
ai_skill_invoke["nuyan_bond_wuyi_1"] = true
ai_skill_invoke["nuyan_lianhuayiyi"] = true
ai_skill_invoke["nuyan_miaojianxuanwei"] = true
