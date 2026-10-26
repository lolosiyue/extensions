local raw_tenyeartuxi
-- Tenyear Standard fixed b6025acc. Native authority remains separate from source plans.
local known = AIValue.requireKnown

local function known_card(self,id)return known(self:getKnownCardById(id),"disclosed card "..tostring(id))end
local function visible_hand(self,p)local cards=known(p:getKnownCards(),"known hand");if #cards~=p:getHandcardNum()then ai_unsupported("source enumerates undisclosed dead hand","mobilexingshang")end;return cards end
local function property(self,k,kind)
 local v=self.player:getPropertyValue(k)
 if kind=="Bool"then return v==true elseif kind=="Int"then return tonumber(v)or 0 end
 if v==nil then return""end;return v
end
-- The viewer's own tag; absent reads as the donor's empty toInt/toIntList, otherwise nil.
local function tag(self,k,kind)
 local row=self.player:getTag(k)
 if row==nil then if kind=="Int"then return 0 elseif kind=="IntList"then return AIList.new({})end;return nil end
 if kind=="Player"then return known(self.room:findPlayerByObjectName(row,true),k)
 elseif kind=="Card"then return CardView.new(row)
 elseif kind=="CardUse"then local to=AIList.new({});for _,name in ipairs(row.to or{})do to:append(known(self.room:findPlayerByObjectName(name,true),k))end;return{card=row.card and CardView.new(row.card),from=row.from and self.room:findPlayerByObjectName(row.from,true),to=to,no_respond_list=row.no_respond_list,no_offset_list=row.no_offset_list}
 elseif kind=="Int"then return row elseif kind=="Damage"then return{from=row.from and self.room:findPlayerByObjectName(row.from,true),to=row.to and self.room:findPlayerByObjectName(row.to,true),card=row.card and CardView.new(row.card),damage=row.amount,nature=row.nature} else return AIList.new(row)end
