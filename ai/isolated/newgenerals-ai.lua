-- Fixed b6025acc newgenerals. Native simulations are readonly; final selected
-- materials are rebound through issued scopes. No source registry fallback.
local function known(v,k)
    if AIUnsupported.is(v) then error(v,0) end
    if v==nil then ai_unsupported('Newgenerals missing '..k,'newgenerals') end
    return v
end
local function copy(v)
    if type(v)~='table' then return v end
    local r={};for k,x in pairs(v) do r[k]=copy(x) end;return r
end
local preview_specs=setmetatable({},{__mode='k'})
local resolve_preview
local failure_mark
local function q(o,m,...)
    if AIValue.isPlayer(o) then
        if m=='getMark' and failure_mark and type((...))=='string' and (...):match('^olxiaofanFailed%-%d+Clear$') then return failure_mark(o:getRoom()._ai,o,(...)) end
        if m=='getMark' then m='getStrategyMark' elseif m=='hasFlag' then m='getStrategyFlag' end
    end
    if not o or type(o[m])~='function' then ai_unsupported('Newgenerals unavailable '..m,'newgenerals') end
    local args={...};for i=1,select('#',...) do if preview_specs[args[i]] then args[i]=resolve_preview(args[i]) end end
    return known(o[m](o,table.unpack(args,1,select('#',...))),m)
end
local function dummy(isDummy,extra,current)
    return AIUsePlan.new({isDummy=isDummy~=false,extra_target=extra,current_targets=current})
end
-- AIUsePlan.new has no options overload: preserve the fixed source dummy
-- fields explicitly for these complete three response callbacks.
local function r44_range_dummy(extra,current)
    local use=AIUsePlan.new();use.isDummy=true;use.extra_target=extra or 0;use.current_targets=current or {};return use
end
local function r42_response_dummy(extra)
    local use=AIUsePlan.new();use.isDummy=true;use.extra_target=extra or 0;use.current_targets={};return use
end
local function pattern_names(self,class)
    if type(class)=='string'then
        local mapping=known(AICardCatalog.patternClassNames(),'exact last-write class/name catalog')
        return mapping[class] or class
    end
    return known(AICardCatalog.patternNames(),'pattern names')
end
local function r45_handpile(self,flags)
    local cards=sgs.QList2Table(q(self.player,"getCards",flags))
    local ids=self.player:getHandPile()
    if not AIValue.isList(ids)then ai_unsupported("actual hand-pile contains an unobserved material","newgenerals.hand_pile")end
    for _,id in ipairs(ids)do table.insert(cards,q(self,"getKnownCardById",id))end
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
        local m=method;c[m]=function(_,...)local r=resolve_preview(c);return q(r,m,...)end
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
        local r=q(st.ai,'evaluateOwnerViewAsCard',spec)
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    if st.skill=='keolshuangxiong' then
        local r=q(st.ai,'evaluateOwnerViewAsCard',{source_key='newgenerals.keolshuangxiong',
            name=st.name,skill=st.skill,suit=st.suit,number=st.number,subcards=copy(st.costs)})
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    if st.skill=='keolsuji' then
        local r=q(st.ai,'evaluateOwnerViewAsCard',{source_key='newgenerals.keolsuji',
            name=st.name,skill=st.skill,suit=st.suit,number=st.number,subcards=copy(st.costs)})
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    if st.skill=='_keolxieju' then
        local r=q(st.ai,'evaluateOwnerViewAsCard',{source_key='newgenerals._keolxieju',
            name=st.name,skill=st.skill,suit=st.suit,number=st.number,subcards=copy(st.costs)})
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    if st.skill=='mouluanji' then
        local r=q(st.ai,'evaluateOwnerViewAsCard',{source_key='newgenerals.mouluanji',
            skill=st.skill,name=st.name,suit=st.suit,number=st.number,subcards=copy(st.costs)})
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    local r45={keolkenshang=true,keolyilie=true,moujiang=true,mobilexiaoni=true,keolweilin=true,
        _xdyifu=true,ofsifen=true,_ofsifen=true,ofjunwei=true,_ofyouchong=true,godshenji=true}
    if r45[st.skill] then
        local spec={source_key='newgenerals.'..st.skill,skill=st.skill,name=st.name,
            suit=st.suit,number=st.number,subcards=copy(st.costs)}
        if st.recast~=nil then spec.can_recast=st.recast end
        local r=q(st.ai,'evaluateOwnerViewAsCard',spec)
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    local r42={moulveying='moulveying',mouyingwu='mouyingwu',_mouxieji='mouxieji'}
    if r42[st.skill] then
        local r=q(st.ai,'evaluateOwnerViewAsCard',{source_key='newgenerals.'..r42[st.skill],
            skill=st.skill,name=st.name,suit=st.suit,number=st.number,subcards=copy(st.costs)})
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    if st.skill=='keolcihuang' then
        local r=q(st.ai,'evaluateOwnerViewAsCard',{source_key='newgenerals_context:keolcihuang',skill=st.skill,name=st.name,suit=st.suit,number=st.number,subcards=copy(st.costs)})
        st.ai:inheritLegacyCardIdentity(r,c);st.cached=r;return r
    end
    if st.suit~=sgs.Card_NoSuit or st.number~=0 then
        ai_unsupported('readonly clone requires exact nondefault suit/number projection','newgenerals.preview')
    end
    local r
    if st.skill=='' and #st.costs==0 then r=st.base
    elseif st.skill=='_mouxianchou' then
        r=q(st.ai,'evaluateOwnerViewAsCard',{source_key='mouxianchou',skill=st.skill,name=st.name,
            suit=st.suit,number=st.number,subcards=copy(st.costs)})
    else r=q(st.ai,'evaluateSkillCard',st.skill,st.name,st.costs) end
    if st.recast~=nil and q(r,'canRecast')~=st.recast then
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
    elseif kind=='add' then st.costs[#st.costs+1]=type(value)=='number' and value or q(value,'getEffectiveId')
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
        local selected=q(self,'evaluateTurnConversion',st.skill,q(r,'getClassName'),
            {name=st.name,skill=st.skill,suit=st.suit,number=st.number,subcards=copy(st.costs)},request)
        return self:inheritLegacyCardIdentity(selected,c)
    end
    return q(self,'bindTurnConversion',st.skill,q(r,'getClassName'),{name=st.name,skill_name=st.skill,suit=q(r,'getSuit'),number=q(r,'getNumber'),subcards=copy(st.costs)},request)
end
local function target_ok(c,from,to,prefix)
    return CanToCard(resolve_preview(c),from,to,prefix)
end
local function scope(self,key)
    local row=q(self,'getDecisionContext').newgenerals
    if type(row)~='table' then ai_unsupported('Newgenerals scoped context unavailable',key) end
    return known(row[key],key)
end
local function player(self,name)
    if name==false or name=='' then return nil end
    return q(self.room,'findPlayerByObjectName',name)
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
        or selected:getEffectiveId()~=q(card,"getEffectiveId") then
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
    return known(rows[tostring(q(card,'getEffectiveId'))],key)
end
local function known_card(self,id)
    id=tonumber(id);if not id then return nil end
    if self.request.kind=='amazing_grace' or self.request.kind=='guanxing' then
        for _,x in ipairs(self.request.options.card_ids or {}) do if x==id then
            local c=q(self,'getChoiceCard',id);return self:getAcquiredCardEvaluation(c) or c
        end end
    end
    local context=self:getDecisionContext().newgenerals
    local rows=type(context)=='table' and context.notified_current_cards
    if type(rows)=='table' and rows[tostring(id)] then
        return q(self,'getPreviewCardEvaluation',id)
    end
    return q(self,'getKnownCardById',id)
end
local function role_count(self,k)return known(known(known(self.world.mode_policy,'role policy').role_counts,'role counts')[k],'role count '..k)end
local function trigger_skill(self,name)
    for _,p in ipairs(self.room:getPlayers())do for _,s in ipairs(q(p,'getVisibleSkillList'))do
        if q(s,'objectName')==name then
            return {hasEvent=function(_,event)return q(s,'hasTriggerEvent',event)end}
        end
    end end
    -- Definitions of skills no visible player holds are not projected.
    ai_unsupported('public trigger-skill definition unavailable',name)
end
local function role_estimate(self,p)return q(self,'getRoleEstimate',p)end
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
    for _,p in ipairs(q(room,'getPlayers'))do if q(p,'objectName')==owner then return p end end
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
            actual_suit=q(known_card(self,cs[1]),'getSuit')
            if #cs>1 then
                local red,black=true,true
                for _,id in ipairs(cs)do local c=known_card(self,id);red=red and q(c,'isRed');black=black and q(c,'isBlack')end
                actual_suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit
            end
        end
        if number<=0 and #cs==1 then number=q(known_card(self,cs[1]),'getNumber')end
        local face=known(printed(self,name),'parsed printed class')
        return q(self,'bindTurnConversion',skill,q(face,'getClassName'),{name=name,skill_name=skill,suit=actual_suit,number=number,subcards=cs},self._newgenerals_request)
    end
    local skill=known(action_skills[class],'source skill for '..class)
    local ids=cost_ids(costs);if not ids then return nil end
    local r
    if self._newgenerals_stage=='fill' and class=='#xdyifucard' then
        -- Source Card_Parse observes a proposal; only a selected usefunc pays.
        r=q(self,'evaluateTurnSkillCard',skill,class,ids,self._newgenerals_request,user)
        action_specs[r]={skill=skill,class=class,costs=ids,user=user,request=self._newgenerals_request}
    elseif self._newgenerals_stage=='fill' and #ids==0 and user=='' then
        r=q(self,'legacySkillSeed',skill,class,self._newgenerals_request)
        action_specs[r]={skill=skill,class=class,costs=ids,user=user,request=self._newgenerals_request}
    else
        r=q(self,'bindSkillCard',skill,ids,self._newgenerals_request,user~=''and user or nil,class)
    end
    return r
end
local original_mutate=mutate
mutate=function(self,c,kind,value)
    local st=action_specs[c]
    if not st then return original_mutate(self,c,kind,value)end
    if kind=='add' then st.costs[#st.costs+1]=type(value)=='number'and value or q(value,'getEffectiveId')
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
    local r=q(self,'bindSkillCard',st.skill,st.costs,request or st.request,st.user~=''and st.user or nil,st.class)
    return self:inheritLegacyCardIdentity(r,c)
end
local function clone_preview(self,name,suit,number)return preview(self,name,'',suit or sgs.Card_NoSuit,number or 0)end
local function printed_card(self,id)return q(self,'getPrintedCardById',id)end
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
    local name=q(p,'objectName')
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
    if key=='hannan_card'or key=='yanyangjie_card'then self:remember(key,value and q(value,'getEffectiveId'))end
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
    local fn=sgs.ai_skill_invoke.peiqi
    if type(fn)~='function'then ai_unsupported('effective Peiqi policy is not loaded','newgenerals.yandiaodu')end
    local ok,result=pcall(fn,self)
    if self.peiqiData then set_state(self,'peiqiData',self.peiqiData)end
    if not ok then error(result,0)end
    return result
end


function SmartAIView:useCardQizhengxiangsheng(card,use)
    self:sort(self.enemies,"hp")
    local extraTarget = q(card,"getTargetModExtra",self.player)
    if use.extra_target then extraTarget = extraTarget+use.extra_target end
    for _,ep in sgs.list(self.enemies)do
        if isCurrent(use,ep) then continue end
        if target_ok(card,self.player,ep,use.to)
        and q(self,"ajustDamage",self.player,ep,1,card)~=0
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
        return q(self,"isFriend",to)
        and q(self,"isWeak",to)
    else
        return q(self,"isEnemy",to)
        and q(self,"isWeak",to)
    end
end

sgs.ai_skill_choice._qizhengxiangsheng = function(self,choices,data)
    local items = choices:split("+")
    local target = data:toPlayer()
    if q(target,"getHandcardNum")<3 and math.random()>0.4
    or q(target,"isKongcheng")
    then return items[2] end
    if math.random()<0.4
    then return items[1] end
end

sgs.ai_skill_invoke.zhiren = function(self,data)
    return true
end

sgs.ai_skill_playerchosen.zhiren = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"equip")
    for _,target in sgs.list(destlist)do
        if q(self,"isEnemy",target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not q(self,"isFriend",target)
        then return target end
    end
    return destlist[1]
end

sgs.ai_skill_playerchosen.zhiren_judge = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not q(self,"isEnemy",target)
        then return target end
    end
end

sgs.ai_skill_invoke.yaner = function(self,data)
    local target = data:toPlayer()
    if target then
        return not q(self,"isEnemy",target)
    end
end

sgs.ai_skill_invoke.quedi = function(self,data)
    local target = data:toPlayer()
    if target then
        return q(self,"isEnemy",target)
    end
end

sgs.ai_skill_choice.quedi = function(self,choices,data)
    local items = choices:split("+")
    local use = data:toCardUse()
    if use.to:at(0):getHandcardNum()>1
    then return items[1] end
    if use.to:at(0):getHandcardNum()<2
    then return items[2] end
end

sgs.ai_fill_skill.chuifeng = function(self,inclusive,request)

    if ((q(self.player,"getMark","usetimeschuifeng-PlayClear") < 2)
    and (q(self.player,"getMark","banchuifeng-Clear") == 0)) then

        for _,cn in sgs.list(pattern_names(self))do
            local fs = preview(self,cn)
            if fs and q(self.player,"getKingdom")=="wei"
            and q(fs,"isKindOf","Duel")
            and q(fs,"isAvailable",self.player)
            and not q(self,"isWeak") then
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

sgs.ai_skill_use_func["#chuifengCard"] = function(card,use,self,request)
    use.card = card
    use.to = get_state(self,"cf_to")
end

sgs.ai_use_value.chuifengCard = 5.4
sgs.ai_use_priority.chuifengCard = 2.8




sgs.ai_fill_skill.chongjian = function(self,inclusive,request)
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards,nil,true)
    local toids = {}
    for _,c in sgs.list(cards)do
        if q(c,"isKindOf","EquipCard")
        then table.insert(toids,c) end
    end
    for _,cn in sgs.list(pattern_names(self))do
        local fs = preview(self,cn)
        if fs and q(self.player,"getKingdom")=="wu"
        and (q(fs,"isKindOf","Slash") or q(fs,"isKindOf","Analeptic"))
        and #toids>0 then
            mutate(self,fs,"skill","chuifeng")
            mutate(self,fs,"add",toids[1])
            local d = use_card(self,fs)
            if q(fs,"isAvailable",self.player)
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
        if q(c,"isKindOf","EquipCard")
        then table.insert(toids,q(c,"getEffectiveId")) end
    end
    if #toids>0
    then return "#chongjianCard:"..toids[1]..":"..toname end
end


sgs.ai_skill_invoke.xiuhao = function(self,data)
    local target = data:toPlayer()
    if target then
        return not q(self,"isEnemy",target) or q(self,"isWeak")
    end
end

sgs.ai_skill_playerchosen.sujian = function(self,players)
    players = self:sort(players,"card",true)
    for _,target in sgs.list(players)do
        if q(self,"isEnemy",target)
        then return target end
    end
    for _,target in sgs.list(players)do
        if not q(self,"isFriend",target)
        then return target end
    end
    return players[1]
end

sgs.ai_skill_askforyiji.sujian = function(self,card_ids,tos)
    local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
    if to and id then return to,id end
    for _,target in sgs.list(tos)do
        if q(self,"isFriend",target)
        then return target,card_ids[1] end
    end
    for _,target in sgs.list(tos)do
        return target,card_ids[1]
    end
end

sgs.ai_skill_choice.sujian = function(self,choices,data)
    local items = choices:split("+")
    local ids = data:toIntList()
    local to,id = sgs.ai_skill_askforyiji.sujian(self,sgs.QList2Table(ids),self.room:getOtherPlayers(self.player))
    if to and id then
        return "give"
    end
    return "discard"
end

sgs.ai_fill_skill.olfuman = function(self,inclusive,request)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(cards)
    for _,ep in sgs.list(self.friends_noself)do
        if q(ep,"getMark","olfuman_target-PlayClear")<1
        and #cards>=q(self.player,"getMaxCards")
        then
            return parse_action(self,"#olfuman:"..cards[1]:getEffectiveId()..":")
        end
    end
    for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
        if q(ep,"getMark","olfuman_target-PlayClear")<1
        and #cards>q(self.player,"getMaxCards")
        and not q(self,"isEnemy",ep)
        then
            return parse_action(self,"#olfuman:"..cards[1]:getEffectiveId()..":")
        end
    end
end

sgs.ai_skill_use_func["#olfuman"] = function(card,use,self,request)
    self:sort(self.friends_noself,"hp")
    for _,ep in sgs.list(self.friends_noself)do
        if q(ep,"getMark","olfuman_target-PlayClear")<1
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
    for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
        if q(ep,"getMark","olfuman_target-PlayClear")<1
        and q(self.player,"getHandcardNum")>q(self.player,"getMaxCards")
        and not q(self,"isEnemy",ep)
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
        if q(self,"isFriend",target)
        then return target end
    end
    for _,target in sgs.list(players)do
        if not q(self,"isEnemy",target)
        then return target end
    end
    return players[1]
end

sgs.ai_skill_discard.zhiming = function(self)
    local cards = {}
    local js = self.player:getCards("j")
    if js:length()>0
    and q(self.player,"getPhase")==sgs.Player_Start then
        local handcards = self.player:getCards("he")
        handcards = self:sortByKeepValue(handcards) -- 按保留值排序
        local jt = judge_pattern(self,js:last():objectName())
        if type(jt)~="table" then
            if type(jt)=="string" then
                jt = {jt,true}
            else
                jt = {q(jc,"getSuitString"),true}
            end
        end
        if jt then
            for _,h in sgs.list(handcards)do
                if q(self,"matchesDiscardPattern",jt[1],h)==jt[2]
                then table.insert(cards,q(h,"getEffectiveId")) end
                if #cards>0 then return cards end
            end
        end
    end
    js = self:poisonCards("he")
    if q(self.player,"getPhase")~=sgs.Player_Start and #js>0 then
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
    return q(self,"isEnemy",use.to:at(0))
end

sgs.ai_skill_playerchosen.xbwuxinglianzhu = function(self,players)
    players = self:sort(players,"handcard",true)
    for _,target in sgs.list(players)do
        if q(self,"isFriend",target)
        then return target end
    end
    for _,target in sgs.list(players)do
        if not q(self,"isEnemy",target)
        then return target end
    end
    return players[1]
end

sgs.ai_skill_playerchosen.xbfukuangdongzhu = function(self,players)
    players = self:sort(players,"hp")
    for _,target in sgs.list(players)do
        if q(self,"isFriend",target)
        then return target end
    end
    for _,target in sgs.list(players)do
        if not q(self,"isEnemy",target)
        then return target end
    end
    return players[1]
end

sgs.ai_skill_playerchosen.xbyinghuoshouxin = function(self,players)
    players = self:sort(players,"handcard",true)
    for _,target in sgs.list(players)do
        if q(self,"isEnemy",target)
        then return target end
    end
    for _,target in sgs.list(players)do
        if not q(self,"isFriend",target)
        then return target end
    end
    return players[1]
end

sgs.ai_skill_invoke.olhaoshi = function(self,data)
    local al = self.room:getOtherPlayers(self.player)
    local n,can = 998,false
    for _,target in sgs.list(al)do
        n = math.min(n,q(target,"getHandcardNum"))
    end
    for _,target in sgs.list(al)do
        if q(target,"getHandcardNum")<=n
        and not q(self,"isEnemy",target)
        then can = true end
    end
    return q(self.player,"getHandcardNum")+2<=5 or can
end

sgs.ai_skill_cardask["@olhaoshi-give"] = function(self,data,pattern,to)
    local use = data:toCardUse()
    if q(self,"isFriend",to)
    and q(self,"isWeak",to)
    then
        local cs
        if q(use.card,"isKindOf","Slash")
        or q(use.card,"isKindOf","ArcheryAttack")
        then cs = self:getCards("Jink") end
        if q(use.card,"isKindOf","Duel")
        or q(use.card,"isKindOf","SavageAssault")
        then cs = self:getCards("Slash") end
        if cs then return cs[1]:getEffectiveId() end
    end
    return "."
end

sgs.ai_fill_skill.oldimeng = function(self,inclusive,request)
    return parse_action(self,"#oldimeng:.:")
end

sgs.ai_skill_use_func["#oldimeng"] = function(card,use,self,request)
    self:sort(self.enemies,"handcard",true)
    self:sort(self.friends_noself,"handcard")
    for _,ep in sgs.list(self.enemies)do
        for _,fp in sgs.list(self.friends_noself)do
            if q(ep,"getHandcardNum")>q(fp,"getHandcardNum")
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
        if not q(self,"isEnemy",target)
        then return target end
    end
    self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
        if q(self,"isEnemy",target)
        then return target end
    end
    self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target)
        then return target end
    end
    return destlist[1]
end

sgs.ai_skill_playerchosen.secondkangge = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
        if not q(self,"isEnemy",target)
        then return target end
    end
    self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target)
        then return target end
    end
    self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
        if q(self,"isEnemy",target)
        then return target end
    end
    return destlist[1]
end

sgs.ai_skill_playerchosen.fengjie = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
        if not q(self,"isEnemy",target)
        then return target end
    end
    return destlist[1]
end

sgs.ai_skill_invoke.secondkangge = function(self,data)
    local target = data:toPlayer()
    if target
    then
        return not q(self,"isEnemy",target)
    end
end

sgs.ai_skill_invoke.secondjielie = function(self,data)
    return true
end

sgs.ai_skill_invoke.yise = function(self,data)
    local target = data:toPlayer()
    if target
    then
        return q(self,"isFriend",target)
    end
end

sgs.ai_skill_askforyiji.shunshi = function(self,card_ids)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
    local tos = self.room:getOtherPlayers(self.player)
    tos = self:sort(tos,"hp")
    for _,p in sgs.list(tos)do
        if q(p,"hasFlag","shunshi")
        then
            if cards[1]:isRed() and q(self,"isFriend",p)
            or cards[1]:isBlack() and q(self,"isEnemy",p)
            then return p,cards[1]:getEffectiveId() end
        end
    end
end

sgs.ai_skill_cardask["@fengzi-discard"] = function(self,data)
    local use = data:toCardUse()
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,h in sgs.list(cards)do
        if q(h,"getTypeId")==q(use.card,"getTypeId")
        then
            if q(use.card,"isKindOf","Peach")
            and q(self.player,"getLostHp")>1
            then return q(h,"getEffectiveId")
            elseif q(use.card,"isKindOf","Analeptic")
            and not(q(h,"isKindOf","Slash") and self:wasPreviouslyPlannedCard(h))
            then return q(h,"getEffectiveId")
            elseif use.to:contains(self.player)
            then return q(h,"getEffectiveId")
            elseif q(use.card,"isDamageCard")
            or q(use.card,"isKindOf","SingleTargetTrick")
            then
                for _,to in sgs.list(use.to)do
                    if q(self,"isFriend",to)
                    then return "." end
                end
                return q(h,"getEffectiveId")
            end
        end
    end
    return "."
end

sgs.ai_skill_invoke.jizhanw = function(self,data)
    return true
end

sgs.ai_skill_choice.jizhanw = function(self,choices,data)
    local n = data:toInt()
    local items = choices:split("+")
    if n>6 then return items[2] end
    if n<7 then return items[1] end
    return items[2]
end


sgs.ai_skill_playerchosen.fusong = function(self,players)
    players = self:sort(players,"card",true)
    for _,target in sgs.list(players)do
        if q(self,"isFriend",target)
        then return target end
    end
    for _,target in sgs.list(players)do
        if not q(self,"isEnemy",target)
        then return target end
    end
end

sgs.ai_skill_invoke.qingjue = function(self,data)
    local use = data:toCardUse()
    if q(self,"isFriend",use.to:at(0))
    then
        if q(self,"isWeak",use.to:at(0))
        and q(use.card,"isDamageCard")
        then return true
        else
            local cards = self.player:getCards("h")
            cards = sgs.QList2Table(cards) -- 将列表转换为表
            self:sortByKeepValue(cards) -- 按保留值排序
            for _,h in sgs.list(cards)do
                if q(h,"getNumber")>9
                then return true end
            end
        end
    end
end

sgs.ai_skill_playerchosen.zhibian = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards) -- 将列表转换为表
        self:sortByKeepValue(cards) -- 按保留值排序
        for _,h in sgs.list(cards)do
            if q(h,"getNumber")>9
            and q(self,"isEnemy",target)
            then return target end
        end
    end
end

sgs.ai_useto_revises.yuyan = function(self,card,use,p)
    if q(card,"isKindOf","Slash")
    and not q(card,"isVirtualCard")
    then
        set_defense(self,"yuyan",0)
        local xc = self:getMaxCard(nil,self:getCards("he"))
        if xc and q(xc,"getNumber")<=q(card,"getNumber")
        then set_defense(self,"yuyan",4) end
    end
end

sgs.ai_skill_invoke.yilie = function(self,data)
    return true
end

sgs.ai_fill_skill.mobilefenming = function(self,inclusive,request)
    return parse_action(self,"#mobilefenming:.:")
end

sgs.ai_skill_use_func["#mobilefenming"] = function(card,use,self,request)
    self:sort(self.enemies,"hp")
    for _,ep in sgs.list(self.enemies)do
        if q(ep,"isChained") and q(ep,"getCardCount")>1
        and q(ep,"getHp")<=q(self.player,"getHp")
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
    for _,ep in sgs.list(self.enemies)do
        if q(ep,"getHp")>q(self.player,"getHp") then continue end
        use.card = card
        use.to:append(ep)
        return
    end
end

