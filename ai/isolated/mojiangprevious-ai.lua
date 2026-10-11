-- Fixed mojiangprevious-ai.lua b6025acc983331337614289d8cac79b078c003af.
-- Decisions preserve donor loop/short-circuit order; native scopes own authority.
local package_skills={}
local function known(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("mojiangprevious policy input is unknown",key) end
    return value
end
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("mojiangprevious policy helper unavailable",method) end
    local result=table.pack(object[method](object,...))
    if AIUnsupported.is(result[1]) then error(result[1],0) end
    return table.unpack(result,1,result.n)
end
local function q(object,method,...) return known(call(object,method,...),method) end
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
local function bind(self,skill,class,costs,request) return q(self,"bindSkillCard",skill,costs,action_request(self,request),nil,class) end
-- Source Card_Parse in use_func allocates a fresh policy object, not authority.
-- Keep exact ordered costs; only the final selected proposal may bind.
local function fresh_policy(self,skill,class,costs,request)
    return q(self,"evaluateTurnSkillCard",skill,class,costs,action_request(self,request))
end
local function response(self,skill,class,costs,targets)
    local use=AIUsePlan.new();use.card=bind(self,skill,class,costs,nil);use.to=AIList.new(targets)
    return use:toAnswer()
end
local function visible_card(self,id) return known(self:getKnownCardById(id),"sanzhi.own_material") end
local function move_count(move)
    if type(move.card_count)=="number" then return move.card_count end
    if move.card_ids then return #move.card_ids end
    ai_unsupported("huangyin move count unknown","sy_old_huangyin")
end
--博略
local sy_old_bolue_skill = {}
sy_old_bolue_skill.name = "sy_old_bolue"
table.insert(package_skills, sy_old_bolue_skill)
sy_old_bolue_skill.getTurnUseCard = function(self,inclusive,request)
    if q(self.player,"hasUsed","#sy_old_bolueCard") then return nil end
	if q(self.player,"getHp") <= 0 then return nil end
	return seed(self,"sy_old_bolue","#sy_old_bolueCard",request)
end

sgs.ai_skill_use_func["#sy_old_bolueCard"] = function(card,use,self,request)
	use.card = q(self,"inheritLegacyCardIdentity",bind(self,"sy_old_bolue","#sy_old_bolueCard",{},request),card)
end

sgs.ai_use_value["sy_old_bolueCard"] = 100
sgs.ai_use_priority["sy_old_bolueCard"] = 9.5

--忍忌
sgs.ai_skill_invoke.sy_old_renji = function(self, data)
    local damage = q(data,"toDamage")
	if q(self,"isEnemy",damage.from) then
	    return true
	end
	return false
end

sgs.ai_can_damagehp.sy_old_renji = function(self,from,card,to)
	if from and q(to,"getHp")+q(self,"getAllPeachNum")-q(self,"ajustDamage",from,to,1,card)>0
	and q(self,"canLoseHp",from,card,to)
	then
		return q(self,"isEnemy",from) and q(from,"getCardCount")>0
	end
end


--sgs.ai_skillInvoke_intention.sy_old_renji = 80


--归命
sgs.ai_skill_invoke.sy_old_guiming = function(self, data)
	local dying = q(data,"toDying")
	local peaches = 1 - q(dying.who,"getHp")
	return q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") < peaches
end


--横行
sgs.ai_skill_invoke.sy_old_hengxing = function(self, data)
	return #q(self.player,"getEquips") + q(self.player,"getHandcardNum") >= q(self.player,"getHp") and q(self.player,"getHp") <= 2
end


--恃傲
sgs.ai_skill_playerchosen.sy_old_shiao = function(self, targets)
	local room = self.room
	local tos = {}
	local slash = q(self,"getEvaluationCard","slash")
	for _, p in sgs.qlist(targets) do
		if q(self,"isEnemy",p) then
			if not q(self.player,"isProhibited",p,slash) then table.insert(tos, p) end
		end
	end
	if #tos > 0 then
		sort_players(self,tos, "defenseSlash")
		return tos[1]
	else
	    return nil
	end
	return nil
end


--狂袭
sgs.ai_skill_invoke.sy_old_kuangxi = function(self, data)
    local room = self.room
	local use = q(data,"toCardUse")
	if q(use.to,"contains",self.player) then return false end
	if not q(use.card,"isNDTrick") then return false end
	local F = 0
	local E = 0
	if q(use.card,"isKindOf","AmazingGrace") or q(use.card,"isKindOf","GodSalvation") then
	    for _, p in sgs.qlist(use.to) do
		    if q(self,"isFriend",p) then
			    F = F + 1
			elseif q(self,"isEnemy",p) then
			    E = E + 1
			end
		end
		if E - F >= 2 then return true else return false end
	end
	if q(use.card,"isKindOf","IronChain") then
	    for _, p in sgs.qlist(use.to) do
		    if q(self,"isFriend",p) then
			    F = F + 1
			elseif q(self,"isEnemy",p) then
			    E = E + 1
			end
		end
		if F == 0 and E > 0 then
		    if math.random(1, 5) > 3 then return true else return false end
		end
	end
	for _, p in sgs.qlist(use.to) do
		if q(self,"isFriend",p) then
		    F = F + 1
		elseif q(self,"isEnemy",p) then
		    E = E + 1
		end
	end
	if F == 0 and E > 0 then
	    local n = 0
	    for _, t in sgs.qlist(use.to) do
		    if q(self,"isEnemy",t) and q(self,"objectiveLevel",t) > 3 and q(self,"damageIsEffective",t) then
			    n = n + 1
			end
		end
		if E == n then
		    if math.random(1, 100) >= 45 then return true else return false end
		end
	end
	return false
end


--布教（旧）
sgs.ai_skill_cardask["@bujiao"] = function(self, data, pattern)
	local cards = AIList.new(q(self.player,"getHandcards"))
	sort_keep(self,cards)
	local zhangjiao = call(data,"toPlayer")
	local bujiaocard
	if q(self,"isEnemy",zhangjiao) or (not q(self,"isFriend",zhangjiao))then
		if q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") == #cards then
			bujiaocard = cards[math.random(1, #cards)]
		else
			local bc
			for _, card in ipairs(cards) do
				if (not q(card,"isKindOf","Peach")) and (not q(card,"isKindOf","Analeptic")) then
					bc = card
					break
				end
			end
			bujiaocard = bc
		end
	else
		if q(self,"isFriend",zhangjiao) then
			if (q(zhangjiao,"containsTrick","SupplyShortage") or q(zhangjiao,"containsTrick","Indulgence")) and q(self,"getCardsNum","Nullification") > 0 then
				for _, card in ipairs(cards) do
					if q(card,"isKindOf","Nullification") then
						bujiaocard = card
						break
					end
				end
			end
			if not bujiaocard then
				if q(self,"isWeak",zhangjiao) and (q(self,"getCardsNum","Peach") > 0 or q(self,"getCardsNum","Analeptic") > 0) then
					for _, card in ipairs(cards) do
						if q(card,"isKindOf","Peach") or q(card,"isKindOf","Analeptic") then
							bujiaocard = card
							break
						end
					end
				end
			end
			if not bujiaocard then
				if q(zhangjiao,"hasSkills","jizhi|nosjizhi") then
					for _, card in ipairs(cards) do
						if q(card,"isNDTrick") then
							bujiaocard = card
							break
						end
					end
				end
			end
			if not bujiaocard then
				if q(zhangjiao,"hasSkills","qiangxi|sgkgodzhiji") then
					for _, card in ipairs(cards) do
						if q(card,"isKindOf","Weapon") then
							bujiaocard = card
							break
						end
					end
				end
			end
			if not bujiaocard then
				bujiaocard = cards[math.random(1, #cards)]
			end
		end
	end
	if not bujiaocard then
		bujiaocard = cards[math.random(1, #cards)]
	end
	return "$" .. q(bujiaocard,"getEffectiveId")
end


--太平
sgs.ai_skill_playerchosen.sy_old_taiping = function(self, targets)
    if #self.enemies == 0 then return self.player end
	for _, enemy in ipairs(self.enemies) do
	    return enemy
	end
	return self.enemies[1]
end

sgs.ai_skill_invoke.sy_old_taiping = true


--妖惑
local sy_old_yaohuo_skill = {}
sy_old_yaohuo_skill.name = "sy_old_yaohuo"
table.insert(package_skills, sy_old_yaohuo_skill)
sy_old_yaohuo_skill.getTurnUseCard = function(self,inclusive,request)
    if q(self.player,"hasUsed","#sy_old_yaohuoCard") then return nil end
	if #self.enemies <= 0 then return nil end
	if q(self.player,"isKongcheng") then return nil end
	return seed(self,"sy_old_yaohuo","#sy_old_yaohuoCard",request)
end

sgs.ai_skill_use_func["#sy_old_yaohuoCard"] = function(card,use,self,request)
	local cards = q(self.player,"getHandcards")
	cards = AIList.new(cards)
	if q(self.player,"hasUsed","#sy_old_yaohuoCard") then return nil end
	sort_players(self,self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local target
	local a = q(self.player,"getHandcardNum") + #q(self.player,"getEquips")
	local b = -999
	for _, k in ipairs(self.enemies) do
	    b = math.max(b, q(k,"getHandcardNum"))
	end
	for _, enemy in ipairs(self.enemies) do
	    if a > q(enemy,"getHandcardNum") and (not q(enemy,"isKongcheng")) and q(enemy,"getHandcardNum") == b then
		    target = enemy
		    break
		end
	end
	if not target then
	    for _, enemy in ipairs(self.enemies) do
		    if a < b then
			    if a > q(enemy,"getHandcardNum") and (not q(enemy,"isKongcheng")) and a - q(enemy,"getHandcardNum") <= 2 then
				    target = enemy
					break
				end
			end
		end
	end
	if not target then return nil end
	if target then
	    use.card = q(self,"inheritLegacyCardIdentity",bind(self,"sy_old_yaohuo","#sy_old_yaohuoCard",{},request),card)
		if use.to then call(use.to,"append",target) end
	end
end


sgs.ai_skill_choice.sy_old_yaohuo = function(self, choices, data)
    local n = math.random(1, 100)
	local yaohuo = q(choices,"split","+")
	if n >= 1 and n <= 98 then
	    return yaohuo[1]
	else
	    return yaohuo[2]
	end
end

sgs.ai_use_value["sy_old_yaohuoCard"] = 100
sgs.ai_use_priority["sy_old_yaohuoCard"] = 8
sgs.ai_card_intention["sy_old_yaohuoCard"] = 90

--三治
local sy_old_sanzhi_skill = {}
sy_old_sanzhi_skill.name = "sy_old_sanzhi"
table.insert(package_skills, sy_old_sanzhi_skill)
sy_old_sanzhi_skill.getTurnUseCard = function(self,inclusive,request)
    if q(self.player,"isKongcheng") then return nil end
	if q(self.player,"hasUsed","#sy_old_sanzhiCard") then return nil end
	if #self.enemies == 0 then return nil end
	return seed(self,"sy_old_sanzhi","#sy_old_sanzhiCard",request)
end


sgs.ai_skill_use_func["#sy_old_sanzhiCard"] = function(card,use,self,request)
    if q(self.player,"hasUsed","#sy_old_sanzhiCard") then return nil end
	if q(self.player,"isKongcheng") then return nil end
	sort_players(self,self.enemies)
	local need_cards = {}
	local cards = AIList.new(q(self.player,"getHandcards"))
	sort_use(self,cards)
	for _,c in ipairs(cards) do
	    if #need_cards == 0 then
		    table.insert(need_cards, q(c,"getEffectiveId"))
		else
		    local can_do = true
			for _, p in ipairs(need_cards) do
			    if q(c,"getTypeId") == q(visible_card(self,p),"getTypeId") then
				    can_do = false
					break
				end
			end
			if can_do then
			    table.insert(need_cards, q(c,"getEffectiveId"))
			end
		end
		if #need_cards == math.min(#self.enemies, 3) then break end
	end
	local to_use = false
	if #self.enemies > 0 then to_use = true end
	if to_use then
	    use.card = fresh_policy(self,"sy_old_sanzhi","#sy_old_sanzhiCard",need_cards,request)
		if use.to then
		    for _, enemy in ipairs(self.enemies) do
				call(use.to,"append",enemy)
				if q(use.to,"length") == #need_cards then break end
			end
			assert(q(use.to,"length") > 0)
		end
	end
end

sgs.ai_card_intention["#sy_old_sanzhiCard"] = function(self, card, from, tos)
    local room = q(from,"getRoom")
	local huatuo = call(room,"findPlayerBySkillName","jijiu")
	for _,to in ipairs(tos) do
		local intention = 80
		if q(to,"hasSkill","yiji") and not q(from,"hasSkill","jueqing") then
			if (huatuo and q(self,"isFriend",huatuo) and q(huatuo,"getHandcardNum") >= 3 and q(huatuo,"objectName") ~= q(from,"objectName")) then
				intention = -30
			end
			if q(to,"getLostHp") == 0 and q(to,"getMaxHp") >= 3 then
				intention = -10
			end
		end
		if q(to,"hasSkill","hunzi") and q(to,"getMark","hunzi") == 0 then
			if q(to,"objectName") == q(q(from,"getNextAlive"),"objectName") and q(to,"getHp") == 2 then
				intention = -20
			end
		end
		if not q(self,"damageIsEffective",to) then intention = -20 end
		call(self,"updateIntention",from, to, intention)
	end
end

sgs.ai_use_value["sy_old_sanzhiCard"] = 100
sgs.ai_use_priority["sy_old_sanzhiCard"] = 7


--纵欲
function sgs.ai_cardsview.sy_old_zongyu(self, class_name, player)
	if class_name == "Analeptic" then
		if q(player,"hasSkill","sy_old_zongyu") and q(player,"getHp") >= 2 then
			return {name="analeptic",skill="sy_old_zongyu",suit=sgs.Card_NoSuit,number=0,subcards={}}
		end
	end
end


--凌虐
sgs.ai_skill_invoke.sy_old_lingnue = true
ai_audited_aliases.register{id="ai_cardneed.sy_old_lingnue",registry="ai_cardneed",path={"sy_old_lingnue"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true}
sgs.double_slash_skill = sgs.double_slash_skill .. "|sy_old_lingnue"


--暴政
sgs.ai_skill_cardask["@baozheng_old"] = function(self, data, pattern)
	local cards = AIList.new(q(self.player,"getCards","he"))
	sort_keep(self,cards)
	local dongzhuo = call(data,"toPlayer")
	local baozhengcard
	local diamond_cards = {}
	if q(self,"isEnemy",dongzhuo) or (not q(self,"isFriend",dongzhuo)) then
		for _, c in ipairs(cards) do
			if (not q(c,"isKindOf","Peach")) and (not q(c,"isKindOf","Analeptic")) and q(c,"getSuit") == sgs.Card_Diamond then
				table.insert(diamond_cards, c)
			end
		end
		if #diamond_cards > 0 then
			sort_keep(self,diamond_cards)
			baozhengcard = diamond_cards[1]
		else
			return "."
		end
	else
		if q(self,"isFriend",dongzhuo) then
			if (q(dongzhuo,"containsTrick","SupplyShortage") or q(dongzhuo,"containsTrick","Indulgence")) and q(self,"getCardsNum","Nullification") > 0 then
				for _, card in ipairs(cards) do
					if q(card,"isKindOf","Nullification") and q(card,"getSuit") == sgs.Card_Diamond then
						baozhengcard = card
						break
					end
				end
			end
			if not baozhengcard then
				if q(self,"isWeak",dongzhuo) and (q(self,"getCardsNum","Peach") > 0 or q(self,"getCardsNum","Analeptic") > 0) then
					for _, card in ipairs(cards) do
						if (q(card,"isKindOf","Peach") or q(card,"isKindOf","Analeptic")) and q(card,"getSuit") == sgs.Card_Diamond then
							baozhengcard = card
							break
						end
					end
				end
			end
			if not baozhengcard then
				if q(dongzhuo,"hasSkills","jizhi|nosjizhi") then
					for _, card in ipairs(cards) do
						if q(card,"isNDTrick") and q(card,"getSuit") == sgs.Card_Diamond then
							baozhengcard = card
							break
						end
					end
				end
			end
			if not baozhengcard then
				if q(dongzhuo,"hasSkills","qiangxi|sgkgodzhiji") then
					for _, card in ipairs(cards) do
						if q(card,"isKindOf","Weapon") and q(card,"getSuit") == sgs.Card_Diamond then
							baozhengcard = card
							break
						end
					end
				end
			end
			if not baozhengcard then
				for _, c in ipairs(cards) do
					if q(c,"getSuit") == sgs.Card_Diamond then
						table.insert(diamond_cards, c)
					end
				end
				if #diamond_cards > 0 then
					sort_keep(self,diamond_cards)
					baozhengcard = diamond_cards[1]
				else
					return "."
				end
			end
		end
	end
	if not baozhengcard then
		return "."
	end
	return "$" .. q(baozhengcard,"getEffectiveId")
end
sgs.ai_damage_reason_suppress_intention["sy_old_baozheng"] = true

--醉酒
local sy_old_zuijiu_skill = {}
sy_old_zuijiu_skill.name = "sy_old_zuijiu"
table.insert(package_skills, sy_old_zuijiu_skill)
sy_old_zuijiu_skill.getTurnUseCard = function(self,inclusive,request)
    if q(self.player,"isKongcheng") then return nil end
	if #self.enemies <= 0 then return nil end
	local s = 0
	for _, enemy in ipairs(self.enemies) do
	    if q(self.player,"canSlash",enemy) then s = s + 1 end
	end
	if s <= 0 then return nil end
	if q(self,"getCardsNum","Slash") <= 0 then return nil end
	if q(self.player,"hasUsed","#sy_old_zuijiuCard") then return nil end
    local red_count = 0
	local black_count = 0
	for _, c in sgs.qlist(q(self.player,"getHandcards")) do
	    if q(c,"isRed") then
		    red_count = red_count + 1
		elseif q(c,"isBlack") then
		    black_count = black_count + 1
		end
	end
	if black_count < red_count then
	    return nil
	else
	    local analeptic = nil -- Fixed extension has no such legacy prototype; preserve subsequent assertion.
		local zuijiu_ana = q(self,"getEvaluationCard","analeptic")
		if q(self.player,"isCardLimited",zuijiu_ana, sgs.Card_MethodUse) or q(self.player,"isProhibited",self.player, zuijiu_ana) then return nil end
		if q(self.player,"usedTimes","Analeptic") > q(zuijiu_ana,"getTargetModResidue") then return nil end
		if q(self,"readonlyTurnAvailability",zuijiu_ana) then
		    assert(analeptic)
		    return analeptic
		end
	end
end

sgs.ai_skill_use_func["#sy_old_zuijiuCard"] = function(card,use,self,request)
    use.card = card
end

sgs.ai_use_value["sy_old_zuijiuCard"] = 100
sgs.ai_use_priority["sy_old_zuijiuCard"] = 7.5


--荒淫
sgs.ai_skill_invoke.sy_old_huangyin = function(self, data)
    local room = self.room
	local move = q(data,"toMoveOneTime")
	local x = move_count(move)
	local s = 0
	for _, p in ipairs(self.enemies) do
	    if (not q(self,"isFriend",p)) and #q(p,"getEquips") + q(p,"getHandcardNum") >= x then
		    s = s + 1
		end
	end
	if s <= 0 then
	    return false
	else
	    local a = math.random(1, 100)
		return a >= 70
	end
end

sgs.ai_skill_playerchosen["huangyin-invoke"] = function(self, targets)
    local room = self.room
	local X = q(self.player,"getMark","huangyin-AI")
	local tos = {}
	for _, p in sgs.qlist(targets) do
		if q(self,"isEnemy",p) then
		    if #q(p,"getEquips") + q(p,"getHandcardNum") >= X then table.insert(tos, p) end
		end
	end
	if #tos == 0 then return nil end
	sort_players(self,tos, "defense")	
	return tos[1]
end


--乱嗣
local sy_old_luansi_skill = {}
sy_old_luansi_skill.name = "sy_old_luansi"
table.insert(package_skills, sy_old_luansi_skill)
sy_old_luansi_skill.getTurnUseCard = function(self,inclusive,request)
    if q(self.player,"hasUsed","#sy_old_luansiCard") then return nil end
	if #self.enemies <= 1 then return nil end
	local j = 0
	for _, p in ipairs(self.enemies) do
	    if (not q(p,"isNude")) then j = j + 1 end
	end
	if j <= 1 then return nil end
	return seed(self,"sy_old_luansi","#sy_old_luansiCard",request)
end

sgs.ai_skill_use_func["#sy_old_luansiCard"] = function(card,use,self,request)
    if q(self.player,"hasUsed","#sy_old_luansiCard") then return nil end
	local tar1, tar2
	for _, p in ipairs(self.enemies) do
	    if (not q(p,"isKongcheng")) then
		    tar1 = p
			break
		end
	end
	for _, m in ipairs(self.enemies) do
	    if q(m,"objectName") ~= tar1:objectName() and (not q(m,"isKongcheng")) then
		    tar2 = m
			break
		end
	end
	if tar1 and tar2 then
	    use.card = q(self,"inheritLegacyCardIdentity",bind(self,"sy_old_luansi","#sy_old_luansiCard",{},request),card)
		if use.to then
		    call(use.to,"append",tar1)
			call(use.to,"append",tar2)
		end
	else
	    return nil
	end
end

sgs.ai_use_value["sy_old_luansiCard"] = 90
sgs.ai_use_priority["sy_old_luansiCard"] = 8
sgs.ai_card_intention["sy_old_luansiCard"] = 90


--诋毁
local sy_old_dihui_skill = {}
sy_old_dihui_skill.name = "sy_old_dihui"
table.insert(package_skills, sy_old_dihui_skill)
sy_old_dihui_skill.getTurnUseCard = function(self,inclusive,request)
    if q(self.player,"hasUsed","#sy_old_dihuiCard") then return nil end
	if #self.enemies <= 0 then return nil end
	if q(self.player,"getHp") <= 0 then return nil end
	return seed(self,"sy_old_dihui","#sy_old_dihuiCard",request)
end

sgs.ai_skill_use_func["#sy_old_dihuiCard"] = function(card,use,self,request)
	if q(self.player,"hasUsed","#sy_old_dihuiCard") then return nil end
	local room = self.room
	local max_hp = {}
	local i_max
	local _maxhp = -1000
	local players = q(room,"getOtherPlayers",self.player)
	for _, p in sgs.qlist(q(room,"getOtherPlayers",self.player)) do
	    _maxhp = math.max(_maxhp, q(p,"getHp"))
	end
	for _, t in sgs.qlist(q(room,"getOtherPlayers",self.player)) do
	    if q(t,"getHp") == _maxhp then
		    table.insert(max_hp, t)
			call(players,"removeOne",t)
			break
		end
	end
	i_max = max_hp[1]
	local targetsB = q(room,"getOtherPlayers",self.player)
	call(targetsB,"removeOne",i_max)
	local targetsA = AIList.new(targetsB)
	local others = {}
	for _, _player in ipairs(targetsA) do
	    if q(self,"isEnemy",_player) then table.insert(others, _player) end
	end
	if i_max and #others > 0 then
	    use.card = q(self,"inheritLegacyCardIdentity",bind(self,"sy_old_dihui","#sy_old_dihuiCard",{},request),card)
		if use.to then
		    call(use.to,"append",i_max)
		end
	end
end

sgs.ai_skill_playerchosen["dihuiothers-choose"] = function(self, targets)
	local tos = {}
	local players = AIList.new(targets)
	for _, p in ipairs(players) do
	    if q(self,"isEnemy",p) then
		    table.insert(tos, p)
		end
	end
	sort_players(self,tos, "hp")
	return tos[1]
end


sgs.ai_use_value["sy_old_dihuiCard"] = 100
sgs.ai_use_priority["sy_old_dihuiCard"] = 7


--谗陷
local sy_old_chanxian_skill = {}
sy_old_chanxian_skill.name = "sy_old_chanxian"
table.insert(package_skills, sy_old_chanxian_skill)
sy_old_chanxian_skill.getTurnUseCard = function(self,inclusive,request)
    if q(self.player,"hasUsed","#sy_old_chanxianCard") then return nil end
	if #self.enemies <= 0 then return nil end
	if q(self.player,"getHandcardNum") - q(self,"getCardsNum","Peach") - q(self,"getCardsNum","Analeptic") <= 0 then return nil end
	if q(self.player,"isKongcheng") then return nil end
	if q(self.player,"getHandcardNum") <= 2 and q(self.player,"getHp") <= 2 then return nil end
	return seed(self,"sy_old_chanxian","#sy_old_chanxianCard",request)
end

sgs.ai_skill_use_func["#sy_old_chanxianCard"] = function(card,use,self,request)
    if #self.enemies <= 0 then return nil end
    local cards = q(self.player,"getHandcards")
	cards = AIList.new(cards)
	sort_keep(self,cards)
	local target
	local enemy_target = {}
	if #self.friends_noself <= 0 then
	    target = self.enemies[1]
	else
	    if #self.enemies > 0 and #self.friends > 0 then
	        target = self.friends[1]
	    end
	end
	if target then
	    local will_use
		if q(self,"isEnemy",target) then
		    for _, card in ipairs(cards) do
			    if (not q(card,"isKindOf","Peach")) and (not q(card,"isKindOf","Analeptic")) and (not q(card,"isKindOf","Nullification")) then
				    will_use = card
					break
				end
			end
		end
		if will_use then
		    use.card = fresh_policy(self,"sy_old_chanxian","#sy_old_chanxianCard",{q(will_use,"getEffectiveId")},request)
			if use.to then call(use.to,"append",target) end
		end
		return
	end
end

sgs.ai_skill_playerchosen["chanxian-choose"] = function(self, targets)
    local to_damage = {}
	local zhangrang = call(self.room,"findPlayerBySkillName","sy_old_chanxian")
	for _, ap in sgs.qlist(q(self.room,"getOtherPlayers",zhangrang)) do
	    if self.player:isEnemy(ap) then
		    table.insert(to_damage, ap)
		end
		if self.player:isFriend(ap) and q(ap,"getHp") >= 2 and q(self,"hasSkills",sgs.masochism_skill, ap) then
		    table.insert(to_damage, ap)
		end
	end
	return to_damage[1]
end


sgs.ai_use_value["sy_old_chanxianCard"] = 80
sgs.ai_use_priority["sy_old_chanxianCard"] = 5.2

--乱政
sgs.ai_skill_choice["sy_old_luanzheng"] = function(self, choices, data)
    local luanzheng = q(choices,"split","+")
	return luanzheng[math.random(1, #luanzheng)]
end


--嗜杀
sgs.ai_skill_discard.sy_old_shisha = function(self, discard_num, min_num, optional, include_equip)
    local to_discard = {}
	local sunhao
	if call(self.room,"findPlayerBySkillName","sy_old_shisha") then sunhao = call(self.room,"findPlayerBySkillName","sy_old_shisha") end
	if sunhao and q(self,"needToLoseHp",self.player, sunhao) then return to_discard end
	local n = math.random(1, 100)
	if q(self.player,"getHp") >= 3 or q(self,"getCardsNum","Peach") + q(self,"getCardsNum","Analeptic") > 0 then
	    if n <= 95 then
		    return to_discard
		else
		    local cards = AIList.new(q(self.player,"getCards","he"))
			sort_keep(self,cards)
			local index = 0
			for i = #cards, 1, -1 do
			    local card = cards[i]
				if (not isCard("Peach", card, self.player)) and (not isCard("Analeptic", card, self.player)) and (not q(self.player,"isJilei",card)) then
				    table.insert(to_discard, q(card,"getEffectiveId"))
			        table.remove(cards, i)
			        index = index + 1
			        if index == 2 then break end
		        end
			end
			if #to_discard < 2 then return {}
			else return to_discard end
		end
	else
	    local cards = AIList.new(q(self.player,"getCards","he"))
		sort_keep(self,cards, true)
		local index = 0
		for i = #cards, 1, -1 do
		    local card = cards[i]
			if not (isCard("Peach", card, self.player)) and (not isCard("Analeptic", card, self.player)) and not q(self.player,"isJilei",card) then
			    table.insert(to_discard, q(card,"getEffectiveId"))
		        table.remove(cards, i)
		        index = index + 1
		        if index == 2 then break end
	        end
		end
		if #to_discard < 2 then return {}
		else return to_discard end
	end
end


--祸心
sgs.ai_skill_choice["sy_old_huoxin"] = function(self, choices, data)
    local huoxin = q(choices,"split","+")
	local caifuren = call(self.room,"findPlayerBySkillName","sy_old_huoxin")
	if q(self,"isFriend",caifuren) then
	    return huoxin[1]
	else
	    return huoxin[math.random(1, #huoxin)]
	end
end
for _,skill in ipairs(package_skills)do sgs.ai_fill_skill[skill.name]=skill.getTurnUseCard end
