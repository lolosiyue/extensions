-- Fixed b6025acc fcDIY. Native simulations are readonly; final selected
-- materials are rebound through issued scopes. No source registry fallback.
local function known(v,k)
    if AIUnsupported.is(v) then error(v,0) end
    if v==nil then ai_unsupported('FcDIY missing '..k,'fcDIY') end
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
    local use=AIUsePlan.new()
    use.isDummy=isDummy~=false;use.extra_target=extra or 0;use.current_targets=current or {}
    return use
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
    c.toCardSpec=function()ai_unsupported('readonly draft has no payment authority','fcDIY')end
    return c
end
resolve_preview=function(c)
    local st=preview_specs[c];if not st then return c end
    if st.cached then return st.cached end
    local r
    local r41_sources={f_luanshe='f_luanshe',sp_taoyuanyi='sp_taoyuanyi',
        sp_qianlixing='sp_qianlixing',sp_hengsaoqianjun='sp_hengsaoqianjun',
        sp_lvezhen='sp_lvezhen',fcj_qinguo='fcj_qinguo',fcj_leixi='fcj_leixi',
        mouduanliangv='mouduanliangg',kjmoushifeng='kjmoushifeng'}
    local source=r41_sources[st.skill]
    if source then
        r=source_query(st.ai, 'evaluateOwnerViewAsCard', {source_key='fcDIY.'..source,name=st.name,
            skill=st.skill,suit=st.suit,number=st.number,subcards=copy(st.costs)})
    elseif st.suit~=sgs.Card_NoSuit or st.number~=0 then
        ai_unsupported('readonly clone requires exact nondefault suit/number projection','fcDIY.preview')
    elseif st.skill=='tyshouli' then
        r=source_query(st.ai, 'evaluateOwnerViewAsCard', {source_key='tyshouli',name=st.name,skill='tyshouli',suit=st.suit,number=st.number,subcards=copy(st.costs)})
    elseif st.skill=='' and #st.costs==0 then r=st.base
    else r=source_query(st.ai, 'evaluateSkillCard', st.skill, st.name, st.costs) end
    if st.recast~=nil and source_query(r, 'canRecast')~=st.recast then
        ai_unsupported('readonly setCanRecast hypothesis is unavailable','fcDIY.preview')
    end
    st.ai:inheritLegacyCardIdentity(r,c)
    st.cached=r
    return r
end
local function mutate(self,c,kind,value)
    local st=preview_specs[c]
    if not st then
        ai_unsupported('mutable SkillCard seed requires exact selected-cost evaluation','fcDIY.'..kind)
    end
    st.cached=nil
    if kind=='skill' then st.skill=value;c._view.skill_name=value;c._view.skill_names={value}
    elseif kind=='add' then st.costs[#st.costs+1]=type(value)=='number' and value or value:getKnownEffectiveId()
    elseif kind=='clear' then st.costs={}
    elseif kind=='recast' then st.recast=value
    else ai_unsupported('unknown draft mutation','fcDIY') end
    return c
end
local function use_card(self,c,use)
    c=resolve_preview(c)
    if c and c:isEvaluationOnly() then return self:evaluateCard(c,use) end
    return self:aiUseCard(c,use)
end
local function select_preview(self,c,request)
    local st=preview_specs[c];if not st then return c end
    local r=resolve_preview(c)
    if st.skill=='f_luanshe' or st.skill=='sp_taoyuanyi' or st.skill=='sp_qianlixing' or st.skill=='sp_hengsaoqianjun' then
        local selected=source_query(self, 'evaluateTurnConversion', st.skill, r:getClassName(), {name=st.name,skill=st.skill,suit=st.suit,number=st.number,subcards=copy(st.costs)}, request)
        return self:inheritLegacyCardIdentity(selected,c)
    end
    return source_query(self, 'bindTurnConversion', st.skill, r:getClassName(), {name=st.name,skill_name=st.skill,suit=r:getSuit(),number=r:getNumber(),subcards=copy(st.costs)}, request)
end
local function target_ok(c,from,to,prefix)
    return CanToCard(resolve_preview(c),from,to,prefix)
end
local function scope(self,key)
    local row=source_query(self, 'getDecisionContext').fcDIY
    if type(row)~='table' then ai_unsupported('FcDIY scoped context unavailable',key) end
    return known(row[key],key)
end
local function player(self,name)
    if name==false or name=='' then return nil end
    return source_query(self.room, 'findPlayerByObjectName', name)
end
local function scoped_player(self,key)return player(self,scope(self,key))end
local function scoped_struct(self,key,kind)
    local row=scope(self,key);if row==false then return kind=='use' and {to=AIList.new({})} or {} end
    local r=copy(row)
    for _,k in ipairs({'from','who'}) do if row[k] then r[k]=player(self,row[k]) end end
    if kind=='use' then r.to=AIList.new({});for _,n in ipairs(known(row.to,key..' targets'))do r.to:append(player(self,n))end
    elseif row.to then r.to=player(self,row.to) end
    if row.card then r.card=known(CardView.new(row.card),key..' card');r.card._evaluation_candidate=row.card.evaluation_candidate end
    return r
end
-- Reached source dummy planning only: the current tag object is borrowed from
-- the authenticated native inquiry. The sealed evaluation key never pays.
local function scoped_use_card(self,key,card,use)
    local evaluated=source_query(self, 'evaluateSkillCard', 'fcDIY_context:'..key, card:objectName(), {})
    if source_query(evaluated, 'getLegacyIdentityToken')~=source_query(card, 'getLegacyIdentityToken') then
        ai_unsupported('FC current-use evaluation changed original card identity',key)
    end
    return use_card(self,evaluated,use)
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
    -- Definitions of skills no visible player holds are not projected.
    ai_unsupported('public trigger-skill definition unavailable',name)
end
local function role_estimate(self,p)return source_query(self, 'getRoleEstimate', p)end
local function set_choice(self,key,value)
    self:setStrategyMemory('fcDIY.choice.'..key,value)
    self:useKnowledgeEstimate({value=true,status='estimate',basis='fcDIY.shared_choice_viewer_partition'},key)
end
local function get_choice(self,key)
    local v,yes=self:getStrategyMemory('fcDIY.choice.'..key)
    if not yes then ai_unsupported('shared source choice has not been observed by this viewer',key)end
    self:useKnowledgeEstimate({value=true,status='estimate',basis='fcDIY.shared_choice_viewer_partition'},key)
    return v
end
local function strategy_flag(self,p,flag)
    if flag=='InfinityAttackRange' or flag=='-InfinityAttackRange' then
        ai_unsupported('readonly InfinityAttackRange hypothesis missing','fcDIY')
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
local function translated(s)return ai_unsupported('translations are not projected','translate:'..tostring(s))end
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

local action_skills={["#f_bawangCard"]="f_bawang",["#f_beifaCard"]="f_beifa",["#f_dingjunCard"]="f_dingjun",["#f_diyuxiCard"]="f_diyuxi",["#f_doufaCard"]="f_doufa",["#f_doushenCard"]="f_doushen",["#f_gengzhongCard"]="f_gengzhong",["#f_gongkangCard"]="f_gongkang",["#f_huishiCard"]="f_huishi",["#f_huoxinCard"]="f_huoxin",["#f_jieyiCard"]="f_jieyi",["#f_jiutianCard"]="f_jiutian",["#f_kuzhaCard"]="f_kuzha",["#f_liaoduCard"]="f_liaodu",["#f_luoleiCard"]="f_luolei",["#f_mafeiCard"]="f_mafei",["#f_newdingjunCard"]="f_newdingjun",["#f_renyiCard"]="f_renyi",["#f_shanmengHSCard"]="f_shanmengHS",["#f_shenlinCard"]="f_shenlin",["#f_shennuCard"]="f_shennu",["#f_shenxianshizuCard"]="f_shenxianshizu",["#f_wuqinCard"]="f_wuqin",["#f_yaoshuCard"]="f_yaoshu",["#f_zhanshanCard"]="f_zhanshan",["#fcbshenwuCard"]="fcbshenwuVS",["#fcgongxinCard"]="fcgongxin",["#fcj_fumanCard"]="fcj_fuman",["#fcj_jianjieCard"]="fcj_jianjie",["#fcj_jueyan"]="fcj_jueyan",["#fcj_kannanCard"]="fcj_kannan",["#fcj_pingcaiCard"]="fcj_pingcai",["#fcj_sanchenCard"]="fcj_sanchen",["#fcj_shanxiCard"]="fcj_shanxi",["#fcmoumingceCard"]="fcmoumingce",["#fcmoutiaoxinCard"]="fcmoutiaoxin",["#fcmouyijueCard"]="fcmouyijue",["#fcmouzhibaCard"]="fcmouzhiba",["#fczhizheCard"]="fczhizhe",["#imbaCard"]="imba",["#mouduanlianggCard"]="mouduanliangg",["#mx_hanhunCard"]="mx_hanhun",["#mx_xinghanCard"]="mx_xinghan",["#ps_huairou"]="ps_huairou",["#sp_chibiCard"]="sp_chibi",["#sp_dujiangCard"]="sp_dujiang",["#sp_feijiangCard"]="sp_feijiang",["#sp_guamuCard"]="sp_guamu",["#sp_guimenCard"]="sp_guimen",["#sp_kongjuCard"]="sp_kongju",["#sp_lingyunCard"]="sp_lingyun",["#sp_lvezhenCard"]="sp_lvezhen",["#sp_shenmouCard"]="sp_shenmou",["#sp_shenqi_ubCard"]="sp_shenqi_ub",["#sp_sishiCard"]="sp_sishi",["#sp_tianxiaCard"]="sp_tianxia",["#sp_xiyingCard"]="sp_xiying",["#sp_yaozhi_ubCard"]="sp_yaozhi_ub",["#sp_yuanzhiCard"]="sp_yuanzhi",["#sp_zhengbianCard"]="sp_zhengbian",["#sp_zhujiuCard"]="sp_zhujiu",["#tycuijueCard"]="tycuijue",["#tyshouli"]="tyshouli",["#wxjifengEXCard"]="wxjifengEX"}
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
        if self._fcDIY_stage=='fill' then
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
        return source_query(self, 'bindTurnConversion', skill, face:getClassName(), {name=name,skill_name=skill,suit=actual_suit,number=number,subcards=cs}, self._fcDIY_request)
    end
    local skill=known(action_skills[class],'source skill for '..class)
    local ids=cost_ids(costs);if not ids then return nil end
    local r
    if self._fcDIY_stage=='fill' and skill=='tyshouli' and class=='#tyshouli' then
        r=source_query(self, 'evaluateTurnSkillCard', skill, class, ids, self._fcDIY_request, user)
    elseif self._fcDIY_stage=='fill' and #ids==0 and user=='' then
        r=source_query(self, 'legacySkillSeed', skill, class, self._fcDIY_request)
        action_specs[r]={skill=skill,class=class,costs=ids,user=user,request=self._fcDIY_request}
    else
        r=source_query(self, 'bindSkillCard', skill, ids, self._fcDIY_request, user~=''and user or nil, class)
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
-- Only the viewer's own properties are projected (another player's raises);
-- QVariant::toString of an unset one is "".
local function property_value(self,p,key)
    local v=p:getPropertyValue(key)
    if v==nil then return '' end
    return v
end
local function visible_top_id(self)
    ai_unsupported('the draw pile top is not projected','visible_draw_top_id')
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
    if key=='fcj_huanshiJudge' then
        if type(row)~='table' or row.scope_key~='fcj_huanshi' then
            ai_unsupported('Huanshi current judge is not authenticated',key)
        end
        local judge=copy(row)
        judge.who=player(self,known(row.who,key..'.who'))
        judge.card=known(CardView.new(known(row.card,key..'.card')),key..'.card')
        if type(row.card.evaluation_candidate)=='table' then
            judge.card._evaluation_candidate=copy(row.card.evaluation_candidate)
        end
        -- Direct source judge:isGood(c) is RAW. Shared getRetrialCardId reads
        -- outcome_by_id separately after CardFilter; never conflate the two.
        function judge:isGood(card)
            if card==nil then return known(self.good,key..'.good') end
            local id=card:getKnownEffectiveId()
            local candidate=type(self.candidate_faces)=='table' and self.candidate_faces[tostring(id)]
            if self.raw_outcomes_complete~=true or type(candidate)~='table'
                or source_query(card, 'isVirtualCard') or candidate.name~=card:objectName()
                or candidate.class_name~=card:getClassName() or candidate.suit~=card:getSuit()
                or candidate.number~=card:getNumber() then
                ai_unsupported('Huanshi raw judge candidate is outside its disclosed face domain',key)
            end
            local value=type(self.raw_outcome_by_id)=='table' and self.raw_outcome_by_id[tostring(id)]
            if type(value)~='boolean' then ai_unsupported('Huanshi raw outcome is unknown',key) end
            return value
        end
        function judge:isBad(card)return not self:isGood(card)end
        -- Only the reached invoke exchange valuation needs a planning profile.
        -- The profile describes the same authenticated owner HE object; it is
        -- never a replacement payment card or an AG acquisition.
        function judge:exchangeMaterial(ai,id)
            local card=known_card(ai,id)
            local face=type(self.candidate_faces)=='table' and self.candidate_faces[tostring(id)]
            if type(face)~='table' or face.evaluation_candidate==nil then return card end
            if ai.request.kind~='skill_invoke' or ai.request.options.reason~='fcj_huanshi'
                or source_query(card, 'isVirtualCard') or face.effective_id~=id
                or face.name~=card:objectName() or face.class_name~=card:getClassName()
                or face.suit~=card:getSuit() or face.number~=card:getNumber()
                or type(face.legacy_identity_token)~='string'
                or type(face.material_identity_token)~='string'
                or face.material_identity_token~=source_query(card, 'getLegacyIdentityToken')
                or face.evaluation_only~=true or face.evaluation_owner~=ai.player:objectName() then
                ai_unsupported('Huanshi exchange profile does not match owner material',key)
            end
            local view=known(CardView.new(face),key..'.exchange')
            view._evaluation_candidate=copy(face.evaluation_candidate)
            return view
        end
        return judge
    end
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
    if type(value)~='string'and type(value)~='number'and type(value)~='boolean'then ai_unsupported('nonvalue source cache','fcDIY')end
    return{kind='scalar',value=value}
end
local function unpack_state(self,row)
    if row.kind=='nil'then return nil end
    if row.kind=='scalar'then return row.value end
    if row.kind=='player'then return player(self,row.name)end
    if row.kind=='card'then return self:restorePriorTurnPlan(row.value)end
    if row.kind=='table'then local r={};for k,v in pairs(row.value)do r[k]=unpack_state(self,v)end
        if AIValue.isList(r)then return AIList.new(r)end;return r end
    ai_unsupported('malformed viewer cache','fcDIY')
end
local function set_state(self,key,value)
    self[key]=value
    if key=='kannan_card'then self:remember(key,value and value:getKnownEffectiveId())end
    self:setStrategyMemory('fcDIY.state.'..key,{value=pack_state(self,value),estimates=copy(self.request.scratch.knowledge_estimates or{})})
end
local function get_state(self,key)
    if rawget(self,key)~=nil then return self[key]end
    local row,yes=self:getStrategyMemory('fcDIY.state.'..key)
    if not yes then return nil end
    if type(row)~='table'or type(row.value)~='table'then ai_unsupported('viewer cache malformed',key)end
    for _,entry in ipairs(row.estimates or{})do entry=copy(entry);entry.status='estimate';entry.value=true;self:useKnowledgeEstimate(entry,'fcDIY.cached')end
    self[key]=unpack_state(self,row.value)
    return self[key]
end

local function invoke_peiqi(self,data)
    local fn=sgs.ai_skill_invoke.peiqi
    if type(fn)~='function'then ai_unsupported('effective Peiqi policy is not loaded','fcDIY.sp_kongju')end
    local ok,result=pcall(fn,self,data)
    if self.peiqiData then set_state(self,'peiqiData',self.peiqiData)end
    if not ok then error(result,0)end
    return result
end



sgs.ai_skill_invoke.f_meihun = true

sgs.ai_skill_playerchosen.f_meihun = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
        if self:isEnemy(p) and not p:isAllNude() then
            return p
        end
    end
    return nil
end
sgs.ai_playerchosen_intention.f_meihun = 50

sgs.ai_skill_cardask["@f_meihun-suit"] = function(self,data, pattern)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _,h in sgs.list(cards)do
        if source_query(self, "matchesDiscardPattern", pattern, h)
        then return h:getKnownEffectiveId() end
        if h:getSuitString() == pattern:split("|")[2]
        then return h:getKnownEffectiveId() end
    end
    return self:getCardId(pattern)
end
local f_huoxin_skill = {
    name = "f_huoxin",
    getTurnUseCard = function(self, inclusive)
        if self.player:getStrategyHasUsed("#f_huoxinCard") then return end
        if self.player:isNude() then return end
        local can_use = false
        self:sort(self.enemies, "chaofeng")
        local slash = clone_preview(self,"slash")

        for _, enemy in ipairs(self.enemies) do
            if not source_query(self, "slashIsEffective", slash, enemy) then continue end
            can_use = true
            break
        end
        if can_use then
            return parse_action(self,"#f_huoxinCard:.:")
        end
    end,
}
table.insert(sgs.ai_skills, f_huoxin_skill) --加入AI可用技能表
sgs.ai_skill_use_func["#f_huoxinCard"] = function(card, use, self,request)
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    local slash = clone_preview(self,"slash", sgs.Card_NoSuit, 0)

    if #handcards == 0 then return end
    self:sortByUseValue(handcards, true) --对可用手牌按使用价值从小到大排序
    local slasher, target
    self:sort(self.enemies, "defense")
    for _, enemy_a in ipairs(self.enemies) do
        for _, enemy_b in ipairs(self.enemies) do
            if source_query(enemy_b, "canPindian", enemy_a) and enemy_a:objectName() ~= enemy_b:objectName() and enemy_a:getStrategyMark("&f_meihuo") > 0  then
                slasher = enemy_b
                target = enemy_a
                break
            end
        end
    end
    if not slasher then
        for _, enemy_a in ipairs(self.enemies) do
            for _, enemy_b in ipairs(self.enemies) do
                if source_query(enemy_b, "canPindian", enemy_a) and enemy_a:objectName() ~= enemy_b:objectName() then
                    slasher = enemy_b
                    target = enemy_a
                    break
                end
            end
        end
    end

    if slasher and target then
        for _, c in ipairs(handcards) do
            for _, c2 in ipairs(handcards) do
                if c:getKnownEffectiveId() ~= c2:getKnownEffectiveId() and c:getSuit() == c2:getSuit() then
                    local card_str = string.format("#f_huoxinCard:%s+%s:", c:getKnownEffectiveId(), c2:getKnownEffectiveId())
                    local acard = parse_action(self,card_str)
                    use.card = acard
                    if use.to then
                        use.to:append(slasher)
                        use.to:append(target)
                        return
                    end
                end
            end
        end
    end
end
sgs.ai_playerchosen_intention["f_huoxinCard"] = 80
sgs.ai_use_priority["f_huoxinCard"] = 2.3

sgs.ai_skill_use["@@f_huoxin!"] = function(self,prompt)
    local min = 999
    if self.player:getPile("f_huoxinPindianCard"):length() > 1 then
        for _, id in sgs.qlist(self.player:getPile("f_huoxinPindianCard")) do
            if known_card(self,id):getNumber() < min then
                min = known_card(self,id):getNumber()
            end
        end
        for _, p in sgs.qlist(self.room:getAlivePlayers()) do
            if p:getStrategyFlag("f_huoxin_pindiantargets") and p:getStrategyMark("&f_meihuo") > 0 then
                for _, id in sgs.qlist(self.player:getPile("f_huoxinPindianCard")) do
                    if known_card(self,id):getNumber() == min then
                        return "#f_huoxinGPCCard:".. id..":->"..p:objectName()
                    end
                end
            end
        end
    end
    if self.player:getPile("f_huoxinPindianCard"):length() > 0 then
        for _, id in sgs.qlist(self.player:getPile("f_huoxinPindianCard")) do
            for _, p in sgs.qlist(self.room:getAlivePlayers()) do
                if p:getStrategyFlag("f_huoxin_pindiantargets") then
                    return "#f_huoxinGPCCard:".. id..":->"..p:objectName()
                end
            end
        end
    end

end
sgs.ai_skill_invoke.f_huoxin = true



sgs.ai_skill_invoke.f_taiping = function(self, data)
    self:sort(self.enemies)
    self.enemies = sgs.reverse(self.enemies)
    for _, enemy in ipairs(self.enemies) do
        if not source_query(self, "needToLoseHp", enemy) and not enemy:isChained() and (source_query(self, "damageIsEffective", enemy, "T") or source_query(self, "damageIsEffective", enemy, "F")) then
            return true
        end
    end
    for _, friend in ipairs(self.friends) do
        if not source_query(self, "needToLoseHp", friend) and friend:isChained() then
            return true
        end
    end
    for _, friend in ipairs(self.friends) do
        if source_query(self, "needToLoseHp", friend) and not friend:isChained() then
            return true
        end
    end
    return false
end

sgs.ai_skill_playerchosen.f_taiping = function(self, targets)
    local targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _,p in ipairs(targets) do
        if self:isEnemy(p) then
            if not source_query(self, "needToLoseHp", p) and not p:isChained() and (source_query(self, "damageIsEffective", p, "T") or source_query(self, "damageIsEffective", p, "F")) then
                return p
            end
        end
        if self:isFriend(p) then
            if not source_query(self, "needToLoseHp", p) and p:isChained() then
                return p
            end
            if source_query(self, "needToLoseHp", p) and not p:isChained() then
                return p
            end
        end
    end
end

sgs.ai_skill_choice.f_taiping = function(self, choices, data)
    local target = data:toPlayer()
    if self:isEnemy(target) then
        if not source_query(self, "needToLoseHp", target) and not target:isChained() and (source_query(self, "damageIsEffective", target, "T") or source_query(self, "damageIsEffective", target, "F")) then
            return "tpChain"
        end
    end
    if self:isFriend(target) then
        if not source_query(self, "needToLoseHp", target) and target:isChained() then
            return "tpRestore"
        end
        if source_query(self, "needToLoseHp", target) and not target:isChained() then
            return "tpChain"
        end
    end
    return "tpChain"
end



local f_yaoshu_skill = {}
f_yaoshu_skill.name = "f_yaoshu"
table.insert(sgs.ai_skills, f_yaoshu_skill)
f_yaoshu_skill.getTurnUseCard          = function(self, inclusive)
    local source = self.player
    return parse_action(self,"#f_yaoshuCard:.:")
end

sgs.ai_skill_use_func["#f_yaoshuCard"] = function(card, use, self,request)
    local targets = AIList.new({})
    self:sort(self.enemies, "defense")
    for _, enemy in ipairs(self.enemies) do
        if enemy and targets:length() < 3 and enemy:faceUp() then
            targets:append(enemy)
        end
    end
    if targets:length() >= 1 and source_query(self.room, "getTurnCount") > 0 then
        use.card = parse_action(self,"#f_yaoshuCard:.:")
        if use.to then use.to = targets end
        return
    end
end

sgs.ai_use_priority["f_yaoshuCard"]    = 6
sgs.ai_card_intention["f_yaoshuCard"]  = 100

local f_luolei_skill = {}
f_luolei_skill.name = "f_luolei"
table.insert(sgs.ai_skills, f_luolei_skill)
f_luolei_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@f_luolei") == 0 then return end
    return parse_action(self,"#f_luoleiCard:.:")
end

sgs.ai_skill_use_func["#f_luoleiCard"] = function(card, use, self,request)
    if self.player:getStrategyMark("@f_luolei") > 0 then
        self:sort(self.enemies)
        self.enemies = sgs.reverse(self.enemies)
        for _, enemy in ipairs(self.enemies) do
            if source_query(self, "objectiveLevel", enemy) > 0 and not source_query(self, "cantbeHurt", enemy) and source_query(self, "damageIsEffective", enemy, "T") then
                use.card = card
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end

sgs.ai_use_value.f_luoleiCard = 8.5
sgs.ai_use_priority.f_luoleiCard = 9.5
sgs.ai_card_intention.f_luoleiCard = 80


local f_doushen_skill = {}
f_doushen_skill.name = "f_doushen"
table.insert(sgs.ai_skills, f_doushen_skill)
f_doushen_skill.getTurnUseCard = function(self)
    return parse_action(self,"#f_doushenCard:.:")
end

sgs.ai_skill_use_func["#f_doushenCard"] = function(card, use, self,request)
    local slashcount = self:getCardsNum("Slash")
    if slashcount >= 2 or (self:getOverflow() > 0 and slashcount > 0) then

        local slash = self:getCard("Slash")
        if not slash then return end
        local dummy_use = dummy()
        if slash then self:useBasicCard(slash,dummy_use) end
        if dummy_use.card then
            use.card = card
            return
        end
    end
end

sgs.ai_use_value["f_doushenCard"] = 9.7
sgs.ai_use_priority["f_doushenCard"] = 7
sgs.f_doushen_keep_value = {
    Peach = 6,
    Analeptic = 5.8,
    Jink = 5.3,
    FireSlash = 5.6,
    Slash = 5.4,
    ThunderSlash = 5.5,
    ExNihilo = 4.7
}

sgs.ai_view_as.f_jiuwei = function(card, player, card_place)
    local suit = card:getSuitString()
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
    and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
        return ("analeptic:f_jiuwei[%s:%s]=%d"):format(suit, number, card_id)
    end
end

ai_audited_aliases.register{id="ai_cardneed.f_jiuwei",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"f_jiuwei"},canonical_registry="ai_cardneed",canonical_path={"slash"}}

sgs.ai_ajustdamage_from.f_jiuwei = function(self,from,to,slash,nature)
    if slash and slash:isKindOf("Slash") and slash:getStrategyFlag("drank")
    then return 1 end
end

sgs.ai_used_revises.f_jiuwei = function(self, use)
    if use.card:isKindOf("Slash")
        and self.player:getStrategyFlag("f_doushenBuff")
        and self.player:getStrategyMark("drank") == 0
        and not use.isDummy
    then
        for _, to in sgs.list(use.to) do
            if self:isEnemy(to) then
                local handcards = sgs.QList2Table(self.player:getCards("h"))
                local card_str =("analeptic:f_jiuwei[%s:%s]=%d"):format(handcards[1]:getSuitString(), handcards[1]:getNumberString(), handcards[1]:getEffectiveId())
                local acard = parse_action(self,card_str)
                use.card = acard
                use.to = AIList.new({})
                return false
            end
        end
    end
end



local f_shenlin_skill = {}
f_shenlin_skill.name = "f_shenlin"
table.insert(sgs.ai_skills, f_shenlin_skill)
f_shenlin_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#f_shenlinCard") or self.player:getHandcardNum() < 3 or (self:getCardsNum("TrickCard") == 0 and self:getCardsNum("EquipCard") == 0) or #self.enemies == 0 then return end
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
                if acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace") then
                    card_id = acard:getKnownEffectiveId()
                    break
                end
            end
        end
    elseif not self.player:getEquips():isEmpty() then
        local player = self.player
        if player:getWeapon() then card_id = player:getWeapon():getId()
        elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
        elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
        elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
        end
    end
    if not card_id then
        if lightning and not self:willUseLightning(lightning) then
            card_id = lightning:getKnownEffectiveId()
        else
            for _, acard in ipairs(cards) do
                if acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace") then
                    card_id = acard:getKnownEffectiveId()
                    break
                end
            end
        end
    end
    if not card_id then
        return nil
    else
        return parse_action(self,"#f_shenlinCard:"..card_id..":")
    end
end

sgs.ai_skill_use_func["#f_shenlinCard"] = function(card, use, self,request)
    if not self.player:getStrategyHasUsed("#f_shenlinCard") and self.player:getHandcardNum() > 2 then
        self:sort(self.enemies)
        self.enemies = sgs.reverse(self.enemies)
        for _, enemy in ipairs(self.enemies) do
            if source_query(self, "objectiveLevel", enemy) > 0 then
                use.card = card
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end

sgs.ai_use_value.f_shenlinCard = 9
sgs.ai_use_priority.f_shenlinCard = 9.7
sgs.ai_card_intention.f_shenlinCard = 90

local f_shennu_skill = {}
f_shennu_skill.name = "f_shennu"
table.insert(sgs.ai_skills, f_shennu_skill)
f_shennu_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#f_shennuCard") or self.player:getHp() < 2 or self:getCardsNum("Slash") == 0 then return end
    return parse_action(self,"#f_shennuCard:.:")
end

sgs.ai_skill_use_func["#f_shennuCard"] = function(card, use, self,request)
    if not self.player:getStrategyFlag("shenzhinuhuo") then
        use.card = card
        return
    end
end

sgs.ai_use_value.f_shennuCard = 8.5
sgs.ai_use_priority.f_shennuCard = 9.5
sgs.ai_card_intention.f_shennuCard = -80

sgs.double_slash_skill = sgs.double_slash_skill .. "|f_shennu"
ai_audited_aliases.register{id="ai_cardneed.f_shennu",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"f_shennu"},canonical_registry="ai_cardneed",canonical_path={"slash"}}
sgs.ai_ajustdamage_from.f_shennu = function(self,from,to,slash,nature)
    if slash and slash:isKindOf("Slash") and from:getStrategyFlag("shenzhinuhuo") then
        local x = 0
        if slash:isRed() then
            x = x + 1
        end
        if to:getStrategyFlag("suodingcaozei") then
            x = x + 1
        end
        return x
    end
