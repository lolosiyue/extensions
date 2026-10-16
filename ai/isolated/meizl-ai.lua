-- Fixed b6025acc meizl. Native simulations are readonly; final selected
-- materials are rebound through issued scopes. No source registry fallback.
local function known(v,k)
    if AIUnsupported.is(v) then error(v,0) end
    if v==nil then ai_unsupported('Meizl missing '..k,'meizl') end
    return v
end
local function copy(v)
    if type(v)~='table' then return v end
    local r={};for k,x in pairs(v) do r[k]=copy(x) end;return r
end
local preview_specs=setmetatable({},{__mode='k'})
local resolve_preview
local function source_query(o,m,...)
    if AIValue.isPlayer(o) then
        if m=='getMark' then m='getStrategyMark' elseif m=='hasFlag' then m='getStrategyFlag' end
    end
    local args={...};for i=1,select('#',...) do if preview_specs[args[i]] then args[i]=resolve_preview(args[i]) end end
    return (AIValue.callKnown(o, m, table.unpack(args,1,select('#',...))))
end
local function dummy(isDummy,extra,current)
    return AIUsePlan.new({isDummy=isDummy~=false,extra_target=extra,current_targets=current})
end
local function pattern_names(self,class)
    if type(class)=='string'then
        local mapping=known(AICardCatalog.patternClassNames(),'exact last-write class/name catalog')
        return mapping[class] or class
    end
    return known(AICardCatalog.patternNames(),'pattern names')
end
local function printed(self,name)
    return self:cloneEvaluationCard(name or 'slash')
end
local function preview(self,name,skill,suit,number)
    local base=printed(self,name);if not base then return nil end
    local row=copy(known(rawget(base,'_view'),'printed descriptor'))
    row.evaluation_only=true;row.conversion_id=nil;row.subcards={};row.skill_name=skill or '';row.skill_names={skill or ''}
    local c=known(CardView.new(row),'readonly prototype')
    local st={ai=self,name=base:objectName(),skill=skill or '',suit=suit or sgs.Card_NoSuit,number=number or 0,costs={},base=base}
    preview_specs[c]=st
    c.getSubcards=function()return AIList.new(copy(st.costs))end
    c.subcardsLength=function()return #st.costs end
    c.getSkillName=function(_,remove)return remove~=false and st.skill:gsub('^_','') or st.skill end
    c.getSkillNames=function()return AIList.new({st.skill:gsub('^_','')})end
    c.deleteLater=function()end -- Pure allocations have no native lifetime.
    for _,method in ipairs({'isAvailable','isLocked','isJilei','isLimited','getSuit','getSuitString','getNumber','getNumberString','getEffectiveId','isBlack','isRed','sameColorWith','getColor','getColorString','toString','getLegacyStringKey','getLegacySortKey','getTargetResidue','getTargetModResidue','getTargetModDistance','getTargetModExtra','targetFixed','targetFilter','canRecast'}) do
        local m=method;c[m]=function(_,...)local r=resolve_preview(c);return AIValue.callKnown(r, m, ...)end
    end
    c.toCardSpec=function()ai_unsupported('readonly draft has no payment authority','meizl')end
    return c
end
resolve_preview=function(c)
    local st=preview_specs[c];if not st then return c end
    if st.cached then return st.cached end
    if st.suit~=sgs.Card_NoSuit or st.number~=0 then
        ai_unsupported('readonly clone requires exact nondefault suit/number projection','meizl.preview')
    end
    local r
    if st.skill=='' and #st.costs==0 then r=st.base
    elseif st.skill=='meizl_o_yuxiang' then
        r=source_query(st.ai, 'evaluateOwnerViewAsCard', {source_key='meizl_o_yuxiang',skill=st.skill,name=st.name,
            suit=st.suit,number=st.number,subcards=copy(st.costs)})
    else r=source_query(st.ai, 'evaluateSkillCard', st.skill, st.name, st.costs) end
    if st.recast~=nil and source_query(r, 'canRecast')~=st.recast then
        ai_unsupported('readonly setCanRecast hypothesis is unavailable','meizl.preview')
    end
    st.ai:inheritLegacyCardIdentity(r,c)
    st.cached=r
    return r
end
local function mutate(self,c,kind,value)
    local st=preview_specs[c]
    if not st then
        ai_unsupported('mutable SkillCard seed requires exact selected-cost evaluation','meizl.'..kind)
    end
    st.cached=nil
    if kind=='skill' then st.skill=value;c._view.skill_name=value;c._view.skill_names={value}
    elseif kind=='add' then st.costs[#st.costs+1]=type(value)=='number' and value or value:getKnownEffectiveId()
    elseif kind=='clear' then st.costs={}
    elseif kind=='recast' then st.recast=value
    else ai_unsupported('unknown draft mutation','meizl') end
    return c
end
local function meizl_use_card(self,c,use)
    c=resolve_preview(c)
    if c and c:isEvaluationOnly() then return self:evaluateCard(c,use) end
    return self:aiUseCard(c,use)
end
local function select_preview(self,c,request)
    local st=preview_specs[c];if not st then return c end
    local r=resolve_preview(c)
    return source_query(self, 'bindTurnConversion', st.skill, r:getClassName(), {name=st.name,skill_name=st.skill,suit=r:getSuit(),number=r:getNumber(),subcards=copy(st.costs)}, request)
end
local function target_ok(c,from,to,prefix)
    return CanToCard(resolve_preview(c),from,to,prefix)
end
local function scope(self,key)
    if key=='CurrentDamageStruct'then
        -- The room tag reaches only asks that project it as their context damage.
        local raw=type(self.request.options)=='table' and self.request.options.context
        return known(type(raw)=='table' and raw.damage or nil,key)
    end
    local row=source_query(self, 'getDecisionContext').meizl
    if type(row)~='table' then ai_unsupported('Meizl scoped context unavailable',key) end
    return known(row[key],key)
end
local function player(self,name)
    if name==false or name=='' then return nil end
    return source_query(self.room, 'findPlayerByObjectName', name)
end
local function scoped_player(self,key)return player(self,scope(self,key))end
local function scoped_struct(self,key,kind)
    local row=scope(self,key);if row==false then
        if kind=='use'then return {to=AIList.new({})}end
        -- QVariant::value<DamageStruct>() default constructor, not absent nil.
        return {damage=1,nature=sgs.DamageStruct_Normal,chain=false,transfer=false,by_user=true,prevented=false,ignore_hujia=false,reason='',transfer_reason=''}
    end
    local r=copy(row)
    for _,k in ipairs({'from','who'}) do if row[k] then r[k]=player(self,row[k]) end end
    if kind=='use' then r.to=AIList.new({});for _,n in ipairs(known(row.to,key..' targets'))do r.to:append(player(self,n))end
    elseif row.to then r.to=player(self,row.to) end
    if row.card then r.card=known(CardView.new(row.card),key..' card');r.card._evaluation_candidate=row.card.evaluation_candidate end
    return r
end
local function scope_list(self,key)return AIList.new(copy(scope(self,key)))end
local function known_card(self,id)
    id=tonumber(id);if not id then return nil end
    if self.request.kind=='amazing_grace' or self.request.kind=='guanxing' then
        for _,x in ipairs(self.request.options.card_ids or {}) do if x==id then
            local c=source_query(self, 'getChoiceCard', id);return self:getAcquiredCardEvaluation(c) or c
        end end
    end
    return source_query(self, 'getKnownCardById', id)
end
local function role_count(self,k)return known(known(known(self.world.mode_policy,'role policy').role_counts,'role counts')[k],'role count '..k)end
local function trigger_skill(self,name)
    for _,p in ipairs(self.room:getPlayers())do for _,s in ipairs(source_query(p, 'getVisibleSkillList'))do
        if s:objectName()==name then
            return {hasEvent=function(_,event)return source_query(s, 'hasTriggerEvent', event)end}
        end
    end end
    -- Trigger skills nobody visible holds are not projected.
    ai_unsupported('public trigger-skill definition unavailable',name)
end
local function role_estimate(self,p)return source_query(self, 'getRoleEstimate', p)end
local function set_choice(self,key,value)
    self:setStrategyMemory('meizl.choice.'..key,value)
    self:useKnowledgeEstimate({value=true,status='estimate',basis='meizl.shared_choice_viewer_partition'},key)
end
local function get_choice(self,key)
    local v,yes=self:getStrategyMemory('meizl.choice.'..key)
    if not yes then ai_unsupported('shared source choice has not been observed by this viewer',key)end
    self:useKnowledgeEstimate({value=true,status='estimate',basis='meizl.shared_choice_viewer_partition'},key)
    return v
end
local function strategy_flag(self,p,flag)
    if flag=='InfinityAttackRange' or flag=='-InfinityAttackRange' then
        ai_unsupported('readonly InfinityAttackRange hypothesis missing','meizl')
    end
    self:setStrategyPlayerFlag(p,flag,true)
end

local function BeMan(room,owner,dead)
    if AIValue.isPlayer(owner)then owner=owner:objectName()end
    for _,p in ipairs(source_query(room, 'getPlayers'))do if p:objectName()==owner then return p end end
end

local first_skill_index=#sgs.ai_skills
local function addAiSkills(name)local r={name=name};table.insert(sgs.ai_skills,r);return r end
local function use_slash(self,c,use)return self:useCardSlash(resolve_preview(c),use)end
local function translated(s)ai_unsupported('public translation is not projected','meizl')end
local function source_suit(skill)
    local value,yes=SmartAIView.getSourceSuitValueTable({},skill)
    if not yes then ai_unsupported('fixed suit metadata unavailable',skill)end
    return value
end
local function card_flag(self,c,flag)return known(self:hasStrategyCardFlag(c,flag),'card flag '..flag)end
local function scoped_card(self,key)local row=scope(self,key);if row==false then return nil end;return known(CardView.new(row),key)end
local function scoped_data(self,key,kind)return{toCardUse=function()return scoped_struct(self,key,kind)end}end

sgs.ai_event_callback[sgs.PreCardUsed]=sgs.ai_event_callback[sgs.PreCardUsed]or{}

local function scoped_extra_targets(self,key)
    local names=scope(self,key);if not AIValue.isList(names)then ai_unsupported('exact native target list unavailable',key)end
    local out=AIList.new({});for _,name in ipairs(names)do out:append(player(self,name))end;return out
end

local function visible_hand(self,p)
    if p==self.player then return source_query(p, 'getHandcards')end
    -- This one donor loop independently checks visible/viewer-visible flags.
    -- Unseen cards cannot pass either predicate; no hidden face is requested.
    return source_query(p, 'getKnownCards')
end

local function lawful_role(self,p)
    local role=p:getRole()
    if type(role)=='string'and role~=''then return role end
    return self:useKnowledgeEstimate({value=known(self:getRoleEstimate(p),'viewer role estimate'),status='estimate',basis='meizl.hujiajh_foreign_role_estimate'},'meizl.hujiajh')
end

local action_skills={["#guyan"]="guyan",["#meichunjiefulicard"]="meichunjiefuli",["#meispliwucard"]="meispliwu",["#meispruixuecard"]="meispruixue",["#meispshliwucard"]="meispshliwu",["#meispshruixuecard"]="meispshruixuecard",["#meizlbiyicard"]="meizlbiyi",["#meizlbiyincard"]="meizlbiyin",["#meizlchanhuocard"]="meizlchanhuo",["#meizlganzhengcard"]="meizlganzheng",["#meizlguihancard"]="meizlguihan",["#meizlhuawucard"]="meizlhuawu",["#meizlhujiacard"]="meizlhujia",["#meizljianwucard"]="meizljianwu",["#meizljiaoraocard"]="meizljiaorao",["#meizlkuangjicard"]="meizlkuangji",["#meizlkujingguhuncard"]="meizlkujingguhun",["#meizllipocard"]="meizllipo",["#meizlluohongcard"]="meizlluohong",["#meizlluoyingbinfencard"]="meizlluoyingbinfen",["#meizlmengshilongcard"]="meizlmengshilong",["#meizlmihuncard"]="meizlmihun",["#meizlmijiancard"]="meizlmijian",["#meizlmosicard"]="meizlmosi",["#meizlqingyancard"]="meizlqingyan",["#meizlrangdoucard"]="meizlrangdou",["#meizlseaomancard"]="meizlseaoman",["#meizlsebaonucard"]="meizlsebaonu",["#meizlsebaoshicard"]="meizlsebaoshi",["#meizlsedangyangcard"]="meizlsedangyang",["#meizlsejiducard"]="meizlsejidu",["#meizlselanduocard"]="meizlselanduo",["#meizlselianyucard"]="meizlselianyu",["#meizlsepoxiaocard"]="meizlsepoxiao",["#meizlsetanlancard"]="meizlsetanlan",["#meizlseyinyucard"]="meizlseyinyu",["#meizlseyoushacard"]="meizlseyousha",["#meizlshguihancard"]="meizlshguihan",["#meizlshhujiacard"]="meizlshhujia",["#meizlshqingyancard"]="meizlshqingyan",["#meizlshtuogucard"]="meizlshtuogu",["#meizlshzefucard"]="meizlshzefu",["#meizltuogucard"]="meizltuogu",["#meizlwuyincard"]="meizlwuyin",["#meizlwuzhijingjichangcard"]="meizlwuzhijingjichang",["#meizlyangxiucard"]="meizlyangxiu",["#meizlyanranyixiaocard"]="meizlyanranyixiao",["#meizlyincaicard"]="meizlyincai",["#meizlyuezhanyueqiangcard"]="meizlyuezhanyueqiang",["#meizlyujuecard"]="meizlyujue",["#meizlzefucard"]="meizlzefu",["#meizlzenhuicard"]="meizlzenhui",["#meizlzhaojiecard"]="meizlzhaojie",["#meizlzhaoxucard"]="meizlzhaoxu",["#meizlzhenhunqucard"]="meizlzhenhunqu",["#meizlzhenshicard"]="meizlzhenshi",["#meizlzhinangcard"]="meizlzhinang",["#meizlzhixicard"]="meizlzhixi",["#shijun"]="shijun"}
local action_specs=setmetatable({},{__mode='k'})
local function cost_ids(text)
    local ids={};if text=='' or text=='.' then return ids end
    for item in text:gmatch('[^+]+')do
        local n=tonumber(item)
        if not n or n<0 or n%1~=0 then return nil end
        ids[#ids+1]=n
    end
    return ids
end
local function parse_action(self,wire)
    local class,costs,user=wire:match('^(#[%w_]+):([^:]*):(.*)$')
    if not class then
        local name,skill,suit,number,ids=wire:match('^([%w_]+):([%w_]+)%[([%w_]+):([%w_%-]+)%]=(.*)$')
        if not name then return nil end -- Original malformed LuaSkillCard::Parse.
        local ns={spade=0,club=1,heart=2,diamond=3,no_suit_red=4,no_suit_black=5,no_suit=6}
        local nn={A=1,J=11,Q=12,K=13};number=tonumber(number)or nn[number]
        local cs=cost_ids(ids);if not cs or not number then return nil end
        if self._meizl_stage=='fill' then
            local draft=preview(self,name,skill,ns[suit] or sgs.Card_NoSuit,number)
            if not draft then return nil end
            for _,id in ipairs(cs)do mutate(self,draft,'add',id)end
            return draft
        end
        local actual_suit=ns[suit]or sgs.Card_NoSuit
        if actual_suit==sgs.Card_NoSuit and #cs>0 then
            actual_suit=(known_card(self,cs[1])):getSuit()
            if #cs>1 then
                local red,black=true,true
                for _,id in ipairs(cs)do local c=known_card(self,id);red=red and c:isRed();black=black and c:isBlack()end
                actual_suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit
            end
        end
        if number<=0 and #cs==1 then number=(known_card(self,cs[1])):getNumber()end
        local face=known(printed(self,name),'parsed printed class')
        return source_query(self, 'bindTurnConversion', skill, face:getClassName(), {name=name,skill_name=skill,suit=actual_suit,number=number,subcards=cs}, self._meizl_request)
    end
    local skill=known(action_skills[class],'source skill for '..class)
    local ids=cost_ids(costs);if not ids then return nil end
    local r
    if self._meizl_stage=='fill' and #ids==0 and user=='' then
        r=source_query(self, 'legacySkillSeed', skill, class, self._meizl_request)
        action_specs[r]={skill=skill,class=class,costs=ids,user=user,request=self._meizl_request}
    else
        r=source_query(self, 'bindSkillCard', skill, ids, self._meizl_request, user~=''and user or nil, class)
    end
    return r
end
local original_mutate=mutate
mutate=function(self,c,kind,value)
    local st=action_specs[c]
    if not st then return original_mutate(self,c,kind,value)end
    if kind=='add' then st.costs[#st.costs+1]=type(value)=='number'and value or value:getKnownEffectiveId()
    elseif kind=='clear' then st.costs={}
    else ai_unsupported('source SkillCard mutation unavailable',kind)end
    -- Only the strategy seed's local getters change; no native receipt exists.
    c.getSubcards=function()return AIList.new(copy(st.costs))end
    c.subcardsLength=function()return #st.costs end
    return c
end
local function materialize_action(self,c,request)
    local st=action_specs[c]
    if not st then return select_preview(self,c,request)end
    local r=source_query(self, 'bindSkillCard', st.skill, st.costs, request or st.request, st.user~=''and st.user or nil, st.class)
    return self:inheritLegacyCardIdentity(r,c)
end
local function clone_preview(self,name,suit,number)return preview(self,name,'',suit or sgs.Card_NoSuit,number or 0)end
local function printed_card(self,id)return source_query(self, 'getPrintedCardById', id)end
local function card_fact(self,c,key)
    ai_unsupported('printed card properties are not projected',key)
end
local function property_value(self,p,key)
    -- Only the viewer's own properties are projected; others raise unsupported.
    return source_query(p, 'getPropertyValue', key)
end
local function visible_top_id(self)
    ai_unsupported('draw pile top card is not projected','meizl')
end
local function judge_pattern(self,key)
    local patterns,yes=self:getEventMemory('judge_patterns')
    if not yes then ai_unsupported('judgestring source history unknown','zhiming')end
    local row=patterns[key];if not row then return nil end
    return {known(row.pattern,'judge pattern'),known(row.pattern_good,'judge polarity')}
end
local function scoped_judge(self,key)
    local row=scope(self,key)
    if row==false then return nil end
    if type(self.getScopedJudge)~='function' then ai_unsupported('exact named judge and candidate outcomes missing',key)end
    return self:getScopedJudge(row)
end
local function pack_state(self,value)
    if AIValue.isPlayer(value)then return{kind='player',name=value:objectName()}end
    if AIValue.isCard(value)or AIValue.isConversion(value)then
        return{kind='card',value=self:capturePriorTurnPlan(resolve_preview(value))}
    end
    if type(value)=='table'then local r={kind='table',value={}};for k,v in pairs(value)do r.value[k]=pack_state(self,v)end;return r end
    if value==nil then return{kind='nil'}end
    if type(value)~='string'and type(value)~='number'and type(value)~='boolean'then ai_unsupported('nonvalue source cache','meizl')end
    return{kind='scalar',value=value}
end
local function unpack_state(self,row)
    if row.kind=='nil'then return nil end
    if row.kind=='scalar'then return row.value end
    if row.kind=='player'then return player(self,row.name)end
    if row.kind=='card'then return self:restorePriorTurnPlan(row.value)end
    if row.kind=='table'then local r={};for k,v in pairs(row.value)do r[k]=unpack_state(self,v)end
        if AIValue.isList(r)then return AIList.new(r)end;return r end
    ai_unsupported('malformed viewer cache','meizl')
end
local function set_state(self,key,value)
    if key=='friend_maxSlash'then self:useKnowledgeEstimate({value=true,status='estimate',basis='meizl.friend_maxSlash_viewer_local_global'},'findyoushaTarget')end
    self[key]=value
    if key=='kannan_card'then self:remember(key,value and value:getKnownEffectiveId())end
    self:setStrategyMemory('meizl.state.'..key,{value=pack_state(self,value),estimates=copy(self.request.scratch.knowledge_estimates or{})})
end
local function get_state(self,key)
    if key=='friend_maxSlash'then self:useKnowledgeEstimate({value=true,status='estimate',basis='meizl.friend_maxSlash_viewer_local_global'},'findyoushaTarget')end
    if rawget(self,key)~=nil then return self[key]end
    local row,yes=self:getStrategyMemory('meizl.state.'..key)
    if not yes then return nil end
    if type(row)~='table'or type(row.value)~='table'then ai_unsupported('viewer cache malformed',key)end
    for _,entry in ipairs(row.estimates or{})do entry=copy(entry);entry.status='estimate';entry.value=true;self:useKnowledgeEstimate(entry,'meizl.cached')end
    self[key]=unpack_state(self,row.value)
    return self[key]
end

local function invoke_peiqi(self,data)
    local fn=sgs.ai_skill_invoke.peiqi
    if type(fn)~='function'then ai_unsupported('effective Peiqi policy is not loaded','meizl.sp_kongju')end
    local ok,result=pcall(fn,self,data)
    if self.peiqiData then set_state(self,'peiqiData',self.peiqiData)end
    if not ok then error(result,0)end
    return result
end


sgs.ai_skill_use["@@meizlchunshen"] = function(self, data, method)
    if not method then method = sgs.Card_MethodDiscard end
    local dmg
    local to_discard = {}

    if data == "@meizlchunshen-card" then
        dmg = scoped_struct(self,"meizlchunshenDamage","damage")
    else
        dmg = data
    end

    if not dmg then

        return "."
    end

    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards, true)
    self:sortByUseValue(cards, true)

    for _, card in ipairs(cards) do
        if not card:isKindOf("Peach") then
            if #to_discard == 2 then break end
            table.insert(to_discard, card:getKnownEffectiveId())
        end
    end
    if #to_discard < 2 then return "." end

    self:sort(self.enemies, "hp")

    for _, enemy in ipairs(self.enemies) do
        if (enemy:isAlive()) and source_query(self.player, "inMyAttackRange", enemy) and enemy:getHp() >= self.player:getHp() then
            if source_query(self, "canAttack", enemy, dmg.from or self.room:getCurrent(), dmg.nature)
                and not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan")) then
                return "#meizlchunshencard:" .. table.concat(to_discard, "+") .. ":->" .. enemy:objectName()
            end
        end
    end

    for _, friend in ipairs(self.friends_noself) do
        if (friend:isAlive()) and source_query(self.player, "inMyAttackRange", friend) and friend:getHp() >= self.player:getHp() then
            if friend:isChained() and dmg.nature ~= sgs.DamageStruct_Normal and not self:isGoodChainTarget(friend, dmg.from, dmg.nature, dmg.damage, dmg.card) then
            elseif (friend:hasSkills("yiji|buqu|nosbuqu|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu")
                    or source_query(self, "needToLoseHp", friend)) then
                return "#meizlchunshencard:" .. table.concat(to_discard, "+") .. "->" .. friend:objectName()
            elseif dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and friend:hasSkill("wuyan") and friend:getLostHp() > 1 then
                return "#meizlchunshencard:" .. table.concat(to_discard, "+") .. "->" .. friend:objectName()
            elseif hasBuquEffect(friend) then
                return "#meizlchunshencard:" .. table.concat(to_discard, "+") .. ":->" .. friend:objectName()
            end
        end
    end

    for _, enemy in ipairs(self.enemies) do
        if enemy:isAlive() and source_query(self.player, "inMyAttackRange", enemy) and enemy:getHp() >= self.player:getHp() then
            if source_query(self, "canAttack", enemy, (dmg.from or self.room:getCurrent()), dmg.nature)
                and not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan")) then
                return "#meizlchunshencard:" .. table.concat(to_discard, "+") .. ":->" .. enemy:objectName()
            end
        end
    end

    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        if not enemy:isWounded() and not self:hasSkills(sgs.masochism_skill, enemy) and enemy:isAlive() and source_query(self.player, "inMyAttackRange", enemy) and enemy:getHp() >= self.player:getHp()
            and source_query(self, "canAttack", enemy, dmg.from or self.room:getCurrent(), dmg.nature)
            and (not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan") and enemy:getLostHp() > 0) or self:isWeak()) then
            return "#meizlchunshencard:" .. table.concat(to_discard, "+") .. ":->" .. enemy:objectName()
        end
    end

    return "."
end

sgs.ai_card_intention.meizlchunshencard = function(self, card, from, tos)
    local to = tos[1]
    if source_query(self, "needToLoseHp", to) then return end
    local intention = 10
    if hasBuquEffect(to) then
        intention = 0
    elseif (to:getHp() >= 2 and to:hasSkills("yiji|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu"))
        or (to:getHandcardNum() < 3 and (to:hasSkill("nosrende") or (to:hasSkill("rende") and not to:getStrategyHasUsed("RendeCard")))) then
        intention = 0
    end
    self:updateIntention(from, to, intention)
end

function sgs.ai_slash_prohibit.meizlchunshen(self, from, to)
    if source_query(self, "hasJueqingEffect", from, to) or (from:hasSkill("nosqianxi") and source_query(from, "distanceTo", to) == 1) then return false end
    if from:getStrategyFlag("NosJiefanUsed") then return false end
    if self:isFriend(to, from) then return false end
    return source_query(self, "cantbeHurt", to, from)
end

function sgs.ai_cardneed.meizlchunshen(to, card, self)
    return to:getHandcardNum() < 3
end

sgs.ai_can_damagehp.meizlchunshen = function(self, from, card, to)
    local d = {damage=1,nature=sgs.DamageStruct_Normal}
    d.from = from
    d.to = to
    d.nature = card and sgs.card_damage_nature[card:getClassName()] or sgs.DamageStruct_Normal
    d.card = card
    return sgs.ai_skill_use["@@meizlchunshen"](self, d, sgs.Card_MethodDiscard) ~= "."
end

sgs.ai_hasTuntianEffect_skill.meizljinlian = function(to, need_zaoxian)
    return to:getPhase() == sgs.Player_NotActive
end


sgs.ai_target_revises.meizlchongyuan = function(to, card, self)
    return source_query(card, "isNDTrick") and self.player:isMale()
end


sgs.ai_skill_discard["meizlqiji"] = function(self, discard_num, min_num, optional, include_equip)
    local usable_cards = sgs.QList2Table(self.player:getCards("he"))
    local damage = scoped_struct(self,"CurrentDamageStruct","damage")
    local target = damage.from
    if target and not self:isFriend(target) then
        self:sortByKeepValue(usable_cards)
        local to_discard = {}
        for _, c in ipairs(usable_cards) do
            if #to_discard < discard_num and not c:isKindOf("Peach") then
                table.insert(to_discard, c:getKnownEffectiveId())
            end
        end
        if #to_discard > 0 then
            return to_discard
        end
    end
    return {}
end



function sgs.ai_slash_prohibit.meizlqiji(self, from, to)
    if self:isFriend(from, to) then return false end
    if source_query(self, "hasJueqingEffect", from, to) or (from:hasSkill("nosqianxi") and source_query(from, "distanceTo", to) == 1) then return false end
    if from:getStrategyFlag("NosJiefanUsed") then return false end
    return from:getHp() < 2
end

sgs.ai_can_damagehp.meizlqiji = function(self, from, card, to)
    if from and to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to) and card and card:isKindOf("Slash") and source_query(to, "getCardCount") > 0
    then
        return self:isEnemy(from) and self:isWeak(from)
    end
end

sgs.ai_skill_invoke.meizlrenru = function(self, data)
    return self:isWeak() or not self.player:faceUp()
end

sgs.ai_ajustdamage_to.meizlrenru = function(self, from, to, card, nature)
    if not to:faceUp()
    then
        return -99
    end
end


sgs.ai_skill_invoke.meizlguiyuan = function(self, data)
    local current = self.room:getCurrent()
    if current then
        return source_query(self, "doDisCard", current, "he")
    end
    return false
end
ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.meizlguiyuan",defer_canonical=true,self_index=1,registry="ai_choicemade_filter",path={"cardChosen","meizlguiyuan"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"}}