sgs.ai_use_value.mobilefenming = 3.4
sgs.ai_use_priority.mobilefenming = 4.8

sgs.ai_fill_skill.jinghe = function(self,inclusive,request)
    local cards = sgs.QList2Table(self.player:getCards("h"))
    if #cards<1 then return end
    self:sortByKeepValue(cards)
    local toids,cs = {},{}
    for _,c in sgs.list(cards)do
        if #toids>=#self.friends
        or cs[q(c,"objectName")]
        then continue end
        cs[q(c,"objectName")] = true
        table.insert(toids,q(c,"getEffectiveId"))
    end
    set_state(self,"jh_n",#toids)
    return #toids>0 and parse_action(self,"#jinghe:"..table.concat(toids,"+")..":")
end

sgs.ai_skill_use_func["#jinghe"] = function(card,use,self,request)
    self:sort(self.friends,"hp",true)
    for _,ep in sgs.list(self.friends)do
        use.card = card
        if use.to:length()<get_state(self,"jh_n")
        then use.to:append(ep) end
    end
end

sgs.ai_use_value.jinghe = 9.4
sgs.ai_use_priority.jinghe = 6.8

sgs.ai_skill_invoke.gongxiu = function(self,data)
    return true
end


sgs.ai_skill_choice.gongxiu = function(self,choices)
    local items = choices:split("+")
    local draw,discard = 0,0
    for _,p in sgs.list(self.room:getAllPlayers())do
        if q(p,"getMark","jinghe_GetSkill-Clear")>0
        then draw = draw+1
        elseif not q(p,"isKongcheng")
        then discard = discard+1 end
    end
    if draw<discard
    then return "discard"
    else return "draw" end
end

sgs.ai_fill_skill.nhhuoqi = function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards,nil,true)
    if #cards>0
    then
        return parse_action(self,"#nhhuoqi:"..cards[1]:getEffectiveId()..":")
    end
end

sgs.ai_skill_use_func["#nhhuoqi"] = function(card,use,self,request)
    self:sort(self.friends,"hp")
    local tos = self.room:getOtherPlayers(self.player)
    tos = self:sort(tos,"hp")
    for _,ep in sgs.list(self.friends)do
        if q(ep,"getHp")<=tos[1]:getHp()
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
end

sgs.ai_use_value.nhhuoqi = 9.4
sgs.ai_use_priority.nhhuoqi = 4.8

sgs.ai_skill_invoke.nhguizhu = function(self,data)
    return true
end

sgs.ai_fill_skill.nhxianshou = function(self,inclusive,request)
    return parse_action(self,"#nhxianshou:.:")
end

sgs.ai_skill_use_func["#nhxianshou"] = function(card,use,self,request)
    self:sort(self.friends,"hp")
    for _,ep in sgs.list(self.friends)do
        if not q(ep,"isWounded")
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
    for _,ep in sgs.list(self.friends)do
        if q(ep,"isWounded")
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
end

sgs.ai_use_value.nhxianshou = 9.4
sgs.ai_use_priority.nhxianshou = 3.8

sgs.ai_skill_invoke.yise = function(self,data)
    local target = data:toPlayer()
    if target
    then
        return not q(self,"isFriend",target) and q(target,"getHandcardNum")>q(self.player,"getHandcardNum")
        or q(target,"getHandcardNum")<q(self.player,"getHandcardNum")
    end
end

sgs.ai_skill_invoke.nhguanyue = function(self,data)
    return true
end

sgs.ai_skill_cardask["@nhyanzheng-keep"] = function(self,data)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards,true) -- 按保留值排序
    local n = #cards-1
    if n>#self.enemies/2
    and n<#self.enemies*2
    then
        return cards[1]:getEffectiveId()
    end
    return "."
end

sgs.ai_skill_use["@@nhyanzheng"] = function(self,prompt)
    local valid = {}
    local destlist = self.room:getOtherPlayers(self.player)
    destlist = self:sort(destlist,"hp")
    local n = q(self.player,"getMark","nhyanzheng-PlayClear")
    for _,friend in sgs.list(destlist)do
        if #valid>=n then break end
        if q(self,"isEnemy",friend)
        then table.insert(valid,q(friend,"objectName")) end
    end
    for _,friend in sgs.list(destlist)do
        if #valid>=n then break end
        if not q(self,"isFriend",friend)
        and not table.contains(valid,q(friend,"objectName"))
        then table.insert(valid,q(friend,"objectName")) end
    end
    if #valid>0
    then
        return string.format("#nhyanzheng:.:->%s",table.concat(valid,"+"))
    end
end

sgs.ai_fill_skill.nosjinwanyi = function(self,inclusive,request)
    local cards = self:addHandPile()
    cards = self:sortByKeepValue(cards,nil,true)
    for _,c in sgs.list(cards)do
        local eg = printed_card(self,q(c,"getEffectiveId"))
        if card_fact(self,c,"YingBianEffects")=="" then continue end
        for _,cn in sgs.list({"zhujinqiyuan","chuqibuyi","drowning","dongzhuxianji"})do
            local tc = preview(self,cn)
            if not tc or q(c,"objectName")==cn then continue end
            mutate(self,tc,"skill","nosjinwanyi")
            mutate(self,tc,"add",c)
            local d = use_card(self,tc)
            self:setPriorityValue("nosjinwanyi",self:getPriorityValue(tc:getClassName()),"newgenerals")
            set_state(self,"wy_to",d.to)
            if d.card and d.to
            and q(tc,"isAvailable",self.player)
            then return parse_action(self,"#nosjinwanyi:"..q(c,"getEffectiveId")..":"..cn) end
        end
    end
end

sgs.ai_skill_use_func["#nosjinwanyi"] = function(card,use,self,request)
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
        if q(self,"isFriend",target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not q(self,"isEnemy",target)
        then return target end
    end
end



sgs.ai_skill_invoke.jinzhaosong = function(self,data)
    local target = data:toPlayer()
    if target
    then
        return not q(self,"isEnemy",target)
    end
end

sgs.ai_skill_invoke.jinzhaosong_lei = function(self,data)
    return true
end

sgs.ai_skill_playerchosen.jinzhaosong = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target)
        and q(self,"doDisCard",target,"ej")
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if q(self,"isEnemy",target)
        and q(target,"getCardCount")>0
        then return target end
    end
end

sgs.ai_skill_invoke.jinzhaosong_fu = function(self,data)
    local target = scoped_player(self,"JinZhaosongDrawer")
    if target then return not q(self,"isEnemy",target) end
end

