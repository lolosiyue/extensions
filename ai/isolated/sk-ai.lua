-- sk fixed b6025acc. Preserve source policy quirks and ordered material selection.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported('sk input unknown',k)end;return v end
local nullable={toPlayer=true,getLord=true,getCurrent=true,getArmor=true,getWeapon=true,getMaxCard=true,getSameEquip=true,findPlayerBySkillName=true,findPlayerByObjectName=true,AssistTarget=true,useBasicCard=true,updatePlayers=true,updateIntention=true,setStrategyCardFlag=true,writeToConsole=true}
local function q(o,k,...)
 if not o or type(o[k])~='function'then ai_unsupported('sk helper unavailable',k)end
 local method=k;if k=='getMark'and AIValue.isPlayer(o)then method='getStrategyMark'end
 local r=table.pack(o[method](o,...));if AIUnsupported.is(r[1])then error(r[1],0)end
 if k=='sort'or k=='sortByKeepValue'or k=='sortByUseValue'then local t=(...);known(r[1],k);for i,v in ipairs(r[1])do t[i]=v end;return t end
 if k=='hasSkill'or k=='hasSkills'then local p=AIValue.isPlayer(o)and o or select(2,...)or o.player;local row=type(p)=='table'and rawget(p,'_view');if r[1]==false and row and row.skills_complete~=true then ai_unsupported('sk foreign skill absence unknown',(...))end end
 if not nullable[k]then known(r[1],k)end;return table.unpack(r,1,r.n)