sgs.ai_hasTuntianEffect_skill.meizlguiyuan = function(to, need_zaoxian)
    return to:getPhase() == sgs.Player_NotActive
end

sgs.ai_getBestHp_skill.meizlwuqing = function(owner)
    return owner:getMaxHp() - 1
end


sgs.ai_skill_invoke.meizlfeiren = function(self, data)
    local effect = data:toCardEffect()
    if self:isEnemy(effect.to) then
        if source_query(self, "doDisCard", effect.to, "h", true) then
            return true
        end
        if self.player:getPile("meizlfeiren"):length() >= 2 then
            return source_query(self, "canAttack", effect.to, self.player) and source_query(self, "damageIsEffective", effect.to, sgs.DamageStruct_Normal, self.player) and not source_query(self, "cantbeHurt", effect.to)
        end

        return true
    elseif self:isFriend(effect.to) then
        if self.player:getPile("meizlfeiren"):length() >= 2 then
            return source_query(self, "isGoodTarget", effect.to, self.player)
        end
        return source_query(self, "doDisCard", effect.to, "h", true)
    end
    return false
end

ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.meizlfeiren",defer_canonical=true,self_index=1,registry="ai_choicemade_filter",path={"cardChosen","meizlfeiren"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"}}

sgs.ai_cardneed.meizlfeiren = function(to, card)
    return isCard("Slash", card, to)
end

sgs.ai_target_revises.meizlyuxiang = function(to, card)
    if card:isKindOf("SavageAssault")
    then
        return true
    end
end

sgs.ai_cardneed.meizlyuxiang = function(to, card)
    return card:isKindOf("SavageAssault")
end


sgs.ai_skill_playerchosen.meizlfujun = function(self, targets)
    local AssistTarget = self:AssistTarget()
    if AssistTarget and not source_query(self, "willSkipPlayPhase", AssistTarget) then
        return AssistTarget
    end

    self:sort(self.friends_noself, "chaofeng")
    for _, target in ipairs(self.friends_noself) do
        if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
            and (not source_query(self, "willSkipPlayPhase", target) or target:hasSkill("shensu")) then
            return target
        end
    end

    for _, target in ipairs(self.friends_noself) do
        if target:hasSkill("dawu") then
            local use = true
            for _, p in ipairs(self.friends_noself) do
                if p:getStrategyMark("@fog") > 0 then
                    use = false
                    break
                end
            end
            if use then
                return target
            end
        else
            return target
        end
    end
end

sgs.ai_playerchosen_intention.meizlfujun = -80

sgs.ai_can_damagehp.meizlfujun = function(self, from, card, to)
    if to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to) and source_query(to, "getCardCount") > 0
    then
        return self:getCardsNum("Peach") > 0 and #self.friends_noself > 0 and not source_query(self, "willSkipPlayPhase")
    end
end

sgs.ai_skill_playerchosen.meizlrangma = function(self, targets)
    local AssistTarget = self:AssistTarget()
    if AssistTarget and not source_query(self, "willSkipPlayPhase", AssistTarget) then
        return AssistTarget
    end

    self:sort(self.friends_noself, "chaofeng")
    for _, target in ipairs(self.friends_noself) do
        if target:hasSkills(sgs.cardneed_skill) and not hasManjuanEffect(target)
            and (not source_query(self, "willSkipPlayPhase", target) or target:hasSkill("shensu")) then
            return target
        end
    end
    for _, target in ipairs(self.friends_noself) do
        if not hasManjuanEffect(target) and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
            and (not source_query(self, "willSkipPlayPhase", target) or target:hasSkill("shensu")) then
            return target
        end
    end
    for _, target in ipairs(self.friends_noself) do
        if not hasManjuanEffect(target)
            and (not source_query(self, "willSkipPlayPhase", target) or target:hasSkill("shensu")) then
            return target
        end
    end
    for _, target in ipairs(self.friends_noself) do
        if not hasManjuanEffect(target) then
            return target
        end
    end
    for _, target in ipairs(self.friends_noself) do
        return target
    end
end

function sgs.ai_slash_prohibit.meizlrangma(self, from, to)
    if source_query(self, "hasJueqingEffect", from, to) or (from:hasSkill("nosqianxi") and source_query(from, "distanceTo", to) == 1) then return false end
    if from:getStrategyFlag("NosJiefanUsed") then return false end
    if self:isFriend(to, from) and self:isWeak(to) then return true end
    return #(self:getEnemies(from)) > 1 and self:isWeak(to) and from:getHandcardNum() > 3
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|meizlrangma"

local meizltuogu_skill = {}
meizltuogu_skill.name = "meizltuogu"
table.insert(sgs.ai_skills, meizltuogu_skill)
meizltuogu_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@meizltuogu") <= 0 then return end
    if #self.enemies <= 0 then return end
    local good, bad = 0, 0
    local lord = self.room:getLord()
    if lord and self.role ~= "rebel" and self:isWeak(lord) and lord:getKnownKingdom() ~= "shu" then return end
    for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if self:isFriend(player) then
            if player:getKnownKingdom() == "shu" and player:getHp() < getBestHp(player) then
                good = good + 1
            elseif player:getKnownKingdom() ~= "shu" then
                bad = bad + 1
                if hasZhaxiangEffect(player) and not hasManjuanEffect(player) and not source_query(self, "willSkipPlayPhase", player)
                    and (player:getHp() > 1 or source_query(self, "getAllPeachNum") > 0) then
                    good = good + 2
                end
            end
        else
            if player:getKnownKingdom() == "shu" and player:getHp() < getBestHp(player) then
                bad = bad + 1
            elseif player:getKnownKingdom() ~= "shu" and not hasZhaxiangEffect(player) then
                good = good + 1
                if self:isWeak(player) then
                    good = good + 1
                end
            elseif player:getKnownKingdom() ~= "shu" and hasZhaxiangEffect(player) then
                bad = bad + 2
            end
        end
    end
    bad = bad + self.player:getHp() + source_query(self, "getAllPeachNum")
    if good > bad then return parse_action(self,"#meizltuogucard:.:") end
end

sgs.ai_skill_use_func["#meizltuogucard"] = function(card, use, self,request)
    if self.role == "lord" then return end
    use.card = card
end

sgs.ai_skill_playerchosen.meizltuogu = function(self, targets)
    local arr1, arr2 = self:getWoundedFriend(false, true, sgs.QList2Table(targets))
    local target = nil

    if #arr1 > 0 and self:isWeak(arr1[1]) and arr1[1]:getHp() < getBestHp(arr1[1]) then target = arr1[1] end
    if target then
        return target
    end
    return nil
end


local meizllipo_skill = {}
meizllipo_skill.name = "meizllipo"
table.insert(sgs.ai_skills, meizllipo_skill)
meizllipo_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#meizllipocard") or self.player:isKongcheng() then return end
    return parse_action(self,"#meizllipocard:.:")
end
sgs.ai_skill_use_func["#meizllipocard"] = function(card, use, self,request)
    local targets = {}
    local target
    self:sort(self.enemies, "defense")
    self:sort(self.friends_noself, "defense")

    for _, friend in ipairs(self.friends_noself) do
        if friend:isMale() and not hasManjuanEffect(friend) and not friend:isKongcheng() then
            if hasTuntianEffect(friend, true) then
                target = friend
                break
            end
            if friend:hasSkill("enyuan") then
                target = friend
                break
            end
        end
    end
    if not target then
        for _, enemy in ipairs(self.enemies) do
            if enemy:isMale() then
                if hasManjuanEffect(enemy) and not enemy:isKongcheng() then
                    target = enemy
                    break
                end
            end
        end
    end
    if not target then
        for _, enemy in ipairs(self.enemies) do
            if enemy:isMale() then
                if not hasTuntianEffect(enemy, true) and not enemy:isKongcheng() then
                    target = enemy
                    break
                end
            end
        end
    end

    if target then
        use.card = card
        if use.to then
            use.to:append(target)
        end
    end
end

sgs.ai_use_priority["meizllipocard"] = 8

sgs.ai_skill_discard["meizllipocard"] = function(self, discard_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    local to_discard = {}
    local compare_func = function(a, b)
        return source_query(self, "getKeepValue", a) < source_query(self, "getKeepValue", b)
    end
    table.sort(cards, compare_func)
    for _, card in ipairs(cards) do
        if #to_discard >= discard_num then break end
        table.insert(to_discard, card:getKnownId())
    end

    return to_discard
end

sgs.ai_cardneed.meizllipo = function(to, card)
    return to:getHandcardNum() < 3
end


sgs.ai_skill_invoke.meizlduyan = function(self, data)

    local current = self.room:getCurrent()
    if not current or self:isFriend(current) then return false end

    local max_card = self:getMaxCard()
    local max_point = max_card:getNumber()
    if self.player:hasSkill("yingyang") then max_point = math.min(max_point + 3, 13) end
    if not (current:hasSkill("zhiji") and current:getStrategyMark("zhiji") == 0 and current:getHandcardNum() == 1) then
        local enemy_max_card = self:getMaxCard(current)
        local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
        if enemy_max_card and current:hasSkill("yingyang") then enemy_max_point = math.min(enemy_max_point + 3, 13) end
        if max_point > enemy_max_point or max_point > 10 then
            return true
        end
    end
    return false
end

function sgs.ai_skill_pindian.meizlduyan(minusecard, self, requestor)
    local maxcard = self:getMaxCard()
    return maxcard
end

ai_audited_aliases.register{id="ai_cardneed.meizlduyan",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlduyan"},canonical_registry="ai_cardneed",canonical_path={"bignumber"}}

sgs.ai_choicemade_filter.skillInvoke.meizlduyan = function(self, player, promptlist)
    local current = self.room:getCurrent()
    if promptlist[#promptlist] == "yes" then
        if current then
            self:updateIntention(player, current, 70)
        end
    end
end



local meizlzhaoxu_skill = {}
meizlzhaoxu_skill.name = "meizlzhaoxu"
table.insert(sgs.ai_skills, meizlzhaoxu_skill)
meizlzhaoxu_skill.getTurnUseCard = function(self)
    if #self.friends_noself == 0 then return end
    if not self.player:isKongcheng() and not self.player:getStrategyHasUsed("#meizlzhaoxucard") then
        return parse_action(self,"#meizlzhaoxucard:.:")
    end
end

sgs.ai_skill_use_func["#meizlzhaoxucard"] = function(card, use, self,request)
    self:sort(self.friends_noself, "handcard")
    local has_red = false
    local cards = sgs.QList2Table(self.player:getHandcards())
    for _, acard in ipairs(cards) do
        if acard:isRed() then
            has_red = true
            break
        end
    end
    if has_red then
        for _, friend in ipairs(self.friends_noself) do
            if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
                if friend:hasSkills(sgs.cardneed_skill) then
                    use.card = parse_action(self,"#meizlzhaoxucard:.:")
                    if use.to then use.to:append(friend) end
                    return
                end
                if getCardsNum("Slash", friend, self.player) + self:getCardsNum("Slash") > 1 then
                    use.card = parse_action(self,"#meizlzhaoxucard:.:")
                    if use.to then use.to:append(friend) end
                    return
                end
            end
        end
    end
end

sgs.ai_use_priority["meizlzhaoxucard"] = 10
sgs.ai_use_value["meizlzhaoxucard"] = 2.45
sgs.ai_card_intention.meizlzhaoxucard = -80

sgs.ai_skill_playerchosen.meizlzhuzhi = function(self, targets)
    local x = self.player:getStrategyMark("meizlzhuzhi")
    local n = x - 1
    self:updatePlayers()
    if x == 1 and #self.friends == 1 then
        for _, enemy in ipairs(self.enemies) do
            if hasManjuanEffect(enemy) then
                return enemy
            end
        end
        return nil
    end

    set_state(self,"yinghun",nil)
    local player = self:AssistTarget()

    if x == 1 then
        self:sort(self.friends_noself, "handcard")
        self.friends_noself = sgs.reverse(self.friends_noself)
        for _, friend in ipairs(self.friends_noself) do
            if self:hasSkills(sgs.lose_equip_skill, friend) and friend:getCards("e"):length() > 0
                and not hasManjuanEffect(friend) then
                set_state(self,"yinghun",friend)
                break
            end
        end
        if not get_state(self,"yinghun") then
            for _, friend in ipairs(self.friends_noself) do
                if hasTuntianEffect(friend, true) and not hasManjuanEffect(friend) and friend:getPhase() == sgs.Player_NotActive then
                    set_state(self,"yinghun",friend)
                    break
                end
            end
        end
        if not get_state(self,"yinghun") then
            for _, friend in ipairs(self.friends_noself) do
                if source_query(self, "needToThrowArmor", friend) and not hasManjuanEffect(friend) then
                    set_state(self,"yinghun",friend)
                    break
                end
            end
        end
        if not get_state(self,"yinghun") then
            for _, enemy in ipairs(self.enemies) do
                if hasManjuanEffect(enemy) then
                    return enemy
                end
            end
        end

        if not get_state(self,"yinghun") and player and not hasManjuanEffect(player) and source_query(player, "getCardCount", true) > 0 and not self:needKongcheng(player, true) then
            set_state(self,"yinghun",player)
        end

        if not get_state(self,"yinghun") then
            for _, friend in ipairs(self.friends_noself) do
                if friend:getCards("he"):length() > 0 and not hasManjuanEffect(friend) then
                    set_state(self,"yinghun",friend)
                    break
                end
            end
        end

        if not get_state(self,"yinghun") then
            for _, friend in ipairs(self.friends_noself) do
                if not hasManjuanEffect(friend) then
                    set_state(self,"yinghun",friend)
                    break
                end
            end
        end
    elseif #self.friends > 1 then
        self:sort(self.friends_noself, "chaofeng")
        for _, friend in ipairs(self.friends_noself) do
            if self:hasSkills(sgs.lose_equip_skill, friend) and friend:getCards("e"):length() > 0
                and not hasManjuanEffect(friend) then
                set_state(self,"yinghun",friend)
                break
            end
        end
        if not get_state(self,"yinghun") then
            for _, friend in ipairs(self.friends_noself) do
                if hasTuntianEffect(friend, true) and not hasManjuanEffect(friend) and friend:getPhase() == sgs.Player_NotActive then
                    set_state(self,"yinghun",friend)
                    break
                end
            end
        end
        if not get_state(self,"yinghun") then
            for _, friend in ipairs(self.friends_noself) do
                if source_query(self, "needToThrowArmor", friend) and not hasManjuanEffect(friend) then
                    set_state(self,"yinghun",friend)
                    break
                end
            end
        end
        if not get_state(self,"yinghun") and #self.enemies > 0 then
            local wf
            if source_query(self.player, "isLord") then
                if self:isWeak() and (self.player:getHp() < 2 and self:getCardsNum("Peach") < 1) then
                    wf = true
                end
            end
            if not wf then
                for _, friend in ipairs(self.friends_noself) do
                    if self:isWeak(friend) then
                        wf = true
                        break
                    end
                end
            end

            if not wf then
                self:sort(self.enemies, "chaofeng")
                for _, enemy in ipairs(self.enemies) do
                    if enemy:getCards("he"):length() == n
                        and source_query(self, "doDisCard", enemy, "he", false, n) then
                        set_state(self,"yinghunchoice","d1tx")
                        return enemy
                    end
                end
                for _, enemy in ipairs(self.enemies) do
                    if enemy:getCards("he"):length() >= n
                        and source_query(self, "doDisCard", enemy, "he", false, n)
                        and self:hasSkills(sgs.cardneed_skill, enemy) then
                        set_state(self,"yinghunchoice","d1tx")
                        return enemy
                    end
                end
            end
        end

        if not get_state(self,"yinghun") and player and not hasManjuanEffect(player) and not self:needKongcheng(player, true) then
            set_state(self,"yinghun",player)
        end

        if not get_state(self,"yinghun") then
            set_state(self,"yinghun",self:findPlayerToDraw(false, n))
        end
        if not get_state(self,"yinghun") then
            for _, friend in ipairs(self.friends_noself) do
                if not hasManjuanEffect(friend) then
                    set_state(self,"yinghun",friend)
                    break
                end
            end
        end
        if get_state(self,"yinghun") then set_state(self,"yinghunchoice","dxt1") end
    end
    if not get_state(self,"yinghun") and x > 1 and #self.enemies > 0 then
        self:sort(self.enemies, "handcard")
        for _, enemy in ipairs(self.enemies) do
            if enemy:getCards("he"):length() >= n
                and source_query(self, "doDisCard", enemy, "he", false, n) then
                set_state(self,"yinghunchoice","d1tx")
                return enemy
            end
        end
        self.enemies = sgs.reverse(self.enemies)
        for _, enemy in ipairs(self.enemies) do
            if not enemy:isNude()
                and not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards("e"):length() > 0)
                and not source_query(self, "needToThrowArmor", enemy)
                and not (hasTuntianEffect(enemy, true)) then
                set_state(self,"yinghunchoice","d1tx")
                return enemy
            end
        end
        for _, enemy in ipairs(self.enemies) do
            if not enemy:isNude()
                and not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards("e"):length() > 0)
                and not source_query(self, "needToThrowArmor", enemy)
                and not (hasTuntianEffect(enemy, true) and x < 3 and enemy:getCards("he"):length() < 2) then
                set_state(self,"yinghunchoice","d1tx")
                return enemy
            end
        end
    end

    return get_state(self,"yinghun")
end

sgs.ai_skill_choice.meizlzhuzhi = function(self, choices)
    return get_state(self,"yinghunchoice")
end


sgs.ai_skill_invoke.meizlsuxian = function(self, data)
    local target = data:toDamage().from

    if target and self:isFriend(target) then
        if self:getOverflow(target) > 2 then
            return true
        else
            return false
        end
    end
    return true
end

local meizlsuxian_skill = {}
meizlsuxian_skill.name = "meizlsuxian"
table.insert(sgs.ai_skills, meizlsuxian_skill)
meizlsuxian_skill.getTurnUseCard = function(self, inclusive)
    if (self.player:getStrategyMark("meizlsuxian") > 0) then
        local cards = self.player:getCards("he")
        cards = sgs.QList2Table(cards)
        local use_card
        local card_ex = known_card(self,self.player:getStrategyMark("meizlsuxiancard"))
        self:sortByUseValue(cards, true)
        for _, card in ipairs(cards) do
            if card:isRed() and not card:isKindOf("Peach") then
                use_card = card
            end
        end
        if use_card then
            if source_query(card_ex, "isAvailable", self.player) then
                mutate(self,card_ex,"skill","meizlsuxian")
                mutate(self,card_ex,"add",use_card)
                local card_str = string.format(card_ex:objectName() .. ":meizlsuxian:%s:", use_card:getKnownEffectiveId())
                return parse_action(self,card_str)
            end
        end
    end
end

sgs.ai_cardsview["meizlsuxian"] = function(self, class_name, player)
    if not (known(self.request.reason,"current card use reason") == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE or known(self.request.reason,"current card use reason") == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) then return end
    local classname2objectname = {
        ["Slash"] = "slash",
        ["Jink"] = "jink",
        ["Peach"] = "peach",
        ["Analeptic"] = "analeptic",
        ["Nullification"] = "nullification",
        ["FireSlash"] = "fire_slash",
        ["ThunderSlash"] = "thunder_slash"
    }
    local name = classname2objectname[class_name]
    if not name or not (self.player:getStrategyMark("meizlsuxian") > 0) then return end
    local card_ex = known_card(self,self.player:getStrategyMark("meizlsuxiancard"))
    if name ~= card_ex:objectName() then return end

    local no_have = true
    local cards = player:getCards("he")
    for _, id in sgs.qlist(player:getPile("wooden_ox")) do
        if known_card(self,id):isRed() and not known_card(self,id):isKindOf("Peach") then
            cards:prepend(known_card(self,id))
        end
    end
    for _, c in sgs.qlist(cards) do
        if c:isKindOf(class_name) then
            no_have = false
            break
        end
    end
    if not no_have then return end
    if class_name == "Peach" and player:getStrategyMark("Global_PreventPeach") > 0 then return end
    cards = sgs.QList2Table(cards)
    local needed = {}
    for _, acard in ipairs(cards) do
        if acard:isRed() then
            table.insert(needed, acard)
        end
    end
    self:sortByKeepValue(cards)
    if player:getPile("wooden_ox"):length() > 0 then
        for _, id in sgs.qlist(player:getPile("wooden_ox")) do
            if not known_card(self,id):isKindOf("Peach") then
                cards[1] = known_card(self,id)
            end
        end
    end
    if #cards == 0 then return end
    if #needed == 0 then return end



    local suit = needed[1]:getSuitString()
    local number = needed[1]:getNumberString()
    local card_id = needed[1]:getEffectiveId()
    if player:hasSkill("meizlsuxian") then
        return (name .. ":meizlsuxian[%s:%s]=%d"):format(suit, number, card_id)
    end
end

sgs.ai_use_revises.meizlsuxian = function(self, card, use)
    if card:isKindOf("EquipCard")
        and card:isRed()
    then
        local same = self:getSameEquip(card)
        if same and same:isRed()
        then
            return false
        end
    end
end

sgs.ai_can_damagehp.meizlsuxian = function(self, from, card, to)
    if from and to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to)
    then
        return self:isEnemy(from) and self:isWeak(from) and source_query(from, "getCardCount") > 0
    end
end

function sgs.ai_cardneed.meizlsuxian(to, card, self)
    return to:getHandcardNum() < 3 and card:isRed()
end

sgs.ai_skill_invoke.meizlcimin = function(self, data)
    local target = data:toPlayer()
    if target and self:isFriend(target) then
        if hasManjuanEffect(target) and #self.friends_noself > 1 then return false end
        if self:needKongcheng(self.player) then return true end
        if self:isWeak(self.player) then return false end
        if self:isWeak(target) then return true end
        if target:getHp() < getBestHp(target) then return true end
    end
    return false
end

