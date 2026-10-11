-- Fixed b6025acc package policy; all selection uses pure views and native-issued receipts.
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("package helper unavailable",method) end
    local values=table.pack(object[method](object,...))
    if AIUnsupported.is(values[1]) then error(values[1],0) end
    return table.unpack(values,1,values.n)
end
local function package_known(object,method,...)
    local values=table.pack(call(object,method,...))
    if values[1]==nil then ai_unsupported("package input is unknown",method) end
    return table.unpack(values,1,values.n)
end
local function visible_he(self,p)
 if p==self.player then return package_known(p,"getCards","he")end
 local cards,n=package_known(self,"getKnownCards",p,self.player,"he")
 if n<package_known(p,"getHandcardNum")then package_known(self,"useKnowledgeEstimate",{value=n,status="estimate",basis="kearmsxfyli.fenghun_visible_hand_only_selection",target=package_known(p,"objectName")},"kesxfenghun.hand")end
 return cards
end
local function ids(cards)local out={};for _,c in ipairs(cards)do out[#out+1]=package_known(c,"getEffectiveId")end;return out end
local function turn(self,skill,name,cards,request)
 local proto=package_known(self,"getEvaluationCard",name)
 return package_known(self,"evaluateTurnConversion",skill,package_known(proto,"getClassName"),{name=name,skill=skill,suit=sgs.Card_NoSuit,number=0,subcards=ids(cards)},request)
end
local function dummy(value,extra,current)local u=AIUsePlan.new();u.isDummy=value~=false;u.extra_target=extra or 0;u.current_targets=current or {};return u end
local function fact(self,key)
 local f=self.world and self.world.strategy_facts and self.world.strategy_facts.kearmsxfyli;local v=f and f[key]
 if v==nil then ai_unsupported("owner source fact unavailable","kearmsxfyli."..key)end;return v
end
local function player_fact(self,key)local n=fact(self,key);if n==false then return nil end;return package_known(self.room,"findPlayerByObjectName",n,true)end
local function use_fact(self,key)
 local d=fact(self,key);if d==false then return{to=AIList.new({})}end
 local u={card=d.card and CardView.new(d.card),from=d.from and package_known(self.room,"findPlayerByObjectName",d.from,true),to=AIList.new({})}
 for _,n in ipairs(d.to or{})do u.to:append(package_known(self.room,"findPlayerByObjectName",n,true))end;return u
end
local function pattern_names(self)
 local f=self.world and self.world.strategy_facts;local names=f and f.pattern_names;if not AIValue.isList(names)then ai_unsupported("ordered source patterns unavailable","pattern_names")end;return names
end
local function peiqi(self,data)
 local fn=sgs.ai_skill_invoke.peiqi;if type(fn)~="function"then ai_unsupported("source peiqi callback unavailable","kearmsxfyli.peiqi")end
 local value=fn(self,data);if AIUnsupported.is(value)then error(value,0)end
 if self.peiqiData then local d=self.peiqiData;call(self,"setStrategyMemory","kearmsxfyli.peiqi",{from=d.from and package_known(d.from,"objectName"),to=d.to and package_known(d.to,"objectName"),cid=d.cid})end;return value
end
local function peiqi_state(self)
 if self.peiqiData then return self.peiqiData end
 local d,known=call(self,"getStrategyMemory","kearmsxfyli.peiqi");if not known or type(d)~="table"then ai_unsupported("source peiqi state is unobserved","kearmsxfyli.peiqi")end
 return{from=d.from and package_known(self.room,"findPlayerByObjectName",d.from,true),to=d.to and package_known(self.room,"findPlayerByObjectName",d.to,true),cid=d.cid}
end
local function respond(self,skill,selector,costs,names,request)
 if request and type(request.getActivationSkillName)~="function"then request=AILegacyRequest.new(request,self.room)end
 local u=AIUsePlan.new();u.card=package_known(self,"bindSkillCard",skill,costs,request,nil,selector)
 for _,name in ipairs(names)do u.to:append(package_known(self.room,"findPlayerByObjectName",name))end;return package_known(u,"toAnswer")
end
local function selected(self,card,names)
 local c=card
 if package_known(card,"isEvaluationOnly")then
  local costs=package_known(card,"getSubcards");local skill=package_known(card,"getSkillName",false)
  c=package_known(self,"bindOriginalSelectedConversion",{name=package_known(card,"objectName"),skill=skill,suit=package_known(card,"getSuit"),number=package_known(card,"getNumber"),subcards=costs},package_known(card,"getClassName"),skill,card)
 end
 local u=AIUsePlan.new();u.card=c;for _,name in ipairs(names)do u.to:append(package_known(self.room,"findPlayerByObjectName",name))end;return package_known(u,"toAnswer")
end
local function save_plan(self,key,use)
 local c=use.card;local names={};for _,p in ipairs(use.to)do names[#names+1]=package_known(p,"objectName")end
 call(self,"setStrategyMemory","kearmsxfyli.plan."..key,{name=package_known(c,"objectName"),skill=package_known(c,"getSkillName",false),costs=package_known(c,"getSubcards"),targets=names})
end
local function load_plan(self,key)
 local d,known=call(self,"getStrategyMemory","kearmsxfyli.plan."..key)
 if not known or type(d)~="table"then ai_unsupported("source selected plan is unobserved","kearmsxfyli.plan."..key)end
 local u=AIUsePlan.new();u.card=package_known(self,"evaluateSkillCard",d.skill,d.name,d.costs)
 for _,name in ipairs(d.targets)do u.to:append(package_known(self.room,"findPlayerByObjectName",name))end;return u
end

sgs.ai_skill_askforyiji.kesxjimeng = function(self,card_ids,tos)
    local p,i = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if not p and package_known(self.player,"getPhase")~=sgs.Player_Start then
		p = package_known(tos,"at",0)
		i = card_ids[#card_ids]
	end
	return p,i
end

sgs.ai_skill_playerschosen.kesxhehe = function(self,players)
    local tos = {}
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p) and #tos<2 then table.insert(tos,p) end
	end
	for _,p in sgs.list(destlist)do
		if not package_known(self,"isEnemy",p) and #tos<2 and #self.enemies>0 and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_fill_skill.kesxquedi = function(self,inclusive,request)
    local cards = package_known(self.player,"getCards","he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if package_known(c,"isKindOf","Slash") then
			local can=turn(self,"kesxquedi","duel",{c},request)
			if package_known(can,"isAvailable",self.player) then
				return can
			end
		end
	end
end

sgs.ai_skill_playerchosen.kesxchunlao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"card")
	local count = fact(self,"kesxchunlaoToGetCount")
    if type(count)~="number" or count<0 or count%1~=0 then ai_unsupported("owner stored list count unavailable","kearmsxfyli.kesxchunlaoToGetCount") end
    -- Source caches toIntList once, then calls length at each reached comparison.
    local tag = {length=function() return count end}
    for _,target in sgs.list(destlist)do
		if package_known(self,"isFriend",target)
		and package_known(target,"getHandcardNum")<package_known(tag,"length")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if package_known(self,"isEnemy",target)
		and package_known(target,"getHandcardNum")>=package_known(tag,"length")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not package_known(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_skill_invoke.kesxchunlao = function(self,data)
	local srt = package_known(data,"toString"):split(":")
	local to = call(self.room,"findPlayerByObjectName",srt[2],true)
	if to then
		return package_known(self,"isFriend",to) or not package_known(self,"isEnemy",to) and #self.enemies>0
	end
end

sgs.ai_skill_playerschosen.kesxxiongsuan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) then table.insert(tos,p) end
	end
	call(self,"sort",destlist,nil,true)
    for _,p in sgs.list(destlist)do
		if #tos<2 and not table.contains(tos,p)
		and not package_known(self,"isFriend",p)
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<1 then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_fill_skill.kesxtiaohe = function(self,inclusive,request)
	return package_known(self,"evaluateTurnSkillCard","kesxtiaohe","#kesxtiaoheCard",{},request)
end

sgs.ai_skill_use_func["#kesxtiaoheCard"] = function(card,use,self,request)
	call(self,"sort",self.friends)
	for _,ep in sgs.list(self.friends)do do
		if package_known(use.to,"isEmpty") then
			local w = call(ep,"getWeapon")
			if w and package_known(self,"doDisCard",ep,package_known(w,"getEffectiveId")) then
				call(use.to,"append",ep)
			end
		else
			if package_known(use.to,"contains",ep) then goto package_continue_1 end
			local a = call(ep,"getArmor")
			if a and package_known(self,"doDisCard",ep,package_known(a,"getEffectiveId")) then
				call(use.to,"append",ep)
				use.card = card
				return
			end
		end
	end ::package_continue_1:: end
	for _,ep in sgs.list(self.friends)do do
		if package_known(use.to,"isEmpty") then
			local w = call(ep,"getWeapon")
			if w and package_known(self,"doDisCard",ep,package_known(w,"getEffectiveId")) then
				call(use.to,"append",ep)
			end
		else
			if package_known(use.to,"contains",ep) then goto package_continue_2 end
			local a = call(ep,"getArmor")
			if a and package_known(self,"doDisCard",ep,package_known(a,"getEffectiveId")) then
				call(use.to,"append",ep)
				use.card = card
				return
			end
		end
	end ::package_continue_2:: end
	call(self,"sort",self.enemies)
	for _,ep in sgs.list(self.enemies)do do
		if package_known(use.to,"isEmpty") then
			local w = call(ep,"getWeapon")
			if w and package_known(self,"doDisCard",ep,package_known(w,"getEffectiveId")) then
				call(use.to,"append",ep)
			end
		else
			if package_known(use.to,"contains",ep) then goto package_continue_3 end
			local a = call(ep,"getArmor")
			if a and package_known(self,"doDisCard",ep,package_known(a,"getEffectiveId")) then
				call(use.to,"append",ep)
				use.card = card
				return
			end
		end
	end ::package_continue_3:: end
	for _,ep in sgs.list(self.enemies)do do
		if package_known(use.to,"isEmpty") then
			local w = call(ep,"getWeapon")
			if w and package_known(self,"doDisCard",ep,package_known(w,"getEffectiveId")) then
				call(use.to,"append",ep)
			end
		else
			if package_known(use.to,"contains",ep) then goto package_continue_4 end
			local a = call(ep,"getArmor")
			if a and package_known(self,"doDisCard",ep,package_known(a,"getEffectiveId")) then
				call(use.to,"append",ep)
				use.card = card
				return
			end
		end
	end ::package_continue_4:: end
	for _,ep in sgs.list(package_known(self.room,"getAlivePlayers"))do do
		if package_known(self,"isFriend",ep) or package_known(use.to,"contains",ep) then goto package_continue_5 end
		if package_known(use.to,"isEmpty") then
			if call(ep,"getWeapon") then
				call(use.to,"append",ep)
			end
		else
			if call(ep,"getArmor") then
				call(use.to,"append",ep)
				use.card = card
				return
			end
		end
	end ::package_continue_5:: end
end

sgs.ai_use_value.kesxtiaoheCard = 7.4
sgs.ai_use_priority.kesxtiaoheCard = 6.2

sgs.ai_skill_invoke.kesxqiansu = function(self,data)
	return package_known(self,"canDraw")
end

sgs.ai_fill_skill.kesxbazhan = function(self,inclusive,request)
    local cards = package_known(self.player,"getCards","h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	call(self,"sort",self.enemies)
	for _,c in sgs.list(cards)do do
	   	if table.contains(self.toUse,c) then goto package_continue_6 end
		for _,ep in sgs.list(self.enemies)do
			if package_known(ep,"getStrategyMark","&kesxqiaoying-Clear") == package_known(ep,"getHandcardNum") and package_known(self.player,"inMyAttackRange",ep) then
				self.ht_to = ep
				return package_known(self,"evaluateTurnSkillCard","kesxbazhan","#kesxbazhanCard",{package_known(c,"getEffectiveId")},request)
			end
		end
	end ::package_continue_6:: end
	for _,c in sgs.list(cards)do do
	   	if table.contains(self.toUse,c) then goto package_continue_7 end
		for _,ep in sgs.list(self.enemies)do
			if package_known(ep,"getStrategyMark","&kesxqiaoying-Clear") == package_known(ep,"getHandcardNum") then
				self.ht_to = ep
				return package_known(self,"evaluateTurnSkillCard","kesxbazhan","#kesxbazhanCard",{package_known(c,"getEffectiveId")},request)
			end
		end
	end ::package_continue_7:: end
	for _,c in sgs.list(cards)do do
	   	if table.contains(self.toUse,c) then goto package_continue_8 end
		for _,ep in sgs.list(self.friends_noself)do
			if package_known(ep,"getStrategyMark","&kesxqiaoying-Clear") > package_known(ep,"getHandcardNum") then
				self.ht_to = ep
				return package_known(self,"evaluateTurnSkillCard","kesxbazhan","#kesxbazhanCard",{package_known(c,"getEffectiveId")},request)
			end
		end
	end ::package_continue_8:: end
	for _,c in sgs.list(cards)do do
	   	if table.contains(self.toUse,c) then goto package_continue_9 end
		for _,ep in sgs.list(self.friends_noself)do
			if package_known(ep,"getStrategyMark","&kesxqiaoying-Clear") <= package_known(ep,"getHandcardNum") then
				self.ht_to = ep
				return package_known(self,"evaluateTurnSkillCard","kesxbazhan","#kesxbazhanCard",{package_known(c,"getEffectiveId")},request)
			end
		end
	end ::package_continue_9:: end
end

sgs.ai_skill_use_func["#kesxbazhanCard"] = function(card,use,self,request)
	use.card = card
	call(use.to,"append",self.ht_to)
end

sgs.ai_use_value.kesxbazhanCard = 7.4
sgs.ai_use_priority.kesxbazhanCard = 2.2

sgs.ai_skill_invoke.kesxyibing = function(self,data)
	local target = call(data,"toPlayer")
	if target then
		if package_known(self,"isFriend",target) then return package_known(self,"doDisCard",target,"e",true)
		else return package_known(self,"doDisCard",target,"he",true) end
	end
end

ai_skill_use["@@kesxzhiyi"]=function(self,prompt,request)
	local dc=package_known(self,"evaluateSkillCard","_kesxzhiyi","slash",{})
    local dummy = package_known(self,"aiUseCard",dc)
   	if dummy.card and dummy.to then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,package_known(p,"objectName"))
       	end
       	return selected(self,dc,tos)
    end
end

sgs.ai_skill_playerchosen.kesxdaoshu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	local cp = call(self.room,"getCurrent")
	if package_known(self,"isEnemy",cp) then
		for _,p in sgs.list(destlist)do
			if package_known(self,"isEnemy",p)
			then return p end
		end
		for _,p in sgs.list(destlist)do
			if not package_known(self,"isFriend",p)
			then return p end
		end
	else
		for _,p in sgs.list(destlist)do
			if package_known(self,"isEnemy",p)
			and package_known(cp,"inMyAttackRange",p)
			and package_known(p,"getHandcardNum")<3
			then return p end
		end
	end
end


sgs.ai_skill_playerchosen.kesxfenghun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) then
			for _,e in sgs.list(package_known(p,"getCards","e"))do
				if package_known(e,"getSuit") == sgs.Card_Diamond and package_known(self,"doDisCard",p,package_known(e,"getEffectiveId")) then
					return p
				end
			end
			for _,e in sgs.list(package_known(p,"getCards","e"))do
				if package_known(e,"getSuit") == sgs.Card_Diamond then
					return p
				end
			end
		end
	end
	for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p) then
			for _,e in sgs.list(visible_he(self,p))do
				if package_known(e,"getSuit") == sgs.Card_Diamond and package_known(self,"doDisCard",p,package_known(e,"getEffectiveId")) then
					return p
				end
			end
			for _,e in sgs.list(visible_he(self,p))do
				if package_known(e,"getSuit") == sgs.Card_Diamond then
					return p
				end
			end
		end
	end
	for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and package_known(self,"doDisCard",p,"he") then
			return p
		end
	end