end

sgs.ai_canliegong_skill.f_shennu = function(self, from, to)
    return from:getStrategyFlag("shenzhinuhuo")
end

local function isSpecialOne(player, name)
    local g_name = translated(source_query(player, "getGeneralName"))
    if string.find(g_name, name) then return true end
    if (source_query(player, "getGeneral2Name")~="") then
        g_name = translated(source_query(player, "getGeneral2Name"))
        if string.find(g_name, name) then return true end
    end
    return false
end
sgs.ai_ajustdamage_from.f_caohen = function(self,from,to,slash,nature)
    if isSpecialOne(to, "曹操") or (to:getKnownKingdom() == "wei" and source_query(to, "isLord"))
    then return 1 end
end


local f_beifa_skill = {}
f_beifa_skill.name = "f_beifa"
table.insert(sgs.ai_skills, f_beifa_skill)
f_beifa_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#f_beifaCard") or self.player:isNude() or #self.enemies == 0 then return end
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
        if player:getWeapon() then card_id = player:getWeapon():getId()
        elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
        elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
        elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
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
    if not card_id then
        return nil
    else
        return parse_action(self,"#f_beifaCard:"..card_id..":")
    end
end

sgs.ai_skill_use_func["#f_beifaCard"] = function(card, use, self,request)
    if not self.player:getStrategyHasUsed("#f_beifaCard") then
        self:sort(self.enemies)
        self.enemies = sgs.reverse(self.enemies)
        for _, enemy in ipairs(self.enemies) do
            if source_query(self, "objectiveLevel", enemy) > 0 then
                use.card = card
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end

sgs.ai_use_value.f_beifaCard = 8.5
sgs.ai_use_priority.f_beifaCard = 9.5
sgs.ai_card_intention.f_beifaCard = 80

local mx_xinghan_skill = {}
mx_xinghan_skill.name = "mx_xinghan"
table.insert(sgs.ai_skills, mx_xinghan_skill)
mx_xinghan_skill.getTurnUseCard = function(self)
    local choices = {}
    if not self.player:hasSkill("kongcheng") then
        table.insert(choices, "addskill_kongcheng")
    end
    if not self.player:hasSkill("tenyearwusheng") then
        table.insert(choices, "addskill_wusheng")
    end
    if not self.player:hasSkill("olpaoxiao") then
        table.insert(choices, "addskill_paoxiao")
    end
    if not self.player:hasSkill("olyajiao") then
        table.insert(choices, "addskill_yajiao")
    end
    if not self.player:hasSkill("tenyearliegong") then
        table.insert(choices, "addskill_liegong")
    end
    if not self.player:hasSkill("tieji") then
        table.insert(choices, "addskill_tieqi")
    end
    if #choices > 0 then
        return parse_action(self,"#mx_xinghanCard:.:")
    end
end

sgs.ai_skill_use_func["#mx_xinghanCard"] = function(card, use, self,request)
    use.card = card
    return
end

sgs.ai_use_value.mx_xinghanCard = 8.5
sgs.ai_use_priority.mx_xinghanCard = 9.5
sgs.ai_skill_choice["mx_xinghan"] = function(self, choices, data)
    local items = choices:split("+")
    return items[math.random(1, #items)]
end


local mx_hanhun_skill = {}
mx_hanhun_skill.name = "mx_hanhun"
table.insert(sgs.ai_skills, mx_hanhun_skill)
mx_hanhun_skill.getTurnUseCard = function(self)
    local use_cards = {}
    local type = {}
    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _, acard in ipairs(cards) do
        if not table.contains(type, acard:getTypeId()) then
            table.insert(type, acard:getTypeId())
            table.insert(use_cards, acard:getKnownEffectiveId())
        end
    end

    if #use_cards == 3 then
        return parse_action(self,"#mx_hanhunCard:" .. table.concat(use_cards, "+") .. ":")
    end
end

sgs.ai_skill_use_func["#mx_hanhunCard"] = function(card, use, self,request)
    use.card = card
    if use.to then use.to:append(self.player) end
    return
end

sgs.ai_use_value.mx_hanhunCard = 8.5
sgs.ai_use_priority.mx_hanhunCard = 9.5
sgs.ai_card_intention.mx_hanhunCard = -80


sgs.ai_skill_invoke.f_zhanshan = function(self, data)
    if self.player:getMaxHp() <= 2 then return false end
    return true
end

local f_zhanshan_skill = {}
f_zhanshan_skill.name = "f_zhanshan"
table.insert(sgs.ai_skills, f_zhanshan_skill)
f_zhanshan_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("&mark_zhanshan")<2 and self:getCardsNum("Peach")<=self.player:getLostHp() then return nil end
    for _,who in ipairs(self.friends_noself)do
        if who:getStrategyMark("&mark_zhanshan")<1 then
            return parse_action(self,"#f_zhanshanCard:.:")
        end
    end

end

sgs.ai_skill_use_func["#f_zhanshanCard"] = function(card, use, self,request)
    for _,who in ipairs(self.friends_noself)do
        if who:getStrategyMark("&mark_zhanshan")<1 then
            use.card = card
            if use.to then
                use.to:append(who)
                return
            end
        end
    end

    return
end

sgs.ai_use_value.f_zhanshanCard = 8.5
sgs.ai_use_priority.f_zhanshanCard = 9.5
sgs.ai_card_intention.f_zhanshanCard = -80



local f_jieyi_skill = {}
f_jieyi_skill.name = "f_jieyi"
table.insert(sgs.ai_skills, f_jieyi_skill)
f_jieyi_skill.getTurnUseCard = function(self)
    if #self.friends_noself < 1 then return end
    return parse_action(self,"#f_jieyiCard:.:")
end

sgs.ai_skill_use_func["#f_jieyiCard"] = function(card, use, self,request)
    local targets = AIList.new({})
    for _,friend in ipairs(self.friends_noself)do
        targets:append(friend)
        if targets:length() >= 2 then break end
    end
    if targets:length() == 2 then
        use.card = card
        use.to = targets
        return
    end
end
sgs.ai_card_intention.f_jieyiCard = -100
sgs.ai_use_priority.f_jieyiCard = 9.6
sgs.ai_skill_use["@@yizhiLoyal"] = function(self,prompt)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local targets = AIList.new({})
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if p:getStrategyMark("&XD") > 0 then
            targets:append(p)
        end
    end
    if targets:length() == 0 then return "." end
    local c,to = self:getCardNeedPlayer(cards, false, targets)
    if c and to then return "#yizhiLoyalCard:"..c:getKnownEffectiveId()..":->"..to:objectName() end
    return "."
end

local f_renyi_skill = {}
f_renyi_skill.name = "f_renyi"
table.insert(sgs.ai_skills, f_renyi_skill)
f_renyi_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#f_renyiCard") then return end
    return parse_action(self,"#f_renyiCard:.:")
end

sgs.ai_skill_use_func["#f_renyiCard"] = function(card, use, self,request)
    if not self.player:getStrategyHasUsed("#f_renyiCard") then
        use.card = card
        return
    end
end
sgs.ai_use_value.f_renyiCard = 8.5
sgs.ai_use_priority.f_renyiCard = 9.5
sgs.ai_card_intention.f_renyiCard = -80

sgs.ai_ajustdamage_from.f_renyi = function(self,from,to,card,nature)
    if card and source_query(card, "isDamageCard") and from:getStrategyMark("f_renyiBUFF") > 0
    then return 1 end
end
sgs.ai_skill_use["@@f_renyiX!"] = function(self,prompt)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local targets = AIList.new({})
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if p:getStrategyMark("&XD") > 0 then
            targets:append(p)
        end
    end
    if targets:length() == 0 then
        local c,to = self:getCardNeedPlayer(cards, false)
        if c and to then return "#f_renyiXCard:"..c:getKnownEffectiveId()..":->"..to:objectName() end
    end
    local c,to = self:getCardNeedPlayer(cards, false, targets)
    if c and to then return "#f_renyiXCard:"..c:getKnownEffectiveId()..":->"..to:objectName() end
    for _, friend in ipairs(self.friends_noself) do
        if friend:getStrategyMark("&XD") > 0 then
            for _,h in sgs.list(self.player:getHandcards())do
                if self:willUse(self.player, h) and source_query(h, "isAvailable", self.player) then continue end
                return "#f_renyiXCard:"..h:getKnownEffectiveId()..":->"..friend:objectName()
            end
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        for _,h in sgs.list(self.player:getHandcards())do
            if self:willUse(self.player, h) and source_query(h, "isAvailable", self.player) then continue end
            return "#f_renyiXCard:"..h:getKnownEffectiveId()..":->"..friend:objectName()
        end
    end

    return "."
end

sgs.ai_skill_playerchosen["f_hanzhongwang"] = function(self, targets)
    for _, friend in ipairs(self.friends_noself) do
        if friend:getKnownKingdom() ~= "shu" then
            return friend
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if enemy:getKnownKingdom() ~= "shu" then
            return enemy
        end
    end

    return nil
end
sgs.ai_ajustdamage_from["&f_hanzhongwang"] = function(self,from,to,card,nature)
    if from:getPhase() ~= sgs.Player_NotActive
    then return 1 end
end
sgs.ai_skill_use["@@f_hanzhongwang"] = function(self,prompt)
    local targets = {}
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if p:getKnownKingdom() == "shu" and not p:isAllNude() then
            table.insert(targets, p:objectName())
        end
    end
    if #targets > 0 then
        return "#f_hanzhongwangCard:.:->".. table.concat(targets, "+")
    end
    return "."
end

sgs.ai_ajustdamage_from.f_shengong = function(self,from,to,card,nature)
    if from:getPile("ShenJian"):length() >= 12 and card and card:isKindOf("Slash")
    then return 1 end
end
ai_audited_aliases.register{id="ai_cardneed.f_shengong",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"f_shengong"},canonical_registry="ai_cardneed",canonical_path={"slash"}}
sgs.hit_skill = sgs.hit_skill .. "|f_shengong"

sgs.ai_canliegong_skill.f_shengong = function(self, from, to)
    return from:getPile("ShenJian"):length() >= 8
end

local f_dingjun_skill = {}
f_dingjun_skill.name = "f_dingjun"
table.insert(sgs.ai_skills, f_dingjun_skill)
f_dingjun_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#f_dingjunCard") and self.player:getPile("ShenJian"):length() >= 16 and self.player:getHandcardNum() <= 6 then return end
    return parse_action(self,"#f_dingjunCard:.:")
end

sgs.ai_skill_use_func["#f_dingjunCard"] = function(card, use, self,request)
    if not self.player:getStrategyHasUsed("#f_dingjunCard") and self.player:getPile("ShenJian"):length() < 16 and self.player:getHandcardNum() > 6 then
        use.card = card
        return
    end
end

sgs.ai_skill_choice.f_dingjun = function(self, choices, data)
    if self.player:getStrategyMark("DJSZhanGong") == 0 and self.player:getHandcardNum() >= 4 then return "add4ShenJian" end
    if self.player:getStrategyMark("DJSZhanGong") == 0 and self.player:getPile("ShenJian"):length() >= 4 and self.player:getHp() <= 2 and self.player:isKongcheng() then return "get4ShenJian" end
end

sgs.ai_use_value.f_dingjunCard = 8.5
sgs.ai_use_priority.f_dingjunCard = 9.5
sgs.ai_card_intention.f_dingjunCard = -80


local f_luanshe_skill = {}
f_luanshe_skill.name = "f_luanshe"
table.insert(sgs.ai_skills, f_luanshe_skill)
f_luanshe_skill.getTurnUseCard = function(self)
    if self.player:getPile("ShenJian"):length()  <= 6 then return end
    local useAll = false
    for _,enemy in sgs.list(self.enemies)do
        if enemy:getHp()==1 and not source_query(enemy, "hasArmorEffect", "Vine")
        and not source_query(self, "hasEightDiagramEffect", enemy) and source_query(self, "damageIsEffective", enemy, nil, self.player) and self:isWeak(enemy)
        and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
        then useAll = true end
    end
    if (source_query(self.player, "aliveCount") - self.player:getHp() * 2) < 0 and not useAll then return end
    local use_cards = {}
    for _, id in sgs.qlist(self.player:getPile("ShenJian")) do
        table.insert(use_cards, known_card(self,id))
        if #use_cards >= self.player:getHp() * 2 then break end
    end
    local archery_attack =  clone_preview(self,"archery_attack", sgs.Card_NoSuit, 0)

    mutate(self,archery_attack,"skill","f_luanshe")
    for _,c in ipairs(use_cards)do
        mutate(self,archery_attack,"add",c)
    end
    assert(archery_attack)

    local dummy_use = dummy()
    self:useTrickCard(resolve_preview(archery_attack),dummy_use)
    if dummy_use.card then
        return archery_attack
    end

end



local f_newdingjun_skill = {}
f_newdingjun_skill.name = "f_newdingjun"
table.insert(sgs.ai_skills, f_newdingjun_skill)
f_newdingjun_skill.getTurnUseCard = function(self)
    if self.player:getPile("ShenJian"):length() >= 16 and self.player:getHandcardNum() <= 3 then return end
    return parse_action(self,"#f_newdingjunCard:.:")
end

sgs.ai_skill_use_func["#f_newdingjunCard"] = function(card, use, self,request)
    if self.player:getPile("ShenJian"):length() < 16 and self.player:getHandcardNum() > 3 then
        use.card = card
        return
    end
    if self.player:getPile("ShenJian"):length() > 0 and not self.player:hasSkill("tenyearliegong")  then
        use.card = card
        return
    end
end

sgs.ai_skill_choice.f_newdingjun = function(self, choices, data)
    local items = choices:split("+")
    if table.contains(items, "add1to4ShenJian") and self.player:getStrategyMark("DJSZhanGong") > 0 and not self.player:isKongcheng() then return "add1to4ShenJian" end
    if table.contains(items, "get1to4ShenJian") and self.player:getStrategyMark("DJSZhanGong") > 0 and self.player:getPile("ShenJian"):length() > 0 and not self.player:hasSkill("tenyearliegong") then return "get1to4ShenJian" end
end

sgs.ai_use_value.f_newdingjunCard = 8.5
sgs.ai_use_priority.f_newdingjunCard = 9.5
sgs.ai_card_intention.f_newdingjunCard = -80

sgs.ai_skill_use["@@getFShenJianSkill"] = function(self, prompt)
    local card = parse_action(self,"#getFShenJianSkillCard:.:")
    local dummy_use = {isDummy = true}
    self:useSkillCard(card, dummy_use)
    if dummy_use.card then return (dummy_use.card):toString() .. "->." end
    return "."
end

sgs.ai_skill_use["@@getOTFShenJianSkill"] = function(self, prompt)
    local use_cards = {}
    for _, id in sgs.qlist(self.player:getPile("ShenJian")) do
        table.insert(use_cards, id)
        if #use_cards >= 1 then break end
    end
    if #use_cards > 0 then return "#getOTFShenJianSkillCard:" .. table.concat(use_cards, "+") .. ":" end
    return "."
end



local f_bawang_skill = {}
f_bawang_skill.name = "f_bawang"
table.insert(sgs.ai_skills, f_bawang_skill)
f_bawang_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#f_bawangCard") or (self:getCardsNum("Slash") == 0 and self:getCardsNum("Jink") == 0 and self:getCardsNum("Analeptic") == 0) or #self.enemies == 0 then return end
    local card_id
    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _, acard in ipairs(cards) do
        if acard:isKindOf("BasicCard") and not acard:isKindOf("Peach") then
            card_id = acard:getKnownEffectiveId()
            break
        end
    end
    if not card_id then
        return nil
    else
        return parse_action(self,"#f_bawangCard:"..card_id..":")
    end
end

sgs.ai_skill_use_func["#f_bawangCard"] = function(card, use, self,request)
    if not self.player:getStrategyHasUsed("#f_bawangCard") then
        self:sort(self.enemies)
        self.enemies = sgs.reverse(self.enemies)
        for _, enemy in ipairs(self.enemies) do
            if source_query(self, "objectiveLevel", enemy) > 0 and source_query(self, "damageIsEffective", enemy, sgs.DamageStruct_Normal) and not source_query(self, "cantbeHurt", enemy) then
                use.card = card
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end

sgs.ai_use_value.f_bawangCard = 8.5
sgs.ai_use_priority.f_bawangCard = 9.5
sgs.ai_card_intention.f_bawangCard = 80

ai_audited_aliases.register{id="ai_cardneed.f_zhuifeng",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"f_zhuifeng"},canonical_registry="ai_cardneed",canonical_path={"slash"}}

ai_audited_aliases.register{id="ai_skill_playerchosen.f_pofuchenzhou",defer_canonical=true,self_index=1,registry="ai_skill_playerchosen",path={"f_pofuchenzhou"},canonical_registry="ai_skill_playerchosen",canonical_path={"damage"}}


local f_doufa_skill = {}
f_doufa_skill.name = "f_doufa"
table.insert(sgs.ai_skills, f_doufa_skill)
f_doufa_skill.getTurnUseCard = function(self)
    if self.player:getHp() >= 4 then return end
    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local use_cards = {}
    for _, acard in ipairs(cards) do
        if acard:isKindOf("BasicCard") and not acard:isKindOf("Peach") then
            table.insert(use_cards, acard:getKnownEffectiveId())
            if #use_cards >= self.player:getHp() then break end
        end
    end
    if #use_cards > 0 then
        return parse_action(self,"#f_doufaCard:".. table.concat(use_cards, "+") .. ":")
    end
end

sgs.ai_skill_use_func["#f_doufaCard"] = function(card, use, self,request)
    if not self.player:getStrategyHasUsed("#f_doufaCard") then
        self:sort(self.enemies)
        self.enemies = sgs.reverse(self.enemies)
        for _, enemy in ipairs(self.enemies) do
            if source_query(self, "objectiveLevel", enemy) > 0 and not source_query(self, "cantbeHurt", enemy) then
                use.card = card
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end

sgs.ai_use_value.f_doufaCard = 8.5
sgs.ai_use_priority.f_doufaCard = 9.5
sgs.ai_card_intention.f_doufaCard = 80



local f_diyuxi_skill = {}
f_diyuxi_skill.name = "f_diyuxi"
table.insert(sgs.ai_skills, f_diyuxi_skill)
f_diyuxi_skill.getTurnUseCard = function(self)
    if self.player:getHp() <= 1 and self.player:getMaxHp() <= 1 then return end
    return parse_action(self,"#f_diyuxiCard:.:")
end

sgs.ai_skill_use_func["#f_diyuxiCard"] = function(card, use, self,request)
    if not self.player:getStrategyHasUsed("#f_diyuxiCard") then --保证（非特殊情况）每回合必选一项且仅选一项，避免结束阶段失去体力
        use.card = card
        return
    end
    if math.random() < 0.5 and source_query(self, "getPriorTurnUseCount") > 0 and #self.enemies > 0 then
        use.card = card
        return
    end
end

sgs.ai_skill_choice.f_diyuxi = function(self, choices, data)
    if self.player:getHp() - self.player:getMaxHp() < 0 and self.player:getMaxHp() > 1 and (self:getCardsNum("Duel") > 0 or self:getCardsNum("SavageAssault") > 0 or self:getCardsNum("ArcheryAttack") > 0 or self:getCardsNum("FireAttack") > 0 or self:getCardsNum("Drowning") > 0 or self:getCardsNum("Chuqibuyi") > 0 or self:getCardsNum("Qizhengxiangsheng") > 0) then return "LM1D2D1" end

        for _,h in sgs.list(self.player:getHandcards())do
            if source_query(h, "isDamageCard") and not h:isKindOf("Slash") and self.player:getMaxHp() > 1 and self.player:isWounded() then
                return "LM1D2D1"
            end
        end
    if self.player:getHp() <= 1 and self.player:getMaxHp() > 1 then return "LM1D2D1" end
    if self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 and (self:getCardsNum("Duel") == 0 and self:getCardsNum("SavageAssault") == 0 and self:getCardsNum("ArcheryAttack") == 0 and self:getCardsNum("FireAttack") == 0 and self:getCardsNum("Drowning") == 0 and self:getCardsNum("Chuqibuyi") == 0 and self:getCardsNum("Qizhengxiangsheng") == 0) then return "cancel" end
    return "L1D1SD1"
end

sgs.ai_use_value.f_diyuxiCard = 10
sgs.ai_use_priority.f_diyuxiCard = 10
sgs.ai_card_intention.f_diyuxiCard = -100


sgs.ai_ajustdamage_from.f_diyuxi = function(self,from,to,card,nature)
    local x = 0
    if from:getStrategyFlag("LM1D2D1_BUFF")
    then x = x + 1 end
    if from:getStrategyFlag("L1D1SD1_BUFF") and card and card:isKindOf("Slash")
    then x = x + 1 end
    return x
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|f_kuanglong"
ai_audited_aliases.register{id="ai_cardneed.f_kuanglong",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"f_kuanglong"},canonical_registry="ai_cardneed",canonical_path={"slash"}}



sgs.ai_skill_use["@@f_juxing"] = function(self,prompt)
    for _, friend in ipairs(self.friends_noself) do
        if friend:getStrategyMark("&KunPeng") == 0 then
            return "#f_juxingCard:.:->"..friend:objectName()
        end
    end
    return "."
end
sgs.ai_card_intention["f_juxingCard"]    = -80
local f_jiutian_skill = {}
f_jiutian_skill.name = "f_jiutian"
table.insert(sgs.ai_skills, f_jiutian_skill)
f_jiutian_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("&f_juxing_trigger") == 0 and self.player:getMaxHp() <= 1 then return end
    return parse_action(self,"#f_jiutianCard:.:")
end

sgs.ai_skill_use_func["#f_jiutianCard"] = function(card, use, self,request)
    if self.player:getStrategyMark("&f_juxing_trigger") > 0 and self.player:getMaxHp() > 1 then
        use.card = card
        return
    end
end

sgs.ai_skill_playerchosen["#f_jiutianContinue"] = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
        if self:isFriend(p) and (p:getHandcardNum() < p:getHp() or p:isWounded()) then
            return p
        end
    end
    return self.player
end
sgs.ai_playerchosen_intention["#f_jiutianContinue"] = -70

sgs.ai_use_value.f_jiutianCard = 10
sgs.ai_use_priority.f_jiutianCard = 10
sgs.ai_card_intention.f_jiutianCard = -87


sgs.ai_skill_invoke.fcshelie = true
sgs.ai_skill_invoke["@fcshelieGC"] = function(self, data)
    if sgs.ai_skill_playerchosen.fcshelie(self, self.room:getOtherPlayers(self.player)) then
        return true
    end
    return false
end
sgs.ai_skill_playerchosen.fcshelie = function(self, targets)
    for _, friend in ipairs(self.friends_noself) do
        if self:canDraw(friend, self.player) then
            return friend
        end
    end
    return nil
end
sgs.ai_playerchosen_intention.fcshelie = -40

local fcgongxin_skill = {}
fcgongxin_skill.name = "fcgongxin"
table.insert(sgs.ai_skills, fcgongxin_skill)
fcgongxin_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#fcgongxinCard") then return end
    local fcgongxin_card = parse_action(self,"#fcgongxinCard:.:")
    assert(fcgongxin_card)
    return fcgongxin_card
end

sgs.ai_skill_use_func["#fcgongxinCard"] = function(card, use, self,request)
    self:sort(self.enemies, "handcard")
    self.enemies = sgs.reverse(self.enemies)

    for _, enemy in ipairs(self.enemies) do
        if not enemy:isKongcheng() and source_query(self, "objectiveLevel", enemy) > 0 and source_query(self, "getKnownNum", enemy) ~= enemy:getHandcardNum() then
            use.card = card
            if use.to then
                use.to:append(enemy)
            end
            return
        end
    end
end

sgs.ai_skill_askforag.fcgongxin = function(self, card_ids)
    set_state(self,"fcgongxinchoice",nil)
    local target = scoped_player(self,"fcgongxin")
    if not target or self:isFriend(target) then return -1 end
    local nextAlive = self.player
    repeat
        nextAlive = nextAlive:getNextAlive()
    until nextAlive:faceUp()

    local peach, ex_nihilo, jink, nullification, slash
    local valuable
    for _, id in ipairs(card_ids) do
        local card = known_card(self,id)
        if card:isKindOf("Peach") then peach = id end
        if card:isKindOf("ExNihilo") then ex_nihilo = id end
        if card:isKindOf("Jink") then jink = id end
        if card:isKindOf("Nullification") then nullification = id end
        if card:isKindOf("Slash") then slash = id end
    end
    valuable = peach or ex_nihilo or jink or nullification or slash or card_ids[1]
    local card = known_card(self,valuable)
    if self:isEnemy(target) and target:hasSkill("tuntian") then
        local zhangjiao = self.room:findPlayerBySkillName("guidao")
        if zhangjiao and self:isFriend(zhangjiao, target) and self:canRetrial(zhangjiao, target) and source_query(self, "isValuableCard", card, zhangjiao) then
            set_state(self,"fcgongxinchoice","discard")
        else
            set_state(self,"fcgongxinchoice","put")
        end
        return valuable
    end

    local willUseExNihilo, willRecast
    if self:getCardsNum("ExNihilo") > 0 then
        local ex_nihilo = self:getCard("ExNihilo")
        if ex_nihilo then
            local dummy_use = { isDummy = true }
            self:useTrickCard(ex_nihilo, dummy_use)
            if dummy_use.card then willUseExNihilo = true end
        end
    elseif self:getCardsNum("IronChain") > 0 then
        local iron_chain = self:getCard("IronChain")
        if iron_chain then
            local dummy_use = { to = AIList.new({}), isDummy = true }
            self:useTrickCard(iron_chain, dummy_use)
            if dummy_use.card and dummy_use.to:isEmpty() then willRecast = true end
        end
    end
    if willUseExNihilo or willRecast then
        local card = known_card(self,valuable)
        if card:isKindOf("Peach") then
            set_state(self,"fcgongxinchoice","put")
            return valuable
        end
        if card:isKindOf("TrickCard") or card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage") then
            local dummy_use = { isDummy = true }
            self:useTrickCard(card, dummy_use)
            if dummy_use.card then
                set_state(self,"fcgongxinchoice","put")
                return valuable
            end
        end
        if card:isKindOf("Jink") and self:getCardsNum("Jink") == 0 then
            set_state(self,"fcgongxinchoice","put")
            return valuable
        end
        if card:isKindOf("Nullification") and self:getCardsNum("Nullification") == 0 then
            set_state(self,"fcgongxinchoice","put")
            return valuable
        end
        if card:isKindOf("Slash") and self:slashIsAvailable() then
            local dummy_use = { isDummy = true }
            self:useBasicCard(card, dummy_use)
            if dummy_use.card then
                set_state(self,"fcgongxinchoice","put")
                return valuable
            end
        end
        set_state(self,"fcgongxinchoice","discard")
        return valuable
    end

    local hasLightning, hasIndulgence, hasSupplyShortage
    local tricks = nextAlive:getJudgingArea()
    if not tricks:isEmpty() and not source_query(nextAlive, "containsTrick", "YanxiaoCard") then
        local trick = tricks:at(tricks:length() - 1)
        if source_query(self, "hasTrickEffective", trick, nextAlive) then
            if trick:isKindOf("Lightning") then hasLightning = true
            elseif trick:isKindOf("Indulgence") then hasIndulgence = true
            elseif trick:isKindOf("SupplyShortage") then hasSupplyShortage = true
            end
        end
    end

    if self:isEnemy(nextAlive) and nextAlive:hasSkill("luoshen") and valuable then
        set_state(self,"fcgongxinchoice","put")
        return valuable
    end
    if nextAlive:hasSkill("yinghun") and nextAlive:isWounded() then
        set_state(self,"fcgongxinchoice",self:isFriend(nextAlive) and "put" or "discard")
        return valuable
    end
    if target:hasSkill("hongyan") and hasLightning and self:isEnemy(nextAlive) and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
        for _, id in ipairs(card_ids) do
            local card = printed_card(self,id)
            if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
                set_state(self,"fcgongxinchoice","put")
                return id
            end
        end
    end
    if hasIndulgence and self:isFriend(nextAlive) then
        set_state(self,"fcgongxinchoice","put")
        return valuable
    end
    if hasSupplyShortage and self:isEnemy(nextAlive) and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
        local enemy_null = 0
        for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            if self:isFriend(p) then enemy_null = enemy_null - getCardsNum("Nullification", p) end
            if self:isEnemy(p) then enemy_null = enemy_null + getCardsNum("Nullification", p) end
        end
        enemy_null = enemy_null - self:getCardsNum("Nullification")
        if enemy_null < 0.8 then
            set_state(self,"fcgongxinchoice","put")
            return valuable
        end
    end

    if self:isFriend(nextAlive) and not source_query(self, "willSkipDrawPhase", nextAlive) and not source_query(self, "willSkipPlayPhase", nextAlive)
        and not nextAlive:hasSkill("luoshen")
        and not nextAlive:hasSkill("tuxi") and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
        if (peach and valuable == peach) or (ex_nihilo and valuable == ex_nihilo) then
            set_state(self,"fcgongxinchoice","put")
            return valuable
        end
        if jink and valuable == jink and getCardsNum("Jink", nextAlive) < 1 then
            set_state(self,"fcgongxinchoice","put")
            return valuable
        end
        if nullification and valuable == nullification and getCardsNum("Nullification", nextAlive) < 1 then
            set_state(self,"fcgongxinchoice","put")
            return valuable
        end
        if slash and valuable == slash and self:hasCrossbowEffect(nextAlive) then
            set_state(self,"fcgongxinchoice","put")
            return valuable
        end
    end

    local card = known_card(self,valuable)
    local keep = false
    if card:isKindOf("Slash") or card:isKindOf("Jink")
        or card:isKindOf("EquipCard")
        or card:isKindOf("Disaster") or card:isKindOf("GlobalEffect") or card:isKindOf("Nullification")
        or source_query(target, "isLocked", card) then
        keep = true
    end
    set_state(self,"fcgongxinchoice",(target:objectName() == nextAlive:objectName() and keep) and "put" or "discard")
    return valuable