sgs.ai_choicemade_filter.skillInvoke.meizlcimin = function(self, player, promptlist)
    local damage = scoped_struct(self,"CurrentDamageStruct","damage")
    if damage.to then
        if promptlist[#promptlist] == "yes" then
            self:updateIntention(player, damage.to, -80)
        end
    end
end

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|meizlcimin"
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|meizlcimin"


local meizlhujia_skill = {}
meizlhujia_skill.name = "meizlhujia"
table.insert(sgs.ai_skills, meizlhujia_skill)
meizlhujia_skill.getTurnUseCard = function(self)
    if source_query(self, "needBear") then return end
    if not self.player:getStrategyHasUsed("#meizlhujiacard") and not self.player:isKongcheng() then
        return parse_action(self,
            "#meizlhujiacard:.:")
    end
end

sgs.ai_skill_use_func["#meizlhujiacard"] = function(card, use, self,request)
    self:sort(self.enemies, "handcard")
    local max_card = self:getMaxCard(self.player)
    local max_point = max_card:getNumber()
    if self.player:hasSkill("kongcheng") and self.player:getHandcardNum() == 1 then
        for _, enemy in ipairs(self.enemies) do
            if not enemy:isKongcheng() and source_query(self.player, "canPindian", enemy) then
                use.card = parse_action(self,"#meizlhujiacard:.:")
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
    if (self:getOverflow() > 0) or (max_point > 9) then
        for _, enemy in ipairs(self.enemies) do
            if not enemy:isKongcheng() and source_query(self.player, "canPindian", enemy) then
                use.card = parse_action(self,"#meizlhujiacard:.:")
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end

function sgs.ai_skill_pindian.meizlhujiacard(minusecard, self, requestor)
    if self:isFriend(requestor) then return minusecard end
    return self:getMaxCard()
end

ai_audited_aliases.register{id="ai_cardneed.meizlhujia",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlhujia"},canonical_registry="ai_cardneed",canonical_path={"bignumber"}}

local meizlguihan_skill = {}
meizlguihan_skill.name = "meizlguihan"
table.insert(sgs.ai_skills, meizlguihan_skill)
meizlguihan_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getStrategyMark("@meizlguihan") == 0 then return end
    return parse_action(self,"#meizlguihancard:.:")
end

sgs.ai_skill_use_func["#meizlguihancard"] = function(card, use, self,request)
    if self:isWeak() then
        use.card = card
        if use.to then use.to:append(self.player) end
        return
    end
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|meizlhunshi"


sgs.ai_skill_playerchosen.meizlliuma = function(self, targets)
    local max_diff = 0
    local target
    for _, splayer in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        local friend = 1
        if not self:isFriend(splayer) then
            friend = -1
        end
        local value = -splayer:getHandcardNum()
        if not hasManjuanEffect(splayer) then
            value = value + splayer:getHp()
        end
        if hasTuntianEffect(splayer) then
            value = value + 1
        end
        if source_query(self, "hasLoseHandcardEffective", splayer) then
            value = value + self:getLeastHandcardNum(splayer)
        end
        value = value * friend


        if value > max_diff then
            if (self:isFriend(splayer) or (self:isEnemy(splayer)) and (source_query(self, "doDisCard", splayer, "h") or value >= 3)) then
                max_diff = value
                target = splayer
            end
        end
    end
    if target then
        return target
    end
    return nil
end

function sgs.ai_cardneed.meizlliuma(to, card)
    return source_query(card, "isNDTrick")
end

local meizlzhinang_skill = {}
meizlzhinang_skill.name = "meizlzhinang"
table.insert(sgs.ai_skills, meizlzhinang_skill)
meizlzhinang_skill.getTurnUseCard = function(self)
    if not self.player:isKongcheng() and not self.player:getStrategyHasUsed("#meizlzhinangcard") then
        return parse_action(self,"#meizlzhinangcard:.:")
    end
end

sgs.ai_skill_use_func["#meizlzhinangcard"] = function(card, use, self,request)
    self:sort(self.enemies, "defense")
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    local use_card
    for _, card in ipairs(cards) do
        if card:isKindOf("BasicCard") and not card:isKindOf("Peach") then
            use_card = card
        end
    end
    if use_card and not self:hasWizard(self.enemies, true) then
        for _, enemy in ipairs(self.enemies) do
            if source_query(self, "objectiveLevel", enemy) > 3 and source_query(self, "canAttack", enemy, self.player) and source_query(self, "damageIsEffective", enemy) then
                use.card = parse_action(self,"#meizlzhinangcard:" .. use_card:getKnownEffectiveId() .. ":")
                if use.to then
                    use.to:append(enemy)
                end
                break
            end
        end
    end
end



sgs.ai_skill_invoke.meizlyuguo = function(self, data)
    return true
end

ai_audited_aliases.register{id="ai_cardneed.meizlyuguo",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlyuguo"},canonical_registry="ai_cardneed",canonical_path={"slash"}}

sgs.ai_skill_invoke.meizlrongzhuang = function(self, data)
    return true
end
sgs.ai_skill_use["@@meizlrongzhuang"] = function(self, prompt)
    self:updatePlayers()
    local card = prompt:split(":")
    if card[2] == "slash" or card[2] == "fire_slash" or card[2] == "thunder_slash" then
        self:sort(self.enemies, "defense")
        local targets = {}
        local slash = known_card(self,card[5])
        for _, enemy in ipairs(self.enemies) do
            if source_query(self.player, "canSlash", enemy, slash) and not source_query(self, "slashProhibit", slash, enemy) and source_query(self, "slashIsEffective", slash, enemy) and source_query(self, "isGoodTarget", enemy, self.enemies, slash) then
                if #targets >= 1 + source_query(slash, "getTargetModExtra", self.player) then break end
                table.insert(targets, enemy:objectName())
            end
        end
        if #targets > 0 then
            return card[5] .. "->" .. table.concat(targets, "+")
        else
            return "."
        end
    end
    return "."
end

ai_audited_aliases.register{id="ai_cardneed.meizlwuji",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlwuji"},canonical_registry="ai_cardneed",canonical_path={"slash"}}


sgs.ai_ajustdamage_from.meizljichi = function(self, from, to, card, nature)
    if source_query(from, "distanceTo", to) == 1 and from:objectName() ~= to:objectName() and from:isWounded()
    then
        return from:getLostHp()
    end
end


sgs.ai_skill_use["@@meizlruimu"] = function(self, prompt)
    self:updatePlayers()
    self:sort(self.enemies, "hp")
    local cards = self.player:getCards("he")
    local to_discard = {}
    cards = sgs.QList2Table(cards)

    self:sortByUseValue(cards, true)

    local target
    for _, enemy in ipairs(self.enemies) do
        if self:hasSkills(sgs.need_maxhp_skill, enemy) and enemy:getMaxHp() > 3 and enemy:getLostHp() > 0 then
            target = enemy
        end
    end
    if not target then
        for _, enemy in ipairs(self.enemies) do
            if source_query(self, "isGoodTarget", enemy, self.enemies) and (enemy:getHp() > 2) then
                target = enemy
            end
        end
    end
    if target then
        local needcard_num = 1
        for _, card in ipairs(cards) do
            if not card:isKindOf("Peach") and not card:isKindOf("EquipCard") and card:getSuit() == sgs.Card_Heart then
                if #to_discard == needcard_num then break end
                table.insert(to_discard, card:getKnownEffectiveId())
            end
        end
        if #to_discard ~= needcard_num then
            for _, card in ipairs(cards) do
                if not card:isKindOf("Peach") and not table.contains(to_discard, card:getKnownEffectiveId()) and card:getSuit() == sgs.Card_Heart then
                    if #to_discard == needcard_num then break end
                    table.insert(to_discard, card:getKnownEffectiveId())
                end
            end
        end
        if #to_discard == 1 then
            return "#meizlruimucard:" .. table.concat(to_discard, "+") .. ":->" .. target:objectName()
        end
    end
    return "."
end

sgs.ai_card_intention.meizlruimucard = function(self, card, from, tos)
    local to = tos[1]
    local intention = 70
    self:updateIntention(from, to, intention)
end

sgs.ai_skill_invoke.meizlxianshu = function(self, data)
    local damage = data:toDamage()
    if damage.to:objectName() == self.player:objectName() and self.player:getHp() < getBestHp(self.player) then
        local cards = sgs.QList2Table(self.player:getHandcards())
        for _, acard in ipairs(cards) do
            if acard:isRed() then
                return true
            end
        end
    end
    if self:isFriend(damage.to) and damage.to:getHp() < getBestHp(damage.to) then
        if damage.to:getHandcardNum() > 2 then
            return true
        end
    else
        if not damage.to:isWounded() or damage.to:getHandcardNum() <= 2 then
            return true
        end
    end
    return false
end
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|meizlxianshu"


local meizlzhaojie_skill = {}
meizlzhaojie_skill.name = "meizlzhaojie"
table.insert(sgs.ai_skills, meizlzhaojie_skill)
meizlzhaojie_skill.getTurnUseCard = function(self)
    if not self.player:isKongcheng() and not self.player:getStrategyHasUsed("#meizlzhaojiecard") then
        return parse_action(self,"#meizlzhaojiecard:.:")
    end
end

sgs.ai_skill_use_func["#meizlzhaojiecard"] = function(card, use, self,request)
    self:sort(self.friends_noself, "handcard")
    local cards = sgs.QList2Table(self.player:getCards("he"))
    local needed = {}
    for _, acard in ipairs(cards) do
        if (#needed < self.player:getHp() or (#needed < self:getOverflow() and self:getOverflow() > 0)) and acard:isRed()  then
            table.insert(needed, acard:getKnownEffectiveId())
        end
    end
    if #needed > 0 then
        for _, friend in ipairs(self.friends_noself) do
            if not self:needKongcheng(friend, true) and self:canDraw(friend, self.player) then
                if friend:hasSkills(sgs.cardneed_skill) or (friend:getHandcardNum() < 3) then
                    use.card = parse_action(self,"#meizlzhaojiecard:" .. table.concat(needed, "+") .. ":")
                    if use.to then use.to:append(friend) end
                    return
                end
            end
        end
        for _, friend in ipairs(self.friends_noself) do
            if not self:needKongcheng(friend, true) and self:canDraw(friend, self.player) then
                use.card = parse_action(self,"#meizlzhaojiecard:" .. table.concat(needed, "+") .. ":")
                if use.to then use.to:append(friend) end
                return
            end
        end
    end
end
sgs.ai_use_priority["meizlzhaojiecard"] = sgs.ai_use_priority.Peach + 0.1
sgs.ai_use_value["meizlzhaojiecard"] = 2.45
sgs.ai_card_intention.meizlzhaojiecard = -80



local meizlqingyan_skill = {}
meizlqingyan_skill.name = "meizlqingyan"
table.insert(sgs.ai_skills, meizlqingyan_skill)
meizlqingyan_skill.getTurnUseCard = function(self)
    if source_query(self, "needBear") then return end
    if not source_query(self.player, "canDiscard", self.player, "he") then return end
    return parse_action(self,"#meizlqingyancard:.:")
end

sgs.ai_skill_use_func["#meizlqingyancard"] = function(card, use, self,request)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sort(self.enemies, "handcard")
    local slashcount = self:getCardsNum("Slash")
    self:sortByUseValue(cards, true)
    if slashcount > 0 then
        for _, card in ipairs(cards) do
            if (not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink")) or self:getOverflow() > 0 then
                local slash = self:getCard("Slash")
                assert(slash)
                local target
                local dummy_use = meizl_use_card(self,card, dummy())

                if not dummy_use.to:isEmpty() then
                    for _, p in sgs.qlist(dummy_use.to) do
                        if p:getStrategyMark("@meizlqingyan") == 0 then
                            target = p
                            break
                        end
                    end
                end

                if target then
                    use.card = parse_action(self,"#meizlqingyancard:" .. card:getKnownId() .. ":")
                    if use.to then use.to:append(target) end
                    return
                end
            end
        end
    end
end

sgs.ai_card_intention["meizlqingyancard"] = 70


sgs.ai_use_value["meizlqingyancard"] = 9.2
sgs.ai_use_priority["meizlqingyancard"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_skill_invoke.meizlxiangjie = function(self, data)
    local hcards = self.player:getCards("h")
    hcards = sgs.QList2Table(hcards)
    self:sortByUseValue(hcards, true)
    local card
    for _, hcard in ipairs(hcards) do
        if hcard:isKindOf("Slash") then
            card = hcard
        end
    end
    if not card then
        return false
    end
    local target
    local friends = self.friends_noself
    local slash = clone_preview(self,"slash", sgs.Card_NoSuit, 0)

    set_state(self,"meizlxiangjieTarget",nil)
    local friend = self.room:getCurrent()
    if friend and self:isFriend(friend) then
        self:sort(self.enemies, "defense")
        for _, enemy in ipairs(self.enemies) do
            if source_query(friend, "canSlash", enemy) and not source_query(self, "slashProhibit", slash, enemy) and source_query(self, "getDefenseSlash", enemy) <= 2
                and source_query(self, "slashIsEffective", slash, enemy) and source_query(self, "isGoodTarget", enemy, self.enemies, slash)
                and enemy:objectName() ~= self.player:objectName() then
                set_state(self,"meizlxiangjieTarget",enemy)
                return true
            end
        end
    end
    return false
end

sgs.ai_skill_playerchosen.meizlxiangjie = function(self, targets)
    if get_state(self,"meizlxiangjieTarget") then return get_state(self,"meizlxiangjieTarget") end
    return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

sgs.ai_skill_cardask["@meizlxiangjie-slash"] = function(self, data, pattern)
    local hcards = self.player:getCards("h")
    hcards = sgs.QList2Table(hcards)
    self:sortByUseValue(hcards, true)
    local card
    for _, hcard in ipairs(hcards) do
        if hcard:isKindOf("Slash") then
            card = hcard
        end
    end
    if card then
        return "$" .. card:getKnownEffectiveId()
    end
end

ai_audited_aliases.register{id="ai_cardneed.meizlxiangjie",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlxiangjie"},canonical_registry="ai_cardneed",canonical_path={"slash"}}


local meizlwuyin_skill = {}
meizlwuyin_skill.name = "meizlwuyin"
table.insert(sgs.ai_skills, meizlwuyin_skill)
meizlwuyin_skill.getTurnUseCard = function(self)
    if not source_query(self.player, "canDiscard", self.player, "he") then return end
    if self.player:getStrategyHasUsed("#meizlwuyincard") then return end
    return parse_action(self,"#meizlwuyincard:.:")
end

sgs.ai_skill_use_func["#meizlwuyincard"] = function(card, use, self,request)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sort(self.enemies, "handcard")

    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
        if (not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink")) or (self:getOverflow() > 0) then
            local duel = clone_preview(self,"Duel")
            local target
            local dummy_use = meizl_use_card(self,duel, dummy())
            if not dummy_use.to:isEmpty() then
                for _, p in sgs.qlist(dummy_use.to) do
                    if p:isMale() then
                        target = p
                        break
                    end
                end
            end

            if target then
                use.card = parse_action(self,"#meizlwuyincard:" .. card:getKnownId() .. ":")
                if use.to then use.to:append(target) end
                return
            end
        end
    end
end


sgs.ai_use_value["meizlwuyincard"] = 3
sgs.ai_use_priority["meizlwuyincard"] = sgs.ai_use_priority.Duel



local meizlmihun_skill = {}
meizlmihun_skill.name = "meizlmihun"
table.insert(sgs.ai_skills, meizlmihun_skill)
meizlmihun_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#meizlmihuncard") or self.player:isNude() then
        return
    end
    local card_id = self:getLijianCard()
    if card_id then return parse_action(self,"#meizlmihuncard:" .. card_id .. ":") end
end

sgs.ai_skill_use_func["#meizlmihuncard"] = function(card, use, self,request)
    local first, second
    local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))
    for _, target in ipairs(players) do
        if self:isEnemy(target) and target:getHandcardNum() >= 1 and source_query(self, "doDisCard", target, "he")  then
            for _, target2 in ipairs(sgs.QList2Table(self.room:getOtherPlayers(target))) do
                if self:isEnemy(target2) then
                    if target2:getHandcardNum() >= 1 and source_query(target, "canDiscard", target2, "he") and source_query(target2, "canDiscard", target, "he") and source_query(self, "doDisCard", target2, "he") then
                        first = target
                        second = target2
                        break
                    end
                end
            end
        end
    end
    if first and second then
        use.card = card
        if use.to then
            use.to:append(first)
            use.to:append(second)
        end
    else
        for _, target in ipairs(players) do
            if self:isFriend(target) and target:getHandcardNum() >= 1 and source_query(self, "doDisCard", target, "he") then
                for _, target2 in ipairs(sgs.QList2Table(self.room:getOtherPlayers(target))) do
                    if self:isEnemy(target2) then
                        if target2:getHandcardNum() >= 1 and source_query(target, "canDiscard", target2, "he") and source_query(target2, "canDiscard", target, "he") and source_query(self, "doDisCard", target2, "he") then
                            first = target
                            second = target2
                            break
                        end
                    end
                end
            end
        end
        if first and second then
            use.card = card
            if use.to then
                use.to:append(first)
                use.to:append(second)
            end
        end
    end
end

sgs.ai_skill_invoke.meizlyaorao = function(self, data)
    if #self.enemies <= 1 then return false end
    for _, c in sgs.qlist(self.player:getHandcards()) do
        local x = nil
        if isCard("ArcheryAttack", c, self.player) then
            x = clone_preview(self,"ArcheryAttack")
        elseif isCard("SavageAssault", c, self.player) then
            x = clone_preview(self,"SavageAssault")
        else
            continue
        end

        local dummy_use = meizl_use_card(self,x, dummy())
        if (dummy_use.card) then return true end

    end
    if self:isWeak() then
        return true
    end
    if #self.enemies == 1 then return true end
    return false
end



local meizlmijian_skill = {}
meizlmijian_skill.name = "meizlmijian"
table.insert(sgs.ai_skills, meizlmijian_skill)
meizlmijian_skill.getTurnUseCard = function(self)
    if not self.player:isKongcheng() and not self.player:getStrategyHasUsed("#meizlmijiancard") then
        return parse_action(self,"#meizlmijiancard:.:")
    end
end

sgs.ai_skill_use_func["#meizlmijiancard"] = function(card, use, self,request)
    self:sort(self.friends_noself, "handcard")
    local cards = sgs.QList2Table(self.player:getCards("he"))
    local needed = {}
    if self.player:isWounded() then
        for _, acard in ipairs(cards) do
            if #needed <= self.player:getHp() then
                table.insert(needed, acard:getKnownEffectiveId())
            end
        end
    else
        if (self.player:getHandcardNum() > 0) then
            for _, acard in ipairs(cards) do
                if #needed < self.player:getHandcardNum() then
                    table.insert(needed, acard:getKnownEffectiveId())
                end
            end
        end
    end
    if #needed > 0 then
        for _, friend in ipairs(self.friends_noself) do
            if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) and (self:hasSkills(sgs.cardneed_skill, friend) or hasTuntianEffect(friend)) then
                use.card = parse_action(self,"#meizlmijiancard:" .. table.concat(needed, "+") .. ":")
                if use.to then use.to:append(friend) end
                return
            end
        end
        for _, friend in ipairs(self.friends_noself) do
            if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
                use.card = parse_action(self,"#meizlmijiancard:" .. table.concat(needed, "+") .. ":")
                if use.to then use.to:append(friend) end
                return
            end
        end
    end
end
sgs.ai_use_priority["meizlmijiancard"] = sgs.ai_use_priority.Peach + 0.1
sgs.ai_use_value["meizlmijiancard"] = 2.45
sgs.ai_card_intention.meizlmijiancard = -10

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|meizlmijian"
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|meizlmijian"
function sgs.ai_cardneed.meizlmijian(to,card)
    return to:getHandcardNum()<=to:getHp()
end

sgs.ai_skill_invoke.meizlnibi = function(self, data)
    return true
end
sgs.ai_skill_use["@@meizlnibi"] = function(self, prompt)
    self:sort(self.friends_noself, "handcard")
    local cards = sgs.QList2Table(self.player:getCards("he"))
    local needed = {}
    if self.player:isWounded() then
        for _, acard in ipairs(cards) do
            if #needed <= self.player:getHp() then
                table.insert(needed, acard:getKnownEffectiveId())
            end
        end
    else
        if (self.player:getHandcardNum() > 0) then
            for _, acard in ipairs(cards) do
                if #needed < self.player:getHandcardNum() then
                    table.insert(needed, acard:getKnownEffectiveId())
                end
            end
        end
    end
    if #needed > 0 then
        for _, friend in ipairs(self.friends_noself) do
            if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) and (self:hasSkills(sgs.cardneed_skill, friend) or hasTuntianEffect(friend)) then
                return "#meizlmijian:" .. table.concat(needed, "+") .. ":->" .. friend:objectName()
            end
        end
        for _, friend in ipairs(self.friends_noself) do
            if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
                return "#meizlmijian:" .. table.concat(needed, "+") .. ":->" .. friend:objectName()
            end
        end
    end
    return "."
end
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|meizlnibi"


sgs.ai_skill_discard.meizlzenyan = function(self, discard_num, min_num, optional, include_equip)
    local current = self.room:getCurrent()
    if current and self:isEnemy(current) and current:getHandcardNum() - current:getHp() > 2 then
        local to_discard = {}
        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)

        table.insert(to_discard, cards[1]:getEffectiveId())

        return to_discard
    end
    return {}
end

sgs.ai_skill_invoke.meizlzhuanchong = function(self, data)
    local target = data:toPlayer()
    if self:isFriend(target) then
        return getKnownCard(target, self.player, "EquipCard", false) > 0 or source_query(self, "getAllPeachNum") == 0
    else
        if (source_query(self, "getKnownNum", target)==target:getHandcardNum() or target:getHandcardNum() < 3) and getKnownCard(target, self.player, "EquipCard", false) == 0 then
            return target:getEquips():length() == 0
        end
    end
    return false
end

sgs.ai_skill_cardask["@meizlzhuanchong"] = function(self, data, pattern, prompt)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards)
    for i, c in sgs.list(cards) do
        if c:isKindOf("EquipCard")
        then
            return c:getKnownEffectiveId()
        end
    end
    return "."
end

sgs.save_skill = sgs.save_skill .. "|meizlzhuanchong"

local meizlganzheng_skill = {}
meizlganzheng_skill.name = "meizlganzheng"
table.insert(sgs.ai_skills, meizlganzheng_skill)
meizlganzheng_skill.getTurnUseCard          = function(self, inclusive)
    if self.player:getStrategyMark("@meizlganzheng") < 1 then return end
    if #self.friends_noself < 1 then return end
    local OK = false
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if self:isFriend(p) and p:getHp() == 1 then
            OK = true
        end
        if self:isFriend(p) and p:getHp() == 2 and self.player:getHp() == 1 and p:getMaxHp() == 3 then
            OK = true
        end
    end
    if OK then
        return parse_action(self,"#meizlganzhengcard:.:")
    end
    return
end

sgs.ai_skill_use_func["#meizlganzhengcard"] = function(card, use, self,request)
    local target
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if self:isFriend(p) and p:getHp() == 1 then
            target = p
        end
        if self:isFriend(p) and p:getHp() == 2 and self.player:getHp() == 1 and p:getMaxHp() == 3 then
            target = p
        end
        if self:isFriend(p) and p:getHp() == 1 and p:getMaxHp() == 3 then
            target = p
        end
    end
    if target then
        use.card = card
        if use.to then use.to:append(target) end
        return
    end
end

sgs.ai_use_value["meizlganzhengcard"]       = 10
sgs.ai_use_priority["meizlganzhengcard"]    = 4
sgs.ai_card_intention.meizlganzhengcard     = -100


sgs.ai_skill_invoke.meizlboxing = function(self, data)
    local hp = self.player:getHp()
    if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 1 - self.player:getHp() then
        return false
    end
    return true
end

sgs.ai_can_damagehp.meizlyoulong = function(self, from, card, to)
    if to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to)
    then
        return not self:hasWizard(self:getEnemies(to), true)
    end
end


function sgs.ai_slash_prohibit.meizlyuanshi(self, from, to)
    if source_query(self, "hasJueqingEffect", from, to) or (from:hasSkill("nosqianxi") and source_query(from, "distanceTo", to) == 1) then return false end
    if from:getStrategyFlag("NosJiefanUsed") then return false end
    return #(self:getEnemies(from)) > 1 and self:isWeak(to) and
        (from:getMaxHp() <= 3 or from:hasSkills(sgs.need_maxhp_skill))
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|meizlyuanshi"

sgs.ai_ajustdamage_to.meizlxiuhua = function(self, from, to, card, nature)
    if nature ~= "N" and source_query(to, "distanceTo", from) <= 2
    then
        return -1
    end
end

sgs.ai_cardneed.meizlxianggui = function(to, card)
    return to:getHandcardNum() - to:getHp() <= 2
end



local meizlchanhuo_skill = {}
meizlchanhuo_skill.name = "meizlchanhuo"
table.insert(sgs.ai_skills, meizlchanhuo_skill)
meizlchanhuo_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meizlchanhuocard") and not self.player:isKongcheng() then
        return parse_action(self,
            "#meizlchanhuocard:.:")
    end
end

sgs.ai_skill_use_func["#meizlchanhuocard"] = function(card, use, self,request)
    self:sort(self.enemies, "handcard")
    local max_card = self:getMaxCard(self.player)
    local max_point = max_card:getNumber()

    if (max_point > 10) then
        for _, enemy in ipairs(self.enemies) do
            if not enemy:isKongcheng() and source_query(self.player, "canPindian", enemy) and enemy:getHp() == 1 then
                use.card = parse_action(self,"#meizlchanhuocard:.:")
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end

function sgs.ai_skill_pindian.meizlchanhuocard(minusecard, self, requestor)
    if self:isFriend(requestor) then return minusecard end
    return self:getMaxCard()
end

ai_audited_aliases.register{id="ai_cardneed.meizlchanhuo",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlchanhuo"},canonical_registry="ai_cardneed",canonical_path={"bignumber"}}

local meizlzenhui_skill = {}
meizlzenhui_skill.name = "meizlzenhui"
table.insert(sgs.ai_skills, meizlzenhui_skill)
meizlzenhui_skill.getTurnUseCard          = function(self)
    if not self.player:getStrategyHasUsed("#meizlzenhuicard") and not self.player:isKongcheng() then
        self:sort(self.enemies, "hp")
        for _, enemy in ipairs(self.enemies) do
            if not (enemy:hasSkill("kongcheng") and enemy:isKongcheng()) and self:isWeak(enemy) and self:damageMinusHp(enemy, 1) > 0
                and #self.enemies > 1 then
                if self.player:getStrategyMark("@meizlzenhui") == 0 then
                    return parse_action(self,"#meizlzenhuicard:.:")
                end
            end
        end
        if self.player:getStrategyMark("@meizlzenhui") == 1 then
            return parse_action(self,"#meizlzenhuicard:.:")
        end
    end
end

sgs.ai_skill_use_func["#meizlzenhuicard"] = function(card, use, self,request)
    self:sort(self.enemies, "hp")
    local cards = sgs.QList2Table(self.player:getCards("h"))
    local needed = {}
    if (self.player:getHandcardNum() > 0) then
        for _, acard in ipairs(cards) do
            if #needed < 1 then
                table.insert(needed, acard:getKnownEffectiveId())
            end
        end
    end
    if #needed > 0 then
        for _, enemy in ipairs(self.enemies) do
            if not (enemy:hasSkill("kongcheng") and enemy:isKongcheng()) and self:isWeak(enemy) and self:damageMinusHp(enemy, 1) > 0
                and #self.enemies > 1 then
                if self.player:getStrategyMark("@meizlzenhui") == 0 then
                    use.card = parse_action(self,"#meizlzenhuicard:" .. table.concat(needed, "+") .. ":")
                    return
                end
            end
        end
        if self.player:getStrategyMark("@meizlzenhui") == 1 and self.player:getStrategyMark("&meizlzenhuiskill") == 0 then
            use.card = parse_action(self,"#meizlzenhuicard:" .. table.concat(needed, "+") .. ":")
            return
        end
    end
end
sgs.ai_use_priority["meizlzenhuicard"] = sgs.ai_use_priority.Slash + 1

sgs.ai_ajustdamage_from["@meizlzenhui"]   = function(self, from, to, card, nature)
    if to and to:isMale() and card and card:isKindOf("Slash") then
        return 1
    end
end
ai_audited_aliases.register{id="ai_cardneed.meizlzenhui",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlzenhui"},canonical_registry="ai_cardneed",canonical_path={"slash"}}



local meizljianwu_skill = {}
meizljianwu_skill.name = "meizljianwu"
table.insert(sgs.ai_skills, meizljianwu_skill)
meizljianwu_skill.getTurnUseCard          = function(self)
    if not self.player:getStrategyHasUsed("#meizljianwucard") and not self.player:isKongcheng() then
        self:sort(self.enemies, "hp")
        for _, enemy in ipairs(self.enemies) do
            if #self.enemies > 1 then
                if self.player:getStrategyMark("@meizljianwu") == 0 then
                    return parse_action(self,"#meizljianwucard:.:")
                end
            end
        end
    end
end

sgs.ai_skill_use_func["#meizljianwucard"] = function(card, use, self,request)
    self:sort(self.enemies, "hp")
    local cards = sgs.QList2Table(self.player:getCards("h"))
    local needed = {}
    if (self.player:getHandcardNum() > 0) then
        for _, acard in ipairs(cards) do
            if #needed < 1 then
                table.insert(needed, acard:getKnownEffectiveId())
            end
        end
    end
    if #needed > 0 then
        for _, enemy in ipairs(self.enemies) do
            if #self.enemies > 1 then
                if self.player:getStrategyMark("@meizljianwu") == 0 then
                    use.card = parse_action(self,"#meizljianwucard:" .. table.concat(needed, "+") .. ":")
                    return
                end
            end
        end
    end
end
sgs.ai_use_priority["meizljianwucard"]    = sgs.ai_use_priority.Slash + 0.1

ai_audited_aliases.register{id="ai_cardneed.meizljianwu",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizljianwu"},canonical_registry="ai_cardneed",canonical_path={"slash"}}

sgs.ai_canliegong_skill.meizljianwu = function(self, from, to)
    if from:getStrategyMark("@meizljianwu") > 0 and to:getHandcardNum() <= source_query(from, "getAttackRange") then return true end
end

sgs.ai_view_as.meizljianwuskill2 = function(card, player, card_place)
    local self=known(player:getRoom()._ai,"viewer AI")
    if known(self.request.reason,"current card use reason") ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
    local suit = card:getSuitString()
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
        and card:getTypeId() == sgs.Card_TypeEquip and not card:getStrategyFlag("using")
        and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
        return ("slash:meizljianwuskill2[%s:%s]=%d"):format(suit, number, card_id)
    end
end

local meizljianwuskill2_skill = {}
meizljianwuskill2_skill.name = "meizljianwuskill2"
table.insert(sgs.ai_skills, meizljianwuskill2_skill)
meizljianwuskill2_skill.getTurnUseCard = function(self, inclusive)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)

    if self.player:getPile("wooden_ox"):length() > 0 then
        for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
            table.insert(cards, known_card(self,id))
        end
    end

    local equip_card
    self:sortByUseValue(cards, true)

    for _, card in ipairs(cards) do
        if card:getTypeId() == sgs.Card_TypeEquip and (source_query(self, "getUseValue", card) < sgs.ai_use_value.Slash or inclusive)
            and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
            equip_card = card
            break
        end
    end

    if equip_card then
        local suit = equip_card:getSuitString()
        local number = source_query(equip_card, "getNumberString")
        local card_id = equip_card:getKnownEffectiveId()
        local card_str = ("slash:meizljianwuskill2[%s:%s]=%d"):format(suit, number, card_id)
        local slash = parse_action(self,card_str)

        assert(slash)

        return slash
    end
end


function sgs.ai_cardneed.meizljianwuskill2(to, card, self)
    return card:getTypeId() == sgs.Card_TypeEquip and getKnownCard(to, self.player, "EquipCard", true) == 0
end

sgs.ai_ajustdamage_from.meizldushiskill = function(self, from, to, card, nature)
    if from and from:getHandcardNum() <= from:getHp() and card and card:isKindOf("Slash") then
        return 1
    end
end


local meizlrangdou_skill                = {}
meizlrangdou_skill.name                 = "meizlrangdou"
table.insert(sgs.ai_skills, meizlrangdou_skill)
meizlrangdou_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meizlrangdoucard") and not self.player:isKongcheng() then
        if self:isWeak() and self.player:getStrategyMark("@meizlrangdou") == 0 then
            return parse_action(self,"#meizlrangdoucard:.:")
        else
            if not self:isWeak() and self.player:getStrategyMark("@meizlrangdou") == 1 then
                return parse_action(self,"#meizlrangdoucard:.:")
            end
        end
    end
end

sgs.ai_skill_use_func["#meizlrangdoucard"] = function(card, use, self,request)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    local needed = {}
    if (self.player:getHandcardNum() > 0) then
        for _, acard in ipairs(cards) do
            if #needed < 1 and acard:isKindOf("BasicCard") then
                table.insert(needed, acard:getKnownEffectiveId())
            end
        end
    end
    if #needed > 0 then
        for _, enemy in ipairs(self.enemies) do
            if self:isWeak() and self.player:getStrategyMark("@meizlrangdou") == 0 then
                use.card = parse_action(self,"#meizlrangdoucard:" .. table.concat(needed, "+") .. ":")
                return
            else
                if not self:isWeak() and self.player:getStrategyMark("@meizlrangdou") == 1 then
                    use.card = parse_action(self,"#meizlrangdoucard:" .. table.concat(needed, "+") .. ":")
                    return
                end
            end
        end
    end
end
sgs.ai_ajustdamage_to["@meizlrangdou"] = function(self, from, to, card, nature)
    return -1
end

sgs.ai_ajustdamage_from["@meizlrangdou"] = function(self, from, to, card, nature)
    return -1
end


local meizlshehua_skill = {}
meizlshehua_skill.name = "meizlshehua"
table.insert(sgs.ai_skills, meizlshehua_skill)
meizlshehua_skill.getTurnUseCard = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)

    if self.player:getPile("wooden_ox"):length() > 0 then
        for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
            table.insert(cards, known_card(self,id))
        end
    end

    local card

    self:sortByUseValue(cards, true)

    for _, acard in ipairs(cards) do
        if acard:isKindOf("EquipCard") then
            card = acard
            break
        end
    end

    if not card then
        for _, acard in ipairs(sgs.QList2Table(self.player:getCards("e"))) do
            if acard:isKindOf("EquipCard") then
                card = acard
                break
            end
        end
    end
    if not card then return nil end
    local number = source_query(card, "getNumberString")
    local suit = card:getSuitString()
    local card_id = card:getKnownEffectiveId()
    local card_str = ("analeptic:meizlshehua[%s:%s]=%d"):format(suit, number, card_id)
    local analeptic = parse_action(self,card_str)

    if sgs.Analeptic_IsAvailable(self.player, analeptic) then
        assert(analeptic)
        return analeptic
    end
end

sgs.ai_view_as.meizlshehua = function(card, player, card_place)
    local self=known(player:getRoom()._ai,"viewer AI")
    local suit = card:getSuitString()
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    if card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id) then
        if card:isKindOf("EquipCard") then
            return ("analeptic:meizlshehua[%s:%s]=%d"):format(suit, number, card_id)
        end
    end
end

local meizlmosi_skill = {} --凤翼天翔
meizlmosi_skill.name = "meizlmosi"
table.insert(sgs.ai_skills, meizlmosi_skill)
meizlmosi_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getStrategyMark("@meizlmosi") > 0 then
        local TH_skillcard = parse_action(self,"#meizlmosicard:.:")
        return TH_skillcard
    end
end
sgs.ai_skill_use_func["#meizlmosicard"] = function(card, use, self,request)
    local jiu
    if not self.player:getStrategyHasUsed("Analeptic") and self:getCard("Analeptic") then
        jiu = self:getCard("Analeptic")
    end
    local slash = clone_preview(self,"Slash")

    if self:UseAoeSkillValue_mei(sgs.DamageStruct_Normal, nil, slash) > 0 or self:isWeak() then
        if jiu and not use.isDummy then
            use.card = jiu
            return
        end
        use.card = card
        return
    end
end

sgs.ai_use_priority["meizlmosicard"] = 3


sgs.ai_skill_invoke.meizlkuma = function(self, data)
    local damage = data:toDamage()
    local target = damage.from
    local slash = clone_preview(self,"slash")

    if target and target:isAlive() and not source_query(self, "slashProhibit", slash, target) and source_query(self, "slashIsEffective", slash, target) and ((source_query(self, "isGoodTarget", target, self.enemies, slash) and self:isEnemy(target)) or (self:isFriend(target) and source_query(self, "needToLoseHp", target, self.player, slash)))
        and target:objectName() ~= self.player:objectName() then
        return true
    end
    return false
end

sgs.ai_can_damagehp.meizlkuma = function(self, from, card, to)
    if from and to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to)
    then
        local slash = clone_preview(self,"slash")

        return self:isEnemy(from) and self:isWeak(from) and source_query(from, "getCardCount") > 0 and
            not source_query(self, "slashProhibit", slash, from) and source_query(self, "slashIsEffective", slash, from)
    end
end

function sgs.ai_slash_prohibit.meizlliyi(self, from, to)
    if source_query(self, "hasJueqingEffect", from, to) or (from:hasSkill("nosqianxi") and source_query(from, "distanceTo", to) == 1) then return false end
    if from:getStrategyFlag("NosJiefanUsed") then return false end
    if to:getHp() > 1 or #(self:getEnemies(from)) == 1 then return false end
    return false
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|meizlliyi"

local meizlyujue_skill = {}
meizlyujue_skill.name = "meizlyujue"
table.insert(sgs.ai_skills, meizlyujue_skill)
meizlyujue_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#meizlyujuecard") or self:isWeak() or self:getOverflow() > 0 then return end
    return parse_action(self,"#meizlyujuecard:.:")
end
sgs.ai_skill_use_func["#meizlyujuecard"] = function(card, use, self,request)
    local targets = {}
    local target
    self:sort(self.enemies, "defense")
    self:sort(self.friends_noself, "defense")
    for _, enemy in ipairs(self.enemies) do
        if source_query(self, "doDisCard", enemy, "he") and source_query(self.player, "canDiscard", enemy, "he") then
            target = enemy
        end
    end
    if target then
        use.card = card
        if use.to then
            use.to:append(target)
        end
    end
end

sgs.bad_skills = sgs.bad_skills .. "|meizlkuijiu"



sgs.ai_skill_use["@@meizlyinzhi"] = function(self, prompt)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    local needed = {}
    self:sortByKeepValue(cards)
    for _, acard in ipairs(cards) do
        if #needed < 1 then
            table.insert(needed, acard:getKnownEffectiveId())
        end
    end
    if #needed > 0 then
        return "#meizlyinzhicard:" .. table.concat(needed, "+") .. ":"
    end
    return "."
end
sgs.ai_skill_invoke.meizlyinzhi = function(self, data)
    local damage = data:toDamage()
    if damage.from and self:isFriend(damage.from) and known_card(self,self.player:getPile("meizlyinzhi"):first()):isKindOf("EquipCard") and not source_query(self, "needToLoseHp", damage.from, self.player) then
        return false
    end
    if damage.from and source_query(self, "damageIsEffective", damage.from, sgs.DamageStruct_Normal, self.player) and not source_query(self, "cantbeHurt", damage.from) and self:isEnemy(damage.from) and known_card(self,self.player:getPile("meizlyinzhi"):first()):isKindOf("EquipCard") then
        return false
    end
    return true
end
sgs.ai_can_damagehp.meizlyinzhi = function(self, from, card, to)
    if to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to)
    then
        return to:getPile("meizlyinzhi"):length() > 0 and ((from and self:isEnemy(from) and ((known_card(self,to:getPile("meizlyinzhi"):first()):isKindOf("EquipCard") and source_query(self, "damageIsEffective", from, sgs.DamageStruct_Normal, to) and not source_query(self, "cantbeHurt", from)) or (known_card(self,to:getPile("meizlyinzhi"):first()):isKindOf("TrickCard") and source_query(self, "doDisCard", from, "he")))) or  known_card(self,to:getPile("meizlyinzhi"):first()):isKindOf("BasicCard") )
    end