end


sgs.ai_skill_cardchosen.kesxfenghun = function(self,who,flags,method)
	if package_known(who,"objectName")==package_known(self.player,"objectName") then
		local cards = call(self,"sortByKeepValue",package_known(who,"getCards","he"))
		for _,e in sgs.list(cards)do
			if package_known(e,"getSuit") == sgs.Card_Diamond and package_known(self,"doDisCard",who,package_known(e,"getEffectiveId")) then
				return package_known(e,"getEffectiveId")
			end
		end
		for _,e in sgs.list(cards)do
			if package_known(e,"getSuit") == sgs.Card_Diamond then
				return package_known(e,"getEffectiveId")
			end
		end
	else
		for _,e in sgs.list(package_known(who,"getCards","e"))do
			if package_known(e,"getSuit") == sgs.Card_Diamond and package_known(self,"doDisCard",who,package_known(e,"getEffectiveId")) then
				return package_known(e,"getEffectiveId")
			end
		end
		for _,e in sgs.list(package_known(who,"getCards","e"))do
			if package_known(e,"getSuit") == sgs.Card_Diamond then
				return package_known(e,"getEffectiveId")
			end
		end
	end
end



sgs.ai_fill_skill.kesxxiongyi = function(self,inclusive,request)
	return package_known(self,"evaluateTurnSkillCard","kesxxiongyi","#kesxxiongyiCard",{},request)
end

sgs.ai_skill_use_func["#kesxxiongyiCard"] = function(card,use,self,request)
	call(self,"sort",self.friends,nil,true)
	for _,p in sgs.list(self.friends)do
		if getKnownCard(p,self.player,"Slash")>0 then
			for _,ep in sgs.list(self.enemies)do
				if package_known(p,"canSlash",ep) then
					call(use.to,"append",ep)
					if package_known(use.to,"length")>#self.friends/2 and package_known(self.room,"getTurnCount")>1 then
						use.card = card
					end
					break
				end
			end
		end
	end
end

sgs.ai_use_value.kesxxiongyiCard = 5.4
sgs.ai_use_priority.kesxxiongyiCard = 0.2
sgs.ai_card_intention.kesxxiongyiCard = -77




ai_skill_use["@@kesxyouqi"]=function(self,prompt,request)
	local valid = {}
	local destlist = package_known(self.room,"getAllPlayers")
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
    call(self,"sort",destlist)
	for _,p in sgs.list(destlist)do
    	if package_known(self,"isFriend",p) and package_known(p,"getKingdom") == "qun" then
			for _,e in sgs.list(package_known(self,"poisonCards","e",p))do
				if package_known(e,"isKindOf","Horse") then
					local n = package_known(e,"getEquipSlot")
					for _,q in sgs.list(destlist)do
						if package_known(self,"isEnemy",q)and package_known(q,"hasEquipArea",n) and not call(q,"getEquip",n) then
							call(self,"setStrategyMemory","kearmsxfyli.youqi",package_known(e,"getId"))
							table.insert(valid,package_known(p,"objectName"))
							table.insert(valid,package_known(q,"objectName"))
							return respond(self,"kesxyouqi","#kesxyouqiCard",{},valid,request)
						end
					end
					for _,q in sgs.list(destlist)do
						if not package_known(self,"isFriend",q)and package_known(q,"hasEquipArea",n) and not call(q,"getEquip",n) then
							call(self,"setStrategyMemory","kearmsxfyli.youqi",package_known(e,"getId"))
							table.insert(valid,package_known(p,"objectName"))
							table.insert(valid,package_known(q,"objectName"))
							return respond(self,"kesxyouqi","#kesxyouqiCard",{},valid,request)
						end
					end
				end
			end
		end
	end
	for _,p in sgs.list(destlist)do
    	if package_known(self,"isEnemy",p) and package_known(p,"getKingdom") == "qun" then
			for _,e in sgs.list(package_known(p,"getEquips"))do
				if package_known(e,"isKindOf","Horse") and #package_known(self,"poisonCards",{e},p)<1 then
					local n = package_known(e,"getEquipSlot")
					for _,q in sgs.list(destlist)do
						if package_known(self,"isFriend",q)and package_known(q,"hasEquipArea",n) and not call(q,"getEquip",n) then
							call(self,"setStrategyMemory","kearmsxfyli.youqi",package_known(e,"getId"))
							table.insert(valid,package_known(p,"objectName"))
							table.insert(valid,package_known(q,"objectName"))
							return respond(self,"kesxyouqi","#kesxyouqiCard",{},valid,request)
						end
					end
					for _,q in sgs.list(destlist)do
						if not package_known(self,"isEnemy",q)and package_known(q,"hasEquipArea",n) and not call(q,"getEquip",n) then
							call(self,"setStrategyMemory","kearmsxfyli.youqi",package_known(e,"getId"))
							table.insert(valid,package_known(p,"objectName"))
							table.insert(valid,package_known(q,"objectName"))
							return respond(self,"kesxyouqi","#kesxyouqiCard",{},valid,request)
						end
					end
				end
			end
		end
	end
	for _,p in sgs.list(destlist)do
    	if not package_known(self,"isFriend",p) and package_known(p,"getKingdom") == "qun" then
			for _,e in sgs.list(package_known(p,"getEquips"))do
				if package_known(e,"isKindOf","Horse") and #package_known(self,"poisonCards",{e},p)<1 then
					local n = package_known(e,"getEquipSlot")
					for _,q in sgs.list(destlist)do
						if package_known(self,"isFriend",q)and package_known(q,"hasEquipArea",n) and not call(q,"getEquip",n) then
							call(self,"setStrategyMemory","kearmsxfyli.youqi",package_known(e,"getId"))
							table.insert(valid,package_known(p,"objectName"))
							table.insert(valid,package_known(q,"objectName"))
							return respond(self,"kesxyouqi","#kesxyouqiCard",{},valid,request)
						end
					end
					for _,q in sgs.list(destlist)do
						if not package_known(self,"isEnemy",q) and package_known(q,"hasEquipArea",n) and not call(q,"getEquip",n) then
							call(self,"setStrategyMemory","kearmsxfyli.youqi",package_known(e,"getId"))
							table.insert(valid,package_known(p,"objectName"))
							table.insert(valid,package_known(q,"objectName"))
							return respond(self,"kesxyouqi","#kesxyouqiCard",{},valid,request)
						end
					end
				end
			end
		end
	end
