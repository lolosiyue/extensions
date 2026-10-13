-- Fixed erciyuan-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local function known(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("erciyuan policy input is unknown",key) end
    return value
end
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("erciyuan policy helper unavailable",method) end
    local result=table.pack(object[method](object,...))
    if AIUnsupported.is(result[1]) then error(result[1],0) end
    return table.unpack(result,1,result.n)
end
local function q(object,method,...)
    local value=call(object,method,...)
    if value==false and (method=="hasSkill"or method=="hasSkills"or method=="hasLordSkill")and AIValue.isPlayer(object)then
        local row=rawget(object,"_view")
        if row and row.skills_complete~=true then ai_unsupported("foreign skill absence is unknown",(...))end
    end
    return known(value,method)
end
local function sorted(self,cards,method,...)
    local result=q(self,method,cards,...)
    for i,c in ipairs(result) do cards[i]=c end
    return cards
end
local function sort_players(self,cards,...) return sorted(self,cards,"sort",...) end
local function sort_use(self,cards,...) return sorted(self,cards,"sortByUseValue",...) end
local function sort_keep(self,cards,...) return sorted(self,cards,"sortByKeepValue",...) end
local function action_request(self,request)
    if request and type(request.getActivationSkillName)~="function" then return AILegacyRequest.new(request,self.room) end
    return request
end
local function seed(self,skill,class,request) return q(self,"legacySkillSeed",skill,class,action_request(self,request)) end
local skill_cards={['#LuaChitian']='LuaChitian',['#LuaQisi']='LuaQisi',['#luablackflamecard']='luablackflame',['#luaboxuecard']='luaboxue',['#luagongluecard']='luagonglue',['#luaposhicard']='luaposhi',['#luarenzhacard']='luarenzha',['#luasaoshecard']='luasaoshe',['#luasynchrogazercard']='luasynchrogazer',['#luatiaojiaocard']='luatiaojiao',['#luatouyingcard']='luatouying',['#luayingxiancard']='luayingxian',['#luayuehuangcard']='luayuehuang',['#luayukongcard']='luayukong',['#slyanhuocard']='slyanhuo',['#yanhuoacquirecard']='yanhuoacquire'}
local function disclosed(self,id)return known(self:getKnownCardById(id)or self:getChoiceCard(id),'erciyuan source card '..tostring(id))end
local function parts(wire)
 local class,raw,user=wire:match('^(#[^:]+):([^:]*):(.*)$');if not class then return end
 local costs={};for id in raw:gmatch('%d+')do costs[#costs+1]=tonumber(id)end
 return class,costs,user~=''and user or nil
end
local function parse(self,request,wire)
 local class,costs,user=parts(wire)
 if class then local skill=known(skill_cards[class],class)
  if #costs==0 and user==nil then return seed(self,skill,class,request)end
  return q(self,'evaluateTurnSkillCard',skill,class,costs,action_request(self,request),user)
 end
 local name,skill,raw=wire:match('^([^:]+):([^%[]+)%[[^%]]+%]=(.*)$')
 if not name then ai_unsupported('unrecognized source card grammar',wire)end
 costs={};local cards={};for id in raw:gmatch('%d+')do costs[#costs+1]=tonumber(id);cards[#cards+1]=disclosed(self,tonumber(id))end
 local suit,number=sgs.Card_NoSuit,0
 if #cards==1 then suit,number=q(cards[1],'getSuit'),q(cards[1],'getNumber')
 elseif #cards>1 then local red,black=true,true;for _,c in ipairs(cards)do red=red and q(c,'isRed');black=black and q(c,'isBlack')end;suit=red and sgs.Card_NoSuitRed or black and sgs.Card_NoSuitBlack or sgs.Card_NoSuit end
 return q(self,'evaluateTurnConversion',skill,q(q(self,'getEvaluationCard',name),'getClassName'),{name=name,skill=skill,suit=suit,number=number,subcards=costs},action_request(self,request))
end
local function final_parse(self,request,wire)
 local class,costs,user=parts(wire)
 return q(self,'bindSkillCard',known(skill_cards[class],class),costs,action_request(self,request),user,class)
end
local function whole_hand(self,player)
 if q(player,'objectName')==q(self.player,'objectName')then return q(player,'getHandcards')end
 local cards=q(player,'getKnownCards')
 if #cards~=q(player,'getHandcardNum')then ai_unsupported('erciyuan source requires full foreign hand sorting','erciyuan.whole_hand')end
 return cards
end
local function he_count(player)return q(player,'getHandcardNum')+#q(player,'getEquips')end
local function material(card,name,skill)return{name=name,skill=skill,suit=q(card,'getSuit'),number=q(card,'getNumber'),subcards={q(card,'getEffectiveId')}}end
local function player_disclosed(player,id)
 for _,cards in ipairs({q(player,'getCards','he'),q(player,'getHandPileCards')})do for _,card in ipairs(cards)do if q(card,'getEffectiveId')==id then return card end end end
 ai_unsupported('LuaChitian owner card not disclosed',tostring(id))
end
local function event_value(self,key,standard)
 -- The room's CurrentDamageStruct reaches the VM only as the ask's context damage.
 local context=q(self,'getDecisionContext');local row=known(context[standard and 'damage' or key],key)
 if type(row)~='table'then ai_unsupported('erciyuan current event absent',key)end
 local result={};for k,v in pairs(row)do result[k]=v end
 for _,field in ipairs({'from','to','who'})do local v=result[field];if type(v)=='string'then result[field]=v~=''and known(self.room:findPlayerByObjectName(v),key..'.'..field)or nil elseif v==false then result[field]=nil end end
 if result.card and type(result.card.isKindOf)~='function'then result.card=CardView.new(result.card)end
 if result.amount~=nil then result.damage=result.amount end
 return result
end
local function owner_eval(self,skill,name,suit,number)return q(self,'evaluateOwnerViewAsCard',{source_key=skill,skill=skill,name=name,suit=suit,number=number,subcards={}})end
local function get_weixiao(self)local name=self:getStrategyMemory('erciyuan.weixiao');return name and known(self.room:findPlayerByObjectName(name,true),'weixiao remembered player')or nil end
local function set_weixiao(self,p)self:setStrategyMemory('erciyuan.weixiao',p and q(p,'objectName')or nil)end
local function get_weixiao_choice(self)return self:getStrategyMemory('erciyuan.weixiaochoice')end
local function set_weixiao_choice(self,v)self:setStrategyMemory('erciyuan.weixiaochoice',v)end
local function target_flag(self,p,value)
 local name=q(p,'objectName');local epochs=known(AIWorldLifecycle.epochs(self.world,'flag'),'strategy_flag_clear_epochs');local epoch=known(epochs[name],'target clear epoch')
 local key='erciyuan.tiaojiao_target:'..name;local row=self:getStrategyMemory(key)
 if value~=nil then self:setStrategyMemory(key,{epoch=epoch,value=value});return end
 return row~=nil and row.epoch==epoch and row.value==true
end
local function current_visible_hand(self,player)
 local current=q(self.room,'getCurrent')
 if q(current,'objectName')~=q(self.player,'objectName')then ai_unsupported('LuaBimie source visibility is another actor private observation','LuaBimie.current_observer')end
 -- Known cards are exactly the hand cards flagged visible to this viewer (or an open hand).
 return q(player,'getKnownCards')
end
local function source_turn_spear(self,skill_name,request)
 -- Fixed caller passes inclusive as skill_name; do not repair its ignored third arg.
 local selected={};local cards=q(self,'sortByUseValue',q(self,'addHandPile'),nil,true)
 for _,card in ipairs(cards)do
  if self:isCard('Peach',card,self.player)or self:isCard('ExNihilo',card,self.player)and q(self.player,'getPhase')<=sgs.Player_Play then continue end
  selected[#selected+1]=card
 end
 if #selected<2 or #cards<q(self.player,'getHp')and q(self.player,'getHp')<5 and not q(self,'needKongcheng')then return nil end
 local slashes={};local remaining=AIList.new(selected)
 for _,c1 in ipairs(selected)do
  if #slashes>#selected/2 or #slashes>3 then break end
  table.removeOne(remaining,c1)
  for _,c2 in ipairs(remaining)do
   local card=parse(self,request,'slash:'..skill_name..'[no_suit:0]='..q(c1,'getId')..'+'..q(c2,'getId'))
   if q(card,'isAvailable',self.player)then slashes[#slashes+1]=card end
  end
 end
 return #slashes>0 and slashes
end
sgs.ai_chaofeng.itomakoto = -2
sgs.ai_chaofeng.ayanami = 3
sgs.ai_chaofeng.keima = 0
sgs.ai_chaofeng.SPkirito = 3
sgs.ai_chaofeng.odanobuna = 3
sgs.ai_chaofeng.yuuta = -2
sgs.ai_chaofeng.tsukushi = -2
sgs.ai_chaofeng.mao_maoyu = 1
sgs.ai_chaofeng.sheryl = 5
sgs.ai_chaofeng.aoitori = 3
sgs.ai_chaofeng.batora = -4
sgs.ai_chaofeng.kyouko = 4
sgs.ai_chaofeng.diarmuid = 6
sgs.ai_chaofeng.ikarishinji = -5
sgs.ai_chaofeng.redarcher = 2
sgs.ai_chaofeng.redo = 2
sgs.ai_chaofeng.runaria = -3
sgs.ai_chaofeng.fuwaaika = 5
sgs.ai_chaofeng.slsty = -2
sgs.ai_chaofeng.rokushikimei = 4
sgs.ai_chaofeng.bernkastel = 5
sgs.ai_chaofeng.hibiki = 4
sgs.ai_chaofeng.kntsubasa = 2
sgs.ai_chaofeng.khntmiku = 5
sgs.ai_chaofeng.yukinechris = 5



local function isEquip(name, player)
	for _, e in sgs.qlist(q(player,"getEquips")) do
		if q(e,"isKindOf",name) then
			return true
		end
	end
	return false
end

sgs.ai_skill_cardchosen.renzha = function(self, who, flags)
	local cards = whole_hand(self,who)
	call(self,"sortByUseValue",cards,true)
	return q(cards,"first")
end

sgs.ai_skill_invoke.ak_renzha = function(self, data)
	local damage = q(data,"toDamage")
	local x = q(self.player,"getMark","ak_renzha")
	if damage.damage >= 2 and x >= 2 then
		return true
	end
	if not q(self.player,"faceUp") then
		return true
	end
	return false
end

sgs.ai_skill_discard.ak_renzha = function(self)
	local to_discard = {}
	local cards = q(self.player,"getHandcards")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	table.insert(to_discard, cards[1]:getEffectiveId())
	return to_discard
end

sgs.ai_need_damaged.ak_renzha = function(self, attacker, player)
	if not (q(player,"hasSkill","chanyuan") and q(player,"getHp") == 2) and q(player,"hasSkill","ak_renzha") and q(self,"getEnemyNumBySeat",call(self.room,"getCurrent"), player, player, true) < q(player,"getHp")
		and (q(player,"getHp") >= 2 and not q(player,"faceUp")) then
		return true
	end
	return false
end

sgs.ai_can_damagehp.ak_renzha = function(self,from,card,to)
	return q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	and q(self,"canLoseHp",from,card,to)  and q(self,"getEnemyNumBySeat",call(self.room,"getCurrent"), to, to, true) < q(to,"getHp")
end


local luarenzha_skill = {}
luarenzha_skill.name = "luarenzha"
table.insert(package_skills, luarenzha_skill)
luarenzha_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"hasUsed","#luarenzhacard") then return end
	if q(self.player,"getPile","zha"):length() == 0 then return end

	local good, bad = 0, 0
	local lord = call(self.room,"getLord")
	if lord and self.role ~= "rebel" and q(self,"isWeak",lord) then return end
	for _, player in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		if q(self,"isWeak",player) then
			if q(self,"isFriend",player) then
				bad = bad + 1
			else
				good = good + 1
			end
		end
	end
	if good == 0 then return end

	for _, player in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
		local hp = math.max(q(player,"getHp"), 1)
		if getCardsNum("Analeptic", player) > 0 then
			if q(self,"isFriend",player) then
				good = good + 1.0 / hp
			else
				bad = bad + 1.0 / hp
			end
		end

		local has_slash = (getCardsNum("Slash", player) > 0)
		local can_slash = false
		if not can_slash then
			for _, p in sgs.qlist(q(self.room,"getOtherPlayers",player)) do
				if q(player,"distanceTo",p) <= q(player,"getAttackRange") then
					can_slash = true
					break
				end
			end
		end
		if not has_slash or not can_slash then
			if q(self,"isFriend",player) then
				good = good + math.max(getCardsNum("Peach", player), 1)
			else
				bad = bad + math.max(getCardsNum("Peach", player), 1)
			end
		end

		if getCardsNum("Jink", player) == 0 then
			local lost_value = 0
			if q(self,"hasSkills",sgs.masochism_skill, player) then lost_value = q(player,"getHp") / 2 end
			local hp = math.max(q(player,"getHp"), 1)
			if q(self,"isFriend",player) then
				bad = bad + (lost_value + 1) / hp
			else
				good = good + (lost_value + 1) / hp
			end
		end
	end

	if q(self.player,"isWounded") then
		good = good + math.min(q(self.player,"getPile","zha"):length(), q(self.player,"getLostHp"))
	end
	if q(self.player,"faceUp") then
		bad = bad +
			0.5 * q(self.room,"getOtherPlayers",self.player):length() /
			math.min(q(self.player,"getPile","zha"):length(), q(self.player,"getLostHp"))
	end
	if good > bad then
		local renzha = disclosed(self,q(self.player,"getPile","zha"):first())
		return parse(self,request,"#luarenzhacard:" .. q(renzha,"getId") .. ":")
	end
end

sgs.ai_skill_use_func["#luarenzhacard"] = function(card,use,self,request)
	use.card = card
	return
end

sgs.ai_use_priority["luarenzhacard"]    = 4.2
sgs.ai_card_intention["luarenzhacard"]  = 0


ai_audited_aliases.register{id="ai_cardneed.weixiao",registry="ai_cardneed",path={"weixiao"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true}
sgs.ai_skill_discard.weixiao            = function(self)
	local to_discard = {}
	local cards = q(self.player,"getHandcards")
	cards = AIList.new(cards)
	if q(self.player,"getHandcardNum") < 2 then return {} end
	local max_number = 0
	for _, card in sgs.qlist(q(self.player,"getHandcards")) do
		max_number = math.max(max_number, q(card,"getNumber"))
	end
	if max_number >= 4 then
		local card_num_max = 0
		local card_n
		local card_num_max2 = 0
		local card_n2
		for _, card in sgs.qlist(q(self.player,"getHandcards")) do
			if q(card,"getNumber") > card_num_max then
				card_num_max2 = card_num_max
				card_num_max = q(card,"getNumber")
				card_n2 = card_n
				card_n = card
			else
				if q(card,"getNumber") <= card_num_max and q(card,"getNumber") > card_num_max2 then
					card_num_max2 = q(card,"getNumber")
					card_n2 = card
				end
			end
		end
		local x = card_num_max2 / 2
		local n = card_num_max / 2
		set_weixiao(self,nil)
		call(self,"updatePlayers")
		if #self.friends == 1 then
			set_weixiao(self,self.player)
			set_weixiao_choice(self,"a")
			if card_n and card_n2 then
				table.insert(to_discard, q(card_n,"getEffectiveId"))
				table.insert(to_discard, q(card_n2,"getEffectiveId"))
				return to_discard
			end
		end
		local player = call(self,"AssistTarget")

		if x == 1 then
			set_weixiao(self,self.player)
		elseif #self.friends > 1 then
			sort_players(self,self.friends, "chaofeng")
			if not get_weixiao(self) and (q(self,"isWeak",self.player) or q(self.player,"getHandcardNum") <= 4) and not q(self,"needKongcheng",self.player, true) then
				set_weixiao(self,self.player)
			end
			if not get_weixiao(self) and #self.enemies > 0 then
				local wf
				if q(self.player,"isLord") then
					if q(self,"isWeak") and (q(self.player,"getHp") < 2 and q(self,"getCardsNum","Peach") < 1) then
						wf = true
					end
				end
				if not wf then
					for _, friend in ipairs(self.friends) do
						if q(self,"isWeak",friend) then
							wf = true
							break
						end
					end
				end

				if not wf then
					sort_players(self,self.enemies, "chaofeng")
					for _, enemy in ipairs(self.enemies) do
						if he_count(enemy) == n
							and q(self,"doDisCard",enemy, "he", false, n) then
							set_weixiao_choice(self,"b")
							set_weixiao(self,enemy)
							if card_n and card_n2 then
								table.insert(to_discard, q(card_n,"getEffectiveId"))
								table.insert(to_discard, q(card_n2,"getEffectiveId"))
								return to_discard
							end
						end
					end
					for _, enemy in ipairs(self.enemies) do
						if he_count(enemy) >= n
							and q(self,"doDisCard",enemy, "he", false, n)
							and q(self,"hasSkills",sgs.cardneed_skill, enemy) then
							set_weixiao_choice(self,"b")
							set_weixiao(self,enemy)
							if card_n and card_n2 then
								table.insert(to_discard, q(card_n,"getEffectiveId"))
								table.insert(to_discard, q(card_n2,"getEffectiveId"))
								return to_discard
							end
						end
					end
				end
			end
			if not get_weixiao(self) and player and not hasManjuanEffect(player) and not q(self,"needKongcheng",player, true) then
				set_weixiao(self,player)
			end

			if not get_weixiao(self) then
				set_weixiao(self,call(self,"findPlayerToDraw",true, n))
			end
			if not get_weixiao(self) then
				for _, friend in ipairs(self.friends) do
					if not hasManjuanEffect(friend) then
						set_weixiao(self,friend)
						break
					end
				end
			end
			if get_weixiao(self) then set_weixiao_choice(self,"a") end
		end
		if not get_weixiao(self) and x > 1 and #self.enemies > 0 then
			sort_players(self,self.enemies, "handcard")
			for _, enemy in ipairs(self.enemies) do
				if he_count(enemy) >= n
					and q(self,"doDisCard",enemy, "he", false, n) then
					set_weixiao_choice(self,"b")
					set_weixiao(self,enemy)
					if card_n and card_n2 then
						table.insert(to_discard, q(card_n,"getEffectiveId"))
						table.insert(to_discard, q(card_n2,"getEffectiveId"))
						return to_discard
					end
				end
			end
			self.enemies = sgs.reverse(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if not q(enemy,"isNude")
					and not (q(self,"hasSkills",sgs.lose_equip_skill, enemy) and q(enemy,"getCards","e"):length() > 0)
					and not q(self,"needToThrowArmor",enemy)
					and not hasTuntianEffect(enemy) then
					set_weixiao_choice(self,"b")
					set_weixiao(self,enemy)
					if card_n and card_n2 then
						table.insert(to_discard, q(card_n,"getEffectiveId"))
						table.insert(to_discard, q(card_n2,"getEffectiveId"))
						return to_discard
					end
				end
			end
			for _, enemy in ipairs(self.enemies) do
				if not q(enemy,"isNude")
					and not (q(self,"hasSkills",sgs.lose_equip_skill, enemy) and q(enemy,"getCards","e"):length() > 0)
					and not q(self,"needToThrowArmor",enemy)
					and not (hasTuntianEffect(enemy) and x < 3 and he_count(enemy) < 2) then
					set_weixiao_choice(self,"b")
					set_weixiao(self,enemy)
					if card_n and card_n2 then
						table.insert(to_discard, q(card_n,"getEffectiveId"))
						table.insert(to_discard, q(card_n2,"getEffectiveId"))
						return to_discard
					end
				end
			end
		end
		if card_n and card_n2 then
			table.insert(to_discard, q(card_n,"getEffectiveId"))
			table.insert(to_discard, q(card_n2,"getEffectiveId"))
			return to_discard
		end
	end
	return {}
end
sgs.ai_skill_choice.weixiao             = function(self, choices, data)
	return get_weixiao_choice(self)
end


sgs.ai_skill_playerchosen.weixiao = function(self, targets)
	return get_weixiao(self)
end


sgs.ai_playerchosen_intention.weixiao = function(self, from, to)
	local intention = -80
	if hasManjuanEffect(to) then intention = -intention end
	if get_weixiao_choice(self) == "a" then
	elseif get_weixiao_choice(self) == "b" then
		intention = -intention
	end
	call(self,"updateIntention",from, to, intention)
end
sgs.ai_use_revises.weixiao = function(self, card, use)
	if q(card,"isKindOf","EquipCard")

	then
		same = call(self,"getSameEquip",card)
		if same
		then
			return false
		end
	end
end



sgs.ai_cardneed.LuaChanshi = function(to, card)
	return isCard("Slash", card, to)
end
sgs.ai_cardneed.LuaZhuan = function(to, card)
	return (q(card,"isBlack") and isCard("Slash", card, to)) or isCard("Duel", card, to)
end


local luagonglue_skill = {}
luagonglue_skill.name = "luagonglue"
table.insert(package_skills, luagonglue_skill)
luagonglue_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 or q(self.player,"hasUsed","#luagongluecard") then return end
	return parse(self,request,"#luagongluecard:.:")
end


sgs.ai_skill_use_func["#luagongluecard"] = function(card,use,self,request)
	local target
	sort_players(self,self.enemies, "defense")
	local lord = call(self.room,"getLord")
	if q(self.player,"getRole") == "rebel" then
		if not q(lord,"isKongcheng") then
			target = lord
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if not q(enemy,"isKongcheng") then
				target = enemy
			end
		end
	end
	if target then
		use.card=final_parse(self,request,"#luagongluecard:.:")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["luagongluecard"]       = 8
sgs.ai_use_priority["luagongluecard"]    = 8
sgs.ai_card_intention["luagongluecard"]  = 60



sgs.ai_skill_playerchosen.LuaChigui = function(self, targets)
	if q(self,"isWeak",self.player) then return nil end
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	local dest
	local temp = 0
	for _, target in ipairs(targets) do
		local count = 0
		if q(self,"isFriend",target) then
			if call(target,"getWeapon") and q(self,"hasSkills",sgs.lose_equip_skill, target) then
				for _, p in sgs.qlist(q(self.room,"getOtherPlayers",target)) do
					if q(target,"inMyAttackRange",p) and q(self,"isEnemy",p) then
						count = count + 1
					end
				end
			end
		else
			if not call(target,"getWeapon") or q(self,"hasSkills",sgs.lose_equip_skill, target) then return nil end
			for _, p in sgs.qlist(q(self.room,"getOtherPlayers",target)) do
				if q(target,"inMyAttackRange",p) and q(self,"isFriend",p) then
					count = count + 1
				end
			end
		end
		if count > temp then
			temp = count
			dest = target
		end
	end
	if dest and temp > 2 then return dest end
	return nil
end

sgs.ai_skill_invoke.LuaBuwu = function(self, data)
	local target = q(data,"toPlayer")
	if not q(target,"faceUp") and q(self,"isFriend",target) then
		return not q(self,"toTurnOver",target, q(target,"getHp") - 1, "LuaBuwu")
	end

	if q(self,"isEnemy",target) then
		if q(self,"toTurnOver",target, q(target,"getHp") - 1, "LuaBuwu") then
			return true
		end
	end
end

sgs.ai_choicemade_filter.skillInvoke.LuaBuwu = function(self, player, promptlist)
	local intention = 60
	local index = promptlist[#promptlist] == "yes" and 1 or -1
	local damage = event_value(self,"current_damage",true)
	if damage.from and damage.to then
		if hasManjuanEffect(damage.to) and index then call(self,"updateIntention",damage.from, damage.to, 80) end
		if not q(self,"toTurnOver",damage.to, q(damage.to,"getHp") - 1) then intention = -intention * index end
		if q(damage.to,"getHp") - 1 < 3 then
			call(self,"updateIntention",damage.from, damage.to, intention * index)
		else
			call(self,"updateIntention",damage.from, damage.to, math.min(intention, -30) * index)
		end
	end
end


sgs.ai_skill_invoke.LuaTianmoDefense = function(self, data)
	if q(self.player,"getMark","@tianmo") == 0 then return false end
	local damage = q(data,"toDamage")
	if not q(self,"needToLoseHp",damage.to, damage.from, damage.card) then
		return true
	end
	return false
end



local LuaWangxiang_skill = {}
LuaWangxiang_skill.name = "LuaWangxiang"
table.insert(package_skills, LuaWangxiang_skill)
LuaWangxiang_skill.getTurnUseCard=function(self,inclusive,request)
	local wxhcn = q(self.player,"getHandcardNum")
	local losehp = q(self.player,"getMaxHp") - q(self.player,"getHp")
	if wxhcn > losehp then return end
	local cards = q(self.player,"getCards","h")
	cards = AIList.new(cards)
	sort_use(self,cards, true)
	local card_nd = cards[1]
	return parse(self,request,("ex_nihilo:LuaWangxiang[%s:%s]=%d"):format(q(card_nd,"getSuitString"), q(card_nd,"getNumberString"),
		q(card_nd,"getEffectiveId")))
end

sgs.ai_use_value["LuaWangxiang"]    = 10
sgs.ai_use_priority["LuaWangxiang"] = 9

local luablackflame_skill = {}
luablackflame_skill.name            = "luablackflame"
table.insert(package_skills, luablackflame_skill)
luablackflame_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 then return end
	local source = self.player
	if q(source,"hasUsed","#luablackflamecard") then return end
	if q(self.player,"getHp") <= 2 then return end
	return parse(self,request,"#luablackflamecard:.:")
end

sgs.ai_skill_use_func["#luablackflamecard"] = function(card,use,self,request)
	sort_players(self,self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if q(self,"objectiveLevel",enemy) > 3 and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Fire, self.player) then
			if q(self.player,"getHp") > q(enemy,"getHp") and q(self.player,"getHp") > 1 and q(self,"canDamage",enemy,self.player,nil) then
				use.card=final_parse(self,request,"#luablackflamecard:.:")
				if use.to then
					call(use.to,"append",enemy)
				end
				return
			end
		end
	end
end

sgs.ai_use_value["luablackflamecard"]       = 8
sgs.ai_use_priority["luablackflamecard"]    = 10
sgs.ai_card_intention.luablackflamecard     = 90


sgs.ai_skill_invoke.LuaGqset                = function(self, data)
	for _, card in sgs.qlist(q(self.player,"getHandcards")) do
		if q(card,"isKindOf","BasicCard") or q(card,"isKindOf","TrickCard") then
			return true
		end
	end
	return false
end

sgs.ai_skill_cardchosen.LuaGqset            = function(self, who, flags)
	local cards = q(self.player,"getCards","h")
	cards = AIList.new(cards)
	sort_use(self,cards, true)
	for _, card in ipairs(cards) do
		if q(card,"isKindOf","BasicCard") then
			return card
		end
		if q(card,"isKindOf","TrickCard") then
			return card
		end
	end
	return cards[1]
end
sgs.ai_skill_discard.LuaGqset               = function(self)
	local to_discard = {}
	local cards = q(self.player,"getHandcards")
	cards = AIList.new(cards)
	sort_use(self,cards)
	for _, card in ipairs(cards) do
		if q(card,"isKindOf","BasicCard") then
			table.insert(to_discard, q(card,"getEffectiveId"))
			return to_discard
		end
		if q(card,"isKindOf","TrickCard") then
			table.insert(to_discard, q(card,"getEffectiveId"))
			return to_discard
		end
	end
	return {}
end

function sgs.ai_slash_prohibit.LuaGqset(self, from, to, card)
	if q(to,"hasSkill","LuaGqset") and q(to,"getPile","gang"):length() > 0 and disclosed(self,q(to,"getPile","gang"):first()):getTypeId() == sgs.Card_TypeBasic then return true end
end

sgs.ai_target_revises.LuaGqset = function(to, card, self)
	if q(to,"getPile","gang"):length() > 0 then
		local newcard = disclosed(self,q(to,"getPile","gang"):first())
		return q(newcard,"getTypeId") == q(card,"getTypeId")
	end
end


local luatiaojiao_skill = {}
luatiaojiao_skill.name = "luatiaojiao"
table.insert(package_skills, luatiaojiao_skill)
luatiaojiao_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"hasUsed","#luatiaojiaocard") then return end
	for _, friend in ipairs(self.friends) do
		if q(friend,"getJudgingArea"):length() > 0 then
			return parse(self,request,"#luatiaojiaocard:.:")
		end
	end
	if #self.enemies < 1 then return end
	if #self.enemies == 1 and self.enemies[1]:isNude() then return end
	return parse(self,request,"#luatiaojiaocard:.:")
end

sgs.ai_skill_use_func["#luatiaojiaocard"] = function(card,use,self,request)
	for _, friend in ipairs(self.friends_noself) do
		if q(friend,"getJudgingArea"):length() > 0
			and not q(friend,"hasSkills","shensu|qingyi|qiaobian")
			and (q(self,"isWeak",friend) or q(self,"getOverflow",friend) > 1)
		then
			for _, c in sgs.list(q(friend,"getJudgingArea")) do
				if not q(c,"isKindOf","YanxiaoCard") then
					use.card=final_parse(self,request,"#luatiaojiaocard:.:")
					if use.to then call(use.to,"append",friend) end
					return
				end
			end
		end
	end
	local dummy_use = { isDummy = true, to = AIList.new({}) }
	local collateral = q(self,"getEvaluationCard","collateral")
	call(self,"useCardCollateral",collateral, dummy_use)
	if dummy_use.card and q(dummy_use.to,"length") == 2 then
		use.card=final_parse(self,request,"#luatiaojiaocard:.:")
		target_flag(self,q(dummy_use.to,"last"),true)
		if use.to then call(use.to,"append",q(dummy_use.to,"first")) end
		return
	end
	for _, enemy in ipairs(self.enemies) do
		if not q(enemy,"isNude") then
			for _, enemy2 in ipairs(self.enemies) do
				if q(enemy,"objectName") ~= q(enemy2,"objectName")
					and q(enemy,"canSlash",enemy2)
					and (q(self,"cantbeHurt",enemy2) or not q(self,"needToLoseHp",enemy2, enemy, nil, true)) and q(self,"canDamage",enemy,self.player,nil) then
					use.card=final_parse(self,request,"#luatiaojiaocard:.:")
					target_flag(self,enemy2,true)
					if use.to then call(use.to,"append",enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_use_value["luatiaojiaocard"]       = 8
sgs.ai_use_priority["luatiaojiaocard"]    = 10
sgs.ai_card_intention.luatiaojiaocard     = 30


sgs.ai_skill_playerchosen.luatiaojiaocard = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets, "defense")
	for _, p in ipairs(targets) do
		if target_flag(self,p) then
			target_flag(self,p,false)
			return p
		end
	end
	local target
	for _, p in ipairs(AIList.new(q(self.room,"getAlivePlayers"))) do
		if q(p,"hasFlag","luatiaojiaocard") then
			target = p
		end
	end
	local slash = q(self,"getEvaluationCard","slash")
	

	for _, enemy in ipairs(targets) do
		if q(target,"canSlash",enemy) and not q(self,"slashProhibit",slash, enemy) and q(self,"getDefenseSlash",enemy) <= 2
			and q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash)
			and q(enemy,"objectName") ~= q(target,"objectName") then
			return enemy
		end
	end
	return targets[0]
end

sgs.ai_skill_cardask["@TiaojiaoSlash"] = function(self, data, pattern, target)
	if q(self.player,"getJudgingArea"):length() > 0
		and not q(self.player,"hasSkills","shensu|qingyi|qiaobian")
		and (q(self,"isWeak",self.player) or q(self,"getOverflow",self.player) > 1)
	then
		for _, c in sgs.list(q(self.player,"getJudgingArea")) do
			if not q(c,"isKindOf","YanxiaoCard") then
				for _, p in ipairs(AIList.new(q(self.room,"getAlivePlayers"))) do
					if q(p,"hasFlag","luatiaojiaocard") then
						if q(self,"isFriend",p) then
							return "."
						end
					end
				end
			end
		end
	end
	if target then
		for _, slash in ipairs(q(self,"getCards","Slash")) do
			if q(self,"isFriend",target) and q(self,"slashIsEffective",slash, target) then
				if q(self,"needLeiji",target, self.player) then return slash end
				if q(self,"needToLoseHp",target, self.player, nil, true) then return slash end
			end

			if not q(self,"isFriend",target) and q(self,"slashIsEffective",slash, target)
				and not q(self,"needLeiji",target, self.player)
			then
				return slash
			end
		end
		for _, slash in ipairs(q(self,"getCards","Slash")) do
			if not q(self,"isFriend",target) then
				if not q(self,"needLeiji",target, self.player) and not q(self,"needToLoseHp",target, self.player, slash) then
					return
						slash
				end
				if not q(self,"slashIsEffective",slash, target) then return slash end
			end
		end
	end
	return "."
end


local luaboxue_skill = {}
luaboxue_skill.name = "luaboxue"
table.insert(package_skills, luaboxue_skill)
luaboxue_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"hasUsed","#luaboxuecard") then return end
	
	return parse(self,request,"#luaboxuecard:.:")
end

sgs.ai_skill_use_func["#luaboxuecard"] = function(card,use,self,request)
	local targets = AIList.new({})
	for _, friend in ipairs(self.friends) do
		if not q(friend,"isNude") then
			call(targets,"append",friend)
		end
	end
	if targets then
		use.card=final_parse(self,request,"#luaboxuecard:.:")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_value["luatiaojiaocard"]    = 8
sgs.ai_use_priority["luatiaojiaocard"] = 10
sgs.ai_card_intention.luatiaojiaocard  = -60

sgs.ai_skill_choice.luaboxuecard       = function(self, choices, data)
	return "gx"
end

local LuaYaojing_skill                 = {}
LuaYaojing_skill.name                  = "LuaYaojing"
table.insert(package_skills, LuaYaojing_skill)

LuaYaojing_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"getHandcardNum") < 1 then return end
	local can = false
	local cards = AIList.new(q(self.player,"getHandcards"))
	local subcards = {}
	sort_use(self,cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
		if not (isCard("Peach", card, self.player) or isCard("ExNihilo", card, self.player)) then
			table.insert(cardsq,
				card)
		end
	end
	if #cardsq == 0 then return end
	if q(self,"getKeepValue",cardsq[1]) > 18 then return end
	if q(self,"getUseValue",cardsq[1]) > 12 then return end
	table.insert(subcards, cardsq[1]:getId())
	local card_str = "god_salvation:LuaYaojing[to_be_decided:0]=" .. table.concat(subcards, "+")
	local AsCard = parse(self,request,card_str)
	assert(AsCard)
	return AsCard
end
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|LuaYaojing"

sgs.ai_skill_playerchosen.LuaGongming = function(self, targets)
	targets = AIList.new(targets)
	sort_players(self,targets)
	for _, friend in ipairs(targets) do
		if not q(self,"isFriend",friend) then
			table.removeOne(targets, friend)
		end
	end
	local max_x = 0
	local target
	local Shenfen_user
	for _, player in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(player,"hasFlag","ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end
	if Shenfen_user then
		local y, weak_friend = 3
		for _, friend in ipairs(targets) do
			local x = q(self.player,"getLostHp") + 1
			if hasManjuanEffect(friend) and x > 0 then x = x + 1 end
			if x > max_x and q(friend,"isAlive") then
				max_x = x
				target = friend
			end

			if q(self,"playerGetRound",friend, Shenfen_user) > q(self,"playerGetRound",self.player, Shenfen_user) and x >= y
				and q(friend,"getHp") == 1 and getCardsNum("Peach", friend, self.player) < 1 then
				y = x
				weak_friend = friend
			end
		end

		if weak_friend and ((getCardsNum("Peach", Shenfen_user, self.player) < 1) or (math.min(q(Shenfen_user,"getMaxHp"), 5) - q(Shenfen_user,"getHandcardNum") <= 1)) then
			return weak_friend
		end
		if q(self,"isFriend",Shenfen_user) and math.min(q(Shenfen_user,"getMaxHp"), 5) > q(Shenfen_user,"getHandcardNum") then
			return Shenfen_user
		end
		if target then return target end
	end

	local CP = call(self.room,"getCurrent")
	local max_x = 0
	local AssistTarget = call(self,"AssistTarget")
	for _, friend in ipairs(targets) do
		local x = q(self.player,"getLostHp") + 1
		if hasManjuanEffect(friend) then x = x + 1 end
		if q(self,"hasCrossbowEffect",CP) then x = x + 1 end
		if AssistTarget and q(friend,"objectName") == q(AssistTarget,"objectName") then x = x + 0.5 end

		if x > max_x and q(friend,"isAlive") then
			max_x = x
			target = friend
		end
	end
	if not target then
		target = self.player
	end
	return target
end




ai_audited_aliases.register{id="ai_cardneed.LuaPomo",registry="ai_cardneed",path={"LuaPomo"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
ai_audited_aliases.register{id="ai_cardneed.LuaBimie",registry="ai_cardneed",path={"LuaBimie"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.ai_use_revises.LuaPomo = function(self, card, use)
	if q(card,"isKindOf","Slash")
	then
		call(self,"setStrategyCardFlag",card,"Qinggang",true)
	end
end

sgs.ai_skill_invoke.LuaBimie = function(self, data)
	local damage = q(data,"toDamage")
	local target = damage.to
	if q(self,"isEnemy",target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.LuaBimie = function(self, player, promptlist)
	local intention = 100
	local index = promptlist[#promptlist] == "yes" and 1 or -1
	local damage = event_value(self,"current_damage",true)
	if damage.from and damage.to then
		if index == -1 then
			intention = -20
		end
		call(self,"updateIntention",damage.from, damage.to, intention)
	end
end



function sgs.ai_cardneed.LuaBimie(to, card, self)
	local cards = current_visible_hand(self,to)
	local has_weapon = call(to,"getWeapon")
	local slash_num = 0
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", call(self.room,"getCurrent"):objectName(), q(to,"objectName"))
		if true then
			if q(c,"isKindOf","Weapon") then
				has_weapon = true
			end
			if q(c,"isKindOf","Slash") then slash_num = slash_num + 1 end
		end
	end

	if not has_weapon then
		return q(card,"isKindOf","Weapon")
	else
		return q(to,"hasWeapon","spear") or q(card,"isKindOf","Slash") or (slash_num > 1 and q(card,"isKindOf","Analeptic"))
	end
end

sgs.ai_skill_defense.LuaBimie = function(self, player)
	return q(self,"isFriend",player) and q(player,"getMaxHp") or -q(player,"getMaxHp")
end


sgs.ai_skill_invoke.LuaBaozou = true
sgs.ai_skill_defense.LuaBaozou = 4

sgs.ai_skill_playerchosen["LuaXinbi"] = function(self, targets)
	return q(self,"findPlayerToDiscard","e", true, true, targets, false)[1]
end

function sgs.ai_slash_prohibit.LuaBaozou(self, from, to, card)
	if q(to,"getHp") <= 1 and not q(self,"isFriend",from, to) then
		return (q(to,"getHandcardNum") >= 2 and not q(self,"willSkipDrawPhase",to)) or not q(self,"willSkipPlayPhase",to)
	end
end

sgs.ai_ajustdamage_to.LuaBaozou = function(self, from, to, card, nature)
	if q(to,"hasFlag","BaozouTurn") then
		return -99
	end
end
sgs.ai_can_damagehp.LuaBaozou = function(self, from, card, to)
	if from and q(to,"getHp") + q(self,"getAllPeachNum") - q(self,"ajustDamage",from, to, 1, card) >= 0 and
		q(self,"canLoseHp",from, card, to) then
		return (q(to,"getHandcardNum") >= 2 and not q(self,"willSkipDrawPhase",to)) or not q(self,"willSkipPlayPhase",to)
	end
end


function sgs.ai_cardneed.LuaBaozou(to, card, self)
	return q(to,"getHandcardNum") < 3
end



local luatouying_skill = {}
luatouying_skill.name = "luatouying"
table.insert(package_skills, luatouying_skill)
luatouying_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"hasUsed","#luatouyingcard") then return end
	if call(self.player,"getWeapon") then return end
	return parse(self,request,"#luatouyingcard:.:")
end

sgs.ai_skill_use_func["#luatouyingcard"] = function(card,use,self,request)
	use.card = card
	return
end

sgs.ai_use_priority["luatouyingcard"]    = 10
sgs.ai_card_intention["luatouyingcard"]  = 0

sgs.ai_skill_choice.luatouying           = function(self, choices)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	local items = q(choices,"split","+")
	return items[math.random(1, #items)]
end


function sgs.ai_cardsview.ZhangbaSkill(self, class_name, player)
	if class_name == "Slash" then
		return cardsView_spear(self, player, "ZhangbaSkill")
	end
end

local ZhangbaSkill_skill = {}
ZhangbaSkill_skill.name = "ZhangbaSkill"
table.insert(package_skills, ZhangbaSkill_skill)
ZhangbaSkill_skill.getTurnUseCard=function(self,inclusive,request)
	return source_turn_spear(self,inclusive,request)
end

ai_audited_aliases.register{id="ai_skill_invoke.ShemaSkill",registry="ai_skill_invoke",path={"ShemaSkill"},canonical_registry="ai_skill_invoke",canonical_path={"kylin_bow"},self_index=1,defer_canonical=true}



local LuaGongqi_skill = {}
LuaGongqi_skill.name = "LuaGongqi"
table.insert(package_skills, LuaGongqi_skill)
LuaGongqi_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = q(self.player,"getCards","he")
	cards = AIList.new(cards)

	if q(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","wooden_ox")) do
			table.insert(cards, disclosed(self,id))
		end
	end

	local equip_card
	sort_use(self,cards, true)

	for _, card in ipairs(cards) do
		if q(card,"getTypeId") == sgs.Card_TypeEquip and (q(self,"getUseValue",card) < sgs.ai_use_value.Slash or inclusive)
			and not (q(card,"isKindOf","WoodenOx") and q(self.player,"getPile","wooden_ox"):length() > 0) then
			equip_card = card
			break
		end
	end

	if equip_card then
		local suit = q(equip_card,"getSuitString")
		local number = q(equip_card,"getNumberString")
		local card_id = q(equip_card,"getEffectiveId")
		local card_str = ("slash:LuaGongqi[%s:%s]=%d"):format(suit, number, card_id)
		local slash = parse(self,request,card_str)

		assert(slash)

		return slash
	end
end


function sgs.ai_cardneed.LuaGongqi(to, card, self)
	return q(card,"getTypeId") == sgs.Card_TypeEquip and getKnownCard(to, self.player, "EquipCard", true) == 0
end

ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.LuaJianzhi",registry="ai_choicemade_filter",path={"cardChosen","LuaJianzhi"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}





local luajianyu_skill = {}
luajianyu_skill.name = "luajianyu"
table.insert(package_skills, luajianyu_skill)

luajianyu_skill.getTurnUseCard=function(self,inclusive,request)
	local yong = q(self.player,"getPile","yong")
	local alivenum = q(self.room,"getAlivePlayers"):length()
	if q(yong,"length") < alivenum then return end

	local cards = {}
	local subcards = {}

	if q(self.player,"getPile","yong"):length() > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","yong")) do
			table.insert(cards, disclosed(self,id))
		end
	end
	sort_use(self,cards, true)
	if #cards == 0 or ((alivenum > 4) and (alivenum / q(yong,"length")) < 1.5) then return end
	for i = 1, alivenum, 1 do
		table.insert(subcards, cards[i]:getId())
	end
	local card_str = "archery_attack:luajianyu[to_be_decided:0]=" .. table.concat(subcards, "+")
	local AsCard = parse(self,request,card_str)
	assert(AsCard)
	return AsCard
end




local LuaChitian_skill = {}
LuaChitian_skill.name = "LuaChitian"
table.insert(package_skills, LuaChitian_skill)
LuaChitian_skill.getTurnUseCard=function(self,inclusive,request)
	call(self,"updatePlayers")
	sort_players(self,self.enemies, "defense")
	local no_have = true
	local cardsq = q(self.player,"getCards","he")
	if q(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","wooden_ox")) do
			call(cardsq,"prepend",disclosed(self,id))
		end
	end
	for _, c in sgs.qlist(cardsq) do
		if q(c,"isKindOf","Slash") then
			no_have = false
			break
		end
	end
	if not no_have then return end

	local cards = {}
	if q(self.player,"getPile","yong"):length() > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","yong")) do
			table.insert(cards, disclosed(self,id))
		end
	end
	sort_use(self,cards, true)
	local use_cards = {}

	if #cards > 0 then
		table.insert(use_cards, cards[1])
	end
	if #use_cards == 0 then return end

	for _, enemy in ipairs(self.enemies) do
		if q(self.player,"canSlash",enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash) and q(self.player,"inMyAttackRange",enemy) then
			local slash = q(self,"getEvaluationCard","slash")
			
			if not q(self,"slashProhibit",slash, enemy, self.player) and q(self,"slashIsEffective",slash, enemy, self.player) then
				local card_str = ("slash:LuaChitian[%s:%s]=%d"):format(sgs.Card_NoSuit, 0, use_cards[1]:getEffectiveId())
				local AsCard = parse(self,request,card_str)
				assert(AsCard)
				return AsCard
			end
		end
	end
end

sgs.ai_skill_use_func["#LuaChitian"] = function(card,use,self,request)
	local userstring = q(card,"getLegacyStringKey")
	userstring = (q(userstring,"split",":"))[4]
	local yizancard=owner_eval(self,"LuaChitian",userstring,q(card,"getSuit"),q(card,"getNumber"))
	
	
	call(self,"useBasicCard",yizancard, use)
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority["LuaChitian"] = 3
sgs.ai_use_value["LuaChitian"] = 3

sgs.ai_view_as["LuaChitian"] = function(card, player, card_place, class_name)
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local cards = q(player,"getCards","he")
	local no_have = true
	if q(player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(player,"getPile","wooden_ox")) do
			call(cards,"prepend",player_disclosed(player,id))
		end
	end
	for _, c in sgs.qlist(cards) do
		if q(c,"isKindOf",class_name) then
			no_have = false
			break
		end
	end
	if not no_have then return end

	local handcards = {}
	if q(player,"getPile","yong"):length() == 0 then return end
	if not q(player,"getPile","yong"):contains(q(card,"getId")) then return end
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	return material(card,name,"LuaChitian")
end




sgs.ai_skill_invoke.LuaChamberMove = function(self, data)
	if q(self.player,"getMark","@Chamber") == 1 then
		if q(self.player,"getHp") < 2 then
			return true
		end
	end
	if q(self.player,"getMark","@Chamber") == 0 then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.LuaRedoWake = function(self, targets)
	if #self.enemies > 0 then
		for _, enemy in ipairs(self.enemies) do
			if q(enemy,"isAlive") and q(self,"isGoodTarget",enemy) and not q(self,"cantbeHurt",enemy) and q(self,"damageIsEffective",enemy, sgs.DamageStruct_Thunder, self.player) and not q(self,"cantDamageMore",self.player, enemy) and q(self,"canDamage",enemy,self.player,nil) then
				return enemy
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if q(enemy,"isAlive") then
			return enemy
		end
	end
end


sgs.ai_skill_cardask["@jiguang"] = function(self, data, pattern)
	local effect = q(data,"toCardEffect")
	if q(self,"needToThrowArmor") then return "$" .. call(self.player,"getArmor"):getEffectiveId() end
	if not q(self,"slashIsEffective",effect.card, self.player, effect.from)
		or (not q(self,"hasHeavyDamage",effect.from, effect.card, self.player)
			and q(self,"needToLoseHp",self.player, effect.from, nil)) then
		return "."
	end
	if not q(self,"hasHeavyDamage",effect.from, effect.card, self.player) and q(self,"getCardsNum","Peach") > 0 then return "." end
	local equip_index = { 3, 0, 2, 4, 1 }
	if q(self.player,"hasSkills",sgs.lose_equip_skill) then
		for _, i in ipairs(equip_index) do
			if i == 4 then break end
			if call(self.player,"getEquip",i) then return "$" .. call(self.player,"getEquip",i):getEffectiveId() end
		end
	end

	local cards = AIList.new(q(self.player,"getHandcards"))
	sort_keep(self,cards)
	for _, card in ipairs(cards) do
		if (not q(self,"isWeak") and (q(self,"getKeepValue",card) > 8 or q(self,"isValuableCard",card))) then continue end
		if q(card,"isKindOf","BasicCard") then continue end
		return "$" .. q(card,"getEffectiveId")
	end

	for _, i in ipairs(equip_index) do
		if call(self.player,"getEquip",i) then
			if not (i == 1 and q(self,"evaluateArmor") > 3)
				and not (i == 4 and call(self.player,"getTreasure"):isKindOf("WoodenOx") and q(self.player,"getPile","wooden_ox"):length() >= 3) then
				return "$" .. call(self.player,"getEquip",i):getEffectiveId()
			end
		end
	end
end

ai_audited_aliases.register{id="ai_cardneed.LuaJiguangAsk",registry="ai_cardneed",path={"LuaJiguangAsk"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

sgs.ai_skill_discard.LuaWenle = function(self)
	local x = math.floor(q(self.room,"alivePlayerCount") / 2)
	local to_discard = {}
	local cards = q(self.player,"getHandcards")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	for i = 1, x do
		table.insert(to_discard, cards[i]:getEffectiveId())
	end
	return to_discard
end


local luayukong_skill = {}
luayukong_skill.name = "luayukong"
table.insert(package_skills, luayukong_skill)
luayukong_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"hasUsed","#luayukongcard") then return end
	if q(self.player,"getPile","si"):length() == 0 then return end
	if q(self.player,"getAttackRange") > 2 then return end
	if #self.enemies <= 1 then return end
	local min_number = 13
	local cardx
	for _, id in sgs.qlist(q(self.player,"getPile","si")) do
		local card = disclosed(self,id)
		local suit = q(card,"getSuitString")
		local number = q(card,"getNumber")
		local card_id = q(card,"getEffectiveId")
		if number < min_number then
			min_number = number
			cardx = card
		end
	end
	if cardx then
		return parse(self,request,"#luayukongcard:" .. q(cardx,"getId") .. ":")
	end
end


sgs.ai_skill_use_func["#luayukongcard"] = function(card,use,self,request)
	use.card = card
	local min_number = 13
	local cardx
	for _, id in sgs.qlist(q(self.player,"getPile","si")) do
		local card = disclosed(self,id)
		local suit = q(card,"getSuitString")
		local number = q(card,"getNumber")
		local card_id = q(card,"getEffectiveId")
		if number < min_number then
			min_number = number
			cardx = card
		end
	end
	if cardx then
		return parse(self,request,"#luayukongcard:" .. q(cardx,"getId") .. ":")
	end
end

sgs.ai_use_priority["luayukongcard"]    = 10
sgs.ai_card_intention["luayukongcard"]  = 0


sgs.ai_skill_use["@@LuaQisi"] = function(self, prompt, method)
	local effect=event_value(self,"erciyuan_qisi_effect")
	local source = effect.from
	local itsar = q(source,"getAttackRange")
	local max_number = 0
	local cardx
	for _, id in sgs.qlist(q(self.player,"getPile","si")) do
		local card = disclosed(self,id)
		local suit = q(card,"getSuitString")
		local number = q(card,"getNumber")
		local card_id = q(card,"getEffectiveId")
		if number > max_number then
			max_number = number
			cardx = card
		end
	end
	if max_number / 2 < itsar then return "." end
	if cardx then
		if self.role == "rebel" and q(self,"getRoleEstimate",effect.from) == "rebel" and not q(effect.from,"hasSkill","jueqing")
			and q(self.player,"getHp") == 1 and q(self,"getAllPeachNum") < 1 then
			return "."
		end
		local card_str = "#LuaQisi:" .. q(cardx,"getId") .. ":"
		if q(self,"isEnemy",effect.from) or (q(self,"isFriend",effect.from) and self.role == "loyalist" and not q(effect.from,"hasSkill","jueqing") and q(effect.from,"isLord") and q(self.player,"getHp") == 1) then
			if q(effect.card,"isKindOf","Slash") then
				if q(self,"slashIsEffective",effect.card, self.player, effect.from) and q(self.player,"getPile","si"):length() > 1 then
					return
						card_str
				end
				if q(self,"hasHeavyDamage",effect.from, effect.card, self.player) then return card_str end

				error('fixed LuaQisi passes CardEffect.to Player to getExpectedJinkNum; sgs.qlist requires length',0)
				local jink_num = q(self,"getExpectedJinkNum",effect)
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
					or (q(effect.from,"hasSkill","dahe") and q(self.player,"hasFlag","dahe") and not hasHeart) then
					if q(effect.card,"isKindOf","NatureSlash") and q(self.player,"isChained") and not q(self,"isGoodChainTarget",self.player, effect.from, nil, nil, effect.card) then
						return
							card_str
					end
					if q(effect.from,"hasSkill","nosqianxi") and q(effect.from,"distanceTo",self.player) == 1 then
						return
							card_str
					end
					if q(self,"isFriend",effect.from) and self.role == "loyalist" and not q(effect.from,"hasSkill","jueqing") and q(effect.from,"isLord") and q(self.player,"getHp") == 1 then
						return
							card_str
					end
					if (not (q(self,"hasSkills",sgs.masochism_skill) or (q(self.player,"hasSkills","tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or q(effect.from,"hasSkill","jueqing")) then
						return card_str
					end
				end
			elseif q(effect.card,"isKindOf","AOE") then
				local from = effect.from
				if q(effect.card,"isKindOf","SavageAssault") then
					local menghuo = call(self.room,"findPlayerBySkillName","huoshou")
					if menghuo then from = menghuo end
				end

				local friend_null = 0
				for _, p in sgs.qlist(q(self.room,"getOtherPlayers",self.player)) do
					if q(self,"isFriend",p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
					if q(self,"isEnemy",p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
				end
				friend_null = friend_null + q(self,"getCardsNum","Nullification")
				local sj_num = q(self,"getCardsNum",q(effect.card,"isKindOf","SavageAssault") and "Slash" or "Jink")

				if not q(self,"hasTrickEffective",effect.card, self.player, from) then return "." end
				if not q(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, from) then return "." end
				if q(effect.from,"hasSkill","drwushuang") and q(self.player,"getCardCount") == 1 and q(self,"hasLoseHandcardEffective") then
					return
						card_str
				end
				if sj_num == 0 and friend_null <= 0 then
					if q(self,"isEnemy",from) and q(from,"hasSkill","jueqing") then return q(self,"doDisCard",from) end
					if q(self,"isFriend",from) and self.role == "loyalist" and q(from,"isLord") and q(self.player,"getHp") == 1 and not q(from,"hasSkill","jueqing") then
						return
							card_str
					end
					if (not (q(self,"hasSkills",sgs.masochism_skill) or (q(self.player,"hasSkills","tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or q(effect.from,"hasSkill","jueqing")) then
						return card_str
					end
				end
			end
		elseif q(self,"isEnemy",effect.from) then
			if q(effect.card,"isKindOf","FireAttack") and q(effect.from,"getHandcardNum") > 0 then
				if not q(self,"hasTrickEffective",effect.card, self.player) then return "." end
				if not q(self,"damageIsEffective",self.player, sgs.DamageStruct_Fire, effect.from) then return "." end
				if (q(self.player,"hasArmorEffect","vine") or q(self.player,"getMark","@gale") > 0) and q(effect.from,"getHandcardNum") > 3
					and not (q(effect.from,"hasSkill","hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
					return card_str
				elseif q(self.player,"isChained") and not q(self,"isGoodChainTarget",self.player, effect.from) then
					return card_str
				end
			elseif (q(effect.card,"isKindOf","Snatch") or q(effect.card,"isKindOf","Dismantlement"))
				and q(self,"getCardsNum","Peach") == q(self.player,"getHandcardNum") and not q(self.player,"isKongcheng") then
				if not q(self,"hasTrickEffective",effect.card, self.player) then return "." end
				return card_str
			elseif q(effect.card,"isKindOf","Duel") then
				if q(self,"getCardsNum","Slash") == 0 or q(self,"getCardsNum","Slash") < getCardsNum("Slash", effect.from, self.player) then
					if not q(self,"hasTrickEffective",effect.card, self.player) then return "." end
					if not q(self,"damageIsEffective",self.player, sgs.DamageStruct_Normal, effect.from) then return "." end
					return card_str
				end
			elseif q(effect.card,"isKindOf","TrickCard") and not q(effect.card,"isKindOf","AmazingGrace") and not q(effect.card,"isKindOf","GodSalvation") and not q(effect.card,"isKindOf","ExNihilo") then
				return card_str
			end
		elseif q(effect.card,"isKindOf","TrickCard") and not q(effect.card,"isKindOf","AmazingGrace") and not q(effect.card,"isKindOf","GodSalvation") and not q(effect.card,"isKindOf","ExNihilo") then
			return card_str
		end
	end
	return "."
end







local function getSlashNum(player)
	local num = 0
	for _, card in sgs.qlist(q(player,"getHandcards")) do
		if q(card,"isKindOf","Slash") then
			num = num + 1
		end
	end
	return num
end

local luaposhi_skill = {}
luaposhi_skill.name = "luaposhi"
table.insert(package_skills, luaposhi_skill)
luaposhi_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"hasUsed","#luaposhicard") then return end
	if q(self.player,"getMark","&luaposhi") > 0 then return end
	if #self.enemies < 1 then return end
	if getSlashNum(self.player) < 2 then return end
	if q(self.player,"getHp") < 2 and q(self,"getCardsNum","Peach") == 0 then return end
	if getSlashNum(self.player) < 3 and (q(self.player,"getHp") < 3 and q(self,"getCardsNum","Peach") == 0) then return end
	return parse(self,request,"#luaposhicard:.:")
end

sgs.ai_skill_use_func["#luaposhicard"] = function(card,use,self,request)
	use.card=final_parse(self,request,"#luaposhicard:.:")
	return
end

sgs.ai_use_value["luaposhicard"] = 7
sgs.ai_use_priority["luaposhicard"] = 9

sgs.double_slash_skill = sgs.double_slash_skill .. "|luaposhi"
ai_audited_aliases.register{id="ai_cardneed.luaposhi",registry="ai_cardneed",path={"luaposhi"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}

sgs.ai_skill_invoke.LuaLiansuo = true
sgs.ai_skill_invoke.LuaYinguo = function(self, data)
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"isMale") and q(self,"isFriend",p) then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.LuaYinguo = function(self, targets)
	local min_card_num = 100
	local target
	for _, p in sgs.qlist(targets) do
		if q(p,"isMale") and q(self,"isFriend",p) then
			if q(p,"getHandcardNum") < min_card_num then
				target = p
				min_card_num = q(p,"getHandcardNum")
			end
		end
	end
	if target then return target end
	return q(targets,"first")
end


local yanhuoacquire_skill = {}
yanhuoacquire_skill.name = "yanhuoacquire"
table.insert(package_skills, yanhuoacquire_skill)
yanhuoacquire_skill.getTurnUseCard=function(self,inclusive,request)
	if not q(self,"isWeak") and not q(self.player,"hasUsed","#yanhuoacquirecard") then
		local target
		local players = q(self.room,"getOtherPlayers",self.player)
		for _, p in sgs.qlist(players) do
			
			if q(p,"getPileCount","confuse") > 0 and q(self,"isEnemy",p) then
				target = p
				break
			end
		end
		if target then
			return parse(self,request,"#yanhuoacquirecard:.:")
		end
	end
end


sgs.ai_skill_use_func["#yanhuoacquirecard"] = function(card,use,self,request)
	if not q(self,"isWeak") then
		local target
		local players = q(self.room,"getOtherPlayers",self.player)
		for _, p in sgs.qlist(players) do
			if q(p,"getPileCount","confuse") > 0 and q(self,"isEnemy",p) then
				target = p
				break
			end
		end
		if target then
			use.card = card
			if use.to then call(use.to,"append",target) end
			return
		end
	end
end


sgs.ai_skill_invoke.slyanhuo = function(self, data)
	local damage = q(data,"toDamage")
	if q(self.player,"getPileCount","confuse") > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","confuse")) do
			local card = disclosed(self,id)
			if q(card,"getSuit") == sgs.Card_Spade and q(self,"isFriend",damage.from) and q(self,"isWeak",damage.from) then
				return true
			elseif q(card,"getSuit") == sgs.Card_Heart or q(card,"getSuit") == sgs.Card_Diamond then
				if q(self,"isEnemy",damage.from) then
					return true
				end
			end
		end
	end
	
	return false
end


sgs.ai_skill_askforag["slyanhuo"] = function(self, card_ids)
	local damage=event_value(self,"erciyuan_slyanhuo_damage")
	local cards = {}
	local spade = {}
	local heart = {}
	local club = {}
	local diamond = {}
	for _, id in ipairs(card_ids) do
		local card = disclosed(self,id)
		if q(card,"getSuit") == sgs.Card_Spade then
			table.insert(spade, card)
		elseif q(card,"getSuit") == sgs.Card_Heart then
			table.insert(heart, card)
		elseif q(card,"getSuit") == sgs.Card_Club then
			table.insert(club, card)
		elseif q(card,"getSuit") == sgs.Card_Diamond then
			table.insert(diamond, card)
		end
		table.insert(cards, card)
	end
	if q(self,"isFriend",damage.from) then
		if q(self,"isWeak",damage.from) and #spade > 0 then
			sort_use(self,spade)
			return spade[1]:getId()
		elseif #club > 0 then
			sort_use(self,club)
			return club[1]:getId()
		end
	else
		if #heart > 0 then
			sort_use(self,heart)
			return heart[1]:getId()
		end
		if #diamond > 0 then
			sort_use(self,diamond)
			return diamond[1]:getId()
		end
	end
	sort_use(self,cards)
	return cards[1]:getId()
end

local yanhuovs_skill = {}
yanhuovs_skill.name = "slyanhuo"
table.insert(package_skills, yanhuovs_skill)
yanhuovs_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"getPileCount","confuse") < 5 and q(self.player,"getHandcardNum") > 0 and q(self.player,"getPileCount","confuse") < q(self.room,"getAlivePlayers"):length() then
		return parse(self,request,"#slyanhuocard:.:")
	end
end

sgs.ai_skill_use_func["#slyanhuocard"] = function(card,use,self,request)
	local cards = AIList.new(q(self.player,"getHandcards"))
	sort_keep(self,cards)
	if cards[1]:isKindOf("Peach") or cards[1]:isKindOf("Nullification") or cards[1]:isKindOf("Analeptic") then return end
	use.card=final_parse(self,request,"#slyanhuocard:" .. cards[1]:getEffectiveId() .. ":")
	return
end
sgs.ai_use_priority["slyanhuo"]        = sgs.ai_use_priority.ExNihilo - 0.1

sgs.ai_skill_invoke.LuaHeartlead       = function(self, data)
	local use = q(data,"toCardUse")
	local source = use.from
	local target = q(use.to,"first")
	local card = use.card
	if q(card,"isKindOf","Peach") and q(self,"isEnemy",target) then return true end
	if q(self,"isEnemy",source) and q(self,"isFriend",target) and q(self.player,"getHp") > 1 then return true end
	if q(self,"isEnemy",source) and q(self,"isFriend",target) and q(target,"getHp") == 1 then return true end
	return false
end

sgs.ai_skill_choice["LuaHeartlead"]    = "chained"

sgs.ai_skill_playerchosen.LuaHeartlead = function(self, targets)
	local positive = true
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"getHp") <= 0 and q(self,"isEnemy",p) then
			positive = false
		end
	end
	if positive then
		for _, p in sgs.qlist(targets) do
			if q(p,"isEnemy") then return p end
		end
	else
		for _, p in sgs.qlist(targets) do
			if q(p,"isFriend") and q(p,"getHp") < q(p,"getMaxHp") then return p end
		end
	end
	return q(targets,"first")
end

sgs.ai_skill_invoke.LuaHeartlead       = function(self, data)
	if q(self.player,"getHp") == 1 and q(self.player,"getHandcardNum") < 3 then return true end
	return false
end


sgs.ai_skill_invoke["erciyuan_qiji"]            = function(self, data)
	local dying = q(data,"toDying")
	if q(self,"isFriend",dying.who) then return true end
	return false
end
sgs.ai_skill_invoke["suipian"]         = function(self, data)
	local judge = q(data,"toJudge")
	if q(self,"needRetrial",judge) and (judge.pattern ~= ".") then return true end
	return false
end

sgs.ai_ajustdamage_from.LuaGungnir     = function(self, from, to, card, nature)
	if q(to,"getHp") > q(from,"getHp") then
		return 1
	end
end
sgs.ai_used_revises.LuaGungnir         = function(self, use)
	if q(use.card,"isKindOf","Slash")
		and not call(self.player,"getWeapon")
		and not use.isDummy
	then
		local use_card
		for _, card in sgs.qlist(q(self.player,"getHandcards")) do
			if q(card,"isKindOf","Weapon") then
				use_card = card
			end
		end
		if use_card then
			use.card = use_card

			use.to = AIList.new({})
			return false
		end
	end
end
sgs.hit_skill = sgs.hit_skill .. "|LuaGungnir"
ai_audited_aliases.register{id="ai_cardneed.LuaGungnir",registry="ai_cardneed",path={"LuaGungnir"},canonical_registry="ai_cardneed",canonical_path={"weapon"},self_index=3,defer_canonical=true}

sgs.ai_canliegong_skill.LuaGungnir = function(self, from, to)
	return call(from,"getWeapon") ~= nil and q(from,"hasWeapon",call(from,"getWeapon"):objectName())
end

ai_audited_aliases.register{id="ai_cardneed.luasynchrogazer",registry="ai_cardneed",path={"luasynchrogazer"},canonical_registry="ai_cardneed",canonical_path={"weapon"},self_index=3,defer_canonical=true}
sgs.double_slash_skill = sgs.double_slash_skill .. "|luasynchrogazer"

ai_audited_aliases.register{id="ai_cardneed.LuaCangshan",registry="ai_cardneed",path={"LuaCangshan"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}


sgs.ai_skill_invoke["moesenskill"] = function(self, data)
	local p = q(data,"toPlayer")
	if q(self,"isFriend",p) then return true end
	return false
end


local luasynchrogazer_skill = {}
luasynchrogazer_skill.name = "luasynchrogazer"
table.insert(package_skills, luasynchrogazer_skill)
luasynchrogazer_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"hasUsed","#luasynchrogazercard") then return end
	if #self.enemies < 1 then return end
	return parse(self,request,"#luasynchrogazercard:.:")
end

sgs.ai_skill_use_func["#luasynchrogazercard"] = function(card,use,self,request)
	use.card=final_parse(self,request,"#luasynchrogazercard:.:")
	return
end


sgs.ai_skill_playerchosen["luasynchrogazer_Target"] = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end




sgs.ai_skill_playerchosen["luasynchrogazer_Friend"] = function(self, targets)
	local drawnum = 1
	local friends = {}
	local player_list = AIList.new({})
	for _, player in ipairs(targets) do
		if q(self,"isFriend",player) and not hasManjuanEffect(player) and not q(self,"needKongcheng",player, true)
			and not (q(player,"hasSkill","kongcheng") and q(player,"isKongcheng") and drawnum <= 2) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return q(targets,"first") end

	sort_players(self,friends, "defense")
	for _, friend in ipairs(friends) do
		if q(friend,"getHandcardNum") < 2 and not q(self,"needKongcheng",friend) and not q(self,"willSkipPlayPhase",friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end

	local AssistTarget = call(self,"AssistTarget")
	if AssistTarget and not q(self,"willSkipPlayPhase",AssistTarget) and (q(AssistTarget,"getHandcardNum") < q(AssistTarget,"getMaxCards") * 2 or q(AssistTarget,"getHandcardNum") < q(self.player,"getHandcardNum")) then
		for _, friend in ipairs(friends) do
			if q(friend,"objectName") == q(AssistTarget,"objectName") and not q(self,"willSkipPlayPhase",friend) and not hasManjuanEffect(friend) then
				return friend
			end
		end
	end

	for _, friend in ipairs(friends) do
		if q(self,"hasSkills",sgs.cardneed_skill, friend) and not q(self,"willSkipPlayPhase",friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end

	sort_players(self,friends, "handcard")
	for _, friend in ipairs(friends) do
		if not q(self,"needKongcheng",friend) and not q(self,"willSkipPlayPhase",friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end
	return q(targets,"first")
end



sgs.ai_use_value["luasynchrogazercard"] = 7
sgs.ai_use_priority["luasynchrogazercard"] = sgs.ai_use_priority.Slash + 0.1





sgs.ai_view_as.LuaCangshan = function(card, player, card_place, class_name)
	local suit = q(card,"getSuitString")
	local number = q(card,"getNumberString")
	local card_id = q(card,"getEffectiveId")
	if (card_place ~= sgs.Player_PlaceSpecial or q(player,"getPile","wooden_ox"):contains(card_id))
		and q(card,"getTypeId") == sgs.Card_TypeEquip and not q(card,"hasFlag","using")
		and not (q(card,"isKindOf","WoodenOx") and q(player,"getPile","wooden_ox"):length() > 0) then
		local viewing_ai=known(q(player,'getRoom')._ai,'LuaCangshan viewing AI')
	local pattern=known(viewing_ai.request and viewing_ai.request.pattern,'LuaCangshan current request pattern')
		if pattern == "Jink" then
			return material(card,"Jink","LuaCangshan")
		elseif pattern == "Slash" then
			return material(card,"slash","LuaCangshan")
		end
	end
end

local LuaCangshan_skill = {}
LuaCangshan_skill.name = "LuaCangshan"
table.insert(package_skills, LuaCangshan_skill)
LuaCangshan_skill.getTurnUseCard=function(self,inclusive,request)
	local cards = q(self.player,"getCards","he")
	cards = AIList.new(cards)

	if q(self.player,"getPile","wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(q(self.player,"getPile","wooden_ox")) do
			table.insert(cards, disclosed(self,id))
		end
	end

	local equip_card
	sort_use(self,cards, true)

	for _, card in ipairs(cards) do
		if q(card,"getTypeId") == sgs.Card_TypeEquip and (q(self,"getUseValue",card) < sgs.ai_use_value.Slash or inclusive)
			and not (q(card,"isKindOf","WoodenOx") and q(self.player,"getPile","wooden_ox"):length() > 0) then
			equip_card = card
			break
		end
	end

	if equip_card then
		local suit = q(equip_card,"getSuitString")
		local number = q(equip_card,"getNumberString")
		local card_id = q(equip_card,"getEffectiveId")
		local card_str = ("slash:LuaCangshan[%s:%s]=%d"):format(suit, number, card_id)
		local slash = parse(self,request,card_str)

		assert(slash)

		return slash
	end
end


local luayuehuang_skill = {}
luayuehuang_skill.name = "luayuehuang"
table.insert(package_skills, luayuehuang_skill)
luayuehuang_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"hasUsed","#luayuehuangcard") then return end
	
	return parse(self,request,"#luayuehuangcard:.:")
end

sgs.ai_skill_use_func["#luayuehuangcard"] = function(card,use,self,request)
	use.card=final_parse(self,request,"#luayuehuangcard:.:")
	return
end

sgs.ai_use_value["luayuehuangcard"] = 7
sgs.ai_use_priority["luayuehuangcard"] = 9
sgs.double_slash_skill = sgs.double_slash_skill .. "|luayuehuang"
ai_audited_aliases.register{id="ai_cardneed.luayuehuang",registry="ai_cardneed",path={"luayuehuang"},canonical_registry="ai_cardneed",canonical_path={"equip"},self_index=3,defer_canonical=true}





sgs.ai_skill_choice["LuaJingming"] = function(self, choices, data)
	local target
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"getMark","noslash_jm") == 1 then
			target = p
		end
	end
	if not target then return "cancel" end
	if q(self,"isEnemy",target) then
		return "cancel"
	else
		if q(target,"getMaxHp") - q(target,"getHp") > 0 and q(target,"getHandcardNum") >= 1 then return "recover" end
		return "eachdraw"
	end
	return "cancel"
end

sgs.ai_choicemade_filter.skillChoice["LuaJingming"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local target
	for _, p in sgs.qlist(q(self.room,"getAlivePlayers")) do
		if q(p,"getMark","noslash_jm") == 1 then
			target = p
		end
	end
	if target then
		if choice ~= "cancel" then
			call(self,"updateIntention",player, target, -40)
		end
	end
end

sgs.ai_skill_cardask["@jmdiscard"] = function(self, data, pattern, target, target2)
	local p = q(data,"toPlayer")
	if q(self.player,"getHandcardNum") > 1 then
		local card_id
		local hcards = q(self.player,"getCards","h")
		hcards = AIList.new(hcards)
		sort_keep(self,hcards)
		if q(self,"isFriend",p) then
			if isEquip("Crossbow", p) then return "." end
			if q(p,"getHp") + q(p,"getHandcardNum") >= 4 then return "." end
			if q(p,"getHandcardNum") + 3 >= q(p,"getHp") then return "." end
			card_id = hcards[1]:getEffectiveId()
			return hcards[1]
		elseif q(self,"isEnemy",p) then
			if q(p,"getHandcardNum") <= 3 then return "." end
			if not isEquip("Crossbow", p) then return "." end
			card_id = hcards[1]:getEffectiveId()
			if q(self,"isWeak",self.player) and q(p,"inMyAttackRange",self.player) then
				if card_id then
					return hcards[1]
				end
			end
		end
		if card_id then
			return hcards[1]
		end
	end
	return "."
end



local luayingxian_skill = {}
luayingxian_skill.name = "luayingxian"
table.insert(package_skills, luayingxian_skill)
luayingxian_skill.getTurnUseCard=function(self,inclusive,request)
	if q(self.player,"hasUsed","#luayingxiancard") then return end
	
	return parse(self,request,"#luayingxiancard:.:")
end

sgs.ai_skill_use_func["#luayingxiancard"] = function(card,use,self,request)
	use.card=final_parse(self,request,"#luayingxiancard:.:")
	return
end

sgs.ai_use_value["luayingxiancard"] = 7
sgs.ai_use_priority["luayingxiancard"] = 9

sgs.ai_cardshow.luayingxiancard = function(self, requestor)
	local max = 0
	local result
	local cards = q(self.player,"getHandcards")
	for _, card in sgs.qlist(cards) do
		if q(card,"getNumber") > max then
			max = q(card,"getNumber")
			result = card
		end
	end


	return result 
end


local luasaoshe_skill = {}
luasaoshe_skill.name = "luasaoshe"
table.insert(package_skills, luasaoshe_skill)
luasaoshe_skill.getTurnUseCard=function(self,inclusive,request)
	if #self.enemies < 1 then return end
	if q(self.player,"isKongcheng") then return end
	local cards = AIList.new(q(self.player,"getHandcards"))
	local card_OK = false
	for _, acard in ipairs(cards) do
		if not q(acard,"isKindOf","Jink") and not q(acard,"isKindOf","Peach") and not q(acard,"isKindOf","Analeptic") then
			card_OK = true
		end
	end
	if not card_OK then return end
	local selfSub = q(self.player,"getHp") - q(self.player,"getHandcardNum")
	local selfDef = q(self,"getDefense",self.player)

	for _, enemy in ipairs(self.enemies) do
		local def = q(self,"getDefenseSlash",enemy)
		local slash = q(self,"getEvaluationCard","slash")
		
		local eff = q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, slash)

		if q(self.player,"canSlash",enemy, slash, true) and not q(self,"slashProhibit",nil, enemy) and def < 6 and eff and q(enemy,"getMark","SaosheX") < 2 then
			return parse(self,request,"#luasaoshecard:.:")
		end
	end
end

sgs.ai_skill_use_func["#luasaoshecard"] = function(card,use,self,request)
	local cards = AIList.new(q(self.player,"getHandcards"))
	local target
	local card
	for _, acard in ipairs(cards) do
		if not q(acard,"isKindOf","Jink") and not q(acard,"isKindOf","Peach") and not q(acard,"isKindOf","Analeptic") then
			card = acard
		end
	end
	local selfSub = q(self.player,"getHp") - q(self.player,"getHandcardNum")
	local selfDef = q(self,"getDefense",self.player)

	for _, enemy in ipairs(self.enemies) do
		local def = q(self,"getDefenseSlash",enemy)
		local slash = q(self,"getEvaluationCard","slash")
		
		local eff = q(self,"slashIsEffective",slash, enemy) and q(self,"isGoodTarget",enemy, self.enemies, nil)

		if q(self.player,"canSlash",enemy, slash, true) and not q(self,"slashProhibit",nil, enemy) and def < 6 and eff and q(enemy,"getMark","SaosheX") < 2 then
			target = enemy
			break
		end
	end
	if target and card then
		use.card=final_parse(self,request,"#luasaoshecard:" .. q(card,"getEffectiveId") .. ":")
		if use.to then call(use.to,"append",target) end
		return
	end
end

sgs.ai_use_value["luasaoshecard"]       = 9
sgs.ai_use_priority["luasaoshecard"]    = 3.2
sgs.ai_card_intention["luasaoshecard"]  = 80

sgs.ai_skill_invoke.LuaDikai            = function(self, data)
	local damage = q(data,"toDamage")
	if damage.from and q(self,"isEnemy",damage.from) then
		if q(self,"doDisCard",damage.from) then
			return true
		end
	end
	if q(self,"isFriend",damage.from) then
		return q(self,"needToThrowArmor",damage.from) or q(self,"doDisCard",damage.from)
	end
	return not damage.from or not q(self,"isFriend",damage.from)
end

sgs.ai_can_damagehp.LuaDikai = function(self,from,card,to)
	if from and q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	and q(self,"canLoseHp",from,card,to)
	then
		return q(self,"isEnemy",from) and q(self,"isWeak",from) and q(from,"getCardCount")>0
	end
end

sgs.ai_skill_cardask["@dikai"]          = function(self, data, pattern, target)
	if q(self,"isFriend",target) then
		local weapon, armor, def_horse, off_horse = {}, {}, {}, {}
		for _, card in sgs.qlist(q(self.player,"getHandcards")) do
			if q(card,"isKindOf","Weapon") then
				table.insert(weapon, card)
			elseif q(card,"isKindOf","Armor") then
				table.insert(armor, card)
			elseif q(card,"isKindOf","DefensiveHorse") then
				table.insert(def_horse, card)
			elseif q(card,"isKindOf","OffensiveHorse") then
				table.insert(off_horse, card)
			end
		end
		if #armor > 0 then
			for _, card in ipairs(armor) do
				if ((not call(target,"getArmor") and not q(target,"hasSkills","bazhen|yizhong"))
						or (call(target,"getArmor") and q(self,"evaluateArmor",card, target) >= q(self,"evaluateArmor",call(target,"getArmor"), target)))
					and not (q(card,"isKindOf","Vine") and q(use.card,"isKindOf","FireSlash") and q(self,"slashIsEffective",use.card, target, use.from)) then
					return "$" .. q(card,"getEffectiveId")
				end
			end
		end
		if q(self,"needToThrowArmor")
			and ((not call(target,"getArmor") and not q(target,"hasSkills","bazhen|yizhong"))
				or (call(target,"getArmor") and q(self,"evaluateArmor",call(self.player,"getArmor"), target) >= q(self,"evaluateArmor",call(target,"getArmor"), target)))
			and not (call(self.player,"getArmor"):isKindOf("Vine") and q(use.card,"isKindOf","FireSlash") and q(self,"slashIsEffective",use.card, target, use.from)) then
			return "$" .. call(self.player,"getArmor"):getEffectiveId()
		end
		if #def_horse > 0 then return "$" .. def_horse[1]:getEffectiveId() end
		if #weapon > 0 then
			for _, card in ipairs(weapon) do
				if not call(target,"getWeapon")
					or (q(self,"evaluateArmor",card, target) >= q(self,"evaluateArmor",call(target,"getWeapon"), target)) then
					return "$" .. q(card,"getEffectiveId")
				end
			end
		end
		if call(self.player,"getWeapon") and q(self,"evaluateWeapon",call(self.player,"getWeapon")) < 5
			and (not call(target,"getArmor")
				or (q(self,"evaluateArmor",call(self.player,"getWeapon"), target) >= q(self,"evaluateArmor",call(target,"getWeapon"), target))) then
			return "$" .. call(self.player,"getWeapon"):getEffectiveId()
		end
		if #off_horse > 0 then return "$" .. off_horse[1]:getEffectiveId() end
		if call(self.player,"getOffensiveHorse")
			and ((call(self.player,"getWeapon") and not call(self.player,"getWeapon"):isKindOf("Crossbow")) or q(self.player,"hasSkills","mashu|tuntian")) then
			return "$" .. call(self.player,"getOffensiveHorse"):getEffectiveId()
		end
		for _, card in sgs.qlist(q(self.player,"getHandcards")) do
			if not q(self,"isValuableCard",card) then return "$" .. q(card,"getEffectiveId") end
		end
	end
end


sgs.ai_skill_playerchosen["LuaLuowang"] = function(self, targets)
	targets = AIList.new(targets)
	if q(self.player,"hasFlag","luoDraw") then
		return call(self,"findPlayerToDraw",true)
	else
		local target = q(self,"findPlayerToDiscard","he", true)[1]
		if target then
			return target
		end
		for _, enemy in ipairs(self.enemies) do
            if q(self,"doDisCard",enemy, "he") then
				return enemy
            end
        end
	end
	return targets[1]
end

for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end
do local source=sgs.ai_skill_use['@@LuaQisi'];sgs.ai_skill_use['@@LuaQisi']=function(self,...)
 local wire=source(self,...);if wire==nil or wire=='.'or type(wire)~='string'then return wire end
 local use=AIUsePlan.new();use.card=final_parse(self,nil,wire);return use:toAnswer()
end end