end


sgs.ai_skill_invoke.meizlfunei = function(self, data)
    local current = self.room:getCurrent()
    if current and self:isFriend(current) and not self:isWeak() and (getCardsNum("Slash", current, self.player) > 0 or current:getHandcardNum() > 3) then
        return not source_query(self, "willSkipPlayPhase", current)
    end
    return false
end

sgs.ai_choicemade_filter.skillInvoke.meizlfunei = function(self, player, promptlist)
    local current = self.room:getCurrent()
    if promptlist[#promptlist] == "yes" and current and current:isAlive() then
        self:updateIntention(player, current, -50)
    end
end

sgs.ai_skill_choice.meizljiaorao = function(self, choices)
    return get_state(self,"yinghunchoice")
end

local meizljiaorao_skill = {}
meizljiaorao_skill.name = "meizljiaorao"
table.insert(sgs.ai_skills, meizljiaorao_skill)
meizljiaorao_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#meizljiaoraocard") or (self:getOverflow() == 0) then return end
    return parse_action(self,"#meizljiaoraocard:.:")
end
sgs.ai_skill_use_func["#meizljiaoraocard"] = function(card, use, self,request)
    self:sort(self.friends_noself, "handcard")
    local cards = sgs.QList2Table(self.player:getCards("he"))
    local needed = {}
    if (self:getOverflow() > 0) then
        for _, acard in ipairs(cards) do
            if #needed < self:getOverflow() and not acard:isKindOf("Peach") then
                table.insert(needed, acard:getKnownEffectiveId())
            end
        end
    end
    if #needed > 0 then
        local x = #needed
        local n = x - 1
        self:updatePlayers()
        if x == 1 and #self.friends == 1 then
            for _, enemy in ipairs(self.enemies) do
                if hasManjuanEffect(enemy) then
                    use.card = parse_action(self,"#meizljiaoraocard:" .. table.concat(needed, "+") .. ":")
                    if use.to then use.to:append(enemy) end
                    return
                end
            end
            return
        end

        local target = nil
        local player = self:AssistTarget()

        if x == 1 then
            self:sort(self.friends_noself, "handcard")
            self.friends_noself = sgs.reverse(self.friends_noself)
            for _, friend in ipairs(self.friends_noself) do
                if self:hasSkills(sgs.lose_equip_skill, friend) and friend:getCards("e"):length() > 0
                    and not hasManjuanEffect(friend) then
                    target = friend
                    break
                end
            end
            if not target then
                for _, friend in ipairs(self.friends_noself) do
                    if hasTuntianEffect(friend, true) and not hasManjuanEffect(friend) then
                        target = friend
                        break
                    end
                end
            end
            if not target then
                for _, friend in ipairs(self.friends_noself) do
                    if source_query(self, "needToThrowArmor", friend) and not hasManjuanEffect(friend) then
                        target = friend
                        break
                    end
                end
            end
            if not target then
                for _, enemy in ipairs(self.enemies) do
                    if hasManjuanEffect(enemy) then
                        use.card = parse_action(self,"#meizljiaoraocard:" .. table.concat(needed, "+") .. ":")
                        if use.to then use.to:append(enemy) end
                        return
                    end
                end
            end

            if not target and player and not hasManjuanEffect(player) and source_query(player, "getCardCount", true) > 0 and not self:needKongcheng(player, true) then
                target = player
            end

            if not target then
                for _, friend in ipairs(self.friends_noself) do
                    if friend:getCards("he"):length() > 0 and not hasManjuanEffect(friend) then
                        target = friend
                        break
                    end
                end
            end

            if not target then
                for _, friend in ipairs(self.friends_noself) do
                    if not hasManjuanEffect(friend) then
                        target = friend
                        break
                    end
                end
            end
        elseif #self.friends > 1 then
            self:sort(self.friends_noself, "chaofeng")
            for _, friend in ipairs(self.friends_noself) do
                if self:hasSkills(sgs.lose_equip_skill, friend) and friend:getCards("e"):length() > 0
                    and not hasManjuanEffect(friend) then
                    target = friend
                    break
                end
            end
            if not target then
                for _, friend in ipairs(self.friends_noself) do
                    if hasTuntianEffect(friend, true) and not hasManjuanEffect(friend) and friend:getPhase() == sgs.Player_NotActive then
                        target = friend
                        break
                    end
                end
            end
            if not target then
                for _, friend in ipairs(self.friends_noself) do
                    if source_query(self, "needToThrowArmor", friend) and not hasManjuanEffect(friend) then
                        target = friend
                        break
                    end
                end
            end
            if not target and #self.enemies > 0 then
                local wf
                if source_query(self.player, "isLord") then
                    if self:isWeak() and (self.player:getHp() < 2 and self:getCardsNum("Peach") < 1) then
                        wf = true
                    end
                end
                if not wf then
                    for _, friend in ipairs(self.friends_noself) do
                        if self:isWeak(friend) then
                            wf = true
                            break
                        end
                    end
                end

                if not wf then
                    self:sort(self.enemies, "chaofeng")
                    for _, enemy in ipairs(self.enemies) do
                        if enemy:getCards("he"):length() == n
                            and source_query(self, "doDisCard", enemy, "he", true, n) then
                            set_state(self,"yinghunchoice","d1tx")
                            use.card = parse_action(self,"#meizljiaoraocard:" .. table.concat(needed, "+") .. ":")
                            if use.to then use.to:append(enemy) end
                            return
                        end
                    end
                    for _, enemy in ipairs(self.enemies) do
                        if enemy:getCards("he"):length() >= n
                            and source_query(self, "doDisCard", enemy, "he", true, n)
                            and self:hasSkills(sgs.cardneed_skill, enemy) then
                            set_state(self,"yinghunchoice","d1tx")
                            use.card = parse_action(self,"#meizljiaoraocard:" .. table.concat(needed, "+") .. ":")
                            if use.to then use.to:append(enemy) end
                            return
                        end
                    end
                end
            end

            if not target and player and not hasManjuanEffect(player) and not self:needKongcheng(player, true) then
                target = player
            end

            if not target then
                target = self:findPlayerToDraw(false, n)
            end
            if not target then
                for _, friend in ipairs(self.friends_noself) do
                    if not hasManjuanEffect(friend) then
                        target = friend
                        break
                    end
                end
            end
            if target then
                set_state(self,"yinghunchoice","dxt1")
                use.card = parse_action(self,"#meizljiaoraocard:" .. table.concat(needed, "+") .. ":")
                if use.to then use.to:append(target) end
                return
            end
        end
        if not target and x > 1 and #self.enemies > 0 then
            self:sort(self.enemies, "handcard")
            for _, enemy in ipairs(self.enemies) do
                if enemy:getCards("he"):length() >= n
                    and source_query(self, "doDisCard", enemy, "he", true, n) then
                    set_state(self,"yinghunchoice","d1tx")
                    use.card = parse_action(self,"#meizljiaoraocard:" .. table.concat(needed, "+") .. ":")
                    if use.to then use.to:append(enemy) end
                    return
                end
            end
            self.enemies = sgs.reverse(self.enemies)
            for _, enemy in ipairs(self.enemies) do
                if not enemy:isNude()
                    and not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards("e"):length() > 0)
                    and not source_query(self, "needToThrowArmor", enemy)
                    and not (hasTuntianEffect(enemy, true)) then
                    set_state(self,"yinghunchoice","d1tx")
                    use.card = parse_action(self,"#meizljiaoraocard:" .. table.concat(needed, "+") .. ":")
                    if use.to then use.to:append(enemy) end
                    return
                end
            end
            for _, enemy in ipairs(self.enemies) do
                if not enemy:isNude()
                    and not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards("e"):length() > 0)
                    and not source_query(self, "needToThrowArmor", enemy)
                    and not (hasTuntianEffect(enemy, true) and x < 3 and enemy:getCards("he"):length() < 2) then
                    set_state(self,"yinghunchoice","d1tx")
                    use.card = parse_action(self,"#meizljiaoraocard:" .. table.concat(needed, "+") .. ":")
                    if use.to then use.to:append(enemy) end
                    return
                end
            end
        end
    end
end
sgs.ai_card_intention["meizljiaoraocard"] = function(self,card,from,tos)
    local to = tos[1]
    if to then
        self:updateIntention(from,to,-60)
    end
end


local meizlzefu_skill = {}
meizlzefu_skill.name = "meizlzefu"
table.insert(sgs.ai_skills, meizlzefu_skill)
meizlzefu_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meizlzefucard") then
        return parse_action(self,"#meizlzefucard:.:")
    end
end

sgs.ai_skill_use_func["#meizlzefucard"] = function(card, use, self,request)
    self:sort(self.friends_noself, "handcard")
    local has_red = false
    for _, friend in ipairs(self.friends_noself) do
        if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
            if (friend:getHandcardNum() > self.player:getHandcardNum()) and (friend:getHp() > self.player:getHp()) and (source_query(friend, "getAttackRange") > source_query(self.player, "getAttackRange")) then
                use.card = parse_action(self,"#meizlzefucard:.:")
                if use.to then use.to:append(friend) end
                return
            end
        end
    end
end

sgs.ai_use_priority["meizlzefucard"] = 10
sgs.ai_use_value["meizlzefucard"] = 2.45
sgs.ai_card_intention.meizlzefucard = -80

sgs.ai_can_damagehp.meizljuese = function(self, from, card, to)
    if to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to) then
        local x = math.random(1, 10)
        if x > 4 then
            return true
        end
    end
end


sgs.ai_skill_invoke.meizlkusu = function(self, data)
    local target = data:toPlayer()

    if self:isFriend(target) then
        if self:getOverflow(target) > 2 then
            return true
        else
            return false
        end
    end
    if self:isEnemy(target) then
        return true
    end
    return true
end

sgs.ai_can_damagehp.meizlkusu = function(self, from, card, to)
    if from and to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to)
    then
        return self:isEnemy(from) and
            (getKnownCard(from, self.player, "TrickCard") + getKnownCard(self.player, self.player, "TrickCard") > 0 or from:getHandcardNum() > 3)
    end
end

sgs.ai_skill_use["TrickCard+^Nullification|.|.|hand"] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards)
    for _, card in ipairs(cards) do
        if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") then
            local dummy_use = meizl_use_card(self,card, dummy())
            if dummy_use.card and dummy_use and dummy_use.to then
                if dummy_use.to:isEmpty() and not card:isKindOf("IronChain") then
                    return dummy_use.card:toString()
                else
                    local target_objectname = {}
                    for _, p in sgs.qlist(dummy_use.to) do
                        table.insert(target_objectname, p:objectName())
                    end
                    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
                end
            end
        end
    end
    return "."
end


sgs.ai_skill_playerchosen.meizlchijia = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _, p in sgs.list(targets) do
        if (source_query(self, "doDisCard", p, "he")) and source_query(self.player, "canDiscard", p, "he") then
            return p
        end
    end
    return nil
end

function sgs.ai_cardneed.meizlchijia(to,card)
    return card:getTypeId()==sgs.Card_TypeTrick
end


sgs.ai_skill_invoke.meizlmengyuan = function(self, data)
    local target = data:toPlayer()
    if target and self:isFriend(target) and ((target:getMaxHp() < 3) or self:hasSkills(sgs.need_maxhp_skill, target)) then
        return true
    end
    return false
end

sgs.ai_need_damaged.meizlshangwu = function(self, attacker, player)
    if not player:hasSkill("chanyuan") and player:hasSkill("meizlshangwu") and (player:getStrategyMark("meizlshangwu1") == 0 or player:getStrategyMark("meizlshangwu2") == 0) and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < player:getHp()
        and (player:getHp() > 2 or player:getHp() == 2) then
        return true
    end
    return false
end

sgs.ai_use_revises.meizlshangwu = function(self, card, use)
    if card:isKindOf("Peach") and (self.player:getStrategyMark("meizlshangwu1") < 1 or self.player:getStrategyMark("meizlshangwu2") < 1)
        and self:getCardsNum("Peach", "h") < self.player:getHp() and self.player:getHp() < 4
    then
        return false
    end
end
sgs.need_equip_skill = sgs.need_equip_skill .. "|meizljinguo"

sgs.ai_getBestHp_skill.meizlshangwu = function(owner)
    if owner:getStrategyMark("meizlshangwu1") == 0 then return 2 end
    if owner:getStrategyMark("meizlshangwu2") == 0 then return 1 end
end

sgs.ai_skill_cardask["@meizlmanwu"] = function(self, data)
    local cards = sgs.QList2Table(self.player:getHandcards())
    if #cards <= 1 and self.player:getPile("meizlmanwu"):length() == 1 then return "." end
    local good_enemies = {}
    for _, enemy in ipairs(self.enemies) do
        if enemy:isMale() and source_query(enemy, "getCardCount") > 0 then
            table.insert(good_enemies, enemy)
        end
    end
    if #good_enemies == 0 and (self.player:getPile("meizlmanwu"):length() == 2) then return "." end

    self:sortByKeepValue(cards)
    local xwcard = nil
    for _, card in ipairs(cards) do
        if card:isRed() then
            if isCard("Jink", card, self.player) then
                if not xwcard and self:getCardsNum("Jink") >= 2 then
                    xwcard = card
                end
            elseif self:getOverflow() >= 0
                or (not isCard("Peach", card, self.player) and not (self:isWeak() and isCard("Analeptic", card, self.player))) then
                xwcard = card
            end
            if xwcard then
                break
            end
        end
    end
    if xwcard then return "$" .. xwcard:getKnownEffectiveId() else return "." end
end

sgs.ai_skill_playerchosen.meizlmanwu = function(self, targets)
    local good_enemies = {}
    for _, enemy in ipairs(self.enemies) do
        if enemy:isMale() then
            table.insert(good_enemies, enemy)
        end
    end
    if #good_enemies == 0 then return targets:first() end

    local getCmpValue = function(enemy)
        local value = 0

        if not enemy:getEquips():isEmpty() then
            local len = enemy:getEquips():length()
            if enemy:hasSkills(sgs.lose_equip_skill) then value = value - 0.6 * len end
            if enemy:getArmor() and source_query(self, "needToThrowArmor") then value = value - 1.5 end
            if source_query(enemy, "hasArmorEffect", "silver_lion") then value = value - 0.5 end

            if enemy:getWeapon() then value = value + 0.8 end
            if enemy:getArmor() then value = value + 1 end
            if enemy:getDefensiveHorse() then value = value + 0.9 end
            if enemy:getOffensiveHorse() then value = value + 0.7 end
            if self:getDangerousCard(enemy) then value = value + 0.3 end
            if self:getValuableCard(enemy) then value = value + 0.15 end
        end
        return value
    end

    local cmp = function(a, b)
        return getCmpValue(a) > getCmpValue(b)
    end
    table.sort(good_enemies, cmp)
    return good_enemies[1]
end

sgs.ai_playerchosen_intention.meizlmanwu = 80

local meizlluohong_skill = {}
meizlluohong_skill.name = "meizlluohong"
table.insert(sgs.ai_skills, meizlluohong_skill)
meizlluohong_skill.getTurnUseCard = function(self)
    if not self.player:isKongcheng() and not self.player:getStrategyHasUsed("#meizlluohongcard") then
        return parse_action(self,"#meizlluohongcard:.:")
    end
end

sgs.ai_skill_use_func["#meizlluohongcard"] = function(card, use, self,request)
    self:sort(self.friends_noself, "handcard")
    local cards = sgs.QList2Table(self.player:getCards("he"))
    local needed = {}
    if self.player:isWounded() then
        for _, acard in ipairs(cards) do
            if #needed < self.player:getHp() and acard:isBlack() and not acard:isKindOf("Peach") then
                table.insert(needed, acard:getKnownEffectiveId())
            end
        end
    else
        if (self:getOverflow() > 0) then
            for _, acard in ipairs(cards) do
                if #needed < self:getOverflow() and acard:isBlack() and not acard:isKindOf("Peach") then
                    table.insert(needed, acard:getKnownEffectiveId())
                end
            end
        end
    end
    if #needed > 0 then
        use.card = parse_action(self,"#meizlluohongcard:" .. table.concat(needed, "+") .. ":")
        return
    end
end


sgs.ai_skill_discard.meizljinghong = function(self, discard_num, min_num, optional, include_equip)
    local current = self.room:getCurrent()
    if current and self:isEnemy(current) then
        local to_discard = {}
        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _, fcard in ipairs(cards) do
            if #to_discard < discard_num then
                table.insert(to_discard, fcard:getKnownEffectiveId())
            end
        end
        return to_discard
    end
    return {}
