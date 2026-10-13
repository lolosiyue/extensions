-- Fixed b6025acc YCZH2017 source policies. Native scopes own all actions.
local function known(v,key)if v==nil then ai_unsupported("YCZH2017 value unknown",key)end;return v end
local function call(o,m,...)
 if AIValue.isPlayer(o)then if m=="getMark"then m="getStrategyMark"elseif m=="hasFlag"then m="getStrategyFlag"end end
 if not o or type(o[m])~="function"then ai_unsupported("YCZH2017 query unavailable",m)end
 return known(o[m](o,...),m)
end
local function register_fill(row)
 setmetatable(row,{__newindex=function(t,k,v)rawset(t,k,v);if k=="getTurnUseCard"then sgs.ai_fill_skill[t.name]=v end end})
 if row.getTurnUseCard then sgs.ai_fill_skill[row.name]=row.getTurnUseCard end
end
local function order(t,sorted)for i,v in ipairs(sorted)do t[i]=v end;return t end
local function sort_players(self,t,...)return order(t,call(self,"sort",t,...))end
local function sort_keep(self,t,...)return order(t,call(self,"sortByKeepValue",t,...))end
local function sort_use(self,t,...)return order(t,call(self,"sortByUseValue",t,...))end
local function sort_need(self,t,...)return order(t,call(self,"sortByCardNeed",t,...))end
local function context(self,key)return known(self:getDecisionContext()[key],key)end
-- Funan reads the viewer's own property and tag (an absent tag is no card).
local function fact(self,key)
 if key=="funan_level_up"then return self.player:getPropertyValue("funan_level_up")==true end
 if key=="funan_card"then local v=self.player:getTag("FunanCard");if type(v)~="table"or next(v)==nil then return false end;return v end
 ai_unsupported("yczh2017 fact is not projected",key)
