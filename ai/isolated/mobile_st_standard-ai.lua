-- Mobile Standard fixed b6025acc. Native authority remains separate from source plans.
local known = AIValue.requireKnown

local function known_card(self,id)return known(self:getKnownCardById(id),"disclosed card "..tostring(id))end
local function visible_hand(self,p)local cards=known(p:getKnownCards(),"known hand");if #cards~=p:getHandcardNum()then ai_unsupported("source enumerates undisclosed dead hand","mobilexingshang")end;return cards end
-- The viewer's own dynamic property, converted like the donor's QVariant read (absent reads empty).
local function property(self,k,kind)
 local v=self.player:getPropertyValue(k)
 if kind=="Bool"then return v==true end
 if v==nil then return""end;return v
end
-- The viewer's own tag; an absent list reads as the donor's empty toIntList, otherwise nil.
local function tag(self,k,kind)
 local row=self.player:getTag(k)
 if row==nil then if kind=="IntList"then return AIList.new({})end;return nil end
 if kind=="Player"then return known(self.room:findPlayerByObjectName(row,true),k)
 elseif kind=="Card"then return CardView.new(row)
 elseif kind=="CardUse"then local to=AIList.new({});for _,name in ipairs(row.to or{})do to:append(known(self.room:findPlayerByObjectName(name,true),k))end;return{card=row.card and CardView.new(row.card),from=row.from and self.room:findPlayerByObjectName(row.from,true),to=to,no_respond_list=known(row.no_respond_list,k.." no respond"),no_offset_list=known(row.no_offset_list,k.." no offset")}
 else return AIList.new(row)end
