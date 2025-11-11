sgs.shifa_skills = {}
sgs.wangxing_skills = {}
function addToSkills(skill)
	if sgs.Sanguosha:getSkill(skill:objectName()) then return end
		local skills = sgs.SkillList()
		skills:append(skill)
		sgs.Sanguosha:addSkills(skills)
	end
function CardIsAvailable(player,name,sn,suit,num)
	local dc = sgs.Sanguosha:cloneCard(name or "slash",suit or -1,num or 0)
	if dc then
    	if sn then dc:setSkillName(sn) end
    	dc:deleteLater()
    	if dc:isAvailable(player)
    	then return dc end
	end
end
function string:cardAvailable(player,sn,suit,num)
	return CardIsAvailable(player,self,sn,suit,num)
end
function AgCardsToName(player,type_ids,NODT,no_names)
	no_names = no_names or {}
	local tocs,toids = {},sgs.IntList()
	type_ids = type_ids or "basic+trick"
	for c,id in sgs.list(sgs.Sanguosha:getRandomCards())do
    	c = sgs.Sanguosha:getEngineCard(id)
		if NODT and c:isKindOf("DelayedTrick")
		or table.contains(tocs,c:objectName())
		or table.contains(no_names,c:objectName())
		then continue end
	    if c:isAvailable(player)
		and string.find(type_ids,c:getType())
		then
        	table.insert(tocs,c:objectName())
			toids:append(c:getId())
		end
   	end
	if toids:isEmpty() then return end
	local room = player:getRoom()
   	room:fillAG(toids,player)
   	toids = room:askForAG(player,toids,false,"AgCardsToName")
   	room:clearAG(player)
	return sgs.Sanguosha:getCard(toids):objectName()
end
function ShimingSkillDoAnimate(self,player,success,gn)
	if self and type(self)~="string" then self = self:objectName() end
	success = success and "Successful" or "Fail"
	local msg = sgs.LogMessage()
	msg.type = "#ShimingSkillDoAnimate"
	msg.from = player
	msg.arg = self
	msg.arg2 = success
	local room = player:getRoom()
	room:sendLog(msg)
	msg = player:getGeneral2()
	if msg and msg:hasSkill(self)
	then gn = gn or player:getGeneral2Name() end
	gn = gn or player:getGeneralName()
	room:doSuperLightbox(gn,success)
end
function SkillWakeTrigger(self,player,n,gn)
	if self and type(self)~="string" then self = self:objectName() end
	local room = player:getRoom()
	local log = sgs.LogMessage()
	log.type = "$SkillWakeTrigger"
	log.from = player
	log.arg = self
	room:sendLog(log)
	n = n or -1
	room:sendCompulsoryTriggerLog(player,self)
	room:addPlayerMark(player,self)
	room:broadcastSkillInvoke(self,player)--播放配音
	log = player:getGeneral2()
	if log and log:hasSkill(self)
	then gn = gn or player:getGeneral2Name() end
	gn = gn or player:getGeneralName()
	room:doSuperLightbox(gn,self)
	room:changeMaxHpForAwakenSkill(player,n)
	player:setTag(self,sgs.QVariant(true))
end
function NotifySkillInvoked(self,player,tos,num)
	local room = player:getRoom()
	if self and type(self)~="string" then self = self:objectName() end
  	if type(num)=="number" then room:broadcastSkillInvoke(self,num)
	elseif num~=false then room:broadcastSkillInvoke(self) end
	local msg = sgs.LogMessage()
	msg.type = "$NotifySkillInvoked_2"
  	if tos and tos:length()>0 then
    	msg.type = "$NotifySkillInvoked_1"
		for _,p in sgs.list(tos)do
			room:doAnimate(1,player:objectName(),p:objectName())
			msg.to:append(p)
		end
	end
	msg.from = player
	msg.arg = self
	room:sendLog(msg)
end
function PlayerChosen(self,player,tos,prompt,optional)
	local room = player:getRoom()
	optional = optional==true
	if self and type(self)~="string" then self = self:objectName() end
	tos = tos or room:getAlivePlayers()
	if not prompt
	then
		prompt = "PlayerChosen0:"..self
		if optional then prompt = "PlayerChosen1:"..self end
	end
	local to = room:askForPlayerChosen(player,tos,self,prompt,optional)
	local msg = sgs.LogMessage()
	msg.type = "$PlayerChosen"
	msg.from = player
	msg.arg = self
	if to
	then
		msg.to:append(to)
		room:sendLog(msg)
		room:doAnimate(1,player:objectName(),to:objectName())
		return to
	end
end
function hasCard(player,name,he)
	local cs = sgs.CardList()
	if name:match(",") then
		for _,n in sgs.list(name:split(","))do
			n = hasCard(player,n,he)
			if n then InsertList(cs,n) end
		end
		return cs:length()>0 and cs
	end
	he = he or "he"
	local hes = sgs.CardList()
	if he:match("h") then
		hes = player:getHandcards()
	end
	if he:match("e") then
		for _,c in sgs.list(player:getEquips())do
			hes:append(c)
		end
	end
	if he:match("j") then
		for _,c in sgs.list(player:getJudgingArea())do
			hes:append(c)
		end
	end
	if he:match("&") then
		for _,key in sgs.list(player:getPileNames())do
			if key:match("&") or key=="wooden_ox" then
				for _,id in sgs.list(player:getPile(key))do
					hes:append(sgs.Sanguosha:getCard(id))
				end
			end
		end
	end
	for _,c in sgs.list(hes)do
		if c:isKindOf(name) or c:objectName()==name
		then cs:append(c) end
	end
	return cs:length()>0 and cs
end
function getKingdoms(player)
	local kingdoms = {player:getKingdom()}
	for _,p in sgs.list(player:getAliveSiblings())do
		if table.contains(kingdoms,p:getKingdom()) then continue end
		table.insert(kingdoms,p:getKingdom())
	end
	return #kingdoms
end
function BfFire(player,to,n,struct)
	local damage = sgs.DamageStruct()
	damage.from = player or nil
	damage.to = to
	damage.damage = n or 1
	damage.nature = struct or sgs.DamageStruct_Fire
	to:getRoom():damage(damage)
end
function UseCardRecast(player,card,reason,n)
	card = type(card)=="number" and sgs.Sanguosha:getCard(card) or card
   	reason = reason or ""
	local r = string.sub(reason,1,1)
	local log = sgs.LogMessage()
	log.type = "$UseCardRecast"
   	log.from = player
  	log.card_str = table.concat(sgs.QList2Table(card:getSubcards()),"+")
	if r=="_" or r=="@" or r=="#" then
		log.type = "$UseCardRecast"..r
		reason = string.sub(reason,2,-1)
	end
	log.arg = reason
	local room = player:getRoom()
    room:broadcastSkillInvoke("@recast")
	if player:hasSkill(reason) then room:notifySkillInvoked(player,reason) end
	if r~="#" then room:sendLog(log) end
	reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST,player:objectName(),reason,"")
   	room:moveCardTo(card,player,nil,sgs.Player_DiscardPile,reason,true)
	n = type(n)=="number" and n or card:subcardsLength()
	return player:drawCardsList(n,"recast")