sgs.ai_skill_use["@@jinzhaosong"] = function(self,prompt)
    local valid = {}
    local destlist = self.room:getOtherPlayers(self.player)
    destlist = self:sort(destlist,"hp")
    for _,friend in sgs.list(destlist)do
        if #valid>1 then break end
        if q(self,"isEnemy",friend)
        and q(friend,"hasFlag","jinzhaosong_can_choose")
        then table.insert(valid,q(friend,"objectName")) end
    end
    for _,friend in sgs.list(destlist)do
        if #valid>1 then break end
        if not q(self,"isFriend",friend)
        and q(friend,"hasFlag","jinzhaosong_can_choose")
        and not table.contains(valid,q(friend,"objectName"))
        then table.insert(valid,q(friend,"objectName")) end
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
        if q(self,"isFriend",target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not q(self,"isEnemy",target)
        then return target end
    end
end


sgs.ai_fill_skill.zuoxing = function(self,inclusive,request)
    for _,name in sgs.list(pattern_names(self))do
        local poi = preview(self,name)
        if poi==nil then continue end
        mutate(self,poi,"skill","zuoxing")
        if q(poi,"isAvailable",self.player)
        and q(poi,"isNDTrick") and q(poi,"isDamageCard") then
            local dummy = use_card(self,poi)
            if dummy.card and dummy.to then
                set_state(self,"zx_to",dummy.to)
                self:setPriorityValue("zuoxing",self:getPriorityValue(poi:getClassName()),"newgenerals")
                if q(poi,"canRecast") and dummy.to:length()<1 then continue end
                return parse_action(self,"#zuoxing:.:"..name)
            end
        end
    end
    for _,name in sgs.list(pattern_names(self))do
        local poi = preview(self,name)
        if poi==nil then continue end
        mutate(self,poi,"skill","zuoxing")
        if q(poi,"isAvailable",self.player)
        and q(poi,"isNDTrick") and name~="amazing_grace"
        and name~="collateral" then
            local dummy = use_card(self,poi)
            if dummy.card and dummy.to then
                set_state(self,"zx_to",dummy.to)
                self:setPriorityValue("zuoxing",self:getPriorityValue(poi:getClassName()),"newgenerals")
                if q(poi,"canRecast") and dummy.to:length()<1 then continue end
                return parse_action(self,"#zuoxing:.:"..name)
            end
        end
    end
end

sgs.ai_skill_use_func["#zuoxing"] = function(card,use,self,request)
    use.card = card
    use.to = get_state(self,"zx_to")
end

sgs.ai_use_value.zuoxing = 8.4
sgs.ai_use_priority.zuoxing = 8.4

sgs.ai_fill_skill.huishi = function(self,inclusive,request)
    return parse_action(self,"#huishiCard:.:")
end

sgs.ai_skill_use_func["#huishiCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value.huishiCard = 8.4
sgs.ai_use_priority.huishiCard = 8.4

sgs.ai_skill_invoke.huishi = function(self,data)
    return true
end

sgs.ai_skill_playerchosen.huishi = function(self,players)
    players = self:sort(players,"handcard")
    for _,target in sgs.list(players)do
        if q(self,"isFriend",target)
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
        if q(self,"isFriend",target)
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
        if q(self,"isEnemy",target)
        then
            return target
        end
    end
    return destlist[1]
end

sgs.ai_fill_skill.huishii = function(self,inclusive,request)
    return parse_action(self,"#huishii:.:")
end

sgs.ai_skill_use_func["#huishii"] = function(card,use,self,request)
    self:sort(self.friends,"hp")
    for _,ep in sgs.list(self.friends)do
        local skills = {}
        for _,sk in sgs.list(ep:getVisibleSkillList())do
            if q(sk,"getFrequency",ep)~=sgs.Skill_Wake
            or q(ep,"getMark",q(sk,"objectName"))>0
            then continue end
            table.insert(skills,q(sk,"objectName"))
        end
        if #skills>0
        and q(self.player,"getMaxHp")>2
        and q(self.player,"getLostHp")>1
        and q(self.player,"getMaxHp")>=self.room:alivePlayerCount()
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
    for _,ep in sgs.list(self.friends)do
        if q(self,"isWeak",ep) and q(self.player,"getMaxHp")>2
        and q(self.player,"getLostHp")>1
        then
            use.card = card
            use.to:append(ep)
            return
        end
    end
end

sgs.ai_use_value.huishii = 8.4
sgs.ai_use_priority.huishii = 8.5

sgs.ai_skill_use["@@dangmo"] = function(self,prompt)
    local valid = {}
    local destlist = self.room:getOtherPlayers(self.player)
    destlist = self:sort(destlist,"hp")
    local n = q(self.player,"getHp")-1
    for _,friend in sgs.list(destlist)do
        if #valid>=n then break end
        if q(self,"isEnemy",friend)
        and q(friend,"hasFlag","dangmo")
        then table.insert(valid,q(friend,"objectName")) end
    end
    for _,friend in sgs.list(destlist)do
        if #valid>=n then break end
        if not q(self,"isFriend",friend)
        and q(friend,"hasFlag","dangmo")
        and not table.contains(valid,q(friend,"objectName"))
        then table.insert(valid,q(friend,"objectName")) end
    end
    if #valid>0
    then
        return string.format("#dangmo:.:->%s",table.concat(valid,"+"))
    end
end

sgs.ai_fill_skill.yingba = function(self,inclusive,request)
    if q(self.player,"getMaxHp")>2
    then
        return parse_action(self,"#yingba:.:")
    end
end

sgs.ai_skill_use_func["#yingba"] = function(card,use,self,request)
    self:sort(self.enemies,"hp")
    for _,ep in sgs.list(self.enemies)do
        if q(ep,"isWounded")
        or q(ep,"getMaxHp")<2
        then continue end
        use.card = card
        use.to:append(ep)
        return
    end
    self:sort(self.enemies,"hp",true)
    for _,ep in sgs.list(self.enemies)do
        if q(ep,"getMaxHp")<2
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
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
        if q(self,"isFriend",p) then return p,cards[1]:getEffectiveId() end
    end
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
        if q(self,"isEnemy",p) then continue end
        return p,cards[1]:getEffectiveId()
    end
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
        return p,cards[1]:getEffectiveId()
    end
end

sgs.ai_use_revises.pinghe = function(self,card)
    if q(card,"isKindOf","Peach")
    then return false end
end

sgs.ai_skill_choice.dinghan = function(self,choices)
    local items = choices:split("+")
    local cns = property_value(self,self.player,"SkillDescriptionRecord_dinghan"):split("+")
    if table.contains(items,"remove") then
        for _,pn in sgs.list(cns)do
            local c = preview(self,pn)
            if c then
                set_state(self,"ai_dinghan_choice",q(c,"objectName"))
                if q(c,"isDamageCard") and q(self,"isWeak")
                and q(self,"getRestCardsNum",c:getClassName())>0
                then return "remove" end
                if q(c,"isKindOf","DelayedTrick")
                and q(self,"getRestCardsNum",c:getClassName())>0
                then return "remove" end
            end
        end
    end
    if table.contains(items,"add") then
        for d,c in sgs.list(self.player:getHandcards())do
            if table.contains(cns,q(c,"objectName"))
            or q(c,"isZhinangCard") then continue end
            if q(c,"targetFixed") and not q(c,"isDamageCard") then
                set_state(self,"ai_dinghan_choice",q(c,"objectName"))
                d = use_card(self,c)
                if d.card and d.to
                then return "add" end
            end
        end
        for _,pn in sgs.list(pattern_names(self))do
            if table.contains(cns,pn) then continue end
            local c = preview(self,pn)
            if c then
                if table.contains(sgs.ZhinangClassName,c:getClassName())
                or q(c,"isZhinangCard") then continue end
                set_state(self,"ai_dinghan_choice",pn)
                if q(c,"targetFixed") and not q(c,"isDamageCard")
                and q(self,"getRestCardsNum",c:getClassName())>0
                then return "add" end
            end
        end
        for _,pn in sgs.list(pattern_names(self))do
            if table.contains(cns,pn) then continue end
            local c = preview(self,pn)
            if c then
                if table.contains(sgs.ZhinangClassName,c:getClassName())
                or q(c,"isZhinangCard") then continue end
                set_state(self,"ai_dinghan_choice",pn)
                if q(c,"isKindOf","GlobalEffect") and not q(c,"isDamageCard")
                and q(self,"getRestCardsNum",c:getClassName())>0
                then return "add" end
            end
        end
    end
    return "cancel"
end

sgs.ai_skill_askforag.dinghan = function(self,card_ids)
    for c,id in sgs.list(card_ids)do
        c = known_card(self,id)
        if q(c,"objectName")==get_state(self,"ai_dinghan_choice")
        then return id end
    end
    for c,id in sgs.list(card_ids)do
        c = known_card(self,id)
        if q(c,"isDamageCard") and q(self,"isWeak")
        and q(self,"getRestCardsNum",c:getClassName())>0
        then return id end
    end
    for c,id in sgs.list(card_ids)do
        c = known_card(self,id)
        if q(c,"targetFixed") and not q(c,"isDamageCard")
        and q(self,"getRestCardsNum",c:getClassName())>0
        then return id end
    end
    for c,id in sgs.list(card_ids)do
        c = known_card(self,id)
        if q(c,"isKindOf","GlobalEffect") and not q(c,"isDamageCard")
        and q(self,"getRestCardsNum",c:getClassName())>0
        then return id end
    end
end

sgs.ai_target_revises.tianzuo = function(to,card,self)
    if q(card,"isKindOf","Qizhengxiangsheng")
    and not q(self,"isFriend",to)
    then return true end
end

sgs.ai_target_revises.dinghan = function(to,card,self)
    if q(card,"getTypeId")==2
    then
        local cns = property_value(self,to,"SkillDescriptionRecord_dinghan"):split("+")
        if table.contains(cns,q(card,"objectName"))
        then return end
        return true
    end
end

sgs.ai_skill_playerchosen.kemobileyijin = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target)
        then
            if q(self.player,"getMark","@keyijin_houren")>0 and q(self,"isWeak",target) and q(target,"isWounded")
            then
                set_choice(self,"kemobileyijin","keyijin_houren")
                return target
            end
            if q(self.player,"getMark","@keyijin_tongshen")>0 and q(self,"isWeak",target)
            then
                set_choice(self,"kemobileyijin","keyijin_tongshen")
                return target
            end
            if q(self.player,"getMark","@keyijin_wushi")>0 and not q(self,"isWeak",target)
            then
                set_choice(self,"kemobileyijin","keyijin_wushi")
                return target
            end
            if q(self.player,"getMark","@keyijin_jinmi")>0 and q(target,"isSkipped",sgs.Player_Play)
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if q(self,"isEnemy",target)
        then
            if q(self.player,"getMark","@keyijin_guxiong")>0 and q(self,"isWeak",target)
            then
                set_choice(self,"kemobileyijin","keyijin_guxiong")
                return target
            end
            if q(self.player,"getMark","@keyijin_yongbi")>0 and q(target,"getHandcardNum")<4
            then
                set_choice(self,"kemobileyijin","keyijin_yongbi")
                return target
            end
            if q(self.player,"getMark","@keyijin_jinmi")>0 and q(self,"getOverflow")~=0
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if not q(self,"isFriend",target)
        then
            if q(self.player,"getMark","@keyijin_guxiong")>0 and q(self,"isWeak",target)
            then
                set_choice(self,"kemobileyijin","keyijin_guxiong")
                return target
            end
            if q(self.player,"getMark","@keyijin_yongbi")>0 and q(target,"getHandcardNum")<4
            then
                set_choice(self,"kemobileyijin","keyijin_yongbi")
                return target
            end
            if q(self.player,"getMark","@keyijin_jinmi")>0 and q(self,"getOverflow")~=0
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if not q(self,"isEnemy",target)
        then
            if q(self.player,"getMark","@keyijin_houren")>0 and q(self,"isWeak",target) and q(target,"isWounded")
            then
                set_choice(self,"kemobileyijin","keyijin_houren")
                return target
            end
            if q(self.player,"getMark","@keyijin_tongshen")>0 and q(self,"isWeak",target)
            then
                set_choice(self,"kemobileyijin","keyijin_tongshen")
                return target
            end
            if q(self.player,"getMark","@keyijin_wushi")>0 and not q(self,"isWeak",target)
            then
                set_choice(self,"kemobileyijin","keyijin_wushi")
                return target
            end
            if q(self.player,"getMark","@keyijin_jinmi")>0 and q(target,"isSkipped",sgs.Player_Play)
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
end


sgs.ai_card_priority.xingtu = function(self,card,v)
    if q(self.player,"getMark","&xingtu") % q(card,"getNumber") == 0
    then return 10 end
end
sgs.ai_card_priority.nosxingtu = function(self,card,v)
    if q(self.player,"getMark","&nosxingtu") % q(card,"getNumber") == 0
    then return 10 end
end


sgs.ai_fill_skill.kehuiyao = function(self,inclusive,request)
    return parse_action(self,"#kehuiyaoCard:.:")
end

sgs.ai_skill_use_func["#kehuiyaoCard"] = function(card,use,self,request)
    if not q(self,"isWeak") then
        self:sort(self.enemies)
        for _, ep in ipairs(self.enemies) do
            local can = true
            for _,sk in ipairs(sgs.getPlayerSkillList(ep)) do
                local ts = trigger_skill(self,q(sk,"objectName"))
                if ts and ts:hasEvent(sgs.Damage) then
                    can = false
                    break
                end
            end
            if can then
                for _, fp in ipairs(self.friends_noself) do
                    for _,sk in ipairs(sgs.getPlayerSkillList(fp)) do
                        local ts = trigger_skill(self,q(sk,"objectName"))
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
                local ts = trigger_skill(self,q(sk,"objectName"))
                if ts and ts:hasEvent(sgs.Damage) then
                    for _, ep in ipairs(self.enemies) do
                        local can = true
                        for _,sk in ipairs(sgs.getPlayerSkillList(ep)) do
                            local ts = trigger_skill(self,q(sk,"objectName"))
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
                local ts = trigger_skill(self,q(sk,"objectName"))
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
                    local ts = trigger_skill(self,q(sk,"objectName"))
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
        if q(self.player,"hasSkill","kequesong") and q(self.player,"getMark","&kequesong-Clear")<1 then
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
        if q(self,"isFriend",p) then
            return p
        end
    end
    return nil
end

sgs.ai_skill_choice.kequesong = function(self,choices,data)
    local items = choices:split("+")
    return q(self.player,"isWounded") and (q(self,"isWeak") or q(self.player,"getHandcardNum")>q(self.player,"getHp")) and items[2]
    or items[1]
end

sgs.ai_skill_playerchosen.kehuiyaoone = function(self, targets)
    targets = sgs.QList2Table(targets)
    local theweak = AIList.new({})
    local theweaktwo = AIList.new({})
    for _, p in ipairs(targets) do
        if q(self,"isEnemy",p) then
            theweak:append(p)
        end
    end
    for _,qq in sgs.qlist(theweak) do
        if theweaktwo:isEmpty() then
            theweaktwo:append(qq)
        else
            local inin = 1
            for _,pp in sgs.qlist(theweaktwo) do
                if (q(pp,"getHp") < q(qq,"getHp")) then
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
        if q(self,"isFriend",p) then
            theweak:append(p)
        end
    end
    for _,qq in sgs.qlist(theweak) do
        if theweaktwo:isEmpty() then
            theweaktwo:append(qq)
        else
            local inin = 1
            for _,pp in sgs.qlist(theweaktwo) do
                if (q(pp,"getHp") < q(qq,"getHp")) then
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


sgs.ai_skill_choice.keolshanduanmpjd = function(self, choices, data)
    return "shanduanfour"
end

sgs.ai_skill_choice.keolshanduancpgjfw = function(self, choices, data)
    local two = 1
    for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if q(self,"isEnemy",p) and q(self.player,"inMyAttackRange",p) then
            two = 0
        end
        break
    end
    if two == 1 then
        return "shanduantwo"
    else
        return "shanduanone"
    end
end

sgs.ai_skill_choice.keolshanduancpslash = function(self, choices, data)
    local items = choices:split("+")
    return items[#items]
end

sgs.ai_skill_discard.keolhuanfu = function(self, discard_num, min_num, optional, include_equip)
    local to_discard = {}
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    if q(self.player,"hasFlag","wantusehuanfu") then
        table.insert(to_discard, cards[1]:getEffectiveId())
        return to_discard
    else
        return self:askForDiscard("dummyreason", discard_num, min_num, true, true)
    end
end

sgs.ai_fill_skill.keolqingyi = function(self,inclusive,request)
    if q(self.player,"hasUsed","keolqingyiCard") then return end
    return parse_action(self,"#keolqingyiCard:.:")
end

sgs.ai_skill_use_func["#keolqingyiCard"] = function(card, use, self,request)
    if not q(self.player,"hasUsed","#keolqingyiCard") then
        local room = self.room
        local all = room:getOtherPlayers(self.player)
        local enys = AIList.new({})
        for _, p in sgs.qlist(all) do
            if q(self,"isEnemy",p) and (enys:length() < 2) then
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
        if q(self,"isEnemy",p) then
            theweak:append(p)
        end
    end
    for _,qq in sgs.qlist(theweak) do
        if theweaktwo:isEmpty() then
            theweaktwo:append(qq)
        else
            local inin = 1
            for _,pp in sgs.qlist(theweaktwo) do
                if (q(pp,"getHp") < q(qq,"getHp")) then
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
        if q(self,"isFriend",target)
        then
            if q(self.player,"getMark","@keyijin_houren")>0 and q(self,"isWeak",target) and q(target,"isWounded")
            then
                set_choice(self,"kemobileyijin","keyijin_houren")
                return target
            end
            if q(self.player,"getMark","@keyijin_tongshen")>0 and q(self,"isWeak",target)
            then
                set_choice(self,"kemobileyijin","keyijin_tongshen")
                return target
            end
            if q(self.player,"getMark","@keyijin_wushi")>0 and not q(self,"isWeak",target)
            then
                set_choice(self,"kemobileyijin","keyijin_wushi")
                return target
            end
            if q(self.player,"getMark","@keyijin_jinmi")>0 and q(target,"isSkipped",sgs.Player_Play)
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if q(self,"isEnemy",target)
        then
            if q(self.player,"getMark","@keyijin_guxiong")>0 and q(self,"isWeak",target)
            then
                set_choice(self,"kemobileyijin","keyijin_guxiong")
                return target
            end
            if q(self.player,"getMark","@keyijin_yongbi")>0 and q(target,"getHandcardNum")<4
            then
                set_choice(self,"kemobileyijin","keyijin_yongbi")
                return target
            end
            if q(self.player,"getMark","@keyijin_jinmi")>0 and q(self,"getOverflow")~=0
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if not q(self,"isFriend",target)
        then
            if q(self.player,"getMark","@keyijin_guxiong")>0 and q(self,"isWeak",target)
            then
                set_choice(self,"kemobileyijin","keyijin_guxiong")
                return target
            end
            if q(self.player,"getMark","@keyijin_yongbi")>0 and q(target,"getHandcardNum")<4
            then
                set_choice(self,"kemobileyijin","keyijin_yongbi")
                return target
            end
            if q(self.player,"getMark","@keyijin_jinmi")>0 and q(self,"getOverflow")~=0
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if not q(self,"isEnemy",target)
        then
            if q(self.player,"getMark","@keyijin_houren")>0 and q(self,"isWeak",target) and q(target,"isWounded")
            then
                set_choice(self,"kemobileyijin","keyijin_houren")
                return target
            end
            if q(self.player,"getMark","@keyijin_tongshen")>0 and q(self,"isWeak",target)
            then
                set_choice(self,"kemobileyijin","keyijin_tongshen")
                return target
            end
            if q(self.player,"getMark","@keyijin_wushi")>0 and not q(self,"isWeak",target)
            then
                set_choice(self,"kemobileyijin","keyijin_wushi")
                return target
            end
            if q(self.player,"getMark","@keyijin_jinmi")>0 and q(target,"isSkipped",sgs.Player_Play)
            then
                set_choice(self,"kemobileyijin","keyijin_jinmi")
                return target
            end
        end
    end
end

sgs.ai_fill_skill.kemobileguanzong = function(self,inclusive,request)
    return parse_action(self,"#kemobileguanzongCard:.:")
end

sgs.ai_skill_use_func["#kemobileguanzongCard"] = function(card,use,self,request)
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
        if not q(self,"isFriend",target)
        then return target end
    end
end

sgs.ai_skill_playerchosen.keoltongdu = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
        if q(self,"isEnemy",target) and q(self,"isWeak")
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if q(self,"isEnemy",target)
        then return target end
    end
    self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target)
        and q(target,"getHandcardNum")>5
        then return target end
    end
    return destlist[1]
end

sgs.ai_fill_skill.keolzhubi = function(self,inclusive,request)
    return parse_action(self,"#keolzhubiCard:.:")
end

sgs.ai_skill_use_func["#keolzhubiCard"] = function(card,use,self,request)
    self:sort(self.friends,"card")
    for _,fp in sgs.list(self.friends)do
        if not q(fp,"hasFlag","keolzhubiTo")
        and q(fp,"getCardCount")>1
        then
            use.card = card
            strategy_flag(self,fp,"keolzhubiTo")
            use.to:append(fp)
            return
        end
    end
    for _,fp in sgs.list(self.enemies)do
        if not q(fp,"hasFlag","keolzhubiTo")
        and q(fp,"getCardCount")==1
        then
            use.card = card
            strategy_flag(self,fp,"keolzhubiTo")
            use.to:append(fp)
            return
        end
    end
    for _,fp in sgs.list(self.friends)do
        if q(fp,"getCardCount")>2
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

sgs.ai_skill_use["@@keolzhubi"] = function(self,prompt)
    local valid = {}
    local ids = scope_list(self,"keolzhubiForAI")
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,c in sgs.list(cards)do
        if owner_tip(self,c,"keolzhubi")
        then
            for _,id in sgs.list(ids)do
                if table.contains(valid,id) then continue end
                local c2 = known_card(self,id)
                if self:cardNeed(c2)>self:cardNeed(c)
                then
                    table.insert(valid,q(c,"getId"))
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
            if q(self,"isEnemy",target) and q(self,"isWeak",target)
            and q(mc,"getNumber")>9 then return target end
        end
        for _,target in sgs.list(destlist)do
            if q(self,"isEnemy",target)
            and q(mc,"getNumber")>9 then return target end
        end
        for _,target in sgs.list(destlist)do
            if not q(self,"isFriend",target)
            and q(mc,"getNumber")>9 then return target end
        end
        self:sort(destlist,"card",true)
        for _,target in sgs.list(destlist)do
            if q(self,"isFriend",target)
            and q(mc,"getNumber")>6 then return target end
        end
        for _,target in sgs.list(destlist)do
            if q(self,"isEnemy",target) and q(self.player,"getPhase")>sgs.Player_Play
            then return target end
        end
    end
end

sgs.ai_skill_use["@@keolzhuri"] = function(self,prompt)
    local ids = scope_list(self,"keolzhuriForAI")
    for _,id in sgs.list(ids)do
        local c2 = known_card(self,id)
        if q(c2,"isAvailable",self.player) then
            local d = use_card(self,c2)
            if d.card then
                local tos = {}
                for _,p in sgs.list(d.to)do
                    table.insert(tos,q(p,"objectName"))
                end
                if q(c2,"canRecast") and #tos<1 then continue end
                return r45_selected_borrowed(self,c2,d.to,tos)
            end
        end
    end
end

sgs.ai_skill_choice.keolzhuri = function(self,choices)
    local items = choices:split("+")
    return (q(self.player,"getPhase")>sgs.Player_Play or q(self,"isWeak")) and items[2] or items[1]
end

sgs.ai_skill_invoke.keolranji = function(self,data)
    return q(self.player,"getMark","keolranji_used-Clear") == q(self.player,"getHp")
end

sgs.ai_skill_choice.keolranji = function(self,choices)
    local items = choices:split("+")
    return q(self,"isWeak") and items[1] or items[2]
end

sgs.ai_use_revises.keolranji = function(self,card,use)
    if q(self.player,"getMark","&keolranji_ban")>0 and q(card,"isKindOf","Peach") then
        return false
    end
end

sgs.ai_skill_invoke.keolbotu = function(self,data)
    return true
end

sgs.ai_skill_use["@@keolxiejuslash"] = function(self,prompt)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,h in sgs.list(cards)do
        local c = preview(self)
        mutate(self,c,"skill","_keolxieju")
        mutate(self,c,"add",h)
        if q(self.player,"isLocked",c) or not q(h,"isBlack") then continue end
        local dummy = use_card(self,c)
        if dummy.card and dummy.to then
            local tos = {}
            for _,p in sgs.list(dummy.to)do
                table.insert(tos,q(p,"objectName"))
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

sgs.ai_fill_skill.keolshuangxiong = function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,h in sgs.list(cards)do
        if q(self.player,"getMark","&keolshuangxiong+"..q(h,"getColorString").."-Clear")>0
        then continue end
        local c = preview(self,"duel")
        mutate(self,c,"skill","keolshuangxiong")
        mutate(self,c,"add",h)
        if q(c,"isAvailable",self.player)
        then return c end
    end
end


sgs.ai_skill_invoke.keolqiejian = function(self,data)
    return true
end

sgs.ai_fill_skill.tyzhuangpo = function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,h in sgs.list(cards)do
        local des = q(h,"getDescription")
        if string.find(des,"【杀】") then
            local c = preview(self,"duel")
            mutate(self,c,"skill","tyzhuangpo")
            mutate(self,c,"add",h)
            if q(c,"isAvailable",self.player)
            then return c end
        end
    end
end

sgs.ai_skill_invoke.tyzhuangpo = function(self,data)
    local to = data:toPlayer()
    return q(self,"isEnemy",to)
    and q(to,"getCardCount")>0
end

sgs.ai_skill_choice.tyzhuangpo = function(self,choices)
    local items = choices:split("+")
    local to = data:toPlayer()
    return items[math.min(q(to,"getCardCount"),#items)]
end

sgs.ai_skill_invoke.yongyiyong = function(self,data)
    local to = data:toPlayer()
    return q(self,"isEnemy",to)
    and not q(self,"isFriend",to) and #self.friends_noself<1
end

sgs.ai_fill_skill.yongshanxie = function(self,inclusive,request)
    return parse_action(self,"#yongshanxieCard:.:")
end

sgs.ai_skill_use_func["#yongshanxieCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value.yongshanxieCard = 3.4
sgs.ai_use_priority.yongshanxieCard = 6.2

sgs.ai_skill_discard.keolhuanfu = function(self,x,n)
    local to_cards = {}
    local use = scoped_struct(self,"keolhuanfuData","use")
    if use.to:contains(self.player) then
        if q(self,"getCardsNum","Jink")<1 then
            local m = q(self,"ajustDamage",use.from,self.player,1,use.card)
            if m>0 and m<q(self.player,"getHp")+q(self,"getCardsNum","Peach,Analeptic") then
                local cards = self.player:getCards("he")
                cards = sgs.QList2Table(cards)
                self:sortByKeepValue(cards)
                for _,c in sgs.list(cards)do
                    if q(self.player,"isJilei",c) then continue end
                    table.insert(to_cards,q(c,"getEffectiveId"))
                    if #to_cards>=x or #to_cards>=m then break end
                end
            end
        end
    elseif use.from==self.player then
        if getCardsNum("Jink",use.to:first(),self.player)<1 then
            local m = q(self,"ajustDamage",use.from,use.to:first(),1,use.card)
            if m>0 then
                local cards = self.player:getCards("he")
                cards = sgs.QList2Table(cards)
                self:sortByKeepValue(cards)
                for _,c in sgs.list(cards)do
                    if q(self.player,"isJilei",c) then continue end
                    table.insert(to_cards,q(c,"getEffectiveId"))
                    if #to_cards>=x or #to_cards>=m then break end
                end
            end
        end
    end
    return to_cards
end

sgs.ai_fill_skill.keolqingyi = function(self,inclusive,request)
    return parse_action(self,"#keolqingyiCard:.:")
end

sgs.ai_skill_use_func["#keolqingyiCard"] = function(card,use,self,request)
    self:sort(self.enemies,"card")
    for _,p in sgs.list(self.enemies)do
        if q(p,"getCardCount")>0 and use.to:length()<2 then
            use.card = card
            use.to:append(p)
        end
    end
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
        if q(p,"getCardCount")>0 and use.to:length()<2
        and not(use.to:contains(p) or q(self,"isFriend",p)) then
            use.card = card
            use.to:append(p)
        end
    end
end

sgs.ai_use_value.keolqingyiCard = 3.4
sgs.ai_use_priority.keolqingyiCard = 6.2

sgs.ai_skill_invoke.keolqingyi = function(self,data)
    return true
end


sgs.ai_skill_playerchosen.keolzeyue = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
        if q(self,"isEnemy",target)
        and #self.enemies>=q(self.player,"aliveCount")/2
        then return target end
    end
end

sgs.ai_skill_invoke.keolkangrui = function(self,data)
    return true
end

sgs.ai_skill_choice.keolkangrui = function(self,choices,data)
    local items = choices:split("+")
    local to = data:toPlayer()
    return q(self,"isFriend",to) and q(to,"isWounded") and items[1]
    or items[2]
end

sgs.ai_skill_invoke.keolqiejian = function(self,data)
    local to = data:toPlayer()
    return q(self,"isFriend",to)
    or #self:poisonCards("ej")>0
    or q(self,"doDisCard",to,"ej")
end

sgs.ai_skill_playerchosen.keolqiejian = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
        if q(self,"doDisCard",target,"ej")
        then return target end
    end
end

sgs.ai_skill_playerchosen.keolnishou = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not q(self,"isEnemy",target)
        then return target end
    end
end

sgs.ai_skill_invoke.keolguangao = function(self,data)
    local st = data:toString()
    local sts = st:split(":")
    local to = BeMan(self.room,sts[2])
    if q(self,"isFriend",to) then
        return q(to,"getHandcardNum")%2==0
    elseif q(to,"getHandcardNum")%2~=0
    then
        return q(self,"isEnemy",to)
        or #self.friends_noself<1
    end
end

sgs.ai_skill_playerschosen.keolguangao = function(self,players,x,n)
    local tos = {}
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target) and #tos<x
        then table.insert(tos,target) end
    end
    return tos
end

sgs.ai_fill_skill.keolxieju = function(self,inclusive,request)
    return parse_action(self,"#keolxiejuCard:.:")
end

sgs.ai_skill_use_func["#keolxiejuCard"] = function(card,use,self,request)
    self:sort(self.friends,"card",true)
    for _,p in sgs.list(self.friends)do
        if q(p,"getCardCount")>0 and q(p,"getMark","keolxiejutar-Clear")>0 then
            use.card = card
            use.to:append(p)
        end
    end
end

sgs.ai_use_value.keolxiejuCard = 3.4
sgs.ai_use_priority.keolxiejuCard = 2.2



sgs.ai_fill_skill.keolshandao = function(self,inclusive,request)
    return parse_action(self,"#keolshandaoCard:.:")
end

sgs.ai_skill_use_func["#keolshandaoCard"] = function(card,use,self,request)
    self:sort(self.friends,"card",true)
    for _,p in sgs.list(self.friends)do
        if q(p,"getCardCount")>0 then
            use.card = card
            use.to:append(p)
        end
    end
    for _,p in sgs.list(self.enemies)do
        if q(p,"getCardCount")>0 and q(self,"doDisCard",p,"e") then
            use.card = card
            use.to:append(p)
        end
    end
    for _,p in sgs.list(self.room:getAllPlayers())do
        if not(q(self,"isEnemy",p) or use.to:contains(p))
        and q(p,"getCardCount")>0 and #self.enemies>0 then
            use.card = card
            use.to:append(p)
        end
    end
end

sgs.ai_use_value.keolshandaoCard = 3.4
sgs.ai_use_priority.keolshandaoCard = 4.2

sgs.ai_fill_skill.keolkenshang = function(self,inclusive,request)
    local dc = preview(self)
    mutate(self,dc,"skill","keolkenshang")
    local cards = r45_handpile(self,"he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for i,c in sgs.list(cards)do
        if q(self.player,"isLocked",c) then continue end
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
            if q(player,"isLocked",c) then continue end
            mutate(self,dc,"add",c)
            if i>#cards/2 or dc:subcardsLength()>#self.enemies then break end
        end
        return dc:subcardsLength()>1 and dc:toString()
    end
end



sgs.ai_fill_skill.keolxianbi = function(self,inclusive,request)
    return parse_action(self,"#keolxianbiCard:.:")
end

sgs.ai_skill_use_func["#keolxianbiCard"] = function(card,use,self,request)
    local tos = sgs.QList2Table(self.room:getAllPlayers())
    self:sort(tos,"equip",true)
    for _,p in sgs.list(tos)do
        if p:getEquips():length()>q(self.player,"getHandcardNum") then
            use.card = card
            use.to:append(p)
            return
        end
    end
    for _,p in sgs.list(self.enemies)do
        if p:getEquips():length()<q(self.player,"getHandcardNum") then
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
        if q(self,"isEnemy",target)
        and #self:poisonCards("he",target)<q(target,"getCardCount")/2
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not q(self,"isFriend",target) and #self.friends_noself<1
        and #self:poisonCards("he",target)<q(target,"getCardCount")/2
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target)
        and #self:poisonCards("he",target)>=q(target,"getCardCount")/2
        then return target end
    end
end

sgs.ai_skill_choice.keolzenrun = function(self,choices,data)
    local items = choices:split("+")
    local to = data:toPlayer()
    if q(self,"isFriend",to) or q(self.player,"getHandcardNum")<q(self.player,"getMaxCards")
    then return items[1] end
end

sgs.ai_skill_playerchosen.keolzhuyan = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    local function compare_func(a,b)
        return q(a,"getMark","keolzhuyanhp")-q(a,"getHp")>q(b,"getMark","keolzhuyanhp")-q(b,"getHp")
    end
    table.sort(destlist,compare_func)
    set_choice(self,"keolzhuyan","hp")
    for _,target in sgs.list(destlist)do
        if q(target,"getMark","beusedzhuyanhp"..q(self.player,"objectName"))<1
        and q(target,"getMark","keolzhuyanhp")-q(target,"getHp")>0
        and q(self,"isFriend",target) and q(self,"isWeak",target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if q(target,"getMark","beusedzhuyanhp"..q(self.player,"objectName"))<1
        and q(target,"getMark","keolzhuyanhp")-q(target,"getHp")>0
        and q(self,"isFriend",target) and q(target,"isWounded")
        then return target end
    end
    destlist = sgs.reverse(destlist)
    for _,target in sgs.list(destlist)do
        if q(target,"getMark","beusedzhuyanhp"..q(self.player,"objectName"))<1
        and q(self,"isEnemy",target) and not q(self,"isWeak",target)
        then return target end
    end
    local function compare_func(a,b)
        return q(a,"getMark","keolzhuyansp")-q(a,"getHandcardNum")>q(b,"getMark","keolzhuyansp")-q(b,"getHandcardNum")
    end
    table.sort(destlist,compare_func)
    set_choice(self,"keolzhuyan","sp")
    for _,target in sgs.list(destlist)do
        if q(target,"getMark","beusedzhuyansp"..q(self.player,"objectName"))<1
        and q(target,"getMark","keolzhuyansp")-q(target,"getHandcardNum")>0
        and q(self,"isFriend",target)
        then return target end
    end
    for _,target in sgs.list(sgs.reverse(destlist))do
        if q(target,"getMark","beusedzhuyansp"..q(self.player,"objectName"))<1
        and q(target,"getMark","keolzhuyansp")-q(target,"getHandcardNum")<0
        and q(self,"isEnemy",target)
        then return target end
    end
end

sgs.ai_skill_playerchosen.keolleijie = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target) and q(target,"getHandcardNum")<5
        and self:getFinalRetrial(nil,"lightning")==1
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if q(self,"isEnemy",target)
        and self:getFinalRetrial(nil,"lightning")==1
        then return target end
    end
    local c = known_card(self,visible_top_id(self))
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target) and q(c,"hasFlag","visible") and q(c,"getSuit")~=0
        and self:getFinalRetrial(nil,"lightning")<2
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target) and q(target,"getHandcardNum")<5
        and self:getFinalRetrial(nil,"lightning")<2
        and not q(self,"isWeak",target)
        then return target end
    end
end

sgs.ai_skill_use["@@keolsujislash"] = function(self,prompt)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,h in sgs.list(cards)do
        local c = preview(self)
        mutate(self,c,"skill","keolsuji")
        mutate(self,c,"add",h)
        if q(self.player,"isLocked",c) or not q(h,"isBlack") then continue end
        local dummy = use_card(self,c)
        if dummy.card then
            local tos = {}
            for _,p in sgs.list(dummy.to)do
                table.insert(tos,q(p,"objectName"))
            end
            return c:toString().."->"..table.concat(tos,"+")
        end
    end
end

sgs.ai_skill_invoke.keollangdao = function(self,data)
    local use = data:toCardUse()
    for _,to in sgs.list(use.to)do
        if q(self,"isEnemy",to) and q(self,"isWeak",to)
        then return true end
    end
end

sgs.ai_skill_playerschosen.keollangdao = function(self,players,x,n)
    local tos = {}
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
        if (q(self,"isEnemy",target) or #self.friends_noself<1) and #tos<x
        then table.insert(tos,target) end
    end
    return tos
end

sgs.ai_skill_choice.keolgoude = function(self,choices,data)
    local items = choices:split("+")
    if table.contains(items,"slash") then
        local dc = preview(self)
        mutate(self,dc,"skill","_keolgoude")
        local d = use_card(self,dc)
        if d.card then
            set_state(self,"keolgoudeUse",d)
            return "slash"
        end
    end
    if table.contains(items,"dis") then
        for _,p in sgs.list(self.enemies)do
            if q(p,"getHandcardNum")<3 and q(self,"doDisCard",p,"h") then
                return "dis"
            end
        end
    end
    if table.contains(items,"kingdom") then
        local ks = {}
        for _,p in sgs.list(self.room:getAllPlayers())do
            ks[q(p,"getKingdom")] = (ks[q(p,"getKingdom")] or 0)+1
        end
        local x = 0
        for k,n in pairs(ks)do
            if n>x then x = n end
        end
        for k,n in pairs(ks)do
            if n>=x and k~=q(self.player,"getKingdom") then
                set_choice(self,"keolgoudekingdom",k)
                return "kingdom"
            end
        end
    end
    if table.contains(items,"draw") then
        return "draw"
    end
    if table.contains(items,"dis") then
        for _,p in sgs.list(self.enemies)do
            if q(self,"doDisCard",p,"h") then
                return "dis"
            end
        end
    end
    return "cancel"
end

sgs.ai_skill_use["@@keolgoude"] = function(self,prompt)
    local dummy = get_state(self,"keolgoudeUse")
    if dummy.card then
        local tos = {}
        for _,p in sgs.list(dummy.to)do
            table.insert(tos,q(p,"objectName"))
        end
        return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end


sgs.ai_fill_skill.keolzhenying = function(self,inclusive,request)
    return parse_action(self,"#keolzhenyingCard:.:")
end

sgs.ai_skill_use_func["#keolzhenyingCard"] = function(card,use,self,request)
    self:sort(self.friends_noself,"handcard",true)
    for _,p in sgs.list(self.friends_noself)do
        if q(p,"getHandcardNum")<=q(self.player,"getHandcardNum")
        and q(p,"getHandcardNum")<2 and q(self.player,"getHandcardNum")<4 then
            use.card = card
            use.to:append(p)
            set_state(self,"keolzhenyingTo",p)
            return
        end
    end
    self:sort(self.enemies,"handcard",true)
    for _,p in sgs.list(self.enemies)do
        if q(p,"getHandcardNum")<=q(self.player,"getHandcardNum") then
            use.card = card
            use.to:append(p)
            set_state(self,"keolzhenyingTo",p)
            return
        end
    end
end

sgs.ai_skill_choice.keolzhenying = function(self,choices,data)
    local items = choices:split("+")
    local from = data:toPlayer()
    if from==self.player then
        if q(self,"isFriend",get_state(self,"keolzhenyingTo")) then
            return items[#items]
        end
    elseif q(self,"isFriend",from) then
        return items[#items]
    end
end

sgs.ai_skill_choice.keolfengyan = function(self,choices,data)
    local items = choices:split("+")
    local from = data:toPlayer()
    if q(self,"isFriend",from) or #self.enemies>0 and not q(self,"isEnemy",from) then
        return items[1]
    end
    return items[2]
end

sgs.ai_skill_invoke.keolbixin = function(self,data)
    local tr = data:toString()
    for _,cn in sgs.list(tr:split("+"))do
        local dc = preview(self,cn)
        mutate(self,dc,"skill","_keolbixin")
        local d = use_card(self,dc)
        if d.card then
            set_choice(self,"keolbixin",cn)
            set_state(self,"keolbixinUse",d)
            return true
        end
    end
end

sgs.ai_skill_choice.keolbixintype = function(self,choices,data)
    local items = choices:split("+")
    local cards = self.player:getCards("h")
    local kv = {}
    for _,k in ipairs(items)do
        kv[k] = 0
    end
    for _,h in sgs.list(cards)do
        kv[q(h,"getType")] = (kv[q(h,"getType")] or 0)+1--q(self,"getKeepValue",h)
    end
    local x = 99
    for k,n in pairs(kv)do
        if n<x and table.contains(items,k) then x = n end
    end
    for k,n in pairs(kv)do
        if n<=x and table.contains(items,k) then
            return k
        end
    end
end

sgs.ai_fill_skill.keolbixin = function(self,inclusive,request)
    return parse_action(self,"#keolbixinCard:.:")
end

sgs.ai_skill_use_func["#keolbixinCard"] = function(card,use,self,request)
    for _,p in sgs.list(pattern_names(self))do
        local dc = preview(self,p)
        if dc and q(dc,"getTypeId")==1 and q(self,"getCardsNum",dc:getClassName())<1
        and q(self.player,"getMark","keolbixin_guhuo_remove_"..p)<1 then
            mutate(self,dc,"skill","keolbixin")
            if q(dc,"isAvailable",self.player) then
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
    if q(self,"getCardsNum",class_name)<1
    then return "#keolbixinCard:.:"..toname end
end

sgs.ai_fill_skill.keolshizhan = function(self,inclusive,request)
    return parse_action(self,"#keolshizhanCard:.:")
end

sgs.ai_skill_use_func["#keolshizhanCard"] = function(card,use,self,request)
    self:sort(self.enemies,"handcard")
    for _,p in sgs.list(self.enemies)do
        if q(self,"getCardsNum","Slash")>getCardsNum("Slash",p,self.player)  then
            local dc = preview(self,"duel")
            mutate(self,dc,"skill","keolshizhan")
            if q(dc,"targetFilter",AIList.new({}),self.player,p) then
                use.card = card
                use.to:append(p)
                return
            end
        end
    end
end

sgs.ai_use_value.keolshizhanCard = 3.4
sgs.ai_use_priority.keolshizhanCard = 2.2


sgs.ai_fill_skill.xin2chuhai = function(self,inclusive,request)
    return parse_action(self,"#xin2chuhaiCard:.:")
end

sgs.ai_skill_use_func["#xin2chuhaiCard"] = function(card,use,self,request)
    self:sort(self.enemies,"handcard")
    local mc = self:getMaxCard()
    if mc and q(mc,"getNumber")>8 then
        for i,c in sgs.list(q(self,"getPriorTurnUseCards"))do
            if i>1 and q(c,"isDamageCard") then
                local d = use_card(self,c)
                if d.card then
                    for _,p in sgs.list(d.to)do
                        if q(self,"isEnemy",p) and q(self.player,"canPindian",p) then
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
        if q(self.player,"canPindian",target)
        then return target end
    end
end

sgs.ai_fill_skill.keolyilie = function(self,inclusive,request)
    for _,p in sgs.list(pattern_names(self))do
        local dc = preview(self,p)
        if dc and q(dc,"getTypeId")==1 and q(self,"getCardsNum",dc:getClassName())<1
        and q(self.player,"getMark","keolyilie_guhuo_remove_"..p)<1 then
            local cards = self.player:getCards("h")
            if cards:length()<2 then break end
            cards = sgs.QList2Table(cards) -- 将列表转换为表
            self:sortByKeepValue(cards) -- 按保留值排序
            mutate(self,dc,"skill","keolyilie")
            for _,h in sgs.list(cards)do
                for _,c in sgs.list(cards)do
                    if q(h,"getId")~=q(c,"getId") and q(h,"getColor")==q(c,"getColor") then
                        mutate(self,dc,"add",h)
                        mutate(self,dc,"add",c)
                        if q(dc,"isAvailable",self.player) then
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
    if q(self,"getCardsNum",class_name)<1 then
        local cards = self.player:getCards("h")
        if cards:length()<2 then return end
        cards = sgs.QList2Table(cards) -- 将列表转换为表
        self:sortByKeepValue(cards) -- 按保留值排序
        local dc = preview(self,toname)
        mutate(self,dc,"skill","keolyilie")
        for _,h in sgs.list(cards)do
            for _,c in sgs.list(cards)do
                if q(h,"getId")~=q(c,"getId") and q(h,"getColor")==q(c,"getColor") then
                    mutate(self,dc,"add",h)
                    mutate(self,dc,"add",c)
                    if not q(self.player,"isLocked",dc) then
                        return dc:toString()
                    end
                    mutate(self,dc,"clear")
                    break
                end
            end
        end
    end
end

sgs.ai_fill_skill.ny_ol_yanru = function(self,inclusive,request)
    return parse_action(self,"#ny_ol_yanruCard:.:")
end

sgs.ai_skill_use_func["#ny_ol_yanruCard"] = function(card,use,self,request)

    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    if #cards<6 then
        if q(self.player,"getMark","ny_ol_yanru_even-PlayClear")<1 then
            self:sortByKeepValue(cards) -- 按保留值排序
            for i,c in sgs.list(cards)do
                if q(self.player,"isJilei",c)
                or card:subcardsLength()>=#cards/2
                then continue end
                mutate(self,card,"add",c)
            end
            if card:subcardsLength()>=#cards/2 then use.card = card end
        end
        if #cards<4 and q(self.player,"getMark","ny_ol_yanru_odd-PlayClear")<1 then
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
        if q(self.player,"isJilei",c) or #to_cards>=n
        or use_card(self,c).card then continue end
        table.insert(to_cards,q(c,"getEffectiveId"))
    end
    for _,c in sgs.list(cards)do
        if q(self.player,"isJilei",c) or #to_cards>=n
        or table.contains(to_cards,q(c,"getEffectiveId")) then continue end
        table.insert(to_cards,q(c,"getEffectiveId"))
    end
    return to_cards
end

sgs.ai_skill_invoke.ny_ol_hezhong = function(self,data)

    return true
end

sgs.ai_skill_choice.ny_ol_hezhong = function(self,choices,data)
    local items = choices:split("+")
    local n = data:toInt()
    if n>6 then
        return items[2]
    end
    return items[1]
end

sgs.ai_skill_invoke.huamu = function(self,data)
    for _,p in sgs.list(self.friends)do
        if q(p,"hasSkill","liangyuan",true)
        then return true end
    end
end

sgs.ai_fill_skill.liangyuan = function(self,inclusive,request)
    return parse_action(self,"#liangyuanCard:.:")
end

sgs.ai_skill_use_func["#liangyuanCard"] = function(card,use,self,request)
    for _,pc in ipairs({"analeptic","peach"}) do
        local dc = canLyUse(self.player,pc)
        if dc and q(dc,"isAvailable",self.player) and q(self,"getCardsNum",dc:getClassName())<1 then
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
    if q(self.player,"getMark",toname.."liangyuan_lun")<1 and q(self,"getCardsNum",class_name)<1 then
        set_choice(self,"liangyuan",toname)
        return "#liangyuanCard:.:"..toname
    end
end

sgs.ai_skill_playerchosen.jisi = function(self,players,x,n)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp",true)
    local sks = scope(self,"jisi_invoke"):split("+")
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target) and not q(self,"isWeak",target) then
            if q(self.player,"hasSkill","huamu",true) and table.contains(sks,"liangyuan") then
                if q(self.player,"hasSkill","liangyuan",true) and table.contains(sks,"liangyuan") then
                    set_choice(self,"jisi","liangyuan")
                    return target
                end
                if q(self.player,"hasSkill","qianmeng",true) and table.contains(sks,"qianmeng") then
                    set_choice(self,"jisi","qianmeng")
                    return target
                end
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if q(self,"isEnemy",target) and q(self,"isWeak",target) then
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


sgs.ai_skill_invoke.keolyangkuang = function(self,data)
    local cur = self.room:getCurrent()
    return q(self,"isFriend",cur) or #self.friends<2
    or #self.enemies>0 and not q(self,"isEnemy",cur)
end

sgs.ai_skill_invoke.keolcihuang = function(self,data)
    local tr = scope(self,"keolcihuang")
    local from = data:toPlayer()
    for _,cn in sgs.list(tr:split("+"))do
        local dc = preview(self,cn)
        mutate(self,dc,"skill","keolcihuang")
        local d = use_card(self,dc)
        if d.card and d.to:contains(from) then
            set_choice(self,"keolcihuang",cn)
            return true
        end
    end
    for _,cn in sgs.list(tr:split("+"))do
        local dc = preview(self,cn)
        mutate(self,dc,"skill","keolcihuang")
        local d = use_card(self,dc)
        if d.card and d.to:contains(self.player) and q(self,"isFriend",from) then
            set_choice(self,"keolcihuang",cn)
            return true
        end
    end
end

sgs.ai_skill_discard.keolhetao = function(self,x,n)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    local use = scoped_struct(self,"keolhetao","use")
    for _,p in sgs.list(use.to)do
        if q(use.card,"isDamageCard") and q(self,"isEnemy",p) then
            for _,c in sgs.list(cards)do
                if q(self.player,"isJilei",c)
                or q(use.card,"getColor")~=q(c,"getColor")
                then continue end
                set_state(self,"keolhetaoTo",p)
                return {q(c,"getEffectiveId")}
            end
        end
    end
    for _,p in sgs.list(use.to)do
        if use.to:contains(use.from) and q(self,"isFriend",p)
        and not q(self,"isFriend",use.from) then
            for _,c in sgs.list(cards)do
                if q(self.player,"isJilei",c)
                or q(use.card,"getColor")~=q(c,"getColor")
                then continue end
                set_state(self,"keolhetaoTo",p)
                return {q(c,"getEffectiveId")}
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

sgs.ai_skill_invoke.keolshenli = function(self,data)
    local use = data:toCardUse()
    local n = 0
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
        if q(self.player,"canSlash",p, use.card, false) then
            if q(self,"isFriend",p) then
                n = n-1
            else
                n = n+1
            end
        end
    end
    return n>0
end

sgs.ai_skill_invoke.keolshishou = function(self,data)
    local from = data:toPlayer()
    return q(self,"isFriend",from)
end

function sgs.ai_weapon_value._keolsizhaojian(self,enemy)
    if enemy then return 6-q(enemy,"getHp") end
    return 3
end

sgs.ai_keep_value.Keolsizhaojian = 4.08



sgs.ai_skill_invoke.moujianxiong = function(self,data)
    return true
end

sgs.ai_skill_invoke.mouqingzheng = function(self,data)
    return true
end

sgs.ai_skill_use["@@mouqingzheng"] = function(self,prompt)
    local valid = {}
    local ids = {}
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
    local n = q(self.player,"getMark","mouqingzhengSuits")
    for _,c in sgs.list(cards)do
        if table.contains(ids,q(c,"getSuit")) then continue end
        table.insert(ids,q(c,"getSuit"))
    end
    local function func(a,b)
        local an,bn = 0,0
        for _,c in sgs.list(cards)do
            if a==q(c,"getSuit") then an = an+1 end
            if b==q(c,"getSuit") then bn = bn+1 end
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
        if table.contains(ids2,q(c,"getSuit"))
        then table.insert(valid,q(c,"getId")) end
    end
    if #valid<1 then return end
    self:sort(self.enemies,"handcard",true)
    for _,p in sgs.list(self.enemies)do
        if q(p,"getHandcardNum")>=#valid or q(self,"isWeak",p) and q(p,"getHandcardNum")>#valid/2 then
            set_state(self,"mouqingzhengTo",p)
            return "#mouqingzhengCard:"..table.concat(valid,"+")..":->"..q(p,"objectName")
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
        if table.contains(ids,q(c,"getSuit")) then continue end
        table.insert(ids,q(c,"getSuit"))
    end
    local function func(a,b)
        local an,bn = 0,0
        for _,c in sgs.list(cards)do
            if a==q(c,"getSuit") then an = an+1 end
            if b==q(c,"getSuit") then bn = bn+1 end
        end
        return an>bn
    end
    table.sort(ids,func)
    self:sortByKeepValue(cards,true) -- 按保留值排序
    for _,c in sgs.list(cards)do
        if ids[1]==q(c,"getSuit")
        then return q(c,"getId") end
    end
end

sgs.ai_skill_playerchosen.mouhujia = function(self,players,x,n)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
        if q(self,"isEnemy",target) and q(self,"isWeak",target)
        then return target end
    end
    local damage = scoped_struct(self,"mouhujiaDamage","damage")
    for _,target in sgs.list(sgs.reverse(destlist))do
        if q(self,"isFriend",target) and not q(self,"isWeak",target)
        and self:canDamageHp(damage.from,damage.card,target)
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if not q(self,"isFriend",target) and q(self,"isWeak")
        then return target end
    end
end

sgs.ai_fill_skill.moufanjian = function(self,inclusive,request)
    return parse_action(self,"#moufanjianCard:.:")
end

sgs.ai_skill_use_func["#moufanjianCard"] = function(card,use,self,request)
    for _,p in ipairs(self.friends_noself) do
        if not q(p,"faceUp") then
            local cards = self.player:getCards("h")
            cards = sgs.QList2Table(cards)
            self:sortByKeepValue(cards) -- 按保留值排序
            for _,c in ipairs(cards) do
                if self:wasPreviouslyPlannedCard(c)
                or q(self.player,"getMark",q(c,"getSuitString").."moufanjianUsed-PlayClear")>0
                then continue end
                use.card = parse_action(self,"#moufanjianCard:"..q(c,"getId")..":")
                use.to:append(p)
                self:setPriorityValue("moufanjianCard",8.8,"newgenerals")
                return
            end
        end
    end
    self:sort(self.enemies,"hp")
    for _,p in ipairs(self.enemies) do
        if q(p,"faceUp") then
            local cards = self.player:getCards("h")
            cards = sgs.QList2Table(cards)
            self:sortByKeepValue(cards) -- 按保留值排序
            for _,c in ipairs(cards) do
                if self:wasPreviouslyPlannedCard(c)
                or q(self.player,"getMark",q(c,"getSuitString").."moufanjianUsed-PlayClear")>0
                then continue end
                use.card = parse_action(self,"#moufanjianCard:"..q(c,"getId")..":")
                use.to:append(p)
                self:setPriorityValue("moufanjianCard",3.8,"newgenerals")
                return
            end
        end
    end
end

sgs.ai_use_value.moufanjianCard = 3.4
sgs.ai_use_priority.moufanjianCard = 3.2

sgs.ai_skill_choice.moufanjian = function(self,choices,data)
    local items = choices:split("+")
    if not q(self.player,"faceUp") then
        return items[3]
    end
    return items[math.random(1,2)]
end

sgs.ai_fill_skill.mourende = function(self,inclusive,request)
    set_state(self,"mourendeUse",nil)
    for _,p in sgs.list(pattern_names(self))do
        local dc = preview(self,p)
        if dc and q(dc,"getTypeId")==1 and q(self.player,"getMark","mRenWang-Clear")<1
        and q(self.player,"getMark","&mRenWang")>1 and q(self,"getCardsNum",dc:getClassName())<2 then
            mutate(self,dc,"skill","_mourende")
            if q(dc,"isAvailable",self.player) then
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

sgs.ai_skill_use_func["#mourendeCard"] = function(card,use,self,request)
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
        if q(friend,"objectName")==q(self.player,"objectName")
        or q(friend,"getMark","mourendeCardGet-PlayClear")>0
        then continue end
        if q(nc,"isAvailable",self.player) then
            if q(nc,"isDamageCard") or q(nc,"isKindOf","SingleTargetTrick") then
                local dummy_use = use_card(self,nc)
                if dummy_use.card and dummy_use.to:length()>0 then
                    if dummy_use.to:length()>1 or q(self,"isWeak",dummy_use.to:first())
                    or sgs.aiResponse[nc:getClassName()] and getCardsNum(sgs.aiResponse[nc:getClassName()],dummy_use.to:first(),self.player)<1
                    then continue end
                end
            elseif q(nc,"isKindOf","DelayedTrick") then
                if self:getEnemyNumBySeat(self.player,friend)>0
                and use_card(self,nc).card then continue end
            end
        end
        local ids = {}
        if q(friend,"hasSkill","enyuan")
        and #cards>=1 and not AIValue.sameLegacyIdentity(cards[1],nc)
        then table.insert(ids,cards[1]:getEffectiveId()) end
        table.insert(ids,q(nc,"getEffectiveId"))
        use.card = parse_action(self,"#mourendeCard:"..table.concat(ids,"+")..":")
        use.to:append(friend)
        return
    end
    if notFound and q(self.player,"isWounded")
    and q(self.player,"getMark","&mRenWang")<4
    and q(self.player,"getCardCount")>4 then
        cards = sgs.QList2Table(self.player:getCards("he"))
        self:sortByUseValue(cards,true)
        for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
            if not q(self,"isFriend",p) and hasManjuanEffect(p)
            and q(p,"getMark","mourendeCardGet-PlayClear")<1 then
                local ids = {}
                for _,c in ipairs(cards)do
                    if not isCard("Peach,ExNihilo",c,self.player)
                    then table.insert(ids,q(c,"getEffectiveId")) end
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
            if not q(self,"isEnemy",p) and q(p,"getMark","mourendeCardGet-PlayClear")<1 then
                local ids = {}
                for _,c in ipairs(cards)do
                    if not isCard("Peach,ExNihilo",c,self.player)
                    then table.insert(ids,q(c,"getEffectiveId")) end
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
            if q(p,"getMark","&mourdTOzw")<1 then
                local ids = {}
                for _,c in ipairs(cards)do
                    if not isCard("Peach,ExNihilo",c,self.player)
                    then table.insert(ids,q(c,"getEffectiveId")) break end
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
            if get_state(self,"mourendeUse").q(card,"objectName")==q(c,"objectName")
            then return q(c,"getId") end
        end
    end
    self:sortByKeepValue(cards,true) -- 按保留值排序
    for _,c in sgs.list(cards)do
        local dc = preview(self,q(c,"objectName"))
        mutate(self,dc,"skill","_mourende")
        if q(dc,"isAvailable",self.player) then
            local d = use_card(self,dc)
            if d.card then
                set_state(self,"mourendeUse",d)
                return q(c,"getId")
            end
        end
    end
end

sgs.ai_skill_use["@@mourende"] = function(self,prompt)
    local dummy = get_state(self,"mourendeUse")
    if dummy.card then
        local tos = {}
        for _,p in sgs.list(dummy.to)do
            table.insert(tos,q(p,"objectName"))
        end
        return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_guhuo_card.mourende = function(self,toname,class_name)
    if q(self,"getCardsNum",class_name)<1 or q(self.player,"getMark","&mRenWang")>4 then
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

sgs.ai_fill_skill.mouzhangwu = function(self,inclusive,request)
    return q(self.player,"getMark","mRenWang-Clear")>0
    and parse_action(self,"#mouzhangwuCard:.:")
end

sgs.ai_skill_use_func["#mouzhangwuCard"] = function(card,use,self,request)
    local tos = self.room:getOtherPlayers(self.player)
    local n = 0
    for _,p in sgs.qlist(tos)do
        if q(p,"getMark","&mourdTOzw")>0 then
            n = n+1
        end
    end
    local x = scope(self,"TurnLengthCount")
    if x>3 and n>tos:length()/2 or x>2 and q(self,"isWeak") and n>=tos:length()/2 then
        use.card = card
    end
end

sgs.ai_use_value.mouzhangwuCard = 4.5
sgs.ai_use_priority.mouzhangwuCard = 7.7

sgs.ai_skill_use["@@moujijiang"] = function(self,prompt)
    local tos = {}
    self:sort(self.enemies,"hp")
    for _,ep in sgs.list(self.enemies)do
        for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
            if q(p,"getKingdom")=="shu" and q(p,"getHp")>=q(self.player,"getHp")
            and q(self,"isFriend",p) and q(p,"inMyAttackRange",ep) then
                table.insert(tos,q(ep,"objectName"))
                table.insert(tos,q(p,"objectName"))
                return "#moujijiangCard:.:->"..table.concat(tos,"+")
            end
        end
    end
    for _,ep in sgs.list(self.enemies)do
        for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
            if q(p,"getKingdom")=="shu" and q(p,"getHp")>=q(self.player,"getHp")
            and q(p,"inMyAttackRange",ep) then
                table.insert(tos,q(ep,"objectName"))
                table.insert(tos,q(p,"objectName"))
                return "#moujijiangCard:.:->"..table.concat(tos,"+")
            end
        end
    end
    for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
        if q(self,"isFriend",ep) then continue end
        for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
            if q(p,"getKingdom")=="shu" and q(p,"getHp")>=q(self.player,"getHp")
            and q(p,"inMyAttackRange",ep) then
                table.insert(tos,q(ep,"objectName"))
                table.insert(tos,q(p,"objectName"))
                return "#moujijiangCard:.:->"..table.concat(tos,"+")
            end
        end
    end
end

sgs.ai_skill_choice.moujijiang = function(self,choices,data)
    local items = choices:split("+")
    local use = data:toCardUse()
    if q(self,"isFriend",use.to:first()) and q(self,"isWeak",use.to:first()) then
        return items[2]
    end
    return items[1]
end

sgs.ai_skill_playerchosen["mouluoshen"] = function(self, targets)
    local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))

    local max_count, max_start = 0, nil
    local cur_count, cur_start = 0, nil

    for i, p in ipairs(players) do
        if q(self,"doDisCard",p, "h") then
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
        if q(self,"doDisCard",target, "h") then
            table.insert(valid_targets, target)
        end
    end

    local first_target = max_start and players[max_start] or nil

    return first_target
end

sgs.ai_view_as.mouqingguo = function(card,player,card_place)
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    if q(card,"isBlack") and card_place==sgs.Player_PlaceHand then
        return ("jink:mouqingguo[%s:%s]=%d"):format(suit,number,card_id)
    end
end

function sgs.ai_cardneed.mouqingguo(to,card)
    return q(to,"getHandcardNum")<2 and q(card,"isBlack")
end


sgs.ai_fill_skill.mouhuoji = function(self,inclusive,request)
    return parse_action(self,"#mouhuojiCard:.:")
end

sgs.ai_skill_use_func["#mouhuojiCard"] = function(card,use,self,request)
    self:sort(self.enemies,"hp")
    local max_value = 0
    local target = nil
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        local value = 0
        if q(self,"damageIsEffective",p, sgs.DamageStruct_Fire, self.player) then
            if q(self,"isEnemy",p) and q(self,"canDamage",p,self.player,nil) then
                value = value + 1
                if q(self,"isWeak",p) then
                    value = value + 1
                end
            elseif q(self,"isFriend",p) then
                value = value - 1
                if q(self,"isWeak",p) then
                    value = value - 1
                end
            end
            for _, q in sgs.qlist(self.room:getOtherPlayers(p)) do
                if q(q,"getKingdom") == q(p,"getKingdom") then
                    if q(self,"damageIsEffective",q, sgs.DamageStruct_Fire, self.player) then
                        if q(self,"isEnemy",q) and q(self,"canDamage",q,self.player,nil) then
                            value = value + 1
                            if q(self,"isWeak",q) then
                                value = value + 1
                            end
                        elseif q(self,"isFriend",q) then
                            value = value - 1
                            if q(self,"isWeak",q) then
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
        if q(card,"isKindOf","Slash") and math.random() < 0.4 then
            return q(card,"getEffectiveId")
        end
    end
    for _, card in ipairs(cards) do
        if q(card,"isKindOf","BasicCard") and math.random() < 0.3 then
            return q(card,"getEffectiveId")
        end
    end
    for _, card in ipairs(cards) do
        if q(card,"isKindOf","TrickCard") and math.random() < 0.4 then
            return q(card,"getEffectiveId")
        end
    end
    if #cards > 0 then
        return cards[1]:getEffectiveId()
    end
end

sgs.ai_skill_invoke.moukanpo = function(self, data)
    local use = data:toCardUse()
    if q(self,"isEnemy",use.from) then return true end
    return false
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
    if q(to,"hasSkill","mouguanxing",true) then
        if to:getPile("&mouStarsXing"):isEmpty() then
            return 1
        end
    end
end
sgs.ai_card_priority.moukongcheng = function(self,card,v)
    return self.player:getPile("&mouStarsXing"):contains(q(card,"getEffectiveId")) and -1
end


sgs.ai_fill_skill.mouguose = function(self,inclusive,request)
    return parse_action(self,"#mouguoseCard:.:")
end

sgs.ai_skill_use_func["#mouguoseCard"] = function(card,use,self,request)
    self:sort(self.friends)

    self:setPriorityValue("mouguoseCard",5.5,"newgenerals")
    for _,friend in ipairs(self.friends)do
        if q(friend,"containsTrick","indulgence")
        and q(self,"willSkipPlayPhase",friend)
        and not q(friend,"hasSkills","shensu|qingyi|qiaobian")
        and (q(self,"isWeak",friend) or q(self,"getOverflow",friend)>1)
        then
            for _,c in sgs.list(friend:getJudgingArea())do
                if q(c,"isKindOf","Indulgence")
                and q(self.player,"canDiscard",friend,q(c,"getEffectiveId"))
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
        if q(acard,"getSuit")==sgs.Card_Diamond
        and ((q(self,"getUseValue",acard)<sgs.ai_use_value.Indulgence))
        then
            local indulgence = preview(self,"Indulgence")
            mutate(self,indulgence,"skill","mouguose")
            mutate(self,indulgence,"add",acard)
            if not q(self.player,"isLocked",indulgence) then
                local dummy_use = use_card(self,indulgence, dummy())
                if dummy_use.card then
                    use.card = parse_action(self,"indulgence:mouguose[no_suit:0]="..q(acard,"getEffectiveId"))
                    self:setPriorityValue("mouguoseCard",self:getPriorityValue("Indulgence"),"newgenerals")
                    use.to = dummy_use.to
                    return
                end
            end
        end
    end
    for _,friend in ipairs(self.friends)do
        if q(friend,"containsTrick","indulgence") then
            for _,c in sgs.list(friend:getJudgingArea())do
                if q(c,"isKindOf","Indulgence") and q(self.player,"canDiscard",friend,q(c,"getEffectiveId")) then
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
    return q(card,"getSuit")==sgs.Card_Diamond
end

sgs.mouguose_suit_value = {
    diamond = 3.9
}


sgs.ai_skill_use["@@mouliuli"] = function(self,prompt,method)
    local others = self.room:getOtherPlayers(self.player)
    local slash = preview(self,"slash")
    others = sgs.QList2Table(others)
    local source
    for _,player in ipairs(others)do
        if q(player,"hasFlag","mouliuliUseFrom") then
            source = player
            break
        end
    end
    self:sort(self.enemies,"defense")

    local doLiuli = function(who)
        if not q(self,"isFriend",who) and q(who,"hasSkills","leiji|nosleiji|olleiji")
            and (q(self,"hasSuit","spade",true,who) or q(who,"getHandcardNum")>=3)
            and (getKnownCard(who,self.player,"Jink",true)>=1 or q(self,"hasEightDiagramEffect",who)) then
            return "."
        end

        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _,card in ipairs(cards)do
            if not q(self.player,"isCardLimited",card,method) and q(self.player,"canSlash",who) then
                if q(self,"isFriend",who) and not (isCard("Peach",card,self.player) or isCard("Analeptic",card,self.player)) then
                    return "#mouliuliCard:"..q(card,"getEffectiveId")..":->"..q(who,"objectName")
                else
                    return "#mouliuliCard:"..q(card,"getEffectiveId")..":->"..q(who,"objectName")
                end
            end
        end

        local cards = self.player:getCards("e")
        cards=sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _,card in ipairs(cards)do
            local range_fix = 0
            if q(card,"isKindOf","Weapon") then range_fix = range_fix+sgs.weapon_range[card:getClassName()]-q(self.player,"getAttackRange",false) end
            if q(card,"isKindOf","OffensiveHorse") then range_fix = range_fix+1 end
            if not q(self.player,"isCardLimited",card,method) and q(self.player,"canSlash",who,nil,true,range_fix) then
                return "#mouliuliCard:"..q(card,"getEffectiveId")..":->"..q(who,"objectName")
            end
        end
        return "."
    end

    for _,enemy in ipairs(self.enemies)do
        if not (source and q(source,"objectName")==q(enemy,"objectName")) then
            local ret = doLiuli(enemy)
            if ret~="." then return ret end
        end
    end

    for _,player in ipairs(others)do
        if q(self,"objectiveLevel",player)==0 and not (source and q(source,"objectName")==q(player,"objectName")) then
            local ret = doLiuli(player)
            if ret~="." then return ret end
        end
    end


    self:sort(self.friends_noself,"defense")
    self.friends_noself = sgs.reverse(self.friends_noself)


    for _,friend in ipairs(self.friends_noself)do
        if not q(self,"slashIsEffective",slash,friend) or self:findLeijiTarget(friend,50,source) then
            if not (source and q(source,"objectName")==q(friend,"objectName")) then
                local ret = doLiuli(friend)
                if ret~="." then return ret end
            end
        end
    end

    for _,friend in ipairs(self.friends_noself)do
        if source~=friend and q(self,"needToLoseHp",friend,source,preview(self)) then
                local ret = doLiuli(friend)
                if ret~="." then return ret end
            end
        end

    if (q(self,"isWeak") or q(self,"ajustDamage",source,nil,1,slash)>1) and q(source,"hasWeapon","Axe") and q(source,"getHandcardNum")+#source:getEquips()>2
      and not self:getCardId("Peach") and not self:getCardId("Analeptic") then
        for _,friend in ipairs(self.friends_noself)do
            if not q(self,"isWeak",friend) then
                if not (source and q(source,"objectName")==q(friend,"objectName")) then
                    local ret = doLiuli(friend)
                    if ret~="." then return ret end
                end
            end
        end
    end

    if (q(self,"isWeak") or q(self,"ajustDamage",source,nil,1,slash)>1) and not self:getCardId("Jink") then
        for _,friend in ipairs(self.friends_noself)do
            if not q(self,"isWeak",friend) or (q(self,"hasEightDiagramEffect",friend) and getCardsNum("Jink",friend)>=1) then
                if not (source and q(source,"objectName")==q(friend,"objectName")) then
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
        if lord and q(self,"isFriend",lord) and q(lord,"objectName")~=q(self.player,"objectName") then
            return lord
        end
    end

    local AssistTarget = self:AssistTarget()
    if AssistTarget and not q(self,"willSkipPlayPhase",AssistTarget) then
        return AssistTarget
    end

    self:sort(self.friends_noself,"handcard")
    for _,target in ipairs(self.friends_noself)do
        return target
    end
    return nil
end
sgs.ai_playerchosen_intention.mouliuli = -40



sgs.ai_fill_skill.mouqixi = function(self,inclusive,request)
    return #self.enemies>0
    and parse_action(self,"#mouqixiCard:.:")
end

sgs.ai_skill_use_func["#mouqixiCard"] = function(card,use,self,request)
    for _,enemy in ipairs(self.enemies)do
        if q(self,"doDisCard",enemy, "he") then
            use.card = parse_action(self,"#mouqixiCard:.:")
            use.to:append(enemy)
            return
        end
    end
end

sgs.ai_use_value.mouqixiCard = 4.5
sgs.ai_use_priority.mouqixiCard = sgs.ai_use_priority.Dismantlement
sgs.ai_card_intention.mouqixiCard = 80
sgs.ai_skill_invoke.mouqixi = true

sgs.ai_fill_skill.moufenwei = function(self,inclusive,request)
    return parse_action(self,"#moufenweiCard:.:")
end

sgs.ai_skill_use_func["#moufenweiCard"] = function(card,use,self,request)
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
        table.insert(use_cards, q(acard,"getEffectiveId"))
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

sgs.ai_skill_choice.moufenwei = function(self, choices, data)
    local use = data:toCardUse()
    local items = choices:split("+")
    if table.contains(items, "2") and q(use.card,"isDamageCard") then
        return "2"
    end
    return items[math.random(1, #items)]
end



sgs.ai_fill_skill.moulianhuan = function(self,inclusive,request)
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
        if q(acard,"getSuit")==sgs.Card_Club then
            local shouldUse = true
            if q(self,"getUseValue",acard)>sgs.ai_use_value.IronChain and q(acard,"getTypeId")==sgs.Card_TypeTrick then
                local dummy_use = dummy()
                self:useTrickCard(acard,dummy_use)
                if dummy_use.card then shouldUse = false end
            end
            if q(acard,"getTypeId")==sgs.Card_TypeEquip then
                local dummy_use = dummy()
                self:useEquipCard(acard,dummy_use)
                if dummy_use.card then shouldUse = false end
            end
            if shouldUse and (not slash or q(slash,"getEffectiveId")~=q(acard,"getEffectiveId")) then
                card = acard
                break
            end
        end
    end

    if not card then return nil end
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    local card_str = ("iron_chain:moulianhuan[club:%s]=%d"):format(number,card_id)
    local skillcard = parse_action(self,card_str)
    assert(skillcard)
    return skillcard
end

sgs.ai_cardneed.moulianhuan = function(to,card)
    return q(card,"getSuit")==sgs.Card_Club and q(to,"getHandcardNum")<=2
end

ai_audited_aliases.register{id="ai_skill_invoke.mouniepan",defer_canonical=true,self_index=1,registry="ai_skill_invoke",path={"mouniepan"},canonical_registry="ai_skill_invoke",canonical_path={"niepan"}}



sgs.ai_fill_skill.mouxuanhuo = function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards,nil,true)
    for i,c in sgs.list(cards)do
        for it,ct in sgs.list(q(self,"getPriorTurnUseCards"))do
            if q(c,"getEffectiveId")~=q(ct,"getEffectiveId")
            and q(c,"getSuit")==q(ct,"getSuit")
            and q(ct,"isKindOf","Slash")
            then
                return parse_action(self,"#mouxuanhuoCard:"..q(c,"getEffectiveId")..":")
            end
        end
    end
    for i,c in sgs.list(cards)do
        if q(c,"isKindOf","EquipCard")
        and #self.enemies>0
        and i<#cards/2
        then
            return parse_action(self,"#mouxuanhuoCard:"..q(c,"getEffectiveId")..":")
        end
    end
end

sgs.ai_skill_use_func["#mouxuanhuoCard"] = function(card,use,self,request)
    self:sort(self.enemies)
    for _, enemy in ipairs(self.enemies) do
        if q(enemy,"getMark","&mXuan+#"..q(self.player,"objectName")) == 0 then
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

sgs.ai_fill_skill.moulijian = function(self,inclusive,request)
    if q(self.player,"isNude") or self.room:getAlivePlayers():length()<3 then
        return
    end
    local n = q(self.player,"getHandcardNum") + self.player:getEquips():length() - 1
    if n > 1 then return parse_action(self,"#moulijianCard:.:") end
end


sgs.ai_skill_use_func["#moulijianCard"] = function(card,use,self,request)
    local lord = self.room:getLord()
    local duel = preview(self,"duel")
    local findFriend_maxSlash = function(self,first)
        local maxSlash = 0
        local friend_maxSlash
        local nos_fazheng,fazheng
        for _,friend in ipairs(self.friends_noself)do
            if q(self,"hasTrickEffective",duel,first,friend) then
                if q(friend,"hasSkill","nosenyuan") and q(friend,"getHp")>1 then nos_fazheng = friend end
                if q(friend,"hasSkill","enyuan") and q(friend,"getHp")>1 then fazheng = friend end
                if (getCardsNum("Slash",friend)>maxSlash) then
                    maxSlash = getCardsNum("Slash",friend)
                    friend_maxSlash = friend
                end
            end
        end

        if friend_maxSlash then
            local safe = false
            if self:hasSkills("neoganglie|vsganglie|fankui|enyuan|ganglie|nosenyuan",first) and not self:hasSkills("wuyan|noswuyan",first) then
                if (q(first,"getHp")<=1 and q(first,"getHandcardNum")==0) then safe = true end
            elseif (getCardsNum("Slash",friend_maxSlash)>=getCardsNum("Slash",first)) then safe = true end
            if safe then return friend_maxSlash end
        else self:log("unfound")
        end
        if nos_fazheng or fazheng then  return nos_fazheng or fazheng end       --备用友方，各种恶心的法正
        return nil
    end
    local n = q(self.player,"getHandcardNum") + self.player:getEquips():length() + 1
    if n < 2 then return end
    local targets = {}
    if self.role=="rebel" or (self.role=="renegade" and role_count(self,"loyalist")+1>role_count(self,"rebel")) then

        if lord and not q(lord,"isNude") and q(lord,"objectName")~=q(self.player,"objectName") then      -- 优先离间1血忠和主
            self:sort(self.enemies,"handcard")
            local e_peaches = 0
            local loyalist

            for _,enemy in ipairs(self.enemies)do
                e_peaches = e_peaches+getCardsNum("Peach",enemy)
                if q(enemy,"getHp")==1 and q(self,"hasTrickEffective",duel,enemy,lord) and q(enemy,"objectName")~=q(lord,"objectName") and not loyalist then
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
        if shenguanyu and q(shenguanyu,"objectName")~=q(self.player,"objectName") then
            if self.role=="rebel" and lord and q(lord,"objectName")~=q(self.player,"objectName") and q(shenguanyu,"objectName")~=q(lord,"objectName")
                and not q(self,"hasJueqingEffect",lord,shenguanyu) and q(self,"hasTrickEffective",duel,shenguanyu,lord) then
                table.insert(targets, shenguanyu)
            elseif q(self,"isEnemy",shenguanyu) and #self.enemies>=2 then
                for _,enemy in ipairs(self.enemies)do
                    if q(enemy,"objectName")~=q(shenguanyu,"objectName") and not q(enemy,"isLocked",duel)
                        and q(self,"hasTrickEffective",duel,shenguanyu,enemy) then
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
            if  not q(enemy,"hasSkills","wuyan|noswuyan") then
                if q(enemy,"hasSkill","kongcheng") and q(enemy,"isKongcheng") then zhugeliang_kongcheng = enemy
                elseif q(enemy,"hasSkill","jieming") then xunyu = enemy
                else
                    for _,anotherenemy in ipairs(self.enemies)do
                        if  q(anotherenemy,"objectName")~=q(enemy,"objectName") then
                            if #males==0 and q(self,"hasTrickEffective",duel,enemy,anotherenemy) then
                                if not (q(enemy,"hasSkill","hunzi") and q(enemy,"getMark","hunzi")<1 and q(enemy,"getHp")==2) then
                                    table.insert(males,enemy)
                                else
                                    table.insert(others,enemy)
                                end
                            end
                            if #males==1 and q(self,"hasTrickEffective",duel,males[1],anotherenemy) then
                                if not q(anotherenemy,"hasSkills","nosjizhi|jizhi|jiang") then
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
            if isLord(males[1]) and q(self.room,"getTurnCount")<=1 and self.role=="rebel" and q(self.player,"aliveCount")>=3 then
                local p_slash,max_p,max_pp = 0,nil,nil
                for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
                    if not q(self,"isFriend",p) and q(p,"objectName")~=males[1]:objectName() and q(self,"hasTrickEffective",duel,males[1],p) and not q(p,"isLocked",duel)
                        and p_slash<getCardsNum("Slash",p) then
                        if q(p,"getKingdom")==males[1]:getKingdom() then
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
            elseif xunyu and not q(xunyu,"isLocked",duel) then
                if getCardsNum("Slash",males[1])<1 then
                    table.insert(males,xunyu)
                else
                    local drawcards = 0
                    for _,enemy in ipairs(self.enemies)do
                        local x = q(enemy,"getMaxHp")>q(enemy,"getHandcardNum") and math.min(5,q(enemy,"getMaxHp")-q(enemy,"getHandcardNum")) or 0
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
            if zhugeliang_kongcheng and q(self,"hasTrickEffective",duel,first,zhugeliang_kongcheng) then
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
        table.insert(use_cards, q(acard,"getEffectiveId"))
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

sgs.ai_fill_skill.moumingce = function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
    return parse_action(self,"#moumingceCard:"..cards[1]:getEffectiveId()..":")
end

sgs.ai_skill_use_func["#moumingceCard"] = function(card,use,self,request)
    local target
    local friends = self.friends_noself
    self:sort(self.enemies,"defense")
    for _,friend in ipairs(friends)do
        if q(self,"canDraw",friend, self.player) and hasZhaxiangEffect(friend) then
            target = friend
            break
        end
    end
    if not target then
        self:sort(friends,"defense")
        for _,friend in ipairs(friends)do
            if q(self,"canDraw",friend, self.player) then
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

sgs.ai_skill_choice.moumingce = function(self,choices)
    local chengong = self.room:getCurrent()
    if not q(self,"isFriend",chengong) then return "2" end
    if (hasZhaxiangEffect(self.player) or math.random() < 0.4) and q(self,"isFriend",chengong) and q(self.player,"getHp") + q(self,"getAllPeachNum") - 1 > 0 then return "1" end
    return "2"
end

sgs.ai_skill_playerchosen.moumingce = function(self,targets)
    targets = sgs.QList2Table(targets)
    return self:findPlayerToDamage(q(self.player,"getMark","&mouCeC"),self.player,"N",targets)[1]
end
sgs.ai_ajustdamage_to.mouzhichi = function(self,from,to,card,nature)
    if q(to,"getMark","&mouzhichi-Clear")>0
    then return -99 end
end

sgs.ai_skill_discard.mobilemoutiandu = function(self, discard_num, min_num, optional, include_equip)
    local cards = sgs.QList2Table(self.player:getHandcards())
    local to_discard = {}
    for _,fcard in sgs.list(cards)do
        if #to_discard>=min_num then break end
        for _,m in sgs.list(self.player:getMarkNames())do
            if q(self.player,"getMark",m)>0 and m:startsWith("&mobilemoutiandu+:") and m:contains(q(fcard,"getSuitString").."_char") then
                if isCard("ArcheryAttack",fcard,self.player)
                or isCard("ArcheryAttack",fcard,self.player)
                or isCard("ExNihilo",fcard,self.player)
                or isCard("Peach",fcard,self.player)
                then continue end
                if not q(self.player,"isCardLimited",fcard,sgs.Card_MethodDiscard) then
                    table.insert(to_discard,q(fcard,"getEffectiveId"))
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
        if not q(self.player,"isCardLimited",fcard,sgs.Card_MethodDiscard) then
            table.insert(to_discard,q(fcard,"getEffectiveId"))
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
        c = preview(self,q(c,"objectName"))
        mutate(self,c,"skill","_mobilemoutiandu")
        local d = use_card(self,c)
        set_state(self,"mobilemoutiandu_use",d)
        if d.card and d.to
        then return id end
    end
end

sgs.ai_skill_use["@@mobilemoutiandu!"] = function(self,prompt)
    local dummy = get_state(self,"mobilemoutiandu_use")
    if dummy.card and dummy.to then
        local tos = {}
        for _,p in sgs.list(dummy.to)do
            table.insert(tos,q(p,"objectName"))
        end
        return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_can_damagehp.mobilemouyiji = function(self,from,card,to)
    return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
    and q(self,"canLoseHp",from,card,to)
end

sgs.ai_skill_askforyiji.mobilemouyiji = function(self,card_ids,tos)
    return sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
end

sgs.ai_skill_use["@@moukurou"] = function(self,prompt)
    if q(self.player,"getHujia") > 4 then
        return "."
    end
    local ids = {}
    local target
    local use_card
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    for _,c in sgs.list(cards)do
        if (q(c,"isKindOf","Peach")
        or q(c,"isKindOf","Analeptic")) and q(self.player,"getHp") + q(self,"getAllPeachNum") - 3 > 0 then
            use_card = c
            break
        end
    end
    if not use_card then
        use_card = cards[1]
    end
    self:sort(self.friends_noself,"defense")
    for _,friend in ipairs(self.friends_noself)do
        if q(self,"canDraw",friend, self.player) then
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
    if use_card and target and q(self.player,"getHp") + q(self,"getAllPeachNum") - 1 > 0 then
        return "#moukurouCard:"..q(use_card,"getEffectiveId")..":->"..q(target,"objectName")
    end
    return "."
end


sgs.ai_fill_skill.moujushou = function(self,inclusive,request)
    local cards = self.player:getCards("h")
    cards = self:sortByKeepValue(cards,nil,"j")
    local toids = {}
    local x = math.min(5 - q(self.player,"getHujia"), 2)
    for _,c in sgs.list(cards)do
        table.insert(toids,q(c,"getEffectiveId"))
        if #toids >= x then break end
    end
    if #toids > 0 then
        return parse_action(self,"#moujushouCard:"..table.concat(toids,"+")..":")
    end
end

sgs.ai_skill_use_func["#moujushouCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value["moujushouCard"] = 9.4
sgs.ai_use_priority["moujushouCard"] = 2

sgs.ai_can_damagehp.moujushou = function(self,from,card,to)
    return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)+q(self.player,"getHujia")>0
    and q(self,"canLoseHp",from,card,to) and not q(to,"faceUp")
end
sgs.ai_fill_skill.moujiewei = function(self,inclusive,request)
    return parse_action(self,"#moujieweiCard:.:")
end

sgs.ai_skill_use_func["#moujieweiCard"] = function(card,use,self,request)
    self:sort(self.enemies,"handcard")
    self.enemies = sgs.reverse(self.enemies)
    for _,p in sgs.list(self.enemies)do
        if q(self,"doDisCard",p,"h", true) then
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
    and q(card,"isKindOf","TrickCard")
    then v = v+3 end
end
ai_audited_aliases.register{id="ai_cardneed.moujizhi",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"moujizhi"},canonical_registry="ai_cardneed",canonical_path={"jizhi"}}

sgs.ai_fill_skill.mouqicai = function(self,inclusive,request)
    return parse_action(self,"#mouqicaiCard:.:")
end
sgs.ai_skill_use_func["#mouqicaiCard"] = function(card,use,self,request)
    local use_card
    for _,id in sgs.qlist(scope_list(self,"mouqicaiDiscardPile"))do
        if q(self.player,"getMark","f_mode_doudizhu")>0 then
            if printed_card(self,id):isKindOf("Armor")
            and q(self.player,"getMark","mouqicaiArmor"..printed_card(self,id):objectName()) < 1
            then use_card = nil break end
    elseif printed_card(self,id):isKindOf("EquipCard") then use_card = nil break end
    end
    for _,h in sgs.qlist(self.player:getHandcards())do
        if q(self.player,"getMark","f_mode_doudizhu")>0
        then if q(h,"isKindOf","Armor") then use_card = h break end
        elseif q(h,"isKindOf","EquipCard") then use_card = h break end
    end
    self:sort(self.friends_noself,"handcard")
    self.friends_noself = sgs.reverse(self.friends_noself)
    if use_card then card = parse_action(self,"#mouqicaiCard:"..q(use_card,"getEffectiveId")..":") end
    for _,p in sgs.list(self.friends_noself)do
        if self:loseEquipEffect(p) or self:hasSkills(sgs.need_equip_skill,p) then
            if q(p,"hasEquipArea") or (use_card and q(p,"hasEquipArea",q(use_card,"getEquipSlot"))) then
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
        if not self:loseEquipEffect(p) and not self:hasSkills(sgs.need_equip_skill,p) and q(p,"getMark","&mouQI") == 0 then
            if q(p,"hasEquipArea") or (use_card and q(p,"hasEquipArea",q(use_card,"getEquipSlot"))) then
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
            if q(p,"hasEquipArea") or (use_card and q(p,"hasEquipArea",q(use_card,"getEquipSlot"))) then
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
            if q(c,"isRed") then
                table.insert(red_cards,q(c,"getEffectiveId"))
            else
                table.insert(black_cards,q(c,"getEffectiveId"))
            end
        end
        if #red_cards>#black_cards then
            return red_cards[1]
        elseif #black_cards>#red_cards then
            return black_cards[1]
        elseif self.player:getPile("mouResponsibility"):isEmpty() then
            for _,c in ipairs(handcards)do
                return q(c,"getEffectiveId")
            end
        end
    else
        local ren = known_card(self,self.player:getPile("mouResponsibility"):first())
        for _,c in ipairs(handcards)do
            if q(self,"getCardsNum","Nullification")>0 and q(c,"isKindOf","TrickCard") then
                if q(ren,"isKindOf","TrickCard") then
                    if not q(c,"isKindOf","Nullification") and self:cardNeed(ren)>self:cardNeed(c) then return q(c,"getEffectiveId") end
                else
                    if not q(c,"isKindOf","Nullification") or q(self,"getCardsNum","Nullification")>1 then return q(c,"getEffectiveId") end
                end
            end
            if q(c,"isKindOf","BasicCard") then
                if q(ren,"isKindOf","BasicCard") then
                    if self:cardNeed(ren)>self:cardNeed(c) then return q(c,"getEffectiveId") end
                else
                    if q(c,"isKindOf","Slash") then return q(c,"getEffectiveId") end
                    if q(c,"isKindOf","Jink") and q(self,"getCardsNum","Jink")>1 then return q(c,"getEffectiveId") end
                    if q(c,"isKindOf","Analeptic") and q(self,"getCardsNum","Analeptic")>1 then return q(c,"getEffectiveId") end
                    if q(c,"isKindOf","Peach") and q(self,"getCardsNum","Peach")>1 then return q(c,"getEffectiveId") end
                end
            end
        end
        if self:cardNeed(ren)>self:cardNeed(handcards[1]) then return handcards[1]:getEffectiveId() end
        return {}
    end
    return {}
end

sgs.ai_fill_skill.mouzhenliang = function(self,inclusive,request)
    if self.player:getPile("mouResponsibility"):length()>0 then
        return parse_action(self,"#mouzhenliang:.:")
    end
end

sgs.ai_skill_use_func["#mouzhenliang"] = function(card,use,self,request)
    self:sort(self.enemies,"hp")
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByUseValue(cards,true)
    local target = nil
    local use_card_num = 0
    local use_card = {}
    for _,enemy in ipairs(self.enemies)do
        use_card_num = math.max(1,math.abs(q(enemy,"getHp")-q(self.player,"getHp")))
        if use_card_num>2 then continue end
        use_card = {}
        if q(self.player,"inMyAttackRange",enemy) and q(self,"canDamage",enemy,self.player) then
            for _,c in ipairs(cards)do
                if q(c,"sameColorWith",known_card(self,self.player:getPile("mouResponsibility"):first())) and not q(c,"isKindOf","Peach") then
                    table.insert(use_card,q(c,"getEffectiveId"))
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

sgs.ai_fill_skill.mouliangzhu = function(self,inclusive,request)
    return parse_action(self,"#mouliangzhuCard::")
end

sgs.ai_skill_use_func["#mouliangzhuCard"] = function(card,use,self,request)
    self:sort(self.friends_noself,"hp")
    self.friends_noself = sgs.reverse(self.friends_noself)
    for _,p in sgs.list(self.friends_noself)do
        if q(self,"doDisCard",p, "e", true) then
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
        if q(self,"doDisCard",p, "e", true) then
            use.card = card
            if use.to then
                use.to:append(p)
            end
            return
        end
    end
    for _,p in sgs.list(self.friends_noself)do
        if q(p,"hasEquip") then
            use.card = card
            if use.to then
                use.to:append(p)
            end
            return
        end
    end
    for _,p in sgs.list(self.enemies)do
        if q(p,"hasEquip") then
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
sgs.ai_skill_choice["moujieyin"] = function(self, choices, data)
    local items = choices:split("+")
    local target = data:toPlayer()
    if q(self,"isFriend",target) and table.contains(items, "1") and not q(self,"isWeak") then
        return "1"
    end
    return items[math.random(1,#items)]
end


sgs.ai_skill_playerchosen.mouxiaoji = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
    for _, enemy in ipairs(self.enemies) do
        if q(self,"doDisCard",enemy, "je") then
            return enemy
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if (self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty())
            or (q(self,"needToThrowArmor",friend) and friend:getArmor()) or q(self,"doDisCard",friend, "je") then
            return friend
        end
    end
    return nil
end

ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.mouxiaoji",defer_canonical=true,self_index=1,registry="ai_choicemade_filter",path={"cardChosen","mouxiaoji"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","dismantlement"}}

sgs.ai_use_revises.mouxiaoji = function(self,card,use)
    if q(card,"isKindOf","EquipCard") and self:evaluateArmor(card)>-5 and q(self.player,"getKingdom") == "wu"
    then use.card = card return true end
end

sgs.ai_fill_skill.mouwusheng = function(self,inclusive,request)
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards, nil, true)
    for _, h in sgs.list(cards) do
        for c, pn in sgs.list(RandomList(pattern_names(self))) do
            c = preview(self,pn)
            if c and q(c,"isKindOf","Slash")
            then
                mutate(self,c,"skill","mouwusheng")
                mutate(self,c,"add",h)
                if q(c,"isAvailable",self.player)
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
    local slashcount = q(self,"getCardsNum","Slash")
    if slashcount>0  then
        local slash = self:getCard("Slash")
        assert(slash)
        local dummy_use = q(self,"withOwnerRange","InfinityAttackRange","mouwusheng",function()
            return use_card(self,slash,r44_range_dummy(99))
        end)
        if dummy_use.card and dummy_use.to:length() > 0 then
            for _,enemy in sgs.qlist(dummy_use.to) do
                if not q(self.player,"inMyAttackRange",enemy) and targets:contains(enemy) then
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
    return not q(card,"isKindOf","SkillCard") and q(to,"getMark",q(self.player,"objectName").."mouyijued-Clear") > 0
