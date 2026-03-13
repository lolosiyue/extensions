
sgs.ai_fill_skill.zhizhe = function(self)
	local cs = {}
	for _,h in sgs.list(self:sortByUseValue(self.player:getCards("h")))do
		if h:getTypeId()<3 and not h:isKindOf("DelayedTrick")
		then table.insert(cs,h) end
	end
	if #cs<4 or self:getUseValue(cs[1])<8 then return end
	return sgs.Card_Parse("@ZhizheCard="..cs[1]:getEffectiveId())
end

sgs.ai_skill_use_func["ZhizheCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ZhizheCard = 5.4
sgs.ai_use_priority.ZhizheCard = 13.8

sgs.ai_skill_playerschosen.qingshi = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	self:sort(destlist,"hp")
	local tos = {}
	for _,to in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isFriend(to) then table.insert(tos,to) end
	end
	for _,to in sgs.list(destlist)do
		if #tos>=x or #tos>self.player:aliveCount()/2 then break end
		if not table.contains(tos,to) and not self:isEnemy(to)
		then table.insert(tos,to) end
	end
	return tos
end

sgs.ai_skill_choice.qingshi = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"draw")
	and #self.friends_noself>self.player:getHp()
	and #self.toUse>3 then return "draw" end
	for _,c in sgs.list(items)do
		if c:startsWith("selfdraw")
		then return c end
	end
	return items[1]
end

sgs.ai_skill_invoke.tenyearsuifu = function(self,data)
	local target = self.room:getCurrent()
	if target then
		return not self:isFriend(target)
		or #self:poisonCards("he",target)>target:getCardCount()/2
	end
end

sgs.ai_skill_playerschosen.tenyearpijing = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	self:sort(destlist,"hp")
	local tos = {}
	for _,to in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isFriend(to) then table.insert(tos,to) end
	end
	for _,to in sgs.list(destlist)do
		if #tos>=x or #tos>self.player:aliveCount()/2 then break end
		if not table.contains(tos,to) and not self:isEnemy(to)
		then table.insert(tos,to) end
	end
	return tos
end

sgs.ai_skill_invoke.lieqiong = function(self,data)
	local target = data:toPlayer()
	if target then
		return not self:isFriend(target)
	end
end

sgs.ai_skill_choice.lieqiong = function(self,choices,data)
	local items = choices:split("+")
	local damage = data:toDamage()
	if table.contains(items,"lq_tianchong")
	and self:isEnemy(damage.to)
	then return "lq_tianchong" end
	if table.contains(items,"lq_zhongshu")
	and self.player:getMark("&lqjishang+:+lq_zhongshu-SelfClear")<1
	then return "lq_zhongshu" end
	if table.contains(items,"lq_diji")
	and self.player:getMark("&lqjishang+:+lq_diji-SelfClear")<1
	then return "lq_diji" end
	if table.contains(items,"lq_lifeng")
	then return "lq_lifeng" end
	if table.contains(items,"lq_qihai")
	and self.player:getMark("&lqjishang+:+lq_qihai-SelfClear")<1
	then return "lq_qihai" end
end

sgs.ai_skill_invoke.thzhanjue = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_choice.thzhanjue = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"thzhanjue1")
	and self.player:getLostHp()<self.player:getHp()
	then return "thzhanjue1" end
	if table.contains(items,"thzhanjue2")
	and self.player:getLostHp()>self.player:getHp()
	then return "thzhanjue2" end
end

sgs.ai_used_revises.fengliao = function(self,use)
	if use.to:length()~=1 or use.card:canRecast() then return end
	local tp = self.player
	if self.player:getChangeSkillState("fengliao")==1 then
		if use.card:isSingleTargetCard() and use.to:length()==1 then tp = use.to:at(0) end
		if self:isEnemy(tp) and #self.toUse>1 then use.card = nil end
	else
		if use.card:isSingleTargetCard() and use.to:length()==1 then tp = use.to:at(0) end
		if tp==self.player then
			if self:getCardsNum("Peach,Analeptic")<1 then use.card = nil end
		elseif self:isFriend(tp)
		then use.card = nil end
	end
end

sgs.ai_fill_skill.peiniang = function(self)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for i,c1 in sgs.list(cards)do
		if self.player:property("yitongSuit"):toString()~=c1:getSuitString()
		or table.contains(self.toUse,c1) then continue end
		local dc = dummyCard("analeptic")
		dc:setSkillName("peiniang")
		dc:addSubcard(c1)
		if dc:isAvailable(self.player)
		then return dc end
	end
end

function sgs.ai_cardsview.peiniang(self,class_name,player)
   	local cards = sgs.QList2Table(player:getCards("h"))
	self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
       	if c:isKindOf("Analeptic") then
	   		return c:toString()
	   	end
	end
	for _,c in sgs.list(cards)do
       	if player:property("yitongSuit"):toString()==c:getSuitString() then
	   		return ("analeptic:peiniang[no_suit:0]="..c:toString())
	   	end
	end
end

sgs.ai_skill_invoke.chaozhen = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_invoke.lianjie = function(self,data)
	return self:canDraw()
end

sgs.ai_fill_skill.jiangxian = function(self)
	return sgs.Card_Parse("@JiangxianCard=.")
end

sgs.ai_skill_use_func["JiangxianCard"] = function(card,use,self)
	if self:isWeak() then
		if self.player:getMaxHp()<3 then
			sgs.ai_skill_choice.jiangxian = "jiangxian1"
			use.card = card
		end
	end
