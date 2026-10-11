-- ol_qifu, fixed b6025acc. Only effective live registries are installed.
-- Shadow Aocai invoke/AG and Duwu bodies belong to the effective source owner.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported('ol_qifu input unavailable',k)end;return v end
local nullable={recordAocaiSourceDrawIdentity=true,toPlayer=true,getStrategyMemory=true,getCurrentDyingPlayer=true,getCurrent=true,getArmor=true,getWeapon=true,getOffensiveHorse=true,getDefensiveHorse=true,findPlayerBySkillName=true,getCardNeedPlayer=true,aiUseCard=true,updateIntention=true,setStrategyCardFlag=true,setStrategyPlayerFlag=true,setStrategyMemory=true}
local function q(o,k,...)
 if not o or type(o[k])~='function'then ai_unsupported('ol_qifu helper unavailable',k)end
 local method=k;if k=='getMark'and AIValue.isPlayer(o)then method='getStrategyMark'end
 local r=table.pack(o[method](o,...));if AIUnsupported.is(r[1])then error(r[1],0)end
 if k=='sort'or k=='sortByKeepValue'or k=='sortByUseValue'then local t=(...);known(r[1],k);for i,v in ipairs(r[1])do t[i]=v end;return t end
 if k=='hasSkill'or k=='hasSkills'then local p=AIValue.isPlayer(o)and o or select(2,...)or o.player;local row=type(p)=='table'and rawget(p,'_view');if r[1]==false and row and row.skills_complete~=true then ai_unsupported('ol_qifu foreign skill absence unknown',(...))end end
 if not nullable[k]then known(r[1],k)end
 return table.unpack(r,1,r.n)
end
local function facts(self)return known(self.world.strategy_facts and self.world.strategy_facts.ol_qifu,'ol_qifu')end
local function property(self,key)return known(facts(self).properties and facts(self).properties[key],key)end
local function tag_ids(self,key)return known(facts(self).owner_tag_ids and facts(self).owner_tag_ids[key],key)end
local function public_flag(self,p,key)
 if key:sub(1,12)=='weapon_done_'then return q(self,'hasStrategyPlayerFlag',p,key)end
 if key=='olanxu_target'then return known(facts(self).olanxu_target and facts(self).olanxu_target[q(p,'objectName')],key)end
 return q(p,'hasFlag',key)
end
local function callback(self,registry,key,...)
 local hooks=q(self,'getHooks',registry);local f=hooks[key]
 if f==nil then ai_unsupported('required shared callback unavailable',registry..'.'..key)end
 local r=table.pack(f(...));if AIUnsupported.is(r[1])then error(r[1],0)end;return table.unpack(r,1,r.n)
end
local function need_callback(self,key)
 if not q(self,'hasSourceCardNeed',key)then return nil end
 local f=q(self,'getHooks','ai_cardneed')[key]
 if type(f)~='function'then ai_unsupported('OlRende cardneed policy not ported',key)end
 return function(...)local v=f(...);if AIUnsupported.is(v)then error(v,0)end;return v end
end
local function evaluation(self,name)return q(self,'getEvaluationCard',name or 'slash')end
local function declared(self,skill,name,costs)
 if skill=='xufa'then return q(self,'evaluateXufaSourceCard',name,costs)end
 return q(self,'evaluateSkillCard',skill,name,costs)
end
local function skill_seed(self,skill,name,costs)
 if skill=="xufa"and name=="XufaCard"then return q(self,"evaluateXufaFirst",costs)end
 if costs then return q(self,'evaluateTurnSkillCard',skill,name,costs,self.request)end
 return q(self,'legacySkillSeed',skill,name,self.request)