end

sgs.ai_target_revises.mouhuoshou = function(to,card)
    if q(card,"isKindOf","SavageAssault")
    then return true end
end

sgs.ai_skill_use["@@mouzaiqi"] = function(self,prompt)
    local n = q(self.player,"getMark","&charge_num")
    n = math.min(n,#self.friends)
    if n<=0 then return "." end

    local lost = q(self.player,"getMaxHp")-q(self.player,"getHp")
    self:sort(self.friends,"handcard")
    local friends = {}

    for i = 1,n do
        lost = lost-1
        if lost<=0 and q(self,"canDraw",self.friends[i]) then
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
sgs.ai_skill_choice.mouzaiqi = function(self,choices,data)
    local to = data:toPlayer()
    choices = choices:split("+")
    if not q(self,"isFriend",to) then
        if q(self.player,"isKongcheng") and q(self,"needKongcheng") and table.contains(choices,"2") then return "2" end
        return "1"
    else
        if table.contains(choices,"2") then return "2" end
        return "1"
    end
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
sgs.ai_fill_skill.mouluanji = function(self,inclusive,request)
    if q(self.player,"getMark","mouluanjiUsed-PlayClear")>0 then return nil end
    local cards = self:addHandPile()
    if #cards>=2
    then
        self:sortByKeepValue(cards)
        local useAll = #cards>4
        for _,enemy in ipairs(self.enemies)do
            if q(enemy,"getHp")==1
            and not q(enemy,"hasArmorEffect","Vine")
            and not q(self,"hasEightDiagramEffect",enemy)
            and r43_mouluanji_damage(self,enemy)
            and q(self,"isWeak",enemy) and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
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


sgs.ai_skill_use["@@mobilemoutuxi"] = function(self,prompt)
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByCardNeed(handcards, true)
    local targets = {}

    local use_cards = {}
    for _,c in ipairs(handcards) do
        if q(c,"hasFlag","moutuxi") and q(self,"getKeepValue",c) < 5 then
            table.insert(use_cards, q(c,"getEffectiveId"))
        end
    end
    local add_player = function (player,isfriend)
        if q(player,"getHandcardNum")==0 or q(player,"objectName")==q(self.player,"objectName") then return #targets end
        if q(self,"objectiveLevel",player)==0 and player:isLord() and role_count(self,"rebel")>1 then return #targets end

        local f = false
        for _,c in ipairs(targets)do
            if c==q(player,"objectName") then
                f = true
                break
            end
        end

        if not f then table.insert(targets,q(player,"objectName")) end

        if isfriend and isfriend==1 then
            strategy_flag(self,self.player,"tenyeartuxi_isfriend_"..q(player,"objectName"))
        end
        return #targets
    end
    local parsemobilemoutuxiCard = function()
        if #targets==0 then return "." end
        local s = table.concat(targets,"+")
        return "#mobilemoutuxiCard:"..table.concat(use_cards,"+")..":->"..table.concat(targets,"+")
    end
    for _, enemy in ipairs(self.enemies) do
        if q(self,"doDisCard",enemy, "h", true) and add_player(enemy)==#use_cards then
            return parsemobilemoutuxiCard()
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if q(self,"doDisCard",friend, "h", true) and add_player(friend)==#use_cards then
            return parsemobilemoutuxiCard()
        end
    end
    if #targets < #use_cards then
        local usecards = {}
        for _,c in ipairs(handcards) do
            if q(c,"hasFlag","moutuxi") then
                table.insert(usecards, q(c,"getEffectiveId"))
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
        if q(self,"doDisCard",enemy, "je") then
            return enemy
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if (self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty())
            or (q(self,"needToThrowArmor",friend) and friend:getArmor()) or q(self,"doDisCard",friend, "je") then
            return friend
        end
    end
    for _, enemy in ipairs(self.enemies) do
        return enemy
    end
    return nil
end
sgs.ai_skill_choice.mobilemoudengfeng = function(self,choices,data)
    local to = data:toPlayer()
    choices = choices:split("+")
    if table.contains(choices,"3") and q(self,"doDisCard",to,"e", true) and q(self.player,"getHp") + q(self,"getAllPeachNum") - 1 > 0 and math.random() < 0.5 then return "3" end
    if table.contains(choices,"1") and q(self,"doDisCard",to,"e", true) then return "1" end
    return "2"
end

sgs.ai_skill_use["@@moulveying"] = function(self,prompt)
    local dismantlement = clone_preview(self,"dismantlement")
    mutate(self,dismantlement,"skill","moulveying")

    local dummy_use = use_card(self,dismantlement, r42_response_dummy())
    if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() then
        local targets = {}
        for _,p in sgs.list(dummy_use.to)do
            table.insert(targets,q(p,"objectName"))
        end
        if #targets>0 then
            return dismantlement:toString().."->"..table.concat(targets,"+")
        end
    end
    return "."
end
sgs.ai_skill_use["@@mouyingwu"] = function(self,prompt)
    local slash = clone_preview(self,"slash")
    mutate(self,slash,"skill","mouyingwu")

    local dummy_use = use_card(self,slash, r42_response_dummy())
    if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() then
        local targets = {}
        for _,p in sgs.list(dummy_use.to)do
            table.insert(targets,q(p,"objectName"))
        end
        if #targets>0 then
            return slash:toString().."->"..table.concat(targets,"+")
        end
    end
    return "."
end



sgs.ai_guhuo_card.moulongdan = function(self, toname, class_name)
    if q(self,"getCardsNum",class_name)>0 then return end
    if q(self.player,"getMark","moujizhuoBf") == 0 then return end
    if q(self.player,"getMark","&moulongdanLast")<1 then return end
    local card = clone_preview(self,toname, sgs.Card_SuitToBeDecided, -1)

    if (not card) or (not q(card,"isKindOf","BasicCard")) then return end
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards, nil, true)
    for c, h in sgs.list(cards) do
        if q(h,"isKindOf","BasicCard") and q(h,"isKindOf","BasicCard") then
            c = preview(self,toname)
            mutate(self,c,"skill","moulongdan")
            mutate(self,c,"add",h)
            return c:toString()
        end
    end