end

sgs.ai_skill_choice.fcgongxin = function(self, choices)
    return get_state(self,"fcgongxinchoice") or "discard"
end

sgs.ai_use_value.fcgongxinCard = 8.5
sgs.ai_use_priority.fcgongxinCard = 9.5
sgs.ai_card_intention.fcgongxinCard = 80



sgs.ai_ajustdamage_from.fclongming = function(self,from,to,card,nature)
    if card and card:isBlack() and table.contains(source_query(card, "getSkillNames"), "fclongmingBuff") then
        if from:getStrategyFlag("fclongmingANA_Buff") then
            return 2
        else
            return 1
        end
    elseif card and card:isKindOf("Slash") then
        if from:getStrategyFlag("fclongmingANA_Buff") then
            return 1
        end
    end
end
local fclongming_skill = {}
fclongming_skill.name = "fclongming"
table.insert(sgs.ai_skills,fclongming_skill)
fclongming_skill.getTurnUseCard = function(self,inclusive)
    local usable_cards = self:addHandPile()
    local equips = sgs.QList2Table(self.player:getCards("e"))
    for _,e in sgs.list(equips)do
        if e:isKindOf("DefensiveHorse") or e:isKindOf("OffensiveHorse") then
            table.insert(usable_cards,e)
        end
    end
    self:sortByUseValue(usable_cards,true)
    local two_spade_cards = {}
    for _,c in sgs.list(usable_cards)do
        if c:getSuit()==sgs.Card_Spade and #two_spade_cards<2 and not c:isKindOf("Peach") and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>0) then
            table.insert(two_spade_cards,c:getKnownEffectiveId())
        end
    end
    if #two_spade_cards==2 and self:slashIsAvailable() and self:getOverflow()>1 then
        return parse_action(self,("analeptic:fclongmingBuff[%s:%s]=%d+%d"):format("to_be_decided",0,two_spade_cards[1],two_spade_cards[2]))
    end
    for _,c in sgs.list(usable_cards)do
        if c:getSuit()==sgs.Card_Spade and self:slashIsAvailable() and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink")<3) and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>0) then
            return parse_action(self,("analeptic:fclongming[%s:%s]=%d"):format(c:getSuitString(),source_query(c, "getNumberString"),c:getKnownEffectiveId()))
        end
    end
    local two_club_cards = {}
    for _,c in sgs.list(usable_cards)do
        if c:getSuit()==sgs.Card_Club and #two_club_cards<2 and not c:isKindOf("Peach") and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>0) then
            table.insert(two_club_cards,c:getKnownEffectiveId())
        end
    end
    if #two_club_cards==2 and self:slashIsAvailable() and self:getOverflow()>1 then
        return parse_action(self,("thunder_slash:fclongmingBuff[%s:%s]=%d+%d"):format("to_be_decided",0,two_club_cards[1],two_club_cards[2]))
    end
    for _,c in sgs.list(usable_cards)do
        if c:getSuit()==sgs.Card_Club and self:slashIsAvailable() and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink")<3) and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>0) then
            return parse_action(self,("thunder_slash:fclongming[%s:%s]=%d"):format(c:getSuitString(),source_query(c, "getNumberString"),c:getKnownEffectiveId()))
        end
    end
    for _,c in sgs.list(usable_cards)do
        if c:getSuit()==sgs.Card_Heart and self.player:getStrategyMark("Global_PreventPeach")==0 and not c:isKindOf("Peach") then
            return parse_action(self,("peach:fclongming[%s:%s]=%d"):format(c:getSuitString(),source_query(c, "getNumberString"),c:getKnownEffectiveId()))
        end
    end
end

sgs.ai_view_as.fclongming = function(card,player,card_place,class_name)
    if card_place==sgs.Player_PlaceSpecial then return end
    local current = player:getRoom():getCurrent()
    local usable_cards = sgs.QList2Table(player:getCards("he"))
    for _,id in sgs.list(player:getHandPile())do
        table.insert(usable_cards,known_card(self,id))
    end
    local two_diamond_cards = {}
    local two_heart_cards = {}
    for _,c in sgs.list(usable_cards)do
        if c:getSuit()==sgs.Card_Diamond and #two_diamond_cards<2 then
            table.insert(two_diamond_cards,c:getKnownEffectiveId())
        elseif c:getSuit()==sgs.Card_Heart and #two_heart_cards<2 then
            table.insert(two_heart_cards,c:getKnownEffectiveId())
        end
    end

    local suit = card:getSuitString()
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()

    if #two_diamond_cards==2 and current and not current:isNude() and current:getWeapon() and current:getWeapon():isKindOf("Crossbow") then
        return ("jink:fclongmingBuff[%s:%s]=%d+%d"):format("to_be_decided",0,two_diamond_cards[1],two_diamond_cards[2])
    elseif card:getSuit()==sgs.Card_Club then
        return ("jink:fclongming[%s:%s]=%d"):format(suit,number,card_id)
    end

    local dying = player:getRoom():getCurrentDyingPlayer()
    if #two_heart_cards==2 and dying and not dying:hasSkill("fcweijing") then
        return ("peach:fclongmingBuff[%s:%s]=%d+%d"):format("to_be_decided",0,two_heart_cards[1],two_heart_cards[2])
    elseif card:getSuit()==sgs.Card_Heart and player:getStrategyMark("Global_PreventPeach")==0 then
        return ("peach:fclongming[%s:%s]=%d"):format(suit,number,card_id)
    end

    if card:getSuit()==sgs.Card_Club and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length()>0) then
        return ("thunder_slash:fclongming[%s:%s]=%d"):format(suit,number,card_id)
    elseif card:getSuit()==sgs.Card_Spade then
        return ("analeptic:fclongming[%s:%s]=%d"):format(suit,number,card_id)
    end
end

sgs.fclongming_suit_value = source_suit("longhun")

function sgs.ai_cardneed.fclongming(to,card,self)
    if source_query(to, "getCardCount")>3 then return false end
    if to:isNude() then return true end
    return card:getSuit()==sgs.Card_Heart or card:getSuit()==sgs.Card_Spade
end

sgs.ai_need_damaged.fclongming = function(self,attacker,player)
    if player:getHp()>1 and player:hasSkill("fcweijing") then return true end
end


sgs.ai_skill_invoke.fcjieying = function(self, data)
    self:sort(self.enemies)
    self.enemies = sgs.reverse(self.enemies)
    for _, enemy in ipairs(self.enemies) do
        if source_query(self, "objectiveLevel", enemy) > 0 then
            return true
        end
    end
    return false
end

sgs.ai_skill_playerchosen.fcjieying = function(self, targets)
    local targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _, p in ipairs(targets) do
        if self:isEnemy(p) and not p:hasSkill("jieying") and not p:hasSkill("fcjieying") and not p:hasSkill("faen") and not p:hasSkill("qianjie") and not p:hasSkills("chenghao+yinshi") then
            return p
        end
    end
    for _, p in ipairs(targets) do
        return p
    end
end

sgs.ai_playerchosen_intention.fcjieying = 10

sgs.ai_target_revises.fcjieying = function(to,card)
    if card:isKindOf("IronChain")
    then return true end
end



sgs.ai_skill_invoke.fcduorui = function(self,data)
    local target = data:toDamage().to
    return source_query(self, "doDisCard", target, "he")
end

sgs.ai_skill_choice.fcduorui = function(self, choices, data)
    local target = data:toDamage().to
    if source_query(self, "getPriorTurnUseCount") == 0 and self:isEnemy(target) and target:getEquips():length() > 0 then return "CleanUpEquipArea" end
    if not self.player:faceUp() and self:isEnemy(target) and source_query(self, "doDisCard", target, "h") and not target:isKongcheng()  then return "CleanUpHandArea" end
    if not "obtain1card" then return "cancel" end
    return "obtain1card"
end



sgs.ai_skill_use["@@f_feiyang"] = function(self,prompt)
    local disaster,indulgence,supply_shortage = -1,-1,-1
    for _,card in sgs.list(self.player:getJudgingArea())do
        if card:isKindOf("Disaster") then disaster = card:getKnownId() end
        if card:isKindOf("Indulgence") then indulgence = card:getKnownId() end
        if card:isKindOf("SupplyShortage") then supply_shortage = card:getKnownId() end
    end

    local handcards = {}
    for _,id in sgs.list(self.player:handCards())do
        if source_query(self.player, "canDiscard", self.player, id) then
            table.insert(handcards,known_card(self,id))
        end
    end
    if #handcards<2 then return "." end
    self:sortByKeepValue(handcards)

    local discard = {}
    table.insert(discard,handcards[1]:getId())
    table.insert(discard,handcards[2]:getId())
    if #discard == 2 then

    return "#f_feiyang:"..table.concat(discard,"+")..":"
    end

    return "."
end



local f_gengzhong_skill = {}
f_gengzhong_skill.name = "f_gengzhong"
table.insert(sgs.ai_skills, f_gengzhong_skill)
f_gengzhong_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#f_gengzhongCard") or (self:getCardsNum("BasicCard") == 0 and self:getCardsNum("Nullification") == 0) or self:getCardsNum("Slash") <= 1 or self.player:getHandcardNum() - self.player:getHp() < 2 or self.player:isNude() then return end
    local card_id
    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _, acard in ipairs(cards) do
        if acard:isKindOf("BasicCard") or acard:isKindOf("Nullification") then
            card_id = acard:getKnownEffectiveId()
            break
        end
    end
    if not card_id then
        return nil
    else
        return parse_action(self,"#f_gengzhongCard:"..card_id..":")
    end
end

sgs.ai_skill_use_func["#f_gengzhongCard"] = function(card, use, self,request)
    if not self.player:getStrategyHasUsed("#f_gengzhongCard") and not self.player:isNude() then
        use.card = card
        return
    end
end

sgs.ai_use_value.f_gengzhongCard = 8.5
sgs.ai_use_priority.f_gengzhongCard = 9.5
sgs.ai_card_intention.f_gengzhongCard = -80

sgs.ai_skill_invoke["@f_gengzhongNTGet"] = function(self, data)
    if self.player:getPile("NT"):length() == 0 then return false end
    if self.player:getHp() <= 1 then return true end
    if self.player:getHandcardNum() <= 2 or self.player:getPile("NT"):length() >= 3 then return true end
    return false
end

local f_gongkang_skill = {}
f_gongkang_skill.name = "f_gongkang"
table.insert(sgs.ai_skills, f_gongkang_skill)
f_gongkang_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@f_gongkang") == 0 then return end
    return parse_action(self,"#f_gongkangCard:.:")
end

sgs.ai_skill_use_func["#f_gongkangCard"] = function(card, use, self,request)
    if self.player:getStrategyMark("@f_gongkang") > 0 then
        self:sort(self.friends_noself)
        for _, friend in ipairs(self.friends_noself) do
            if self:isFriend(friend) then
                use.card = card
                if use.to then use.to:append(friend) end
                return
            end
        end
        return
    end
end

sgs.ai_use_value.f_gongkangCard = 8.5
sgs.ai_use_priority.f_gongkangCard = 9.5
sgs.ai_card_intention.f_gongkangCard = -80

sgs.ai_skill_invoke.f_tongxin = true

sgs.ai_skill_choice.f_tongxin = function(self, choices, data)
    if self.player:getHp() <= 1 and not self.player:isKongcheng() then return "2" end
    return "1"
end



local sp_taoyuanyi_skill = {}
sp_taoyuanyi_skill.name = "sp_taoyuanyi"
table.insert(sgs.ai_skills, sp_taoyuanyi_skill)
sp_taoyuanyi_skill.getTurnUseCard = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    local card
    self:sortByUseValue(cards, true)

    for _, acard in ipairs(cards) do
        if acard:getSuit() == sgs.Card_Heart then
            card = acard
            break
        end
    end
    if card and self:willUseGodSalvation(card) then
        local card_str = string.format("god_salvation:sp_taoyuanyi[%s:%s]=.", sgs.Card_NoSuit, 0)
        local god_salvation = parse_action(self,card_str)
        mutate(self,god_salvation,"add",card)
        assert(god_salvation)
        return god_salvation
    end
end

sgs.ai_card_priority.sp_taoyuanyi = function(self,card,v)
    if card:isKindOf("GodSalvation")
    then return 3 end
end

local sp_weizhen_skill = {}
sp_weizhen_skill.name = "sp_weizhen"
table.insert(sgs.ai_skills, sp_weizhen_skill)
sp_weizhen_skill.getTurnUseCard = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    local card
    self:sortByUseValue(cards, true)
    local useAll = false
    self:sort(self.enemies,"defense")
    for _,enemy in ipairs(self.enemies)do
        if enemy:getHp()<2 and not source_query(enemy, "hasArmorEffect", "EightDiagram")
        and source_query(self.player, "distanceTo", enemy)<=source_query(self.player, "getAttackRange") and self:isWeak(enemy)
        and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
        then useAll = true break end
    end
    if self.player:getStrategyMark("sp_weizhen_used") >= 3 then
        if self.player:getMaxHp() <= 3 then
            return
        end
        if not useAll then
            return
        end
    end


    for _, acard in ipairs(cards) do
        if acard:isBlack() and not acard:isKindOf("Peach") and (self:getDynamicUsePriority(acard) < sgs.ai_use_value.Drowning or self:getOverflow() > 0) then
            if acard:isKindOf("Slash") and self:getCardsNum("Slash") == 1 then
                local keep
                local dummy_use = { isDummy = true , to = AIList.new({}) }
                self:useBasicCard(acard, dummy_use)
                if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
                    for _, p in sgs.qlist(dummy_use.to) do
                        if p:getHp() <= 1 then keep = true break end
                    end
                    if dummy_use.to:length() > 1 then keep = true end
                end
                if keep then self:setPriorityValue("Slash",self:getPriorityValue("Drowning") + 0.1,"fcDIY")
                else
                    self:setPriorityValue("Slash",2.6,"fcDIY")
                    card = acard
                    break
                end
            else
                card = acard
                break
            end
        end
    end
    if not card then return nil end
    if self.player:hasSkill("sp_qianlixing") then
        self:setPriorityValue("Drowning",2.4,"fcDIY")
    end

    local suit = card:getSuitString()
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    local card_str = ("drowning:sp_weizhen[%s:%s]=%d"):format(suit, number, card_id)
    local skillcard = parse_action(self,card_str)
    assert(skillcard)
    return skillcard
end
sgs.ai_event_callback[sgs.PreCardUsed].sp_weizhen = function(self,player,data)
    local use = data:toCardUse()
    if use.card and table.contains(source_query(use.card, "getSkillNames"), "sp_weizhen") then
        self:setPriorityValue("Drowning",7,"fcDIY")
    end
end

sgs.ai_cardneed.sp_weizhen = function(to, card, self)
    return card:isBlack() and (card:isKindOf("BasicCard") or card:isKindOf("TrickCard"))
end

sgs.ai_skill_use_func.sp_weizhen = function(card, use, self)
    if self.player:getStrategyMark("sp_weizhen_used") < 3 then
        use.card = card
        return
    end
end

sgs.ai_view_as.sp_qianlixing = function(card,player,card_place)
    local suit = card:getSuitString()
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    if card_place~=sgs.Player_PlaceSpecial and card:isRed() and not card:isKindOf("Peach") and not card:getStrategyFlag("using") then
        return ("slash:sp_qianlixing[%s:%s]=%d"):format(suit,number,card_id)
    end
end

local sp_qianlixing_skill = {}
sp_qianlixing_skill.name = "sp_qianlixing"
table.insert(sgs.ai_skills,sp_qianlixing_skill)
sp_qianlixing_skill.getTurnUseCard = function(self,inclusive)
    local cards = self:addHandPile("he")
    cards = self:sortByUseValue(cards,true)
    local red_card = {}
    local useAll = false
    self:sort(self.enemies,"defense")
    for _,enemy in ipairs(self.enemies)do
        if enemy:getHp()<2 and not source_query(enemy, "hasArmorEffect", "EightDiagram")
        and source_query(self.player, "distanceTo", enemy)<=source_query(self.player, "getAttackRange") and self:isWeak(enemy)
        and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
        then useAll = true break end
    end
    for _,card in ipairs(cards)do
        if card:isRed() and not card:isKindOf("TrickCard")
        and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
        and (source_query(self, "getUseValue", card)<sgs.ai_use_value.Slash or inclusive or source_query(preview(self), "getTargetModResidue", self.player)>0)
        then table.insert(red_card,card) end
    end

    for _,card in ipairs(red_card)do
        local slash = preview(self,"slash")
        mutate(self,slash,"add",card)
        mutate(self,slash,"skill","sp_qianlixing")
        if source_query(slash, "isAvailable", self.player)
        then return slash end
    end
end

function sgs.ai_cardneed.sp_qianlixing(to,card)
    return to:getHandcardNum()<3 and card:isRed()
end
sgs.ai_use_revises.sp_qianlixing = function(self,card,use)
    if card:isKindOf("Slash") and table.contains(source_query(card, "getSkillNames"), "sp_qianlixing") and self.player:getPhase() == sgs.Player_Play then
        self:setStrategyCardFlag(card,"Qinggang",true)
    end
end

sgs.ai_skill_use["@@sp_xiansheng"] = function(self, prompt)
    local targets = {}
    self:sort(self.friends_noself, "hp")
    for _, friend in ipairs(self.friends_noself) do
        if friend:getHp() < getBestHp(friend) then
            table.insert(targets, friend:objectName())
            if #targets >= 3 then break end
        end
    end
    if #targets > 0 then
        return "#sp_xianshengCard:.:->" .. table.concat(targets, "+")
    end
    return "."
end
sgs.ai_use_revises.sp_guoguanzhanjiang = function(self,card,use)
    if card:isKindOf("Drowning") then
        for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
            if p:getStrategyMark("&LeVeL") > 0 and CanToCard(card,self.player,p) and source_query(self, "damageIsEffective", p, card, self.player) then
                use.card = card
                local targets = AIList.new({})
                targets:append(p)
                use.to = targets
                return
            end
        end
    end
end



local sp_guamu_skill = {}
sp_guamu_skill.name = "sp_guamu"
table.insert(sgs.ai_skills, sp_guamu_skill)
sp_guamu_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#sp_guamuCard") then return end
    return parse_action(self,"#sp_guamuCard:.:")
end

sgs.ai_skill_use_func["#sp_guamuCard"] = function(card, use, self,request)
    if not self.player:getStrategyHasUsed("#sp_guamuCard") then
        use.card = card
        if use.to then use.to:append(self.player) end
        return
    end
end

sgs.ai_skill_choice["sp_guamuONE"] = function(self, choices, data)
    return "sp_guamuONEthrow"
end

sgs.ai_use_value.sp_guamuCard = 8.5
sgs.ai_use_priority.sp_guamuCard = 9.5
sgs.ai_card_intention.sp_guamuCard = -80

local sp_dujiang_skill = {}
sp_dujiang_skill.name = "sp_dujiang"
table.insert(sgs.ai_skills,sp_dujiang_skill)
sp_dujiang_skill.getTurnUseCard = function(self,inclusive)
    return parse_action(self,"#sp_dujiangCard:.:")
end

sgs.ai_skill_use_func["#sp_dujiangCard"] = function(card,use,self,request)
    local slashes = self:getCards("Slash")
    if #slashes<1 then return end
    self:sort(self.enemies,"hp")
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards, true)

    for _,enemy in sgs.list(self.enemies)do
        for _,slash in sgs.list(slashes)do
            local d = use_card(self,slash)
            if d.card and d.to:contains(enemy) then
                for _, c in ipairs(cards) do
                    if c:isKindOf("EquipCard") then
                        use.card = parse_action(self,"#sp_dujiangCard:" .. c:getKnownEffectiveId() .. ":")
                        use.to:append(enemy)
                        return
                    end
                end
            end
        end
    end
end

sgs.ai_use_priority.sp_dujiangCard = sgs.ai_use_priority.Slash+0.5
sgs.ai_use_value.sp_dujiangCard = 3



local sp_chibi_skill = {}
sp_chibi_skill.name = "sp_chibi"
table.insert(sgs.ai_skills, sp_chibi_skill)
sp_chibi_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@sp_chibi") == 0 then return end
    return parse_action(self,"#sp_chibiCard:.:")
end

sgs.ai_skill_use_func["#sp_chibiCard"] = function(card, use, self,request)
    local good = 0
    for _, p in ipairs(sgs.QList2Table(self.room:getOtherPlayers(self.player))) do
        if self:isEnemy(p) and source_query(self, "damageIsEffective", p, sgs.DamageStruct_Fire) and not source_query(self, "cantbeHurt", p) and not source_query(self, "needToLoseHp", p, self.player, nil) then
            good = good + 1
            if self:isWeak(p) then
                good = good + 2
            end
            if not self:cantDamageMore(p, self.player) and self.player:hasSkill("sp_huoshen") and source_query(self.player, "inMyAttackRange", p) then
                good = good + 1
            end
        end
        if self:isFriend(p) and source_query(self, "damageIsEffective", p, sgs.DamageStruct_Fire) and not source_query(self, "needToLoseHp", p, self.player, nil) then
            good = good - 1
            if self:isWeak(p) then
                good = good - 2
            end
            if not self:cantDamageMore(p, self.player) and self.player:hasSkill("sp_huoshen") and source_query(self.player, "inMyAttackRange", p) then
                good = good - 1
            end
        end
    end
    if not self.player:hasSkill("sp_shenzi") and self.player:hasSkill("sp_qiangu") then good = good + 3 end
    if good > 0 then
        use.card = card
        return
    end
end

sgs.ai_use_value.sp_chibiCard = 8.5
sgs.ai_use_priority.sp_chibiCard = 9.5
sgs.ai_card_intention.sp_chibiCard = 80

sgs.ai_ajustdamage_from.sp_huoshen         = function(self, from, to, card, nature)
    if source_query(from, "inMyAttackRange", to) and nature == "F" then
        return 1
    end
end
sgs.ai_skill_invoke.sp_qinmo = function(self, data)
    if source_query(self, "getPriorTurnUseCount")<2 and self:getOverflow() <= 0 then
        return sgs.ai_skill_choice.sp_qinmo(self, "sp_qinmoloseHp+sp_qinmoaddHp") ~= "cancel"
    end
    return false
end


sgs.ai_skill_choice.sp_qinmo = function(self, choices, data)
    local items = choices:split("+")
    if table.contains(items, "sp_qinmoaddHp") then
        local arr1, arr2 = self:getWoundedFriend(false, true)
        local target = nil

        if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < getBestHp(arr1[1]) then target = arr1[1] end
        if target then
            set_state(self,"sp_qinmo",target)
            return "sp_qinmoaddHp"
        end
    end
    if table.contains(items, "sp_qinmoloseHp") then

        local target = nil
        self:sort(self.enemies, "hp")
        for _, enemy in ipairs(self.enemies) do
            if not hasZhaxiangEffect(enemy) then
                target = enemy
                break
            end
        end

        if target then
            set_state(self,"sp_qinmo",target)
            return "sp_qinmoloseHp"
        end
    end
    return "cancel"
end
sgs.ai_skill_playerchosen.sp_qinmo = function(self, targets)
    if get_state(self,"sp_qinmo") then return get_state(self,"sp_qinmo") end
    if self.player:getStrategyFlag("sp_qinmoloseHp") then
        self:sort(self.enemies, "hp")
        for _, enemy in ipairs(self.enemies) do
            if not hasZhaxiangEffect(enemy) then
                return enemy
            end
        end
    end
    local arr1, arr2 = self:getWoundedFriend(false, true)
    if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < getBestHp(arr1[1]) then return arr1[1] end
    return targets[1]
end

sgs.ai_skill_choice.sp_shenzi = function(self, choices, data)
    local target = sgs.ai_skill_playerchosen.sp_shenzi(self, self.room:getOtherPlayers(self.player))
    if target ~= nil and source_query(self.player, "inMyAttackRange", target) and not self:cantDamageMore(self.player,target) and self.player:hasSkill("sp_huoshen") then return "sp_shenzi0card" end
    if (self.player:isKongcheng() or self.player:getHp() - self.player:getHandcardNum() > 1) and self.player:getHp() > 1 then return "sp_shenzi4cards" end
    if self:getOverflow() > 2 then return "sp_shenzi1card" end
    return "sp_shenzi3cards"
end
sgs.ai_skill_playerchosen.sp_shenzi = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
        if self:isEnemy(p) and source_query(self, "damageIsEffective", p, sgs.DamageStruct_Fire) and not source_query(self, "cantbeHurt", p) and self:isWeak(p) and source_query(self.player, "inMyAttackRange", p) then
            return p
        end
    end
    for _, p in ipairs(targets) do
        if self:isEnemy(p) and source_query(self, "damageIsEffective", p, sgs.DamageStruct_Fire) and not source_query(self, "cantbeHurt", p) and self:isWeak(p) then
            return p
        end
    end
    return nil
end



sgs.ai_skill_invoke.sp_zhengshen = true
sgs.ai_skill_invoke["@sp_zhengshenGC"] = function(self, data)
    if sgs.ai_skill_use["@@sp_zhengshenGC!"] == "." then return false end
    return true
end
sgs.ai_skill_use["@@sp_zhengshenGC!"] = function(self,prompt)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local targets = self.room:getOtherPlayers(self.player)
    local c,to = self:getCardNeedPlayer(cards, false, targets)
    if c and to then return "#sp_zhengshenGCCard:"..c:getKnownEffectiveId()..":->"..to:objectName() end
    for _, friend in ipairs(self.friends_noself) do
        for _,h in sgs.list(self.player:getHandcards())do
            if self:willUse(self.player, h) and source_query(h, "isAvailable", self.player) then continue end
            return "#sp_zhengshenGCCard:"..h:getKnownEffectiveId()..":->"..friend:objectName()
        end
    end

    return "."
end
function sgs.ai_cardneed.sp_zhishen(to,card)
    return source_query(card, "isNDTrick")
end
sgs.ai_card_priority.sp_zhishen = function(self,card,v)
    if self.useValue
    and source_query(card, "isNDTrick")
    then v = v+3 end
end

sgs.ai_ajustdamage_to["@sp_crazywind"] = function(self,from,to,card,nature)
    if nature=="F"
    then return 1 end
end
sgs.ai_ajustdamage_to["@sp_fog"] = function(self,from,to,card,nature)
    if nature~="T"
    then return -99 end
end

sgs.ai_skill_invoke.sp_qitian = true

sgs.ai_skill_choice.sp_qitian = function(self, choices, data)
    if self.player:getStrategyMark("&ShenZhi") < 4 then return "1" end
    return "4"
end

sgs.ai_skill_playerchosen.sp_qitian = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
        if self:isEnemy(p) and (((self.player:getStrategyFlag("sp_qitian_Club") and source_query(self, "damageIsEffective", p, sgs.DamageStruct_Fire))) or (source_query(self, "damageIsEffective", p, sgs.DamageStruct_Thunder) and source_query(self, "doDisCard", p, "he") )) and not source_query(self, "cantbeHurt", p) then
            return p
        end
    end
    for _, p in ipairs(targets) do
        if self:isEnemy(p) and source_query(self, "doDisCard", p, "he") and not source_query(self, "cantbeHurt", p) then
            return p
        end
    end
    return nil
end

local sp_guimen_skill = {}
sp_guimen_skill.name = "sp_guimen"
table.insert(sgs.ai_skills, sp_guimen_skill)
sp_guimen_skill.getTurnUseCard = function(self)
    return parse_action(self,"#sp_guimenCard:.:")
end

sgs.ai_skill_use_func["#sp_guimenCard"] = function(card, use, self,request)
    local good = 0
    for _, p in ipairs(sgs.QList2Table(self.room:getOtherPlayers(self.player))) do
        if self:isEnemy(p) and source_query(self, "damageIsEffective", p, sgs.DamageStruct_Thunder) and not source_query(self, "cantbeHurt", p) and not source_query(self, "needToLoseHp", p, self.player, nil) then
            good = good + 1
            if self:isWeak(p) then
                good = good + 2
            end
        end
        if self:isFriend(p) and source_query(self, "damageIsEffective", p, sgs.DamageStruct_Thunder) and not source_query(self, "needToLoseHp", p, self.player, nil) then
            good = good - 1
            if self:isWeak(p) then
                good = good - 2
            end
        end
    end
    if good > 0 then
        use.card = card
        return
    end