end
local function write(self,k,v)
 if k=="qm_lose"or k=="tenyearzhenjun_discard"then
 elseif k=="tenyearqiaoshui_to"or k=="tenyearxiansi_to"then if v then local ns={};for _,p in sgs.list(v)do ns[#ns+1]=p:objectName()end;v=ns end
 else v=v and v:objectName()end
 self:setStrategyMemory("tenyear_st_standard."..k,v==nil and false or v)
end
local function read(self,k)
 local v,ok=self:getStrategyMemory("tenyear_st_standard."..k);if not ok or v==false then return nil end
 if k=="qm_lose"or k=="tenyearzhenjun_discard"then return v
 elseif k=="tenyearqiaoshui_to"or k=="tenyearxiansi_to"then local ps=AIList.new({});for _,name in ipairs(v)do ps:append(known(self.room:findPlayerByObjectName(name,true),k))end;return ps
 else return known(self.room:findPlayerByObjectName(v,true),k)end
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
local function set_jincanmou(self,use)ai_unsupported("source temporary JincanmouData adapter unavailable","mobilebenxi")end
local classes={['TenyearZhihengCard']='tenyearzhiheng',['TenyearJieyinCard']='tenyearjieyin',['TenyearYijueCard']='tenyearyijue',['TenyearQingjianCard']='tenyearqingjian',['TenyearTuxiCard']='tenyeartuxi',['TenyearQingnangCard']='tenyearqingnang',['TenyearQimouCard']='tenyearqimou',['TenyearShensuCard']='tenyearshensu',['TenyearTianxiangCard']='tenyeartianxiang',['OLTianxiangCard']='oltianxiang',['TenyearSanyaoCard']='tenyearsanyao',['TenyearChunlaoWineCard']='tenyearchunlaowine',['TenyearJiangchiCard']='tenyearjiangchi',['TenyearWurongCard']='tenyearwurong',['ExtraCollateralCard']='tenyearbenxi',['TenyearKuangfuCard']='tenyearkuangfu',['TenyearYanzhuCard']='tenyearyanzhu',['TenyearXingxueCard']='tenyearxingxue',['TenyearShenduanCard']='tenyearshenduan',['TenyearQiaoshuiCard']='tenyearqiaoshui',['TenyearQiaoshuiTargetCard']='tenyearqiaoshuitarget',['TenyearAocaiCard']='tenyearaocai',['TenyearDuwuCard']='tenyearduwu',['TenyearXianzhenCard']='tenyearxianzhen',['SecondTenyearXianzhenCard']='secondtenyearxianzhen',['TenyearZishouCard']='tenyearzishou',['TenyearyongjinCard']='tenyearyongjin',['TenyearXuanhuoCard']='tenyearxuanhuo',['TenyearSidiCard']='tenyearsidi',['TenyearHuaiyiCard']='tenyearhuaiyi',['TenyearHuaiyiSnatchCard']='tenyearhuaiyisnatch',['TenyearGongqiCard']='tenyeargongqi',['TenyearJiefanCard']='tenyearjiefan',['TenyearXianzhouCard']='tenyearxianzhou',['TenyearXianzhouDamageCard']='tenyearxianzhoudamage',['TenyearShenxingCard']='tenyearshenxing',['TenyearBingyiCard']='tenyearbingyi',['TenyearZongxuanCard']='tenyearzongxuan',['TenyearYjYanyuCard']='tenyearyjyanyu',['TenyearJiaozhaoCard']='tenyearjiaozhao',['TenyearGanluCard']='tenyearganlu',['TenyearJianyanCard']='tenyearjianyan',['TenyearAnxuCard']='tenyearanxu',['TenyearQinwangCard']='tenyearqinwang',['TenyearXiansiCard']='tenyearxiansi',['TenyearXiansiSlashCard']='tenyearxiansi_slash',['TenyearMingceCard']='tenyearmingce',['TenyearFenchengCard']='tenyearfencheng',['TenyearMiejiCard']='tenyearmieji'}
classes.TenyearChunlaoCard="tenyearchunlao";classes.SecondTenyearChunlaoCard="secondtenyearchunlao"
classes.TenyearChunlaoWineCard="tenyearchunlao";classes.SecondTenyearChunlaoWineCard="secondtenyearchunlao"
classes.TenyearQiaoshuiTargetCard="tenyearqiaoshui";classes.TenyearHuaiyiSnatchCard="tenyearhuaiyi";classes.TenyearXianzhouDamageCard="tenyearxianzhou"

local function decode(text)
 local cl,raw=text:match("^@([%w_]+)=(.*)$");if not cl or not classes[cl]then ai_unsupported("unexpected authored skill card wire","tenyear standard")end
 local cost,user=raw:match("^(.-):(.*)$");cost=cost or raw;local ids={};if cost~="."then for id in cost:gmatch("[^+]+")do ids[#ids+1]=assert(tonumber(id))end end;return cl,classes[cl],ids,user
end
local function printed_spec(self,text)
 local name,skill,suit,number,raw=text:match("^([%w_]+):([%w_]+)%[([^:]+):([^%]]+)%]=(.*)$")
 if not name then return nil end
 local suites={spade=sgs.Card_Spade,club=sgs.Card_Club,heart=sgs.Card_Heart,diamond=sgs.Card_Diamond,no_suit=sgs.Card_NoSuit}
 local numbers={A=1,J=11,Q=12,K=13};local ids={};if raw~="."then for id in raw:gmatch("[^+]+")do ids[#ids+1]=assert(tonumber(id))end end
 return{name=name,skill=skill,suit=known(suites[suit],"source suit"),number=known(tonumber(number)or numbers[number],"source number"),subcards=ids}
end
local function parse_policy(self,text,request)
 local spec=printed_spec(self,text);if spec then local c=known(self:getEvaluationCard(spec.name),"source prototype");return self:evaluateTurnConversion(spec.skill,c:getClassName(),spec,request)end
 local cl,skill,ids,user=decode(text);return self:evaluateTurnSkillCard(skill,cl,ids,request,user)
end
local function selected_policy(self,text)local cl,skill,ids,user=decode(text);return self:bindSkillCard(skill,ids,nil,user,cl)end
local function select_card(self,card,cl)if type(card.isStrategySeed)=="function"and card:isStrategySeed()then return self:bindSkillCard(classes[cl],{},nil,nil,cl)end;return card end
local function response_wire(self,wire)
 if type(wire)~="string"or wire=="."or wire==""then return wire end
 local text,targets=wire:match("^(.-)%->(.*)$");text=text or wire
 local paid;local spec=printed_spec(self,text)
 if spec then
  local base=known(self:getEvaluationCard(spec.name),"response prototype");local policy=known(self:getConversionPolicy(base:getClassName()),"response class policy");local row
  for _,r in ipairs(policy.skills or{})do if r.skill==spec.skill then row=r;break end end
  paid=known(self:resolveResponseConversion(spec,known(row,"selected response skill")),"selected response authority")
 elseif text:match("^%d+$")then paid=known_card(self,tonumber(text))
 else paid=selected_policy(self,text)end
 return{kind="use_card",card_spec=paid:toCardSpec(),targets=targets and targets:split("+")or{}}
end
local function printed_card(self,id)return known(self:getPrintedCardById(id),"offered printed face")end
local function value_variant()local v;return{setValue=function(_,x)v=x end,toCardUse=function()return v end,toString=function()return""end}end
local function set_used_data(self)ai_unsupported("source global UsedData/yb_zhuzhan2 temporary input has no exported pure adapter","tenyearxianzhen")end
local function aggregate_mieji(self,ids)
 ai_unsupported("source Dummy Slash aggregate response lacks issued cost scope","@mieji-discard")
end
local function hypothetical_distance(self,n)ai_unsupported("source temporary native distance planning unavailable","tenyearqimou")end
local function can_to(self,c,from,to,targets)
 if from:objectName()~=self.player:objectName()then ai_unsupported("foreign source targetFilter requires lawful public rule query","tenyearmingce")end
 return self:cardTargetFilter(c,targets or{},to)
end
local function current_damage(self)
 -- Room tag CurrentDamageStruct: a question's decision context carries it while the tag
 -- holds one (absent reads as the donor's empty struct); event callbacks get no context.
 if self.request.kind=="event"then ai_unsupported("CurrentDamageStruct is not projected to event callbacks","current_damage")end
 local d=self:getDecisionContext().damage
 if d==nil then return{}end
 return{from=d.from,to=d.to,damage=d.amount,card=d.card,nature=d.nature}
end
local function extra_card(self,wire)
 -- Reached after the source sort. Native parses this exact first raw token;
 -- normalization/repair of '+' materials or trailing skill would change source.
 return self:evaluateSkillCard("tenyearbenxi:extra_collateral",wire,{})
end
local function raw_shensu1(self,prompt)
	self.enemies=self:sort(self.enemies,"defense")
	if self.player:containsTrick("lightning") and self.player:getCards("j"):length()==1
	and self:hasWizard(self.friends) and not self:hasWizard(self.enemies,true)
	then return "." end

	if self:needBear() then return "." end

	local slash=clone(self,"tenyearshensu","shensu","slash",sgs.Card_NoSuit,0,{})
	local dummy = self:aiUseCard(slash)
	if dummy.card then
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return "@ShensuCard=.->"..table.concat(tos,"+")
	end
	return "."
end

local function equip_type(card)
	return known(card:getEquipSlot(),"equipment location")+1
end

local function raw_shensu2(self,prompt,method)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	local eCard
	local hasCard = {}
	if self:needToThrowArmor() then
		eCard = self.player:getArmor()
	end
	for i,card in ipairs(cards)do
		if card:isKindOf("EquipCard") then
			i = equip_type(card)
			hasCard[i] = (hasCard[i] or 0)+1
		end
	end
	for _,card in ipairs(cards)do
		if eCard then break end
		if card:isKindOf("EquipCard") and hasCard[equip_type(card)]>1
		then eCard = card end
	end
	for _,card in ipairs(cards)do
		if eCard then break end
		if card:isKindOf("EquipCard") and equip_type(card)>3
		then eCard = card end
	end
	for _,card in ipairs(cards)do
		if eCard then break end
		if card:isKindOf("EquipCard") and not card:isKindOf("Armor")
		then eCard = card end
	end
	if not eCard then return "." end
	local slash=clone(self,"tenyearshensu","shensu","slash",sgs.Card_NoSuit,0,{})
	local dummy = self:aiUseCard(slash)
	if dummy.card then
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return "@ShensuCard="..eCard:getEffectiveId().."->"..table.concat(tos,"+")
	end
	return "."
end

local function raw_chunlao(self,prompt)
	if prompt~="@chunlao" and prompt~="@tenyearchunlao" and prompt~="@secondtenyearchunlao" then return "." end
	local slashcards={}
	local chunlao = self.player:getPile("wine")
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	for _,card in ipairs(cards)  do
		if card:isKindOf("Slash") then
			table.insert(slashcards,card:getId())
		end
	end
	if #slashcards>0 and chunlao:isEmpty() then
		return "@ChunlaoCard="..table.concat(slashcards,"+")
	end
	return "."
end

local function raw_duanliang(self)
	local cards = self:addHandPile("he")
	local card
	cards=self:sortByUseValue(cards,true)
	for _,acard in ipairs(cards)  do
		if (acard:isBlack()) and (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard")) and (self:getDynamicUsePriority(acard)<sgs.ai_use_value.SupplyShortage)then
			card = acard
			break
		end
	end
	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	return parse_policy(self,("supply_shortage:duanliang[%s:%s]=%d"):format(suit,number,card_id))
end

local function known_hand_partition(self,p)
 local cs=known(self:getKnownCards(p,self.player),"known hand");local unseen=p:getHandcardNum()-#known(p:getKnownCards(),"disclosed physical hand")
 if unseen<0 then ai_unsupported("inconsistent known hand count","tenyearwurong")end
 local unknown={};for i=1,unseen do unknown[i]=true end -- count only; never a fake CardView or ID.
 return cs,unknown
end
local function source_random_card(self,who,flags)
 local disabled=self.disabled_ids or self:getStrategyMemory("discard_disabled_ids")or{}
 local cards;if who:objectName()==self.player:objectName()then cards=known(who:getCards(flags),"owner card zone");cards=self:sortByKeepValue(cards)
 else
  cards={};if flags:find("h",1,true)then local hand=known(who:getKnownCards(),"known hand");if#hand~=who:getHandcardNum()then ai_unsupported("hidden random card domain requires inquiry opaque token","tenyearbuyi")end;for _,c in ipairs(hand)do cards[#cards+1]=c end end
  if flags:find("e",1,true)then for _,c in sgs.list(who:getEquips())do cards[#cards+1]=c end end
  if flags:find("j",1,true)then for _,c in sgs.list(who:getJudgingArea())do cards[#cards+1]=c end end
 end
 local ids={};for _,c in sgs.list(cards)do local id=c:getEffectiveId();if not table.contains(disabled,id)then ids[#ids+1]=id end end
 if#ids==0 then return -1 end;if who:objectName()==self.player:objectName()then return ids[1]end
 local n=math.random(1,#ids);local id=ids[n];local c=known_card(self,id)
 if c:isKindOf("SilverLion")and who:isWounded()and self:isEnemy(who)and who:hasArmorEffect("SilverLion")then if n~=#ids then id=ids[n+1]elseif n>1 then id=ids[n-1]end end
 return id
end
local function save_override(self,kind,key,v)
 if AIValue.isPlayer(v)then v=v:objectName()end
 self:setStrategyMemory("tenyear_override:"..kind..":"..key,v)
 self:useKnowledgeEstimate({value=v,status="estimate",basis="viewer_local_dynamic_registry_without_cross_viewer_writes"},key)
end
--制衡

ai_fill_skill["tenyearzhiheng"] = function(self, options, request)
    local inclusive = options and options.inclusive

	return parse_policy(self,"@TenyearZhihengCard=.")
end

ai_card_use.TenyearZhihengCard=function(self, card, use, request)
 local ids=self:selectZhihengCosts();if #ids>0 then use.card=self:bindSkillCard("tenyearzhiheng",ids,nil,nil,"TenyearZhihengCard")end
end

sgs.ai_use_value.TenyearZhihengCard = sgs.ai_use_value.ZhihengCard
sgs.ai_use_priority.TenyearZhihengCard = sgs.ai_use_priority.ZhihengCard
sgs.dynamic_value.benefit.TenyearZhihengCard = sgs.dynamic_value.benefit.ZhihengCard

function sgs.ai_cardneed.tenyearzhiheng(to,card)
	return not card:isKindOf("Jink")
end

--救援
sgs.ai_skill_playerchosen.tenyearjiuyuan = function(self,targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets,"hp")
	for _,p in ipairs(targets)do
		if not self:isFriend(p) then continue end
		if self:isWeak(p) and p:isLord() then
			return p
		end
	end
	if self:isWeak() then return nil end
	for _,p in ipairs(targets)do
		if not self:isFriend(p) then continue end
		if self:isWeak(p) then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if not self:isFriend(p) then continue end
		return p
	end
	return nil
end

--结姻
local function getTenyearJieyinId(self,male,equips,cards)
	if #equips<=0 and #cards<=0 then return -1 end
	if self.player:hasSkills(sgs.lose_equip_skill) then
		equips = self:sortByKeepValue(equips)
		for _,c in ipairs(equips)do
			local index = known(c:getEquipSlot(),"equipment location")
			if male:getEquip(index) or not male:hasEquipArea(index) or (c:isKindOf("Armor") and not male:getArmor() and male:hasSkills("bazhen|linglong|bossmanjia|yizhong")) then
				continue
			end
			return c:getKnownEffectiveId()
		end
	end
	if self.player:getArmor() and self:needToThrowArmor() then
		local armor_id = self.player:getArmor():getEffectiveId()
		local armor = known_card(self,armor_id)
		if not male:getEquip(1) and male:hasEquipArea(1) and not male:hasSkills("bazhen|linglong|bossmanjia|yizhong") then
			return armor_id
		end
	end
	cards = self:sortByKeepValue(cards)
	for _,c in ipairs(cards)do
		if self.player:canDiscard(self.player,c:getKnownEffectiveId()) then
			return c:getKnownEffectiveId()
		end
	end
	return -1
end


ai_fill_skill["tenyearjieyin"] = function(self, options, request)
    local inclusive = options and options.inclusive

	return parse_policy(self,"@TenyearJieyinCard=.")
end

ai_card_use.TenyearJieyinCard = function(self, card, use, request)
	local cards,equips = {},{}
	for _,c in sgs.qlist(self.player:getCards("h"))do
		if self.player:canDiscard(self.player,c:getKnownEffectiveId()) then
			table.insert(cards,c)
		end
		if c:isKindOf("EquipCard") then
			table.insert(equips,c)
		end
	end
	for _,c in sgs.qlist(self.player:getCards("e"))do
		table.insert(equips,c)
	end
	if #cards<=0 and #equips<=0 then return end

	local weak_friends,recover_friends,draw_friends,not_friends,enemies = {},{},{},{},{}

	if self:isWeak() and self.player:getLostHp()>0 then
		self.friends_noself = self:sort(self.friends_noself)
		for _,p in ipairs(self.friends_noself)do
			if p:getHp()>self.player:getHp() and self:canDraw(p) and p:isMale() then
				table.insert(draw_friends,p)
			end
		end
		for _,p in ipairs(draw_friends)do
			local id = getTenyearJieyinId(self,p,equips,cards)
			if id>0 then
				use.card = parse_policy(self,"@TenyearJieyinCard="..id)
				use.to:append(p)
				return
			end
		end

		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if p:getHp()>self.player:getHp() and not self:isEnemy(p) and p:isMale() then
				table.insert(not_friends,p)
			end
		end
		for _,p in ipairs(not_friends)do
			local id = getTenyearJieyinId(self,p,equips,cards)
			if id>0 then
				use.card = parse_policy(self,"@TenyearJieyinCard="..id)
				use.to:append(p)
				return
			end
		end

		self.enemies = self:sort(self.enemies)
		for _,p in ipairs(self.enemies)do
			if p:getHp()>self.player:getHp() and not self:canDraw(p) and p:isMale() then
				table.insert(enemies,p)
			end
		end
		for _,p in ipairs(enemies)do
			local id = getTenyearJieyinId(self,p,equips,cards)
			if id>0 then
				use.card = parse_policy(self,"@TenyearJieyinCard="..id)
				use.to:append(p)
				return
			end
		end

		self.enemies = sgs.reverse(self.enemies)
		for _,p in ipairs(self.enemies)do
			if p:getHp()>self.player:getHp() and p:isMale() then
				table.insert(enemies,p)
			end
		end
		for _,p in ipairs(enemies)do
			local id = getTenyearJieyinId(self,p,equips,cards)
			if id>0 then
				use.card = parse_policy(self,"@TenyearJieyinCard="..id)
				use.to:append(p)
				return
			end
		end
	end

	for _,p in ipairs(self.friends_noself)do
		if self:isWeak(p) and p:getHp()<self.player:getHp() and p:getLostHp()>0 and p:isMale() then
			table.insert(weak_friends,p)
		end
	end
	if #weak_friends>0 then
		weak_friends = self:sort(weak_friends,"hp")
		for _,p in ipairs(weak_friends)do
			local id = getTenyearJieyinId(self,p,equips,cards)
			if id<0 then continue end
			use.card = parse_policy(self,"@TenyearJieyinCard="..id)
			use.to:append(p)
			return
		end
	end

	for _,p in ipairs(self.friends_noself)do
		if p:getHp()<self.player:getHp() and p:getLostHp()>0 and p:isMale() then
			table.insert(recover_friends,p)
		end
	end
	if #recover_friends>0 then
		recover_friends = self:sort(recover_friends)
		for _,p in ipairs(recover_friends)do
			local id = getTenyearJieyinId(self,p,equips,cards)
			if id<0 then continue end
			use.card = parse_policy(self,"@TenyearJieyinCard="..id)
			use.to:append(p)
			return
		end
	end

	self.friends_noself = self:sort(self.friends_noself)
	for _,p in ipairs(self.friends_noself)do
		if p:getHp()>self.player:getHp() and self:canDraw(p) and p:isMale() then
			table.insert(draw_friends,p)
		end
	end
	for _,p in ipairs(draw_friends)do
		local id = getTenyearJieyinId(self,p,equips,cards)
		if id>0 then
			use.card = parse_policy(self,"@TenyearJieyinCard="..id)
			use.to:append(p)
			return
		end
	end

	if self.player:getLostHp()>0 then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if p:getHp()>self.player:getHp() and not self:isEnemy(p) and p:isMale() then
				table.insert(not_friends,p)
			end
		end
		for _,p in ipairs(not_friends)do
			local id = getTenyearJieyinId(self,p,equips,cards)
			if id>0 then
				use.card = parse_policy(self,"@TenyearJieyinCard="..id)
				use.to:append(p)
				return
			end
		end

		self.enemies = self:sort(self.enemies)
		for _,p in ipairs(self.enemies)do
			if p:getHp()>self.player:getHp() and not self:canDraw(p) and p:isMale() then
				table.insert(enemies,p)
			end
		end
		for _,p in ipairs(enemies)do
			local id = getTenyearJieyinId(self,p,equips,cards)
			if id>0 then
				use.card = parse_policy(self,"@TenyearJieyinCard="..id)
				use.to:append(p)
				return
			end
		end
	end
end

sgs.ai_use_priority.TenyearJieyinCard = 0

--仁德
local function tenyearRendeV2Card(self,ids,request)
 return self:evaluateTurnSkillCard("tenyearrende","ActiveSkillCard",ids or{},request)
end
ai_fill_skill.tenyearrende = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:isKongcheng() then return end
	return tenyearRendeV2Card(self,{},request)
end

ai_card_use.tenyearrende = function(self, card, use, request)
    local others = self.room:getOtherPlayers(self.player)
    local friends,enemies,unknowns = {},{},{}
    local arrange = {}
    arrange["count"] = 0
    for _,p in sgs.qlist(others)do
        if p:getStrategyMark("tenyearrendetarget-PlayClear")<1
		then
            arrange[p:objectName()] = {}
            if self:isFriend(p) then table.insert(friends,p)
            elseif self:isEnemy(p) then table.insert(enemies,p)
            else table.insert(unknowns,p) end
        end
    end
    local new_friends = {}
    for _,friend in ipairs(friends)do
        local exclude = false
        if self:needKongcheng(friend,true) or self:willSkipPlayPhase(friend)
		then
            exclude = true
            if self:hasSkills("keji|qiaobian|shensu",friend) then exclude = false
            elseif friend:getHp()-friend:getHandcardNum()>=3 then exclude = false
            elseif friend:isLord() and self:isWeak(friend) and self:getEnemyNumBySeat(self.player,friend)>=1
			then exclude = false end
        end
        if not exclude and not hasManjuanEffect(friend) and self:objectiveLevel(friend)<=-2
		then table.insert(new_friends,friend) end
    end
    friends = new_friends
    if self:getOverflow()<1 and #friends<1 then return end
    local handcards = self.player:getHandcards()
    handcards = sgs.QList2Table(handcards)
    handcards = self:sortByUseValue(handcards)
    while true do
        if #handcards<1 then break end
        local target,to_give,group = OlRendeArrange(self,handcards,friends,enemies,unknowns,arrange,false)
        if target and to_give and group then
            table.insert(arrange[target:objectName()],to_give)
            arrange["count"] = arrange["count"]+1
            handcards = self:resetCards(handcards,to_give)
        else break end
    end
    local max_count,max_name = 0,nil
    for name,cards in pairs(arrange)do
        if type(cards)=="table" then
            local count = #cards
            if count>max_count then
                max_count = count
                max_name = name
            end
        end
    end
    if max_count<1 or not max_name
	then return end
    local max_target = nil
    for _,p in sgs.qlist(others)do
        if p:objectName()==max_name
		then max_target = p break end
    end
    if max_target and type(arrange[max_name])=="table" and #arrange[max_name]>0
	then
        local to_use = {}
        for _,c in ipairs(arrange[max_name])do
            table.insert(to_use,c:getKnownEffectiveId())
        end
        use.card = self:bindSkillCard("tenyearrende",to_use,nil,nil,"ActiveSkillCard")
        use.to:append(max_target)
    end
end

sgs.ai_use_value.TenyearRendeCard = sgs.ai_use_value.RendeCard
sgs.ai_use_priority.TenyearRendeCard = sgs.ai_use_priority.RendeCard
sgs.ai_card_intention.TenyearRendeCard = sgs.ai_card_intention.RendeCard
sgs.dynamic_value.benefit.TenyearRendeCard = true
sgs.ai_use_value.tenyearrende = sgs.ai_use_value.TenyearRendeCard
sgs.ai_use_priority.tenyearrende = sgs.ai_use_priority.TenyearRendeCard
sgs.ai_card_intention.tenyearrende = sgs.ai_card_intention.TenyearRendeCard
sgs.dynamic_value.benefit.tenyearrende = true

sgs.ai_skill_askforag.tenyearrende = function(self,card_ids)
	local cards = {}
	for _,id in ipairs(card_ids)do
		local card = printed_card(self,id)
		if card:isKindOf("Analeptic") and self:getCardsNum("Slash")<1 then continue end  --这里应该判断会不会使用【杀】，偷懒一下
		if card:targetFixed() then table.insert(cards,card)
		else
			local d = clone(self,"tenyearrende","_tenyearrende",card:objectName(),sgs.Card_NoSuit,0,{})
			if self:aiUseCard(d).card then
				table.insert(cards,card)
			end
		end
	end
	if #cards>0 then
		cards = self:sortByUseValue(cards,false)
		return cards[1]:getKnownEffectiveId()
	end
	for _,id in ipairs(card_ids)do
		if printed_card(self,id):isKindOf("Analeptic") then return id end
	end
	return card_ids[1]
end

ai_skill_invoke.tenyearrende = true

ai_skill_use["@@tenyearrende"] = function(self, prompt, request)
	local method = request and request.handling_method
	local name = prompt:split(":")[2]
	if not name then return "." end
	local card = clone(self,"tenyearrende","_tenyearrende",name,sgs.Card_NoSuit,0,{})
	local d = self:aiUseCard(card)
	if d.card then
		local tos = {}
		for _,p in sgs.qlist(d.to)do
			table.insert(tos,p:objectName())
		end
		return card:getLegacyStringKey().."->"..table.concat(tos,"+")
	end
end

--武圣
sgs.ai_view_as.tenyearwusheng = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and card:isRed() and not card:isKindOf("Peach") and not card:getStrategyFlag("using") then
		return{name="slash",skill="tenyearwusheng",suit=card:getSuit(),number=card:getNumber(),subcards={card_id}}
	end
end


ai_fill_skill["tenyearwusheng"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self:addHandPile("he")
	local red_card
	cards = self:sortByUseValue(cards,true)

	local useAll = false
	self.enemies = self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()==1 and not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy)<=self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)==0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash")<2 or self.player:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao") then
		disCrossbow = true
	end

	local nuzhan_equip = false
	local nuzhan_equip_e = false
	self.enemies = self:sort(self.enemies,"defense")
	if self.player:hasSkill("nuzhan") then
		for _,enemy in ipairs(self.enemies)do
			if  not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy)<=self.player:getAttackRange()
			and getCardsNum("Jink",enemy)<1 then
				nuzhan_equip_e = true
				break
			end
		end
		for _,card in ipairs(cards)do
			if card:isRed() and card:isKindOf("TrickCard") and nuzhan_equip_e then
				nuzhan_equip = true
				break
			end
		end
	end

	local nuzhan_trick = false
	local nuzhan_trick_e = false
	self.enemies = self:sort(self.enemies,"defense")
	if self.player:hasSkill("nuzhan") and not self.player:getStrategyFlag("hasUsedSlash") and self:getCardsNum("Slash")>1 then
		for _,enemy in ipairs(self.enemies)do
			if  not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy)<=self.player:getAttackRange() then
				nuzhan_trick_e = true
				break
			end
		end
		for _,card in ipairs(cards)do
			if card:isRed() and card:isKindOf("TrickCard") and nuzhan_trick_e then
				nuzhan_trick = true
				break
			end
		end
	end

	for _,card in ipairs(cards)do
		if card:isRed() and not card:isKindOf("Slash") and not (nuzhan_equip or nuzhan_trick)
			and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
			and (not isCard("Crossbow",card,self.player) or disCrossbow)
			and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or known(self:getEvaluationCard("slash"):getTargetModResidue(self.player),"Slash residue")>0) then
			red_card = card
			break
		end
	end

	if nuzhan_equip then
		for _,card in ipairs(cards)do
			if card:isRed() and card:isKindOf("EquipCard") then
				red_card = card
				break
			end
		end
	end

	if nuzhan_trick then
		for _,card in ipairs(cards)do
			if card:isRed() and card:isKindOf("TrickCard")then
				red_card = card
				break
			end
		end
	end

	if red_card then
		local suit = red_card:getSuitString()
		local number = red_card:getNumberString()
		local card_id = red_card:getKnownEffectiveId()
		return parse_policy(self,("slash:tenyearwusheng[%s:%s]=%d"):format(suit,number,card_id))
	end
end

sgs.ai_cardneed.tenyearwusheng = sgs.ai_cardneed.wusheng

--义绝
local function hasRedHandcard(self,target)
	if target:isKongcheng() then return false end
	local not_red,known_count = 0,0
	local flag = string.format("%s_%s_%s","visible",self.player:objectName(),target:objectName())
	for _,c in sgs.qlist(known(target:getKnownCards(),"known hand"))do
		if target:isHandVisible()or c:getStrategyFlag("visible") or c:getStrategyFlag(flag) then
			known_count = known_count+1
			if c:isRed() then
				return true
			else
				not_red = not_red+1
			end
		end
	end
	if known_count-not_red>=2 then return true end
	if target:getHandcardNum()>=3 then return true end
	return false
end


ai_fill_skill["tenyearyijue"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:canDiscard(self.player,"he") then
		return parse_policy(self,"@TenyearYijueCard=.")
	end
end

ai_card_use.TenyearYijueCard = function(self, card, use, request)
	local id = -1
	if self:needToThrowArmor() and self.player:canDiscard(self.player,self.player:getArmor():getEffectiveId()) then
		id = self.player:getArmor():getEffectiveId()
	else
		local cards = sgs.QList2Table(self.player:getCards("he"))
		cards = self:sortByKeepValue(cards)
		id = cards[1]:getKnownEffectiveId()
	end
	if id<0 then return end

	self.friends_noself = self:sort(self.friends_noself,"hp")
	for _,p in ipairs(self.friends_noself)do
		if self:isWeak(p) and p:getLostHp()>0 and hasRedHandcard(self,p) then
			use.card = parse_policy(self,"@TenyearYijueCard="..id)
			use.to:append(p)
			return
		end
	end

	self.enemies = self:sort(self.enemies,"handcard")
	for _,p in ipairs(self.enemies)do
		if self.player:canSlash(p,nil) and not p:isKongcheng() then
			use.card = parse_policy(self,"@TenyearYijueCard="..id)
			use.to:append(p)
			return
		end
	end

	if self.player:hasArmorEffect("SilverLion") and known_card(self,id):objectName()=="silver_lion" and self.room:getCardPlace(id)==sgs.Player_PlaceEquip
	and (self:needToThrowArmor() or (self:isWeak() and self.player:getLostHp()>0)) then
		for _,p in ipairs(self.friends_noself)do
			if p:getLostHp()>0 and hasRedHandcard(self,p) then
				use.card = parse_policy(self,"@TenyearYijueCard="..id)
				use.to:append(p)
				return
			end
		end

		for _,p in ipairs(self.enemies)do
			if not p:isKongcheng() then
				use.card = parse_policy(self,"@TenyearYijueCard="..id)
				use.to:append(p)
				return
			end
		end
	end
end

sgs.ai_use_priority.TenyearYijueCard = sgs.ai_use_priority.Slash+0.1
sgs.ai_use_value.TenyearYijueCard = 8.5

sgs.ai_cardshow.tenyearyijue = function(self,requestor)
	local cards,red = sgs.QList2Table(self.player:getCards("h")),{}
	cards = self:sortByUseValue(cards,true)
	for _,c in ipairs(cards)do
		if c:isRed() then
			table.insert(red,c)
		end
	end
	if self:isFriend(requestor) and #red>0 and (self.player:getLostHp()>0 or self:getOverflow()>0) then
		return red[1]
	end
	return cards[1]
end

ai_skill_invoke.tenyearyijue = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local name = data:toString():split(":")
	if #name<=1 or name[2]=="" or name[2]==nil then return (false) or false end
	local player = self.room:findPlayerByObjectName(name[2])
	if not player or player:isDead() then return (false) or false end
	return (self:isFriend(player)) or false
end

--替身
ai_skill_invoke.tenyeartishen = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local hascard = false
	for _,c in sgs.qlist(self.player:getCards("he"))do
		if c:isKindOf("TrickCard") or c:isKindOf("OffensiveHorse") or c:isKindOf("DefensiveHorse") then  --没有相应区域不能使用坐骑牌暂时未考虑
			hascard = true
			break
		end
	end
	if not hascard then return (true) or false end
	if self:getCardsNum("Jink")==0 then return (false) or false end
	return (true) or false  --偷懒
end

--观星
ai_skill_invoke.tenyearguanxing = true

--涯角
ai_skill_invoke.tenyearyajiao = true

sgs.ai_skill_playerchosen.tenyearyajiao = function(self,targets)
	local id = self.player:getStrategyMark("tenyearyajiao")
	local card = known_card(self,id)
	local cards = { card }
	local c,friend = self:getCardNeedPlayer(cards,self.friends)
	if friend then return friend end

	self.friends = self:sort(self.friends)
	for _,friend in ipairs(self.friends)do
		if self:isValuableCard(card,friend) and not hasManjuanEffect(friend) and not self:needKongcheng(friend,true) then return friend end
	end
	for _,friend in ipairs(self.friends)do
		if self:isWeak(friend) and not hasManjuanEffect(friend) and not self:needKongcheng(friend,true) then return friend end
	end
	local trash = card:isKindOf("Disaster") or card:isKindOf("GodSalvation") or card:isKindOf("AmazingGrace")
	if trash then
		for _,enemy in ipairs(self.enemies)do
			if enemy:getPhase()>sgs.Player_Play and self:needKongcheng(enemy,true) and not hasManjuanEffect(enemy) then return enemy end
		end
	end
	for _,friend in ipairs(self.friends)do
		if not hasManjuanEffect(friend) and not self:needKongcheng(friend,true) then return friend end
	end
end

sgs.ai_playerchosen_intention.tenyearyajiao = function(self,from,to)
	if not self:needKongcheng(to,true) and not hasManjuanEffect(to) then self:updateIntention(from,to,-50) end
end

sgs.ai_skill_discard.tenyearyajiao = function(self,discard_num,min_num,optional,include_equip)
	return self:askForDiscard("dummy",1,1,false,true)
end

--集智
ai_skill_invoke.tenyearjizhi = function(self, options, request)
	local choices = request and self:getDecisionData(request) or nil
	local data = nil
	return (self:canDraw()) or false
end

ai_skill_invoke.tenyearjizhi_discard = function(self, options, request)
	local choices = request and self:getDecisionData(request) or nil
	local data = nil
	if self.player:getHandcardNum()<=self.player:getMaxCards() then return (false) or false end
	local id = tag(self,"tenyearjizhi_id","Int")
	local card = known_card(self,id)
	if card:isKindOf("Jink") and self:getCardsNum("Jink")<=1 then return (false) or false end
	if card:isKindOf("Peach") then return (false) or false end
	if not self.player:canUse(card) then return (true) or false end
	if card:isKindOf("Analeptic") and self:willUse(self.player,card) then return (false) or false end
	local dummy_use = dummy_plan()
	self:useCardByClassName(card,dummy_use)
	if not dummy_use.card or dummy_use.to:isEmpty() then return (true) or false end
	if card:isKindOf("Slash") and self:getCardsNum("Slash")>1 and (self.player:canSlashWithoutCrossbow() or self.player:hasWeapon("Crossbow")) then return (false) or false end
	return (false) or false
end

--奸雄
ai_skill_invoke.tenyearjianxiong = function(self, options, request)
	local choices = request and self:getDecisionData(request) or nil
	local data = nil
	return (self:canDraw()) or false
end

--清俭
ai_skill_use["@@tenyearqingjian"] = function(self, prompt, request)
	local method = request and request.handling_method
	if not self.room:hasCurrent() then return "." end
	local current = self.room:getCurrent()
	if current:isDead() or not self:isFriend(current) then return "." end

	self.friends_noself = self:sort(self.friends_noself)
	local to
	for _,p in ipairs(self.friends_noself)do
		if hasManjuanEffect(p) or self:needKongcheng(p,true) then continue end
		to = p:objectName()
		break
	end
	if not to then return "." end

	local give = {}
	if self:needToThrowArmor() then table.insert(give,self.player:getArmor():getEffectiveId()) end
	if self:needToThrowLastHandcard(self.player,self.player:getHandcardNum()) and self.player:getPhase()==sgs.Player_NotActive then
		for _,id in sgs.qlist(self.player:handCards())do
			table.insert(give,id)
		end
		if #give>0 then
			return "@TenyearQingjianCard="..table.concat(give,"+").."->"..to
		end
	end

	local basic,equip,trick,allcards = {} ,{},{},sgs.QList2Table(self.player:getCards("he"))
	allcards = self:sortByKeepValue(allcards)
	for _,c in ipairs(allcards)do
		if c:isKindOf("BasicCard") then
			table.insert(basic,c:getKnownEffectiveId())
		elseif c:isKindOf("EquipCard") then
			table.insert(equip,c:getKnownEffectiveId())
		elseif c:isKindOf("TrickCard") then
			table.insert(trick,c:getKnownEffectiveId())
		end
	end
	if #equip>0 and #give<=0 then
		table.insert(give,equip[1])
	end
	if #basic>0 then
		table.insert(give,basic[1])
	end
	if #trick>0 then
		table.insert(give,trick[1])
	end
	if #give>0 then
		return "@TenyearQingjianCard="..table.concat(give,"+").."->"..to
	end
	return "."
end

--裸衣
ai_skill_invoke.tenyearluoyi = function(self, options, request)
	if self.player:getPile("yiji"):length()>1 then return (false) or false end
	local diaochans,nosdiaochans = self.room:findPlayersBySkillName("lijian"),self.room:findPlayersBySkillName("noslijian")
	for _,diaochan in sgs.qlist(diaochans)do
		if self:isEnemy(diaochan) then
			for _,friend in ipairs(self.friends_noself)do
				if self:isWeak(friend) or friend:getHp()<=2 then return (false) or false end
			end
		end
	end
	for _,diaochan in sgs.qlist(nosdiaochans)do
		if self:isEnemy(diaochan) then
			for _,friend in ipairs(self.friends_noself)do
				if self:isWeak(friend) or friend:getHp()<=2 then return (false) or false end
			end
		end
	end
	local ids = tag(self,"tenyearluoyi_ids","IntList")
	local num = 0
	local slash = false
	for _,id in sgs.qlist(ids)do
		local c = known_card(self,id)
		if c:isKindOf("Slash") then  --若其中只有一张【杀】且敌人虚弱，也可以发动技能，待补充
			slash = true
			num = num+1
		elseif c:isKindOf("Duel") or c:isKindOf("Weapon") or c:isKindOf("Peach") then num = num+1
		elseif c:isKindOf("Jink") and (self:getCardsNum("Jink")==0 or (self:getCardsNum("Jink")==1 and self:isWeak())) then num = num+1
		elseif c:isKindOf("Analeptic") and (slash or self:getCardsNum("Slash")>0) then num = num+1
		end
	end
	return (num>=2) or false
end

--遗计
ai_skill_invoke.tenyearyiji = function(self, options, request)
	return (ai_skill_invoke.nosyiji(self, {}, nil)) or false
end

sgs.ai_skill_askforyiji.tenyearyiji = function(self,card_ids,tos)
	return sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
end

sgs.ai_need_damaged.tenyearyiji = function (self,attacker,player)
	return sgs.ai_need_damaged.nosyiji(self,attacker,player)
end

sgs.ai_can_damagehp.tenyearyiji = function(self,from,card,to)
	return self:canLoseHp(from,card,to)
	and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
end

--洛神
ai_skill_invoke.tenyearluoshen = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:getStrategyFlag("AI_doNotInvoke_tenyearluoshen") then
		self:setStrategyPlayerFlag(self.player,"AI_doNotInvoke_tenyearluoshen",false)
		return (false) or false
	end
	if self.player:getStrategyFlag("AI_TenyearLuoshen_Conflict_With_Guanxing") and self.player:getStrategyMark("AI_tenyearluoshen_times")==0 then return (false) or false end
	if self:willSkipPlayPhase() then
		local erzhang = self.room:findPlayerBySkillName("guzheng")
		if erzhang and self:isEnemy(erzhang) and self:getOverflow()>1 then return (false) or false end
		if self.player:getPile("incantation"):length()>0 then
			local card = known_card(self,self.player:getPile("incantation"):first())
			if not self.player:getJudgingArea():isEmpty() and not self.player:containsTrick("YanxiaoCard") and not self:hasWizard(self.enemies,true) then
				local trick = self.player:getJudgingArea():last()
				if trick:isKindOf("Indulgence") then
					if card:getSuit()==sgs.Card_Heart or (self.player:hasSkill("hongyan") and card:getSuit()==sgs.Card_Spade) then return (false) or false end
				elseif trick:isKindOf("SupplyShortage") then
					if card:getSuit()==sgs.Card_Club then return (false) or false end
				end
			end
			local zhangbao = self.room:findPlayerBySkillName("yingbing")
			if zhangbao and self:isEnemy(zhangbao) and not zhangbao:hasSkill("manjuan")
				and (card:isRed() or (self.player:hasSkill("hongyan") and card:getSuit()==sgs.Card_Spade)) then return (false) or false end
		end
	end
	return (true) or false
end

--突袭
ai_skill_use["@@tenyeartuxi"] = function(self, prompt, request)
	self.enemies = self:sort(self.enemies,"handcard_defense")
	local tuxi_mark = self.player:getStrategyMark("tenyeartuxi")
	local targets = {}

	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	local luxun = self.room:findPlayerBySkillName("lianying") or self.room:findPlayerBySkillName("noslianying")
	local dengai = self.room:findPlayerBySkillName("tuntian")
	local jiangwei = self.room:findPlayerBySkillName("zhiji")
	local zhijiangwei = self.room:findPlayerBySkillName("beifa")

	local add_player = function (player,isfriend)
		if player:getHandcardNum()==0 or player:objectName()==self.player:objectName() then return #targets end
		if self:objectiveLevel(player)==0 and player:isLord() and known(self:getRoleCounts().rebel,"rebel count")>1 then return #targets end

		local f = false
		for _,c in ipairs(targets)do
			if c==player:objectName() then
				f = true
				break
			end
		end

		if not f then table.insert(targets,player:objectName()) end

		if isfriend and isfriend==1 then
			self:setStrategyPlayerFlag(self.player,"tenyeartuxi_isfriend_"..player:objectName(),true)
		end
		return #targets
	end

	local parseTenyearTuxiCard = function()
		if #targets==0 then return "." end
		local s = table.concat(targets,"+")
		return "@TenyearTuxiCard=.->"..s
	end

	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) and known(self.world.turn_count,"turn count")<=1 and not lord:isKongcheng() then
		if add_player(lord)==tuxi_mark then return parseTenyearTuxiCard() end
	end

	if jiangwei and self:isFriend(jiangwei) and jiangwei:getStrategyMark("zhiji")==0 and jiangwei:getHandcardNum()==1
			and self:getEnemyNumBySeat(self.player,jiangwei)<=(jiangwei:getHp()>=3 and 1 or 0) then
		if add_player(jiangwei,1)==tuxi_mark  then return parseTenyearTuxiCard() end
	end

	if dengai and self:isFriend(dengai) and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player,dengai)==0 )
			and dengai:hasSkill("zaoxian") and dengai:getStrategyMark("zaoxian")==0 and dengai:getPile("field"):length()==2 and add_player(dengai,1)==tuxi_mark then
		return parseTenyearTuxiCard()
	end

	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum()==1 and self:getEnemyNumBySeat(self.player,zhugeliang)>0 then
		if zhugeliang:getHp()<=2 then
			if add_player(zhugeliang,1)==tuxi_mark then return parseTenyearTuxiCard() end
		else
			local flag = string.format("%s_%s_%s","visible",self.player:objectName(),zhugeliang:objectName())
			local cards = sgs.QList2Table(zhugeliang:getHandcards())
			if #cards==1 and (cards[1]:getStrategyFlag("visible") or cards[1]:getStrategyFlag(flag)) then
				if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
					if add_player(zhugeliang,1)==tuxi_mark then return parseTenyearTuxiCard() end
				end
			end
		end
	end

	if luxun and self:isFriend(luxun) and luxun:getHandcardNum()==1 and self:getEnemyNumBySeat(self.player,luxun)>0 then
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),luxun:objectName())
		local cards = sgs.QList2Table(luxun:getHandcards())
		if #cards==1 and (cards[1]:getStrategyFlag("visible") or cards[1]:getStrategyFlag(flag)) then
			if cards[1]:isKindOf("TrickCard") or cards[1]:isKindOf("Slash") or cards[1]:isKindOf("EquipCard") then
				if add_player(luxun,1)==tuxi_mark  then return parseTenyearTuxiCard() end
			end
		end
	end

	if zhijiangwei and self:isFriend(zhijiangwei) and zhijiangwei:getHandcardNum()==1 and
		self:getEnemyNumBySeat(self.player,zhijiangwei)<=(zhijiangwei:getHp()>=3 and 1 or 0) then
		local isGood
		for _,enemy in ipairs(self.enemies)do
			local def = self:getDefenseSlash(enemy)
			local slash = self:getEvaluationCard("slash")
			local eff = self:slashIsEffective(slash,enemy,zhijiangwei) and self:isGoodTarget(enemy,self.enemies,slash)
			if zhijiangwei:canSlash(enemy,slash) and not self:slashProhibit(slash,enemy,zhijiangwei) and eff and def<4 then
				isGood = true
			end
		end
		if isGood and add_player(zhijiangwei,1)==tuxi_mark  then return parseTenyearTuxiCard() end
	end

	for i = 1,#self.enemies,1 do
		local p = self.enemies[i]
		local cards = sgs.QList2Table(p:getHandcards())
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),p:objectName())
		for _,card in ipairs(cards)do
			if (card:getStrategyFlag("visible") or card:getStrategyFlag(flag)) and (card:isKindOf("Peach") or card:isKindOf("Nullification") or card:isKindOf("Analeptic") ) then
				if add_player(p)==tuxi_mark  then return parseTenyearTuxiCard() end
			end
		end
	end

	for i = 1,#self.enemies,1 do
		local p = self.enemies[i]
		if p:hasSkills("jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then
			if add_player(p)==tuxi_mark  then return parseTenyearTuxiCard() end
		end
	end

	for i = 1,#self.enemies,1 do
		local p = self.enemies[i]
		local x = p:getHandcardNum()
		local good_target = true
		if x==1 and self:needKongcheng(p) then good_target = false end
		-- 屯田類收益統一由 helper 判斷，涵蓋技能變體與回合外條件。
		if x>=2 and self:hasTuntianEffect(p, true) then good_target = false end
		if good_target and add_player(p)==tuxi_mark then return parseTenyearTuxiCard() end
	end


	if luxun and add_player(luxun,(self:isFriend(luxun) and 1 or nil))==tuxi_mark then
		return parseTenyearTuxiCard()
	end

	if dengai and self:isFriend(dengai) and dengai:hasSkill("zaoxian") and (not self:isWeak(dengai) or self:getEnemyNumBySeat(self.player,dengai)==0 ) and add_player(dengai,1)==tuxi_mark then
		return parseTenyearTuxiCard()
	end

	local others = self.room:getOtherPlayers(self.player)
	for _,other in sgs.qlist(others)do
		if self:objectiveLevel(other)>=0 and not (self:hasTuntianEffect(other, true)) and add_player(other)==tuxi_mark then
			return parseTenyearTuxiCard()
		end
	end

	for _,other in sgs.qlist(others)do
		if self:objectiveLevel(other)>=0 and not (self:hasTuntianEffect(other, true)) and math.random(0,5)<=1 and not self:hasSkills("qiaobian") then
			add_player(other)
		end
	end

	return parseTenyearTuxiCard()
end

sgs.ai_card_intention.TenyearTuxiCard = function(self,card,from,tos)
	local lord = getLord(self.player)
	local tuxi_lord = false
	if known(self:getRoleEstimate(from),"role estimate")=="neutral" and known(self:getRoleEstimate(tos[1]),"role estimate")=="neutral" and
		(not tos[2] or known(self:getRoleEstimate(tos[2]),"role estimate")=="neutral") and lord and not lord:isKongcheng() and
		not (self:needKongcheng(lord) and lord:getHandcardNum()==1 ) and
		self:hasLoseHandcardEffective(lord) and not (self:hasTuntianEffect(lord, true)) and from:aliveCount()>=4 then
			self:updateIntention(from,lord,-80)
		return
	end
	if from:getState()=="online" then
		for _,to in ipairs(tos)do
			if to:hasSkill("kongcheng") or to:hasSkill("lianying") or to:hasSkill("zhiji")
				or (self:hasTuntianEffect(to, true)) then
			else
				self:updateIntention(from,to,80)
			end
		end
	else
		for _,to in ipairs(tos)do
			if lord and to:objectName()==lord:objectName() then tuxi_lord = true end
			local intention = from:getStrategyFlag("tenyeartuxi_isfriend_"..to:objectName()) and -5 or 80
			self:updateIntention(from,to,intention)
		end
		if known(self.world.turn_count,"turn count")<=1 and not tuxi_lord and lord and not lord:isKongcheng() and from:getRoom():alivePlayerCount()>2 then
			self:updateIntention(from,lord,-80)
		end
	end
end

--青囊

ai_fill_skill["tenyearqingnang"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local compare_func = function(a,b)
		local v1 = self:getKeepValue(a)+( a:isRed() and 50 or 0 )+( a:isKindOf("Peach") and 50 or 0 )
		local v2 = self:getKeepValue(b)+( b:isRed() and 50 or 0 )+( b:isKindOf("Peach") and 50 or 0 )
		return v1<v2
	end
	table.sort(cards,compare_func)
	return parse_policy(self,("@TenyearQingnangCard=%d"):format(cards[1]:getId()))
end

ai_card_use.TenyearQingnangCard = function(self, card, use, request)
	local friends = {}
	for _,p in ipairs(self.friends)do
		if p:getStrategyMark("tenyearqingnang_target-PlayClear")>0 or p:getLostHp()<=0 then continue end
		table.insert(friends,p)
	end
	if #friends<=0 then return end

	local arr1,arr2 = self:getWoundedFriend(false,true,friends)
	local target = nil

	if #arr1>0 and (self:isWeak(arr1[1]) or self:getOverflow()>=1) and arr1[1]:getHp()<getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		use.card = card
		use.to:append(target)
		return
	end
	if self:getOverflow()>0 and #arr2>0 then
		for _,friend in ipairs(arr2)do
			if not friend:hasSkills("hunzi|longhun") then
				use.card = card
				use.to:append(friend)
				return
			end
		end
	end
end

sgs.ai_use_priority.TenyearQingnangCard = sgs.ai_use_priority.QingnangCard
sgs.ai_card_intention.TenyearQingnangCard = sgs.ai_card_intention.QingnangCard
sgs.dynamic_value.benefit.TenyearQingnangCard = true

--利驭
ai_skill_invoke.tenyearliyu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local to = data:toPlayer()
    if self:isFriend(to)
	then return (self:doDisCard(to,"ej") or #self.enemies>0) or false
	else return (to:hasEquip()) or false end
	return false

end

sgs.ai_skill_playerchosen.tenyearliyu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"handcard")
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


--闭月
ai_skill_invoke.tenyearbiyue = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw()) or false
end

--耀武
ai_skill_choice.tenyearyaowu = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	return ai_choice_result((ai_skill_choice.yaowu(self,{reason="yaowu",choices=options and options.choices or (choices~=nil and {} or nil),inquiry_scope="nested"},nil)), options)
end

--烈弓
ai_skill_invoke.tenyearliegong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (ai_skill_invoke.liegong(self, options, request)) or false
end

--狂骨
ai_skill_choice.tenyearkuanggu = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	choices = choices:split("+")
	if table.contains(choices,"draw") and #self.enemies>0
	and self.player:getPhase()==sgs.Player_Play and sgs.Slash_IsAvailable(self.player) then
		return ai_choice_result(("draw"), options)
	end
	if table.contains(choices,"recover") and self.player:getLostHp()>0 and self:isWeak() then
		return ai_choice_result(("recover"), options)
	end
	if table.contains(choices,"draw") and self:needBear() then
		return ai_choice_result(("draw"), options)
	end
	if table.contains(choices,"recover") and self.player:getLostHp()>0 then
		return ai_choice_result(("recover"), options)
	end
    return ai_choice_result(("draw"), options)
end

--奇谋

ai_fill_skill["tenyearqimou"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies<=0 then return end
	write(self,"qm_lose",math.min(self:getCardsNum("Slash")-1,self.player:getHp()+self:getCardsNum("Analeptic,Peach")-1))
	if read(self,"qm_lose")<2 then return end
	return parse_policy(self,"@TenyearQimouCard=.")
end

ai_card_use.TenyearQimouCard = function(self, card, use, request)
	hypothetical_distance(self,-read(self,"qm_lose"))
	local slash = self:getCard("Slash")
	if not slash then hypothetical_distance(self,read(self,"qm_lose")) return end
	local dummy_use = dummy_plan()
	if slash then self:useBasicCard(slash,dummy_use) end
	hypothetical_distance(self,read(self,"qm_lose"))
	if not dummy_use.card or dummy_use.to:isEmpty() then return end
	use.card = card
end

ai_skill_choice.tenyearqimou = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	choices = choices:split("+")
	for _,choice in ipairs(choices)do
		if tonumber(choice)==read(self,"qm_lose") then return ai_choice_result((choice), options) end
	end
	return ai_choice_result((choices[1]), options)
end

sgs.ai_use_priority.TenyearQimouCard = sgs.ai_use_priority.Slash+0.1

--神速
ai_skill_use["@@tenyearshensu1"] = function(self, prompt, request)
	local card_str = raw_shensu1(self,prompt)
	if not card_str or card_str=="." then return "." end
	return string.gsub(card_str,"@ShensuCard","@TenyearShensuCard")
end

ai_skill_use["@@tenyearshensu2"] = function(self, prompt, request)
	local card_str = raw_shensu2(self,prompt,method)
	if not card_str or card_str=="." then return "." end
	return string.gsub(card_str,"@ShensuCard","@TenyearShensuCard")
end

ai_skill_use["@@tenyearshensu3"] = function(self, prompt, request)
	self.enemies = self:sort(self.enemies,"defense")
	if self:needBear() then return "." end
	local selfSub = self:getOverflow()
	local selfDef = self:getDefense(self.player)
	for _,enemy in ipairs(self.enemies)do
		local def = self:getDefenseSlash(enemy)
		local slash = clone(self,"tenyearshensu","_tenyearshensu","slash",sgs.Card_NoSuit,0,{})
		local eff = self:slashIsEffective(slash,enemy) and self:isGoodTarget(enemy,self.enemies,slash)

		if not self.player:canSlash(enemy,slash,false) then
		elseif self:slashProhibit(nil,enemy) then
		elseif def<6 and eff then return "@TenyearShensuCard=.->"..enemy:objectName()

		elseif selfSub>=2 then return "@TenyearShensuCard=.->"..enemy:objectName()
		elseif selfDef<6 then return "." end
	end

	for _,enemy in ipairs(self.enemies)do
		local def=self:getDefense(enemy)
		local slash = clone(self,"tenyearshensu","_tenyearshensu","slash",sgs.Card_NoSuit,0,{})
		local eff = self:slashIsEffective(slash,enemy) and self:isGoodTarget(enemy,self.enemies,slash)

		if not self.player:canSlash(enemy,slash,false) then
		elseif self:slashProhibit(nil,enemy) then
		elseif eff and def<8 then return "@TenyearShensuCard=.->"..enemy:objectName()
		else return "." end
	end
	return "."
end

sgs.ai_cardneed.tenyearshensu = function(to,card,self)
	return sgs.ai_cardneed.shensu(to,card,self)
end

sgs.ai_card_intention.TenyearShensuCard = sgs.ai_card_intention.ShensuCard
sgs.tenyearshensu_keep_value = sgs.shensu_keep_value

--据守
ai_skill_invoke.tenyearjushou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw()) or false
end

sgs.ai_skill_cardask["@tenyearjushou"] = function(self,data)
	if self.player:getHandcardNum()==1 then
		local id = self.player:handCards():first()
		return "$"..id
	end

	local equips,not_equips = {},{}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	for _,c in ipairs(cards)do
		if c:isKindOf("EquipCard") then
			table.insert(equips,c)
		else
			table.insert(not_equips,c)
		end
	end
	if #equips>0 then
		equips = self:sortByUseValue(equips)
		local sp = AIList.new({})
		sp:append(self.player)
		for _,c in ipairs(equips)do
			if self.player:canUse(c,sp) then
				local index = known(c:getEquipSlot(),"equipment location")
				if self.player:getEquip(index) then continue end
				return "$"..c:getKnownEffectiveId()
			end
		end
	end
	if #not_equips>0 then
		not_equips = self:sortByKeepValue(not_equips)
		for _,c in ipairs(not_equips)do
			if self.player:canDiscard(self.player,c:getKnownEffectiveId()) then
				if c:isKindOf("Peach") or (c:isKindOf("Jink") and self:getCardsNum("Jink")==1) or (c:isKindOf("ExNihilo") and self.player:canUse(c)) then continue end
				return "$"..c:getKnownEffectiveId()
			end
		end
	end
	if #equips>0 then
		equips = self:sortByUseValue(equips)
		for _,c in ipairs(equips)do
			if self.player:canUse(c) then
				return "$"..c:getKnownEffectiveId()
			end
		end
	end
	return "."
end

--解围
sgs.ai_view_as.tenyearjiewei = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getKnownEffectiveId()
	if card_place==sgs.Player_PlaceEquip then
		return{name="nullification",skill="tenyearjiewei",suit=card:getSuit(),number=card:getNumber(),subcards={card_id}}
	end
end

sgs.ai_skill_cardask["@tenyearjiewei"] = function(self,data)
	local id,cards = nil,{}
	if self:needToThrowArmor() and self.player:canDiscard(self.player,self.player:getArmor():getEffectiveId()) then
		id = self.player:getArmor():getEffectiveId()
	else
		for _,c in sgs.qlist(self.player:getCards("he"))do
			if self.player:canDiscard(self.player,c:getKnownEffectiveId()) then
				table.insert(cards,c)
			end
		end
		if #cards<=0 then return "." end
		cards = self:sortByKeepValue(cards)
		id = cards[1]:getKnownEffectiveId()
	end

	if not id then return "." end

	local from,card,to = self:moveField(nil,"ej")
	if from and card and to then
		save_override(self,"playerchosen","tenyearjiewei_from",from)
		save_override(self,"cardchosen","tenyearjiewei",card:getId())
		save_override(self,"playerchosen","tenyearjiewei_to",to)
		return "$"..id
	end
	return "."
end

--天香
ai_skill_use["@@tenyeartianxiang"] = function(self, prompt, request)
	local cards = self.player:getCards("h")
	local str = "@TenyearTianxiangCard="
	local reason = "tenyeartianxiang"
	if prompt=="@oltianxiang" then
		cards = self.player:getCards("he")
		str = "@OLTianxiangCard="
		reason = "oltianxiang"
	end
	cards = sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards,true)

	local card_id,choice

	for _,card in ipairs(cards)do
		if self.player:canDiscard(self.player,card:getKnownEffectiveId()) and card:getSuit()==sgs.Card_Heart and not card:isKindOf("Peach") then
			card_id = card:getId()
			break
		end
	end
	if not card_id then return "." end
	self.enemies = self:sort(self.enemies,"hp")
	self.friends_noself = self:sort(self.friends_noself)

	for _,friend in ipairs(self.friends_noself)do
		if not hasZhaxiangEffect(friend) or self:willSkipPlayPhase(friend) or self:isWeak(friend) then continue end
		ai_skill_choice[reason] = "losehp"
		return str..card_id.."->"..friend:objectName()
	end

	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()<=1 and enemy:isAlive() and not hasZhaxiangEffect(enemy) then
			ai_skill_choice[reason] = "losehp"
			return str..card_id.."->"..enemy:objectName()
		end
	end

	for _,enemy in ipairs(self.enemies)do
		if enemy:isAlive() and not hasZhaxiangEffect(enemy) then
			ai_skill_choice[reason] = "losehp"
			return str..card_id.."->"..enemy:objectName()
		end
	end

	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()<=1 and enemy:isAlive() and not hasBuquEffect(enemy) and self:damageIsEffective(enemy) then
			ai_skill_choice[reason] = "damage"
			return str..card_id.."->"..enemy:objectName()
		end
	end

	for _,friend in ipairs(self.friends_noself)do
		if friend:getLostHp()>=1 and friend:isAlive()
		and (friend:hasSkills("yiji|buqu|nosbuqu|shuangxiong|zaiqi|yinghun|jianxiong|fangzhu")
			or self:needToLoseHp(friend)
			or (friend:getHandcardNum()<3 and (friend:hasSkill("nosrende") or friend:hasSkill("rende") and not friend:hasUsed("RendeCard"))))
		then
			ai_skill_choice[reason] = "damage"
			return str..card_id.."->"..friend:objectName()
		elseif hasBuquEffect(friend) then
			ai_skill_choice[reason] = "damage"
			return str..card_id.."->"..friend:objectName()
		end
	end

	for _,enemy in ipairs(self.enemies)do
		if enemy:getLostHp()==0 and enemy:isAlive() and self:damageIsEffective(enemy) and not self:canDraw(enemy) then
			ai_skill_choice[reason] = "damage"
			return str..card_id.."->"..enemy:objectName()
		end
	end

	for _,enemy in ipairs(self.enemies)do
		if enemy:getLostHp()==0 and enemy:isAlive() and not self:canDraw(enemy) then
			ai_skill_choice[reason] = "damage"
			return str..card_id.."->"..enemy:objectName()
		end
	end

	for _,enemy in ipairs(self.enemies)do
		if enemy:isAlive() and self:damageIsEffective(enemy) and not self:canDraw(enemy) then
			ai_skill_choice[reason] = "damage"
			return str..card_id.."->"..enemy:objectName()
		end
	end

	for _,enemy in ipairs(self.enemies)do
		if enemy:isAlive() and self:damageIsEffective(enemy) then
			ai_skill_choice[reason] = "damage"
			return str..card_id.."->"..enemy:objectName()
		end
	end
	return "."