end

sgs.ai_use_value.JiangxianCard = 5.4
sgs.ai_use_priority.JiangxianCard = 0.8

sgs.ai_skill_cardask.thshenduan0 = function(self,data,pattern)
    local pd = data:toPindian()
	if pd.to==self.player then
		if self:isEnemy(pd.from)
		then return true end
	else
		if self:isEnemy(pd.to)
		then return true end
	end
	return "."
end

sgs.ai_fill_skill.thkegou = function(self)
	return sgs.Card_Parse("@ThKegouCard=.")
end

sgs.ai_skill_use_func["ThKegouCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,to in sgs.list(self.enemies)do
		if self.player:canPindian(to) then
			use.to:append(to)
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.ThKegouCard = 5.4
sgs.ai_use_priority.ThKegouCard = 3.8

sgs.ai_skill_use["@@thkegou"] = function(self,prompt)
	self:sort(self.enemies)
	for _,to in sgs.list(self.enemies)do
		if self.player:canPindian(to) then
			return string.format("@ThKegouCard=.->%s",to:objectName())
		end
	end
end

sgs.ai_fill_skill.dixian = function(self)
	return sgs.Card_Parse("@DixianCard=.")
end

sgs.ai_skill_use_func["DixianCard"] = function(card,use,self)
	if self:isWeak() and self:getOverflow()<1 then
		use.card = card
	end
end

sgs.ai_use_value.DixianCard = 5.4
sgs.ai_use_priority.DixianCard = 3.8

sgs.ai_skill_playerchosen.ruijun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_discard.thzhiji = function(self)
	local cards = {}
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if #cards>#handcards/2 or self:getKeepValue(h)>7 then continue end
		table.insert(cards,h:getEffectiveId())
	end
	return cards
end

sgs.ai_skill_playerschosen.thzhiji = function(self,players,x,n)
	local destlist = sgs.QList2Table(players)
	self:sort(destlist)
	local tos = {}
	for _,to in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isEnemy(to) then table.insert(tos,to) end
	end
	for _,to in sgs.list(destlist)do
		if #tos>=x or table.contains(tos,to) then break end
		if not self:isFriend(to) then table.insert(tos,to) end
	end
	return tos
end

sgs.ai_fill_skill.zhongyan = function(self)
	return sgs.Card_Parse("@ZhongyanCard=.")
end

sgs.ai_skill_use_func["ZhongyanCard"] = function(card,use,self)
	self:sort(self.friends)
	for i,p in sgs.list(self.friends)do
		if i>=#self.friends/2 and p:getHandcardNum()>0 then
			use.to:append(p)
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.ZhongyanCard = 5.4
sgs.ai_use_priority.ZhongyanCard = 3.8

sgs.ai_skill_use["@@zhongyan!"] = function(self,prompt)
	self.qianlong_use = false
	local n1 = {}
	for _,id in sgs.list(self.player:getTag("zhongyanForAI"):toIntList())do
		table.insert(n1,sgs.Sanguosha:getCard(id))
	end
	self:sortByKeepValue(n1,true)
	local hs = self:sortByKeepValue(self.player:getHandcards(),true)
	for _,c in sgs.list(n1)do
		local ids = {c:toString()}
		for _,h in sgs.list(hs)do
			if self:getUseValue(c)>self:getUseValue(h) then
				table.insert(ids,c:toString())
				return "@ZhongyanCard="..table.concat(ids,"+")
			end
		end
	end
end

sgs.ai_skill_playerchosen.zhongyan = function(self,players)
	if self:isWeak() and self.player:isWounded() then return end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target) and self:doDisCard(target,"ej",true)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"ej",true)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_invoke.jinglun = function(self,data)
	local target = data:toPlayer()
	if target then
		return self:isFriend(target)
	end
end

sgs.ai_fill_skill.saying = function(self)
	local es = self:sortByKeepValue(self.player:getEquips())
	for _,h in sgs.list(es)do
		if self.player:getMark("saying_juguan_remove_analeptic_lun")<1 then
			local dc = dummyCard("analeptic")
			dc:setSkillName("saying")
			local d = self:aiUseCard(dc)
			if d.card then
				self.sayingTo = d.to
				return sgs.Card_Parse("@SayingCard="..h:toString()..":analeptic")
			end
		end
		if self.player:getMark("saying_juguan_remove_peach_lun")<1 then
			local dc = dummyCard("peach")
			dc:setSkillName("saying")
			local d = self:aiUseCard(dc)
			if d.card then
				self.sayingTo = d.to
				return sgs.Card_Parse("@SayingCard="..h:toString()..":peach")
			end
		end
	end
	local hs = self:sortByKeepValue(self.player:getHandcards())
	for _,h in sgs.list(hs)do
		if h:getTypeId()==3 and self.player:getMark("saying_juguan_remove_slash_lun")<1
		and h:isAvailable(self.player) and self:aiUseCard(h).card then
			local dc = dummyCard()
			dc:setSkillName("saying")
			local d = self:aiUseCard(dc)
			if d.card then
				self.sayingTo = d.to
				return sgs.Card_Parse("@SayingCard="..h:toString()..":slash")
			end
		end
	end
end

sgs.ai_skill_use_func["SayingCard"] = function(card,use,self)
	if self.sayingTo then
		use.card = card
		use.to = self.sayingTo
	end
