-- Fixed Mountain effective callbacks; all costs require native authority.
local known = AIValue.requireKnown
local function skill(self,player,names)
    if type(names)=="table" then names=names:objectName() end
    local value=player:hasSkills(names)
    local row=type(player)=="table" and rawget(player,"_view")
    if value==true or value~=nil and (not row or row.skills_complete==true) then return value end
    if player:objectName()==self.player:objectName() then ai_unsupported("owner skill roster is incomplete","mountain.skills") end
    return self:useKnowledgeEstimate({status="estimate",value=false,basis="mountain.undisclosed_skill_uses_visible_roster",target=player:objectName()},"mountain.skills")
end
local dummy = AIUsePlan.dummy
local function reversed(cards)
    local result={};for i=#cards,1,-1 do result[#result+1]=cards[i] end;return AIList.new(result)
end
local function action(self,name,costs,targets,request)
    if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room) end
    local receipt=self:bindSkillCard(name,costs,request)
    local use=AIUsePlan.new();use.card=receipt;use.to=AIList.new(targets or {})
    return known(use:toAnswer(),"mountain.action")
end
ai_skill_invoke.tuntian = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if #self.enemies==1 and self.room:alivePlayerCount()==2 and self:hasSkills("noswuyan|qianxun",self.enemies[1]) then
		if (skill(self,self.player,"zaoxian") and self.player:getMark("zaoxian")==0) or (skill(self,self.player,"olzaoxian") and self.player:getMark("olzaoxian")==0) then
			return (false) or false
		end
	end
	return (true) or false
end

sgs.ai_slash_prohibit.tuntian = function(self,from,to,card)
	if self:isFriend(to) then return false end
	if not skill(self,to,"zaoxian") then return false end
	if skill(self,from,"tieji") or self:canLiegong(to,from) then
		return false
	end
	local enemies = self:getEnemies(to)
	if #enemies==1 and self.room:alivePlayerCount()==2 and self:hasSkills("noswuyan|qianxun|weimu",enemies[1]) then return false end
	if getCardsNum("Jink",to,from)<1 or self:isWeak(to) then return false end
	if to:getHandcardNum()>=3 and skill(self,to,"zaoxian") then return true end
	return false
end


sgs.ai_skill_cardask["@xiangle-discard"] = function(self,data)
	local target = data:toPlayer()
	if self:isFriend(target) and not self:findLeijiTarget(target,50,self.player) then return "." end
	local has_peach,has_analeptic,has_slash,has_jink
	for _,card in ipairs(self.player:getHandcards())do
		if card:isKindOf("Peach") then has_peach = card
		elseif card:isKindOf("Analeptic") then has_analeptic = card
		elseif card:isKindOf("Slash") then has_slash = card
		elseif card:isKindOf("Jink") then has_jink = card
		end
	end

	if has_slash then return "$"..has_slash:getEffectiveId()
	elseif has_jink then return "$"..has_jink:getEffectiveId()
	elseif has_analeptic or has_peach then
		if getCardsNum("Jink",target,self.player)==0 and self.player:getMark("drank")>0 and self:getAllPeachNum(target)==0 then
			if has_analeptic then return "$"..has_analeptic:getEffectiveId()
			else return "$"..has_peach:getEffectiveId()
			end
		end
	else return "."
	end
end


ai_skill_invoke.fangquan = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if #self.friends==1 then return (false) or false end

	-- First we'll judge whether it's worth skipping the Play Phase
	local cards = AIList.new(self.player:getHandcards())
	local shouldUse,range_fix = 0,0
	local hasCrossbow,slashTo = false,false
	for _,card in ipairs(cards)do
		if card:isKindOf("TrickCard") and self:getUseValue(card)>3.69 then
			local dummy_use = dummy()
			self:useTrickCard(card,dummy_use)
			if dummy_use.card then shouldUse = shouldUse+(card:isKindOf("ExNihilo") and 2 or 1) end
		end
		if card:isKindOf("Weapon") then
			local new_range = sgs.weapon_range[card:getClassName()] or 0
			local current_range = self.player:getAttackRange()
			range_fix = math.min(current_range-new_range,0)
		end
		if card:isKindOf("OffensiveHorse") and not self.player:getOffensiveHorse() then range_fix = range_fix-1 end
		if card:isKindOf("DefensiveHorse") or card:isKindOf("Armor") and not self:getSameEquip(card) and (self:isWeak() or self:getCardsNum("Jink")==0) then shouldUse = shouldUse+1 end
		if card:isKindOf("Crossbow") or self:hasCrossbowEffect() then hasCrossbow = true end
	end

	local slashs = self:getCards("Slash")
	for _,enemy in ipairs(self.enemies)do
		for _,slash in ipairs(slashs)do
			if hasCrossbow and self:getCardsNum("Slash")>1 and self:slashIsEffective(slash,enemy)
			and self.player:canSlash(enemy,slash,true,range_fix) then
				shouldUse = shouldUse+2
				hasCrossbow = false
				break
			elseif not slashTo and self:slashIsAvailable() and self:slashIsEffective(slash,enemy)
				and self.player:canSlash(enemy,slash,true,range_fix) and getCardsNum("Jink",enemy)<1 then
				shouldUse = shouldUse+1
				slashTo = true
			end
		end
	end
	if shouldUse>=2 then return false end

	-- Then we need to find the card to be discarded
	local limit = self.player:getMaxCards()
	if self.player:isKongcheng() then return (false) or false end
	if self:getCardsNum("Peach")>=limit-2 and self.player:isWounded() then return (false) or false end

	local to_discard = nil

	local index = 0
	local all_peaches = 0
	for _,card in ipairs(cards)do
		if isCard("Peach",card,self.player) then
			all_peaches = all_peaches+1
		end
	end
	if all_peaches>=2 and self:getOverflow()<=0 then return (false) or false end
	cards = self:sortByKeepValue(cards)

	for _,card in ipairs(cards)do
		if not isCard("Peach",card,self.player) and not self.player:isJilei(card) then
			to_discard = card:getEffectiveId()
			break
		end
	end

	if to_discard then
		if known(self:getRoleCounts().rebel,"mountain.role_count")==0 then
			local lord = self.room:getLord()
			if lord and self:isFriend(lord) then
				return (true) or false
			end
		end

		local AssistTarget = self:AssistTarget()
		if AssistTarget and not self:willSkipPlayPhase(AssistTarget) then
			return (true) or false
		end

		self.friends_noself = self:sortInPlace(self.friends_noself, "handcard")
		self.friends_noself = reversed(self.friends_noself)
		for _,target in ipairs(self.friends_noself)do
			if not skill(self,target,"dawu") and skill(self,target,"yongsi|zhiheng|"..sgs.priority_skill.."|shensu")
			and (not self:willSkipPlayPhase(target) or skill(self,target,"shensu")) then
				return (true) or false
			end
		end

		for _,target in ipairs(self.friends_noself)do
			if skill(self,target,"dawu") then
				local use = true
				for _,p in ipairs(self.friends_noself)do
					if p:getMark("&dawu")>0 then use = false break end
				end
				if use then
					return (true) or false
				end
			else
				return (true) or false
			end
		end
	end
	return (false) or false
end


ai_skill_choice.zhiji = function(self, options, request)
    local choice = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	if self.player:getHp()<self.player:getMaxHp()-1 then return ai_choice_result(("recover"), options) end
	return ai_choice_result(("draw"), options)
end

sgs.ai_cardneed.jiang = function(to,card,self)
	return isCard("Duel",card,to) or (isCard("Slash",card,to) and card:isRed())
end


sgs.ai_need_damaged.hunzi = function(self,attacker,player)
	if not skill(self,player,"chanyuan") and skill(self,player,"hunzi") and player:getMark("hunzi")==0 and self:getEnemyNumBySeat(self.room:getCurrent(),player,player,true)<player:getHp()
		and (player:getHp()>2 or player:getHp()==2 and (player:faceUp() or skill(self,player,"guixin") or skill(self,player,"toudu") and not player:isKongcheng())) then
		return true
	end
	return false
end


sgs.ai_skill_cardask["@beige"] = function(self,data)
	local damage = data:toDamage()
	if not self:isFriend(damage.to) or self:isFriend(damage.from) then return "." end
	local to_discard = self:askForDiscard("beige",1,1,false,true)
	if #to_discard>0 then return "$"..to_discard[1] else return "." end
end

function sgs.ai_cardneed.beige(to,card)
	return to:getCardCount()<=2
end


ai_skill_invoke.huashen = function(self, options, request)
	return (self.player:getHp()>0) or false
end

sgs.ai_can_damagehp.xinsheng = function(self,from,card,to)
	return not self:isWeak()
	and self:canLoseHp(from,card,to)
end


sgs.ai_suit_priority.jiang = function(self,card)
	return (card:isKindOf("Slash") or card:isKindOf("Duel")) and "diamond|heart|club|spade"
end

sgs.ai_cardneed.jiang = function(to,card,self)
	return isCard("Duel",card,to) or (isCard("Slash",card,to) and card:isRed())
end




sgs.ai_use_revises.renjie = function(self,card)
	if skill(self,self.player,"baiyin")
	and not skill(self,self.player,"jilve") and self.player:getMark("&bear")<4 then
		if (card:isKindOf("Peach") or card:isKindOf("Armor")) and self.player:getLostHp()>1
		or card:isKindOf("TrickCard") and (card:targetFixed() and not card:isDamageCard() or card:canRecast() or ("snatch|collateral"):match(card:objectName()))
		then return end
		return false
	end
end


ai_skill_invoke.jilve_guicai = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local n = self.player:getMark("&bear")
	local use = (n>2 or self:getOverflow()>0)
	local judge = data:toJudge()
	if not self:needRetrial(judge) then return (false) or false end
	return ((use or judge.who:objectName()==self.player:objectName() or judge.reason=="lightning")
	and self:getRetrialCardId(AIList.new(self.player:getHandcards()),judge)~=-1) or false