end
function RandomList(rl)
	local tolist = {}
	if type(rl)=="table" then
		for _,t in ipairs(rl)do
    	table.insert(tolist,t)
   	end
    	while #tolist>0 do
	    	local t = tolist[math.random(1,#tolist)]
			table.removeOne(tolist,t)
			table.removeOne(rl,t)
	    	table.insert(rl,t)
    	end
	else
		for _,t in sgs.qlist(rl)do
			table.insert(tolist,t)
		end
    	while #tolist>0 do
	    	local t = tolist[math.random(1,#tolist)]
			table.removeOne(tolist,t)
	    	rl:removeOne(t)
	    	rl:append(t)
    	end
	end
	return rl
end
function MoveFromPlaceIds(move,places)
	local ids = sgs.IntList()
   	for i,id in sgs.list(move.card_ids)do
    	if move.from_places:at(i)==places
		then ids:append(id) end
   	end
	return ids
end
function MovePlaceIds(room,ids,place)
	local toids = sgs.IntList()
   	for i,id in sgs.list(ids)do
		if room:getCardPlace(id)==place
		then toids:append(id) end
   	end
	return toids
end
function BeMan(room,owner,dead)
	if type(owner)=="userdata" then
		owner = owner:objectName()
	end
	for _,p in sgs.qlist(room:getPlayers())do
		if p:objectName()==owner and (dead~=true or p:isAlive())
		then return p end
	end
end
function dummyCard(name,suit,number,sn)
	if type(suit)=="string" then
		sn = suit
		suit = -1
	end
	local dc = sgs.Sanguosha:cloneCard(name or "slash", suit or -1, number or 0)
	if dc then
		if sn then dc:setSkillName(sn) end
		dc:deleteLater()
		return dc
	end
end
function ToData(self)
	if type(self)=="boolean" then return sgs.QVariant(self) end
	local data = sgs.QVariant()
	data:setValue(self or "")
	return data
end
function ToSkillInvoke(self,player,to,data,n)
	if self and type(self)~="string" then self = self:objectName() end
	data = data or to and to~=true and ToData(to) or sgs.QVariant()
	local room = player:getRoom()
	local msg = sgs.LogMessage()
	msg.type = "$ToSkillInvoke"
	msg.from = player
	msg.arg = self
	local function Invoke()
		if type(n)=="number" then room:broadcastSkillInvoke(self,n)
		elseif n~=false then room:broadcastSkillInvoke(self) end
	end
	if to==true then
		Invoke()
		if player:hasSkill(self) then room:notifySkillInvoked(player,self) end
		room:sendLog(msg)
		return true
	elseif data==true and to then
		Invoke()
		if player:hasSkill(self) then room:notifySkillInvoked(player,self)
		elseif to:hasSkill(self) then room:notifySkillInvoked(to,self) end
		room:doAnimate(1,player:objectName(),to:objectName())
		msg.type = "$ToSkillInvoke3"
		msg.to:append(to)
		room:sendLog(msg)
		return true
	elseif to then
		if player:askForSkillInvoke(self,data,false) then
			Invoke()
			if player:hasSkill(self) then room:notifySkillInvoked(player,self)
			elseif to:hasSkill(self) then room:notifySkillInvoked(to,self) end
			room:doAnimate(1,player:objectName(),to:objectName())
			msg.type = "$ToSkillInvoke3"
			msg.to:append(to)
			room:sendLog(msg)
			return true
		end
	elseif player:askForSkillInvoke(self,data) then
		Invoke()
--		room:sendLog(msg)
		return true
	end
end
function YijiPreview(self,player,cards,bool,reason)
	local guojia = sgs.SPlayerList()
	local room = player:getRoom()
	guojia:append(player)
	reason = reason or sgs.CardMoveReason_S_REASON_PREVIEW
	self = type(self)=="string" and self or self:objectName()
	local move = sgs.CardsMoveStruct(cards,player,nil,sgs.Player_PlaceHand,sgs.Player_PlaceTable,
	sgs.CardMoveReason(reason,player:objectName(),self,nil))
	if bool then
		local slash = dummyCard()
		for _,id in sgs.list(cards)do
			if room:getCardPlace(id)~=sgs.Player_PlaceTable
			and room:getCardPlace(id)~=sgs.Player_DrawPile
			then slash:addSubcard(id) end
		end
		room:moveCardTo(slash,nil,sgs.Player_PlaceTable)
		move = sgs.CardsMoveStruct(cards,nil,player,sgs.Player_PlaceTable,sgs.Player_PlaceHand,
		sgs.CardMoveReason(reason,player:objectName(),self,nil))
	end
	local moves = sgs.CardsMoveList()
	moves:append(move)
	room:notifyMoveCards(true,moves,false,guojia)
	room:notifyMoveCards(false,moves,false,guojia)
end
function PlayerHandcardNum(player,self,num)
	if self and type(self)~="string" then self = self:objectName() end
	local room = player:getRoom()
	local n = player:getHandcardNum()
	local msg = sgs.LogMessage()
	msg.type = "$PlayerHandcardNum"
	msg.from = player
	msg.arg = n
	msg.arg2 = num
	room:sendLog(msg)
	if n>num then room:askForDiscard(player,self,n-num,n-num)
	elseif num>n then room:drawCards(player,num-n,self) end
end
function AddSelectShownMark(targets,marks,source) --基于妹神的文字标记制作（膜拜）
    source = source or sgs.Self
	local alive = source:getAliveSiblings()
	alive:append(source)
	for _,p in sgs.list(alive)do
		for _,mark in ipairs(marks)do
	      	p:setMark("&"..mark,0)
		end
	end
	for i = 1,#targets do
    	if marks[i]=="" or marks[i]==nil
		then table.insert(marks,marks[1]) end
    	targets[i]:setMark("&"..marks[i],1)
	end
end
function SetCloneCard(card,name)
   	if name then
    	local slash = dummyCard(name)
      	slash:addSubcards(card:getSubcards())
     	for _,f in sgs.list(card:getFlags())do
	    	slash:setFlags(f)
    	end
    	return slash
	elseif card:isVirtualCard() then
		local s,n = sgs.Card_NoSuit,0
     	for _,id in sgs.list(card:getSubcards())do
			local c = sgs.Sanguosha:getCard(id)
			if card:subcardsLength()>1 then
				s = c:getColor()
				if sgs.Sanguosha:getCard(card:getSubcards():at(1)):getColor()~=s
				then s = sgs.Card_NoSuit break end
			else
				n = c:getNumber()
				s = c:getSuit()
			end
		end
    	card:setNumber(n)
     	card:setSuit(s)
	end
	return card
end
function Skill_msg(self,player,num)
	local room = player:getRoom()
	if type(self)~="string" then self = self:objectName() end
  	if type(num)=="number" then room:broadcastSkillInvoke(self,num) end
	if player:hasSkill(self,true) then room:notifySkillInvoked(player,self) end
  	local msg = sgs.LogMessage()
	msg.type = "#Skill_msg"
   	msg.from = player
	msg.arg = self
  	room:sendLog(msg)
end
function SkillInvoke(self,player,trigger,n)
	local room = player:getRoom()
	if self and type(self)~="string" then self = self:objectName() end
	if trigger then room:sendCompulsoryTriggerLog(player,self) end
 	if type(n)=="number" then room:broadcastSkillInvoke(self,n)
	else room:broadcastSkillInvoke(self) end
end
function ArmorNotNullified(target)
	return target:getMark("Armor_Nullified")<1
	and #target:getTag("Qinggang"):toStringList()<1
	and target:getMark("Equips_Nullified_to_Yourself")<1
end

sgs.LoadTranslationTable{
	["$TransferMark"] = "%from 将 %arg2 枚 %arg 转移给 %to",
	["$ToSkillInvoke2"] = "%from 发动 %arg2 的“%arg”",
	["$ToSkillInvoke"] = "%from 发动“%arg”",
	["$ToSkillInvoke3"] = "%from 对 %to 发动“%arg”",
	["$DamageRevises1"] = "%from 受到的 %arg 点伤害%arg3至 %arg2 点",
	["$DamageRevises2"] = "%from 造成的 %arg 点伤害%arg3至 %arg2 点",
	["$DamageRevises0"] = "%from 防止了此次 %arg 点伤害",
	["Damage+"] = "增加",
	["Damage-"] = "减少",
	["$PlayerHandcardNum"] = "%from 将手牌数从 %arg 张调整为 %arg2 张",
	["$UseCardRecast_"] = "%from 执行“%arg”的效果，重铸了 %card",
	["$UseCardRecast"] = "%from 重铸了 %card",
	["$UseCardRecast@"] = "%from 发动“%arg”，重铸了 %card",
	["#Skill_msg"] = "%from 的“%arg”效果触发",
	["$SkillWakeTrigger"] = "%from 的 %arg 觉醒条件达成",
	["$PlayerChosen"] = "%from 执行“%arg”的效果，选择了 %to",
	["PlayerChosen0"] = "%src：请选择一名角色",
	["PlayerChosen1"] = "%src：你可以选择一名角色",
	["#ShimingSkillDoAnimate"] = "%from 的 %arg %arg2",
	["Successful"] = "使命成功",
	["Fail"] = "使命失败",
	["BreakCard"] = "销毁",
	["#PhaseExtra"] = "%from 将执行一个额外的 %arg",
	["$BreakCard"] = "%from 销毁了 %card",
	["$zhengsu0"] = "%from 执行 %arg 的结果为 %arg2",
	["$shifa"] = "%from 选择了“%arg3”的 %arg 回合为 %arg2 ，“%arg3”的效果将于第 %arg2 个回合结束后生效",
	["shifa"] = "施法",
	["$shifa0"] = "%from“%arg”的 %arg2 效果生效",
	["$bf_huangtian0"] = "%from 发动 %arg 的“%arg2”",
	["@Equip0lose"] = "武器栏",
	["@Equip1lose"] = "防具栏",
	["@Equip2lose"] = "+马 ",
	["@Equip3lose"] = "-马 ",
	["@Equip4lose"] = "宝物栏",
	["Player_Start"] = "准备阶段",
	["Player_Judge"] = "判定阶段",
	["Player_Draw"] = "摸牌阶段",
	["Player_Play"] = "出牌阶段",
	["Player_Discard"] = "弃牌阶段",
	["Player_Finish"] = "结束阶段",
	["$NotifySkillInvoked_1"] = "%from 发动“%arg”，目标是 %to",
	["$NotifySkillInvoked_2"] = "%from 发动“%arg”",
	["basic_char"] = "基",
	["trick_char"] = "锦",
	["equip_char"] = "装",
	["zhengsu"] = "整肃",
	["zhengsu1"] = "擂进",
	["zhengsu2"] = "变阵",
	["zhengsu3"] = "鸣止",
	["zhengsu_successful"] = "成功",
	["zhengsu_fail"] = "失败",
	[":zhengsu1"] = "出牌阶段内，使用的牌点数递增且至少使用三张牌。",
	[":zhengsu2"] = "出牌阶段内，使用的牌花色均相同且至少使用两张牌。",
	[":zhengsu3"] = "弃牌阶段内，弃置的牌花色各不同且至少弃置两张牌。",
	[":&zhengsu+-+zhengsu1"] = "出牌阶段内，使用的牌点数递增且至少使用三张牌。",
	[":&zhengsu+-+zhengsu2"] = "出牌阶段内，使用的牌花色均相同且至少使用两张牌。",
	[":&zhengsu+-+zhengsu3"] = "弃牌阶段内，弃置的牌花色各不同且至少弃置两张牌。",
	["drawCards_2"] = "摸两张牌",
	["recover_1"] = "回复1点体力",
	["$zhengsu"] = "%from 选择执行 %arg 的 %arg2",
	["$jl_zhendian0"] = "%from 在“%arg”中选择了 %arg2",
	["bieshui"] = "背水",
	["Exchange:Exchange"] = "%src：是否与“%dest”中进行交换牌？",
	["Exchange0"] = "请选择牌交换至“%src”",
	["ExNihilo"] = "无中生有",
	["Dismantlement"] = "过河拆桥",
	["Nullification"] = "无懈可击",
	["Qizhengxiangsheng"] = "奇正相生",
	["Mantianguohai"] = "瞒天过海",
	["Tiaojiyanmei"] = "调剂盐梅",
	["Binglinchengxia"] = "兵临城下",
	["beishui_choice"] = "背水 %src",
	[":beishui_choice"] = "依次执行上面所有的选项",
	["shifa1"] = "X为1且于1个回合结束时执行",
	["shifa2"] = "X为2且于2个回合结束时执行",
	["shifa3"] = "X为3且于3个回合结束时执行",
	["$ov_baonieNum0"] = "%from 获得了 %arg 点 %arg2",
	["$ov_baonieNum1"] = "%from 消耗了 %arg 点 %arg2",
	["ov_baonieNum"] = "暴虐值",
	["$PlaceSpecial0"] = "%from 从 %to 的“%arg”中获得 %arg2 张牌 %card",
	["$PlaceSpecial1"] = "%from 从 %to 的“%arg”中获得 %arg2 张牌",
	["$wangxing"] = "%from“%arg3”选择“%arg”的值为 %arg2",
	["$wangxing0"] = "%from“%arg3”的“%arg2”效果触发，需弃置 %arg 张牌，否则扣减1点体力上限",
	["wangxing0"] = "%dest-妄行：请弃置%src张牌，否则将扣减1点体力上限",
	["wangxing"] = "妄行",
	["$targetsPindian0"] = "%from 为此次%arg2中唯一最大点数 %arg ，%from获得%arg2胜利",
	["$targetsPindian1"] = "此次%arg2中最大点数 %arg 重复，无人获得%arg2胜利",
	["MoveField0"] = "%src：请选择一名角色转移牌",
	["MoveField1"] = "%src：请选择一名角色成为此【%dest】转移的目标",
	["rebelish"] = "叛逆",
	["loyalish"] = "忠诚",
	["dilemma"] = "两难",
	["neutral"] = "未知",
	["DTjudge"] = "开始判定",
	["basic_card"] = "基本牌",
	["trick_card"] = "锦囊牌",
	["equip_card"] = "装备牌",
}

function ListI2C(intlist)
	local cs = sgs.CardList()
	for _,id in sgs.list(intlist)do
		cs:append(sgs.Sanguosha:getCard(id))
	end
	return cs
end
function ListC2I(cardlist)
	local ids = sgs.IntList()
	for _,c in sgs.list(cardlist)do
		ids:append(c:getEffectiveId())
	end
	return ids
end
function PhaseExtra(player,tophase,log)
	local room = player:getRoom()
	if log~=false
	then
    	local log = sgs.LogMessage()
    	log.type ="#PhaseExtra"
    	log.from = player
		if tophase==sgs.Player_Start
		then log.arg = "Player_Start"
		elseif tophase==sgs.Player_Judge
		then log.arg = "Player_Judge"
		elseif tophase==sgs.Player_Draw
		then log.arg = "Player_Draw"
		elseif tophase==sgs.Player_Play
		then log.arg = "Player_Play"
		elseif tophase==sgs.Player_Discard
		then log.arg = "Player_Discard"
		elseif tophase==sgs.Player_Finish
		then log.arg = "Player_Finish" end
    	room:sendLog(log)
	end
	local player_phase = player:getPhase()
	local thread = room:getThread()
	player:setPhase(tophase)
	room:broadcastProperty(player,"phase")
	if not thread:trigger(sgs.EventPhaseStart,room,player)
	then thread:trigger(sgs.EventPhaseProceeding,room,player) end
	thread:trigger(sgs.EventPhaseEnd,room,player)
	player:setPhase(player_phase)
	room:broadcastProperty(player,"phase")
end
function getPileSuitNum(Pile,suit)
	local suits = {}
	for _,c in sgs.list(Pile)do
		local s = c:getSuitString()
		if suit then if s==suit then table.insert(suits,c) end
		elseif not table.contains(suits,s) then table.insert(suits,s) end
	end
   	return #suits
end
function MovePlayerCard(player,players,Pile,reason,prompt)
	local room = player:getRoom()
	local totos = sgs.SPlayerList()
	for _,p in sgs.list(players)do
    	local can
		for _,c in sgs.list(p:getCards(Pile))do
    		can = true
			break
		end
		if can
		then
			totos:append(p)
		end
	end
	totos = room:askForPlayerChosen(player,totos,reason,prompt)
	local id = room:askForCardChosen(player,totos,Pile,reason)
	local card = sgs.Sanguosha:getCard(id)
	local place = room:getCardPlace(id)
	local index = -1
	if place==sgs.Player_PlaceEquip
	then
		index = card:getRealCard():toEquipCard():location()
	end
	local tos = sgs.SPlayerList()
	for _,p in sgs.list(room:getAlivePlayers())do
		if index~=-1
		then
			if not p:getEquip(index)
			then tos:append(p) end
		else
			if not player:isProhibited(p,card)
			and not p:containsTrick(card:objectName())
			then tos:append(p) end
		end
	end
	local tag,mx = sgs.QVariant(),sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER,player:objectName(),reason,"")
	tag:setValue(totos)
	room:setTag("QiaobianTarget",tag)
	local to1 = room:askForPlayerChosen(player,tos,reason,prompt)
	if to1 then room:moveCardTo(card,totos,to1,place,mx) end
	room:removeTag("QiaobianTarget")
end
function Log_message(msg_type,from,to,cid,arg,arg2,arg3,arg4,arg5)
	cid = cid and type(cid)~="number" and type(cid)~="string" and cid:getEffectiveId() or cid
	local room = from and from:getRoom() or to and to:length()>0 and to:at(0):getRoom()
	local msg = sgs.LogMessage()
	msg.type = msg_type
	msg.from = from or nil
	msg.to = to or sgs.SPlayerList()
	msg.card_str = cid or "."
	msg.arg = arg or "."
	msg.arg2 = arg2 or "."
	msg.arg3 = arg3 or "."
	msg.arg4 = arg4 or "."
	msg.arg5 = arg5 or "."
	room:sendLog(msg)
end
function BreakCard(player,card)
	card = type(card)=="number" and sgs.Sanguosha:getCard(card) or card
	if card:getEffectiveId()<0 then return end
	local toids = sgs.IntList()
	for _,id in sgs.list(card:getSubcards())do
		toids:append(id)
	end
	local room = player:getRoom()
	local msg = sgs.LogMessage()
	msg.type = "$BreakCard"
	msg.from = player
	msg.card_str = table.concat(sgs.QList2Table(toids,"+"))
	room:sendLog(msg)
	for _,id in sgs.list(room:getTag("BreakCard"):toIntList())do
		if room:getCardPlace(id)==sgs.Player_PlaceTable
		then toids:append(id) end
	end
	room:setTag("BreakCard",ToData(toids))
	msg = sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON,player:objectName(),"BreakCard","")
   	room:moveCardTo(card,nil,sgs.Player_PlaceTable,msg,true)
end
function SearchCard(player,card_names)
	local cs = sgs.CardList()
	local function SearchCardNames(c)
    	if type(card_names)=="table" then
			if table.contains(card_names,c:objectName())
			or table.contains(card_names,c:getClassName())
			then return true end
		elseif string.find(card_names,c:objectName())
		or string.find(card_names,c:getClassName())
		then return true end
	end
	local room = player:getRoom()
	for _,c in sgs.list(room:getDiscardPile())do
		c = sgs.Sanguosha:getCard(c)
		if SearchCardNames(c) then cs:append(c) end
	end
   	for _,p in sgs.list(room:getAlivePlayers())do
		for _,c in sgs.list(p:getCards("ej"))do
			if SearchCardNames(c) then cs:append(c) end
		end
	end
	return cs
end
function ThrowEquipArea(self,player,cancel,invoke,n,x)
	if self and type(self)~="string" then self = self:objectName() end
	local choices = {}
	n = n or 0
	x = x or 4
	for i=n,x do
		if player:hasEquipArea(i)
		then
			table.insert(choices,"@Equip"..i.."lose")
		end
	end
	if #choices>0
	and (not invoke or player:askForSkillInvoke(self))
	then
		if cancel then table.insert(choices,"cancel") end
    	choices = player:getRoom():askForChoice(player,self,table.concat(choices,"+"))
    	if choices~="cancel"
    	then
	        choices = tonumber(string.sub(choices,7,7))
			player:throwEquipArea(choices)
    	    return choices
	    end
	end
	return -1
end
function ObtainEquipArea(self,player,cancel,invoke,n,x)
	if self and type(self)~="string" then self = self:objectName() end
	local choices = {}
	n = n or 0
	x = x or 4
	for i=n,x do
		if player:hasEquipArea(i) then continue end
		table.insert(choices,"@Equip"..i.."lose")
	end
	if #choices>0
	and (not invoke or player:askForSkillInvoke(self))
	then
    	if cancel then table.insert(choices,"cancel") end
		choices = player:getRoom():askForChoice(player,self,table.concat(choices,"+"))
    	if choices~="cancel" then
	        choices = tonumber(string.sub(choices,7,7))
	        player:obtainEquipArea(choices)
        	return choices
		end
	end
	return -1
end
function GetCardPlace(source,to_select)
    if source:getHandcards():contains(to_select)
	then return 1 end
    if source:getEquips():contains(to_select)
	then return 2 end
    if source:getJudgingArea():contains(to_select)
	then return 3 end
	return -1
end
function PatternsCard(name,islist,derivative)
  	local cards = {}
	if type(name)=="table" then
		for _,n in sgs.list(name)do
			local c = PatternsCard(n,islist,derivative)
			if type(c)=="table" then InsertList(cards,c)
			elseif c then return c end
		end
		return islist and cards
	elseif name:match(",") then
		for _,n in sgs.list(name:split(","))do
			local c = PatternsCard(n,islist,derivative)
			if type(c)=="table" then InsertList(cards,c)
			else return c end
		end
		return islist and cards
	end
	for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(derivative==true))do
		local c = sgs.Sanguosha:getEngineCard(id)
		if c:objectName()==name or c:isKindOf(name) then
			if islist then table.insert(cards,c)
			else return c end
		end
	end
	return islist and cards
end
function MarkRevises(player,mark1,mark2)
	local room = player:getRoom()
	if mark1:endsWith("_lun") then
		local mark = mark1:split("_lun")
		local c_m = mark[1].."+"..mark2
		for _,m in sgs.list(player:getMarkNames())do
			local n = player:getMark(m)
			if n<1 then continue end
			local to_m = m:split("_lun")
			if m:startsWith(mark[1])
			and m:endsWith("_lun") then
				c_m = to_m[1].."+"..mark2
				room:setPlayerMark(player,m,0)
				room:setPlayerMark(player,c_m.."_lun",n)
				return true
			end
		end
		room:addPlayerMark(player,c_m.."_lun")
		return true
	end
	local mark = mark1:split("-")
	local c_m = mark[1].."+"..mark2
	for _,m in sgs.list(player:getMarkNames())do
		local n = player:getMark(m)
		if n<1 then continue end
		local to_m = m:split("-")
		if m:startsWith(mark[1])
		and (#mark<2 or to_m[#to_m]==mark[#mark]) then
			c_m = to_m[1].."+"..mark2
			if #mark>1 then c_m = c_m.."-"..mark[#mark] end
			room:setPlayerMark(player,m,0)
			room:setPlayerMark(player,c_m,n)
			return true
		end
	end
	if #mark>1 then c_m = c_m.."-"..mark[#mark] end
	room:addPlayerMark(player,c_m)
	return true
end
function TransferMark(player,target,name,n)
	n = n or 1
	n = math.min(n,player:getMark(name))
	if n<1 then return end
   	local log = sgs.LogMessage()
   	log.type = "$TransferMark"
    log.from = player
    log.to:append(target)
 	log.arg = name
	if name:match("&") then
		log.arg = string.gsub(name,"&","")
	end
	if log.arg:match("+") then
		log.arg = log.arg:split("+")[1]
	end
 	log.arg2 = n
	local room = player:getRoom()
 	room:sendLog(log)
	room:removePlayerMark(player,name,n)
	room:addPlayerMark(target,name,n)
end
function ExchangePileCard(self,player,name,n,can_equipped,will,compulsory)
	local can_equipped,compulsory = can_equipped or false,compulsory or false
	if can_equipped and player:getCardCount()<1
	or player:getHandcardNum()<1 then return end
	if self and type(self)~="string" then self = self:objectName() end
	local room = player:getRoom()
	if compulsory or player:askForSkillInvoke("Exchange",sgs.QVariant("Exchange:"..self..":"..name),false) then
		local cids = player:getPile(name)
		local c,ids = dummyCard(),sgs.IntList()
		local guojia = sgs.SPlayerList()
		guojia:append(player)
		local reason = sgs.CardMoveReason_S_REASON_PREVIEW
		local move = sgs.CardsMoveStruct(cids,player,player,sgs.Player_PlaceSpecial,sgs.Player_PlaceHand,
		sgs.CardMoveReason(reason,player:objectName(),self,nil))
		local moves = sgs.CardsMoveList()
		moves:append(move)
		room:notifyMoveCards(true,moves,false,guojia)
		room:notifyMoveCards(false,moves,false,guojia)
		local x = n
		if will then x = 1 end
		local ns = room:askForExchange(player,self,n,x,can_equipped,"Exchange0:"..name,compulsory)
		move = sgs.CardsMoveStruct(cids,player,nil,sgs.Player_PlaceHand,sgs.Player_PlaceTable,
		sgs.CardMoveReason(reason,player:objectName(),self,nil))
		moves = sgs.CardsMoveList()
		moves:append(move)
		room:notifyMoveCards(true,moves,false,guojia)
		room:notifyMoveCards(false,moves,false,guojia)
		if ns and ns:subcardsLength()>0 then
			ids = dummyCard()
			for i,id in sgs.list(ns:getSubcards())do
				if cids:contains(id)
				then continue end
				ids:addSubcard(id)
			end
			for i,id in sgs.list(cids)do
				if ns:getSubcards():contains(id)
				then continue end
				c:addSubcard(id)
			end
			player:addToPile(name,ids)
			room:obtainCard(player,c)
		end
	end
end
function PreviewCards(self,player,cards,x,n,optional,prompt,throw)
	if cards:length()<1 then return end
	if self and type(self)~="string" then self = self:objectName() end
	local room,optional = player:getRoom(),optional or false
	local guojia = sgs.SPlayerList()
	guojia:append(player)
	local prompt = prompt or self
	local reason = sgs.CardMoveReason_S_REASON_PREVIEW
	local owner,place = room:getCardOwner(cards:at(0)),room:getCardPlace(cards:at(0))
	local move = sgs.CardsMoveStruct(cards,owner,player,place,sgs.Player_PlaceHand,
	sgs.CardMoveReason(reason,player:objectName(),self,nil))
	local moves = sgs.CardsMoveList()
	moves:append(move)
	room:notifyMoveCards(true,moves,false,guojia)
	room:notifyMoveCards(false,moves,false,guojia)
	local ns = table.concat(sgs.QList2Table(cards),",")
	player:setTag("PreviewCards",ToData(ns))
	if throw then ns = room:askForDiscard(player,self,x,n,true,optional,prompt,ns,self)
	else ns = room:askForExchange(player,self,x,n,true,prompt,optional,ns) end
	player:removeTag("PreviewCards")
	move = sgs.CardsMoveStruct(cards,player,nil,sgs.Player_PlaceHand,sgs.Player_PlaceTable,
	sgs.CardMoveReason(reason,player:objectName(),self,nil))
	moves = sgs.CardsMoveList()
	moves:append(move)
	room:notifyMoveCards(true,moves,false,guojia)
	room:notifyMoveCards(false,moves,false,guojia)
	return ns and ns:subcardsLength()>0 and ns
end
function CanToCard(card,from,to,tos)
	local plist = sgs.PlayerList()
	for _,p in sgs.list(tos or {})do
		plist:append(p)
	end
  	return card:targetFilter(plist,to,from)
end
function CardVisible(player,id,special)
	if type(id)~="number" then id = id:getEffectiveId() end
	local place = player:getRoom():getCardPlace(id)
	if place==sgs.Player_PlaceEquip or place==sgs.Player_PlaceJudge or place==sgs.Player_PlaceTable
	or place==sgs.Player_DiscardPile or place==sgs.Player_PlaceDelayedTrick then return true
	elseif special and place==sgs.Player_PlaceSpecial then
		place = player:getRoom():getCardOwner(id)
		return place:pileOpen(place:getPileName(id),player:objectName())
	end
end
function ThrowArea(player,n)
	if n==1 then
		local room = player:getRoom()
		local log = sgs.LogMessage()
		log.type = "#ThrowArea"
		log.from = player
		log.arg = "hand_area"
		room:sendLog(log)
		log = dummyCard()
		log:addSubcards(player:handCards())
		room:throwCard(log,nil)
		player:setTag("ThrowArea_"..n,sgs.QVariant(true))
		room:setPlayerMark(player,"@Handlose",1)
		return true
	elseif n==2 then
		player:throwJudgeArea()
		return true
	elseif n==3 then
		player:throwEquipArea()
		return true
	end
end
function ObtainArea(player,n)
	if n==1 then
		local room = player:getRoom()
		local log = sgs.LogMessage()
		log.type = "#ObtainArea"
		log.from = player
		log.arg = "hand_area"
		room:sendLog(log)
		player:setTag("ThrowArea_"..n,sgs.QVariant(false))
		room:setPlayerMark(player,"@Handlose",0)
		return true
	elseif n== 2 then
		player:obtainJudgeArea()
		return true
	elseif n==3 then
		player:obtainEquipArea()
		return true
	end
end
function GetStringLength(inputstr)
    local i,n = 1,0
    while type(inputstr)=="string" and #inputstr>0 do
        local count = 1
        local cur = string.byte(inputstr,i)
        if cur>239 then count = 4 -- 4字节字符
        elseif cur>223 then count = 3 -- 汉字
        elseif cur>128 then count = 2 -- 双字节字符
        else count = 1 end -- 单字节字符
        i = i+count
        n = n+1
        if i>#inputstr
		then break end
    end
    return n
end
function string:stringLength()
	return GetStringLength(self)
end
function ZhengsuChoice(player)
	local choices = {}
	for i = 1,3 do
		if player:getTag("zhengsu"..i):toBool() then continue end
		table.insert(choices,"zhengsu"..i)
	end
	if #choices<1 then return -1 end
	local room = player:getRoom()
	choices = room:askForChoice(player,"zhengsu",table.concat(choices,"+"))
	Log_message("$zhengsu",player,nil,nil,"zhengsu",choices)
	player:setTag(choices,ToData(true))
	room:setPlayerMark(player,"&zhengsu+-+"..choices,1)
	return tonumber(string.sub(choices,8,8))
end
function SetShifa(self,player,x)
	local room = player:getRoom()
	if self and type(self)~="string" then self = self:objectName() end
	if type(x)~="number" then x = room:askForChoice(player,"shifa","shifa1+shifa2+shifa3") end
	if x=="shifa1" then x = 1 elseif x=="shifa2" then x = 2 elseif x=="shifa3" then x = 3 end
    for t,m in ipairs(sgs.shifa_skills)do
		if m.name==self and m.playerId==player:objectName()
		then table.remove(sgs.shifa_skills,t) end
	end
	local shifa = {name=self,x=x,m=x,playerId=player:objectName()}
	table.insert(sgs.shifa_skills,shifa)
	room:setPlayerMark(player,"&"..self.."+-+shifa",x)
	Log_message("$shifa",player,nil,nil,"shifa",x,self)
	return shifa
end
sgs.ZhinangClassName = {"ExNihilo","Dismantlement","Nullification","Qizhengxiangsheng","Mantianguohai","Tiaojiyanmei","Binglinchengxia"}
function GainOvBaonieNum(target,n)
	local room = target:getRoom()
	n = tonumber(n)
	if n>0 then
		local x = 5-target:getTag("ov_baonieNum"):toInt()
		if x<1 then return end
		x = x<n and x or n
		local m = target:getTag("ov_baonieNum"):toInt()+x
		target:setTag("ov_baonieNum",ToData(m))
		room:setPlayerMark(target,"@ov_baonieNum",m)
		Log_message("$ov_baonieNum0",target,nil,nil,x,"ov_baonieNum")
	elseif n<0 then
		local x = target:getTag("ov_baonieNum"):toInt()
		if x<1 then return end
		x = x+n<1 and x or -n
		local m = target:getTag("ov_baonieNum"):toInt()-x
		target:setTag("ov_baonieNum",ToData(m))
		room:setPlayerMark(target,"@ov_baonieNum",m)
		Log_message("$ov_baonieNum1",target,nil,nil,x,"ov_baonieNum")
	end
	
end
function SetWangxing(self,player,x)
	local room = player:getRoom()
	if self and type(self)~="string" then self = self:objectName() end
	if type(x)~="number" then x = tonumber(room:askForChoice(player,"wangxing","1+2+3+4")) end
    for t,m in ipairs(sgs.wangxing_skills)do
		if m.name==self and m.playerId==player:objectName()
		then table.remove(sgs.wangxing_skills,t) end
	end
	local wangxing = {name=self,x=x,playerId=player:objectName()}
	table.insert(sgs.wangxing_skills,wangxing)
	room:setPlayerMark(player,"&"..self.."+-+wangxing-Clear",x)
	Log_message("$wangxing",player,nil,nil,"wangxing",x,self)
	return wangxing
end
function targetsPindian(self,player,targets)
	if self and type(self)~="string" then self = self:objectName() end
    local log = sgs.LogMessage()
    log.type = "#Pindian"
    log.from = player
	local to_names = {}
	for _,to in sgs.list(targets)do
		log.to:append(to)
		table.insert(to_names,to:objectName())
	end
	if log.to:length()<1 then return {} end
	--log.to:prepend(player)
	local room = player:getRoom()
    room:sendLog(log)
	player:setTag("targetsPindian_"..self,ToData(table.concat(to_names,"+")))
	local pd = sgs.PindianStruct()
	pd.from = player
	pd.reason = self
	local pd_to_card = {}
	local data = sgs.QVariant()
	for _,t in sgs.qlist(log.to)do
		pd.to = t
		pd.to_card = nil
		data:setValue(pd)
		room:getThread():trigger(sgs.AskforPindianCard,room,player,data)
		pd = data:toPindian()
		pd_to_card[t:objectName()] = pd.to_card
	end
	local pd_to_number = {}
	local moves = sgs.CardsMoveList()
	for _,t in sgs.qlist(log.to)do
		if not pd_to_card[t:objectName()] and not pd.from_card then
			local cs = room:askForPindianRace(player,t,self)
			if cs:length()<2 then continue end
			pd.from_card = cs:first()
			pd_to_card[t:objectName()] = cs:last()
		elseif not pd.from_card then
			pd.from_card = room:askForPindian(player,player,self)
		elseif not pd_to_card[t:objectName()] then
			pd_to_card[t:objectName()] = room:askForPindian(t,player,self)
		end
		if pd_to_card[t:objectName()] then
			pd_to_number[t:objectName()] = pd_to_card[t:objectName()]:getNumber()
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN,pd.from:objectName(),t:objectName(),pd.reason,"")
			moves:append(sgs.CardsMoveStruct(pd_to_card[t:objectName()]:getEffectiveId(),nil,sgs.Player_PlaceTable,reason))
		end
	end
	if pd.from_card then
		pd.from_number = pd.from_card:getNumber()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN,pd.from:objectName(),pd.reason,"")
		moves:append(sgs.CardsMoveStruct(pd.from_card:getEffectiveId(),nil,sgs.Player_PlaceTable,reason))
	end
	if moves:length()<2 then return {} end
	room:moveCardsAtomic(moves,true)
    log.type = "$PindianResult"
    log.from = pd.from
    log.card_str = pd.from_card:toString()
    room:sendLog(log)
	for _,t in sgs.qlist(log.to)do
		if pd_to_card[t:objectName()] then
			log.from = t
			log.card_str = pd_to_card[t:objectName()]:toString()
			room:sendLog(log)
		end
	end
	local numbers = {}
	for _,t in sgs.qlist(log.to)do
		pd.to_card = pd_to_card[t:objectName()]
		if not pd.to_card then continue end
		pd.to_number = pd_to_number[t:objectName()]
		pd.to = t
		data:setValue(pd)
		room:getThread():trigger(sgs.PindianVerifying,room,player,data)
		pd = data:toPindian()
		pd_to_number[t:objectName()] = pd.to_number
		table.insert(numbers,pd.to_number)
		if t~=log.to:last() then
			pd.from_number = pd.from_card:getNumber()
		else
			table.insert(numbers,pd.from_number)
		end
	end
	local maxNumbers = function(a,b)
		return a>b
	end
	table.sort(numbers,maxNumbers)
	local pd_ = {}
	pd_.from = pd.from
	pd_.reason = pd.reason
	pd_.from_card = pd.from_card
	pd_.from_number = pd.from_number
	pd_.to = sgs.SPlayerList()
	pd_.to_number = sgs.IntList()
	pd_.to_card = sgs.CardList()
	if numbers[1]==numbers[2] then
		pd_.success_owner = nil
		room:setEmotion(player,"no-success")
	elseif numbers[1]==pd.from_number then
		pd_.success_owner = player
		room:setEmotion(player,"success")
	end
	for _,t in sgs.qlist(log.to)do
		if pd_to_card[t:objectName()] then
			if numbers[1]~=numbers[2] and pd_to_number[t:objectName()]==numbers[1] then
				room:setEmotion(t,"success")
				pd_.success_owner = t
			else
				room:setEmotion(t,"no-success")
			end
			pd_.to:append(t)
			pd_.to_number:append(pd_to_number[t:objectName()])
			pd_.to_card:append(pd_to_card[t:objectName()])
		end
	end
	room:getThread():delay()
	log.arg = numbers[1]
	log.arg2 = "pindian"
	if pd_.success_owner then
		log.type = "$targetsPindian0"
		log.from = pd_.success_owner
	else
		log.type = "$targetsPindian1"
	end
	room:sendLog(log)
	for _,t in sgs.qlist(log.to)do
		pd.to_card = pd_to_card[t:objectName()]
		if not pd.to_card then continue end
		pd.to_number = pd_to_number[t:objectName()]
		pd.success = player==pd_.success_owner
		pd.to = t
		data:setValue(pd)
		room:getThread():trigger(sgs.Pindian,room,player,data)
	end
	moves = sgs.CardsMoveList()
	if pd.from_card and room:getCardPlace(pd.from_card:getEffectiveId())==sgs.Player_PlaceTable then
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN,pd.from:objectName(),pd.reason,"")
		moves:append(sgs.CardsMoveStruct(pd.from_card:getEffectiveId(),nil,sgs.Player_DiscardPile,reason))
	end
	for _,t in sgs.qlist(log.to)do
		local c = pd_to_card[t:objectName()]
		if not c or room:getCardPlace(c:getEffectiveId())~=sgs.Player_PlaceTable then continue end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN,pd.from:objectName(),t:objectName(),pd.reason,"")
		moves:append(sgs.CardsMoveStruct(c:getEffectiveId(),nil,sgs.Player_DiscardPile,reason))
	end
	room:moveCardsAtomic(moves,true)
	player:removeTag("targetsPindian_"..self)
	room:getThread():delay()
	return pd_
