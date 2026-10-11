-- Fixed donor: fire-ai.lua at b6025acc983331337614289d8cac79b078c003af.
-- Fire callback branches use pure views and native-issued conversion/action receipts.
-- Private-derived global priorities stay viewer-local with estimate provenance.
local function known(value, label)
    if AIUnsupported and AIUnsupported.is and AIUnsupported.is(value) then error(value,0) end
    if value == nil then ai_unsupported("fire strategy requires " .. label, "fire") end
    return value
end
local function query(object, method, ...)
    if not object or type(object[method]) ~= "function" then
        ai_unsupported("fire strategy requires " .. method, "fire")
    end
    return known(object[method](object, ...), method)
end
local function dummy_use()
    local use = AIUsePlan.new()
    use.isDummy = true
    return use
end

-- Callback cost choice is separate from authority. The common binder checks
-- activation/source identity and obtains a native receipt; it never parses a
-- legacy card string into authority.
local function convert(self, skill, class_name, name, material, request)
    local spec = {name=name, suit=query(material,"getSuit"), number=query(material,"getNumber"),
        skill=skill, subcards={query(material,"getEffectiveId")}}
    return query(self,"bindTurnConversion",skill,class_name,spec,request)
end

sgs.ai_fill_skill.lianhuan = function(self, inclusive, request)
    local cards = query(self,"addHandPile")
    cards = query(self,"sortByUseValue",cards,true)
    local chosen
    local slash = self:getCard("FireSlash") or self:getCard("ThunderSlash") or self:getCard("Slash")
    if slash then
        local use = dummy_use()
        self:useBasicCard(slash,use)
        if not use.card then slash = nil end
    end
    for _, card in ipairs(cards) do
        if query(card,"getSuit") == known(sgs.Card_Club,"Club suit enum") then
            local should_use = true
            -- 5.4 is the donor standard IronChain baseline, also used by the
            -- common layer before package value registries are populated.
            if query(self,"getUseValue",card) > (sgs.ai_use_value.IronChain or 5.4)
                and query(card,"getTypeId") == known(sgs.Card_TypeTrick,"Trick type enum") then
                local use = dummy_use()
                self:useTrickCard(card,use)
                if use.card then should_use = false end
            end
            if query(card,"getTypeId") == known(sgs.Card_TypeEquip,"Equip type enum") then
                local use = dummy_use()
                self:useEquipCard(card,use)
                if use.card then should_use = false end
            end
            if should_use and (not slash or query(slash,"getEffectiveId") ~= query(card,"getEffectiveId")) then
                chosen = card
                break
            end
        end
    end
    if not chosen then return nil end
    return convert(self,"lianhuan","IronChain","iron_chain",chosen,request)
end

-- Shared response dispatcher validates this pure proposal against the exact
-- material, class policy and source-instance receipt before it can be used.
sgs.ai_view_as.kanpo = function(card, player, card_place)
    local suit = query(card,"getSuit")
    local number = query(card,"getNumber")
    local id = query(card,"getEffectiveId")
    if card_place == known(sgs.Player_PlaceHand,"hand place enum") and query(card,"isBlack") then
        return {name="nullification",skill="kanpo",suit=suit,number=number,subcards={id}}
    end
end
sgs.ai_cardneed.huoji = function(to,card)
    return query(to,"getHandcardNum") >= 2 and query(card,"isRed")
end
sgs.ai_cardneed.kanpo = function(to,card) return query(card,"isBlack") end
sgs.ai_cardneed.lianhuan = function(to,card)
    return query(card,"getSuit") == known(sgs.Card_Club,"Club suit enum") and query(to,"getHandcardNum") <= 2
end
sgs.ai_armor_value.bazhen = function(player,self,card) if not card then return 4 end end
sgs.kanpo_suit_value = {spade=3.9,club=3.9}
sgs.ai_suit_priority.lianhuan = "club|diamond|heart|spade"
sgs.ai_suit_priority.kanpo = "diamond|heart|club|spade"
sgs.ai_skill_invoke.niepan = function(self,data)
    local dying = query(data,"toDying")
    local hp = query(known(dying.who,"dying player"),"getHp")
    return query(self,"getCardsNum","Peach") + query(self,"getCardsNum","Analeptic") < 1-hp
end

sgs.ai_fill_skill.huoji = function(self,inclusive,request)
    local cards = query(self,"sortByUseValue",query(self,"addHandPile"),true)
    local selected
    for _, card in ipairs(cards) do
        if query(card,"isRed") and not query(card,"isKindOf","Peach")
            and (query(self,"getDynamicUsePriority",card)<(sgs.ai_use_value.FireAttack or 4.8)
                or query(self,"getOverflow")>0) then
            if query(card,"isKindOf","Slash") and query(self,"getCardsNum","Slash")==1 then
                local keep
                local use=dummy_use()
                self:useBasicCard(card,use)
                if use.card and use.to and #use.to>0 then
                    for _,target in ipairs(use.to) do if query(target,"getHp")<=1 then keep=true break end end
                    if #use.to>1 then keep=true end
                end
                if keep then
                    self:setPriorityValue("Slash",query(self,"getPriorityValue","FireAttack",nil,9.5)+0.1,"huoji")
                else
                    self:setPriorityValue("Slash",2.6,"huoji")
                    selected=card
                    break
                end
            else selected=card break end
        end
    end
    if not selected then return nil end
    return convert(self,"huoji","FireAttack","fire_attack",selected,request)
end









-- Complete Fire strategy callbacks. Legacy policy identities are kept apart
-- from the native receipt: only the latter can authorize costs or targets.
sgs.ai_choicemade_filter.cardUsed=sgs.ai_choicemade_filter.cardUsed or {}
local function sort_in_place(self,cards,key,reverse)
    local ordered=query(self,"sort",cards,key,reverse)
    for i=1,#cards do cards[i]=ordered[i] end
    return cards
end
local function cards_in_place(self,method,cards,...)
    local ordered=query(self,method,cards,...)
    for i=1,#cards do cards[i]=ordered[i] end
    return cards