end

sgs.ai_can_damagehp.meizljinghong = function(self, from, card, to)
    if to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to)
    then
        return self:isEnemy(from) and to:getHandcardNum() > 0
    end
end

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|meizljinghong"

sgs.ai_skill_invoke.meizlyuyundying = function(self, data)
    return true
end

sgs.ai_skill_use["@@meizlyuyun"] = function(self, prompt, method, data)
    local first_card, second_card
    local first_found, second_found = false, false
    local use_card = {}
    if self.player:getHandcardNum() >= 2 then
        local cards = self.player:getHandcards()
        cards = sgs.QList2Table(cards)


        self:sortByKeepValue(cards)
        local useAll = false
        for _, fcard in ipairs(cards) do
            first_card = fcard
            first_found = true
            for _, scard in ipairs(cards) do
                if first_card ~= scard and (scard:getSuit() == first_card:getSuit()) then
                    second_card = scard
                    second_found = true
                    break
                end
            end
            if second_card then break end
        end
    end
    local target = self.room:getCurrentDyingPlayer()
    if first_found and second_found and target and self:isFriend(target) then
        table.insert(use_card, first_card:getKnownEffectiveId())
        table.insert(use_card, second_card:getKnownEffectiveId())
        return "#meizlyuyuncard:" .. table.concat(use_card, "+") .. ":"
    end

    return "."
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|meizlyuyun"


sgs.ai_skill_use["@@meizlhuhun"] = function(self, prompt)
    local target
    self:updatePlayers()
    self:sort(self.enemies, "defense")

    if source_query(self, "needBear") then return "." end

    local selfSub = self.player:getHp() - self.player:getHandcardNum()
    local selfDef = sgs.getDefense(self.player)
    local slash = clone_preview(self,"slash")

    for _, enemy in ipairs(self.enemies) do
        local def = source_query(self, "getDefenseSlash", enemy)

        local eff = source_query(self, "slashIsEffective", slash, enemy) and source_query(self, "isGoodTarget", enemy, self.enemies, slash)

        if not source_query(self.player, "canSlash", enemy, slash, false) then
        elseif source_query(self, "slashProhibit", nil, enemy) then
        elseif def < 6 and eff and source_query(self.player, "distanceTo", enemy) <= 1 then
            return "#meizlhuhuncard:.:->" .. enemy:objectName()
        elseif selfSub >= 2 then
            return "."
        elseif selfDef < 6 then
            return "."
        end
    end

    for _, enemy in ipairs(self.enemies) do
        local def = sgs.getDefense(enemy)
        local eff = source_query(self, "slashIsEffective", slash, enemy) and source_query(self, "isGoodTarget", enemy, self.enemies, slash) and
            source_query(self.player, "inMyAttackRange", enemy)

        if not source_query(self.player, "canSlash", enemy, slash, false) then
        elseif source_query(self, "slashProhibit", nil, enemy) then
        elseif eff and def < 8 and source_query(self.player, "distanceTo", enemy) <= 1 then
            return "#meizlhuhuncard:.:->" .. enemy:objectName()
        else
            return "."
        end
    end
    return "."
end
sgs.ai_skill_invoke.meizlhuhun = function(self, data)
    return true
end

sgs.ai_skill_invoke.meizlxuechou = function(self, data)
    local slash = clone_preview(self,"slash")

    local current = self.room:getCurrent()
    if not current or current:isDead() then
        return true
    end
    if current:objectName() == self.player:objectName() then
        return true
    end
    if self:isEnemy(current) and source_query(self, "slashIsEffective", slash, current) and source_query(self, "isGoodTarget", current, self.enemies, slash) and not source_query(self, "slashProhibit", slash, current) then
        return true
    end
    return false
end


sgs.ai_skill_invoke.meizlmuniu = function(self, data)
    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _, fcard in ipairs(cards) do
        if fcard:isKindOf("TrickCard") then
            return true
        end
    end
    return false
end
function sgs.ai_cardneed.meizlmuniu(to,card)
    return source_query(card, "isNDTrick")
end


local meizlyincai_skill = {}
meizlyincai_skill.name = "meizlyincai"
table.insert(sgs.ai_skills, meizlyincai_skill)
meizlyincai_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getStrategyMark("@meizlyincai") > 0 then
        local use_card = parse_action(self,"#meizlyincaicard:.:")
        return use_card
    end
end
sgs.ai_skill_use_func["#meizlyincaicard"] = function(card, use, self,request)
    use.card = card
    return
end
sgs.ai_use_value.meizlyincaicard = 4.4
sgs.ai_use_priority.meizlyincaicard = 2.8

local meizlzhixi_skill = {}
meizlzhixi_skill.name = "meizlzhixi"
table.insert(sgs.ai_skills, meizlzhixi_skill)
meizlzhixi_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meizlzhixicard") and not self.player:isKongcheng() then
        return parse_action(self,"#meizlzhixicard:.:")
    end
end

sgs.ai_skill_use_func["#meizlzhixicard"] = function(card, use, self,request)
    self:sort(self.enemies, "handcard")
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards)
    for _, enemy in ipairs(self.enemies) do
        if enemy:getPile("meizlzhixi"):isEmpty() then
            use.card = parse_action(self,"#meizlzhixicard:" .. cards[1]:getEffectiveId() .. ":")
            if use.to then use.to:append(enemy) end
            return
        end
    end
end

sgs.ai_skill_playerchosen.meizlzhixi = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if self:isEnemy(target) then
            return target
        end
    end
    return nil
end


local meizlzhenshi_skill = {}
meizlzhenshi_skill.name = "meizlzhenshi"
table.insert(sgs.ai_skills, meizlzhenshi_skill)
meizlzhenshi_skill.getTurnUseCard = function(self)
    if not self.player:isWounded() and not self.player:getStrategyHasUsed("#meizlzhenshicard") then
        return parse_action(self,"#meizlzhenshicard:.:")
    end
end

sgs.ai_skill_use_func["#meizlzhenshicard"] = function(card, use, self,request)
    self:sort(self.friends_noself, "handcard")
    local cards = sgs.QList2Table(self.player:getCards("he"))

    if self:isWeak() then
        if self.player:getEquips():length() < 2 then
            use.card = parse_action(self,"#meizlzhenshicard:.:")
            return
        end
        if not (self.player:getHandcardNum() > 4) then
            use.card = parse_action(self,"#meizlzhenshicard:.:")
            return
        end
    end
end
sgs.ai_skill_choice.meizlzhenshi = function(self, choices, data)
    if self:isWeak() then
        if self.player:getEquips():length() < 2 then
            return "meizlzhenshie"
        end
        if not (self.player:getHandcardNum() > 4) then
            return "meizlzhenshih"
        end
    end
end
sgs.need_equip_skill = sgs.need_equip_skill .. "|meizlzhenshi"

sgs.ai_skill_invoke.meizlhuanji = function(self, data)
    local dying = 0
    local handang = self.room:findPlayerBySkillName("nosjiefan")
    for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
        if aplayer:getHp() < 1 and not aplayer:hasSkill("nosbuqu") then
            dying = 1
            break
        end
    end
    if handang and self:isFriend(handang) and dying > 0 then return false end

    local use = data:toCardUse()

    local current = self.room:getCurrent()
    if current and self:isFriend(current) and self.player:isChained() and self:isGoodChainTarget(self.player, current) then return false end --內奸跳反會有問題，非屬性殺也有問題。但狀況特殊，八卦陣原碼資訊不足，暫時這樣寫。

    if self.player:getHandcardNum() == 1 and self:getCardsNum("Jink") == 1 and self.player:hasSkills("zhiji|beifa") and self:needKongcheng() then
        local enemy_num = self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player)
        if self.player:getHp() > enemy_num and enemy_num <= 1 then return false end
    end
    if handang and self:isFriend(handang) and dying > 0 then return false end
    if source_query(self, "needToLoseHp", self.player, use.from, use.card) then return false end
    if self:getCardsNum("Jink") == 0 then return true end

    return true
end

sgs.ai_skill_use["@@meizlkaoshang"] = function(self, prompt)
    self:sort(self.friends_noself, "handcard")
    local cards = sgs.QList2Table(self.player:getCards("he"))

    local equips = {}
    for _, card in sgs.qlist(self.player:getHandcards()) do
        if card:isKindOf("Armor") or card:isKindOf("Weapon") then
            if not self:getSameEquip(card) then
            elseif card:isKindOf("GudingBlade") and self:getCardsNum("Slash") > 0 then
                local HeavyDamage
                local slash = self:getCard("Slash")
                for _, enemy in ipairs(self.enemies) do
                    if source_query(self.player, "canSlash", enemy, slash, true) and not source_query(self, "slashProhibit", slash, enemy) and
                        source_query(self, "slashIsEffective", slash, enemy) and enemy:isKongcheng() then
                        HeavyDamage = true
                        break
                    end
                end
                if not HeavyDamage then table.insert(equips, card) end
            else
                table.insert(equips, card)
            end
        elseif card:getTypeId() == sgs.Card_TypeEquip then
            table.insert(equips, card)
        end
    end
    local ecards = self.player:getCards("e")
    ecards = sgs.QList2Table(ecards)

    for _, ecard in ipairs(ecards) do
        if ecard:isKindOf("Weapon") or ecard:isKindOf("OffensiveHorse") then
            table.insert(equips, ecard)
        end
    end

    if #equips == 0 then return "." end

    local select_equip, target
    for _, friend in ipairs(self.friends_noself) do
        for _, equip in ipairs(equips) do
            local equip_index = source_query(equip, "getEquipSlot")
            if not self:getSameEquip(equip, friend) and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) and friend:getEquip(equip_index) == nil and source_query(friend, "hasEquipArea", equip_index) then
                for _, enemy in ipairs(self.enemies) do
                    if (enemy:objectName() ~= friend:objectName()) and source_query(friend, "distanceTo", enemy) <= source_query(friend, "getAttackRange") and not source_query(self, "cantbeHurt", enemy) and source_query(self, "damageIsEffective", enemy) and source_query(self, "canAttack", enemy, friend) then
                        target = friend
                        select_equip = equip
                        break
                    end
                end
            end
        end
        if target then break end
        for _, equip in ipairs(equips) do
            local equip_index = source_query(equip, "getEquipSlot")
            if not self:getSameEquip(equip, friend) and friend:getEquip(equip_index) == nil and source_query(friend, "hasEquipArea", equip_index) then
                for _, enemy in ipairs(self.enemies) do
                    if (enemy:objectName() ~= friend:objectName()) and source_query(friend, "distanceTo", enemy) <= source_query(friend, "getAttackRange") and not source_query(self, "cantbeHurt", enemy) and source_query(self, "damageIsEffective", enemy) and source_query(self, "canAttack", enemy, friend) then
                        target = friend
                        select_equip = equip
                        break
                    end
                end
            end
        end
        if target then break end
    end



    if target and select_equip then
        return "#meizlkaoshangcard:" .. select_equip:getKnownId() .. ":->" .. target:objectName()
    end
    return "."
end

ai_audited_aliases.register{id="ai_skill_playerchosen.meizlkaoshangcard",defer_canonical=true,self_index=1,registry="ai_skill_playerchosen",path={"meizlkaoshangcard"},canonical_registry="ai_skill_playerchosen",canonical_path={"damage"}}
sgs.need_equip_skill = sgs.need_equip_skill .. "|meizlkaoshang"
local meizlkaoshang_filter = function(self,player,carduse)
    if carduse.card:isKindOf("meizlkaoshangCard") then
        self:setEventMemory("ai_quhu_effect",true)
    end
end

table.insert(sgs.ai_choicemade_filter.cardUsed,meizlkaoshang_filter)


function sgs.ai_slash_prohibit.meizlbiyin(self, from, to, card)
    if to:getStrategyMark("@meizlbiyinx") > 0 then return true end
end

sgs.ai_target_revises["@meizlbiyinx"] = function(to, card, self)
    return card and card:isKindOf("Slash")
end

local meizlbiyin_skill = {}
meizlbiyin_skill.name = "meizlbiyin"
table.insert(sgs.ai_skills, meizlbiyin_skill)
meizlbiyin_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meizlbiyincard") and not self.player:isKongcheng() and self.player:getStrategyMark("@meizlbiyin") > 0 then
        return parse_action(self,"#meizlbiyincard:.:")
    end
end

sgs.ai_skill_use_func["#meizlbiyincard"] = function(card, use, self,request)
    self:sort(self.friends, "hp")
    local targets = {}
    local lord = self.room:getLord()
    self:sort(self.friends, "defense")
    if lord and lord:getStrategyMark("@meizlbiyinx") == 0 and self:isFriend(lord) and not sgs.isLordHealthy() and not source_query(self.player, "isLord") and not hasBuquEffect(lord)
        and not (lord:hasSkill("hunzi") and lord:getStrategyMark("hunzi") == 0 and lord:getHp() > 1) then
        table.insert(targets, lord)
    else
        for _, friend in ipairs(self.friends) do
            if friend:getStrategyMark("@meizlbiyinx") == 0 and self:isWeak(friend) and not hasBuquEffect(friend)
                and not (friend:hasSkill("hunzi") and friend:getStrategyMark("hunzi") == 0 and friend:getHp() > 1) then
                table.insert(targets, friend)
                break
            end
        end
    end
    if self:isWeak() then table.insert(targets, self.player) end
    if #targets > 0 then
        use.card = parse_action(self,"#meizlbiyincard:.:")
        if use.to then use.to:append(targets[1]) end
        return
    end
end

local meizlkuangji_skill = {}
meizlkuangji_skill.name = "meizlkuangji"
table.insert(sgs.ai_skills, meizlkuangji_skill)
meizlkuangji_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meizlkuangjicard") and not self.player:isNude() then
        if self.player:getStrategyMark("@meizlbiyin") == 0 and self.player:getLostHp() < 2 and self.player:getStrategyMark("@meizlkuangji") == 0 then
            return parse_action(self,"#meizlkuangjicard:.:")
        end
    end
end

sgs.ai_skill_use_func["#meizlkuangjicard"] = function(card, use, self,request)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    local needed = {}
    if (self.player:getHandcardNum() > 0) then
        for _, acard in ipairs(cards) do
            if #needed < 1 and not acard:isKindOf("Peach") then
                table.insert(needed, acard:getKnownEffectiveId())
            end
        end
    end
    if #needed > 0 then
        for _, enemy in ipairs(self.enemies) do
            if self.player:getStrategyMark("@meizlbiyin") == 0 and self.player:getLostHp() < 2 and self.player:getStrategyMark("@meizlkuangji") == 0 then
                use.card = parse_action(self,"#meizlkuangjicard:" .. table.concat(needed, "+") .. ":")
                return
            end
        end
    end
end

ai_audited_aliases.register{id="ai_cardneed.meizlhuyi",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlhuyi"},canonical_registry="ai_cardneed",canonical_path={"slash"}}


local meizlbiyi_skill = {}
meizlbiyi_skill.name = "meizlbiyi"
table.insert(sgs.ai_skills, meizlbiyi_skill)
meizlbiyi_skill.getTurnUseCard = function(self)
    if (self.player:getStrategyMark("@meizlbiyi") > 0) then
        local x = math.random(1, 10)
        if x >= 5 then
            return parse_action(self,"#meizlbiyicard:.:")
        end
    end
end

sgs.ai_skill_use_func["#meizlbiyicard"] = function(card, use, self,request)
    use.card = parse_action(self,"#meizlbiyicard:.:")
    return
end

sgs.ai_skill_invoke.meizlxiuse = function(self, data)
    if #self.friends_noself > 0 then
        return true
    end
    return false
end

sgs.ai_skill_playerchosen.meizlxiuse = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    local max = 0
    local target
    for _, friend in ipairs(self.friends_noself) do
        local x = self:ImitateResult_DrawNCards(friend, friend:getVisibleSkillList(true))
        if x > max and not source_query(self, "willSkipPlayPhase", friend) then
            target = friend
            max = x
        end
    end
    if target then
        return target
    end
    return targets[1]
end
sgs.ai_playerchosen_intention["meizlxiuse"] = -80


local meizlhuawu_skill = {}
meizlhuawu_skill.name  = "meizlhuawu"
table.insert(sgs.ai_skills, meizlhuawu_skill)
meizlhuawu_skill.getTurnUseCard = function(self)
    if source_query(self, "needBear") then return end

    local n = self.player:getHandcardNum()
    if n < 1 then return end
    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    local usecards = {}
    local getOverflow = math.max(self:getOverflow(), 0)
    local discards = self:askForDiscard("dummyreason", math.min(getOverflow, 5), math.min(getOverflow, 5), false, true, ".")
    if self:needKongcheng() and n < 6 then
        for _, card in ipairs(cards) do
            table.insert(usecards, card:getKnownId())
        end
    else
        for _, card in ipairs(discards) do
            table.insert(usecards, card)
        end
    end
    if #usecards > 0 then
        return parse_action(self,"#meizlhuawucard:" .. table.concat(usecards, "+") .. ":")
    end
    return nil
end

sgs.ai_skill_use_func["#meizlhuawucard"] = function(card, use, self,request)
    use.card = card
    return
end

sgs.ai_can_damagehp.meizlpingting = function(self, from, card, to)
    if from and to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to)
    then
        return true
    end
end

sgs.ai_skill_use["@@meizlyanhong"] = function(self, prompt)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards)
    local current = self.room:getCurrent()
    if current then
        if self:isFriend(current) then
            if (current:getJudgingArea():length() > 0) then
                for _, card in ipairs(cards) do
                    if card:getSuit() == sgs.Card_Diamond then
                        return "#meizlyanhongcard:" .. card:getKnownId() .. ":"
                    end
                end
            end
            if (self:getOverflow(current, true) > 1 and (self.player:getHandcardNum() > 2)) then
                for _, card in ipairs(cards) do
                    if card:getSuit() == sgs.Card_Heart and not card:isKindOf("Peach") then
                        return "#meizlyanhongcard:" .. card:getKnownId() .. ":"
                    end
                end
            end
        elseif self:isEnemy(current) then
            if (self:getOverflow(current, true) > 0) then
                for _, card in ipairs(cards) do
                    if card:getSuit() == sgs.Card_Spade then
                        return "#meizlyanhongcard:" .. card:getKnownId() .. ":"
                    end
                end
            end
            if (current:getHandcardNum() < 2) then
                for _, card in ipairs(cards) do
                    if card:getSuit() == sgs.Card_Club then
                        return "#meizlyanhongcard:" .. card:getKnownId() .. ":"
                    end
                end
            end
        end
    end

    return "."
end

sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|meizlyanhong"

local meizlyangxiu_skill = {}
meizlyangxiu_skill.name  = "meizlyangxiu"
table.insert(sgs.ai_skills, meizlyangxiu_skill)
meizlyangxiu_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@meizlyangxiu") == 0 then return nil end
    if #self.enemies == 0 then return nil end
    if not ((self.player:getPile("meizlshan"):length() > 0) and (self.player:getPile("meizlqun"):length() > 0) and (self.player:getPile("meizlhua"):length() > 0)) then return nil end
    if self:isWeak() or (self.player:getPile("meizlhua"):length() > 2) then
        return parse_action(self,"#meizlyangxiucard:.:")
    end
    return nil
end

sgs.ai_skill_use_func["#meizlyangxiucard"] = function(card, use, self,request)
    local targets = AIList.new({})
    self:sort(self.enemies, "defense")
    for _, enemy in ipairs(self.enemies) do
        if (targets:length() < self.player:getPile("meizlqun"):length()) then
            if (source_query(self, "damageIsEffective", enemy) and not source_query(self, "cantbeHurt", enemy, self.player, 2)) and source_query(self.player, "inMyAttackRange", enemy) and source_query(self, "canAttack", enemy, self.player) then
                targets:append(enemy)
            end
        else
            break
        end
    end
    use.card = card
    if use.to then use.to = targets end
end



sgs.ai_ajustdamage_from.meispfengdan = function(self, from, to, card, nature)
    if from and card and (card:isKindOf("Slash") or card:isKindOf("Duel"))
    then
        return from:getStrategyMark("@meispfeng")
    end
end

local meispliwu_skill = {}
meispliwu_skill.name = "meispliwu"
table.insert(sgs.ai_skills, meispliwu_skill)
meispliwu_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meispliwucard") then
        if self.player:getStrategyMark("@meispliwuprevent") == 0 and self.player:getStrategyMark("@meispfeng") >= 2 and self.player:getKnownKingdom() == "shu" then
            return parse_action(self,"#meispliwucard:.:")
        end
    end
end

sgs.ai_skill_use_func["#meispliwucard"] = function(card, use, self,request)
    use.card = card
    return
end

local meispliwuskill2_skill = {}
meispliwuskill2_skill.name = "meispliwuskill2"
table.insert(sgs.ai_skills, meispliwuskill2_skill)
meispliwuskill2_skill.getTurnUseCard = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)

    if self.player:getPile("wooden_ox"):length() > 0 then
        for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
            table.insert(cards, known_card(self,id))
        end
    end

    local jink_card

    self:sortByUseValue(cards, true)

    for _, card in ipairs(cards) do
        if card:isKindOf("Jink") then
            jink_card = card
            break
        end
    end

    if not jink_card then return nil end
    local suit = jink_card:getSuitString()
    local number = source_query(jink_card, "getNumberString")
    local card_id = jink_card:getKnownEffectiveId()
    local card_str = ("slash:meispliwuskill2[%s:%s]=%d"):format(suit, number, card_id)
    local slash = parse_action(self,card_str)
    assert(slash)

    return slash
end

sgs.ai_view_as.meispliwuskill2 = function(card, player, card_place)
    local self=known(player:getRoom()._ai,"viewer AI")
    if known(self.request.reason,"current card use reason") ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
    local suit = card:getSuitString()
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
        if card:isKindOf("Jink") then
            return ("slash:meispliwuskill2[%s:%s]=%d"):format(suit, number, card_id)
        elseif card:isKindOf("Slash") then
            return ("jink:meispliwuskill2[%s:%s]=%d"):format(suit, number, card_id)
        end
    end
end


sgs.ai_use_value["meispliwucard"] = 2      --卡牌使用价值
sgs.ai_use_priority["meispliwucard"] = 3.5 --卡牌使用优先级



local meispruixue_skill = {}
meispruixue_skill.name = "meispruixue"
table.insert(sgs.ai_skills, meispruixue_skill)
meispruixue_skill.getTurnUseCard = function(self)
    if not (self.player:getStrategyMark("@meispruixue") > 0 and self.player:getKnownKingdom() == "qun") then return end
    return parse_action(self,"#meispruixuecard:.:")
end
sgs.ai_skill_use_func["#meispruixuecard"] = function(card, use, self,request)
    self:updatePlayers()
    self:sort(self.enemies, "defense")
    local acard = parse_action(self,"#meispruixuecard:.:") --根据卡牌构成字符串产生实际将使用的卡牌
    assert(acard)
    local defense = 6
    local selfSub = self.player:getHandcardNum() - self.player:getHp()
    if #self.enemies <= 1 then return "." end
    local best_target
    for _, enemy in ipairs(self.enemies) do
        local def = sgs.getDefense(enemy)
        local slash = clone_preview(self,"slash")

        local eff = source_query(self, "slashIsEffective", slash, enemy) and source_query(self, "isGoodTarget", enemy, self.enemies, slash) and
            source_query(self.player, "distanceTo", enemy) - math.min(self.player:getHp() - 1, self:getCardsNum("Slash")) <= 1

        if not source_query(self.player, "canSlash", enemy, slash, false) then
        elseif source_query(self, "slashProhibit", nil, enemy) then
        elseif eff then
            if enemy:getHp() == 1 and getCardsNum("Jink", enemy) == 0 then
                best_target = enemy
                break
            end
            if def < defense then
                best_target = enemy
                defense = def
            end
            target = enemy
        end
        if selfSub < 0 then return "." end
    end
    if best_target then
        if self:getCardsNum("Slash") > 1 then
            use.card = acard
        end
    end
    if target then
        if self:getCardsNum("Slash") > 1 then
            use.card = acard
        end
    end
    for _, c in sgs.qlist(self.player:getHandcards()) do
        local x = nil
        if isCard("ArcheryAttack", c, self.player) then
            x = clone_preview(self,"ArcheryAttack")
        elseif isCard("SavageAssault", c, self.player) then
            x = clone_preview(self,"SavageAssault")
        else
            continue
        end

        local dummy_use = meizl_use_card(self,x, dummy())

        if (dummy_use.card) and self.player:getHp() > 1 then use.card = acard end

    end
end

sgs.ai_use_value["meispruixuecard"] = 2    --卡牌使用价值
sgs.ai_use_priority["meispruixuecard"] = 3 --卡牌使用优先级



local meichunjiefuli_skill = {}
meichunjiefuli_skill.name = "meichunjiefuli"
table.insert(sgs.ai_skills, meichunjiefuli_skill)
meichunjiefuli_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meichunjiefulicard") then
        if (self.player:getStrategyMark("@meispfeng") > 0) and self.player:getKnownKingdom() ~= "shu" then
            return parse_action(self,"#meichunjiefulicard:.:")
        end
        if (self.player:getStrategyMark("@meispruixue") > 0) and self.player:getKnownKingdom() ~= "qun" then
            return parse_action(self,"#meichunjiefulicard:.:")
        end
    end
end

sgs.ai_skill_use_func["#meichunjiefulicard"] = function(card, use, self,request)
    use.card = card
    return
end

sgs.ai_skill_choice["meispniangzhaoyunkingdom"] = function(self, choices)
    local items = choices:split("+")
    if #items == 1 then
        return items[1]
    else
        if (self.player:getStrategyMark("@meispfeng") > 0) and self.player:getKnownKingdom() ~= "shu" then
            return "shu"
        end
        if (self.player:getStrategyMark("@meispruixue") > 0) and self.player:getKnownKingdom() ~= "qun" then
            local defense = 6
            local selfSub = self.player:getHandcardNum() - self.player:getHp()
            if #self.enemies <= 1 then return "shu" end
            local slash = clone_preview(self,"slash")

            for _, enemy in ipairs(self.enemies) do
                local def = sgs.getDefense(enemy)

                local eff = source_query(self, "slashIsEffective", slash, enemy) and source_query(self, "isGoodTarget", enemy, self.enemies, slash) and
                    source_query(self.player, "distanceTo", enemy) - math.min(self.player:getHp() - 1, self:getCardsNum("Slash")) <= 1

                if not source_query(self.player, "canSlash", enemy, slash, false) then
                elseif source_query(self, "slashProhibit", nil, enemy) then
                elseif eff then
                    if enemy:getHp() == 1 and getCardsNum("Jink", enemy) == 0 then
                        best_target = enemy
                        break
                    end
                    if def < defense then
                        best_target = enemy
                        defense = def
                    end
                    target = enemy
                end
                if selfSub < 0 then return "." end
            end
            if best_target then
                if self:getCardsNum("Slash") > 1 then
                    return "qun"
                end
            end
            if target then
                if self:getCardsNum("Slash") > 1 then
                    return "qun"
                end
            end
            for _, c in sgs.qlist(self.player:getHandcards()) do
                local x = nil
                if isCard("ArcheryAttack", c, self.player) then
                    x = clone_preview(self,"ArcheryAttack")
                elseif isCard("SavageAssault", c, self.player) then
                    x = clone_preview(self,"SavageAssault")
                else
                    continue
                end

                local du = { isDummy = true }
                self:useTrickCard(x, du)

                if (du.card) and self.player:getHp() > 1 then return "qun" end

            end
        end
    end
    return "shu"