end
local function write(self,k,v)
 if k=="jy_to"or k=="mobileshensu_to"then if v then local ns={};for _,p in sgs.list(v)do ns[#ns+1]=p:objectName()end;v=ns end
 elseif k~="mobileqiaoshui_collateral"then v=v and v:objectName()end
 self:setStrategyMemory("mobile_st_standard."..k,v==nil and false or v)
end
local function read(self,k)
 local v,ok=self:getStrategyMemory("mobile_st_standard."..k);if not ok or v==false then return nil end
 if k=="jy_to"or k=="mobileshensu_to"then local ps=AIList.new({});for _,name in ipairs(v)do ps:append(known(self.room:findPlayerByObjectName(name,true),k))end;return ps
 elseif k~="mobileqiaoshui_collateral"then return known(self.room:findPlayerByObjectName(v,true),k)end;return v
end
local function diagnostic(self,text)self.request.scratch=self.request.scratch or{};self.request.scratch.source_diagnostics=self.request.scratch.source_diagnostics or{};table.insert(self.request.scratch.source_diagnostics,text)end
local function dummy_plan(isDummy, extra, targets)
    local current = {}
    for _, player in sgs.list(targets or {}) do
        current[#current + 1] = type(player) == "string" and player or player:objectName()
    end
    return AIUsePlan.dummy(isDummy, extra, current)
end
local function clone(self,key,skill,name,suit,number,ids)return self:evaluateOwnerViewAsCard({source_key=key,skill=skill,name=name,suit=suit,number=number,subcards=ids})end
local function turn_clone(self,skill,name,suit,number,ids,request)local base=self:getEvaluationCard(name);if not base then return nil end;return self:evaluateTurnConversion(skill,base:getClassName(),{name=name,skill=skill,suit=suit,number=number,subcards=ids},request)end
local function contains_identity(cs,c)for _,v in sgs.list(cs)do if AIValue.sameLegacyIdentity(v,c)then return true end end;return false end
local function mobile_fangquan(self,prompt)
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards=self:sortByKeepValue(cards)
	if known(self:getRoleCounts().rebel,"rebel count")==0 then
		local lord = self.room:getLord()
		if lord and self:isFriend(lord) and lord:objectName()~=self.player:objectName() then
			return "@MobileFangquanCard="..cards[1]:getEffectiveId().."->"..lord:objectName()
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) then
		return "@MobileFangquanCard="..cards[1]:getEffectiveId().."->"..AssistTarget:objectName()
	end

	self.friends_noself=self:sort(self.friends_noself,"chaofeng")
	for _,target in ipairs(self.friends_noself)do
		if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|"..sgs.priority_skill.."|shensu")
			and (not self:willSkipPlayPhase(target) or target:hasSkill("shensu")) then
			return "@MobileFangquanCard="..cards[1]:getEffectiveId().."->"..target:objectName()
		end
	end

	for _,target in ipairs(self.friends_noself)do
		if target:hasSkill("dawu") then
			local use = true
			for _,p in ipairs(self.friends_noself)do
				if p:getStrategyMark("&dawu")>0 then use = false break end
			end
			if use then
				return "@MobileFangquanCard="..cards[1]:getEffectiveId().."->"..target:objectName()
			end
		else
			return "@MobileFangquanCard="..cards[1]:getEffectiveId().."->"..target:objectName()
		end
	end
	return "."
end

local classes={['MobileZongxuanPutCard']='mobilezongxuanput',['MobileZongshihCard']='mobilezongshih',['MobileXingxueCard']='mobilexingxue',['MobileJunxingCard']='mobilejunxing',['MobileFurongCard']='mobilefurong',['MobilePoluCard']='mobilepolu',['MobileJianyingCard']='mobilejianying',['MobileZaiqiCard']='mobilezaiqi',['MobileQingjianCard']='mobileqingjian',['MobileBingyiCard']='mobilebingyi',['MobileXianzhenCard']='mobilexianzhen',['MobileJieyueCard']='mobilejieyue',['MobileSidiCard']='mobilesidi',['MobileTiaoxinCard']='mobiletiaoxin',['MobileShensuCard']='mobileshensu',['MobileYaomingCard']='mobileyaoming',['MobileQiaoshuiCard']='mobileqiaoshui',['MobileZhijianCard']='mobilezhijian',['MobileMiejiDiscardCard']='mobilemiejidiscard',['MobileYanzhuCard']='mobileyanzhu',['ExtraCollateralCard']='mobileqiaoshui',['MobileGongqiCard']='mobilegongqi',['MobileAnxuCard']='mobileanxu',['MobileDingpinCard']='mobiledingpin',['MobileZongxuanCard']='mobilezongxuan',['MobileMiejiCard']='mobilemieji',['MobileGanluCard']='mobileganlu',['MobileShenxingCard']='mobileshenxing',['MobileQiangxiCard']='mobileqiangxi',['MobileFangquanCard']='mobilefangquan'}
local function decode(text)
 local cl,raw=text:match("^@([%w_]+)=(.*)$");if not cl or not classes[cl]then ai_unsupported("unexpected authored skill card wire","mobile standard")end
 local cost,user=raw:match("^(.-):(.*)$");cost=cost or raw;local ids={};if cost~="."then for id in cost:gmatch("[^+]+")do ids[#ids+1]=assert(tonumber(id))end end;return cl,classes[cl],ids,user
end
local function parse_policy(self,text,request)local cl,skill,ids,user=decode(text);return self:evaluateTurnSkillCard(skill,cl,ids,request,user)end
local function selected_policy(self,text)local cl,skill,ids,user=decode(text);return self:bindSkillCard(skill,ids,nil,user,cl)end
local function select_card(self,card,cl)if type(card.isStrategySeed)=="function"and card:isStrategySeed()then return self:bindSkillCard(classes[cl],{},nil,nil,cl)end;return card end
local function response_wire(self,wire)
 if type(wire)~="string"or wire=="."or wire==""then return wire end
 local text,targets=wire:match("^(.-)%->(.*)$");local paid=selected_policy(self,text or wire)
 return{kind="use_card",card_spec=paid:toCardSpec(),targets=targets and targets:split("+")or{}}
end
--清俭
sgs.ai_skill_discard.mobileqingjian = function(self,discard_num,min_num,optional,include_equip)
	if #self.friends_noself==0 then return {} end
	local put = {}
	if self:needToThrowLastHandcard(self.player,self.player:getHandcardNum()) then
		for _,c in sgs.qlist(self.player:getCards("h"))do
			table.insert(put,c:getKnownEffectiveId())
		end
		return put
	end

	local n = self:getOverflow()
	if n<=0 then return {} end

	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
	for _,c in ipairs(cards)do
		if self:isValuableCard(c) then continue end
		table.insert(put,c:getKnownEffectiveId())
		if #put-1>=n then break end
	end
	return put
end

sgs.ai_skill_use["@@mobileqingjian!"] = function(self,prompt,method)
	local card_ids = {}
	for _,id in sgs.qlist(self.player:getPile("mobileqingjian"))do
		table.insert(card_ids,id)
	end
	if #self.friends_noself>0 then
		local target,id = sgs.ai_skill_askforyiji.miji(self,card_ids)
		if target and id then
			return "@MobileQingjianCard="..id.."->"..target:objectName()
		end
	end

	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if not self:isEnemy(p) then
			return "@MobileQingjianCard="..table.concat(card_ids,"+").."->"..p:objectName()
		end
	end

	return "@MobileQingjianCard="..table.concat(card_ids,"+").."->"..self.enemies[1]:objectName()
end

--奋激
sgs.ai_skill_invoke.mobilefenji = function(self,data)
	if self.player:getHp()>0
	or hasBuquEffect(self.player)
	or self:getSaveNum(true)>0
	then
		local target = self.room:getCurrent()
		if self:isFriend(target)
		and self:canDraw(target)
		then return true end
	end
	return false
end

--强袭

sgs.ai_fill_skill["mobileqiangxi"] = function(self,inclusive,request)
	return parse_policy(self,"@MobileQiangxiCard=.")
end

sgs.ai_skill_use_func.MobileQiangxiCard = function(card,use,self)
	local weapon = self.player:getWeapon()
	if weapon then
		local hand_weapon,cards
		cards = self.player:getHandcards()
		for _,card in sgs.qlist(cards)do
			if card:isKindOf("Weapon") then
				hand_weapon = card
				break
			end
		end
		self.enemies = self:sort(self.enemies)
		self.equipsToDec = hand_weapon and 0 or 1
		for _,enemy in ipairs(self.enemies)do
			if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and enemy:getStrategyMark("mobileqiangxi_used-PlayClear")<=0 then
				if hand_weapon and self.player:distanceTo(enemy)<=self.player:getAttackRange() then
					use.card = selected_policy(self,"@MobileQiangxiCard="..hand_weapon:getId())
					use.to:append(enemy)
					break
				end
				if self.player:distanceTo(enemy)<=1 and enemy:getStrategyMark("mobileqiangxi_used-PlayClear")<=0 then
					use.card = selected_policy(self,"@MobileQiangxiCard="..weapon:getId())
					use.to:append(enemy)
					return
				end
			end
		end
		self.equipsToDec = 0
	else
		self.enemies = self:sort(self.enemies,"hp")
		for _,enemy in ipairs(self.enemies)do
			if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and enemy:getStrategyMark("mobileqiangxi_used-PlayClear")<=0 then
				if self.player:distanceTo(enemy)<=self.player:getAttackRange() and self.player:getHp()>enemy:getHp() and self.player:getHp()>1 then
					use.card = selected_policy(self,"@MobileQiangxiCard=.")
					use.to:append(enemy)
					return
				end
			end
		end
	end
end

sgs.ai_use_value.MobileQiangxiCard = sgs.ai_use_value.QiangxiCard
sgs.ai_card_intention.MobileQiangxiCard = sgs.ai_card_intention.QiangxiCard
sgs.dynamic_value.damage_card.MobileQiangxiCard = sgs.dynamic_value.damage_card.QiangxiCard
sgs.ai_cardneed.mobileqiangxi = sgs.ai_cardneed.qiangxi
sgs.mobileqiangxi_keep_value = sgs.qiangxi_keep_value

--节命
sgs.ai_skill_playerchosen.mobilejieming = function(self,targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets,"handcard")
	if self:canDraw() then
		for _,p in ipairs(targets)do
			if self:isFriend(p) and self:canDraw(p) and p:getHandcardNum()+2+ZishuEffect(p)<p:getMaxHp() and ZishuEffect(p)>0 then
			----清俭待补充----
				return p
			end
		end
		for _,p in ipairs(targets)do
			if self:isFriend(p) and self:canDraw(p) and p:getHandcardNum()+2<p:getMaxHp() then
				return p
			end
		end
	end

	if not self:canDraw() then
		for _,p in ipairs(targets)do
			if self:isFriend(p) and self:canDraw(p) and p:getHandcardNum()+2+ZishuEffect(p)>=p:getMaxHp() and ZishuEffect(p)>0 then
			----清俭待补充----
				return p
			end
		end
		for _,p in ipairs(targets)do
			if self:isFriend(p) and self:canDraw(p) and p:getHandcardNum()+2>=p:getMaxHp() then
				return p
			end
		end
	end

	for _,p in ipairs(targets)do
		if self:isFriend(p) and self:canDraw(p) and ZishuEffect(p)>0 then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if self:isFriend(p) and self:canDraw(p) then
			return p
		end
	end

	return nil
end

sgs.ai_playerchosen_intention.mobilejieming = function(self,from,to)
	if self:canDraw(to) then
		self:updateIntention(from,to,-80)
	end
end

sgs.append_skill_list("drawSkillsList","mobilejieming")

--涅槃
sgs.ai_skill_invoke.mobileniepan = function(self,data)
	return sgs.ai_skill_invoke.niepan(self,data)
end
----出牌阶段主动使用的待补充----

--双雄
sgs.ai_skill_invoke.mobileshuangxiong = function(self,data)
	if data:toString():startsWith("mobileshuangxiong_invoke")
	then return self:canDraw() end
	return sgs.ai_skill_invoke.shuangxiong(self,data)
end

sgs.ai_cardneed.mobileshuangxiong = function(to,card,self)
	return sgs.ai_cardneed.shuangxiong(to,card,self)
end

sgs.ai_skill_askforag.mobileshuangxiong = function(self,card_ids)
	local fcard,scard = known_card(self,card_ids[1]),known_card(self,card_ids[2])
	if fcard:sameColorWith(scard) then
		return sgs.ai_skill_askforag.amazing_grace(self,card_ids)
	end

	local red,black = 0,0
	for _,c in sgs.qlist(self.player:getCards("h"))do  --如果这张牌是【杀】，数量不加1，待补充
		if c:isRed() then red = red+1
		elseif c:isBlack() then black = black+1 end
	end

	--有“武圣”等技能需要改变选牌策略，待补充--
	if red==black then
		return sgs.ai_skill_askforag.amazing_grace(self,card_ids)
	elseif red>black then
		if fcard:isBlack() then return fcard:getKnownEffectiveId() end
		if scard:isBlack() then return scard:getKnownEffectiveId() end
	else
		if fcard:isRed() then return fcard:getKnownEffectiveId() end
		if scard:isRed() then return scard:getKnownEffectiveId() end
	end
	return sgs.ai_skill_askforag.amazing_grace(self,card_ids)
end


sgs.ai_fill_skill["mobileshuangxiong"] = function(self,inclusive,request)
	local red = self.player:getStrategyMark("mobileshuangxiong_red-Clear")
	local black = self.player:getStrategyMark("mobileshuangxiong_black-Clear")
	local cards = self:addHandPile()
	cards = self:sortByUseValue(cards,true)
	for dc,acard in ipairs(cards)  do
		if not acard:isRed() and red>0
		or not acard:isBlack() and black>0
		then
			dc = turn_clone(self,"mobileshuangxiong","duel",sgs.Card_NoSuit,0,{acard:getKnownEffectiveId()},request)
			if dc:isAvailable(self.player)
			then return dc end
		end
	end
end

--乱击

sgs.ai_fill_skill["mobileluanji"] = function(self,inclusive,request)
	local cards = self:addHandPile()
	if #cards>=2
	then
		cards = self:sortByKeepValue(cards)
		local useAll = #cards>4
		for _,enemy in ipairs(self.enemies)do
			if enemy:getHp()==1
			and not enemy:hasArmorEffect("Vine")
			and not self:hasEightDiagramEffect(enemy)
			and self:damageIsEffective(enemy)
			and self:isWeak(enemy) and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
			then useAll = true end
		end
		if not useAll then return end
		local suits = property(self,"mobileluanji_suitstring"):split("+")
		for _,fcard in ipairs(cards)do
			if table.contains(suits,fcard:getSuitString())
			or isCard("ArcheryAttack",fcard,self.player)
			or isCard("ArcheryAttack",fcard,self.player)
			or isCard("ExNihilo",fcard,self.player)
			or isCard("Peach",fcard,self.player)
			then continue end
			for _,scard in ipairs(cards)do
				if table.contains(suits,scard:getSuitString())
				or isCard("ArcheryAttack",scard,self.player)
				or isCard("ArcheryAttack",scard,self.player)
				or isCard("ExNihilo",scard,self.player)
				or isCard("Peach",scard,self.player)
				or AIValue.sameLegacyIdentity(fcard,scard)
				then continue end
				local archery = turn_clone(self,"mobileluanji","archery_attack",sgs.Card_NoSuit,0,{fcard:getKnownEffectiveId(),scard:getKnownEffectiveId()},request)
				local dummy_use = self:aiUseCard(archery)
				if dummy_use.card then return archery end
			end
		end
	end
end

--再起
sgs.ai_skill_use["@@mobilezaiqi"] = function(self,prompt)
	local n = self.player:getStrategyMark("mobilezaiqi-Clear")
	n = math.min(n,#self.friends)
	if n<=0 then return "." end

	local lost = self.player:getMaxHp()-self.player:getHp()
	self.friends = self:sort(self.friends,"handcard")
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
		return "@MobileZaiqiCard=.->"..table.concat(friends,"+")
	end
	return "."
end

sgs.ai_skill_choice.mobilezaiqi = function(self,choices,data)
	local to = data:toPlayer()
	choices = choices:split("+")
	if not self:isFriend(to) then
		if self.player:isKongcheng() and self:needKongcheng() and table.contains(choices,"recover") then return "recover" end
		return "draw"
	else
		if table.contains(choices,"recover") then return "recover" end
		return "draw"
	end
end

--烈刃
sgs.ai_cardneed.mobilelieren = function(to,card,self)
	return sgs.ai_cardneed.lieren(to,card,self)
end

sgs.ai_skill_invoke.mobilelieren = function(self,data)
	local to = data:toPlayer()
	if not self:isEnemy(to) then return false end

	local max_card = self:getMaxCard()
	if not max_card then return false end
	local point = max_card:getNumber()
	if self.player:hasSkill("tianbian") and max_card:getSuit()==sgs.Card_Heart then point = 13 end

	if self.player:getHandcardNum()==1 then
		if (self:needKongcheng() or not self:hasLoseHandcardEffective()) and not self:isWeak() then
			self:remember("mobilelieren_card",max_card:getKnownEffectiveId())
			return true
		end
		local card  = self.player:getHandcards():first()
		if card:isKindOf("Jink") or card:isKindOf("Peach") then return false end
	end

	if self:doDisCard(to,"he",true) then
		self:remember("mobilelieren_card",max_card:getKnownEffectiveId())
		return true
	end
end

function sgs.ai_skill_pindian.mobilelieren(minusecard,self,requestor)
	return sgs.ai_skill_pindian.lieren(minusecard,self,requestor)
end

--行殇
sgs.ai_skill_invoke.mobilexingshang = function(self,data)
	return self:canDraw() or self.player:getLostHp()>0
end

sgs.ai_skill_choice.mobilexingshang = function(self,choices,data)
	local choices = choices:split("+")
	local who = data:toDeath().who
	if not self:canDraw() and self.player:getLostHp()>0 then return "recover" end
	if self.player:getLostHp()>0 and self:willSkipPlayPhase() then return "recover" end
	if self:canDraw() then
		local peach = false
		for _,c in sgs.qlist(visible_hand(self,who))do  --做个弊
			if isCard("Peach",c,self.player) or isCard("Analeptic",c,self.player) then
				peach = true
				break
			end
		end
		if peach then return "get" end
		if self.player:getLostHp()>0 and self.player:getHp()<2 and not hasBuquEffect(self.player) then return "recover" end
		if (self.player:getHp()>=2 or hasBuquEffect(self.player)) and who:getHandcardNum()>=3 then return "get" end  --应该判断有有价值的卡牌且不虚弱，待补充
		if not peach and self.player:getLostHp()>0 then return "recover" end
	else
		if self.player:getLostHp()>0 then return "recover" end
	end
	return "get"
end

--放逐
sgs.ai_skill_playerchosen.mobilefangzhu = function(self,targets)
	return sgs.ai_skill_playerchosen.fangzhu(self,targets)
end

sgs.ai_skill_discard.mobilefangzhu = function(self,discard_num,min_num,optional,include_equip)
	if not self.player:faceUp() or self:needBear() then return {} end
	if self.player:getCardCount()-discard_num<=2 and self.player:getHp()<=2 then return {} end
	if self.player:getHp()>1 or hasBuquEffect(self.player) or self:getSaveNum(true)>0 then
		return self:askForDiscard("dummy",discard_num,min_num,false,include_equip)
	end
	return {}
end

sgs.ai_playerchosen_intention.mobilefangzhu = function(self,from,to)
	return sgs.ai_playerchosen_intention.fangzhu(self,from,to)
end

sgs.ai_need_damaged.mobilefangzhu = function (self,attacker,player)
	if not player:hasSkill("mobilefangzhu") then return false end
	local enemies = self:getEnemies(player)
	if #enemies<1 then return false end
	enemies = self:sort(enemies,"defense")
	for _,enemy in ipairs(enemies)do
		if player:getLostHp()<1 and self:toTurnOver(enemy,player:getLostHp()+1) then
			return true
		end
	end
	local friends = self:getFriends(player,true)
	friends = self:sort(friends,"defense")
	for _,friend in ipairs(friends)do
		if not self:toTurnOver(friend,player:getLostHp()+1) then return true end
	end
	return false
end

--破虏
sgs.ai_skill_use["@@mobilepolu"] = function(self,prompt,method)
	local n = self.player:getStrategyMark("mobilepolu_usedtimes")+1
	local friends = self.friends_noself
	if self.player:isAlive() then friends = self.friends end

	local targets = {}
	for _,p in ipairs(friends)do
		if not self:canDraw(p) or p:isDead() then continue end
		table.insert(targets,p:objectName())
	end

	if n==1 then
		for _,p in ipairs(self.enemies)do
			if not p:isKongcheng() or not self:needKongcheng(p) or p:isDead() then continue end
			table.insert(targets,p:objectName())
		end
	end
	return "@MobilePoluCard=.->"..table.concat(targets,"+")
end

sgs.ai_card_intention.MobilePoluCard = function(self,card,from,tos)
	for _,to in ipairs(tos)do
		if hasManjuanEffect(to) then continue end
		local intention = -80
		if to:isKongcheng() and self:needKongcheng(to)
		then intention = 80 end
		self:updateIntention(from,to,intention)
	end
end

--酒池

sgs.ai_fill_skill["mobilejiuchi"] = function(self,inclusive,request)
	local cards = self:addHandPile()
	local card
	cards = self:sortByUseValue(cards,true)
	for _,acard in ipairs(cards)  do
		if acard:getSuit()==sgs.Card_Spade then
			card = acard
			break
		end
	end
	if not card then return nil end
	local analeptic = turn_clone(self,"mobilejiuchi","analeptic",sgs.Card_Spade,0,{card:getKnownEffectiveId()},request)
	if self:readonlyTurnAvailability(analeptic)
	then return analeptic end
end

sgs.ai_view_as.mobilejiuchi = function(card,player,card_place)
	local str = sgs.ai_view_as.jiuchi(card,player,card_place)
	if not str or str=="" or str==nil then return end
	if type(str)=="table"then local copy={};for k,v in pairs(str)do copy[k]=v end;copy.skill="mobilejiuchi";return copy end
 return string.gsub(str,"jiuchi","mobilejiuchi")
end

function sgs.ai_cardneed.mobilejiuchi(to,card,self)
	return sgs.ai_cardneed.jiuchi(to,card,self)
end

--屯田
sgs.ai_skill_invoke.mobiletuntian = function(self,data)
	return sgs.ai_skill_invoke.tuntian(self,data)
end

--挑衅

sgs.ai_fill_skill["mobiletiaoxin"] = function(self,inclusive,request)
	return parse_policy(self,"@MobileTiaoxinCard=.")
end

sgs.ai_skill_use_func.MobileTiaoxinCard = function(card,use,self)
	local distance = use.DefHorse and 1 or 0
	local targets = {}
	for _,enemy in ipairs(self.enemies)do
		if self:doDisCard(enemy,"he") and self:isTiaoxinTarget(enemy)
		then table.insert(targets,enemy) end
	end

	if #targets==0 then return end

	self:setPriorityValue("MobileTiaoxinCard",8,"mobile_st_standard")
	if not self.player:getArmor() and not self.player:isKongcheng() then
		for _,card in sgs.qlist(self.player:getCards("h"))do
			if card:isKindOf("Armor") and self:evaluateArmor(card)>3 then
				self:setPriorityValue("MobileTiaoxinCard",5.9,"mobile_st_standard")
				break
			end
		end
	end

	targets = self:sort(targets,"defenseSlash")
	use.to:append(targets[1])
	use.card = selected_policy(self,"@MobileTiaoxinCard=.")
end

sgs.ai_card_intention.MobileTiaoxinCard = sgs.ai_card_intention.TiaoxinCard
sgs.ai_use_priority.MobileTiaoxinCard = sgs.ai_use_priority.TiaoxinCard

sgs.ai_skill_cardask["@mobiletiaoxin-slash"] = function(self,data,pattern,target)
	return sgs.ai_skill_cardask["@tiaoxin-slash"](self,data,pattern,target)
end

--志继
sgs.ai_skill_choice.mobilezhiji = function(self,choice)
	return sgs.ai_skill_choice.zhiji(self,choice)
end

--悲歌
sgs.ai_skill_cardask["@mobilebeige"] = function(self,data)
	return sgs.ai_skill_cardask["@beige"](self,data)
end

--直谏

sgs.ai_fill_skill["mobilezhijian"] = function(self,inclusive,request)
	local equips = {}
	for _,card in sgs.qlist(self.player:getHandcards())do
		if card:getTypeId()==sgs.Card_TypeEquip then
			table.insert(equips,card)
		end
	end
	if #equips==0 then return end

	return parse_policy(self,"@MobileZhijianCard=.")
end

sgs.ai_skill_use_func.MobileZhijianCard = function(card,use,self)
	local equips = {}
	for _,card in sgs.qlist(self.player:getHandcards())do
		if card:isKindOf("Armor") or card:isKindOf("Weapon") then
			if not self:getSameEquip(card) then
			elseif card:isKindOf("GudingBlade") and self:getCardsNum("Slash")>0 then
				local HeavyDamage
				local slash = self:getCard("Slash")
				for _,enemy in ipairs(self.enemies)do
					if self.player:canSlash(enemy,slash,true) and not self:slashProhibit(slash,enemy) and
						self:slashIsEffective(slash,enemy) and not self:hasJueqingEffect(self.player,enemy) and enemy:isKongcheng() then
							HeavyDamage = true
							break
					end
				end
				if not HeavyDamage then table.insert(equips,card) end
			else
				table.insert(equips,card)
			end
		elseif card:getTypeId()==sgs.Card_TypeEquip then
			table.insert(equips,card)
		end
	end

	if #equips==0 then return end

	local select_equip,target
	for _,friend in ipairs(self.friends_noself)do
		for _,equip in ipairs(equips)do
			local index = known(equip:getEquipSlot(),"equipment location")
			if not friend:hasEquipArea(index) then continue end
			if not self:getSameEquip(equip,friend) and self:hasSkills(sgs.need_equip_skill.."|"..sgs.lose_equip_skill,friend) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
		for _,equip in ipairs(equips)do
			local index = known(equip:getEquipSlot(),"equipment location")
			if not friend:hasEquipArea(index) then continue end
			if not self:getSameEquip(equip,friend) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
	end

	if not target then return end
	use.to:append(target)
	local zhijian = selected_policy(self,"@MobileZhijianCard="..select_equip:getId())
	use.card = zhijian
end

sgs.ai_card_intention.MobileZhijianCard = sgs.ai_card_intention.ZhijianCard
sgs.ai_use_priority.MobileZhijianCard = sgs.ai_use_priority.ZhijianCard
sgs.ai_cardneed.mobilezhijian = sgs.ai_cardneed.zhijian

--放权
sgs.ai_skill_invoke.mobilefangquan = function(self,data)
	return sgs.ai_skill_invoke.fangquan(self,data)
end

sgs.ai_skill_use["@@mobilefangquan"] = function(self,prompt)
    return mobile_fangquan(self,prompt)
end

--破军
sgs.ai_skill_invoke.mobilepojun = function(self,data)
    local target = data:toPlayer()
    if not self:isFriend(target) then return true end
    return false
end

sgs.ai_skill_choice.mobilepojun_num = function(self,choices,data)
	local items = choices:split("+")
	return items[#items]
end

sgs.ai_use_revises.mobilepojun = function(self,card,use)
	if card:isKindOf("Slash") then
		self:setStrategyCardFlag(card,"Qinggang",true)
	end
end

--甘露

sgs.ai_fill_skill["mobileganlu"] = function(self,inclusive,request)
	return parse_policy(self,"@MobileGanluCard=.")
end

sgs.ai_skill_use_func.MobileGanluCard = function(card,use,self)
	local lost_hp = self.player:getLostHp()
	local target,min_friend,max_enemy

	local compare_func = function(a,b)
		return a:getEquips():length()>b:getEquips():length()
	end
	table.sort(self.enemies,compare_func)
	table.sort(self.friends,compare_func)

	self.friends = sgs.reverse(self.friends)

	for _,friend in ipairs(self.friends)do
		for _,enemy in ipairs(self.enemies)do
			if not enemy:hasSkills(sgs.lose_equip_skill)
			and not hasTuntianEffect(enemy,true)
			and friend:getPile("wooden_ox"):isEmpty() then
				local ee = enemy:getEquips():length()
				local fe = friend:getEquips():length()
				local value = self:evaluateArmor(enemy:getArmor(),friend)-self:evaluateArmor(friend:getArmor(),enemy)-self:evaluateArmor(nil,friend)+self:evaluateArmor(nil,enemy)
				if (math.abs(ee-fe)<=lost_hp or friend==self.player) and ee>0 and (ee>fe or ee==fe and value>0) then
					if friend:hasSkills(sgs.lose_equip_skill) then
						use.card = select_card(self,card,"MobileGanluCard")
						use.to:append(friend)
						use.to:append(enemy)
						return
					elseif not min_friend and not max_enemy then
						min_friend = friend
						max_enemy = enemy
					end
				end
			end
		end
	end
	if min_friend and max_enemy then
		use.card = select_card(self,card,"MobileGanluCard")
		use.to:append(min_friend)
		use.to:append(max_enemy)
		return
	end

	for _,friend in ipairs(self.friends)do
		if self:needToThrowArmor(friend)
		or ((friend:hasSkills(sgs.lose_equip_skill) or hasTuntianEffect(friend,true)) and friend:getEquips():length()>0) then
			target = friend
			break
		end
	end
	if not target then return end
	for _,friend in ipairs(self.friends)do
		if friend~=target and ((friend==self.player or target==self.player)
			or math.abs(friend:getEquips():length()-target:getEquips():length())<=lost_hp) then
			use.card = select_card(self,card,"MobileGanluCard")
			use.to:append(friend)
			use.to:append(target)
			return
		end
	end
end

sgs.ai_use_priority.MobileGanluCard = sgs.ai_use_priority.GanluCard
sgs.dynamic_value.control_card.MobileGanluCard = true

sgs.ai_card_intention.MobileGanluCard = function(self,card,from,to)
	local compare_func = function(a,b)
		return a:getEquips():length()<b:getEquips():length()
	end
	table.sort(to,compare_func)
	for i = 1,2,1 do
		if to[i]:hasArmorEffect("SilverLion") then
			self:updateIntention(from,to[i],-20)
			break
		end
	end
	if to[1]:getEquips():length()<to[2]:getEquips():length() then
		self:updateIntention(from,to[1],-80)
	end
end

--节钺
sgs.ai_skill_askforyiji.mobilejieyue = function(self,card_ids)
    local cards = {}
	for c,id in sgs.list(card_ids)do
		c = known_card(self,id)
		table.insert(cards,c)
	end
    cards = self:sortByKeepValue(cards)
	local tos = self.room:getOtherPlayers(self.player)
	tos = self:sort(tos,"card")
	for _,p in sgs.list(tos)do
	   	if self:isFriend(p)
		then return p,cards[1]:getKnownEffectiveId() end
	end
	tos = self:sort(tos,"card",true)
	for _,p in sgs.list(tos)do
	   	if not self:isEnemy(p)
		then return p,cards[1]:getKnownEffectiveId() end
	end
	for _,p in sgs.list(tos)do
	   	if self:isEnemy(p)
		and #cards>2
		then return p,cards[1]:getKnownEffectiveId() end
	end
end

sgs.ai_skill_use["@@mobilejieyue"] = function(self,prompt)
	local valid = {}
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if #cards-#valid<=1 then break end
        table.insert(valid,h:getKnownEffectiveId())
	end
    cards = self.player:getCards("e")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
   	local target = self.room:getCurrent()
	local n = 0
	for _,h in sgs.list(cards)do
		if #cards-n<=1 then break end
        table.insert(valid,h:getKnownEffectiveId())
		n = n+1
	end
	if self:isEnemy(target)
	and #valid<4
	then
		return string.format("@MobileJieyueCard=%s",table.concat(valid,"+"))
	end
end

--伏枥
sgs.ai_skill_invoke.mobilefuli = true

--安恤

sgs.ai_fill_skill["mobileanxu"] = function(self,inclusive,request)
	return parse_policy(self,"@MobileAnxuCard=.")
end

sgs.ai_skill_use_func.MobileAnxuCard = function(card,use,self)
	if #self.enemies==0 then return end
	self.friends_noself = self:sort(self.friends_noself,"handcard")

	--friend获得enemy的牌
	for _,friend in ipairs(self.friends_noself)do
		if not self:canDraw(friend) or ZishuEffect(friend)<=0 then continue end
		local n = 2+ZishuEffect(friend)
		for _,enemy in ipairs(self.enemies)do
			if not self:doDisCard(enemy,"he",true) or friend:getHandcardNum()+n>enemy:getHandcardNum() then continue end
			use.card = select_card(self,card,"MobileAnxuCard")
			use.to:append(friend)
			use.to:append(enemy)
			return
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if not self:canDraw(friend) then continue end
		for _,enemy in ipairs(self.enemies)do
			if not self:doDisCard(enemy,"he",true) or friend:getHandcardNum()+2>enemy:getHandcardNum() then continue end
			use.card = select_card(self,card,"MobileAnxuCard")
			use.to:append(friend)
			use.to:append(enemy)
			return
		end
	end

	--friend获得中立角色的牌
	for _,friend in ipairs(self.friends_noself)do
		if not self:canDraw(friend) or ZishuEffect(friend)<=0 then continue end
		local n = 2+ZishuEffect(friend)
		for _,p in sgs.qlist(self.room:getOtherPlayers(friend))do
			if self:isFriend(p) or self:isEnemy(p) or not self:doDisCard(p,"he",true) or friend:getHandcardNum()+n>p:getHandcardNum() then continue end
			use.card = select_card(self,card,"MobileAnxuCard")
			use.to:append(friend)
			use.to:append(p)
			return
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if not self:canDraw(friend) then continue end
		for _,p in sgs.qlist(self.room:getOtherPlayers(friend))do
			if self:isFriend(p) or self:isEnemy(p) or self:doDisCard(p,"he",true) or friend:getHandcardNum()+2>p:getHandcardNum() then continue end
			use.card = select_card(self,card,"MobileAnxuCard")
			use.to:append(friend)
			use.to:append(p)
			return
		end
	end

	--friend获得friend的牌
	local friends = self.friends_noself
	friends = sgs.reverse(friends)

	for _,friend in ipairs(self.friends_noself)do
		if not self:canDraw(friend) or ZishuEffect(friend)<=0 then continue end
		local n = 2+ZishuEffect(friend)
		for _,fri in ipairs(friends)do
			if friend:objectName()==fri:objectName() then continue end
			if self:doDisCard(fri,"he",true) and friend:getHandcardNum()+n>fri:getHandcardNum() then
				use.card = select_card(self,card,"MobileAnxuCard")
				use.to:append(friend)
				use.to:append(fri)
				return
			end
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if not self:canDraw(friend) then continue end
		for _,fri in ipairs(friends)do
			if friend:objectName()==fri:objectName() then continue end
			if self:doDisCard(fri,"he",true) and friend:getHandcardNum()+2>fri:getHandcardNum() then
				use.card = select_card(self,card,"MobileAnxuCard")
				use.to:append(friend)
				use.to:append(fri)
				return
			end
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if not self:canDraw(friend) or ZishuEffect(friend)<=0 then continue end
		local n = 2+ZishuEffect(friend)
		for _,fri in ipairs(friends)do
			if friend:objectName()==fri:objectName() then continue end
			if friend:getHandcardNum()+n>fri:getHandcardNum() then
				use.card = select_card(self,card,"MobileAnxuCard")
				use.to:append(friend)
				use.to:append(fri)
				return
			end
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if not self:canDraw(friend) then continue end
		for _,fri in ipairs(friends)do
			if friend:objectName()==fri:objectName() then continue end
			if friend:getHandcardNum()+2>fri:getHandcardNum() then
				use.card = select_card(self,card,"MobileAnxuCard")
				use.to:append(friend)
				use.to:append(fri)
				return
			end
		end
	end

	--friend获得enemy的牌
	for _,friend in ipairs(self.friends_noself)do
		if not self:canDraw(friend) then continue end
		for _,enemy in ipairs(self.enemies)do
			if not self:doDisCard(enemy,"he",true) then continue end
			use.card = select_card(self,card,"MobileAnxuCard")
			use.to:append(friend)
			use.to:append(enemy)
			return
		end
	end

	--friend获得中立角色的牌
	for _,friend in ipairs(self.friends_noself)do
		if not self:canDraw(friend) then continue end
		for _,p in sgs.qlist(self.room:getOtherPlayers(friend))do
			if p==self.player or not self:doDisCard(p,"he",true) then continue end
			use.card = select_card(self,card,"MobileAnxuCard")
			use.to:append(friend)
			use.to:append(p)
			return
		end
	end

	--enemy获得enemy来破坏kongcheng，待补充
end

sgs.ai_card_intention.MobileAnxuCard = sgs.ai_card_intention.AnxuCard
sgs.ai_use_priority.MobileAnxuCard = sgs.ai_use_priority.AnxuCard

sgs.ai_skill_invoke.mobileanxu = function(self,data)
	local player = data:toPlayer()
	return self:isFriend(player) and self:canDraw(player)
end

--旋风
sgs.ai_skill_invoke.mobilexuanfeng = function(self,data)
	local from,card,to = self:moveField(nil,"e",self.room:getOtherPlayers(self.player),self.room:getOtherPlayers(self.player))
	if from and card and to then
		sgs.ai_skill_choice.mobilexuanfeng = "move"
		sgs.ai_skill_playerchosen.mobilexuanfeng_from = from
		sgs.ai_skill_cardchosen.mobilexuanfeng = card:getId()
		sgs.ai_skill_playerchosen.mobilexuanfeng_to = to
		return true
	end
	if sgs.ai_skill_invoke.xuanfeng(self,data) then
		sgs.ai_skill_choice.mobilexuanfeng = "discard"
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.mobilexuanfeng = function(self,targets)
	return sgs.ai_skill_playerchosen.xuanfeng(self,targets)
end

sgs.ai_skill_cardchosen.mobilexuanfeng = function(self,who,flags)
	return sgs.ai_skill_cardchosen.xuanfeng(self,who,flags)
end

sgs.mobilexuanfeng_keep_value = sgs.xuanfeng_keep_value
sgs.ai_cardneed.mobilexuanfeng = sgs.ai_cardneed.xuanfeng

--酒诗
function sgs.ai_cardsview.mobilejiushi(self,class_name,player)
	if player:faceUp()
	then
		return ("analeptic:mobilejiushi[no_suit:0]=.")
	end
end

sgs.ai_skill_invoke.mobilejiushi = true

--弓骑

sgs.ai_fill_skill["mobilegongqi"] = function(self,inclusive,request)
	return parse_policy(self,"@MobileGongqiCard=.")
end

sgs.ai_skill_use_func.MobileGongqiCard = function(card,use,self)
	local to = self:findPlayerToDiscard("he",false,true)[1]
	if not to then return end

	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)

	local dis = {}
	for _,c in ipairs(cards)do
		if c:isKindOf("BasicCard") then continue end
		table.insert(dis,c)
	end
	if #dis<=0 then return end

	for _,c in ipairs(dis)do
		if (c:isKindOf("Dismantlement") or c:isKindOf("Snatch")) and self.player:canUse(c)
		then
			if self:aiUseCard(c).card
			then continue end
		end
		use.card = selected_policy(self,"@MobileGongqiCard="..c:getKnownEffectiveId())
		use.to:append(to)
		return
	end
end

sgs.ai_use_priority.MobileGongqiCard = sgs.ai_use_priority.Dismantlement

--权计
sgs.ai_skill_invoke.mobilequanji = function(self,data)
	return sgs.ai_skill_invoke.quanji(self,data)
end

sgs.ai_skill_discard.mobilequanji = function(self)
	return sgs.ai_skill_discard.quanji(self)
end

--疠火
function sgs.ai_cardneed.mobilelihuo(to,card,self)
	local slash = card:isKindOf("Slash") and not (card:isKindOf("FireSlash") or card:isKindOf("ThunderSlash"))
	return slash and getKnownCard(to,self.player,"Slash",false)==0
end

sgs.ai_skill_invoke.mobilelihuo = function(self,data)
	local use = data:toCardUse()
	local slash = use.card
	if slash:isVirtualCard() and slash:subcardsLength()>0 then
		for _,player in sgs.qlist(use.to)do
			if self:isEnemy(player) and self:isGoodTarget(player,self.enemies,slash)
			then
				if player:isChained() then return self:isGoodChainTarget(player,"F") end
				if player:hasArmorEffect("Vine") then return true end
			end
		end
	else
		return sgs.ai_skill_invoke.lihuo(self,data)
	end
	return false
end

--纵玄

sgs.ai_fill_skill["mobilezongxuan"] = function(self,inclusive,request)
	return parse_policy(self,"@MobileZongxuanCard=.")
end

sgs.ai_skill_use_func.MobileZongxuanCard = function(card,use,self)
	use.card = select_card(self,card,"MobileZongxuanCard")
end

sgs.ai_card_intention.MobileZongxuanCard = 10

sgs.ai_skill_discard.mobilezongxuan = function(self,discard_num,min_num,optional,include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	return {cards[1]:getKnownEffectiveId()}
end

sgs.ai_skill_use["@@mobilezongxuan"] = function(self,prompt)
	if self.player:getPhase()>=sgs.Player_Finish then return "." end
	local valuable
	for _,id in sgs.list(tag(self,"mobilezongxuanForAI","IntList"))do
		local card = known_card(self,id)
		if card:isKindOf("EquipCard") then
			for _,friend in ipairs(self.friends)do
				if not (card:isKindOf("Armor") and not friend:getArmor() and friend:hasSkills("bazhen|yizhong"))
				and (not self:getSameEquip(card,friend) or card:isKindOf("DefensiveHorse") or card:isKindOf("OffensiveHorse")
					or (card:isKindOf("Weapon") and self:evaluateWeapon(card)>self:evaluateWeapon(friend:getWeapon())-1)) then
					return "@MobileZongxuanPutCard="..id
				end
			end
		elseif self:isValuableCard(card) and not valuable then
			valuable = id
		end
	end
	if valuable then
		return "@MobileZongxuanPutCard="..valuable
	end
	return "."
end

--峻刑
sgs.ai_fill_skill["mobilejunxing"] = function(self,inclusive,request)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,"j")
  	if #cards>0 then
		return parse_policy(self,"@MobileJunxingCard="..cards[1]:getKnownEffectiveId())
	end
end

sgs.ai_skill_use_func["MobileJunxingCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard")
	for _,ep in sgs.list(self.enemies)do
		use.card = select_card(self,card,"MobileJunxingCard")
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.MobileJunxingCard = 9.4
sgs.ai_use_priority.MobileJunxingCard = 0.8

sgs.ai_skill_discard.mobilejunxing = function(self,max,min)
	if not self.player:faceUp() then return {} end
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,"j")
	local to_cards = {}
   	for _,h in sgs.list(cards)do
		if not self:isWeak() then
            table.insert(to_cards,h:getKnownEffectiveId())
			if #to_cards>=min then return to_cards end
		end
	end
	return {}
end

--绝策
sgs.ai_skill_playerchosen.mobilejuece = function(self,targets)
	return sgs.ai_skill_playerchosen.juece(self,targets)
end

sgs.ai_playerchosen_intention.mobilejuece = function(self,from,to)
	return sgs.ai_playerchosen_intention.juece(self,from,to)
end

--灭计
sgs.ai_fill_skill["mobilemieji"] = function(self,inclusive,request)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		if c:isBlack()
		and c:isKindOf("TrickCard")
		then
			return parse_policy(self,"@MobileMiejiCard="..c:getKnownEffectiveId())
		end
	end
end

sgs.ai_skill_use_func["MobileMiejiCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies,"card",true)
	for _,ep in sgs.list(self.enemies)do
		if ep:getCardCount()>1
		then
			use.card = select_card(self,card,"MobileMiejiCard")
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if ep:getCardCount()>0
		then
			use.card = select_card(self,card,"MobileMiejiCard")
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.MobileMiejiCard = 9.4
sgs.ai_use_priority.MobileMiejiCard = 3.8

sgs.ai_skill_use["@@mobilemieji!"] = function(self,prompt)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	local ids = {}
	for _,c in ipairs(cards)do
		if c:isKindOf("TrickCard")
		then
			return "@MobileMiejiDiscardCard="..c:getKnownEffectiveId()
		end
		if #ids>1
		then
			return "@MobileMiejiDiscardCard="..table.concat(ids,"+")
		end
		table.insert(ids,c:getId())
	end
	return "."
end

--陷阵

sgs.ai_fill_skill["mobilexianzhen"] = function(self,inclusive,request)
	return parse_policy(self,"@MobileXianzhenCard=.")
end

sgs.ai_skill_use_func.MobileXianzhenCard = function(card,use,self)
	self.enemies = self:sort(self.enemies,"handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount-1 end

	if slashcount>0  then
		for _,enemy in ipairs(self.enemies)do
			if enemy:getStrategyFlag("AI_HuangtianPindian") and enemy:getHandcardNum()==1 and self.player:canPindian(enemy) then
				self:remember("mobilexianzhen_card",max_card:getId())
				use.card = selected_policy(self,"@MobileXianzhenCard=.")
				use.to:append(enemy)
				self:setStrategyPlayerFlag(enemy,"AI_HuangtianPindian",false)
				return
			end
		end

		--[[local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = dummy_plan()
		self:useBasicCard(slash,dummy_use)--]]

		for _,enemy in ipairs(self.enemies)do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) and self:canAttack(enemy,self.player)
				and not self:canLiuli(enemy,self.friends_noself) and not self:findLeijiTarget(enemy,50,self.player) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point =enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point>enemy_max_point then
					self:remember("mobilexianzhen_card",max_card:getId())
					use.card = selected_policy(self,"@MobileXianzhenCard=.")
					use.to:append(enemy)
					return
				end
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) and self:canAttack(enemy,self.player)
				and not self:canLiuli(enemy,self.friends_noself) and not self:findLeijiTarget(enemy,50,self.player) then
				if max_point>=10 then
					self:remember("mobilexianzhen_card",max_card:getId())
					use.card = selected_policy(self,"@MobileXianzhenCard=.")
					use.to:append(enemy)
					return
				end
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByUseValue(cards,true)
	if (self:getUseValue(cards[1])<6 and self:getKeepValue(cards[1])<6) or self:getOverflow()>0 then
		for _,enemy in ipairs(self.enemies)do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) and not hasTuntianEffect(enemy, true) then
				self:remember("mobilexianzhen_card",cards[1]:getId())
				use.card = selected_policy(self,"@MobileXianzhenCard=.")
				use.to:append(enemy)
				return
			end
		end
	end
end

sgs.ai_cardneed.mobilexianzhen = function(to,card,self)
	return sgs.ai_cardneed.xianzhen(to,card,self)
end

function sgs.ai_skill_pindian.mobilexianzhen(minusecard,self,requestor)
	return sgs.ai_skill_pindian.xianzhen(minusecard,self,requestor)
end

sgs.ai_card_intention.MobileXianzhenCard = sgs.ai_card_intention.XianzhenCard
sgs.dynamic_value.control_card.MobileXianzhenCard = true
sgs.ai_use_value.MobileXianzhenCard = sgs.ai_use_value.XianzhenCard
sgs.ai_use_priority.MobileXianzhenCard = sgs.ai_use_priority.XianzhenCard

--巧说

sgs.ai_fill_skill["mobileqiaoshui"] = function(self,inclusive,request)
	if self:needBear() then return end
	return parse_policy(self,"@MobileQiaoshuiCard=.")
end

sgs.ai_skill_use_func.MobileQiaoshuiCard = function(card,use,self)
	local trick_num = 0
	for _,card in sgs.qlist(self.player:getHandcards())do
		if card:isNDTrick() and not card:isKindOf("Nullification") then trick_num = trick_num+1 end
	end
	self.enemies = self:sort(self.enemies,"handcard")
	local max_card = self:getMaxCard()
	if not max_card then return end
	local max_point = max_card:getNumber()
	if self.player:hasSkill("tianbian") and max_card:getSuit()==sgs.Card_Heart then max_point = 13 end

	for _,enemy in ipairs(self.enemies)do
		if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
			if max_point>enemy_max_point then
				self:remember("mobileqiaoshui_card",max_card:getKnownEffectiveId())
				use.card = select_card(self,card,"MobileQiaoshuiCard")
				use.to:append(enemy)
				return
			end
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) then
			if max_point>=10 then
				self:remember("mobileqiaoshui_card",max_card:getKnownEffectiveId())
				use.card = select_card(self,card,"MobileQiaoshuiCard")
				use.to:append(enemy)
				return
			end
		end
	end

	self.friends_noself = self:sort(self.friends_noself,"handcard")
	for index = #self.friends_noself,1,-1 do
		local friend = self.friends_noself[index]
		if self.player:canPindian(friend) then
			local friend_min_card = self:getMinCard(friend)
			local friend_min_point = friend_min_card and friend_min_card:getNumber() or 100
			if max_point>friend_min_point then
				self:remember("mobileqiaoshui_card",max_card:getKnownEffectiveId())
				use.card = select_card(self,card,"MobileQiaoshuiCard")
				use.to:append(friend)
				return
			end
		end
	end

	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum()==1 and zhugeliang:objectName()~=self.player:objectName()
		and self.player:canPindian(zhugeliang) then
		if max_point>=7 then
			self:remember("mobileqiaoshui_card",max_card:getKnownEffectiveId())
			use.card = select_card(self,card,"MobileQiaoshuiCard")
			use.to:append(zhugeliang)
			return
		end
	end

	for index = #self.friends_noself,1,-1 do
		local friend = self.friends_noself[index]
		if self.player:canPindian(friend) then
			if max_point>=7 then
				self:remember("mobileqiaoshui_card",max_card:getKnownEffectiveId())
				use.card = select_card(self,card,"MobileQiaoshuiCard")
				use.to:append(friend)
				return
			end
		end
	end

	if trick_num==0 or (trick_num<=2 and self.player:hasSkill("zongshih")) and not self:isValuableCard(max_card) then
		for _,enemy in ipairs(self.enemies)do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) and self:hasLoseHandcardEffective(enemy) then
				self:remember("mobileqiaoshui_card",max_card:getKnownEffectiveId())
				use.card = select_card(self,card,"MobileQiaoshuiCard")
				use.to:append(enemy)
				return
			end
		end
	end
	return "."
