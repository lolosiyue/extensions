-- Fixed b6025acc package policy; all selection uses pure views and native-issued receipts.
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("package helper unavailable",method) end
    local values=table.pack(object[method](object,...))
    if AIUnsupported.is(values[1]) then error(values[1],0) end
    return table.unpack(values,1,values.n)
end
local function q(object,method,...)
    local values=table.pack(call(object,method,...))
    if values[1]==nil then ai_unsupported("package input is unknown",method) end
    return table.unpack(values,1,values.n)
end
local function dummy(value,extra)local u=AIUsePlan.new();u.isDummy=value~=false;u.extra_target=extra or 0;return u end
local function isCurrent(use,to)
 for _,p in ipairs(use.current_targets or {})do if p==to or p==q(to,"objectName")then return true end end
end
local function source_free_card(self)ai_unsupported("donor free global card is not scoped knowledge","kearlqxf.ty2chengshi.card")end
local function event_damage(self)
 local d,known=q(self,"getEventMemory","damage_data");if not known or type(d)~="table"then ai_unsupported("tyfuwei prior Damage data unknown","kearlqxf.damage_data")end
 local row={};for k,v in pairs(d)do row[k]=v end
 if type(row.to)=="string"then row.to=q(self.room,"findPlayerByObjectName",row.to,true)end;return row
end
local function respond(self,skill,selector,costs,names,request)
 if request and type(request.getActivationSkillName)~="function"then request=AILegacyRequest.new(request,self.room)end
 local u=AIUsePlan.new();u.card=q(self,"bindSkillCard",skill,costs,request,nil,selector)
 for _,name in ipairs(names)do u.to:append(q(self.room,"findPlayerByObjectName",name))end;return q(u,"toAnswer")
end
local function selected(self,card,names)
 local c=card
 if q(card,"isEvaluationOnly")then
  local costs=q(card,"getSubcards");local skill=q(card,"getSkillName",false)
  c=q(self,"bindOriginalSelectedConversion",{name=q(card,"objectName"),skill=skill,suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards=costs},q(card,"getClassName"),skill,card)
 end
 local u=AIUsePlan.new();u.card=c;for _,name in ipairs(names)do u.to:append(q(self.room,"findPlayerByObjectName",name))end;return q(u,"toAnswer")