end
local function answer(self,card,tos)
 local names={};for _,p in ipairs(tos or{})do names[#names+1]=type(p)=='string'and p or q(p,'objectName')end
 if AIValue.isCard(card) and q(card,'isEvaluationOnly')then
  local skill=q(card,'getSkillName',false)
  if skill~='Omozhi'and skill~='mozhi'and skill~='xufa'then ai_unsupported('unexpected selected readonly provider',skill)end
  local authority=q(self,'bindSkillCard',skill,q(card,'getSubcards'),self.request,q(card,'objectName'))
  if q(authority,'objectName')~=q(card,'objectName')or q(authority,'getSuit')~=q(card,'getSuit')or q(authority,'getNumber')~=q(card,'getNumber')or q(authority,'getSkillName',false)~=skill then ai_unsupported('selected declared receipt changes source product',skill)end
  local a,b=q(authority,'getSubcards'),q(card,'getSubcards');if #a~=#b then ai_unsupported('selected declared receipt changes costs',skill)end
  for i,id in ipairs(a)do if id~=b[i]then ai_unsupported('selected declared receipt reorders costs',skill)end end
  card=authority
 end
 if AIValue.isConversion(card)then return{kind='use_card',card_spec=q(card,'toCardSpec'),targets=names}end
 if q(card,'isVirtualCard')then ai_unsupported('selected virtual product has no authority','ol_qifu.response')end
 return{kind='use_card',card_ids={q(card,'getEffectiveId')},targets=names}
end
local function paid(self,skill,cls,ids,tos)
 local c=q(self,'bindSkillCard',skill,ids,self.request,nil,cls)
 return answer(self,c,tos)
end
local function source_choice_continuity(self,op,key,row)
 if type(ai_response_choice_continuity)~='function'then ai_unsupported('native source choice continuity unavailable',key)end
 local result=ai_response_choice_continuity({op=op,key=key,row=row})
 if AIUnsupported.is(result)then error(result,0)end
 if type(result)~='table'or result.known~=true then
  ai_unsupported('source global choice continuation is unobserved',key)
 end
 if op=='record'then if result.recorded~=true then ai_unsupported('invalid source choice record',key)end;return end
 if type(result.present)~='boolean'or(result.present and type(result.value)~='string')then ai_unsupported('invalid source choice value',key)end
 return result.present and result.value or nil
end
local function save_xufa(self,d,name)
 q(self,'rememberActualXufaUse',d) -- source assignment precedes global choice write
 source_choice_continuity(self,'record','xufa',{known=true,present=true,value=name})
end
local function load_xufa(self)
 -- nil/false is a legal host result but the donor then indexes it: retain that ordinary error.
 return self:readActualXufaUse()
end
local function fengpo_from(self)
 local row=facts(self).fengpo_from
 if type(row)~='table'or row.known~=true then ai_unsupported('source global from is not classified','fengpo.from')end
 if row.present==false then return nil end
 return known(self.room:findPlayerByObjectName(row.player),'fengpo.from')
end


sgs.ai_fill_skill.aocai = function(self)
	if not q(self,"aocaiSourceDrawIdentityMatches") then return skill_seed(self,"aocai","AocaiCard") end
end

sgs.ai_skill_use_func["AocaiCard"] = function(card,use,self)
	use.card = card
	q(self,"recordAocaiSourceDrawIdentity")
end

sgs.ai_guhuo_card.aocai = function(self,toname,class_name)
    return {skill="aocai",legacy_class="AocaiCard",subcards={},user_string=toname}
end

sgs.ai_skill_use["@@aocai"] = function(self,prompt)
    local c = q(self.player,"getMark","aocaiId")
	c = q(self,"getKnownCardById",c)
    local dummy = q(self,"aiUseCard",c)
   	if dummy.card then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,q(p,"objectName"))
       	end
       	return answer(self,c,tos)
    end
end

sgs.ai_skill_invoke.olpojun = function(self,data)
	local target = q(data,"toPlayer")
	if target then
		return not q(self,"isFriend",target)
	end
end

sgs.ai_use_revises.olpojun = function(self,card,use)
	if q(card,"isKindOf","Slash") then
		q(self,"setStrategyCardFlag",card,"Qinggang",true)
	end
end

sgs.ai_skill_invoke.lixia = function(self,data)
    return true
end

sgs.ai_skill_invoke.biluan = function(self,data)
    return q(self.player,"getHandcardNum")>3 and #q(self,"getTurnUse")>2
end

sgs.ai_skill_choice.mobilemiji_draw = function(self,choices)
    return ""..q(self.player,"getLostHp")
end

sgs.ai_skill_invoke.mobilemiji = function(self,data)
    if #self.friends==0 then return false end
    for _,friend in ipairs(self.friends)do
        if not q(friend,"hasSkill","manjuan") and not q(self,"isLihunTarget",friend) then return true end
    end
    return false
end

sgs.ai_skill_askforyiji.mobilemiji = function(self,card_ids)
    local available_friends = {}
    for _,friend in ipairs(self.friends)do
        if not q(friend,"hasSkill","manjuan") and not q(self,"isLihunTarget",friend) then table.insert(available_friends,friend) end
    end
    local toGive,allcards = {},{}
    local keep
    for _,id in ipairs(card_ids)do
        local card = q(self,"getKnownCardById",id)
        if not keep and (isCard("Jink",card,self.player) or isCard("Analeptic",card,self.player)) then
            keep = true
        else
            table.insert(toGive,card)
        end
        table.insert(allcards,card)
    end
    local cards = #toGive>0 and toGive or allcards
    q(self,"sortByKeepValue",cards,true)
    local id = q(cards[1],"getId")
    local card,friend = q(self,"getCardNeedPlayer",cards,true)
    if card and friend and table.contains(available_friends,friend) then 
        if q(friend,"objectName")==q(self.player,"objectName") then 
            return nil,-1
        else
            return friend,q(card,"getId") 
        end
    end
    if #available_friends>0 then
        q(self,"sort",available_friends,"handcard")
        for _,afriend in ipairs(available_friends)do
            if not q(self,"needKongcheng",afriend,true) then
                if afriend:objectName()==q(self.player,"objectName") then 
                    return nil,-1
                else
                    return afriend,id
                end
            end
        end
        q(self,"sort",available_friends,"defense")
        if available_friends[1]:objectName()==q(self.player,"objectName") then 
            return nil,-1
        else
            return available_friends[1],id
        end
    end
    return nil,-1
end

sgs.ai_skill_use["@@bushi"] = function(self,prompt,method)
    local zhanglu = q(self.room,"findPlayerBySkillName","bushi")
    if not zhanglu then return "." end
    local ids = q(zhanglu,"getPile","rice")
    if q(self,"isEnemy",zhanglu) and ids:length()==1 and q(zhanglu,"isWounded") then return "." end
    if q(self,"isFriend",zhanglu) then
		local damage = known(q(self,"getDecisionContext").damage,"CurrentDamageStruct")
		if damage.damage<ids:length() and q(self,"getOverflow")>1 or not q(zhanglu,"isWounded") then
			return "."
		end
	end
    local cards = {}
    for _,id in sgs.list(ids)do
        table.insert(cards,q(self,"getKnownCardById",id))
    end
    q(self,"sortByUseValue",cards,true)
    return paid(self,"bushi","BushiCard",{q(cards[1],"getEffectiveId")})    