end
local function own_ai(p)local a=p._room and p._room._ai;if not a or p~=a.player then ai_unsupported('sk view-as material is not owner-authorized','sk.view_as')end;return a end
local function face(self,id)return q(self,'getKnownCardById',id)end
local function seed(self,wire)
 local cls,raw,user=wire:match('^#(sk_[%w_]+):([^:]*):(.*)$')
 local skill=cls and cls:gsub('Card$','');if not skill then ai_unsupported('invalid sk source selector',wire)end
 local ids={};if raw~='.'and raw~=''then for id in raw:gmatch('[^+]+')do ids[#ids+1]=known(tonumber(id),'source cost')end end
 if #ids==0 and user==''then return q(self,'legacySkillSeed',skill,'#'..cls,self.request)end
 return q(self,'evaluateTurnSkillCard',skill,'#'..cls,ids,self.request,user~=''and user or nil)
end
local function response(self,skill,cls,ids,targets)
 local card=q(self,'bindSkillCard',skill,ids,self.request,nil,cls)
 return{kind='use_card',card_spec=q(card,'toCardSpec'),targets=targets or{}}
end
local function evaluation(self,name)return q(self,'getEvaluationCard',name or'slash')end
local function declared(self,skill,card,name)
 local value=q(self,'evaluateSkillCard',skill,name,{})
 if q(value,'getSuit')~=q(card,'getSuit')or q(value,'getNumber')~=q(card,'getNumber')then ai_unsupported('sk declared clone does not preserve prototype face',skill)end
 return value
end
local function hand_count(p)return q(p,'getHandcardNum')+#q(p,'getEquips')end
local function reason(player)
 local self=own_ai(player);return known(self.request and self.request.reason,'response reason')
end
local function card_answer(c)
 if AIValue.isCard(c)or AIValue.isConversion(c)then return c end
 ai_unsupported('selected response is not a pure card','sk.response')
end


sgs.ai_skill_invoke.sk_leiji = true

sgs.ai_skill_playerchosen.sk_leiji = function(self, targets)
    local lightning_targets = {}
	for _, e in ipairs(self.enemies) do
	    if not q(e,"hasSkill","hongyan|wuyan") and q(e,"getArmor") ~= "SilverLion" then
		    table.insert(lightning_targets, e)
		end
	end
	return lightning_targets[math.random(1, #lightning_targets)]
end

sgs.ai_skill_invoke.sk_quanlue = true

sgs.ai_skill_invoke.sk_fushe = function(self, data)
    local current = q(self.room,"getCurrent")
	return q(self,"isEnemy",current)
end
sgs.ai_choicemade_filter.skillInvoke.sk_fushe = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local current = q(self.room,"getCurrent")
		q(self,"updateIntention",player, current, 50)
	end
end

sgs.ai_skill_choice["sk_baozheng"] = function(self, choices, data)
    local dongzhuo = q(self.room,"findPlayerBySkillName","sk_baozheng")
	if q(self,"isEnemy",dongzhuo) then
	    return "discardtwocards"
	end
	return "giveonecard"
end

sgs.ai_fill_skill.sk_ziguo=function(self,inclusive,request)
    if q(self.player,"hasUsed","#sk_ziguoCard") then return nil end
	return seed(self,"#sk_ziguoCard:.:")
end

sgs.ai_skill_use_func["#sk_ziguoCard"] = function(card, use, self)
    local targets = {}
	for _, player in ipairs(self.friends) do
	    if q(player,"isWounded") then
		    table.insert(targets, player)
		end
	end
	if #targets == 0 then return nil end
	q(self,"sort",targets, "hp")
	use.card = card
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_value["sk_ziguoCard"] = 100
sgs.ai_use_priority["sk_ziguoCard"] = 7
sgs.ai_card_intention["sk_ziguoCard"] = -90

sgs.ai_fill_skill.sk_yishe=function(self,inclusive,request)
    if q(self.player,"hasUsed","#sk_yisheCard") then return nil end
	if q(self,"getOverflow") <= 0 then return nil end
	return seed(self,"#sk_yisheCard:.:")
end

sgs.ai_skill_use_func["#sk_yisheCard"] = function(card, use, self)
    local targets = {}
	for _, player in ipairs(self.friends_noself) do
	    if q(player,"getHandcardNum") < q(self.player,"getHandcardNum") then
		    table.insert(targets, player)
		end
	end
	if #targets == 0 then return nil end
	q(self,"sort",targets, "hp")
	use.card = card
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_value["sk_yisheCard"] = 100
sgs.ai_use_priority["sk_yisheCard"] = 2
sgs.ai_card_intention["sk_yisheCard"] = -90

sgs.ai_fill_skill.sk_midao=function(self,inclusive,request)
    if q(self.player,"hasUsed","#sk_midaoCard") then return nil end
	return seed(self,"#sk_midaoCard:.:")
end

sgs.ai_skill_use_func["#sk_midaoCard"] = function(card, use, self)
	local friend, enemy = 0,0
	for _, player in ipairs(self.friends_noself) do
	    if q(player,"getHandcardNum") > q(self.player,"getHandcardNum") then
			friend = friend + 1
		end
	end
	for _, player in ipairs(self.enemies) do
	    if q(player,"getHandcardNum") > q(self.player,"getHandcardNum") then
			enemy = enemy + 1
		end
	end
	if enemy < friend then return nil end
	use.card = card
end

sgs.ai_use_value["sk_midaoCard"] = 100
sgs.ai_use_priority["sk_midaoCard"] = 4
sgs.ai_card_intention["sk_midaoCard"] = -90

sgs.ai_fill_skill.sk_pudu=function(self,inclusive,request)
    if q(self.player,"hasUsed","#sk_puduCard") then return nil end
	return seed(self,"#sk_puduCard:.:")
end

sgs.ai_skill_use_func["#sk_puduCard"] = function(card, use, self)
    local targets = {}
	local friend, enemy = 0,0
	for _, player in ipairs(self.friends_noself) do
	    if q(player,"getHandcardNum") > 0 then
		    table.insert(targets, player)
			friend = friend + q(player,"getHandcardNum")
		end
	end
	for _, player in ipairs(self.enemies) do
	    if q(player,"getHandcardNum") > 0 then
		    table.insert(targets, player)
			enemy = enemy + q(player,"getHandcardNum")
		end
	end
	if enemy < friend then return nil end
	q(self,"sort",targets, "hp")
	use.card = card
end

sgs.ai_use_value["sk_puduCard"] = 100
sgs.ai_use_priority["sk_puduCard"] = 5
sgs.ai_card_intention["sk_puduCard"] = -90

sgs.ai_skill_cardchosen.sk_pudu = function(self, who,flags,reason,method)
	local list = q(self.room,"getAlivePlayers")
	local target
	for _, player in sgs.qlist(list) do
		if q(player,"hasFlag","sk_pudu_target") then
			target = player
            break
		end
	end

	local usable_cards = sgs.QList2Table(q(self.player,"getCards","he"))
	q(self,"sortByKeepValue",usable_cards)
	
	if target then 
		if q(self,"isFriend",target) then
			usable_cards = sgs.reverse(usable_cards)
			return usable_cards[1]:getEffectiveId()
		else
			return usable_cards[1]:getEffectiveId()
		end
	end
    return usable_cards[1]:getEffectiveId()
end

sgs.ai_skill_invoke.sk_zhaoxin = function(self, data)
    local suits = {"spade", "heart", "club", "diamond"}
	for _, c in sgs.qlist(q(self.player,"getHandcards")) do
		if table.contains(suits, q(c,"getSuitString")) then
		    table.removeOne(suits, q(c,"getSuitString"))
		end
	end
	return #suits > 0
end

sgs.ai_fill_skill.sk_zhihe=function(self,inclusive,request)
    if q(self.player,"isKongcheng") then return nil end
	local suits = {}
	for _, c in sgs.qlist(q(self.player,"getHandcards")) do
		if not table.contains(suits, q(c,"getSuitString")) then
		    table.insert(suits, q(c,"getSuitString"))
		end
	end
	local S = #suits
	if q(self.player,"getHandcardNum") > 2*S then return nil end
	if q(self.player,"hasUsed","#sk_zhiheCard") then return nil end
	return seed(self,"#sk_zhiheCard:.:")
end

sgs.ai_skill_use_func["#sk_zhiheCard"] = function(card, use, self)
    use.card = card
end

sgs.ai_use_value["sk_zhiheCard"] = 100
sgs.ai_use_priority["sk_zhiheCard"] = 4.5

sgs.ai_fill_skill.sk_baoli=function(self,inclusive,request)
    if #self.enemies == 0 then return nil end
	if q(self.player,"hasUsed","#sk_baoliCard") then return nil end
	return seed(self,"#sk_baoliCard:.:")
end

sgs.ai_skill_use_func["#sk_baoliCard"] = function(card, use, self)
    local target
	local targets = {}
	for _, p in ipairs(self.enemies) do
	    if (q(p,"getEquips"):isEmpty() or (not q(p,"getJudgingArea"):isEmpty())) and q(self,"damageIsEffective",p, sgs.DamageStruct_Normal) and not q(self,"cantbeHurt",p) and q(self,"canDamage",p,self.player,nil)  then
		    table.insert(targets, p)
		end
	end
	if #targets > 0 then
	    q(self,"sort",targets, "hp")
		use.card = card
		target = targets[1]
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_value["sk_baoliCard"] = 100
sgs.ai_use_priority["sk_baoliCard"] = 5
sgs.ai_card_intention["sk_baoliCard"] = 95

sgs.ai_skill_invoke.sk_yexi = function(self, data)
    if q(self.player,"isKongcheng") then return false end
    local targets = q(self.room,"getOtherPlayers",self.player)
	local s = 0
	local k = 0
	for _, t in sgs.qlist(targets) do
	    if q(self,"isFriend",t) then
		    if q(self.player,"getRole") == "renegade" then k = k + 1 end
		    if q(self,"getRoleEstimate",t)=="renegade" then k = k + 1 end
		    for _, enemy in ipairs(self.enemies) do
			    if q(self,"isWeak",enemy) and q(enemy,"getHp") == 1 and not q(self,"slashProhibit",nil, enemy, t)
				    and (getCardsNum("Jink", enemy, self.player) == 0)
				    and (getCardsNum("Slash", t, self.player) >= 1 or q(self,"getCardsNum","Slash") > 0) then
				    s = s + 1
			    end
			end
		end
		if not q(self.player,"isWounded") and q(self,"isWeak",t) then s = s + 1 end
	end
	return s > 0
end

sgs.ai_skill_playerchosen.sk_yexi = function(self, targets)
    local target
	local tos = {}
	local players = sgs.QList2Table(targets)
	for _, p in ipairs(players) do
	    if q(self,"isFriend",p) then
		    local k = 0
		    for _, enemy in ipairs(self.enemies) do
			    if q(self,"isWeak",enemy) and q(enemy,"getHp") == 1 and not q(self,"slashProhibit",nil, enemy, p)
				    and (not sgs.isJinkAvailable(p, enemy) or getCardsNum("Jink", enemy, self.player) == 0)
				    and (getCardsNum("Slash", p, self.player) >= 1 or q(self,"getCardsNum","Slash") > 0) then
				    k = k + 1
			    end
			end
			if k > 0 then table.insert(tos, p) end
		end
	end
	for _, p in ipairs(players) do
	    if q(self,"isFriend",p) then
		   if (getCardsNum("Slash", p, self.player) >= 1 or q(self,"getCardsNum","Slash") > 0)   then
		   table.insert(tos, p) end
		end
	end
	q(self,"sort",tos, "defense")
	targets = tos[1]
	return target
end
sgs.ai_use_revises["&sk_yexi"] = function(self,card,use)
	if q(card,"isBlack") and q(card,"isKindOf","Slash") and q(self.player,"hasFlag","yexi_blackslash_buff") then
		q(self,"setStrategyCardFlag",card,"Qinggang",true)
	end
end
sgs.ai_playerchosen_intention.sk_yexi = -40

sgs.ai_fill_skill.sk_huaqiang=function(self,inclusive,request)
    if q(self.player,"hasUsed","#sk_huaqiangCard") then return nil end
	if #self.enemies == 0 then return nil end
	if q(self.player,"isKongcheng") then return nil end
	return seed(self,"#sk_huaqiangCard:.:")
end

sgs.ai_skill_use_func["#sk_huaqiangCard"] = function(card, use, self)
    if #self.enemies == 0 then return nil end
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	q(self,"sortByKeepValue",cards)
	q(self,"sort",self.enemies, "hp")
	local huaqiang_need = {}
	for _, c in ipairs(cards) do
	    if #huaqiang_need == 0 then
		    table.insert(huaqiang_need, q(c,"getEffectiveId"))
		else
		    local can_do = true
			for _, p in ipairs(huaqiang_need) do
			    if q(c,"getSuit") == face(self,p):getSuit() then
				    can_do = false
					break
				end
			end
			if can_do then
			    table.insert(huaqiang_need, q(c,"getEffectiveId"))
			end
		end
		if #huaqiang_need == math.max(1, q(self.player,"getHp")) then break end
	end
	if #huaqiang_need == math.max(1, q(self.player,"getHp")) then
	    use.card = seed(self,"#sk_huaqiangCard:" .. table.concat(huaqiang_need, "+") .. ":")
		if use.to then use.to:append(self.enemies[1]) end
	end
end

sgs.ai_use_value["sk_huaqiangCard"] = 80
sgs.ai_use_priority["sk_huaqiangCard"] = 3.5
sgs.ai_card_intention["sk_huaqiangCard"] = 95

sgs.ai_fill_skill.sk_chaohuang=function(self,inclusive,request)
    local slash = evaluation(self,"slash")
    if q(self.player,"isJilei",slash, true) then return nil end
    if #self.enemies == 0 then return nil end
    if q(self,"isWeak") then return nil end
    if q(self.player,"getHp") <= 1 and q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") == 0 then return nil end
	if q(self.player,"hasUsed","#sk_chaohuangCard") then return nil end
    return seed(self,"#sk_chaohuangCard:.:")
end

sgs.ai_skill_use_func["#sk_chaohuangCard"] = function(card, use, self)
    if #self.enemies <= 0 then return nil end
	local E = 0
	for _, enemy in ipairs(self.enemies) do
		if q(self.player,"inMyAttackRange",enemy) then E = E + 1 end
	end
	if E == 0 then return nil end
	q(self,"sort",self.enemies, "defense")
	use.card = card
	local slash = evaluation(self,"slash")
	
	if use.to then
		if q(self.player,"getHp") > 1 or (q(self.player,"getHp") == 1 and q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") > 1) then
			for _, enemy in ipairs(self.enemies) do
				if q(self.player,"canSlash",enemy, slash, true) and q(self,"slashIsEffective",slash, enemy) and q(self,"objectiveLevel",enemy) > 3 and q(self,"isGoodTarget",enemy, self.enemies, slash) then use.to:append(enemy) end
			end
			assert(use.to:length() > 0)
		end
	end
end

sgs.ai_use_value["sk_chaohuangCard"] = 100
sgs.ai_use_priority["sk_chaohuangCard"] = sgs.ai_use_priority.Slash + 2
sgs.ai_card_intention["sk_chaohuangCard"] = 95

sgs.ai_skill_invoke.sk_sijian = function(self, data)
    return q(self,"findPlayerToDiscard")[1]
end

sgs.ai_skill_playerchosen.sk_sijian = function(self, targets)
    local enemies = {}
	local target
	for _, t in sgs.qlist(targets) do
	    if q(self,"isEnemy",t) then table.insert(enemies, t) end
	end
	if #enemies > 0 then
	    q(self,"sort",enemies, "defense")
		target = enemies[1]
	end
	return target
end
sgs.need_kongcheng = sgs.need_kongcheng .. "|sk_sijian"
sgs.ai_playerchosen_intention["sk_sijian"] = 50

sgs.ai_skill_invoke.sk_gangzhi = function(self, data)
    if q(self.player,"isKongcheng") then
	    return true
	else
	    if q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") > 0 then return false else return true end
	end
	return false
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|sk_gangzhi"

sgs.ai_skill_invoke.sk_zhongyong = function(self, data)
	if q(self,"isWeak",self.player) then return false end
	if q(self,"willSkipPlayPhase",self.player) then return false end
	for _,card in sgs.qlist(q(self.player,"getHandcards")) do
		if q(card,"isKindOf","Peach") or q(card,"isKindOf","Analeptic") then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen["sk_zhongyong"] = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if q(self,"isFriend",p) and q(self,"canDraw",p, self.player) then
			table.insert(friends,p)
		end
	end
	if #friends == 0 then return nil end
	q(self,"sort",friends,"defense")
	return friends[1]
end

sgs.ai_playerchosen_intention["sk_zhongyong"] = -50

sgs.ai_skill_invoke.sk_xiongyi = function(self, data)
    if q(self.player,"hasSkill","zhiji") and q(self.player,"isKongcheng") and q(self.player,"getMark","@waked") == 0 then return false end  --没手牌，有【志继】就不要发动
	if q(self.player,"hasSkill","hunzi") and q(self.player,"getHp") == 1 and q(self.player,"getMark","@waked") == 0 then return false end  --体力为1，是孙笨，也别发动
	return true
end

sgs.ai_fill_skill.sk_chaochen=function(self,inclusive,request)
    if q(self.player,"isKongcheng") then return nil end
	if q(self,"isWeak") then return nil end
	if #self.enemies == 0 then return nil end
	if q(self.player,"hasUsed","#sk_chaochenCard") then return nil end
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	q(self,"sortByKeepValue",cards)
	if (not cards[1]:isKindOf("Peach")) and (not cards[1]:isKindOf("Analeptic")) then
	    return seed(self,"#sk_chaochenCard:"..cards[1]:getEffectiveId()..":")
	else
	    return nil
	end
end

sgs.ai_skill_use_func["#sk_chaochenCard"] = function(card, use, self)
    local target
	for _, enemy in ipairs(self.enemies) do
	    if q(self,"isWeak",enemy) and q(self,"objectiveLevel",enemy) >= 3 and q(enemy,"getHandcardNum") > q(enemy,"getHp") then
		    target = enemy
			break
		end
	end
	if not target then
	    for _, enemy in ipairs(self.enemies) do
		    if q(self,"willSkipPlayPhase",enemy) and q(enemy,"getHandcardNum") > q(enemy,"getHp") then
			    target = enemy
				break
			end
		end
	end
	if not target then
	    for _, enemy in ipairs(self.enemies) do
		    if q(self,"isWeak",enemy) and q(enemy,"getHandcardNum") > q(enemy,"getHp") and q(enemy,"getHp") <= 1 and q(enemy,"hasSkills","wansha|tongtian_wansha") then
			    target = enemy
				break
			end
		end
	end
	if not target then
	    for _, enemy in ipairs(self.enemies) do
		    if q(enemy,"getHandcardNum") > q(enemy,"getHp") and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Normal) and not q(self,"cantbeHurt",enemy) then
			    target = enemy
				break
			end
		end
	end
	if target then
	    if use.to then use.to:append(target) end
		use.card = card
	end
end


sgs.ai_use_value["sk_chaochenCard"] = 70
sgs.ai_use_priority["sk_chaochenCard"] = 3
sgs.ai_card_intention["sk_chaochenCard"] = 80

sgs.ai_skill_invoke.sk_quanzheng = function(self, data)
    return not q(self,"needKongcheng",self.player, true)
end

local function card_for_qiaobian(self, who, return_prompt)
	local card, target
	if q(self,"isFriend",who) then
		local judges = q(who,"getJudgingArea")
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = face(self,q(judge,"getEffectiveId"))
				if not q(judge,"isKindOf","YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not q(enemy,"containsTrick",q(judge,"objectName")) and not q(enemy,"containsTrick","YanxiaoCard")
							and not q(self.room,"isProhibited",self.player, enemy, judge) then
							target = enemy
							break
						end
					end
					if target then break end
				end
			end
		end

		local equips = q(who,"getCards","e")
		local weak
		if not target and not equips:isEmpty() and q(self,"hasSkills",sgs.lose_equip_skill, who) then
			for _, equip in sgs.qlist(equips) do
				if q(equip,"isKindOf","OffensiveHorse") then card = equip break
				elseif q(equip,"isKindOf","Weapon") then card = equip break
				elseif q(equip,"isKindOf","DefensiveHorse") and not q(self,"isWeak",who) then
					card = equip
					break
				elseif q(equip,"isKindOf","Armor") and (not q(self,"isWeak",who) or q(self,"needToThrowArmor",who)) then
					card = equip
					break
				end
			end

			if card then
				if q(card,"isKindOf","Armor") or q(card,"isKindOf","DefensiveHorse") then 
					q(self,"sort",self.friends, "defense")
				else
					q(self,"sort",self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not q(self,"getSameEquip",card, friend) and q(friend,"objectName") ~= q(who,"objectName") 
						and q(self,"hasSkills",sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
							target = friend
							break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not q(self,"getSameEquip",card, friend) and q(friend,"objectName") ~= q(who,"objectName") then
						target = friend
						break
					end
				end
			end
		end
	else
		local judges = q(who,"getJudgingArea")
		if q(who,"containsTrick","YanxiaoCard") then
			for _, judge in sgs.qlist(judges) do
				if q(judge,"isKindOf","YanxiaoCard") then
					card = face(self,q(judge,"getEffectiveId"))
					for _, friend in ipairs(self.friends) do
						if not q(friend,"containsTrick",q(judge,"objectName")) and 
						not q(self.room,"isProhibited",self.player, friend, judge) 
							and not q(friend,"getJudgingArea"):isEmpty() then
							target = friend
							break
						end
					end
					if target then break end
					for _, friend in ipairs(self.friends) do
						if not q(friend,"containsTrick",q(judge,"objectName")) and 
						not q(self.room,"isProhibited",self.player, friend, judge) then
							target = friend
							break
						end
					end
					if target then break end
				end
			end
		end
		if card==nil or target==nil then
			if not q(who,"hasEquip") or q(self,"hasSkills",sgs.lose_equip_skill, who) then return nil end
			local card_id = q(self,"askForCardChosen",who, "e", "snatch")
			if card_id >= 0 and q(who,"hasEquip",face(self,card_id)) then 
				card = face(self,card_id) end

			if card then
				if q(card,"isKindOf","Armor") or q(card,"isKindOf","DefensiveHorse") then 
					q(self,"sort",self.friends, "defense")
				else
					q(self,"sort",self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not q(self,"getSameEquip",card, friend) and q(friend,"objectName") ~= q(who,"objectName") and 
					q(self,"hasSkills",sgs.lose_equip_skill .. "|shensu" , friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not q(self,"getSameEquip",card, friend) and q(friend,"objectName") ~= q(who,"objectName") then
						target = friend
						break
					end
				end
			end			
		end
	end

	if return_prompt == "card" then return card
	elseif return_prompt == "target" then return target
	else
		return (card and target)
	end
end

sgs.ai_skill_invoke.sk_yaoming = function(self, data)
    local others = q(self.room,"getOtherPlayers",self.player)
	local players = q(self.room,"getAlivePlayers")
	if q(self.player,"getMark","yaoming") == 1 then return true
	elseif q(self.player,"getMark","yaoming") == 2 then
	    local targets = {}
		for _, _player in sgs.qlist(others) do
		    if q(self,"isEnemy",_player) and (not q(_player,"isNude")) then table.insert(targets, _player) end
		end
		if #targets > 0 then return true end
		return false
	elseif q(self.player,"getMark","yaoming") == 3 then
	    local qiaobian_targets = {}
		for _, target in sgs.qlist(others) do
		    if q(self,"isFriend",target) then
			    if not q(target,"getCards","j"):isEmpty() and not q(target,"containsTrick","YanxiaoCard") and  card_for_qiaobian(self, target, ".") then
				    table.insert(qiaobian_targets, target)
				end
				if not q(target,"getCards","e"):isEmpty() and q(self,"hasSkills",sgs.lose_equip_skill, target) and card_for_qiaobian(self, target, ".") then
				    table.insert(qiaobian_targets, target)
				end
			elseif q(self,"isEnemy",target) then
			    if not q(target,"getCards","j"):isEmpty() and q(target,"containsTrick","YanxiaoCard") and card_for_qiaobian(self, target, ".") then
				    table.insert(qiaobian_targets, target)
				end
				if card_for_qiaobian(self, target, ".") then table.insert(qiaobian_targets, target) end
			end
		end
		if #qiaobian_targets <= 0 then return false else return true end
	elseif q(self.player,"getMark","yaoming") == 4 then
	    local enemies = {}
		for _, t in sgs.qlist(others) do
		    if q(self,"isEnemy",t) then table.insert(enemies, t) end
		end
		return #enemies > 0
	end
end

sgs.ai_skill_playerchosen["yaoming_first"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not q(self,"isFriend",p) then
			table.insert(enemies,p)
		end
	end
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if q(self,"isFriend",p) then
			table.insert(friends,p)
		end
	end
	q(self,"sort",enemies, "defense")
	for _, friend in ipairs(friends) do
		if not q(friend,"getCards","j"):isEmpty() and not q(friend,"containsTrick","YanxiaoCard") and 
		card_for_qiaobian(self, friend, ".") then			
			return friend
		end
	end
	
	for _, enemy in ipairs(enemies) do
		if not q(enemy,"getCards","j"):isEmpty() and q(enemy,"containsTrick","YanxiaoCard") and 
			card_for_qiaobian(self, enemy, ".") then

			return enemy
		end
	end

	for _, friend in ipairs(friends) do
		if not q(friend,"getCards","e"):isEmpty() and q(self,"hasSkills",sgs.lose_equip_skill, friend) and 
		card_for_qiaobian(self, friend, ".") then
			return friend
		end
	end

	local targets = {}
	for _, enemy in ipairs(enemies) do
		if card_for_qiaobian(self, enemy, ".") then
			table.insert(targets, enemy)
		end
	end
	
	if #targets > 0 then
		q(self,"sort",targets, "defense")

		return targets[#targets]
	end
end

sgs.ai_skill_playerchosen["yaoming_second"] = function(self, targets)
	local context=q(self,"getDecisionContext")
	if context.sk_yaoming_known~=true then ai_unsupported("sk current public target unknown","yaomingTarget")end
	local name=context.sk_yaoming_target
	local who = name and known(self.room:findPlayerByObjectName(name,true),"yaomingTarget")
	if who then
		if not card_for_qiaobian(self, who, "target") then q(self.room,"writeToConsole","NULL") end
		return card_for_qiaobian(self, who, "target")
	end
end


sgs.ai_skill_playerchosen["yaoming_damage"] = function(self, targets)
	local players = {}
	for _, t in sgs.qlist(targets) do
	    if q(self,"isEnemy",t) then table.insert(players, t) end
	end
	if #players > 0 then
	    q(self,"sort",players, "hp")
		return players[1]
	end
end

sgs.ai_skill_playerchosen.sk_yaoming = function(self, targets)
	return q(self,"findPlayerToDiscard")[1]
end
sgs.ai_playerchosen_intention["sk_yaoming"] = 50

sgs.ai_skill_invoke.sk_diezhang = true

sgs.ai_card_priority.sk_diezhang = function(self,card,v)
	-- Own tag; QVariant::toInt reads absent as 0.
	if (tonumber(self.player:getTag("diezhang_point")) or 0)<q(card,"getNumber")
	then return 10 end
end

sgs.ai_fill_skill.sk_pengri=function(self,inclusive,request)
	if q(self.player,"hasUsed","#sk_pengriCard") then return nil end
	return seed(self,"#sk_pengriCard:.:")
end













sgs.ai_skill_use_func["#sk_pengriCard"] = function(card, use, self)
    local others = q(self.room,"getOtherPlayers",self.player)
	local distance = use.DefHorse and 1 or 0
	local canslash_count = 0
	local enemy_slash = 0
	local enemy_slashfrom = 0
	for _, t in sgs.qlist(others) do
	    if q(t,"canSlash",self.player, nil, true) then
		    canslash_count = canslash_count + 1
		end
		if q(self,"isEnemy",t) and q(t,"canSlash",self.player, nil, true) then
		    enemy_slash = enemy_slash + 1
		end
		if q(self,"isEnemy",t) and q(t,"distanceTo",self.player, distance) <= q(t,"getAttackRange") then
		    enemy_slashfrom = enemy_slashfrom + 1
		end
	end
	if canslash_count == 0 then  --没有人能砍得到你的话，直接捧日就行了，白摸两张牌何乐而不为？
	    use.card = card
	else
	    if enemy_slash == 0 then  --能砍得到你的都是队友的话，那也可以白摸两张牌
		    use.card = card
		else
		    if q(self,"getCardsNum","Jink") >= enemy_slashfrom then
			    use.card = card
			end
		end
	end
	if math.random(1, 100) >= 40 then use.card = card end  --老子就是喜欢浪，你来砍我啊
end


sgs.ai_use_value["sk_pengriCard"] = 80
sgs.ai_use_priority["sk_pengriCard"] = 7

sgs.ai_skill_cardask["@pengri-slash"] = function(self, data, pattern, target)
	if target then
		for _, slash in ipairs(q(self,"getCards","Slash")) do
			if q(self,"isFriend",target) then
				return "."
			end
			if not q(self,"isFriend",target) and q(self,"slashIsEffective",slash, target)
				 and not q(self,"needLeiji",target, self.player) then
					return card_answer(slash)
			end
		end
		for _, slash in ipairs(q(self,"getCards","Slash")) do
			if not q(self,"isFriend",target) then
				if not q(self,"needLeiji",target, self.player) then return card_answer(slash) end
				if not q(self,"slashIsEffective",slash, target) then return card_answer(slash) end
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.sk_danmou = function(self, data)
    local damage = q(data,"toDamage")
	if q(damage.from,"getHandcardNum") < q(self.player,"getHandcardNum") then return false end
	if q(self,"isFriend",damage.from) then return false end
	if q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") > 0 then return false end
	if q(damage.from,"isKongcheng") then return false end
	return q(damage.from,"getHandcardNum") >= q(self.player,"getHandcardNum")
end

sgs.ai_can_damagehp.sk_danmou = function(self,from,card,to)
	if from and q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	and q(self,"canLoseHp",from,card,to)
	then
		return q(self,"isEnemy",from) and (q(from,"getHandcardNum") - q(self.player,"getHandcardNum") > 2)
	end
end

sgs.ai_fill_skill.sk_gongshen=function(self,inclusive,request)
	if q(self.player,"getCards","he"):length() < 3 then return nil end
	return seed(self,"#sk_gongshenCard:.:")
end


sgs.ai_skill_use_func["#sk_gongshenCard"] = function(card, use, self)
    local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	q(self,"sortByKeepValue",cards)
	local gongshen = {}
	for _, c in ipairs(cards) do
	    table.insert(gongshen, q(c,"getEffectiveId"))
		if #gongshen == 3 then break end
	end
	if #gongshen < 3 then return nil end
	use.card = seed(self,"#sk_gongshenCard:" .. table.concat(gongshen, "+") .. ":")
end


sgs.ai_use_value["sk_gongshenCard"] = 6.5
sgs.ai_use_priority["sk_gongshenCard"] = sgs.ai_use_priority.Peach - 1

sgs.ai_skill_invoke.sk_jianyue = function(self, data)
    local current = q(self.room,"getCurrent")
	return q(self,"isFriend",current)
end
sgs.ai_choicemade_filter.skillInvoke.sk_jianyue = function(self, player, promptlist)
	local current = q(self.room,"getCurrent")
	if promptlist[#promptlist] == "yes" and current and q(current,"isAlive") then
		q(self,"updateIntention",player, current, -50)
	end
end

sgs.ai_skill_use["@@sk_suiji"] = function(self, prompt)
    local current = q(self.room,"getCurrent")
	if q(current,"getHandcardNum") <= q(current,"getHp") then return "." end
	if q(self.player,"isKongcheng") then return "." end
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	q(self,"sortByKeepValue",cards)
	if q(current,"getHandcardNum") >= q(current,"getHp") + 1 then
	    return response(self,"sk_suiji","#sk_suijiCard",{cards[1]:getEffectiveId()},{"."})
	end
end

sgs.ai_skill_invoke.sk_fengyi = true

sgs.ai_skill_invoke.sk_bibu = function(self, data)
    if q(self.player,"getHandcardNum") <= math.max(1, q(self.player,"getHp")) then return true end
	local current = q(self.room,"getCurrent")
	if q(self.player,"getHandcardNum") > math.max(1, q(self.player,"getHp")) and q(self,"isFriend",current) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.sk_bibu = function(self, player, promptlist)
	local current = q(self.room,"getCurrent")
	if promptlist[#promptlist] == "yes" and current and q(current,"isAlive") then
		q(self,"updateIntention",player, current, -50)
	end
end

function canKuangzhengFriend(target)
    if q(target,"isChained") then return true end
	if q(target,"isAlive") and not q(target,"faceUp") then return true end
	if q(target,"getMark","@duanchang") > 0 then return true end
	return false
end

sgs.ai_skill_invoke.sk_kuangzheng = function(self, data)
    local x = 0
	for _, t in sgs.qlist(q(self.room,"getAlivePlayers")) do
	    if q(self,"isFriend",t) and canKuangzhengFriend(t) then x = x + 1 end
	end
	return x > 0
end

sgs.ai_skill_playerchosen.sk_kuangzheng = function(self, targets)
    local kuangzheng = {}
	for _, t in sgs.qlist(targets) do
	    if q(self,"isFriend",t) and canKuangzhengFriend(t) then table.insert(kuangzheng, t) end
	end
	if #kuangzheng > 0 then
	    return kuangzheng[math.random(1, #kuangzheng)]
	end
	return
end
sgs.ai_playerchosen_intention["sk_kuangzheng"] = -50

sgs.ai_fill_skill.sk_shejian=function(self,inclusive,request)
    if q(self.player,"getArmor") ~= nil then return nil end
	if q(self.player,"isNude") then return nil end
	if q(self,"isWeak") then return nil end
	return seed(self,"#sk_shejianCard:.:")
end


sgs.ai_skill_use_func["#sk_shejianCard"] = function(card, use, self)
    local target
	if #self.enemies > 0 then
	    for _, enemy in ipairs(self.enemies) do
		    if q(self,"isTiaoxinTarget",enemy) and not q(enemy,"hasFlag","shejian_used") and not q(enemy,"isNude") then
			    target = enemy
				break
			end
		end
		if not target then
		    for _, enemy in ipairs(self.enemies) do
		        if not q(enemy,"canSlash",self.player, false) and not q(enemy,"hasFlag","shejian_used") and not q(enemy,"isNude") then
			        target = enemy
				    break
			    end
		    end
		end
		if not target then
		    for _, enemy in ipairs(self.enemies) do
		        if q(self,"objectiveLevel",enemy) > 3 and not q(enemy,"hasFlag","shejian_used") and q(enemy,"getHandcardNum") >= 2*q(self.player,"getHandcardNum") + 1 then
			        target = enemy
				    break
			    end
		    end
		end
	end
	if not target and #self.friends_noself > 0 then
	    local max_x = 0
	    local AssistTarget = q(self,"AssistTarget")
		for _, friend in ipairs(self.friends_noself) do
		    if not q(friend,"hasFlag","shejian_used") and not q(friend,"isNude")then
			    local x = math.min(q(friend,"getMaxHp"), 5) - q(friend,"getHandcardNum")
		        if q(friend,"hasSkill","manjuan") then x = x + 1 end
		        if AssistTarget and q(friend,"objectName") == q(AssistTarget,"objectName") then x = x + 0.5 end
		        if x > max_x and q(friend,"isAlive") then
		            max_x = x
				    target = friend
				end
	        end
	    end
	end
	if target then
	    use.card = card
		if use.to then use.to:append(target) end
	end
end


sgs.ai_use_value["sy_shejianCard"] = 75
sgs.ai_use_priority["sy_shejianCard"] = 5.2


sgs.ai_skill_choice.sk_shejian = function(self, choices, data)
    local miheng = q(self.room,"findPlayerBySkillName","sk_shejian")
	if q(self,"isFriend",miheng) then return "useslashtomiheng" end
	if q(self,"isEnemy",miheng) then
	    if q(self.player,"getHandcardNum") >= 2*q(miheng,"getHandcardNum") then
		    if q(self,"objectiveLevel",miheng) > 3 then return "useslashtomiheng" else return "cancel" end
		end
	end
	if not q(self,"isFriend",miheng) then return "useslashtomiheng" end
	return "useslashtomiheng"
end

sgs.ai_skill_invoke.sk_kuangao = function(self, data)
	local slasher = q(data,"toPlayer")
    if q(self,"isFriend",slasher) then return true end
	if q(self,"isEnemy",slasher) then
		if q(self.player,"isNude") then return false end
	    if q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") <= 0 and hand_count(slasher) >= 2*q(self.player,"getCards","he"):length() then return true end
		if hand_count(slasher) >= 2.5*q(self.player,"getCards","he"):length() then return true end
	end
	return false
end

sgs.ai_skill_choice.sk_kuangao = function(self, choices, data)
    local slasher = q(data,"toPlayer")
	if slasher and q(self,"isFriend",slasher) then return "kuangao_draw" end
	if slasher and q(self,"isEnemy",slasher) then return "kuangao_discard" end
end

sgs.ai_choicemade_filter.skillChoice["sk_kuangao"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local target
	local list = q(self.room,"getAlivePlayers")
	for _, p in sgs.qlist(list) do
		if q(p,"hasFlag","kuangao_target") then
			target = p
		end
	end
	if choice == "kuangao_draw" and target then
		q(self,"updateIntention",player, target, -80)
	end
	if choice == "kuangao_discard" and target then
		q(self,"updateIntention",player, target, 80)
	end
end

sgs.ai_skill_invoke.sk_fenwei = function(self, data)
    local damage = q(data,"toDamage")
	local nature = damage.nature
	if not q(damage.to,"getArmor") ~= "SilverLion" and q(self,"isEnemy",damage.to) and q(self,"damageIsEffective",damage.to, nature) then
	    return true
	end
	return false
end
-- audited alias ai_cardneed.sk_fenwei
sgs.bad_skills = sgs.bad_skills .. "|sk_shiyong"


sgs.ai_skill_cardask["@cangshu-give"] = function(self, data, pattern, target, target2)
	local handcards = sgs.QList2Table(q(self.player,"getCards","h"))
	if q(self,"isFriend",target) then return "." end
		local use = q(data,"toCardUse")
		if use.card and q(use.card,"isVirtualCard") then return "." end
	q(self,"sortByKeepValue",handcards)
	local give_cards = {}
	for _, c in ipairs(handcards) do
		if q(c,"isKindOf","BasicCard") then
			table.insert(give_cards, c)
			break
		end
	end
	if #give_cards > 0 then
		return card_answer(give_cards[1])
	end
	return "."
end

sgs.ai_guhuo_card.sk_kanwu = function(self,toname,class_name)
    local cards = q(self.player,"getCards","he")
    cards = q(self,"sortByKeepValue",cards) -- 按保留值排序
   	for d,c in sgs.list(cards)do
       	d = evaluation(self,toname)
        if q(c,"getTypeId")~=1
       	and q(d,"isKindOf","BasicCard") and q(self,"getCardsNum",class_name)<1
		and (reason(self.player)==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE or reason(self.player)== sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
      	then return {skill="sk_kanwu",legacy_class="#sk_kanwu",subcards={q(c,"getEffectiveId")},user_string=toname} end
   	end
end

function CountSuit(zumao, suit)
	local cards = q(zumao,"getHandcards");if #cards~=q(zumao,"getHandcardNum")then ai_unsupported("CountSuit requires complete lawful hand","sk.CountSuit")end
	local x = 0
	for _, c in sgs.qlist(cards) do
		if q(c,"getSuit") == suit then
			x = x + 1
		end
	end
	return x
end

function SmartAIView:getYinbingValue(zumao)
	local n = 0
	if q(zumao,"isNude") then return 0 end
	if not q(zumao,"isWounded") then return 0 end
	if q(zumao,"hasSkill","manjuan") and q(zumao,"getPhase") == sgs.Player_NotActive then return -1 end
	n = n + math.max(q(zumao,"getHandcardNum")-1, 0) + q(zumao,"getLostHp")
	if q(zumao,"hasSkill","jiuchi") then
		if CountSuit(zumao, sgs.Card_Spade) > 1 then
			n = n + math.max(q(zumao,"getHandcardNum")-1, 0) + q(zumao,"getLostHp")
		end
	end
	if q(zumao,"hasSkill","jijiu") and q(zumao,"getPhase") == sgs.Player_NotActive then
		if CountSuit(zumao, sgs.Card_Heart) + CountSuit(zumao, sgs.Card_Diamond) > 1 then
			n = n + math.max(q(zumao,"getHandcardNum")-1, 0) + q(zumao,"getLostHp")
		end
	end
	if q(zumao,"hasSkill","jiushi") and q(zumao,"faceUp") then
		n = n + math.max(q(zumao,"getHandcardNum")-1, 0) + q(zumao,"getLostHp")
	end
	if q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") > 1 then
		n = n + math.max(q(zumao,"getHandcardNum")-1, 0) + q(zumao,"getLostHp")
	end
	if q(zumao,"hasSkill","chunlao") and q(zumao,"getPile","wine"):length() > 0 then
		n = n + math.max(q(zumao,"getHandcardNum")-1, 0) + q(zumao,"getLostHp")
	end
	if q(zumao,"hasSkills","longhun|sgkgodlonghun") and CountSuit(zumao, sgs.Card_Heart) > 1 then
		n = n + math.max(q(zumao,"getHandcardNum")-1, 0) + q(zumao,"getLostHp")
	end
	return n
end

sgs.ai_skill_invoke.sk_yinbing = function(self, data)
	local t = q(data,"toPlayer")
	if q(self.player,"inMyAttackRange",t) and (not q(t,"getEquips"):isEmpty()) and (not q(self,"isEnemy",t)) then
		if q(self,"getYinbingValue",self.player) >= 2 then return true else return false end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.sk_yinbing = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = q(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then q(self,"updateIntention",player,target,-50) end
	end
end
sgs.ai_skill_invoke.sk_yinbing_draw = true

sgs.ai_skill_invoke.sk_hengshi = true

sgs.ai_skill_playerchosen.sk_zhijiao = function(self, targets)
	local room = self.room
	if q(self.player,"getMark","@zhijiao") == 0 then return nil end
	local target
	if #self.friends_noself == 0 then return nil end
	local tag = q(self.player,"getMark","zhijiao_count")
	local n = tag
	if n >= 8 then
		for _, p in sgs.qlist(targets) do
			if q(self,"isFriend",p) then
				if q(p,"hasSkills","shuangxiong|sgkgodshayi|paoxiao|fuhun|huoji|yeyan|sgkgodyeyan|sgkgodtongtian|sk_quanlue|sgkgodwushen|longhun|sgkgodlonghun|sgkgodjilue") and not q(p,"hasSkill","manjuan") then
					target = p
					break
				end
			end
		end
		if not target then
			for _, p in sgs.qlist(targets) do
				if q(self,"isWeak",p) and q(p,"getJudgingArea"):isEmpty() and q(self,"isFriend",p) then
					target = p
					break
				end
			end
		end
		if not target then
			for _, p in sgs.qlist(targets) do
				if q(self,"hasCrossbowEffect",p) and q(self,"isFriend",p) then
					target = p
					break
				end
			end
		end
		if not target then
			for _, p in sgs.qlist(targets) do
				if q(self,"isFriend",p) then
					target = p
					break
				end
			end
		end
	end
	if target then
		return target
	else
		return nil
	end
end

sgs.ai_skill_invoke.sk_daoshi = function(self, data)
	local zhoucang = q(data,"toPlayer")
	return q(self,"isFriend",zhoucang)
end

sgs.ai_skill_invoke.sk_kuangfu = function(self, data)
	local to = q(data,"toPlayer")
	return q(self,"isEnemy",to)
end
-- audited alias ai_cardneed.sk_kuangfu
sgs.ai_skill_playerchosen.sk_hubu = function(self, targets)
	local room = self.room
    local duel = evaluation(self,"duel")
	
	if q(self.player,"hasSkill","wuyan") and not q(self.player,"hasSkill","jueqing") then return end
	if q(self.player,"hasSkill","noswuyan") then return end
	local enemies = q(self,"exclude",self.enemies, duel)
	local friends = q(self,"exclude",self.friends_noself, duel)
	q(self,"setStrategyCardFlag",duel,"AI_Using",true)
	local n1 = q(self,"getCardsNum","Slash")
	q(self,"setStrategyCardFlag",duel,"AI_Using",false)
	if q(self.player,"hasSkill","wushuang") then
		n1 = n1 * 2
	end
	local targets = {}
	local canUseDuelTo = function(target)
		return q(self,"hasTrickEffective",duel, target) and q(self,"damageIsEffective",target,sgs.DamageStruct_Normal) and not q(self.room,"isProhibited",self.player, target, duel)

		and not (q(target,"hasSkill","guixin") and q(target,"getHp") > 1 and known(self.world.turn_count,"turn_count") <= 1 and not q(self.player,"hasSkill","jueqing"))
	end
	for _, enemy in ipairs(enemies) do
		if canUseDuelTo(enemy) then
			table.insert(targets, enemy)
		end
	end
	local cmp = function(a, b)
		local v1 = getCardsNum("Slash", a) + q(a,"getHp")
		local v2 = getCardsNum("Slash", b) + q(b,"getHp")

		if q(a,"isKongcheng") then v1 = v1 - 20 end
		if q(b,"isKongcheng") then v2 = v2 - 20 end

		if not q(self,"isWeak",a) and q(a,"hasSkill","jianxiong") and not q(self.player,"hasSkill","jueqing") then v1 = v1 + 10 end
		if not q(self,"isWeak",b) and q(b,"hasSkill","jianxiong") and not q(self.player,"hasSkill","jueqing") then v2 = v2 + 10 end

		if q(self,"needToLoseHp",a) then v1 = v1 + 5 end
		if q(self,"needToLoseHp",b) then v2 = v2 + 5 end

		if q(self,"hasSkills",sgs.masochism_skill, a) then v1 = v1 + 5 end
		if q(self,"hasSkills",sgs.masochism_skill, b) then v2 = v2 + 5 end

		if not q(self,"isWeak",a) and q(a,"hasSkill","jiang") then v1 = v1 + 5 end
		if not q(self,"isWeak",b) and q(b,"hasSkill","jiang") then v2 = v2 + 5 end

		if q(a,"hasLordSkill","jijiang") then v1 = v1 + q(self,"JijiangSlash",a) * 2 end
		if q(b,"hasLordSkill","jijiang") then v2 = v2 + q(self,"JijiangSlash",b) * 2 end

		if v1 == v2 then return q(self,"getDefenseSlash",a) < q(self,"getDefenseSlash",b) end

		return v1 < v2
	end
	table.sort(enemies, cmp)
	for _, enemy in ipairs(enemies) do
		local useduel
		local n2 = getCardsNum("Slash", enemy)
		if q(enemy,"hasSkill","wushuang") then n2 = n2 * 2 end
		useduel = n1 >= n2 or q(self,"needToLoseHp",self.player, nil, nil, true)  or (n2 < 1 and sgs.isGoodHp(self.player))
		if q(self,"objectiveLevel",enemy) >= 3 and canUseDuelTo(enemy) and not q(self,"cantbeHurt",enemy) and useduel and q(self,"isGoodTarget",enemy, enemies, nil) then
			if not table.contains(targets, enemy) then table.insert(targets, enemy) end
		end
	end
	for _, enemy in ipairs(enemies) do
		if q(self.player,"getHandcardNum") >= 1.5 * q(enemy,"getHandcardNum") or q(enemy,"isKongcheng") then
			if canUseDuelTo(enemy) and not table.contains(targets, enemy) then table.insert(targets, enemy) end
		end
	end
	if #targets > 0 then
		return targets[1]
	else
	    return nil
	end
end

sgs.ai_fill_skill.sk_huilian=function(self,inclusive,request)
	if not q(self.player,"hasUsed","#sk_huilian") then
		return seed(self,"#sk_huilian:.:")
	end
end

sgs.ai_skill_use_func["#sk_huilian"] = function(card, use, self)
	q(self,"updatePlayers")
	q(self,"sort",self.friends_noself, "hp")
	self.friends = sgs.reverse(self.friends_noself)
	local target = nil
	for _, friend in ipairs(self.friends_noself) do
		if q(friend,"isWounded") or q(friend,"getHp") <= 3 then
			target = friend
		end
	end
	if target == nil then return end
	use.card = card
	if use.to then use.to:append(target) end
end


sgs.ai_use_priority["sk_huilian"] = 7.2
sgs.ai_use_value["sk_huilian"] = 7.2
sgs.ai_card_intention["sk_huilian"] = -50

sgs.ai_fill_skill.sk_lirang=function(self,inclusive,request)
	local gift = q(self.player,"getPile","gift")
	local giftids = {}
	for _, id in sgs.qlist(gift) do
		local card = face(self,id)
		table.insert(giftids, q(card,"getEffectiveId"))
		if #giftids == 2 then break end
	end
	if #giftids < 2 or (not q(self.player,"isWounded")) then return nil end
	local lirang_peach = seed(self,"#sk_lirang:" .. table.concat(giftids, "+") .. ":" .. "peach")
	return lirang_peach
end

sgs.ai_skill_use_func["#sk_lirang"] = function(card, use, self)
	local userstring = q(card,"getLegacyStringKey")
	userstring = (userstring:split(":"))[4]
	local lirang_peach = declared(self,"sk_lirang",card,userstring)
	q(self,"useBasicCard",lirang_peach, use)
	if not use.card then return end
	use.card = card
end

sgs.ai_view_as["sk_lirang"] = function(card, player, card_place)
	local gift = q(player,"getPile","gift")
	local giftids = {}
	for _, id in sgs.qlist(gift) do
		local card = face(own_ai(player),id)
		table.insert(giftids, q(card,"getEffectiveId"))
		if #giftids == 2 then break end
	end
	if #giftids >= 2 then return {name="peach",skill="sk_lirang",suit=sgs.Card_NoSuit,number=0,subcards={giftids[1],giftids[2]}} end
end

sgs.ai_skill_cardask["@lirang_to"] = function(self, data, pattern)
	local kongrong = q(data,"toPlayer")
	if not q(self,"isFriend",kongrong) then return "." end
	local cards = q(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	q(self,"sortByKeepValue",cards)
	for _,h in sgs.list(cards)do
		if q(self,"matchesDiscardPattern",pattern,h)
		then return q(h,"getEffectiveId") end
		if q(h,"isKindOf",pattern)
		then return q(h,"getEffectiveId") end
	end
	return "."
end
sgs.ai_choicemade_filter.cardResponded["@lirang_to"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
	local dest
	for _, aplayer in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(aplayer,"hasFlag","lirang_Target") then dest = aplayer break end
	end
	if dest then 
		q(self,"updateIntention",player, dest, -40)
		end
	end
end

sgs.ai_skill_invoke.sk_xianshi = function(self, data)
	local damage = q(data,"toDamage")
	if damage.from and q(self,"isFriend",damage.from) and q(self,"isWeak") then return true end
	if not q(self,"needToLoseHp",damage.from, self.player) then return true end
	return true
end

sgs.ai_skill_cardask["@xianshi-discard"] = function(self, data, pattern)
	local damage = q(data,"toDamage")
	if q(self,"isFriend",damage.to) then
		return "."
	else
		local cards = sgs.QList2Table(q(self.player,"getCards","h"))
		q(self,"sortByKeepValue",cards)
		local acard
		for _, c in ipairs(cards) do
			if not q(c,"isKindOf","Peach") then
				acard = c
				break
			end
		end
		if acard then
			return "$" .. q(acard,"getEffectiveId")
		else
			return "."
		end
	end
end

sgs.ai_skill_playerchosen.sk_yijian = function(self, targets)
	if q(self.player,"isWounded") then
		local who = {}
		for _, friend in ipairs(self.friends_noself) do
			if q(friend,"getHandcardNum") + 1 >= q(self.player,"getHandcardNum") then table.insert(who, friend) end
		end
		if #who > 0 then
			q(self,"sort",who, "hp")
			who = sgs.reverse(who)
			return who[1]
		else
			return nil
		end
	else
		return nil
	end
end
sgs.ai_playerchosen_intention.sk_yijian = -20
sgs.double_slash_skill = sgs.double_slash_skill .. "|sk_feijun"
-- audited alias ai_cardneed.sk_feijun
sgs.ai_skill_cardask["@yanliang_card"] = function(self, data, pattern, target, target2)
	if q(self.player,"isNude") then return "." end
	if q(self,"isWeak",self.player) then return "." end
	local room = q(self.player,"getRoom")
	local player = q(data,"toPlayer")
	if not player or q(player,"isDead") then return false end
	if q(player,"containsTrick","supply_shortage") then return "." end
	local black,red = {},{}
	for _,c in sgs.qlist(q(self.player,"getCards","he")) do
		if q(c,"isRed") then
			table.insert(red,c)
		elseif q(c,"isBlack") then
			table.insert(black,c)
		end
	end
	if q(self,"isFriend",player) then
		if #black == 0 then return "." end
		q(self,"sortByKeepValue",black)
		if q(player,"getHandcardNum") - q(player,"getHp") >= 2 then
			return card_answer(black[1])
		end
		return "."
	else
		if #red == 0 then return "." end
		if q(player,"getHp")< 2 or q(player,"getHandcardNum")<= 1 then
			return card_answer(red[1])
		end
	end
	return "."
end
sgs.ai_choicemade_filter.cardResponded["@yanliang_card"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = q(self.room,"getCurrent")
		if not current then return end
		q(self,"updateIntention",player, current, 80)
	end
end

sgs.ai_skill_invoke.sk_caijie = function(self, data)
	local player = q(data,"toPlayer")
	local max_card = q(self,"getMaxCard")
	if max_card then
		local max_point = q(max_card,"getNumber")
		if max_point >= 10 and q(self,"isFriend",player) then return true end
		if q(self,"getCardsNum","Analeptic") + q(self,"getCardsNum","Peach") >= 2 and q(self,"isEnemy",player) and q(player,"getHandcardNum") >= 1.5*q(self.player,"getHandcardNum") then
			return true
		end
		if max_point >= 12 and q(self,"isEnemy",player) then
			return true
		end
		if max_point == 13 then return true end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.sk_caijie = function(self, player, promptlist)
	local current = q(self.room,"getCurrent")
	if promptlist[#promptlist] == "yes" then
		if current then
			q(self,"updateIntention",player, current, 40)
		end
	end
end
-- audited alias ai_cardneed.sk_caijie
sgs.ai_skill_invoke.sk_jilei = function(self, data)
	local who = q(data,"toPlayer")
	return q(self,"isEnemy",who)
end
sgs.ai_choicemade_filter.skillInvoke.sk_jilei = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = q(self.room,"findPlayerByObjectName",promptlist[#promptlist-1])
		if target then q(self,"updateIntention",player,target,50) end
	end
end

function can_zhengyi_inturn(player)
	if q(player,"getPhase") ~= sgs.Player_NotActive then
		return q(player,"getHandcardNum") - (math.max(0, q(player,"getHp"))) == 1 or (q(player,"getHandcardNum") == math.max(0, q(player,"getHp")) and q(player,"getEquips"):length() > 0)
	end
end

function can_zhengyi_outturn(player)
	if q(player,"getPhase") == sgs.Player_NotActive then
		return math.max(0, q(player,"getHp")) - q(player,"getHandcardNum") == 1
	end
end

sgs.ai_fill_skill.sk_zhengyi=function(self,inclusive,request)
	q(self,"updatePlayers")
	if can_zhengyi_inturn(self.player) then
		if q(self.player,"isWounded") then
			return seed(self,"#sk_zhengyi:.:" .. "peach")
		end
		local slash = evaluation(self,"slash")
		
		if q(self,"getCardsNum","Slash") > 1 and not q(slash,"isAvailable",self.player) then
			for _, enemy in ipairs(self.enemies) do
				if ((q(enemy,"getHp") < 3 and q(enemy,"getHandcardNum") < 3) or (q(enemy,"getHandcardNum") < 2)) and q(self.player,"canSlash",enemy) and not q(self,"slashProhibit",slash, enemy, self.player)
					and q(self,"slashIsEffective",slash, enemy, self.player) and q(self,"isGoodTarget",enemy, self.enemies, nil) then
					return seed(self,"#sk_zhengyi:.:" .. "analeptic")
				end
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if q(self.player,"canSlash",enemy) and q(self,"isGoodTarget",enemy, self.enemies, nil) then
				local thunder_slash = evaluation(self,"thunder_slash")
				
				local fire_slash = evaluation(self,"fire_slash")
				
				if  not q(self,"slashProhibit",fire_slash, enemy, self.player)and q(self,"slashIsEffective",fire_slash, enemy, self.player) then
					return seed(self,"#sk_zhengyi:.:" .. "fire_slash")
				end
				if not q(self,"slashProhibit",thunder_slash, enemy, self.player)and q(self,"slashIsEffective",thunder_slash, enemy, self.player) then
					return seed(self,"#sk_zhengyi:.:" .. "thunder_slash")
				end
				if not q(self,"slashProhibit",slash, enemy, self.player)and q(self,"slashIsEffective",slash, enemy, self.player) then
					return seed(self,"#sk_zhengyi:.:" .. "slash")
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#sk_zhengyi"] = function(card, use, self)
	local userstring = q(card,"getLegacyStringKey")
	userstring = (userstring:split(":"))[4]
	local zhengyi_card = declared(self,"sk_zhengyi",card,userstring)
	q(self,"useBasicCard",zhengyi_card, use)
	if not use.card then return end
	use.card = card
end


sgs.ai_use_priority["sk_zhengyi"] = 8
sgs.ai_use_value["sk_zhengyi"] = 8


sgs.ai_view_as["sk_zhengyi"] = function(card, player, card_place, class_name)
	if reason(player) == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and can_zhengyi_outturn(player) then
		local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["Peach"] = "peach", ["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash"
		}
		local name = classname2objectname[class_name]
		if not name then return end
		return {name=name,skill="sk_zhengyi",suit=sgs.Card_NoSuit,number=0,subcards={}}
	end
end

-- audited alias ai_cardneed.sk_jiwu
sgs.ai_skill_use["@@sk_jiwu"] = function(self, prompt)
	for _, c in ipairs(sgs.QList2Table(q(self.player,"getCards","h"))) do
		if q(c,"isKindOf","Slash") then
			return response(self,"sk_jiwu","#sk_jiwu",{q(c,"getEffectiveId")})
		end
	end
		
	return "."
end
sgs.ai_ajustdamage_from.sk_jiwu = function(self, from, to, card, nature)
	if card and q(card,"isKindOf","Slash") and q(card,"hasFlag","llq_jiwu_damage")
	then
		return 1
	end
end

sgs.ai_skill_invoke.sk_zhenlie = function(self, data)
	local use = q(data,"toCardUse")
	if not use.from or q(use.from,"isDead") then return false end
	if q(self.player,"getRole") == "rebel" and q(self,"getRoleEstimate",use.from) == "rebel" and not q(use.from,"hasSkill","jueqing")
		and q(self.player,"getHp") == 1 and q(self,"getAllPeachNum") < 1 then return false end
	if q(self,"isEnemy",use.from) or (q(self,"isFriend",use.from) and q(self.player,"getRole") == "loyalist" and not q(use.from,"hasSkill","jueqing") and q(use.from,"isLord") and q(self.player,"getHp") == 1) then
		if q(use.card,"isKindOf","Slash") then
			if not q(self,"slashIsEffective",use.card, self.player, use.from) then return false end
			if q(self,"hasHeavyDamage",use.from, use.card, self.player) then return true end
			local jink_num = q(self,"getExpectedJinkNum",use)
			local hasHeart = false
			for _, card in ipairs(q(self,"getCards","Jink")) do
				if q(card,"getSuit") == sgs.Card_Heart then
					hasHeart = true
					break
				end
			end
			if q(self,"getCardsNum","Jink") == 0
				or jink_num == 0
				or q(self,"getCardsNum","Jink") < jink_num
				or (q(use.from,"hasSkill","dahe") and q(self.player,"hasFlag","dahe") and not hasHeart) then

				if q(use.card,"isKindOf","NatureSlash") and q(self.player,"isChained") and not q(self,"isGoodChainTarget",self.player, use.from, nil, nil, use.card) then return true end
				if q(use.from,"hasSkill","nosqianxi") and q(use.from,"distanceTo",self.player) == 1 then return true end
				if q(self,"isFriend",use.from) and q(self.player,"getRole") == "loyalist" and not q(use.from,"hasSkill","jueqing") and q(use.from,"isLord") and q(self.player,"getHp") == 1 then return true end
				if (not (q(self,"hasSkills",sgs.masochism_skill) or (q(self.player,"hasSkills","tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or q(use.from,"hasSkill","jueqing"))
					and q(self,"doDisCard",use.from) then
					return true
				end
			end
		elseif q(use.card,"isKindOf","AOE") then
			local from = use.from
			if q(use.card,"isKindOf","SavageAssault") then
				local menghuo = q(self.room,"findPlayerBySkillName","huoshou")
				if menghuo then from = menghuo end
			end

			local friend_null = 0
			for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
				if q(self,"isFriend",p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
				if q(self,"isEnemy",p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
			end
			friend_null = friend_null + q(self,"getCardsNum","Nullification")
			local sj_num = q(self,"getCardsNum",q(use.card,"isKindOf","SavageAssault") and "Slash" or "Jink")

			if not q(self,"hasTrickEffective",use.card, self.player, from) then return false end
			if not q(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, from) then return false end
			if q(use.from,"hasSkill","drwushuang") and q(self.player,"getCardCount") == 1 and q(self,"hasLoseHandcardEffective") then return true end
			if sj_num == 0 and friend_null <= 0 then
				if q(self,"isEnemy",from) and q(from,"hasSkill","jueqing") then return q(self,"doDisCard",from) end
				if q(self,"isFriend",from) and q(self.player,"getRole") == "loyalist" and q(from,"isLord") and q(self.player,"getHp") == 1 and not q(from,"hasSkill","jueqing") then return true end
				if (not (q(self,"hasSkills",sgs.masochism_skill) or (q(self.player,"hasSkills","tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or q(use.from,"hasSkill","jueqing"))
					and q(self,"doDisCard",use.from) then
					return true
				end
			end
		elseif q(self,"isEnemy",use.from) then
			if q(use.card,"isKindOf","FireAttack") and q(use.from,"getHandcardNum") > 0 then
					if not q(self,"hasTrickEffective",use.card, self.player) then return false end
				if not q(self,"damageIsEffective",self.player, sgs.DamageStruct_Fire, use.from) then return false end
				if (q(self.player,"hasArmorEffect","vine") or q(self.player,"getMark","@gale") > 0) and q(use.from,"getHandcardNum") > 3
					and not (q(use.from,"hasSkill","hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
					return q(self,"doDisCard",use.from)
				elseif q(self.player,"isChained") and not q(self,"isGoodChainTarget",self.player, use.from) then
					return q(self,"doDisCard",use.from)
				end
			elseif (q(use.card,"isKindOf","Snatch") or q(use.card,"isKindOf","Dismantlement"))
					and q(self,"getCardsNum","Peach") == q(self.player,"getHandcardNum") and not q(self.player,"isKongcheng") then
				if not q(self,"hasTrickEffective",use.card, self.player) then return false end
				return q(self,"doDisCard",use.from)
			elseif q(use.card,"isKindOf","Duel") then
				if q(self,"getCardsNum","Slash") == 0 or q(self,"getCardsNum","Slash") < getCardsNum("Slash", use.from, self.player) then
					if not q(self,"hasTrickEffective",use.card, self.player) then return false end
					if not q(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, use.from) then return false end
					return q(self,"doDisCard",use.from)
				end
			elseif q(use.card,"isKindOf","TrickCard") and not q(use.card,"isKindOf","AmazingGrace") then
				if q(self,"doDisCard",use.from) and q(self,"needToLoseHp",self.player) then
					return true
				end
			end
		end
	end
	return false
end

sgs.ai_skill_cardask["@zhenlie-discard"] = function(self, data)
	local who = q(data,"toPlayer")
	if not q(self,"isEnemy",who) then return "." end
	local cards = q(self.player,"getCards","he")
	q(self,"sortByKeepValue",cards)
	for _, c in sgs.qlist(cards) do
		if not q(c,"isKindOf","Peach") and (not q(c,"isKindOf","Analeptic")) then
			return "$" .. q(c,"getEffectiveId")
		end
	end
end

sgs.ai_skill_invoke.sk_miji = true

sgs.ai_skill_playerchosen["sk_miji"] = function(self, targets)
	q(self,"updatePlayers")
	q(self,"sort",self.friends, "handcard")
	local can_give_friend = {}
	for _, friend in ipairs(self.friends) do
		if not q(self,"hasManjuanEffect",friend) and not q(self,"isLihunTarget",friend) then
			table.insert(can_give_friend, friend)
		end
	end
	if #can_give_friend > 0 then return can_give_friend[1] end
end
sgs.ai_playerchosen_intention.sk_miji = -50

sgs.ai_getBestHp_skill.sk_miji = function(owner)
	return q(owner,"getMaxHp") - 1
end

sgs.ai_skill_cardask["@zhoufu"] = function(self, data)
	local current = q(self.room,"getCurrent")
	if q(self,"isEnemy",current) then
		local cards = q(self.player,"getCards","h")
		q(self,"sortByKeepValue",cards)
		for _, c in sgs.qlist(cards) do
			if not q(c,"isKindOf","Peach") and (not q(c,"isKindOf","Analeptic")) then
				return "$" .. q(c,"getEffectiveId")
			end
		end
	end
	return "."
end
sgs.ai_choicemade_filter.cardResponded["@zhoufu"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = q(self.room,"getCurrent")
		if not current then return end
		q(self,"updateIntention",player, current, 80)
	end
end

sgs.ai_skill_invoke["sk_yingbing"] = function(self, data)
	local player = q(data,"toPlayer")
	return q(self,"isEnemy",player)
end
ai_audited_aliases.register({id="ai_cardneed.sk_fenwei",registry="ai_cardneed",path={"sk_fenwei"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.sk_kuangfu",registry="ai_cardneed",path={"sk_kuangfu"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.sk_feijun",registry="ai_cardneed",path={"sk_feijun"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.sk_caijie",registry="ai_cardneed",path={"sk_caijie"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.sk_jiwu",registry="ai_cardneed",path={"sk_jiwu"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

--邓芝：和盟/素检
sgs.ai_fill_skill.sk_hemeng=function(self,inclusive,request)
    if q(self.player,"isKongcheng") then return nil end
	return seed(self,"#sk_hemengCard:.:")
end

sgs.ai_skill_use_func["#sk_hemengCard"] = function(card, use, self)
    local target
	for _, p in ipairs(self.enemies) do
	    if not q(p,"isKongcheng") and q(p,"getHandcardNum") > q(self.player,"getHandcardNum") then
		    if not target or q(p,"getHandcardNum") > q(target,"getHandcardNum") then target = p end
		end
	end
	if target then
	    use.card = card
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_value["sk_hemengCard"] = 60
sgs.ai_use_priority["sk_hemengCard"] = 2
sgs.ai_card_intention["sk_hemengCard"] = 30

sgs.ai_skill_cardchosen.sk_hemeng = function(self, who, flags, reason, method)
    local cards = sgs.QList2Table(q(who,"getCards","h"))
	if #cards == 0 then return -1 end
	q(self,"sortByKeepValue",cards)
	return cards[#cards]:getEffectiveId()
end

sgs.ai_skill_playerchosen.sk_sujian = function(self, targets)
    local friends = {}
	for _, t in sgs.qlist(targets) do
	    if q(self,"isFriend",t) and not q(t,"isNude") then table.insert(friends, t) end
	end
	if #friends > 0 then return friends[1] end
	if q(self.player,"getHandcardNum") >= 3 then
	    local enemies = {}
		for _, t in sgs.qlist(targets) do
		    if q(self,"isEnemy",t) and not q(t,"isNude") then table.insert(enemies, t) end
		end
		if #enemies > 0 then return enemies[1] end
	end
	return nil
end

sgs.ai_skill_cardchosen.sk_sujian = function(self, who, flags, reason, method)
    local cards = sgs.QList2Table(q(who,"getCards","he"))
	if #cards == 0 then return -1 end
	q(self,"sortByKeepValue",cards)
	if q(self,"isFriend",who) then
	    return cards[1]:getEffectiveId()
	end
	return cards[#cards]:getEffectiveId()
end
sgs.ai_playerchosen_intention.sk_sujian = 30

--陈式：擎北
sgs.ai_skill_invoke.sk_qingbei = true

sgs.ai_skill_choice.sk_qingbei = function(self, choices)
    local count = {spade = 0, heart = 0, club = 0, diamond = 0}
	for _, c in sgs.qlist(q(self.player,"getHandcards")) do
	    local s = q(c,"getSuitString")
		if count[s] ~= nil then count[s] = count[s] + 1 end
	end
	local best, n = "spade", -1
	for k, v in pairs(count) do
	    if v > n then best, n = k, v end
	end
	return best
end

--马良：雅虑/协穆
sgs.ai_skill_invoke.sk_yalv = true

sgs.ai_skill_cardask["@xiemu-put"] = function(self, data)
    if q(self.player,"isKongcheng") then return "." end
	local current = q(self.room,"getCurrent")
	if not current then return "." end
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	if #cards == 0 then return "." end
	q(self,"sortByKeepValue",cards)
	if q(self,"isFriend",current) then
	    if q(current,"isWounded") then
		    for _, c in ipairs(cards) do
			    if q(c,"isKindOf","Peach") then return card_answer(c) end
			end
		end
		for i = #cards, 1, -1 do
		    if q(cards[i],"isKindOf","BasicCard") then return card_answer(cards[i]) end
		end
	end
	return card_answer(cards[1])
end

sgs.ai_skill_invoke.sk_xiemu = function(self, data)
    local current = q(self.room,"getCurrent")
	return current and q(self,"isFriend",current)
end

--费祎：衍息/止戈
sgs.ai_skill_invoke.sk_yanxi = true

sgs.ai_skill_invoke.sk_zhige = function(self, data)
    if q(self.player,"getEquips"):isEmpty() then return false end
	local asked = q(data,"toStringList")
	local pattern = asked and asked[1]
	if pattern == "jink" then
	    return q(self,"getCardsNum","Jink") == 0
	elseif pattern == "slash" then
	    return q(self,"getCardsNum","Slash") == 0
	end
	return true
end

--甘夫人：淑慎/神智
sgs.ai_skill_playerchosen.sk_shushen = function(self, targets)
    local friends = {}
	for _, t in sgs.qlist(targets) do
	    if q(self,"isFriend",t) then table.insert(friends, t) end
	end
	if #friends == 0 then return nil end
	local wounded = {}
	for _, t in ipairs(friends) do
	    if q(t,"isWounded") then table.insert(wounded, t) end
	end
	if #wounded > 0 then
	    q(self,"sort",wounded,"hp")
		return wounded[1]
	end
	q(self,"sort",friends,"hp")
	return friends[1]
end
sgs.ai_playerchosen_intention.sk_shushen = -50

sgs.ai_skill_choice.sk_shushen = function(self, choices)
    if q(self.player,"isWounded") and q(self.player,"getHp") <= 2 then
	    return "shushen_recover"
	end
	return "shushen_draw"
end

sgs.ai_skill_invoke.sk_shenzhi = function(self, data)
    if not q(self.player,"isWounded") then return false end
	local h = q(self.player,"getHandcardNum")
	local hp = math.max(1, q(self.player,"getHp"))
	if h < hp then return false end
	if q(self,"isWeak") then return true end
	if h <= hp then return true end
	return q(self.player,"getLostHp") >= 3
end

--糜夫人：闺秀/存嗣
sgs.ai_skill_invoke.sk_guixiu = true

sgs.ai_skill_playerchosen.sk_cunsi = function(self, targets)
    local friends = {}
	for _, t in sgs.qlist(targets) do
	    if q(self,"isFriend",t) then table.insert(friends, t) end
	end
	if #friends == 0 then return nil end
	q(self,"sort",friends,"defense")
	return friends[#friends]
end
sgs.ai_playerchosen_intention.sk_cunsi = -80

--刘谌：战绝
sgs.ai_skill_playerchosen.sk_zhanjue = function(self, targets)
	local enemies = {}
	for _, t in sgs.qlist(targets) do
		if q(self,"isEnemy",t) then table.insert(enemies, t) end
	end
	if #enemies == 0 then return nil end
	q(self,"sort",enemies,"hp")
	return enemies[1]
end
sgs.ai_playerchosen_intention.sk_zhanjue = 80

--诸葛果：羽化/登仙
sgs.ai_skill_invoke.sk_yuhua = function(self, data)
	local damage = q(data,"toDamage")
	if damage.to and q(damage.to,"objectName") == q(self.player,"objectName") then return true end
	if damage.from and q(damage.from,"objectName") == q(self.player,"objectName")
		and damage.to and q(self,"isFriend",damage.to) then return true end
	return false
end

sgs.ai_skill_choice.sk_dengxian = function(self, choices)
	if q(self.player,"getHandcardNum") > 0 then return "dengxian_play" end
	return "dengxian_draw"
end

--夏侯氏：拾樵/莺歌
sgs.ai_skill_invoke.sk_shiqiao = true

sgs.ai_skill_cardask["@sk_yingge-discard"] = function(self, data)
	local current = q(self.room,"getCurrent")
	if not (current and q(self,"isFriend",current)) then return "." end
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	if #cards == 0 then return "." end
	q(self,"sortByKeepValue",cards)
	local best
	for _, c in ipairs(cards) do
		if not best or q(c,"getNumber") < q(best,"getNumber") then best = c end
	end
	return card_answer(best)
end

--吴苋：贺春/怠宴
sgs.ai_fill_skill.sk_hechun=function(self,inclusive,request)
    if q(self.player,"hasUsed","#sk_hechunCard") then return nil end
	return seed(self,"#sk_hechunCard:.:")
end

sgs.ai_skill_use_func["#sk_hechunCard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["sk_hechunCard"] = 60
sgs.ai_use_priority["sk_hechunCard"] = 6
sgs.ai_card_intention["sk_hechunCard"] = 30

sgs.ai_skill_invoke.sk_hechun_recover = function(self, data)
	local who = q(data,"toPlayer")
	return who and q(self,"isFriend",who)
end

sgs.ai_skill_invoke.sk_hechun_lose = function(self, data)
	local who = q(data,"toPlayer")
	return who and q(self,"isEnemy",who)
end

sgs.ai_skill_cardchosen.sk_hechun = function(self, who, flags, reason, method)
	local cards = sgs.QList2Table(q(who,"getCards","he"))
	if #cards == 0 then return -1 end
	q(self,"sortByKeepValue",cards)
	for _, c in ipairs(cards) do
		if q(c,"isRed") then return q(c,"getEffectiveId") end
	end
	return q(cards[1],"getEffectiveId")
end

sgs.ai_skill_playerchosen.sk_daiyan = function(self, targets)
	local mine = q(self.player,"objectName")
	local best, bestcnt
	for _, t in sgs.qlist(targets) do
		local cnt = q(t,"getMark","&sk_daiyan+#"..mine)
		if q(self,"isFriend",t) and (not bestcnt or cnt < bestcnt) then
			best, bestcnt = t, cnt
		end
	end
	if best then return best end
	for _, t in sgs.qlist(targets) do
		if t:objectName() == mine and q(t,"getMark","&sk_daiyan+#"..mine) < 2 then return t end
	end
	return nil
end

sgs.ai_playerchosen_intention.sk_daiyan = -60

--花鬘：蛮裔/薮影
sgs.ai_skill_invoke.sk_manyi = function(self, data)
	local use = q(data,"toCardUse")
	local card, from = use.card, use.from
	if not (card and from) then return false end
	local is_self = q(from,"objectName") == q(self.player,"objectName")
	if q(card,"isKindOf","SavageAssault") then return is_self end
	if is_self then return #self.enemies >= #self.friends_noself end
	return q(self.player,"getArmor") == "Vine" or #self.enemies > #self.friends
end

sgs.ai_skill_playerchosen.sk_souying_dmg = function(self, targets)
	local enemies = {}
	for _, t in sgs.qlist(targets) do
		if q(self,"isEnemy",t) then table.insert(enemies, t) end
	end
	if #enemies == 0 then return nil end
	q(self,"sort",enemies,"hp")
	return enemies[1]
end

sgs.ai_playerchosen_intention.sk_souying_dmg = 80

sgs.ai_skill_playerchosen.sk_souying_heal = function(self, targets)
	local wounded = {}
	for _, t in sgs.qlist(targets) do
		if q(self,"isFriend",t) and q(t,"isWounded") then table.insert(wounded, t) end
	end
	if #wounded == 0 then return nil end
	q(self,"sort",wounded,"hp")
	return wounded[1]
end

sgs.ai_playerchosen_intention.sk_souying_heal = -50


--关索：征南/同心
local sk_zhengnan_skill = {}
sk_zhengnan_skill.name = "sk_zhengnan"
table.insert(sgs.ai_skills, sk_zhengnan_skill)
sk_zhengnan_skill.getTurnUseCard = function(self, inclusive)
	if q(self.player,"hasUsed","#sk_zhengnanCard") then return nil end
	return sgs.Card_Parse("#sk_zhengnanCard:.:")
end
sgs.ai_skill_use_func["#sk_zhengnanCard"] = function(card, use, self)
	if #self.enemies <= #self.friends_noself then return end
	use.card = card
	if use.to then use.to:append(self.player) end
end
sgs.ai_use_value["sk_zhengnanCard"] = 6
sgs.ai_use_priority["sk_zhengnanCard"] = 4

sgs.ai_skill_invoke.sk_tongxin = true


--鲍三娘：镇南（剑舞为被动技）
sgs.ai_skill_playerchosen.sk_zhennan = function(self, targets)
	local enemies = {}
	for _, t in sgs.qlist(targets) do
		if q(self,"isEnemy",t) then table.insert(enemies, t) end
	end
	if #enemies == 0 then return nil end
	q(self,"sort",enemies,"hp")
	return enemies[1]
end
sgs.ai_playerchosen_intention.sk_zhennan = 80


--谯周：识命/星卜
sgs.ai_skill_invoke.sk_shiming = function(self, data)
	local move = q(data,"toMoveOneTime")
	if move.to then return q(self,"isEnemy",move.to) end
	return false
end
sgs.ai_skill_choice["sk_shiming"] = function(self, choices, data)
	return "sk_shiming_obtain"
end

sgs.ai_skill_invoke.sk_xingbu = true
sgs.ai_skill_playerchosen.sk_xingbu = function(self, targets)
	local friends = {}
	for _, t in sgs.qlist(targets) do
		if q(self,"isFriend",t) then table.insert(friends, t) end
	end
	if #friends == 0 then return nil end
	q(self,"sort",friends,"handcard")
	return friends[1]
end
sgs.ai_playerchosen_intention.sk_xingbu = -60


--孙策：昂扬/威风
sgs.ai_skill_invoke.sk_angyang = true

sgs.ai_skill_playerchosen.sk_weifeng = function(self, targets)
	targets = sgs.QList2Table(targets)
	local max_card = q(self,"getMaxCard")
	local max_point = max_card and q(max_card,"getNumber") or 0
	if max_point >= 10 then
		local enemies = {}
		for _, t in ipairs(targets) do
			if q(self,"isEnemy",t) then table.insert(enemies, t) end
		end
		if #enemies > 0 then
			q(self,"sort",enemies,"handcard")
			return enemies[1]
		end
	end
	local friends = {}
	for _, t in ipairs(targets) do
		if q(self,"isFriend",t) and q(t,"getHandcardNum") <= 1 then table.insert(friends, t) end
	end
	if #friends > 0 then
		q(self,"sort",friends,"handcard")
		return friends[1]
	end
	return nil
end


--步骘：折节/风雅
sgs.ai_skill_cardask["@sk_zhejie-discard"] = function(self, data)
	local current = q(self.room,"getCurrent")
	if not current then return "." end
	if not (q(self,"isEnemy",current) and not q(current,"isNude")) then return "." end
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	if #cards == 0 then return "." end
	q(self,"sortByKeepValue",cards)
	return card_answer(cards[1])
end

sgs.ai_skill_cardchosen.sk_zhejie = function(self, who, flags, reason, method)
	local cards = sgs.QList2Table(q(who,"getCards","he"))
	if #cards == 0 then return -1 end
	q(self,"sortByKeepValue",cards)
	if q(self,"isFriend",who) then
		return q(cards[1],"getEffectiveId")
	end
	for i = #cards, 1, -1 do
		if q(cards[i],"isKindOf","EquipCard") then return q(cards[i],"getEffectiveId") end
	end
	return q(cards[#cards],"getEffectiveId")
end

sgs.ai_skill_playerchosen.sk_zhejie = function(self, targets)
	for _, t in sgs.qlist(targets) do
		if q(t,"objectName") == q(self.player,"objectName") then return t end
	end
	for _, t in sgs.qlist(targets) do
		if q(self,"isFriend",t) then return t end
	end
	return nil
end

sgs.ai_skill_invoke.sk_fengya = true

sgs.ai_skill_invoke.sk_fengya_reduce = function(self, data)
	local who = q(data,"toPlayer")
	return who and q(self,"isFriend",who)
end


--董袭：断缆
local sk_duanlan_skill = {}
sk_duanlan_skill.name = "sk_duanlan"
table.insert(sgs.ai_skills, sk_duanlan_skill)
sk_duanlan_skill.getTurnUseCard = function(self, inclusive)
	if q(self.player,"hasUsed","#sk_duanlanCard") then return nil end
	return sgs.Card_Parse("#sk_duanlanCard:.:")
end

sgs.ai_skill_use_func["#sk_duanlanCard"] = function(card, use, self)
	local has_victim = false
	for _, p in ipairs(self.enemies) do
		if not (q(p,"isNude") and q(p,"getJudgingArea"):isEmpty()) then has_victim = true break end
	end
	if not has_victim then return end
	local max_point, total = 0, q(self.player,"getCards","he"):length()
	for _, c in sgs.qlist(q(self.player,"getCards","he")) do
		if q(c,"getNumber") > max_point then max_point = q(c,"getNumber") end
	end
	if max_point <= 10 and not (q(self.player,"getHp") > 2 and total >= 3) then return end
	use.card = card
end
sgs.ai_use_value["sk_duanlanCard"] = 6
sgs.ai_use_priority["sk_duanlanCard"] = 5

sgs.ai_skill_playerchosen.sk_duanlan = function(self, targets)
	local enemies = {}
	for _, t in sgs.qlist(targets) do
		if q(self,"isEnemy",t) then table.insert(enemies, t) end
	end
	if #enemies == 0 then return nil end
	local best, best_n
	for _, t in ipairs(enemies) do
		local n = q(t,"getEquips"):length()
		if not best_n or n > best_n then best, best_n = t, n end
	end
	return best or enemies[1]
end

sgs.ai_skill_cardchosen.sk_duanlan = function(self, who, flags, reason, method)
	local cards = sgs.QList2Table(q(who,"getCards","hej"))
	if #cards == 0 then return -1 end
	q(self,"sortByKeepValue",cards)
	if q(self,"isFriend",who) then
		return q(cards[1],"getEffectiveId")
	end
	return q(cards[#cards],"getEffectiveId")
end

sgs.ai_skill_cardask["@sk_duanlan-pay"] = function(self, data, pattern)
	local need = 14
	if type(pattern) == "string" then
		need = tonumber(pattern:match("%d+")) or 14
	end
	local best
	for _, c in sgs.qlist(q(self.player,"getCards","he")) do
		if q(c,"getNumber") >= need then
			if not best or q(c,"getNumber") < q(best,"getNumber") then best = c end
		end
	end
	if best then return card_answer(best) end
	return "."
end


--朱然：胆守（锁定技）/勇烈
sgs.ai_skill_invoke.sk_yonglie = function(self, data)
	local damage = q(data,"toDamage")
	if not (damage.from and q(damage.from,"isAlive")) then return false end
	return q(self,"isEnemy",damage.from) and q(self.player,"getHp") > 1
end


--丁奉：搏战/轻袭（锁定技）
sgs.ai_skill_cardask["@sk_bozhan-slash"] = sgs.ai_skill_cardask["@pengri-slash"]


--蒋钦：尚义/忘私
local sk_shangyi_skill = {}
sk_shangyi_skill.name = "sk_shangyi"
table.insert(sgs.ai_skills, sk_shangyi_skill)
sk_shangyi_skill.getTurnUseCard = function(self, inclusive)
	if q(self.player,"hasUsed","#sk_shangyiCard") then return nil end
	return sgs.Card_Parse("#sk_shangyiCard:.:")
end

sgs.ai_skill_use_func["#sk_shangyiCard"] = function(card, use, self)
	local targets = {}
	for _, p in ipairs(self.enemies) do
		if not q(p,"isKongcheng") then table.insert(targets, p) end
	end
	if #targets == 0 then
		for _, p in ipairs(self.friends_noself) do table.insert(targets, p) end
	end
	if #targets == 0 then return nil end
	q(self,"sort",targets,"handcard")
	use.card = card
	if use.to then use.to:append(targets[#targets]) end
end
sgs.ai_use_value["sk_shangyiCard"] = 5
sgs.ai_use_priority["sk_shangyiCard"] = 6

sgs.ai_skill_choice["sk_shangyi"] = function(self, choices, data)
	return "shangyi_hand"
end

sgs.ai_skill_invoke.sk_wangsi = function(self, data)
	local damage = q(data,"toDamage")
	return damage.from and q(self,"isEnemy",damage.from) and not q(damage.from,"isKongcheng")
end


--周泰：不屈（锁定技）/奋激
sgs.ai_skill_invoke.sk_fenji = function(self, data)
	local target = q(data,"toPlayer")
	if not target then return false end
	if q(self.player,"getHp") <= 1 then return false end
	return q(self,"isFriend",target)
end


--陆绩：怀橘/浑天
sgs.ai_skill_invoke.sk_huaiju = true

sgs.ai_skill_choice.sk_huaiju = function(self, choices)
	if q(self,"getOverflow") > 0 then return "huaiju_discard" end
	return "huaiju_draw"
end

sgs.ai_skill_invoke.sk_huntian = true

sgs.ai_skill_askforag.sk_huntian = function(self, card_ids)
	local cards = {}
	for _, id in sgs.list(card_ids) do
		table.insert(cards, face(self, id))
	end
	if #cards == 0 then return -1 end
	q(self,"sortByKeepValue",cards)
	return q(cards[1],"getEffectiveId")
end

sgs.ai_skill_askforag.sk_huntian_more = function(self, card_ids)
	return -1
end


--诸葛瑾：缓兵（锁定技）/弘援
sgs.ai_fill_skill.sk_hongyuan = function(self, inclusive, request)
	if q(self.player,"getLostHp") <= 0 then return nil end
	if q(self.player,"hasUsed","#sk_hongyuanCard") then return nil end
	local field = 0
	for _, p in sgs.qlist(q(self.room,"getAllPlayers")) do
		field = field + q(p,"getCards","ej"):length()
	end
	if field <= 0 then return nil end
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	if #cards == 0 then return nil end
	q(self,"sortByKeepValue",cards)
	local n = math.min(q(self.player,"getLostHp"), #cards, field)
	local ids = {}
	for i = 1, n do
		table.insert(ids, q(cards[i],"getEffectiveId"))
	end
	return seed(self,"#sk_hongyuanCard:" .. table.concat(ids, "+") .. ":")
end

sgs.ai_skill_use_func["#sk_hongyuanCard"] = function(card, use, self)
	local target = self.player
	for _, p in ipairs(self.friends) do
		if not q(p,"getJudgingArea"):isEmpty() then
			target = p
			break
		end
	end
	use.card = card
	if use.to then use.to:append(target) end
end

sgs.ai_use_value["sk_hongyuanCard"] = 60
sgs.ai_use_priority["sk_hongyuanCard"] = 4
sgs.ai_card_intention["sk_hongyuanCard"] = -80

--徐氏：问卦/伏诛
sgs.ai_skill_exchange = sgs.ai_skill_exchange or {}
sgs.ai_skill_exchange["sk_wengua"] = function(self, pattern, max_num, min_num, expand_pile)
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	if #cards == 0 then return nil end
	q(self,"sortByKeepValue",cards)
	if pattern and string.find(pattern,"@sk_wengua%-give") then
		local promptlist = pattern:split(":")
		local target = q(self.room,"findPlayerByObjectName",promptlist[#promptlist])
		if not (target and q(self,"isFriend",target)) then return nil end
	end
	return { q(cards[1],"getEffectiveId") }
end

sgs.ai_fill_skill.sk_fuzhu = function(self, inclusive, request)
	if q(self.player,"hasUsed","#sk_fuzhuCard") then return nil end
	return seed(self,"#sk_fuzhuCard:.:")
end

sgs.ai_skill_use_func["#sk_fuzhuCard"] = function(card, use, self)
	local target
	for _, p in ipairs(self.enemies) do
		if not target or q(p,"getHp") < q(target,"getHp")
			or (q(p,"getHp") == q(target,"getHp") and q(p,"getHandcardNum") < q(target,"getHandcardNum")) then
			target = p
		end
	end
	if not target then return end
	use.card = card
	if use.to then use.to:append(target) end
end

sgs.ai_use_value["sk_fuzhuCard"] = 60
sgs.ai_use_priority["sk_fuzhuCard"] = 4
sgs.ai_card_intention["sk_fuzhuCard"] = 120


--周妃：姻缘/箜篌
sgs.ai_skill_playerchosen.sk_yinyuan = function(self, targets)
	local best
	for _, t in sgs.qlist(targets) do
		if q(self,"isFriend",t) and (not best or q(t,"getHandcardNum") < q(best,"getHandcardNum")) then
			best = t
		end
	end
	if best then return best end
	for _, t in sgs.qlist(targets) do
		if t:objectName() == q(self.player,"objectName") then return t end
	end
	return nil
end

sgs.ai_playerchosen_intention.sk_yinyuan = -60

sgs.ai_skill_cardask["@sk_konghou-discard"] = function(self, data)
	local use = q(data,"toCardUse")
	if not (use and use.from) then return "." end
	if not q(self,"isEnemy",use.from) then return "." end
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	if #cards == 0 then return "." end
	q(self,"sortByKeepValue",cards)
	return card_answer(cards[1])
end


--潘淑：锦织/鱼忧
sgs.ai_fill_skill.sk_jinzhi = function(self, inclusive, request)
	if q(self.player,"isKongcheng") then return nil end
	if q(self.player,"isWounded") then
		return seed(self,"#sk_jinzhi:.:peach")
	end
	local slash = evaluation(self,"slash")
	for _, enemy in ipairs(self.enemies) do
		if q(self.player,"canSlash",enemy) and not q(self,"slashProhibit",slash,enemy,self.player)
			and q(self,"slashIsEffective",slash,enemy,self.player)
			and q(self,"isGoodTarget",enemy,self.enemies,nil) then
			return seed(self,"#sk_jinzhi:.:slash")
		end
	end
	return nil
end

sgs.ai_skill_use_func["#sk_jinzhi"] = function(card, use, self)
	local userstring = q(card,"getLegacyStringKey")
	local name
	for _, p in ipairs(userstring:split(":")) do
		if p == "peach" or p == "analeptic" or p == "slash" or p == "fire_slash" or p == "thunder_slash" then
			name = p
		end
	end
	if not name then return end
	local jinzhi_card = declared(self,"sk_jinzhi",card,name)
	q(self,"useBasicCard",jinzhi_card,use)
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority["sk_jinzhi"] = 8
sgs.ai_use_value["sk_jinzhi"] = 8

sgs.ai_skill_askforag["@sk_yuyou-keep"] = function(self, card_ids)
	local cards = {}
	for _, id in sgs.list(card_ids) do
		table.insert(cards, face(self, id))
	end
	if #cards == 0 then return -1 end
	q(self,"sortByKeepValue",cards)
	return q(cards[1],"getEffectiveId")
end

sgs.ai_skill_playerchosen.sk_yuyou = function(self, targets)
	local best
	for _, t in sgs.qlist(targets) do
		if q(self,"isEnemy",t) then
			if not best or q(t,"getHp") < q(best,"getHp")
				or (q(t,"getHp") == q(best,"getHp") and q(t,"getHandcardNum") < q(best,"getHandcardNum")) then
				best = t
			end
		end
	end
	return best
end

sgs.ai_playerchosen_intention.sk_yuyou = 60

sgs.ai_skill_choice["sk_yuyou"] = function(self, choices, data)
	local n = 1
	if data then n = data:toInt() or 1 end
	local cards = sgs.QList2Table(q(self.player,"getCards","he"))
	if q(self.player,"getHp") <= 1 then return "yuyou_discard" end
	if n <= #cards and n <= 2 then return "yuyou_discard" end
	if n > #cards then return "yuyou_discard" end
	return "yuyou_losehp"
end


--孙休：宴诛/兴学
sgs.ai_fill_skill.sk_yanzhu = function(self, inclusive, request)
	if q(self.player,"hasUsed","#sk_yanzhuCard") then return nil end
	return seed(self,"#sk_yanzhuCard:.:")
end

sgs.ai_skill_use_func["#sk_yanzhuCard"] = function(card, use, self)
	local target
	for _, e in ipairs(self.enemies) do
		local m = q(e,"getMark","@sk_yanzhu")
		if m == 2 and q(self,"damageIsEffective",e, sgs.DamageStruct_Normal)
			and q(self,"canDamage",e,self.player,nil) and not q(self,"cantbeHurt",e) then
			target = e
			break
		end
	end
	if not target then
		for _, e in ipairs(self.enemies) do
			if q(e,"getMark","@sk_yanzhu") == 1 and not q(e,"isKongcheng") then
				target = e
				break
			end
		end
	end
	if not target then
		for _, f in ipairs(self.friends) do
			if q(f,"getMark","@sk_yanzhu") == 0 then
				target = f
				break
			end
		end
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_value["sk_yanzhuCard"] = 70
sgs.ai_use_priority["sk_yanzhuCard"] = 4
sgs.ai_card_intention["sk_yanzhuCard"] = function(self, card, from, tos)
	local to = tos[1]
	if to and q(to,"getMark","@sk_yanzhu") > 0 then return 60 end
	return -30
end

sgs.ai_skill_playerchosen.sk_xingxue = function(self, targets)
	local selfname = q(self.player,"objectName")
	for _, t in sgs.qlist(targets) do
		if q(t,"objectName") == selfname and q(t,"getMark","@sk_yanzhu") > 0 then return t end
	end
	local best, best_m = nil, 0
	for _, t in sgs.qlist(targets) do
		local m = q(t,"getMark","@sk_yanzhu")
		if q(self,"isFriend",t) and m > best_m then
			best = t
			best_m = m
		end
	end
	if best then return best end
	for _, t in sgs.qlist(targets) do
		local m = q(t,"getMark","@sk_yanzhu")
		if q(self,"isEnemy",t) and q(t,"getHandcardNum") + m > q(t,"getMaxHp") then
			return t
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.sk_xingxue = -40


--孙登：匡弼
sgs.ai_skill_invoke.sk_kuangbi = function(self, data)
	local use = q(data,"toCardUse")
	if not (use and use.from and use.card and use.to) then return false end
	if not q(self,"isEnemy",use.from) then return false end
	local harmful = q(use.card,"isKindOf","Slash") or q(use.card,"isKindOf","Duel")
		or q(use.card,"isKindOf","SavageAssault") or q(use.card,"isKindOf","ArcheryAttack")
		or q(use.card,"isKindOf","Dismantlement") or q(use.card,"isKindOf","Snatch")
		or q(use.card,"isKindOf","FireAttack")
	if harmful then
		for _, t in sgs.qlist(use.to) do
			if q(self,"isFriend",t) then return true end
		end
		return false
	end
	for _, t in sgs.qlist(use.to) do
		if q(self,"isFriend",t) then return false end
	end
	return #self.friends > 0
end

sgs.ai_skill_playerschosen.sk_kuangbi = function(self, targets, max_num, min_num)
	local chosen = {}
	if q(self.player,"getMark","sk_kuangbi_harm-Clear") > 0 then
		for _, p in sgs.qlist(targets) do
			if q(self,"isEnemy",p) then table.insert(chosen, p) end
		end
	else
		for _, p in sgs.qlist(targets) do
			if q(self,"isFriend",p) then table.insert(chosen, p) end
		end
	end
	return chosen
end


--朱治：安国
sgs.ai_skill_playerchosen.sk_anguo = function(self, targets)
	local wounded = {}
	for _, t in sgs.qlist(targets) do
		if q(self,"isFriend",t) and q(t,"isWounded") then table.insert(wounded, t) end
	end
	if #wounded > 0 then
		q(self,"sort",wounded,"hp")
		return wounded[1]
	end
	local selfname = q(self.player,"objectName")
	for _, t in sgs.qlist(targets) do
		if q(t,"objectName") == selfname then return t end
	end
	for _, t in sgs.qlist(targets) do
		if q(self,"isFriend",t) then return t end
	end
	return nil
end

sgs.ai_playerchosen_intention.sk_anguo = -50


--孙亮：溃诛
sgs.ai_skill_playerchosen.sk_kuizhu = function(self, targets)
	for _, e in ipairs(self.enemies) do
		for _, t in sgs.qlist(targets) do
			if q(t,"objectName") == q(e,"objectName") then return t end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.sk_kuizhu = 60


--孙亮：掣政
local function sk_chezheng_pick(self, targets)
	local rich_enemy, friend = nil, nil
	for _, t in sgs.qlist(targets) do
		if q(self,"isEnemy",t) and q(t,"getHandcardNum") >= 3 then
			if not rich_enemy or q(t,"getHandcardNum") > q(rich_enemy,"getHandcardNum") then
				rich_enemy = t
			end
		elseif q(self,"isFriend",t) and not friend then
			friend = t
		end
	end
	return rich_enemy, friend
end

sgs.ai_skill_invoke.sk_chezheng = function(self, data)
	local rich_enemy, friend = sk_chezheng_pick(self, q(self.room,"getAlivePlayers"))
	return rich_enemy ~= nil or friend ~= nil
end

sgs.ai_skill_playerschosen.sk_chezheng = function(self, targets, max_num, min_num)
	local rich_enemy, friend = sk_chezheng_pick(self, targets)
	local chosen = {}
	if rich_enemy then
		for _, t in sgs.qlist(targets) do
			if q(self,"isEnemy",t) and q(t,"getHandcardNum") >= 3 then table.insert(chosen, t) end
		end
	elseif friend then
		for _, t in sgs.qlist(targets) do
			if q(self,"isFriend",t) then table.insert(chosen, t) end
		end
	end
	return chosen
end

sgs.ai_skill_choice["sk_chezheng"] = function(self, choices)
	for _, t in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(self,"isEnemy",t) and q(t,"getHandcardNum") >= 3 then
			return "sk_chezheng_discard"
		end
	end
	return "sk_chezheng_play"
end


--葛玄：炼化
sgs.ai_skill_invoke.sk_lianhua = function(self, data)
	local current = q(self.room,"getCurrent")
	if not current then return false end
	if q(self,"isFriend",current) then return true end
	return q(self,"isEnemy",current) and q(current,"getHandcardNum") <= 2
end

sgs.ai_skill_cardchosen.sk_lianhua = function(self, who, flags, reason, method)
	local cards = sgs.QList2Table(q(who,"getCards","h"))
	if #cards == 0 then return nil end
	q(self,"sortByKeepValue",cards)
	if q(self,"isFriend",who) then
		return cards[1]:getEffectiveId()
	end
	return cards[#cards]:getEffectiveId()
end


--臧霸：横江
sgs.ai_skill_choice["sk_hengjiang"] = function(self, choices)
	local field_enemy = false
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(self,"isEnemy",p) and (q(p,"hasEquip") or q(p,"getJudgingArea"):length() > 0) then
			field_enemy = true
			break
		end
	end
	if field_enemy and q(self.player,"getHandcardNum") > q(self.player,"getHp") then
		return "hengjiang_minus"
	end
	return "hengjiang_plus"
end

sgs.ai_skill_playerchosen.sk_hengjiang = function(self, targets)
	for _, e in ipairs(self.enemies) do
		for _, t in sgs.qlist(targets) do
			if q(t,"objectName") == q(e,"objectName") then return t end
		end
	end
	return nil
end

sgs.ai_skill_cardchosen.sk_hengjiang = function(self, who, flags, reason, method)
	local cards = sgs.QList2Table(q(who,"getCards","ej"))
	if #cards == 0 then return -1 end
	q(self,"sortByKeepValue",cards)
	if q(self,"isFriend",who) then return cards[1]:getEffectiveId() end
	return cards[#cards]:getEffectiveId()
end
sgs.ai_playerchosen_intention.sk_hengjiang = 60


--卞夫人：化戈
sgs.ai_fill_skill.sk_huage = function(self, inclusive, request)
	if q(self.player,"hasUsed","#sk_huageCard") then return nil end
	return seed(self,"#sk_huageCard:.:")
end

sgs.ai_skill_use_func["#sk_huageCard"] = function(card, use, self)
	for _, c in sgs.qlist(q(self.player,"getHandcards")) do
		if q(c,"isKindOf","Slash") then use.card = card return end
	end
	if #self.enemies > #self.friends_noself then use.card = card end
end

sgs.ai_use_value["sk_huageCard"] = 6
sgs.ai_use_priority["sk_huageCard"] = 5

sgs.ai_skill_exchange["sk_huage"] = function(self, pattern, max_num, min_num, expand_pile)
	local cards = sgs.QList2Table(q(self.player,"getCards","h"))
	if #cards == 0 then return nil end
	q(self,"sortByKeepValue",cards)
	for _, c in ipairs(cards) do
		if q(c,"isKindOf","Slash") then return { q(c,"getEffectiveId") } end
	end
	return { q(cards[1],"getEffectiveId") }
end


--卞夫人：母仪
sgs.ai_skill_exchange["sk_muyi"] = function(self, pattern, max_num, min_num, expand_pile)
	local cards = sgs.QList2Table(q(self.player,"getCards","h"))
	if #cards == 0 then return nil end
	q(self,"sortByKeepValue",cards)
	if pattern and string.find(pattern,"@muyi%-give") then
		local promptlist = pattern:split(":")
		local target = q(self.room,"findPlayerByObjectName",promptlist[#promptlist])
		if not (target and q(self,"isFriend",target)) then return nil end
		return { q(cards[1],"getEffectiveId") }
	elseif pattern and string.find(pattern,"@muyi%-back") then
		local ids = {}
		for i = 1, math.min(min_num, #cards) do
			table.insert(ids, q(cards[i],"getEffectiveId"))
		end
		return ids
	end
	return nil
end


--戏志才：天策/竭心
sgs.ai_skill_playerchosen.sk_tiance = function(self, targets)
	for _, t in sgs.qlist(targets) do
		if t:objectName() == q(self.player,"objectName") then return t end
	end
	for _, t in sgs.qlist(targets) do
		if q(self,"isFriend",t) then return t end
	end
	return nil
end
sgs.ai_playerchosen_intention.sk_tiance = -40

sgs.ai_skill_choice["sk_tiance"] = function(self, choices, data)
	local list = type(choices) == "table" and choices or choices:split("+")
	for _, c in ipairs(list) do
		if c == "tiance_others" and #self.enemies > #self.friends_noself then return c end
	end
	for _, c in ipairs(list) do
		if c == "tiance_drawpile" then return c end
	end
	for _, c in ipairs(list) do
		if c ~= "cancel" then return c end
	end
	return "cancel"
end


--曹睿：恢拓/兴衰
sgs.ai_skill_playerchosen.sk_huituo = function(self, targets)
	local friends = {}
	for _, t in sgs.qlist(targets) do
		if q(self,"isFriend",t) then table.insert(friends, t) end
	end
	if #friends == 0 then return nil end
	q(self,"sort",friends, "hp")
	self.sk_huituo_target = friends[1]
	return friends[1]
end
sgs.ai_playerchosen_intention.sk_huituo = -60

sgs.ai_skill_choice["sk_huituo"] = function(self, choices, data)
	local list = type(choices) == "table" and choices or choices:split("+")
	local target = self.sk_huituo_target
	local has = {}
	for _, c in ipairs(list) do has[c] = true end
	if target and q(target,"isWounded") and q(target,"getHp") <= 2 and has["huituo_recover"] then return "huituo_recover" end
	if has["huituo_draw"] then return "huituo_draw" end
	if has["huituo_equip"] then return "huituo_equip" end
	if has["huituo_recover"] and target and q(target,"isWounded") then return "huituo_recover" end
	if has["huituo_acquire"] and target and target:objectName() ~= q(self.player,"objectName") then return "huituo_acquire" end
	return "cancel"
end

sgs.ai_skill_playerchosen.sk_xingshuai = function(self, targets)
	for _, t in sgs.qlist(targets) do
		if q(self,"isFriend",t) and not q(t,"faceUp") then return t end
	end
	for _, t in sgs.qlist(targets) do
		if q(self,"isEnemy",t) and q(t,"faceUp") then return t end
	end
	for _, t in sgs.qlist(targets) do
		if q(self,"isEnemy",t) then return t end
	end
	return nil
end
sgs.ai_playerchosen_intention.sk_xingshuai = 40

sgs.ai_skill_choice["sk_xingshuai"] = function(self, choices, data)
	local caorui = q(self.room,"findPlayerBySkillName","sk_xingshuai")
	if not q(self.player,"faceUp") then return "xingshuai_turnover" end
	if caorui and q(self,"isFriend",caorui) then return "xingshuai_extraturn" end
	return "xingshuai_turnover"
end


--曹休：讨袭
sgs.ai_fill_skill.sk_taoxi = function(self, inclusive, request)
	if q(self.player,"hasUsed","#sk_taoxiCard") then return nil end
	return seed(self,"#sk_taoxiCard:.:")
end

sgs.ai_skill_use_func["#sk_taoxiCard"] = function(card, use, self)
	local n = 0
	for _, e in ipairs(self.enemies) do
		if not q(e,"isKongcheng") then n = n + 1 end
	end
	if n == 0 then return nil end
	use.card = card
end

sgs.ai_use_value["sk_taoxiCard"] = 6
sgs.ai_use_priority["sk_taoxiCard"] = 9


--关羽：拖刀
sgs.ai_skill_cardask["@sk_tuodao"] = function(self, data, pattern, target)
	if target then
		for _, slash in ipairs(q(self,"getCards","Slash")) do
			if q(self,"isFriend",target) then
				return "."
			end
			if q(self,"slashIsEffective",slash, target) then
				return card_answer(slash)
			end
		end
		for _, slash in ipairs(q(self,"getCards","Slash")) do
			if not q(self,"isFriend",target) then return card_answer(slash) end
		end
	end
	return "."
end


--辛宪英：才鉴
sgs.ai_fill_skill.sk_caijian = function(self, inclusive, request)
	if q(self.player,"hasUsed","#sk_caijianCard") then return nil end
	return seed(self,"#sk_caijianCard:.:")
end

sgs.ai_skill_use_func["#sk_caijianCard"] = function(card, use, self)
	for _, e in ipairs(self.enemies) do
		if not q(e,"isNude") and q(e,"faceUp") then
			use.card = card
			if use.to then use.to:append(e) end
			return
		end
	end
	for _, e in ipairs(self.enemies) do
		if not q(e,"isNude") then
			use.card = card
			if use.to then use.to:append(e) end
			return
		end
	end
end

sgs.ai_use_value["sk_caijianCard"] = 6
sgs.ai_use_priority["sk_caijianCard"] = 6
sgs.ai_card_intention["sk_caijianCard"] = 60

sgs.ai_skill_playerchosen.sk_caijian = function(self, targets)
	for _, e in ipairs(self.enemies) do
		for _, t in sgs.qlist(targets) do
			if q(t,"objectName") == q(e,"objectName") and q(t,"faceUp") then return t end
		end
	end
	for _, e in ipairs(self.enemies) do
		for _, t in sgs.qlist(targets) do
			if q(t,"objectName") == q(e,"objectName") then return t end
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.sk_caijian = 60

sgs.ai_skill_cardchosen.sk_caijian = function(self, who, flags, reason, method)
	local cards = sgs.QList2Table(q(who,"getCards","he"))
	if #cards == 0 then return -1 end
	local suits = {}
	for _, id in sgs.qlist(q(self.player,"getPile","sk_jian")) do
		suits[q(face(self,id),"getSuit")] = true
	end
	q(self,"sortByKeepValue",cards)
	for i = #cards, 1, -1 do
		local c = cards[i]
		if q(c,"isKindOf","EquipCard") and q(c,"isBlack") and not suits[q(c,"getSuit")] then
			return q(c,"getEffectiveId")
		end
	end
	return q(cards[#cards],"getEffectiveId")
end


--辛宪英：智识
sgs.ai_fill_skill.sk_zhishi = function(self, inclusive, request)
	local suits = {}
	for _, id in sgs.qlist(q(self.player,"getPile","sk_jian")) do
		suits[q(face(self,id),"getSuit")] = id
	end
	local picked = {}
	for _, id in pairs(suits) do
		table.insert(picked, id)
		if #picked == 3 then break end
	end
	if #picked < 3 then return nil end
	return seed(self,"#sk_zhishiCard:" .. table.concat(picked, "+") .. ":")
end

sgs.ai_skill_use_func["#sk_zhishiCard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["sk_zhishiCard"] = 8
sgs.ai_use_priority["sk_zhishiCard"] = 9


--王朗：劝降
sgs.ai_fill_skill.sk_quanxiang = function(self, inclusive, request)
	if q(self.player,"isKongcheng") then return nil end
	return seed(self,"#sk_quanxiangCard:.:")
end

sgs.ai_skill_use_func["#sk_quanxiangCard"] = function(card, use, self)
	if q(self.player,"getMark","@sk_raoshe") > 4 then return nil end
	local max_num = 0
	for _, c in sgs.qlist(q(self.player,"getHandcards")) do
		max_num = math.max(max_num, q(c,"getNumber"))
	end
	if max_num + q(self.player,"getMark","@sk_raoshe") < 10 then return nil end
	for _, e in ipairs(self.enemies) do
		if not q(e,"isKongcheng") then
			use.card = card
			if use.to then use.to:append(e) end
			return
		end
	end
end

sgs.ai_use_value["sk_quanxiangCard"] = 6
sgs.ai_use_priority["sk_quanxiangCard"] = 5
sgs.ai_card_intention["sk_quanxiangCard"] = 80


--王朗：激词
sgs.ai_skill_invoke.sk_jici = function(self, data)
	if q(self.player,"getMark","@sk_raoshe") > 5 then return false end
	local damage = q(data,"toDamage")
	local n = (damage and damage.damage) or 1
	for _, c in sgs.qlist(q(self.player,"getHandcards")) do
		if q(c,"getNumber") >= 10 then return true end
	end
	return n >= 2 or q(self.player,"getHp") <= n
end


--sp姜维：才遇
sgs.ai_skill_invoke.sk_caiyu = function(self, data)
	local maxhp = q(self.player,"getMaxHp")
	if maxhp <= 1 then return false end
	if maxhp <= 2 and q(self.player,"getHp") <= 1 then return false end
	return true
end


--左慈：千幻
sgs.ai_skill_choice.sk_qianhuan = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "cancel") then return "cancel" end
	return items[math.random(1, #items)]
end


--吉平：毒治
sgs.ai_skill_invoke.sk_duzhi = function(self, data)
	for _, e in ipairs(self.enemies) do
		if q(e,"getHp") <= 2 or q(e,"isKongcheng") then return true end
	end
	return #self.enemies > 0 and q(self.player,"getHp") > 1
end

sgs.ai_skill_playerchosen.sk_duzhi = function(self, targets)
	local best = nil
	for _, e in ipairs(self.enemies) do
		for _, t in sgs.qlist(targets) do
			if q(t,"objectName") == q(e,"objectName") then
				if not best or q(t,"getHp") < q(best,"getHp") or (q(t,"getHp") == q(best,"getHp") and q(t,"isKongcheng")) then
					best = t
				end
			end
		end
	end
	return best
end
sgs.ai_playerchosen_intention.sk_duzhi = 80

sgs.ai_skill_cardask["@sk_duzhi-slash"] = function(self, data, pattern, target)
	if target and not q(self,"isFriend",target) then
		for _, slash in ipairs(q(self,"getCards","Slash")) do
			if q(self,"slashIsEffective",slash, target) then
				return card_answer(slash)
			end
		end
	end
	return "."
end


--何进：专擅
sgs.ai_skill_invoke.sk_zhuanshan = true

sgs.ai_skill_playerchosen.sk_zhuanshan = function(self, targets)
	for _, e in ipairs(self.enemies) do
		for _, t in sgs.qlist(targets) do
			if q(t,"objectName") == q(e,"objectName") and #q(t,"getEquips") > 0 then return t end
		end
	end
	for _, t in sgs.qlist(targets) do
		if q(t,"objectName") == q(self.player,"objectName") then return t end
	end
	return nil
end

sgs.ai_skill_cardchosen.sk_zhuanshan = function(self, who, flags, reason, method)
	if q(self,"isEnemy",who) then
		local armor = q(who,"getArmor")
		if armor then return q(armor,"getEffectiveId") end
		local equips = sgs.QList2Table(q(who,"getCards","e"))
		if #equips > 0 then return q(equips[1],"getEffectiveId") end
	end
	local cards = sgs.QList2Table(q(who,"getCards","h"))
	if #cards == 0 then cards = sgs.QList2Table(q(who,"getCards","he")) end
	if #cards == 0 then return -1 end
	q(self,"sortByKeepValue",cards)
	return q(cards[1],"getEffectiveId")
end


--蒯越：异度/诛暴
sgs.ai_skill_invoke.sk_yidu = true

sgs.ai_skill_invoke.sk_zhubao = true


--卢植：经纶/儒宗
sgs.ai_skill_invoke.sk_jinglun = true

sgs.ai_view_as["sk_ruzong"] = function(card, player, card_place, class_name)
	if card_place ~= sgs.Player_PlaceHand then return end
	local card_id = q(card,"getEffectiveId")
	if class_name == "Jink" and q(card,"isKindOf","Nullification") then
		return {name="jink",skill="sk_ruzong",suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={card_id}}
	elseif class_name == "Nullification" and q(card,"isKindOf","Jink") then
		return {name="nullification",skill="sk_ruzong",suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={card_id}}
	end
end


--于吉：蛊惑/符箓
sgs.ai_skill_invoke.sk_guhuo = function(self, data)
	local player = q(data,"toPlayer")
	if not player then return false end
	local max_card = q(self,"getMaxCard")
	if not max_card then return false end
	if q(max_card,"getNumber") >= 10 and q(self,"isEnemy",player) then return true end
	return q(max_card,"getNumber") >= 12
end

sgs.ai_skill_choice["sk_guhuo"] = function(self, choices, data)
	local list = type(choices) == "table" and choices or choices:split("+")
	for _, c in ipairs({"duel","dismantlement","snatch","fire_attack","slash"}) do
		for _, v in ipairs(list) do
			if v == c then return v end
		end
	end
	return list[1]
end

sgs.ai_skill_choice["sk_guhuo_slash"] = function(self, choices, data)
	local list = type(choices) == "table" and choices or choices:split("+")
	for _, c in ipairs({"fire_slash","thunder_slash","slash","normal_slash"}) do
		for _, v in ipairs(list) do
			if v == c then return v end
		end
	end
	return list[1]
end

sgs.ai_skill_playerchosen.sk_guhuo = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, t in ipairs(targets) do
		if q(self,"isEnemy",t) then return t end
	end
	return targets[1]
end

sgs.ai_skill_invoke.sk_fulu = true

--SP马超：雄烈
sgs.ai_skill_invoke.sk_xionglie = true
sgs.ai_skill_choice.sk_xionglie = function(self, choices, data)
 local use = q(data,"toCardUse")
 if use then
  for _, p in sgs.qlist(use.to) do
   if q(self,"isEnemy",p) and q(self,"getCardsNum","Jink",p) > 0 then return "no_response" end
  end
 end
 return "damage"
end

--董白：奢靡/狡慧
sgs.ai_skill_exchange.sk_shemi = function(self, pattern, max_num, min_num, expand_pile) return {} end
sgs.ai_skill_invoke.sk_jiaohui = true
sgs.ai_skill_choice.sk_jiaohui = function(self, choices, data)
 if q(self.player,"getHandcardNum") == q(self.player,"getHp") + 1 then return "discard" end
 return "draw"
end

--张梁：集军及主动衍生技能
sgs.ai_fill_skill.sk_jijun = function(self, inclusive, request)
 if q(self.player,"hasUsed","#sk_jijunCard") then return nil end
 local cards = sgs.QList2Table(q(self.player,"getHandcards"))
 table.sort(cards, function(a,b) return q(a,"getNumber") > q(b,"getNumber") end)
 local suits, ids = {}, {}
 for _, c in ipairs(cards) do
  local suit = q(c,"getSuit")
  if not suits[suit] and #ids < 4 and not q(c,"isKindOf","Peach") then
   suits[suit] = true; table.insert(ids, q(c,"getEffectiveId"))
  end
 end
 return seed(self,"#sk_jijunCard:" .. (#ids > 0 and table.concat(ids,"+") or ".") .. ":")
end
sgs.ai_skill_use_func["#sk_jijunCard"] = function(card, use, self) use.card = card end
sgs.ai_skill_choice.sk_jijun = function(self, choices, data)
 local list = type(choices) == "table" and choices or choices:split("+")
 for _, c in ipairs(list) do if c == "put" then return c end end
 return list[1]
end
sgs.ai_skill_choice.sk_jijun_basic = function(self, choices, data)
 local list = type(choices) == "table" and choices or choices:split("+")
 if q(self.player,"isWounded") then
  for _, c in ipairs(list) do if c == "peach" then return c end end
 end
 for _, wanted in ipairs({"slash","fire_slash","thunder_slash","normal_slash","analeptic"}) do
  for _, c in ipairs(list) do if c == wanted then return c end end
 end
 return list[1]
end
sgs.ai_skill_playerchosen.sk_jijun = function(self, targets)
 for _, p in sgs.qlist(targets) do if q(self,"isEnemy",p) then return p end end
 return nil
end
sgs.ai_skill_playerchosen.sk_zhangliang_leiji = function(self, targets)
 for _, p in sgs.qlist(targets) do if q(self,"isEnemy",p) then return p end end
 return nil
end
sgs.ai_skill_cardask["@sk_zhangliang_zhoufu"] = function(self, data)
 local current = q(self.room,"getCurrent")
 if current and q(self,"isEnemy",current) then
  local cards = sgs.QList2Table(q(self.player,"getHandcards"))
  q(self,"sortByKeepValue",cards)
  for _, c in ipairs(cards) do if not q(c,"isKindOf","Peach") then return card_answer(c) end end
 end
 return "."
end
sgs.ai_skill_invoke.sk_zhangliang_shendao = function(self, data)
 self.sk_zhangliang_shendao_judge = q(data,"toJudge")
 return q(self,"needRetrial",self.sk_zhangliang_shendao_judge)
end
sgs.ai_skill_askforag.sk_zhangliang_shendao = function(self, card_ids)
 local cards = {}
 for _, id in ipairs(card_ids) do table.insert(cards,face(self,id)) end
 local judge = self.sk_zhangliang_shendao_judge
 if judge then
  local id = q(self,"getRetrialCardId",cards,judge)
  if id and id >= 0 then return id end
 end
 return -1
end
sgs.ai_skill_askforag.sk_jijun = function(self, card_ids) return card_ids[1] end

--曹节：掷玺
sgs.ai_fill_skill.sk_zhixi = function(self, inclusive, request)
 if q(self.player,"hasUsed","#sk_zhixiCard") or q(q(self.player,"getPile","sk_xi"),"isEmpty") then return nil end
 return seed(self,"#sk_zhixiCard:.:")
end
sgs.ai_skill_use_func["#sk_zhixiCard"] = function(card, use, self)
 for _, p in ipairs(self.enemies) do
  if q(p,"isAlive") then use.card = card; if use.to then use.to:append(p) end; return end
 end
end

--沮授：渐营/矢北
sgs.ai_skill_invoke.sk_jianying = true
sgs.ai_skill_invoke.sk_shibei = true
sgs.ai_skill_use["@@sk_shibei"] = function(self, prompt)
 local cards = sgs.QList2Table(q(self.player,"getCards","he"))
 q(self,"sortByKeepValue",cards)
 for _, material in ipairs(cards) do
  local card = q(self,"evaluateSkillCard","sk_shibei",nil,{q(material,"getEffectiveId")})
  local use = {isDummy = true, to = sgs.SPlayerList()}
  q(self,"useCardByClassName",card,use)
  if use.card then
   local targets = {}
   for _, p in sgs.qlist(use.to) do table.insert(targets,q(p,"objectName")) end
   return {kind="use_card",card_spec=q(card,"toCardSpec"),targets=targets}
  end
 end
 return "."
end

--严颜：拒战
sgs.ai_skill_invoke.sk_juzhan = function(self, data)
 return q(self.player,"getLostHp") > 0 or q(self,"getCardsNum","Jink") > 0
end
sgs.ai_skill_choice.sk_juzhan = function(self, choices, data)
 local x = q(data,"toInt")
 if x == 0 then return "discard" end
 local count = hand_count(self.player)
 if count >= x and (x <= 1 or count - x >= 3) then return "discard" end
 return "end"
end

--诸葛瞻：妖智
sgs.ai_skill_invoke.sk_yaozhi = true
sgs.ai_fill_skill.sk_yaozhi = function(self, inclusive, request)
 if not q(self.player,"hasUsed","#sk_yaozhiCard") then return seed(self,"#sk_yaozhiCard:.:" ) end
end
sgs.ai_skill_use_func["#sk_yaozhiCard"] = function(card, use, self) use.card = card end

--潘璋：截军
sgs.ai_skill_cardask["@sk_jiejun"] = function(self, data, pattern, target)
 if target and q(self,"isEnemy",target) then
  for _, card in ipairs(sgs.QList2Table(q(self.player,"getHandcards"))) do
   if q(card,"isKindOf","Slash") and q(self,"slashIsEffective",card,target) then return card_answer(card) end
  end
 end
 return "."
end

--孙茹：撷翠/忧恤
sgs.ai_skill_use["@@sk_xiecui"] = function(self, prompt)
 local cards = sgs.QList2Table(q(self.player,"getCards","he")); q(self,"sortByKeepValue",cards)
 for i, a in ipairs(cards) do
  for j = i + 1, #cards do
   local b = cards[j]
   if q(a,"getSuit") ~= q(b,"getSuit") and not q(self.player,"isJilei",a) and not q(self.player,"isJilei",b) then
    return {kind="use_card",card_spec="#sk_xiecuiCard:" .. q(a,"getEffectiveId") .. "+" .. q(b,"getEffectiveId") .. ":",targets={}}
   end
  end
 end
 return "."
end
sgs.ai_skill_choice.sk_xiecui = function(self, choices, data)
 local damage = q(data,"toDamage")
 return damage and q(self,"isEnemy",damage.to) and "increase" or "decrease"
end
sgs.ai_skill_invoke.sk_youxu = true
sgs.ai_skill_choice.sk_youxu = function(self, choices, data)
 local target = q(data,"toPlayer")
 return target and q(target,"isWounded") and q(self,"isFriend",target) and "peach" or "amazing_grace"
end

--岑昏：极奢
sgs.ai_fill_skill.sk_jishe = function(self, inclusive, request)
 if q(self.player,"getMark","sk_jishe_count") >= q(self.player,"getMaxHp") then return end
 for _, name in ipairs({"ex_nihilo", "snatch", "dismantlement", "iron_chain", "god_salvation", "amazing_grace", "fire_attack"}) do
  local card = q(self,"evaluateSkillCard","sk_jishe",name,{})
  local use = {isDummy = true, to = sgs.SPlayerList()}
  q(self,"useCardByClassName",card,use)
  if use.card then return card end
 end
end

--刘焉：逐鹿/立牧
sgs.ai_skill_invoke.sk_zhulu = function(self, data)
 return q(self,"isEnemy",q(data,"toDamage").to)
end
sgs.ai_fill_skill.sk_limu = function(self, inclusive, request)
 if q(self.player,"hasUsed","#sk_limuCard") or q(self.player,"containsTrick","indulgence") then return end
 local cards = sgs.QList2Table(q(self.player,"getCards","he"))
 local best
 for _, card in ipairs(cards) do
  if q(card,"getSuit") == sgs.Card_Diamond and (not best or q(card,"getNumber") > q(best,"getNumber")) then best = card end
 end
 if best then return seed(self,"#sk_limuCard:" .. q(best,"getEffectiveId") .. ":") end
end
sgs.ai_skill_use_func["#sk_limuCard"] = function(card, use, self) use.card = card end

--公孙渊：怀异
sgs.ai_fill_skill.sk_huaiyi = function(self, inclusive, request)
 if not q(self.player,"hasUsed","#sk_huaiyiCard") then return seed(self,"#sk_huaiyiCard:.:") end
end
sgs.ai_skill_use_func["#sk_huaiyiCard"] = function(card, use, self)
 local enemies = self.enemies
 q(self,"sort",enemies,"defense")
 for _, target in ipairs(enemies) do
  if q(target,"getCardCount",true) > 0 then use.card = card; use.to:append(target); return end
 end
end

--南华老仙：仙授；天道为锁定技，保留其必要的目标选择。
sgs.ai_skill_invoke.sk_xianshou = true
sgs.ai_skill_playerchosen.sk_xianshou = function(self, targets)
 for _, target in sgs.qlist(targets) do
  if q(self,"isFriend",target) and not q(target,"hasSkill","sk_tiandao") then return target end
 end
 for _, target in sgs.qlist(targets) do if q(self,"isFriend",target) then return target end end
 return targets:first()
end
sgs.ai_skill_playerchosen.sk_tiandao = function(self, targets)
 for _, target in sgs.qlist(targets) do if q(self,"isEnemy",target) then return target end end
 return targets:first()
end

sgs.ai_skill_invoke.sk_jueyong = true
sgs.ai_fill_skill.sk_choujue = function(self)
 if not q(self.player,"hasUsed","#sk_choujueCard") and q(self.player,"getMaxHp") > 1 then return seed(self,"#sk_choujueCard:.:") end
end
sgs.ai_skill_use_func["#sk_choujueCard"] = function(card, use, self)
 for _, target in ipairs(self.enemies) do
  if not q(self.player,"isProhibited",target,evaluation(self,"slash")) then use.card = card; use.to:append(target); return end
 end
end

sgs.ai_skill_invoke.sk_danxin = true
sgs.ai_fill_skill.sk_jiaozhao = function(self)
 if q(self.player,"getMark","sk_jiaozhao_used") > 0 then return end
 local cards = sgs.QList2Table(q(self.player,"getHandcards")); q(self,"sortByKeepValue",cards)
 for _, material in ipairs(cards) do
  for _, name in ipairs({"snatch", "dismantlement", "slash", "duel"}) do
   local card = q(self,"evaluateSkillCard","sk_jiaozhao",name,{q(material,"getEffectiveId")})
   local use = {isDummy = true, to = sgs.SPlayerList()}; q(self,"useCardByClassName",card,use)
   if use.card and not use.to:isEmpty() then return card end
  end
 end
end

sgs.ai_skill_invoke.sk_dingguan = function(self, data)
 for _, p in sgs.qlist(q(data,"toCardUse").to) do if q(self,"isFriend",p) then return true end end
 return false
end
sgs.ai_skill_choice.sk_dingguan = function(self, choices, data) return q(self,"isFriend",q(data,"toPlayer")) and "draw" or "cancel" end
sgs.ai_fill_skill.sk_huomo = function(self)
 local cards = sgs.QList2Table(q(self.player,"getCards","he")); q(self,"sortByKeepValue",cards)
 for _, material in ipairs(cards) do
  if q(material,"isBlack") then
   for _, name in ipairs({"peach", "fire_slash", "thunder_slash", "slash", "analeptic"}) do
    if q(self.player,"getMark","sk_huomo_" .. name) == 0 then
     local card = q(self,"evaluateSkillCard","sk_huomo",name,{q(material,"getEffectiveId")})
     local use = {isDummy = true, to = sgs.SPlayerList()}; q(self,"useCardByClassName",card,use)
     if use.card then return card end
    end
   end
  end
 end
end
sgs.ai_view_as.sk_huomo = function(card, player, place, class_name)
 local name = ({Slash="slash", Jink="jink", Peach="peach", Analeptic="analeptic"})[class_name]
 if name and q(card,"isBlack") and q(player,"getMark","sk_huomo_" .. name) == 0 then
  return q(own_ai(player),"evaluateSkillCard","sk_huomo",name,{q(card,"getEffectiveId")})
 end
end

sgs.ai_skill_invoke.sk_fuhan = true
sgs.ai_skill_invoke.sk_fanghun = function(self, data) return q(self,"isEnemy",q(data,"toPlayer")) end
sgs.ai_fill_skill.sk_fanghun = function(self)
 for _, c in sgs.qlist(q(self.player,"getCards","he")) do
  if q(c,"isKindOf","Jink") then return q(self,"evaluateSkillCard","sk_fanghun","slash",{q(c,"getEffectiveId")}) end
 end
end
sgs.ai_view_as.sk_fanghun = function(card, player, place, class_name)
 local name = class_name == "Slash" and q(card,"isKindOf","Jink") and "slash" or class_name == "Jink" and q(card,"isKindOf","Slash") and "jink"
 if name then return q(own_ai(player),"evaluateSkillCard","sk_fanghun",name,{q(card,"getEffectiveId")}) end
end

sgs.ai_fill_skill.sk_wurong = function(self)
 if not q(self.player,"hasUsed","#sk_wurongCard") then return seed(self,"#sk_wurongCard:.:" ) end
end
sgs.ai_skill_use_func["#sk_wurongCard"] = function(card, use, self)
 for _, p in ipairs(self.enemies) do
  if not q(p,"isKongcheng") then use.card = card; if use.to then use.to:append(p) end; return end
 end
end
sgs.ai_skill_invoke.sk_wurong = true
sgs.ai_skill_cardask["@sk_wurong-discard"] = function(self)
 local cards = sgs.QList2Table(q(self.player,"getHandcards")); q(self,"sortByKeepValue",cards)
 if #cards > 0 then return "$" .. q(cards[1],"getEffectiveId") end
 return "."
end
sgs.ai_skill_choice.sk_wurong = function(self, choices) return choices:split("+")[1] end
sgs.ai_use_value.sk_wurongCard = 5
sgs.ai_use_priority.sk_wurongCard = 4

sgs.ai_fill_skill.sk_dingpin = function(self)
 local cards = sgs.QList2Table(q(self.player,"getHandcards")); q(self,"sortByKeepValue",cards)
 for _, c in ipairs(cards) do if not q(self.player,"isJilei",c) then return seed(self,"#sk_dingpinCard:" .. q(c,"getEffectiveId") .. ":") end end
end
sgs.ai_skill_use_func["#sk_dingpinCard"] = function(card, use, self)
 for _, p in ipairs(self.friends_noself) do
  if q(p,"getMark","sk_dingpin_" .. q(self.player,"objectName")) == 0 then use.card = card; if use.to then use.to:append(p) end; return end
 end
 for _, p in ipairs(self.enemies) do
  if q(p,"getMark","sk_dingpin_" .. q(self.player,"objectName")) == 0 then use.card = card; if use.to then use.to:append(p) end; return end
 end
end
sgs.ai_skill_choice.sk_dingpin = function(self, choices, data) return q(self,"isFriend",q(data,"toPlayer")) and "draw" or "discard" end
sgs.ai_skill_invoke.sk_faen = function(self, data) return q(self,"isFriend",q(data,"toPlayer")) end
sgs.ai_use_value.sk_dingpinCard = 6
sgs.ai_use_priority.sk_dingpinCard = 4

sgs.ai_fill_skill.sk_sanjue = function(self)
 if not q(self.player,"hasUsed","#sk_sanjueCard") then return seed(self,"#sk_sanjueCard:.:") end
end
sgs.ai_skill_use_func["#sk_sanjueCard"] = function(card, use, self)
 use.card = card
 if use.to then use.to:append(self.player) end
end
sgs.ai_skill_choice.sk_sanjue = function(self, choices, data)
 local target = q(data,"toPlayer")
 for _, name in ipairs(choices:split("+")) do
  if target and not q(target,"hasSkill",name) then return name end
 end
 return choices:split("+")[1]
end
sgs.ai_use_value.sk_sanjueCard = 8
sgs.ai_use_priority.sk_sanjueCard = 7

sgs.ai_skill_invoke.sk_zhendu = function(self, data)
 local target = q(data,"toPlayer")
 return target == self.player or q(self,"isEnemy",target) or (q(self,"isFriend",target) and q(target,"getHp") > 2)
end
sgs.ai_skill_playerchosen.sk_qiluan = function(self, targets)
 for _, p in sgs.qlist(targets) do if q(self,"isEnemy",p) then return p end end
 if q(self.room,"getTag","sk_qiluan_changes"):toInt() > 0 then return targets:first() end
end

sgs.ai_skill_invoke.sk_canshi = true
sgs.ai_skill_playerchosen.sk_xianji = function(self, targets)
 local best, count
 for _, p in sgs.qlist(targets) do
  local n = q(p,"getSkillList",false,false):length()
  if q(self,"isEnemy",p) and (not count or n > count) then best = p; count = n end
 end
 return best
end

sgs.ai_skill_invoke.sk_xuxie_draw = function(self, data) return q(data,"toCardUse").to:length() > 0 end

sgs.ai_skill_invoke.sk_jili = function(self)
 local score = 0
 for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
  if q(self.player,"inMyAttackRange",p) and not q(p,"isNude") then
   score = score + (q(self,"isEnemy",p) and 1 or -1)
  end
 end
 return score > 0
end

sgs.ai_skill_invoke.sk_fengyin = function(self, data)
 return q(self,"isEnemy",q(data,"toDamage").to)
end

sgs.ai_skill_playerchosen.sk_qinqing = function(self, targets)
 local best, score
 for _, p in sgs.qlist(targets) do
  if q(self,"isFriend",p) then
   local n = q(p,"isWounded") and 1 or 0
   for _, other in sgs.qlist(q(self.room,"getAlivePlayers")) do
    if q(other,"inMyAttackRange",p) and not q(other,"isNude") then n = n + (q(self,"isEnemy",other) and 2 or 1) end
   end
   if not score or n > score then best = p; score = n end
  end
 end
 return best
end
sgs.ai_skill_invoke.sk_qinqing_recover = function(self, data) return q(self,"isFriend",q(data,"toPlayer")) end
sgs.ai_skill_exchange.sk_qinqing = function(self)
 local cards = sgs.QList2Table(q(self.player,"getCards","he")); q(self,"sortByKeepValue",cards)
 return #cards > 0 and {q(cards[1],"getEffectiveId")} or {}
end
sgs.ai_skill_exchange.sk_huisheng = function(self)
 local cards = sgs.QList2Table(q(self.player,"getHandcards")); q(self,"sortByKeepValue",cards)
 local ids = {}
 for i = 1, math.min(3,#cards) do table.insert(ids,q(cards[i],"getEffectiveId")) end
 return ids
end
sgs.ai_skill_choice.sk_huisheng = function(self, choices, data)
 if q(self,"isFriend",q(data,"toPlayer")) or q(self.player,"getCardCount",true) < 3 then return "obtain" end
 return "discard"
end
sgs.ai_skill_askforag.sk_huisheng = function(self, ids)
 local best, value
 for _, id in ipairs(ids) do
  local c = face(self,id); local v = q(self,"getUseValue",c)
  if not value or v > value then best = id; value = v end
 end
 return best
end

sgs.ai_skill_playerchosen.sk_qianchong = function(self, targets)
 local red = (self.request.prompt or ""):find("sk_qianchong-red", 1, true) ~= nil
 local best, score
 for _, p in sgs.qlist(targets) do
  if (red and q(self,"isFriend",p)) or (not red and q(self,"isEnemy",p)) then
   local n = red and (q(p,"isWounded") and 10 or q(p,"getMaxHp")) or (10 - q(p,"getHp"))
   if not score or n > score then best = p; score = n end
  end
 end
 return best
end
sgs.ai_skill_choice.sk_qianchong = function(self, choices, data)
 local p = q(data,"toPlayer")
 if choices:find("recover") then
  return q(p,"getLostHp") >= 2 and "recover" or "draw"
 end
 return (q(p,"getHp") <= 2 or q(p,"getCardCount",true) < q(p,"getMaxHp")) and "losehp" or "discard"
end
sgs.ai_skill_exchange.sk_shangjian = function(self, pattern, max_num)
 local cards = sgs.QList2Table(q(self.player,"getHandcards")); q(self,"sortByKeepValue",cards)
 local ids = {}
 for i = 1, math.min(max_num,#cards) do table.insert(ids,q(cards[i],"getEffectiveId")) end
 return ids
end
sgs.ai_skill_askforyiji.sk_shangjian = function(self, ids)
 for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
  if q(self,"isFriend",p) then return p, ids[1] end
 end
 local others = q(self.room,"getOtherPlayers",self.player)
 if not others:isEmpty() then return others:first(), ids[1] end
end
sgs.ai_skill_playerchosen.sk_shangjian = function(self, targets)
 for _, p in sgs.qlist(targets) do if q(self,"isFriend",p) then return p end end
 return targets:first()
end

sgs.ai_skill_playerchosen.sk_guolun = function(self, targets)
 local prompt = self.request.prompt or ""
 local benefit = prompt:find("draw", 1, true) or prompt:find("recover", 1, true)
 for _, p in sgs.qlist(targets) do
  if benefit and q(self,"isFriend",p) or not benefit and q(self,"isEnemy",p) then return p end
 end
end

sgs.ai_skill_invoke.sk_qinguo = true
sgs.ai_skill_playerchosen.sk_qinguo = function(self, targets)
 for _, p in sgs.qlist(targets) do if p == self.player then return p end end
end
sgs.ai_skill_choice.sk_qinguo = function(self, choices)
 local options = choices:split("+")
 if q(self.player,"isWounded") then for _, name in ipairs(options) do if name == "peach" then return name end end end
 for _, name in ipairs(options) do if name == "slash" then return name end end
 return "cancel"
end
sgs.ai_skill_use["@@sk_qinguo"] = function(self)
 local name = q(q(self.player,"getTag","sk_qinguo_card"),"toString")
 local card = q(self,"evaluateSkillCard","sk_qinguo",name,{})
 local use = {isDummy=true, to=sgs.SPlayerList()}
 q(self,"useBasicCard",card,use)
 if not use.card then return "." end
 local targets = {}
 for _, p in sgs.qlist(use.to) do table.insert(targets,q(p,"objectName")) end
 return {kind="use_card",card_spec=q(card,"toCardSpec"),targets=targets}
end

sgs.ai_skill_playerchosen.sk_zhukou = function(self, targets)
 local best
 for _, p in sgs.qlist(targets) do
  if q(self,"isEnemy",p) and (not best or q(p,"getHp") < q(best,"getHp")) then best = p end
 end
 return best
end
sgs.ai_skill_choice.sk_zhukou = function(self, choices, data)
 return q(self,"isEnemy",q(data,"toPlayer")) and "repeat" or "done"
end
sgs.ai_skill_invoke.sk_duannian = function(self)
 if q(self.player,"isWounded") then return true end
 local cards = sgs.QList2Table(q(self.player,"getHandcards"))
 local value = 0
 for _, card in ipairs(cards) do value = value + q(self,"getKeepValue",card) end
 return #cards == 0 or value / #cards < 4
end
sgs.ai_skill_choice.sk_duannian = function(self)
 return q(self.player,"isWounded") and "recover" or "use"
end

sgs.ai_skill_use["@@sk_duannian"] = function(self)
 local cards = sgs.QList2Table(q(self.player,"getHandcards")); q(self,"sortByUseValue",cards)
 for _, material in ipairs(cards) do
  local card = q(self,"evaluateSkillCard","sk_duannian",nil,{q(material,"getEffectiveId")})
  local use = {isDummy=true,to=sgs.SPlayerList()}
  q(self,"useCardByClassName",card,use)
  if use.card then
   local targets = {}
   for _, p in sgs.qlist(use.to) do table.insert(targets,q(p,"objectName")) end
   return {kind="use_card",card_spec=q(card,"toCardSpec"),targets=targets}
  end
 end
 return "."
end

local sk_yanjiao_skill = {name = "sk_yanjiao"}
table.insert(sgs.ai_skills, sk_yanjiao_skill)
sk_yanjiao_skill.getTurnUseCard = function(self)
 if q(self.player,"getMark","sk_yanjiao_1") > 0 then return end
 local best
 for _, c in sgs.qlist(q(self.player,"getHandcards")) do
  if not best or q(c,"getNumber") > q(best,"getNumber") then best = c end
 end
 if best then return seed(self,"#sk_yanjiaoCard:" .. q(best,"getEffectiveId") .. ":") end
end
sgs.ai_skill_use_func["#sk_yanjiaoCard"] = function(card, use, self)
 local targets = q(self.player,"getMark","&sk_xingshen") > 0 and self.enemies or self.friends_noself
 if #targets > 0 then use.card = card; if use.to then use.to:append(targets[1]) end end
end
sgs.ai_skill_invoke.sk_yanjiao = function(self, data) return q(self,"isEnemy",q(data,"toPlayer")) end

sgs.ai_skill_invoke.sk_jingce = true
sgs.ai_skill_choice.sk_jingce = function(self, choices)
 local options = choices:split("+")
 for _, choice in ipairs(options) do if choice == "draw" then return choice end end
 for _, choice in ipairs(options) do if choice == "maxhp" then return choice end end
 return options[1]
end

sgs.ai_skill_invoke.sk_juyi = function(self) return q(self.player,"getMaxHp") > 2 end

sgs.ai_skill_playerchosen.sk_yuqi = function(self, targets)
 local best
 for _, p in sgs.qlist(targets) do
  if q(self,"isEnemy",p) and (not best or q(p,"getHp") < q(best,"getHp")) then best = p end
 end
 if q(self.player,"getHp") <= 1 and q(self.player,"getPhase") ~= sgs.Player_NotActive then return nil end
 return best
end

sgs.ai_skill_invoke.sk_tianbian = true
sgs.ai_skill_askforag.sk_tianbian = function(self, ids)
 local best, value
 for _, id in ipairs(ids) do
  local c = q(sgs.Sanguosha,"getCard",id)
  local v = q(self.player,"getPhase") == sgs.Player_NotActive and q(self,"getUseValue",c) or q(c,"getNumber")
  if not value or v > value then best, value = id, v end
 end
 return best or -1
end
sgs.ai_skill_invoke.sk_jianzheng = function(self, data)
 local use = q(data,"toCardUse")
 return use and q(self,"isEnemy",use.from)
end
sgs.ai_skill_invoke.sk_jianzheng_reselect = true
sgs.ai_skill_playerchosen.sk_jianzheng = function(self, targets)
 for _, p in sgs.qlist(targets) do if q(self,"isEnemy",p) then return p end end
 return nil
end

sgs.ai_skill_invoke.sk_tunan = function(self, data)
 local source = q(data,"toPlayer")
 local target = source and q(source,"getNextAlive")
 return source and target and q(self,"isFriend",source) and q(self,"isEnemy",target)
end
sgs.ai_skill_choice.sk_tunan = function(self, choices, data)
 local source = q(data,"toPlayer")
 local target = source and q(source,"getNextAlive")
 if choices:find("snatch") and target and not q(target,"isNude") then return "snatch" end
 return choices:split("+")[1]
end
sgs.ai_skill_invoke.sk_bijing = function(self, data)
 local use = q(data,"toCardUse")
 return use and q(self,"isEnemy",use.from)
end

sgs.ai_skill_playerchosen.sk_youyan = function(self, targets)
 local best
 for _, p in sgs.qlist(targets) do
  if q(self,"isFriend",p) then best = p; break end
 end
 return best or targets:first()
end
sgs.ai_skill_invoke.sk_zhuihuan = function(self)
 local score = 0
 for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
  if q(p,"getMark","sk_zhuihuan_pending_" .. q(self.player,"objectName")) > 0 then
   score = score + (q(self,"isEnemy",p) and 2 or -2)
  end
 end
 return score > 0
end

sgs.ai_skill_invoke.sk_ciwei = function(self, data)
 local use = q(data,"toCardUse")
 if not use or not use.card then return false end
 local changed = q(q(use.card,"getTag","sk_ciwei_changed"),"toBool")
 return changed and q(self,"isEnemy",use.from) or not changed and q(self,"isFriend",use.from)
end
sgs.ai_skill_invoke.sk_caiyuan = true
sgs.ai_skill_playerchosen.sk_caiyuan = function(self, targets)
 for _, p in sgs.qlist(targets) do if q(self,"isEnemy",p) then return p end end
 return targets:first()
end

sgs.ai_skill_invoke.sk_luanzhan = function(self, data)
 local use = q(data,"toCardUse")
 if not use or not use.card then return false end
 local card = use.card
 if q(card,"isKindOf","ExNihilo") or q(card,"isKindOf","GodSalvation") or q(card,"isKindOf","AmazingGrace") then return true end
 if q(card,"isKindOf","Slash") or q(card,"isKindOf","Duel") or q(card,"isKindOf","AOE") or q(card,"isKindOf","FireAttack") then
  return q(self,"isEnemy",use.from) and q(self.player,"getHp") > 2
 end
 return q(self.player,"getHp") > 1
end

sgs.ai_skill_invoke.sk_jixu = true
sgs.ai_skill_playerchosen.sk_jixu_slash = function(self, targets)
 for _, p in sgs.qlist(targets) do if q(self,"isEnemy",p) then return p end end
 return nil
end
sgs.ai_skill_playerchosen.sk_jixu_transfer = sgs.ai_skill_playerchosen.sk_jixu_slash

sgs.ai_skill_playerchosen.sk_zhengu = function(self, targets)
 local x = q(self.player,"getHandcardNum"); local delta = q(self.player,"isWounded") and 2 or 1
 local best, score = nil, 0
 for _, p in sgs.qlist(targets) do
  local n = q(p,"getHandcardNum")
  local value = q(self,"isFriend",p) and x + delta - n or q(self,"isEnemy",p) and n - math.max(0,x-delta) or 0
  if value > score then best, score = p, value end
 end
 return best
end
sgs.ai_skill_choice.sk_zhengu = function(self, choices, data)
 return q(self,"isFriend",q(data,"toPlayer")) and "increase" or "decrease"
end

sgs.ai_skill_invoke.sk_sanchen = true
sgs.ai_skill_invoke.sk_sanchen_draw = function(self, data) return q(self,"isFriend",q(data,"toPlayer")) end
sgs.ai_fill_skill.sk_pozhu = function(self)
 if q(self.player,"usedTimes","#sk_pozhuCard") >= 3 then return end
 local cards = sgs.QList2Table(q(self.player,"getHandcards")); q(self,"sortByKeepValue",cards)
 for _, c in ipairs(cards) do
  if q(c,"isKindOf","TrickCard") and not q(self.player,"isJilei",c) then return seed(self,"#sk_pozhuCard:" .. q(c,"getEffectiveId") .. ":") end
 end
end
sgs.ai_skill_use_func["#sk_pozhuCard"] = function(card, use, self)
 for _, p in ipairs(self.enemies) do
  if q(self.player,"inMyAttackRange",p) and (q(p,"getMark","sk_pozhu_damage_" .. q(self.player,"objectName")) > 0 or q(self,"getKnownCard",p,self.player,"TrickCard",false,"h") > 0) then
   use.card = card; if use.to then use.to:append(p) end; return
  end
 end
end
sgs.ai_use_value.sk_pozhuCard = 5
sgs.ai_use_priority.sk_pozhuCard = 3

sgs.ai_fill_skill.sk_junbing = function(self)
 if q(self.player,"hasUsed","#sk_junbingCard") then return end
 local cards = sgs.QList2Table(q(self.player,"getHandcards")); q(self,"sortByKeepValue",cards)
 for _, c in ipairs(cards) do
  if q(c,"isKindOf","Slash") and not q(self.player,"isJilei",c) then return seed(self,"#sk_junbingCard:" .. q(c,"getEffectiveId") .. ":") end
 end
end
sgs.ai_skill_playerchosen.sk_junbing = function(self, targets)
 local best = self.player
 for _, p in sgs.qlist(targets) do if q(self,"isFriend",p) and q(p,"getKingdom") == "wei" then best = p; break end end
 return best
end
sgs.ai_skill_use_func["#sk_junbingCard"] = function(card, use, self)
 use.card = card
 if use.to then use.to:append(sgs.ai_skill_playerchosen.sk_junbing(self,q(self.room,"getAlivePlayers"))) end
end
sgs.ai_skill_cardask["@sk_junbing"] = function(self)
 for _, c in sgs.qlist(q(self.player,"getHandcards")) do
  if q(c,"isKindOf","Slash") and not q(self.player,"isJilei",c) then return "$" .. q(c,"getEffectiveId") end
 end
 return "."
end
sgs.ai_skill_cardask["@sk_quji"] = function(self, data)
 if not q(self,"isFriend",q(data,"toDamage").to) then return "." end
 for _, c in sgs.qlist(q(self.player,"getHandcards")) do
  if q(c,"isKindOf","Jink") and not q(self.player,"isJilei",c) then return "$" .. q(c,"getEffectiveId") end
 end
 return "."
end
sgs.ai_skill_choice.sk_quji = function(self, choices)
 if choices:find("draw") then return "draw" end
 return choices:split("+")[1]
end
sgs.ai_use_value.sk_junbingCard = 7
sgs.ai_use_priority.sk_junbingCard = 5

sgs.ai_skill_invoke.sk_caiyi = function(self)
 return q(self.player,"getHandcardNum") < 4
end
sgs.ai_skill_playerchosen.sk_caiyi = function(self, targets)
 for _, p in sgs.qlist(targets) do if q(self,"isEnemy",p) and q(p,"faceUp") then return p end end
 for _, p in sgs.qlist(targets) do if q(self,"isEnemy",p) then return p end end
 return targets:first()
end

sgs.ai_skill_playerchosen.sk_xunxian = function(self, targets)
 for _, p in sgs.qlist(targets) do if q(self,"isEnemy",p) then return p end end
end
sgs.ai_skill_cardask["@sk_xunxian-give"] = function(self, data)
 local use = q(data,"toCardUse"); local cards = sgs.QList2Table(q(self.player,"getCards","he"))
 q(self,"sortByKeepValue",cards)
 for _, c in ipairs(cards) do
  if q(c,"getNumber") ~= q(use.card,"getNumber") then return "$" .. q(c,"getEffectiveId") end
 end
 return "."
end

sgs.ai_skill_playerchosen.sk_fenyin = function(self, targets)
 for _, p in sgs.qlist(targets) do if q(self,"isEnemy",p) and q(self,"damageIsEffective",p,sgs.DamageStruct_Normal,self.player) then return p end end
end

sgs.ai_skill_playerchosen.sk_qingyuan = function(self, targets)
 for _, p in sgs.qlist(targets) do if q(self,"isEnemy",p) then return p end end
 return targets:first()
end
sgs.ai_skill_playerchosen.sk_zhongshen = function(self, targets)
 for _, p in sgs.qlist(targets) do if q(self,"isFriend",p) then return p end end
end
sgs.ai_view_as.sk_zhongshen = function(card, player, place, class_name)
 if class_name == "Peach" and q(card,"isRed") then return q(own_ai(player),"evaluateSkillCard","sk_zhongshen","peach",{q(card,"getEffectiveId")}) end
end
sgs.ai_fill_skill.sk_zhongshen = function(self)
 if not q(self.player,"isWounded") then return end
 local cards = sgs.QList2Table(q(self.player,"getCards","he")); q(self,"sortByKeepValue",cards)
 for _, c in ipairs(cards) do if q(c,"isRed") then return q(self,"evaluateSkillCard","sk_zhongshen","peach",{q(c,"getEffectiveId")}) end end
end

local sk_qianxi_ai = {name = "sk_qianxi"}
table.insert(sgs.ai_skills, sk_qianxi_ai)
sk_qianxi_ai.getTurnUseCard = function(self)
 if q(self.player, "getMark", "sk_qianxi_phase_used") == 0 then return seed(self, "#sk_qianxiCard:.:" ) end
end
sgs.ai_skill_use_func["#sk_qianxiCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.sk_qianxiCard = 9
sgs.ai_skill_cardask["@sk_qianxi"] = function(self)
 local cards = sgs.QList2Table(q(self.player, "getHandcards"))
 q(self, "sortByUseValue", cards)
 for _, c in ipairs(cards) do if q(c, "isKindOf", "Slash") then return "$" .. q(c, "getEffectiveId") end end
 if #cards > 0 then return "$" .. q(cards[1], "getEffectiveId") end
 return "."
end

sgs.ai_skill_cardask["@sk_biluan"] = function(self)
 local cards = sgs.QList2Table(q(self.player, "getCards", "he"))
 q(self, "sortByKeepValue", cards)
 for _, c in ipairs(cards) do
  if not q(self.player, "isJilei", c) then return "$" .. q(c, "getEffectiveId") end
 end
 return "."
end
sgs.ai_skill_invoke.sk_lixia = function(self, data) return q(self, "isFriend", q(data, "toPlayer")) end
sgs.ai_skill_choice.sk_lixia = function(self, choices)
 local names = choices:split("+")
 for _, name in ipairs(names) do if name == "sk_biluan" then return name end end
 return names[1]
end

sgs.ai_skill_cardask["@sk_zhenyi"] = function(self, data)
 local d = q(data, "toDamage")
 if d.damage == 1 and q(self.player, "getHp") > 2 then return "." end
 local cards = sgs.QList2Table(q(self.player, "getHandcards"))
 q(self, "sortByKeepValue", cards)
 for _, c in ipairs(cards) do if not q(self.player, "isJilei", c) then return "$" .. q(c, "getEffectiveId") end end
 return "."
end
sgs.ai_skill_invoke.sk_zhenyi_remove = function(self, data) return q(self, "isEnemy", q(data, "toPlayer")) end
sgs.ai_skill_cardask["@sk_dianhua"] = function(self, data, pattern, target)
 if not target or not q(self, "isFriend", target) then return "." end
 local cards = sgs.QList2Table(q(self.player, "getHandcards"))
 q(self, "sortByKeepValue", cards)
 for _, c in ipairs(cards) do if q(c, "getSuit") == sgs.Card_Heart and not q(self.player, "isJilei", c) then return "$" .. q(c, "getEffectiveId") end end
 return "."
end
sgs.ai_skill_choice.sk_dianhua_count = function(self, choices) local names = choices:split("+"); return names[#names] end
local function sk_ch4_skill_choice(self, choices)
 local names = choices:split("+")
 for _, wanted in ipairs({"sk_jizhi", "jizhi", "sk_yingzi", "yingzi", "rende", "zhiheng"}) do if table.contains(names, wanted) then return wanted end end
 return names[1]
end
sgs.ai_skill_choice.sk_falu_reserve = sk_ch4_skill_choice
sgs.ai_skill_choice.sk_falu_give = sk_ch4_skill_choice
sgs.ai_skill_choice.sk_dianhua = sk_ch4_skill_choice
sgs.ai_skill_playerchosen.sk_falu_damage = function(self, targets)
 local list = sgs.QList2Table(targets); q(self, "sort", list, "hp")
 for _, p in ipairs(list) do if q(self, "isEnemy", p) then return p end end
 return list[1]
end
sgs.ai_skill_playerchosen.sk_falu_give = function(self, targets)
 for _, p in sgs.qlist(targets) do if q(self, "isFriend", p) then return p end end
 return targets:first()
end

-- 极略67 周鲂
sgs.ai_skill_invoke.sk_duanfa = true
local sk_duanfa_ai = {name = "sk_duanfa"}
table.insert(sgs.ai_skills, sk_duanfa_ai)
sk_duanfa_ai.getTurnUseCard = function(self)
 if q(self.player, "getMark", "sk_duanfa_phase_used") == 0 then return seed(self, "#sk_duanfaCard:.:") end
end
sgs.ai_skill_use_func["#sk_duanfaCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.sk_duanfaCard = 9
sgs.ai_skill_playerchosen.sk_youdi = function(self, targets)
 for _, p in sgs.qlist(targets) do if q(self, "isEnemy", p) and not q(p, "isNude") then return p end end
 for _, p in sgs.qlist(targets) do if q(self, "isEnemy", p) then return p end end
end