end

sgs.ai_use_priority.MobileQiaoshuiCard = 8
sgs.ai_card_intention.MobileQiaoshuiCard = 0

sgs.ai_skill_choice.mobileqiaoshui = function(self,choices,data)
	local use = data:toCardUse()
	if use.card:isKindOf("Collateral") then
		local dummy_use = dummy_plan(true,0,use.to)
		self:useCardCollateral(use.card,dummy_use)
		if dummy_use.card and dummy_use.to:length()==2 then
			local first = dummy_use.to:at(0):objectName()
			local second = dummy_use.to:at(1):objectName()
			write(self,"mobileqiaoshui_collateral",{ first,second })
			return "add"
		else
			write(self,"mobileqiaoshui_collateral",nil)
		end
	elseif use.card:isKindOf("Analeptic") then
	elseif use.card:isKindOf("Peach") then
		self.friends_noself = self:sort(self.friends_noself,"hp")
		for _,friend in ipairs(self.friends_noself)do
			if friend:isWounded() and friend:getHp()<getBestHp(friend) then
				write(self,"mobileqiaoshui_extra_target",friend)
				return "add"
			end
		end
	elseif use.card:isKindOf("ExNihilo") then
		local friend = self:findPlayerToDraw(false,2)
		if friend then
			write(self,"mobileqiaoshui_extra_target",friend)
			return "add"
		end
	elseif use.card:isKindOf("GodSalvation") then
		self.enemies = self:sort(self.enemies,"hp")
		for _,enemy in ipairs(self.enemies)do
			if enemy:isWounded() and self:hasTrickEffective(use.card,enemy,self.player) then
				write(self,"mobileqiaoshui_remove_target",enemy)
				return "remove"
			end
		end
	elseif use.card:isKindOf("AmazingGrace") then
		self.enemies = self:sort(self.enemies)
		for _,enemy in ipairs(self.enemies)do
			if self:hasTrickEffective(use.card,enemy,self.player) and not hasManjuanEffect(enemy)
				and not self:needKongcheng(enemy,true) then
				write(self,"mobileqiaoshui_remove_target",enemy)
				return "remove"
			end
		end
	elseif use.card:isKindOf("AOE") then
		self.friends_noself = self:sort(self.friends_noself)
		local lord = self.room:getLord()
		if lord and lord:objectName()~=self.player:objectName() and self:isFriend(lord) and self:isWeak(lord) then
			write(self,"mobileqiaoshui_remove_target",lord)
			return "remove"
		end
		for _,friend in ipairs(self.friends_noself)do
			if self:hasTrickEffective(use.card,friend,self.player) then
				write(self,"mobileqiaoshui_remove_target",friend)
				return "remove"
			end
		end
	elseif use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") then
		local trick = clone(self,"mobileqiaoshui","qiaoshui",use.card:objectName(),sgs.Card_NoSuit,0,{})
		local dummy_use = dummy_plan(true,0,use.to)
		self:useCardDismantlement(trick,dummy_use)
		if dummy_use.card and dummy_use.to:length()>0 then
			write(self,"mobileqiaoshui_extra_target",dummy_use.to:first())
			return "add"
		end
	elseif use.card:isKindOf("Slash") then
		local slash = clone(self,"mobileqiaoshui","qiaoshui",use.card:objectName(),sgs.Card_NoSuit,0,{})
		local dummy_use = dummy_plan(true,0,use.to)
		self:useCardSlash(slash,dummy_use)
		if dummy_use.card and dummy_use.to:length()>0 then
			write(self,"mobileqiaoshui_extra_target",dummy_use.to:first())
			return "add"
		end
	else
		local dummy_use = dummy_plan(true,0,use.to)
		self:useCardByClassName(use.card,dummy_use)
		if dummy_use.card and dummy_use.to:length()>0 then
			write(self,"mobileqiaoshui_extra_target",dummy_use.to:first())
			return "add"
		end
	end
	write(self,"mobileqiaoshui_extra_target",nil)
	write(self,"mobileqiaoshui_remove_target",nil)
	return "cancel"