end    

sgs.ai_skill_use["@@midao"] = function(self,prompt,method)
    local judge = q(self,"getJudge")
    local ids = q(self.player,"getPile","rice")
    if q(self.room,"getMode"):find("_mini_46") and not q(judge,"isGood") then return paid(self,"midao","MidaoCard",{ids:first()}) end
    local cards = {}
    for _,id in sgs.list(ids)do
        table.insert(cards,q(self,"getKnownCardById",id))
    end
    if q(self,"needRetrial",judge) then
        local id = q(self,"getRetrialCardId",cards,judge)
        if id~=-1 then return paid(self,"midao","MidaoCard",{id}) end
    end
	if q(self,"isWeak") and #cards<2
	and q(self.player,"getLostHp")>0
	then
        local id = q(self,"getRetrialCardId",cards,judge,nil,true)
        if id~=-1 then return paid(self,"midao","MidaoCard",{id}) end
	end
    return "."    
end

sgs.ai_skill_defense.yishe = 2

sgs.ai_skill_invoke["olmeibu2"] = function(self,data)
   	local target = q(self.room,"getCurrent")
	return q(self,"isEnemy",target)
	and (q(self,"getCardsNum","Jink")>0 or not q(self,"isWeak"))
end


sgs.ai_fill_skill.olanxu = function(self,inclusive,request)
 if q(self.room,"alivePlayerCount")>2 then return skill_seed(self,"olanxu","OlAnxuCard") end
end
sgs.ai_skill_use_func["OlAnxuCard"] = function(card,use,self)
    local tos = q(self.room,"getOtherPlayers",self.player)
	for i,to1 in sgs.list(tos)do
		for i,to2 in sgs.list(tos)do
			if q(to1,"getHandcardNum")<q(to2,"getHandcardNum")
			and q(self,"isFriend",to1) and q(self,"isEnemy",to2)
			then
				use.card = card
				use.to:append(to1)
				use.to:append(to2)
				return
			end
		end
	end
	for i,to1 in sgs.list(tos)do
		for i,to2 in sgs.list(tos)do
			if q(to1,"getHandcardNum")<q(to2,"getHandcardNum")
			and q(self,"isFriend",to1) and not q(self,"isFriend",to2)
			then
				use.card = card
				use.to:append(to1)
				use.to:append(to2)
				return
			end
		end
	end
	for i,to1 in sgs.list(tos)do
		for i,to2 in sgs.list(tos)do
			if q(to1,"getHandcardNum")<q(to2,"getHandcardNum")
			and not q(self,"isEnemy",to1) and q(self,"isEnemy",to2)
			then
				use.card = card
				use.to:append(to1)
				use.to:append(to2)
				return
			end
		end
	end
	for i,to1 in sgs.list(tos)do
		for i,to2 in sgs.list(tos)do
			if q(to1,"getHandcardNum")<q(to2,"getHandcardNum")
			and not q(self,"isEnemy",to1) and not q(self,"isFriend",to2)
			then
				use.card = card
				use.to:append(to1)
				use.to:append(to2)
				return
			end
		end
	end
	for i,to1 in sgs.list(tos)do
		for i,to2 in sgs.list(tos)do
			if q(to1,"getHandcardNum")<q(to2,"getHandcardNum")
			and q(self,"isFriend",to1) and q(self,"isFriend",to2)
			then
				use.card = card
				use.to:append(to1)
				use.to:append(to2)
				return
			end
		end
	end
	for i,to1 in sgs.list(tos)do
		for i,to2 in sgs.list(tos)do
			if q(to1,"getHandcardNum")<q(to2,"getHandcardNum")
			and not q(self,"isEnemy",to1) and not q(self,"isEnemy",to2)
			then
				use.card = card
				use.to:append(to1)
				use.to:append(to2)
				return
			end
		end
	end
end

sgs.ai_skill_discard["olanxu"] = function(self,discard_num,min_num,optional,include_equip,pattern)
    for _,p in sgs.list(q(self.room,"getOtherPlayers",self.player))do
        if public_flag(self,p,"olanxu_target") and q(self,"isFriend",p)
		and not q(self,"hasManjuanEffect",p)
		then
			local handcards = q(self.player,"getHandcards")
			handcards = q(self,"sortByUseValue",handcards)
			return {handcards[1]:getEffectiveId()}
		end
    end
    return q(self,"askForDiscard","dummy",discard_num,min_num,optional,include_equip,pattern)
end

sgs.ai_skill_choice["olanxu"] = function(self,choices,data)
    local items = choices:split("+")
    if #items==1 then
        return items[1]
    end
    return "recover"
end