end

sgs.ai_use_value.sp_guimenCard = 8.5
sgs.ai_use_priority.sp_guimenCard = 9.5



sgs.ai_skill_invoke.sp_zhujiu = true

sgs.ai_skill_playerchosen.sp_zhujiu = function(self, targets)
    local max_card = self:getMaxCard()
    local max_point = max_card:getNumber()
    local targets = sgs.QList2Table(targets)
    self:sort(targets, "handcard")

    for _,enemy in sgs.list(targets)do
        if self:isEnemy(enemy) and source_query(self.player, "canPindian", enemy) then
            local enemy_max_card = self:getMaxCard(enemy)
            local allknown = 0
            if source_query(self, "getKnownNum", enemy)==enemy:getHandcardNum() then
                allknown = allknown+1
            end
            if (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown>0)
                or (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown<1 and max_point>10)
                or (not enemy_max_card and max_point>10) then
                return enemy
            end
        end
    end
    for _, p in ipairs(targets) do
        if self:isEnemy(p) and source_query(self.player, "canPindian", p) then return p end
    end
end
ai_audited_aliases.register{id="ai_cardneed.sp_zhujiu",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"sp_zhujiu"},canonical_registry="ai_cardneed",canonical_path={"bignumber"}}

local sp_zhujiu_skill = {}
sp_zhujiu_skill.name = "sp_zhujiu"
table.insert(sgs.ai_skills, sp_zhujiu_skill)
sp_zhujiu_skill.getTurnUseCard = function(self)
    return parse_action(self,"#sp_zhujiuCard:.:")
end

sgs.ai_skill_use_func["#sp_zhujiuCard"] = function(card, use, self,request)
    self:sort(self.enemies)
    self.enemies = sgs.reverse(self.enemies)
    local max_card = self:getMaxCard()
    local max_point = max_card:getNumber()
    self:sort(self.enemies, "handcard")

    for _, enemy in ipairs(self.enemies) do
        if source_query(self.player, "canPindian", enemy) and enemy:getStrategyMark("&qingmei_zhujiu-PlayClear") > 0 then
            local enemy_max_card = self:getMaxCard(enemy)
            local allknown = 0
            if source_query(self, "getKnownNum", enemy)==enemy:getHandcardNum() then
                allknown = allknown+1
            end
            if (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown>0)
                or (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown<1 and max_point>10)
                or (not enemy_max_card and max_point>10) then
                use.card = card
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
    if self.player:hasSkill("sp_gexing") and self.player:getStrategyMark("@duangexing") > 0 and self.player:getStrategyMark("sp_zhujiuFQC") < 10 then
        for _, enemy in ipairs(self.enemies) do
            if source_query(self, "objectiveLevel", enemy) > 0 and source_query(self.player, "canPindian", enemy) and enemy:getStrategyMark("&qingmei_zhujiu-PlayClear") > 0 then
                use.card = card
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end

sgs.ai_use_value.sp_zhujiuCard = 8.5
sgs.ai_use_priority.sp_zhujiuCard = 9.5
sgs.ai_card_intention.sp_zhujiuCard = 80

sgs.ai_skill_invoke["@sp_zhujiugetPindianCards"] = true

sgs.ai_skill_invoke.sp_gexing = true

local sp_tianxia_skill = {}
sp_tianxia_skill.name = "sp_tianxia"
table.insert(sgs.ai_skills, sp_tianxia_skill)
sp_tianxia_skill.getTurnUseCard = function(self)
    if not self.player:getStrategyHasUsed("#sp_tianxiaCard") then
        return parse_action(self,"#sp_tianxiaCard:.:")
    end
end

sgs.ai_skill_use_func["#sp_tianxiaCard"] = function(card, use, self,request)
    use.card = card
    return
end

sgs.ai_use_value["sp_tianxiaCard"] = sgs.ai_use_value.ExNihilo - 0.1
sgs.ai_use_priority["sp_tianxiaCard"] = sgs.ai_use_priority.ExNihilo - 0.1

sgs.ai_skill_choice["sp_tianxia"] = function(self, choices, data)
    if self.player:getMaxHp() >= 4 then return "3" end
    if self.player:getLostHp() >= 2 and self:isWeak() then return "3" end
    if self.player:getHp() + source_query(self, "getAllPeachNum") > 0 then return "1" end
    return "2"
end
sgs.ai_skill_choice["sp_tianxiaOther"] = function(self, choices, data)
    local items = choices:split("+")
    local current = self.room:getCurrent()
    if source_query(self, "needToLoseHp", self.player, current) then return "2" end
    if table.contains(items, "1") then return "1" end
    return "2"
end
sgs.ai_skill_choice["sp_tianxiaSelf"] = function(self, choices, data)
    local items = choices:split("+")
    local target = data:toPlayer()
    if source_query(self, "damageIsEffective", target, sgs.DamageStruct_Normal) and not source_query(self, "cantbeHurt", target) and source_query(self, "canDamage", target, self.player) then return "2" end
    if table.contains(items, "1") then return "1" end
    return "2"
end


sgs.ai_skill_invoke["sp_wuji"] = true

sgs.ai_skill_choice["sp_wuji"] = function(self, choices, data)
    if self.player:getMaxHp() <= 3 then return "cancel" end
    if self.player:getHandcardNum() <= 3 then return "1" end
    return "2"
end


local sp_feijiang_skill = {}
sp_feijiang_skill.name = "sp_feijiang"
table.insert(sgs.ai_skills, sp_feijiang_skill)
sp_feijiang_skill.getTurnUseCard = function(self)
    return parse_action(self,"#sp_feijiangCard:.:")
end

sgs.ai_skill_use_func["#sp_feijiangCard"] = function(card, use, self,request)
    self:sort(self.enemies)
    self.enemies = sgs.reverse(self.enemies)
    local max_card = self:getMaxCard()
    local max_point = max_card:getNumber()
    self:sort(self.enemies, "handcard")
    local slash = clone_preview(self,"slash")

    for _, enemy in ipairs(self.enemies) do
        if source_query(self.player, "canSlash", enemy, false) and not source_query(self, "slashProhibit", slash, enemy) and source_query(self, "getDefenseSlash", enemy) <= 2
            and source_query(self, "slashIsEffective", slash, enemy) and source_query(self, "isGoodTarget", enemy, self.enemies, slash)
            and enemy:objectName() ~= self.player:objectName() and source_query(self.player, "canPindian", enemy) then
            local enemy_max_card = self:getMaxCard(enemy)
            local allknown = 0
            if source_query(self, "getKnownNum", enemy)==enemy:getHandcardNum() then
                allknown = allknown+1
            end
            if (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown>0)
                or (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown<1 and max_point>10)
                or (not enemy_max_card and max_point>10) then
                use.card = card
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end

sgs.ai_use_value.sp_feijiangCard = 8.5
sgs.ai_use_priority.sp_feijiangCard = 2.4
sgs.ai_card_intention.sp_feijiangCard = 80

local sp_mengguan_skill = {}
sp_mengguan_skill.name = "sp_mengguan"
table.insert(sgs.ai_skills, sp_mengguan_skill)
sp_mengguan_skill.getTurnUseCard = function(self)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    local card
    self:sortByUseValue(cards, true)
    for _, c in ipairs(cards) do
        if c:isKindOf("Weapon") then
            card = c
            break
        end
    end
    if not card then return nil end
    local suit = card:getSuitString()
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    local card_str = ("duel:sp_mengguan[%s:%s]=%d"):format(suit, number, card_id)
    local skillcard = parse_action(self,card_str)
    assert(skillcard)
    return skillcard
end

sgs.ai_skill_invoke.sp_duyong = function(self, data)
    if self.player:isNude() then return false end
    local target = data:toDamage().to
    return not self:isFriend(target) and not self:cantDamageMore(target, self.player) and source_query(self, "damageIsEffective", target, data:toDamage().card, self.player)
end

sgs.ai_ajustdamage_from.sp_duyong = function(self,from,to,card,nature)
    if card and (card:isKindOf("Slash") or card:isKindOf("Duel")) and not beFriend(to,from) and source_query(from, "canDiscard", from, "he")
    then return 1 end
end


local sp_hengsaoqianjun_skill = {}
sp_hengsaoqianjun_skill.name = "sp_hengsaoqianjun"
table.insert(sgs.ai_skills,sp_hengsaoqianjun_skill)
sp_hengsaoqianjun_skill.getTurnUseCard = function(self)
    local newcards = {}
    local cards = self:addHandPile()
    local color = {}
    cards = self:sortByUseValue(cards,nil,true)
    for _,card in sgs.list(cards)do
        if isCard("Peach",card,self.player)
        or isCard("ExNihilo",card,self.player) and self.player:getPhase()<=sgs.Player_Play
        then continue end
        if table.contains(color, card:getColorString()) then continue end
        table.insert(newcards,card)
        table.insert(color,card:getColorString())
    end
    if #newcards<2
    or #cards<self.player:getHp() and self.player:getHp()<5
    and not self:needKongcheng() then return end
    local slashs = {}
    -- addFunction.lua1545: this reached overload appends to a Lua table.
    local newcards2 = {}
    for _,entry in sgs.list(newcards) do table.insert(newcards2,entry) end
    for _,c1 in sgs.list(newcards)do
        if #slashs>#newcards/2 or #slashs>3 then break end
        table.removeOne(newcards2,c1)
        for _,c2 in sgs.list(newcards2)do
            local dc = parse_action(self,"slash:sp_hengsaoqianjun[no_suit:0]="..c1:getKnownId().."+"..c2:getKnownId())
            if source_query(dc, "isAvailable", self.player) then table.insert(slashs,dc) end
        end
    end
    return #slashs>0 and slashs
end

sgs.ai_ajustdamage_from.sp_hengsaoqianjun = function(self,from,to,card,nature)
    if card and card:isKindOf("Slash") and from:getStrategyFlag("sp_hengsaoqianjunDMGbuff") and table.contains(source_query(card, "getSkillNames"), "sp_hengsaoqianjun")
    then return 1 end
end

sgs.ai_skill_playerschosen.sp_hengsaoqianjun = function(self, targets, max, min)
    targets = sgs.QList2Table(targets)
    local tos = {}
    local use = scoped_struct(self,"sp_hengsaoqianjun","use")
    local dummy_use = scoped_use_card(self,"sp_hengsaoqianjun",use.card, dummy(true, 99, use.to))
    if not dummy_use.to:isEmpty() then
        for _, p in sgs.qlist(dummy_use.to) do
            if table.contains(targets,p) and #tos<max then
                table.insert(tos,p)
            end
        end
    end
    return tos
end
sgs.ai_skill_choice["sp_hengsaoqianjun"] = function(self, choices, data)
    local use = scoped_struct(self,"sp_hengsaoqianjun","use")
    local extra_targets = scoped_extra_targets(self,"sp_hengsaoqianjun_extra_targets")
    if sgs.ai_skill_playerschosen.sp_hengsaoqianjun(self, extra_targets, 2, 0) ~= {} then
        if self.player:getMaxHp() >= 4 then return "3" end
        return "2"
    end
    return "1"
end
sgs.ai_card_priority.sp_hengsaoqianjun = function(self,card)
    if table.contains(source_query(card, "getSkillNames"), "sp_hengsaoqianjun")
    then
        if self.useValue
        then return 1 end
        return -1
    end
end



sgs.ai_guhuo_card.sp_qijin = function(self,toname,class_name)
    if self:getCardsNum(class_name)<1 and self.player:getStrategyMark("&canuse_qijin") > 0 and self.player:getMaxHp() > 1
    then return "#sp_qijinCard:.:"..toname end
end


local sp_lingyun_skill = {}
sp_lingyun_skill.name = "sp_lingyun"
table.insert(sgs.ai_skills, sp_lingyun_skill)
sp_lingyun_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#sp_lingyunCard") then return end
    if self.player:getStrategyMark("@sp_lingyunAI") == 1 then return end
    local card = parse_action(self,"#sp_lingyunCard:.:")


    return card
end

sgs.ai_skill_use_func["#sp_lingyunCard"] = function(card, use, self,request)
        use.card = card
end
sgs.ai_use_priority["sp_lingyunCard"] = sgs.ai_use_priority.Slash + 5.1

sgs.ai_skill_choice["sp_gudan"] = function(self, choices, data)
    local items = choices:split("+")
    if table.contains(items, "2and0") and self.player:getLostHp() > 2 then
        return "2and0"
    end
    return "1and0"
end

local sp_danqi_skill={}
sp_danqi_skill.name="sp_danqi"
table.insert(sgs.ai_skills,sp_danqi_skill)
sp_danqi_skill.getTurnUseCard=function(self)
    local cards = self:addHandPile()
    self:sortByUseValue(cards,true)
    if self.player:getStrategyMark("&canuse_danqi") > 0 then
        local usable_cards = sgs.QList2Table(self.player:getCards("he"))
        for _,id in sgs.list(self.player:getHandPile())do
            table.insert(usable_cards,known_card(self,id))
        end
        local two_analeptic_cards = {}
        local two_peach_cards = {}
        for _,c in sgs.list(usable_cards)do
            if c:isKindOf("Analeptic") and #two_analeptic_cards<2 then
                table.insert(two_analeptic_cards,c:getKnownEffectiveId())
            elseif c:isKindOf("Peach") and #two_peach_cards<2 then
                table.insert(two_peach_cards,c:getKnownEffectiveId())
            end
        end
        if #two_analeptic_cards==2 and self:slashIsAvailable() and self:getOverflow()>1 then
            return parse_action(self,("slash:sp_danqi_buffs[%s:%s]=%d+%d"):format("to_be_decided",0,two_analeptic_cards[1],two_analeptic_cards[2]))
        end
        if #two_peach_cards==2 and sgs.Analeptic_IsAvailable(self.player) and self:getOverflow()>1 then
            return parse_action(self,("analeptic:sp_danqi_buffs[%s:%s]=%d+%d"):format("to_be_decided",0,two_peach_cards[1],two_peach_cards[2]))
        end

    end

    if (self.player:getStrategyMark("&canuse_danqi") > 0 or self.player:getLostHp() > 0) then
        for _,c in ipairs(cards)do
            if c:isKindOf("Analeptic") then
                return parse_action(self,("slash:sp_danqi[%s:%s]=%d"):format(c:getSuitString(),source_query(c, "getNumberString"),c:getKnownEffectiveId()))
            end
        end
        for _,c in ipairs(cards)do
            if c:isKindOf("Peach") then
                return sgs.Analeptic_IsAvailable(self.player) and parse_action(self,("analeptic:sp_danqi[%s:%s]=%d"):format(c:getSuitString(),source_query(c, "getNumberString"),c:getKnownEffectiveId()))
            end
        end
        for _,c in ipairs(cards)do
            if c:isKindOf("Jink") and (self.player:getLostHp() > 1 or self.player:getStrategyMark("&canuse_danqi") > 0) then
                return parse_action(self,("peach:sp_danqi[%s:%s]=%d"):format(c:getSuitString(),source_query(c, "getNumberString"),c:getKnownEffectiveId()))
            end
        end
    end
end

sgs.ai_view_as.sp_danqi = function(card,player,card_place)
    local suit = card:getSuitString()
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    if card_place==sgs.Player_PlaceHand and (player:getStrategyMark("&canuse_danqi") > 0 or player:getLostHp() > 0) then
        if card:isKindOf("Jink") then
            return ("peach:sp_danqi[%s:%s]=%d"):format(suit,number,card_id)
        elseif card:isKindOf("Slash") then
            return ("jink:sp_danqi[%s:%s]=%d"):format(suit,number,card_id)
        elseif card:isKindOf("Peach") then
            return ("analeptic:sp_danqi[%s:%s]=%d"):format(suit,number,card_id)
        elseif card:isKindOf("Analeptic") and (player:getStrategyMark("&canuse_danqi") > 0 or player:getLostHp() > 0) then
            return ("slash:sp_danqi[%s:%s]=%d"):format(suit,number,card_id)
        end
    end
end

sgs.sp_danqi_keep_value = sgs.longdan_keep_value

sgs.ai_ajustdamage_from.sp_danqi = function(self,from,to,slash,nature)
    if slash and slash:isKindOf("Slash") then
        local x = 0
        if slash:getStrategyFlag("drank") then
            x = x + from:getStrategyMark("sp_danqi_AnalepticBuff")
        end
        if slash:getStrategyFlag("sp_danqi") then
            x = x + from:getStrategyMark("sp_danqi_SlashBuff")
        end
        return x
    end
end
sgs.ai_use_revises.sp_danqi = function(self,card,use)
    if card:isKindOf("Slash") and (table.contains(source_query(card, "getSkillNames"), "sp_danqi") or table.contains(source_query(card, "getSkillNames"), "sp_danqi_buffs")) then
        self:setStrategyCardFlag(card,"Qinggang",true)
    end
end

sgs.ai_skill_choice["sp_danqi"] = function(self, choices, data)
    local items = choices:split("+")
    local use = data:toCardUse()
    local buff = true
    if table.contains(source_query(use.card, "getSkillNames"), "sp_danqi") then
        buff = false
    end
    if use.card:isKindOf("Slash") then
        for _, p in sgs.qlist(use.to) do
            if self:isFriend(p) or self:cantDamageMore(p, self.player) then return "cancel" end
        end
        for _, p in sgs.qlist(use.to) do
            if getCardsNum("Jink",p,self.player) < 1 or self:canLiegong(p, self.player) then
                if table.contains(items, "slash2") and self.player:getLostHp() > 1  then
                    return "slash2"
                end
            end
        end
        for _, p in sgs.qlist(use.to) do
            if getCardsNum("Jink",p,self.player) < 1 or self:canLiegong(p, self.player) then
                if table.contains(items, "slash1") and (buff or self.player:getLostHp() > 1) then
                    return "slash1"
                end
            end
        end
    elseif use.card:isKindOf("Peach") then
        for _, p in sgs.qlist(use.to) do
            if self:isFriend(p) and self:canDraw(p, self.player) then
                if table.contains(items, "peach2") and buff then
                    return "peach2"
                end
            end
        end
        for _, p in sgs.qlist(use.to) do
            if self:isFriend(p) and self:canDraw(p, self.player) then
                if table.contains(items, "peach1") then
                    return "peach1"
                end
            end
        end
    elseif use.card:isKindOf("Analeptic") then
        if table.contains(items, "analeptic2") and (buff and self.player:getLostHp() >= 1)  then
            return "analeptic2"
        end
        if table.contains(items, "analeptic1") and (buff or self.player:getLostHp() > 1)  then
            return "analeptic1"
        end
    end
    return "cancel"
end


sgs.ai_card_priority.sp_danqi = function(self,card)
    if (table.contains(source_query(card, "getSkillNames"), "sp_danqi") or table.contains(source_query(card, "getSkillNames"), "sp_danqi_buffs"))
    then
        if self.useValue
        then return 1 end
        return 0.08
    end
end

sgs.ai_skill_invoke["sp_danqi_jink"] = function(self, data)
    local target = data:toPlayer()
    return target and source_query(self, "doDisCard", target, "he")
end

sgs.ai_skill_cardchosen.sp_lingyun = function(self,who,flags)
    return -1
end



sgs.ai_can_damagehp.sp_zhuangbing = function(self,from,card,to)
    return to:inYinniState() and sgs.ai_skill_invoke.sp_zhuangbing(self)
end
sgs.ai_skill_invoke.sp_zhuangbing = function(self, data)
    local target = self.room:getCurrent()
    return not self:isFriend(target)
end

sgs.ai_ajustdamage_to.sp_zhuangbing   = function(self, from, to, card, nature)
    if not to:faceUp()then
        return -99
    end
end
sgs.ai_skill_invoke.sp_yinren = function(self, data)
    return (self:isWeak()and self.player:getPile("sp_yinren"):length() < 2) or (self.player:hasSkill("sp_zhengbian") and self.player:getStrategyMark("@sp_zhengbian") > 0 and self.player:getPile("sp_yinren"):length() < 2 and not self.player:isKongcheng())
end
sgs.ai_skill_discard.sp_yinren = function(self,max,min)
    local to_cards = {}
    local cards = self.player:getCards("h")
    cards = self:sortByKeepValue(cards)
    local x = self:getOverflow()
    if not self.player:faceUp() then x = self.player:getHandcardNum() end
    for _,h in sgs.list(cards)do
        if #to_cards>=min then break end
        table.insert(to_cards,h:getKnownEffectiveId())
    end
    return to_cards
end

local sp_shenmou_skill = {}
sp_shenmou_skill.name = "sp_shenmou"
table.insert(sgs.ai_skills, sp_shenmou_skill)
sp_shenmou_skill.getTurnUseCard = function(self)
    return parse_action(self,"#sp_shenmouCard:.:")
end

sgs.ai_skill_use_func["#sp_shenmouCard"] = function(card, use, self,request)
    use.card = card
    return
end
sgs.ai_use_priority.sp_shenmouCard = 9.5

local sp_sishi_skill = {}
sp_sishi_skill.name = "sp_sishi"
table.insert(sgs.ai_skills, sp_sishi_skill)
sp_sishi_skill.getTurnUseCard = function(self)
    if self.player:getPile("sp_ss"):length() < 2 then return end
    return parse_action(self,"#sp_sishiCard:.:")
end

sgs.ai_skill_use_func["#sp_sishiCard"] = function(card, use, self,request)
    if self.player:getPile("sp_ss"):length() >= 2 and self.player:getHp() > 1 then --上古经典一血两牌理念
        use.card = card
        return
    end
end

sgs.ai_use_value.sp_sishiCard = 8.5
sgs.ai_use_priority.sp_sishiCard = 9.5
sgs.ai_card_intention.sp_sishiCard = -80

sgs.ai_skill_invoke.sp_yinyang = function(self, data)
    return #self.enemies > 0
end
sgs.ai_skill_playerchosen.sp_yinyang = function(self, targets)
    for _, friend in ipairs(self.friends_noself) do
        if source_query(self, "needToLoseHp", friend) then
            return friend
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if source_query(self, "doDisCard", friend, "he") then
            return friend
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if source_query(self, "doDisCard", enemy, "he") then
            return enemy
        end
    end
    return targets:first()
end


local sp_zhengbian_skill = {}
sp_zhengbian_skill.name = "sp_zhengbian"
table.insert(sgs.ai_skills,sp_zhengbian_skill)
sp_zhengbian_skill.getTurnUseCard = function(self,inclusive)
    return parse_action(self,"#sp_zhengbianCard:.:")
end

sgs.ai_skill_use_func["#sp_zhengbianCard"] = function(card,use,self,request)
    local slashes = self:getCards("Slash")
    for _,e in sgs.list(self.player:getEquips())do
        for _,slash in sgs.list(table.copyFrom(slashes))do
            if slash:getKnownEffectiveId()==e:getKnownId()
            or table.contains(source_query(slash, "getSkillNames"), e:objectName())
            or not source_query(slash, "isAvailable", self.player)
            then table.removeOne(slashes,slash) end
        end
    end
    if #slashes+self.player:getPile("sp_ss"):length()<1 then return end
    self:sort(self.enemies,"hp")
    for _,enemy in sgs.list(self.enemies)do
        local n = 0
        for _,slash in sgs.list(slashes)do
            local d = use_card(self,slash)
            if d.card and d.to:contains(enemy) then
                n = n+1
                if n>=enemy:getHp() then
                    use.card = card
                    use.to:append(enemy)
                    return
                end
            end
        end
    end
end

sgs.ai_use_priority["sp_zhengbianCard"] = sgs.ai_use_priority.Slash+0.5
sgs.ai_use_value["sp_zhengbianCard"] = 3

local sp_kongju_skill = {}
sp_kongju_skill.name = "sp_kongju"
table.insert(sgs.ai_skills,sp_kongju_skill)
sp_kongju_skill.getTurnUseCard = function(self,inclusive)
    return parse_action(self,"#sp_kongjuCard:.:")
end

sgs.ai_skill_use_func["#sp_kongjuCard"] = function(card,use,self,request)
    use.card = card
    return
end
sgs.ai_skill_choice["sp_kongju"] = function(self, choices, data)
    local items = choices:split("+")
    if table.contains(items, "lose1MaxHptochosetodo") and self.player:getMaxHp() >= 4 and self.player:isWounded() then
        return "lose1MaxHptochosetodo"
    end
    if table.contains(items, "randomtodo") then
        return "randomtodo"
    end
    if table.contains(items, "one") then
        if invoke_peiqi(self,ToData())  then
            return "one"
        end
    end
    if table.contains(items, "two") then
        for _, p in ipairs(self.enemies) do
            if source_query(self, "doDisCard", p, "h", true) then
                return "two"
            end
        end
    end
    return items[#items]
end

sgs.ai_skill_playerchosen.sp_kongju = function(self,players)
    local choice = scope(self,"sp_kongju_choose")
    if choice == "one" then
        local from = scoped_player(self,"sp_kongjuOneTarget")
        if from then
            for _,target in sgs.list(players)do
                if target:objectName()==(get_state(self,"peiqiData").to):objectName()
                then return target end
            end
        else
            if invoke_peiqi(self,ToData())
            then
                for _,target in sgs.list(players)do
                    if target:objectName()==(get_state(self,"peiqiData").from):objectName()
                    then return target end
                end
            end
        end
    elseif choice == "two" then
        local from = scoped_player(self,"sp_kongjuOneTarget")
        if from then
            return self.player
        else
            for _,target in sgs.list(players)do
                if source_query(self, "doDisCard", target, "h", true) then
                    return target
                end
            end
        end
    elseif choice == "three" then
        for _,target in sgs.list(players)do
            if self:isEnemy(target) and target:getMarkNames():length() > 0 then
                return target
            end
        end
    end
end



sgs.ai_skill_invoke["@sp_yingjie_xingxia"] = true
sgs.ai_skill_playerchosen["sp_yingjie"] = function(self, targets)
    targets = sgs.QList2Table(targets)
    if self.player:hasSkill("sp_rongma") and self.player:getStrategyMark("&sp_rongma") < 40 then
        return self.player
    end
    if self:findPlayerToDraw(true,1,false) then return self:findPlayerToDraw(true,1,false) end
    for _, p in ipairs(targets) do
        if self:isFriend(p) and self:canDraw(p, self.player) then
            return p
        end
    end
    return self.player
end
sgs.ai_playerchosen_intention["sp_yingjie"] = -50

sgs.ai_skill_use["@@sp_yingjie!"] = function(self,prompt)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local targets = self.room:getOtherPlayers(self.player)
    local c,to = self:getCardNeedPlayer(cards, false, targets)
    if c and to then return "#sp_yingjieCard:"..c:getKnownEffectiveId()..":->"..to:objectName() end
    for _, friend in ipairs(self.friends_noself) do
        for _,h in sgs.list(self.player:getHandcards())do
            if self:willUse(self.player, h) and source_query(h, "isAvailable", self.player) then continue end
            return "#sp_yingjieCard:"..h:getKnownEffectiveId()..":->"..friend:objectName()
        end
    end

    return "."
end
sgs.ai_card_intention.sp_yingjieCard     = -50

sgs.ai_skill_invoke["@sp_yingjie_zhangyi"] = true

sgs.ai_skill_playerchosen.sp_yuanzhi = function(self, targets)
    local targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _, p in ipairs(targets) do
        if self:isEnemy(p) and not p:isKongcheng() then
            return p
        end
    end
end

local sp_yuanzhi_skill = {}
sp_yuanzhi_skill.name = "sp_yuanzhi"
table.insert(sgs.ai_skills, sp_yuanzhi_skill)
sp_yuanzhi_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#sp_yuanzhiCard") or self.player:isKongcheng() and self.player:getStrategyMark("&sp_yuanzhiFQC") <= self.player:getStrategyMark("sp_yuanzhiUF") then return end
    return parse_action(self,"#sp_yuanzhiCard:.:")
end

sgs.ai_skill_use_func["#sp_yuanzhiCard"] = function(card, use, self,request)
    if not self.player:getStrategyHasUsed("#sp_yuanzhiCard") and not self.player:isKongcheng() and self.player:getStrategyMark("&sp_yuanzhiFQC") > self.player:getStrategyMark("sp_yuanzhiUF") then
        self:sort(self.enemies)
        self.enemies = sgs.reverse(self.enemies)
        for _, enemy in ipairs(self.enemies) do
            if source_query(self, "objectiveLevel", enemy) > 0 and source_query(self.player, "canPindian", enemy) then
                use.card = card
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end

sgs.ai_use_value.sp_yuanzhiCard = 8.5
sgs.ai_use_priority.sp_yuanzhiCard = 9.5
sgs.ai_card_intention.sp_yuanzhiCard = 80

sgs.ai_skill_choice.sp_yuanzhi = function(self, choices, data)
return "2" end

ai_audited_aliases.register{id="ai_cardneed.sp_yuanzhi",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"sp_yuanzhi"},canonical_registry="ai_cardneed",canonical_path={"bignumber"}}



sgs.ai_skill_invoke["@sp_zaoyan_yang"] = function(self, data)
    if sgs.ai_skill_cardask["@sp_zaoyan-red"](self,data, ".|red|.|.") ~= "." then
        return true
    end
    return false