end

sgs.ai_use_value.SayingCard = 5.4
sgs.ai_use_priority.SayingCard = 6.8

function sgs.ai_cardsview.saying(self,class_name,player)
   	local cn = patterns(class_name)
	if player:getMark("saying_juguan_remove_"..cn.."_lun")>0 then return end
	if class_name=="Slash" or class_name=="Jink" then
		local cards = sgs.QList2Table(player:getCards("h"))
		self:sortByKeepValue(cards)
		for _,c in sgs.list(cards)do
			if c:getTypeId()==3 and c:isAvailable(player) then
				return "@SayingCard="..c:toString()..":"..cn
			end
		end
	else
		local cards = sgs.QList2Table(player:getEquips())
		self:sortByKeepValue(cards)
		for _,c in sgs.list(cards)do
			return "@SayingCard="..c:toString()..":"..cn
		end
	end
end

sgs.ai_fill_skill.jiaohao = function(self)
	return sgs.Card_Parse("@JiaohaoCard=.")
end

sgs.ai_skill_use_func["JiaohaoCard"] = function(card,use,self)
	local mc = self:getMaxCard()
	if mc:getNumber()>9 then
		self:sort(self.enemies)
		for _,to in sgs.list(self.enemies)do
			if self.player:canPindian(to) and to:getEquips():length()<=self.player:getEquips():length() then
				use.to:append(to)
				use.card = card
				return
			end
		end
	end
	if self:getOverflow()>1 then
		self:sort(self.friends_noself,nil,true)
		for _,to in sgs.list(self.friends_noself)do
			if self.player:canPindian(to) and to:getEquips():length()<=self.player:getEquips():length() then
				use.to:append(to)
				use.card = card
				return
			end
		end
	end
end

sgs.ai_use_value.JiaohaoCard = 5.4
sgs.ai_use_priority.JiaohaoCard = 4.8

sgs.ai_skill_invoke.jiaohao = function(self,data)
	local target = data:toPlayer()
	if target then
		return self:isFriend(target)
	end
end

sgs.ai_fill_skill.shimou = function(self)
	return sgs.Card_Parse("@ShimouCard=.")
end

sgs.ai_skill_use_func["ShimouCard"] = function(card,use,self)
	if self.player:getChangeSkillState("shimou")==1 then
		local n = 999
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if p:getHandcardNum()<n then n = p:getHandcardNum() end
		end
		for _,p in sgs.list(self.friends)do
			if p:getHandcardNum()<=n and p:getHandcardNum()<5 then
				use.card = card
				break
			end
		end
	else
		local n = 0
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if p:getHandcardNum()>n then n = p:getHandcardNum() end
		end
		for _,p in sgs.list(self.enemies)do
			if p:getHandcardNum()>=n and p:getHandcardNum()>5 then
				use.card = card
				break
			end
		end
	end
end

sgs.ai_use_value.ShimouCard = 5.4
sgs.ai_use_priority.ShimouCard = 3.8

sgs.ai_skill_askforag.shimou = function(self,card_ids)
	self.shimouTo = nil
	for _,id in sgs.list(card_ids)do
		local cn = sgs.Sanguosha:getCard(id):objectName()
		local dc = dummyCard(cn)
		dc:setSkillName("shimou")
		local d = self:aiUseCard(dc)
		if d.card then
			self.shimouTo = d.to
			local pnts = self.player:property("shimouPN"):toString():split(":")
			local tp = BeMan(self.room,pnts[2])
			for _,p in sgs.list(d.to)do
				if tp:canUse(dc,p) then continue end
				cn = false
				break
			end
			if cn then
				return id
			end
		end
	end
end