end

sgs.ai_skill_playerchosen.mobileqiaoshui = function(self,targets)
	if not read(self,"mobileqiaoshui_extra_target") and not read(self,"mobileqiaoshui_remove_target") then diagnostic(self,"MobileQiaoshui player chosen error!!") end
	return read(self,"mobileqiaoshui_extra_target") or read(self,"mobileqiaoshui_remove_target")
end

sgs.ai_skill_use["@@mobileqiaoshui!"] = function(self,prompt) -- extra target for Collateral
	if not read(self,"mobileqiaoshui_collateral") then diagnostic(self,"MobileQiaoshui player chosen error!!") end
	return "@ExtraCollateralCard=.->"..read(self,"mobileqiaoshui_collateral")[1].."+"..read(self,"mobileqiaoshui_collateral")[2]
end

--纵适
sgs.ai_skill_invoke.mobilezongshih = true

sgs.ai_skill_use["@@mobilezongshih"] = function(self,prompt,method)
	local cards = {}
	local draw = tag(self,"mobilezongshih_drawForAI","IntList")
	local pdlist = tag(self,"mobilezongshih_pindianForAI","IntList")
	for _,id in sgs.qlist(draw)do
		local c = known_card(self,id)
		if self:canDraw() then
			table.insert(cards,c)
		else
			if self:willUse(self.player,c) then
				table.insert(cards,c)
			end
		end
	end
	for _,id in sgs.qlist(pdlist)do
		local c = known_card(self,id)
		if self:canDraw() then
			table.insert(cards,c)
		else
			if self:willUse(self.player,c) then
				table.insert(cards,c)
			end
		end
	end
	if #cards<=0 then return "." end
	cards = self:sortByCardNeed(cards,true)
	return "@MobileZongshihCard="..cards[1]:getKnownEffectiveId()