end
function InstallEquip(eid,player,self,to)
	local e = eid
	if type(eid)~="number" then eid = eid:getEffectiveId()
	else e = sgs.Sanguosha:getCard(eid) end
	if e:getTypeId()~=3 then return end
	local n = e:getRealCard():toEquipCard():location()
	to = to or player
	if not to:hasEquipArea(n) then return end
	local ton = to~=player and to:objectName() or ""
	self = type(self)=="string" and self or self and self:objectName() or ""
	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,player:objectName(),ton,self,"")
	local move1 = sgs.CardsMoveStruct(eid,to,sgs.Player_PlaceEquip,reason)
	e = to:getEquip(n)
	local moves = sgs.CardsMoveList()
	if e and e:getEffectiveId()~=eid then
		reason.m_reason = sgs.CardMoveReason_S_REASON_CHANGE_EQUIP
		moves:append(sgs.CardsMoveStruct(e:getEffectiveId(),nil,sgs.Player_DiscardPile,reason))
	end
	moves:append(move1)
	player:getRoom():moveCardsAtomic(moves,true)
	return true
end
function MoveFieldCard(self,player,flags,froms,tos)
	local room = player:getRoom()
	if self and type(self)~="string" then self = self:objectName() end
	local mfc = {reason = self,owner = player}
	mfc.flags = flags or "ej"
	froms = froms or sgs.SPlayerList()
	if froms:isEmpty() then
		for i,p in sgs.list(room:getAlivePlayers())do
			if p:getCards(mfc.flags):length()>0
			then froms:append(p) end
		end
	end
	if froms:isEmpty() then return end
	mfc.from = room:askForPlayerChosen(player,froms,self.."_from","MoveField0:"..self)
	room:doAnimate(1,player:objectName(),mfc.from:objectName())
	local noids = sgs.IntList()
	tos = tos or room:getAlivePlayers()
	for _,ej in sgs.list(mfc.from:getCards(mfc.flags))do
		local cp = room:getCardPlace(ej:getEffectiveId())
		local has = true
		for _,p in sgs.list(tos)do
			if cp==sgs.Player_PlaceEquip then
				local n = ej:getRealCard():toEquipCard():location()
				if p:getEquip(n) or not p:hasEquipArea(n) then continue end
			elseif cp==sgs.Player_PlaceDelayedTrick then
				if p:containsTrick(ej:objectName())
				or player:isProhibited(p,ej)
				then continue end
			end
			has = false
		end
		if has then
			noids:append(ej:getEffectiveId())
		end
	end
	noids = room:askForCardChosen(player,mfc.from,mfc.flags,self,false,sgs.Card_MethodNone,noids)
	if noids<0 then return end
	mfc.to_place = room:getCardPlace(noids)
	mfc.card = sgs.Sanguosha:getCard(noids)
	local canTos = sgs.SPlayerList()
	for _,p in sgs.list(tos)do
		if mfc.to_place==sgs.Player_PlaceEquip then
			local n = mfc.card:getRealCard():toEquipCard():location()
			if p:getEquip(i) or not p:hasEquipArea(i)
			then continue end
		elseif mfc.to_place==sgs.Player_PlaceDelayedTrick then
			if p:containsTrick(mfc.card:objectName())
			or player:isProhibited(p,mfc.card)
			then continue end
		end
		canTos:append(p)
	end
	mfc.to = room:askForPlayerChosen(player,canTos,self.."_to","MoveField1:"..self..":"..mfc.card:objectName())
	room:doAnimate(1,mfc.from:objectName(),mfc.to:objectName())
	canTos = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER,player:objectName(),mfc.from:objectName(),self,"")
	room:moveCardTo(mfc.card,mfc.from,mfc.to,mfc.to_place,canTos)
	return mfc
