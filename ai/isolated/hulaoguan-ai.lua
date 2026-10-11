-- Fixed b6025acc package policy; all selection uses pure views and native-issued receipts.
local function call(object,method,...)
    if not object or type(object[method])~="function" then ai_unsupported("package helper unavailable",method) end
    local value=object[method](object,...)
    if AIUnsupported.is(value) then error(value,0) end
    return value
end
local function q(object,method,...)
    local value=call(object,method,...)
    if value==nil then ai_unsupported("package input is unknown",method) end
    return value
end
sgs.ai_skill_invoke["weapon_recast"] = function(self,data)
	if q(self,"hasSkills",sgs.lose_equip_skill,self.player) then return false end
	if q(self.player,"isLord") then
		local card_use = q(data,"toCardUse")
		if q(card_use.card,"objectName")~="Crossbow" then return true end
	else
		if call(self.player,"getWeapon") then return true end
	end
end

sgs.ai_skill_invoke["draw_1v3"] = function(self,data)
	return not q(self,"needKongcheng",self.player,true)
end

sgs.ai_skill_choice.Hulaopass = "recover"

sgs.ai_skill_cardask["@xiuluo"] = function(self,data,pattern)
	if q(self.player,"containsTrick","YanxiaoCard") then return "." end
	if not q(self.player,"containsTrick","indulgence") and not q(self.player,"containsTrick","supply_shortage")
		and not (q(self.player,"containsTrick","lightning") and not q(self,"hasWizard",self.enemies)) then return "." end
	local indul_suit,ss_suit,lightning_suit = nil,nil,nil
	for _,card in sgs.qlist(q(self.player,"getJudgingArea"))do
		if q(card,"isKindOf","Indulgence") then indul_suit = q(card,"getSuit") end
		if q(card,"isKindOf","SupplyShortage") then ss_suit = q(card,"getSuit") end
		if q(card,"isKindOf","Lightning") then ss_suit = q(card,"getSuit") end
	end
	if ss_suit then
		for _,card in sgs.qlist(q(self.player,"getHandcards"))do
			if q(card,"getSuit")==ss_suit then return "$"..q(card,"getEffectiveId") end
		end
	elseif indul_suit then
		for _,card in sgs.qlist(q(self.player,"getHandcards"))do
			if q(card,"getSuit")==indul_suit and not isCard("Peach",self.player,card) then return "$"..q(card,"getEffectiveId") end
		end
	elseif lightning_suit then
		for _,card in sgs.qlist(q(self.player,"getHandcards"))do
			if q(card,"getSuit")==lightning_suit and not isCard("Peach",self.player,card) then return "$"..q(card,"getEffectiveId") end
		end
	end
	return "."
end

sgs.ai_skill_askforag.xiuluo = function(self,card_ids)
	for _,id in ipairs(card_ids)do
		local card = q(self,"getChoiceCard",id)
		if q(card,"isKindOf","SupplyShortage") then return id end
	end
	for _,id in ipairs(card_ids)do
		local card = q(self,"getChoiceCard",id)
		if q(card,"isKindOf","Indulgence") then return id end
	end
	if q(self,"hasWizard",self.enemies) and q(self.player,"containsTrick","lightning") then
		for _,id in ipairs(card_ids)do
			local card = q(self,"getChoiceCard",id)
			if q(card,"isKindOf","Lightning") then return id end
		end
	end
	return card_ids[1]
end

