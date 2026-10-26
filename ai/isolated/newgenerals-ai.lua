-- Source: b6025acc ai/newgenerals-ai.lua.
local known = AIValue.requireKnown
local function copy(v)
    if type(v)~='table' then return v end
    local r={};for k,x in pairs(v) do r[k]=copy(x) end;return r
end
local preview_specs=setmetatable({},{__mode='k'})
local resolve_preview
local failure_mark
local function source_query(o,m,...)
    if AIValue.isPlayer(o) then
        if m=='getMark' and failure_mark and type((...))=='string' and (...):match('^olxiaofanFailed%-%d+Clear$') then return failure_mark(o:getRoom()._ai,o,(...)) end
        if m=='getMark' then m='getStrategyMark' elseif m=='hasFlag' then m='getStrategyFlag' end
    end
    local args={...};for i=1,select('#',...) do if preview_specs[args[i]] then args[i]=resolve_preview(args[i]) end end
    return (AIValue.callKnown(o, m, table.unpack(args,1,select('#',...))))
end
local dummy = AIUsePlan.dummy
local function pattern_names(self,class)
    if type(class)=='string'then
        local mapping=known(AICardCatalog.patternClassNames(),'exact last-write class/name catalog')
        return mapping[class] or class
    end
    return known(AICardCatalog.patternNames(),'pattern names')
end
local function r45_handpile(self,flags)
    local cards=sgs.QList2Table(source_query(self.player, "getCards", flags))
    local ids=self.player:getHandPile()
    if not AIValue.isList(ids)then ai_unsupported("actual hand-pile contains an unobserved material","newgenerals.hand_pile")end
    for _,id in ipairs(ids)do table.insert(cards,source_query(self, "getKnownCardById", id))end
    return cards
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
    c.toCardSpec=function()ai_unsupported('readonly draft has no payment authority','newgenerals')end
    return c
end
resolve_preview=function(c)
    local st=preview_specs[c];if not st then return c end
    if st.cached then return st.cached end
    if st.skill=='_xdfangchan' or st.skill=='_yantaoluan' then
        local spec={source_key='newgenerals.'..st.skill,skill=st.skill,name=st.name,
            suit=st.suit,number=st.number,subcards=copy(st.costs)}
        if st.recast~=nil then spec.can_recast=st.recast end
        local r=source_query(st.ai, 'evaluateOwnerViewAsCard', spec)
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    if st.skill=='keolshuangxiong' then
        local r=source_query(st.ai, 'evaluateOwnerViewAsCard', {source_key='newgenerals.keolshuangxiong',
            name=st.name,skill=st.skill,suit=st.suit,number=st.number,subcards=copy(st.costs)})
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    if st.skill=='keolsuji' then
        local r=source_query(st.ai, 'evaluateOwnerViewAsCard', {source_key='newgenerals.keolsuji',
            name=st.name,skill=st.skill,suit=st.suit,number=st.number,subcards=copy(st.costs)})
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    if st.skill=='_keolxieju' then
        local r=source_query(st.ai, 'evaluateOwnerViewAsCard', {source_key='newgenerals._keolxieju',
            name=st.name,skill=st.skill,suit=st.suit,number=st.number,subcards=copy(st.costs)})
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    if st.skill=='mouluanji' then
        local r=source_query(st.ai, 'evaluateOwnerViewAsCard', {source_key='newgenerals.mouluanji',
            skill=st.skill,name=st.name,suit=st.suit,number=st.number,subcards=copy(st.costs)})
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    local r45={keolkenshang=true,keolyilie=true,moujiang=true,mobilexiaoni=true,keolweilin=true,
        _xdyifu=true,ofsifen=true,_ofsifen=true,ofjunwei=true,_ofyouchong=true,godshenji=true}
    if r45[st.skill] then
        local spec={source_key='newgenerals.'..st.skill,skill=st.skill,name=st.name,
            suit=st.suit,number=st.number,subcards=copy(st.costs)}
        if st.recast~=nil then spec.can_recast=st.recast end
        local r=source_query(st.ai, 'evaluateOwnerViewAsCard', spec)
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    local r42={moulveying='moulveying',mouyingwu='mouyingwu',_mouxieji='mouxieji'}
    if r42[st.skill] then
        local r=source_query(st.ai, 'evaluateOwnerViewAsCard', {source_key='newgenerals.'..r42[st.skill],
            skill=st.skill,name=st.name,suit=st.suit,number=st.number,subcards=copy(st.costs)})
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    if st.skill=='keolcihuang' then
        local r=source_query(st.ai, 'evaluateOwnerViewAsCard', {source_key='newgenerals_context:keolcihuang',skill=st.skill,name=st.name,suit=st.suit,number=st.number,subcards=copy(st.costs)})
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    if st.suit~=sgs.Card_NoSuit or st.number~=0 then
        ai_unsupported('readonly clone requires exact nondefault suit/number projection','newgenerals.preview')
    end
    local r
    if st.skill=='' and #st.costs==0 then r=st.base
    elseif st.skill=='_mouxianchou' then
        r=source_query(st.ai, 'evaluateOwnerViewAsCard', {source_key='mouxianchou',skill=st.skill,name=st.name,
            suit=st.suit,number=st.number,subcards=copy(st.costs)})
    else r=source_query(st.ai, 'evaluateSkillCard', st.skill, st.name, st.costs) end
    if st.recast~=nil and source_query(r, 'canRecast')~=st.recast then
        ai_unsupported('readonly setCanRecast hypothesis is unavailable','newgenerals.preview')
    end
    st.ai:inheritLegacyCardIdentity(r,c)
    st.cached=r
    return r
end
local function mutate(self,c,kind,value)
    local st=preview_specs[c]
    if not st then
        ai_unsupported('mutable SkillCard seed requires exact selected-cost evaluation','newgenerals.'..kind)
    end
    st.cached=nil
    if kind=='skill' then st.skill=value;c._view.skill_name=value;c._view.skill_names={value}
    elseif kind=='add' then st.costs[#st.costs+1]=type(value)=='number' and value or value:getKnownEffectiveId()
    elseif kind=='clear' then st.costs={}
    elseif kind=='recast' then st.recast=value
    else ai_unsupported('unknown draft mutation','newgenerals') end
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
    local r45turn={keolshuangxiong=true,keolkenshang=true,keolyilie=true,moujiang=true,mobilexiaoni=true,keolweilin=true}
    if st.skill=='mouluanji' or r45turn[st.skill] then
        local selected=source_query(self, 'evaluateTurnConversion', st.skill, r:getClassName(), {name=st.name,skill=st.skill,suit=st.suit,number=st.number,subcards=copy(st.costs)}, request)
        return self:inheritLegacyCardIdentity(selected,c)
    end
    return source_query(self, 'bindTurnConversion', st.skill, r:getClassName(), {name=st.name,skill_name=st.skill,suit=r:getSuit(),number=r:getNumber(),subcards=copy(st.costs)}, request)
end
local function target_ok(c,from,to,prefix)
    return CanToCard(resolve_preview(c),from,to,prefix)
end
local function scope(self,key)
    local row=source_query(self, 'getDecisionContext').newgenerals
    if type(row)~='table' then ai_unsupported('Newgenerals scoped context unavailable',key) end
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
local function scope_list(self,key)return AIList.new(copy(scope(self,key)))end
-- Selected borrowed physical products must retain the native request's six
-- identities. The raw request DTO is not an AiLegacyRequestView.
local function r45_selected_borrowed(self,card,targets,names)
    local request=AILegacyRequest.new(self.request,self.room)
    if not request or not request:isValid() then
        ai_unsupported("borrowed physical source request is incomplete","newgenerals.preview")
    end
    local selected=self:materializeBorrowedSelectedCard(card,targets,request)
    if not AIValue.isCard(selected) or selected:isVirtualCard()~=false
        or selected:isEvaluationOnly()~=false
        or selected:getEffectiveId()~=card:getKnownEffectiveId() then
        ai_unsupported("selected borrowed receipt changed its source physical identity","newgenerals.preview")
    end
    -- These two actual V2 inquiries consume a selected-ID action. Preserve the
    -- donor's original card/target order, but never route its physical wire
    -- through a legacy raw-skill-name comparison or fabricate a card product.
    return {accepted=true,cards={selected:getEffectiveId()},targets=names}
end
local function scoped_count(self,key)
    local n=scope(self,key)
    if type(n)~='number' or n<0 or n%1~=0 then ai_unsupported('invalid scoped public count',key) end
    return n
end
local function owner_tip(self,card,key)
    local rows=scope(self,'owner_keolzhubi_tip')
    return known(rows[tostring(card:getKnownEffectiveId())],key)
end
local function known_card(self,id)
    id=tonumber(id);if not id then return nil end
    if self.request.kind=='amazing_grace' or self.request.kind=='guanxing' then
        for _,x in ipairs(self.request.options.card_ids or {}) do if x==id then
            local c=source_query(self, 'getChoiceCard', id);return self:getAcquiredCardEvaluation(c) or c
        end end
    end
    local context=self:getDecisionContext().newgenerals
    local rows=type(context)=='table' and context.notified_current_cards
    if type(rows)=='table' and rows[tostring(id)] then
        return source_query(self, 'getPreviewCardEvaluation', id)
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
    self:setStrategyMemory('newgenerals.choice.'..key,value)
    self:useKnowledgeEstimate({value=true,status='estimate',basis='newgenerals.shared_choice_viewer_partition'},key)
end
local function get_choice(self,key)
    local v,yes=self:getStrategyMemory('newgenerals.choice.'..key)
    if not yes then ai_unsupported('shared source choice has not been observed by this viewer',key)end
    self:useKnowledgeEstimate({value=true,status='estimate',basis='newgenerals.shared_choice_viewer_partition'},key)
    return v
end
local function strategy_flag(self,p,flag)
    if flag=='InfinityAttackRange' or flag=='-InfinityAttackRange' then
        ai_unsupported('readonly InfinityAttackRange hypothesis missing','newgenerals')
    end
    self:setStrategyPlayerFlag(p,flag,true)
end

local function BeMan(room,owner,dead)
    if AIValue.isPlayer(owner)then owner=owner:objectName()end
    for _,p in ipairs(source_query(room, 'getPlayers'))do if p:objectName()==owner then return p end end
end

local action_skills={
 ["#_chunqiubiCard"]="_chunqiubi",
 ["#chuifengCard"]="chuifeng",
 ["#hannanCard"]="hannan",
 ["#huishiCard"]="huishi",
 ["#huishii"]="huishii",
 ["#jinghe"]="jinghe",
 ["#kehuiyaoCard"]="kehuiyao",
 ["#kemobileguanzongCard"]="kemobileguanzong",
 ["#keolbixinCard"]="keolbixin",
 ["#keolqingyiCard"]="keolqingyi",
 ["#keolsaoguCard"]="keolsaogu",
 ["#keolshandaoCard"]="keolshandao",
 ["#keolshizhanCard"]="keolshizhan",
 ["#keolxianbiCard"]="keolxianbi",
 ["#keolxiejuCard"]="keolxieju",
 ["#keolzhenyingCard"]="keolzhenying",
 ["#keolzhubiCard"]="keolzhubi",
 ["#liangyuanCard"]="liangyuan",
 ["#mobile_dingzouCard"]="mobile_dingzou",
 ["#mobile_wulingCard"]="mobile_wuling",
 ["#mobile_youyiCard"]="mobile_youyi",
 ["#mobiledamingCard"]="mobiledamingvs",
 ["#mobilefenming"]="mobilefenming",
 ["#mobilejingxieCard"]="mobilejingxie",
 ["#mobileqiaosiCard"]="mobileqiaosi",
 ["#moufanjianCard"]="moufanjian",
 ["#moufenweiCard"]="moufenwei",
 ["#mouguoseCard"]="mouguose",
 ["#mouhuojiCard"]="mouhuoji",
 ["#moujieweiCard"]="moujiewei",
 ["#moujushouCard"]="moujushou",
 ["#mouliangzhuCard"]="mouliangzhu",
 ["#moulijianCard"]="moulijian",
 ["#moumingceCard"]="moumingce",
 ["#mouqicaiCard"]="mouqicai",
 ["#mouqixiCard"]="mouqixi",
 ["#mourendeCard"]="mourende",
 ["#moutianxiangCard"]="moutianxiang",
 ["#mouxuanhuoCard"]="mouxuanhuo",
 ["#mouyanyuCard"]="mouyanyu",
 ["#mouzhangwuCard"]="mouzhangwu",
 ["#mouzhenliang"]="mouzhenliang",
 ["#nhhuoqi"]="nhhuoqi",
 ["#nhxianshou"]="nhxianshou",
 ["#nosjinwanyi"]="nosjinwanyi",
 ["#ny_ol_yanruCard"]="ny_ol_yanru",
 ["#offunanCard"]="offunan",
 ["#ofjixuCard"]="ofjixu",
 ["#ofshezuoCard"]="ofshezuo",
 ["#ofsifenCard"]="ofsifen",
 ["#ofyouchongCard"]="ofyouchong",
 ["#oldimeng"]="oldimeng",
 ["#olfuman"]="olfuman",
 ["#olxiaofan0Card"]="olxiaofan",
 ["#renbinglunCard"]="renbinglun",
 ["#renluanchouCard"]="renluanchou",
 ["#xdyifucard"]="xdyifuvs",
 ["#xin2chuhaiCard"]="xin2chuhai",
 ["#xiongsuanCard"]="xiongsuan",
 ["#yanduanbiCard"]="yanduanbi",
 ["#yanyangjieCard"]="yanyangjie",
 ["#yingba"]="yingba",
 ["#yongshanxieCard"]="yongshanxie",
 ["#zaibiCard"]="zaibi",
 ["#zhaoluanCard"]="zhaoluan",
 ["#zuoxing"]="zuoxing",
}
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
        return source_query(self, 'bindTurnConversion', skill, face:getClassName(), {name=name,skill_name=skill,suit=actual_suit,number=number,subcards=cs}, self._newgenerals_request)
    end
    local skill=known(action_skills[class],'source skill for '..class)
    local ids=cost_ids(costs);if not ids then return nil end
    local r
    if self._newgenerals_stage=='fill' and class=='#xdyifucard' then
        -- Source Card_Parse observes a proposal; only a selected usefunc pays.
        r=source_query(self, 'evaluateTurnSkillCard', skill, class, ids, self._newgenerals_request, user)
        action_specs[r]={skill=skill,class=class,costs=ids,user=user,request=self._newgenerals_request}
    elseif self._newgenerals_stage=='fill' and #ids==0 and user=='' then
        r=source_query(self, 'legacySkillSeed', skill, class, self._newgenerals_request)
        action_specs[r]={skill=skill,class=class,costs=ids,user=user,request=self._newgenerals_request}
    else
        r=source_query(self, 'bindSkillCard', skill, ids, self._newgenerals_request, user~=''and user or nil, class)
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
local function card_fact(self,c,key)ai_unsupported('card dynamic properties are not projected',key)end
local function property_value(self,p,key)
    -- Only the viewer's own properties are projected (a foreign read raises); absent reads as toString() "".
    local v=p:getPropertyValue(key)
    if v==nil then return '' end;return v
end
local function visible_top_id(self)ai_unsupported('draw-pile top card is not projected','newgenerals.draw_top')end
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
failure_mark=function(self,p,key,increment)
    if p~=self.player then ai_unsupported('olxiaofan failure mark is owner-scoped',key)end
    local name=p:objectName()
    local epochs=known(AIWorldLifecycle.epochs(self.world,'all_mark'),'mark clear facts')
    local epoch=known(epochs[name],'all-mark clear epoch')
    local state,present=self:getStrategyMemory('newgenerals.olxiaofan_failures')
    if not present or state.epoch~=epoch then state={epoch=epoch,values={}}else state=copy(state)end
    local value=state.values[key]
    if value==nil then value=known(p:getMark(key),'owner failed mark')end
    if increment then value=value+1;state.values[key]=value;self:setStrategyMemory('newgenerals.olxiaofan_failures',state)end
    return value
end
local function add_failure_mark(self,key)
    -- Source uses numeric phase suffix (-4Clear etc). GameRule only clears
    -- named phase suffixes, so this mark persists until throwAllMarks(false).
    return failure_mark(self,self.player,key,true)
end
local function canLyUse(player,name)
    local self=known(player:getRoom()._ai,'Liangyuan viewer')
    local rows=scope(self,'liangyuan_cards');local row=known(rows[name],'Liangyuan preview')
    if row==false then return nil end
    local c=known(CardView.new(row.card),'Liangyuan face');c._evaluation_candidate=known(row.candidate,'Liangyuan candidate');return c
end
local function isCurrent(use,p)
    for _,v in ipairs(use.current_targets or{})do if v==p or v==p:objectName()then return true end end
    return false
end
local function pack_state(self,value)
    if AIValue.isPlayer(value)then return{kind='player',name=value:objectName()}end
    if AIValue.isCard(value)or AIValue.isConversion(value)then
        return{kind='card',value=self:capturePriorTurnPlan(resolve_preview(value))}
    end
    if type(value)=='table'then local r={kind='table',value={}};for k,v in pairs(value)do r.value[k]=pack_state(self,v)end;return r end
    if value==nil then return{kind='nil'}end
    if type(value)~='string'and type(value)~='number'and type(value)~='boolean'then ai_unsupported('nonvalue source cache','newgenerals')end
    return{kind='scalar',value=value}
end
local function unpack_state(self,row)
    if row.kind=='nil'then return nil end
    if row.kind=='scalar'then return row.value end
    if row.kind=='player'then return player(self,row.name)end
    if row.kind=='card'then return self:restorePriorTurnPlan(row.value)end
    if row.kind=='table'then local r={};for k,v in pairs(row.value)do r[k]=unpack_state(self,v)end
        if AIValue.isList(r)then return AIList.new(r)end;return r end
    ai_unsupported('malformed viewer cache','newgenerals')
end
local function set_state(self,key,value)
    if key=='xdyifuvsTo'then return self:writeNewgeneralsSavedSlot(key,value)end
    if key=='xdyifuvsUse'or key=='godshenji_use'then
        return self:writeNewgeneralsSavedSlot(key,value,resolve_preview(value.card))
    end
    self[key]=value
    if key=='hannan_card'or key=='yanyangjie_card'then self:remember(key,value and value:getKnownEffectiveId())end
    self:setStrategyMemory('newgenerals.state.'..key,{value=pack_state(self,value),estimates=copy(self.request.scratch.knowledge_estimates or{})})
end
local function get_state(self,key)
    if key=='xdyifuvsTo'or key=='xdyifuvsUse'or key=='godshenji_use'then
        return self:readNewgeneralsSavedSlot(key)
    end
    if rawget(self,key)~=nil then return self[key]end
    local row,yes=self:getStrategyMemory('newgenerals.state.'..key)
    if not yes then return nil end
    if type(row)~='table'or type(row.value)~='table'then ai_unsupported('viewer cache malformed',key)end
    for _,entry in ipairs(row.estimates or{})do entry=copy(entry);entry.status='estimate';entry.value=true;self:useKnowledgeEstimate(entry,'newgenerals.cached')end
    self[key]=unpack_state(self,row.value)
    return self[key]
end
local function set_defense(self,key,value)
    if type(self.setDefenseValue)~='function'then ai_unsupported('viewer-local defense override consumers missing','newgenerals.'..key)end
    self:setDefenseValue(key,value)
end

local function invoke_peiqi(self)
    local fn=ai_skill_invoke.peiqi
    if type(fn)~='function'then ai_unsupported('effective Peiqi policy is not loaded','newgenerals.yandiaodu')end
    local ok,result=pcall(fn, self, {}, nil)
    if self.peiqiData then set_state(self,'peiqiData',self.peiqiData)end
    if not ok then error(result,0)end
    return result
end


function SmartAIView:useCardQizhengxiangsheng(card,use)
    local recommend = self:targetRecommendScorer(card)
    self:sort(self.enemies,"hp")
    local extraTarget = source_query(card, "getTargetModExtra", self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,ep in sgs.list(self:orderTargetsByRecommend(self.enemies, recommend))do
        if isCurrent(use,ep) then continue end
        if target_ok(card,self.player,ep,use.to)
        and source_query(self, "ajustDamage", self.player, ep, 1, card)~=0
        then
            use.card = card
            use.to:append(ep)
            if use.to:length()>extraTarget
            then return end
        end
    end
end
sgs.ai_use_priority.Qizhengxiangsheng = 3.4
sgs.ai_keep_value.Qizhengxiangsheng = 4
sgs.ai_use_value.Qizhengxiangsheng = 3.7
sgs.ai_card_intention.Qizhengxiangsheng = 22

sgs.ai_nullification.Qizhengxiangsheng = function(self,trick,from,to,positive)
    if positive then
        return self:isFriend(to)
        and self:isWeak(to)
    else
        return self:isEnemy(to)
        and self:isWeak(to)
    end
end

ai_skill_choice._qizhengxiangsheng = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local target = data:toPlayer()
    if target:getHandcardNum()<3 and math.random()>0.4
    or target:isKongcheng()
    then return ai_choice_result((items[2]), options) end
    if math.random()<0.4
    then return ai_choice_result((items[1]), options) end

    return ai_choice_result(nil, options)
end

ai_skill_invoke.zhiren = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

sgs.ai_skill_playerchosen.zhiren = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"equip")
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not self:isFriend(target)
        then return target end
    end
    return destlist[1]
end

sgs.ai_skill_playerchosen.zhiren_judge = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not self:isEnemy(target)
        then return target end
    end
end

ai_skill_invoke.yaner = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    if target then
        return (not self:isEnemy(target)) or false
    end
    return false

end

ai_skill_invoke.quedi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    if target then
        return (self:isEnemy(target)) or false
    end
    return false

end

ai_skill_choice.quedi = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local use = data:toCardUse()
    if use.to:at(0):getHandcardNum()>1
    then return ai_choice_result((items[1]), options) end
    if use.to:at(0):getHandcardNum()<2
    then return ai_choice_result((items[2]), options) end

    return ai_choice_result(nil, options)
end

ai_fill_skill.chuifeng = function(self, options, request)
    local inclusive = options and options.inclusive


    if ((source_query(self.player, "getMark", "usetimeschuifeng-PlayClear") < 2)
    and (source_query(self.player, "getMark", "banchuifeng-Clear") == 0)) then

        for _,cn in sgs.list(pattern_names(self))do
            local fs = preview(self,cn)
            if fs and self.player:getKnownKingdom()=="wei"
            and fs:isKindOf("Duel")
            and source_query(fs, "isAvailable", self.player)
            and not self:isWeak() then
                mutate(self,fs,"skill","chuifeng")
                local d = use_card(self,fs)
                self:setPriorityValue("chuifeng",self:getPriorityValue(fs:getClassName()),"newgenerals")
                set_state(self,"cf_to",d.to)
                if d.card and d.to then
                    return parse_action(self,"#chuifengCard:.:"..cn)
                end
            end
        end
    end
end

ai_card_use["#chuifengCard"] = function(self, card, use, request)
    use.card = card
    use.to = get_state(self,"cf_to")
end

sgs.ai_use_value.chuifengCard = 5.4
sgs.ai_use_priority.chuifengCard = 2.8




ai_fill_skill.chongjian = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards,nil,true)
    local toids = {}
    for _,c in sgs.list(cards)do
        if c:isKindOf("EquipCard")
        then table.insert(toids,c) end
    end
    for _,cn in sgs.list(pattern_names(self))do
        local fs = preview(self,cn)
        if fs and self.player:getKnownKingdom()=="wu"
        and (fs:isKindOf("Slash") or fs:isKindOf("Analeptic"))
        and #toids>0 then
            mutate(self,fs,"skill","chuifeng")
            mutate(self,fs,"add",toids[1])
            local d = use_card(self,fs)
            if source_query(fs, "isAvailable", self.player)
            and d.card and d.to
            then return fs end
        end
    end
end

sgs.ai_guhuo_card.chongjian = function(self,toname,class_name)
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards,nil,true)
    local toids = {}
    for _,c in sgs.list(cards)do
        if c:isKindOf("EquipCard")
        then table.insert(toids,c:getKnownEffectiveId()) end
    end
    if #toids>0
    then return "#chongjianCard:"..toids[1]..":"..toname end
end


ai_skill_invoke.xiuhao = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    if target then
        return (not self:isEnemy(target) or self:isWeak()) or false
    end
    return false

end

sgs.ai_skill_playerchosen.sujian = function(self,players)
    players = self:sort(players,"card",true)
    for _,target in sgs.list(players)do
        if self:isEnemy(target)
        then return target end
    end
    for _,target in sgs.list(players)do
        if not self:isFriend(target)
        then return target end
    end
    return players[1]
end

sgs.ai_skill_askforyiji.sujian = function(self,card_ids,tos)
    local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
    if to and id then return to,id end
    for _,target in sgs.list(tos)do
        if self:isFriend(target)
        then return target,card_ids[1] end
    end
    for _,target in sgs.list(tos)do
        return target,card_ids[1]
    end
end

ai_skill_choice.sujian = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local ids = data:toIntList()
    local to,id = sgs.ai_skill_askforyiji.sujian(self,sgs.QList2Table(ids),self.room:getOtherPlayers(self.player))
    if to and id then
        return ai_choice_result(("give"), options)
    end
    return ai_choice_result(("discard"), options)
end

ai_fill_skill.olfuman = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(cards)
    for _,ep in sgs.list(self.friends_noself)do
        if source_query(ep, "getMark", "olfuman_target-PlayClear")<1
        and #cards>=source_query(self.player, "getMaxCards")
        then
            return parse_action(self,"#olfuman:"..cards[1]:getEffectiveId()..":")
        end
    end
    for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
        if source_query(ep, "getMark", "olfuman_target-PlayClear")<1
        and #cards>source_query(self.player, "getMaxCards")
        and not self:isEnemy(ep)
        then
            return parse_action(self,"#olfuman:"..cards[1]:getEffectiveId()..":")
        end
    end
end

ai_card_use["#olfuman"] = function(self, card, use, request)
    self:sort(self.friends_noself,"hp")
    for _,ep in sgs.list(self.friends_noself)do
        if source_query(ep, "getMark", "olfuman_target-PlayClear")<1
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
    for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
        if source_query(ep, "getMark", "olfuman_target-PlayClear")<1
        and self.player:getHandcardNum()>source_query(self.player, "getMaxCards")
        and not self:isEnemy(ep)
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
end

sgs.ai_use_value.olfuman = 9.4
sgs.ai_use_priority.olfuman = 4.8

sgs.ai_skill_playerchosen.xianwei = function(self,players)
    players = self:sort(players,"hp")
    for _,target in sgs.list(players)do
        if self:isFriend(target)
        then return target end
    end
    for _,target in sgs.list(players)do
        if not self:isEnemy(target)
        then return target end
    end
    return players[1]
end

sgs.ai_skill_discard.zhiming = function(self)
    local cards = {}
    local js = self.player:getCards("j")
    if js:length()>0
    and self.player:getPhase()==sgs.Player_Start then
        local handcards = self.player:getCards("he")
        handcards = self:sortByKeepValue(handcards)
        local jt = judge_pattern(self,js:last():objectName())
        if type(jt)~="table" then
            if type(jt)=="string" then
                jt = {jt,true}
            else
                jt = {jc:getSuitString(),true}
            end
        end
        if jt then
            for _,h in sgs.list(handcards)do
                if source_query(self, "matchesDiscardPattern", jt[1], h)==jt[2]
                then table.insert(cards,h:getKnownEffectiveId()) end
                if #cards>0 then return cards end
            end
        end
    end
    js = self:poisonCards("he")
    if self.player:getPhase()~=sgs.Player_Start and #js>0 then
        table.insert(cards,js[1]:getEffectiveId())
    end
    return cards
end

sgs.ai_skill_cardask["@zhiming-put"] = function(self,data,pattern)
    local target = self.room:getCurrent()
    local cards = sgs.ai_skill_discard.zhiming(self)
    return #cards>0 and cards[1] or "."
end

sgs.ai_skill_cardask["@yuyanzy-give"] = function(self,data,pattern)
    local use = data:toCardUse()
    return self:isEnemy(use.to:at(0))
end

sgs.ai_skill_playerchosen.xbwuxinglianzhu = function(self,players)
    players = self:sort(players,"handcard",true)
    for _,target in sgs.list(players)do
        if self:isFriend(target)
        then return target end
    end
    for _,target in sgs.list(players)do
        if not self:isEnemy(target)
        then return target end
    end
    return players[1]
end

sgs.ai_skill_playerchosen.xbfukuangdongzhu = function(self,players)
    players = self:sort(players,"hp")
    for _,target in sgs.list(players)do
        if self:isFriend(target)
        then return target end
    end
    for _,target in sgs.list(players)do
        if not self:isEnemy(target)
        then return target end
    end
    return players[1]
end

sgs.ai_skill_playerchosen.xbyinghuoshouxin = function(self,players)
    players = self:sort(players,"handcard",true)
    for _,target in sgs.list(players)do
        if self:isEnemy(target)
        then return target end
    end
    for _,target in sgs.list(players)do
        if not self:isFriend(target)
        then return target end
    end
    return players[1]
end

ai_skill_invoke.olhaoshi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local al = self.room:getOtherPlayers(self.player)
    local n,can = 998,false
    for _,target in sgs.list(al)do
        n = math.min(n,target:getHandcardNum())
    end
    for _,target in sgs.list(al)do
        if target:getHandcardNum()<=n
        and not self:isEnemy(target)
        then can = true end
    end
    return (self.player:getHandcardNum()+2<=5 or can) or false
end

sgs.ai_skill_cardask["@olhaoshi-give"] = function(self,data,pattern,to)
    local use = data:toCardUse()
    if self:isFriend(to)
    and self:isWeak(to)
    then
        local cs
        if use.card:isKindOf("Slash")
        or use.card:isKindOf("ArcheryAttack")
        then cs = self:getCards("Jink") end
        if use.card:isKindOf("Duel")
        or use.card:isKindOf("SavageAssault")
        then cs = self:getCards("Slash") end
        if cs then return cs[1]:getEffectiveId() end
    end
    return "."
end

ai_fill_skill.oldimeng = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#oldimeng:.:")
end

ai_card_use["#oldimeng"] = function(self, card, use, request)
    self:sort(self.enemies,"handcard",true)
    self:sort(self.friends_noself,"handcard")
    for _,ep in sgs.list(self.enemies)do
        for _,fp in sgs.list(self.friends_noself)do
            if ep:getHandcardNum()>fp:getHandcardNum()
            then
                use.card = card
                use.to:append(ep)
                use.to:append(fp)
                return
            end
        end
    end
end

sgs.ai_use_value.oldimeng = 9.4
sgs.ai_use_priority.oldimeng = 5.8

sgs.ai_skill_playerchosen.secondwenji = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
        if not self:isEnemy(target)
        then return target end
    end
    self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target)
        then return target end
    end
    self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        then return target end
    end
    return destlist[1]
