-- Fixed wisdom policy; private source values stay in scoped DTOs or marked memory.
local function known(v,key)
 if AIUnsupported.is(v)then error(v,0)end
 if v==nil then ai_unsupported("Wisdom requires "..key,"wisdom")end;return v
end
local function q(o,m,...)
 if AIValue.isPlayer(o)then
  if m=="getMark"then m="getStrategyMark"elseif m=="hasFlag"then m="getStrategyFlag"end
 end
 if not o or type(o[m])~="function"then ai_unsupported("Wisdom method unavailable: "..m,"wisdom")end
 return known(o[m](o,...),m)
end
local function own_first_keep(self)
 local disabled=self.disabled_ids
 if not disabled then local value,present=self:getStrategyMemory("discard_disabled_ids");disabled=present and value or{}end
 if not AIValue.isList(disabled)then ai_unsupported("owner discard cache malformed","juao")end
 for _,c in ipairs(self:sortByKeepValue(self.player:getCards("h")))do
  local id=q(c,"getEffectiveId");if not table.contains(disabled,id)then return id end
 end
 return -1
end
local function hydrate(self,row,players,cards)
 if type(row)~="table"then ai_unsupported("Wisdom original scoped data missing","wisdom")end
 local result={};for k,v in pairs(row)do result[k]=v end
 for _,k in ipairs(players)do if type(row[k])=="string"and row[k]~=""then result[k]=known(self.room:findPlayerByObjectName(row[k]),k)end end
 for _,k in ipairs(cards)do if type(row[k])=="table"then result[k]=CardView.new(row[k])end end
 return result
end
local function current_damage(self)
 -- CurrentDamageStruct is set from DamageDone to DamageComplete and a trigger is
 -- logged when its dispatch ends, so while a Damaged skill answers the latest
 -- damage event is that damage's DamageDone or Damage stage.
 local event=self:getLastEvent("damage")
 local stage=event and q(event,"getTriggerEvent")
 if stage~=sgs.DamageDone and stage~=sgs.Damage then ai_unsupported("CurrentDamageStruct is not projected","CurrentDamageStruct")end
 local row=rawget(event,"_view")
 return hydrate(self,{from=row.from,to=row.to,card=row.details and row.details.card},{"from","to"},{"card"})
end
local function fuzuo_data(self)
 local c=q(self,"getDecisionContext").wisdom
 return hydrate(self,c and c.fuzuo_pindian,{"from","to"},{"from_card","to_card"})
end
local function set_jincui(self)
 self:setStrategyMemory("wisdom.jincui_discard",true)
 self:useKnowledgeEstimate({status="estimate",value=true,basis="wisdom.jincui_viewer_local_global_without_cross_viewer_propagation"},"jincui")
end
local function get_jincui(self)
 local value,present=self:getStrategyMemory("wisdom.jincui_discard")
 if present and type(value)~="boolean"then ai_unsupported("Jincui cache malformed","jincui")end
 return self:useKnowledgeEstimate({status="estimate",value=present and value or false,
  basis="wisdom.jincui_viewer_local_global_without_cross_viewer_propagation"},"jincui")
end
--[[
	技能：倨傲
	描述：出牌阶段，你可以选择两张手牌背面向上移出游戏，指定一名角色，被指定的角色到下个回合开始阶段时，跳过摸牌阶段，得到你所移出游戏的两张牌。每阶段限一次
]]--
sgs.ai_fill_skill.juao = function(self,inclusive,request)
	if q(self,"needBear") then return end
	if q(self.player,"getHandcardNum")>1 then
		local card_id = own_first_keep(self)
		return q(self,"legacySkillSeedWithCosts","juao","JuaoCard",request,{card_id})
	end
end