end

--鞬出
ai_skill_invoke.tenyearjianchu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if not target then return (false) or false end
	return (not self:isFriend(target) and self:doDisCard(target,"he")) or false
end

--散谣

ai_fill_skill["tenyearsanyao"] = function(self, options, request)
    local inclusive = options and options.inclusive

	return parse_policy(self,"@TenyearSanyaoCard=.")
end

ai_card_use.TenyearSanyaoCard = function(self, card, use, request)
	local alives = self.room:getAlivePlayers()
	local max_hp = -1000
	for _,p in sgs.qlist(alives)do
		local hp = p:getHp()
		if hp>max_hp then
			max_hp = hp
		end
	end
	local friends,enemies = {},{}
	for _,p in sgs.qlist(alives)do
		if p:getHp()==max_hp then
			if self:isFriend(p) then
				table.insert(friends,p)
			elseif self:isEnemy(p) then
				table.insert(enemies,p)
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	local discards = {}
	for _,c in ipairs(cards)do
		if c:isKindOf("Peach") or c:isKindOf("ExNihilo") or (c:isKindOf("Jink") and self:getCardsNum("Jink")==1) then continue end
		if not self.player:canDiscard(self.player,c:getKnownEffectiveId()) then continue end
		table.insert(discards,c:getKnownEffectiveId())
	end
	if #discards<=0 then return end

	local targets = {}
	if #enemies>0 then
		enemies = self:sort(enemies,"hp")
		for _,enemy in ipairs(enemies)do
			if self:damageIsEffective(enemy,sgs.DamageStruct_Normal,self.player) then
				if self:cantbeHurt(enemy,self.player) then
				elseif self:needToLoseHp(enemy,self.player) then
				else
					table.insert(targets,enemy)
				end
			end
		end
	end

	if #friends>0 and not target then
		friends = self:sort(friends,"hp")
		friends = sgs.reverse(friends)
		for _,friend in ipairs(friends)do
			if self:damageIsEffective(friend,sgs.DamageStruct_Normal,self.player) then
				if self:needToLoseHp(friend,self.player) then
				elseif friend:getCards("j"):length()>0 and self.player:hasSkill("zhiman") then
				elseif self:needToThrowArmor(friend) and self.player:hasSkill("zhiman") then
					table.insert(targets,enemy)
				end
			end
		end
	end

	local max_num,to_discards = math.min(#discards,#targets),{}
	for i = 1,max_num do
		table.insert(to_discards,discards[i])
	end
	use.card = parse_policy(self,"@TenyearSanyaoCard="..table.concat(to_discards,"+"))
	for i = 1,max_num do
		use.to:append(targets[i])
	end
end

sgs.ai_use_value.TenyearSanyaoCard = sgs.ai_use_value.SanyaoCard
sgs.ai_card_intention.TenyearSanyaoCard = sgs.ai_card_intention.SanyaoCard

--制蛮
ai_skill_invoke.tenyearzhiman = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (ai_skill_invoke.zhiman(self, options, request)) or false
end

--镇军
sgs.ai_skill_playerchosen.tenyearzhenjun = function(self,targets)
    targets = sgs.QList2Table(targets)
    targets = self:sort(targets,"defense")
    targets = sgs.reverse(targets)
    for _,target in ipairs(targets)do
		if self:isFriend(target) and self:needToThrowArmor(target) then
			write(self,"tenyearzhenjun_discard",false)
			return target
		end
    end
    targets = sgs.reverse(targets)
    for _,target in ipairs(targets)do
        if self:isEnemy(target) and self:doDisCard(target,"he") then
            write(self,"tenyearzhenjun_discard",true)
            return target
        end
    end

    if table.contains(targets,self.player) then
		local num,not_equip = math.max(1,self.player:getHandcardNum()-self.player:getHp()),0
		num = math.min(num,self.player:getHandcardNum())
		for _,c in sgs.qlist(self.player:getCards("h"))do
			if not c:isKindOf("EquipCard") and not c:isKindOf("Peach") and not c:isKindOf("ExNihilo") then
				not_equip = not_equip+1
			end
		end
		if not_equip<=0 then return nil end
		if not_equip>num then
			write(self,"tenyearzhenjun_discard",false)
			return self.player
		end
	end
	return nil
end

sgs.ai_skill_cardchosen.tenyearzhenjun = function(self,who,flags)
	if who:objectName()==self.player:objectName() then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		cards = self:sortByKeepValue(cards)
		for _,c in ipairs(cards)do
			if not c:isKindOf("EquipCard") and not c:isKindOf("Peach") and not c:isKindOf("ExNihilo") then
				return c:getId()
			end
		end
		return cards[1]:getId()
	else
		if who:getCards(flags):length()==1 then return who:getCards(flags):first() end
		local id = self:askForCardChosen(who,flags,"dismantlement")
		return id
	end
end

sgs.ai_skill_discard.tenyearzhenjun = function(self,discard_num,min_num,optional,include_equip)
	if not read(self,"tenyearzhenjun_discard") then return {} end
	return self:askForDiscard("dummy",discard_num,min_num,false,include_equip)
end

--精策
ai_skill_invoke.tenyearjingce = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw()) or false
end