end

--胆守
sgs.ai_skill_discard.mobiledanshou = function(self,discard_num,min_num,optional,include_equip)
	local target = tag(self,"mobiledanshou_target","Player")
	if not target or target:isDead() then return {} end
	if not self:damageIsEffective(target,sgs.DamageStruct_Normal) then return {} end
	if self:isFriend(target) then
		if not self:needToLoseHp(target,self.player) then return {} end
		if self:getOverflow()>=min_num then
			local ids = self:askForDiscard("dummyreason",discard_num,min_num,false,include_equip)
			for _,id in ipairs(ids)do
				if known_card(self,id):isKindOf("Peach") then return {} end
			end
			return ids
		end
	end

	if self:isEnemy(target) then
		if self.player:getCardCount()-discard_num<=2 and self.player:getHp()<=2 then
			if target:getHp()>self:ajustDamage(self.player,target) or hasBuquEffect(target) then
				return {}
			end
		end
		local ids = self:askForDiscard("dummyreason",discard_num,min_num,false,include_equip)
		if target:getHp()>=self:ajustDamage(self.player,target) then
			for _,id in ipairs(ids)do
				if known_card(self,id):isKindOf("Peach") then return {} end
			end
		end
		return ids
	end
	return {}
end

--夺刀
sgs.ai_skill_invoke.mobileduodao = function(self,data)
	local from = data:toPlayer()
	if self:isFriend(from) then
		if from:hasSkills("kofxiaoji|xiaoji") and self:isWeak(damage.from) then return true
		else
			if self:getCardsNum("Slash")==0 or self:willSkipPlayPhase() then return "." end
			local invoke = false
			local range = sgs.weapon_range[from:getWeapon():getClassName()] or 0
			if self.player:hasSkills("anjian|mobileanjian") then
				for _,enemy in ipairs(self.enemies)do
					if not enemy:inMyAttackRange(self.player) and not self.player:inMyAttackRange(enemy) and self.player:distanceTo(enemy)<=range then
						invoke = true
						break
					end
				end
			end
			if not invoke and self:evaluateWeapon(from:getWeapon())>8 then invoke = true end
			if invoke then
				return true
			end
		end
	else
		if from:hasSkill("nosxuanfeng") then
			for _,friend in ipairs(self.friends)do
				if self:isWeak(friend) then return "." end
			end
		else
			return not (self:needKongcheng(self.player,true) and self.player:isKongcheng())
		end
	end
	return false