sgs.ai_skill_use_func.JuaoCard = function(card,use,self,request)
	local givecard = {}
	local cards = self.player:getHandcards()
	for _,friend in ipairs(self.friends_noself)do
		if q(friend,"getHp")==1 then --队友快死了
			for _,hcard in sgs.qlist(cards)do
				if q(hcard,"isKindOf","Analeptic") or q(hcard,"isKindOf","Peach") then
					table.insert(givecard,q(hcard,"getId"))
				end
				if #givecard==1 and givecard[1]~=q(hcard,"getId") then
					table.insert(givecard,q(hcard,"getId"))
				elseif #givecard==2 then
					use.card = q(self,"bindSkillCard","juao",givecard,request,nil,"JuaoCard")
					use.to:append(friend)
					self:speak("顶住，你的快递马上就到了。")
					return
				end
			end
		end
		if q(friend,"hasSkill","nosjizhi") then --队友有集智
			for _,hcard in sgs.qlist(cards)do
				if q(hcard,"isKindOf","TrickCard") and not q(hcard,"isKindOf","DelayedTrick") and not table.contains(givecard,q(hcard,"getId")) then
					table.insert(givecard,q(hcard,"getId"))
				end
				if #givecard==1 and givecard[1]~=q(hcard,"getId") then
					table.insert(givecard,q(hcard,"getId"))
				elseif #givecard==2 then
					use.card = q(self,"bindSkillCard","juao",givecard,request,nil,"JuaoCard")
					use.to:append(friend)
					return
				end
			end
		end
		if q(friend,"hasSkill","jizhi") then --队友有集智
			for _,hcard in sgs.qlist(cards)do
				if q(hcard,"isKindOf","TrickCard") and not table.contains(givecard,q(hcard,"getId")) then
					table.insert(givecard,q(hcard,"getId"))
				end
				if #givecard==1 and givecard[1]~=q(hcard,"getId") then
					table.insert(givecard,q(hcard,"getId"))
				elseif #givecard==2 then
					use.card = q(self,"bindSkillCard","juao",givecard,request,nil,"JuaoCard")
					use.to:append(friend)
					return
				end
			end
		end
		if q(friend,"hasSkill","leiji") then --队友有雷击
			for _,hcard in sgs.qlist(cards)do
				if ((q(friend,"hasSkill","guidao") and q(hcard,"getSuit")==sgs.Card_Spade) or q(hcard,"isKindOf","Jink"))
					and not table.contains(givecard,q(hcard,"getId")) then
					table.insert(givecard,q(hcard,"getId"))
				end
				if #givecard==1 and givecard[1]~=q(hcard,"getId") then
					table.insert(givecard,q(hcard,"getId"))
				elseif #givecard==2 then
					use.card = q(self,"bindSkillCard","juao",givecard,request,nil,"JuaoCard")
					use.to:append(friend)
					self:speak("我知道你有什么牌，哼哼。")
					return
				end
			end
		end
		if q(friend,"hasSkill","nosleiji") then --队友有雷击
			for _,hcard in sgs.qlist(cards)do
				if ((q(friend,"hasSkill","guidao") and q(hcard,"isBlack")) or q(hcard,"isKindOf","Jink"))
					and not table.contains(givecard,q(hcard,"getId")) then
					table.insert(givecard,q(hcard,"getId"))
				end
				if #givecard==1 and givecard[1]~=q(hcard,"getId") then
					table.insert(givecard,q(hcard,"getId"))
				elseif #givecard==2 then
					use.card = q(self,"bindSkillCard","juao",givecard,request,nil,"JuaoCard")
					use.to:append(friend)
					self:speak("我知道你有什么牌，哼哼。")
					return
				end
			end
		end
		if q(friend,"hasSkill","xiaoji") or q(friend,"hasSkill","xuanfeng") then --队友有枭姬（旋风）
			for _,hcard in sgs.qlist(cards)do
				if q(hcard,"isKindOf","EquipCard") and not table.contains(givecard,q(hcard,"getId")) then
					table.insert(givecard,q(hcard,"getId"))
				end
				if #givecard==1 and givecard[1]~=q(hcard,"getId") then
					table.insert(givecard,q(hcard,"getId"))
				elseif #givecard==2 then
					use.card = q(self,"bindSkillCard","juao",givecard,request,nil,"JuaoCard")
					use.to:append(friend)
					return
				end
			end
		end
	end
	givecard = {}
	for _,enemy in ipairs(self.enemies)do
		if q(enemy,"getHp")==1 then --敌人快死了
			for _,hcard in sgs.qlist(cards)do
				if q(hcard,"isKindOf","Disaster") then
					table.insert(givecard,q(hcard,"getId"))
				end
				if #givecard==1 and givecard[1]~=q(hcard,"getId") and
					not q(hcard,"isKindOf","Peach") and not q(hcard,"isKindOf","TrickCard") then
					table.insert(givecard,q(hcard,"getId"))
					use.card = q(self,"bindSkillCard","juao",givecard,request,nil,"JuaoCard")
					use.to:append(enemy)
					return
				elseif #givecard==2 then
					use.card = q(self,"bindSkillCard","juao",givecard,request,nil,"JuaoCard")
					use.to:append(enemy)
					self:speak("咱最擅长落井下石了。")
					return
				else
				end
			end
		end
		if q(enemy,"hasSkill","yongsi") then --敌人有庸肆
			local players = self.room:getAlivePlayers()
			local extra = q(self,"KingdomsCount",players) --额外摸牌的数目
			if q(enemy,"getCardCount",true)<=extra then --如果敌人快裸奔了
				for _,hcard in sgs.qlist(cards)do
					if q(hcard,"isKindOf","Disaster") and not table.contains(givecard,q(hcard,"getId")) then
						table.insert(givecard,q(hcard,"getId"))
					end
					if #givecard==1 and givecard[1]~=q(hcard,"getId") then
						if not q(hcard,"isKindOf","Peach") and not q(hcard,"isKindOf","ExNihilo") then
							table.insert(givecard,q(hcard,"getId"))
							use.card = q(self,"bindSkillCard","juao",givecard,request,nil,"JuaoCard")
							use.to:append(enemy)
							return
						end
					end
					if #givecard==2 then
						use.card = q(self,"bindSkillCard","juao",givecard,request,nil,"JuaoCard")
						use.to:append(enemy)
						return
					end
				end
			end
		end
	end
	if #givecard<2 then
		for _,hcard in sgs.qlist(cards)do
			if q(hcard,"isKindOf","Disaster") and not table.contains(givecard,q(hcard,"getId")) then
				table.insert(givecard,q(hcard,"getId"))
			end
			if #givecard==2 then
				use.card = q(self,"bindSkillCard","juao",givecard,request,nil,"JuaoCard")
				use.to:append(self.enemies[1])
				return
			end
		end
	end