--当先
ai_skill_invoke.tenyeardangxian = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self:isWeak() then return (false) or false end
	if self:getCardsNum("Slash")>1 then return (false) or false end
	local slashs = AIList.new({})
	for _,id in sgs.qlist(self.room:getDiscardPile())do
		if known_card(self,id):isKindOf("Slash") then
			slashs:append(known_card(self,id))
		end
	end
	if slashs:isEmpty() then return (false) or false end
	local slash
	if slashs:length()==1 then
		slash = slashs:first()
	else
		slash = self:getEvaluationCard("slash")
	end
	local dummy_use = dummy_plan()
	self:useCardSlash(slash,dummy_use)
	if dummy_use.card and dummy_use.to:length()>0 then
		return (true) or false
	end
	return (false) or false
end

--伏枥
ai_skill_invoke.tenyearfuli = true

--醇醪
sgs.ai_cardneed.tenyearchunlao = function(to,card)
	return sgs.ai_cardneed.chunlao(to,card)
end

sgs.ai_card_intention.TenyearChunlaoWineCard = sgs.ai_card_intention.ChunlaoWineCard
sgs.tenyearchunlao_keep_value = sgs.chunlao_keep_value

ai_skill_use["@@tenyearchunlao"] = function(self, prompt, request)
	local str = raw_chunlao(self,prompt)
	if not str or str=="" or str=="." then return "." end
	return string.gsub(str,"ChunlaoCard","TenyearChunlaoCard")
end

sgs.ai_cardsview_valuable.tenyearchunlao = function(self,class_name,player)
	local dying = player:getRoom():getCurrentDyingPlayer()
	if dying then
		if dying:isLocked(self:getEvaluationCard("analeptic")) then return end
		local wines = player:getPile("wine")
		local wine_id = wines:first()
		if not self:willSkipPlayPhase()
		and self:canDraw() then
			for _,id in sgs.qlist(wines)do
				if known_card(self,id):isKindOf("ThunderSlash")
				then wine_id = id break end
			end
		end
		if self:isWeak(nil,false)
		and player:getLostHp()>0 then
			for _,id in sgs.qlist(wines)do
				if known_card(self,id):isKindOf("FireSlash")
				then wine_id = id break end
			end
		end
		return "@TenyearChunlaoWineCard="..wine_id
	end
end

--二版疠火
function sgs.ai_cardneed.secondtenyearlihuo(to,card,self)
	return sgs.ai_cardneed.lihuo(to,card,self)
end

ai_skill_invoke.secondtenyearlihuo = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if data:toString()=="put" then return (true) or false end
	return (ai_skill_invoke.lihuo(self, options, request)) or false
end

sgs.ai_view_as.secondtenyearlihuo = function(card,player,card_place)
	local str = sgs.ai_view_as.lihuo(card,player,card_place)
	if not str or str=="." or str=="" then return end
	if type(str)=="table"then local out={};for k,v in pairs(str)do out[k]=v end;out.skill="secondtenyearlihuo";return out end
 return string.gsub(str,"lihuo","secondtenyearlihuo")
end