sgs.ai_skill_use["@@shimou!"] = function(self,prompt)
	local tps = {}
	for _,to in sgs.list(self.shimouTo or {})do
		table.insert(tps,to:objectName())
	end
	local pnts = self.player:property("shimouPN"):toString():split(":")
	return "@ShimouCard=.:"..pnts[#pnts].."->"..table.concat(tps,"+")
end

sgs.ai_skill_playerchosen.bizuo = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
    for i,target in sgs.list(destlist)do
		if i<#destlist/2 and self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_invoke.lieji = function(self,data)
	return true
end

sgs.ai_fill_skill.quzhou = function(self)
	return sgs.Card_Parse("@QuzhouCard=.:slash")
end

sgs.ai_skill_use_func["QuzhouCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.QuzhouCard = 5.4
sgs.ai_use_priority.QuzhouCard = 2.8

sgs.ai_skill_use["@@quzhou"] = function(self,prompt)
	for _,id in sgs.list(self.player:getTag("quzhouForAI"):toIntList())do
		local c = sgs.Sanguosha:getCard(id)
		local d = self:aiUseCard(c)
		if d.card then
			local tps = {}
			for _,p in sgs.list(d.to)do
				table.insert(tps,p:objectName())
			end
			return c:toString().."->"..table.concat(tps,"+")
		end
	end
end

sgs.ai_skill_playerchosen.baojia = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for i,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for i,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

sgs.ai_skill_invoke.baojia = function(self,data)
	local damage = data:toDamage()
	if damage.to then
		return self:isFriend(damage.to) and self:isWeak(damage.to)
	end
end

sgs.ai_skill_choice.baojia = function(self,choices,data)
	local items = choices:split("+")
	return items[#items]
end

sgs.ai_fill_skill.douwei = function(self)
	local hs = self:sortByKeepValue(self.player:getHandcards(),nil,"j")
	for _,h in sgs.list(hs)do
		if h:isDamageCard() then
			local dc = dummyCard(h:objectName())
			dc:setSkillName("douwei")
			local d = self:aiUseCard(dc,dummy(nil,99))
			if d.card then
				self.douweitps = {}
				for i,p in sgs.list(d.to)do
					if self.player:inMyAttackRange(p) then
						table.insert(self.douweitps,p)
					end
				end
				if #self.douweitps<1 then continue end
				return sgs.Card_Parse("@DouweiCard="..h:toString())
			end
		end
	end
end

sgs.ai_skill_use_func["DouweiCard"] = function(card,use,self)
	for i,to in sgs.list(self.douweitps)do
		use.to:append(to)
		use.card = card
	end
end

sgs.ai_use_value.DouweiCard = 5.4
sgs.ai_use_priority.DouweiCard = 3.8

sgs.ai_skill_playerchosen.yingjia = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
    for i,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for i,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
end

sgs.ai_fill_skill.xianju = function(self)
	return sgs.Card_Parse("@XianjuCard=.")
end

sgs.ai_skill_use_func["XianjuCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.XianjuCard = 5.4
sgs.ai_use_priority.XianjuCard = 3.8

sgs.ai_fill_skill.woheng = function(self)
	return sgs.Card_Parse("@WohengCard=.")
end

sgs.ai_skill_use_func["WohengCard"] = function(card,use,self)
	self:sort(self.friends_noself)
	local n = self.player:getMark("&woheng_lun")
	for i,to in sgs.list(self.friends_noself)do
		if n>=0 and self:canDraw(to) then
			use.to:append(to)
			use.card = card
			return
		end
	end
	self:sort(self.enemies)
	for i,to in sgs.list(self.enemies)do
		if n>0 and to:getCardCount()>=n then
			use.to:append(to)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.WohengCard = 5.4
sgs.ai_use_priority.WohengCard = 6.8

sgs.ai_skill_choice.woheng = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return items[1]
	end
	return items[#items]
end

sgs.ai_skill_use["@@woheng"] = function(self,prompt)
	self:sort(self.friends_noself)
	local n = self.player:getMark("&woheng_lun")
	for i,to in sgs.list(self.friends_noself)do
		if n>=0 and self:canDraw(to) then
			return string.format("@WohengCard=.->%s",to:objectName())
		end
	end
	self:sort(self.enemies)
	for i,to in sgs.list(self.enemies)do
		if n>0 and to:getCardCount()>=n then
			return string.format("@WohengCard=.->%s",to:objectName())
		end
	end
end

sgs.ai_skill_playerchosen.yugui = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
    for i,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_cardask["yugui1"] = function(self,data)
    local tp = data:toPlayer()
	if self:isFriend(tp)
   	then return true end
    return "."
end

sgs.ai_skill_playerchosen.juchui = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:isWeak(p)
		and p:getMaxHp()<=self.player:getMaxHp()
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and p:isWounded()
		and p:getMaxHp()<=self.player:getMaxHp()
		then return p end
	end
end

sgs.ai_skill_choice.juchui = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items,"juchui1") then
		if self:isFriend(target) and table.contains(items,"juchui2") then
			return "juchui2"
		end
		return "juchui1"
	end
	return items[1]
end

sgs.ai_skill_playerchosen.thlinjie = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p,"N",self.player)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if not self:isFriend(p) and self:damageIsEffective(p,"N",self.player)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p) 
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if p:getMark("jianghuoDamage")<1
		then return p end
	end
	return destlist[#destlist]
end

sgs.ai_fill_skill.zhanpan = function(self)
	return self:canDraw() and sgs.Card_Parse("@ZhanpanCard=.")
end

sgs.ai_skill_use_func["ZhanpanCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ZhanpanCard = 5.4
sgs.ai_use_priority.ZhanpanCard = 6.8

sgs.ai_skill_playerschosen.tiancheng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local tps = {}
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and p:getHandcardNum()-self.player:getHandcardNum()>3
		then table.insert(tps,p) end
	end
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and not table.contains(tps,p)
		 and self.player:getHandcardNum()-p:getHandcardNum()<3
		then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_skill_invoke.duhai = function(self,data)
	local use = data:toCardUse()
	if use.from then
		return self:isEnemy(use.from)
	end
end

sgs.ai_fill_skill.lingse = function(self)
	for _,h in sgs.list(self:sortByKeepValue(self.player:getCards("he")))do
		return sgs.Card_Parse("@LingseCard="..h:getEffectiveId())
	end
end

sgs.ai_skill_use_func["LingseCard"] = function(card,use,self)
	self:sort(self.enemies)
    for i,p in sgs.list(self.enemies)do
		if p:getCardCount()>1 then
			use.card = card
			use.to:append(p)
			return
		end
	end
	self:sort(self.friends_noself,nil,true)
    for i,p in sgs.list(self.friends_noself)do
		if p:getCardCount()>1 then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.LingseCard = 5.4
sgs.ai_use_priority.LingseCard = 3.8
 
sgs.ai_fill_skill.chouxi = function(self)
	local hs = self:sortByKeepValue(self.player:getCards("he"))
	if #hs<1 then return end
	local cns = {}
	for _,p in sgs.qlist(self.room:getAlivePlayers())do
		for _,id in sgs.list(p:getPile("cang_ming"))do
			local c = sgs.Sanguosha:getCard(id)
			if self.player:getMark(c:objectName().."chouxiUse-Clear")>0
			or table.contains(cns,c:objectName()) then continue end
			if (c:getTypeId()==1 or c:isNDTrick()) then
				table.insert(cns,c:objectName())
			end
		end
	end
	for _,cn in sgs.list(RandomList(cns))do
		for _,h in sgs.list(hs)do
			local dc = dummyCard(cn)
			dc:setSkillName("chouxi")
			dc:addSubcard(h)
			if dc:isAvailable(self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					if dc:canRecast() and d.to:length()<1 then continue end
					self.chouxi_use = d
					sgs.ai_skill_choice.chouxi = cn
					return sgs.Card_Parse("@ChouxiCard=.:"..cn)
				end
			end
		end
	end
end

sgs.ai_skill_use_func["ChouxiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ChouxiCard = 5.4
sgs.ai_use_priority.ChouxiCard = 3.8

sgs.ai_skill_use["@@chouxi"] = function(self,prompt)
	local d = self.chouxi_use
	if d.card then
		local tps = {}
		for _,p in sgs.list(d.to)do
			table.insert(tps,p:objectName())
		end
		return d.card:toString().."->"..table.concat(tps,"+")
	end
end

sgs.ai_fill_skill.jichao = function(self)
	return sgs.Card_Parse("@JichaoCard=.")
end

sgs.ai_skill_use_func["JichaoCard"] = function(card,use,self)
	self:sort(self.enemies,nil,true)
	for i,to in sgs.list(self.enemies)do
		if to:getHandcardNum()>0 and to:hasEquip() then
			use.to:append(to)
			use.card = card
			return
		end
	end
	local n = 0
	for i,p in sgs.list(self.room:getAlivePlayers())do
		if p:getCardCount()>1 and not self:isFriend(p) then
			n = n+1
		else
			n = n-1
		end
	end
	if n>0 then
		use.card = card
	end
end

sgs.ai_use_value.JichaoCard = 5.4
sgs.ai_use_priority.JichaoCard = 7.8

sgs.ai_skill_invoke.kanyu = function(self,data)
	local judge = data:toJudge()
	if judge and judge.who then
		self.kanyu_judge = judge
		return self:isFriend(judge.who) or self:isWeak()
	end
	self.kanyu_judge = nil
	return self:isWeak() and self:canDraw()
end

sgs.ai_skill_askforag.kanyu = function(self,card_ids)
	if self.kanyu_judge then
		for i,id in sgs.list(card_ids)do
			if self.kanyu_judge:isGood(CardFilter(id,self.kanyu_judge.who)) then
				if self:isFriend(self.kanyu_judge.who) then
					return -1
				end
			else
				if self:isEnemy(self.kanyu_judge.who) then
					return -1
				end
			end
		end
	end
	if self:canDraw() then
		return card_ids[1]
	end
	return -1
end

sgs.ai_skill_invoke.chongzhu = function(self,data)
	return true
end

sgs.ai_skill_playerchosen.chongzhu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p,"N",self.player)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if not self:isFriend(p) and self:damageIsEffective(p,"N",self.player)
		then return p end
	end
end

sgs.ai_skill_invoke.zhenting = function(self,data)
	local dps = data:toStringList()
	for i,p in sgs.list(self.friends)do
		if table.contains(dps,p:objectName()) and self:isWeak(p) then
			return true
		end
	end
	for i,p in sgs.list(self.friends)do
		if p:getMark("zhentingDamaged-Clear")>0 and self:canDraw(p) then
			return true
		end
	end
end

sgs.ai_skill_playerchosen.zhenting = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then return p end
	end
end

sgs.ai_skill_invoke.chiguo = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_playerchosen.chiguo = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then return p end
	end
end

sgs.ai_use_revises.chiguo = function(self,card,use)
	--[[if self.player:getMark("chiguoBf-PlayClear")>0 then
		for i,id in sgs.qlist(self.player:getTag("chiguoBf"):toIntList())do
			if self.room:getDrawPile():contains(id) then
				if card:getSuit()==sgs.Sanguosha:getCard(id):getSuit() then
					break
				end
				return false
			end
		end
	end]]
end

sgs.ai_skill_playerchosen.thjizhan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p,"N",self.player)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if not self:isFriend(p) and self:damageIsEffective(p,"N",self.player)
		then return p end
	end
end

sgs.ai_skill_playerchosen.zhiwang = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for i,p in sgs.list(destlist)do
		if self.zhiwang_to==p
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then return p end
	end
end

sgs.ai_skill_askforag.zhiwang = function(self,card_ids)
	self.zhiwang_to = nil
	for i,id in sgs.list(card_ids)do
		local c = sgs.Sanguosha:getCard(id)
		for _,fp in sgs.list(self.friends_noself)do
			if c:isAvailable(fp) and sgs.ais[fp:objectName()]:aiUseCard(c).card then
				self.zhiwang_to = fp
				return id
			end
		end
	end
	return card_ids[1]
end

sgs.ai_skill_use["@@zhiwang!"] = function(self,prompt)
	local c = sgs.Sanguosha:getCard(self.player:getMark("zhiwangId"))
	local d = self:aiUseCard(c)
	if d.card then
		local tps = {}
		for _,p in sgs.qlist(d.to)do
			table.insert(tps,p:objectName())
		end
		return c:toString().."->"..table.concat(tps,"+")
	end
	if c:targetFixed() then
		return c:toString()
	end
	local aps = sgs.SPlayerList()
	for _,p in sgs.qlist(self.room:getAlivePlayers())do
		if self.player:canUse(c,p) then
			aps:append(p)
			if c:targetsFeasible(aps,self.player) then
				local tps = {}
				for _,p in sgs.qlist(aps)do
					table.insert(tps,p:objectName())
				end
				return c:toString().."->"..table.concat(tps,"+")
			end
		end
	end
end

sgs.ai_skill_use["@@qiaodui"] = function(self,prompt)
	local use = self.player:getTag("qiaodui_data"):toCardUse()
	if use.from==self.player then
		if self:isEnemy(use.to:at(0)) then
			
		else
			return
		end
	else
		if self:isWeak() and use.card:isDamageCard() then
			
		else
			return
		end
	end
	self:sort(self.friends_noself)
	local hs = self:sortByKeepValue(self.player:getCards("he"))
	for i,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) then
			return "@QiaoduiCard="..hs[1].."->"..p:objectName()
		end
	end
	for i,p in sgs.list(self.room:getAlivePlayers())do
		if self.player~=p and not self:isEnemy(p) then
			return "@QiaoduiCard="..hs[1].."->"..p:objectName()
		end
	end
end

sgs.ai_skill_playerchosen.chiguo0 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	local use = self.player:getTag("chiguo_data"):toCardUse()
	self:sort(destlist)
    for i,p in sgs.list(destlist)do
		if use.to:contains(p) then
			continue
		end
		if self:canCanmou(p,use)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if use.to:contains(p) then
			if use.card:isDamageCard() then
				if self:isFriend(p) and self:isWeak(p) then
					return p
				end
			elseif use.to:contains(self.player) and use.card:targetFixed() then
				if self:isEnemy(p) then
					return p
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen.chiguo1 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then return p end
	end
end

sgs.ai_skill_playerchosen.juce = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	local use = self.player:getTag("juce_data"):toCardUse()
	self:sort(destlist)
    for i,p in sgs.list(destlist)do
		if self:canCanmou(p,use)
		then return p end
	end
end

sgs.ai_skill_invoke.kangming = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_cardask.kangming0 = function(self,data,pattern)
    local use = data:toCardUse()
    for i,id in sgs.list(pattern:split(","))do
		local c = sgs.Sanguosha:getCard(id)
		local dc = dummyCard(c:objectName(),"kangming")
		local d = self:aiUseCard(dc)
		if d.card then
			if d.to:contains(use.from) then
				return id
			end
			if c:isDamageCard() then
				if self:isEnemy(use.from) then
					return id
				end
			else
				if d.to:length()<1 then
					if self:isFriend(use.from) then
						return id
					end
				else
					if self:isFriend(d.to:at(0))==self:isFriend(use.from) then
						return id
					end
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_cardask["junmou0"] = function(self,data)
	if self.player:getChangeSkillState("junmou")==2
	or not self:isWeak() or self:getOverflow()>0
   	then return true end
    return "."
end

sgs.ai_skill_invoke.junmou = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_playerschosen.junmou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local tps = {}
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p) and #tps<2
		then table.insert(tps,p) end
	end
    for i,p in sgs.list(destlist)do
		if not self:isFriend(p) and #tps<2
		then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_fill_skill.zhanyan = function(self)
	return sgs.Card_Parse("@ZhanyanCard=.")
end

sgs.ai_skill_use_func["ZhanyanCard"] = function(card,use,self)
	self:sort(self.enemies)
	for i,p in sgs.list(self.enemies)do
		if p:isChained() and p:getHandcardNum()>0 then
			use.to:append(p)
		end
	end
	if use.to:length()>#self.enemies/2 then
		use.card = card
	end
	if self:isWeak() then
		for i,p in sgs.list(self.room:getAlivePlayers())do
			if self:isFriend(p) or use.to:contains(p) then continue end
			if p:isChained() and p:getHandcardNum()>0 then
				use.to:append(p)
			end
		end
	end
end

sgs.ai_use_value.ZhanyanCard = 5.4
sgs.ai_use_priority.ZhanyanCard = 0.8

sgs.ai_skill_use["@@zhanyan"] = function(self,prompt)
	local c = sgs.Card_Parse("@ZhanyanCard=.")
	local d = self:aiUseCard(c)
	if d.card then
		local tps = {}
		for _,p in sgs.qlist(d.to)do
			table.insert(tps,p:objectName())
		end
		return c:toString().."->"..table.concat(tps,"+")
	end
end

sgs.ai_skill_cardask["zhanyan0"] = function(self,data)
	if self:isEnemy(data:toPlayer()) or self:getOverflow()>0
   	then return true end
    return "."
end

sgs.ai_skill_discard.qinqiang = function(self,m,x)
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(handcards) -- 按保留值排序
	local ids = {}
	for _,h in sgs.list(handcards)do
		table.insert(ids,h:getId())
		if #ids>#handcards/2 then break end
	end
	return ids
end

sgs.ai_skill_invoke.shugang = function(self,data)
	return self:canDraw()
end

sgs.ai_fill_skill.shugang = function(self)
	for _,c in sgs.list(self.player:getCards("he"))do
		if c:hasTip("shugang") then
			local cs = {}
			for _,cn in sgs.list(patterns())do
				local dc = dummyCard(cn)
				if dc:isDamageCard() then
					dc:setSkillName("shugang")
					dc:addSubcard(c)
					if dc:isAvailable(self.player) then
						table.insert(cs,dc)
					end
				end
			end
			return cs
		end
	end
end

sgs.ai_fill_skill.dianlun = function(self)
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    if #handcards<1 then return end
	handcards = self:sortByKeepValue(handcards,nil,"j") -- 按保留值排序
	local ids = {}
	for _,h1 in sgs.list(handcards)do
		local ids2 = {h1}
		for _,h2 in sgs.list(handcards)do
			if table.contains(ids2,h2) then continue end
			if #ids2>1 then
				local x = math.abs(ids2[1]:getNumber()-ids2[2]:getNumber())
				if x==math.abs(ids2[1]:getNumber()-h2:getNumber())
				or x==math.abs(ids2[#ids2]:getNumber()-h2:getNumber()) then
					
				else
					continue
				end
			end
			table.insert(ids2,h2)
			if #ids2>=#handcards/2 then 
				break
			end
		end
		if #ids2>=#handcards/2 then 
			for _,c in sgs.list(ids2)do
				table.insert(ids,c:getId())
			end
			break
		end
	end
	return #ids>0 and sgs.Card_Parse("@DianlunCard="..table.concat(ids,"+"))
end

sgs.ai_skill_use_func["DianlunCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.DianlunCard = 5.4
sgs.ai_use_priority.DianlunCard = 6.8

sgs.ai_skill_use["@@dianlun"] = function(self,prompt)
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    if #handcards<1 then return end
	handcards = self:sortByKeepValue(handcards,nil,"j") -- 按保留值排序
	local ids = {}
	for _,h1 in sgs.list(handcards)do
		local ids2 = {h1}
		for _,h2 in sgs.list(handcards)do
			if table.contains(ids2,h2) then continue end
			if #ids2>1 then
				local x = math.abs(ids2[1]:getNumber()-ids2[2]:getNumber())
				if x==math.abs(ids2[1]:getNumber()-h2:getNumber())
				or x==math.abs(ids2[#ids2]:getNumber()-h2:getNumber()) then
					
				else
					continue
				end
			end
			table.insert(ids2,h2)
			if #ids2>=#handcards/2 or #ids2>2 then 
				break
			end
		end
		if #ids2>=#handcards/2 or #ids2>2 then 
			for _,c in sgs.list(ids2)do
				table.insert(ids,c:getId())
			end
			break
		end
	end
	if #ids>0 then
		return "@DianlunCard="..table.concat(ids,"+")
	end
end

sgs.ai_fill_skill.thjiweivs = function(self)
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    if #handcards<1 or self:getOverflow()<1 then return end
	handcards = self:sortByKeepValue(handcards) -- 按保留值排序
	return sgs.Card_Parse("@ThJiweiCard="..handcards[1]:getId())
end

sgs.ai_skill_use_func["ThJiweiCard"] = function(card,use,self)
	self:sort(self.friends_noself)
	for i,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) and p:hasSkill("thjiwei") then
			use.to:append(p)
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.ThJiweiCard = 5.4
sgs.ai_use_priority.ThJiweiCard = 4.8

sgs.ai_skill_playerchosen.duoyue = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p,"N",self.player)
		then return p end
	end
	self:sort(destlist,nil,true)
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and self:getOverflow(p)>0
		and p:getKingdom()=="wei" and not self:isWeak(p)
		then return p end
	end
end

sgs.ai_skill_invoke.duoyue = function(self,data)
    local str = data:toString()
	for i,p in sgs.list(self.friends)do
		if str:endsWith(p:objectName()) then
			return self:canDraw(P)
		end
	end
end

sgs.ai_skill_use["@@junhe"] = function(self,prompt)
    local cards = sgs.QList2Table(self.player:getCards("he"))
    if #cards<1 then return end
	local ids = {}
	local cts = {}
	for _,c in sgs.list(cards)do
		cts[c:getColorString()] = (cts[c:getColorString()] or 0)+1
		cts[c:getType()] = (cts[c:getType()] or 0)+1
	end
	local x = 0
	for t,n in pairs(cts)do
		x = math.max(x,n)
	end
	local r = ""
	for t,n in pairs(cts)do
		if n>=x then
			r = t
		end
	end
	for _,c in sgs.list(cards)do
		if c:getColorString()==r or c:getType()==r then
			table.insert(ids,c:getId())
		end
	end
	if #ids>0 then
		return "@JunheCard="..table.concat(ids,"+")
	end
end

sgs.ai_skill_cardask["junhe1"] = function(self,data)
	local damage = data:toDamage()
	if self:isEnemy(damage.to)
   	then return true end
    return "."
end

sgs.ai_skill_choice.xiongwei = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if self:isFriend(target) then
		for i,t in sgs.list(items)do
			if i>=#items/2 then
				return t
			end
		end
	end
	return items[#items]
end

sgs.ai_fill_skill.zongtao = function(self)
	return sgs.Card_Parse("@ZongtaoCard=.")
end

sgs.ai_skill_use_func["ZongtaoCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ZongtaoCard = 5.4
sgs.ai_use_priority.ZongtaoCard = 8.8

sgs.ai_skill_choice.zongtao = function(self,choices,data)
	local items = choices:split("+")
	return items[math.random(1,#items-1)]
end

sgs.ai_skill_choice.thjizhanmc = function(self,choices,data)
	local items = choices:split("+")
	local n = self.player:getMark("thjizhanmcUse-Clear")
	for i,p in sgs.list(self.enemies)do
		if (p:getHp()<=n or self:isWeak(p)) and self:damageIsEffective(p,"N",self.player) then
			self.thjizhanmc2 = true
			return items[2]
		end
	end
	return items[1]
end

sgs.ai_skill_playerchosen.thjizhanmc = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	if self.thjizhanmc2 then
		self.thjizhanmc2 = false
		for i,p in sgs.list(destlist)do
			if self:isEnemy(p) and self:damageIsEffective(p,"N",self.player)
			then return p end
		end
	end
    for i,p in sgs.list(destlist)do
		if self:doDisCard(p,"he")
		then return p end
	end
	for i,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
end

sgs.ai_fill_skill.zhifeng = function(self)
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    if #handcards<1 then return end
	handcards = self:sortByKeepValue(handcards) -- 按保留值排序
	local n = #handcards-self.player:getHp()
	if n>0 then
		for i,h in sgs.list(handcards)do
			if h:isBlack() then
				local dc = dummyCard("analeptic","zhifeng")
				dc:addSubcard(h)
				if dc:isAvailable(self.player) then
					return dc
				end
			end
		end
	elseif n<1 then
		for i,h in sgs.list(handcards)do
			if h:isRed() then
				local dc = dummyCard("slash","zhifeng")
				dc:addSubcard(h)
				if dc:isAvailable(self.player) then
					return dc
				end
			end
		end
	else
		for i,h in sgs.list(handcards)do
			local dc = dummyCard("duel","zhifeng")
			dc:addSubcard(h)
			if dc:isAvailable(self.player) then
				return dc
			end
		end
	end
end

function sgs.ai_cardsview.zhifeng(self,class_name,player)
	local cards = sgs.QList2Table(player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		if class_name=="Slash" then
			if c:isRed() then
				local dc = dummyCard("slash","zhifeng")
				dc:addSubcard(c)
				return dc:toString()
			end
		elseif class_name=="Analeptic" then
			if c:isBlack() then
				local dc = dummyCard("analeptic","zhifeng")
				dc:addSubcard(c)
				return dc:toString()
			end
		else
			local dc = dummyCard("duel","zhifeng")
			dc:addSubcard(c)
			return dc:toString()
		end
	end
end

sgs.ai_skill_invoke.thweijing = function(self,data)
    local tp = data:toPlayer()
	return self:isEnemy(tp) or self:getOverflow(tp)>=0
end

sgs.ai_skill_choice.thweijing = function(self,choices,data)
	local items = choices:split("+")
    local tp = data:toPlayer()
	if self:isEnemy(tp) then
		return items[1]
	end
	return items[2]
end

sgs.ai_skill_use["@@zhifeng"] = function(self,prompt)
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    if #handcards<1 then return end
	handcards = self:sortByKeepValue(handcards) -- 按保留值排序
	local n = #handcards-self.player:getHp()
	if n>0 then
		for i,h in sgs.list(handcards)do
			if h:isBlack() then
				local dc = dummyCard("analeptic","zhifeng")
				dc:addSubcard(h)
				if dc:isAvailable(self.player) then
					local d = self:aiUseCard(dc)
					if d.card then
						local tps = {}
						for _,p in sgs.qlist(d.to)do
							table.insert(tps,p:objectName())
						end
						return dc:toString().."->"..table.concat(tps,"+")
					end
				end
			end
		end
	elseif n<1 then
		for i,h in sgs.list(handcards)do
			if h:isRed() then
				local dc = dummyCard("slash","zhifeng")
				dc:addSubcard(h)
				if dc:isAvailable(self.player) then
					local d = self:aiUseCard(dc)
					if d.card then
						local tps = {}
						for _,p in sgs.qlist(d.to)do
							table.insert(tps,p:objectName())
						end
						return dc:toString().."->"..table.concat(tps,"+")
					end
				end
			end
		end
	else
		for i,h in sgs.list(handcards)do
			local dc = dummyCard("duel","zhifeng")
			dc:addSubcard(h)
			if dc:isAvailable(self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					local tps = {}
					for _,p in sgs.qlist(d.to)do
						table.insert(tps,p:objectName())
					end
					return dc:toString().."->"..table.concat(tps,"+")
				end
			end
		end
	end
end

sgs.ai_fill_skill.shuren = function(self)
	if self:isWeak() then
		for i=4,0,-1 do
			if self.player:hasEquipArea(i) and self.player:getEquip(i) then
				sgs.ai_skill_choice.shuren = "EquipArea"..i
				return sgs.Card_Parse("@ShurenCard=.")
			end
		end
	else
		for i=4,0,-1 do
			if self.player:hasEquipArea(i) then
				sgs.ai_skill_choice.shuren = "EquipArea"..i
				return sgs.Card_Parse("@ShurenCard=.")
			end
		end
	end
end

sgs.ai_skill_use_func["ShurenCard"] = function(card,use,self)
	self:sort(self.friends_noself)
	for i,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.ShurenCard = 5.4
sgs.ai_use_priority.ShurenCard = 1.8

sgs.ai_skill_choice.sharan = function(self,choices,data)
	local items = choices:split("+")
	return items[1]
end