sgs.ai_skill_playerchosen["olchenqing"] = function(self,targets)
    local victim = q(self.room,"getCurrentDyingPlayer")
    local help = false
    local careLord = false
    if victim then
        if q(self,"isFriend",victim) then
            help = true
        elseif q(self.player,"getRole")=="renegade" and q(victim,"isLord") and q(self.room,"alivePlayerCount")>2 then
            help = true
            careLord = true
        end
    end
    local friends,enemies = {},{}
    for _,p in sgs.list(targets)do
        if q(self,"isFriend",p) then
            table.insert(friends,p)
        else
            table.insert(enemies,p)
        end
    end
    local compare_func = function(a,b)
        local nA = q(a,"getCardCount",true)
        local nB = q(b,"getCardCount",true)
        if nA==nB then
            return q(a,"getHandcardNum")>q(b,"getHandcardNum")
        else
            return nA>nB
        end
    end
    if help and #friends>0 then
        table.sort(friends,compare_func)
        for _,friend in ipairs(friends)do
            if not q(self,"hasManjuanEffect",friend) then
                return friend
            end
        end
    end
    if careLord and #enemies>0 then
        table.sort(enemies,compare_func)
        for _,enemy in ipairs(enemies)do
            if q(self,"getRoleEstimate",enemy)=="loyalist" then
                return enemy
            end
        end
    end
    if #enemies>0 then
        q(self,"sort",enemies,"threat")
        for _,enemy in ipairs(enemies)do
            if q(self,"hasManjuanEffect",enemy) then
                return enemy
            end
        end
    end
    if #friends>0 then
        q(self,"sort",friends,"defense")
        for _,friend in ipairs(friends)do
            if not q(self,"hasManjuanEffect",friend) then
                return friend
            end
        end
    end
end

sgs.ai_skill_discard["olchenqing"] = function(self,discard_num,min_num,optional,include_equip)
    local victim = q(self.room,"getCurrentDyingPlayer")
    local help = false
    if victim
	then
        if q(self,"isFriend",victim)
		then help = true
        elseif q(self.player,"getRole")=="renegade"
		and q(victim,"isLord") and q(self.room,"alivePlayerCount")>2
		then help = true end
    end
    if help
	then
        local peach_num = 0
        local suits,ids = {},{}
		local cards = q(self.player,"getCards","he")
		cards = q(self,"sortByKeepValue",cards,nil,true)
        for _,c in ipairs(cards)do
            if isCard("Peach",c,self.player)
			then peach_num = peach_num+1
            else
                if table.contains(suits,q(c,"getSuit"))
				then continue end
				table.insert(suits,q(c,"getSuit"))
				table.insert(ids,q(c,"getEffectiveId"))
            end
        end
        if peach_num+q(victim,"getHp")<1
		or #ids>3 then return ids end
    end
    return q(self,"askForDiscard","dummy",discard_num,min_num,optional,include_equip)
end

sgs.ai_skill_playerchosen["chenqing"] = function(self,targets)
	return sgs.ai_skill_playerchosen["olchenqing"](self,targets)
end

sgs.ai_skill_discard["Chenqing"] = function(self,discard_num,min_num,optional,include_equip)
	return sgs.ai_skill_discard["olchenqing"](self,discard_num,min_num,optional,include_equip)
end


sgs.ai_skill_use["@@Omozhi"] = function(self,prompt,method)
    local list = property(self,"allowed_guhuo_dialog_buttons"):split("+")
    local cards = q(self.player,"getCards","h")
    cards = q(self,"sortByKeepValue",cards,nil,true) -- 按保留值排序
	if #list<1 or #cards<1 then return end
	list = declared(self,"Omozhi",list[1],{q(cards[1],"getEffectiveId")})
    local dummy = q(self,"aiUseCard",list)
   	if dummy.card and dummy.to
   	then
		if q(list,"canRecast") and dummy.to:length()<1
		and method~=sgs.Card_MethodRecast
		then return end
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,q(p,"objectName"))
       	end
       	return answer(self,list,tos)
    end
end

sgs.ai_skill_use["@@mozhi"] = function(self,prompt,method)
    local c = property(self,"mozhi")
    local cards = q(self.player,"getCards","h")
    cards = q(self,"sortByKeepValue",cards,nil,true) -- 按保留值排序
	local name=c;c=evaluation(self,name)
	if #cards<1 or not c then return end
	c=declared(self,"mozhi",name,{q(cards[1],"getEffectiveId")})
	local dummy = q(self,"aiUseCard",c)
   	if dummy.card and dummy.to
   	then
		if q(c,"canRecast") and dummy.to:length()<1
		and method~=sgs.Card_MethodRecast
		then return end
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,q(p,"objectName"))
       	end
       	return answer(self,c,tos)
    end
end


sgs.ai_skill_discard["olyongsi"] = function(self,discard_num,min_num,optional,include_equip)
    if q(self,"needToLoseHp") or getBestHp(self.player)<=q(self.player,"getHp")
	then return "." end
    return q(self,"askForDiscard","dummy",discard_num,min_num,optional,include_equip)
end


sgs.ai_skill_choice["oljixi"] = function(self,choices,data)
    local items = choices:split("+")
    if #items==1 then
        return items[1]
    end
    return "wangzun"
end