end
sgs.ai_skill_invoke["@sp_zaoyan_yin"] = function(self, data)
    if sgs.ai_skill_cardask["@sp_zaoyan-black"](self,data, ".|black|.|.") ~= "." then
        return true
    end
    return false
end

sgs.ai_skill_cardask["@sp_zaoyan-red"] = function(self,data,pattern,target)
    local use = data:toCardUse()
    local target = use.to:first()
    local cards = sgs.QList2Table(self.player:getCards("eh"))
    self:sortByKeepValue(cards)
    if source_query(self, "damageIsEffective", target, sgs.DamageStruct_Fire) then
        if (self:isFriend(target) and source_query(self, "needToLoseHp", target, use.from)) or (self:isEnemy(target) and not source_query(self, "cantbeHurt", target)) then
            for _,h in sgs.list(cards)do
                if source_query(self, "matchesDiscardPattern", pattern, h)
                then return h:getKnownEffectiveId() end
                if h:isRed()
                then return h:getKnownEffectiveId() end
            end
            return self:getCardId(pattern)
        end
    end
    return "."
end
sgs.ai_skill_cardask["@sp_zaoyan-black"] = function(self,data,pattern,target)
    local use = data:toCardUse()
    local target = use.to:first()
    local cards = sgs.QList2Table(self.player:getCards("eh"))
    self:sortByKeepValue(cards)
    if (self:isFriend(target) and (source_query(self, "needToLoseHp", target, use.from) or hasZhaxiangEffect(target))) or (self:isEnemy(target) and not hasZhaxiangEffect(target)) then
        for _,h in sgs.list(cards)do
            if source_query(self, "matchesDiscardPattern", pattern, h)
            then return h:getKnownEffectiveId() end
            if h:isBlack()
            then return h:getKnownEffectiveId() end
        end
        return self:getCardId(pattern)
    end
    return "."
