-- Fixed b6025acc hayate. Preserve source terminal errors; no private priors.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported("hayate fact is unknown",k)end;return v end
local nullable={findPlayerToDamage=true,findPlayerToDraw=true,findPlayerToDiscard=true,findPlayerBySkillName=true,setStrategyPlayerFlag=true,toPlayer=true}
local sorted={sort=true,sortByKeepValue=true,sortByUseValue=true}
local function q(o,k,...)
    if not o or type(o[k])~="function"then ai_unsupported("hayate source helper unavailable",k)end
    local method=k;if k=="getMark"and AIValue.isPlayer(o)then method="getStrategyMark"end
    local v=o[method](o,...);if AIUnsupported.is(v)then error(v,0)end
    if sorted[k]then local t=(...);known(v,k);for i,c in ipairs(v)do t[i]=c end;return t end
    if k=="hasSkill"or k=="hasSkills"then
        local p=AIValue.isPlayer(o)and o or select(2,...)or o.player;local row=p and rawget(p,"_view")
        if v==false and row and row.skills_complete~=true then ai_unsupported("hayate foreign skill absence is unknown",(...))end
    end
    if nullable[k]then return v end;return known(v,k)
end
local function facts(self)return known(self.world.strategy_facts and self.world.strategy_facts.hayate,"hayate")end
local function owner_tag(self,key)return known(facts(self).owner_tags and facts(self).owner_tags[key],key)end
local function target_flag(self,p,flag)
    local rows=facts(self).target_flags;local row=rows and rows[flag]
    local value=row and row[q(p,"objectName")]
    if type(value)~="boolean"then ai_unsupported("hayate scoped public target flag missing",flag)end
    return value
end
local function response(self,skill,selector,costs,targets,request)
    local card=q(self,"bindSkillCard",skill,costs,request or self.request,nil,selector)
    return {kind="use_card",card_spec=q(card,"toCardSpec"),targets=targets}
end
local function role(self,p)return p==self.player and q(p,"getRole")or q(self,"getRoleEstimate",p)end
-- Native RoomRoster::findFirstBySkill scans current-first, not seat-first.
local function mishi_first_holder(self)
    for _,player in sgs.qlist(q(self.room,"getAllPlayers",false))do
        if q(player,"hasSkill","mishi")then return player end
    end
end
-- Mishi counts only public/owner current hand faces. A foreign complete
-- getKnownCards list is not exposed by PlayerView:getHandcards.
local function mishi_hand(self,p)
    local cards=p and p:getHandcards()
    if AIUnsupported.is(cards)then error(cards,0)end
    local total=q(p,"getHandcardNum")
    if type(total)~="number"or total~=total or total==math.huge or total<0 or total%1~=0 then
        ai_unsupported("mishi public hand count malformed","mishi")
    end
    if cards==nil then
        if total==0 then return {},0 end
        cards=q(p,"getKnownCards")
    end
    if #cards>total then ai_unsupported("mishi known hand exceeds current total","mishi")end
    local seen={}
    for _,card in sgs.qlist(cards)do
        local id=q(card,"getEffectiveId")
        if type(id)~="number"or id<0 or id%1~=0 or seen[id]then
            ai_unsupported("mishi known hand identity malformed","mishi")
        end
        seen[id]=true
    end
    return cards,total-#cards
end
local function mishi_partial_result(hp,rescue,jink,missing)
    -- Exact completion proof, not a private-card estimate. Rescue and Jink
    -- are disjoint native card classes; other cards may fill remaining slots.
    local function result(r,j)
        return hp>0 and (r>2 or r>1 and j>0)
            or hp>1 and (r>1 or r>0 and j>0)
            or hp>2 and (r>0 or j>0)
    end
    local base=result(rescue,jink)
    if base then return true end
    for r=0,math.min(3,missing)do
        for j=0,math.min(1,missing-r)do
            if result(rescue+r,jink+j)then
                ai_unsupported("mishi undisclosed cards can change the source result","mishi")
            end
        end
    end
    return false