end

sgs.ai_skill_cardchosen.kesxfenghun = function(self,who,flags,method)
	local id=call(self,"getStrategyMemory","kearmsxfyli.youqi");if id then
		return id
	end
end


sgs.ai_fill_skill.kesxmingfa = function(self,inclusive,request)
	return package_known(self,"evaluateTurnSkillCard","kesxmingfa","#kesxmingfaCard",{},request)
end

sgs.ai_skill_use_func["#kesxmingfaCard"] = function(card,use,self,request)
	call(self,"sort",self.enemies)
	for _,p in sgs.list(self.enemies)do
		if package_known(p,"getHp")>1 and package_known(self,"damageIsEffective",p,"N") then
			call(use.to,"append",p)
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.kesxmingfaCard = 5.4
sgs.ai_use_priority.kesxmingfaCard = 0.2
sgs.ai_card_intention.kesxmingfaCard = 77

sgs.ai_skill_playerschosen.kesxhuiji = function(self,players)
    local tos = {}
	local use = use_fact(self,"kesxhuijiUse")
	local d = package_known(self,"aiUseCard",use.card,dummy(true,1,use.to))
	if d.card then
		for _,p in sgs.list(players)do
			if package_known(d.to,"contains",p) and #tos<2
			then table.insert(tos,p) end
		end
	end
	return tos
end

sgs.ai_skill_invoke.kesxhuiji = function(self,data)
	for _,p in sgs.list(self.friends_noself)do
		if package_known(p,"getStrategyMark","&kesxhuiji-Clear")>0 and getCardsNum("Jink",p,self.player)>0 then
			return true
		end
	end
end

ai_skill_use["kesxhuiji-help"]=function(self,prompt,request)
	local prs = package_known(prompt,"split",":")
	for _,p in sgs.list(self.friends_noself)do
		if package_known(p,"objectName")==prs[2] then
			return package_known(self,"getCardId","Jink")
		end
	end
	return "."
end

