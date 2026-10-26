-- Source: b6025acc ai/yitian-ai.lua.
local known = AIValue.requireKnown

-- General::isMale (printed, not the player's current gender) is not projected.
local function general_male(self,p)ai_unsupported("printed general gender is not projected","yitian.general_is_male")end
local function known_card(self,id)return known(self:getKnownCardById(id),"disclosed card "..tostring(id))end
local function memory(self,key)local v,ok=self:getStrategyMemory("yitian."..key);if ok then return v end end
local function guixin_target(self)local name=known(self:getDecisionContext().guixin_modify_target,"Guixin2Modify");if name==false then return nil end;return known(self.room:findPlayerByObjectName(name,true),"Guixin2Modify target")end
local function hujia_count(self,p)local v,ok=self:getStrategyMemory("yitian.hujia:"..p:objectName());if ok then return v end;return p:getStrategyMark("caizhaoji_hujia")end
local dummy_plan = AIUsePlan.dummy
local source_classes={JuejiCard="jueji",LianliSlashCard="lianli-slash",GuihanCard="guihan",LexueCard="lexue",XunzhiCard="xunzhi",YtYisheCard="ytyishe",YtYisheAskCard="ytyishe_ask",TaichenCard="taichen",YTChengxiangCard="ytchengxiang",TouduCard="toudu"}
local function decode(text)
 local cl,raw=text:match("^@([%w_]+)=(.*)$");if not cl or not source_classes[cl]then ai_unsupported("unexpected authored skill card wire","yitian")end
 local ids={};if raw~="."then for id in raw:gmatch("[^+]+")do ids[#ids+1]=assert(tonumber(id))end end
 return cl,source_classes[cl],ids
end
local function parse_policy(self,text,request)local cl,skill,ids=decode(text);return self:evaluateTurnSkillCard(skill,cl,ids,request)end
local function selected_policy(self,text)local cl,skill,ids=decode(text);return self:bindSkillCard(skill,ids,nil,nil,cl)end
local function response_wire(self,wire)
 if wire=="."then return wire end
 local text,targets=wire:match("^(.-)%->(.*)$");local paid=selected_policy(self,text)
 return {kind="use_card",card_spec=paid:toCardSpec(),targets=targets:split("+")}
end
local function turn_lexue(self,source,material,request)
 return self:evaluateTurnConversion("lexue",source:getClassName(),{name=source:objectName(),skill="lexue",suit=sgs.Card_NoSuit,number=0,subcards={material:getEffectiveId()}},request)
end

sgs.weapon_range.YitianSword = 2
sgs.ai_use_priority.YitianSword = 2.625
--room->askForPlayerChosen(player,room->getAlivePlayers(),"yitian_sword","@YitianSword-lost",true,true)
sgs.ai_skill_playerchosen["yitian_sword"] = sgs.ai_skill_playerchosen["damage"]

ai_skill_invoke.weiwudi_guixin = true

local function findPlayerForModifyKingdom(self,players) --从目标列表中选择一名用于修改势力
	if players and not players:isEmpty() then
		local lord = self.room:getLord()
		local isGood = lord and self:isFriend(lord) --自己是否为忠方

		for _,player in sgs.qlist(players)do
			if not player:isLord() then
				if known(self:getRoleEstimate(player),"role estimate")=="loyalist" and not self:hasSkills("huashen|liqian",player) then
					local sameKingdom =lord and player:getKnownKingdom()==lord:getKnownKingdom()
					if isGood~=sameKingdom then
						return player
					end
				elseif lord and lord:hasLordSkill("xueyi") and not player:isLord() and not self:hasSkills("huashen|liqian",player) then
					local isQun = player:getKnownKingdom()=="qun"
					if isGood~=isQun then
						return player
					end
				end
			end
		end
	end
end

local function chooseKingdomForPlayer(self,to_modify) --选择合适的势力以修改目标势力
	local lord = self.room:getLord()
	local isGood = self:isFriend(lord)
	if known(self:getRoleEstimate(to_modify),"role estimate")=="loyalist" or known(self:getRoleEstimate(to_modify),"role estimate")=="renegade" then
		if isGood then
			return lord and lord:getKnownKingdom()
		else
			-- find a kingdom that is different from the lord
			local kingdoms = {"qun","wei","shu","wu"}
			for _,kingdom in ipairs(kingdoms)do
				if lord and lord:getKnownKingdom()~=kingdom then
					return kingdom
				end
			end
		end
	elseif lord and lord:hasLordSkill("xueyi") and not to_modify:isLord() then
		return isGood and "qun" or "wei"
	elseif self.player:hasLordSkill("xueyi") then
		return "qun"
	end

	return "qun"
end

ai_skill_choice.weiwudi_guixin = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	if choices=="wei+shu+wu+qun" then --选择势力
		local to_modify = guixin_target(self)
		return ai_choice_result((chooseKingdomForPlayer(self,to_modify)), options)
	end

	if choices~="modify+obtain" then --选择主公技
		if choices:match("xueyi") and not self.room:getLieges("qun",self.player):isEmpty() then return ai_choice_result(("xueyi"), options) end
		if choices:match("weidai") and self:isWeak() then return ai_choice_result(("weidai"), options) end
		if choices:match("ruoyu") then return ai_choice_result(("ruoyu"), options) end
		local choice_table = choices:split("+")
		return ai_choice_result((choice_table[math.random(1,#choice_table)]), options)
	end

	-- two choices: modify and obtain --选择技能项
	if self.player:getRole()=="renegade" or self.player:getRole()=="lord" then
		return ai_choice_result(("obtain"), options)
	end

	local lord = self.room:getLord()
	if not lord then return ai_choice_result(("obtain"), options) end

	local skills = lord:getVisibleSkillList(true)
	local hasLordSkill = false
	for _,skill in sgs.qlist(skills)do
		if skill:isLordSkill() then
			hasLordSkill = true
			break
		end
	end

	if not hasLordSkill then
		return ai_choice_result(("obtain"), options)
	end

	local players = self.room:getOtherPlayers(self.player)
	players:removeOne(lord)
	if findPlayerForModifyKingdom(self,players) then
		return ai_choice_result(("modify"), options)
	else
		return ai_choice_result(("obtain"), options)
	end

    return ai_choice_result(nil, options)
end

sgs.ai_skill_playerchosen.weiwudi_guixin = function(self,players) --选择修改势力的目标
	if players and not players:isEmpty() then
		local player = findPlayerForModifyKingdom(self,players)
		return player or players:first()
	end
end

ai_skill_use["@@ytchengxiang"]=function(self, prompt, request)
	local prompts=prompt:split(":")
	local point=tonumber(prompts[4])
	local targets=self.friends
	if not targets then return end
	local compare_func = function(a,b)
		if a:isWounded()~=b:isWounded() then
			return a:isWounded()
		elseif a:isWounded() then
			return a:getHp()<b:getHp()
		else
			return a:getHandcardNum()<b:getHandcardNum()
		end
	end
	table.sort(targets,compare_func)
	local cards=self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	cards = self:sortByUseValue(cards,true)
	local opt1,opt2
	for _,card in ipairs(cards)do
		if card:getNumber()==point then opt1 = "@YTChengxiangCard="..card:getId().."->"..targets[1]:objectName() break end
	end
	for _,card1 in ipairs(cards)do
		for __,card2 in ipairs(cards)do
			if card1:getId()==card2:getId() then
			elseif card1:getNumber()+card2:getNumber()==point then
				if #targets>=2 and targets[2]:isWounded() then
					opt2 = "@YTChengxiangCard="..card1:getId().."+"..card2:getId().."->"..targets[1]:objectName().."+"..targets[2]:objectName()
					break
				elseif targets[1]:getHp()==1 or self:getUseValue(card1)+self:getUseValue(card2)<=6 then
					opt2 = "@YTChengxiangCard="..card1:getId().."+"..card2:getId().."->"..targets[1]:objectName()
					break
				end
			end
		end
		if opt2 then break end
	end
	if opt1 and opt2 then
		if self.player:getHandcardNum()>7 then return response_wire(self,opt2)else return response_wire(self,opt1)end
	end
	return response_wire(self,opt2 or opt1 or ".")
end

sgs.ai_card_intention.YTChengxiangCard = sgs.ai_card_intention.QingnangCard

function sgs.ai_cardneed.ytchengxiang(to,card,self)
	return card:getNumber()<8 and self:getUseValue(card)<6 and to:hasSkill("ytchengxiang") and to:getHandcardNum()<12
end

ai_skill_invoke.jueji = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if not target then self:remember("jueji_card",false) return (false) or false end
	local invoke = self:doDisCard(target,"h")
	if invoke then
		local cards = sgs.QList2Table(self.player:getHandcards())
		cards = self:sortByUseValue(cards,true)
		self:remember("jueji_card",cards[1]:getId())
	end
	return (invoke) or false
end

ai_fill_skill["jueji"] = function(self, options, request)
    local inclusive = options and options.inclusive

	return self:legacySkillSeed("jueji","JuejiCard",request)
end

ai_card_use.JuejiCard = function(self, card, use, request)
	if not self.player:canPindian() then return end
	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum()==1 and zhugeliang:objectName()~=self.player:objectName()
	  and self:getEnemyNumBySeat(self.player,zhugeliang)>0 and zhugeliang:getHp()<=2 and self.player:canPindian(zhugeliang) then
		local cards = sgs.QList2Table(self.player:getHandcards())
		cards = self:sortByUseValue(cards,true)
		self:remember("jueji_card",cards[1]:getId())
		use.card = self:bindSkillCard("jueji",{},nil,nil,"JuejiCard")
		use.to:append(zhugeliang)
		return
	end

	self.enemies = self:sort(self.enemies,"defense")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()

	if (self:needKongcheng() and self.player:getHandcardNum()==1) or not self:hasLoseHandcardEffective() then
		for _,enemy in ipairs(self.enemies)do
			if self:doDisCard(enemy,"h",true) and self.player:canPindian(enemy) then
				self:remember("jueji_card",max_card:getId())
				use.card = self:bindSkillCard("jueji",{},nil,nil,"JuejiCard")
				use.to:append(enemy)
				return
			end
		end
	end

	for _,enemy in ipairs(self.enemies)do
		if self:doDisCard(enemy,"h",true) and self.player:canPindian(enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if self:getKnownNum(enemy)==enemy:getHandcardNum() then
				allknown = allknown+1
			end
			if (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown>0)
				or (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown<1 and max_point>10)
				or (not enemy_max_card and max_point>10) then
				self:remember("jueji_card",max_card:getId())
				use.card = self:bindSkillCard("jueji",{},nil,nil,"JuejiCard")
				use.to:append(enemy)
				return
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	if self:getOverflow()>0 then
		for _,enemy in ipairs(self.enemies)do
			if self:doDisCard(enemy,"h",true) and self.player:canPindian(enemy) then
				self:remember("jueji_card",cards[1]:getId())
				use.card = self:bindSkillCard("jueji",{},nil,nil,"JuejiCard")
				use.to:append(enemy)
				return
			end
		end
	end
	return
end

sgs.ai_use_priority.JuejiCard = 3.4
sgs.ai_card_intention.JuejiCard = function(self,card,from,tos)
	local intention = 10
	local to = tos[1]
	if self:needKongcheng(to) and to:getHandcardNum()==1 then
		intention = 0
	end
	self:updateIntention(from,tos[1],intention)
end
sgs.ai_cardneed.jueji = sgs.ai_cardneed.bignumber
sgs.dynamic_value.control_card.JuejiCard = true

function sgs.ai_skill_pindian.jueji(minusecard,self,requestor,maxcard)
	if self:isFriend(requestor) then return end
	if maxcard:getNumber()==13 then return maxcard end
	if (maxcard:getNumber()/13)^requestor:getHandcardNum()<=0.6 then return minusecard end
end

ai_skill_invoke.lukang_weiyan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local handcard = self.player:getHandcardNum()
	local max_card = self.player:getMaxCards()
	local target = 0
	local slashnum = 0

	for _,slash in ipairs(self:getCards("Slash"))do
		for _,enemy in ipairs(self.enemies)do
			if self.player:canSlash(enemy,slash) and self:slashIsEffective(slash,enemy)
			and not self:slashProhibit(slash,enemy) and self:isGoodTarget(enemy,self.enemies,slash) then
				slashnum = slashnum+1
				target = target+1
				break
			end
		end
	end

	local prompt = data:toString()
	if prompt=="draw2play" then
		if self:needBear() then return (false) or false end
		if slashnum>1 and target>0 then return (true) or false end
		if self.player:isSkipped(sgs.Player_Play) and #(self:getTurnUse())>0 then return (true) or false end
		return (false) or false
	elseif prompt=="play2draw" then
		if self:needBear() then return (true) or false end
		if slashnum>0 and target>0 then return (false) or false end
		if #(self:getTurnUse())==0 then return (true) or false end
		return (false) or false
	end
	return false

end

function sgs.ai_cardneed.lukang_weiyan(to,card,self)
	return isCard("Slash",card,to) and getKnownCard(to,self.player,"Slash",true)<2
end

ai_skill_choice.wuling = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	if choices:match("water") then
		local weak_friend,weak_enemy = 0,0
		for _,player in sgs.qlist(self.room:getAlivePlayers())do
			if self:isWeak(player) then
				if self:isEnemy(player) then
					weak_enemy = weak_enemy+1
					if player:isLord() then weak_enemy = weak_enemy+1 end
				elseif self:isFriend(player) then
					weak_friend = weak_friend+1
					if player:isLord() then weak_friend = weak_friend+1 end
				end
			end
		end
		if weak_friend>0 and weak_friend>=weak_enemy then return ai_choice_result(("water"), options) end
	end
	if choices:match("earth") then
		if #(self:getChainedFriends())>#(self:getChainedEnemies()) and
			#(self:getChainedFriends())+#(self:getChainedEnemies())>1 then return ai_choice_result(("earth"), options) end
		if self:hasWizard(self.enemies,true) and not self:hasWizard(self.friends,true) then
			for _,player in sgs.qlist(self.room:getAlivePlayers())do
				if player:containsTrick("lightning") then return ai_choice_result(("earth"), options) end
			end
		end
	end
	if choices:match("fire") then
		for _,enemy in ipairs(self.enemies)do
			if enemy:hasArmorEffect("Vine") then return ai_choice_result(("fire"), options) end
		end
		if #(self:getChainedFriends())<#(self:getChainedEnemies()) and
			#(self:getChainedFriends())+#(self:getChainedEnemies())>1 then return ai_choice_result(("fire"), options) end
	end
	if choices:match("wind") then
		for _,enemy in ipairs(self.enemies)do
			if enemy:hasArmorEffect("Vine") then return ai_choice_result(("wind"), options) end
		end
		for _,friend in ipairs(self.friends)do
			if friend:hasSkill("huoji") then return ai_choice_result(("wind"), options) end
		end
		if #(self:getChainedFriends())<#(self:getChainedEnemies()) and
			#(self:getChainedFriends())+#(self:getChainedEnemies())>1 then return ai_choice_result(("wind"), options) end
		for _,friend in ipairs(self.friends)do
			if friend:hasWeapon("fan") then return ai_choice_result(("wind"), options) end
		end
		if self:getCardId("FireSlash") or self:getCardId("FireAttack") then return ai_choice_result(("wind"), options) end
	end
	if choices:match("thunder") then
		if self:hasWizard(self.friends,true) and not self:hasWizard(self.enemies,true) then
			for _,player in sgs.qlist(self.room:getAlivePlayers())do
				if player:containsTrick("lightning") then return ai_choice_result(("thunder"), options) end
			end
			for _,friend in ipairs(self.friends)do
				if friend:hasSkill("leiji") then return ai_choice_result(("thunder"), options) end
			end
		end
		if self:getCardId("ThunderSlash") then return ai_choice_result(("thunder"), options) end
	end
	local choices_table = choices:split("+")
	return ai_choice_result((choices_table[math.random(1,#choices_table)]), options)
end

sgs.ai_skill_playerchosen.lianli = function(self,targets)

	if self.room:getMode()=="couple" then
		for _,friend in ipairs(self.friends_noself)do
			local name = string.lower(friend:getGeneralName())
			if name:find("zhangfei") then
				return friend
			end
		end
	return "."
	end

	self.friends = self:sort(self.friends,"defense")
	local AssistTarget = self:AssistTarget()
	if AssistTarget and AssistTarget:isMale() and not AssistTarget:hasSkill("manjuan") then return AssistTarget end

	for _,friend in ipairs(self.friends_noself)do --优先考虑与队友连理
		if friend:isMale() and not friend:hasSkill("manjuan") then
			return friend
		end
	end

	for _,friend in ipairs(self.friends_noself)do
		if friend:isMale() then
			return friend
		end
	end


	if known(self.world.turn_count,"turn count")<=2 then
		for _,player in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if player:isMale() and not self:isEnemy(player) and not player:inMyAttackRange(self.player) then
				return player
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.lianli = -10
sgs.ai_card_intention.LianliCard = -80

ai_skill_invoke["lianli_jink"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local tied
	for _,player in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if player:getStrategyMark("@tied")>0 then tied = player break end
	end
	if self:hasEightDiagramEffect(tied) then return (true) or false end
	return (self:getCardsNum("Jink")==0) or false
end

sgs.ai_choicemade_filter.skillInvoke["lianli-jink"] = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		self:setStrategyMemory("response_source:lianlisource",player:objectName())
	end
end

sgs.ai_choicemade_filter.cardResponded["@lianli-jink"] = function(self,player,promptlist)
	if promptlist[#promptlist]~="" then
		local xiahoujuan = player:getRoom():findPlayerBySkillName("lianli")
		assert(xiahoujuan)
		self:updateIntention(player,xiahoujuan,-80)
		self:setStrategyMemory("response_source:lianlisource",false)
	end
end

sgs.ai_skill_cardask["@lianli-jink"] = function(self)
	local players = self.room:getOtherPlayers(self.player)
	local target
	for _,p in sgs.qlist(players)do
		if p:getStrategyMark("@tied")>0 then target = p break end
	end
	if not self:isFriend(target) then return "." end
	return self:getCardId("Jink") or "."
end

function sgs.ai_slash_prohibit.lianli(self,from,to,card)
	if self:isFriend(to) then return false end
	if self:canLiegong(to,from) then return false end
	local players = sgs.QList2Table(self.room:getOtherPlayers(to))
	for _,player in ipairs(players)do
		if player:getStrategyMark("@tied")>0 and self:isFriend(player,to) then
			if player:hasSkill("tiandu") and sgs.ai_slash_prohibit.tiandu(self,from,player,card) then return true end
			if player:hasLordSkill("hujia") and sgs.ai_slash_prohibit.hujia(self,from,player,card) then return true end
			if player:hasSkill("leiji") and sgs.ai_slash_prohibit.leiji(self,from,player,card) then return true end
			if player:hasSkill("weidi") and sgs.ai_slash_prohibit.weidi(self,from,player,card) then return true end
		end
	end
	return false
end

ai_fill_skill["lianli-slash"] = function(self, options, request)
    local inclusive = options and options.inclusive
 --考虑主动使用连理杀
	return self:legacySkillSeed("lianli-slash","LianliSlashCard",request)
end

ai_card_use.LianliSlashCard = function(self, card, use, request)
	if self.player:hasUsed("LianliSlashCard") and not memory(self,"lianlislash") then return end
	if use.card then use.card = self:bindSkillCard("lianli-slash",{},nil,nil,"LianliSlashCard") end
	local dummy_use = dummy_plan()
	if self.player:getStrategyFlag("slashTargetFix") then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if p:getStrategyFlag("SlashAssignee") then
				dummy_use.to:append(p)
			end
		end
	end
	local slash = self:getEvaluationCard("slash")
	self:useCardSlash(slash,dummy_use)
	if dummy_use.card and dummy_use.to:length()>0 then
		use.card = self:bindSkillCard("lianli-slash",{},nil,nil,"LianliSlashCard")
		for _,p in sgs.qlist(dummy_use.to)do
			use.to:append(p)
		end
	end
end

sgs.ai_choicemade_filter.cardUsed.LianliSlashCard = function(self,player,carduse)
	self:setStrategyMemory("yitian.lianlislash",false)
end

sgs.ai_choicemade_filter.cardResponded["@lianli-slash"] = function(self,player,promptlist)
	if promptlist[#promptlist]~="" then
		self:setStrategyMemory("yitian.lianlislash",true)
	end
end

sgs.ai_skill_cardask["@lianli-slash"] = function(self)
	local players = self.room:getOtherPlayers(self.player)
	local target
	for _,p in sgs.qlist(players)do
		if p:getStrategyMark("@tied")>0 then target = p break end
	end
	if not self:isFriend(target) then return "." end
	return self:getCardId("Slash") or "."
end

ai_skill_invoke["lianli_slash"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local asked = data:toStringList()
	local prompt = asked[2]
	if self:askForCard("slash",prompt,1)=="." then return (false) or false end

	local xiahoujuan = self.room:findPlayerBySkillName("lianli")
	if xiahoujuan and xiahoujuan:getPhase()~=sgs.Player_NotActive
		and self:isFriend(xiahoujuan) and self:getOverflow(xiahoujuan)>2 and not self:hasCrossbowEffect(xiahoujuan) then
		return (true) or false
	end

	local cards = self.player:getHandcards()
	for _,card in sgs.qlist(cards)do
		if isCard("Slash",card,self.player) then
			return (false) or false
		end
	end
	return (xiahoujuan and self:isFriend(xiahoujuan)) or false
end


ai_skill_invoke.tongxin = true


ai_fill_skill["guihan"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self:getOverflow()<=0 then return end
	if self.room:alivePlayerCount()==2 or self.role=="renegade" then return end
	if #self.friends_noself==0 then return end
	local rene = 0
	for _,ap in sgs.qlist(self.room:getAlivePlayers())do
		if known(self:getRoleEstimate(ap),"role estimate")=="renegade" then rene = rene+1 end
	end
	if #self.friends+#self.enemies+rene<self.room:alivePlayerCount() then return end
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByUseValue(cards)
	local red_cards = {}
	for index = #cards,1,-1 do
		if self:getUseValue(cards[index])>=6 then break end
		if cards[index]:isRed() then
			if #red_cards==0 or (#red_cards==1 and cards[index]:getSuit()==known_card(self,red_cards[1]):getSuit()) then
				table.insert(red_cards,cards[index]:getId())
				table.remove(cards,index)
			end
			if #red_cards>=2 then break end
		end
	end
	if #red_cards==2 then return parse_policy(self,"@GuihanCard="..table.concat(red_cards,"+")) end
end

function ai_card_use.GuihanCard(self, card, use, request)
	local values,range = {},self.player:getAttackRange()
	local nplayer = self.player
	for i = 1,self.player:aliveCount()do
		local fediff,add,isfriend = 0,0,nil
		local np = nplayer
		for value = #self.friends_noself,1,-1 do
			np = np:getNextAlive()
			if np:objectName()==self.player:objectName() then
				if self:isFriend(nplayer) then fediff = fediff+value
				else fediff = fediff-value
				end
			else
				if self:isFriend(np) then
					fediff = fediff+value
					if isfriend then add = add+1
					else isfriend = true end
				elseif self:isEnemy(np) then
					fediff = fediff-value
					isfriend = false
				end
			end
		end
		values[nplayer:objectName()] = fediff+add
		nplayer = nplayer:getNextAlive()
	end
	local function get_value(a)
		local ret = 0
		for _,enemy in ipairs(self.enemies)do
			if a:objectName()~=enemy:objectName() and a:distanceTo(enemy)<=range then ret = ret+1 end
		end
		return ret
	end
	local function compare_func(a,b)
		if values[a:objectName()]~=values[b:objectName()] then
			return values[a:objectName()]>values[b:objectName()]
		else
			return get_value(a)>get_value(b)
		end
	end
	local players = sgs.QList2Table(self.room:getAlivePlayers())
	table.sort(players,compare_func)
	if values[players[1]:objectName()]>0 and players[1]:objectName()~=self.player:objectName() then
		use.card = card
		use.to:append(players[1])
	end
end

sgs.ai_use_priority.GuihanCard = 8

ai_skill_invoke.caizhaoji_hujia = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local zhangjiao = self.room:findPlayerBySkillName("guidao")
	if zhangjiao and self:isEnemy(zhangjiao) and getKnownCard(zhangjiao,self.player,"black",false,"he")>1 then return (false) or false end
	if not self.player:faceUp() then
		return (true) or false
	end
	local invokeNum = hujia_count(self,self.player)
	if invokeNum<2 then
		self:setStrategyMemory("yitian.hujia:"..self.player:objectName(),invokeNum+1)
		return (true) or false
	else
		return (false) or false
	end
	return false


end

sgs.ai_event_callback[sgs.EventPhaseEnd] = sgs.ai_event_callback[sgs.EventPhaseEnd] or {}
sgs.ai_event_callback[sgs.EventPhaseEnd].caizhaoji_hujia = function(self,player,data)
	if player:getPhase()==sgs.Player_Finish then
		self:setStrategyMemory("yitian.hujia:"..player:objectName(),0)
	end
end

function ai_skill_choice.shenjun(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local gender
	if known(self:isRolePredictable(),"role predictability") then
		local male = 0
		for _,enemy in ipairs(self.enemies)do
			if general_male(self,enemy) then male = male+1 end
		end
		gender = (male<#self.enemies-male)
	else
		local males = 0
		for _,player in sgs.qlist(self.room:getAlivePlayers())do
			if player:isMale() then males = males+1 end
		end
		gender = (males<=self.player:aliveCount()-males)
	end
	if self.player:getSeat()<self.room:alivePlayerCount()/2 then gender = not gender end
	if gender then return ai_choice_result(("male"), options) else return ai_choice_result(("female"), options) end

    return ai_choice_result(nil, options)
end

function sgs.ai_slash_prohibit.shenjun(self,from,to,card)
	if from:hasSkill("jueqing") then return false end --绝情返回false
	if from:hasSkill("nosqianxi") and from:distanceTo(to)==1 then return false end --潜袭返回false
	if from:getGender()==to:getGender() then return true end --性别相同返回true
	if not card:isKindOf("ThunderSlash") then return true end --不是雷杀的返回true
	return false --统一返回false
end

function ai_skill_invoke.shaoying(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	local enemynum = 0
	for _,p in sgs.qlist(self.room:getOtherPlayers(damage.to))do
		if damage.to:distanceTo(p)<=1 and self:isEnemy(p) then
			enemynum = enemynum+1
		end
	end
	if enemynum<1 then return (false) or false end
	local zhangjiao = self.room:findPlayerBySkillName("guidao")
	if zhangjiao and self:isEnemy(zhangjiao) and getKnownCard(zhangjiao,self.player,"black",false,"he")>1 then return (false) or false end
	return (true) or false
end

sgs.ai_skill_playerchosen.shaoying = function(self,targets)
	local tos = {}
	for _,target in sgs.qlist(targets)do
		if self:isEnemy(target) then table.insert(tos,target) end
	end

	if #tos>0 then
		tos = self:SortByAtomDamageCount(tos,self.player,sgs.DamageStruct_Fire,nil)
		return tos[1]
	end
end

sgs.ai_playerchosen_intention.shaoying = function(self,from,to)
	self:setStrategyMemory("yitian.shaoying_target",to:objectName())
	self:updateIntention(from,to ,10)
end



sgs.ai_skill_playerchosen.gongmou = function(self,targets)
	local gongmou_target
	if self.player:hasSkill("manjuan") then return nil end
	self.friends_noself = self:sort(self.friends_noself,"defense")
	for _,friend in ipairs(self.friends_noself)do
		if friend:hasSkill("enyuan") then
			gongmou_target = friend
		elseif friend:hasSkill("manjuan") then
			return friend
		end
	end
	if gongmou_target then return gongmou_target end

	self.enemies = self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if not self:willSkipDrawPhase(enemy) and not (self:needKongcheng(enemy) and self.player:getHandcardNum()>enemy:getHandcardNum())
		  and not self:hasSkills("manjuan|qiaobian",enemy) then
			return enemy
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.gongmou = function(self,from,to)
	local intention = 60
	if to:hasSkill("manjuan") then intention = -intention
	elseif to:hasSkill("enyuan") then intention = 0
	end
	self:updateIntention(from,to,intention)
	self:setStrategyMemory("yitian.gongmou_target",false)
end

sgs.ai_skill_discard.gongmou = function(self,discard_num,optional,include_equip)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_discard = {}
	local compare_func = function(a,b)
		return self:getKeepValue(a)<self:getKeepValue(b)
	end
	table.sort(cards,compare_func)
	for _,card in ipairs(cards)do
		if #to_discard>=discard_num then break end
		table.insert(to_discard,card:getId())
	end

	return to_discard
end

sgs.ai_cardshow.lexue = function(self,requestor)
	local cards = self.player:getHandcards()
	if self:isFriend(requestor)
	then
		for _,card in sgs.qlist(cards)do
			if card:isKindOf("Peach") and requestor:isWounded()
			then return card end
		end
		for _,card in sgs.qlist(cards)do
			if card:isNDTrick()
			then return card end
		end
		for _,card in sgs.qlist(cards)do
			if card:isKindOf("Slash")
			then return card end
		end
		for _,card in sgs.qlist(cards)do
			if card:isKindOf("EquipCard")
			then return card end
		end
	else
		for _,card in sgs.qlist(cards)do
			if card:isKindOf("Jink")
			then return card end
		end
		for _,card in sgs.qlist(cards)do
			if card:getTypeId()<3 and not card:isAvailable(requestor)
			then return card end
		end
	end
	return self.player:getRandomHandCard()
end

ai_fill_skill["lexue"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self.player:getStrategyFlag("lexue")
	then
		local lexuesrc = known_card(self,self.player:getStrategyMark("lexue"))
		for _,hcard in ipairs(self:sortByUseValue(self.player:getHandcards(),true))do
			if hcard:getSuit()==lexuesrc:getSuit()
			then
				local lexuec = turn_lexue(self,lexuesrc,hcard,request)
				if self:getUseValue(lexuec)>self:getUseValue(hcard)
				then return lexuec end
			end
		end
	end
	return self.player:usedTimes("LexueCard")<1 and self:legacySkillSeed("lexue","LexueCard",request)
end

ai_card_use.LexueCard = function(self, card, use, request)
	if #self.enemies>0
	then
		local target
		self.enemies = self:sort(self.enemies,"hp")
		local enemy = self.enemies[1]
		if self:isWeak(enemy) and not enemy:isKongcheng()
		then target = enemy
		else
			self.friends_noself = self:sort(self.friends_noself,"handcard")
			target = self.friends_noself[#self.friends_noself]
			if target and target:isKongcheng() then target = nil end
		end
		if not target then
			self.enemies = self:sort(self.enemies,"handcard")
			if self.enemies[1] and not self.enemies[1]:isKongcheng() then target = self.enemies[1] else return end
		end
		use.card = self:bindSkillCard("lexue",{},nil,nil,"LexueCard")
		use.to:append(target)
	end
end

function sgs.ai_cardsview.lexue(self,class_name,player)
	local lexuesrc = known_card(self,player:getStrategyMark("lexue"))
	if lexuesrc:isKindOf(class_name) then else return end
	for _,hcard in ipairs(self:sortByKeepValue(player:getHandcards()))do
		if hcard:getSuit()==lexuesrc:getSuit()
		then
			return {name=lexuesrc:objectName(),skill="lexue",suit=sgs.Card_NoSuit,number=0,subcards={hcard:getKnownEffectiveId()}}
			-- if self:getUseValue(lexuec)>self:getUseValue(hcard)
			-- then return lexuec:toString() end
		end
	end
end

sgs.ai_use_priority.LexueCard = 10

ai_fill_skill["xunzhi"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self:needBear() then return end
	if not known(self.world.mode_policy.enable_hegemony,"hegemony config") then
		if self.role=="renegade" or self.role=="lord" then return end
	end
	if (#self.friends>1) or (#self.enemies==1 and known(self.world.turn_count,"turn count")>1) then
		if self:getAllPeachNum()==0 and self.player:getHp()==1 then
			return self:legacySkillSeed("xunzhi","XunzhiCard",request)
		end
		if self:isWeak() and self.role=="rebel" and self.player:inMyAttackRange(self.room:getLord()) and self:hasCrossbowEffect() then
			return self:legacySkillSeed("xunzhi","XunzhiCard",request)
		end
	end
end

function ai_card_use.XunzhiCard(self, card, use, request)
	use.card = self:bindSkillCard("xunzhi",{},nil,nil,"XunzhiCard")
end

function sgs.ai_slash_prohibit.dushi(self,from,to,card)
	if from:hasSkill("jueqing") then return false end
	if from:getStrategyFlag("NosJiefanUsed") then return false end
	return from:isLord() and #self.enemies>1
end

ai_skill_invoke.zhenggong = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if known(self.world.turn_count,"turn count")<=1 and #self.enemies==0 then return (false) or false end
	return (true) or false
end



ai_skill_use["@@toudu"] = function(self, prompt, request)
	local toudu_target = nil
	local targets = sgs.SPlayerList()
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if self.player:canSlash(p,nil,false) then targets:append(p) end
	end
	if targets:length()==0 then return "." end
	toudu_target = sgs.ai_skill_playerchosen.zero_card_as_slash(self,targets)
	if not toudu_target then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	for _,card in ipairs(cards)do
		if not (isCard("Peach",card,self.player) and self:isFriend(toudu_target)) then
			return response_wire(self,"@TouduCard="..card:getKnownEffectiveId().."->"..toudu_target:objectName())
		end
	end
	return "."
end

sgs.ai_card_intention.TouduCard = sgs.ai_card_intention.Slash

sgs.ai_need_damaged.toudu = function(self,attacker,player)
	if not player:hasSkill("toudu") or player:faceUp() then return false end
	local peaches = getCardsNum("Peach",player)
	if peaches>=player:getLostHp() and peaches>0 then return true end
	if self.player:objectName()==player:objectName() and player:getHp()>1 then
		for _,target in ipairs(self.enemies)do
			if self:isEnemy(target) and getCardsNum("Jink",target,self.player)<1
			and (target:getHp()==1 or self:ajustDamage(player,target,1,self:getEvaluationCard())>1 and target:getHp()==2)
			and self:slashIsEffective(self:getEvaluationCard(),target)
			then return true end
		end
	end
	return false
end


ai_fill_skill["ytyishe"] = function(self, options, request)
    local inclusive = options and options.inclusive

	if self:needBear() then return end
	if not self.player:hasUsed("YtYisheCard") then
		return parse_policy(self,"@YtYisheCard=.")
	end
	local n = self.player:getHandcardNum()
	if n<1 then return end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local usecards = {}
	local getOverflow = math.max(self:getOverflow(),0)
	local discards = self:askForDiscard("dummyreason",math.min(getOverflow,5),math.min(getOverflow,5))
	if self:needKongcheng() and n<6 then
		for _,card in ipairs(cards)do
			table.insert(usecards,card:getId())
		end
	else
		for _,card in ipairs(discards)do
			table.insert(usecards,card)
		end
	end
	if #usecards>0 then
		return parse_policy(self,"@YtYisheCard="..table.concat(usecards,"+"))
	end
end

ai_card_use.YtYisheCard = function(self, card, use, request)
	self:setPriorityValue("YtYisheCard",10,"yitian")
	if self.player:getPile("ytrice"):isEmpty() then
		self:setPriorityValue("YtYisheCard",0,"yitian")
		if self.player:hasUsed("YtYisheCard") then
			use.card = card
			return
		end
	else
		if not self.player:hasUsed("YtYisheCard") then use.card = card return end
	end
end

ai_skill_choice.ytyishe_ask = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	if self:isFriend(self.room:getCurrent()) then return ai_choice_result(("allow"), options) else return ai_choice_result(("disallow"), options) end

    return ai_choice_result(nil, options)
end

ai_fill_skill["ytyishe_ask"] = function(self, options, request)
    local inclusive = options and options.inclusive

	for _,player in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if player:hasSkill("ytyishe") and not player:getPile("ytrice"):isEmpty() then
			return parse_policy(self,"@YtYisheAskCard="..player:getPile("ytrice"):first())
		end
	end
end

ai_card_use.YtYisheAskCard = function(self, card, use, request)
	self:setPriorityValue("YtYisheAskCard",9.1,"yitian")
	if known(self:getRoleEstimate(self.player),"role estimate")=="neutral" then self:setPriorityValue("YtYisheAskCard",0,"yitian") end
	local zhanglu
	local cards
	for _,player in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if player:hasSkill("ytyishe") and not player:getPile("ytrice"):isEmpty() then zhanglu=player cards=player:getPile("ytrice") break end
	end
	if not zhanglu or self:isEnemy(zhanglu) then return end
	cards = sgs.QList2Table(cards)
	for _,pcard in ipairs(cards)do
		use.card = card
		return
	end
end

sgs.ai_event_callback[sgs.ChoiceMade].ytyishe_ask = function(self,player,data)
	-- Choice events carry "skillChoice:ytyishe_ask:allow" as kind, reason and answer.
	local details=data.details
	if data.kind=="choice" and type(details)=="table" and details.choice_kind=="skillChoice"
		and data.reason=="ytyishe_ask" and details.answer=="allow" then
		self:updateIntention(self.player,self.room:getCurrent(),-70)
	end
end

sgs.ai_use_priority.YtYisheAskCard = 9.1


ai_skill_invoke.xiliang = true

ai_skill_choice.xiliang = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	if self.player:hasSkill("manjuan") or self:needKongcheng(self.player) then return ai_choice_result(("put"), options) end
	if not self.player:hasSkill("ytyishe") then return ai_choice_result(("obtain"), options) end
	if self:willSkipPlayPhase() and self.player:getHandcardNum()>2 then return ai_choice_result(("put"), options) end
	if self.player:getHandcardNum()<3 or self:getCardsNum("Jink")<1 then return ai_choice_result(("obtain"), options) end
	if self:getOverflow()>=0 then return ai_choice_result(("put"), options) end
	return ai_choice_result(("obtain"), options)
end

sgs.ai_skill_defense.xiliang = 2


ai_skill_invoke.ytzhenwei = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (not self:needKongcheng(self.player)) or false
end

ai_skill_invoke.yitian = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local damage = data:toDamage()
	return (self:isFriend(damage.to)) or false
end

ai_fill_skill["taichen"] = function(self, options, request)
    local inclusive = options and options.inclusive

	return self:legacySkillSeed("taichen","TaichenCard",request)
end

ai_card_use.TaichenCard = function(self, card, use, request)
	local target,card_str
	local targets,friends,enemies = {},{},{}
	local weapon = self.player:getWeapon()

	local hcards = self.player:getHandcards()
	local hand_weapon
	for _,hcard in sgs.qlist(hcards)do
		if hcard:isKindOf("Weapon") then
			hand_weapon = true
			card_str = "@TaichenCard="..hcard:getId()
		end
	end
	if hand_weapon or self.player:getHp()>3 then
		if not card_str then card_str = "@TaichenCard=." end
		for _,player in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if self.player:canSlash(player) then
				table.insert(targets,player)

				if self:isFriend(player) then
					table.insert(friends,player)
				elseif self:isEnemy(player) and self:doDisCard(player,"he",nil,2) then
					table.insert(enemies,player)
				end
			end
		end
	else
		if weapon then card_str = "@TaichenCard="..weapon:getId() end
		for _,player in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if self.player:distanceTo(player)<=1 then
				table.insert(targets,player)

				if self:isFriend(player) then
					table.insert(friends,player)
				elseif self:isEnemy(player) and self:doDisCard(player,"he",nil,2) then
					table.insert(enemies,player)
				end
			end
		end
	end

	if #targets==0 then return end
	for _,player in ipairs(targets)do
		if not player:containsTrick("YanxiaoCard") and player:containsTrick("lightning") and self:getFinalRetrial(player)==2 then
			target = player
			break
		end
	end
	if not target and #friends~=0 then
		for _,friend in ipairs(friends)do
			if not friend:containsTrick("YanxiaoCard") and not (friend:hasSkill("qiaobian") and not friend:isKongcheng())
			  and (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
				target = friend
				break
			end
			if friend:getCards("e"):length()>1 and self:hasSkills(sgs.lose_equip_skill,friend) then
				target = friend
				break
			end
		end
	end
	if not target and #enemies>0 then
		enemies = self:sort(enemies,"defense")
		for _,enemy in ipairs(enemies)do
			if enemy:containsTrick("YanxiaoCard") and (enemy:containsTrick("indulgence") or enemy:containsTrick("supply_shortage")) then
				target = enemy
				break
			end
			if self:getDangerousCard(enemy) then
				target = enemy
				break
			end
			if not enemy:hasSkill("tuntian+zaoxian") then
				target = enemy
				break
			end
		end
	end

	if not target then return end
	if not card_str then
		if self:isFriend(target) and self.player:getHp()>2 then card_str = "@TaichenCard=." end
	end

	if card_str then
		if self:isFriend(target) then
			if not use.isDummy then self:setStrategyPlayerFlag(target,"TaichenOK",true) end
		end
		use.to:append(target)
		use.card = selected_policy(self,card_str)
	end
end

sgs.ai_cardneed.taichen = sgs.ai_cardneed.weapon
sgs.taichen_keep_value = sgs.qiangxi_keep_value
sgs.ai_use_priority.TaichenCard = 3.6
sgs.ai_card_intention.TaichenCard = function(self,card,from,tos)
	if #tos>0 then
		for _,to in ipairs(tos)do
			if to:getStrategyFlag("TaichenOK") then
				self:setStrategyPlayerFlag(to,"TaichenOK",false)
				self:updateIntention(from,to,-30)
			else
				self:updateIntention(from,to,30)
			end
		end
	end
	return 0
end

sgs.ai_use_revises.ytchengxiang = function(self,card,use)
	if self.player:getHandcardNum()<8
	and card:getNumber()<7
	then
		if card:isKindOf("EquipCard")
		then
			if self:getSameEquip(card)
			then return false end
		elseif card:getTypeId()>0
		then return false end
	end
end

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, player, m, query, context)
        if query(player,"hasSkill","zaoyao") then return query(self.player,"getHandcardNum"), true end
        return m
    end
    local function policy_2(self, from, to, dmg, card, nature, damage_call, helpers, context)
        if nature=="F" or damage_call(self, "hasWulingEffect", "@fire") then
            if damage_call(self, "hasWulingEffect", "@wind") then dmg = dmg+1 end
            if damage_call(self, "hasWulingEffect", "@earth") and not damage_call(to, "hasSkill", "ranshang") then return 1, nature, true end
            nature = "F"
        end
        return dmg, nature
    end
    local function policy_3(self, from, to, dmg, card, nature, damage_call, helpers, context)
        if nature=="T" then
            if damage_call(self, "hasWulingEffect", "@earth") then return 1, nature, true end
            if damage_call(self, "hasWulingEffect", "@thunder") then dmg = dmg+1 end
        end
        return dmg, nature
    end
    local previous_1 = sgs.ai_getOverflow_skill["zaoyao"]
    sgs.ai_getOverflow_skill["zaoyao"] = function(self, player, m, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "before_max" and context.rule == "zaoyao" then
                return policy_1(self, player, context.value, context.query, context)
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, player, m) end
    end
    sgs.declareValueHookStages("ai_getOverflow_skill", "zaoyao", {
        {phase="before_max", rule="zaoyao", order=2801},
    })
    local previous_2 = sgs.ai_ajustdamage_from["wuling"]
    sgs.ai_ajustdamage_from["wuling"] = function(self, from, to, card, nature, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "before_from" and context.rule == "fire_wuling" then
                local damage, next_nature, terminal = policy_2(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            if context.phase == "after_from_head" and context.rule == "thunder_wuling" then
                local damage, next_nature, terminal = policy_3(self, from, to, context.value.damage, card, context.value.nature, context.query, context.extra[3], context)
                context.value.damage, context.value.nature = damage, next_nature
                return context.value, terminal
            end
            return context.value
        end
        if type(previous_2) == "function" then return previous_2(self, from, to, card, nature) end
    end
    sgs.declareValueHookStages("ai_ajustdamage_from", "wuling", {
        {phase="before_from", rule="fire_wuling", order=4000},
        {phase="after_from_head", rule="thunder_wuling", order=4900},
    })
end)()

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_need_damaged["sizhan"]
    local policy = function(self, from, to, card, context)
        local value, damage_call = context.value, context.query
        local from, card, helpers = context.extra[1], context.extra[2], context.extra[3]
        if damage_call(to,"hasSkill","sizhan") then return nil, true end
        return value
    end
    sgs.ai_need_damaged["sizhan"] = function(self, from, to, card, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "need_hp_slash_before_weapon" and context.rule == "sizhan" then
                return policy(self, from, to, card, context)
            end
            if type(previous) == "function" then return previous(self, from, to, card, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, from, to, card) end
    end
    sgs.declareValueHookStages("ai_need_damaged", "sizhan", {
        {phase="need_hp_slash_before_weapon", order=1, rule="sizhan"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_defense_slash["xiliang"]
    local policy = function(self, to, observer, context)
        local call, state = context.query, context.extra[1]
        local defense = context.value
        if not state.diagram then
            if state.knownJink < 1 and call(to, "hasSkill", "xiliang") then defense = defense - 2 end
        end
        return defense
    end
    sgs.ai_defense_slash["xiliang"] = function(self, to, observer, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "base" and context.rule == "slash_defense.base_xiliang" then
                return policy(self, to, observer, context)
            end
            if type(previous) == "function" then return previous(self, to, observer, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to, observer) end
    end
    sgs.declareValueHookStages("ai_defense_slash", "xiliang", {
        {phase="base", order=47, rule="slash_defense.base_xiliang"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_defense_slash["lianli"]
    local policy = function(self, to, observer, context)
        local call, state = context.query, context.extra[1]
        local defense = context.value
        local strategy_mark = state.strategy_mark
        if strategy_mark(self, to, "@tied") > 0 and not call(self.player, "hasSkill", "jueqing") then defense = defense + 1 end
        return defense
    end
    sgs.ai_defense_slash["lianli"] = function(self, to, observer, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "special_1" and context.rule == "slash_defense.tied" then
                return policy(self, to, observer, context)
            end
            if type(previous) == "function" then return previous(self, to, observer, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to, observer) end
    end
    sgs.declareValueHookStages("ai_defense_slash", "lianli", {
        {phase="special_1", order=17, rule="slash_defense.tied"},
    })
end)()
end