end
function InsertList(list1,list2)
	if type(list1)=="table" then
		for _,l in sgs.list(list2)do
			table.insert(list1,l)
		end
	else
		for _,l in sgs.list(list2)do
			list1:append(l)
		end
	end
	return list1
end
function string:contains(pattern)
	return string.find(self,pattern)
end

function delayedPingdian(self,player,target,from_card)
	if self and type(self)~="string" then self = self:objectName() end
    local log = sgs.LogMessage()
    log.type = "#Pindian"
    log.from = player
	log.to:append(target)
	local room = player:getRoom()
    room:sendLog(log)
	local pd = sgs.PindianStruct()
	pd.from = player
	pd.from_card = from_card
	pd.reason = self
	pd.to = target
	pd.to_card = nil
	local data = sgs.QVariant()
	data:setValue(pd)
	if pd.from_card==nil then
		room:getThread():trigger(sgs.AskforPindianCard,room,player,data)
		pd = data:toPindian()
	end
	if not pd.to_card and not pd.from_card then
		local cs = room:askForPindianRace(player,pd.to,self)
		if cs:length()<2 then return end
		pd.from_card = cs:first()
		pd.to_card = cs:last()
	elseif not pd.from_card then
		pd.from_card = room:askForPindian(player,player,self)
	elseif not pd.to_card then
		pd.to_card = room:askForPindian(pd.to,player,self)
	end
	local moves = sgs.CardsMoveList()
	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN,pd.from:objectName(),pd.to:objectName(),pd.reason,"")
	if pd.to_card then
		pd.to_number = pd.to_card:getNumber()
		moves:append(sgs.CardsMoveStruct(pd.to_card:getEffectiveId(),nil,sgs.Player_PlaceTable,reason))
	end
	if pd.from_card then
		pd.from_number = pd.from_card:getNumber()
		moves:append(sgs.CardsMoveStruct(pd.from_card:getEffectiveId(),nil,sgs.Player_PlaceTable,reason))
	end
	if moves:length()<2 then return end
	pd.success = pd.from_number>pd.to_number
	room:moveCardsAtomic(moves,false)
	local dpr = {"delayedPingdians",pd.from:objectName(),pd.from_card:toString(),pd.to:objectName(),pd.to_card:toString(),pd.reason}
	local pds = room:getTag("delayedPingdian"):toString():split("+")
	table.insert(pds,table.concat(dpr,":"))
	room:setTag("delayedPingdians",ToData(table.concat(pds,"+")))
	room:setTag(pds[#pds],data)
	return pd
end

function verifyPindian(pd)
	if pd==nil then return end
	local room = pd.from:getRoom()
	local dpr = {"delayedPingdian",pd.from:objectName(),pd.from_card:toString(),pd.to:objectName(),pd.to_card:toString(),pd.reason}
	local pds = room:getTag("delayedPingdians"):toString():split("+")
	table.removeOne(pds,table.concat(dpr,":"))
	room:setTag("delayedPingdians",ToData(table.concat(pds,"+")))
    local log = sgs.LogMessage()
    log.type = "$PindianResult"
    log.from = pd.from
    log.card_str = pd.from_card:toString()
    room:sendLog(log)
	log.from = pd.to
	log.card_str = pd.to_card:toString()
	room:sendLog(log)
	local data = sgs.QVariant()
	data:setValue(pd)
	room:getThread():trigger(sgs.PindianVerifying,room,pd.from,data)
	pd = data:toPindian()
	pd.success = pd.from_number>pd.to_number--[[
	if pd.success then room:setEmotion(pd.from,"success")
	else room:setEmotion(pd.from,"no-success") end
	if pd.to_number>pd.from_number then room:setEmotion(pd.to,"success")
	else room:setEmotion(pd.to,"no-success") end]]
	local jsonLog = {
		16,
		pd.from:objectName(),
		pd.from_card:getEffectiveId(),
		pd.to:objectName(),
		pd.to_card:getEffectiveId(),
		pd.success,
		pd.reason
	}
	room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT,json.encode(jsonLog))
	log.from = pd.from
	log.to:append(pd.to)
    log.type = pd.success and "#PindianSuccess" or "#PindianFailure"
	room:sendLog(log)
	room:getThread():delay()
	data:setValue(pd)
	room:getThread():trigger(sgs.Pindian,room,pd.from,data)
	local moves = sgs.CardsMoveList()
	local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN,pd.from:objectName(),pd.to:objectName(),pd.reason,"")
	if pd.from_card and room:getCardPlace(pd.from_card:getEffectiveId())==sgs.Player_PlaceTable then
		moves:append(sgs.CardsMoveStruct(pd.from_card:getEffectiveId(),nil,sgs.Player_DiscardPile,reason))
	end
	if pd.to_card and room:getCardPlace(pd.to_card:getEffectiveId())==sgs.Player_PlaceTable then
		moves:append(sgs.CardsMoveStruct(pd.to_card:getEffectiveId(),nil,sgs.Player_DiscardPile,reason))
	end
	room:moveCardsAtomic(moves,true)
	data = sgs.QVariant("pindian:"..pd.reason..":"..pd.from:objectName()..":"..pd.from_card:getEffectiveId()..":"..pd.to:objectName()..":"..pd.to_card:getEffectiveId())
	room:getThread():trigger(sgs.ChoiceMade,room,pd.from,data)
	return pd