sgs.ai_fill_skill.kesxxiongxia = function(self,inclusive,request)
    local cards = package_known(self.player,"getCards","he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,c1 in sgs.list(cards)do
		for _,c2 in sgs.list(cards)do do
			if AIValue.sameLegacyIdentity(c1,c2) then goto package_continue_10 end
			local dc=package_known(self,"evaluateSkillCard","kesxxiongxia","duel",{package_known(c1,"getId"),package_known(c2,"getId")})
			local d = package_known(self,"aiUseCard",dc,dummy(nil,1))
			if d.card and package_known(d.to,"length")==2 then
				local valid = {}
				table.insert(valid,package_known(c1,"getEffectiveId"))
				table.insert(valid,package_known(c2,"getEffectiveId"))
				self.kesxxiongxia_to = d.to
				return package_known(self,"evaluateTurnSkillCard","kesxxiongxia","#kesxxiongxiaCard",valid,request)
			end
		end ::package_continue_10:: end
	end
end

sgs.ai_skill_use_func["#kesxxiongxiaCard"] = function(card,use,self,request)
	if self.kesxxiongxia_to then
		use.card = card
		use.to = self.kesxxiongxia_to
	end
end

sgs.ai_use_value.kesxxiongxiaCard = 5.4
sgs.ai_use_priority.kesxxiongxiaCard = 2.2
sgs.ai_card_intention.kesxxiongxiaCard = 77


sgs.ai_skill_invoke.kesxjinjian = function(self,data)
	local str = package_known(data,"toString"):split(":")
	if str[1]=="kesxjinjian0" then
		local to = call(self.room,"findPlayerByObjectName",str[2],true)
		return package_known(self,"isFriend",to)
	else
		local to = call(self.room,"findPlayerByObjectName",str[2],true)
		return package_known(self,"isEnemy",to) or not package_known(self,"isFriend",to) and #self.enemies<1
	end
end








sgs.ai_fill_skill.sxwuyou = function(self,inclusive,request)
	return package_known(self,"evaluateTurnSkillCard","sxwuyou","#sxwuyouCard",{},request)
end

sgs.ai_skill_use_func["#sxwuyouCard"] = function(card,use,self,request)
	local dc = package_known(self,"getEvaluationCard","duel")
	for _,p in sgs.list(package_known(self,"aiUseCard",dc,dummy(nil,99)).to)do
		if package_known(self.player,"canPindian",p) then
			call(use.to,"append",p)
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.sxwuyouCard = 3.4
sgs.ai_use_priority.sxwuyouCard = 3.2
sgs.ai_card_intention.sxwuyouCard = 44

sgs.ai_fill_skill.sxbeiwu = function(self,inclusive,request)
    local cards = package_known(self.player,"getCards","e")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	local pts = {"ex_nihilo","duel"}
	for _,c in sgs.list(cards)do
		if package_known(self.player,"getStrategyMark",package_known(c,"getLegacyStringKey").."sxbeiwu-Clear")<1 then
			local dc=turn(self,"sxbeiwu",pts[math.random(1,2)],{c},request)
			if package_known(dc,"isAvailable",self.player) and package_known(self,"aiUseCard",dc).card then
				return dc
			end
		end
	end
end

sgs.ai_skill_invoke.sxchengshi = function(self,data)
	local target = call(data,"toPlayer")
	if target then
		return package_known(target,"getEquips"):length()-#package_known(self,"poisonCards","e",target)>package_known(self.player,"getEquips"):length()-#package_known(self,"poisonCards","e")
	end
end

sgs.ai_fill_skill.sxxiemuvs = function(self,inclusive,request)
    local cards = package_known(self.player,"getCards","h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if package_known(c,"getTypeId")==1 then
			return package_known(self,"evaluateTurnSkillCard","sxxiemuvs","#sxxiemuCard",{package_known(c,"getEffectiveId")},request)
		end
	end
end

sgs.ai_skill_use_func["#sxxiemuCard"] = function(card,use,self,request)
	call(self,"sort",self.enemies)
	local has = false
	for i,p in sgs.list(self.enemies)do
		if i<=#self.enemies/2 and package_known(self.player,"distanceTo",p)-package_known(self.player,"getAttackRange")==1 then
			has = true
			break
		end
	end
	for _,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
		if has and package_known(p,"hasSkill","sxxiemu") then
			use.card = card
			call(use.to,"append",p)
			break
		end
	end
end

sgs.ai_use_value.sxxiemuCard = 5.4
sgs.ai_use_priority.sxxiemuCard = 3.2
sgs.ai_card_intention.sxxiemuCard = -33

sgs.ai_fill_skill.sxnaman = function(self,inclusive,request)
	return package_known(self,"evaluateTurnSkillCard","sxnaman","#sxnamanCard",{},request)
end

sgs.ai_skill_use_func["#sxnamanCard"] = function(card,use,self,request)
    local cards = package_known(self.player,"getCards","h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	local bs = {}
	for _,c in sgs.list(cards)do
		if package_known(c,"getTypeId")==1 then
			table.insert(bs,package_known(c,"getId"))
		end
	end
	local dc = package_known(self,"getEvaluationCard","duel")
	for _,p in sgs.list(package_known(self,"aiUseCard",dc,dummy(nil,99)).to)do
		if package_known(use.to,"length")<#bs and package_known(self,"hasTrickEffective",package_known(self,"getEvaluationCard","savage_assault"),p) then
			call(use.to,"append",p)
		end
	end
	if package_known(use.to,"length")>0 then
		cards = {}
		for _,id in sgs.list(bs)do
			if #cards<package_known(use.to,"length") then
				table.insert(cards,id)
			end
		end
		use.card = package_known(self,"evaluateTurnSkillCard","sxnaman","#sxnamanCard",cards,request)
	end
end

sgs.ai_use_value.sxnamanCard = 3.4
sgs.ai_use_priority.sxnamanCard = 2.2
sgs.ai_card_intention.sxnamanCard = 66

sgs.ai_skill_playerchosen.sxjujian = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p) and package_known(self,"canDraw",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isEnemy",p) and #self.enemies>0
		then return p end
	end
end

sgs.ai_skill_playerchosen.sxxingfa = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and package_known(self,"damageIsEffective",p,"N")
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and #self.enemies<1
		then return p end
	end
end

sgs.ai_skill_invoke.sxshangjian = function(self,data)
	local ids = package_known(data,"toIntList")
	if package_known(self,"canDraw") then
		return true
	end
end

sgs.ai_skill_invoke.sxfunan = function(self,data)
	local effect = package_known(data,"toCardEffect")
	if package_known(self,"canDraw") then
		return true
	end
end

sgs.ai_skill_playerchosen.sxjiexun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p) and package_known(self,"canDraw",p)
		and package_known(self,"hasSuit","diamond",false,p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and #self.enemies>0
		then return p end
	end
end

sgs.ai_skill_discard.sxjiexun = function(self,x,n)
	local discard = {}
	for _,c in ipairs(call(self,"sortByKeepValue",package_known(self.player,"getHandcards")))do do
		if package_known(self.player,"isCardLimited",c,sgs.Card_MethodDiscard,true)
		or package_known(c,"getSuit")~=3 then goto package_continue_11 end
		table.insert(discard,package_known(c,"getEffectiveId"))
		if #discard>=n then return discard end
	end ::package_continue_11:: end
end

sgs.ai_skill_invoke.sxdingyi = function(self,data)
	if package_known(self,"canDraw") then
		return true
	end
end

sgs.ai_skill_playerchosen.sxzuici = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	local from = player_fact(self,"sxzuiciFrom")
	if package_known(self,"isFriend",from) then
		for _,p in sgs.list(destlist)do
			if not package_known(self,"isFriend",p) then return p end
		end
	else
		for _,p in sgs.list(destlist)do
			if package_known(self,"isFriend",p) and #package_known(self,"poisonCards","ej",p)>0
			then return p end
		end
	end
end


sgs.ai_fill_skill.sxyinge = function(self,inclusive,request)
	return package_known(self,"evaluateTurnSkillCard","sxyinge","#sxyingeCard",{},request)
end

sgs.ai_skill_use_func["#sxyingeCard"] = function(card,use,self,request)
	call(self,"sort",self.friends_noself,nil,true)
	for _,p in sgs.list(self.enemies)do
		if package_known(self.player,"inMyAttackRange",p) then
			for _,q in sgs.list(self.friends_noself)do
				if package_known(q,"getCardCount")>0 then
					call(use.to,"append",q)
					use.card = card
					return
				end
			end
		end
	end
	for _,p in sgs.list(self.friends_noself)do
		if package_known(self.player,"inMyAttackRange",p) and package_known(self,"isWeak",p) then
			return
		end
	end
	call(self,"sort",self.enemies)
	for _,q in sgs.list(self.enemies)do
		if package_known(q,"getCardCount")>0 then
			call(use.to,"append",q)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.sxyingeCard = 3.4
sgs.ai_use_priority.sxyingeCard = 4.2
--sgs.ai_card_intention.sxwuyouCard = 44

sgs.ai_skill_playerchosen.sxyinge = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and #self.enemies>0
		then return p end
	end
end

sgs.ai_skill_invoke.sxshiren = function(self,data)
	if package_known(self,"canDraw") then
		return true
	end
end

sgs.ai_skill_invoke.sxjuyi = function(self,data)
	local target = call(data,"toPlayer")
	if target then
		return package_known(self,"isFriend",target)
	end
end

sgs.ai_skill_invoke.sxzishou = function(self,data)
	if package_known(self,"canDraw") then
		return #self.enemies<1 or package_known(self,"getOverflow")<0
	end
end

sgs.ai_skill_discard.sxjujing = function(self,x,n)
	local discard = {}
	for _,c in ipairs(call(self,"sortByKeepValue",package_known(self.player,"getCards","he")))do do
		if package_known(self.player,"isCardLimited",c,sgs.Card_MethodDiscard,true) then goto package_continue_12 end
		table.insert(discard,package_known(c,"getEffectiveId"))
		if #discard>=n and (package_known(self,"isWeak") or #package_known(self,"poisonCards","he")>0)
		then return discard end
	end ::package_continue_12:: end
end

sgs.ai_skill_invoke.sxfengbai = function(self,data)
	local target = call(data,"toPlayer")
	if target and package_known(self,"canDraw",target) then
		return package_known(self,"isFriend",target)
	end
end

sgs.ai_skill_discard.sxhuaiyi = function(self,x,n)
	local cs = {}
	for _,c in ipairs(call(self,"sortByKeepValue",package_known(self.player,"getCards","h")))do do
		if package_known(self.player,"isCardLimited",c,sgs.Card_MethodDiscard,true) then goto package_continue_13 end
		cs[package_known(c,"getColorString")] = (cs[package_known(c,"getColorString")] or 0)+1
	end ::package_continue_13:: end
	local x = 99
	for k,n in pairs(cs)do
		if n<x then x = n end
	end
	for k,n in pairs(cs)do
		if n<=x then
			for _,c in ipairs(call(self,"sortByKeepValue",package_known(self.player,"getCards","h")))do do
				if package_known(self.player,"isCardLimited",c,sgs.Card_MethodDiscard,true)
				or package_known(c,"getColorString")~=k then goto package_continue_14 end
				return {package_known(c,"getEffectiveId")}
			end ::package_continue_14:: end
		end
	end
end

sgs.ai_skill_playerschosen.sxhuaiyi = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if package_known(self,"doDisCard",p,"he",true) and #tos<x then
			table.insert(tos,p)
			if package_known(self,"isWeak") then
				break
			end
		end
	end
	return tos
end

sgs.ai_skill_cardask["sxzhuikong0"] = function(self,data,pattern)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	local target = call(data,"toPlayer")
   	for _,c in sgs.list(cards)do
    	if package_known(c,"isKindOf","Slash") and package_known(c,"getNumber")>9
		and package_known(self,"isEnemy",target)
		then return package_known(c,"getEffectiveId") end
	end
    return "."
end

ai_skill_use["@@sxzhuikong"]=function(self,prompt,request)
    for _,id in sgs.list(package_known(self,"getNotifiedTag","sxzhuikongForAI"))do do
      	local c = package_known(self,"getKnownCardById",tonumber(id))
		if package_known(c,"isAvailable",self.player) then
			local dummy = package_known(self,"aiUseCard",c)
			if dummy.card then
				local tos = {}
				for _,p in sgs.list(dummy.to)do
					table.insert(tos,package_known(p,"objectName"))
				end
				if package_known(c,"canRecast") and #tos<1 then goto package_continue_15 end
				return selected(self,c,tos)
			end
		end
	end ::package_continue_15:: end
end

sgs.ai_skill_playerchosen.sxqiuyuan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and #self.enemies>0
		then return p end
	end
end

sgs.ai_skill_discard.sxqiuyuan = function(self,x,n)
	local use = use_fact(self,"sxqiuyuanUse")
	for _,c in ipairs(call(self,"sortByKeepValue",package_known(self.player,"getCards","he")))do
		if package_known(self,"slashIsEffective",use.card,self.player,use.from)
		and (package_known(self,"isWeak") or package_known(self,"getCardsNum","Jink")<1)
		then return {package_known(c,"getId")} end
	end
end

sgs.ai_skill_invoke.sxwudu = function(self,data)
	local target = call(data,"toPlayer")
	if target and package_known(self,"isWeak",target) then
		return package_known(self,"isFriend",target)
	end
end

sgs.ai_fill_skill.sxgushe = function(self,inclusive,request)
	local mc = call(self,"getMaxCard")
	return mc and package_known(mc,"getNumber")>9
	and package_known(self,"evaluateTurnSkillCard","sxgushe","#sxgusheCard",{},request)
end

sgs.ai_skill_use_func["#sxgusheCard"] = function(card,use,self,request)
	call(self,"sort",self.enemies)
	for _,p in sgs.list(self.enemies)do
		if package_known(self.player,"canPindian",p) then
			call(use.to,"append",p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.sxgusheCard = 3.4
sgs.ai_use_priority.sxgusheCard = 4.2
sgs.ai_card_intention.sxgusheCard = 44

sgs.ai_skill_invoke.sxgushe = function(self,data)
	local target = call(data,"toPlayer")
	if target and package_known(self,"isEnemy",target) and package_known(self,"canDraw") then
		local mc = call(self,"getMaxCard")
		return mc and package_known(mc,"getNumber")>6
	end
end

sgs.ai_skill_invoke.sxjici = function(self,data)
	local pindian = package_known(data,"toPindian")
	if pindian.to==self.player then
		return package_known(self,"isEnemy",pindian.from) and not package_known(self,"isWeak")
		and pindian.from_number>pindian.to_number
		and pindian.to_number<13
	else
		return package_known(self,"isEnemy",pindian.to) and not package_known(self,"isWeak")
		and pindian.to_number>=pindian.from_number
		and pindian.from_number<13
		and pindian.to_number<13
	end
end

sgs.ai_skill_invoke.sxyuanqing = function(self,data)
	if package_known(self,"canDraw") then
		return true
	end
end

function sgs.ai_cardsview.sxshuchen(self,class_name,player)
   	local cards = sgs.QList2Table(package_known(player,"getCards","h"))
    call(self,"sortByKeepValue",cards)
	for _,card in sgs.list(cards)do
		return {name="peach",skill="sxshuchen",suit=sgs.Card_NoSuit,number=0,subcards={package_known(card,"getEffectiveId")}}
	end
end

sgs.ai_skill_discard.sxjinglve = function(self,x,n)
	local discard = {}
	local cp = call(self.room,"getCurrent")
	for _,c in ipairs(call(self,"sortByKeepValue",package_known(self.player,"getCards","he")))do
		table.insert(discard,package_known(c,"getEffectiveId"))
		if #discard>=n and package_known(self.player,"getCardCount")>2
		and package_known(self,"getOverflow",cp)>0 and package_known(self,"isEnemy",cp)
		then return discard end
	end
end

sgs.ai_skill_invoke.sxjinglve = function(self,data)
	if package_known(self,"canDraw") then
		return true
	end
end

sgs.ai_fill_skill.sxchengji = function(self,inclusive,request)
   	local cards = sgs.QList2Table(package_known(self.player,"getCards","he"))
    call(self,"sortByKeepValue",cards)
	for _,c1 in sgs.list(cards)do
		local dc
		for _,c2 in sgs.list(cards)do
			if package_known(c1,"getColor")~=package_known(c2,"getColor") then
				return turn(self,"sxchengji","slash",{c1,c2},request)
			end
		end
	end
end

function sgs.ai_cardsview.sxchengji(self,class_name,player)
   	local cards = sgs.QList2Table(package_known(player,"getCards","he"))
    call(self,"sortByKeepValue",cards)
	for _,c1 in sgs.list(cards)do
		local dc
		for _,c2 in sgs.list(cards)do
			if package_known(c1,"getColor")~=package_known(c2,"getColor") then
				return {name="slash",skill="sxchengji",suit=sgs.Card_NoSuit,number=0,subcards={package_known(c1,"getId"),package_known(c2,"getId")}}
			end
		end
	end
end

ai_skill_use["@@sxzhengnan"]=function(self,prompt,request)
	for _,c in ipairs(call(self,"sortByKeepValue",package_known(self.player,"getCards","h")))do do
      	local dc=package_known(self,"evaluateSkillCard","sxzhengnan","slash",{package_known(c,"getId")})
		if package_known(c,"isRed") and package_known(dc,"isAvailable",self.player) then
			local dummy = package_known(self,"aiUseCard",dc)
			if dummy.card then
				local tos = {}
				for _,p in sgs.list(dummy.to)do
					table.insert(tos,package_known(p,"objectName"))
				end
				if package_known(dc,"canRecast") and #tos<1 then goto package_continue_16 end
				return selected(self,dc,tos)
			end
		end
	end ::package_continue_16:: end
end

sgs.ai_fill_skill.sxzhanjue = function(self,inclusive,request)
   	local ids = sgs.QList2Table(package_known(self.player,"handCards"))
	return package_known(self,"evaluateTurnSkillCard","sxzhanjue","#sxzhanjueCard",ids,request)
end

sgs.ai_skill_use_func["#sxzhanjueCard"] = function(card,use,self,request)
	local dc=package_known(self,"evaluateSkillCard","sxzhanjue","duel",ids(package_known(self.player,"getCards","h")))
	if package_known(dc,"isAvailable",self.player) then
		local d = package_known(self,"aiUseCard",dc)
		for _,p in sgs.list(d.to)do
			if package_known(p,"getHandcardNum")<package_known(self.player,"getHandcardNum")
			or getCardsNum("Slash",p,self.player)<1 then
				call(use.to,"append",p)
				use.card = card
			end
		end
	end
end

sgs.ai_use_value.sxzhanjueCard = 3.4
sgs.ai_use_priority.sxzhanjueCard = -1.2
sgs.ai_card_intention.sxzhanjueCard = 66

sgs.ai_skill_invoke.sxqinwang = function(self,data)
	if #self.friends_noself>0 then
		return true
	end
end

sgs.ai_skill_cardask["sxzhengnan0"] = function(self,data,pattern)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	local target = call(data,"toPlayer")
   	for _,c in sgs.list(cards)do
    	if package_known(c,"getTypeId")==1 and getCardsNum("Slash",target,self.player)<1
		and package_known(self,"isFriend",target) and package_known(self,"isWeak",target)
		then return package_known(c,"getEffectiveId") end
	end
    return "."
end

sgs.ai_skill_invoke.sxhuituo = function(self,data)
	if package_known(self,"canDraw") then
		return true
	end
end

ai_skill_use["@@sxhuituo"]=function(self,prompt,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	local ids = {}
    for _,id in sgs.list(package_known(self,"getNotifiedTag","sxhuituoForAI"))do
      	local c = package_known(self,"getKnownCardById",tonumber(id))
		for _,h in sgs.list(cards)do do
			if table.contains(ids,package_known(h,"getId")) then goto package_continue_17 end
			if package_known(self,"getKeepValue",c)>package_known(self,"getKeepValue",h) then
				table.insert(ids,package_known(h,"getId"))
				table.insert(ids,id)
				break
			end
		end ::package_continue_17:: end
	end
	if #ids>1 then
		return respond(self,"sxhuituo","#sxhuituoCard",ids,{},request)
	end
end

sgs.ai_fill_skill.sxmingjian = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
    call(self,"sortByUseValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do do
		if not package_known(c,"isDamageCard") then goto package_continue_18 end
		for _,p in sgs.list(self.friends_noself)do
			if package_known(c,"isAvailable",p) then
				self.sxmingjianTo = p
				return package_known(self,"evaluateTurnSkillCard","sxmingjian","#sxmingjianCard",{package_known(c,"getEffectiveId")},request)
			end
		end
	end ::package_continue_18:: end
	for _,c in sgs.list(cards)do
		for _,p in sgs.list(self.friends_noself)do
			if package_known(c,"isAvailable",p) then
				self.sxmingjianTo = p
				return package_known(self,"evaluateTurnSkillCard","sxmingjian","#sxmingjianCard",{package_known(c,"getEffectiveId")},request)
			end
		end
	end
end

sgs.ai_skill_use_func["#sxmingjianCard"] = function(card,use,self,request)
	if self.sxmingjianTo then
		call(use.to,"append",self.sxmingjianTo)
		use.card = card
	end
end

sgs.ai_use_value.sxmingjianCard = 3.4
sgs.ai_use_priority.sxmingjianCard = -1.2
sgs.ai_card_intention.sxmingjianCard = -66

sgs.ai_skill_playerchosen.sxbaobian = function(self,players)
	if package_known(self,"isWeak") then return end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and #self.enemies>0
		then return p end
	end
end

sgs.ai_skill_choice.sxzaoli = function(self,choices)
	local items = package_known(choices,"split","+")
	if table.contains(items,"sxzaoli1")
	and package_known(self.player,"getHandcardNum")/2<=package_known(self.player,"getEquips"):length()
	then return "sxzaoli1" end
end

sgs.ai_skill_invoke.sxfenyin = function(self,data)
	if package_known(self,"canDraw") then
		return not package_known(self.player,"isSkipped",sgs.Player_Play)
	end
end

sgs.ai_used_revises.sxfenyin = function(self,use)
	if package_known(self.player,"getStrategyMark","sxfenyinUse-Clear")>0 and #self.toUse>1
	and package_known(self.player,"getStrategyMark","&sxfenyin+:+"..package_known(use.card,"getColorString").."-Clear")>0 then
		use.card = nil
	end
end

sgs.ai_skill_playerchosen.sxshuangren = function(self,players)
	local mc = call(self,"getMaxCard")
	if mc and package_known(mc,"getNumber")>9 or package_known(self,"getCardsNum","Slash")<1
	then else return end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) then
			for _,q in sgs.list(self.enemies)do
				if package_known(p,"distanceTo",q)==1 and package_known(self.player,"canSlash",q,false) then
					return p
				end
			end
		end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) then
			for _,q in sgs.list(self.enemies)do
				if package_known(p,"distanceTo",q)==1 and package_known(self.player,"canSlash",q,false) then
					return p
				end
			end
		end
	end
end

sgs.ai_skill_playerschosen.sxshuangren = function(self,players)
	local tos = {}
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if #tos<2 and package_known(self,"isEnemy",p) and package_known(self,"slashIsEffective",package_known(self,"getEvaluationCard","slash"),p) then
			table.insert(tos,p)
		end
	end
    for _,p in sgs.list(destlist)do
		if #tos<2 and not table.contains(tos,p)
		and not package_known(self,"isFriend",p) and package_known(self,"slashIsEffective",package_known(self,"getEvaluationCard","slash"),p) then
			table.insert(tos,p)
		end
	end
	return tos
end

sgs.ai_fill_skill.sxmieji = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
    call(self,"sortByUseValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if package_known(c,"getTypeId")==2 and package_known(c,"isBlack") then
			return package_known(self,"evaluateTurnSkillCard","sxmieji","#sxmiejiCard",{package_known(c,"getEffectiveId")},request)
		end
	end
end

sgs.ai_skill_use_func["#sxmiejiCard"] = function(card,use,self,request)
	call(self,"sort",self.enemies)
	for _,p in sgs.list(self.enemies)do
		if package_known(self,"doDisCard",p,"he",false,2) then
			call(use.to,"append",p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.sxmiejiCard = 3.4
sgs.ai_use_priority.sxmiejiCard = 2.2
sgs.ai_card_intention.sxmiejiCard = 66

sgs.ai_skill_playerchosen.sxjuece = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and package_known(self,"damageIsEffective",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and #self.enemies<1
		and package_known(self,"damageIsEffective",p)
		then return p end
	end
end

sgs.ai_fill_skill.sxlianji = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
    call(self,"sortByUseValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if package_known(c,"getTypeId")==3 then
			local dc=turn(self,"sxlianji","collateral",{c},request)
			if package_known(dc,"isAvailable",self.player) then
				return dc
			end
		end
	end
end

sgs.ai_skill_invoke.sxzongji = function(self,data)
	local damage = package_known(data,"toDamage")
	return package_known(self,"doDisCard",damage.to,"he") or package_known(self,"doDisCard",damage.from,"he")
end

sgs.ai_skill_playerchosen.sxyirang = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p) and package_known(self,"canDraw",p)
		and sgs.getDefense(p)<sgs.getDefense(self.player)
		then return p end
	end
end

sgs.ai_fill_skill.sxjiaozhao = function(self,inclusive,request)
	return package_known(self,"evaluateTurnSkillCard","sxjiaozhao","#sxjiaozhaoCard",{},request)
end

sgs.ai_skill_use_func["#sxjiaozhaoCard"] = function(card,use,self,request)
	call(self,"sort",self.enemies,nil,true)
	for _,p in sgs.list(self.enemies)do
		if package_known(p,"getHandcardNum")>1 then
			call(use.to,"append",p)
			use.card = card
			return
		end
	end
	for _,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
		if package_known(p,"getHandcardNum")>1 and not package_known(self,"isFriend",p) then
			call(use.to,"append",p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.sxjiaozhaoCard = 3.4
sgs.ai_use_priority.sxjiaozhaoCard = 7.2
sgs.ai_card_intention.sxjiaozhaoCard = 66

sgs.ai_skill_discard.sxjiaozhao1 = function(self,x,n)
	for _,c in ipairs(call(self,"sortByKeepValue",package_known(self.player,"getCards","he")))do
		return {package_known(c,"getEffectiveId")}
	end
end

ai_skill_use["@@sxjiaozhao"]=function(self,prompt,request)
	call(self,"sort",self.enemies,nil,true)
	for _,p in sgs.list(self.enemies)do
		if package_known(p,"getHandcardNum")>1 then
			return respond(self,"sxjiaozhao","#sxjiaozhaoCard",{},{package_known(p,"objectName")},request)
		end
	end
	for _,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
		if package_known(p,"getHandcardNum")>1 and not package_known(self,"isFriend",p) then
			return respond(self,"sxjiaozhao","#sxjiaozhaoCard",{},{package_known(p,"objectName")},request)
		end
	end
end

sgs.ai_skill_invoke.sxpolu = function(self,data)
	local to = call(data,"toPlayer")
	return package_known(self,"doDisCard",to,"e")
end

sgs.ai_fill_skill.sxchoulve = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
    call(self,"sortByUseValue",cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		local c,p = call(self,"getCardNeedPlayer",{h},false)
		if c and p then
			self.sxchoulveTo = p
			return package_known(self,"evaluateTurnSkillCard","sxchoulve","#sxchoulveCard",{package_known(c,"getEffectiveId")},request)
		end
	end
end

sgs.ai_skill_use_func["#sxchoulveCard"] = function(card,use,self,request)
	if self.sxchoulveTo then
		call(use.to,"append",self.sxchoulveTo)
		use.card = card
	end
end

sgs.ai_use_value.sxchoulveCard = 3.4
sgs.ai_use_priority.sxchoulveCard = 2.2
sgs.ai_card_intention.sxchoulveCard = -66

sgs.ai_skill_discard.sxchoulve = function(self,x,n)
	local cp = call(self.room,"getCurrent")
	for _,c in ipairs(call(self,"sortByKeepValue",package_known(self.player,"getCards","he")))do
		if package_known(c,"getTypeId")==3 and package_known(self,"isFriend",cp) then return {package_known(c,"getId")} end
	end
end

sgs.ai_fill_skill.sxfenxun = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
    call(self,"sortByUseValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if package_known(c,"isKindOf","Armor") then
			return package_known(self,"evaluateTurnSkillCard","sxfenxun","#sxfenxunCard",{package_known(c,"getEffectiveId")},request)
		end
	end
end

sgs.ai_skill_use_func["#sxfenxunCard"] = function(card,use,self,request)
	call(self,"sort",self.enemies)
	for _,p in sgs.list(self.enemies)do
		if package_known(self,"isWeak",p) and not package_known(self.player,"inMyAttackRange",p)
		and package_known(self,"getCardsNum","Slash")>0 and package_known(self,"getEvaluationCard","slash"):isAvailable(self.player)
		and package_known(self,"slashIsEffective",package_known(self,"getEvaluationCard","slash"),p,self.player) then
			call(use.to,"append",p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.sxfenxunCard = 3.4
sgs.ai_use_priority.sxfenxunCard = 2.2
sgs.ai_card_intention.sxfenxunCard = 66

sgs.ai_skill_playerchosen.sxzenhui = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isEnemy",p)
		and sgs.getDefense(p)>sgs.getDefense(self.player)
		then return p end
	end
end

sgs.ai_skill_invoke.sxchuyi = function(self,data)
	local to = call(data,"toPlayer")
	return package_known(self,"isEnemy",to)
end

sgs.ai_skill_playerchosen.sxzhaoxin = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and package_known(self,"damageIsEffective",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and #self.enemies<1
		and package_known(self,"damageIsEffective",p)
		then return p end
	end
end


sgs.ai_fill_skill.sxxianlu = function(self,inclusive,request)
	return package_known(self,"evaluateTurnSkillCard","sxxianlu","#sxxianluCard",{},request)
end

sgs.ai_skill_use_func["#sxxianluCard"] = function(card,use,self,request)
	if package_known(self.player,"containsTrick","indulgence") then
		call(self,"sort",self.enemies)
		for _,p in sgs.list(self.enemies)do
			if package_known(self,"doDisCard",p,"e") then
				call(use.to,"append",p)
				use.card = card
				return
			end
		end
		for _,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
			if package_known(self,"doDisCard",p,"e") then
				call(use.to,"append",p)
				use.card = card
				return
			end
		end
	else
		call(self,"sort",self.enemies)
		for _,p in sgs.list(self.enemies)do
			if package_known(self,"doDisCard",p,"e") then
				call(use.to,"append",p)
				use.card = card
				return
			end
		end
		for _,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
			for _,e in sgs.list(package_known(p,"getEquips"))do
				if package_known(e,"isBlack") and package_known(self,"doDisCard",p,package_known(e,"getId")) then
					call(use.to,"append",p)
					use.card = card
					return
				end
			end
		end
		for _,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
			if package_known(self,"doDisCard",p,"e") and not package_known(self,"isFriend",p) then
				call(use.to,"append",p)
				use.card = card
				return
			end
		end
	end
end

sgs.ai_use_value.sxxianluCard = 3.4
sgs.ai_use_priority.sxxianluCard = 7.2
sgs.ai_card_intention.sxxianluCard = 66

sgs.ai_skill_playerchosen.sxcansi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and (package_known(self,"slashIsEffective",package_known(self,"getEvaluationCard","slash"),p,self.player) or package_known(self,"hasTrickEffective",package_known(self,"getEvaluationCard","duel"),p))
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p)
		then return p end
	end
end

sgs.ai_fill_skill.sxmingshi = function(self,inclusive,request)
	return package_known(self,"evaluateTurnSkillCard","sxmingshi","#sxmingshiCard",{},request)
end

sgs.ai_skill_use_func["#sxmingshiCard"] = function(card,use,self,request)
	if #self.enemies>0 then
		use.card = card
	end
end

sgs.ai_use_value.sxmingshiCard = 3.4
sgs.ai_use_priority.sxmingshiCard = 7.2

sgs.ai_skill_choice.sxmingshi = function(self,choices,data)
	local items = package_known(choices,"split","+")
	if table.contains(items,"sxmingshi2") and package_known(self,"isWeak")
	then return "sxmingshi2" end
	if table.contains(items,"sxmingshi3") then
		for _,p in sgs.list(self.enemies)do
			if package_known(self,"isWeak",p) and package_known(self,"damageIsEffective",p) then
				return "sxmingshi3"
			end
		end
	end
	if table.contains(items,"sxmingshi1") and package_known(self,"canDraw") and package_known(self,"getOverflow")<1
	then return "sxmingshi1" end
	if table.contains(items,"sxmingshi4") and peiqi(self,data)
	then return "sxmingshi4" end
	if table.contains(items,"sxmingshi1")
	then return "sxmingshi1" end
end

sgs.ai_skill_playerchosen.sxmingshi3 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and package_known(self,"damageIsEffective",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and #self.enemies<1
		and package_known(self,"damageIsEffective",p)
		then return p end
	end
end

sgs.ai_skill_playerchosen["sxmingshi_from"] = function(self,players)
	for _,target in sgs.list(players)do
		if target==peiqi_state(self).from
		then return target end
	end
end

sgs.ai_skill_playerchosen["sxmingshi_to"] = function(self,players)
	for _,target in sgs.list(players)do
		if target==peiqi_state(self).to
		then return target end
	end
end

sgs.ai_skill_cardchosen.sxmingshi = function(self,who,flags,method)
	for _,e in sgs.list(package_known(who,"getCards",flags))do
		local id = package_known(e,"getEffectiveId")
		if id==peiqi_state(self).cid
		then return id end
	end
end

sgs.ai_skill_playerchosen.sxyizheng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and package_known(self.player,"canPindian",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and #self.enemies<1
		and package_known(self.player,"canPindian",p)
		then return p end
	end
end

sgs.ai_skill_playerchosen["sxrangjie"] = function(self,players)
	if peiqi(self) then
		for _,target in sgs.list(players)do
			if target==peiqi_state(self).from
			then return target end
		end
	end
end

sgs.ai_skill_playerchosen["sxrangjie1"] = function(self,players)
	for _,target in sgs.list(players)do
		if target==peiqi_state(self).to
		then return target end
	end
end

sgs.ai_skill_cardchosen.sxrangjie = function(self,who,flags,method)
	for _,e in sgs.list(package_known(who,"getCards",flags))do
		local id = package_known(e,"getEffectiveId")
		if id==peiqi_state(self).cid
		then return id end
	end
end

sgs.ai_fill_skill.sxzhitu = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do do
		if table.contains(self.toUse,c) then goto package_continue_19 end
		for _,a in sgs.list(cards)do do
			if AIValue.sameLegacyIdentity(c,a) or table.contains(self.toUse,a) then goto package_continue_20 end
			if package_known(c,"getNumber")+package_known(a,"getNumber")==13 then
				for _,cn in sgs.list(pattern_names(self))do
					local dc=package_known(self,"evaluateSkillCard","sxzhitu",cn,{})
					if dc and package_known(dc,"isNDTrick") then
						dc=turn(self,"sxzhitu",cn,{c,a},request)
						if package_known(dc,"isAvailable",self.player) and package_known(self,"aiUseCard",dc).card
						then return dc end
					end
				end
			end
		end ::package_continue_20:: end
	end ::package_continue_19:: end
end

function sgs.ai_cardsview.sxzhitu(self,class_name,player)
	local cards = package_known(player,"getCards","he")
	cards = sgs.QList2Table(cards)
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		for _,a in sgs.list(cards)do do
			if AIValue.sameLegacyIdentity(c,a) then goto package_continue_21 end
			if package_known(c,"getNumber")+package_known(a,"getNumber")==13 then
				local dc=call(self,"createCardsViewSourceCard","sxzhitu",class_name,
                    {package_known(c,"getId"),package_known(a,"getId")})
				if dc then return dc end
			end
		end ::package_continue_21:: end
	end
end

sgs.ai_skill_askforyiji.sxyimou = function(self,card_ids,tos)
    return sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
end

sgs.ai_skill_playerchosen.sxmutao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p) and package_known(self,"damageIsEffective",p)
		and getCardsNum("Slash",p,self.player)>0
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and #self.enemies<1
		and package_known(self,"damageIsEffective",p)
		and getCardsNum("Slash",p,self.player)>0
		then return p end
	end
    for _,p in sgs.list(sgs.reverse(destlist))do
		if package_known(self,"isEnemy",p) and package_known(self,"damageIsEffective",p)
		then return p end
	end
    for _,p in sgs.list(sgs.reverse(destlist))do
		if package_known(self,"isEnemy",p) then return p end
	end
end

sgs.ai_skill_askforyiji.sxtaoluan = function(self,card_ids,tos)
    if package_known(self,"isEnemy",package_known(tos,"last")) and getCardsNum("Jink",package_known(tos,"last"),self.player)>0 then
		local cards = package_known(self.player,"getCards","he")
		cards = sgs.QList2Table(cards)
		call(self,"sortByKeepValue",cards) -- 按保留值排序
		return package_known(tos,"last"),cards[1]:getId()
	end
end

sgs.ai_skill_cardask["sxtaoluan0"] = function(self,data,pattern)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	local tp = call(self.room,"getCurrent")
   	if #cards>0 and package_known(self,"isEnemy",tp)
	and getCardsNum("Jink",tp,self.player)>0
	and (package_known(self,"isWeak",tp) or not package_known(self,"isWeak")) then
		for _,p in sgs.list(self.friends)do
			if package_known(p,"canSlash",tp) and getCardsNum("Slash",p,self.player)>0 then
				return cards[1]:getEffectiveId()
			end
		end
	end
    return "."
end

sgs.ai_skill_playerchosen._zc_xuanhuafu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isEnemy",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not package_known(self,"isFriend",p) and #self.enemies<1
		then return p end
	end
end

sgs.ai_skill_invoke.zcjieji = function(self,data)
	local to = call(data,"toPlayer")
	return package_known(self,"doDisCard",to,"he",false) and package_known(self,"getCardsNum","Jink")>0
end

ai_skill_use["@@zcruixi"]=function(self,prompt,request)
	for _,c in ipairs(call(self,"sortByKeepValue",package_known(self.player,"getCards","he")))do
      	local dc=package_known(self,"evaluateSkillCard","zcruixi","slash",{package_known(c,"getId")})
		if package_known(dc,"isAvailable",self.player) then
			local dummy = package_known(self,"aiUseCard",dc)
			if dummy.card then
				local tos = {}
				for _,p in sgs.list(dummy.to)do
					table.insert(tos,package_known(p,"objectName"))
				end
				return selected(self,dc,tos)
			end
		end
	end
end

sgs.ai_skill_invoke.zclianrong = function(self,data)
	return package_known(self,"canDraw")
end

sgs.ai_fill_skill.zcbizun = function(self,inclusive,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do do
		if table.contains(self.toUse,c) or package_known(c,"getTypeId")~=3 then goto package_continue_22 end
		local dc=turn(self,"zcbizun","slash",{c},request)
		if package_known(dc,"isAvailable",self.player) and package_known(self,"aiUseCard",dc).card
		then return dc end
	end ::package_continue_22:: end
end

sgs.ai_view_as.zcbizun = function(card,player,card_place,class_name)
	if package_known(card,"getTypeId")==3 and card_place~=sgs.Player_PlaceSpecial then
    	if class_name=="Jink" then
			return {name="jink",skill="zcbizun",suit=sgs.Card_NoSuit,number=0,subcards={package_known(card,"getEffectiveId")}}
		else
			return {name="slash",skill="zcbizun",suit=sgs.Card_NoSuit,number=0,subcards={package_known(card,"getEffectiveId")}}
		end
	end
end

sgs.ai_skill_discard.zcdechong = function(self,x,n)
	local cards = call(self,"sortByKeepValue",package_known(self.player,"getCards","he"))
	local cp = call(self.room,"getCurrent")
	local c,p = call(self,"getCardNeedPlayer",cards,false,{cp})
	if c and p then
		return {package_known(c,"getEffectiveId")}
	end
	if package_known(self,"isFriend",cp) then
		if package_known(self,"isWeak",cp) then
			return {cards[#cards]:getEffectiveId()}
		end
	elseif package_known(self,"getOverflow")>0 then
		return {cards[1]:getEffectiveId()}
	end
end

sgs.ai_fill_skill.zcyuanzhuo = function(self,inclusive,request)
	return package_known(self,"evaluateTurnSkillCard","zcyuanzhuo","#zcyuanzhuoCard",{},request)
end

sgs.ai_skill_use_func["#zcyuanzhuoCard"] = function(card,use,self,request)
	local destlist = sgs.QList2Table(package_known(self.room,"getAlivePlayers")) -- 将列表转换为表
	call(self,"sort",destlist)
	for _,p in sgs.list(destlist)do
		if p~=self.player and package_known(self,"doDisCard",p,"he") then
			call(use.to,"append",p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.zcyuanzhuoCard = 3.4
sgs.ai_use_priority.zcyuanzhuoCard = 7.2

sgs.ai_skill_invoke.zcyuanzhuo = function(self,data)
	local tp = call(data,"toPlayer")
	return not package_known(self,"isFriend",tp)
end

ai_skill_use["@@zcwuwei"]=function(self,prompt,request)
	local cards = package_known(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	call(self,"sort",self.friends_noself)
	for _,h in sgs.list(cards)do
		if package_known(h,"getTypeId")==3 then
			for _,p in sgs.list(self.friends_noself)do do
				if package_known(self.player,"isProhibited",p,h) or #package_known(self,"poisonCards",{h},p)>0 then goto package_continue_23 end
				return respond(self,"zcwuwei","#zcwuweiCard",{package_known(h,"getEffectiveId")},{package_known(p,"objectName")},request)
			end ::package_continue_23:: end
			for _,p in sgs.list(self.enemies)do do
				if package_known(self.player,"isProhibited",p,h) or #package_known(self,"poisonCards",{h},p)<1 then goto package_continue_24 end
				return respond(self,"zcwuwei","#zcwuweiCard",{package_known(h,"getEffectiveId")},{package_known(p,"objectName")},request)
			end ::package_continue_24:: end
		end
	end
end

sgs.ai_skill_playerchosen.zcleiruo = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"doDisCard",p,"he",false)
		then return p end
	end
end

sgs.ai_skill_invoke.zcleiruo = function(self,data)
	local tp = call(data,"toPlayer")
	return not package_known(self,"isFriend",tp)
end

sgs.ai_skill_playerschosen.zclijun = function(self,players,x)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if #tps<x then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_skill_invoke.zczhuying = function(self,data)
	local tp = call(data,"toPlayer")
	return not package_known(self,"isFriend",tp)
end

sgs.ai_fill_skill.sxgongqiao = function(self,inclusive,request)
	return package_known(self,"evaluateTurnSkillCard","sxgongqiao","#sxgongqiaoCard",{},request)
end

sgs.ai_skill_use_func["#sxgongqiaoCard"] = function(card,use,self,request)
	local destlist = sgs.QList2Table(package_known(self.room,"getAlivePlayers")) -- 将列表转换为表
	call(self,"sort",destlist)
	for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p) and package_known(self,"canDraw",p) then
			call(use.to,"append",p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.sxgongqiaoCard = 3.4
sgs.ai_use_priority.sxgongqiaoCard = 7.2

sgs.ai_fill_skill.sxwanglu = function(self,inclusive,request)
	return package_known(self,"evaluateTurnSkillCard","sxwanglu","#sxwangluCard",{},request)
end

sgs.ai_skill_use_func["#sxwangluCard"] = function(card,use,self,request)
	local destlist = sgs.QList2Table(package_known(self.room,"getAlivePlayers")) -- 将列表转换为表
	call(self,"sort",destlist)
	for _,p in sgs.list(destlist)do
		if package_known(self,"doDisCard",p,"e") then
			call(use.to,"append",p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.sxwangluCard = 3.4
sgs.ai_use_priority.sxwangluCard = 7.2

sgs.ai_skill_invoke.sxjinhui = function(self,data)
	return true
end

sgs.ai_skill_playerchosen.sxjinhui = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p)
		then return p end
	end
end

ai_skill_use["@@sxjinhui!"]=function(self,prompt,request)
	for _,id in sgs.list(package_known(self,"getNotifiedTag","sxjinhuiForAI"))do do
      	local dc = package_known(self,"getKnownCardById",tonumber(id))
		if package_known(dc,"isAvailable",self.player) then
			local d = package_known(self,"aiUseCard",dc)
			if d.card then
				if package_known(dc,"canRecast") and package_known(d.to,"isEmpty") then goto package_continue_25 end
				local tos = {}
				for _,p in sgs.list(d.to)do
					table.insert(tos,package_known(p,"objectName"))
				end
				return selected(self,dc,tos)
			end
		end
	end ::package_continue_25:: end
	for _,id in sgs.list(package_known(self,"getNotifiedTag","sxjinhuiForAI"))do
      	local dc = package_known(self,"getKnownCardById",tonumber(id))
		if package_known(dc,"isAvailable",self.player) then
			if package_known(dc,"targetFixed") then return selected(self,dc,{}) end
			for _,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
				if package_known(self.player,"canUse",dc,p) then
					return selected(self,dc,{package_known(p,"objectName")})
				end
			end
		end
	end
end

sgs.ai_skill_discard.sxzhengjing = function(self,x,n)
	local ids = {}
	for _,c in sgs.list(call(self,"sortByKeepValue",package_known(self.player,"getCards","h")))do
		table.insert(ids,package_known(c,"getId"))
		if #ids>=x then break end
	end
	return ids
end

ai_skill_use["@@sxzhengjing!"]=function(self,prompt,request)
	local cards = {}
	for _,id in sgs.list(fact(self,"sxzhengjingIds"):split("+"))do
		table.insert(cards,package_known(self,"getKnownCardById",tonumber(id)))
	end
	call(self,"sortByKeepValue",cards)
	call(self,"sort",self.friends_noself)
    for _,p in sgs.list(self.friends_noself)do
		if package_known(self,"canDraw",p) then
			return respond(self,"sxzhengjing","#sxzhengjingCard",{cards[1]:getEffectiveId()},{package_known(p,"objectName")},request)
		end
	end
    for _,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
		if p~=self.player and not package_known(self,"isEnemy",p) then
			return respond(self,"sxzhengjing","#sxzhengjingCard",{cards[1]:getEffectiveId()},{package_known(p,"objectName")},request)
		end
	end
    for _,p in sgs.list(package_known(self.room,"getAlivePlayers"))do
		if p~=self.player then
			return respond(self,"sxzhengjing","#sxzhengjingCard",{cards[1]:getEffectiveId()},{package_known(p,"objectName")},request)
		end
	end
end

sgs.ai_skill_playerschosen.sxjianjie = function(self,players,x)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,nil,true)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if #tps<x and package_known(self,"isFriend",p) then table.insert(tps,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tps<x and not table.contains(tps,p)
		and not package_known(self,"isEnemy",p) then table.insert(tps,p) end
	end
	return tps
end

ai_skill_use["@@sxjianjie"]=function(self,prompt,request)
	local c = package_known(self,"getKnownCardById",package_known(self.player,"getStrategyMark","sxjianjieId"))
	if package_known(c,"isRed") then
		local dc=package_known(self,"evaluateSkillCard","_sxjianjie","fire_attack",{package_known(c,"getId")})
		local d = package_known(self,"aiUseCard",dc)
		if d.card then
			if package_known(dc,"canRecast") and package_known(d.to,"isEmpty") then return end
			local tos = {}
			for _,p in sgs.list(d.to)do
				table.insert(tos,package_known(p,"objectName"))
			end
			return selected(self,dc,tos)
		end
	elseif package_known(c,"isBlack") then
		local dc=package_known(self,"evaluateSkillCard","_sxjianjie","iron_chain",{package_known(c,"getId")})
		local d = package_known(self,"aiUseCard",dc)
		if d.card then
			if package_known(dc,"canRecast") and package_known(d.to,"isEmpty") then return end
			local tos = {}
			for _,p in sgs.list(d.to)do
				table.insert(tos,package_known(p,"objectName"))
			end
			return selected(self,dc,tos)
		end
	end
end

sgs.ai_skill_invoke.sxchenghao = function(self,data)
	return true
end

sgs.ai_skill_playerchosen.sxchenghao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p) and package_known(self,"canDraw",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if package_known(self,"isFriend",p)
		then return p end
	end
end

sgs.ai_skill_discard.sxshejian = function(self,x,n)
	local ids = {}
	local use = use_fact(self,"sxshejianData")
	if package_known(use.from,"getStrategyMark","&sxshejian+#"..package_known(self.player,"objectName").."-Clear")<1
	and package_known(self,"isEnemy",use.from) and package_known(self,"damageIsEffective",use.from,"N",self.player) then
		for _,c in sgs.list(call(self,"sortByKeepValue",package_known(self.player,"getCards","h")))do
			table.insert(ids,package_known(c,"getId"))
			if #ids>=x then break end
		end
	end
	return ids
end

sgs.ai_fill_skill.sxfuli = function(self,inclusive,request)
	for i,h in sgs.qlist(package_known(self.player,"getHandcards"))do
		if package_known(h,"isDamageCard") and package_known(self.player,"canDiscard",package_known(h,"getId")) and package_known(self,"aiUseCard",h).card
		then return end
	end
	return package_known(self,"evaluateTurnSkillCard","sxfuli","#sxfuliCard",{},request)
end

sgs.ai_skill_use_func["#sxfuliCard"] = function(card,use,self,request)
	call(self,"sort",self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if package_known(self,"isWeak",p) and package_known(p,"isWounded") then
			call(use.to,"append",p)
			use.card = card
			return
		end
	end
	for _,p in sgs.list(self.friends_noself)do
		if package_known(p,"isWounded") then
			call(use.to,"append",p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.sxfuliCard = 3.4
sgs.ai_use_priority.sxfuliCard = 7.2

sgs.ai_skill_askforag.sxdehua = function(self,card_ids)
	for _,id in sgs.list(card_ids)do do
		local c = package_known(self,"getPrintedCardById",id)
		local dc=package_known(self,"evaluateSkillCard","_sxdehua",package_known(c,"objectName"),{})
		if package_known(dc,"isAvailable",self.player) then
			local d = package_known(self,"aiUseCard",dc)
			if d.card then
				if package_known(dc,"canRecast") and package_known(d.to,"isEmpty")
				then goto package_continue_26 end
				save_plan(self,"sxdehua",d)
				return id
			end
		end
	end ::package_continue_26:: end
	return -1
end

ai_skill_use["@@sxdehua"]=function(self,prompt,request)
	local d=load_plan(self,"sxdehua")
	if d.card then
		local tos = {}
		for _,p in sgs.list(d.to)do
			table.insert(tos,package_known(p,"objectName"))
		end
		return selected(self,d.card,tos)
	end
end

sgs.ai_fill_skill.sxzengou = function(self,inclusive,request)
	return package_known(self,"evaluateTurnSkillCard","sxzengou","#sxzengouCard",{},request)
end

sgs.ai_skill_use_func["#sxzengouCard"] = function(card,use,self,request)
	for _,p in sgs.list(call(self,"sort",package_known(self.room,"getAlivePlayers"),nil,true))do
		if self.player~=p and package_known(p,"getHandcardNum")>2 then
			call(use.to,"append",p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.sxzengouCard = 3.4
sgs.ai_use_priority.sxzengouCard = 7.2

sgs.ai_skill_askforag.sxzengou = function(self,card_ids)
	for _,id in sgs.list(card_ids)do do
		local c = package_known(self,"getPrintedCardById",id)
		local dc=package_known(self,"evaluateSkillCard","_sxzengou",package_known(c,"objectName"),{})
		if package_known(dc,"isAvailable",self.player) then
			local d = package_known(self,"aiUseCard",dc)
			if d.card then
				if package_known(dc,"canRecast") and package_known(d.to,"isEmpty")
				then goto package_continue_27 end
				save_plan(self,"sxzengou",d)
				return id
			end
		end
	end ::package_continue_27:: end
	return -1
end

ai_skill_use["@@sxzengou"]=function(self,prompt,request)
	local d=load_plan(self,"sxzengou")
	if d.card then
		local tos = {}
		for _,p in sgs.list(d.to)do
			table.insert(tos,package_known(p,"objectName"))
		end
		return selected(self,d.card,tos)
	end
end

ai_skill_use["@@sxfeili"]=function(self,prompt,request)
	if package_known(self,"isWeak") and package_known(self.player,"getStrategyMark","sxzengouBan_lun")<1 then
		return respond(self,"sxfeili","#sxfeiliCard",{}, {},request)
	end
	if package_known(self,"getOverflow")>0 or package_known(self,"isWeak") then
		local ids = {}
		for _,c in sgs.list(call(self,"sortByKeepValue",package_known(self.player,"getCards","he")))do
			table.insert(ids,package_known(c,"getId"))
			if #ids>=2 then return respond(self,"sxfeili","#sxfeiliCard",ids, {},request) end
		end
	end
end

ai_skill_use["@@sxshuangrui"]=function(self,prompt,request)
	local cs = AIList.new({})
	local dc=package_known(self,"evaluateSkillCard","sxshuangrui","slash",{})
	local hs = call(self,"sortByKeepValue",package_known(self.player,"getCards","h"))
	for _,c in sgs.list(hs)do
		dc=package_known(self,"evaluateSkillCard","sxshuangrui","slash",ids(cs))
		if package_known(dc,"isAvailable",self.player) then
			local d = package_known(self,"aiUseCard",dc)
			if d.card then
				local tos = {}
				local has = true
				for _,p in sgs.list(d.to)do
					if package_known(self,"isEnemy",p) and package_known(p,"getHandcardNum")~=#hs-package_known(cs,"length")
					then has = false break end
					table.insert(tos,package_known(p,"objectName"))
				end
				if has then
					return selected(self,dc,tos)
				end
			end
			call(cs,"append",c)
		end
		dc=package_known(self,"evaluateSkillCard","sxshuangrui","slash",{})
	end
	if package_known(dc,"isAvailable",self.player) then
		local d = package_known(self,"aiUseCard",dc)
		if d.card then
			local tos = {}
			for _,p in sgs.list(d.to)do
				table.insert(tos,package_known(p,"objectName"))
			end
			return selected(self,dc,tos)
		end
	end
end

sgs.ai_skill_invoke.sxkengqiang = function(self,data)
	return package_known(self,"canDraw") or #self.enemies>0
end

sgs.ai_skill_choice.sxkengqiang = function(self,choices,data)
	local items = package_known(choices,"split","+")
	local use = package_known(data,"toCardUse")
	for _,p in sgs.list(use.to)do
		if package_known(self,"isFriend",p) then
			return items[1]
		end
	end
	if package_known(self,"isWeak") then
		return items[1]
	else
		for _,p in sgs.list(use.to)do
			if getCardsNum(sgs.aiResponse[package_known(use.card,"getClassName")],p,self.player)<1 then
				return items[2]
			end
		end
	end
end

sgs.ai_skill_invoke.sxshangjue = function(self,data)
	return package_known(self,"getAllPeachNum")+package_known(self.player,"getHp")<1
end

sgs.ai_skill_invoke.sxshangjue0 = function(self,data)
	return #self.enemies/2>=#self.friends
end

sgs.ai_skill_playerchosen.sxjianying = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	if peiqi(self) then
		for _,p in sgs.list(destlist)do
			if peiqi_state(self).from==p
			then return p end
		end
	end
end

sgs.ai_skill_cardchosen.sxjianying = function(self,who,flags,method)
	for _,c in sgs.qlist(package_known(who,"getCards",flags))do
		if package_known(c,"getId")==peiqi_state(self).cid
		then return package_known(c,"getId") end
	end
end

sgs.ai_skill_playerchosen.sxjianying1 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	for _,p in sgs.list(destlist)do
		if peiqi_state(self).to==p
		then return p end
	end
end

sgs.ai_skill_invoke.sxshibei = function(self,data)
	return package_known(self,"getAllPeachNum")+package_known(self.player,"getHp")<1
end

sgs.ai_skill_invoke.sxtongli = function(self,data)
	return true
end

sgs.ai_skill_invoke.sxshezang = function(self,data)
	local f,c,t = call(self,"moveField",self.player,"e",nil,{self.player})
	return f and c and t
end

sgs.ai_skill_playerchosen.sxshezang = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	local f,c,t = call(self,"moveField",self.player,"e",nil,{self.player})
	if f and c and t then
		for _,p in sgs.list(destlist)do
			if f==p then return p end
		end
	end
end

sgs.ai_skill_cardchosen.sxjianying = function(self,who,flags,method)
	local f,c,t = call(self,"moveField",self.player,"e",nil,{self.player})
	for _,c2 in sgs.qlist(package_known(who,"getCards",flags))do
		if AIValue.sameLegacyIdentity(c2,c) then return package_known(c2,"getId") end
	end
end

sgs.ai_fill_skill.sxyingmen = function(self,inclusive,request)
	return package_known(self,"evaluateTurnSkillCard","sxyingmen","#sxyingmenCard",{},request)
end

sgs.ai_skill_use_func["#sxyingmenCard"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value.sxyingmenCard = 3.4
sgs.ai_use_priority.sxyingmenCard = 7.2

sgs.ai_fill_skill.sxpingjian = function(self,inclusive,request)
	local cs = {}
	local hs = call(self,"sortByKeepValue",package_known(self.player,"getCards","h"))
	for _,id in sgs.qlist(package_known(self.player,"getPile","sxfangke"))do
		local c = package_known(self,"getPrintedCardById",id)
		local dc
		for _,h in sgs.list(hs)do do
			if table.contains(self.toUse,h) then goto package_continue_28 end
			dc=turn(self,"sxpingjian",package_known(c,"objectName"),{h},request)
			if package_known(dc,"isAvailable",self.player) then
				table.insert(cs,dc)
				break
			end
			-- discarded readonly hypothesis; next cost is independent
		end ::package_continue_28:: end
	end
	return cs
end
