end

sgs.ai_fill_skill.moulongdan = function(self,inclusive,request)
    if q(self.player,"getMark","&moulongdanLast") < 1 then return end
    local cards = self:addHandPile()
    self:sortByUseValue(cards, true)

    local function findCardByType(cards, type_func)
        for _, card in ipairs(cards) do
            if type_func(card) then
                return card
            end
        end
    end

    if q(self.player,"getMark","moujizhuoBf") > 0 then
        local use_card = findCardByType(cards, function(card) return q(card,"isKindOf","BasicCard") end)
        if not use_card then return nil end
        for _, pn in ipairs(RandomList(pattern_names(self))) do
            local c = preview(self,pn)
            if c and q(c,"isKindOf","BasicCard") then
                mutate(self,c,"skill","moulongdan")
                mutate(self,c,"add",use_card)
                if q(c,"isAvailable",self.player) then
                    return c
                end
            end
        end
    else
        local jink_card = findCardByType(cards, function(card) return q(card,"isKindOf","Jink") end)
        if not jink_card then return nil end
        local suit = q(jink_card,"getSuitString")
        local number = q(jink_card,"getNumberString")
        local card_id = q(jink_card,"getEffectiveId")
        local card_str = ("slash:moulongdan[%s:%s]=%d"):format(suit, number, card_id)
        local slash = parse_action(self,card_str)
        assert(slash)
        return slash
    end
