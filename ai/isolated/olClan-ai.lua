-- Fixed olClan policy over disclosed values. Runtime owns all card authority.
-- This file is being extended by dependency group; see the named /tmp inventory.
local known = AIValue.requireKnown

local function copy_list(values)
    local out={};for i,value in ipairs(known(values,"olClan.list"))do out[i]=value end
    return AIList.new(out)
end
local function has_skill(self,player,name,include_lose)
    local value=player:hasSkill(name,include_lose)
    local row=rawget(player,"_view")
    if value==true or value~=nil and (not row or row.skills_complete==true) then return value end
    if player:objectName()==self.player:objectName() then ai_unsupported("owner skill roster is incomplete",name) end
    return self:useKnowledgeEstimate({status="estimate",value=false,basis="olClan.undisclosed_skill_uses_public_roster",target=player:objectName(),skill=name},"olClan.skills")
end
local function mark(self,player,key)return known(player:getStrategyMark(key),"olClan.mark")end
local function remember(self,key,value)self:setStrategyMemory("olClan."..key,value)end
local function recall(self,key)local value=self:getStrategyMemory("olClan."..key);return value end
local function data_value(self,kind)
    local method=({player="toPlayer",damage="toDamage",use="toCardUse",dying="toDying"})[kind]
    return known(self:getDecisionData()[method](),"olClan.context."..kind)
end

-- Source olClan-ai.lua:2
sgs.ai_skill_discard.zuyuzhi = function(self)
	local to_cards = {}
	local cards = self.player:getCards("h")
	cards = copy_list(cards)
	self:sortByKeepValueInPlace(cards)
	local n = 0
   	for _,c in ipairs(cards)do
		local x = c:nameLength()
		if x>n then n = x end
	end
   	for _,c in ipairs(cards)do
		local x = c:nameLength()
		if x>=n then table.insert(to_cards,c:getEffectiveId()) break end
	end
	return to_cards
end

-- Source olClan-ai.lua:19
sgs.ai_skill_choice.losehoorremoveskill = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"removes_zu_zhong_baozu")
	and self:isWeak() and mark(self,self.player,"@zu_zhong_baozu")<1
	then return "removes_zu_zhong_baozu" end
	return items[1]
end

-- Source olClan-ai.lua:27
sgs.ai_skill_discard.zuxieshu = function(self,max,min)
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = copy_list(cards)
	if self.player:getLostHp()>max/2 then
		self:sortByKeepValueInPlace(cards)
		for _,h in ipairs(cards)do
			if #to_cards>min then break end
			table.insert(to_cards,h:getEffectiveId())
		end
	end
	if #to_cards<min then to_cards = {} end
	return to_cards
end

-- Source olClan-ai.lua:42
sgs.ai_skill_invoke.zu_zhong_baozu = function(self,data)
	local dying = data_value(self,"dying")
	return self:isFriend(dying.who)
	and self:getAllPeachNum()+dying.who:getHp()<1
end

-- Source olClan-ai.lua:48
sgs.ai_skill_playerchosen.zujiejian = function(self,players)
    for _,target in ipairs(players)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in ipairs(players)do
		if not self:isEnemy(target)
		and #self.enemies>0
		then return target end
	end
end

-- Source olClan-ai.lua:75
sgs.ai_skill_invoke.zuhuanghan = function(self,data)
	local damage = data_value(self,"damage")
	local n = damage.card:nameLength()
	return n>=self.player:getLostHp() or mark(self,self.player,"@zu_zhong_baozu")<1
	and has_skill(self,self.player,"zu_zhong_baozu",true)
end

-- Source olClan-ai.lua:166
sgs.ai_skill_playerchosen.zu_wu_muyin = function(self, targets)
    local min = -1
    local selected = nil
    for _,target in ipairs(targets) do
        if self:isFriend(target) then
            if has_skill(self,target,"zuguixiang",true) and target:getMaxCards() == 2 then continue end--防止穆荫导致贵相跳了摸牌阶段
            if min < 0 or min > target:getMaxCards() then 
                min = target:getMaxCards() 
                selected = target
            end
        end
    end
    return selected
end

-- Source olClan-ai.lua:291
sgs.ai_skill_playerchosen.zulianzhu = function(self,players)
    local ep = self:readOlClanPlayerSlot("zulianzhuEp")
	if ep and self:isFriend(ep) then
		for _,target in ipairs(players)do
			if self:isEnemy(target)
			and self.player:canSlash(target,nil,false)
			and ep:canSlash(target,nil,false)
			then return target end
		end
	end
    for _,target in ipairs(players)do
		if not self:isFriend(target)
		then return target end
	end
end

-- Source olClan-ai.lua:307
sgs.ai_skill_cardask["@zuqiajue-invoke"] = function(self,data,pattern)
	local cards = self.player:getCards("he")
	cards = copy_list(cards)
    self:sortByKeepValueInPlace(cards)--按保留值排序
	local n = 0
   	for _,c in ipairs(cards)do
		n = n+c:getNumber()
	end
   	for _,c in ipairs(cards)do
    	if n>30 or self.player:isJilei(c) or not c:isBlack() then continue end
		return c:getEffectiveId()
	end
    return "."
end

-- Source olClan-ai.lua:325
sgs.ai_skill_choice["kezudaojie"] = function(self, choices, data)
	local items = choices:split("+")
    if table.contains(items,"hp")
	and self.player:getHp()+self:getCardsNum("Peach,Analeptic")>1 then return "hp" end
	if table.contains(items,"kezudaojie") then return "kezudaojie" end
	if table.contains(items,"skill") then return "skill" end
end

-- Source olClan-ai.lua:333
sgs.ai_skill_playerchosen.kezudaojie = function(self, targets)
    local fri = {}
    for _,target in ipairs(targets) do
        if self:isFriend(target) then
            table.insert(fri, target)
        end
    end
    if #fri > 0 then
        self:sortInPlace(fri, "handcard")
        return fri[1]
    end
    for _,target in ipairs(targets) do
        return target
    end
end