function OlRendeArrange(self,cards,friends,enemies,unknowns,arrange,recover_only)
	recover_only = recover_only or true
    if #enemies>0 then
        q(self,"sort",enemies,"hp")
        for _,card in ipairs(cards)do
            if q(card,"isKindOf","Shit") then
                return enemies[1],card,"enemy"
            end
        end
    end
    if #friends>0 then
        q(self,"sort",friends,"defense")
        for _,friend in ipairs(friends)do
            local arranged = arrange[q(friend,"objectName")] or {}
            if q(self,"isWeak",friend) and q(friend,"getHandcardNum")+#arranged<3 then
                for _,card in ipairs(cards)do
                    if q(card,"isKindOf","Shit") then
                    elseif isCard("Peach",card,friend) or isCard("Analeptic",card,friend)
					then return friend,card,"friend"
                    elseif isCard("Jink",card,friend) and q(self,"getEnemyNumBySeat",self.player,friend)>0
					then return friend,card,"friend"
                    end
                end
            end
        end
        for _,friend in ipairs(friends)do
            local arranged = arrange[q(friend,"objectName")] or {}
            if q(friend,"getHp")<=2 and q(friend,"faceUp") then
                for _,card in ipairs(cards)do
                    if q(card,"isKindOf","Armor") then
                        if not q(friend,"getArmor") and not q(self,"hasSkills","yizhong|bazhen|bossmanjia",friend) then
                            local given = false
                            for _,c in ipairs(arranged)do
                                if q(c,"isKindOf","Armor") then
                                    given = true
                                    break
                                end
                            end
                            if not given then
                                return friend,card,"friend"
                            end
                        end
                    elseif q(card,"isKindOf","DefensiveHorse") then
                        if not q(friend,"getDefensiveHorse") then
                            local given = false
                            for _,c in ipairs(arranged)do
                                if q(c,"isKindOf","DefensiveHorse") then
                                    given = true
                                    break
                                end
                            end
                            if not given then
                                return friend,card,"friend"
                            end
                        end
                    end
                end
            end
        end
        for _,friend in ipairs(friends)do
            local arranged = arrange[q(friend,"objectName")] or {}
            if q(friend,"getHandcardNum")+#arranged<4 then
                if q(friend,"hasSkill","jijiu") then
                    for _,card in ipairs(cards)do
                        if q(card,"isRed") then
                            return friend,card,"friend"
                        end
                    end
                end
                if q(friend,"hasSkill","jieyin") then
                    return friend,cards[1],"friend"
                elseif q(friend,"hasSkill","nosrenxin") and q(friend,"isKongcheng") then
                    return friend,cards[1],"friend"
                end
            end
        end
        for _,friend in ipairs(friends)do
            if q(self,"hasSkills","wusheng|longdan|wushen|keji|chixin",friend) then
                local arranged = arrange[q(friend,"objectName")] or {}
                if q(friend,"getHandcardNum")+#arranged>=2 and not q(self,"hasCrossbowEffect",friend) then
                    for _,card in ipairs(cards)do
                        if q(card,"isKindOf","Crossbow") then
                            local given = false
                            for _,c in ipairs(arranged)do
                                if q(c,"isKindOf","Crossbow") then
                                    given = true
                                    break
                                end
                            end
                            if not given then
                                return friend,card,"friend"
                            end
                        end
                    end
                end
            end
        end
        for _,friend in ipairs(friends)do
            local arranged = arrange[q(friend,"objectName")] or {}
            local has_crossbow = q(self,"hasCrossbowEffect",friend)
            if not has_crossbow then
                for _,c in ipairs(arranged)do
                    if q(c,"isKindOf","Crossbow") then
                        has_crossbow = true
                        break
                    end
                end
            end
            if has_crossbow or getKnownCard(friend,self.player,"Crossbow")>0 then
                for _,p in ipairs(self.enemies)do
                    if q(self,"isGoodTarget",p,self.enemies,evaluation(self)) and q(friend,"distanceTo",p)<=1 then
                        for _,card in ipairs(cards)do
                            if isCard("Slash",card,friend) then
                                return friend,card,"friend"
                            end
                        end
                    end
                end
            end
        end
        local compareByAction = function(a,b)
            return q(a,"objectName")~=q(b,"objectName") and q(self.room,"getFront",a,b):objectName()==q(a,"objectName")
        end
        table.sort(friends,compareByAction)
        for _,friend in ipairs(friends)do
            local flag = string.format("weapon_done_%s_%s",q(self.player,"objectName"),q(friend,"objectName"))
            if q(friend,"faceUp") and not public_flag(self,friend,flag) then
                local can_slash = false
                local others = q(self.room,"getOtherPlayers",friend)
                for _,p in sgs.list(others)do
                    if q(self,"isEnemy",p) and q(self,"isGoodTarget",p,self.enemies) then
                        if q(friend,"distanceTo",p)<=q(friend,"getAttackRange") then
                            can_slash = true
                            break
                        end
                    end
                end
                if not can_slash then
                    for _,p in sgs.list(others)do
                        if q(self,"isEnemy",p) and q(self,"isGoodTarget",p,self.enemies) then
                            local distance = q(friend,"distanceTo",p)
                            local range = q(friend,"getAttackRange")
                            if distance>range then
                                for _,card in ipairs(cards)do
                                    if q(card,"isKindOf","Weapon") then
                                        if not q(friend,"getWeapon") then
                                            if distance<=range+(sgs.weapon_range[q(card,"getClassName")] or 0) then
                                                q(self,"setStrategyPlayerFlag",friend,flag,true)
                                                return friend,card,"friend"
                                            end
                                        end
                                    elseif q(card,"isKindOf","OffensiveHorse") then
                                        if not q(friend,"getOffensiveHorse") then
                                            if distance<=range+1 then
                                                q(self,"setStrategyPlayerFlag",friend,flag,true)
                                                return friend,card,"friend"
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        local compareByNumber = function(a,b)
            return q(a,"getNumber")>q(b,"getNumber")
        end
        table.sort(cards,compareByNumber)
        for _,friend in ipairs(friends)do
            if q(friend,"faceUp") then
                local skills = q(friend,"getVisibleSkillList",true)
                for _,skill in sgs.list(skills)do
                    local callback = need_callback(self,q(skill,"objectName"))
                    if type(callback)=="function" then
                        for _,card in ipairs(cards)do
                            if callback(friend,card,self) then
                                return friend,card,"friend"
                            end
                        end
                    end
                end
            end
        end
        for _,card in ipairs(cards)do
            if q(card,"isKindOf","Shit") then
                for _,friend in ipairs(friends)do
                    if q(self,"isWeak",friend) then
                    elseif q(friend,"hasSkill","jueqing") or q(card,"getSuit")==sgs.Card_Spade then
                        if q(self,"hasZhaxiangEffect",friend) then
                            return friend,card,"friend"
                        end
                    elseif q(self,"hasSkills","guixin|jieming|yiji|nosyiji|chengxiang|noschengxiang|jianxiong",friend) then
                        return friend,card,"friend"
                    end
                end
            end
        end
        if q(self.player,"getRole")=="lord" and q(self.player,"hasLordSkill","jijiang") then
            for _,friend in ipairs(friends)do
                local arranged = arrange[q(friend,"objectName")] or {}
                if q(friend,"getKingdom")=="shu" and q(friend,"getHandcardNum")+#arranged<3 then
                    for _,card in ipairs(cards)do
                        if isCard("Slash",card,friend) then
                            return friend,card,"friend"
                        end
                    end
                end
            end
        end
    end
    if #enemies>0 then
        q(self,"sort",enemies,"defense")
        for _,enemy in ipairs(enemies)do
            if q(enemy,"hasSkill","kongcheng") and q(enemy,"isKongcheng") then
                if not q(enemy,"hasSkill","manjuan") then
                    for _,card in ipairs(cards)do
                        if isCard("Jink",card,enemy) then
                        elseif q(card,"isKindOf","Disaster") or q(card,"isKindOf","Shit") then
                            return enemy,card,"enemy"
                        elseif q(card,"isKindOf","Collateral") or q(card,"isKindOf","AmazingGrace") then
                            return enemy,card,"enemy"
                        elseif q(card,"isKindOf","OffensiveHorse") or q(card,"isKindOf","Weapon") then
                            return enemy,card,"enemy"
                        end
                    end
                end
            end
        end
    end
    local overflow = q(self,"getOverflow")
    if #friends>0 then
        for _,friend in ipairs(friends)do
            local arranged = arrange[q(friend,"objectName")] or {}
            if q(self,"willSkipPlayPhase",friend) then
            elseif q(self,"hasSkills",sgs.priority_skill,friend) and q(friend,"getHandcardNum")+#arranged<=3 then
                if overflow-#arranged>0 or q(self.player,"getHandcardNum")-#arranged>3 then
                    return friend,cards[1],"friend"
                end
            end
        end
    end
    if overflow>0 and #friends>0 then
        for _,card in ipairs(cards)do
            if not q(self,"aiUseCard",card).card then
                q(self,"sort",friends,"defense")
                return friends[1],card,"friend"
            end
        end
    end
	
	local slash = evaluation(self)
	local will_use_slash = false
	if q(self,"aiUseCard",slash).card
	then will_use_slash = true end
	if not will_use_slash then
		local fire_slash = evaluation(self,"fire_slash")
		if q(self,"aiUseCard",fire_slash).card
		then will_use_slash = true end
		if not will_use_slash then
			local thunder_slash = evaluation(self,"thunder_slash")
			if q(self,"aiUseCard",thunder_slash).card then
				will_use_slash = true
			end
		end
	end
	
    if arrange["count"]<2 and q(self.player,"getHandcardNum")>=2
	and ((q(self.player,"getLostHp")>0 and q(self,"isWeak")) or (not recover_only and will_use_slash))
	then
        if #friends>0 then
            return friends[1],cards[1],"friend"
        elseif #unknowns>0 then
            q(self,"sortByKeepValue",cards)
            for _,p in ipairs(unknowns)do
                if q(p,"hasSkill","manjuan") then
                    return p,cards[1],"unknown"
                end
            end
            q(self,"sort",unknowns,"threat")
            return unknowns[#unknowns],cards[1],"unknown"
        elseif #enemies>0 then
            for _,enemy in ipairs(enemies)do
                if q(enemy,"hasSkill","manjuan") then
                    return enemy,cards[1],"enemy"
                end
            end
        end
    end
end
local function resetPlayers(players,except)
    local result = {}
    for _,p in ipairs(players)do
        if not q(p,"objectName")==except:objectName() then
            table.insert(result,p)
        end
    end
    return result
end



sgs.ai_skill_choice.fengpo = function(self,choices,data)
	local use = q(data,"toCardUse")
	local to,slash = use.to:first(),use.card
 if q(to,"isDead") or not q(self,"isEnemy",to)then return "drawCards" end
 local from=fengpo_from(self)
 if not q(self,"slashIsEffective",slash,to,from)then return "drawCards" end
	local nature = sgs.DamageStruct_Normal
	if q(slash,"isKindOf","FireSlash") then nature = sgs.DamageStruct_Fire
	elseif q(slash,"isKindOf","ThunderSlash") then nature = sgs.DamageStruct_Thunder end
	if not q(self,"damageIsEffective",to,nature,from) then return "drawCards" end
	if getCardsNum("Jink",to,self.player)==0 and not q(self,"cantDamageMore",self.player,to) then return "addDamage" end
	return "drawCards"
end

sgs.ai_skill_discard["olqingjian"] = function(self,discard_num,min_num,optional,include_equip,pattern)
    local qj = tag_ids(self,"olqingjian")
	qj = sgs.QList2Table(qj)
	local n = #qj
	local ids = {}
	for i=1,n do
		local to,id = callback(self,"ai_skill_askforyiji","nosyiji",self,qj)
		if to and id then
			table.insert(ids,id)
			table.removeOne(qj,id)
		end
	end
	return ids
end

sgs.ai_skill_use["@@olqingjian!"] = function(self,prompt,method)
    local qj = q(self.player,"getPile","olqingjian")
	local to,id = callback(self,"ai_skill_askforyiji","nosyiji",self,sgs.QList2Table(qj))
	if to and id then
		return paid(self,"olqingjian","OlQingjianCard",{id},{to})
	end
    local cards = {}
    for _,id in sgs.list(qj)do
        table.insert(cards,q(self,"getKnownCardById",id))
    end
    q(self,"sortByUseValue",cards,true)
	for _,p in sgs.list(self.friends_noself)do
		if q(self,"canDraw",p) and not q(self,"hasManjuanEffect",p) then
			return paid(self,"olqingjian","OlQingjianCard",{q(cards[1],"getEffectiveId")},{p})
		end
	end
	for _,p in sgs.list(q(self.room,"getOtherPlayers",self.player))do
		if not q(self,"isEnemy",p) and not q(self,"hasManjuanEffect",p) then
			return paid(self,"olqingjian","OlQingjianCard",{q(cards[1],"getEffectiveId")},{p})
		end
	end
	for _,p in sgs.list(q(self.room,"getOtherPlayers",self.player))do
		return paid(self,"olqingjian","OlQingjianCard",{q(cards[1],"getEffectiveId")},{p})
	end
end    



sgs.ai_skill_invoke.liangzhu = function(self,data)
	return true
end

sgs.ai_skill_choice.liangzhu = function(self,choices,data)
	local current = q(self.room,"getCurrent")
	if q(self,"isFriend",current) and (q(self,"isWeak",current) or q(current,"hasSkills",sgs.cardneed_skill))then
		return "letdraw"
	end
	return "draw"
end

sgs.ai_skill_invoke.cihuai = function(self,data)
	local has_slash = false
	local cards = q(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)
	for _,card in ipairs(cards)do
		if q(card,"isKindOf","Slash") then has_slash = true end
	end
	if has_slash then return false end

	q(self,"sort",self.enemies,"defenseSlash")
	for _,enemy in ipairs(self.enemies)do
		local slash = evaluation(self)
		local eff = q(self,"slashIsEffective",slash,enemy) and q(self,"isGoodTarget",enemy,self.enemies,slash)
		if eff and q(self.player,"canSlash",enemy) and not q(self,"slashProhibit",nil,enemy) then
			return true
		end
	end

return false
end

sgs.ai_fill_skill.cihuai = function(self,inclusive,request)
 return q(self,"evaluateTurnConversion","cihuai","Slash",{name="slash",skill="_cihuai",suit=sgs.Card_NoSuit,number=0,subcards={}},request or self.request)
end

sgs.ai_skill_invoke.kunfen = function(self,data)
	if not q(self,"isWeak") and (q(self,"getCardsNum","Peach")+q(self.player,"getHp")>1 or q(self,"hasZhaxiangEffect",self.player)) then
		return true
	end
end

sgs.ai_fill_skill.chixin = function(self,inclusive,request)
	local cards = q(self.player,"getCards","he")
	cards=sgs.QList2Table(cards)

	local diamond_card

	q(self,"sortByUseValue",cards,true)

	local useAll = false
	q(self,"sort",self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if q(enemy,"getHp")==1 and not q(enemy,"hasArmorEffect","EightDiagram") and q(self.player,"distanceTo",enemy)<=q(self.player,"getAttackRange") and q(self,"isWeak",enemy)
			and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)==0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if q(self,"getCardsNum","Slash")<2 or q(self.player,"hasSkill","paoxiao") then
		disCrossbow = true
	end


	for _,card in ipairs(cards)  do
		if q(card,"getSuit")==sgs.Card_Diamond
		and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (not isCard("Crossbow",card,self.player) and not disCrossbow)
		and (q(self,"getUseValue",card)<sgs.ai_use_value.Slash or inclusive or q(evaluation(self,"slash"),"getTargetModResidue",self.player)>0) then
			diamond_card = card
			break
		end
	end
	if not diamond_card then return nil end
	local suit = q(diamond_card,"getSuitString")
	local number = q(diamond_card,"getNumberString")
	local card_id = q(diamond_card,"getEffectiveId")
	return q(self,"evaluateTurnConversion","chixin","Slash",{name="slash",skill="chixin",suit=q(diamond_card,"getSuit"),number=q(diamond_card,"getNumber"),subcards={card_id}},request or self.request)

end

sgs.ai_view_as.chixin = function(card,player,card_place,class_name)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if card_place~=sgs.Player_PlaceSpecial and q(card,"getSuit")==sgs.Card_Diamond and not q(card,"isKindOf","Peach") and not q(card,"hasFlag","using") then
		if class_name=="Slash" then
			return {name="slash",skill="chixin",suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={card_id}}
		elseif class_name=="Jink" then
			return {name="jink",skill="chixin",suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={card_id}}
		end
	end
end

sgs.ai_cardneed.chixin = function(to,card)
	return q(card,"getSuit")==sgs.Card_Diamond
end

sgs.ai_skill_playerchosen.suiren = function(self,targets)
	if q(self.player,"getMark","@suiren")==0 then return "." end
	if q(self,"isWeak") and (q(self,"getOverflow")<-2 or not q(self,"willSkipPlayPhase")) then return self.player end
	q(self,"sort",self.friends_noself,"defense")
	for _,friend in ipairs(self.friends)do
		if q(self,"isWeak",friend) and not q(self,"needKongcheng",friend) then
			return friend
		end
	end
	q(self,"sort",self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if (q(self,"isWeak",enemy) and q(enemy,"getHp")==1)
			and q(self.player,"getHandcardNum")<2 and not q(self,"willSkipPlayPhase") and q(self.player,"inMyAttackRange",enemy) then
			return self.player
		end
	end
end

sgs.ai_playerchosen_intention.suiren = -60

sgs.ai_skill_use["@@jiqiao"] = function(self,prompt,method,pattern,request)
	local usable_cards = sgs.QList2Table(q(self.player,"getCards","he"))
	q(self,"sortByUseValue",usable_cards,true)
	local use_cards = {}
	for _,c in ipairs(usable_cards)do
		if q(c,"isKindOf","Armor") or q(c,"isKindOf","DefensiveHorse") or q(c,"isKindOf","OffensiveHorse") or (q(c,"isKindOf","WoodenOx") and q(self.player,"getPile","wooden_ox"):length()==0) then
			table.insert(use_cards,q(c,"getEffectiveId"))
		end
	end
	if #use_cards==0 then return end
	if #use_cards>0 then
		return answer(self,q(self,"bindSkillCard","jiqiao",use_cards,request,nil,"JiqiaoCard"))
	end
end


sgs.ai_fill_skill.xufa = function(self)
	local ids = q(self.player,"getPile","xufa")
	local toids = {}
	if ids:length()>0 and q(self.player,"getMark","xufa2-PlayClear")<1 then
		local xf = {}
		for _,id in sgs.list(ids)do
			table.insert(xf,q(self,"getKnownCardById",id))
		end
		xf = q(self,"sortByUseValue",xf)
		local cards = q(self.player,"getCards","he")
		cards = q(self,"sortByUseValue",cards)
		for _,c in sgs.list(xf)do
			if q(c,"isNDTrick") and #cards>0 then
				local costs = {}
				table.insert(toids,q(c,"getId"))
				for _,c in sgs.list(sgs.reverse(xf))do
					if not table.contains(toids,q(c,"getId")) and #toids<#xf/2 then
						table.insert(toids,q(c,"getId"))
					end
				end
				costs[#costs+1]=q(cards[#cards],"getEffectiveId")
				local dc=declared(self,"xufa",q(c,"objectName"),costs)
				if q(dc,"isAvailable",self.player) then
					local d = q(self,"aiUseCard",dc)
					if d.card then
						if q(dc,"canRecast") and d.to:length()<1
						then continue end
						save_xufa(self,d,q(c,"objectName"))
						return skill_seed(self,"xufa","XufaCard",toids)
					end
				end
				toids = {}
			end
		end
	end
	local cards = q(self.player,"getCards","he")
	if cards:length()>0 and q(self.player,"getMark","xufa1-PlayClear")<1 then
		cards = q(self,"sortByUseValue",cards)
		for _,c in sgs.list(cards)do
			if q(c,"isNDTrick") then
				local costs = {}
				table.insert(toids,q(c,"getId"))
				for _,c in sgs.list(sgs.reverse(cards))do
					if not table.contains(toids,q(c,"getId")) and #toids<#cards/2 then
						if #costs<1 then
							costs[#costs+1]=q(c,"getEffectiveId")
						else
							table.insert(toids,q(c,"getId"))
						end
					end
				end
				local dc=declared(self,"xufa",q(c,"objectName"),costs)
				if q(dc,"isAvailable",self.player) then
					local d = q(self,"aiUseCard",dc)
					if d.card then
						if q(dc,"canRecast") and d.to:length()<1
						then continue end
						save_xufa(self,d,q(c,"objectName"))
						return skill_seed(self,"xufa","XufaCard",toids)
					end
				end
				toids = {}
			end
		end
	end
end

sgs.ai_skill_use_func["XufaCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.XufaCard = 4.4
sgs.ai_use_priority.XufaCard = 11.8

sgs.ai_skill_choice.xufa=function(self)
 return source_choice_continuity(self,'read','xufa')
end
sgs.ai_skill_use["@@xufa"]=function(self,prompt,method)
 local d=load_xufa(self)
 if d.card then
  if q(d.card,"canRecast") and #d.to<1 and method~=sgs.Card_MethodRecast then return end
  local tos={};for _,p in ipairs(d.to)do tos[#tos+1]=q(p,"objectName")end
  return q(self,"materializeXufaSaved",d.card,tos)
 end
end