end
sgs.ai_use_value["meichunjiefulicard"] = 2      --卡牌使用价值
sgs.ai_use_priority["meichunjiefulicard"] = 3.5 --卡牌使用优先级


sgs.ai_skill_use["@@meispbaiyue"] = function(self, prompt)
    self:sort(self.friends_noself, "handcard")
    local cards = sgs.QList2Table(self.player:getCards("he"))
    local values, range = {}, source_query(self.player, "getAttackRange")
    local nplayer = self.player
    for i = 1, source_query(self.player, "aliveCount") do
        local fediff, add, isfriend = 0, 0
        local np = nplayer
        for value = #self.friends_noself, 1, -1 do
            np = np:getNextAlive()
            if np:objectName() == self.player:objectName() then
                if self:isFriend(nplayer) then
                    fediff = fediff + value
                else
                    fediff = fediff - value
                end
            else
                if self:isFriend(np) then
                    fediff = fediff + value
                    if isfriend then
                        add = add + 1
                    else
                        isfriend = true
                    end
                elseif self:isEnemy(np) then
                    fediff = fediff - value
                    isfriend = false
                end
            end
        end
        values[nplayer:objectName()] = fediff + add
        nplayer = nplayer:getNextAlive()
    end
    local function get_value(a)
        local ret = 0
        for _, enemy in ipairs(self.enemies) do
            if a:objectName() ~= enemy:objectName() and source_query(a, "distanceTo", enemy) <= range then ret = ret + 1 end
        end
        return ret
    end
    local function compare_func(a, b)
        if values[a:objectName()] ~= values[b:objectName()] then
            return values[a:objectName()] > values[b:objectName()]
        else
            return get_value(a) > get_value(b)
        end
    end
    local players = sgs.QList2Table(self.room:getAlivePlayers())
    table.sort(players, compare_func)
    if values[players[1]:objectName()] > 0 and players[1]:objectName() ~= self.player:objectName() then
        return "#meispbaiyuecard:.:->" .. players[1]:objectName()
    end
    return "."
end

sgs.ai_skill_playerchosen["meispshuzhuang"] = function(self, targets)
    local targets = sgs.QList2Table(targets)
    self:sort(targets, "hp")
    for _, p in ipairs(targets) do
        if self:isEnemy(p) and not hasZhaxiangEffect(p) then
            return p
        end
    end
    for _, p in ipairs(targets) do
        if self:isFriend(p) and not self:isWeak(p) and hasZhaxiangEffect(p) and not source_query(self, "willSkipPlayPhase", p) then
            return p
        end
    end
    for _, p in ipairs(targets) do
        return p
    end
end

sgs.ai_playerchosen_intention["meispshuzhuang"] = function(self, from, to)
    local intention = 50
    if hasZhaxiangEffect(to) then
        intention = -intention
    end
    self:updateIntention(from, to, intention)
end


sgs.ai_skill_invoke.meispxiaoji = function(self, data)
    local target = data:toPlayer()
    if self:isEnemy(target) then
        return source_query(self, "doDisCard", target, "he")
    end
    return not self:isFriend(target)
end

sgs.ai_skill_use["@@meispxiaoji"] = function(self, prompt)
    local cards = sgs.QList2Table(self.player:getHandcards())
    local card
    if (self.player:getHandcardNum() >= 2) then
        self:sortByKeepValue(cards)
        for _, cd in ipairs(cards) do
            if not cd:isKindOf("Peach") then
                card = cd
                break
            end
        end
        local target
        local slash = clone_preview(self,"slash")

        local dummy_use = meizl_use_card(self,slash, dummy())
        if not dummy_use.to:isEmpty() then
            for _, p in sgs.qlist(dummy_use.to) do
                target = p
            end
        end
        if target and card then
            return "#meispxiaojicard:" .. card:getKnownEffectiveId() .. ":->" .. target:objectName()
        end
    else
        for _, enemy in ipairs(self.enemies) do
            if (enemy:getPile("meispji"):length() > 0) and not enemy:isNude() then
                local ints = sgs.QList2Table(enemy:getPile("meispji"))
                local x = math.min(enemy:getPile("meispji"):length(), enemy:getCards("he"):length())
                local cardx = {}
                for _, key in sgs.list(enemy:getPileNames()) do
                    for _, id in sgs.qlist(enemy:getPile(key)) do
                        table.insert(cardx, known_card(self,id))
                    end
                end
                for i = 1, x, 1 do
                    table.insert(cardx, tostring(enemy:getPile("meispji")[i]))
                end
                return "#meispxiaojicard:" .. table.concat(cardx, "+") .. ":->" .. enemy:objectName()
            end
        end
    end
    return "."
end