end





local bans = {}
equip_patterns = {}
local cardNames = {}
local class2Names = {}
function patterns(class)
	if type(class)=="string" then
		return class2Names[class] or class
	end
			local bp = sgs.Sanguosha:getBanPackages()
		if bp~=bans then
			bans = bp
			cardNames = {}
			equip_patterns = {}
			for id=0,sgs.Sanguosha:getCardCount()-1 do
				local c = sgs.Sanguosha:getEngineCard(id)
			if class2Names[c:getClassName()]==nil then class2Names[c:getClassName()] = c:objectName() end
				if string.sub(c:objectName(),1,1)=="_" or table.contains(bp,c:getPackage())
				or table.contains(cardNames,c:objectName()) then continue end
				if c:getTypeId()<3 then table.insert(cardNames,c:objectName())
				else table.insert(equip_patterns,c:objectName()) end
			end
		end
	if class==true then return class2Names end
		return cardNames
	end

local hcv = io.open("lua/ai/cstring")
if hcv then
	hcv:close()
	sgs.aiHandCardVisible = true
end
OnSkillTrigger = sgs.CreateTriggerSkill{
    name = "OnSkillTrigger",
	global = true,
	priority = {9,9,9,0,1},
	frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart,sgs.EventPhaseProceeding,sgs.EventPhaseEnd,sgs.CardsMoveOneTime,
	sgs.EventPhaseChanging,sgs.PreCardUsed,sgs.Damaged},
    on_trigger = function(self,event,player,data,room)
		if event==sgs.CardsMoveOneTime then
	    	local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_PlaceHand and move.to:objectName()==player:objectName()
			and player:getTag("ThrowArea_1"):toBool() then
				move.to = nil
				move.card_ids = player:handCards()
				move.to_place = sgs.Player_DiscardPile
				room:moveCardsAtomic(move,true)
			end
			if room:getCurrent()~=player then return end
			if player:getTag("zhengsu3"):toBool() and player:getPhase()==sgs.Player_Discard and move.to_place==sgs.Player_DiscardPile
			and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD then
				local cards = player:getTag("zhengsu-3"):toIntList()
				for _,id in sgs.qlist(move.card_ids)do
					cards:append(sgs.Sanguosha:getCard(id):getSuit())
				end
				player:setTag("zhengsu-3",ToData(cards))
			end
   		elseif event==sgs.Damaged then
		    local damage = data:toDamage()
			if damage.card then room:setTag("damage_caused_"..damage.card:toString(),data) end
			if damage.from and damage.from:isAlive() then
				for _,skill in sgs.qlist(damage.from:getSkillList())do
					if skill:property("ov_baonieNum"):toBool() then
						GainOvBaonieNum(damage.from,damage.damage)
						break
					end
				end
			end
			if player:isAlive() then
				for _,skill in sgs.qlist(player:getSkillList())do
					if skill:property("ov_baonieNum"):toBool() then
						GainOvBaonieNum(player,damage.damage)
						break
					end
				end
			end
        elseif event==sgs.PreCardUsed then
	       	local use = data:toCardUse()
			room:removeTag("damage_caused_"..use.card:toString())
			for i=1,2 do
				if use.from==player and player:getTag("zhengsu"..i):toBool()
				and player:getPhase()==sgs.Player_Play and use.card:getTypeId()~=0 then
					local zhengsu = player:getTag("zhengsu-"..i):toIntList()
					if i<2 then zhengsu:append(use.card:getNumber())
					else zhengsu:append(use.card:getSuit()) end
					player:setTag("zhengsu-"..i,ToData(zhengsu))
				end
			end
        elseif event==sgs.EventPhaseChanging then
	     	local change = data:toPhaseChange()
			if change.to==sgs.Player_NotActive then
	         	for _,p in sgs.qlist(room:getAllPlayers())do
					for _,sf in pairs(sgs.shifa_skills)do
					   	if sf.m<1 or sf.playerId~=p:objectName() then continue end
						sf.m = sf.m-1
						room:setPlayerMark(p,"&"..sf.name.."+-+shifa",sf.m)
						if sf.m>0 then continue end
						Log_message("$shifa0",p,nil,nil,sf.name,"shifa")
						sf.effect(p,sf.x)
					end
					for _,wx in pairs(sgs.wangxing_skills)do
					   	if wx.x<1 or wx.playerId~=p:objectName() then continue end
						Log_message("$wangxing0",p,nil,nil,wx.x,"wangxing",wx.name)
						change = p:getCardCount()>=wx.x
						if change then
							p:setTag("wangxing_ai",ToData(wx.name))
							change = room:askForDiscard(p,"wangxing",wx.x,wx.x,true,true,"wangxing0:"..wx.x..":"..wx.name)
							p:removeTag("wangxing_ai")
						end
						if not change then room:loseMaxHp(p,1,"wangxing") end
						wx.x = 0
					end
				end
				for _,pdn in ipairs(room:getTag("delayedPingdians"):toString():split("+"))do
							local pd = p:getTag(pdn):toPindian()
								local moves = sgs.CardsMoveList()
								if pd.from_card and room:getCardPlace(pd.from_card:getEffectiveId())==sgs.Player_PlaceTable then
									local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN,pd.from:objectName(),pd.reason,"")
									moves:append(sgs.CardsMoveStruct(pd.from_card:getEffectiveId(),nil,sgs.Player_DiscardPile,reason))
								end
								if pd.to_card and room:getCardPlace(pd.to_card:getEffectiveId())==sgs.Player_PlaceTable then
									local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PINDIAN,pd.from:objectName(),pd.to:objectName(),pd.reason,"")
									moves:append(sgs.CardsMoveStruct(pd.to_card:getEffectiveId(),nil,sgs.Player_DiscardPile,reason))
								end
					room:moveCardsAtomic(moves,true)
							end
				room:removeTag("delayedPingdians")
			elseif change.from==sgs.Player_Discard then
				for i=1,3 do
					if player:getTag("zhengsu"..i):toBool() then
						local ids = player:getTag("zhengsu-"..i):toIntList()
						local can = true
						if i==1 then
							local n = 0
							for _,c in sgs.list(ids)do
								if c<=n then can = false end
								n = c
							end
							can = can and ids:length()>2
						elseif i==2 then
							local n = ids:first()
							for _,c in sgs.list(ids)do
								if c~=n then can = false end
								n = c
							end
							can = can and ids:length()>1
						elseif i==3 then
							local n = {}
							for _,c in sgs.list(ids)do
								if table.contains(n,c) then can = false end
								table.insert(n,c)
							end
							can = can and ids:length()>1
						end
						local msg = sgs.LogMessage()
						msg.type = "$zhengsu0"
						msg.from = player
						msg.arg = "zhengsu"
						msg.arg2 = "zhengsu_fail"
						ids = "zhengsu:"..i..":zhengsu_fail"
						if can then
							msg.arg2 = "zhengsu_successful"
							room:sendLog(msg)
							msg = room:askForChoice(player,"zhengsu","drawCards_2+recover_1")
							if msg=="drawCards_2" then player:drawCards(2,"zhengsu")
							else room:recover(player,sgs.RecoverStruct("zhengsu")) end
							ids = "zhengsu:"..i..":zhengsu_successful:"..msg
						else room:sendLog(msg) end
						player:removeTag("zhengsu"..i)
						player:removeTag("zhengsu-"..i)
						local data = ToData(ids)
						room:getThread():trigger(sgs.EventForDiy,room,player,data)
						room:setPlayerMark(player,"&zhengsu+-+zhengsu"..i,0)
					end
				end
			end
        elseif event==sgs.EventPhaseStart
		or event==sgs.EventPhaseProceeding
		or event==sgs.EventPhaseEnd then
			local n = player:getTag("FinishPhase"):toInt()
			if n>0 then
				if n==player:getPhase() then return true end
				if n>player:getPhase() then return end
				player:removeTag("FinishPhase")
			end
 		end
    end,
}
addToSkills(OnSkillTrigger)
IsProhibited = sgs.CreateProhibitSkill{
	name = "IsProhibited",
	is_prohibited = function(self,from,to,card)
		return card:getTypeId()>0 and to
		and to:property("aiNoTo"):toBool()
	end
}
addToSkills(IsProhibited)