-- Fixed GeniusPackageGod-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local function known(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("GeniusPackageGod policy input is unknown",key) end
    return value
end
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("GeniusPackageGod policy helper unavailable",method) end
    local result=table.pack(object[method](object,...))
    if AIUnsupported.is(result[1]) then error(result[1],0) end
    return table.unpack(result,1,result.n)
end
local function q(object,method,...)
    local value=call(object,method,...)
    if value==false and (method=="hasSkill"or method=="hasSkills"or method=="hasLordSkill")and AIValue.isPlayer(object)then
        local row=rawget(object,"_view")
        if row and row.skills_complete~=true then ai_unsupported("foreign skill absence is unknown",(...))end
    end
    return known(value,method)
end
local function sorted(self,cards,method,...)
    local result=q(self,method,cards,...)
    for i,c in ipairs(result) do cards[i]=c end
    return cards
end
local function sort_players(self,cards,...) return sorted(self,cards,"sort",...) end
local function sort_use(self,cards,...) return sorted(self,cards,"sortByUseValue",...) end
local function sort_keep(self,cards,...) return sorted(self,cards,"sortByKeepValue",...) end
local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return q(self,"legacySkillSeed",skill,class,action_request(self,request)) end
local skill_cards={['#diy_k_luoshang']='diy_k_luoshang',['#diy_k_meihun']='diy_k_meihun',['#diy_k_shouli']='diy_k_shouli',['#f_henjueCard']='f_henjue',['#f_jianyuangiveCard']='f_jianyuan',['#f_jianyuanthrowCard']='f_jianyuan',['#f_jishenCard']='f_jishen',['#f_qianduCard']='f_qiandu',['#f_sandaoEXCard']='f_sandaoEX',['#f_sandaoEXSlashCard']='f_sandaoEX',['#f_shenjiangCard']='f_shenjiang',['#f_shenjiangSBKCard']='f_shenjiang',['#f_shenpanCard']='f_shenpan',['#f_skyssonCard']='f_skysson',['#f_yanyiCard']='f_yanyi',['#f_yifaCard']='f_yifa',['#f_yishiCard']='f_yishi',['#f_yonghunCard']='f_yonghun',['#f_yonghunSlashCard']='f_yonghun',['#lcd_f_huimengCard']='f_huimeng',['#mini_f_qigongCard']='f_qigong',['#pro_f_qigongCard']='f_qigong',['#tc_changbiao_sqrh']='tc_changbiao_sqrh',['#tc_dingzhou']='tc_dingzhou',['#tc_huashen']='tc_huashen',['#tc_huishi']='tc_huishi',['#tc_liutiCard']='tc_liuti',['#tc_shenfen']='tc_shenfen',['#tc_zuoxing']='tc_zuoxing'}
local function disclosed(self,id)return known(self:getKnownCardById(id)or self:getChoiceCard(id),'GeniusPackageGod source card '..tostring(id))end
local function parts(wire)
 local class,raw,user=wire:match('^(#[^:]+):([^:]*):(.*)$');if not class then return end
 local costs={};for id in raw:gmatch('%d+')do costs[#costs+1]=tonumber(id)end
 return class,costs,user~=''and user or nil
end
local function parse(self,request,wire)
 if wire=='@ShenfenCard=.'then return seed(self,'tc_shenfen','ShenfenCard',request)end
 local class,costs,user=parts(wire)
 if class then local skill=known(skill_cards[class],class)
  if #costs==0 and user==nil then return seed(self,skill,class,request)end
  return q(self,'evaluateTurnSkillCard',skill,class,costs,action_request(self,request),user)
 end
 local name,skill,raw=wire:match('^([^:]+):([^%[]+)%[[^%]]+%]=(.*)$')
 if not name then ai_unsupported('unrecognized source card grammar',wire)end
 costs={};local cards={};for id in raw:gmatch('%d+')do costs[#costs+1]=tonumber(id);cards[#cards+1]=disclosed(self,tonumber(id))end
 local suit,number=sgs.Card_NoSuit,0
 if #cards==1 then suit,number=q(cards[1],'getSuit'),q(cards[1],'getNumber')
 elseif #cards>1 then local red,black=true,true;for _,c in ipairs(cards)do red=red and q(c,'isRed');black=black and q(c,'isBlack')end;suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit end
 local activation=(skill=='f_lingqij'or skill=='f_lingqix_poison')and'f_lingqi'or skill
 return q(self,'evaluateTurnConversion',activation,q(q(self,'getEvaluationCard',name),'getClassName'),{name=name,skill=skill,suit=suit,number=number,subcards=costs},action_request(self,request))
end
local function final_parse(self,request,wire)
 local class,costs,user=parts(wire)
 return q(self,'bindSkillCard',known(skill_cards[class],class),costs,action_request(self,request),user,class)
end
local function addAiSkills(name)local entry={name=name};package_skills[#package_skills+1]=entry;return entry end
local function he_count(player)return q(player,'getHandcardNum')+#q(player,'getEquips')end
local function owner_fact(self,key)return known(known(self.world.strategy_facts.genius,'genius')[key],key)end
local function context_card(self,key)
 local row=known(q(self,'getDecisionContext')[key],key)
 if type(row)~='table'then ai_unsupported('current question has no disclosed card',key)end
 return type(row.isKindOf)=='function'and row or known(CardView.new(row),key)
end
local function owner_eval(self,skill,name,costs)return q(self,'evaluateOwnerViewAsCard',{source_key=skill,skill=skill,name=name,suit=sgs.Card_NoSuit,number=0,subcards=costs})end
local function dummy(value,extra)local use=AIUsePlan.new();use.isDummy=value~=false;use.extra_target=extra or 0;return use end
local function no_distance(self,card)return q(self,'withOwnerRange','InfinityAttackRange','@@f_yonghunSlash',function()return q(self,'aiUseCard',card,dummy())end)end
local function can_to(self,card,from,to)
 if q(from,'objectName')~=q(self.player,'objectName')then ai_unsupported('foreign native targetFilter is not projected','f_skysson.foreign_actor')end
 return q(self,'cardTargetFilter',card,{},to)
end
local function remember_player(self,key,p)self:setStrategyMemory(key,p and q(p,'objectName')or false)end
local function remember_targets(self,key,targets)
 local names={};for _,p in ipairs(targets)do names[#names+1]=q(p,'objectName')end
 self:setStrategyMemory('GeniusPackageGod.'..key,names)
end
local function recall_targets(self,key)
 local names=self:getStrategyMemory('GeniusPackageGod.'..key);if names==nil then return nil end
 local targets=AIList.new{};for _,name in ipairs(names)do targets[#targets+1]=known(self.room:findPlayerByObjectName(name,true),key)end;return targets
end
local function peiqi(self)
 local fn=sgs.ai_skill_invoke.peiqi;if type(fn)~='function'then ai_unsupported('effective peiqi policy missing','f_yifa.peiqi')end
 local ok,value=pcall(fn,self,nil)
 if self.peiqiData then local d=self.peiqiData;self:setStrategyMemory('GeniusPackageGod.peiqi',{from=d.from and q(d.from,'objectName'),to=d.to and q(d.to,'objectName'),cid=d.cid})end
 if not ok then error(value,0)end;return value
end
local function peiqi_data(self)
 if self.peiqiData then return self.peiqiData end
 local row=known(self:getStrategyMemory('GeniusPackageGod.peiqi'),'f_yifa preceding peiqi state')
 return{from=row.from and known(self.room:findPlayerByObjectName(row.from,true),'peiqi.from'),to=row.to and known(self.room:findPlayerByObjectName(row.to,true),'peiqi.to'),cid=row.cid}
end
local function RandomList(items)
 local list=AIList.new(items);local remaining=AIList.new(items)
 while #remaining>0 do local v=remaining[math.random(1,#remaining)];table.removeOne(remaining,v);table.removeOne(list,v);list[#list+1]=v end
 return list
end
local function patterns(self)return known(self.world.strategy_facts.pattern_names,'public pattern catalog')end
addAiSkills("f_henjue").getTurnUseCard=function(self,inclusive,request)
	return parse(self,request,"#f_henjueCard:.:")
end

sgs.ai_skill_use_func["#f_henjueCard"] = function(card,use,self,request)
	sort_players(self,self.enemies)
    for _,p in sgs.list(self.enemies)do
		if q(p,"hasEquip") and q(p,"hasEquipArea") and q(self,"loseEquipEffect",p) then
			use.card = card
			call(use.to,"append",p)
			return
		end
	end
    for _,p in sgs.list(self.enemies)do
		if q(p,"hasEquip") and q(p,"hasEquipArea") then
			use.card = card
			call(use.to,"append",p)
			return
		end
	end
    for _,p in sgs.list(self.enemies)do
		if q(p,"hasEquipArea") and q(self,"loseEquipEffect",p) then
			use.card = card
			call(use.to,"append",p)
			return
		end
	end
end

sgs.ai_use_value.f_henjueCard = 1.4
sgs.ai_use_priority.f_henjueCard = 5.8
sgs.ai_card_intention.f_henjueCard = 50

sgs.ai_ajustdamage_from.f_pingpan = function(self, from, to, card, nature)
    local e = 0
    for i = 0, 4 do
        if not q(to,"hasEquipArea",i) then
            e = e + 1
        end
    end
    return e
end


local f_sandaoEX_skill = {}
f_sandaoEX_skill.name = "f_sandaoEX"
table.insert(package_skills, f_sandaoEX_skill)
f_sandaoEX_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 or q(self.player,"isKongcheng") then return end
	local too_weak = true
    local slash = q(self,"getEvaluationCard","slash")
    
	for _, player in ipairs(self.enemies) do
		if q(player,"getHp") <= 3 and q(self,"slashIsEffective",slash, player) then
			too_weak = false
		end
	end
	if too_weak then return end
	return parse(self,request,"#f_sandaoEXCard:.:")
end

sgs.ai_skill_use_func["#f_sandaoEXCard"] = function(card,use,self,request)
	local target
	local slash = q(self,"getEvaluationCard","slash")
	
	sort_players(self,self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if q(self,"isEnemy",enemy) and not q(self,"slashProhibit",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash) and q(self,"slashIsEffective",slash, enemy) and q(enemy,"getHp") <= 3 then
			target = enemy
            break
		end
	end
	if target then
		use.card=final_parse(self,request,"#f_sandaoEXCard:.:")
		return
	end
end

sgs.ai_use_value["f_sandaoEXCard"]       = 8
sgs.ai_use_priority["f_sandaoEXCard"]    = 2
sgs.ai_card_intention.f_sandaoEXCard     = 108

sgs.ai_skill_use["@@f_sandaoEXSlash"] = function(self, prompt, method)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "defense")
	local slash=owner_eval(self,"_f_sandaoEXSlash","slash",{})
	
	local dummy_use = q(self,"aiUseCard",slash, dummy())
	if dummy_use.to and q(dummy_use.to,"length") > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, q(to,"objectName"))
        end
        return "#f_sandaoEXSlashCard:.:->"..table.concat(tos, "+")
    end
	return "."
end




  
sgs.ai_skill_invoke.f_xiongyan = true

sgs.ai_skill_choice.f_xiongyan = function(self, choices, data)
	if q(self.player,"getHandcardNum") + q(self.player,"getEquips"):length() < 2 then return "1" end
	if q(self.player,"getHp") <= 1 then return "2" end
	for _, friend in ipairs(self.friends) do
		if q(friend,"hasFlag","f_shendongzhuo") then return "2" end
	end
	
	return "2"
end

sgs.ai_skill_discard.f_xiongyan = function(self) 
	local to_discard = {}
	local cards = q(self.player,"getCards","he")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	table.insert(to_discard, cards[1]:getEffectiveId())
	table.insert(to_discard, cards[2]:getEffectiveId())
	return to_discard
end

sgs.ai_skill_invoke["@f_xiongyanDraw"] = function(self, data)
	
	sort_players(self,self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"hasFlag","f_sdzForE") and q(self,"objectiveLevel",enemy) > 0 then 
		    return false
		end
	end
	return true
end
sgs.ai_skill_choice.f_qiandu = function(self, choices, data)
	return "1"
end

sgs.ai_skill_playerchosen.f_qiandu = function(self,players)
	local destlist = AIList.new(players) 
	sort_players(self,destlist,"card",true)
    for _,target in sgs.list(destlist)do
		if q(self,"isEnemy",target)
		and q(self,"doDisCard",target,"ej")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if q(self,"isFriend",target)
		and q(self,"doDisCard",target,"ej")
		then return target end
	end
	return nil
end

sgs.ai_skill_use["@@f_qiandu"] = function(self, prompt, method)
	local cards = q(self.player,"getCards","he")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	local values,range = {},q(self.player,"getAttackRange")
	local nplayer = self.player
	for i = 1,q(self.player,"aliveCount")do
		local fediff,add,isfriend = 0,0,nil
		local np = nplayer
		for value = #self.friends_noself,1,-1 do
			np = q(np,"getNextAlive")
			if q(np,"objectName")==q(self.player,"objectName") then
				if q(self,"isFriend",nplayer) then fediff = fediff+value
				else fediff = fediff-value
				end
			else
				if q(self,"isFriend",np) then
					fediff = fediff+value
					if isfriend then add = add+1
					else isfriend = true end
				elseif q(self,"isEnemy",np) then
					fediff = fediff-value
					isfriend = false
				end
			end
		end
		values[q(nplayer,"objectName")] = fediff+add
		nplayer = q(nplayer,"getNextAlive")
	end
	local function get_value(a)
		local ret = 0
		for _,enemy in ipairs(self.enemies)do
			if q(a,"objectName")~=q(enemy,"objectName") and q(a,"distanceTo",enemy)<=range then ret = ret+1 end
		end
		return ret
	end
	local function compare_func(a,b)
		if values[q(a,"objectName")]~=values[q(b,"objectName")] then
			return values[q(a,"objectName")]>values[q(b,"objectName")]
		else
			return get_value(a)>get_value(b)
		end
	end
	local players = AIList.new(q(self.room,"getAlivePlayers"))
	table.sort(players,compare_func)
	if values[players[1]:objectName()]>0 and players[1]:objectName()~=q(self.player,"objectName") then
		for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
			if q(self,"doDisCard",p,"ej") then
				return "#f_qianduCard:.:->"..players[1]:objectName()
			end
		end
	end
	return "."
end


sgs.ai_skill_invoke.f_yanyi = true

addAiSkills("f_yanyi").getTurnUseCard=function(self,inclusive,request)
    return parse(self,request,"#f_yanyiCard:.:")
end

sgs.ai_skill_use_func["#f_yanyiCard"] = function(card,use,self,request)
	use.card = card
end

addAiSkills("f_yishi").getTurnUseCard=function(self,inclusive,request)
	local sks = owner_fact(self,"yishi_skills"):split("+")
	if #sks > 0 and sgs.ai_skill_choice.f_yishi(self, "2+3") ~= "cancel"  then
    	return parse(self,request,"#f_yishiCard:.:")
	end
	if sgs.ai_skill_choice.f_yishi(self, "1") ~= "cancel" and q(self.player,"getHandcardNum") >= q(self.player,"getHp") and q(self.player,"getEquips"):length() > 0 and q(self.player,"canDiscard",self.player, "he") then
    	return parse(self,request,"#f_yishiCard:.:")
	end
end

sgs.ai_skill_use_func["#f_yishiCard"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_skill_choice.f_yishi = function(self, choices)
    local items = q(choices,"split","+")
    if q(self,"isWeak") and table.contains(items, "3") then
		return "3"
	end
	local acquire = getChoice(choices, "1")
	if acquire then
		return acquire
	end

	if table.contains(items, "2") then
		return "2"
	end
    return "cancel"
end



  
sgs.ai_skill_invoke.f_leji = function(self,data)
	local target = q(q(data,"toCardUse").to,"first")
	if q(self,"isFriend",target) and not (q(target,"getPhase") ~= sgs.Player_NotActive and  (q(target,"hasSkill","Dlimu") or q(target,"hasSkill","limu"))) then
		return true
	end
	if q(self,"isEnemy",target) and (q(target,"getPhase") ~= sgs.Player_NotActive and (q(target,"hasSkill","Dlimu") or q(target,"hasSkill","limu"))) then
		return true
	end
    return false
end

sgs.ai_choicemade_filter.skillInvoke.f_leji = function(self, player, promptlist)
   	local target
	for _,p in sgs.qlist(q(self.room,"getOtherPlayers",player))do
		if q(p,"hasFlag","f_leji") then target = p break end
	end
	if target and not (q(target,"getPhase") ~= sgs.Player_NotActive and  (q(target,"hasSkill","Dlimu") or q(target,"hasSkill","limu"))) then
		if promptlist[#promptlist]=="yes" then
        	call(self,"updateIntention",player, target, -80)
		end
    end
end


sgs.ai_skill_playerchosen.f_leji = function(self, targets)
    targets = AIList.new(targets)
	sort_players(self,targets, "defense")
    for _, target in ipairs(targets) do
        if q(self,"isFriend",target) then
            return target
        end
    end
    return nil
end
sgs.ai_playerchosen_intention.f_leji = -80


sgs.ai_skill_discard.f_leji = function(self,discard_num,min_num,optional,include_equip)
	local targets = AIList.new({})
	for _, cjl in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		if q(cjl,"containsTrick","indulgence") then 
			call(targets,"append",cjl)
		end
	end
	if sgs.ai_skill_playerchosen.f_leji(self, targets) ~= nil then
		return {}
	end
	if q(self,"isWeak") or math.random() < 0.5 then
		local to_discard = {}
		local cards = AIList.new(q(self.player,"getCards","he"))
		sort_keep(self,cards)
		table.insert(to_discard, cards[1]:getEffectiveId())
		if #to_discard > 0 then
			return to_discard
		end
	end

	return {}
end
sgs.ai_skill_invoke.f_wuyou = true
sgs.ai_skill_playerchosen.f_wuyou = function(self, targets)
	targets = AIList.new(targets)
	for _, p in ipairs(targets) do
	    if q(self,"isFriend",p) then
		    return p
		end
	end
	return self.player
end

sgs.ai_skill_choice.f_wuyou = function(self, choices, data)
	if q(self.player,"hasJudgeArea") then
		local n = q(self.player,"getJudgingArea"):length()
		if q(self.player,"getHp") < 2 then return "2" end 
		if n > 0 and #self.friends_noself <= 0 then return "2" end
		if n == 0 then return "1="..n+1 end
	end
	return "cancel"
end


  

sgs.ai_skill_playerchosen.f_dansha = function(self, targets)
	targets = AIList.new(targets)
	for _, p in ipairs(targets) do
	    if q(self,"isEnemy",p) then
		    return p
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.f_dansha = 80





  
sgs.ai_skill_invoke.f_qizhen = function(self, data)
	local use = q(data,"toCardUse")
	return not q(self,"isFriend",use.from)
end

  
sgs.ai_skill_invoke.f_lijun = true
sgs.ai_skill_invoke["@f_lijunGHJ"] = function(self, data)
	local target = q(data,"toPlayer")
	return q(self,"isFriend",target)
end

sgs.ai_choicemade_filter.skillInvoke["@f_lijunGHJ"] = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = call(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then call(self,"updateIntention",player,target,-50) end
	end
end

sgs.ai_skill_choice.f_lijun = function(self, choices, data)
	local target = q(data,"toPlayer")
	if q(self,"isEnemy",target) then 
		return "2"
	end
	return "1"
end

sgs.ai_skill_playerchosen.f_lijun = function(self, targets)
	local targets = AIList.new(targets)
	sort_players(self,self.friends_noself)
	for _, p in ipairs(self.friends_noself) do 
		if q(self,"isFriend",p) and q(p,"getHandcardNum") == 0 and not q(p,"hasSkill","kongcheng") and q(self,"canDraw",p, self.player) then
			return p
		end
	end
	for _, p in ipairs(self.friends_noself) do 
		if q(self,"isFriend",p) and q(p,"getHandcardNum") < q(p,"getHp") and q(self,"canDraw",p, self.player) then
			return p
		end
	end

	sort_players(self,targets, "defense")
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and q(p,"getHandcardNum") - q(p,"getHp") >= 3 then
			return p
		end
	end
		for _, p in ipairs(self.friends_noself) do 
		if q(self,"isFriend",p) then
			return p
		end
	end
	return self.player 
end


addAiSkills("f_yonghun").getTurnUseCard=function(self,inclusive,request)
    return parse(self,request,"#f_yonghunCard:.:")
end

sgs.ai_skill_use_func["#f_yonghunCard"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value.f_yonghunCard = 5.4
sgs.ai_use_priority.f_yonghunCard = 2.8

sgs.ai_skill_invoke.f_yonghun = function(self, data)
	local card = q(data,"toCard")
	if q(card,"isKindOf","Analeptic") then
		if q(self,"getCardsNum","Slash")>0 then
			local slash = call(self,"getCard","Slash")
			if slash then
				assert(slash)
				local dummy_use = q(self,"aiUseCard",slash, dummy())
				if dummy_use.card and dummy_use.to then
					if not q(dummy_use.to,"isEmpty") then
						return true
					end
				end
			end
		end
	end
	if q(card,"isKindOf","Jink") then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.f_yonghun = function(self,targets)
	for _,p in sgs.qlist(targets) do
		if q(self,"isFriend",p) and q(p,"getHp") < q(self,"getBestHp",p) then
			return p
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.f_yonghun = -40


sgs.ai_skill_use["@@f_yonghunSlash"] = function(self, prompt)
	local cards = q(self.player,"getCards","h")
    cards = AIList.new(cards)
    sort_keep(self,cards)
	for _,h in sgs.list(cards)do
		if q(h,"hasFlag","f_yonghun") and q(h,"isKindOf","Slash") then
			
			local dummy_use = q(self,'withOwnerRange','InfinityAttackRange','@@f_yonghunSlash',function()
                call(self,'writeOwnerRangeQinggang',h,true)
                local value=q(self,'aiUseCard',h,dummy())
                call(self,'writeOwnerRangeQinggang',h,false)
                return value
            end)
			
			if dummy_use.to and q(dummy_use.to,"length") > 0 then
				local tos = {}
				for _,to in sgs.qlist(dummy_use.to) do
					table.insert(tos, q(to,"objectName"))
				end
				return "#f_yonghunSlashCard:"..q(h,"getEffectiveId")..":->"..table.concat(tos, "+")
			end
		end
	end
    return "."
end

sgs.ai_skill_invoke.f_jianyuanadd = function(self, data)
	local str = q(data,"toString")
	if string.startsWith(str, "JianYuanLu")  then
		return true
	end
end
sgs.ai_skill_invoke.f_jianyuan = function(self, data)
	if q(self.player,"getHandcardNum") > q(self.player,"getMark","&f_jianyuanX") + 4 + 2 then
		local JianYuanLu = owner_fact(self,"jianyuan_record"):split("+")
		if math.random() < 0.3 and #JianYuanLu > 0 then
			return false
		end
	end
	return true
end
sgs.ai_can_damagehp.f_jianyuan = function(self,from,card,to)
	return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)-1>0
	and q(self,"canLoseHp",from,card,to) and from and q(from,"isMale")
end

sgs.ai_skill_choice.f_jianyuan = function(self, choices, data)
	if q(self.player,"getMark","&f_jianyuanY") + 3 < 4 +q(self.player,"getMark","&f_jianyuanX") then
		return "y"
	end
	return "x"
end

sgs.ai_skill_use["@@f_jianyuangive"] = function(self, prompt)
	local cards = q(self.player,"getCards","h")
    cards = AIList.new(cards)
	sort_use(self,cards,true)
	for _,h in sgs.list(cards)do
		if q(h,"hasFlag","f_jianyuan") then
			for _, p in ipairs(self.friends_noself) do
				if q(p,"hasFlag","f_JYuan") and call(p,"getWeapon") ~= nil then
					return "#f_jianyuangiveCard:"..q(h,"getEffectiveId")..":->"..q(p,"objectName")
				end
			end
			for _, p in ipairs(self.friends_noself) do
				if q(p,"hasFlag","f_JYuan") then
					local JianYuanLu = owner_fact(self,"jianyuan_record"):split("+")
					if not table.contains(JianYuanLu, q(p,"getGeneralName")) then
						return "#f_jianyuangiveCard:"..q(h,"getEffectiveId")..":->"..q(p,"objectName")
					end
				end
			end
			for _, p in ipairs(self.friends_noself) do
				if q(p,"hasFlag","f_JYuan") and q(self,"canDraw",p, self.player) then
					return "#f_jianyuangiveCard:"..q(h,"getEffectiveId")..":->"..q(p,"objectName")
				end
			end
			for _, p in ipairs(AIList.new(q(self.room,"getOtherPlayers",self.player))) do
				if q(p,"hasFlag","f_JYuan") and not q(p,"hasFlag","f_JYuan_real") then
					local JianYuanLu = owner_fact(self,"jianyuan_record"):split("+")
					if not table.contains(JianYuanLu, q(p,"getGeneralName")) then
						return "#f_jianyuangiveCard:"..q(h,"getEffectiveId")..":->"..q(p,"objectName")
					end
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_use["@@f_jianyuanthrow!"] = function(self, prompt)
	local cards = q(self.player,"getCards","h")
    cards = AIList.new(cards)
	sort_use(self,cards,true)
	for _,h in sgs.list(cards)do
		if q(h,"hasFlag","f_jianyuan") then
			return "#f_jianyuanthrowCard:"..q(h,"getEffectiveId")..":"
		end
	end
end

sgs.ai_skill_choice.f_gongli = function(self, choices, data)
	local items = q(choices,"split","+")
	local current = call(self.room,"getCurrent")
	if current and (q(self,"isFriend",current) or (not q(self,"isFriend",current) and q(current,"getHp") >= q(self,"getBestHp",current))) then
		if table.contains(items, "ue") then
			if q(self,"loseEquipEffect",self.player) or math.random() < 0.5 or (q(self.player,"hasSkill","f_jianyuan") and call(self.player,"getWeapon") == nil) then
				return "ue"
			end
		end
		return "dc"
	end
	return "cancel"
end



  
sgs.ai_skill_invoke.f_huisheng = function(self, data)
	
	local dying = q(data,"toDying")
	local peaches = 1 - q(dying.who,"getHp")
	return q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") < peaches
end

  
sgs.ai_skill_invoke.f_miaodao = function(self, data)
	if q(self.player,"getPile","f_syjDao"):length() >= 4 or q(self.player,"getHandcardNum") <= 2 then return false end
	return true
end
sgs.ai_skill_invoke.f_yifa = function(self, data)
	if peiqi(self)
	then
		return true
	end
	local current = call(self.room,"getCurrent")
	if current then
		return q(self,"doDisCard",current, "ej", true)
	end
	if current and q(self,"isEnemy",current) then
		return q(self,"doDisCard",current, "hej", true)
	end
	return false
end


sgs.ai_skill_playerchosen.f_yifa_from = function(self,players)
	peiqi(self)
    for _,target in sgs.list(players)do
		if target==peiqi_data(self).from
		then return target end
	end
    for _,target in sgs.list(players)do
        return target
    end
end

sgs.ai_skill_cardchosen.f_yifa = function(self,who,flags,method)
	for _,e in sgs.list(q(who,"getCards",flags))do
		local id = q(e,"getEffectiveId")
		if id==peiqi_data(self).cid
		then return id end
	end
end

sgs.ai_skill_playerchosen.f_yifa_to = function(self,players)
    for _,target in sgs.list(players)do
		if target==peiqi_data(self).to
		then return target end
	end
    for _,target in sgs.list(players)do
        return target
    end
end

sgs.ai_skill_choice.f_yifa = function(self, choices, data)
	if peiqi(self)
	then
		return "move"
	end
	return "get"
end

sgs.ai_skill_use["@@f_yifa!"] = function(self, prompt)
	for _,id in sgs.qlist(q(self.player,"getPile","f_syjDao"))do
		return "#f_yifaCard:"..id..":"
	end
	return "."
end




  
sgs.ai_skill_choice.f_fengchu = function(self, choices, data)
	if q(self.player,"isWounded") then return "2"
	else return "1" end 
	return "3" or "4" 
end

addAiSkills("f_shenpan").getTurnUseCard=function(self,inclusive,request)
    return parse(self,request,"#f_shenpanCard:.:")
end

sgs.ai_skill_use_func["#f_shenpanCard"] = function(card,use,self,request)
	local cards = q(self.player,"getCards","h")
	cards = AIList.new(cards)
	local card
	sort_use(self,cards, true)
	for _, acard in ipairs(cards) do
		if q(self,"getUseValue",acard) < 6 then
			card = acard
			break
		end
	end
	if not card then return nil end

	local card_id = q(card,"getEffectiveId")
	for _,enemy in sgs.list(self.enemies)do
		if q(enemy,"getMark","f_shenpan-PlayClear") == 0 then
			for _, m in sgs.list(q(enemy,"getMarkNames")) do
            	if q(m,"startsWith","f_shenpan") and q(enemy,"getMark",m) > 0 then
					use.card=final_parse(self,request,"#f_shenpanCard:" .. card_id .. ":")
					call(use.to,"append",enemy)
					return
				end
			end
		end
	end
end

sgs.ai_use_value.f_shenpanCard = 5.4
sgs.ai_use_priority.f_shenpanCard = 2
sgs.ai_card_intention.f_shenpanCard = 80

addAiSkills("f_qigong").getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"getEquips"):length() > 0 and not (q(self.player,"getMark","&fJuJiang") > 0 and q(self.player,"getPile","spy_shenbingku"):isEmpty()) then
		 return parse(self,request,"#pro_f_qigongCard:.:")
	end
    return parse(self,request,"#mini_f_qigongCard:.:")
end

sgs.ai_skill_use_func["#pro_f_qigongCard"] = function(card,use,self,request)
	local cards = AIList.new(q(self.player,"getCards","e"))
	local to_use = {}
	for _, c in ipairs(cards) do
		table.insert(to_use, q(c,"getEffectiveId"))
	end
	if #to_use == 0 then return nil end

	use.card=final_parse(self,request,"#pro_f_qigongCard:"..table.concat(to_use, "+") ..":")
	return 
end
sgs.ai_skill_use_func["#mini_f_qigongCard"] = function(card,use,self,request)
	use.card = card
	return
end
sgs.ai_skill_playerchosen.f_qigong = function(self,players)
	local destlist = AIList.new(players) 
	sort_players(self,destlist,"card",true)
    for _,target in sgs.list(destlist)do
		if q(self,"isFriend",target)
		and q(self,"loseEquipEffect",target)
		then return target end
	end
	local card = context_card(self,"genius_qigong_card")
	for _, friend in ipairs(self.friends_noself) do
		local equip_index = q(card,"getEquipSlot")
		if not call(self,"getSameEquip",card, friend) and q(self,"hasSkills",sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) and call(friend,"getEquip",equip_index) == nil and q(friend,"hasEquipArea",equip_index) then
			return friend
		end

		local equip_index = q(card,"getEquipSlot")
		if not call(self,"getSameEquip",card, friend) and call(friend,"getEquip",equip_index) == nil and q(friend,"hasEquipArea",equip_index) then
			return friend
		end
		
	end
	return self.player
end

sgs.ai_playerchosen_intention.f_qigong = -40



local f_lingqi_skill = {}
f_lingqi_skill.name = "f_lingqi"
table.insert(package_skills,f_lingqi_skill)
f_lingqi_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = q(self,"addHandPile","he")
	local equip_card
	sort_use(self,cards,true)
	for _,card in ipairs(cards)do
		if q(card,"getTypeId")==sgs.Card_TypeEquip and (q(self,"getUseValue",card)<sgs.ai_use_value.Slash or inclusive) then
			equip_card = card
			break
		end
	end
	if equip_card then
		local suit = q(equip_card,"getSuitString")
		local number = q(equip_card,"getNumberString")
		local card_id = q(equip_card,"getEffectiveId")
		if q(self.player,"getMark","&fXiaJiang") > 0 then
			if suit == "heart" then
				return parse(self,request,("fire_slash:f_lingqi[%s:%s]=%d"):format(suit,number,card_id))
			elseif suit == "diamond" then
				return parse(self,request,("thunder_slash:f_lingqi[%s:%s]=%d"):format(suit,number,card_id))
			elseif suit == "club" then
				return parse(self,request,("ice_slash:f_lingqi[%s:%s]=%d"):format(suit,number,card_id))
			elseif suit == "spade" then
				return parse(self,request,("slash:f_lingqix_poison[%s:%s]=%d"):format(suit,number,card_id))
			end
		end
		return parse(self,request,("slash:f_lingqij[%s:%s]=%d"):format(suit,number,card_id))
	end
end

sgs.ai_card_priority.f_lingqi = function(self,card)
	if table.contains(q(card,"getSkillNames"), "f_lingqi") or table.contains(q(card,"getSkillNames"), "f_lingqij") or table.contains(q(card,"getSkillNames"), "f_lingqix_poison")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end




sgs.ai_use_revises.f_lingqi = function(self,card,use)
	if q(card,"isKindOf","Slash") and table.contains(q(card,"getSkillNames"), "f_lingqij") then
		call(self,"setStrategyCardFlag",card,"Qinggang",true)
	end
end

addAiSkills("f_shenjiang").getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"getMark","&fJuJiang") > 0 and q(self.player,"getPile","spy_shenbingku"):isEmpty() then return end
    return parse(self,request,"#f_shenjiangCard:.:")
end
sgs.ai_skill_use_func["#f_shenjiangCard"] = function(card,use,self,request)
	local cards = AIList.new(q(self.player,"getPile","f_YT"))
	local to_use = {}
	for _, id in ipairs(cards) do
		table.insert(to_use, id)
		if #to_use >= 4 then break end
	end
	if #to_use ~= 4 then return end
	sort_players(self,self.friends, "defense", true)
	for _,friend in ipairs(self.friends) do
		use.card=final_parse(self,request,"#f_shenjiangCard:".. table.concat(to_use, "+") ..":")
		call(use.to,"append",friend)
		return
	end
end
sgs.ai_skill_cardask["@f_shenjiangRecast"] = function(self, data, pattern, target, target2)	
	return true
end
sgs.ai_card_intention.f_shenjiangCard = -80

sgs.ai_skill_use["@@f_shenjiangSBK!"] = function(self, prompt)
	local target
    for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
        if q(p,"hasFlag","f_shenjiangTarget") then
            target = p
            break
        end
    end
	local card_ids = RandomList(q(self.player,"getPile","spy_shenbingku"))
	for _,id in sgs.qlist(card_ids)do
		if not call(self,"getSameEquip",disclosed(self,id),target) then
			return "#f_shenjiangSBKCard:"..id..":"
		end
	end
	for _,id in sgs.qlist(card_ids)do
		return "#f_shenjiangSBKCard:"..id..":"
	end
	return "."
end



addAiSkills("f_jishen").getTurnUseCard=function(self,inclusive,request)
    return parse(self,request,"#f_jishenCard:.:")
end
sgs.ai_skill_use_func["#f_jishenCard"] = function(card,use,self,request)
	sort_players(self,self.friends, "defense", true)
	for _,friend in ipairs(self.friends) do
		use.card=final_parse(self,request,"#f_jishenCard:.:")
		call(use.to,"append",friend)
		return
	end
end

sgs.ai_card_intention.f_jishenCard = -80

  
sgs.ai_skill_playerchosen.f_zhengmie_f = function(self,targets)
	local target
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"hasFlag","f_zhengmie_fTarget") then
			target = p
			break
		end
	end
	local dc=owner_eval(self,"f_zhengmie_f","slash",{})
	for _,p in sgs.qlist(targets) do
		if q(self,"isEnemy",p) and q(self,"isGoodTarget",p,self.enemies, dc) and not q(self,"needToLoseHp",p, target, dc) and  q(self,"slashIsEffective",dc, p) then
			return p
		end
	end
	for _,p in sgs.qlist(targets) do
		if q(self,"isEnemy",p) and q(self,"isGoodTarget",p,self.enemies, dc) and  q(self,"slashIsEffective",dc, p) then
			return p
		end
	end
	for _,p in sgs.qlist(targets) do
		if q(self,"isFriend",p) and q(self,"needToLoseHp",p, target, dc) then
			return p
		end
	end
	return nil
end


sgs.ai_playerchosen_intention.f_zhengmie_f = 50

  
sgs.ai_skill_choice.dy_shemi = function(self, choices, data)
	local items = q(choices,"split","+")
	if table.contains(items, "1") then
		return "1"
	end
	if table.contains(items, "2") then
		return "2"
	end
	return "cancel"
end




  

sgs.ai_skill_invoke.f_skysson = function(self, data)
	return sgs.ai_skill_playerchosen.f_skysson(self, q(self.room,"getAllPlayers")) ~= self.player
end

sgs.ai_skill_playerchosen.f_skysson = function(self, targets)
	local targets = AIList.new(targets)
	for _, p in ipairs(targets) do
		if q(self,"isEnemy",p) and q(self,"doDisCard",p, "hej", true) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if q(self,"isFriend",p) and q(self,"doDisCard",p, "hej", true) then
			return p
		end
	end
	return self.player
end
sgs.ai_skill_playerchosen.f_skysson_slash = function(self, targets)
	local targets = AIList.new(targets)
	for _, p in ipairs(targets) do
		if q(self,"isFriend",p) and getKnownCard(p, self.player, "Slash") > 0 then
			return p
		end
	end
	local dc=owner_eval(self,"f_skysson","slash",{})
	for _, p in ipairs(targets) do
		if q(self,"slashIsEffective",dc,p,self.player) then
			return p
		end
	end
	return targets[1]
end

addAiSkills("f_skysson").getTurnUseCard=function(self,inclusive,request)
	local cards = q(self.player,"getCards","he")
	cards = sort_keep(self,cards)
	for _,c in sgs.list(cards)do
		return parse(self,request,"#f_skyssonCard:"..q(c,"getEffectiveId")..":")
	end
end

sgs.ai_skill_use_func["#f_skyssonCard"] = function(card,use,self,request)
	sort_players(self,self.enemies,"hp")
	local dc=owner_eval(self,"f_skysson","slash",{})
	for _,ep in sgs.list(self.enemies)do
		for _,fp in sgs.list(self.friends_noself)do
			if can_to(self,dc,fp,ep)
			and can_to(self,dc,self.player,ep) and getKnownCard(fp, self.player, "Slash") > 0
			then
				use.card = card
				call(use.to,"append",fp)
				call(use.to,"append",ep)
				return
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		for _,fp in sgs.list(self.friends_noself)do
			if can_to(self,dc,fp,ep) and getKnownCard(fp, self.player, "Slash") > 0
			then
				use.card = card
				call(use.to,"append",fp)
				call(use.to,"append",ep)
				return
			end
		end
	end
	for _,ep in sgs.list(q(self.room,"getOtherPlayers",self.player))do
		for _,fp in sgs.list(self.friends_noself)do
			if can_to(self,dc,fp,ep) 
			and not q(self,"isFriend",ep) and getKnownCard(fp, self.player, "Slash") > 0
			then
				use.card = card
				call(use.to,"append",fp)
				call(use.to,"append",ep)
				return
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		for _,ep2 in sgs.list(self.enemies)do
			if can_to(self,dc,ep2,ep)
			and can_to(self,dc,self.player,ep) then
				use.card = card
				call(use.to,"append",ep)
				call(use.to,"append",ep2)
				return
			end
		end
	end
end

sgs.ai_use_value.f_skyssonCard = 3.4
sgs.ai_use_priority.f_skyssonCard = 3.8

sgs.ai_skill_playerchosen.f_skysson = function(self,targets)
	local enemies = sort_players(self,targets,"hp")
  	for i,p in sgs.list(enemies)do
		remember_player(self,"tenyear_st_standard.mingce_to",p)
		if q(self,"isEnemy",p)
		then return p end
	end
  	for i,p in sgs.list(enemies)do
		remember_player(self,"tenyear_st_standard.mingce_to",p)
		if not q(self,"isFriend",p)
		then return p end
	end
	remember_player(self,"tenyear_st_standard.mingce_to",enemies[1])
	return enemies[1]
end


sgs.ai_skill_cardask["@f_skysson-jink"] = function(self, data, pattern, target, target2)	
	local target = q(data,"toPlayer")
	if q(self,"isFriend",target) then
		return true
	end
	return "."
end


  
sgs.ai_skill_invoke.f_kuilei = true


sgs.ai_skill_playerchosen.f_kuilei = function(self, targets)
	local targets = AIList.new(targets)
	sort_players(self,self.friends_noself, "handcard")
	for _, p in ipairs(self.friends_noself) do
		if q(self,"isFriend",p) and getKnownCard(p, self.player, "Peach") > 0 then 
			return p
		end
	end
	for _, p in ipairs(targets) do 
		if q(self,"isEnemy",p) and q(self,"doDisCard",p, "he") then
			return p
		end
	end
end

sgs.ai_skill_cardask["@f_kuilei-peach"]=function(self,data)
	local dying = q(data,"toDying")
	if dying.who then
		if q(self,"isFriend",dying.who) then
			return true
		end
		if q(self,"isEnemy",dying.who) then
			if q(dying.who,"isLord") then return "." end
			if math.random() < 0.5 then return true end
		end
	end
	return "."
end

sgs.ai_skill_playerchosen.f_dansha_new = function(self, targets)
	targets = AIList.new(targets)
	for _, p in ipairs(targets) do
	    if q(self,"isEnemy",p) then
		    return p
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.f_dansha_new = 80




  
sgs.ai_skill_invoke.diy_k_luoshang = true
ai_audited_aliases.register{id="ai_skill_invoke.diy_k_luoshang_judge",registry="ai_skill_invoke",path={"diy_k_luoshang_judge"},canonical_registry="ai_skill_invoke",canonical_path={"noszhenlie"},self_index=1,defer_canonical=true}


addAiSkills("diy_k_luoshang").getTurnUseCard=function(self,inclusive,request)
	return parse(self,request,"#diy_k_luoshang:.:")
end

sgs.ai_skill_use_func["diy_k_luoshang"] = function(card,use,self,request)
	use.card = card
end



sgs.ai_ajustdamage_from.f_mingwang = function(self, from, to, card, nature)
    if q(to,"getMark","&f_ysS")==0
    then
        return 1
    end
end



  
sgs.ai_skill_choice.f_mingwang = function(self, choices, data)
	return "1"
end

  
sgs.ai_skill_invoke.f_feishi = function(self, data)
	local str = q(data,"toString"):split(":")[2]
	local target = call(self.room,"findPlayerByObjectName",str)
	return target and not q(self,"isFriend",target)
end


  
sgs.ai_skill_choice.f_lijian = function(self, choices, data)
	local target = q(data,"toPlayer")
	if q(self,"isWeak") and q(self,"canHit",self.player,target,true) then
		return "1"
	end
	return "2"
end
sgs.ai_skill_cardask["@f_lijian-SlashShow"]=function(self,data)
	local use = q(data,"toCardUse")
	if use.from and q(self,"isEnemy",use.from) then
		return true
	end
	return "."
end

sgs.ai_ajustdamage_from.f_lijian = function(self, from, to, card, nature)
    if card and q(card,"hasFlag","f_lijian_slash_dmg")
    then
        return 1
    end
end
sgs.ai_ajustdamage_from.f_luanji = function(self, from, to, card, nature)
    if card and table.contains(q(card,"getSkillNames"), "f_luanji") and q(card,"subcardsLength") >= 3
    then
        return 1
    end
end

  

local f_luanji_skill = {}
f_luanji_skill.name = "f_luanji"
table.insert(package_skills, f_luanji_skill)
f_luanji_skill.getTurnUseCard=function(self,inclusive,request)
	local first_found, second_found = false, false
	local first_card, second_card
	if he_count(self.player) >= 2 and q(self.player,"getMark","f_luanji_used-PlayClear") == 0 then
		local cards = q(self.player,"getCards","he")
		cards = AIList.new(cards)
		sort_keep(self,cards)
		local useAll = false
		for _, enemy in ipairs(self.enemies) do
			if q(enemy,"getHp") == 1 and not q(enemy,"hasArmorEffect","Vine") and not q(self,"hasEightDiagramEffect",enemy) and q(self,"damageIsEffective",enemy, nil, self.player)
				and q(self,"isWeak",enemy) and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
				useAll = true
			end
		end
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("ArcheryAttack", fcard, self.player))
			if useAll then fvalueCard = isCard("ArcheryAttack", fcard, self.player) end
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player))
					if useAll then svalueCard = (isCard("ArcheryAttack", scard, self.player)) end
					if first_card ~= scard and q(scard,"getColor") == q(fcard,"getColor") and not svalueCard then
						local card_str = ("archery_attack:f_luanji[%s:%s]=%d+%d"):format("to_be_decided", 0, q(first_card,"getId"), q(scard,"getId"))
						local archeryattack = parse(self,request,card_str)
						assert(archeryattack)
						local dummy_use = { isDummy = true }
						call(self,"useTrickCard",archeryattack, dummy_use)
						if dummy_use.card then
							second_card = scard
							second_found = true
							break
						end
					end
				end
				if second_card then break end
			end
		end
	end
	if first_found and second_found then
		local first_id = q(first_card,"getId")
		local second_id = q(second_card,"getId")
		local card_str = ("archery_attack:f_luanji[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = parse(self,request,card_str)
		assert(archeryattack)
		return archeryattack
	end
end

  
local f_huimeng_skill = {}
f_huimeng_skill.name = "f_huimeng"
table.insert(package_skills, f_huimeng_skill)
f_huimeng_skill.getTurnUseCard=function(self,inclusive,request)
	if (q(self.player,"getEquips"):length() == 0 and q(self.player,"getHandcardNum") <= q(self.player,"getHp")) or q(self.player,"getMark","&fUnited") >= 18 then return end
	local card_id
	local cards = q(self.player,"getCards","he")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	local lightning = call(self,"getCard","Lightning")
	if q(self,"needToThrowArmor") then
		card_id = call(self.player,"getArmor"):getId()
	elseif q(self.player,"getHandcardNum") > q(self.player,"getHp") then
		if lightning and not q(self,"willUseLightning",lightning) then
			card_id = q(lightning,"getEffectiveId")
		else
			for _, acard in ipairs(cards) do
				if q(acard,"isKindOf","EquipCard") or q(acard,"isKindOf","AmazingGrace") then
					card_id = q(acard,"getEffectiveId")
					break
				end
			end
		end
	elseif not q(self.player,"getEquips"):isEmpty() then
		local player = self.player
		if call(player,"getWeapon") then card_id = call(player,"getWeapon"):getId()
		elseif call(player,"getOffensiveHorse") then card_id = call(player,"getOffensiveHorse"):getId()
		elseif call(player,"getDefensiveHorse") then card_id = call(player,"getDefensiveHorse"):getId()
		elseif call(player,"getArmor") and q(player,"getHandcardNum") <= 1 then card_id = call(player,"getArmor"):getId()
		end
	end
	if not card_id then
		if lightning and not q(self,"willUseLightning",lightning) then
			card_id = q(lightning,"getEffectiveId")
		else
			for _, acard in ipairs(cards) do
				if q(acard,"isKindOf","EquipCard") or q(acard,"isKindOf","AmazingGrace") then
					card_id = q(acard,"getEffectiveId")
					break
				end
			end
		end
	end
	if not card_id then
		for _, acard in ipairs(cards) do
			if q(acard,"isKindOf","BasicCard") and not q(acard,"isKindOf","Peach") and not q(acard,"isKindOf","Analeptic") then
				card_id = q(acard,"getEffectiveId")
				break
			end
		end
	end
	if not card_id then
	    if q(self.player,"getLostHp") > q(self,"getCardsNum","Peach") then
			return nil
		else
			return parse(self,request,"#lcd_f_huimengCard:.:")
		end
	else
	    return parse(self,request,"#lcd_f_huimengCard:"..card_id..":")
	end
end

    
sgs.ai_skill_use_func["#lcd_f_huimengCard"] = function(card,use,self,request)
	use.card = card
	return
end
sgs.ai_use_value.lcd_f_huimengCard = 1.8
sgs.ai_use_priority.lcd_f_huimengCard = 1.8

sgs.ai_skill_invoke["@f_huimeng-crzw"] = function(self, data)
	local dying = q(data,"toDying")
	return not q(self,"isFriend",dying.who) and q(self.player,"getMark","&fUnited") / 3 <= he_count(dying.who)
end

sgs.ai_skill_invoke["@f_huimeng-myzd"] = function(self, data)
	local damage = q(data,"toDamage")
	return q(self.player,"getHp") + q(self.player,"getHujia") + q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") <= damage.damage
end





  
sgs.ai_target_revises.tc_juxiang_stsh = function(to,card)
	if q(card,"isKindOf","SavageAssault")
	then return true end
end

sgs.ai_skill_invoke.tc_liefeng_spwd = function(self, data)
	local use = q(data,"toCardUse")
	for _, p in sgs.qlist(use.to) do
		if q(self,"isFriend",p) then return false end
	end
	return true
end

sgs.ai_skill_playerchosen.tc_liefeng_spwd = function(self, targets)
	targets = AIList.new(targets)
	for _, p in ipairs(targets) do
	    if q(self,"isEnemy",p) and q(p,"getHp") <= 1 and not q(p,"hasSkill","newjuejing") and not q(p,"hasSkill","mrds_juejing")
		and not q(p,"hasSkill","zjjuejing") and not q(p,"hasSkill","szsjuejing") then
		    return p
		end
	end
	for _, p in ipairs(targets) do
	    if q(self,"isEnemy",p) then
		    return p
		end
	end
	return nil
end


addAiSkills("tc_changbiao_sqrh").getTurnUseCard=function(self,inclusive,request)
	local cards = q(self.player,"getCards","h")
	cards = sort_keep(self,cards,nil,true)
	if #cards<1 then return end
	local ids = {}
   	local fs
  	for _,c in sgs.list(cards)do
		if q(self,"getKeepValue",c)>3
		or #ids>=#cards/2 then continue end
		table.insert(ids,q(c,"getEffectiveId"))
		
	end
	if #ids<1 and #cards>1
	then
		table.insert(ids,cards[1]:getEffectiveId())
		
	end
	fs=owner_eval(self,"tc_changbiao_sqrh","slash",ids)
	local dummy = q(self,"aiUseCard",fs, dummy(true, 99))
	if q(fs,"isAvailable",self.player)
	and dummy.card
	and dummy.to
	and #ids>0
  	then
		remember_targets(self,"olcb_to",dummy.to)
		ids = #ids>0 and table.concat(ids,"+") or "."
		return parse(self,request,"#tc_changbiao_sqrh:"..ids..":")
	end
end

sgs.ai_skill_use_func["#tc_changbiao_sqrh"] = function(card,use,self,request)
	use.card = card
	use.to = recall_targets(self,"olcb_to")
end

sgs.ai_use_value.tc_changbiao_sqrh = 9.4
sgs.ai_use_priority.tc_changbiao_sqrh = 2.8





  
local diy_k_meihun_skill = {}
diy_k_meihun_skill.name = "diy_k_meihun"
table.insert(package_skills, diy_k_meihun_skill)
diy_k_meihun_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"usedTimes","#diy_k_meihun") >= 1 or q(self.player,"isNude") or #self.enemies == 0 then return end
	local card_id
	local cards = q(self.player,"getHandcards")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	local lightning = call(self,"getCard","Lightning")
	if q(self,"needToThrowArmor") then
		card_id = call(self.player,"getArmor"):getId()
	elseif q(self.player,"getHandcardNum") > q(self.player,"getHp") then
		if lightning and not q(self,"willUseLightning",lightning) then
			card_id = q(lightning,"getEffectiveId")
		else
			for _, acard in ipairs(cards) do
				if (q(acard,"isKindOf","BasicCard") or q(acard,"isKindOf","EquipCard") or q(acard,"isKindOf","AmazingGrace"))
					and not q(acard,"isKindOf","Peach") then
					card_id = q(acard,"getEffectiveId")
					break
				end
			end
		end
	elseif not q(self.player,"getEquips"):isEmpty() then
		local player = self.player
		if call(player,"getWeapon") then card_id = call(player,"getWeapon"):getId()
		elseif call(player,"getOffensiveHorse") then card_id = call(player,"getOffensiveHorse"):getId()
		elseif call(player,"getDefensiveHorse") then card_id = call(player,"getDefensiveHorse"):getId()
		elseif call(player,"getArmor") and q(player,"getHandcardNum") <= 1 then card_id = call(player,"getArmor"):getId()
		end
	end
	if not card_id then
		if lightning and not q(self,"willUseLightning",lightning) then
			card_id = q(lightning,"getEffectiveId")
		else
			for _, acard in ipairs(cards) do
				if (q(acard,"isKindOf","BasicCard") or q(acard,"isKindOf","EquipCard") or q(acard,"isKindOf","AmazingGrace"))
				  and not q(acard,"isKindOf","Peach") then
					card_id = q(acard,"getEffectiveId")
					break
				end
			end
		end
	end
	if not card_id then
	    return nil
	else
	    return parse(self,request,"#diy_k_meihun:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#diy_k_meihun"] = function(card,use,self,request)
    if q(self.player,"usedTimes","#diy_k_meihun") < 1 then
        sort_players(self,self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
		    if q(self,"objectiveLevel",enemy) > 0 then
			    use.card = card
			    if use.to then call(use.to,"append",enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value["diy_k_meihun"] = 8.5
sgs.ai_use_priority["diy_k_meihun"] = 9.5
sgs.ai_card_intention["diy_k_meihun"] = 80

sgs.ai_skill_cardask["@diy_k_huoxin"] = function(self,data,pattern,prompt)
	local current = call(self.room,"getCurrent")
	if current and not q(self,"isEnemy",current) then
		return true
	end
	return "."
end



  
sgs.ai_skill_invoke.diy_k_hengwu = true




addAiSkills("diy_k_shouli").getTurnUseCard=function(self,inclusive,request)
	
	local target
	if q(self.player,"getMark","diy_k_shouli-Self-Clear") == 0 and q(self.player,"canDiscard",self.player, "he") then
		target = self.player
	end
	if q(self.player,"getMark","diy_k_shouli-noSelf-Clear") == 0 then
		for _,p in sgs.list(q(self.room,"getOtherPlayers",self.player))do
			if q(self,"doDisCard",p, "he", true) then
				target = p
				break
			end
		end
	end
	if target then
		local dc=owner_eval(self,"diy_k_shouli","slash",{})
		local d = q(self,"aiUseCard",dc)
		if d.card and d.to
		and q(dc,"isAvailable",self.player)
		then
			remember_targets(self,"diy_k_shouli_to",d.to)
			call(self,"setPriorityValue","diy_k_shouli",q(self,"getPriorityValue","Slash")+0.6)
			return parse(self,request,"#diy_k_shouli:.:slash")
		end
	end
end

sgs.ai_skill_use_func["#diy_k_shouli"] = function(card,use,self,request)
	if recall_targets(self,"diy_k_shouli_to")
	then
		use.card = card
		use.to = recall_targets(self,"diy_k_shouli_to")
	end
end

sgs.ai_use_value.diy_k_shouli = 5.4
sgs.ai_use_priority.diy_k_shouli = 2.8


sgs.ai_card_priority.diy_k_shouli = function(self,card)
	if table.contains(q(card,"getSkillNames"), "diy_k_shouli")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_skill_playerchosen.diy_k_shouli = function(self, targets)
	targets = AIList.new(targets)
	for _, p in ipairs(targets) do
	    if q(self,"isEnemy",p) and q(self,"doDisCard",p, "he", true) then
		    return p
		end
	end
	for _, p in ipairs(targets) do
	    if q(self,"doDisCard",p, "he", true) then
		    return p
		end
	end
	return self.player
end

sgs.ai_guhuo_card.diy_k_shouli = function(self,toname,class_name)
	if class_name=="Slash" or class_name=="Jink" then
		if q(self.player,"getMark","diy_k_shouli-noSelf-Clear") == 0 then
			for _,p in sgs.list(q(self.room,"getOtherPlayers",self.player))do
				if q(self,"doDisCard",p, "he", true) then
					return {skill="diy_k_shouli",legacy_class="#diy_k_shouli",subcards={},user_string=toname}
				end
			end
		end
		if q(self.player,"getMark","diy_k_shouli-Self-Clear") == 0 then
			if q(self.player,"canDiscard",self.player, "he") then
				return {skill="diy_k_shouli",legacy_class="#diy_k_shouli",subcards={},user_string=toname}
			end
		end
	end
end


sgs.ai_card_priority.tc_zhitu = function(self,card,v)
	if q(self.player,"getMark","&tc_zhitu") % q(card,"getNumber") == 0 or q(card,"getNumber") % q(self.player,"getMark","&tc_zhitu") == 0
	then return 10 end
end


local tc_liuti_skill = {}
tc_liuti_skill.name = "tc_liuti"
table.insert(package_skills,tc_liuti_skill)
tc_liuti_skill.getTurnUseCard=function(self,inclusive,request)
	call(self,"setPriorityValue","tc_liutiCard",3)
	if q(self.player,"getCardCount",true)<2 then return false end
	if q(self,"getOverflow")<=0 then return false end
	if q(self,"isWeak") and q(self,"getOverflow")<=1 then return false end
	return parse(self,request,"#tc_liutiCard:.:")
end
sgs.ai_skill_use_func["#tc_liutiCard"] = function(card,use,self,request)
	local num = q(self.player,"getMark","&tc_zhitu")
	local unpreferedCards = {}
	local cards = AIList.new(q(self.player,"getHandcards"))
	sort_keep(self,cards)

	for _,c1 in ipairs(cards)do
		local temp = 0
		temp = temp + q(c1,"getNumber")
		for _,c in ipairs(cards)do
			if c1 ~= c then
				if not q(self.player,"isCardLimited",c,sgs.Card_MethodDiscard) and not q(self.player,"isCardLimited",c1,sgs.Card_MethodDiscard) then
					if table.contains(unpreferedCards,q(c,"getId")) then continue end
					if (((temp + q(c,"getNumber")) % num) == num) or (((temp + q(c,"getNumber")) % num) % num == 0 and temp + q(c,"getNumber") ~= num and (temp + q(c,"getNumber")) % num ~= 0) then
						temp = temp + q(c,"getNumber")
						table.insert(unpreferedCards,q(c,"getId"))
						table.insert(unpreferedCards,q(c1,"getId"))
						break
					end
					
				end
				if #unpreferedCards==2 then break end
			end
		end
		if #unpreferedCards==2 then break end
	end

	if #unpreferedCards==2 then
		use.card=final_parse(self,request,"#tc_liutiCard:"..table.concat(unpreferedCards,"+")..":")
		call(self,"setPriorityValue","tc_liutiCard",0)
		return
	end

end

sgs.ai_use_priority.tc_liutiCard = 3






  
local tc_shenfen_skill = {}
tc_shenfen_skill.name = "tc_shenfen"
table.insert(package_skills, tc_shenfen_skill)
tc_shenfen_skill.getTurnUseCard=function(self,inclusive,request)
	if (q(self.player,"getMark","@wrath") < 6 and q(self.player,"getMark","&wrath") < 6) or q(self.player,"hasUsed","#tc_shenfen") then return end
	return parse(self,request,"#tc_shenfen:.:")
end

sgs.ai_skill_use_func["#tc_shenfen"] = function(card,use,self,request)
	local card = parse(self,request,"@ShenfenCard=.")
	local dummy_use = dummy()
	call(self,"useSkillCard",card,dummy_use)
	if dummy_use.card then return parse(self,request,"#tc_shenfen:.:") end
end

sgs.ai_use_value["tc_shenfen"] = 8.7
sgs.ai_use_priority["tc_shenfen"] = 9.6
sgs.ai_card_intention["tc_shenfen"] = 66

sgs.ai_skill_invoke.tc_wumou = function(self, data)
	local use = q(data,"toCardUse")
	for _,to in sgs.list(use.to)do
		if q(self,"isFriend",to) then return false end
	end
	if q(self.player,"getMark","&wrath") < 6 then
		local dummy_use = dummy()
		local card = parse(self,request,"@ShenfenCard=.")
		call(self,"useSkillCard",card,dummy_use)
		if dummy_use.card then 
		 	return false 
		end
	end
	return true
end
sgs.ai_skill_invoke.tc_wumou_damage = function(self, data)
	local damage = q(data,"toDamage")
	local target = damage.to
	if not target then return end
	if q(self,"isFriend",target) then
		if q(self,"needToLoseHp",target,self.player) then return false end
		return false
	else
		if q(self,"isWeak",target) then return false end
		return q(self,"needToLoseHp",target,self.player)
	end
end



  
local tc_huashen_skill = {}
tc_huashen_skill.name = "tc_huashen"
table.insert(package_skills, tc_huashen_skill)
tc_huashen_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"usedTimes","#tc_huashen") >= 1 + q(self.player,"getMark","tc_huashen-Clear") then return end
	return parse(self,request,"#tc_huashen:.:")
end

sgs.ai_skill_use_func["#tc_huashen"] = function(card,use,self,request)
    if q(self.player,"usedTimes","#tc_huashen") < 1 + q(self.player,"getMark","tc_huashen-Clear") then
        use.card = card
	return end
end

sgs.ai_use_value["tc_huashen"] = 8.5
sgs.ai_use_priority["tc_huashen"] = 9.5
sgs.ai_card_intention["tc_huashen"] = -80

sgs.ai_skill_use["@@tc_huashen"] = function(self, prompt)
	return "#tc_huashen:.:"
end
sgs.ai_skill_choice["@tc_huashen"] = function(self, choices, data)
	return "yes"
end





  
local tc_huishi_skill = {}
tc_huishi_skill.name = "tc_huishi"
table.insert(package_skills, tc_huishi_skill)
tc_huishi_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"usedTimes","#tc_huishi") >= 1 then return end
	return parse(self,request,"#tc_huishi:.:")
end

sgs.ai_skill_use_func["#tc_huishi"] = function(card,use,self,request)
    if q(self.player,"usedTimes","#tc_huishi") < 1 then
        use.card = card
	    return
	end
end

sgs.ai_skill_invoke.tc_huishi = true

    
sgs.ai_skill_playerchosen.tc_huishi = function(self, targets)
    local targets = AIList.new(targets)
	sort_players(self,self.friends_noself)
	for _, p in ipairs(self.friends_noself) do 
		if q(self,"isFriend",p) and q(p,"getHandcardNum") < 3 and q(self.player,"getHandcardNum") >= q(self.player,"getMaxHp") and q(self,"canDraw",p, self.player) then
			return p
		end
	end
    return self.player
end
    
sgs.ai_skill_playerchosen["tc_huishizx"] = function(self, targets)
    local targets = AIList.new(targets)
	sort_players(self,self.friends_noself)
	for _, p in ipairs(self.friends_noself) do 
		if q(self,"isFriend",p) and q(p,"getState") == "online" then
			return p
		end
	end
    return nil 
end

sgs.ai_use_value["tc_huishi"] = 8.5
sgs.ai_use_priority["tc_huishi"] = 9.5
sgs.ai_card_intention["tc_huishi"] = -80


addAiSkills("tc_zuoxing").getTurnUseCard=function(self,inclusive,request)
	for _,name in sgs.list(patterns(self))do
		local poi=owner_eval(self,"tc_zuoxing",name,{})
		if poi==nil then continue end
		
		if q(poi,"isAvailable",self.player)
		and q(poi,"isNDTrick") and q(poi,"isDamageCard")
		then
			local dummy = q(self,"aiUseCard",poi)
			if dummy.card and dummy.to
			then
				remember_targets(self,"zx_to",dummy.to)
				call(self,"setPriorityValue","tc_zuoxing",q(self,"getPriorityValue",q(poi,"getClassName")))
				if q(poi,"canRecast") and q(dummy.to,"length")<1 then continue end
				return parse(self,request,"#tc_zuoxing:.:"..name)
			end
		end
	end
	for _,name in sgs.list(patterns(self))do
		local poi=owner_eval(self,"tc_zuoxing",name,{})
		if poi==nil then continue end
		
		if q(poi,"isAvailable",self.player)
		and q(poi,"isNDTrick")
		and name~="amazing_grace"
		and name~="collateral"
		then
			local dummy = q(self,"aiUseCard",poi)
			if dummy.card and dummy.to
			then
				remember_targets(self,"zx_to",dummy.to)
				call(self,"setPriorityValue","tc_zuoxing",q(self,"getPriorityValue",q(poi,"getClassName")))
				if q(poi,"canRecast") and q(dummy.to,"length")<1 then continue end
				return parse(self,request,"#tc_zuoxing:.:"..name)
			end
		end
	end
end

sgs.ai_skill_use_func["#tc_zuoxing"] = function(card,use,self,request)
	use.card = card
	use.to = recall_targets(self,"zx_to")
end

sgs.ai_use_value.tc_zuoxing = 8.4
sgs.ai_use_priority.tc_zuoxing = 8.4









addAiSkills("tc_dingzhou").getTurnUseCard=function(self,inclusive,request)
	return parse(self,request,"#tc_dingzhou:.:")
end

sgs.ai_skill_use_func["#tc_dingzhou"] = function(card,use,self,request)
	local target
	for _,friend in ipairs(self.friends_noself) do
		if q(self,"doDisCard",friend, "ej", true) and q(self.player,"getEquips"):length() + q(self.player,"getJudgingArea"):length() > 0 then
			target = friend
			break
		end
	end
	if target then
		use.card = card
		call(use.to,"append",target)
	end
end


  
sgs.ai_skill_playerchosen.tc_zhimeng = function(self, targets)
	targets = AIList.new(targets)
	for _, p in ipairs(targets) do
		if q(self,"isFriend",p) and q(self,"doDisCard",p, "he", true) then 
			return p
		end
	end
	for _, p in ipairs(targets) do
		if q(self,"isFriend",p) then 
			return p
		end
	end
	return nil
end











for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end
for key,source in pairs(sgs.ai_skill_use)do if ({['@@f_sandaoEXSlash']=true,['@@f_qiandu']=true,['@@f_yonghunSlash']=true,['@@f_jianyuangive']=true,['@@f_jianyuanthrow!']=true,['@@f_yifa!']=true,['@@f_shenjiangSBK!']=true,['@@tc_huashen']=true})[key]then
 sgs.ai_skill_use[key]=function(self,...)
  local wire=source(self,...);if wire==nil or wire=='.'then return wire end
  local cardwire,rawtargets=wire:match('^(.-)%-%>(.*)$');cardwire=cardwire or wire
  local use=AIUsePlan.new();use.card=final_parse(self,nil,cardwire)
  if rawtargets then for _,name in ipairs(rawtargets:split('+'))do use.to:append(known(self.room:findPlayerByObjectName(name),'response target'))end end
  return use:toAnswer()
 end
end end