end

--暗箭
sgs.ai_skill_choice.mobileanjian = function(self,choices,data)
	local target = data:toPlayer()
	local use = tag(self,"mobileanjian_usedata","CardUse")
	local no_respond_list = use.no_respond_list
	local no_offset_list = use.no_offset_list
	if table.contains(no_respond_list,target:objectName()) or table.contains(no_respond_list,"_ALL_TARGETS") then return "damage" end
	if table.contains(no_offset_list,target:objectName()) or table.contains(no_offset_list,"_ALL_TARGETS") then return "damage" end
	if target:hasArmorEffect("EightDiagram") or getCardsNum("Jink",target,self.player)>0 or target:getHandcardNum()>=3 then return "noresponse" end
	return "damage"
end

--惴恐
sgs.ai_skill_invoke.mobilezhuikong = function(self,data)
	if self.player:getHandcardNum()<=(self:isWeak() and 2 or 1) then return false end
	local current = self.room:getCurrent()
	if not current or self:isFriend(current) then return false end

	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	if self.player:hasSkill("yingyang") then max_point = math.min(max_point+3,13) end
	if not (current:hasSkill("zhiji") and current:getStrategyMark("zhiji")==0 and current:getHandcardNum()==1) and not
		(current:hasSkill("mobilezhiji") and current:getStrategyMark("mobilezhiji")==0 and current:getHandcardNum()==1) then
		local enemy_max_card = self:getMaxCard(current)
		local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
		if enemy_max_card and current:hasSkill("yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
		if max_point>enemy_max_point or max_point>10 then
			self:remember("mobilezhuikong_card",max_card:getKnownEffectiveId())
			return true
		end
	end
	if current:distanceTo(self.player)==1 and not self:isValuableCard(max_card) then
		self:remember("mobilezhuikong_card",max_card:getKnownEffectiveId())
		return true
	end
	return false
end

--求援
sgs.ai_skill_playerchosen.mobileqiuyuan = function(self,targets)
	return sgs.ai_skill_playerchosen.qiuyuan(self,targets)
end

sgs.ai_skill_cardask["@mobileqiuyuan-give"] = function(self,data,pattern,target)
	return sgs.ai_skill_cardask["@tenyearqiuyuan-give"](self,data,pattern,target)
end

--精策
sgs.ai_skill_invoke.mobilejingce = function(self,data)
	return self:canDraw()
end

sgs.ai_fill_skill["mobiledingpin"] = function(self,inclusive,request)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		if self.player:getStrategyMark("dingpin_"..c:getType().."-Clear")>0
		or #cards<3 then continue end
		return parse_policy(self,"@MobileDingpinCard="..c:getKnownEffectiveId())
	end
end

sgs.ai_skill_use_func["MobileDingpinCard"] = function(card,use,self)
	self.friends = self:sort(self.friends,"hp")
	if not self.player:faceUp()
	then
		use.card = select_card(self,card,"MobileDingpinCard")
		use.to:append(self.player)
		return
	end
	for _,ep in sgs.list(self.friends)do
		if ep:getHp()<=self.player:getHp()
		then
			use.card = select_card(self,card,"MobileDingpinCard")
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.MobileDingpinCard = 9.4
sgs.ai_use_priority.MobileDingpinCard = 4.8

sgs.ai_skill_invoke.mobilezhongyong = function(self,data)
    return true
end

sgs.ai_skill_playerchosen.mobilezhongyong = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

sgs.ai_fill_skill["mobileshenxing"] = function(self,inclusive,request)
	if self.player:usedTimes("MobileShenxingCard")>=self.player:getHp()
	then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	local toids = {}
	local color
  	for _,c in sgs.list(cards)do
		if #toids>=2 then break end
		if table.contains(self:getPriorTurnUseCards(),c)
		or color and color~=c:getColor()
		then continue end
		if self:getKeepValue(c)<4
		then
			color = c:getColor()
			table.insert(toids,c:getKnownEffectiveId())
		end
	end
  	for _,c in sgs.list(cards)do
		if #toids>=2 then break end
		if table.contains(self:getPriorTurnUseCards(),c)
		or table.contains(toids,c:getKnownEffectiveId())
		then continue end
		if self:getKeepValue(c)<4
		then
			table.insert(toids,c:getKnownEffectiveId())
		end
	end
	local ids = #toids>0 and table.concat(toids,"+") or "."
	if #toids>=2 then return parse_policy(self,"@MobileShenxingCard="..ids) end
end

sgs.ai_skill_use_func["MobileShenxingCard"] = function(card,use,self)
	use.card = select_card(self,card,"MobileShenxingCard")
end

sgs.ai_use_value.MobileShenxingCard = 4.4
sgs.ai_use_priority.MobileShenxingCard = 2.8

sgs.ai_skill_use["@@mobilebingyi"] = function(self,prompt)
	local valid,n = {},0
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
	for _,h in sgs.list(cards)do
		if h:getColor()~=cards[1]:getColor()
		then return end
    	n = n+1
	end
    table.insert(valid,self.player:objectName())
	for _,p in sgs.list(self.player:getAliveSiblings())do
      	if self:isFriend(p) and #valid<n
    	then table.insert(valid,p:objectName()) end
	end
	if #valid<1 then return end
	return ("@MobileBingyiCard=.->"..table.concat(valid,"+"))
end

sgs.ai_skill_invoke.mobileqieting = function(self,data)
    return true
end

sgs.ai_skill_choice.mobileqieting = function(self,choices,data)
	local target = data:toPlayer()
	local items = choices:split("+")
	if table.contains(items,"draw")
	and self:isFriend(target)
	then return "draw" end
	if target:getHandcardNum()>=2
	then return items[1] end
	if target:hasEquip()
	then return items[2] end
	if table.contains(items,"draw")
	then return "draw" end
end

sgs.ai_fill_skill["mobilejianying"] = function(self,inclusive,request)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
	if #cards<1 then return end
	for _,name in sgs.list(known(AICardCatalog.patternNames(),"patterns"))do
		local c = self:getEvaluationCard(name)
		local card = tag(self,"mobilejianying","Card")
		if card then c = clone(self,"mobilejianying","",name,card:getSuit(),0,{})end
		if c==nil or self:getCardsNum(c:getClassName())>0
		or c:getTypeId()~=1 then continue end
		c = clone(self,"mobilejianying","",name,c:getSuit(),c:getNumber(),{cards[1]:getKnownEffectiveId()})
		if c:isAvailable(self.player) then
         	local dummy = self:aiUseCard(c)
    		if dummy.card and dummy.to then
                if c:canRecast()
				and dummy.to:length()<1
				then continue end
				write(self,"jy_to",dummy.to)
				self:setPriorityValue("MobileJianyingCard",sgs.ai_use_priority[c:getClassName()],"mobile_st_standard")
                return parse_policy(self,"@MobileJianyingCard="..cards[1]:getKnownEffectiveId()..":"..name)
			end
		end
	end
end

sgs.ai_skill_use_func["MobileJianyingCard"] = function(card,use,self)
	use.card = select_card(self,card,"MobileJianyingCard")
	use.to = read(self,"jy_to")
end

sgs.ai_use_value.JinzhiCard = 10.4
sgs.ai_use_priority.JinzhiCard = 10.4

sgs.ai_use_revises.mobilejianying = function(self,card,use)
	local card = tag(self,"mobilejianying","Card")
	if #self:getPriorTurnUseCards()>0 and card then
		for _,c in sgs.list(self:getPriorTurnUseCards())do
			if c:getSuit()==card:getSuit()
			then card = c return end
		end
		for _,c in sgs.list(self:getPriorTurnUseCards())do
			if c:getNumber()==card:getNumber()
			then card = c return end
		end
	end
end

sgs.ai_skill_invoke.mobilejianying = function(self,data)
	return sgs.ai_skill_invoke.jianying(self,data)
end

sgs.ai_fill_skill["mobileyanzhu"] = function(self,inclusive,request)
	return parse_policy(self,"@MobileYanzhuCard=.")
end

sgs.ai_skill_use_func["MobileYanzhuCard"] = function(card,use,self)
	for _,ep in sgs.list(self.friends_noself)do
		if self:doDisCard(ep,"ej")
		then
			use.card = select_card(self,card,"MobileYanzhuCard")
			use.to:append(ep)
			return
		end
	end
	self.enemies = self:sort(self.enemies,"equip")
	for _,ep in sgs.list(self.enemies)do
		if ep:getEquips():length()>1
		then
			use.card = select_card(self,card,"MobileYanzhuCard")
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if ep:getCardCount()>1
		then
			use.card = select_card(self,card,"MobileYanzhuCard")
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.MobileYanzhuCard = 9.4
sgs.ai_use_priority.MobileYanzhuCard = 5.8

sgs.ai_skill_use["@@mobilexingxue"] = function(self,prompt)
	local valid = {}
	local destlist = self.room:getAllPlayers()
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
    destlist = self:sort(destlist,"hp")
	local xingxue = property(self,"MobileXingxueLevelUp","Bool")
    local n = xingxue and self.player:getMaxHp() or self.player:getHp()
	for _,friend in sgs.list(destlist)do
		if #valid>=n then break end
		if self:isFriend(friend) then table.insert(valid,friend:objectName()) end
	end
	for _,friend in sgs.list(destlist)do
		if #valid>=n then break end
		if table.contains(valid,friend:objectName()) then continue end
		if not self:isEnemy(friend) then table.insert(valid,friend:objectName()) end
	end
	if #valid>0
	then
    	return string.format("@MobileXingxueCard=.->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_playerchosen.mobileanguo = function(self,players)
    for _,p in sgs.list(self.room:getAllPlayers())do
		if p:getStrategyMark("&mobileanguo")>0 and self:isFriend(p) and not self:isWeak(p)
		then return end
	end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,nil,true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

sgs.ai_skill_choice.mobileanguo = function(self,choices,data)
	return "hp"
end

sgs.ai_skill_discard.mobilebenxi = function(self,max,min)
	local useds = self:getTurnUse()
	if #useds<1 then return {} end
   	for _,h in sgs.list(useds)do
		if h:getTypeId()>0 then
			if h:isDamageCard() or h:isNDTrick() then break end
			return {}
		end
	end
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,"j")
	local to_cards = {}
   	for _,h in sgs.list(cards)do
		if #to_cards<=#self.enemies and self:getKeepValue(h)<6 and not contains_identity(useds,h) then
            table.insert(to_cards,h:getKnownEffectiveId())
		end
	end
	return to_cards
end

sgs.ai_skill_playerschosen.mobilebenxi = function(self,players,x,n)
 return self:withNestedDelegateUse("mobilebenxi",function(use,facts)
	local tos = {}
    for i=0,x do
		local to = sgs.ai_skill_playerchosen.jincanmou(self,players)
		if to then
            -- Fixed source reads free global p, not the chosen `to`. Only the
            -- immutable audited nil observation can reproduce that branch.
            if facts.global_p_known_nil ~= true then ai_unsupported("source global p is not known nil","mobilebenxi.global_p") end
            local p = nil
			table.insert(tos,p)
			players:removeOne(p)
		else
			break
		end
	end
    return tos
 end)
end

sgs.ai_skill_playerschosen.mobilepingkou = function(self,players,x,n)
	local tos = {}
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if #tos<x and self:isEnemy(p)
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<x and not table.contains(tos,p) and not self:isFriend(p)
		then table.insert(tos,p) end
	end
    return tos
end

sgs.ai_fill_skill["mobilefurong"] = function(self,inclusive,request)
	return parse_policy(self,"@MobileFurongCard=.")
end

sgs.ai_skill_use_func["MobileFurongCard"] = function(card,use,self)
	self.enemies = self:sort(self.enemies)
	for _,ep in sgs.list(self.enemies)do
		if ep:getCardCount()>1 then
			use.card = select_card(self,card,"MobileFurongCard")
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		use.card = select_card(self,card,"MobileFurongCard")
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.MobileFurongCard = 9.4
sgs.ai_use_priority.MobileFurongCard = 5.8

sgs.ai_fill_skill["mobileyaoming"] = function(self,inclusive,request)
	return parse_policy(self,"@MobileYaomingCard=.")
end

sgs.ai_skill_use_func["MobileYaomingCard"] = function(card,use,self)
	self.friends_noself = self:sort(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if p:getHandcardNum()>=self.player:getHandcardNum() and self:doDisCard(p,"he") then
			use.card = select_card(self,card,"MobileYaomingCard")
			use.to:append(p)
			return
		end
	end
	self.enemies = self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>=self.player:getHandcardNum() and self:doDisCard(p,"he") then
			use.card = select_card(self,card,"MobileYaomingCard")
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.friends_noself)do
		if p:getHandcardNum()<=self.player:getHandcardNum() and self:canDraw(p) and self:getOverflow(p)<1 then
			use.card = select_card(self,card,"MobileYaomingCard")
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.MobileYaomingCard = 9.4
sgs.ai_use_priority.MobileYaomingCard = 5.8

sgs.ai_skill_use["@@mobileyaoming"] = function(self,prompt)
	self.friends_noself = self:sort(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if p:getHandcardNum()>=self.player:getHandcardNum() and self:doDisCard(p,"he") then
			return string.format("@MobileYaomingCard=.->%s",p:objectName())
		end
	end
	self.enemies = self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>=self.player:getHandcardNum() and self:doDisCard(p,"he") then
			return string.format("@MobileYaomingCard=.->%s",p:objectName())
		end
	end
	for _,p in sgs.list(self.friends_noself)do
		if p:getHandcardNum()<=self.player:getHandcardNum() and self:canDraw(p) and self:getOverflow(p)<1 then
			return string.format("@MobileYaomingCard=.->%s",p:objectName())
		end
	end
end

sgs.ai_skill_choice.mobileyaoming = function(self,choices,data)
	local target = data:toPlayer()
	local items = choices:split("+")
	if table.contains(items,"discard")
	and self:doDisCard(target,"he")
	then return "discard" end
end

sgs.ai_skill_use["@@mobilesidi"] = function(self,prompt)
	local tos = self.room:getAllPlayers()
	tos = self:sort(tos,nil,true)
	for _,p in sgs.list(tos)do
		if p~=self.player and p:getStrategyMark("mobilesidiFrom"..self.player:objectName())<1 and self:getOverflow()>0 then
			for _,q in sgs.list(tos)do
				if p~=q and self:isEnemy(p,q) then
					return string.format("@MobileSidiCard=.->%s+%s",p:objectName(),q:objectName())
				end
			end
		end
	end
end

sgs.ai_skill_choice.mobilesidi = function(self,choices,data)
	local use = data:toCardUse()
	local items = choices:split("+")
	if table.contains(items,"mobilesidi1")
	and use.card:isDamageCard()
	and self:isFriend(use.to:first())
	then return "mobilesidi1" end
	return "mobilesidi2"
end

sgs.ai_skill_invoke.mobileqingxi = function(self,data)
    local to = data:toPlayer()
	return not self:isFriend(to)
end

sgs.ai_skill_discard.mobileqingxi = function(self,max,min)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,"j")
	local to_cards = {}
   	for _,h in sgs.list(cards)do
		if self:getKeepValue(h)<7 then
            table.insert(to_cards,h:getKnownEffectiveId())
			if #to_cards>=min then return to_cards end
		end
	end
	return {}
end

sgs.ai_skill_invoke.mobilezhengzi = function(self,data)
	return self.player:isWounded() or self.player:isChained() or not self.player:faceUp()
end

sgs.ai_skill_invoke.mobileshensu = function(self,data)
	local dc = clone(self,"mobileshensu","shensu","slash",sgs.Card_NoSuit,0,{})
	return self:aiUseCard(dc).card~=nil
end

sgs.ai_skill_choice.mobileshensu = function(self,choices,data)
	local items = choices:split("+")
	local dc = clone(self,"mobileshensu","shensu","slash",sgs.Card_NoSuit,0,{})
	local bts = {}
   	for _,p in sgs.list(self.room:getAllPlayers())do
		if p:getStrategyMark("mobileshensuBan-Clear")>0 then
			table.insert(bts,p)
		end
	end
	local d = self:aiUseCard(dc,dummy_plan(nil,0,bts))
	if d.card then
		write(self,"mobileshensu_to",d.to)
		return items[1]
	end
	return items[#items]
end

sgs.ai_skill_use["@@mobileshensu"] = function(self,prompt)
	local tos = {}
	for _,p in sgs.list(read(self,"mobileshensu_to"))do
		table.insert(tos,p:objectName())
	end
	return string.format("@MobileShensuCard=.->%s",table.concat(tos,"+"))
end







for _,key in ipairs({'@@mobileqingjian!','@@mobilezaiqi','@@mobilepolu','@@mobilefangquan','@@mobilejieyue','@@mobilezongxuan','@@mobilemieji!','@@mobileqiaoshui!','@@mobilezongshih','@@mobilebingyi','@@mobilexingxue','@@mobileyaoming','@@mobilesidi','@@mobileshensu'})do local source=sgs.ai_skill_use[key];sgs.ai_skill_use[key]=function(self,...)return response_wire(self,source(self,...))end end
