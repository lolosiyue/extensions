-- Source Guanxing policies and their classical-control dependency.
-- Only disclosed cards and viewer-local strategy memory cross inquiries.
local known = AIValue.requireKnown
local function query(object,method,...)
    if type(object)~="table" or type(object[method])~="function" then ai_unsupported("guanxing requires "..method,"guanxing") end
    return known(object[method](object,...),method)
end
local function split(value,separator)
    local result,start={},1
    while true do
        local pos=value:find(separator,start,true)
        if not pos then result[#result+1]=value:sub(start);return result end
        result[#result+1]=value:sub(start,pos-1);start=pos+#separator
    end
end
local function remove_one(cards,card)
    for i,c in ipairs(cards)do if c==card then table.remove(cards,i);return true end end
    return false
end
local function append_all(cards,other)for _,card in ipairs(other)do cards[#cards+1]=card end end
local function reverse(cards)local result={}for i=#cards,1,-1 do result[#result+1]=cards[i]end;return result end
local function same_player(a,b)return a and b and query(a,"objectName")==query(b,"objectName")end
local function card_by_id(self,id)
    local card=known(self:getChoiceCard(id) or self:getKnownCardById(id),"disclosed card "..tostring(id))
    -- Keep the same physical identity, enriching it only with the current
    -- inquiry's readonly owner evaluation (residue/limits). This grants neither
    -- ownership nor submission authority for the disclosed draw-pile card.
    local evaluation=self:getAcquiredCardEvaluation(card)
    return evaluation or card
end
local function cards_from_ids(self,ids)local cards={}for _,id in ipairs(ids)do cards[#cards+1]=card_by_id(self,id)end;return cards end
local function ids_from_cards(cards)local ids={}for _,card in ipairs(cards)do ids[#ids+1]=query(card,"getId")end;return ids end
local function note(self,basis,value)
    return query(self,"useKnowledgeEstimate",{status="estimate",value=value,basis=basis},"guanxing")
end

-- Exact ExpPattern factor semantics. Native userdata is never reconstructed.
function SmartAIView:matchGuanxingPattern(pattern,player,card)
    if type(pattern)~="string" then ai_unsupported("judge pattern is unknown","guanxing")end
    if pattern:sub(1,1)=="$"then
        pattern=pattern:gsub("%$","")
        if player and not query(card,"isAvailable",player)then return false end
    end
    local function term(text)local neg=text:sub(1,1)=="^";return neg and text:sub(2)or text,neg end
    local function integer(text)
        text=text:match("^%s*(.-)%s*$")
        if not text:match("^[+-]?%d+$")then return nil end
        local n=tonumber(text);if n and n>=-2147483648 and n<=2147483647 then return n end
    end
    local function one(expression)
        local f=split(expression,"|")
        if f[1]~="."then
            local checkpoint=false
            local kind=query(card,"getType")
            local percent="%"..query(card,"objectName")
            local serialized
            for _,group in ipairs(split(f[1],","))do
                for _,raw in ipairs(split(group,"+"))do
                    local text,neg=term(raw)
                    local hit=kind==text
                    if not hit then
                        serialized=serialized or query(card,"getLegacyStringKey")
                        hit=serialized==text or percent==text or query(card,"isKindOf",text)
                    end
                    checkpoint=hit and not neg or not hit and neg
                    if not checkpoint then break end
                end
                if checkpoint then break end
            end
            if not checkpoint then return false end
        end
        if #f<2 then return true end
        if f[2]~="."then
            local suit=query(card,"getSuitString")
            local color=query(card,"isRed")and"red"or query(card,"isBlack")and"black"or"no_color"
            local checkpoint=false
            for _,raw in ipairs(split(f[2],","))do
                local text,neg=term(raw);local hit=suit==text or color==text
                checkpoint=hit and not neg or not hit and neg
                if checkpoint then break end
            end
            if not checkpoint then return false end
        end
        if #f<3 then return true end
        if f[3]~="."then
            local checkpoint=false
            for _,raw in ipairs(split(f[3],","))do
                local text,neg=term(raw);checkpoint=neg
                local range=split(text,"~")
                if #range>1 then
                    local low=range[1]~=""and(integer(range[1])or 0)or 1
                    local high=range[2]~=""and(integer(range[2])or 0)or 13
                    local value=query(card,"getNumber")
                    if value>=low and value<=high then checkpoint=not neg end
                else
                    local value=integer(text)
                    if value~=nil then if value==query(card,"getNumber")then checkpoint=not neg end
                    elseif text==query(card,"getNumberString")then checkpoint=not neg end
                end
                if checkpoint then break end
            end
            if not checkpoint then return false end
        end
        if #f<4 then return true end
        if f[4]~="."and player then
            local checkpoint=false
            for _,raw in ipairs(split(f[4],","))do
                local place,neg=term(raw)
                for _,id in ipairs(query(card,"getSubcards"))do
                    checkpoint=neg
                    local contains=false
                    if place=="equipped"or place=="hand"then
                        local cards=query(player,place=="equipped"and"getEquips"or"getHandcards")
                        for _,held in ipairs(cards)do if query(held,"getEffectiveId")==id then contains=true break end end
                    elseif place:sub(1,1)=="%"then
                        for _,other in ipairs(query(player,"getAliveSiblings"))do
                            for _,held in ipairs(query(other,"getPile",place:sub(2)))do if held==id then contains=true break end end
                            if contains then break end
                        end
                    else for _,held in ipairs(query(player,"getPile",place))do if held==id then contains=true break end end end
                    if contains then checkpoint=not neg end
                    if not checkpoint then break end
                end
                if checkpoint then return true end
            end
            return false
        end
        return true
    end
    for _,alternative in ipairs(split(pattern,"#"))do if one(alternative)then return true end end
    return false
end

sgs.ai_judgestring=sgs.ai_judgestring or {}
sgs.ai_judgestring.indulgence=".|heart"
sgs.ai_judgestring.supply_shortage=".|club"
sgs.ai_judgestring.lightning={".|spade|2~9",false}
sgs.ai_skill_guanxing=sgs.ai_skill_guanxing or {}
local function judge_pattern(self,card)
    local patterns,present=self:getEventMemory("judge_patterns")
    local name=query(card,"objectName")
    local value=present and type(patterns)=="table"and patterns[name]or sgs.ai_judgestring[name]
    if not present then note(self,"guanxing_unobserved_judge_patterns_use_public_defaults",0)end
    if type(value)=="string"then return {value,true}end
    if type(value)=="table"then return value end
    return {".|"..query(card,"getSuitString"),true}
end
local function effect_bonus(self)
    local effect,present=self:getEventMemory("card_effect")
    local dongzhu=false
    if present and effect and effect.card then dongzhu=query(CardView.new(effect.card),"isKindOf","Dongzhuxianji")
    elseif not present then dongzhu=note(self,"guanxing_unobserved_card_effect_assume_absent",false)end
    local friend=self:getStrategyMemory("guanxing_friend")
    if dongzhu or friend then
        self:setStrategyMemory("guanxing_friend",false)
        note(self,"viewer_local_guanxing_friend_without_private_cross_viewer_propagation",0)
        return true
    end
    return false
end
local function available(self,card)
    local projected=self:getAcquiredCardEvaluation(card)
    return query(known(projected,"acquired card evaluation"),"isAvailable",self.player)
end
local function evaluate(self,card)return query(self,"evaluateAcquiredCard",card)end
local function drawer_relation(self,player)
    if same_player(player,self.player) or query(self,"isFriend",player) then return "friend" end
    if query(self,"isEnemy",player) then return "enemy" end
end
-- Bottom is ordered best first. Friends draw the best cards, the viewer
-- preferring one it can use; enemies draw the least useful ones.
local function feed_draws(self,up,bottom,count,relation,own)
    for _=1,count do
        if #bottom<1 then break end
        local pick=relation=="enemy" and #bottom or 1
        if own then
            for i,c in ipairs(bottom)do if evaluate(self,c).card then pick=i break end end
        end
        table.insert(up,table.remove(bottom,pick))
    end
end
-- Top cards are consumed in turn order from the current player: its pending
-- judgments and draw, then the next acting player's judgments and draw. Only
-- phases still ahead count, so Guanxing outside one's own Start phase works.
-- Each pending judgment owns a separate slot, even for repeated trick names.
local function GuanXing(self,cards,up_only)
	local up,bottom = {},cards_from_ids(self,cards)
	self:sortByUseValueInPlace(bottom, true)
	if query(self.player,"hasSkill","myjincui") then
		local cs = {}
		for _,c in ipairs(AIList.new(bottom))do
			if query(c,"getNumber")==7 then
				table.insert(cs,c)
				remove_one(bottom,c)
			end
		end
		append_all(bottom,cs)
	end
	local lightnings = {}
   	local target = self.room:getCurrent() or self.player
	local phase = query(target,"getPhase")
	local judge = AIList.new(query(target,"getJudgingArea"))
	local self_has_judged,willSkipDrawPhase,willSkipPlayPhase
	if #judge>0 and phase<=sgs.Player_Judge and not query(target,"isSkipped",sgs.Player_Judge)
	and not query(target,"containsTrick","YanxiaoCard") then
		judge = reverse(judge)
		local judged_list = {}
		for i,jc in ipairs(judge)do
			if query(jc,"isKindOf","Indulgence") then
				willSkipPlayPhase = true
				if query(target,"isSkipped",sgs.Player_Play) then continue end
			elseif query(jc,"isKindOf","SupplyShortage") then
				willSkipDrawPhase = true
				if query(target,"isSkipped",sgs.Player_Draw) then continue end
			elseif query(jc,"isKindOf","DelayedTrick") and query(jc,"isDamageCard") then
				table.insert(lightnings,jc)
			end
			local judge_str = judge_pattern(self,jc)
			for _,c in ipairs(AIList.new(bottom))do
				local cf = query(self,"CardFilter",c,target)
				if query(self,"matchGuanxingPattern",judge_str[1],target,cf)==judge_str[2] and query(self,"isFriend",target)
				or query(self,"matchGuanxingPattern",judge_str[1],target,cf)~=judge_str[2] and query(self,"isEnemy",target) then
					judged_list[i] = c
					if query(jc,"isKindOf","SupplyShortage")
					then willSkipDrawPhase = false
					elseif query(jc,"isKindOf","Indulgence")
					then willSkipPlayPhase = false end
					self_has_judged = true
					remove_one(bottom,c)
					break
				end
			end
		end
		for i,jc in ipairs(judge)do
			local c = judged_list[i]
			if c then table.insert(up,c)
			else table.insert(up,table.remove(bottom,1)) end
		end
	end
	if not up_only and effect_bonus(self) then
		for _,c in ipairs(AIList.new(bottom))do
			if query(self.player,"getPhase")<=sgs.Player_Play and query(self,"cardNeed",c)>6
			and available(self,c) and evaluate(self,c).card
			then table.insert(up,c) remove_one(bottom,c) end
		end
		for _,c in ipairs(AIList.new(bottom))do
			if query(self,"cardNeed",c)>6 then
				table.insert(up,c)
				remove_one(bottom,c)
			end
		end
	end
	local drawCards = query(self,"ImitateResult_DrawNCards",target,query(target,"getVisibleSkillList",true))
	if willSkipDrawPhase or phase>sgs.Player_Draw then drawCards = 0 end
	-- Whoever draws next takes the following cards; with an unreadable
	-- relation those draws stay unplanned and so does everything after them.
	local drawer = drawCards>0 and drawer_relation(self,target)

	local np = query(target,"getNextAlive")
	while not same_player(np,target) do
		if query(np,"faceUp") then break end
		np = query(np,"getNextAlive")
	end
	judge = {}
	if drawCards==0 or drawer then
		judge = AIList.new(query(np,"getJudgingArea"))
		for i,jc in ipairs(lightnings)do
			if query(np,"containsTrick",query(jc,"objectName")) then continue end
			table.insert(judge,jc)
		end
	end
	judge = reverse(judge)
	local judged_list = {}
	-- Unknown allegiance is not an enemy judgment-control opportunity.
	local next_relation
	if #judge>0 and #bottom>drawCards then
		next_relation = query(self,"relationTo",np)
		if next_relation~="friend" and next_relation~="enemy" then
			ai_unsupported("next judgment target relation is unknown","guanxing")
		end
	end
	for x,jc in ipairs(judge)do
		local n = x-1
		if #bottom-drawCards-n<1 then break end
		local judge_str = judge_pattern(self,jc)
		for _,c in ipairs(AIList.new(bottom))do
			local cf = query(self,"CardFilter",c,np)
			if next_relation=="friend" then
				if query(self,"matchGuanxingPattern",judge_str[1],np,cf)==judge_str[2] then
					judged_list[x] = c
					remove_one(bottom,c)
					break
				end
			elseif query(self,"matchGuanxingPattern",judge_str[1],np,cf)~=judge_str[2] then
				judged_list[x] = c
				remove_one(bottom,c)
				break
			end
		end
	end
	self:sortByUseValueInPlace(bottom)
	if #bottom>0 and query(self.player,"hasSkill","myjincui") then
		local cs = {}
		for _,c in ipairs(AIList.new(bottom))do
			if query(c,"getNumber")==7 then
				table.insert(cs,c)
				remove_one(bottom,c)
			end
		end
		append_all(bottom,cs)
	end
	if drawer then feed_draws(self,up,bottom,drawCards,drawer,same_player(target,self.player)) end
	local next_draws = phase>sgs.Player_Play and phase<sgs.Player_NotActive
	for i,jc in ipairs(judge)do
		local c = judged_list[i]
		if not c and #bottom>0 then c = table.remove(bottom,#bottom) end
		if c then table.insert(up,c) else next_draws = false end
		-- The planned card decides whether the next player still draws.
		if c and query(jc,"isKindOf","SupplyShortage") then
			local judge_str = judge_pattern(self,jc)
			local cf = query(self,"CardFilter",c,np)
			if query(self,"matchGuanxingPattern",judge_str[1],np,cf)~=judge_str[2] then next_draws = false end
		end
	end
	-- Once the current turn is past its Play phase nothing else draws before
	-- the next acting player's Draw phase, e.g. Guanxing in a Finish phase.
	if next_draws and #bottom>0 then
		local relation = drawer_relation(self,np)
		if relation then
			local count = query(self,"ImitateResult_DrawNCards",np,query(np,"getVisibleSkillList",true))
			feed_draws(self,up,bottom,count,relation,same_player(np,self.player))
		end
	end
	--query(self.player,"speak","GuanXing="..#up.."="..#bottom)
	return ids_from_cards(up),ids_from_cards(bottom)
end

-- Classical control state is viewer-local. The donor's cross-viewer globals
-- cannot carry another viewer's private future-general arrangement.
local function kof_state(self)
    local marks=self:getStrategyMemory("classical.kof_marks") or {}
    local state=self:getStrategyMemory("classical.kof_globals") or {
        type={},suit={},result={},detail={EruptSkill={},MaxInterval={},ControlFinished={}}}
    return marks,state
end
local function kof_mark(self,marks,name)
    if marks[name]==nil then marks[name]=query(self.player,"getMark",name)end
    return marks[name]
end
local function kof_save(self,marks,state)
    self:setStrategyMemory("classical.kof_marks",marks)
    self:setStrategyMemory("classical.kof_globals",state)
end
local function kof_start(self,marks,state)
    if query(self.player,"hasSkill","guanxing")or query(self.player,"hasSkill","super_guanxing")then
        local arrange=known(nil,"owner 1v1Arrange") -- Future generals' skills are not projected.
        for follow,general in ipairs(arrange)do
            if general.exists~=true then ai_unsupported("donor 1v1Arrange references nonexistent general","guanxing")end
            local skills=known(general.has_skills,"future general skill membership")
            local flag,skill,interval=false
            if known(skills.luoshen,"future luoshen")then
                state.suit={sgs.Card_Spade,sgs.Card_Club};skill,interval,flag="luoshen",0,true
            elseif known(skills.jizhi,"future jizhi")then
                state.type={"TrickCard"};skill,interval="jizhi",1
            elseif known(skills.xiaoji,"future xiaoji")then
                state.type={"EquipCard"};skill,interval="xiaoji",2
            elseif known(skills.guhuo,"future guhuo")then
                state.suit={sgs.Card_Heart};skill,interval="guhuo",1
            elseif known(skills.caizhaoji_hujia,"future caizhaoji_hujia")then
                state.suit={sgs.Card_Heart,sgs.Card_Diamond};skill,interval,flag="caizhaoji_hujia",0,true
            end
            if skill then state.detail={EruptSkill={skill},MaxInterval={interval},ControlFinished={false}}end
            -- Intentionally retain the other type/suit list and prior strict mark.
            if #state.type>0 or #state.suit>0 then
                marks.KOFControl=follow
                if flag then marks.StrictControl=1 end
                return true
            end
        end
    end
    marks.KFC_Forbidden=1
    return false
end
local function kof_guanxing(self,cards,marks,state)
    local up,bottom={},{}
    local strict=kof_mark(self,marks,"StrictControl")>0
    for _,id in pairs(cards)do
        local card=card_by_id(self,id)
        local matches=false
        for _,suit in ipairs(state.suit)do if query(card,"getSuit")==suit then matches=true break end end
        if not matches then
            for _,class in ipairs(state.type)do if query(card,"isKindOf",class)then matches=true break end end
        end
        if matches then
            if query(card,"isKindOf","Peach")and query(self,"isWeak")then up[#up+1]=id
            else bottom[#bottom+1]=id;state.result[#state.result+1]=id;marks.KOFInterval=0 end
        elseif strict then up[#up+1]=id
        elseif query(card,"isKindOf","Crossbow")then
            bottom[#bottom+1]=id;state.result[#state.result+1]=id
            marks.KOFInterval=kof_mark(self,marks,"KOFInterval")+1
        else
            local interval=kof_mark(self,marks,"KOFInterval")
            local maximum=state.detail.MaxInterval[1]
            local value=maximum and interval<maximum and sgs.ai_use_value[query(card,"objectName")]
            if value and value>4 then
                bottom[#bottom+1]=id;state.result[#state.result+1]=id;marks.KOFInterval=interval+1
            else up[#up+1]=id end
        end
    end
    kof_save(self,marks,state)
    return up,bottom
end
function SmartAIView:askForGuanxing(cards,guanxing_type)
    -- Future-general control only belongs to duel mode. Ordinary Guanxing
    -- must not require the unprojected private 1v1Arrange roster.
    if guanxing_type==sgs.Room_GuanxingBothSides and query(self.room,"getMode")=="02_1v1" then
        local marks,state=kof_state(self)
        if kof_mark(self,marks,"KFC_Forbidden")==0 then
            note(self,"viewer_local_classical_control_without_private_cross_viewer_globals",0)
            local selected=kof_mark(self,marks,"KFC_Control")>0 or kof_start(self,marks,state)
            kof_save(self,marks,state)
            if selected then return kof_guanxing(self,cards,marks,state)end
        end
    end
    if guanxing_type==sgs.Room_GuanxingBothSides then return GuanXing(self,cards)
    elseif guanxing_type==sgs.Room_GuanxingUpOnly then
        -- Same consumer plan; cards it would leave at the bottom follow on top.
        local up,bottom=GuanXing(self,cards,true)
        append_all(up,bottom)
        return up,{}
    elseif guanxing_type==sgs.Room_GuanxingDownOnly then return {},cards end
    return cards,{}
end

-- Native Guanxing uses this reason for every source skill. Keep the current
-- request's offered IDs and direction; no legacy callback or cached card IDs.
ai_skill_guanxing.guanxing = function(self, options, request)
    if type(options)~="table" or not AIValue.isList(options.card_ids) then
        ai_unsupported("guanxing cards are missing","guanxing")
    end
    local mode=tonumber(options.default_choice)
    if mode~=sgs.Room_GuanxingBothSides and mode~=sgs.Room_GuanxingUpOnly
        and mode~=sgs.Room_GuanxingDownOnly then
        ai_unsupported("guanxing direction is unknown","guanxing")
    end
    local remaining={}
    for _,id in ipairs(options.card_ids)do
        if type(id)~="number" or id<0 or id%1~=0 or remaining[id] then
            ai_unsupported("invalid guanxing offered card domain","guanxing")
        end
        remaining[id]=true
    end
    local up,down=self:askForGuanxing(AIList.new(options.card_ids),mode)
    if not AIValue.isList(up) or not AIValue.isList(down) then
        ai_unsupported("invalid guanxing ordered piles","guanxing")
    end
    -- A judgment allocation must partition the request exactly once.
    for _,pile in ipairs({up,down})do
        for _,id in ipairs(pile)do
            if not remaining[id] then ai_unsupported("guanxing repeated or unoffered card","guanxing") end
            remaining[id]=nil
        end
    end
    if next(remaining)~=nil or mode==sgs.Room_GuanxingUpOnly and #down>0
        or mode==sgs.Room_GuanxingDownOnly and #up>0 then
        ai_unsupported("guanxing result violates the request","guanxing")
    end
    return {kind="answer",cards=up,bottom_cards=down}
end
function SmartAIView:getValuableCardForGuanxing(cards)
    local id=self:selectAmazingGracePolicy(ids_from_cards(cards))
    if AIUnsupported.is(id)then error(id,0)end
    if id then return card_by_id(self,id)end
end