end

sgs.ai_view_as.moulongdan = function(card,player,card_place)
    if q(player,"getMark","&moulongdanLast")<1 then return end
    local suit = q(card,"getSuitString")
    local number = q(card,"getNumberString")
    local card_id = q(card,"getEffectiveId")
    if card_place==sgs.Player_PlaceHand then
        if q(card,"isKindOf","Jink") then
            return ("slash:moulongdan[%s:%s]=%d"):format(suit,number,card_id)
        elseif q(card,"isKindOf","Slash") then
            return ("jink:moulongdan[%s:%s]=%d"):format(suit,number,card_id)
        end
    end
end


ai_audited_aliases.register{id="ai_cardneed.moulongdan",defer_canonical=true,self_index=3,registry="ai_cardneed",path={"moulongdan"},canonical_registry="ai_cardneed",canonical_path={"longdan"}}
sgs.ai_card_priority.moulongdan = function(self,card)
    if table.contains(q(card,"getSkillNames"), "moulongdan")
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
    if card and q(card,"isKindOf","Slash") and q(from,"getMark","moupaoxiaoSlashUsed-PlayClear")>1 then
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

sgs.ai_skill_use["@@mouxieji"] = function(self,prompt)
    local slash = clone_preview(self,"slash")
    mutate(self,slash,"skill","_mouxieji")

    local dummy_use = use_card(self,slash, r42_response_dummy(2))
    if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() then
        local targets = {}
        for _,p in sgs.list(dummy_use.to)do
            table.insert(targets,q(p,"objectName"))
        end
        if #targets>0 then
            return "#mouxiejiCard:.:->"..table.concat(targets,"+")
        end
    end
    return "."
end

sgs.ai_skill_use["@@moumingxuan!"] = function(self,prompt)
    self:sort(self.enemies, "defense")
    local n = math.max(1,q(self.player,"getMark","moumingxuanCardGive"))
    local targets = {}
    local suits = {}
    local use_cards = {}
    for _, card in sgs.qlist(self.player:getCards("h")) do
        if not table.contains(suits, q(card,"getSuitString")) and not q(card,"isKindOf","Slash") then
            table.insert(suits, q(card,"getSuitString"))
            table.insert(use_cards, q(card,"getEffectiveId"))
            if #use_cards >= n then break end
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if q(friend,"getMark","&moumingxuan+#"..q(self.player,"objectName")) < 1 then
            table.insert(targets, q(friend,"objectName"))
            if #targets >= #use_cards then break end
        end
    end
    if #targets < #use_cards then
        for _, enemy in ipairs(self.enemies) do
            if q(enemy,"getMark","&moumingxuan+#"..q(self.player,"objectName")) < 1 and ((self:getKnownNum(enemy)==q(enemy,"getHandcardNum") and getKnownCard(enemy,self.player,"Slash")==0) or q(enemy,"getHandcardNum") < 3) then
                table.insert(targets, q(enemy,"objectName"))
                if #targets >= #use_cards then break end
            end
        end
    end
    if #use_cards > #targets then
        local suits = {}
        local use_cards = {}
        for _, card in sgs.qlist(self.player:getCards("h")) do
            if not table.contains(suits, q(card,"getSuitString")) then
                table.insert(suits, q(card,"getSuitString"))
                table.insert(use_cards, q(card,"getEffectiveId"))
                if #use_cards >= #targets then break end
            end
        end
    end
    if #targets == #use_cards and #targets > 0 then
        return "#moumingxuanCard:"..table.concat(use_cards,"+")..":->"..table.concat(targets,"+")
    end
end
sgs.ai_can_damagehp.mouxianchou = function(self,from,card,to)
    if from and q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
    and q(self,"canLoseHp",from,card,to)
    then
        return q(self,"isEnemy",from) and q(self,"isWeak",from)
    end
end

sgs.ai_skill_playerchosen.mouxianchou = function(self, targets)
    local destlist = sgs.QList2Table(targets) -- 将列表转换为表
    self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target) and q(self,"doDisCard",target, "he") then
            return target
        end
    end
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target) then
            return target
        end
    end
    return destlist[1]
end

sgs.ai_skill_cardask["@mouxianchou-slash"] = function(self, data, pattern, target, target2)
    local damage = data:toDamage()
    local dc = preview(self)
    mutate(self,dc,"skill","_mouxianchou")
    local dummy_use = q(self,"withOwnerRange","InfinityAttackRange","@mouxianchou-slash",function()
        return use_card(self,dc,r44_range_dummy(0,self.room:getOtherPlayers(damage.from)))
    end)
    if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(damage.from) then
        return true
    end
    return false
end

sgs.ai_fill_skill.mouyanyu = function(self,inclusive,request)
    if #self.friends_noself == 0 then return nil end
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if q(card,"isKindOf","Slash") then
            local card_str = "#mouyanyuCard:"..q(card,"getEffectiveId")..":"
            return parse_action(self,card_str)
        end
    end
end

sgs.ai_skill_use_func["#mouyanyuCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_skill_playerchosen.mouyanyu = function(self, targets)
    return self:findPlayerToDraw(false, q(self.player,"getMark","&mouyanyuDraw-PlayClear")*3)
end
sgs.ai_playerchosen_intention.mouyanyu = -80
sgs.ai_skill_invoke.mouqiaoshi = function(self,data)
    local damage = data:toDamage()
    return q(self,"isFriend",damage.to) or ZishuEffect(self.player)>0 or not q(damage.to,"isWounded")
end

sgs.ai_choicemade_filter.skillInvoke.mouqiaoshi = function(self,player,promptlist)
    local damage = scoped_struct(self,"CurrentDamageStruct","damage")
    if promptlist[#promptlist]=="yes" and damage then
        self:updateIntention(player,damage.to,-40)
    end
end

sgs.ai_can_damagehp.mouqiaoshi = function(self,from,card,to)
    if from and q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
    and q(self,"canLoseHp",from,card,to)
    then
        return q(self,"isFriend",from) and q(to,"getMark","mouqiaoshiUse-Clear")<1 and role_estimate(self,to) ~= "neutral"
    end
end


sgs.ai_fill_skill.moujiang = function(self,inclusive,request)
    local fs = preview(self,"duel")
    mutate(self,fs,"skill","moujiang")
    for _,c in sgs.list(self.player:getHandcards())do
        mutate(self,fs,"add",c)
    end
    if fs:subcardsLength()>0
    and q(self,"getPriorTurnUseCount")<2
    then return fs end
end

sgs.ai_use_revises.moujiang = function(self,card,use)
    if table.contains(q(card,"getSkillNames"), "moujiang") then
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
    if q(self.player,"getHp") + q(self,"getAllPeachNum") - 1 <= 0 then
        return nil
    end
    local use = scoped_struct(self,"moujiang","use")
    local dummy_use = use_card(self,q(self,'evaluateSkillCard','newgenerals_context:moujiang',q(use.card,'objectName'),{}),r44_range_dummy(99,use.to))
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
sgs.ai_skill_invoke.moulieren = function(self,data)
    local target = data:toPlayer()
    if not q(self,"isEnemy",target) then return false end

    if q(self.player,"getHandcardNum")==1 then
        if (q(self,"needKongcheng") or not q(self,"hasLoseHandcardEffective")) and not q(self,"isWeak") then return true end
        local card  = self.player:getHandcards():first()
        if q(card,"isKindOf","Jink") or q(card,"isKindOf","Peach") then return end
    end
    return sgs.ai_skill_playerchosen.moulieren(self, self.room:getOtherPlayers(target)) ~= nil
end

sgs.ai_target_revises.makijuxiang = function(to,card)
    if q(card,"isKindOf","SavageAssault")
    then return true end
end


sgs.ai_fill_skill.moutianxiang = function(self,inclusive,request)
    return parse_action(self,"#moutianxiangCard:.:")
end

sgs.ai_skill_use_func["#moutianxiangCard"] = function(card, use, self,request)
    local function hasMoutianxiangMark(player)
        for _, mark in sgs.list(player:getMarkNames()) do
            if string.startsWith(mark, "&moutianxiang") and q(player,"getMark",mark) > 0 then
                return true
            end
        end
        return false
    end
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
    local heart, red
    for _,c in ipairs(cards) do
        if not heart and q(c,"getSuit") == sgs.Card_Heart then heart = c end
        if not red and q(c,"isRed") then red = c end
        if heart and red then break end
    end

    self:sort(self.friends_noself, "hp")

    local function tryUse(targets, cond, card_obj)
        for _, p in sgs.list(targets) do
            if cond(p) and not hasMoutianxiangMark(p) then
                use.card = parse_action(self,"#moutianxiangCard:" .. q(card_obj,"getId") .. ":")
                if use.to then use.to:append(p) end
                return true
            end
        end
        return false
    end

    if heart then
        if tryUse(self.friends_noself, function(p) return q(self,"needToLoseHp",p) or not q(self,"isWeak",p) end, heart) then return end
    end

    if red then
        if tryUse(self.friends_noself, function(p) return q(self,"doDisCard",p, "he", true) or hasTuntianEffect(p) end, red) then return end
    end
     if heart then
        if tryUse(self.enemies, function(p) return not q(self,"needToLoseHp",p) or q(self,"isWeak",p) end, heart) then return end
    end
end

sgs.ai_use_value.moutianxiangCard = 4.5
sgs.ai_use_priority.moutianxiangCard = 6.7

sgs.ai_skill_playerchosen.moutianxiang = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "handcard")
    for _, friend in ipairs(targets) do
        for _, mark in sgs.list(friend:getMarkNames()) do
            if string.startsWith(mark, "&moutianxiang") and string.contains(mark, "heart") and q(friend,"getMark",mark) > 0 and q(self,"needToLoseHp",friend) then
                return friend
            end
        end
    end
    for _, enemy in ipairs(targets) do
        for _, mark in sgs.list(enemy:getMarkNames()) do
            if string.startsWith(mark, "&moutianxiang") and string.contains(mark, "heart") and q(enemy,"getMark",mark) > 0 then
                return enemy
            end
        end
    end
    for _, enemy in ipairs(targets) do
        for _, mark in sgs.list(enemy:getMarkNames()) do
            if string.startsWith(mark, "&moutianxiang") and string.contains(mark, "diamond") and q(enemy,"getMark",mark) > 0 and q(self,"doDisCard",enemy, "he", true, 2) then
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
        local isFriend = q(self,"isFriend",judge.who)
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


sgs.ai_skill_invoke.rensongshu = function(self,data)
    local to = data:toPlayer()
    local card_count = scoped_count(self,"ren_pile_count")
    return q(self,"isEnemy",to) and (card_count<4 or q(self,"isWeak"))
end

sgs.ai_skill_invoke.renyizhu = function(self,data)
    local use = data:toCardUse()
    if q(self,"isEnemy",use.from) then
        return q(self,"isFriend",use.to:first())
        or q(self,"isEnemy",use.to:first())
    end
end

sgs.ai_fill_skill.renluanchou = function(self,inclusive,request)
    return parse_action(self,"#renluanchouCard:.:")
end

sgs.ai_skill_use_func["#renluanchouCard"] = function(card,use,self,request)
    self:sort(self.friends,"hp")
    self:sort(self.enemies,"hp",true)
    for _,ep in sgs.list(self.enemies)do
        for _,p in sgs.list(self.friends)do
            if q(ep,"getHp")>q(p,"getHp") then
                use.card = card
                return
            end
        end
    end
    local tos = self.room:getAllPlayers()
    tos = self:sort(tos,"hp",true)
    for _,ep in sgs.list(tos)do
        for _,p in sgs.list(self.friends)do
            if q(ep,"getHp")>q(p,"getHp") then
                use.card = card
                return
            end
        end
    end
    for _,ep in sgs.list(self.enemies)do
        for _,p in sgs.list(self.friends)do
            if q(ep,"getHp")>=q(p,"getHp") then
                use.card = card
                return
            end
        end
    end
    for _,ep in sgs.list(tos)do
        for _,p in sgs.list(self.friends)do
            if ep~=p and q(ep,"getHp")>=q(p,"getHp") then
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
        if q(self,"isFriend",target) then
            table.insert(tos,target)
            break
        end
    end
    for _,target in sgs.list(sgs.reverse(destlist))do
        if q(self,"isEnemy",target) and #tos==1 and q(target,"getHp")>tos[1]:getHp() then
            table.insert(tos,target)
        end
    end
    for _,target in sgs.list(sgs.reverse(destlist))do
        if q(self,"isEnemy",target) and #tos==1 and q(target,"getHp")>=tos[1]:getHp() then
            table.insert(tos,target)
        end
    end
    for _,target in sgs.list(sgs.reverse(destlist))do
        if #tos==1 and q(target,"getHp")>=tos[1]:getHp() then
            table.insert(tos,target)
        end
    end
    return tos
end

sgs.ai_skill_invoke.renliaoyi = function(self,data)
    local to = data:toPlayer()
    return q(self,"isFriend",to) and q(to,"getHp")>q(to,"getHandcardNum")
    or q(self,"isEnemy",to) and q(to,"getHp")<q(to,"getHandcardNum")
end

sgs.ai_fill_skill.renbinglun = function(self,inclusive,request)
    local card_count = scoped_count(self,"ren_pile_count")
    return card_count>0
    and parse_action(self,"#renbinglunCard:.:")
end

sgs.ai_skill_use_func["#renbinglunCard"] = function(card,use,self,request)
    self:sort(self.friends,"hp")
    for _,p in sgs.list(self.friends)do
        if q(p,"isWounded") then
            use.card = card
            use.to:append(p)
            return
        end
    end
    self:sort(self.friends,"handcard")
    for _,p in sgs.list(self.friends)do
        if q(p,"getHandcardNum")<q(p,"getHp") then
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

sgs.ai_skill_choice.renbinglun = function(self,choices,data)
    local items = choices:split("+")
    if q(self.player,"getMark","&renbinglun")>0
    or q(self.player,"getHandcardNum")<3
    then return items[1] end
    return items[2]
end

sgs.ai_fill_skill.mobile_wuling = function(self,inclusive,request)
    return parse_action(self,"#mobile_wulingCard:.:")
end

sgs.ai_skill_use_func["#mobile_wulingCard"] = function(card,use,self,request)
    self:sort(self.friends,nil,true)
    for _,p in sgs.list(self.friends)do
        if q(p,"getMark","mobile_wuling")<1 then
            use.card = card
            use.to:append(p)
            return
        end
    end
end

sgs.ai_use_value.mobile_wulingCard = 4.5
sgs.ai_use_priority.mobile_wulingCard = 5.7

sgs.ai_skill_choice.mobile_wuling = function(self,choices,data)
    local items = choices:split("+")
    local to = data:toPlayer()
    if q(self,"isFriend",to) then
        if table.contains(items,"wl_hu_mark") and q(self,"isWeak",to) then
            return "wl_hu_mark"
        end
        if table.contains(items,"wl_lu_mark") and to:getCards("j"):length()>0 then
            return "wl_lu_mark"
        end
    end
end

sgs.ai_fill_skill.mobile_youyi = function(self,inclusive,request)
    local card_count = scoped_count(self,"ren_pile_count")
    return card_count>0 and parse_action(self,"#mobile_youyiCard:.:")
end

sgs.ai_skill_use_func["#mobile_youyiCard"] = function(card,use,self,request)
    local n = 0
    for _,p in sgs.list(self.room:getAllPlayers())do
        if q(p,"isWounded") then
            if q(self,"isEnemy",p) then
                n = n-1
                if q(self,"isWeak",p)
                then n = n-1 end
            else
                n = n+1
                if q(self,"isFriend",p) and q(self,"isWeak",p)
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

sgs.ai_skill_invoke.mobile_youyi = function(self)
    return true
end

sgs.ai_skill_invoke.mobile_tamo = function(self)
    return true
end

sgs.ai_fill_skill.mobile_dingzou = function(self,inclusive,request)
    return parse_action(self,"#mobile_dingzouCard:.:")
end

sgs.ai_skill_use_func["#mobile_dingzouCard"] = function(card,use,self,request)
    self:sort(self.friends_noself,nil,true)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,p in sgs.list(self.friends_noself)do
        if #self:poisonCards("ej",p)>p:getEquips():length()/2 then
            local n = p:getCards("ej"):length()
            if n<1 then continue end
            local ids = {}
            for _,c in sgs.list(cards)do

                table.insert(ids,q(c,"getEffectiveId"))
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

                table.insert(ids,q(c,"getEffectiveId"))
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
        if not q(self,"isFriend",target)
        and q(target,"getHandcardNum")>q(self.player,"getHandcardNum")
        then return target end
    end
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target) and q(self,"isWeak",target)
        and q(target,"getHandcardNum")<q(self.player,"getHandcardNum")/2
        then return target end
    end
end


sgs.ai_fill_skill.yanduanbi = function(self,inclusive,request)
    return parse_action(self,"#yanduanbiCard:.:")
end

sgs.ai_skill_use_func["#yanduanbiCard"] = function(card,use,self,request)
    for _,p in sgs.list(self.friends)do
        if q(self,"isWeak",p) and q(p,"getHandcardNum")<3 then
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
        if q(self,"isFriend",target)
        then return target end
    end
end

sgs.ai_skill_playerchosen.yantongdu = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,nil,true)
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target)
        and q(target,"getCardCount")>2
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
        local id = q(e,"getEffectiveId")
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

sgs.ai_skill_invoke.yandiancai = function(self)
    return true
end

local function canZhengsu(self,player)
    player = player or self.player
    local handcards = sgs.QList2Table(player:getCards("h"))
    self:sortByUsePriority(handcards)
    local tocs,ns = {},AIList.new({})
    for d,h in sgs.list(handcards)do
        if q(h,"isAvailable",player) then
            d = use_card(self,h)
            if d.card and d.to
            then table.insert(tocs,h) end
        end
    end
    for d,h in sgs.list(tocs)do
        if ns:contains(q(h,"getNumber")) then continue end
        ns:append(q(h,"getNumber"))
    end
    if ns:length()>2 then
        set_state(self,"zhengsu_choice","zhengsu1")
        return true
    end
    for d,h in sgs.list(tocs)do
        ns = 0
        for _,h1 in sgs.list(tocs)do
            if q(h,"getSuit")==q(h1,"getSuit")
            then ns = ns+1 end
        end
        if ns>2 then
            set_state(self,"zhengsu_choice","zhengsu2")
            return true
        end
    end
    if #handcards-q(player,"getMaxCards")>2
    and #handcards-q(player,"getMaxCards")<5 then
        set_state(self,"zhengsu_choice","zhengsu3")
        return true
    end
end

sgs.ai_skill_choice.zhengsu = function(self,choices)
    return get_state(self,"zhengsu_choice")
end

sgs.ai_skill_invoke.yanyanji = function(self)
    return canZhengsu(self)
end

sgs.ai_skill_invoke.yantaoluan = function(self,data)
    local judge = data:toJudge()
    if q(self,"isFriend",judge.who) then
        return judge:isBad()
    elseif q(self,"isEnemy",judge.who) then
        return judge:isGood()
    end
    return q(self.player,"getHandcardNum")<=q(self.player,"getMaxCards")
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

sgs.ai_skill_choice.yantaoluan = function(self,choices,data)
    local items = choices:split("+")
    local judge = data:toJudge()
    if q(self,"isEnemy",judge.who) then
        if r48_yantaoluan_can_slash(self,judge.who,preview(self,"fire_slash","_yantaoluan")) then
            return "yantaoluan2"
        end
    end
    return items[1]
end

sgs.ai_skill_invoke.yanshiji = function(self,data)
    local to = data:toPlayer()
    return q(self,"isEnemy",to)
    or not q(self,"isFriend",to) and #self.friends_noself<1
end

sgs.ai_skill_invoke.yanzhengjun = function(self)
    return canZhengsu(self)
end

sgs.ai_skill_playerchosen.yanzhengjun = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target) then
            return target
        end
    end
end

sgs.ai_fill_skill.yanyangjie = function(self,inclusive,request)
    return parse_action(self,"#yanyangjieCard:.:")
end