end

local function jilveFangzhuChosen(self,which)
	local fn = sgs.ai_skill_playerchosen[which]
	if type(fn)~="function" then return nil end
	return fn(self,self.room:getOtherPlayers(self.player))
end

ai_skill_invoke.jilve_fangzhu = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (jilveFangzhuChosen(self,"fangzhu")~=nil
	or jilveFangzhuChosen(self,"mobilefangzhu")~=nil
	or jilveFangzhuChosen(self,"sfofl_fangzhu")~=nil) or false
end

ai_skill_choice._jilve = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	choices = choices:split("+")
	if table.contains(choices,"tenyearjizhi") then return ai_choice_result(("tenyearjizhi"), options) end
	if table.contains(choices,"mobilefangzhu") and jilveFangzhuChosen(self,"mobilefangzhu")~=nil then
		return ai_choice_result(("mobilefangzhu"), options)
	end
	if table.contains(choices,"sfofl_fangzhu") and jilveFangzhuChosen(self,"sfofl_fangzhu")~=nil then
		return ai_choice_result(("sfofl_fangzhu"), options)
	end
	if table.contains(choices,"fangzhu") then return ai_choice_result(("fangzhu"), options) end
	return ai_choice_result((choices[2] or choices[1]), options)
end


ai_skill_choice.mobilelianpo = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	choices = choices:split("+")
	return ai_choice_result((choices[1]), options)
end

ai_skill_invoke.mobilejilve = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (self:canDraw()) or false
end