end
local function require_enemy_nil(self)
    if facts(self).legacy_enemy_global_known_nil~=true then ai_unsupported("source vector typo reads an unclassified global enemy","vector")end
end

sgs.ai_keep_value.DoubleSword = 8

sgs.ai_skill_invoke.diansuo = function(self, data)
	local damage = q(data,"toDamage")
	if q(damage.from,"objectName") == q(self.player,"objectName") then
		if q(self,"isFriend",damage.to) and q(self.player,"getRole") ~= "renegade" then return false end
		return true
	else
		if q(self,"isFriend",damage.to) then return true end
		return false
	end
end

sgs.ai_skill_playerchosen.diansuo = function(self, targets)
	if q(self.player,"isChained") then
		if q(self.player,"getRole") == "renegade" then
			for _, target in sgs.qlist(targets) do
				if q(self,"isEnemy",target) then return target end
			end
		end
		if q(self.player,"getRole") == "loyalist" then
			for _, target in sgs.qlist(targets) do
				if q(target,"isLord") then return target end
			end
		end
		if q(self.player,"getRole") == "rebel" then
			for _, target in sgs.qlist(targets) do
				if role(self,target) == "loyalist" then return target end
			end
		end
		for _, target in sgs.qlist(targets) do
			if q(self.player,"objectName") ~= q(target,"objectName") then return target end
		end
	else
		return q(self,"findPlayerToDamage",nil, nil, nil, targets)
	end

end

sgs.ai_skill_invoke.bimie = function(self, data)
	local damage = q(data,"toDamage")
	local target = damage.to
	if q(self,"isEnemy",target) then
		return true
	end
	return false
end

sgs.ai_skill_invoke.gangqu = function(self, data)
	for _,card in sgs.qlist(q(self.player,"getHandcards")) do
		if q(card,"isKindOf","BasicCard") or q(card,"isKindOf","TrickCard") then
			return true
		end
	end
	return false
end

sgs.ai_skill_invoke.gangquPrevent = function(self, data)
	local effect = q(data,"toCardEffect")
	return not (q(effect.card,"isKindOf","Peach") or q(effect.card,"isKindOf","AmazingGrace") or q(effect.card,"isKindOf","KeyTrick") or q(effect.card,"isKindOf","GodSalvation") or (q(effect.card,"isKindOf","MapoTofu") and effect.from and q(self,"isFriend",effect.from)))
end

sgs.ai_skill_cardchosen.gangqu = function(self, who, flags)
	local cards = q(self.player,"getCards","h")
	cards=sgs.QList2Table(cards)
	q(self,"sortByUseValue",cards,true)
	for _,card in ipairs(cards) do
		if q(card,"isKindOf","BasicCard") then
			return card
		end
		if q(card,"isKindOf","TrickCard") then
			return card
		end
	end
	return cards[1]
end


sgs.ai_fill_skill.tiaojiao=function(self,inclusive,request)
	if q(self.player,"hasUsed","TiaojiaoCard") then return end
	for _,friend in ipairs(self.friends) do
		if q(friend,"getJudgingArea"):length() > 0 then
			return q(self,"legacySkillSeed","tiaojiao","TiaojiaoCard",request or self.request)
		end
	end
	if #self.enemies < 1 then return end
	if #self.enemies == 1 and self.enemies[1]:isNude() then return end
	return q(self,"legacySkillSeed","tiaojiao","TiaojiaoCard",request or self.request)
end