ai_audited_aliases.register{id="ai_cardneed.meispxiaoji",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meispxiaoji"},canonical_registry="ai_cardneed",canonical_path={"slash"}}
ai_audited_aliases.register{id="ai_cardneed.meispzhanhun",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meispzhanhun"},canonical_registry="ai_cardneed",canonical_path={"slash"}}

sgs.ai_skill_invoke.meispzhiji = function(self, data)
    local target = data:toPlayer()
    local Piles = target:getPileNames()
    local dummy = clone_preview(self,"slash", sgs.Card_NoSuit, 0)

    local material_count=0
    for i=1,#Piles do material_count=material_count+source_query(target, "getPileCount", Piles[i])end
    if self:isEnemy(target) then
        if (source_query(target, "getPileCount", "meispji") > 0) then
            return false
        end
        if material_count > 1 then
            return true
        end
        return false
    end
    if self:isFriend(target) then
        if (source_query(target, "getPileCount", "meispji") > 0) then
            return true
        end
        if material_count > 0 then
            return false
        end
        return true
    end
    return false
end



sgs.ai_skill_use["@@meispzhiji"] = function(self, prompt)
    local targets = {}
    for _, enemy in ipairs(self.enemies) do
        for _, key in sgs.list(enemy:getPileNames()) do
            for _, id in sgs.qlist(enemy:getPile(key)) do
                if not table.contains(targets, enemy) then
                    table.insert(targets, enemy)
                end
            end
        end
    end
    local target = self:findPlayerToDiscard("he", false, true, targets, false)[1]
    if target then
        return "#meispzhijicard:.:->" .. target:objectName()
    end
    return "."
end

ai_audited_aliases.register{id="ai_cardneed.meisproulin",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meisproulin"},canonical_registry="ai_cardneed",canonical_path={"slash"}}

sgs.hit_skill = sgs.hit_skill .. "|meisproulin"



sgs.ai_skill_invoke.meispzlbhbaiyue = function(self, data)
    local slash = clone_preview(self,"Slash")

    if self:UseAoeSkillValue_mei(sgs.DamageStruct_Normal, nil, slash) > 0 or self:isWeak() then
        return true
    end
    return false
end

sgs.ai_skill_playerchosen.meispzlbhshuzhuang = function(self, targets)
    self:sort(self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        return enemy
    end
    return targets[1]
end


sgs.ai_playerchosen_intention["meispzlbhshuzhuang"] = function(self, from, to)
    self:updateIntention(from, to, 80)
end



sgs.ai_skill_cardask["@meizlselueduo"] = function(self, data)
    local cards = sgs.QList2Table(self.player:getHandcards())

    local current = self.room:getCurrent()
    local xwcard = nil
    if current and self:isEnemy(current) and current:getHandcardNum() - current:getHp() > 2 then


        self:sortByKeepValue(cards)

        for _, card in ipairs(cards) do
            if card:isKindOf("TrickCard") then
                xwcard = card
            end
            if xwcard then
                break
            end
        end
    end
    if xwcard then
        return "$" .. xwcard:getKnownEffectiveId()
    else
        return "."
    end
end


sgs.ai_skill_invoke.meizlselueduo = function(self, data)
    local target = data:toPlayer()
    if target and self:isEnemy(target) and target:getHandcardNum() - target:getHp() > 2 then
        return not self:isWeak()
    end
    return false
end

sgs.ai_choicemade_filter.skillInvoke.meizlselueduo = function(self, player, promptlist)
    local current = self.room:getCurrent()
    if current then
        if promptlist[#promptlist] == "yes" and player:getStrategyMark("@meizlsetanlan") == 0 then
            self:updateIntention(player, current, 80)
        end
    end
end

sgs.ai_choicemade_filter.cardResponded["@meizlselueduo"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then

        local current = self.room:getCurrent()
        if not current then return end
        self:updateIntention(player, current, 80)
    end
end


local meizlsetanlan_skill = {}
meizlsetanlan_skill.name = "meizlsetanlan"
table.insert(sgs.ai_skills, meizlsetanlan_skill)
meizlsetanlan_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meizlsetanlancard") then
        if self.player:getStrategyMark("@meizlsetanlan") == 0 and self.player:getHp() <= 2 then
            return parse_action(self,"#meizlsetanlancard:.:")
        end
    end
end

sgs.ai_skill_use_func["#meizlsetanlancard"] = function(card, use, self,request)
    use.card = card
    return
end

function SmartAIView:findyoushaTarget(card_name, use)
    local lord = self.room:getLord()

    local findFriend_maxSlash = function(self, first)

        local nos_fazheng, fazheng
        for _, friend in ipairs(self.friends_noself) do
            if friend:isMale() then
                if friend:hasSkill("nosenyuan") and friend:getHp() > 1 then nos_fazheng = friend end
                if friend:hasSkill("enyuan") and friend:getHp() > 1 then fazheng = friend end
                if (source_query(self, "needToLoseHp", friend, first)) and not self:dontHurt(friend, first) then
                    set_state(self,"friend_maxSlash",friend)
                end
            end
        end

        if get_state(self,"friend_maxSlash") then
            local safe = false
            if self:hasSkills("neoganglie|vsganglie|fankui|enyuan|ganglie|nosenyuan", first) then
                if (first:getHp() <= 1 and first:getHandcardNum() == 0) then safe = true end
            end
            if safe then return get_state(self,"friend_maxSlash") end
        end
        if nos_fazheng or fazheng then return nos_fazheng or fazheng end --备用友方，各种恶心的法正
        return nil
    end

    if self.role == "rebel" or (self.role == "renegade" and role_count(self,"loyalist") + 1 > role_count(self,"rebel")) then
        if lord and lord:isMale() and lord:objectName() ~= self.player:objectName() then -- 优先离间1血忠和主
            self:sort(self.enemies, "handcard")
            local e_peaches = 0
            local loyalist

            for _, enemy in ipairs(self.enemies) do
                e_peaches = e_peaches + getCardsNum("Peach", enemy)
                if enemy:getHp() == 1 and source_query(self, "canAttack", enemy, lord) and source_query(self, "canAttack", lord, enemy) and enemy:objectName() ~= lord:objectName()
                    and enemy:isMale() and not loyalist then
                    loyalist = enemy
                    break
                end
            end

            if loyalist and e_peaches < 1 then return loyalist, lord end
        end

        if #self.friends_noself >= 2 and source_query(self, "getAllPeachNum") < 1 then --收友方反
            local nextplayerIsEnemy
            local nextp = self.player:getNextAlive()
            for i = 1, self.room:alivePlayerCount() do
                if not source_query(self, "willSkipPlayPhase", nextp) then
                    if not self:isFriend(nextp) then nextplayerIsEnemy = true end
                    break
                else
                    nextp = nextp:getNextAlive()
                end
            end
            if nextplayerIsEnemy then
                local round = 50
                local to_die, nextfriend
                self:sort(self.enemies, "hp")

                for _, a_friend in ipairs(self.friends_noself) do -- 目标1：寻找1血友方
                    if a_friend:getHp() == 1 and a_friend:isMale() then
                        for _, b_friend in ipairs(self.friends_noself) do --目标2：寻找位于我之后，离我最近的友方
                            if b_friend:objectName() ~= a_friend:objectName() and b_friend:isMale() and self:playerGetRound(b_friend) < round
                                and not self:dontHurt(a_friend, b_friend) and not self:dontHurt(b_friend, a_friend) then
                                round = self:playerGetRound(b_friend)
                                to_die = a_friend
                                nextfriend = b_friend
                            end
                        end
                        if to_die and nextfriend then break end
                    end
                end

                if to_die and nextfriend then return to_die, nextfriend end
            end
        end
    end

    if lord and self:isFriend(lord) and source_query(self, "needToLoseHp", lord) and lord:objectName() ~= self.player:objectName() then
        local enemycount = self:getEnemyNumBySeat(self.player, lord)
        local peaches = source_query(self, "getAllPeachNum")
        if peaches >= enemycount then
            local f_target, e_target
            for _, ap in sgs.list(self.room:getOtherPlayers(self.player)) do
                if ap:objectName() ~= lord:objectName() and ap:isMale() then
                    if self:isFriend(ap) and source_query(self, "needToLoseHp", lord, ap) and source_query(self, "needToLoseHp", ap, lord) then
                        f_target = ap
                    elseif not source_query(self, "cantbeHurt", ap, lord) and not source_query(self, "needToLoseHp", ap, lord) then
                        e_target = ap
                    end
                end
            end
            if f_target or e_target then
                local target
                if f_target then
                    target = f_target
                elseif e_target then
                    target = e_target
                end
                if target then
                    if not use.isDummy then self:setStrategyPlayerFlag(lord,"AIGlobal_NeedToWake",true) end
                    return lord, target
                end
            end
        end
    end

    local shenguanyu = self.room:findPlayerBySkillName("wuhun")
    if shenguanyu and shenguanyu:isMale() and shenguanyu:objectName() ~= self.player:objectName() then
        if self.role == "rebel" and lord and lord:isMale() and lord:objectName() ~= self.player:objectName() and shenguanyu:objectName() ~= lord:objectName()
            and not source_query(self, "hasJueqingEffect", lord, shenguanyu) then
            return shenguanyu, lord
        elseif self:isEnemy(shenguanyu) and #self.enemies >= 2 then
            for _, enemy in ipairs(self.enemies) do
                if enemy:objectName() ~= shenguanyu:objectName() and enemy:isMale() and not source_query(self, "hasJueqingEffect", enemy, shenguanyu) then
                    return shenguanyu, enemy
                end
            end
        end
    end

    if not self.player:getStrategyHasUsed(card_name) then
        self:sort(self.enemies, "defense")
        local males, others = {}, {}
        local first, second

        for _, enemy in ipairs(self.enemies) do
            if enemy:isMale() then
                for _, anotherenemy in ipairs(self.enemies) do
                    if anotherenemy:isMale() and anotherenemy:objectName() ~= enemy:objectName() then
                        if not (source_query(self, "needToLoseHp", enemy, anotherenemy)) and not (source_query(self, "needToLoseHp", anotherenemy, enemy)) then
                            table.insert(males, enemy)
                        else
                            table.insert(others, enemy)
                        end
                        if #males >= 2 then break end
                    end
                end

                if #males >= 2 then break end
            end
        end

        if #males >= 1 and role_estimate(self,males[1]) == "rebel" and males[1]:getHp() == 1 then
            if lord and self:isFriend(lord) and lord:isMale() and lord:objectName() ~= males[1]:objectName()
                and lord:objectName() ~= self.player:objectName() and lord:isAlive() and (source_query(self, "needToLoseHp", lord, males[1]) or not self:isWeak(lord))
            then
                return males[1], lord
            end

            local afriend = findFriend_maxSlash(self, males[1])
            if afriend and afriend:objectName() ~= males[1]:objectName() then
                return males[1], afriend
            end
        end

        if #males == 1 then
            if isLord(males[1]) and source_query(self.room, "getTurnCount") <= 1 and self.role == "rebel" and source_query(self.player, "aliveCount") >= 3 then
                local p_slash, max_p, max_pp = 0, nil, nil
                for _, p in sgs.list(self.room:getOtherPlayers(self.player)) do
                    if p:isMale() and not self:isFriend(p) and p:objectName() ~= males[1]:objectName() then
                        if p:getKnownKingdom() == males[1]:getKingdom() then
                            max_p = p
                            break
                        elseif not max_pp then
                            max_pp = p
                        end
                    end
                end
                if max_p then table.insert(males, max_p) end
                if max_pp and #males == 1 then table.insert(males, max_pp) end
            end
        end

        if #males == 1 then
            if #others >= 1 then
                table.insert(males, others[1])
            end
        end

        if #males >= 2 then
            first = males[1]
            second = males[2]
            if lord and first:getHp() <= 1 then
                if source_query(self.player, "isLord") or isRolePredictable() then
                    local friend_maxSlash = findFriend_maxSlash(self, first)
                    if friend_maxSlash then second = friend_maxSlash end
                elseif lord:isMale() then
                    if self.role == "rebel" and not source_query(first, "isLord") then
                        second = lord
                    else
                        if ((self.role == "loyalist" or self.role == "renegade")) then
                            second = lord
                        end
                    end
                end
            end

            if first and second and first:objectName() ~= second:objectName() then
                return first, second
            end
        end
    end
end

function SmartAIView:getyoushaCard()
    local card_id
    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local lightning = self:getCard("Lightning")

    if source_query(self, "needToThrowArmor") then
        card_id = self.player:getArmor():getId()
    elseif self.player:getHandcardNum() > self.player:getHp() then
        if lightning and not self:willUseLightning(lightning) then
            card_id = lightning:getKnownEffectiveId()
        else
            for _, acard in ipairs(cards) do
                if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
                    and not acard:isKindOf("Peach") then
                    card_id = acard:getKnownEffectiveId()
                    break
                end
            end
        end
    elseif not self.player:getEquips():isEmpty() then
        local player = self.player
        if player:getWeapon() then
            card_id = player:getWeapon():getId()
        elseif player:getOffensiveHorse() then
            card_id = player:getOffensiveHorse():getId()
        elseif player:getDefensiveHorse() then
            card_id = player:getDefensiveHorse():getId()
        elseif player:getArmor() and player:getHandcardNum() <= 1 then
            card_id = player:getArmor():getId()
        end
    end
    if not card_id then
        if lightning and not self:willUseLightning(lightning) then
            card_id = lightning:getKnownEffectiveId()
        else
            for _, acard in ipairs(cards) do
                if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
                    and not acard:isKindOf("Peach") then
                    card_id = acard:getKnownEffectiveId()
                    break
                end
            end
        end
    end
    return card_id
end

local meizlseyousha_skill = {}
meizlseyousha_skill.name = "meizlseyousha"
table.insert(sgs.ai_skills, meizlseyousha_skill)
meizlseyousha_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#meizlseyoushacard") or self.player:isNude() then
        return
    end
    local card_id = self:getyoushaCard()
    if card_id then return parse_action(self,"#meizlseyoushacard:" .. card_id .. ":") end
end

sgs.ai_skill_use_func["#meizlseyoushacard"] = function(card, use, self,request)
    local first, second = self:findyoushaTarget("meizlseyoushacard", use)


    if first and second then
        use.card = card
        if use.to then
            use.to:append(first)
            use.to:append(second)
        end
    end
end

sgs.ai_use_value["#meizlseyoushacard"] = 8.5
sgs.ai_use_priority["#meizlseyoushacard"] = 4

sgs.ai_damage_reason_suppress_intention["meizlseyousha"] = true

function SmartAIView:UseAoeSkillValue_mei(element, players, card)
    element = element or sgs.DamageStruct_Normal
    card = card or clone_preview(self,"slash", sgs.Card_NoSuit, 0)
    local friends = {}
    local enemies = {}
    local good = 0

    players = players or sgs.QList2Table(self.room:getOtherPlayers(self.player))

    for _, ap in ipairs(players) do
        if self:isFriend(ap) then
            table.insert(friends, ap)
        else
            table.insert(enemies, ap)
        end
    end

    good = (#enemies - #friends) * 2
    if #enemies == 0 then return -100 end
    if element == sgs.DamageStruct_Thunder then
        for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
            if ap:hasSkill("TH_yuyiruokong") then
                if self:isFriend(ap) then
                    good = good + source_query(ap, "getCardCount", true)
                else
                    good = good - source_query(ap, "getCardCount", true)
                end
            end
        end
    end
    if element == sgs.DamageStruct_Fire then
        for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
            if ap:hasSkill("TH_Meltdown") then
                for _, friend in ipairs(friends) do
                    if friend:getHandcardNum() > 0 then good = good - 0.5 end
                end
                for _, enemy in ipairs(enemies) do
                    if enemy:getHandcardNum() > 0 then good = good + 0.5 end
                end
            end
        end
    end

    if self.player:hasSkill("TH_hongsehuanxiangxiang") then good = good + 1 end

    if self.player:getRole() == "renegade" then good = good + 0.5 end
    if self.player:getRole() == "rebel" then good = good + 0.8 end

    for _, player in ipairs(players) do
        if card and card:isKindOf("Slash") then
            if source_query(self.player, "canSlash", player) and not source_query(self, "slashProhibit", card, player) and source_query(self, "slashIsEffective", card, player) then
                if self:isEnemy(player) then
                    if source_query(self, "isGoodTarget", player, self.enemies, card) then
                        good = good + 2
                    end
                    if self:isGoodChainTarget(player, card, self.player) then
                        good = good + 2
                    end
                    if self:isWeak(player) and not self:needDeath(player) then
                        good = good + 2
                    end
                elseif self:isFriend(player) then
                    if not source_query(self, "needToLoseHp", player, self.player, card) or self:dontHurt(player, self.player) then
                        good = good - 0.2
                    end
                    if player:getHp() == 1 and source_query(self, "getAllPeachNum") == 0 and not self:needDeath(player) then
                        good = good - 2
                    end
                end
            end
        end
    end
    return good
end

local meizlselianyu_skill = {}
meizlselianyu_skill.name = "meizlselianyu"
table.insert(sgs.ai_skills, meizlselianyu_skill)
meizlselianyu_skill.getTurnUseCard = function(self, inclusive)
    if not self.player:getStrategyHasUsed("#meizlselianyucard") and (self.player:getStrategyMark("@meizlselianyu") > 0 or self.player:getStrategyMark("@meizlsebaonu") > 0) then
        local TH_skillcard = parse_action(self,"#meizlselianyucard:.:")
        return TH_skillcard
    end
end
sgs.ai_skill_use_func["#meizlselianyucard"] = function(card, use, self,request)
    local jiu
    if not self.player:getStrategyHasUsed("Analeptic") and self:getCard("Analeptic") then
        jiu = self:getCard("Analeptic")
    end
    local fs = self:getCard("FireSlash")
    if self:UseAoeSkillValue_mei(sgs.DamageStruct_Fire, nil, fs) > 0 then
        if jiu and not use.isDummy then
            use.card = jiu
            return
        end
        use.card = card
        return
    end
end

sgs.ai_use_priority["meizlselianyucard"] = 3

sgs.ai_ajustdamage_from.meizlsemiejue = function(self, from, to, card, nature)
    if nature and nature ~= "N"
    then
        return to:getHp() - 2
    end
end


local meizlsebaonu_skill = {}
meizlsebaonu_skill.name = "meizlsebaonu"
table.insert(sgs.ai_skills, meizlsebaonu_skill)
meizlsebaonu_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meizlsebaonucard") then
        if self.player:getStrategyMark("@meizlsebaonu") == 0 and self.player:isKongcheng() and self.player:getStrategyMark("@meizlselianyu") == 0 then
            return parse_action(self,"#meizlsebaonucard:.:")
        end
    end
end

sgs.ai_skill_use_func["#meizlsebaonucard"] = function(card, use, self,request)
    use.card = card
    return
end



sgs.ai_skill_playerchosen.meizlsecanhui = function(self, targets)
    local targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _, p in ipairs(targets) do
        if self:isEnemy(p) and not (hasZhaxiangEffect(p) and (p:getHp() > 1 or hasBuquEffect(p))) then
            return p
        end
    end
    return nil
end

sgs.ai_playerchosen_intention["meizlsecanhui"] = function(self, from, to)
    local intention = 50
    if hasZhaxiangEffect(to) then
        intention = -intention
    end
    self:updateIntention(from, to, intention)
end


sgs.ai_getLeastHandcardNum_skill.meizlsecanhui = function(self, player, least)
    if player:getStrategyMark("@meizlsejidu") > 0 and least < 1 then
        return 1
    end
end

sgs.ai_damage_reason_suppress_intention["meizlsezhicuan"] = true

local meizlsejidu_skill = {}
meizlsejidu_skill.name = "meizlsejidu"
table.insert(sgs.ai_skills, meizlsejidu_skill)
meizlsejidu_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meizlsejiducard") then
        if self.player:getStrategyMark("@meizlsejidu") == 0 and not self.player:isKongcheng() then
            return parse_action(self,"#meizlsejiducard:.:")
        end
    end
end

sgs.ai_skill_use_func["#meizlsejiducard"] = function(card, use, self,request)
    local spade = {}
    local heart = {}
    local club = {}
    local diamond = {}
    local cards = sgs.QList2Table(self.player:getCards("he"))
    for _, card in ipairs(cards) do
        if card:getSuit() == sgs.Card_Spade and (#spade < 4) then
            table.insert(spade, card:getKnownEffectiveId())
        elseif card:getSuit() == sgs.Card_Heart and (#heart < 4) then
            table.insert(heart, card:getKnownEffectiveId())
        elseif card:getSuit() == sgs.Card_Club and (#club < 4) then
            table.insert(club, card:getKnownEffectiveId())
        elseif card:getSuit() == sgs.Card_Diamond and (#diamond < 4) then
            table.insert(diamond, card:getKnownEffectiveId())
        end
    end
    local card_str
    local can_use = false
    if (#spade > 3) then
        card_str = string.format("#meizlsejiducard:%s:", table.concat(spade, "+"))
        can_use = true
    elseif (#club > 3) then
        card_str = string.format("#meizlsejiducard:%s:", table.concat(club, "+"))
        can_use = true
    elseif (#diamond > 3) then
        card_str = string.format("#meizlsejiducard:%s:", table.concat(diamond, "+"))
        can_use = true
    elseif (#heart > 3) then
        card_str = string.format("#meizlsejiducard:%s:", table.concat(heart, "+"))
        can_use = true
    end
    if can_use then
        local acard = parse_action(self,card_str)
        use.card = acard
        return
    end
end

sgs.ai_use_value["meizlsejiducard"] = sgs.ai_use_value.ExNihilo - 0.1
sgs.ai_use_priority["meizlsejiducard"] = sgs.ai_use_priority.ExNihilo - 0.1


local meizlsedangyang_skill = {}
meizlsedangyang_skill.name = "meizlsedangyang"
table.insert(sgs.ai_skills, meizlsedangyang_skill)
meizlsedangyang_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meizlsedangyangcard") then
        return parse_action(self,"#meizlsedangyangcard:.:")
    end
end

sgs.ai_skill_use_func["#meizlsedangyangcard"] = function(card, use, self,request)
    use.card = card
    return
end

sgs.ai_use_value["meizlsedangyangcard"] = sgs.ai_use_value.ExNihilo - 0.1
sgs.ai_use_priority["meizlsedangyangcard"] = sgs.ai_use_priority.ExNihilo - 0.1


local meizlseyinyu_skill = {}
meizlseyinyu_skill.name = "meizlseyinyu"
table.insert(sgs.ai_skills, meizlseyinyu_skill)
meizlseyinyu_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@meizlseyinyu") == 0 and self.player:getStrategyMark("meizlseyaohuo") > 0 then
        return parse_action(self,"#meizlseyinyucard:.:")
    end
end

sgs.ai_skill_use_func["#meizlseyinyucard"] = function(card, use, self,request)
    use.card = card
    return
end

sgs.ai_getBestHp_skill.meizlseyaohuo = function(owner)
    return owner:getMaxHp() - 1
end


sgs.ai_use_value["meizlsejiducard"] = sgs.ai_use_value.ExNihilo
sgs.ai_use_priority["meizlsejiducard"] = sgs.ai_use_priority.ExNihilo


local meizlsepoxiao_skill = {}
meizlsepoxiao_skill.name = "meizlsepoxiao"
table.insert(sgs.ai_skills, meizlsepoxiao_skill)
meizlsepoxiao_skill.getTurnUseCard = function(self, inclusive)
    if source_query(self, "needBear") then return end
    if self.player:getStrategyMark("@meizlseaoman") > 0 then
        if not self.player:getStrategyHasUsed("#meizlsepoxiaocard") and not self.player:isKongcheng() then
            return parse_action(self,
                "#meizlsepoxiaocard:.:")
        end
    else
        for _, p in ipairs(self.enemies) do
            if p:getStrategyMark("@meizlsepoxiaotarget") < 1 and source_query(self.player, "canPindian", p) then
                return parse_action(self,"#meizlsepoxiaocard:.:")
            end
        end
    end
end

sgs.ai_skill_use_func["#meizlsepoxiaocard"] = function(card, use, self,request)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByUseValue(cards, true)
    self:sort(self.enemies, "handcard")
    for _, enemy in ipairs(self.enemies) do
        if source_query(self.player, "canPindian", enemy) and ((enemy:getStrategyMark("@meizlsepoxiaotarget") < 1) or (self.player:getStrategyMark("@meizlseaoman") > 0)) then
            if use.to then
                use.to:append(enemy)
                break
            end
        end
    end
    for _, card in ipairs(cards) do
        if not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink") then
            use.card = parse_action(self,"#meizlsepoxiaocard:" .. card:getKnownId() .. ":")
        end
    end
    if use.to and use.to:length() > 0 then return end
    return nil
end



function sgs.ai_skill_pindian.meizlsepoxiao(minusecard, self, requestor)
    if requestor:getHandcardNum() == 1 then
        local cards = sgs.QList2Table(self.player:getHandcards())
        self:sortByKeepValue(cards)
        return cards[1]
    end
    local maxcard = self:getMaxCard()
    return self:isFriend(requestor) and self:getMinCard() or (maxcard:getNumber() < 6 and minusecard or maxcard)
end

ai_audited_aliases.register{id="ai_cardneed.meizlsepoxiao",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlsepoxiao"},canonical_registry="ai_cardneed",canonical_path={"bignumber"}}

local meizlseaoman_skill = {}
meizlseaoman_skill.name = "meizlseaoman"
table.insert(sgs.ai_skills, meizlseaoman_skill)
meizlseaoman_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@meizlseaoman") == 0 and self.player:getHp() == 1 then
        return parse_action(self,"#meizlseaomancard:.:")
    end
end

sgs.ai_skill_use_func["#meizlseaomancard"] = function(card, use, self,request)
    use.card = card
    return
end


local meizlsebaoshi_skill = {}
meizlsebaoshi_skill.name = "meizlsebaoshi"
table.insert(sgs.ai_skills, meizlsebaoshi_skill)
meizlsebaoshi_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meizlsebaoshicard") then
        if self.player:getStrategyMark("@meizlsebaoshi") == 0 and not self.player:isKongcheng() then
            return parse_action(self,"#meizlsebaoshicard:.:")
        end
    end
end

sgs.ai_skill_use_func["#meizlsebaoshicard"] = function(card, use, self,request)
    local use_card = {}
    local cards = sgs.QList2Table(self.player:getCards("he"))
    for _, card in ipairs(cards) do
        if card:isKindOf("EquipCard") and (#use_card < 4) then
            table.insert(use_card, card:getKnownEffectiveId())
        end
    end
    local card_str
    local can_use = false
    if (#use_card > 3) then
        card_str = string.format("#meizlsebaoshicard:%s:", table.concat(use_card, "+"))
        local acard = parse_action(self,card_str)
        use.card = acard
        return
    end
end

sgs.ai_use_value["meizlsebaoshicard"] = sgs.ai_use_value.ExNihilo - 0.1
sgs.ai_use_priority["meizlsebaoshicard"] = sgs.ai_use_priority.ExNihilo - 0.1

sgs.ai_ajustdamage_from.meizlsejunwang = function(self, from, to, card, nature)
    local x = from:getLostHp()
    if (source_query(from, "distanceTo", to) <= 1) or (from:getStrategyMark("@meizlsebaoshi") > 0 and source_query(from, "distanceTo", to) <= x)
    then
        return x
    end
end

ai_audited_aliases.register{id="ai_cardneed.meizlsebihui",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlsebihui"},canonical_registry="ai_cardneed",canonical_path={"slash"}}
ai_audited_aliases.register{id="ai_cardneed.meizlsejunwang",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlsejunwang"},canonical_registry="ai_cardneed",canonical_path={"slash"}}
sgs.hit_skill = sgs.hit_skill .. "|meizlsejunwang"

sgs.ai_canliegong_skill.meizlsejunwang = function(self, from, to)
    if source_query(from, "distanceTo", to) <= from:getLostHp() then return true end
end

local meizlselanduo_skill = {}
meizlselanduo_skill.name = "meizlselanduo"
table.insert(sgs.ai_skills, meizlselanduo_skill)
meizlselanduo_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@meizlselanduo") == 0 and self.player:getHandcardNum() >= 10 then
        return parse_action(self,"#meizlselanduocard:.:")
    end
end

sgs.ai_skill_use_func["#meizlselanduocard"] = function(card, use, self,request)
    use.card = card
    return
end



sgs.ai_use_value["meizlselanduocard"] = sgs.ai_use_value.ExNihilo - 0.1
sgs.ai_use_priority["meizlselanduocard"] = sgs.ai_use_priority.ExNihilo - 0.1

sgs.ai_hasTuntianEffect_skill.meizlsesiyi = function(to, need_zaoxian)
    if to:getPhase() == sgs.Player_NotActive then
        for _, p in sgs.qlist(source_query(to:getRoom(), "getAlivePlayers")) do
            if p:getKnownKingdom() == "sevendevil" then
                return true
            end
        end
    end
    return false
end

sgs.ai_skill_use["@@meizlshchunshen"] = function(self, data, method)
    if not method then method = sgs.Card_MethodDiscard end
    local dmg
    if data == "@meizlshchunshen-card" then
        dmg = scoped_struct(self,"meizlshchunshenDamage","damage")
    else
        dmg = data
    end

    if not dmg then

        return "."
    end

    self:sort(self.enemies, "hp")

    for _, enemy in ipairs(self.enemies) do
        if (enemy:isAlive()) and source_query(self.player, "distanceTo", enemy) == 1 and enemy:getHp() >= self.player:getHp() then
            if source_query(self, "canAttack", enemy, dmg.from or self.room:getCurrent(), dmg.nature)
                and not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan")) then
                return "#meizlshchunshencard:.:->" .. enemy:objectName()
            end
        end
    end

    for _, friend in ipairs(self.friends_noself) do
        if (friend:isAlive()) and source_query(self.player, "distanceTo", friend) == 1 and friend:getHp() >= self.player:getHp() then
            if friend:isChained() and dmg.nature ~= sgs.DamageStruct_Normal and not self:isGoodChainTarget(friend, dmg.from, dmg.nature, dmg.damage, dmg.card) then
            elseif (friend:hasSkills("yiji|buqu|nosbuqu|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu")
                    or source_query(self, "needToLoseHp", friend)) then
                return "#meizlshchunshencard:.:->" .. friend:objectName()
            elseif dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and friend:hasSkill("wuyan") and friend:getLostHp() > 1 then
                return "#meizlshchunshencard:.:->" .. friend:objectName()
            elseif hasBuquEffect(friend) then
                return "#meizlshchunshencard:.:->" .. friend:objectName()
            end
        end
    end

    for _, enemy in ipairs(self.enemies) do
        if enemy:isAlive() and source_query(self.player, "distanceTo", enemy) == 1 and enemy:getHp() >= self.player:getHp() then
            if source_query(self, "canAttack", enemy, (dmg.from or self.room:getCurrent()), dmg.nature)
                and not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan")) then
                return "#meizlshchunshencard:.:->" .. enemy:objectName()
            end
        end
    end

    for i = #self.enemies, 1, -1 do
        local enemy = self.enemies[i]
        if not enemy:isWounded() and not self:hasSkills(sgs.masochism_skill, enemy) and enemy:isAlive() and source_query(self.player, "distanceTo", enemy) == 1 and enemy:getHp() >= self.player:getHp()
            and source_query(self, "canAttack", enemy, dmg.from or self.room:getCurrent(), dmg.nature)
            and (not (dmg.card and dmg.card:getTypeId() == sgs.Card_TypeTrick and enemy:hasSkill("wuyan") and enemy:getLostHp() > 0) or self:isWeak()) then
            return "#meizlshchunshencard:.:->" .. enemy:objectName()
        end
    end

    return "."
end

sgs.ai_card_intention.meizlshchunshencard = function(self, card, from, tos)
    local to = tos[1]
    if source_query(self, "needToLoseHp", to) then return end
    local intention = 10
    if hasBuquEffect(to) then
        intention = 0
    elseif (to:getHp() >= 2 and to:hasSkills("yiji|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu"))
        or (to:getHandcardNum() < 3 and (to:hasSkill("nosrende") or (to:hasSkill("rende") and not to:getStrategyHasUsed("RendeCard")))) then
        intention = 0
    end
    self:updateIntention(from, to, intention)
end

function sgs.ai_slash_prohibit.meizlshchunshen(self, from, to)
    if source_query(self, "hasJueqingEffect", from, to) or (from:hasSkill("nosqianxi") and source_query(from, "distanceTo", to) == 1) then return false end
    if from:getStrategyFlag("NosJiefanUsed") then return false end
    if self:isFriend(to, from) then return false end
    return source_query(self, "cantbeHurt", to, from)
end

sgs.ai_can_damagehp.meizlshchunshen = function(self, from, card, to)
    local d = {damage=1,nature=sgs.DamageStruct_Normal}
    d.from = from
    d.to = to
    d.nature = card and sgs.card_damage_nature[card:getClassName()] or sgs.DamageStruct_Normal
    d.card = card
    return sgs.ai_skill_use["@@meizlshchunshen"](self, d, sgs.Card_MethodDiscard) ~= "."
end

sgs.ai_hasTuntianEffect_skill.meizlshjinlian = function(to, need_zaoxian)
    return to:getPhase() == sgs.Player_NotActive
end

local meizlluoyingbinfen_skill = {}
meizlluoyingbinfen_skill.name = "meizlluoyingbinfen"
table.insert(sgs.ai_skills, meizlluoyingbinfen_skill)
meizlluoyingbinfen_skill.getTurnUseCard = function(self)
    if not (self.player:getStrategyMark("@meizldaqiaomark") >= 15 or self.player:getStrategyMark("@meizlxiaoqiaomark") >= 15) then return end
    if self.room:getMode() == "_mini_13" then return parse_action(self,"#meizlluoyingbinfencard:.:") end
    local good, bad = 1, 0
    local lord = self.room:getLord()
    if lord and self.role ~= "rebel" and (lord:getHandcardNum() > lord:getHp()) and lord:isMale() then return end
    for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if (player:getHandcardNum() > 0) and player:isMale() and source_query(self, "ajustDamage", player, player, player:getHandcardNum()) > 0 then
            if self:isFriend(player) then
                bad = bad + 1
            else
                good = good + 1
            end
        end
    end
    if good == 0 then return end

    for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if player:isMale() then
            local hp = math.max(player:getHp(), 1)
            if getCardsNum("Analeptic", player) > 0 then
                if self:isFriend(player) then
                    good = good + 1.0 / hp
                else
                    bad = bad + 1.0 / hp
                end
            end
            if self:isFriend(player) then
                good = good + math.max(getCardsNum("Peach", player), 1)
            else
                bad = bad + math.max(getCardsNum("Peach", player), 1)
            end
        end
    end

    if good > bad then return parse_action(self,"#meizlluoyingbinfencard:.:") end
end

sgs.ai_skill_use_func["#meizlluoyingbinfencard"] = function(card, use, self,request)
    use.card = card
end

sgs.dynamic_value.damage_card["#meizlluoyingbinfencard"] = true



local meizlshhujia_skill = {}
meizlshhujia_skill.name = "meizlshhujia"
table.insert(sgs.ai_skills, meizlshhujia_skill)
meizlshhujia_skill.getTurnUseCard = function(self)
    if source_query(self, "needBear") then return end
    if not self.player:getStrategyHasUsed("#meizlshhujiacard") and not self.player:isKongcheng() then
        return parse_action(self,
            "#meizlshhujiacard:.:")
    end
end

sgs.ai_skill_use_func["#meizlshhujiacard"] = function(card, use, self,request)
    self:sort(self.enemies, "handcard")
    local max_card = self:getMaxCard(self.player)
    local max_point = max_card:getNumber()
    if self.player:hasSkill("kongcheng") and self.player:getHandcardNum() == 1 then
        for _, enemy in ipairs(self.enemies) do
            if source_query(self.player, "canPindian", enemy) then
                use.card = parse_action(self,"#meizlshhujiacard:.:")
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
    if (self:getOverflow() > 0) or (max_point > 9) then
        for _, enemy in ipairs(self.enemies) do
            if source_query(self.player, "canPindian", enemy) then
                use.card = parse_action(self,"#meizlshhujiacard:.:")
                set_state(self,"meizlshhujia_card",max_card:getKnownEffectiveId())
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end

function sgs.ai_skill_pindian.meizlshhujia(minusecard, self, requestor)
    if self:isFriend(requestor) then return minusecard end
    return self:getMaxCard()
end

ai_audited_aliases.register{id="ai_cardneed.meizlshhujia",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlshhujia"},canonical_registry="ai_cardneed",canonical_path={"bignumber"}}


local meizlshguihan_skill = {}
meizlshguihan_skill.name = "meizlshguihan"
table.insert(sgs.ai_skills, meizlshguihan_skill)
meizlshguihan_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getStrategyMark("@meizlshguihan") == 0 then return end
    return parse_action(self,"#meizlshguihancard:.:")
end

sgs.ai_skill_use_func["#meizlshguihancard"] = function(card, use, self,request)
    if self:isWeak() or (self.room:alivePlayerCount() < 8 and self.player:getHp() < getBestHp(self.player)) then
        use.card = card
        if use.to then use.to:append(self.player) end
        return
    end
end

sgs.ai_use_value["meizlshguihancard"] = sgs.ai_use_value.ExNihilo - 0.1
sgs.ai_use_priority["meizlshguihancard"] = sgs.ai_use_priority.ExNihilo - 0.1

function sgs.ai_slash_prohibit.meizlshhunshi(self, from, to)
    if source_query(self, "hasJueqingEffect", from, to) or (from:hasSkill("nosqianxi") and source_query(from, "distanceTo", to) == 1) then return false end
    if from:getStrategyFlag("NosJiefanUsed") then return false end
    if to:getHp() > 1 or #(self:getEnemies(from)) == 1 then return false end
    return self:isWeak(from)
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|meizlshhunshi"
sgs.bad_skills = sgs.bad_skills .. "|meizlshhunshidistance"

local meizlzhenhunqu_skill = {}
meizlzhenhunqu_skill.name = "meizlzhenhunqu"
table.insert(sgs.ai_skills, meizlzhenhunqu_skill)
meizlzhenhunqu_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@meizlcaiwenjimark") >= 5 then
        return parse_action(self,"#meizlzhenhunqucard:.:")
    end
end

sgs.ai_skill_use_func["#meizlzhenhunqucard"] = function(card, use, self,request)
    self:sort(self.enemies, "defense")

    for _, enemy in ipairs(self.enemies) do
        if source_query(self, "objectiveLevel", enemy) > 3 and source_query(self, "isGoodTarget", enemy, self.enemies) and not (hasZhaxiangEffect(enemy) and #self.enemies > 1) then
            use.card = parse_action(self,"#meizlzhenhunqucard:.:")
            if use.to then
                use.to:append(enemy)
            end
            break
        end
    end
end


local meizlshqingyan_skill = {}
meizlshqingyan_skill.name = "meizlshqingyan"
table.insert(sgs.ai_skills, meizlshqingyan_skill)
meizlshqingyan_skill.getTurnUseCard = function(self)
    if not source_query(self.player, "canDiscard", self.player, "he") then return end
    return parse_action(self,"#meizlshqingyancard:.:")
end

sgs.ai_skill_use_func["#meizlshqingyancard"] = function(card, use, self,request)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sort(self.enemies, "handcard")
    local slashcount = self:getCardsNum("Slash")
    self:sortByKeepValue(cards)
    if slashcount > 0 then
        for _, card in ipairs(cards) do
            if (not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink")) or self:getOverflow() > 0 then
                local slash = self:getCard("Slash")
                assert(slash)
                local target
                local dummy_use = meizl_use_card(self,slash, dummy())
                if not dummy_use.to:isEmpty() then
                    for _, p in sgs.qlist(dummy_use.to) do
                        if p:getStrategyMark("@meizlshqingyan") == 0 then
                            target = p
                            break
                        end
                    end
                end

                if target then
                    use.card = parse_action(self,"#meizlshqingyancard:" .. card:getKnownId() .. ":")
                    if use.to then use.to:append(target) end
                    return
                end
            end
        end
    end
    if self:getOverflow() > 0 then
        for _, card in ipairs(cards) do
            if (not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink")) or self:getOverflow() > 0 then
                local target
                self:sort(self.enemies, "handcard")
                self.enemies = sgs.reverse(self.enemies)
                for _, p in ipairs(self.enemies) do
                    if p:getStrategyMark("@meizlshqingyan") == 0 then
                        target = p
                        break
                    end
                end
                if target then
                    use.card = parse_action(self,"#meizlshqingyancard:" .. card:getKnownId() .. ":")
                    if use.to then use.to:append(target) end
                    return
                end
            end
        end
    end
end

sgs.ai_card_intention["meizlshqingyancard"] = 70


sgs.ai_use_value["meizlshqingyancard"] = 9.2
sgs.ai_use_priority["meizlshqingyancard"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_skill_invoke.meizlshxiangjie = function(self, data)
    local hcards = self.player:getCards("h")
    hcards = sgs.QList2Table(hcards)
    self:sortByUseValue(hcards, true)
    local card
    for _, hcard in ipairs(hcards) do
        if hcard:isKindOf("Slash") then
            card = hcard
        end
    end
    if not card then
        return false
    end
    local target
    local friends = self.friends_noself
    set_state(self,"meizlxiangjieTarget",nil)
    local friend = self.room:getCurrent()
    if friend and self:isFriend(friend) then
        self:sort(self.enemies, "defense")
        for _, enemy in ipairs(self.enemies) do
            if source_query(friend, "canSlash", enemy, card, false) and not source_query(self, "slashProhibit", card, enemy) and source_query(self, "getDefenseSlash", enemy) <= 6
                and source_query(self, "slashIsEffective", card, enemy) and source_query(self, "isGoodTarget", enemy, self.enemies, card)
                and enemy:objectName() ~= self.player:objectName() then
                set_state(self,"meizlxiangjieTarget",enemy)
                return true
            end
        end
    end
    return false
end

sgs.ai_skill_playerchosen.meizlshxiangjie = function(self, targets)
    if get_state(self,"meizlxiangjieTarget") then return get_state(self,"meizlxiangjieTarget") end
    return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end
sgs.ai_suppress_intention["meizlxiangjie"] = true

sgs.ai_skill_cardask["@meizlshxiangjie-slash"] = function(self, data, pattern)
    local hcards = self.player:getCards("h")
    hcards = sgs.QList2Table(hcards)
    self:sortByUseValue(hcards, true)
    local card
    for _, hcard in ipairs(hcards) do
        if hcard:isKindOf("Slash") then
            card = hcard
        end
    end
    if card then
        return "$" .. card:getKnownEffectiveId()
    end
end

ai_audited_aliases.register{id="ai_cardneed.meizlshxiangjie",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlshxiangjie"},canonical_registry="ai_cardneed",canonical_path={"slash"}}
sgs.ai_suppress_intention["meizlshxiangjie"] = true

local meizlmengshilong_skill = {}
meizlmengshilong_skill.name = "meizlmengshilong"
table.insert(sgs.ai_skills, meizlmengshilong_skill)
meizlmengshilong_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@meizlyangwanmark") >= 4 then
        return parse_action(self,"#meizlmengshilongcard:.:")
    end
end

sgs.ai_skill_use_func["#meizlmengshilongcard"] = function(card, use, self,request)
    self:sort(self.enemies, "defense")
    local target
    if self.role == "rebel" then
        local lord = self.room:getLord()
        target = lord
    end
    if target and target:getStrategyMark("@meizlmengshilong") == 0 then
        use.card = parse_action(self,"#meizlmengshilongcard:.:")
        if use.to then
            use.to:append(target)
        end
    else
        for _, enemy in ipairs(self.enemies) do
            if source_query(self, "objectiveLevel", enemy) > 3 and enemy:getStrategyMark("@meizlmengshilong") == 0 then
                use.card = parse_action(self,"#meizlmengshilongcard:.:")
                if use.to then
                    use.to:append(enemy)
                end
                break
            end
        end
    end
end


sgs.ai_ajustdamage_from["@meizlmengshilong"] = function(self, from, to, card, nature)
    return -99
end


local meizlshzefu_skill = {}
meizlshzefu_skill.name = "meizlshzefu"
table.insert(sgs.ai_skills, meizlshzefu_skill)
meizlshzefu_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meizlshzefucard") then
        return parse_action(self,"#meizlshzefucard:.:")
    end
end

sgs.ai_skill_use_func["#meizlshzefucard"] = function(card, use, self,request)
    self:sort(self.friends_noself, "handcard")
    local has_red = false
    for _, friend in ipairs(self.friends_noself) do
        if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
            if (friend:getHandcardNum() > self.player:getHandcardNum()) and (friend:getHp() > self.player:getHp()) and (source_query(friend, "getAttackRange") > source_query(self.player, "getAttackRange")) then
                use.card = parse_action(self,"#meizlshzefucard:.:")
                if use.to then use.to:append(friend) end
                return
            end
        end
    end
end

sgs.ai_use_priority["meizlshzefucard"] = 10
sgs.ai_use_value["meizlshzefucard"] = 2.45
sgs.ai_card_intention.meizlshzefucard = -80


sgs.ai_can_damagehp.meizlshjuese = function(self, from, card, to)
    if to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to) then
        local x = math.random(1, 10)
        if x > 3 then
            return true
        end
    end
end


local meizlyanranyixiao_skill = {}
meizlyanranyixiao_skill.name = "meizlyanranyixiao"
table.insert(sgs.ai_skills, meizlyanranyixiao_skill)
meizlyanranyixiao_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@meizlfanshimark") >= 8 and not self.player:getStrategyHasUsed("#meizlyanranyixiaocard") then
        return parse_action(self,"#meizlyanranyixiaocard:.:")
    end
end

sgs.ai_skill_use_func["#meizlyanranyixiaocard"] = function(card, use, self,request)
    use.card = card
    return
end



sgs.ai_use_value["meizlyanranyixiaocard"] = sgs.ai_use_value.ExNihilo - 0.1
sgs.ai_use_priority["meizlyanranyixiaocard"] = sgs.ai_use_priority.ExNihilo - 0.1

sgs.ai_cardneed.meizlshxianggui = function(to, card)
    return true
end


sgs.ai_ajustdamage_to.meizlshxiuhua = function(self, from, to, card, nature)
    if nature ~= "N"
    then
        return -99
    end
end
ai_audited_aliases.register{id="ai_cardneed.meizlshyuguo",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlshyuguo"},canonical_registry="ai_cardneed",canonical_path={"slash"}}

sgs.ai_skill_invoke.meizlshyuguo = function(self, data)
    return true
end

sgs.ai_ajustdamage_from.meizlshyuguo = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash")
    then
        return from:getStrategyMark("@meizlshyuguo")
    end
end

local meizlyuezhanyueqiang_skill = {}
meizlyuezhanyueqiang_skill.name = "meizlyuezhanyueqiang"
table.insert(sgs.ai_skills, meizlyuezhanyueqiang_skill)
meizlyuezhanyueqiang_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@meizlmayunlumark") >= 4 and not self.player:getStrategyHasUsed("#meizlyuezhanyueqiangcard") then
        return parse_action(self,"#meizlyuezhanyueqiangcard:.:")
    end
end

sgs.ai_skill_use_func["#meizlyuezhanyueqiangcard"] = function(card, use, self,request)
    use.card = card
    return
end



sgs.ai_use_value["meizlyuezhanyueqiangcard"] = sgs.ai_use_value.ExNihilo - 0.1
sgs.ai_use_priority["meizlyuezhanyueqiangcard"] = sgs.ai_use_priority.ExNihilo - 0.1

sgs.ai_ajustdamage_from.meizlyuezhanyueqiang = function(self, from, to, card, nature)
    return from:getStrategyMark("@meizlyuezhanyueqiangdamage")
end



sgs.ai_skill_invoke.meizlshrongzhuang = function(self, data)
    return true
end
sgs.ai_skill_use["@@meizlshrongzhuang"] = function(self, prompt)
    self:updatePlayers()
    local card = prompt:split(":")
    if card[2] == "slash" or card[2] == "fire_slash" or card[2] == "thunder_slash" then
        self:sort(self.enemies, "defense")
        local targets = {}
        local slash = known_card(self,card[5])
        for _, enemy in ipairs(self.enemies) do
            if source_query(self.player, "canSlash", enemy, slash) and not source_query(self, "slashProhibit", slash, enemy) and source_query(self, "slashIsEffective", slash, enemy) and source_query(self, "isGoodTarget", enemy, self.enemies, slash) then
                if #targets >= 1 + source_query(slash, "getTargetModExtra", self.player) then break end
                table.insert(targets, enemy:objectName())
            end
        end
        if #targets > 0 then
            return card[5] .. "->" .. table.concat(targets, "+")
        else
            return "."
        end
    end
    return "."
end

sgs.need_equip_skill = sgs.need_equip_skill .. "|meizlshwuji"
ai_audited_aliases.register{id="ai_cardneed.meizlshwuji",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"meizlshwuji"},canonical_registry="ai_cardneed",canonical_path={"slash"}}

sgs.ai_ajustdamage_from.meizlshjichi = function(self, from, to, card, nature)
    if source_query(from, "inMyAttackRange", to) and from:objectName() ~= to:objectName() and from:isWounded() then
        return from:getLostHp()
    end
end

local meizlwuzhijingjichang_skill = {}
meizlwuzhijingjichang_skill.name = "meizlwuzhijingjichang"
table.insert(sgs.ai_skills, meizlwuzhijingjichang_skill)
meizlwuzhijingjichang_skill.getTurnUseCard = function(self)
    if (self.player:getStrategyMark("@meizllvlingqimark") < 5) or (self.player:getStrategyMark("@meizlwuzhijingjichangstate") > 0) then return end
    return parse_action(self,"#meizlwuzhijingjichangcard:.:")
end
sgs.ai_skill_use_func["#meizlwuzhijingjichangcard"] = function(card, use, self,request)
    self:updatePlayers()
    self:sort(self.enemies, "defense")
    local acard = parse_action(self,"#meizlwuzhijingjichangcard:.:") --根据卡牌构成字符串产生实际将使用的卡牌
    assert(acard)
    local defense = 6
    local selfSub = self.player:getHandcardNum() - self.player:getHp()
    if #self.enemies <= 1 then return "." end
    local best_target
    for _, enemy in ipairs(self.enemies) do
        local def = sgs.getDefense(enemy)
        local slash = clone_preview(self,"slash")

        local eff = source_query(self, "slashIsEffective", slash, enemy) and source_query(self, "isGoodTarget", enemy, self.enemies, slash)

        if not source_query(self.player, "canSlash", enemy, slash, false) then
        elseif throw_weapon and source_query(enemy, "hasArmorEffect", "vine") and not self.player:hasSkill("zonghuo") then
        elseif source_query(self, "slashProhibit", nil, enemy) then
        elseif eff then
            if enemy:getHp() == 1 and getCardsNum("Jink", enemy) == 0 then
                best_target = enemy
                break
            end
            if def < defense then
                best_target = enemy
                defense = def
            end
            best_target = enemy
        end
        if selfSub < 0 then return "." end
    end
    if best_target then
        if self:getCardsNum("Slash") > 1 and self.player:getHp() > 1 then
            use.card = acard
            if use.to then use.to:append(best_target) end
            return
        end
    end
    if target then
        if self:getCardsNum("Slash") > 1 and self.player:getHp() > 2 then
            use.card = acard
            if use.to then use.to:append(target) end
            return
        end
    end

end

sgs.ai_use_value["meizlwuzhijingjichangcard"] = 2    --卡牌使用价值
sgs.ai_use_priority["meizlwuzhijingjichangcard"] = 3 --卡牌使用优先级

sgs.ai_skill_playerchosen.meizlshfujun = function(self, targets)
    local AssistTarget = self:AssistTarget()
    if AssistTarget and not source_query(self, "willSkipPlayPhase", AssistTarget) then
        return AssistTarget
    end

    self:sort(self.friends_noself, "chaofeng")
    for _, target in ipairs(self.friends_noself) do
        if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
            and (not source_query(self, "willSkipPlayPhase", target) or target:hasSkill("shensu")) then
            return target
        end
    end

    for _, target in ipairs(self.friends_noself) do
        if target:hasSkill("dawu") then
            local use = true
            for _, p in ipairs(self.friends_noself) do
                if p:getStrategyMark("@fog") > 0 then
                    use = false
                    break
                end
            end
            if use then
                return target
            end
        else
            return target
        end
    end
end

sgs.ai_playerchosen_intention.meizlshfujun = -80

sgs.ai_can_damagehp.meizlshfujun = function(self, from, card, to)
    if to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to) and source_query(to, "getCardCount") > 0
    then
        return self:getCardsNum("Peach") > 0 and #self.friends_noself > 0 and not source_query(self, "willSkipPlayPhase")
    end
end

sgs.ai_skill_playerchosen.meizlshrangma = function(self, targets)
    local AssistTarget = self:AssistTarget()
    if AssistTarget and not source_query(self, "willSkipPlayPhase", AssistTarget) then
        return AssistTarget
    end

    self:sort(self.friends_noself, "chaofeng")
    for _, target in ipairs(self.friends_noself) do
        if target:hasSkills(sgs.cardneed_skill) and not hasManjuanEffect(target)
            and (not source_query(self, "willSkipPlayPhase", target) or target:hasSkill("shensu")) then
            return target
        end
    end
    for _, target in ipairs(self.friends_noself) do
        if not hasManjuanEffect(target) and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
            and (not source_query(self, "willSkipPlayPhase", target) or target:hasSkill("shensu")) then
            return target
        end
    end
    for _, target in ipairs(self.friends_noself) do
        if not hasManjuanEffect(target)
            and (not source_query(self, "willSkipPlayPhase", target) or target:hasSkill("shensu")) then
            return target
        end
    end
    for _, target in ipairs(self.friends_noself) do
        if not hasManjuanEffect(target) then
            return target
        end
    end
    for _, target in ipairs(self.friends_noself) do
        return target
    end
end

function sgs.ai_slash_prohibit.meizlshrangma(self, from, to)
    if source_query(self, "hasJueqingEffect", from, to) or (from:hasSkill("nosqianxi") and source_query(from, "distanceTo", to) == 1) then return false end
    if from:getStrategyFlag("NosJiefanUsed") then return false end
    if self:isFriend(to, from) and self:isWeak(to) then return true end
    return #(self:getEnemies(from)) > 1 and self:isWeak(to) and from:getHandcardNum() > 3
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|meizlshrangma"

local meizlshtuogu_skill = {}
meizlshtuogu_skill.name = "meizlshtuogu"
table.insert(sgs.ai_skills, meizlshtuogu_skill)
meizlshtuogu_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@meizlshtuogu") <= 0 then return end
    if #self.enemies <= 0 then return end
    local good, bad = 0, 0
    local lord = self.room:getLord()
    if lord and self.role ~= "rebel" and self:isWeak(lord) and lord:getKnownKingdom() ~= "shu" then return end
    for _, player in sgs.qlist(self.room:getAlivePlayers()) do
        if self:isFriend(player) then
            if player:getKnownKingdom() == "shu" and player:getHp() < getBestHp(player) then
                good = good + 1
            elseif player:getKnownKingdom() ~= "shu" then
                bad = bad + 1
                if hasZhaxiangEffect(player) and not hasManjuanEffect(player) and not source_query(self, "willSkipPlayPhase", player)
                    and (player:getHp() > 1 or source_query(self, "getAllPeachNum") > 0) then
                    good = good + 2
                end
            end
        else
            if player:getKnownKingdom() == "shu" and player:getHp() < getBestHp(player) then
                bad = bad + 1
            elseif player:getKnownKingdom() ~= "shu" and not hasZhaxiangEffect(player) then
                good = good + 1
                if self:isWeak(player) then
                    good = good + 1
                end
            elseif player:getKnownKingdom() ~= "shu" and hasZhaxiangEffect(player) then
                bad = bad + 2
            end
        end
    end
    bad = bad
    if good > bad then return parse_action(self,"#meizlshtuogucard:.:") end
end


sgs.ai_skill_use_func.meizlshtuogucard = function(card, use, self)
    use.card = card
end

sgs.ai_skill_playerchosen.meizlshtuogucard = function(self, targets)
    local arr1, arr2 = self:getWoundedFriend(false, false)
    local target = nil

    if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and arr1[1]:getHp() < getBestHp(arr1[1]) then
        target =
            arr1[1]
    end
    if target and target:getKnownKingdom() == "shu" then
        return target
    end
end

sgs.ai_playerchosen_intention["meizlshtuogucard"] = function(self, from, to)
    self:updateIntention(from, to, -50)
end


local meizlkujingguhun_skill = {}
meizlkujingguhun_skill.name = "meizlkujingguhun"
table.insert(sgs.ai_skills, meizlkujingguhun_skill)
meizlkujingguhun_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@meizlmifurenmark") >= 1 and not self.player:getStrategyHasUsed("#meizlkujingguhuncard") then
        return parse_action(self,"#meizlkujingguhuncard:.:")
    end
end

sgs.ai_skill_use_func["#meizlkujingguhuncard"] = function(card, use, self,request)
    self:sort(self.enemies, "defense")
    local target
    if self.role == "rebel" then
        local lord = self.room:getLord()
        target = lord
    end
    if target then
        use.card = parse_action(self,"#meizlkujingguhuncard:.:")
        if use.to then
            use.to:append(target)
        end
    else
        for _, enemy in ipairs(self.enemies) do
            use.card = parse_action(self,"#meizlkujingguhuncard:.:")
            if use.to then
                use.to:append(enemy)
                break
            end
        end
    end
end



sgs.ai_skill_playerchosen.meizlkujingguhuncard = function(self, targets)
    local target
    if self.role == "loyalist" then
        local lord = self.room:getLord()
        return lord
    end
    self:sort(self.friends_noself, "hp")
    for _, friend in ipairs(self.friends_noself) do
        return friend
    end
    return targets[1]
end



sgs.ai_ajustdamage_from.meispshfengdan = function(self, from, to, card, nature)
    if from
    then
        return from:getStrategyMark("@meispshfeng")
    end
end

local meispshliwu_skill = {}
meispshliwu_skill.name = "meispshliwu"
table.insert(sgs.ai_skills, meispshliwu_skill)
meispshliwu_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#meispshliwucard") then
        if self.player:getStrategyMark("@meispshliwuprevent") == 0 and self.player:getStrategyMark("@meispshfeng") >= 1 and self.player:getKnownKingdom() == "shu" then
            return parse_action(self,"#meispshliwucard:.:")
        end
    end
end

sgs.ai_skill_use_func["#meispshliwucard"] = function(card, use, self,request)
    use.card = card
    return
end

local meispshliwuskill2_skill = {}
meispshliwuskill2_skill.name = "meispshliwuskill2"
table.insert(sgs.ai_skills, meispshliwuskill2_skill)
meispshliwuskill2_skill.getTurnUseCard = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)

    if self.player:getPile("wooden_ox"):length() > 0 then
        for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
            table.insert(cards, known_card(self,id))
        end
    end

    local jink_card

    self:sortByUseValue(cards, true)

    for _, card in ipairs(cards) do
        if card:isKindOf("Jink") then
            jink_card = card
            break
        end
    end

    if not jink_card then return nil end
    local suit = jink_card:getSuitString()
    local number = source_query(jink_card, "getNumberString")
    local card_id = jink_card:getKnownEffectiveId()
    local card_str = ("slash:meispshliwuskill2[%s:%s]=%d"):format(suit, number, card_id)
    local slash = parse_action(self,card_str)
    assert(slash)

    return slash
end

sgs.ai_view_as.meispshliwuskill2 = function(card, player, card_place)
    local self=known(player:getRoom()._ai,"viewer AI")
    if known(self.request.reason,"current card use reason") ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
    local suit = card:getSuitString()
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
        if card:isKindOf("Jink") then
            return ("slash:meispshliwuskill2[%s:%s]=%d"):format(suit, number, card_id)
        elseif card:isKindOf("Slash") then
            return ("jink:meispshliwuskill2[%s:%s]=%d"):format(suit, number, card_id)
        end
    end
end


sgs.ai_use_value["meispliwucard"] = 2      --卡牌使用价值
sgs.ai_use_priority["meispliwucard"] = 3.5 --卡牌使用优先级







local meispshruixuecard_skill = {}
meispshruixuecard_skill.name = "meispshruixuecard"
table.insert(sgs.ai_skills, meispshruixuecard_skill)
meispshruixuecard_skill.getTurnUseCard = function(self)
    if not (self.player:getStrategyMark("@meispshruixue") > 0 and self.player:getKnownKingdom() == "qun") then return end
    return parse_action(self,"#meispshruixuecard:.:")
end
sgs.ai_skill_use_func["#meispshruixuecard"] = function(card, use, self,request)
    self:updatePlayers()
    self:sort(self.enemies, "defense")
    local acard = parse_action(self,"#meispshruixuecard:.:") --根据卡牌构成字符串产生实际将使用的卡牌
    assert(acard)
    local defense = 6
    local selfSub = self.player:getHandcardNum() - self.player:getHp()
    if #self.enemies <= 1 then return "." end
    local best_target
    for _, enemy in ipairs(self.enemies) do
        local def = sgs.getDefense(enemy)
        local slash = clone_preview(self,"slash")

        local eff = source_query(self, "slashIsEffective", slash, enemy) and source_query(self, "isGoodTarget", enemy, self.enemies, slash) and
            source_query(self.player, "distanceTo", enemy) - math.min(self.player:getHp() - 1, self:getCardsNum("Slash")) <= 1

        if not source_query(self.player, "canSlash", enemy, slash, false) then
        elseif throw_weapon and source_query(enemy, "hasArmorEffect", "vine") and not self.player:hasSkill("zonghuo") then
        elseif source_query(self, "slashProhibit", nil, enemy) then
        elseif eff then
            if enemy:getHp() == 1 and getCardsNum("Jink", enemy) == 0 then
                best_target = enemy
                break
            end
            if def < defense then
                best_target = enemy
                defense = def
            end
            best_target = enemy
        end
        if selfSub < 0 then return "." end
    end
    if best_target then
        if self:getCardsNum("Slash") > 1 then
            use.card = acard
        end
    end
    if target then
        if self:getCardsNum("Slash") > 1 then
            use.card = acard
        end
    end
    for _, c in sgs.qlist(self.player:getHandcards()) do
        local x = nil
        if isCard("ArcheryAttack", c, self.player) then
            x = clone_preview(self,"ArcheryAttack")
        elseif isCard("SavageAssault", c, self.player) then
            x = clone_preview(self,"SavageAssault")
        else
            continue
        end

        local dummy_use = meizl_use_card(self,x, dummy())
        if (dummy_use.card) and self.player:getHp() > 1 then use.card = acard end

    end
end

sgs.ai_use_value["meispshruixuecard"] = 2    --卡牌使用价值
sgs.ai_use_priority["meispshruixuecard"] = 3 --卡牌使用优先级


sgs.ai_ajustdamage_to.meispshengguangjiahu = function(self, from, to, card, nature)
    if to:getStrategyMark("@meispniangzhaoyunmark") >= 2
    then
        return -1
    end
end




sgs.ai_skill_invoke.feiren = function(self, data)
    local target = data:toPlayer()
    if not self:isEnemy(target) then return false end

    if self.player:getHandcardNum() == 1 then
        if (self:needKongcheng() or not source_query(self, "hasLoseHandcardEffective")) and not self:isWeak() then return true end
    end

    if (self.player:getHandcardNum() >= self.player:getHp() or (self:needKongcheng() and self.player:getHandcardNum() == 1) or not source_query(self, "hasLoseHandcardEffective") or self.player:getHp() < target:getHandcardNum())
        and source_query(self, "doDisCard", target, "h", true) then
        return true
    end
    if source_query(self, "doDisCard", target, "he", true) then return true end
    return false
end


ai_audited_aliases.register{id="ai_cardneed.feiren",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"feiren"},canonical_registry="ai_cardneed",canonical_path={"slash"}}

sgs.ai_skill_invoke.meizl_o_yuxiang = function(self, data)
    local savage_assault = clone_preview(self,"savage_assault", sgs.Card_NoSuit, 0)
    mutate(self,savage_assault,"skill","meizl_o_yuxiang")

    if source_query(self, "getAoeValue", savage_assault) > 0 then
        return true
    end
    return false
end



sgs.ai_skill_invoke.guihans = function(self, data)
    return true
end

sgs.ai_getBestHp_skill.guihans = function(owner)
    return owner:getMaxHp() - 1
end

sgs.ai_skill_invoke.hujias = function(self, data)
    local damage = data:toDamage()
    if damage.from then
        if self:isFriend(damage.from) then
            if self:isWeak(damage.from) and source_query(self, "getAllPeachNum") == 0 then
                return false
            end
        else
            if hasZhaxiangEffect(damage.from) and damage.from:getHp() > 1 then
                return false
            end
        end
    end
    return true
end


local guyan_skill = {}
guyan_skill.name = "guyan"
table.insert(sgs.ai_skills, guyan_skill)
guyan_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#guyan") then
        return parse_action(self,"#guyan:.:")
    end
end

sgs.ai_skill_use_func["#guyan"] = function(card, use, self,request)
    self:sort(self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        if source_query(self, "objectiveLevel", enemy) > 3 and source_query(self, "canAttack", enemy, self.player) and source_query(self, "damageIsEffective", enemy) and source_query(self, "isGoodTarget", enemy, self.player) then
            use.card = parse_action(self,"#guyan:.:")
            if use.to then
                use.to:append(enemy)
            end
            return
        end
    end
end



sgs.ai_skill_invoke.guyanjh = function(self, data)
    local damage = data:toDamage()
    if damage.from and self:isEnemy(damage.from) and not hasZhaxiangEffect(damage.from) then
        local to_discard = self:askForDiscard("beige", 1, 1, false, true, ".")
        if #to_discard > 0 then
            return true
        end
    end
    return false
end

sgs.ai_skill_discard["guyanjh"] = function(self, discard_num, min_num, optional, include_equip)
    local usable_cards = sgs.QList2Table(self.player:getCards("he"))
    local damage = scoped_struct(self,"CurrentDamageStruct","damage")
    local target = damage.from
    if target and not self:isFriend(target) then
        self:sortByKeepValue(usable_cards)
        local to_discard = {}
        for _, c in ipairs(usable_cards) do
            if #to_discard < discard_num and not c:isKindOf("Peach") then
                table.insert(to_discard, c:getKnownEffectiveId())
            end
        end
        return to_discard
    end
    return {}
end

function sgs.ai_slash_prohibit.hujiajh(self, from, to)
    if source_query(self, "hasJueqingEffect", from, to) or (from:hasSkill("nosqianxi") and source_query(from, "distanceTo", to) == 1) then return false end
    if from:getStrategyFlag("NosJiefanUsed") then return false end
    if to:getHp() > 1 or #(self:getEnemies(from)) == 1 then return false end
    if from:getMaxHp() == 3 and from:getArmor() and from:getDefensiveHorse() then return false end
    if from:getMaxHp() <= 3 or (source_query(from, "isLord") and self:isWeak(from)) then return true end
    if from:getMaxHp() <= 3 or (self.room:getLord() and lawful_role(self,from) == "renegade") then return true end
    if from:getMaxHp() - to:getHandcardNum() < 3 then return true end
    if from:getHp() < from:getHandcardNum() then return true end
    return false
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|hujiajh"

sgs.ai_skill_invoke.xiehou = function(self, data)
    return true
end

sgs.ai_can_damagehp.xiehou = function(self, from, card, to)
    return card and source_query(card, "isDamageCard") and source_query(self, "canLoseHp", from, card, to) and
    sgs.card_damage_nature[card:getClassName()] ~= sgs.DamageStruct_Normal
        and to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
end

sgs.ai_skill_cardask["@huixue"] = function(self, data, pattern)
    local hcards = self.player:getCards("h")
    hcards = sgs.QList2Table(hcards)
    self:sortByUseValue(hcards, true)
    local card
    for _, hcard in ipairs(hcards) do
        if hcard:isKindOf("BasicCard") then
            card = hcard
        end
    end
    if card and getBestHp(self.player) >= self.player:getHp() then
        return "$" .. card:getKnownEffectiveId()
    end
end



sgs.ai_skill_invoke.luoshenjh = function(self, data)
    return true
end

sgs.ai_need_damaged.luoshenjh = function(self, attacker, player)
    local friends = {}
    for _, ap in sgs.list(self.room:getAlivePlayers()) do
        if self:isFriend(ap, player) then
            table.insert(friends, ap)
        end
    end
    self:sort(friends, "hp")

    if #friends > 0 and friends[1]:objectName() == player:objectName() and self:isWeak(player) and getCardsNum("Peach", player, (attacker or self.player)) == 0 then return false end

    return player:getHp() > 2 and source_query(self.room, "getTurnCount") > 2 and #friends > 1 and not self:isWeak(player) and
        player:getHandcardNum() >= 2
end

sgs.ai_can_damagehp.luoshenjh = function(self, from, card, to)
    return to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to)
end


sgs.ai_skill_invoke.huixuejh = function(self, data)
    if self.player:getHp() < getBestHp(self.player) then return true end
    return false
end




sgs.ai_skill_invoke.meizi_shenfu = function(self, data)
    return true
end

sgs.ai_can_damagehp.meizi_shenfu = function(self, from, card, to)
    return to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to)
end
sgs.ai_need_damaged.meizi_shenfu = function(self, attacker, player)
    if self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < player:getHp()
        and (player:getHp() > 0 or player:getHp() == 1 and (player:faceUp() or player:hasSkill("guixin"))) then
        return true
    end
    return false
end


sgs.ai_skill_invoke.biyues = function(self, data)
    local damage = data:toDamage()
    if damage.from and self:isEnemy(damage.from) then
        if damage.from:isKongcheng() and (damage.from:getEquips():length() > 0) and (self:hasSkills(sgs.lose_equip_skill, damage.from)) then
            return false
        end
        return true
    end
    return false
end

sgs.ai_can_damagehp.biyues = function(self, from, card, to)
    return to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to) and from and self:isEnemy(from) and from:isMale() and source_query(self, "doDisCard", from, "he") and
        source_query(to, "canDiscard", from, "he")
end


sgs.ai_skill_invoke.luoshenjhnd = function(self, data)
    return true
end


sgs.ai_skill_invoke.biyuejh = function(self, data)
    local damage = data:toDamage()
    if damage.from and self:isEnemy(damage.from) then
        if damage.from:isKongcheng() and (damage.from:getEquips():length() > 0) and (self:hasSkills(sgs.lose_equip_skill, damage.from)) then
            return false
        end
        return true
    end
    return false
end
sgs.ai_can_damagehp.biyuejh = function(self, from, card, to)
    return to:getHp() + source_query(self, "getAllPeachNum") - source_query(self, "ajustDamage", from, to, 1, card) > 0
        and source_query(self, "canLoseHp", from, card, to) and from and self:isEnemy(from) and from:isMale() and source_query(self, "doDisCard", from, "he") and
        source_query(to, "canDiscard", from, "he")
end


local shijun_skill = {}
shijun_skill.name = "shijun"
table.insert(sgs.ai_skills, shijun_skill)
shijun_skill.getTurnUseCard = function(self)
    if not source_query(self.player, "canDiscard", self.player, "he") then return end
    return parse_action(self,"#shijun:.:")
end

sgs.ai_skill_use_func["#shijun"] = function(card, use, self,request)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sort(self.enemies, "handcard")
    local slashcount = self:getCardsNum("Slash")
    self:sortByUseValue(cards, true)
    if slashcount > 0 then
        for _, card in ipairs(cards) do
            if (not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink")) or self:getOverflow() > 0 then
                local slash = self:getCard("Slash")
                assert(slash)

                local dummy_use = source_query(self, "withOwnerRange", "slashNoDistanceLimit", "shijun", function()
                    return meizl_use_card(self,slash,dummy())
                end)

                local target
                if not dummy_use.to:isEmpty() then
                    for _, p in sgs.qlist(dummy_use.to) do
                        if p:getStrategyMark("shijuntarget") == 0 and not source_query(self.player, "inMyAttackRange", p) then
                            target = p
                            break
                        end
                    end
                end
                if target then
                    use.card = parse_action(self,"#shijun:" .. card:getKnownId() .. ":")
                    if use.to then use.to:append(target) end
                    return
                end
            end
        end
    end
end

sgs.ai_card_intention["shijun"] = 70


sgs.ai_use_value["shijun"] = 9.2
sgs.ai_use_priority["shijun"] = sgs.ai_use_priority.Slash + 0.1



sgs.ai_skill_invoke.shixiang = function(self, data)
    if self.player:getHandcardNum() == 3 then
        return true
    end
    return false
end-- The source constructs a strategy seed before choosing targets/costs. Rebind
-- exactly the first selected proposal, without re-running the policy.
for class,skill in pairs(action_skills)do
    local fn=sgs.ai_skill_use_func[class]
    if type(fn)=='function' then
        sgs.ai_skill_use_func[class]=function(card,use,self,request)
            local previous=self._meizl_request
            self._meizl_request=request
            local ok,result=pcall(fn,card,use,self,request)
            self._meizl_request=previous
            if not ok then error(result,0)end
            if use.card then use.card=materialize_action(self,use.card,request)end
            return result
        end
    end
end
local meizl_fill_names={}
for i=first_skill_index+1,#sgs.ai_skills do
    local sk=sgs.ai_skills[i]
    if type(sk.getTurnUseCard)=='function'then sgs.ai_fill_skill[sk.name]=sk.getTurnUseCard;meizl_fill_names[#meizl_fill_names+1]=sk.name end
end
for _,skill in ipairs(meizl_fill_names)do
    local fn=sgs.ai_fill_skill[skill]
    sgs.ai_fill_skill[skill]=function(self,inclusive,request)
        local previous,stage=self._meizl_request,self._meizl_stage
        self._meizl_request,self._meizl_stage=request,'fill'
        local ok,result=pcall(fn,self,inclusive,request)
        self._meizl_request,self._meizl_stage=previous,stage
        if not ok then error(result,0)end
        return select_preview(self,result,request)
    end
end