sgs.ai_skill_choice.hulaopass_shenlvbu = function(self,choices,data)  --待补充
	local lvbus = q(choices,"split","+")
	return lvbus[math.random(1,#lvbus)]
end


--神躯
sgs.ai_skill_choice.shenqu = function(self,choices,data)
	return true
end

--极武
local function CanUsejiwu(self)
	if q(self,"needBear") and q(self.player,"getHandcardNum")>q(self.player,"getMaxCards") then return false end
	
	if not q(self.player,"hasSkill","xuanfeng",true) and q(self.player,"getEquips"):length()>0 then return true end
	if not q(self.player,"hasSkill","lieren",true) and q(self,"getCardsNum","Slash")>0 and
		(q(self.player,"getHandcardNum")-q(self,"getCardsNum","Peach")-q(self,"getCardsNum","Slash")>0) then return true end
	local candis = false
	for _,c in sgs.list(q(self.player,"getCards","he"))do
		if q(c,"isKindOf","Weapon") and q(self.player,"canDiscard",self.player,q(c,"getEffectiveId")) then
			candis = true
			break
		end
	end
	if not q(self.player,"hasSkill","qiangxi",true) and (q(self.player,"getHp")>3 or q(self,"getCardsNum","Peach")>0 or candis) then return true end
	call(self,"sort",self.enemies,"hp")
	if not q(self.player,"hasSkill","wansha",true) then
		for _,enemy in sgs.list(self.enemies)do
			if not (q(enemy,"hasSkill","kongcheng") and q(enemy,"isKongcheng")) and q(self,"isWeak",enemy) and q(self,"damageMinusHp",enemy,1)>0 and #self.enemies>1 then
				return true
			end
			if q(self.player,"hasSkill","qiangxi") and q(self,"isWeak",enemy) and q(self,"damageMinusHp",enemy,1)>0 then
				return true
			end
		end
	end
	
	if q(self,"needToThrowArmor") and q(self.player,"canDiscard",self.player,q(self.player,"getArmor"):getEffectiveId()) then return true end
	
	local num = 0
	if not q(self.player,"hasSkill","xuanfeng",true) then num = num+1 end
	if not q(self.player,"hasSkill","lieren",true) then num = num+1 end
	if not q(self.player,"hasSkill","qiangxi",true) then num = num+1 end
	if not q(self.player,"hasSkill","wansha",true) then num = num+1 end
	if q(self,"needKongcheng",self.player,true) and q(self.player,"getHandcardNum")<=num and num>0 then return true end
	
	return false
end

sgs.ai_fill_skill.jiwu = function(self,inclusive,request)
	if not CanUsejiwu(self) then return end
	return q(self,"legacySkillSeed","jiwu","JiwuCard",request)
end

sgs.ai_skill_use_func.JiwuCard = function(card,use,self,request)
	local usable_cards = q(self.player,"getCards","h")
	local use_card = {}
	for _,c in sgs.list(usable_cards)do
		if not q(c,"isKindOf","Peach") and not q(c,"isKindOf","ExNihilo") then
			table.insert(use_card,c)
		end
	end
	if #use_card==0 then return end
	call(self,"sortByKeepValue",use_card)
	use.card = q(self,"bindSkillCard","jiwu",{q(use_card[1],"getEffectiveId")},request,nil,"JiwuCard")
end

sgs.ai_skill_choice.jiwu = function(self,choices,data)
	if q(self.player,"getHandcardNum")-q(self,"getCardsNum","Peach")>0 then
		if not q(self.player,"hasSkill","xuanfeng",true) and q(self.player,"getEquips"):length()>0 then
			return "xuanfeng"
		end
		if not q(self.player,"hasSkill","lieren",true) and q(self,"getCardsNum","Slash")>0 and (q(self.player,"getHandcardNum")-q(self,"getCardsNum","Peach")-q(self,"getCardsNum","Slash")>0) then
			return "lieren"
		end
		
		local candis = false
		for _,c in sgs.list(q(self.player,"getCards","he"))do
			if q(c,"isKindOf","Weapon") and q(self.player,"canDiscard",self.player,q(c,"getEffectiveId")) then
				candis = true
				break
			end
		end
		if not q(self.player,"hasSkill","qiangxi",true) and (q(self.player,"getHp")>3 or q(self,"getCardsNum","Peach")>0 or candis) then
			return "qiangxi"
		end
		
		call(self,"sort",self.enemies,"hp")
		if not q(self.player,"hasSkill","wansha",true) then
			for _,enemy in sgs.list(self.enemies)do
				if not (q(enemy,"hasSkill","kongcheng") and q(enemy,"isKongcheng")) and q(self,"isWeak",enemy) and q(self,"damageMinusHp",enemy,1)>0 and #self.enemies>1 then
					return "wansha"
				end
				if q(self.player,"hasSkill","qiangxi") and q(self,"isWeak",enemy) and q(self,"damageMinusHp",enemy,1)>0 then
					return "wansha"
				end
			end
		end
	else
		if not q(self.player,"hasSkill","xuanfeng",true) then
			return "xuanfeng"
		end
		if not q(self.player,"hasSkill","lieren",true) then
			return "lieren"
		end
		if not q(self.player,"hasSkill","qiangxi",true) then
			return "qiangxi"
		end
		if not q(self.player,"hasSkill","wansha",true) then
			return "wansha"
		end
	end
	return q(choices,"split","+")[1]
end

sgs.ai_use_priority.JiwuCard = sgs.ai_use_priority.Slash+0.1
sgs.ai_use_value.JiwuCard = 3

sgs.ai_skill_invoke.wushuangji = function(self,data)
	local target = call(data,"toPlayer")
	if target then
		return q(self,"doDisCard",target,"he") or q(self,"canDraw")
	end
end

sgs.ai_skill_cardchosen.wushuangji = function(self,who,flags,method)
	if q(self,"doDisCard",who,"he")
	then return end
    return -1
end

sgs.ai_use_value.Wushuangji = 3
sgs.ai_keep_value.Wushuangji = 3.9

sgs.ai_skill_invoke.shimandai = function(self,data)
	local use = q(data,"toCardUse")
	if q(use.card,"isDamageCard") then
		if q(self,"canDamageHp",use.from,use.card) then
			return false
		end
	end
	return not q(self,"isFriend",use.from)
end

sgs.ai_use_value.Shimandai = 4.4
sgs.ai_keep_value.Shimandai = 3.9

sgs.ai_target_revises.baihuapao = function(to,card,self)
    if q(card,"isKindOf","NatureSlash") then
		return not q(self,"hasJueqingEffect",self.player,to)
	end
end

sgs.ai_ajustdamage_to.baihuapao = function(self,from,to,card,nature)
	if nature~="N" and not q(self,"hasJueqingEffect",from,to) then
		return -99
	end
end

sgs.ai_use_value.Baohuapao = 5.4
sgs.ai_keep_value.Baohuapao = 3.9

sgs.ai_skill_playerchosen.zijinguan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	call(self,"sort",destlist)
    for _,p in sgs.list(destlist)do
		if q(self,"isEnemy",p)
		and q(self,"damageIsEffective",p,"N")
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not q(self,"isFriend",p)
		and q(self,"damageIsEffective",p,"N")
		then return p end
	end
end

sgs.ai_use_value.Zijinguan = 5.4
sgs.ai_keep_value.Zijinguan = 3.9

function SmartAIView:useCardLianjunshengyan(card,use)
	local n = 0
	for _,p in sgs.list(q(self.room,"getAlivePlayers"))do
		if q(self.player,"canUse",card,p) then
			if q(self,"isEnemy",p) then
				n = n-1
				if q(self,"isWeak",p) then
					n = n-1
				end
			else
				n = n+1
				if q(self,"isFriend",p) and q(self,"isWeak",p) then
					n = n+1
				end
			end
		end
	end
	if n>=0 then
		use.card = card
	end
end
sgs.ai_use_priority.Lianjunshengyan = 1.4
sgs.ai_keep_value.Lianjunshengyan = 4
sgs.ai_use_value.Lianjunshengyan = 2.7