end
local function visible(self,id)return known(self:getKnownCardById(tonumber(id)),"lawful card "..tostring(id))end
local function evaluation(self,name)return self:getEvaluationCard(name or"slash")end
local function role(self,p)return known(self:getRoleEstimate(p),"viewer role estimate")end
local classes={ZhongjianCard="zhongjian",OLZhongjianCard="olzhongjian",MobileQingxianCard="mobileqingxian",MobileCanyunCard="mobilecanyun",WenguaCard="wengua",WenguagiveCard="wenguagive",HuiminCard="huimin",TongboCard="tongbo",FumianCard="fumian",ExtraCollateralCard="fumian"}
local function authored(self,text,bind)
 local class,ids=text:match("^@([%w_]+)=([%d+.]*)$")
 if not class or not classes[class]then ai_unsupported("invalid authored YCZH2017 card",text)end
 local costs={};if ids~="."then for id in ids:gmatch("%d+")do costs[#costs+1]=tonumber(id)end end
 if not bind and #costs==0 then return call(self,"legacySkillSeed",classes[class],class)end
 return call(self,"bindSkillCard",classes[class],costs,nil,nil,class)
end
local function remember(self,key,value)self:setStrategyMemory("yczh2017."..key,value)end
local function recall(self,key)return self:getStrategyMemory("yczh2017."..key)end
local function recall_player(self,key)local name=recall(self,key);return name and known(self.room:findPlayerByObjectName(name,true),key)or nil end
local function remember_target(self,key,p)remember(self,key,p and call(p,"objectName")or nil)end
local function consume_target(self,actor,key)
 -- Source writes an AI-only temporary tag. Keep own writes in viewer memory;
 -- never read another AI's cache. Observed foreign target evidence may be
 -- provided separately by the public event adapter.
 local name=call(actor,"objectName");local value=recall_player(self,key..":"..name)
 remember(self,key..":"..name,nil)
 if value then return value end
 if name~=call(self.player,"objectName")then
  self:useKnowledgeEstimate({status="estimate",value=false,viewer=call(self.player,"objectName"),observer=name,
   basis="other_ai_temporary_target_unobserved_no_intention_prior"},"yczh2017."..key)
 end
end
local function target_written(self,key,p)remember_target(self,key..":"..call(self.player,"objectName"),p)end
local function source_variant()return{setValue=function(self,v)self.value=v end}end
local function has_hand_equip(self,p)
 local own=call(p,"objectName")==call(self.player,"objectName")
 local cards=known(own and call(p,"getHandcards")or p:getKnownCards(),"known Qingxian hand")
 for _,card in ipairs(cards)do if call(card,"isKindOf","EquipCard")then return true end end
 local hidden=call(p,"getHandcardNum")-#cards
 if hidden<0 then ai_unsupported("known hand exceeds public count","qingxian.hand")end
 if hidden==0 then return false end
 -- The configured deck definition's kind counts are not projected.
 ai_unsupported("public equipment distribution is not projected","qingxian.hand")
end
local function fumian_card(self,name)
 return known(self:evaluateSkillCard("fumian",name,{}),"fumian_distance readonly clone")
end
local function can_use_group(self,card,players)
 if #players==0 then return call(self.player,"canUse",card)end
 for _,p in ipairs(players)do if call(self.player,"canUse",card,p)then return true end end
 return false
end
local function fumian_use(self)
 local value=context(self,"fumian_use")
 if type(value)~="table"then ai_unsupported("public Fumian use unavailable","fumian_use")end
 local targets=AIList.new({});for _,name in ipairs(value.to or{})do targets:append(known(self.room:findPlayerByObjectName(name),"Fumian use target"))end
 return{card=known(CardView.new(value.card),"Fumian used card"),to=targets}
end
local function plan_store(self)
 local rows={};for _,row in ipairs(self.fumian_extra or{})do local values={};for i,v in ipairs(row)do values[i]=type(v)=="string"and v or call(v,"objectName")end;rows[#rows+1]=values end;remember(self,"fumian_extra",rows)
end
local function plan_restore(self)
 local rows=known(recall(self,"fumian_extra"),"source Fumian prior choice plan")
 self.fumian_extra={};for _,row in ipairs(rows)do local values={};for i,v in ipairs(row)do values[i]=i==#row and v or known(self.room:findPlayerByObjectName(v),"Fumian planned player")end;self.fumian_extra[#self.fumian_extra+1]=values end
end
local function source_fumian_allowed(self,p)
 local offered=self._fumian_offered
 if offered then return offered[call(p,"objectName")]==true end
 return call(p,"hasFlag","fumian_canchoose")
end
local function huimin_count(self)return known(context(self,"huimin").count,"Huimin native count")end
local function huimin_target(self,p)
 local names=known(context(self,"huimin").recipients,"Huimin native recipients")
 for _,name in ipairs(names)do if call(p,"objectName")==name then return true end end;return false
end

local function getNextJudgeReason(self,player)
	if self:playerGetRound(player)>2 then
		if call(player,"hasSkills","ganglie|vsganglie") then return end
		local caiwenji = self.room:findPlayerBySkillName("beige")
		if caiwenji and call(caiwenji,"canDiscard",caiwenji,"he") and self:isFriend(caiwenji,player) then return end
		if call(player,"hasArmorEffect","EightDiagram") or call(player,"hasSkill","bazhen") then
			if self:playerGetRound(player)>3 and self:isEnemy(player) then return "EightDiagram"
			else return end
		end
	end
	if self:isFriend(player) and call(player,"hasSkill","luoshen") then return "luoshen" end
	if not call(player,"getJudgingArea"):isEmpty() and not call(player,"containsTrick","YanxiaoCard") then
		return call(player,"getJudgingArea"):last():objectName()
	end
	if call(player,"hasSkill","qianxi") then return "qianxi" end
	if call(player,"hasSkill","nosmiji") and call(player,"getLostHp")>0 then return "nosmiji" end
	if call(player,"hasSkill","tuntian") then return "tuntian" end
	if call(player,"hasSkill","tieji") then return "tieji" end
	if call(player,"hasSkill","nosqianxi") then return "nosqianxi" end
	if call(player,"hasSkill","caizhaoji_hujia") then return "caizhaoji_hujia" end
end

local function funan_card(self)
 local value=fact(self,"funan_card");if value==false then return nil end
 return known(CardView.new(value),"Funan public response")
end
-- The AG discloses each offered card's face to the viewer.
local function shouxi_printed(self,id)
 return known(self:getChoiceCard(id),"offered Shouxi card")
end
-- from:canDiscard(from,"h"). Another player's answer depends on its hidden hand:
-- none is false, otherwise the hand is estimated discardable.
local function shouxi_hand_discardable(self,from)
 if call(from,"objectName")==call(self.player,"objectName")then return call(from,"canDiscard",from,"h")end
 if call(from,"getHandcardNum")==0 then return false end
 return self:useKnowledgeEstimate({status="estimate",value=true,viewer=call(self.player,"objectName"),observer=call(from,"objectName"),
  basis="foreign_hand_discard_limits_on_hidden_cards_assumed_absent"},"yczh2017.shouxi_from_discard")
end

local function source_dummy()local u=AIUsePlan.new();u.isDummy=true;u.extra_target=0;u.current_targets={};return u end

--谏征
sgs.ai_skill_cardask["jianzheng-put"] = function(self,data)
	local use = data:toCardUse()
	local slash = use.card
	local from = use.from
	if from and self:isFriend(from) then return "." end
	local willSave = false
	local friend
	for _,to in sgs.qlist(use.to)do
        if self:isFriend(to) and self:slashIsEffective(slash,to,from) and self:isWeak(to) then
            friend = to
			willSave = true
			break
        end
    end
	if not willSave then return "." end
	local cards = sgs.QList2Table(call(self.player,"getCards","h"))
	if #cards<2 then return "." end
	sort_keep(self,cards)
	if call(slash,"isBlack") or not self:isWeak() or not self:slashIsEffective(slash,self.player,from) or self:getOverflow()>0 then
		for _,card in ipairs(cards)do
			if not call(card,"isKindOf","Peach") then
				sgs.updateIntention(self.player,friend,-10)
				return "$"..call(card,"getEffectiveId")
			end
		end
	end
	return "."
end

--专对
sgs.ai_skill_invoke.zhuandui=function(self,data)
	local target = data:toPlayer()
	if target then
		return not self:isFriend(target)
	end
	return true
end

function sgs.ai_slash_prohibit.zhuandui(self,from,to)
	if call(from,"getHandcardNum")<=1 or call(to,"isKongcheng") then return false end
	if not call(to,"hasSkill","tianbian") then return false end
	if call(from,"hasSkills","tieji|qianjie") or self:needKongcheng(from) then return false end
	if self:isEnemy(to,from) and self:hasEightDiagramEffect(to) and not IgnoreArmor(from,to) and #self:getEnemies(from)>1 then return true end
	if call(from,"getHandcardNum")<=2 and call(from,"isWounded") and not self:isFriend(to,from) and self:getCardsNum("Peach")>0 then return true end
	return false
end

--天辩
sgs.ai_skill_invoke.tianbian = function(self,data)
	local handcards = call(self.player,"getCards","h")
	for _,c in sgs.qlist(handcards)do
		if call(c,"getSuit")==sgs.Card_Heart and not call(c,"isKindOf","Peach") and self:getOverflow()>0 then
			return false
		end
	end
	return true
end

sgs.ai_cardneed.tianbian = function(to,card)
	return call(to,"getHandcardNum")<2 or call(card,"getSuit")==sgs.Card_Heart
end

--福绵
sgs.ai_skill_invoke.fumian = function(self,data)
	return true
end

local function fumianJudgeFriend(self,name,friends)
	local card = fumian_card(self,name)
	if not card then return false end
	-- Flag belongs to the readonly native Fumian evaluation scope.
	if not can_use_group(self,card,friends) then return false end
	local extra_targets_and_name = {}
	for _,c in sgs.qlist(call(self.player,"getHandcards"))do
		if isCard(call(card,"getClassName"),c,self.player) and call(c,"isRed") then
			for _,p in sgs.qlist(friends)do
				local sp = AIList.new({})
				sp:append(p)
				if can_use_group(self,card,sp) then
					if call(card,"targetFixed") and call(self.player,"isProhibited",p,card) then continue end
					if call(card,"isKindOf","TrickCard") then
						if self:hasTrickEffective(card,p,self.player) then
							table.insert(extra_targets_and_name,p)
						end
					else
						if call(card,"isKindOf","Peach") and call(p,"getLostHp")>0 then
							table.insert(extra_targets_and_name,p)
						else
							table.insert(extra_targets_and_name,p)
						end
					end
				end
			end
			if #extra_targets_and_name>0 then
				table.insert(extra_targets_and_name,name)
				table.insert(self.fumian_extra,extra_targets_and_name)
				return true
			end
		end
	end
	return false
end

local function fumianJudgeEnemy(self,name,enemies)
	local card = fumian_card(self,name)
	if not card then return false end
	-- Flag belongs to the readonly native Fumian evaluation scope.
	if not can_use_group(self,card,enemies) then return false end
	local extra_targets_and_name = {}
	for _,c in sgs.qlist(call(self.player,"getHandcards"))do
		if isCard(call(card,"getClassName"),c,self.player) and call(c,"isRed") then
			for _,p in sgs.qlist(enemies)do
				local sp = AIList.new({})
				sp:append(p)
				if can_use_group(self,card,sp) then
					if call(card,"targetFixed") and call(self.player,"isProhibited",p,card) then continue end
					if call(card,"isKindOf","TrickCard") then
						if self:hasTrickEffective(card,p,self.player) then  --过河拆桥和顺手牵羊的处理待补充
							table.insert(extra_targets_and_name,p)
						end
					else
						if call(card,"isKindOf","Slash") and self:slashIsEffective(card,p,self.player) then
							table.insert(extra_targets_and_name,p)
						else
							table.insert(extra_targets_and_name,p)
						end
					end
				end
			end
			if #extra_targets_and_name>1 then
				table.insert(extra_targets_and_name,name)
				table.insert(self.fumian_extra,extra_targets_and_name)
				return true
			end
		end
	end
	return false
end

local function fumianCanGetFriends(self,friends)
	local ex_nihilo = fumianJudgeFriend(self,"ex_nihilo",friends)
	local peach = fumianJudgeFriend(self,"peach",friends)
	--顺、拆、铁索等待补充，杀队友以此杀远距离敌人待补充
	return ex_nihilo or peach
end

local function fumianCanGetEnemies(self,enemies)
	local slash = fumianJudgeEnemy(self,"slash",enemies)
	local fire_slash = fumianJudgeEnemy(self,"fire_slash",enemies)
	local thunder_slash = fumianJudgeEnemy(self,"thunder_slash",enemies)
	local duel = fumianJudgeEnemy(self,"duel",enemies)
	local snatch = fumianJudgeEnemy(self,"snatch",enemies)
	local dismantlement = fumianJudgeEnemy(self,"dismantlement",enemies)
	local iron_chain = fumianJudgeEnemy(self,"iron_chain",enemies)
	local fire_attack = fumianJudgeEnemy(self,"fire_attack",enemies)
	return slash or fire_slash or thunder_slash or duel or snatch or dismantlement or iron_chain or fire_attack
end

sgs.ai_skill_choice.fumian = function(self,choices,data)
	if call(self.player,"containsTrick","indulgence") then
		return "draw"
	end
	self.fumian_extra = {}
	local friends = AIList.new({})
	for _,p in ipairs(self.friends_noself)do
		friends:append(p)
	end
	local enemies = AIList.new({})
	for _,p in ipairs(self.enemies)do
		enemies:append(p)
	end

	if call(self.player,"containsTrick","supply_shortage") or self:getOverflow()>1 then
		if fumianCanGetFriends(self,friends) or fumianCanGetEnemies(self,enemies) then
			return "target"
		end
	end

	if not friends:isEmpty() and fumianCanGetFriends(self,friends) then return "target" end
	if not enemies:isEmpty() and fumianCanGetEnemies(self,enemies) then return "target" end
	return "draw"
end

sgs.ai_skill_use["@@fumian"] = function(self,prompt,method)
	local length = string.find(prompt,":")
	local card_name = string.sub(prompt,length+1 ,string.len(prompt))
	local maxnum = (self._fumian_max or call(self.player,"getMark","fumian_extra_target-Clear"))
	local use = fumian_use(self)

	if card_name=="collateral" then  --【借刀杀人】这部分没有测试
		local dummy_use = source_dummy()
		for _,p in sgs.qlist(use.to)do
			table.insert(dummy_use.current_targets,call(p,"objectName"))
		end
		self:useCardCollateral(use.card,dummy_use)
		if dummy_use.card and dummy_use.to:length()==2 then
			local first = dummy_use.to:at(0):objectName()
			local second = dummy_use.to:at(1):objectName()
			return "@ExtraCollateralCard=.->"..first.."+"..second
		end
	end

	local extra_table = {}
	for _,t in ipairs(self.fumian_extra)do

		if t[#t]==card_name then
			--extra_table = t
			for i=1,#t-1 do  --为了不把card_name一起存进去
				if not source_fumian_allowed(self,t[i]) then continue end
				table.insert(extra_table,t[i])
			end
			break
		end
	end
	if #extra_table==0 then return "." end
	--table.removeOne(extra_table,card_name)  --无法remove掉
	--if #extra_table==0 then return "." end

	local extra_players = {}
	if self:isFriend(extra_table[1]) then
		if card_name=="peach" then
			sort_players(self,extra_table,"hp")
		elseif card_name=="ex_nihilo" then
			sort_players(self,extra_table,"handcard")
		else
			sort_players(self,extra_table,"defense")
		end
		for i=1,math.min(maxnum,#extra_table)do
			table.insert(extra_players,call(extra_table[i],"objectName"))
		end
		if #extra_players>0 then
			return "@FumianCard=.->"..table.concat(extra_players,"+")
		end
	end
	if self:isEnemy(extra_table[1]) then
		sort_players(self,extra_table,"defense")
		for i=1,math.min(maxnum,#extra_table)do
			table.insert(extra_players,call(extra_table[i],"objectName"))
		end
		if #extra_players>0 then
			return "@FumianCard=.->"..table.concat(extra_players,"+")
		end
	end
	return "."
end

--怠宴
sgs.ai_skill_playerchosen.daiyan = function(self,targets)
	sort_players(self,self.friends_noself,"defense")
	for _,friend in ipairs(self.friends_noself)do
		if hasManjuanEffect(friend) then continue end
		if self:needKongcheng(friend,true) then continue end
		if call(friend,"getMark","&daiyan+#"..call(self.player,"objectName"))==0 or self:hasZhaxiangEffect(friend) or self:needToLoseHp(friend,self.player,nil,true) then
			return friend
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if hasManjuanEffect(enemy) then return enemy end
	end
	return nil
end

sgs.ai_playerchosen_intention.daiyan = function(self,from,to)
	if self:needKongcheng(to,true) then return end
	if hasManjuanEffect(to) then return end
	if call(to,"getMark","&daiyan+#"..call(self.player,"objectName"))>0 then return end
	sgs.updateIntention(from,to,-10)
end

--忠鉴
local zhongjian_skill = {}
zhongjian_skill.name = "zhongjian"
register_fill(zhongjian_skill)
zhongjian_skill.getTurnUseCard = function(self,inclusive)
	return authored(self,"@ZhongjianCard=.")
end

sgs.ai_skill_use_func.ZhongjianCard = function(card,use,self)
	if call(self.player,"isKongcheng") then return end
	local handcards = sgs.QList2Table(call(self.player,"getCards","h"))
	sort_use(self,handcards,true)
	self.zhongjian_target = nil
	local n = 0
	for _,p in sgs.qlist(call(self.room,"getOtherPlayers",self.player))do
		if call(p,"getHandcardNum")-call(p,"getHp")>n then
			n = call(p,"getHandcardNum")-call(p,"getHp")
			self.zhongjian_target = p
		end
	end
	if not self.zhongjian_target then return end
	use.card = authored(self,"@ZhongjianCard="..call(handcards[1],"getEffectiveId"))
	use.to:append(self.zhongjian_target)
end

sgs.ai_skill_choice.zhongjian = function(self,choices,data)
	if not self.zhongjian_target then return "draw" end
	if self:isEnemy(self.zhongjian_target) and self:doDisCard(self.zhongjian_target,"he") then return "discard" end
	if self:isFriend(self.zhongjian_target) and self:needToThrowCard(self.zhongjian_target,"e") then return "discard" end
	return "draw"
end

sgs.ai_use_priority.ZhongjianCard = 7
sgs.ai_use_value.ZhongjianCard = 7

--才识
sgs.ai_skill_invoke.caishi=function(self,data)
	self.caishi_choice = nil
	if call(self.player,"isWounded") and (self:getCardsNum("Peach")==0 or call(self.player,"isSkipped",sgs.Player_Play)) then
		self.caishi_choice = "recover"
	elseif #self.enemies<1 or call(self.player,"isSkipped",sgs.Player_Play) then
		self.caishi_choice = "max"
	else
		local cards = sgs.QList2Table(call(self.player,"getHandcards"))
		sort_keep(self,cards)
		for _,card in ipairs(cards)do
			if call(card,"isKindOf","Slash") then
				if self:willUse(self.player,card,false,false,true) then
					return false
				end
			elseif call(card,"isKindOf","TrickCard") and not call(card,"isKindOf","ExNihilo") and not call(card,"isKindOf","Nullification") then
				if self:willUse(self.player,card,false,false,true) then
					return false
				end
			end
		end
		self.caishi_choice = "max"
	end
	return self.caishi_choice~=nil
end

sgs.ai_skill_choice.caishi=function(self,choices,data)
	if not self.caishi_choice then return "max" end
	return self.caishi_choice
end

--十周年忠鉴

--十周年才识

--OL忠鉴
local olzhongjian_skill = {}
olzhongjian_skill.name = "olzhongjian"
register_fill(olzhongjian_skill)
olzhongjian_skill.getTurnUseCard = function(self,inclusive)
	return authored(self,"@OLZhongjianCard=.")
end

sgs.ai_skill_use_func.OLZhongjianCard = function(card,use,self)
	if call(self.player,"isKongcheng") then return end
	local handcards = sgs.QList2Table(call(self.player,"getCards","h"))
	sort_use(self,handcards,true)
	local others = sgs.QList2Table(call(self.room,"getOtherPlayers",self.player))
	local targets = {}
	for _,p in ipairs(others)do
		if call(p,"isKongcheng") then continue end
		table.insert(targets,p)
	end
	if #targets==0 then return end
	sort_players(self,targets,"handcard")
	use.card = authored(self,"@OLZhongjianCard="..call(handcards[1],"getEffectiveId"))
	use.to:append(targets[#targets])
end

sgs.ai_skill_playerchosen.olzhongjian = function(self,targets)
	local target = self:findPlayerToDiscard("he",false,true,targets)[1]
	if target then return target end
	return nil
end

sgs.ai_use_priority.OLZhongjianCard = sgs.ai_use_priority.ZhongjianCard
sgs.ai_use_value.OLZhongjianCard = sgs.ai_use_value.ZhongjianCard

--OL才识
sgs.ai_skill_invoke.olcaishi=true

sgs.ai_skill_choice.olcaishi=function(self,choices,data)
	if call(self.player,"isWounded") and (self:getCardsNum("Peach")==0 or call(self.player,"isSkipped",sgs.Player_Play)) then
		return "recover"
	end
	return "max"
end

--清弦
function SmartAIView:qingxianLose(to,from)
	from = from or self.player
	if self:isFriend(to,from) then
		if self:hasZhaxiangEffect(to) and not(hasManjuanEffect(to) or self:willSkipPlayPhase(to))
		and (call(to,"getHp")>1 or self:getAllPeachNum()>0)
		or self:needToLoseHp(to,self.player,nil,false,true)
		then return true end
	else
		if self:hasZhaxiangEffect(to)
		or self:needToLoseHp(to,self.player,nil,false,true)
		then return false end
	end
	return not self:isFriend(to,from)
end

function SmartAIView:qingxianRecover(to,from)
	from = from or self.player
	if call(to,"getLostHp")<1 then return false end
	if self:isFriend(to,from) then
		if self:needToThrowCard(to,"e") then return true end
		if self:needToLoseHp(to,self.player,nil,false,true) then return false end
		local can = has_hand_equip(self,to)
		if not can and call(to,"hasTreasure","wooden_ox") and not (call(to,"getPileCount","wooden_ox")==0) and call(to,"getCards","e"):length()==1 then return false end
		if self:isWeak(to) then return true end
		if not can and call(to,"getCards","e"):length()>0 and not to:getWeapon() and not to:getOffensiveHorse() and not (call(to,"hasTreasure","wooden_ox") and (call(to,"getPileCount","wooden_ox")==0)) then
			return false
		end
		return true
	else
		if self:needToThrowCard(to,"e") then return false end
		if self:isWeak(to) then return false end
		if self:needToLoseHp(to,self.player,nil,true,true) and call(to,"getCards","e"):length()>0 then return true end
		local can = has_hand_equip(self,to)
		if not can and call(to,"hasTreasure","wooden_ox") and not (call(to,"getPileCount","wooden_ox")==0) and call(to,"getCards","e"):length()==1 then return true end
		return false
	end
	return self:isFriend(to,from)
end

sgs.ai_skill_invoke.qingxian = function(self,data)
	local from = data:toPlayer()
	if not from then return false end
	self.qingxian_choice = nil
	if self:isFriend(from) then
		if call(from,"getLostHp")>0 and self:qingxianRecover(from) then
			self.qingxian_choice = "recover"
		elseif self:qingxianLose(from) then
			self.qingxian_choice = "losehp"
		end
	else
		if self:qingxianLose(from) then
			self.qingxian_choice = "losehp"
		elseif call(from,"getLostHp")>0 and self:qingxianRecover(from) then
			self.qingxian_choice = "recover"
		end
	end
	if self.qingxian_choice then
		local new_data = source_variant()
		new_data:setValue(from)
		target_written(self,"qingxian_target",new_data.value)
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.qingxian = function(self,targets)
	local tos = sort_players(self,targets,"defense")
	self.qingxian_choice = nil
	local new_data = source_variant()

	for _,to in ipairs(tos)do
		if self:isFriend(to) and self:qingxianRecover(to) then
			self.qingxian_choice = "recover"
			new_data:setValue(to)
			target_written(self,"qingxian_target",new_data.value)
			return to
		elseif self:isEnemy(to) and self:qingxianLose(to) then
			new_data:setValue(to)
			target_written(self,"qingxian_target",new_data.value)
			self.qingxian_choice = "losehp"
			return to
		end
	end
	tos = sgs.reverse(tos)
	for _,to in ipairs(tos)do
		if self:isFriend(to) and self:qingxianLose(to) then
			new_data:setValue(to)
			target_written(self,"qingxian_target",new_data.value)
			self.qingxian_choice = "losehp"
			return to
		elseif not self:isFriend(to) and (self:qingxianLose(to) or self:qingxianRecover(to)) then
			new_data:setValue(to)
			target_written(self,"qingxian_target",new_data.value)
			self.qingxian_choice = "recover"
			return to
		end
	end
	return "."
end

sgs.ai_skill_choice.qingxian = function(self,choices)
	if not self.qingxian_choice then return choices[1] end
	return self.qingxian_choice
end

sgs.ai_skill_discard.qingxian = function(self,discard_num,min_num,optional,include_equip)
	local card_id = self:disEquip()
	if card_id then return {card_id} end

	for _,card in sgs.qlist(call(self.player,"getCards","he"))do
		if call(card,"isKindOf","EquipCard") then
			return {call(card,"getEffectiveId")}
		end
	end
	return "."
end

function sgs.ai_slash_prohibit.qingxian(self,from,to,card)
	if self:ajustDamage(to,from,1,card)>1
	or self:hasZhaxiangEffect(from)
	or not(self:isFriend(to,from) or self:qingxianLose(to,from))
	or call(from,"getHp")>2
	or call(from,"hasSkills",sgs.need_equip_skill) and call(from,"getHp")>1
	or call(to,"getHp")<2
	then return false end
	return not self:isFriend(to,from) and self:isWeak(from)
end

sgs.ai_choicemade_filter.skillChoice.qingxian = function(self,player,promptlist)
	local to = consume_target(self,player,"qingxian_target")

	if not to then return end
	local choice = promptlist[#promptlist]
	if choice=="losehp" then
		if self:hasZhaxiangEffect(to) or self:needToLoseHp(to,player) or (call(to,"hasSkills",sgs.need_equip_skill) and not self:isWeak(to)) then return end
		sgs.updateIntention(player,to,10)
	end
	if choice=="recover" then
		if self:needToLoseHp(to,player,nil,false,true) then return end
		if call(to,"hasTreasure","wooden_ox") and call(to,"getPileCount","wooden_ox")>0 and call(to,"getCards","e"):length()==1 then return end
		sgs.updateIntention(player,to,-10)
	end
end

--绝响
sgs.ai_skill_playerchosen.juexiang = function(self,targets)
	targets = sgs.QList2Table(targets)
	sort_players(self,targets,"defense")
	for _,to in ipairs(targets)do
		if self:isFriend(to) then return to end
	end
	return "."
end

--激弦
sgs.ai_skill_invoke.jixian = function(self,data)
	local from = data:toPlayer()
	if not from then return false end
	return self:qingxianLose(from)
end

--烈弦
sgs.ai_skill_playerchosen.liexian = function(self,targets)
	targets = sgs.QList2Table(targets)
	sort_players(self,targets,"defense")

	for _,to in ipairs(targets)do
		if self:isEnemy(to) and self:qingxianLose(to) then return to end
	end
	targets = sgs.reverse(targets)
	for _,to in ipairs(targets)do
		if self:isFriend(to) and self:qingxianLose(to) then return to end
	end
	return "."
end

--柔弦
sgs.ai_skill_invoke.rouxian = function(self,data)
	local to = data:toPlayer()
	return self:qingxianRecover(to)
end

--和弦
sgs.ai_skill_playerchosen.hexian = function(self,targets)
	targets = sgs.QList2Table(targets)
	sort_players(self,targets,"defense")

	for _,to in ipairs(targets)do
		if self:isFriend(to) and self:qingxianRecover(to) then return to end
	end
	targets = sgs.reverse(targets)
	for _,to in ipairs(targets)do
		if not self:isFriend(to) and self:qingxianRecover(to) then return to end
	end
	return "."
end

--手杀清弦
local mobileqingxian_skill = {}
mobileqingxian_skill.name = "mobileqingxian"
register_fill(mobileqingxian_skill)
mobileqingxian_skill.getTurnUseCard = function(self,inclusive)
	return authored(self,"@MobileQingxianCard=.")
end

sgs.ai_skill_use_func.MobileQingxianCard = function(card,use,self)
	local cards = sgs.QList2Table(call(self.player,"getCards","he"))
	local useable_cards = {}
	sort_keep(self,cards)
	local use_silver_lion = 0
	if self.player:getArmor() and self:needToThrowArmor() then
		table.insert(useable_cards,self.player:getArmor():getEffectiveId())
		use_silver_lion = 1
	end
	for _,c in ipairs(cards)do
		if not call(c,"isKindOf","Peach") and #useable_cards<math.min(call(self.player,"getHp"),self:getOverflow()>0 and self:getOverflow() or 1) then
			table.insert(useable_cards,call(c,"getEffectiveId"))
		end
	end
	if #useable_cards==0 then return end
	sort_players(self,self.friends_noself,"hp")
	sort_players(self,self.enemies,"hp")
	local targets = {}
	for _,enemy in ipairs(self.enemies)do
		if call(enemy,"getEquips"):length()>call(self.player,"getEquips"):length()-use_silver_lion and #targets<#useable_cards and not self:needToLoseHp(enemy,self.player,nil,true) and not self:hasZhaxiangEffect(enemy) then
			table.insert(targets,enemy)
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if call(friend,"getEquips"):length()<call(self.player,"getEquips"):length()-use_silver_lion and call(friend,"isWounded") and #targets<#useable_cards and not self:needToLoseHp(friend,self.player,nil,true,true) then
			table.insert(targets,friend)
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if call(friend,"getEquips"):length()==call(self.player,"getEquips"):length()-use_silver_lion and #targets<#useable_cards and self:canDraw(friend) then
			table.insert(targets,friend)
		end
	end

	if #targets==0 then return end
	local discard = {}
	local n = #targets
	for _,id in ipairs(useable_cards)do
		table.insert(discard,id)
		n = n-1
		if n<1 then break end
	end

	use.card = authored(self,"@MobileQingxianCard="..table.concat(discard,"+"))
	for i=1,#targets,1 do
		use.to:append(targets[i])
	end
end

sgs.ai_use_priority.MobileQingxianCard = 3
sgs.ai_use_value.MobileQingxianCard = 3

sgs.ai_card_intention.MobileQingxianCard = function(self,card,from,tos)
	for _,to in ipairs(tos)do
		if call(to,"getEquips"):length()<call(from,"getEquips"):length() then
			if not call(to,"isWounded") or self:needToLoseHp(to,from,nil,true,true) then return end
			sgs.updateIntention(from,to,-10)
		elseif call(to,"getEquips"):length()==call(from,"getEquips"):length() then
			if not self:canDraw(to,from) then return end
			sgs.updateIntention(from,to,-10)
		else
			if self:needToLoseHp(to,from,nil,true) or self:hasZhaxiangEffect(to) then return end
			sgs.updateIntention(from,to,10)
		end
	end
end

--手杀绝响
sgs.ai_skill_playerchosen.mobilejuexiang = function(self,targets)
	local targets = sgs.QList2Table(targets)
	sort_players(self,targets,"defense")
	for _,p in ipairs(targets)do
		if self:isFriend(p) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_playerchosen.mobilejuexiang_discard = function(self,targets)
	local target = self:findPlayerToDiscard("ej",true,true,targets)[1]
	if target then return target end

	local targets = sgs.QList2Table(targets)
	sort_players(self,targets,"defense")
	for _,p in ipairs(targets)do
		if not self:isFriend(p) and self:doDisCard(p,"ej") then
			return p
		end
	end
	return nil
end

function sgs.ai_slash_prohibit.mobilejuexiang(self,from,to)
	if self:justDamage(to,from,true) then return false end
	if call(to,"isLord") then return false end
	if call(to,"getHp")>1 or #self:getEnemies(from)==1 then return false end
	if self:needToThrowCard(to,"e") then return false end
	if getCardsNum("Peach",to,from)+getCardsNum("Analeptic",to,from)>0 then return false end
	return self:isWeak(from) and call(from,"getHp")<2
end

--残韵
local mobilecanyun_skill = {}
mobilecanyun_skill.name = "mobilecanyun"
register_fill(mobilecanyun_skill)
mobilecanyun_skill.getTurnUseCard = function(self,inclusive)
	return authored(self,"@MobileCanyunCard=.")
end

sgs.ai_skill_use_func.MobileCanyunCard = function(card,use,self)
	local cards = sgs.QList2Table(call(self.player,"getCards","he"))
	local useable_cards = {}
	sort_keep(self,cards)
	local use_silver_lion = 0
	if self.player:getArmor() and self:needToThrowArmor() then
		table.insert(useable_cards,self.player:getArmor():getEffectiveId())
		use_silver_lion = 1
	end
	for _,c in ipairs(cards)do
		if not call(c,"isKindOf","Peach") and #useable_cards<math.min(call(self.player,"getHp"),self:getOverflow()>0 and self:getOverflow() or 1) then
			table.insert(useable_cards,call(c,"getEffectiveId"))
		end
	end
	if #useable_cards==0 then return end
	sort_players(self,self.friends_noself,"hp")
	sort_players(self,self.enemies,"hp")
	local targets = {}
	for _,enemy in ipairs(self.enemies)do
		if call(enemy,"getMark","mobilecanyun_used"..call(self.player,"objectName"))>0 then continue end
		if call(enemy,"getEquips"):length()>call(self.player,"getEquips"):length()-use_silver_lion and #targets<#useable_cards and not self:needToLoseHp(enemy,self.player,nil,true) and not self:hasZhaxiangEffect(enemy) then
			table.insert(targets,enemy)
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if call(friend,"getMark","mobilecanyun_used"..call(self.player,"objectName"))>0 then continue end
		if call(friend,"getEquips"):length()<call(self.player,"getEquips"):length()-use_silver_lion and call(friend,"isWounded") and #targets<#useable_cards and not self:needToLoseHp(friend,self.player,nil,true,true) then
			table.insert(targets,friend)
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if call(friend,"getMark","mobilecanyun_used"..call(self.player,"objectName"))>0 then continue end
		if call(friend,"getEquips"):length()==call(self.player,"getEquips"):length()-use_silver_lion and #targets<#useable_cards and self:canDraw(friend) then
			table.insert(targets,friend)
		end
	end

	if #targets==0 then return end
	local discard = {}
	local n = #targets
	for _,id in ipairs(useable_cards)do
		table.insert(discard,id)
		n = n-1
		if n<1 then break end
	end

	use.card = authored(self,"@MobileCanyunCard="..table.concat(discard,"+"))
	for i=1,#targets,1 do
		use.to:append(targets[i])
	end
end

sgs.ai_use_priority.MobileCanyunCard = 3
sgs.ai_use_value.MobileCanyunCard = 3

sgs.ai_card_intention.MobileCanyunCard = function(self,card,from,tos)
	for _,to in ipairs(tos)do
		if call(to,"getEquips"):length()<call(from,"getEquips"):length() then
			if not call(to,"isWounded") or self:needToLoseHp(to,from,nil,true,true) then return end
			sgs.updateIntention(from,to,-10)
		elseif call(to,"getEquips"):length()==call(from,"getEquips"):length() then
			if not self:canDraw(to,from) then return end
			sgs.updateIntention(from,to,-10)
		else
			if self:needToLoseHp(to,from,nil,true) or self:hasZhaxiangEffect(to) then return end
			sgs.updateIntention(from,to,10)
		end
	end
end

--问卦
local wengua_skill = {}
wengua_skill.name = "wengua"
register_fill(wengua_skill)
wengua_skill.getTurnUseCard = function(self,inclusive)
	if call(self.player,"isNude") then return end
	return authored(self,"@WenguaCard=.")
end

sgs.ai_skill_use_func.WenguaCard = function(card,use,self)
	local cards = sgs.QList2Table(call(self.player,"getCards","he"))
	local id = -1
	sort_use(self,cards,true)
	if self:needToThrowArmor() then
		id = self.player:getArmor():getEffectiveId()
	end

	local nextAlive = self.player
	repeat
		nextAlive = nextAlive:getNextAlive()
		if call(nextAlive,"objectName")==call(self.player,"objectName") then break end
	until call(nextAlive,"faceUp")

	if call(nextAlive,"objectName")~=call(self.player,"objectName") or not call(self.player,"getJudgingArea"):isEmpty() then
		local reason = getNextJudgeReason(self,nextAlive)
		for _,c in ipairs(cards)do
			if not self:keepCard(c,self.player,true) then
				if self:goodJudge(nextAlive,reason,c) then
					id = call(c,"getEffectiveId")
					break
				else
					if id<0 then id = call(c,"getEffectiveId") end
				end
			end
		end
	end

	if self:needToThrowCard() then self:setPriorityValue("WenguaCard",sgs.ai_use_priority.Slash+0.1,"wengua")
	elseif call(nextAlive,"getCards","j"):length()>0 then self:setPriorityValue("WenguaCard",0.1,"wengua")
	else self:setPriorityValue("WenguaCard",sgs.ai_use_priority.IronChain-0.1,"wengua")
	end

	if id<0 then return end
	use.card = authored(self,"@WenguaCard="..id)
end

local wenguagive_skill = {}
wenguagive_skill.name = "wenguagive"
register_fill(wenguagive_skill)
wenguagive_skill.getTurnUseCard = function(self,inclusive)
	if call(self.player,"isNude") then return end
	return authored(self,"@WenguagiveCard=.")
end

sgs.ai_skill_use_func.WenguagiveCard = function(card,use,self)
	local xushi=nil
	for _,p in ipairs(self.friends_noself)do
		if call(p,"getMark","wengua-PlayClear")<=0 and call(p,"hasSkill","wengua") and not self:needKongcheng(p,true) then
			xushi=p
			break
		end
	end
	if not xushi then return end

	local cards = sgs.QList2Table(call(self.player,"getCards","he"))
	local id = -1
	sort_use(self,cards,true)
	if self:needToThrowArmor() then
		id = self.player:getArmor():getEffectiveId()
	end

	local nextAlive = self.player
	repeat
		nextAlive = nextAlive:getNextAlive()
		if call(nextAlive,"objectName")==call(self.player,"objectName") then break end
	until call(nextAlive,"faceUp")

	if call(nextAlive,"objectName")~=call(self.player,"objectName") or not call(self.player,"getJudgingArea"):isEmpty() then
		local reason = getNextJudgeReason(self,nextAlive)
		for _,c in ipairs(cards)do
			if not self:keepCard(c,self.player,true) then
				if self:goodJudge(nextAlive,reason,c) then
					id = call(c,"getEffectiveId")
					break
				else
					if id<0 then id = call(c,"getEffectiveId") end
				end
			end
		end
	end

	if (role(self,self.player)~="neutral" and role(self,xushi)~="neutral") or call(self.player,"hasSkill","wengua") then
		if self:needToThrowCard() then self:setPriorityValue("WenguagiveCard",sgs.ai_use_priority.Slash+0.1,"wengua")
		elseif call(nextAlive,"getCards","j"):length()>0 then self:setPriorityValue("WenguagiveCard",0.1,"wengua")
		else self:setPriorityValue("WenguagiveCard",sgs.ai_use_priority.IronChain-0.1,"wengua")
		end
	else
		self:setPriorityValue("WenguagiveCard",0.1,"wengua")
	end
	if id<0 then return end
	use.card = authored(self,"@WenguagiveCard="..id)
	use.to:append(xushi)
end

sgs.ai_use_value.WenguaCard = 0.5
sgs.ai_use_value.WenguagiveCard = sgs.ai_use_value.WenguaCard

sgs.ai_skill_choice.wengua = function(self,choices,data)
	local name = context(self,"wengua").donor
	local id = context(self,"wengua").card_id
	local c = visible(self,id)
	local from = self.room:findPlayerByObjectName(name)
	choices = choices:split("+")
	if from then
		local data = source_variant()
		data:setValue(from)
		target_written(self,"wengua_target",data.value)

		local nextAlive = from
		repeat
			nextAlive = nextAlive:getNextAlive()
			if call(nextAlive,"objectName")==call(from,"objectName") then break end
		until call(nextAlive,"faceUp")

		if call(nextAlive,"objectName")~=name or not call(from,"getJudgingArea"):isEmpty() then
			local reason = getNextJudgeReason(self,nextAlive)
			if self:goodJudge(nextAlive,reason,c) then return "top" end
		end

		if self:isFriend(from) and call(from,"isAlive") and self:needKongcheng(from,true) and table.contains(choices,"cancel") then return "cancel" end

		if not self:isEnemy(from) then return "bottom" end
		if self:needKongcheng(from,true) then return "bottom" end
	end

	if table.contains(choices,"cancel") then return "cancel" end
	return "bottom"
end

sgs.ai_choicemade_filter.skillChoice.wengua = function(self,player,promptlist)
	local choice = promptlist[#promptlist]
	local to = consume_target(self,player,"wengua_target")

	if not to then return end
	if self:needKongcheng(to,true) or role(self,to)=="neutral" then return end
	if choice=="cancel" and not (call(player,"isAlive") and self:needKongcheng(player,true)) then
		sgs.updateIntention(player,to,80)
	end
end

--伏诛
sgs.ai_skill_invoke.fuzhu = function(self,data)
	local player = data:toPlayer()
	return self:isEnemy(player)
end

--复难
sgs.ai_skill_invoke.funan = function(self,data)
	if fact(self,"funan_level_up")
	then return not self:needKongcheng(self.player,true) end
	local to = data:toPlayer()
	if self:isFriend(to) then return not self:needKongcheng(to,true) and not self:needKongcheng(self.player,true) end
	if not self:isFriend(to) and not self:isEnemy(to) then return not self:needKongcheng(self.player,true) end
	if self:needKongcheng(to,true) then return true end
	local card = funan_card(self)
	if not card then return false end
	if call(card,"isKindOf","AOE")
	then
		if role(self,to)~="neutral" and self:canDraw(to)
		then sgs.updateIntention(self.player,to,10) end
		return false
	elseif call(card,"isNDTrick")
	then return true end
	if self:getOverflow()>0 or call(self.player,"getHandcardNum")>=call(to,"getHandcardNum")
	then
		if role(self,to)~="neutral" and self:canDraw(to)
		then sgs.updateIntention(self.player,to,10) end
		return false
	end
	return true
end


--诫训
sgs.ai_skill_playerchosen.jiexun = function(self,targets)
	local diamond_count = 0
	for _,p in sgs.qlist(call(self.room,"getAlivePlayers"))do
		for _,c in sgs.qlist(call(p,"getCards","ej"))do
			if call(c,"getSuit")==sgs.Card_Diamond then
				diamond_count = diamond_count+1
			end
		end
	end
	local use_time = call(self.player,"getMark","&jiexun-Keep")

	sort_players(self,self.enemies,"handcard")
	sort_players(self,self.friends_noself,"handcard")
	local second
	if use_time>diamond_count then
		local n = use_time-diamond_count
		for _,enemy in ipairs(self.enemies)do
			if hasManjuanEffect(enemy) and self:doDisCard(enemy,"he",false,use_time) then return enemy end
			if not second and not self:needToThrowCard(enemy,"he",true) and call(enemy,"getCardCount",true)>=n
			and not (call(enemy,"hasSkill","lirang") and self:findFriendsByType(sgs.Friend_Draw,enemy)) then
				second = enemy
			end
		end
	elseif use_time<diamond_count then
		for _,friend in ipairs(self.friends_noself)do
			if self:needToThrowCard(friend,"e") and not hasManjuanEffect(friend) then return friend end
			if not second and not hasManjuanEffect(friend) then second = friend end
		end
		if not second then self:noChoice(targets) end
	elseif use_time==diamond_count then
		self.friends_noself = sgs.reverse(self.friends_noself)
		for _,friend in ipairs(self.friends_noself)do
			if self:needToThrowCard(friend,"e") and not hasManjuanEffect(friend) then return friend end
			if not second and not hasManjuanEffect(friend) then second = friend end
		end
		if use_time==0 then
			for _,player in sgs.qlist(call(self.room,"getOtherPlayers",self.player))do
				return player
			end
		end
	end
	return second
end

--守玺
sgs.ai_skill_invoke.shouxi=function(self,data)
	local use = data:toCardUse()
	local player = use.from
	local slash = use.card
	if not self:slashIsEffective(slash,self.player,player) then return false end
	if self:getCardsNum("Jink")<1 then remember_target(self,"shouxi_from",use.from) return true end
	if not self:canHit(self.player,player) then return false end
	remember_target(self,"shouxi_from",use.from)
	return true
end

sgs.ai_skill_askforag.shouxi=function(self,card_ids)
	local cards,basic = {},{}
	for _,card_id in ipairs(card_ids)do
		local card = shouxi_printed(self,card_id)
		table.insert(cards,card)
		if call(card,"isKindOf","BasicCard") then
			table.insert(basic,card)
		end
	end
	local id = -1
	local from = recall_player(self,"shouxi_from")
	remember(self,"shouxi_from",nil)
	if (not from or call(from,"isDead") or not shouxi_hand_discardable(self,from)) and #basic>0 then
		sort_use(self,basic,true)
		id = call(basic[1],"getEffectiveId")
	else
		sort_use(self,cards,true)
		id = call(cards[1],"getEffectiveId")
	end
	if id>-1 then
		return id
	else
		return card_ids[1]
	end
end



--惠民
sgs.ai_skill_invoke.huimin = function(self,data)
	local friend_num = 0
	local enemy_num = 0
	for _,friend in ipairs(self.friends)do
		if call(friend,"getHandcardNum")<call(friend,"getHp") then
			friend_num = friend_num+1
			if self:needKongcheng(friend,true) then return false end
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if call(enemy,"getHandcardNum")<call(enemy,"getHp") then
			if self:needKongcheng(enemy,true) then friend_num = friend_num+1
			else enemy_num = enemy_num+1
			end
		end
	end
	return friend_num>0 and friend_num>=enemy_num
end

local function huiminValue(self,p,tos)
	local v = 0
	local suf,coeff = 0.9,0.9
	local next_player = p
	if self:isFriend(p) then v = 1
	elseif self:isEnemy(p) then v = -1
	end
	repeat
		next_player = next_player:getNextAlive()
		if call(next_player,"objectName")~=call(p,"objectName") and table.contains(tos,next_player) then
			if self:isFriend(next_player) then v = v+suf
			elseif self:isEnemy(next_player) then
				v = v-suf
			end
			suf = suf*coeff
		end
	until call(next_player,"objectName")==call(p,"objectName")
	return v
end

sgs.ai_skill_use["@@huimin!"] = function(self,prompt)
	local length = huimin_count(self)
	local hand,show = {},{}
	for _,c in sgs.qlist(call(self.player,"getCards","h"))do
		table.insert(hand,c)
	end
	length = math.min(#hand,length)
	sort_keep(self,hand)
	for i=1,length do
		table.insert(show,call(hand[i],"getEffectiveId"))
	end

	local targets = {}
	for _,p in sgs.qlist(call(self.room,"getAlivePlayers"))do
		if huimin_target(self,p) then
			table.insert(targets,p)
		end
	end
	if #targets==0 then return "." end
	if #targets==1 then
		return "@HuiminCard="..table.concat(show,"+").."->"..call(targets[1],"objectName")
	else
		local start = targets[1]
		local v = huiminValue(self,targets[1],targets)
		for _,p in ipairs(targets)do
			if huiminValue(self,p,targets)>v then
				v = huiminValue(self,p,targets)
				start = p
			end
		end
		return "@HuiminCard="..table.concat(show,"+").."->"..call(start,"objectName")
	end
	return "."
end

--辟撰
sgs.ai_skill_invoke.bizhuan = function(self,data)
	return true
end

--通博
sgs.ai_skill_use["@@tongbo"] = function(self,prompt,method)
	local pile = call(self.player,"getPile","book")
	local cards = call(self.player,"getCards","he")
	cards = sgs.QList2Table(cards)
	if pile:isEmpty() or #cards<1 then return "." end
	local piles = {}
	for _,id in sgs.qlist(pile)do
		table.insert(piles,visible(self,id))
	end
	local exchange = {}
	sort_need(self,cards)
	sort_need(self,piles)
	local max_num = math.max(pile:length(),#cards)
	for i=1,max_num do
		if #piles>0 and #cards>0
		and self:cardNeed(piles[#piles])>self:cardNeed(cards[1])
		then
			table.insert(exchange,call(piles[#piles],"getId"))
			table.insert(exchange,call(cards[1],"getId"))
			table.removeOne(piles,piles[#piles])
			table.removeOne(cards,cards[1])
		else break end
	end
	if #exchange<2 then return "." end
	return "@TongboCard="..table.concat(exchange,"+")
end

sgs.ai_skill_askforyiji.tongbo = function(self,card_ids)
	return known(sgs.ai_skill_askforyiji.miji,"Miji package dependency")(self,card_ids)
end

-- Persist the donor's own per-AI plans across isolated requests. These values
-- contain only scalar choices and public player names, never foreign AI tags.
local function with_cache(fn)
 return function(self,...)
  self.zhongjian_target=recall_player(self,"zhongjian_target")
  self.caishi_choice=recall(self,"caishi_choice")
  self.qingxian_choice=recall(self,"qingxian_choice")
  local result=table.pack(fn(self,...))
  remember_target(self,"zhongjian_target",self.zhongjian_target)
  remember(self,"caishi_choice",self.caishi_choice)
  remember(self,"qingxian_choice",self.qingxian_choice)
  return table.unpack(result,1,result.n)
 end
end
for _,name in ipairs{"caishi","qingxian"}do sgs.ai_skill_invoke[name]=with_cache(sgs.ai_skill_invoke[name])end
for _,name in ipairs{"zhongjian","caishi","qingxian"}do sgs.ai_skill_choice[name]=with_cache(sgs.ai_skill_choice[name])end
sgs.ai_skill_playerchosen.qingxian=with_cache(sgs.ai_skill_playerchosen.qingxian)
do local fn=sgs.ai_skill_use_func.ZhongjianCard
 sgs.ai_skill_use_func.ZhongjianCard=function(card,use,self)
  fn(card,use,self);remember_target(self,"zhongjian_target",self.zhongjian_target)
 end
end
do local fn=sgs.ai_skill_choice.fumian
 sgs.ai_skill_choice.fumian=function(self,...)
  local previous=recall(self,"fumian_extra")
  if previous then plan_restore(self)end
  local result=fn(self,...)
  if self.fumian_extra then plan_store(self)end
  return result
 end
end
local source_fumian=sgs.ai_skill_use["@@fumian"]
sgs.ai_skill_use["@@fumian"]=function(self,...)
 -- No current V2 request authorizes this historical skill-card response.
 ai_unsupported("historical Fumian response is not a current native prompt","@@fumian")
end
-- The V2 inquiry offers players directly. Apply the same stored source plan
-- to that offered set; no fictitious FumianCard receipt or flag is introduced.
sgs.ai_skill_playerschosen.fumian=function(self,targets,max_count,min_count)
 plan_restore(self)
 self._fumian_offered={};for _,p in ipairs(targets)do self._fumian_offered[call(p,"objectName")]=true end
 self._fumian_max=max_count
 local result=source_fumian(self,self.request.prompt,self.request.handling_method)
 self._fumian_max=nil;self._fumian_offered=nil
 if result=="."then return{}end
 local class,names=result:match("^@([%w_]+)=%.%->(.*)$")
 if not names then ai_unsupported("invalid source Fumian target proposal","fumian")end
 local out={};for name in names:gmatch("[^+]+")do out[#out+1]=known(self.room:findPlayerByObjectName(name),"Fumian selection")end
 if class=="ExtraCollateralCard"then
  if #out~=2 then ai_unsupported("invalid source Collateral pair","fumian")end
  remember(self,"fumian_collateral_victim",call(out[2],"objectName"))
  return{out[1]}
 end
 if #out>max_count then ai_unsupported("source Fumian exceeds native target count","fumian")end
 return out
end
for _,name in ipairs{"@@huimin!","@@tongbo"}do
 local fn=sgs.ai_skill_use[name]
 sgs.ai_skill_use[name]=function(self,...)
  local result=fn(self,...);if not result or result=="."then return{kind="pass"}end
  local text,names=result:match("^(.-)%->(.*)$");text=text or result
  local use=AIUsePlan.new();use.card=authored(self,text,true)
  for name in (names or""):gmatch("[^+]+")do use.to:append(known(self.room:findPlayerByObjectName(name),"response target"))end
  return use:toAnswer()
 end
end

sgs.ai_skill_playerchosen.fumian=function(self,targets)
 local victim=recall_player(self,"fumian_collateral_victim")
 remember(self,"fumian_collateral_victim",nil)
 if not victim then ai_unsupported("Fumian Collateral victim plan missing","fumian")end
 for _,p in ipairs(targets)do if call(p,"objectName")==call(victim,"objectName")then return p end end
 ai_unsupported("Fumian source victim is outside current native offer","fumian")
end