sgs.ai_skill_use_func["#yanyangjieCard"] = function(card,use,self,request)
    local nc = self:getMinCard()
    if nc and q(nc,"getNumber")<5 then
        self:sort(self.enemies)
        set_state(self,"yanyangjie_card",nc)
        for _,p in sgs.list(self.enemies)do
            if q(self.player,"canPindian",p) then
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
        if q(self,"isFriend",target) then
            for _,sk in ipairs(sgs.getPlayerSkillList(target)) do
                local ts = trigger_skill(self,q(sk,"objectName"))
                if ts and (ts:hasEvent(sgs.DamageCaused) or ts:hasEvent(sgs.Damage)) then
                    return target
                end
            end
        end
    end
    for _,target in sgs.list(destlist)do
        if q(self,"isFriend",target) then
            local can = true
            for _,sk in ipairs(sgs.getPlayerSkillList(get_state(self,"yanyangjieTo"))) do
                local ts = trigger_skill(self,q(sk,"objectName"))
                if ts and (ts:hasEvent(sgs.DamageInflicted) or ts:hasEvent(sgs.Damaged)) then
                    can = false
                    break
                end
            end
            if can then
                return target
            else
                for _,p in sgs.list(destlist)do
                    if q(self,"isEnemy",p) then
                        return p
                    end
                end
            end
        end
    end
    return destlist[1]
end

sgs.ai_skill_invoke.yanjuxiang = function(self,data)
    local to = data:toPlayer()
    return to and q(self,"isEnemy",to)
end

sgs.ai_skill_invoke.yanhoufeng = function(self,data)
    local to = data:toPlayer()
    return canZhengsu(self,to)
end

sgs.ai_skill_use["@@olyuheng!"] = function(self,prompt)
    local valid = {}
    local ids = {}
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
    local n = q(self.player,"getMark","mouqingzhengSuits")
    for _,c in sgs.list(cards)do
        if table.contains(ids,q(c,"getSuit")) then continue end
        table.insert(valid,q(c,"getEffectiveId"))
        table.insert(ids,q(c,"getSuit"))
    end
    if #valid<1 then return end
    return "#olyuhengCard:"..table.concat(valid,"+")..":"
end

sgs.ai_skill_choice.oldili = function(self,choices,data)
    local items = choices:split("+")
    local n = data:toInt()
    if n>=3 then
        return items[#items]
    end
    return items[2]
end

sgs.ai_skill_invoke.zhaoluan = function(self,data)
    local to = data:toPlayer()
    return not q(self,"isEnemy",to)
    or #self.friends/2>=#self.enemies
end

sgs.ai_fill_skill.zhaoluan = function(self,inclusive,request)
    return parse_action(self,"#zhaoluanCard:.:")
end

sgs.ai_skill_use_func["#zhaoluanCard"] = function(card,use,self,request)
    self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
        if q(p,"getMark","zhaoluanDamage"..q(self.player,"objectName"))<1 and q(self,"isWeak")
        and q(self,"damageIsEffective",p,nil,self.player) then
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

sgs.ai_fill_skill.mobilejingxie = function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards,true) -- 按保留值排序
    for _,c in sgs.list(cards)do
        if table.contains(jx_equip,q(c,"objectName"))
        and not q(self.player,"hasFlag","jx_equip"..q(c,"objectName")) and use_card(self,c).card then
            set_state(self,"jx_equip_name",q(c,"objectName"))
            return parse_action(self,"#mobilejingxieCard:"..q(c,"getId")..":")
        end
    end
end

sgs.ai_skill_use_func["#mobilejingxieCard"] = function(card,use,self,request)
    strategy_flag(self,self.player,"jx_equip"..get_state(self,"jx_equip_name"))
    use.card = card
end

sgs.ai_use_value.mobilejingxieCard = 4.5
sgs.ai_use_priority.mobilejingxieCard = 7.7

sgs.ai_fill_skill.mobileqiaosi = function(self,inclusive,request)
    self:setPriorityValue("mobileqiaosiCard",8-q(self.player,"getHandcardNum"),"newgenerals")
    return parse_action(self,"#mobileqiaosiCard:.:")
end