sgs.ai_skill_use_func.TiaojiaoCard = function(card,use,self,request)
	local target
	local source = self.player
	for _,enemy in ipairs(self.enemies) do
		if not q(enemy,"isNude") then
			target = enemy
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if q(enemy,"getHp") == 2 and not q(enemy,"isNude") then
			target = enemy
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if q(enemy,"getHp") == 1 and not q(enemy,"isNude") then
			target = enemy
		end
	end
	for _,friend in ipairs(self.friends) do
		if q(friend,"getJudgingArea"):length() > 0 then
			target = friend
		end
	end
	if target then
		use.card = q(self,"bindSkillCard","tiaojiao",{},request or self.request,nil,"TiaojiaoCard")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value.TiaojiaoCard = 8
sgs.ai_use_priority.TiaojiaoCard  = 10
sgs.ai_card_intention.TiaojiaoCard = 30


sgs.ai_skill_playerchosen.tiaojiao = function(self, targets)
	local target
	if #self.enemies > 0 then
		local cards = 0
		for _,enemy in ipairs(self.enemies) do
			if q(enemy,"isAlive") then
				target = enemy
			end
		end
		for _,enemy in ipairs(self.enemies) do
			if q(enemy,"isAlive") and q(enemy,"getHandcardNum") == 1 then
				target = enemy
			end
		end
		if target then return target end
	end
end

sgs.ai_view_as.yaojing = function(card, player, card_place)
	if not q(player,"hasFlag","Yaojing_Active") then return end
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id =q(card,"getEffectiveId")
	return {name="god_salvation",skill="yaojing",suit=q(card,"getSuit"),number=q(card,"getNumber"),subcards={card_id}}
end

sgs.ai_skill_invoke.yaojing = function(self, data)
	return true
end

sgs.ai_use_value.yaojing = 9
sgs.ai_use_priority.yaojing  = 6

sgs.ai_skill_choice.gongming = function(self, choices, data)



	return  "youdraw"
end

sgs.ai_skill_invoke.kurimu = function(self, data)
	return true
end

sgs.ai_skill_invoke.minatsu = function(self, data)
	if #self.enemies == 0 then return false end
	return true
end

sgs.ai_skill_invoke.chizuru = function(self, data)
	return true
end

sgs.ai_skill_invoke.mafuyu = function(self, data)
	if #self.enemies == 0 then return false end
	return true
end

sgs.ai_skill_playerchosen.kurimu = function(self, targets)
	for _,friend in ipairs(self.friends) do
		if q(friend,"getHandcardNum") < 3 and q(friend,"objectName") ~= q(self.player,"objectName") then
			return friend
		end
	end
	for _,friend in ipairs(self.friends) do
		if q(friend,"objectName") ~= q(self.player,"objectName") then
			return friend
		end
	end
	return targets:at(0)
end