end
local function save_plan(self,key,use)
 local c=use.card;local names={};for _,p in ipairs(use.to)do names[#names+1]=q(p,"objectName")end
 call(self,"setStrategyMemory","kearlqxf.plan."..key,{name=q(c,"objectName"),skill=q(c,"getSkillName",false),costs=q(c,"getSubcards"),targets=names})
end
local function load_plan(self,key)
 local d,known=call(self,"getStrategyMemory","kearlqxf.plan."..key)
 if not known or type(d)~="table"then ai_unsupported("source selected plan is unobserved","kearlqxf.plan."..key)end
 local u=AIUsePlan.new();u.card=q(self,"evaluateSkillCard",d.skill,d.name,d.costs)
 for _,name in ipairs(d.targets)do u.to:append(q(self.room,"findPlayerByObjectName",name))end;return u
end
sgs.ai_skill_discard.kelqchaojue = function(self)
	local cards = q(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	if #cards<3 then return {} end
	call(self,"sortByKeepValue",cards)
	local to_cards = {}
   	for i,c in sgs.list(cards)do do
		if i>=#to_cards/2 then
			if q(self,"aiUseCard",c).card then goto package_continue_1 end
			table.insert(to_cards,q(c,"getEffectiveId"))
			break
		end
	end ::package_continue_1:: end
	return to_cards
end

sgs.ai_skill_discard.kelqchaojue_show = function(self,x,n,o,e,p)
	local cards = q(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	call(self,"sortByKeepValue",cards)
	local to_cards = {}
	local cp = call(self.room,"getCurrent")
   	for i,c in sgs.list(cards)do
		if q(p,"contains",q(c,"getSuitString")) and not q(self,"isEnemy",cp) then
			table.insert(to_cards,q(c,"getEffectiveId"))
			break
		end
	end
	return to_cards
end

sgs.ai_fill_skill.kelqjunshen = function(self,inclusive,request)
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	call(self,"sortByKeepValue",cards)
	for _,h in sgs.list(cards)do
		if q(h,"isRed") then
			local slash=q(self,"evaluateTurnConversion","kelqjunshen","Slash",{name="slash",skill="kelqjunshen",suit=sgs.Card_NoSuit,number=0,subcards={q(h,"getEffectiveId")}},request)
			if q(slash,"isAvailable",self.player) then
				return slash
			end
		end
	end
end

sgs.ai_view_as.kelqjunshen = function(card,player,card_place,class_name)
	if card_place==sgs.Player_PlaceSpecial then return end
	if q(card,"isRed") then
    	return {name="slash",skill="kelqjunshen",suit=sgs.Card_NoSuit,number=0,subcards={q(card,"getEffectiveId")}}
	end
end

sgs.ai_skill_choice.kelqjunshen = function(self,choices)
	local items = q(choices,"split","+")
	if table.contains(items,"qizhi") then
		if q(self.player,"getEquips"):length()<3 or q(self,"isWeak") or q(self.player,"getEquips"):length()/2<=#q(self,"poisonCards","e") then
			return "qizhi"
		end
	end
	return items[2]
end

ai_skill_use["@@kelqlizhong"]=function(self,prompt,request)
	local valid,tos = {},{}
	local players = q(self.player,"getAliveSiblings")
    players = call(self,"sort",players)
	if q(self.player,"getStrategyMark","kelqlizhong1")~=1 then
		local cards = q(self.player,"getCards","he")
		cards = call(self,"sortByKeepValue",cards) -- 按保留值排序
		for _,h in sgs.list(cards)do
			if q(h,"getTypeId")==3 then
				local n = q(h,"getEquipSlot")
				for _,p in sgs.list(players)do do
					if table.contains(tos,q(p,"objectName")) then goto package_continue_2 end
					if q(p,"hasEquipArea",n) and call(p,"getEquip",n)==nil then
						if #q(self,"poisonCards",{h})>0 then
							if q(self,"isEnemy",p) or not q(self,"isFriend",p) and #self.enemies<1 then
								table.insert(valid,q(h,"getEffectiveId"))
								table.insert(tos,q(p,"objectName"))
								break
							end
						elseif q(self,"isFriend",p) then
							table.insert(valid,q(h,"getEffectiveId"))
							table.insert(tos,q(p,"objectName"))
							break
						end
					end
				end ::package_continue_2:: end
			end
		end
		if #tos<1 then
			if q(self.player,"getStrategyMark","kelqlizhong1")==2 then return end
			for _,p in sgs.list(players)do
				if q(self,"isFriend",p) and q(p,"hasEquip")
				then table.insert(tos,q(p,"objectName")) end
			end
		end
		if #tos<1 then table.insert(tos,q(self.player,"objectName")) end
	else
		for _,p in sgs.list(players)do
			if q(self,"isFriend",p) and q(p,"hasEquip")
			then table.insert(tos,q(p,"objectName")) end
		end
		if #tos<1 then table.insert(tos,q(self.player,"objectName")) end
	end
	if #tos<1 then return end
	return respond(self,"kelqlizhong","#kelqlizhongcard",valid,tos,request)
end

sgs.ai_view_as.kelqlizhongUse = function(card,player,card_place,class_name)
	if card_place~=sgs.Player_PlaceEquip then return end
   	return {name="nullification",skill="_kelqlizhong",suit=sgs.Card_NoSuit,number=0,subcards={q(card,"getEffectiveId")}}
end

sgs.ai_skill_invoke.kelqjuesui = function(self,data)
	local target = call(data,"toPlayer")
	if target then
		return q(self,"isFriend",target)
		or not q(self,"isEnemy",target) and #self.enemies>=#self.friends
	else
		return true
	end
end


sgs.ai_fill_skill.kelqjuesuiUse = function(self,inclusive,request)
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	call(self,"sortByKeepValue",cards)
	for _,h in sgs.list(cards)do
		if q(h,"isBlack") and q(h,"getTypeId")>1 then
			local slash=q(self,"evaluateTurnConversion","kelqjuesuiUse","Slash",{name="slash",skill="_kelqjuesui",suit=sgs.Card_NoSuit,number=0,subcards={q(h,"getEffectiveId")}},request)
			if q(slash,"isAvailable",self.player) then
				return slash
			end
		end
	end
end

sgs.ai_view_as.kelqjuesuiUse = function(card,player,card_place,class_name)
	if card_place==sgs.Player_PlaceSpecial then return end
	if q(card,"isRed") and q(card,"getTypeId")>1 then
    	return {name="slash",skill="_kelqjuesui",suit=sgs.Card_NoSuit,number=0,subcards={q(card,"getEffectiveId")}}
	end
end

sgs.ai_target_revises.kelqjuwu = function(to,card,self)
    if q(card,"objectName")=="slash" then
		local num = 0
		for _, p in sgs.qlist(q(self.room,"getAllPlayers")) do
			if q(self.player,"inMyAttackRange",p) then
				num = num + 1
			end
		end
		if num>=3
		then return true end
	end
end

sgs.ai_skill_invoke.kelqshouxiang = function(self,data)
	local numt = 0
	for _, p in sgs.qlist(q(self.room,"getAllPlayers")) do
		if q(p,"inMyAttackRange",self.player) then
			numt = numt + 1
		end
	end
	if numt>1 then
		return #q(self,"getTurnUse")<2
	end
end

ai_skill_use["@@kelqshouxiang"]=function(self,prompt,request)
	local valid,tos = {},{}
    call(self,"sort",self.friends_noself,nil,true)
	local n = q(self.player,"getStrategyMark","kelqshouxiangNum")
	local cards = q(self.player,"getCards","h")
	cards = call(self,"sortByKeepValue",cards) -- 按保留值排序
	if #self.friends_noself<2 then
		local players = q(self.player,"getAliveSiblings")
		players = call(self,"sort",players,nil,true)
		for _,h in sgs.list(cards)do
			for _,p in sgs.list(players)do do
				if table.contains(tos,q(p,"objectName")) or #tos>=n then goto package_continue_3 end
				if q(self,"isFriend",p) or not q(self,"isEnemy",p) and #self.enemies>0 then
					table.insert(valid,q(h,"getEffectiveId"))
					table.insert(tos,q(p,"objectName"))
					break
				end
			end ::package_continue_3:: end
		end
	else
		for _,h in sgs.list(cards)do
			for _,p in sgs.list(self.friends_noself)do do
				if table.contains(tos,q(p,"objectName")) or #tos>=n then goto package_continue_4 end
				table.insert(valid,q(h,"getEffectiveId"))
				table.insert(tos,q(p,"objectName"))
				break
			end ::package_continue_4:: end
		end
	end
	if #tos<1 then return end
	return respond(self,"kelqshouxiang","#kelqshouxiangcard",valid,tos,request)
end









sgs.ai_fill_skill.tywusheng = function(self,inclusive,request)
    local cards = q(self.player,"getCards","he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do do
		if table.contains(self.toUse,c)
		or not q(c,"isRed")
		then goto package_continue_5 end
		local dc=q(self,"evaluateTurnConversion","tywusheng","Slash",{name="slash",skill="tywusheng",suit=sgs.Card_NoSuit,number=0,subcards={q(c,"getEffectiveId")}},request)
		if q(dc,"isAvailable",self.player)
		then return dc end
	end ::package_continue_5:: end
end

sgs.ai_view_as.tywusheng = function(card,player,card_place,class_name)
	if q(card,"isRed") and card_place~=sgs.Player_PlaceSpecial then
    	return {name="slash",skill="tywusheng",suit=sgs.Card_NoSuit,number=0,subcards={q(card,"getEffectiveId")}}
	end
end

sgs.ai_skill_discard.tyfuwei = function(self,x,n)
	local damage = event_damage(self)
	if not q(self,"isFriend",damage.to) then return {} end
	local cards = {}
    local handcards = sgs.QList2Table(q(self.player,"getCards","he"))
    call(self,"sortByKeepValue",handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if #cards>2 or #cards>#handcards/2 or #cards>=x then break end
		table.insert(cards,q(h,"getEffectiveId"))
	end
	return cards
end

sgs.ai_skill_invoke.tyfuhan1 = function(self,data)
	local target = call(data,"toPlayer")
	if target then
		return not q(self,"isFriend",target)
	end
end

sgs.ai_skill_invoke.tyfuhan2 = function(self,data)
	local target = call(data,"toPlayer")
	if target then
		return q(self,"isFriend",target)
	end
end

sgs.ai_fill_skill.tychende = function(self,inclusive,request)
    local cards = q(self.player,"getCards","h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	local ids = {}
	for _,c in sgs.list(cards)do
		if q(c,"isKindOf","BasicCard") or q(c,"isNDTrick") then
			local dc=q(self,"getEvaluationCard",q(c,"objectName"))
			if q(self,"aiUseCard",dc).card then
				table.insert(ids,q(c,"getId"))
			end
		end
	end
	for _,c in sgs.list(cards)do
		if #ids==1 and not table.contains(ids,q(c,"getId")) then
			table.insert(ids,q(c,"getId"))
		end
	end
	call(self,"writeCurrentSourceTarget","tychendeTo",nil)
	if #ids>1 then return q(self,"evaluateTurnSkillCard","tychende","#tychendeCard",ids,request) end
	ids = {}
	local tp
	for _,h in sgs.list(cards)do
		if not table.contains(self.toUse,h) then
			local c,p = call(self,"getCardNeedPlayer",{h})
			if c and p then
				table.insert(ids,q(c,"getId"))
				if tp==p and #ids>1 then
					call(self,"writeCurrentSourceTarget","tychendeTo",p)
					return q(self,"evaluateTurnSkillCard","tychende","#tychendeCard",ids,request)
				end
				tp = p
			end
		end
	end
end

sgs.ai_skill_use_func["#tychendeCard"] = function(card,use,self,request)
	if q(self,"currentSourceTargetPresent","tychendeTo") then
		use.card = card
		call(use.to,"append",call(self,"readCurrentSourceTarget","tychendeTo"))
		return
	end
	call(self,"sort",self.friends_noself,"card")
	for _,p in sgs.list(self.friends_noself)do
		if q(self,"canDraw",p) then
			use.card = card
			call(use.to,"append",p)
			break
		end
	end
end

sgs.ai_use_value.tychendeCard = 3.4
sgs.ai_use_priority.tychendeCard = 11.2

sgs.ai_skill_askforag.tychende = function(self,card_ids)
    local cards = {}
	for _,id in sgs.list(card_ids)do
		table.insert(cards,q(self,"getKnownCardById",id))
	end
	call(self,"sortByUsePriority",cards)
	for _,c in sgs.list(cards)do do
		local dc=self:evaluateTychendeSource(q(c,"objectName"))
		local d = self:aiUseCard(dc)
		if d.card then
			if q(c,"canRecast") and q(d.to,"isEmpty") then goto package_continue_6 end
			self:writeTychendeSavedPlan(d)
			return q(c,"getId")
		end
	end ::package_continue_6:: end
	return -1
end

ai_skill_use["@@tychende"]=function(self,prompt,request)
    local d=self:readTychendeSavedPlan()
   	if d.card then
      	local tos = {}
       	for _,p in sgs.list(d.to)do
       		table.insert(tos,q(p,"objectName"))
       	end
       	return self:materializeTychendeSaved(d.card,tos)
    end
end

sgs.ai_skill_playerchosen.tysheju = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,"card")
    for _,target in sgs.list(destlist)do
		if q(self,"doDisCard",target,"e")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if q(self,"doDisCard",target,"he")
		and not q(self,"isFriend",target)
		then return target end
	end
end

sgs.ai_skill_invoke.tyxiyu = function(self,data)
	return q(self,"canDraw")
end

sgs.ai_fill_skill.tyxingsha = function(self,inclusive,request)
    local cards = q(self.player,"getCards","he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	local ids = {}
	local m = q(self,"getOverflow")
	for _,c in sgs.list(cards)do
		table.insert(ids,q(c,"getId"))
		if #ids>1 then return q(self,"evaluateTurnSkillCard","tyxingsha","#tyxingshaCard",ids,request) end
		if #ids>=m then break end
	end
	if #ids>0 then return q(self,"evaluateTurnSkillCard","tyxingsha","#tyxingshaCard",ids,request) end
end

sgs.ai_skill_use_func["#tyxingshaCard"] = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_value.tyxingshaCard = 3.4
sgs.ai_use_priority.tyxingshaCard = -3.2

sgs.ai_fill_skill.ty2chengshi = function(self,inclusive,request)
    local cards = q(self.player,"getCards","he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		local dc=source_free_card(self)
		if q(c,"isRed") and q(dc,"isAvailable",self.player) then
			return q(self,"evaluateTurnSkillCard","ty2chengshi","#ty2chengshicard",{q(c,"getId")},request)
		end
	end
end

sgs.ai_skill_use_func["#tyxingshaCard"] = function(card,use,self,request)
	local dc=q(self,"evaluateSkillCard","ty2chengshi","slash",{q(card,"getEffectiveId")})
	local d = q(self,"aiUseCard",dc,dummy(nil,99))
	if d.card then
		for _,p in sgs.list(d.to)do
			if q(p,"getStrategyMark","&ty2chengshi+#"..q(self.player,"objectName").."_lun")>0 then
				use.card = card
				call(use.to,"append",p)
				break
			end
		end
	end
end

sgs.ai_use_value.ty2chengshicard = 3.4
sgs.ai_use_priority.ty2chengshicard = 1.2

ai_skill_use["@@tyxingsha"]=function(self,prompt,request)
    local ids = q(self.player,"getPile","tyyuan")
	for i,id1 in sgs.list(ids)do
		for n,id2 in sgs.list(ids)do
			if i<n then
				local dc=q(self,"evaluateSkillCard","tyxingsha","slash",{id1,id2})
				if q(dc,"isAvailable",self.player) then
					local d = q(self,"aiUseCard",dc)
					if d.card then
						local tos = {}
						for _,p in sgs.list(d.to)do
							table.insert(tos,q(p,"objectName"))
						end
						return selected(self,dc,tos)
					end
				end
			end
		end
	end
end

sgs.ai_skill_invoke.tybianwo = function(self,data)
	return true
end

ai_skill_use["@@tybianwo"]=function(self,prompt,request)
    local id = q(self.player,"getStrategyMark","tybianwoId")
	local dc = q(self,"getKnownCardById",id)
	local d = q(self,"aiUseCard",dc)
	if d.card then
		local tos = {}
		for _,p in sgs.list(d.to)do
			table.insert(tos,q(p,"objectName"))
		end
		if q(dc,"canRecast") and #tos<1 then return end
		return selected(self,dc,tos)
	end
end

sgs.ai_skill_playerchosen.tyxianshou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if q(self,"isFriend",p) and q(p,"isWounded")
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not q(self,"isEnemy",p)
		then return p end
	end
end

sgs.ai_skill_playerchosen.tybenxiang = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if q(self,"isFriend",p) and q(self,"canDraw",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not q(self,"isEnemy",p)
		then return p end
	end
end

sgs.ai_skill_invoke.tyzhongen = function(self,data)
	local to = call(data,"toPlayer")
	if q(self,"isFriend",to) and q(self,"canDraw",to) then
		return true
	end
	return #self.enemies>0
end

sgs.ai_skill_choice.tyzhongen = function(self,choices,data)
	local items = q(choices,"split","+")
	if table.contains(items,"tyzhongen1") then
		local to = call(data,"toPlayer")
		if q(self,"isFriend",to) and q(self,"canDraw",to) then
			return "tyzhongen1"
		end
	end
	if table.contains(items,"tyzhongen2")
	then return "tyzhongen2" end
end

sgs.ai_skill_invoke.tyliebao = function(self,data)
	local to = call(data,"toPlayer")
	if q(self,"isFriend",to) and q(self,"isWeak",to) then
		return not q(self,"isWeak") or call(self,"getCard","Jink")~=nil
	end
end

sgs.ai_skill_invoke.tyfenwu = function(self,data)
	return q(self,"canDraw")
end

sgs.ai_skill_choice.tyfenwu = function(self,choices,data)
	local items = q(choices,"split","+")
	local id = q(self.player,"getStrategyMark","tyfenwuId")
    for _,pn in sgs.list(items)do
		if pn=="cancel" then return pn end
		local dc=self:evaluateTyfenwuSource(pn,id)
		if q(dc,"isAvailable",self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				self:writeTyfenwuSavedPlan(d)
				return pn
			end
		end
	end
end

ai_skill_use["@@tyfenwu"]=function(self,prompt,request)
    local d=self:readTyfenwuSavedPlan()
   	if d.card then
      	local tos = {}
       	for _,p in sgs.list(d.to)do
       		table.insert(tos,q(p,"objectName"))
       	end
       	return self:materializeTyfenwuSaved(d.card,tos)
    end
end

sgs.ai_skill_invoke.tyqingkou = function(self,data)
	return q(self,"canDraw")
end

sgs.ai_skill_choice.tyqingkou = function(self,choices,data)
	local items = q(choices,"split","+")
	local id = q(self.player,"getStrategyMark","tyqingkouId")
    for _,pn in sgs.list(items)do do
		if pn=="cancel" then return pn end
		local dc=self:evaluateTyqingkouSource(pn,id)
		if q(dc,"isAvailable",self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				if q(dc,"canRecast") and q(d.to,"isEmpty") then goto package_continue_7 end
				self:writeTyqingkouSavedPlan(d)
				return pn
			end
		end
	end ::package_continue_7:: end
end

ai_skill_use["@@tyqingkou"]=function(self,prompt,request)
    local d=self:readTyqingkouSavedPlan()
   	if d.card then
      	local tos = {}
       	for _,p in sgs.list(d.to)do
       		table.insert(tos,q(p,"objectName"))
       	end
       	return self:materializeTyqingkouSaved(d.card,tos)
    end
end

sgs.ai_skill_invoke.tyyuantao = function(self,data)
	local use = q(data,"toCardUse")
	return q(self,"isFriend",use.from) and not q(self,"isWeak")
	and (q(use.card,"isDamageCard") or q(use.from,"getLostHp")>1 and q(use.to,"contains",use.from))
end

sgs.ai_skill_cardask.tychonglong1 = function(self,data,pattern,prompt)
	local damage = q(data,"toDamage")
    if q(self,"isEnemy",damage.to)
	and q(self,"isWeak",damage.to)
	then return true end
	return "."
end

sgs.ai_skill_cardask.tychonglong0 = function(self,data,pattern,prompt)
	local use = q(data,"toCardUse")
    if q(self,"isEnemy",q(use.to,"first"))
	and not q(self,"isEnemy",use.from)
	then return true end
	return "."
end

sgs.ai_skill_invoke.tychonglong = function(self,data)
	return q(self,"canDraw")
end

sgs.ai_skill_cardask.tyqianshou0 = function(self,data,pattern,prompt)
	local to = call(data,"toPlayer")
    if q(self,"isEnemy",to)
	and (q(self,"isWeak",to) or q(to,"inMyAttackRange",self.player) and q(self,"isWeak"))
	then return true end
	return "."
end

sgs.ai_skill_invoke.tyqianshou = function(self,data)
	local to = call(data,"toPlayer")
	return q(self,"canDraw") and not q(self,"isWeak")
end

sgs.ai_fill_skill.tytanlong = function(self,inclusive,request)
	return q(self,"evaluateTurnSkillCard","tytanlong","#tytanlongCard",{},request)
end

sgs.ai_skill_use_func["#tytanlongCard"] = function(card,use,self,request)
	call(self,"sort",self.enemies)
	for _,ep in sgs.list(self.enemies)do
		if q(self.player,"getHandcardNum")>q(ep,"getHandcardNum") and q(self.player,"canPindian",ep) then
			use.card = card
			call(use.to,"append",ep)
			break
		end
	end
end

sgs.ai_use_value.tytanlongCard = 3.4
sgs.ai_use_priority.tytanlongCard = 3.2

sgs.ai_skill_invoke.tytanlong = function(self,data)
	local c = q(data,"toCard")
	return q(self,"canDraw") and #q(self,"poisonCards",{c})<1
end

sgs.ai_skill_invoke.tyxibei = function(self,data)
	return q(self,"canDraw")
end

sgs.ai_skill_cardask.tyxibei0 = function(self,data,pattern,prompt)
    if #self.enemies>0
	then return true end
	return "."
end

ai_card_use.HuoshaolianyingTy=function(self,card,use)
	call(self,"sort",self.enemies)
	for _,ep in sgs.list(self.enemies)do do
		if isCurrent(use,ep) then goto package_continue_8 end
		if q(self,"cardTargetFilter",card,use.to,ep) and q(self,"hasTrickEffective",card,ep,self.player)
		and q(self,"ajustDamage",self.player,ep,1,card,"F")~=0 then
	    	use.card = card
	    	call(use.to,"append",ep)
		end
	end ::package_continue_8:: end
	if q(self,"getOverflow")>1 then
		local tos = call(self,"sort",q(self.room,"getAlivePlayers"),nil,true)
		for _,ep in sgs.list(tos)do do
			if isCurrent(use,ep) or q(self,"isFriend",ep) then goto package_continue_9 end
			if q(self,"cardTargetFilter",card,use.to,ep) and q(self,"hasTrickEffective",card,ep,self.player)
			and q(self,"ajustDamage",self.player,ep,1,card,"F")~=0 then
				use.card = card
				call(use.to,"append",ep)
			end
		end ::package_continue_9:: end
	end
end
sgs.ai_use_priority.HuoshaolianyingTy = 3.5
sgs.ai_keep_value.HuoshaolianyingTy = 2
sgs.ai_use_value.HuoshaolianyingTy = 3.7

sgs.ai_skill_cardask._tyhuoshaolianying0 = function(self,data,pattern,prompt)
	local effect = q(data,"toCardEffect")
	if q(self,"ajustDamage",self.player,effect.to,1,effect.card,"F")==0
	then return "." end
    if q(self,"isFriend",effect.to) then
		return q(effect.to,"isChained") and q(self,"isGoodChainTarget",effect.to,"F")
	elseif q(effect.to,"isChained") then
		return q(self,"isGoodChainTarget",effect.to,"F")
	else
		return true
	end
	return "."
end

sgs.ai_nullification.HuoshaolianyingTy = function(self,trick,from,to,positive)
    return q(self,"isFriend",to) and positive
end

sgs.ai_card_intention.HuoshaolianyingTy = 77

sgs.ai_skill_playerschosen.tyqingshi = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist,nil,true)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and q(self,"isFriend",p) and q(p,"getHandcardNum")>0
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<x and not q(self,"isEnemy",p) and q(p,"getHandcardNum")>0
		and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
	return tos
end

ai_skill_use["@@tyqingshi"]=function(self,prompt,request)
	local ids,tos = {},{}
	local aps = {}
    for _,p in sgs.list(q(self.room,"getOtherPlayers",self.player))do
      	if q(p,"getStrategyFlag","tyqingshiBlack") then table.insert(aps,p) end
	end
    local cards = q(self.player,"getCards","he")
    cards = call(self,"sortByKeepValue",cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		local c,p = call(self,"getCardNeedPlayer",{h},false,aps)
		if c and p then
			table.insert(ids,q(c,"getId"))
			table.insert(tos,q(p,"objectName"))
			table.removeOne(aps,p)
		end
	end
	if #ids<1 then return end
	return respond(self,"tyqingshi","#tyqingshiCard",ids,tos,request)
end

sgs.ai_skill_invoke.tyyilin = function(self,data)
	local move = q(data,"toMoveOneTime")
	local to = move.to
	return q(self,"isFriend",to)
end

sgs.ai_skill_playerchosen.tychengming = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if q(self,"isFriend",p) and q(self,"canDraw",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if q(self,"isFriend",p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not q(self,"isEnemy",p)
		then return p end
	end
end

sgs.ai_skill_invoke.tymanyong = function(self,data)
	return #self.enemies>0 and q(self,"canDraw")
end

sgs.ai_skill_invoke._tytiejiliguduo = function(self,data)
	return q(self.player,"getHp")>2 and q(self.player,"getHandcardNum")>=q(self.player,"getHp")
end

sgs.ai_skill_invoke.tyyizhuang = function(self,data)
	return q(self,"doDisCard",self.player,"j") and not q(self,"isWeak")
end

sgs.ai_skill_discard.tysiji = function(self,x,n,o,e,p)
	local to = call(self.room,"getCurrent")
	if not q(self,"isEnemy",to) then return {} end
    local handcards = sgs.QList2Table(q(self.player,"getCards","he"))
    call(self,"sortByKeepValue",handcards) -- 按保留值排序
	local dc
   	for _,h in sgs.list(handcards)do
		dc=q(self,"evaluateSkillCard","tysiji","yj_stabs_slash",{q(h,"getEffectiveId")})
		if q(self.player,"canSlash",to,dc,false) and q(self,"hasTrickEffective",dc,to) then
			return {q(h,"getId")}
		end
		-- next iteration constructs a fresh native readonly clone
	end
	return {}
end

sgs.ai_skill_discard.tydaifa = function(self,x,n,o,e,p)
	local to = call(self.room,"getCurrent")
	if not q(self,"isEnemy",to) then return {} end
    local handcards = sgs.QList2Table(q(self.player,"getCards","he"))
    call(self,"sortByKeepValue",handcards) -- 按保留值排序
	local dc
   	for _,h in sgs.list(handcards)do
		dc=q(self,"evaluateSkillCard","tydaifa","yj_stabs_slash",{q(h,"getEffectiveId")})
		if q(self.player,"canSlash",to,dc,false) and q(self,"hasTrickEffective",dc,to) then
			return {q(h,"getId")}
		end
		-- next iteration constructs a fresh native readonly clone
	end
	return {}
end

sgs.ai_skill_discard.tyansha = function(self,x,n,o,e,p)
	local to = call(self.room,"getCurrent")
	if not q(self,"isEnemy",to) then return {} end
    local handcards = sgs.QList2Table(q(self.player,"getCards","he"))
    call(self,"sortByKeepValue",handcards) -- 按保留值排序
	local dc
   	for _,h in sgs.list(handcards)do
		dc=q(self,"evaluateSkillCard","tyansha","yj_stabs_slash",{q(h,"getEffectiveId")})
		if q(self.player,"canSlash",to,dc) and q(self,"hasTrickEffective",dc,to) then
			return {q(h,"getId")}
		end
		-- next iteration constructs a fresh native readonly clone
	end
	return {}
end

sgs.ai_skill_discard.tyxihun = function(self,x,n)
    local handcards = sgs.QList2Table(q(self.player,"getCards","h"))
	if not q(self,"isWeak") and #handcards<4 then return {} end
	local cards = {}
    call(self,"sortByKeepValue",handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if #cards>1 then break end
		table.insert(cards,q(h,"getEffectiveId"))
	end
	return cards
end

sgs.ai_fill_skill.tyxianqivs = function(self,inclusive,request)
    local cards = q(self.player,"getCards","h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    call(self,"sortByKeepValue",cards,nil,"j") -- 按保留值排序
	local ids = {}
	for _,h in sgs.list(cards)do do
		if table.contains(self.toUse,h) then goto package_continue_10 end
		table.insert(ids,q(h,"getId"))
		if #ids>1 and q(self,"getOverflow")>0 then
			return q(self,"evaluateTurnSkillCard","tyxianqivs","#tyxianqicard",ids,request)
		end
	end ::package_continue_10:: end
	return not q(self,"isWeak")
	and q(self,"evaluateTurnSkillCard","tyxianqivs","#tyxianqicard",{},request)
end

sgs.ai_skill_use_func["#tyxianqicard"] = function(card,use,self,request)
	for _,p in sgs.list(self.enemies)do
		if q(p,"hasSkill","tyxianqi") and q(self,"ajustDamage",self.player,p,1)~=0 then
			use.card = card
			call(use.to,"append",p)
			break
		end
	end
end

sgs.ai_use_value.tyxianqicard = 3.4
sgs.ai_use_priority.tyxianqicard = 0.2