end
local function own_card(self,id)
    for _,card in ipairs(query(self,"addHandPile","he")) do
        if query(card,"getEffectiveId")==id then return card end
    end
    return query(self,"getKnownCardById",id)
end
local function skill_card(self,skill,class,costs,request,planning_costs)
    if self:isUseReviseSkillEvaluation(skill,class) then
        return self:evaluateUseReviseSkillCard(skill,class,costs)
    end
    self._fire_skill_requests=self._fire_skill_requests or {}
    if request then self._fire_skill_requests[skill]=request end
    request=request or self._fire_skill_requests[skill]
    local authority=query(self,"bindSkillCard",skill,costs,request)
    local ids=planning_costs or costs
    local suit,number=sgs.Card_NoSuit,0
    if #ids==1 then
        local material=own_card(self,ids[1])
        suit,number=query(material,"getSuit"),query(material,"getNumber")
    elseif #ids>1 then
        local red,black=true,true
        for _,id in ipairs(ids) do
            local c=own_card(self,id)
            red,black=red and query(c,"isRed"),black and query(c,"isBlack")
        end
        suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit
    end
    local suits={[sgs.Card_Spade]="spade",[sgs.Card_Club]="club",[sgs.Card_Heart]="heart",
        [sgs.Card_Diamond]="diamond",[sgs.Card_NoSuitBlack]="no_suit_black",[sgs.Card_NoSuitRed]="no_suit_red",[sgs.Card_NoSuit]="no_suit"}
    local ns=({[1]="A",[11]="J",[12]="Q",[13]="K"})[number] or tostring(number)
    local serialized="@"..class.."["..known(suits[suit],"policy suit")..":"..ns.."]="..(#ids>0 and table.concat(ids,"+") or ".")
    return query(self,"legacyPolicyCard",authority,{name="",class_name=class,type_id=0,
        kind_of={class,"SkillCard","Card"},legacy_string_key=serialized,subcards=ids,suit=suit,number=number,
        effective_id=ids[1],skill_name=skill,skill_names={skill},will_throw=class~="QixingCard" and class~="KuangfengCard" and class~="DawuCard",
        handling_method=(class=="QixingCard" or class=="KuangfengCard" or class=="DawuCard") and sgs.Card_MethodNone or sgs.Card_MethodDiscard,
        damage_card=false,can_recast=false,red=suit==sgs.Card_Heart or suit==sgs.Card_Diamond or suit==sgs.Card_NoSuitRed,
        black=suit==sgs.Card_Spade or suit==sgs.Card_Club or suit==sgs.Card_NoSuitBlack})
end
local function remember_pindian(self,skill,id)
    self[skill.."_card"]=id
    self:remember(skill.."_card",id)
end
local function response_skill(self,skill,class,costs,targets)
    local use=AIUsePlan.new()
    use.card=skill_card(self,skill,class,costs)
    for _,target in ipairs(targets or {}) do
        if type(target)=="string" then target=known(self.room:findPlayerByObjectName(target),"response target") end
        use.to:append(target)
    end
    return use:toAnswer()
end
sgs.ai_fill_skill.quhu=function(self,inclusive,request)
    if query(self,"needBear") then return end
    local max_card=known(self:getMaxCard(),"Quhu maximum card")
    return skill_card(self,"quhu","QuhuCard",{},request,{query(max_card,"getEffectiveId")})
end
sgs.ai_fill_skill.qiangxi=function(self,inclusive,request) return skill_card(self,"qiangxi","QiangxiCard",{},request) end
sgs.ai_fill_skill.tianyi=function(self,inclusive,request)
    if query(self,"needBear") then return end
    return skill_card(self,"tianyi","TianyiCard",{},request)
end

sgs.ai_skill_use_func.QuhuCard = function(card,use,self,request)
	local max_card = self:getMaxCard()
	local max_point = query(max_card,"getNumber")

	if #self.enemies==0 then return end
	sort_in_place(self,self.enemies,"handcard")

	for _,enemy in ipairs(self.enemies)do
		if query(enemy,"getHp")>query(self.player,"getHp") and query(self.player,"canPindian",enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if query(self,"getKnownNum",enemy)==query(enemy,"getHandcardNum") then
				allknown = allknown+1
			end
			if (enemy_max_card and max_point>query(enemy_max_card,"getNumber") and allknown>0)
				or (enemy_max_card and max_point>query(enemy_max_card,"getNumber") and allknown<1 and max_point>10)
				or (not enemy_max_card and max_point>10) then
				for _,enemy2 in ipairs(self.enemies)do
					if (query(enemy,"objectName")~=query(enemy2,"objectName"))
						and query(enemy,"distanceTo",enemy2)<=query(enemy,"getAttackRange") then
						remember_pindian(self,"quhu",query(max_card,"getEffectiveId"))
						use.card = skill_card(self,"quhu","QuhuCard",{},request)
						use.to:append(enemy)
						return
					end
				end
			end
		end
	end
	if (not query(self.player,"isWounded") or (query(self.player,"getHp")==1 and query(self,"getCardsNum","Analeptic")>0 and query(self.player,"getHandcardNum")>=2))
	  and query(self.player,"hasSkill","jieming") then
		local use_quhu
		for _,friend in ipairs(self.friends)do
			if math.min(5,query(friend,"getMaxHp"))-query(friend,"getHandcardNum")>=2 then
				sort_in_place(self,self.enemies,"handcard")
				if query(self.player,"canPindian",self.enemies[#self.enemies]) then use_quhu = true break end
			end
		end
		if use_quhu then
			for _,enemy in ipairs(self.enemies)do
				if query(self.player,"canPindian",enemy) and query(self.player,"getHp")<query(enemy,"getHp") and not query(enemy,"hasSkill","jueqing") then
					local cards = query(self.player,"getHandcards")
					cards = AIList.new(cards)
					cards_in_place(self,"sortByUseValue",cards,true)
					remember_pindian(self,"quhu",query(cards[1],"getEffectiveId"))
					use.card = skill_card(self,"quhu","QuhuCard",{},request)
					use.to:append(enemy)
					return
				end
			end
		end
	end
end

sgs.ai_choicemade_filter.cardUsed.QuhuCard = function(self,player,carduse)
	self:setEventMemory("ai_quhu_effect",true)
end

sgs.ai_cardneed.quhu = sgs.ai_cardneed.bignumber
sgs.ai_skill_playerchosen.quhu = sgs.ai_skill_playerchosen.damage
sgs.ai_playerchosen_intention.quhu = 80

sgs.ai_card_intention.QuhuCard = 0
sgs.dynamic_value.control_card.QuhuCard = true

table.insert(sgs.damageSkillsList, "quhu")

sgs.ai_skill_playerchosen.jieming = function(self,targets)
	local friends = {}
	for _,player in ipairs(self.friends)do
		if query(player,"isAlive") and not hasManjuanEffect(player) then
			table.insert(friends,player)
		end
	end
	sort_in_place(self,friends)

	local max_x = 0
	local target
	local Shenfen_user
	for _,player in ipairs(query(self.room,"getAlivePlayers"))do
		if query(player,"getStrategyFlag","ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end
	if Shenfen_user then
		local y,weak_friend = 3,nil
		for _,friend in ipairs(friends)do
			local x = math.min(query(friend,"getMaxHp"),5)-query(friend,"getHandcardNum")
			if query(friend,"hasSkill","manjuan") and x>0 then x = x+1 end
			if query(friend,"getMaxHp")>=5 and x>max_x and query(friend,"isAlive") then
				max_x = x
				target = friend
			end

			if query(self,"playerGetRound",friend,Shenfen_user)>query(self,"playerGetRound",self.player,Shenfen_user) and x>=y
				and query(friend,"getHp")==1 and getCardsNum("Peach",friend,self.player)<1 then
				y = x
				weak_friend = friend
			end
		end

		if weak_friend and ((getCardsNum("Peach",Shenfen_user,self.player)<1) or (math.min(query(Shenfen_user,"getMaxHp"),5)-query(Shenfen_user,"getHandcardNum")<=1)) then
			return weak_friend
		end
		if query(self,"isFriend",Shenfen_user) and math.min(query(Shenfen_user,"getMaxHp"),5)>query(Shenfen_user,"getHandcardNum") then
			return Shenfen_user
		end
		if target then return target end
	end

	local CP = query(self.room,"getCurrent")
	local max_x = 0
	local AssistTarget = self:AssistTarget()
	for _,friend in ipairs(friends)do
		local x = math.min(query(friend,"getMaxHp"),5)-query(friend,"getHandcardNum")
		if query(friend,"hasSkill","manjuan") then x = x+1 end
		if query(self,"hasCrossbowEffect",CP) then x = x+1 end
		if AssistTarget and query(friend,"objectName")==query(AssistTarget,"objectName") then x = x+0.5 end

		if x>max_x and query(friend,"isAlive") then
			max_x = x
			target = friend
		end
	end

	return target
end

sgs.ai_need_damaged.jieming = function (self,attacker,player)
	return query(player,"hasSkill","jieming") and query(self,"getJiemingChaofeng",player)<=-6
end

sgs.ai_playerchosen_intention.jieming = function(self,from,to)
	if query(to,"getHandcardNum")<math.min(5,query(to,"getMaxHp")) then
		self:updateIntention(from,to,-80)
	end
end

sgs.ai_can_damagehp.jieming = function(self,from,card,to)
	if not query(self,"isWeak")
	and query(self,"canLoseHp",from,card,to)
	and query(to,"getHp")+query(self,"getAllPeachNum")-query(self,"ajustDamage",from,to,1,card)>0
	then
		for _,fp in ipairs(self.friends)do
			if query(fp,"getMaxHp")-query(fp,"getHandcardNum")>1
			then return true end
		end
	end
end

table.insert(sgs.drawSkillsList, "jieming")


sgs.ai_skill_use_func.QiangxiCard = function(card,use,self,request)
	local weapon = self.player:getWeapon()
	if weapon then
		local hand_weapon,cards
		cards = query(self.player,"getHandcards")
		for _,card in ipairs(cards)do
			if query(card,"isKindOf","Weapon") then
				hand_weapon = card
				break
			end
		end
		sort_in_place(self,self.enemies)
		self.equipsToDec = hand_weapon and 0 or 1
		for _,enemy in ipairs(self.enemies)do
			if query(self,"objectiveLevel",enemy)>3 and not query(self,"cantbeHurt",enemy) and query(self,"damageIsEffective",enemy)
			then
				if hand_weapon and query(self.player,"distanceTo",enemy)<=query(self.player,"getAttackRange")
				 then
					use.card = skill_card(self,"qiangxi","QiangxiCard",{query(hand_weapon,"getId")},request)
					use.to:append(enemy)
					break
				end
				if query(self.player,"distanceTo",enemy)<=1
				 then
					use.card = skill_card(self,"qiangxi","QiangxiCard",{query(weapon,"getId")},request)
					use.to:append(enemy)
					return
				end
			end
		end
		self.equipsToDec = 0
	else
		sort_in_place(self,self.enemies,"hp")
		for _,enemy in ipairs(self.enemies)do
			if query(self,"objectiveLevel",enemy)>3 and not query(self,"cantbeHurt",enemy) and query(self,"damageIsEffective",enemy)
			and query(self.player,"distanceTo",enemy)<=query(self.player,"getAttackRange") and query(self.player,"getHp")>query(enemy,"getHp") and query(self.player,"getHp")>1
			then
				use.card = skill_card(self,"qiangxi","QiangxiCard",{},request)
				use.to:append(enemy)
				return
			end
		end
	end
end

sgs.ai_use_value.QiangxiCard = 2.5
sgs.ai_card_intention.QiangxiCard = 80
sgs.dynamic_value.damage_card.QiangxiCard = true
sgs.ai_cardneed.qiangxi = sgs.ai_cardneed.weapon

sgs.qiangxi_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 5
}




sgs.ai_skill_use_func.TianyiCard = function(card,use,self,request)
	sort_in_place(self,self.enemies,"handcard")
	local cards = AIList.new({})
	local peach = 0
	for _,c in ipairs(query(self.player,"getHandcards"))do
		if isCard("Peach",c,self.player) and peach<2 then
			peach = peach+1
		else
			cards:append(c)
		end
	end
	local max_card = self:getMaxCard(self.player,cards)
	if not max_card then return end
	local max_point = query(max_card,"getNumber")
	local slashcount = query(self,"getCardsNum","Slash")
	if isCard("Slash",max_card,self.player) then slashcount = slashcount-1 end
	if query(self.player,"hasSkill","kongcheng") and query(self.player,"getHandcardNum")==1 then
		for _,enemy in ipairs(self.enemies)do
			if query(self.player,"canPindian",enemy) and query(self,"doDisCard",enemy,"h") then
				query(self,"setPriorityValue","TianyiCard",1.2,"tianyi")
				remember_pindian(self,"tianyi",query(max_card,"getId"))
				use.card = skill_card(self,"tianyi","TianyiCard",{},request)
				use.to:append(enemy)
				return
			end
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if query(enemy,"getStrategyFlag","AI_HuangtianPindian") and query(enemy,"getHandcardNum")==1 and query(self.player,"canPindian",enemy) then
			query(self,"setPriorityValue","TianyiCard",7.2,"tianyi")
			remember_pindian(self,"tianyi",query(max_card,"getId"))
			use.card = skill_card(self,"tianyi","TianyiCard",{},request)
			use.to:append(enemy)
			self:setStrategyPlayerFlag(enemy,"AI_HuangtianPindian",false)
			return
		end
	end
	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")

	local slash = self:getCard("Slash")
	local dummy_use = dummy_use()
	dummy_use.extra_target=1
	if slash then dummy_use=query(self,"evaluateTianyiSlash",slash,dummy_use) end

	query(self,"setPriorityValue","TianyiCard",(slashcount>=1 and dummy_use.card) and 7.2 or 1.2,"tianyi")
	if slashcount>=1 and slash and dummy_use.card  then
		for _,enemy in ipairs(self.enemies)do
			if not (query(enemy,"hasSkill","kongcheng") and query(enemy,"getHandcardNum")==1) and query(self.player,"canPindian",enemy) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point = enemy_max_card and query(enemy_max_card,"getNumber") or 100
				if max_point>enemy_max_point then
					remember_pindian(self,"tianyi",query(max_card,"getId"))
					use.card = skill_card(self,"tianyi","TianyiCard",{},request)
					use.to:append(enemy)
					return
				end
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if not (query(enemy,"hasSkill","kongcheng") and query(enemy,"getHandcardNum")==1) and query(self.player,"canPindian",enemy) then
				if max_point>=10 then
					remember_pindian(self,"tianyi",query(max_card,"getId"))
					use.card = skill_card(self,"tianyi","TianyiCard",{},request)
					use.to:append(enemy)
					return
				end
			end
		end
		if #self.enemies<1 then return end
		if dummy_use.to:length()>1 then
			sort_in_place(self,self.friends_noself,"handcard")
			for index = #self.friends_noself,1,-1 do
				local friend = self.friends_noself[index]
				if query(self.player,"canPindian",friend) then
					local friend_min_card = self:getMinCard(friend)
					local friend_min_point = friend_min_card and query(friend_min_card,"getNumber") or 100
					if max_point>friend_min_point then
						remember_pindian(self,"tianyi",query(max_card,"getId"))
						use.card = skill_card(self,"tianyi","TianyiCard",{},request)
						use.to:append(friend)
						return
					end
				end
			end
		end

		if zhugeliang and query(self,"isFriend",zhugeliang) and query(zhugeliang,"getHandcardNum")==1 and query(zhugeliang,"objectName")~=query(self.player,"objectName")
			and query(self.player,"canPindian",zhugeliang) then
			if max_point>=7 then
				remember_pindian(self,"tianyi",query(max_card,"getId"))
				use.card = skill_card(self,"tianyi","TianyiCard",{},request)
				use.to:append(zhugeliang)
				return
			end
		end

		if dummy_use.to:length()>1 then
			for index = #self.friends_noself,1,-1 do
				local friend = self.friends_noself[index]
				if query(self.player,"canPindian",friend) then
					if max_point>=7 then
						remember_pindian(self,"tianyi",query(max_card,"getId"))
						use.card = skill_card(self,"tianyi","TianyiCard",{},request)
						use.to:append(friend)
						return
					end
				end
			end
		end
	end

	cards = AIList.new(cards)
	cards_in_place(self,"sortByUseValue",cards,true)
	if zhugeliang and query(self,"isFriend",zhugeliang) and query(zhugeliang,"getHandcardNum")==1
		and query(zhugeliang,"objectName")~=query(self.player,"objectName") and query(self,"getEnemyNumBySeat",self.player,zhugeliang)>=1 and query(self.player,"canPindian",zhugeliang) then
		if isCard("Jink",cards[1],self.player) and query(self,"getCardsNum","Jink")==1 then return end
		remember_pindian(self,"tianyi",query(cards[1],"getId"))
		use.card = skill_card(self,"tianyi","TianyiCard",{},request)
		use.to:append(zhugeliang)
		return
	end

	if query(self,"getOverflow")>0 then
		for _,enemy in ipairs(self.enemies)do
			if query(self,"doDisCard",enemy,"h") and query(self.player,"canPindian",enemy) then
				remember_pindian(self,"tianyi",query(cards[1],"getId"))
				use.card = skill_card(self,"tianyi","TianyiCard",{},request)
				use.to:append(enemy)
				return
			end
		end
	end
	return nil
end

function sgs.ai_skill_pindian.tianyi(minusecard,self,requestor)
	if query(requestor,"getHandcardNum")==1 then
		local cards = AIList.new(query(self.player,"getHandcards"))
		cards_in_place(self,"sortByKeepValue",cards)
		return cards[1]
	end
	local maxcard = self:getMaxCard()
	return query(self,"isFriend",requestor) and self:getMinCard() or ( query(maxcard,"getNumber")<6 and  minusecard or maxcard )
end

sgs.ai_cardneed.tianyi = function(to,card,self)
	local cards = query(to,"getKnownCards")
    local current=known(self.room:getCurrent(),"Tianyi observer")
    if current:objectName()~=self.player:objectName() then
        self:useKnowledgeEstimate({status="estimate",value=0,target=to:objectName(),
            basis="tianyi_current_observer_private_visibility_replaced_by_viewer_known_cards"},"tianyi.cardneed")
    end
	local has_big = false
	for _,c in ipairs(cards)do
		local flag = string.format("%s_%s_%s","visible",query(self.room,"getCurrent"):objectName(),query(to,"objectName"))
		if query(c,"hasFlag","visible") or (function()
            local visible=c:hasFlag(flag)
            if visible~=nil then return visible end
            return self:useKnowledgeEstimate({status="estimate",value=false,target=to:objectName(),
                basis="tianyi_unobserved_other_observer_visibility_flag_false_prior"},"tianyi.cardneed")
        end)() then
			if query(c,"getNumber")>10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return query(card,"getNumber")>10
	else
		return query(card,"isKindOf","Slash") or query(card,"isKindOf","Analeptic")
	end
end

sgs.ai_card_intention.TianyiCard = 0
sgs.dynamic_value.control_card.TianyiCard = true

sgs.ai_use_value.TianyiCard = 8.5




sgs.ai_fill_skill.luanji = function(self,inclusive,request)
	local first_found,second_found = false,false
	local first_card,second_card
	if query(self.player,"getHandcardNum")>=2
	then
		local cards = query(self,"addHandPile")
		local same_suit = false
		cards_in_place(self,"sortByKeepValue",cards)
		local useAll = false
		for _,enemy in ipairs(self.enemies)do
			if query(enemy,"getHp")==1 and not query(enemy,"hasArmorEffect","Vine")
			and not query(self,"hasEightDiagramEffect",enemy) and query(self,"damageIsEffective",enemy,nil,self.player) and query(self,"isWeak",enemy)
			and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
			then useAll = true end
		end
		for _,fcard in ipairs(cards)do
			local fvalueCard = (isCard("Peach",fcard,self.player) or isCard("ExNihilo",fcard,self.player) or isCard("ArcheryAttack",fcard,self.player))
			if useAll then fvalueCard = isCard("ArcheryAttack",fcard,self.player) end
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _,scard in ipairs(cards)do
					local svalueCard = (isCard("Peach",scard,self.player) or isCard("ExNihilo",scard,self.player) or isCard("ArcheryAttack",scard,self.player))
					if useAll then svalueCard = (isCard("ArcheryAttack",scard,self.player)) end
					if first_card~=scard and query(scard,"getSuit")==query(first_card,"getSuit")
						and not svalueCard then

						local card_str = ("archery_attack:luanji[%s:%s]=%d+%d"):format("to_be_decided",0,query(first_card,"getId"),query(scard,"getId"))
						local archeryattack = query(self,"bindTurnConversion","luanji","ArcheryAttack",{name="archery_attack",skill="luanji",suit=query(first_card,"isRed") and sgs.Card_NoSuitRed or query(first_card,"isBlack") and sgs.Card_NoSuitBlack or sgs.Card_NoSuit,number=0,subcards={query(first_card,"getId"),query(second_card or scard,"getId")}},request)

						assert(archeryattack)

						local dummy_use = dummy_use()
						self:useTrickCard(archeryattack,dummy_use)
						if dummy_use.card then
							second_card = scard
							second_found = true
							break
						end
					end
				end
				if second_card then break end
			end
		end
	end

	if first_found and second_found then
		local first_id = query(first_card,"getId")
		local second_id = query(second_card,"getId")
		local card_str = ("archery_attack:luanji[%s:%s]=%d+%d"):format("to_be_decided",0,first_id,second_id)
		local archeryattack = query(self,"bindTurnConversion","luanji","ArcheryAttack",{name="archery_attack",skill="luanji",suit=query(first_card,"isRed") and sgs.Card_NoSuitRed or query(first_card,"isBlack") and sgs.Card_NoSuitBlack or sgs.Card_NoSuit,number=0,subcards={query(first_card,"getId"),query(second_card or scard,"getId")}},request)
		assert(archeryattack)
		return archeryattack
	end
end




sgs.ai_skill_invoke.shuangxiong=function(self,data)
	if query(self,"needBear") then return false end
	if query(self.player,"isSkipped",sgs.Player_Play) or (query(self.player,"getHp")<2 and not (query(self,"getCardsNum","Slash")>1 and query(self.player,"getHandcardNum")>=3)) or #self.enemies==0 then
		return false
	end
	local duel = query(self,"getEvaluationCard","duel")

	local dummy_use = dummy_use()
	self:useTrickCard(duel,dummy_use)

	return query(self.player,"getHandcardNum")>=3 and dummy_use.card
end

sgs.ai_cardneed.shuangxiong=function(to,card,self)
	return not query(self,"willSkipDrawPhase",to)
end

sgs.ai_fill_skill.shuangxiong=function(self,inclusive,request)
	-- All modes use the same accumulated judgment colors.
	local colors = query(self.player,"getShuangxiongColors")

	local cards = query(self,"addHandPile")
	cards_in_place(self,"sortByUseValue",cards,true)

	local card
	for _,acard in ipairs(cards)  do
		if not query(acard,"hasFlag","using") and ((query(acard,"isRed") and table.contains(colors, "no_suit_black"))
			or (query(acard,"isBlack") and table.contains(colors, "no_suit_red"))) then
			card = acard
			break
		end
	end

	if not card then return nil end
	local suit = query(card,"getSuitString")
	local number = query(card,"getNumberString")
	local card_id = query(card,"getEffectiveId")
	local card_str = ("duel:shuangxiong[%s:%s]=%d"):format(suit,number,card_id)
	local skillcard = convert(self,"shuangxiong","Duel","duel",card,request)
	assert(skillcard)
	return skillcard

end



sgs.ai_skill_invoke.mengjin = function(self,data)
	local effect = query(data,"toCardEffect")
	if query(self,"isEnemy",effect.to) then
		if query(self,"doDisCard",effect.to) then
			return true
		end
	end
	if query(self,"isFriend",effect.to) then
		return query(self,"needToThrowArmor",effect.to) or query(self,"doDisCard",effect.to)
	end
	return not query(self,"isFriend",effect.to)
end

sgs.ai_suit_priority.lianhuan= "club|diamond|heart|spade"
sgs.ai_suit_priority.kanpo= "diamond|heart|club|spade"



sgs.ai_skill_invoke.qinyin = function(self,data)
	sort_in_place(self,self.friends,"hp")
	sort_in_place(self,self.enemies,"hp")
	local up = 0
	local down = 0

	for _,friend in ipairs(self.friends)do
		down = down-10
		up = up+(query(friend,"isWounded") and 10 or 0)
		if query(self,"hasSkills",sgs.masochism_skill,friend) then
			down = down-5
			if query(friend,"isWounded") then up = up+5 end
		end
		if query(self,"needToLoseHp",friend,nil,nil,true) then down = down+5 end
		if query(self,"needToLoseHp",friend,nil,nil,true,true) and query(friend,"isWounded") then up = up-5 end

		if query(self,"isWeak",friend) then
			if query(friend,"isWounded") then up = up+10+(query(friend,"isLord") and 20 or 0) end
			down = down-10-(query(friend,"isLord") and 40 or 0)
			if query(friend,"getHp")<=1 and not query(friend,"hasSkill","buqu") or query(friend,"getPile","buqu"):length()>4 then
				down = down-20-(query(friend,"isLord") and 40 or 0)
			end
		end
	end

	for _,enemy in ipairs(self.enemies)do
		down = down+10
		up = up-(query(enemy,"isWounded") and 10 or 0)
		if query(self,"hasSkills",sgs.masochism_skill,enemy) then
			down = down+10
			if query(enemy,"isWounded") then up = up-10 end
		end
		if query(self,"needToLoseHp",enemy,nil,nil,true) then down = down-5 end
		if query(self,"needToLoseHp",enemy,nil,nil,true,true) and query(enemy,"isWounded") then up = up-5 end

		if query(self,"isWeak",enemy) then
			if query(enemy,"isWounded") then up = up-10 end
			down = down+10
			if query(enemy,"getHp")<=1 and not query(enemy,"hasSkill","buqu") then
				down = down+10+((query(enemy,"isLord") and #self.enemies>1) and 20 or 0)
			end
		end
	end

	if down>0 then
		query(self,"setStrategyMemory","fire.qinyin_choice","down")
		return true
	elseif up>0 then
		query(self,"setStrategyMemory","fire.qinyin_choice","up")
		return true
	end
	return false
end


sgs.ai_skill_choice.qinyin=function(self)
    local choice,present=self:getStrategyMemory("fire.qinyin_choice")
    if not present then ai_unsupported("Qinyin choice has no prior invocation","qinyin") end
    return choice
end

sgs.ai_fill_skill.yeyan=function(self,inclusive,request)
	if query(self.player,"getHandcardNum")>=4 then
		local spade,club,heart,diamond
		for _,card in ipairs(query(self.player,"getHandcards"))do
			if query(card,"getSuit")==sgs.Card_Spade then spade = true
			elseif query(card,"getSuit")==sgs.Card_Club then club = true
			elseif query(card,"getSuit")==sgs.Card_Heart then heart = true
			elseif query(card,"getSuit")==sgs.Card_Diamond then diamond = true
			end
		end
		if spade and club and diamond and heart then
			sort_in_place(self,self.enemies,"hp")
			local target_num = 0
			for _,enemy in ipairs(self.enemies)do
				if ((query(enemy,"hasArmorEffect","Vine") or query(enemy,"getHp")<=3) and not query(enemy,"isChained"))
				or (query(enemy,"isChained") and query(self,"isGoodChainTarget",enemy,nil,nil,3))
				then target_num = target_num+1 end
			end
			if target_num>=1 then
				-- The donor fills an unpaid GreatYeyan prototype. Its four
				-- materials are selected later by use_func; an empty-cost
				-- native Yeyan receipt would instead authorize SmallYeyan.
				return query(self,"legacySkillSeed","yeyan","GreatYeyanCard",request)
			end
		end
	end

	self.yeyanchained = false
	if query(self.player,"getHp")+query(self,"getCardsNum","Peach")+query(self,"getCardsNum","Analeptic")<=2 then
		return skill_card(self,"yeyan","SmallYeyanCard",{},request)
	end
	local target_num = 0
	local chained = 0
	for _,enemy in ipairs(self.enemies)do
                if ((query(enemy,"hasArmorEffect","Vine") or query(enemy,"getStrategyMark","&kuangfeng")>0) or query(enemy,"getHp")<=1)
			and not (query(self.player,"getRole")=="renegade" and query(enemy,"isLord")) then
			target_num = target_num+1
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if query(enemy,"isChained") and query(self,"isGoodChainTarget",enemy)
		then
			if chained==0 then target_num = target_num +1 end
			chained = chained+1
		end
	end
	self.yeyanchained = (chained>1)
	if target_num>2 or (target_num>1 and self.yeyanchained) or
	(#self.enemies+1==query(self.room,"alivePlayerCount") and query(self.room,"alivePlayerCount")<query(self.room,"getModePlayerCount")) then
		return skill_card(self,"yeyan","SmallYeyanCard",{},request)
	end
end

sgs.ai_skill_use_func.GreatYeyanCard = function(card,use,self,request)
	if query(self.player,"getRole")=="lord" and (query(self.room,"getTurnCount")<=1 or query(self,"getRoleCountValue","rebel")>#query(self,"getChainedEnemies") or query(self,"getAllPeachNum")<4-query(self.player,"getHp")) then
		return
	end
	if query(self.player,"getRole")=="renegade" and query(self.room,"alivePlayerCount")>2 and query(self,"getCardsNum","Peach")<3-query(self.player,"getHp") then return end
	local cards = query(self.player,"getHandcards")
	cards = AIList.new(cards)
	cards_in_place(self,"sortByUseValue",cards,true)
	local need_cards = {}
	local spade,club,heart,diamond
	for _,card in ipairs(cards)do
		if query(card,"getSuit")==sgs.Card_Spade and not spade then spade = true table.insert(need_cards,query(card,"getId"))
		elseif query(card,"getSuit")==sgs.Card_Club and not club then club = true table.insert(need_cards,query(card,"getId"))
		elseif query(card,"getSuit")==sgs.Card_Heart and not heart then heart = true table.insert(need_cards,query(card,"getId"))
		elseif query(card,"getSuit")==sgs.Card_Diamond and not diamond then diamond = true table.insert(need_cards,query(card,"getId"))
		end
	end
	if #need_cards<4 then return end
	local greatyeyan = skill_card(self,"yeyan","GreatYeyanCard",need_cards,request)
	assert(greatyeyan)

	local first
	sort_in_place(self,self.enemies,"hp")
	for _,enemy in ipairs(self.enemies)do
		if not query(enemy,"hasArmorEffect","SilverLion") and query(self,"objectiveLevel",enemy)>3
		and query(self,"damageIsEffective",enemy,sgs.DamageStruct_Fire)
		and not (query(enemy,"hasSkill","tianxiang") and query(enemy,"getHandcardNum")>0)
		and query(enemy,"isChained") and query(self,"isGoodChainTarget",enemy,nil,nil,3)
		then
            if query(enemy,"hasArmorEffect","Vine") or query(enemy,"getStrategyMark","&kuangfeng")>0
			then
				use.card = greatyeyan
				use.to:append(enemy)
				use.to:append(enemy)
				use.to:append(enemy)
				return
			elseif not first then first = enemy end
		end
	end
	if first then
		use.card = greatyeyan
		use.to:append(first)
		use.to:append(first)
		use.to:append(first)
		return
	end

	local second
	for _,enemy in ipairs(self.enemies)do
		if not query(enemy,"hasArmorEffect","SilverLion") and query(self,"objectiveLevel",enemy)>3 and query(self,"damageIsEffective",enemy,sgs.DamageStruct_Fire)
		and not (query(enemy,"hasSkill","tianxiang") and query(enemy,"getHandcardNum")>0) and not query(enemy,"isChained")
		then
            if query(enemy,"hasArmorEffect","Vine") or query(enemy,"getStrategyMark","&kuangfeng")>0
			then
				use.card = greatyeyan
				use.to:append(enemy)
				use.to:append(enemy)
				use.to:append(enemy)
				return
			elseif not second then second = enemy end
		end
	end
	if second then
		use.card = greatyeyan
		use.to:append(second)
		use.to:append(second)
		use.to:append(second)
		return
	end
end

sgs.ai_use_value.GreatYeyanCard = 8
sgs.ai_use_priority.GreatYeyanCard = 9

sgs.ai_card_intention.GreatYeyanCard = 200

sgs.ai_skill_use_func.SmallYeyanCard = function(card,use,self,request)
	if query(self.player,"getStrategyMark","@flame")==0 then return end
	local targets = AIList.new({})
	sort_in_place(self,self.enemies,"hp")
	for _,enemy in ipairs(self.enemies)do
		if not (query(enemy,"hasSkill","tianxiang") and query(enemy,"getHandcardNum")>0) and query(self,"damageIsEffective",enemy,sgs.DamageStruct_Fire)
        and query(enemy,"isChained") and query(self,"isGoodChainTarget",enemy) and (query(enemy,"hasArmorEffect","Vine") or query(enemy,"getStrategyMark","&kuangfeng")>0)
		then
			targets:append(enemy)
			if targets:length()>=3 then break end
		end
	end
	if targets:length()<3 then
		for _,enemy in ipairs(self.enemies)do
			if not targets:contains(enemy)
			and not (query(enemy,"hasSkill","tianxiang") and query(enemy,"getHandcardNum")>0)
			and query(self,"damageIsEffective",enemy,sgs.DamageStruct_Fire)
			and query(enemy,"isChained") and query(self,"isGoodChainTarget",enemy)
			then
				targets:append(enemy)
				if targets:length()>=3 then break end
			end
		end
	end
	if targets:length()<3 then
		for _,enemy in ipairs(self.enemies)do
			if not targets:contains(enemy)
				and not (query(enemy,"hasSkill","tianxiang") and query(enemy,"getHandcardNum")>0) and query(self,"damageIsEffective",enemy,sgs.DamageStruct_Fire)
                                and not query(enemy,"isChained") and (query(enemy,"hasArmorEffect","Vine") or query(enemy,"getStrategyMark","&kuangfeng")>0) then
				targets:append(enemy)
				if targets:length()>=3 then break end
			end
		end
	end
	if targets:length()<3 then
		for _,enemy in ipairs(self.enemies)do
			if not targets:contains(enemy)
				and not (query(enemy,"hasSkill","tianxiang") and query(enemy,"getHandcardNum")>0) and query(self,"damageIsEffective",enemy,sgs.DamageStruct_Fire)
				and not query(enemy,"isChained") then
				targets:append(enemy)
				if targets:length()>=3 then break end
			end
		end
	end
	if targets:length()>0 then
		use.card = card
		use.to = targets
	end
end

sgs.ai_card_intention.SmallYeyanCard = 80
sgs.ai_use_priority.SmallYeyanCard = 2.3


sgs.ai_skill_discard.qixing = function(self,discard_num,optional,include_equip)
	local cards = AIList.new(query(self.player,"getHandcards"))
	local to_discard = {}
	local compare_func = function(a,b)
		return query(self,"getKeepValue",a)<query(self,"getKeepValue",b)
	end
	table.sort(cards,compare_func)
	for _,card in ipairs(cards)do
		if #to_discard>=discard_num then break end
		table.insert(to_discard,query(card,"getId"))
	end

	return to_discard
end
sgs.ai_skill_use["@@qixing"] = function(self,prompt)
	local pile = query(self.player,"getPile","stars")
	local piles = {}
	local cards = query(self.player,"getHandcards")
	cards = AIList.new(cards)
	local max_num = math.min(pile:length(),#cards)
	if pile:isEmpty() or (#cards==0) then
		return "."
	end
	for _,card_id in ipairs(pile)do
		table.insert(piles,own_card(self,card_id))
	end
	local exchange_to_pile = {}
	local exchange_to_handcard = {}
	cards_in_place(self,"sortByCardNeed",cards)
	cards_in_place(self,"sortByCardNeed",piles)
	for i = 1 ,max_num,1 do
		if query(self,"cardNeed",piles[#piles])>query(self,"cardNeed",cards[1]) then
			table.insert(exchange_to_handcard,piles[#piles])
			table.insert(exchange_to_pile,cards[1])
			table.remove(piles,#piles)
			table.remove(cards,1)
		else
			break
		end
	end
	if #exchange_to_handcard==0 then return "." end
	local exchange = {}

	for _,c in ipairs(exchange_to_handcard)do
		table.insert(exchange,query(c,"getId"))
	end

	for _,c in ipairs(exchange_to_pile)do
		table.insert(exchange,query(c,"getId"))
	end

	return response_skill(self,"qixing","QixingCard",exchange)
end

sgs.ai_skill_use["@@kuangfeng"] = function(self,prompt)
	local friendly_fire
	for _,friend in ipairs(self.friends_noself)do
                if query(friend,"getStrategyMark","&kuangfeng")==0 and query(self,"damageIsEffective",friend,sgs.DamageStruct_Fire) and query(friend,"faceUp") and not query(self,"willSkipPlayPhase",friend)
			and (query(friend,"hasSkill","huoji") or query(friend,"hasWeapon","Fan") or (query(friend,"hasSkill","yeyan") and query(friend,"getStrategyMark","@flame")>0)) then
			friendly_fire = true
			break
		end
	end

	local is_chained = 0
	local target = {}
	for _,enemy in ipairs(self.enemies)do
                if query(enemy,"getStrategyMark","&kuangfeng")==0 and query(self,"damageIsEffective",enemy,sgs.DamageStruct_Fire) then
			if query(enemy,"isChained") then
				is_chained = is_chained+1
				table.insert(target,enemy)
			elseif query(enemy,"hasArmorEffect","Vine") then
				table.insert(target,1,enemy)
				break
			end
		end
	end
	local usecard=false
	if friendly_fire and is_chained>1 then usecard=true end
	sort_in_place(self,self.friends,"hp")
	if target[1] and not query(self,"isWeak",self.friends[1]) then
		if query(target[1],"hasArmorEffect","Vine") and friendly_fire then usecard = true end
	end
	if usecard then
		if not target[1] then table.insert(target,self.enemies[1]) end
		if target[1] then return response_skill(self,"kuangfeng","KuangfengCard",{query(self.player,"getPile","stars"):first()},{target[1]}) else return "." end
	else
		return "."
	end
end

sgs.ai_card_intention.KuangfengCard = 80

sgs.ai_skill_use["@@dawu"] = function(self,prompt)
	sort_in_place(self,self.friends_noself,"hp")
	local targets = {}
	local lord = self.room:getLord()
	sort_in_place(self,self.friends_noself,"defense")
        if lord and query(lord,"getStrategyMark","&dawu")==0 and query(self,"isFriend",lord) and not query(self,"isLordHealthy") and not query(self.player,"isLord") and not query(lord,"hasSkill","buqu")
		and not (query(lord,"hasSkill","hunzi") and query(lord,"getStrategyMark","hunzi")==0 and query(lord,"getHp")>1) then
			table.insert(targets,query(lord,"objectName"))
	else
		for _,friend in ipairs(self.friends_noself)do
                        if query(friend,"getStrategyMark","&dawu")==0 and query(self,"isWeak",friend) and not query(friend,"hasSkill","buqu")
				and not (query(friend,"hasSkill","hunzi") and query(friend,"getStrategyMark","hunzi")==0 and query(friend,"getHp")>1) then
					table.insert(targets,query(friend,"objectName"))
					break
			end
		end
	end
	if query(self.player,"getPile","stars"):length()>#targets and query(self,"isWeak") then table.insert(targets,query(self.player,"objectName")) end
	if #targets>0 then
		local s = AIList.new(query(self.player,"getPile","stars"))
		local length = #targets
		for i = 1,#s-length do
			table.remove(s,#s)
		end
		return response_skill(self,"dawu","DawuCard",s,targets)
	end
	return "."
end

sgs.ai_card_intention.DawuCard = -70


-- 袁绍主公选将策略
sgs.ai_general_choice_for_lord["yuanshao"] = function(ai, generals, default_choice, lord)
	local role = query(ai.player,"getRole")
	local general_scores = {}
	for _, general_name in ipairs(generals) do
		local score = 0
		local context=ai.request and ai.request.options and ai.request.options.context
        local general=known(context and context.general_catalog and context.general_catalog[general_name],"general catalog")
        known(general.exists,"general existence")

		if general.exists then
			local desc = known(general.skill_description,"general skill description")
			local hp = known(general.max_hp,"general max HP")

			if role == "loyalist" then
				if string.find(desc, "闪") then score = score + 3 end
				if string.find(desc, "受到伤害") and string.find(desc, "摸") then score = score + 5 end
				if hp >= 4 then score = score + 3 end
			else
				if string.find(desc, "受到伤害") then score = score + 5 end
			end

			local strategy_func = sgs.ai_general_choice[general_name]
			if type(strategy_func) == "function" then
				local recommend = strategy_func(ai, lord, role)
				if recommend == 1 then
					score = score + 10
				elseif recommend == -1 then
					score = score - 10
				end
			end
		end

		table.insert(general_scores, {name = general_name, score = score})
	end

	table.sort(general_scores, function(a, b) return a.score > b.score end)
	local best_score = general_scores[1] and general_scores[1].score or 0
	local best_generals = {}
	for _, gs in ipairs(general_scores) do
		if gs.score == best_score then
			table.insert(best_generals, gs.name)
		else
			break
		end
	end

	if #best_generals > 0 then
		return best_generals[math.random(1, #best_generals)]
	end

	return #generals > 0 and generals[math.random(1, #generals)] or default_choice
end

-- 荀彧主公策略（节命：濒死时让别人摸牌）
sgs.ai_general_choice_for_lord["xunyu"] = function(ai, generals, default_choice, lord)
	local scores = known(hp_loss_lord_strategy_scores(ai, generals, lord, false),"Xun Yu general scores")
	return select_best_general(scores, default_choice)
end