end

sgs.ai_skill_playerchosen.secondkangge = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
        if not self:isEnemy(target)
        then return target end
    end
    self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        then return target end
    end
    self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target)
        then return target end
    end
    return destlist[1]
end

sgs.ai_skill_playerchosen.fengjie = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
        if not self:isEnemy(target)
        then return target end
    end
    return destlist[1]
end

ai_skill_invoke.secondkangge = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    if target
    then
        return (not self:isEnemy(target)) or false
    end
    return false

end

ai_skill_invoke.secondjielie = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

ai_skill_invoke.yise = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    if target
    then
        return (self:isFriend(target)) or false
    end
    return false

end

sgs.ai_skill_askforyiji.shunshi = function(self,card_ids)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    local tos = self.room:getOtherPlayers(self.player)
    tos = self:sort(tos,"hp")
    for _,p in sgs.list(tos)do
        if p:getStrategyFlag("shunshi")
        then
            if cards[1]:isRed() and self:isFriend(p)
            or cards[1]:isBlack() and self:isEnemy(p)
            then return p,cards[1]:getEffectiveId() end
        end
    end
end

sgs.ai_skill_cardask["@fengzi-discard"] = function(self,data)
    local use = data:toCardUse()
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards)
    for _,h in sgs.list(cards)do
        if h:getTypeId()==use.card:getTypeId()
        then
            if use.card:isKindOf("Peach")
            and self.player:getLostHp()>1
            then return h:getKnownEffectiveId()
            elseif use.card:isKindOf("Analeptic")
            and not(h:isKindOf("Slash") and self:wasPreviouslyPlannedCard(h))
            then return h:getKnownEffectiveId()
            elseif use.to:contains(self.player)
            then return h:getKnownEffectiveId()
            elseif source_query(use.card, "isDamageCard")
            or use.card:isKindOf("SingleTargetTrick")
            then
                for _,to in sgs.list(use.to)do
                    if self:isFriend(to)
                    then return "." end
                end
                return h:getKnownEffectiveId()
            end
        end
    end
    return "."
end

ai_skill_invoke.jizhanw = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

ai_skill_choice.jizhanw = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local n = data:toInt()
    local items = choices:split("+")
    if n>6 then return ai_choice_result((items[2]), options) end
    if n<7 then return ai_choice_result((items[1]), options) end
    return ai_choice_result((items[2]), options)
end


sgs.ai_skill_playerchosen.fusong = function(self,players)
    players = self:sort(players,"card",true)
    for _,target in sgs.list(players)do
        if self:isFriend(target)
        then return target end
    end
    for _,target in sgs.list(players)do
        if not self:isEnemy(target)
        then return target end
    end
end

ai_skill_invoke.qingjue = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = data:toCardUse()
    if self:isFriend(use.to:at(0))
    then
        if self:isWeak(use.to:at(0))
        and source_query(use.card, "isDamageCard")
        then return (true) or false
        else
            local cards = self.player:getCards("h")
            cards = sgs.QList2Table(cards) -- 将列表转换为表
            self:sortByKeepValue(cards)
            for _,h in sgs.list(cards)do
                if h:getNumber()>9
                then return (true) or false end
            end
        end
    end
    return false

end

sgs.ai_skill_playerchosen.zhibian = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards) -- 将列表转换为表
        self:sortByKeepValue(cards)
        for _,h in sgs.list(cards)do
            if h:getNumber()>9
            and self:isEnemy(target)
            then return target end
        end
    end
end

sgs.ai_useto_revises.yuyan = function(self,card,use,p)
    if card:isKindOf("Slash")
    and not source_query(card, "isVirtualCard")
    then
        set_defense(self,"yuyan",0)
        local xc = self:getMaxCard(nil,self:getCards("he"))
        if xc and xc:getNumber()<=card:getNumber()
        then set_defense(self,"yuyan",4) end
    end
end

ai_skill_invoke.yilie = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

ai_fill_skill.mobilefenming = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#mobilefenming:.:")
end

ai_card_use["#mobilefenming"] = function(self, card, use, request)
    self:sort(self.enemies,"hp")
    for _,ep in sgs.list(self.enemies)do
        if ep:isChained() and source_query(ep, "getCardCount")>1
        and ep:getHp()<=self.player:getHp()
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
    for _,ep in sgs.list(self.enemies)do
        if ep:getHp()>self.player:getHp() then continue end
        use.card = card
        use.to:append(ep)
        return
    end
end

sgs.ai_use_value.mobilefenming = 3.4
sgs.ai_use_priority.mobilefenming = 4.8

ai_fill_skill.jinghe = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = sgs.QList2Table(self.player:getCards("h"))
    if #cards<1 then return end
    self:sortByKeepValue(cards)
    local toids,cs = {},{}
    for _,c in sgs.list(cards)do
        if #toids>=#self.friends
        or cs[c:objectName()]
        then continue end
        cs[c:objectName()] = true
        table.insert(toids,c:getKnownEffectiveId())
    end
    set_state(self,"jh_n",#toids)
    return #toids>0 and parse_action(self,"#jinghe:"..table.concat(toids,"+")..":")
end

ai_card_use["#jinghe"] = function(self, card, use, request)
    self:sort(self.friends,"hp",true)
    for _,ep in sgs.list(self.friends)do
        use.card = card
        if use.to:length()<get_state(self,"jh_n")
        then use.to:append(ep) end
    end
end

sgs.ai_use_value.jinghe = 9.4
sgs.ai_use_priority.jinghe = 6.8

ai_skill_invoke.gongxiu = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end


ai_skill_choice.gongxiu = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    local items = choices:split("+")
    local draw,discard = 0,0
    for _,p in sgs.list(self.room:getAllPlayers())do
        if source_query(p, "getMark", "jinghe_GetSkill-Clear")>0
        then draw = draw+1
        elseif not p:isKongcheng()
        then discard = discard+1 end
    end
    if draw<discard
    then return ai_choice_result(("discard"), options)
    else return ai_choice_result(("draw"), options) end

    return ai_choice_result(nil, options)
end

ai_fill_skill.nhhuoqi = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards,nil,true)
    if #cards>0
    then
        return parse_action(self,"#nhhuoqi:"..cards[1]:getEffectiveId()..":")
    end
end

ai_card_use["#nhhuoqi"] = function(self, card, use, request)
    self:sort(self.friends,"hp")
    local tos = self.room:getOtherPlayers(self.player)
    tos = self:sort(tos,"hp")
    for _,ep in sgs.list(self.friends)do
        if ep:getHp()<=tos[1]:getHp()
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
end

sgs.ai_use_value.nhhuoqi = 9.4
sgs.ai_use_priority.nhhuoqi = 4.8

ai_skill_invoke.nhguizhu = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

ai_fill_skill.nhxianshou = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#nhxianshou:.:")
end

ai_card_use["#nhxianshou"] = function(self, card, use, request)
    self:sort(self.friends,"hp")
    for _,ep in sgs.list(self.friends)do
        if not ep:isWounded()
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
    for _,ep in sgs.list(self.friends)do
        if ep:isWounded()
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
end

sgs.ai_use_value.nhxianshou = 9.4
sgs.ai_use_priority.nhxianshou = 3.8

ai_skill_invoke.yise = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    if target
    then
        return (not self:isFriend(target) and target:getHandcardNum()>self.player:getHandcardNum()
        or target:getHandcardNum()<self.player:getHandcardNum()) or false
    end
    return false

end

ai_skill_invoke.nhguanyue = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

sgs.ai_skill_cardask["@nhyanzheng-keep"] = function(self,data)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards,true)
    local n = #cards-1
    if n>#self.enemies/2
    and n<#self.enemies*2
    then
        return cards[1]:getEffectiveId()
    end
    return "."
end

ai_skill_use["@@nhyanzheng"] = function(self, prompt, request)
    local valid = {}
    local destlist = self.room:getOtherPlayers(self.player)
    destlist = self:sort(destlist,"hp")
    local n = source_query(self.player, "getMark", "nhyanzheng-PlayClear")
    for _,friend in sgs.list(destlist)do
        if #valid>=n then break end
        if self:isEnemy(friend)
        then table.insert(valid,friend:objectName()) end
    end
    for _,friend in sgs.list(destlist)do
        if #valid>=n then break end
        if not self:isFriend(friend)
        and not table.contains(valid,friend:objectName())
        then table.insert(valid,friend:objectName()) end
    end
    if #valid>0
    then
        return string.format("#nhyanzheng:.:->%s",table.concat(valid,"+"))
    end
end

ai_fill_skill.nosjinwanyi = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self:addHandPile()
    cards = self:sortByKeepValue(cards,nil,true)
    for _,c in sgs.list(cards)do
        local eg = printed_card(self,c:getKnownEffectiveId())
        if card_fact(self,c,"YingBianEffects")=="" then continue end
        for _,cn in sgs.list({"zhujinqiyuan","chuqibuyi","drowning","dongzhuxianji"})do
            local tc = preview(self,cn)
            if not tc or c:objectName()==cn then continue end
            mutate(self,tc,"skill","nosjinwanyi")
            mutate(self,tc,"add",c)
            local d = use_card(self,tc)
            self:setPriorityValue("nosjinwanyi",self:getPriorityValue(tc:getClassName()),"newgenerals")
            set_state(self,"wy_to",d.to)
            if d.card and d.to
            and source_query(tc, "isAvailable", self.player)
            then return parse_action(self,"#nosjinwanyi:"..c:getKnownEffectiveId()..":"..cn) end
        end
    end
end

ai_card_use["#nosjinwanyi"] = function(self, card, use, request)
    if get_state(self,"wy_to")
    then
        use.card = card
        use.to = get_state(self,"wy_to")
    end
end

sgs.ai_use_value.nosjinwanyi = 9.4
sgs.ai_use_priority.nosjinwanyi = 7.8


sgs.ai_skill_playerchosen.nosjinxuanbei = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not self:isEnemy(target)
        then return target end
    end
end



ai_skill_invoke.jinzhaosong = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    if target
    then
        return (not self:isEnemy(target)) or false
    end
    return false

end

ai_skill_invoke.jinzhaosong_lei = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

sgs.ai_skill_playerchosen.jinzhaosong = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        and source_query(self, "doDisCard", target, "ej")
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target)
        and source_query(target, "getCardCount")>0
        then return target end
    end
end

ai_skill_invoke.jinzhaosong_fu = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = scoped_player(self,"JinZhaosongDrawer")
    if target then return (not self:isEnemy(target)) or false end
    return false

end

ai_skill_use["@@jinzhaosong"] = function(self, prompt, request)
    local valid = {}
    local destlist = self.room:getOtherPlayers(self.player)
    destlist = self:sort(destlist,"hp")
    for _,friend in sgs.list(destlist)do
        if #valid>1 then break end
        if self:isEnemy(friend)
        and friend:getStrategyFlag("jinzhaosong_can_choose")
        then table.insert(valid,friend:objectName()) end
    end
    for _,friend in sgs.list(destlist)do
        if #valid>1 then break end
        if not self:isFriend(friend)
        and friend:getStrategyFlag("jinzhaosong_can_choose")
        and not table.contains(valid,friend:objectName())
        then table.insert(valid,friend:objectName()) end
    end
    if #valid>0
    then
        return string.format("#jinzhaosong:.:->%s",table.concat(valid,"+"))
    end
end


sgs.ai_skill_playerchosen.jinlisi = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not self:isEnemy(target)
        then return target end
    end
end


ai_fill_skill.zuoxing = function(self, options, request)
    local inclusive = options and options.inclusive

    for _,name in sgs.list(pattern_names(self))do
        local poi = preview(self,name)
        if poi==nil then continue end
        mutate(self,poi,"skill","zuoxing")
        if source_query(poi, "isAvailable", self.player)
        and source_query(poi, "isNDTrick") and source_query(poi, "isDamageCard") then
            local dummy = use_card(self,poi)
            if dummy.card and dummy.to then
                set_state(self,"zx_to",dummy.to)
                self:setPriorityValue("zuoxing",self:getPriorityValue(poi:getClassName()),"newgenerals")
                if source_query(poi, "canRecast") and dummy.to:length()<1 then continue end
                return parse_action(self,"#zuoxing:.:"..name)
            end
        end
    end
    for _,name in sgs.list(pattern_names(self))do
        local poi = preview(self,name)
        if poi==nil then continue end
        mutate(self,poi,"skill","zuoxing")
        if source_query(poi, "isAvailable", self.player)
        and source_query(poi, "isNDTrick") and name~="amazing_grace"
        and name~="collateral" then
            local dummy = use_card(self,poi)
            if dummy.card and dummy.to then
                set_state(self,"zx_to",dummy.to)
                self:setPriorityValue("zuoxing",self:getPriorityValue(poi:getClassName()),"newgenerals")
                if source_query(poi, "canRecast") and dummy.to:length()<1 then continue end
                return parse_action(self,"#zuoxing:.:"..name)
            end
        end
    end
end

ai_card_use["#zuoxing"] = function(self, card, use, request)
    use.card = card
    use.to = get_state(self,"zx_to")
end

sgs.ai_use_value.zuoxing = 8.4
sgs.ai_use_priority.zuoxing = 8.4

ai_fill_skill.huishi = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#huishiCard:.:")
end

ai_card_use["#huishiCard"] = function(self, card, use, request)
    use.card = card
end

sgs.ai_use_value.huishiCard = 8.4
sgs.ai_use_priority.huishiCard = 8.4

ai_skill_invoke.huishi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

sgs.ai_skill_playerchosen.huishi = function(self,players)
    players = self:sort(players,"handcard")
    for _,target in sgs.list(players)do
        if self:isFriend(target)
        then
            return target
        end
    end
end

sgs.ai_skill_playerchosen.godtianyi = function(self,players)
    local destlist = players
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
    self:sort(destlist,"maxhp",true)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        then
            return target
        end
    end
    return destlist[1]
end

sgs.ai_skill_playerchosen.zuoxing = function(self,players)
    local destlist = players
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
    self:sort(destlist,"maxhp")
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target)
        then
            return target
        end
    end
    return destlist[1]
end

ai_fill_skill.huishii = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#huishii:.:")
end

ai_card_use["#huishii"] = function(self, card, use, request)
    self:sort(self.friends,"hp")
    for _,ep in sgs.list(self.friends)do
        local skills = {}
        for _,sk in sgs.list(ep:getVisibleSkillList())do
            if source_query(sk, "getFrequency", ep)~=sgs.Skill_Wake
            or source_query(ep, "getMark", sk:objectName())>0
            then continue end
            table.insert(skills,sk:objectName())
        end
        if #skills>0
        and self.player:getMaxHp()>2
        and self.player:getLostHp()>1
        and self.player:getMaxHp()>=self.room:alivePlayerCount()
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
    for _,ep in sgs.list(self.friends)do
        if self:isWeak(ep) and self.player:getMaxHp()>2
        and self.player:getLostHp()>1
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
end

sgs.ai_use_value.huishii = 8.4
sgs.ai_use_priority.huishii = 8.5

ai_skill_use["@@dangmo"] = function(self, prompt, request)
    local valid = {}
    local destlist = self.room:getOtherPlayers(self.player)
    destlist = self:sort(destlist,"hp")
    local n = self.player:getHp()-1
    for _,friend in sgs.list(destlist)do
        if #valid>=n then break end
        if self:isEnemy(friend)
        and friend:getStrategyFlag("dangmo")
        then table.insert(valid,friend:objectName()) end
    end
    for _,friend in sgs.list(destlist)do
        if #valid>=n then break end
        if not self:isFriend(friend)
        and friend:getStrategyFlag("dangmo")
        and not table.contains(valid,friend:objectName())
        then table.insert(valid,friend:objectName()) end
    end
    if #valid>0
    then
        return string.format("#dangmo:.:->%s",table.concat(valid,"+"))
    end
end

ai_fill_skill.yingba = function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getMaxHp()>2
    then
        return parse_action(self,"#yingba:.:")
    end
end

ai_card_use["#yingba"] = function(self, card, use, request)
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

sgs.ai_use_value.yingba = 8.4
sgs.ai_use_priority.yingba = 7.4

sgs.ai_skill_askforyiji.pinghe = function(self,card_ids)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards)
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
        if self:isFriend(p) then return p,cards[1]:getEffectiveId() end
    end
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
        if self:isEnemy(p) then continue end
        return p,cards[1]:getEffectiveId()
    end
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
        return p,cards[1]:getEffectiveId()
    end
end

sgs.ai_use_revises.pinghe = function(self,card)
    if card:isKindOf("Peach")
    then return false end
end

ai_skill_choice.dinghan = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    local items = choices:split("+")
    local cns = property_value(self,self.player,"SkillDescriptionRecord_dinghan"):split("+")
    if table.contains(items,"remove") then
        for _,pn in sgs.list(cns)do
            local c = preview(self,pn)
            if c then
                set_state(self,"ai_dinghan_choice",c:objectName())
                if source_query(c, "isDamageCard") and self:isWeak()
                and source_query(self, "getRestCardsNum", c:getClassName())>0
                then return ai_choice_result(("remove"), options) end
                if c:isKindOf("DelayedTrick")
                and source_query(self, "getRestCardsNum", c:getClassName())>0
                then return ai_choice_result(("remove"), options) end
            end
        end
    end
    if table.contains(items,"add") then
        for d,c in sgs.list(self.player:getHandcards())do
            if table.contains(cns,c:objectName())
            or source_query(c, "isZhinangCard") then continue end
            if source_query(c, "targetFixed") and not source_query(c, "isDamageCard") then
                set_state(self,"ai_dinghan_choice",c:objectName())
                d = use_card(self,c)
                if d.card and d.to
                then return ai_choice_result(("add"), options) end
            end
        end
        for _,pn in sgs.list(pattern_names(self))do
            if table.contains(cns,pn) then continue end
            local c = preview(self,pn)
            if c then
                if table.contains(sgs.ZhinangClassName,c:getClassName())
                or source_query(c, "isZhinangCard") then continue end
                set_state(self,"ai_dinghan_choice",pn)
                if source_query(c, "targetFixed") and not source_query(c, "isDamageCard")
                and source_query(self, "getRestCardsNum", c:getClassName())>0
                then return ai_choice_result(("add"), options) end
            end
        end
        for _,pn in sgs.list(pattern_names(self))do
            if table.contains(cns,pn) then continue end
            local c = preview(self,pn)
            if c then
                if table.contains(sgs.ZhinangClassName,c:getClassName())
                or source_query(c, "isZhinangCard") then continue end
                set_state(self,"ai_dinghan_choice",pn)
                if c:isKindOf("GlobalEffect") and not source_query(c, "isDamageCard")
                and source_query(self, "getRestCardsNum", c:getClassName())>0
                then return ai_choice_result(("add"), options) end
            end
        end
    end
    return ai_choice_result(("cancel"), options)
end

sgs.ai_skill_askforag.dinghan = function(self,card_ids)
    for c,id in sgs.list(card_ids)do
        c = known_card(self,id)
        if c:objectName()==get_state(self,"ai_dinghan_choice")
        then return id end
    end
    for c,id in sgs.list(card_ids)do
        c = known_card(self,id)
        if source_query(c, "isDamageCard") and self:isWeak()
        and source_query(self, "getRestCardsNum", c:getClassName())>0
        then return id end
    end
    for c,id in sgs.list(card_ids)do
        c = known_card(self,id)
        if source_query(c, "targetFixed") and not source_query(c, "isDamageCard")
        and source_query(self, "getRestCardsNum", c:getClassName())>0
        then return id end
    end
    for c,id in sgs.list(card_ids)do
        c = known_card(self,id)
        if c:isKindOf("GlobalEffect") and not source_query(c, "isDamageCard")
        and source_query(self, "getRestCardsNum", c:getClassName())>0
        then return id end
    end
end

sgs.ai_target_revises.tianzuo = function(to,card,self)
    if card:isKindOf("Qizhengxiangsheng")
    and not self:isFriend(to)
    then return true end
end

sgs.ai_target_revises.dinghan = function(to,card,self)
    if card:getTypeId()==2
    then
        local cns = property_value(self,to,"SkillDescriptionRecord_dinghan"):split("+")
        if table.contains(cns,card:objectName())
        then return end
        return true
    end
end

sgs.ai_skill_playerchosen.kemobileyijin = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        then
            if source_query(self.player, "getMark", "@keyijin_houren")>0 and self:isWeak(target) and target:isWounded()
            then
                set_choice(self,"kemobileyijin","keyijin_houren")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_tongshen")>0 and self:isWeak(target)
            then
                set_choice(self,"kemobileyijin","keyijin_tongshen")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_wushi")>0 and not self:isWeak(target)
            then
                set_choice(self,"kemobileyijin","keyijin_wushi")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_jinmi")>0 and source_query(target, "isSkipped", sgs.Player_Play)
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target)
        then
            if source_query(self.player, "getMark", "@keyijin_guxiong")>0 and self:isWeak(target)
            then
                set_choice(self,"kemobileyijin","keyijin_guxiong")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_yongbi")>0 and target:getHandcardNum()<4
            then
                set_choice(self,"kemobileyijin","keyijin_yongbi")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_jinmi")>0 and self:getOverflow()~=0
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if not self:isFriend(target)
        then
            if source_query(self.player, "getMark", "@keyijin_guxiong")>0 and self:isWeak(target)
            then
                set_choice(self,"kemobileyijin","keyijin_guxiong")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_yongbi")>0 and target:getHandcardNum()<4
            then
                set_choice(self,"kemobileyijin","keyijin_yongbi")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_jinmi")>0 and self:getOverflow()~=0
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if not self:isEnemy(target)
        then
            if source_query(self.player, "getMark", "@keyijin_houren")>0 and self:isWeak(target) and target:isWounded()
            then
                set_choice(self,"kemobileyijin","keyijin_houren")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_tongshen")>0 and self:isWeak(target)
            then
                set_choice(self,"kemobileyijin","keyijin_tongshen")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_wushi")>0 and not self:isWeak(target)
            then
                set_choice(self,"kemobileyijin","keyijin_wushi")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_jinmi")>0 and source_query(target, "isSkipped", sgs.Player_Play)
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
end


sgs.ai_card_priority.xingtu = function(self,card,v)
    if source_query(self.player, "getMark", "&xingtu") % card:getNumber() == 0
    then return 10 end
end
sgs.ai_card_priority.nosxingtu = function(self,card,v)
    if source_query(self.player, "getMark", "&nosxingtu") % card:getNumber() == 0
    then return 10 end
end


ai_fill_skill.kehuiyao = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#kehuiyaoCard:.:")
end

ai_card_use["#kehuiyaoCard"] = function(self, card, use, request)
    if not self:isWeak() then
        self:sort(self.enemies)
        for _, ep in ipairs(self.enemies) do
            local can = true
            for _,sk in ipairs(sgs.getPlayerSkillList(ep)) do
                local ts = trigger_skill(self,sk:objectName())
                if ts and ts:hasEvent(sgs.Damage) then
                    can = false
                    break
                end
            end
            if can then
                for _, fp in ipairs(self.friends_noself) do
                    for _,sk in ipairs(sgs.getPlayerSkillList(fp)) do
                        local ts = trigger_skill(self,sk:objectName())
                        if ts and ts:hasEvent(sgs.Damaged) then
                            use.card = card
                            use.to:append(ep)
                            use.to:append(fp)
                            return
                        end
                    end
                end
            end
        end
        for _, fp in ipairs(self.friends_noself) do
            for _,sk in ipairs(sgs.getPlayerSkillList(fp)) do
                local ts = trigger_skill(self,sk:objectName())
                if ts and ts:hasEvent(sgs.Damage) then
                    for _, ep in ipairs(self.enemies) do
                        local can = true
                        for _,sk in ipairs(sgs.getPlayerSkillList(ep)) do
                            local ts = trigger_skill(self,sk:objectName())
                            if ts and ts:hasEvent(sgs.Damaged) then
                                can = false
                                break
                            end
                        end
                        if can then
                            use.card = card
                            use.to:append(fp)
                            use.to:append(ep)
                            return
                        end
                    end
                end
            end
        end
        for _, fp in ipairs(self.friends_noself) do
            for _,sk in ipairs(sgs.getPlayerSkillList(fp)) do
                local ts = trigger_skill(self,sk:objectName())
                if ts and ts:hasEvent(sgs.Damage) then
                    for _, ep in ipairs(self.enemies) do
                        use.card = card
                        use.to:append(fp)
                        use.to:append(ep)
                        return
                    end
                end
            end
        end
        for _, ep in ipairs(self.enemies) do
            for _, fp in ipairs(self.friends_noself) do
                for _,sk in ipairs(sgs.getPlayerSkillList(fp)) do
                    local ts = trigger_skill(self,sk:objectName())
                    if ts and ts:hasEvent(sgs.Damaged) then
                        use.card = card
                        use.to:append(ep)
                        use.to:append(fp)
                        return
                    end
                end
            end
            break
        end
        if self.player:hasSkill("kequesong") and source_query(self.player, "getMark", "&kequesong-Clear")<1 then
            self:sort(self.friends_noself,nil,true)
            for _, fp in ipairs(self.friends_noself) do
                for _, ep in ipairs(self.enemies) do
                    use.card = card
                    use.to:append(fp)
                    use.to:append(ep)
                    return
                end
            end
            for _, fp in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                for _, ep in ipairs(self.enemies) do
                    use.card = card
                    use.to:append(fp)
                    use.to:append(ep)
                    return
                end
            end
            for _, fp in sgs.qlist(self.room:getOtherPlayers(self.player)) do
                for _, ep in sgs.qlist(self.room:getOtherPlayers(fp)) do
                    if ep==self.player then continue end
                    use.card = card
                    use.to:append(fp)
                    use.to:append(ep)
                    return
                end
            end
        end
    end
end

sgs.ai_skill_playerchosen.kequesong = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets)
    for _, p in ipairs(targets) do
        if self:isFriend(p) then
            return p
        end
    end
    return nil
end

ai_skill_choice.kequesong = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    return ai_choice_result((self.player:isWounded() and (self:isWeak() or self.player:getHandcardNum()>self.player:getHp()) and items[2]
    or items[1]), options)
end

sgs.ai_skill_playerchosen.kehuiyaoone = function(self, targets)
    targets = sgs.QList2Table(targets)
    local theweak = AIList.new({})
    local theweaktwo = AIList.new({})
    for _, p in ipairs(targets) do
        if self:isEnemy(p) then
            theweak:append(p)
        end
    end
    for _,qq in sgs.qlist(theweak) do
        if theweaktwo:isEmpty() then
            theweaktwo:append(qq)
        else
            local inin = 1
            for _,pp in sgs.qlist(theweaktwo) do
                if (pp:getHp() < qq:getHp()) then
                    inin = 0
                end
            end
            if (inin == 1) then
                theweaktwo:append(qq)
            end
        end
    end
    if theweaktwo:length() > 0 then
        return theweaktwo:at(0)
    end
    return nil
end

sgs.ai_skill_playerchosen.kehuiyaotwo = function(self, targets)
    targets = sgs.QList2Table(targets)
    local theweak = AIList.new({})
    local theweaktwo = AIList.new({})
    for _, p in ipairs(targets) do
        if self:isFriend(p) then
            theweak:append(p)
        end
    end
    for _,qq in sgs.qlist(theweak) do
        if theweaktwo:isEmpty() then
            theweaktwo:append(qq)
        else
            local inin = 1
            for _,pp in sgs.qlist(theweaktwo) do
                if (pp:getHp() < qq:getHp()) then
                    inin = 0
                end
            end
            if (inin == 1) then
                theweaktwo:append(qq)
            end
        end
    end
    if theweaktwo:length() > 0 then
        return theweaktwo:at(0)
    end
    return nil
end


ai_skill_choice.keolshanduanmpjd = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    return ai_choice_result(("shanduanfour"), options)
end

ai_skill_choice.keolshanduancpgjfw = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local two = 1
    for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if self:isEnemy(p) and source_query(self.player, "inMyAttackRange", p) then
            two = 0
        end
        break
    end
    if two == 1 then
        return ai_choice_result(("shanduantwo"), options)
    else
        return ai_choice_result(("shanduanone"), options)
    end

    return ai_choice_result(nil, options)
end