ai_skill_choice.mobilejilve = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	choices = choices:split("+")
	if self:getOverflow()<2 or self:isWeak() then
		return ai_choice_result((choices[2]), options)
	end
	return ai_choice_result((choices[#choices]), options)
end


ai_skill_invoke.lianpo=true
sgs.ai_cardneed.qiaobian=function(to,card) return to:getHandcardNum()<=2 end
sgs.ai_skill_defense.qiaobian=-2.4
sgs.ai_card_intention.FangquanCard=-80
sgs.ai_card_intention.fangquan=sgs.ai_card_intention.FangquanCard
ai_skill_invoke.jilve_jizhi=function(self, options, request)
    local n=known(self.player:getMark("&bear"),"jilve.bear")
    local use=n>2 or self:getOverflow()>0
    local context=self:getDecisionContext()
    local card=context.card or context.use and context.use.card
    return (use or known(card,"jilve_jizhi.card"):isKindOf("ExNihilo")) or false
end
ai_skill_invoke.guzheng=function(self, options, request)
    local data = request and self:getDecisionData(request) or nil
    local count=known(self:getDecisionContext().guzheng_to_get_count,"guzheng.discarded_count")
    return (self:canDraw() and (self:isFriend(data:toPlayer()) or count>2)) or false
end
sgs.ai_skill_askforag.guzheng=function(self,ids)
    local offered=known(self:getChoiceCards(),"guzheng.offered_cards")
    local cards={};for _,id in ipairs(ids) do
        local found;for _,card in ipairs(offered) do if card:getEffectiveId()==id then found=card;break end end
        cards[#cards+1]=known(found,"guzheng.disclosed_id")
    end
    cards=self:sortByKeepValue(cards)
    return known(self:isFriend(self.room:getCurrent()) and cards[#cards] or cards[1],"guzheng.nonempty"):getId()
end

local function skill_metadata(self,name,kind)
    local context=self:getDecisionContext()
    local row=known(context.huashen_skills and context.huashen_skills[name],"huashen.offered_skill_metadata")
    if kind=="view_as" and not row.view_as or kind=="trigger" and not row.trigger or not known(row.exists,"huashen.skill_exists") then return nil end
    return {objectName=function()return name end,getDescription=function()return known(row.description,"huashen.description")end,
        isEnabledAtPlay=function()return known(row.enabled_at_play,"huashen.owner_enabled")end,
        hasEvent=function(_,event)
            if event~=sgs.CardsMoveOneTime then ai_unsupported("unprojected Huashen event","huashen.trigger") end
            return known(row.has_cards_move,"huashen.cards_move")
        end}
end
local function skill_defense(self,name)
    local history,available=self:getEventMemory("defense_statistics")
    local sum=0
    if available and type(history)=="table" then
        for _,class in ipairs({"drawData","damageData","throwData","convertData"}) do
            for key,samples in pairs(history[class] or {}) do
                -- Source matches the complete line using the skill as a Lua
                -- pattern, not exact key lookup. Preserve that matching order.
                if key:match(name) and #samples>0 then
                    local total=0;for _,value in ipairs(samples) do total=total+value end
                    sum=sum+total/#samples
                end
            end
        end
    end
    return self:useKnowledgeEstimate({status="estimate",value=sum,basis="mountain.huashen_viewer_history_replaces_unpartitioned_files"},"huashen.skillDefense")
end
local function match_one(text,option)
    return text:match("^"..option.."%p") or text:match("%p"..option.."%p") or text:match("%p"..option.."$")
end
function ai_skill_choice.huashen(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil
    local xiaode_choice = options and options.xiaode_choice

	local str = choices
	choices = str:split("+")
	local function compare_func(a,b)
		return skill_defense(self,a)>skill_defense(self,b)
	end
	table.sort(choices,compare_func)
	if not xiaode_choice and self.player:getHp()<1 and match_one(str,"nosbuqu") then return ai_choice_result(("nosbuqu"), options) end
	if xiaode_choice and xiaode_choice>0
	or self.player:getPhase()==sgs.Player_RoundStart
	then
		if not xiaode_choice and self.player:getHp()<1 and match_one(str,"nosbuqu") then return ai_choice_result(("nosbuqu"), options) end
		if self.player:getHandcardNum()>=self.player:getHp() and self.player:getHandcardNum()<10 and not self:isWeak()
		or self.player:isSkipped(sgs.Player_Play)
		then
			if match_one(str,"keji") then return ai_choice_result(("keji"), options) end
		end
		if self.player:getHandcardNum()>4
		then
			for vs,askill in ipairs(choices)do
				vs = skill_metadata(self,askill,"view_as")
				if vs and not skill(self,self.player,vs)
				and vs:isEnabledAtPlay(self.player) then return ai_choice_result((askill), options) end
			end
			if self:findFriendsByType(sgs.Friend_Draw)
			then
				for _,askill in ipairs(("nosrende|rende|lirang|longluo"):split("|"))do
					if match_one(str,askill) then return ai_choice_result((askill), options) end
				end
			end
		end
		if self.player:getLostHp()>=2
		then
			if match_one(str,"qingnang") then return ai_choice_result(("qingnang"), options) end
			if match_one(str,"jieyin") and self:findFriendsByType(sgs.Friend_MaleWounded) then return ai_choice_result(("jieyin"), options) end
			if match_one(str,"nosrende") and self:findFriendsByType(sgs.Friend_Draw) then return ai_choice_result(("nosrende"), options) end
			if match_one(str,"rende") and self:findFriendsByType(sgs.Friend_Draw) then return ai_choice_result(("rende"), options) end
			for sk,ac in ipairs(choices)do
				sk = skill_metadata(self,ac)
				if sk and string.find(sk:getDescription(),"已损失")-- or string.find(sk:getDescription(),"至体力上限")
				and not skill(self,self.player,sk)
				then return ai_choice_result((ac), options) end
			end
			if match_one(str,"miji") and self:findFriendsByType(sgs.Friend_Draw) then return ai_choice_result(("miji"), options) end
		end
		if self.player:getHandcardNum()<2
		then
			if match_one(str,"haoshi") then return ai_choice_result(("haoshi"), options) end
		end
		if self.player:isWounded()
		then
			if match_one(str,"qingnang") then return ai_choice_result(("qingnang"), options) end
			if match_one(str,"jieyin") and self:findFriendsByType(sgs.Friend_MaleWounded) then return ai_choice_result(("jieyin"), options) end
			if match_one(str,"nosrende") and self:findFriendsByType(sgs.Friend_Draw) then return ai_choice_result(("nosrende"), options) end
			if match_one(str,"rende") and self:findFriendsByType(sgs.Friend_Draw) then return ai_choice_result(("rende"), options) end
			for sk,ac in ipairs(choices)do
				sk = skill_metadata(self,ac)
				if sk and string.find(sk:getDescription(),"已损失")-- or string.find(sk:getDescription(),"至体力上限")
				and not skill(self,self.player,sk)
				then return ai_choice_result((ac), options) end
			end
			if self.player:getHp()<2 and self.player:getHandcardNum()==1 and self:getCardsNum("Peach")<1 then
				if match_one(str,"shenzhi") then return ai_choice_result(("shenzhi"), options) end
			end
		end
		if self.player:getEquips():length()>1
		then
			for sk,ac in ipairs(choices)do
				sk = skill_metadata(self,ac)
				if sk and string.find(sk:getDescription(),"装备区")
				and not skill(self,self.player,sk)
				then
					sk = skill_metadata(self,ac,"trigger")
					if sk and sk:hasEvent(sgs.CardsMoveOneTime)
					then return ai_choice_result((ac), options) end
				end
			end
		end
		if self.player:getWeapon()
		then
			for sk,ac in ipairs(choices)do
				sk = skill_metadata(self,ac)
				if sk and not skill(self,self.player,sk)
				and string.find(sk:getDescription(),"武器牌")
				then return ai_choice_result((ac), options) end
			end
		end
		for sk,ac in ipairs(choices)do
			sk = skill_metadata(self,ac)
			if sk and not skill(self,self.player,sk)
			and (string.find(sk:getDescription(),"准备阶段") or string.find(sk:getDescription(),"摸牌阶段"))
			then return ai_choice_result((ac), options) end
		end
		if self:findFriendsByType(sgs.Friend_Draw)
		then
			for sk,ac in ipairs(choices)do
				sk = skill_metadata(self,ac)
				if sk and string.find(sk:getDescription(),"出牌阶段")
				and not skill(self,self.player,sk)
				then return ai_choice_result((ac), options) end
			end
		end
		for vs,askill in ipairs(choices)do
			vs = skill_metadata(self,askill,"view_as")
			if vs and not skill(self,self.player,vs)
			and vs:isEnabledAtPlay(self.player) then return ai_choice_result((askill), options) end
		end
		for sk,ac in ipairs(choices)do
			sk = skill_metadata(self,ac)
			if sk and string.find(sk:getDescription(),"阶段")
			and not skill(self,self.player,sk)
			then return ai_choice_result((ac), options) end
		end
	else
		if self.player:getHp()==1
		then
			for sk,ac in ipairs(choices)do
				sk = skill_metadata(self,ac)
				if sk and (string.find(sk:getDescription(),"濒死") or string.find(sk:getDescription(),"死亡"))
				and not skill(self,self.player,sk)
				then return ai_choice_result((ac), options) end
			end
		end
		if self:getAllPeachNum()>0 or self.player:getHp()>1 or not self:isWeak()
		then
			for sk,ac in ipairs(choices)do
				sk = skill_metadata(self,ac)
				if sk and string.find(sk:getDescription(),"受到")
				and not skill(self,self.player,sk)
				then return ai_choice_result((ac), options) end
			end
		end
		if self.room:alivePlayerCount()>2
		then
			for sk,ac in ipairs(choices)do
				sk = skill_metadata(self,ac)
				if sk and string.find(sk:getDescription(),"成为")
				and not skill(self,self.player,sk)
				then return ai_choice_result((ac), options) end
			end
		end
		if self.player:isKongcheng() and match_one(str,"kongcheng")
		then return ai_choice_result(("kongcheng"), options) end
		for sk,ac in ipairs(choices)do
			sk = skill_metadata(self,ac)
			if sk and string.find(sk:getDescription(),"视为装备")
			and not skill(self,self.player,sk)
			then return ai_choice_result((ac), options) end
		end
		if not self.player:faceUp() then
			for sk,ac in ipairs(choices)do
				sk = skill_metadata(self,ac)
				if sk and string.find(sk:getDescription(),"翻面")
				and not skill(self,self.player,sk)
				then return ai_choice_result((ac), options) end
			end
		end
		if self.player:getHandcardNum()>self.player:getHp() and self.player:getCards("e"):length()>0
		and match_one(str,"yanzheng") then return ai_choice_result(("yanzheng"), options) end
		if self.player:getEquips():length()>1
		then
			for sk,ac in ipairs(choices)do
				sk = skill_metadata(self,ac)
				if sk and string.find(sk:getDescription(),"装备区")
				and not skill(self,self.player,sk)
				then
					sk = skill_metadata(self,ac,"trigger")
					if sk and sk:hasEvent(sgs.CardsMoveOneTime)
					then return ai_choice_result((ac), options) end
				end
			end
		end
		for sk,ac in ipairs(choices)do
			sk = skill_metadata(self,ac)
			if sk and string.find(sk:getDescription(),"防止")
			and not skill(self,self.player,sk)
			then return ai_choice_result((ac), options) end
		end
		for sk,ac in ipairs(choices)do
			sk = skill_metadata(self,ac)
			if sk and string.find(sk:getDescription(),"对你无效")
			and not skill(self,self.player,sk)
			then return ai_choice_result((ac), options) end
		end
		for sk,ac in ipairs(choices)do
			sk = skill_metadata(self,ac)
			if sk and string.find(sk:getDescription(),"你可以将")
			and not skill(self,self.player,sk)
			then return ai_choice_result((ac), options) end
		end
		for sk,ac in ipairs(choices)do
			sk = skill_metadata(self,ac)
			if sk and string.find(sk:getDescription(),"受到")
			and not skill(self,self.player,sk)
			then return ai_choice_result((ac), options) end
		end
		for sk,ac in ipairs(choices)do
			sk = skill_metadata(self,ac)
			if sk and string.find(sk:getDescription(),"当你使用")
			and not skill(self,self.player,sk)
			then return ai_choice_result((ac), options) end
		end
		for sk,ac in ipairs(choices)do
			sk = skill_metadata(self,ac)
			if sk and string.find(sk:getDescription(),"当你成为")
			and not skill(self,self.player,sk)
			then return ai_choice_result((ac), options) end
		end
	end
	for i=#choices,1,-1 do
		if ("renjie|benghuai|shenjun|dongcha|yishe|shiyong|wumou|yaowu"):match(choices[i])
		then table.remove(choices,i) end
	end
	if not xiaode_choice and #choices>0 then
		return ai_choice_result((choices[math.random(1,#choices)]), options)
	end

    return ai_choice_result(nil, options)
end

function sgs.ai_slash_prohibit.xiangle(self,from,to)
	if self:isFriend(to,from) then return false end
	local slash_num,analeptic_num,jink_num
	if from:objectName()==self.player:objectName() then
		slash_num = self:getCardsNum("Slash")
		analeptic_num = self:getCardsNum("Analeptic")
		jink_num = self:getCardsNum("Jink")
	else
		slash_num = getCardsNum("Slash",from,self.player)
		analeptic_num = getCardsNum("Analpetic",from,self.player)
		jink_num = getCardsNum("Jink",from,self.player)
	end
	if self.player:getHandcardNum()==2 then
        local previous=self._mountain_xiangle_guard
        self._mountain_xiangle_guard=skill(self,self.player,"beifa") or previous
        local ok,needkongcheng=pcall(self.needKongcheng,self)
        self._mountain_xiangle_guard=previous
        if not ok then error(needkongcheng,0) end
		if needkongcheng then return slash_num+analeptic_num+jink_num<2 end
	end
	return slash_num+analeptic_num+math.max(jink_num-1,0)<2
end

ai_skill_use["@@fangquan"] = function(self,prompt,request)
	local cards = AIList.new(self.player:getHandcards())
	cards = self:sortByKeepValue(cards)
	if known(self:getRoleCounts().rebel,"mountain.role_count")==0 then
		local lord = self.room:getLord()
		if lord and self:isFriend(lord) and lord:objectName()~=self.player:objectName() then
			return action(self,"fangquan",{cards[1]:getEffectiveId()},{lord},request)
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) then
		return action(self,"fangquan",{cards[1]:getEffectiveId()},{AssistTarget},request)
	end

	self.friends_noself = self:sortInPlace(self.friends_noself, "chaofeng")
	for _,target in ipairs(self.friends_noself)do
		if not skill(self,target,"dawu") and skill(self,target,"yongsi|zhiheng|"..sgs.priority_skill.."|shensu")
			and (not self:willSkipPlayPhase(target) or skill(self,target,"shensu")) then
			return action(self,"fangquan",{cards[1]:getEffectiveId()},{target},request)
		end
	end

	for _,target in ipairs(self.friends_noself)do
		if skill(self,target,"dawu") then
			local use = true
			for _,p in ipairs(self.friends_noself)do
				if p:getMark("&dawu")>0 then use = false break end
			end
			if use then
				return action(self,"fangquan",{cards[1]:getEffectiveId()},{target},request)
			end
		else
			return action(self,"fangquan",{cards[1]:getEffectiveId()},{target},request)
		end
	end
	return "."
end

sgs.ai_card_intention.FangquanCard = -80


local function role(self,player)
    local result=player:getRole();if result~=nil then return result end
    return self:useKnowledgeEstimate({status="estimate",value=known(self:getRoleEstimate(player),"mountain.role"),basis="mountain.private_role_uses_viewer_inference",target=player:objectName()},"mountain.role")
end
function sgs.ai_slash_prohibit.duanchang(self,from,to)
	if self:hasJueqingEffect(from,to) or (skill(self,from,"nosqianxi") and from:distanceTo(to)==1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if to:getHp()>1 or #(self:getEnemies(from))==1 then return false end
	if from:getMaxHp()==3 and from:getArmor() and from:getDefensiveHorse() then return false end
	if from:getMaxHp()<=3 or (from:isLord() and self:isWeak(from)) then return true end
	if from:getMaxHp()<=3 or (self.room:getLord() and role(self,from)=="renegade") then return true end
	return false
end



ai_skill_choice.zhiba_pindian = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local who = self.room:getCurrent()
	local cards = self.player:getHandcards()
	local has_large_number,all_small_number = false,true
	for _,c in ipairs(cards)do
		if c:getNumber()>11 then
			has_large_number = true
			break
		end
	end
	for _,c in ipairs(cards)do
		if c:getNumber()>4 then
			all_small_number = false
			break
		end
	end
	if all_small_number or (self:isEnemy(who) and not has_large_number) then return ai_choice_result(("reject"), options)
	else return ai_choice_result(("accept"), options)
	end

    return ai_choice_result(nil, options)
end

ai_skill_choice.zhiba_pindian_obtain = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	if self.player:isKongcheng() and self:needKongcheng() then return ai_choice_result(("reject"), options) end
	return ai_choice_result(("obtainPindianCards"), options)
end

function sgs.ai_skill_pindian.zhiba_pindian(minusecard,self,requestor,maxcard)
	local cards,maxcard = AIList.new(self.player:getHandcards())
	local function compare_func(a,b)
		return a:getNumber()>b:getNumber()
	end
	table.sort(cards,compare_func)
	for _,card in ipairs(cards)do
		if self:getUseValue(card)<6 then maxcard = card break end
	end
	return maxcard or cards[1]
end


local function proposal(skill,name,cards)
    local ids={};for _,card in ipairs(cards) do ids[#ids+1]=known(card:getEffectiveId(),"mountain.material") end
    local suit=known(cards[1]:getSuit(),"mountain.suit")
    if #cards>1 then
        local red,black=true,true
        for _,card in ipairs(cards) do
            local current=known(card:getSuit(),"mountain.suit")
            red=red and (current==sgs.Card_Heart or current==sgs.Card_Diamond or current==sgs.Card_NoSuitRed)
            black=black and (current==sgs.Card_Spade or current==sgs.Card_Club or current==sgs.Card_NoSuitBlack)
        end
        suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit
    end
    return {skill=skill,name=name,suit=known(suit,"mountain.derived_suit"),
        number=#cards==1 and known(cards[1]:getNumber(),"mountain.number") or 0,subcards=ids}
end
local function bind_turn(self,skill,class,spec,request)
    -- Both fill sources construct policy hypotheses before selected admission.
    -- NewLonghun's two-material parser explicitly uses to_be_decided/0.
    if skill=="newlonghun" and #spec.subcards==2 then spec.suit=sgs.Card_SuitToBeDecided;spec.number=0 end
    return self:evaluateTurnConversion(skill,class,spec,request)
end
sgs.ai_view_as.longhun=function(card,player,place)
    if player:getHp()>1 or place==sgs.Player_PlaceSpecial then return end
    local name=({[sgs.Card_Diamond]="fire_slash",[sgs.Card_Club]="jink",[sgs.Card_Heart]="peach",[sgs.Card_Spade]="nullification"})[card:getSuit()]
    if name then return proposal("longhun",name,{card}) end
end
ai_fill_skill.longhun=function(self, options, request)
    local inclusive = options and options.inclusive

    if self.player:getHp()>1 then return end
    local cards=self:sortByUseValue(self:addHandPile("he"),true)
    for _,card in ipairs(cards) do
        if card:getSuit()==sgs.Card_Diamond and self:slashIsAvailable() then
            return bind_turn(self,"longhun","FireSlash",proposal("longhun","fire_slash",{card}),request)
        end
    end
end
sgs.longhun_suit_value={heart=6.7,spade=5,club=4.2,diamond=3.9}
sgs.ai_cardneed.longhun=function(to,card,self)
    if to:getCardCount()>3 then return false end
    if to:isNude() then return true end
    return card:getSuit()==sgs.Card_Heart or card:getSuit()==sgs.Card_Spade
end
sgs.newlonghun_suit_value=sgs.longhun_suit_value
sgs.ai_cardneed.newlonghun=sgs.ai_cardneed.longhun
sgs.ai_need_damaged.newlonghun=function(self,attacker,player)
    if player:getHp()>1 and skill(self,player,"newjuejing") then return true end
end
ai_fill_skill.newlonghun=function(self, options, request)
    local inclusive = options and options.inclusive

    local cards=self:addHandPile()
    for _,card in ipairs(self.player:getCards("e")) do
        if card:isKindOf("DefensiveHorse") or card:isKindOf("OffensiveHorse") then cards[#cards+1]=card end
    end
    cards=self:sortByUseValue(cards,true)
    local diamonds={}
    local function occupied_ox(card)return card:isKindOf("WoodenOx") and #self.player:getPile("wooden_ox")>0 end
    for _,card in ipairs(cards) do
        if card:getSuit()==sgs.Card_Diamond and #diamonds<2 and not card:isKindOf("Peach") and not occupied_ox(card) then diamonds[#diamonds+1]=card end
    end
    if #diamonds==2 and self:slashIsAvailable() and self:getOverflow()>1 then
        return bind_turn(self,"newlonghun","FireSlash",proposal("newlonghun","fire_slash",diamonds),request)
    end
    for _,card in ipairs(cards) do
        if card:getSuit()==sgs.Card_Diamond and self:slashIsAvailable() and not card:isKindOf("Peach")
            and not(card:isKindOf("Jink") and self:getCardsNum("Jink")<3) and not occupied_ox(card) then
            return bind_turn(self,"newlonghun","FireSlash",proposal("newlonghun","fire_slash",{card}),request)
        end
    end
    for _,card in ipairs(cards) do
        if card:getSuit()==sgs.Card_Heart and self.player:getMark("Global_PreventPeach")==0 and not card:isKindOf("Peach") then
            return bind_turn(self,"newlonghun","Peach",proposal("newlonghun","peach",{card}),request)
        end
    end
end
sgs.ai_view_as.newlonghun=function(card,player,place,class_name)
    if place==sgs.Player_PlaceSpecial then return end
    local room=known(rawget(player,"_room"),"newlonghun.room")
    local current=room:getCurrent()
    local cards=AIList.new(player:getCards("he"))
    for _,pile_card in ipairs(known(player:getHandPileCards(),"newlonghun.handpile")) do cards[#cards+1]=pile_card end
    local clubs,hearts={},{}
    for _,c in ipairs(cards) do
        if c:getSuit()==sgs.Card_Club and #clubs<2 then clubs[#clubs+1]=c
        elseif c:getSuit()==sgs.Card_Heart and #hearts<2 then hearts[#hearts+1]=c end
    end
    if #clubs==2 and current and not current:isNude() and current:getWeapon() and current:getWeapon():isKindOf("Crossbow") then
        return proposal("newlonghun","jink",clubs)
    elseif card:getSuit()==sgs.Card_Club then return proposal("newlonghun","jink",{card}) end
    local dying=room:getCurrentDyingPlayer()
    if #hearts==2 and dying and not skill(known(room._ai,"newlonghun.observer"),dying,"newjuejing") then return proposal("newlonghun","peach",hearts)
    elseif card:getSuit()==sgs.Card_Heart and player:getMark("Global_PreventPeach")==0 then return proposal("newlonghun","peach",{card}) end
    if card:getSuit()==sgs.Card_Diamond and not(card:isKindOf("WoodenOx") and #player:getPile("wooden_ox")>0) then
        return proposal("newlonghun","fire_slash",{card})
    elseif card:getSuit()==sgs.Card_Spade then return proposal("newlonghun","nullification",{card}) end
end
function SmartAIView:card_for_qiaobian(who,flag,to_friends,to_enemies)
	flag = flag or "ej"
	to_friends = to_friends or self.friends
	to_enemies = to_enemies or self.enemies
	local card,target
	if self:isFriend(who) then
		if flag:match("j") then
			for _,judge in ipairs(who:getJudgingArea())do
				if not judge:isKindOf("YanxiaoCard") then
					for _,enemy in ipairs(to_enemies)do
						if not enemy:containsTrick("YanxiaoCard")
						and not known(self.player:isProhibited(enemy,judge),"qiaobian.prohibited")
						and not (skill(self,enemy,"hongyan|olhongyan") or judge:isKindOf("Lightning"))
						then return enemy,judge end
					end
				end
			end
		end
		if flag:match("e") and #who:getEquips()>0 then
			if skill(self,who,sgs.lose_equip_skill) then
				for _,equip in ipairs(who:getCards("e"))do
					if self:doDisCard(who,equip:getEffectiveId(),true) then
						if equip:isKindOf("DefensiveHorse")
						and not self:isWeak(who) then card = equip break
						elseif equip:isKindOf("Armor") and (not self:isWeak(who) or self:needToThrowArmor(who))
						then card = equip break else card = equip break end
					end
				end
				if card then
					local index = card:getEquipSlot()
					if #self:poisonCards({card},who)>0 then
						to_enemies = self:sortInPlace(to_enemies, "defense")
						for _,friend in ipairs(to_enemies)do
							if not friend:hasEquipArea(index) then continue end
							if not self:getSameEquip(card,friend) and friend:objectName()~=who:objectName()
							then return friend,card end
						end
					else
						if card:isKindOf("Armor")
						or card:isKindOf("DefensiveHorse") then
							to_friends = self:sortInPlace(to_friends, "defense")
						else
							to_friends = self:sortInPlace(to_friends, "handcard", true)
						end
						for _,friend in ipairs(to_friends)do
							if not friend:hasEquipArea(index) then continue end
							if not self:getSameEquip(card,friend) and friend:objectName()~=who:objectName()
							and skill(self,friend,sgs.need_equip_skill.."|"..sgs.lose_equip_skill)
							then return friend,card end
						end
						for _,friend in ipairs(to_friends)do
							if not friend:hasEquipArea(index) then continue end
							if not self:getSameEquip(card,friend) and friend:objectName()~=who:objectName()
							then return friend,card end
						end
					end
				end
			end
		end
	else
		if flag:match("j")
		and who:containsTrick("YanxiaoCard") then
			for _,judge in ipairs(who:getJudgingArea())do
				if judge:isKindOf("YanxiaoCard") then
					for _,friend in ipairs(to_friends)do
						if not friend:containsTrick(judge:objectName())
						and not known(self.player:isProhibited(friend,judge),"qiaobian.prohibited")
						and friend:getJudgingArea():length()>0
						then return friend,judge end
					end
					for _,friend in ipairs(to_friends)do
						if not friend:containsTrick(judge:objectName())
						and not known(self.player:isProhibited(friend,judge),"qiaobian.prohibited")
						then return friend,judge end
					end
				end
			end
		end
		if flag:match("e") and #who:getEquips()>0 then
			if skill(self,who,sgs.lose_equip_skill) then return end
			local card_id = self:askForCardChosen(who,"e","snatch")
			if card_id>=0 then
                for _,equip in ipairs(who:getEquips()) do if equip:getEffectiveId()==card_id then card=equip;break end end
            end
			if card and #self:poisonCards({card},who)<1 then
				local index = card:getEquipSlot()
				if card:isKindOf("Armor")
				or card:isKindOf("DefensiveHorse") then
					to_friends = self:sortInPlace(to_friends, "defense")
				else
					to_friends = self:sortInPlace(to_friends, "handcard", true)
				end
				for _,friend in ipairs(to_friends)do
					if not friend:hasEquipArea(index) then continue end
					if not self:getSameEquip(card,friend) and friend:objectName()~=who:objectName()
					and skill(self,friend,sgs.lose_equip_skill.."|shensu|tenyearshensu")
					then return friend,card end
				end
				for _,friend in ipairs(to_friends)do
					if not friend:hasEquipArea(index) then continue end
					if not self:getSameEquip(card,friend) and friend:objectName()~=who:objectName()
					then return friend,card end
				end
			end
		end
	end
end

sgs.ai_skill_discard.qiaobian = function(self,discard_num,min_num,optional,include_equip)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = AIList.new(cards)
	cards = self:sortByUseValue(cards,true)
	local stealer
	for _,ap in ipairs(self.room:getOtherPlayers(self.player))do
		if skill(self,ap,"tuxi|nostuxi") and self:isEnemy(ap) then stealer = ap end
	end
	local card
	for i=1,#cards,1 do
		local isPeach = cards[i]:isKindOf("Peach")
		if isPeach then
			if stealer and self:isEnemy(stealer) and self.player:getHandcardNum()<=2 and self.player:getHp()>2
			and (not stealer:containsTrick("supply_shortage") or stealer:containsTrick("YanxiaoCard")) then
				card = cards[i]
				break
			end
			local to_discard_peach = true
			for _,fd in ipairs(self.friends)do
				if fd:getHp()<=2 and not skill(self,fd,"niepan") then
					to_discard_peach = false
				end
			end
			if to_discard_peach then
				card = cards[i]
				break
			end
		else
			card = cards[i]
			break
		end
	end
	if card==nil then return {} end
	table.insert(to_discard,card:getEffectiveId())
	local current_phase = self.player:getMark("qiaobianPhase")
	if current_phase==sgs.Player_Judge and not self.player:isSkipped(sgs.Player_Judge) then
		if not self.player:containsTrick("YanxiaoCard") then
			if (self.player:containsTrick("lightning") and not self:hasWizard(self.friends) and self:hasWizard(self.enemies))
				or (self.player:containsTrick("lightning") and #self.friends>#self.enemies) then
				return to_discard
			elseif self.player:containsTrick("supply_shortage") then
				if self.player:getHp()>self.player:getHandcardNum() then return to_discard end
				if #self:selectNosTuxiTargets("@nostuxi")==2 then return to_discard end
			elseif self.player:containsTrick("indulgence") then
				if self.player:getHandcardNum()>3 or self.player:getHandcardNum()>self.player:getHp()-1 then return to_discard end
				for _,friend in ipairs(self.friends_noself)do
					if not friend:containsTrick("YanxiaoCard") and (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
						return to_discard
					end
				end
			end
		end
	elseif current_phase==sgs.Player_Draw and not self.player:isSkipped(sgs.Player_Draw) and not skill(self,self.player,"tuxi|nostuxi") then
		if #self:selectNosTuxiTargets("@nostuxi")==2 then return to_discard end
		return {}
	elseif current_phase==sgs.Player_Play and not self.player:isSkipped(sgs.Player_Play)
	then
		cards = self:sortByKeepValue(cards)
		table.remove(to_discard)
		table.insert(to_discard,cards[1]:getEffectiveId())

		self.enemies = self:sortInPlace(self.enemies, "defense")
		self.friends = self:sortInPlace(self.friends, "defense")
		self.friends_noself = self:sortInPlace(self.friends_noself, "defense")

		for _,friend in ipairs(self.friends)do
			if not friend:getCards("j"):isEmpty() and not friend:containsTrick("YanxiaoCard")
			and self:card_for_qiaobian(friend)
			then return to_discard end
		end

		for _,enemy in ipairs(self.enemies)do
			if not enemy:getCards("j"):isEmpty() and enemy:containsTrick("YanxiaoCard")
			and self:card_for_qiaobian(enemy)
			then return to_discard end
		end

		for _,friend in ipairs(self.friends_noself)do
			if not friend:getCards("e"):isEmpty()
			and self:hasSkills(sgs.lose_equip_skill,friend)
			and self:card_for_qiaobian(friend)
			then return to_discard end
		end

		local top_value = 0
		for _,hcard in ipairs(cards)do
			if not hcard:isKindOf("Jink") then
				if self:getUseValue(hcard)>top_value then top_value = self:getUseValue(hcard) end
			end
		end
		if top_value>=3.7 and #(self:getTurnUse())>0 then return {} end

		local targets = {}
		for _,enemy in ipairs(self.enemies)do
			if not self:hasSkills(sgs.lose_equip_skill,enemy)
			and self:card_for_qiaobian(enemy)
			then table.insert(targets,enemy) end
		end

		if #targets>0 then
			targets = self:sortInPlace(targets, "defense")
			return to_discard
		end
	elseif current_phase==sgs.Player_Discard and not self.player:isSkipped(sgs.Player_Discard) then
		cards = self:sortByKeepValue(cards)
		if self:needBear() then return {} end
		if self.player:getHandcardNum()>self:getOverflow(self.player,true) then
			return { cards[1]:getEffectiveId() }
		end
	end

	return {}
end


sgs.ai_skill_cardchosen.qiaobian=function(self,who,flags)
    if flags=="ej" then local target,card=self:card_for_qiaobian(who);return card and card:getEffectiveId() end
end
sgs.ai_skill_playerchosen.qiaobian=function(self,targets)
    local name=known(self:getDecisionContext().qiaobian_target,"qiaobian.target")
    if name then
        local who=known(self.room:findPlayerByObjectName(name),"qiaobian.target_player")
        return self:card_for_qiaobian(who)
    end
end
ai_skill_use["@@qiaobian"] = function(self,prompt,request)
	local cards = self.player:getHandcards()
	cards = AIList.new(cards)
	cards = self:sortByUseValue(cards,true)
	local card = cards[1]

    if prompt=="@qiaobian-2" then
        local targets=self:selectNosTuxiTargets("@nostuxi")
        if #targets>0 then return action(self,"qiaobian",{},targets,request) end
        return "."
    end

	if prompt=="@qiaobian-3" then


		self.enemies = self:sortInPlace(self.enemies, "defense")
		for _,friend in ipairs(self.friends)do
			if not friend:getCards("j"):isEmpty() and not friend:containsTrick("YanxiaoCard")
			and self:card_for_qiaobian(friend)
			then

				return action(self,"qiaobian",{},{friend},request)
			end
		end

		for _,enemy in ipairs(self.enemies)do
			if not enemy:getCards("j"):isEmpty() and enemy:containsTrick("YanxiaoCard")
			and self:card_for_qiaobian(enemy)
			then

				return action(self,"qiaobian",{},{enemy},request)
			end
		end

		for _,friend in ipairs(self.friends_noself)do
			if not friend:getCards("e"):isEmpty() and self:hasSkills(sgs.lose_equip_skill,friend)
			and self:card_for_qiaobian(friend)
			then
				return action(self,"qiaobian",{},{friend},request)
			end
		end

		local top_value = 0
		for _,hcard in ipairs(cards)do
			if not hcard:isKindOf("Jink") then
				if self:getUseValue(hcard)>top_value then top_value = self:getUseValue(hcard) end
			end
		end
		if top_value>=3.7 and #(self:getTurnUse())>0 then return "." end

		local targets = {}
		for _,enemy in ipairs(self.enemies)do
			if self:card_for_qiaobian(enemy)
			then
				table.insert(targets,enemy)
			end
		end

		if #targets>0 then
			targets = self:sortInPlace(targets, "defense")

			return action(self,"qiaobian",{},{targets[#targets]},request)
		end
	end

	return "."
end


sgs.ai_card_intention.QiaobianCard=function(self,card,from,targets)
    if from:getMark("qiaobianPhase")==3 then return sgs.ai_card_intention.TuxiCard(self,card,from,targets) end
end
sgs.ai_card_intention.qiaobian=sgs.ai_card_intention.QiaobianCard

local function bind_legacy(self,skill_name,class,costs,request)
    if self:isUseReviseSkillEvaluation(skill_name,class) then
        return self:evaluateUseReviseSkillCard(skill_name,class,costs)
    end
    if request and type(request.getActivationSkillName)~="function" then request=AILegacyRequest.new(request,self.room) end
    local receipt=self:bindSkillCard(skill_name,costs,request)
    local number=#costs==1 and receipt:getNumber() or 0
    local suit=sgs.Card_NoSuit
    if #costs>0 then
        assert(#costs==1,"Mountain legacy SkillCard has one material")
        local material
        for _,card in ipairs(self.player:getCards("he")) do
            if card:getEffectiveId()==costs[1] then material=card;break end
        end
        suit=known(material,"mountain.legacy_material"):getSuit()
    end
    local suit_name=({[sgs.Card_Spade]="spade",[sgs.Card_Club]="club",[sgs.Card_Heart]="heart",[sgs.Card_Diamond]="diamond",[sgs.Card_NoSuit]="no_suit"})[suit]
    if suit==sgs.Card_NoSuitBlack then suit_name="no_suit_black" elseif suit==sgs.Card_NoSuitRed then suit_name="no_suit_red" end
    local printed=({[1]="A",[11]="J",[12]="Q",[13]="K",[14]="JOKER",[15]="JOKER"})[number] or tostring(number)
    local text="@"..class.."["..known(suit_name,"mountain.legacy_suit")..":"..printed.."]="..(#costs>0 and table.concat(costs,"+") or ".")
    local policy={name="",class_name=class,type_id=0,kind_of={class,"SkillCard","Card"},subcards=costs,
        suit=suit,number=number,red=suit==sgs.Card_Heart or suit==sgs.Card_Diamond or suit==sgs.Card_NoSuitRed,
        black=suit==sgs.Card_Spade or suit==sgs.Card_Club or suit==sgs.Card_NoSuitBlack,damage_card=false,can_recast=false,
        will_throw=class~="ZhijianCard",handling_method=class=="ZhijianCard" and sgs.Card_MethodNone or sgs.Card_MethodDiscard,
        legacy_string_key=text,legacy_sort_key=text}
    if #costs>0 then policy.effective_id=costs[1] end
    return self:legacyPolicyCard(receipt,policy)
end
ai_fill_skill.tiaoxin=function(self, options, request)
    local inclusive = options and options.inclusive
 return self:legacySkillSeed("tiaoxin","TiaoxinCard",request) end
ai_fill_skill.zhiba_pindian=function(self, options, request)
    local inclusive = options and options.inclusive

    if self:needBear() or self:getOverflow()<=0 or self.player:getKingdom()~="wu" then return end
    return self:legacySkillSeed("zhiba_pindian","ZhibaCard",request)
end
ai_fill_skill.zhijian=function(self, options, request)
    local inclusive = options and options.inclusive

    local equips={}
    for _,card in ipairs(self.player:getHandcards()) do if card:getTypeId()==sgs.Card_TypeEquip then equips[#equips+1]=card end end
    if #equips==0 then return end
    return self:legacySkillSeed("zhijian","ZhijianCard",request)
end
-- isTiaoxinTarget and needBear use the existing complete common helpers.
ai_card_use.TiaoxinCard = function(self, card, use, request)
	local distance = use.DefHorse and 1 or 0
	local targets = {}
	for _,enemy in ipairs(self.enemies)do
		if enemy:distanceTo(self.player,distance)<=enemy:getAttackRange() and self:doDisCard(enemy,"he") and self:isTiaoxinTarget(enemy) then
			table.insert(targets,enemy)
		end
	end

	if #targets==0 then return end

	self:setPriorityValue("TiaoxinCard",8,"tiaoxin")
	if not self.player:getArmor() and not self.player:isKongcheng() then
		for _,card in ipairs(self.player:getCards("h"))do
			if card:isKindOf("Armor") and self:evaluateArmor(card)>3 then
				self:setPriorityValue("TiaoxinCard",5.9,"tiaoxin")
				break
			end
		end
	end

	targets = self:sortInPlace(targets, "defenseSlash")
	use.to:append(targets[1])
	use.card = bind_legacy(self,"tiaoxin","TiaoxinCard",{},request)
end

sgs.ai_skill_cardask["@tiaoxin-slash"] = function(self,data,pattern,target)
	if target then
		for _,slash in ipairs(self:getCards("Slash"))do
			if self:isFriend(target) and self:slashIsEffective(slash,target) then
				if self:needLeiji(target,self.player) then return slash end
				if self:needToLoseHp(target,self.player,nil,true) then return slash end
			end

			if not self:isFriend(target) and self:slashIsEffective(slash,target)
			and not self:needLeiji(target,self.player)
			then return slash end
		end
		for _,slash in ipairs(self:getCards("Slash"))do
			if not self:isFriend(target) then
				if not self:needLeiji(target,self.player) and not self:needToLoseHp(target,self.player,slash) then return slash end
				if not self:slashIsEffective(slash,target) then return slash end
			end
		end
	end
	return "."
end


sgs.ai_card_intention.TiaoxinCard = 80
sgs.ai_use_priority.TiaoxinCard = 4

ai_card_use.ZhijianCard = function(self, card, use, request)
	local equips = {}
	for _,card in ipairs(self.player:getHandcards())do
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
			local index = equip:getEquipSlot()
			if not friend:hasEquipArea(index) then continue end
			if not self:getSameEquip(equip,friend) and self:hasSkills(sgs.need_equip_skill.."|"..sgs.lose_equip_skill,friend) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
		for _,equip in ipairs(equips)do
			local index = equip:getEquipSlot()
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
	use.card = bind_legacy(self,"zhijian","ZhijianCard",{select_equip:getId()},request)
end

sgs.ai_card_intention.ZhijianCard = -80
sgs.ai_use_priority.ZhijianCard = (sgs.ai_use_priority.RendeCard or 8.8)+0.1  -- 刘备二张双将的话，优先直谏
sgs.ai_cardneed.zhijian = sgs.ai_cardneed.equip

ai_card_use.ZhibaCard = function(self, card, use, request)
	local lords = {}
	for _,player in ipairs(self.room:getOtherPlayers(self.player))do
		if player:hasLordSkill("zhiba") and self.player:canPindian(player) and not player:hasFlag("ZhibaInvoked")
			and not (self:isEnemy(player) and player:getMark("hunzi")>0) then
				table.insert(lords,player)
		end
	end
	if #lords==0 then return end
	lords = self:sortInPlace(lords, "defense")
	for _,lord in ipairs(lords)do
		local zhiba_str
		local cards = self.player:getHandcards()

		local max_num,max_card = 0,nil
		local min_num,min_card = 14,nil
		for _,hcard in ipairs(cards)do
			if hcard:getNumber()>max_num then
				max_num = hcard:getNumber()
				max_card = hcard
			end

			if hcard:getNumber()<=min_num then
				if hcard:getNumber()==min_num then
					if min_card and self:getKeepValue(hcard)>self:getKeepValue(min_card) then
						min_num = hcard:getNumber()
						min_card = hcard
					end
				else
					min_num = hcard:getNumber()
					min_card = hcard
				end
			end
		end

        local lord_max_num=0
        -- Source uses only maximum among cards visible to current. Its private
        -- unguarded minimum scan never affects a branch and is omitted.
        local visible=self:getKnownCards(lord,self.room:getCurrent(),"h")
        if not visible then
            self:useKnowledgeEstimate({status="estimate",value=true,basis="mountain.zhiba_other_current_visibility_uses_viewer_hand",target=lord:objectName()},"zhiba.visible_hand")
            visible=self:getKnownCards(lord,self.player,"h")
        end
        for _,lcard in ipairs(known(visible,"zhiba.visible_hand")) do
            if lcard:getNumber()>lord_max_num then lord_max_num=lcard:getNumber() end
        end

		if self:isEnemy(lord) and max_num>10 and max_num>lord_max_num then
			if isCard("Jink",max_card,self.player) and self:getCardsNum("Jink")==1 then return end
			if isCard("Peach",max_card,self.player) or isCard("Analeptic",max_card,self.player) then return end
			self.zhiba_pindian_card = max_card;self:remember("zhiba_pindian_card",max_card:getEffectiveId())
			zhiba_str = "@ZhibaCard=."
		end
		if self:isFriend(lord) and not skill(self,lord,"manjuan") and ((lord_max_num>0 and min_num<=lord_max_num) or min_num<7) then
			if isCard("Jink",min_card,self.player) and self:getCardsNum("Jink")==1 then return end
			self.zhiba_pindian_card = min_card;self:remember("zhiba_pindian_card",min_card:getEffectiveId())
			zhiba_str = "@ZhibaCard=."
		end

		if zhiba_str then
			use.card = bind_legacy(self,"zhiba_pindian","ZhibaCard",{},request)
			use.to:append(lord)
			return
		end
	end
end


sgs.ai_use_priority.ZhibaCard=0
sgs.ai_card_intention.ZhibaCard=0
sgs.ai_card_intention.zhiba_pindian=0
sgs.ai_card_intention.tiaoxin=sgs.ai_card_intention.TiaoxinCard
sgs.ai_card_intention.zhijian=sgs.ai_card_intention.ZhijianCard

local function disclosed_card(self,id)
    id=tonumber(id)
    for _,card in ipairs(self:getChoiceCards() or {}) do if card:getEffectiveId()==id then return card end end
    for _,row in ipairs(self.world.discard_pile or {}) do
        if (row.effective_id or row.id)==id then return CardView.new(row) end
    end
    for _,player in ipairs(self.room:getAllPlayers()) do
        for _,cards in ipairs({player:getKnownCards() or {},player:getEquips() or {},player:getJudgingArea() or {}}) do
            for _,card in ipairs(cards) do if card:getEffectiveId()==id then return card end end
        end
    end
    ai_unsupported("referenced Mountain card is not disclosed","mountain.card_identity")
end
sgs.ai_choicemade_filter.pindian=sgs.ai_choicemade_filter.pindian or {}
sgs.ai_choicemade_filter.pindian.zhiba_pindian = function(self,from,promptlist)
	local number = disclosed_card(self,tonumber(promptlist[4])):getNumber()
	local lord = self.room:findPlayerByObjectName(promptlist[5])
	if not lord then return end
	local lord_max_card = self:getMaxCard(lord)
	if lord_max_card and lord_max_card:getNumber()>=number then sgs.updateIntention(from,lord,-60)
	elseif lord_max_card and lord_max_card:getNumber()<number then sgs.updateIntention(from,lord,60)
	elseif number<6 then sgs.updateIntention(from,lord,-60)
	elseif number>8 then sgs.updateIntention(from,lord,60)
	end
end


-- Preserved old explicit-use API; fixed native Guzheng currently asks invoke/AG.
ai_skill_use["@@guzheng"] = function(self,data,request)
	local card_ids = known(self:getDecisionContext().guzheng_all_cards,"guzheng.legacy_offered_ids")
	local who = self.room:getCurrent()

	if self:isLihunTarget(self.player,#card_ids-1) then return "." end
	local invoke = (self:isFriend(who) and not (skill(self,who,"kongcheng") and who:isKongcheng()))
					or (#card_ids>=3 and not skill(self,self.player,"manjuan"))
					or (#card_ids==2 and not self:hasSkills(sgs.cardneed_skill,who) and not skill(self,self.player,"manjuan"))
					or (self:isEnemy(who) and skill(self,who,"kongcheng") and who:isKongcheng())
	if not invoke then return "." end

	local wulaotai = self.room:findPlayerBySkillName("buyi")
	local Need_buyi = wulaotai and who:getHp()==1 and self:isFriend(who,wulaotai)

	local cards,except_Equip,except_Key = {},{},{}
	for _,card_id in ipairs(card_ids)do
		local card = disclosed_card(self,card_id)
		if skill(self,self.player,"zhijian|mobilezhijianzhan") and not card:isKindOf("EquipCard") then
			table.insert(except_Equip,card)
		end
		if not card:isKindOf("Peach") and not card:isKindOf("Jink") and not card:isKindOf("Analeptic") and
			not card:isKindOf("Nullification") and not (card:isKindOf("EquipCard") and skill(self,self.player,"zhijian|mobilezhijianzhan")) then
			table.insert(except_Key,card)
		end
		table.insert(cards,card)
	end

	if self:isFriend(who) then

		if Need_buyi then
			local buyicard1,buyicard2
			cards = self:sortByKeepValue(cards)
			for _,card in ipairs(cards)do
				if card:isKindOf("TrickCard") and not buyicard1 then
					buyicard1 = card:getEffectiveId()
				end
				if not card:isKindOf("BasicCard") and not buyicard2 then
					buyicard2 = card:getEffectiveId()
				end
				if buyicard1 then break end
			end
			if buyicard1 then
				return action(self,"guzheng",{buyicard1},{},request)
			elseif buyicard2 then
				return action(self,"guzheng",{buyicard2},{},request)
			end
		end

		local peach_num,peach,jink,analeptic,slash = 0,nil,nil,nil,nil
		for _,card in ipairs(cards)do
			if card:isKindOf("Peach") then peach = card:getEffectiveId() peach_num = peach_num+1 end
			if card:isKindOf("Jink") then jink = card:getEffectiveId() end
			if card:isKindOf("Analeptic") then analeptic = card:getEffectiveId() end
			if card:isKindOf("Slash") then slash = card:getEffectiveId() end
		end
		if peach then
			if peach_num>1
				or (self:getCardsNum("Peach")>=self.player:getMaxCards())
				or (who:getHp()<getBestHp(who) and who:getHp()<self.player:getHp()) then
					return action(self,"guzheng",{peach},{},request)
			end
		end
		if self:isWeak(who) and (jink or analeptic) then
			if jink then
				return action(self,"guzheng",{jink},{},request)
			elseif analeptic then
				return action(self,"guzheng",{analeptic},{},request)
			end
		end

		for _,card in ipairs(cards)do
			if not card:isKindOf("EquipCard") then
				for _,askill in ipairs(who:getVisibleSkillList(true))do
					local callback = sgs.ai_cardneed[askill:objectName()]
					if type(callback)=="function" and callback(who,card,self) then
						return action(self,"guzheng",{card:getEffectiveId()},{},request)
					end
				end
			end
		end

		if jink or analeptic or slash then
			if jink then
				return action(self,"guzheng",{jink},{},request)
			elseif analeptic then
				return action(self,"guzheng",{analeptic},{},request)
			elseif slash then
				return action(self,"guzheng",{slash},{},request)
			end
		end

		for _,card in ipairs(cards)do
			if not card:isKindOf("EquipCard") and not card:isKindOf("Peach") then
				return action(self,"guzheng",{card:getEffectiveId()},{},request)
			end
		end

	else

		if Need_buyi then
			for _,card in ipairs(cards)do
				if card:isKindOf("Slash") then
					return action(self,"guzheng",{card:getEffectiveId()},{},request)
				end
			end
		end

		for _,card in ipairs(cards)do
			if card:isKindOf("EquipCard") and skill(self,self.player,"zhijian|mobilezhijianzhan") then
				local Cant_Zhijian = true
				for _,friend in ipairs(self.friends)do
					if not self:getSameEquip(card,friend) then
						Cant_Zhijian = false
					end
				end
				if Cant_Zhijian then
					return action(self,"guzheng",{card:getEffectiveId()},{},request)
				end
			end
		end

		local new_cards = (#except_Key>0 and except_Key) or (#except_Equip>0 and except_Equip) or cards

		new_cards = self:sortByKeepValue(new_cards)
		local valueless,slash
		for _,card in ipairs (new_cards)do
			if card:isKindOf("Lightning") and not self:hasSkills(sgs.wizard_harm_skill,who) then
				return action(self,"guzheng",{card:getEffectiveId()},{},request)
			end

			if card:isKindOf("Slash") then slash = card:getEffectiveId() end

			if not valueless and not card:isKindOf("Peach") then
				for _,askill in ipairs(who:getVisibleSkillList(true))do
					local callback = sgs.ai_cardneed[askill:objectName()]
					if (type(callback)=="function" and not callback(who,card,self)) or not callback then
						valueless = card:getEffectiveId()
						break
					end
				end
			end
		end

		if slash or valueless then
			if slash then
				return action(self,"guzheng",{slash},{},request)
			elseif valueless then
				return action(self,"guzheng",{valueless},{},request)
			end
		end

		return action(self,"guzheng",{new_cards[1]:getEffectiveId()},{},request)
	end
end


local function viable_zhiheng_costs(self)
    local ids=self:selectZhihengCosts()
    if #ids<1 then return nil end
    local hp=self.player:getHp()
    local own=self.player:getCards("he")
    for _,id in ipairs(ids) do
        local material
        for _,card in ipairs(own) do if card:getEffectiveId()==id then material=card;break end end
        material=known(material,"jilve.zhiheng_owner_cost")
        if material:isKindOf("Poison") or material:isKindOf("Shit") then hp=hp-1 end
    end
    if hp<1 and hp+self:getAllPeachNum()<1 then return nil end
    return ids
end
ai_fill_skill.jilve=function(self, options, request)
    local inclusive = options and options.inclusive

    if not(known(self.player:hasFlag("JilveWansha"),"jilve.wansha_flag") or skill(self,self.player,"wansha|olwansha")) then
        for _,enemy in ipairs(self.enemies) do
            if known(self.player:canSlash(enemy),"jilve.can_slash") and self:isWeak(enemy)
                and self:damageMinusHp(enemy,1)>0 and #self.enemies>1 then
                self:setPriorityValue("JilveCard",8,"jilve")
                -- Whether the engine registers olwansha (Sanguosha:getSkill) is not projected.
                ai_unsupported("engine skill registry is not projected","jilve.olwansha")
            end
        end
    end
    if not known(self.player:hasFlag("JilveZhiheng"),"jilve.zhiheng_flag") then
        self:setStrategyMemory("choice_override:jilve","tenyearzhiheng")
        -- Effective tenyear_st_standard-ai:9 delegates unchanged cost selection
        -- to Zhiheng and only renames its result; source priority aliases 2.61.
        self:setPriorityValue("JilveCard",sgs.ai_use_priority.TenyearZhihengCard or sgs.ai_use_priority.ZhihengCard or 2.61,"jilve")
        if viable_zhiheng_costs(self) then return self:legacySkillSeed("jilve","JilveCard",request) end
    end
end
ai_card_use.JilveCard=function(self, card, use, request)
    use.card=self:inheritLegacyCardIdentity(bind_legacy(self,"jilve","JilveCard",{},request),card)
end
ai_skill_choice.jilve=function(self, options, request) return ai_choice_result((self:getStrategyMemory("choice_override:jilve")), options) end
for _,name in ipairs({"zhiheng","tenyearzhiheng"}) do
    ai_skill_use["@@"..name]=function(self,prompt,request)
        local ids=viable_zhiheng_costs(self)
        if ids then return action(self,name,ids,{},request) end
        return "."
    end
end
-- newgenerals.lua defines the LuaSkillCard, but the fixed AI registry has no
-- #jiudingmouzhihengCard callback or useCard method. Source's empty dummy thus
-- declines; do not invent Zhiheng reuse for a merely similar skill name.
ai_skill_use["@@jiudingmouzhiheng"]=function() return "." end

ai_fill_skill.jixi=function(self, options, request)
    local inclusive = options and options.inclusive

    local field=known(self.player:getPile("field"),"jixi.owner_field")
    if self.player:getHandcardNum()>=self.player:getHp()+2
        and #field<=self.player:aliveCount()/2-1 then return end
    for _,id in ipairs(field) do
        local evaluation=self:evaluateSkillCard("jixi","snatch",{id})
        if known(evaluation:isAvailable(self.player),"jixi.source_availability") then
            local authority=self:bindSkillCard("jixi",{id},request)
            local row=known(rawget(evaluation,"_view"),"jixi.source_identity")
            return self:legacyPolicyCard(authority,{
                name=evaluation:objectName(),class_name=evaluation:getClassName(),type_id=2,
                kind_of=known(row.kind_of or row.kind_of_names,"jixi.source_classes"),
                subcards={id},suit=evaluation:getSuit(),number=evaluation:getNumber(),
                effective_id=id,red=evaluation:isRed(),black=evaluation:isBlack(),
                damage_card=evaluation:isDamageCard(),can_recast=evaluation:canRecast(),
                handling_method=evaluation:getHandlingMethod(),will_throw=evaluation:willThrow(),
                legacy_string_key=evaluation:getLegacyStringKey(),legacy_sort_key=evaluation:getLegacySortKey()
            },evaluation)
        end
    end
end
sgs.ai_view_as.jixi=function(card,player,place)
    if place==sgs.Player_PlaceSpecial and player:getPileName(card:getEffectiveId())=="field" then
        return proposal("jixi","snatch",{card})
    end
end

-- Modern ActiveSkillCard events identify these same source actions by their
-- activation skill; the numeric intentions remain the donor class callbacks.
sgs.ai_card_intention.tiaoxin=sgs.ai_card_intention.TiaoxinCard
sgs.ai_card_intention.zhiba_pindian=sgs.ai_card_intention.ZhibaCard
sgs.ai_card_intention.zhijian=sgs.ai_card_intention.ZhijianCard

-- Package-owned value hooks; original callback arguments remain unchanged.
;(function()
    local function policy_1(self, player, preferred, query, context)
        local name = "zhiji"
        if query(player, "hasSkill", name) and query(player, "getMark", name) < 1 then return true, true end
        return preferred
    end
    local function policy_2(self, player, preferred, query, context)
        local name = "zhiji"
        if query(player, "getMark", name) < 1 and query(player, "hasSkill", name) then return true, true end
        return preferred
    end
    local function policy_3(self, owner, max_hp, query, context)
        if query(owner, "hasSkill", "longhun") then
            local hand = type(owner.getHandcardNum) == "function" and owner:getHandcardNum() or nil
            if type(hand) ~= "number" then hand = nil end
            local equips = owner:getEquips()
            if hand == nil or equips == nil then return nil, true end
            if hand + #equips > 2 then return 1, true end
        end
        return max_hp
    end
    local function policy_4(self, owner, max_hp, query, context)
        if query(owner, "hasSkill", "hunzi") and query(owner, "getMark", "hunzi") < 1 then return 2, true end
        return max_hp
    end
    local function policy_5(self, owner, max_hp, query, context)
        if query(owner,"hasSkills","renjie+baiyin") and query(owner,"getMark","baiyin") < 1 then return max_hp - 1, true end
        return max_hp
    end
    local function policy_6(self, player, m, query, context)
        if query(player, "hasSkill", "qiaobian") then m = math.max(query(self.player, "getHandcardNum") - 1, m) end
        return m
    end
    local previous_1 = sgs.ai_need_kongcheng["zhiji"]
    sgs.ai_need_kongcheng["zhiji"] = function(self, player, keep, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "keep" and context.rule == "zhiji" then
                return policy_1(self, player, context.value, context.query, context)
            end
            if context.phase == "after_loss" and context.rule == "zhiji" then
                return policy_2(self, player, context.value, context.query, context)
            end
            return context.value
        end
        if type(previous_1) == "function" then return previous_1(self, player, keep) end
    end
    sgs.declareValueHookStages("ai_need_kongcheng", "zhiji", {
        {phase="keep", rule="zhiji", order=600},
        {phase="after_loss", rule="zhiji", order=1000},
    })
    local previous_2 = sgs.ai_getBestHp_skill["longhun"]
    sgs.ai_getBestHp_skill["longhun"] = function(owner, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "base" and context.rule == "low_hp_conversion" then
                return policy_3(context.self, owner, context.value, context.query, context)
            end
            return context.value
        end
        if type(previous_2) == "function" then return previous_2(owner) end
    end
    sgs.declareValueHookStages("ai_getBestHp_skill", "longhun", {
        {phase="base", rule="low_hp_conversion", order=2300},
    })
    local previous_3 = sgs.ai_getBestHp_skill["hunzi"]
    sgs.ai_getBestHp_skill["hunzi"] = function(owner, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "base" and context.rule == "low_hp_awakening" then
                return policy_4(context.self, owner, context.value, context.query, context)
            end
            return context.value
        end
        if type(previous_3) == "function" then return previous_3(owner) end
    end
    sgs.declareValueHookStages("ai_getBestHp_skill", "hunzi", {
        {phase="base", rule="low_hp_awakening", order=2400},
    })
    local previous_4 = sgs.ai_getBestHp_skill["renjie"]
    sgs.ai_getBestHp_skill["renjie"] = function(owner, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "base" and context.rule == "renjie" then
                return policy_5(context.self, owner, context.value, context.query, context)
            end
            return context.value
        end
        if type(previous_4) == "function" then return previous_4(owner) end
    end
    sgs.declareValueHookStages("ai_getBestHp_skill", "renjie", {
        {phase="base", rule="renjie", order=2600},
    })
    local previous_5 = sgs.ai_getOverflow_skill["qiaobian"]
    sgs.ai_getOverflow_skill["qiaobian"] = function(self, player, m, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "before_max" and context.rule == "qiaobian" then
                return policy_6(self, player, context.value, context.query, context)
            end
            return context.value
        end
        if type(previous_5) == "function" then return previous_5(self, player, m) end
    end
    sgs.declareValueHookStages("ai_getOverflow_skill", "qiaobian", {
        {phase="before_max", rule="qiaobian", order=2700},
    })
end)()

-- Package-owned survival, damage-target and Slash-defense stages.
do
(function()
    local previous = sgs.ai_skill_defense["longhun"]
    local policy = function(self, to, context)
        local value, query = context.value, context.query
        local hp, core_query = context.extra[1], context.extra[2]
        if query(to, "getCardCount") > 2 and query(to, "hasSkills", "longhun|newlonghun") then return false, true end
        return value
    end
    sgs.ai_skill_defense["longhun"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "weakness_early" and context.rule == "longhun" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
        return previous
    end
    sgs.declareValueHookStages("ai_skill_defense", "longhun", {
        {phase="weakness_early", order=2, rule="longhun"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_skill_defense["weakness_hp.hunzi_mobilehunzi"]
    local policy = function(self, to, context)
        local value, query = context.value, context.query
        local hp, core_query = context.extra[1], context.extra[2]
        if core_query(to,"getStrategyMark","hunzi") < 1 and hp > 1 and query(to, "hasSkill", "hunzi")
                or core_query(to,"getStrategyMark","mobilehunzi") < 1 and hp > 2 and query(to, "hasSkill", "mobilehunzi") then return false, true end
        return value
    end
    sgs.ai_skill_defense["weakness_hp.hunzi_mobilehunzi"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "weakness_hp" and context.rule == "hunzi_mobilehunzi" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
        return previous
    end
    sgs.declareValueHookStages("ai_skill_defense", "weakness_hp.hunzi_mobilehunzi", {
        {phase="weakness_hp", order=1, rule="hunzi_mobilehunzi"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_skill_defense["duanchang"]
    local policy = function(self, to, context)
        local value, core_query = context.value, context.query
        local from, damageNum, role = context.extra[1], context.extra[2], context.extra[3]
        if core_query(to,"hasSkill","duanchang") and not core_query(to,"isLord")
        	and #core_query(self,"getFriends",to,true)>0 and core_query(to,"getHp")<=1 then
        		if not (core_query(from,"getMaxHp")==3 and from:getArmor() and from:getDefensiveHorse()) then
        			if core_query(from,"getMaxHp")<=3 or core_query(from,"isLord") and core_query(self,"isWeak",from) then return true, true end
        			if core_query(from,"getMaxHp")<=3 or self.room:getLord() and role(self,from)=="renegade" then return true, true end
        		end
        	end
        return value
    end
    sgs.ai_skill_defense["duanchang"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "retaliation" and context.rule == "duanchang" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
        return previous
    end
    sgs.declareValueHookStages("ai_skill_defense", "duanchang", {
        {phase="retaliation", order=2, rule="duanchang"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["hunzi"]
    local policy = function(self, to, context)
        local value, good_query = context.value, context.query
        local card, damageNum, apn, value_known = context.extra[1], context.extra[2], context.extra[3], context.extra[4]
        if good_query(to, "getMark", "hunzi")<1 and good_query(to, "isLord") and good_query(to, "getHp")>=2 and math.abs(damageNum)==1
        	and value_known(good_query(self,"getRoleCounts").loyalist,"loyalist count")>0 and good_query(to, "hasSkill", "hunzi") then return nil, true end
        return value
    end
    sgs.ai_target_damage["hunzi"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "good_before_negative" and context.rule == "hunzi" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "hunzi", {
        {phase="good_before_negative", order=1, rule="hunzi"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_target_damage["duanchang"]
    local policy = function(self, to, context)
        local value, good_query = context.value, context.query
        local card, damageNum, apn, value_known = context.extra[1], context.extra[2], context.extra[3], context.extra[4]
        if good_query(to, "getHp")<=damageNum and good_query(self.player, "getMaxHp")<6
        	and not good_query(to, "isLord") and #good_query(self, "getFriends", to,true)>0 and good_query(to, "hasSkill", "duanchang") then
        		if not(good_query(self.player, "getMaxHp")>=3 and self.player:getArmor() and self.player:getDefensiveHorse()) then
        			if good_query(self.player, "isLord") and good_query(self, "isWeak") or self.room:getLord() and good_query(self.player, "getRole")=="renegade"
        			then return nil, true end
        		end
        	end
        return value
    end
    sgs.ai_target_damage["duanchang"] = function(self, to, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "good_retaliation" and context.rule == "duanchang" then
                return policy(self, to, context)
            end
            if type(previous) == "function" then return previous(self, to, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to) end
    end
    sgs.declareValueHookStages("ai_target_damage", "duanchang", {
        {phase="good_retaliation", order=3, rule="duanchang"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_defense_slash["guzheng"]
    local policy = function(self, to, observer, context)
        local call, state = context.query, context.extra[1]
        local defense = context.value
        if not state.diagram then
            if state.knownJink < 1 and call(to, "hasSkill", "guzheng") then defense = defense - 2.5 end
        end
        return defense
    end
    sgs.ai_defense_slash["guzheng"] = function(self, to, observer, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "base" and context.rule == "slash_defense.base_guzheng" then
                return policy(self, to, observer, context)
            end
            if type(previous) == "function" then return previous(self, to, observer, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to, observer) end
    end
    sgs.declareValueHookStages("ai_defense_slash", "guzheng", {
        {phase="base", order=42, rule="slash_defense.base_guzheng"},
    })
end)()
end
do
(function()
    local previous = sgs.ai_defense_slash["qiaobian"]
    local policy = function(self, to, observer, context)
        local call, state = context.query, context.extra[1]
        local defense = context.value
        if not state.diagram then
            if call(to, "hasSkill", "qiaobian") then defense = defense - 2.4 end
        end
        return defense
    end
    sgs.ai_defense_slash["qiaobian"] = function(self, to, observer, context)
        if sgs.isValueHookContext(context) then
            if context.phase == "base" and context.rule == "slash_defense.base_qiaobian" then
                return policy(self, to, observer, context)
            end
            if type(previous) == "function" then return previous(self, to, observer, context) end
            return context.value
        end
        if type(previous) == "function" then return previous(self, to, observer) end
    end
    sgs.declareValueHookStages("ai_defense_slash", "qiaobian", {
        {phase="base", order=43, rule="slash_defense.base_qiaobian"},
    })
end)()
end