end
sgs.ai_skill_use["@@sp_fenying"] = function(self, prompt, method)
    local damage = scoped_struct(self,"sp_fenying","damage")
    if self:isFriend(damage.to) then return "." end
    if not source_query(self, "damageIsEffective", damage.to, sgs.DamageStruct_Fire) then return "." end
    if not source_query(self, "damageIsEffective", damage.to, damage.card, damage.from) then return "." end
    if self:cantDamageMore(damage.to, damage.from) then return "." end
    if damage.damage <= 1 and damage.to:getHp() > damage.damage * 2 and not self:isWeak()  then return "." end
    if self.player:getEquips():length() < damage.damage * 2 and not self:isWeak()  then return "." end
    local targets = {}

    for _, enemy in ipairs(self.enemies) do
        if source_query(self, "damageIsEffective", enemy, sgs.DamageStruct_Fire) and not source_query(self, "cantbeHurt", enemy) and not enemy:isChained() then
            table.insert(targets, enemy:objectName())
        end
    end
    for _, friend in ipairs(self.friends) do
        if source_query(self, "damageIsEffective", friend, sgs.DamageStruct_Fire) and friend:isChained() and not source_query(self, "needToLoseHp", friend) then
            table.insert(targets, friend:objectName())
        end
    end
    local give_all_cards = {}
    for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
        if #give_all_cards < #targets then
            table.insert(give_all_cards, c:getKnownEffectiveId())
        end
    end
    if #give_all_cards < #targets then
        while #give_all_cards < #targets do
            table.removeOne(targets,targets[#targets])
        end
    end
    if #targets < #give_all_cards then
        while #targets < #give_all_cards do
            table.removeOne(give_all_cards,give_all_cards[#give_all_cards])
        end
    end
    if #targets > 0 and #give_all_cards == #targets then
        return "#sp_fenyingCard:" .. table.concat(give_all_cards, "+") .. ":->" .. table.concat(targets, "+")
    end
    return "."
end





sgs.ai_skill_use["@@sp_qiangxi"] = function(self,prompt)
    self:sort(self.enemies,"handcard_defense")
    local sp_qiangxi_mark = self.player:getStrategyMark("sp_qiangxi")
    local targets = {}

    local add_player = function (player,isfriend)
        if player:getHandcardNum()==0 or player:objectName()==self.player:objectName() then return #targets end
        if source_query(self, "objectiveLevel", player)==0 and source_query(player, "isLord") and role_count(self,"rebel")>1 then return #targets end

        local f = false
        for _,c in ipairs(targets)do
            if c==player:objectName() then
                f = true
                break
            end
        end

        if not f then table.insert(targets,player:objectName()) end

        if isfriend and isfriend==1 then
            self:setStrategyPlayerFlag(self.player,"sp_qiangxi_isfriend_"..player:objectName(),true)
        end
        return #targets
    end

    local parsesp_qiangxiCard = function()
        if #targets==0 then return "." end
        local s = table.concat(targets,"+")
        return "#sp_qiangxiCard:.:->"..s
    end

    local lord = self.room:getLord()
    if lord and self:isEnemy(lord) and source_query(self.room, "getTurnCount")<=1 and not lord:isKongcheng() then
        if add_player(lord)==sp_qiangxi_mark then return parsesp_qiangxiCard() end
    end


    for i = 1,#self.enemies,1 do
        local p = self.enemies[i]
        local cards = sgs.QList2Table(visible_hand(self,p))
        local flag = string.format("%s_%s_%s","visible",self.player:objectName(),p:objectName())
        for _,card in ipairs(cards)do
            if (card:getStrategyFlag("visible") or card:getStrategyFlag(flag)) and (card:isKindOf("Peach") or card:isKindOf("Nullification") or card:isKindOf("Analeptic") ) then
                if add_player(p)==sp_qiangxi_mark  then return parsesp_qiangxiCard() end
            end
        end
    end

    for i = 1,#self.enemies,1 do
        local p = self.enemies[i]
        if p:hasSkills("jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then
            if add_player(p)==sp_qiangxi_mark  then return parsesp_qiangxiCard() end
        end
    end

    for i = 1,#self.enemies,1 do
        local p = self.enemies[i]
        local x = p:getHandcardNum()
        local good_target = true
        if x==1 and self:needKongcheng(p) then good_target = false end
        if x>=2 and p:hasSkill("tuntian") and p:hasSkill("zaoxian", true) then good_target = false end
        if good_target and add_player(p)==sp_qiangxi_mark then return parsesp_qiangxiCard() end
    end


    local others = self.room:getOtherPlayers(self.player)
    for _,other in sgs.list(others)do
        if source_query(self, "objectiveLevel", other)>=0 and not (other:hasSkill("tuntian") and other:hasSkill("zaoxian", true)) and add_player(other)==sp_qiangxi_mark then
            return parsesp_qiangxiCard()
        end
    end

    for _,other in sgs.list(others)do
        if source_query(self, "objectiveLevel", other)>=0 and not (other:hasSkill("tuntian") and other:hasSkill("zaoxian", true)) and math.random(0,5)<=1 and not self:hasSkills("qiaobian") then
            add_player(other)
        end
    end

    return parsesp_qiangxiCard()
end

sgs.ai_card_intention.sp_qiangxiCard = function(self,card,from,tos)
    local lord = getLord(self.player)
    local sp_qiangxi_lord = false
    if role_estimate(self,from)=="neutral" and role_estimate(self,tos[1])=="neutral" and
        (not tos[2] or role_estimate(self,tos[2])=="neutral") and lord and not lord:isKongcheng() and
        not (self:needKongcheng(lord) and lord:getHandcardNum()==1 ) and
        source_query(self, "hasLoseHandcardEffective", lord) and not (lord:hasSkill("tuntian") and lord:hasSkill("zaoxian", true)) and source_query(from, "aliveCount")>=4 then
            self:updateIntention(from,lord,-80)
        return
    end
    if source_query(from, "getState")=="online" then
        for _,to in ipairs(tos)do
            if to:hasSkill("kongcheng") or to:hasSkill("lianying") or to:hasSkill("zhiji")
                or (to:hasSkill("tuntian") and to:hasSkill("zaoxian")) then
            else
                self:updateIntention(from,to,80)
            end
        end
    else
        for _,to in ipairs(tos)do
            if lord and to:objectName()==lord:objectName() then sp_qiangxi_lord = true end
            local intention = from:getStrategyFlag("sp_qiangxi_isfriend_"..to:objectName()) and -5 or 80
            self:updateIntention(from,to,intention)
        end
        if source_query(self.room, "getTurnCount")<=1 and not sp_qiangxi_lord and lord and not lord:isKongcheng() and from:getRoom():alivePlayerCount()>2 then
            self:updateIntention(from,lord,-80)
        end
    end
end

sgs.ai_ajustdamage_from.sp_liaolai = function(self,from,to,card,nature)
    if to and to:getKnownKingdom() == "wu" then
        local n = 0
        if from:getHp() < to:getHp() then n = n + 1 end
        if from:getHandcardNum() < to:getHandcardNum() then n = n + 1 end
        return n
    end
end



sgs.ai_skill_playerchosen.sp_lvezhen = function(self, targets)
    targets = sgs.QList2Table(targets)
    local use = scoped_struct(self,"sp_lvezhen","use")
    local dummy_use = scoped_use_card(self,"sp_lvezhen",use.card, dummy(true, 1, use.to))
    if not dummy_use.to:isEmpty() then
        for _, p in sgs.qlist(dummy_use.to) do
            return p
        end
    end
    return nil
end
sgs.ai_skill_use["@@sp_lvezhen_SSQY"] = function(self, prompt)
    for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
        if c:isRed() then
            local acard = clone_preview(self,"snatch", sgs.Card_SuitToBeDecided, -1)
            mutate(self,acard,"add",c)

            mutate(self,acard,"skill","sp_lvezhen")
            local d = use_card(self,acard, dummy())
            if d.card then
                local tos = {}
                for _,p in sgs.list(d.to)do
                    table.insert(tos,p:objectName())
                end
                return acard:toString().."->"..table.concat(tos,"+")
            end
        end
    end
    return "."
end
sgs.ai_skill_use["@@sp_lvezhen_GHCQ"] = function(self, prompt)
    for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
        if c:isBlack() then
            local acard = clone_preview(self,"dismantlement", sgs.Card_SuitToBeDecided, -1)

            mutate(self,acard,"add",c)
            mutate(self,acard,"skill","sp_lvezhen")
            local d = use_card(self,acard, dummy())
            if d.card then
                local tos = {}
                for _,p in sgs.list(d.to)do
                    table.insert(tos,p:objectName())
                end
                return acard:toString().."->"..table.concat(tos,"+")
            end
        end
    end
    return "."
end

local sp_lvezhen_skill = {}
sp_lvezhen_skill.name = "sp_lvezhen"
table.insert(sgs.ai_skills,sp_lvezhen_skill)
sp_lvezhen_skill.getTurnUseCard = function(self)
    return parse_action(self,"#sp_lvezhenCard:.:")
end

sgs.ai_skill_use_func["#sp_lvezhenCard"] = function(card,use,self,request)
    local n = source_query(self.player, "getChangeSkillState", "sp_lvezhen")
    if n == 1 then
        if sgs.ai_skill_use["@@sp_lvezhen_SSQY"](self, "")~= "." then
            use.card = card
            return
        end
    else
        if sgs.ai_skill_use["@@sp_lvezhen_GHCQ"](self, "")~= "." then
            use.card = card
            return
        end
    end
end
sgs.ai_use_priority.sp_lvezhenCard = sgs.ai_use_priority.Dismantlement

local sp_xiying_skill = {}
sp_xiying_skill.name = "sp_xiying"
table.insert(sgs.ai_skills, sp_xiying_skill)
sp_xiying_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("@sp_xiying") == 0 then return end
    return parse_action(self,"#sp_xiyingCard:.:")
end

sgs.ai_skill_use_func["#sp_xiyingCard"] = function(card, use, self,request)
    if self.player:getStrategyMark("@sp_xiying") > 0 and self.player:getHandcardNum() <= 3 then
        self:sort(self.enemies,"handcard",true)
        local jwfy = self.room:findPlayerBySkillName("shoucheng")
        for _,enemy in sgs.list(self.enemies)do
            if not enemy:hasSkill("kongcheng")
            then
                if (enemy:hasSkill("lianying") or jwfy and self:isFriend(jwfy, enemy)) and self:damageMinusHp(enemy,1)>0
                or enemy:getHp()<3 and self:damageMinusHp(enemy,0)>0 and enemy:getHandcardNum()>0
                or enemy:getHandcardNum()>=enemy:getHp() and enemy:getHp()>2 and self:damageMinusHp(enemy,0)>=-1
                or enemy:getHandcardNum()-enemy:getHp()>2
                then
                    use.card = card
                    use.to:append(enemy)
                    return
                end
            end
        end
        for _,enemy in sgs.list(self.enemies)do
            if enemy:getHandcardNum()>=enemy:getHp()
            then
                use.card = card
                use.to:append(enemy)
                return
            end
        end
        if self:hasCrossbowEffect()
    or self:getCardsNum("Crossbow")>0
    then
        local slash = self:getCard("Slash") or preview(self)
        for _,enemy in sgs.list(self.enemies)do
            if enemy:isMale()
            and not enemy:isKongcheng()
            and source_query(self, "slashIsEffective", slash, enemy)
            and source_query(self.player, "distanceTo", enemy)==1
            and not enemy:hasSkills("fenyong|zhichi|fankui|vsganglie|ganglie|neoganglie|enyuan|nosenyuan|langgu|guixin|kongcheng")
            and self:getCardsNum("Slash")+getKnownCard(enemy,self.player,"Slash")>=3
            then
                use.card = card
                use.to:append(enemy)
                return
            end
        end
    end
    end
end

sgs.ai_use_value.sp_xiyingCard = 9.5
sgs.ai_use_priority.sp_xiyingCard = 3.5
sgs.ai_card_intention.sp_xiyingCard = 30



local fcj_kannan_skill = {}
fcj_kannan_skill.name = "fcj_kannan"
table.insert(sgs.ai_skills, fcj_kannan_skill)
fcj_kannan_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("fcj_kannanUsed") >= self.player:getHp() or self.player:isKongcheng() then return end
    return parse_action(self,"#fcj_kannanCard:.:")
end

sgs.ai_skill_use_func["#fcj_kannanCard"] = function(card, use, self,request)
    local cards = sgs.CardList()
    local peach = 0
    for _,c in sgs.qlist(self.player:getHandcards())do
        if isCard("Peach",c,self.player) and peach<2 then
            peach = peach+1
        else
            cards:append(c)
        end
    end

    local min_card = self:getMinCard(self.player,cards)
    if min_card then
        local min_point = min_card:getNumber()
        if self.player:hasSkill("tianbian") and min_card:getSuit()==sgs.Card_Heart then min_point = 13 end
        if min_point<7 then
            self:sort(self.friends_noself,"handcard")
            self.friends_noself = sgs.reverse(self.friends_noself)
            for _,p in ipairs(self.friends_noself)do
                if p:getStrategyFlag("fcj_kannanSelected") or not source_query(self.player, "canPindian", p) then continue end
                if not self:needToThrowLastHandcard(p) then continue end
                set_state(self,"kannan_card",min_card)
                use.card = parse_action(self,"#fcj_kannanCard:.:")
                use.to:append(p)
                return
            end
            for _,p in ipairs(self.friends_noself)do
                if p:getStrategyFlag("fcj_kannanSelected") or not source_query(self.player, "canPindian", p) then continue end
                set_state(self,"kannan_card",min_card)
                use.card = parse_action(self,"#fcj_kannanCard:.:")
                use.to:append(p)
                return
            end
        end
    end

    local max_card = self:getMaxCard(self.player,cards)
    if max_card then
        local max_point = max_card:getNumber()
        if self.player:hasSkill("tianbian") and max_card:getSuit()==sgs.Card_Heart then max_point = 13 end
        if max_point>=7 then
            self:sort(self.enemies,"handcard")
            for _,p in ipairs(self.enemies)do
                if p:getStrategyFlag("fcj_kannanSelected") or not source_query(self.player, "canPindian", p) or not source_query(self, "doDisCard", p, "h", true) then continue end
                set_state(self,"kannan_card",max_card)
                use.card = parse_action(self,"#fcj_kannanCard:.:")
                use.to:append(p)
                return
            end
        end
    end
end

sgs.ai_use_value.fcj_kannanCard = 8.5
sgs.ai_use_priority.fcj_kannanCard = 9.5


sgs.ai_skill_choice.fcj_kannan = function(self, choices, data)
    return "1"
end
function sgs.ai_skill_pindian.fcj_kannan(minusecard,self,requestor)
    return self:isFriend(requestor) and self:getMaxCard() or ( self:getMinCard():getNumber()>6 and  minusecard or self:getMinCard() )
end

sgs.ai_ajustdamage_from["&fcj_kannan"] = function(self,from,to,slash,nature)
    if slash and slash:isKindOf("Slash")
    then return from:getStrategyMark("&fcj_kannan") end
end


local fcj_pingcai_skill = {}
fcj_pingcai_skill.name = "fcj_pingcai"
table.insert(sgs.ai_skills, fcj_pingcai_skill)
fcj_pingcai_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("fcj_pingcaiCard") then return end
    return parse_action(self,"#fcj_pingcaiCard:.:")
end

sgs.ai_skill_use_func["#fcj_pingcaiCard"] = function(card, use, self,request)
    if not self.player:getStrategyHasUsed("#fcj_pingcaiCard") then
        use.card = card
        return
    end
end

sgs.ai_use_value.fcj_pingcaiCard = 8.5
sgs.ai_use_priority.fcj_pingcaiCard = 9.5
sgs.ai_card_intention.fcj_pingcaiCard = -80

sgs.ai_skill_choice["@fcj_pingcai-ChooseTreasure"] = function(self, choices, data)
    choices = choices:split("+")
    if table.contains(choices,"xuanjian") then
        for _,p in ipairs(self.friends)do
            if self:isWeak(p) and p:getLostHp()>0
            and not self:needKongcheng(p, true)
            then return "xuanjian" end
        end
    end
    if table.contains(choices,"wolong") then
        for _,p in ipairs(self.enemies)do
            if source_query(self, "damageIsEffective", p, sgs.DamageStruct_Fire, self.player)
            and source_query(self, "hasHeavyDamage", self.player, nil, p, "F")
            then return "wolong" end
        end
    end
    if table.contains(choices,"xuanjian") then
        for _,p in ipairs(self.enemies)do
            if p:getLostHp()>0
            and self:needKongcheng(p, true)
            and not hasManjuanEffect(p)
            and self:getEnemyNumBySeat(self.player,p,p)>0
            then return "xuanjian" end
        end
    end
    if table.contains(choices,"fengchu")
    and #choices>1 then
        local fengchu = 0
        for _,p in ipairs(self.enemies)do
            if not p:isChained()
            and not p:hasSkill("qianjie")
            then fengchu = fengchu+1 end
        end
        if fengchu<2 then table.removeOne(choices,"fengchu") end
    end
    if table.contains(choices,"shuijing")
    and #choices>1 then
        local shuijing = false
        for _,p in sgs.qlist(self.room:getAlivePlayers())do
            if string.find(translated(source_query(p, "getGeneralName")),"司马徽")
            or string.find(translated(source_query(p, "getGeneral2Name")),"司马徽")
            then shuijing = true break end
        end
        if shuijing then
            local from,card,to = self:moveField(nil,"e")
            if not from or not card or not to then
                table.removeOne(choices,"shuijing")
            end
        else
            if #pingcaiMoveArmor(self)==0 then
                table.removeOne(choices,"shuijing")
            end
        end
    end
    return choices[math.random(1,#choices)]
end

sgs.ai_skill_use["@@fcj_pingcaiFengchu"] = function(self, prompt, method)
    local tos = {}
    self:sort(self.enemies)
    for _,p in ipairs(self.enemies)do
        if not p:isChained() and #tos<4 and not p:hasSkill("qianjie")
        then table.insert(tos,p:objectName()) end
    end
    if #tos > 0 then
        return "#fcj_pingcaiFengchuCard:.:->" ..  table.concat(tos, "+")
    end
    return "."
end

sgs.ai_skill_use["@@fcj_pingcaiWolong"] = function(self, prompt, method)
    local tos = self:findPlayerToDamage(1,self.player,"F")
    self:sort(tos)
    local tos2 = {}
    for _,p in ipairs(tos)do
        if #tos2<2 and not self:isFriend(p)
        then table.insert(tos2,p:objectName()) end
    end
    self:sort(self.enemies)
    for _,p in ipairs(self.enemies)do
        if #tos2<2 and not table.contains(tos2,p:objectName())
        then table.insert(tos2,p:objectName()) end
    end
    if #tos2 > 0 then
        return "#fcj_pingcaiWolongCard:.:->" ..  table.concat(tos2, "+")
    end
    return "."
end
sgs.ai_skill_use["@@fcj_pingcaiShuijing"] = function(self, prompt, method)
    local from,card,to = self:moveField(nil,"e")
    if from then return  "#fcj_pingcaiShuijingCard:.:->" .. from:objectName()  end
    return "."
end
sgs.ai_skill_cardchosen.fcj_pingcaiShuijing = function(self,who,flags)
    local from,card,to = self:moveField(nil,"e")
    if card then return card end
end
sgs.ai_skill_playerchosen.fcj_pingcaiShuijing = function(self,targets)
    local from,card,to = self:moveField(nil,"e")
    if to then return to end
end


sgs.ai_skill_use["@@fcj_pingcaiXuanjian"] = function(self, prompt, method)
    local target
    for _, p in ipairs(self.friends) do --先找体力值过低的队友
        if self:isFriend(p) and p:getMaxHp() > 2 and p:getHp() == 1 then --不写<=1，跳过周泰这个体力值不与生命危险程度挂钩的
            target = p
            break
        end
    end
    for _, p in ipairs(self.friends) do --再找受伤队友
        if self:isFriend(p) and p:isWounded() then
            target = p
            break
        end
    end
    for _, p in ipairs(self.friends) do --再找健康但手牌过少的队友
        if self:isFriend(p) and p:getHandcardNum() < 2 then
            target = p
            break
        end
    end
    for _, p in ipairs(self.friends) do --再找一般健康队友
        if self:isFriend(p) then
            target = p
            break
        end
    end
    if target then
        return "#fcj_pingcaiXuanjianCard:.:->" .. target:objectName()
    end
    return "#fcj_pingcaiXuanjianCard:.:->" .. self.player:objectName()
end
sgs.ai_card_intention.fcj_pingcaiXuanjianCard = -80


sgs.ai_skill_invoke.fcj_wanglie = function(self, data)
    local use = data:toCardUse()
    for _, p in sgs.qlist(use.to) do
        if p and self:isFriend(p) then
            return false
        end
    end
    return source_query(use.card, "isDamageCard")
end

sgs.ai_skill_choice.fcj_wanglie = function(self, choices, data)
    local items = choices:split("+")


    if source_query(self, "getPriorTurnUseCount")<2 and table.contains(items, "Beishui") then return "Beishui" end
    return "Hit" or "Damage"
end
sgs.ai_ajustdamage_from.fcj_wanglie = function(self, from, to, card, nature)
    if (card and card:getStrategyFlag("fcj_wanglieDamage")) then
        return 1
    end
end






sgs.ai_target_revises.fcj_yizhong = function(to,card,self)
    if card:isBlack() and card:isKindOf("Slash")
    then return true end
end
sgs.ai_skill_invoke.fcj_yizhong = function(self, data)
    return sgs.ai_skill_playerchosen.fcj_yizhong(self, self.room:getOtherPlayers(self.player)) ~= nil
end

sgs.ai_skill_cardask["@fcj_yizhong-invoke"] = function(self,data,pattern)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _,h in sgs.list(cards)do
        if source_query(self, "matchesDiscardPattern", pattern, h)
        then return h:getKnownEffectiveId() end
        if h:isBlack()
        then return h:getKnownEffectiveId() end
    end
    return "."
end
sgs.ai_skill_playerchosen.fcj_yizhong = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _, friend in ipairs(targets) do
        if self:isFriend(friend) and not friend:hasSkill("fcj_yizhong") then
            return friend
        end
    end
    return nil
end

sgs.ai_playerchosen_intention.fcj_yizhong = -50



local function getKangkaiCard(self,target,data)
    local use = data:toCardUse()
    local weapon,armor,def_horse,off_horse = {},{},{},{}
    for _,card in sgs.qlist(self.player:getHandcards())do
        if card:isKindOf("Weapon") then table.insert(weapon,card)
        elseif card:isKindOf("Armor") then table.insert(armor,card)
        elseif card:isKindOf("DefensiveHorse") then table.insert(def_horse,card)
        elseif card:isKindOf("OffensiveHorse") then table.insert(off_horse,card)
        end
    end
    if #armor>0 then
        for _,card in ipairs(armor)do
            if ((not target:getArmor() and not target:hasSkills("bazhen|yizhong"))
                or (target:getArmor() and self:evaluateArmor(card,target)>=self:evaluateArmor(target:getArmor(),target)))
                and not (card:isKindOf("Vine") and use.card:isKindOf("FireSlash") and source_query(self, "slashIsEffective", use.card, target, use.from)) then
                return card:getKnownEffectiveId()
            end
        end
    end
    if source_query(self, "needToThrowArmor")
        and ((not target:getArmor() and not target:hasSkills("bazhen|yizhong"))
            or (target:getArmor() and self:evaluateArmor(self.player:getArmor(),target)>=self:evaluateArmor(target:getArmor(),target)))
        and not (self.player:getArmor():isKindOf("Vine") and use.card:isKindOf("FireSlash") and source_query(self, "slashIsEffective", use.card, target, use.from)) then
        return self.player:getArmor():getEffectiveId()
    end
    if #def_horse>0 then return def_horse[1]:getEffectiveId() end
    if #weapon>0 then
        for _,card in ipairs(weapon)do
            if not target:getWeapon()
                or (self:evaluateArmor(card,target)>=self:evaluateArmor(target:getWeapon(),target)) then
                return card:getKnownEffectiveId()
            end
        end
    end
    if self.player:getWeapon() and self:evaluateWeapon(self.player:getWeapon())<5
        and (not target:getArmor()
            or (self:evaluateArmor(self.player:getWeapon(),target)>=self:evaluateArmor(target:getWeapon(),target))) then
        return self.player:getWeapon():getEffectiveId()
    end
    if #off_horse>0 then return off_horse[1]:getEffectiveId() end
    if self.player:getOffensiveHorse()
        and ((self.player:getWeapon() and not self.player:getWeapon():isKindOf("Crossbow")) or self.player:hasSkills("mashu|tuntian")) then
        return self.player:getOffensiveHorse():getEffectiveId()
    end
end
sgs.ai_skill_invoke.fcj_kangkai = function(self, data)
    set_state(self,"fcj_kangkai_give_id",nil)
    if hasManjuanEffect(self.player) then return false end
    local target = data:toPlayer()
    if not target then return false end
    if target:objectName() == self.player:objectName() then return true
    elseif not self:isFriend(target) then
        return hasManjuanEffect(target)
    else
        local id = getKangkaiCard(self, target, scoped_data(self,"fcj_kangkaiSlash","use"))
        if id then return true else return not self:needKongcheng(target, true) end
    end
end

sgs.ai_skill_cardask["@fcj_kangkai_give"] = function(self, data, pattern, target)
    if self:isFriend(target) then
        local id = getKangkaiCard(self, target, data)
        if id then return "$" .. id end
        if self:getCardsNum("Jink") > 1 then
            for _, card in sgs.qlist(self.player:getHandcards()) do
                if isCard("Jink", card, target) then return "$" .. card:getKnownEffectiveId() end
            end
        end
        for _, card in sgs.qlist(self.player:getHandcards()) do
            if not source_query(self, "isValuableCard", card) then return "$" .. card:getKnownEffectiveId() end
        end
    else
        local to_discard = self:askForDiscard("dummyreason", 1, 1, false, true)
        if #to_discard > 0 then return "$" .. to_discard[1] end
    end
end

sgs.ai_skill_invoke["fcj_kangkai_hedraw"] = true

sgs.ai_skill_invoke["fcj_kangkai_use"] = function(self, data)
    local use = scoped_struct(self,"fcj_kangkaiSlash","use")
    local card = scoped_card(self,"fcj_kangkaiGivenCard")
    if not use.card or not card then return false end
    if card:isKindOf("Vine") and use.card:isKindOf("FireSlash") and source_query(self, "slashIsEffective", use.card, self.player, use.from) then return false end
    if ((card:isKindOf("DefensiveHorse") and self.player:getDefensiveHorse())
        or (card:isKindOf("OffensiveHorse") and (self.player:getOffensiveHorse() or (self.player:hasSkill("drmashu") and self.player:getDefensiveHorse()))))
        and not self.player:hasSkills(sgs.lose_equip_skill) then
        return false
    end
    if card:isKindOf("Armor") and ((self.player:hasSkills("bazhen|yizhong") and not self.player:getArmor())
        or (self.player:getArmor() and self:evaluateArmor(card) < self:evaluateArmor(self.player:getArmor()))) then return false end
    if card:isKindOf("Weanpon") and (self.player:getWeapon() and self:evaluateArmor(card) < self:evaluateArmor(self.player:getWeapon())) then return false end
    return true
end


sgs.ai_skill_use["@@fcj_qinguo"] = function(self, prompt, method)
    local slash = preview(self)
    mutate(self,slash,"skill","fcj_qinguo")
    local dummy_use = dummy()
    use_slash(self,slash,dummy_use)
    if dummy_use.card and dummy_use.to:length()>0 then
        local tos = {}
        for _,p in sgs.qlist(dummy_use.to)do
            table.insert(tos,p:objectName())
        end
        return "#fcj_qinguoCard:.:->"..table.concat(tos,"+")
    end
    return "."
end
sgs.need_equip_skill = sgs.need_equip_skill .. "|fcj_qinguo"
ai_audited_aliases.register{id="ai_cardneed.fcj_qinguo",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"fcj_qinguo"},canonical_registry="ai_cardneed",canonical_path={"equip"}}



local fcj_jueyan_skill = {}
fcj_jueyan_skill.name = "fcj_jueyan"
table.insert(sgs.ai_skills, fcj_jueyan_skill)
fcj_jueyan_skill.getTurnUseCard = function(self, inclusive)
    if source_query(self.player, "hasEquipArea") then
        return parse_action(self,"#fcj_jueyan:.:")
    end
end

sgs.ai_skill_use_func["#fcj_jueyan"] = function(card, use, self,request)
    use.card = card
end

sgs.ai_skill_choice["fcj_jueyan"] = function(self, choices, data)
    local has_fcj_jueyan_slash_target = false
    self:updatePlayers()
    self:sort(self.enemies, "defense")
    for _, enemy in ipairs(self.enemies) do
        if source_query(self.player, "distanceTo", enemy) == 1 and not source_query(enemy, "hasArmorEffect", "vine") then
            has_fcj_jueyan_slash_target = true
        end
    end
    local items = choices:split("+")
    if source_query(self.player, "hasEquipArea", 0) and self:getCardsNum("Slash") > 2 and has_fcj_jueyan_slash_target then
        return "fcj_jueyan0"
    elseif source_query(self.player, "hasEquipArea", 4) and self:getCardsNum("ExNihilo") > 0 then
        return "fcj_jueyan4"
    elseif source_query(self.player, "hasEquipArea", 2) and source_query(self.player, "hasEquipArea", 3) and not has_fcj_jueyan_slash_target and self:getCardsNum("Slash") > 0 then
        return "fcj_jueyan2"
    elseif source_query(self.player, "hasEquipArea", 1) then
        return "fcj_jueyan1"
    else
        return items[1]
    end
end

sgs.ai_use_value.fcj_jueyan = 10
sgs.ai_use_priority.fcj_jueyan = 10
sgs.ai_card_intention.fcj_jueyan = -100

local ps_huairou_skill = {}
ps_huairou_skill.name = "ps_huairou"
table.insert(sgs.ai_skills, ps_huairou_skill)
ps_huairou_skill.getTurnUseCard = function(self, inclusive)
    local usable_cards = sgs.QList2Table(self.player:getCards("he"))
    for _, c in ipairs(usable_cards) do
        if source_query(self.player, "hasArmorEffect", "silver_lion") and c:isKindOf("SilverLion")
        and self.player:isWounded() then
            return parse_action(self,string.format("#ps_huairou:%s:", c:getKnownEffectiveId()))
        elseif not source_query(self.player, "hasEquipArea", 0) and c:isKindOf("Weapon") then
            return parse_action(self,string.format("#ps_huairou:%s:", c:getKnownEffectiveId()))
        elseif not source_query(self.player, "hasEquipArea", 1) and c:isKindOf("Armor") then
            return parse_action(self,string.format("#ps_huairou:%s:", c:getKnownEffectiveId()))
        elseif not source_query(self.player, "hasEquipArea", 2) and c:isKindOf("DefensiveHorse") then
            return parse_action(self,string.format("#ps_huairou:%s:", c:getKnownEffectiveId()))
        elseif not source_query(self.player, "hasEquipArea", 3) and c:isKindOf("OffensiveHorse") then
            return parse_action(self,string.format("#ps_huairou:%s:", c:getKnownEffectiveId()))
        elseif not source_query(self.player, "hasEquipArea", 4) and c:isKindOf("Treasure") then
            return parse_action(self,string.format("#ps_huairou:%s:", c:getKnownEffectiveId()))
        end
    end
end

sgs.ai_skill_use_func["#ps_huairou"] = function(card, use, self,request)
    use.card = card
end

sgs.ai_use_value.ps_huairou = 10
sgs.ai_use_priority.ps_huairou = 10
sgs.ai_card_intention.ps_huairou = -100


sgs.ai_ajustdamage_from.fcj_jiaozi = function(self,from,to,card,nature)
    for _,p in sgs.qlist(from:getAliveSiblings())do
        if p:getHandcardNum()>=from:getHandcardNum() then return 0 end
    end
    return 1
end
sgs.ai_ajustdamage_to.fcj_jiaozi = function(self,from,to,card,nature)
    for _,p in sgs.qlist(to:getAliveSiblings())do
        if p:getHandcardNum()>=to:getHandcardNum() then return 0 end
    end
    return 1
end


sgs.ai_skill_playerchosen.fcj_jianjie = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
        if self:isFriend(p) and (p:getStrategyMark("&fcj_Loong") > 0 or p:getStrategyMark("&fcj_Phoenix") > 0) then
            return p
        end
    end
    for _, p in ipairs(targets) do --优先
        if self:isFriend(p) then
            return p
        end
    end
    return self.player
end

sgs.ai_skill_playerchosen["fcj_jianjied"] = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do --优先真人队友
        if self:isFriend(p) and source_query(p, "getState") == "online" then
            return p
        end
    end
    for _, p in ipairs(targets) do
        if self:isFriend(p) then
            return p
        end
    end
    return self.player
end

local fcj_jianjie_skill = {}
fcj_jianjie_skill.name = "fcj_jianjie"
table.insert(sgs.ai_skills, fcj_jianjie_skill)
fcj_jianjie_skill.getTurnUseCard = function(self)
    if self.player:usedTimes("#fcj_jianjieCard") >= 2 then return end
    return parse_action(self,"#fcj_jianjieCard:.:")
end

sgs.ai_skill_use_func["#fcj_jianjieCard"] = function(card, use, self,request)
    if self.player:usedTimes("#fcj_jianjieCard") < 2 then
        self:sort(self.enemies)
        self.enemies = sgs.reverse(self.enemies)
        for _, enemy in ipairs(self.enemies) do
            if source_query(self, "objectiveLevel", enemy) > 0 and (enemy:getStrategyMark("&fcj_Loong") > 0 or enemy:getStrategyMark("&fcj_Phoenix") > 0) then
                use.card = card
                if use.to then use.to:append(enemy) end
                return
            end
        end
        self:sort(self.friends_noself)
        for _, friend in ipairs(self.friends_noself) do
             if (friend:getStrategyMark("&fcj_Loong") > 0 or friend:getStrategyMark("&fcj_Phoenix") > 0) then
                use.card = card
                if use.to then use.to:append(friend) end
                return
            end
        end
    end
    return nil
end

sgs.ai_use_value.fcj_jianjieCard = 8.5
sgs.ai_use_priority.fcj_jianjieCard = 9.5


local fcjiehuoji_skill = {}
fcjiehuoji_skill.name = "fcjiehuoji"
table.insert(sgs.ai_skills, fcjiehuoji_skill)
fcjiehuoji_skill.getTurnUseCard = function(self)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    local card
    self:sortByUseValue(cards, true)
    for _, acard in sgs.list(cards) do
        if acard:isRed() and not acard:isKindOf("Peach") and (self:getDynamicUsePriority(acard) < sgs.ai_use_value.FireAttack or self:getOverflow() > 0) then
            if acard:isKindOf("Slash") and self:getCardsNum("Slash") == 1 then
                local keep
                local dummy_use = use_card(self,acard, dummy())
                if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
                    for _, p in sgs.qlist(dummy_use.to) do
                        if p:getHp() <= 1 then keep = true break end
                    end
                    if dummy_use.to:length() > 1 then keep = true end
                end
                if keep then self:setPriorityValue("Slash",self:getPriorityValue("FireAttack") + 0.1,"fcDIY")
                else
                    self:setPriorityValue("Slash",2.6,"fcDIY")
                    card = acard
                    break
                end
            else
                card = acard
                break
            end
        end
    end
    if not card then return nil end
    local suit = card:getSuitString()
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    local card_str = ("fire_attack:fcjiehuoji[%s:%s]=%d"):format(suit, number, card_id)
    local skillcard = parse_action(self,card_str)
    assert(skillcard)
    return skillcard
end

sgs.ai_cardneed.fcjiehuoji = function(to, card, self)
    return card:isRed()
end

local fcjielianhuan_skill = {}
fcjielianhuan_skill.name = "fcjielianhuan"
table.insert(sgs.ai_skills, fcjielianhuan_skill)
fcjielianhuan_skill.getTurnUseCard = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    local card
    self:sortByUseValue(cards, true)
    local slash = self:getCard("FireSlash") or self:getCard("ThunderSlash") or self:getCard("Slash")
    if slash then
        local dummy_use = use_card(self,slash, dummy())
        if not dummy_use.card then slash = nil end
    end
    for _, acard in sgs.list(cards) do
        if acard:getSuit() == sgs.Card_Club then
            local shouldUse = true
            if source_query(self, "getUseValue", acard) > sgs.ai_use_value.IronChain and acard:getTypeId() == sgs.Card_TypeTrick then
                local dummy_use = use_card(self,acard, dummy())
                if dummy_use.card then shouldUse = false end
            end
            if acard:getTypeId() == sgs.Card_TypeEquip then
                local dummy_use = use_card(self,acard, dummy())
                if dummy_use.card then shouldUse = false end
            end
            if shouldUse and (not slash or slash:getKnownEffectiveId() ~= acard:getKnownEffectiveId()) then
                card = acard
                break
            end
        end
    end
    if not card then return nil end
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    local card_str = ("iron_chain:fcjielianhuan[club:%s]=%d"):format(number, card_id)
    local skillcard = parse_action(self,card_str)
    assert(skillcard)
    return skillcard
end

sgs.ai_skill_playerchosen.fcjielianhuan = function(self, targets)
    targets = sgs.QList2Table(targets)
    local use = scoped_struct(self,"fcjielianhuan","use")
    local dummy_use = scoped_use_card(self,"fcjielianhuan",use.card, dummy(true, 99, use.to))
    if not dummy_use.to:isEmpty() then
        for _, p in sgs.qlist(dummy_use.to) do
            if table.contains(targets,p) then
                return p
            end
        end
    end
    return nil
end

sgs.ai_cardneed.fcjielianhuan = function(to, card, self)
    return card:getSuit() == sgs.Card_Club
end

sgs.ai_fill_skill.fczhizhe = function(self)
    local cs = {}
    for _,h in sgs.list(self:sortByUseValue(self.player:getCards("h")))do
        if h:getTypeId()<3 and not h:isKindOf("DelayedTrick")
        then table.insert(cs,h) end
    end
    if #cs<4 or source_query(self, "getUseValue", cs[1])<8 then return end
    return parse_action(self,"#fczhizheCard:"..cs[1]:getEffectiveId()..":")
end

sgs.ai_skill_use_func["#fczhizheCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value.fczhizheCard = 5.4
sgs.ai_use_priority.fczhizheCard = 13.8
sgs.ai_card_priority.fczhizhe = function(self,card)
    if table.contains(source_query(card, "getSkillNames"), "fczhizhe")
    then
        if self.useValue
        then return 1 end
        return 0.08
    end
end



sgs.ai_skill_invoke.fcjieniepan = function(self, data)
    local dying = data:toDying()
    local peaches = 1 - dying.who:getHp()
    return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches
end

sgs.ai_canNiepan_skill.fcjieniepan = function(player)
    return player:getStrategyMark("&fcj_Phoenix") >= 2
end

sgs.ai_skill_invoke.fcluanfeng = function(self, data)
    local dying = data:toDying()
    if dying.who:objectName() == self.player:objectName() then
        return true
    else
        return self:isFriend(dying.who)
    end
end

sgs.ai_use_revises.fcj_yinshi = function(self,card,use)
    if self.player:getStrategyMark("&fcj_Loong")+self.player:getStrategyMark("&fcj_Phoenix")<1
    and card:isKindOf("Armor")
    then return false end
end

sgs.ai_target_revises.fcj_yinshi = function(to,card)
    if not to:getArmor()
    and to:getStrategyMark("&fcj_Loong")+to:getStrategyMark("&fcj_Phoenix")<1
    and source_query(card, "isDamageCard")
    then
        if card:isKindOf("NatureSlash")
        or card:isKindOf("TrickCard")
        then return true end
    end
end




local fcj_fuman_skill = {}
fcj_fuman_skill.name = "fcj_fuman"
table.insert(sgs.ai_skills, fcj_fuman_skill)
fcj_fuman_skill.getTurnUseCard = function(self)
    if self.player:isNude() or #self.enemies == 0 or #self.friends_noself == 0 then return end
    local card_id
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _, acard in ipairs(cards) do
        if source_query(acard, "isDamageCard") or acard:isKindOf("Weanpon") then
            card_id = acard:getKnownEffectiveId()
            break
        end
    end
    if not card_id then
        return nil
    else
        return parse_action(self,"#fcj_fumanCard:"..card_id..":")
    end
end

sgs.ai_skill_use_func["#fcj_fumanCard"] = function(card, use, self,request)
    if not self.player:isNude() then
        self:sort(self.friends_noself)
        for _, friend in ipairs(self.friends_noself) do
            if friend and not self:needKongcheng(friend, true) and friend:getStrategyMark("fcj_fuman-PlayClear") == 0 then
                use.card = card
                if use.to then use.to:append(friend) end
                return
            end
        end
    end
    return nil
end

sgs.ai_use_value.fcj_fumanCard = 8.5
sgs.ai_use_priority.fcj_fumanCard = 9.5
sgs.ai_card_intention.fcj_fumanCard = -80


sgs.ai_skill_invoke.fcj_xiaoguo = function(self, data)
    local current = self.room:getCurrent()
    return self:isEnemy(current)
end

sgs.ai_skill_playerchosen.fcj_xiaoguo = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
        if self:isEnemy(p) and source_query(self, "damageIsEffective", p) and not source_query(self, "cantbeHurt", p) and not source_query(self, "needToLoseHp", p, self.player) then
            return p
        end
    end
    for _, p in ipairs(targets) do
        if self:isEnemy(p) and source_query(self, "damageIsEffective", p) and not source_query(self, "cantbeHurt", p) then
            return p
        end
    end

end
sgs.ai_choicemade_filter.skillInvoke.fcj_xiaoguo = function(self,player,promptlist)
    if promptlist[#promptlist]=="yes" then
        local current = self.room:getCurrent()
        self:updateIntention(player,current,50)
    end
end
sgs.ai_playerchosen_intention.fcj_xiaoguo = 50

sgs.ai_skill_cardask["@fcj_xiaoguo-disBasic"] = function(self, data, pattern)
    local target = data:toPlayer()
    if source_query(self, "needToLoseHp", self.player, target, nil) then return "." end
    if not source_query(self, "damageIsEffective", self.player) then return "." end
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _,h in sgs.list(cards)do
        if source_query(self, "matchesDiscardPattern", pattern, h)
        then return h:getKnownEffectiveId() end
        if h:isKindOf(pattern)
        then return h:getKnownEffectiveId() end
    end
    return self:getCardId(pattern)
end
sgs.ai_skill_cardask["@fcj_xiaoguo-disEquip"] = function(self, data, pattern)
    local target = data:toPlayer()
    if source_query(self, "needToLoseHp", self.player, target, nil) then return "." end
    if not source_query(self, "damageIsEffective", self.player) then return "." end
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _,h in sgs.list(cards)do
        if source_query(self, "matchesDiscardPattern", pattern, h)
        then return h:getKnownEffectiveId() end
        if h:isKindOf(pattern)
        then return h:getKnownEffectiveId() end
    end
    return self:getCardId(pattern)
end
sgs.ai_skill_cardask["@fcj_xiaoguo-disTrick"] = function(self, data, pattern)
    local target = data:toPlayer()
    if source_query(self, "needToLoseHp", self.player, target, nil) then return "." end
    if not source_query(self, "damageIsEffective", self.player) then return "." end
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _,h in sgs.list(cards)do
        if source_query(self, "matchesDiscardPattern", pattern, h)
        then return h:getKnownEffectiveId() end
        if h:isKindOf(pattern)
        then return h:getKnownEffectiveId() end
    end
    return self:getCardId(pattern)
end



sgs.ai_skill_use["@@fcj_jintang"] = function(self, prompt)
    local targets = {}
    if self.player:getStrategyFlag("fcj_jintang") then
        if #self.enemies == 0 then return "." end
        self:sort(self.enemies, "defense")
        for _, enemy in ipairs(self.enemies) do
            if enemy and enemy:getStrategyMark("&fcj_jintang_Friends") == 0 and not table.contains(targets, enemy:objectName()) then
                table.insert(targets, enemy:objectName())
            end
        end
    else
        table.insert(targets, self.player:objectName())
        if #self.friends_noself > 0 then
            self:sort(self.friends_noself, "defense")
            for _, friend in ipairs(self.friends_noself) do
                if friend and not table.contains(targets, friend:objectName()) then
                    table.insert(targets, friend:objectName())
                end
            end
        end
    end
    if #targets > 0 then
        return "#fcj_jintangCard:.:->" .. table.concat(targets, "+")
    end
    return "."
end
sgs.ai_skill_invoke.fcj_jintang = function(self, data)
    if #self.enemies == 0 then return false end
    return true
end
sgs.ai_card_intention["fcj_jintangCard"] = function(self,card,from,tos,source)
    for _,to in ipairs(tos)do
        self:updateIntention(from,to,from:getStrategyFlag("fcj_jintang") and 50 or -50)
    end
end

sgs.ai_skill_invoke.fcj_zhenwei = function(self, data)
    local use = data:toCardUse()
    if use.to:length()~=1 or not use.from or not use.card then return false end
    if not self:isFriend(use.to:at(0)) or self:isFriend(use.from) then return false end
    if use.to:at(0):hasSkills("liuli|tianxiang") and use.card:isKindOf("Slash") and use.to:at(0):getHandcardNum()>1 then return false end
    if use.card:isKindOf("Slash") and not source_query(self, "slashIsEffective", use.card, use.to:at(0), use.from) then return false end
    if use.to:at(0):hasSkills(sgs.masochism_skill) and not self:isWeak(use.to:at(0)) then return false end
    if self.player:getHandcardNum()+self.player:getEquips():length()<2 and not self:isWeak(use.to:at(0)) then return false end
    local to_discard = self:askForDiscard("sp_zhenwei",1,1,false,true)
    if #to_discard>0 then
        if not (use.card:isKindOf("Slash") and  self:isWeak(use.to:at(0))) and known_card(self,to_discard[1]):isKindOf("Peach") then return false end
        return true
    else
        return false
    end
end

sgs.ai_skill_choice.fcj_zhenwei = function(self, choices, data)
    local use = data:toCardUse()
    if self:isWeak() or self.player:getHandcardNum()<2 then return "2" end
    if use.card:isKindOf("TrickCard") and use.from:hasSkill("jizhi") then return "1" end
    if use.card:isKindOf("Slash") and (use.from:hasSkills("paoxiao|tianyi|xianzhen|jiangchi|fuhun|qiangwu")
        or (use.from:getWeapon() and use.from:getWeapon():isKindOf("Crossbow"))) and self:getCardsNum("Jink")==0 then return "2" end
    if use.card:isKindOf("SupplyShortage") then return "2" end
    if use.card:isKindOf("Slash") and self:getCardsNum("Jink")==0 and self.player:getLostHp()>0 then return "2" end
    if use.card:isKindOf("Indulgence") and self.player:getHandcardNum()+1>self.player:getHp() then return "2" end
    if use.card:isKindOf("Slash") and use.from:hasSkills("tieqi|wushuang|yijue|liegong|mengjin|qianxi") and not (use.from:getWeapon() and use.from:getWeapon():isKindOf("Crossbow")) then return "2" end
    return "1"
end


sgs.ai_skill_invoke.fcj_huanshi = function(self,data)
    local judge = scoped_judge(self,"fcj_huanshiJudge")
    local cards = sgs.QList2Table(self.player:getCards("he"))
    if self:isFriend(judge.who) then
        local card_id = self:getRetrialCardId(cards,judge)
        if card_id~=-1 then return true end
        local card_id = self:getRetrialCardId(cards,judge,nil,true)
        if card_id<0 then return false end
        if self:needRetrial(judge) or source_query(self, "getUseValue", judge.card)>source_query(self, "getUseValue", judge:exchangeMaterial(self,card_id))then
            return true
        end
    elseif self:isEnemy(judge.who) and self:needRetrial(judge) then
        for _,card in sgs.list(cards)do
            if judge:isGood(card) or source_query(self, "isValuableCard", card) then return false end
        end
        return true
    end
    return false
end

sgs.ai_skill_askforag.fcj_huanshi = function(self,card_ids)
    local cards = {}
    for _,id in sgs.list(card_ids)do
        table.insert(cards,known_card(self,id))
    end
    local judge = scoped_judge(self,"fcj_huanshiJudge")
    local zhugejin = scoped_player(self,"fcj_huanshiFrom")

    local cmp = function(a,b)
        local a_keep_value,b_keep_value = sgs.ai_keep_value[a:getClassName()] or 0,sgs.ai_keep_value[b:getClassName()] or 0
        a_keep_value = a_keep_value+a:getNumber()/100
        b_keep_value = b_keep_value+b:getNumber()/100
        if zhugejin and zhugejin:hasSkill("fcj_mingzhe") then
            if a:isRed() then a_keep_value = a_keep_value-0.3 end
            if b:isRed() then b_keep_value = b_keep_value-0.3 end
        end
        return a_keep_value<b_keep_value
    end

    local card_id = self:getRetrialCardId(cards,judge,false)
    if card_id~=-1 then return card_id end
    if zhugejin and not self:isEnemy(zhugejin) then
        local valueless = {}
        for _,card in sgs.list(cards)do
            if not source_query(self, "isValuableCard", card, zhugejin) then table.insert(valueless,card) end
        end
        if #valueless==0 then valueless = cards end
        table.sort(valueless,cmp)
        return valueless[1]:getEffectiveId()
    else
        for _,card in sgs.list(cards)do
            if judge:isGood(card) then return card:getKnownEffectiveId() end
        end
        local valuable = {}
        for _,card in sgs.list(cards)do
            if source_query(self, "isValuableCard", card, zhugejin) then table.insert(valuable,card) end
        end
        if #valuable==0 then valuable = cards end
        table.sort(valuable,cmp)
        return valuable[#valuable]:getEffectiveId()
    end
    return -1
end

function sgs.ai_cardneed.fcj_huanshi(to,card,self)
    for _,player in sgs.list(self.friends)do
        if self:getFinalRetrial(to)==1 then
            if source_query(self, "willSkipDrawPhase", player) then
                return card:getSuit()==sgs.Card_Club and not source_query(self, "hasSuit", "club", true, to)
            end
            if source_query(self, "willSkipPlayPhase", player) then
                return card:getSuit()==sgs.Card_Heart and not source_query(self, "hasSuit", "heart", true, to)
            end
        end
    end
end

sgs.ai_skill_invoke["@fcj_hongyuanDC"] = true
sgs.ai_skill_invoke["@fcj_hongyuanGC"] = true

sgs.ai_skill_use["@@fcj_hongyuan"] = function(self, prompt)
    if self.player:getStrategyMark("fcj_hongyuan") < 1 then
        local targets = {}
        if #self.friends_noself == 0 then return "." end
        self:sort(self.friends_noself, "hp")
        for _, friend in ipairs(self.friends_noself) do
            if friend and not table.contains(targets, friend:objectName()) then
                table.insert(targets, friend:objectName())
            end
        end
        if #targets > 0 then
            return "#fcj_hongyuanCard:.:->" .. table.concat(targets, "+")
        end
    else
        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        local targets = self.room:getOtherPlayers(self.player)
        local c,to = self:getCardNeedPlayer(cards, false, targets)
        if c and to then return "#fcj_hongyuanCard:.:->"..to:objectName() end
        for _, friend in ipairs(self.friends_noself) do
            for _,h in sgs.list(self.player:getHandcards())do
                if self:willUse(self.player, h) and source_query(h, "isAvailable", self.player) then continue end
                return "#fcj_hongyuanCard:.:->"..friend:objectName()
            end
        end
    end
    return "."
end
sgs.ai_card_intention["#fcj_hongyuanCard"] = -80

sgs.ai_skill_invoke["@fcj_mingzheGC"] = true
sgs.ai_skill_invoke["@fcj_mingzheLC"] = true



sgs.weapon_range.FcjhqWeapon = 4
sgs.ai_use_priority.FcjhqWeapon = 2.78

sgs.ai_use_priority.FcjhqArmor = 0.99

sgs.need_equip_skill = sgs.need_equip_skill .. "|fcj_qizhou"
ai_audited_aliases.register{id="ai_cardneed.fcj_qizhou",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"fcj_qizhou"},canonical_registry="ai_cardneed",canonical_path={"equip"}}

local fcj_shanxi_skill = {}
fcj_shanxi_skill.name = "fcj_shanxi"
table.insert(sgs.ai_skills, fcj_shanxi_skill)
fcj_shanxi_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#fcj_shanxiCard") or self.player:isNude() or #self.enemies == 0 then return end
    local card_id
    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    if self.player:getHandcardNum() > self.player:getHp() then
        for _, acard in ipairs(cards) do
            if acard:isKindOf("BasicCard") and acard:isRed() and not acard:isKindOf("Peach") then
                card_id = acard:getKnownEffectiveId()
                break
            end
        end
    end
    if not card_id then
        return nil
    else
        return parse_action(self,"#fcj_shanxiCard:"..card_id..":")
    end
end

sgs.ai_skill_use_func["#fcj_shanxiCard"] = function(card, use, self,request)
    if not self.player:getStrategyHasUsed("#fcj_shanxiCard") then
        self:sort(self.enemies)
        self.enemies = sgs.reverse(self.enemies)
        for _, enemy in ipairs(self.enemies) do
            if source_query(self, "objectiveLevel", enemy) > 0 and not enemy:isNude() then
                use.card = card
                if use.to then use.to:append(enemy) end
            return end
        end
    end
end

sgs.ai_use_value.fcj_shanxiCard = 8.5
sgs.ai_use_priority.fcj_shanxiCard = 9.5
sgs.ai_card_intention.fcj_shanxiCard = 80


sgs.ai_skill_invoke.fcj_yimie = function(self, data)
    local target = data:toDamage().to
    if self:cantDamageMore(self.player,target) then return false end
    if target:getHp()<1 then return false end
    return not self:isFriend(target)
end

sgs.ai_card_priority.fcj_tairan = function(self,card)
    if card:getStrategyFlag("fcj_tairanD")
    then
        return 1
    end
end



local fcj_sanchen_skill = {}
fcj_sanchen_skill.name = "fcj_sanchen"
table.insert(sgs.ai_skills, fcj_sanchen_skill)
fcj_sanchen_skill.getTurnUseCard = function(self)
    if self.player:usedTimes("#fcj_sanchenCard") >= 3 or self.player:getStrategyMark("fcj_sanchenBan-SelfClear") > 0 then return end
    return parse_action(self,"#fcj_sanchenCard:.:")
end

sgs.ai_skill_use_func["#fcj_sanchenCard"] = function(card, use, self,request)
    if self.player:usedTimes("#fcj_sanchenCard") < 3 and self.player:getStrategyMark("fcj_sanchenBan-SelfClear") == 0 then
        if self.player:getStrategyMark("&fcj_sanchenThree-Clear") == 0 then
            use.card = card
            if use.to then use.to:append(self.player) end
            return
        end
        self:sort(self.friends_noself)
        for _, friend in ipairs(self.friends_noself) do
            if friend and friend:getStrategyMark("&fcj_sanchenThree-Clear") == 0 and self:canDraw(friend, self.player) then
                use.card = card
                if use.to then use.to:append(friend) end
                return
            end
        end
    end
end

sgs.ai_use_value.fcj_sanchenCard = 8.5
sgs.ai_use_priority.fcj_sanchenCard = 9.5
sgs.ai_card_intention.fcj_sanchenCard = -80


sgs.ai_skill_playerchosen.fcj_jieying = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
        if self:isEnemy(p) then
        return p end
    end
    for _, p in ipairs(targets) do
        if self:isFriend(p) and source_query(self, "needToLoseHp", p) then
        return p end
    end
end
sgs.ai_target_revises.fcj_jieying = function(to,card)
    if card:isKindOf("IronChain")
    then return true end
end



sgs.ai_skill_use["@@fcj_leixiSlash"] = function(self, prompt, method)
    self:updatePlayers()
    self:sort(self.enemies, "defense")
    local ts = clone_preview(self,"thunder_slash", sgs.Card_SuitToBeDecided, -1)
    mutate(self,ts,"skill","fcj_leixi")

    for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
        if c:isBlack() then
            mutate(self,ts,"clear")
            mutate(self,ts,"add",c)
            local dummy_use = use_card(self,ts, dummy())
            local targets = {}
            if not dummy_use.to:isEmpty() then
                for _, p in sgs.qlist(dummy_use.to) do
                    table.insert(targets, p:objectName())
                end
            end
            if #targets > 0 then
                return ts:toString().."->"..table.concat(targets,"+")
            end
        end
    end
    return "."
end

sgs.ai_skill_use["@@fcj_leixiDuel"] = function(self, prompt, method)
    self:updatePlayers()
    self:sort(self.enemies, "defense")
    local duel = clone_preview(self,"duel", sgs.Card_NoSuit, 0)

    mutate(self,duel,"skill","fcj_leixi")
    local dummy_use = use_card(self,duel, dummy())
    local targets = {}
    if not dummy_use.to:isEmpty() then
        for _, p in sgs.qlist(dummy_use.to) do
            table.insert(targets, p:objectName())
        end
    end
    if #targets > 0 then
        return duel:toString().."->"..table.concat(targets,"+")
    end
    return "."
end

sgs.ai_skill_playerchosen.fcj_leixi = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "hp")
    if self.player:getStrategyMark("fcj_leixi") == 3 then
        local max_card = self:getMaxCard()
        local max_point = max_card:getNumber()

        if #self.enemies==0 then return end
        self:sort(self.enemies,"handcard")

        for _,enemy in sgs.list(self.enemies)do
            if source_query(self, "damageIsEffective", enemy, sgs.DamageStruct_Thunder) and not source_query(self, "cantbeHurt", enemy) and source_query(self.player, "canPindian", enemy) then
                local enemy_max_card = self:getMaxCard(enemy)
                local allknown = 0
                if source_query(self, "getKnownNum", enemy)==enemy:getHandcardNum() then
                    allknown = allknown+1
                end
                if (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown>0)
                    or (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown<1 and max_point>10)
                    or (not enemy_max_card and max_point>10) then
                    return enemy
                end
            end
        end
    end
    for _, p in ipairs(targets) do
        if self:isEnemy(p) and source_query(self, "damageIsEffective", p, sgs.DamageStruct_Thunder) and not source_query(self, "cantbeHurt", p) then
            return p
        end
    end
end
ai_audited_aliases.register{id="ai_cardneed.fcj_leixi",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"fcj_leixi"},canonical_registry="ai_cardneed",canonical_path={"bignumber"}}
sgs.ai_ajustdamage_from.fcj_leixi = function(self,from,to,card,nature)
    if nature == "T"
    then return from:getStrategyMark("&fcj_leixi") end
end

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|fcbyajiao"
sgs.ai_skill_invoke.fcbyajiao = true

sgs.ai_card_intention["fcbyajiaoCard"] = 50
sgs.ai_skill_use["@@fcbyajiao"] = function(self,prompt)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local c,to = self:getCardNeedPlayer(cards)
    if c and to then return "#fcbyajiaoCard:"..c:getKnownEffectiveId()..":->"..to:objectName() end
    for _,friend in ipairs(self.friends_noself)do
        if self:getCardsNum("Jink")>1 then
            for _,card in sgs.qlist(self.player:getHandcards())do
                if isCard("Jink",card,friend) then return "#fcbyajiaoCard:"..card:getKnownEffectiveId()..":->"..friend:objectName() end
            end
        end
        for _,card in sgs.qlist(self.player:getHandcards())do
            if not source_query(self, "isValuableCard", card) then return "#fcbyajiaoCard:"..card:getKnownEffectiveId()..":->"..friend:objectName() end
        end
    end
    return "."
end
sgs.ai_skill_playerchosen.fcbyajiao = function(self,targets)
    return self:findPlayerToDiscard("hej",false,true,targets)[1]
end
sgs.ai_skill_playerchosen.fcbyajiaoequip = function(self,targets)
    local card = scoped_card(self,"fcbyajiaoCard")
    if not card then return false end
    local index = source_query(card, "getEquipSlot")
    for _,friend in ipairs(self.friends)do
        if not source_query(friend, "hasEquipArea", index) then continue end
        if self:loseEquipEffect(friend) then
            return friend
        end
    end
    local target
    for _,friend in ipairs(self.friends)do
        if not source_query(friend, "hasEquipArea", index) then continue end
        if not self:getSameEquip(card,friend) and self:hasSkills(sgs.need_equip_skill.."|"..sgs.lose_equip_skill,friend) then
            return target
        end
        if not source_query(friend, "hasEquipArea", index) then continue end
        if not self:getSameEquip(card,friend) then
            return target
        end
    end
    for _,friend in ipairs(self.friends_noself)do
        if ((card:isKindOf("DefensiveHorse") and friend:getDefensiveHorse())
            or (card:isKindOf("OffensiveHorse") and (friend:getOffensiveHorse() or (friend:hasSkill("drmashu") and friend:getDefensiveHorse()))))
            and not friend:hasSkills(sgs.lose_equip_skill) then
            continue
        end
        if card:isKindOf("Armor") and ((friend:hasSkills("bazhen|yizhong") and not friend:getArmor())
        or (friend:getArmor() and self:evaluateArmor(card)<self:evaluateArmor(friend:getArmor()))) then continue end
        if card:isKindOf("Weapon") and (friend:getWeapon() and self:evaluateArmor(card)<self:evaluateArmor(friend:getWeapon())) then continue end
        return friend
    end

    return nil
end
sgs.ai_playerchosen_intention["fcbyajiaoequip"] = -50

sgs.ai_skill_invoke.fcbpozhen = true

sgs.ai_card_priority.fcbpozhen = function(self,card)
    if table.contains(source_query(card, "getSkillNames"), "longdan")
    then
        if self.useValue
        then return 2 end
        return 0.08
    end
end


sgs.ai_skill_cardchosen.fcbpozhen = function(self,who,flags,method)
    if who and self:isFriend(who) then return -1 end
    for _,e in sgs.list(who:getCards(flags))do
        local id = e:getKnownEffectiveId()
        return id
    end
end


local fcbshenwuVS_skill = {}
fcbshenwuVS_skill.name = "fcbshenwuVS"
table.insert(sgs.ai_skills, fcbshenwuVS_skill)
fcbshenwuVS_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getStrategyFlag("Forbidfcbshenwu") then return nil end
    if self.player:getKnownKingdom() ~= "qun" then return nil end

    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    local card
    self:sortByUseValue(cards, true)
    for _, acard in ipairs(cards) do
        if acard:isKindOf("Slash") or acard:isKindOf("Duel") or acard:isKindOf("Weapon") then
            card = acard
            break
        end
    end
    if not card then return nil end

    local card_id = card:getKnownEffectiveId()
    local card_str = "#fcbshenwuCard:" .. card_id .. ":"
    local skillcard = parse_action(self,card_str)

    assert(skillcard)
    return skillcard
end

sgs.ai_skill_use_func["#fcbshenwuCard"] = function(card, use, self,request)
    if source_query(self, "needBear") or self:getCardsNum("Slash", "h") <= 1 then
        return
    end
    local targets = {}
    for _, friend in ipairs(self.friends_noself) do
        if friend:hasLordSkill("fcbshenwu") then
            if not friend:getStrategyFlag("fcbshenwuInvoked") then
                if not hasManjuanEffect(friend) then
                    table.insert(targets, friend)
                end
            end
        end
    end
    if #targets > 0 then --黄天己方
        use.card = card
        self:sort(targets, "defense")
        if use.to then
            use.to:append(targets[1])
        end
    end
end

sgs.ai_card_intention.fcbshenwuCard = function(self, card, from, tos)
    if tos[1]:isKongcheng() and ((from:hasSkill("tianyi") and not from:getStrategyHasUsed("TianyiCard"))
            or (from:hasSkill("xianzhen") and not from:getStrategyHasUsed("XianzhenCard"))) then
    else
        self:updateIntention(from, tos[1], -80)
    end
end

sgs.ai_use_priority.fcbshenwuCard = 10
sgs.ai_use_value.fcbshenwuCard = 8.5

sgs.ai_use_revises.fcbgaolou = function(self,card,use)
    if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5
    then use.card = card return true end
end


sgs.ai_skill_invoke["sp_yaozhi_ub"] = true

local sp_yaozhi_ub_skill = {}
sp_yaozhi_ub_skill.name = "sp_yaozhi_ub"
table.insert(sgs.ai_skills, sp_yaozhi_ub_skill)
sp_yaozhi_ub_skill.getTurnUseCard = function(self)
    if self.player:getStrategyMark("sp_yaozhi_ubUsed") >= 3 + self.player:getStrategyMark("&sp_yaozhi_ubAdd") then return end
    return parse_action(self,"#sp_yaozhi_ubCard:.:")
end

sgs.ai_skill_use_func["#sp_yaozhi_ubCard"] = function(card, use, self,request)
    if self.player:getStrategyMark("sp_yaozhi_ubUsed") < 3 + self.player:getStrategyMark("&sp_yaozhi_ubAdd") then
        use.card = card
    return end
end

sgs.ai_use_value.sp_yaozhi_ubCard = 8.5
sgs.ai_use_priority.sp_yaozhi_ubCard = 9.5
sgs.ai_card_intention.sp_yaozhi_ubCard = -80



sgs.ai_skill_playerchosen.sp_yaozhi_ub = function(self,targets)
    if self.player:getStrategyMark("@sp_shenqi_ub") > 0 and self.player:hasSkill("sp_shenqi_ub") then
        for _,p in sgs.qlist(targets) do
            if self:isEnemy(p) and not self:cantDamageMore(self.player, p) and not p:getPile("GodIncantation_ub"):isEmpty() then
                return p
            end
        end
        for _,p in sgs.qlist(targets) do
            if self:isEnemy(p) and not self:cantDamageMore(self.player, p) then
                return p
            end
        end
    end
    return nil
end
sgs.ai_skill_playerchosen.sp_yaozhi_ubX = function(self,targets)
    return targets:first()
end

local sp_shenqi_ub_skill = {}
sp_shenqi_ub_skill.name = "sp_shenqi_ub"
table.insert(sgs.ai_skills, sp_shenqi_ub_skill)
sp_shenqi_ub_skill.getTurnUseCard = function(self)
    return parse_action(self,"#sp_shenqi_ubCard:.:")
end

sgs.ai_skill_use_func["#sp_shenqi_ubCard"] = function(card, use, self,request)
    self:sort(self.enemies,"defense")
    local target
    for _,enemy in sgs.list(self.enemies)do
        if not enemy:getPile("GodIncantation_ub"):isEmpty() and enemy:getPile("GodIncantation_ub"):length() > enemy:getHp() and self.player:getMaxHp() > enemy:getPile("GodIncantation_ub"):length() then
            if not source_query(self, "cantbeHurt", enemy) and ((source_query(self, "damageIsEffective", enemy, "N", self.player)) or (source_query(self, "damageIsEffective", enemy, "F", self.player)) or (source_query(self, "damageIsEffective", enemy, "T", self.player)))  and source_query(self, "canDamage", enemy, self.player, nil) and not self:cantDamageMore(self.player, enemy) then
                target = enemy
                break
            end
        end
    end
    if target then
        use.card = parse_action(self,"#sp_shenqi_ubCard:.:")
        use.to:append(target)
        return
    end
end

sgs.ai_use_value.sp_shenqi_ubCard = 9.5
sgs.ai_use_priority.sp_shenqi_ubCard = 3.5
sgs.ai_card_intention.sp_shenqi_ubCard = 70


sgs.ai_skill_choice.sp_shenqi_ub = function(self, choices, data)
    local items = choices:split("+")
    local target = data:toPlayer()
    if target then
        if self:isEnemy(target) then
            return "2"
        end
        if self:isFriend(target) then
            return "1"
        end
    end
    return "2"
end

sgs.ai_skill_choice.sp_shenqi_ub_zhuxie = function(self, choices, data)
    local items = choices:split("+")
    local target = data:toPlayer()
    if target then
        if self:isEnemy(target) then
            if (source_query(self, "damageIsEffective", target, "F", self.player)) then
                return "fire"
            end
            if (source_query(self, "damageIsEffective", target, "N", self.player)) then
                return "normal"
            end

            if (source_query(self, "damageIsEffective", target, "T", self.player)) then
                return "thunder"
            end
        end
    end
    return "normal"
end



addAiSkills("f_huishi").getTurnUseCard = function(self)
    return parse_action(self,"#f_huishiCard:.:")
end

sgs.ai_skill_use_func["#f_huishiCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value.f_huishiCard = 8.4
sgs.ai_use_priority.f_huishiCard = 8.4

sgs.ai_skill_invoke["@f_huishi_continue"] = function(self,data)
    return true
end

sgs.ai_skill_playerchosen.f_huishi = function(self,players)
    players = self:sort(players,"handcard")
    for _,target in sgs.list(players)do
        if self:isFriend(target)
        then
            return target
        end
    end
end


sgs.ai_skill_choice["@f_huishiAdd"] = function(self, choices, data)
    local items = choices:split("+")
    if self.player:isWounded() then
        return "hp"
    end
    return "mhp"
end
sgs.ai_skill_choice["@f_huishiLose"] = function(self, choices, data)
    if sgs.ai_skill_choice.benghuai == "maxhp" then
        return "mhp"
    end
    return "hp"
end
sgs.ai_skill_invoke.f_tianzuo = true


local imba_skill = {}
imba_skill.name = "imba"
table.insert(sgs.ai_skills, imba_skill)
imba_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#imbaCard") and self.player:getMaxHp() <= 2 then return end
    return parse_action(self,"#imbaCard:.:")
end

sgs.ai_skill_use_func["#imbaCard"] = function(card, use, self,request)
    self:sort(self.enemies,"hp")
    for _,ep in sgs.list(self.enemies)do
        if ep:isWounded()
        or ep:getMaxHp()<2
        then continue end
        use.card = card
        use.to:append(ep)
        return
    end
    self:sort(self.enemies,"hp",true)
    for _,ep in sgs.list(self.enemies)do
        if ep:getMaxHp()<2
        then continue end
        use.card = card
        use.to:append(ep)
        return
    end
end

sgs.ai_use_value.imbaCard = 8.5
sgs.ai_use_priority.imbaCard = 9.5
sgs.ai_card_intention.imbaCard = 80


addAiSkills("tyshouli").getTurnUseCard = function(self)
    local cards = {}
    for i,p in sgs.list(self.room:getAlivePlayers())do
        for d,c in sgs.list(p:getCards("ej"))do
            if c:isKindOf("OffensiveHorse")
            then table.insert(cards,c) end
        end
    end
    self:sortByKeepValue(cards,nil,"l")
    for _,c in sgs.list(cards)do
        local dc = preview(self)
        mutate(self,dc,"skill","tyshouli")
        mutate(self,dc,"add",c)
        local d = use_card(self,dc)
        if d.card and d.to
        and source_query(dc, "isAvailable", self.player)
        then
            set_state(self,"tyshouli_to",d.to)
            self:setPriorityValue("tyshouli",self:getPriorityValue("Slash")+0.6,"fcDIY")
            return parse_action(self,"#tyshouli:"..c:getKnownEffectiveId()..":slash")
        end
    end
end

sgs.ai_skill_use_func["tyshouli"] = function(card,use,self,request)
    if get_state(self,"tyshouli_to")
    then
        use.card = card
        use.to = get_state(self,"tyshouli_to")
    end
end

sgs.ai_use_value.tyshouli = 5.4
sgs.ai_use_priority.tyshouli = 2.8


sgs.ai_card_priority.tyshouli = function(self,card)
    if table.contains(source_query(card, "getSkillNames"), "tyshouli")
    then
        if self.useValue
        then return 1 end
        return 0.08
    end
end

sgs.ai_guhuo_card.tyshouli = function(self,toname,class_name)
    local cards = {}
    for _,p in sgs.list(self.room:getAlivePlayers())do
        for _,c in sgs.list(p:getCards("ej"))do
            if c:isKindOf("OffensiveHorse") and class_name=="Slash"
            or c:isKindOf("DefensiveHorse") and class_name=="Jink"
            then table.insert(cards,c) end
        end
    end
    self:sortByKeepValue(cards,nil,"l")
    for _,c in sgs.list(cards)do
        if self:getCardsNum(class_name)>0 then break end
        return "#tyshouli:"..c:getKnownEffectiveId()..":"..toname
    end
end




local tycuijue_skill = {}
tycuijue_skill.name = "tycuijue"
table.insert(sgs.ai_skills, tycuijue_skill)
tycuijue_skill.getTurnUseCard = function(self, inclusive)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    if not cards[1] then return nil end
    return parse_action(self,"#tycuijueCard:" .. cards[1]:getEffectiveId() .. ":")
end

sgs.ai_skill_use_func["#tycuijueCard"] = function(card, use, self,request)
    local target = nil
    self:updatePlayers()
    self:sort(self.enemies, "handcard")
    local distance = 0
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if source_query(self.player, "inMyAttackRange", p) then
            if source_query(self.player, "distanceTo", p) > distance then
                distance = source_query(self.player, "distanceTo", p)
            end
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if source_query(self, "damageIsEffective", enemy, sgs.DamageStruct_Normal) and not source_query(self, "cantbeHurt", enemy) and source_query(self, "canDamage", enemy, self.player, nil) and source_query(self.player, "distanceTo", enemy) == distance and enemy:getStrategyMark("tycuijueTarget-Clear") == 0 then
            target = enemy
            break
        end
    end
    if target then
    use.card = card
    if use.to then use.to:append(target) end
    end
end
sgs.ai_card_intention["tycuijueCard"] = 80


sgs.ai_skill_invoke.wxqixingEX = true

local wxjifengEX_skill = {}
wxjifengEX_skill.name = "wxjifengEX"
table.insert(sgs.ai_skills, wxjifengEX_skill)
wxjifengEX_skill.getTurnUseCard = function(self)
    if self.player:isKongcheng() then return end
    local card_id
    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _, acard in ipairs(cards) do
        if (not acard:isKindOf("TrickCard") and not acard:isKindOf("Peach")) or acard:isKindOf("Nullification") then
            card_id = acard:getKnownEffectiveId()
            break
        end
    end
    if not card_id then
        return nil
    else
        return parse_action(self,"#wxjifengEXCard:"..card_id..":")
    end
end

sgs.ai_skill_use_func["#wxjifengEXCard"] = function(card, use, self,request)
    use.card = card
    return
end

sgs.ai_use_value.wxjifengEXCard = 8.5
sgs.ai_use_priority.wxjifengEXCard = 9.5

sgs.ai_skill_use["@@wxtianzuiEX"] = function(self, prompt)
    local targets, exZUI = {}, self.player:getStrategyMark("&exZUI")
    if exZUI == 0 then return "." end

    self:sort(self.friends_noself)
    for _, friend in ipairs(self.friends_noself) do
        if source_query(self, "doDisCard", friend, "hej") then
            table.insert(targets, friend:objectName())
            if #targets >= exZUI then
                break
            end
        end
    end
    if #self.enemies > 0 then --再拆对手
        self:sort(self.enemies, "defense")
        for _, enemy in ipairs(self.enemies) do
            if source_query(self, "doDisCard", enemy, "hej")  then
                table.insert(targets, enemy:objectName())
                if #targets >= exZUI then
                    break
                end
            end
        end
    end
    if #targets > 0 then
        return "#wxtianzuiEXCard:.:->" .. table.concat(targets, "+")
    end
    return "."
end

sgs.ai_skill_use["@@wxtianfaEX"] = function(self, prompt)
    local targets, exFA = {}, self.player:getStrategyMark("&exFA")
    if #self.enemies == 0 or exFA == 0 then return "." end
    self:sort(self.enemies, "hp")
    for _, enemy in ipairs(self.enemies) do
        if source_query(self, "objectiveLevel", enemy) > 0 and source_query(self, "damageIsEffective", enemy, sgs.DamageStruct_Thunder) and not source_query(self, "cantbeHurt", enemy) and source_query(self, "canDamage", enemy, self.player, nil)  then
            table.insert(targets, enemy:objectName())
            if #targets >= exFA then
                break
            end
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if #targets >= exFA then
            break
        end
        if source_query(self, "damageIsEffective", friend, sgs.DamageStruct_Thunder) and source_query(self, "canDamage", friend, self.player, nil)  then
            table.insert(targets, friend:objectName())
        end
    end
    if #targets > 0 then
        return "#wxtianfaEXCard:.:->" .. table.concat(targets, "+")
    end
    return "."
end

sgs.ai_ajustdamage_from.fcmouliegong = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") then
        local record = property_value(self,from,"fcmouliegongRecords")
        local records = {}
        if (record) then
            records = record:split(",")
        end
        if #records >= 3 then
            return 1
        end
    end
end

sgs.ai_canliegong_skill.fcmouliegong = function(self, from, to)
    local record = property_value(self,from,"fcmouliegongRecords")
    local records = {}
    if record then
        records = record:split(",")
    end
    return #records >= 2
end


sgs.ai_view_as.fcmouwusheng = function(card, player, card_place)
    local suit = card:getSuitString()
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    if card_place ~= sgs.Player_PlaceSpecial and card:isRed() and not card:isKindOf("Peach") and not card:getStrategyFlag("using") then
        return ("slash:fcmouwusheng[%s:%s]=%d"):format(suit, number, card_id)
    end
end

local fcmouwusheng_skill = {}
fcmouwusheng_skill.name = "fcmouwusheng"
table.insert(sgs.ai_skills, fcmouwusheng_skill)
fcmouwusheng_skill.getTurnUseCard = function(self, inclusive)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    local red_card
    self:sortByUseValue(cards, true)
    local useAll = false
    self:sort(self.enemies, "defense")
    for _, enemy in ipairs(self.enemies) do
        if enemy:getHp() == 1 and not source_query(enemy, "hasArmorEffect", "EightDiagram") and source_query(self.player, "distanceTo", enemy) <= source_query(self.player, "getAttackRange") and self:isWeak(enemy)
            and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
            useAll = true
            break
        end
    end
    local disCrossbow = false
    if self:getCardsNum("Slash") < 2 or self.player:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao") then
        disCrossbow = true
    end
    local nuzhan_equip = false
    local nuzhan_equip_e = false
    self:sort(self.enemies, "defense")
    if self.player:hasSkill("nuzhan") then
        for _, enemy in ipairs(self.enemies) do
            if  not source_query(enemy, "hasArmorEffect", "EightDiagram") and source_query(self.player, "distanceTo", enemy) <= source_query(self.player, "getAttackRange")
            and getCardsNum("Jink", enemy) < 1 then
                nuzhan_equip_e = true
                break
            end
        end
        for _, card in ipairs(cards) do
            if card:isRed() and card:isKindOf("TrickCard") and nuzhan_equip_e then
                nuzhan_equip = true
                break
            end
        end
    end
    local nuzhan_trick = false
    local nuzhan_trick_e = false
    self:sort(self.enemies, "defense")
    if self.player:hasSkill("nuzhan") and not self.player:getStrategyFlag("hasUsedSlash") and self:getCardsNum("Slash") > 1 then
        for _, enemy in ipairs(self.enemies) do
            if  not source_query(enemy, "hasArmorEffect", "EightDiagram") and source_query(self.player, "distanceTo", enemy) <= source_query(self.player, "getAttackRange") then
                nuzhan_trick_e = true
                break
            end
        end
        for _, card in ipairs(cards) do
            if card:isRed() and card:isKindOf("TrickCard") and nuzhan_trick_e then
                nuzhan_trick = true
                break
            end
        end
    end
    for _, card in ipairs(cards) do
        if card:isRed() and not card:isKindOf("Slash") and not (nuzhan_equip or nuzhan_trick)
            and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
            and (not isCard("Crossbow", card, self.player) or disCrossbow)
            and (source_query(self, "getUseValue", card) < sgs.ai_use_value.Slash or inclusive or source_query(preview(self), "getTargetModResidue", self.player) > 0) then
            red_card = card
            break
        end
    end
    if nuzhan_equip then
        for _, card in ipairs(cards) do
            if card:isRed() and card:isKindOf("EquipCard") then
                red_card = card
                break
            end
        end
    end
    if nuzhan_trick then
        for _, card in ipairs(cards) do
            if card:isRed() and card:isKindOf("TrickCard") then
                red_card = card
                break
            end
        end
    end
    if red_card then
        local suit = red_card:getSuitString()
        local number = source_query(red_card, "getNumberString")
        local card_id = red_card:getKnownEffectiveId()
        local card_str = ("slash:fcmouwusheng[%s:%s]=%d"):format(suit, number, card_id)
        local slash = parse_action(self,card_str)
        assert(slash)
        return slash
    end
end

function sgs.ai_cardneed.fcmouwusheng(to, card)
    return card:isRed() --鼓励使用，因为都有加成效果
end

local fcmouyijue_skill = {}
fcmouyijue_skill.name = "fcmouyijue"
table.insert(sgs.ai_skills, fcmouyijue_skill)
fcmouyijue_skill.getTurnUseCard = function(self)
    if self.player:getStrategyHasUsed("#fcmouyijueCard") or self.player:isNude() or #self.enemies == 0 then return end
    local card_id
    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    if source_query(self, "needToThrowArmor") then
        card_id = self.player:getArmor():getId()
    elseif self.player:getHandcardNum() > self.player:getHp() then
        for _, acard in ipairs(cards) do
            if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
                and not acard:isKindOf("Peach") then
                card_id = acard:getKnownEffectiveId()
                break
            end
        end
    elseif not self.player:getEquips():isEmpty() then
        local player = self.player
        if player:getWeapon() then card_id = player:getWeapon():getId()
        elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
        elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
        elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
        end
    end
    if not card_id then
        for _, acard in ipairs(cards) do
            if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
                and not acard:isKindOf("Peach") then
                card_id = acard:getKnownEffectiveId()
                break
            end
        end
    end
    if not card_id then
        return nil
    else
        return parse_action(self,"#fcmouyijueCard:"..card_id..":")
    end
end

sgs.ai_skill_use_func["#fcmouyijueCard"] = function(card, use, self,request)
    if not self.player:getStrategyHasUsed("#fcmouyijueCard") then
        self:sort(self.enemies)
        self.enemies = sgs.reverse(self.enemies)
        for _, enemy in ipairs(self.enemies) do
            if source_query(self, "objectiveLevel", enemy) > 0 then
                use.card = card
                if use.to then use.to:append(enemy) end
                return
            end
        end
    end
end

sgs.ai_use_value.fcmouyijueCard = 8.5
sgs.ai_use_priority.fcmouyijueCard = 9.5
sgs.ai_card_intention.fcmouyijueCard = 80


sgs.ai_ajustdamage_from.fcmouwusheng = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and card:getSuit() == sgs.Card_Heart then
        return 1
    end
end

sgs.ai_ajustdamage_from.fcmouyijue = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and to:getStrategyMark("&fcmouyijue") > 0 and card:isRed() then
        return 1
    end
end

sgs.ai_skill_invoke.fcmoutieqii = function(self, data)
    local target = data:toPlayer()
    return not self:isFriend(target)
end

sgs.ai_ajustdamage_from.fcmoutieqii = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and card:getStrategyFlag("fcmoutieqii_successDMG") then
        return 1
    end
end


local mouduanliangg_skill = {}
mouduanliangg_skill.name = "mouduanliangg"
table.insert(sgs.ai_skills, mouduanliangg_skill)
mouduanliangg_skill.getTurnUseCard = function(self)
    if self.player:usedTimes("#mouduanlianggCard") >= 2 then return end
    return parse_action(self,"#mouduanlianggCard:.:")
end

sgs.ai_skill_use_func["#mouduanlianggCard"] = function(card, use, self,request)
    self:sort(self.enemies)
    self.enemies = sgs.reverse(self.enemies)
    local shortage = clone_preview(self,"supply_shortage", card:getSuit(), card:getNumber())
    mutate(self,shortage,"skill","mouduanliangv")

    local duel = clone_preview(self,"duel", sgs.Card_NoSuit, 0)
    mutate(self,duel,"skill","mouduanliangv")

    local dummy_use = use_card(self,shortage, dummy())
    if dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            use.card = card
            if use.to then use.to:append(to) end
            return
        end
    end
    local dummy_use = use_card(self,duel, dummy())
    if dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            use.card = card
            if use.to then use.to:append(to) end
            return
        end
    end


end

sgs.ai_use_value.mouduanlianggCard = 8.5
sgs.ai_use_priority.mouduanlianggCard = 9.5
sgs.ai_card_intention.mouduanlianggCard = 80

sgs.ai_skill_invoke.moushipoo = true

sgs.ai_skill_playerchosen.moushipoo = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
        if self:isEnemy(p) then
            return p
        end
    end
end

sgs.ai_skill_choice.moushipoo = function(self, choices, data)
    if self.player:isKongcheng() then return "3" end
    if self.player:getHp() <= 1 and self.player:getHandcardNum() <= 1
    and (self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0)
    then return "4" end
    if self.player:getHp() <= 1 then return "3" end
    return "4"
end

sgs.ai_skill_discard.moushipoo = function(self) --给牌
    local to_discard = {}
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    table.insert(to_discard, cards[1]:getEffectiveId())
    return to_discard
end



sgs.ai_skill_invoke.kjmoushifeng = true
sgs.ai_skill_invoke.kjmoulijin = true

sgs.ai_skill_use["@@kjmoushifeng"] = function(self, prompt)
    local slash = clone_preview(self,"slash", sgs.Card_NoSuit, 0)

    mutate(self,slash,"skill","kjmoushifeng")
    local dummy_use = use_card(self,slash, dummy(true))
    if dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return slash:toString().."->"..table.concat(tos, "+")
    end
    return "."
end

sgs.ai_skill_choice.kjmoujuezhan = function(self, choices, data)
    if self.player:isWounded() and self.player:getHp() <= 1 and self.player:getHandcardNum() > 1 then return "1" end
    return "2"
end

sgs.ai_skill_choice.kjmoulijin = function(self, choices, data)
    if self.player:isWounded() and self.player:getHp() <= 1 and source_query(self.player, "getHujia") == 0
    and self.player:getHandcardNum() - self.player:getHp() <= 1 then return "discard" end
    if self.player:getHandcardNum() <= 2 then return "draw" end
    return "play"
end

sgs.ai_skill_playerchosen.kjmoulijin = function(self, targets)
    for _, enemy in ipairs(self.enemies) do
        if source_query(self, "doDisCard", enemy, "he") then
            return enemy
        end
    end
    return targets:first()
end



addAiSkills("fcmoutiaoxin").getTurnUseCard = function(self)
    return parse_action(self,"#fcmoutiaoxinCard:.:")
end

sgs.ai_skill_use_func["#fcmoutiaoxinCard"] = function(card,use,self,request)
    local distance = use.DefHorse and 1 or 0
    local targets = {}
    for _,enemy in ipairs(self.enemies)do
        if source_query(self, "doDisCard", enemy, "he", true) and self:isTiaoxinTarget(enemy)
        then table.insert(targets,enemy)
            if #targets>=self.player:getStrategyMark("&charge_num") then
                break
            end
        end
    end

    if #targets==0 then return end

    self:setPriorityValue("fcmoutiaoxinCard",8,"fcDIY")
    if not self.player:getArmor() and not self.player:isKongcheng() then
        for _,card in sgs.qlist(self.player:getCards("h"))do
            if card:isKindOf("Armor") and self:evaluateArmor(card)>3 then
                self:setPriorityValue("fcmoutiaoxinCard",5.9,"fcDIY")
                break
            end
        end
    end
    if #targets>0 then
        self:sort(targets,"defenseSlash")
        for i = 1, #targets, 1 do
            use.to:append(targets[i])
        end
        use.card = parse_action(self,"#fcmoutiaoxinCard:.:")
    end
end

ai_audited_aliases.register{id="ai_card_intention.fcmoutiaoxinCard",defer_canonical=true,self_index=1,registry="ai_card_intention",path={"fcmoutiaoxinCard"},canonical_registry="ai_card_intention",canonical_path={"TiaoxinCard"}}
sgs.ai_use_priority.fcmoutiaoxinCard = sgs.ai_use_priority.TiaoxinCard

sgs.ai_skill_invoke.fcmzj_yaozhi = true

sgs.ai_skill_invoke.fcmzj_jiezhuangshen = true

sgs.ai_skill_playerchosen.fcmzj_jiezhuangshen = function(self, targets)
    targets = sgs.QList2Table(targets)
    return targets[math.random(1, #targets)]
end

sgs.ai_skill_choice.fcmzj_jiezhuangshen = function(self,choices,data)
    local player = data:toPlayer()
    local skills = choices:split("+")


    for _,sk in sgs.list(skills)do
        if self:isValueSkill(sk,player,true) then
            return sk
        end
    end

    for _,sk in sgs.list(skills)do
        if self:isValueSkill(sk,player) then
            return sk
        end
    end

    local not_bad_skills = {}
    for _,sk in sgs.list(skills)do
        if string.find(sgs.bad_skills,sk) then continue end
        table.insert(not_bad_skills,sk)
    end
    if #not_bad_skills>0 then
        return not_bad_skills[math.random(1,#not_bad_skills)]
    end

    return skills[math.random(1,#skills)]
end

sgs.ai_skill_playerchosen.fcmzj_jiezhuangshenbuff = function(self, targets)
    local cardstr = sgs.ai_skill_use["@@dawu"](self, "@dawu")
    if cardstr:match("->") then
        local targetstr = cardstr:split("->")[2]:split("+")
        if #targetstr > 0 then
            local target = self.room:findPlayerByObjectName(targetstr[1])
            return target
        end
    end
    local cardstr = sgs.ai_skill_use["@@kuangfeng"](self, "@kuangfeng")
    if cardstr:match("->") then
        local targetstr = cardstr:split("->")[2]:split("+")
        if #targetstr > 0 then
            local target = self.room:findPlayerByObjectName(targetstr[1])
            return target
        end
    end
    return self.player
end

sgs.ai_skill_choice.fcmzj_jiezhuangshenbuff = function(self,choices,data)
    local player = data:toPlayer()
    if self:isFriend(player) then
        return "dwg"
    else
        return "kfc"
    end

    return "kfc"
end


sgs.ai_skill_playerschosen.fcmoujiang = function(self, targets)
    if self.player:getHp() + source_query(self, "getAllPeachNum") - 1 <= 0 then
        return {}
    end
    targets = sgs.QList2Table(targets)
    local tos = {}
    local use = scoped_struct(self,"fcmoujiang","use")
    local dummy_use = scoped_use_card(self,"fcmoujiang",use.card, dummy(true, math.min(self.player:getHp()-1, 2), use.to))
    if not dummy_use.to:isEmpty() then
        for _, p in sgs.qlist(dummy_use.to) do
            if table.contains(targets,p) then
                table.insert(tos,p)
            end
        end
    end
    return tos
end

sgs.ai_card_priority.fcmoujiang = function(self,card)
    if card:isKindOf("Slash") and card:isRed()
    then return 0.05 end
end

sgs.ai_canNiepan_skill.fcmouhunzi = function(player)
    return player:getStrategyMark("fcmouhunzi") == 0
end


local fcmouzhiba_skill = {}
fcmouzhiba_skill.name = "fcmouzhiba"
table.insert(sgs.ai_skills, fcmouzhiba_skill)
fcmouzhiba_skill.getTurnUseCard = function(self)
    if self:getOverflow() > 0 then
        return parse_action(self,"#fcmouzhibaCard:.:")
    end
end

sgs.ai_skill_use_func["#fcmouzhibaCard"] = function(card, use, self,request)

    self:sort(self.enemies, "handcard")
    self.enemies = sgs.reverse(self.enemies)
    for _, enemy in ipairs(self.enemies) do --先找体力值和手牌数都只有1的
        if not enemy:isKongcheng() and source_query(self, "objectiveLevel", enemy) > 0 and enemy:getHp() == 1 and enemy:getHandcardNum() == 1 and source_query(self.player, "canPindian", enemy) then
            use.card = card
            if use.to then
            use.to:append(enemy) end
            return
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if not enemy:isKongcheng() and source_query(self, "objectiveLevel", enemy) > 0 and source_query(self.player, "canPindian", enemy) then
            use.card = card
            if use.to then
            use.to:append(enemy) end
            return
        end
    end

end

sgs.ai_use_value.fcmouzhibaCard = 8.5
sgs.ai_use_priority.fcmouzhibaCard = sgs.ai_use_priority.Dismantlement
sgs.ai_card_intention.fcmouzhibaCard = 80



sgs.ai_skill_invoke.fcmhz_yinhun = function(self,data)
    return true
end

sgs.ai_skill_playerchosen.fcmhz_yinhun = function(self, targets)
    for _, enemy in ipairs(self.enemies) do
        if (source_query(enemy, "isLord") and self.player:getJudgingArea():length() >= 2) or not source_query(enemy, "isLord") then
            return enemy
        end
    end
    return targets:first()
end
sgs.ai_playerchosen_intention.fcmhz_yinhun = 80



sgs.ai_skill_invoke.ahmoukuangfu = true


sgs.ai_skill_playerchosen.ahmoukuangfu = function(self, targets)
    local targets = sgs.QList2Table(targets)
    self:sort(self.friends_noself)
    for _, p in ipairs(self.friends_noself) do
        if self:isFriend(p) and p:getHandcardNum() < p:getHp() and (p:hasSkill("olwushen") or p:hasSkill("tyshencai") or p:hasSkill("tyxunshi")
        or p:hasSkill("newlonghun") or p:hasSkill("mrds_longhun") or p:hasSkill("gdlonghun") or p:hasSkill("xj_longhun")
        or p:hasSkill("mouliegongg") or p:hasSkill("jlsgliegong") or p:hasSkill("f_kaigong") or p:hasSkill("f_gonghun")
        or p:hasSkill("tyshouli") or p:hasSkill("tyhengwu") or p:hasSkill("shouli") or p:hasSkill("hengwu")) then -- 六 星 耀 帝 ！
            return p
        end
    end
    return self.player
end

sgs.ai_skill_invoke["@ahmoushizhi_ZHI"] = function(self,data)
    return sgs.ai_skill_use["@@ahmoushizhi_zhi"](self, "") ~= "."
end
sgs.ai_skill_invoke["@ahmoushizhi_SHI"] = function(self,data)
    return sgs.ai_skill_use["@@ahmoushizhi_shi"](self, "") ~= "."
end
sgs.ai_skill_use["@@ahmoushizhi_zhi"] = function(self, prompt)
    local targets = {}
    self:sort(self.enemies,"handcard", true)
    for _,enemy in ipairs(self.enemies)do
        table.insert(targets, enemy:objectName())
        if #targets >= 2 then break end
    end
    if #targets > 0 then
        return "#ahmoushizhi_zhiCard:.:->" .. table.concat(targets, "+")
    end
    return "."
end
sgs.ai_card_intention["#ahmoushizhi_zhiCard"] = 100
sgs.ai_skill_use["@@ahmoushizhi_shi"] = function(self, prompt)
    local targets, xingfu, hanshi = {}, #self.friends_noself, 0
    if #self.friends_noself < 2 then return "." end
    self:sort(self.friends_noself)
    for _, friend in ipairs(self.friends_noself) do
        if xingfu > 0 and hanshi < 4 and not self:needKongcheng(friend, true) then
            table.insert(targets, friend:objectName())
            xingfu = xingfu - 1
            hanshi = hanshi + 1
        end
    end
    if #targets > 0 then
        return "#ahmoushizhi_shiCard:.:->" .. table.concat(targets, "+")
    end
    return "."
end

sgs.ai_card_intention["#ahmoushizhi_shiCard"] = -100

sgs.ai_skill_use["@@ahmoutaozei_tm"] = function(self, prompt)
    local pattern = property_value(self,self.player,"ahmoutaozei_tm")
    local cd = clone_preview(self,pattern, sgs.Card_NoSuit, 0)
    mutate(self,cd,"skill","ahmoutaozei")

    local dummy_use = use_card(self,cd, dummy())
    if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return cd:toString().."->"..table.concat(tos, "+")
    elseif dummy_use.card then
        return cd:toString()
    end
    return "."
end
sgs.ai_skill_use["@@ahmoutaozei"] = function(self, prompt)
    local use = scoped_struct(self,"ahmoutaozei","use")
    if use.from and self:isEnemy(use.from) then return "#ahmoutaozeiCard:.:" end
    return "."
end



sgs.ai_skill_invoke.fcmouguanxing = function(self, data)
    local current = self.room:getCurrent()
    if self.player:getStrategyMark("&fcmouguanxing") <= 1 and current:objectName() ~= self.player:objectName() then return false end --要是自己还剩1个标记还在别人回合观星，技能就直接废了
    if (self:isFriend(current) or self:isEnemy(current)) and current:getJudgingAreaID():length() > 0 then return true end
    if math.random() > 0.9 and self.player:getStrategyMark("&fcmouguanxing") < 5 then return true end
    if math.random() > 0.5 then return true end
    return current:objectName() == self.player:objectName() --还是偏无脑
end

sgs.ai_skill_invoke["fcmoukongchengMY"] = function(self, data)
    local target = data:toCardUse().from
    return not self:isFriend(target)
end
sgs.ai_ajustdamage_to.fcmoukongcheng = function(self, from, to, card, nature)
    if to:isKongcheng() and card and (card:isKindOf("Slash") or card:isKindOf("Duel"))
    then
        return -99
    end
end


local fcmoumingce_skill = {}
fcmoumingce_skill.name = "fcmoumingce"
table.insert(sgs.ai_skills, fcmoumingce_skill)
fcmoumingce_skill.getTurnUseCard = function(self)
    if self.player:isNude() or #self.enemies == 0 then return end
    local can_use = false
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if self:isFriend(p) and not p:getStrategyFlag("fcmoumingced") then
            can_use = true
        end
    end
    if not can_use then return end
    local card_id
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    if source_query(self, "needToThrowArmor") then
        card_id = self.player:getArmor():getId()
    elseif self.player:getHandcardNum() > self.player:getHp() then
        for _, acard in ipairs(cards) do
            if acard:isKindOf("EquipCard") or acard:isKindOf("Peach") or acard:isKindOf("Analeptic") then
                card_id = acard:getKnownEffectiveId()
                break
            end
        end
    elseif not self.player:getEquips():isEmpty() then
        local player = self.player
        if player:getWeapon() then card_id = player:getWeapon():getId()
        elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
        elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
        elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
        end
    end
    if not card_id then
        for _, acard in ipairs(cards) do
            if acard:isKindOf("EquipCard") or acard:isKindOf("Peach") or acard:isKindOf("Analeptic") then
                card_id = acard:getKnownEffectiveId()
                break
            end
        end
    end
    if not card_id then
        for _, acard in ipairs(cards) do
            if acard:isKindOf("BasicCard") then
                card_id = acard:getKnownEffectiveId()
                break
            end
        end
    end
    if not card_id then
        return nil
    else
        return parse_action(self,"#fcmoumingceCard:"..card_id..":")
    end
end

sgs.ai_skill_use_func["#fcmoumingceCard"] = function(card, use, self,request)
    if not self.player:getStrategyHasUsed("#fcmoumingceCard") and not self.player:isNude() then
        self:sort(self.friends_noself)
        for _, friend in ipairs(self.friends_noself) do --优先考虑手牌少的
            if friend and friend:getHandcardNum() < 2 and not self:needKongcheng(friend, true) and not friend:getStrategyFlag("fcmoumingced") then
                use.card = card
                if use.to then use.to:append(friend) end
                return
            end
        end
        for _, friend in ipairs(self.friends_noself) do
            if friend and not self:needKongcheng(friend, true) and not friend:getStrategyFlag("fcmoumingced") then
                use.card = card
                if use.to then use.to:append(friend) end
                return
            end
        end
    end
    return nil
end

sgs.ai_skill_choice["fcmoumingce"] = function(self, choices, data)
    local current = self.room:getCurrent()
    if self:isEnemy(current) then return "2" end
    if self.player:getHp() <= 1 and not self.player:hasSkill("buqu") then return "2" end
    return "1"
end

sgs.ai_use_value.fcmoumingceCard = 8.5
sgs.ai_use_priority.fcmoumingceCard = 9.5
sgs.ai_card_intention.fcmoumingceCard = -80

sgs.ai_skill_invoke["fcmoumingce"] = true

sgs.ai_skill_playerchosen["fcmoumingce"] = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
        if self:isEnemy(p) and self.player:getStrategyMark("&fcmCe") >= p:getHp() + source_query(p, "getHujia") and not self:cantDamageMore(self.player, p) and not source_query(self, "cantbeHurt", p) and source_query(self, "canDamage", p, self.player, nil) then --优先考虑有机会斩杀的
            return p
        end
    end
    for _, p in ipairs(targets) do
        if self:isEnemy(p)  and source_query(self, "canDamage", p, self.player, nil) then
            return p
        end
    end
    return nil
end

sgs.ai_ajustdamage_to["&fcmouzhichi"] = function(self,from,to,card,nature)
    return -99
end



sgs.ai_skill_invoke.ahmoubaifu = true

sgs.ai_ajustdamage_from.ahmouwushuang = function(self, from, to, card, nature)
    if card and source_query(card, "isDamageCard") and not card:getStrategyFlag("ahmouwushuang"..to:objectName())
    then
        return 1
    end
end



addAiSkills("f_kuzha").getTurnUseCard = function(self)
    if self.player:getMaxHp() <= 2 then return end
    return parse_action(self,"#f_kuzhaCard:.:")
end

sgs.ai_skill_use_func["#f_kuzhaCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value.f_kuzhaCard = 8.4
sgs.ai_use_priority.f_kuzhaCard = 8.4


sgs.ai_ajustdamage_from.f_shenxianshizu = function(self,from,to,card,nature)
    if nature == "F" and to:getStrategyMark("zbkcTarget+to+"..from:objectName().."-Clear") > 0 then
        return 1
    end
end

local f_shenxianshizu_skill = {}
f_shenxianshizu_skill.name = "f_shenxianshizu"
table.insert(sgs.ai_skills,f_shenxianshizu_skill)
f_shenxianshizu_skill.getTurnUseCard = function(self)
    if self.player:getHandcardNum() > 3 then return end
    if #self.enemies<=0 then return end
    for _,enemy in sgs.list(self.enemies)do
        if self:damageMinusHp(enemy,1)>0
        or enemy:getHp()<3 and self:damageMinusHp(enemy,0)>0 and enemy:getHandcardNum()>0
        then
            return parse_action(self,"#f_shenxianshizuCard:.:")
        end
    end
    if (#self.friends>1) or (#self.enemies==1 and source_query(self.room, "getTurnCount")>1) then
        if self.role=="rebel" then
            return parse_action(self,"#f_shenxianshizuCard:.:")
        end
    end
end

sgs.ai_skill_use_func["#f_shenxianshizuCard"] = function(card,use,self,request)
    self:sort(self.enemies,"defenseSlash")
    for _,enemy in sgs.list(self.enemies)do
        if self:damageMinusHp(enemy,1)>0
        or enemy:getHp()<3 and self:damageMinusHp(enemy,0)>0 and enemy:getHandcardNum()>0
        then
            use.card = card
            use.to:append(enemy)
            return
        end
    end
end

sgs.ai_use_priority["f_shenxianshizuCard"] = 10


local f_liaodu_skill = {}
f_liaodu_skill.name = "f_liaodu"
table.insert(sgs.ai_skills,f_liaodu_skill)
f_liaodu_skill.getTurnUseCard = function(self)
    if self.player:getHandcardNum()<1 then return nil end

    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    local use_cards = {}
    local compare_func = function(a,b)
        local v1 = source_query(self, "getKeepValue", a)+( a:isRed() and 50 or 0 )+( a:isKindOf("Peach") and 50 or 0 )
        local v2 = source_query(self, "getKeepValue", b)+( b:isRed() and 50 or 0 )+( b:isKindOf("Peach") and 50 or 0 )
        return v1<v2
    end
    table.sort(cards,compare_func)
    for _,c in ipairs(cards)do
        if c:isKindOf("EquipCard") then
            table.insert(use_cards, c)
        end
    end
    if #use_cards > 0 then
        return parse_action(self,"#f_liaoduCard:"..use_cards[1]:getId()..":")
    end
end

sgs.ai_skill_use_func["#f_liaoduCard"] = function(card,use,self,request)
    local arr1,arr2 = self:getWoundedFriend(false,true)
    local target = nil

    if #arr1>0 and (self:isWeak(arr1[1]) or self:getOverflow()>=1) and arr1[1]:getHp()<getBestHp(arr1[1]) then target = arr1[1] end
    if target then
        use.card = card
        use.to:append(target)
        return
    end
    if self:getOverflow()>0 and #arr2>0 then
        for _,friend in ipairs(arr2)do
            if not friend:hasSkills("hunzi|longhun") then
                use.card = card
                use.to:append(friend)
                return
            end
        end
    end
end

sgs.ai_use_priority.f_liaoduCard = 4.2
sgs.ai_card_intention.f_liaoduCard = -100

sgs.dynamic_value.benefit.f_liaoduCard = true


local f_mafei_skill = {}
f_mafei_skill.name = "f_mafei"
table.insert(sgs.ai_skills,f_mafei_skill)
f_mafei_skill.getTurnUseCard = function(self)
    if self.player:getHandcardNum()<1 then return nil end

    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    local use_cards = {}
    local compare_func = function(a,b)
        local v1 = source_query(self, "getKeepValue", a)+( a:isRed() and 50 or 0 )+( a:isKindOf("Peach") and 50 or 0 )
        local v2 = source_query(self, "getKeepValue", b)+( b:isRed() and 50 or 0 )+( b:isKindOf("Peach") and 50 or 0 )
        return v1<v2
    end
    table.sort(cards,compare_func)
    for _,c in ipairs(cards)do
        if c:isKindOf("TrickCard") then
            table.insert(use_cards, c)
        end
    end
    if #use_cards > 0 then
        return parse_action(self,"#f_mafeiCard:"..use_cards[1]:getId()..":")
    end
end
sgs.ai_skill_use_func["#f_mafeiCard"] = function(card,use,self,request)
    local previousAlive = self.player:getNextAlive(source_query(self.player, "aliveCount")-1)
    if previousAlive and self:isFriend(previousAlive) and self:isWeak(previousAlive) then
        use.card = card
        use.to:append(previousAlive)
        return
    end
    local nextAlive = self.player
    repeat
        nextAlive = nextAlive:getNextAlive()
    until nextAlive:faceUp()
    if nextAlive and self:isEnemy(nextAlive) then
        use.card = card
        use.to:append(nextAlive)
        return
    end
    for _,friend in ipairs(self.friends_noself)do
        if not self:toTurnOver(friend,0,"f_mafei") then
            use.card = card
            use.to:append(friend)
            return
        end
    end
    for _,friend in ipairs(self.friends_noself)do
        if self:isWeak(friend) then
            use.card = card
            use.to:append(friend)
            return
        end
    end
end

local f_wuqin_skill = {}
f_wuqin_skill.name = "f_wuqin"
table.insert(sgs.ai_skills,f_wuqin_skill)
f_wuqin_skill.getTurnUseCard = function(self)
    if self.player:getHandcardNum()<1 then return nil end

    local cards = self.player:getHandcards()
    cards = sgs.QList2Table(cards)
    local use_cards = {}
    local compare_func = function(a,b)
        local v1 = source_query(self, "getKeepValue", a)+( a:isRed() and 50 or 0 )+( a:isKindOf("Peach") and 50 or 0 )
        local v2 = source_query(self, "getKeepValue", b)+( b:isRed() and 50 or 0 )+( b:isKindOf("Peach") and 50 or 0 )
        return v1<v2
    end
    table.sort(cards,compare_func)
    for _,c in ipairs(cards)do
        if c:isKindOf("BasicCard") then
            table.insert(use_cards, c)
        end
    end
    if #use_cards > 0 then
        return parse_action(self,"#f_wuqinCard:"..use_cards[1]:getId()..":")
    end
end
sgs.ai_skill_use_func["#f_wuqinCard"] = function(card,use,self,request)
    for _,friend in ipairs(self.friends_noself)do
        use.card = card
        use.to:append(friend)
        return
    end
    for _,friend in ipairs(self.friends)do
        use.card = card
        use.to:append(friend)
        return
    end
end
sgs.ai_use_priority.f_wuqinCard = 5
sgs.ai_card_intention.f_wuqinCard = -100

sgs.ai_ajustdamage_from["&f_wuqin_tiger"] = function(self, from, to, card, nature)
    if card and (card:isKindOf("Slash") or card:isKindOf("Duel"))  then
        return 1
    end
end

sgs.ai_skill_playerchosen.f_chongzhen = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if source_query(self, "doDisCard", target, "hej")  then
            return target
        end
    end
    return nil
end

sgs.ai_skill_invoke.f_chongzhen = function(self,data)
    local target = data:toPlayer()
    set_state(self,"f_chongzhenTarget",target)
    return source_query(self, "doDisCard", target, "hej")
end
ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.f_chongzhen",defer_canonical=true,self_index=1,registry="ai_choicemade_filter",path={"cardChosen","f_chongzhen"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"}}

sgs.ai_skill_invoke["@f_forSXSandSHZ_changeSkin"] = function(self, data)
    if math.random() > 0.5 then return true end
    return false
end


sgs.ai_skill_invoke["f_pojun"] = function(self, data)
    local target = data:toPlayer()
    if not self:isFriend(target) then return true end
    return false
end

sgs.ai_skill_invoke.f_yicheng = function(self, data)
    local target = data:toPlayer()
    return self:isFriend(target)
end
sgs.ai_choicemade_filter.skillInvoke.f_yicheng = function(self,player,promptlist)
    if promptlist[#promptlist]=="yes" then
        local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
        if target then self:updateIntention(player,target,-50) end
    end
end
sgs.ai_skill_invoke.f_haishiSM = true


sgs.ai_skill_invoke.f_dazhuang = true


sgs.ai_skill_invoke.f_kaigong = function(self, data)
    local target = scoped_player(self,"f_kaigong")
    return not self:isFriend(target)
end

sgs.ai_ajustdamage_from.f_kaigong = function(self, from, to, card, nature)
    if card and card:getStrategyFlag("f_kaigong")
    then
        return to:getStrategyMark("f_kaigong")
    end
end

sgs.ai_skill_invoke["#f_gonghunMission"] = true


sgs.ai_card_priority.f_gonghun = function(self,card,v)
    if self.player:getStrategyMark("&f_gonghun")==2 and card:isKindOf("Slash") and ((card:isRed() and self.player:getStrategyMark("f_gonghun_2to3_red") == 0) or (card:isBlack() and self.player:getStrategyMark("f_gonghun_2to3_black") == 0))
    then return 10 end
    if self.player:getStrategyMark("&f_gonghun")==3 and card:isKindOf("Slash") and
    ((self.player:getStrategyMark("f_gonghun_3to4_"..card:getSuitString()) == 0)
    )
    then return 10 end
    if self.player:getStrategyMark("&f_gonghun")==4 and card:isKindOf("Slash") and
    source_query(card, "isVirtualCard") and (card:subcardsLength() == 0 or card:subcardsLength() >= 4)
    then return 10 end
end

sgs.ai_ajustdamage_from.f_gonghun = function(self, from, to, card, nature)
    if from:getStrategyMark("&f_gonghun") > 1 and card and card:isKindOf("Slash")
    then
        return from:getStrategyMark("&f_gonghun") - 1
    end
end

sgs.ai_skill_invoke.Fchixieren = function(self, data)
    return self.player:getHp() < getBestHp(self.player)
end
sgs.ai_skill_invoke.Fmorigong = function(self, data)
    local damage = data:toDamage()
    return not self:isFriend(damage.to)
end

sgs.ai_ajustdamage_from.f_shanmengHS = function(self, from, to, card, nature)
    if isSpecialOne(from, "神黄忠") and isSpecialOne(from, "神徐盛")
    then
        return 1
    end
end



local f_shanmengHS_skill = {}
f_shanmengHS_skill.name = "f_shanmengHS"
table.insert(sgs.ai_skills, f_shanmengHS_skill)
f_shanmengHS_skill.getTurnUseCard = function(self, inclusive)
    local deathplayer = {}
    for _, p in sgs.qlist(self.room:getPlayers()) do
        if p:isDead() and p:getMaxHp() >= 2 and self:isFriend(p) then
            table.insert(deathplayer, source_query(p, "getGeneralName"))
        end
    end
    if #deathplayer == 0 then return end
    if not self:isWeak() and self.player:hasSkill("f_gonghun") and self.player:getStrategyMark("&f_gonghun") < 5 then return end
    if #deathplayer > 0 then
        return parse_action(self,"#f_shanmengHSCard:.:")
    end
end

sgs.ai_skill_use_func["#f_shanmengHScard"] = function(card, use, self,request)
    use.card = parse_action(self,"#f_shanmengHScard:.:")
    return
end

sgs.ai_use_value["f_shanmengHScard"] = 8
sgs.ai_use_priority["f_shanmengHScard"] = 7

-- The source constructs a strategy seed before choosing targets/costs. Rebind
-- exactly the first selected proposal, without re-running the policy.
for class,skill in pairs(action_skills)do
    local fn=sgs.ai_skill_use_func[class]
    if type(fn)=='function' then
        sgs.ai_skill_use_func[class]=function(card,use,self,request)
            local previous=self._fcDIY_request
            self._fcDIY_request=request
            local ok,result=pcall(fn,card,use,self,request)
            self._fcDIY_request=previous
            if not ok then error(result,0)end
            if use.card then use.card=materialize_action(self,use.card,request)end
            return result
        end
    end
end
local fcDIY_fill_names={"fczhizhe"}
for i=first_skill_index+1,#sgs.ai_skills do
    local sk=sgs.ai_skills[i]
    if type(sk.getTurnUseCard)=='function'then sgs.ai_fill_skill[sk.name]=sk.getTurnUseCard;fcDIY_fill_names[#fcDIY_fill_names+1]=sk.name end
end
for _,skill in ipairs(fcDIY_fill_names)do
    local fn=sgs.ai_fill_skill[skill]
    sgs.ai_fill_skill[skill]=function(self,inclusive,request)
        local previous,stage=self._fcDIY_request,self._fcDIY_stage
        self._fcDIY_request,self._fcDIY_stage=request,'fill'
        local ok,result=pcall(fn,self,inclusive,request)
        self._fcDIY_request,self._fcDIY_stage=previous,stage
        if not ok then error(result,0)end
        if skill=='sp_hengsaoqianjun' and type(result)=='table' and not preview_specs[result] then
            local proposals={}
            for i,card in ipairs(result) do proposals[i]=select_preview(self,card,request) end
            return proposals
        end
        return select_preview(self,result,request)
    end
end