end
--[[
	技能：贪婪
	描述：每当你受到一次伤害，可与伤害来源进行拼点：若你赢，你获得两张拼点牌
]]--
sgs.ai_skill_invoke.tanlan = function(self,data)
	local damage = data:toDamage()
	local from = damage.from
	local max_card = self:getMaxCard()
	if not max_card then return end
	if q(max_card,"getNumber")>10 and q(self,"isFriend",from) then
		if q(from,"getHandcardNum")==1 and q(self,"needKongcheng",from) then return true end
		if q(self,"getOverflow",from)>2 then return true end
		if not q(self,"hasLoseHandcardEffective",from) then return true end
	end
	if q(self,"isFriend",from) then return false end
	if q(max_card,"getNumber")>10
		or (q(self.player,"getHp")>2 and q(self.player,"getHandcardNum")>2 and q(max_card,"getNumber")>4)
		or (q(self.player,"getHp")>1 and q(self.player,"getHandcardNum")>1 and q(max_card,"getNumber")>7)
		or (q(from,"getHandcardNum")<=2 and q(max_card,"getNumber")>2)
		or (q(from,"getHandcardNum")==1 and q(self,"hasLoseHandcardEffective",from) and not q(self,"needKongcheng",from))
		or q(self,"getOverflow")>2 then
		return true
	end
end

sgs.ai_choicemade_filter.skillInvoke.tanlan = function(self,player,promptlist)
	local damage = current_damage(self)
	if damage.from and promptlist[3]=="yes" then
		local target = damage.from
		local intention = 10
		if q(target,"getHandcardNum")==1 and q(self,"needKongcheng",target) then intention = 0 end
		if q(self,"getOverflow",target)>2 then intention = 0 end
		if not q(self,"hasLoseHandcardEffective",target) then intention = 0 end
		self:updateIntention(player,target,intention)
	end
end

function sgs.ai_skill_pindian.tanlan(minusecard,self,requestor)
	local maxcard = self:getMaxCard()
	return q(self,"isFriend",requestor) and minusecard or ( q(maxcard,"getNumber")<6 and minusecard or maxcard )
end

sgs.ai_cardneed.tanlan = sgs.ai_cardneed.bignumber

--[[
	技能：异才
	描述：每当你使用一张非延时类锦囊时(在它结算之前)，可立即对攻击范围内的角色使用一张【杀】
]]--
sgs.ai_skill_invoke.yicai = function(self,data)
	if q(self,"needBear") then return false end
	for _,enemy in ipairs(self.enemies)do
		if q(self.player,"canSlash",enemy,nil,true) then
			if q(self,"getCardsNum","Slash")>0 then
				return true
			end
		end
	end
