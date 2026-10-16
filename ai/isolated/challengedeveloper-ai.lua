-- Fixed challengedeveloper-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local function known(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("challengedeveloper policy input is unknown",key) end
    return value
end


local function sorted(self,cards,method,...)
    local result=AIValue.callKnown(self, method, cards, ...)
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
local function seed(self,skill,class,request) return self:legacySkillSeed(skill, class, action_request(self,request)) end
local function bind(self,skill,class,costs,request) return self:bindSkillCard(skill, costs, action_request(self,request), nil, class) end
local function response(self,skill,class,costs,targets)
    local use=AIUsePlan.new();use.card=bind(self,skill,class,costs,nil);use.to=AIList.new(targets)
    return use:toAnswer()
end
local function play_epoch(self)
    local epochs=known(AIWorldLifecycle.epochs(self.world,"play"),"challengedeveloper.play_clear_epoch")
    return known(epochs[self.player:objectName()],"challengedeveloper.play_clear_epoch")
end
local function context(self,key)
    local row=self:getDecisionContext();local value=known(row["challengedeveloper_"..key],key)
    if value==false then return nil end
    local out={};for k,v in pairs(value)do out[k]=v end
    for _,k in ipairs({"from","to"})do
        if type(out[k])=="string"then out[k]=self.room:findPlayerByObjectName(out[k], true)
        elseif out[k]==false then out[k]=nil end
    end
    if out.card and not AIValue.isCard(out.card)then out.card=CardView.new(out.card)end
    return out
end
local function remember(self,key,value)self:setStrategyMemory("challengedeveloper."..key,value)end
local function recall(self,key)local value=self:getStrategyMemory("challengedeveloper."..key);return value end
local function pattern_names(self)return known(AICardCatalog.patternNames(),"pattern_names")end
local function disclosed(self,id)return known(self:getKnownCardById(id)or self:getChoiceCard(id),"disclosed card")end
local function clone(self,source,skill,name,costs)
    return self:evaluateOwnerViewAsCard({source_key=source,skill=skill,name=name,suit=sgs.Card_NoSuit,number=0,subcards=costs})
end
local function turn(self,skill,class,costs,request,user)
    return self:evaluateTurnSkillCard(skill, class, costs, action_request(self,request), user)
end
local function dummy()local use=AIUsePlan.new();use.isDummy=true;return use end
local function qinyin_choice(self)
    local value,present=self:getStrategyMemory("fire.qinyin_choice")
    if not present then ai_unsupported("Qinyin source choice unavailable","dev_pofeng")end
    return value
end
local function priority(self,key,card,offset)
    return self:setPriorityValue(key,self:getPriorityValue(card:getClassName(), card)+offset,"challengedeveloper."..key)
end
local function known_draw_id(self,index)
    -- Draw-pile contents are not projected.
    ai_unsupported("source requires undisclosed draw-pile order","dev_lvedong")
end
local function lvedong_mark(self)
    local epoch=play_epoch(self);local row=recall(self,"lvedong_mark")
    local delta=type(row)=="table"and row.epoch==epoch and row.delta or 0
    return self.player:getMark("dev_lvedongUse-PlayClear")+delta
end
local function increment_lvedong(self)
    local epoch=play_epoch(self);local row=recall(self,"lvedong_mark")
    local delta=type(row)=="table"and row.epoch==epoch and row.delta or 0
    remember(self,"lvedong_mark",{epoch=epoch,delta=delta+1})
end
local function card_used(self)
    -- PreCardUsed memory is intentionally not substituted for source filterData[CardUsed].
    return context(self,"caiyi_use")
end
local function converted_response(self,skill,class,spec,names)
    local card=self:bindOriginalSelectedConversion(spec, class, skill)
    local use=AIUsePlan.new();use.card=card
    for _,name in ipairs(names)do use.to:append(self.room:findPlayerByObjectName(name, true))end
    return use:toAnswer()
end
--略懂
local dev_lvedong = {}
dev_lvedong.name = "dev_lvedong"
table.insert(package_skills,dev_lvedong)
dev_lvedong.getTurnUseCard = function(self,inclusive,request)
    if lvedong_mark(self)>0
	then
		for i=0,1+self.player:getLostHp() do
			local id = known_draw_id(self,i)
			local c = disclosed(self,id)
			if c:isKindOf("BasicCard")
			then
				local dummy = self:aiUseCard(c)
				if dummy.card and c:isAvailable(self.player)
				then
					self._dev_lvedong_plan = dummy
					priority(self,"DevLvedongCard",c,0)
					return turn(self,"dev_lvedong","DevLvedongCard",{},request,c:objectName())
				end
			elseif c:getSuit()==3
			then
				local card = clone(self,"dev_lvedong","dev_lvedong","slash",{c:getKnownEffectiveId()})
				if card:isAvailable(self.player)
				then
					local dummy = self:aiUseCard(card)
					if dummy.card
					then
						self._dev_lvedong_plan = dummy
						priority(self,"DevLvedongCard",card,0)
						return turn(self,"dev_lvedong","DevLvedongCard",{},request,"slash")
					end
				end
			elseif c:getSuit()==0
			then
				local card = clone(self,"dev_lvedong","dev_lvedong","analeptic",{c:getKnownEffectiveId()})
				if card:isAvailable(self.player)
				then
					local dummy = self:aiUseCard(card)
					if dummy.card
					then
						self._dev_lvedong_plan = dummy
						priority(self,"DevLvedongCard",card,0)
						return turn(self,"dev_lvedong","DevLvedongCard",{},request,"analeptic")
					end
				end
			end
		end
		return
	end
	for _,name in sgs.list(pattern_names(self))do
        local card = self:getEvaluationCard(name)
        if card and card:isKindOf("BasicCard")
		and card:isAvailable(self.player)
		then
            card = clone(self,"dev_lvedong","dev_lvedong",name,{})
            local dummy = self:aiUseCard(card)
			if dummy.card
			then
				self._dev_lvedong_plan = dummy
				priority(self,"DevLvedongCard",card,0)
				return turn(self,"dev_lvedong","DevLvedongCard",{},request,name)
			end
		end
	end
end

sgs.ai_skill_use_func.DevLvedongCard = function(card,use,self,request)
	use.card = card
	use.to = self._dev_lvedong_plan.to
	increment_lvedong(self)
end

sgs.ai_guhuo_card.dev_lvedong = function(self,toname,class_name)
	if self:getCardsNum(class_name)>1 then return end
   	return {skill="dev_lvedong",legacy_class="DevLvedongCard",subcards={},user_string=toname}
end

--猜疑
sgs.ai_skill_invoke.dev_caiyi = function(self,data)
	local to = data:toPlayer()
	return to and not self:isFriend(to)
end

sgs.ai_skill_discard.dev_caiyi = function(self)
    local use = card_used(self)
	if self:needToLoseHp(self.player, use.from, use.card)
	or self:getCardsNum("Jink")<1 then return {} end
	local handcards = AIList.new(self.player:getCards("h"))
    sort_keep(self,handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if h:isKindOf("Slash") then return {h:getKnownEffectiveId()} end
	end
	return {}
end

--箭矢
function sgs.ai_cardsview_valuable.dev_jianshi(self,class_name,player)
	local jians = player:getPile("dev_jian")
	if jians:length()<2 then return nil end
	local null = clone(self,"dev_jianshi","dev_jianshi","nullification",{jians:first(),jians:last()})
	if player:isLocked(null) then return nil end
	return {name="nullification",skill="dev_jianshi",suit=null:getSuit(),number=null:getNumber(),subcards={jians:first(),jians:last()}}
end

sgs.ai_skill_invoke.dev_jianshi = function(self,data)
	return true
end

--藏刀
sgs.ai_skill_askforyiji.dev_cangdao = function(self,card_ids)
	local enemies,id = {},-1
	local slash = clone(self,"dev_cangdao","_dev_cangdao","slash",{})	
	local targets = {}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if self.player:canSlash(enemy, slash, false) then
			table.insert(targets,p)
		end
	end
	if #targets>0 then
		local target = sgs.ai_skill_playerchosen.zero_card_as_slash(self,targets)
		if target and self:isFriend(target) then
			return target,card_ids[1]
		end
	end
	for i = 1,#card_ids do
		id = card_ids[i]
		local card = disclosed(self,card_ids[i])
		local index = card:getEquipSlot()
		for _,enemy in sgs.list(self.enemies)do
			if self.player:canSlash(enemy, slash, false) and self:slashIsEffective(slash, enemy, self.player) and
			self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
				if enemy:getEquip(index) or not enemy:hasEquipArea(index) then
					table.insert(enemies,enemy)
				end
			end
		end
		if #enemies>0 then break end
	end
	if #enemies>0 and id>0 then
		sort_players(self,enemies,"defenseSlash")
		for _,enemy in sgs.list(enemies)do
			if self:isGoodTarget(enemy, enemies, self:getEvaluationCard("slash")) then
				return enemy,id
			end
		end
		for _,enemy in sgs.list(enemies)do
			if not self:needToLoseHp(enemy, self.player, self:getEvaluationCard("slash"))
			then
				return enemy,id
			end
		end
	end
	
	return sgs.ai_skill_askforyiji.miji(self,card_ids)
end

sgs.ai_skill_invoke.dev_cangdao = function(self,data)
	local to = data:toPlayer()
	local slash = clone(self,"dev_cangdao","_dev_cangdao","slash",{})	
	if self:isEnemy(to) then
		if self:slashIsEffective(slash, to, self.player)
		and self:damageIsEffective(to, slash, self.player)
		and not self:needToLoseHp(enemy, self.player, self:getEvaluationCard("slash"))
		then return true end
	end
	if self:isFriend(to) then
		local huatuo = false
		for _,p in sgs.list(self.friends)do
			if self:isFriend(p) and p:hasSkill("jijiu") and p:getPhase()==sgs.Player_NotActive then
				huatuo = true
				break
			end
		end
		if not self:ajustDamage(self.player, to, 1, slash)>1 and not self:slashProhibit(slash, to) and self:slashIsEffective(slash, to)
		and ((self:findLeijiTarget(to, 50, self.player, -1) or (self:findLeijiTarget(to, 50, self.player, 1) and to:isWounded()))
		or (to:isLord() and self.player:hasSkill("guagu") and to:getLostHp()>=1 and getCardsNum("Jink",to,self.player)==0)
		or (friend:hasSkill("jieming") and self.player:hasSkill("nosrende") and huatuo)) then
			return true
		end
	end
	return false
end

--全能
sgs.ai_skill_invoke.dev_quanneng = function(self,data)
	return true
end

sgs.ai_skill_invoke.dev_quanneng_buyi = function(self,data)
	local dying={who=data:toPlayer()}
    local new_data={toDying=function()return dying end}
	return sgs.ai_skill_invoke.buyi(self,new_data)
end

sgs.ai_skill_invoke.dev_quanneng_lieren = function(self,data)
	local damage={to=data:toPlayer()}
    local new_data={toDamage=function()return damage end}
	return sgs.ai_skill_invoke.lieren(self,new_data)
end

--破风
local dev_pofeng_skill = {}
dev_pofeng_skill.name = "dev_pofeng"
table.insert(package_skills,dev_pofeng_skill)
dev_pofeng_skill.getTurnUseCard = function(self,inclusive,request)
    if self.player:isNude() then return end
	local cards = AIList.new(self.player:getCards("he"))
	table.sort(cards,function(a,b)
		return a:getNumber()>b:getNumber()
	end)
	if cards[1]:getNumber()>=9 then
		if sgs.ai_skill_invoke.qinyin(self) then
			if qinyin_choice(self)=="down" then
				remember(self,"pofeng_id",cards[1]:getEffectiveId())
				return turn(self,"dev_pofeng","DevPofengCard",{},request)
			end
		end
	elseif cards[#cards]:getNumber()<=5 then
		if sgs.ai_skill_invoke.qinyin(self) then
			if qinyin_choice(self)=="up" then
				remember(self,"pofeng_id",cards[1]:getEffectiveId())
				return turn(self,"dev_pofeng","DevPofengCard",{},request)
			end
		end
	end
end

sgs.ai_skill_use_func.DevPofengCard = function(card,use,self,request)
	use.card = card
end

sgs.ai_use_priority.DevPofengCard = sgs.ai_use_priority.RendeCard+0.1
sgs.ai_use_value.DevPofengCard = 2

sgs.ai_skill_discard.dev_pofeng = function(self,discard_num,min_num,optional,include_equip)
	if recall(self,"pofeng_id") then
		local id = recall(self,"pofeng_id")
		remember(self,"pofeng_id",false)
		return {id}
	end
	
	local n = self.player:getTag("dev_pofeng_num") or 0 -- absent: QVariant::toInt() 0
	if n<=0 then return self:askForDiscard("dummyreason", 1, 1, optional, include_equip) end
	
	local cards,discards = AIList.new(self.player:getCards("he")),{}
	table.sort(cards,function(a,b)
		return a:getNumber()>b:getNumber()
	end)
	
	if sgs.ai_skill_invoke.qinyin(self) then
		if qinyin_choice(self)=="down" then
			for _,c in sgs.list(cards)do
				if c:getNumber()<n then
					table.insert(discards,c)
				end
			end
		else
			for _,c in sgs.list(cards)do
				if c:getNumber()>n then
					table.insert(discards,c)
				end
			end
		end
	end
	if #discards>0 then
		sort_keep(self,discards)
		return {discards[1]:getEffectiveId()}
	end
	
	return self:askForDiscard("dummyreason", 1, 1, optional, include_equip)
end

--销魂
local dev_xiaohun_skill = {}
dev_xiaohun_skill.name = "dev_xiaohun"
table.insert(package_skills,dev_xiaohun_skill)
dev_xiaohun_skill.getTurnUseCard = function(self,inclusive,request)
	local cards = AIList.new(self.player:getCards("h"))
	if self.player:getHandcardNum()<self.room:getOtherPlayers(self.player):length()/2 then return end
	sort_keep(self,cards)
	local xiaohun_ids={};remember(self,"xiaohun_ids",xiaohun_ids)
	local targets = {}
	local f,e = 0,0
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if #targets>self.player:getHandcardNum() then break end
		if p:getHp()==0 or p:isDead() then continue end
		if self:isEnemy(p) then
			for _,c in sgs.list(cards)do
				if c:getNumber() % p:getHp()==0 then
					xiaohun_ids[p:objectName()]=c:getKnownEffectiveId();remember(self,"xiaohun_ids",xiaohun_ids)
					table.removeOne(cards,c)
					table.insert(targets,p)
					e = e+1
				end
			end
		elseif self:isFriend(p) then
			for _,c in sgs.list(cards)do
				if c:getNumber() % p:getHp()~=0 and not self:needKongcheng(p) then
					xiaohun_ids[p:objectName()]=c:getKnownEffectiveId();remember(self,"xiaohun_ids",xiaohun_ids)
					table.removeOne(cards,c)
					table.insert(targets,p)
					f = f+1
				end
			end
		end
	end
	if e>0 or f>1 then
		return turn(self,"dev_xiaohun","DevXiaohunCard",{},request)
	end
end

sgs.ai_skill_use_func.DevXiaohunCard=function(card,use,self,request)
	use.card = card
end

sgs.ai_use_priority.DevXiaohunCard = sgs.ai_use_priority.DevPofengCard+0.05

sgs.ai_skill_askforyiji.dev_xiaohun = function(self,card_ids)
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if not p:hasFlag("dev_xiaohun") then continue end
		if known(recall(self,"xiaohun_ids"),"xiaohun prior plan")[p:objectName()]~=nil then
			return p,known(recall(self,"xiaohun_ids"),"xiaohun prior plan")[p:objectName()]
		end
	end
	return nil,-1
end

--塞车
sgs.ai_skill_cardask["@dev_saiche-give"] = function(self,data)
	local target = data:toPlayer()
	if target:isSkipped(sgs.Player_Play) or self:willSkipPlayPhase(target) then return "." end
	
	local cards = AIList.new(self.player:getHandcards())
	sort_use(self,cards,true)
	
	if isCard("Peach",cards[1],self.player) or isCard("Jink",cards[1],self.player) then return "." end
	
	local far_enemies,near_enemies = {},{}
	for _,p in sgs.qlist(self.room:getOtherPlayers(target))do
		if self:isEnemy(target, p) then
			if target:distanceTo(p)>1 then
				table.insert(far_enemies,p)
			else
				table.insert(near_enemies,p)
			end
		end
	end
	
	local num = 1
	if #self.enemies==1 then num = 0 end
	
	if self:isFriend(target) and #far_enemies>num then return "." end
	if self:isFriend(target) and #far_enemies==0 and not self:needKongcheng(target) then return "$"..cards[1]:getEffectiveId() end
	if self:isEnemy(target) and self:isWeak(far_enemies) and not self:isWeak(near_enemies) and target:getHandcardNum()>3 and target:getAttackRange()>=2 then
		if isCard("Slash",cards[1],target) or isCard("ThunderSlash",cards[1],target) or isCard("FireSlash",cards[1],target) or isCard("IceSlash",cards[1],target) or
		isCard("ExNihilo",cards[1],target) then
			return "."
		end
		return "$"..cards[1]:getEffectiveId()
	end
	return "."
end

--110
function sgs.ai_slash_prohibit.dev_110(self,from,to,card)
	return to:hasSkill("dev_110") and to:getMark("dev_110_first_time")<=0 and from:faceUp() and self:isWeak(from) and to:getPhase()==sgs.Player_NotActive
end

sgs.ai_need_damaged.dev_110 = function (self,attacker,player)
	if player:getMark("dev_110_first_time")>0 or player:getPhase()~=sgs.Player_NotActive then return false end
	if self:isFriend(attacker) and not attacker:faceUp() then return true end
	if attacker:faceUp() and self:isWeak(attacker) and self:isEnemy(attacker) then return true end  --据守、放逐什么的再说吧
	return false
end

--假药
sgs.ai_skill_discard.dev_jiayao = function(self,discard_num,min_num,optional,include_equip)
	local cards = AIList.new(self.player:getHandcards())
	local all_peaches = 0
	for _,card in sgs.list(cards)do
		if isCard("Peach",card,self.player) then
			all_peaches = all_peaches+1
		end
	end
	if all_peaches>=2 and self:getOverflow()<=0 then return {} end
	sort_keep(self,cards)

	for i = 1,#cards do
		local card = cards[i]
		if not isCard("Peach",card,self.player) and not self.player:isJilei(card) then
			return {card:getKnownEffectiveId()}
		end
	end
	return {}
end

--上瘾
sgs.ai_skill_playerchosen.dev_shangyin = function(self,targets)
	local slashs = self:getCards("Slash")
	if self.player:getSlashCount()==0 and #slashs<=1 then return self:findPlayerToDraw(true, 1) end
	
	for _,slash in sgs.list(self:getCards("Slash"))do
		if self:willUse(self.player, slash, false, false, true) then
			return self.player
		end
	end
	return self:findPlayerToDraw(true, 1)
end

--鲜橙
--橙汁
function sgs.ai_cardsview_valuable.dev_chengzhi(self,class_name,player)
	local dying = player:getRoom():getCurrentDyingPlayer()
	if dying then
		local slashs = {}
		for _,c in sgs.qlist(player:getCards("h"))do
			if c:isKindOf("Slash") then
				table.insert(slashs,c)
			end
		end
		if #slashs>0 then
			sort_keep(self,slashs,true)
			return {skill="dev_chengzhi",legacy_class="DevChengzhiCard",subcards={slashs[1]:getEffectiveId()}}
		end
	end
end

function sgs.ai_cardneed.dev_chengzhi(to,card)
	return card:isKindOf("Slash") and to:getHandcardNum()<=2
end

--半橙
local dev_bancheng_skill={}
dev_bancheng_skill.name = "dev_bancheng"
table.insert(package_skills,dev_bancheng_skill)
dev_bancheng_skill.getTurnUseCard = function(self,inclusive,request)
	return turn(self,"dev_bancheng","DevBanchengCard",{},request)
end

sgs.ai_skill_use_func.DevBanchengCard = function(card,use,self,request)
	local num = 2+self.player:getLostHp()
	
	if num==2 then
		sort_players(self,self.friends_noself,"handcard")
		for _,p in sgs.list(self.friends_noself)do
			if not self:canDraw(p) then continue end
			if self:damageIsEffective(p, nil, self.player) then continue end
			use.card = card
			remember(self,"bancheng_target",p:objectName())
			use.to:append(p)
			return
		end
		for _,p in sgs.list(self.friends_noself)do
			if not self:canDraw(p) then continue end
			if self:isWeak(p) then continue end
			use.card = card
			remember(self,"bancheng_target",p:objectName())
			use.to:append(p)
			return
		end
		for _,p in sgs.list(self.friends_noself)do
			if not self:canDraw(p) then continue end
			use.card = card
			remember(self,"bancheng_target",p:objectName())
			use.to:append(p)
			return
		end
	else
		local enemies = {}
		for _,p in sgs.list(self.enemies)do
			if not self:damageIsEffective(p, nil, self.player) then continue end
			table.insert(enemies,p)
		end
		if #enemies==0 then return end
		sort_players(self,enemies,"hp")
		
		for _,p in sgs.list(enemies)do
			local damage = self:ajustDamage(self.player, p, 1)
			if damage>=p:getHp() and not hasBuquEffect(p) then
				use.card = card
				remember(self,"bancheng_target",p:objectName())
				use.to:append(p)
				return
			end
		end
		for _,p in sgs.list(enemies)do
			local damage = self:ajustDamage(self.player, p, 1)
			if damage>=p:getHp() and not self:canDraw(p) then
				use.card = card
				remember(self,"bancheng_target",p:objectName())
				use.to:append(p)
				return
			end
		end
		for _,p in sgs.list(enemies)do
			local damage = self:ajustDamage(self.player, p, 1)
			if damage>=p:getHp() then
				use.card = card
				remember(self,"bancheng_target",p:objectName())
				use.to:append(p)
				return
			end
		end
		for _,p in sgs.list(enemies)do
			use.card = card
			remember(self,"bancheng_target",p:objectName())
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_priority.DevBanchengCard = sgs.ai_use_priority.QiangxiCard
sgs.ai_use_value.DevBanchengCard = sgs.ai_use_value.QiangxiCard

sgs.ai_card_intention.DevBanchengCard = function(self,card,from,tos)
	local intention = 50
	for _,to in sgs.list(tos)do
		if not self:damageIsEffective(to, nil, from) then intention = -20
		elseif from:getLostHp()==0 then intention = 0 end
		self:updateIntention(from, to, intention)
	end
end

sgs.ai_skill_use["@@dev_bancheng"] = function(self,prompt)
    local card=bind(self,"dev_bancheng","DevBanchengCard",{},nil)
    local use=dummy();self:useSkillCard(card, use)
    if use.card and recall(self,"bancheng_target")then return response(self,"dev_bancheng","DevBanchengCard",{}, {self.room:findPlayerByObjectName(recall(self,"bancheng_target"))})end
    return "."
end

sgs.ai_need_damaged.dev_bancheng = function (self,attacker,player)
	return not self:isWeak(player) and self:isWeak(self:getEnemies(player))
end

--曙光
sgs.ai_skill_invoke.dev_shuguang = function(self,data)
	local who = data:toPlayer()
	if who:getLostHp()==0 or not self:isFriend(who) then return false end
	if who:getMaxHp()-who:getHp()==1 and not self.player:hasFlag("Global_PreventPeach") then
		for _,peach in sgs.list(self:getCards("Peach"))do
			if not self.player:isProhibited(who, peach) then
				return false
			end
		end
	end
	return true
end

--妮妮
local dev_nini_skill={}
dev_nini_skill.name = "dev_nini"
table.insert(package_skills,dev_nini_skill)
dev_nini_skill.getTurnUseCard = function(self,inclusive,request)
	if #self.enemies<=0 then return end
	return turn(self,"dev_nini","DevNiniCard",{},request)
end

sgs.ai_skill_use_func.DevNiniCard = function(card,use,self,request)
	sort_players(self,self.enemies,"handcard")
	for _,p in sgs.list(self.enemies)do
		if not(self.player:canPindian(p) and self:doDisCard(p, "h")) then continue end
		use.card = turn(self,"dev_nini","DevNiniCard",{},request)
		use.to:append(p)
		return
	end
end

sgs.ai_use_priority.DevNiniCard = sgs.ai_use_priority.RendeCard+0.15

function sgs.ai_skill_pindian.dev_nini(minusecard,self,requestor)
	local cards = AIList.new(self.player:getHandcards())
	sort_keep(self,cards)
	if requestor:objectName()==self.player:objectName() then
		return cards[1]:getId()
	end
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( maxcard:getNumber()<5 and  minusecard or maxcard )
end

--蛋疼
sgs.ai_skill_invoke.dev_danteng = function(self,data)
	local target = data:toPlayer()
	if target:objectName()==self.player:objectName() then return self:canDraw() end
	if target:isWounded() then return self:canDraw() end
	if self:isFriend(target) then return self:canDraw() and target:getHandcardNum()<=2 end
	return self:canDraw()
end

--更新
sgs.ai_skill_use["@@dev_gengxin"] = function(self,prompt)
	local x = {}
	local enemies,friends = {},{}
	for _,p in sgs.list(self.enemies)do
		if p:getWeapon() and self.player:canDiscard(p, p:getEquip(0):getEffectiveId()) and self:doDisCard(p, "e") then
			table.insert(enemies,p)
		end
	end
	for _,p in sgs.list(self.friends)do
		if p:getWeapon() and self.player:canDiscard(p, p:getEquip(0):getEffectiveId()) and (p:hasSkills(sgs.lose_equip_skill) or self:doDisCard(p, "e")) then
			table.insert(friends,p)
		end
	end
	if #enemies>0 then
		for _,p in sgs.list(enemies)do
			table.insert(x,p:getWeapon():getRange())
		end
		table.sort(x)
		for _,p in sgs.list(enemies)do
			if p:getWeapon():getRange()==x[#x] then
				return response(self,"dev_gengxin","DevGengxinCard",{}, {p})
			end
		end
	end
	if #friends>0 then
		for _,p in sgs.list(friends)do
			table.insert(x,p:getWeapon():getRange())
		end
		table.sort(x)
		for _,p in sgs.list(friends)do
			if p:getWeapon():getRange()==x[#x] then
				return response(self,"dev_gengxin","DevGengxinCard",{}, {p})
			end
		end
	end
	
	local weapons = {}
	for _,c in sgs.qlist(self.player:getCards("he"))do
		if c:isKindOf("Weapon") then
			table.insert(weapons,c)
			table.insert(x,c:getRange())
		end
	end
	if #weapons>0 then
		table.sort(x)
		local id = -1
		for _,c in sgs.list(weapons)do
			if c:getRange()==x[#x] then
				id = c:getKnownEffectiveId()
				break
			end
		end
		for _,p in sgs.list(self.friends)do
			if not p:getWeapon() and p:hasWeaponArea() then
				table.insert(friends,p)
			end
		end
		if #friends>0 then
			local function attack_range_sort(a,b)
				local c1 = a:getAttackRange()
				local c2 = b:getAttackRange()
				return c1<c2
			end
			table.sort(friends,attack_range_sort)
			return response(self,"dev_gengxin","DevGengxinCard",{id},{friends[1]})
		end
	end
	
	if self:isWeak() and self.player:getWeapon() and self.player:canDiscard(self.player, self.player:getEquip(0):getEffectiveId()) then
		return response(self,"dev_gengxin","DevGengxinCard",{}, {self.player})
	end
	return "."
end

--学霸
sgs.ai_skill_invoke.dev_xueba = function(self,data)
	local target = data:toPlayer()
	return self:isFriend(target)
end

sgs.ai_skill_choice.xuehen = function(self,choices)
	choices = choices:split("+")
	for _,choice in sgs.list(choices)do
		if self:isValueSkill(choice, self.player, true) then
			return choice
		end
	end
	for _,choice in sgs.list(choices)do
		if self:isValueSkill(choice, self.player) then
			return choice
		end
	end
	for _,choice in sgs.list(choices)do
		if string.find(sgs.bad_skills,choice) then continue end
		return choice
	end
	return choices[math.random(1,#choices)]
end

--魅惑
sgs.ai_skill_invoke.dev_meihuo = function(self,data)
	local target = data:toPlayer()
	if target then
		return self:canDraw() and not self:isFriend(target) and (self:doDisCard(target, "h") or
		(target:getHp()==1 and target:getHandcardNum()==1 and not hasBuquEffect(target)))
	else
		local use = data:toCardUse()
		local nature = sgs.DamageStruct_Normal
		if use.card:isKindOf("FireSlash") then nature = sgs.DamageStruct_Fire
		elseif use.card:isKindOf("ThunderSlash") then nature = sgs.DamageStruct_Thunder
		elseif use.card:isKindOf("IceSlash") then nature = sgs.DamageStruct_Ice end
		if self:canDraw() then
			if self:isFriend(use.from) then
				return self:isGoodChainTarget(self.player, nature, use.from)
				and self:slashIsEffective(use.card, self.player, use.from)
			end
			return true
		end
		return self:isWeak() and not self:isFriend(use.from) and self:slashIsEffective(use.card, self.player, use.from) and self:damageIsEffective(self.player, nature, use.from)
	end
	return false
end

--女神
sgs.ai_skill_playerchosen.dev_nvshen = function(self,targets)
	targets = AIList.new(targets)
	sort_players(self,targets,"HP")
	for _,p in sgs.list(targets)do
		if self:isEnemy(p) then
			return p
		end
	end
	
	if self:hasSkills(sgs.recover_hp_skill, self.friends) then
		targets = sgs.reverse(targets)
		for _,p in sgs.list(targets)do
			if self:isFriend(p) then
				return p
			end
		end
	end
	
	return nil
end

--嗝屁
sgs.ai_skill_invoke.dev_gepi = function(self,data)
	if self.player:getCardCount()==1 and not self.player:isKongcheng() and self.player:getCards("h"):first():isKindOf("Peach") and self:isWeak(self.friends) then return false end
	local target = data:toPlayer()
	local skills = {}
	for _,sk in sgs.qlist(target:getVisibleSkillList())do
		if sk:isAttachedLordSkill() or sk:inherits("SPConvertSkill") or sk:isLordSkill() or
		sk:getFrequency()==sgs.Skill_Wake or table.contains(skills,sk:objectName()) then continue end
		table.insert(skills,sk:objectName())
	end
	if #skills==0 then return self:canDraw(target) and self:isFriend(target) end
	if self:isFriend(target) then
		for _,sk in sgs.list(skills)do
			if string.find(sgs.bad_skills,sk) then
				remember(self,"gepi_choice",sk)
				return true
			end
		end
	elseif self:isEnemy(target) then
		for _,sk in sgs.list(skills)do
			if not string.find(self.room:getPublicSkill(sk):getDescription(),"出牌阶段") then continue end
			if self:isValueSkill(sk, target) then
				remember(self,"gepi_choice",sk)
				return true
			end
		end
	end
	return false
end

--柴刀
sgs.ai_skill_invoke.dev_chaidao = function(self,data)
	local str = data:toString():split(":")
	if #str~=2 then return false end
	local target = self.room:findPlayerByObjectName(str[2])  --被横置就先不考虑了
	if str[1]=="DamageCaused" then
		return self:isEnemy(target) and not self:cantDamageMore(self.player, target)
	elseif str[1]=="DamageInflicted" then
		return not self:isFriend(target)  --被横置就先不考虑了，有卖血技也先不考虑了
	end
	return false
end

--骚动
sgs.ai_skill_discard.dev_saodong = function(self,discard_num,min_num,optional,include_equip)
	local damage = context(self,"saodong_damage")
	if not damage or not damage.from or damage.from:isDead() or not damage.card or not damage.card:isKindOf("TrickCard") then return {} end
	
	local diamond = {}
	for _,c in sgs.qlist(self.player:getCards("he"))do
		if c:getSuit()~=sgs.Card_Diamond then continue end
		table.insert(diamond,c)
	end
	if #diamond==0 then return {} end
	sort_use(self,diamond,true)
	
	local nature = sgs.DamageStruct_Normal
	if damage.card:isKindOf("FireAttack") then nature = sgs.DamageStruct_Fire
	elseif damage.card:isKindOf("Drowning") then nature = sgs.DamageStruct_Thunder end
	
	if not self:damageIsEffective(self.player, nature, damage.from) then return {} end
	
	if self:isFriend(damage.from) then
		if self:isWeak(damage.from) and self:damageIsEffective(damage.from, nature, damage.from) then return {} end
		if not self:damageIsEffective(damage.from, nature, damage.from) then return {diamond[1]:getEffectiveId()} end
		if self:isWeak() then return {diamond[1]:getEffectiveId()} end
	else
		if diamond[1]:isKindOf("Peach") or diamond[1]:isKindOf("Analeptic") then return {} end
		if not self:isWeak() and (diamond[1]:isKindOf("ExNihilo") or diamond[1]:isKindOf("Dongzhuxianji")) then return {} end
		return {diamond[1]:getEffectiveId()}
	end
	
	return {}
end

sgs.ai_skill_cardask["@dev_saodong"] = function(self,data)
	local heart = {}
	for _,c in sgs.qlist(self.player:getCards("he"))do
		if c:getSuit()~=sgs.Card_Heart then continue end
		table.insert(heart,c)
	end
	if #heart==0 then return {} end
	sort_use(self,heart,true)
	
	for _,c in sgs.list(heart)do
		local peach = clone(self,"dev_saodong","dev_saodong","peach",{c:getKnownEffectiveId()})
		
		local ex_nihilo = clone(self,"dev_saodong","dev_saodong","ex_nihilo",{c:getKnownEffectiveId()})
		
		if self:isWeak() then
			if peach:isAvailable(self.player) and self:getUseValue(peach)>=self:getUseValue(c) and self.player:getMark("dev_geili_effect-Clear")<=0 then
				remember(self,"saodong_choice","peach")
				return "$"..c:getKnownEffectiveId()
			end
		elseif self:canDraw() then
			if self:hasTrickEffective(ex_nihilo, self.player, self.player) and ex_nihilo:isAvailable(self.player) and self:getUseValue(ex_nihilo)>=self:getUseValue(c) then
				remember(self,"saodong_choice","ex_nihilo")
				return "$"..c:getKnownEffectiveId()
			end
		elseif self.player:getLostHp()>0 then
			if peach:isAvailable(self.player) and self:getUseValue(peach)>=self:getUseValue(c) and self.player:getMark("dev_geili_effect-Clear")<=0 then
				remember(self,"saodong_choice","peach")
				return "$"..c:getKnownEffectiveId()
			end
		end
	end
	
	return "."
end

--治愈
sgs.ai_skill_playerchosen.dev_zhiyu = function(self,targets)
	targets = AIList.new(targets)
    sort_players(self,targets,"hp")
	for _,p in sgs.list(targets)do
		if self:isFriend(p) then
		    if p:getLostHp()>1 or self:isWeak(p) then
				return p
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.dev_zhiyu = -100

--指引
sgs.ai_skill_playerchosen.dev_zhiyin = function(self,targets)
	return self:findPlayerToDiscard("j", false, true, targets)[1]
end

sgs.ai_playerchosen_intention.dev_zhiyin = -20

--教导
sgs.ai_skill_invoke.dev_jiaodao = function(self,data)
	local use = context(self,"jiaodao_use")
	if not use then return false end
	--return q(self,"willUse",use.from,use.card,false,false,true)
	return self:willUse(self.player, use.card, false, false, true)
end

--美工
local function limited_sort(self,players,no_mark)
	if type(players)~="table" then
		players = AIList.new(players)
	end
	local pds = {}
	for _,p in sgs.list(players)do
		pds[p:objectName()] = self:getDefenseSlash(p)
	end
	local func = function(a,b)
		local c1,c2 = 0,0
		for _,skill in sgs.qlist(a:getVisibleSkillList())do
			if not skill:isLimitedSkill() or skill:getLimitMark()=="" then continue end
			if no_mark and a:getMark(skill:getLimitMark())>0 then continue end
			c1 = c1+1
		end
		for _,skill in sgs.qlist(b:getVisibleSkillList())do
			if not skill:isLimitedSkill() or skill:getLimitMark()=="" then continue end
			if no_mark and b:getMark(skill:getLimitMark())>0 then continue end
			c2 = c2+1
		end
		if c1==c2 then
			return pds[a:objectName()]>pds[b:objectName()]
		end
		return c1>c2
	end
	table.sort(players,func)
end

local dev_meigong_skill={}
dev_meigong_skill.name = "dev_meigong"
table.insert(package_skills,dev_meigong_skill)
dev_meigong_skill.getTurnUseCard = function(self,inclusive,request)
	if #self.friends_noself<=0 then return end
	return turn(self,"dev_meigong","DevMeigongCard",{},request)
end

sgs.ai_skill_use_func.DevMeigongCard = function(card,use,self,request)
	limited_sort(self,self.friends_noself,true)
	local num = 0
	for _,skill in sgs.qlist(self.friends_noself[1]:getVisibleSkillList())do
		if not skill:isLimitedSkill() or skill:getLimitMark()=="" then continue end
		if self.friends_noself[1]:getMark(skill:getLimitMark())>0 then continue end
		num = num+1
	end
	if num>0 then
		use.card = turn(self,"dev_meigong","DevMeigongCard",{},request)
		use.to:append(self.friends_noself[1])
		return
	end
	
	limited_sort(self,self.friends_noself)
	use.card = turn(self,"dev_meigong","DevMeigongCard",{},request)
	use.to:append(self.friends_noself[1])
end

--弃疗
sgs.ai_skill_playerchosen.dev_qiliao = function(self,targets)
	targets = AIList.new(targets)
	
	sort_players(self,targets,"hp")
	for _,p in sgs.list(targets)do
		if not self:isFriend(p) then continue end
		if p:getLostHp()>0 and self:isWeak(p) then
			return p
		end
	end
	
	return self:findPlayerToDraw(false, 1)
end

sgs.ai_playerchosen_intention.dev_qiliao = -20

sgs.ai_skill_invoke.dev_qiliao = function(self,data)
	local strs = data:toString():split(":")
	if #strs~=2 then return false end
	local target = self.room:findPlayerByObjectName(strs[2])
	if not target or target:isDead() then return false end
	return self:isFriend(target) and self:isWeak(target) and target:getLostHp()>0
end

--学习
sgs.ai_skill_invoke.dev_xuexi = function(self,data)
	return self:canDraw()
end

--给力
sgs.ai_skill_invoke.dev_geili = function(self,data)
	local target = data:toPlayer()
	return self:isEnemy(target) and target:getLostHp()>0
end

--奆佬
local dev_juanlao_skill = {}
dev_juanlao_skill.name = "dev_juanlao"
table.insert(package_skills,dev_juanlao_skill)
dev_juanlao_skill.getTurnUseCard = function(self,inclusive,request)
	local name = self.player:getPropertyValue("dev_juanlao_card") or "" -- absent: QVariant::toString() ""
	if not name or name==nil or name=="" then return end
	local card_str = ("%s:dev_juanlao[no_suit:0]=."):format(name)
	local preview=self:getEvaluationCard(name)
    if not preview then return end
    local card=self:evaluateTurnConversion("dev_juanlao", preview:getClassName(), {name=name,skill="dev_juanlao",suit=sgs.Card_NoSuit,number=0,subcards={}}, request)
	if not card or card:isKindOf("IronChain") then return end
	assert(card)
	return card
end

--饺气
sgs.ai_skill_invoke.dev_jiaoqi = function(self,data)
	local strs = data:toString():split(":")
	if #strs~=2 then return false end
	local target = self.room:findPlayerByObjectName(strs[2])
	if not target or target:isDead() then return false end
	if strs[1]=="discard" then
		return self:isEnemy(target) and self:doDisCard(target, "e")
	elseif strs[1]=="jink" then
		return self:isEnemy(target)
	end
	return false
end

--饺猾
sgs.ai_skill_use["@@dev_jiaohua"] = function(self,prompt)
	local cards,suits = {},{}
	for _,c in sgs.qlist(self.player:getEquips())do
		local suit = c:getSuit()
		if not table.contains(suits,suit) then
			table.insert(suits,suit)
		end
	end
	if #suits==0 then return "." end
	
	for _,c in sgs.qlist(self.player:getHandcards())do
		if not table.contains(suits,c:getSuit()) then continue end
		local slash = clone(self,"dev_jiaohua","dev_jiaohua","slash",{c:getKnownEffectiveId()})
		if not self.player:isLocked(slash, true) and self:willUse(self.player, slash, false, false, true) then
			table.insert(cards,c)
		end
	end
	if #cards==0 then return "." end
	
	sort_use(self,cards,true)
	
	local targets = {}
	local slash = clone(self,"dev_jiaohua","dev_jiaohua","slash",{cards[1]:getEffectiveId()})
	local dummy_use = dummy()
	self:useCardSlash(slash, dummy_use)
	if dummy_use.card and dummy_use.to:length()>0 then
		for _,p in sgs.qlist(dummy_use.to)do
			table.insert(targets,p:objectName())
		end
	end
	if #targets==0 then return "." end
	
	return converted_response(self,"dev_jiaohua","Slash",{name="slash",skill="dev_jiaohua",suit=cards[1]:getSuit(),number=cards[1]:getNumber(),subcards={cards[1]:getEffectiveId()}},targets)
end


--图谋
local dev_tumou = {}
dev_tumou.name = "dev_tumou"
table.insert(package_skills,dev_tumou)
dev_tumou.getTurnUseCard = function(self,inclusive,request)
	local cards = AIList.new(self.player:getCards("h"))
	sort_keep(self,cards)
	local id = -1
	for _,h in sgs.list(cards)do
		if self.player:isLocked(h, true)
		or table.contains(self.toUse,h)
		or h:getTypeId()~=1
		then continue end
		id = h:getKnownId()
		break
	end
	if id<0 then return end
	for _,name in sgs.list(pattern_names(self))do
		if(self.player:getMark("dev_tumou_guhuo_remove"..name)>0)
		then continue end
        local card = self:getEvaluationCard(name)
        if card and card:isNDTrick()
		and not card:isDamageCard()
		and card:isAvailable(self.player)
		then
            card = clone(self,"dev_tumou","dev_lvedong",name,{id})
            local dummy = self:aiUseCard(card)
			if dummy.card
			then
				if card:canRecast()
				and dummy.to:length()<1
				then continue end
				self._dev_tumou_plan = dummy
				priority(self,"DevTumouCard",card,2)
				return turn(self,"dev_tumou","DevTumouCard",{id},request,name)
			end
		end
	end
	for _,name in sgs.list(pattern_names(self))do
		if(self.player:getMark("dev_tumou_guhuo_remove"..name)>0)
		then continue end
        local card = self:getEvaluationCard(name)
        if card and card:isNDTrick()
		and card:isAvailable(self.player)
		then
            card = clone(self,"dev_tumou","dev_lvedong",name,{id})
            local dummy = self:aiUseCard(card)
			if dummy.card
			then
				if card:canRecast()
				and dummy.to:length()<1
				then continue end
				self._dev_tumou_plan = dummy
				priority(self,"DevTumouCard",card,0)
				return turn(self,"dev_tumou","DevTumouCard",{id},request,name)
			end
		end
	end
end

sgs.ai_skill_use_func.DevTumouCard = function(card,use,self,request)
	use.card = card
	use.to = self._dev_tumou_plan.to
end

sgs.ai_use_priority.DevTumouCard = 3

sgs.ai_guhuo_card.dev_tumou = function(self,toname,class_name)
	if self:getCardsNum(class_name)>1 then return end
	local cards = AIList.new(self.player:getCards("h"))
	sort_keep(self,cards)
	local id = -1
	for _,h in sgs.list(cards)do
		if self.player:isLocked(h, true)
		or h:getTypeId()~=1
		then continue end
		id = h:getKnownId()
		break
	end
	if id<0 then return end
   	return {skill="dev_tumou",legacy_class="DevTumouCard",subcards={id},user_string=toname}
end

--机应
sgs.ai_skill_invoke.dev_jiying = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_choice.dev_gepi=function(self)return known(recall(self,"gepi_choice"),"dev_gepi prior choice")end
sgs.ai_skill_choice.dev_saodong=function(self)return known(recall(self,"saodong_choice"),"dev_saodong prior choice")end
for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end

SmartAIView.DevLimitedSkillSort=limited_sort