ai_skill_choice.keolshanduancpslash = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    return ai_choice_result((items[#items]), options)
end

sgs.ai_skill_discard.keolhuanfu = function(self, discard_num, min_num, optional, include_equip)
    local to_discard = {}
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    if self.player:getStrategyFlag("wantusehuanfu") then
        table.insert(to_discard, cards[1]:getEffectiveId())
        return to_discard
    else
        return self:askForDiscard("dummyreason", discard_num, min_num, true, true)
    end
end

ai_fill_skill.keolqingyi = function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getStrategyHasUsed("keolqingyiCard") then return end
    return parse_action(self,"#keolqingyiCard:.:")
end

ai_card_use["#keolqingyiCard"] = function(self, card, use, request)
    if not self.player:getStrategyHasUsed("#keolqingyiCard") then
        local room = self.room
        local all = room:getOtherPlayers(self.player)
        local enys = AIList.new({})
        for _, p in sgs.qlist(all) do
            if self:isEnemy(p) and (enys:length() < 2) then
                enys:append(p)
            end
        end
        if (enys:length() > 0) then
            for _, p in sgs.qlist(enys) do
                use.card = card
                use.to:append(p)
            end
        end
        return
    end
end

sgs.ai_use_value.keolqingyiCard = 8.5
sgs.ai_use_priority.keolqingyiCard = 9.5
sgs.ai_card_intention.keolqingyiCard = 80


sgs.ai_skill_playerchosen.keolzeyue = function(self, targets)
    targets = sgs.QList2Table(targets)
    local theweak = AIList.new({})
    local theweaktwo = AIList.new({})
    for _, p in ipairs(targets) do
        if self:isEnemy(p) then
            theweak:append(p)
        end
    end
    for _,qq in sgs.qlist(theweak) do
        if theweaktwo:isEmpty() then
            theweaktwo:append(qq)
        else
            local inin = 1
            for _,pp in sgs.qlist(theweaktwo) do
                if (pp:getHp() < qq:getHp()) then
                    inin = 0
                end
            end
            if (inin == 1) then
                theweaktwo:append(qq)
            end
        end
    end
    if theweaktwo:length() > 0 then
        return theweaktwo:at(0)
    end
    return nil
end


sgs.ai_skill_playerchosen.kemobileyijin = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        then
            if source_query(self.player, "getMark", "@keyijin_houren")>0 and self:isWeak(target) and target:isWounded()
            then
                set_choice(self,"kemobileyijin","keyijin_houren")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_tongshen")>0 and self:isWeak(target)
            then
                set_choice(self,"kemobileyijin","keyijin_tongshen")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_wushi")>0 and not self:isWeak(target)
            then
                set_choice(self,"kemobileyijin","keyijin_wushi")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_jinmi")>0 and source_query(target, "isSkipped", sgs.Player_Play)
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target)
        then
            if source_query(self.player, "getMark", "@keyijin_guxiong")>0 and self:isWeak(target)
            then
                set_choice(self,"kemobileyijin","keyijin_guxiong")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_yongbi")>0 and target:getHandcardNum()<4
            then
                set_choice(self,"kemobileyijin","keyijin_yongbi")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_jinmi")>0 and self:getOverflow()~=0
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if not self:isFriend(target)
        then
            if source_query(self.player, "getMark", "@keyijin_guxiong")>0 and self:isWeak(target)
            then
                set_choice(self,"kemobileyijin","keyijin_guxiong")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_yongbi")>0 and target:getHandcardNum()<4
            then
                set_choice(self,"kemobileyijin","keyijin_yongbi")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_jinmi")>0 and self:getOverflow()~=0
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if not self:isEnemy(target)
        then
            if source_query(self.player, "getMark", "@keyijin_houren")>0 and self:isWeak(target) and target:isWounded()
            then
                set_choice(self,"kemobileyijin","keyijin_houren")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_tongshen")>0 and self:isWeak(target)
            then
                set_choice(self,"kemobileyijin","keyijin_tongshen")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_wushi")>0 and not self:isWeak(target)
            then
                set_choice(self,"kemobileyijin","keyijin_wushi")
                return target
            end
            if source_query(self.player, "getMark", "@keyijin_jinmi")>0 and source_query(target, "isSkipped", sgs.Player_Play)
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
end

ai_fill_skill.kemobileguanzong = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#kemobileguanzongCard:.:")
end

ai_card_use["#kemobileguanzongCard"] = function(self, card, use, request)
    set_state(self,"gz_to",nil)
    for _,fp in sgs.list(self.friends_noself)do
        for _,sk in sgs.list(aiConnect(fp))do
            local tsk = trigger_skill(self,sk)
            if tsk and tsk:hasEvent(sgs.Damage)
            then
                use.card = card
                use.to:append(fp)
                return
            end
        end
    end
    for _,ep in sgs.list(self.enemies)do
        local can = true
        for _,sk in sgs.list(aiConnect(ep))do
            local tsk = trigger_skill(self,sk)
            if tsk and tsk:hasEvent(sgs.Damage)
            then can = false break end
        end
        if can==false then break end
        for _,fp in sgs.list(self.friends_noself)do
            for _,sk in sgs.list(aiConnect(fp))do
                local tsk = trigger_skill(self,sk)
                if tsk and tsk:hasEvent(sgs.Damaged)
                then
                    use.card = card
                    use.to:append(ep)
                    set_state(self,"gz_to",fp)
                    return
                end
            end
        end
    end
end

sgs.ai_use_value.kemobileguanzongCard = 3.4
sgs.ai_use_priority.kemobileguanzongCard = 2.7

sgs.ai_skill_playerchosen.kemobileguanzongCard = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
        if target==get_state(self,"gz_to")
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not self:isFriend(target)
        then return target end
    end
end

sgs.ai_skill_playerchosen.keoltongdu = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target) and self:isWeak()
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target)
        then return target end
    end
    self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        and target:getHandcardNum()>5
        then return target end
    end
    return destlist[1]
end

ai_fill_skill.keolzhubi = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#keolzhubiCard:.:")
end

ai_card_use["#keolzhubiCard"] = function(self, card, use, request)
    self:sort(self.friends,"card")
    for _,fp in sgs.list(self.friends)do
        if not fp:getStrategyFlag("keolzhubiTo")
        and source_query(fp, "getCardCount")>1
        then
            use.card = card
            strategy_flag(self,fp,"keolzhubiTo")
            use.to:append(fp)
            return
        end
    end
    for _,fp in sgs.list(self.enemies)do
        if not fp:getStrategyFlag("keolzhubiTo")
        and source_query(fp, "getCardCount")==1
        then
            use.card = card
            strategy_flag(self,fp,"keolzhubiTo")
            use.to:append(fp)
            return
        end
    end
    for _,fp in sgs.list(self.friends)do
        if source_query(fp, "getCardCount")>2
        then
            use.card = card
            strategy_flag(self,fp,"keolzhubiTo")
            use.to:append(fp)
            return
        end
    end
end

sgs.ai_use_value.keolzhubiCard = 3.4
sgs.ai_use_priority.keolzhubiCard = 6.2

ai_skill_use["@@keolzhubi"] = function(self, prompt, request)
    local valid = {}
    local ids = scope_list(self,"keolzhubiForAI")
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _,c in sgs.list(cards)do
        if owner_tip(self,c,"keolzhubi")
        then
            for _,id in sgs.list(ids)do
                if table.contains(valid,id) then continue end
                local c2 = known_card(self,id)
                if self:cardNeed(c2)>self:cardNeed(c)
                then
                    table.insert(valid,c:getKnownId())
                    table.insert(valid,id)
                    break
                end
            end
        end
    end
    if #valid<2 then return end
    return string.format("#keolzhubiVSCard:%s:",table.concat(valid,"+"))
end

sgs.ai_skill_playerchosen.keolzhuri = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"handcard")
    local mc = self:getMaxCard()
    if mc then
        for _,target in sgs.list(destlist)do
            if self:isEnemy(target) and self:isWeak(target)
            and mc:getNumber()>9 then return target end
        end
        for _,target in sgs.list(destlist)do
            if self:isEnemy(target)
            and mc:getNumber()>9 then return target end
        end
        for _,target in sgs.list(destlist)do
            if not self:isFriend(target)
            and mc:getNumber()>9 then return target end
        end
        self:sort(destlist,"card",true)
        for _,target in sgs.list(destlist)do
            if self:isFriend(target)
            and mc:getNumber()>6 then return target end
        end
        for _,target in sgs.list(destlist)do
            if self:isEnemy(target) and self.player:getPhase()>sgs.Player_Play
            then return target end
        end
    end
end

ai_skill_use["@@keolzhuri"] = function(self, prompt, request)
    local ids = scope_list(self,"keolzhuriForAI")
    for _,id in sgs.list(ids)do
        local c2 = known_card(self,id)
        if source_query(c2, "isAvailable", self.player) then
            local d = use_card(self,c2)
            if d.card then
                local tos = {}
                for _,p in sgs.list(d.to)do
                    table.insert(tos,p:objectName())
                end
                if source_query(c2, "canRecast") and #tos<1 then continue end
                return r45_selected_borrowed(self,c2,d.to,tos)
            end
        end
    end
end

ai_skill_choice.keolzhuri = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    local items = choices:split("+")
    return ai_choice_result(((self.player:getPhase()>sgs.Player_Play or self:isWeak()) and items[2] or items[1]), options)
end

ai_skill_invoke.keolranji = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (source_query(self.player, "getMark", "keolranji_used-Clear") == self.player:getHp()) or false
end

ai_skill_choice.keolranji = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    local items = choices:split("+")
    return ai_choice_result((self:isWeak() and items[1] or items[2]), options)
end

sgs.ai_use_revises.keolranji = function(self,card,use)
    if source_query(self.player, "getMark", "&keolranji_ban")>0 and card:isKindOf("Peach") then
        return false
    end
end

ai_skill_invoke.keolbotu = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

ai_skill_use["@@keolxiejuslash"] = function(self, prompt, request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards)
    for _,h in sgs.list(cards)do
        local c = preview(self)
        mutate(self,c,"skill","_keolxieju")
        mutate(self,c,"add",h)
        if source_query(self.player, "isLocked", c) or not h:isBlack() then continue end
        local dummy = use_card(self,c)
        if dummy.card and dummy.to then
            local tos = {}
            for _,p in sgs.list(dummy.to)do
                table.insert(tos,p:objectName())
            end
            return c:toString().."->"..table.concat(tos,"+")
        end
    end
end

sgs.ai_skill_discard.keolshuangxiong = function(self, discard_num, min_num, optional, include_equip)
    local cards = self.player:getCards("he")
    if cards:length()>2 then
        return self:askForDiscard("dummyreason", 1, 1, true, true)
    end
end

ai_fill_skill.keolshuangxiong = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards)
    for _,h in sgs.list(cards)do
        if source_query(self.player, "getMark", "&keolshuangxiong+"..h:getColorString().."-Clear")>0
        then continue end
        local c = preview(self,"duel")
        mutate(self,c,"skill","keolshuangxiong")
        mutate(self,c,"add",h)
        if source_query(c, "isAvailable", self.player)
        then return c end
    end
end


ai_skill_invoke.keolqiejian = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

ai_fill_skill.tyzhuangpo = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards)
    for _,h in sgs.list(cards)do
        local des = source_query(h, "getDescription")
        if string.find(des,"【杀】") then
            local c = preview(self,"duel")
            mutate(self,c,"skill","tyzhuangpo")
            mutate(self,c,"add",h)
            if source_query(c, "isAvailable", self.player)
            then return c end
        end
    end
end

ai_skill_invoke.tyzhuangpo = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local to = data:toPlayer()
    return (self:isEnemy(to)
    and source_query(to, "getCardCount")>0) or false
end