end
--[[
	技能：北伐（锁定技）
	描述：当你失去最后一张手牌时，视为对攻击范围内的一名角色使用了一张【杀】
]]--
sgs.ai_skill_playerchosen.beifa = function(self,targets)
	local slash = q(self,"getEvaluationCard","slash")
	local targetlist = {}
	for _,p in sgs.qlist(targets)do
		if not q(self,"slashProhibit",slash,p) then
			table.insert(targetlist,p)
		end
	end
	self:sort(targetlist,"defenseSlash")
	for _,target in ipairs(targetlist)do
		if q(self,"isEnemy",target) then
			if q(self,"slashIsEffective",slash,target) then
				if q(self,"isGoodTarget",target,targetlist,slash) then
					self:speak("嘿！没想到吧？")
					return target
				end
			end
		end
	end
	for i=#targetlist,1,-1 do
		if q(self,"isGoodTarget",targetlist[i],targetlist) then
			return targetlist[i]
		end
	end
	return targetlist[#targetlist]
end


--[[
	技能：后援
	描述：出牌阶段，你可以弃置两张手牌，指定一名其他角色摸两张牌，每阶段限一次
]]--
sgs.ai_fill_skill.houyuan = function(self,inclusive,request)
	if q(self,"needBear") then return end
	if q(self.player,"getHandcardNum")>1 then
		local givecard = {}
		local index = 0
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _,fcard in ipairs(cards)do
			if not q(fcard,"isKindOf","Peach") then
				table.insert(givecard,q(fcard,"getId"))
				index = index+1
			end
			if index==2 then break end
		end
		if index<2 then return end
		return q(self,"bindSkillCard","houyuan",givecard,request,nil,"HouyuanCard")
	end
end

sgs.ai_skill_use_func.HouyuanCard = function(card,use,self,request)
	if #self.friends==1 then return end
	local target
	local AssistTarget = self:AssistTarget()
	if AssistTarget and not q(AssistTarget,"hasSkill","manjuan") and not q(self,"needKongcheng",AssistTarget,true)
	then target = AssistTarget else target = self:findPlayerToDraw(false,2) end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	local usecards = {cards[1]:getId(),cards[2]:getId()}
	if not cards[1]:isKindOf("ExNihilo") then
		if target then
			use.to:append(target)
			self:speak("有你这样出远门不带粮食的么？接好了！")
		end
		use.card = q(self,"bindSkillCard","houyuan",usecards,request,nil,"HouyuanCard")
	end
end

sgs.ai_card_intention.HouyuanCard = -70


--[[
	技能：霸王
	描述：当你使用的【杀】被【闪】响应时，你可以和对方拼点：若你赢，可以选择最多两个目标角色，视为对其分别使用了一张【杀】
]]--
sgs.ai_skill_invoke.bawang = function(self,data)
	local effect = data:toCardEffect()
	local max_card = self:getMaxCard()
	if max_card and q(max_card,"getNumber")>10 then
		return q(self,"isEnemy",effect.to)
	end
	if q(self,"isEnemy",effect.to) then
		if q(self,"getOverflow")>0 then return true end
	end
end

function sgs.ai_skill_pindian.bawang(minusecard,self,requestor,maxcard)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local function compare_func(a,b)
		return q(a,"getNumber")>q(b,"getNumber")
	end
	table.sort(cards,compare_func)
	for _,card in ipairs(cards)do
		if q(card,"getNumber")>10 then return card end
	end
	self:sortByKeepValue(cards)
	return cards[1]
end

sgs.ai_skill_use["@@bawang"] = function(self,prompt)
	local first_index,second_index
	self:sort(self.enemies,"defenseSlash")
	local slash = q(self,"getEvaluationCard","slash")
	for i=1,#self.enemies do
		if not (self.enemies[i]:hasSkill("kongcheng") and self.enemies[i]:isKongcheng()) and not q(self,"slashProhibit",slash ,self.enemies[i]) then
			if not first_index then
				first_index = i
			else
				second_index = i
			end
		end
		if second_index then break end
	end
	if not first_index then return "." end
	local first = self.enemies[first_index]:objectName()
	if not second_index then
		return ("@BawangCard=.->%s"):format(first)
	else
		local second = self.enemies[second_index]:objectName()
		return ("@BawangCard=.->%s+%s"):format(first,second)
	end
end

sgs.ai_cardneed.bawang = sgs.ai_cardneed.bignumber
ai_audited_aliases.register{id="ai_card_intention.BawangCard",registry="ai_card_intention",path={"BawangCard"},
 canonical_registry="ai_card_intention",canonical_path={"ShensuCard"},self_index=1,defer_canonical=true}
--[[
	技能：危殆（主公技）
	描述：当你需要使用一张【酒】时，所有吴势力角色按行动顺序依次选择是否打出一张黑桃2~9的手牌，视为你使用了一张【酒】，直到有一名角色或没有任何角色决定如此做时为止
]]--

function sgs.ai_cardsview.weidai(self,class_name,player)
	return "@WeidaiCard=.->."
end

sgs.ai_skill_use_func.WeidaiCard = function(card,use,self,request)
	use.card = card
end

ai_audited_aliases.register{id="ai_card_intention.WeidaiCard",registry="ai_card_intention",path={"WeidaiCard"},
 canonical_registry="ai_card_intention",canonical_path={"Peach"},self_index=1}

sgs.ai_skill_cardask["@weidai-analeptic"] = function(self,data)
	local who = data:toPlayer()
	if q(self,"isEnemy",who) then return "." end
	if q(self,"needBear") and q(who,"getHp")>0 then return "." end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	for _,fcard in ipairs(cards)do
		if q(fcard,"getSuit")==sgs.Card_Spade and q(fcard,"getNumber")>1 and q(fcard,"getNumber")<10 then
			return q(fcard,"getEffectiveId")
		end
	end
	return "."
end

sgs.ai_event_callback[sgs.ChoiceMade].weidai=function(self,player,data)
    -- A public Yiji kind proves the cardResponded prefix false without
    -- demanding its hidden card-ID suffix from another observer.
    if type(data)=="table" and data.kind=="choice" and type(data.details)=="table"
        and data.details.choice_kind=="Yiji" then return end
	local choices= data:toString():split(":")
	if choices[1]=="cardResponded" and choices[3]=="@weidai-analeptic" then
		local target = self.room:findPlayerByObjectName(choices[4])
		local card = choices[#choices]
		if card~="" then
			self:updateIntention(player,target,-80)
		end
	end
end


--[[
	技能：笼络
	描述：回合结束阶段开始时，你可以选择一名其他角色摸取与你弃牌阶段弃牌数量相同的牌
]]--
sgs.ai_skill_playerchosen.longluo = function(self,targets)
	if #self.friends<=1 then return nil end
	local n = q(self.player,"getMark","longluo")
	local to = self:findPlayerToDraw(false,n)
	if to then return to end
	return self.friends_noself[1]
end

sgs.ai_playerchosen_intention.longluo = -60

--[[
	技能：辅佐
	描述：当有角色拼点时，你可以打出一张点数小于8的手牌，让其中一名角色的拼点牌加上这张牌点数的二分之一（向下取整）
]]--
sgs.ai_skill_use["@@fuzuo"] = function(self,prompt,method)
	if q(self.player,"isKongcheng") then return "." end

	local function find_a_card(number)
		local card
		number = math.abs(number)
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		for _,acard in ipairs(cards)do
			local anum = q(acard,"getNumber")
			if math.ceil(anum/2)>number and anum<8 then
				card = acard
			end
		end
		return card
	end

	local pindian = fuzuo_data(self)
	local from,to = pindian.from,pindian.to
	local from_num,to_num = pindian.from_number,pindian.to_number
	local reason = pindian.reason
	local PDcards = {}
	table.insert(PDcards,pindian.from_card)
	table.insert(PDcards,pindian.to_card)

	if math.abs(from_num-to_num)>=3 then return "." end

	local card = find_a_card(from_num-to_num)
	if not card then return "." end

	local Valuable
	for _,acard in ipairs(PDcards)do
		if q(acard,"isKindOf","ExNihilo") or q(acard,"isKindOf","Peach") or q(acard,"isKindOf","Snatch") or q(acard,"isKindOf","Dismantlement") or q(acard,"isKindOf","Duel") then
			Valuable = true
			break
		elseif q(acard,"isKindOf","Slash") and q(self,"hasCrossbowEffect",from) and reason~="zhiba_pindian" then
			Valuable = true
		end
	end

	local onlyone_Jink_Peach
	if isCard("Peach",card,self.player) and q(self,"getCardsNum","Peach")<=1 and q(self.player,"isWounded") then
		onlyone_Jink_Peach = true
	elseif isCard("Jink",card,self.player) and q(self,"getCardsNum","Jink")<=1 then
		onlyone_Jink_Peach = true
	end

	if reason=="zhiba_pindian" then
		if Valuable or not onlyone_Jink_Peach or q(self,"getOverflow")>0 and q(self,"willSkipPlayPhase") then
			if q(self,"isFriend",to) and from_num>to_num then
				return "@FuzuoCard="..q(card,"getEffectiveId").."->"..q(to,"objectName")
			elseif not q(self,"isFriend",to) and to_num>from_num then
				return "@FuzuoCard="..q(card,"getEffectiveId").."->"..q(from,"objectName")
			end
		end
	elseif reason=="dahe" or reason=="mizhao" or reason=="shuangren" then
		if q(self,"isFriend",from) and from_num<to_num then
			return "@FuzuoCard="..q(card,"getEffectiveId").."->"..q(from,"objectName")
		elseif not q(self,"isFriend",from) and from_num>to_num then
			return "@FuzuoCard="..q(card,"getEffectiveId").."->"..q(to,"objectName")
		end

	elseif reason=="lieren" or reason=="tanlan"  or reason=="jueji" then
		if Valuable or not onlyone_Jink_Peach or q(self,"getOverflow")>0 and q(self,"willSkipPlayPhase") then
			if q(self,"isFriend",from) and not q(self,"isFriend",to) and from_num<to_num then
				return "@FuzuoCard="..q(card,"getEffectiveId").."->"..q(from,"objectName")
			elseif q(self,"isFriend",to) and not q(self,"isFriend",from) and to_num<from_num then
				return "@FuzuoCard="..q(card,"getEffectiveId").."->"..q(to,"objectName")
			end
		end

	elseif reason=="tianyi" or reason=="xianzhen" then
		if q(self,"isFriend",from) and from_num<to_num and getCardsNum("Slash",from,self.player)>=1 then
			return "@FuzuoCard="..q(card,"getEffectiveId").."->"..q(from,"objectName")
		elseif not q(self,"isFriend",from) and q(self,"isFriend",to) and from_num>to_num and getCardsNum("Slash",from,self.player)>=1 then
			return "@FuzuoCard="..q(card,"getEffectiveId").."->"..q(to,"objectName")
		end

	elseif reason=="quhu"  then
		if not q(self,"isFriend",from) and q(self,"isFriend",to) and from_num>to_num then
			return "@FuzuoCard="..q(card,"getEffectiveId").."->"..q(to,"objectName")
		elseif q(self,"isFriend",from) and from_num>=10 and from_num<to_num then
			return "@FuzuoCard="..q(card,"getEffectiveId").."->"..q(from,"objectName")
		end

	else
		if q(self,"isFriend",from) and q(self,"isFriend",to) then return "." end
		if not onlyone_Jink_Peach or q(self,"getOverflow")>0 and q(self,"willSkipPlayPhase") then
			if q(self,"isFriend",from) and from_num<to_num then
				return "@FuzuoCard="..q(card,"getEffectiveId").."->"..q(from,"objectName")
			elseif not q(self,"isFriend",to) and to_num<from_num then
				return "@FuzuoCard="..q(card,"getEffectiveId").."->"..q(to,"objectName")
			end
		end
	end

	return "."
end

--[[
	技能：尽瘁
	描述：当你死亡时，可令一名角色摸取或者弃置三张牌
]]--

sgs.ai_skill_playerchosen.jincui = function(self,targets)
	local AssistTarget = self:AssistTarget()
	if AssistTarget and not q(AssistTarget,"hasSkill","manjuan") and not q(self,"needKongcheng",AssistTarget,true) then return AssistTarget end
	local wf
	for _,friend in ipairs(self.friends_noself)do
		if q(self,"isWeak",friend) then
			wf = true
			break
		end
	end

	if not wf then
		self:sort(self.enemies,"handcard")
		for _,enemy in ipairs(self.enemies)do
			if q(enemy,"getCardCount",true)==3
			  and q(self,"doDisCard",enemy,"he",true,3) then
				set_jincui(self)
				return enemy
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if q(enemy,"getCardCount",true)>=3
			and q(self,"doDisCard",enemy,"he",true,3)
			and self:hasSkills(sgs.cardneed_skill,enemy)
			then
				set_jincui(self)
				return enemy
			end
		end
	end

	local to = self:findPlayerToDraw(false,3)
	if to then return to end
	set_jincui(self)
	return self.enemies[1]
end


sgs.ai_skill_choice.jincui = function(self,choices)
	if get_jincui(self) then return "throw" else return "draw" end
end


--你使用黑色的【杀】造成的伤害+1，你无法闪避红色的【杀】

sgs.ai_slash_prohibit.wenjiu = function(self,from,to,card)
	local has_black_slash,has_red_slash
	local slashes = self:getCards("Slash")
	for _,slash in ipairs(slashes)do
		if q(slash,"isBlack") and q(self,"slashIsEffective",slash,to) then has_black_slash = true end
		if q(slash,"isRed") and q(self,"slashIsEffective",slash,to) then has_red_slash = true end
	end

	if q(self,"isFriend",to) then
		return q(card,"isRed") and (has_black_slash or q(self,"isWeak",to))
	else
		if has_red_slash and getCardsNum("Jink",to,self.player)>0 then return not q(card,"isRed") end
	end
end

--[[
	技能：霸刀
	描述：当你成为黑色的【杀】目标时，你可以对你攻击范围内的一名其他角色使用一张【杀】
]]--

sgs.ai_skill_cardask["@askforslash"] = function(self,data)
	local slashes = self:getCards("Slash")
	self:sort(self.enemies,"defenseSlash")

	for _,slash in ipairs(slashes)do
		local no_distance = q(slash,"getTargetModDistance",self.player)>50 or q(self.player,"hasFlag","slashNoDistanceLimit")
		for _,enemy in ipairs(self.enemies)do
			if q(self.player,"canSlash",enemy,slash,not no_distance) and not q(self,"slashProhibit",slash,enemy) and q(slash,"isBlack") and self:hasSkills("wenjiu")
			and q(self,"slashIsEffective",slash,enemy) and q(self,"isGoodTarget",enemy,self.enemies,slash)
			and not (q(self.player,"hasFlag","slashTargetFix") and not q(enemy,"hasFlag","SlashAssignee")) then
				return ("%s->%s"):format(slash:toString(),q(enemy,"objectName"))
			end
		end
	end
	for _,slash in ipairs(slashes)do
		local no_distance = q(slash,"getTargetModDistance",self.player)>50 or q(self.player,"hasFlag","slashNoDistanceLimit")
		for _,enemy in ipairs(self.enemies)do
			if q(self.player,"canSlash",enemy,slash,not no_distance) and not q(self,"slashProhibit",slash,enemy) and not q(slash,"isBlack")
			and q(self,"slashIsEffective",slash,enemy) and q(self,"isGoodTarget",enemy,self.enemies,slash)
			and not (q(self.player,"hasFlag","slashTargetFix") and not q(enemy,"hasFlag","SlashAssignee")) then
				return ("%s->%s"):format(slash:toString(),q(enemy,"objectName"))
			end
		end
	end
	return "."
end


sgs.ai_slash_prohibit.badao = function(self,from,to,card)
	local has_black_slash,has_red_slash
	local slashes = self:getCards("Slash")
	for _,slash in ipairs(slashes)do
		if q(slash,"isBlack") and q(self,"slashIsEffective",slash,to) then has_black_slash = true end
		if q(slash,"isRed") and q(self,"slashIsEffective",slash,to) then has_red_slash = true end
	end
	if q(self,"isFriend",to) then
		return q(card,"isRed") and (has_black_slash or q(self,"isWeak",to))
	else
		if has_red_slash then return q(card,"isBlack") end
		if getCardsNum("Slash",to,self.player)>1 then
			local slash = q(self,"getEvaluationCard","slash")
			for _,target in ipairs(self:getEnemies(to))do
				if q(to,"canSlash",target,slash) and not q(self,"slashProhibit",slash,target)
				and q(self,"slashIsEffective",slash,target)
				and not q(self,"needToLoseHp",target,to,slash,true)
				and q(self,"canHit",target,to) and q(self,"isWeak",target)
				then
					return q(card,"isBlack")
				end
			end
		end
	end
end

sgs.ai_cardneed.wenjiu = function(to,card)
	return q(card,"isBlack") and isCard("Slash",card,to)
end
--[[
	技能：识破
	描述：任意角色判定阶段判定前，你可以弃置两张牌，获得该角色判定区里的所有牌
]]--

sgs.ai_skill_discard.shipo = function(self)
	local target = self.room:getCurrent()
	if ((q(target,"containsTrick","supply_shortage") and q(target,"getHp")>q(target,"getHandcardNum")) or
		(q(target,"containsTrick","indulgence") and q(target,"getHandcardNum")>q(target,"getHp")-1)) then
		if q(self,"isFriend",target) then
			return self:askForDiscard("dummyreason",2,2,false,true)
		end
	end
	return {}
end

sgs.ai_choicemade_filter.skillInvoke.shipo = function(self,player,promptlist)
	if promptlist[3]=="yes" then
		local cp = self.room:getCurrent()
		self:updateIntention(player,cp,-10)
	end
end

sgs.ai_cardneed.gushou = function(to,card)
	return q(to,"getHandcardNum")<3 and q(card,"getTypeId")==sgs.Card_TypeBasic
end


--[[
	技能：授业
	描述：出牌阶段，你可以弃置一张红色手牌，指定最多两名其他角色各摸一张牌
]]--
sgs.ai_fill_skill.shouye = function(self,inclusive,request)
	if #self.friends_noself==0 then return end
	if q(self.player,"getHandcardNum")>0 then
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _,hcard in ipairs(cards)do
			if q(hcard,"isRed") then
				return q(self,"bindSkillCard","shouye",{q(hcard,"getId")},request,nil,"ShouyeCard")
			end
		end
	end
end

sgs.ai_skill_use_func.ShouyeCard = function(card,use,self,request)
	self:sort(self.friends_noself,"defense")
	local first
	local second
	local AssistTarget = self:AssistTarget()
	if AssistTarget and not q(AssistTarget,"hasSkill","manjuan") and not q(self,"needKongcheng",AssistTarget,true) then first = AssistTarget end

	for _,friend in ipairs(self.friends_noself)do
		if not q(friend,"hasSkill","manjuan") and not q(self,"needKongcheng",friend,true) then
			if not first then
				first = friend
			elseif q(first,"objectName")~=q(friend,"objectName") then
				second = friend
			end
			if second then break end
		end
	end

	if q(self.player,"hasSkill","jiehuo") and q(self.player,"getMark","jiehuo")<1 then
		self:setPriorityValue("ShouyeCard",9.29,"shouye")
		if first and not second then
			for _,friend in ipairs(self.friends_noself)do
				if q(first,"objectName")~=q(friend,"objectName") then
					second = friend
				end
				if second then break end
			end
			if not second then
				for _,enemy in ipairs(self.enemies)do
					if q(first,"objectName")~=q(enemy,"objectName") and (q(enemy,"hasSkill","manjuan") or q(self,"needKongcheng",enemy,true)) then
						second = enemy
					end
					if second then break end
				end
			end
			if not second then self:setPriorityValue("ShouyeCard",0,"shouye") end
		end
	else
		self:setPriorityValue("ShouyeCard",0,"shouye")
	end

	if not second and q(self,"getOverflow")<=0 then return end
	if first then
		use.to:append(first)
		self:speak("好好学习，天天向上！")
	end
	if second then
		use.to:append(second)
	end
	use.card = card
end

sgs.ai_cardneed.shouye = function(to,card)
	return q(to,"hasSkill","jiehuo") and q(to,"getMark","jiehuo")<1 and q(to,"getHandcardNum")<3 and q(card,"isRed")
end

sgs.ai_card_intention.ShouyeCard = function(self,card,from,tos)
	local intention = -70
	for i=1,#tos do
		local to = tos[i]
		if q(to,"hasSkill","manjuan") or q(self,"needKongcheng",to,true) then
			intention = 0
		end
		self:updateIntention(from,tos[i],intention)
	end
end

--[[
	技能：师恩
	描述：其他角色使用非延时锦囊时，可以让你摸一张牌
]]--
sgs.ai_skill_invoke.shien = function(self,data)
	local target = data:toPlayer()
	if target and q(target,"isAlive") then
		return q(self,"isFriend",target)
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.shien = function(self,player,promptlist)
	local simahui = self.room:findPlayerBySkillName("shien")
	if simahui and promptlist[3]=="yes" then
		self:updateIntention(player,simahui,-10)
	end
end