-- Source olClan-ai.lua:439
sgs.ai_skill_choice["ny_baichu"] = function(self, choices, data)
	if string.find(choices, "recover") then return "recover" end
    local items = choices:split("+")
    return items[math.random(1,#items)]
end

-- Source olClan-ai.lua:518
sgs.ai_skill_choice["kezulieshi"] = function(self, choices, data)
	local items = choices:split("+")
    --if table.contains(items,"slash") then return "slash" end
	--if table.contains(items,"jink") then return "jink" end
    for _,tr in ipairs(items) do
		if tr:startsWith("lieshidamage") and not self:isWeak()
		then return tr end
	end
end

-- Source olClan-ai.lua:528
sgs.ai_skill_playerchosen.kezulieshi = function(self, players)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist, "handcard", true)
    for _,target in ipairs(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in ipairs(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

-- Source olClan-ai.lua:556
sgs.ai_skill_choice["kezufangzhen"] = function(self, choices, data)
	local items = choices:split("+")
	local to = data_value(self,"player")
    if self:isWeak(to) and to:isWounded()
	then return items[2] end
    return items[1]
end

-- Source olClan-ai.lua:564
sgs.ai_skill_playerchosen.kezuliuju = function(self, players)
    local cards = self.player:getCards("h")
    cards = copy_list(cards)--将列表转换为表
	if #cards<2 then return end
    self:sortByKeepValueInPlace(cards)--按保留值排序
	self:remember("kezuliuju_card",cards[1]:getEffectiveId())
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist, "handcard")
    for _,target in ipairs(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in ipairs(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

-- Source olClan-ai.lua:635
sgs.ai_skill_playerschosen.kezulianhe = function(self,players,x,n)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist, "handcard")
	local tos = {}
    for _,p in ipairs(destlist)do
		if self:isEnemy(p) and #tos<x
		then table.insert(tos,p) end
	end
    for _,p in ipairs(destlist)do
		if not self:isFriend(p) and #tos<x
		and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
    for _,p in ipairs(destlist)do
		if #tos<x and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
	return tos
end

-- Source olClan-ai.lua:655
sgs.ai_skill_invoke.kezulianhe = function(self,data)
	return #self.friends+#self.enemies>1
end

-- Source olClan-ai.lua:676
sgs.ai_skill_choice["kezuhuanjia"] = function(self, choices, data)
	local items = choices:split("+")
    if table.contains(items,"kezuxumin")
	and mark(self,self.player,"@kezuxumin")<1
	then return "kezuxumin" end
end

-- Source olClan-ai.lua:683
sgs.ai_skill_playerchosen.kezuhuanjia = function(self, players)
    local cards = self.player:getCards("h")
    cards = copy_list(cards)--将列表转换为表
	if #cards<2 then return end
    self:sortByKeepValueInPlace(cards)--按保留值排序
	self:remember("kezuliuju_card",cards[1]:getEffectiveId())
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist, "handcard")
    for _,target in ipairs(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in ipairs(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

-- Source olClan-ai.lua:902
sgs.ai_skill_choice["kezubolong"] = function(self, choices, data)
	local items = choices:split("+")
	if self:isWeak() then return items[2] end
    return items[1]
end

-- Source olClan-ai.lua:996
sgs.ai_skill_invoke.kezuchenya = function(self,data)
	local to = data_value(self,"player")
	return self:isFriend(to)
	or not self:isEnemy(to) and #self.enemies>0
end

-- Source olClan-ai.lua:1102
sgs.ai_skill_invoke.kezujianji = function(self,data)
	local cur = self.room:getCurrent()
	return self:isFriend(cur)
	or not self:isEnemy(cur) and #self.enemies>0
end

-- Source olClan-ai.lua:1184
sgs.ai_skill_invoke.kezujianyuan = function(self,data)
	local cur = data_value(self,"player")
	return self:isFriend(cur)
	or not self:isEnemy(cur) and #self.enemies>0
end

-- Source olClan-ai.lua:1304
sgs.ai_skill_playerchosen.zuchengqi = function(self, players)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist, "handcard")
    for _,target in ipairs(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in ipairs(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

-- Source olClan-ai.lua:1317
sgs.ai_skill_playerchosen.zujieli = function(self, players)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist)
    for _,target in ipairs(destlist)do
		self:writeOlClanPlayerSlot("zujieliTo",target)
		if self:isFriend(target)
		then return target end
	end
    for _,target in ipairs(sgs.reverse(destlist))do
		self:writeOlClanPlayerSlot("zujieliTo",target)
		if self:isEnemy(target)
		then return target end
	end
end

-- Source olClan-ai.lua:1366
sgs.ai_skill_playerchosen.kezutanque = function(self, players)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist)
    for _,target in ipairs(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in ipairs(destlist)do
		if not self:isFriend(target)
		and #self.enemies<1
		then return target end
	end
end

-- Source olClan-ai.lua:1463
sgs.ai_skill_cardchosen.zukaiji = function(self,who)
	if self.player==who then
		for _,h in ipairs(who:getHandcards())do
			if h:isAvailable(who) and self:aiUseCard(h).card then
				return h:getId()
			end
		end
	end
end

-- Source olClan-ai.lua:1473
sgs.ai_skill_invoke.zuanran = function(self,data)
	return self:canDraw()
end

-- Source olClan-ai.lua:1477
sgs.ai_skill_playerschosen.zuanran = function(self, players,x,n)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist)
	local tos = {}
    for _,p in ipairs(destlist)do
		if #tos<x and self:isFriend(p) and self:canDraw(p)
		then table.insert(tos,p) end
	end
	if #tos<=x/2 and self:canDraw()
	then tos = {} end
	return tos
end

-- Source olClan-ai.lua:1523
sgs.ai_skill_invoke.zuqieyi = function(self,data)
	return self:canDraw() and not self:isWeak()
end

-- Source olClan-ai.lua:1527
sgs.ai_skill_playerchosen.zuquhuo = function(self, players)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist)
    for _,target in ipairs(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in ipairs(destlist)do
		if not self:isEnemy(target)
		and #self.enemies>0
		then return target end
	end
end

-- Source olClan-ai.lua:1541
sgs.ai_skill_playerchosen.zujiewu = function(self, players)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist, nil, true)
    for _,target in ipairs(destlist)do
		if not self:isFriend(target)
		then return target end
	end
	return destlist[1]
end

-- Source olClan-ai.lua:1551
sgs.ai_skill_invoke.zujiewu = function(self,data)
	local use = data_value(self,"use")
	self:writeOlClanSuitSlot(known(use.card:getSuitString(),"zujiewu.suit"))
	for _,p in ipairs(self.room:getAlivePlayers())do
		if mark(self,p,"&zujiewu+#"..self.player:objectName().."-PlayClear")>0
		and getKnownCard(p,self.player,self:readOlClanSuitSlot())>0
		then return true end
	end
end

-- Source olClan-ai.lua:1561
sgs.ai_skill_cardchosen.zujiewu = function(self,who)
	for _,h in ipairs(getKnownCards(who,self.player,"h"))do
		if self:readOlClanSuitSlot()==h:getSuitString() then
			return h:getId()
		end
	end
end

-- Source olClan-ai.lua:1569
sgs.ai_skill_invoke.zugaoshi = function(self,data)
	return self:canDraw() or self:isWeak()
end

-- Source olClan-ai.lua:1594
sgs.ai_skill_invoke.zuyangji = function(self,data)
    local n = 0
	for _,h in ipairs(self.player:getHandcards())do
		if h:isBlack() and h:isAvailable(self.player) then
			if self:aiUseCard(h).card then n = n+1 end
		end
	end
	return n>=self.player:getHandcardNum()/3
end

-- Source olClan-ai.lua:1641
sgs.ai_skill_playerchosen.zujuetu = function(self, players)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist)
    for _,p in ipairs(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in ipairs(destlist)do
		if not self:isFriend(p)
		and #self.enemies>0
		then return p end
	end
end

-- Source olClan-ai.lua:1721
sgs.ai_skill_invoke.zujiannan = function(self,data)
	return self:canDraw() or self:isWeak()
end

-- Source olClan-ai.lua:1725
sgs.ai_skill_playerchosen.zujiannan = function(self, players)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist)
    for _,p in ipairs(destlist)do
		if mark(self,self.player,"zujiannan2-Clear")<1
		and self:isFriend(p) and self:canDraw(p)
		then return p end
	end
    for _,p in ipairs(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in ipairs(destlist)do
		if not self:isFriend(p)
		and #self.enemies>0
		then return p end
	end
end

-- Source olClan-ai.lua:1744
sgs.ai_skill_choice["zujiannan"] = function(self, choices, data)
	local items = choices:split("+")
	local to = data_value(self,"player")
    if self:isFriend(to) and table.contains(items,"zujiannan2")
	then return "zujiannan2" end
end

-- Source olClan-ai.lua:1751
sgs.ai_skill_cardask.zujiannan4 = function(self,data,pattern)
    local parsed = data_value(self,"player")
    if self:isFriend(parsed)
	or self:isWeak() then return true end
	return "."
end

-- Source olClan-ai.lua:1758
sgs.ai_skill_playerchosen.zuyichi = function(self, players)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist)
    for _,p in ipairs(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in ipairs(destlist)do
		if not self:isFriend(p)
		and #self.enemies>0
		then return p end
	end
end

-- Source olClan-ai.lua:1772
sgs.ai_skill_playerschosen.zufennu = function(self, players,x,n)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist)
	local tos = {}
    for _,p in ipairs(destlist)do
		if #tos<x and self:isEnemy(p) then table.insert(tos,p) end
	end
    for _,p in ipairs(destlist)do
		if #tos<x and not self:isFriend(p) and #self.enemies>0
		and not table.contains(tos,p) then table.insert(tos,p) end
	end
	return tos
end

-- Source olClan-ai.lua:1786
sgs.ai_skill_playerchosen.zuzelie = function(self, players)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist)
    for _,p in ipairs(destlist)do
		remember(self,"choice.zuzelie","zuzelie1")
		if self:isFriend(p) and self:canDraw(p)
		and mark(self,p,"&zuzelie1Bf-Clear")<1
		then return p end
	end
    for _,p in ipairs(destlist)do
		remember(self,"choice.zuzelie","zuzelie2")
		if self:isEnemy(p) and mark(self,p,"&zuzelie2Bf-Clear")<1
		then return p end
	end
    for _,p in ipairs(destlist)do
		remember(self,"choice.zuzelie","zuzelie1")
		if self:isFriend(p) and mark(self,p,"&zuzelie1Bf-Clear")<1
		then return p end
	end
    for _,p in ipairs(destlist)do
		remember(self,"choice.zuzelie","zuzelie2")
		if not self:isFriend(p) and mark(self,p,"&zuzelie2Bf-Clear")<1
		then return p end
	end
end

-- Source olClan-ai.lua:1832
sgs.ai_skill_invoke.zutanfeng = function(self,data)
	local to = data_value(self,"player")
	return self:isEnemy(to)
end

-- Source olClan-ai.lua:1837
sgs.ai_skill_cardask.zujuewei0 = function(self,data,pattern)
	local use = data_value(self,"use")
	if use.from==self.player then
		remember(self,"choice.zujuewei","zujuewei1")
		if self:isEnemy(use.to:first()) then return true end
	else
		remember(self,"choice.zujuewei","zujuewei2")
		if self:isWeak() then return true end
	end
	return "."
end

-- Source olClan-ai.lua:1849
sgs.ai_skill_playerschosen.zudingan = function(self, players)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist)
	local tps = {}
    for i,p in ipairs(destlist)do
		if i==#destlist or self:isFriend(p) and self:canDraw(p)
		then table.insert(tps,p) end
	end
	return tps
end

-- Source olClan-ai.lua:1882
sgs.ai_skill_invoke.zuheta = function(self,data)
	for i,c in ipairs(self:getTurnUse())do
		if c:isKindOf("BasicCard") or c:isNDTrick() then
			return true
		end
	end
end

-- Source olClan-ai.lua:1909
sgs.ai_skill_invoke.zuyingxiang = function(self,data)
	return true
end

