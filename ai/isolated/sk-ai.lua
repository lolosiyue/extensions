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