sgs.ai_skill_playerchosen.minatsu = function(self, targets)
	if #self.enemies == 0 then return self.player end
	q(self,"sort",self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		if enemy then
			return enemy
		end
	end
	return self.enemies[1]
end

sgs.ai_skill_playerchosen.chizuru = function(self, targets)
	local minHp = 100
	local target
	for _,friend in ipairs(self.friends) do
		local hp = q(friend,"getHp")
		if q(friend,"getHp")==q(friend,"getMaxHp") then
			hp = 1000
		end
		if q(self,"hasSkills",sgs.masochism_skill, friend) then
			hp = hp - 1
		end
		if q(friend,"isLord") then
			hp = hp - 1
		end
		if hp < minHp then
			minHp = hp
			target = friend
		end
	end
	if target then
		return target
	end
	return self.player
end

sgs.ai_skill_playerchosen.mafuyu = function(self, targets)
	local card_num = 0
	local target
	if #self.enemies == 0 then return self.player end
	for _,enemy in ipairs(self.enemies) do
		if q(enemy,"getHandcardNum") - q(enemy,"getHp") > card_num then
			target = enemy
			card_num = q(enemy,"getHandcardNum") - q(enemy,"getHp")
		end
	end
	if target then
		return target
	end
	return self.enemies[1]
end


ai_skill_use["@@haremu"] = function(self,prompt,request)

	local target = nil
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if target_flag(self,p,"haremu_target") then
			target = p
			break
		end
	end
	if not target then return end
	if #self.enemies == 0 then return end
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	q(self,"sortByUseValue",cards,true)

	local damaged = sgs.ai_skill_playerchosen.chizuru(self, q(self.room,"getAlivePlayers")):getLostHp()
	local hurt = damaged > 0
	local need_help = damaged > 1

	local weak = sgs.ai_skill_playerchosen.minatsu(self, q(self.room,"getAlivePlayers")):getHp() == 1

	if q(self,"isEnemy",target) then
		if q(self,"isWeak") then return "." end
		for _,acard in ipairs(cards) do
			if q(self,"getKeepValue",acard)<5 and q(acard,"getSuit") == sgs.Card_Spade then
				return response(self,"haremu","HaremuCard",{q(acard,"getEffectiveId")},{q(target,"objectName")},request)
			end
			if q(self,"getKeepValue",acard)<5 and q(acard,"getSuit") == sgs.Card_Heart and need_help then
				return response(self,"haremu","HaremuCard",{q(acard,"getEffectiveId")},{q(target,"objectName")},request)
			end
			if q(self,"getKeepValue",acard)<5 and q(acard,"getSuit") == sgs.Card_Club and weak then
				return response(self,"haremu","HaremuCard",{q(acard,"getEffectiveId")},{q(target,"objectName")},request)
			end
		end
	else
		for _,acard in ipairs(cards) do
			if q(acard,"getSuit") == sgs.Card_Spade then
				return response(self,"haremu","HaremuCard",{q(acard,"getEffectiveId")},{q(target,"objectName")},request)
			end
			if q(acard,"getSuit") == sgs.Card_Heart and hurt then
				return response(self,"haremu","HaremuCard",{q(acard,"getEffectiveId")},{q(target,"objectName")},request)
			end
			if q(acard,"getSuit") == sgs.Card_Club and weak then
				return response(self,"haremu","HaremuCard",{q(acard,"getEffectiveId")},{q(target,"objectName")},request)
			end
		end
	end
	return "."
end

sgs.ai_skill_choice.haremu = function(self, choices, data)
	local player = q(data,"toPlayer")

	if not q(self,"isEnemy",player) then return "haremu_accept" end
	if q(self.player,"getRole") == "lord" then return "haremu_accept" end
	return "cancel"
end

sgs.ai_skill_invoke.gaokang = function(self, data)
	local damage = q(data,"toDamage")
	if q(self,"isFriend",damage.to) then
		if q(self.player,"getHandcardNum") == 1 and q(damage.to,"objectName") == q(self.player,"objectName") then return true end
		if q(self,"hasSkills",sgs.masochism_skill, damage.to) and q(damage.to,"getHp") > 1 then return false end
		if q(self.player,"getHandcardNum") == 1 and q(damage.to,"getHp") > 2 then return false end
		return true
	end
end

sgs.ai_skill_choice.rennai = function(self, choices, data)
	choices = choices:split("+")
	local tp = 1
	for _,choice in ipairs(choices) do
		if choice == "rennai_hp" then
			tp = 0
			break
		end
		if choice == "rennai_gain" then
			tp = 2
			break
		end
	end

	local hp_table = {}
	local hand_table = {}
	for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if hp_table[q(p,"getHp")] ~= nil then
			if q(self,"isFriend",p) then
				if q(p,"getMark","@Frozen_Eu") > 0 then
				else
					hp_table[q(p,"getHp")] = hp_table[q(p,"getHp")] - 2
				end
			else
				if q(p,"getMark","@Frozen_Eu") > 0 then
					hp_table[q(p,"getHp")] = hp_table[q(p,"getHp")] + 1
				else
					hp_table[q(p,"getHp")] = hp_table[q(p,"getHp")] + 3
				end
			end
		else
			if q(self,"isFriend",p) then
				if q(p,"getMark","@Frozen_Eu") > 0 then
					hp_table[q(p,"getHp")] = 0
				else
					hp_table[q(p,"getHp")] = - 2
				end
			else
				if q(p,"getMark","@Frozen_Eu") > 0 then
					hp_table[q(p,"getHp")] = 1
				else
					hp_table[q(p,"getHp")] = 3
				end
			end
		end
		if hand_table[q(p,"getHandcardNum")] ~= nil then
			if q(self,"isFriend",p) then
				if q(p,"getMark","@Frozen_Eu") > 0 then
				else
					hand_table[q(p,"getHandcardNum")] = hand_table[q(p,"getHandcardNum")] - 2
				end
			else
				if q(p,"getMark","@Frozen_Eu") > 0 then
					hand_table[q(p,"getHandcardNum")] = hand_table[q(p,"getHandcardNum")] + 1
				else
					hand_table[q(p,"getHandcardNum")] = hand_table[q(p,"getHandcardNum")] + 3
				end
			end
		else
			if q(self,"isFriend",p) then
				if q(p,"getMark","@Frozen_Eu") > 0 then
					hand_table[q(p,"getHandcardNum")] = 0
				else
					hand_table[q(p,"getHandcardNum")] = - 2
				end
			else
				if q(p,"getMark","@Frozen_Eu") > 0 then
					hand_table[q(p,"getHandcardNum")] = 1
				else
					hand_table[q(p,"getHandcardNum")] = 3
				end
			end
		end
	end

	local maxValue = -100000
	local hp_or_hand
	local isHp = false
	for k,v in ipairs(hp_table) do
		if v > maxValue then
			maxValue = v
			hp_or_hand = k
			isHp = true
		end
	end

	for k,v in ipairs(hand_table) do
		if v > maxValue then
			maxValue = v
			hp_or_hand = k
			isHp = false
		end
	end

	if tp == 0 then

		if isHp then
			return "rennai_hp"
		else
			return "rennai_lose"
		end
	elseif tp == 1 then
		return hp_or_hand
	else
		return "rennai_gain"
	end
end

sgs.ai_skill_invoke.zhanfang = function(self, data)

	local use = q(data,"toCardUse")
	if use.card and q(self,"isEnemy",use.to:first()) then return true end
	return false
end

sgs.ai_skill_choice.zhanfang = function(self, choices, data)
	if q(self.player,"getMark","@Frozen_Eu") > 1 then
		return "cancel"
	else
		return "zhanfang_discard"
	end
end

sgs.ai_skill_invoke.huajian = function(self, data)
	if #self.friends > 1 then return true end
	return false
end

sgs.ai_skill_playerchosen.huajian = function(self, targets)
	local bestChoice
	local bestP = 0
	for _,p in ipairs(self.friends_noself) do
		if q(p,"isAlive") and q(p,"objectName") ~= q(self.player,"objectName") then
			local point = 0
			if q(p,"hasSkill","se_erdao") then point = point + 20 end
			if q(p,"hasSkill","Zhena") then point = point + 10 end
			if q(p,"hasSkill","se_xunyu") then point = point + 30 end
			if q(p,"hasSkill","LuaCangshan") then point = point + 9 end
			if q(p,"hasSkill","LuaSaoshe") then point = point + 30 end
			if q(p,"getHp") > 2 then point = point + 3 end
			if q(p,"getHp") <= 1 then point = point - 10 end
			if point > bestP then
				bestP = point
				bestChoice = p
			end
		end
	end
	if bestChoice then return bestChoice end
	return self.friends[1]
end

sgs.ai_skill_choice.guiyin = function(self, choices, data)
	local k1 = q(self.room,"findPlayerBySkillName","guiyin")
	if k1 and q(self,"isFriend",k1) then return "guiyin_give" end
	return "cancel"
end

sgs.ai_skill_invoke.qiubang = function(self, data)
	local use = q(data,"toCardUse")
	if owner_tag(self,"QiubangUsed") >= 4 then return true end
	if q(use.card,"isKindOf","Duel") then return true end
	if use.from and q(self,"isEnemy",use.from) then
		if q(use.card,"isKindOf","Slash") and q(self,"getCardsNum","Jink") == 0 then return true end
		if q(use.card,"isKindOf","Dismantlement") or q(use.card,"isKindOf","Snatch") and (q(self,"getCardsNum","Peach") > 0 or q(self,"getCardsNum","Analeptic") > 0) then return true end
		if q(self,"getCardsNum","Slash") + q(self.player,"getHp") > 3 then
			return true
		end
		if q(self,"isWeak",use.from) and q(self,"getCardsNum","Slash") > 0 then return true end
	end
	return false
end

ai_skill_use["@@youshui"] = function(self,prompt,request)
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	q(self,"sortByKeepValue",cards)
	local target
	for _,p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if target_flag(self,p,"youshui_target") then
			target = p
			break
		end
	end
	if not target then return "." end
	if q(self,"isFriend",target) then
		for _, card in ipairs(cards) do
			if q(card,"isKindOf","Analeptic") then
				return ("@YoushuiCard[%s:%s]=%d"):format(suit, number, card_id) .. "->" .. q(target,"objectName")
			end
		end
	else
		local needed = {}
		for _,acard in ipairs(cards) do
			if #needed < q(target,"getHandcardNum") / 2 and not q(acard,"isKindOf","Peach") and not q(acard,"isKindOf","Analeptic") then
				table.insert(needed, q(acard,"getEffectiveId"))
			end
		end
		if #needed > 0 then
			return response(self,"youshui","YoushuiCard",needed,{q(target,"objectName")},request)
		end
	end
end

sgs.ai_skill_invoke["zuozhan"] = true

sgs.ai_skill_choice["zuozhan1"] = function(self, choices, data)
	local room = self.room
	local p = q(room,"getCurrent")
	if q(self,"isEnemy",p) then
		return "1_Zuozhan"
	else
		if q(p,"getHandcardNum") <= q(p,"getHp") then return "4_Zuozhan" else return "2_Zuozhan" end
	end
	return "1_Zuozhan"
end

sgs.ai_skill_choice["zuozhan2"] = function(self, choices, data)
	local room = self.room
	local p = q(room,"getCurrent")
	if q(self,"isEnemy",p) then
		if q(p,"getHandcardNum") <= 1 and q(p,"getHp") <= 2 then
			return "3_Zuozhan"
		else
			return "2_Zuozhan"
		end
	else
		if q(p,"getHandcardNum") <= q(p,"getHp") then return "2_Zuozhan" else return "3_Zuozhan" end
	end
	return "2_Zuozhan"
end

sgs.ai_skill_choice["zuozhan3"] = function(self, choices, data)
	local room = self.room
	local p = q(room,"getCurrent")
	if q(self,"isEnemy",p) then
		if q(p,"getHandcardNum") <= 1 and q(p,"getHp") <= 2 then
			return "2_Zuozhan"
		else
			return "4_Zuozhan"
		end
	else
		if q(p,"getHandcardNum") <= q(p,"getHp") then return "3_Zuozhan" else return "4_Zuozhan" end
	end
	return "3_Zuozhan"
end

sgs.ai_skill_choice["zuozhan4"] = function(self, choices, data)
	local room = self.room
	local p = q(room,"getCurrent")
	if q(self,"isEnemy",p) then
		if q(p,"getHandcardNum") <= 1 and q(p,"getHp") <= 2 then
			return "4_Zuozhan"
		else
			return "3_Zuozhan"
		end
	else
		return "1_Zuozhan"
	end
	return "4_Zuozhan"
end

sgs.ai_skill_invoke.nishen = function(self, data)
	local dying = q(data,"toDying")
	if not q(self,"isEnemy",dying.who) then return true end
	for _,p in ipairs(self.friends) do
		if q(self,"isWeak",p) then return false end
	end
	return true
end

sgs.ai_skill_choice.nishen = function(self, choices, data)
	choices = choices:split("+")
	local on_join = false
	for _,choice in ipairs(choices) do
		if choice == "nishen_accept" then
			on_join = true
		end
	end
	if on_join then
		local yuri = q(self.room,"findPlayerBySkillName","nishen")
		if not yuri then return "cancel" end
		if q(self.player,"getRole") == "renegade" then return "cancel" end
		if not q(self,"isEnemy",yuri) then return "nishen_accept" end
		return "cancel"
	else
		if q(self.player,"getHandcardNum") < q(self.player,"getHp") * 2 then return "draw" end
		return "recover"
	end
end

sgs.ai_skill_choice["mengxian"] = function(self, choices, data)
	if q(self.player,"getHandcardNum") > q(self.player,"getHp") + 3 then return "equip" end
	return "trick"
end

sgs.ai_skill_choice.yuanwang = function(self, choices, data)
	local haruhi = q(self.room,"findPlayerBySkillName","yuanwang")
	if not haruhi then return "cancel" end
	if q(self,"isFriend",haruhi) then return "yuanwang_accept" end
	return "cancel"
end

sgs.ai_skill_playerchosen.yuanwang = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if q(self,"isFriend",p) then return p end
	end
	return
end


sgs.ai_skill_invoke.hayate_jiejie = function(self, targets)
	local hakaze = q(self.room,"findPlayerBySkillName","hayate_jiejie")
	if not hakaze then return false end
	return not q(self,"isEnemy",hakaze)
end





sgs.ai_skill_cardask["@vector-discard"] = function(self, data)
	if q(self.player,"isKongcheng") then return "." end
	local cards = sgs.QList2Table(q(self.player,"getHandcards"))
	q(self,"sortByUseValue",cards,true)
	local toUse = "$" .. cards[1]:getEffectiveId()
	local effect = q(data,"toCardEffect")
	local card = effect.card
	local power = q(self.player,"getHp") * 2 + q(self.player,"getHandcardNum")
	local cardN = q(self.player,"getCards","he"):length()
	local hp = q(self.player,"getHp")
	if q(card,"isKindOf","AOE") then
		if power > 9 or cardN > hp or power < 4 or hp == 1 then
			return toUse
		end
		return "."
	elseif q(card,"isKindOf","Snatch") or q(card,"isKindOf","Dismantlement") or q(card,"isKindOf","Collateral") or q(card,"isKindOf","Duel") then return toUse
	elseif q(card,"isKindOf","ex_nihilo") then
		q(self,"setStrategyPlayerFlag",self.player,"vecter_friend",true)
		if power > 10 then return toUse end
		return "."
	elseif q(card,"isKindOf","Slash") then
		if q(self,"isFriend",effect.from) then return "." end
		if #self.enemies == 0 then return "." end
		q(self,"setStrategyPlayerFlag",self.player,"vecter_slash",true)
		return toUse
	end
	return "."
end

local function doVector(who, self)
	if not who then return false end
	if q(who,"objectName") == q(self.player,"objectName") then return false end
	if not q(self,"isFriend",who) and q(who,"hasSkill","leiji") and (q(self,"hasSuit","spade", true, who) or q(who,"getHandcardNum") >= 3) and (getKnownCard(who, "Jink", true) >= 1 or q(self,"hasEightDiagramEffect",who)) then
		return false
	end

	local cards = q(self.player,"getCards","h")
	cards = sgs.QList2Table(cards)
	q(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
		if not q(self.player,"isCardLimited",card, method) then
			if q(self,"isFriend",who) then
				return false
			else
				return true
			end
		end
	end

	local cards = q(self.player,"getCards","e")
	cards=sgs.QList2Table(cards)
	q(self,"sortByKeepValue",cards)
	for _, card in ipairs(cards) do
		if not q(self.player,"isCardLimited",card, method) then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.vector = function(self, targets)
	if q(self.player,"getStrategyFlag","vecter_friend") then
		return q(self,"findPlayerToDraw",false, 2)
	elseif q(self.player,"getStrategyFlag","vecter_slash") then
        if #self.enemies>0 then require_enemy_nil(self) end
        local enemy=nil -- only the authenticated fixed-source undefined global
		for _,ememy in ipairs(self.enemies) do
			if doVector(enemy, self) then return enemy end
		end
		for _,ememy in ipairs(self.enemies) do
			return enemy
		end
	else
		return q(self,"findPlayerToDiscard")
	end
end

sgs.ai_skill_invoke.juhe = function(self, data)
	if q(self.player,"getHandcardNum") <= q(self.player,"getHp") then return true end
	return false
end

sgs.ai_skill_choice.juhe = function(self, choices, data)
	if #choices:split("+") == 1 then return "juhe_skip" end
	local pe = q(self,"findPlayerToDamage",q(self.player,"getMark","@xuli"))
	if pe and q(self,"isEnemy",pe) and (q(pe,"getHp") <= q(self.player,"getMark","@xuli") or q(self,"isWeak")) then return "juhe_lose" end
	return "juhe_skip"
end

sgs.ai_skill_playerchosen.juhe = function(self, targets)
	return q(self,"findPlayerToDamage",q(self.player,"getMark","@xuli"))
end

sgs.ai_need_damaged.qifen = function (self, attacker)
	return q(self.player,"getHp") < q(self.player,"getMaxHp")
end

sgs.qifen_keep_value =
{
    Peach 		= 9,
    Analeptic 	= 8,
}

sgs.ai_skill_invoke.qifen = function(self, data)
	if q(self.player,"getHp") < q(self.player,"getMaxHp") then return true end
	if q(self.player,"getHp") == q(self.player,"getMaxHp") then
		if #self.friends >= #self.enemies then return true end
	end
	return false
end

sgs.ai_skill_invoke.mishi = function(self, data)
	local dying_data = q(data,"toDying")
	local source = dying_data.who
	local mygod= mishi_first_holder(self)
	local good
	if (q(self,"isFriend",source) and not q(self,"isFriend",mygod)) or (not q(self,"isFriend",source) and q(self,"isFriend",mygod)) then
		good = true
	end
	if not good then return false end
	local peach_num = 0
	local jink_num = 0
	local hand,missing=mishi_hand(self,mygod)
	for _,card in sgs.qlist(hand) do
		if q(card,"isKindOf","Peach") or q(card,"isKindOf","Analeptic") then
			peach_num = peach_num + 1
		end
		if q(card,"isKindOf","Jink") then
			jink_num = jink_num + 1
		end
	end
	if missing>0 then return mishi_partial_result(q(mygod,"getHp"),peach_num,jink_num,missing)end
	if good then
		if q(mygod,"getHp") > 0 and peach_num > 2 then return true end
		if q(mygod,"getHp") > 0 and peach_num > 1 and jink_num > 0 then return true end
		if q(mygod,"getHp") > 1 and peach_num > 1 then return true end
		if q(mygod,"getHp") > 1 and peach_num > 0 and jink_num > 0 then return true end
		if q(mygod,"getHp") > 2 and peach_num > 0 then return true end
		if q(mygod,"getHp") > 2 and jink_num > 0 then return true end
	end
	return false
end

ai_skill_use["@@hayate_zhufu"] = function(self,prompt,request)
	if q(self.player,"getHandcardNum") < 6 then return "." end
	local targets = {}
	for _,p in ipairs(self.friends_noself) do
		if q(p,"getHandcardNum") < 5 or #targets < 2 then
			table.insert(targets, q(p,"objectName"))
		end
	end
	if #targets > 1 then
		return response(self,"hayate_zhufu","ZhufuCard",{},targets,request)
	end
end