-- Source olClan-ai.lua:1928
sgs.ai_skill_choice["zuyingxiang"] = function(self, choices, data)
	local items = choices:split("+")
	for _,s in ipairs(items)do
		if self.player:hasSkill(s,true) then
			return items[#items]
		end
	end
end

-- Source olClan-ai.lua:1937
sgs.ai_skill_invoke.zugezhi = function(self,data)
	local damage = data_value(self,"damage")
	return self:doDisCard(damage.to,"he")
end

-- Source olClan-ai.lua:2000
sgs.ai_skill_playerchosen.zushize = function(self, players)
	local destlist = copy_list(players)--将列表转换为表
	self:sortInPlace(destlist, nil, true)
    for _,p in ipairs(destlist)do
		if self:isFriend(p)
		then return p end
	end
end

-- Source olClan-ai.lua:2009
sgs.ai_skill_choice.zujianzhi = function(self,choices)
	local items = choices:split("+")
	if not self:isWeak() then return items[#items] end
end

-- Source olClan-ai.lua:2014
sgs.ai_skill_askforyiji.zujianzhi = function(self,card_ids,tos)
    return sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
end

-- Donor callbacks write these choices during selection, even if no target is
-- ultimately selected. Keep that observational state in this viewer only.
sgs.ai_skill_choice.zuzelie=function(self)return recall(self,"choice.zuzelie")end
sgs.ai_skill_choice.zujuewei=function(self)return recall(self,"choice.zujuewei")end

-- Zero-cost legacy prototypes and source target orchestration.
local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room)end
    return request
end
local function seed(self,skill,prototype,request)
    return self:legacySkillSeed(skill,prototype,action_request(self,request))
end
local function bind_selected(self,skill,prototype,input,use,request,costs,user_string)
    if use.card==input then
        local paid=self:bindSkillCard(skill,costs or {},action_request(self,request),user_string,prototype)
        use.card=self:inheritLegacyCardIdentity(paid,input)
    end
end

-- Source olClan-ai.lua:82
sgs.ai_fill_skill.zuguangu=function(self,inclusive,request)
    return seed(self,"zuguangu","#zuguanguCard",request)
end

-- Source olClan-ai.lua:86
local function select_zuguangu(card,use,self)
	if self.player:getChangeSkillState("zuguangu")==1 then
		use.card = card
	else
		self:sortInPlace(self.enemies, "handcard", true)
		for _,p in ipairs(self.enemies)do
			if p:getHandcardNum()>0 then
				use.card = card
				use.to:append(p)
				return
			end
		end
		for _,p in ipairs(self:sortInPlace(self.room:getOtherPlayers(self.player), "handcard", true))do
			if p:getHandcardNum()>0 and not self:isFriend(p) then
				use.card = card
				use.to:append(p)
				return
			end
		end
		self:sortInPlace(self.friends_noself, "handcard", true)
		for _,p in ipairs(self.friends_noself)do
			if p:getHandcardNum()>0 then
				use.card = card
				use.to:append(p)
				return
			end
		end
	end
end
sgs.ai_skill_use_func["#zuguanguCard"]=function(card,use,self,request)
    select_zuguangu(card,use,self)
    bind_selected(self,"zuguangu","#zuguanguCard",card,use,request)
end
sgs.ai_use_priority.zuguanguCard = 6.2
sgs.ai_use_value.zuguanguCard = 3.4

-- Source olClan-ai.lua:204
sgs.ai_fill_skill.zuyirong=function(self,inclusive,request)
	return seed(self,"zuyirong","#zuyirongCard",request)
end

-- Source olClan-ai.lua:208
local function select_zuyirong(card,use,self)
	local n = self.player:getHandcardNum()-self.player:getMaxCards()
	if n>0 then
		self:setPriorityValue("zuyirongCard",0.2,"zuyirong")
		if self.player:getHandcardNum()>3
		then use.card = card end
	else
		self:setPriorityValue("zuyirongCard",7.2,"zuyirong")
		use.card = card
	end
end
sgs.ai_skill_use_func["#zuyirongCard"]=function(card,use,self,request)
    select_zuyirong(card,use,self)
    bind_selected(self,"zuyirong","#zuyirongCard",card,use,request)
end

-- Source olClan-ai.lua:447
sgs.ai_fill_skill.kezuyunshen=function(self,inclusive,request)
	return seed(self,"kezuyunshen","#kezuyunshenCard",request)
end

-- Source olClan-ai.lua:451
local function select_kezuyunshen(card,use,self)
	self:sortInPlace(self.enemies, "hp")
	for _,ep in ipairs(self.enemies)do
		if not ep:isWounded() then
			use.card = card
			use.to:append(ep)
			remember(self,"choice.kezuyunshen","he")
			return
		end
	end
	for _,p in ipairs(self.friends_noself)do
		if self:isWeak(p) and not self:isWeak() then
			use.card = card
			use.to:append(p)
			remember(self,"choice.kezuyunshen","self")
			return
		end
	end
	for _,p in ipairs(self.friends_noself)do
		if p:isWounded() and self:getCardsNum("Jink")>0 then
			use.card = card
			use.to:append(p)
			remember(self,"choice.kezuyunshen","self")
			return
		end
	end
end
sgs.ai_skill_use_func["#kezuyunshenCard"]=function(card,use,self,request)
    select_kezuyunshen(card,use,self)
    bind_selected(self,"kezuyunshen","#kezuyunshenCard",card,use,request)
end
sgs.ai_use_priority.kezuyunshenCard = 6.2
sgs.ai_use_value.kezuyunshenCard = 3.4

-- Source olClan-ai.lua:496
sgs.ai_fill_skill.kezulieshi=function(self,inclusive,request)
	return #self.enemies>0
	and seed(self,"kezulieshi","#kezulieshiCard",request)
end

-- Source olClan-ai.lua:501
local function select_kezulieshi(card,use,self)
	if self.player:hasJudgeArea() and not self:isWeak() and self.player:isChained() then
		use.card = card
	else
		local n = 0
		for _, c in ipairs(self.player:getHandcards()) do
			if c:isKindOf("Slash") then n = n+1 end
		end
		if n<self:getCardsNum("Slash") then
			use.card = card
		end
	end
end
sgs.ai_skill_use_func["#kezulieshiCard"]=function(card,use,self,request)
    select_kezulieshi(card,use,self)
    bind_selected(self,"kezulieshi","#kezulieshiCard",card,use,request)
end
sgs.ai_use_priority.kezulieshiCard = 3.2
sgs.ai_use_value.kezulieshiCard = 3.4

-- Source olClan-ai.lua:1416
sgs.ai_fill_skill.zukaiji=function(self,inclusive,request)
	if mark(self,self.player,"sgszukaijiTo_lun")<1 then
		for _,h in ipairs(self.player:getHandcards())do
			if h:isAvailable(self.player) and self:aiUseCard(h).card then
				return seed(self,"zukaiji","#zukaijiCard",request)
			end
		end
	end
	return self:getOverflow()>0
	and seed(self,"zukaiji","#zukaijiCard",request)
end

-- Source olClan-ai.lua:1428
local function select_zukaiji(card,use,self)
	if mark(self,self.player,"sgszukaijiTo_lun")<1 then
		use.card = card
		use.to:append(self.player)
		return
	end
	self:sortInPlace(self.friends, nil, true)
	for _,p in ipairs(self.friends)do
		if mark(self,p,"sgszukaijiTo_lun")>0
		then continue end
		use.card = card
		use.to:append(p)
		break
	end
end
sgs.ai_skill_use_func["#zukaijiCard"]=function(card,use,self,request)
    select_zukaiji(card,use,self)
    bind_selected(self,"zukaiji","#zukaijiCard",card,use,request)
end
sgs.ai_use_priority.zukaijiCard = 11.2
sgs.ai_use_value.zukaijiCard = 3.4
sgs.ai_skill_choice.kezuyunshen=function(self)return recall(self,"choice.kezuyunshen")end

-- Disclosed physical-card response planners. Preserve the donor tag order and
-- evaluate only reached candidates. Read-only values cannot be submitted: the
-- chosen original ID is subsequently bound by its real native response scope.
local function notified_cards(self,skill)
    -- Source order is the viewer's own "<skill>ForAI" tag (Room::notifyMoveToPile);
    -- an absent tag is the donor's empty toIntList(). A face is used only while this
    -- viewer can see the card; notified-only faces are not projected.
    local ids=self.player:getTag(skill.."ForAI") or {}
    if not AIValue.isList(ids) then ai_unsupported("olClan notification tag malformed",skill) end
    local out={}
    for i,id in ipairs(ids)do
        if type(id)~="number" or id<0 or id%1~=0 then ai_unsupported("olClan notification tag malformed",skill) end
        out[i]=known(self:getKnownCardById(id) or self:getChoiceCard(id),"olClan.notified_card")
    end
    return AIList.new(out)
end
local function notified_evaluation(self,card)
    local projected,candidate=self:getAcquiredCardEvaluation(card)
    if not projected or not candidate then ai_unsupported("olClan physical-card evaluation is unavailable","notified")end
    return projected,candidate
end
local function notified_plan(self,card,candidate)
    local previous=self._evaluation_scope
    self._evaluation_scope={card=card,candidate=candidate}
    local ok,result=pcall(self.aiUseCard,self,card)
    self._evaluation_scope=previous
    if not ok then error(result,0)end
    return known(result,"olClan.notified_plan")
end
local function notified_answer(self,skill,card,targets,request)
    local use=AIUsePlan.new()
    use.card=self:bindSkillCard(skill,{card:getKnownEffectiveId()},action_request(self,request))
    use.to=targets
    return known(use:toAnswer(),"olClan.notified_answer")
end
local function choose_notified(self,skill,request,method,reverse)
    local cards=notified_cards(self,skill)
    AIValue.callKnown(self, method .. "InPlace", cards, reverse)
    for _,original in ipairs(cards)do
        local c,candidate=notified_evaluation(self,original)
        if c:isAvailable(self.player)then
            local use=notified_plan(self,c,candidate)
            if use.card then
                if c:canRecast() and #use.to<1 then continue end
                return notified_answer(self,skill,c,use.to,request)
            end
        end
    end
end
-- Source 136–155 and 1573–1592: descending use-value order, no RNG.
sgs.ai_skill_use["@@zuguangu"]=function(self,prompt,request)
    return choose_notified(self,"zuguangu",request,"sortByUseValue")
end
sgs.ai_skill_use["@@zugaoshi"]=function(self,prompt,request)
    return choose_notified(self,"zugaoshi",request,"sortByUseValue")
end
-- Source 582–601 / 701–720: the explicit *Ids tag and notification
-- contain the same ordered IDs at these native askForUseCard call sites.
sgs.ai_skill_use["@@kezuliuju"]=function(self,prompt,request)
    return choose_notified(self,"kezuliuju",request,"sortByKeepValue",true)
end
sgs.ai_skill_use["@@kezuhuanjia"]=function(self,prompt,request)
    return choose_notified(self,"kezuhuanjia",request,"sortByKeepValue",true)
end
-- Source 1447–1461: only the first original card; no availability precheck.
sgs.ai_skill_use["@@zukaiji"]=function(self,prompt,request)
    local cards=notified_cards(self,"zukaiji")
    local c,candidate=notified_evaluation(self,known(cards[1],"zukaiji.first_notified_card"))
    local use=notified_plan(self,c,candidate)
    if use.card then
        if c:canRecast() and #use.to<1 then return end
        return notified_answer(self,"zukaiji",c,use.to,request)
    end
end
-- Source 1490–1521: two ordered passes. The second canSlash probe and
-- enemy-before-neutral preference are retained even if aiUseCard declined.
sgs.ai_skill_use["@@zugaobian"]=function(self,prompt,request)
    if mark(self,self.player,"&zuanran+#num")>2 and has_skill(self,self.player,"kezuzhongliu")
        and not self:isWeak()then return end
    local cards=notified_cards(self,"zugaobian")
    for _,original in ipairs(cards)do
        local c,candidate=notified_evaluation(self,original)
        if c:isAvailable(self.player)then
            local use=notified_plan(self,c,candidate)
            if use.card then return notified_answer(self,"zugaobian",c,use.to,request)end
        end
    end
    for _,original in ipairs(cards)do
        local c=notified_evaluation(self,original)
        if c:isAvailable(self.player)then
            for _,p in ipairs(self.enemies)do
                if self.player:canSlash(p, c)then
                    return notified_answer(self,"zugaobian",c,AIList.new({p}),request)
                end
            end
            for _,p in ipairs(self.room:getAlivePlayers())do
                if not self:isFriend(p) and self.player:canSlash(p, c)then
                    return notified_answer(self,"zugaobian",c,AIList.new({p}),request)
                end
            end
        end
    end
end
-- Source 157–160, static final choice body.
sgs.ai_skill_choice.zuguangunum=function(self,choices)
    local items=choices:split("+");return items[#items]
end

-- Source 60–74 compares serialized policy cards, not object identity. Keep the
-- first matching later card and preserve nil versus false callback results.
sgs.ai_use_revises.zujiejian=function(self,card,use)
    local planned=known(self.toUse,"zujiejian.toUse")
    if #planned>1 then
        local selected=""
        for i,c in ipairs(planned)do
            if i>1 and c:nameLength()==mark(self,self.player,"&zujiejian-Clear")+1 then
                selected=c:getLegacyStringKey()
                break
            end
        end
        if selected~="" and selected~=card:getLegacyStringKey()then return false end
    end
end

-- Source 908–957. The donor mutates its fresh seed with at most one hand card;
-- collect that exact payment before binding the authoritative nonthrow product.
sgs.ai_fill_skill.kezufuxun=function(self,inclusive,request)
    return seed(self,"kezufuxun","#kezufuxunCard",request)
end
local function select_kezufuxun(card,use,self)
    for _,p in ipairs(self.enemies)do
        if mark(self,p,"&kezufuxunmove-PlayClear")<1
            and p:getHandcardNum()-self.player:getHandcardNum()==2 then
            use.to:append(p);use.card=card;return {}
        end
    end
    for _,p in ipairs(self.friends_noself)do
        if mark(self,p,"&kezufuxunmove-PlayClear")<1
            and p:getHandcardNum()-self.player:getHandcardNum()==-2 then
            local cards=copy_list(self.player:getCards("h"))
            if #cards<2 then continue end
            self:sortByKeepValueInPlace(cards)
            use.to:append(p);use.card=card;return {cards[1]:getKnownEffectiveId()}
        end
    end
    -- Retain the source's repeated third pass rather than silently deleting it.
    for _,p in ipairs(self.friends_noself)do
        if mark(self,p,"&kezufuxunmove-PlayClear")<1
            and p:getHandcardNum()-self.player:getHandcardNum()==-2 then
            local cards=copy_list(self.player:getCards("h"))
            if #cards<3 then continue end
            self:sortByKeepValueInPlace(cards)
            use.to:append(p);use.card=card;return {cards[1]:getKnownEffectiveId()}
        end
    end
    for _,p in ipairs(self.enemies)do
        if p:getHandcardNum()>0 then
            use.to:append(p);use.card=card;return {}
        end
    end
end
sgs.ai_skill_use_func["#kezufuxunCard"]=function(card,use,self,request)
    local costs=select_kezufuxun(card,use,self)
    bind_selected(self,"kezufuxun","#kezufuxunCard",card,use,request,costs)
end
sgs.ai_use_value.kezufuxunCard=3.4
sgs.ai_use_priority.kezufuxunCard=6.2

-- Source 805–834: count the actual ordered turn plan before scanning the roster.
sgs.ai_fill_skill.kezumingjie=function(self,inclusive,request)
    return seed(self,"kezumingjie","#kezumingjieCard",request)
end
local function select_kezumingjie(card,use,self)
    local damage,fixed=0,0
    for _,c in ipairs(known(self.toUse,"kezumingjie.toUse"))do
        if c:isKindOf("BasicCard") or c:isNDTrick()then
            if c:isDamageCard()then damage=damage+1
            elseif c:targetFixed()then fixed=fixed+1 end
        end
    end
    for _,p in ipairs(self.room:getAlivePlayers())do
        if mark(self,p,"&kezumingjie+#"..self.player:objectName())>0 then continue end
        if damage>0 and self:isEnemy(p) and not self.player:inMyAttackRange(p)then
            use.card=card;use.to:append(p);return
        end
        if fixed>1 and p~=self.player and self:isFriend(p)then
            use.card=card;use.to:append(p);return
        end
    end
end
sgs.ai_skill_use_func["#kezumingjieCard"]=function(card,use,self,request)
    select_kezumingjie(card,use,self)
    bind_selected(self,"kezumingjie","#kezumingjieCard",card,use,request)
end
sgs.ai_use_value.kezumingjieCard=3.4
sgs.ai_use_priority.kezumingjieCard=11.2

-- Source 1109–1148: retain `i>1 and Slash or NDTrick` precedence, including
-- the first planned non-delayed Trick. No sorting or random draw is introduced.
sgs.ai_fill_skill.kezuqiuxin=function(self,inclusive,request)
    return seed(self,"kezuqiuxin","#kezuqiuxinCard",request)
end
local function select_kezuqiuxin(card,use,self)
    for i,c in ipairs(known(self.toUse,"kezuqiuxin.toUse"))do
        if i>1 and c:isKindOf("Slash") or c:isNDTrick()then
            local planned=self:aiUseCard(c)
            if planned.card then
                for _,p in ipairs(planned.to)do
                    if mark(self,p,"&kezuqiuxinsha+#"..self.player:objectName())>0
                        or mark(self,p,"&kezuqiuxinjinnang+#"..self.player:objectName())>0
                        or p==self.player then continue end
                    use.card=card;use.to:append(p);return
                end
            end
        end
    end
    for _,p in ipairs(self.enemies)do
        if mark(self,p,"&kezuqiuxinsha+#"..self.player:objectName())>0
            or mark(self,p,"&kezuqiuxinjinnang+#"..self.player:objectName())>0 then continue end
        use.card=card;use.to:append(p);return
    end
    for _,p in ipairs(self.room:getOtherPlayers(self.player))do
        if self:isFriend(p) or mark(self,p,"&kezuqiuxinsha+#"..self.player:objectName())>0
            or mark(self,p,"&kezuqiuxinjinnang+#"..self.player:objectName())>0 then continue end
        use.card=card;use.to:append(p);return
    end
end
sgs.ai_skill_use_func["#kezuqiuxinCard"]=function(card,use,self,request)
    select_kezuqiuxin(card,use,self)
    bind_selected(self,"kezuqiuxin","#kezuqiuxinCard",card,use,request)
end
sgs.ai_use_value.kezuqiuxinCard=3.4
sgs.ai_use_priority.kezuqiuxinCard=9.2

-- Source 119/835/1061: these AG callbacks share exactly the same planning loop.
-- The remembered plan contains values only, never a candidate or native receipt.
local function remember_ag_plan(self,key,selected,plan)
    if key=="kezumingjieUse"or key=="kezulilunUse"then
        self:writeOlClanSavedSlot(key,plan,known(plan.card,"olClan.ag.card"));return
    end
    local targets={}
    for _,p in ipairs(known(plan.to,"olClan.ag.targets")) do targets[#targets+1]=p:objectName() end
    local card=known(plan.card,"olClan.ag.card")
    local estimates={}
    for _,entry in ipairs(self.request and self.request.scratch and self.request.scratch.knowledge_estimates or {}) do
        local copy={}
        for field,value in pairs(entry) do
            if type(value)=="string" or type(value)=="number" or type(value)=="boolean" then copy[field]=value end
        end
        estimates[#estimates+1]=copy
    end
    remember(self,key,{selected_id=selected:getEffectiveId(),card_id=card:getEffectiveId(),
        name=card:objectName(),suit=card:getSuit(),number=card:getNumber(),targets=targets,estimates=estimates})
end
local function select_ag_plan(self,ids,key)
    local cards={}
    for _,id in ipairs(ids) do cards[#cards+1]=known(self:getChoiceCard(id),"olClan.ag.offered_card") end
    self:sortByUseValueInPlace(cards)
    for _,card in ipairs(cards) do
        local projected,candidate=notified_evaluation(self,card)
        local plan=notified_plan(self,projected,candidate)
        if plan.card then
            if card:canRecast() and plan.to:isEmpty() then continue end
            remember_ag_plan(self,key,card,plan)
            return card:getEffectiveId()
        end
    end
    -- Source leaves a previously cached plan unchanged on failure.
    return -1
end
sgs.ai_skill_askforag.zuguangu=function(self,ids)return select_ag_plan(self,ids,"zuguanguUse")end
sgs.ai_skill_askforag.kezumingjie=function(self,ids)return select_ag_plan(self,ids,"kezumingjieUse")end
sgs.ai_skill_askforag.kezulilun=function(self,ids)return select_ag_plan(self,ids,"kezulilunUse")end

local function remembered_ag_answer(self,key,skill,request)
    local plan=self:readOlClanSavedSlot(key)
    if plan.card and plan.to then
        -- Source serializes its actual Card only after iterating actual targets.
        local tos={};for _,p in ipairs(plan.to)do tos[#tos+1]=p:objectName()end
        local source_wire=plan.card:toString()
        -- Selection alone binds the fresh native marked provider. Physical
        -- toString is just its ID; do not compare stale printed face snapshots.
        local paid=self:bindSkillCard(skill,{},action_request(self,request))
        if paid:getLegacyStringKey()~=source_wire then
            ai_unsupported("actual saved source wire differs from fresh marked native product",skill)
        end
        local use=AIUsePlan.new();use.card=paid
        for _,name in ipairs(tos)do use.to:append(known(self.room:findPlayerByObjectName(name,true),"olClan.ag.actual_target"))end
        return known(use:toAnswer(),"olClan.ag.answer")
    end
end
sgs.ai_skill_use["@@kezumingjiemark"]=function(self,prompt,request)
    return remembered_ag_answer(self,"kezumingjieUse","kezumingjiemark",request)
end
sgs.ai_skill_use["@@kezulilunuse"]=function(self,prompt,request)
    return remembered_ag_answer(self,"kezulilunUse","kezulilunuse",request)
end

-- Round21 remaining fill subtree, fixed source 722/1380/1680. The ordinary
-- hypotheses and SkillCard seeds carry no payment ticket until final selection.
local function remaining_preview(self,skill,name,costs)
    return self:evaluateOwnerViewAsCard({source_key=skill,skill=skill,name=name,
        suit=sgs.Card_NoSuit,number=0,subcards=costs})
end
local function remaining_seed(self,skill,prototype,costs,request,declared)
    return self:evaluateTurnSkillCard(skill, prototype, costs, action_request(self,request), declared)
end
local function remember_shengmo(self,plan)
    self.kezushengmoUse=plan
    local targets={};for _,p in ipairs(known(plan.to,"kezushengmo.to"))do targets[#targets+1]=p:objectName()end
    local estimates={}
    for _,entry in ipairs(self.request and self.request.scratch and self.request.scratch.knowledge_estimates or {})do
        local row={};for k,v in pairs(entry)do if type(v)~="table"then row[k]=v end end;estimates[#estimates+1]=row
    end
    remember(self,"kezushengmoUse",{card=self:capturePriorTurnPlan(plan.card),targets=targets,estimates=estimates})
end
local function shengmo_plan(self)
    if self.kezushengmoUse then return self.kezushengmoUse end
    local row=recall(self,"kezushengmoUse")
    if not row then error("fixed kezushengmo use_func has no previous plan",0)end
    for _,entry in ipairs(row.estimates or {})do
        local copy={};for k,v in pairs(entry)do copy[k]=v end;copy.status,copy.value="estimate",true
        self:useKnowledgeEstimate(copy,entry.context or "olClan.kezushengmo.cached")
    end
    local targets=AIList.new({})
    for _,name in ipairs(known(row.targets,"kezushengmo targets"))do
        targets:append(known(self.room:findPlayerByObjectName(name,true),"kezushengmo saved target"))
    end
    return {card=self:restorePriorTurnPlan(known(row.card,"kezushengmo saved card")),to=targets}
end

sgs.ai_fill_skill.kezujiexuan=function(self,inclusive,request)
    local n=self.player:getChangeSkillState("kezujiexuan")
    local name=n==1 and "snatch" or "dismantlement"
    local class=n==1 and "Snatch" or "Dismantlement"
    local can
    for i,c in ipairs(self:getPriorTurnUseCards())do
        if i>1 and self.room:getKnownCardPlace(c:getKnownEffectiveId())~=sgs.Player_PlaceHand then can=c;break end
    end
    local function make(id)
        -- Source dummyCard has NoSuit/0, which native derives from its sole
        -- material. Do not copy a product's printed face into constructor args.
        return self:evaluateTurnConversion("kezujiexuan", class, {name=name,skill="kezujiexuan",suit=sgs.Card_NoSuit,number=0,subcards={id}}, action_request(self,request))
    end
    if can then
        local cards=copy_list(self.player:getCards("he"));self:sortByKeepValueInPlace(cards)
        for _,c in ipairs(cards)do
            if c:getKnownEffectiveId()==can:getKnownEffectiveId()then continue end
            local dc=make(c:getKnownEffectiveId())
            -- Fixed donor tests RED here even in its yin/Dismantlement branch.
            -- Native yin requires black. Preserve first proposal and rejection.
            if dc:isRed() and dc:isAvailable(self.player)then return dc end
        end
    end
    local ids=self.player:getHandPile()
    for _,id in ipairs(ids)do
        if self.player:handCards():contains(id)then continue end
        local dc=make(id)
        if (AIValue.callKnown(dc, n==1 and "isRed" or "isBlack")) and dc:isAvailable(self.player)then return dc end
    end
    local cards=copy_list(self.player:getCards("e"));self:sortByKeepValueInPlace(cards)
    for _,e in ipairs(cards)do
        local dc=make(e:getKnownEffectiveId())
        if (AIValue.callKnown(dc, n==1 and "isRed" or "isBlack")) and dc:isAvailable(self.player)then return dc end
    end
end

sgs.ai_fill_skill.kezushengmo=function(self,inclusive,request)
    for _,pn in ipairs(known(AICardCatalog.patternNames(),"pattern_names"))do
        if mark(self,self.player,"kezushengmo_guhuo_remove_"..pn)>0 then continue end
        local dc=self:cloneEvaluationCard(pn)
        if dc and dc:getTypeId()==1 and self:getCardsNum(dc:getClassName())<1 then
            dc=remaining_preview(self,"kezushengmo",pn,{})
            if dc:isAvailable(self.player)then
                local d=self:aiUseCard(dc)
                if d.card then
                    if dc:canRecast() and d.to:isEmpty()then break end
                    remember_shengmo(self,d)
                    -- Intentional donor wrong-key write; do not repair to
                    -- kezushengmoCard or reset its original priority 9.2.
                    self:setPriorityValue("zuchengqiCard",self:getSourcePriorityValue(dc:getClassName()))
                    return remaining_seed(self,"kezushengmo","#kezushengmoCard",{},request,pn)
                end
            end
        end
    end
end
sgs.ai_skill_use_func["#kezushengmoCard"]=function(card,use,self)
    local ut=shengmo_plan(self)
    if ut.card then use.card=card;use.to=ut.to end
end
sgs.ai_use_value.kezushengmoCard=3.4
sgs.ai_use_priority.kezushengmoCard=9.2
sgs.ai_guhuo_card.kezushengmo=function(self,toname,class_name)
    if mark(self,self.player,"kezushengmo_guhuo_remove_"..toname)>0 or self:getCardsNum(class_name)>0 then return end
    return "#kezushengmoCard:.:"..toname
end

sgs.ai_fill_skill.zukudu=function(self,inclusive,request)
    local cards=copy_list(self.player:getCards("he"))
    self:sortByKeepValueInPlace(cards, nil, "j")
    local ids={}
    for _,c1 in ipairs(cards)do
        if self:wasPreviouslyPlannedCard(c1) or self:getKeepValue(c1)>6 then continue end
        ids[#ids+1]=c1:getKnownId()
        if #ids>1 then return remaining_seed(self,"zukudu","#zukuduCard",ids,request)end
    end
end
sgs.ai_skill_use_func["#zukuduCard"]=function(card,use,self)
    local tps=self:sort(self.room:getAlivePlayers())
    for i,p in ipairs(tps)do
        if i>#tps/2 and p~=self.player and self:isFriend(p)then use.to:append(p);use.card=card;return end
    end
end
sgs.ai_use_value.zukuduCard=3.4
sgs.ai_use_priority.zukuduCard=6.2
sgs.ai_skill_use["@@zukudu"]=function(self,prompt,request)
    local dc=sgs.ai_fill_skill.zukudu(self,nil,request)
    if dc then
        local dummy=self:aiUseCard(dc)
        if dummy.card then
            local names={};for _,p in ipairs(dummy.to)do names[#names+1]=p:objectName()end
            return dc:getLegacyStringKey().."->"..table.concat(names,"+")
        end
    end
end

-- Round21 A9 owner-material selection, fixed source 1002–1999.
-- All helpers above are existing package locals. Final action binding occurs
-- after the source has committed to its one ordered material/target proposal.
local function a_color(card)
    if card:isRed()then return "red"end
    if card:isBlack()then return "black"end
    return "colorless"
end
local function a_response(self,skill,prototype,ids,targets,request)
    local paid=self:bindSkillCard(skill,ids,action_request(self,request),nil,prototype)
    local use=AIUsePlan.new();use.card=paid
    for _,p in ipairs(targets or {})do use.to:append(p)end
    return known(use:toAnswer(),"olClan.owner_material_answer")
end

-- Source 1017: the original zero-cost card is allocated before scanning. Its
-- selected material mutation preserves that strategy identity, not its ticket.
sgs.ai_fill_skill.kezulilun=function(self,inclusive,request)
    local dc=seed(self,"kezulilun","#kezulilunCard",request)
    local cards=copy_list(self.player:getCards("he"))
    self:sortByDynamicUsePriorityInPlace(cards)
    local function selected(h,r)
        local result=remaining_seed(self,"kezulilun","#kezulilunCard",{h:getKnownEffectiveId(),r:getKnownEffectiveId()},request)
        return self:inheritLegacyCardIdentity(result,dc)
    end
    for _,h in ipairs(cards)do
        if self.player:isCardLimited(h, sgs.Card_MethodRecast)then continue end
        if h:isAvailable(self.player)then
            local d=self:aiUseCard(h)
            if d.card then
                for _,r in ipairs(cards)do
                    if self.player:isCardLimited(r, sgs.Card_MethodRecast)then continue end
                    if not AIValue.sameLegacyIdentity(h,r) and h:sameNameWith(r)then return selected(h,r)end
                end
            end
        end
    end
    self:sortByKeepValueInPlace(cards)
    for i,h in ipairs(cards)do
        if i>#cards/2 or self:wasPreviouslyPlannedCard(h)
            or self.player:isCardLimited(h, sgs.Card_MethodRecast)then continue end
        for _,r in ipairs(cards)do
            if self.player:isCardLimited(r, sgs.Card_MethodRecast)then continue end
            if not AIValue.sameLegacyIdentity(h,r) and h:sameNameWith(r)then return selected(h,r)end
        end
    end
end
sgs.ai_skill_use_func["#kezulilunCard"]=function(card,use,self)use.card=card end
sgs.ai_use_value.kezulilunCard=3.4
sgs.ai_use_priority.kezulilunCard=11.2

-- Source1002: name length compares to current hand count; sorted upper half
-- exclusion is evaluated before Recast legality and length.
sgs.ai_skill_use["@@kezuchenyacz"]=function(self,prompt,request)
    local cards=copy_list(self.player:getCards("he"));self:sortByKeepValueInPlace(cards)
    local valid={}
    for i,h in ipairs(cards)do
        if i>#cards/2 or self.player:isCardLimited(h, sgs.Card_MethodRecast)
            or h:nameLength()~=self.player:getHandcardNum()then continue end
        valid[#valid+1]=h:getKnownEffectiveId()
    end
    if #valid<1 then return end
    return a_response(self,"kezuchenyacz","#kezuchenyaCard",valid,{},request)
end
-- Source1170: same ordered mechanics but a distinct source mark and scope.
sgs.ai_skill_use["@@kezujianyuancz"]=function(self,prompt,request)
    local cards=copy_list(self.player:getCards("he"));self:sortByKeepValueInPlace(cards)
    local valid={}
    for i,h in ipairs(cards)do
        if i>#cards/2 or self.player:isCardLimited(h, sgs.Card_MethodRecast)
            or h:nameLength()~=mark(self,self.player,"sgsjianyuantimes-PlayClear")then continue end
        valid[#valid+1]=h:getKnownEffectiveId()
    end
    if #valid<1 then return end
    return a_response(self,"kezujianyuancz","#kezujianyuanCard",valid,{},request)
end
-- Source1626: one first card per suit, covering every hand suit. There is no
-- invented keep threshold, and final native selection validates the coverage.
sgs.ai_skill_use["@@zujuetu!"]=function(self,prompt,request)
    local cards=copy_list(self.player:getCards("h"));self:sortByKeepValueInPlace(cards)
    local valid,suits={},{}
    for _,h in ipairs(cards)do
        local suit=h:getSuit()
        if table.contains(suits,suit)then continue end
        valid[#valid+1]=h:getKnownEffectiveId();suits[#suits+1]=h:getSuit()
    end
    if #valid<1 then return end
    return a_response(self,"zujuetu","#zujuetuCard",valid,{},request)
end
-- Source1860: source thresholds are not the provider's LostHp threshold.
-- Preserve a native rejection if the first chosen source cost count differs.
sgs.ai_skill_use["@@zufuning"]=function(self,prompt,request)
    local cards=copy_list(self.player:getCards("he"));self:sortByKeepValueInPlace(cards)
    local valid,first={},nil
    for _,h in ipairs(cards)do
        if #valid>0 and self:isWeak()then
            if a_color(h)~=a_color(first)then continue end
        end
        valid[#valid+1]=h:getKnownId();if not first then first=h end
        if #valid>mark(self,self.player,"zufuningDoneNum-Clear") or #valid>#cards/2 then break end
    end
    if #valid<1 then return end
    self:sortInPlace(self.friends_noself)
    for _,p in ipairs(self.friends_noself)do
        if self:canDraw(p)then return a_response(self,"zufuning","#zufuningCard",valid,{p},request)end
    end
end
-- Source1962 and1977 intentionally differ only by the previous-plan exclusion.
sgs.ai_skill_use["@@zumingdian"]=function(self,prompt,request)
    local cards=copy_list(self.player:getCards("he"));self:sortByKeepValueInPlace(cards)
    local valid={}
    for _,h in ipairs(cards)do
        if h:getTypeId()~=1 or mark(self,self.player,h:objectName().."zumingdianRecast_lun")>0
            or self.player:isCardLimited(h, sgs.Card_MethodRecast)then continue end
        valid[#valid+1]=h:getKnownId()
        if #valid>=#cards/2 then break end
    end
    if #valid<1 then return end
    return a_response(self,"zumingdian","#zumingdianCard",valid,{},request)
end
sgs.ai_fill_skill.zumingdian=function(self,inclusive,request)
    local cards=copy_list(self.player:getCards("he"));self:sortByKeepValueInPlace(cards)
    local valid={}
    for _,h in ipairs(cards)do
        if h:getTypeId()~=1 or mark(self,self.player,h:objectName().."zumingdianRecast_lun")>0
            or self:wasPreviouslyPlannedCard(h) or self.player:isCardLimited(h, sgs.Card_MethodRecast)then continue end
        valid[#valid+1]=h:getKnownId()
        if #valid>=#cards/2 then break end
    end
    if #valid<1 then return end
    return remaining_seed(self,"zumingdian","#zumingdianCard",valid,request)
end
sgs.ai_skill_use_func["#zumingdianCard"]=function(card,use,self)use.card=card end
sgs.ai_use_value.zumingdianCard=3.4
sgs.ai_use_priority.zumingdianCard=2.8


-- Round22 B/C/F: exact fixed olClan source branches. Root merges this scope.
do
local known = AIValue.requireKnown

local function cards(self,zone)
    local out={};for _,c in ipairs(self.player:getCards(zone))do out[#out+1]=c end
    return out
end
local function has_parent(self,player)
    local value=player:hasSkill('zulianzhu')
    local row=rawget(player,'_view')
    if value==true or value~=nil and (not row or row.skills_complete==true)then return value end
    if player:objectName()==self.player:objectName()then ai_unsupported('owner parent roster is incomplete','zulianzhu')end
    return self:useKnowledgeEstimate({status='estimate',value=false,basis='olClan.undisclosed_skill_uses_public_roster',target=player:objectName(),skill='zulianzhu'},'olClan.skills')
end
local function hypothesis(self,key,name,skill,costs)
    return self:evaluateOwnerViewAsCard({source_key=key,name=name,skill=skill,suit=sgs.Card_NoSuit,number=0,subcards=costs})
end
local function empty(self,key,prototype,request)
    return self:evaluateTurnSkillCard(key, prototype, {}, request)
end
local function recast_card(self,card,cost,request)
    local next_card=self:evaluateTurnSkillCard('zulianzhuvs', '#zulianzhuCard', {cost:getKnownEffectiveId()}, request)
    return self:inheritLegacyCardIdentity(next_card, card)
end
-- 186: construct each exact material hypothesis before availability. The first
-- available policy is returned; only the common final selection can pay it.
sgs.ai_fill_skill.zuzhanding=function(self,inclusive,request)
    if self:getCardsNum('Slash')>0 and self.player:getHandcardNum()>self.player:getMaxCards()then return end
    local hand=self:sortByKeepValueInPlace(cards(self,'he'))
    for _,material in ipairs(hand)do
        local slash=self:evaluateTurnConversion('zuzhanding', 'Slash', {name='slash',skill='zuzhanding',suit=sgs.Card_NoSuit,number=0,subcards={material:getKnownEffectiveId()}}, request)
        if slash:isAvailable(self.player)then return slash end
    end
end
-- 222/226: native normalizes the registered zulianzhuvs& to zulianzhuvs.
sgs.ai_fill_skill.zulianzhuvs=function(self,inclusive,request)
    return empty(self,'zulianzhuvs','#zulianzhuCard',request)
end
sgs.ai_skill_use_func['#zulianzhuCard']=function(card,use,self,request)
    self:sortInPlace(self.enemies, 'handcard')
    for _,p in ipairs(self:sort(self.room:getAlivePlayers(), 'handcard', true))do
        if has_parent(self,p) and self:isFriend(p)then
            local state=p:getChangeSkillState('zulianzhu')
            if state==1 then
                local hand=cards(self,'he')
                if #hand>2 and p:getCardCount()>2 then
                    self:sortByKeepValueInPlace(hand)
                    for _,c in ipairs(hand)do
                        if self.player:isCardLimited(c, sgs.Card_MethodRecast)then continue end
                        use.card=recast_card(self,card,c,request);use.to:append(p);return
                    end
                end
            else
                for _,ep in ipairs(self.enemies)do
                    if self.player:canSlash(ep, nil, false) and p:canSlash(ep, nil, false)then
                        use.card=card;use.to:append(p)
                        self:writeOlClanPlayerSlot('zulianzhuEp',ep);return
                    end
                end
            end
        end
    end
    for _,p in ipairs(self:sort(self.room:getAlivePlayers(), 'handcard'))do
        if has_parent(self,p) and not self:isFriend(p)then
            local state=p:getChangeSkillState('zulianzhu')
            if state==1 then
                local hand=cards(self,'he')
                if #hand>2 and p:getCardCount()>0 then
                    self:sortByKeepValueInPlace(hand)
                    for _,c in ipairs(hand)do
                        if self.player:isCardLimited(c, sgs.Card_MethodRecast)then continue end
                        use.card=recast_card(self,card,c,request);use.to:append(p);return
                    end
                end
            else
                for _,ep in ipairs(self.enemies)do
                    if self.player:canSlash(ep, nil, false) and p~=ep then
                        use.card=card;use.to:append(p)
                        self:writeOlClanPlayerSlot('zulianzhuEp',ep);return
                    end
                end
            end
        end
    end
end
-- 603/607: the donor intentionally leaves the final SkillCard empty. Do not
-- transfer the one-card AmazingGrace probe material into its final payment.
sgs.ai_fill_skill.kezuxumin=function(self,inclusive,request)return empty(self,'kezuxumin','#kezuxuminCard',request)end
sgs.ai_skill_use_func['#kezuxuminCard']=function(card,use,self)
    local hand=self:sortByKeepValueInPlace(cards(self,'he'))
    for _,h in ipairs(hand)do
        local grace=hypothesis(self,'kezuxumin','amazing_grace','kezuxumin',{h:getKnownEffectiveId()})
        if grace:isAvailable(self.player)then
            local can=false
            for _,p in ipairs(self.friends_noself)do
                if self.player:isProhibited(p, grace) or use.to:contains(p)then continue end
                use.to:append(p)
                if self:isWeak(p)then can=true end
            end
            if can then use.card=card else break end
        end
    end
end
-- 875/879: weak enemy early return precedes the ThunderSlash hypothesis.
sgs.ai_fill_skill.kezubolong=function(self,inclusive,request)return empty(self,'kezubolong','#kezubolongCard',request)end
sgs.ai_skill_use_func['#kezubolongCard']=function(card,use,self)
    for _,p in ipairs(self.enemies)do
        if self:isWeak(p)then use.to:append(p);use.card=card;return end
    end
    local dc=hypothesis(self,'kezubolong','thunder_slash','kezubolong',{})
    local d=self:aiUseCard(dc)
    if d.card then
        for _,p in ipairs(d.to)do use.to:append(p);use.card=card;return end
    end
end
-- 1604: select the original physical hand card, even if dummy.card was revised.
sgs.ai_skill_use.zuyangji0=function(self,prompt)
    local hand={}
    for _,h in ipairs(self.player:getHandcards())do if h:isBlack()then hand[#hand+1]=h end end
    self:sortByUseValueInPlace(hand)
    for _,c in ipairs(hand)do
        if c:isAvailable(self.player)then
            local dummy=self:aiUseCard(c)
            if dummy.card then
                local to={};for _,p in ipairs(dummy.to)do to[#to+1]=p end
                if c:canRecast()and #to<1 then continue end
                local answer=AIUsePlan.new();answer.card=c
                for _,p in ipairs(to)do answer.to:append(p)end
                return answer:toAnswer()
            end
        end
    end
end
-- 1814/1818: Qinggang is put on an issued native detached clone by the finite
-- source constructor, then retained in its sealed recipe. No live flag write.
sgs.ai_fill_skill.zutanfeng=function(self,inclusive,request)return empty(self,'zutanfeng','#zutanfengCard',request)end
sgs.ai_skill_use_func['#zutanfengCard']=function(card,use,self)
    local dc=hypothesis(self,'zutanfeng','slash','',{})
    local d=self:aiUseCard(dc)
    if d.card then use.card=card;use.to:append(d.to:first());return end
end
sgs.ai_use_value.zulianzhuCard=3.4;sgs.ai_use_priority.zulianzhuCard=5.2
sgs.ai_use_value.kezuxuminCard=3.4;sgs.ai_use_priority.kezuxuminCard=4.2
sgs.ai_use_value.kezubolongCard=3.4;sgs.ai_use_priority.kezubolongCard=3.2
sgs.ai_use_value.zutanfengCard=3.4;sgs.ai_use_priority.zutanfengCard=2.8

end


-- Fixed b6025acc olClan-ai.lua D12. Self-contained registration fragment.
do
local known = AIValue.requireKnown

local function copy(xs)local out={};for _,x in ipairs(known(xs,'list'))do out[#out+1]=x end;return out end
local function sorted(self,zone,method)
 local cs=copy(self.player:getCards(zone));self[method](self,cs);return cs
end
local function scoped(self,key)
 local context=self:getDecisionContext()
 local row=type(context)=='table'and context.olclan_plan
 if type(row)~='table'then ai_unsupported('olClan D scoped observation absent',key)end
 local value=row[key]
 if value==nil then ai_unsupported('olClan D scoped observation absent',key)end
 return value
end
local function patterns(self)return known(AICardCatalog.patternNames(),'pattern_names')end
local function clone(self,name)
 -- The only non-card choice emitted by ny_shenjun's fixed native writer.
 if name=='cancel'then return nil end
 return self:cloneEvaluationCard(name)
end
local function preview(self,key,name,skill,costs,previous)
 local dc=self:evaluateOwnerViewAsCard({source_key=key,name=name,skill=skill,suit=sgs.Card_NoSuit,number=0,subcards=copy(costs)})
 if previous then dc=self:inheritLegacyCardIdentity(dc,previous)end
 return dc
end
local function names(targets)local out={};for _,p in ipairs(targets)do out[#out+1]=p:objectName()end;return out end
local function wire(card,targets)return card:getLegacyStringKey()..'->'..table.concat(names(targets),'+')end
-- Fixed source assignments write the same actual own LuaAI slots. No cached
-- strategy copy overrides a subsequent real slot mutation or error prefix.
local function save(self,key,plan)
 return self:writeOlClanSavedSlot(key,plan,plan.card)
end
local function saved(self,key)
 return self:readOlClanSavedSlot(key)
end

local function current_request(self,r)if r and type(r.getActivationSkillName)~='function'then return AILegacyRequest.new(r,self.room)end;return r end
local function seed(self,ids,r)return self:evaluateTurnSkillCard('zuchengqi','#zuchengqiCard',ids,current_request(self,r))end

-- 351 / 370: choosing a name and the later actual use independently sort and
-- select their own materials. They must not share a payment receipt.
sgs.ai_skill_choice.ny_shenjun=function(self,choices,data)
 local cards=copy(self.player:getHandcards());self:sortByUseValue(cards)
 for _,ch in ipairs(choices:split('+'))do
  local base=clone(self,ch)
  if not base then continue end
  local n=self.player:getMark('ny_shenjun');local ids={}
  for _,h in ipairs(cards)do ids[#ids+1]=h:getKnownEffectiveId();if #ids>=n then break end end
  local dc=preview(self,'ny_shenjun',ch,'ny_shenjun',ids,base)
  local d=self:aiUseCard(dc)
  if d.card then return ch end
 end
 return 'cancel'
end
sgs.ai_skill_use['@@ny_shenjun']=function(self,prompt)
 local n=self.player:getMark('ny_shenjun');local cards=copy(self.player:getCards('h'))
 if n>#cards/2 then return end
 local name=scoped(self,'ny_shenjun');local base=clone(self,name)
 self:sortByKeepValue(cards);local ids={}
 for _,h in ipairs(cards)do ids[#ids+1]=h:getKnownEffectiveId();if #ids>=n then break end end
 local dc=preview(self,'ny_shenjun',name,'ny_shenjun',ids,base)
 local d=self:aiUseCard(dc)
 if d.card then
  local tos=names(d.to)
  if dc:canRecast()and #tos<1 then return end
  return dc:getLegacyStringKey()..'->'..table.concat(tos,'+')
 end
end
-- 959: offered products first, then owner he materials. isLocked must be read
-- BEFORE the half-list test, even for later materials.
sgs.ai_skill_askforag.kezufuxun=function(self,ids)
 local offered={};for _,id in ipairs(ids)do offered[#offered+1]=known(self:getChoiceCard(id),'offered card')end
 self:sortByUseValue(offered);local cards=sorted(self,'he','sortByKeepValue')
 for _,c in ipairs(offered)do for i,h in ipairs(cards)do
  local dc=preview(self,'kezufuxun',c:objectName(),'_kezufuxun',{h:getKnownEffectiveId()})
  if self.player:isLocked(dc)or i>#cards/2 then continue end
  local d=self:aiUseCard(dc)
  if d.card then
   if c:canRecast()and d.to:isEmpty()then continue end
   save(self,'kezufuxunUse',d);return c:getKnownEffectiveId()
  end
 end end
 return -1
end
sgs.ai_skill_use['@@kezufuxunbasic']=function(self,prompt)
 local d=saved(self,'kezufuxunUse');if d.card and d.to then return wire(d.card,d.to)end
end
sgs.ai_skill_use['@@kezujianji']=function(self,prompt)
 local dc=preview(self,'kezujianji','slash','kezujianji',{})
 local d=self:aiUseCard(dc);if d.card and d.to then return wire(d.card,d.to)end
end
-- 1150: exact source +99 dummy target hypothesis; no extra distance flag.
sgs.ai_skill_askforag.kezuqiuxin=function(self,ids)
 local offered={};for _,id in ipairs(ids)do offered[#offered+1]=known(self:getChoiceCard(id),'offered card')end
 self:sortByUseValue(offered)
 local name=scoped(self,'kezuqiuxinTo');local to=name~=false and known(self.room:findPlayerByObjectName(name),'Qiuxin target')or nil
 for _,c in ipairs(offered)do
  local dc=preview(self,'kezuqiuxin',c:objectName(),'_kezuqiuxin',{})
  if dc:targetFixed()or(to~=nil and self:isEnemy(to))then
   local use=AIUsePlan.new();use.isDummy=true;use.extra_target=99;use.current_targets={}
   local d=self:aiUseCard(dc,use)
   if d.card and d.to:contains(to)then return c:getKnownEffectiveId()end
  end
 end
 return -1
end
-- 1190: the recast break exits ONLY the inner loop, without clearSubcards.
-- Therefore accumulated/repeated costs on the next h are deliberate donor
-- semantics; readonly permits this finite history, final native payment does not.
sgs.ai_fill_skill.zuchengqi=function(self,inclusive,request)
 for pass=1,2 do
  for _,pn in ipairs(patterns(self))do
   if self.player:getMark(pn..'zuchengqiUse-Clear')<1 then
    local dc=clone(self,pn)
    if dc and(dc:isNDTrick()or dc:getTypeId()==1)
     and(pass==2 or dc:isDamageCard())and self:getCardsNum(dc:getClassName())<1 then
     local m=dc:nameLength();local cards=sorted(self,'h','sortByKeepValue');local costs={}
     for _,h in ipairs(cards)do local x=h:nameLength()
      for _,c in ipairs(cards)do
       if AIValue.sameLegacyIdentity(h,c)then continue end
       if x+c:nameLength()>=m then
        costs[#costs+1]=h:getKnownEffectiveId();costs[#costs+1]=c:getKnownEffectiveId()
        dc=preview(self,'zuchengqi',pn,'zuchengqi',costs,dc)
        if dc:isAvailable(self.player)then
         local d=self:aiUseCard(dc)
         if d.card then
          if dc:canRecast()and d.to:isEmpty()then break end
          save(self,'zuchengqiUse',d)
          self:setPriorityValue('zuchengqiCard',self:getSourcePriorityValue(dc:getClassName()),'olClan.zuchengqi')
          return seed(self,{h:getKnownId(),c:getKnownId()},request)
         end
        end
        costs={}
       end
      end
     end
    end
   end
  end
 end
end
sgs.ai_skill_use_func['#zuchengqiCard']=function(card,use,self)use.card=card end
sgs.ai_use_value.zuchengqiCard=3.4
sgs.ai_use_priority.zuchengqiCard=9.2
sgs.ai_skill_use['@@zuchengqi']=function(self,prompt)
 local d=saved(self,'zuchengqiUse');if d.card and d.to then return wire(d.card,d.to)end
end
sgs.ai_guhuo_card.zuchengqi=function(self,name,class_name)
 if self.player:getMark(name..'zuchengqiUse-Clear')>0 or self:getCardsNum(class_name)>0 then return end
 local dc=clone(self,name)
 if dc and(dc:isNDTrick()or dc:getTypeId()==1)then
  local m=dc:nameLength();local cards=sorted(self,'h','sortByKeepValue')
  for _,h in ipairs(cards)do local x=h:nameLength()
   for _,c in ipairs(cards)do
    if AIValue.sameLegacyIdentity(h,c)then continue end
    if x+c:nameLength()>=m then
     dc=preview(self,'zuchengqi',name,'zuchengqi',{h:getKnownEffectiveId(),c:getKnownEffectiveId()},dc)
     if not self.player:isLocked(dc)then return dc:getLegacyStringKey()end
    end
   end
  end
 end
end
sgs.ai_skill_use['@@zujuetu1!']=function(self,prompt)
 local dc=preview(self,'zujuetu','dismantlement','_zujuetu',{self.player:getMark('zujuetuId')})
 local d=self:aiUseCard(dc)
 if d.card then return wire(dc,d.to)end
 for _,p in ipairs(self.enemies)do if self.player:canUse(dc, p)then return wire(dc,{p})end end
 for _,p in ipairs(self.room:getAlivePlayers())do if not self:isFriend(p)and #self.enemies>0 then return wire(dc,{p})end end
 for _,p in ipairs(self.room:getAlivePlayers())do if not self:isFriend(p)then return wire(dc,{p})end end
end
sgs.ai_skill_use['@@zuyingxiang!']=function(self,prompt)
 local dc=preview(self,'zuyingxiang',scoped(self,'zuyingxiangCn'),'_zuyingxiang',{})
 local d=self:aiUseCard(dc)
 if d.card then return wire(dc,d.to)end
 for _,p in ipairs(self.room:getAlivePlayers())do if self.player:canUse(dc, p)then return wire(dc,{p})end end
end
end


-- Round22 olClan E: fixed b6025 source-scoped observations, eight callbacks.
do
local known = AIValue.requireKnown

local function optional(object,method,...)
    if type(object)~="table" or type(object[method])~="function"then ai_unsupported("olClan E helper is unavailable",method)end
    local value=object[method](object,...);if AIUnsupported.is(value)then error(value,0)end;return value
end
local function row(self,key)
    local context=self:getDecisionContext()
    local rows=context.olclan_observations
    local r=type(rows)=="table"and rows[key]
    if type(r)~="table"or r.known~=true then ai_unsupported("olClan current question observation is incomplete",key)end
    return r.value
end
local function player(self,name)
    if name==nil or name==false then return nil end
    return known(self.room:findPlayerByObjectName(name,true),"olClan.observed_player")
end
local function cardq(card,method,...)
    if card==nil then error("attempt to index a nil card",0)end
    return AIValue.callKnown(card, method, ...)
end
local function use_data(self,key)
    local raw=known(row(self,key),key)
    local use={from=player(self,raw.from),to=AIList.new({})}
    if raw.card~=nil then use.card=CardView.new(raw.card)end
    for _,name in ipairs(raw.to or {})do use.to:append(player(self,name))end
    return use
end
local function list(values)
    local out={};for i,v in ipairs(known(values,"olClan.list"))do out[i]=v end
    return AIList.new(out)
end
local function sort(self,values,method,...)
    local sorted=AIValue.callKnown(self, method, values, ...)
    for i,v in ipairs(sorted)do values[i]=v end
    return values
end
local function faces(self,key)
    local cards=AIList.new({})
    for _,face in ipairs(known(row(self,key),key))do
        local disclosed=CardView.new(face)
        local evaluated=self:getAcquiredCardEvaluation(disclosed)
        -- The native evaluator returns this same physical object identity.
        -- Notification printed metadata has no token to inherit or fabricate.
        local token=evaluated:getLegacyIdentityToken()
        if evaluated:getKnownEffectiveId()~=disclosed:getKnownEffectiveId()
            or evaluated:isVirtualCard()~=false
            or type(token)~="string" or token=="" then
            ai_unsupported("notification evaluation changed physical identity",key)
        end
        cards:append(evaluated)
    end
    return cards
end
local function answer(self,skill,costs,targets,request)
    if request and type(request.getActivationSkillName)~="function"then request=AILegacyRequest.new(request,self.room)end
    local card=self:bindSkillCard(skill, costs, request, nil, "#"..skill.."Card")
    local use=AIUsePlan.new();use.card=card
    for _,p in ipairs(targets or {})do use.to:append(p)end
    return known(use:toAnswer(),"olClan.E.answer")
end

-- Source412: counts of hidden hand cards are public; never enumerate their faces.
sgs.ai_skill_playerchosen.ny_sankuang=function(self,targets)
    local use=use_data(self,"ny_sankuang_use")
    local give=cardq(use.card,"subcardsLength") -- known-empty source retains nil-card error
    if self.player:hasSkill("kezudaojie") and not cardq(use.card,"isDamageCard")
        and use.card:isKindOf("TrickCard") and self.player:getMark("kezudaojie-Clear")==0 then give=0 end
    local max=-99;local rtarget
    for _,target in ipairs(targets)do
        local min=0
        if #target:getCards("ej")>0 then min=min+1 end
        if target:isWounded()then min=min+1 end
        if target:getHandcardNum()>target:getHp()then min=min+1 end
        min=math.min(min,target:getHandcardNum()+#target:getEquips())
        local value=min*1.2-give
        if self:isFriend(target)then value=-value end
        if value>max then max=value;rtarget=target end
    end
    return rtarget
end
-- Source482: damage comes from the real SkillInvoke data, not a stale room tag.
sgs.ai_skill_invoke.kezushangshen=function(self,data)
    local damage=known(self:getDecisionData().toDamage(),"kezushangshen.damage")
    if self:isFriend(damage.to)and damage.to:getHandcardNum()<4 then
        local to=player(self,row(self,"fenchaiPlayer"))
        if to and to:isAlive()and self.player:hasSkill("kezufenchai")then return true end
        local finalRetrial=self:getFinalRetrial(nil,"lightning")
        known(finalRetrial,"kezushangshen.finalRetrial")
        if finalRetrial<2 then return not to or to:isAlive()or not self.player:hasSkill("kezufenchai")end
    end
end
-- Source541: preserve the two separately ordered passes.
sgs.ai_skill_playerchosen.kezufangzhen=function(self,players)
    local dest=list(players);sort(self,dest,"sort","hp")
    for _,target in ipairs(dest)do
        if self:isFriend(target)and target:getSeat()<=known(row(self,"TurnLengthCount"),"TurnLengthCount")then return target end
    end
    for _,target in ipairs(dest)do if self:isFriend(target)and self:isWeak(target)then return target end end
end
-- Source659: the friend/zero clause intentionally does not add a first card.
sgs.ai_skill_discard.kezulianhe=function(self,n,x)
    local from=player(self,row(self,"kezulianheFrom"));local cards={}
    for _,h in ipairs(self:poisonCards("he"))do
        cards[#cards+1]=h:getKnownEffectiveId();if #cards>=n then break end
    end
    local handcards=list(self.player:getCards("he"));sort(self,handcards,"sortByKeepValue")
    for _,h in ipairs(handcards)do
        if not(self:isFriend(from)and #cards<1 or #cards>=n or table.contains(cards,h:getKnownEffectiveId()))then
            cards[#cards+1]=h:getKnownEffectiveId()
        end
    end
    return cards
end
-- Source863: explicit actual input string, no modern-tag substitution.
sgs.ai_skill_invoke.kezumingjie=function(self,data)
    local st=known(row(self,"invoke_string"),"kezumingjie.string")
    local sts=st:split(":");local to=player(self,sts[2]);local use=use_data(self,"kezumingjieData")
    if self:isFriend(to)and cardq(use.card,"targetFixed")then return true
    elseif self:isEnemy(to)and cardq(use.card,"isDamageCard")then return true end
end
-- Source1332: costs stay h,c pairs and preserve both sort direction predicates.
sgs.ai_skill_use["@@zujieli"]=function(self,prompt,request)
    local valid={};local cards=faces(self,"zujieliForAI");local cns=faces(self,"zujieliNForAI")
    local to=self:readOlClanPlayerSlot("zujieliTo")
    sort(self,cards,"sortByKeepValue",self:isEnemy(to))
    sort(self,cns,"sortByKeepValue",self:isFriend(to))
    for _,h in ipairs(cards)do for _,c in ipairs(cns)do
        if not table.contains(valid,c:getKnownEffectiveId())then
            if self:isFriend(to)then
                if self:getKeepValue(c)>self:getKeepValue(h)then valid[#valid+1]=h:getKnownEffectiveId();valid[#valid+1]=c:getKnownEffectiveId();break end
            elseif self:getKeepValue(c)<self:getKeepValue(h)then valid[#valid+1]=h:getKnownEffectiveId();valid[#valid+1]=c:getKnownEffectiveId();break end
        end
    end end
    if #valid<1 then return end
    return answer(self,"zujieli",valid,{},request)
end
-- Source1890: preserve current target membership and canCanmou use descriptor.
sgs.ai_skill_playerschosen.zuheta=function(self,players)
    local dest=list(players);sort(self,dest,"sort");local tps={};local use=use_data(self,"zuheta_data")
    for _,p in ipairs(dest)do
        if use.to:contains(p)then
            if cardq(use.card,"isDamageCard")then if self:isFriend(p)and self:isWeak(p)then tps[#tps+1]=p end end
        elseif optional(self,"canCanmou",p,use)then tps[#tps+1]=p end
    end
    return tps
end
-- Source1942: three source attempts; do not repair native's exact-two quota.
sgs.ai_skill_use["@@zugezhi"]=function(self,prompt,request)
    local cards=faces(self,"zugezhiForAI");local tps={};local names={};local valid={}
    for i=0,2 do
        local c,p=self:getCardNeedPlayer(cards,true)
        if AIUnsupported.is(c)then error(c,0)end
        if AIUnsupported.is(p)then error(p,0)end
        if c and p then
            table.removeOne(cards,c);valid[#valid+1]=c:getKnownId()
            local name=p:objectName()
            if not table.contains(names,name)then names[#names+1]=name;tps[#tps+1]=p end
        end
    end
    if #valid<1 then return end
    return answer(self,"zugezhi",valid,tps,request)
end
end

-- Fixed olClan-ai.lua:1882–1888. Merge after the existing package body.
-- getTurnUse has an isolated-only diagnostic third return. A partial source
-- plan cannot prove either invocation or refusal; preserve that signal exactly.
do
sgs.ai_skill_invoke.zuheta = function(self, data)
    local cards, _, unknown = self:getTurnUse()
    if unknown ~= nil then error(unknown, 0) end
    if AIUnsupported.is(cards) then error(cards, 0) end
    for _, card in ipairs(cards) do
        if card:isKindOf("BasicCard") or card:isNDTrick() then
            return true
        end
    end
end
end