sgs.ai_skill_use_func["#mobileqiaosiCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value.mobileqiaosiCard = 4.5
sgs.ai_use_priority.mobileqiaosiCard = 8.7

sgs.ai_skill_choice.qs_shuizhuan = function(self,choices,data)
    local items = choices:split("+")
    for _,t in sgs.list(table.copyFrom(items))do
        if string.find(t,"100") then table.removeOne(items,t) end
    end
    if #items>0 then
        for _,t in sgs.list(items)do
            if string.find(t,"qs_wang") or string.find(t,"qs_wang")
            then return t end
        end
        for _,t in sgs.list(items)do
            if string.find(t,"qs_shang") or string.find(t,"qs_shi")
            then return t end
        end
        return items[math.random(1,#items)]
    end
end

sgs.ai_skill_use["@@mobileqiaosi!"] = function(self,prompt)
    local valid = {}
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
    local n = q(self.player,"getMark","mobileqiaosiNum")
    for _,c in sgs.list(cards)do
        if #valid>=n or use_card(self,c).card then continue end
        table.insert(valid,q(c,"getEffectiveId"))
    end
    for _,c in sgs.list(cards)do
        if #valid>=n or table.contains(valid,q(c,"getEffectiveId")) then continue end
        table.insert(valid,q(c,"getEffectiveId"))
    end
    if #valid<1 then return end
    self:sort(self.friends_noself)
    for _,p in sgs.list(self.friends_noself)do
        return "#mobileqiaosi2Card:"..table.concat(valid,"+")..":->"..q(p,"objectName")
    end
    for _,c in sgs.list(cards)do
        if #valid>=n or use_card(self,c).card or q(self.player,"isJilei",c) then continue end
        table.insert(valid,q(c,"getEffectiveId"))
    end
    for _,c in sgs.list(cards)do
        if #valid>=n or table.contains(valid,q(c,"getEffectiveId")) or q(self.player,"isJilei",c) then continue end
        table.insert(valid,q(c,"getEffectiveId"))
    end
    if #valid<1 then return end
    return "#mobileqiaosi2Card:"..table.concat(valid,"+")..":"
end

sgs.ai_skill_playerchosen.keoljianxuan = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    for _,p in sgs.list(destlist)do
        if q(self,"isFriend",p) then
            local h = q(p,"getHandcardNum")+1
            if h==2+q(self.player,"getMark","&keolgangshu_mp")
            or h==q(self.player,"getAttackRange")
            or h==1+q(preview(self),"getTargetModResidue",self.player)
            then return p end
        end
    end
    for _,p in sgs.list(destlist)do
        if q(self,"isFriend",p) then
            local h = q(p,"getHandcardNum")
            if h<2+q(self.player,"getMark","&keolgangshu_mp")
            or h<q(self.player,"getAttackRange")
            or h<1+q(preview(self),"getTargetModResidue",self.player)
            then return p end
        end
    end
    for _,p in sgs.list(destlist)do
        if q(self,"isFriend",p) then
            return p
        end
    end
end

sgs.ai_fill_skill.mobiledamingvs = function(self,inclusive,request)
    return parse_action(self,"#mobiledamingCard:.:")
end

sgs.ai_skill_use_func["#mobiledamingCard"] = function(card,use,self,request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    if #cards<1 then return end
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,p in sgs.list(self.friends_noself)do
        if q(p,"hasSkill","mobiledaming")
        and q(self.player,"getMark",q(p,"objectName").."mobiledamingUse-PlayClear")<1
        then
            use.card = parse_action(self,"#mobiledamingCard:"..cards[1]:getId()..":")
            use.to:append(p)
            return
        end
    end
    cards = self:poisonCards(cards)
    if #cards<1 then return end
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
        if q(p,"hasSkill","mobiledaming")
        and q(self.player,"getMark",q(p,"objectName").."mobiledamingUse-PlayClear")<1
        then
            use.card = parse_action(self,"#mobiledamingCard:"..cards[1]:getId()..":")
            use.to:append(p)
            return
        end
    end
end

sgs.ai_use_value.mobiledamingCard = 4.5
sgs.ai_use_priority.mobiledamingCard = 6.7

sgs.ai_fill_skill.mobilexiaoni = function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    if #cards<1 then return end
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,pn in sgs.list(pattern_names(self))do
        local dc = preview(self,pn)
        if dc and q(dc,"isDamageCard") and q(self,"getCardsNum",dc:getClassName())<1
        and not q(dc,"isKindOf","DelayedTrick") then
            mutate(self,dc,"skill","mobilexiaoni")
            for _,c in sgs.list(cards)do
                mutate(self,dc,"add",c)
                if q(dc,"isAvailable",self.player) then
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
        if q(self,"isEnemy",p) and q(p,"getCardCount")>0 then
            return p
        end
    end
    for _,p in sgs.list(destlist)do
        if q(p,"getCardCount")>0 then
            return p
        end
    end
end

sgs.ai_fill_skill.hannan = function(self,inclusive,request)
    return parse_action(self,"#hannanCard:.:")
end

sgs.ai_skill_use_func["#hannanCard"] = function(card,use,self,request)
    local mc = self:getMaxCard()
    if not mc or q(mc,"getNumber")<11 then return end
    set_state(self,"hannan_card",mc)
    self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
        if q(self.player,"canPindian",p) then
            use.card = card
            use.to:append(p)
            return
        end
    end
end

sgs.ai_use_value.hannanCard = 4.5
sgs.ai_use_priority.hannanCard = 2.7

sgs.ai_fill_skill.keolsaogu = function(self,inclusive,request)
    if q(self.player,"getChangeSkillState","keolsaogu") == 1 then
        local cards = self.player:getCards("he")
        cards = self:sortByKeepValue(cards,nil,"jl") -- 按保留值排序
        if #cards<1 then return end
        local ids = {}
        for _,c in sgs.list(cards)do
            if #ids<2 and q(c,"isKindOf","Slash") and q(self.player,"getMark",q(c,"getSuitString").."keolsaoguSuit-PlayClear")<1 then
                if q(self.player,"hasUsed","Slash") then
                    table.insert(ids,q(c,"getEffectiveId"))
                end
            end
        end
        for _,c in sgs.list(cards)do
            if #ids==1 and q(self.player,"getMark",q(c,"getSuitString").."keolsaoguSuit-PlayClear")<1
            and q(c,"getEffectiveId")~=ids[1] then
                table.insert(ids,q(c,"getEffectiveId"))
            end
        end
        for _,c in sgs.list(cards)do
            if #ids<1 and q(self.player,"getMark",q(c,"getSuitString").."keolsaoguSuit-PlayClear")<1
            and #cards>3 then
                table.insert(ids,q(c,"getEffectiveId"))
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

sgs.ai_skill_use_func["#keolsaoguCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value.keolsaoguCard = 4.5
sgs.ai_use_priority.keolsaoguCard = 1.7

sgs.ai_skill_use["@@keolsaogu"] = function(self,prompt)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards,nil,"j") -- 按保留值排序
    if #cards<2 then return end
    if q(self.player,"getChangeSkillState","keolsaogu") == 1 then
        self:sort(self.friends_noself,nil,true)
        for _,p in sgs.list(self.friends_noself)do
            if q(p,"getCardCount")>2 and (getCardsNum("Slash",p,self.player)>0 or #self:poisonCards("e",p)>0) then
                return "#keolsaogu2Card:"..cards[1]:getId()..":->"..q(p,"objectName")
            end
        end
        self:sort(self.enemies)
        for _,p in sgs.list(self.enemies)do
            if q(p,"getCardCount")>0 and getCardsNum("Slash",p,self.player)<1 and #self:poisonCards("e",p)<1 then
                return "#keolsaogu2Card:"..cards[1]:getId()..":->"..q(p,"objectName")
            end
        end
    else
        self:sort(self.friends_noself)
        for _,p in sgs.list(self.friends_noself)do
            return "#keolsaogu2Card:"..cards[1]:getId()..":->"..q(p,"objectName")
        end
    end
end

sgs.ai_skill_use["@@keolsaoguslash"] = function(self,prompt)
    local ids = scope_list(self,"keolsaoguslashForAI")
    for _,id in sgs.list(ids)do
        local c = known_card(self,id)
        if q(c,"isKindOf","Slash") and not q(self.player,"isLocked",c) then
            local d = use_card(self,c)
            if d.card then
                local tos = {}
                for _,p in sgs.list(d.to)do
                    table.insert(tos,q(p,"objectName"))
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
        if #to_cards>=n or q(self.player,"getMark",q(c,"getSuitString").."keolsaoguSuit-PlayClear")>0 then continue end
        if q(c,"isKindOf","Slash") and use_card(self,c).card then
            table.insert(to_cards,q(c,"getEffectiveId"))
        end
    end
    for _,c in sgs.list(cards)do
        if #to_cards>=n or table.contains(to_cards,q(c,"getEffectiveId")) then continue end
        if q(self.player,"getMark",q(c,"getSuitString").."keolsaoguSuit-PlayClear")>0 then continue end
        table.insert(to_cards,q(c,"getEffectiveId"))
    end
    return to_cards
end

sgs.ai_fill_skill.olxiaofan = function(self,inclusive,request)
    local n = 1
    for _,m in sgs.list(self.player:getMarkNames())do
        if m:startsWith("&olxiaofan+:+") and q(self.player,"getMark",m)>0 then
            n = n+#m:split("+")-2
            break
        end
    end
    if n<4 or q(self.player,"getHandcardNum")<2 and q(self,"getPriorTurnUseCount")<2 then
        if q(self.player,"usedTimes","#olxiaofan0Card")<1 then
            return parse_action(self,"#olxiaofan0Card:.:")
        end
        local pattern = property_value(self,self.player,"olxiaofanPattern")
        if pattern~="" or q(self,"getPriorTurnUseCount")>1 then
            for _,id in sgs.list(pattern:split("+"))do
                local c = known_card(self,id)
                local d = use_card(self,c)
                if d.card then
                    if q(c,"canRecast") and d.to:isEmpty() then continue end
                    return parse_action(self,"#olxiaofan0Card:.:")
                end
            end
        end
    end
end

sgs.ai_skill_use_func["#olxiaofan0Card"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value.olxiaofan0Card = 4.5
sgs.ai_use_priority.olxiaofan0Card = 9.7

sgs.ai_skill_use["@@olxiaofan1"] = function(self,prompt)
    local pattern = property_value(self,self.player,"olxiaofanPattern")
    local cs = {}
    for _,id in sgs.list(pattern:split("+"))do
        table.insert(cs,known_card(self,id))
    end
    self:sortByDynamicUsePriority(cs)
    for _,c in sgs.list(cs)do
        local d = use_card(self,c)
        if d.card then
            if q(c,"canRecast") and d.to:isEmpty() then continue end
            local tos = {}
            for _,p in sgs.list(d.to)do
                table.insert(tos,q(p,"objectName"))
            end
            return c:toString().."->"..table.concat(tos,"+")
        end
    end
end

sgs.ai_guhuo_card.olxiaofan = function(self,toname,class_name)
    if q(self.player,"getMark","olxiaofanFailed-"..q(self.player,"getPhase").."Clear")>0 then return end
    local n = 1
    for _,m in sgs.list(self.player:getMarkNames())do
        if m:startsWith("&olxiaofan+:+") and q(self.player,"getMark",m)>0 then
            n = n+#m:split("+")-2
            break
        end
    end
    if n<4 or q(self.player,"getHandcardNum")<2 and q(self,"getCardsNum",class_name)<2 then
        add_failure_mark(self,"olxiaofanFailed-"..q(self.player,"getPhase").."Clear")
        return "#olxiaofanCard:.:"..toname
    end
end

sgs.ai_skill_use["@@olxiaofan2"] = function(self,prompt)
    local cs = {}
    for _,id in sgs.list(scope_list(self,"olxiaofanForAI"))do
        table.insert(cs,known_card(self,id))
    end
    local pattern = scope(self,"olxiaofanPattern")
    for _,c in sgs.list(cs)do
        for _,pn in sgs.list(pattern:split("+"))do
            if q(c,"sameNameWith",pn) and not q(self.player,"isLocked",c) then
                return "#olxiaofan0Card:"..q(c,"getId")..":@@olxiaofan2"
            end
        end
    end
end

sgs.ai_skill_invoke.keoldulie = function(self,data)
    local use = data:toCardUse()
    if q(use.card,"isDamageCard") then
        return q(self.player,"getAttackRange")>1 and not q(self,"isWeak")
    elseif q(self,"isFriend",use.from) then
        return q(self.player,"getAttackRange")>0
    end
    return q(self.player,"getAttackRange")>1
end

sgs.ai_fill_skill.keolweilin = function(self,inclusive,request)
    local cards = r45_handpile(self,"he")
    cards = sgs.QList2Table(cards)
    if #cards<1 then return end
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,pn in sgs.list(pattern_names(self))do
        local dc = preview(self,pn)
        if dc and (q(dc,"isKindOf","Analeptic") or q(dc,"isKindOf","Slash"))
        and q(self,"getCardsNum",dc:getClassName())<1 then
            mutate(self,dc,"skill","keolweilin")
            for _,c in sgs.list(cards)do
                mutate(self,dc,"add",c)
                if q(dc,"isAvailable",self.player) then
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
        if not q(player,"isLocked",dc)
        then return dc:toString() end
        mutate(self,dc,"clear")
    end
end

sgs.ai_card_priority.keolweilin = function(self,card,v)
    if table.contains(q(card,"getSkillNames"), "keolweilin") then
        return 0.5
    end
end

sgs.ai_skill_cardask["juqi0"] = function(self,data,pattern,prompt)
    local to = data:toPlayer()
    if q(self,"isFriend",to) then
        local n = q(to,"getChangeSkillState","juqi")
        if n==1 then return true end
    elseif q(self,"isEnemy",to) then
        local n = q(to,"getChangeSkillState","juqi")
        if n==2 and q(to,"inMyAttackRange",self.player) and q(self,"isWeak") then return true end
    end
end

sgs.ai_skill_playerchosen.fengtu = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,nil,true)
    for _,p in sgs.list(destlist)do
        if q(self,"isFriend",p) then
            return p
        end
    end
end

sgs.ai_skill_invoke.taishi = function(self,data)
    local cp = self.room:getCurrent()
    return not q(self,"isFriend",cp)
end

sgs.ai_skill_choice.xdtiantong = function(self,choices,data)
    local items = choices:split("+")
    if not q(self.player,"faceUp") then
        return items[1]
    end
end

sgs.ai_fill_skill.xdyifuvs = function(self,inclusive,request)
    local cards = self.player:getCards("h")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
    for _,c in sgs.list(cards)do
        if q(c,"getTypeId")==1 then
            for _,p in sgs.list(self.room:getAllPlayers())do
                if q(p,"hasSkill","xdyifu") then
                    local n = q(p,"getChangeSkillState","xdyifu")
                    local choice = ""
                    if n==1 then choice = "lightning"
                    elseif n==2 then choice = property_value(self,self.player,"Suijiyingbian")
                    elseif n==3 then choice = "iron_chain" end
                    local dc = preview(self,choice,"_xdyifu")
                    if dc then
                        mutate(self,dc,"add",c)
                        mutate(self,dc,"recast",false)
                        if q(dc,"isAvailable",self.player) then
                            local d = use_card(self,dc)
                            if d.card then
                                set_state(self,"xdyifuvsTo",p)
                                set_state(self,"xdyifuvsUse",d)
                                return parse_action(self,"#xdyifucard:"..q(c,"getId")..":"..choice)
                            end
                        end
                    end
                end
            end
        end
    end
end

sgs.ai_skill_use_func["#xdyifucard"] = function(card,use,self,request)
    if get_state(self,"xdyifuvsTo") then
        use.card = card
        use.to:append(get_state(self,"xdyifuvsTo"))
    end
end

sgs.ai_use_value.xdyifucard = 4.5
sgs.ai_use_priority.xdyifucard = 2.7

sgs.ai_skill_use["@@xdyifuvs"] = function(self,prompt)
    local d = get_state(self,"xdyifuvsUse")
    if d.card then
        local tos = {}
        for _,p in sgs.list(d.to)do
            table.insert(tos,q(p,"objectName"))
        end
        return d.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_playerchosen.xdtianjie = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    for _,p in sgs.list(destlist)do
        if q(self,"isEnemy",p) and q(self,"damageIsEffective",p,"T") then
            return p
        end
    end
    for _,p in sgs.list(destlist)do
        if not q(self,"isFriend",p) then
            return p
        end
    end
end

-- Only the actually chosen readonly product binds a new response receipt.
-- Recast(false) is a source planning mutation; it is not serialized in the
-- donor wire or copied onto the separately native-produced selected card.
local function r48_xdfangchan_wire(self,card)
    if q(card,'isEvaluationOnly') and q(card,'getSkillName',false)=='_xdfangchan' then
        local selected=q(self,'bindOriginalSelectedConversion',{
            name=q(card,'objectName'),skill='_xdfangchan',suit=q(card,'getSuit'),
            number=q(card,'getNumber'),subcards=sgs.QList2Table(q(card,'getSubcards'))},
            q(card,'getClassName'),'xdfangchan')
        return q(selected,'toString')
    end
    return q(card,'toString')
end

sgs.ai_skill_use["@@xdfangchan"] = function(self,prompt)
    local n = q(self.player,"getMark","xdfangchanId")
    local dc = preview(self,known_card(self,n):objectName())
    mutate(self,dc,"skill","_xdfangchan")
    mutate(self,dc,"recast",false)
    local d = use_card(self,dc)
    if d.card then
        local tos = {}
        for _,p in sgs.list(d.to)do
            table.insert(tos,q(p,"objectName"))
        end
        return r48_xdfangchan_wire(self,d.card).."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_playerschosen._wuqibingfa = function(self,players,x,n)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist,nil,true)
    local tos = {}
    for _,p in sgs.list(destlist)do
        if #tos<x and q(self,"isFriend",p) and q(p,"getCardCount")>0 then
            for _,q in sgs.list(self.enemies)do
                if q(p,"canSlash",q) then
                    table.insert(tos,p)
                    break
                end
            end
        end
    end
    for _,p in sgs.list(destlist)do
        if #tos<x and not table.contains(tos,p) and not q(self,"isEnemy",p) and q(p,"getCardCount")>0 then
            for _,q in sgs.list(self.enemies)do
                if q(p,"canSlash",q) then
                    table.insert(tos,p)
                    break
                end
            end
        end
    end
    return tos
end

sgs.ai_skill_use["@@_wuqibingfa!"] = function(self,prompt)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
    for _,c in sgs.list(cards)do
        local dc = preview(self)
        mutate(self,dc,"skill","_wuqibingfa")
        mutate(self,dc,"add",c)
        if q(dc,"isAvailable",self.player) then
            local d = use_card(self,dc)
            if d.card then
                local tos = {}
                for _,p in sgs.list(d.to)do
                    table.insert(tos,q(p,"objectName"))
                end
                return d.card:toString().."->"..table.concat(tos,"+")
            end
        end
    end
    for _,c in sgs.list(cards)do
        local dc = preview(self)
        mutate(self,dc,"skill","_wuqibingfa")
        mutate(self,dc,"add",c)
        if q(dc,"isAvailable",self.player) then
            for _,p in sgs.list(self.enemies)do
                if q(self.player,"canSlash",p,dc) then
                    return dc:toString().."->"..q(p,"objectName")
                end
            end
            for _,p in sgs.list(self.room:getAllPlayers())do
                if q(self.player,"canSlash",p,dc) and not q(self,"isFriend",p) then
                    return dc:toString().."->"..q(p,"objectName")
                end
            end
            for _,p in sgs.list(self.room:getAllPlayers())do
                if q(self.player,"canSlash",p,dc) then
                    return dc:toString().."->"..q(p,"objectName")
                end
            end
        end
    end
end

sgs.ai_skill_invoke.xdfenbo = function(self,data)
    return q(self,"isWeak") or #self.friends<=#self.enemies/2
end

sgs.ai_fill_skill.xiongsuan = function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
    for _,c in sgs.list(cards)do
        return parse_action(self,"#xiongsuanCard:"..q(c,"getId")..":")
    end
end

sgs.ai_skill_use_func["#xiongsuanCard"] = function(card,use,self,request)
    self:sort(self.friends,nil,true)
    for _,p in sgs.list(self.friends)do
        for _,s in sgs.qlist(p:getVisibleSkillList()) do
            if q(s,"getFrequency",p) == sgs.Skill_Limited and q(p,"getMark",q(s,"getLimitMark"))<1 then
                use.to:append(p)
                use.card = card
                return
            end
        end
    end
    self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
        if q(p,"getHp")<2 and q(self,"damageIsEffective",p) then
            use.card = card
            use.to:append(p)
            return
        end
    end
    if not q(self,"isWeak") then
        use.card = card
        use.to:append(self.player)
    end
end

sgs.ai_use_value.xiongsuanCard = 4.5
sgs.ai_use_priority.xiongsuanCard = 7.7

sgs.ai_skill_choice.xiongsuan = function(self,choices,data)
    local items = choices:split("+")
    local p = data:toPlayer()
    if q(self,"isFriend",p) then
        local skills = {}
        for _,s in sgs.qlist(p:getVisibleSkillList()) do
            if table.contains(items,q(s,"objectName")) and q(p,"getMark",q(s,"getLimitMark"))<1 then
                table.insert(skills,q(s,"objectName"))
            end
        end
        if table.contains(items,"luanwu") then
            return "luanwu"
        end
        if table.contains(items,"fencheng") then
            return "fencheng"
        end
        if table.contains(items,"xingshuai") and q(self,"isWeak") then
            for _,p in sgs.list(self.friends_noself) do
                if q(p,"getKingdom")=="wei" then
                    return "xingshuai"
                end
            end
        end
        if table.contains(items,"xdfenbo") and q(self,"isWeak",self.enemies) then
            return "xdfenbo"
        end
        if table.contains(items,"xiongsuan") then
            return "xiongsuan"
        end
        return items[1]
    else
        return items[#items]
    end
end

sgs.ai_skill_invoke._eight_diagram = function(self,data)
    return sgs.ai_skill_invoke.eight_diagram(self,data)
end

sgs.ai_skill_cardask["mobilejingxie0"] = function(self,data,pattern,prompt)
    return true
end

sgs.ai_fill_skill.olmoguofu = function(self,inclusive,request)
    local cards = self:addHandPile("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
    local pns = property_value(self,self.player,"olmoguofuPns"):split("+")
    for _,c in sgs.list(cards)do
        if q(c,"hasTip","olmoguofu") then
            for _,pn in sgs.list(RandomList(pns))do
                if q(self.player,"getMark",pn.."olmoguofuBan-Clear")>0 then continue end
                local dc = preview(self,pn)
                if dc and q(self,"getCardsNum",dc:getClassName())<1 then
                    mutate(self,dc,"skill","olmoguofu")
                    mutate(self,dc,"add",c)
                    mutate(self,dc,"recast",false)
                    if q(dc,"isAvailable",self.player) and use_card(self,dc).card
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
        if q(c,"hasTip","olmoguofu") then
            local dc = preview(self,class_name)
            if q(player,"getMark",q(dc,"objectName").."olmoguofuBan-Clear")>0 then continue end
            mutate(self,dc,"skill","olmoguofu")
            mutate(self,dc,"add",c)
            return dc:toString()
        end
    end
end

sgs.ai_skill_invoke.olmomoubian = function(self,data)
    return not q(self,"isWeak")
end

sgs.ai_skill_invoke.olmozhouxi = function(self,data)
    local stp = data:toString():split(":")
    local tp = BeMan(self.room,stp[2])
    return tp and q(self,"isEnemy",tp)
end

sgs.ai_skill_use["ol_shengsiyugong0"] = function(self,prompt,method,pattern)
    local dy = scoped_struct(self,"ol_shengsiyugongData","dying")
    if q(self,"isFriend",dy.who) and q(self,"getAllPeachNum")<1 then
        for _,h in sgs.list(self:getCard("Shengsiyugong",true))do
            return h:toString()
        end
    end
end

sgs.ai_skill_use["ol_luojingxiashi0"] = function(self,prompt,method,pattern)
    local dy = scoped_struct(self,"ol_luojingxiashiData","dying")
    if q(self,"isEnemy",dy.who) then
        for _,h in sgs.list(self:getCard("Luojingxiashi",true))do
            return h:toString()
        end
    end
end

sgs.ai_nullification.Luojingxiashi = function(self,trick,from,to,positive,null_num)
    if positive
    then
        if q(self,"isFriend",to) and q(self,"getAllPeachNum") > 0
        then return true end
    else

    end
end

function SmartAIView:useCardHongyundangtou(card,use)
    self:sort(self.friends_noself,nil,true)
    for _,p in sgs.list(self.friends_noself)do
        if isCurrent(use,p) then continue end
        if q(self,"doDisCard",p,"he") and q(self,"canDraw",p) and target_ok(card,self.player,p,use.to) then
            use.to:append(p)
            use.card = card
        end
    end
    for _,p in sgs.list(self.friends_noself)do
        if isCurrent(use,p) or use.to:contains(p) then continue end
        if q(p,"canDiscard",p,"he") and q(self,"canDraw",p) and target_ok(card,self.player,p,use.to) then
            use.to:append(p)
            use.card = card
        end
    end
end
sgs.ai_use_priority.Hongyundangtou = 8.4
sgs.ai_keep_value.Hongyundangtou = 4
sgs.ai_use_value.Hongyundangtou = 7.7
sgs.ai_nullification.Hongyundangtou = function(self,trick,from,to,positive)
    return q(self,"isEnemy",to)
    and q(to,"getHandcardNum")<3
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
        table.insert(to_cards,q(c,"getId"))
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
    self:sort(self.friends_noself,nil,true)
    for _,p in sgs.list(self.friends_noself)do
        if isCurrent(use,p) then continue end
        if q(self,"canDraw",p) and target_ok(card,self.player,p,use.to) then
            use.to:append(p)
            use.card = card
        end
    end
    for _,p in sgs.list(self.friends_noself)do
        if isCurrent(use,p) or use.to:contains(p) then continue end
        if q(self,"canDraw",p) and target_ok(card,self.player,p,use.to) then
            use.to:append(p)
            use.card = card
        end
    end
end
sgs.ai_use_priority.Liangleichadao = 8.4
sgs.ai_keep_value.Liangleichadao = 4
sgs.ai_use_value.Liangleichadao = 0.7
sgs.ai_nullification.Liangleichadao = function(self,trick,from,to,positive)
    return q(self,"isEnemy",to) and positive
    and q(to,"getHandcardNum")<3
end

sgs.ai_card_intention.Liangleichadao = -66

function SmartAIView:useCardXiongdiqixin(card,use)
    self:sort(self.friends_noself,nil,true)
    for _,p in sgs.list(self.friends_noself)do
        if isCurrent(use,p) then continue end
        if q(self,"canDraw",p) and target_ok(card,self.player,p,use.to) then
            use.to:append(p)
            use.card = card
        end
    end
    for _,p in sgs.list(self.friends_noself)do
        if isCurrent(use,p) or use.to:contains(p) then continue end
        if q(self,"canDraw",p) and target_ok(card,self.player,p,use.to) then
            use.to:append(p)
            use.card = card
        end
    end
end
sgs.ai_use_priority.Xiongdiqixin = 8.4
sgs.ai_keep_value.Xiongdiqixin = 4
sgs.ai_use_value.Xiongdiqixin = 9.7
sgs.ai_nullification.Xiongdiqixin = function(self,trick,from,to,positive)
    return q(self,"isEnemy",to) and positive and q(self,"isWeak",to)
    and q(to,"getHandcardNum")+q(from,"getHandcardNum")>5
end

sgs.ai_card_intention.Xiongdiqixin = -66

sgs.ai_skill_use["@@ol_xiongdiqixin!"] = function(self,prompt)
    local cs = {}
    for _,id in sgs.list(scope_list(self,"ol_xiongdiqixinForAI"))do
        table.insert(cs,known_card(self,id))
    end
    for _,c in sgs.list(self.player:getHandcards())do
        table.insert(cs,c)
    end
    local ids = {}
    self:sortByKeepValue(cs) -- 按保留值排序
    for i,c in sgs.list(cs)do
        if i%2==1 then table.insert(ids,q(c,"getLegacyStringKey")) end
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
    return positive and (to==self.player or q(self,"isWeak",to) and q(self,"isFriend",to))
end

sgs.ai_skill_use["@@ol_qianjiu0"] = function(self,prompt)
    local cs = {}
    for _,c in sgs.list(self.player:getCards("he"))do
        table.insert(cs,c)
    end
    self:sortByUseValue(cs)
    for _,c in sgs.list(cs)do
        if q(c,"isKindOf","Analeptic") or q(c,"getNumber")==9 then
            if q(c,"isAvailable",self.player) then
                local d = use_card(self,c)
                if d.card then
                    local tos = {}
                    for _,p in sgs.list(d.to)do
                        table.insert(tos,q(p,"objectName"))
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

sgs.ai_fill_skill.ofsifen = function(self,inclusive,request)
    return parse_action(self,"#ofsifenCard:.:")
end

sgs.ai_skill_use_func["#ofsifenCard"] = function(card,use,self,request)
    local n = q(self.player,"getMark","ofsifenRed-PlayClear")
    if n>0 then
        local cards = r45_handpile(self,"he")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards) -- 按保留值排序
        local ids = {}
        local dc = preview(self,"duel","ofsifen")
        for _,c in sgs.list(cards)do
            if q(c,"isRed") and #ids<n then
                table.insert(ids,c:toString())
                mutate(self,dc,"add",c)
            end
        end
        if #ids==n and q(dc,"isAvailable",self.player) then
            local btps = {}
            for _,p in sgs.list(self.room:getAllPlayers())do
                if q(self.player,"getMark",q(p,"objectName").."ofsifenDuel-PlayClear")<1
                then table.insert(btps,p) end
            end
            local d = use_card(self,dc,r44_range_dummy(0,btps))
            if d.card then
                use.to = d.to
                use.card = parse_action(self,"#ofsifenCard:"..table.concat(ids,"+")..":")
            end
        end
        return
    end
    self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
        if q(p,"getHandcardNum")>0 then
            use.card = card
            use.to:append(p)
            return
        end
    end
end

sgs.ai_use_value.ofsifenCard = 4.5
sgs.ai_use_priority.ofsifenCard = 2.7

sgs.ai_skill_use["@@ofsifen!"] = function(self,prompt)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
    local dc = preview(self,"duel","_ofsifen")
    for _,c in sgs.list(cards)do
        mutate(self,dc,"add",c)
        if dc:subcardsLength()>=#cards/2 then
            if q(dc,"isAvailable",self.player) then
                local d = use_card(self,dc)
                if d.card then
                    local tos = {}
                    for _,p in sgs.list(d.to)do
                        table.insert(tos,q(p,"objectName"))
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
        if q(dc,"isAvailable",self.player) then
            local d = use_card(self,dc)
            if d.card then
                local tos = {}
                for _,p in sgs.list(d.to)do
                    table.insert(tos,q(p,"objectName"))
                end
                return dc:toString().."->"..table.concat(tos,"+")
            end
            for _,p in sgs.list(self.room:getAllPlayers())do
                if target_ok(dc,self.player,p) then
                    return dc:toString().."->"..q(p,"objectName")
                end
            end
            break
        end
    end
end

sgs.ai_skill_invoke.offunan = function(self,data)
    for _,p in sgs.list(self.friends_noself)do
        if q(p,"getKingdom")=="shu" and getCardsNum("Slash",p,self.player)>0 then
            return true
        end
    end
    return not q(self,"isWeak")
end

sgs.ai_fill_skill.offunan = function(self,inclusive,request)
    return sgs.ai_skill_invoke.offunan(self)
    and parse_action(self,"#offunanCard:.:")
end

sgs.ai_skill_use_func["#offunanCard"] = function(card,use,self,request)
    local dc = preview(self,"slash")
    if q(dc,"isAvailable",self.player) then
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
        if #tps<2 and q(self,"isEnemy",p) then
            table.insert(tps,p)
        end
    end
    return tps
end

sgs.ai_skill_invoke.ofshezuo = function(self,data)
    return not q(self,"isWeak")
end

sgs.ai_fill_skill.ofshezuo = function(self,inclusive,request)
    return #self.enemies>0 and parse_action(self,"#ofshezuoCard:.:")
end

sgs.ai_skill_use_func["#ofshezuoCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value.ofshezuoCard = 4.5
sgs.ai_use_priority.ofshezuoCard = 6.7

sgs.ai_skill_playerchosen.ofshezuo = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    for _,p in sgs.list(destlist)do
        if q(self,"isEnemy",p) then
            return p
        end
    end
    for _,p in sgs.list(destlist)do
        if not q(self,"isFriend",p) then
            return p
        end
    end
end

sgs.ai_skill_askforag.ofshezuo = function(self,card_ids)
    local cards = {}
    for _,id in sgs.list(card_ids)do
        table.insert(cards,known_card(self,id))
    end
    self:sortByKeepValue(cards,true) -- 按保留值排序
    for _,c in sgs.list(cards)do
        local dc = preview(self,q(c,"objectName"))
        mutate(self,dc,"skill","_mourende")
        mutate(self,dc,"recast",false)
        if q(dc,"isAvailable",self.player) then
            local d = use_card(self,dc)
            if d.card then
                set_state(self,"ofshezuoUse",d)
                return q(c,"getId")
            end
        end
    end
end

sgs.ai_skill_use["@@ofshezuo!"] = function(self,prompt)
    local dummy = get_state(self,"ofshezuoUse")
    if dummy.card then
        local tos = {}
        for _,p in sgs.list(dummy.to)do
            table.insert(tos,q(p,"objectName"))
        end
        return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_fill_skill.ofjixu = function(self,inclusive,request)
    return parse_action(self,"#ofjixuCard:.:")
end

sgs.ai_skill_use_func["#ofjixuCard"] = function(card,use,self,request)
    local tps = self:sort(self.room:getAllPlayers())
    for _,p in sgs.list(tps)do
        if q(p,"getMark","ofjixuTo-PlayClear")<1 and use.to:length()<2
        and q(self,"isFriend",p) and q(self,"canDraw",p) then
            use.to:append(p)
        end
    end
    for _,p in sgs.list(tps)do
        if q(p,"getMark","ofjixuTo-PlayClear")<1 and use.to:length()<2
        and not use.to:contains(p) and q(self,"isFriend",p) then
            use.to:append(p)
        end
    end
    for _,p in sgs.list(tps)do
        if q(p,"getMark","ofjixuTo-PlayClear")<1 and use.to:length()<2
        and not use.to:contains(p) and not q(self,"isEnemy",p) then
            use.to:append(p)
        end
    end
    for _,p in sgs.list(tps)do
        if q(p,"getMark","ofjixuTo-PlayClear")<1 and use.to:length()==1
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

sgs.ai_skill_use["@@ofjixu!"] = function(self,prompt)
    local cs = {}
    for _,id in sgs.list(scope_list(self,"ofjixuForAI"))do
        table.insert(cs,known_card(self,id))
    end
    local aps = {}
    for _,p in sgs.list(self.room:getAllPlayers())do
        if q(p,"hasFlag","ofjixuTo") then table.insert(aps,p) end
    end
    local ids = {}
    local tps = {}
    for i = 1,#cs do
        local c,p = self:getCardNeedPlayer(cs,nil,aps)
        if c and p then
            table.insert(ids,q(c,"getLegacyStringKey"))
            table.insert(tps,q(p,"objectName"))
            table.removeOne(cs,c)
            table.removeOne(aps,p)
            if #cs<1 or #aps<1 then break end
        end
    end
    self:sort(aps)
    for i,p in sgs.list(aps)do
        table.insert(tps,q(p,"objectName"))
    end
    self:sortByKeepValue(cs) -- 按保留值排序
    for i,c in sgs.list(cs)do
        table.insert(ids,q(c,"getLegacyStringKey"))
    end
    return "#ofjixuCard:"..table.concat(ids,"+")..":->"..table.concat(tps,"+")
end

sgs.ai_fill_skill.ofyouchong = function(self,inclusive,request)
    return #self.friends_noself>0
    and parse_action(self,"#ofyouchongCard:.:")
end

sgs.ai_skill_use_func["#ofyouchongCard"] = function(card,use,self,request)
    for _,p in sgs.list(pattern_names(self))do
        local dc = preview(self,p)
        if dc and q(dc,"getTypeId")==1 and q(dc,"isAvailable",self.player) then
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
        if not q(self,"isEnemy",p) then
            table.insert(tps,p)
        end
    end
    return tps
end


sgs.ai_skill_cardask["@@ofyouchong"] = function(self,data)
    local tp = data:toPlayer()
    if q(self,"isEnemy",tp) or #self.enemies<1 then return "." end
    local cn = property_value(self,self.player,"ofyouchongCN")
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
    local dc = preview(self,cn,"_ofyouchong")
    for _,h in sgs.list(cards)do
        mutate(self,dc,"add",h)
        if dc:subcardsLength()>2
        then return dc:toString() end
    end
    return "."
end

sgs.ai_fill_skill.jiechu = function(self,inclusive,request)
    return preview(self,"snatch","jiechu")
end

sgs.ai_skill_cardask["jiechu1"] = function(self,data)
    local use = data:toCardUse()
    if q(self.player,"getMark",q(use.card,"getSuitString").."daojueSuit")<1 then return "." end
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,h in sgs.list(cards)do
        return dc:toString()
    end
    return "."
end

sgs.ai_skill_invoke.tuonan = function(self,data)
    return q(self,"getCardsNum","Peach,Analeptic")+q(self.player,"getHp")<1
end

sgs.ai_skill_playerchosen.yingzhen = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    for _,p in sgs.list(destlist)do
        if q(self,"isFriend",p) then
            return p
        end
    end
    for _,p in sgs.list(destlist)do
        if not q(self,"isEnemy",p) then
            return p
        end
    end
end

sgs.ai_skill_invoke.yuanjue = function(self,data)
    return q(self,"getOverflow")>0
end

sgs.ai_skill_invoke.aoyong = function(self,data)
    return q(self,"canDraw") or q(self.player,"isWounded")
end

sgs.ai_skill_choice.aoyong = function(self,choices,data)
    local items = choices:split("+")
    if table.contains(items,"aoyong2") and q(self,"isWeak") then
        return "aoyong2"
    end
    if table.contains(items,"aoyong3") then
        for _,c in sgs.list(self.player:getHandcards())do
            if use_card(self,c) then
                return "aoyong3"
            end
        end
    end
    if table.contains(items,"aoyong2") then
        return "aoyong2"
    end
    if table.contains(items,"aoyong1") then
        return "aoyong1"
    end
end

sgs.ai_skill_invoke.tongkai = function(self,data)
    local to = data:toPlayer()
    return not q(self,"isEnemy",to)
end

sgs.ai_skill_invoke.dianmo = function(self,data)
    return q(self,"canDraw") or q(self.player,"isWounded")
end

sgs.ai_fill_skill.zaibi = function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
    while #cards>0 do
        local cs = {}
        for _,c in sgs.list(cards)do
            if self:wasPreviouslyPlannedCard(c) then continue end
            local has = false
            for _,t in sgs.list(cs)do
                if q(t,"getNumber")==q(c,"getNumber") then
                    has = true
                    break
                end
            end
            if has then continue end
            if #cs>0 then
                for _,t in sgs.list(cs)do
                    if math.abs(q(t,"getNumber")-q(c,"getNumber"))==1 then
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
            table.insert(ids,q(c,"getId"))
        end
        if #ids>1 then
            return parse_action(self,"#zaibiCard:"..table.concat(ids,"+")..":")
        end
        table.removeOne(cards,cs[1])
    end
end

sgs.ai_skill_use_func["#zaibiCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value.zaibiCard = 4.5
sgs.ai_use_priority.zaibiCard = 7.7

sgs.ai_fill_skill._chunqiubi = function(self,inclusive,request)
    return parse_action(self,"#_chunqiubiCard:.:")
end

sgs.ai_skill_use_func["#_chunqiubiCard"] = function(card,use,self,request)
    local tps = self:sort(self.room:getAllPlayers())
    for _,p in sgs.list(tps)do
        if not q(self,"isFriend",p) then
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
        if (q(self,"isFriend",target) or q(target,"isWounded")) or q(self,"isEnemy",target) then
            return target
        end
    end
end

sgs.ai_skill_choice["nyarz_falu"] = function(self, choices, data)
    local target = data:toPlayer()
    if q(self,"isFriend",target) then
        return "recover"
    end
    return "losehp"
end

sgs.ai_playerchosen_intention.nyarz_falu = function(self, from, to)
    if q(self,"isFriend",to) then
        self:updateIntention(from, to, -80)
    else
        self:updateIntention(from, to, 80)
    end
end

sgs.ai_skill_invoke.cangqiao = function(self,data)
    return q(self,"canDraw")
end

sgs.ai_skill_playerchosen.godshenji = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    local cns = scope(self,"godshenjiCNS"):split("+")
    for _,p in sgs.list(destlist)do
        for _,id in sgs.qlist(p:getEquipsId())do
            if q(self,"doDisCard",p,id) then
                for _,cn in sgs.list(cns)do
                    local dc = preview(self,cn,"godshenji")
                    mutate(self,dc,"add",id)
                    if q(dc,"isAvailable",self.player) then
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
        if q(self,"isFriend",p) then continue end
        for _,id in sgs.qlist(p:getEquipsId())do
            for _,cn in sgs.list(cns)do
                local dc = preview(self,cn,"godshenji")
                mutate(self,dc,"add",id)
                if q(dc,"isDamageCard") and q(dc,"targetFixed") and q(dc,"isAvailable",self.player) then
                    set_state(self,"godshenji_use",{card = dc,to = {}})
                    set_choice(self,"godshenji",cn)
                    return p
                end
            end
        end
    end
end

sgs.ai_skill_use["@@godshenji"] = function(self,prompt)
    local dummy = get_state(self,"godshenji_use")
    if dummy.card then
        local tos = {}
        for _,p in sgs.list(dummy.to)do
            table.insert(tos,q(p,"objectName"))
        end
        return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_choice.huaxiu = function(self,choices,data)
    local items = choices:split("+")
    for _,t in sgs.list(items)do
        for _,e in sgs.qlist(player:getEquips())do
            if t:contains(q(e,"objectName")) then
                return t
            end
        end
    end
end

sgs.ai_use_revises.cangqiao = function(self,card,use)
    if q(self.player,"getHandcardNum")<q(self.player,"getMaxHp")
    and (q(card,"objectName")=="yj_numa" or q(card,"objectName")=="yj_nvzhuang" or q(card,"objectName")=="yj_zheji")
    then return true end
end

sgs.ai_skill_invoke._ofhun_crossbow = function(self,data)
    return true
end

sgs.ai_skill_choice._ofhun_crossbow = function(self,choices,data)
    local items = choices:split("+")
    for _,t in sgs.list(items)do
        for _,p in sgs.qlist(room:getPlayers())do
            if t:endsWith(q(p,"objectName")) and q(self,"objectiveLevel",p)>1 then
                return t
            end
        end
    end
end

sgs.ai_skill_invoke._ofhun_eight_diagram = function(self,data)
    return true
end

sgs.ai_skill_choice._ofhun_eight_diagram = function(self,choices,data)
    local items = choices:split("+")
    for _,t in sgs.list(items)do
        for _,p in sgs.qlist(room:getPlayers())do
            if t:endsWith(q(p,"objectName")) and q(self,"objectiveLevel",p)>1 then
                return t
            end
        end
    end
end

sgs.ai_skill_playerchosen._of_lingling = function(self,players)
    local destlist = sgs.QList2Table(players) -- 将列表转换为表
    self:sort(destlist)
    for _,p in sgs.list(destlist)do
        if q(self,"isEnemy",p) and q(self,"damageIsEffective",p,"T",self.player) then
            return p
        end
    end
    for _,p in sgs.list(destlist)do
        if q(self,"isEnemy",p) then
            return p
        end
    end
end





sgs.ai_skill_choice.godshenji=function(self)return get_choice(self,"godshenji")end
sgs.ai_skill_choice.jisi=function(self)return get_choice(self,"jisi")end
sgs.ai_skill_choice.kemobileyijin=function(self)return get_choice(self,"kemobileyijin")end
sgs.ai_skill_choice.keolbixin=function(self)return get_choice(self,"keolbixin")end
sgs.ai_skill_choice.keolcihuang=function(self)return get_choice(self,"keolcihuang")end
sgs.ai_skill_choice.keolgoudekingdom=function(self)return get_choice(self,"keolgoudekingdom")end
sgs.ai_skill_choice.keolzhuyan=function(self)return get_choice(self,"keolzhuyan")end
sgs.ai_skill_choice.liangyuan=function(self)return get_choice(self,"liangyuan")end
-- The source constructs a strategy seed before choosing targets/costs. Rebind
-- exactly the first selected proposal, without re-running the policy.
for class,skill in pairs(action_skills)do
    local fn=sgs.ai_skill_use_func[class]
    if type(fn)=='function' then
        sgs.ai_skill_use_func[class]=function(card,use,self,request)
            local previous=self._newgenerals_request
            self._newgenerals_request=request
            local ok,result=pcall(fn,card,use,self,request)
            self._newgenerals_request=previous
            if not ok then error(result,0)end
            if use.card then use.card=materialize_action(self,use.card,request)end
            return result
        end
    end
end
local newgenerals_fill_names={"_chunqiubi","chongjian","chuifeng","hannan","huishi","huishii","jiechu","jinghe","kehuiyao","kemobileguanzong","keolbixin","keolkenshang","keolqingyi","keolsaogu","keolshandao","keolshizhan","keolshuangxiong","keolweilin","keolxianbi","keolxieju","keolyilie","keolzhenying","keolzhubi","liangyuan","mobile_dingzou","mobile_wuling","mobile_youyi","mobiledamingvs","mobilefenming","mobilejingxie","mobileqiaosi","mobilexiaoni","moufanjian","moufenwei","mouguose","mouhuoji","moujiang","moujiewei","moujushou","mouliangzhu","moulianhuan","moulijian","moulongdan","mouluanji","moumingce","mouqicai","mouqixi","mourende","moutianxiang","mouwusheng","mouxuanhuo","mouyanyu","mouzhangwu","mouzhenliang","nhhuoqi","nhxianshou","nosjinwanyi","ny_ol_yanru","offunan","ofjixu","ofshezuo","ofsifen","ofyouchong","oldimeng","olfuman","olmoguofu","olxiaofan","renbinglun","renluanchou","tyzhuangpo","xdyifuvs","xin2chuhai","xiongsuan","yanduanbi","yanyangjie","yingba","yongshanxie","zaibi","zhaoluan","zuoxing"}
for _,skill in ipairs(newgenerals_fill_names)do
    local fn=sgs.ai_fill_skill[skill]
    sgs.ai_fill_skill[skill]=function(self,inclusive,request)
        local previous,stage=self._newgenerals_request,self._newgenerals_stage
        self._newgenerals_request,self._newgenerals_stage=request,'fill'
        local ok,result=pcall(fn,self,inclusive,request)
        self._newgenerals_request,self._newgenerals_stage=previous,stage
        if not ok then error(result,0)end
        return select_preview(self,result,request)
    end
end