ai_skill_choice.tyzhuangpo = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    local items = choices:split("+")
    local to = data:toPlayer()
    return ai_choice_result((items[math.min(source_query(to, "getCardCount"),#items)]), options)
end

ai_skill_invoke.yongyiyong = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local to = data:toPlayer()
    return (self:isEnemy(to)
    and not self:isFriend(to) and #self.friends_noself<1) or false
end

ai_fill_skill.yongshanxie = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#yongshanxieCard:.:")
end

ai_card_use["#yongshanxieCard"] = function(self, card, use, request)
    use.card = card
end

sgs.ai_use_value.yongshanxieCard = 3.4
sgs.ai_use_priority.yongshanxieCard = 6.2

sgs.ai_skill_discard.keolhuanfu = function(self,x,n)
    local to_cards = {}
    local use = scoped_struct(self,"keolhuanfuData","use")
    if use.to:contains(self.player) then
        if self:getCardsNum("Jink")<1 then
            local m = source_query(self, "ajustDamage", use.from, self.player, 1, use.card)
            if m>0 and m<self.player:getHp()+self:getCardsNum("Peach,Analeptic") then
                local cards = self.player:getCards("he")
                cards = sgs.QList2Table(cards)
                self:sortByKeepValue(cards)
                for _,c in sgs.list(cards)do
                    if source_query(self.player, "isJilei", c) then continue end
                    table.insert(to_cards,c:getKnownEffectiveId())
                    if #to_cards>=x or #to_cards>=m then break end
                end
            end
        end
    elseif use.from==self.player then
        if getCardsNum("Jink",use.to:first(),self.player)<1 then
            local m = source_query(self, "ajustDamage", use.from, use.to:first(), 1, use.card)
            if m>0 then
                local cards = self.player:getCards("he")
                cards = sgs.QList2Table(cards)
                self:sortByKeepValue(cards)
                for _,c in sgs.list(cards)do
                    if source_query(self.player, "isJilei", c) then continue end
                    table.insert(to_cards,c:getKnownEffectiveId())
                    if #to_cards>=x or #to_cards>=m then break end
                end
            end
        end
    end
    return to_cards
end

ai_fill_skill.keolqingyi = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#keolqingyiCard:.:")
end

ai_card_use["#keolqingyiCard"] = function(self, card, use, request)
    self:sort(self.enemies,"card")
    for _,p in sgs.list(self.enemies)do
        if source_query(p, "getCardCount")>0 and use.to:length()<2 then
            use.card = card
            use.to:append(p)
        end
    end
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
        if source_query(p, "getCardCount")>0 and use.to:length()<2
        and not(use.to:contains(p) or self:isFriend(p)) then
            use.card = card
            use.to:append(p)
        end
    end
end

sgs.ai_use_value.keolqingyiCard = 3.4
sgs.ai_use_priority.keolqingyiCard = 6.2

ai_skill_invoke.keolqingyi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end


sgs.ai_skill_playerchosen.keolzeyue = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target)
        and #self.enemies>=source_query(self.player, "aliveCount")/2
        then return target end
    end
end

ai_skill_invoke.keolkangrui = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

ai_skill_choice.keolkangrui = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local to = data:toPlayer()
    return ai_choice_result((self:isFriend(to) and to:isWounded() and items[1]
    or items[2]), options)
end

ai_skill_invoke.keolqiejian = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local to = data:toPlayer()
    return (self:isFriend(to)
    or #self:poisonCards("ej")>0
    or source_query(self, "doDisCard", to, "ej")) or false
end

sgs.ai_skill_playerchosen.keolqiejian = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
        if source_query(self, "doDisCard", target, "ej")
        then return target end
    end
end

sgs.ai_skill_playerchosen.keolnishou = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not self:isEnemy(target)
        then return target end
    end
end

ai_skill_invoke.keolguangao = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local st = data:toString()
    local sts = st:split(":")
    local to = BeMan(self.room,sts[2])
    if self:isFriend(to) then
        return (to:getHandcardNum()%2==0) or false
    elseif to:getHandcardNum()%2~=0
    then
        return (self:isEnemy(to)
        or #self.friends_noself<1) or false
    end
    return false

end

sgs.ai_skill_playerschosen.keolguangao = function(self,players,x,n)
    local tos = {}
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
        if self:isFriend(target) and #tos<x
        then table.insert(tos,target) end
    end
    return tos
end

ai_fill_skill.keolxieju = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#keolxiejuCard:.:")
end

ai_card_use["#keolxiejuCard"] = function(self, card, use, request)
    self:sort(self.friends,"card",true)
    for _,p in sgs.list(self.friends)do
        if source_query(p, "getCardCount")>0 and source_query(p, "getMark", "keolxiejutar-Clear")>0 then
            use.card = card
            use.to:append(p)
        end
    end
end

sgs.ai_use_value.keolxiejuCard = 3.4
sgs.ai_use_priority.keolxiejuCard = 2.2



ai_fill_skill.keolshandao = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#keolshandaoCard:.:")
end

ai_card_use["#keolshandaoCard"] = function(self, card, use, request)
    self:sort(self.friends,"card",true)
    for _,p in sgs.list(self.friends)do
        if source_query(p, "getCardCount")>0 then
            use.card = card
            use.to:append(p)
        end
    end
    for _,p in sgs.list(self.enemies)do
        if source_query(p, "getCardCount")>0 and source_query(self, "doDisCard", p, "e") then
            use.card = card
            use.to:append(p)
        end
    end
    for _,p in sgs.list(self.room:getAllPlayers())do
        if not(self:isEnemy(p) or use.to:contains(p))
        and source_query(p, "getCardCount")>0 and #self.enemies>0 then
            use.card = card
            use.to:append(p)
        end
    end
end

sgs.ai_use_value.keolshandaoCard = 3.4
sgs.ai_use_priority.keolshandaoCard = 4.2

ai_fill_skill.keolkenshang = function(self, options, request)
    local inclusive = options and options.inclusive

    local dc = preview(self)
    mutate(self,dc,"skill","keolkenshang")
    local cards = r45_handpile(self,"he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for i,c in sgs.list(cards)do
        if source_query(self.player, "isLocked", c) then continue end
        mutate(self,dc,"add",c)
        if dc:subcardsLength()>1 and (i>=#cards/2 or dc:subcardsLength()>=#self.enemies) then break end
    end
    return dc:subcardsLength()>1 and dc
end

function sgs.ai_cardsview.keolkenshang(self,class_name,player)
    local cn = pattern_names(self,class_name)
    if cn then
        local dc = preview(self,cn)
        mutate(self,dc,"skill","keolkenshang")
        local cards = r45_handpile(self,"he")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for i,c in sgs.list(cards)do
            if source_query(player, "isLocked", c) then continue end
            mutate(self,dc,"add",c)
            if i>#cards/2 or dc:subcardsLength()>#self.enemies then break end
        end
        return dc:subcardsLength()>1 and dc:toString()
    end
end



ai_fill_skill.keolxianbi = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#keolxianbiCard:.:")
end

ai_card_use["#keolxianbiCard"] = function(self, card, use, request)
    local tos = sgs.QList2Table(self.room:getAllPlayers())
    self:sort(tos,"equip",true)
    for _,p in sgs.list(tos)do
        if p:getEquips():length()>self.player:getHandcardNum() then
            use.card = card
            use.to:append(p)
            return
        end
    end
    for _,p in sgs.list(self.enemies)do
        if p:getEquips():length()<self.player:getHandcardNum() then
            use.card = card
            use.to:append(p)
            return
        end
    end
end

sgs.ai_use_value.keolxianbiCard = 3.4
sgs.ai_use_priority.keolxianbiCard = 3.2

sgs.ai_skill_playerchosen.keolzenrun = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target)
        and #self:poisonCards("he",target)<source_query(target, "getCardCount")/2
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not self:isFriend(target) and #self.friends_noself<1
        and #self:poisonCards("he",target)<source_query(target, "getCardCount")/2
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        and #self:poisonCards("he",target)>=source_query(target, "getCardCount")/2
        then return target end
    end
end

ai_skill_choice.keolzenrun = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local to = data:toPlayer()
    if self:isFriend(to) or self.player:getHandcardNum()<source_query(self.player, "getMaxCards")
    then return ai_choice_result((items[1]), options) end

    return ai_choice_result(nil, options)
end

sgs.ai_skill_playerchosen.keolzhuyan = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    local function compare_func(a,b)
        return source_query(a, "getMark", "keolzhuyanhp")-a:getHp()>source_query(b, "getMark", "keolzhuyanhp")-b:getHp()
    end
    table.sort(destlist,compare_func)
    set_choice(self,"keolzhuyan","hp")
    for _,target in sgs.list(destlist)do
        if source_query(target, "getMark", "beusedzhuyanhp"..self.player:objectName())<1
        and source_query(target, "getMark", "keolzhuyanhp")-target:getHp()>0
        and self:isFriend(target) and self:isWeak(target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if source_query(target, "getMark", "beusedzhuyanhp"..self.player:objectName())<1
        and source_query(target, "getMark", "keolzhuyanhp")-target:getHp()>0
        and self:isFriend(target) and target:isWounded()
        then return target end
    end
    destlist = sgs.reverse(destlist)
    for _,target in sgs.list(destlist)do
        if source_query(target, "getMark", "beusedzhuyanhp"..self.player:objectName())<1
        and self:isEnemy(target) and not self:isWeak(target)
        then return target end
    end
    local function compare_func(a,b)
        return source_query(a, "getMark", "keolzhuyansp")-a:getHandcardNum()>source_query(b, "getMark", "keolzhuyansp")-b:getHandcardNum()
    end
    table.sort(destlist,compare_func)
    set_choice(self,"keolzhuyan","sp")
    for _,target in sgs.list(destlist)do
        if source_query(target, "getMark", "beusedzhuyansp"..self.player:objectName())<1
        and source_query(target, "getMark", "keolzhuyansp")-target:getHandcardNum()>0
        and self:isFriend(target)
        then return target end
    end
    for _,target in sgs.list(sgs.reverse(destlist))do
        if source_query(target, "getMark", "beusedzhuyansp"..self.player:objectName())<1
        and source_query(target, "getMark", "keolzhuyansp")-target:getHandcardNum()<0
        and self:isEnemy(target)
        then return target end
    end
end

sgs.ai_skill_playerchosen.keolleijie = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
        if self:isFriend(target) and target:getHandcardNum()<5
        and self:getFinalRetrial(nil,"lightning")==1
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target)
        and self:getFinalRetrial(nil,"lightning")==1
        then return target end
    end
    local c = known_card(self,visible_top_id(self))
    for _,target in sgs.list(destlist)do
        if self:isFriend(target) and c:getStrategyFlag("visible") and c:getSuit()~=0
        and self:getFinalRetrial(nil,"lightning")<2
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if self:isFriend(target) and target:getHandcardNum()<5
        and self:getFinalRetrial(nil,"lightning")<2
        and not self:isWeak(target)
        then return target end
    end
end

ai_skill_use["@@keolsujislash"] = function(self, prompt, request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards)
    for _,h in sgs.list(cards)do
        local c = preview(self)
        mutate(self,c,"skill","keolsuji")
        mutate(self,c,"add",h)
        if source_query(self.player, "isLocked", c) or not h:isBlack() then continue end
        local dummy = use_card(self,c)
        if dummy.card then
            local tos = {}
            for _,p in sgs.list(dummy.to)do
                table.insert(tos,p:objectName())
            end
            return c:toString().."->"..table.concat(tos,"+")
        end
    end
end

ai_skill_invoke.keollangdao = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = data:toCardUse()
    for _,to in sgs.list(use.to)do
        if self:isEnemy(to) and self:isWeak(to)
        then return (true) or false end
    end
    return false

end

sgs.ai_skill_playerschosen.keollangdao = function(self,players,x,n)
    local tos = {}
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
        if (self:isEnemy(target) or #self.friends_noself<1) and #tos<x
        then table.insert(tos,target) end
    end
    return tos
end

ai_skill_choice.keolgoude = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    if table.contains(items,"slash") then
        local dc = preview(self)
        mutate(self,dc,"skill","_keolgoude")
        local d = use_card(self,dc)
        if d.card then
            set_state(self,"keolgoudeUse",d)
            return ai_choice_result(("slash"), options)
        end
    end
    if table.contains(items,"dis") then
        for _,p in sgs.list(self.enemies)do
            if p:getHandcardNum()<3 and source_query(self, "doDisCard", p, "h") then
                return ai_choice_result(("dis"), options)
            end
        end
    end
    if table.contains(items,"kingdom") then
        local ks = {}
        for _,p in sgs.list(self.room:getAllPlayers())do
            ks[p:getKnownKingdom()] = (ks[p:getKnownKingdom()] or 0)+1
        end
        local x = 0
        for k,n in pairs(ks)do
            if n>x then x = n end
        end
        for k,n in pairs(ks)do
            if n>=x and k~=self.player:getKnownKingdom() then
                set_choice(self,"keolgoudekingdom",k)
                return ai_choice_result(("kingdom"), options)
            end
        end
    end
    if table.contains(items,"draw") then
        return ai_choice_result(("draw"), options)
    end
    if table.contains(items,"dis") then
        for _,p in sgs.list(self.enemies)do
            if source_query(self, "doDisCard", p, "h") then
                return ai_choice_result(("dis"), options)
            end
        end
    end
    return ai_choice_result(("cancel"), options)
end

ai_skill_use["@@keolgoude"] = function(self, prompt, request)
    local dummy = get_state(self,"keolgoudeUse")
    if dummy.card then
        local tos = {}
        for _,p in sgs.list(dummy.to)do
            table.insert(tos,p:objectName())
        end
        return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end


ai_fill_skill.keolzhenying = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#keolzhenyingCard:.:")
end

ai_card_use["#keolzhenyingCard"] = function(self, card, use, request)
    self:sort(self.friends_noself,"handcard",true)
    for _,p in sgs.list(self.friends_noself)do
        if p:getHandcardNum()<=self.player:getHandcardNum()
        and p:getHandcardNum()<2 and self.player:getHandcardNum()<4 then
            use.card = card
            use.to:append(p)
            set_state(self,"keolzhenyingTo",p)
            return
        end
    end
    self:sort(self.enemies,"handcard",true)
    for _,p in sgs.list(self.enemies)do
        if p:getHandcardNum()<=self.player:getHandcardNum() then
            use.card = card
            use.to:append(p)
            set_state(self,"keolzhenyingTo",p)
            return
        end
    end
end

ai_skill_choice.keolzhenying = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local from = data:toPlayer()
    if from==self.player then
        if self:isFriend(get_state(self,"keolzhenyingTo")) then
            return ai_choice_result((items[#items]), options)
        end
    elseif self:isFriend(from) then
        return ai_choice_result((items[#items]), options)
    end

    return ai_choice_result(nil, options)
end

ai_skill_choice.keolfengyan = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local from = data:toPlayer()
    if self:isFriend(from) or #self.enemies>0 and not self:isEnemy(from) then
        return ai_choice_result((items[1]), options)
    end
    return ai_choice_result((items[2]), options)
end

ai_skill_invoke.keolbixin = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local tr = data:toString()
    for _,cn in sgs.list(tr:split("+"))do
        local dc = preview(self,cn)
        mutate(self,dc,"skill","_keolbixin")
        local d = use_card(self,dc)
        if d.card then
            set_choice(self,"keolbixin",cn)
            set_state(self,"keolbixinUse",d)
            return (true) or false
        end
    end
    return false

end

ai_skill_choice.keolbixintype = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local cards = self.player:getCards("h")
    local kv = {}
    for _,k in ipairs(items)do
        kv[k] = 0
    end
    for _,h in sgs.list(cards)do
        kv[source_query(h, "getType")] = (kv[source_query(h, "getType")] or 0)+1--q(self,"getKeepValue",h)
    end
    local x = 99
    for k,n in pairs(kv)do
        if n<x and table.contains(items,k) then x = n end
    end
    for k,n in pairs(kv)do
        if n<=x and table.contains(items,k) then
            return ai_choice_result((k), options)
        end
    end

    return ai_choice_result(nil, options)
end

ai_fill_skill.keolbixin = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#keolbixinCard:.:")
end

ai_card_use["#keolbixinCard"] = function(self, card, use, request)
    for _,p in sgs.list(pattern_names(self))do
        local dc = preview(self,p)
        if dc and dc:getTypeId()==1 and self:getCardsNum(dc:getClassName())<1
        and source_query(self.player, "getMark", "keolbixin_guhuo_remove_"..p)<1 then
            mutate(self,dc,"skill","keolbixin")
            if source_query(dc, "isAvailable", self.player) then
                local d = use_card(self,dc)
                if d.card then
                    use.card = parse_action(self,"#keolbixinCard:.:"..p)
                    use.to = d.to
                    self:setPriorityValue("keolbixinCard",self:getPriorityValue(dc:getClassName()),"newgenerals")
                    return
                end
            end
        end
    end
end

sgs.ai_use_value.keolbixinCard = 3.4
sgs.ai_use_priority.keolbixinCard = 3.2

sgs.ai_guhuo_card.keolbixin = function(self,toname,class_name)
    if self:getCardsNum(class_name)<1
    then return "#keolbixinCard:.:"..toname end
end

ai_fill_skill.keolshizhan = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#keolshizhanCard:.:")
end

ai_card_use["#keolshizhanCard"] = function(self, card, use, request)
    self:sort(self.enemies,"handcard")
    for _,p in sgs.list(self.enemies)do
        if self:getCardsNum("Slash")>getCardsNum("Slash",p,self.player)  then
            local dc = preview(self,"duel")
            mutate(self,dc,"skill","keolshizhan")
            if source_query(dc, "targetFilter", AIList.new({}), self.player, p) then
                use.card = card
                use.to:append(p)
                return
            end
        end
    end
end

sgs.ai_use_value.keolshizhanCard = 3.4
sgs.ai_use_priority.keolshizhanCard = 2.2


ai_fill_skill.xin2chuhai = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#xin2chuhaiCard:.:")
end

ai_card_use["#xin2chuhaiCard"] = function(self, card, use, request)
    self:sort(self.enemies,"handcard")
    local mc = self:getMaxCard()
    if mc and mc:getNumber()>8 then
        for i,c in sgs.list(source_query(self, "getPriorTurnUseCards"))do
            if i>1 and source_query(c, "isDamageCard") then
                local d = use_card(self,c)
                if d.card then
                    for _,p in sgs.list(d.to)do
                        if self:isEnemy(p) and source_query(self.player, "canPindian", p) then
                            use.card = card
                            return
                        end
                    end
                end
            end
        end
    end
end

sgs.ai_use_value.xin2chuhaiCard = 3.4
sgs.ai_use_priority.xin2chuhaiCard = 6.2

sgs.ai_skill_playerchosen.xin2chuhai = function(self,players,x,n)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
        if source_query(self.player, "canPindian", target)
        then return target end
    end
end

ai_fill_skill.keolyilie = function(self, options, request)
    local inclusive = options and options.inclusive

    for _,p in sgs.list(pattern_names(self))do
        local dc = preview(self,p)
        if dc and dc:getTypeId()==1 and self:getCardsNum(dc:getClassName())<1
        and source_query(self.player, "getMark", "keolyilie_guhuo_remove_"..p)<1 then
            local cards = self.player:getCards("h")
            if cards:length()<2 then break end
            cards = sgs.QList2Table(cards) -- 将列表转换为表
            self:sortByKeepValue(cards)
            mutate(self,dc,"skill","keolyilie")
            for _,h in sgs.list(cards)do
                for _,c in sgs.list(cards)do
                    if h:getKnownId()~=c:getKnownId() and h:getColor()==c:getColor() then
                        mutate(self,dc,"add",h)
                        mutate(self,dc,"add",c)
                        if source_query(dc, "isAvailable", self.player) then
                            local d = use_card(self,dc)
                            if d.card then
                                return dc
                            end
                        end
                        mutate(self,dc,"clear")
                        break
                    end
                end
            end
        end
    end
end

sgs.ai_guhuo_card.keolyilie = function(self,toname,class_name)
    if self:getCardsNum(class_name)<1 then
        local cards = self.player:getCards("h")
        if cards:length()<2 then return end
        cards = sgs.QList2Table(cards) -- 将列表转换为表
        self:sortByKeepValue(cards)
        local dc = preview(self,toname)
        mutate(self,dc,"skill","keolyilie")
        for _,h in sgs.list(cards)do
            for _,c in sgs.list(cards)do
                if h:getKnownId()~=c:getKnownId() and h:getColor()==c:getColor() then
                    mutate(self,dc,"add",h)
                    mutate(self,dc,"add",c)
                    if not source_query(self.player, "isLocked", dc) then
                        return dc:toString()
                    end
                    mutate(self,dc,"clear")
                    break
                end
            end
        end
    end
end

ai_fill_skill.ny_ol_yanru = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#ny_ol_yanruCard:.:")
end

ai_card_use["#ny_ol_yanruCard"] = function(self, card, use, request)

    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    if #cards<6 then
        if source_query(self.player, "getMark", "ny_ol_yanru_even-PlayClear")<1 then
            self:sortByKeepValue(cards)
            for i,c in sgs.list(cards)do
                if source_query(self.player, "isJilei", c)
                or card:subcardsLength()>=#cards/2
                then continue end
                mutate(self,card,"add",c)
            end
            if card:subcardsLength()>=#cards/2 then use.card = card end
        end
        if #cards<4 and source_query(self.player, "getMark", "ny_ol_yanru_odd-PlayClear")<1 then
            mutate(self,card,"clear")
            use.card = card
        end
    end
end

sgs.ai_use_value.ny_ol_yanruCard = 3.4
sgs.ai_use_priority.ny_ol_yanruCard = 3.2

sgs.ai_skill_discard.ny_ol_yanru = function(self,x,n)
    local to_cards = {}
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _,c in sgs.list(cards)do
        if source_query(self.player, "isJilei", c) or #to_cards>=n
        or use_card(self,c).card then continue end
        table.insert(to_cards,c:getKnownEffectiveId())
    end
    for _,c in sgs.list(cards)do
        if source_query(self.player, "isJilei", c) or #to_cards>=n
        or table.contains(to_cards,c:getKnownEffectiveId()) then continue end
        table.insert(to_cards,c:getKnownEffectiveId())
    end
    return to_cards
end

ai_skill_invoke.ny_ol_hezhong = function(self, options, request)

    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

ai_skill_choice.ny_ol_hezhong = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local n = data:toInt()
    if n>6 then
        return ai_choice_result((items[2]), options)
    end
    return ai_choice_result((items[1]), options)
end

ai_skill_invoke.huamu = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    for _,p in sgs.list(self.friends)do
        if p:hasSkill("liangyuan", true)
        then return (true) or false end
    end
    return false

end

ai_fill_skill.liangyuan = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#liangyuanCard:.:")
end

ai_card_use["#liangyuanCard"] = function(self, card, use, request)
    for _,pc in ipairs({"analeptic","peach"}) do
        local dc = canLyUse(self.player,pc)
        if dc and source_query(dc, "isAvailable", self.player) and self:getCardsNum(dc:getClassName())<1 then
            local d = use_card(self,dc)
            if d.card then
                use.card = card
                use.to = d.to
                self:setPriorityValue("liangyuanCard",self:getPriorityValue(dc:getClassName()),"newgenerals")
                set_choice(self,"liangyuan",pc)
                break
            end
        end
    end
end

sgs.ai_use_value.liangyuanCard = 3.4
sgs.ai_use_priority.liangyuanCard = 3.2

sgs.ai_guhuo_card.liangyuan = function(self,toname,class_name)
    if source_query(self.player, "getMark", toname.."liangyuan_lun")<1 and self:getCardsNum(class_name)<1 then
        set_choice(self,"liangyuan",toname)
        return "#liangyuanCard:.:"..toname
    end
end

sgs.ai_skill_playerchosen.jisi = function(self,players,x,n)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp",true)
    local sks = scope(self,"jisi_invoke"):split("+")
    for _,target in sgs.list(destlist)do
        if self:isFriend(target) and not self:isWeak(target) then
            if self.player:hasSkill("huamu", true) and table.contains(sks,"liangyuan") then
                if self.player:hasSkill("liangyuan", true) and table.contains(sks,"liangyuan") then
                    set_choice(self,"jisi","liangyuan")
                    return target
                end
                if self.player:hasSkill("qianmeng", true) and table.contains(sks,"qianmeng") then
                    set_choice(self,"jisi","qianmeng")
                    return target
                end
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target) and self:isWeak(target) then
            local dc = preview(self)
            local d = use_card(self,dc)
            if table.contains(sks,"huamu") then
                set_choice(self,"jisi","huamu")
            end
            if d.card and d.to:contains(target) then
                return target
            end
        end
    end
end


ai_skill_invoke.keolyangkuang = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local cur = self.room:getCurrent()
    return (self:isFriend(cur) or #self.friends<2
    or #self.enemies>0 and not self:isEnemy(cur)) or false
end

ai_skill_invoke.keolcihuang = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local tr = scope(self,"keolcihuang")
    local from = data:toPlayer()
    for _,cn in sgs.list(tr:split("+"))do
        local dc = preview(self,cn)
        mutate(self,dc,"skill","keolcihuang")
        local d = use_card(self,dc)
        if d.card and d.to:contains(from) then
            set_choice(self,"keolcihuang",cn)
            return (true) or false
        end
    end
    for _,cn in sgs.list(tr:split("+"))do
        local dc = preview(self,cn)
        mutate(self,dc,"skill","keolcihuang")
        local d = use_card(self,dc)
        if d.card and d.to:contains(self.player) and self:isFriend(from) then
            set_choice(self,"keolcihuang",cn)
            return (true) or false
        end
    end
    return false

end

sgs.ai_skill_discard.keolhetao = function(self,x,n)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local use = scoped_struct(self,"keolhetao","use")
    for _,p in sgs.list(use.to)do
        if source_query(use.card, "isDamageCard") and self:isEnemy(p) then
            for _,c in sgs.list(cards)do
                if source_query(self.player, "isJilei", c)
                or use.card:getColor()~=c:getColor()
                then continue end
                set_state(self,"keolhetaoTo",p)
                return {c:getKnownEffectiveId()}
            end
        end
    end
    for _,p in sgs.list(use.to)do
        if use.to:contains(use.from) and self:isFriend(p)
        and not self:isFriend(use.from) then
            for _,c in sgs.list(cards)do
                if source_query(self.player, "isJilei", c)
                or use.card:getColor()~=c:getColor()
                then continue end
                set_state(self,"keolhetaoTo",p)
                return {c:getKnownEffectiveId()}
            end
        end
    end
    return {}
end

sgs.ai_skill_playerchosen.keolhetao = function(self,players,x,n)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
        if target==get_state(self,"keolhetaoTo")
        then return target end
    end
end

ai_skill_invoke.keolshenli = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = data:toCardUse()
    local n = 0
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
        if source_query(self.player, "canSlash", p, use.card, false) then
            if self:isFriend(p) then
                n = n-1
            else
                n = n+1
            end
        end
    end
    return (n>0) or false
end

ai_skill_invoke.keolshishou = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local from = data:toPlayer()
    return (self:isFriend(from)) or false
end

function sgs.ai_weapon_value._keolsizhaojian(self,enemy)
    if enemy then return 6-enemy:getHp() end
    return 3
end

sgs.ai_keep_value.Keolsizhaojian = 4.08



ai_skill_invoke.moujianxiong = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

ai_skill_invoke.mouqingzheng = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

ai_skill_use["@@mouqingzheng"] = function(self, prompt, request)
    local valid = {}
    local ids = {}
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local n = source_query(self.player, "getMark", "mouqingzhengSuits")
    for _,c in sgs.list(cards)do
        if table.contains(ids,c:getSuit()) then continue end
        table.insert(ids,c:getSuit())
    end
    local function func(a,b)
        local an,bn = 0,0
        for _,c in sgs.list(cards)do
            if a==c:getSuit() then an = an+1 end
            if b==c:getSuit() then bn = bn+1 end
        end
        return an<bn
    end
    table.sort(ids,func)
    local ids2 = {}
    for _,s in sgs.list(ids)do
        table.insert(ids2,s)
        if #ids2>=n then break end
    end
    for _,c in sgs.list(cards)do
        if table.contains(ids2,c:getSuit())
        then table.insert(valid,c:getKnownId()) end
    end
    if #valid<1 then return end
    self:sort(self.enemies,"handcard",true)
    for _,p in sgs.list(self.enemies)do
        if p:getHandcardNum()>=#valid or self:isWeak(p) and p:getHandcardNum()>#valid/2 then
            set_state(self,"mouqingzhengTo",p)
            return "#mouqingzhengCard:"..table.concat(valid,"+")..":->"..p:objectName()
        end
    end
end

sgs.ai_skill_askforag.mouqingzheng = function(self,card_ids)
    local cards = {}
    for _,id in sgs.list(card_ids)do
        table.insert(cards,known_card(self,id))
    end
    local ids = {}
    for _,c in sgs.list(cards)do
        if table.contains(ids,c:getSuit()) then continue end
        table.insert(ids,c:getSuit())
    end
    local function func(a,b)
        local an,bn = 0,0
        for _,c in sgs.list(cards)do
            if a==c:getSuit() then an = an+1 end
            if b==c:getSuit() then bn = bn+1 end
        end
        return an>bn
    end
    table.sort(ids,func)
    self:sortByKeepValue(cards,true)
    for _,c in sgs.list(cards)do
        if ids[1]==c:getSuit()
        then return c:getKnownId() end
    end
end

sgs.ai_skill_playerchosen.mouhujia = function(self,players,x,n)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
        if self:isEnemy(target) and self:isWeak(target)
        then return target end
    end
    local damage = scoped_struct(self,"mouhujiaDamage","damage")
    for _,target in sgs.list(sgs.reverse(destlist))do
        if self:isFriend(target) and not self:isWeak(target)
        and self:canDamageHp(damage.from,damage.card,target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not self:isFriend(target) and self:isWeak()
        then return target end
    end
end

ai_fill_skill.moufanjian = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#moufanjianCard:.:")
end

ai_card_use["#moufanjianCard"] = function(self, card, use, request)
    for _,p in ipairs(self.friends_noself) do
        if not p:faceUp() then
            local cards = self.player:getCards("h")
            cards = sgs.QList2Table(cards)
            self:sortByKeepValue(cards)
            for _,c in ipairs(cards) do
                if self:wasPreviouslyPlannedCard(c)
                or source_query(self.player, "getMark", c:getSuitString().."moufanjianUsed-PlayClear")>0
                then continue end
                use.card = parse_action(self,"#moufanjianCard:"..c:getKnownId()..":")
                use.to:append(p)
                self:setPriorityValue("moufanjianCard",8.8,"newgenerals")
                return
            end
        end
    end
    self:sort(self.enemies,"hp")
    for _,p in ipairs(self.enemies) do
        if p:faceUp() then
            local cards = self.player:getCards("h")
            cards = sgs.QList2Table(cards)
            self:sortByKeepValue(cards)
            for _,c in ipairs(cards) do
                if self:wasPreviouslyPlannedCard(c)
                or source_query(self.player, "getMark", c:getSuitString().."moufanjianUsed-PlayClear")>0
                then continue end
                use.card = parse_action(self,"#moufanjianCard:"..c:getKnownId()..":")
                use.to:append(p)
                self:setPriorityValue("moufanjianCard",3.8,"newgenerals")
                return
            end
        end
    end
end

sgs.ai_use_value.moufanjianCard = 3.4
sgs.ai_use_priority.moufanjianCard = 3.2

ai_skill_choice.moufanjian = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    if not self.player:faceUp() then
        return ai_choice_result((items[3]), options)
    end
    return ai_choice_result((items[math.random(1,2)]), options)
end

ai_fill_skill.mourende = function(self, options, request)
    local inclusive = options and options.inclusive

    set_state(self,"mourendeUse",nil)
    for _,p in sgs.list(pattern_names(self))do
        local dc = preview(self,p)
        if dc and dc:getTypeId()==1 and source_query(self.player, "getMark", "mRenWang-Clear")<1
        and source_query(self.player, "getMark", "&mRenWang")>1 and self:getCardsNum(dc:getClassName())<2 then
            mutate(self,dc,"skill","_mourende")
            if source_query(dc, "isAvailable", self.player) then
                local d = use_card(self,dc)
                if d.card then
                    set_state(self,"mourendeUse",d)
                    self:setPriorityValue("mourendeCard",self:getPriorityValue(dc:getClassName()),"newgenerals")
                    return parse_action(self,"#mourendeCard:.:")
                end
            end
        end
    end
    self:setPriorityValue("mourendeCard",self:getPriorityValue("RendeCard"),"newgenerals")
    return parse_action(self,"#mourendeCard:.:")
end

ai_card_use["#mourendeCard"] = function(self, card, use, request)
    if get_state(self,"mourendeUse") then
        use.card = card
        return
    end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards,true)
    local notFound = false
    for i = 1,#cards do
        local nc,friend = self:getCardNeedPlayer(cards)
        if nc and friend then cards = self:resetCards(cards,nc)
        else notFound = true break end
        if friend:objectName()==self.player:objectName()
        or source_query(friend, "getMark", "mourendeCardGet-PlayClear")>0
        then continue end
        if source_query(nc, "isAvailable", self.player) then
            if source_query(nc, "isDamageCard") or nc:isKindOf("SingleTargetTrick") then
                local dummy_use = use_card(self,nc)
                if dummy_use.card and dummy_use.to:length()>0 then
                    if dummy_use.to:length()>1 or self:isWeak(dummy_use.to:first())
                    or sgs.aiResponse[nc:getClassName()] and getCardsNum(sgs.aiResponse[nc:getClassName()],dummy_use.to:first(),self.player)<1
                    then continue end
                end
            elseif nc:isKindOf("DelayedTrick") then
                if self:getEnemyNumBySeat(self.player,friend)>0
                and use_card(self,nc).card then continue end
            end
        end
        local ids = {}
        if friend:hasSkill("enyuan")
        and #cards>=1 and not AIValue.sameLegacyIdentity(cards[1],nc)
        then table.insert(ids,cards[1]:getEffectiveId()) end
        table.insert(ids,nc:getKnownEffectiveId())
        use.card = parse_action(self,"#mourendeCard:"..table.concat(ids,"+")..":")
        use.to:append(friend)
        return
    end
    if notFound and self.player:isWounded()
    and source_query(self.player, "getMark", "&mRenWang")<4
    and source_query(self.player, "getCardCount")>4 then
        cards = sgs.QList2Table(self.player:getCards("he"))
        self:sortByUseValue(cards,true)
        for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
            if not self:isFriend(p) and hasManjuanEffect(p)
            and source_query(p, "getMark", "mourendeCardGet-PlayClear")<1 then
                local ids = {}
                for _,c in ipairs(cards)do
                    if not isCard("Peach,ExNihilo",c,self.player)
                    then table.insert(ids,c:getKnownEffectiveId()) end
                    if #ids>1 then break end
                end
                if #ids>0 then
                    use.card = parse_action(self,"#mourendeCard:"..table.concat(ids,"+")..":")
                    use.to:append(p)
                    return
                end
            end
        end
        for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
            if not self:isEnemy(p) and source_query(p, "getMark", "mourendeCardGet-PlayClear")<1 then
                local ids = {}
                for _,c in ipairs(cards)do
                    if not isCard("Peach,ExNihilo",c,self.player)
                    then table.insert(ids,c:getKnownEffectiveId()) end
                    if #ids>1 then break end
                end
                if #ids>0 then
                    use.card = parse_action(self,"#mourendeCard:"..table.concat(ids,"+")..":")
                    use.to:append(p)
                    return
                end
            end
        end
        for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
            if source_query(p, "getMark", "&mourdTOzw")<1 then
                local ids = {}
                for _,c in ipairs(cards)do
                    if not isCard("Peach,ExNihilo",c,self.player)
                    then table.insert(ids,c:getKnownEffectiveId()) break end
                end
                if #ids>0 then
                    use.card = card
                    use.to:append(p)
                    return
                end
            end
        end
    end
end

sgs.ai_use_value.mourendeCard = sgs.ai_use_value.RendeCard
sgs.ai_use_priority.mourendeCard = sgs.ai_use_priority.RendeCard

sgs.ai_skill_askforag.mourende = function(self,card_ids)
    local cards = {}
    for _,id in sgs.list(card_ids)do
        table.insert(cards,known_card(self,id))
    end
    if get_state(self,"mourendeUse") then
        for _,c in sgs.list(cards)do
            if get_state(self,"mourendeUse").q(card,"objectName")==c:objectName()
            then return c:getKnownId() end
        end
    end
    self:sortByKeepValue(cards,true)
    for _,c in sgs.list(cards)do
        local dc = preview(self,c:objectName())
        mutate(self,dc,"skill","_mourende")
        if source_query(dc, "isAvailable", self.player) then
            local d = use_card(self,dc)
            if d.card then
                set_state(self,"mourendeUse",d)
                return c:getKnownId()
            end
        end
    end
end

ai_skill_use["@@mourende"] = function(self, prompt, request)
    local dummy = get_state(self,"mourendeUse")
    if dummy.card then
        local tos = {}
        for _,p in sgs.list(dummy.to)do
            table.insert(tos,p:objectName())
        end
        return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_guhuo_card.mourende = function(self,toname,class_name)
    if self:getCardsNum(class_name)<1 or source_query(self.player, "getMark", "&mRenWang")>4 then
        local dc = preview(self,toname)
        -- dummyCard can return nil; the fixed source then fails at setSkillName.
        if dc==nil then dc:setSkillName("_mourende") end
        mutate(self,dc,"skill","_mourende")
        local st=preview_specs[dc]
        -- A represented source string. The existing response collector parses
        -- this only when reached, and authorizes payment only when selected.
        return {name=st.name,skill=st.skill,suit=st.suit,number=st.number,subcards=copy(st.costs)}
    end
end

ai_fill_skill.mouzhangwu = function(self, options, request)
    local inclusive = options and options.inclusive

    return source_query(self.player, "getMark", "mRenWang-Clear")>0
    and parse_action(self,"#mouzhangwuCard:.:")
end

ai_card_use["#mouzhangwuCard"] = function(self, card, use, request)
    local tos = self.room:getOtherPlayers(self.player)
    local n = 0
    for _,p in sgs.qlist(tos)do
        if source_query(p, "getMark", "&mourdTOzw")>0 then
            n = n+1
        end
    end
    local x = scope(self,"TurnLengthCount")
    if x>3 and n>tos:length()/2 or x>2 and self:isWeak() and n>=tos:length()/2 then
        use.card = card
    end
end

sgs.ai_use_value.mouzhangwuCard = 4.5
sgs.ai_use_priority.mouzhangwuCard = 7.7

ai_skill_use["@@moujijiang"] = function(self, prompt, request)
    local tos = {}
    self:sort(self.enemies,"hp")
    for _,ep in sgs.list(self.enemies)do
        for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
            if p:getKnownKingdom()=="shu" and p:getHp()>=self.player:getHp()
            and self:isFriend(p) and source_query(p, "inMyAttackRange", ep) then
                table.insert(tos,ep:objectName())
                table.insert(tos,p:objectName())
                return "#moujijiangCard:.:->"..table.concat(tos,"+")
            end
        end
    end
    for _,ep in sgs.list(self.enemies)do
        for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
            if p:getKnownKingdom()=="shu" and p:getHp()>=self.player:getHp()
            and source_query(p, "inMyAttackRange", ep) then
                table.insert(tos,ep:objectName())
                table.insert(tos,p:objectName())
                return "#moujijiangCard:.:->"..table.concat(tos,"+")
            end
        end
    end
    for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
        if self:isFriend(ep) then continue end
        for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
            if p:getKnownKingdom()=="shu" and p:getHp()>=self.player:getHp()
            and source_query(p, "inMyAttackRange", ep) then
                table.insert(tos,ep:objectName())
                table.insert(tos,p:objectName())
                return "#moujijiangCard:.:->"..table.concat(tos,"+")
            end
        end
    end
end

ai_skill_choice.moujijiang = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local use = data:toCardUse()
    if self:isFriend(use.to:first()) and self:isWeak(use.to:first()) then
        return ai_choice_result((items[2]), options)
    end
    return ai_choice_result((items[1]), options)
end

sgs.ai_skill_playerchosen["mouluoshen"] = function(self, targets)
    local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))

    local max_count, max_start = 0, nil
    local cur_count, cur_start = 0, nil

    for i, p in ipairs(players) do
        if source_query(self, "doDisCard", p, "h") then
            if not cur_start then cur_start = i end
            cur_count = cur_count + 1
            if cur_count > max_count then
                max_count = cur_count
                max_start = cur_start
            end
        else
            cur_count = 0
            cur_start = nil
        end
    end

    local valid_targets = {}
    for _, target in ipairs(players) do
        if source_query(self, "doDisCard", target, "h") then
            table.insert(valid_targets, target)
        end
    end

    local first_target = max_start and players[max_start] or nil

    return first_target
end

sgs.ai_view_as.mouqingguo = function(card,player,card_place)
    local suit = card:getSuitString()
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    if card:isBlack() and card_place==sgs.Player_PlaceHand then
        return ("jink:mouqingguo[%s:%s]=%d"):format(suit,number,card_id)
    end
end

function sgs.ai_cardneed.mouqingguo(to,card)
    return to:getHandcardNum()<2 and card:isBlack()
end


ai_fill_skill.mouhuoji = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#mouhuojiCard:.:")
end

ai_card_use["#mouhuojiCard"] = function(self, card, use, request)
    self:sort(self.enemies,"hp")
    local max_value = 0
    local target = nil
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        local value = 0
        if source_query(self, "damageIsEffective", p, sgs.DamageStruct_Fire, self.player) then
            if self:isEnemy(p) and source_query(self, "canDamage", p, self.player, nil) then
                value = value + 1
                if self:isWeak(p) then
                    value = value + 1
                end
            elseif self:isFriend(p) then
                value = value - 1
                if self:isWeak(p) then
                    value = value - 1
                end
            end
            for _, q in sgs.qlist(self.room:getOtherPlayers(p)) do
                if q:getKnownKingdom() == p:getKnownKingdom() then
                    if source_query(self, "damageIsEffective", q, sgs.DamageStruct_Fire, self.player) then
                        if self:isEnemy(q) and source_query(self, "canDamage", q, self.player, nil) then
                            value = value + 1
                            if self:isWeak(q) then
                                value = value + 1
                            end
                        elseif self:isFriend(q) then
                            value = value - 1
                            if self:isWeak(q) then
                                value = value - 1
                            end
                        end
                    end
                end
            end
            if value > max_value then
                max_value = value
                target = p
            end

        end
    end
    if target then
        use.card = card
        use.to:append(target)
    end
end

sgs.ai_skill_askforag["moukanpo"] = function(self, card_ids)
    local cards = {}
    for _, card_id in ipairs(card_ids) do
        table.insert(cards, known_card(self,card_id))
    end
    self:sortByUseValue(cards)

    for _, card in ipairs(cards) do
        if card:isKindOf("Slash") and math.random() < 0.4 then
            return card:getKnownEffectiveId()
        end
    end
    for _, card in ipairs(cards) do
        if card:isKindOf("BasicCard") and math.random() < 0.3 then
            return card:getKnownEffectiveId()
        end
    end
    for _, card in ipairs(cards) do
        if card:isKindOf("TrickCard") and math.random() < 0.4 then
            return card:getKnownEffectiveId()
        end
    end
    if #cards > 0 then
        return cards[1]:getEffectiveId()
    end
end

ai_skill_invoke.moukanpo = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = data:toCardUse()
    if self:isEnemy(use.from) then return (true) or false end
    return (false) or false
end

sgs.ai_choicemade_filter.skillInvoke.moukanpo = function(self,player,promptlist)
    local use = scoped_struct(self,"moukanpo","use")
    if not use then return end
    local dest = use.from
    if dest and promptlist[#promptlist]=="yes" then
        self:updateIntention(player,dest,80)
    end
end

sgs.ai_ajustdamage_to.moukongcheng = function(self, from, to, card, nature)
    if to:hasSkill("mouguanxing", true) then
        if to:getPile("&mouStarsXing"):isEmpty() then
            return 1
        end
    end
end
sgs.ai_card_priority.moukongcheng = function(self,card,v)
    return self.player:getPile("&mouStarsXing"):contains(card:getKnownEffectiveId()) and -1
end


ai_fill_skill.mouguose = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#mouguoseCard:.:")
end

ai_card_use["#mouguoseCard"] = function(self, card, use, request)
    self:sort(self.friends)

    self:setPriorityValue("mouguoseCard",5.5,"newgenerals")
    for _,friend in ipairs(self.friends)do
        if source_query(friend, "containsTrick", "indulgence")
        and source_query(self, "willSkipPlayPhase", friend)
        and not friend:hasSkills("shensu|qingyi|qiaobian")
        and (self:isWeak(friend) or self:getOverflow(friend)>1)
        then
            for _,c in sgs.list(friend:getJudgingArea())do
                if c:isKindOf("Indulgence")
                and source_query(self.player, "canDiscard", friend, c:getKnownEffectiveId())
                then
                    use.card = card
                    use.to:append(friend)
                    return
                end
            end
        end
    end
    local cards = self:addHandPile("he")
    self:sortByUseValue(cards,true)
    for _,acard in ipairs(cards)do
        if acard:getSuit()==sgs.Card_Diamond
        and ((source_query(self, "getUseValue", acard)<sgs.ai_use_value.Indulgence))
        then
            local indulgence = preview(self,"Indulgence")
            mutate(self,indulgence,"skill","mouguose")
            mutate(self,indulgence,"add",acard)
            if not source_query(self.player, "isLocked", indulgence) then
                local dummy_use = use_card(self,indulgence, dummy())
                if dummy_use.card then
                    use.card = parse_action(self,"indulgence:mouguose[no_suit:0]="..acard:getKnownEffectiveId())
                    self:setPriorityValue("mouguoseCard",self:getPriorityValue("Indulgence"),"newgenerals")
                    use.to = dummy_use.to
                    return
                end
            end
        end
    end
    for _,friend in ipairs(self.friends)do
        if source_query(friend, "containsTrick", "indulgence") then
            for _,c in sgs.list(friend:getJudgingArea())do
                if c:isKindOf("Indulgence") and source_query(self.player, "canDiscard", friend, c:getKnownEffectiveId()) then
                    use.card = card
                    use.to:append(friend)
                    return
                end
            end
        end

    end
end

sgs.ai_use_priority["mouguoseCard"] = 5.5
sgs.ai_use_value["mouguoseCard"] = 5
sgs.ai_card_intention["mouguoseCard"] = -60

function sgs.ai_cardneed.mouguose(to,card)
    return card:getSuit()==sgs.Card_Diamond
end

sgs.mouguose_suit_value = {
    diamond = 3.9
}


ai_skill_use["@@mouliuli"] = function(self, prompt, request)
    local method = request and request.handling_method
    local others = self.room:getOtherPlayers(self.player)
    local slash = preview(self,"slash")
    others = sgs.QList2Table(others)
    local source
    for _,player in ipairs(others)do
        if player:getStrategyFlag("mouliuliUseFrom") then
            source = player
            break
        end
    end
    self:sort(self.enemies,"defense")

    local doLiuli = function(who)
        if not self:isFriend(who) and who:hasSkills("leiji|nosleiji|olleiji")
            and (source_query(self, "hasSuit", "spade", true, who) or who:getHandcardNum()>=3)
            and (getKnownCard(who,self.player,"Jink",true)>=1 or source_query(self, "hasEightDiagramEffect", who)) then
            return "."
        end

        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _,card in ipairs(cards)do
            if not source_query(self.player, "isCardLimited", card, method) and source_query(self.player, "canSlash", who) then
                if self:isFriend(who) and not (isCard("Peach",card,self.player) or isCard("Analeptic",card,self.player)) then
                    return "#mouliuliCard:"..card:getKnownEffectiveId()..":->"..who:objectName()
                else
                    return "#mouliuliCard:"..card:getKnownEffectiveId()..":->"..who:objectName()
                end
            end
        end

        local cards = self.player:getCards("e")
        cards=sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _,card in ipairs(cards)do
            local range_fix = 0
            if card:isKindOf("Weapon") then range_fix = range_fix+sgs.weapon_range[card:getClassName()]-source_query(self.player, "getAttackRange", false) end
            if card:isKindOf("OffensiveHorse") then range_fix = range_fix+1 end
            if not source_query(self.player, "isCardLimited", card, method) and source_query(self.player, "canSlash", who, nil, true, range_fix) then
                return "#mouliuliCard:"..card:getKnownEffectiveId()..":->"..who:objectName()
            end
        end
        return "."
    end

    for _,enemy in ipairs(self.enemies)do
        if not (source and source:objectName()==enemy:objectName()) then
            local ret = doLiuli(enemy)
            if ret~="." then return ret end
        end
    end

    for _,player in ipairs(others)do
        if source_query(self, "objectiveLevel", player)==0 and not (source and source:objectName()==player:objectName()) then
            local ret = doLiuli(player)
            if ret~="." then return ret end
        end
    end


    self:sort(self.friends_noself,"defense")
    self.friends_noself = sgs.reverse(self.friends_noself)


    for _,friend in ipairs(self.friends_noself)do
        if not source_query(self, "slashIsEffective", slash, friend) or self:findLeijiTarget(friend,50,source) then
            if not (source and source:objectName()==friend:objectName()) then
                local ret = doLiuli(friend)
                if ret~="." then return ret end
            end
        end
    end

    for _,friend in ipairs(self.friends_noself)do
        if source~=friend and source_query(self, "needToLoseHp", friend, source, preview(self)) then
                local ret = doLiuli(friend)
                if ret~="." then return ret end
            end
        end

    if (self:isWeak() or source_query(self, "ajustDamage", source, nil, 1, slash)>1) and source_query(source, "hasWeapon", "Axe") and source:getHandcardNum()+#source:getEquips()>2
      and not self:getCardId("Peach") and not self:getCardId("Analeptic") then
        for _,friend in ipairs(self.friends_noself)do
            if not self:isWeak(friend) then
                if not (source and source:objectName()==friend:objectName()) then
                    local ret = doLiuli(friend)
                    if ret~="." then return ret end
                end
            end
        end
    end

    if (self:isWeak() or source_query(self, "ajustDamage", source, nil, 1, slash)>1) and not self:getCardId("Jink") then
        for _,friend in ipairs(self.friends_noself)do
            if not self:isWeak(friend) or (source_query(self, "hasEightDiagramEffect", friend) and getCardsNum("Jink",friend)>=1) then
                if not (source and source:objectName()==friend:objectName()) then
                    local ret = doLiuli(friend)
                    if ret~="." then return ret end
                end
            end
        end
    end
    return "."
end
sgs.ai_skill_playerchosen.mouliuli = function(self, targets)

    if role_count(self,"rebel")==0 then
        local lord = self.room:getLord()
        if lord and self:isFriend(lord) and lord:objectName()~=self.player:objectName() then
            return lord
        end
    end

    local AssistTarget = self:AssistTarget()
    if AssistTarget and not source_query(self, "willSkipPlayPhase", AssistTarget) then
        return AssistTarget
    end

    self:sort(self.friends_noself,"handcard")
    for _,target in ipairs(self.friends_noself)do
        return target
    end
    return nil
end
sgs.ai_playerchosen_intention.mouliuli = -40



ai_fill_skill.mouqixi = function(self, options, request)
    local inclusive = options and options.inclusive

    return #self.enemies>0
    and parse_action(self,"#mouqixiCard:.:")
end

ai_card_use["#mouqixiCard"] = function(self, card, use, request)
    for _,enemy in ipairs(self.enemies)do
        if source_query(self, "doDisCard", enemy, "he") then
            use.card = parse_action(self,"#mouqixiCard:.:")
            use.to:append(enemy)
            return
        end
    end
end

sgs.ai_use_value.mouqixiCard = 4.5
sgs.ai_use_priority.mouqixiCard = sgs.ai_use_priority.Dismantlement
sgs.ai_card_intention.mouqixiCard = 80
ai_skill_invoke.mouqixi = true

ai_fill_skill.moufenwei = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#moufenweiCard:.:")
end

ai_card_use["#moufenweiCard"] = function(self, card, use, request)
    local num = 3
    num = math.min(num,#self.friends)
    if num<=0 then return end

    self:sort(self.friends)
    local friends = {}
    for i = 1,num do
        table.insert(friends,self.friends[i]:objectName())
    end
    local use_cards = {}
    local type = {}
    local cards = self.player:getCards("he")

    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _, acard in ipairs(cards) do
        table.insert(use_cards, acard:getKnownEffectiveId())
        if #use_cards >= #friends then break end
    end
    if #friends>0 and #use_cards == #friends then
        use.card = parse_action(self,"#moufenweiCard:"..table.concat(use_cards,"+")..":")
        for _, friend in ipairs(friends) do
            if use.to then
                use.to:append(self.room:findPlayerByObjectName(friend))
            end
        end
    end
end

sgs.ai_card_intention.moufenweiCard = -80

ai_skill_choice.moufenwei = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local use = data:toCardUse()
    local items = choices:split("+")
    if table.contains(items, "2") and source_query(use.card, "isDamageCard") then
        return ai_choice_result(("2"), options)
    end
    return ai_choice_result((items[math.random(1, #items)]), options)
end



ai_fill_skill.moulianhuan = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self:addHandPile()
    self:sortByUseValue(cards,true)
    local card
    local slash = self:getCard("FireSlash") or self:getCard("ThunderSlash") or self:getCard("Slash")
    if slash then
        local dummy_use = dummy()
        self:useBasicCard(slash,dummy_use)
        if not dummy_use.card then slash = nil end
    end

    for _,acard in sgs.list(cards)do
        if acard:getSuit()==sgs.Card_Club then
            local shouldUse = true
            if source_query(self, "getUseValue", acard)>sgs.ai_use_value.IronChain and acard:getTypeId()==sgs.Card_TypeTrick then
                local dummy_use = dummy()
                self:useTrickCard(acard,dummy_use)
                if dummy_use.card then shouldUse = false end
            end
            if acard:getTypeId()==sgs.Card_TypeEquip then
                local dummy_use = dummy()
                self:useEquipCard(acard,dummy_use)
                if dummy_use.card then shouldUse = false end
            end
            if shouldUse and (not slash or slash:getKnownEffectiveId()~=acard:getKnownEffectiveId()) then
                card = acard
                break
            end
        end
    end

    if not card then return nil end
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    local card_str = ("iron_chain:moulianhuan[club:%s]=%d"):format(number,card_id)
    local skillcard = parse_action(self,card_str)
    assert(skillcard)
    return skillcard
end

sgs.ai_cardneed.moulianhuan = function(to,card)
    return card:getSuit()==sgs.Card_Club and to:getHandcardNum()<=2
end

ai_audited_aliases.register{id="ai_skill_invoke.mouniepan",defer_canonical=true,self_index=1,registry="ai_skill_invoke",path={"mouniepan"},canonical_registry="ai_skill_invoke",canonical_path={"niepan"}}



ai_fill_skill.mouxuanhuo = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards,nil,true)
    for i,c in sgs.list(cards)do
        for it,ct in sgs.list(source_query(self, "getPriorTurnUseCards"))do
            if c:getKnownEffectiveId()~=ct:getKnownEffectiveId()
            and c:getSuit()==ct:getSuit()
            and ct:isKindOf("Slash")
            then
                return parse_action(self,"#mouxuanhuoCard:"..c:getKnownEffectiveId()..":")
            end
        end
    end
    for i,c in sgs.list(cards)do
        if c:isKindOf("EquipCard")
        and #self.enemies>0
        and i<#cards/2
        then
            return parse_action(self,"#mouxuanhuoCard:"..c:getKnownEffectiveId()..":")
        end
    end
end

ai_card_use["#mouxuanhuoCard"] = function(self, card, use, request)
    self:sort(self.enemies)
    for _, enemy in ipairs(self.enemies) do
        if source_query(enemy, "getMark", "&mXuan+#"..self.player:objectName()) == 0 then
            use.card = card
            if use.to then
                use.to:append(enemy)
            end
            return
        end
    end
end

sgs.ai_card_intention.mouxuanhuoCard = 80
sgs.ai_use_priority.mouxuanhuoCard = sgs.ai_use_priority.Dismantlement

ai_fill_skill.moulijian = function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:isNude() or self.room:getAlivePlayers():length()<3 then
        return
    end
    local n = self.player:getHandcardNum() + self.player:getEquips():length() - 1
    if n > 1 then return parse_action(self,"#moulijianCard:.:") end
end


ai_card_use["#moulijianCard"] = function(self, card, use, request)
    local lord = self.room:getLord()
    local duel = preview(self,"duel")
    local findFriend_maxSlash = function(self,first)
        local maxSlash = 0
        local friend_maxSlash
        local nos_fazheng,fazheng
        for _,friend in ipairs(self.friends_noself)do
            if source_query(self, "hasTrickEffective", duel, first, friend) then
                if friend:hasSkill("nosenyuan") and friend:getHp()>1 then nos_fazheng = friend end
                if friend:hasSkill("enyuan") and friend:getHp()>1 then fazheng = friend end
                if (getCardsNum("Slash",friend)>maxSlash) then
                    maxSlash = getCardsNum("Slash",friend)
                    friend_maxSlash = friend
                end
            end
        end

        if friend_maxSlash then
            local safe = false
            if self:hasSkills("neoganglie|vsganglie|fankui|enyuan|ganglie|nosenyuan",first) and not self:hasSkills("wuyan|noswuyan",first) then
                if (first:getHp()<=1 and first:getHandcardNum()==0) then safe = true end
            elseif (getCardsNum("Slash",friend_maxSlash)>=getCardsNum("Slash",first)) then safe = true end
            if safe then return friend_maxSlash end
        else self:log("unfound")
        end
        if nos_fazheng or fazheng then  return nos_fazheng or fazheng end       --备用友方，各种恶心的法正
        return nil
    end
    local n = self.player:getHandcardNum() + self.player:getEquips():length() + 1
    if n < 2 then return end
    local targets = {}
    if self.role=="rebel" or (self.role=="renegade" and role_count(self,"loyalist")+1>role_count(self,"rebel")) then

        if lord and not lord:isNude() and lord:objectName()~=self.player:objectName() then      -- 优先离间1血忠和主
            self:sort(self.enemies,"handcard")
            local e_peaches = 0
            local loyalist

            for _,enemy in ipairs(self.enemies)do
                e_peaches = e_peaches+getCardsNum("Peach",enemy)
                if enemy:getHp()==1 and source_query(self, "hasTrickEffective", duel, enemy, lord) and enemy:objectName()~=lord:objectName() and not loyalist then
                    loyalist = enemy
                    break
                end
            end

            if loyalist and e_peaches<1 then
                table.insert(targets, loyalist)
                table.insert(targets, lord)
            end
        end
    end
    if #targets < n then
        local shenguanyu = self.room:findPlayerBySkillName("wuhun")
        if shenguanyu and shenguanyu:objectName()~=self.player:objectName() then
            if self.role=="rebel" and lord and lord:objectName()~=self.player:objectName() and shenguanyu:objectName()~=lord:objectName()
                and not source_query(self, "hasJueqingEffect", lord, shenguanyu) and source_query(self, "hasTrickEffective", duel, shenguanyu, lord) then
                table.insert(targets, shenguanyu)
            elseif self:isEnemy(shenguanyu) and #self.enemies>=2 then
                for _,enemy in ipairs(self.enemies)do
                    if enemy:objectName()~=shenguanyu:objectName() and not source_query(enemy, "isLocked", duel)
                        and source_query(self, "hasTrickEffective", duel, shenguanyu, enemy) then
                        if not table.contains(targets,enemy) then
                            table.insert(targets, enemy)
                            if #targets >= n then
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    if #targets < n then
        self:sort(self.enemies,"defense")
        local males,others = {},{}
        local first,second
        local zhugeliang_kongcheng,xunyu

        for _,enemy in ipairs(self.enemies)do
            if  not enemy:hasSkills("wuyan|noswuyan") then
                if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then zhugeliang_kongcheng = enemy
                elseif enemy:hasSkill("jieming") then xunyu = enemy
                else
                    for _,anotherenemy in ipairs(self.enemies)do
                        if  anotherenemy:objectName()~=enemy:objectName() then
                            if #males==0 and source_query(self, "hasTrickEffective", duel, enemy, anotherenemy) then
                                if not (enemy:hasSkill("hunzi") and source_query(enemy, "getMark", "hunzi")<1 and enemy:getHp()==2) then
                                    table.insert(males,enemy)
                                else
                                    table.insert(others,enemy)
                                end
                            end
                            if #males==1 and source_query(self, "hasTrickEffective", duel, males[1], anotherenemy) then
                                if not anotherenemy:hasSkills("nosjizhi|jizhi|jiang") then
                                    table.insert(males,anotherenemy)
                                else
                                    table.insert(others,anotherenemy)
                                end
                            end
                        end
                    end
                end
            end
        end

        if #males>0 then
            if isLord(males[1]) and source_query(self.room, "getTurnCount")<=1 and self.role=="rebel" and source_query(self.player, "aliveCount")>=3 then
                local p_slash,max_p,max_pp = 0,nil,nil
                for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
                    if not self:isFriend(p) and p:objectName()~=males[1]:objectName() and source_query(self, "hasTrickEffective", duel, males[1], p) and not source_query(p, "isLocked", duel)
                        and p_slash<getCardsNum("Slash",p) then
                        if p:getKnownKingdom()==males[1]:getKingdom() then
                            max_p = p
                            break
                        elseif not max_pp then
                            max_pp = p
                        end
                    end
                end
                if max_p then table.insert(males,max_p) end
                if max_pp and #males==1 then table.insert(males,max_pp) end
            end
        end

        if #males>0 then
            if #others>=1 and not others[1]:isLocked(duel) then
                for _,p in ipairs(others)do
                    if not table.contains(males,p) then
                        table.insert(males,p)
                    end
                end
            elseif xunyu and not source_query(xunyu, "isLocked", duel) then
                if getCardsNum("Slash",males[1])<1 then
                    table.insert(males,xunyu)
                else
                    local drawcards = 0
                    for _,enemy in ipairs(self.enemies)do
                        local x = enemy:getMaxHp()>enemy:getHandcardNum() and math.min(5,enemy:getMaxHp()-enemy:getHandcardNum()) or 0
                        if x>drawcards then drawcards = x end
                    end
                    if drawcards<=2 then
                        table.insert(males,xunyu)
                    end
                end
            end
        end

        if #males>0 and #self.friends_noself>0 then
            self:log("Only 1")
            first = males[1]
            if zhugeliang_kongcheng and source_query(self, "hasTrickEffective", duel, first, zhugeliang_kongcheng) then
                table.insert(males,zhugeliang_kongcheng)
            else
                local friend_maxSlash = findFriend_maxSlash(self,first)
                if friend_maxSlash then table.insert(males,friend_maxSlash) end
            end
        end

        if #males>=2 then
            for _,p in ipairs(males)do
                if not table.contains(targets,p) then
                    table.insert(targets, p)
                    if #targets >= n then
                        break
                    end
                end
            end
        end
    end
    local use_cards = {}
    local cards = self.player:getCards("he")

    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _, acard in ipairs(cards) do
        table.insert(use_cards, acard:getKnownEffectiveId())
        if #use_cards >= #targets - 1 then break end
    end
    if #targets >= 2 and n >= #targets and #use_cards == #targets - 1 then
        use.card = parse_action(self,"#moulijianCard:"..table.concat(use_cards,"+")..":")
        for _,p in ipairs(targets)do
            use.to:append(p)
        end
    end
end

sgs.ai_use_value["moulijianCard"] = 8.5
sgs.ai_use_priority["moulijianCard"] = 4

sgs.ai_card_intention["moulijianCard"] = function(self,card,from,to)
    self:updateIntentions(from,to,40)
end

sgs.dynamic_value.damage_card["moulijianCard"] = true

ai_fill_skill.moumingce = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards)
    return parse_action(self,"#moumingceCard:"..cards[1]:getEffectiveId()..":")
end

ai_card_use["#moumingceCard"] = function(self, card, use, request)
    local target
    local friends = self.friends_noself
    self:sort(self.enemies,"defense")
    for _,friend in ipairs(friends)do
        if self:canDraw(friend, self.player) and hasZhaxiangEffect(friend) then
            target = friend
            break
        end
    end
    if not target then
        self:sort(friends,"defense")
        for _,friend in ipairs(friends)do
            if self:canDraw(friend, self.player) then
                target = friend
                break
            end
        end
    end

    if target then
        use.card = card
        use.to:append(target)
    end
end

ai_skill_choice.moumingce = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    local chengong = self.room:getCurrent()
    if not self:isFriend(chengong) then return ai_choice_result(("2"), options) end
    if (hasZhaxiangEffect(self.player) or math.random() < 0.4) and self:isFriend(chengong) and self.player:getHp() + source_query(self, "getAllPeachNum") - 1 > 0 then return ai_choice_result(("1"), options) end
    return ai_choice_result(("2"), options)
end

sgs.ai_skill_playerchosen.moumingce = function(self,targets)
    targets = sgs.QList2Table(targets)
    return self:findPlayerToDamage(source_query(self.player, "getMark", "&mouCeC"),self.player,"N",targets)[1]
end
sgs.ai_ajustdamage_to.mouzhichi = function(self,from,to,card,nature)
    if source_query(to, "getMark", "&mouzhichi-Clear")>0
    then return -99 end
end

sgs.ai_skill_discard.mobilemoutiandu = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getHandcards())
    local to_discard = {}
    for _,fcard in sgs.list(cards)do
        if #to_discard>=min_num then break end
        for _,m in sgs.list(self.player:getMarkNames())do
            if source_query(self.player, "getMark", m)>0 and m:startsWith("&mobilemoutiandu+:") and m:contains(fcard:getSuitString().."_char") then
                if isCard("ArcheryAttack",fcard,self.player)
                or isCard("ArcheryAttack",fcard,self.player)
                or isCard("ExNihilo",fcard,self.player)
                or isCard("Peach",fcard,self.player)
                then continue end
                if not source_query(self.player, "isCardLimited", fcard, sgs.Card_MethodDiscard) then
                    table.insert(to_discard,fcard:getKnownEffectiveId())
                end
            end
        end
    end

    if #to_discard == min_num then
        return to_discard
    end
    local to_discard = {}
    for _,fcard in sgs.list(cards)do
        if #to_discard>=min_num then break end
        if isCard("ArcheryAttack",fcard,self.player)
        or isCard("ArcheryAttack",fcard,self.player)
        or isCard("ExNihilo",fcard,self.player)
        or isCard("Peach",fcard,self.player)
        then continue end
        if not source_query(self.player, "isCardLimited", fcard, sgs.Card_MethodDiscard) then
            table.insert(to_discard,fcard:getKnownEffectiveId())
        end
    end
    if #to_discard == min_num then
        return to_discard
    end
    return {}
end

sgs.ai_skill_askforag.mobilemoutiandu = function(self,card_ids)
    for _,id in sgs.list(RandomList(card_ids))do
        local c = known_card(self,id)
        c = preview(self,c:objectName())
        mutate(self,c,"skill","_mobilemoutiandu")
        local d = use_card(self,c)
        set_state(self,"mobilemoutiandu_use",d)
        if d.card and d.to
        then return id end
    end
end

ai_skill_use["@@mobilemoutiandu!"] = function(self, prompt, request)
    local dummy = get_state(self,"mobilemoutiandu_use")
    if dummy.card and dummy.to then
        local tos = {}
        for _,p in sgs.list(dummy.to)do
            table.insert(tos,p:objectName())
        end
        return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_can_damagehp.mobilemouyiji = function(self,from,card,to)
    return to:getHp()+source_query(self, "getAllPeachNum")-source_query(self, "ajustDamage", from, to, 1, card)>0
    and source_query(self, "canLoseHp", from, card, to)
end

sgs.ai_skill_askforyiji.mobilemouyiji = function(self,card_ids,tos)
    return sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
end

ai_skill_use["@@moukurou"] = function(self, prompt, request)
    if source_query(self.player, "getHujia") > 4 then
        return "."
    end
    local ids = {}
    local target
    local use_card
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _,c in sgs.list(cards)do
        if (c:isKindOf("Peach")
        or c:isKindOf("Analeptic")) and self.player:getHp() + source_query(self, "getAllPeachNum") - 3 > 0 then
            use_card = c
            break
        end
    end
    if not use_card then
        use_card = cards[1]
    end
    self:sort(self.friends_noself,"defense")
    for _,friend in ipairs(self.friends_noself)do
        if self:canDraw(friend, self.player) then
            target = friend
            break
        end
    end
    if not target then
        local tos = self.room:getOtherPlayers(self.player)
        for _,p in sgs.list(tos)do
            target = p
            break
        end
    end
    if use_card and target and self.player:getHp() + source_query(self, "getAllPeachNum") - 1 > 0 then
        return "#moukurouCard:"..use_card:getKnownEffectiveId()..":->"..target:objectName()
    end
    return "."
end


ai_fill_skill.moujushou = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("h")
    cards = self:sortByKeepValue(cards,nil,"j")
    local toids = {}
    local x = math.min(5 - source_query(self.player, "getHujia"), 2)
    for _,c in sgs.list(cards)do
        table.insert(toids,c:getKnownEffectiveId())
        if #toids >= x then break end
    end
    if #toids > 0 then
        return parse_action(self,"#moujushouCard:"..table.concat(toids,"+")..":")
    end
end

ai_card_use["#moujushouCard"] = function(self, card, use, request)
    use.card = card
end

sgs.ai_use_value["moujushouCard"] = 9.4
sgs.ai_use_priority["moujushouCard"] = 2

sgs.ai_can_damagehp.moujushou = function(self,from,card,to)
    return to:getHp()+source_query(self, "getAllPeachNum")-source_query(self, "ajustDamage", from, to, 1, card)+source_query(self.player, "getHujia")>0
    and source_query(self, "canLoseHp", from, card, to) and not to:faceUp()
end
ai_fill_skill.moujiewei = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#moujieweiCard:.:")
end

ai_card_use["#moujieweiCard"] = function(self, card, use, request)
    self:sort(self.enemies,"handcard")
    self.enemies = sgs.reverse(self.enemies)
    for _,p in sgs.list(self.enemies)do
        if source_query(self, "doDisCard", p, "h", true) then
            use.card = card
            if use.to then
                use.to:append(p)
            end
            return
        end
    end
end

sgs.ai_use_value["moujieweiCard"] = 9.4
sgs.ai_use_priority["moujieweiCard"] = 3

sgs.ai_card_priority.moujizhi = function(self,card,v)
    if self.useValue
    and card:isKindOf("TrickCard")
    then v = v+3 end
end
ai_audited_aliases.register{id="ai_cardneed.moujizhi",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"moujizhi"},canonical_registry="ai_cardneed",canonical_path={"jizhi"}}

ai_fill_skill.mouqicai = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#mouqicaiCard:.:")
end
ai_card_use["#mouqicaiCard"] = function(self, card, use, request)
    local use_card
    for _,id in sgs.qlist(scope_list(self,"mouqicaiDiscardPile"))do
        if source_query(self.player, "getMark", "f_mode_doudizhu")>0 then
            if printed_card(self,id):isKindOf("Armor")
            and source_query(self.player, "getMark", "mouqicaiArmor"..printed_card(self,id):objectName()) < 1
            then use_card = nil break end
    elseif printed_card(self,id):isKindOf("EquipCard") then use_card = nil break end
    end
    for _,h in sgs.qlist(self.player:getHandcards())do
        if source_query(self.player, "getMark", "f_mode_doudizhu")>0
        then if h:isKindOf("Armor") then use_card = h break end
        elseif h:isKindOf("EquipCard") then use_card = h break end
    end
    self:sort(self.friends_noself,"handcard")
    self.friends_noself = sgs.reverse(self.friends_noself)
    if use_card then card = parse_action(self,"#mouqicaiCard:"..use_card:getKnownEffectiveId()..":") end
    for _,p in sgs.list(self.friends_noself)do
        if self:loseEquipEffect(p) or self:hasSkills(sgs.need_equip_skill,p) then
            if source_query(p, "hasEquipArea") or (use_card and source_query(p, "hasEquipArea", source_query(use_card, "getEquipSlot"))) then
                use.card = card
                if use.to then
                    use.to:append(p)
                end
                return
            end
        end
    end
    self:sort(self.enemies,"handcard")
    self.enemies = sgs.reverse(self.enemies)
    for _,p in sgs.list(self.enemies)do
        if not self:loseEquipEffect(p) and not self:hasSkills(sgs.need_equip_skill,p) and source_query(p, "getMark", "&mouQI") == 0 then
            if source_query(p, "hasEquipArea") or (use_card and source_query(p, "hasEquipArea", source_query(use_card, "getEquipSlot"))) then
                use.card = card
                if use.to then
                    use.to:append(p)
                end
                return
            end
        end
    end
    for _,p in sgs.list(self.enemies)do
        if not self:loseEquipEffect(p) and not self:hasSkills(sgs.need_equip_skill,p) then
            if source_query(p, "hasEquipArea") or (use_card and source_query(p, "hasEquipArea", source_query(use_card, "getEquipSlot"))) then
                use.card = card
                if use.to then
                    use.to:append(p)
                end
                return
            end
        end
    end
end

sgs.ai_use_value["mouqicaiCard"] = 9.4
sgs.ai_use_priority["mouqicaiCard"] = 3

sgs.ai_skill_discard.moumingren = function(self,discard_num,min_num,optional,include_equip)
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(handcards)
    if not optional then
        local red_cards = {}
        local black_cards = {}
        for _,c in ipairs(handcards)do
            if c:isRed() then
                table.insert(red_cards,c:getKnownEffectiveId())
            else
                table.insert(black_cards,c:getKnownEffectiveId())
            end
        end
        if #red_cards>#black_cards then
            return red_cards[1]
        elseif #black_cards>#red_cards then
            return black_cards[1]
        elseif self.player:getPile("mouResponsibility"):isEmpty() then
            for _,c in ipairs(handcards)do
                return c:getKnownEffectiveId()
            end
        end
    else
        local ren = known_card(self,self.player:getPile("mouResponsibility"):first())
        for _,c in ipairs(handcards)do
            if self:getCardsNum("Nullification")>0 and c:isKindOf("TrickCard") then
                if ren:isKindOf("TrickCard") then
                    if not c:isKindOf("Nullification") and self:cardNeed(ren)>self:cardNeed(c) then return c:getKnownEffectiveId() end
                else
                    if not c:isKindOf("Nullification") or self:getCardsNum("Nullification")>1 then return c:getKnownEffectiveId() end
                end
            end
            if c:isKindOf("BasicCard") then
                if ren:isKindOf("BasicCard") then
                    if self:cardNeed(ren)>self:cardNeed(c) then return c:getKnownEffectiveId() end
                else
                    if c:isKindOf("Slash") then return c:getKnownEffectiveId() end
                    if c:isKindOf("Jink") and self:getCardsNum("Jink")>1 then return c:getKnownEffectiveId() end
                    if c:isKindOf("Analeptic") and self:getCardsNum("Analeptic")>1 then return c:getKnownEffectiveId() end
                    if c:isKindOf("Peach") and self:getCardsNum("Peach")>1 then return c:getKnownEffectiveId() end
                end
            end
        end
        if self:cardNeed(ren)>self:cardNeed(handcards[1]) then return handcards[1]:getEffectiveId() end
        return {}
    end
    return {}
end

ai_fill_skill.mouzhenliang = function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getPile("mouResponsibility"):length()>0 then
        return parse_action(self,"#mouzhenliang:.:")
    end
end

ai_card_use["#mouzhenliang"] = function(self, card, use, request)
    self:sort(self.enemies,"hp")
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards,true)
    local target = nil
    local use_card_num = 0
    local use_card = {}
    for _,enemy in ipairs(self.enemies)do
        use_card_num = math.max(1,math.abs(enemy:getHp()-self.player:getHp()))
        if use_card_num>2 then continue end
        use_card = {}
        if source_query(self.player, "inMyAttackRange", enemy) and source_query(self, "canDamage", enemy, self.player) then
            for _,c in ipairs(cards)do
                if source_query(c, "sameColorWith", known_card(self,self.player:getPile("mouResponsibility"):first())) and not c:isKindOf("Peach") then
                    table.insert(use_card,c:getKnownEffectiveId())
                    if #use_card==use_card_num then target = enemy break end
                end
            end
            if target then break end
        end
    end
    if #use_card==0 or target==nil or #use_card<use_card_num then return end
    use.card = parse_action(self,"#mouzhenliang:"..table.concat(use_card,"+")..":")
    use.to:append(target)
end

sgs.ai_use_priority["mouzhenliang"] = sgs.ai_use_priority.Snatch-0.1
sgs.ai_use_value["mouzhenliang"] = 7

sgs.ai_skill_playerchosen.mouzhenliang = function(self,targets)
    return self:findPlayerToDraw(true,2)
end

ai_fill_skill.mouliangzhu = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#mouliangzhuCard::")
end

ai_card_use["#mouliangzhuCard"] = function(self, card, use, request)
    self:sort(self.friends_noself,"hp")
    self.friends_noself = sgs.reverse(self.friends_noself)
    for _,p in sgs.list(self.friends_noself)do
        if source_query(self, "doDisCard", p, "e", true) then
            use.card = card
            if use.to then
                use.to:append(p)
            end
            return
        end
    end
    self:sort(self.enemies,"handcard")
    self.enemies = sgs.reverse(self.enemies)
    for _,p in sgs.list(self.enemies)do
        if source_query(self, "doDisCard", p, "e", true) then
            use.card = card
            if use.to then
                use.to:append(p)
            end
            return
        end
    end
    for _,p in sgs.list(self.friends_noself)do
        if source_query(p, "hasEquip") then
            use.card = card
            if use.to then
                use.to:append(p)
            end
            return
        end
    end
    for _,p in sgs.list(self.enemies)do
        if source_query(p, "hasEquip") then
            use.card = card
            if use.to then
                use.to:append(p)
            end
            return
        end
    end
end

sgs.ai_skill_playerchosen.moujieyin = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")

    return targets[math.random(1, #targets)]
end
ai_skill_choice["moujieyin"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local target = data:toPlayer()
    if self:isFriend(target) and table.contains(items, "1") and not self:isWeak() then
        return ai_choice_result(("1"), options)
    end
    return ai_choice_result((items[math.random(1,#items)]), options)
end


sgs.ai_skill_playerchosen.mouxiaoji = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _, enemy in ipairs(self.enemies) do
        if source_query(self, "doDisCard", enemy, "je") then
            return enemy
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if (self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty())
            or (source_query(self, "needToThrowArmor", friend) and friend:getArmor()) or source_query(self, "doDisCard", friend, "je") then
            return friend
        end
    end
    return nil
end

ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.mouxiaoji",defer_canonical=true,self_index=1,registry="ai_choicemade_filter",path={"cardChosen","mouxiaoji"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","dismantlement"}}

sgs.ai_use_revises.mouxiaoji = function(self,card,use)
    if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5 and self.player:getKnownKingdom() == "wu"
    then use.card = card return true end
end

ai_fill_skill.mouwusheng = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards, nil, true)
    for _, h in sgs.list(cards) do
        for c, pn in sgs.list(RandomList(pattern_names(self))) do
            c = preview(self,pn)
            if c and c:isKindOf("Slash")
            then
                mutate(self,c,"skill","mouwusheng")
                mutate(self,c,"add",h)
                if source_query(c, "isAvailable", self.player)
                then
                    return c
                end
            end
        end
    end
end

sgs.ai_guhuo_card.mouwusheng = function(self, toname, class_name)
    if class_name == "Slash"
    then
        local cards = self:addHandPile("he")
        cards = self:sortByKeepValue(cards, nil, true)
        for c, h in sgs.list(cards) do
            c = preview(self,toname)
            mutate(self,c,"skill","mouwusheng")
            mutate(self,c,"add",h)
            return c:toString()
        end
    end
end

sgs.ai_skill_playerchosen.mouwusheng = function(self, targets)
    local slashcount = self:getCardsNum("Slash")
    if slashcount>0  then
        local slash = self:getCard("Slash")
        assert(slash)
        local dummy_use = source_query(self, "withOwnerRange", "InfinityAttackRange", "mouwusheng", function()
            return use_card(self,slash,dummy(true,99))
        end)
        if dummy_use.card and dummy_use.to:length() > 0 then
            for _,enemy in sgs.qlist(dummy_use.to) do
                if not source_query(self.player, "inMyAttackRange", enemy) and targets:contains(enemy) then
                    return enemy
                end
            end
            for _,enemy in sgs.qlist(dummy_use.to) do
                if targets:contains(enemy) then
                    return enemy
                end
            end
        end
    end
    self:sort(self.enemies, "defense")
    for _, enemy in ipairs(self.enemies) do
        return enemy
    end
    return nil
end

sgs.ai_target_revises["&mouyijued"] = function(to,card,self)
    return not card:isKindOf("SkillCard") and source_query(to, "getMark", self.player:objectName().."mouyijued-Clear") > 0
end

sgs.ai_target_revises.mouhuoshou = function(to,card)
    if card:isKindOf("SavageAssault")
    then return true end
end

ai_skill_use["@@mouzaiqi"] = function(self, prompt, request)
    local n = source_query(self.player, "getMark", "&charge_num")
    n = math.min(n,#self.friends)
    if n<=0 then return "." end

    local lost = self.player:getMaxHp()-self.player:getHp()
    self:sort(self.friends,"handcard")
    local friends = {}

    for i = 1,n do
        lost = lost-1
        if lost<=0 and self:canDraw(self.friends[i]) then
            table.insert(friends,self.friends[i]:objectName())
        elseif lost>0 then
            table.insert(friends,self.friends[i]:objectName())
        end
    end
    if #friends>0 then
        return "#mouzaiqiCard:.:->"..table.concat(friends,"+")
    end
    return "."
end
ai_skill_choice.mouzaiqi = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local to = data:toPlayer()
    choices = choices:split("+")
    if not self:isFriend(to) then
        if self.player:isKongcheng() and self:needKongcheng() and table.contains(choices,"2") then return ai_choice_result(("2"), options) end
        return ai_choice_result(("1"), options)
    else
        if table.contains(choices,"2") then return ai_choice_result(("2"), options) end
        return ai_choice_result(("1"), options)
    end

    return ai_choice_result(nil, options)
end

-- This source predicate may legitimately return nil. Only the actual audited
-- helper provider can establish that nil; missing facts/providers stay unknown.
local function r43_mouluanji_damage(self,enemy)
    local provider=self.damageIsEffective
    if type(provider)~='function' then ai_unsupported('Mouluanji damage provider unavailable','newgenerals.mouluanji') end
    local value=provider(self,enemy)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil and not SmartAIView.isKnownNilStrategyResult(self,'damageIsEffective',provider) then
        ai_unsupported('Mouluanji damage result unknown','newgenerals.mouluanji')
    end
    return value
end
ai_fill_skill.mouluanji = function(self, options, request)
    local inclusive = options and options.inclusive

    if source_query(self.player, "getMark", "mouluanjiUsed-PlayClear")>0 then return nil end
    local cards = self:addHandPile()
    if #cards>=2
    then
        self:sortByKeepValue(cards)
        local useAll = #cards>4
        for _,enemy in ipairs(self.enemies)do
            if enemy:getHp()==1
            and not source_query(enemy, "hasArmorEffect", "Vine")
            and not source_query(self, "hasEightDiagramEffect", enemy)
            and r43_mouluanji_damage(self,enemy)
            and self:isWeak(enemy) and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
            then useAll = true end
        end
        if not useAll then return end
        for _,fcard in ipairs(cards)do
            if isCard("ArcheryAttack",fcard,self.player)
            or isCard("ExNihilo",fcard,self.player)
            or isCard("Peach",fcard,self.player)
            then continue end
            for _,scard in ipairs(cards)do
                if isCard("ArcheryAttack",scard,self.player)
                or isCard("ExNihilo",scard,self.player)
                or isCard("Peach",scard,self.player)
                or AIValue.sameLegacyIdentity(fcard,scard)
                then continue end
                local archery = preview(self,"archery_attack")
                mutate(self,archery,"skill","mouluanji")
                mutate(self,archery,"add",fcard)
                mutate(self,archery,"add",scard)
                local dummy_use = use_card(self,archery)
                if AIUnsupported.is(dummy_use) then error(dummy_use,0) end
                if dummy_use.card then return archery end
            end
        end
    end
end


ai_skill_use["@@mobilemoutuxi"] = function(self, prompt, request)
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByCardNeed(handcards, true)
    local targets = {}

    local use_cards = {}
    for _,c in ipairs(handcards) do
        if c:getStrategyFlag("moutuxi") and source_query(self, "getKeepValue", c) < 5 then
            table.insert(use_cards, c:getKnownEffectiveId())
        end
    end
    local add_player = function (player,isfriend)
        if player:getHandcardNum()==0 or player:objectName()==self.player:objectName() then return #targets end
        if source_query(self, "objectiveLevel", player)==0 and player:isLord() and role_count(self,"rebel")>1 then return #targets end

        local f = false
        for _,c in ipairs(targets)do
            if c==player:objectName() then
                f = true
                break
            end
        end

        if not f then table.insert(targets,player:objectName()) end

        if isfriend and isfriend==1 then
            strategy_flag(self,self.player,"tenyeartuxi_isfriend_"..player:objectName())
        end
        return #targets
    end
    local parsemobilemoutuxiCard = function()
        if #targets==0 then return "." end
        local s = table.concat(targets,"+")
        return "#mobilemoutuxiCard:"..table.concat(use_cards,"+")..":->"..table.concat(targets,"+")
    end
    for _, enemy in ipairs(self.enemies) do
        if source_query(self, "doDisCard", enemy, "h", true) and add_player(enemy)==#use_cards then
            return parsemobilemoutuxiCard()
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if source_query(self, "doDisCard", friend, "h", true) and add_player(friend)==#use_cards then
            return parsemobilemoutuxiCard()
        end
    end
    if #targets < #use_cards then
        local usecards = {}
        for _,c in ipairs(handcards) do
            if c:getStrategyFlag("moutuxi") then
                table.insert(usecards, c:getKnownEffectiveId())
                if #usecards >= #targets then
                    break
                end
            end
        end
        return "#mobilemoutuxiCard:"..table.concat(usecards,"+")..":->"..table.concat(targets,"+")
    end

    return "."
end

sgs.ai_skill_playerchosen.mobilemoudengfeng = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _, enemy in ipairs(self.enemies) do
        if source_query(self, "doDisCard", enemy, "je") then
            return enemy
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if (self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty())
            or (source_query(self, "needToThrowArmor", friend) and friend:getArmor()) or source_query(self, "doDisCard", friend, "je") then
            return friend
        end
    end
    for _, enemy in ipairs(self.enemies) do
        return enemy
    end
    return nil
end
ai_skill_choice.mobilemoudengfeng = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local to = data:toPlayer()
    choices = choices:split("+")
    if table.contains(choices,"3") and source_query(self, "doDisCard", to, "e", true) and self.player:getHp() + source_query(self, "getAllPeachNum") - 1 > 0 and math.random() < 0.5 then return ai_choice_result(("3"), options) end
    if table.contains(choices,"1") and source_query(self, "doDisCard", to, "e", true) then return ai_choice_result(("1"), options) end
    return ai_choice_result(("2"), options)
end

ai_skill_use["@@moulveying"] = function(self, prompt, request)
    local dismantlement = clone_preview(self,"dismantlement")
    mutate(self,dismantlement,"skill","moulveying")

    local dummy_use = use_card(self,dismantlement, dummy(true))
    if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() then
        local targets = {}
        for _,p in sgs.list(dummy_use.to)do
            table.insert(targets,p:objectName())
        end
        if #targets>0 then
            return dismantlement:toString().."->"..table.concat(targets,"+")
        end
    end
    return "."
end
ai_skill_use["@@mouyingwu"] = function(self, prompt, request)
    local slash = clone_preview(self,"slash")
    mutate(self,slash,"skill","mouyingwu")

    local dummy_use = use_card(self,slash, dummy(true))
    if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() then
        local targets = {}
        for _,p in sgs.list(dummy_use.to)do
            table.insert(targets,p:objectName())
        end
        if #targets>0 then
            return slash:toString().."->"..table.concat(targets,"+")
        end
    end
    return "."
end



sgs.ai_guhuo_card.moulongdan = function(self, toname, class_name)
    if self:getCardsNum(class_name)>0 then return end
    if source_query(self.player, "getMark", "moujizhuoBf") == 0 then return end
    if source_query(self.player, "getMark", "&moulongdanLast")<1 then return end
    local card = clone_preview(self,toname, sgs.Card_SuitToBeDecided, -1)

    if (not card) or (not card:isKindOf("BasicCard")) then return end
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards, nil, true)
    for c, h in sgs.list(cards) do
        if h:isKindOf("BasicCard") and h:isKindOf("BasicCard") then
            c = preview(self,toname)
            mutate(self,c,"skill","moulongdan")
            mutate(self,c,"add",h)
            return c:toString()
        end
    end
end

ai_fill_skill.moulongdan = function(self, options, request)
    local inclusive = options and options.inclusive

    if source_query(self.player, "getMark", "&moulongdanLast") < 1 then return end
    local cards = self:addHandPile()
    self:sortByUseValue(cards, true)

    local function findCardByType(cards, type_func)
        for _, card in ipairs(cards) do
            if type_func(card) then
                return card
            end
        end
    end

    if source_query(self.player, "getMark", "moujizhuoBf") > 0 then
        local use_card = findCardByType(cards, function(card) return card:isKindOf("BasicCard") end)
        if not use_card then return nil end
        for _, pn in ipairs(RandomList(pattern_names(self))) do
            local c = preview(self,pn)
            if c and c:isKindOf("BasicCard") then
                mutate(self,c,"skill","moulongdan")
                mutate(self,c,"add",use_card)
                if source_query(c, "isAvailable", self.player) then
                    return c
                end
            end
        end
    else
        local jink_card = findCardByType(cards, function(card) return card:isKindOf("Jink") end)
        if not jink_card then return nil end
        local suit = jink_card:getSuitString()
        local number = source_query(jink_card, "getNumberString")
        local card_id = jink_card:getKnownEffectiveId()
        local card_str = ("slash:moulongdan[%s:%s]=%d"):format(suit, number, card_id)
        local slash = parse_action(self,card_str)
        assert(slash)
        return slash
    end
end

sgs.ai_view_as.moulongdan = function(card,player,card_place)
    if source_query(player, "getMark", "&moulongdanLast")<1 then return end
    local suit = card:getSuitString()
    local number = source_query(card, "getNumberString")
    local card_id = card:getKnownEffectiveId()
    if card_place==sgs.Player_PlaceHand then
        if card:isKindOf("Jink") then
            return ("slash:moulongdan[%s:%s]=%d"):format(suit,number,card_id)
        elseif card:isKindOf("Slash") then
            return ("jink:moulongdan[%s:%s]=%d"):format(suit,number,card_id)
        end
    end
end


ai_audited_aliases.register{id="ai_cardneed.moulongdan",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"moulongdan"},canonical_registry="ai_cardneed",canonical_path={"longdan"}}
sgs.ai_card_priority.moulongdan = function(self,card)
    if table.contains(source_query(card, "getSkillNames"), "moulongdan")
    then
        return 1
    end
end

sgs.ai_skill_playerchosen.moujizhuo = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "handcard")
    for _, friend in ipairs(self.friends_noself) do
        return friend
    end
    for _, enemy in ipairs(self.enemies) do
        return enemy
    end
    return targets[1]
end

ai_audited_aliases.register{id="ai_use_revises.moupaoxiao",defer_canonical=true,self_index=1,registry="ai_use_revises",path={"moupaoxiao"},canonical_registry="ai_use_revises",canonical_path={"paoxiao"}}
ai_audited_aliases.register{id="ai_cardneed.moupaoxiao",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"moupaoxiao"},canonical_registry="ai_cardneed",canonical_path={"paoxiao"}}
sgs.ai_ajustdamage_from.moupaoxiao = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and source_query(from, "getMark", "moupaoxiaoSlashUsed-PlayClear")>1 then
        return 1
    end
end

sgs.ai_skill_playerchosen.mouxieji = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "handcard")
    for _, friend in ipairs(self.friends_noself) do
        return friend
    end
    for _, enemy in ipairs(self.enemies) do
        return enemy
    end
    return targets[1]
end

ai_skill_use["@@mouxieji"] = function(self, prompt, request)
    local slash = clone_preview(self,"slash")
    mutate(self,slash,"skill","_mouxieji")

    local dummy_use = use_card(self,slash, dummy(true,2))
    if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() then
        local targets = {}
        for _,p in sgs.list(dummy_use.to)do
            table.insert(targets,p:objectName())
        end
        if #targets>0 then
            return "#mouxiejiCard:.:->"..table.concat(targets,"+")
        end
    end
    return "."
end

ai_skill_use["@@moumingxuan!"] = function(self, prompt, request)
    self:sort(self.enemies, "defense")
    local n = math.max(1,source_query(self.player, "getMark", "moumingxuanCardGive"))
    local targets = {}
    local suits = {}
    local use_cards = {}
    for _, card in sgs.qlist(self.player:getCards("h")) do
        if not table.contains(suits, card:getSuitString()) and not card:isKindOf("Slash") then
            table.insert(suits, card:getSuitString())
            table.insert(use_cards, card:getKnownEffectiveId())
            if #use_cards >= n then break end
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if source_query(friend, "getMark", "&moumingxuan+#"..self.player:objectName()) < 1 then
            table.insert(targets, friend:objectName())
            if #targets >= #use_cards then break end
        end
    end
    if #targets < #use_cards then
        for _, enemy in ipairs(self.enemies) do
            if source_query(enemy, "getMark", "&moumingxuan+#"..self.player:objectName()) < 1 and ((self:getKnownNum(enemy)==enemy:getHandcardNum() and getKnownCard(enemy,self.player,"Slash")==0) or enemy:getHandcardNum() < 3) then
                table.insert(targets, enemy:objectName())
                if #targets >= #use_cards then break end
            end
        end
    end
    if #use_cards > #targets then
        local suits = {}
        local use_cards = {}
        for _, card in sgs.qlist(self.player:getCards("h")) do
            if not table.contains(suits, card:getSuitString()) then
                table.insert(suits, card:getSuitString())
                table.insert(use_cards, card:getKnownEffectiveId())
                if #use_cards >= #targets then break end
            end
        end
    end
    if #targets == #use_cards and #targets > 0 then
        return "#moumingxuanCard:"..table.concat(use_cards,"+")..":->"..table.concat(targets,"+")
    end
end
sgs.ai_can_damagehp.mouxianchou = function(self,from,card,to)
    if from and to:getHp()+source_query(self, "getAllPeachNum")-source_query(self, "ajustDamage", from, to, 1, card)>0
    and source_query(self, "canLoseHp", from, card, to)
    then
        return self:isEnemy(from) and self:isWeak(from)
    end
end

sgs.ai_skill_playerchosen.mouxianchou = function(self, targets)
    local destlist = sgs.QList2Table(targets) -- 将列表转换为表
    self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target) and source_query(self, "doDisCard", target, "he") then
            return target
        end
    end
    for _,target in sgs.list(destlist)do
        if self:isFriend(target) then
            return target
        end
    end
    return destlist[1]
end

sgs.ai_skill_cardask["@mouxianchou-slash"] = function(self, data, pattern, target, target2)
    local damage = data:toDamage()
    local dc = preview(self)
    mutate(self,dc,"skill","_mouxianchou")
    local dummy_use = source_query(self, "withOwnerRange", "InfinityAttackRange", "@mouxianchou-slash", function()
        return use_card(self,dc,dummy(true,0,self.room:getOtherPlayers(damage.from)))
    end)
    if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(damage.from) then
        return true
    end
    return false
end

ai_fill_skill.mouyanyu = function(self, options, request)
    local inclusive = options and options.inclusive

    if #self.friends_noself == 0 then return nil end
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isKindOf("Slash") then
            local card_str = "#mouyanyuCard:"..card:getKnownEffectiveId()..":"
            return parse_action(self,card_str)
        end
    end
end

ai_card_use["#mouyanyuCard"] = function(self, card, use, request)
    use.card = card
end

sgs.ai_skill_playerchosen.mouyanyu = function(self, targets)
    return self:findPlayerToDraw(false, source_query(self.player, "getMark", "&mouyanyuDraw-PlayClear")*3)
end
sgs.ai_playerchosen_intention.mouyanyu = -80
ai_skill_invoke.mouqiaoshi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local damage = data:toDamage()
    return (self:isFriend(damage.to) or ZishuEffect(self.player)>0 or not damage.to:isWounded()) or false
end

sgs.ai_choicemade_filter.skillInvoke.mouqiaoshi = function(self,player,promptlist)
    local damage = scoped_struct(self,"CurrentDamageStruct","damage")
    if promptlist[#promptlist]=="yes" and damage then
        self:updateIntention(player,damage.to,-40)
    end
end

sgs.ai_can_damagehp.mouqiaoshi = function(self,from,card,to)
    if from and to:getHp()+source_query(self, "getAllPeachNum")-source_query(self, "ajustDamage", from, to, 1, card)>0
    and source_query(self, "canLoseHp", from, card, to)
    then
        return self:isFriend(from) and source_query(to, "getMark", "mouqiaoshiUse-Clear")<1 and role_estimate(self,to) ~= "neutral"
    end
end


ai_fill_skill.moujiang = function(self, options, request)
    local inclusive = options and options.inclusive

    local fs = preview(self,"duel")
    mutate(self,fs,"skill","moujiang")
    for _,c in sgs.list(self.player:getHandcards())do
        mutate(self,fs,"add",c)
    end
    if fs:subcardsLength()>0
    and source_query(self, "getPriorTurnUseCount")<2
    then return fs end
end

sgs.ai_use_revises.moujiang = function(self,card,use)
    if table.contains(source_query(card, "getSkillNames"), "moujiang") then
        for _,ep in sgs.list(self.enemies)do
            if target_ok(card,self.player,ep,use.to)
            and getCardsNum("Slash",ep,self.player)<1 then
                use.card = card
                use.to:append(ep)
            end
        end
        return AIValue.sameLegacyIdentity(use.card,card)
    end
end

sgs.ai_skill_playerchosen.moujiang = function(self, targets)
    if self.player:getHp() + source_query(self, "getAllPeachNum") - 1 <= 0 then
        return nil
    end
    local use = scoped_struct(self,"moujiang","use")
    local dummy_use = use_card(self,source_query(self, 'evaluateSkillCard', 'newgenerals_context:moujiang', use.card:objectName(), {}),dummy(true,99,use.to))
    if not dummy_use.to:isEmpty() then
        for _, p in sgs.qlist(dummy_use.to) do
            if targets:contains(p) then
                return p
            end
        end
    end
    return nil
end


ai_audited_aliases.register{id="ai_skill_invoke.mouzhiba",defer_canonical=true,self_index=1,registry="ai_skill_invoke",path={"mouzhiba"},canonical_registry="ai_skill_invoke",canonical_path={"niepan"}}
ai_audited_aliases.register{id="ai_skill_invoke.mouzhibas",defer_canonical=true,self_index=1,registry="ai_skill_invoke",path={"mouzhibas"},canonical_registry="ai_skill_invoke",canonical_path={"niepan"}}

sgs.ai_skill_playerchosen.moulieren = function(self, targets)
    return self:findPlayerToDamage(1, self.player,sgs.DamageStruct_Normal, targets)[1]
end
ai_audited_aliases.register{id="ai_cardneed.moulieren",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"moulieren"},canonical_registry="ai_cardneed",canonical_path={"lieren"}}
ai_audited_aliases.register{id="ai_skill_pindian.moulieren",defer_canonical=true,self_index=2,registry="ai_skill_pindian",path={"moulieren"},canonical_registry="ai_skill_pindian",canonical_path={"lieren"}}
ai_skill_invoke.moulieren = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    if not self:isEnemy(target) then return (false) or false end

    if self.player:getHandcardNum()==1 then
        if (self:needKongcheng() or not source_query(self, "hasLoseHandcardEffective")) and not self:isWeak() then return (true) or false end
        local card  = self.player:getHandcards():first()
        if card:isKindOf("Jink") or card:isKindOf("Peach") then return false end
    end
    return (sgs.ai_skill_playerchosen.moulieren(self, self.room:getOtherPlayers(target)) ~= nil) or false
end

sgs.ai_target_revises.makijuxiang = function(to,card)
    if card:isKindOf("SavageAssault")
    then return true end
end


ai_fill_skill.moutianxiang = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#moutianxiangCard:.:")
end

ai_card_use["#moutianxiangCard"] = function(self, card, use, request)
    local function hasMoutianxiangMark(player)
        for _, mark in sgs.list(player:getMarkNames()) do
            if string.startsWith(mark, "&moutianxiang") and source_query(player, "getMark", mark) > 0 then
                return true
            end
        end
        return false
    end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local heart, red
    for _,c in ipairs(cards) do
        if not heart and c:getSuit() == sgs.Card_Heart then heart = c end
        if not red and c:isRed() then red = c end
        if heart and red then break end
    end

    self:sort(self.friends_noself, "hp")

    local function tryUse(targets, cond, card_obj)
        for _, p in sgs.list(targets) do
            if cond(p) and not hasMoutianxiangMark(p) then
                use.card = parse_action(self,"#moutianxiangCard:" .. card_obj:getKnownId() .. ":")
                if use.to then use.to:append(p) end
                return true
            end
        end
        return false
    end

    if heart then
        if tryUse(self.friends_noself, function(p) return source_query(self, "needToLoseHp", p) or not self:isWeak(p) end, heart) then return end
    end

    if red then
        if tryUse(self.friends_noself, function(p) return source_query(self, "doDisCard", p, "he", true) or hasTuntianEffect(p) end, red) then return end
    end
     if heart then
        if tryUse(self.enemies, function(p) return not source_query(self, "needToLoseHp", p) or self:isWeak(p) end, heart) then return end
    end
end

sgs.ai_use_value.moutianxiangCard = 4.5
sgs.ai_use_priority.moutianxiangCard = 6.7

sgs.ai_skill_playerchosen.moutianxiang = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "handcard")
    for _, friend in ipairs(targets) do
        for _, mark in sgs.list(friend:getMarkNames()) do
            if string.startsWith(mark, "&moutianxiang") and string.contains(mark, "heart") and source_query(friend, "getMark", mark) > 0 and source_query(self, "needToLoseHp", friend) then
                return friend
            end
        end
    end
    for _, enemy in ipairs(targets) do
        for _, mark in sgs.list(enemy:getMarkNames()) do
            if string.startsWith(mark, "&moutianxiang") and string.contains(mark, "heart") and source_query(enemy, "getMark", mark) > 0 then
                return enemy
            end
        end
    end
    for _, enemy in ipairs(targets) do
        for _, mark in sgs.list(enemy:getMarkNames()) do
            if string.startsWith(mark, "&moutianxiang") and string.contains(mark, "diamond") and source_query(enemy, "getMark", mark) > 0 and source_query(self, "doDisCard", enemy, "he", true, 2) then
                return enemy
            end
        end
    end
    return nil
end


sgs.ai_skill_suit.mouhongyan = function(self, card)
    local judge = scoped_judge(self,"mouhongyan")
    if judge and self:needRetrial(judge) and not (self:getFinalRetrial() == 2) then
        local suits = {sgs.Card_Diamond, sgs.Card_Heart, sgs.Card_Spade, sgs.Card_Club}
        local isFriend = self:isFriend(judge.who)
        for _, suit in ipairs(suits) do
            local newcard = judge:cloneCandidate(suit,0)

            if (isFriend and judge:isGood(newcard)) or (not isFriend and not judge:isGood(newcard)) then
                return suit
            end
        end
    end
    local map = { 0, 0, 1, 2, 2, 3, 3, 3 }
    return map[math.random(1, 8)]
end


ai_skill_invoke.rensongshu = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local to = data:toPlayer()
    local card_count = scoped_count(self,"ren_pile_count")
    return (self:isEnemy(to) and (card_count<4 or self:isWeak())) or false
end

ai_skill_invoke.renyizhu = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = data:toCardUse()
    if self:isEnemy(use.from) then
        return (self:isFriend(use.to:first())
        or self:isEnemy(use.to:first())) or false
    end
    return false

end

ai_fill_skill.renluanchou = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#renluanchouCard:.:")
end

ai_card_use["#renluanchouCard"] = function(self, card, use, request)
    self:sort(self.friends,"hp")
    self:sort(self.enemies,"hp",true)
    for _,ep in sgs.list(self.enemies)do
        for _,p in sgs.list(self.friends)do
            if ep:getHp()>p:getHp() then
                use.card = card
                return
            end
        end
    end
    local tos = self.room:getAllPlayers()
    tos = self:sort(tos,"hp",true)
    for _,ep in sgs.list(tos)do
        for _,p in sgs.list(self.friends)do
            if ep:getHp()>p:getHp() then
                use.card = card
                return
            end
        end
    end
    for _,ep in sgs.list(self.enemies)do
        for _,p in sgs.list(self.friends)do
            if ep:getHp()>=p:getHp() then
                use.card = card
                return
            end
        end
    end
    for _,ep in sgs.list(tos)do
        for _,p in sgs.list(self.friends)do
            if ep~=p and ep:getHp()>=p:getHp() then
                use.card = card
                return
            end
        end
    end
end

sgs.ai_use_value.renluanchouCard = 4.5
sgs.ai_use_priority.renluanchouCard = 6.7

sgs.ai_skill_playerschosen.renluanchou = function(self,players,x,n)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp")
    local tos = {}
    for _,target in sgs.list(destlist)do
        if self:isFriend(target) then
            table.insert(tos,target)
            break
        end
    end
    for _,target in sgs.list(sgs.reverse(destlist))do
        if self:isEnemy(target) and #tos==1 and target:getHp()>tos[1]:getHp() then
            table.insert(tos,target)
        end
    end
    for _,target in sgs.list(sgs.reverse(destlist))do
        if self:isEnemy(target) and #tos==1 and target:getHp()>=tos[1]:getHp() then
            table.insert(tos,target)
        end
    end
    for _,target in sgs.list(sgs.reverse(destlist))do
        if #tos==1 and target:getHp()>=tos[1]:getHp() then
            table.insert(tos,target)
        end
    end
    return tos
end

ai_skill_invoke.renliaoyi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local to = data:toPlayer()
    return (self:isFriend(to) and to:getHp()>to:getHandcardNum()
    or self:isEnemy(to) and to:getHp()<to:getHandcardNum()) or false
end

ai_fill_skill.renbinglun = function(self, options, request)
    local inclusive = options and options.inclusive

    local card_count = scoped_count(self,"ren_pile_count")
    return card_count>0
    and parse_action(self,"#renbinglunCard:.:")
end

ai_card_use["#renbinglunCard"] = function(self, card, use, request)
    self:sort(self.friends,"hp")
    for _,p in sgs.list(self.friends)do
        if p:isWounded() then
            use.card = card
            use.to:append(p)
            return
        end
    end
    self:sort(self.friends,"handcard")
    for _,p in sgs.list(self.friends)do
        if p:getHandcardNum()<p:getHp() then
            use.card = card
            use.to:append(p)
            return
        end
    end
    use.card = card
    use.to:append(self.player)
end

sgs.ai_use_value.renbinglunCard = 4.5
sgs.ai_use_priority.renbinglunCard = 6.7

ai_skill_choice.renbinglun = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    if source_query(self.player, "getMark", "&renbinglun")>0
    or self.player:getHandcardNum()<3
    then return ai_choice_result((items[1]), options) end
    return ai_choice_result((items[2]), options)
end

ai_fill_skill.mobile_wuling = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#mobile_wulingCard:.:")
end

ai_card_use["#mobile_wulingCard"] = function(self, card, use, request)
    self:sort(self.friends,nil,true)
    for _,p in sgs.list(self.friends)do
        if source_query(p, "getMark", "mobile_wuling")<1 then
            use.card = card
            use.to:append(p)
            return
        end
    end
end

sgs.ai_use_value.mobile_wulingCard = 4.5
sgs.ai_use_priority.mobile_wulingCard = 5.7

ai_skill_choice.mobile_wuling = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local to = data:toPlayer()
    if self:isFriend(to) then
        if table.contains(items,"wl_hu_mark") and self:isWeak(to) then
            return ai_choice_result(("wl_hu_mark"), options)
        end
        if table.contains(items,"wl_lu_mark") and to:getCards("j"):length()>0 then
            return ai_choice_result(("wl_lu_mark"), options)
        end
    end

    return ai_choice_result(nil, options)
end

ai_fill_skill.mobile_youyi = function(self, options, request)
    local inclusive = options and options.inclusive

    local card_count = scoped_count(self,"ren_pile_count")
    return card_count>0 and parse_action(self,"#mobile_youyiCard:.:")
end

ai_card_use["#mobile_youyiCard"] = function(self, card, use, request)
    local n = 0
    for _,p in sgs.list(self.room:getAllPlayers())do
        if p:isWounded() then
            if self:isEnemy(p) then
                n = n-1
                if self:isWeak(p)
                then n = n-1 end
            else
                n = n+1
                if self:isFriend(p) and self:isWeak(p)
                then n = n+1 end
            end
        end
    end
    if n>0 then
        use.card = card
    end
end

sgs.ai_use_value.mobile_youyiCard = 4.5
sgs.ai_use_priority.mobile_youyiCard = 1.7

ai_skill_invoke.mobile_youyi = function(self, options, request)
    return (true) or false
end

ai_skill_invoke.mobile_tamo = function(self, options, request)
    return (true) or false
end

ai_fill_skill.mobile_dingzou = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#mobile_dingzouCard:.:")
end

ai_card_use["#mobile_dingzouCard"] = function(self, card, use, request)
    self:sort(self.friends_noself,nil,true)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _,p in sgs.list(self.friends_noself)do
        if #self:poisonCards("ej",p)>p:getEquips():length()/2 then
            local n = p:getCards("ej"):length()
            if n<1 then continue end
            local ids = {}
            for _,c in sgs.list(cards)do

                table.insert(ids,c:getKnownEffectiveId())
                if #ids>=n then--card:subcardsLength()>=n then
                    use.card = parse_action(self,"#mobile_dingzouCard:"..table.concat(ids,"+")..":")
                    use.to:append(p)
                    return
                end
            end

        end
    end
    for _,p in sgs.list(self.enemies)do
        if #self:poisonCards("ej",p)<p:getEquips():length()/2 then
            local n = p:getCards("ej"):length()
            if n<1 then continue end
            local ids = {}
            for _,c in sgs.list(cards)do

                table.insert(ids,c:getKnownEffectiveId())
                if #ids>=n then--card:subcardsLength()>=n then
                    use.card = parse_action(self,"#mobile_dingzouCard:"..table.concat(ids,"+")..":")
                    use.to:append(p)
                    return
                end
            end

        end
    end
end

sgs.ai_use_value.mobile_dingzouCard = 4.5
sgs.ai_use_priority.mobile_dingzouCard = 4.7

sgs.ai_skill_playerchosen.mobile_zhimeng = function(self,players,x,n)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
        if not self:isFriend(target)
        and target:getHandcardNum()>self.player:getHandcardNum()
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if self:isFriend(target) and self:isWeak(target)
        and target:getHandcardNum()<self.player:getHandcardNum()/2
        then return target end
    end
end


ai_fill_skill.yanduanbi = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#yanduanbiCard:.:")
end

ai_card_use["#yanduanbiCard"] = function(self, card, use, request)
    for _,p in sgs.list(self.friends)do
        if self:isWeak(p) and p:getHandcardNum()<3 then
            use.card = card
            break
        end
    end
end

sgs.ai_use_value.yanduanbiCard = 4.5
sgs.ai_use_priority.yanduanbiCard = 5.7

sgs.ai_skill_playerchosen.yanduanbi = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,nil,true)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        then return target end
    end
end

sgs.ai_skill_playerchosen.yantongdu = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,nil,true)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target)
        and source_query(target, "getCardCount")>2
        then return target end
    end
end

sgs.ai_skill_playerchosen.yandiaodu = function(self,players)
    invoke_peiqi(self)
    for _,target in sgs.list(players)do
        if target==get_state(self,"peiqiData").from
        then return target end
    end
end

sgs.ai_skill_cardchosen.yandiaodu = function(self,who,flags,method)
    for _,e in sgs.list(who:getCards(flags))do
        local id = e:getKnownEffectiveId()
        if id==get_state(self,"peiqiData").cid
        then return id end
    end
end

sgs.ai_skill_playerchosen.yandiaodu_to = function(self,players)
    for _,target in sgs.list(players)do
        if target==get_state(self,"peiqiData").to
        then return target end
    end
end

ai_skill_invoke.yandiancai = function(self, options, request)
    return (true) or false
end

local function canZhengsu(self,player)
    player = player or self.player
    local handcards = sgs.QList2Table(player:getCards("h"))
    self:sortByUsePriority(handcards)
    local tocs,ns = {},AIList.new({})
    for d,h in sgs.list(handcards)do
        if source_query(h, "isAvailable", player) then
            d = use_card(self,h)
            if d.card and d.to
            then table.insert(tocs,h) end
        end
    end
    for d,h in sgs.list(tocs)do
        if ns:contains(h:getNumber()) then continue end
        ns:append(h:getNumber())
    end
    if ns:length()>2 then
        set_state(self,"zhengsu_choice","zhengsu1")
        return true
    end
    for d,h in sgs.list(tocs)do
        ns = 0
        for _,h1 in sgs.list(tocs)do
            if h:getSuit()==h1:getSuit()
            then ns = ns+1 end
        end
        if ns>2 then
            set_state(self,"zhengsu_choice","zhengsu2")
            return true
        end
    end
    if #handcards-source_query(player, "getMaxCards")>2
    and #handcards-source_query(player, "getMaxCards")<5 then
        set_state(self,"zhengsu_choice","zhengsu3")
        return true
    end
end

ai_skill_choice.zhengsu = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

    return ai_choice_result((get_state(self,"zhengsu_choice")), options)
end

ai_skill_invoke.yanyanji = function(self, options, request)
    return (canZhengsu(self)) or false
end

ai_skill_invoke.yantaoluan = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local judge = data:toJudge()
    if self:isFriend(judge.who) then
        return (judge:isBad()) or false
    elseif self:isEnemy(judge.who) then
        return (judge:isGood()) or false
    end
    return (self.player:getHandcardNum()<=source_query(self.player, "getMaxCards")) or false
end

-- Native result is for this exact raw-skill FireSlash and this Choice judge.
-- Do not substitute the generic name:fire_slash snapshot or foreign legality.
local function r48_yantaoluan_can_slash(self,target,card)
    local actual=resolve_preview(card)
    local row=known(rawget(actual,'_view'),'Yantaoluan native face')
    local value=row.source_yantaoluan_can_slash
    if type(value)~='table' or value.actor~=self.player:objectName()
        or value.target~=target:objectName() or value.distance_limit~=false
        or value.range_fix~=0 or type(value.value)~='boolean' then
        ai_unsupported('exact Yantaoluan owner/judge Slash check unavailable','newgenerals.yantaoluan')
    end
    return value.value
end

ai_skill_choice.yantaoluan = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local judge = data:toJudge()
    if self:isEnemy(judge.who) then
        if r48_yantaoluan_can_slash(self,judge.who,preview(self,"fire_slash","_yantaoluan")) then
            return ai_choice_result(("yantaoluan2"), options)
        end
    end
    return ai_choice_result((items[1]), options)
end

ai_skill_invoke.yanshiji = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local to = data:toPlayer()
    return (self:isEnemy(to)
    or not self:isFriend(to) and #self.friends_noself<1) or false
end

ai_skill_invoke.yanzhengjun = function(self, options, request)
    return (canZhengsu(self)) or false
end

sgs.ai_skill_playerchosen.yanzhengjun = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target) then
            return target
        end
    end
end

ai_fill_skill.yanyangjie = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#yanyangjieCard:.:")
end

ai_card_use["#yanyangjieCard"] = function(self, card, use, request)
    local nc = self:getMinCard()
    if nc and nc:getNumber()<5 then
        self:sort(self.enemies)
        set_state(self,"yanyangjie_card",nc)
        for _,p in sgs.list(self.enemies)do
            if source_query(self.player, "canPindian", p) then
                set_state(self,"yanyangjieTo",p)
                use.card = card
                use.to:append(p)
                break
            end
        end
    end
end

sgs.ai_use_value.yanyangjieCard = 4.5
sgs.ai_use_priority.yanyangjieCard = 2.7

sgs.ai_skill_playerchosen.yanyangjie = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,nil,true)
    for _,target in sgs.list(destlist)do
        if self:isFriend(target) then
            for _,sk in ipairs(sgs.getPlayerSkillList(target)) do
                local ts = trigger_skill(self,sk:objectName())
                if ts and (ts:hasEvent(sgs.DamageCaused) or ts:hasEvent(sgs.Damage)) then
                    return target
                end
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if self:isFriend(target) then
            local can = true
            for _,sk in ipairs(sgs.getPlayerSkillList(get_state(self,"yanyangjieTo"))) do
                local ts = trigger_skill(self,sk:objectName())
                if ts and (ts:hasEvent(sgs.DamageInflicted) or ts:hasEvent(sgs.Damaged)) then
                    can = false
                    break
                end
            end
            if can then
                return target
            else
                for _,p in sgs.list(destlist)do
                    if self:isEnemy(p) then
                        return p
                    end
                end
            end
        end
    end
    return destlist[1]
end

ai_skill_invoke.yanjuxiang = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local to = data:toPlayer()
    return (to and self:isEnemy(to)) or false
end

ai_skill_invoke.yanhoufeng = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local to = data:toPlayer()
    return (canZhengsu(self,to)) or false
end

ai_skill_use["@@olyuheng!"] = function(self, prompt, request)
    local valid = {}
    local ids = {}
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local n = source_query(self.player, "getMark", "mouqingzhengSuits")
    for _,c in sgs.list(cards)do
        if table.contains(ids,c:getSuit()) then continue end
        table.insert(valid,c:getKnownEffectiveId())
        table.insert(ids,c:getSuit())
    end
    if #valid<1 then return end
    return "#olyuhengCard:"..table.concat(valid,"+")..":"
end

ai_skill_choice.oldili = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local n = data:toInt()
    if n>=3 then
        return ai_choice_result((items[#items]), options)
    end
    return ai_choice_result((items[2]), options)
end

ai_skill_invoke.zhaoluan = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local to = data:toPlayer()
    return (not self:isEnemy(to)
    or #self.friends/2>=#self.enemies) or false
end

ai_fill_skill.zhaoluan = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#zhaoluanCard:.:")
end

ai_card_use["#zhaoluanCard"] = function(self, card, use, request)
    self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
        if source_query(p, "getMark", "zhaoluanDamage"..self.player:objectName())<1 and self:isWeak()
        and source_query(self, "damageIsEffective", p, nil, self.player) then
            use.card = card
            use.to:append(p)
            break
        end
    end
end

sgs.ai_use_value.zhaoluanCard = 4.5
sgs.ai_use_priority.zhaoluanCard = 1.7

sgs.ai_skill_cardask.mobilejingxie = function(self,data,pattern,prompt)
    return true
end

local jx_equip = {"crossbow","eight_diagram","renwang_shield","silver_lion","vine"}

ai_fill_skill.mobilejingxie = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards,true)
    for _,c in sgs.list(cards)do
        if table.contains(jx_equip,c:objectName())
        and not self.player:getStrategyFlag("jx_equip"..c:objectName()) and use_card(self,c).card then
            set_state(self,"jx_equip_name",c:objectName())
            return parse_action(self,"#mobilejingxieCard:"..c:getKnownId()..":")
        end
    end
end

ai_card_use["#mobilejingxieCard"] = function(self, card, use, request)
    strategy_flag(self,self.player,"jx_equip"..get_state(self,"jx_equip_name"))
    use.card = card
end

sgs.ai_use_value.mobilejingxieCard = 4.5
sgs.ai_use_priority.mobilejingxieCard = 7.7

ai_fill_skill.mobileqiaosi = function(self, options, request)
    local inclusive = options and options.inclusive

    self:setPriorityValue("mobileqiaosiCard",8-self.player:getHandcardNum(),"newgenerals")
    return parse_action(self,"#mobileqiaosiCard:.:")
end

ai_card_use["#mobileqiaosiCard"] = function(self, card, use, request)
    use.card = card
end

sgs.ai_use_value.mobileqiaosiCard = 4.5
sgs.ai_use_priority.mobileqiaosiCard = 8.7

ai_skill_choice.qs_shuizhuan = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    for _,t in sgs.list(table.copyFrom(items))do
        if string.find(t,"100") then table.removeOne(items,t) end
    end
    if #items>0 then
        for _,t in sgs.list(items)do
            if string.find(t,"qs_wang") or string.find(t,"qs_wang")
            then return ai_choice_result((t), options) end
        end
        for _,t in sgs.list(items)do
            if string.find(t,"qs_shang") or string.find(t,"qs_shi")
            then return ai_choice_result((t), options) end
        end
        return ai_choice_result((items[math.random(1,#items)]), options)
    end

    return ai_choice_result(nil, options)
end

ai_skill_use["@@mobileqiaosi!"] = function(self, prompt, request)
    local valid = {}
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local n = source_query(self.player, "getMark", "mobileqiaosiNum")
    for _,c in sgs.list(cards)do
        if #valid>=n or use_card(self,c).card then continue end
        table.insert(valid,c:getKnownEffectiveId())
    end
    for _,c in sgs.list(cards)do
        if #valid>=n or table.contains(valid,c:getKnownEffectiveId()) then continue end
        table.insert(valid,c:getKnownEffectiveId())
    end
    if #valid<1 then return end
    self:sort(self.friends_noself)
    for _,p in sgs.list(self.friends_noself)do
        return "#mobileqiaosi2Card:"..table.concat(valid,"+")..":->"..p:objectName()
    end
    for _,c in sgs.list(cards)do
        if #valid>=n or use_card(self,c).card or source_query(self.player, "isJilei", c) then continue end
        table.insert(valid,c:getKnownEffectiveId())
    end
    for _,c in sgs.list(cards)do
        if #valid>=n or table.contains(valid,c:getKnownEffectiveId()) or source_query(self.player, "isJilei", c) then continue end
        table.insert(valid,c:getKnownEffectiveId())
    end
    if #valid<1 then return end
    return "#mobileqiaosi2Card:"..table.concat(valid,"+")..":"
end

sgs.ai_skill_playerchosen.keoljianxuan = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    for _,p in sgs.list(destlist)do
        if self:isFriend(p) then
            local h = p:getHandcardNum()+1
            if h==2+source_query(self.player, "getMark", "&keolgangshu_mp")
            or h==source_query(self.player, "getAttackRange")
            or h==1+source_query(preview(self), "getTargetModResidue", self.player)
            then return p end
        end
    end
    for _,p in sgs.list(destlist)do
        if self:isFriend(p) then
            local h = p:getHandcardNum()
            if h<2+source_query(self.player, "getMark", "&keolgangshu_mp")
            or h<source_query(self.player, "getAttackRange")
            or h<1+source_query(preview(self), "getTargetModResidue", self.player)
            then return p end
        end
    end
    for _,p in sgs.list(destlist)do
        if self:isFriend(p) then
            return p
        end
    end
end

ai_fill_skill.mobiledamingvs = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#mobiledamingCard:.:")
end

ai_card_use["#mobiledamingCard"] = function(self, card, use, request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    if #cards<1 then return end
    self:sortByKeepValue(cards)
    for _,p in sgs.list(self.friends_noself)do
        if p:hasSkill("mobiledaming")
        and source_query(self.player, "getMark", p:objectName().."mobiledamingUse-PlayClear")<1
        then
            use.card = parse_action(self,"#mobiledamingCard:"..cards[1]:getId()..":")
            use.to:append(p)
            return
        end
    end
    cards = self:poisonCards(cards)
    if #cards<1 then return end
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
        if p:hasSkill("mobiledaming")
        and source_query(self.player, "getMark", p:objectName().."mobiledamingUse-PlayClear")<1
        then
            use.card = parse_action(self,"#mobiledamingCard:"..cards[1]:getId()..":")
            use.to:append(p)
            return
        end
    end
end

sgs.ai_use_value.mobiledamingCard = 4.5
sgs.ai_use_priority.mobiledamingCard = 6.7

ai_fill_skill.mobilexiaoni = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    if #cards<1 then return end
    self:sortByKeepValue(cards)
    for _,pn in sgs.list(pattern_names(self))do
        local dc = preview(self,pn)
        if dc and source_query(dc, "isDamageCard") and self:getCardsNum(dc:getClassName())<1
        and not dc:isKindOf("DelayedTrick") then
            mutate(self,dc,"skill","mobilexiaoni")
            for _,c in sgs.list(cards)do
                mutate(self,dc,"add",c)
                if source_query(dc, "isAvailable", self.player) then
                    local d = use_card(self,dc)
                    if d.card then return dc end
                end
                mutate(self,dc,"clear")
            end
        end
    end
end

sgs.ai_skill_playerchosen.jiebing = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,nil,true)
    for _,p in sgs.list(destlist)do
        if self:isEnemy(p) and source_query(p, "getCardCount")>0 then
            return p
        end
    end
    for _,p in sgs.list(destlist)do
        if source_query(p, "getCardCount")>0 then
            return p
        end
    end
end

ai_fill_skill.hannan = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#hannanCard:.:")
end

ai_card_use["#hannanCard"] = function(self, card, use, request)
    local mc = self:getMaxCard()
    if not mc or mc:getNumber()<11 then return end
    set_state(self,"hannan_card",mc)
    self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
        if source_query(self.player, "canPindian", p) then
            use.card = card
            use.to:append(p)
            return
        end
    end
end

sgs.ai_use_value.hannanCard = 4.5
sgs.ai_use_priority.hannanCard = 2.7

ai_fill_skill.keolsaogu = function(self, options, request)
    local inclusive = options and options.inclusive

    if source_query(self.player, "getChangeSkillState", "keolsaogu") == 1 then
        local cards = self.player:getCards("he")
        cards = self:sortByKeepValue(cards,nil,"jl")
        if #cards<1 then return end
        local ids = {}
        for _,c in sgs.list(cards)do
            if #ids<2 and c:isKindOf("Slash") and source_query(self.player, "getMark", c:getSuitString().."keolsaoguSuit-PlayClear")<1 then
                if self.player:getStrategyHasUsed("Slash") then
                    table.insert(ids,c:getKnownEffectiveId())
                end
            end
        end
        for _,c in sgs.list(cards)do
            if #ids==1 and source_query(self.player, "getMark", c:getSuitString().."keolsaoguSuit-PlayClear")<1
            and c:getKnownEffectiveId()~=ids[1] then
                table.insert(ids,c:getKnownEffectiveId())
            end
        end
        for _,c in sgs.list(cards)do
            if #ids<1 and source_query(self.player, "getMark", c:getSuitString().."keolsaoguSuit-PlayClear")<1
            and #cards>3 then
                table.insert(ids,c:getKnownEffectiveId())
            end
        end
        if #ids<2 then return end
        self:setPriorityValue("keolsaoguCard",1.7,"newgenerals")
        return parse_action(self,"#keolsaoguCard:"..table.concat(ids,"+")..":")
    else
        self:setPriorityValue("keolsaoguCard",7.7,"newgenerals")
        return parse_action(self,"#keolsaoguCard:.:")
    end
end

ai_card_use["#keolsaoguCard"] = function(self, card, use, request)
    use.card = card
end

sgs.ai_use_value.keolsaoguCard = 4.5
sgs.ai_use_priority.keolsaoguCard = 1.7

ai_skill_use["@@keolsaogu"] = function(self, prompt, request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards,nil,"j")
    if #cards<2 then return end
    if source_query(self.player, "getChangeSkillState", "keolsaogu") == 1 then
        self:sort(self.friends_noself,nil,true)
        for _,p in sgs.list(self.friends_noself)do
            if source_query(p, "getCardCount")>2 and (getCardsNum("Slash",p,self.player)>0 or #self:poisonCards("e",p)>0) then
                return "#keolsaogu2Card:"..cards[1]:getId()..":->"..p:objectName()
            end
        end
        self:sort(self.enemies)
        for _,p in sgs.list(self.enemies)do
            if source_query(p, "getCardCount")>0 and getCardsNum("Slash",p,self.player)<1 and #self:poisonCards("e",p)<1 then
                return "#keolsaogu2Card:"..cards[1]:getId()..":->"..p:objectName()
            end
        end
    else
        self:sort(self.friends_noself)
        for _,p in sgs.list(self.friends_noself)do
            return "#keolsaogu2Card:"..cards[1]:getId()..":->"..p:objectName()
        end
    end
end

ai_skill_use["@@keolsaoguslash"] = function(self, prompt, request)
    local ids = scope_list(self,"keolsaoguslashForAI")
    for _,id in sgs.list(ids)do
        local c = known_card(self,id)
        if c:isKindOf("Slash") and not source_query(self.player, "isLocked", c) then
            local d = use_card(self,c)
            if d.card then
                local tos = {}
                for _,p in sgs.list(d.to)do
                    table.insert(tos,p:objectName())
                end
                return r45_selected_borrowed(self,c,d.to,tos)
            end
        end
    end
end

sgs.ai_skill_discard.keolsaogu = function(self,x,n)
    local to_cards = {}
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards,nil,"j")
    for _,c in sgs.list(cards)do
        if #to_cards>=n or source_query(self.player, "getMark", c:getSuitString().."keolsaoguSuit-PlayClear")>0 then continue end
        if c:isKindOf("Slash") and use_card(self,c).card then
            table.insert(to_cards,c:getKnownEffectiveId())
        end
    end
    for _,c in sgs.list(cards)do
        if #to_cards>=n or table.contains(to_cards,c:getKnownEffectiveId()) then continue end
        if source_query(self.player, "getMark", c:getSuitString().."keolsaoguSuit-PlayClear")>0 then continue end
        table.insert(to_cards,c:getKnownEffectiveId())
    end
    return to_cards
end

ai_fill_skill.olxiaofan = function(self, options, request)
    local inclusive = options and options.inclusive

    local n = 1
    for _,m in sgs.list(self.player:getMarkNames())do
        if m:startsWith("&olxiaofan+:+") and source_query(self.player, "getMark", m)>0 then
            n = n+#m:split("+")-2
            break
        end
    end
    if n<4 or self.player:getHandcardNum()<2 and source_query(self, "getPriorTurnUseCount")<2 then
        if self.player:usedTimes("#olxiaofan0Card")<1 then
            return parse_action(self,"#olxiaofan0Card:.:")
        end
        local pattern = property_value(self,self.player,"olxiaofanPattern")
        if pattern~="" or source_query(self, "getPriorTurnUseCount")>1 then
            for _,id in sgs.list(pattern:split("+"))do
                local c = known_card(self,id)
                local d = use_card(self,c)
                if d.card then
                    if source_query(c, "canRecast") and d.to:isEmpty() then continue end
                    return parse_action(self,"#olxiaofan0Card:.:")
                end
            end
        end
    end
end

ai_card_use["#olxiaofan0Card"] = function(self, card, use, request)
    use.card = card
end

sgs.ai_use_value.olxiaofan0Card = 4.5
sgs.ai_use_priority.olxiaofan0Card = 9.7

ai_skill_use["@@olxiaofan1"] = function(self, prompt, request)
    local pattern = property_value(self,self.player,"olxiaofanPattern")
    local cs = {}
    for _,id in sgs.list(pattern:split("+"))do
        table.insert(cs,known_card(self,id))
    end
    self:sortByDynamicUsePriority(cs)
    for _,c in sgs.list(cs)do
        local d = use_card(self,c)
        if d.card then
            if source_query(c, "canRecast") and d.to:isEmpty() then continue end
            local tos = {}
            for _,p in sgs.list(d.to)do
                table.insert(tos,p:objectName())
            end
            return c:toString().."->"..table.concat(tos,"+")
        end
    end
end

sgs.ai_guhuo_card.olxiaofan = function(self,toname,class_name)
    if source_query(self.player, "getMark", "olxiaofanFailed-"..self.player:getPhase().."Clear")>0 then return end
    local n = 1
    for _,m in sgs.list(self.player:getMarkNames())do
        if m:startsWith("&olxiaofan+:+") and source_query(self.player, "getMark", m)>0 then
            n = n+#m:split("+")-2
            break
        end
    end
    if n<4 or self.player:getHandcardNum()<2 and self:getCardsNum(class_name)<2 then
        add_failure_mark(self,"olxiaofanFailed-"..self.player:getPhase().."Clear")
        return "#olxiaofanCard:.:"..toname
    end
end

ai_skill_use["@@olxiaofan2"] = function(self, prompt, request)
    local cs = {}
    for _,id in sgs.list(scope_list(self,"olxiaofanForAI"))do
        table.insert(cs,known_card(self,id))
    end
    local pattern = scope(self,"olxiaofanPattern")
    for _,c in sgs.list(cs)do
        for _,pn in sgs.list(pattern:split("+"))do
            if source_query(c, "sameNameWith", pn) and not source_query(self.player, "isLocked", c) then
                return "#olxiaofan0Card:"..c:getKnownId()..":@@olxiaofan2"
            end
        end
    end
end

ai_skill_invoke.keoldulie = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local use = data:toCardUse()
    if source_query(use.card, "isDamageCard") then
        return (source_query(self.player, "getAttackRange")>1 and not self:isWeak()) or false
    elseif self:isFriend(use.from) then
        return (source_query(self.player, "getAttackRange")>0) or false
    end
    return (source_query(self.player, "getAttackRange")>1) or false
end

ai_fill_skill.keolweilin = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = r45_handpile(self,"he")
    cards = sgs.QList2Table(cards)
    if #cards<1 then return end
    self:sortByKeepValue(cards)
    for _,pn in sgs.list(pattern_names(self))do
        local dc = preview(self,pn)
        if dc and (dc:isKindOf("Analeptic") or dc:isKindOf("Slash"))
        and self:getCardsNum(dc:getClassName())<1 then
            mutate(self,dc,"skill","keolweilin")
            for _,c in sgs.list(cards)do
                mutate(self,dc,"add",c)
                if source_query(dc, "isAvailable", self.player) then
                    local d = use_card(self,dc)
                    if d.card then return dc end
                end
                mutate(self,dc,"clear")
            end
        end
    end
end

function sgs.ai_cardsview.keolweilin(self,class_name,player)
    local cards = r45_handpile(self,"he")
    cards = sgs.QList2Table(cards)
    if #cards<1 then return end
    self:sortByKeepValue(cards)
    local dc = preview(self,class_name)
    mutate(self,dc,"skill","keolweilin")
    for i,c in sgs.list(cards)do
        mutate(self,dc,"add",c)
        if not source_query(player, "isLocked", dc)
        then return dc:toString() end
        mutate(self,dc,"clear")
    end
end

sgs.ai_card_priority.keolweilin = function(self,card,v)
    if table.contains(source_query(card, "getSkillNames"), "keolweilin") then
        return 0.5
    end
end

sgs.ai_skill_cardask["juqi0"] = function(self,data,pattern,prompt)
    local to = data:toPlayer()
    if self:isFriend(to) then
        local n = source_query(to, "getChangeSkillState", "juqi")
        if n==1 then return true end
    elseif self:isEnemy(to) then
        local n = source_query(to, "getChangeSkillState", "juqi")
        if n==2 and source_query(to, "inMyAttackRange", self.player) and self:isWeak() then return true end
    end
end

sgs.ai_skill_playerchosen.fengtu = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,nil,true)
    for _,p in sgs.list(destlist)do
        if self:isFriend(p) then
            return p
        end
    end
end

ai_skill_invoke.taishi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local cp = self.room:getCurrent()
    return (not self:isFriend(cp)) or false
end

ai_skill_choice.xdtiantong = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    if not self.player:faceUp() then
        return ai_choice_result((items[1]), options)
    end

    return ai_choice_result(nil, options)
end

ai_fill_skill.xdyifuvs = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("h")
    cards = self:sortByKeepValue(cards)
    for _,c in sgs.list(cards)do
        if c:getTypeId()==1 then
            for _,p in sgs.list(self.room:getAllPlayers())do
                if p:hasSkill("xdyifu") then
                    local n = source_query(p, "getChangeSkillState", "xdyifu")
                    local choice = ""
                    if n==1 then choice = "lightning"
                    elseif n==2 then choice = property_value(self,self.player,"Suijiyingbian")
                    elseif n==3 then choice = "iron_chain" end
                    local dc = preview(self,choice,"_xdyifu")
                    if dc then
                        mutate(self,dc,"add",c)
                        mutate(self,dc,"recast",false)
                        if source_query(dc, "isAvailable", self.player) then
                            local d = use_card(self,dc)
                            if d.card then
                                set_state(self,"xdyifuvsTo",p)
                                set_state(self,"xdyifuvsUse",d)
                                return parse_action(self,"#xdyifucard:"..c:getKnownId()..":"..choice)
                            end
                        end
                    end
                end
            end
        end
    end
end

ai_card_use["#xdyifucard"] = function(self, card, use, request)
    if get_state(self,"xdyifuvsTo") then
        use.card = card
        use.to:append(get_state(self,"xdyifuvsTo"))
    end
end

sgs.ai_use_value.xdyifucard = 4.5
sgs.ai_use_priority.xdyifucard = 2.7

ai_skill_use["@@xdyifuvs"] = function(self, prompt, request)
    local d = get_state(self,"xdyifuvsUse")
    if d.card then
        local tos = {}
        for _,p in sgs.list(d.to)do
            table.insert(tos,p:objectName())
        end
        return d.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_playerchosen.xdtianjie = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    for _,p in sgs.list(destlist)do
        if self:isEnemy(p) and source_query(self, "damageIsEffective", p, "T") then
            return p
        end
    end
    for _,p in sgs.list(destlist)do
        if not self:isFriend(p) then
            return p
        end
    end
end

-- Only the actually chosen readonly product binds a new response receipt.
-- Recast(false) is a source planning mutation; it is not serialized in the
-- donor wire or copied onto the separately native-produced selected card.
local function r48_xdfangchan_wire(self,card)
    if source_query(card, 'isEvaluationOnly') and card:getKnownSkillName(false)=='_xdfangchan' then
        local selected=source_query(self, 'bindOriginalSelectedConversion', {
            name=card:objectName(),skill='_xdfangchan',suit=card:getSuit(),
            number=card:getNumber(),subcards=sgs.QList2Table(card:getSubcards())}, card:getClassName(), 'xdfangchan')
        return source_query(selected, 'toString')
    end
    return source_query(card, 'toString')
end

ai_skill_use["@@xdfangchan"] = function(self, prompt, request)
    local n = source_query(self.player, "getMark", "xdfangchanId")
    local dc = preview(self,known_card(self,n):objectName())
    mutate(self,dc,"skill","_xdfangchan")
    mutate(self,dc,"recast",false)
    local d = use_card(self,dc)
    if d.card then
        local tos = {}
        for _,p in sgs.list(d.to)do
            table.insert(tos,p:objectName())
        end
        return r48_xdfangchan_wire(self,d.card).."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_playerschosen._wuqibingfa = function(self,players,x,n)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,nil,true)
    local tos = {}
    for _,p in sgs.list(destlist)do
        if #tos<x and self:isFriend(p) and source_query(p, "getCardCount")>0 then
            for _,q in sgs.list(self.enemies)do
                if source_query(p, "canSlash", q) then
                    table.insert(tos,p)
                    break
                end
            end
        end
    end
    for _,p in sgs.list(destlist)do
        if #tos<x and not table.contains(tos,p) and not self:isEnemy(p) and source_query(p, "getCardCount")>0 then
            for _,q in sgs.list(self.enemies)do
                if source_query(p, "canSlash", q) then
                    table.insert(tos,p)
                    break
                end
            end
        end
    end
    return tos
end

ai_skill_use["@@_wuqibingfa!"] = function(self, prompt, request)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards)
    for _,c in sgs.list(cards)do
        local dc = preview(self)
        mutate(self,dc,"skill","_wuqibingfa")
        mutate(self,dc,"add",c)
        if source_query(dc, "isAvailable", self.player) then
            local d = use_card(self,dc)
            if d.card then
                local tos = {}
                for _,p in sgs.list(d.to)do
                    table.insert(tos,p:objectName())
                end
                return d.card:toString().."->"..table.concat(tos,"+")
            end
        end
    end
    for _,c in sgs.list(cards)do
        local dc = preview(self)
        mutate(self,dc,"skill","_wuqibingfa")
        mutate(self,dc,"add",c)
        if source_query(dc, "isAvailable", self.player) then
            for _,p in sgs.list(self.enemies)do
                if source_query(self.player, "canSlash", p, dc) then
                    return dc:toString().."->"..p:objectName()
                end
            end
            for _,p in sgs.list(self.room:getAllPlayers())do
                if source_query(self.player, "canSlash", p, dc) and not self:isFriend(p) then
                    return dc:toString().."->"..p:objectName()
                end
            end
            for _,p in sgs.list(self.room:getAllPlayers())do
                if source_query(self.player, "canSlash", p, dc) then
                    return dc:toString().."->"..p:objectName()
                end
            end
        end
    end
end

ai_skill_invoke.xdfenbo = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (self:isWeak() or #self.friends<=#self.enemies/2) or false
end

ai_fill_skill.xiongsuan = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards)
    for _,c in sgs.list(cards)do
        return parse_action(self,"#xiongsuanCard:"..c:getKnownId()..":")
    end
end

ai_card_use["#xiongsuanCard"] = function(self, card, use, request)
    self:sort(self.friends,nil,true)
    for _,p in sgs.list(self.friends)do
        for _,s in sgs.qlist(p:getVisibleSkillList()) do
            if source_query(s, "getFrequency", p) == sgs.Skill_Limited and source_query(p, "getMark", source_query(s, "getLimitMark"))<1 then
                use.to:append(p)
                use.card = card
                return
            end
        end
    end
    self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
        if p:getHp()<2 and source_query(self, "damageIsEffective", p) then
            use.card = card
            use.to:append(p)
            return
        end
    end
    if not self:isWeak() then
        use.card = card
        use.to:append(self.player)
    end
end

sgs.ai_use_value.xiongsuanCard = 4.5
sgs.ai_use_priority.xiongsuanCard = 7.7

ai_skill_choice.xiongsuan = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    local p = data:toPlayer()
    if self:isFriend(p) then
        local skills = {}
        for _,s in sgs.qlist(p:getVisibleSkillList()) do
            if table.contains(items,s:objectName()) and source_query(p, "getMark", source_query(s, "getLimitMark"))<1 then
                table.insert(skills,s:objectName())
            end
        end
        if table.contains(items,"luanwu") then
            return ai_choice_result(("luanwu"), options)
        end
        if table.contains(items,"fencheng") then
            return ai_choice_result(("fencheng"), options)
        end
        if table.contains(items,"xingshuai") and self:isWeak() then
            for _,p in sgs.list(self.friends_noself) do
                if p:getKnownKingdom()=="wei" then
                    return ai_choice_result(("xingshuai"), options)
                end
            end
        end
        if table.contains(items,"xdfenbo") and self:isWeak(self.enemies) then
            return ai_choice_result(("xdfenbo"), options)
        end
        if table.contains(items,"xiongsuan") then
            return ai_choice_result(("xiongsuan"), options)
        end
        return ai_choice_result((items[1]), options)
    else
        return ai_choice_result((items[#items]), options)
    end

    return ai_choice_result(nil, options)
end

ai_skill_invoke._eight_diagram = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (ai_skill_invoke.eight_diagram(self, options, request)) or false
end

sgs.ai_skill_cardask["mobilejingxie0"] = function(self,data,pattern,prompt)
    return true
end

ai_fill_skill.olmoguofu = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self:addHandPile("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local pns = property_value(self,self.player,"olmoguofuPns"):split("+")
    for _,c in sgs.list(cards)do
        if source_query(c, "hasTip", "olmoguofu") then
            for _,pn in sgs.list(RandomList(pns))do
                if source_query(self.player, "getMark", pn.."olmoguofuBan-Clear")>0 then continue end
                local dc = preview(self,pn)
                if dc and self:getCardsNum(dc:getClassName())<1 then
                    mutate(self,dc,"skill","olmoguofu")
                    mutate(self,dc,"add",c)
                    mutate(self,dc,"recast",false)
                    if source_query(dc, "isAvailable", self.player) and use_card(self,dc).card
                    then return dc end
                end
            end
        end
    end
end

function sgs.ai_cardsview.olmoguofu(self,class_name,player)
    local cards = self:addHandPile("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _,c in sgs.list(cards)do
        if source_query(c, "hasTip", "olmoguofu") then
            local dc = preview(self,class_name)
            if source_query(player, "getMark", dc:objectName().."olmoguofuBan-Clear")>0 then continue end
            mutate(self,dc,"skill","olmoguofu")
            mutate(self,dc,"add",c)
            return dc:toString()
        end
    end
end

ai_skill_invoke.olmomoubian = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (not self:isWeak()) or false
end

ai_skill_invoke.olmozhouxi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local stp = data:toString():split(":")
    local tp = BeMan(self.room,stp[2])
    return (tp and self:isEnemy(tp)) or false
end

ai_skill_use["ol_shengsiyugong0"] = function(self, prompt, request)
    local method = request and request.handling_method
    local pattern = request and request.pattern
    local dy = scoped_struct(self,"ol_shengsiyugongData","dying")
    if self:isFriend(dy.who) and source_query(self, "getAllPeachNum")<1 then
        for _,h in sgs.list(self:getCard("Shengsiyugong",true))do
            return h:toString()
        end
    end
end

ai_skill_use["ol_luojingxiashi0"] = function(self, prompt, request)
    local method = request and request.handling_method
    local pattern = request and request.pattern
    local dy = scoped_struct(self,"ol_luojingxiashiData","dying")
    if self:isEnemy(dy.who) then
        for _,h in sgs.list(self:getCard("Luojingxiashi",true))do
            return h:toString()
        end
    end
end

sgs.ai_nullification.Luojingxiashi = function(self,trick,from,to,positive,null_num)
    if positive
    then
        if self:isFriend(to) and source_query(self, "getAllPeachNum") > 0
        then return true end
    else

    end
end

function SmartAIView:useCardHongyundangtou(card,use)
    local recommend = self:targetRecommendScorer(card)
    self:sort(self.friends_noself,nil,true)
    for _,p in sgs.list(self:orderTargetsByRecommend(self.friends_noself, recommend))do
        if isCurrent(use,p) then continue end
        if source_query(self, "doDisCard", p, "he") and self:canDraw(p) and target_ok(card,self.player,p,use.to) then
            use.to:append(p)
            use.card = card
        end
    end
    for _,p in sgs.list(self:orderTargetsByRecommend(self.friends_noself, recommend))do
        if isCurrent(use,p) or use.to:contains(p) then continue end
        if source_query(p, "canDiscard", p, "he") and self:canDraw(p) and target_ok(card,self.player,p,use.to) then
            use.to:append(p)
            use.card = card
        end
    end
end
sgs.registerSkillCardType("Hongyundangtou", "draw")
sgs.registerSkillCardType("Hongyundangtou", "decrease")
sgs.ai_use_priority.Hongyundangtou = 8.4
sgs.ai_keep_value.Hongyundangtou = 4
sgs.ai_use_value.Hongyundangtou = 7.7
sgs.ai_nullification.Hongyundangtou = function(self,trick,from,to,positive)
    return self:isEnemy(to)
    and to:getHandcardNum()<3
    and positive
end

sgs.ai_card_intention.Hongyundangtou = -66

sgs.ai_skill_discard.ol_hongyundangtou = function(self,x,n)
    local to_cards = {}
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards,nil,"j")
    for i,c in sgs.list(cards)do
        if #to_cards>=x or self:wasPreviouslyPlannedCard(c) or i>#cards/2 then continue end
        table.insert(to_cards,c:getKnownId())
    end
    return to_cards
end

function SmartAIView:useCardYounantongdang(card,use)
    if #self.friends<=#self.enemies then
        use.card = card
    end
end
sgs.ai_use_priority.Younantongdang = 3.4
sgs.ai_keep_value.Younantongdang = 3
sgs.ai_use_value.Younantongdang = 3.7
sgs.ai_nullification.Younantongdang = function(self,trick,from,to,positive)
    return sgs.ai_nullification.IronChain(self,trick,from,to,positive)
end

function SmartAIView:useCardLeigongzhuwo(card,use)
    if #self.friends<=#self.enemies then
        use.card = card
    end
end
sgs.ai_use_priority.Leigongzhuwo = 3.4
sgs.ai_keep_value.Leigongzhuwo = 3
sgs.ai_use_value.Leigongzhuwo = 1.7


function SmartAIView:useCardLiangleichadao(card,use)
    local recommend = self:targetRecommendScorer(card)
    self:sort(self.friends_noself,nil,true)
    for _,p in sgs.list(self:orderTargetsByRecommend(self.friends_noself, recommend))do
        if isCurrent(use,p) then continue end
        if self:canDraw(p) and target_ok(card,self.player,p,use.to) then
            use.to:append(p)
            use.card = card
        end
    end
    for _,p in sgs.list(self:orderTargetsByRecommend(self.friends_noself, recommend))do
        if isCurrent(use,p) or use.to:contains(p) then continue end
        if self:canDraw(p) and target_ok(card,self.player,p,use.to) then
            use.to:append(p)
            use.card = card
        end
    end
end
sgs.registerSkillCardType("Liangleichadao", "draw")
sgs.ai_use_priority.Liangleichadao = 8.4
sgs.ai_keep_value.Liangleichadao = 4
sgs.ai_use_value.Liangleichadao = 0.7
sgs.ai_nullification.Liangleichadao = function(self,trick,from,to,positive)
    return self:isEnemy(to) and positive
    and to:getHandcardNum()<3
end

sgs.ai_card_intention.Liangleichadao = -66

function SmartAIView:useCardXiongdiqixin(card,use)
    local recommend = self:targetRecommendScorer(card)
    self:sort(self.friends_noself,nil,true)
    for _,p in sgs.list(self:orderTargetsByRecommend(self.friends_noself, recommend))do
        if isCurrent(use,p) then continue end
        if self:canDraw(p) and target_ok(card,self.player,p,use.to) then
            use.to:append(p)
            use.card = card
        end
    end
    for _,p in sgs.list(self:orderTargetsByRecommend(self.friends_noself, recommend))do
        if isCurrent(use,p) or use.to:contains(p) then continue end
        if self:canDraw(p) and target_ok(card,self.player,p,use.to) then
            use.to:append(p)
            use.card = card
        end
    end
end
sgs.registerSkillCardType("Xiongdiqixin", "draw")
sgs.ai_use_priority.Xiongdiqixin = 8.4
sgs.ai_keep_value.Xiongdiqixin = 4
sgs.ai_use_value.Xiongdiqixin = 9.7
sgs.ai_nullification.Xiongdiqixin = function(self,trick,from,to,positive)
    return self:isEnemy(to) and positive and self:isWeak(to)
    and to:getHandcardNum()+from:getHandcardNum()>5
end

sgs.ai_card_intention.Xiongdiqixin = -66

ai_skill_use["@@ol_xiongdiqixin!"] = function(self, prompt, request)
    local cs = {}
    for _,id in sgs.list(scope_list(self,"ol_xiongdiqixinForAI"))do
        table.insert(cs,known_card(self,id))
    end
    for _,c in sgs.list(self.player:getHandcards())do
        table.insert(cs,c)
    end
    local ids = {}
    self:sortByKeepValue(cs)
    for i,c in sgs.list(cs)do
        if i%2==1 then table.insert(ids,source_query(c, "getLegacyStringKey")) end
    end
    return "#ol_xiongdiqixinCard:"..table.concat(ids,"+")..":"
end

function SmartAIView:useCardQianjiu(card,use)
    if #self.friends<=#self.enemies then
        use.card = card
    end
end
sgs.ai_use_priority.Qianjiu = 3.4
sgs.ai_keep_value.Qianjiu = 3
sgs.ai_use_value.Qianjiu = 3.7
sgs.ai_nullification.Qianjiu = function(self,trick,from,to,positive)
    return positive and (to==self.player or self:isWeak(to) and self:isFriend(to))
end

ai_skill_use["@@ol_qianjiu0"] = function(self, prompt, request)
    local cs = {}
    for _,c in sgs.list(self.player:getCards("he"))do
        table.insert(cs,c)
    end
    self:sortByUseValue(cs)
    for _,c in sgs.list(cs)do
        if c:isKindOf("Analeptic") or c:getNumber()==9 then
            if source_query(c, "isAvailable", self.player) then
                local d = use_card(self,c)
                if d.card then
                    local tos = {}
                    for _,p in sgs.list(d.to)do
                        table.insert(tos,p:objectName())
                    end
                    return d.card:toString().."->"..table.concat(tos,"+")
                end
            end
        end
    end
end

function SmartAIView:useCardWutianwujie(card,use)
    use.card = card
end
sgs.ai_use_priority.Wutianwujie = 3.4
sgs.ai_keep_value.Wutianwujie = 3
sgs.ai_use_value.Wutianwujie = 8.7
sgs.ai_nullification.Wutianwujie = function(self,trick,from,to,positive)
    return sgs.ai_nullification.ExNihilo(self,trick,from,to,positive)
end

sgs.ai_card_intention.Wutianwujie = -66

ai_fill_skill.ofsifen = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#ofsifenCard:.:")
end

ai_card_use["#ofsifenCard"] = function(self, card, use, request)
    local n = source_query(self.player, "getMark", "ofsifenRed-PlayClear")
    if n>0 then
        local cards = r45_handpile(self,"he")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        local ids = {}
        local dc = preview(self,"duel","ofsifen")
        for _,c in sgs.list(cards)do
            if c:isRed() and #ids<n then
                table.insert(ids,c:toString())
                mutate(self,dc,"add",c)
            end
        end
        if #ids==n and source_query(dc, "isAvailable", self.player) then
            local btps = {}
            for _,p in sgs.list(self.room:getAllPlayers())do
                if source_query(self.player, "getMark", p:objectName().."ofsifenDuel-PlayClear")<1
                then table.insert(btps,p) end
            end
            local d = use_card(self,dc,dummy(true,0,btps))
            if d.card then
                use.to = d.to
                use.card = parse_action(self,"#ofsifenCard:"..table.concat(ids,"+")..":")
            end
        end
        return
    end
    self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
        if p:getHandcardNum()>0 then
            use.card = card
            use.to:append(p)
            return
        end
    end
end

sgs.ai_use_value.ofsifenCard = 4.5
sgs.ai_use_priority.ofsifenCard = 2.7

ai_skill_use["@@ofsifen!"] = function(self, prompt, request)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local dc = preview(self,"duel","_ofsifen")
    for _,c in sgs.list(cards)do
        mutate(self,dc,"add",c)
        if dc:subcardsLength()>=#cards/2 then
            if source_query(dc, "isAvailable", self.player) then
                local d = use_card(self,dc)
                if d.card then
                    local tos = {}
                    for _,p in sgs.list(d.to)do
                        table.insert(tos,p:objectName())
                    end
                    return dc:toString().."->"..table.concat(tos,"+")
                end
            end
            break
        end
    end
    for _,c in sgs.list(cards)do
        mutate(self,dc,"clear")
        mutate(self,dc,"add",c)
        if source_query(dc, "isAvailable", self.player) then
            local d = use_card(self,dc)
            if d.card then
                local tos = {}
                for _,p in sgs.list(d.to)do
                    table.insert(tos,p:objectName())
                end
                return dc:toString().."->"..table.concat(tos,"+")
            end
            for _,p in sgs.list(self.room:getAllPlayers())do
                if target_ok(dc,self.player,p) then
                    return dc:toString().."->"..p:objectName()
                end
            end
            break
        end
    end
end

ai_skill_invoke.offunan = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    for _,p in sgs.list(self.friends_noself)do
        if p:getKnownKingdom()=="shu" and getCardsNum("Slash",p,self.player)>0 then
            return (true) or false
        end
    end
    return (not self:isWeak()) or false
end

ai_fill_skill.offunan = function(self, options, request)
    local inclusive = options and options.inclusive

    return ai_skill_invoke.offunan(self, {}, nil)
    and parse_action(self,"#offunanCard:.:")
end

ai_card_use["#offunanCard"] = function(self, card, use, request)
    local dc = preview(self,"slash")
    if source_query(dc, "isAvailable", self.player) then
        for _,p in sgs.list(use_card(self,dc).to)do
            use.card = card
            use.to:append(p)
        end
    end
end

sgs.ai_use_value.offunanCard = 4.5
sgs.ai_use_priority.offunanCard = 2.7

function sgs.ai_cardsview.ofjunwei(self,class_name,player)
    local cards = r45_handpile(self,"he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for i,c in sgs.list(cards)do
        for n,a in sgs.list(cards)do
            if i<=n then continue end
            local dc = preview(self,"nullification")
            mutate(self,dc,"skill","ofjunwei")
            mutate(self,dc,"add",c)
            mutate(self,dc,"add",a)
            return dc:toString()
        end
    end
end

sgs.ai_skill_playerschosen.ofjunwei = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    local tps = {}
    for _,p in sgs.list(destlist)do
        if #tps<2 and self:isEnemy(p) then
            table.insert(tps,p)
        end
    end
    return tps
end

ai_skill_invoke.ofshezuo = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (not self:isWeak()) or false
end

ai_fill_skill.ofshezuo = function(self, options, request)
    local inclusive = options and options.inclusive

    return #self.enemies>0 and parse_action(self,"#ofshezuoCard:.:")
end

ai_card_use["#ofshezuoCard"] = function(self, card, use, request)
    use.card = card
end

sgs.ai_use_value.ofshezuoCard = 4.5
sgs.ai_use_priority.ofshezuoCard = 6.7

sgs.ai_skill_playerchosen.ofshezuo = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    for _,p in sgs.list(destlist)do
        if self:isEnemy(p) then
            return p
        end
    end
    for _,p in sgs.list(destlist)do
        if not self:isFriend(p) then
            return p
        end
    end
end

sgs.ai_skill_askforag.ofshezuo = function(self,card_ids)
    local cards = {}
    for _,id in sgs.list(card_ids)do
        table.insert(cards,known_card(self,id))
    end
    self:sortByKeepValue(cards,true)
    for _,c in sgs.list(cards)do
        local dc = preview(self,c:objectName())
        mutate(self,dc,"skill","_mourende")
        mutate(self,dc,"recast",false)
        if source_query(dc, "isAvailable", self.player) then
            local d = use_card(self,dc)
            if d.card then
                set_state(self,"ofshezuoUse",d)
                return c:getKnownId()
            end
        end
    end
end

ai_skill_use["@@ofshezuo!"] = function(self, prompt, request)
    local dummy = get_state(self,"ofshezuoUse")
    if dummy.card then
        local tos = {}
        for _,p in sgs.list(dummy.to)do
            table.insert(tos,p:objectName())
        end
        return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

ai_fill_skill.ofjixu = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#ofjixuCard:.:")
end

ai_card_use["#ofjixuCard"] = function(self, card, use, request)
    local tps = self:sort(self.room:getAllPlayers())
    for _,p in sgs.list(tps)do
        if source_query(p, "getMark", "ofjixuTo-PlayClear")<1 and use.to:length()<2
        and self:isFriend(p) and self:canDraw(p) then
            use.to:append(p)
        end
    end
    for _,p in sgs.list(tps)do
        if source_query(p, "getMark", "ofjixuTo-PlayClear")<1 and use.to:length()<2
        and not use.to:contains(p) and self:isFriend(p) then
            use.to:append(p)
        end
    end
    for _,p in sgs.list(tps)do
        if source_query(p, "getMark", "ofjixuTo-PlayClear")<1 and use.to:length()<2
        and not use.to:contains(p) and not self:isEnemy(p) then
            use.to:append(p)
        end
    end
    for _,p in sgs.list(tps)do
        if source_query(p, "getMark", "ofjixuTo-PlayClear")<1 and use.to:length()==1
        and not use.to:contains(p) then
            use.to:append(p)
        end
    end
    if use.to:length()==2 then
        use.card = card
    end
end

sgs.ai_use_value.ofjixuCard = 4.5
sgs.ai_use_priority.ofjixuCard = 7.7

ai_skill_use["@@ofjixu!"] = function(self, prompt, request)
    local cs = {}
    for _,id in sgs.list(scope_list(self,"ofjixuForAI"))do
        table.insert(cs,known_card(self,id))
    end
    local aps = {}
    for _,p in sgs.list(self.room:getAllPlayers())do
        if p:getStrategyFlag("ofjixuTo") then table.insert(aps,p) end
    end
    local ids = {}
    local tps = {}
    for i = 1,#cs do
        local c,p = self:getCardNeedPlayer(cs,nil,aps)
        if c and p then
            table.insert(ids,source_query(c, "getLegacyStringKey"))
            table.insert(tps,p:objectName())
            table.removeOne(cs,c)
            table.removeOne(aps,p)
            if #cs<1 or #aps<1 then break end
        end
    end
    self:sort(aps)
    for i,p in sgs.list(aps)do
        table.insert(tps,p:objectName())
    end
    self:sortByKeepValue(cs)
    for i,c in sgs.list(cs)do
        table.insert(ids,source_query(c, "getLegacyStringKey"))
    end
    return "#ofjixuCard:"..table.concat(ids,"+")..":->"..table.concat(tps,"+")
end

ai_fill_skill.ofyouchong = function(self, options, request)
    local inclusive = options and options.inclusive

    return #self.friends_noself>0
    and parse_action(self,"#ofyouchongCard:.:")
end

ai_card_use["#ofyouchongCard"] = function(self, card, use, request)
    for _,p in sgs.list(pattern_names(self))do
        local dc = preview(self,p)
        if dc and dc:getTypeId()==1 and source_query(dc, "isAvailable", self.player) then
            local d = use_card(self,dc)
            if d.card then
                use.card = parse_action(self,"#ofyouchongCard:.:"..p)
                use.to = d.to
                break
            end
        end
    end
end

sgs.ai_use_value.ofyouchongCard = 4.5
sgs.ai_use_priority.ofyouchongCard = 7.7

sgs.ai_skill_playerschosen.ofyouchong = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    local tps = {}
    for _,p in sgs.list(destlist)do
        if not self:isEnemy(p) then
            table.insert(tps,p)
        end
    end
    return tps
end


sgs.ai_skill_cardask["@@ofyouchong"] = function(self,data)
    local tp = data:toPlayer()
    if self:isEnemy(tp) or #self.enemies<1 then return "." end
    local cn = property_value(self,self.player,"ofyouchongCN")
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards)
    local dc = preview(self,cn,"_ofyouchong")
    for _,h in sgs.list(cards)do
        mutate(self,dc,"add",h)
        if dc:subcardsLength()>2
        then return dc:toString() end
    end
    return "."
end

ai_fill_skill.jiechu = function(self, options, request)
    local inclusive = options and options.inclusive

    return preview(self,"snatch","jiechu")
end

sgs.ai_skill_cardask["jiechu1"] = function(self,data)
    local use = data:toCardUse()
    if source_query(self.player, "getMark", use.card:getSuitString().."daojueSuit")<1 then return "." end
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards)
    for _,h in sgs.list(cards)do
        return dc:toString()
    end
    return "."
end

ai_skill_invoke.tuonan = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (self:getCardsNum("Peach,Analeptic")+self.player:getHp()<1) or false
end

sgs.ai_skill_playerchosen.yingzhen = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    for _,p in sgs.list(destlist)do
        if self:isFriend(p) then
            return p
        end
    end
    for _,p in sgs.list(destlist)do
        if not self:isEnemy(p) then
            return p
        end
    end
end

ai_skill_invoke.yuanjue = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (self:getOverflow()>0) or false
end

ai_skill_invoke.aoyong = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (self:canDraw() or self.player:isWounded()) or false
end

ai_skill_choice.aoyong = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    if table.contains(items,"aoyong2") and self:isWeak() then
        return ai_choice_result(("aoyong2"), options)
    end
    if table.contains(items,"aoyong3") then
        for _,c in sgs.list(self.player:getHandcards())do
            if use_card(self,c) then
                return ai_choice_result(("aoyong3"), options)
            end
        end
    end
    if table.contains(items,"aoyong2") then
        return ai_choice_result(("aoyong2"), options)
    end
    if table.contains(items,"aoyong1") then
        return ai_choice_result(("aoyong1"), options)
    end

    return ai_choice_result(nil, options)
end

ai_skill_invoke.tongkai = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local to = data:toPlayer()
    return (not self:isEnemy(to)) or false
end

ai_skill_invoke.dianmo = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (self:canDraw() or self.player:isWounded()) or false
end

ai_fill_skill.zaibi = function(self, options, request)
    local inclusive = options and options.inclusive

    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards)
    while #cards>0 do
        local cs = {}
        for _,c in sgs.list(cards)do
            if self:wasPreviouslyPlannedCard(c) then continue end
            local has = false
            for _,t in sgs.list(cs)do
                if t:getNumber()==c:getNumber() then
                    has = true
                    break
                end
            end
            if has then continue end
            if #cs>0 then
                for _,t in sgs.list(cs)do
                    if math.abs(t:getNumber()-c:getNumber())==1 then
                        has = true
                        break
                    end
                end
                if not has then continue end
            end
            table.insert(cs,c)
        end
        local ids = {}
        for _,c in sgs.list(cs)do
            table.insert(ids,c:getKnownId())
        end
        if #ids>1 then
            return parse_action(self,"#zaibiCard:"..table.concat(ids,"+")..":")
        end
        table.removeOne(cards,cs[1])
    end
end

ai_card_use["#zaibiCard"] = function(self, card, use, request)
    use.card = card
end

sgs.ai_use_value.zaibiCard = 4.5
sgs.ai_use_priority.zaibiCard = 7.7

ai_fill_skill._chunqiubi = function(self, options, request)
    local inclusive = options and options.inclusive

    return parse_action(self,"#_chunqiubiCard:.:")
end

ai_card_use["#_chunqiubiCard"] = function(self, card, use, request)
    local tps = self:sort(self.room:getAllPlayers())
    for _,p in sgs.list(tps)do
        if not self:isFriend(p) then
            use.to:append(p)
            use.card = card
            break
        end
    end
end

sgs.ai_use_value._chunqiubiCard = 4.5
sgs.ai_use_priority._chunqiubiCard = 7.7


sgs.ai_skill_playerchosen.nyarz_falu = function(self,players)
    for _,target in sgs.list(self:sort(players,"hp"))do
        if (self:isFriend(target) or target:isWounded()) or self:isEnemy(target) then
            return target
        end
    end
end

ai_skill_choice["nyarz_falu"] = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local target = data:toPlayer()
    if self:isFriend(target) then
        return ai_choice_result(("recover"), options)
    end
    return ai_choice_result(("losehp"), options)
end

sgs.ai_playerchosen_intention.nyarz_falu = function(self, from, to)
    if self:isFriend(to) then
        self:updateIntention(from, to, -80)
    else
        self:updateIntention(from, to, 80)
    end
end

ai_skill_invoke.cangqiao = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (self:canDraw()) or false
end

sgs.ai_skill_playerchosen.godshenji = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    local cns = scope(self,"godshenjiCNS"):split("+")
    for _,p in sgs.list(destlist)do
        for _,id in sgs.qlist(p:getEquipsId())do
            if source_query(self, "doDisCard", p, id) then
                for _,cn in sgs.list(cns)do
                    local dc = preview(self,cn,"godshenji")
                    mutate(self,dc,"add",id)
                    if source_query(dc, "isAvailable", self.player) then
                        local d = use_card(self,dc)
                        if d.card then
                            set_state(self,"godshenji_use",d)
                            set_choice(self,"godshenji",cn)
                            return p
                        end
                    end
                end
            end
        end
    end
    self:sort(destlist,nil,true)
    for _,p in sgs.list(destlist)do
        if self:isFriend(p) then continue end
        for _,id in sgs.qlist(p:getEquipsId())do
            for _,cn in sgs.list(cns)do
                local dc = preview(self,cn,"godshenji")
                mutate(self,dc,"add",id)
                if source_query(dc, "isDamageCard") and source_query(dc, "targetFixed") and source_query(dc, "isAvailable", self.player) then
                    set_state(self,"godshenji_use",{card = dc,to = {}})
                    set_choice(self,"godshenji",cn)
                    return p
                end
            end
        end
    end
end

ai_skill_use["@@godshenji"] = function(self, prompt, request)
    local dummy = get_state(self,"godshenji_use")
    if dummy.card then
        local tos = {}
        for _,p in sgs.list(dummy.to)do
            table.insert(tos,p:objectName())
        end
        return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

ai_skill_choice.huaxiu = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    for _,t in sgs.list(items)do
        for _,e in sgs.qlist(player:getEquips())do
            if t:contains(e:objectName()) then
                return ai_choice_result((t), options)
            end
        end
    end

    return ai_choice_result(nil, options)
end

sgs.ai_use_revises.cangqiao = function(self,card,use)
    if self.player:getHandcardNum()<self.player:getMaxHp()
    and (card:objectName()=="yj_numa" or card:objectName()=="yj_nvzhuang" or card:objectName()=="yj_zheji")
    then return true end
end

ai_skill_invoke._ofhun_crossbow = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

ai_skill_choice._ofhun_crossbow = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    for _,t in sgs.list(items)do
        for _,p in sgs.qlist(room:getPlayers())do
            if t:endsWith(p:objectName()) and source_query(self, "objectiveLevel", p)>1 then
                return ai_choice_result((t), options)
            end
        end
    end

    return ai_choice_result(nil, options)
end

ai_skill_invoke._ofhun_eight_diagram = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

ai_skill_choice._ofhun_eight_diagram = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    local items = choices:split("+")
    for _,t in sgs.list(items)do
        for _,p in sgs.qlist(room:getPlayers())do
            if t:endsWith(p:objectName()) and source_query(self, "objectiveLevel", p)>1 then
                return ai_choice_result((t), options)
            end
        end
    end

    return ai_choice_result(nil, options)
end

sgs.ai_skill_playerchosen._of_lingling = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    for _,p in sgs.list(destlist)do
        if self:isEnemy(p) and source_query(self, "damageIsEffective", p, "T", self.player) then
            return p
        end
    end
    for _,p in sgs.list(destlist)do
        if self:isEnemy(p) then
            return p
        end
    end
end





ai_skill_choice.godshenji=function(self, options, request)return ai_choice_result((get_choice(self,"godshenji")), options)end
ai_skill_choice.jisi=function(self, options, request)return ai_choice_result((get_choice(self,"jisi")), options)end
ai_skill_choice.kemobileyijin=function(self, options, request)return ai_choice_result((get_choice(self,"kemobileyijin")), options)end
ai_skill_choice.keolbixin=function(self, options, request)return ai_choice_result((get_choice(self,"keolbixin")), options)end
ai_skill_choice.keolcihuang=function(self, options, request)return ai_choice_result((get_choice(self,"keolcihuang")), options)end
ai_skill_choice.keolgoudekingdom=function(self, options, request)return ai_choice_result((get_choice(self,"keolgoudekingdom")), options)end
ai_skill_choice.keolzhuyan=function(self, options, request)return ai_choice_result((get_choice(self,"keolzhuyan")), options)end
ai_skill_choice.liangyuan=function(self, options, request)return ai_choice_result((get_choice(self,"liangyuan")), options)end
-- The source constructs a strategy seed before choosing targets/costs. Rebind
-- exactly the first selected proposal, without re-running the policy.
for class,skill in pairs(action_skills)do
    local fn=ai_card_use[class]
    if type(fn)=='function' then
        ai_card_use[class]=function(self, card, use, request)
            local previous=self._newgenerals_request
            self._newgenerals_request=request
            local ok,result=pcall(fn, self, card, use, request)
            self._newgenerals_request=previous
            if not ok then error(result,0)end
            if use.card then use.card=materialize_action(self,use.card,request)end
            return result
        end
    end
end
local newgenerals_fill_names={"_chunqiubi","chongjian","chuifeng","hannan","huishi","huishii","jiechu","jinghe","kehuiyao","kemobileguanzong","keolbixin","keolkenshang","keolqingyi","keolsaogu","keolshandao","keolshizhan","keolshuangxiong","keolweilin","keolxianbi","keolxieju","keolyilie","keolzhenying","keolzhubi","liangyuan","mobile_dingzou","mobile_wuling","mobile_youyi","mobiledamingvs","mobilefenming","mobilejingxie","mobileqiaosi","mobilexiaoni","moufanjian","moufenwei","mouguose","mouhuoji","moujiang","moujiewei","moujushou","mouliangzhu","moulianhuan","moulijian","moulongdan","mouluanji","moumingce","mouqicai","mouqixi","mourende","moutianxiang","mouwusheng","mouxuanhuo","mouyanyu","mouzhangwu","mouzhenliang","nhhuoqi","nhxianshou","nosjinwanyi","ny_ol_yanru","offunan","ofjixu","ofshezuo","ofsifen","ofyouchong","oldimeng","olfuman","olmoguofu","olxiaofan","renbinglun","renluanchou","tyzhuangpo","xdyifuvs","xin2chuhai","xiongsuan","yanduanbi","yanyangjie","yingba","yongshanxie","zaibi","zhaoluan","zuoxing"}
for _,skill in ipairs(newgenerals_fill_names)do
    local fn=ai_fill_skill[skill]
    ai_fill_skill[skill]=function(self, options, request)
    local inclusive = options and options.inclusive

        local previous,stage=self._newgenerals_request,self._newgenerals_stage
        self._newgenerals_request,self._newgenerals_stage=request,'fill'
        local ok,result=pcall(fn,self,options,request)
        self._newgenerals_request,self._newgenerals_stage=previous,stage
        if not ok then error(result,0)end
        return select_preview(self,result,request)
    end
end

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, from, to, dmg, card, nature, damage_call, helpers, context)
        dmg=dmg+damage_call(to,"getMark","&yise")
        return dmg, nature
    end
    local previous_1 = sgs.ai_ajustdamage_from["yise"]
    sgs.ai_ajustdamage_from["yise"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "slash_card" and context.rule == "yise" then
                local damage, next_nature, terminal = policy_1(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_from", "yise", {
        {phase="slash_card", rule="yise", order=5205},
    })
end)()

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_skill_defense["yingba"]
    local policy = function(self, to, context)
        local value, query = context.value, context.query
        local hp, core_query = context.extra[1], context.extra[2]
        if query(to, "getHandcardNum") > 1 and query(to, "hasSkills", "yingba+pinghe") then return false, true end
        return value
    end
    sgs.ai_skill_defense["yingba"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "weakness_early" and context.rule == "yingba_pinghe" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
        return previous
    end
    sgs.declareValueHookStages("ai_skill_defense", "yingba", {
        {phase="weakness_early", order=3, rule="yingba_pinghe"},
    })
end)()
end