ai_fill_skill["secondtenyearlihuo"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local slash_card
	for _,card in ipairs(self:addHandPile())do
		if card:isKindOf("Slash") and not card:isKindOf("NatureSlash") then
			slash_card = card
			break
		end
	end
	if not slash_card then return nil end
	local dummy_use = dummy_plan()
	self:useCardFireSlash(slash_card,dummy_use)
	if dummy_use.card and dummy_use.to:length()>0 then
		local use = {}
		use.from = self.player
		use.to = dummy_use.to
		use.card = slash_card
		if not ai_skill_invoke.secondtenyearlihuo(self,self:inquiryInput("skill_invoke","secondtenyearlihuo",{use=use})) then return nil end
	else return nil end
	local suit = slash_card:getSuitString()
	local number = slash_card:getNumberString()
	local card_id = slash_card:getKnownEffectiveId()
	return parse_policy(self,("fire_slash:secondtenyearlihuo[%s:%s]=%d"):format(suit,number,card_id))
end

--二版醇醪
sgs.ai_cardneed.secondtenyearchunlao = function(to,card)
	return sgs.ai_cardneed.chunlao(to,card)
end

sgs.ai_card_intention.SecondTenyearChunlaoWineCard = sgs.ai_card_intention.ChunlaoWineCard
sgs.secondtenyearchunlao_keep_value = sgs.chunlao_keep_value

ai_skill_use["@@secondtenyearchunlao"] = function(self, prompt, request)
	local str = raw_chunlao(self,prompt)
	if not str or str=="" or str=="." then return "." end
	return string.gsub(str,"ChunlaoCard","SecondTenyearChunlaoCard")
end

sgs.ai_cardsview_valuable.secondtenyearchunlao = function(self,class_name,player)
	local str = sgs.ai_cardsview_valuable.tenyearchunlao(self,class_name,player)
	if not str or str=="" or str=="." then return end
	if type(str)=="table"then local out={};for k,v in pairs(str)do out[k]=v end;out.legacy_class="SecondTenyearChunlaoWineCard";out.skill="secondtenyearchunlao";return out end
 return string.gsub(str,"TenyearChunlaoWineCard","SecondTenyearChunlaoWineCard")
end

--将驰
ai_skill_use["@@tenyearjiangchi"] = function(self, prompt, request)
	local choice = ai_skill_choice.jiangchi(self,{reason="jiangchi",choices=nil,inquiry_scope="nested"},nil)
	if choice=="cancel" then return "." end
	if choice=="jiang" then
		return "@TenyearJiangchiCard=."
	end
	if choice=="chi" then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		cards = self:sortByKeepValue(cards)
		if cards[1]:isKindOf("Slash") and self:getCardsNum("Slash")<=2 then return "." end
		return "@TenyearJiangchiCard="..cards[1]:getKnownEffectiveId()
	end
	return "."
end

function sgs.ai_cardneed.tenyearjiangchi(to,card,self)
	return sgs.ai_cardneed.jiangchi(to,card,self)
end

--怃戎
ai_fill_skill.tenyearwurong = function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:isKongcheng() then return end
    return parse_policy(self,"@TenyearWurongCard=.")
end

ai_card_use.TenyearWurongCard = function(self, card, use, request)
    local handcards = self.player:getHandcards()
    local my_slashes,my_cards = {},{}
    for _,c in sgs.qlist(handcards)do
        if c:isKindOf("Slash") then
            table.insert(my_slashes,c)
        else
            table.insert(my_cards,c)
        end
    end
    local no_slash = ( #my_slashes==0 )
    local all_slash = ( #my_cards==0 )
    local need_slash,target = nil,nil

    --自己展示的一定不是【杀】，目标展示的必须是【闪】，方可获得目标一张牌
	local other_players = self.room:getOtherPlayers(self.player)
    if no_slash then
        for _,p in ipairs(self:findPlayerToDiscard("he",false,false,other_players))do
            if not p:isKongcheng() then
                local knowns,unknowns = known_hand_partition(self,p)
                if #unknowns==0 then
                    local all_jink = true
                    for _,jink in ipairs(knowns)do
                        if not jink:isKindOf("Jink") then
                            all_jink = false
                            break
                        end
                    end
                    if all_jink then
                        need_slash,target = false,p
                        break
                    end
                end
            end
        end
    end

    --自己展示的一定是【杀】，目标展示的不是【闪】时，可对目标造成1点伤害
    if all_slash and not target then
        for _,p in ipairs(self:findPlayerToDamage(1,self.player,"N",nil,5))do
            if self.player~=p and not p:isKongcheng() then
                local knowns,unknowns = known_hand_partition(self,p)
                if self:isFriend(p) then
                    local all_jink = true
                    if #unknowns==0 then
                        for _,c in ipairs(knowns)do
                            if not c:isKindOf("Jink") then
                                all_jink = false
                                break
                            end
                        end
                    else
                        all_jink = false --队友会配合不展示【闪】的
                    end
                    if not all_jink then
                        need_slash,target = true,p
                        break
                    end
                else
                    local all_jink = false
                    if #unknowns==0 then
                        for _,c in ipairs(knowns)do
                            if c:isKindOf("Jink") then
                                all_jink = true
                                break
                            end
                        end
                    end
                    if not all_jink then
                        need_slash,target = true,p
                        break
                    end
                end
            end
        end
    end

    --自己展示的不一定是【杀】，可根据目标情况决定展示的牌
    if not target then
        local friends,enemies,others = {},{},{}
        for _,p in sgs.qlist(other_players)do
            if not p:isKongcheng() then
                if self:isFriend(p) then
                    table.insert(friends,p)
                elseif self:isEnemy(p) then
                    table.insert(enemies,p)
                else
                    table.insert(others,p)
                end
            end
        end

        for _,enemy in ipairs(self:findPlayerToDamage(1,self.player,"N",enemies,5))do
            local knowns,unknowns = known_hand_partition(self,enemy)
            local no_jink = true
            if #unknowns==0 then
                for _,jink in ipairs(knowns)do
                    if jink:isKindOf("Jink") then
                        no_jink = false
                        break
                    end
                end
            else
                no_jink = false
            end
            if no_jink and enemy~=self.player then
                need_slash,target = true,enemy
                break
            end
        end

        if not target then
            for _,p in ipairs(self:findPlayerToDiscard("he",false,false,other_players))do
                if not p:isKongcheng() then
                    local knowns,unknowns = known_hand_partition(self,p)
                    if self:isFriend(p) then
                        local has_jink = false
                        for _,jink in ipairs(knowns)do
                            if jink:isKindOf("Jink") then
                                has_jink = true
                                break
                            end
                        end
                        if has_jink then
                            need_slash,target = false,p
                            break
                        end
                    else
                        local all_jink = true
                        if #unknowns==0 then
                            for _,c in ipairs(knowns)do
                                if not c:isKindOf("Jink") then
                                    all_jink = false
                                    break
                                end
                            end
                        else
                            all_jink = false
                        end
                        if all_jink then
                            need_slash,target = false,p
                            break
                        end
                    end
                end
            end
        end

        if not target then
            for _,friend in ipairs(self:findPlayerToDamage(1,self.player,"N",friends,25))do
                local knowns,unknowns = known_hand_partition(self,friend)
                local all_jink = true
                for _,c in ipairs(knowns)do
                    if not c:isKindOf("Jink") then
                        all_jink = false
                        break
                    end
                end
                if not all_jink then
                    need_slash,target = true,friend
                    break
                end
            end
        end

        if not target then
            local victim = self:findPlayerToDamage(1,self.player,"N",others,5)[1]
            if victim then
                need_slash,target = true,victim
            end
        end

        --只是为了看牌……
        if not target and #my_cards>0 then
            if #enemies>0 then
                enemies = self:sort(enemies,"handcard")
                need_slash,target = false,enemies[1]
            elseif #others>0 then
                others = self:sort(others,"threat")
                need_slash,target = false,others[1]
            end
        end

        if not target and #enemies>0 then
            enemies = self:sort(enemies,"defense")
            need_slash,target = (math.random(0,1)==0),enemies[1]
        end
    end

    if target and not target:isKongcheng() then
        local use_cards = need_slash and my_slashes or my_cards
        if #use_cards>0 then
            use_cards = self:sortByUseValue(use_cards,true)
            use.card = parse_policy(self,"@TenyearWurongCard="..use_cards[1]:getKnownEffectiveId())
            use.to:append(target)
        end
    end
end

sgs.ai_use_priority.TenyearWurongCard = sgs.ai_use_priority.WurongCard
sgs.ai_use_value.TenyearWurongCard = sgs.ai_use_value.WurongCard

--邀名
sgs.ai_skill_playerchosen.tenyearyaoming = function(self,targets)
	targets = sgs.QList2Table(targets)
	targets = self:sort(targets,"handcard")
	for _,p in ipairs(targets)do
		if self:isFriend(p) and self:canDraw(p) and p:getHandcardNum()<self.player:getHandcardNum() then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if self:isEnemy(p) and p:getHandcardNum()>self.player:getHandcardNum() and self:doDisCard(p,"h") then
			return p
		end
	end
	targets = sgs.reverse(targets)
	for _,p in ipairs(targets)do
		if self:isFriend(p) and not hasManjuanEffect(p) and p:getHandcardNum()==self.player:getHandcardNum() then
			return p
		end
	end
	targets = sgs.reverse(targets)
	for _,p in ipairs(targets)do
		if self:isFriend(p) and p:getHandcardNum()>self.player:getHandcardNum() and not self:doDisCard(p,"h") then
			return p
		end
	end
	return nil
end

sgs.ai_skill_discard.tenyearyaoming = function(self,discard_num,min_num,optional,include_equip)
	local discards,dummy = {},self:askForDiscard("dummy",discard_num,min_num,false,include_equip)
	for _,id in ipairs(dummy)do
		local card = known_card(self,id)
		if card:isKindOf("Peach") or card:isKindOf("ExNihilo") or (card:isKindOf("Jink") and self:getCardsNum("Jink")==1) then continue end
		table.insert(discards,id)
	end
	return discards
end

sgs.ai_playerchosen_intention.tenyearyaoming = function(self,from,to)
	if hasManjuanEffect(to) then self:updateIntention(from,to,20) end
	if to:getHandcardNum()<=from:getHandcardNum() then
		self:updateIntention(from,to,-20)
	else
		if self:doDisCard(to) then
			self:updateIntention(from,to,-20)
		else
			self:updateIntention(from,to,20)
		end
	end
end

--胆守
ai_skill_invoke.tenyeardanshou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local name = data:toString():split(":")
	if #name<2 then return (false) or false end
	if name[1]=="tenyeardanshou_invoke" then
		local target = self.room:getCurrent()
		return (self:isFriend(target) or target:getHandcardNum()>self.player:getHandcardNum()) or false
	end
	local target = self.room:findPlayerByObjectName(name[2])
	if not target or target:isDead() then return (false) or false end
	return (self:isFriend(target) and self:needToLoseHp(target,self.player)
	or not self:isFriend(target) and self:canAttack(target)) or false
end

sgs.ai_skill_discard.tenyeardanshou = function(self,x,n)
	local cards = {}
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    handcards = self:sortByKeepValue(handcards)
   	for _,h in sgs.list(handcards)do
		if #cards>=n then break end
		table.insert(cards,h:getKnownEffectiveId())
	end
	if #cards<n then return {} end
   	local target = self.room:getCurrent()
	return self:isEnemy(target) and (self:isWeak(target) or #cards<2) and cards or {}
end

--谮毁
sgs.ai_skill_playerchosen.tenyearzenhui = function(self,targetlist)
	write(self,"tenyearzenhui_collateral",nil)
	local use = tag(self,"tenyearzenhui","CardUse")
	local target = use.to:first()
	if not target then return end
	local dummy_use = dummy_plan(true,99,{target})
	self:useCardByClassName(use.card,dummy_use)
	if dummy_use.card and use.card:getClassName()==dummy_use.card:getClassName() and not dummy_use.to:isEmpty() then
		if use.card:isKindOf("Collateral") then
			local player = dummy_use.to:first()
			if targetlist:contains(player) and (self:isFriend(player) or self:hasTrickEffective(use.card,target,player)) then
				write(self,"tenyearzenhui_collateral",dummy_use.to:at(1))
				return player
			end
			return false
		elseif use.card:isKindOf("Slash") then
			for _,player in sgs.qlist(dummy_use.to)do
				if targetlist:contains(player) and (self:isFriend(player) or not self:slashProhibit(use.card,target,player)) then
					return player
				end
			end
		elseif use.card:isKindOf("FireAttack") then
			for _,player in sgs.qlist(dummy_use.to)do
				if targetlist:contains(player) and not self:isFriend(player,target) and not self:isFriend(player) and self:hasTrickEffective(use.card,target,player) then
					return player
				end
			end
			dummy_use.to = sgs.QList2Table(dummy_use.to)
			self:sort(dummy_use.to,"handcard")
			dummy_use.to = sgs.reverse(dummy_use.to)
			local suits = {}
			for _,c in sgs.qlist(self.player:getHandcards())do
				if c:getSuit()<=3 and not table.contains(suits,c:getSuitString()) then table.insert(suits,c:getSuitString()) end
			end
			if #suits<=2 or self:getSuitNum("heart",false,target)>0 and self:getSuitNum("heart")==0 then
				for _,player in ipairs(dummy_use.to)do
					if self:isFriend(player) and targetlist:contains(player) then return player end
				end
			end
		elseif use.card:isKindOf("Duel") then
			for _,player in sgs.qlist(dummy_use.to)do
				if targetlist:contains(player) and (self:isFriend(player) or self:hasTrickEffective(use.card,target,player)) then
					return player
				end
			end
		elseif use.card:isKindOf("Drowning") then
			for _,player in sgs.qlist(dummy_use.to)do
				if targetlist:contains(player) and (self:isFriend(player) or self:hasTrickEffective(use.card,target,player)) then
					return player
				end
			end
		elseif use.card:isKindOf("Dismantlement") then
			for _,player in sgs.qlist(dummy_use.to)do
				if targetlist:contains(player) and self:isFriend(player) then
					return player
				end
			end
			for _,player in sgs.qlist(dummy_use.to)do
				if targetlist:contains(player) then
					if not self:isFriend(player,target) then
						return player
					elseif not self:needToThrowArmor(target)
						and (target:getJudgingArea():isEmpty()
							or (not target:containsTrick("indulgence")
								and not target:containsTrick("supply_shortage")
								and not (target:containsTrick("lightning") and self:getFinalRetrial(target)==1))) then
						return player
					end
				end
			end
		elseif use.card:isKindOf("Snatch") then
			for _,player in sgs.qlist(dummy_use.to)do
				if targetlist:contains(player) and self:isFriend(player) then
					return player
				end
			end
			local friend = self:findPlayerToDraw(false)
			if friend and targetlist:contains(friend) and self:hasTrickEffective(use.card,target,friend) then
				return friend
			end
		else
			diagnostic(self,"playerchosen.tenyearzenhui->"..use.card:getClassName().."?")
		end
	end
	return false
end

sgs.ai_skill_playerchosen.tenyearzenhui_collateral = function(self,targetlist)
	if read(self,"tenyearzenhui_collateral") then return read(self,"tenyearzenhui_collateral") end
	diagnostic(self,debug.traceback())
	return targetlist:at(math.random(0,targetlist:length()-1))
end

sgs.ai_skill_cardask["tenyearzenhui-give"] = function(self,data)
	local use = data:toCardUse()
	local target = use.to:first()
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	local id = cards[1]:getKnownEffectiveId()
	if use.card:isKindOf("Snatch")
	then
		if self:isFriend(use.from)
		then
			if self:askForCardChosen(self.player,"ej","dummyReason") or not use.from:getAI()
			then return "."
			else
				cards = self:sortByUseValue(cards)
				return cards[1]:getKnownEffectiveId()
			end
		elseif not self:hasTrickEffective(use.card,self.player,use.from)
		then return "." end
		return id
	elseif use.card:isKindOf("Slash")
	then
		if self:slashProhibit(use.card,self.player,use.from)
		or self:ajustDamage(use.from,self.player,1,use.card)<2
		and  self:needToLoseHp(self.player,use.from)
		then return "."
		elseif self:isFriend(target)
		then
			if not self:slashIsEffective(use.card,target,self.player)
			then return id end
		elseif not self:isValuableCard(cards[1]) or self:isWeak() or self:getCardsNum("Jink")==0 or not sgs.isJinkAvailable(use.from,self.player,use.card)
		then return id end
		return "."
	elseif use.card:isKindOf("Dismantlement")
	then
		if not self:hasTrickEffective(use.card,self.player,use.from)
		then return "."
		elseif self:isFriend(use.from) and self:askForCardChosen(self.player,"ej","dummyReason")
		then return "." end
		return id
	elseif use.card:isKindOf("Duel")
	then
		if self:needToLoseHp(self.player,use.from,use.card)
		then return "."
		elseif not self:hasTrickEffective(use.card,self.player,use.from)
		then return "."
		elseif self:isFriend(use.from)
		then
			if self:needToLoseHp(use.from,self.player,use.card)
			and self:getCardsNum("Slash")-(cards[1]:isKindOf("Slash") and 1 or 0)>0
			then return "." end
		else
			if self:getCardsNum("Slash")-(cards[1]:isKindOf("Slash") and 1 or 0)>getCardsNum("Slash",use.from,self.player)
			then return "." end
		end
		return id
	elseif use.card:isKindOf("FireAttack")
	then
		if self:needToLoseHp(self.player,use.from,use.card)
		then return "." end
		return id
	elseif use.card:isKindOf("Collateral")
	then
		local victim = tag(self,"collateralVictim","Player")
		if sgs.ai_skill_cardask["collateral-slash"](self,nil,nil,victim,use.from)~="."
		and self:isFriend(use.from) or not self:isValuableCard(cards[1])
		then return "." end
		return id
	elseif use.card:isKindOf("Drowning")
	then
		if self:needToLoseHp(self.player,use.from,use.card)
		or self:needToThrowArmor()
		then return "."
		elseif self:isValuableCard(cards[1]) and self:isEnemy(use.from)
		then return "." end
		return id
	else
		diagnostic(self,"@tenyearzenhui->"..use.card:getClassName().."?")
	end
	return "."
end

sgs.ai_skill_cardask["tenyearzenhui-mustgive"] = function(self,data)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	return cards[1]:getKnownEffectiveId()
end

--骄矜
sgs.ai_skill_cardask["@tenyearjiaojin"] = function(self,data)
	local id = -1
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	for _,c in ipairs(cards)do
		if c:getTypeId()==sgs.Card_TypeEquip then id = c:getKnownEffectiveId() break end
	end
	if id<0 then return "." end
	local use = data:toCardUse()
	if not use then return "." end
	local card = use.card
	local nature = sgs.DamageStruct_Normal
	if card:isKindOf("FireSlash") or card:isKindOf("FireAttack") then nature = sgs.DamageStruct_Fire end
	if card:isKindOf("ThunderSlash") then nature = sgs.DamageStruct_Thunder end

	if card:isKindOf("Slash") then
		if self:slashIsEffective(card,self.player,use.from) then return "." end
		if self:damageIsEffective(self.player,nature,use.from)
		and not self:needToLoseHp(self.player,use.from,card) then
			return id
		end
	else
		if not self:hasTrickEffective(card,self.player,use.from) then return "." end  --可以主动弃装备拿有价值的锦囊，这里偷懒一下
		return id
	end
	return "."
end

--奔袭
ai_skill_use["@@tenyearbenxi!"] = function(self, prompt, request)
	local valid = property(self,"extra_collateral"):split("+")
	local destlist = self.room:getOtherPlayers(self.player)
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
    destlist = self:sort(destlist,"hp")
	local c = extra_card(self,valid[1])
	for _,to in sgs.list(destlist)do
		if table.contains(valid,to:objectName()) then continue end
		if self:isEnemy(to) and c:isDamageCard() and can_to(self,c,self.player,to)
		then return ("@ExtraCollateralCard=.->"..to:objectName()) end
	end
end

--狂斧

ai_fill_skill["tenyearkuangfu"] = function(self, options, request)
    local inclusive = options and options.inclusive

	return parse_policy(self,"@TenyearKuangfuCard=.")
end

ai_card_use.TenyearKuangfuCard = function(self, card, use, request)
	local target = self:findPlayerToDiscard("e",true,true,self.room:getAlivePlayers())[1]
	if target then
		use.card = card
		use.to:append(target)
	end
end

sgs.ai_use_priority.TenyearKuangfuCard = sgs.ai_use_priority.Slash-0.1

ai_skill_use["@@tenyearkuangfu!"] = function(self, prompt, request)
	local slash = clone(self,"tenyearkuangfu","_tenyearkuangfu","slash",sgs.Card_NoSuit,0,{})
   	local d = self:aiUseCard(slash)
    if slash:isAvailable(self.player)
	and d.card and d.to then
	   	local c_tos = {}
	   	for _,p in sgs.list(d.to)do
	   		table.insert(c_tos,p:objectName())
	   	end
	   	return slash:getLegacyStringKey().."->"..table.concat(c_tos,"+")
	end
end

sgs.ai_skill_discard.tenyearkuangfu = function(self,discard_num,min_num,optional,include_equip)
	return self:askForDiscard("dummyreason",discard_num,min_num,false,include_equip)
end

--破军
ai_skill_invoke.tenyearpojun = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local target = data:toPlayer()
    if not self:isFriend(target) then return (true) or false end
    return (false) or false
end

ai_skill_choice.tenyearpojun_num = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	return ai_choice_result((items[#items]), options)
end

sgs.ai_use_revises.tenyearpojun = function(self,card,use)
	if card:isKindOf("Slash") then
		self:setStrategyCardFlag(card,"Qinggang",true)
	end
end

--断粮

ai_fill_skill["tenyearduanliang"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local card = raw_duanliang(self)
	if card then
		local str = card:getLegacyStringKey()
		str = string.gsub(str,"duanliang","tenyearduanliang")
		return parse_policy(self,str)
	end
end

sgs.ai_cardneed.tenyearduanliang = sgs.ai_cardneed.duanliang
sgs.tenyearduanliang_suit_value = sgs.duanliang_suit_value

--残蚀
ai_skill_invoke.tenyearcanshi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (ai_skill_invoke.canshi(self, options, request)) or false
end

sgs.ai_skill_discard.tenyearcanshi = function(self,discard_num,min_num,optional,include_equip)
	return self:askForDiscard("dummy",discard_num,min_num,false,include_equip)
end

--宴诛

ai_fill_skill["tenyearyanzhu"] = function(self, options, request)
    local inclusive = options and options.inclusive

	return parse_policy(self,"@TenyearYanzhuCard=.")
end

ai_card_use.TenyearYanzhuCard = function(self, card, use, request)
	if property(self,"tenyearyanzhu_level_up","Bool") then
		self.enemies = self:sort(self.enemies,"defense")
		for _,p in ipairs(self.enemies)do
			if self:doDisCard(p,"he") then
				use.card = card
				if (use.to) then use.to:append(p) end
				return
			end
		end
	else
		self.enemies = self:sort(self.enemies,"threat")
		for _,p in ipairs(self.enemies)do
			if not p:isNude() then
				use.card = card
				if (use.to) then use.to:append(p) end
				return
			end
		end
		for _,p in ipairs(self.friends_noself)do
			if self.needToThrowArmor(p) and p:getArmor() and not p:isJilei(p:getArmor()) then
				use.card = card
				if (use.to) then use.to:append(p) end
				return
			end
		end
	end
end

sgs.ai_use_priority.TenyearYanzhuCard = sgs.ai_use_priority.YanzhuCard

sgs.ai_skill_discard.tenyearyanzhu = function(self,_,__,optional)
    if not optional then return self:askForDiscard("dummyreason",1,1,false,true) end
    if self:needToThrowArmor() and self.player:getArmor() and not self.player:isJilei(self.player:getArmor()) then return self.player:getArmor():getEffectiveId() end
    if self.player:getTreasure() then
        if (self.player:getCardCount()==1) then return self.player:getTreasure():getEffectiveId()
        elseif not self.player:isKongcheng() then return self:askForDiscard("dummyreason",1,1,false,false) end
    end
    if self.player:getEquips():length()>2 and not self.player:isKongcheng() then return self:askForDiscard("dummyreason",1,1,false,false) end
    if self.player:getEquips():length()==1 then return {} end
    return self:askForDiscard("dummyreason",1,1,false,true)
end

--兴学
ai_skill_use["@@tenyearxingxue"] = function(self, prompt, request)
    local n = (property(self,"tenyearyanzhu_level_up","Bool")) and self.player:getMaxHp() or self.player:getHp()
    n = math.min(n,#self.friends)
	if n<=0 then return "." end
	self.friends = self:sort(self.friends,"defense")
    local l = AIList.new({})
    local s = {}
    for i = 1,n,1 do
        l:append(self.friends[i])
        table.insert(s,self.friends[i]:objectName())
    end
    if #s==0 then return "." end
    return "@TenyearXingxueCard=.->"..table.concat(s,"+")
end

sgs.ai_skill_discard.tenyearxingxue = function(self,discard_num,min_num,optional,include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	return cards[1]:getKnownEffectiveId()
end

--倾袭
ai_skill_invoke.tenyearqingxi = ai_skill_invoke.tenyearpojun

sgs.ai_skill_discard.tenyearqingxi = function(self,discard_num,min_num,optional,include_equip)
	return self:askForDiscard("dummyreason",discard_num,min_num,false,include_equip)
end

--夺刀
sgs.ai_skill_cardask["@tenyearduodao"] = function(self,data)
	local use = data:toCardUse()
	if not use or use.from:isDead() or not use.from:getWeapon() then
		if self:needToThrowArmor() and self.player:canDiscard(self.player,self.player:getArmor():getEffectiveId()) then
			return "$"..self.player:getArmor():getEffectiveId()
		elseif self.player:canDiscard(self.player,"h") and self:needToThrowLastHandcard() then
			return "$"..self.player:handCards():first()
		else
			return "."
		end
	end
	local function getLeastValueCard(from)
		if self:needToThrowArmor() then return "$"..self.player:getArmor():getEffectiveId() end
		local cards = sgs.QList2Table(self.player:getHandcards())
		cards = self:sortByKeepValue(cards)
		for _,c in ipairs(cards)do
			if self:getKeepValue(c)<8 and not self.player:isJilei(c) and not self:isValuableCard(c) then return "$"..c:getKnownEffectiveId() end
		end
		local offhorse_avail,weapon_avail
		for _,enemy in ipairs(self.enemies)do
			if self:canAttack(enemy,self.player) then
				if not offhorse_avail and self.player:getOffensiveHorse() and self.player:distanceTo(enemy, 1)<=self.player:getAttackRange() then
					offhorse_avail = true
				end
				if not weapon_avail and self.player:getWeapon() and self.player:distanceTo(enemy)==1 then
					weapon_avail = true
				end
			end
			if offhorse_avail and weapon_avail then break end
		end
		if offhorse_avail and not self.player:isJilei(self.player:getOffensiveHorse()) then return "$"..self.player:getOffensiveHorse():getEffectiveId() end
		if weapon_avail and not self.player:isJilei(self.player:getWeapon()) and self:evaluateWeapon(self.player:getWeapon())<self:evaluateWeapon(from:getWeapon()) then
			return "$"..self.player:getWeapon():getEffectiveId()
		end
	end
	if self:isFriend(use.from) then
		if use.from:hasSkills("kofxiaoji|xiaoji") and self:isWeak(use.from) then
			local str = getLeastValueCard(use.from)
			if str then return str end
		else
			if self:getCardsNum("Slash")==0 or self:willSkipPlayPhase() then return "." end
			local invoke = false
			local range = sgs.weapon_range[use.from:getWeapon():getClassName()] or 0
			if self.player:hasSkill("anjian") then
				for _,enemy in ipairs(self.enemies)do
					if not enemy:inMyAttackRange(self.player) and not self.player:inMyAttackRange(enemy) and self.player:distanceTo(enemy)<=range then
						invoke = true
						break
					end
				end
			end
			if not invoke and self:evaluateWeapon(use.from:getWeapon())>8 then invoke = true end
			if invoke then
				local str = getLeastValueCard(use.from)
				if str then return str end
			end
		end
	else
		if use.from:hasSkill("nosxuanfeng") then
			for _,friend in ipairs(self.friends)do
				if self:isWeak(friend) then return "." end
			end
		else
			if hasManjuanEffect(self.player) then
				if self:needToThrowArmor() and not self.player:isJilei(self.player:getArmor()) then
					return "$"..self.player:getArmor():getEffectiveId()
				elseif self.player:canDiscard(self.player,"h") and self:needToThrowLastHandcard()then
					return "$"..self.player:handCards():first()
				end
			else
				local str = getLeastValueCard(use.from)
				if str then return str end
			end
		end
	end
	return "."
end

--慎断
ai_skill_use["@@tenyearshenduan"] = function(self, prompt, request)
	for _,id in sgs.list(tag(self,"tenyearshenduanForAI","IntList"))do
		local ss = clone(self,"tenyearshenduan","tenyearshenduan","supply_shortage",sgs.Card_NoSuit,0,{id})
		if self.player:isCardLimited(ss,sgs.Card_MethodUse) then continue end
		local dummy_use = self:aiUseCard(ss)
		if dummy_use.card and dummy_use.to:length()>0 then
			return ss:getLegacyStringKey().."->"..dummy_use.to:first():objectName()
			--"@TenyearShenduanCard="..id.."->"..dummy_use.to:first():objectName()
		end
	end
	return "."
end

--勇略
ai_skill_invoke.tenyearyonglve = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local name = data:toString():split(":")[2]
	if not name then return (false) or false end
	local current = self.room:findPlayerByObjectName(name)
	if not current or current:isDead() then return (false) or false end
	local slash = clone(self,"tenyearyonglve","_tenyearyonglve","slash",sgs.Card_NoSuit,0,{})
	if self:isFriend(current) and self:doDisCard(current,"j") then
		if self.player:inMyAttackRange(current) then return (true) or false end
		if not self:slashIsEffective(slash,current,self.player) then return (true) or false end
		if not self:isWeak(current) or getKnownCard(current,self.player,"Jink")>0 then return (true) or false end
	elseif self:isEnemy(current)
	then
		if self:doDisCard(current,"j") then return (true) or false end
		for _,card in sgs.qlist(current:getJudgingArea())do
			if card:isKindOf("SupplyShortage") and (current:getHandcardNum()>4 or current:containsTrick("indulgence"))
			then
				save_override(self,"cardchosen","tenyearyonglve",card:getKnownEffectiveId())
				return (true) or false
			elseif card:isKindOf("Indulgence") and current:getHandcardNum()+self:ImitateResult_DrawNCards(current)<=self:getOverflow(current,true)
			then
				save_override(self,"cardchosen","tenyearyonglve",card:getKnownEffectiveId())
				return (true) or false
			end
		end
		if self.player:inMyAttackRange(current) and self.player:getHandcardNum()<3 then return (true) or false end
		if self:isWeak(current) and current:getHp()<2 and getCardsNum("Jink",current,self.player)<1
		and self:slashIsEffective(slash,current,self.player) then
			save_override(self,"cardchosen","tenyearyonglve",source_random_card(self,current,"j"))
			return (true) or false
		end
	end
	return false

end

--巧说
ai_fill_skill["tenyearqiaoshui"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		if c:getNumber()>9
		then
			return parse_policy(self,"@TenyearQiaoshuiCard=.")
		end
	end
end

ai_card_use["TenyearQiaoshuiCard"] = function(self, card, use, request)
	self.enemies = self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if self.player:canPindian(ep)
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.TenyearQiaoshuiCard = 3.4
sgs.ai_use_priority.TenyearQiaoshuiCard = 4.8

ai_skill_choice.tenyearqiaoshui = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local items = choices:split("+")
	local use = data:toCardUse()
	if table.contains(items,"add")
	then
		local d = {to=AIList.new({}),current_targets=use.to}
		self:aiUseCard(use.card,d)
		if d.card
		then
			write(self,"tenyearqiaoshui_to",{d.to:at(0)})
			if d.card:isKindOf("Collateral")
			then
				write(self,"tenyearqiaoshui_to",{d.to:at(0),d.to:at(1)})
			end
			return ai_choice_result(("add"), options)
		end
	end
	if table.contains(items,"remove")
	then
		if use.card:isKindOf("GlobalEffect")
		then
			for _,to in sgs.list(use.to)do
				if self:isEnemy(to)
				and self:hasTrickEffective(use.card,to,use.from)
				then
					write(self,"tenyearqiaoshui_to",{to})
					return ai_choice_result(("remove"), options)
				end
			end
		elseif use.card:isDamageCard()
		then
			for _,to in sgs.list(use.to)do
				if self:isFriend(to) and self:isWeak(to)
				and self:hasTrickEffective(use.card,to,use.from)
				then
					write(self,"tenyearqiaoshui_to",{to})
					return ai_choice_result(("remove"), options)
				end
			end
			for _,to in sgs.list(use.to)do
				if self:isFriend(to)
				and self:hasTrickEffective(use.card,to,use.from)
				then
					write(self,"tenyearqiaoshui_to",{to})
					return ai_choice_result(("remove"), options)
				end
			end
		end
	end
	return ai_choice_result(("cancel"), options)
end

ai_skill_use["@@tenyearqiaoshui1"] = function(self, prompt, request)
    local s = {}
	for _,to in sgs.list(read(self,"tenyearqiaoshui_to"))do
        table.insert(s,to:objectName())
    end
    if #s==0 then return "." end
    return "@TenyearQiaoshuiTargetCard=.->"..table.concat(s,"+")
end

ai_skill_use["@@tenyearqiaoshui2"] = function(self, prompt, request)
    local s = {}
	for _,to in sgs.list(read(self,"tenyearqiaoshui_to"))do
        table.insert(s,to:objectName())
    end
    if #s==0 then return "." end
    return "@ExtraCollateralCard=.->"..table.concat(s,"+")
end

--傲才
sgs.ai_guhuo_card.tenyearaocai = function(self,toname,class_name)
    return "@TenyearAocaiCard=.:"..toname
end

ai_skill_invoke.tenyearaocai = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (ai_skill_invoke.aocai(self, options, request)) or false
end

ai_skill_use["@@tenyearaocai"] = function(self, prompt, request)
    local c = self.player:getStrategyMark("tenyearaocaiId")
	c = known_card(self,c)
    local dummy = self:aiUseCard(c)
   	if dummy.card then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return c:getLegacyStringKey().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_askforag.tenyearaocai = function(self,card_ids)
	local pattern = known(self:getCurrentCardUsePattern(),"current pattern")
	if pattern~="" then return card_ids[1] end
    for _,id in sgs.list(card_ids)do
		local c = known_card(self,id)
		if self:aiUseCard(c).card
		then return id end
	end
end

--黩武

ai_fill_skill["tenyearduwu"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if #self.enemies==0 then return end
	return parse_policy(self,"@TenyearDuwuCard=.")
end

ai_card_use.TenyearDuwuCard = function(self, card, use, request)
	local cmp = function(a,b)
		if a:getHp()<b:getHp() then
			if a:getHp()==1 and b:getHp()==2 then return false else return true end
		end
		return false
	end
	local enemies = {}
	for _,enemy in ipairs(self.enemies)do
		if self:canAttack(enemy,self.player) and self.player:inMyAttackRange(enemy) then table.insert(enemies,enemy) end
	end
	if #enemies==0 then return end
	table.sort(enemies,cmp)
	if enemies[1]:getHp()<=0 then
		use.card = parse_policy(self,"@TenyearDuwuCard=.")
		use.to:append(enemies[1])
		return
	end

	-- find cards
	local card_ids = {}
	if self:needToThrowArmor() then table.insert(card_ids,self.player:getArmor():getEffectiveId()) end

	local zcards = self.player:getHandcards()
	local use_slash,keep_jink,keep_analeptic = false,false,false
	for _,zcard in sgs.qlist(zcards)do
		if not isCard("Peach",zcard,self.player) and not isCard("ExNihilo",zcard,self.player) then
			local shouldUse = true
			if zcard:getTypeId()==sgs.Card_TypeTrick then
				local dummy_use = dummy_plan()
				self:useTrickCard(zcard,dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if zcard:getTypeId()==sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
				local dummy_use = dummy_plan()
				self:useEquipCard(zcard,dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if isCard("Jink",zcard,self.player) and not keep_jink then
				keep_jink = true
				shouldUse = false
			end
			if self.player:getHp()==1 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
				keep_analeptic = true
				shouldUse = false
			end
			if shouldUse then table.insert(card_ids,zcard:getId()) end
		end
	end
	local hc_num = #card_ids
	local eq_num = 0
	if self.player:getOffensiveHorse() then
		table.insert(card_ids,self.player:getOffensiveHorse():getEffectiveId())
		eq_num = eq_num+1
	end
	if self.player:getWeapon() and self:evaluateWeapon(self.player:getWeapon())<5 then
		table.insert(card_ids,self.player:getWeapon():getEffectiveId())
		eq_num = eq_num+2
	end

	local function getRangefix(index)
		if index<=hc_num then return 0
		elseif index==hc_num+1 then
			if eq_num==2 then
				return sgs.weapon_range[self.player:getWeapon():getClassName()]-self.player:getAttackRange(false)
			else
				return 1
			end
		elseif index==hc_num+2 then
			return sgs.weapon_range[self.player:getWeapon():getClassName()]
		end
	end

	for _,enemy in ipairs(enemies)do
		if enemy:getHp()>#card_ids then continue end
		if enemy:getHp()<=0
		and self:damageIsEffective(enemy,card)
		then
			use.card = parse_policy(self,"@TenyearDuwuCard=.")
			use.to:append(enemy)
			return
		elseif enemy:getHp()>1
		then
			local hp_ids = {}
			if self.player:distanceTo(enemy, getRangefix(enemy:getHp()))<=self.player:getAttackRange()
			and self:damageIsEffective(enemy,card)
			then
				for _,id in ipairs(card_ids)do
					table.insert(hp_ids,id)
					if #hp_ids==enemy:getHp() then break end
				end
				use.card = parse_policy(self,"@TenyearDuwuCard="..table.concat(hp_ids,"+"))
				use.to:append(enemy)
				return
			end
		else
			if not self:isWeak() or self:getSaveNum(true)>=1
			and self:damageIsEffective(enemy,card)
			and self.player:distanceTo(enemy, getRangefix(1))<=self.player:getAttackRange()
			then
				use.card = parse_policy(self,"@TenyearDuwuCard="..card_ids[1])
				use.to:append(enemy)
				return
			end
		end
	end
end

sgs.ai_use_priority.TenyearDuwuCard = sgs.ai_use_priority.DuwuCard
sgs.ai_use_priority.TenyearDuwuCard = sgs.ai_use_value.DuwuCard
sgs.dynamic_value.damage_card.TenyearDuwuCard = sgs.dynamic_value.damage_card.DuwuCard
sgs.ai_card_intention.TenyearDuwuCard = sgs.ai_card_intention.DuwuCard

--啖酪
ai_skill_invoke.tenyeardanlao = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (ai_skill_invoke.danlao(self, options, request)) or false
end

--鸡肋
ai_skill_invoke.tenyearjilei = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (ai_skill_invoke.jilei(self, options, request)) or false
end

ai_skill_choice.tenyearjilei = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	return ai_choice_result((ai_skill_choice.jilei(self,{reason="jilei",choices=options and options.choices or (choices~=nil and {} or nil),inquiry_scope="nested"},nil)), options)
end

--陷阵

ai_fill_skill["tenyearxianzhen"] = function(self, options, request)
    local inclusive = options and options.inclusive

	return parse_policy(self,"@TenyearXianzhenCard=.")
end

ai_card_use.TenyearXianzhenCard = function(self, card, use, request)
	self.enemies = self:sort(self.enemies,"handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount-1 end

	if slashcount>0  then
		for _,enemy in ipairs(self.enemies)do
			if enemy:getStrategyFlag("AI_HuangtianPindian") and enemy:getHandcardNum()==1 and self.player:canPindian(enemy) then
				self:remember("tenyearxianzhen_card",max_card:getId())
				use.card = card
				use.to:append(enemy)
				self:setStrategyPlayerFlag(enemy,"AI_HuangtianPindian",false)
				return
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) and self:canAttack(enemy,self.player)
				and not self:canLiuli(enemy,self.friends_noself) and not self:findLeijiTarget(enemy,50,self.player) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point =enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point>enemy_max_point then
					self:remember("tenyearxianzhen_card",max_card:getId())
					use.card = card
					use.to:append(enemy)
					return
				end
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) and self:canAttack(enemy,self.player)
				and not self:canLiuli(enemy,self.friends_noself) and not self:findLeijiTarget(enemy,50,self.player) then
				if max_point>=10 then
					self:remember("tenyearxianzhen_card",max_card:getId())
					use.card = card
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
				self:remember("tenyearxianzhen_card",cards[1]:getId())
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end
end

sgs.ai_cardneed.tenyearxianzhen = function(to,card,self)
	return sgs.ai_cardneed.xianzhen(to,card,self)
end

function sgs.ai_skill_pindian.tenyearxianzhen(minusecard,self,requestor)
	return sgs.ai_skill_pindian.xianzhen(minusecard,self,requestor)
end

sgs.ai_skill_playerchosen.tenyearxianzhen = function(self,targets)
	set_used_data(self)
	return sgs.ai_skill_playerchosen.yb_zhuzhan2(self,targets)
end

sgs.ai_card_intention.TenyearXianzhenCard = sgs.ai_card_intention.XianzhenCard
sgs.dynamic_value.control_card.TenyearXianzhenCard = sgs.dynamic_value.control_card.XianzhenCard
sgs.ai_use_value.TenyearXianzhenCard = sgs.ai_use_value.XianzhenCard
sgs.ai_use_priority.TenyearXianzhenCard = sgs.ai_use_priority.XianzhenCard

--陷阵
ai_fill_skill.secondtenyearxianzhen = function(self, options, request)
    local inclusive = options and options.inclusive

	return parse_policy(self,"@SecondTenyearXianzhenCard=.")
end

ai_card_use.SecondTenyearXianzhenCard = function(self, card, use, request)
	self.enemies = self:sort(self.enemies,"handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount-1 end

	if slashcount>0  then
		for _,enemy in ipairs(self.enemies)do
			if enemy:getStrategyFlag("AI_HuangtianPindian") and enemy:getHandcardNum()==1 and self.player:canPindian(enemy) then
				self:remember("secondtenyearxianzhen_card",max_card:getId())
				use.card = card
				use.to:append(enemy)
				self:setStrategyPlayerFlag(enemy,"AI_HuangtianPindian",false)
				return
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1)
			and self.player:canPindian(enemy) and self:canAttack(enemy,self.player)
			and not self:canLiuli(enemy,self.friends_noself)
			and not self:findLeijiTarget(enemy,50,self.player) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point =enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point>enemy_max_point then
					self:remember("secondtenyearxianzhen_card",max_card:getId())
					use.card = card
					use.to:append(enemy)
					return
				end
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1)
			and self.player:canPindian(enemy) and self:canAttack(enemy,self.player)
			and not self:canLiuli(enemy,self.friends_noself)
			and not self:findLeijiTarget(enemy,50,self.player) then
				if max_point>=10 then
					self:remember("secondtenyearxianzhen_card",max_card:getId())
					use.card = card
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
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1)
			and self.player:canPindian(enemy) and not hasTuntianEffect(enemy, true) then
				self:remember("secondtenyearxianzhen_card",cards[1]:getId())
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end
end

sgs.ai_card_intention.SecondTenyearXianzhenCard = sgs.ai_card_intention.XianzhenCard
sgs.dynamic_value.control_card.SecondTenyearXianzhenCard = sgs.dynamic_value.control_card.XianzhenCard
sgs.ai_use_value.SecondTenyearXianzhenCard = sgs.ai_use_value.XianzhenCard
sgs.ai_use_priority.SecondTenyearXianzhenCard = sgs.ai_use_priority.XianzhenCard

--避乱
sgs.ai_skill_cardask["@tenyearbiluan-discard"] = function(self,data)
	local to_discard = self:askForDiscard("tenyearbiluan",1,1,false,true)
	if #to_discard>0 then return "$"..to_discard[1] else return "." end
end

function sgs.ai_cardneed.tenyearbiluan(to,card)
	return to:getCardCount()<=2
end

--礼下
ai_skill_choice.tenyearlixia = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	local player = data:toPlayer()
	if not player or player:isDead() then return ai_choice_result(("self"), options) end
	if self:isFriend(player) and self:canDraw(player) then return ai_choice_result(("other"), options) end
	if not self:isFriend(player) and self:canDraw() then return ai_choice_result(("self"), options) end
	if self:isFriend(player) and not self:canDraw(player) then
		if self:canDraw() then return ai_choice_result(("self"), options) end
		return ai_choice_result(("other"), options)
	end
	return ai_choice_result(("self"), options)
end

--自守
ai_skill_invoke.tenyearzishou = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (ai_skill_invoke.noszishou(self, options, request)) or false
end

ai_skill_use["@@tenyearzishou"] = function(self, prompt, request)
	local method = request and request.handling_method
	local cards = sgs.QList2Table(self.player:getCards("h"))
	cards = self:sortByKeepValue(cards)

	local heart,diamond,club,spade = {},{},{},{}
	for _,c in ipairs(cards)do
		if not self.player:canDiscard(self.player,c:getKnownEffectiveId()) or self:isValuableCard(c,self.player) then continue end
		if c:getSuit()==sgs.Card_Heart then
			table.insert(heart,c:getKnownEffectiveId())
		elseif c:getSuit()==sgs.Card_Diamond then
			table.insert(diamond,c:getKnownEffectiveId())
		elseif c:getSuit()==sgs.Card_Club then
			table.insert(club,c:getKnownEffectiveId())
		elseif c:getSuit()==sgs.Card_Spade then
			table.insert(spade,c:getKnownEffectiveId())
		end
	end

	local dis = {}
	if #heart>0 then table.insert(dis,heart[1]) end
	if #diamond>0 then table.insert(dis,diamond[1]) end
	if #club>0 then table.insert(dis,club[1]) end
	if #spade>0 then table.insert(dis,spade[1]) end
	if #dis>0 then return "@TenyearZishouCard="..table.concat(dis,"+") end
	return "."
end

sgs.ai_target_revises.tenyearzongshi = function(to,card)
    if to:getHandcardNum()>=to:getMaxCards()
	then
		if card:isKindOf("DelayedTrick")
		then return true
		elseif card:isRed()
    	or card:isBlack()
		then return end
		return true
	end
end

--旋风
ai_skill_invoke.tenyearxuanfeng = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (ai_skill_invoke.xuanfeng(self, options, request)) or false
end

sgs.ai_skill_playerchosen.tenyearxuanfeng = function(self,targets)
	return sgs.ai_skill_playerchosen.xuanfeng(self,targets)
end

sgs.ai_skill_cardchosen.tenyearxuanfeng = function(self,who,flags)
	return sgs.ai_skill_cardchosen.xuanfeng(self,who,flags)
end

sgs.ai_skill_playerchosen.tenyearxuanfeng_damage = function(self,targets)
	return self:findPlayerToDamage(1,self.player,"N",targets)[1]
end

sgs.tenyearxuanfeng_keep_value = sgs.xuanfeng_keep_value
sgs.ai_cardneed.tenyearxuanfeng = sgs.ai_cardneed.xuanfeng

--勇进

ai_fill_skill["tenyearyongjin"] = function(self, options, request)
    local inclusive = options and options.inclusive

	return parse_policy(self,"@TenyearyongjinCard=.")
end

ai_card_use.TenyearyongjinCard = function(self, card, use, request)
	local from,card,to = self:moveField(nil,"e")
	if from and card and to then
		use.card = parse_policy(self,"@TenyearyongjinCard=.")
	end
end

sgs.ai_use_priority.TenyearyongjinCard = 50

sgs.ai_skill_playerchosen.tenyearyongjin_from = function(self,targets)
	local from,card,to = self:moveField(nil,"e")
	if from then return from end
end

sgs.ai_skill_cardchosen.tenyearyongjin = function(self,who,flags)
	local from,card,to = self:moveField(nil,"e")
	if card then return card:getId() end
end

sgs.ai_skill_playerchosen.tenyearyongjin_to = function(self,targets)
	local from,card,to = self:moveField(nil,"e")
	if to then return to end
end

--恩怨
ai_skill_invoke.tenyearenyuan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (ai_skill_invoke.enyuan(self, options, request)) or false
end

sgs.ai_choicemade_filter.skillInvoke.tenyearenyuan = function(self,player,promptlist)
	local invoked = (promptlist[3]=="yes")
	local intention = 0

	local EnyuanDrawTarget
	for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
		if p:getStrategyFlag("TenyearEnyuanDrawTarget") then EnyuanDrawTarget = p break end
	end

	if EnyuanDrawTarget then
		if not invoked and not self:needKongcheng(EnyuanDrawTarget,true) then
			intention = 10
		elseif not self:needKongcheng(from,true) then
			intention = -10
		end
		self:updateIntention(player,EnyuanDrawTarget,intention)
	else
		local damage = current_damage(self)
		if damage.from then
			if not invoked then
				intention = -10
			elseif self:needToLoseHp(damage.from,player,nil,true) then
				intention = 0
			elseif not self:hasLoseHandcardEffective(damage.from) and not damage.from:isKongcheng() then
				intention = 0
			elseif self:getOverflow(damage.from)<=2 then
				intention = 10
			end
			self:updateIntention(player,damage.from,intention)
		end
	end
end

sgs.ai_skill_discard.tenyearenyuan = function(self,discard_num,min_num,optional,include_equip)
	if hasZhaxiangEffect(self.player) and (self.player:getHp()>1 or hasBuquEffect(self.player) or self:getSaveNum(true)>=1) then return {} end

	local damage = tag(self,"tenyearenyuan_data","Damage")
	if not damage then return {} end
	local fazheng = damage.to
    if not fazheng then return {} end
    local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	if self:needToLoseHp(self.player,fazheng,damage.card,true) and not self:hasSkills(sgs.masochism_skill) then return {} end

	if self:isFriend(fazheng) then
		for _,card in ipairs(cards)do
			if card:getSuit()~=sgs.Card_Heart and self:canDraw(fazheng) and isCard("Peach",card,fazheng) and
			((not self:isWeak() and self:getCardsNum("Peach")>0) or self:getCardsNum("Peach")>1) then
				table.insert(to_discard,card:getKnownEffectiveId())
				return to_discard
			end
			if card:getSuit()~=sgs.Card_Heart and self:canDraw(fazheng) and isCard("Analeptic",card,fazheng) and self:getCardsNum("Analeptic")>1 then
				table.insert(to_discard,card:getKnownEffectiveId())
				return to_discard
			end
			if card:getSuit()~=sgs.Card_Heart and self:canDraw(fazheng) and isCard("Jink",card,fazheng) and self:getCardsNum("Jink")>1 then
				table.insert(to_discard,card:getKnownEffectiveId())
				return to_discard
			end

			if isCard("Peach",card,fazheng) and ((not self:isWeak() and self:getCardsNum("Peach")>0) or self:getCardsNum("Peach")>1) then
				table.insert(to_discard,card:getKnownEffectiveId())
				return to_discard
			end
			if isCard("Analeptic",card,fazheng) and self:getCardsNum("Analeptic")>1 then
				table.insert(to_discard,card:getKnownEffectiveId())
				return to_discard
			end
			if isCard("Jink",card,fazheng) and self:getCardsNum("Jink")>1 then
				table.insert(to_discard,card:getKnownEffectiveId())
				return to_discard
			end
		end
	end

	if self:needToLoseHp() and not self:hasSkills(sgs.masochism_skill) then return {} end
	cards = self:sortByKeepValue(cards)
	for _,card in ipairs(cards)do
		if not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and card:getSuit()==sgs.Card_Heart then
			table.insert(to_discard,card:getKnownEffectiveId())
			return to_discard
		end
	end
	for _,card in ipairs(cards)do
		if not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) then
			table.insert(to_discard,card:getKnownEffectiveId())
			return to_discard
		end
	end
	return {}
end

--眩惑
ai_skill_use["@@tenyearxuanhuo"] = function(self, prompt, request)
	local valid,to = {},nil
    for _,p in sgs.list(self.player:getAliveSiblings())do
      	if not self:isFriend(p) and self:isWeak(p)
    	then to = p break end
	end
    for _,p in sgs.list(self.player:getAliveSiblings())do
      	if self:isEnemy(p) and self:isWeak(p)
    	then to = p break end
	end
    for _,p in sgs.list(self.player:getAliveSiblings())do
      	if self:isFriend(p) then to = p break end
	end
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    cards = self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if #valid>1 or #cards<3 or to==nil then break end
        table.insert(valid,h:getKnownEffectiveId())
	end
	if #valid<2 or #self.enemies<1 then return end
	return ("@TenyearXuanhuoCard="..table.concat(valid,"+").."->"..to:objectName())
end

sgs.ai_skill_playerchosen.tenyearxuanhuo = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
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

ai_skill_choice.tenyearxuanhuo = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local items = choices:split("+")
    for _,item in sgs.list(items)do
		if item~="duel" then return ai_choice_result((item), options) end
	end

    return ai_choice_result(nil, options)
end

--惴恐
ai_skill_invoke.tenyearzhuikong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self.player:getHandcardNum()<=(self:isWeak() and 2 or 1) then return (false) or false end
	local current = self.room:getCurrent()
	if not current or self:isFriend(current) then return (false) or false end

	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	if self.player:hasSkill("yingyang") then max_point = math.min(max_point+3,13) end
	if not (current:hasSkill("zhiji") and current:getStrategyMark("zhiji")==0 and current:getHandcardNum()==1) and not
		(current:hasSkill("mobilezhiji") and current:getStrategyMark("mobilezhiji")==0 and current:getHandcardNum()==1) then
		local enemy_max_card = self:getMaxCard(current)
		local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
		if enemy_max_card and current:hasSkill("yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
		if max_point>enemy_max_point or max_point>10 then
			self:remember("tenyearzhuikong_card",max_card:getKnownEffectiveId())
			return (true) or false
		end
	end
	if current:distanceTo(self.player)==1 and not self:isValuableCard(max_card) then
		self:remember("tenyearzhuikong_card",max_card:getKnownEffectiveId())
		return (true) or false
	end
	return (false) or false
end

--求援
sgs.ai_skill_playerchosen.tenyearqiuyuan = function(self,targets)
	return sgs.ai_skill_playerchosen.qiuyuan(self,targets)
end

sgs.ai_skill_cardask["@tenyearqiuyuan-give"] = function(self,data,pattern,target)
	local give = true
	local huanghou = tag(self,"tenyearqiuyuan_from","Player")
	if not huanghou or huanghou:isDead() then return "." end
	if self:isEnemy(huanghou) then
		if not (self:needKongcheng() and self.player:getHandcardNum()==1) then
			give = false
		end
	elseif self:isFriend(huanghou) then
		if not self:isWeak(huanghou) and self:hasSkills("leiji|nosleiji") then
			give = false
		end
	end
	if give==true then
		local cards = sgs.QList2Table(self.player:getHandcards())
		cards = self:sortByKeepValue(cards)
		for _,card in ipairs(cards)do
			if card:isKindOf("BasicCard") and not card:isKindOf("Slash") then
				return "$"..card:getKnownEffectiveId()
			end
		end
	end
	return "."
end

--司敌
sgs.ai_skill_cardask["@tenyearsidi-put"] = function(self,data,pattern,target)
	local all = sgs.QList2Table(self.player:getCards("he"))
	local cards = {}
	for _,c in ipairs(all)do
		if c:isKindOf("BasicCard") or self:isValuableCard(c) then continue end
		table.insert(cards,c)
	end
	if #cards==0 then return "." end
	cards = self:sortByKeepValue(cards)
	return cards[1]:getLegacyStringKey()
end

ai_skill_use["@@tenyearsidi"] = function(self, prompt, request)
	local name = prompt:split(":")[2]
	if not name then return "." end
	local player = self.room:findPlayerByObjectName(name)
	if not player or player:isDead() or not self:isEnemy(player) then return "." end
	for _,id in sgs.qlist(self.player:getPile("sidi"))do
		if known_card(self,id):isBlack() then
			return "@TenyearSidiCard="..id
		end
	end
	return "@TenyearSidiCard="..self.player:getPile("sidi"):first()
end

sgs.ai_card_intention.TenyearSidiCard = 50

--怀异

ai_fill_skill["tenyearhuaiyi"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:isKongcheng() then return nil end
	return parse_policy(self,"@TenyearHuaiyiCard=.")
end

ai_card_use.TenyearHuaiyiCard = function(self, card, use, request)
    local handcards = self.player:getHandcards()
    local reds,blacks = {},{}
    for _,c in sgs.qlist(handcards)do
		local dummy_use = dummy_plan()
        if c:isKindOf("BasicCard") then
            self:useBasicCard(c,dummy_use)
        elseif c:isKindOf("EquipCard") then
            self:useEquipCard(c,dummy_use)
        elseif c:isKindOf("TrickCard") then
            self:useTrickCard(c,dummy_use)
        end
        if dummy_use.card then
            return --It seems that self.player should use this card first.
        end
        if c:isRed() then
            table.insert(reds,c)
        else
            table.insert(blacks,c)
        end
    end

    local targets = self:findPlayerToDiscard("he",false,false)
    local n_reds,n_blacks,n_targets = #reds,#blacks,#targets

	if n_reds==0 or n_blacks==0 then
		use.card = card
	end

    if n_targets==0 then
        return
    elseif n_reds-n_targets>=2 and n_blacks-n_targets>=2 and handcards:length()-n_targets>=5 then
        return
    end
    use.card = card
end

ai_skill_choice.tenyearhuaiyi = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

    return ai_choice_result((ai_skill_choice.huaiyi(self,{reason="huaiyi",choices=options and options.choices or (choices~=nil and {} or nil),inquiry_scope="nested"},request)), options)
end

ai_skill_use["@@tenyearhuaiyi"] = function(self, prompt, request)
    local method = request and request.handling_method
    local n = self.player:getStrategyMark("tenyearhuaiyi_num-PlayClear")
    if n>=2 then
        if self:needToLoseHp() then
        elseif self:isWeak() then
            n = 1
        end
    end
    if n==0 then
        return "."
    end
    local targets = self:findPlayerToDiscard("he",false,false)
    local names = {}
    for index,target in ipairs(targets)do
        if index<=n then
            table.insert(names,target:objectName())
        else
            break
        end
    end
    return "@TenyearHuaiyiSnatchCard=.->"..table.concat(names,"+")
end

--绝情
ai_skill_invoke.tenyearjueqing = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = tag(self,"tenyearjueqing_data","Damage")
	if not damage or damage.to:isDead() or self:isFriend(damage.to) then return (false) or false end
	if self:cantDamageMore(self.player,damage.to) then return (false) or false end
	local n = damage.damage-self.player:getHp()
        if n<0 or hasBuquEffect(self.player) or self:getSaveNum(true)>=n then return (true) or false end
	return (false) or false
end

--弓骑

ai_fill_skill["tenyeargongqi"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self:needBear() then return end
	if #self.enemies==0 then return end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	if self:needToThrowArmor() then
		return parse_policy(self,"@TenyearGongqiCard="..self.player:getArmor():getEffectiveId())
	end

	for _,c in ipairs(cards)do
		if c:isKindOf("Weapon") then return parse_policy(self,"@TenyearGongqiCard="..c:getKnownEffectiveId()) end
	end

	local handcards = self.player:getHandcards()
	handcards = sgs.QList2Table(handcards)
	local has_weapon,has_armor,has_def,has_off = false,false,false,false
	local weapon,armor
	for _,c in ipairs(handcards)do
		if c:isKindOf("Weapon") then
			has_weapon = true
			if not weapon or self:evaluateWeapon(weapon)<self:evaluateWeapon(c) then weapon = c end
		end
		if c:isKindOf("Armor") then
			has_armor = true
			if not armor or self:evaluateArmor(armor)<self:evaluateArmor(c) then armor = c end
		end
		if c:isKindOf("DefensiveHorse") then has_def = true end
		if c:isKindOf("OffensiveHorse") then has_off = true end
	end
	if has_off and self.player:getOffensiveHorse() then return parse_policy(self,"@TenyearGongqiCard="..self.player:getOffensiveHorse():getEffectiveId()) end
	if has_def and self.player:getDefensiveHorse() then return parse_policy(self,"@TenyearGongqiCard="..self.player:getDefensiveHorse():getEffectiveId()) end
	if has_weapon and self.player:getWeapon() and self:evaluateWeapon(self.player:getWeapon())<=self:evaluateWeapon(weapon) then
		return parse_policy(self,"@TenyearGongqiCard="..self.player:getWeapon():getEffectiveId())
	end
	if has_armor and self.player:getArmor() and self:evaluateArmor(self.player:getArmor())<=self:evaluateArmor(armor) then
		return parse_policy(self,"@TenyearGongqiCard="..self.player:getArmor():getEffectiveId())
	end

	if self:getOverflow()>0 and self:getCardsNum("Slash")>=1 then
		handcards = self:sortByKeepValue(handcards)
		self.enemies = self:sort(self.enemies,"defense")
		for _,c in ipairs(handcards)do
			if c:isKindOf("Snatch") or c:isKindOf("Dismantlement") then
				local use = dummy_plan()
				self:useCardSnatch(c,use)
				if use.card then return end
			elseif isCard("Peach",c,self.player)
				or isCard("ExNihilo",c,self.player)
				or (isCard("Analeptic",c,self.player) and self.player:getHp()<=2)
				or (isCard("Jink",c,self.player) and self:getCardsNum("Jink")<2)
				or (isCard("Nullification",c,self.player) and self:getCardsNum("Nullification")<2)
				or (isCard("Slash",c,self.player) and self:getCardsNum("Slash")==1) then
			elseif not c:isKindOf("EquipCard") and #self.enemies>0 and self.player:inMyAttackRange(self.enemies[1]) then
			else
				return parse_policy(self,"@TenyearGongqiCard="..c:getKnownEffectiveId())
			end
		end
	end
end

ai_card_use.TenyearGongqiCard = function(self, card, use, request)
	local id = card:getSubcards():first()
	local subcard = known_card(self,id)
	if subcard:isKindOf("SilverLion") and self.room:getCardPlace(id)==sgs.Player_PlaceHand and self:isWounded() and self.player:canUse(subcard) then
		use.card = subcard
		return
	end
	use.card = card
end

sgs.ai_skill_playerchosen.tenyeargongqi = function(self,targets)
	local player = self:findPlayerToDiscard()[1]
	return player
end

sgs.ai_use_value.TenyearGongqiCard = sgs.ai_use_value.GongqiCard
sgs.ai_use_priority.TenyearGongqiCard = sgs.ai_use_priority.GongqiCard

--解烦

ai_fill_skill["tenyearjiefan"] = function(self, options, request)
    local inclusive = options and options.inclusive

	return parse_policy(self,"@TenyearJiefanCard=.")
end

ai_card_use.TenyearJiefanCard = function(self, card, use, request)
	local target
	local use_value = 0
	local max_value = -10000
	local p_count = 0
	for _,friend in ipairs(self.friends)do
		use_value = 0
		local count = 0
		for _,p in sgs.qlist(self.room:getOtherPlayers(friend))do
			if p:inMyAttackRange(friend) then
				count = count+1
				if self:isFriend(p) then
					if not friend:hasSkill("manjuan") then use_value = use_value+1 end
				else
					if p:getWeapon() then
						use_value = use_value+1.2
					else
						if not friend:hasSkill("manjuan") then use_value = use_value+p:getHandcardNum()/5 end
					end
				end
			end
		end
		if friend:objectName()==self.player:objectName() then p_count = count end
		use_value = use_value-friend:getHandcardNum()/2
		if use_value>max_value then
			max_value = use_value
			target = friend
		end
	end

	if (target and max_value>=self.player:aliveCount()/2) or self.room:getTurnCount()==1 then
		use.card = card
		use.to:append(target)
		return
	end

	if (self:isWeak() and p_count>0) or self.room:getTurnCount()==1 then
		use.card = card
		use.to:append(self.player)
		return
	end
end

sgs.ai_card_intention.TenyearJiefanCard = sgs.ai_card_intention.JiefanCard

function sgs.ai_cardneed.tenyearjiefan(to,card,self)
	return sgs.ai_cardneed.jiefan(to,card,self)
end

--忠勇
sgs.ai_skill_playerchosen.tenyearzhongyong = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

--急攻
ai_skill_invoke.tenyearjigong = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

ai_skill_choice.tenyearjigong = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	return ai_choice_result((""..math.random(2,3)), options)
end



--竭忠
ai_skill_invoke.tenyearjiezhong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw() and self.player:getHp()-self.player:getHandcardNum()>1) or false
end

--龙吟
sgs.ai_skill_cardask["@tenyearlongyin"] = function(self,data)
	return sgs.ai_skill_cardask["@longyin"](self,data)
end

--二版镇军
sgs.ai_skill_playerchosen.secondtenyearzhenjun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
		local n = math.max(target:getHandcardNum()-target:getHp(),1)
		if self:isEnemy(target)
		and n<=target:getEquips():length()
		then return target end
	end
	local n = math.max(self.player:getHandcardNum()-self.player:getHp(),1)
	destlist = self:askForDiscard("secondtenyearzhenjun",n,n)
    for c,id in sgs.list(destlist)do
		c = known_card(self,id)
		if c:isKindOf("EquipCard")
		or self:getUseValue(c)>5
		then return end
	end
	return self.player
end


--二版精策
ai_skill_invoke.secondtenyearjingce = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

ai_skill_choice.secondtenyearjingce = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local items = choices:split("+")
	if table.contains(items,"draw")
	and self.player:getHandcardNum()<2
	then return ai_choice_result(("draw"), options) end
	if table.contains(items,"play")
	then return ai_choice_result(("play"), options) end

    return ai_choice_result(nil, options)
end

--二版将驰
ai_skill_invoke.secondtenyearjiangchi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (true) or false
end

ai_skill_choice.secondtenyearjingce = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local items = choices:split("+")
	if table.contains(items,"two")
	and self:getCardsNum("Slash")<1
	then return ai_choice_result(("two"), options) end
	if self:getCardsNum("Slash")>1
	and items[3]
	then
		for _,ep in sgs.list(self.enemies)do
			if self.player:canSlash(ep)
			then
				return ai_choice_result((items[3]), options)
			end
		end
	end
	if table.contains(items,"one")
	then return ai_choice_result(("one"), options) end

    return ai_choice_result(nil, options)
end


ai_skill_invoke.tenyearqieting = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local items = data:toString():split(":")
    local target = self.room:findPlayerByObjectName(items[2])
	if target then return (not self:isFriend(target)) or false end
	return false

end

ai_fill_skill["tenyearxianzhou"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getEquips():length()>#self.enemies/2
	then
		return parse_policy(self,"@TenyearXianzhouCard=.")
	end
end

ai_card_use["TenyearXianzhouCard"] = function(self, card, use, request)
	self.enemies = self:sort(self.enemies,"hp")
	local x = self.player:getEquips():length()
	for _,fp in sgs.list(self.friends_noself)do
		local n = 0
		for _,ep in sgs.list(self.enemies)do
			if fp:inMyAttackRange(ep)
			and self:isWeak(ep)
			then n = n+1 end
		end
		if #self.enemies/2<=n
		and n<=x
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
	for _,fp in sgs.list(self.friends_noself)do
		local n = 0
		for _,ep in sgs.list(self.enemies)do
			if fp:inMyAttackRange(ep)
			then n = n+1 end
		end
		if #self.enemies/2<=n
		and n<=x
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
end

sgs.ai_use_value.TenyearXianzhouCard = 9.4
sgs.ai_use_priority.TenyearXianzhouCard = -4.8

ai_skill_use["@@tenyearxianzhou"] = function(self, prompt, request)
	local valid = {}
	local destlist = self.room:getOtherPlayers(self.player)
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
    destlist = self:sort(destlist,"hp")
    local target = property(self,"tenyearxianzhou_target")
	target = self.room:findPlayerByObjectName(target)
	for _,friend in sgs.list(destlist)do
		if self:isEnemy(friend)
		and target:inMyAttackRange(friend)
		and #valid<self.player:getStrategyMark("tenyearxianzhou")
		then table.insert(valid,friend:objectName()) end
	end
	for _,friend in sgs.list(destlist)do
		if not self:isFriend(friend)
		and target:inMyAttackRange(friend)
		and #valid<self.player:getStrategyMark("tenyearxianzhou")
		and not table.contains(valid,friend:objectName())
		then table.insert(valid,friend:objectName()) end
	end
	if #valid>0
	then
    	return ("@TenyearXianzhouDamageCard=.->"..table.concat(valid,"+"))
	end
end

ai_fill_skill["tenyearshenxing"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
	local n = math.min(2,self.player:usedTimes("TenyearShenxingCard"))
	local toids = {}
  	for _,c in sgs.list(cards)do
		if #toids>=n then break end
		if table.contains(self:getPriorTurnUseCards(),c)
		then continue end
		if self:getKeepValue(c)<3
		then table.insert(toids,c:getKnownEffectiveId()) end
	end
	local ids = #toids>0 and table.concat(toids,"+") or "."
	if #toids>=n then return parse_policy(self,"@TenyearShenxingCard="..ids) end
end

ai_card_use["TenyearShenxingCard"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.TenyearShenxingCard = 4.4
sgs.ai_use_priority.TenyearShenxingCard = 2.8

ai_skill_use["@@tenyearbingyi"] = function(self, prompt, request)
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
	return ("@TenyearBingyiCard=.->"..table.concat(valid,"+"))
end

sgs.ai_skill_playerchosen.tenyearzongxuan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

ai_skill_use["@@tenyearzongxuan"] = function(self, prompt, request)
	local zx_help = tag(self,"tenyearzongxuanForAI","IntList")
	local n1,n2 = {},{}
	for c,id in sgs.list(zx_help)do
		table.insert(n1,known_card(self,id))
	end
	n1 = self:sortByKeepValue(n1,true)
	local poisons = self:poisonCards(n1)
   	local target = self.room:getCurrent()
	target = target:getNextAlive()
	for _,c in sgs.list(n1)do
		if self:isFriend(target)
		and table.contains(poisons,c)
		then continue end
		table.insert(n2,c:getKnownEffectiveId())
	end
	return #n2>0 and ("@TenyearZongxuanCard="..table.concat(n2,"+"))
end

ai_skill_use["@@tenyearzongxuan!"] = function(self, prompt, request)
	local zx_help = tag(self,"tenyearzongxuanForAI","IntList")
	local n1,n2 = {},{}
	for c,id in sgs.list(zx_help)do
		table.insert(n1,known_card(self,id))
	end
	n1 = self:sortByKeepValue(n1,true)
	local poisons = self:poisonCards(n1)
   	local target = self.room:getCurrent()
	target = target:getNextAlive()
	for _,c in sgs.list(n1)do
		if self:isFriend(target)
		and table.contains(poisons,c)
		then continue end
		table.insert(n2,c:getKnownEffectiveId())
	end
	return #n2>0 and ("@TenyearZongxuanCard="..table.concat(n2,"+"))
end

sgs.ai_skill_playerchosen.tenyearzhiyan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

ai_skill_invoke.tenyearqiaoshi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target
	then
		return (not self:isEnemy(target)) or false
	end
	return false

end

sgs.ai_skill_playerchosen.tenyearyjyanyu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

ai_fill_skill["tenyearyjyanyu"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		if c:isKindOf("Slash")
		then
			if table.contains(self:getPriorTurnUseCards(),c) then continue end
			return parse_policy(self,"@TenyearYjYanyuCard="..c:getKnownEffectiveId())
		end
	end
end

ai_card_use["TenyearYjYanyuCard"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.TenyearYjYanyuCard = 5.4
sgs.ai_use_priority.TenyearYjYanyuCard = 5.8

ai_skill_invoke.tenyearqianxi = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

sgs.ai_skill_playerchosen.tenyearqianxi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

ai_fill_skill["tenyearjiaozhao"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
	local basic = self.player:getStrategyMark("tenyearjiaozhao_basic-Clear")-1
	local trick = self.player:getStrategyMark("tenyearjiaozhao_trick-Clear")-1
	local bname = property(self,"tenyearjiaozhao_name")
  	for _,c in sgs.list(cards)do
		if c:getKnownEffectiveId()~=basic
		and c:getKnownEffectiveId()~=trick then continue end
		local bn = clone(self,"tenyearjiaozhao","tenyearjiaozhao",bname,sgs.Card_NoSuit,0,{})
		if bn then
			bn = turn_clone(self,"tenyearjiaozhao",bname,sgs.Card_NoSuit,0,{c:getKnownEffectiveId()},request)
			if bn:isAvailable(self.player) then
				local d = self:aiUseCard(bn)
				if d.card and d.to then
					if bn:canRecast() and d.to:isEmpty() then continue end
					self:setPriorityValue("TenyearJiaozhaoCard",sgs.ai_use_priority[bn:getClassName()]-0.5,"tenyear_st_standard")
					return bn
				end
			end
		end
	end
	self:setPriorityValue("TenyearJiaozhaoCard",6.8,"tenyear_st_standard")
	local level = property(self,"tenyearjiaozhao_level","Int")
	level = type(level)=="number" and level or 0
  	for _,c in sgs.list(cards)do
		if self.player:hasUsed("TenyearJiaozhaoCard") and level<2
		or level>1 and self.player:usedTimes("TenyearJiaozhaoCard")>1
		then break end
		return parse_policy(self,"@TenyearJiaozhaoCard="..c:getKnownEffectiveId())
	end
end

sgs.ai_guhuo_card.tenyearjiaozhao = function(self,toname,class_name)
	local basic = self.player:getStrategyMark("tenyearjiaozhao_basic-Clear")-1
	local trick = self.player:getStrategyMark("tenyearjiaozhao_trick-Clear")-1
	local bname = property(self,"tenyearjiaozhao_name")
	local cards = self:addHandPile()
	cards = self:sortByKeepValue(cards,nil,"l")
   	for d,c in sgs.list(cards)do
		if c:getKnownEffectiveId()~=basic
		and c:getKnownEffectiveId()~=trick
		then continue end
		local bn = self:getEvaluationCard(bname)
		if bn and toname==bname
		and known(self.request.reason,"current reason")==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
		then
			return{name=bname,skill="tenyearjiaozhao",suit=sgs.Card_NoSuit,number=0,subcards={c:getKnownEffectiveId()}}
		end
	end
end

ai_card_use["TenyearJiaozhaoCard"] = function(self, card, use, request)
	local level = property(self,"tenyearjiaozhao_level","Int")
	level = type(level)=="number" and level or 0
	if level>1 then use.card = card return end
	local n = 998
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if self.player:distanceTo(p)<=n then n = self.player:distanceTo(p) end
	end
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if self.player:distanceTo(p)<=n
		and self:isFriend(p)
		then
			use.card = card
			return
		end
	end
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if self.player:distanceTo(p)<=n
		and not self:isEnemy(p)
		then
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.TenyearJiaozhaoCard = 5.4
sgs.ai_use_priority.TenyearJiaozhaoCard = 6.8

sgs.ai_skill_playerchosen.tenyearjiaozhao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_askforag.tenyearjiaozhao = function(self,card_ids)
    local cards = {}
	for c,id in sgs.list(card_ids)do
		c = known_card(self,id)
		table.insert(cards,c)
	end
   	local target = self.room:getCurrent()
    cards = self:sortByUseValue(cards,self:isEnemy(target))
	local level = property(self,"tenyearjiaozhao_level","Int")
	if target:objectName()==self.player:objectName()
	then
		for d,c in sgs.list(cards)do
			d = self:aiUseCard(c)
			if not d.card then continue end
			if level>1 and c:isAvailable(target)
			then return c:getKnownEffectiveId() end
			if c:isAvailable(target)
			and not c:targetFixed()
			then return c:getKnownEffectiveId() end
		end
	end
    for _,c in sgs.list(cards)do
		if self:isEnemy(target)
		and c:targetFixed()
		then return c:getKnownEffectiveId() end
		if level>1 and self:isFriend(target)
		and c:isAvailable(target)
		then return c:getKnownEffectiveId() end
		if self:isFriend(target)
		and c:isAvailable(target)
		and not c:targetFixed()
		then return c:getKnownEffectiveId() end
	end
	return cards[1]:getKnownEffectiveId() or "."
end

ai_fill_skill["tenyearganlu"] = function(self, options, request)
    local inclusive = options and options.inclusive

	return parse_policy(self,"@TenyearGanluCard=.")
end

ai_card_use["TenyearGanluCard"] = function(self, card, use, request)
	self.friends = self:sort(self.friends,"equip")
	self.enemies = self:sort(self.enemies,"equip",true)
	for _,fp in sgs.list(self.friends)do
		local n = fp:getEquips():length()-#self:poisonCards("e",fp)
		for _,ep in sgs.list(self.enemies)do
			local x = ep:getEquips():length()-#self:poisonCards("e",ep)
			if n<x
			then
				use.card = card
				use.to:append(fp)
				use.to:append(ep)
				return
			end
		end
	end
	for _,fp in sgs.list(self.friends)do
		local n = fp:getEquips():length()-#self:poisonCards("e",fp)
		for _,ep in sgs.list(self.enemies)do
			local x = ep:getEquips():length()-#self:poisonCards("e",ep)
			if n<x and ep:getEquips():length()-x>0
			then
				use.card = card
				use.to:append(fp)
				use.to:append(ep)
				return
			end
		end
	end
end

sgs.ai_use_value.TenyearGanluCard = 9.4
sgs.ai_use_priority.TenyearGanluCard = 6.8

ai_skill_invoke.tenyearbuyi = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local dy = data:toDying()
	if dy
	then
		return (self:isFriend(dy.who)) or false
	end
	return false

end

sgs.ai_skill_cardchosen.tenyearbuyi = function(self,who,flags,method)
	if who:objectName()==self.player:objectName()
	then
		for _,c in sgs.list(self:sortByUseValue(who:getCards(flags),true))do
			if c:getTypeId()~=1 then return c:getId() end
		end
	end
	return source_random_card(self,who,flags)
end

sgs.ai_skill_cardask["@tenyearzhuhai"] = function(self,data)
   	local target = self.room:getCurrent()
	self:setStrategyMemory("choice_override:tenyearzhuhai","dismantlement="..target:objectName())
	if self:isFriend(target)
	and self:doDisCard(target,"ej")
  	then return true end
	if self:isEnemy(target)
	and not self:isWeak(target)
	and self:doDisCard(target)
  	then return true end
	self:setStrategyMemory("choice_override:tenyearzhuhai","slash="..target:objectName())
    return self:isEnemy(target) and (self:isWeak(target) or self.player:getHandcardNum()>1)
end

ai_fill_skill["tenyearjianyan"] = function(self, options, request)
    local inclusive = options and options.inclusive

	return parse_policy(self,"@TenyearJianyanCard=.")
end

ai_card_use["TenyearJianyanCard"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.TenyearJianyanCard = 3.4
sgs.ai_use_priority.TenyearJianyanCard = 5.8

ai_skill_choice.tenyearjianyan = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local items = choices:split("+")
	if self:isWeak()
	and math.random()>0.4
	and table.contains(items,"red")
	then return ai_choice_result(("red"), options) end
	if self:isWeak()
	and math.random()>0.5
	and table.contains(items,"basic")
	then return ai_choice_result(("basic"), options) end
	if not self:isWeak()
	and math.random()>0.4
	and table.contains(items,"black")
	then return ai_choice_result(("black"), options) end
	if self:isWeak()
	and math.random()>0.5
	and table.contains(items,"trick")
	then return ai_choice_result(("trick"), options) end

    return ai_choice_result(nil, options)
end

sgs.ai_skill_playerchosen.tenyearjianyan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
	local cid = self.player:getStrategyMark("tenyearjianyan")
	local c = known_card(self,cid)
	if c:isAvailable(self.player)
	and players:contains(self.player)
	then
		c = self:aiUseCard(c)
		if c.card
		then
			return self.player
		end
	end
	local to,id = sgs.ai_skill_askforyiji.nosyiji(self,{cid},players)
    for _,target in sgs.list(destlist)do
		if to and target:objectName()==to:objectName()
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end

ai_fill_skill["tenyearanxu"] = function(self, options, request)
    local inclusive = options and options.inclusive

	return parse_policy(self,"@TenyearAnxuCard=.")
end

ai_card_use["TenyearAnxuCard"] = function(self, card, use, request)
	self.enemies = self:sort(self.enemies,"hp")
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
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		for _,fp in sgs.list(self.friends_noself)do
			if ep:getHandcardNum()>fp:getHandcardNum()
			and not self:isFriend(ep)
			then
				use.card = card
				use.to:append(ep)
				use.to:append(fp)
				return
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		for _,fp in sgs.list(self.room:getOtherPlayers(self.player))do
			if ep:getHandcardNum()>fp:getHandcardNum()
			and not self:isEnemy(fp)
			then
				use.card = card
				use.to:append(ep)
				use.to:append(fp)
				return
			end
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		for _,fp in sgs.list(self.room:getOtherPlayers(self.player))do
			if ep:getHandcardNum()>fp:getHandcardNum()
			and not self:isFriend(ep)
			and not self:isEnemy(fp)
			then
				use.card = card
				use.to:append(ep)
				use.to:append(fp)
				return
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		for _,fp in sgs.list(self.enemies)do
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

sgs.ai_use_value.TenyearAnxuCard = 3.4
sgs.ai_use_priority.TenyearAnxuCard = 4.8

sgs.ai_skill_playerchosen.tenyearzhuiyi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	destlist = self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and target:isWounded()
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

ai_skill_invoke.TenyearJianying = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    return (true) or false
end

sgs.ai_use_revises.TenyearJianying = function(self,card,use)
	for _,m in sgs.list(self.player:getMarkNames())do
		m = m:split("+")
		if table.contains(m,"&TenyearJianying")
		then
			if table.contains(m,card:getSuitString().."_char") or table.contains(m,card:getNumberString())
			then self:incrementNamedSourcePriority("TenyearJianying",card,card:getClassName())end
		end
	end
end

sgs.ai_can_damagehp.tenyearshibei = function(self,from,card,to)
	return to:getStrategyMark("tenyearshibei-Clear")<1
	and self:canLoseHp(from,card,to)
	and to:getHp()>1
end

sgs.ai_skill_defense.tenyearshibei = function(self,to)
	return to:getStrategyMark("shibei")<1 and 1
	or to:getStrategyMark("shibei")<2 and -3
end

ai_fill_skill["tenyearzhanjue"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local ids = {}
  	for _,c in sgs.list(self.player:getHandcards())do
		if self.player:getStrategyMark("tenyearzhanjueIgnore_"..c:getId().."-Clear")<1
        then table.insert(ids,c:getKnownEffectiveId())end
	end
	local fs=turn_clone(self,"tenyearzhanjue","duel",sgs.Card_NoSuit,0,ids,request)
 if #ids>0
	and #self:getPriorTurnUseCards()<2
	then return fs end
end

sgs.ai_use_revises.tenyearzhanjue = function(self,card,use)
	if table.contains(card:getSkillNames(), "tenyearzhanjue") then
		for _,ep in sgs.list(self.enemies)do
			if can_to(self,card,self.player,ep,use.to)
			and getCardsNum("Slash",ep,self.player)<1 then
				use.card = card
				use.to:append(ep)
			end
		end
		return use.card==card
	end
end

ai_fill_skill["tenyearqinwang"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.room:getLieges("shu",self.player):length()>0 then
		return parse_policy(self,"@TenyearQinwangCard=.")
	end
end

ai_card_use["TenyearQinwangCard"] = function(self, card, use, request)
	use.card = card
end

sgs.ai_use_value.TenyearQinwangCard = 4.4
sgs.ai_use_priority.TenyearQinwangCard = 4.8

sgs.ai_skill_cardask["@tenyearqinwang-give"] = function(self,data)
    local to = data:toPlayer()
	if self:isFriend(to)
  	then return self:getCardsNum("Slash")>1 or self.player:getCardCount()>3
	elseif not self:isEnemy(to) then return self:isWeak(to) end
end

sgs.ai_skill_playerschosen.tenyearxiansi = function(self,targets,max_num,min_num)
	local tos = {}
  	for i,p in sgs.list(targets)do
		if #tos>=max_num then break end
		if self:isFriend(p)
		and self:doDisCard(p,"e")
		then table.insert(tos,p) end
	end
  	for i,p in sgs.list(targets)do
		if #tos>=max_num then break end
		if self:isEnemy(p)
		and self:doDisCard(p,"he")
		then table.insert(tos,p) end
	end
  	for i,p in sgs.list(targets)do
		if #tos>=max_num then break end
		if not self:isFriend(p)
		and self:doDisCard(p,"he")
		and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
	return tos
end

ai_fill_skill["tenyearxiansi"] = function(self, options, request)
    local inclusive = options and options.inclusive

  	local ids = self.player:getPile("counter")
	if ids:length()>self.player:getHp()
	then
	   	local fs = clone(self,"tenyearxiansi","_tenyearxiansi","slash",sgs.Card_NoSuit,0,{})
		if fs:isAvailable(self.player) then
			fs = self:aiUseCard(fs)
			if fs.card and fs.to then
				write(self,"tenyearxiansi_to",fs.to)
				self:setPriorityValue("TenyearXiansiCard",sgs.ai_use_priority.Slash+0.5,"tenyear_st_standard")
				return parse_policy(self,"@TenyearXiansiCard="..ids:at(0))
			end
		end
	end
end

ai_card_use["TenyearXiansiCard"] = function(self, card, use, request)
	if read(self,"tenyearxiansi_to")
	then
		use.card = card
		use.to = read(self,"tenyearxiansi_to")
	end
end

sgs.ai_use_value.TenyearXiansiCard = 5.4
sgs.ai_use_priority.TenyearXiansiCard = 2.8

ai_fill_skill["tenyearxiansi_slash"] = function(self, options, request)
    local inclusive = options and options.inclusive

	for _,owner in sgs.list(self.room:findPlayersBySkillName("tenyearxiansi"))do
		local ids = owner:getPile("counter")
		if ids:length()<2 then continue end
	   	local fs = clone(self,"tenyearxiansi","_tenyearxiansi","slash",sgs.Card_NoSuit,0,{})
		if fs:isAvailable(self.player)	then
			local d = self:aiUseCard(fs)
			if d.card and d.to
			and d.to:contains(owner)
			then
				write(self,"tenyearxiansi_to",d.to)
				self:setPriorityValue("TenyearXiansiSlashCard",sgs.ai_use_priority.Slash+0.3,"tenyear_st_standard")
				return parse_policy(self,"@TenyearXiansiSlashCard="..ids:at(0).."+"..ids:at(1))
			end
			if self:isFriend(owner)
			and can_to(self,fs,self.player,owner)
			and not self:slashIsEffective(fs,owner,self.player)
			then
				write(self,"tenyearxiansi_to",AIList.new({}))
				write(self,"tenyearxiansi_to",{owner})
				self:setPriorityValue("TenyearXiansiSlashCard",sgs.ai_use_priority.Slash+0.3,"tenyear_st_standard")
				return parse_policy(self,"@TenyearXiansiSlashCard="..ids:at(0).."+"..ids:at(1))
			end
		end
	end
end

ai_card_use["TenyearXiansiSlashCard"] = function(self, card, use, request)
	if read(self,"tenyearxiansi_to")
	then
		use.card = card
		use.to = read(self,"tenyearxiansi_to")
	end
end

sgs.ai_use_value.TenyearXiansiSlashCard = 5.4
sgs.ai_use_priority.TenyearXiansiSlashCard = 2.8


ai_skill_invoke.tenyearfenli = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local pstring = data:toString()
	if pstring=="judge"
	then
		return (#self.enemies>0) or false
	end
	if pstring=="play"
	then
		pstring = self:getTurnUse()
		return (#self.enemies>0
		and #pstring<4) or false
	end
	if pstring=="discard"
	then
		return (#self.enemies>0
		or self.player:getHandcardNum()>0) or false
	end
	return false

end

sgs.ai_skill_playerschosen.tenyearpingkou = function(self,targets,max_num,min_num)
	local tos = {}
	local enemies = self:sort(targets,"hp")
  	for i,p in sgs.list(enemies)do
		if #tos>=max_num then break end
		if self:isEnemy(p)
		then table.insert(tos,p) end
	end
  	for i,p in sgs.list(enemies)do
		if #tos>=max_num then break end
		if self:isFriend(p)
		and not self:isWeak(p)
		and self:canDamageHp(self.player,nil,p)
		then table.insert(tos,p) end
	end
  	for i,p in sgs.list(enemies)do
		if #tos>=max_num then break end
		if not self:isFriend(p)
		and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_skill_playerchosen.tenyearpingkou = function(self,targets)
	local enemies = self:sort(targets,"hp")
  	for i,p in sgs.list(enemies)do
		if self:isEnemy(p)
		then return p end
	end
  	for i,p in sgs.list(enemies)do
		if not self:isFriend(p)
		then return p end
	end
	return enemies[1]
end

ai_fill_skill["tenyearmingce"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		if c:isKindOf("Slash") or c:isKindOf("EquipCard") then
			return parse_policy(self,"@TenyearMingceCard="..c:getKnownEffectiveId())
		end
	end
end

ai_card_use["TenyearMingceCard"] = function(self, card, use, request)
	self.enemies = self:sort(self.enemies,"hp")
	local dc = clone(self,"tenyearmingce","tenyearmingce","slash",sgs.Card_NoSuit,0,{})
	for _,ep in sgs.list(self.enemies)do
		for _,fp in sgs.list(self.friends_noself)do
			if can_to(self,dc,fp,ep)
			and can_to(self,dc,self.player,ep)
			then
				use.card = card
				use.to:append(fp)
				return
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		for _,fp in sgs.list(self.friends_noself)do
			if can_to(self,dc,fp,ep)
			then
				use.card = card
				use.to:append(fp)
				return
			end
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		for _,fp in sgs.list(self.friends_noself)do
			if can_to(self,dc,fp,ep)
			and not self:isFriend(ep)
			then
				use.card = card
				use.to:append(fp)
				return
			end
		end
	end
	for _,fp in sgs.list(self.friends_noself)do
		use.card = card
		use.to:append(fp)
		return
	end
	for _,fp in sgs.list(self.room:getOtherPlayers(self.player))do
		if not self:isEnemy(fp) then
			use.card = card
			use.to:append(fp)
			return
		end
	end
end

sgs.ai_use_value.TenyearMingceCard = 3.4
sgs.ai_use_priority.TenyearMingceCard = 3.8

sgs.ai_skill_playerchosen.tenyearmingce = function(self,targets)
	local enemies = self:sort(targets,"hp")
  	for i,p in sgs.list(enemies)do
		write(self,"mingce_to",p)
		if self:isEnemy(p)
		then return p end
	end
  	for i,p in sgs.list(enemies)do
		write(self,"mingce_to",p)
		if not self:isFriend(p)
		then return p end
	end
	write(self,"mingce_to",enemies[1])
	return enemies[1]
end

ai_skill_choice.tenyearmingce = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local items = choices:split("+")
	if table.contains(items,"use")
	and read(self,"mingce_to") then
		local dc = clone(self,"tenyearmingce","tenyearmingce","slash",sgs.Card_NoSuit,0,{})
		if not self:isFriend(read(self,"mingce_to")) and self:isWeak(read(self,"mingce_to"))
		and self:slashIsEffective(dc,read(self,"mingce_to"),self.player)
		then return ai_choice_result(("use"), options) end
		if not self:isFriend(read(self,"mingce_to")) and read(self,"mingce_to"):getHandcardNum()<2
		and self:slashIsEffective(dc,read(self,"mingce_to"),self.player)
		then return ai_choice_result(("use"), options) end
	end
	return ai_choice_result(("draw"), options)
end

ai_skill_invoke.tenyearzhiyu = function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    if self:canDraw() then
		local hs = self.player:getHandcards()
		for _,h in sgs.list(hs)do
			if hs:first():getColor()~=h:getColor()
			then return (true) or false end
		end
		local damage = data:toDamage()
		return (not(damage.from and self:isFriend(damage.from))) or false
	end
    return false

end

sgs.ai_can_damagehp.tenyearzhiyu = function(self,from,card,to)
	return from and self:isEnemy(from)
	and card and card:isDamageCard() and self:canLoseHp(from,card,to)
	and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
end

ai_fill_skill["tenyearfencheng"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local can = 0
	for _,ep in sgs.list(self.enemies)do
		if self:isWeak(ep) then can = can+1 end
	end
	if can<#self.enemies/2 then return end
	return parse_policy(self,"@TenyearFenchengCard=.")
end

ai_card_use["TenyearFenchengCard"] = function(self, card, use, request)
	self.friends = self:sort(self.friends,"card",true)
	for _,ep in sgs.list(self.friends)do
		if self:isEnemy(ep:getNextAlive()) then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		if not self:isEnemy(ep) and self:isEnemy(ep:getNextAlive()) then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.TenyearFenchengCard = 5.4
sgs.ai_use_priority.TenyearFenchengCard = 0.8

sgs.ai_skill_discard.tenyearfencheng = function(self,max,min)
	if self:ajustDamage(self.room:getCurrent(),self.player,2,nil,"F")==0
	or min>3 and self.player:getHp()>3
	then return {} end
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	local to = self.player:getNextAlive()
	if to==self.room:getCurrent()
	then to = to:getNextAlive() end
	if self:isEnemy(to)	and self:isWeak(to)
	and to:getCardCount()<=#cards then
		min = min>to:getCardCount() and min or to:getCardCount()
	end
	for _,c in sgs.list(cards)do
		if #to_cards>=min then break end
		table.insert(to_cards,c:getKnownEffectiveId())
	end
	return to_cards
end

ai_fill_skill["tenyearmieji"] = function(self, options, request)
    local inclusive = options and options.inclusive

	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		if c:isKindOf("Weapon") or c:isKindOf("TrickCard") and c:isBlack()
		then return parse_policy(self,"@TenyearMiejiCard="..c:getKnownEffectiveId()) end
	end
end

ai_card_use["TenyearMiejiCard"] = function(self, card, use, request)
	self.enemies = self:sort(self.enemies,"handcard")
	for _,ep in sgs.list(self.enemies)do
		if ep:getHandcardNum()>0
		then
			use.card = card
			write(self,"tenyearmieji_to",ep)
			return
		end
	end
end

sgs.ai_use_value.TenyearMiejiCard = 3.4
sgs.ai_use_priority.TenyearMiejiCard = 2.8

sgs.ai_skill_playerchosen.tenyearmieji = function(self,targets)
	return read(self,"tenyearmieji_to")
end

sgs.ai_skill_cardask["@mieji-discard"] = function(self,data,pattern,target)
	local all = sgs.QList2Table(self.player:getCards("he"))
	all = self:sortByKeepValue(all)
	local ids={}
	for _,c in ipairs(all)do
		if c:isKindOf("TrickCard") then return c:getLegacyStringKey() end
		if (#ids)>=2 then return aggregate_mieji(self,ids) end
		table.insert(ids,c:getEffectiveId())
	end
	return aggregate_mieji(self,ids)
end














-- V2 target selection reuses the existing Tenyear Tuxi strategy without parsing
-- or executing its legacy card. Intersect its reply with the current candidates.
raw_tenyeartuxi=ai_skill_use["@@tenyeartuxi"]
sgs.ai_skill_playerschosen.tenyeartuxi = function(self, candidates, max_num, min_num)
    local strategy = raw_tenyeartuxi
    if type(strategy) ~= "function" then return {} end
    local reply = strategy(self, "@tuxi-card:::" .. tostring(max_num))
    local names = type(reply) == "string" and reply:match("%->(.+)$")
    if not names then return {} end
    local available, selected, result = {}, {}, {}
    for _, player in sgs.qlist(candidates) do available[player:objectName()] = player end
    for name in names:gmatch("[^+]+") do
        if available[name] and not selected[name] and #result < max_num then
            selected[name] = true
            table.insert(result, available[name])
        end
    end
    return result
end

local raw_use={};for k,v in pairs(ai_skill_use)do raw_use[k]=v end
do local f=raw_use['@@tenyearrende'];ai_skill_use['@@tenyearrende']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearqingjian'];ai_skill_use['@@tenyearqingjian']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyeartuxi'];ai_skill_use['@@tenyeartuxi']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearshensu1'];ai_skill_use['@@tenyearshensu1']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearshensu2'];ai_skill_use['@@tenyearshensu2']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearshensu3'];ai_skill_use['@@tenyearshensu3']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyeartianxiang'];ai_skill_use['@@tenyeartianxiang']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearchunlao'];ai_skill_use['@@tenyearchunlao']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@secondtenyearchunlao'];ai_skill_use['@@secondtenyearchunlao']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearjiangchi'];ai_skill_use['@@tenyearjiangchi']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearbenxi!'];ai_skill_use['@@tenyearbenxi!']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearkuangfu!'];ai_skill_use['@@tenyearkuangfu!']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearxingxue'];ai_skill_use['@@tenyearxingxue']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearshenduan'];ai_skill_use['@@tenyearshenduan']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearqiaoshui1'];ai_skill_use['@@tenyearqiaoshui1']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearqiaoshui2'];ai_skill_use['@@tenyearqiaoshui2']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearaocai'];ai_skill_use['@@tenyearaocai']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearzishou'];ai_skill_use['@@tenyearzishou']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearxuanhuo'];ai_skill_use['@@tenyearxuanhuo']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearsidi'];ai_skill_use['@@tenyearsidi']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearhuaiyi'];ai_skill_use['@@tenyearhuaiyi']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearxianzhou'];ai_skill_use['@@tenyearxianzhou']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearbingyi'];ai_skill_use['@@tenyearbingyi']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearzongxuan'];ai_skill_use['@@tenyearzongxuan']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=raw_use['@@tenyearzongxuan!'];ai_skill_use['@@tenyearzongxuan!']=function(self, prompt, request)return response_wire(self,f(self,prompt, request))end end
do local f=sgs.ai_cardsview_valuable.tenyearchunlao;sgs.ai_cardsview_valuable.tenyearchunlao=function(self,...)local v=f(self,...);if type(v)~="string"then return v end;local cl,skill,ids=decode(v);return{legacy_class=cl,skill=skill,subcards=ids}end end
do local f=sgs.ai_cardsview_valuable.secondtenyearchunlao;sgs.ai_cardsview_valuable.secondtenyearchunlao=function(self,...)local v=f(self,...);if type(v)~="string"then return v end;local cl,skill,ids=decode(v);return{legacy_class=cl,skill=skill,subcards=ids}end end

sgs.ai_skill_playerchosen.tenyearjiewei_from=function(self) local v,ok=self:getStrategyMemory("tenyear_override:playerchosen:tenyearjiewei_from");if not ok then ai_unsupported("dynamic source writer not observed","tenyearjiewei_from")end;return known(self.room:findPlayerByObjectName(v,true),"source chosen target")end

sgs.ai_skill_cardchosen.tenyearjiewei=function(self) local v,ok=self:getStrategyMemory("tenyear_override:cardchosen:tenyearjiewei");if not ok then ai_unsupported("dynamic source writer not observed","tenyearjiewei")end;self:setStrategyMemory("tenyear_override:cardchosen:tenyearjiewei",nil);return v end

sgs.ai_skill_playerchosen.tenyearjiewei_to=function(self) local v,ok=self:getStrategyMemory("tenyear_override:playerchosen:tenyearjiewei_to");if not ok then ai_unsupported("dynamic source writer not observed","tenyearjiewei_to")end;return known(self.room:findPlayerByObjectName(v,true),"source chosen target")end

sgs.ai_skill_cardchosen.tenyearyonglve=function(self) local v,ok=self:getStrategyMemory("tenyear_override:cardchosen:tenyearyonglve");if not ok then ai_unsupported("dynamic source writer not observed","tenyearyonglve")end;self:setStrategyMemory("tenyear_override:cardchosen:tenyearyonglve",nil);return v end

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_target_damage["just_damage_after_relation.zhiman"]
    local policy = function(self, to, context)
        local value, strategy_call = context.value, context.query
        local from, is_slash, lock, same_player, strategy_known = context.extra[1], context.extra[2], context.extra[3], context.extra[4], context.extra[5]
        if strategy_call(from, "hasSkills", "zhiman|tenyearzhiman") and strategy_call(self, "doDisCard", to, "e") then return true, true end
        return value
    end
    sgs.ai_target_damage["just_damage_after_relation.zhiman"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "just_damage_after_relation" and context.rule == "zhiman" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "just_damage_after_relation.zhiman", {
        {phase="just_damage_after_relation", order=6, rule="zhiman"},
    })
end)()
end
